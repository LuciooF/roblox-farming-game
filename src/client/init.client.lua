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
local PlotCountdownManager = require(script.PlotCountdownManager)

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
    root:render(React.createElement(MainUI, {
        playerData = playerData,
        remotes = remotes,
        tutorialData = tutorialData
    }))
end

-- Handle player data sync from server
syncRemote.OnClientEvent:Connect(function(newPlayerData)
    -- Use minimal logging for data sync (can be verbose)
    if newPlayerData.money then
        log.trace("Player data synced - Money:", newPlayerData.money)
    end
    playerData = newPlayerData
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

-- Initialize client systems
PlotCountdownManager.initialize()

-- Handle plot updates from server
plotUpdateRemote.OnClientEvent:Connect(function(plotData)
    PlotCountdownManager.updatePlotData(plotData.plotId, plotData)
end)

-- Initialize React UI
wait(1) -- Wait a moment for everything to load
updateUI()

log.info("React 3D Farming Game Client Ready!")
log.info("Responsive UI activated - supports mobile and desktop!")
log.info("Enhanced with emojis and smooth animations!")
log.info("Client-side plot countdown system active!")

-- Development hot reload support (optional)
if game:GetService("RunService"):IsStudio() then
    log.debug("Development mode: Hot reload available")
end