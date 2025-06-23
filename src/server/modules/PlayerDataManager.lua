-- Player Data Management Module with ProfileStore
-- Handles all player data operations with local caching and automatic saves

local GameConfig = require(script.Parent.GameConfig)
local Logger = require(script.Parent.Logger)

-- ProfileStore requires - will be set up after packages are installed
local ProfileStore = nil
local Profiles = {}

local log = Logger.getModuleLogger("PlayerDataManager")

local PlayerDataManager = {}

-- Configuration
local PROFILE_STORE_NAME = "PlayerData"
local PROFILE_TEMPLATE = {
    money = 0, -- Will be set to GameConfig.Settings.startingMoney on first load
    rebirths = 0,
    extraSlots = 0,
    assignedFarm = nil,
    inventory = {
        seeds = {},
        crops = {}
    },
    plots = {}, -- [localPlotIndex] = {state, seedType, plantedAt, etc.}
    tutorial = {
        completed = false,
        skipped = false,
        currentStep = 1,
        completedSteps = {}, -- [stepId] = true for completed steps
        totalRewardsEarned = 0
    }
}

-- Initialize ProfileStore
function PlayerDataManager.initialize()
    -- Try to load ProfileStore (check both ServerStorage/Packages and ServerPackages)
    local success, profileStoreModule = pcall(function()
        -- First try ServerPackages (Wally default location)
        local serverPackages = game:GetService("ServerStorage"):FindFirstChild("ServerPackages")
        if serverPackages then
            local profileStore = serverPackages:FindFirstChild("profilestore")
            if profileStore then
                log.debug("Found ProfileStore in ServerPackages")
                return require(profileStore)
            end
        end
        
        -- Then try ServerStorage/Packages (alternative location)
        local serverStorage = game:GetService("ServerStorage")
        local packages = serverStorage:FindFirstChild("Packages")
        if packages then
            local profileStore = packages:FindFirstChild("ProfileStore")
            if profileStore then
                log.debug("Found ProfileStore in ServerStorage/Packages")
                return require(profileStore)
            end
        end
        
        log.info("ProfileStore package not found in any expected location")
        return nil
    end)
    
    if success and profileStoreModule then
        ProfileStore = profileStoreModule.new(PROFILE_STORE_NAME, PROFILE_TEMPLATE)
        log.info("ProfileStore initialized successfully for", PROFILE_STORE_NAME)
    else
        log.warn("ProfileStore not available - falling back to in-memory storage (Studio mode)")
        -- Keep fallback system for Studio testing
        ProfileStore = nil
    end
end

-- Handle player joining
function PlayerDataManager.onPlayerJoined(player)
    if not ProfileStore then
        log.warn("ProfileStore not initialized - using fallback data for", player.Name)
        return
    end
    
    local userId = tostring(player.UserId)
    local profile = ProfileStore:LoadProfileAsync(userId)
    
    if profile then
        profile:AddUserId(player.UserId) -- GDPR compliance
        profile:Reconcile() -- Fill in missing template values
        
        profile.OnRelease = function()
            Profiles[player] = nil
            player:Kick("Profile released - please rejoin")
        end
        
        if player.Parent then
            Profiles[player] = profile
            
            -- Set up starting values for new players
            if profile.Data.money == 0 then
                profile.Data.money = GameConfig.Settings.startingMoney
                
                -- Set starting seeds
                for seedType, count in pairs(GameConfig.Settings.startingSeeds) do
                    profile.Data.inventory.seeds[seedType] = count
                end
                
                log.info("Initialized new player data for", player.Name)
            else
                log.info("Loaded existing player data for", player.Name, "- Money:", profile.Data.money, "Rebirths:", profile.Data.rebirths)
            end
        else
            profile:Release()
        end
    else
        player:Kick("Failed to load player data - please try again")
    end
end

-- Handle player leaving
function PlayerDataManager.onPlayerLeaving(player)
    local profile = Profiles[player]
    if profile then
        profile:Release()
        log.info("Released profile for", player.Name)
    end
end

-- Get player data (returns the profile data or fallback)
function PlayerDataManager.getPlayerData(player)
    local profile = Profiles[player]
    if profile then
        return profile.Data
    end
    
    -- Fallback for Studio mode or when ProfileStore isn't available
    log.info("Using fallback data for", player.Name, "- ProfileStore not available (Studio mode)")
    local userId = tostring(player.UserId)
    
    if not _G.FallbackPlayerData then
        _G.FallbackPlayerData = {}
    end
    
    if not _G.FallbackPlayerData[userId] then
        _G.FallbackPlayerData[userId] = {
            money = GameConfig.Settings.startingMoney,
            rebirths = 0,
            extraSlots = 0,
            assignedFarm = nil,
            inventory = {
                seeds = {},
                crops = {}
            },
            plots = {},
            tutorial = {
                completed = false,
                skipped = false,
                currentStep = 1,
                completedSteps = {},
                totalRewardsEarned = 0
            },
            -- Legacy fields for backward compatibility
            tutorialCompleted = false,
            tutorialSkipped = false
        }
        
        -- Set starting seeds
        for seedType, count in pairs(GameConfig.Settings.startingSeeds) do
            _G.FallbackPlayerData[userId].inventory.seeds[seedType] = count
        end
        
        log.debug("Created new fallback data for", player.Name)
    else
        -- Ensure tutorial field exists in existing fallback data
        if not _G.FallbackPlayerData[userId].tutorial then
            _G.FallbackPlayerData[userId].tutorial = {
                completed = _G.FallbackPlayerData[userId].tutorialCompleted or false,
                skipped = _G.FallbackPlayerData[userId].tutorialSkipped or false,
                currentStep = 1,
                completedSteps = {},
                totalRewardsEarned = 0
            }
        end
        
        -- Ensure plots field exists
        if not _G.FallbackPlayerData[userId].plots then
            _G.FallbackPlayerData[userId].plots = {}
        end
        
        log.debug("Loaded existing fallback data for", player.Name)
    end
    
    return _G.FallbackPlayerData[userId]
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
    
    log.info("Player", player.Name, "rebirthed from", oldRebirths, "to", playerData.rebirths)
    
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

-- Get player's assigned farm
function PlayerDataManager.getAssignedFarm(player)
    local playerData = PlayerDataManager.getPlayerData(player)
    return playerData and playerData.assignedFarm
end

-- Set player's assigned farm
function PlayerDataManager.setAssignedFarm(player, farmId)
    local playerData = PlayerDataManager.getPlayerData(player)
    if playerData then
        playerData.assignedFarm = farmId
    end
end

-- Save plot state to player data (called by PlotManager)
function PlayerDataManager.savePlotState(player, plotIndex, plotState)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return false end
    
    -- Copy plot state to avoid reference issues
    playerData.plots[plotIndex] = {
        state = plotState.state,
        seedType = plotState.seedType,
        plantedTime = plotState.plantedTime,
        wateredTime = plotState.wateredTime,
        lastWateredTime = plotState.lastWateredTime,
        wateredCount = plotState.wateredCount,
        waterNeeded = plotState.waterNeeded,
        harvestCount = plotState.harvestCount,
        maxHarvests = plotState.maxHarvests,
        needsReplanting = plotState.needsReplanting,
        variation = plotState.variation,
        harvestCooldown = plotState.harvestCooldown,
        growthTime = plotState.growthTime,
        waterTime = plotState.waterTime,
        deathTime = plotState.deathTime,
        plantedAt = plotState.plantedAt,
        lastWateredAt = plotState.lastWateredAt,
        deathReason = plotState.deathReason
    }
    
    -- ProfileStore automatically handles saving - no manual save needed!
    log.debug("Saved plot", plotIndex, "state", plotState.state, "for player", player.Name, "(ProfileStore auto-save)")
    return true
end

-- Get plot state from player data (called by PlotManager)
function PlayerDataManager.getPlotState(player, plotIndex)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return nil end
    
    return playerData.plots[plotIndex]
end

-- Force save player data (used when player leaves or on critical actions)
function PlayerDataManager.forceSave(player)
    local profile = Profiles[player]
    if profile then
        -- ProfileStore handles saving automatically, but we can log the action
        log.debug("Force save requested for", player.Name, "(ProfileStore handles automatic saving)")
        return true
    end
    return false
end

-- Tutorial progress management
function PlayerDataManager.getTutorialProgress(player)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return nil end
    
    return playerData.tutorial
end

function PlayerDataManager.setTutorialStep(player, stepNumber)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return false end
    
    playerData.tutorial.currentStep = stepNumber
    log.debug("Set tutorial step for", player.Name, "to", stepNumber)
    return true
end

function PlayerDataManager.markTutorialStepCompleted(player, stepId, rewardAmount)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return false end
    
    playerData.tutorial.completedSteps[stepId] = true
    if rewardAmount then
        playerData.tutorial.totalRewardsEarned = playerData.tutorial.totalRewardsEarned + rewardAmount
    end
    
    log.debug("Marked tutorial step", stepId, "completed for", player.Name, "with reward", rewardAmount or 0)
    return true
end

function PlayerDataManager.completeTutorial(player, skipped)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return false end
    
    playerData.tutorial.completed = true
    playerData.tutorial.skipped = skipped or false
    
    log.info("Tutorial completed for", player.Name, "skipped:", skipped or false, "total rewards:", playerData.tutorial.totalRewardsEarned)
    return true
end

function PlayerDataManager.isTutorialCompleted(player)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return false end
    
    return playerData.tutorial.completed
end

-- Get ProfileStore statistics (for debugging)
function PlayerDataManager.getProfileStoreStats()
    if not ProfileStore then
        return "ProfileStore not initialized"
    end
    
    local activeProfiles = 0
    for _ in pairs(Profiles) do
        activeProfiles = activeProfiles + 1
    end
    
    return {
        activeProfiles = activeProfiles,
        storeName = PROFILE_STORE_NAME,
        templateVersion = "1.0"
    }
end

return PlayerDataManager