-- React-based 3D Farming Game Client
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Initialize client-side logging
local ClientLogger = require(script.ClientLogger)
local log = ClientLogger.getModuleLogger("ClientMain")

-- Wait for React packages and components to be available
local packagesExist = ReplicatedStorage:WaitForChild("Packages", 5)
local reactExists = packagesExist and packagesExist:FindFirstChild("react")
local componentsExist = script:FindFirstChild("components")

log.info("React 3D Farming Game Client Starting...")
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

-- Player data state
local playerData = {
    money = 100,
    rebirths = 0,
    inventory = {
        seeds = {},
        crops = {}
    },
    gamepasses = {}
}

-- Tutorial data state
local tutorialData = nil

-- Loading state
local isLoading = true

-- Create React root
local root = ReactRoblox.createRoot(playerGui)

-- Remote objects for passing to components
local remotes = {
    syncRemote = syncRemote,
    buyRemote = buyRemote,
    sellRemote = sellRemote,
    togglePremiumRemote = togglePremiumRemote,
    rebirthRemote = rebirthRemote,
    tutorialActionRemote = tutorialActionRemote,
    selectedItem = selectedItemRemote,
    buySlot = buySlotRemote
}

-- Update UI function
local function updateUI()
    if isLoading then
        root:render(React.createElement(LoadingScreen, {
            visible = true,
            screenSize = Vector2.new(1024, 768)
        }))
    else
        root:render(React.createElement(MainUI, {
            playerData = playerData,
            remotes = remotes,
            tutorialData = tutorialData
        }))
    end
end

-- Handle player data sync from server
syncRemote.OnClientEvent:Connect(function(newPlayerData)
    -- Use minimal logging for data sync (can be verbose)
    if newPlayerData.money then
        log.trace("Player data synced - Money:", newPlayerData.money)
    end
    playerData = newPlayerData
    
    -- Update PlotInteractionManager with current inventory data
    PlotInteractionManager.updatePlayerData(playerData)
    
    updateUI()
end)

-- Handle tutorial updates
tutorialRemote.OnClientEvent:Connect(function(newTutorialData)
    -- Only log tutorial updates when they happen
    if newTutorialData and newTutorialData.step then
        log.info("Tutorial step:", newTutorialData.stepNumber or "?")
    end
    tutorialData = newTutorialData
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
end)

-- Initialize React UI with loading screen
updateUI()

-- Initialize client systems after UI is ready
spawn(function()
    log.info("Initializing client systems...")
    
    -- Initialize all systems immediately
    PlotCountdownManager.initialize()
    PlotInteractionManager.initialize(farmingRemotes)
    PlotInteractionManager.updatePlayerData(playerData) -- Initialize with current player data
    PlotProximityHandler.initialize()
    FlyController.initialize() -- Initialize fly controller for easy testing
    CharacterFaceTracker.initialize() -- Make character displays always face the player
    
    -- Hide loading screen once character spawns
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart", 10)
    
    -- Hide loading screen and show main UI immediately
    isLoading = false
    updateUI()
    
    log.info("🌾 Farming Game fully loaded and ready!")
end)

-- Start cleanup timer for pending interactions and stale connections
spawn(function()
    while true do
        wait(30) -- Clean up every 30 seconds
        PlotInteractionManager.cleanupPendingInteractions()
        PlotProximityHandler.cleanupStaleConnections()
    end
end)

log.info("React 3D Farming Game Client Ready!")
log.info("Responsive UI activated - supports mobile and desktop!")
log.info("Enhanced with emojis and smooth animations!")
log.info("Client-side plot countdown system active!")
log.info("✈️ Fly Controller: Press F to toggle fly mode for easy testing!")
log.info("👀 Character Face Tracker: All farm avatars will always look at you!")

-- Development hot reload support (optional)
if game:GetService("RunService"):IsStudio() then
    log.debug("Development mode: Hot reload available")
end