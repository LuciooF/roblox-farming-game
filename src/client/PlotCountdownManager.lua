-- Client-side Plot Countdown Manager
-- Handles smooth countdown displays with client-side prediction
-- Reduces server load and eliminates network lag in countdowns

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local ClientLogger = require(script.Parent.ClientLogger)
local PlotUtils = require(script.Parent.PlotUtils)
local log = ClientLogger.getModuleLogger("PlotCountdowns")

local PlotCountdownManager = {}

-- Storage for plot timing data
local plotTimers = {} -- [plotId] = {startTime, growthTime, waterTime, state, seedType}
local countdownConnections = {} -- [plotId] = RBXScriptConnection
local masterUpdateConnection = nil -- Single connection for all plots
local plotsNeedingUpdate = {} -- Set of plotIds that need display updates

-- Initialize countdown manager
function PlotCountdownManager.initialize()
    log.info("Client-side plot countdown system initialized")
    
    -- Start master update loop (single connection for all plots)
    PlotCountdownManager.startMasterUpdateLoop()
    
    -- Initialize existing plots in the world
    PlotCountdownManager.scanExistingPlots()
end

-- Scan for existing plots and set them to empty state
function PlotCountdownManager.scanExistingPlots()
    local farmsContainer = Workspace:FindFirstChild("PlayerFarms")
    if not farmsContainer then 
        log.warn("No PlayerFarms found in Workspace")
        return 
    end
    
    -- Debug: List what's actually in the PlayerFarms
    log.info("PlayerFarms contents:")
    for _, child in pairs(farmsContainer:GetChildren()) do
        log.info("- " .. child.Name .. " (" .. child.ClassName .. ")")
    end
    
    -- Scan all individual farms for plots
    local totalPlotCount = 0
    for _, farmFolder in pairs(farmsContainer:GetChildren()) do
        if farmFolder.Name:match("^Farm_") then
            local farmId = farmFolder.Name:match("Farm_(%d+)")
            log.info("Scanning", farmFolder.Name, "for plots")
            
            local farmPlotCount = 0
            for _, child in pairs(farmFolder:GetChildren()) do
                local plotIdValue = child:FindFirstChild("PlotId")
                if plotIdValue then
                    local plotId = plotIdValue.Value
                    farmPlotCount = farmPlotCount + 1
                    
                    -- Initialize with empty state until server sends actual data
                    PlotCountdownManager.updatePlotData(plotId, {
                        state = "empty",
                        plantedAt = 0,
                        lastWateredAt = 0,
                        growthTime = 60,
                        waterTime = 30,
                        deathTime = 120,
                        seedType = "",
                        variation = "normal",
                        isOwner = false -- Will be updated when server sends real data
                    })
                end
            end
            
            if farmPlotCount > 0 then
                log.info("Found", farmPlotCount, "plots in", farmFolder.Name)
                totalPlotCount = totalPlotCount + farmPlotCount
            end
        end
    end
    
    log.info("Initialized", totalPlotCount, "total plots across all farms")
end

-- Initialize plots in a container (Farm or Plots folder)
function PlotCountdownManager.initializePlotsInContainer(container)
    local plotCount = 0
    for _, plot in pairs(container:GetChildren()) do
        local plotIdValue = plot:FindFirstChild("PlotId")
        if plotIdValue then
            local plotId = plotIdValue.Value
            plotCount = plotCount + 1
            
            -- Initialize with empty state until server sends actual data
            PlotCountdownManager.updatePlotData(plotId, {
                state = "empty",
                plantedAt = 0,
                lastWateredAt = 0,
                growthTime = 60,
                waterTime = 30,
                deathTime = 120,
                seedType = "",
                variation = "normal"
            })
        end
    end
    
    log.info("Initialized", plotCount, "plots in container")
end

-- Update plot timing data when server sends state changes
function PlotCountdownManager.updatePlotData(plotId, plotData)
    local currentTime = tick()
    
    log.info("Received plot update for plot", plotId, "state:", plotData.state, "seedType:", plotData.seedType or "none", "isOwner:", plotData.isOwner)
    
    -- Store plot timing information
    plotTimers[plotId] = {
        startTime = plotData.plantedAt or currentTime,
        growthTime = plotData.growthTime or 60, -- Default 60 seconds
        waterTime = plotData.waterTime or 30, -- Default 30 seconds  
        deathTime = plotData.deathTime or 120, -- Default 120 seconds
        state = plotData.state or "empty",
        seedType = plotData.seedType or "",
        lastWateredAt = plotData.lastWateredAt or 0,
        variation = plotData.variation or "normal",
        isOwner = plotData.isOwner or false,
        ownerName = plotData.ownerName
    }
    
    log.debug("Updated plot", plotId, "data:", plotData.state, plotData.seedType, "owner:", plotData.ownerName or "none")
    
    -- Only start countdown for owned plots
    if plotData.isOwner then
        PlotCountdownManager.startCountdown(plotId)
    else
        PlotCountdownManager.stopCountdown(plotId)
    end
end

-- Start master update loop (single connection for all plots)
function PlotCountdownManager.startMasterUpdateLoop()
    if masterUpdateConnection then
        return -- Already running
    end
    
    -- Single connection that updates all plots efficiently
    masterUpdateConnection = RunService.Heartbeat:Connect(function()
        PlotCountdownManager.updateAllCountdowns()
    end)
    
    log.debug("Started master countdown update loop")
end

-- Update all plot countdowns in a single loop
function PlotCountdownManager.updateAllCountdowns()
    local Players = game:GetService("Players")
    local localPlayer = Players.LocalPlayer
    
    -- Get player position for distance checking
    local playerPosition = nil
    if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
        playerPosition = localPlayer.Character.HumanoidRootPart.Position
    end
    
    for plotId, plotData in pairs(plotTimers) do
        local plot = PlotUtils.findPlotById(plotId)
        if plot then
            local countdownGui = plot:FindFirstChild("CountdownDisplay")
            local countdownLabel = countdownGui and countdownGui:FindFirstChild("TextLabel")
            if countdownLabel then
                -- Check distance before updating UI
                local shouldShowUI = PlotCountdownManager.shouldShowUIForPlot(plot, plotData, playerPosition)
                
                if shouldShowUI then
                    countdownGui.Enabled = true
                    PlotCountdownManager.updateCountdownDisplay(plotId, countdownLabel)
                else
                    countdownGui.Enabled = false -- Hide UI when too far away
                    countdownLabel.Visible = false -- Also ensure label is hidden
                    countdownLabel.Text = "" -- Clear any text
                end
            end
        end
    end
end

-- Determine if UI should be shown for a plot based on distance and ownership
function PlotCountdownManager.shouldShowUIForPlot(plot, plotData, playerPosition)
    if not playerPosition then
        return false -- No player position available
    end
    
    local plotPosition = plot.Position
    local distance = (playerPosition - plotPosition).Magnitude
    local maxDistance = 50 -- Maximum distance to show UI
    
    -- Always show UI for owned plots within range
    if plotData.isOwner and distance <= maxDistance then
        return true
    end
    
    -- For non-owned plots, only show if very close and has something interesting (NOT empty)
    if not plotData.isOwner then
        local closeDistance = 20 -- Closer range for other players' plots
        if distance <= closeDistance and plotData.state ~= "empty" and plotData.seedType ~= "" then
            return true -- Only show other players' crops when close AND they have actual crops
        end
    end
    
    return false -- Don't show anything for empty plots or distant plots
end

-- Start countdown display for a specific plot
function PlotCountdownManager.startCountdown(plotId)
    -- No longer need individual connections - master loop handles all plots
    plotsNeedingUpdate[plotId] = true
    log.debug("Added plot", plotId, "to update queue")
end

-- Stop countdown for a specific plot
function PlotCountdownManager.stopCountdown(plotId)
    plotsNeedingUpdate[plotId] = nil
    log.debug("Removed plot", plotId, "from update queue")
end

-- Update countdown display for a plot (called every frame)
function PlotCountdownManager.updateCountdownDisplay(plotId, countdownLabel)
    local plotData = plotTimers[plotId]
    if not plotData then return end
    
    -- If not owner, show different display
    if not plotData.isOwner then
        PlotCountdownManager.updateNonOwnerDisplay(plotId, countdownLabel, plotData)
        return
    end
    
    local currentTime = tick()
    local state = plotData.state
    
    if state == "empty" then
        countdownLabel.Text = ""
        countdownLabel.Visible = false  -- Hide text for empty plots
        
    elseif state == "planted" then
        -- Calculate time until needs water and death time
        countdownLabel.Visible = true
        local timeSincePlanted = currentTime - plotData.startTime
        local timeUntilWater = plotData.waterTime - timeSincePlanted
        local timeUntilDeath = plotData.deathTime - timeSincePlanted
        
        if timeUntilWater > 0 then
            countdownLabel.Text = "Water in: " .. PlotCountdownManager.formatTime(timeUntilWater)
            countdownLabel.TextColor3 = Color3.fromRGB(100, 200, 255) -- Light blue
        elseif timeUntilDeath > 0 then
            countdownLabel.Text = "Dies in: " .. PlotCountdownManager.formatTime(timeUntilDeath)
            countdownLabel.TextColor3 = Color3.fromRGB(255, 100, 100) -- Red
        else
            countdownLabel.Text = "Dead!"
            countdownLabel.TextColor3 = Color3.fromRGB(120, 50, 50) -- Dark red
        end
        
    elseif state == "watered" then
        -- Calculate time until ready to harvest
        countdownLabel.Visible = true
        local timeSinceWatered = currentTime - plotData.lastWateredAt
        local timeUntilReady = plotData.growthTime - timeSinceWatered
        
        if timeUntilReady > 0 then
            local baseText = "Ready in: " .. PlotCountdownManager.formatTime(timeUntilReady)
            
            -- Add harvest count if available and enabled
            if plotData.harvestCount and plotData.maxHarvests and plotData.maxHarvests > 0 then
                local harvestsLeft = plotData.maxHarvests - plotData.harvestCount
                baseText = baseText .. " (" .. harvestsLeft .. " left)"
            end
            
            countdownLabel.Text = baseText
            countdownLabel.TextColor3 = Color3.fromRGB(100, 255, 100) -- Green
        else
            local baseText = "Ready to Harvest!"
            
            -- Add harvest count if available and enabled
            if plotData.harvestCount and plotData.maxHarvests and plotData.maxHarvests > 0 then
                local harvestsLeft = plotData.maxHarvests - plotData.harvestCount
                baseText = baseText .. " (" .. harvestsLeft .. " left)"
            end
            
            countdownLabel.Text = baseText
            countdownLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
        end
        
    elseif state == "ready" then
        countdownLabel.Visible = true
        local baseText = "Ready to Harvest!"
        
        -- Add harvest count if available and enabled
        if plotData.harvestCount and plotData.maxHarvests and plotData.maxHarvests > 0 then
            local harvestsLeft = plotData.maxHarvests - plotData.harvestCount
            baseText = baseText .. " (" .. harvestsLeft .. " left)"
        end
        
        countdownLabel.Text = baseText
        countdownLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
        
    else
        -- For any unknown state, hide the text instead of showing the raw state name
        countdownLabel.Text = ""
        countdownLabel.Visible = false
    end
end

-- Update display for non-owned plots (no countdown, just basic info)
function PlotCountdownManager.updateNonOwnerDisplay(plotId, countdownLabel, plotData)
    local state = plotData.state
    local ownerName = plotData.ownerName or "Someone"
    
    if state == "empty" then
        countdownLabel.Text = ""  -- Completely hide text for empty non-owned plots
        countdownLabel.Visible = false  -- Make sure it's truly invisible
    else
        -- Show basic status without revealing timing details
        countdownLabel.Visible = true  -- Make sure it's visible for crops
        local seedType = plotData.seedType
        if state == "planted" or state == "watered" then
            countdownLabel.Text = seedType  -- Just show the crop type, not the owner
            countdownLabel.TextColor3 = Color3.fromRGB(200, 200, 200) -- Gray
        elseif state == "ready" then
            countdownLabel.Text = seedType .. " (Ready)"
            countdownLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
        else
            countdownLabel.Text = (seedType ~= "" and seedType or "crop")
            countdownLabel.TextColor3 = Color3.fromRGB(200, 200, 200) -- Gray
        end
    end
end

-- Format time in MM:SS format
function PlotCountdownManager.formatTime(seconds)
    if seconds < 0 then
        return "00:00"
    end
    
    local minutes = math.floor(seconds / 60)
    local remainingSeconds = math.floor(seconds % 60)
    return string.format("%02d:%02d", minutes, remainingSeconds)
end


-- Clean up countdown for a plot (when plot is removed)
function PlotCountdownManager.cleanupPlot(plotId)
    PlotCountdownManager.stopCountdown(plotId)
    plotTimers[plotId] = nil
    log.debug("Cleaned up plot", plotId)
end

-- Clean up all countdowns (on player leave)
function PlotCountdownManager.cleanup()
    -- Disconnect master update loop
    if masterUpdateConnection then
        masterUpdateConnection:Disconnect()
        masterUpdateConnection = nil
    end
    
    -- Clear all data
    plotTimers = {}
    plotsNeedingUpdate = {}
    countdownConnections = {}
    
    log.info("Cleaned up all plot countdowns and master update loop")
end

-- Handle plot state updates from server
function PlotCountdownManager.onPlotStateUpdate(plotId, newState, additionalData)
    local plotData = plotTimers[plotId]
    if not plotData then
        log.warn("Received state update for unknown plot", plotId)
        return
    end
    
    local currentTime = tick()
    
    -- Update state and timing based on new state
    plotData.state = newState
    
    if newState == "planted" then
        plotData.startTime = additionalData.plantedAt or currentTime
        plotData.seedType = additionalData.seedType or plotData.seedType
        
    elseif newState == "watered" then
        plotData.lastWateredAt = additionalData.wateredAt or currentTime
        
    elseif newState == "ready" then
        -- Plant is ready, stop growth calculations
        
    elseif newState == "empty" then
        -- Plot is empty, reset data
        plotData.seedType = ""
        plotData.lastWateredAt = 0
    end
    
    log.debug("Plot", plotId, "state updated to", newState)
end

return PlotCountdownManager