-- New Modular Farming System
-- Main coordinator that brings all modules together

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Import all modules
local Logger = require(script.Parent.modules.Logger)
local GameConfig = require(script.Parent.modules.GameConfig)
local PlayerDataManager = require(script.Parent.modules.PlayerDataManager)
local PlotManager = require(script.Parent.modules.PlotManager)
local GamepassManager = require(script.Parent.modules.GamepassManager)
local AutomationSystem = require(script.Parent.modules.AutomationSystem)
local NotificationManager = require(script.Parent.modules.NotificationManager)
local RemoteManager = require(script.Parent.modules.RemoteManager)
local SoundManager = require(script.Parent.modules.SoundManager)
local SeedDropSystem = require(script.Parent.modules.SeedDropSystem)
local TutorialManager = require(script.Parent.modules.TutorialManager)

-- Import WorldBuilder (keeping this for now since it works)
local WorldBuilder = require(script.Parent.WorldBuilder)

local FarmingSystem = {}

-- Get module logger
local log = Logger.getModuleLogger("FarmingSystem")

-- Initialize the entire system
function FarmingSystem.initialize()
    -- Initialize Logger first
    Logger.initialize()
    log.info("New Modular Farming System: Initializing...")
    
    -- Initialize RemoteEvents first
    RemoteManager.initialize()
    
    -- Initialize sound system
    SoundManager.initialize()
    
    -- Initialize seed drop system
    SeedDropSystem.initialize()
    
    -- Build the farm world
    local success, farm = pcall(function()
        return WorldBuilder.buildFarm()
    end)
    
    if not success then
        log.error("Failed to build farm:", farm)
        return
    end
    
    -- Set up plot interactions
    FarmingSystem.setupPlotInteractions()
    
    -- Set up NPC interactions  
    FarmingSystem.setupNPCInteractions()
    
    -- Start the main game loop
    FarmingSystem.startMainLoop()
    
    log.info("New Modular Farming System: Ready!")
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
                
                -- Tutorial: Detect when player approaches a plot for the first time
                plantPrompt.PromptShown:Connect(function(player)
                    log.trace("Player", player.Name, "approached plot", plotId)
                    TutorialManager.checkGameAction(player, "approach_plot")
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
                    -- Play sell sound for automation
                    -- SoundManager.playSellSound()
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
    
    -- Get the player's selected item from hotbar
    local selectedItem = RemoteManager.getSelectedItem(player)
    local selectedSeed = nil
    
    log.debug("Planting - Got selected item:", selectedItem and (selectedItem.type .. ":" .. selectedItem.name) or "none")
    
    -- Use selected seed if it's a seed and available
    if selectedItem and selectedItem.type == "seed" then
        local seedCount = playerData.inventory.seeds[selectedItem.name] or 0
        if seedCount > 0 then
            selectedSeed = selectedItem.name
            log.debug("Player", player.Name, "using selected seed:", selectedSeed)
        else
            log.debug("Player", player.Name, "selected seed not available:", selectedItem.name, "count:", seedCount)
        end
    else
        log.debug("Planting - No valid selected item:", selectedItem and tostring(selectedItem.type) or "nil")
    end
    
    -- Fallback to first available seed if no valid selection
    if not selectedSeed then
        for seedType, count in pairs(playerData.inventory.seeds) do
            if count > 0 then
                selectedSeed = seedType
                log.debug("Player", player.Name, "falling back to first available seed:", selectedSeed)
                break
            end
        end
    end
    
    if not selectedSeed then
        log.debug("Player", player.Name, "has no seeds available")
        NotificationManager.sendError(player, "🌱 No seeds available! Buy some from the shop.")
        return
    end
    
    local success, message = PlotManager.plantSeed(player, plotId, selectedSeed)
    if success then
        RemoteManager.syncPlayerData(player)
        
        -- Update plot visuals with variation FIRST
        local plot = WorldBuilder.getPlotById(plotId)
        local plotState = PlotManager.getPlotState(plotId)
        if plot and plotState then
            log.trace("Updating plot visual - plotId:", plotId, "seed:", selectedSeed, "variation:", plotState.variation)
            WorldBuilder.updatePlotState(plot, "planted", selectedSeed, plotState.variation)
            -- Play plant sound at plot location
            -- SoundManager.playPlantSound(plot.Position)
        else
            log.error("Failed to get plot or plot state for visual update. Plot:", plot ~= nil, "PlotState:", plotState ~= nil)
        end
        
        -- Check tutorial progress AFTER visual update
        TutorialManager.checkGameAction(player, "plant_seed")
    end
    
    -- Use appropriate notification type based on success
    if success then
        NotificationManager.sendSuccess(player, "🌱 " .. message)
    else
        NotificationManager.sendError(player, "❌ " .. message)
    end
end

function FarmingSystem.handleWaterInteraction(player, plotId)
    local success, message = PlotManager.waterPlant(player, plotId)
    
    if success then
        -- Check tutorial progress
        TutorialManager.checkGameAction(player, "water_plant")
        
        -- Update plot visuals with variation
        local plot = WorldBuilder.getPlotById(plotId)
        local plotState = PlotManager.getPlotState(plotId)
        if plot and plotState then
            WorldBuilder.updatePlotState(plot, plotState.state, plotState.seedType, plotState.variation)
            -- Play water sound at plot location
            -- SoundManager.playWaterSound(plot.Position)
        end
        NotificationManager.sendSuccess(player, "💧 " .. message)
    else
        NotificationManager.sendError(player, "❌ " .. message)
    end
end

function FarmingSystem.handleHarvestInteraction(player, plotId)
    local success, message = PlotManager.harvestCrop(player, plotId)
    
    if success then
        RemoteManager.syncPlayerData(player)
        
        -- Check tutorial progress
        TutorialManager.checkGameAction(player, "harvest_crop")
        
        -- Update plot visual to match the actual state after harvest
        local plot = WorldBuilder.getPlotById(plotId)
        local plotState = PlotManager.getPlotState(plotId)
        if plot and plotState then
            -- Use actual plot state (should be "watered" after harvest to start growing again)
            WorldBuilder.updatePlotState(plot, plotState.state, plotState.seedType, plotState.variation)
            -- Play harvest sound at plot location
            -- SoundManager.playHarvestSound(plot.Position)
        end
        NotificationManager.sendMoney(player, "🌾 " .. message)
    else
        NotificationManager.sendError(player, "❌ " .. message)
    end
end

-- Main game loop for growth monitoring and countdown updates
function FarmingSystem.startMainLoop()
    -- Growth monitoring loop (less frequent for performance)
    spawn(function()
        while true do
            wait(5) -- Check every 5 seconds for growth events
            
            -- Update plot growth monitoring
            local eventType, eventData = PlotManager.updateGrowthMonitoring()
            
            -- Handle growth events
            if eventType == "plant_died" then
                local deathInfo = eventData.deathInfo
                NotificationManager.sendPlantDeathNotification(deathInfo.ownerId, deathInfo.seedType, deathInfo.reason)
                
                -- Update plot visuals and play death sound
                local plot = WorldBuilder.getPlotById(eventData.plotId)
                if plot then
                    WorldBuilder.updatePlotState(plot, "empty", "")
                    -- SoundManager.playPlantDeathSound(plot.Position)
                end
                
            elseif eventType == "plant_ready" then
                -- Check tutorial progress
                TutorialManager.checkGameAction(game.Players:GetPlayerByUserId(PlotManager.getPlotState(eventData.plotId).ownerId), "plant_ready")
                
                -- Update plot visuals and play ready sound with variation
                local plot = WorldBuilder.getPlotById(eventData.plotId)
                local plotState = PlotManager.getPlotState(eventData.plotId)
                if plot and plotState then
                    WorldBuilder.updatePlotState(plot, "ready", eventData.seedType, plotState.variation)
                    -- SoundManager.playPlantReadySound(plot.Position)
                end
            end
        end
    end)
    
    -- Countdown display loop (more frequent for smooth UI)
    spawn(function()
        while true do
            wait(1) -- Update countdowns every second for smooth display
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