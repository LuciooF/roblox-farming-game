-- Gamepass Configuration
-- Central configuration for all gamepasses and developer products

local GamepassConfig = {}

-- Gamepass definitions with all their properties
GamepassConfig.GAMEPASSES = {
    moneyMultiplier = {
        id = 1285355447,
        name = "2x Money Boost",
        description = "Double the money you earn from all crop sales!",
        icon = "rbxassetid://1285355447", -- Uses the gamepass ID as asset ID
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
        id = 1286467321,
        name = "Fly Mode",
        description = "Soar above your farm with unlimited flight!",
        icon = "rbxassetid://1286467321", -- Uses the gamepass ID as asset ID
        price = "R$ 149", -- Display price (actual price set in Roblox)
        benefits = {
            "✈️ Unlimited flight ability",
            "🚀 Fast farm navigation",
            "🎮 Toggle with F key",
            "🌟 Permanent access"
        },
        category = "movement"
    },
    
    productionBoost = {
        id = 1283605505,
        name = "2x Production",
        description = "Double the speed of all crop production!",
        icon = "rbxassetid://1283605505", -- Uses the gamepass ID as asset ID
        price = "R$ 199", -- Display price (actual price set in Roblox)
        benefits = {
            "⚡ 2x faster crop production",
            "🌱 All plants grow twice as fast",
            "🚀 More crops per hour",
            "🌟 Permanent boost"
        },
        multiplier = 2.0,
        category = "production"
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