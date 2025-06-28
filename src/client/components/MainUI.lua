-- Main UI Component
-- Orchestrates all UI components with responsive design

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local e = React.createElement
local ClientLogger = require(script.Parent.Parent.ClientLogger)
local ScreenUtils = require(game:GetService("ReplicatedStorage").Shared.ScreenUtils)

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
local SettingsPanel = require(script.Parent.SettingsPanel)
local PlotUI = require(script.Parent.PlotUI_Simple)
local DebugPanel = require(script.Parent.DebugPanel)
local GamepassPanel = require(script.Parent.GamepassPanel)
local ConfettiAnimation = require(script.Parent.ConfettiAnimation)
local RebirthPanel = require(script.Parent.RebirthPanel)
local PlantingPanel = require(script.Parent.PlantingPanel)
local MusicButton = require(script.Parent.MusicButton)
local RewardsPanel = require(script.Parent.RewardsPanel)

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
    local rebirthVisible, setRebirthVisible = React.useState(false)
    local plotUIVisible, setPlotUIVisible = React.useState(false)
    local selectedPlotData, setSelectedPlotData = React.useState(nil)
    local confettiVisible, setConfettiVisible = React.useState(false)
    local plantingVisible, setPlantingVisible = React.useState(false)
    local selectedPlotForPlanting, setSelectedPlotForPlanting = React.useState(nil)
    
    -- Track previous gamepass ownership to detect new purchases
    local previousGamepasses, setPreviousGamepasses = React.useState({})
    
    -- Check if tutorial is completed (for showing reset button)
    local isTutorialCompleted = tutorialData and tutorialData.completed
    local shouldShowTutorial = tutorialData and not isTutorialCompleted
    
    -- Screen size detection for responsive design
    local screenSize, setScreenSize = React.useState(Vector2.new(1024, 768))
    local scale = ScreenUtils.getProportionalScale(screenSize)
    
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
        setGamepassVisible(false)
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
        setRebirthVisible(false)
    end
    
    
    local function handleCloseAll()
        setInventoryVisible(false)
        setShopVisible(false)
        setWeatherVisible(false)
        setGamepassVisible(false)
        setRebirthVisible(false)
        setPlotUIVisible(false)
        setCropViewVisible(false)
        setPlantingVisible(false)
    end
    
    -- Plot UI handlers
    local function handlePlotInteraction(plotData)
        -- If plot is empty, directly open planting panel instead of plot UI
        if plotData.state == "empty" then
            setSelectedPlotForPlanting({
                plotData = plotData,
                mode = "single"
            })
            setPlantingVisible(true)
            -- Close other panels
            setInventoryVisible(false)
            setShopVisible(false)
            setWeatherVisible(false)
            setGamepassVisible(false)
            setRebirthVisible(false)
            setCropViewVisible(false)
            setPlotUIVisible(false)
        else
            -- For planted plots, show the plot UI
            setSelectedPlotData(plotData)
            setPlotUIVisible(true)
            -- Close other panels
            setInventoryVisible(false)
            setShopVisible(false)
            setWeatherVisible(false)
            setGamepassVisible(false)
            setRebirthVisible(false)
            setCropViewVisible(false)
            setPlantingVisible(false)
        end
    end
    
    -- Planting panel handlers
    local function handlePlantAllSameCrop(plotData)
        if not plotData or not plotData.seedType then
            log.warn("Cannot plant all - no seed type in plot data")
            return
        end
        
        local seedType = plotData.seedType
        local availableSeeds = (playerData.inventory and playerData.inventory.crops and playerData.inventory.crops[seedType]) or 0
        
        if availableSeeds <= 0 then
            log.info("No", seedType, "seeds available to plant")
            return
        end
        
        -- Calculate how many we can plant (current + available, up to any plot limit)
        local currentPlanted = plotData.harvestCount or 1
        local maxPerPlot = 1000 -- Default max if no limit specified
        
        -- Check if there's a crop limit from GameConfig
        if playerData.gameConfig and playerData.gameConfig.crops and playerData.gameConfig.crops[seedType] then
            local cropConfig = playerData.gameConfig.crops[seedType]
            maxPerPlot = cropConfig.maxPerPlot or maxPerPlot
        end
        
        local canPlantMore = maxPerPlot - currentPlanted
        local quantityToPlant = math.min(availableSeeds, canPlantMore)
        
        if quantityToPlant <= 0 then
            log.info("Plot already at maximum capacity for", seedType)
            return
        end
        
        log.info("Planting all available", seedType, "- quantity:", quantityToPlant, "on plot:", plotData.plotId)
        
        -- Plant the seeds directly without opening UI
        if remotes.farmAction then
            -- Limit to 50 per the server's validation (most common case)
            local batchSize = math.min(quantityToPlant, 50)
            remotes.farmAction:FireServer("plant", plotData.plotId, seedType, batchSize)
            
            -- If there are more than 50, the user can click Plant All again
            if quantityToPlant > 50 then
                log.info("Planted 50", seedType, "- click Plant All again to plant remaining", quantityToPlant - 50)
            end
        end
        
        -- Don't close the plot UI - let user continue managing the plot
    end
    
    local function handlePlantingRequest(plotData, mode)
        setSelectedPlotForPlanting({
            plotData = plotData,
            mode = mode or "single" -- "single" or "all"
        })
        setPlantingVisible(true)
        -- Close other panels
        setInventoryVisible(false)
        setShopVisible(false)
        setWeatherVisible(false)
        setGamepassVisible(false)
        setRebirthVisible(false)
        setCropViewVisible(false)
        setPlotUIVisible(false)
    end
    
    local function handlePlantSeed(seedType, quantity)
        quantity = quantity or 1 -- Default to 1 if no quantity specified
        local plotData = selectedPlotForPlanting and selectedPlotForPlanting.plotData
        log.info("Planting seed:", seedType, "quantity:", quantity, "on plot:", plotData and plotData.plotId)
        
        if remotes.farmAction and plotData then
            remotes.farmAction:FireServer("plant", plotData.plotId, seedType, quantity)
        end
        
        -- Close planting panel and open plot UI automatically
        setPlantingVisible(false)
        setSelectedPlotForPlanting(nil)
        
        -- Wait a brief moment for the plant action to process, then open plot UI
        if plotData then
            -- Create updated plot data (it will be "planted" now instead of "empty")
            local updatedPlotData = {}
            for k, v in pairs(plotData) do
                updatedPlotData[k] = v
            end
            updatedPlotData.state = "planted"
            updatedPlotData.seedType = seedType
            
            -- Open plot UI with the updated plot data
            setSelectedPlotData(updatedPlotData)
            setPlotUIVisible(true)
        end
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
        setRebirthVisible(not rebirthVisible)
        -- Close other panels
        setInventoryVisible(false)
        setShopVisible(false)
        setWeatherVisible(false)
        setGamepassVisible(false)
        setCropViewVisible(false)
        setPlotUIVisible(false)
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
        IgnoreGuiInset = true, -- Ignore TopBar inset to allow positioning at very top
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    }, {
        -- Background click detector to close panels (only when panels are visible)
        -- Proportional space at bottom for controls
        ClickDetector = (inventoryVisible or shopVisible or weatherVisible or gamepassVisible or plantingVisible) and e("TextButton", {
            Name = "ClickDetector",
            Size = UDim2.new(1, 0, 1, -ScreenUtils.getProportionalSize(screenSize, 200)), -- Proportional space at bottom
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
                setInventoryVisible(not inventoryVisible)
                setShopVisible(false)
                setWeatherVisible(false)
                setCropViewVisible(false)
                setGamepassVisible(false)
            end,
            onWeatherClick = handleWeatherClick,
            onGamepassClick = handleGamepassClick,
            onRebirthClick = handleRebirthClick,
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
        
        -- Music Button Component (bottom right corner)
        MusicButton = e(MusicButton, {
            screenSize = screenSize,
            playerData = playerData,
            remotes = remotes
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
        
        -- Rebirth Panel Component
        RebirthPanel = rebirthVisible and e(RebirthPanel, {
            visible = rebirthVisible,
            onClose = function() setRebirthVisible(false) end,
            playerData = playerData,
            remotes = remotes,
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
            onOpenPlanting = function(mode)
                if mode == "all" and selectedPlotData and selectedPlotData.seedType then
                    -- Plot already has crops - automatically plant more of the same type
                    handlePlantAllSameCrop(selectedPlotData)
                else
                    -- Empty plot or single plant mode - open planting panel
                    handlePlantingRequest(selectedPlotData, mode)
                end
            end,
            remotes = remotes,
            screenSize = screenSize
        }) or nil,
        
        -- Planting Panel Component
        PlantingPanel = plantingVisible and selectedPlotForPlanting and e(PlantingPanel, {
            plotData = selectedPlotForPlanting.plotData,
            plantingMode = selectedPlotForPlanting.mode,
            playerData = playerData,
            visible = plantingVisible,
            onClose = function()
                setPlantingVisible(false)
                setSelectedPlotForPlanting(nil)
            end,
            onPlant = handlePlantSeed,
            screenSize = screenSize
        }) or nil,
        
        -- Confetti Animation (shows on top of everything)
        ConfettiAnimation = e(ConfettiAnimation, {
            visible = confettiVisible,
            onComplete = function()
                setConfettiVisible(false)
            end,
            screenSize = screenSize
        }),
        
        -- Rewards Panel (shows on top of everything)
        RewardsPanel = e(RewardsPanel, {
            screenSize = screenSize
        })
    })
end

return MainUI