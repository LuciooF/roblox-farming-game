-- Main UI Component
-- Orchestrates all UI components with responsive design

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local e = React.createElement
local ClientLogger = require(script.Parent.Parent.ClientLogger)

local log = ClientLogger.getModuleLogger("MainUI")

-- Import components
local TopStats = require(script.Parent.TopStats)
local SideButtons = require(script.Parent.SideButtons)
local InventoryPanel = require(script.Parent.InventoryPanel)
local ShopPanel = require(script.Parent.ShopPanel)
local TutorialPanel = require(script.Parent.TutorialPanel)
local HotbarInventory = require(script.Parent.HotbarInventory)
local SeedDetailModal = require(script.Parent.SeedDetailModal)
local WeatherPanel = require(script.Parent.WeatherPanel)
local BoostPanel = require(script.Parent.BoostPanel)
local TutorialResetButton = require(script.Parent.TutorialResetButton)
local SettingsPanel = require(script.Parent.SettingsPanel)
local PlotUI = require(script.Parent.PlotUI)

local function MainUI(props)
    local playerData = props.playerData or {}
    local remotes = props.remotes or {}
    local tutorialData = props.tutorialData
    
    -- State management
    local inventoryVisible, setInventoryVisible = React.useState(false)
    local shopVisible, setShopVisible = React.useState(false)
    local tutorialVisible, setTutorialVisible = React.useState(tutorialData ~= nil)
    local hotbarInfoVisible, setHotbarInfoVisible = React.useState(false)
    local selectedHotbarInfo, setSelectedHotbarInfo = React.useState(nil)
    local weatherVisible, setWeatherVisible = React.useState(false)
    local settingsVisible, setSettingsVisible = React.useState(false)
    local plotUIVisible, setPlotUIVisible = React.useState(false)
    local selectedPlotData, setSelectedPlotData = React.useState(nil)
    
    -- Check if tutorial is completed (for showing reset button)
    local isTutorialCompleted = tutorialData and tutorialData.completed
    local shouldShowTutorial = tutorialData and not isTutorialCompleted
    
    -- Screen size detection for responsive design
    local screenSize, setScreenSize = React.useState(Vector2.new(1024, 768))
    
    -- Update screen size
    React.useEffect(function()
        local camera = workspace.CurrentCamera
        if camera then
            local function updateScreenSize()
                setScreenSize(camera.ViewportSize)
            end
            
            updateScreenSize()
            local connection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScreenSize)
            
            return function()
                connection:Disconnect()
            end
        end
    end, {})
    
    -- Event handlers
    local function handleShopClick()
        log.debug("Shop button clicked! Current state:", shopVisible)
        setShopVisible(not shopVisible)
        setInventoryVisible(false)
        setWeatherVisible(false)
    end
    
    local function handleWeatherClick()
        setWeatherVisible(not weatherVisible)
        setInventoryVisible(false)
        setShopVisible(false)
    end
    
    local function handleCloseAll()
        setInventoryVisible(false)
        setShopVisible(false)
        setWeatherVisible(false)
        setPlotUIVisible(false)
    end
    
    -- Plot UI handlers
    local function handlePlotInteraction(plotData)
        log.info("🎉 Plot interaction triggered for plot", plotData.plotId, "state:", plotData.state)
        setSelectedPlotData(plotData)
        setPlotUIVisible(true)
        -- Close other panels
        setInventoryVisible(false)
        setShopVisible(false)
        setWeatherVisible(false)
        log.info("📋 Plot UI should now be visible")
    end
    
    -- Expose plot UI handler and updater to parent
    React.useEffect(function()
        if props.onPlotUIHandler then
            log.info("🔗 Setting up plot UI handler in MainUI")
            props.onPlotUIHandler(handlePlotInteraction)
        else
            log.warn("❌ No onPlotUIHandler prop provided to MainUI")
        end
        
        if props.onPlotUIUpdater then
            -- Function to update the currently open plot UI
            local function updateCurrentPlotUI(newPlotData)
                log.info("📧 Plot UI updater called with data for plot", newPlotData.plotId, "UI visible:", plotUIVisible, "selected plot:", selectedPlotData and selectedPlotData.plotId or "none")
                if plotUIVisible and selectedPlotData and newPlotData.plotId == selectedPlotData.plotId then
                    log.info("🔄 Updating open Plot UI with new data for plot", newPlotData.plotId, "state:", newPlotData.state, "plants:", newPlotData.maxHarvests - newPlotData.harvestCount)
                    setSelectedPlotData(newPlotData)
                else
                    log.warn("❌ Not updating Plot UI - visible:", plotUIVisible, "selectedPlotId:", selectedPlotData and selectedPlotData.plotId, "newPlotId:", newPlotData.plotId)
                end
            end
            props.onPlotUIUpdater(updateCurrentPlotUI)
        end
    end, {plotUIVisible, selectedPlotData})
    
    local function handleRebirthClick()
        if remotes.rebirthRemote then
            remotes.rebirthRemote:FireServer()
        end
    end
    
    local function handlePurchase(itemType, item, price)
        if remotes.buyRemote then
            remotes.buyRemote:FireServer(itemType, item, price)
        end
    end
    
    local function handleTutorialNext()
        if remotes.tutorialActionRemote then
            remotes.tutorialActionRemote:FireServer("next")
        end
    end
    
    local function handleTutorialSkip()
        if remotes.tutorialActionRemote then
            remotes.tutorialActionRemote:FireServer("skip")
        end
        setTutorialVisible(false)
    end
    
    -- Update tutorial visibility when data changes
    React.useEffect(function()
        if tutorialData and tutorialData.action == "hide" then
            setTutorialVisible(false)
        elseif shouldShowTutorial and tutorialData.step then
            setTutorialVisible(true)
        else
            setTutorialVisible(false)
        end
    end, {tutorialData, shouldShowTutorial})
    
    return e("ScreenGui", {
        Name = "FarmingUIReact",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    }, {
        -- Background click detector to close panels (only when panels are visible)
        ClickDetector = (inventoryVisible or shopVisible or weatherVisible or plotUIVisible) and e("TextButton", {
            Name = "ClickDetector",
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = 1,
            [React.Event.Activated] = function()
                handleCloseAll()
            end
        }) or nil,
        
        -- Top Stats Component
        TopStats = e(TopStats, {
            playerData = playerData,
            screenSize = screenSize,
            onRebirthClick = handleRebirthClick
        }),
        
        -- Side Buttons Component
        SideButtons = e(SideButtons, {
            screenSize = screenSize,
            onShopClick = handleShopClick,
            onWeatherClick = handleWeatherClick,
            onSettingsClick = function()
                setSettingsVisible(true)
            end,
            onSellClick = function()
                -- Sell all crops using automation remote
                if remotes.automation then
                    remotes.automation:FireServer("sellAll")
                else
                    log.error("automation remote not available")
                end
            end
        }),
        
        -- Inventory Panel Component
        InventoryPanel = e(InventoryPanel, {
            playerData = playerData,
            screenSize = screenSize,
            visible = inventoryVisible,
            onClose = function() setInventoryVisible(false) end,
            remotes = remotes
        }),
        
        -- Shop Panel Component
        ShopPanel = e(ShopPanel, {
            playerData = playerData,
            screenSize = screenSize,
            visible = shopVisible,
            onClose = function() setShopVisible(false) end,
            remotes = remotes
        }),
        
        -- Hotbar Inventory Component (always visible)
        HotbarInventory = e(HotbarInventory, {
            playerData = playerData,
            screenSize = screenSize,
            visible = true, -- Always visible
            remotes = remotes,
            onShowInfo = function(seedType)
                setSelectedHotbarInfo(seedType)
                setHotbarInfoVisible(true)
            end
        }),
        
        -- Tutorial Panel Component (only show if tutorial not completed)
        TutorialPanel = shouldShowTutorial and e(TutorialPanel, {
            tutorialData = tutorialData,
            screenSize = screenSize,
            visible = tutorialVisible,
            onNext = handleTutorialNext,
            onSkip = handleTutorialSkip,
            remotes = remotes
        }) or nil,
        
        -- Weather Panel Component
        WeatherPanel = e(WeatherPanel, {
            weatherData = props.weatherData or {},
            visible = weatherVisible,
            onClose = function() setWeatherVisible(false) end,
            remotes = remotes,
            screenSize = screenSize,
            isDebugMode = true -- Enable for testing
        }),
        
        -- Boost Panel Component (bottom left)
        BoostPanel = e(BoostPanel, {
            playerData = playerData,
            weatherData = props.weatherData or {},
            screenSize = screenSize
        }),
        
        -- Hotbar Info Modal (rendered at top level for proper positioning)
        HotbarInfoModal = hotbarInfoVisible and e(SeedDetailModal, {
            seedType = selectedHotbarInfo,
            isVisible = hotbarInfoVisible,
            onClose = function()
                setHotbarInfoVisible(false)
            end,
            playerMoney = playerData.money or 0,
            screenSize = screenSize,
            weatherData = props.weatherData or {}
        }) or nil,
        
        -- Tutorial Reset Button (only show when tutorial is completed, for debugging)
        TutorialResetButton = isTutorialCompleted and e(TutorialResetButton, {
            visible = true,
            screenSize = screenSize,
            remotes = remotes
        }) or nil,
        
        -- Settings Panel Component
        SettingsPanel = e(SettingsPanel, {
            visible = settingsVisible,
            onClose = function() setSettingsVisible(false) end,
            screenSize = screenSize
        }),
        
        -- Plot UI Component
        PlotUI = plotUIVisible and selectedPlotData and e(PlotUI, {
            plotData = selectedPlotData,
            playerData = playerData,
            visible = plotUIVisible,
            onClose = function() 
                setPlotUIVisible(false)
                setSelectedPlotData(nil)
            end,
            onOpenShop = function()
                setShopVisible(true)
                setPlotUIVisible(false)
                setSelectedPlotData(nil)
                setInventoryVisible(false)
                setWeatherVisible(false)
            end,
            remotes = remotes,
            screenSize = screenSize
        }) or nil
    })
end

return MainUI