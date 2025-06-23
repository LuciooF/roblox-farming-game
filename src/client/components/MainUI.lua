-- Main UI Component
-- Orchestrates all UI components with responsive design

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local e = React.createElement

-- Import components
local TopStats = require(script.Parent.TopStats)
local SideButtons = require(script.Parent.SideButtons)
local InventoryPanel = require(script.Parent.InventoryPanel)
local ShopPanel = require(script.Parent.ShopPanel)
local TutorialPanel = require(script.Parent.TutorialPanel)
local HotbarInventory = require(script.Parent.HotbarInventory)

local function MainUI(props)
    local playerData = props.playerData or {}
    local remotes = props.remotes or {}
    local tutorialData = props.tutorialData
    
    -- State management
    local inventoryVisible, setInventoryVisible = React.useState(false)
    local shopVisible, setShopVisible = React.useState(false)
    local tutorialVisible, setTutorialVisible = React.useState(tutorialData ~= nil)
    
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
        setShopVisible(not shopVisible)
        setInventoryVisible(false)
    end
    
    local function handleCloseAll()
        setInventoryVisible(false)
        setShopVisible(false)
    end
    
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
        elseif tutorialData and tutorialData.step then
            setTutorialVisible(true)
        end
    end, {tutorialData})
    
    return e("ScreenGui", {
        Name = "FarmingUIReact",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    }, {
        -- Background click detector to close panels (only when panels are visible)
        ClickDetector = (inventoryVisible or shopVisible) and e("TextButton", {
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
            onShopClick = handleShopClick
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
            remotes = remotes
        }),
        
        -- Tutorial Panel Component
        TutorialPanel = tutorialData and e(TutorialPanel, {
            tutorialData = tutorialData,
            screenSize = screenSize,
            visible = tutorialVisible,
            onNext = handleTutorialNext,
            onSkip = handleTutorialSkip
        }) or nil
    })
end

return MainUI