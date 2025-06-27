-- Configuration Manager
-- Loads and manages all game configuration data
-- Central access point for all config files

local ConfigManager = {}

-- Load all configuration modules
local CropConfig = require(script.Parent.Parent.config.CropConfig)
local WeatherConfig = require(script.Parent.Parent.config.WeatherConfig)
local GameplayConfig = require(script.Parent.Parent.config.GameplayConfig)

local Logger = require(script.Parent.Logger)
local log = Logger.getModuleLogger("ConfigManager")

-- Initialize the config system
function ConfigManager.initialize()
    log.info("Loading game configuration...")
    
    -- Validate configurations
    local isValid = ConfigManager.validateConfigs()
    
    if isValid then
        log.info("All configurations loaded successfully!")
        ConfigManager.logConfigSummary()
    else
        log.error("Configuration validation failed!")
    end
    
    return isValid
end

-- Validate all configuration files
function ConfigManager.validateConfigs()
    local errors = {}
    
    -- Validate crop config
    local crops = CropConfig.getAllCrops()
    local cropCount = 0
    for cropName, cropData in pairs(crops) do
        cropCount = cropCount + 1
        
        -- Check required fields
        if not cropData.baseProductionPerHour then
            table.insert(errors, "Crop " .. cropName .. " missing baseProductionPerHour")
        end
        if not cropData.storageCapacity then
            table.insert(errors, "Crop " .. cropName .. " missing storageCapacity")
        end
        if not cropData.seedCost then
            table.insert(errors, "Crop " .. cropName .. " missing seedCost")
        end
        if not cropData.basePrice then
            table.insert(errors, "Crop " .. cropName .. " missing basePrice")
        end
    end
    
    -- Validate weather config
    local weatherTypes = WeatherConfig.getAllWeatherTypes()
    local weatherCount = 0
    for weatherName, weatherData in pairs(weatherTypes) do
        weatherCount = weatherCount + 1
        
        if not weatherData.effects then
            table.insert(errors, "Weather " .. weatherName .. " missing effects")
        end
    end
    
    -- Log validation results
    if #errors > 0 then
        log.error("Configuration validation errors:")
        for _, error in ipairs(errors) do
            log.error("-", error)
        end
        return false
    end
    
    log.info("Validation passed:", cropCount, "crops,", weatherCount, "weather types")
    return true
end

-- Log configuration summary
function ConfigManager.logConfigSummary()
    local crops = CropConfig.getAllCrops()
    local cropNames = {}
    for cropName, _ in pairs(crops) do
        table.insert(cropNames, cropName)
    end
    
    local weatherTypes = WeatherConfig.getAllWeatherTypes()
    local weatherNames = {}
    for weatherName, _ in pairs(weatherTypes) do
        table.insert(weatherNames, weatherName)
    end
    
    log.info("Config Summary:")
    log.info("- Crops:", table.concat(cropNames, ", "))
    log.info("- Weather:", table.concat(weatherNames, ", "))
    log.info("- Starting money:", GameplayConfig.Economy.startingMoney)
    log.info("- Online bonus:", GameplayConfig.OnlineBonus.growthMultiplier .. "x")
end

-- === CROP CONFIGURATION ACCESS ===
function ConfigManager.getAllCrops()
    return CropConfig.getAllCrops()
end

function ConfigManager.getCrop(cropName)
    return CropConfig.getCrop(cropName)
end

function ConfigManager.getUnlockedCrops()
    return CropConfig.getUnlockedCrops()
end

function ConfigManager.getCropsForLevel(playerLevel)
    return CropConfig.getCropsForLevel(playerLevel)
end

function ConfigManager.unlockCrop(cropName)
    return CropConfig.unlockCrop(cropName)
end

function ConfigManager.getGrowthTimeFromRate(cropName)
    return CropConfig.getGrowthTimeFromRate(cropName)
end

function ConfigManager.getProductionRate(cropName)
    return CropConfig.getProductionRate(cropName)
end

-- === WEATHER CONFIGURATION ACCESS ===
function ConfigManager.getWeatherType(weatherName)
    return WeatherConfig.getWeatherType(weatherName)
end

function ConfigManager.getAllWeatherTypes()
    return WeatherConfig.getAllWeatherTypes()
end

function ConfigManager.getWeatherPattern(patternName)
    return WeatherConfig.getWeatherPattern(patternName)
end

function ConfigManager.getCycleTimeSeconds()
    return WeatherConfig.getCycleTimeSeconds()
end

function ConfigManager.isAutoWaterWeather(weatherName)
    return WeatherConfig.isAutoWaterWeather(weatherName)
end

function ConfigManager.getWeatherDamageChance(weatherName)
    return WeatherConfig.getWeatherDamageChance(weatherName)
end

function ConfigManager.getGlobalWeatherMultiplier(weatherName)
    return WeatherConfig.getGlobalGrowthMultiplier(weatherName)
end

function ConfigManager.getCropWeatherBoost(cropName, weatherName)
    -- Get crop-specific weather boost from CropConfig
    local crop = CropConfig.getCrop(cropName)
    if crop and crop.weatherBoosts and crop.weatherBoosts[weatherName] then
        return crop.weatherBoosts[weatherName]
    end
    
    -- Fallback to general weather boost from WeatherConfig
    return WeatherConfig.getCropWeatherBoost(cropName, weatherName)
end

-- === GAMEPLAY CONFIGURATION ACCESS ===
function ConfigManager.getExperienceRequired(level)
    return GameplayConfig.getExperienceRequired(level)
end

function ConfigManager.getRebirthRequirement(rebirthLevel)
    return GameplayConfig.getRebirthRequirement(rebirthLevel)
end

function ConfigManager.getRebirthMultiplier(rebirthLevel)
    return GameplayConfig.getRebirthMultiplier(rebirthLevel)
end

function ConfigManager.getPlotExpansionCost(plotNumber)
    return GameplayConfig.getPlotExpansionCost(plotNumber)
end

function ConfigManager.getTotalStorageCapacity(storageType, upgradeLevel)
    return GameplayConfig.getTotalStorageCapacity(storageType, upgradeLevel)
end

function ConfigManager.rollCropVariation()
    return GameplayConfig.rollCropVariation()
end

function ConfigManager.getOnlineBonus()
    return GameplayConfig.OnlineBonus
end


function ConfigManager.getFarmConfig()
    return GameplayConfig.Farm
end


function ConfigManager.getTimingConfig()
    return GameplayConfig.Timing
end

-- === CONVENIENCE FUNCTIONS ===


-- Get weather data formatted for client
function ConfigManager.getWeatherDataForClient()
    local weather = {}
    for weatherName, weatherData in pairs(WeatherConfig.getAllWeatherTypes()) do
        weather[weatherName] = {
            name = weatherData.name,
            emoji = weatherData.emoji,
            description = weatherData.description,
            effects = {
                globalGrowthMultiplier = weatherData.effects.globalGrowthMultiplier,
                autoWater = weatherData.effects.autoWater,
                damageChance = weatherData.effects.damageChance
            }
        }
    end
    return weather
end


return ConfigManager