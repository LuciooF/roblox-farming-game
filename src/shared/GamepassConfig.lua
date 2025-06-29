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
    },
    
    flyMode = {
        id = 1276253029,
        name = "Fly Mode",
        description = "Soar above your farm with unlimited flight!",
        icon = "rbxassetid://1276253029", -- Uses the gamepass ID as asset ID
        price = "R$ 149", -- Display price (actual price set in Roblox)
        benefits = {
            "✈️ Unlimited flight ability",
            "🚀 Fast farm navigation",
            "🎮 Toggle with F key",
            "🌟 Permanent access"
        },
        category = "movement"
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


return GamepassConfig