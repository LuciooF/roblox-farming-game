-- Gameplay Configuration
-- Core game mechanics, balancing, and progression

local GameplayConfig = {}

-- Player progression and levels
GameplayConfig.Progression = {
    -- Experience and levels
    baseExperience = 100,               -- XP needed for level 2
    experienceMultiplier = 1.5,         -- Each level needs 50% more XP
    maxLevel = 50,                      -- Maximum player level
    
    -- XP rewards
    experienceRewards = {
        plantSeed = 5,                  -- XP for planting
        waterPlant = 3,                 -- XP for watering
        harvestCrop = 10,               -- XP for harvesting
        sellCrops = 2,                  -- XP per crop sold
        completeTutorial = 100,         -- Bonus XP for tutorial
        discoverVariation = 50          -- XP for getting special crop
    },
    
    -- Level rewards
    levelRewards = {
        money = 100,                    -- Money per level
        seeds = {                       -- Free seeds per level
            wheat = 5,
            carrot = 3
        }
    }
}

-- Online vs Offline mechanics
GameplayConfig.OnlineBonus = {
    growthMultiplier = 2.0,             -- 2x growth when online
    experienceMultiplier = 1.5,         -- 50% more XP when online
    showBoostIndicator = true,          -- Show ⚡ symbol
    offlineCapHours = 24                -- Max 24 hours of offline progress
}

-- Storage and inventory
GameplayConfig.Storage = {
    -- Default storage capacities (can be upgraded)
    defaultCapacities = {
        seeds = 200,                    -- Total seed storage
        crops = 500,                    -- Total crop storage
        money = 999999999               -- Essentially unlimited money
    },
    
    -- Storage upgrades
    upgrades = {
        seedStorage = {
            levels = {100, 150, 200, 300, 500},  -- Storage amounts per level
            costs = {500, 1000, 2000, 5000, 10000}  -- Upgrade costs
        },
        cropStorage = {
            levels = {250, 400, 600, 1000, 1500},
            costs = {1000, 2000, 4000, 8000, 15000}
        }
    },
    
    -- Warning thresholds
    warnings = {
        nearFull = 0.8,                 -- Warn when 80% full
        almostFull = 0.95               -- Urgent warning at 95%
    }
}

-- Farm and plot configuration
GameplayConfig.Farm = {
    -- Plot system
    basePlotsPerFarm = 9,               -- Starting plots (3x3 grid)
    maxPlotsPerFarm = 25,               -- Maximum plots (5x5 grid)
    
    -- Plot expansion costs
    plotExpansionCosts = {
        [10] = 5000,                    -- 10th plot costs 5000
        [11] = 7500,
        [12] = 10000,
        [13] = 12500,
        [14] = 15000,
        [15] = 20000,
        [16] = 25000,
        [17] = 30000,
        [18] = 35000,
        [19] = 40000,
        [20] = 50000,
        [21] = 60000,
        [22] = 70000,
        [23] = 80000,
        [24] = 90000,
        [25] = 100000
    },
    
    -- Farm settings
    totalFarms = 6,                     -- Maximum concurrent farms
    farmSize = Vector3.new(100, 1, 100),
    farmSpacing = 120
}

-- Economy and pricing
GameplayConfig.Economy = {
    -- Starting resources
    startingMoney = 100,
    startingSeeds = {
        wheat = 10,
        carrot = 5
    },
    
    -- Price fluctuation (future feature)
    priceFluctuation = {
        enabled = false,                -- Dynamic pricing
        maxChange = 0.2,                -- ±20% price changes
        updateFrequency = 3600          -- Update every hour
    },
    
    -- Rebirth system
    rebirth = {
        moneyRequirements = {           -- Money needed for each rebirth
            [0] = 10000,                -- First rebirth
            [1] = 50000,                -- Second rebirth
            [2] = 200000,               -- Third rebirth
            [3] = 1000000,              -- Fourth rebirth
            [4] = 5000000               -- Fifth rebirth (continue pattern)
        },
        
        multipliers = {                 -- Sell price multipliers per rebirth
            [0] = 1.0,                  -- No rebirth
            [1] = 1.5,                  -- 50% more money
            [2] = 2.0,                  -- 2x money
            [3] = 3.0,                  -- 3x money
            [4] = 4.5,                  -- 4.5x money
            [5] = 6.0                   -- 6x money
        }
    }
}

-- Crop variations and special effects
GameplayConfig.Variations = {
    -- Chance for special crop variations
    chances = {
        normal = 85,                    -- 85% normal crops
        shiny = 10,                     -- 10% shiny (1.5x value)
        rainbow = 3,                    -- 3% rainbow (2.5x value)
        golden = 1.5,                   -- 1.5% golden (5x value)
        diamond = 0.5                   -- 0.5% diamond (10x value)
    },
    
    -- Variation effects
    effects = {
        normal = { multiplier = 1.0, prefix = "", emoji = "" },
        shiny = { multiplier = 1.5, prefix = "Shiny ", emoji = "✨" },
        rainbow = { multiplier = 2.5, prefix = "Rainbow ", emoji = "🌈" },
        golden = { multiplier = 5.0, prefix = "Golden ", emoji = "💛" },
        diamond = { multiplier = 10.0, prefix = "Diamond ", emoji = "💎" }
    }
}

-- Tutorial and new player experience
GameplayConfig.Tutorial = {
    enabled = true,
    steps = {
        "plant_seed",                   -- Plant your first seed
        "water_plant",                  -- Water the plant
        "wait_growth",                  -- Wait for growth (shortened)
        "harvest_crop",                 -- Harvest the crop
        "sell_crops",                   -- Sell in inventory
        "buy_seeds",                    -- Buy more seeds from shop
        "expand_farm"                   -- Learn about expansion
    },
    
    rewards = {
        completionMoney = 500,
        completionSeeds = {
            wheat = 20,
            carrot = 10,
            tomato = 5
        }
    },
    
    skipOption = true,                  -- Allow players to skip
    skipReward = 250                    -- Reduced reward for skipping
}

-- Time and scheduling
GameplayConfig.Timing = {
    -- Tick rates and update frequencies
    plotUpdateInterval = 1,             -- Seconds between plot updates
    weatherUpdateInterval = 10,         -- Seconds between weather checks
    dataAutoSaveInterval = 60,          -- Seconds between auto-saves
    
    -- Cooldowns
    wateringCooldown = 10,              -- Seconds between watering same plot
    harvestCooldown = 5,                -- Seconds between harvests
    shopCooldown = 1,                   -- Seconds between purchases
    
    -- Death and decay system removed - plants no longer die
}

-- Helper Functions
function GameplayConfig.getExperienceRequired(level)
    if level <= 1 then return 0 end
    return math.floor(GameplayConfig.Progression.baseExperience * (GameplayConfig.Progression.experienceMultiplier ^ (level - 2)))
end

function GameplayConfig.getRebirthRequirement(rebirthLevel)
    local requirements = GameplayConfig.Economy.rebirth.moneyRequirements
    return requirements[rebirthLevel] or (requirements[4] * (2 ^ (rebirthLevel - 4)))
end

function GameplayConfig.getRebirthMultiplier(rebirthLevel)
    local multipliers = GameplayConfig.Economy.rebirth.multipliers
    return multipliers[rebirthLevel] or (multipliers[5] * (1.5 ^ (rebirthLevel - 5)))
end

function GameplayConfig.getPlotExpansionCost(plotNumber)
    return GameplayConfig.Farm.plotExpansionCosts[plotNumber] or 100000
end

function GameplayConfig.getTotalStorageCapacity(storageType, upgradeLevel)
    local upgrades = GameplayConfig.Storage.upgrades[storageType .. "Storage"]
    if upgrades and upgrades.levels[upgradeLevel] then
        return upgrades.levels[upgradeLevel]
    end
    return GameplayConfig.Storage.defaultCapacities[storageType] or 100
end

function GameplayConfig.rollCropVariation()
    local roll = math.random() * 100
    local cumulative = 0
    
    local variationOrder = {"normal", "shiny", "rainbow", "golden", "diamond"}
    
    for _, variation in ipairs(variationOrder) do
        cumulative = cumulative + GameplayConfig.Variations.chances[variation]
        if roll <= cumulative then
            return variation
        end
    end
    
    return "normal"  -- Fallback
end

return GameplayConfig