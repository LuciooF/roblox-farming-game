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
local GamepassService = require(script.Parent.modules.GamepassService)
local AutomationSystem = require(script.Parent.modules.AutomationSystem)
-- -- local NotificationManager = require(script.Parent.modules.NotificationManager) -- REMOVED
local RemoteManager = require(script.Parent.modules.RemoteManager)
local TutorialManager = require(script.Parent.modules.TutorialManager)
local FarmManager = require(script.Parent.modules.FarmManager)
local WeatherSystem = require(script.Parent.modules.WeatherSystem)
local FarmEnvironment = require(script.Parent.modules.FarmEnvironment)
local SoundManager = require(script.Parent.modules.SoundManager)
local RankDisplayManager = require(script.Parent.modules.RankDisplayManager)
local ChatManager = require(script.Parent.modules.ChatManager)
local CodesManager = require(script.Parent.modules.CodesManager)

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
    
    -- Initialize gamepass system
    GamepassService.initialize()
    
    -- Initialize sound system
    SoundManager.initialize()
    
    -- Initialize farm management system
    FarmManager.initialize()
    
    -- Initialize weather system
    WeatherSystem.initialize()
    
    -- Initialize rank display system
    RankDisplayManager.initialize()
    
    -- Initialize chat system with rank integration
    ChatManager.initialize()
    
    -- Initialize chat tracking for any existing players (if server restart)
    for _, existingPlayer in pairs(Players:GetPlayers()) do
        spawn(function()
            wait(2) -- Brief delay to ensure player data is loaded
            ChatManager.initializePlayer(existingPlayer)
        end)
    end
    
    -- Initialize codes system
    CodesManager.initialize()
    
    -- Build the farm world
    local success, farm = pcall(function()
        return WorldBuilder.buildFarm()
    end)
    
    if not success then
        log.info("Failed to build farm:", farm)
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
    
    -- Start regular plot update system
    FarmingSystem.startPlotUpdateLoop()
    
    -- Add debug functions to global scope
    _G.recreateFarms = function()
        return WorldBuilder.recreateFarms()
    end
    
    _G.fixFarmSpawns = function()
        return WorldBuilder.fixFarmSpawnPositions()
    end
    
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
--                 NotificationManager.sendAutomationNotification(player, success, message, details)
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
--                 NotificationManager.sendNotification(player, message)
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
    else
        log.warn("Unknown plot state:", plotState.state, "for plot", plotId)
--         NotificationManager.sendError(player, "❌ Cannot interact with this plot right now")
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
--         NotificationManager.sendCenterNotification(player, "🌱 No crops available to plant!\nHarvest some crops first or buy from shop.", "error")
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
            log.info("Failed to get plot or plot state for visual update. Plot:", plot ~= nil, "PlotState:", plotState ~= nil)
        end
        
        -- Check tutorial progress AFTER visual update (pass seedType for corn check)
        TutorialManager.checkGameAction(player, "plant_seed", {seedType = selectedCrop})
    else
        -- Send interaction failure to client for prediction rollback
        RemoteManager.sendInteractionFailure(player, plotId, "plant", "plot_manager_failure")
    end
    
    -- Use appropriate notification type based on success
    if success then
--         NotificationManager.sendSuccess(player, "🌱 " .. message)
    else
        -- Use center notification for critical gameplay errors
        if message:find("crops") or message:find("locked") or message:find("different crop") or message:find("ownership") then
--             NotificationManager.sendCenterNotification(player, "❌ " .. message, "error")
        else
--             NotificationManager.sendError(player, "❌ " .. message)
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
--         NotificationManager.sendSuccess(player, "💧 " .. message)
    else
--         NotificationManager.sendError(player, "❌ " .. message)
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
--         NotificationManager.sendMoney(player, "🌾 " .. message)
    else
--         NotificationManager.sendError(player, "❌ " .. message)
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
                
                -- Check all plots for maintenance watering needs
                local allPlotStates = PlotManager.getAllPlotStates()
                for plotId, plotState in pairs(allPlotStates) do
                    PlotManager.checkMaintenanceWatering(plotId)
                end
                
                -- Handle growth events
                if eventType == "plant_ready" then
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
                log.info("Growth monitoring loop error:", err)
                wait(10) -- Longer wait on error to prevent spam
            end
        end
    end)
    
end


-- Player connection handlers
function FarmingSystem.onPlayerJoined(player)
    local joinTimestamp = tick()
    log.info("🚨 PLAYER JOINING - NEW OPTIMIZED CODE:", player.Name, "at timestamp:", joinTimestamp)
    
    -- Log all currently connected players for context
    local currentPlayers = {}
    for _, existingPlayer in pairs(game.Players:GetPlayers()) do
        table.insert(currentPlayers, existingPlayer.Name)
    end
    log.info("🔍 Current players when", player.Name, "joins:", table.concat(currentPlayers, ", "))
    
    -- Initialize remotes immediately (for loading screen communication)
    log.info("🔵 Initializing remotes for:", player.Name)
    RemoteManager.onPlayerJoined(player)
    
    -- Connect respawn handler immediately
    player.CharacterAdded:Connect(FarmingSystem.onCharacterAdded)
    
    -- Load data in background and handle farm assignment BEFORE spawning character
    spawn(function()
        -- Handle data loading and farm assignment first, then spawn character at correct location
        
        log.info("🔵 LOADING PLAYER DATA IN BACKGROUND FOR:", player.Name)
        
        -- Start gamepass initialization in parallel (non-blocking)
        local GamepassService = require(script.Parent.modules.GamepassService)
        spawn(function()
            log.info("🎮 STARTING GAMEPASS INIT FOR:", player.Name)
            GamepassService.initializePlayerGamepasses(player)
            log.info("🎮 GAMEPASSES DONE FOR:", player.Name)
        end)
        
        -- Load ProfileStore data (this is the main bottleneck)
        log.info("🔄 CALLING PlayerDataManager.onPlayerJoined FOR:", player.Name)
        PlayerDataManager.onPlayerJoined(player)
        log.info("🔄 PlayerDataManager.onPlayerJoined COMPLETE FOR:", player.Name)
        
        -- Assign farm FIRST, then set spawn location, then spawn character
        local startTime = tick()
        log.info("🔵 STARTING FARM ASSIGNMENT FOR:", player.Name)
        local farmId = FarmManager.assignFarmToPlayer(player)
        local farmAssignTime = tick()
        log.info("🔵 FARM ASSIGNMENT COMPLETED FOR:", player.Name, "ID:", farmId, "in", (farmAssignTime - startTime), "seconds")
        
        if farmId then
            -- Audit spawn locations before setting
            FarmManager.auditSpawnLocations("BEFORE_SETTING_" .. player.Name)
            
            -- Set spawn location BEFORE spawning character
            local spawnSetSuccess = FarmManager.setPlayerSpawn(player, farmId)
            
            if spawnSetSuccess then
                log.info("✅ SPAWN LOCATION SET FOR:", player.Name, "FARM:", farmId)
                
                -- Audit spawn locations after setting
                FarmManager.auditSpawnLocations("AFTER_SETTING_" .. player.Name)
                
                -- Verify spawn location is actually set and wait a moment
                wait(0.2) -- Give Roblox time to register the spawn location change
                
                -- Double-check the spawn location is correct
                local farmModel = workspace.PlayerFarms:FindFirstChild("Farm_" .. farmId)
                local expectedSpawn = farmModel and farmModel:FindFirstChild("FarmSpawn_" .. farmId)
                
                if expectedSpawn and player.RespawnLocation == expectedSpawn then
                    log.info("✅ SPAWN LOCATION VERIFIED FOR:", player.Name, "AT FARM:", farmId)
                else
                    log.warn("⚠️ SPAWN LOCATION NOT PROPERLY SET - Retrying for:", player.Name)
                    -- Retry setting spawn location
                    FarmManager.setPlayerSpawn(player, farmId)
                    wait(0.1)
                    FarmManager.auditSpawnLocations("AFTER_RETRY_" .. player.Name)
                end
                
                -- Final audit before spawning character
                FarmManager.auditSpawnLocations("BEFORE_SPAWN_" .. player.Name)
                
                -- Additional debugging: check what Roblox thinks player's spawn location is
                local currentRespawnLocation = player.RespawnLocation
                if currentRespawnLocation then
                    log.info("🎯 PLAYER", player.Name, "RespawnLocation is set to:", currentRespawnLocation.Name, "at position:", currentRespawnLocation.Position)
                else
                    log.error("🚨 PLAYER", player.Name, "RespawnLocation is NIL! This could be the problem!")
                end
                
                -- NOW spawn character at the correct farm location
                log.info("🚀 SPAWNING CHARACTER AT ASSIGNED FARM FOR:", player.Name, "FARM:", farmId)
            else
                log.error("❌ FAILED TO SET SPAWN LOCATION FOR:", player.Name, "FARM:", farmId)
                -- Still try to spawn character, but it might spawn at default location
            end
            
            -- Character spawn function with immediate teleportation
            local function spawnCharacterSafely()
                local maxRetries = 3
                local retries = 0
                
                while retries < maxRetries do
                    local attemptStart = tick()
                    log.info("🚀 Character spawn attempt", retries + 1, "for:", player.Name, "at farm", farmId)
                    
                    -- Final spawn audit RIGHT before LoadCharacter call
                    FarmManager.auditSpawnLocations("IMMEDIATE_PRE_LOAD_" .. player.Name)
                    
                    local success = pcall(function()
                        log.info("⚡ CALLING LoadCharacter() for:", player.Name, "at timestamp:", tick())
                        player:LoadCharacter()
                        log.info("⚡ LoadCharacter() call completed for:", player.Name, "at timestamp:", tick())
                    end)
                    
                    local loadTime = tick()
                    log.info("⏱️ LoadCharacter() call took:", (loadTime - attemptStart), "seconds")
                    
                    -- Wait a moment for character to actually spawn
                    wait(0.5)
                    local validationTime = tick()
                    log.info("⏱️ Character validation took:", (validationTime - loadTime), "seconds")
                    
                    if success and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        -- Log where player actually spawned
                        local actualSpawnPos = player.Character.HumanoidRootPart.Position
                        log.info("📍 PLAYER", player.Name, "SPAWNED AT POSITION:", actualSpawnPos)
                        
                        -- Check which farm they spawned near (if any)
                        local spawnedNearFarm = nil
                        for i = 1, 6 do -- 6 farms total
                            local farmModel = workspace.PlayerFarms:FindFirstChild("Farm_" .. i)
                            if farmModel then
                                -- Use farm spawn location as reference point instead of PrimaryPart
                                local farmSpawn = farmModel:FindFirstChild("FarmSpawn_" .. i)
                                if farmSpawn then
                                    local distance = (actualSpawnPos - farmSpawn.Position).Magnitude
                                    if distance < 50 then -- Within 50 studs of farm spawn
                                        spawnedNearFarm = i
                                        log.info("📍 PLAYER", player.Name, "SPAWNED NEAR FARM", i, "(distance:", distance, "from spawn)")
                                        break
                                    end
                                end
                            end
                        end
                        
                        if not spawnedNearFarm then
                            log.warn("📍 PLAYER", player.Name, "SPAWNED IN UNKNOWN LOCATION:", actualSpawnPos)
                        end
                        
                        -- Check if they spawned at the correct farm
                        if spawnedNearFarm == farmId then
                            log.info("✅ PLAYER", player.Name, "SPAWNED AT CORRECT FARM", farmId)
                        else
                            log.error("❌ PLAYER", player.Name, "SPAWNED AT WRONG LOCATION! Expected farm", farmId, "but spawned near farm", spawnedNearFarm or "UNKNOWN")
                        end
                        
                        -- IMMEDIATELY teleport to correct farm location regardless of where they spawned
                        local farmModel = workspace.PlayerFarms:FindFirstChild("Farm_" .. farmId)
                        local farmSpawn = farmModel and farmModel:FindFirstChild("FarmSpawn_" .. farmId)
                        
                        if farmSpawn then
                            log.info("📍 FORCE TELEPORTING", player.Name, "TO FARM", farmId, "IMMEDIATELY AFTER SPAWN")
                            player.Character.HumanoidRootPart.CFrame = farmSpawn.CFrame + Vector3.new(0, 3, 0)
                            log.info("✅ Character spawned and teleported for:", player.Name, "to farm", farmId, "in", (validationTime - attemptStart), "seconds")
                        else
                            log.warn("⚠️ Farm spawn location not found for teleportation - farm", farmId)
                        end
                        
                        return true
                    else
                        retries = retries + 1
                        log.warn("⚠️ Character spawn attempt", retries, "failed for:", player.Name, "- success:", success, "character exists:", player.Character ~= nil)
                        if retries < maxRetries then
                            log.info("⏳ Waiting 1 second before retry...")
                            wait(1) -- Wait before retry
                        end
                    end
                end
                
                log.error("❌ Failed to spawn character after", maxRetries, "attempts for:", player.Name)
                return false
            end
            
            -- Spawn character now that spawn location is set
            local spawnStart = tick()
            local spawnSuccess = spawnCharacterSafely()
            local spawnTime = tick()
            log.info("⏱️ CHARACTER SPAWN TOOK:", (spawnTime - spawnStart), "SECONDS")
            
            if spawnSuccess then
                -- Audit spawn locations after character spawned
                FarmManager.auditSpawnLocations("AFTER_SPAWN_" .. player.Name)
                
                -- Verify character spawned at correct farm location
                wait(0.1) -- Let character fully load position
                
                local character = player.Character
                local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
                
                if humanoidRootPart then
                    local farmModel = workspace.PlayerFarms:FindFirstChild("Farm_" .. farmId)
                    local farmSpawn = farmModel and farmModel:FindFirstChild("FarmSpawn_" .. farmId)
                    
                    if farmSpawn then
                        local spawnPos = farmSpawn.Position
                        local charPos = humanoidRootPart.Position
                        local distance = (spawnPos - charPos).Magnitude
                        
                        if distance > 50 then -- If character spawned far from farm
                            log.warn("⚠️ CHARACTER SPAWNED FAR FROM FARM for:", player.Name, "Distance:", distance, "- Teleporting to farm")
                            humanoidRootPart.CFrame = farmSpawn.CFrame + Vector3.new(0, 3, 0)
                            log.info("📍 TELEPORTED", player.Name, "TO CORRECT FARM LOCATION")
                        else
                            log.info("✅ CHARACTER SPAWNED AT CORRECT FARM for:", player.Name, "Distance from spawn:", distance)
                        end
                    end
                end
                
                -- Sync UI data after successful spawn
                log.info("🚀 SYNCING UI DATA AFTER SPAWN FOR:", player.Name)
                RemoteManager.syncPlayerData(player)
                log.info("🚀 UI DATA SYNCED FOR:", player.Name)
                
                -- Send character ready signal
                log.info("📡 SENDING CHARACTER READY SIGNAL FOR:", player.Name)
                RemoteManager.sendCharacterReady(player)
                log.info("📡 CHARACTER READY SIGNAL SENT FOR:", player.Name)
            else
                log.error("❌ CHARACTER SPAWN FAILED FOR:", player.Name)
                -- Still sync UI data for potential retry
                RemoteManager.syncPlayerData(player)
            end
            
            local totalTime = tick()
            log.info("⏱️ TOTAL FARM ASSIGNMENT AND SPAWN TOOK:", (totalTime - startTime), "SECONDS")
        else
            log.error("❌ NO FARM ASSIGNED FOR:", player.Name, "- cannot spawn character")
        end
        
        -- Send a final sync after everything is complete (includes updated gamepass data)
        wait(1) -- Give gamepasses a moment to finish
        log.info("🔵 FINAL DATA SYNC FOR:", player.Name)
        RemoteManager.syncPlayerData(player)
        log.info("🔵 ALL DATA SYNCED FOR:", player.Name)
        
        -- Initialize chat rank tracking after data is loaded
        local ChatManager = require(script.Parent.modules.ChatManager)
        ChatManager.initializePlayer(player)
    end)
end

function FarmingSystem.onPlayerLeft(player)
    log.info("🚪 PLAYER LEAVING DETECTED:", player.Name, "- Starting cleanup sequence")
    
    -- Clean up farm assignment first
    log.debug("🚪 Step 1: Farm cleanup for", player.Name)
    FarmManager.onPlayerLeaving(player)
    
    -- Handle remote cleanup
    log.debug("🚪 Step 2: Remote cleanup for", player.Name)
    RemoteManager.onPlayerLeft(player)
    
    -- Clean up chat rank tracking
    log.debug("🚪 Step 3: Chat cleanup for", player.Name)
    local ChatManager = require(script.Parent.modules.ChatManager)
    ChatManager.onPlayerRemoving(player)
    
    -- Release ProfileStore profile last
    log.info("🚪 Step 4: CRITICAL - ProfileStore release for", player.Name)
    PlayerDataManager.onPlayerLeaving(player)
    
    log.info("🚪 PLAYER CLEANUP COMPLETE for:", player.Name)
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
            log.info("No spawn point found for farm", farmId)
        end
    end
    
    -- Set up death handling to ensure respawn
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.Died:Connect(function()
        log.debug("Player", player.Name, "died - scheduling respawn")
        
        -- Wait a short delay then load a new character
        wait(2) -- Give time for death animation
        
        if player and player.Parent then
            player:LoadCharacter()
            log.debug("Respawned player", player.Name)
        end
    end)
    
    -- Update rank display (handled by RankDisplayManager.onCharacterAdded)
    RankDisplayManager.onCharacterAdded(character)
    
    -- Note: Character ready signal is now sent after farm teleportation in onPlayerJoined
end

-- Start event-driven plot update system
function FarmingSystem.startPlotUpdateLoop()
    log.info("Starting event-driven plot update system...")
    -- Event-driven updates are now handled when plots transition to "watered" state
    -- and scheduled based on actual growth times
end

return FarmingSystem