-- Game Configuration Module
-- Contains all game constants, plant configs, and economic settings

local GameConfig = {}

-- Import unified crop system - REQUIRED for the refactored system
local CropRegistry = require(game:GetService("ReplicatedStorage").Shared.CropRegistry)

-- Use new CropRegistry system
GameConfig.SeedRarities = CropRegistry.getAllRarities()
GameConfig.CropColors = {}
GameConfig.CropVariations = CropRegistry.getAllVariations()

-- Build legacy color table from CropRegistry
for cropId, crop in pairs(CropRegistry.getAllCrops()) do
    GameConfig.CropColors[cropId] = crop.color
end

-- Legacy Plants compatibility (DEPRECATED - use CropRegistry instead)
GameConfig.Plants = {}
for cropId, crop in pairs(CropRegistry.getAllCrops()) do
    GameConfig.Plants[cropId] = {
        growthTime = crop.growthTime,
        waterNeeded = crop.waterNeeded,
        basePrice = crop.basePrice,
        seedCost = crop.seedCost,
        description = crop.description,
        harvestCooldown = crop.harvestCooldown,
    }
end

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
    startingCrops = {
        wheat = 1,
        tomato = 0,
        carrot = 0,
        potato = 0,
        corn = 0
    }
}

-- Replanting configuration - now uses CropRegistry maxHarvestCycles
GameConfig.Replanting = {
    requiresWateringAfterHarvest = true,
    wateringChanceAfterHarvest = 70,
    showHarvestCount = true,
    randomFactors = {
        earlyWearoutChance = 15,
        bonusHarvestChance = 10
    }
}

-- Get max harvest cycles from CropRegistry
function GameConfig.getMaxHarvestCycles(cropId)
    local crop = CropRegistry.getCrop(cropId)
    return crop and crop.maxHarvestCycles or 3
end

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