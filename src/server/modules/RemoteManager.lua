-- Remote Event Management Module  
-- Handles all client-server communication and RemoteEvent setup

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(script.Parent.Logger)
local GameConfig = require(script.Parent.GameConfig)
local PlayerDataManager = require(script.Parent.PlayerDataManager)
local PlotManager = require(script.Parent.PlotManager)
local GamepassManager = require(script.Parent.GamepassManager)
local AutomationSystem = require(script.Parent.AutomationSystem)
local NotificationManager = require(script.Parent.NotificationManager)
local SoundManager = require(script.Parent.SoundManager)

local RemoteManager = {}

-- Get module logger
local log = Logger.getModuleLogger("RemoteManager")

-- Storage
local remotes = {}
local selectedItems = {} -- [playerId] = {type, name} or nil

-- Initialize all RemoteEvents
function RemoteManager.initialize()
    log.info("Initializing remote events...")
    
    -- Clear existing remotes folder if it exists
    local existingFolder = ReplicatedStorage:FindFirstChild("FarmingRemotes")
    if existingFolder then
        log.debug("Removing existing FarmingRemotes folder")
        existingFolder:Destroy()
    end
    
    -- Create RemoteEvents folder
    local remoteFolder = Instance.new("Folder")
    remoteFolder.Name = "FarmingRemotes"
    remoteFolder.Parent = ReplicatedStorage
    
    -- Create individual RemoteEvents
    local plantRemote = Instance.new("RemoteEvent")
    plantRemote.Name = "PlantCrop"
    plantRemote.Parent = remoteFolder
    
    local waterRemote = Instance.new("RemoteEvent")
    waterRemote.Name = "WaterPlant"
    waterRemote.Parent = remoteFolder
    
    local harvestRemote = Instance.new("RemoteEvent")
    harvestRemote.Name = "HarvestCrop"
    harvestRemote.Parent = remoteFolder
    
    local harvestAllRemote = Instance.new("RemoteEvent")
    harvestAllRemote.Name = "HarvestAllCrops"
    harvestAllRemote.Parent = remoteFolder
    
    local plotActionRemote = Instance.new("RemoteEvent")
    plotActionRemote.Name = "PlotAction"
    plotActionRemote.Parent = remoteFolder
    
    local openPlotUIRemote = Instance.new("RemoteEvent")
    openPlotUIRemote.Name = "OpenPlotUI"
    openPlotUIRemote.Parent = remoteFolder
    
    local buyRemote = Instance.new("RemoteEvent")
    buyRemote.Name = "BuyItem"
    buyRemote.Parent = remoteFolder
    
    local sellRemote = Instance.new("RemoteEvent")
    sellRemote.Name = "SellCrop"
    sellRemote.Parent = remoteFolder
    
    local syncRemote = Instance.new("RemoteEvent")
    syncRemote.Name = "SyncPlayerData"
    syncRemote.Parent = remoteFolder
    log.info("Created SyncPlayerData remote successfully")
    
    local togglePremiumRemote = Instance.new("RemoteEvent")
    togglePremiumRemote.Name = "TogglePremium"
    togglePremiumRemote.Parent = remoteFolder
    
    local rebirthRemote = Instance.new("RemoteEvent")
    rebirthRemote.Name = "PerformRebirth"
    rebirthRemote.Parent = remoteFolder
    
    local automationRemote = Instance.new("RemoteEvent")
    automationRemote.Name = "Automation"
    automationRemote.Parent = remoteFolder
    
    local tutorialRemote = Instance.new("RemoteEvent")
    tutorialRemote.Name = "TutorialData"
    tutorialRemote.Parent = remoteFolder
    
    local tutorialActionRemote = Instance.new("RemoteEvent")
    tutorialActionRemote.Name = "TutorialAction"
    tutorialActionRemote.Parent = remoteFolder
    
    local logCommandRemote = Instance.new("RemoteEvent")
    logCommandRemote.Name = "LogCommand"
    logCommandRemote.Parent = remoteFolder
    
    local selectedItemRemote = Instance.new("RemoteEvent")
    selectedItemRemote.Name = "SelectedItem"
    selectedItemRemote.Parent = remoteFolder
    
    local buySlotRemote = Instance.new("RemoteEvent")
    buySlotRemote.Name = "BuySlot"
    buySlotRemote.Parent = remoteFolder
    
    local buyPlotRemote = Instance.new("RemoteEvent")
    buyPlotRemote.Name = "BuyPlot"
    buyPlotRemote.Parent = remoteFolder
    
    local plotUpdateRemote = Instance.new("RemoteEvent")
    plotUpdateRemote.Name = "PlotUpdate"
    plotUpdateRemote.Parent = remoteFolder
    
    local characterTrackingRemote = Instance.new("RemoteEvent")
    characterTrackingRemote.Name = "CharacterTracking"
    characterTrackingRemote.Parent = remoteFolder
    
    local interactionFailureRemote = Instance.new("RemoteEvent")
    interactionFailureRemote.Name = "InteractionFailure"
    interactionFailureRemote.Parent = remoteFolder
    
    local clearDeadPlantRemote = Instance.new("RemoteEvent")
    clearDeadPlantRemote.Name = "ClearDeadPlant"
    clearDeadPlantRemote.Parent = remoteFolder
    
    local cutPlantRemote = Instance.new("RemoteEvent")
    cutPlantRemote.Name = "CutPlant"
    cutPlantRemote.Parent = remoteFolder
    
    local weatherRemote = Instance.new("RemoteEvent")
    weatherRemote.Name = "WeatherData"
    weatherRemote.Parent = remoteFolder
    
    local debugRemote = Instance.new("RemoteEvent")
    debugRemote.Name = "DebugActions"
    debugRemote.Parent = remoteFolder
    
    -- Store references
    remotes.plant = plantRemote
    remotes.water = waterRemote
    remotes.harvest = harvestRemote
    remotes.harvestAll = harvestAllRemote
    remotes.plotAction = plotActionRemote
    remotes.openPlotUI = openPlotUIRemote
    remotes.buy = buyRemote
    remotes.sell = sellRemote
    remotes.sync = syncRemote
    remotes.togglePremium = togglePremiumRemote
    remotes.rebirth = rebirthRemote
    remotes.automation = automationRemote
    remotes.tutorialRemote = tutorialRemote
    remotes.tutorialActionRemote = tutorialActionRemote
    remotes.logCommand = logCommandRemote
    remotes.selectedItem = selectedItemRemote
    remotes.buySlot = buySlotRemote
    remotes.buyPlot = buyPlotRemote
    remotes.plotUpdate = plotUpdateRemote
    remotes.characterTracking = characterTrackingRemote
    remotes.interactionFailure = interactionFailureRemote
    remotes.clearDeadPlant = clearDeadPlantRemote
    remotes.cutPlant = cutPlantRemote
    remotes.weather = weatherRemote
    remotes.debug = debugRemote
    
    -- Also create direct references for client access
    remotes.SyncPlayerData = syncRemote
    remotes.TutorialData = tutorialRemote
    remotes.TutorialAction = tutorialActionRemote
    remotes.LogCommand = logCommandRemote
    
    -- Connect events
    plantRemote.OnServerEvent:Connect(RemoteManager.onPlantCrop)
    waterRemote.OnServerEvent:Connect(RemoteManager.onWaterPlant)
    harvestRemote.OnServerEvent:Connect(RemoteManager.onHarvestCrop)
    harvestAllRemote.OnServerEvent:Connect(RemoteManager.onHarvestAllCrops)
    plotActionRemote.OnServerEvent:Connect(RemoteManager.onPlotAction)
    buyRemote.OnServerEvent:Connect(RemoteManager.onBuyItem)
    sellRemote.OnServerEvent:Connect(RemoteManager.onSellCrop)
    togglePremiumRemote.OnServerEvent:Connect(RemoteManager.onTogglePremium)
    rebirthRemote.OnServerEvent:Connect(RemoteManager.onPerformRebirth)
    automationRemote.OnServerEvent:Connect(RemoteManager.onAutomation)
    tutorialActionRemote.OnServerEvent:Connect(RemoteManager.onTutorialAction)
    logCommandRemote.OnServerEvent:Connect(RemoteManager.onLogCommand)
    selectedItemRemote.OnServerEvent:Connect(RemoteManager.onSelectedItem)
    buySlotRemote.OnServerEvent:Connect(RemoteManager.onBuySlot)
    buyPlotRemote.OnServerEvent:Connect(RemoteManager.onBuyPlot)
    clearDeadPlantRemote.OnServerEvent:Connect(RemoteManager.onClearDeadPlant)
    cutPlantRemote.OnServerEvent:Connect(RemoteManager.onCutPlant)
    weatherRemote.OnServerEvent:Connect(RemoteManager.onWeatherRequest)
    debugRemote.OnServerEvent:Connect(RemoteManager.onDebugAction)
    
    log.info("Remote events ready!")
end

-- Get remotes for other modules
function RemoteManager.getRemotes()
    return remotes
end

-- Sync player data to client
function RemoteManager.syncPlayerData(player)
    local playerData = PlayerDataManager.getPlayerData(player)
    
    -- If player data isn't loaded yet (ProfileStore still loading), send default data
    if not playerData or not playerData.isInitialized then
        log.debug("Player data not ready, sending default data for", player.Name)
        playerData = {
            isInitialized = false,
            money = 100, -- Default starting money
            seeds = {
                wheat = 5,  -- Give some starter seeds
                carrot = 0,
                tomato = 0,
                potato = 0,
                corn = 0
            },
            plantsGrown = 0,
            totalEarnings = 0
        }
    end
    
    -- Add gamepass statuses to synced data
    playerData.gamepasses = GamepassManager.getGamepassStatuses(player)
    
    log.debug("Syncing player data to", player.Name, "- Money:", playerData.money)
    remotes.sync:FireClient(player, playerData)
    log.debug("Player data sync sent successfully")
end

-- Remote event handlers
function RemoteManager.onPlantCrop(player, plotId, cropType)
    local success, message = PlotManager.plantCrop(player, plotId, cropType)
    if success then
        RemoteManager.syncPlayerData(player)
    end
    NotificationManager.sendNotification(player, message)
end

function RemoteManager.onWaterPlant(player, plotId)
    local success, message = PlotManager.waterPlant(player, plotId)
    NotificationManager.sendNotification(player, message)
end

function RemoteManager.onHarvestCrop(player, plotId)
    local success, message, totalYield = PlotManager.harvestCrop(player, plotId)
    if success then
        RemoteManager.syncPlayerData(player)
    end
    NotificationManager.sendNotification(player, message)
end

function RemoteManager.onHarvestAllCrops(player, plotId)
    local success, message = PlotManager.harvestAllCrops(player, plotId)
    if success then
        RemoteManager.syncPlayerData(player)
    end
    NotificationManager.sendNotification(player, message)
end

function RemoteManager.onPlotAction(player, action, plotId, extraData, quantity)
    log.debug("Plot action received:", action, "for plot", plotId, "from", player.Name, "extraData:", extraData, "quantity:", quantity)
    
    local success, message
    
    if action == "plant" then
        local cropType = extraData
        local plantQuantity = quantity or 1 -- Default to 1 if no quantity specified
        success, message = PlotManager.plantCrop(player, plotId, cropType, plantQuantity)
        if success then
            RemoteManager.syncPlayerData(player)
        end
    elseif action == "water" then
        success, message = PlotManager.waterPlant(player, plotId)
    elseif action == "harvest" then
        success, message = PlotManager.harvestCrop(player, plotId)
        if success then
            RemoteManager.syncPlayerData(player)
        end
    elseif action == "clear" then
        -- Clear dead plants
        local plotState = PlotManager.getPlotState(plotId)
        if plotState and plotState.state == "dead" then
            success, message = PlotManager.clearDeadPlant(player, plotId)
        else
            -- Cut living plants
            success, message = PlotManager.cutPlant(player, plotId)
        end
        if success then
            RemoteManager.syncPlayerData(player)
        end
    else
        log.warn("Unknown plot action:", action)
        message = "Unknown action"
    end
    
    if message then
        NotificationManager.sendNotification(player, message)
    end
end

function RemoteManager.onCutPlant(player, plotId)
    local success, message = PlotManager.cutPlant(player, plotId)
    if success then
        RemoteManager.syncPlayerData(player)
    end
    NotificationManager.sendNotification(player, message)
end

function RemoteManager.onBuyItem(player, itemType, itemName, cost)
    local playerData = PlayerDataManager.getPlayerData(player)
    
    -- Use server-side pricing for validation
    local actualCost = GameConfig.Plants[itemName] and GameConfig.Plants[itemName].seedCost or cost
    
    if playerData.money >= actualCost then
        local success = PlayerDataManager.removeMoney(player, actualCost)
        if success then
            PlayerDataManager.addToInventory(player, itemType, itemName, 1)
            RemoteManager.syncPlayerData(player)
            
            -- Check tutorial progress
            if itemType == "crops" then
                local TutorialManager = require(script.Parent.TutorialManager)
                TutorialManager.checkGameAction(player, "buy_crop", {cropType = itemName})
            end
            
            local message = "🛒 Bought " .. itemName .. " crop (-$" .. actualCost .. ")"
            NotificationManager.sendSuccess(player, message)
        end
    else
        NotificationManager.sendError(player, "💰 Need $" .. actualCost .. " for " .. itemName .. " crop")
    end
end

function RemoteManager.onSellCrop(player, cropType, amount)
    local playerData = PlayerDataManager.getPlayerData(player)
    local available = PlayerDataManager.getInventoryCount(player, "crops", cropType)
    
    -- Ensure amount is a number
    amount = tonumber(amount) or 0
    
    if available >= amount then
        -- Handle variation crops (e.g., "Shiny wheat" -> "wheat")
        local baseCropType = cropType
        local variationMultiplier = 1
        
        -- Check for variation prefixes
        for variationName, variationData in pairs(GameConfig.CropVariations) do
            if variationName ~= "normal" and cropType:find(variationData.prefix) then
                baseCropType = cropType:gsub(variationData.prefix, "")
                variationMultiplier = variationData.multiplier
                break
            end
        end
        
        local basePrice = GameConfig.Plants[baseCropType] and GameConfig.Plants[baseCropType].basePrice or 10
        local rebirthMultiplier = GameConfig.Rebirth.getCropMultiplier(playerData.rebirths)
        local totalPrice = math.floor(basePrice * variationMultiplier * amount * rebirthMultiplier)
        
        PlayerDataManager.removeFromInventory(player, "crops", cropType, amount)
        PlayerDataManager.addMoney(player, totalPrice)
        
        RemoteManager.syncPlayerData(player)
        
        -- Play sell sound
        SoundManager.playSellSound()
        
        -- Check tutorial progress
        local TutorialManager = require(script.Parent.TutorialManager)
        TutorialManager.checkGameAction(player, "sell_crops")
        
        local message = "💰 Sold " .. amount .. " " .. cropType .. " (+$" .. totalPrice .. ")"
        if playerData.rebirths > 0 then
            message = message .. " (" .. rebirthMultiplier .. "x)"
        end
        NotificationManager.sendMoney(player, message)
    else
        NotificationManager.sendError(player, "❌ Not enough " .. cropType .. " to sell!")
    end
end

function RemoteManager.onPerformRebirth(player)
    local success, result = PlayerDataManager.performRebirth(player)
    if success then
        RemoteManager.syncPlayerData(player)
        -- Play special rebirth sound
        SoundManager.playRebirthSound()
        NotificationManager.sendRebirthNotification(player, result)
    else
        local moneyRequired = GameConfig.Rebirth.getMoneyRequirement(PlayerDataManager.getPlayerData(player).rebirths)
        NotificationManager.sendError(player, "💰 Need $" .. moneyRequired .. " to rebirth!")
    end
end

function RemoteManager.onTogglePremium(player)
    -- This would be updated to handle specific gamepass toggles
    NotificationManager.sendWarning(player, "👑 Use individual gamepass toggles in Premium panel!")
end

function RemoteManager.onAutomation(player, actionType)
    local success, message, details
    
    if actionType == "plantAll" then
        success, message, details = AutomationSystem.plantAll(player)
    elseif actionType == "harvestAll" then
        success, message, details = AutomationSystem.harvestAll(player)
    elseif actionType == "waterAll" then
        success, message, details = AutomationSystem.waterAll(player)
    elseif actionType == "sellAll" then
        success, message, details = AutomationSystem.sellAll(player)
    elseif actionType == "menu" then
        message = GamepassManager.getAutomationMenuText(player)
        success = true
    else
        success = false
        message = "Unknown automation action: " .. tostring(actionType)
    end
    
    if success and (actionType == "plantAll" or actionType == "harvestAll" or actionType == "sellAll") then
        RemoteManager.syncPlayerData(player)
        
        -- Check tutorial progress for sellAll
        if actionType == "sellAll" then
            local TutorialManager = require(script.Parent.TutorialManager)
            TutorialManager.checkGameAction(player, "sell_crops")
        end
    end
    
    NotificationManager.sendAutomationNotification(player, success, message, details)
end

-- Tutorial action handler
function RemoteManager.onTutorialAction(player, actionType, data)
    local TutorialManager = require(script.Parent.TutorialManager)
    TutorialManager.handleTutorialAction(player, actionType, data)
end

-- Selected item handler
function RemoteManager.onSelectedItem(player, itemData)
    local playerId = tostring(player.UserId)
    selectedItems[playerId] = itemData -- {type = "crop", name = "wheat"} or nil
end

-- Get selected item for player
function RemoteManager.getSelectedItem(player)
    local playerId = tostring(player.UserId)
    return selectedItems[playerId]
end

-- Buy slot handler
function RemoteManager.onBuySlot(player)
    local playerData = PlayerDataManager.getPlayerData(player)
    local slotCost = 50 -- Fixed cost for now, will be developer product later
    
    if playerData.money >= slotCost then
        local success = PlayerDataManager.removeMoney(player, slotCost)
        if success then
            -- Add extra slot to player data
            if not playerData.extraSlots then
                playerData.extraSlots = 0
            end
            playerData.extraSlots = playerData.extraSlots + 1
            
            RemoteManager.syncPlayerData(player)
            
            local message = "🔓 Bought inventory slot " .. (9 + playerData.extraSlots) .. " (-$" .. slotCost .. ")"
            NotificationManager.sendSuccess(player, message)
            log.debug("Player", player.Name, "bought slot", 9 + playerData.extraSlots, "for $" .. slotCost)
        end
    else
        NotificationManager.sendError(player, "💰 Need $" .. slotCost .. " to buy a new inventory slot")
    end
end

-- Buy plot handler
function RemoteManager.onBuyPlot(player)
    local FarmManager = require(script.Parent.FarmManager)
    local success, message = FarmManager.unlockPlot(player)
    
    if success then
        -- Send updated player data to client
        RemoteManager.syncPlayerData(player)
        NotificationManager.sendSuccess(player, "🔓 " .. message)
        log.info("Player", player.Name, "purchased a new plot")
    else
        NotificationManager.sendError(player, "❌ " .. message)
        log.debug("Player", player.Name, "failed to purchase plot:", message)
    end
end

-- Clear dead plant handler
function RemoteManager.onClearDeadPlant(player, plotId)
    local success, message = PlotManager.clearDeadPlant(player, plotId)
    if success then
        NotificationManager.sendSuccess(player, "🗑️ " .. message)
    else
        NotificationManager.sendError(player, "❌ " .. message)
    end
end

-- Send interaction failure notification to client for rollback
function RemoteManager.sendInteractionFailure(player, plotId, interactionType, reason)
    if not remotes.interactionFailure then
        log.warn("InteractionFailure remote not available")
        return
    end
    
    log.debug("Sending interaction failure to", player.Name, "- plot:", plotId, "type:", interactionType, "reason:", reason)
    remotes.interactionFailure:FireClient(player, {
        plotId = plotId,
        interactionType = interactionType,
        reason = reason
    })
end

-- Send plot state update to clients with ownership-based data filtering
function RemoteManager.sendPlotUpdate(plotId, plotState, additionalData)
    if not remotes.plotUpdate then
        log.warn("PlotUpdate remote not available")
        return
    end
    
    -- Get plot ownership info via FarmManager
    local FarmManager = require(script.Parent.FarmManager)
    local farmId, plotIndex = FarmManager.getFarmAndPlotFromGlobalId(plotId)
    local ownerId, ownerName = FarmManager.getFarmOwner(farmId)
    
    -- Send detailed update to plot owner only
    if ownerId then
        local Players = game:GetService("Players")
        local owner = Players:GetPlayerByUserId(ownerId)
        if owner then
            -- Get timing data from GameConfig for the seed type
            local growthTime = 60 -- Default
            local waterTime = 30 -- Default
            local deathTime = 120 -- Default
            
            if plotState.seedType and plotState.seedType ~= "" then
                local plantConfig = GameConfig.Plants[plotState.seedType]
                if plantConfig then
                    growthTime = plantConfig.growthTime or 60
                    waterTime = plantConfig.waterTime or 30
                    deathTime = plantConfig.deathTime or 120
                end
            end
            
            local ownerUpdateData = {
                plotId = plotId,
                state = plotState.state,
                seedType = plotState.seedType,
                plantedAt = plotState.plantedAt,
                lastWateredAt = plotState.lastWateredAt,
                growthTime = growthTime,
                waterTime = waterTime,
                deathTime = deathTime,
                variation = plotState.variation,
                isOwner = true,
                harvestCount = plotState.harvestCount or 0,
                maxHarvests = plotState.maxHarvests or 0,
                accumulatedCrops = plotState.accumulatedCrops or 0,
                wateredCount = plotState.wateredCount or 0,
                waterNeeded = plotState.waterNeeded or 0
            }
            
            -- Add any additional timing data
            if additionalData then
                for key, value in pairs(additionalData) do
                    ownerUpdateData[key] = value
                end
            end
            
            remotes.plotUpdate:FireClient(owner, ownerUpdateData)
        end
    end
    
    -- Send visual-only update to all other players
    local publicUpdateData = {
        plotId = plotId,
        state = plotState.state,
        seedType = plotState.seedType,
        variation = plotState.variation,
        ownerName = ownerName,
        isOwner = false
    }
    
    for _, player in pairs(game.Players:GetPlayers()) do
        if not ownerId or player.UserId ~= ownerId then
            remotes.plotUpdate:FireClient(player, publicUpdateData)
        end
    end
    
    log.debug("Sent plot update for", plotId, "state:", plotState.state, "owner:", ownerName or "none")
end

-- Log command handler
function RemoteManager.onLogCommand(player, command, ...)
    -- Only allow in Studio or for developers
    local RunService = game:GetService("RunService")
    if not RunService:IsStudio() then
        return
    end
    
    if command == "setlevel" then
        local level = ...
        local success = Logger.setLevel(level)
        if success then
            log.info(player.Name .. " changed log level to " .. tostring(level))
        end
    elseif command == "getlevel" then
        log.info("Current log level: " .. Logger.getLevelName(Logger.getLevel()))
    elseif command == "test" then
        log.error("Test ERROR message")
        log.warn("Test WARN message") 
        log.info("Test INFO message")
        log.debug("Test DEBUG message")
        log.trace("Test TRACE message")
    end
end

-- Player connection handlers
function RemoteManager.onPlayerJoined(player)
    -- DON'T sync data immediately - wait for ProfileStore to load
    -- RemoteManager.syncPlayerData(player) -- REMOVED: This was sending default data too early
    
    -- Send current weather data
    RemoteManager.sendWeatherData(player)
    
    -- Tutorial initialization moved to PlayerDataManager.onPlayerJoined (after data is loaded)
    
    log.info("Player joined the farm:", player.Name)
end

function RemoteManager.onPlayerLeft(player)
    -- Clean up tutorial state
    local TutorialManager = require(script.Parent.TutorialManager)
    TutorialManager.onPlayerLeft(player)
    
    -- Clean up notification system
    NotificationManager.onPlayerLeft(player)
    
    -- Clean up selected items
    local playerId = tostring(player.UserId)
    selectedItems[playerId] = nil
    
    log.info("Player left the farm:", player.Name)
end

-- Handle weather data requests
function RemoteManager.onWeatherRequest(player, requestType, weatherName)
    print("🌤️ [RemoteManager] Weather request received from", player.Name)
    print("🌤️ [RemoteManager] Request type:", requestType)
    print("🌤️ [RemoteManager] Weather name:", weatherName)
    
    if requestType == "current" then
        -- Send current weather data
        print("🌤️ [RemoteManager] Sending current weather data")
        RemoteManager.sendWeatherData(player)
    elseif requestType == "force_change" and weatherName then
        -- Debug: Force weather change
        print("🌤️ [RemoteManager] Attempting to force weather change to:", weatherName)
        local WeatherSystem = require(script.Parent.WeatherSystem)
        local success = WeatherSystem.forceWeatherChange(weatherName)
        
        print("🌤️ [RemoteManager] Force weather change success:", success)
        
        if success then
            -- Broadcast updated weather to all players
            RemoteManager.broadcastWeatherData()
            NotificationManager.sendSuccess(player, "🌤️ Weather changed to " .. weatherName .. " (debug)")
        else
            NotificationManager.sendError(player, "❌ Failed to change weather to " .. weatherName)
        end
    else
        print("🌤️ [RemoteManager] Unknown request type or missing weather name")
    end
end

-- Send weather data to client
function RemoteManager.sendWeatherData(player)
    local WeatherSystem = require(script.Parent.WeatherSystem)
    local weatherData = WeatherSystem.getWeatherDataForClient()
    
    if remotes.weather then
        remotes.weather:FireClient(player, weatherData)
        log.debug("Sent weather data to", player.Name)
    end
end

-- Send weather data to all players
function RemoteManager.broadcastWeatherData()
    local WeatherSystem = require(script.Parent.WeatherSystem)
    local weatherData = WeatherSystem.getWeatherDataForClient()
    
    if remotes.weather then
        remotes.weather:FireAllClients(weatherData)
        log.debug("Broadcasted weather data to all players")
    end
end

-- Handle debug actions
function RemoteManager.onDebugAction(player, action, data)
    log.info("Debug action", action, "requested by", player.Name)
    
    if action == "addRebirth" then
        local success = PlayerDataManager.debugAddRebirth(player)
        if success then
            NotificationManager.sendSuccess(player, "🐛 Debug: +1 Rebirth added!")
            RemoteManager.syncPlayerData(player)
        else
            NotificationManager.sendError(player, "❌ Debug: Failed to add rebirth")
        end
        
    elseif action == "resetRebirths" then
        local success = PlayerDataManager.debugResetRebirths(player)
        if success then
            NotificationManager.sendSuccess(player, "🐛 Debug: Rebirths reset to 0!")
            RemoteManager.syncPlayerData(player)
        else
            NotificationManager.sendError(player, "❌ Debug: Failed to reset rebirths")
        end
        
    elseif action == "resetDatastore" then
        local success = PlayerDataManager.debugResetDatastore(player)
        if success then
            NotificationManager.sendSuccess(player, "🐛 Debug: Datastore completely reset!")
            RemoteManager.syncPlayerData(player)
        else
            NotificationManager.sendError(player, "❌ Debug: Failed to reset datastore")
        end
        
    elseif action == "addMoney" then
        local amount = data or 1000 -- Default to $1000 if no amount specified
        local success = PlayerDataManager.debugAddMoney(player, amount)
        if success then
            NotificationManager.sendSuccess(player, "🐛 Debug: +$" .. amount .. " added!")
            RemoteManager.syncPlayerData(player)
        else
            NotificationManager.sendError(player, "❌ Debug: Failed to add money")
        end
        
    else
        log.warn("Unknown debug action:", action)
        NotificationManager.sendError(player, "❌ Debug: Unknown action: " .. tostring(action))
    end
end

-- Send plot update to clients and update plot attributes
function RemoteManager.sendPlotUpdate(plotId, plotState, additionalData)
    if not plotState then return end
    
    -- Find the plot in the world and update its attributes
    local Players = game:GetService("Players")
    local plot = nil
    
    -- Search for the plot by plotId in all farms
    for _, farm in pairs(game.Workspace.PlayerFarms:GetChildren()) do
        for _, child in pairs(farm:GetChildren()) do
            local plotIdValue = child:FindFirstChild("PlotId")
            if plotIdValue and plotIdValue.Value == plotId then
                plot = child
                break
            end
        end
        if plot then break end
    end
    
    if plot then
        -- Update plot data values
        local plotData = plot:FindFirstChild("PlotData")
        if plotData then
            plotData.Value = plotState.state or "empty"
        end
        
        local seedType = plot:FindFirstChild("SeedType")
        if seedType then
            seedType.Value = plotState.seedType or ""
        end
        
        -- Set attributes for UI system
        plot:SetAttribute("HarvestCount", plotState.harvestCount or 0)
        plot:SetAttribute("MaxHarvests", plotState.maxHarvests or 0)
        plot:SetAttribute("AccumulatedCrops", plotState.accumulatedCrops or 0)
        plot:SetAttribute("WateredCount", plotState.wateredCount or 0)
        plot:SetAttribute("WaterNeeded", plotState.waterNeeded or 1)
        
        -- Update visual state
        local WorldBuilder = require(script.Parent.Parent.WorldBuilder)
        WorldBuilder.updatePlotState(plot, plotState.state, plotState.seedType, plotState.variation or "normal", plotState.wateredCount or 0, nil, nil, nil)
    end
    
    -- Send to client if owner exists
    if plotState.ownerId then
        local player = Players:GetPlayerByUserId(plotState.ownerId)
        if player and remotes.plotUpdate then
            -- Get timing data from GameConfig for the seed type
            local growthTime = 60 -- Default
            local waterTime = 30 -- Default
            local deathTime = 120 -- Default
            
            if plotState.seedType and plotState.seedType ~= "" then
                local plantConfig = GameConfig.Plants[plotState.seedType]
                if plantConfig then
                    growthTime = plantConfig.growthTime or 60
                    waterTime = plantConfig.waterTime or 30
                    deathTime = plantConfig.deathTime or 120
                end
            end
            
            -- Get current weather effects (same as openPlotUI)
            local WeatherSystem = require(script.Parent.WeatherSystem)
            local currentWeather = WeatherSystem.getCurrentWeather()
            local weatherEffects = {}
            
            if currentWeather and currentWeather.effects then
                weatherEffects = {
                    name = currentWeather.name,
                    emoji = currentWeather.emoji,
                    growthMultiplier = currentWeather.effects.growthMultiplier or 1.0,
                    autoWater = currentWeather.effects.autoWater or false,
                    benefitsThisCrop = false
                }
                
                -- Check if this crop benefits from current weather
                if currentWeather.benefitSeeds then
                    for _, benefitSeed in ipairs(currentWeather.benefitSeeds) do
                        if benefitSeed == plotState.seedType then
                            weatherEffects.benefitsThisCrop = true
                            break
                        end
                    end
                end
            end
            
            local clientData = {
                plotId = plotId,
                state = plotState.state or "empty",
                seedType = plotState.seedType or "",
                harvestCount = plotState.harvestCount or 0,
                maxHarvests = plotState.maxHarvests or 0,
                accumulatedCrops = plotState.accumulatedCrops or 0,
                wateredCount = plotState.wateredCount or 0,
                waterNeeded = plotState.waterNeeded or 1,
                -- Timing data
                plantedAt = plotState.plantedTime or 0,
                lastWateredAt = plotState.lastWateredTime or 0,
                growthTime = growthTime,
                waterTime = waterTime,
                deathTime = deathTime,
                -- Water cooldown data
                lastWaterActionTime = plotState.lastWaterActionTime or 0,
                waterCooldownSeconds = GameConfig.Settings.waterCooldown or 30,
                -- Weather and boost data
                weatherEffects = weatherEffects,
                onlineBonus = true, -- Player is online if they're receiving updates
                variation = plotState.variation or "normal",
                isOwner = true,
                ownerName = player.Name
            }
            
            -- Add any additional data passed in
            if additionalData then
                for key, value in pairs(additionalData) do
                    clientData[key] = value
                end
            end
            
            remotes.plotUpdate:FireClient(player, clientData)
            log.trace("Sent plot update to", player.Name, "for plot", plotId, "state:", plotState.state)
        end
    end
end

-- Send plot UI open request to client
function RemoteManager.openPlotUI(player, plotId)
    if not remotes.openPlotUI then return end
    
    -- Get plot state for the UI
    local PlotManager = require(script.Parent.PlotManager)
    local plotState = PlotManager.getPlotState(plotId)
    
    if plotState then
        -- Get timing data from GameConfig for the seed type
        local growthTime = 60 -- Default
        local waterTime = 30 -- Default
        local deathTime = 120 -- Default
        
        if plotState.seedType and plotState.seedType ~= "" then
            local plantConfig = GameConfig.Plants[plotState.seedType]
            if plantConfig then
                growthTime = plantConfig.growthTime or 60
                waterTime = plantConfig.waterTime or 30
                deathTime = plantConfig.deathTime or 120
            end
        end
        
        -- Get current weather effects
        local WeatherSystem = require(script.Parent.WeatherSystem)
        local currentWeather = WeatherSystem.getCurrentWeather()
        local weatherEffects = {}
        
        if currentWeather and currentWeather.effects then
            weatherEffects = {
                name = currentWeather.name,
                emoji = currentWeather.emoji,
                growthMultiplier = currentWeather.effects.growthMultiplier or 1.0,
                autoWater = currentWeather.effects.autoWater or false,
                benefitsThisCrop = false
            }
            
            -- Check if this crop benefits from current weather
            if currentWeather.benefitSeeds then
                for _, benefitSeed in ipairs(currentWeather.benefitSeeds) do
                    if benefitSeed == plotState.seedType then
                        weatherEffects.benefitsThisCrop = true
                        break
                    end
                end
            end
        end
        
        local clientData = {
            plotId = plotId,
            state = plotState.state or "empty",
            seedType = plotState.seedType or "",
            harvestCount = plotState.harvestCount or 0,
            maxHarvests = plotState.maxHarvests or 0,
            accumulatedCrops = plotState.accumulatedCrops or 0,
            wateredCount = plotState.wateredCount or 0,
            waterNeeded = plotState.waterNeeded or 1,
            -- Timing data
            plantedAt = plotState.plantedTime or 0,
            lastWateredAt = plotState.lastWateredTime or 0,
            growthTime = growthTime,
            waterTime = waterTime,
            deathTime = deathTime,
            -- Water cooldown data
            lastWaterActionTime = plotState.lastWaterActionTime or 0,
            waterCooldownSeconds = GameConfig.Settings.waterCooldown or 30,
            -- Weather and boost data
            weatherEffects = weatherEffects,
            onlineBonus = true, -- Player is online if they're opening the UI
            variation = plotState.variation or "normal"
        }
        
        remotes.openPlotUI:FireClient(player, clientData)
        log.info("📋 Sent plot UI open request to", player.Name, "for plot", plotId)
    else
        log.warn("❌ Could not find plot state for plot", plotId)
    end
end

return RemoteManager