-- Remote Event Management Module  
-- Handles all client-server communication and RemoteEvent setup

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(script.Parent.GameConfig)
local PlayerDataManager = require(script.Parent.PlayerDataManager)
local PlotManager = require(script.Parent.PlotManager)
local GamepassManager = require(script.Parent.GamepassManager)
local AutomationSystem = require(script.Parent.AutomationSystem)
local NotificationManager = require(script.Parent.NotificationManager)

local RemoteManager = {}

-- Storage
local remotes = {}

-- Initialize all RemoteEvents
function RemoteManager.initialize()
    print("RemoteManager: Initializing...")
    
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
    
    local togglePremiumRemote = Instance.new("RemoteEvent")
    togglePremiumRemote.Name = "TogglePremium"
    togglePremiumRemote.Parent = remoteFolder
    
    local rebirthRemote = Instance.new("RemoteEvent")
    rebirthRemote.Name = "PerformRebirth"
    rebirthRemote.Parent = remoteFolder
    
    local automationRemote = Instance.new("RemoteEvent")
    automationRemote.Name = "Automation"
    automationRemote.Parent = remoteFolder
    
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
    
    -- Connect events
    plantRemote.OnServerEvent:Connect(RemoteManager.onPlantSeed)
    waterRemote.OnServerEvent:Connect(RemoteManager.onWaterPlant)
    harvestRemote.OnServerEvent:Connect(RemoteManager.onHarvestCrop)
    buyRemote.OnServerEvent:Connect(RemoteManager.onBuyItem)
    sellRemote.OnServerEvent:Connect(RemoteManager.onSellCrop)
    togglePremiumRemote.OnServerEvent:Connect(RemoteManager.onTogglePremium)
    rebirthRemote.OnServerEvent:Connect(RemoteManager.onPerformRebirth)
    automationRemote.OnServerEvent:Connect(RemoteManager.onAutomation)
    
    print("RemoteManager: Ready!")
end

-- Sync player data to client
function RemoteManager.syncPlayerData(player)
    local playerData = PlayerDataManager.getPlayerData(player)
    -- Add gamepass statuses to synced data
    playerData.gamepasses = GamepassManager.getGamepassStatuses(player)
    remotes.sync:FireClient(player, playerData)
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
            
            local config = GameConfig.Plants[itemName]
            local message = "Bought " .. itemName .. " seeds! (" .. config.description .. ")"
            NotificationManager.sendNotification(player, message)
        end
    else
        NotificationManager.sendNotification(player, "Not enough money! Need $" .. actualCost)
    end
end

function RemoteManager.onSellCrop(player, cropType, amount)
    local playerData = PlayerDataManager.getPlayerData(player)
    local available = PlayerDataManager.getInventoryCount(player, "crops", cropType)
    
    if available >= amount then
        local basePrice = GameConfig.Plants[cropType].basePrice
        local rebirthMultiplier = GameConfig.Rebirth.getCropMultiplier(playerData.rebirths)
        local totalPrice = math.floor(basePrice * amount * rebirthMultiplier)
        
        PlayerDataManager.removeFromInventory(player, "crops", cropType, amount)
        PlayerDataManager.addMoney(player, totalPrice)
        
        RemoteManager.syncPlayerData(player)
        
        local message = "Sold " .. amount .. " " .. cropType .. " for $" .. totalPrice
        if playerData.rebirths > 0 then
            message = message .. " (" .. rebirthMultiplier .. "x)"
        end
        NotificationManager.sendNotification(player, message)
    else
        NotificationManager.sendNotification(player, "You don't have enough " .. cropType .. "!")
    end
end

function RemoteManager.onPerformRebirth(player)
    local success, result = PlayerDataManager.performRebirth(player)
    if success then
        RemoteManager.syncPlayerData(player)
        NotificationManager.sendRebirthNotification(player, result)
    else
        local moneyRequired = GameConfig.Rebirth.getMoneyRequirement(PlayerDataManager.getPlayerData(player).rebirths)
        NotificationManager.sendNotification(player, "Need $" .. moneyRequired .. " to rebirth!")
    end
end

function RemoteManager.onTogglePremium(player)
    -- This would be updated to handle specific gamepass toggles
    NotificationManager.sendNotification(player, "Use the individual gamepass toggles in Premium panel!")
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

-- Player connection handlers
function RemoteManager.onPlayerJoined(player)
    local playerData = PlayerDataManager.getPlayerData(player)
    
    -- Wait a bit for client to load
    wait(2)
    RemoteManager.syncPlayerData(player)
    
    print("Player " .. player.Name .. " joined the farm!")
end

function RemoteManager.onPlayerLeft(player)
    print("Player " .. player.Name .. " left the farm!")
end

return RemoteManager