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

-- Ensure mobile controls are enabled
if UserInputService.TouchEnabled then
    GuiService.TouchControlsEnabled = true
    log.info("Mobile device detected - ensuring touch controls are enabled")
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

-- Player data state (starts as loading)
local playerData = {
    loading = true,  -- Indicates data is still loading
    money = 0,
    rebirths = 0,
    inventory = {
        seeds = {},
        crops = {}
    },
    gamepasses = {}
}

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

-- Update UI function - always render main UI
local function updateUI()
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
    -- Use minimal logging for data sync (can be verbose)
    if newPlayerData.money then
        log.trace("Player data synced - Money:", newPlayerData.money)
    end
    
    -- Mark loading as complete and update data
    playerData = newPlayerData
    playerData.loading = false
    
    -- Update PlotInteractionManager with current inventory data
    PlotInteractionManager.updatePlayerData(playerData)
    
    -- Update UI with new data
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


-- Render initial UI
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