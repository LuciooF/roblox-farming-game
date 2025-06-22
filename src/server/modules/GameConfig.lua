-- Game Configuration Module
-- Contains all game constants, plant configs, and economic settings

local GameConfig = {}

-- Plant configurations with strategic depth
GameConfig.Plants = {
    -- Quick crops (for active play)
    wheat = { 
        growthTime = 10, -- 10 seconds for testing (30 min real-time)
        waterNeeded = 1, 
        basePrice = 3, 
        seedCost = 1,
        description = "Fast growing, low profit",
        category = "Quick",
        deathTime = 30 -- Dies in 30 seconds if not watered
    },
    tomato = { 
        growthTime = 30, -- 30 seconds for testing (2 hours real-time)
        waterNeeded = 2, 
        basePrice = 12, 
        seedCost = 3,
        description = "Medium growth, good profit",
        category = "Medium",
        deathTime = 60 -- Dies in 1 minute if not watered
    },
    
    -- Medium crops (balanced)
    carrot = { 
        growthTime = 60, -- 1 minute for testing (4 hours real-time)
        waterNeeded = 2, 
        basePrice = 25, 
        seedCost = 8,
        description = "Steady growth, solid profit",
        category = "Medium",
        deathTime = 120 -- Dies in 2 minutes if not watered
    },
    
    -- Long-term crops (overnight/AFK)
    potato = { 
        growthTime = 180, -- 3 minutes for testing (12 hours real-time)
        waterNeeded = 3, 
        basePrice = 100, 
        seedCost = 25,
        description = "Slow growth, high profit",
        category = "Long-term",
        deathTime = 300 -- Dies in 5 minutes if not watered
    },
    corn = {
        growthTime = 300, -- 5 minutes for testing (24 hours real-time)
        waterNeeded = 4,
        basePrice = 250,
        seedCost = 80,
        description = "Very slow, premium profit",
        category = "Premium",
        deathTime = 600 -- Dies in 10 minutes if not watered
    }
}

-- Rebirth system configuration
GameConfig.Rebirth = {
    -- Exponentially growing money requirements for rebirths
    getMoneyRequirement = function(rebirth)
        return math.floor(1000 * (2.5 ^ rebirth)) -- 1K, 2.5K, 6.25K, 15.6K, 39K, 97.5K, etc.
    end,
    
    -- Crop value multiplier based on rebirths
    getCropMultiplier = function(rebirth)
        return 1 + (rebirth * 0.5) -- 1x, 1.5x, 2x, 2.5x, 3x, etc.
    end
}

-- Gamepass configurations
GameConfig.Gamepasses = {
    autoPlant = {name = "Auto Plant", description = "Automatically plant seeds on empty plots"},
    autoWater = {name = "Auto Water", description = "Automatically water growing plants"},
    autoHarvest = {name = "Auto Harvest", description = "Automatically harvest ready crops"},
    autoSell = {name = "Auto Sell", description = "Automatically sell harvested crops"}
}

-- System settings
GameConfig.Settings = {
    waterCooldown = 30, -- 30 seconds between waterings for multi-water plants
    startingMoney = 100,
    startingSeeds = {
        wheat = 3,
        tomato = 2,
        carrot = 1,
        potato = 0,
        corn = 0
    }
}

-- World building settings
GameConfig.World = {
    plotSize = Vector3.new(8, 1, 8),
    plotSpacing = 2,
    farmGridSize = 4, -- 4x4 grid of plots
    farmOffsetZ = 20, -- Move farm away from spawn
    spawnPosition = Vector3.new(0, 2, -40),
    merchantPosition = Vector3.new(40, 1, 0),
    autoPosition = Vector3.new(-45, 1, 0)
}

return GameConfig