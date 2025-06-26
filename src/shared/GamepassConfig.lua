-- Gamepass Configuration
-- Central configuration for all gamepasses and developer products

local GamepassConfig = {}

-- Gamepass definitions with all their properties
GamepassConfig.GAMEPASSES = {
    moneyMultiplier = {
        id = 1277613878,
        name = "2x Money Boost",
        description = "Double the money you earn from all crop sales!",
        icon = "rbxassetid://1277613878", -- Uses the gamepass ID as asset ID
        price = "R$ 99", -- Display price (actual price set in Roblox)
        benefits = {
            "💰 2x money from selling crops",
            "🌟 Permanent boost",
            "✨ Works on all future sales"
        },
        multiplier = 2.0,
        category = "economy"
    }
    
    -- Future gamepasses can be added here:
    -- autoHarvest = {
    --     id = 123456789,
    --     name = "Auto Harvest",
    --     description = "Automatically harvest ready crops",
    --     icon = "rbxassetid://123456789",
    --     price = "R$ 149",
    --     benefits = {
    --         "🤖 Automatic harvesting",
    --         "⚡ Never miss a harvest",
    --         "🎯 Works on all plots"
    --     },
    --     category = "automation"
    -- }
}

-- Get all gamepasses
function GamepassConfig.getAllGamepasses()
    return GamepassConfig.GAMEPASSES
end

-- Get gamepass by ID
function GamepassConfig.getGamepassById(gamepassId)
    for key, gamepass in pairs(GamepassConfig.GAMEPASSES) do
        if gamepass.id == gamepassId then
            return key, gamepass
        end
    end
    return nil, nil
end

-- Get gamepass by key
function GamepassConfig.getGamepass(key)
    return GamepassConfig.GAMEPASSES[key]
end

-- Get all gamepasses in a category
function GamepassConfig.getGamepassesByCategory(category)
    local filtered = {}
    for key, gamepass in pairs(GamepassConfig.GAMEPASSES) do
        if gamepass.category == category then
            filtered[key] = gamepass
        end
    end
    return filtered
end

-- Check if a gamepass ID is valid
function GamepassConfig.isValidGamepassId(gamepassId)
    local _, gamepass = GamepassConfig.getGamepassById(gamepassId)
    return gamepass ~= nil
end

return GamepassConfig