-- React-based 3D Farming Game Client
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

-- Initialize client-side logging with fallback
local ClientLogger
local hasLogger = pcall(function()
    ClientLogger = require(script.ClientLogger)
end)

if not hasLogger then
    -- Fallback logging
    ClientLogger = {
        getModuleLogger = function(name)
            return {
                info = function(...) print("[INFO]", name, ...) end,
                debug = function(...) print("[DEBUG]", name, ...) end,
                warn = function(...) warn("[WARN]", name, ...) end,
                error = function(...) error("[ERROR] " .. name .. ": " .. table.concat({...}, " ")) end
            }
        end
    }
end

local log = ClientLogger.getModuleLogger("ClientMain")

-- Ensure mobile controls are enabled and protected
if UserInputService.TouchEnabled then
    GuiService.TouchControlsEnabled = true
    log.info("Mobile device detected - ensuring touch controls are enabled")
    
    -- Force enable both movement and camera controls
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    
    -- Enable mobile controls more aggressively with multiple approaches
    spawn(function()
        wait(0.5) -- Shorter initial wait
        GuiService.TouchControlsEnabled = true
        
        -- Try multiple methods to enable mobile controls
        pcall(function()
            -- Method 1: Direct PlayerModule access
            if player and player.PlayerScripts then
                local playerModule = player.PlayerScripts:WaitForChild("PlayerModule", 3)
                if playerModule then
                    local controls = require(playerModule:WaitForChild("ControlModule"))
                    if controls and controls.Enable then
                        controls:Enable()
                        log.info("Mobile movement controls enabled via ControlModule")
                    end
                end
            end
        end)
        
        -- Method 2: Force enable at game level
        wait(1)
        GuiService.TouchControlsEnabled = true
        
        -- Method 3: Enable via PlayerGui properties 
        pcall(function()
            local playerGui = player:WaitForChild("PlayerGui")
            if playerGui then
                -- Ensure no ScreenGuis are blocking input
                for _, gui in pairs(playerGui:GetChildren()) do
                    if gui:IsA("ScreenGui") and gui.Name ~= "LoadingScreen" then
                        pcall(function()
                            -- Make sure they don't have Modal properties that block input
                            if gui:FindFirstChild("Modal") then
                                gui.Modal.Modal = false
                            end
                        end)
                    end
                end
            end
        end)
        
        wait(2)
        GuiService.TouchControlsEnabled = true
        log.info("Mobile controls force re-enabled after full UI load")
    end)
end

-- Wait for React packages and components to be available
local packagesExist = ReplicatedStorage:WaitForChild("Packages", 5)
local reactExists = packagesExist and packagesExist:FindFirstChild("react")
local componentsExist = script:FindFirstChild("components")

log.debug("packagesExist =", packagesExist ~= nil, "reactExists =", reactExists ~= nil, "componentsExist =", componentsExist ~= nil)

if not reactExists or not componentsExist then
    error("❌ React packages or components not found! Cannot start UI.")
end

-- If React is available, load the full React UI
local React = require(ReplicatedStorage.Packages.react)
local ReactRoblox = require(ReplicatedStorage.Packages["react-roblox"])

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Import main UI component
local MainUI = require(script.components.MainUI)
local LoadingScreen = require(script.components.LoadingScreen)
local PlotCountdownManager = require(script.PlotCountdownManager)
local PlotInteractionManager = require(script.PlotInteractionManager)
local PlotProximityHandler = require(script.PlotProximityHandler)
local FlyController = require(script.FlyController)
local CharacterFaceTracker = require(script.CharacterFaceTracker)
local TutorialArrowManager = require(script.TutorialArrowManager)

-- Wait for farming remotes
log.debug("Waiting for FarmingRemotes folder...")
local farmingRemotes = ReplicatedStorage:WaitForChild("FarmingRemotes", 10)
if not farmingRemotes then
    error("❌ FarmingRemotes folder not found after 10 seconds!")
end
log.debug("Found FarmingRemotes folder, waiting for SyncPlayerData...")
local syncRemote = farmingRemotes:WaitForChild("SyncPlayerData", 10)
if not syncRemote then
    error("❌ SyncPlayerData remote not found after 10 seconds!")
end
log.debug("Found SyncPlayerData remote, continuing...")
local buyRemote = farmingRemotes:WaitForChild("BuyItem")
local sellRemote = farmingRemotes:WaitForChild("SellCrop")
local togglePremiumRemote = farmingRemotes:WaitForChild("TogglePremium")
local rebirthRemote = farmingRemotes:WaitForChild("PerformRebirth")
local tutorialRemote = farmingRemotes:WaitForChild("TutorialData")
local tutorialActionRemote = farmingRemotes:WaitForChild("TutorialAction")
local selectedItemRemote = farmingRemotes:WaitForChild("SelectedItem")
local buySlotRemote = farmingRemotes:WaitForChild("BuySlot")
local plotUpdateRemote = farmingRemotes:WaitForChild("PlotUpdate")
local characterTrackingRemote = farmingRemotes:WaitForChild("CharacterTracking")
local weatherRemote = farmingRemotes:WaitForChild("WeatherData")
local cutPlantRemote = farmingRemotes:WaitForChild("CutPlant")
local automationRemote = farmingRemotes:WaitForChild("Automation")
local openPlotUIRemote = farmingRemotes:WaitForChild("OpenPlotUI")
local gamepassPurchaseRemote = farmingRemotes:WaitForChild("GamepassPurchase")
local gamepassDataRemote = farmingRemotes:WaitForChild("GamepassData")

-- Player data state (starts as nil - UI won't render until data loads)
local playerData = nil

-- Tutorial data state
local tutorialData = nil

-- Weather data state
local weatherData = {}

-- Gamepass data state (prices from server)
local gamepassData = {}

-- Remove loading state - no more loading screen

-- Create React root
log.debug("Creating React root in PlayerGui")
local root = ReactRoblox.createRoot(playerGui)
log.debug("React root created successfully")

-- Remote objects for passing to components
local remotes = {
    syncRemote = syncRemote,
    buy = buyRemote,
    sell = sellRemote,
    togglePremiumRemote = togglePremiumRemote,
    rebirthRemote = rebirthRemote,
    tutorialActionRemote = tutorialActionRemote,
    selectedItem = selectedItemRemote,
    buySlot = buySlotRemote,
    weatherRemote = weatherRemote,
    cutPlant = cutPlantRemote,
    automation = automationRemote,
    gamepassPurchase = gamepassPurchaseRemote,
    gamepassData = gamepassDataRemote,
    farmAction = farmingRemotes:WaitForChild("FarmAction") -- Farm action remote for PlotUI
}

-- Handler for plot UI interactions
local plotUIHandler = nil
local plotUIUpdater = nil -- Function to update the currently open Plot UI

-- Screen size state for responsive design
local screenSize = Vector2.new(1024, 768)

-- Update screen size function
local function updateScreenSize()
    local camera = workspace.CurrentCamera
    if camera then
        screenSize = camera.ViewportSize
    end
end

-- Update UI function - renders loading screen or main UI
local function updateUI()
    -- Update screen size
    updateScreenSize()
    
    if not playerData then
        -- Show loading screen while waiting for player data
        log.debug("Player data not loaded yet, showing loading screen")
        root:render(React.createElement(LoadingScreen, {
            screenSize = screenSize
        }))
        return
    end
    
    -- Render main UI when data is loaded
    root:render(React.createElement(MainUI, {
        playerData = playerData,
        remotes = remotes,
        tutorialData = tutorialData,
        weatherData = weatherData,
        gamepassData = gamepassData,
        onPlotUIHandler = function(handler)
            plotUIHandler = handler
            -- Update PlotInteractionManager with the handler
            PlotInteractionManager.setPlotUIHandler(handler)
        end,
        onPlotUIUpdater = function(updater)
            plotUIUpdater = updater
        end
    }))
end

-- Handle player data sync from server
syncRemote.OnClientEvent:Connect(function(newPlayerData)
    local isFirstLoad = playerData == nil
    
    -- Use minimal logging for data sync (can be verbose)
    if newPlayerData.money then
        log.trace("Player data synced - Money:", newPlayerData.money)
    end
    
    if isFirstLoad then
        log.info("Player data loaded for first time - switching from loading screen to main UI")
    end
    
    -- Update player data
    playerData = newPlayerData
    
    -- Update PlotInteractionManager with current inventory data
    PlotInteractionManager.updatePlayerData(playerData)
    
    -- Update UI with new data (will now render if this was first load)
    updateUI()
end)

-- Handle tutorial updates
tutorialRemote.OnClientEvent:Connect(function(newTutorialData)
    -- Only log tutorial updates when they happen
    if newTutorialData and newTutorialData.step then
        log.info("Tutorial step:", newTutorialData.stepNumber or "?")
    end
    tutorialData = newTutorialData
    
    -- Update tutorial arrows
    TutorialArrowManager.updateForTutorialStep(newTutorialData)
    
    updateUI()
end)

-- Handle weather updates
weatherRemote.OnClientEvent:Connect(function(newWeatherData)
    log.trace("Weather data received:", newWeatherData.current and newWeatherData.current.name or "unknown")
    weatherData = newWeatherData
    updateUI()
end)

-- Handle gamepass data updates
gamepassDataRemote.OnClientEvent:Connect(function(newGamepassData)
    log.debug("Gamepass data received with", newGamepassData and #newGamepassData or 0, "gamepasses")
    gamepassData = newGamepassData
    updateUI()
end)

-- Cleanup old UI if it exists
local existingUI = playerGui:FindFirstChild("FarmingUI")
if existingUI then
    existingUI:Destroy()
end

-- Handle plot updates from server
plotUpdateRemote.OnClientEvent:Connect(function(plotData)
    
    PlotCountdownManager.updatePlotData(plotData.plotId, plotData)
    
    -- Also handle as server response for interaction prediction
    PlotInteractionManager.onServerResponse(plotData.plotId, true, plotData.state)
    
    -- Update the currently open Plot UI if it's for this plot
    if plotUIUpdater then
        plotUIUpdater(plotData)
    else
    end
    
    -- Check if we should trigger rain effect
    if plotData.triggerRainEffect then
        local PlotUtils = require(script.PlotUtils)
        local RainEffectManager = require(script.RainEffectManager)
        local plot = PlotUtils.findPlotById(plotData.plotId)
        if plot then
            RainEffectManager.createRainEffect(plot)
        end
    end
end)

-- Handle plot UI open requests from server
openPlotUIRemote.OnClientEvent:Connect(function(plotData)
    
    -- Call the plot UI handler if it exists
    if plotUIHandler then
        plotUIHandler(plotData)
    else
    end
end)

-- Initialize client systems
PlotCountdownManager.initialize()
PlotInteractionManager.initialize(farmingRemotes)
PlotInteractionManager.updatePlayerData(playerData)
-- PlotProximityHandler.initialize() -- Disabled: using simpler server-side UI opening
FlyController.initialize()
CharacterFaceTracker.initialize()


-- Set up camera viewport size change detection
local camera = workspace.CurrentCamera
if camera then
    camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        updateScreenSize()
        updateUI() -- Re-render on screen size change
    end)
end

-- Render initial loading screen
updateUI()

-- Request gamepass data from server
spawn(function()
    wait(1) -- Wait a bit for remotes to be fully set up
    gamepassDataRemote:FireServer()
end)

-- Initialize character-dependent features in background (non-blocking)
spawn(function()
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart", 10)
    end)

-- Start cleanup timer for pending interactions
spawn(function()
    while true do
        wait(30) -- Clean up every 30 seconds
        PlotInteractionManager.cleanupPendingInteractions()
        -- PlotProximityHandler.cleanupStaleConnections() -- Disabled: not using proximity handler
    end
end)


-- Development hot reload support (optional)
if game:GetService("RunService"):IsStudio() then
    log.debug("Development mode: Hot reload available")
end