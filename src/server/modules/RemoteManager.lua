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
    
    -- Store references
    remotes.plant = plantRemote
    remotes.water = waterRemote
    remotes.harvest = harvestRemote
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
    
    -- Also create direct references for client access
    remotes.SyncPlayerData = syncRemote
    remotes.TutorialData = tutorialRemote
    remotes.TutorialAction = tutorialActionRemote
    remotes.LogCommand = logCommandRemote
    
    -- Connect events
    plantRemote.OnServerEvent:Connect(RemoteManager.onPlantSeed)
    waterRemote.OnServerEvent:Connect(RemoteManager.onWaterPlant)
    harvestRemote.OnServerEvent:Connect(RemoteManager.onHarvestCrop)
    buyRemote.OnServerEvent:Connect(RemoteManager.onBuyItem)
    sellRemote.OnServerEvent:Connect(RemoteManager.onSellCrop)
    togglePremiumRemote.OnServerEvent:Connect(RemoteManager.onTogglePremium)
    rebirthRemote.OnServerEvent:Connect(RemoteManager.onPerformRebirth)
    automationRemote.OnServerEvent:Connect(RemoteManager.onAutomation)
    tutorialActionRemote.OnServerEvent:Connect(RemoteManager.onTutorialAction)
    logCommandRemote.OnServerEvent:Connect(RemoteManager.onLogCommand)
    selectedItemRemote.OnServerEvent:Connect(RemoteManager.onSelectedItem)
    buySlotRemote.OnServerEvent:Connect(RemoteManager.onBuySlot)
    
    log.info("Remote events ready!")
end

-- Get remotes for other modules
function RemoteManager.getRemotes()
    return remotes
end

-- Sync player data to client
function RemoteManager.syncPlayerData(player)
    local playerData = PlayerDataManager.getPlayerData(player)
    -- Add gamepass statuses to synced data
    playerData.gamepasses = GamepassManager.getGamepassStatuses(player)
    
    log.debug("Syncing player data to", player.Name, "- Money:", playerData.money)
    remotes.sync:FireClient(player, playerData)
    log.debug("Player data sync sent successfully")
end

-- Remote event handlers
function RemoteManager.onPlantSeed(player, plotId, seedType)
    local success, message = PlotManager.plantSeed(player, plotId, seedType)
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
            if itemType == "seeds" then
                local TutorialManager = require(script.Parent.TutorialManager)
                TutorialManager.checkGameAction(player, "buy_seed", {seedType = itemName})
            end
            
            local message = "🛒 Bought " .. itemName .. " seeds (-$" .. actualCost .. ")"
            NotificationManager.sendSuccess(player, message)
        end
    else
        NotificationManager.sendError(player, "💰 Need $" .. actualCost .. " for " .. itemName .. " seeds")
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
    selectedItems[playerId] = itemData -- {type = "seed", name = "wheat"} or nil
    log.debug("Player", player.Name, "selected item:", itemData and (itemData.type .. ":" .. itemData.name) or "none")
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
    local playerData = PlayerDataManager.getPlayerData(player)
    
    -- Wait a bit for client to load
    wait(2)
    RemoteManager.syncPlayerData(player)
    
    -- Initialize tutorial for new players
    local TutorialManager = require(script.Parent.TutorialManager)
    TutorialManager.initializePlayer(player)
    
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

return RemoteManager