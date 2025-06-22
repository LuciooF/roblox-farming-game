-- Player data management system
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Promise = require(Packages.promise)

local PlayerDataManager = {}

-- DataStore reference (Studio-safe)
local playerDataStore
local success, result = pcall(function()
    return DataStoreService:GetDataStore("PlayerData_v1")
end)

if success then
    playerDataStore = result
    print("PlayerDataManager: DataStore connected")
else
    warn("PlayerDataManager: DataStore not available (Studio mode) - " .. tostring(result))
end

-- Cache for loaded player data
local playerDataCache = {}

-- Default player data template
local defaultPlayerData = {
    money = 100,
    level = 1,
    experience = 0,
    inventory = {
        seeds = {
            tomato = 5,
            carrot = 3,
            wheat = 2
        },
        crops = {},
        tools = {}
    },
    farm = {
        equipment = {
            wateringCan = true,
            airPurifier = false,
            advancedSoil = false,
            greenhouse = false
        }
    },
    stats = {
        totalPlantsGrown = 0,
        totalCropsHarvested = 0,
        totalMoneySaved = 0,
        playtime = 0
    },
    settings = {
        musicEnabled = true,
        soundEnabled = true,
        autoSave = true
    },
    lastSaved = 0
}

-- Load player data
function PlayerDataManager.loadPlayerData(player)
    return Promise.new(function(resolve, reject)
        local userId = tostring(player.UserId)
        
        -- Handle Studio mode (no DataStore)
        if not playerDataStore then
            print("Using default data for " .. player.Name .. " (Studio mode)")
            local defaultData = PlayerDataManager.deepCopy(defaultPlayerData)
            playerDataCache[userId] = defaultData
            resolve(defaultData)
            return
        end
        
        local success, result = pcall(function()
            return playerDataStore:GetAsync(userId)
        end)
        
        if success then
            local playerData = result or {}
            
            -- Merge with default data to ensure all fields exist
            playerData = PlayerDataManager.mergeWithDefaults(playerData, defaultPlayerData)
            
            -- Cache the data
            playerDataCache[userId] = playerData
            
            print("Loaded data for player: " .. player.Name)
            resolve(playerData)
        else
            warn("Failed to load data for player " .. player.Name .. ": " .. tostring(result))
            
            -- Use default data on failure
            local defaultData = PlayerDataManager.deepCopy(defaultPlayerData)
            playerDataCache[userId] = defaultData
            
            resolve(defaultData)
        end
    end)
end

-- Save player data
function PlayerDataManager.savePlayerData(player)
    return Promise.new(function(resolve, reject)
        local userId = tostring(player.UserId)
        local playerData = playerDataCache[userId]
        
        if not playerData then
            warn("No data to save for player: " .. player.Name)
            resolve(false)
            return
        end
        
        -- Handle Studio mode (no DataStore)
        if not playerDataStore then
            print("Data save skipped for " .. player.Name .. " (Studio mode)")
            resolve(true)
            return
        end
        
        -- Update last saved timestamp
        playerData.lastSaved = tick()
        
        local success, result = pcall(function()
            return playerDataStore:SetAsync(userId, playerData)
        end)
        
        if success then
            print("Saved data for player: " .. player.Name)
            resolve(true)
        else
            warn("Failed to save data for player " .. player.Name .. ": " .. tostring(result))
            reject(result)
        end
    end)
end

-- Get cached player data
function PlayerDataManager.getPlayerData(player)
    local userId = tostring(player.UserId)
    return playerDataCache[userId]
end

-- Update player data in cache
function PlayerDataManager.updatePlayerData(player, dataPath, value)
    local userId = tostring(player.UserId)
    local playerData = playerDataCache[userId]
    
    if not playerData then
        warn("No cached data for player: " .. player.Name)
        return false
    end
    
    -- Handle nested path updates (e.g., "inventory.seeds.tomato")
    local pathParts = string.split(dataPath, ".")
    local current = playerData
    
    for i = 1, #pathParts - 1 do
        local part = pathParts[i]
        if not current[part] then
            current[part] = {}
        end
        current = current[part]
    end
    
    current[pathParts[#pathParts]] = value
    return true
end

-- Add money to player
function PlayerDataManager.addMoney(player, amount)
    local userId = tostring(player.UserId)
    local playerData = playerDataCache[userId]
    
    if playerData then
        playerData.money = playerData.money + amount
        return playerData.money
    end
    
    return 0
end

-- Remove money from player
function PlayerDataManager.removeMoney(player, amount)
    local userId = tostring(player.UserId)
    local playerData = playerDataCache[userId]
    
    if playerData and playerData.money >= amount then
        playerData.money = playerData.money - amount
        return true, playerData.money
    end
    
    return false, playerData and playerData.money or 0
end

-- Add experience and check for level up
function PlayerDataManager.addExperience(player, amount)
    local userId = tostring(player.UserId)
    local playerData = playerDataCache[userId]
    
    if not playerData then
        return false, 0, 0
    end
    
    playerData.experience = playerData.experience + amount
    local oldLevel = playerData.level
    
    -- Calculate level based on experience (100 XP per level)
    local newLevel = math.floor(playerData.experience / 100) + 1
    
    if newLevel > oldLevel then
        playerData.level = newLevel
        print(player.Name .. " leveled up to level " .. newLevel .. "!")
        
        -- Give level up bonus
        PlayerDataManager.addMoney(player, newLevel * 50)
        
        return true, newLevel, oldLevel -- Level up occurred
    end
    
    return false, newLevel, oldLevel -- No level up
end

-- Add item to inventory
function PlayerDataManager.addToInventory(player, itemType, itemName, amount)
    local userId = tostring(player.UserId)
    local playerData = playerDataCache[userId]
    
    if not playerData then
        return false
    end
    
    if not playerData.inventory[itemType] then
        playerData.inventory[itemType] = {}
    end
    
    local currentAmount = playerData.inventory[itemType][itemName] or 0
    playerData.inventory[itemType][itemName] = currentAmount + amount
    
    return true
end

-- Remove item from inventory
function PlayerDataManager.removeFromInventory(player, itemType, itemName, amount)
    local userId = tostring(player.UserId)
    local playerData = playerDataCache[userId]
    
    if not playerData or not playerData.inventory[itemType] then
        return false
    end
    
    local currentAmount = playerData.inventory[itemType][itemName] or 0
    
    if currentAmount >= amount then
        playerData.inventory[itemType][itemName] = currentAmount - amount
        return true
    end
    
    return false
end

-- Get inventory item count
function PlayerDataManager.getInventoryCount(player, itemType, itemName)
    local userId = tostring(player.UserId)
    local playerData = playerDataCache[userId]
    
    if not playerData or not playerData.inventory[itemType] then
        return 0
    end
    
    return playerData.inventory[itemType][itemName] or 0
end

-- Update player stats
function PlayerDataManager.updateStats(player, statName, value)
    local userId = tostring(player.UserId)
    local playerData = playerDataCache[userId]
    
    if playerData and playerData.stats then
        if statName == "playtime" then
            playerData.stats.playtime = playerData.stats.playtime + value
        else
            playerData.stats[statName] = (playerData.stats[statName] or 0) + value
        end
        return true
    end
    
    return false
end

-- Auto-save system
function PlayerDataManager.startAutoSave()
    spawn(function()
        while true do
            wait(300) -- Auto-save every 5 minutes
            
            for _, player in pairs(Players:GetPlayers()) do
                local playerData = PlayerDataManager.getPlayerData(player)
                if playerData and playerData.settings.autoSave then
                    PlayerDataManager.savePlayerData(player):catch(function(err)
                        warn("Auto-save failed for " .. player.Name .. ": " .. tostring(err))
                    end)
                end
            end
        end
    end)
end

-- Utility function to deep copy tables
function PlayerDataManager.deepCopy(original)
    local copy = {}
    for key, value in pairs(original) do
        if type(value) == "table" then
            copy[key] = PlayerDataManager.deepCopy(value)
        else
            copy[key] = value
        end
    end
    return copy
end

-- Utility function to merge player data with defaults
function PlayerDataManager.mergeWithDefaults(playerData, defaults)
    local merged = PlayerDataManager.deepCopy(defaults)
    
    for key, value in pairs(playerData) do
        if type(value) == "table" and type(merged[key]) == "table" then
            merged[key] = PlayerDataManager.mergeWithDefaults(value, merged[key])
        else
            merged[key] = value
        end
    end
    
    return merged
end

-- Clean up player data when they leave
function PlayerDataManager.cleanupPlayer(player)
    local userId = tostring(player.UserId)
    
    -- Save data before cleanup
    PlayerDataManager.savePlayerData(player):finally(function()
        -- Remove from cache
        playerDataCache[userId] = nil
        print("Cleaned up data for player: " .. player.Name)
    end)
end

-- Initialize the system
function PlayerDataManager.initialize()
    print("PlayerDataManager: Initializing...")
    
    -- Start auto-save system
    PlayerDataManager.startAutoSave()
    
    -- Handle players already in game (for testing)
    for _, player in pairs(Players:GetPlayers()) do
        PlayerDataManager.loadPlayerData(player)
    end
    
    print("PlayerDataManager: Ready!")
end

return PlayerDataManager