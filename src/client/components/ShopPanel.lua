-- Shop Panel Component  
-- Shows shop items with info and purchase buttons using card layout

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local e = React.createElement
local assets = require(game:GetService("ReplicatedStorage").Shared.assets)
local ClientLogger = require(script.Parent.Parent.ClientLogger)

local log = ClientLogger.getModuleLogger("ShopPanel")

local ShopSeedCard = require(script.Parent.ShopSeedCard)
local SeedDetailModal = require(script.Parent.SeedDetailModal)

local function ShopPanel(props)
    local playerData = props.playerData
    local visible = props.visible or false
    local onClose = props.onClose or function() end
    local remotes = props.remotes or {}
    
    -- Debug shop visibility
    React.useEffect(function()
        log.debug("ShopPanel visibility changed to:", visible)
        log.debug("ShopPanel BackgroundTransparency:", visible and 0.05 or 1)
        log.debug("ShopPanel Visible property:", visible)
    end, {visible})
    
    -- Responsive sizing
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local isMobile = screenSize.X < 768
    local scale = isMobile and 0.85 or 1
    local panelWidth = isMobile and 450 or 500
    local panelHeight = isMobile and 280 or 320
    
    -- Modal state
    local selectedSeed, setSelectedSeed = React.useState(nil)
    local modalVisible, setModalVisible = React.useState(false)
    
    -- Shop crops with pricing (matching server GameConfig.Plants basePrice)
    local shopSeeds = {
        {type = "wheat", price = 10},
        {type = "carrot", price = 25}, 
        {type = "tomato", price = 50},
        {type = "potato", price = 35},
        {type = "corn", price = 120}
    }
    
    -- Handle info button click
    local function handleSeedInfo(seedType)
        setSelectedSeed(seedType)
        setModalVisible(true)
    end
    
    -- Handle buy button click
    local function handleSeedPurchase(seedType, price)
        log.debug("Trying to buy:", seedType, "for", price, "- remotes.buy exists:", remotes.buy ~= nil)
        if remotes.buy then
            remotes.buy:FireServer("crops", seedType, price)
            log.debug("Sent buy request to server")
        else
            log.error("remotes.buy is nil!")
        end
    end
    
    -- Handle modal purchase
    local function handleModalPurchase(seedType, price)
        handleSeedPurchase(seedType, price)
    end
    
    -- Handle modal close
    local function handleModalClose()
        setModalVisible(false)
        setSelectedSeed(nil)
    end
    
    return React.createElement(React.Fragment, {}, {
        -- Main Shop Panel
        ShopPanel = e("Frame", {
            Name = "ShopPanel",
            Size = UDim2.new(0, panelWidth * scale, 0, panelHeight * scale),
            Position = UDim2.new(0.5, -panelWidth * scale / 2, 0.5, -panelHeight * scale / 2), -- Center the panel
            BackgroundColor3 = Color3.fromRGB(30, 25, 35),
            BackgroundTransparency = visible and 0.05 or 1,
            BorderSizePixel = 0,
            Visible = visible,
            ZIndex = 12
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 15)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(210, 150, 100),
                Thickness = 3,
                Transparency = 0.3
            }),
            Gradient = e("UIGradient", {
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 35, 45)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 20, 30))
                },
                Rotation = 45
            }),
            
            -- Close Button
            CloseButton = e("ImageButton", {
                Name = "CloseButton",
                Size = UDim2.new(0, 30, 0, 30),
                Position = UDim2.new(1, -40, 0, 10),
                Image = assets["X Button/X Button 64.png"],
                ImageColor3 = Color3.fromRGB(255, 100, 100),
                ScaleType = Enum.ScaleType.Fit,
                BackgroundColor3 = Color3.fromRGB(50, 25, 25),
                BorderSizePixel = 0,
                ZIndex = 14,
                [React.Event.Activated] = onClose
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0.5, 0)
                })
            }),
            
            -- Title
            Title = e("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -60, 0, 30),
                Position = UDim2.new(0, 20, 0, 15),
                Text = "🛒 Seed Shop",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 13
            }),
            
            -- Seeds Section Title
            SeedsTitle = e("TextLabel", {
                Name = "SeedsTitle",
                Size = UDim2.new(1, -40, 0, 25),
                Position = UDim2.new(0, 20, 0, 55),
                Text = "🌱 Buy Seeds (Info & Purchase)",
                TextColor3 = Color3.fromRGB(255, 200, 100),
                TextScaled = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 13
            }),
            
            -- Seeds Grid Container
            SeedsContainer = e("ScrollingFrame", {
                Name = "SeedsContainer",
                Size = UDim2.new(1, -40, 0, 200),
                Position = UDim2.new(0, 20, 0, 85),
                BackgroundColor3 = Color3.fromRGB(20, 15, 25),
                BackgroundTransparency = 0.3,
                BorderSizePixel = 0,
                ScrollBarThickness = 8,
                ScrollingDirection = Enum.ScrollingDirection.X, -- Horizontal scrolling only
                CanvasSize = UDim2.new(0, 600, 0, 160), -- Scrollable width for multiple cards
                ZIndex = 13
            }, React.createElement("UICorner", {
                CornerRadius = UDim.new(0, 8)
            }), React.createElement("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                VerticalAlignment = Enum.VerticalAlignment.Top,
                Padding = UDim.new(0, 10)
            }), React.createElement("UIPadding", {
                PaddingTop = UDim.new(0, 10),
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10),
                PaddingBottom = UDim.new(0, 10)
            }), (function()
                local seedCards = {}
                for i, seedData in ipairs(shopSeeds) do
                    seedCards[seedData.type] = e(ShopSeedCard, {
                        seedType = seedData.type,
                        price = seedData.price,
                        onInfo = handleSeedInfo,
                        onBuy = handleSeedPurchase,
                        playerMoney = playerData.money or 0,
                        screenSize = screenSize
                    })
                end
                return seedCards
            end)())
        }),
        
        -- Seed Detail Modal
        SeedModal = modalVisible and e(SeedDetailModal, {
            seedType = selectedSeed,
            isVisible = modalVisible,
            onClose = handleModalClose,
            onPurchase = handleModalPurchase,
            playerMoney = playerData.money or 0,
            screenSize = screenSize
        }) or nil
    })
end

return ShopPanel