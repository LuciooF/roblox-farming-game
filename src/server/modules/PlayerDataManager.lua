-- Player Data Management Module
-- Handles all player data operations, inventory, and rebirths

local GameConfig = require(script.Parent.GameConfig)

local PlayerDataManager = {}

-- Storage
local playerFarms = {} -- [playerId] = { money, rebirths, inventory }

-- Get or create player data
function PlayerDataManager.getPlayerData(player)
    local userId = tostring(player.UserId)
    
    if not playerFarms[userId] then
        playerFarms[userId] = {
            money = GameConfig.Settings.startingMoney,
            rebirths = 0,
            extraSlots = 0, -- Additional inventory slots beyond the main 9
            inventory = {
                seeds = {},
                crops = {}
            }
        }
        
        -- Set starting seeds
        for seedType, count in pairs(GameConfig.Settings.startingSeeds) do
            playerFarms[userId].inventory.seeds[seedType] = count
        end
    end
    
    -- Ensure existing players have extraSlots field
    if playerFarms[userId].extraSlots == nil then
        playerFarms[userId].extraSlots = 0
    end
    
    return playerFarms[userId]
end

-- Check if player can rebirth
function PlayerDataManager.canRebirth(playerData)
    local moneyRequired = GameConfig.Rebirth.getMoneyRequirement(playerData.rebirths)
    return playerData.money >= moneyRequired
end

-- Perform rebirth
function PlayerDataManager.performRebirth(player)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return false end
    
    if not PlayerDataManager.canRebirth(playerData) then
        return false, "Not enough money"
    end
    
    -- Perform rebirth
    local oldRebirths = playerData.rebirths
    playerData.rebirths = playerData.rebirths + 1
    playerData.money = GameConfig.Settings.startingMoney -- Reset money
    -- Note: extraSlots is preserved through rebirth
    
    -- Reset inventory to starting amounts
    playerData.inventory = {
        seeds = {},
        crops = {}
    }
    
    for seedType, count in pairs(GameConfig.Settings.startingSeeds) do
        playerData.inventory.seeds[seedType] = count
    end
    
    local newMultiplier = GameConfig.Rebirth.getCropMultiplier(playerData.rebirths)
    
    return true, {
        oldRebirths = oldRebirths,
        newRebirths = playerData.rebirths,
        multiplier = newMultiplier
    }
end

-- Get rebirth info for player
function PlayerDataManager.getRebirthInfo(player)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return nil end
    
    return {
        currentRebirths = playerData.rebirths,
        moneyRequired = GameConfig.Rebirth.getMoneyRequirement(playerData.rebirths),
        cropMultiplier = GameConfig.Rebirth.getCropMultiplier(playerData.rebirths),
        canRebirth = PlayerDataManager.canRebirth(playerData)
    }
end

-- Add money to player
function PlayerDataManager.addMoney(player, amount)
    local playerData = PlayerDataManager.getPlayerData(player)
    if playerData then
        playerData.money = playerData.money + amount
        return true
    end
    return false
end

-- Remove money from player
function PlayerDataManager.removeMoney(player, amount)
    local playerData = PlayerDataManager.getPlayerData(player)
    if playerData and playerData.money >= amount then
        playerData.money = playerData.money - amount
        return true
    end
    return false
end

-- Add item to inventory
function PlayerDataManager.addToInventory(player, itemType, itemName, amount)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return false end
    
    if not playerData.inventory[itemType] then
        playerData.inventory[itemType] = {}
    end
    
    playerData.inventory[itemType][itemName] = (playerData.inventory[itemType][itemName] or 0) + amount
    return true
end

-- Remove item from inventory
function PlayerDataManager.removeFromInventory(player, itemType, itemName, amount)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return false end
    
    local available = (playerData.inventory[itemType] and playerData.inventory[itemType][itemName]) or 0
    if available >= amount then
        playerData.inventory[itemType][itemName] = available - amount
        return true
    end
    return false
end

-- Get inventory count
function PlayerDataManager.getInventoryCount(player, itemType, itemName)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return 0 end
    
    return (playerData.inventory[itemType] and playerData.inventory[itemType][itemName]) or 0
end

-- Clear all crops from inventory and return total value
function PlayerDataManager.sellAllCrops(player)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return 0, {} end
    
    local totalProfit = 0
    local itemsSold = {}
    local rebirthMultiplier = GameConfig.Rebirth.getCropMultiplier(playerData.rebirths)
    
    for cropType, amount in pairs(playerData.inventory.crops) do
        if amount > 0 and GameConfig.Plants[cropType] then
            local baseValue = GameConfig.Plants[cropType].basePrice * amount
            local cropValue = math.floor(baseValue * rebirthMultiplier)
            totalProfit = totalProfit + cropValue
            itemsSold[cropType] = amount
            
            -- Clear crops from inventory
            playerData.inventory.crops[cropType] = 0
        end
    end
    
    if totalProfit > 0 then
        playerData.money = playerData.money + totalProfit
    end
    
    return totalProfit, itemsSold, rebirthMultiplier
end

return PlayerDataManager