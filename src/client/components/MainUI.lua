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
local CropViewModal = require(script.Parent.CropViewModal)
local SeedDetailModal = require(script.Parent.SeedDetailModal)
local WeatherPanel = require(script.Parent.WeatherPanel)
local BoostPanel = require(script.Parent.BoostPanel)
local TutorialResetButton = require(script.Parent.TutorialResetButton)
local SettingsPanel = require(script.Parent.SettingsPanel)
local PlotUI = require(script.Parent.PlotUI)
local DebugPanel = require(script.Parent.DebugPanel)
local GamepassPanel = require(script.Parent.GamepassPanel)
local ConfettiAnimation = require(script.Parent.ConfettiAnimation)
local RankPanel = require(script.Parent.RankPanel)

local function MainUI(props)
    local playerData = props.playerData or {}
    local remotes = props.remotes or {}
    local tutorialData = props.tutorialData
    local gamepassData = props.gamepassData or {}
    
    -- State management
    local inventoryVisible, setInventoryVisible = React.useState(false)
    local shopVisible, setShopVisible = React.useState(false)
    local tutorialVisible, setTutorialVisible = React.useState(tutorialData ~= nil)
    local cropViewVisible, setCropViewVisible = React.useState(false)
    local weatherVisible, setWeatherVisible = React.useState(false)
    local settingsVisible, setSettingsVisible = React.useState(false)
    local gamepassVisible, setGamepassVisible = React.useState(false)
    local plotUIVisible, setPlotUIVisible = React.useState(false)
    local selectedPlotData, setSelectedPlotData = React.useState(nil)
    local confettiVisible, setConfettiVisible = React.useState(false)
    local rankVisible, setRankVisible = React.useState(false)
    
    -- Track previous gamepass ownership to detect new purchases
    local previousGamepasses, setPreviousGamepasses = React.useState({})
    
    -- Check if tutorial is completed (for showing reset button)
    local isTutorialCompleted = tutorialData and tutorialData.completed
    local shouldShowTutorial = tutorialData and not isTutorialCompleted
    
    -- Screen size detection for responsive design
    local screenSize, setScreenSize = React.useState(Vector2.new(1024, 768))
    local isMobile = screenSize.X < 768
    
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
    
    -- Initialize DebugPanel when component mounts
    React.useEffect(function()
        DebugPanel.create()
    end, {})
    
    -- Event handlers
    local function handleShopClick()
        log.debug("Shop button clicked! Current state:", shopVisible)
        setShopVisible(not shopVisible)
        setInventoryVisible(false)
        setWeatherVisible(false)
        setCropViewVisible(false)
    end
    
    local function handleWeatherClick()
        setWeatherVisible(not weatherVisible)
        setInventoryVisible(false)
        setShopVisible(false)
        setCropViewVisible(false)
        setGamepassVisible(false)
    end
    
    local function handleGamepassClick()
        setGamepassVisible(not gamepassVisible)
        setInventoryVisible(false)
        setShopVisible(false)
        setWeatherVisible(false)
        setCropViewVisible(false)
        setRankVisible(false)
    end
    
    local function handleRankClick()
        setRankVisible(not rankVisible)
        setInventoryVisible(false)
        setShopVisible(false)
        setWeatherVisible(false)
        setGamepassVisible(false)
        setCropViewVisible(false)
    end
    
    local function handleCloseAll()
        setInventoryVisible(false)
        setShopVisible(false)
        setWeatherVisible(false)
        setGamepassVisible(false)
        setPlotUIVisible(false)
        setCropViewVisible(false)
        setRankVisible(false)
    end
    
    -- Plot UI handlers
    local function handlePlotInteraction(plotData)
        setSelectedPlotData(plotData)
        setPlotUIVisible(true)
        -- Close other panels
        setInventoryVisible(false)
        setShopVisible(false)
        setWeatherVisible(false)
        setGamepassVisible(false)
        setCropViewVisible(false)
    end
    
    -- Expose plot UI handler and updater to parent
    React.useEffect(function()
        if props.onPlotUIHandler then
                props.onPlotUIHandler(handlePlotInteraction)
        else
            log.warn("❌ No onPlotUIHandler prop provided to MainUI")
        end
        
        if props.onPlotUIUpdater then
            -- Function to update the currently open plot UI
            local function updateCurrentPlotUI(newPlotData)
                if plotUIVisible and selectedPlotData and newPlotData.plotId == selectedPlotData.plotId then
                    setSelectedPlotData(newPlotData)
                else
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
    
    local function handleGamepassPurchase(gamepassKey)
        log.info("Gamepass purchase requested:", gamepassKey)
        
        -- Send request to server to handle the purchase
        if remotes.gamepassPurchase then
            remotes.gamepassPurchase:FireServer(gamepassKey)
        else
            log.warn("Gamepass purchase remote not available")
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
    
    -- Watch for gamepass purchases and trigger confetti
    React.useEffect(function()
        log.info("Player data gamepasses updated:", playerData.gamepasses)
        if playerData.gamepasses then
            log.info("Current gamepasses:", playerData.gamepasses)
            log.info("Previous gamepasses:", previousGamepasses)
            
            -- Check if player acquired any new gamepasses
            local gamepassCount = 0
            for gamepassKey, owned in pairs(playerData.gamepasses) do
                gamepassCount = gamepassCount + 1
                log.info("Checking gamepass:", gamepassKey, "owned:", owned, "previously owned:", previousGamepasses[gamepassKey])
                if owned and not previousGamepasses[gamepassKey] then
                    -- Player just got a new gamepass! Show confetti
                    log.info("Gamepass purchased detected:", gamepassKey, "- showing confetti!")
                    setConfettiVisible(true)
                    break -- Only show confetti once even if multiple gamepasses purchased
                end
            end
            log.info("Total gamepasses found:", gamepassCount)
            
            -- Update previous gamepasses for next comparison
            setPreviousGamepasses(playerData.gamepasses)
        else
            log.warn("No gamepasses in playerData")
        end
    end, {playerData.gamepasses})
    
    return e("ScreenGui", {
        Name = "FarmingUIReact",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    }, {
        -- Background click detector to close panels (only when panels are visible)
        -- Mobile-friendly: smaller area that doesn't interfere with bottom controls
        ClickDetector = (inventoryVisible or shopVisible or weatherVisible or gamepassVisible or rankVisible) and e("TextButton", {
            Name = "ClickDetector",
            Size = UDim2.new(1, 0, 1, isMobile and -200 or 0), -- Leave more space at bottom for mobile controls
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = 1,
            [React.Event.Activated] = function()
                handleCloseAll()
            end
        }) or nil,
        
        -- Top Stats Component (rebirth moved to side buttons)
        TopStats = e(TopStats, {
            playerData = playerData,
            screenSize = screenSize
        }),
        
        -- Side Buttons Component
        SideButtons = e(SideButtons, {
            screenSize = screenSize,
            tutorialData = tutorialData,
            onShopClick = handleShopClick,
            onInventoryClick = function()
                setCropViewVisible(true)
            end,
            onWeatherClick = handleWeatherClick,
            onGamepassClick = handleGamepassClick,
            onRebirthClick = handleRebirthClick,
            onRankClick = handleRankClick,
            onPetsClick = function()
                DebugPanel.toggle()
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
        
        -- Crop View Modal (rendered at top level for proper positioning)
        CropViewModal = e(CropViewModal, {
            playerData = playerData,
            visible = cropViewVisible,
            onClose = function()
                setCropViewVisible(false)
            end,
            onSellCrop = function(cropType, quantity)
                if remotes.sell then
                    remotes.sell:FireServer(cropType, quantity)
                end
            end,
            screenSize = screenSize
        }),
        
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
        
        -- Gamepass Panel Component (only render when needed)
        GamepassPanel = gamepassVisible and e(GamepassPanel, {
            visible = gamepassVisible,
            onClose = function() setGamepassVisible(false) end,
            onPurchase = handleGamepassPurchase,
            playerData = playerData,
            gamepassData = gamepassData,
            screenSize = screenSize
        }) or nil,
        
        -- Rank Panel Component (only render when needed)
        RankPanel = rankVisible and e(RankPanel, {
            playerData = playerData,
            onClose = function() setRankVisible(false) end,
            screenSize = screenSize
        }) or nil,
        
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
                setGamepassVisible(false)
                setCropViewVisible(false)
            end,
            remotes = remotes,
            screenSize = screenSize
        }) or nil,
        
        -- Confetti Animation (shows on top of everything)
        ConfettiAnimation = e(ConfettiAnimation, {
            visible = confettiVisible,
            onComplete = function()
                setConfettiVisible(false)
            end,
            screenSize = screenSize
        })
    })
end

return MainUI