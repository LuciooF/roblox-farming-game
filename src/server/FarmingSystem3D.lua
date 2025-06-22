-- 3D Physical Farming System
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Promise = require(Packages.promise)

local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

local FarmingSystem3D = {}

-- Game data
local playerFarms = {} -- [playerId] = { plots = {}, inventory = {}, stats = {} }
local plotStates = {}  -- [plotId] = { state, seedType, plantedTime, wateredTime, ownerId }
local testingGamepasses = {} -- [userId] = {autoPlant, autoWater, autoHarvest, autoSell}

-- Gamepass configurations
local gamepassConfig = {
    autoPlant = {name = "Auto Plant", description = "Automatically plant seeds on empty plots"},
    autoWater = {name = "Auto Water", description = "Automatically water growing plants"},
    autoHarvest = {name = "Auto Harvest", description = "Automatically harvest ready crops"},
    autoSell = {name = "Auto Sell", description = "Automatically sell harvested crops"}
}

-- RemoteEvents
local remotes = {}

-- Plant configurations with strategic depth
local plantConfig = {
    -- Quick crops (for active play)
    wheat = { 
        growthTime = 10, -- 10 seconds for testing (30 min real-time)
        waterNeeded = 1, 
        basePrice = 3, 
        seedCost = 1,
        description = "Fast growing, low profit",
        category = "Quick",
        deathTime = 30 -- Dies in 30 seconds if not watered
    },
    tomato = { 
        growthTime = 30, -- 30 seconds for testing (2 hours real-time)
        waterNeeded = 2, 
        basePrice = 12, 
        seedCost = 3,
        description = "Medium growth, good profit",
        category = "Medium",
        deathTime = 60 -- Dies in 1 minute if not watered
    },
    
    -- Medium crops (balanced)
    carrot = { 
        growthTime = 60, -- 1 minute for testing (4 hours real-time)
        waterNeeded = 2, 
        basePrice = 25, 
        seedCost = 8,
        description = "Steady growth, solid profit",
        category = "Medium",
        deathTime = 120 -- Dies in 2 minutes if not watered
    },
    
    -- Long-term crops (overnight/AFK)
    potato = { 
        growthTime = 180, -- 3 minutes for testing (12 hours real-time)
        waterNeeded = 3, 
        basePrice = 100, 
        seedCost = 25,
        description = "Slow growth, high profit",
        category = "Long-term",
        deathTime = 300 -- Dies in 5 minutes if not watered
    },
    corn = {
        growthTime = 300, -- 5 minutes for testing (24 hours real-time)
        waterNeeded = 4,
        basePrice = 250,
        seedCost = 80,
        description = "Very slow, premium profit",
        category = "Premium",
        deathTime = 600 -- Dies in 10 minutes if not watered
    }
}

-- Initialize the system
function FarmingSystem3D.initialize()
    print("FarmingSystem3D: Initializing...")
    
    -- Create RemoteEvents
    local remoteFolder = Instance.new("Folder")
    remoteFolder.Name = "FarmingRemotes"
    remoteFolder.Parent = ReplicatedStorage
    
    local plantRemote = Instance.new("RemoteEvent")
    plantRemote.Name = "PlantSeed"
    plantRemote.Parent = remoteFolder
    
    local waterRemote = Instance.new("RemoteEvent")
    waterRemote.Name = "WaterPlant"
    waterRemote.Parent = remoteFolder
    
    local harvestRemote = Instance.new("RemoteEvent")
    harvestRemote.Name = "HarvestCrop"
    harvestRemote.Parent = remoteFolder
    
    local buyRemote = Instance.new("RemoteEvent")
    buyRemote.Name = "BuyItem"
    buyRemote.Parent = remoteFolder
    
    local sellRemote = Instance.new("RemoteEvent")
    sellRemote.Name = "SellCrop"
    sellRemote.Parent = remoteFolder
    
    local syncRemote = Instance.new("RemoteEvent")
    syncRemote.Name = "SyncPlayerData"
    syncRemote.Parent = remoteFolder
    
    local togglePremiumRemote = Instance.new("RemoteEvent")
    togglePremiumRemote.Name = "TogglePremium"
    togglePremiumRemote.Parent = remoteFolder
    
    local rebirthRemote = Instance.new("RemoteEvent")
    rebirthRemote.Name = "PerformRebirth"
    rebirthRemote.Parent = remoteFolder
    
    -- Store references
    remotes.plant = plantRemote
    remotes.water = waterRemote
    remotes.harvest = harvestRemote
    remotes.buy = buyRemote
    remotes.sell = sellRemote
    remotes.sync = syncRemote
    remotes.togglePremium = togglePremiumRemote
    remotes.rebirth = rebirthRemote
    
    -- Connect events
    plantRemote.OnServerEvent:Connect(FarmingSystem3D.onPlantSeed)
    waterRemote.OnServerEvent:Connect(FarmingSystem3D.onWaterPlant)
    harvestRemote.OnServerEvent:Connect(FarmingSystem3D.onHarvestCrop)
    buyRemote.OnServerEvent:Connect(FarmingSystem3D.onBuyItem)
    sellRemote.OnServerEvent:Connect(FarmingSystem3D.onSellCrop)
    togglePremiumRemote.OnServerEvent:Connect(FarmingSystem3D.onTogglePremium)
    rebirthRemote.OnServerEvent:Connect(FarmingSystem3D.onPerformRebirth)
    
    -- Build the farm world
    local success, farm = pcall(function()
        return WorldBuilder.buildFarm()
    end)
    
    if not success then
        warn("Failed to build farm: " .. tostring(farm))
        return
    end
    
    -- Set up plot interactions
    FarmingSystem3D.setupPlotInteractions()
    
    -- Set up merchant interaction
    FarmingSystem3D.setupMerchantInteraction()
    
    -- Set up automation interaction
    FarmingSystem3D.setupAutomationInteraction()
    
    -- Start growth monitoring
    FarmingSystem3D.startGrowthMonitoring()
    
    print("FarmingSystem3D: Ready!")
end

-- Setup ProximityPrompt interactions
function FarmingSystem3D.setupPlotInteractions()
    local plots = WorldBuilder.getAllPlots()
    
    for _, plot in pairs(plots) do
        local plotIdValue = plot:FindFirstChild("PlotId")
        if plotIdValue then
            local plotId = plotIdValue.Value
            
            -- Initialize plot state with water tracking and cooldown
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
            
            -- Connect ProximityPrompts
            local plantPrompt = plot:FindFirstChild("PlantPrompt")
            local waterPrompt = plot:FindFirstChild("WaterPrompt")
            local harvestPrompt = plot:FindFirstChild("HarvestPrompt")
            
            if plantPrompt then
                plantPrompt.Triggered:Connect(function(player)
                    FarmingSystem3D.handlePlantInteraction(player, plotId)
                end)
            end
            
            if waterPrompt then
                waterPrompt.Triggered:Connect(function(player)
                    FarmingSystem3D.handleWaterInteraction(player, plotId)
                end)
            end
            
            if harvestPrompt then
                harvestPrompt.Triggered:Connect(function(player)
                    FarmingSystem3D.handleHarvestInteraction(player, plotId)
                end)
            end
        end
    end
end

-- Setup merchant interaction
function FarmingSystem3D.setupMerchantInteraction()
    local farm = game.Workspace:FindFirstChild("Farm")
    if not farm then return end
    
    local merchant = farm:FindFirstChild("Merchant")
    if not merchant then return end
    
    local sellPrompt = merchant:FindFirstChild("SellAllPrompt")
    if sellPrompt then
        sellPrompt.Triggered:Connect(function(player)
            FarmingSystem3D.handleSellAllCrops(player)
        end)
    end
end

-- Setup automation NPC interaction
function FarmingSystem3D.setupAutomationInteraction()
    local farm = game.Workspace:FindFirstChild("Farm")
    if not farm then return end
    
    local autoBot = farm:FindFirstChild("AutoBot")
    if not autoBot then return end
    
    local autoPrompt = autoBot:FindFirstChild("AutoPrompt")
    if autoPrompt then
        autoPrompt.Triggered:Connect(function(player)
            FarmingSystem3D.showAutomationMenu(player)
        end)
    end
end

-- Handle plant interaction via ProximityPrompt
function FarmingSystem3D.handlePlantInteraction(player, plotId)
    local playerData = FarmingSystem3D.getPlayerData(player)
    if not playerData then return end
    
    -- Check if player has seeds
    local availableSeed = nil
    for seedType, count in pairs(playerData.inventory.seeds) do
        if count > 0 then
            availableSeed = seedType
            break
        end
    end
    
    if not availableSeed then
        FarmingSystem3D.sendNotification(player, "You don't have any seeds!")
        return
    end
    
    FarmingSystem3D.plantSeed(player, plotId, availableSeed)
end

-- Handle water interaction via ProximityPrompt
function FarmingSystem3D.handleWaterInteraction(player, plotId)
    FarmingSystem3D.waterPlant(player, plotId)
end

-- Handle harvest interaction via ProximityPrompt
function FarmingSystem3D.handleHarvestInteraction(player, plotId)
    FarmingSystem3D.harvestCrop(player, plotId)
end

-- Plant seed on plot
function FarmingSystem3D.plantSeed(player, plotId, seedType)
    local plotState = plotStates[plotId]
    local playerData = FarmingSystem3D.getPlayerData(player)
    
    if not plotState or not playerData then return end
    
    -- Validate plot is empty
    if plotState.state ~= "empty" then
        FarmingSystem3D.sendNotification(player, "Plot is already occupied!")
        return
    end
    
    -- Check player has seeds
    if (playerData.inventory.seeds[seedType] or 0) <= 0 then
        FarmingSystem3D.sendNotification(player, "You don't have " .. seedType .. " seeds!")
        return
    end
    
    -- Plant the seed
    plotState.state = "planted"
    plotState.seedType = seedType
    plotState.plantedTime = tick()
    plotState.ownerId = player.UserId
    plotState.wateredCount = 0
    plotState.waterNeeded = plantConfig[seedType].waterNeeded
    
    -- Remove seed from inventory
    playerData.inventory.seeds[seedType] = playerData.inventory.seeds[seedType] - 1
    
    -- Update plot visuals
    local plot = WorldBuilder.getPlotById(plotId)
    if plot then
        WorldBuilder.updatePlotState(plot, "planted", seedType)
    end
    
    -- Sync player data
    FarmingSystem3D.syncPlayerData(player)
    
    FarmingSystem3D.sendNotification(player, "Planted " .. seedType .. "! Now water it.")
    
    print(player.Name .. " planted " .. seedType .. " on plot " .. plotId)
end

-- Water plant on plot
function FarmingSystem3D.waterPlant(player, plotId)
    local plotState = plotStates[plotId]
    
    if not plotState then return end
    
    -- Validate plot has planted seed and needs water
    if plotState.state ~= "planted" and plotState.state ~= "growing" then
        FarmingSystem3D.sendNotification(player, "Nothing to water here!")
        return
    end
    
    -- Check if already fully watered
    if plotState.wateredCount >= plotState.waterNeeded then
        FarmingSystem3D.sendNotification(player, "Plant doesn't need more water!")
        return
    end
    
    -- Check watering cooldown (30 seconds between waterings for multi-water plants)
    local waterCooldown = 30 -- 30 seconds
    local timeSinceLastWater = tick() - plotState.lastWateredTime
    
    if plotState.wateredCount > 0 and timeSinceLastWater < waterCooldown then
        local timeLeft = math.ceil(waterCooldown - timeSinceLastWater)
        FarmingSystem3D.sendNotification(player, "Wait " .. timeLeft .. " seconds before watering again!")
        return
    end
    
    -- Add water
    plotState.wateredCount = plotState.wateredCount + 1
    plotState.lastWateredTime = tick() -- Record when this watering happened
    
    local waterProgress = plotState.wateredCount .. "/" .. plotState.waterNeeded
    
    if plotState.wateredCount >= plotState.waterNeeded then
        -- Fully watered - start growing
        plotState.state = "watered"
        plotState.wateredTime = tick()
        
        -- Update plot visuals
        local plot = WorldBuilder.getPlotById(plotId)
        if plot then
            WorldBuilder.updatePlotState(plot, "watered", plotState.seedType)
        end
        
        FarmingSystem3D.sendNotification(player, "Plant fully watered (" .. waterProgress .. ")! Growing now...")
    else
        -- Partially watered
        plotState.state = "growing"
        
        -- Update plot visuals to show growing state
        local plot = WorldBuilder.getPlotById(plotId)
        if plot then
            WorldBuilder.updatePlotState(plot, "growing", plotState.seedType)
        end
        
        FarmingSystem3D.sendNotification(player, "Plant watered (" .. waterProgress .. "). Needs more water!")
    end
    
    print(player.Name .. " watered plot " .. plotId .. " (" .. waterProgress .. ")")
end

-- Harvest crop from plot
function FarmingSystem3D.harvestCrop(player, plotId)
    local plotState = plotStates[plotId]
    local playerData = FarmingSystem3D.getPlayerData(player)
    
    if not plotState or not playerData then return end
    
    -- Validate plot is ready
    if plotState.state ~= "ready" then
        FarmingSystem3D.sendNotification(player, "Crop is not ready yet!")
        return
    end
    
    local seedType = plotState.seedType
    local baseYield = 1
    local bonusYield = math.random(0, 1) -- Random bonus
    local totalYield = baseYield + bonusYield
    
    -- Add crops to inventory
    playerData.inventory.crops[seedType] = (playerData.inventory.crops[seedType] or 0) + totalYield
    
    -- Reset plot
    plotState.state = "empty"
    plotState.seedType = ""
    plotState.plantedTime = 0
    plotState.wateredTime = 0
    plotState.lastWateredTime = 0
    plotState.wateredCount = 0
    plotState.waterNeeded = 0
    plotState.ownerId = nil
    
    -- Update plot visuals
    local plot = WorldBuilder.getPlotById(plotId)
    if plot then
        WorldBuilder.updatePlotState(plot, "empty", "")
    end
    
    -- Sync player data
    FarmingSystem3D.syncPlayerData(player)
    
    FarmingSystem3D.sendNotification(player, "Harvested " .. totalYield .. " " .. seedType .. "!")
    
    print(player.Name .. " harvested " .. totalYield .. " " .. seedType .. " from plot " .. plotId)
end

-- Handle selling all crops to merchant
function FarmingSystem3D.handleSellAllCrops(player)
    local playerData = FarmingSystem3D.getPlayerData(player)
    if not playerData then return end
    
    local totalProfit = 0
    local itemsSold = {}
    
    -- Calculate total value with rebirth multiplier
    local rebirthMultiplier = rebirthConfig.getCropMultiplier(playerData.rebirths)
    
    for cropType, amount in pairs(playerData.inventory.crops) do
        if amount > 0 and plantConfig[cropType] then
            local baseValue = plantConfig[cropType].basePrice * amount
            local cropValue = math.floor(baseValue * rebirthMultiplier)
            totalProfit = totalProfit + cropValue
            itemsSold[cropType] = amount
            
            -- Clear crops from inventory
            playerData.inventory.crops[cropType] = 0
        end
    end
    
    if totalProfit > 0 then
        -- Add money to player
        playerData.money = playerData.money + totalProfit
        
        -- Build notification message with rebirth info
        local message = "Sold all crops for $" .. totalProfit .. "!"
        if playerData.rebirths > 0 then
            message = message .. " (" .. rebirthConfig.getCropMultiplier(playerData.rebirths) .. "x multiplier)"
        end
        for cropType, amount in pairs(itemsSold) do
            message = message .. "\n" .. amount .. " " .. cropType
        end
        
        -- Sync player data
        FarmingSystem3D.syncPlayerData(player)
        
        FarmingSystem3D.sendNotification(player, message)
        print(player.Name .. " sold all crops for $" .. totalProfit)
    else
        FarmingSystem3D.sendNotification(player, "You don't have any crops to sell!")
    end
end

-- Handle plant all automation (gamepass feature)
function FarmingSystem3D.handlePlantAll(player)
    -- Check if player has auto plant gamepass
    if not FarmingSystem3D.hasGamepass(player, "autoPlant") then
        FarmingSystem3D.sendNotification(player, "Auto Plant gamepass required!")
        return
    end
    
    local playerData = FarmingSystem3D.getPlayerData(player)
    if not playerData then return end
    
    local plantsPlanted = 0
    local seedsUsed = {}
    
    -- Find available seed (prefer wheat for automation)
    local seedPriority = {"wheat", "tomato", "carrot", "potato", "corn"}
    local selectedSeed = nil
    
    for _, seedType in ipairs(seedPriority) do
        if (playerData.inventory.seeds[seedType] or 0) > 0 then
            selectedSeed = seedType
            break
        end
    end
    
    if not selectedSeed then
        FarmingSystem3D.sendNotification(player, "You don't have any seeds to plant!")
        return
    end
    
    -- Plant on all empty plots
    for plotId, plotState in pairs(plotStates) do
        if plotState.state == "empty" and (playerData.inventory.seeds[selectedSeed] or 0) > 0 then
            -- Plant the seed
            plotState.state = "planted"
            plotState.seedType = selectedSeed
            plotState.plantedTime = tick()
            plotState.ownerId = player.UserId
            plotState.wateredCount = 0
            plotState.waterNeeded = plantConfig[selectedSeed].waterNeeded
            
            -- Remove seed from inventory
            playerData.inventory.seeds[selectedSeed] = playerData.inventory.seeds[selectedSeed] - 1
            seedsUsed[selectedSeed] = (seedsUsed[selectedSeed] or 0) + 1
            
            -- Update plot visuals
            local plot = WorldBuilder.getPlotById(plotId)
            if plot then
                WorldBuilder.updatePlotState(plot, "planted", selectedSeed)
            end
            
            plantsPlanted = plantsPlanted + 1
        end
    end
    
    if plantsPlanted > 0 then
        FarmingSystem3D.syncPlayerData(player)
        FarmingSystem3D.sendNotification(player, "AutoBot planted " .. plantsPlanted .. " " .. selectedSeed .. " seeds!")
        print(player.Name .. " used AutoBot to plant " .. plantsPlanted .. " seeds")
    else
        FarmingSystem3D.sendNotification(player, "No empty plots available!")
    end
end

-- Handle harvest all automation (gamepass feature)
function FarmingSystem3D.handleHarvestAll(player)
    -- Check if player has auto harvest gamepass
    if not FarmingSystem3D.hasGamepass(player, "autoHarvest") then
        FarmingSystem3D.sendNotification(player, "Auto Harvest gamepass required!")
        return
    end
    
    local playerData = FarmingSystem3D.getPlayerData(player)
    if not playerData then return end
    
    local cropsHarvested = 0
    local cropsGained = {}
    
    -- Harvest all ready plots owned by player
    for plotId, plotState in pairs(plotStates) do
        if plotState.state == "ready" and plotState.ownerId == player.UserId then
            local seedType = plotState.seedType
            local baseYield = 1
            local bonusYield = math.random(0, 1)
            local totalYield = baseYield + bonusYield
            
            -- Add crops to inventory
            playerData.inventory.crops[seedType] = (playerData.inventory.crops[seedType] or 0) + totalYield
            cropsGained[seedType] = (cropsGained[seedType] or 0) + totalYield
            
            -- No experience system - using rebirths instead
            
            -- Reset plot
            plotState.state = "empty"
            plotState.seedType = ""
            plotState.plantedTime = 0
            plotState.wateredTime = 0
            plotState.lastWateredTime = 0
            plotState.wateredCount = 0
            plotState.waterNeeded = 0
            plotState.ownerId = nil
            
            -- Update plot visuals
            local plot = WorldBuilder.getPlotById(plotId)
            if plot then
                WorldBuilder.updatePlotState(plot, "empty", "")
            end
            
            cropsHarvested = cropsHarvested + 1
        end
    end
    
    if cropsHarvested > 0 then
        FarmingSystem3D.syncPlayerData(player)
        
        local message = "AutoBot harvested " .. cropsHarvested .. " crops!"
        for cropType, amount in pairs(cropsGained) do
            message = message .. "\n" .. amount .. " " .. cropType
        end
        
        FarmingSystem3D.sendNotification(player, message)
        print(player.Name .. " used AutoBot to harvest " .. cropsHarvested .. " crops")
    else
        FarmingSystem3D.sendNotification(player, "No ready crops to harvest!")
    end
end

-- Check specific gamepass
function FarmingSystem3D.hasGamepass(player, gamepassType)
    local userId = tostring(player.UserId)
    local playerPasses = testingGamepasses[userId] or {}
    return playerPasses[gamepassType] or false
end

-- Toggle specific gamepass for testing
function FarmingSystem3D.toggleGamepass(player, gamepassType)
    local userId = tostring(player.UserId)
    if not testingGamepasses[userId] then
        testingGamepasses[userId] = {}
    end
    
    testingGamepasses[userId][gamepassType] = not (testingGamepasses[userId][gamepassType] or false)
    
    local status = testingGamepasses[userId][gamepassType] and "enabled" or "disabled"
    local passName = gamepassConfig[gamepassType].name
    FarmingSystem3D.sendNotification(player, passName .. " " .. status .. " for testing!")
    
    return testingGamepasses[userId][gamepassType]
end

-- Get all gamepass statuses
function FarmingSystem3D.getGamepassStatuses(player)
    local userId = tostring(player.UserId)
    return testingGamepasses[userId] or {}
end

-- Show automation menu to player
function FarmingSystem3D.showAutomationMenu(player)
    local statuses = FarmingSystem3D.getGamepassStatuses(player)
    
    local message = "AUTOMATION MENU:\n"
    for passType, config in pairs(gamepassConfig) do
        local status = statuses[passType] and "ON" or "OFF"
        message = message .. "\n" .. config.name .. ": " .. status
    end
    message = message .. "\n\nUse Premium Panel to toggle!"
    
    FarmingSystem3D.sendNotification(player, message)
end

-- Monitor plant growth and update countdowns
function FarmingSystem3D.startGrowthMonitoring()
    spawn(function()
        while true do
            wait(1) -- Check every second for real-time countdown updates
            
            for plotId, plotState in pairs(plotStates) do
                local plot = WorldBuilder.getPlotById(plotId)
                if not plot then continue end
                
                local countdownGui = plot:FindFirstChild("CountdownDisplay")
                local countdownLabel = countdownGui and countdownGui:FindFirstChild("TextLabel")
                
                if plotState.state == "planted" or plotState.state == "growing" then
                    -- Show water requirement countdown
                    local deathTime = plantConfig[plotState.seedType].deathTime
                    local timeSincePlanted = tick() - plotState.plantedTime
                    local timeUntilDeath = deathTime - timeSincePlanted
                    
                    if timeUntilDeath <= 0 then
                        -- Plant died!
                        FarmingSystem3D.killPlant(plotId, "Not watered in time")
                    else
                        local waterProgress = plotState.wateredCount .. "/" .. plotState.waterNeeded
                        local deathMinutes = math.floor(timeUntilDeath / 60)
                        local deathSeconds = math.floor(timeUntilDeath % 60)
                        
                        if countdownLabel then
                            local plantName = plotState.seedType:gsub("^%l", string.upper)
                            local displayText = plantName .. "\nWater: " .. waterProgress .. "\nDies in: " .. deathMinutes .. ":" .. string.format("%02d", deathSeconds)
                            
                            -- Check if there's a watering cooldown
                            if plotState.wateredCount > 0 and plotState.wateredCount < plotState.waterNeeded then
                                local waterCooldown = 30
                                local timeSinceLastWater = tick() - plotState.lastWateredTime
                                local cooldownLeft = waterCooldown - timeSinceLastWater
                                
                                if cooldownLeft > 0 then
                                    local cooldownMinutes = math.floor(cooldownLeft / 60)
                                    local cooldownSeconds = math.floor(cooldownLeft % 60)
                                    displayText = displayText .. "\nNext water: " .. cooldownMinutes .. ":" .. string.format("%02d", cooldownSeconds)
                                end
                            end
                            
                            countdownLabel.Text = displayText
                            -- Warning color if running out of time
                            if timeUntilDeath < 30 then
                                countdownLabel.TextColor3 = Color3.fromRGB(255, 100, 100) -- Red warning
                            else
                                countdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- Normal white
                            end
                        end
                    end
                    
                elseif plotState.state == "watered" then
                    -- Show growth countdown
                    local growthTime = plantConfig[plotState.seedType].growthTime
                    local timeSinceWatered = tick() - plotState.wateredTime
                    local timeUntilReady = growthTime - timeSinceWatered
                    
                    if timeUntilReady <= 0 then
                        -- Plant is ready!
                        plotState.state = "ready"
                        WorldBuilder.updatePlotState(plot, "ready", plotState.seedType)
                        print("Plot " .. plotId .. " (" .. plotState.seedType .. ") is ready for harvest!")
                    else
                        local readyMinutes = math.floor(timeUntilReady / 60)
                        local readySeconds = math.floor(timeUntilReady % 60)
                        
                        if countdownLabel then
                            local plantName = plotState.seedType:gsub("^%l", string.upper)
                            countdownLabel.Text = plantName .. " Growing\nReady in: " .. readyMinutes .. ":" .. string.format("%02d", readySeconds)
                            countdownLabel.TextColor3 = Color3.fromRGB(100, 255, 100) -- Green for growing
                        end
                    end
                    
                elseif plotState.state == "ready" then
                    -- Show harvest message
                    if countdownLabel then
                        local plantName = plotState.seedType:gsub("^%l", string.upper)
                        countdownLabel.Text = plantName .. " Ready!\n🌟 Harvest Now! 🌟"
                        countdownLabel.TextColor3 = Color3.fromRGB(255, 255, 100) -- Golden
                    end
                    
                elseif plotState.state == "empty" then
                    -- Clear countdown
                    if countdownLabel then
                        countdownLabel.Text = ""
                    end
                end
            end
        end
    end)
end

-- Rebirth system configuration
local rebirthConfig = {
    -- Exponentially growing money requirements for rebirths
    getMoneyRequirement = function(rebirth)
        return math.floor(1000 * (2.5 ^ rebirth)) -- 1K, 2.5K, 6.25K, 15.6K, 39K, 97.5K, etc.
    end,
    
    -- Crop value multiplier based on rebirths
    getCropMultiplier = function(rebirth)
        return 1 + (rebirth * 0.5) -- 1x, 1.5x, 2x, 2.5x, 3x, etc.
    end
}

-- Get or create player data
function FarmingSystem3D.getPlayerData(player)
    local userId = tostring(player.UserId)
    
    if not playerFarms[userId] then
        playerFarms[userId] = {
            money = 100,
            rebirths = 0,
            inventory = {
                seeds = {
                    wheat = 3,
                    tomato = 2,
                    carrot = 1,
                    potato = 0,
                    corn = 0
                },
                crops = {}
            }
        }
    end
    
    return playerFarms[userId]
end

-- Check if player can rebirth
function FarmingSystem3D.canRebirth(playerData)
    local moneyRequired = rebirthConfig.getMoneyRequirement(playerData.rebirths)
    return playerData.money >= moneyRequired
end

-- Perform rebirth
function FarmingSystem3D.performRebirth(player)
    local playerData = FarmingSystem3D.getPlayerData(player)
    if not playerData then return false end
    
    if not FarmingSystem3D.canRebirth(playerData) then
        local moneyRequired = rebirthConfig.getMoneyRequirement(playerData.rebirths)
        FarmingSystem3D.sendNotification(player, "Need $" .. moneyRequired .. " to rebirth!")
        return false
    end
    
    -- Perform rebirth
    local oldRebirths = playerData.rebirths
    playerData.rebirths = playerData.rebirths + 1
    playerData.money = 100 -- Reset money to starting amount
    
    -- Reset inventory to starting amounts
    playerData.inventory = {
        seeds = {
            wheat = 3,
            tomato = 2,
            carrot = 1,
            potato = 0,
            corn = 0
        },
        crops = {}
    }
    
    local newMultiplier = rebirthConfig.getCropMultiplier(playerData.rebirths)
    FarmingSystem3D.sendNotification(player, "REBIRTH! You are now Rebirth " .. playerData.rebirths .. "!\nCrop value multiplier: " .. newMultiplier .. "x")
    
    -- Sync updated data
    FarmingSystem3D.syncPlayerData(player)
    
    print(player.Name .. " rebirthed from " .. oldRebirths .. " to " .. playerData.rebirths)
    return true
end

-- Get rebirth info for player
function FarmingSystem3D.getRebirthInfo(player)
    local playerData = FarmingSystem3D.getPlayerData(player)
    if not playerData then return nil end
    
    return {
        currentRebirths = playerData.rebirths,
        moneyRequired = rebirthConfig.getMoneyRequirement(playerData.rebirths),
        cropMultiplier = rebirthConfig.getCropMultiplier(playerData.rebirths),
        canRebirth = FarmingSystem3D.canRebirth(playerData)
    }
end

-- Sync player data to client
function FarmingSystem3D.syncPlayerData(player)
    local playerData = FarmingSystem3D.getPlayerData(player)
    -- Add gamepass statuses to synced data
    playerData.gamepasses = FarmingSystem3D.getGamepassStatuses(player)
    remotes.sync:FireClient(player, playerData)
end

-- Send notification to player
function FarmingSystem3D.sendNotification(player, message)
    spawn(function()
        -- Create a temporary GUI notification
        local playerGui = player:WaitForChild("PlayerGui")
        
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "Notification_" .. tick()
        screenGui.Parent = playerGui
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 300, 0, 50)
        frame.Position = UDim2.new(0.5, -150, 0, 100)
        frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        frame.BackgroundTransparency = 0.3
        frame.BorderSizePixel = 0
        frame.Parent = screenGui
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = frame
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -20, 1, -10)
        label.Position = UDim2.new(0, 10, 0, 5)
        label.Text = message
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextScaled = true
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.SourceSansBold
        label.Parent = frame
        
        -- Fade out after 3 seconds
        wait(3)
        
        local tweenService = game:GetService("TweenService")
        local tween = tweenService:Create(frame, TweenInfo.new(1), {BackgroundTransparency = 1})
        local textTween = tweenService:Create(label, TweenInfo.new(1), {TextTransparency = 1})
        
        tween:Play()
        textTween:Play()
        
        tween.Completed:Connect(function()
            screenGui:Destroy()
        end)
    end)
end

-- Kill a plant (death mechanism)
function FarmingSystem3D.killPlant(plotId, reason)
    local plotState = plotStates[plotId]
    if not plotState then return end
    
    local seedType = plotState.seedType
    local ownerId = plotState.ownerId
    
    -- Reset plot state
    plotState.state = "empty"
    plotState.seedType = ""
    plotState.plantedTime = 0
    plotState.wateredTime = 0
    plotState.lastWateredTime = 0
    plotState.wateredCount = 0
    plotState.waterNeeded = 0
    plotState.ownerId = nil
    
    -- Update plot visuals
    local plot = WorldBuilder.getPlotById(plotId)
    if plot then
        WorldBuilder.updatePlotState(plot, "empty", "")
    end
    
    -- Notify owner if they're still in game
    if ownerId then
        local owner = game.Players:GetPlayerByUserId(ownerId)
        if owner then
            FarmingSystem3D.sendNotification(owner, "Your " .. seedType .. " died! " .. reason)
        end
    end
    
    print("Plot " .. plotId .. " plant (" .. seedType .. ") died: " .. reason)
end

-- Remote event handlers
function FarmingSystem3D.onPlantSeed(player, plotId, seedType)
    FarmingSystem3D.plantSeed(player, plotId, seedType)
end

function FarmingSystem3D.onWaterPlant(player, plotId)
    FarmingSystem3D.waterPlant(player, plotId)
end

function FarmingSystem3D.onHarvestCrop(player, plotId)
    FarmingSystem3D.harvestCrop(player, plotId)
end

function FarmingSystem3D.onBuyItem(player, itemType, itemName, cost)
    local playerData = FarmingSystem3D.getPlayerData(player)
    
    -- Use server-side pricing for validation
    local actualCost = plantConfig[itemName] and plantConfig[itemName].seedCost or cost
    
    if playerData.money >= actualCost then
        playerData.money = playerData.money - actualCost
        
        if itemType == "seeds" then
            playerData.inventory.seeds[itemName] = (playerData.inventory.seeds[itemName] or 0) + 1
        end
        
        FarmingSystem3D.syncPlayerData(player)
        
        local config = plantConfig[itemName]
        local message = "Bought " .. itemName .. " seeds! (" .. config.description .. ")"
        FarmingSystem3D.sendNotification(player, message)
    else
        FarmingSystem3D.sendNotification(player, "Not enough money! Need $" .. actualCost)
    end
end

function FarmingSystem3D.onSellCrop(player, cropType, amount)
    local playerData = FarmingSystem3D.getPlayerData(player)
    local available = playerData.inventory.crops[cropType] or 0
    
    if available >= amount then
        local basePrice = plantConfig[cropType].basePrice
        local rebirthMultiplier = rebirthConfig.getCropMultiplier(playerData.rebirths)
        local totalPrice = math.floor(basePrice * amount * rebirthMultiplier)
        
        playerData.inventory.crops[cropType] = available - amount
        playerData.money = playerData.money + totalPrice
        
        FarmingSystem3D.syncPlayerData(player)
        
        local message = "Sold " .. amount .. " " .. cropType .. " for $" .. totalPrice
        if playerData.rebirths > 0 then
            message = message .. " (" .. rebirthMultiplier .. "x)"
        end
        FarmingSystem3D.sendNotification(player, message)
    else
        FarmingSystem3D.sendNotification(player, "You don't have enough " .. cropType .. "!")
    end
end

function FarmingSystem3D.onTogglePremium(player)
    FarmingSystem3D.togglePremiumGamepass(player)
end

function FarmingSystem3D.onPerformRebirth(player)
    FarmingSystem3D.performRebirth(player)
end

-- Player join/leave handlers
function FarmingSystem3D.onPlayerJoined(player)
    local playerData = FarmingSystem3D.getPlayerData(player)
    
    -- Wait a bit for client to load
    wait(2)
    FarmingSystem3D.syncPlayerData(player)
    
    print("Player " .. player.Name .. " joined the farm!")
end

function FarmingSystem3D.onPlayerLeft(player)
    local userId = tostring(player.UserId)
    
    -- Clean up any owned plots
    for plotId, plotState in pairs(plotStates) do
        if plotState.ownerId == player.UserId then
            -- Reset plot (optional - you might want to keep plants growing)
            -- plotState.state = "empty"
            -- plotState.ownerId = nil
        end
    end
    
    print("Player " .. player.Name .. " left the farm!")
end

return FarmingSystem3D