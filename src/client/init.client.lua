-- React-based 3D Farming Game Client
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

-- Initialize client-side logging with simple print statements
local function createLogger(name)
    return {
        info = function(...) print("[INFO]", name, ...) end,
        warn = function(...) warn("[WARN]", name, ...) end,
        error = function(...) error("[ERROR] " .. name .. ": " .. table.concat({...}, " ")) end,
    }
end

local log = createLogger("ClientMain")

-- Client-side Sound Utilities
local SoundService = game:GetService("SoundService")

local SoundUtils = {}

-- Sound IDs
local SOUND_IDS = {
    shopPurchase = "10066947742",
    gamepassPurchase = "9068897474", 
    sellCrops = "117754737160472"
}

-- Helper function to play a sound by ID
local function playSound(soundId, volume, playbackSpeed)
    volume = volume or 0.5
    playbackSpeed = playbackSpeed or 1.0
    
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. soundId
    sound.Volume = volume
    sound.PlaybackSpeed = playbackSpeed
    sound.Parent = SoundService
    sound:Play()
    
    -- Clean up after sound finishes
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

-- Play shop purchase sound (for buying items or plots)
function SoundUtils.playShopPurchaseSound()
    playSound(SOUND_IDS.shopPurchase, 0.5)
end

-- Play gamepass purchase sound 
function SoundUtils.playGamepassPurchaseSound()
    playSound(SOUND_IDS.gamepassPurchase, 0.6)
end

-- Play crop selling sound (at 1.25x speed)
function SoundUtils.playSellSound()
    playSound(SOUND_IDS.sellCrops, 0.4, 1.25)
end

-- Purchase detection state
local previousMoney = nil
_G.lastActionTime = 0 -- Global so other modules can update it
local pendingPurchase = false

-- Simple mobile control enablement - no hacks
if UserInputService.TouchEnabled then
    GuiService.TouchControlsEnabled = true
    log.info("Mobile device detected - TouchControlsEnabled set to true")
end

-- Wait for React packages and components to be available
local packagesExist = ReplicatedStorage:WaitForChild("Packages", 5)
local reactExists = packagesExist and packagesExist:FindFirstChild("react")
local componentsExist = script:FindFirstChild("components")


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
local DoubleJumpController = require(script.DoubleJumpController)
local BackgroundMusicManager = require(script.BackgroundMusicManager)
local CodesService = require(script.CodesService)
local RewardsService = require(script.RewardsService)

-- Wait for farming remotes
local farmingRemotes = ReplicatedStorage:WaitForChild("FarmingRemotes", 10)
if not farmingRemotes then
    error("❌ FarmingRemotes folder not found after 10 seconds!")
end
local syncRemote = farmingRemotes:WaitForChild("SyncPlayerData", 10)
if not syncRemote then
    error("❌ SyncPlayerData remote not found after 10 seconds!")
end
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
local characterReadyRemote = farmingRemotes:WaitForChild("CharacterReady")
local musicPreferenceRemote = farmingRemotes:WaitForChild("MusicPreference")
local redeemCodeRemote = farmingRemotes:WaitForChild("RedeemCode", 5) -- Optional, may not exist yet
local showRewardRemote = farmingRemotes:WaitForChild("ShowReward")

-- Player data state (starts as nil - UI won't render until data loads)
local playerData = nil

-- Character ready state (starts as false - loading screen waits for this)
local characterReady = false

-- Tutorial data state
local tutorialData = nil

-- Weather data state
local weatherData = {}

-- Gamepass data state (prices from server)
local gamepassData = {}

-- Remove loading state - no more loading screen

-- Create React root on a ScreenGui instead of directly on PlayerGui
-- This prevents React from interfering with mobile controls
local reactScreenGui = Instance.new("ScreenGui")
reactScreenGui.Name = "ReactContainer"
reactScreenGui.ResetOnSpawn = false
reactScreenGui.IgnoreGuiInset = true -- Don't interfere with mobile controls
reactScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
reactScreenGui.DisplayOrder = 1
reactScreenGui.Parent = playerGui

local root = ReactRoblox.createRoot(reactScreenGui)

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
    farmAction = farmingRemotes:WaitForChild("FarmAction"), -- Farm action remote for PlotUI
    MusicPreference = musicPreferenceRemote,
    redeemCode = redeemCodeRemote
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
    -- Update screen size for responsive design
    updateScreenSize()
    
    if not playerData or not characterReady then
        -- Show loading screen while waiting for player data AND character spawn
        local reason = ""
        if not playerData then
            reason = "player data"
        elseif not characterReady then
            reason = "character spawn"
        end
        
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
    end
    
    -- Detect shop purchases (money decreased recently)
    if not isFirstLoad and previousMoney and newPlayerData.money then
        local currentTime = tick()
        local timeSinceLastAction = currentTime - _G.lastActionTime
        
        -- If money decreased and it was recent (within 3 seconds), it's likely a purchase
        if newPlayerData.money < previousMoney and timeSinceLastAction < 3 then
            SoundUtils.playShopPurchaseSound()
        -- If money increased and it was recent, it's likely a sale
        elseif newPlayerData.money > previousMoney and timeSinceLastAction < 3 then
            -- Check if inventory decreased (indicating a sale vs other money gain)
            local soldSomething = false
            if playerData and playerData.inventory and newPlayerData.inventory then
                for itemType, items in pairs(playerData.inventory) do
                    if newPlayerData.inventory[itemType] then
                        for itemName, oldCount in pairs(items) do
                            local newCount = newPlayerData.inventory[itemType][itemName] or 0
                            if newCount < oldCount then
                                soldSomething = true
                                break
                            end
                        end
                    end
                    if soldSomething then break end
                end
            end
            
            if soldSomething then
                SoundUtils.playSellSound()
            end
        end
    end
    
    if isFirstLoad then
        log.info("Player data loaded for first time - waiting for character spawn before showing main UI")
        
        -- Initialize background music with saved preference
        local musicEnabled = true -- Default to true
        if newPlayerData.settings and newPlayerData.settings.musicEnabled ~= nil then
            musicEnabled = newPlayerData.settings.musicEnabled
        end
        BackgroundMusicManager.setInitialState(musicEnabled)
    end
    
    -- Store previous money for purchase detection
    previousMoney = newPlayerData.money
    
    -- Update player data
    playerData = newPlayerData
    
    -- Make player data available globally for other modules
    _G.currentPlayerData = playerData
    
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
    weatherData = newWeatherData
    updateUI()
end)

-- Handle gamepass data updates
gamepassDataRemote.OnClientEvent:Connect(function(newGamepassData)
    
    -- Detect new gamepass purchases (when gamepass data increases)
    if gamepassData and newGamepassData then
        local oldCount = gamepassData and #gamepassData or 0
        local newCount = newGamepassData and #newGamepassData or 0
        
        if newCount > oldCount then
            SoundUtils.playGamepassPurchaseSound()
        end
    end
    
    gamepassData = newGamepassData
    updateUI()
end)

-- Handle character ready signal
characterReadyRemote.OnClientEvent:Connect(function()
    log.info("Character ready signal received - switching from loading screen to main UI")
    characterReady = true
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

-- Handle reward display requests from server
showRewardRemote.OnClientEvent:Connect(function(rewardData)
    log.info("Received reward from server:", rewardData.type, rewardData.amount)
    
    if rewardData.type == "money" then
        RewardsService.showMoneyReward(rewardData.amount, rewardData.description)
    else
        -- For future reward types
        RewardsService.showReward(rewardData)
    end
end)

-- Initialize client systems
PlotCountdownManager.initialize()
PlotInteractionManager.initialize(farmingRemotes)
PlotInteractionManager.updatePlayerData(playerData)
-- PlotProximityHandler.initialize() -- Disabled: using simpler server-side UI opening
FlyController.initialize()
CharacterFaceTracker.initialize()
BackgroundMusicManager.initialize()

-- Initialize RewardsService
RewardsService.initialize()

-- Initialize CodesService
CodesService.initialize(remotes)


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
    
    -- Initialize double jump controller
    DoubleJumpController.initialize()
    log.info("Double jump controller initialized")
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
end