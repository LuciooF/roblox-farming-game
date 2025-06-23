-- Enhanced Inventory Panel Component  
-- Shows seeds as interactive cards with detailed information modal

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local e = React.createElement

local SeedCard = require(script.Parent.SeedCard)
local SeedDetailModal = require(script.Parent.SeedDetailModal)
local CropCard = require(script.Parent.CropCard)

local function InventoryPanel(props)
    local playerData = props.playerData or {}
    local visible = props.visible or false
    local onClose = props.onClose or function() end
    local remotes = props.remotes or {}
    
    -- Responsive sizing
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local isMobile = screenSize.X < 768
    local scale = isMobile and 0.85 or 1
    local panelWidth = isMobile and 450 or 500
    local panelHeight = isMobile and 400 or 450
    
    -- Modal state
    local selectedSeed, setSelectedSeed = React.useState(nil)
    local modalVisible, setModalVisible = React.useState(false)
    
    -- Available seeds with pricing (matching server GameConfig.Plants seedCost)
    local availableSeeds = {
        {type = "wheat", price = 10},
        {type = "carrot", price = 25}, 
        {type = "tomato", price = 50},
        {type = "potato", price = 35},
        {type = "corn", price = 120}
    }
    
    -- Get seed quantity from inventory
    local function getSeedQuantity(seedType)
        if playerData.inventory and playerData.inventory.seeds and playerData.inventory.seeds[seedType] then
            return playerData.inventory.seeds[seedType]
        end
        return 0
    end
    
    -- Handle seed card click
    local function handleSeedClick(seedType)
        setSelectedSeed(seedType)
        setModalVisible(true)
    end
    
    -- Handle seed purchase
    local function handleSeedPurchase(seedType, price)
        if remotes.buyRemote then
            remotes.buyRemote:FireServer("seeds", seedType, price)
        end
    end
    
    -- Handle crop selling
    local function handleCropSell(cropType, quantity, totalValue)
        if remotes.sellRemote then
            remotes.sellRemote:FireServer(cropType, quantity)
        end
    end
    
    -- Get available crops for display
    local function getAvailableCrops()
        local crops = {}
        if playerData.inventory and playerData.inventory.crops then
            for cropType, count in pairs(playerData.inventory.crops) do
                if count > 0 then
                    table.insert(crops, {type = cropType, quantity = count})
                end
            end
        end
        return crops
    end
    
    -- Handle modal close
    local function handleModalClose()
        setModalVisible(false)
        setSelectedSeed(nil)
    end
    
    return React.createElement(React.Fragment, {}, {
        -- Main Inventory Panel
        InventoryPanel = e("Frame", {
            Name = "InventoryPanel",
            Size = UDim2.new(0, panelWidth * scale, 0, panelHeight * scale),
            Position = UDim2.new(0, (isMobile and 55 or 60) * scale, 0, (isMobile and 80 or 60) * scale),
            BackgroundColor3 = Color3.fromRGB(30, 35, 40),
            BackgroundTransparency = visible and 0.05 or 1,
            BorderSizePixel = 0,
            Visible = visible,
            ZIndex = 12
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 15)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(85, 255, 85),
                Thickness = 3,
                Transparency = 0.3
            }),
            Gradient = e("UIGradient", {
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 45, 50)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 30, 35))
                },
                Rotation = 45
            }),
            
            -- Close Button
            CloseButton = e("TextButton", {
                Name = "CloseButton",
                Size = UDim2.new(0, 30, 0, 30),
                Position = UDim2.new(1, -40, 0, 10),
                Text = "✕",
                TextColor3 = Color3.fromRGB(255, 100, 100),
                TextScaled = true,
                BackgroundColor3 = Color3.fromRGB(50, 25, 25),
                BorderSizePixel = 0,
                Font = Enum.Font.SourceSansBold,
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
                Text = "🎒 My Seeds",
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
                Text = "🌱 Your Seeds (Click for details)",
                TextColor3 = Color3.fromRGB(150, 255, 150),
                TextScaled = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 13
            }),
            
            -- Seeds Grid Container
            SeedsContainer = e("ScrollingFrame", {
                Name = "SeedsContainer",
                Size = UDim2.new(1, -40, 0, 140),
                Position = UDim2.new(0, 20, 0, 85),
                BackgroundColor3 = Color3.fromRGB(20, 25, 30),
                BackgroundTransparency = 0.3,
                BorderSizePixel = 0,
                ScrollBarThickness = 8,
                ScrollingDirection = Enum.ScrollingDirection.X, -- Horizontal scrolling only
                CanvasSize = UDim2.new(0, 600, 0, 140), -- Scrollable width for multiple cards
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
                for i, seedData in ipairs(availableSeeds) do
                    seedCards[seedData.type] = e(SeedCard, {
                        seedType = seedData.type,
                        quantity = getSeedQuantity(seedData.type),
                        price = seedData.price,
                        onClick = handleSeedClick,
                        screenSize = screenSize
                    })
                end
                return seedCards
            end)()),
            
            -- Separator Line
            Separator = e("Frame", {
                Name = "Separator",
                Size = UDim2.new(1, -40, 0, 2),
                Position = UDim2.new(0, 20, 0, 235),
                BackgroundColor3 = Color3.fromRGB(100, 100, 100),
                BorderSizePixel = 0,
                ZIndex = 13
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 1)
                })
            }),
            
            -- Crops Section Title
            CropsTitle = e("TextLabel", {
                Name = "CropsTitle",
                Size = UDim2.new(1, -40, 0, 25),
                Position = UDim2.new(0, 20, 0, 245),
                Text = "🥕 Harvested Crops (Click to sell)",
                TextColor3 = Color3.fromRGB(255, 200, 100),
                TextScaled = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 13
            }),
            
            -- Crops Grid Container
            CropsContainer = e("ScrollingFrame", {
                Name = "CropsContainer",
                Size = UDim2.new(1, -40, 0, 140),
                Position = UDim2.new(0, 20, 0, 275),
                BackgroundColor3 = Color3.fromRGB(25, 20, 30),
                BackgroundTransparency = 0.3,
                BorderSizePixel = 0,
                ScrollBarThickness = 8,
                ScrollingDirection = Enum.ScrollingDirection.X,
                CanvasSize = UDim2.new(0, math.max(600, #getAvailableCrops() * 110), 0, 140),
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
                local cropCards = {}
                local availableCrops = getAvailableCrops()
                
                -- If no crops, show a message
                if #availableCrops == 0 then
                    cropCards.EmptyMessage = e("TextLabel", {
                        Name = "EmptyMessage",
                        Size = UDim2.new(0, 200, 0, 60),
                        Text = "No crops harvested yet\n\nHarvest some plants to see them here!",
                        TextColor3 = Color3.fromRGB(150, 150, 150),
                        TextScaled = true,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.SourceSansItalic,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        ZIndex = 14
                    })
                else
                    -- Create crop cards
                    for i, cropData in ipairs(availableCrops) do
                        cropCards[cropData.type] = e(CropCard, {
                            cropType = cropData.type,
                            quantity = cropData.quantity,
                            onSell = handleCropSell,
                            screenSize = screenSize
                        })
                    end
                end
                
                return cropCards
            end)())
        }),
        
        -- Seed Detail Modal
        SeedModal = modalVisible and e(SeedDetailModal, {
            seedType = selectedSeed,
            isVisible = modalVisible,
            onClose = handleModalClose,
            onPurchase = handleSeedPurchase,
            playerMoney = playerData.money or 0,
            screenSize = screenSize
        }) or nil
    })
end

return InventoryPanel