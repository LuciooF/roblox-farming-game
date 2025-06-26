-- Tutorial Arrow Manager
-- Creates and manages 3D arrows pointing to tutorial objectives

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local ClientLogger = require(script.Parent.ClientLogger)
local log = ClientLogger.getModuleLogger("TutorialArrowManager")

local TutorialArrowManager = {}

-- State
local currentArrow = nil
local currentConnection = nil
local arrowTween = nil
local currentTrail = nil
local trailConnection = nil

-- Arrow configuration
local ARROW_HEIGHT_OFFSET = 8 -- Height above target
local ARROW_BOUNCE_AMOUNT = 2 -- How much the arrow bounces
local ARROW_BOUNCE_SPEED = 2 -- Speed of bounce animation
local UI_ARROW_OFFSET = 50 -- Offset from UI elements

-- Create a 2D billboard arrow pointing to a world position
function TutorialArrowManager.createWorldArrow(targetPosition, color)
    log.warn("🎯 Creating world arrow at position:", targetPosition, "color:", color or "Lime green")
    
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
    
    log.warn("🎯 2D Billboard arrow created successfully!")
    
    -- Animate arrow bounce
    local startY = targetPosition.Y + ARROW_HEIGHT_OFFSET
    currentConnection = RunService.Heartbeat:Connect(function()
        if not currentArrow then return end
        
        local time = tick()
        local bounceOffset = math.sin(time * ARROW_BOUNCE_SPEED) * ARROW_BOUNCE_AMOUNT
        
        anchorPart.Position = Vector3.new(targetPosition.X, startY + bounceOffset, targetPosition.Z)
    end)
    
    log.warn("🎯 Arrow animation started successfully!")
end

-- Create a trail from player to target position
function TutorialArrowManager.createTrail(targetPosition, color)
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        log.warn("🎯 No character for trail creation")
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
        
        -- Create simple static dots that just hover up and down
        spawn(function()
            local dotIndex = i - 1 -- 0-based index
            local hoverOffset = dotIndex * 0.3 -- Stagger the hover timing
            
            while dotModel.Parent and character and character:FindFirstChild("HumanoidRootPart") do
                -- Get current player position each frame
                local currentPlayerPos = character.HumanoidRootPart.Position - Vector3.new(0, character.HumanoidRootPart.Size.Y/2 + 1, 0)
                local currentDirection = (targetPosition - currentPlayerPos).Unit
                local currentDistance = (targetPosition - currentPlayerPos).Magnitude
                
                -- Skip if too close to target
                if currentDistance < 10 then
                    dot.Transparency = 1 -- Hide dot
                    RunService.Heartbeat:Wait()
                    continue
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
                
                RunService.Heartbeat:Wait()
            end
        end)
    end
    
    log.warn("🎯 Trail created with dynamic player following")
end

-- Create a simple UI arrow next to a UI element (like another UI button)
function TutorialArrowManager.createUIArrow(screenPosition, direction, color)
    log.warn("🎯 Creating simple UI arrow next to inventory button at:", screenPosition, "direction:", direction)
    
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
    log.warn("🎯 Simple UI arrow created successfully next to inventory button!")
end

-- Point to a specific plot
function TutorialArrowManager.pointToPlot(plotId)
    local plotFound = false
    
    -- Search for the plot in the world
    for _, farmFolder in pairs(Workspace.PlayerFarms:GetChildren()) do
        for _, plot in pairs(farmFolder:GetChildren()) do
            if plot.Name == "Plot_" .. plotId then
                TutorialArrowManager.createWorldArrow(plot.Position)
                plotFound = true
                break
            end
        end
        if plotFound then break end
    end
    
    if not plotFound then
        log.warn("Could not find plot", plotId, "to point to")
    end
end

-- Point to the closest unowned plot
function TutorialArrowManager.pointToClosestUnownedPlot()
    log.warn("🎯 Looking for closest unowned plot...")
    
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then 
        log.warn("🎯 No character or HumanoidRootPart found")
        return false
    end
    
    local playerPos = character.HumanoidRootPart.Position
    
    -- Request farm ID from server instead of trying to find it by text matching
    log.warn("🎯 Requesting farm ID from server...")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local farmingRemotes = ReplicatedStorage:FindFirstChild("FarmingRemotes")
    if not farmingRemotes then
        log.warn("🎯 FarmingRemotes not found")
        return false
    end
    
    local getFarmIdRemote = farmingRemotes:FindFirstChild("GetFarmId")
    if not getFarmIdRemote then
        log.warn("🎯 GetFarmId remote not found")
        return false
    end
    
    -- Create a promise-like system to wait for the server response
    local farmIdReceived = false
    local playerFarmId = nil
    
    local connection = getFarmIdRemote.OnClientEvent:Connect(function(farmId)
        log.warn("🎯 Received farm ID from server:", farmId)
        playerFarmId = farmId
        farmIdReceived = true
    end)
    
    -- Request the farm ID
    getFarmIdRemote:FireServer()
    
    -- Wait for response (max 5 seconds)
    local waitTime = 0
    while not farmIdReceived and waitTime < 5 do
        wait(0.1)
        waitTime = waitTime + 0.1
    end
    
    connection:Disconnect()
    
    if not farmIdReceived or not playerFarmId then
        log.warn("🎯 Failed to get farm ID from server")
        return false
    end
    
    -- Now find the farm in Workspace using the farm ID
    local playerFarm = Workspace.PlayerFarms:FindFirstChild("Farm_" .. playerFarmId)
    if not playerFarm then
        log.warn("🎯 Could not find farm in Workspace: Farm_" .. playerFarmId)
        return false
    end
    
    log.warn("🎯 Found player's farm:", playerFarm.Name)
    
    -- Find the Plots folder within the farm
    local plotsFolder = playerFarm:FindFirstChild("Plots")
    if not plotsFolder then
        log.warn("🎯 No Plots folder found in farm!")
        return false
    end
    
    -- Find closest unowned plot (specifically prioritize Plot_1 for first plot tutorial)
    log.warn("🎯 Searching for unowned plots in Plots folder...")
    local plotNames = {}
    for _, plot in pairs(plotsFolder:GetChildren()) do
        table.insert(plotNames, plot.Name)
    end
    log.warn("🎯 All plots in farm:", table.concat(plotNames, ", "))
    
    local plot1 = nil -- Special handling for first plot
    local closestPlot = nil
    local closestDistance = math.huge
    
    for _, plot in pairs(plotsFolder:GetChildren()) do
        if plot.Name:match("^Plot") then -- Changed from "^Plot_" to "^Plot" since plots are named "Plot1", "Plot2", etc.
            log.warn("🎯 Found plot:", plot.Name, "color:", plot.BrickColor.Name, "position:", plot.Position)
            
            -- Special case: Always prioritize Plot1 for the first plot tutorial
            if plot.Name == "Plot1" then -- Changed from "Plot_1" to "Plot1"
                log.warn("🎯 Found Plot1! Color:", plot.BrickColor.Name, "Expected: Bright red")
                if plot.BrickColor == BrickColor.new("Bright red") then
                    plot1 = plot
                    log.warn("🎯 Plot1 is red - using as target!")
                    break
                else
                    log.warn("🎯 Plot1 is not red, checking if it should get an arrow anyway...")
                    -- For tutorial, point to Plot1 regardless of color for "first plot" step
                    plot1 = plot
                    log.warn("🎯 Using Plot1 regardless of color for tutorial!")
                    break
                end
            end
            
            -- Check if plot is locked (red)
            if plot.BrickColor == BrickColor.new("Bright red") then
                local distance = (plot.Position - playerPos).Magnitude
                log.warn("🎯 Red plot found:", plot.Name, "distance:", distance)
                if distance < closestDistance then
                    closestDistance = distance
                    closestPlot = plot
                end
            end
        end
    end
    
    -- Use Plot_1 if found, otherwise use closest
    local targetPlot = plot1 or closestPlot
    
    if targetPlot then
        log.warn("🎯 Creating arrow for plot:", targetPlot.Name, "at position:", targetPlot.Position)
        TutorialArrowManager.createWorldArrow(targetPlot.Position, "Bright yellow")
        return true
    else
        log.warn("🎯 No unowned (red) plots found!")
        return false
    end
end

-- Point to a UI element by name
function TutorialArrowManager.pointToUIElement(elementPath, direction)
    log.warn("🎯 Attempting to point to UI element:", elementPath)
    
    -- Parse element path (e.g., "MainUI.LeftPanel.SellButton")
    local parts = string.split(elementPath, ".")
    local current = player:WaitForChild("PlayerGui")
    
    log.warn("🎯 Starting search in PlayerGui")
    log.warn("🎯 PlayerGui children:", table.concat((function()
        local names = {}
        for _, child in pairs(current:GetChildren()) do
            table.insert(names, child.Name)
        end
        return names
    end)(), ", "))
    
    for i, part in ipairs(parts) do
        log.warn("🎯 Looking for part", i, ":", part, "in", current.Name)
        local nextCurrent = current:FindFirstChild(part)
        if not nextCurrent then
            log.warn("🎯 Could not find UI element part:", part, "in", current.Name)
            log.warn("🎯 Available children:", table.concat((function()
                local names = {}
                for _, child in pairs(current:GetChildren()) do
                    table.insert(names, child.Name)
                end
                return names
            end)(), ", "))
            return
        end
        current = nextCurrent
        log.warn("🎯 Found:", current.Name, "- continuing search")
    end
    
    log.warn("🎯 Successfully found UI element:", current.Name, "at position:", current.AbsolutePosition)
    
    -- Get screen position
    local position = current.AbsolutePosition + (current.AbsoluteSize / 2)
    TutorialArrowManager.createUIArrow(
        Vector2.new(position.X, position.Y),
        direction or "up",
        Color3.fromRGB(255, 255, 50)
    )
    
    log.warn("🎯 UI arrow created successfully!")
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
        -- Properly cleanup all dots and their spawn threads
        for _, child in pairs(currentTrail:GetChildren()) do
            if child:IsA("Model") then
                -- This will also clean up the spawn threads when the model is destroyed
                child:Destroy()
            end
        end
        currentTrail:Destroy()
        currentTrail = nil
    end
    
    log.warn("🎯 Tutorial arrows and trail cleaned up")
end

-- Update arrow for current tutorial step
function TutorialArrowManager.updateForTutorialStep(stepData)
    log.warn("🎯 TutorialArrowManager.updateForTutorialStep called with:", stepData)
    
    if not stepData or not stepData.arrowTarget then
        log.warn("🎯 No arrow target data, cleaning up arrows")
        TutorialArrowManager.cleanup()
        return
    end
    
    local target = stepData.arrowTarget
    log.warn("🎯 Arrow target:", target.type, "plotId:", target.plotId, "element:", target.element)
    
    if target.type == "plot" then
        if target.plotId then
            log.warn("🎯 Pointing to specific plot:", target.plotId)
            TutorialArrowManager.pointToPlot(target.plotId)
        else
            log.warn("🎯 Pointing to closest unowned plot")
            -- Try immediately first
            local success = TutorialArrowManager.pointToClosestUnownedPlot()
            if not success then
                log.warn("🎯 Immediate attempt failed, starting retry mechanism...")
                -- Retry mechanism for farm loading
                TutorialArrowManager.retryPointToUnownedPlot()
            else
                log.warn("🎯 Immediate attempt succeeded!")
            end
        end
    elseif target.type == "ui" then
        log.warn("🎯 Pointing to UI element:", target.element, "direction:", target.direction)
        TutorialArrowManager.pointToUIElement(target.element, target.direction)
    elseif target.type == "position" then
        log.warn("🎯 Pointing to world position:", target.position)
        TutorialArrowManager.createWorldArrow(target.position)
    else
        log.warn("🎯 Unknown arrow target type:", target.type)
    end
end

-- Retry pointing to unowned plot with delays, waiting for player data sync
function TutorialArrowManager.retryPointToUnownedPlot()
    spawn(function()
        -- First, wait for character to spawn
        log.warn("🎯 Waiting for character to spawn before looking for farm...")
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)
        
        if not humanoidRootPart then
            log.warn("🎯 Failed to get HumanoidRootPart, cannot create arrows")
            return
        end
        
        -- Wait for player data sync (this indicates farm assignment is complete)
        log.warn("🎯 Character spawned, waiting for player data sync to indicate farm assignment...")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local farmingRemotes = ReplicatedStorage:WaitForChild("FarmingRemotes")
        local syncRemote = farmingRemotes:WaitForChild("SyncPlayerData")
        
        -- Wait for first data sync after character spawn
        local dataSynced = false
        local connection = syncRemote.OnClientEvent:Connect(function(playerData)
            if not dataSynced and playerData and not playerData.loading then
                dataSynced = true
                log.warn("🎯 Player data synced! Farm should now be assigned. Looking for arrows...")
                
                -- Small delay to ensure everything is fully loaded
                wait(1)
                
                local attempts = 0
                local maxAttempts = 10 -- More attempts for better reliability
                
                local function tryPointing()
                    attempts = attempts + 1
                    log.warn("🎯 Retry attempt", attempts, "of", maxAttempts, "(after data sync)")
                    
                    -- First check if farms exist in workspace
                    local playerFarms = workspace:FindFirstChild("PlayerFarms")
                    if playerFarms then
                        local farmCount = #playerFarms:GetChildren()
                        log.warn("🎯 Found", farmCount, "farms in PlayerFarms")
                    else
                        log.warn("🎯 PlayerFarms folder not found yet")
                    end
                    
                    local success = TutorialArrowManager.pointToClosestUnownedPlot()
                    if not success and attempts < maxAttempts then
                        -- Wait 2 seconds and try again (more time for farm creation)
                        wait(2)
                        tryPointing()
                    elseif not success then
                        log.warn("🎯 Failed to create arrow after", maxAttempts, "attempts (after data sync)")
                        -- One final attempt after longer delay
                        wait(5)
                        log.warn("🎯 Final attempt after longer delay...")
                        TutorialArrowManager.pointToClosestUnownedPlot()
                    else
                        log.warn("🎯 Successfully created arrow on attempt", attempts)
                    end
                end
                
                tryPointing()
            end
        end)
        
        -- Timeout after 30 seconds in case data sync never comes
        spawn(function()
            wait(30)
            if not dataSynced then
                connection:Disconnect()
                log.warn("🎯 Timeout waiting for player data sync, giving up on arrows")
            end
        end)
    end)
end

return TutorialArrowManager