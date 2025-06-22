-- Server-side farming system management
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Promise = require(Packages.promise)

local FarmingSystem = {}

-- Active farms data (server-side)
local activeFarms = {}
local plantGrowthTimes = {
    tomato = 30,    -- 30 seconds for testing
    carrot = 45,    -- 45 seconds
    wheat = 20,     -- 20 seconds
    potato = 60     -- 60 seconds
}

local cropPrices = {
    tomato = 5,
    carrot = 8,
    wheat = 3,
    potato = 12
}

-- Climate system
local globalClimate = {
    temperature = 72,
    humidity = 60,
    airQuality = 100,
    season = "spring"
}

-- Initialize the farming system
function FarmingSystem.initialize()
    print("FarmingSystem: Initializing...")
    
    -- Start climate update loop
    spawn(function()
        while true do
            FarmingSystem.updateClimate()
            wait(60) -- Update climate every minute
        end
    end)
    
    -- Start plant growth checking loop
    spawn(function()
        while true do
            FarmingSystem.checkPlantGrowth()
            wait(5) -- Check every 5 seconds
        end
    end)
    
    print("FarmingSystem: Ready!")
end

-- Get player farm data
function FarmingSystem.getPlayerFarm(player)
    local userId = tostring(player.UserId)
    if not activeFarms[userId] then
        activeFarms[userId] = {
            plots = {},
            equipment = {
                wateringCan = true,
                airPurifier = false,
                advancedSoil = false
            }
        }
    end
    return activeFarms[userId]
end

-- Plant a seed
function FarmingSystem.plantSeed(player, plotId, seedType, soilType)
    return Promise.new(function(resolve, reject)
        local farm = FarmingSystem.getPlayerFarm(player)
        
        -- Check if plot is empty
        if farm.plots[plotId] then
            reject("Plot is already occupied")
            return
        end
        
        -- Plant the seed
        farm.plots[plotId] = {
            seedType = seedType,
            soilType = soilType or "basic",
            plantedAt = tick(),
            watered = false,
            lastWatered = nil,
            growthStage = 0, -- 0 = planted, 1 = growing, 2 = ready
            healthModifier = 1.0
        }
        
        print(player.Name .. " planted " .. seedType .. " in plot " .. plotId)
        resolve(true)
    end)
end

-- Water a plant
function FarmingSystem.waterPlant(player, plotId)
    return Promise.new(function(resolve, reject)
        local farm = FarmingSystem.getPlayerFarm(player)
        local plot = farm.plots[plotId]
        
        if not plot then
            reject("No plant in this plot")
            return
        end
        
        if plot.watered and plot.lastWatered and (tick() - plot.lastWatered) < 10 then
            reject("Plant was recently watered")
            return
        end
        
        plot.watered = true
        plot.lastWatered = tick()
        plot.growthStage = math.max(plot.growthStage, 1)
        
        print(player.Name .. " watered plant in plot " .. plotId)
        resolve(true)
    end)
end

-- Harvest a crop
function FarmingSystem.harvestCrop(player, plotId)
    return Promise.new(function(resolve, reject)
        local farm = FarmingSystem.getPlayerFarm(player)
        local plot = farm.plots[plotId]
        
        if not plot then
            reject("No plant in this plot")
            return
        end
        
        if plot.growthStage < 2 then
            reject("Plant is not ready for harvest")
            return
        end
        
        local seedType = plot.seedType
        local baseYield = 1
        local bonusYield = 0
        
        -- Calculate bonus yield based on soil and equipment
        if plot.soilType == "advanced" then
            bonusYield = bonusYield + math.random(0, 1)
        end
        
        if farm.equipment.airPurifier then
            bonusYield = bonusYield + math.random(0, 1)
        end
        
        local totalYield = baseYield + bonusYield
        local experience = totalYield * 10
        
        -- Remove plant from plot
        farm.plots[plotId] = nil
        
        print(player.Name .. " harvested " .. totalYield .. " " .. seedType .. " from plot " .. plotId)
        
        resolve({
            cropType = seedType,
            amount = totalYield,
            experience = experience
        })
    end)
end

-- Sell crops
function FarmingSystem.sellCrops(player, cropType, amount)
    return Promise.new(function(resolve, reject)
        if not cropPrices[cropType] then
            reject("Invalid crop type")
            return
        end
        
        local basePrice = cropPrices[cropType]
        local totalProfit = basePrice * amount
        
        -- Apply market fluctuations (simple random modifier)
        local marketModifier = math.random(80, 120) / 100
        totalProfit = math.floor(totalProfit * marketModifier)
        
        print(player.Name .. " sold " .. amount .. " " .. cropType .. " for $" .. totalProfit)
        
        resolve({
            profit = totalProfit,
            pricePerUnit = math.floor(totalProfit / amount)
        })
    end)
end

-- Check plant growth status
function FarmingSystem.checkPlantGrowth()
    for userId, farm in pairs(activeFarms) do
        for plotId, plot in pairs(farm.plots) do
            if plot.watered and plot.growthStage == 1 then
                local growthTime = plantGrowthTimes[plot.seedType] or 30
                local timeSinceWatered = tick() - (plot.lastWatered or 0)
                
                -- Apply climate and soil modifiers
                local growthModifier = 1.0
                if plot.soilType == "advanced" then
                    growthModifier = growthModifier * 0.8 -- 20% faster growth
                end
                
                if globalClimate.temperature > 80 or globalClimate.temperature < 60 then
                    growthModifier = growthModifier * 1.2 -- Slower in extreme temps
                end
                
                local adjustedGrowthTime = growthTime * growthModifier
                
                if timeSinceWatered >= adjustedGrowthTime then
                    plot.growthStage = 2 -- Ready for harvest
                    print("Plant in plot " .. plotId .. " is ready for harvest!")
                end
            end
        end
    end
end

-- Update global climate
function FarmingSystem.updateClimate()
    -- Simple climate simulation
    globalClimate.temperature = globalClimate.temperature + math.random(-2, 2)
    globalClimate.temperature = math.max(50, math.min(90, globalClimate.temperature))
    
    globalClimate.humidity = globalClimate.humidity + math.random(-5, 5)
    globalClimate.humidity = math.max(30, math.min(90, globalClimate.humidity))
    
    globalClimate.airQuality = math.max(60, math.min(100, globalClimate.airQuality + math.random(-1, 1)))
    
    print("Climate updated: Temp=" .. globalClimate.temperature .. "°F, Humidity=" .. globalClimate.humidity .. "%, Air Quality=" .. globalClimate.airQuality)
end

-- Get current climate
function FarmingSystem.getClimate()
    return globalClimate
end

-- Get plant growth info
function FarmingSystem.getPlantInfo(player, plotId)
    local farm = FarmingSystem.getPlayerFarm(player)
    local plot = farm.plots[plotId]
    
    if not plot then
        return nil
    end
    
    local growthTime = plantGrowthTimes[plot.seedType] or 30
    local timeSinceWatered = plot.lastWatered and (tick() - plot.lastWatered) or 0
    local timeRemaining = math.max(0, growthTime - timeSinceWatered)
    
    return {
        seedType = plot.seedType,
        growthStage = plot.growthStage,
        watered = plot.watered,
        timeRemaining = timeRemaining,
        soilType = plot.soilType
    }
end

return FarmingSystem