-- Chat Manager
-- Handles rank integration with chat system

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")

local Logger = require(script.Parent.Logger)
local RankConfig = require(game:GetService("ReplicatedStorage").Shared.RankConfig)
local PlayerDataManager = require(script.Parent.PlayerDataManager)
local NotificationManager = require(script.Parent.NotificationManager)

local ChatManager = {}
local log = Logger.getModuleLogger("ChatManager")

-- Track previous ranks to detect rank ups
local playerPreviousRanks = {} -- [userId] = previousRankThreshold

-- Initialize chat system
function ChatManager.initialize()
    log.info("Initializing ChatManager...")
    
    -- Check if new TextChatService is available
    if TextChatService then
        ChatManager.setupTextChatService()
    else
        ChatManager.setupLegacyChat()
    end
    
    log.info("ChatManager initialized successfully")
end

-- Setup new TextChatService (Roblox's new chat system)
function ChatManager.setupTextChatService()
    log.info("Setting up TextChatService integration...")
    
    -- OnIncomingMessage can only be set on the client
    -- For server-side rank integration, we'll use a different approach
    -- We'll handle rank announcements via system messages only
    
    log.info("TextChatService integration setup complete (server-side)")
end

-- Setup legacy chat system (fallback)
function ChatManager.setupLegacyChat()
    log.info("Setting up legacy chat integration...")
    
    -- Use StarterGui for legacy chat
    Players.PlayerAdded:Connect(function(player)
        player.Chatted:Connect(function(message)
            ChatManager.handlePlayerChatted(player, message)
        end)
    end)
    
    -- Handle existing players
    for _, player in pairs(Players:GetPlayers()) do
        player.Chatted:Connect(function(message)
            ChatManager.handlePlayerChatted(player, message)
        end)
    end
    
    log.info("Legacy chat integration setup complete")
end

-- Process incoming message (new TextChatService)
function ChatManager.processIncomingMessage(message)
    local player = Players:GetPlayerByUserId(message.TextSource.UserId)
    if not player then return message end
    
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return message end
    
    local rebirths = playerData.rebirths or 0
    local rankPrefix = RankConfig.getChatPrefix(rebirths)
    local rank = RankConfig.getRankForRebirths(rebirths)
    
    -- Create new message with rank prefix
    local newMessage = message:Clone()
    newMessage.Text = rankPrefix .. " " .. message.Text
    
    -- Apply rank color if possible
    if rank.color then
        newMessage.PrefixText = rankPrefix
        -- Note: TextChatService color formatting may vary
    end
    
    log.debug("Added rank prefix to message:", player.Name, rankPrefix)
    return newMessage
end

-- Handle player chatted (legacy system)
function ChatManager.handlePlayerChatted(player, message)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return end
    
    local rebirths = playerData.rebirths or 0
    local rankPrefix = RankConfig.getChatPrefix(rebirths)
    
    log.debug("Player", player.Name, "chatted with rank:", rankPrefix)
    
    -- For legacy chat, we can't modify the message after it's sent
    -- But we can use this for logging or other purposes
end

-- Announce rank up in chat
function ChatManager.announceRankUp(player, oldRank, newRank)
    if not player or not newRank then return end
    
    local message = string.format("🎉 %s has reached %s! 🎉", player.Name, newRank.name)
    
    -- Broadcast to all players
    ChatManager.broadcastSystemMessage(message, newRank.color)
    
    log.info("Announced rank up:", player.Name, "->", newRank.name)
end

-- Broadcast system message to all players
function ChatManager.broadcastSystemMessage(message, color)
    color = color or Color3.fromRGB(255, 255, 0) -- Default to yellow
    
    -- Server can't use DisplaySystemMessage - use notifications instead
    -- Send announcement to all players via notifications
    for _, player in pairs(Players:GetPlayers()) do
        NotificationManager.sendSuccess(player, message)
    end
    
    log.info("Broadcasted system message:", message)
end

-- Check for rank ups and announce them
function ChatManager.checkRankUp(player)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then 
        log.warn("No player data found for rank check:", player.Name)
        return 
    end
    
    local userId = player.UserId
    local currentRebirths = playerData.rebirths or 0
    local currentRank = RankConfig.getRankForRebirths(currentRebirths)
    
    -- Get previous rank
    local previousRankThreshold = playerPreviousRanks[userId] or 0
    local previousRank = RankConfig.getRankForRebirths(previousRankThreshold)
    
    log.error("🏆 RANK CHECK for", player.Name, "- Current:", currentRebirths, "rebirths (" .. currentRank.name .. "), Previous:", previousRankThreshold, "rebirths (" .. previousRank.name .. ")")
    
    -- Check if rank increased
    if currentRank.threshold > previousRank.threshold then
        -- Player ranked up!
        log.error("🎉 RANK UP DETECTED!", player.Name, "went from", previousRank.name, "to", currentRank.name)
        
        ChatManager.announceRankUp(player, previousRank, currentRank)
        
        -- Show special rank-up notification
        local NotificationManager = require(script.Parent.NotificationManager)
        NotificationManager.sendRankUpNotification(player, currentRank)
        
        -- Update rank display immediately
        local RankDisplayManager = require(script.Parent.RankDisplayManager)
        RankDisplayManager.updatePlayerRank(player)
    else
        log.debug("No rank change for", player.Name, "- threshold check:", currentRank.threshold, "vs", previousRank.threshold)
    end
    
    -- Update stored rank
    playerPreviousRanks[userId] = currentRebirths
end

-- Initialize player's rank tracking
function ChatManager.initializePlayer(player)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then 
        -- Retry after a short delay
        wait(1)
        playerData = PlayerDataManager.getPlayerData(player)
        if not playerData then return end
    end
    
    local userId = player.UserId
    local rebirths = playerData.rebirths or 0
    
    -- Store initial rank
    playerPreviousRanks[userId] = rebirths
    local initialRank = RankConfig.getRankForRebirths(rebirths)
    
    log.info("🏆 Initialized rank tracking for", player.Name, "with", rebirths, "rebirths (" .. initialRank.name .. ")")
end

-- Clean up when player leaves
function ChatManager.onPlayerRemoving(player)
    local userId = player.UserId
    playerPreviousRanks[userId] = nil
    log.debug("Cleaned up rank tracking for", player.Name)
end

-- Get player's current chat display name with rank
function ChatManager.getPlayerDisplayName(player)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return player.Name end
    
    local rebirths = playerData.rebirths or 0
    local rankPrefix = RankConfig.getChatPrefix(rebirths)
    
    return rankPrefix .. " " .. player.Name
end

-- Connect player events
Players.PlayerAdded:Connect(function(player)
    -- Initialize after a delay to ensure data is loaded
    spawn(function()
        wait(5) -- Give time for player data to load
        ChatManager.initializePlayer(player)
    end)
end)

Players.PlayerRemoving:Connect(ChatManager.onPlayerRemoving)

return ChatManager