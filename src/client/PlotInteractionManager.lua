-- Client-side Plot Interaction Manager
-- Provides immediate visual feedback for plot interactions
-- Reduces perceived lag through client-side prediction

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientLogger = require(script.Parent.ClientLogger)
local PlotUtils = require(script.Parent.PlotUtils)
local log = ClientLogger.getModuleLogger("PlotInteractions")

local PlotInteractionManager = {}

-- Storage for pending interactions
local pendingInteractions = {} -- [plotId] = {type, timestamp, originalState}
local remotes = {}
local currentPlayerData = nil -- Cache current player data for inventory checks

-- Initialize interaction manager
function PlotInteractionManager.initialize(farmingRemotes)
    remotes.plant = farmingRemotes:WaitForChild("PlantSeed")
    remotes.water = farmingRemotes:WaitForChild("WaterPlant") 
    remotes.harvest = farmingRemotes:WaitForChild("HarvestCrop")
    remotes.interactionFailure = farmingRemotes:WaitForChild("InteractionFailure")
    
    -- Connect to interaction failure events for rollback
    remotes.interactionFailure.OnClientEvent:Connect(function(failureData)
        log.debug("Received interaction failure:", failureData.plotId, failureData.interactionType, failureData.reason)
        PlotInteractionManager.rollbackPrediction(failureData.plotId)
    end)
    
    -- Start periodic cleanup of stale pending interactions
    spawn(function()
        while true do
            wait(30) -- Clean up every 30 seconds
            PlotInteractionManager.cleanupPendingInteractions()
        end
    end)
    
    log.info("Plot interaction prediction system initialized")
end

-- Update current player data for inventory checks
function PlotInteractionManager.updatePlayerData(playerData)
    currentPlayerData = playerData
end

-- Predict contextual action based on plot state
function PlotInteractionManager.predictContextualAction(plot, plotId)
    -- Get the ActionPrompt to determine current action
    local actionPrompt = plot:FindFirstChild("ActionPrompt")
    if not actionPrompt then return false end
    
    local actionText = actionPrompt.ActionText
    
    -- Route to appropriate prediction based on action text
    if actionText:find("Plant") then
        return PlotInteractionManager.predictPlantInteraction(plot, plotId)
    elseif actionText:find("Water") then
        return PlotInteractionManager.predictWaterInteraction(plot, plotId)
    elseif actionText:find("Harvest") then
        return PlotInteractionManager.predictHarvestInteraction(plot, plotId)
    elseif actionText:find("Clear") then
        return PlotInteractionManager.predictClearDeadPlantInteraction(plot, plotId)
    else
        -- Unknown action, provide generic feedback
        local countdownGui = plot:FindFirstChild("CountdownDisplay")
        local countdownLabel = countdownGui and countdownGui:FindFirstChild("TextLabel")
        if countdownLabel then
            -- Store original state
            pendingInteractions[plotId] = {
                type = "generic",
                timestamp = tick(),
                originalText = countdownLabel.Text,
                originalColor = countdownLabel.TextColor3
            }
            
            countdownLabel.Text = "Processing..."
            countdownLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
        return true
    end
end

-- Predict plant interaction with immediate visual feedback
function PlotInteractionManager.predictPlantInteraction(plot, plotId)
    -- Get countdown display
    local countdownGui = plot:FindFirstChild("CountdownDisplay")
    local countdownLabel = countdownGui and countdownGui:FindFirstChild("TextLabel")
    if not countdownLabel then return false end
    
    -- Check if player has any seeds before predicting
    if currentPlayerData and currentPlayerData.inventory and currentPlayerData.inventory.seeds then
        local hasSeeds = false
        for seedType, count in pairs(currentPlayerData.inventory.seeds) do
            if count > 0 then
                hasSeeds = true
                break
            end
        end
        
        if not hasSeeds then
            log.debug("Not predicting plant interaction - player has no seeds")
            return false -- Don't predict if no seeds available
        end
    else
        log.debug("No player data available for seed check, skipping prediction")
        return false -- Don't predict if we can't check inventory
    end
    
    -- Store original state for potential rollback
    pendingInteractions[plotId] = {
        type = "plant",
        timestamp = tick(),
        originalText = countdownLabel.Text,
        originalColor = countdownLabel.TextColor3
    }
    
    -- Immediate visual feedback
    countdownLabel.Text = "Planting..."
    countdownLabel.TextColor3 = Color3.fromRGB(100, 255, 100) -- Green
    
    -- Note: Do NOT call the remote here - the server-side FarmingSystem handles the actual planting
    -- This function only provides immediate visual feedback
    
    log.debug("Predicted plant interaction for plot", plotId)
    return true
end

-- Predict water interaction with immediate visual feedback  
function PlotInteractionManager.predictWaterInteraction(plot, plotId)
    -- Get countdown display
    local countdownGui = plot:FindFirstChild("CountdownDisplay")
    local countdownLabel = countdownGui and countdownGui:FindFirstChild("TextLabel")
    if not countdownLabel then return false end
    
    -- Check if it looks like it needs water
    local currentText = countdownLabel.Text
    if not (currentText:find("Water") or currentText:find("Needs") or currentText:find("0/")) then
        return false -- Doesn't look like it needs water
    end
    
    -- Store original state for potential rollback
    pendingInteractions[plotId] = {
        type = "water",
        timestamp = tick(),
        originalText = countdownLabel.Text,
        originalColor = countdownLabel.TextColor3
    }
    
    -- Immediate visual feedback based on current state
    if currentText:find("0/1") then
        -- First water
        countdownLabel.Text = "Watered (1/1)! Growing..."
        countdownLabel.TextColor3 = Color3.fromRGB(100, 255, 100) -- Green
    elseif currentText:find("0/2") then
        -- First water of two
        countdownLabel.Text = "Watered (1/2). Needs more!"
        countdownLabel.TextColor3 = Color3.fromRGB(255, 255, 100) -- Yellow
    elseif currentText:find("1/2") then
        -- Second water of two
        countdownLabel.Text = "Watered (2/2)! Growing..."
        countdownLabel.TextColor3 = Color3.fromRGB(100, 255, 100) -- Green
    else
        -- Generic watering feedback
        countdownLabel.Text = "Watering..."
        countdownLabel.TextColor3 = Color3.fromRGB(100, 200, 255) -- Light blue
    end
    
    -- Note: Do NOT call the remote here - the server-side FarmingSystem handles the actual watering
    
    log.debug("Predicted water interaction for plot", plotId)
    return true
end

-- Predict harvest interaction with immediate visual feedback
function PlotInteractionManager.predictHarvestInteraction(plot, plotId)
    -- Get countdown display
    local countdownGui = plot:FindFirstChild("CountdownDisplay")
    local countdownLabel = countdownGui and countdownGui:FindFirstChild("TextLabel")
    if not countdownLabel then return false end
    
    -- Check if it looks ready to harvest
    local currentText = countdownLabel.Text
    if not currentText:find("Ready") then
        return false -- Doesn't look ready
    end
    
    -- Store original state for potential rollback
    pendingInteractions[plotId] = {
        type = "harvest",
        timestamp = tick(),
        originalText = countdownLabel.Text,
        originalColor = countdownLabel.TextColor3
    }
    
    -- Immediate visual feedback
    countdownLabel.Text = "Harvesting..."
    countdownLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
    
    -- Note: Do NOT call the remote here - the server-side FarmingSystem handles the actual harvesting
    
    log.debug("Predicted harvest interaction for plot", plotId)
    return true
end

-- Predict clear dead plant interaction with immediate visual feedback
function PlotInteractionManager.predictClearDeadPlantInteraction(plot, plotId)
    -- Get countdown display
    local countdownGui = plot:FindFirstChild("CountdownDisplay")
    local countdownLabel = countdownGui and countdownGui:FindFirstChild("TextLabel")
    if not countdownLabel then return false end
    
    -- Check if it looks like a dead plant
    local currentText = countdownLabel.Text
    if not currentText:find("Died") then
        return false -- Doesn't look dead
    end
    
    -- Store original state for potential rollback
    pendingInteractions[plotId] = {
        type = "clear",
        timestamp = tick(),
        originalText = countdownLabel.Text,
        originalColor = countdownLabel.TextColor3
    }
    
    -- Immediate visual feedback
    countdownLabel.Text = "Clearing..."
    countdownLabel.TextColor3 = Color3.fromRGB(128, 128, 128) -- Gray
    
    -- Note: Do NOT call the remote here - the server-side FarmingSystem handles the actual clearing
    
    log.debug("Predicted clear dead plant interaction for plot", plotId)
    return true
end

-- Handle server response (success or failure)
function PlotInteractionManager.onServerResponse(plotId, success, newState)
    local pending = pendingInteractions[plotId]
    if not pending then return end
    
    if success then
        -- Server confirmed - prediction was correct, clear pending
        log.debug("Server confirmed", pending.type, "for plot", plotId)
    else
        -- Server rejected - rollback to original state
        log.warn("Server rejected", pending.type, "for plot", plotId, "- rolling back")
        PlotInteractionManager.rollbackPrediction(plotId)
    end
    
    -- Clear pending interaction
    pendingInteractions[plotId] = nil
end

-- Rollback prediction if server rejects
function PlotInteractionManager.rollbackPrediction(plotId)
    local pending = pendingInteractions[plotId]
    if not pending then return end
    
    -- Find the plot and restore original state
    local plot = PlotUtils.findPlotById(plotId)
    if not plot then return end
    
    local countdownGui = plot:FindFirstChild("CountdownDisplay")
    local countdownLabel = countdownGui and countdownGui:FindFirstChild("TextLabel")
    if not countdownLabel then return end
    
    -- Restore original appearance
    countdownLabel.Text = pending.originalText
    countdownLabel.TextColor3 = pending.originalColor
    
    log.debug("Rolled back prediction for plot", plotId)
end

-- Clean up old pending interactions (prevent memory leaks)
function PlotInteractionManager.cleanupPendingInteractions()
    local currentTime = tick()
    local timeout = 10 -- 10 seconds timeout
    
    for plotId, pending in pairs(pendingInteractions) do
        if currentTime - pending.timestamp > timeout then
            log.warn("Cleaning up stale pending interaction for plot", plotId)
            pendingInteractions[plotId] = nil
        end
    end
end


return PlotInteractionManager