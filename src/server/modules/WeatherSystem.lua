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
local WEATHER_UPDATE_INTERVAL = 60 -- Check every minute for day changes
local FORECAST_DAYS = 3 -- Show forecast for next 3 days

-- Weather Types and Effects
local WeatherTypes = {
    Sunny = {
        name = "Sunny",
        emoji = "☀️",
        icon = "http://www.roblox.com/asset/?id=240651661", -- Proper sunny weather icon
        description = "Perfect growing conditions with enhanced crop growth",
        gameplayDescription = "• 20% faster growth for sun-loving crops\n• Plants need watering more often",
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
        icon = "http://www.roblox.com/asset/?id=240651406", -- Proper rainy weather icon
        description = "Gentle rainfall keeps crops hydrated automatically",
        gameplayDescription = "• No watering needed - auto-waters all crops\n• Slightly slower overall growth",
        effects = {
            growthMultiplier = 0.9, -- 10% slower growth
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
        icon = "http://www.roblox.com/asset/?id=240650939", -- Proper cloudy weather icon
        description = "Mild conditions with no special effects",
        gameplayDescription = "• Normal growth rates\n• Standard watering requirements",
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
        icon = "http://www.roblox.com/asset/?id=261307430", -- Proper thunderstorm weather icon
        description = "Dangerous weather that can damage unprotected crops",
        gameplayDescription = "• Auto-waters crops but slows growth\n• 15% chance to damage crops",
        effects = {
            growthMultiplier = 0.7, -- 30% slower growth due to stress
            waterEvaporation = 0, -- No water loss
            autoWater = true, -- Heavy rain waters crops
            damageChance = 0.15 -- 15% chance to damage unprotected crops
        },
        benefitSeeds = {}, -- No crops benefit from storms
        color = Color3.fromRGB(100, 100, 200)
    }
}

-- Day-based weather pattern (7 days)
-- Sunny on weekends, predictable pattern during week
local DayWeatherPattern = {
    [1] = "Sunny",        -- Sunday (weekend)
    [2] = "Cloudy",       -- Monday
    [3] = "Rainy",        -- Tuesday
    [4] = "Sunny",        -- Wednesday
    [5] = "Thunderstorm", -- Thursday
    [6] = "Cloudy",       -- Friday
    [7] = "Sunny"         -- Saturday (weekend)
}

-- Current state
local currentWeatherName = "Sunny"
local currentDayOfWeek = 1
local isInitialized = false

-- Events for other systems
local weatherChangeCallbacks = {}

-- Get current day of week (1 = Sunday, 7 = Saturday)
local function getCurrentDayOfWeek()
    local currentTime = os.time()
    local dateInfo = os.date("*t", currentTime)
    return dateInfo.wday -- 1 = Sunday, 2 = Monday, ..., 7 = Saturday
end

-- Get weather for specific day
local function getWeatherForDay(dayOfWeek)
    return DayWeatherPattern[dayOfWeek] or "Sunny"
end

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
    
    log.info("Initializing day-based weather system...")
    
    -- Clear any existing sky objects first
    WeatherSystem.clearSky()
    
    -- Get current day and set weather accordingly
    currentDayOfWeek = getCurrentDayOfWeek()
    currentWeatherName = getWeatherForDay(currentDayOfWeek)
    
    -- Force apply initial weather effects
    WeatherSystem.applyWeatherEffects(currentWeatherName)
    
    -- Start weather update loop (checks for day changes)
    WeatherSystem.startWeatherLoop()
    
    isInitialized = true
    log.info("Weather system initialized - Day", currentDayOfWeek, "Weather:", currentWeatherName)
end

-- Start the weather update loop
function WeatherSystem.startWeatherLoop()
    spawn(function()
        while true do
            wait(WEATHER_UPDATE_INTERVAL) -- Check every minute for day changes
            WeatherSystem.updateWeather()
        end
    end)
end

-- Update weather system (checks for day changes)
function WeatherSystem.updateWeather()
    local newDayOfWeek = getCurrentDayOfWeek()
    
    -- Check if the day has changed
    if newDayOfWeek ~= currentDayOfWeek then
        currentDayOfWeek = newDayOfWeek
        WeatherSystem.changeWeather()
    end
end

-- Change weather based on current day
function WeatherSystem.changeWeather()
    local oldWeather = currentWeatherName
    local newWeather = getWeatherForDay(currentDayOfWeek)
    
    if newWeather ~= oldWeather then
        currentWeatherName = newWeather
        
        log.info("Day changed! Weather changed from", oldWeather, "to", newWeather, "(Day", currentDayOfWeek .. ")")
        
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
    
    if not weatherData then
        log.warn("Weather type not found:", currentWeatherName)
        return nil
    end
    
    -- Get day name for display
    local dayNames = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"}
    local dayName = dayNames[currentDayOfWeek] or "Unknown"
    
    -- Generate a random temperature based on weather (just for display)
    local baseTemp = 72 -- Base temperature
    local tempVariation = {
        Sunny = math.random(75, 85),
        Cloudy = math.random(65, 75),
        Rainy = math.random(60, 70),
        Thunderstorm = math.random(58, 68)
    }
    
    return {
        name = currentWeatherName,
        data = weatherData,
        dayOfWeek = currentDayOfWeek,
        dayName = dayName,
        temperature = tempVariation[currentWeatherName] or baseTemp
    }
end

-- Get weather forecast
function WeatherSystem.getForecast()
    local forecast = {}
    local dayNames = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"}
    
    for i = 1, FORECAST_DAYS do
        local forecastDay = currentDayOfWeek + i
        if forecastDay > 7 then
            forecastDay = forecastDay - 7
        end
        
        local weatherName = getWeatherForDay(forecastDay)
        local weatherData = WeatherTypes[weatherName]
        
        if weatherData then
            table.insert(forecast, {
                name = weatherName,
                data = weatherData,
                dayOfWeek = forecastDay,
                dayName = dayNames[forecastDay],
                daysFromNow = i
            })
        end
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