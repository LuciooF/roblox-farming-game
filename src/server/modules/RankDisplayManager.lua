-- Rank Display Manager
-- Manages rank displays above player characters

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Logger = require(script.Parent.Logger)
local RankConfig = require(game:GetService("ReplicatedStorage").Shared.RankConfig)
local PlayerDataManager = require(script.Parent.PlayerDataManager)

local RankDisplayManager = {}
local log = Logger.getModuleLogger("RankDisplayManager")

-- Track active rank displays
local rankDisplays = {} -- [player] = {gui = BillboardGui, tween = Tween}

-- Create rank display above character
local function createRankDisplay(player, character)
    if not character or not character:FindFirstChild("Head") then
        return nil
    end
    
    -- Get player's current rank
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then
        log.debug("No player data available for rank display:", player.Name)
        return nil
    end
    
    local rebirths = playerData.rebirths or 0
    local rankInfo = RankConfig.getRankForRebirths(rebirths)
    local rankTier = RankConfig.getRankTier(rebirths)
    
    -- Create BillboardGui
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "RankDisplay"
    billboardGui.Size = UDim2.new(0, 150, 0, 25) -- Smaller size
    billboardGui.StudsOffset = Vector3.new(0, 3, 0) -- Position above head
    billboardGui.LightInfluence = 0
    billboardGui.Parent = character.Head
    
    -- Rank text (no background frame)
    local rankLabel = Instance.new("TextLabel")
    rankLabel.Name = "RankLabel"
    rankLabel.Size = UDim2.new(1, 0, 1, 0)
    rankLabel.Position = UDim2.new(0, 0, 0, 0)
    rankLabel.BackgroundTransparency = 1 -- No background
    rankLabel.Text = rankInfo.name
    rankLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
    rankLabel.TextScaled = true
    rankLabel.Font = Enum.Font.SourceSansBold
    rankLabel.TextStrokeTransparency = 0 -- Black outline
    rankLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    rankLabel.Parent = billboardGui
    
    -- Text size constraint
    local textSizeConstraint = Instance.new("UITextSizeConstraint")
    textSizeConstraint.MaxTextSize = 14 -- Smaller text
    textSizeConstraint.MinTextSize = 8
    textSizeConstraint.Parent = rankLabel
    
    log.debug("Created rank display for", player.Name, "- Rank:", rankInfo.name, "Rebirths:", rebirths)
    
    -- Add special effects for higher tiers (text effects only)
    local effectTween = nil
    if rankTier == "Ultimate" then
        -- Rainbow text effect for ultimate ranks
        local rainbowColors = {
            Color3.fromRGB(255, 100, 100), -- Red
            Color3.fromRGB(255, 200, 100), -- Orange  
            Color3.fromRGB(255, 255, 100), -- Yellow
            Color3.fromRGB(100, 255, 100), -- Green
            Color3.fromRGB(100, 200, 255), -- Blue
            Color3.fromRGB(200, 100, 255), -- Purple
        }
        
        local colorIndex = 1
        local function cycleColors()
            if rankLabel and rankLabel.Parent then
                rankLabel.TextColor3 = rainbowColors[colorIndex]
                colorIndex = (colorIndex % #rainbowColors) + 1
            end
        end
        
        -- Create a controllable rainbow effect with cleanup flag
        local rainbowActive = true
        local function startRainbowEffect()
            spawn(function()
                while rainbowActive and rankLabel and rankLabel.Parent do
                    cycleColors()
                    wait(0.5)
                end
            end)
        end
        
        startRainbowEffect()
        effectTween = {
            cleanup = function()
                rainbowActive = false
            end
        }
    elseif rankTier == "Elite" then
        -- Pulsing text effect for elite ranks
        effectTween = TweenService:Create(rankLabel,
            TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {TextTransparency = 0.3}
        )
        effectTween:Play()
    end
    
    return {
        gui = billboardGui,
        tween = effectTween
    }
end

-- Update player's rank display
function RankDisplayManager.updatePlayerRank(player)
    if not player.Character then
        log.debug("No character found for rank update:", player.Name)
        return
    end
    
    -- Remove existing display
    RankDisplayManager.removePlayerRank(player)
    
    -- Create new display
    local display = createRankDisplay(player, player.Character)
    if display then
        rankDisplays[player] = display
        log.debug("Updated rank display for", player.Name)
    end
end

-- Remove player's rank display
function RankDisplayManager.removePlayerRank(player)
    local display = rankDisplays[player]
    if display then
        if display.tween then
            log.debug("Cleaning up tween for", player.Name, "- tween type:", typeof(display.tween))
            
            -- Safely check if it has a cleanup function
            local hasCleanup, cleanupFunc = pcall(function() return display.tween.cleanup end)
            
            if hasCleanup and type(cleanupFunc) == "function" then
                -- It's a custom effect with cleanup function
                cleanupFunc()
                log.debug("Stopped custom effect for", player.Name)
            elseif typeof(display.tween) == "Tween" then
                -- It's a real Tween - cancel it properly
                display.tween:Cancel()
                display.tween:Destroy()
                log.debug("Stopped real tween for", player.Name)
            elseif typeof(display.tween) == "Instance" then
                -- It's an Instance (probably a Tween) - try to cancel
                if display.tween.Cancel then
                    display.tween:Cancel()
                    display.tween:Destroy()
                    log.debug("Stopped Instance tween for", player.Name)
                end
            else
                log.debug("Unknown tween type for", player.Name, ":", typeof(display.tween))
            end
        end
        if display.gui then
            display.gui:Destroy()
        end
        rankDisplays[player] = nil
        log.debug("Removed rank display for", player.Name)
    end
end

-- Handle character spawning
function RankDisplayManager.onCharacterAdded(character)
    local player = Players:GetPlayerFromCharacter(character)
    if not player then return end
    
    -- Wait for character to fully load and for player data to be available
    spawn(function()
        wait(2) -- Give more time for character and data to load
        
        -- Ensure player data is available before creating rank display
        local maxWait = 10 -- Maximum 10 seconds to wait for data
        local waitTime = 0
        
        while waitTime < maxWait do
            local playerData = PlayerDataManager.getPlayerData(player)
            if playerData then
                log.debug("Player data found for rank display:", player.Name)
                break
            end
            wait(0.5)
            waitTime = waitTime + 0.5
        end
        
        -- Create rank display
        RankDisplayManager.updatePlayerRank(player)
    end)
end

-- Handle player leaving
function RankDisplayManager.onPlayerRemoving(player)
    RankDisplayManager.removePlayerRank(player)
end

-- Initialize rank displays for all players
function RankDisplayManager.initialize()
    log.info("Initializing RankDisplayManager...")
    
    -- Connect events
    Players.PlayerRemoving:Connect(RankDisplayManager.onPlayerRemoving)
    
    -- Handle existing players
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character then
            RankDisplayManager.onCharacterAdded(player.Character)
        end
        
        -- Connect to future character spawns
        player.CharacterAdded:Connect(RankDisplayManager.onCharacterAdded)
    end
    
    -- Connect to new players
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(RankDisplayManager.onCharacterAdded)
    end)
    
    log.info("RankDisplayManager initialized successfully")
end

-- Update all player ranks (useful when rank system changes)
function RankDisplayManager.updateAllRanks()
    log.info("Updating all player ranks...")
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character then
            RankDisplayManager.updatePlayerRank(player)
        end
    end
end

-- Get rank info for player (utility function)
function RankDisplayManager.getPlayerRankInfo(player)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return nil end
    
    local rebirths = playerData.rebirths or 0
    local currentRank = RankConfig.getRankForRebirths(rebirths)
    local nextRank, rebirthsNeeded = RankConfig.getNextRank(rebirths)
    local progress = RankConfig.getRankProgress(rebirths)
    local tier = RankConfig.getRankTier(rebirths)
    
    return {
        current = currentRank,
        next = nextRank,
        rebirthsNeeded = rebirthsNeeded,
        progress = progress,
        tier = tier,
        rebirths = rebirths
    }
end

return RankDisplayManager