-- Gamepass Service
-- Handles gamepass purchasing, validation, and persistence

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Logger = require(script.Parent.Logger)
local GamepassConfig = require(game:GetService("ReplicatedStorage").Shared.GamepassConfig)
local PlayerDataManager = require(script.Parent.PlayerDataManager)

local GamepassService = {}
local log = Logger.getModuleLogger("GamepassService")

-- Session cache for gamepass ownership (per session only)
local sessionGamepassCache = {} -- [userId] = {gamepassKey = boolean}

-- Cache for gamepass prices (to avoid repeated API calls)
local priceCache = {} -- [gamepassId] = {price = number, robux = string, lastFetched = tick()}

-- Initialize gamepass service
function GamepassService.initialize()
    log.info("Initializing GamepassService...")
    
    -- Connect to purchase events
    MarketplaceService.ProcessReceipt = GamepassService.processReceipt
    MarketplaceService.PromptGamePassPurchaseFinished:Connect(GamepassService.onPurchaseFinished)
    
    log.info("GamepassService initialized successfully")
end

-- Initialize gamepass ownership for a player (called when they join)
function GamepassService.initializePlayerGamepassOwnership(player)
    local userId = player.UserId
    sessionGamepassCache[userId] = {}
    
    log.info("Initializing gamepass ownership for", player.Name)
    
    -- Check all configured gamepasses
    for gamepassKey, gamepass in pairs(GamepassConfig.getAllGamepasses()) do
        local success, owns = pcall(function()
            return MarketplaceService:UserOwnsGamePassAsync(userId, gamepass.id)
        end)
        
        if success then
            sessionGamepassCache[userId][gamepassKey] = owns
            if owns then
                log.info("Player", player.Name, "owns gamepass:", gamepassKey)
            end
        else
            log.warn("Failed to check gamepass", gamepassKey, "for", player.Name)
            sessionGamepassCache[userId][gamepassKey] = false
        end
    end
    
    log.info("Gamepass initialization complete for", player.Name)
end

-- Check if player owns a gamepass (from session cache)
function GamepassService.playerOwnsGamepass(player, gamepassId)
    local gamepassKey, gamepass = GamepassConfig.getGamepassById(gamepassId)
    if not gamepassKey then
        return false
    end
    
    return GamepassService.playerOwnsGamepassKey(player, gamepassKey)
end

-- Check if player owns a gamepass by key name
function GamepassService.playerOwnsGamepassKey(player, gamepassKey)
    local userId = player.UserId
    
    -- Check session cache
    if sessionGamepassCache[userId] and sessionGamepassCache[userId][gamepassKey] ~= nil then
        return sessionGamepassCache[userId][gamepassKey]
    end
    
    -- If not in cache, assume false (shouldn't happen if properly initialized)
    log.warn("Gamepass", gamepassKey, "not found in session cache for", player.Name)
    return false
end

-- Get all gamepasses owned by player
function GamepassService.getPlayerGamepasses(player)
    local userId = player.UserId
    
    -- Return session cache or empty table
    return sessionGamepassCache[userId] or {}
end

-- Prompt player to purchase gamepass
function GamepassService.promptPurchase(player, gamepassKey)
    local gamepass = GamepassConfig.getGamepass(gamepassKey)
    if not gamepass then
        log.warn("Attempted to prompt purchase for unknown gamepass:", gamepassKey)
        return false
    end
    
    -- Check if player already owns it
    if GamepassService.playerOwnsGamepass(player, gamepass.id) then
        log.info("Player", player.Name, "already owns gamepass", gamepassKey)
        return false
    end
    
    -- Prompt purchase
    local success = pcall(function()
        MarketplaceService:PromptGamePassPurchase(player, gamepass.id)
    end)
    
    if success then
        log.info("Prompted gamepass purchase for", player.Name, "gamepass:", gamepassKey)
        return true
    else
        log.warn("Failed to prompt gamepass purchase for", player.Name, "gamepass:", gamepassKey)
        return false
    end
end

-- Handle purchase completion
function GamepassService.onPurchaseFinished(player, gamepassId, wasPurchased)
    local gamepassKey, gamepass = GamepassConfig.getGamepassById(gamepassId)
    
    if wasPurchased and gamepass and gamepassKey then
        log.info("🎉 Player", player.Name, "successfully purchased gamepass:", gamepassKey)
        
        -- Update session cache
        local userId = player.UserId
        if not sessionGamepassCache[userId] then
            sessionGamepassCache[userId] = {}
        end
        sessionGamepassCache[userId][gamepassKey] = true
        
        -- Sync updated gamepass data to client
        local RemoteManager = require(script.Parent.RemoteManager)
        RemoteManager.syncPlayerData(player)
        
        -- Apply gamepass effects with notification for new purchase
        GamepassService.applyGamepassEffects(player, gamepassKey, true) -- true = new purchase
        
        log.info("Session cache updated for", player.Name, "- now owns:", gamepassKey)
    end
end

-- Process receipt for developer products (future use)
function GamepassService.processReceipt(receiptInfo)
    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
    if not player then
        log.warn("Player not found for receipt:", receiptInfo.PlayerId)
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
    
    local productId = receiptInfo.ProductId
    log.info("Processing developer product purchase:", productId, "for player:", player.Name)
    
    -- Handle rebirth developer product
    if productId == 3320263208 then
        log.info("Rebirth product purchased by", player.Name)
        
        -- Give the player an instant rebirth (bypass money check for Robux purchase)
        local success, result = PlayerDataManager.performRebirth(player, true)
        if success then
            log.info("Rebirth granted to", player.Name, "via Robux purchase")
            
            -- Sync player data to client (same as normal rebirth)
            local RemoteManager = require(script.Parent.RemoteManager)
            RemoteManager.syncPlayerData(player)
            
            -- Force a complete farm refresh to update all plot visuals after rebirth
            local FarmManager = require(script.Parent.FarmManager)
            local farmId = FarmManager.getPlayerFarm(player.UserId)
            if farmId then
                log.info("🔄 Refreshing all plots after Robux rebirth for", player.Name)
                FarmManager.onFarmAssigned(farmId, player)
                
                -- Explicitly clear all plot visuals to remove any lingering text/displays  
                local WorldBuilder = require(script.Parent.Parent.WorldBuilder)
                local playerData = PlayerDataManager.getPlayerData(player)
                if playerData and playerData.plots then
                    for plotId, plotData in pairs(playerData.plots) do
                        local plot = WorldBuilder.getPlotById(plotId)
                        if plot then
                            WorldBuilder.clearPlotDisplay(plot)
                        end
                    end
                end
            end
            
            -- Play special rebirth sound immediately
            local SoundManager = require(script.Parent.SoundManager)
            SoundManager.playRebirthSound()
            
            -- Send rebirth notification (same as normal rebirth)
--             local NotificationManager = require(script.Parent.NotificationManager)
--             NotificationManager.sendRebirthNotification(player, result)
            
            -- Make potentially slow operations async to prevent lag
            spawn(function()
                -- Update player's rank display (async)
                local RankDisplayManager = require(script.Parent.RankDisplayManager)
                RankDisplayManager.updatePlayerRank(player)
                
                -- Check for rank up and announce in chat (async)
                local ChatManager = require(script.Parent.ChatManager)
                ChatManager.checkRankUp(player)
                
                -- Update farm nameplate with new rank (async)
                if farmId then
                    log.info("🏠 Updating farm nameplate for", player.Name, "on farm", farmId)
                    local WorldBuilder = require(script.Parent.Parent.WorldBuilder)
                    WorldBuilder.updateFarmNameOnly(farmId, player.Name, player)
                else
                    log.warn("🏠 No farm found for", player.Name, "- cannot update nameplate")
                end
            end)
            
            return Enum.ProductPurchaseDecision.PurchaseGranted
        else
            log.error("Failed to grant rebirth to", player.Name, "even though they purchased it")
            return Enum.ProductPurchaseDecision.NotProcessedYet
        end
    end
    
    log.warn("Unknown developer product purchased:", productId, "by", player.Name)
    return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- Get gamepass data for client (no persistence needed)
function GamepassService.getGamepassDataForClient(player)
    return GamepassService.getPlayerGamepasses(player)
end

-- Apply gamepass effects when player joins or purchases
function GamepassService.applyGamepassEffects(player, gamepassKey, isNewPurchase)
    -- Effects are handled in the respective systems (e.g., money multiplier in selling)
    -- This function is for immediate effects like inventory expansion, etc.
    
    if gamepassKey == "moneyMultiplier" then
        -- Money multiplier is passive - no immediate effect needed
        log.debug("2x Money Boost is now active for", player.Name)
    elseif gamepassKey == "flyMode" then
        -- Fly mode is passive - handled by FlyController
        log.debug("Fly Mode is now active for", player.Name)
    elseif gamepassKey == "productionBoost" then
        -- Production boost is passive - handled by PlotManager production calculations
        log.debug("2x Production Boost is now active for", player.Name)
    end
    
    -- Only send notification for new purchases, not existing ownership
    if isNewPurchase then
        local gamepass = GamepassConfig.getGamepass(gamepassKey)
        if gamepass then
--             local NotificationManager = require(script.Parent.NotificationManager)
--             NotificationManager.sendSuccess(player, "🎉 " .. gamepass.name .. " activated!")
        end
    end
end

-- Get gamepass info from MarketplaceService (with caching)
function GamepassService.getGamepassInfo(gamepassId)
    -- Check cache first (cache for 1 hour)
    local cached = priceCache[gamepassId]
    if cached and (tick() - cached.lastFetched) < 3600 then
        return cached.price, cached.robux, cached.iconUrl
    end
    
    -- Fetch from MarketplaceService
    local success, productInfo = pcall(function()
        return MarketplaceService:GetProductInfo(gamepassId, Enum.InfoType.GamePass)
    end)
    
    if success and productInfo then
        local price = productInfo.PriceInRobux or 0
        local robuxString = "R$ " .. tostring(price)
        local iconUrl = productInfo.IconImageAssetId and ("rbxassetid://" .. productInfo.IconImageAssetId) or nil
        
        -- Cache the result
        priceCache[gamepassId] = {
            price = price,
            robux = robuxString,
            iconUrl = iconUrl,
            lastFetched = tick()
        }
        
        log.debug("Fetched gamepass info for ID", gamepassId, "- Price:", robuxString, "Icon:", iconUrl or "none")
        return price, robuxString, iconUrl
    else
        log.warn("Failed to fetch gamepass info for ID", gamepassId)
        return 0, "R$ ?", nil
    end
end

-- Get gamepass price from MarketplaceService (backward compatibility)
function GamepassService.getGamepassPrice(gamepassId)
    local price, robuxString, _ = GamepassService.getGamepassInfo(gamepassId)
    return price, robuxString
end

-- Get all gamepass data for client (including icons)
function GamepassService.getAllGamepassData()
    local data = {}
    
    for key, gamepass in pairs(GamepassConfig.getAllGamepasses()) do
        local price, robuxString, iconUrl = GamepassService.getGamepassInfo(gamepass.id)
        data[key] = {
            price = price,
            robux = robuxString,
            iconUrl = iconUrl,
            id = gamepass.id
        }
    end
    
    return data
end

-- Get all gamepass prices for client (backward compatibility)
function GamepassService.getAllGamepassPrices()
    local prices = {}
    
    for key, gamepass in pairs(GamepassConfig.getAllGamepasses()) do
        local price, robuxString = GamepassService.getGamepassPrice(gamepass.id)
        prices[key] = {
            price = price,
            robux = robuxString,
            id = gamepass.id
        }
    end
    
    return prices
end

-- Get money multiplier for player (used by selling system)
function GamepassService.getMoneyMultiplier(player)
    if GamepassService.playerOwnsGamepassKey(player, "moneyMultiplier") then
        local gamepass = GamepassConfig.getGamepass("moneyMultiplier")
        return gamepass.multiplier or 2.0
    end
    return 1.0
end

-- Prompt gamepass purchase via RemoteEvent (called from client)
function GamepassService.promptGamepassPurchase(player, gamepassKey)
    local gamepass = GamepassConfig.getGamepass(gamepassKey)
    if not gamepass then
        return false, "Invalid gamepass: " .. tostring(gamepassKey)
    end
    
    -- Check if player already owns this gamepass
    if GamepassService.playerOwnsGamepassKey(player, gamepassKey) then
        return false, "You already own " .. gamepass.name .. "!"
    end
    
    -- Prompt the purchase
    log.info("Attempting to prompt purchase for gamepass ID:", gamepass.id, "name:", gamepass.name)
    local success = GamepassService.promptPurchase(player, gamepassKey)
    
    if success then
        log.info("Purchase prompt opened for", player.Name, "- gamepass:", gamepassKey, "ID:", gamepass.id)
        return true, "Purchase prompt opened for " .. gamepass.name
    else
        log.error("Failed to prompt gamepass purchase for", player.Name, "gamepass:", gamepassKey, "ID:", gamepass.id)
        return false, "Failed to open purchase prompt for " .. gamepass.name
    end
end

-- Initialize player gamepasses when they join
function GamepassService.initializePlayerGamepasses(player)
    log.debug("Initializing gamepasses for", player.Name)
    
    -- Initialize gamepass ownership from MarketplaceService
    GamepassService.initializePlayerGamepassOwnership(player)
    
    -- Apply all owned gamepass effects (silent for existing ownership)
    for gamepassKey, owned in pairs(GamepassService.getPlayerGamepasses(player)) do
        if owned then
            GamepassService.applyGamepassEffects(player, gamepassKey, false) -- false = not a new purchase
        end
    end
end

-- Clear cache when player leaves
function GamepassService.onPlayerRemoving(player)
    sessionGamepassCache[player.UserId] = nil
    log.debug("Cleared gamepass session cache for", player.Name)
end

-- Connect player events
Players.PlayerRemoving:Connect(GamepassService.onPlayerRemoving)

return GamepassService