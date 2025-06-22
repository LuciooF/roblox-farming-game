-- Plot Management Module
-- Handles all plot states, plant lifecycle, watering, and growth monitoring

local GameConfig = require(script.Parent.GameConfig)
local PlayerDataManager = require(script.Parent.PlayerDataManager)

local PlotManager = {}

-- Storage
local plotStates = {} -- [plotId] = { state, seedType, plantedTime, etc. }

-- Initialize plot state
function PlotManager.initializePlot(plotId)
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
    
    -- Validate plot is empty
    if plotState.state ~= "empty" then
        return false, "Plot is already occupied!"
    end
    
    -- Check player has seeds
    local seedCount = PlayerDataManager.getInventoryCount(player, "seeds", seedType)
    if seedCount <= 0 then
        return false, "You don't have " .. seedType .. " seeds!"
    end
    
    -- Plant the seed
    plotState.state = "planted"
    plotState.seedType = seedType
    plotState.plantedTime = tick()
    plotState.ownerId = player.UserId
    plotState.wateredCount = 0
    plotState.waterNeeded = GameConfig.Plants[seedType].waterNeeded
    plotState.lastWateredTime = 0
    
    -- Remove seed from inventory
    PlayerDataManager.removeFromInventory(player, "seeds", seedType, 1)
    
    return true, "Planted " .. seedType .. "! Now water it."
end

-- Water plant on plot
function PlotManager.waterPlant(player, plotId)
    local plotState = plotStates[plotId]
    
    if not plotState then 
        return false, "Invalid plot"
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
    plotState.wateredCount = plotState.wateredCount + 1
    plotState.lastWateredTime = tick()
    
    local waterProgress = plotState.wateredCount .. "/" .. plotState.waterNeeded
    
    if plotState.wateredCount >= plotState.waterNeeded then
        -- Fully watered - start growing
        plotState.state = "watered"
        plotState.wateredTime = tick()
        return true, "Plant fully watered (" .. waterProgress .. ")! Growing now..."
    else
        -- Partially watered
        plotState.state = "growing"
        return true, "Plant watered (" .. waterProgress .. "). Needs more water!"
    end
end

-- Harvest crop from plot
function PlotManager.harvestCrop(player, plotId)
    local plotState = plotStates[plotId]
    local playerData = PlayerDataManager.getPlayerData(player)
    
    if not plotState or not playerData then 
        return false, "Invalid plot or player data"
    end
    
    -- Validate plot is ready
    if plotState.state ~= "ready" then
        return false, "Crop is not ready yet!"
    end
    
    local seedType = plotState.seedType
    local baseYield = 1
    local bonusYield = math.random(0, 1) -- Random bonus
    local totalYield = baseYield + bonusYield
    
    -- Add crops to inventory
    PlayerDataManager.addToInventory(player, "crops", seedType, totalYield)
    
    -- Reset plot
    PlotManager.resetPlot(plotId)
    
    return true, "Harvested " .. totalYield .. " " .. seedType .. "!", totalYield
end

-- Reset plot to empty state
function PlotManager.resetPlot(plotId)
    local plotState = plotStates[plotId]
    if plotState then
        plotState.state = "empty"
        plotState.seedType = ""
        plotState.plantedTime = 0
        plotState.wateredTime = 0
        plotState.lastWateredTime = 0
        plotState.wateredCount = 0
        plotState.waterNeeded = 0
        plotState.ownerId = nil
    end
end

-- Kill a plant (death mechanism)
function PlotManager.killPlant(plotId, reason)
    local plotState = plotStates[plotId]
    if not plotState then return false end
    
    local seedType = plotState.seedType
    local ownerId = plotState.ownerId
    
    -- Reset plot state
    PlotManager.resetPlot(plotId)
    
    return true, {
        seedType = seedType,
        ownerId = ownerId,
        reason = reason
    }
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
                return "plant_ready", {
                    plotId = plotId,
                    seedType = plotState.seedType
                }
            end
        end
    end
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
        
    else
        -- Empty plot
        return {
            text = "",
            color = Color3.fromRGB(255, 255, 255)
        }
    end
end

return PlotManager