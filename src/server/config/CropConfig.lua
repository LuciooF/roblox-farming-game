-- Crop Configuration
-- All crop data, stats, and behavior in one place
-- To add a new crop: Just add it to this file and it will appear everywhere!

local CropConfig = {}

-- Production rate configuration
CropConfig.ProductionRates = {
    -- Crops per hour (base rate when online)
    perHour = {
        wheat = 12,      -- 12 wheat per hour = 1 every 5 minutes
        carrot = 8,      -- 8 carrots per hour = 1 every 7.5 minutes  
        tomato = 6,      -- 6 tomatoes per hour = 1 every 10 minutes
        potato = 10,     -- 10 potatoes per hour = 1 every 6 minutes
        corn = 4,        -- 4 corn per hour = 1 every 15 minutes
        banana = 2,      -- 2 bananas per hour = 1 every 30 minutes
        strawberry = 3   -- 3 strawberries per hour = 1 every 20 minutes
    },
    
    -- Storage capacity per crop type
    storageCapacity = {
        wheat = 100,
        carrot = 80,
        tomato = 60,
        potato = 90,
        corn = 50,
        banana = 30,
        strawberry = 40
    }
}

-- Complete crop database
CropConfig.Crops = {
    wheat = {
        -- Basic Info
        name = "Wheat",
        emoji = "🌾",
        description = "Fast-growing grain, perfect for beginners",
        rarity = "common",
        
        -- Growth & Production 
        baseProductionPerHour = CropConfig.ProductionRates.perHour.wheat,
        storageCapacity = CropConfig.ProductionRates.storageCapacity.wheat,
        waterNeeded = 1,                -- Waters needed to start growing
        waterCooldown = 10,             -- Seconds between watering
        maxHarvests = 5,                -- Times you can harvest before replanting
        
        -- Economy
        seedCost = 10,                  -- Cost to buy seed
        basePrice = 5,                  -- Base sell price per crop
        
        -- Weather Preferences
        weatherBoosts = {
            sunny = 1.5,                -- 50% faster in sunny weather
            rainy = 1.0,                -- Normal in rain
            cloudy = 1.0,               -- Normal in cloudy
            thunderstorm = 0.7          -- 30% slower in storms
        },
        
        -- Visual
        plantedEmoji = "🌱",           -- When first planted
        growingEmoji = "🌿",           -- When growing
        readyEmoji = "🌾",             -- When ready to harvest
        
        -- Unlock Requirements
        unlockLevel = 0,                -- Player level required
        unlockCost = 0,                 -- Money to unlock crop
        unlocked = true                 -- Available from start
    },
    
    carrot = {
        name = "Carrot",
        emoji = "🥕", 
        description = "Root vegetable that loves rainy weather",
        rarity = "common",
        
        baseProductionPerHour = CropConfig.ProductionRates.perHour.carrot,
        storageCapacity = CropConfig.ProductionRates.storageCapacity.carrot,
        waterNeeded = 2,
        waterCooldown = 15,
        maxHarvests = 4,
        
        seedCost = 25,
        basePrice = 15,
        
        weatherBoosts = {
            sunny = 0.9,                -- Slightly slower in sun
            rainy = 1.4,                -- 40% faster in rain (root vegetable)
            cloudy = 1.1,               -- Slightly faster in cloudy
            thunderstorm = 0.8
        },
        
        plantedEmoji = "🌱",
        growingEmoji = "🥬",
        readyEmoji = "🥕",
        
        unlockLevel = 0,
        unlockCost = 0,
        unlocked = true
    },
    
    tomato = {
        name = "Tomato",
        emoji = "🍅",
        description = "Juicy fruit that needs lots of sun",
        rarity = "uncommon",
        
        baseProductionPerHour = CropConfig.ProductionRates.perHour.tomato,
        storageCapacity = CropConfig.ProductionRates.storageCapacity.tomato,
        waterNeeded = 2,
        waterCooldown = 20,
        maxHarvests = 6,
        
        seedCost = 50,
        basePrice = 35,
        
        weatherBoosts = {
            sunny = 1.6,                -- Loves sunshine
            rainy = 0.8,                -- Doesn't like too much water
            cloudy = 0.9,
            thunderstorm = 0.6
        },
        
        plantedEmoji = "🌱",
        growingEmoji = "🌿",
        readyEmoji = "🍅",
        
        unlockLevel = 2,
        unlockCost = 100,
        unlocked = false
    },
    
    potato = {
        name = "Potato",
        emoji = "🥔",
        description = "Hearty root vegetable, reliable in any weather",
        rarity = "common",
        
        baseProductionPerHour = CropConfig.ProductionRates.perHour.potato,
        storageCapacity = CropConfig.ProductionRates.storageCapacity.potato,
        waterNeeded = 2,
        waterCooldown = 12,
        maxHarvests = 4,
        
        seedCost = 35,
        basePrice = 25,
        
        weatherBoosts = {
            sunny = 1.1,
            rainy = 1.2,                -- Likes moisture
            cloudy = 1.1,               -- Consistent performer
            thunderstorm = 1.0          -- Hardy against storms
        },
        
        plantedEmoji = "🌱",
        growingEmoji = "🌿",
        readyEmoji = "🥔",
        
        unlockLevel = 1,
        unlockCost = 50,
        unlocked = false
    },
    
    corn = {
        name = "Corn",
        emoji = "🌽",
        description = "Golden grain that takes time but gives great rewards",
        rarity = "uncommon",
        
        baseProductionPerHour = CropConfig.ProductionRates.perHour.corn,
        storageCapacity = CropConfig.ProductionRates.storageCapacity.corn,
        waterNeeded = 3,
        waterCooldown = 30,
        maxHarvests = 8,
        
        seedCost = 120,
        basePrice = 80,
        
        weatherBoosts = {
            sunny = 1.4,                -- Loves heat
            rainy = 1.1,
            cloudy = 1.0,
            thunderstorm = 0.7
        },
        
        plantedEmoji = "🌱",
        growingEmoji = "🌾",
        readyEmoji = "🌽",
        
        unlockLevel = 3,
        unlockCost = 250,
        unlocked = false
    },
    
    banana = {
        name = "Banana",
        emoji = "🍌",
        description = "Exotic tropical fruit, slow but very valuable",
        rarity = "rare",
        
        baseProductionPerHour = CropConfig.ProductionRates.perHour.banana,
        storageCapacity = CropConfig.ProductionRates.storageCapacity.banana,
        waterNeeded = 3,
        waterCooldown = 45,
        maxHarvests = 10,
        
        seedCost = 300,
        basePrice = 200,
        
        weatherBoosts = {
            sunny = 1.3,                -- Tropical = loves sun
            rainy = 1.2,                -- Needs moisture too
            cloudy = 0.8,
            thunderstorm = 0.5          -- Storms damage tropical crops
        },
        
        plantedEmoji = "🌱",
        growingEmoji = "🌴",
        readyEmoji = "🍌",
        
        unlockLevel = 5,
        unlockCost = 500,
        unlocked = false
    },
    
    strawberry = {
        name = "Strawberry", 
        emoji = "🍓",
        description = "Sweet berry that's sensitive to weather",
        rarity = "uncommon",
        
        baseProductionPerHour = CropConfig.ProductionRates.perHour.strawberry,
        storageCapacity = CropConfig.ProductionRates.storageCapacity.strawberry,
        waterNeeded = 2,
        waterCooldown = 25,
        maxHarvests = 7,
        
        seedCost = 180,
        basePrice = 120,
        
        weatherBoosts = {
            sunny = 1.2,
            rainy = 0.9,                -- Too much rain hurts berries
            cloudy = 1.3,               -- Perfect berry weather
            thunderstorm = 0.4          -- Very sensitive to storms
        },
        
        plantedEmoji = "🌱",
        growingEmoji = "🌿",
        readyEmoji = "🍓",
        
        unlockLevel = 4,
        unlockCost = 350,
        unlocked = false
    }
}

-- Rarity Configuration
CropConfig.Rarities = {
    common = {
        color = Color3.fromRGB(200, 200, 200),
        dropChance = 70,
        priceMultiplier = 1.0
    },
    uncommon = {
        color = Color3.fromRGB(100, 255, 100),
        dropChance = 20,
        priceMultiplier = 1.5
    },
    rare = {
        color = Color3.fromRGB(100, 100, 255),
        dropChance = 7,
        priceMultiplier = 3.0
    },
    epic = {
        color = Color3.fromRGB(255, 100, 255),
        dropChance = 2.5,
        priceMultiplier = 5.0
    },
    legendary = {
        color = Color3.fromRGB(255, 215, 0),
        dropChance = 0.5,
        priceMultiplier = 10.0
    }
}

-- Helper Functions
function CropConfig.getAllCrops()
    return CropConfig.Crops
end

function CropConfig.getCrop(cropName)
    return CropConfig.Crops[cropName]
end

function CropConfig.getUnlockedCrops()
    local unlockedCrops = {}
    for cropName, cropData in pairs(CropConfig.Crops) do
        if cropData.unlocked then
            unlockedCrops[cropName] = cropData
        end
    end
    return unlockedCrops
end

function CropConfig.getCropsForLevel(playerLevel)
    local availableCrops = {}
    for cropName, cropData in pairs(CropConfig.Crops) do
        if playerLevel >= cropData.unlockLevel then
            availableCrops[cropName] = cropData
        end
    end
    return availableCrops
end

function CropConfig.unlockCrop(cropName)
    if CropConfig.Crops[cropName] then
        CropConfig.Crops[cropName].unlocked = true
        return true
    end
    return false
end

-- Calculate growth time from production rate
function CropConfig.getGrowthTimeFromRate(cropName)
    local crop = CropConfig.getCrop(cropName)
    if not crop then return 60 end -- Default 1 minute
    
    -- Convert production per hour to seconds per production
    local secondsPerHour = 3600
    local growthTimeSeconds = secondsPerHour / crop.baseProductionPerHour
    
    return growthTimeSeconds
end

-- Get production rate for display
function CropConfig.getProductionRate(cropName)
    local crop = CropConfig.getCrop(cropName)
    if not crop then return 0 end
    
    return crop.baseProductionPerHour
end

return CropConfig