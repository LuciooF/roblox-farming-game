-- Plot Management Module
-- Handles all plot states, plant lifecycle, watering, and growth monitoring

local GameConfig = require(script.Parent.GameConfig)
local PlayerDataManager = require(script.Parent.PlayerDataManager)
local Logger = require(script.Parent.Logger)

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
function PlotManager.initializePlot(plotId, ownerId)
    local Players = game:GetService("Players")
    local player = Players:GetPlayerByUserId(ownerId)
    
    -- Try to load existing plot state from player data
    local savedPlotState = nil
    if player then
        local FarmManager = require(script.Parent.FarmManager)
        local farmId, plotIndex = FarmManager.getFarmAndPlotFromGlobalId(plotId)
        savedPlotState = PlayerDataManager.getPlotState(player, plotIndex)
        
        if savedPlotState then
            log.info("Loading saved plot state for player", player.Name, "plot", plotIndex, "state:", savedPlotState.state)
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
        needsReplanting = false -- Flag for when plant needs to be replanted
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

-- Plant seed on plot
function PlotManager.plantSeed(player, plotId, seedType)
    local plotState = plotStates[plotId]
    local playerData = PlayerDataManager.getPlayerData(player)
    
    if not plotState or not playerData then 
        return false, "Invalid plot or player data"
    end
    
    -- Validate seedType parameter
    if not seedType then
        log.error("PlotManager.plantSeed called with nil seedType for player", player.Name, "plot", plotId)
        return false, "No seed type specified"
    end
    
    -- Validate plot ownership with FarmManager
    local FarmManager = require(script.Parent.FarmManager)
    if not FarmManager.doesPlayerOwnPlot(player.UserId, plotId) then
        return false, "This plot doesn't belong to you!"
    end
    
    -- Validate plot is empty
    if plotState.state ~= "empty" then
        return false, "Plot is already occupied!"
    end
    
    -- Check if seed type exists in config
    if not GameConfig.Plants[seedType] then
        return false, "Unknown seed type: " .. seedType
    end
    
    -- Check player has seeds
    local seedCount = PlayerDataManager.getInventoryCount(player, "seeds", seedType)
    if seedCount <= 0 then
        return false, "You don't have " .. seedType .. " seeds!"
    end
    
    -- Roll for crop variation
    local variation = PlotManager.rollCropVariation()
    
    -- Plant the seed
    local currentTime = tick()
    plotState.state = "planted"
    plotState.seedType = seedType
    plotState.plantedTime = currentTime
    plotState.plantedAt = currentTime -- For client prediction
    plotState.ownerId = player.UserId
    plotState.wateredCount = 0
    plotState.waterNeeded = GameConfig.Plants[seedType].waterNeeded
    plotState.lastWateredTime = 0
    plotState.lastWateredAt = 0 -- For client prediction
    plotState.variation = variation
    plotState.harvestCooldown = 0 -- For permanent crops
    plotState.growthTime = GameConfig.Plants[seedType].growthTime
    plotState.waterTime = GameConfig.Plants[seedType].waterNeeded * 10 -- Time before needs water
    plotState.deathTime = GameConfig.Plants[seedType].deathTime or 120
    
    -- Set up replanting system
    plotState.harvestCount = 0
    local baseMaxHarvests = GameConfig.Replanting.maxHarvestCycles[seedType] or 3
    
    -- Apply random factors for realism
    local randomFactors = GameConfig.Replanting.randomFactors
    local rand = math.random(1, 100)
    
    if rand <= randomFactors.earlyWearoutChance then
        -- Plant wears out early
        plotState.maxHarvests = math.max(1, baseMaxHarvests - 1)
        log.debug("Plant", seedType, "will wear out early after", plotState.maxHarvests, "harvests")
    elseif rand <= randomFactors.earlyWearoutChance + randomFactors.bonusHarvestChance then
        -- Plant gets bonus harvest
        plotState.maxHarvests = baseMaxHarvests + 1
        log.debug("Plant", seedType, "will get bonus harvest, lasting", plotState.maxHarvests, "harvests")
    else
        -- Normal harvest count
        plotState.maxHarvests = baseMaxHarvests
    end
    
    plotState.needsReplanting = false
    
    -- Remove seed from inventory
    PlayerDataManager.removeFromInventory(player, "seeds", seedType, 1)
    
    -- Send plot update to clients for smooth countdown prediction (also saves to player data)
    sendPlotUpdate(plotId, {plantedAt = currentTime})
    
    return true, "Planted " .. seedType .. "! Now water it."
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
        sendPlotUpdate(plotId, {wateredAt = currentTime})
        
        return true, "Plant fully watered (" .. waterProgress .. ")! Growing now..."
    else
        -- Partially watered
        plotState.state = "growing"
        
        -- Send plot update to clients (also saves to player data)
        sendPlotUpdate(plotId, {wateredAt = currentTime})
        
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
    
    -- Check harvest cooldown
    local harvestCooldown = GameConfig.Plants[plotState.seedType].harvestCooldown or 30
    if tick() - plotState.harvestCooldown < harvestCooldown then
        local timeLeft = math.ceil(harvestCooldown - (tick() - plotState.harvestCooldown))
        return false, "Harvest again in " .. timeLeft .. " seconds!"
    end
    
    local seedType = plotState.seedType
    local variation = plotState.variation or "normal"
    local baseYield = 1
    local bonusYield = math.random(0, 1) -- Random bonus
    local variationMultiplier = GameConfig.CropVariations[variation].multiplier or 1
    local totalYield = math.floor((baseYield + bonusYield) * variationMultiplier)
    
    -- Add crops to inventory with variation prefix
    local cropName = seedType
    if variation ~= "normal" then
        cropName = GameConfig.CropVariations[variation].prefix .. seedType
    end
    
    PlayerDataManager.addToInventory(player, "crops", cropName, totalYield)
    
    -- Update harvest count and check replanting logic
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
        
        local message = "Harvested " .. totalYield .. " " .. cropName .. "! Plant needs replanting."
        if variation ~= "normal" then
            message = message .. " (" .. (variationMultiplier) .. "x bonus!)"
        end
        
        return true, message
    else
        -- Plant can continue growing, check if it needs watering
        local needsWatering = false
        
        if GameConfig.Replanting.requiresWateringAfterHarvest then
            local wateringChance = GameConfig.Replanting.wateringChanceAfterHarvest
            needsWatering = math.random(1, 100) <= wateringChance
        end
        
        if needsWatering then
            -- Reset to planted state requiring watering
            plotState.state = "planted"
            plotState.plantedTime = tick()
            plotState.wateredTime = 0
            plotState.lastWateredTime = 0
            plotState.wateredCount = 0
            
            sendPlotUpdate(plotId, {plantedAt = plotState.plantedTime, lastWateredAt = 0})
            
            local harvestsLeft = plotState.maxHarvests - plotState.harvestCount
            local message = "Harvested " .. totalYield .. " " .. cropName .. "! Needs watering again (" .. harvestsLeft .. " harvests left)."
            if variation ~= "normal" then
                message = message .. " (" .. (variationMultiplier) .. "x bonus!)"
            end
            
            return true, message
        else
            -- Reset to watered state for immediate regrowth
            plotState.state = "watered"
            plotState.wateredTime = tick()
            plotState.lastWateredTime = tick() -- Also update lastWateredTime for client countdown
            
            sendPlotUpdate(plotId, {lastWateredAt = plotState.wateredTime})
            
            local harvestsLeft = plotState.maxHarvests - plotState.harvestCount
            local message = "Harvested " .. totalYield .. " " .. cropName .. "! Growing again (" .. harvestsLeft .. " harvests left)."
            if variation ~= "normal" then
                message = message .. " (" .. (variationMultiplier) .. "x bonus!)"
            end
            
            return true, message
        end
    end
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
            
            if timeSinceWatered >= growthTime then
                -- Plant is ready!
                plotState.state = "ready"
                
                -- Send plot update to clients
                sendPlotUpdate(plotId)
                
                return "plant_ready", {
                    plotId = plotId,
                    seedType = plotState.seedType
                }
            end
        end
    end
end

-- Roll for crop variation when planting
function PlotManager.rollCropVariation()
    local roll = math.random() * 100
    local cumulative = 0
    
    -- Check variations in order of rarity (most common first)
    local variationOrder = {"normal", "shiny", "rainbow", "golden", "diamond"}
    
    for _, variation in ipairs(variationOrder) do
        cumulative = cumulative + GameConfig.CropVariations[variation].chance
        if roll <= cumulative then
            return variation
        end
    end
    
    -- Fallback to normal
    return "normal"
end

-- Get countdown info for display
function PlotManager.getCountdownInfo(plotId)
    local plotState = plotStates[plotId]
    if not plotState then return nil end
    
    local plantName = plotState.seedType:gsub("^%l", string.upper)
    
    if plotState.state == "planted" or plotState.state == "growing" then
        -- Show water requirement countdown
        local deathTime = GameConfig.Plants[plotState.seedType].deathTime
        local timeSincePlanted = tick() - plotState.plantedTime
        local timeUntilDeath = deathTime - timeSincePlanted
        
        local waterProgress = plotState.wateredCount .. "/" .. plotState.waterNeeded
        local deathMinutes = math.floor(timeUntilDeath / 60)
        local deathSeconds = math.floor(timeUntilDeath % 60)
        
        local displayText = plantName .. "\nWater: " .. waterProgress .. "\nDies in: " .. deathMinutes .. ":" .. string.format("%02d", deathSeconds)
        
        -- Check if there's a watering cooldown
        if plotState.wateredCount > 0 and plotState.wateredCount < plotState.waterNeeded then
            local timeSinceLastWater = tick() - plotState.lastWateredTime
            local cooldownLeft = GameConfig.Settings.waterCooldown - timeSinceLastWater
            
            if cooldownLeft > 0 then
                local cooldownMinutes = math.floor(cooldownLeft / 60)
                local cooldownSeconds = math.floor(cooldownLeft % 60)
                displayText = displayText .. "\nNext water: " .. cooldownMinutes .. ":" .. string.format("%02d", cooldownSeconds)
            end
        end
        
        return {
            text = displayText,
            color = timeUntilDeath < 30 and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(255, 255, 255)
        }
        
    elseif plotState.state == "watered" then
        -- Show growth countdown
        local growthTime = GameConfig.Plants[plotState.seedType].growthTime
        local timeSinceWatered = tick() - plotState.wateredTime
        local timeUntilReady = growthTime - timeSinceWatered
        
        local readyMinutes = math.floor(timeUntilReady / 60)
        local readySeconds = math.floor(timeUntilReady % 60)
        
        return {
            text = plantName .. " Growing\nReady in: " .. readyMinutes .. ":" .. string.format("%02d", readySeconds),
            color = Color3.fromRGB(100, 255, 100)
        }
        
    elseif plotState.state == "ready" then
        -- Show harvest message
        return {
            text = plantName .. " Ready!\n🌟 Harvest Now! 🌟",
            color = Color3.fromRGB(255, 255, 100)
        }
        
    elseif plotState.state == "dead" then
        -- Show dead plant message
        local deathReason = plotState.deathReason or "unknown reason"
        return {
            text = "💀 " .. plantName .. " Died\n" .. deathReason .. "\n❌ Clear to replant",
            color = Color3.fromRGB(255, 0, 0)
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

return PlotManager