-- Plot Management Module
-- Handles all plot states, plant lifecycle, watering, and growth monitoring

local ConfigManager = require(script.Parent.ConfigManager)
local PlayerDataManager = require(script.Parent.PlayerDataManager)
local Logger = require(script.Parent.Logger)
local GameConfig = require(script.Parent.GameConfig) -- Temporary import for features not yet migrated

-- Import RemoteManager for client updates (lazy loaded to avoid circular dependency)
local RemoteManager = nil

-- Get module logger
local log = Logger.getModuleLogger("PlotManager")

local PlotManager = {}

-- Storage
local plotStates = {} -- [plotId] = { state, seedType, plantedTime, etc. }

-- Helper function to save plot state to player data
local function savePlotToPlayerData(plotId)
    local plotState = plotStates[plotId]
    if not plotState or not plotState.ownerId then return end
    
    local Players = game:GetService("Players")
    local player = Players:GetPlayerByUserId(plotState.ownerId)
    if not player then return end
    
    local FarmManager = require(script.Parent.FarmManager)
    local farmId, plotIndex = FarmManager.getFarmAndPlotFromGlobalId(plotId)
    
    -- Use ProfileStore-powered PlayerDataManager to save plot state
    PlayerDataManager.savePlotState(player, plotIndex, plotState)
end

-- Helper function to send plot updates to clients
local function sendPlotUpdate(plotId, additionalData)
    -- Save plot state to player data whenever it changes
    savePlotToPlayerData(plotId)
    
    -- Lazy load RemoteManager to avoid circular dependency
    if not RemoteManager then
        RemoteManager = require(script.Parent.RemoteManager)
    end
    
    local plotState = plotStates[plotId]
    if plotState and RemoteManager.sendPlotUpdate then
        RemoteManager.sendPlotUpdate(plotId, plotState, additionalData)
    end
end

-- Initialize plot state (loads from player data if available)
function PlotManager.initializePlot(plotId, ownerId, playerObject)
    -- Try to load existing plot state from player data (only if we have an owner)
    local savedPlotState = nil
    if ownerId and playerObject then
        local FarmManager = require(script.Parent.FarmManager)
        local farmId, plotIndex = FarmManager.getFarmAndPlotFromGlobalId(plotId)
        
        -- Use the passed player object directly
        savedPlotState = PlayerDataManager.getPlotState(playerObject, plotIndex)
        
        if savedPlotState then
            log.info("Loading saved plot state for player", playerObject.Name, "plot", plotIndex, "state:", savedPlotState.state)
            
            -- Ensure all required fields exist (migration for old save data)
            if not savedPlotState.lastReadyTime then
                savedPlotState.lastReadyTime = 0
            end
            if not savedPlotState.accumulatedCrops then
                savedPlotState.accumulatedCrops = 0
            end
            if not savedPlotState.baseYieldRate then
                savedPlotState.baseYieldRate = 1
            end
            
            -- Process offline growth
            savedPlotState = PlotManager.processOfflineGrowth(savedPlotState, playerObject)
        else
            log.debug("No saved state for player", playerObject.Name, "plot", plotIndex)
        end
    elseif ownerId and not playerObject then
        -- Fallback to the old method if no player object passed
        local Players = game:GetService("Players")
        local player = Players:GetPlayerByUserId(ownerId)
        
        if player then
            local FarmManager = require(script.Parent.FarmManager)
            local farmId, plotIndex = FarmManager.getFarmAndPlotFromGlobalId(plotId)
            savedPlotState = PlayerDataManager.getPlotState(player, plotIndex)
            
            if savedPlotState then
                log.info("Loading saved plot state for player", player.Name, "plot", plotIndex, "state:", savedPlotState.state)
                
                -- Ensure all required fields exist (migration for old save data)
                if not savedPlotState.lastReadyTime then
                    savedPlotState.lastReadyTime = 0
                end
                if not savedPlotState.accumulatedCrops then
                    savedPlotState.accumulatedCrops = 0
                end
                if not savedPlotState.baseYieldRate then
                    savedPlotState.baseYieldRate = 1
                end
            end
        else
            log.warn("Could not find player for userId", ownerId, "when loading plot", plotId)
        end
    end
    
    -- Use saved state or create new empty plot
    plotStates[plotId] = savedPlotState or {
        state = "empty",
        seedType = "",
        plantedTime = 0,
        wateredTime = 0,
        lastWateredTime = 0,
        wateredCount = 0,
        waterNeeded = 0,
        ownerId = ownerId or nil,
        harvestCount = 0, -- Track how many times this plant has been harvested
        maxHarvests = 0,  -- Max harvests for this specific plant (set when planted)
        needsReplanting = false, -- Flag for when plant needs to be replanted
        accumulatedCrops = 0, -- Crops generated over time (max 100)
        lastReadyTime = 0, -- When the plant first became ready
        baseYieldRate = 1 -- How many crops per harvest cycle
    }
    
    -- Ensure ownerId is set correctly (in case it changed)
    plotStates[plotId].ownerId = ownerId
end

-- Reset plot state (for when players leave)
function PlotManager.resetPlot(plotId)
    local plotState = plotStates[plotId]
    if plotState then
        -- Clear ownership and reset to empty state
        plotStates[plotId] = {
            state = "empty",
            seedType = "",
            plantedTime = 0,
            wateredTime = 0,
            lastWateredTime = 0,
            wateredCount = 0,
            waterNeeded = 0,
            ownerId = nil
        }
        
        -- Update visual state in the world
        local WorldBuilder = require(script.Parent.Parent.WorldBuilder)
        local plot = WorldBuilder.getPlotById(plotId)
        if plot then
            WorldBuilder.updatePlotState(plot, "empty", "")
        end
        
        -- Send update to all clients
        sendPlotUpdate(plotId)
    end
end

-- Get plot state
function PlotManager.getPlotState(plotId)
    return plotStates[plotId]
end

-- Check if plot is unlocked for player
local function isPlotUnlocked(player, plotId)
    local FarmManager = require(script.Parent.FarmManager)
    local farmId, plotIndex = FarmManager.getFarmAndPlotFromGlobalId(plotId)
    
    -- Check if player owns the farm
    if not FarmManager.doesPlayerOwnPlot(player.UserId, plotId) then
        return false
    end
    
    -- Check if plot is within unlocked range using new rebirth system
    if plotIndex <= 10 then
        return true -- First 10 plots are always unlocked
    end
    
    -- For plots 11+, check if they're available for purchase based on rebirth level
    return PlayerDataManager.isPlotAvailableForPurchase(player, plotIndex)
end

-- Plant crop on plot
function PlotManager.plantCrop(player, plotId, cropType, quantity)
    local plotState = plotStates[plotId]
    local playerData = PlayerDataManager.getPlayerData(player)
    quantity = quantity or 1 -- Default to 1 if not specified
    
    if not plotState or not playerData then 
        return false, "Invalid plot or player data"
    end
    
    -- Validate cropType parameter
    if not cropType then
        log.error("PlotManager.plantCrop called with nil cropType for player", player.Name, "plot", plotId)
        return false, "No crop type specified"
    end
    
    -- Validate quantity
    if quantity <= 0 or quantity > 50 then
        return false, "Invalid quantity! Must be between 1 and 50."
    end
    
    -- Validate plot ownership with FarmManager
    local FarmManager = require(script.Parent.FarmManager)
    if not FarmManager.doesPlayerOwnPlot(player.UserId, plotId) then
        return false, "This plot doesn't belong to you!"
    end
    
    -- Check if plot is unlocked
    if not isPlotUnlocked(player, plotId) then
        return false, "This plot is locked! Purchase more plots to unlock it."
    end
    
    -- Check for dead crops first
    if plotState.state == "dead" then
        return false, "Clear the dead crop first before planting new ones!"
    end
    
    -- Allow stacking: Either empty plot OR same crop type for stacking
    if plotState.state ~= "empty" then
        if plotState.seedType ~= cropType then
            return false, "Different crop already planted! Clear it first or plant the same type to stack."
        end
        -- Same crop type - check stacking limit with new quantity
        local currentPlants = plotState.maxHarvests - plotState.harvestCount
        if currentPlants + quantity > 50 then
            local available = 50 - currentPlants
            return false, "Can only plant " .. available .. " more crops! (Max 50 per plot)"
        end
    end
    
    -- Check if crop type exists in config
    local cropData = ConfigManager.getCrop(cropType)
    if not cropData then
        return false, "Unknown crop type: " .. cropType
    end
    
    -- Check player has enough crops for the quantity
    local cropCount = PlayerDataManager.getInventoryCount(player, "crops", cropType)
    if cropCount < quantity then
        return false, "You only have " .. cropCount .. " " .. cropType .. " crops! Need " .. quantity .. "."
    end
    
    local currentTime = tick()
    local isStacking = plotState.state ~= "empty"
    
    if isStacking then
        -- Stacking: Add plants (1 crop = 1 plant, regardless of harvests per plant)
        local baseMaxHarvests = cropData.maxHarvests
        local randomFactors = GameConfig.Replanting.randomFactors
        
        -- Simply add quantity to maxHarvests (1 crop planted = 1 additional plant/harvest)
        plotState.maxHarvests = plotState.maxHarvests + quantity
        log.debug("Stacked", quantity, cropType, "plants. Total plants:", plotState.maxHarvests - plotState.harvestCount)
        
        -- Remove crops from inventory (use quantity parameter)
        PlayerDataManager.removeFromInventory(player, "crops", cropType, quantity)
        
        -- Send update
        sendPlotUpdate(plotId)
        
        local totalPlants = plotState.maxHarvests - plotState.harvestCount
        return true, "Stacked " .. quantity .. " " .. cropType .. "! Total: " .. totalPlants .. " plants in this plot."
    else
        -- First plant: Set up the plot normally
        local variation = PlotManager.rollCropVariation()
        
        plotState.state = "planted"
        plotState.seedType = cropType
        plotState.plantedTime = currentTime
        plotState.plantedAt = currentTime
        plotState.ownerId = player.UserId
        plotState.wateredCount = 0
        plotState.waterNeeded = cropData.waterNeeded
        plotState.lastWateredTime = 0
        plotState.lastWateredAt = 0
        plotState.variation = variation
        plotState.harvestCooldown = 0
        plotState.growthTime = ConfigManager.getGrowthTimeFromRate(cropType)
        plotState.waterTime = cropData.waterCooldown
        plotState.deathTime = ConfigManager.getTimingConfig().plantDeathTime
        
        -- Set up initial harvests (1 crop planted = 1 plant = 1 harvest opportunity)
        plotState.harvestCount = 0
        plotState.maxHarvests = quantity  -- Simply set to quantity planted
        plotState.needsReplanting = false
        
        -- Remove crops from inventory (use quantity parameter)
        PlayerDataManager.removeFromInventory(player, "crops", cropType, quantity)
        
        -- Send plot update
        sendPlotUpdate(plotId, {plantedAt = currentTime})
        
        return true, "Planted " .. quantity .. " " .. cropType .. "! Now water them."
    end
end

-- Water plant on plot
function PlotManager.waterPlant(player, plotId)
    local plotState = plotStates[plotId]
    
    if not plotState then 
        return false, "Invalid plot"
    end
    
    -- Validate plot ownership with FarmManager
    local FarmManager = require(script.Parent.FarmManager)
    if not FarmManager.doesPlayerOwnPlot(player.UserId, plotId) then
        return false, "This plot doesn't belong to you!"
    end
    
    -- Check if plot is unlocked
    if not isPlotUnlocked(player, plotId) then
        return false, "This plot is locked! Purchase more plots to unlock it."
    end
    
    -- Validate plot has planted seed and needs water
    if plotState.state ~= "planted" and plotState.state ~= "growing" then
        return false, "Nothing to water here!"
    end
    
    -- Check if already fully watered
    if plotState.wateredCount >= plotState.waterNeeded then
        return false, "Plant doesn't need more water!"
    end
    
    -- Check watering cooldown
    local timeSinceLastWater = tick() - plotState.lastWateredTime
    if plotState.wateredCount > 0 and timeSinceLastWater < GameConfig.Settings.waterCooldown then
        local timeLeft = math.ceil(GameConfig.Settings.waterCooldown - timeSinceLastWater)
        return false, "Wait " .. timeLeft .. " seconds before watering again!"
    end
    
    -- Add water
    local currentTime = tick()
    plotState.wateredCount = plotState.wateredCount + 1
    plotState.lastWateredTime = currentTime
    plotState.lastWateredAt = currentTime -- For client prediction
    
    local waterProgress = plotState.wateredCount .. "/" .. plotState.waterNeeded
    
    if plotState.wateredCount >= plotState.waterNeeded then
        -- Fully watered - start growing
        plotState.state = "watered"
        plotState.wateredTime = currentTime
        
        -- Send plot update to clients (also saves to player data)
        sendPlotUpdate(plotId, {wateredAt = currentTime, triggerRainEffect = true})
        
        return true, "Plant fully watered (" .. waterProgress .. ")! Growing now..."
    else
        -- Partially watered
        plotState.state = "growing"
        
        -- Send plot update to clients (also saves to player data)
        sendPlotUpdate(plotId, {wateredAt = currentTime, triggerRainEffect = true})
        
        return true, "Plant watered (" .. waterProgress .. "). Needs more water!"
    end
end

-- Harvest crop from plot (permanent crops)
function PlotManager.harvestCrop(player, plotId)
    local plotState = plotStates[plotId]
    local playerData = PlayerDataManager.getPlayerData(player)
    
    if not plotState or not playerData then 
        return false, "Invalid plot or player data"
    end
    
    -- Validate plot is ready and owned by player
    if plotState.state ~= "ready" then
        return false, "Crop is not ready yet!"
    end
    
    -- Validate plot ownership with FarmManager
    local FarmManager = require(script.Parent.FarmManager)
    if not FarmManager.doesPlayerOwnPlot(player.UserId, plotId) then
        return false, "This plot doesn't belong to you!"
    end
    
    -- Check if plot is unlocked
    if not isPlotUnlocked(player, plotId) then
        return false, "This plot is locked! Purchase more plots to unlock it."
    end
    
    -- Check harvest cooldown
    local harvestCooldown = GameConfig.Plants[plotState.seedType].harvestCooldown or 30
    if tick() - plotState.harvestCooldown < harvestCooldown then
        local timeLeft = math.ceil(harvestCooldown - (tick() - plotState.harvestCooldown))
        return false, "Harvest again in " .. timeLeft .. " seconds!"
    end
    
    local seedType = plotState.seedType
    local variation = plotState.variation or "normal"
    
    -- Update accumulated crops before harvesting
    PlotManager.updateCropAccumulation(plotId, plotState)
    
    -- Harvest ALL ready crops at once
    local totalYield = math.max(1, plotState.accumulatedCrops or 1)
    local variationMultiplier = GameConfig.CropVariations[variation].multiplier or 1
    totalYield = math.floor(totalYield * variationMultiplier)
    
    -- Add crops to inventory with variation prefix
    local cropName = seedType
    if variation ~= "normal" then
        cropName = GameConfig.CropVariations[variation].prefix .. seedType
    end
    
    PlayerDataManager.addToInventory(player, "crops", cropName, totalYield)
    
    -- Reset accumulation after harvesting all ready crops
    plotState.accumulatedCrops = 0
    plotState.lastReadyTime = 0 -- Reset for next cycle
    
    -- Harvest only the ready crop (1 at a time from the queue)
    plotState.harvestCount = plotState.harvestCount + 1
    plotState.harvestCooldown = tick()
    
    -- Check if plant needs replanting
    if plotState.harvestCount >= plotState.maxHarvests then
        -- Plant has reached its harvest limit, needs replanting
        plotState.state = "empty"
        plotState.seedType = ""
        plotState.plantedTime = 0
        plotState.wateredTime = 0
        plotState.lastWateredTime = 0
        plotState.wateredCount = 0
        plotState.waterNeeded = 0
        plotState.harvestCount = 0
        plotState.maxHarvests = 0
        plotState.needsReplanting = false
        
        sendPlotUpdate(plotId)
        
        local message = "Harvested " .. totalYield .. " " .. cropName .. "! All plants harvested, plot cleared."
        if variation ~= "normal" then
            message = message .. " (" .. (variationMultiplier) .. "x bonus!)"
        end
        
        return true, message
    else
        -- For queue system, always go directly to watered state for next plant
        plotState.state = "watered"
        plotState.wateredTime = tick()
        plotState.lastWateredTime = tick() -- Reset growth timer for next plant
        plotState.wateredCount = plotState.waterNeeded -- Mark as fully watered
        
        sendPlotUpdate(plotId, {lastWateredAt = plotState.wateredTime})
        
        local harvestsLeft = plotState.maxHarvests - plotState.harvestCount
        local message = "Harvested " .. totalYield .. " " .. cropName .. "! " .. harvestsLeft .. " plants in queue, next growing."
        if variation ~= "normal" then
            message = message .. " (" .. (variationMultiplier) .. "x bonus!)"
        end
        
        return true, message
    end
end

-- Harvest ALL crops from plot at once (for stacked plants)
function PlotManager.harvestAllCrops(player, plotId)
    local plotState = plotStates[plotId]
    local playerData = PlayerDataManager.getPlayerData(player)
    
    if not plotState or not playerData then 
        return false, "Invalid plot or player data"
    end
    
    -- Validate plot is ready and owned by player
    if plotState.state ~= "ready" then
        return false, "Crop is not ready yet!"
    end
    
    -- Validate plot ownership with FarmManager
    local FarmManager = require(script.Parent.FarmManager)
    if not FarmManager.doesPlayerOwnPlot(player.UserId, plotId) then
        return false, "This plot doesn't belong to you!"
    end
    
    -- Check if plot is unlocked
    if not isPlotUnlocked(player, plotId) then
        return false, "This plot is locked! Purchase more plots to unlock it."
    end
    
    local seedType = plotState.seedType
    local variation = plotState.variation or "normal"
    local harvestsLeft = plotState.maxHarvests - plotState.harvestCount
    
    -- Update accumulated crops before harvesting
    PlotManager.updateCropAccumulation(plotId, plotState)
    
    -- Harvest ALL accumulated crops
    local totalYield = math.max(harvestsLeft, plotState.accumulatedCrops or harvestsLeft)
    local variationMultiplier = GameConfig.CropVariations[variation].multiplier or 1
    totalYield = math.floor(totalYield * variationMultiplier)
    
    -- Add crops to inventory with variation prefix
    local cropName = seedType
    if variation ~= "normal" then
        cropName = GameConfig.CropVariations[variation].prefix .. seedType
    end
    
    PlayerDataManager.addToInventory(player, "crops", cropName, totalYield)
    
    -- Clear all accumulated crops and harvest all plants
    plotState.accumulatedCrops = 0
    plotState.lastReadyTime = 0
    plotState.harvestCount = plotState.maxHarvests -- Harvest all remaining
    
    -- Plant has reached its harvest limit, needs replanting
    plotState.state = "empty"
    plotState.seedType = ""
    plotState.plantedTime = 0
    plotState.wateredTime = 0
    plotState.lastWateredTime = 0
    plotState.wateredCount = 0
    plotState.waterNeeded = 0
    plotState.harvestCount = 0
    plotState.maxHarvests = 0
    plotState.needsReplanting = false
    
    sendPlotUpdate(plotId)
    
    local message = "Harvested ALL " .. totalYield .. " " .. cropName .. "! Plot needs replanting."
    if variation ~= "normal" then
        message = message .. " (" .. variationMultiplier .. "x bonus!)"
    end
    
    return true, message
end

-- Cut/remove a plant from a plot (gives crop if ready, nothing if not)
function PlotManager.cutPlant(player, plotId)
    local plotState = plotStates[plotId]
    local playerData = PlayerDataManager.getPlayerData(player)
    
    if not plotState or not playerData then 
        return false, "Invalid plot or player data"
    end
    
    -- Validate plot has something to cut
    if plotState.state == "empty" then
        return false, "Nothing to cut on this plot!"
    end
    
    -- Validate plot ownership with FarmManager
    local FarmManager = require(script.Parent.FarmManager)
    if not FarmManager.doesPlayerOwnPlot(player.UserId, plotId) then
        return false, "This plot doesn't belong to you!"
    end
    
    -- Check if plot is unlocked
    if not isPlotUnlocked(player, plotId) then
        return false, "This plot is locked! Purchase more plots to unlock it."
    end
    
    local seedType = plotState.seedType
    local wasReady = plotState.state == "ready"
    local message = ""
    
    if wasReady then
        -- Plant was ready - give the player one crop
        local cropName = GameConfig.Plants[seedType].name or seedType
        local plantConfig = GameConfig.Plants[seedType]
        local sellPrice = plantConfig.sellPrice or 1
        
        -- Add crop to player's money (sell immediately)
        playerData.money = playerData.money + sellPrice
        playerData.totalEarnings = (playerData.totalEarnings or 0) + sellPrice
        
        message = "Cut " .. cropName .. " and sold for $" .. sellPrice .. "!"
    else
        -- Plant wasn't ready - no reward
        local cropName = GameConfig.Plants[seedType].name or seedType
        message = "Cut down the " .. cropName .. " plant (no reward - wasn't ready yet)"
    end
    
    -- Reset plot to empty state
    plotState.state = "empty"
    plotState.seedType = ""
    plotState.plantedTime = 0
    plotState.wateredTime = 0
    plotState.wateredCount = 0
    plotState.waterNeeded = 0
    plotState.lastWateredTime = 0
    plotState.harvestCount = 0
    plotState.maxHarvests = 0
    plotState.variation = "normal"
    
    -- Send plot update to clients
    sendPlotUpdate(plotId, {cutAt = tick()})
    
    return true, message
end

-- Reset plot to empty state
function PlotManager.resetPlot(plotId)
    local plotState = plotStates[plotId]
    if plotState then
        local ownerId = plotState.ownerId -- Remember owner before reset
        
        plotState.state = "empty"
        plotState.seedType = ""
        plotState.plantedTime = 0
        plotState.wateredTime = 0
        plotState.lastWateredTime = 0
        plotState.wateredCount = 0
        plotState.waterNeeded = 0
        plotState.harvestCount = 0
        plotState.maxHarvests = 0
        plotState.needsReplanting = false
        plotState.variation = nil
        plotState.harvestCooldown = 0
        plotState.growthTime = 0
        plotState.waterTime = 0
        plotState.deathTime = 0
        plotState.plantedAt = 0
        plotState.lastWateredAt = 0
        plotState.deathReason = nil
        
        -- Only clear ownerId if this is called during farm unassignment
        -- (not during normal plot clearing by the owner)
        if not ownerId then
            plotState.ownerId = nil
        end
        
        -- Save the reset state to player data
        if ownerId then
            savePlotToPlayerData(plotId)
        end
    end
end

-- Kill a plant (death mechanism)
function PlotManager.killPlant(plotId, reason)
    local plotState = plotStates[plotId]
    if not plotState then return false end
    
    local seedType = plotState.seedType
    local ownerId = plotState.ownerId
    
    -- Set plot to dead state instead of resetting immediately
    plotState.state = "dead"
    plotState.deathReason = reason
    plotState.deathTime = tick()
    
    -- Send plot update to clients
    sendPlotUpdate(plotId)
    
    return true, {
        seedType = seedType,
        ownerId = ownerId,
        reason = reason
    }
end

-- Clear a dead plant (player acknowledgment)
function PlotManager.clearDeadPlant(player, plotId)
    local plotState = plotStates[plotId]
    if not plotState then 
        return false, "Plot not found"
    end
    
    if plotState.state ~= "dead" then
        return false, "Plant is not dead"
    end
    
    -- Verify ownership
    if plotState.ownerId and plotState.ownerId ~= player.UserId then
        return false, "This is not your plot"
    end
    
    local seedType = plotState.seedType
    local deathReason = plotState.deathReason or "unknown"
    
    -- Reset plot to empty state
    PlotManager.resetPlot(plotId)
    
    -- Manually update visual state in the world (since the resetPlot function might not do it)
    local WorldBuilder = require(script.Parent.Parent.WorldBuilder)
    local plot = WorldBuilder.getPlotById(plotId)
    if plot then
        WorldBuilder.updatePlotState(plot, "empty", "", "normal", 0, nil, nil, nil)
        log.debug("Updated plot visual state to empty for plot", plotId)
    else
        log.warn("Could not find plot in world for visual update:", plotId)
    end
    
    -- Send plot update to clients
    sendPlotUpdate(plotId)
    
    log.debug("Player", player.Name, "cleared dead", seedType, "from plot", plotId, "- reason:", deathReason)
    
    return true, "Cleared dead " .. seedType .. " plant"
end

-- Get all plots in specific state
function PlotManager.getPlotsInState(state, ownerId)
    local plots = {}
    for plotId, plotState in pairs(plotStates) do
        if plotState.state == state then
            if not ownerId or plotState.ownerId == ownerId then
                table.insert(plots, {
                    plotId = plotId,
                    plotState = plotState
                })
            end
        end
    end
    return plots
end

-- Update growth monitoring (called by main loop)
function PlotManager.updateGrowthMonitoring()
    for plotId, plotState in pairs(plotStates) do
        -- Check for plant death (not watered in time)
        if plotState.state == "planted" or plotState.state == "growing" then
            local deathTime = GameConfig.Plants[plotState.seedType].deathTime
            local timeSincePlanted = tick() - plotState.plantedTime
            
            if timeSincePlanted >= deathTime then
                local success, deathInfo = PlotManager.killPlant(plotId, "Not watered in time")
                if success then
                    -- Will be handled by notification system
                    return "plant_died", {
                        plotId = plotId,
                        deathInfo = deathInfo
                    }
                end
            end
        end
        
        -- Check for plant ready to harvest
        if plotState.state == "watered" then
            local growthTime = GameConfig.Plants[plotState.seedType].growthTime
            local timeSinceWatered = tick() - plotState.wateredTime
            
            -- Apply online speed boost (2x growth when player is online)
            local effectiveGrowthTime = PlotManager.calculateEffectiveGrowthTime(plotState, growthTime)
            
            if timeSinceWatered >= effectiveGrowthTime then
                -- Plant is ready!
                plotState.state = "ready"
                
                -- Initialize accumulation tracking
                if (plotState.lastReadyTime or 0) == 0 then
                    plotState.lastReadyTime = tick()
                    
                    -- Set base yield rate based on crop type
                    local cropData = GameConfig.Plants[plotState.seedType]
                    plotState.baseYieldRate = cropData.baseYield or 1
                    plotState.accumulatedCrops = math.random(plotState.baseYieldRate, plotState.baseYieldRate + 1) -- Start with 1-2 crops
                end
                
                -- Send plot update to clients
                sendPlotUpdate(plotId)
                
                return "plant_ready", {
                    plotId = plotId,
                    seedType = plotState.seedType
                }
            end
        end
        
        -- Update crop accumulation for ready plants
        if plotState.state == "ready" and (plotState.lastReadyTime or 0) > 0 then
            local oldAccumulated = plotState.accumulatedCrops or 0
            PlotManager.updateCropAccumulation(plotId, plotState)
            local newAccumulated = plotState.accumulatedCrops or 0
            if newAccumulated > oldAccumulated then
                log.debug("Plot", plotId, "accumulation increased from", oldAccumulated, "to", newAccumulated)
                -- Send update to client when accumulation changes
                sendPlotUpdate(plotId)
            end
        end
    end
end

-- Update crop accumulation for ready plants
function PlotManager.updateCropAccumulation(plotId, plotState)
    local currentTime = tick()
    local timeSinceReady = currentTime - (plotState.lastReadyTime or currentTime)
    
    -- Get growth time for this crop
    local growthTime = GameConfig.Plants[plotState.seedType].growthTime
    local baseYieldRate = plotState.baseYieldRate or 1
    
    -- Accumulate crops every 30 seconds (much faster than full growth cycle)
    local accumulationInterval = 30 -- seconds
    local accumulationCycles = math.floor(timeSinceReady / accumulationInterval)
    
    if accumulationCycles > 0 then
        -- Add 1 crop every 30 seconds (steady accumulation)
        local newCrops = accumulationCycles * 1
        
        -- Update accumulated crops (capped at 100)
        plotState.accumulatedCrops = math.min(100, (plotState.accumulatedCrops or 0) + newCrops)
        
        -- Update the last ready time to prevent double-counting
        plotState.lastReadyTime = currentTime
        
        -- Save to player data
        savePlotToPlayerData(plotId)
        
        log.debug("Plot", plotId, "accumulated", newCrops, "crops over", timeSinceReady, "seconds, total:", plotState.accumulatedCrops)
    end
end

-- Roll for crop variation when planting
function PlotManager.rollCropVariation()
    -- Always return normal variation for simplicity
    return "normal"
end

-- Get countdown info for display
function PlotManager.getCountdownInfo(plotId)
    local plotState = plotStates[plotId]
    if not plotState then return nil end
    
    local plantName = plotState.seedType:gsub("^%l", string.upper)
    
    if plotState.state == "planted" or plotState.state == "growing" then
        -- Show water requirement countdown with detailed info
        local deathTime = GameConfig.Plants[plotState.seedType].deathTime
        local timeSincePlanted = tick() - plotState.plantedTime
        local timeUntilDeath = deathTime - timeSincePlanted
        
        local waterProgress = plotState.wateredCount .. "/" .. plotState.waterNeeded
        local deathMinutes = math.floor(timeUntilDeath / 60)
        local deathSeconds = math.floor(timeUntilDeath % 60)
        
        local harvestsLeft = plotState.maxHarvests - plotState.harvestCount
        local displayText = "🌱 " .. plantName .. " (Life " .. harvestsLeft .. ")\n💧 Water: " .. waterProgress
        
        -- Show urgency for death time
        if timeUntilDeath > 0 then
            if timeUntilDeath < 60 then
                displayText = displayText .. "\n⚠️ Dies in: " .. math.floor(timeUntilDeath) .. "s"
            else
                displayText = displayText .. "\n⏱️ Dies in: " .. deathMinutes .. ":" .. string.format("%02d", deathSeconds)
            end
        else
            displayText = displayText .. "\n💀 DYING NOW!"
        end
        
        -- Check if there's a watering cooldown
        if plotState.wateredCount > 0 and plotState.wateredCount < plotState.waterNeeded then
            local timeSinceLastWater = tick() - plotState.lastWateredTime
            local cooldownLeft = GameConfig.Settings.waterCooldown - timeSinceLastWater
            
            if cooldownLeft > 0 then
                displayText = displayText .. "\n🚰 Next water: " .. math.ceil(cooldownLeft) .. "s"
            else
                displayText = displayText .. "\n✅ Ready to water!"
            end
        end
        
        local color = Color3.fromRGB(255, 255, 255)
        if timeUntilDeath < 30 then
            color = Color3.fromRGB(255, 100, 100) -- Red for urgent
        elseif timeUntilDeath < 120 then
            color = Color3.fromRGB(255, 200, 100) -- Orange for warning
        end
        
        return {
            text = displayText,
            color = color
        }
        
    elseif plotState.state == "watered" then
        -- Show growth countdown with online boost info
        local growthTime = GameConfig.Plants[plotState.seedType].growthTime
        local timeSinceWatered = tick() - plotState.wateredTime
        local effectiveGrowthTime = PlotManager.calculateEffectiveGrowthTime(plotState, growthTime)
        local timeUntilReady = effectiveGrowthTime - timeSinceWatered
        
        local readyMinutes = math.floor(timeUntilReady / 60)
        local readySeconds = math.floor(timeUntilReady % 60)
        local harvestsLeft = plotState.maxHarvests - plotState.harvestCount
        
        -- Show online vs offline timing
        local offlineTime = growthTime -- Normal offline time
        local onlineTime = effectiveGrowthTime -- Current boosted time
        
        local displayText = "🌿 " .. plantName .. " Growing (Life " .. harvestsLeft .. ")\n⚡ Online 2x Speed"
        
        if timeUntilReady > 0 then
            if timeUntilReady < 60 then
                displayText = displayText .. "\n🎯 Ready in: " .. math.floor(timeUntilReady) .. "s"
            else
                displayText = displayText .. "\n🎯 Ready in: " .. readyMinutes .. ":" .. string.format("%02d", readySeconds)
            end
            
            -- Show offline comparison
            local offlineMinutes = math.floor(offlineTime / 60)
            displayText = displayText .. "\n🐌 Offline: " .. offlineMinutes .. "m"
        else
            displayText = displayText .. "\n✨ READY NOW!"
        end
        
        return {
            text = displayText,
            color = Color3.fromRGB(100, 255, 200) -- Bright green for growing
        }
        
    elseif plotState.state == "ready" then
        -- Show harvest message with accumulated crops info
        PlotManager.updateCropAccumulation(plotId, plotState) -- Update before displaying
        
        local accumulatedCrops = plotState.accumulatedCrops or 1
        local harvestsLeft = plotState.maxHarvests - plotState.harvestCount
        local timeSinceReady = plotState.lastReadyTime > 0 and (tick() - plotState.lastReadyTime) or 0
        local minutesSinceReady = math.floor(timeSinceReady / 60)
        
        local displayText = "🌟 " .. plantName .. " READY! (Life " .. harvestsLeft .. ")\n🎁 Yield: " .. accumulatedCrops .. " crops"
        
        if minutesSinceReady > 0 then
            displayText = displayText .. "\n⏰ Ready for: " .. minutesSinceReady .. "m"
        end
        
        if accumulatedCrops >= 100 then
            displayText = displayText .. "\n🔥 MAX CROPS!"
        elseif accumulatedCrops > 10 then
            displayText = displayText .. "\n📈 High yield!"
        end
        
        return {
            text = displayText,
            color = Color3.fromRGB(255, 255, 100) -- Gold for ready
        }
        
    elseif plotState.state == "dead" then
        -- Show clear dead plant message
        local deathReason = plotState.deathReason or "unknown reason"
        return {
            text = "💀 " .. plantName .. " DIED!\n💔 " .. deathReason .. "\n🗑️ CLICK TO CLEAR",
            color = Color3.fromRGB(255, 50, 50) -- Bright red for dead
        }
        
    else
        -- Empty plot
        return {
            text = "",
            color = Color3.fromRGB(255, 255, 255)
        }
    end
end

-- Clear plot from memory (used when farm is unassigned)
function PlotManager.clearPlotFromMemory(plotId)
    plotStates[plotId] = nil
    log.debug("Cleared plot", plotId, "from memory")
end

-- Process offline growth for saved plot state
function PlotManager.processOfflineGrowth(plotState, player)
    if not plotState or not player then return plotState end
    
    local currentTime = tick()
    local timeOffline = 0
    
    -- Calculate offline time based on the last saved timestamp
    if plotState.lastUpdateTime then
        timeOffline = currentTime - plotState.lastUpdateTime
    end
    
    -- Only process if player was offline for at least 30 seconds
    if timeOffline < 30 then
        plotState.lastUpdateTime = currentTime
        return plotState
    end
    
    log.info("Processing", math.floor(timeOffline/60), "minutes of offline growth for", player.Name)
    
    -- Process different states
    if plotState.state == "watered" then
        -- Check if crop should be ready by now
        local growthTime = GameConfig.Plants[plotState.seedType].growthTime
        local timeSinceWatered = currentTime - plotState.wateredTime
        
        if timeSinceWatered >= growthTime then
            -- Crop is ready!
            plotState.state = "ready"
            log.info("Offline growth: Crop", plotState.seedType, "is now ready for", player.Name)
        end
    elseif plotState.state == "ready" then
        -- For idle mechanics: accumulate crops automatically over time
        local offlineHarvests = PlotManager.calculateOfflineHarvests(plotState, timeOffline)
        
        if offlineHarvests > 0 then
            -- Add offline harvested crops to inventory
            local cropName = plotState.seedType
            if plotState.variation and plotState.variation ~= "normal" then
                cropName = GameConfig.CropVariations[plotState.variation].prefix .. plotState.seedType
            end
            
            PlayerDataManager.addToInventory(player, "crops", cropName, offlineHarvests)
            log.info("Offline harvest:", offlineHarvests, cropName, "added for", player.Name)
            
            -- Update harvest count (but don't exceed max harvests)
            plotState.harvestCount = math.min(plotState.harvestCount + offlineHarvests, plotState.maxHarvests)
            
            -- Check if plant needs replanting
            if plotState.harvestCount >= plotState.maxHarvests then
                plotState.state = "empty"
                plotState.seedType = ""
                plotState.plantedTime = 0
                plotState.wateredTime = 0
                plotState.lastWateredTime = 0
                plotState.wateredCount = 0
                plotState.waterNeeded = 0
                plotState.harvestCount = 0
                plotState.maxHarvests = 0
                plotState.needsReplanting = false
                
                local NotificationManager = require(script.Parent.NotificationManager)
                NotificationManager.sendSuccess(player, "🌾 Offline harvest: " .. offlineHarvests .. " " .. cropName .. "! Plot needs replanting.")
            else
                -- Reset to watered state for continued growth
                plotState.state = "watered"
                plotState.wateredTime = currentTime
                plotState.lastWateredTime = currentTime
                
                local NotificationManager = require(script.Parent.NotificationManager)
                NotificationManager.sendSuccess(player, "🌾 Offline harvest: " .. offlineHarvests .. " " .. cropName .. "! Growing again.")
            end
        end
    elseif plotState.state == "planted" or plotState.state == "growing" then
        -- Check if plant died due to lack of watering
        local deathTime = GameConfig.Plants[plotState.seedType].deathTime
        local timeSincePlanted = currentTime - plotState.plantedTime
        
        if timeSincePlanted >= deathTime then
            -- Plant died while offline
            plotState.state = "dead"
            plotState.deathReason = "Not watered while offline"
            plotState.deathTime = currentTime
            
            local NotificationManager = require(script.Parent.NotificationManager)
            NotificationManager.sendError(player, "💀 " .. plotState.seedType .. " died while you were away! Clear to replant.")
        end
    end
    
    -- Update last update time
    plotState.lastUpdateTime = currentTime
    
    return plotState
end

-- Calculate how many crops a ready plant should have produced offline
function PlotManager.calculateOfflineHarvests(plotState, timeOffline)
    if not plotState or plotState.state ~= "ready" then return 0 end
    
    -- Base harvest rate: 1 harvest per growth time (offline rate)
    local growthTime = GameConfig.Plants[plotState.seedType].growthTime
    local maxOfflineHarvests = math.floor(timeOffline / growthTime)
    
    -- Limit by remaining harvest count
    local remainingHarvests = plotState.maxHarvests - plotState.harvestCount
    local offlineHarvests = math.min(maxOfflineHarvests, remainingHarvests)
    
    -- Cap offline harvests to prevent exploitation (max 24 hours worth)
    local maxDailyHarvests = math.floor(86400 / growthTime) -- 24 hours worth
    offlineHarvests = math.min(offlineHarvests, maxDailyHarvests)
    
    return math.max(0, offlineHarvests)
end

-- Calculate effective growth time with online speed boost and weather effects
function PlotManager.calculateEffectiveGrowthTime(plotState, baseGrowthTime)
    if not plotState or not plotState.ownerId then
        return baseGrowthTime
    end
    
    local effectiveTime = baseGrowthTime
    
    -- Apply online speed boost
    local Players = game:GetService("Players")
    local owner = Players:GetPlayerByUserId(plotState.ownerId)
    
    if owner then
        -- Player is online: 2x speed boost (half the time)
        effectiveTime = effectiveTime / 2
    end
    
    -- Apply weather effects
    local WeatherSystem = require(script.Parent.WeatherSystem)
    local currentWeather = WeatherSystem.getCurrentWeather()
    local weatherMultiplier = 1.0
    
    if currentWeather and currentWeather.name then
        -- Get global weather multiplier
        local globalMultiplier = ConfigManager.getGlobalWeatherMultiplier(currentWeather.name)
        -- Get crop-specific weather boost
        local cropMultiplier = ConfigManager.getCropWeatherBoost(plotState.seedType, currentWeather.name)
        weatherMultiplier = globalMultiplier * cropMultiplier
    end
    
    -- Weather multiplier affects growth rate (higher = faster = less time)
    effectiveTime = effectiveTime / weatherMultiplier
    
    return effectiveTime
end

-- Get online boost multiplier for a player
function PlotManager.getOnlineBoostMultiplier(player)
    if player and player.Parent then
        return 2.0 -- 2x speed when online
    else
        return 1.0 -- Normal speed when offline
    end
end

return PlotManager