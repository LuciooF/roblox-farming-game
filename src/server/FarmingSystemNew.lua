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
local TutorialManager = require(script.Parent.modules.TutorialManager)
local FarmManager = require(script.Parent.modules.FarmManager)
local WeatherSystem = require(script.Parent.modules.WeatherSystem)
local FarmEnvironment = require(script.Parent.modules.FarmEnvironment)

-- Disable auto-spawning so we can control when players spawn
Players.CharacterAutoLoads = false
local ConfigManager = require(script.Parent.modules.ConfigManager)

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
    
    -- Initialize PlayerDataManager with ProfileStore first
    -- Initialize configuration system
    ConfigManager.initialize()
    
    PlayerDataManager.initialize()
    
    -- Initialize RemoteEvents
    RemoteManager.initialize()
    
    -- Initialize sound system
    SoundManager.initialize()
    
    -- Initialize farm management system
    FarmManager.initialize()
    
    -- Initialize weather system
    WeatherSystem.initialize()
    
    -- Build the farm world
    local success, farm = pcall(function()
        return WorldBuilder.buildFarm()
    end)
    
    if not success then
        log.error("Failed to build farm:", farm)
        return
    end
    
    -- Plot interactions are now set up per-farm when players join (in FarmManager.onFarmAssigned)
    -- FarmingSystem.setupPlotInteractions()
    
    -- Set up NPC interactions  
    FarmingSystem.setupNPCInteractions()
    
    -- Start the main game loop
    FarmingSystem.startMainLoop()
    
    -- Initialize farm environment system after everything else is ready
    -- TEMPORARILY DISABLED - causing spawn issues
    -- log.info("🚀 About to initialize FarmEnvironment...")
    -- FarmEnvironment.initialize()
    -- log.info("🚀 FarmEnvironment initialization complete")
    
    log.info("New Modular Farming System: Ready!")
end

-- Setup ProximityPrompt interactions for plots (now handled by WorldBuilder)
function FarmingSystem.setupPlotInteractions()
    -- Plot interactions are now set up in WorldBuilder.setupPlotComponents()
    -- This includes separate plant and water interactions with water hoses
    log.info("Plot interactions are set up by WorldBuilder during plot creation")
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

-- Handle single plot action based on current state
function FarmingSystem.handlePlotAction(player, plotId)
    -- Get current plot state to determine appropriate action
    local plotState = PlotManager.getPlotState(plotId)
    if not plotState then 
        log.warn("No plot state found for plotId", plotId)
        return 
    end
    
    log.debug("handlePlotAction for plot", plotId, "state:", plotState.state, "player:", player.Name)
    
    -- Route to appropriate handler based on current state
    if plotState.state == "empty" then
        log.debug("Routing to plant interaction for empty plot")
        FarmingSystem.handlePlantInteraction(player, plotId)
    elseif plotState.state == "planted" or plotState.state == "growing" then
        log.debug("Routing to water interaction for planted/growing plot")
        FarmingSystem.handleWaterInteraction(player, plotId)
    elseif plotState.state == "watered" then
        -- For watered plots, allow planting more (stacking) since they're growing
        log.debug("Routing to plant interaction for watered plot (stacking)")
        FarmingSystem.handlePlantInteraction(player, plotId)
    elseif plotState.state == "ready" then
        log.debug("Routing to harvest interaction for ready plot")
        FarmingSystem.handleHarvestInteraction(player, plotId)
    elseif plotState.state == "dead" then
        log.debug("Routing to clear dead plant interaction")
        FarmingSystem.handleClearDeadPlantInteraction(player, plotId)
    else
        log.warn("Unknown plot state:", plotState.state, "for plot", plotId)
        NotificationManager.sendError(player, "❌ Cannot interact with this plot right now")
    end
end

-- Handle plot interactions via ProximityPrompt
function FarmingSystem.handlePlantInteraction(player, plotId)
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return end
    
    -- Get the player's selected item from hotbar
    local selectedItem = RemoteManager.getSelectedItem(player)
    local selectedCrop = nil
    
    -- Use selected crop if it's a crop and available
    if selectedItem and selectedItem.type == "crop" then
        local cropCount = playerData.inventory.crops[selectedItem.name] or 0
        if cropCount > 0 then
            selectedCrop = selectedItem.name
        end
    end
    
    -- Fallback to first available crop if no valid selection
    if not selectedCrop then
        for cropType, count in pairs(playerData.inventory.crops) do
            if count > 0 then
                selectedCrop = cropType
                break
            end
        end
    end
    
    if not selectedCrop then
        NotificationManager.sendCenterNotification(player, "🌱 No crops available to plant!\nHarvest some crops first or buy from shop.", "error")
        -- Send interaction failure to client for prediction rollback
        RemoteManager.sendInteractionFailure(player, plotId, "plant", "no_crops")
        return
    end
    
    local success, message = PlotManager.plantCrop(player, plotId, selectedCrop)
    if success then
        RemoteManager.syncPlayerData(player)
        
        -- Update plot visuals with variation FIRST
        local plot = WorldBuilder.getPlotById(plotId)
        local plotState = PlotManager.getPlotState(plotId)
        if plot and plotState then
            log.trace("Updating plot visual - plotId:", plotId, "seed:", selectedCrop, "variation:", plotState.variation)
            WorldBuilder.updatePlotState(plot, "planted", selectedCrop, plotState.variation)
            -- Play plant sound at plot location
            -- SoundManager.playPlantSound(plot.Position)
        else
            log.error("Failed to get plot or plot state for visual update. Plot:", plot ~= nil, "PlotState:", plotState ~= nil)
        end
        
        -- Check tutorial progress AFTER visual update
        TutorialManager.checkGameAction(player, "plant_seed")
    else
        -- Send interaction failure to client for prediction rollback
        RemoteManager.sendInteractionFailure(player, plotId, "plant", "plot_manager_failure")
    end
    
    -- Use appropriate notification type based on success
    if success then
        NotificationManager.sendSuccess(player, "🌱 " .. message)
    else
        -- Use center notification for critical gameplay errors
        if message:find("crops") or message:find("locked") or message:find("different crop") or message:find("ownership") then
            NotificationManager.sendCenterNotification(player, "❌ " .. message, "error")
        else
            NotificationManager.sendError(player, "❌ " .. message)
        end
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

function FarmingSystem.handleClearDeadPlantInteraction(player, plotId)
    local success, message = PlotManager.clearDeadPlant(player, plotId)
    
    if success then
        -- Update plot visual to empty state
        local plot = WorldBuilder.getPlotById(plotId)
        if plot then
            WorldBuilder.updatePlotState(plot, "empty", "")
            -- Play cleanup sound at plot location
            -- SoundManager.playCleanupSound(plot.Position)
        end
        NotificationManager.sendSuccess(player, "🗑️ " .. message)
    else
        NotificationManager.sendError(player, "❌ " .. message)
    end
end

-- Main game loop for growth monitoring and countdown updates
function FarmingSystem.startMainLoop()
    -- Growth monitoring loop (less frequent for performance)
    spawn(function()
        while true do
            local success, err = pcall(function()
                wait(5) -- Check every 5 seconds for growth events
                
                -- Update plot growth monitoring
                local eventType, eventData = PlotManager.updateGrowthMonitoring()
                
                -- Handle growth events
                if eventType == "plant_died" then
                    local deathInfo = eventData.deathInfo
                    NotificationManager.sendPlantDeathNotification(deathInfo.ownerId, deathInfo.seedType, deathInfo.reason)
                    
                    -- Update plot visuals to show dead state
                    local plot = WorldBuilder.getPlotById(eventData.plotId)
                    if plot then
                        WorldBuilder.updatePlotState(plot, "dead", deathInfo.seedType)
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
            end)
            
            if not success then
                log.error("Growth monitoring loop error:", err)
                wait(10) -- Longer wait on error to prevent spam
            end
        end
    end)
    
end


-- Player connection handlers
function FarmingSystem.onPlayerJoined(player)
    log.info("🔵 Player joining:", player.Name)
    
    -- Initialize remotes immediately (for loading screen communication)
    log.info("🔵 Initializing remotes for:", player.Name)
    RemoteManager.onPlayerJoined(player)
    
    -- Load player data with ProfileStore (this takes 3-4 seconds)
    log.info("🔵 Loading player data for:", player.Name)
    PlayerDataManager.onPlayerJoined(player)
    log.info("🔵 Player data loaded for:", player.Name)
    
    -- Assign farm after data is loaded
    log.info("🔵 Assigning farm for:", player.Name)
    local farmId = FarmManager.onPlayerJoined(player)
    log.info("🔵 Farm", farmId, "assigned to:", player.Name)
    
    -- Sync the real data once loaded
    log.info("🔵 Syncing data for:", player.Name)
    RemoteManager.syncPlayerData(player)
    log.info("🔵 Data synced for:", player.Name)
    
    -- Connect respawn handler before first spawn
    player.CharacterAdded:Connect(FarmingSystem.onCharacterAdded)
    
    -- NOW spawn the character after everything is ready
    if farmId then
        log.info("Farm assigned, spawning player:", player.Name, "at farm", farmId)
        player:LoadCharacter()
    else
        log.error("Failed to assign farm for player:", player.Name)
        -- Still spawn but at default location
        player:LoadCharacter()
    end
end

function FarmingSystem.onPlayerLeft(player)
    -- Clean up farm assignment first
    FarmManager.onPlayerLeaving(player)
    -- Handle remote cleanup
    RemoteManager.onPlayerLeft(player)
    -- Release ProfileStore profile last
    PlayerDataManager.onPlayerLeaving(player)
end

-- Handle respawning
function FarmingSystem.onCharacterAdded(character)
    local player = Players:GetPlayerFromCharacter(character)
    if not player then return end
    
    -- Wait a frame for character to fully load
    RunService.Heartbeat:Wait()
    
    -- Teleport to farm spawn point
    local farmId = FarmManager.getPlayerFarm(player.UserId)
    if farmId then
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        local farmModel = workspace.PlayerFarms:FindFirstChild("Farm_" .. farmId)
        local spawnPoint = farmModel and farmModel:FindFirstChild("FarmSpawn_" .. farmId)
        if spawnPoint then
            humanoidRootPart.CFrame = spawnPoint.CFrame + Vector3.new(0, 3, 0)
        else
            log.error("No spawn point found for farm", farmId)
        end
    end
end

return FarmingSystem