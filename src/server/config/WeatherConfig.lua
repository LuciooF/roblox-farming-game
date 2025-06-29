-- Weather Configuration
-- All weather types, effects, and patterns

local WeatherConfig = {}

-- Weather cycle settings
WeatherConfig.Settings = {
    cycleTimeMinutes = 5,               -- How long each weather lasts
    forecastHours = 3,                  -- How far ahead to show forecast
    autoWaterDuringRain = true,         -- Rain automatically waters crops
    stormDamageEnabled = true           -- Storms can damage unprotected crops
}

-- Weather Types and Effects
WeatherConfig.Types = {
    Sunny = {
        name = "Sunny",
        emoji = "☀️",
        description = "Bright sunshine boosts all crop growth by 50%",
        
        effects = {
            globalGrowthMultiplier = 1.5,   -- 50% faster growth
            waterEvaporationRate = 1.3,     -- Plants dry out 30% faster
            autoWater = false,
            damageChance = 0,
            lightLevel = 1.5                -- Brighter lighting
        },
        
        -- Crops that get special bonuses (defined in CropConfig)
        favoredCrops = {"wheat", "corn", "tomato"},
        
        -- Visual effects
        skyColor = Color3.fromRGB(135, 206, 235),   -- Sky blue
        ambientColor = Color3.fromRGB(255, 255, 200), -- Warm light
        fogEnd = 1000,                              -- Clear visibility
        
        -- Sound effects (when implemented)
        ambientSound = "birds_chirping",
        soundVolume = 0.3
    },
    
    Rainy = {
        name = "Rainy",
        emoji = "🌧️", 
        description = "No watering needed, but slower growth",
        
        effects = {
            globalGrowthMultiplier = 0.9,   -- Slightly slower overall
            waterEvaporationRate = 0,       -- No water loss during rain
            autoWater = true,               -- Automatically waters all crops
            damageChance = 0,
            lightLevel = 0.7                -- Darker during rain
        },
        
        favoredCrops = {"carrot", "potato"},
        
        skyColor = Color3.fromRGB(100, 100, 120),
        ambientColor = Color3.fromRGB(150, 150, 180),
        fogEnd = 300,                       -- Reduced visibility
        
        ambientSound = "rain_loop",
        soundVolume = 0.5
    },
    
    Cloudy = {
        name = "Cloudy",
        emoji = "☁️",
        description = "Neutral weather with no special effects",
        
        effects = {
            globalGrowthMultiplier = 1.0,   -- Normal growth rate
            waterEvaporationRate = 1.0,     -- Normal water loss
            autoWater = false,
            damageChance = 0,
            lightLevel = 0.9                -- Slightly dimmer
        },
        
        favoredCrops = {"strawberry"},      -- Berries like mild weather
        
        skyColor = Color3.fromRGB(150, 150, 150),
        ambientColor = Color3.fromRGB(200, 200, 200),
        fogEnd = 600,
        
        ambientSound = "wind_gentle",
        soundVolume = 0.2
    },
    
    Thunderstorm = {
        name = "Thunderstorm",
        emoji = "⛈️",
        description = "Dangerous storms can damage unprotected crops",
        
        effects = {
            globalGrowthMultiplier = 0.7,   -- Significantly slower due to stress
            waterEvaporationRate = 0,       -- No water loss
            autoWater = true,               -- Heavy rain waters crops
            damageChance = 0.15,            -- 15% chance to damage unprotected crops
            lightLevel = 0.5                -- Dark storm clouds
        },
        
        favoredCrops = {},                  -- No crops like storms
        
        skyColor = Color3.fromRGB(50, 50, 70),
        ambientColor = Color3.fromRGB(100, 100, 150),
        fogEnd = 200,                       -- Very poor visibility
        
        ambientSound = "thunder_rain",
        soundVolume = 0.8
    },
    
    -- Rare weather events (could be added later)
    Heatwave = {
        name = "Heatwave",
        emoji = "🔥",
        description = "Extreme heat damages most crops but boosts desert plants",
        
        effects = {
            globalGrowthMultiplier = 0.5,
            waterEvaporationRate = 2.0,     -- Plants dry out twice as fast
            autoWater = false,
            damageChance = 0.1,             -- Heat damage
            lightLevel = 2.0                -- Intense brightness
        },
        
        favoredCrops = {},                  -- Could add cactus/desert crops later
        
        skyColor = Color3.fromRGB(255, 200, 150),
        ambientColor = Color3.fromRGB(255, 220, 180),
        fogEnd = 800,
        
        ambientSound = "desert_wind",
        soundVolume = 0.4,
        
        -- Rare weather settings
        isRareWeather = true,
        rareChance = 5                      -- 5% chance to occur
    }
}

-- Weather patterns and cycles
WeatherConfig.Patterns = {
    -- Default pattern (always used)
    default = {"Sunny", "Cloudy", "Rainy", "Sunny", "Cloudy", "Thunderstorm", "Cloudy", "Sunny"},
    
    -- Seasonal patterns (could be implemented later)
    spring = {"Rainy", "Cloudy", "Sunny", "Rainy", "Cloudy", "Sunny", "Thunderstorm", "Rainy"},
    summer = {"Sunny", "Sunny", "Cloudy", "Sunny", "Thunderstorm", "Sunny", "Cloudy", "Sunny"},
    fall = {"Cloudy", "Rainy", "Cloudy", "Sunny", "Rainy", "Thunderstorm", "Cloudy", "Rainy"},
    winter = {"Cloudy", "Cloudy", "Rainy", "Cloudy", "Rainy", "Cloudy", "Thunderstorm", "Cloudy"}
}

-- Helper Functions
function WeatherConfig.getWeatherType(weatherName)
    return WeatherConfig.Types[weatherName]
end

function WeatherConfig.getAllWeatherTypes()
    return WeatherConfig.Types
end

function WeatherConfig.getWeatherPattern(patternName)
    return WeatherConfig.Patterns[patternName or "default"]
end

function WeatherConfig.getCycleTimeSeconds()
    return WeatherConfig.Settings.cycleTimeMinutes * 60
end

function WeatherConfig.isAutoWaterWeather(weatherName)
    local weather = WeatherConfig.getWeatherType(weatherName)
    return weather and weather.effects.autoWater or false
end

function WeatherConfig.getWeatherDamageChance(weatherName)
    local weather = WeatherConfig.getWeatherType(weatherName)
    return weather and weather.effects.damageChance or 0
end

function WeatherConfig.getGlobalGrowthMultiplier(weatherName)
    local weather = WeatherConfig.getWeatherType(weatherName)
    return weather and weather.effects.globalGrowthMultiplier or 1.0
end

-- Get weather boost for specific crop
function WeatherConfig.getCropWeatherBoost(cropName, weatherName)
    local weather = WeatherConfig.getWeatherType(weatherName)
    if not weather then return 1.0 end
    
    -- Check if this crop is favored by this weather
    if weather.favoredCrops then
        for _, favoredCrop in ipairs(weather.favoredCrops) do
            if favoredCrop == cropName then
                return 1.2  -- 20% bonus for favored crops
            end
        end
    end
    
    return 1.0  -- No special bonus
end

return WeatherConfig