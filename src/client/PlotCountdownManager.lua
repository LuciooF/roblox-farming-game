-- Client-side Plot Countdown Manager
-- Handles smooth countdown displays with client-side prediction
-- Reduces server load and eliminates network lag in countdowns

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local PlotUtils = require(script.Parent.PlotUtils)

-- Simple logging functions for PlotCountdownManager
local function logInfo(...) print("[INFO] PlotCountdownManager:", ...) end
local function logDebug(...) print("[DEBUG] PlotCountdownManager:", ...) end

local PlotCountdownManager = {}

-- Storage for plot timing data
local plotTimers = {} -- [plotId] = {startTime, growthTime, waterTime, state, seedType}
local countdownConnections = {} -- [plotId] = RBXScriptConnection
local masterUpdateConnection = nil -- Single connection for all plots
local plotsNeedingUpdate = {} -- Set of plotIds that need display updates

-- Initialize countdown manager
function PlotCountdownManager.initialize()
    
    -- Start master update loop (single connection for all plots)
    PlotCountdownManager.startMasterUpdateLoop()
    
    -- Initialize existing plots in the world
    PlotCountdownManager.scanExistingPlots()
    
    -- Set up remote event listener for clearing all plot displays (used during rebirth)
    PlotCountdownManager.setupClearDisplaysRemote()
end

-- Set up remote event listener for clearing all plot displays
function PlotCountdownManager.setupClearDisplaysRemote()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local farmingRemotes = ReplicatedStorage:WaitForChild("FarmingRemotes")
    local clearPlotsRemote = farmingRemotes:WaitForChild("ClearAllPlotDisplays")
    
    clearPlotsRemote.OnClientEvent:Connect(function()
        logInfo("Clearing all plot displays after rebirth")
        PlotCountdownManager.clearAllDisplays()
    end)
    logDebug("Set up ClearAllPlotDisplays remote listener")
end

-- Clear all plot countdown displays and reset data
function PlotCountdownManager.clearAllDisplays()
    -- Clear all plot timer data
    plotTimers = {}
    
    -- Clear all countdown connections
    for plotId, connection in pairs(countdownConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    countdownConnections = {}
    
    -- Clear plots needing update
    plotsNeedingUpdate = {}
    
    -- Find and clear all countdown displays in the world
    local farmsContainer = Workspace:FindFirstChild("PlayerFarms")
    if farmsContainer then
        for _, farmFolder in pairs(farmsContainer:GetChildren()) do
            if farmFolder.Name:match("^Farm_") then
                for _, child in pairs(farmFolder:GetDescendants()) do
                    local countdownGui = child:FindFirstChild("CountdownDisplay")
                    if countdownGui then
                        countdownGui.Enabled = false
                        local textLabel = countdownGui:FindFirstChild("TextLabel")
                        if textLabel then
                            textLabel.Text = ""
                            textLabel.Visible = false
                        end
                    end
                end
            end
        end
    end
    
    logInfo("Cleared all plot displays and reset countdown manager")
end

-- Scan for existing plots and set them to empty state
function PlotCountdownManager.scanExistingPlots()
    local farmsContainer = Workspace:FindFirstChild("PlayerFarms")
    if not farmsContainer then 
        return 
    end
    
    
    -- Scan all individual farms for plots
    local totalPlotCount = 0
    for _, farmFolder in pairs(farmsContainer:GetChildren()) do
        if farmFolder.Name:match("^Farm_") then
            local farmId = farmFolder.Name:match("Farm_(%d+)")
            
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
                logInfo("Found", farmPlotCount, "plots in", farmFolder.Name)
                totalPlotCount = totalPlotCount + farmPlotCount
            end
        end
    end
    
    if totalPlotCount > 0 then
        logInfo("Initialized", totalPlotCount, "total plots across all farms")
    else
        logDebug("No existing plots found - will initialize when player is assigned a farm")
    end
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
    
    logInfo("Initialized", plotCount, "plots in container")
end

-- Update plot timing data when server sends state changes
function PlotCountdownManager.updatePlotData(plotId, plotData)
    local currentTime = tick()
    
    
    -- Check if this is a harvest (harvestCount increased)
    local previousData = plotTimers[plotId]
    local wasHarvested = false
    if previousData and previousData.harvestCount and plotData.harvestCount then
        if plotData.harvestCount > previousData.harvestCount then
            wasHarvested = true
            logDebug("Plot", plotId, "was harvested - resetting firstReadyTime")
        end
    end
    
    -- Store plot timing information (preserve firstReadyTime unless harvest occurred)
    local existingFirstReadyTime = nil
    if previousData and not wasHarvested then
        existingFirstReadyTime = previousData.firstReadyTime
    end
    
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
        ownerName = plotData.ownerName,
        harvestCount = plotData.harvestCount or 0,
        maxHarvests = plotData.maxHarvests or 0,
        accumulatedCrops = plotData.accumulatedCrops or 0,
        wateredCount = plotData.wateredCount or 0,
        waterNeeded = plotData.waterNeeded or 0,
        countdownInfo = plotData.countdownInfo, -- Rich display information from server
        firstReadyTime = existingFirstReadyTime -- Preserve client-side timing unless harvest occurred
    }
    
    logDebug("Updated plot", plotId, "data:", plotData.state, plotData.seedType, "owner:", plotData.ownerName or "none")
    
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
    
    logDebug("Started master countdown update loop")
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
end

-- Stop countdown for a specific plot
function PlotCountdownManager.stopCountdown(plotId)
    plotsNeedingUpdate[plotId] = nil
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
    
    -- Use enhanced display with real-time countdowns for owned plots
    local currentTime = tick()
    local state = plotData.state
    
    if state == "empty" then
        countdownLabel.Text = ""
        countdownLabel.Visible = false
        return
    end
    
    -- Show simplified information (detailed info is now in the UI)
    countdownLabel.Visible = true
    local displayText = ""
    local color = Color3.fromRGB(255, 255, 255)
    
    if state == "planted" or state == "growing" then
        -- Get crop emoji from CropRegistry
        local CropRegistry = require(game:GetService("ReplicatedStorage").Shared.CropRegistry)
        local cropData = CropRegistry.getCrop(plotData.seedType)
        local cropEmoji = cropData and cropData.emoji or "🌱"
        local plantName = plotData.seedType:gsub("^%l", string.upper)
        
        -- Check if water is actually needed and can be applied
        local wateredCount = plotData.wateredCount or 0
        local waterNeeded = plotData.waterNeeded or 1
        local lastWaterActionTime = plotData.lastWaterActionTime or 0
        local waterCooldownSeconds = plotData.waterCooldownSeconds or 30
        local currentTime = tick()
        local timeSinceLastWater = currentTime - lastWaterActionTime
        local waterCooldownRemaining = waterCooldownSeconds - timeSinceLastWater
        
        -- Show water status based on current state
        if wateredCount < waterNeeded then
            if lastWaterActionTime == 0 or waterCooldownRemaining <= 0 then
                -- Can water now
                displayText = cropEmoji .. " " .. plantName .. "\n💧 Needs Water"
            else
                -- Recently watered but needs more, on cooldown
                displayText = cropEmoji .. " " .. plantName .. "\n💧 Drinking Water"
            end
        else
            -- Fully watered, just show crop name
            displayText = cropEmoji .. " " .. plantName
        end
        color = Color3.fromRGB(150, 200, 255) -- Light blue
        
    elseif state == "watered" then
        -- Get crop emoji from CropRegistry
        local CropRegistry = require(game:GetService("ReplicatedStorage").Shared.CropRegistry)
        local cropData = CropRegistry.getCrop(plotData.seedType)
        local cropEmoji = cropData and cropData.emoji or "🌿"
        local plantName = plotData.seedType:gsub("^%l", string.upper)
        displayText = cropEmoji .. " " .. plantName .. "\n⚡ Growing..."
        color = Color3.fromRGB(100, 255, 200) -- Bright green
        
    elseif state == "ready" then
        -- Get crop emoji from CropRegistry
        local CropRegistry = require(game:GetService("ReplicatedStorage").Shared.CropRegistry)
        local cropData = CropRegistry.getCrop(plotData.seedType)
        local cropEmoji = cropData and cropData.emoji or "🌟"
        local plantName = plotData.seedType:gsub("^%l", string.upper)
        local accumulatedCrops = plotData.accumulatedCrops or 1
        displayText = cropEmoji .. " " .. plantName .. "\n✨ Ready (" .. accumulatedCrops .. ")"
        color = Color3.fromRGB(255, 255, 100) -- Gold
        
    elseif state == "dead" then
        local plantName = plotData.seedType:gsub("^%l", string.upper)
        displayText = "💀 " .. plantName .. " Dead"
        color = Color3.fromRGB(255, 50, 50) -- Red
    end
    
    countdownLabel.Text = displayText
    countdownLabel.TextColor3 = color
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
    
end

-- Handle plot state updates from server
function PlotCountdownManager.onPlotStateUpdate(plotId, newState, additionalData)
    local plotData = plotTimers[plotId]
    if not plotData then
        return
    end
    
    local currentTime = tick()
    
    -- Reset firstReadyTime when plot transitions away from ready state
    if plotData.state == "ready" and newState ~= "ready" then
        plotTimers[plotId].firstReadyTime = nil
    end
    
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
        plotTimers[plotId].firstReadyTime = nil -- Clear timer when plot becomes empty
    end
    
    logDebug("Plot", plotId, "state updated to", newState)
end

return PlotCountdownManager