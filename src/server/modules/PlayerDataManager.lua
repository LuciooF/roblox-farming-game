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
    unlockedPlots = 10, -- Start with 10 free plots, can purchase more through rebirths
    assignedFarm = nil,
    isInitialized = false, -- Explicit flag to detect new players safely
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
        ProfileStore = profileStoreModule.New(PROFILE_STORE_NAME, PROFILE_TEMPLATE)
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
        -- Still create leaderstats for fallback data
        spawn(function()
            wait(1) -- Wait for fallback data to be ready
            local fallbackData = PlayerDataManager.getPlayerData(player)
            if fallbackData then
                PlayerDataManager.createLeaderstats(player, fallbackData)
                
                -- Initialize tutorial AFTER fallback data is ready
                local TutorialManager = require(script.Parent.TutorialManager)
                TutorialManager.initializePlayer(player)
            end
        end)
        return
    end
    
    local userId = tostring(player.UserId)
    local profile = ProfileStore:StartSessionAsync(userId)
    
    if profile then
        profile:AddUserId(player.UserId) -- GDPR compliance
        profile:Reconcile() -- Fill in missing template values
        
        -- Ensure plots field exists after reconciliation
        if not profile.Data.plots then
            profile.Data.plots = {}
        end
        
        profile.OnRelease = function()
            Profiles[player] = nil
            player:Kick("Profile released - please rejoin")
        end
        
        if player.Parent then
            Profiles[player] = profile
            
            -- Set up starting values for new players using safe initialization flag
            log.debug("=== PROFILE DEBUG for", player.Name, "===")
            log.debug("profile.Data.isInitialized:", profile.Data.isInitialized)
            log.debug("profile.Data.money:", profile.Data.money)
            log.debug("Current seeds:")
            for seedType, count in pairs(profile.Data.inventory.seeds) do
                log.debug("  ", seedType, ":", count)
            end
            
            if not profile.Data.isInitialized then
                log.debug("NEW PLAYER: Giving starting resources")
                profile.Data.money = GameConfig.Settings.startingMoney
                
                -- Set starting crops
                for cropType, count in pairs(GameConfig.Settings.startingCrops) do
                    profile.Data.inventory.crops[cropType] = count
                    log.debug("  Gave", count, cropType, "crops")
                end
                
                profile.Data.isInitialized = true
                log.info("Initialized new player data for", player.Name, "- Money:", profile.Data.money, "Seeds given")
            else
                -- Safety check: Only give starter crops if player has NEVER had them (check for both low money AND no crops AND no rebirths)
                local totalCrops = 0
                for cropType, count in pairs(profile.Data.inventory.crops) do
                    totalCrops = totalCrops + count
                end
                
                if totalCrops == 0 and profile.Data.money <= 10 and profile.Data.rebirths == 0 then
                    log.warn("CORRUPTED NEW PLAYER: Low money, no crops, no rebirths - giving starter crops...")
                    
                    -- Give starter crops only for truly corrupted new players
                    for cropType, count in pairs(GameConfig.Settings.startingCrops) do
                        profile.Data.inventory.crops[cropType] = count
                        log.debug("  Fixed: Gave", count, cropType, "crops")
                    end
                    
                    log.info("Fixed corrupted new player profile for", player.Name, "- Gave missing starter crops")
                else
                    log.debug("EXISTING PLAYER: Using saved data")
                    log.info("Loaded existing player data for", player.Name, "- Money:", profile.Data.money, "Rebirths:", profile.Data.rebirths)
                end
            end
            log.debug("=== END PROFILE DEBUG ===")
            
            -- Create leaderstats for Roblox leaderboard
            PlayerDataManager.createLeaderstats(player, profile.Data)
            
            -- Initialize tutorial AFTER player data is fully loaded
            local TutorialManager = require(script.Parent.TutorialManager)
            TutorialManager.initializePlayer(player)
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
        -- Only call Release if this is a real ProfileStore profile (not fallback data)
        if profile.Release then
            profile:Release()
            log.info("Released ProfileStore profile for", player.Name)
        else
            log.debug("Cleared fallback data for", player.Name)
        end
        Profiles[player] = nil
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
            unlockedPlots = 10, -- Start with 10 free plots, can purchase more through rebirths
            assignedFarm = nil,
            isInitialized = true, -- Fallback data is always initialized with starter resources
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
        
        -- Set starting crops
        for cropType, count in pairs(GameConfig.Settings.startingCrops) do
            _G.FallbackPlayerData[userId].inventory.crops[cropType] = count
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
    playerData.money = 500 -- Reset to 500 money as requested
    -- Note: extraSlots is preserved through rebirth
    
    -- Reset plot ownership - keep first 10, reset others
    playerData.unlockedPlots = 10 -- Reset to base 10 plots
    
    -- Clear all plot states (crops will be removed)
    playerData.plots = {}
    
    -- Reset inventory to starting amounts
    playerData.inventory = {
        seeds = {},
        crops = {}
    }
    
    for cropType, count in pairs(GameConfig.Settings.startingCrops) do
        playerData.inventory.crops[cropType] = count
    end
    
    local newMultiplier = GameConfig.Rebirth.getCropMultiplier(playerData.rebirths)
    
    log.info("Player", player.Name, "rebirthed from", oldRebirths, "to", playerData.rebirths, "- plots reset to 10")
    
    -- Clear all crops from plots in the world
    local FarmManager = require(script.Parent.FarmManager)
    local farmId = FarmManager.getPlayerFarm(player.UserId)
    if farmId then
        local PlotManager = require(script.Parent.PlotManager)
        -- Clear all plots for this player
        for plotIndex = 1, 40 do -- Clear all possible plots
            local globalPlotId = FarmManager.getGlobalPlotId(farmId, plotIndex)
            PlotManager.resetPlot(globalPlotId)
        end
    end
    
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
        PlayerDataManager.updateLeaderstats(player) -- Update leaderboard
        return true
    end
    return false
end

-- Remove money from player
function PlayerDataManager.removeMoney(player, amount)
    local playerData = PlayerDataManager.getPlayerData(player)
    if playerData and playerData.money >= amount then
        playerData.money = playerData.money - amount
        PlayerDataManager.updateLeaderstats(player) -- Update leaderboard
        return true
    end
    return false
end

-- Get plot purchase price for next plot
function PlayerDataManager.getPlotPurchasePrice(player)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return nil end
    
    local currentPlots = playerData.unlockedPlots
    -- Price increases with each plot: $50, $100, $200, $400, etc.
    local basePrice = 50
    local priceMultiplier = math.pow(1.5, currentPlots - 10) -- Start multiplying after 10 plots
    return math.floor(basePrice * priceMultiplier)
end

-- Purchase a new plot
function PlayerDataManager.purchasePlot(player)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then 
        return false, "Player data not found"
    end
    
    local baseUnlocked, maxAvailable = PlayerDataManager.getAvailablePlotRange(player)
    
    -- Check if player can buy more plots based on rebirth level
    if playerData.unlockedPlots >= maxAvailable then
        local rebirths = playerData.rebirths or 0
        if rebirths == 0 then
            return false, "Need rebirth to unlock more plots!"
        else
            return false, "Maximum plots reached for this rebirth level!"
        end
    end
    
    local price = PlayerDataManager.getPlotPurchasePrice(player)
    if playerData.money < price then
        return false, "Need $" .. (price - playerData.money) .. " more coins!"
    end
    
    -- Purchase the plot
    playerData.money = playerData.money - price
    playerData.unlockedPlots = playerData.unlockedPlots + 1
    
    log.info("Player", player.Name, "purchased plot", playerData.unlockedPlots, "for $" .. price)
    
    return true, "Plot " .. playerData.unlockedPlots .. " unlocked for $" .. price .. "!"
end

-- Get number of unlocked plots for player
function PlayerDataManager.getUnlockedPlots(player)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return 10 end -- Default to 10 if no data (first 10 are always unlocked)
    
    return playerData.unlockedPlots or 10
end

-- Get which plots are available to purchase based on rebirth level
function PlayerDataManager.getAvailablePlotRange(player)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return 10, 10 end -- No plots available if no data
    
    local rebirths = playerData.rebirths or 0
    local baseUnlocked = 10 -- First 10 plots are always unlocked
    
    -- Each rebirth unlocks a new row of 5 plots for purchase
    -- Rebirth 1: plots 11-15 available
    -- Rebirth 2: plots 16-20 available  
    -- etc.
    if rebirths == 0 then
        return baseUnlocked, baseUnlocked -- Only base plots, no expansion
    else
        local maxAvailable = baseUnlocked + (rebirths * 5)
        return baseUnlocked, maxAvailable
    end
end

-- Check if a specific plot is unlocked for purchase (not necessarily owned)
function PlayerDataManager.isPlotAvailableForPurchase(player, plotIndex)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return false end
    
    local baseUnlocked, maxAvailable = PlayerDataManager.getAvailablePlotRange(player)
    
    -- First 10 plots are always owned after rebirth
    if plotIndex <= 10 then
        return true -- Always owned
    end
    
    -- Check if plot is in the available range for this rebirth level
    return plotIndex <= maxAvailable
end

-- Get plot visibility state for progressive unlocking
function PlayerDataManager.getPlotVisibilityState(player, plotIndex)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return "invisible", 0 end
    
    local unlockedPlots = playerData.unlockedPlots or 10
    local rebirths = playerData.rebirths or 0
    
    -- If plot is already owned, it should be empty/usable
    if plotIndex <= unlockedPlots then
        return "unlocked", 0 -- Normal brown color, fully usable
    end
    
    -- Calculate rebirth tiers (each rebirth unlocks 5 plots)
    local currentTierMax = 10 + (rebirths * 5) -- Max plots available for purchase at current rebirth
    local nextTierMax = 10 + ((rebirths + 1) * 5) -- Max plots for next rebirth
    
    if plotIndex <= currentTierMax then
        return "locked", 0 -- Available for purchase (red)
    elseif plotIndex <= nextTierMax then
        return "next_tier", rebirths + 1 -- Visible but no price (gray, shows rebirth requirement)
    else
        return "invisible", 0 -- Completely hidden
    end
end

-- Get which rebirth level unlocks a specific plot
function PlayerDataManager.getRequiredRebirthForPlot(plotIndex)
    if plotIndex <= 10 then
        return 0 -- Always unlocked
    end
    
    -- Each rebirth unlocks 5 plots: 11-15 = rebirth 1, 16-20 = rebirth 2, etc.
    return math.ceil((plotIndex - 10) / 5)
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
    if not playerData then 
        log.warn("Failed to save plot", plotIndex, "- no player data for", player.Name)
        return false 
    end
    
    -- Ensure plots table exists
    if not playerData.plots then
        playerData.plots = {}
    end
    
    -- Ensure we use string key for consistency (ProfileStore converts numeric keys to strings)
    local plotKey = tostring(plotIndex)
    
    -- Copy plot state to avoid reference issues
    playerData.plots[plotKey] = {
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
        deathReason = plotState.deathReason,
        lastUpdateTime = plotState.lastUpdateTime or tick()
    }
    
    -- ProfileStore automatically handles saving - no manual save needed!
    log.info("Saved plot", plotIndex, "state", plotState.state, "seed", plotState.seedType, "for player", player.Name)
    
    return true
end

-- Get plot state from player data (called by PlotManager)
function PlayerDataManager.getPlotState(player, plotIndex)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then 
        log.warn("Failed to get plot", plotIndex, "- no player data for", player.Name)
        return nil 
    end
    
    -- Check if plots table exists
    if not playerData.plots then
        return nil
    end
    
    -- Try both string and numeric keys (ProfileStore converts numeric keys to strings)
    local plotKey = tostring(plotIndex)
    local plotState = playerData.plots[plotKey] or playerData.plots[plotIndex]
    
    if plotState then
        log.info("Loading plot", plotIndex, "for", player.Name, "- state:", plotState.state, "seed:", plotState.seedType)
    else
        log.info("No saved plot", plotIndex, "found for", player.Name)
    end
    
    return plotState
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

-- Debug function to reset tutorial (for testing)
function PlayerDataManager.resetTutorial(player)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return false end
    
    playerData.tutorial.completed = false
    playerData.tutorial.skipped = false
    playerData.tutorial.currentStep = 1
    playerData.tutorial.completedSteps = {}
    playerData.tutorial.totalRewardsEarned = 0
    
    log.info("Tutorial reset for", player.Name)
    return true
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

-- Debug function to add rebirth
function PlayerDataManager.debugAddRebirth(player)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return false end
    
    playerData.rebirths = (playerData.rebirths or 0) + 1
    log.info("Debug: Added rebirth to", player.Name, "- now has", playerData.rebirths, "rebirths")
    return true
end

-- Debug function to reset rebirths
function PlayerDataManager.debugResetRebirths(player)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return false end
    
    playerData.rebirths = 0
    log.info("Debug: Reset rebirths for", player.Name)
    return true
end

-- Debug function to reset player datastore completely
function PlayerDataManager.debugResetDatastore(player)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return false end
    
    -- Reset to template values
    playerData.money = GameConfig.Settings.startingMoney
    playerData.rebirths = 0
    playerData.extraSlots = 0
    playerData.unlockedPlots = 10
    playerData.assignedFarm = nil
    playerData.isInitialized = true
    playerData.inventory = {
        seeds = {},
        crops = {}
    }
    playerData.plots = {}
    playerData.tutorial = {
        completed = false,
        skipped = false,
        currentStep = 1,
        completedSteps = {},
        totalRewardsEarned = 0
    }
    
    -- Set starting crops
    for cropType, count in pairs(GameConfig.Settings.startingCrops) do
        playerData.inventory.crops[cropType] = count
    end
    
    log.info("Debug: Completely reset datastore for", player.Name)
    return true
end

-- Debug function to add money
function PlayerDataManager.debugAddMoney(player, amount)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return false end
    
    amount = amount or 1000
    playerData.money = (playerData.money or 0) + amount
    log.info("Debug: Added $" .. amount .. " to", player.Name, "- now has $" .. playerData.money)
    return true
end

-- Create leaderstats for Roblox leaderboard
function PlayerDataManager.createLeaderstats(player, playerData)
    if not player or not player.Parent then return end
    
    -- Create leaderstats folder
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player
    
    -- Create Money stat
    local money = Instance.new("IntValue")
    money.Name = "Money"
    money.Value = playerData.money or 0
    money.Parent = leaderstats
    
    -- Create Rebirths stat
    local rebirths = Instance.new("IntValue")
    rebirths.Name = "Rebirths"
    rebirths.Value = playerData.rebirths or 0
    rebirths.Parent = leaderstats
    
    log.info("Created leaderstats for", player.Name, "- Money:", money.Value, "Rebirths:", rebirths.Value)
end

-- Update leaderstats when player data changes
function PlayerDataManager.updateLeaderstats(player)
    if not player or not player.Parent then return end
    
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end
    
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return end
    
    -- Update Money
    local money = leaderstats:FindFirstChild("Money")
    if money then
        money.Value = playerData.money or 0
    end
    
    -- Update Rebirths
    local rebirths = leaderstats:FindFirstChild("Rebirths")
    if rebirths then
        rebirths.Value = playerData.rebirths or 0
    end
end

return PlayerDataManager