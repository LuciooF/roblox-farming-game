-- Unified Crop Registry
-- Single source of truth for ALL crop data: visuals, economics, growth, weather, etc.

local CropRegistry = {}

-- Get appropriate logger based on environment
local log
local RunService = game:GetService("RunService")
if RunService:IsServer() then
    local Logger = require(game:GetService("ServerScriptService").Server.modules.Logger)
    log = Logger.getModuleLogger("CropRegistry")
else
    local ClientLogger = require(game:GetService("StarterPlayer").StarterPlayerScripts.Client.ClientLogger)
    log = ClientLogger.getModuleLogger("CropRegistry")
end

-- Crop definitions with ALL properties in one place
local CROPS = {
    wheat = {
        -- Basic Info
        name = "Wheat",
        description = "Common fast-growing grain that feeds the world",
        rarity = "common",
        
        -- Economics
        seedCost = 10,
        basePrice = 5,
        
        -- Growth Configuration
        growthTime = 15, -- seconds
        waterNeeded = 1,
        harvestCooldown = 10,
        maxHarvestCycles = 5,
        
        -- Visual Assets
        emoji = "🌾",
        color = Color3.fromRGB(255, 255, 100), -- Light yellow
        meshId = nil, -- Uses basic cylinder
        
        -- Weather Effects
        weatherMultipliers = {
            Sunny = 1.0,
            Cloudy = 0.9,
            Rainy = 1.2,
            Thunderstorm = 0.7
        },
        
        -- Special Properties
        canGrowInSeason = {"Spring", "Summer", "Fall"},
        soilTypes = {"any"},
        unlockLevel = 1
    },
    
    carrot = {
        -- Basic Info
        name = "Carrot",
        description = "Common orange root vegetable packed with vitamins",
        rarity = "common",
        
        -- Economics
        seedCost = 25,
        basePrice = 15,
        
        -- Growth Configuration
        growthTime = 30, -- seconds
        waterNeeded = 2,
        harvestCooldown = 15,
        maxHarvestCycles = 3,
        
        -- Visual Assets
        emoji = "🥕",
        color = Color3.fromRGB(255, 140, 0), -- Orange
        meshId = 1374148, -- 3D carrot model
        
        -- Weather Effects
        weatherMultipliers = {
            Sunny = 1.1,
            Cloudy = 1.0,
            Rainy = 1.3,
            Thunderstorm = 0.8
        },
        
        -- Special Properties
        canGrowInSeason = {"Spring", "Summer", "Fall"},
        soilTypes = {"any"},
        unlockLevel = 1
    },
    
    tomato = {
        -- Basic Info
        name = "Tomato",
        description = "Uncommon juicy fruit that's technically a vegetable",
        rarity = "uncommon",
        
        -- Economics
        seedCost = 50,
        basePrice = 35,
        
        -- Growth Configuration
        growthTime = 45, -- seconds
        waterNeeded = 2,
        harvestCooldown = 20,
        maxHarvestCycles = 4,
        
        -- Visual Assets
        emoji = "🍅",
        color = Color3.fromRGB(255, 69, 0), -- Red-orange
        meshId = nil, -- Uses basic cylinder
        
        -- Weather Effects
        weatherMultipliers = {
            Sunny = 1.3,
            Cloudy = 0.8,
            Rainy = 1.0,
            Thunderstorm = 0.6
        },
        
        -- Special Properties
        canGrowInSeason = {"Summer"},
        soilTypes = {"rich", "any"},
        unlockLevel = 5
    },
    
    potato = {
        -- Basic Info
        name = "Potato",
        description = "Common hearty root vegetable, perfect for any meal",
        rarity = "common",
        
        -- Economics
        seedCost = 35,
        basePrice = 25,
        
        -- Growth Configuration
        growthTime = 60, -- seconds
        waterNeeded = 2,
        harvestCooldown = 20,
        maxHarvestCycles = 3,
        
        -- Visual Assets
        emoji = "🥔",
        color = Color3.fromRGB(139, 69, 19), -- Brown
        meshId = nil, -- Uses basic cylinder
        
        -- Weather Effects
        weatherMultipliers = {
            Sunny = 0.9,
            Cloudy = 1.2,
            Rainy = 1.1,
            Thunderstorm = 1.0
        },
        
        -- Special Properties
        canGrowInSeason = {"Spring", "Fall"},
        soilTypes = {"any"},
        unlockLevel = 3
    },
    
    corn = {
        -- Basic Info
        name = "Corn",
        description = "Uncommon golden grain that grows tall and proud",
        rarity = "uncommon",
        
        -- Economics
        seedCost = 120,
        basePrice = 80,
        
        -- Growth Configuration
        growthTime = 90, -- seconds
        waterNeeded = 3,
        harvestCooldown = 30,
        maxHarvestCycles = 2,
        
        -- Visual Assets
        emoji = "🌽",
        color = Color3.fromRGB(255, 215, 0), -- Golden yellow
        meshId = nil, -- Uses basic cylinder
        
        -- Weather Effects
        weatherMultipliers = {
            Sunny = 1.4,
            Cloudy = 0.7,
            Rainy = 1.1,
            Thunderstorm = 0.5
        },
        
        -- Special Properties
        canGrowInSeason = {"Summer"},
        soilTypes = {"rich"},
        unlockLevel = 10
    }
}

-- Rarity definitions with multipliers
local RARITIES = {
    common = {
        dropChance = 70,
        color = Color3.fromRGB(200, 200, 200),
        multiplier = 1.0,
        name = "Common"
    },
    uncommon = {
        dropChance = 20,
        color = Color3.fromRGB(100, 255, 100),
        multiplier = 1.5,
        name = "Uncommon"
    },
    rare = {
        dropChance = 7,
        color = Color3.fromRGB(100, 100, 255),
        multiplier = 3.0,
        name = "Rare"
    },
    epic = {
        dropChance = 2.5,
        color = Color3.fromRGB(255, 100, 255),
        multiplier = 5.0,
        name = "Epic"
    },
    legendary = {
        dropChance = 0.5,
        color = Color3.fromRGB(255, 215, 0),
        multiplier = 10.0,
        name = "Legendary"
    }
}

-- Basic variation definitions (simplified)
local VARIATIONS = {
    normal = {
        chance = 100,
        multiplier = 1.0,
        prefix = "",
        color = nil -- Uses default crop color
    },
    dead = {
        chance = 0,
        multiplier = 0,
        prefix = "Dead ",
        color = Color3.fromRGB(100, 50, 50) -- Dead plants are dark brown
    }
}

-- API Functions
function CropRegistry.getCrop(cropId)
    return CROPS[cropId]
end

function CropRegistry.getAllCrops()
    return CROPS
end

function CropRegistry.getCropsByRarity(rarity)
    local crops = {}
    for id, crop in pairs(CROPS) do
        if crop.rarity == rarity then
            crops[id] = crop
        end
    end
    return crops
end

function CropRegistry.getCropsByUnlockLevel(level)
    local crops = {}
    for id, crop in pairs(CROPS) do
        if crop.unlockLevel <= level then
            crops[id] = crop
        end
    end
    return crops
end

function CropRegistry.getRarity(rarityId)
    return RARITIES[rarityId]
end

function CropRegistry.getAllRarities()
    return RARITIES
end

function CropRegistry.getVariation(variationId)
    return VARIATIONS[variationId]
end

function CropRegistry.getAllVariations()
    return VARIATIONS
end

-- Calculate final price with rarity and variation multipliers
function CropRegistry.calculatePrice(cropId, rarity, variation)
    local crop = CROPS[cropId]
    if not crop then return 0 end
    
    local rarityData = RARITIES[rarity or "common"]
    local variationData = VARIATIONS[variation or "normal"]
    
    return math.floor(crop.basePrice * (rarityData.multiplier or 1) * (variationData.multiplier or 1))
end

-- Get weather multiplier for a crop
function CropRegistry.getWeatherMultiplier(cropId, weatherType)
    local crop = CROPS[cropId]
    if not crop or not crop.weatherMultipliers then return 1.0 end
    
    return crop.weatherMultipliers[weatherType] or 1.0
end

-- Check if crop can grow in current season
function CropRegistry.canGrowInSeason(cropId, season)
    local crop = CROPS[cropId]
    if not crop or not crop.canGrowInSeason then return true end
    
    for _, allowedSeason in ipairs(crop.canGrowInSeason) do
        if allowedSeason == season then
            return true
        end
    end
    return false
end

-- Get crop visual data (emoji, color, mesh)
function CropRegistry.getVisuals(cropId, variation)
    local crop = CROPS[cropId]
    if not crop then return nil end
    
    local variationData = VARIATIONS[variation or "normal"]
    if not variationData then
        -- Fallback to normal variation if invalid variation provided
        variationData = VARIATIONS["normal"]
    end
    
    local color = (variationData and variationData.color) or crop.color
    local prefix = (variationData and variationData.prefix) or ""
    
    return {
        emoji = crop.emoji,
        color = color,
        meshId = crop.meshId,
        name = prefix .. crop.name
    }
end

-- Validate crop data on module load
local function validateCrops()
    for id, crop in pairs(CROPS) do
        assert(crop.name, "Crop " .. id .. " missing name")
        assert(crop.seedCost, "Crop " .. id .. " missing seedCost")
        assert(crop.basePrice, "Crop " .. id .. " missing basePrice")
        assert(crop.growthTime, "Crop " .. id .. " missing growthTime")
        assert(RARITIES[crop.rarity], "Crop " .. id .. " has invalid rarity: " .. tostring(crop.rarity))
    end
end

-- Initialize
validateCrops()

return CropRegistry