-- Client-Side Plot Growth Calculator
-- Handles all growth calculations, offline progression, and real-time updates
-- This replaces server-side growth polling with efficient client calculations

local RunService = game:GetService("RunService")
-- Simple logging removed ClientLogger
local CropRegistry = require(game:GetService("ReplicatedStorage").Shared.CropRegistry)


local PlotGrowthCalculator = {}

-- Constants
local SECONDS_PER_HOUR = 3600
local MAX_REASONABLE_OFFLINE_HOURS = 24 * 7 -- 1 week max offline time

-- Helper function to get current timestamp
local function getCurrentTime()
    return os.time()
end

-- Helper function to convert hours to seconds
local function hoursToSeconds(hours)
    return hours * SECONDS_PER_HOUR
end

-- Helper function to convert seconds to hours
local function secondsToHours(seconds)
    return seconds / SECONDS_PER_HOUR
end

-- Helper function to safely get crop data
local function getCropData(seedType)
    if not seedType or not CropRegistry.crops[seedType] then
        warn("[WARN]", "Invalid seed type for growth calculation:", seedType)
        return nil
    end
    return CropRegistry.crops[seedType]
end

--[[
    Calculate how much time the plot was actually growing (accounting for water needs)
    
    Parameters:
    - timeOffline: How long the player was offline (seconds)
    - waterNeededAt: Timestamp when the plot will need water next
    - currentTime: Current timestamp
    
    Returns:
    - actualGrowthTime: Time the plot could actually grow (seconds)
]]
function PlotGrowthCalculator.calculateActualGrowthTime(timeOffline, waterNeededAt, currentTime)
    currentTime = currentTime or getCurrentTime()
    
    -- If waterNeededAt is in the future, plot can grow for full offline duration
    if waterNeededAt > currentTime then
        return timeOffline
    end
    
    -- If waterNeededAt is in the past, calculate how long plot could grow before needing water
    local timeUntilWaterNeeded = waterNeededAt - (currentTime - timeOffline)
    
    -- If water was already needed when player left, no growth occurred
    if timeUntilWaterNeeded <= 0 then
        return 0
    end
    
    -- Plot grew until it needed water
    return math.min(timeOffline, timeUntilWaterNeeded)
end

--[[
    Calculate offline crop production
    
    Parameters:
    - plotData: Complete plot state data
    - lastOnlineAt: When player was last online
    - playerBoosts: Current player boost multipliers (only applied if online)
    
    Returns:
    - Table with:
        - totalCropsReady: Total crops ready to harvest
        - cropsFromOfflineGrowth: How many crops grew while offline
        - timeGrowing: How long the plot was actually growing
        - waterNeeded: Whether plot needs water now
]]
function PlotGrowthCalculator.calculateOfflineGrowth(plotData, lastOnlineAt, playerBoosts)
    local currentTime = getCurrentTime()
    local timeOffline = currentTime - lastOnlineAt
    
    -- Validate input data
    if not plotData or not lastOnlineAt then
        error("[ERROR]", "Invalid data for offline growth calculation")
        return {
            totalCropsReady = 0,
            cropsFromOfflineGrowth = 0,
            timeGrowing = 0,
            waterNeeded = true
        }
    end
    
    -- Get crop data
    local cropData = getCropData(plotData.seedType)
    if not cropData then
        return {
            totalCropsReady = 0,
            cropsFromOfflineGrowth = 0,
            timeGrowing = 0,
            waterNeeded = true
        }
    end
    
    -- Safety check for unreasonable offline times
    if timeOffline > hoursToSeconds(MAX_REASONABLE_OFFLINE_HOURS) then
        warn("[WARN]", "Capping offline time from", secondsToHours(timeOffline), "to", MAX_REASONABLE_OFFLINE_HOURS, "hours")
        timeOffline = hoursToSeconds(MAX_REASONABLE_OFFLINE_HOURS)
    end
    
    -- If plot isn't in a growing state, return current ready crops
    if plotData.state ~= "watered" and plotData.state ~= "ready" then
        return {
            totalCropsReady = plotData.accumulatedCrops or 0,
            cropsFromOfflineGrowth = 0,
            timeGrowing = 0,
            waterNeeded = plotData.state ~= "watered"
        }
    end
    
    -- Calculate when plot will need water next
    local maintenanceInterval = cropData.maintenanceWaterInterval or 24 -- Default 24 hours
    local lastMaintenanceTime = plotData.lastMaintenanceWater or plotData.wateredTime or lastOnlineAt
    local waterNeededAt = lastMaintenanceTime + hoursToSeconds(maintenanceInterval)
    
    -- Calculate actual growing time (accounting for water limitations)
    local actualGrowthTime = PlotGrowthCalculator.calculateActualGrowthTime(timeOffline, waterNeededAt, currentTime)
    
    -- Calculate crops produced during offline time
    local productionRate = cropData.productionRate or 0 -- crops per hour
    local growthHours = secondsToHours(actualGrowthTime)
    local cropsFromOfflineGrowth = math.floor(growthHours * productionRate)
    
    -- Get existing crops ready to harvest
    local existingCrops = plotData.accumulatedCrops or 0
    
    -- Calculate total crops (existing + new)
    local totalCropsBeforeLimit = existingCrops + cropsFromOfflineGrowth
    
    -- Apply plot capacity limit
    local plotLimit = cropData.plotLimit or 1000 -- Default limit
    local totalCropsReady = math.min(totalCropsBeforeLimit, plotLimit)
    
    -- Determine if plot needs water now
    local waterNeeded = currentTime >= waterNeededAt
    
    
    return {
        totalCropsReady = totalCropsReady,
        cropsFromOfflineGrowth = cropsFromOfflineGrowth,
        timeGrowing = actualGrowthTime,
        waterNeeded = waterNeeded
    }
end

--[[
    Calculate real-time growth progress for online players
    
    Parameters:
    - plotData: Complete plot state data
    - playerBoosts: Current player boost multipliers
    
    Returns:
    - Table with:
        - cropsReady: Current crops ready to harvest
        - nextCropIn: Seconds until next crop is ready
        - productionRate: Current effective production rate (including boosts)
        - needsWater: Whether plot needs watering
]]
function PlotGrowthCalculator.calculateRealTimeGrowth(plotData, playerBoosts)
    local currentTime = getCurrentTime()
    
    -- Validate input data
    if not plotData then
        error("[ERROR]", "Invalid plot data for real-time growth calculation")
        return {
            cropsReady = 0,
            nextCropIn = 0,
            productionRate = 0,
            needsWater = true
        }
    end
    
    -- Get crop data
    local cropData = getCropData(plotData.seedType)
    if not cropData then
        return {
            cropsReady = 0,
            nextCropIn = 0,
            productionRate = 0,
            needsWater = true
        }
    end
    
    -- If plot isn't growing, return static state
    if plotData.state ~= "watered" and plotData.state ~= "ready" then
        return {
            cropsReady = plotData.accumulatedCrops or 0,
            nextCropIn = 0,
            productionRate = 0,
            needsWater = plotData.state ~= "watered"
        }
    end
    
    -- Calculate effective production rate with online boosts
    local baseProductionRate = cropData.productionRate or 0
    local boostMultiplier = 1
    
    -- Apply player boosts (only when online)
    if playerBoosts then
        if playerBoosts.onlineBoost then
            boostMultiplier = boostMultiplier * playerBoosts.onlineBoost
        end
        if playerBoosts.globalMultiplier then
            boostMultiplier = boostMultiplier * playerBoosts.globalMultiplier
        end
        -- Add other boost types as needed
    end
    
    local effectiveProductionRate = baseProductionRate * boostMultiplier
    
    -- Check if plot needs water
    local maintenanceInterval = cropData.maintenanceWaterInterval or 24
    local lastMaintenanceTime = plotData.lastMaintenanceWater or plotData.wateredTime or currentTime
    local waterNeededAt = lastMaintenanceTime + hoursToSeconds(maintenanceInterval)
    local needsWater = currentTime >= waterNeededAt
    
    -- If plot needs water, production stops
    if needsWater then
        return {
            cropsReady = plotData.accumulatedCrops or 0,
            nextCropIn = 0,
            productionRate = 0,
            needsWater = true
        }
    end
    
    -- Calculate time since last production update
    local lastUpdateTime = plotData.lastUpdateTime or plotData.wateredTime or currentTime
    local timeSinceUpdate = currentTime - lastUpdateTime
    
    -- Calculate new crops produced
    local growthHours = secondsToHours(timeSinceUpdate)
    local newCrops = math.floor(growthHours * effectiveProductionRate)
    
    -- Get current total crops
    local existingCrops = plotData.accumulatedCrops or 0
    local totalCrops = existingCrops + newCrops
    
    -- Apply plot limit
    local plotLimit = cropData.plotLimit or 1000
    local cropsReady = math.min(totalCrops, plotLimit)
    
    -- Calculate time until next crop (if not at limit)
    local nextCropIn = 0
    if cropsReady < plotLimit and effectiveProductionRate > 0 then
        local secondsPerCrop = SECONDS_PER_HOUR / effectiveProductionRate
        local timeSinceLastCrop = timeSinceUpdate % secondsPerCrop
        nextCropIn = secondsPerCrop - timeSinceLastCrop
    end
    
    return {
        cropsReady = cropsReady,
        nextCropIn = nextCropIn,
        productionRate = effectiveProductionRate,
        needsWater = false
    }
end

--[[
    Calculate growth progress percentage for UI display
    
    Parameters:
    - plotData: Complete plot state data
    - cropData: Crop configuration data
    
    Returns:
    - progressPercent: Growth progress from 0-100
]]
function PlotGrowthCalculator.calculateGrowthProgress(plotData, cropData)
    if not plotData or not cropData then
        return 0
    end
    
    local currentTime = getCurrentTime()
    
    -- Handle different plot states
    if plotData.state == "planted" then
        -- Progress from planted to watered (watering progress)
        local wateredCount = plotData.wateredCount or 0
        local waterNeeded = plotData.waterNeeded or cropData.waterNeeded or 1
        return (wateredCount / waterNeeded) * 50 -- Watering is first 50% of progress
    elseif plotData.state == "watered" or plotData.state == "ready" then
        -- Progress from watered to ready (growing progress)
        local wateredTime = plotData.wateredTime or currentTime
        local growthTime = cropData.growthTime or 3600 -- Default 1 hour
        local timeGrowing = currentTime - wateredTime
        
        local growthProgress = math.min((timeGrowing / growthTime) * 50, 50) -- Growing is second 50%
        return 50 + growthProgress -- Start at 50% (watered) + growth progress
    end
    
    return 0
end

--[[
    Get formatted time remaining string for UI display
    
    Parameters:
    - seconds: Time remaining in seconds
    
    Returns:
    - Formatted string like "5m 30s" or "2h 15m"
]]
function PlotGrowthCalculator.formatTimeRemaining(seconds)
    if seconds <= 0 then
        return "Ready!"
    end
    
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    
    if hours > 0 then
        if minutes > 0 then
            return string.format("%dh %dm", hours, minutes)
        else
            return string.format("%dh", hours)
        end
    elseif minutes > 0 then
        if secs > 0 then
            return string.format("%dm %ds", minutes, secs)
        else
            return string.format("%dm", minutes)
        end
    else
        return string.format("%ds", secs)
    end
end

--[[
    Main function to get complete plot status for UI updates
    
    Parameters:
    - plotData: Complete plot state data
    - lastOnlineAt: When player was last online (for offline calculations)
    - playerBoosts: Current player boost multipliers
    
    Returns:
    - Complete plot status for UI consumption
]]
function PlotGrowthCalculator.getPlotStatus(plotData, lastOnlineAt, playerBoosts)
    if not plotData then
        return nil
    end
    
    local cropData = getCropData(plotData.seedType)
    if not cropData then
        return nil
    end
    
    local currentTime = getCurrentTime()
    
    -- Determine if we need to calculate offline growth
    local needsOfflineCalculation = lastOnlineAt and (currentTime - lastOnlineAt) > 60 -- More than 1 minute offline
    
    local status = {}
    
    if needsOfflineCalculation then
        -- Calculate offline growth
        local offlineResult = PlotGrowthCalculator.calculateOfflineGrowth(plotData, lastOnlineAt, playerBoosts)
        status.cropsReady = offlineResult.totalCropsReady
        status.needsWater = offlineResult.waterNeeded
        status.offlineGrowth = offlineResult.cropsFromOfflineGrowth
        status.productionRate = cropData.productionRate -- Base rate for offline
        status.nextCropIn = 0 -- Will be calculated in real-time after this
    else
        -- Calculate real-time growth
        local realtimeResult = PlotGrowthCalculator.calculateRealTimeGrowth(plotData, playerBoosts)
        status.cropsReady = realtimeResult.cropsReady
        status.needsWater = realtimeResult.needsWater
        status.productionRate = realtimeResult.productionRate
        status.nextCropIn = realtimeResult.nextCropIn
        status.offlineGrowth = 0
    end
    
    -- Add common status information
    status.growthProgress = PlotGrowthCalculator.calculateGrowthProgress(plotData, cropData)
    status.timeRemainingText = PlotGrowthCalculator.formatTimeRemaining(status.nextCropIn)
    status.plotLimit = cropData.plotLimit or 1000
    status.isAtLimit = status.cropsReady >= status.plotLimit
    status.cropName = cropData.name or plotData.seedType
    status.plotState = plotData.state
    
    return status
end

return PlotGrowthCalculator