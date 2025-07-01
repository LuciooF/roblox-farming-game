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

-- Helper function to get maximum crops allowed per plot for a player
-- This can be expanded later for gamepasses that increase crop limits
function PlotManager.getMaxAllowedInPlot(player)
    local baseLimit = 1000 -- Default 1k crops per plot
    
    -- Future gamepass logic could go here:
    -- local playerData = PlayerDataManager.getPlayerData(player)
    -- if playerData.gamepasses and playerData.gamepasses.doubleCropLimit then
    --     return baseLimit * 2
    -- end
    -- if playerData.gamepasses and playerData.gamepasses.ultraCropLimit then
    --     return baseLimit * 5
    -- end
    
    return baseLimit
end

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
    log.info("🔄 INITIALIZING PLOT", plotId, "for owner", ownerId, "player:", playerObject and playerObject.Name or "nil")
    -- Try to load existing plot state from player data (only if we have an owner)
    local savedPlotState = nil
    if ownerId and playerObject then
        local FarmManager = require(script.Parent.FarmManager)
        local farmId, plotIndex = FarmManager.getFarmAndPlotFromGlobalId(plotId)
        
        -- Use the passed player object directly
        savedPlotState = PlayerDataManager.getPlotState(playerObject, plotIndex)
        
        if savedPlotState then
            log.info("📂 LOADED SAVED STATE for plot", plotId, "- state:", savedPlotState.state, "seedType:", savedPlotState.seedType)
            
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
            if not savedPlotState.lastUpdateTime then
                savedPlotState.lastUpdateTime = tick()
            end
            
            -- Ensure maintenance watering fields exist (migration for old save data)
            if not savedPlotState.lastMaintenanceWater then
                savedPlotState.lastMaintenanceWater = 0
            end
            if savedPlotState.needsMaintenanceWater == nil then
                savedPlotState.needsMaintenanceWater = false
            end
            if not savedPlotState.maintenanceWaterInterval then
                savedPlotState.maintenanceWaterInterval = 43200 -- 12 hours
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
                if not savedPlotState.lastUpdateTime then
                    savedPlotState.lastUpdateTime = tick()
                end
                
                -- Ensure maintenance watering fields exist (migration for old save data)
                if not savedPlotState.lastMaintenanceWater then
                    savedPlotState.lastMaintenanceWater = 0
                end
                if savedPlotState.needsMaintenanceWater == nil then
                    savedPlotState.needsMaintenanceWater = false
                end
                if not savedPlotState.maintenanceWaterInterval then
                    savedPlotState.maintenanceWaterInterval = 43200 -- 12 hours
                end
            end
        else
            log.warn("Could not find player for userId", ownerId, "when loading plot", plotId)
        end
    end
    
    -- Use saved state or create new plot (locked if no owner)
    log.info("🎯 FINAL PLOT STATE for", plotId, "- using", savedPlotState and "SAVED" or "NEW", "state")
    plotStates[plotId] = savedPlotState or {
        state = ownerId and "empty" or "locked",
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
        baseYieldRate = 1, -- How many crops per harvest cycle
        
        -- Maintenance watering system (will be set per-crop when planting)
        lastMaintenanceWater = 0, -- When last maintenance watered
        needsMaintenanceWater = false, -- Whether crop needs maintenance watering
        maintenanceWaterInterval = 14400 -- Default 4 hours, updated per-crop when planting
    }
    
    -- Ensure ownerId is set correctly (in case it changed)
    plotStates[plotId].ownerId = ownerId
    
    -- Schedule production for plots that are already watered (on player join)
    local plotState = plotStates[plotId]
    if plotState.state == "watered" or plotState.state == "ready" then
        PlotManager.scheduleCropProduction(plotId, plotState)
    end
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
            ownerId = nil,
            
            -- Reset maintenance watering fields
            lastMaintenanceWater = 0,
            needsMaintenanceWater = false,
            maintenanceWaterInterval = 43200
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
        plotState.ownerId = player.UserId
        plotState.wateredCount = 0
        plotState.waterNeeded = cropData.waterNeeded
        plotState.lastWateredTime = 0
        plotState.variation = variation
        plotState.growthTime = ConfigManager.getGrowthTimeFromRate(cropType)
        plotState.waterTime = cropData.waterCooldown
        
        -- Set per-crop maintenance watering interval
        local CropRegistry = require(game:GetService("ReplicatedStorage").Shared.CropRegistry)
        plotState.maintenanceWaterInterval = CropRegistry.getMaintenanceWaterInterval(cropType)
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
    
    -- Calculate if maintenance watering is needed (same logic as client)
    local needsMaintenanceWater = false
    if plotState.wateredCount >= plotState.waterNeeded and plotState.seedType ~= "" then
        local CropRegistry = require(game:GetService("ReplicatedStorage").Shared.CropRegistry)
        local cropInfo = CropRegistry.getCrop(plotState.seedType)
        if cropInfo and cropInfo.maintenanceWaterInterval then
            local maintenanceStartTime = plotState.lastMaintenanceWater > 0 and plotState.lastMaintenanceWater or plotState.lastWateredTime
            local timeSinceLastMaintenance = tick() - maintenanceStartTime
            needsMaintenanceWater = timeSinceLastMaintenance >= cropInfo.maintenanceWaterInterval
        end
    end
    
    -- Validate plot has planted seed and needs water OR needs maintenance watering
    if plotState.state ~= "planted" and plotState.state ~= "growing" and not needsMaintenanceWater then
        return false, "Nothing to water here!"
    end
    
    -- Handle maintenance watering for ready/harvestable crops
    if needsMaintenanceWater then
        local currentTime = tick()
        plotState.lastMaintenanceWater = currentTime
        plotState.needsMaintenanceWater = false
        
        -- Resume crop production if plant was paused
        if plotState.state == "ready" then
            PlotManager.scheduleCropProduction(plotId, plotState)
        end
        
        -- Send plot update to clients
        sendPlotUpdate(plotId, {wateredAt = currentTime, triggerRainEffect = true})
        
        return true, "🚿 Maintenance watering complete! Crop production resumed."
    end
    
    -- Check if already fully watered (for initial watering)
    if plotState.wateredCount >= plotState.waterNeeded then
        return false, "Plant doesn't need more water!"
    end
    
    -- Check watering cooldown (per-crop specific)
    local CropRegistry = require(game:GetService("ReplicatedStorage").Shared.CropRegistry)
    local waterCooldown = CropRegistry.getWaterCooldown(plotState.seedType)
    local timeSinceLastWater = tick() - plotState.lastWateredTime
    if plotState.wateredCount > 0 and timeSinceLastWater < waterCooldown then
        local timeLeft = math.ceil(waterCooldown - timeSinceLastWater)
        return false, "Wait " .. timeLeft .. " seconds before watering again!"
    end
    
    -- Add water
    local currentTime = tick()
    plotState.wateredCount = plotState.wateredCount + 1
    plotState.lastWateredTime = currentTime
    plotState.lastWaterActionTime = currentTime -- For client UI cooldown display
    
    local waterProgress = plotState.wateredCount .. "/" .. plotState.waterNeeded
    
    if plotState.wateredCount >= plotState.waterNeeded then
        -- Fully watered - start growing
        plotState.state = "watered"
        plotState.wateredTime = currentTime
        plotState.lastReadyTime = currentTime -- Start accumulation timer
        
        -- Initialize maintenance watering system
        plotState.lastMaintenanceWater = currentTime -- Set initial maintenance time
        plotState.needsMaintenanceWater = false -- Not needed yet
        
        -- Schedule crop production (event-driven)
        PlotManager.scheduleCropProduction(plotId, plotState)
        
        -- Send plot update to clients (also saves to player data)
        sendPlotUpdate(plotId, {wateredAt = currentTime, triggerRainEffect = true})
        
        return true, "Plant fully watered (" .. waterProgress .. ")! Growing now... (Maintenance watering every 12h)"
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
    
    -- Debug logging for harvest issues
    log.warn("🌾 HARVEST ATTEMPT: Plot", plotId, "by", player.Name)
    log.warn("   State:", plotState.state)
    log.warn("   Accumulated Crops:", plotState.accumulatedCrops or 0)
    log.warn("   Seed Type:", plotState.seedType or "none")
    log.warn("   Watered Count:", plotState.wateredCount or 0, "/", plotState.waterNeeded or 0)
    
    -- NEW LOGIC: Allow harvest if we have accumulated crops, regardless of state
    local hasAccumulatedCrops = plotState.accumulatedCrops and plotState.accumulatedCrops > 0
    
    -- Validate plot is ready and owned by player
    if plotState.state ~= "ready" and not hasAccumulatedCrops then
        log.warn("❌ HARVEST DENIED: State is", plotState.state, "and no accumulated crops")
        return false, "Crop is not ready yet! (State: " .. tostring(plotState.state) .. ", Crops: " .. tostring(plotState.accumulatedCrops or 0) .. ")"
    end
    
    if hasAccumulatedCrops then
        log.warn("✅ HARVEST ALLOWED: Has", plotState.accumulatedCrops, "accumulated crops (state:", plotState.state, ")")
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
    
    -- Harvest cooldown check removed - players can harvest immediately
    
    local seedType = plotState.seedType
    local variation = plotState.variation or "normal"
    
    -- Accumulated crops are now updated via event-driven system
    
    -- Harvest ALL ready crops at once
    local totalYield = math.max(1, plotState.accumulatedCrops or 1)
    
    -- Safe variation handling with fallback
    local variationMultiplier = 1
    if GameConfig.CropVariations and GameConfig.CropVariations[variation] then
        variationMultiplier = GameConfig.CropVariations[variation].multiplier or 1
    end
    totalYield = math.floor(totalYield * variationMultiplier)
    
    -- Add crops to inventory with variation prefix
    local cropName = seedType
    if variation ~= "normal" and GameConfig.CropVariations and GameConfig.CropVariations[variation] then
        cropName = GameConfig.CropVariations[variation].prefix .. seedType
    end
    
    local success, amountAdded, limitHit = PlayerDataManager.addToInventory(player, "crops", cropName, totalYield)
    
    -- Handle crop limit notification
    if limitHit then
--         local NotificationManager = require(script.Parent.NotificationManager)
        local wastedCrops = totalYield - amountAdded
        if amountAdded > 0 then
--             NotificationManager.sendWarning(player, "🚧 Inventory limit: Only " .. amountAdded .. " " .. cropName .. " added! (" .. wastedCrops .. " lost - 1k max per crop)")
        else
--             NotificationManager.sendError(player, "🚫 Inventory full: " .. cropName .. " limit reached (1k max)! Sell some crops first.")
        end
    end
    
    -- Reset accumulation after harvesting all ready crops
    plotState.accumulatedCrops = 0
    
    -- Harvest cooldown removed - no longer tracking cooldown timestamp
    
    -- Plants continue producing - DON'T reset timing, just continue from where they were
    plotState.state = "watered"  -- Back to growing state
    -- DON'T reset wateredTime, lastWateredTime, or lastReadyTime - keep current progress!
    plotState.wateredCount = plotState.waterNeeded -- Keep plants watered
    
    -- Continue production cycle if not already running (don't restart timing)
    -- The existing scheduleCropProduction will handle the timing correctly
    log.info("🔄 Harvest complete - continuing production without resetting timing")
    
    -- Keep the plant visual (all plants remain active)
    local WorldBuilder = require(script.Parent.Parent.WorldBuilder)
    local plot = WorldBuilder.getPlotById(plotId)
    if plot then
        local activePlants = plotState.maxHarvests - plotState.harvestCount
        WorldBuilder.updatePlotState(plot, "watered", plotState.seedType, plotState.variation or "normal", plotState.harvestCount, plotState.wateredCount, plotState.waterNeeded, 0)
    end
    
    sendPlotUpdate(plotId, {cropHarvested = true})
    
    local activePlants = plotState.maxHarvests - plotState.harvestCount
    log.info("🔄 Harvest complete - plot continues growing from current timing")
    local message = "Harvested " .. totalYield .. " " .. cropName .. "! " .. activePlants .. " plants continue producing."
    if variation ~= "normal" then
        message = message .. " (" .. (variationMultiplier) .. "x bonus!)"
    end
    
    return true, message
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
    
    -- Accumulated crops are now updated via event-driven system
    
    -- Harvest ALL accumulated crops
    local totalYield = math.max(harvestsLeft, plotState.accumulatedCrops or harvestsLeft)
    local variationMultiplier = 1
    if GameConfig.CropVariations and GameConfig.CropVariations[variation] then
        variationMultiplier = GameConfig.CropVariations[variation].multiplier or 1
    end
    totalYield = math.floor(totalYield * variationMultiplier)
    
    -- Add crops to inventory with variation prefix
    local cropName = seedType
    if variation ~= "normal" and GameConfig.CropVariations and GameConfig.CropVariations[variation] then
        cropName = GameConfig.CropVariations[variation].prefix .. seedType
    end
    
    local success, amountAdded, limitHit = PlayerDataManager.addToInventory(player, "crops", cropName, totalYield)
    
    -- Handle crop limit notification
    if limitHit then
--         local NotificationManager = require(script.Parent.NotificationManager)
        local wastedCrops = totalYield - amountAdded
        if amountAdded > 0 then
--             NotificationManager.sendWarning(player, "🚧 Inventory limit: Only " .. amountAdded .. " " .. cropName .. " added! (" .. wastedCrops .. " lost - 1k max per crop)")
        else
--             NotificationManager.sendError(player, "🚫 Inventory full: " .. cropName .. " limit reached (1k max)! Sell some crops first.")
        end
    end
    
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
        
        -- Update leaderstats since money changed
        PlayerDataManager.updateLeaderstats(player)
        
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
        plotState.growthTime = 0
        plotState.waterTime = 0
        plotState.deathTime = 0
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
        
        -- Crop accumulation is now handled via event-driven system
    end
end

-- Update crop accumulation for ready plants
function PlotManager.updateCropAccumulation(plotId, plotState)
    local currentTime = tick()
    local timeSinceReady = currentTime - (plotState.lastReadyTime or currentTime)
    
    -- Get production rate for this crop and calculate accumulation interval
    local CropRegistry = require(game:GetService("ReplicatedStorage").Shared.CropRegistry)
    local crop = CropRegistry.getCrop(plotState.seedType)
    local productionRate = (crop and crop.productionRate) or 1 -- fallback to 1/hour if not found
    local baseYieldRate = plotState.baseYieldRate or 1
    
    -- Calculate number of active plants (total planted minus harvested)
    local activePlants = plotState.maxHarvests - plotState.harvestCount
    
    -- Use production rate to calculate accumulation interval with boosts (e.g., 450 seconds for wheat at 8/hour)
    local baseAccumulationInterval = 3600 / productionRate -- Each plant produces 1 crop per production cycle
    
    -- Apply same boosts as scheduleCropProduction for consistency
    local Players = game:GetService("Players")
    local player = Players:GetPlayerByUserId(plotState.ownerId)
    local boostMultiplier = PlotManager.getOnlineBoostMultiplier(player)
    
    -- Apply weather effects
    local weatherMultiplier = 1.0
    if player then
        local WeatherSystem = require(script.Parent.WeatherSystem)
        local currentWeather = WeatherSystem.getCurrentWeather()
        
        if currentWeather and currentWeather.name then
            -- Use centralized weather configuration
            weatherMultiplier = ConfigManager.getGlobalWeatherMultiplier(currentWeather.name)
        end
    end
    
    -- Apply all boosts to interval (higher boosts = shorter intervals = faster production)
    local accumulationInterval = baseAccumulationInterval / (boostMultiplier * weatherMultiplier)
    local accumulationCycles = math.floor(timeSinceReady / accumulationInterval)
    
    if accumulationCycles > 0 and activePlants > 0 then
        -- Each plant produces 1 crop per growth cycle
        -- So with 10 plants, you get 10 crops every growth cycle
        local newCrops = accumulationCycles * activePlants
        
        -- Update accumulated crops with limit enforcement
        local oldCrops = plotState.accumulatedCrops or 0
        local plotCropLimit = PlotManager.getMaxAllowedInPlot(player)
        local maxCanAccumulate = plotCropLimit - oldCrops
        local cropsToAdd = math.min(newCrops, maxCanAccumulate)
        
        if cropsToAdd > 0 then
            plotState.accumulatedCrops = oldCrops + cropsToAdd
            
            if cropsToAdd < newCrops then
                local wastedCrops = newCrops - cropsToAdd
                log.debug("Plot", plotId, "hit", plotCropLimit, "crop limit -", wastedCrops, "crops not accumulated")
            end
        else
            log.debug("Plot", plotId, "at", plotCropLimit, "crop limit - no additional accumulation")
        end
        
        -- Update the last ready time to prevent double-counting
        plotState.lastReadyTime = currentTime
        
        -- Save to player data
        savePlotToPlayerData(plotId)
        
        log.debug("Plot", plotId, "accumulated", cropsToAdd, "crops over", timeSinceReady, "seconds, total:", plotState.accumulatedCrops, 
                 "| Base interval:", math.floor(baseAccumulationInterval), "s, Boosted interval:", math.floor(accumulationInterval), "s, Boost:", boostMultiplier, "x, Weather:", weatherMultiplier, "x")
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
        -- Crop accumulation handled by event-driven system
        
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
            -- PERMANENT CROPS: Accumulate crops on plot, capped by player's limit
            local plotCropLimit = PlotManager.getMaxAllowedInPlot(player)
            local currentAccumulated = plotState.accumulatedCrops or 0
            local maxCanAccumulate = plotCropLimit - currentAccumulated
            local cropsToAccumulate = math.min(offlineHarvests, maxCanAccumulate)
            
            if cropsToAccumulate > 0 then
                plotState.accumulatedCrops = currentAccumulated + cropsToAccumulate
                log.info("Plot", plotId, "accumulated", cropsToAccumulate, "crops offline (total:", plotState.accumulatedCrops, ")")
                
                if cropsToAccumulate < offlineHarvests then
                    local wastedCrops = offlineHarvests - cropsToAccumulate
                    log.info("Plot", plotId, "hit", plotCropLimit, "crop limit -", wastedCrops, "crops not produced")
                end
            else
                log.info("Plot", plotId, "at", plotCropLimit, "crop limit - no additional production")
            end
            
            -- Check if maintenance watering is needed after offline time
            local timeSinceMaintenanceWater = currentTime - (plotState.lastMaintenanceWater or 0)
            if timeSinceMaintenanceWater >= plotState.maintenanceWaterInterval then
                plotState.needsMaintenanceWater = true
                log.info("Plot", plotId, "needs maintenance watering after offline time")
            end
            
            -- PERMANENT CROPS: Always preserve crops for manual harvest - NEVER auto-harvest
            if (plotState.accumulatedCrops or 0) > 0 then
                plotState.state = "ready"
                log.info("Plot", plotId, "ready with", plotState.accumulatedCrops, "crops waiting for manual harvest")
            else
                -- Continue growing if not at limit and no maintenance needed
                if not plotState.needsMaintenanceWater then
                    plotState.state = "watered"
                    plotState.wateredTime = currentTime
                    plotState.lastWateredTime = currentTime
                    log.info("Plot", plotId, "continuing growth cycle")
                else
                    plotState.state = "ready" -- Needs maintenance, stop growing
                    log.info("Plot", plotId, "stopped growing - maintenance needed")
                end
            end
            
            -- Don't increment harvestCount for permanent crops - they produce forever
            -- plotState.harvestCount = math.min(plotState.harvestCount + offlineHarvests, plotState.maxHarvests)
        end
    elseif plotState.state == "planted" or plotState.state == "growing" then
        -- Plants no longer die - they just stop growing if not watered
        -- No death checking needed anymore
    end
    
    -- PERMANENT CROPS: Allow "ready" state even with 0 accumulated crops
    -- A plot can be "ready" (finished growing) but have 0 crops if it just completed a cycle
    -- The old validation was too aggressive and caused permanent crops to disappear
    -- if plotState.state == "ready" and (plotState.accumulatedCrops or 0) == 0 then
    --     plotState.state = "watered"
    --     log.info("Plot", plotId, "corrected state from ready to watered - no accumulated crops")
    -- end
    
    log.debug("Plot", plotId, "offline processing complete - state:", plotState.state, "accumulatedCrops:", plotState.accumulatedCrops or 0)
    
    -- Update last update time
    plotState.lastUpdateTime = currentTime
    
    return plotState
end

-- Calculate how many crops a ready plant should have produced offline
function PlotManager.calculateOfflineHarvests(plotState, timeOffline)
    if not plotState or plotState.state ~= "ready" then return 0 end
    
    -- Use base production rate WITHOUT boosts for offline production
    local CropRegistry = require(game:GetService("ReplicatedStorage").Shared.CropRegistry)
    local crop = CropRegistry.getCrop(plotState.seedType)
    local productionRate = (crop and crop.productionRate) or 1 -- fallback to 1/hour if not found
    local baseProductionInterval = 3600 / productionRate -- Convert crops/hour to seconds/crop
    
    -- NO BOOSTS for offline production - use base rate only
    local effectiveProductionInterval = baseProductionInterval
    
    -- Calculate number of active plants
    local activePlants = plotState.maxHarvests - plotState.harvestCount
    
    -- Calculate how many production cycles completed during offline time
    local completedCycles = math.floor(timeOffline / effectiveProductionInterval)
    
    -- Each cycle produces crops equal to number of active plants
    local totalOfflineCrops = completedCycles * activePlants
    
    -- Cap offline crops to prevent exploitation (max 24 hours worth at base rate)
    local maxDailyCycles = math.floor(86400 / effectiveProductionInterval) -- 24 hours worth
    local maxDailyCrops = maxDailyCycles * activePlants
    totalOfflineCrops = math.min(totalOfflineCrops, maxDailyCrops)
    
    log.debug("Offline calculation (unboosted) - Time:", math.floor(timeOffline), "s, Base interval:", math.floor(baseProductionInterval), "s, Cycles:", completedCycles, "Plants:", activePlants, "Total crops:", totalOfflineCrops)
    
    return math.max(0, totalOfflineCrops)
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
        -- Player is online: apply boost multiplier
        local boostMultiplier = PlotManager.getOnlineBoostMultiplier(owner)
        effectiveTime = effectiveTime / boostMultiplier
    end
    
    -- Apply weather effects
    local WeatherSystem = require(script.Parent.WeatherSystem)
    local currentWeather = WeatherSystem.getCurrentWeather()
    local weatherMultiplier = 1.0
    
    if currentWeather and currentWeather.name then
        -- Use only global weather multiplier (affects all crops equally)
        weatherMultiplier = ConfigManager.getGlobalWeatherMultiplier(currentWeather.name)
    end
    
    -- Weather multiplier affects growth rate (higher = faster = less time)
    effectiveTime = effectiveTime / weatherMultiplier
    
    return effectiveTime
end

-- Get online boost multiplier for a player
function PlotManager.getOnlineBoostMultiplier(player)
    if player and player.Parent then
        local baseBoost = 2.0 -- 2x speed when online
        
        -- Add debug production boost if present
        local PlayerDataManager = require(script.Parent.PlayerDataManager)
        local playerData = PlayerDataManager.getPlayerData(player)
        local finalMultiplier = baseBoost
        
        if playerData and playerData.debugProductionBoost then
            local debugMultiplier = 1 + (playerData.debugProductionBoost / 100)
            finalMultiplier = finalMultiplier * debugMultiplier
        end
        
        -- Add production gamepass boost if player owns it
        if playerData and playerData.gamepasses and playerData.gamepasses.productionBoost then
            finalMultiplier = finalMultiplier * 2.0 -- 2x for production gamepass
        end
        
        return finalMultiplier
    else
        return 1.0 -- Normal speed when offline
    end
end

-- Get all plot states (for update loops)
function PlotManager.getAllPlotStates()
    return plotStates
end

-- Schedule crop production for a plot (event-driven)
function PlotManager.scheduleCropProduction(plotId, plotState)
    -- Use productionRate from CropRegistry instead of growthTime
    local CropRegistry = require(game:GetService("ReplicatedStorage").Shared.CropRegistry)
    local crop = CropRegistry.getCrop(plotState.seedType)
    local productionRate = (crop and crop.productionRate) or 1 -- fallback to 1/hour if not found
    local baseProductionInterval = 3600 / productionRate -- Convert crops/hour to seconds/crop
    local activePlants = plotState.maxHarvests - plotState.harvestCount
    
    if activePlants <= 0 then return end
    
    -- Apply same bonuses as client: online bonus, debug boost, gamepass boost, weather effects, etc.
    local effectiveProductionInterval = baseProductionInterval
    
    -- Get comprehensive boost multiplier (includes online, debug, gamepass, etc.)
    local Players = game:GetService("Players")
    local player = Players:GetPlayerByUserId(plotState.ownerId)
    local boostMultiplier = PlotManager.getOnlineBoostMultiplier(player)
    
    -- Apply boost multiplier to production interval (higher boost = faster = shorter interval)
    effectiveProductionInterval = effectiveProductionInterval / boostMultiplier
    
    -- Weather effects - Apply same logic as client
    local weatherMultiplier = 1.0
    if player then
        local WeatherSystem = require(script.Parent.WeatherSystem)
        local currentWeather = WeatherSystem.getCurrentWeather()
        
        if currentWeather and currentWeather.name then
            -- Use centralized weather configuration
            weatherMultiplier = ConfigManager.getGlobalWeatherMultiplier(currentWeather.name)
        end
        
        -- Apply weather multiplier (higher = faster = shorter interval)
        effectiveProductionInterval = effectiveProductionInterval / weatherMultiplier
    end
    
    
    -- Calculate elapsed time since last watering to adjust production timer
    local currentTime = tick()
    local timeSinceWatered = currentTime - (plotState.lastWateredTime or 0)
    local remainingTime = math.max(0, effectiveProductionInterval - timeSinceWatered)
    
    
    spawn(function()
        if remainingTime > 0 then
            wait(remainingTime)
        else
        end
        
        -- Check if plot still exists and is in watered state
        local currentState = plotStates[plotId]
        if currentState and (currentState.state == "watered" or currentState.state == "ready") then
            -- Check if maintenance watering is needed (12 hours since last maintenance)
            local currentTime = tick()
            local timeSinceMaintenanceWater = currentTime - (currentState.lastMaintenanceWater or 0)
            
            if timeSinceMaintenanceWater >= currentState.maintenanceWaterInterval then
                -- Needs maintenance watering - pause production
                currentState.needsMaintenanceWater = true
                log.info("Plot", plotId, "needs maintenance watering after", math.floor(timeSinceMaintenanceWater/3600), "hours")
                
                -- Send update to client indicating maintenance is needed
                sendPlotUpdate(plotId, {maintenanceWaterNeeded = true})
                
                -- Don't produce crops or schedule next cycle until watered
                return
            end
            
            -- Produce crops equal to number of active plants (with limit enforcement)
            local currentActivePlants = currentState.maxHarvests - currentState.harvestCount
            local oldCrops = currentState.accumulatedCrops or 0
            
            -- Get crop limit and enforce it
            local Players = game:GetService("Players")
            local player = Players:GetPlayerByUserId(currentState.ownerId)
            local plotCropLimit = PlotManager.getMaxAllowedInPlot(player)
            local maxCanAccumulate = plotCropLimit - oldCrops
            local cropsToAdd = math.min(currentActivePlants, maxCanAccumulate)
            
            if cropsToAdd > 0 then
                currentState.accumulatedCrops = oldCrops + cropsToAdd
                
                if cropsToAdd < currentActivePlants then
                    local wastedCrops = currentActivePlants - cropsToAdd
                end
            else
            end
            
            currentState.state = "ready"
            currentState.lastReadyTime = currentTime
            
            -- CRITICAL: Update lastWateredTime to current time to prevent infinite loops
            currentState.lastWateredTime = currentTime
            
            
            -- Send update to client
            sendPlotUpdate(plotId, {cropProduced = true})
            
            -- Schedule next production cycle if plants are still active
            if currentActivePlants > 0 then
                PlotManager.scheduleCropProduction(plotId, currentState)
            end
        end
    end)
end

-- Check if a plot needs maintenance watering and update its status
function PlotManager.checkMaintenanceWatering(plotId)
    local plotState = plotStates[plotId]
    if not plotState then return false end
    
    -- Only check maintenance for crops that are watered/ready and have a harvest count > 0
    if plotState.state == "watered" or plotState.state == "ready" then
        local currentTime = tick()
        local timeSinceMaintenanceWater = currentTime - (plotState.lastMaintenanceWater or 0)
        
        -- If 12 hours have passed since last maintenance watering
        if timeSinceMaintenanceWater >= plotState.maintenanceWaterInterval and not plotState.needsMaintenanceWater then
            plotState.needsMaintenanceWater = true
            log.info("Plot", plotId, "now needs maintenance watering after", math.floor(timeSinceMaintenanceWater/3600), "hours")
            
            -- Send update to client
            sendPlotUpdate(plotId, {maintenanceWaterNeeded = true})
            return true
        end
    end
    
    return false
end


return PlotManager