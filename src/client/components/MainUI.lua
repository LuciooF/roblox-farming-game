-- Main UI Component
-- Orchestrates all UI components with responsive design

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local e = React.createElement
local ScreenUtils = require(game:GetService("ReplicatedStorage").Shared.ScreenUtils)

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
local PlotUI = require(script.Parent.PlotUI)
local DebugPanel = require(script.Parent.DebugPanel)
local GamepassPanel = require(script.Parent.GamepassPanel)
local ConfettiAnimation = require(script.Parent.ConfettiAnimation)
local RebirthPanel = require(script.Parent.RebirthPanel)
local PlantingPanel = require(script.Parent.PlantingPanel)
local MusicButton = require(script.Parent.MusicButton)
local FlyButton = require(script.Parent.FlyButton)
local RewardsPanel = require(script.Parent.RewardsPanel)
local CodesPanel = require(script.Parent.CodesPanel)
local CodesButton = require(script.Parent.CodesButton)
local LikeFavoritePopup = require(script.Parent.LikeFavoritePopup)
local ProTipDisplay = require(script.Parent.ProTipDisplay)

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
    local codesVisible, setCodesVisible = React.useState(false)
    local likeFavoriteVisible, setLikeFavoriteVisible = React.useState(false)
    local likeFavoriteData, setLikeFavoriteData = React.useState(nil)
    
    -- ProTips state
    local currentProTip, setCurrentProTip = React.useState(nil)
    local showProTip, setShowProTip = React.useState(false)
    
    -- Track previous gamepass ownership to detect new purchases
    local previousGamepasses, setPreviousGamepasses = React.useState(nil) -- nil = not initialized yet
    
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
    
    -- Initialize ProTips manager
    React.useEffect(function()
        local ProTipsManager = require(script.Parent.Parent.ProTipsManager)
        
        ProTipsManager.init(function(tipText, visible)
            setCurrentProTip(tipText)
            setShowProTip(visible)
        end, function()
            -- Return current player data for rebirth checking
            return playerData
        end)
    end, {})
    
    -- Set up global handler for like/favorite popup
    React.useEffect(function()
        -- Make this accessible globally for CodesService
        _G.showLikeFavoritePopup = function(groupId, waitTimeSeconds)
            setLikeFavoriteData({
                groupId = groupId,
                waitTimeSeconds = waitTimeSeconds
            })
            setLikeFavoriteVisible(true)
        end
        
        return function()
            _G.showLikeFavoritePopup = nil
        end
    end, {})
    
    -- Event handlers
    local function handleShopClick()
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
        setCodesVisible(false)
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
            warn("Cannot plant all - no seed type in plot data")
            return
        end
        
        local seedType = plotData.seedType
        local availableSeeds = (playerData.inventory and playerData.inventory.crops and playerData.inventory.crops[seedType]) or 0
        
        if availableSeeds <= 0 then
            return
        end
        
        -- Calculate how many we can plant (matching PlotUI logic exactly)
        local MAX_PLANTS_PER_PLOT = 50
        local maxHarvests = plotData.maxHarvests or 0
        local harvestCount = plotData.harvestCount or 0
        local activePlants = maxHarvests - harvestCount
        local currentPlantCount = plotData.state == "empty" and 0 or activePlants
        local availableSpace = MAX_PLANTS_PER_PLOT - currentPlantCount
        
        local quantityToPlant = math.min(availableSeeds, availableSpace)
        
        if quantityToPlant <= 0 then
            return
        end
        
        
        -- Plant the seeds directly without opening UI
        if remotes.farmAction then
            remotes.farmAction:FireServer("plant", plotData.plotId, seedType, quantityToPlant)
        end
        
        -- Don't close the plot UI - let user continue managing the plot
    end
    
    local function handlePlantOneSameCrop(plotData)
        if not plotData or not plotData.seedType then
            warn("Cannot plant one - no seed type in plot data")
            return
        end
        
        local seedType = plotData.seedType
        local availableSeeds = (playerData.inventory and playerData.inventory.crops and playerData.inventory.crops[seedType]) or 0
        
        if availableSeeds <= 0 then
            return
        end
        
        -- Calculate if we can plant 1 more (matching PlotUI logic)
        local MAX_PLANTS_PER_PLOT = 50
        local maxHarvests = plotData.maxHarvests or 0
        local harvestCount = plotData.harvestCount or 0
        local activePlants = maxHarvests - harvestCount
        local currentPlantCount = plotData.state == "empty" and 0 or activePlants
        local availableSpace = MAX_PLANTS_PER_PLOT - currentPlantCount
        
        if availableSpace <= 0 then
            return
        end
        
        -- Plant exactly 1 seed
        if remotes.farmAction then
            remotes.farmAction:FireServer("plant", plotData.plotId, seedType, 1)
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
            warn("❌ No onPlotUIHandler prop provided to MainUI")
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
    
    local function handleCodesClick()
        setCodesVisible(not codesVisible)
        -- Close other panels
        setInventoryVisible(false)
        setShopVisible(false)
        setWeatherVisible(false)
        setGamepassVisible(false)
        setRebirthVisible(false)
        setCropViewVisible(false)
        setPlotUIVisible(false)
        setPlantingVisible(false)
    end
    
    local function handlePurchase(itemType, item, price)
        if remotes.buyRemote then
            remotes.buyRemote:FireServer(itemType, item, price)
        end
    end
    
    local function handleGamepassPurchase(gamepassKey)
        
        -- Send request to server to handle the purchase
        if remotes.gamepassPurchase then
            remotes.gamepassPurchase:FireServer(gamepassKey)
        else
            warn("Gamepass purchase remote not available")
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
        if playerData.gamepasses then
            
            -- Only check for new purchases if we have previous state (not first initialization)
            if previousGamepasses ~= nil then
                -- Check if player acquired any new gamepasses
                local gamepassCount = 0
                for gamepassKey, owned in pairs(playerData.gamepasses) do
                    gamepassCount = gamepassCount + 1
                    if owned and not previousGamepasses[gamepassKey] then
                        -- Player just got a new gamepass! Show confetti
                        setConfettiVisible(true)
                        break -- Only show confetti once even if multiple gamepasses purchased
                    end
                end
            else
            end
            
            -- Update previous gamepasses for next comparison
            setPreviousGamepasses(playerData.gamepasses)
        else
            warn("No gamepasses in playerData")
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
        ClickDetector = (inventoryVisible or shopVisible or weatherVisible or gamepassVisible or plantingVisible or codesVisible or rebirthVisible) and e("TextButton", {
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
                -- Check if player is authorized for debug UI
                local remoteFolder = game:GetService("ReplicatedStorage"):WaitForChild("FarmingRemotes")
                local checkDebugAuth = remoteFolder:FindFirstChild("CheckDebugAuth")
                
                if checkDebugAuth then
                    local success, isAuthorized = pcall(function()
                        return checkDebugAuth:InvokeServer()
                    end)
                    
                    if success and isAuthorized then
                        -- Toggle debug panel for authorized users
                        DebugPanel.toggle()
                    else
                        -- Not authorized - do nothing (silent)
                        -- Could show "Pets coming soon" tooltip here if desired
                    end
                else
                    -- RemoteFunction not found - probably in studio
                    -- For testing purposes, allow in studio
                    DebugPanel.toggle()
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
            remotes = remotes,
            tutorialData = tutorialData
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
            gamepassData = gamepassData,
            weatherData = props.weatherData or {},
            screenSize = screenSize
        }),
        
        -- Music Button Component (bottom right corner)
        MusicButton = e(MusicButton, {
            screenSize = screenSize,
            playerData = playerData,
            remotes = remotes
        }),
        
        -- Fly Button Component (above music button)
        FlyButton = e(FlyButton, {
            screenSize = screenSize,
            playerData = playerData,
            onGamepassToggle = handleGamepassClick
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
            weatherData = props.weatherData or {},
            visible = plotUIVisible,
            screenSize = props.screenSize,
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
                elseif mode == "one" and selectedPlotData and selectedPlotData.seedType then
                    -- Plot already has crops - automatically plant 1 more of the same type
                    handlePlantOneSameCrop(selectedPlotData)
                else
                    -- Empty plot or other modes - open planting panel
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
            screenSize = props.screenSize,
            onClose = function()
                setPlantingVisible(false)
                setSelectedPlotForPlanting(nil)
            end,
            onPlant = handlePlantSeed,
            onOpenShop = function()
                setShopVisible(true)
                setPlantingVisible(false)
                setSelectedPlotForPlanting(nil)
            end,
            screenSize = screenSize
        }) or nil,
        
        -- Codes Panel Component
        CodesPanel = codesVisible and e(CodesPanel, {
            visible = codesVisible,
            onClose = function() setCodesVisible(false) end,
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
        }),
        
        -- Rewards Panel (shows on top of everything)
        RewardsPanel = e(RewardsPanel, {
            screenSize = screenSize
        }),
        
        -- Codes Button (always visible on right side)
        CodesButton = e(CodesButton, {
            onClick = handleCodesClick,
            screenSize = screenSize
        }),
        
        -- Like/Favorite Popup (shows on top of everything)
        LikeFavoritePopup = likeFavoriteVisible and likeFavoriteData and e(LikeFavoritePopup, {
            visible = likeFavoriteVisible,
            onClose = function() setLikeFavoriteVisible(false) end,
            groupId = likeFavoriteData.groupId,
            waitTimeSeconds = likeFavoriteData.waitTimeSeconds,
            screenSize = screenSize
        }) or nil,
        
        -- Pro Tips Display (shows at bottom center with rainbow effect)
        ProTipDisplay = e(ProTipDisplay, {
            tipText = currentProTip,
            visible = showProTip,
            screenSize = screenSize
        })
    })
end

return MainUI