-- New Modular Farming System
-- Main coordinator that brings all modules together

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Import all modules
local GameConfig = require(script.Parent.modules.GameConfig)
local PlayerDataManager = require(script.Parent.modules.PlayerDataManager)
local PlotManager = require(script.Parent.modules.PlotManager)
local GamepassManager = require(script.Parent.modules.GamepassManager)
local AutomationSystem = require(script.Parent.modules.AutomationSystem)
local NotificationManager = require(script.Parent.modules.NotificationManager)
local RemoteManager = require(script.Parent.modules.RemoteManager)

-- Import WorldBuilder (keeping this for now since it works)
local WorldBuilder = require(script.Parent.WorldBuilder)

local FarmingSystem = {}

-- Initialize the entire system
function FarmingSystem.initialize()
    print("🌱 New Modular Farming System: Initializing...")
    
    -- Initialize RemoteEvents first
    RemoteManager.initialize()
    
    -- Build the farm world
    local success, farm = pcall(function()
        return WorldBuilder.buildFarm()
    end)
    
    if not success then
        warn("Failed to build farm: " .. tostring(farm))
        return
    end
    
    -- Set up plot interactions
    FarmingSystem.setupPlotInteractions()
    
    -- Set up NPC interactions  
    FarmingSystem.setupNPCInteractions()
    
    -- Start the main game loop
    FarmingSystem.startMainLoop()
    
    print("🌱 New Modular Farming System: Ready!")
end

-- Setup ProximityPrompt interactions for plots
function FarmingSystem.setupPlotInteractions()
    local plots = WorldBuilder.getAllPlots()
    
    for _, plot in pairs(plots) do
        local plotIdValue = plot:FindFirstChild("PlotId")
        if plotIdValue then
            local plotId = plotIdValue.Value
            
            -- Initialize plot in PlotManager
            PlotManager.initializePlot(plotId)
            
            -- Connect ProximityPrompts
            local plantPrompt = plot:FindFirstChild("PlantPrompt")
            local waterPrompt = plot:FindFirstChild("WaterPrompt")
            local harvestPrompt = plot:FindFirstChild("HarvestPrompt")
            
            if plantPrompt then
                plantPrompt.Triggered:Connect(function(player)
                    FarmingSystem.handlePlantInteraction(player, plotId)
                end)
            end
            
            if waterPrompt then
                waterPrompt.Triggered:Connect(function(player)
                    FarmingSystem.handleWaterInteraction(player, plotId)
                end)
            end
            
            if harvestPrompt then
                harvestPrompt.Triggered:Connect(function(player)
                    FarmingSystem.handleHarvestInteraction(player, plotId)
                end)
            end
        end
    end
end

-- Setup NPC interactions
function FarmingSystem.setupNPCInteractions()
    local farm = game.Workspace:FindFirstChild("Farm")
    if not farm then return end
    
    -- Merchant interaction
    local merchant = farm:FindFirstChild("Merchant")
    if merchant then
        local sellPrompt = merchant:FindFirstChild("SellAllPrompt")
        if sellPrompt then
            sellPrompt.Triggered:Connect(function(player)
                local success, message, details = AutomationSystem.sellAll(player)
                if success then
                    RemoteManager.syncPlayerData(player)
                end
                NotificationManager.sendAutomationNotification(player, success, message, details)
            end)
        end
    end
    
    -- AutoBot interaction
    local autoBot = farm:FindFirstChild("AutoBot")
    if autoBot then
        local autoPrompt = autoBot:FindFirstChild("AutoPrompt")
        if autoPrompt then
            autoPrompt.Triggered:Connect(function(player)
                local message = GamepassManager.getAutomationMenuText(player)
                NotificationManager.sendNotification(player, message)
            end)
        end
    end
end

-- Handle plot interactions via ProximityPrompt
function FarmingSystem.handlePlantInteraction(player, plotId)
    local playerData = PlayerDataManager.getPlayerData(player)
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
        NotificationManager.sendNotification(player, "You don't have any seeds!")
        return
    end
    
    local success, message = PlotManager.plantSeed(player, plotId, availableSeed)
    if success then
        RemoteManager.syncPlayerData(player)
        
        -- Update plot visuals
        local plot = WorldBuilder.getPlotById(plotId)
        if plot then
            WorldBuilder.updatePlotState(plot, "planted", availableSeed)
        end
    end
    
    NotificationManager.sendNotification(player, message)
end

function FarmingSystem.handleWaterInteraction(player, plotId)
    local success, message = PlotManager.waterPlant(player, plotId)
    
    if success then
        -- Update plot visuals
        local plot = WorldBuilder.getPlotById(plotId)
        local plotState = PlotManager.getPlotState(plotId)
        if plot and plotState then
            WorldBuilder.updatePlotState(plot, plotState.state, plotState.seedType)
        end
    end
    
    NotificationManager.sendNotification(player, message)
end

function FarmingSystem.handleHarvestInteraction(player, plotId)
    local success, message = PlotManager.harvestCrop(player, plotId)
    
    if success then
        RemoteManager.syncPlayerData(player)
        
        -- Update plot visuals
        local plot = WorldBuilder.getPlotById(plotId)
        if plot then
            WorldBuilder.updatePlotState(plot, "empty", "")
        end
    end
    
    NotificationManager.sendNotification(player, message)
end

-- Main game loop for growth monitoring and countdown updates
function FarmingSystem.startMainLoop()
    spawn(function()
        while true do
            wait(1) -- Check every second for real-time countdown updates
            
            -- Update plot growth monitoring
            local eventType, eventData = PlotManager.updateGrowthMonitoring()
            
            -- Handle growth events
            if eventType == "plant_died" then
                local deathInfo = eventData.deathInfo
                NotificationManager.sendPlantDeathNotification(deathInfo.ownerId, deathInfo.seedType, deathInfo.reason)
                
                -- Update plot visuals
                local plot = WorldBuilder.getPlotById(eventData.plotId)
                if plot then
                    WorldBuilder.updatePlotState(plot, "empty", "")
                end
                
            elseif eventType == "plant_ready" then
                -- Update plot visuals
                local plot = WorldBuilder.getPlotById(eventData.plotId)
                if plot then
                    WorldBuilder.updatePlotState(plot, "ready", eventData.seedType)
                end
            end
            
            -- Update countdown displays
            FarmingSystem.updateCountdownDisplays()
        end
    end)
end

-- Update all countdown displays
function FarmingSystem.updateCountdownDisplays()
    local plots = WorldBuilder.getAllPlots()
    
    for _, plot in pairs(plots) do
        local plotIdValue = plot:FindFirstChild("PlotId")
        if plotIdValue then
            local plotId = plotIdValue.Value
            local countdownGui = plot:FindFirstChild("CountdownDisplay")
            local countdownLabel = countdownGui and countdownGui:FindFirstChild("TextLabel")
            
            if countdownLabel then
                local countdownInfo = PlotManager.getCountdownInfo(plotId)
                if countdownInfo then
                    countdownLabel.Text = countdownInfo.text
                    countdownLabel.TextColor3 = countdownInfo.color
                end
            end
        end
    end
end

-- Player connection handlers
function FarmingSystem.onPlayerJoined(player)
    RemoteManager.onPlayerJoined(player)
end

function FarmingSystem.onPlayerLeft(player)
    RemoteManager.onPlayerLeft(player)
end

return FarmingSystem