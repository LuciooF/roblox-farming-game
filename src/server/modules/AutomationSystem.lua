-- Automation System Module
-- Handles all automated farming operations (plant all, harvest all, etc.)

local GameConfig = require(script.Parent.GameConfig)
local PlayerDataManager = require(script.Parent.PlayerDataManager)
local PlotManager = require(script.Parent.PlotManager)
local GamepassManager = require(script.Parent.GamepassManager)

local AutomationSystem = {}

-- Auto plant all empty plots
function AutomationSystem.plantAll(player)
    -- Check gamepass
    local hasAccess, message = GamepassManager.validateAutomation(player, "plant")
    if not hasAccess then
        return false, message
    end
    
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then 
        return false, "Player data not found"
    end
    
    -- Find available seed (prefer wheat for automation)
    local seedPriority = {"wheat", "tomato", "carrot", "potato", "corn"}
    local selectedSeed = nil
    
    for _, seedType in ipairs(seedPriority) do
        if PlayerDataManager.getInventoryCount(player, "seeds", seedType) > 0 then
            selectedSeed = seedType
            break
        end
    end
    
    if not selectedSeed then
        return false, "You don't have any seeds to plant!"
    end
    
    -- Plant on all empty plots
    local emptyPlots = PlotManager.getPlotsInState("empty")
    local plantsPlanted = 0
    
    for _, plotInfo in ipairs(emptyPlots) do
        if PlayerDataManager.getInventoryCount(player, "seeds", selectedSeed) > 0 then
            local success, _ = PlotManager.plantSeed(player, plotInfo.plotId, selectedSeed)
            if success then
                plantsPlanted = plantsPlanted + 1
            end
        else
            break -- No more seeds
        end
    end
    
    if plantsPlanted > 0 then
        return true, "AutoBot planted " .. plantsPlanted .. " " .. selectedSeed .. " seeds!", {
            planted = plantsPlanted,
            seedType = selectedSeed
        }
    else
        return false, "No empty plots available!"
    end
end

-- Auto harvest all ready crops owned by player
function AutomationSystem.harvestAll(player)
    -- Check gamepass
    local hasAccess, message = GamepassManager.validateAutomation(player, "harvest")
    if not hasAccess then
        return false, message
    end
    
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then 
        return false, "Player data not found"
    end
    
    -- Harvest all ready plots owned by player
    local readyPlots = PlotManager.getPlotsInState("ready", player.UserId)
    local cropsHarvested = 0
    local cropsGained = {}
    
    for _, plotInfo in ipairs(readyPlots) do
        local success, _, totalYield = PlotManager.harvestCrop(player, plotInfo.plotId)
        if success then
            local seedType = plotInfo.plotState.seedType
            cropsGained[seedType] = (cropsGained[seedType] or 0) + totalYield
            cropsHarvested = cropsHarvested + 1
        end
    end
    
    if cropsHarvested > 0 then
        return true, "AutoBot harvested " .. cropsHarvested .. " crops!", {
            harvested = cropsHarvested,
            cropsGained = cropsGained
        }
    else
        return false, "No ready crops to harvest!"
    end
end

-- Auto water all plants that need watering (if gamepass allows)
function AutomationSystem.waterAll(player)
    -- Check gamepass
    local hasAccess, message = GamepassManager.validateAutomation(player, "water")
    if not hasAccess then
        return false, message
    end
    
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then 
        return false, "Player data not found"
    end
    
    -- Find all plants that need watering and are owned by player
    local plantsWatered = 0
    local needWaterStates = {"planted", "growing"}
    
    for _, state in ipairs(needWaterStates) do
        local plots = PlotManager.getPlotsInState(state, player.UserId)
        
        for _, plotInfo in ipairs(plots) do
            -- Try to water (will check cooldowns internally)
            local success, _ = PlotManager.waterPlant(player, plotInfo.plotId)
            if success then
                plantsWatered = plantsWatered + 1
            end
        end
    end
    
    if plantsWatered > 0 then
        return true, "AutoBot watered " .. plantsWatered .. " plants!", {
            watered = plantsWatered
        }
    else
        return false, "No plants need watering right now!"
    end
end

-- Auto sell all crops
function AutomationSystem.sellAll(player)
    -- Gamepass check temporarily disabled for testing
    -- local hasAccess, message = GamepassManager.validateAutomation(player, "sell")
    -- if not hasAccess then
    --     return false, message
    -- end
    
    local totalProfit, itemsSold, rebirthMultiplier = PlayerDataManager.sellAllCrops(player)
    
    if totalProfit > 0 then
        local message = "AutoBot sold all crops for $" .. totalProfit .. "!"
        if rebirthMultiplier > 1 then
            message = message .. " (" .. rebirthMultiplier .. "x multiplier)"
        end
        
        return true, message, {
            profit = totalProfit,
            itemsSold = itemsSold,
            multiplier = rebirthMultiplier
        }
    else
        return false, "You don't have any crops to sell!"
    end
end

return AutomationSystem