-- Main game state reducer using Rodux
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Rodux = require(Packages.rodux)

-- Helper function for joining tables (joinTables equivalent)
local function joinTables(...)
    local result = {}
    for i = 1, select("#", ...) do
        local dict = select(i, ...)
        for key, value in pairs(dict) do
            result[key] = value
        end
    end
    return result
end

-- Helper function for combining reducers
local function combineReducers(reducers)
    return function(state, action)
        local newState = {}
        for key, reducer in pairs(reducers) do
            newState[key] = reducer(state and state[key], action)
        end
        return newState
    end
end

-- Initial game state
local initialState = {
    player = {
        money = 100,
        level = 1,
        experience = 0
    },
    farm = {
        plots = {},
        equipment = {
            wateringCan = true,
            airPurifier = false,
            advancedSoil = false
        },
        climate = {
            temperature = 72,
            humidity = 60,
            airQuality = 100
        }
    },
    inventory = {
        seeds = {
            tomato = 5,
            carrot = 3,
            wheat = 2
        },
        crops = {},
        tools = {}
    },
    shop = {
        seeds = {
            tomato = { price = 2, name = "Tomato Seeds" },
            carrot = { price = 3, name = "Carrot Seeds" },
            wheat = { price = 1, name = "Wheat Seeds" },
            potato = { price = 4, name = "Potato Seeds" }
        },
        equipment = {
            airPurifier = { price = 500, name = "Air Purifier" },
            advancedSoil = { price = 200, name = "Advanced Soil" },
            greenhouse = { price = 1000, name = "Greenhouse" }
        }
    }
}

-- Action types
local ActionTypes = {
    PLANT_SEED = "PLANT_SEED",
    WATER_PLANT = "WATER_PLANT", 
    HARVEST_CROP = "HARVEST_CROP",
    BUY_ITEM = "BUY_ITEM",
    SELL_CROP = "SELL_CROP",
    UPDATE_CLIMATE = "UPDATE_CLIMATE",
    GAIN_EXPERIENCE = "GAIN_EXPERIENCE"
}

-- Reducers
local function playerReducer(state, action)
    state = state or initialState.player
    
    if action.type == ActionTypes.BUY_ITEM then
        return joinTables(state, {
            money = state.money - action.cost
        })
    elseif action.type == ActionTypes.SELL_CROP then
        return joinTables(state, {
            money = state.money + action.profit
        })
    elseif action.type == ActionTypes.GAIN_EXPERIENCE then
        local newExp = state.experience + action.amount
        local newLevel = state.level
        
        -- Level up every 100 experience points
        if newExp >= state.level * 100 then
            newLevel = newLevel + 1
        end
        
        return joinTables(state, {
            experience = newExp,
            level = newLevel
        })
    end
    
    return state
end

local function farmReducer(state, action)
    state = state or initialState.farm
    
    if action.type == ActionTypes.PLANT_SEED then
        local newPlots = joinTables(state.plots, {
            [action.plotId] = {
                seedType = action.seedType,
                plantedAt = tick(),
                watered = false,
                soilType = action.soilType or "basic"
            }
        })
        
        return joinTables(state, {
            plots = newPlots
        })
    elseif action.type == ActionTypes.WATER_PLANT then
        local plot = state.plots[action.plotId]
        if plot then
            local newPlots = joinTables(state.plots, {
                [action.plotId] = joinTables(plot, {
                    watered = true,
                    lastWatered = tick()
                })
            })
            
            return joinTables(state, {
                plots = newPlots
            })
        end
    elseif action.type == ActionTypes.HARVEST_CROP then
        local newPlots = joinTables(state.plots)
        newPlots[action.plotId] = nil
        
        return joinTables(state, {
            plots = newPlots
        })
    elseif action.type == ActionTypes.UPDATE_CLIMATE then
        return joinTables(state, {
            climate = joinTables(state.climate, action.climate)
        })
    end
    
    return state
end

local function inventoryReducer(state, action)
    state = state or initialState.inventory
    
    if action.type == ActionTypes.PLANT_SEED then
        local newSeeds = joinTables(state.seeds, {
            [action.seedType] = math.max(0, (state.seeds[action.seedType] or 0) - 1)
        })
        
        return joinTables(state, {
            seeds = newSeeds
        })
    elseif action.type == ActionTypes.HARVEST_CROP then
        local newCrops = joinTables(state.crops, {
            [action.cropType] = (state.crops[action.cropType] or 0) + action.amount
        })
        
        return joinTables(state, {
            crops = newCrops
        })
    elseif action.type == ActionTypes.BUY_ITEM then
        if action.itemType == "seed" then
            local newSeeds = joinTables(state.seeds, {
                [action.item] = (state.seeds[action.item] or 0) + action.quantity
            })
            
            return joinTables(state, {
                seeds = newSeeds
            })
        end
    elseif action.type == ActionTypes.SELL_CROP then
        local newCrops = joinTables(state.crops, {
            [action.cropType] = math.max(0, (state.crops[action.cropType] or 0) - action.amount)
        })
        
        return joinTables(state, {
            crops = newCrops
        })
    end
    
    return state
end

-- Main reducer
local gameReducer = combineReducers({
    player = playerReducer,
    farm = farmReducer,
    inventory = inventoryReducer,
    shop = function(state)
        return state or initialState.shop
    end
})

return gameReducer