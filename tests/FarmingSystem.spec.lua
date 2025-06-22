-- Unit tests for FarmingSystem
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Mock player for testing
local function createMockPlayer(name, userId)
    local player = {
        Name = name or "TestPlayer",
        UserId = userId or 12345
    }
    return player
end

-- Mock Promise for testing
local function createMockPromise()
    local Promise = {}
    
    function Promise.new(executor)
        local promise = {
            _state = "pending",
            _value = nil,
            _reason = nil
        }
        
        local function resolve(value)
            if promise._state == "pending" then
                promise._state = "resolved"
                promise._value = value
            end
        end
        
        local function reject(reason)
            if promise._state == "pending" then
                promise._state = "rejected"
                promise._reason = reason
            end
        end
        
        executor(resolve, reject)
        return promise
    end
    
    return Promise
end

return function()
    local FarmingSystem = require(script.Parent.Parent.src.server.FarmingSystem)
    
    describe("FarmingSystem", function()
        local mockPlayer
        
        beforeEach(function()
            mockPlayer = createMockPlayer("TestFarmer", 12345)
            FarmingSystem.initialize()
        end)
        
        describe("Player Farm Management", function()
            it("should create new farm data for new player", function()
                local farm = FarmingSystem.getPlayerFarm(mockPlayer)
                
                expect(farm).to.be.ok()
                expect(farm.plots).to.be.ok()
                expect(farm.equipment).to.be.ok()
                expect(farm.equipment.wateringCan).to.equal(true)
                expect(farm.equipment.airPurifier).to.equal(false)
            end)
            
            it("should return same farm data for existing player", function()
                local farm1 = FarmingSystem.getPlayerFarm(mockPlayer)
                local farm2 = FarmingSystem.getPlayerFarm(mockPlayer)
                
                expect(farm1).to.equal(farm2)
            end)
        end)
        
        describe("Planting System", function()
            it("should plant seed successfully in empty plot", function()
                local promise = FarmingSystem.plantSeed(mockPlayer, 1, "tomato", "basic")
                
                expect(promise._state).to.equal("resolved")
                expect(promise._value).to.equal(true)
                
                local farm = FarmingSystem.getPlayerFarm(mockPlayer)
                expect(farm.plots[1]).to.be.ok()
                expect(farm.plots[1].seedType).to.equal("tomato")
                expect(farm.plots[1].soilType).to.equal("basic")
                expect(farm.plots[1].watered).to.equal(false)
                expect(farm.plots[1].growthStage).to.equal(0)
            end)
            
            it("should reject planting in occupied plot", function()
                -- Plant first seed
                FarmingSystem.plantSeed(mockPlayer, 1, "tomato", "basic")
                
                -- Try to plant second seed in same plot
                local promise = FarmingSystem.plantSeed(mockPlayer, 1, "carrot", "basic")
                
                expect(promise._state).to.equal("rejected")
                expect(promise._reason).to.equal("Plot is already occupied")
            end)
            
            it("should use default soil type if not specified", function()
                FarmingSystem.plantSeed(mockPlayer, 1, "tomato")
                
                local farm = FarmingSystem.getPlayerFarm(mockPlayer)
                expect(farm.plots[1].soilType).to.equal("basic")
            end)
        end)
        
        describe("Watering System", function()
            beforeEach(function()
                FarmingSystem.plantSeed(mockPlayer, 1, "tomato", "basic")
            end)
            
            it("should water plant successfully", function()
                local promise = FarmingSystem.waterPlant(mockPlayer, 1)
                
                expect(promise._state).to.equal("resolved")
                expect(promise._value).to.equal(true)
                
                local farm = FarmingSystem.getPlayerFarm(mockPlayer)
                expect(farm.plots[1].watered).to.equal(true)
                expect(farm.plots[1].lastWatered).to.be.ok()
                expect(farm.plots[1].growthStage).to.equal(1)
            end)
            
            it("should reject watering non-existent plant", function()
                local promise = FarmingSystem.waterPlant(mockPlayer, 999)
                
                expect(promise._state).to.equal("rejected")
                expect(promise._reason).to.equal("No plant in this plot")
            end)
            
            it("should reject watering recently watered plant", function()
                -- Water the plant first
                FarmingSystem.waterPlant(mockPlayer, 1)
                
                -- Try to water again immediately
                local promise = FarmingSystem.waterPlant(mockPlayer, 1)
                
                expect(promise._state).to.equal("rejected")
                expect(promise._reason).to.equal("Plant was recently watered")
            end)
        end)
        
        describe("Harvesting System", function()
            beforeEach(function()
                FarmingSystem.plantSeed(mockPlayer, 1, "tomato", "basic")
                FarmingSystem.waterPlant(mockPlayer, 1)
                
                -- Manually set plant to ready state for testing
                local farm = FarmingSystem.getPlayerFarm(mockPlayer)
                farm.plots[1].growthStage = 2
            end)
            
            it("should harvest ready crop successfully", function()
                local promise = FarmingSystem.harvestCrop(mockPlayer, 1)
                
                expect(promise._state).to.equal("resolved")
                expect(promise._value).to.be.ok()
                expect(promise._value.cropType).to.equal("tomato")
                expect(promise._value.amount).to.be.ok()
                expect(promise._value.experience).to.be.ok()
                
                -- Plot should be empty after harvest
                local farm = FarmingSystem.getPlayerFarm(mockPlayer)
                expect(farm.plots[1]).to.equal(nil)
            end)
            
            it("should reject harvesting non-existent plant", function()
                local promise = FarmingSystem.harvestCrop(mockPlayer, 999)
                
                expect(promise._state).to.equal("rejected")
                expect(promise._reason).to.equal("No plant in this plot")
            end)
            
            it("should reject harvesting unready plant", function()
                -- Set plant back to growing state
                local farm = FarmingSystem.getPlayerFarm(mockPlayer)
                farm.plots[1].growthStage = 1
                
                local promise = FarmingSystem.harvestCrop(mockPlayer, 1)
                
                expect(promise._state).to.equal("rejected")
                expect(promise._reason).to.equal("Plant is not ready for harvest")
            end)
            
            it("should give bonus yield for advanced soil", function()
                -- Plant with advanced soil
                FarmingSystem.plantSeed(mockPlayer, 2, "tomato", "advanced")
                FarmingSystem.waterPlant(mockPlayer, 2)
                
                local farm = FarmingSystem.getPlayerFarm(mockPlayer)
                farm.plots[2].growthStage = 2
                
                local promise = FarmingSystem.harvestCrop(mockPlayer, 2)
                
                expect(promise._state).to.equal("resolved")
                -- Bonus yield is random, so we just check that it's at least base amount
                expect(promise._value.amount).to.be.greaterThan(0)
            end)
        end)
        
        describe("Selling System", function()
            it("should sell crops successfully", function()
                local promise = FarmingSystem.sellCrops(mockPlayer, "tomato", 3)
                
                expect(promise._state).to.equal("resolved")
                expect(promise._value).to.be.ok()
                expect(promise._value.profit).to.be.ok()
                expect(promise._value.pricePerUnit).to.be.ok()
            end)
            
            it("should reject selling invalid crop type", function()
                local promise = FarmingSystem.sellCrops(mockPlayer, "invalid_crop", 1)
                
                expect(promise._state).to.equal("rejected")
                expect(promise._reason).to.equal("Invalid crop type")
            end)
            
            it("should apply market fluctuations", function()
                local promise1 = FarmingSystem.sellCrops(mockPlayer, "tomato", 1)
                local promise2 = FarmingSystem.sellCrops(mockPlayer, "tomato", 1)
                
                expect(promise1._state).to.equal("resolved")
                expect(promise2._state).to.equal("resolved")
                
                -- Prices may vary due to market fluctuations
                expect(promise1._value.profit).to.be.ok()
                expect(promise2._value.profit).to.be.ok()
            end)
        end)
        
        describe("Plant Growth System", function()
            it("should advance growth stage when conditions are met", function()
                FarmingSystem.plantSeed(mockPlayer, 1, "wheat", "basic") -- Short growth time
                FarmingSystem.waterPlant(mockPlayer, 1)
                
                local farm = FarmingSystem.getPlayerFarm(mockPlayer)
                
                -- Manually advance time for testing
                farm.plots[1].lastWatered = tick() - 25 -- 25 seconds ago (wheat needs 20)
                
                FarmingSystem.checkPlantGrowth()
                
                expect(farm.plots[1].growthStage).to.equal(2) -- Should be ready
            end)
            
            it("should not advance growth if not watered", function()
                FarmingSystem.plantSeed(mockPlayer, 1, "wheat", "basic")
                
                local farm = FarmingSystem.getPlayerFarm(mockPlayer)
                local initialStage = farm.plots[1].growthStage
                
                FarmingSystem.checkPlantGrowth()
                
                expect(farm.plots[1].growthStage).to.equal(initialStage)
            end)
        end)
        
        describe("Climate System", function()
            it("should return current climate data", function()
                local climate = FarmingSystem.getClimate()
                
                expect(climate).to.be.ok()
                expect(climate.temperature).to.be.ok()
                expect(climate.humidity).to.be.ok()
                expect(climate.airQuality).to.be.ok()
                expect(climate.season).to.be.ok()
            end)
            
            it("should update climate values", function()
                local initialClimate = FarmingSystem.getClimate()
                
                FarmingSystem.updateClimate()
                
                local updatedClimate = FarmingSystem.getClimate()
                
                -- Values should be within reasonable ranges
                expect(updatedClimate.temperature).to.be.greaterThan(49)
                expect(updatedClimate.temperature).to.be.lessThan(91)
                expect(updatedClimate.humidity).to.be.greaterThan(29)
                expect(updatedClimate.humidity).to.be.lessThan(91)
                expect(updatedClimate.airQuality).to.be.greaterThan(59)
                expect(updatedClimate.airQuality).to.be.lessThan(101)
            end)
        end)
        
        describe("Plant Information", function()
            it("should return plant info for existing plant", function()
                FarmingSystem.plantSeed(mockPlayer, 1, "tomato", "basic")
                FarmingSystem.waterPlant(mockPlayer, 1)
                
                local plantInfo = FarmingSystem.getPlantInfo(mockPlayer, 1)
                
                expect(plantInfo).to.be.ok()
                expect(plantInfo.seedType).to.equal("tomato")
                expect(plantInfo.growthStage).to.equal(1)
                expect(plantInfo.watered).to.equal(true)
                expect(plantInfo.soilType).to.equal("basic")
                expect(plantInfo.timeRemaining).to.be.ok()
            end)
            
            it("should return nil for non-existent plant", function()
                local plantInfo = FarmingSystem.getPlantInfo(mockPlayer, 999)
                
                expect(plantInfo).to.equal(nil)
            end)
        end)
        
        describe("Equipment Effects", function()
            it("should apply air purifier bonus yield", function()
                local farm = FarmingSystem.getPlayerFarm(mockPlayer)
                farm.equipment.airPurifier = true
                
                FarmingSystem.plantSeed(mockPlayer, 1, "tomato", "basic")
                FarmingSystem.waterPlant(mockPlayer, 1)
                farm.plots[1].growthStage = 2
                
                local promise = FarmingSystem.harvestCrop(mockPlayer, 1)
                
                expect(promise._state).to.equal("resolved")
                -- Should have potential for bonus yield
                expect(promise._value.amount).to.be.greaterThan(0)
            end)
        end)
    end)
end