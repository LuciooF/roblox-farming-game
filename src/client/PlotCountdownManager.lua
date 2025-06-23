-- Client-side Plot Countdown Manager
-- Handles smooth countdown displays with client-side prediction
-- Reduces server load and eliminates network lag in countdowns

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local ClientLogger = require(script.Parent.ClientLogger)
local log = ClientLogger.getModuleLogger("PlotCountdowns")

local PlotCountdownManager = {}

-- Storage for plot timing data
local plotTimers = {} -- [plotId] = {startTime, growthTime, waterTime, state, seedType}
local countdownConnections = {} -- [plotId] = RBXScriptConnection

-- Initialize countdown manager
function PlotCountdownManager.initialize()
    log.info("Client-side plot countdown system initialized")
end

-- Update plot timing data when server sends state changes
function PlotCountdownManager.updatePlotData(plotId, plotData)
    local currentTime = tick()
    
    -- Store plot timing information
    plotTimers[plotId] = {
        startTime = plotData.plantedAt or currentTime,
        growthTime = plotData.growthTime or 60, -- Default 60 seconds
        waterTime = plotData.waterTime or 30, -- Default 30 seconds  
        deathTime = plotData.deathTime or 120, -- Default 120 seconds
        state = plotData.state or "empty",
        seedType = plotData.seedType or "",
        lastWateredAt = plotData.lastWateredAt or 0,
        variation = plotData.variation or "normal"
    }
    
    log.debug("Updated plot", plotId, "data:", plotData.state, plotData.seedType)
    
    -- Start countdown for this plot
    PlotCountdownManager.startCountdown(plotId)
end

-- Start countdown display for a specific plot
function PlotCountdownManager.startCountdown(plotId)
    -- Stop existing countdown if any
    PlotCountdownManager.stopCountdown(plotId)
    
    -- Find the plot in the world
    local plot = PlotCountdownManager.findPlotById(plotId)
    if not plot then
        log.warn("Could not find plot", plotId, "in workspace")
        return
    end
    
    local countdownGui = plot:FindFirstChild("CountdownDisplay")
    local countdownLabel = countdownGui and countdownGui:FindFirstChild("TextLabel")
    if not countdownLabel then
        log.warn("Plot", plotId, "missing countdown UI elements")
        return
    end
    
    -- Create smooth countdown update loop
    local connection = RunService.Heartbeat:Connect(function()
        PlotCountdownManager.updateCountdownDisplay(plotId, countdownLabel)
    end)
    
    countdownConnections[plotId] = connection
    log.debug("Started countdown for plot", plotId)
end

-- Stop countdown for a specific plot
function PlotCountdownManager.stopCountdown(plotId)
    if countdownConnections[plotId] then
        countdownConnections[plotId]:Disconnect()
        countdownConnections[plotId] = nil
        log.debug("Stopped countdown for plot", plotId)
    end
end

-- Update countdown display for a plot (called every frame)
function PlotCountdownManager.updateCountdownDisplay(plotId, countdownLabel)
    local plotData = plotTimers[plotId]
    if not plotData then return end
    
    local currentTime = tick()
    local state = plotData.state
    
    if state == "empty" then
        countdownLabel.Text = "Empty"
        countdownLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        
    elseif state == "planted" then
        -- Calculate time until needs water
        local timeSincePlanted = currentTime - plotData.startTime
        local timeUntilWater = plotData.waterTime - timeSincePlanted
        
        if timeUntilWater > 0 then
            countdownLabel.Text = "Water in: " .. PlotCountdownManager.formatTime(timeUntilWater)
            countdownLabel.TextColor3 = Color3.fromRGB(100, 200, 255) -- Light blue
        else
            countdownLabel.Text = "Needs Water!"
            countdownLabel.TextColor3 = Color3.fromRGB(255, 100, 100) -- Red
        end
        
    elseif state == "watered" then
        -- Calculate time until ready to harvest
        local timeSinceWatered = currentTime - plotData.lastWateredAt
        local timeUntilReady = plotData.growthTime - timeSinceWatered
        
        if timeUntilReady > 0 then
            countdownLabel.Text = "Ready in: " .. PlotCountdownManager.formatTime(timeUntilReady)
            countdownLabel.TextColor3 = Color3.fromRGB(100, 255, 100) -- Green
        else
            countdownLabel.Text = "Ready to Harvest!"
            countdownLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
        end
        
    elseif state == "ready" then
        countdownLabel.Text = "Ready to Harvest!"
        countdownLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
        
    else
        countdownLabel.Text = state
        countdownLabel.TextColor3 = Color3.fromRGB(200, 200, 200) -- Gray
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

-- Find plot by ID in workspace
function PlotCountdownManager.findPlotById(plotId)
    local farm = Workspace:FindFirstChild("Farm")
    if not farm then return nil end
    
    local plots = farm:FindFirstChild("Plots")
    if not plots then return nil end
    
    for _, plot in pairs(plots:GetChildren()) do
        local plotIdValue = plot:FindFirstChild("PlotId")
        if plotIdValue and plotIdValue.Value == plotId then
            return plot
        end
    end
    
    return nil
end

-- Clean up countdown for a plot (when plot is removed)
function PlotCountdownManager.cleanupPlot(plotId)
    PlotCountdownManager.stopCountdown(plotId)
    plotTimers[plotId] = nil
    log.debug("Cleaned up plot", plotId)
end

-- Clean up all countdowns (on player leave)
function PlotCountdownManager.cleanup()
    for plotId, _ in pairs(countdownConnections) do
        PlotCountdownManager.stopCountdown(plotId)
    end
    plotTimers = {}
    log.info("Cleaned up all plot countdowns")
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