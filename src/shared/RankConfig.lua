-- Rank Configuration
-- Farming-themed ranks based on rebirth count

local RankConfig = {}

-- Rank definitions with rebirth thresholds and styling
RankConfig.RANKS = {
    -- Beginner Ranks (0-4 rebirths)
    {threshold = 0, name = "🌱 Dirt Digger", shortName = "🌱 Digger", color = Color3.fromRGB(139, 90, 43)},
    {threshold = 1, name = "🌰 Seed Sower", shortName = "🌰 Sower", color = Color3.fromRGB(160, 100, 50)},
    {threshold = 2, name = "🌿 Plot Tender", shortName = "🌿 Tender", color = Color3.fromRGB(90, 140, 90)},
    {threshold = 3, name = "🌱 Garden Rookie", shortName = "🌱 Rookie", color = Color3.fromRGB(100, 150, 100)},
    {threshold = 4, name = "🍃 Farming Newbie", shortName = "🍃 Newbie", color = Color3.fromRGB(110, 160, 110)},
    
    -- Early Ranks (5-9 rebirths)
    {threshold = 5, name = "🌾 Crop Curious", shortName = "🌾 Curious", color = Color3.fromRGB(180, 140, 60)},
    {threshold = 6, name = "🥕 Harvest Helper", shortName = "🥕 Helper", color = Color3.fromRGB(200, 120, 40)},
    {threshold = 7, name = "🌽 Farming Enthusiast", shortName = "🌽 Enthusiast", color = Color3.fromRGB(220, 180, 60)},
    {threshold = 8, name = "🥔 Garden Grower", shortName = "🥔 Grower", color = Color3.fromRGB(160, 120, 80)},
    {threshold = 9, name = "🍅 Crop Collector", shortName = "🍅 Collector", color = Color3.fromRGB(220, 60, 60)},
    
    -- Mid Ranks (10-19 rebirths)
    {threshold = 10, name = "🌻 Plot Master", shortName = "🌻 Master", color = Color3.fromRGB(255, 200, 80)},
    {threshold = 12, name = "🚜 Farm Hand", shortName = "🚜 Hand", color = Color3.fromRGB(100, 150, 200)},
    {threshold = 14, name = "🧑‍🌾 Harvest Hero", shortName = "🧑‍🌾 Hero", color = Color3.fromRGB(120, 180, 120)},
    {threshold = 16, name = "🌾 Farming Fanatic", shortName = "🌾 Fanatic", color = Color3.fromRGB(255, 215, 0)},
    {threshold = 18, name = "🥬 Crop Commander", shortName = "🥬 Commander", color = Color3.fromRGB(50, 200, 50)},
    
    -- Advanced Ranks (20-34 rebirths)
    {threshold = 20, name = "🏆 Agricultural Ace", shortName = "🏆 Ace", color = Color3.fromRGB(255, 165, 0)},
    {threshold = 23, name = "👑 Garden Guru", shortName = "👑 Guru", color = Color3.fromRGB(255, 140, 0)},
    {threshold = 26, name = "🎖️ Harvest Master", shortName = "🎖️ Master", color = Color3.fromRGB(192, 192, 192)},
    {threshold = 29, name = "⭐ Farming Legend", shortName = "⭐ Legend", color = Color3.fromRGB(255, 255, 0)},
    {threshold = 32, name = "🏅 Agricultural Admiral", shortName = "🏅 Admiral", color = Color3.fromRGB(0, 191, 255)},
    
    -- Expert Ranks (35-49 rebirths)
    {threshold = 35, name = "💎 Crop Connoisseur", shortName = "💎 Connoisseur", color = Color3.fromRGB(185, 242, 255)},
    {threshold = 38, name = "🔮 Farm Overlord", shortName = "🔮 Overlord", color = Color3.fromRGB(138, 43, 226)},
    {threshold = 41, name = "🧙‍♂️ Agricultural Wizard", shortName = "🧙‍♂️ Wizard", color = Color3.fromRGB(147, 0, 211)},
    {threshold = 44, name = "👤 Crop Whisperer", shortName = "👤 Whisperer", color = Color3.fromRGB(75, 0, 130)},
    {threshold = 47, name = "💰 Farm Tycoon", shortName = "💰 Tycoon", color = Color3.fromRGB(255, 215, 0)},
    
    -- Elite Ranks (50-74 rebirths)
    {threshold = 50, name = "🌟 Farming Deity", shortName = "🌟 Deity", color = Color3.fromRGB(255, 20, 147)},
    {threshold = 55, name = "👑 Harvest Emperor", shortName = "👑 Emperor", color = Color3.fromRGB(220, 20, 60)},
    {threshold = 60, name = "🛡️ Agricultural Overlord", shortName = "🛡️ Overlord", color = Color3.fromRGB(255, 0, 0)},
    {threshold = 65, name = "⚡ Crop Immortal", shortName = "⚡ Immortal", color = Color3.fromRGB(255, 69, 0)},
    {threshold = 70, name = "🌌 Farm Universe", shortName = "🌌 Universe", color = Color3.fromRGB(186, 85, 211)},
    
    -- Legendary Ranks (75+ rebirths)
    {threshold = 75, name = "🌍 Earthbound Farmer", shortName = "🌍 Earthbound", color = Color3.fromRGB(0, 255, 127)},
    {threshold = 80, name = "🌙 Celestial Cultivator", shortName = "🌙 Celestial", color = Color3.fromRGB(173, 216, 230)},
    {threshold = 85, name = "☀️ Solar Harvester", shortName = "☀️ Solar", color = Color3.fromRGB(255, 140, 0)},
    {threshold = 90, name = "🌌 Galactic Grower", shortName = "🌌 Galactic", color = Color3.fromRGB(72, 61, 139)},
    {threshold = 95, name = "🌟 Cosmic Farmer", shortName = "🌟 Cosmic", color = Color3.fromRGB(138, 43, 226)},
    {threshold = 100, name = "🚀 Infinite Cultivator", shortName = "🚀 Infinite", color = Color3.fromRGB(255, 255, 255)},
    
    -- Ultimate Ranks (100+ rebirths)
    {threshold = 150, name = "🎆 Omnipotent Farmer", shortName = "🎆 Omnipotent", color = Color3.fromRGB(255, 215, 0)},
    {threshold = 200, name = "💫 Transcendent Grower", shortName = "💫 Transcendent", color = Color3.fromRGB(255, 20, 147)},
    {threshold = 300, name = "🌈 Mythical Cultivator", shortName = "🌈 Mythical", color = Color3.fromRGB(255, 0, 255)},
    {threshold = 500, name = "🔥 Legendary Overlord", shortName = "🔥 Legendary", color = Color3.fromRGB(255, 69, 0)},
    {threshold = 1000, name = "👹 Farming Demon King", shortName = "👹 Demon King", color = Color3.fromRGB(139, 0, 0)},
}

-- Get rank for a given rebirth count
function RankConfig.getRankForRebirths(rebirths)
    local currentRank = RankConfig.RANKS[1] -- Default to first rank
    
    -- Find the highest rank threshold that the player meets
    for _, rank in ipairs(RankConfig.RANKS) do
        if rebirths >= rank.threshold then
            currentRank = rank
        else
            break -- Since ranks are sorted by threshold, we can stop here
        end
    end
    
    return currentRank
end

-- Get short name for chat display
function RankConfig.getShortRankName(rebirths)
    local rank = RankConfig.getRankForRebirths(rebirths)
    return rank.shortName or rank.name
end

-- Get formatted chat prefix for a player
function RankConfig.getChatPrefix(rebirths)
    local shortName = RankConfig.getShortRankName(rebirths)
    return "[" .. shortName .. "]"
end

-- Get next rank information
function RankConfig.getNextRank(rebirths)
    local currentRankIndex = 1
    
    -- Find current rank index
    for i, rank in ipairs(RankConfig.RANKS) do
        if rebirths >= rank.threshold then
            currentRankIndex = i
        else
            break
        end
    end
    
    -- Return next rank if it exists
    if currentRankIndex < #RankConfig.RANKS then
        local nextRank = RankConfig.RANKS[currentRankIndex + 1]
        local rebirthsNeeded = nextRank.threshold - rebirths
        return nextRank, rebirthsNeeded
    end
    
    return nil, 0 -- Player is at max rank
end

-- Get rank progress (percentage to next rank)
function RankConfig.getRankProgress(rebirths)
    local currentRank = RankConfig.getRankForRebirths(rebirths)
    local nextRank, rebirthsNeeded = RankConfig.getNextRank(rebirths)
    
    if not nextRank then
        return 100 -- Max rank = 100% progress
    end
    
    local rebirthsInCurrentRank = rebirths - currentRank.threshold
    local rebirthsForNextRank = nextRank.threshold - currentRank.threshold
    
    return math.floor((rebirthsInCurrentRank / rebirthsForNextRank) * 100)
end

-- Get all ranks (for UI display)
function RankConfig.getAllRanks()
    return RankConfig.RANKS
end

-- Get rank tier (for special effects)
function RankConfig.getRankTier(rebirths)
    if rebirths >= 100 then
        return "Ultimate"
    elseif rebirths >= 50 then
        return "Elite"
    elseif rebirths >= 20 then
        return "Expert"
    elseif rebirths >= 10 then
        return "Advanced"
    elseif rebirths >= 5 then
        return "Intermediate"
    else
        return "Beginner"
    end
end

return RankConfig