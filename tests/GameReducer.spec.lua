-- Unit tests for GameReducer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Mock the packages for testing
local function createMockRodux()
    local Rodux = {}
    
    function Rodux.Dictionary.join(...)
        local result = {}
        for i = 1, select("#", ...) do
            local dict = select(i, ...)
            for key, value in pairs(dict) do
                result[key] = value
            end
        end
        return result
    end
    
    function Rodux.combineReducers(reducers)
        return function(state, action)
            local newState = {}
            for key, reducer in pairs(reducers) do
                newState[key] = reducer(state and state[key], action)
            end
            return newState
        end
    end
    
    return Rodux
end

-- Mock ReplicatedStorage for testing environment
if not ReplicatedStorage:FindFirstChild("Packages") then
    local packagesFolder = Instance.new("Folder")
    packagesFolder.Name = "Packages"
    packagesFolder.Parent = ReplicatedStorage
    
    local roduxModule = Instance.new("ModuleScript")
    roduxModule.Name = "Rodux"
    roduxModule.Source = "return " .. require(script.Parent.MockRodux)
    roduxModule.Parent = packagesFolder
end

return function()
    local GameReducer = require(script.Parent.Parent.src.shared.GameReducer)
    
    describe("GameReducer", function()
        local initialState
        
        beforeEach(function()
            initialState = {
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
        end)
        
        describe("Player Reducer", function()
            it("should handle BUY_ITEM action", function()
                local action = {
                    type = "BUY_ITEM",
                    cost = 50
                }
                
                local newState = GameReducer(initialState, action)
                
                expect(newState.player.money).to.equal(50)
            end)
            
            it("should handle SELL_CROP action", function()
                local action = {
                    type = "SELL_CROP",
                    profit = 25
                }
                
                local newState = GameReducer(initialState, action)
                
                expect(newState.player.money).to.equal(125)
            end)
            
            it("should handle GAIN_EXPERIENCE action", function()
                local action = {
                    type = "GAIN_EXPERIENCE",
                    amount = 50
                }
                
                local newState = GameReducer(initialState, action)
                
                expect(newState.player.experience).to.equal(50)
                expect(newState.player.level).to.equal(1) -- Should not level up yet
            end)
            
            it("should level up when experience threshold is reached", function()
                local stateWithExp = GameReducer(initialState, {
                    type = "GAIN_EXPERIENCE",
                    amount = 99
                })
                
                local levelUpState = GameReducer(stateWithExp, {
                    type = "GAIN_EXPERIENCE",
                    amount = 10
                })
                
                expect(levelUpState.player.experience).to.equal(109)
                expect(levelUpState.player.level).to.equal(2)
            end)
        end)
        
        describe("Farm Reducer", function()
            it("should handle PLANT_SEED action", function()
                local action = {
                    type = "PLANT_SEED",
                    plotId = 1,
                    seedType = "tomato",
                    soilType = "basic"
                }
                
                local newState = GameReducer(initialState, action)
                
                expect(newState.farm.plots[1]).to.be.ok()
                expect(newState.farm.plots[1].seedType).to.equal("tomato")
                expect(newState.farm.plots[1].soilType).to.equal("basic")
                expect(newState.farm.plots[1].watered).to.equal(false)
            end)
            
            it("should handle WATER_PLANT action", function()
                -- First plant a seed
                local plantedState = GameReducer(initialState, {
                    type = "PLANT_SEED",
                    plotId = 1,
                    seedType = "tomato",
                    soilType = "basic"
                })
                
                -- Then water it
                local wateredState = GameReducer(plantedState, {
                    type = "WATER_PLANT",
                    plotId = 1
                })
                
                expect(wateredState.farm.plots[1].watered).to.equal(true)
                expect(wateredState.farm.plots[1].lastWatered).to.be.ok()
            end)
            
            it("should handle HARVEST_CROP action", function()
                -- First plant a seed
                local plantedState = GameReducer(initialState, {
                    type = "PLANT_SEED",
                    plotId = 1,
                    seedType = "tomato",
                    soilType = "basic"
                })
                
                -- Then harvest it
                local harvestedState = GameReducer(plantedState, {
                    type = "HARVEST_CROP",
                    plotId = 1
                })
                
                expect(harvestedState.farm.plots[1]).to.equal(nil)
            end)
            
            it("should handle UPDATE_CLIMATE action", function()
                local action = {
                    type = "UPDATE_CLIMATE",
                    climate = {
                        temperature = 80,
                        humidity = 70
                    }
                }
                
                local newState = GameReducer(initialState, action)
                
                expect(newState.farm.climate.temperature).to.equal(80)
                expect(newState.farm.climate.humidity).to.equal(70)
                expect(newState.farm.climate.airQuality).to.equal(100) -- Should preserve unchanged values
            end)
        end)
        
        describe("Inventory Reducer", function()
            it("should consume seeds when planting", function()
                local action = {
                    type = "PLANT_SEED",
                    plotId = 1,
                    seedType = "tomato"
                }
                
                local newState = GameReducer(initialState, action)
                
                expect(newState.inventory.seeds.tomato).to.equal(4) -- Should decrease from 5 to 4
            end)
            
            it("should add crops when harvesting", function()
                local action = {
                    type = "HARVEST_CROP",
                    cropType = "tomato",
                    amount = 2
                }
                
                local newState = GameReducer(initialState, action)
                
                expect(newState.inventory.crops.tomato).to.equal(2)
            end)
            
            it("should add seeds when buying", function()
                local action = {
                    type = "BUY_ITEM",
                    itemType = "seed",
                    item = "potato",
                    quantity = 3
                }
                
                local newState = GameReducer(initialState, action)
                
                expect(newState.inventory.seeds.potato).to.equal(3)
            end)
            
            it("should remove crops when selling", function()
                -- First add some crops
                local stateWithCrops = GameReducer(initialState, {
                    type = "HARVEST_CROP",
                    cropType = "tomato",
                    amount = 5
                })
                
                -- Then sell some
                local soldState = GameReducer(stateWithCrops, {
                    type = "SELL_CROP",
                    cropType = "tomato",
                    amount = 3
                })
                
                expect(soldState.inventory.crops.tomato).to.equal(2)
            end)
            
            it("should not allow selling more crops than available", function()
                local action = {
                    type = "SELL_CROP",
                    cropType = "tomato",
                    amount = 5
                }
                
                local newState = GameReducer(initialState, action)
                
                expect(newState.inventory.crops.tomato).to.equal(0) -- Should not go negative
            end)
        end)
        
        describe("State Immutability", function()
            it("should not mutate original state", function()
                local originalMoney = initialState.player.money
                local originalSeeds = initialState.inventory.seeds.tomato
                
                GameReducer(initialState, {
                    type = "BUY_ITEM",
                    cost = 50
                })
                
                GameReducer(initialState, {
                    type = "PLANT_SEED",
                    plotId = 1,
                    seedType = "tomato"
                })
                
                expect(initialState.player.money).to.equal(originalMoney)
                expect(initialState.inventory.seeds.tomato).to.equal(originalSeeds)
            end)
        end)
        
        describe("Edge Cases", function()
            it("should handle unknown action types gracefully", function()
                local action = {
                    type = "UNKNOWN_ACTION"
                }
                
                local newState = GameReducer(initialState, action)
                
                -- State should remain unchanged
                expect(newState.player.money).to.equal(initialState.player.money)
                expect(newState.farm.plots).to.equal(initialState.farm.plots)
            end)
            
            it("should handle watering non-existent plant", function()
                local action = {
                    type = "WATER_PLANT",
                    plotId = 999 -- Non-existent plot
                }
                
                local newState = GameReducer(initialState, action)
                
                -- State should remain unchanged
                expect(newState.farm.plots).to.equal(initialState.farm.plots)
            end)
        end)
    end)
end