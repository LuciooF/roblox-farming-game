-- Player Data Management Module with ProfileStore
-- Handles all player data operations with local caching and automatic saves

local GameConfig = require(script.Parent.GameConfig)
local Logger = require(script.Parent.Logger)
local NumberFormatter = require(game:GetService("ReplicatedStorage").Shared.NumberFormatter)

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
    unlockedPlots = 0, -- Start with 0 owned plots, must purchase them
    ownedPlots = {}, -- Track which specific plots are owned
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
    },
    settings = {
        musicEnabled = true -- Default to music on
    }
    -- Note: gamepasses are not stored in datastore - they're session-only from MarketplaceService
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
        
        -- Start periodic auto-save system
        PlayerDataManager.startAutoSaveSystem()
        
        -- Set up server shutdown handler
        PlayerDataManager.setupShutdownHandler()
    else
        log.warn("ProfileStore not available - falling back to in-memory storage (Studio mode)")
        -- Keep fallback system for Studio testing
        ProfileStore = nil
    end
end

-- Setup server shutdown handler to properly release all profiles
function PlayerDataManager.setupShutdownHandler()
    game:BindToClose(function()
        log.info("🛑 SERVER SHUTDOWN DETECTED - Force releasing all ProfileStore profiles")
        
        local releaseCount = 0
        local releaseErrors = 0
        
        for player, profile in pairs(Profiles) do
            if profile and profile.Release then
                log.info("🛑 Force releasing profile for", player.Name)
                
                local success, errorMsg = pcall(function()
                    -- Force save then release
                    if profile.Save then
                        profile:Save()
                    end
                    profile:Release()
                end)
                
                if success then
                    releaseCount = releaseCount + 1
                    log.info("✅ Successfully force released profile for", player.Name)
                else
                    releaseErrors = releaseErrors + 1
                    log.error("❌ Failed to force release profile for", player.Name, "Error:", errorMsg)
                end
            end
        end
        
        log.info("🛑 SHUTDOWN COMPLETE:", releaseCount, "profiles released,", releaseErrors, "errors")
        
        -- Give ProfileStore time to process releases
        wait(2)
    end)
end

-- Periodic auto-save system to reduce data loss risk
function PlayerDataManager.startAutoSaveSystem()
    spawn(function()
        while true do
            wait(30) -- Check every 30 seconds for orphaned profiles
            
            local savedCount = 0
            local errorCount = 0
            local orphanedProfiles = {}
            
            for player, profile in pairs(Profiles) do
                -- Check if player still exists in the game
                if not player.Parent then
                    -- Player left but profile wasn't released!
                    table.insert(orphanedProfiles, player.Name)
                    log.error("🚨 ORPHANED PROFILE DETECTED for", player.Name, "- Player left but profile still active!")
                    log.error("🚨 This causes 'already logged in this session' errors on rejoin!")
                    
                    -- Force release the orphaned profile immediately
                    if profile and profile.Release then
                        local success, errorMsg = pcall(function()
                            if profile.Save then
                                profile:Save()
                            end
                            profile:Release()
                        end)
                        
                        if success then
                            log.info("✅ Force released orphaned profile for", player.Name, "- Player can rejoin now")
                        else
                            log.error("❌ Failed to force release orphaned profile for", player.Name, "Error:", errorMsg)
                        end
                    end
                    
                    -- Clear from tracking immediately
                    Profiles[player] = nil
                end
            end
            
            -- Separate loop for auto-save (every 5 minutes)
            local currentTime = tick()
            for player, profile in pairs(Profiles) do
                if profile and profile.Save and player.Parent then
                    if not profile.lastAutoSave or (currentTime - profile.lastAutoSave) >= 300 then
                        local success, errorMsg = pcall(function()
                            profile:Save()
                        end)
                        
                        if success then
                            savedCount = savedCount + 1
                            profile.lastAutoSave = currentTime
                        else
                            errorCount = errorCount + 1
                            log.warn("Auto-save failed for", player.Name, "error:", errorMsg)
                        end
                    end
                end
            end
            
            if #orphanedProfiles > 0 then
                log.warn("🧹 FIXED DATASTORE LOCKS: Cleaned up", #orphanedProfiles, "orphaned profiles:", table.concat(orphanedProfiles, ", "))
            end
            
            if savedCount > 0 or errorCount > 0 then
                log.info("Auto-save completed:", savedCount, "saved,", errorCount, "errors")
            end
        end
    end)
end

-- Handle player joining
function PlayerDataManager.onPlayerJoined(player)
    local totalStartTime = tick()
    log.debug("🔄 PlayerDataManager.onPlayerJoined STARTED for:", player.Name)
    
    if not ProfileStore then
        log.error("🚫 CRITICAL: ProfileStore not initialized - CANNOT PROCEED")
        player:Kick("Game initialization error. Please try rejoining. If this persists, the game servers may be experiencing issues.")
        return
    end
    
    local userId = tostring(player.UserId)
    
    -- Add timeout handling for ProfileStore operations
    local profile = nil
    local profileSuccess = false
    
    log.debug("🔄 Starting ProfileStore session for:", player.Name)
    
    -- Use pcall with timeout and retry logic to handle profile locks
    local startTime = tick()
    spawn(function()
        local maxRetries = 5 -- Increased from 3 to 5 attempts
        local retryDelay = 2 -- Start with 2 seconds (increased from 1)
        
        for attempt = 1, maxRetries do
            local success, result = pcall(function()
                return ProfileStore:StartSessionAsync(userId)
            end)
            
            if success and result then
                profile = result
                profileSuccess = true
                log.info("✅ ProfileStore session completed for:", player.Name, "in", math.floor((tick() - startTime) * 1000), "ms", "- Attempt:", attempt)
                break
            else
                local errorMsg = tostring(result or "unknown error")
                log.warn("❌ ProfileStore attempt", attempt, "failed for", player.Name, "error:", errorMsg)
                
                -- Check if this is a "profile locked" error (common on quick rejoin)
                local isLockError = string.find(errorMsg:lower(), "locked") or 
                                   string.find(errorMsg:lower(), "session") or 
                                   string.find(errorMsg:lower(), "active") or
                                   string.find(errorMsg:lower(), "conflict") or
                                   string.find(errorMsg:lower(), "already loaded")
                
                if isLockError then
                    if string.find(errorMsg:lower(), "already loaded") then
                        log.warn("🔒 Profile 'already loaded' error for", player.Name, "- Previous session not properly closed. Waiting", retryDelay, "seconds...")
                    else
                        log.info("🔒 Profile is locked for", player.Name, "- Quick rejoin detected. Waiting", retryDelay, "seconds for unlock...")
                    end
                else
                    log.warn("❓ Unknown ProfileStore error for", player.Name, "- Will retry in", retryDelay, "seconds")
                end
                
                if attempt < maxRetries then
                    wait(retryDelay)
                    retryDelay = math.min(retryDelay * 1.3, 8) -- Gentler exponential backoff, capped at 8 seconds
                else
                    log.error("❌ All", maxRetries, "ProfileStore attempts failed for", player.Name, "final error:", errorMsg)
                end
            end
        end
    end)
    
    -- Optimized polling: check every 50ms instead of 100ms for faster response
    local RunService = game:GetService("RunService")
    local timeout = RunService:IsStudio() and 8 or 20 -- Increased timeout for 5 retry attempts with longer delays
    local elapsed = 0
    while not profileSuccess and elapsed < timeout and player.Parent do
        wait(0.05) -- Check every 50ms instead of 100ms
        elapsed = elapsed + 0.05
    end
    
    if not profileSuccess or not profile then
        local RunService = game:GetService("RunService")
        if RunService:IsStudio() then
            log.error("💥 STUDIO: ProfileStore failed - likely Studio DataStore limitations")
            log.error("🔧 Solutions:")
            log.error("   1. Enable Studio Access to API Services in Game Settings")
            log.error("   2. Test in published game instead of Studio")
            log.error("   3. Check internet connection")
            player:Kick("Studio DataStore Error: Enable 'Studio Access to API Services' in Game Settings > Security, or test in a published game.")
        else
            log.error("💥 CRITICAL: ProfileStore failed for", player.Name, "- CANNOT PROCEED WITHOUT PLAYER DATA")
            log.error("🔍 Root cause analysis needed:")
            log.error("   - DataStore API health issues?")
            log.error("   - Too many requests (throttling)?") 
            log.error("   - Network connectivity problems?")
            log.error("   - Profile lock from quick rejoin?")
            
            -- Check if we can determine the specific error type for better user messaging
            local userMessage = "Data loading failed after multiple attempts."
            
            -- Note: We can't access the specific error here since it was in the spawn thread
            -- But the retry logic above should handle most lock scenarios
            
            -- Give specific guidance for the most common scenario
            userMessage = userMessage .. "\n\n🔄 If you just left and rejoined quickly:"
            userMessage = userMessage .. "\n• Wait 15-30 seconds before rejoining"
            userMessage = userMessage .. "\n• Your data is safe and will be available shortly"
            userMessage = userMessage .. "\n\n⚡ For other issues:"
            userMessage = userMessage .. "\n• Check your internet connection"
            userMessage = userMessage .. "\n• Try rejoining in a few moments"
            
            player:Kick(userMessage)
        end
        return
    end
    
    if profile then
        profile:AddUserId(player.UserId) -- GDPR compliance
        profile:Reconcile() -- Fill in missing template values
        
        -- Ensure plots field exists after reconciliation
        if not profile.Data.plots then
            profile.Data.plots = {}
        end
        
        profile.OnRelease = function()
            Profiles[player] = nil
            log.warn("🚨 ProfileStore auto-released profile for", player.Name, "- This usually means server shutdown or force release")
            -- Don't kick if player already left (they won't be in game anymore)
            if player.Parent then
                player:Kick("Profile released - please rejoin")
            end
        end
        
        if player.Parent then
            Profiles[player] = profile
            
            -- Clear missing data tracking for this player
            if PlayerDataManager._loggedMissingData then
                PlayerDataManager._loggedMissingData[player.UserId] = nil
            end
            
            -- Set up starting values for new players using safe initialization flag
            
            if not profile.Data.isInitialized then
                log.debug("NEW PLAYER: Giving starting resources")
                profile.Data.money = GameConfig.Settings.startingMoney
                
                -- Set starting crops
                for cropType, count in pairs(GameConfig.Settings.startingCrops) do
                    profile.Data.inventory.crops[cropType] = count
                end
                
                -- Initialize plot ownership (start with 0 owned plots)
                if not profile.Data.ownedPlots then
                    profile.Data.ownedPlots = {}
                end
                profile.Data.unlockedPlots = 0
                
                profile.Data.isInitialized = true
                log.info("Initialized new player data for", player.Name, "- Money:", profile.Data.money, "Seeds given, 0 plots owned")
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
                    end
                    
                    log.info("Fixed corrupted new player profile for", player.Name, "- Gave missing starter crops")
                else
                    log.info("Loaded existing player data for", player.Name, "- Money:", profile.Data.money, "Rebirths:", profile.Data.rebirths)
                end
            end
            
            -- Create leaderstats for Roblox leaderboard
            PlayerDataManager.createLeaderstats(player, profile.Data)
            
            -- Initialize tutorial AFTER player data is fully loaded
            local TutorialManager = require(script.Parent.TutorialManager)
            TutorialManager.initializePlayer(player)
            
            -- Note: Gamepass initialization is now handled asynchronously in FarmingSystemNew.lua
            -- to prevent blocking the main PlayerDataManager.onPlayerJoined thread
            
            log.info("🔄 PlayerDataManager.onPlayerJoined COMPLETED for:", player.Name, "in", math.floor((tick() - totalStartTime) * 1000), "ms")
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
            log.info("🔄 Preparing to save and release ProfileStore profile for", player.Name)
            
            -- Step 1: Force manual save before release (ProfileStore best practice)
            local saveSuccess = false
            if profile.Save then
                local saveStartTime = tick()
                local success, errorMsg = pcall(function()
                    profile:Save()
                end)
                
                if success then
                    saveSuccess = true
                    log.info("✅ Manual save completed for", player.Name, "in", math.floor((tick() - saveStartTime) * 1000), "ms")
                else
                    log.warn("⚠️ Manual save failed for", player.Name, "Error:", errorMsg, "- Release will still attempt auto-save")
                end
            else
                log.debug("Profile:Save() method not available - relying on Release() auto-save")
                saveSuccess = true -- Continue with release anyway
            end
            
            -- Step 2: Clear from our tracking BEFORE release to prevent race conditions
            Profiles[player] = nil
            log.debug("🗑️ Cleared profile from tracking for", player.Name)
            
            -- Step 3: Add small delay to ensure save is processed
            if saveSuccess then
                wait(0.1) -- Brief delay to ensure save is processed
            end
            
            -- Step 4: Release the profile (this unlocks it for future sessions)
            local releaseStartTime = tick()
            local success, errorMsg = pcall(function()
                profile:Release()
            end)
            
            if success then
                log.info("✅ Successfully released ProfileStore profile for", player.Name, "in", math.floor((tick() - releaseStartTime) * 1000), "ms")
            else
                log.error("❌ Failed to release ProfileStore profile for", player.Name, "Error:", errorMsg)
                log.error("🚨 CRITICAL: Profile may remain locked for", player.Name, "- they may need to wait before rejoining")
                
                -- Try force release as last resort
                spawn(function()
                    wait(1)
                    log.warn("🔄 Attempting force release for", player.Name)
                    local forceSuccess, forceError = pcall(function()
                        profile:Release()
                    end)
                    if forceSuccess then
                        log.info("✅ Force release succeeded for", player.Name)
                    else
                        log.error("❌ Force release also failed for", player.Name, "Error:", forceError)
                    end
                end)
            end
        else
            log.debug("Cleared fallback data for", player.Name)
            Profiles[player] = nil
        end
    else
        log.debug("No profile found to release for", player.Name)
    end
end

-- Get player data (returns the profile data or fallback)
function PlayerDataManager.getPlayerData(player)
    local profile = Profiles[player]
    if profile then
        return profile.Data
    end
    
    -- NO FALLBACK FOR PLAYER DATA - This would be a security risk!
    -- Note: This can happen during initial load - only log once per player
    if not PlayerDataManager._loggedMissingData then
        PlayerDataManager._loggedMissingData = {}
    end
    
    if not PlayerDataManager._loggedMissingData[player.UserId] then
        log.debug("📊 getPlayerData() called before profile loaded for", player.Name, "- this is normal during optimized loading")
        PlayerDataManager._loggedMissingData[player.UserId] = true
    end
    
    return nil
end

-- Check if player can rebirth
function PlayerDataManager.canRebirth(playerData)
    local moneyRequired = GameConfig.Rebirth.getMoneyRequirement(playerData.rebirths)
    return playerData.money >= moneyRequired
end

-- Perform rebirth
function PlayerDataManager.performRebirth(player, bypassMoneyCheck)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return false end
    
    -- Allow bypassing money check for Robux purchases
    if not bypassMoneyCheck and not PlayerDataManager.canRebirth(playerData) then
        return false, "Not enough money"
    end
    
    -- Perform rebirth
    local oldRebirths = playerData.rebirths
    playerData.rebirths = playerData.rebirths + 1
    playerData.money = 100 -- Reset to 100 money after rebirth
    -- Note: extraSlots is preserved through rebirth
    
    -- Reset plot ownership - clear all owned plots
    playerData.ownedPlots = {}
    playerData.unlockedPlots = 0
    
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
    
    log.info("Player", player.Name, "rebirthed from", oldRebirths, "to", playerData.rebirths, "- all plots reset")
    
    -- Update leaderstats since money and rebirths changed
    PlayerDataManager.updateLeaderstats(player)
    
    -- Clear all crops from plots in the world and update visibility (async to prevent lag)
    spawn(function()
        local FarmManager = require(script.Parent.FarmManager)
        local farmId = FarmManager.getPlayerFarm(player.UserId)
        if farmId then
            local PlotManager = require(script.Parent.PlotManager)
            -- Clear all plots for this player
            for plotIndex = 1, 40 do -- Clear all possible plots
                local globalPlotId = FarmManager.getGlobalPlotId(farmId, plotIndex)
                PlotManager.resetPlot(globalPlotId)
            end
            log.debug("Async plot clearing completed for", player.Name)
            
            -- Update plot visibility states after rebirth reset
            log.debug("Updating plot visibility after rebirth for", player.Name)
            FarmManager.updatePlayerPlotVisibility(player)
            
            -- Add small delay and force another refresh to ensure plots are properly hidden
            wait(0.1)
            log.debug("Forcing secondary plot visibility refresh for", player.Name)
            FarmManager.updatePlayerPlotVisibility(player)
        end
    end)
    
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

-- Get plot purchase price for a specific plot
function PlayerDataManager.getPlotPurchasePrice(player, plotIndex)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return nil end
    
    -- First plot is free
    if plotIndex == 1 then
        return 0
    end
    
    local basePrice
    local priceMultiplier
    
    -- Plots 2-10 have increasing prices
    if plotIndex <= 10 then
        basePrice = 50
        priceMultiplier = math.pow(1.3, plotIndex - 2)
    else
        -- Plots beyond 10 cost more
        basePrice = 500
        priceMultiplier = math.pow(1.5, plotIndex - 11)
    end
    
    local baseTotal = basePrice * priceMultiplier
    
    -- Apply rebirth scaling: +0.5x per rebirth (so 10 rebirths = 5x price)
    local rebirths = playerData.rebirths or 0
    local rebirthMultiplier = 1 + (0.5 * rebirths)
    
    return math.floor(baseTotal * rebirthMultiplier)
end

-- Purchase a new plot
function PlayerDataManager.purchasePlot(player, plotIndex)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then 
        return false, "Player data not found"
    end
    
    -- Initialize ownedPlots if needed
    if not playerData.ownedPlots then
        playerData.ownedPlots = {}
    end
    
    -- Check if already owned
    if PlayerDataManager.isPlotOwned(player, plotIndex) then
        return false, "You already own this plot!"
    end
    
    -- Check if available for purchase
    if not PlayerDataManager.isPlotAvailableForPurchase(player, plotIndex) then
        if plotIndex > 10 then
            local requiredRebirth = PlayerDataManager.getRequiredRebirthForPlot(plotIndex)
            return false, "Need rebirth level " .. requiredRebirth .. " to unlock this plot!"
        end
        return false, "This plot is not available for purchase!"
    end
    
    -- Get price for this specific plot
    local price = PlayerDataManager.getPlotPurchasePrice(player, plotIndex)
    if plotIndex == 1 then
        price = 0 -- First plot is free
    end
    
    if playerData.money < price then
        return false, "Need $" .. (price - playerData.money) .. " more coins!"
    end
    
    -- Purchase the plot
    playerData.money = playerData.money - price
    playerData.ownedPlots[tostring(plotIndex)] = true
    playerData.unlockedPlots = (playerData.unlockedPlots or 0) + 1
    
    -- Update leaderstats since money changed
    PlayerDataManager.updateLeaderstats(player)
    
    log.info("Player", player.Name, "purchased plot", plotIndex, "for $" .. price)
    
    local message = plotIndex == 1 and "First plot unlocked for FREE!" or "Plot " .. plotIndex .. " unlocked for $" .. price .. "!"
    return true, message, plotIndex
end

-- Get number of owned plots for player
function PlayerDataManager.getUnlockedPlots(player)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return 0 end
    
    -- Count owned plots
    if playerData.ownedPlots then
        local count = 0
        for _, owned in pairs(playerData.ownedPlots) do
            if owned then count = count + 1 end
        end
        return count
    end
    
    -- Legacy support
    return playerData.unlockedPlots or 0
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

-- Check if a specific plot is owned by the player
function PlayerDataManager.isPlotOwned(player, plotIndex)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return false end
    
    -- Check if plot is in the owned plots list
    if playerData.ownedPlots then
        return playerData.ownedPlots[tostring(plotIndex)] == true
    end
    
    -- Legacy support: if using old unlockedPlots system
    return plotIndex <= (playerData.unlockedPlots or 0)
end

-- Check if a specific plot is available for purchase
function PlayerDataManager.isPlotAvailableForPurchase(player, plotIndex)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return false end
    
    -- Already owned?
    if PlayerDataManager.isPlotOwned(player, plotIndex) then
        return false
    end
    
    -- First 10 plots are always available to purchase
    if plotIndex <= 10 then
        return true
    end
    
    -- Beyond plot 10 requires rebirths
    local baseUnlocked, maxAvailable = PlayerDataManager.getAvailablePlotRange(player)
    return plotIndex <= maxAvailable
end

-- Get plot visibility state for progressive unlocking
function PlayerDataManager.getPlotVisibilityState(player, plotIndex)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return "invisible", 0 end
    
    local rebirths = playerData.rebirths or 0
    
    -- If plot is already owned, it should be empty/usable
    if PlayerDataManager.isPlotOwned(player, plotIndex) then
        return "unlocked", 0 -- Normal brown color, fully usable
    end
    
    -- First 10 plots are always visible and purchasable
    if plotIndex <= 10 then
        return "locked", 0 -- Available for purchase (red)
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
    if not playerData then return false, 0 end
    
    if not playerData.inventory[itemType] then
        playerData.inventory[itemType] = {}
    end
    
    -- Implement 1k crop limit for crops
    if itemType == "crops" then
        local currentAmount = playerData.inventory[itemType][itemName] or 0
        local CROP_LIMIT = 1000
        
        if currentAmount >= CROP_LIMIT then
            -- Already at limit, can't add any
            return true, 0, true -- success, amountAdded, limitHit
        elseif currentAmount + amount > CROP_LIMIT then
            -- Would exceed limit, add only what fits
            local amountToAdd = CROP_LIMIT - currentAmount
            playerData.inventory[itemType][itemName] = CROP_LIMIT
            return true, amountToAdd, true -- success, amountAdded, limitHit
        else
            -- Normal addition, under limit
            playerData.inventory[itemType][itemName] = currentAmount + amount
            return true, amount, false -- success, amountAdded, limitHit
        end
    else
        -- Non-crop items have no limit
        playerData.inventory[itemType][itemName] = (playerData.inventory[itemType][itemName] or 0) + amount
        return true, amount, false
    end
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
        -- Update leaderstats since money changed
        PlayerDataManager.updateLeaderstats(player)
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
    local plotDataToSave = {
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
        lastUpdateTime = plotState.lastUpdateTime or tick(),
        
        -- Growth calculator fields
        accumulatedCrops = plotState.accumulatedCrops or 0,
        lastReadyTime = plotState.lastReadyTime or 0,
        baseYieldRate = plotState.baseYieldRate or 1,
        
        -- Maintenance watering system
        lastMaintenanceWater = plotState.lastMaintenanceWater or 0,
        needsMaintenanceWater = plotState.needsMaintenanceWater or false,
        maintenanceWaterInterval = plotState.maintenanceWaterInterval or 43200,
        
        -- Add save timestamp for debugging
        savedAt = tick()
    }
    
    -- Save to player data in memory
    playerData.plots[plotKey] = plotDataToSave
    
    -- CRITICAL: Verify the save worked by reading it back
    local verification = playerData.plots[plotKey]
    if not verification or verification.state ~= plotState.state or verification.accumulatedCrops ~= (plotState.accumulatedCrops or 0) then
        log.error("❌ SAVE VERIFICATION FAILED for plot", plotIndex, "player", player.Name)
        log.error("Expected state:", plotState.state, "crops:", plotState.accumulatedCrops)
        log.error("Actual saved:", verification and verification.state or "nil", "crops:", verification and verification.accumulatedCrops or "nil")
        return false
    end
    
    -- ProfileStore automatically handles DataStore persistence, but we should log when critical data is saved
    if plotState.accumulatedCrops and plotState.accumulatedCrops > 0 then
        log.warn("🌾 CRITICAL SAVE: Plot", plotIndex, "has", plotState.accumulatedCrops, "crops ready for", player.Name, "- ProfileStore MUST persist this!")
    end
    
    log.info("✅ Saved plot", plotIndex, "state:", plotState.state, "seed:", plotState.seedType, "crops:", plotState.accumulatedCrops or 0, "for player", player.Name)
    
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
    -- Update leaderstats since rebirths changed
    PlayerDataManager.updateLeaderstats(player)
    log.info("Debug: Added rebirth to", player.Name, "- now has", playerData.rebirths, "rebirths")
    return true
end

-- Debug function to reset rebirths
function PlayerDataManager.debugResetRebirths(player)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return false end
    
    playerData.rebirths = 0
    -- Update leaderstats since rebirths changed
    PlayerDataManager.updateLeaderstats(player)
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
    playerData.unlockedPlots = 0 -- Start with 0 owned plots
    playerData.ownedPlots = {} -- No plots owned initially
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
    
    -- Update leaderstats since money and rebirths changed
    PlayerDataManager.updateLeaderstats(player)
    
    log.info("Debug: Completely reset datastore for", player.Name)
    return true
end

-- Debug function to add money
function PlayerDataManager.debugAddMoney(player, amount)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return false end
    
    amount = amount or 1000
    playerData.money = (playerData.money or 0) + amount
    -- Update leaderstats since money changed
    PlayerDataManager.updateLeaderstats(player)
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
    
    -- Create Money stat with formatted display
    local money = Instance.new("StringValue")
    money.Name = "Money"
    money.Value = NumberFormatter.format(playerData.money or 0)
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
    
    -- Update Money with formatted display
    local money = leaderstats:FindFirstChild("Money")
    if money then
        money.Value = NumberFormatter.format(playerData.money or 0)
    end
    
    -- Update Rebirths
    local rebirths = leaderstats:FindFirstChild("Rebirths")
    if rebirths then
        rebirths.Value = playerData.rebirths or 0
    end
end

-- Get music preference
function PlayerDataManager.getMusicEnabled(player)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return true end -- Default to true if no data
    
    -- Handle legacy players who don't have settings yet
    if not playerData.settings then
        playerData.settings = { musicEnabled = true }
    end
    
    return playerData.settings.musicEnabled
end

-- Set music preference
function PlayerDataManager.setMusicEnabled(player, enabled)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return false end
    
    -- Initialize settings if not present (for legacy players)
    if not playerData.settings then
        playerData.settings = {}
    end
    
    playerData.settings.musicEnabled = enabled
    log.debug("Set music preference for", player.Name, "to", enabled)
    return true
end

return PlayerDataManager