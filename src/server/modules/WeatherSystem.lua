-- Weather System Module
-- Manages global weather states and their effects on crop growth

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Logger = require(script.Parent.Logger)
local NotificationManager = require(script.Parent.NotificationManager)
local ConfigManager = require(script.Parent.ConfigManager)

local log = Logger.getModuleLogger("WeatherSystem")

local WeatherSystem = {}

-- Configuration
local WEATHER_CYCLE_TIME = 300 -- 5 minutes per weather cycle
local FORECAST_HOURS = 3 -- Show forecast for next 3 weather periods

-- Weather Types and Effects
local WeatherTypes = {
    Sunny = {
        name = "Sunny",
        emoji = "☀️",
        description = "Bright sunshine boosts certain crops",
        effects = {
            growthMultiplier = 1.2, -- 20% faster growth for sunny-loving crops
            waterEvaporation = 1.3, -- Plants dry out 30% faster
            damageChance = 0
        },
        benefitSeeds = {"wheat", "corn", "tomato"}, -- These grow faster in sun
        color = Color3.fromRGB(255, 255, 100)
    },
    
    Rainy = {
        name = "Rainy",
        emoji = "🌧️", 
        description = "No watering needed, but slower growth",
        effects = {
            growthMultiplier = 0.8, -- 20% slower growth
            waterEvaporation = 0, -- No water loss during rain
            autoWater = true, -- Automatically waters all crops
            damageChance = 0
        },
        benefitSeeds = {"carrot", "potato"}, -- Root vegetables love rain
        color = Color3.fromRGB(100, 150, 255)
    },
    
    Cloudy = {
        name = "Cloudy",
        emoji = "☁️",
        description = "Neutral weather with no special effects",
        effects = {
            growthMultiplier = 1.0, -- Normal growth rate
            waterEvaporation = 1.0, -- Normal water loss
            damageChance = 0
        },
        benefitSeeds = {}, -- No special benefits
        color = Color3.fromRGB(150, 150, 150)
    },
    
    Thunderstorm = {
        name = "Thunderstorm",
        emoji = "⛈️",
        description = "Dangerous storms can damage unprotected crops",
        effects = {
            growthMultiplier = 0.6, -- 40% slower growth due to stress
            waterEvaporation = 0, -- No water loss
            autoWater = true, -- Heavy rain waters crops
            damageChance = 0.15 -- 15% chance to damage unprotected crops
        },
        benefitSeeds = {}, -- No crops benefit from storms
        color = Color3.fromRGB(100, 100, 200)
    }
}

-- Weather progression pattern (loops)
local WeatherPattern = {"Sunny", "Cloudy", "Rainy", "Sunny", "Cloudy", "Thunderstorm", "Cloudy", "Sunny"}

-- Current state
local currentWeatherIndex = 1
local currentWeatherName = "Sunny" -- Track the actual current weather
local weatherStartTime = 0
local isInitialized = false

-- Events for other systems
local weatherChangeCallbacks = {}

-- Clear any existing sky objects and lighting effects
function WeatherSystem.clearSky()
    local Lighting = game:GetService("Lighting")
    
    -- Remove all existing Sky objects
    for _, child in pairs(Lighting:GetChildren()) do
        if child:IsA("Sky") then
            child:Destroy()
        end
    end
    
    -- Reset lighting to defaults
    Lighting.Brightness = 2
    Lighting.Ambient = Color3.fromRGB(128, 128, 128)
    Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
end

-- Initialize weather system
function WeatherSystem.initialize()
    if isInitialized then 
        return 
    end
    
    log.info("Initializing weather system...")
    
    -- Clear any existing sky objects first
    WeatherSystem.clearSky()
    
    -- Start with sunny weather
    currentWeatherName = "Sunny"
    currentWeatherIndex = 1
    weatherStartTime = tick()
    
    -- Force apply initial weather effects
    WeatherSystem.applyWeatherEffects("Sunny")
    
    -- Start weather update loop
    WeatherSystem.startWeatherLoop()
    
    isInitialized = true
    log.info("Weather system initialized - Starting weather: Sunny")
end

-- Start the weather update loop
function WeatherSystem.startWeatherLoop()
    spawn(function()
        while true do
            wait(10) -- Check every 10 seconds
            WeatherSystem.updateWeather()
        end
    end)
end

-- Update weather system (checks for weather changes)
function WeatherSystem.updateWeather()
    local currentTime = tick()
    local timeInCurrentWeather = currentTime - weatherStartTime
    
    -- Check if it's time to change weather
    if timeInCurrentWeather >= WEATHER_CYCLE_TIME then
        WeatherSystem.changeWeather()
    end
end

-- Change to next weather in pattern
function WeatherSystem.changeWeather()
    local oldWeather = WeatherPattern[currentWeatherIndex]
    
    -- Move to next weather in pattern
    currentWeatherIndex = currentWeatherIndex + 1
    if currentWeatherIndex > #WeatherPattern then
        currentWeatherIndex = 1
    end
    
    local newWeather = WeatherPattern[currentWeatherIndex]
    weatherStartTime = tick()
    
    log.info("Weather changed from", oldWeather, "to", newWeather)
    
    -- Apply weather effects
    WeatherSystem.applyWeatherEffects(newWeather)
    
    -- Notify all players
    WeatherSystem.notifyWeatherChange(newWeather)
    
    -- Broadcast weather data to all players
    local RemoteManager = require(script.Parent.RemoteManager)
    RemoteManager.broadcastWeatherData()
    
    -- Call registered callbacks
    for _, callback in ipairs(weatherChangeCallbacks) do
        pcall(callback, newWeather, oldWeather)
    end
end

-- Apply weather effects to all active plots
function WeatherSystem.applyWeatherEffects(weatherName)
    local weatherData = WeatherTypes[weatherName]
    if not weatherData then 
        log.warn("Weather type not found:", weatherName)
        return 
    end
    
    -- Auto-water crops during rain/storms
    if weatherData.effects and weatherData.effects.autoWater then
        WeatherSystem.autoWaterAllCrops()
    end
    
    -- Apply storm damage if applicable
    if weatherData.effects and weatherData.effects.damageChance and weatherData.effects.damageChance > 0 then
        WeatherSystem.applyStormDamage(weatherData.effects.damageChance)
    end
    
    -- Apply visual effects (skybox, lighting, etc.)
    WeatherSystem.applyVisualEffects(weatherName)
    
    log.info("Weather changed to:", weatherName)
end

-- Visual effects disabled for now - skybox can be added later
function WeatherSystem.applyVisualEffects(weatherName)
    -- No visual effects for now - just keep the weather logic
    log.info("Weather changed to", weatherName, "(visual effects disabled)")
end

-- Auto-water all crops during rain/storms
function WeatherSystem.autoWaterAllCrops()
    local PlotManager = require(script.Parent.PlotManager)
    local waterCount = 0
    
    -- This would need to iterate through all active plots
    -- For now, we'll add this functionality when we have plot tracking
    
    log.info("Auto-watering crops due to rain/storm")
end

-- Apply storm damage to unprotected crops
function WeatherSystem.applyStormDamage(damageChance)
    local PlotManager = require(script.Parent.PlotManager)
    local damageCount = 0
    
    -- This would check all plots for protection (roofs) and apply damage
    -- For now, we'll implement this when we add the roof system
    
    log.info("Checking for storm damage to unprotected crops")
end

-- Notify all players about weather change
function WeatherSystem.notifyWeatherChange(weatherName)
    local weatherData = WeatherTypes[weatherName]
    if not weatherData then return end
    
    local message = weatherData.emoji .. " Weather changed to " .. weatherName .. "! " .. weatherData.description
    
    for _, player in ipairs(Players:GetPlayers()) do
        NotificationManager.sendNotification(player, message, "info")
    end
end

-- Get current weather information
function WeatherSystem.getCurrentWeather()
    local weatherData = WeatherTypes[currentWeatherName]
    local timeRemaining = WEATHER_CYCLE_TIME - (tick() - weatherStartTime)
    
    if not weatherData then
        log.warn("Weather type not found:", currentWeatherName)
        return nil
    end
    
    return {
        name = currentWeatherName,
        emoji = weatherData.emoji,
        description = weatherData.description,
        effects = weatherData.effects,
        benefitSeeds = weatherData.benefitSeeds,
        timeRemaining = math.max(0, timeRemaining),
        progress = math.min(1, (tick() - weatherStartTime) / WEATHER_CYCLE_TIME)
    }
end

-- Get weather forecast
function WeatherSystem.getForecast()
    local forecast = {}
    
    for i = 1, FORECAST_HOURS do
        local forecastIndex = currentWeatherIndex + i
        if forecastIndex > #WeatherPattern then
            forecastIndex = forecastIndex - #WeatherPattern
        end
        
        local weatherName = WeatherPattern[forecastIndex]
        table.insert(forecast, {
            name = weatherName,
            data = WeatherTypes[weatherName],
            hoursFromNow = i
        })
    end
    
    return forecast
end

-- Calculate weather effect on growth time
function WeatherSystem.getWeatherGrowthMultiplier(seedType)
    local currentWeather = WeatherSystem.getCurrentWeather()
    local weatherData = currentWeather.data
    
    if not weatherData then return 1.0 end
    
    local baseMultiplier = weatherData.effects.growthMultiplier or 1.0
    
    -- Check if this seed benefits from current weather
    if weatherData.benefitSeeds then
        for _, benefitSeed in ipairs(weatherData.benefitSeeds) do
            if benefitSeed == seedType then
                -- Extra boost for beneficial weather
                return baseMultiplier * 1.2
            end
        end
    end
    
    return baseMultiplier
end

-- Check if current weather auto-waters crops
function WeatherSystem.isAutoWatering()
    local currentWeather = WeatherSystem.getCurrentWeather()
    return currentWeather.data and currentWeather.data.effects.autoWater or false
end

-- Register callback for weather changes
function WeatherSystem.onWeatherChange(callback)
    table.insert(weatherChangeCallbacks, callback)
end

-- Get weather data for client
function WeatherSystem.getWeatherDataForClient()
    local WeatherConfig = require(script.Parent.Parent.config.WeatherConfig)
    return {
        current = WeatherSystem.getCurrentWeather(),
        forecast = WeatherSystem.getForecast(),
        types = WeatherConfig.getAllWeatherTypes()
    }
end

-- Debug function to force weather change
function WeatherSystem.forceWeatherChange(weatherName)
    local WeatherConfig = require(script.Parent.Parent.config.WeatherConfig)
    local weatherType = WeatherConfig.getWeatherType(weatherName)
    
    if not weatherType then
        log.warn("Invalid weather name:", weatherName)
        return false
    end
    
    -- Directly force the weather change
    currentWeatherName = weatherName -- Update current weather name
    currentWeatherIndex = 1 -- Reset to beginning for forced changes
    weatherStartTime = tick()
    
    WeatherSystem.applyWeatherEffects(weatherName)
    WeatherSystem.notifyWeatherChange(weatherName)
    
    log.info("Forced weather change to", weatherName)
    return true
end

return WeatherSystem