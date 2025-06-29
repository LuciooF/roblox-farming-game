-- Codes Manager
-- Handles code validation and reward distribution on the server

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

-- Get required modules
local PlayerDataManager = require(script.Parent.PlayerDataManager)
local Logger = require(script.Parent.Logger)
local log = Logger.getModuleLogger("CodesManager")

local CodesManager = {}

-- DataStore for tracking redeemed codes and like/favorite timestamps
local redeemedCodesDataStore = nil
local likeFavoriteDataStore = nil
pcall(function()
    redeemedCodesDataStore = DataStoreService:GetDataStore("RedeemedCodes")
    likeFavoriteDataStore = DataStoreService:GetDataStore("LikeFavoriteTimestamps")
end)

-- Valid codes configuration
local VALID_CODES = {
    ["WELCOME"] = {
        rewardType = "money",
        rewardAmount = 500,
        description = "Welcome bonus!",
        expiresAt = nil -- Never expires
    },
    -- Add more codes here as needed
    -- ["SUMMER2024"] = {
    --     rewardType = "seeds",
    --     seedType = "corn",
    --     rewardAmount = 10,
    --     description = "Summer special!",
    --     expiresAt = os.time() + (30 * 24 * 60 * 60) -- Expires in 30 days
    -- }
}

-- Check if a code has been redeemed by a player
local function hasRedeemedCode(player, code)
    if not redeemedCodesDataStore then
        log.warn("DataStore not available, cannot check redeemed codes")
        return false
    end
    
    local success, redeemed = pcall(function()
        local key = "Player_" .. player.UserId .. "_Code_" .. code
        return redeemedCodesDataStore:GetAsync(key)
    end)
    
    if not success then
        log.error("Failed to check redeemed code:", redeemed)
        return false
    end
    
    return redeemed == true
end

-- Check if player has redeemed any code before (to skip group/favorite check)
local function hasRedeemedAnyCode(player)
    if not redeemedCodesDataStore then
        log.warn("DataStore not available, cannot check redeemed codes")
        return false
    end
    
    local success, hasRedeemed = pcall(function()
        -- Check if player has redeemed any of the valid codes
        for code, _ in pairs(VALID_CODES) do
            local key = "Player_" .. player.UserId .. "_Code_" .. code
            local redeemed = redeemedCodesDataStore:GetAsync(key)
            if redeemed == true then
                return true
            end
        end
        return false
    end)
    
    if not success then
        log.error("Failed to check any redeemed codes:", hasRedeemed)
        return false
    end
    
    return hasRedeemed == true
end

-- Mark a code as redeemed by a player
local function markCodeAsRedeemed(player, code)
    if not redeemedCodesDataStore then
        log.warn("DataStore not available, cannot mark code as redeemed")
        return false
    end
    
    local success, err = pcall(function()
        local key = "Player_" .. player.UserId .. "_Code_" .. code
        redeemedCodesDataStore:SetAsync(key, true)
    end)
    
    if not success then
        log.error("Failed to mark code as redeemed:", err)
        return false
    end
    
    return true
end

-- Configuration for group and game requirements
local GROUP_ID = 1019485148 -- Your actual group ID
local LIKE_FAVORITE_WAIT_TIME = 120 -- 2 minutes in seconds

-- Check if player has like/favorite timestamp and if enough time has passed
local function hasLikedAndFavorited(player)
    if not likeFavoriteDataStore then
        log.warn("DataStore not available for like/favorite check")
        return true -- Allow if DataStore is unavailable
    end
    
    local success, timestamp = pcall(function()
        local key = "Player_" .. player.UserId .. "_LikeFavorite"
        return likeFavoriteDataStore:GetAsync(key)
    end)
    
    if not success then
        log.error("Failed to check like/favorite timestamp:", timestamp)
        return true -- Allow if check fails
    end
    
    if not timestamp then
        return false -- No timestamp means they haven't been prompted yet
    end
    
    -- Check if enough time has passed
    local currentTime = os.time()
    return (currentTime - timestamp) >= LIKE_FAVORITE_WAIT_TIME
end

-- Set like/favorite timestamp for player
local function setLikeFavoriteTimestamp(player)
    if not likeFavoriteDataStore then
        log.warn("DataStore not available, cannot set like/favorite timestamp")
        return false
    end
    
    local success, err = pcall(function()
        local key = "Player_" .. player.UserId .. "_LikeFavorite"
        likeFavoriteDataStore:SetAsync(key, os.time())
    end)
    
    if not success then
        log.error("Failed to set like/favorite timestamp:", err)
        return false
    end
    
    return true
end

-- Clear all redeemed codes for a player (debug function)
function CodesManager.clearPlayerCodes(player)
    if not redeemedCodesDataStore then
        log.warn("DataStore not available, cannot clear codes")
        return false
    end
    
    local success, err = pcall(function()
        -- Clear all codes for this player
        for code, _ in pairs(VALID_CODES) do
            local key = "Player_" .. player.UserId .. "_Code_" .. code
            redeemedCodesDataStore:RemoveAsync(key)
        end
        
        -- Also clear like/favorite timestamp
        if likeFavoriteDataStore then
            local likeFavoriteKey = "Player_" .. player.UserId .. "_LikeFavorite"
            likeFavoriteDataStore:RemoveAsync(likeFavoriteKey)
        end
    end)
    
    if not success then
        log.error("Failed to clear player codes:", err)
        return false
    end
    
    log.info("Cleared all codes and like/favorite timestamp for player:", player.Name)
    return true
end

-- Initialize the codes manager
function CodesManager.initialize()
    log.info("CodesManager initialized with", #VALID_CODES, "valid codes")
    
    -- Create remotes
    local farmingRemotes = ReplicatedStorage:WaitForChild("FarmingRemotes")
    local redeemCodeRemote = Instance.new("RemoteEvent")
    redeemCodeRemote.Name = "RedeemCode"
    redeemCodeRemote.Parent = farmingRemotes
    
    local clearCodesRemote = Instance.new("RemoteEvent")
    clearCodesRemote.Name = "ClearCodes"
    clearCodesRemote.Parent = farmingRemotes
    
    -- Handle code redemption requests
    redeemCodeRemote.OnServerEvent:Connect(function(player, code)
        if not code or type(code) ~= "string" then
            log.warn("Invalid code redemption request from", player.Name)
            redeemCodeRemote:FireClient(player, false, nil)
            return
        end
        
        -- Clean up the code (uppercase, trim whitespace)
        code = string.upper(string.gsub(code, "^%s*(.-)%s*$", "%1"))
        
        log.info("Player", player.Name, "attempting to redeem code:", code)
        
        -- Check if code is valid
        local codeData = VALID_CODES[code]
        if not codeData then
            log.info("Invalid code attempted:", code)
            redeemCodeRemote:FireClient(player, false, nil)
            return
        end
        
        -- Check if code has expired
        if codeData.expiresAt and os.time() > codeData.expiresAt then
            log.info("Expired code attempted:", code)
            redeemCodeRemote:FireClient(player, false, nil)
            return
        end
        
        -- Check if player has already redeemed this code
        if hasRedeemedCode(player, code) then
            log.info("Player", player.Name, "has already redeemed code:", code)
            redeemCodeRemote:FireClient(player, false, {
                error = "already_redeemed",
                message = "You have already redeemed this code!"
            })
            return
        end
        
        -- Check if player has liked and favorited (only for first-time code redeemers)
        if not hasRedeemedAnyCode(player) and not hasLikedAndFavorited(player) then
            log.info("Player", player.Name, "is redeeming their first code and needs to like and favorite")
            
            -- Get the like/favorite timestamp (create if doesn't exist)
            local timestamp = nil
            if likeFavoriteDataStore then
                local success, existingTimestamp = pcall(function()
                    local key = "Player_" .. player.UserId .. "_LikeFavorite"
                    return likeFavoriteDataStore:GetAsync(key)
                end)
                
                if success and existingTimestamp then
                    timestamp = existingTimestamp
                else
                    -- Set timestamp if this is their first attempt
                    setLikeFavoriteTimestamp(player)
                    timestamp = os.time()
                end
            else
                -- Set timestamp if this is their first attempt
                setLikeFavoriteTimestamp(player)
                timestamp = os.time()
            end
            
            redeemCodeRemote:FireClient(player, false, {
                error = "like_favorite_required",
                message = "Welcome! Please join our group and favorite the game to unlock codes!",
                groupId = GROUP_ID,
                waitTime = LIKE_FAVORITE_WAIT_TIME,
                timestamp = timestamp -- Send the timestamp for client-side calculation
            })
            return
        end
        
        -- Get player data
        local playerData = PlayerDataManager.getPlayerData(player)
        if not playerData then
            log.error("Failed to get player data for code redemption")
            redeemCodeRemote:FireClient(player, false, nil)
            return
        end
        
        -- Apply the reward
        local success = false
        if codeData.rewardType == "money" then
            -- Give money reward
            playerData.money = (playerData.money or 0) + codeData.rewardAmount
            success = true
            log.info("Gave", player.Name, "$" .. codeData.rewardAmount, "from code:", code)
            
        elseif codeData.rewardType == "seeds" then
            -- Give seeds reward (future implementation)
            if not playerData.inventory then
                playerData.inventory = {}
            end
            if not playerData.inventory.seeds then
                playerData.inventory.seeds = {}
            end
            
            local seedType = codeData.seedType
            playerData.inventory.seeds[seedType] = (playerData.inventory.seeds[seedType] or 0) + codeData.rewardAmount
            success = true
            log.info("Gave", player.Name, codeData.rewardAmount, seedType, "seeds from code:", code)
        end
        
        if success then
            -- Mark code as redeemed
            markCodeAsRedeemed(player, code)
            
            -- Sync player data (this also saves it)
            local RemoteManager = require(script.Parent.RemoteManager)
            RemoteManager.syncPlayerData(player)
            
            -- Send success response
            redeemCodeRemote:FireClient(player, true, {
                code = code,
                rewardType = codeData.rewardType,
                rewardAmount = codeData.rewardAmount,
                seedType = codeData.seedType,
                description = codeData.description
            })
            
            log.info("Code", code, "successfully redeemed by", player.Name)
        else
            redeemCodeRemote:FireClient(player, false, nil)
        end
    end)
    
    -- Handle clear codes requests (debug only)
    clearCodesRemote.OnServerEvent:Connect(function(player)
        log.info("Debug: Clearing codes for player", player.Name)
        local success = CodesManager.clearPlayerCodes(player)
        clearCodesRemote:FireClient(player, success)
    end)
end

-- Add a new code (for admin use)
function CodesManager.addCode(code, rewardData)
    if not code or not rewardData then
        log.error("Invalid code data provided")
        return false
    end
    
    VALID_CODES[string.upper(code)] = rewardData
    log.info("Added new code:", code)
    return true
end

-- Remove a code (for admin use)
function CodesManager.removeCode(code)
    if not code then
        return false
    end
    
    code = string.upper(code)
    if VALID_CODES[code] then
        VALID_CODES[code] = nil
        log.info("Removed code:", code)
        return true
    end
    
    return false
end

-- Get all valid codes (for admin use)
function CodesManager.getValidCodes()
    local codes = {}
    for code, data in pairs(VALID_CODES) do
        codes[code] = data
    end
    return codes
end

return CodesManager