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
    billboardGui.Size = UDim2.new(0, 200, 0, 40)
    billboardGui.StudsOffset = Vector3.new(0, 3, 0) -- Position above head
    billboardGui.LightInfluence = 0
    billboardGui.Parent = character.Head
    
    -- Background frame
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.Position = UDim2.new(0, 0, 0, 0)
    background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    background.BackgroundTransparency = 0.3
    background.BorderSizePixel = 0
    background.Parent = billboardGui
    
    -- Rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = background
    
    -- Gradient for higher tiers
    if rankTier ~= "Beginner" and rankTier ~= "Intermediate" then
        local gradient = Instance.new("UIGradient")
        if rankTier == "Ultimate" then
            gradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 215, 0))
            }
        elseif rankTier == "Elite" then
            gradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(138, 43, 226)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 20, 147))
            }
        elseif rankTier == "Expert" then
            gradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 165, 0)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 215, 0))
            }
        else
            gradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, rankInfo.color),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(math.min(255, rankInfo.color.R * 255 + 50), 
                                                            math.min(255, rankInfo.color.G * 255 + 50),
                                                            math.min(255, rankInfo.color.B * 255 + 50)))
            }
        end
        gradient.Parent = background
    else
        background.BackgroundColor3 = rankInfo.color
    end
    
    -- Stroke for better visibility
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 2
    stroke.Transparency = 0.2
    stroke.Parent = background
    
    -- Rank text
    local rankLabel = Instance.new("TextLabel")
    rankLabel.Name = "RankLabel"
    rankLabel.Size = UDim2.new(1, -10, 1, -6)
    rankLabel.Position = UDim2.new(0, 5, 0, 3)
    rankLabel.BackgroundTransparency = 1
    rankLabel.Text = rankInfo.name
    rankLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    rankLabel.TextScaled = true
    rankLabel.Font = Enum.Font.SourceSansBold
    rankLabel.TextStrokeTransparency = 0
    rankLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    rankLabel.Parent = background
    
    -- Text size constraint
    local textSizeConstraint = Instance.new("UITextSizeConstraint")
    textSizeConstraint.MaxTextSize = 16
    textSizeConstraint.MinTextSize = 8
    textSizeConstraint.Parent = rankLabel
    
    log.debug("Created rank display for", player.Name, "- Rank:", rankInfo.name, "Rebirths:", rebirths)
    
    -- Add special effects for higher tiers
    local effectTween = nil
    if rankTier == "Ultimate" then
        -- Rainbow effect for ultimate ranks
        effectTween = TweenService:Create(gradient, 
            TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {Rotation = 360}
        )
        effectTween:Play()
    elseif rankTier == "Elite" then
        -- Pulsing effect for elite ranks
        effectTween = TweenService:Create(stroke,
            TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {Transparency = 0.8}
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
            display.tween:Cancel()
            display.tween:Destroy()
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
    
    -- Wait a moment for character to fully load
    wait(1)
    
    -- Create rank display
    RankDisplayManager.updatePlayerRank(player)
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