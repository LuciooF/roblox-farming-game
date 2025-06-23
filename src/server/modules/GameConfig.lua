-- Game Configuration Module
-- Contains all game constants, plant configs, and economic settings

local GameConfig = {}

-- Seed Rarity System
GameConfig.SeedRarities = {
    -- Common (70% chance)
    common = {
        dropChance = 70,
        color = Color3.fromRGB(200, 200, 200),
        multiplier = 1.0,
        seeds = {
            wheat = { 
                growthTime = 15, waterNeeded = 1, basePrice = 5, seedCost = 10,
                description = "Common fast-growing grain", harvestCooldown = 10, deathTime = 120
            },
            carrot = { 
                growthTime = 30, waterNeeded = 2, basePrice = 15, seedCost = 25,
                description = "Common root vegetable", harvestCooldown = 15, deathTime = 180
            }
        }
    },
    
    -- Uncommon (20% chance)
    uncommon = {
        dropChance = 20,
        color = Color3.fromRGB(100, 255, 100),
        multiplier = 1.5,
        seeds = {
            tomato = { 
                growthTime = 45, waterNeeded = 2, basePrice = 35, seedCost = 50,
                description = "Uncommon juicy fruit", harvestCooldown = 20, deathTime = 240
            },
            corn = {
                growthTime = 90, waterNeeded = 3, basePrice = 80, seedCost = 120,
                description = "Uncommon golden grain", harvestCooldown = 30, deathTime = 360
            }
        }
    },
    
    -- Rare (7% chance)
    rare = {
        dropChance = 7,
        color = Color3.fromRGB(100, 100, 255),
        multiplier = 3.0,
        seeds = {
            banana = {
                growthTime = 120, waterNeeded = 3, basePrice = 200, seedCost = 300,
                description = "Rare tropical fruit", harvestCooldown = 45, deathTime = 480
            },
            strawberry = {
                growthTime = 75, waterNeeded = 2, basePrice = 150, seedCost = 200,
                description = "Rare sweet berry", harvestCooldown = 25, deathTime = 360
            }
        }
    },
    
    -- Epic (2.5% chance)
    epic = {
        dropChance = 2.5,
        color = Color3.fromRGB(255, 100, 255),
        multiplier = 5.0,
        seeds = {
            dragonfruit = {
                growthTime = 180, waterNeeded = 4, basePrice = 500, seedCost = 750,
                description = "Epic mystical fruit", harvestCooldown = 60, deathTime = 720
            },
            goldapple = {
                growthTime = 240, waterNeeded = 5, basePrice = 800, seedCost = 1200,
                description = "Epic golden apple", harvestCooldown = 90, deathTime = 900
            }
        }
    },
    
    -- Legendary (0.5% chance)
    legendary = {
        dropChance = 0.5,
        color = Color3.fromRGB(255, 215, 0),
        multiplier = 10.0,
        seeds = {
            starfruit = {
                growthTime = 300, waterNeeded = 6, basePrice = 2000, seedCost = 3000,
                description = "Legendary celestial fruit", harvestCooldown = 120, deathTime = 1200
            },
            crystalberry = {
                growthTime = 360, waterNeeded = 7, basePrice = 3500, seedCost = 5000,
                description = "Legendary crystal berry", harvestCooldown = 180, deathTime = 1440
            }
        }
    }
}

-- Crop Colors for seeds and plants
GameConfig.CropColors = {
    wheat = Color3.fromRGB(255, 255, 100), -- Light yellow
    carrot = Color3.fromRGB(255, 140, 0), -- Orange
    tomato = Color3.fromRGB(255, 69, 0), -- Red-orange
    corn = Color3.fromRGB(255, 215, 0), -- Golden yellow
    potato = Color3.fromRGB(139, 69, 19), -- Brown
    banana = Color3.fromRGB(255, 255, 0), -- Bright yellow
    strawberry = Color3.fromRGB(255, 20, 147), -- Deep pink
    dragonfruit = Color3.fromRGB(255, 20, 147), -- Magenta
    goldapple = Color3.fromRGB(255, 215, 0), -- Gold
    starfruit = Color3.fromRGB(255, 255, 224), -- Light yellow
    crystalberry = Color3.fromRGB(173, 216, 230) -- Light blue
}

-- Crop Variations (chance when planting)
GameConfig.CropVariations = {
    normal = {
        chance = 85,
        multiplier = 1.0,
        prefix = "",
        color = nil -- Uses default plant color
    },
    shiny = {
        chance = 10,
        multiplier = 2.0,
        prefix = "Shiny ",
        color = Color3.fromRGB(255, 255, 150) -- Light gold
    },
    rainbow = {
        chance = 4,
        multiplier = 5.0,
        prefix = "Rainbow ",
        color = Color3.fromRGB(255, 100, 255) -- Rainbow effect (will cycle)
    },
    golden = {
        chance = 0.9,
        multiplier = 10.0,
        prefix = "Golden ",
        color = Color3.fromRGB(255, 215, 0) -- Pure gold
    },
    diamond = {
        chance = 0.1,
        multiplier = 25.0,
        prefix = "Diamond ",
        color = Color3.fromRGB(185, 242, 255) -- Diamond sparkle
    }
}

-- Legacy Plants (for backward compatibility)
GameConfig.Plants = {
    wheat = GameConfig.SeedRarities.common.seeds.wheat,
    tomato = GameConfig.SeedRarities.uncommon.seeds.tomato,
    carrot = GameConfig.SeedRarities.common.seeds.carrot,
    corn = GameConfig.SeedRarities.uncommon.seeds.corn,
    banana = GameConfig.SeedRarities.rare.seeds.banana,
    -- Add missing potato seed
    potato = { 
        growthTime = 60, waterNeeded = 2, basePrice = 25, seedCost = 35,
        description = "Common hearty vegetable", harvestCooldown = 20, deathTime = 240
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

-- Replanting configuration (configurable and modular)
GameConfig.Replanting = {
    -- Whether plants require watering after each harvest
    requiresWateringAfterHarvest = true,
    
    -- Percentage chance a plant needs watering after each harvest (0-100)
    wateringChanceAfterHarvest = 70, -- 70% chance to need watering
    
    -- How many harvest cycles before plant automatically needs replanting
    maxHarvestCycles = {
        wheat = 5,   -- Wheat can be harvested 5 times before needing replanting
        carrot = 3,  -- Carrot can be harvested 3 times
        tomato = 4,  -- Tomato can be harvested 4 times
        potato = 3,  -- Potato can be harvested 3 times
        corn = 2,    -- Corn can be harvested 2 times (premium crop)
        banana = 1,  -- Rare fruits need replanting more often
        strawberry = 1,
        dragonfruit = 1,
        goldapple = 1,
        starfruit = 1,
        crystalberry = 1
    },
    
    -- Whether to show harvest count in UI
    showHarvestCount = true,
    
    -- Random factors for realism
    randomFactors = {
        -- Chance for plant to "wear out" early (0-100)
        earlyWearoutChance = 15, -- 15% chance to need replanting one cycle early
        
        -- Chance for plant to last longer (0-100) 
        bonusHarvestChance = 10  -- 10% chance to get one extra harvest cycle
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
    autoPosition = Vector3.new(-45, 1, 0),
    
    -- Sky drop system
    skyDropPosition = Vector3.new(-70, 100, 0), -- High above and away from farm plots
    seedDropInterval = 15, -- Drop a seed every 15 seconds
    seedLifetime = 30, -- Seeds disappear after 30 seconds if not picked up
    maxSeedsOnGround = 10 -- Maximum seeds that can be on ground at once
}

return GameConfig