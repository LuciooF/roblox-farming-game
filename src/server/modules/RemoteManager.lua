-- Remote Event Management Module  
-- Handles all client-server communication and RemoteEvent setup

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(script.Parent.Logger)
local GameConfig = require(script.Parent.GameConfig)
local PlayerDataManager = require(script.Parent.PlayerDataManager)
local PlotManager = require(script.Parent.PlotManager)
local GamepassManager = require(script.Parent.GamepassManager)
local AutomationSystem = require(script.Parent.AutomationSystem)
-- -- local NotificationManager = require(script.Parent.NotificationManager) -- REMOVED
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
    
    local clearPlotsRemote = Instance.new("RemoteEvent")
    clearPlotsRemote.Name = "ClearAllPlotDisplays"
    clearPlotsRemote.Parent = remoteFolder
    
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
    
    local debugAuthFunction = Instance.new("RemoteFunction")
    debugAuthFunction.Name = "CheckDebugAuth"
    debugAuthFunction.Parent = remoteFolder
    
    local musicRemote = Instance.new("RemoteEvent")
    musicRemote.Name = "MusicPreference"
    musicRemote.Parent = remoteFolder
    
    local gamepassPurchaseRemote = Instance.new("RemoteEvent")
    gamepassPurchaseRemote.Name = "GamepassPurchase"
    gamepassPurchaseRemote.Parent = remoteFolder
    
    local gamepassDataRemote = Instance.new("RemoteEvent")
    gamepassDataRemote.Name = "GamepassData"
    gamepassDataRemote.Parent = remoteFolder
    
    local farmActionRemote = Instance.new("RemoteEvent")
    farmActionRemote.Name = "FarmAction"
    farmActionRemote.Parent = remoteFolder
    
    local getFarmIdRemote = Instance.new("RemoteEvent")
    getFarmIdRemote.Name = "GetFarmId"
    getFarmIdRemote.Parent = remoteFolder
    
    local characterReadyRemote = Instance.new("RemoteEvent")
    characterReadyRemote.Name = "CharacterReady"
    characterReadyRemote.Parent = remoteFolder
    
    local showRewardRemote = Instance.new("RemoteEvent")
    showRewardRemote.Name = "ShowReward"
    showRewardRemote.Parent = remoteFolder
    
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
    remotes.clearAllPlotDisplays = clearPlotsRemote
    remotes.buyPlot = buyPlotRemote
    remotes.plotUpdate = plotUpdateRemote
    remotes.characterTracking = characterTrackingRemote
    remotes.interactionFailure = interactionFailureRemote
    remotes.clearDeadPlant = clearDeadPlantRemote
    remotes.cutPlant = cutPlantRemote
    remotes.weather = weatherRemote
    remotes.debug = debugRemote
    remotes.gamepassPurchase = gamepassPurchaseRemote
    remotes.gamepassData = gamepassDataRemote
    remotes.farmAction = farmActionRemote
    remotes.getFarmId = getFarmIdRemote
    remotes.characterReady = characterReadyRemote
    remotes.MusicPreference = musicRemote
    remotes.showReward = showRewardRemote
    
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
    debugAuthFunction.OnServerInvoke = RemoteManager.checkDebugAuthorization
    gamepassPurchaseRemote.OnServerEvent:Connect(RemoteManager.onGamepassPurchase)
    gamepassDataRemote.OnServerEvent:Connect(RemoteManager.onGamepassDataRequest)
    farmActionRemote.OnServerEvent:Connect(RemoteManager.onFarmAction)
    getFarmIdRemote.OnServerEvent:Connect(RemoteManager.onGetFarmId)
    musicRemote.OnServerEvent:Connect(RemoteManager.onMusicPreference)
    
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
    local GamepassService = require(script.Parent.GamepassService)
    playerData.gamepasses = GamepassService.getGamepassDataForClient(player)
    
    -- Ensure settings are included (for music preferences)
    if not playerData.settings then
        playerData.settings = { musicEnabled = true }
    end
    
    log.debug("Syncing player data to", player.Name, "- Money:", playerData.money)
    remotes.sync:FireClient(player, playerData)
    log.debug("Player data sync sent successfully")
end

-- Send reward to client (triggers nice reward animation)
function RemoteManager.sendReward(player, rewardType, amount, description)
    if not remotes.showReward then
        log.warn("Show reward remote not found!")
        return
    end
    
    local rewardData = {
        type = rewardType,
        amount = amount,
        description = description
    }
    
    log.info("Sending reward to", player.Name, "- Type:", rewardType, "Amount:", amount)
    remotes.showReward:FireClient(player, rewardData)
end

-- Helper function for money rewards
function RemoteManager.sendMoneyReward(player, amount, description)
    RemoteManager.sendReward(player, "money", amount, description)
end

-- Remote event handlers
function RemoteManager.onPlantCrop(player, plotId, cropType)
    local success, message = PlotManager.plantCrop(player, plotId, cropType)
    if success then
        RemoteManager.syncPlayerData(player)
    end
--     NotificationManager.sendNotification(player, message)
end

function RemoteManager.onWaterPlant(player, plotId)
    log.info("Water request received from", player.Name, "for plot", plotId)
    local success, message = PlotManager.waterPlant(player, plotId)
    log.info("Water result:", success, message)
--     NotificationManager.sendNotification(player, message)
end

function RemoteManager.onHarvestCrop(player, plotId)
    local success, message, totalYield = PlotManager.harvestCrop(player, plotId)
    if success then
        RemoteManager.syncPlayerData(player)
    end
--     NotificationManager.sendNotification(player, message)
end

function RemoteManager.onHarvestAllCrops(player, plotId)
    local success, message = PlotManager.harvestAllCrops(player, plotId)
    if success then
        RemoteManager.syncPlayerData(player)
    end
--     NotificationManager.sendNotification(player, message)
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
        -- Cut plants (no more dead plants)
        print("🔄 FARMACTION CLEAR called for plotId:", plotId, "player:", player.Name)
        success, message = PlotManager.cutPlant(player, plotId)
        if success then
            RemoteManager.syncPlayerData(player)
            
            -- Explicitly update the plot visual to ensure icon is removed
            local WorldBuilder = require(script.Parent.Parent.WorldBuilder)
            local plot = WorldBuilder.getPlotById(plotId)
            if plot then
                print("🔄 Updating plot visual for cut plant - plotId:", plotId, "plot:", plot.Name)
                WorldBuilder.updatePlotState(plot, "empty", "", "normal")
                
                -- Double-check that Plant was removed
                local existingPlant = plot:FindFirstChild("Plant")
                if existingPlant then
                    print("⚠️  Plant visual still exists after updatePlotState, manually destroying:", existingPlant.Name)
                    existingPlant:Destroy()
                else
                    print("✅ Plant visual successfully removed")
                end
            else
                print("❌ Could not find plot", plotId, "for visual update")
            end
        end
    else
        log.warn("Unknown plot action:", action)
        message = "Unknown action"
    end
    
    if message then
--         NotificationManager.sendNotification(player, message)
    end
end

function RemoteManager.onCutPlant(player, plotId)
    local success, message = PlotManager.cutPlant(player, plotId)
    if success then
        RemoteManager.syncPlayerData(player)
        
        -- Explicitly update the plot visual to ensure icon is removed
        local WorldBuilder = require(script.Parent.Parent.WorldBuilder)
        local plot = WorldBuilder.getPlotById(plotId)
        if plot then
            WorldBuilder.updatePlotState(plot, "empty", "", "normal")
        end
    end
--     NotificationManager.sendNotification(player, message)
end

function RemoteManager.onBuyItem(player, itemType, itemName, cost)
    local playerData = PlayerDataManager.getPlayerData(player)
    
    -- Use server-side pricing for validation with rebirth scaling
    local baseCost = GameConfig.Plants[itemName] and GameConfig.Plants[itemName].seedCost or cost
    local rebirthMultiplier = GameConfig.Rebirth.getCropMultiplier(playerData.rebirths or 0)
    local actualCost = math.floor(baseCost * rebirthMultiplier)
    
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
--             NotificationManager.sendSuccess(player, message)
        end
    else
--         NotificationManager.sendError(player, "💰 Need $" .. actualCost .. " for " .. itemName .. " crop")
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
        
        -- Check for variation prefixes (if variations exist)
        if GameConfig.CropVariations then
            for variationName, variationData in pairs(GameConfig.CropVariations) do
                if variationName ~= "normal" and cropType:find(variationData.prefix) then
                    baseCropType = cropType:gsub(variationData.prefix, "")
                    variationMultiplier = variationData.multiplier
                    break
                end
            end
        end
        
        local basePrice = GameConfig.Plants[baseCropType] and GameConfig.Plants[baseCropType].basePrice or 10
        local rebirthMultiplier = GameConfig.Rebirth.getCropMultiplier(playerData.rebirths)
        
        -- Apply gamepass money multiplier
        local GamepassService = require(script.Parent.GamepassService)
        local gamepassMultiplier = GamepassService.getMoneyMultiplier(player)
        
        local totalPrice = math.floor(basePrice * variationMultiplier * amount * rebirthMultiplier * gamepassMultiplier)
        
        PlayerDataManager.removeFromInventory(player, "crops", cropType, amount)
        PlayerDataManager.addMoney(player, totalPrice)
        
        RemoteManager.syncPlayerData(player)
        
        -- Play sell sound
        SoundManager.playSellSound()
        
        -- Check tutorial progress
        local TutorialManager = require(script.Parent.TutorialManager)
        TutorialManager.checkGameAction(player, "sell_crops")
        
        local message = "💰 Sold " .. amount .. " " .. cropType .. " (+$" .. totalPrice .. ")"
        local multiplierText = ""
        if playerData.rebirths > 0 and gamepassMultiplier > 1 then
            multiplierText = " (" .. rebirthMultiplier .. "x rebirth + " .. gamepassMultiplier .. "x gamepass)"
        elseif playerData.rebirths > 0 then
            multiplierText = " (" .. rebirthMultiplier .. "x rebirth)"
        elseif gamepassMultiplier > 1 then
            multiplierText = " (" .. gamepassMultiplier .. "x gamepass)"
        end
--         NotificationManager.sendMoney(player, message .. multiplierText)
    else
--         NotificationManager.sendError(player, "❌ Not enough " .. cropType .. " to sell!")
    end
end

function RemoteManager.onPerformRebirth(player)
    local success, result = PlayerDataManager.performRebirth(player)
    if success then
        RemoteManager.syncPlayerData(player)
        
        -- Force a complete farm refresh to update all plot visuals after rebirth
        local FarmManager = require(script.Parent.FarmManager)
        local farmId = FarmManager.getPlayerFarm(player.UserId)
        if farmId then
            log.info("🔄 Refreshing all plots after rebirth for", player.Name)
            -- Call onFarmAssigned to refresh all plot visuals with new ownership
            FarmManager.onFarmAssigned(farmId, player)
            
            -- Explicitly clear all plot visuals to remove any lingering text/displays
            local WorldBuilder = require(script.Parent.Parent.WorldBuilder)
            local playerData = PlayerDataManager.getPlayerData(player)
            if playerData and playerData.plots then
                for plotId, plotData in pairs(playerData.plots) do
                    local plot = WorldBuilder.getPlotById(plotId)
                    if plot then
                        -- Force plot to empty state to clear all visual elements
                        WorldBuilder.updatePlotState(plot, "empty", "", "normal")
                    end
                end
            end
            
            -- Send client-side clear command to reset countdown displays
            local clearPlotsRemote = remotes.clearAllPlotDisplays
            if clearPlotsRemote then
                clearPlotsRemote:FireClient(player)
            end
        end
        
        -- Play special rebirth sound immediately
        SoundManager.playRebirthSound()
--         NotificationManager.sendRebirthNotification(player, result)
        
        -- Make potentially slow operations async to prevent lag
        spawn(function()
            -- Check tutorial progress for first rebirth
            local TutorialManager = require(script.Parent.TutorialManager)
            TutorialManager.checkGameAction(player, "perform_rebirth")
            
            -- Update player's rank display (async)
            local RankDisplayManager = require(script.Parent.RankDisplayManager)
            RankDisplayManager.updatePlayerRank(player)
            
            -- Check for rank up and announce in chat (async)
            local ChatManager = require(script.Parent.ChatManager)
            ChatManager.checkRankUp(player)
            
            -- Update farm nameplate with new rank (async) - nameplate only, don't recreate character
            if farmId then
                log.info("🏠 Updating farm nameplate for", player.Name, "on farm", farmId)
                local WorldBuilder = require(script.Parent.Parent.WorldBuilder)
                WorldBuilder.updateFarmNameOnly(farmId, player.Name, player)
            else
                log.warn("🏠 No farm found for", player.Name, "- cannot update nameplate")
            end
            
            log.debug("🔄 Async rebirth operations completed for", player.Name)
        end)
    else
        local moneyRequired = GameConfig.Rebirth.getMoneyRequirement(PlayerDataManager.getPlayerData(player).rebirths)
--         NotificationManager.sendError(player, "💰 Need $" .. moneyRequired .. " to rebirth!")
    end
end

function RemoteManager.onTogglePremium(player)
    -- This would be updated to handle specific gamepass toggles
--     NotificationManager.sendWarning(player, "👑 Use individual gamepass toggles in Premium panel!")
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
    
--     NotificationManager.sendAutomationNotification(player, success, message, details)
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
--             NotificationManager.sendSuccess(player, message)
            log.debug("Player", player.Name, "bought slot", 9 + playerData.extraSlots, "for $" .. slotCost)
        end
    else
--         NotificationManager.sendError(player, "💰 Need $" .. slotCost .. " to buy a new inventory slot")
    end
end

-- Buy plot handler
function RemoteManager.onBuyPlot(player, plotId)
    local FarmManager = require(script.Parent.FarmManager)
    local farmId, plotIndex = FarmManager.getFarmAndPlotFromGlobalId(plotId)
    
    -- Check if player owns this farm
    if not FarmManager.doesPlayerOwnFarm(player.UserId, farmId) then
--         NotificationManager.sendError(player, "❌ You can only buy plots on your own farm!")
        return
    end
    
    local success, message, purchasedPlotIndex = PlayerDataManager.purchasePlot(player, plotIndex)
    
    if success then
        -- Initialize the newly purchased plot
        PlotManager.initializePlot(plotId, player.UserId, player)
        
        -- Send updated player data to client
        RemoteManager.syncPlayerData(player)
        
        -- Get the updated plot state and update visual
        local plotState = PlotManager.getPlotState(plotId)
        if plotState then
            -- Update the visual state in the world
            local WorldBuilder = require(script.Parent.Parent.WorldBuilder)
            local plot = WorldBuilder.getPlotById(plotId)
            if plot then
                WorldBuilder.updatePlotState(plot, "empty", "", nil)
            end
            
            -- Send plot update to all clients
            RemoteManager.sendPlotUpdate(plotId, plotState)
        end
        
--         NotificationManager.sendSuccess(player, "🔓 " .. message)
        log.info("Player", player.Name, "purchased plot", plotIndex)
        
        -- Check tutorial progress
        local TutorialManager = require(script.Parent.TutorialManager)
        TutorialManager.checkGameAction(player, "buy_plot")
    else
--         NotificationManager.sendError(player, "❌ " .. message)
        log.debug("Player", player.Name, "failed to purchase plot", plotIndex, ":", message)
    end
end

-- Clear dead plant handler (deprecated - no more dead plants)
function RemoteManager.onClearDeadPlant(player, plotId)
    -- Redirect to cut plant instead
    local success, message = PlotManager.cutPlant(player, plotId)
    if success then
--         NotificationManager.sendSuccess(player, "🗑️ " .. message)
    else
--         NotificationManager.sendError(player, "❌ " .. message)
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
    
    -- Update crop accumulation before sending data to ensure it's current
    if plotState and plotState.state == "ready" then
        PlotManager.updateCropAccumulation(plotId, plotState)
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
            
            if plotState.seedType and plotState.seedType ~= "" then
                local plantConfig = GameConfig.Plants[plotState.seedType]
                if plantConfig then
                    growthTime = plantConfig.growthTime or 60
                    waterTime = plantConfig.waterTime or 30
                end
            end
            
            local ownerUpdateData = {
                plotId = plotId,
                state = plotState.state,
                seedType = plotState.seedType,
                plantedTime = plotState.plantedTime,
                plantedAt = plotState.plantedTime, -- Backward compatibility
                lastWateredTime = plotState.lastWateredTime or plotState.wateredTime or 0,
                lastWateredAt = plotState.lastWateredTime or plotState.wateredTime or 0, -- Backward compatibility
                growthTime = growthTime,
                waterTime = waterTime,
                variation = plotState.variation,
                isOwner = true,
                harvestCount = plotState.harvestCount or 0,
                maxHarvests = plotState.maxHarvests or 0,
                accumulatedCrops = plotState.accumulatedCrops or 0,
                wateredCount = plotState.wateredCount or 0,
                waterNeeded = plotState.waterNeeded or 0,
                
                -- Growth calculator fields
                lastUpdateTime = plotState.lastUpdateTime or tick(),
                lastReadyTime = plotState.lastReadyTime or 0,
                baseYieldRate = plotState.baseYieldRate or 1,
                wateredTime = plotState.wateredTime or 0,
                
                -- Maintenance watering data
                needsMaintenanceWater = plotState.needsMaintenanceWater or false,
                lastMaintenanceWater = plotState.lastMaintenanceWater or 0,
                maintenanceWaterInterval = plotState.maintenanceWaterInterval or 43200
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
--     NotificationManager.onPlayerLeft(player)
    
    -- Clean up selected items
    local playerId = tostring(player.UserId)
    selectedItems[playerId] = nil
    
    log.info("Player left the farm:", player.Name)
end

-- Handle weather data requests
function RemoteManager.onWeatherRequest(player, requestType, weatherName)
    
    if requestType == "current" then
        -- Send current weather data
        RemoteManager.sendWeatherData(player)
    elseif requestType == "force_change" and weatherName then
        -- Debug: Force weather change
        local WeatherSystem = require(script.Parent.WeatherSystem)
        local success = WeatherSystem.forceWeatherChange(weatherName)
        
        
        if success then
            -- Broadcast updated weather to all players
            RemoteManager.broadcastWeatherData()
--             NotificationManager.sendSuccess(player, "🌤️ Weather changed to " .. weatherName .. " (debug)")
        else
--             NotificationManager.sendError(player, "❌ Failed to change weather to " .. weatherName)
        end
    else
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
    end
end

-- Handle gamepass purchase requests
function RemoteManager.onGamepassPurchase(player, gamepassKey)
    log.info("Gamepass purchase requested:", gamepassKey, "by", player.Name)
    
    local GamepassService = require(script.Parent.GamepassService)
    local success, message = GamepassService.promptGamepassPurchase(player, gamepassKey)
    
    if success then
--         NotificationManager.sendSuccess(player, "🚀 " .. message)
        -- Sync player data to update gamepass status on client
        RemoteManager.syncPlayerData(player)
    else
--         NotificationManager.sendError(player, "❌ " .. message)
    end
end

-- Handle gamepass data requests (for prices)
function RemoteManager.onGamepassDataRequest(player)
    log.debug("Gamepass data requested by", player.Name)
    
    local GamepassService = require(script.Parent.GamepassService)
    local gamepassData = GamepassService.getAllGamepassData() -- Now includes icons
    
    -- Send gamepass data to client
    if remotes.gamepassData then
        remotes.gamepassData:FireClient(player, gamepassData)
        log.debug("Sent gamepass data with icons to", player.Name)
    end
end

-- Handle farm actions from PlotUI (plant, water, harvest, clear)
function RemoteManager.onFarmAction(player, action, plotId, ...)
    log.debug("Farm action from", player.Name, ":", action, "on plot", plotId)
    
    if action == "plant" then
        local seedType, quantity = ...
        quantity = quantity or 1
        
        -- Use PlotManager directly for planting
        local success, message = PlotManager.plantCrop(player, plotId, seedType, quantity)
        if success then
            RemoteManager.syncPlayerData(player)
            
            -- Update plot visuals
            local WorldBuilder = require(script.Parent.Parent.WorldBuilder)
            local plot = WorldBuilder.getPlotById(plotId)
            local plotState = PlotManager.getPlotState(plotId)
            if plot and plotState then
                WorldBuilder.updatePlotState(plot, "planted", seedType, plotState.variation)
            end
            
            -- Check tutorial progress
            local TutorialManager = require(script.Parent.TutorialManager)
            TutorialManager.checkGameAction(player, "plant_seed", {seedType = seedType})
        end
--         NotificationManager.sendNotification(player, message)
        
    elseif action == "water" then
        local success, message = PlotManager.waterPlant(player, plotId)
        if success then
            -- Check tutorial progress
            local TutorialManager = require(script.Parent.TutorialManager)
            TutorialManager.checkGameAction(player, "water_plant")
        end
--         NotificationManager.sendNotification(player, message)
        
    elseif action == "harvest" then
        local success, message, totalYield = PlotManager.harvestCrop(player, plotId)
        if success then
            RemoteManager.syncPlayerData(player)
            
            -- Check tutorial progress
            local TutorialManager = require(script.Parent.TutorialManager)
            TutorialManager.checkGameAction(player, "harvest_crop")
        end
--         NotificationManager.sendNotification(player, message)
        
    elseif action == "clear" then
        local success, message = PlotManager.cutPlant(player, plotId)
        if success then
            RemoteManager.syncPlayerData(player)
            
            -- Update plot visuals to remove the plant icon
            local WorldBuilder = require(script.Parent.Parent.WorldBuilder)
            local plot = WorldBuilder.getPlotById(plotId)
            if plot then
                WorldBuilder.updatePlotState(plot, "empty", "", "normal")
            end
        end
--         NotificationManager.sendNotification(player, message)
        
    else
        log.warn("Unknown farm action:", action, "from", player.Name)
--         NotificationManager.sendError(player, "Unknown action: " .. tostring(action))
    end
end

-- Authorized debug users - add player IDs here
local AUTHORIZED_DEBUG_USERS = {
    7273741008, -- Your player ID
    7804278628,
    -- Add more authorized user IDs here as needed
}

-- Check if player is authorized for debug actions
local function isAuthorizedDebugUser(player)
    local userId = player.UserId
    for _, authorizedId in pairs(AUTHORIZED_DEBUG_USERS) do
        if userId == authorizedId then
            return true
        end
    end
    return false
end

-- Check if player is authorized for debug (called by client)
function RemoteManager.checkDebugAuthorization(player)
    return isAuthorizedDebugUser(player)
end

-- Handle debug actions
function RemoteManager.onDebugAction(player, action, data)
    log.info("Debug action", action, "requested by", player.Name, "UserID:", player.UserId)
    
    -- 🔒 SECURITY CHECK: Only allow authorized users
    if not isAuthorizedDebugUser(player) then
        log.warn("🚨 UNAUTHORIZED DEBUG ATTEMPT by", player.Name, "UserID:", player.UserId, "Action:", action)
        -- Silently ignore - don't give feedback to potential exploiters
        return
    end
    
    log.info("✅ Authorized debug action", action, "by", player.Name)
    
    if action == "addRebirth" then
        local success = PlayerDataManager.debugAddRebirth(player)
        if success then
--             NotificationManager.sendSuccess(player, "🐛 Debug: +1 Rebirth added!")
            RemoteManager.syncPlayerData(player)
        else
--             NotificationManager.sendError(player, "❌ Debug: Failed to add rebirth")
        end
        
    elseif action == "resetRebirths" then
        local success = PlayerDataManager.debugResetRebirths(player)
        if success then
--             NotificationManager.sendSuccess(player, "🐛 Debug: Rebirths reset to 0!")
            RemoteManager.syncPlayerData(player)
        else
--             NotificationManager.sendError(player, "❌ Debug: Failed to reset rebirths")
        end
        
    elseif action == "resetDatastore" then
        local success = PlayerDataManager.debugResetDatastore(player)
        if success then
--             NotificationManager.sendSuccess(player, "🐛 Debug: Datastore completely reset!")
            RemoteManager.syncPlayerData(player)
            
            -- Reinitialize tutorial to show first step
            local TutorialManager = require(script.Parent.TutorialManager)
            TutorialManager.initializePlayer(player)
            
            -- Update all plots to reflect new ownership
            local FarmManager = require(script.Parent.FarmManager)
            local farmId = FarmManager.getPlayerFarm(player.UserId)
            if farmId then
                -- Reset all plot states and visuals
                for plotIndex = 1, 30 do
                    local globalPlotId = FarmManager.getGlobalPlotId(farmId, plotIndex)
                    
                    -- Reinitialize the plot with new ownership
                    if PlayerDataManager.isPlotOwned(player, plotIndex) then
                        PlotManager.initializePlot(globalPlotId, player.UserId, player)
                    else
                        PlotManager.initializePlot(globalPlotId, nil, nil)
                    end
                    
                    -- Update visual state
                    local plotState = PlotManager.getPlotState(globalPlotId)
                    if plotState then
                        local WorldBuilder = require(script.Parent.Parent.WorldBuilder)
                        local plot = WorldBuilder.getPlotById(globalPlotId)
                        if plot then
                            WorldBuilder.updatePlotState(plot, plotState.state, plotState.seedType, plotState.variation)
                        end
                        RemoteManager.sendPlotUpdate(globalPlotId, plotState)
                    end
                end
            end
        else
--             NotificationManager.sendError(player, "❌ Debug: Failed to reset datastore")
        end
        
    elseif action == "addMoney" then
        local amount = data or 1000 -- Default to $1000 if no amount specified
        local success = PlayerDataManager.debugAddMoney(player, amount)
        if success then
--             NotificationManager.sendSuccess(player, "🐛 Debug: +$" .. amount .. " added!")
            RemoteManager.syncPlayerData(player)
        else
--             NotificationManager.sendError(player, "❌ Debug: Failed to add money")
        end
        
    elseif action == "checkGamepass" then
        local GamepassService = require(script.Parent.GamepassService)
        local owns2x = GamepassService.playerOwnsGamepassKey(player, "moneyMultiplier")
        local playerData = PlayerDataManager.getPlayerData(player)
        local savedGamepasses = playerData and playerData.gamepasses or {}
        
        log.info("Debug gamepass check for", player.Name)
        log.info("- MarketplaceService says owns 2x Money:", owns2x)
        log.info("- PlayerData.gamepasses:", savedGamepasses)
        log.info("- Stored moneyMultiplier:", savedGamepasses.moneyMultiplier)
        
--         NotificationManager.sendSuccess(player, "🐛 Debug: Check logs for gamepass info")
        
        -- Force refresh gamepass data
        GamepassService.initializePlayerGamepassOwnership(player)
        RemoteManager.syncPlayerData(player)
        
    elseif action == "forceGamepass" then
        -- Manually give gamepass for testing (Studio only)
        local RunService = game:GetService("RunService")
        if RunService:IsStudio() then
            -- Simulate gamepass purchase completion
            GamepassService.onPurchaseFinished(player, 1285355447, true)
            log.info("Debug: Simulated 2x Money gamepass purchase for", player.Name)
--             NotificationManager.sendSuccess(player, "🐛 Debug: Simulated gamepass purchase!")
        else
--             NotificationManager.sendError(player, "❌ Debug commands only work in Studio")
        end
        
    elseif action == "addProductionBoost" then
        local boostPercent = data or 100
        local playerData = PlayerDataManager.getPlayerData(player)
        if playerData then
            -- Add debug boost to player data
            playerData.debugProductionBoost = (playerData.debugProductionBoost or 0) + boostPercent
            -- Data is automatically saved by ProfileService
--             NotificationManager.sendSuccess(player, "🚀 Debug: +" .. boostPercent .. "% production boost added!")
            RemoteManager.syncPlayerData(player)
            log.info("Added " .. boostPercent .. "% production boost to", player.Name, "Total boost:", playerData.debugProductionBoost)
        else
--             NotificationManager.sendError(player, "❌ Debug: Failed to add production boost")
        end
        
    elseif action == "removeProductionBoost" then
        local boostPercent = data or 100
        local playerData = PlayerDataManager.getPlayerData(player)
        if playerData then
            -- Remove debug boost from player data
            playerData.debugProductionBoost = math.max(0, (playerData.debugProductionBoost or 0) - boostPercent)
            -- Data is automatically saved by ProfileService
--             NotificationManager.sendSuccess(player, "🚀 Debug: -" .. boostPercent .. "% production boost removed!")
            RemoteManager.syncPlayerData(player)
            log.info("Removed " .. boostPercent .. "% production boost from", player.Name, "Total boost:", playerData.debugProductionBoost)
        else
--             NotificationManager.sendError(player, "❌ Debug: Failed to remove production boost")
        end
        
    else
        log.warn("Unknown debug action:", action)
--         NotificationManager.sendError(player, "❌ Debug: Unknown action: " .. tostring(action))
    end
end


-- Send plot UI open request to client
function RemoteManager.openPlotUI(player, plotId)
    if not remotes.openPlotUI then return end
    
    -- Check if this plot is owned by the player
    local FarmManager = require(script.Parent.FarmManager)
    local farmId, plotIndex = FarmManager.getFarmAndPlotFromGlobalId(plotId)
    
    -- Verify this is the player's farm
    if not FarmManager.doesPlayerOwnFarm(player.UserId, farmId) then
        return -- Can't interact with other players' plots
    end
    
    -- Check if player owns this specific plot
    if not PlayerDataManager.isPlotOwned(player, plotIndex) then
        -- Plot is not owned - attempt to purchase it
        RemoteManager.onBuyPlot(player, plotId)
        return
    end
    
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
            -- Water cooldown data
            lastWaterActionTime = plotState.lastWaterActionTime or 0,
            waterCooldownSeconds = GameConfig.Settings.waterCooldown or 30,
            -- Weather and boost data
            weatherEffects = weatherEffects,
            onlineBonus = true, -- Player is online if they're opening the UI
            variation = plotState.variation or "normal",
            
            -- Maintenance watering data
            needsMaintenanceWater = plotState.needsMaintenanceWater or false,
            lastMaintenanceWater = plotState.lastMaintenanceWater or 0,
            maintenanceWaterInterval = plotState.maintenanceWaterInterval or 43200
        }
        
        remotes.openPlotUI:FireClient(player, clientData)
    else
        log.warn("❌ Could not find plot state for plot", plotId)
    end
end

-- Handle farm ID request from client
function RemoteManager.onGetFarmId(player)
    local FarmManager = require(script.Parent.FarmManager)
    local farmId = FarmManager.getPlayerFarmId(player.UserId)
    
    log.warn("🎯 Client requested farm ID for", player.Name, "- returning:", farmId or "nil")
    
    remotes.getFarmId:FireClient(player, farmId)
end

-- Send character ready signal to client
function RemoteManager.sendCharacterReady(player)
    if remotes.characterReady then
        remotes.characterReady:FireClient(player)
        log.info("✅ Sent character ready signal to:", player.Name)
    end
end

-- Handle music preference changes
function RemoteManager.onMusicPreference(player, enabled)
    local success = PlayerDataManager.setMusicEnabled(player, enabled)
    if success then
        log.debug("Set music preference for", player.Name, "to", enabled)
    else
        log.warn("Failed to set music preference for", player.Name)
    end
end

return RemoteManager