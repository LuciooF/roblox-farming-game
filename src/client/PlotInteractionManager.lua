-- Client-side Plot Interaction Manager
-- Provides immediate visual feedback for plot interactions
-- Reduces perceived lag through client-side prediction

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Simple logging removed ClientLogger
local PlotUtils = require(script.Parent.PlotUtils)

local PlotInteractionManager = {}

-- Storage for pending interactions
local pendingInteractions = {} -- [plotId] = {type, timestamp, originalState}
local remotes = {}
local currentPlayerData = nil -- Cache current player data for inventory checks
local plotUIHandler = nil -- Handler to open plot UI

-- Initialize interaction manager
function PlotInteractionManager.initialize(farmingRemotes)
    remotes.plant = farmingRemotes:WaitForChild("PlantCrop")
    remotes.water = farmingRemotes:WaitForChild("WaterPlant") 
    remotes.harvest = farmingRemotes:WaitForChild("HarvestCrop")
    remotes.harvestAll = farmingRemotes:WaitForChild("HarvestAllCrops")
    remotes.cut = farmingRemotes:WaitForChild("CutPlant")
    remotes.buyPlot = farmingRemotes:WaitForChild("BuyPlot")
    remotes.interactionFailure = farmingRemotes:WaitForChild("InteractionFailure")
    
    -- Connect to interaction failure events for rollback
    remotes.interactionFailure.OnClientEvent:Connect(function(failureData)
        print("[DEBUG]", "Received interaction failure:", failureData.plotId, failureData.interactionType, failureData.reason)
        PlotInteractionManager.rollbackPrediction(failureData.plotId)
    end)
    
    -- Start periodic cleanup of stale pending interactions
    spawn(function()
        while true do
            wait(30) -- Clean up every 30 seconds
            PlotInteractionManager.cleanupPendingInteractions()
        end
    end)
    
end

-- Update current player data for inventory checks
function PlotInteractionManager.updatePlayerData(playerData)
    currentPlayerData = playerData
end

-- Set the plot UI handler function
function PlotInteractionManager.setPlotUIHandler(handler)
    plotUIHandler = handler
end

-- Predict contextual action based on plot state
function PlotInteractionManager.predictContextualAction(plot, plotId)
    print("[INFO]", "🔍 predictContextualAction called for plot", plotId, "plotUIHandler exists:", plotUIHandler ~= nil)
    
    -- If we have a UI handler, open the UI instead of predictions
    if plotUIHandler then
        print("[INFO]", "📋 UI handler found, opening Plot UI for plot", plotId)
        
        -- Get current plot state information (using correct field names)
        local plotState = plot:FindFirstChild("PlotData")
        local seedType = plot:FindFirstChild("SeedType")
        local countdownGui = plot:FindFirstChild("CountdownDisplay")
        
        print("[DEBUG]", "Plot state data:", plotState and plotState.Value or "nil", "seed:", seedType and seedType.Value or "nil")
        
        -- Build plot data for UI
        local plotData = {
            plotId = plotId,
            state = plotState and plotState.Value or "empty",
            seedType = seedType and seedType.Value or "",
            -- Get additional data from attributes if available
            harvestCount = plot:GetAttribute("HarvestCount") or 0,
            maxHarvests = plot:GetAttribute("MaxHarvests") or 0,
            accumulatedCrops = plot:GetAttribute("AccumulatedCrops") or 0,
            wateredCount = plot:GetAttribute("WateredCount") or 0,
            waterNeeded = plot:GetAttribute("WaterNeeded") or 1
        }
        
        print("[DEBUG]", "Built plot data:", plotData)
        
        -- Check if this is a purchase/unlock action
        local actionPrompt = plot:FindFirstChild("ActionPrompt")
        if actionPrompt and (actionPrompt.ActionText:find("Purchase") or actionPrompt.ActionText:find("Unlock")) then
            print("[INFO]", "🏪 Purchase/unlock action detected, using direct action")
            -- For purchase/unlock, still use the direct action
            return PlotInteractionManager.predictPurchasePlotInteraction(plot, plotId)
        end
        
        -- Open the plot UI
        print("[INFO]", "✨ Opening Plot UI with data:", plotData.state, plotData.seedType)
        plotUIHandler(plotData)
        return true
    else
        warn("[WARN]", "❌ No plotUIHandler available!")
    end
    
    -- Fallback to old prediction system if no UI handler
    -- Check if shift key is held - if so, try to cut the plant
    local UserInputService = game:GetService("UserInputService")
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
        print("[DEBUG]", "Shift held - attempting to cut plant on plot", plotId)
        return PlotInteractionManager.predictCutPlantInteraction(plot, plotId)
    end
    
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
    elseif actionText:find("Purchase") or actionText:find("Unlock") then
        return PlotInteractionManager.predictPurchasePlotInteraction(plot, plotId)
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
            print("[DEBUG]", "Not predicting plant interaction - player has no seeds")
            return false -- Don't predict if no seeds available
        end
    else
        print("[DEBUG]", "No player data available for seed check, skipping prediction")
        return false -- Don't predict if we can't check inventory
    end
    
    -- Store original state for potential rollback
    pendingInteractions[plotId] = {
        type = "plant",
        timestamp = tick(),
        originalText = countdownLabel.Text,
        originalColor = countdownLabel.TextColor3,
        originalPlotColor = plot.BrickColor
    }
    
    -- Immediate visual feedback
    countdownLabel.Text = "Planting..."
    countdownLabel.TextColor3 = Color3.fromRGB(100, 255, 100) -- Green
    
    -- Immediate plot color update for planted state
    plot.BrickColor = BrickColor.new("Nougat") -- Light brown for planted
    local plantPosition = plot:FindFirstChild("PlantPosition")
    if plantPosition then
        plantPosition.BrickColor = BrickColor.new("Nougat")
    end
    
    -- Note: Do NOT call the remote here - the server-side FarmingSystem handles the actual planting
    -- This function only provides immediate visual feedback
    
    print("[DEBUG]", "Predicted plant interaction for plot", plotId)
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
        originalColor = countdownLabel.TextColor3,
        originalPlotColor = plot.BrickColor
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
    
    -- Immediate plot color update for watered state
    plot.BrickColor = BrickColor.new("Brown") -- Dark brown for watered
    local plantPosition = plot:FindFirstChild("PlantPosition")
    if plantPosition then
        plantPosition.BrickColor = BrickColor.new("Brown")
    end
    
    -- Note: Do NOT call the remote here - the server-side FarmingSystem handles the actual watering
    
    print("[DEBUG]", "Predicted water interaction for plot", plotId)
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
        originalColor = countdownLabel.TextColor3,
        originalPlotColor = plot.BrickColor
    }
    
    -- Immediate visual feedback
    countdownLabel.Text = "Harvesting..."
    countdownLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
    
    -- Immediate plot color update for empty state (after harvest)
    plot.BrickColor = BrickColor.new("CGA brown") -- Dry brown for empty
    local plantPosition = plot:FindFirstChild("PlantPosition")
    if plantPosition then
        plantPosition.BrickColor = BrickColor.new("CGA brown")
    end
    
    -- Note: Do NOT call the remote here - the server-side FarmingSystem handles the actual harvesting
    
    print("[DEBUG]", "Predicted harvest interaction for plot", plotId)
    return true
end

-- Predict harvest ALL interaction with immediate visual feedback
function PlotInteractionManager.predictHarvestAllInteraction(plot, plotId)
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
        type = "harvestAll",
        timestamp = tick(),
        originalText = countdownLabel.Text,
        originalColor = countdownLabel.TextColor3
    }
    
    -- Immediate visual feedback for harvest all
    countdownLabel.Text = "Harvesting ALL..."
    countdownLabel.TextColor3 = Color3.fromRGB(255, 165, 0) -- Orange for harvest all
    
    -- Send harvest all request to server
    if remotes.harvestAll then
        remotes.harvestAll:FireServer(plotId)
    end
    
    print("[DEBUG]", "Predicted harvest ALL interaction for plot", plotId)
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
    
    print("[DEBUG]", "Predicted clear dead plant interaction for plot", plotId)
    return true
end

-- Cut/remove any plant from a plot (with shift+click or right-click)
function PlotInteractionManager.predictCutPlantInteraction(plot, plotId)
    -- Get countdown display
    local countdownGui = plot:FindFirstChild("CountdownDisplay")
    local countdownLabel = countdownGui and countdownGui:FindFirstChild("TextLabel")
    if not countdownLabel then return false end
    
    -- Check if there's something to cut (not empty)
    local currentText = countdownLabel.Text
    if currentText:find("Empty") or currentText:find("Click") then
        return false -- Plot is empty
    end
    
    -- Store original state for potential rollback
    pendingInteractions[plotId] = {
        type = "cut",
        timestamp = tick(),
        originalText = countdownLabel.Text,
        originalColor = countdownLabel.TextColor3
    }
    
    -- Immediate visual feedback
    countdownLabel.Text = "Cutting..."
    countdownLabel.TextColor3 = Color3.fromRGB(255, 150, 50) -- Orange
    
    -- Send cut request to server
    remotes.cut:FireServer(plotId)
    
    print("[DEBUG]", "Predicted cut plant interaction for plot", plotId)
    return true
end

-- Purchase plot interaction (for locked plots)
function PlotInteractionManager.predictPurchasePlotInteraction(plot, plotId)
    -- Get countdown display
    local countdownGui = plot:FindFirstChild("CountdownDisplay")
    local countdownLabel = countdownGui and countdownGui:FindFirstChild("TextLabel")
    if not countdownLabel then return false end
    
    -- Store original state for potential rollback
    pendingInteractions[plotId] = {
        type = "purchase",
        timestamp = tick(),
        originalText = countdownLabel.Text,
        originalColor = countdownLabel.TextColor3
    }
    
    -- Immediate visual feedback
    countdownLabel.Text = "Processing Purchase..."
    countdownLabel.TextColor3 = Color3.fromRGB(100, 255, 100) -- Green
    
    -- Send purchase request to server
    if remotes.buyPlot then
        -- Update the global lastActionTime for purchase detection
        _G.lastActionTime = tick()
        remotes.buyPlot:FireServer()
    end
    
    print("[DEBUG]", "Predicted purchase plot interaction for plot", plotId)
    return true
end

-- Handle server response (success or failure)
function PlotInteractionManager.onServerResponse(plotId, success, newState)
    local pending = pendingInteractions[plotId]
    if not pending then return end
    
    if success then
        -- Server confirmed - prediction was correct, clear pending
        print("[DEBUG]", "Server confirmed", pending.type, "for plot", plotId)
    else
        -- Server rejected - rollback to original state
        warn("[WARN]", "Server rejected", pending.type, "for plot", plotId, "- rolling back")
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
    
    -- Restore original plot color if available
    if pending.originalPlotColor then
        plot.BrickColor = pending.originalPlotColor
        local plantPosition = plot:FindFirstChild("PlantPosition")
        if plantPosition then
            plantPosition.BrickColor = pending.originalPlotColor
        end
    end
    
    print("[DEBUG]", "Rolled back prediction for plot", plotId)
end

-- Clean up old pending interactions (prevent memory leaks)
function PlotInteractionManager.cleanupPendingInteractions()
    local currentTime = tick()
    local timeout = 10 -- 10 seconds timeout
    
    for plotId, pending in pairs(pendingInteractions) do
        if currentTime - pending.timestamp > timeout then
            warn("[WARN]", "Cleaning up stale pending interaction for plot", plotId)
            pendingInteractions[plotId] = nil
        end
    end
end


return PlotInteractionManager