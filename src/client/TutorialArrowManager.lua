-- Tutorial Arrow Manager
-- Creates and manages 3D arrows pointing to tutorial objectives

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
-- Simple logging removed ClientLogger

local TutorialArrowManager = {}

-- State
local currentArrow = nil
local currentConnection = nil
local arrowTween = nil
local currentTrail = nil
local trailConnection = nil
local trailConnections = {} -- Track connections for each trail

-- Arrow configuration
local ARROW_HEIGHT_OFFSET = 8 -- Height above target
local ARROW_BOUNCE_AMOUNT = 2 -- How much the arrow bounces
local ARROW_BOUNCE_SPEED = 2 -- Speed of bounce animation
local UI_ARROW_OFFSET = 50 -- Offset from UI elements

-- Create a 2D billboard arrow pointing to a world position
function TutorialArrowManager.createWorldArrow(targetPosition, color)
    
    -- Clean up existing arrow
    TutorialArrowManager.cleanup()
    
    -- Create invisible anchor part for the main arrow
    local anchorPart = Instance.new("Part")
    anchorPart.Name = "MainArrowAnchor"
    anchorPart.Size = Vector3.new(0.1, 0.1, 0.1)
    anchorPart.Anchored = true
    anchorPart.CanCollide = false
    anchorPart.Transparency = 1
    anchorPart.Position = targetPosition + Vector3.new(0, ARROW_HEIGHT_OFFSET, 0)
    anchorPart.Parent = Workspace
    currentArrow = anchorPart
    
    -- Create billboard GUI for the main arrow
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "MainArrowBillboard"
    billboardGui.Size = UDim2.new(0, 150, 0, 150) -- Larger for main arrow
    billboardGui.StudsOffset = Vector3.new(0, 0, 0)
    billboardGui.Adornee = anchorPart
    billboardGui.Parent = anchorPart
    
    -- Create the main arrow using TextLabel
    local arrowText = Instance.new("TextLabel")
    arrowText.Name = "MainArrowText"
    arrowText.Size = UDim2.new(1, 0, 1, 0)
    arrowText.Position = UDim2.new(0, 0, 0, 0)
    arrowText.BackgroundTransparency = 1
    arrowText.Text = "⬇" -- Down arrow pointing to the plot
    arrowText.TextColor3 = Color3.fromRGB(255, 255, 50) -- Bright yellow for main arrow
    arrowText.TextScaled = true
    arrowText.Font = Enum.Font.GothamBold
    arrowText.TextStrokeTransparency = 0
    arrowText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    arrowText.Parent = billboardGui
    
    -- Create trail from player to target
    TutorialArrowManager.createTrail(targetPosition, color)
    
    
    -- Animate arrow bounce
    local startY = targetPosition.Y + ARROW_HEIGHT_OFFSET
    currentConnection = RunService.Heartbeat:Connect(function()
        if not currentArrow then return end
        
        local time = tick()
        local bounceOffset = math.sin(time * ARROW_BOUNCE_SPEED) * ARROW_BOUNCE_AMOUNT
        
        anchorPart.Position = Vector3.new(targetPosition.X, startY + bounceOffset, targetPosition.Z)
    end)
    
end

-- Create a trail from player to target position
function TutorialArrowManager.createTrail(targetPosition, color)
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    -- Create trail model
    local trailModel = Instance.new("Model")
    trailModel.Name = "TutorialTrail"
    trailModel.Parent = Workspace
    currentTrail = trailModel
    
    -- Get INITIAL player position (fixed, won't change)
    local rootPart = character.HumanoidRootPart
    local startPlayerPos = rootPart.Position - Vector3.new(0, rootPart.Size.Y/2 + 1, 0) -- At feet level
    local trailDirection = (targetPosition - startPlayerPos).Unit
    local trailDistance = (targetPosition - startPlayerPos).Magnitude
    
    -- Don't create trail if too close
    if trailDistance < 10 then
        return
    end
    
    -- Create a fixed number of dots with FIXED path
    local numDots = 15 -- Fixed number of dots
    
    -- Store dot update connections for proper cleanup
    local dotConnections = {}
    
    -- Create continuous flowing dots
    for i = 1, numDots do
        local dotModel = Instance.new("Model")
        dotModel.Name = "ConveyorDot_" .. i
        dotModel.Parent = currentTrail
        
        -- Create smaller yellow dot
        local dot = Instance.new("Part")
        dot.Name = "Dot"
        dot.Size = Vector3.new(1, 1, 1) -- Smaller dots
        dot.Shape = Enum.PartType.Ball
        dot.Material = Enum.Material.Neon
        dot.BrickColor = BrickColor.new("Bright yellow")
        dot.Anchored = true
        dot.CanCollide = false
        dot.Parent = dotModel
        
        -- Add glow effect
        local pointLight = Instance.new("PointLight")
        pointLight.Brightness = 1.5
        pointLight.Range = 6
        pointLight.Color = Color3.fromRGB(255, 255, 50)
        pointLight.Parent = dot
        
        -- Use RunService connection instead of spawn thread
        local dotIndex = i - 1 -- 0-based index
        local hoverOffset = dotIndex * 0.3 -- Stagger the hover timing
        
        local connection = RunService.Heartbeat:Connect(function()
            -- Check if dot still exists and character is valid
            if not dotModel.Parent or not character or not character:FindFirstChild("HumanoidRootPart") then
                return
            end
            
            -- Get current player position each frame
            local currentPlayerPos = character.HumanoidRootPart.Position - Vector3.new(0, character.HumanoidRootPart.Size.Y/2 + 1, 0)
            local currentDirection = (targetPosition - currentPlayerPos).Unit
            local currentDistance = (targetPosition - currentPlayerPos).Magnitude
            
            -- Skip if too close to target
            if currentDistance < 10 then
                dot.Transparency = 1 -- Hide dot
                return
            end
            
            -- Position dot at fixed location along the path (no movement)
            local progress = dotIndex / (numDots - 1) -- Evenly space from 0 to 1
            local basePosition = currentPlayerPos + (currentDirection * (progress * currentDistance))
            
            -- Add gentle up/down hover animation
            local hoverHeight = math.sin(tick() * 3 + hoverOffset) * 0.3 -- Gentle hover
            
            -- Set final position
            dot.Position = basePosition + Vector3.new(0, 1 + hoverHeight, 0)
            
            -- No transparency fading - just keep them visible
            dot.Transparency = 0
        end)
        
        -- Store connection for cleanup
        table.insert(dotConnections, connection)
    end
    
    -- Store connections in a way we can access them for cleanup
    -- Since we can't store arrays as attributes, we'll store them in a global variable
    if not currentTrail:FindFirstChild("ConnectionStorage") then
        local storage = Instance.new("ObjectValue")
        storage.Name = "ConnectionStorage"
        storage.Parent = currentTrail
    end
    
    -- Store the connections in our global cleanup system
    trailConnections[currentTrail] = dotConnections
    
end

-- Create a simple UI arrow next to a UI element (like another UI button)
function TutorialArrowManager.createUIArrow(screenPosition, direction, color)
    
    -- Clean up existing arrow
    TutorialArrowManager.cleanup()
    
    -- Create ScreenGui for the arrow
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TutorialArrowGui"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = player:WaitForChild("PlayerGui")
    
    -- Create arrow frame positioned next to the UI element
    local arrowFrame = Instance.new("Frame")
    arrowFrame.Name = "ArrowFrame"
    arrowFrame.Size = UDim2.new(0, 60, 0, 60)
    arrowFrame.BackgroundTransparency = 1
    arrowFrame.ZIndex = 1000
    arrowFrame.Parent = screenGui
    
    -- Create arrow text (using the same arrows as plot arrows)
    local arrowText = Instance.new("TextLabel")
    arrowText.Name = "ArrowText"
    arrowText.Size = UDim2.new(1, 0, 1, 0)
    arrowText.BackgroundTransparency = 1
    arrowText.TextColor3 = Color3.fromRGB(255, 255, 50) -- Bright yellow like plot arrows
    arrowText.TextScaled = true
    arrowText.Font = Enum.Font.GothamBold
    arrowText.TextStrokeTransparency = 0
    arrowText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    arrowText.TextStrokeThickness = 2
    arrowText.ZIndex = 1001
    arrowText.Parent = arrowFrame
    
    -- Position the arrow relative to the UI element and set direction
    local offset = 15 -- Distance from the UI element
    
    if direction == "up" then
        arrowFrame.Position = UDim2.new(0, screenPosition.X - 30, 0, screenPosition.Y - 60 - offset)
        arrowText.Text = "⬆"
    elseif direction == "down" then
        arrowFrame.Position = UDim2.new(0, screenPosition.X - 30, 0, screenPosition.Y + offset)
        arrowText.Text = "⬇"
    elseif direction == "left" then
        arrowFrame.Position = UDim2.new(0, screenPosition.X - 60 - offset, 0, screenPosition.Y - 30)
        arrowText.Text = "⬅"
    elseif direction == "right" then
        arrowFrame.Position = UDim2.new(0, screenPosition.X + offset, 0, screenPosition.Y - 30)
        arrowText.Text = "➡"
    else
        -- Default to right
        arrowFrame.Position = UDim2.new(0, screenPosition.X + offset, 0, screenPosition.Y - 30)
        arrowText.Text = "➡"
    end
    
    -- Animate arrow pulse (simple UI animation)
    local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
    arrowTween = TweenService:Create(arrowText, tweenInfo, {
        Size = UDim2.new(1.2, 0, 1.2, 0),
        Position = UDim2.new(-0.1, 0, -0.1, 0),
        TextColor3 = Color3.fromRGB(255, 200, 0) -- Pulse from yellow to orange
    })
    arrowTween:Play()
    
    currentArrow = screenGui
end

-- Point to a specific plot
function TutorialArrowManager.pointToPlot(plotId)
    local plotFound = false
    
    -- Search for the plot in the world
    for _, farmFolder in pairs(Workspace.PlayerFarms:GetChildren()) do
        -- Look in Plots subfolder for Model plots
        local plotsFolder = farmFolder:FindFirstChild("Plots")
        if plotsFolder then
            for _, plot in pairs(plotsFolder:GetChildren()) do
                if plot.Name == "Plot" .. plotId then
                    local PlotUtils = require(script.Parent.PlotUtils)
                    local interactionPart = PlotUtils.getPlotInteractionPart(plot)
                    local plotPosition = interactionPart and interactionPart.Position or plot.Position
                    TutorialArrowManager.createWorldArrow(plotPosition)
                    plotFound = true
                    break
                end
            end
        end
        
        -- Also check direct children for Part plots
        for _, plot in pairs(farmFolder:GetChildren()) do
            if plot.Name == "Plot_" .. plotId then
                local PlotUtils = require(script.Parent.PlotUtils)
                local interactionPart = PlotUtils.getPlotInteractionPart(plot)
                local plotPosition = interactionPart and interactionPart.Position or plot.Position
                TutorialArrowManager.createWorldArrow(plotPosition)
                plotFound = true
                break
            end
        end
        if plotFound then break end
    end
    
    if not plotFound then
        warn("Could not find plot", plotId, "to point to")
    end
end

-- Point to the closest unowned plot
function TutorialArrowManager.pointToClosestUnownedPlot()
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then 
        return false
    end
    
    -- Get player data from the global scope (set by init.client.lua)
    if not _G.currentPlayerData then
        return false
    end
    
    local playerData = _G.currentPlayerData
    local playerPos = character.HumanoidRootPart.Position
    
    -- Request farm ID from server instead of trying to find it by text matching
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local farmingRemotes = ReplicatedStorage:FindFirstChild("FarmingRemotes")
    if not farmingRemotes then
        return false
    end
    
    local getFarmIdRemote = farmingRemotes:FindFirstChild("GetFarmId")
    if not getFarmIdRemote then
        return false
    end
    
    -- Create a promise-like system to wait for the server response with timeout
    local farmIdReceived = false
    local playerFarmId = nil
    local connection = nil
    local startTime = tick() -- Record when we started waiting
    
    -- Set up timeout first
    local timeoutConnection = nil
    timeoutConnection = game:GetService("RunService").Heartbeat:Connect(function()
        -- Check if 5 seconds have passed
        if tick() - startTime > 5 then
            if timeoutConnection then
                timeoutConnection:Disconnect()
                timeoutConnection = nil
            end
            if connection then
                connection:Disconnect()
                connection = nil
            end
            if not farmIdReceived then
                farmIdReceived = true -- Stop waiting
            end
        end
    end)
    
    local startTime = tick()
    connection = getFarmIdRemote.OnClientEvent:Connect(function(farmId)
        playerFarmId = farmId
        farmIdReceived = true
        
        -- Clean up connections
        if connection then
            connection:Disconnect()
            connection = nil
        end
        if timeoutConnection then
            timeoutConnection:Disconnect()
            timeoutConnection = nil
        end
    end)
    
    -- Request the farm ID
    getFarmIdRemote:FireServer()
    
    -- Wait for response (max 5 seconds)
    local waitTime = 0
    while not farmIdReceived and waitTime < 5 do
        wait(0.1)
        waitTime = waitTime + 0.1
    end
    
    -- Final cleanup in case we exited the loop early
    if connection then
        connection:Disconnect()
        connection = nil
    end
    if timeoutConnection then
        timeoutConnection:Disconnect()
        timeoutConnection = nil
    end
    
    if not farmIdReceived or not playerFarmId then
        return false
    end
    
    -- Now find the farm in Workspace using the farm ID
    local playerFarm = Workspace.PlayerFarms:FindFirstChild("Farm_" .. playerFarmId)
    if not playerFarm then
        return false
    end
    
    -- Find the Plots folder within the farm
    local plotsFolder = playerFarm:FindFirstChild("Plots")
    if not plotsFolder then
        return false
    end
    
    local bestUnlockedEmptyPlot = nil
    local cheapestLockedPlot = nil
    local closestDistance = math.huge
    
    -- Function to check if plot is owned by player
    local function isPlotOwned(plotNumber)
        if not playerData.ownedPlots then return false end
        return playerData.ownedPlots[tostring(plotNumber)] == true
    end
    
    -- Function to check if plot has crops planted using player data
    local function isPlotEmpty(plotNumber)
        if not playerData.plots then return true end
        local plotData = playerData.plots[tostring(plotNumber)]
        return not plotData or plotData.state == "empty"
    end
    
    -- Function to get plot position from the model
    local function getPlotPosition(plotModel)
        -- Use the PlotUtils helper to get the interaction part
        local PlotUtils = require(script.Parent.PlotUtils)
        local interactionPart = PlotUtils.getPlotInteractionPart(plotModel)
        
        if interactionPart then
            return interactionPart.Position
        end
        
        -- Final fallback: use model center if it's a Model
        if plotModel:IsA("Model") then
            local cf, size = plotModel:GetBoundingBox()
            return cf.Position
        else
            -- If it's a Part, just use its position
            return plotModel.Position
        end
    end
    
    -- Function to get plot number for cost calculation
    local function getPlotNumber(plotName)
        local number = plotName:match("Plot(%d+)")
        return number and tonumber(number) or 999
    end
    
    for _, plot in pairs(plotsFolder:GetChildren()) do
        if (plot:IsA("Model") or plot:IsA("BasePart")) and plot.Name:match("^Plot") then
            local plotPosition = getPlotPosition(plot)
            local distance = (plotPosition - playerPos).Magnitude
            local plotNumber = getPlotNumber(plot.Name)
            local isOwned = isPlotOwned(plotNumber)
            local isEmpty = isPlotEmpty(plotNumber)
            
            -- Priority 1: Owned plots that are empty (closest one)
            if isOwned and isEmpty then
                if distance < closestDistance then
                    closestDistance = distance
                    bestUnlockedEmptyPlot = plot
                end
            elseif not isOwned then
                -- Priority 2: Unowned plots (cheapest = lowest number)
                if not cheapestLockedPlot or plotNumber < getPlotNumber(cheapestLockedPlot.Name) then
                    cheapestLockedPlot = plot
                end
            end
        end
    end
    
    -- Priority: 1) Owned empty plot, 2) Cheapest unowned plot
    local targetPlot = bestUnlockedEmptyPlot or cheapestLockedPlot
    
    if targetPlot then
        local targetPosition = getPlotPosition(targetPlot)
        TutorialArrowManager.createWorldArrow(targetPosition, "Bright yellow")
        return true
    else
        return false
    end
end

-- Point to a UI element by name
function TutorialArrowManager.pointToUIElement(elementPath, direction)
    -- Parse element path (e.g., "MainUI.LeftPanel.SellButton")
    local parts = string.split(elementPath, ".")
    local current = player:WaitForChild("PlayerGui")
    
    for i, part in ipairs(parts) do
        local nextCurrent = current:FindFirstChild(part)
        if not nextCurrent then
            return
        end
        current = nextCurrent
    end
    
    -- Get screen position
    local position = current.AbsolutePosition + (current.AbsoluteSize / 2)
    TutorialArrowManager.createUIArrow(
        Vector2.new(position.X, position.Y),
        direction or "up",
        Color3.fromRGB(255, 255, 50)
    )
end

-- Clean up current arrow
function TutorialArrowManager.cleanup()
    if currentConnection then
        currentConnection:Disconnect()
        currentConnection = nil
    end
    
    if trailConnection then
        trailConnection:Disconnect()
        trailConnection = nil
    end
    
    if arrowTween then
        arrowTween:Cancel()
        arrowTween = nil
    end
    
    if currentArrow then
        currentArrow:Destroy()
        currentArrow = nil
    end
    
    if currentTrail then
        -- Disconnect all dot update connections
        local dotConnections = trailConnections[currentTrail]
        if dotConnections then
            for _, connection in pairs(dotConnections) do
                if connection then
                    connection:Disconnect()
                end
            end
            -- Clear the reference
            trailConnections[currentTrail] = nil
        end
        
        -- Properly cleanup all dot models
        for _, child in pairs(currentTrail:GetChildren()) do
            if child:IsA("Model") then
                child:Destroy()
            end
        end
        currentTrail:Destroy()
        currentTrail = nil
    end
end

-- Update arrow for current tutorial step
function TutorialArrowManager.updateForTutorialStep(stepData)
    if not stepData or not stepData.arrowTarget then
        TutorialArrowManager.cleanup()
        return
    end
    
    local target = stepData.arrowTarget
    
    if target.type == "plot" then
        if target.plotId then
            TutorialArrowManager.pointToPlot(target.plotId)
        else
            -- Try immediately first
            local success = TutorialArrowManager.pointToClosestUnownedPlot()
            if not success then
                -- Retry mechanism for farm loading
                TutorialArrowManager.retryPointToUnownedPlot()
            end
        end
    elseif target.type == "ui" then
        TutorialArrowManager.pointToUIElement(target.element, target.direction)
    elseif target.type == "position" then
        TutorialArrowManager.createWorldArrow(target.position)
    end
end

-- Retry pointing to unowned plot with delays, waiting for player data sync
function TutorialArrowManager.retryPointToUnownedPlot()
    spawn(function()
        -- First, wait for character to spawn
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)
        
        if not humanoidRootPart then
            return
        end
        
        -- Wait for player data sync (this indicates farm assignment is complete)
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local farmingRemotes = ReplicatedStorage:WaitForChild("FarmingRemotes")
        local syncRemote = farmingRemotes:WaitForChild("SyncPlayerData")
        
        -- Wait for first data sync after character spawn with proper timeout handling
        local dataSynced = false
        local connection = nil
        local timeoutConnection = nil
        
        -- Set up timeout using RunService connection instead of spawn
        local startTime = tick()
        timeoutConnection = game:GetService("RunService").Heartbeat:Connect(function()
            if tick() - startTime > 30 then -- 30 second timeout
                if not dataSynced then
                    dataSynced = true -- Prevent further processing
                end
                
                -- Clean up connections
                if connection then
                    connection:Disconnect()
                    connection = nil
                end
                if timeoutConnection then
                    timeoutConnection:Disconnect()
                    timeoutConnection = nil
                end
            end
        end)
        
        connection = syncRemote.OnClientEvent:Connect(function(playerData)
            if not dataSynced and playerData and not playerData.loading then
                dataSynced = true
                
                -- Clean up connections first
                if connection then
                    connection:Disconnect()
                    connection = nil
                end
                if timeoutConnection then
                    timeoutConnection:Disconnect()
                    timeoutConnection = nil
                end
                
                -- Small delay to ensure everything is fully loaded
                wait(1)
                
                local attempts = 0
                local maxAttempts = 10 -- More attempts for better reliability
                
                local function tryPointing()
                    attempts = attempts + 1
                    
                    local success = TutorialArrowManager.pointToClosestUnownedPlot()
                    if not success and attempts < maxAttempts then
                        -- Wait 2 seconds and try again (more time for farm creation)
                        wait(2)
                        tryPointing()
                    elseif not success then
                        -- One final attempt after longer delay
                        wait(5)
                        TutorialArrowManager.pointToClosestUnownedPlot()
                    end
                end
                
                tryPointing()
            end
        end)
    end)
end

return TutorialArrowManager