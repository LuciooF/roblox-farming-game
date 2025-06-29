-- Modern Inventory Panel Component  
-- Modern card-grid layout matching ShopPanel design
-- Shows crops with beautiful cards, quantities, and sell options

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local e = React.createElement
local assets = require(game:GetService("ReplicatedStorage").Shared.assets)
local CropRegistry = require(game:GetService("ReplicatedStorage").Shared.CropRegistry)
local NumberFormatter = require(game:GetService("ReplicatedStorage").Shared.NumberFormatter)
local ScreenUtils = require(game:GetService("ReplicatedStorage").Shared.ScreenUtils)

-- Simple logging functions for InventoryPanel
local function logInfo(...) print("[INFO] InventoryPanel:", ...) end
local function logDebug(...) print("[DEBUG] InventoryPanel:", ...) end

-- Sound IDs for button interactions
local HOVER_SOUND_ID = "rbxassetid://15675059323"
local CLICK_SOUND_ID = "rbxassetid://6324790483"

-- Pre-create sounds for better performance
local hoverSound = Instance.new("Sound")
hoverSound.SoundId = HOVER_SOUND_ID
hoverSound.Volume = 0.3
hoverSound.Parent = SoundService

local clickSound = Instance.new("Sound")
clickSound.SoundId = CLICK_SOUND_ID
clickSound.Volume = 0.4
clickSound.Parent = SoundService

-- Function to play sound effects
local function playSound(soundType)
    if soundType == "hover" and hoverSound then
        hoverSound:Play()
    elseif soundType == "click" and clickSound then
        clickSound:Play()
    end
end

-- Function to create flip animation for icons
local function createFlipAnimation(iconRef, animationTracker)
    if not iconRef.current then return end
    
    -- Cancel any existing animation for this icon
    if animationTracker.current then
        animationTracker.current:Cancel()
        animationTracker.current:Destroy()
        animationTracker.current = nil
    end
    
    -- Reset rotation to 0 to prevent accumulation
    iconRef.current.Rotation = 0
    
    -- Create new animation
    animationTracker.current = TweenService:Create(
        iconRef.current,
        TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Rotation = 360 }
    )
    
    animationTracker.current:Play()
end

local function InventoryPanel(props)
    local playerData = props.playerData
    local visible = props.visible or false
    local onClose = props.onClose or function() end
    local remotes = props.remotes or {}
    
    -- Debug inventory visibility
    React.useEffect(function()
        logDebug("InventoryPanel visibility changed to:", visible)
    end, {visible})
    
    -- Responsive sizing (same as shop)
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local scale = ScreenUtils.getProportionalScale(screenSize)
    local aspectRatio = screenSize.X / screenSize.Y
    
    -- Proportional text sizes
    local titleTextSize = ScreenUtils.getProportionalTextSize(screenSize, 32)
    local normalTextSize = ScreenUtils.getProportionalTextSize(screenSize, 18)
    local smallTextSize = ScreenUtils.getProportionalTextSize(screenSize, 14)
    local buttonTextSize = ScreenUtils.getProportionalTextSize(screenSize, 16)
    local cardTitleSize = ScreenUtils.getProportionalTextSize(screenSize, 20)
    local cardValueSize = ScreenUtils.getProportionalTextSize(screenSize, 16)
    
    -- Dynamic panel sizing based on screen dimensions
    local panelWidth = math.min(screenSize.X * 0.9, ScreenUtils.getProportionalSize(screenSize, 1100))
    local panelHeight = math.min(screenSize.Y * 0.85, ScreenUtils.getProportionalSize(screenSize, 750))
    
    -- Card sizing - dynamically adjust columns based on available width
    local minCardWidth = ScreenUtils.getProportionalSize(screenSize, 220)
    local cardsPerRow = math.max(2, math.floor((panelWidth - 100) / (minCardWidth + 15)))
    local availableWidth = panelWidth - 100
    local cardWidth = math.floor((availableWidth / cardsPerRow) - 15)
    local cardHeight = ScreenUtils.getProportionalSize(screenSize, 260) -- Fixed proportional height for stacked buttons
    
    -- Get inventory items from all crop types
    local inventoryItems = {}
    
    -- Check crops inventory
    if playerData.inventory and playerData.inventory.crops then
        for cropId, quantity in pairs(playerData.inventory.crops) do
            if quantity > 0 then
                local crop = CropRegistry.getCrop(cropId)
                local visual = crop -- Use crop data directly since it contains all visual info
                if crop and visual then
                    table.insert(inventoryItems, {
                        type = cropId,
                        quantity = quantity,
                        category = "crops",
                        crop = crop,
                        visual = visual,
                        sellPrice = crop.basePrice or 1
                    })
                end
            end
        end
    end
    
    -- Sort by rarity, then by name
    table.sort(inventoryItems, function(a, b)
        if a.crop.rarity == b.crop.rarity then
            return a.crop.name < b.crop.name
        end
        -- Custom rarity order
        local rarityOrder = {common = 1, uncommon = 2, rare = 3, epic = 4, legendary = 5}
        return (rarityOrder[a.crop.rarity] or 1) < (rarityOrder[b.crop.rarity] or 1)
    end)
    
    -- Calculate grid dimensions
    local totalRows = math.ceil(#inventoryItems / cardsPerRow)
    -- Account for: card heights + spacing between rows + top/bottom padding
    -- Multiply by 1.3 for safety buffer without excessive empty space
    local totalHeight = ((totalRows * cardHeight) + ((totalRows - 1) * 20) + 40) * 1.3
    
    -- Handle crop sale
    local function handleCropSale(cropType, sellPrice)
        if remotes.sell then
            -- Update the global lastActionTime for sale detection
            _G.lastActionTime = tick()
            remotes.sell:FireServer(cropType, 1) -- Sell 1 at a time
            playSound("click")
        end
    end
    
    -- Handle sell all of specific crop type
    local function handleCropSellAll(cropType, quantity)
        if remotes.sell then
            -- Update the global lastActionTime for sale detection
            _G.lastActionTime = tick()
            remotes.sell:FireServer(cropType, quantity) -- Sell all of this crop
            playSound("click")
        end
    end
    
    -- Handle sell all
    local function handleSellAll()
        if remotes.automation then
            remotes.automation:FireServer("sellAll")
            playSound("click")
        end
    end
    
    -- Rarity colors for borders and effects (same as shop)
    local rarityColors = {
        common = {Color3.fromRGB(150, 150, 150), Color3.fromRGB(180, 180, 180)},
        uncommon = {Color3.fromRGB(100, 255, 100), Color3.fromRGB(150, 255, 150)}, 
        rare = {Color3.fromRGB(100, 100, 255), Color3.fromRGB(150, 150, 255)},
        epic = {Color3.fromRGB(255, 100, 255), Color3.fromRGB(255, 150, 255)},
        legendary = {Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 235, 50)}
    }
    
    return e("Frame", {
        Name = "InventoryContainer",
        Size = UDim2.new(0, panelWidth * scale, 0, panelHeight * scale + 50), -- Extra space for floating title
        Position = UDim2.new(0.5, -panelWidth * scale / 2, 0.5, -(panelHeight * scale + 50) / 2),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = visible,
        ZIndex = 30
    }, {
        
        InventoryPanel = e("Frame", {
            Name = "InventoryPanel",
            Size = UDim2.new(0, panelWidth * scale, 0, panelHeight * scale),
            Position = UDim2.new(0, 0, 0, 50), -- Below floating title
            BackgroundColor3 = Color3.fromRGB(240, 245, 255),
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
            ZIndex = 30
        }, {
            -- Floating Title (positioned very close to main panel)
            FloatingTitle = e("Frame", {
                Name = "FloatingTitle",
                Size = UDim2.new(0, 260, 0, 40),
                Position = UDim2.new(0, -10, 0, -25), -- Much closer to main panel
                BackgroundColor3 = Color3.fromRGB(100, 200, 100),
                BorderSizePixel = 0,
                ZIndex = 32
            }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 12)
            }),
            Gradient = e("UIGradient", {
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 220, 120)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 180, 80))
                },
                Rotation = 45
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(255, 255, 255),
                Thickness = 3,
                Transparency = 0.2
            }),
            -- Title Content Container
            TitleContent = e("Frame", {
                Size = UDim2.new(1, -10, 1, 0),
                Position = UDim2.new(0, 5, 0, 0),
                BackgroundTransparency = 1,
                ZIndex = 33
            }, {
                Layout = e("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 5),
                    SortOrder = Enum.SortOrder.LayoutOrder
                }),
                
                InventoryIcon = e("ImageLabel", {
                    Name = "InventoryIcon",
                    Size = UDim2.new(0, 24, 0, 24),
                    Image = assets["General/Barn/Barn Outline 256.png"] or "",
                    BackgroundTransparency = 1,
                    ScaleType = Enum.ScaleType.Fit,
                    ImageColor3 = Color3.fromRGB(255, 255, 255),
                    ZIndex = 34,
                    LayoutOrder = 1
                }),
                
                TitleText = e("TextLabel", {
                    Size = UDim2.new(0, 0, 1, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    Text = "INVENTORY",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = titleTextSize,
            TextWrapped = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    ZIndex = 34,
                    LayoutOrder = 2
                }, {
                    TextStroke = e("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = 2,
                        Transparency = 0.5
                    })
                })
            })
        }),
        Corner = e("UICorner", {
            CornerRadius = UDim.new(0, 20)
        }),
        Stroke = e("UIStroke", {
            Color = Color3.fromRGB(100, 200, 100),
            Thickness = 3,
            Transparency = 0.1
        }),
        Gradient = e("UIGradient", {
            Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(0.3, Color3.fromRGB(240, 250, 255)),
                ColorSequenceKeypoint.new(0.7, Color3.fromRGB(230, 240, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 235, 255))
            },
            Rotation = 135
        }),
        
        -- Close Button (partially outside main panel, square with 3D effect)
        CloseButton = e("ImageButton", {
            Name = "CloseButton",
            Size = UDim2.new(0, 32, 0, 32),
            Position = UDim2.new(1, -16, 0, -16), -- Half outside the panel
            Image = assets["X Button/X Button 64.png"],
            ImageColor3 = Color3.fromRGB(255, 255, 255), -- Pure white text
            ScaleType = Enum.ScaleType.Fit,
            BackgroundColor3 = Color3.fromRGB(255, 100, 100),
            BorderSizePixel = 0,
            ZIndex = 34, -- Higher ZIndex to be above everything
            [React.Event.Activated] = onClose
        }, {
            -- Text stroke to make white text stand out
            TextStroke = e("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 2,
                Transparency = 0.3,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
            }),
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 6) -- Square with rounded corners
            }),
            Gradient = e("UIGradient", {
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 140, 140)), -- Lighter top for 3D effect
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 60, 60))     -- Darker bottom for 3D effect
                },
                Rotation = 90 -- Vertical gradient for 3D effect
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(255, 255, 255),
                Thickness = 2,
                Transparency = 0.2
            }),
            -- 3D Shadow effect
            Shadow = e("Frame", {
                Name = "Shadow",
                Size = UDim2.new(1, 2, 1, 2),
                Position = UDim2.new(0, 2, 0, 2),
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundTransparency = 0.7,
                BorderSizePixel = 0,
                ZIndex = 33 -- Behind the button
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 6)
                })
            })
        }),
        
        -- Subtitle (compact, under the floating title)
        Subtitle = e("TextLabel", {
            Name = "Subtitle",
            Size = UDim2.new(1, -80, 0, 25),
            Position = UDim2.new(0, 40, 0, 15),
            Text = "Manage your crops and items!",
            TextColor3 = Color3.fromRGB(60, 80, 140),
            TextSize = smallTextSize,
            TextWrapped = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 31
        }),
        
        -- Sell All Button (calculate total value)
        SellAllButton = (function()
            local totalValue = 0
            for _, item in ipairs(inventoryItems) do
                totalValue = totalValue + (item.quantity * item.sellPrice)
            end
            
            -- Determine button width based on total value text length
            local buttonText = "SELL ALL ( " .. NumberFormatter.format(totalValue) .. ")"
            local buttonWidth = math.max(200, 140 + (string.len(buttonText) * 6))
            
            return e("TextButton", {
                Name = "SellAllButton",
                Size = UDim2.new(0, buttonWidth, 0, 35),
                Position = UDim2.new(1, -buttonWidth - 10, 0, 10),
                Text = "",
                BackgroundColor3 = Color3.fromRGB(255, 165, 0),
                BorderSizePixel = 0,
                ZIndex = 32,
                [React.Event.Activated] = handleSellAll
            }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 8)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(200, 130, 0),
                Thickness = 2,
                Transparency = 0.2
            }),
            Gradient = e("UIGradient", {
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 185, 50)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 145, 0))
                },
                Rotation = 90
            }),
            
            -- Button content container
            ButtonContent = e("Frame", {
                Name = "ButtonContent",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                ZIndex = 33
            }, {
                Layout = e("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 5),
                    SortOrder = Enum.SortOrder.LayoutOrder
                }),
                
                SellAllText = e("TextLabel", {
                    Name = "SellAllText",
                    Size = UDim2.new(0, 0, 1, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    Text = "SELL ALL (",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = buttonTextSize,
            TextWrapped = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.SourceSansBold,
                    ZIndex = 34,
                    LayoutOrder = 1
                }, {
                    TextStroke = e("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = 2,
                        Transparency = 0.5
                    })
                }),
                
                SellIcon = e("ImageLabel", {
                    Name = "SellIcon",
                    Size = UDim2.new(0, 20, 0, 20),
                    Image = assets["Currency/Cash/Cash Outline 256.png"] or "",
                    BackgroundTransparency = 1,
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 34,
                    LayoutOrder = 2
                }),
                
                SellAllAmount = e("TextLabel", {
                    Name = "SellAllAmount",
                    Size = UDim2.new(0, 0, 1, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    Text = " " .. NumberFormatter.format(totalValue) .. ")",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = normalTextSize,
            TextWrapped = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.SourceSansBold,
                    ZIndex = 34,
                    LayoutOrder = 3
                }, {
                    TextStroke = e("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = 2,
                        Transparency = 0.5
                    })
                })
            })
            })
        end)(),
        
        -- Scrollable Cards Container
        CardsContainer = e("ScrollingFrame", {
            Name = "CardsContainer",
            Size = UDim2.new(1, -40, 1, -60),
            Position = UDim2.new(0, 20, 0, 50),
            BackgroundColor3 = Color3.fromRGB(250, 252, 255),
            BackgroundTransparency = 0.2,
            BorderSizePixel = 0,
            ScrollBarThickness = 12,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            CanvasSize = UDim2.new(0, 0, 0, totalHeight),
            ScrollBarImageColor3 = Color3.fromRGB(100, 200, 100),
            ZIndex = 31
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 15)
            }),
            ContainerGradient = e("UIGradient", {
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(245, 255, 245))
                },
                Rotation = 45
            }),
            
            -- Grid Layout
            GridLayout = e("UIGridLayout", {
                CellSize = UDim2.new(0, cardWidth, 0, cardHeight),
                CellPadding = UDim2.new(0, 20, 0, 20),
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Top,
                SortOrder = Enum.SortOrder.LayoutOrder
            }),
            
            Padding = e("UIPadding", {
                PaddingTop = UDim.new(0, 20),
                PaddingLeft = UDim.new(0, 20),
                PaddingRight = UDim.new(0, 20),
                PaddingBottom = UDim.new(0, 20)
            }),
            
            -- Generate inventory cards
            InventoryCards = React.createElement(React.Fragment, {}, (function()
                local cards = {}
                
                -- Show enhanced empty state if no items
                if #inventoryItems == 0 then
                    cards["emptyState"] = e("Frame", {
                        Name = "EmptyState",
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        ZIndex = 32
                    }, {
                        EmptyContainer = e("Frame", {
                            Size = UDim2.new(0, 400, 0, 300),
                            Position = UDim2.new(0.5, -200, 0.5, -150),
                            BackgroundColor3 = Color3.fromRGB(250, 250, 250),
                            BackgroundTransparency = 0.3,
                            BorderSizePixel = 0,
                            ZIndex = 33
                        }, {
                            Corner = e("UICorner", {
                                CornerRadius = UDim.new(0, 20)
                            }),
                            Stroke = e("UIStroke", {
                                Color = Color3.fromRGB(200, 200, 200),
                                Thickness = 2,
                                Transparency = 0.5
                            }),
                            
                            EmptyIcon = e("TextLabel", {
                                Size = UDim2.new(0, 120, 0, 120),
                                Position = UDim2.new(0.5, -60, 0, 30),
                                Text = "🏪",
                                TextSize = normalTextSize,
            TextWrapped = true,
                                BackgroundTransparency = 1,
                                Font = Enum.Font.SourceSansBold,
                                ZIndex = 34
                            }),
                            EmptyTitle = e("TextLabel", {
                                Size = UDim2.new(1, -40, 0, 40),
                                Position = UDim2.new(0, 20, 0, 160),
                                Text = "Inventory Empty",
                                TextColor3 = Color3.fromRGB(80, 80, 80),
                                TextSize = normalTextSize,
            TextWrapped = true,
                                BackgroundTransparency = 1,
                                Font = Enum.Font.GothamBold,
                                TextXAlignment = Enum.TextXAlignment.Center,
                                ZIndex = 34
                            }),
                            EmptyText = e("TextLabel", {
                                Size = UDim2.new(1, -40, 0, 60),
                                Position = UDim2.new(0, 20, 0, 210),
                                Text = "Visit the shop to buy seeds and start farming!\nYour harvested crops will appear here.",
                                TextColor3 = Color3.fromRGB(120, 120, 120),
                                TextSize = 16,
                                BackgroundTransparency = 1,
                                Font = Enum.Font.Gotham,
                                TextXAlignment = Enum.TextXAlignment.Center,
                                TextWrapped = true,
                                ZIndex = 34
                            })
                        })
                    })
                else
                    -- Generate item cards
                    for i, itemData in ipairs(inventoryItems) do
                        local rarity = itemData.crop.rarity or "common"
                        local colors = rarityColors[rarity] or rarityColors.common
                        
                        -- Animation refs - simplified without React.useRef in loop
                        local cropIconRef = {current = nil}
                        local sellIconRef = {current = nil}
                        local cropAnimTracker = {current = nil}
                        local sellAnimTracker = {current = nil}
                        
                        cards[itemData.type] = e("TextButton", {
                            Name = itemData.type .. "Card",
                            Text = "",
                            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                            BackgroundTransparency = 0.05,
                            BorderSizePixel = 0,
                            ZIndex = 32,
                            LayoutOrder = i,
                            AutoButtonColor = false,
                            [React.Event.MouseEnter] = function()
                                playSound("hover")
                                createFlipAnimation(cropIconRef, cropAnimTracker)
                            end,
                            [React.Event.Activated] = function()
                                handleCropSale(itemData.type, itemData.sellPrice)
                                createFlipAnimation(cropIconRef, cropAnimTracker)
                                createFlipAnimation(sellIconRef, sellAnimTracker)
                            end
                        }, {
                            Corner = e("UICorner", {
                                CornerRadius = UDim.new(0, 15)
                            }),
                            
                            -- Card Gradient Background
                            CardGradient = e("UIGradient", {
                                Color = ColorSequence.new{
                                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                                    ColorSequenceKeypoint.new(1, Color3.fromRGB(248, 252, 255))
                                },
                                Rotation = 45
                            }),
                            
                            Stroke = e("UIStroke", {
                                Color = colors[1],
                                Thickness = 3,
                                Transparency = 0.1
                            }),
                            
                            -- Black outline for card
                            BlackOutline = e("UIStroke", {
                                Color = Color3.fromRGB(0, 0, 0),
                                Thickness = 1,
                                Transparency = 0.7,
                                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                            }),
                            
                            -- Crop Icon
                            CropIcon = itemData.visual and itemData.visual.assetId and e("ImageLabel", {
                                Name = "CropIcon",
                                Size = UDim2.new(0, 60, 0, 60),
                                Position = UDim2.new(0.5, -30, 0, 15),
                                Image = itemData.visual.assetId:gsub("-64%.png", "-outline-256.png"):gsub("-256%.png", "-outline-256.png"),
                                BackgroundTransparency = 1,
                                ScaleType = Enum.ScaleType.Fit,
                                ZIndex = 33,
                                ref = cropIconRef
                            }) or e("TextLabel", {
                                Name = "CropEmoji",
                                Size = UDim2.new(1, 0, 0, 50),
                                Position = UDim2.new(0, 0, 0, 15),
                                Text = itemData.visual and itemData.visual.emoji or "🌱",
                                TextSize = normalTextSize,
            TextWrapped = true,
                                BackgroundTransparency = 1,
                                Font = Enum.Font.SourceSansBold,
                                ZIndex = 33,
                                ref = cropIconRef
                            }),
                            
                            -- Quantity Badge (top right)
                            QuantityBadge = e("Frame", {
                                Name = "QuantityBadge",
                                Size = UDim2.new(0, 30, 0, 20),
                                Position = UDim2.new(1, -35, 0, 5),
                                BackgroundColor3 = Color3.fromRGB(255, 165, 0),
                                BorderSizePixel = 0,
                                ZIndex = 34
                            }, {
                                Corner = e("UICorner", {
                                    CornerRadius = UDim.new(0, 10)
                                }),
                                QuantityText = e("TextLabel", {
                                    Size = UDim2.new(1, 0, 1, 0),
                                    Text = tostring(itemData.quantity),
                                    TextColor3 = Color3.fromRGB(255, 255, 255),
                                    TextSize = normalTextSize,
            TextWrapped = true,
                                    BackgroundTransparency = 1,
                                    Font = Enum.Font.GothamBold,
                                    ZIndex = 35
                                }, {
                                    TextStroke = e("UIStroke", {
                                        Color = Color3.fromRGB(0, 0, 0),
                                        Thickness = 2,
                                        Transparency = 0.5
                                    })
                                })
                            }),
                            
                            -- Crop Name
                            CropName = e("TextLabel", {
                                Name = "CropName",
                                Size = UDim2.new(1, -10, 0, 20),
                                Position = UDim2.new(0, 5, 0, 80),
                                Text = itemData.crop.name,
                                TextColor3 = Color3.fromRGB(40, 40, 40),
                                TextSize = cardTitleSize,
            TextWrapped = true,
                                BackgroundTransparency = 1,
                                Font = Enum.Font.SourceSansBold,
                                ZIndex = 33
                            }),
                            
                            -- Crop Description
                            CropDescription = e("TextLabel", {
                                Name = "CropDescription",
                                Size = UDim2.new(1, -10, 0, 25),
                                Position = UDim2.new(0, 5, 0, 100),
                                Text = itemData.crop.description or "A wonderful crop!",
                                TextColor3 = Color3.fromRGB(70, 80, 120),
                                TextSize = ScreenUtils.getProportionalTextSize(screenSize, 14),
                                BackgroundTransparency = 1,
                                Font = Enum.Font.Gotham,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                TextYAlignment = Enum.TextYAlignment.Top,
                                TextWrapped = true,
                                ZIndex = 33
                            }),
                            
                            -- Rarity Badge
                            RarityBadge = e("Frame", {
                                Name = "RarityBadge",
                                Size = UDim2.new(0, 60, 0, 15),
                                Position = UDim2.new(0.5, -30, 0, 145),
                                BackgroundColor3 = colors[1],
                                BorderSizePixel = 0,
                                ZIndex = 33
                            }, {
                                Corner = e("UICorner", {
                                    CornerRadius = UDim.new(0, 8)
                                }),
                                RarityText = e("TextLabel", {
                                    Size = UDim2.new(1, 0, 1, 0),
                                    Text = rarity:upper(),
                                    TextColor3 = Color3.fromRGB(255, 255, 255),
                                    TextSize = smallTextSize,
            TextWrapped = true,
                                    BackgroundTransparency = 1,
                                    Font = Enum.Font.SourceSansBold,
                                    ZIndex = 34
                                })
                            }),
                            
                            -- Sell One Button
                            SellOneButton = e("TextButton", {
                                Name = "SellOneButton",
                                Size = UDim2.new(1, -10, 0, 20),
                                Position = UDim2.new(0, 5, 0, 170),
                                Text = "",
                                BackgroundColor3 = Color3.fromRGB(40, 120, 40),
                                BorderSizePixel = 0,
                                ZIndex = 33,
                                AutoButtonColor = true,
                                [React.Event.Activated] = function()
                                    handleCropSale(itemData.type, itemData.sellPrice)
                                    createFlipAnimation(cropIconRef, cropAnimTracker)
                                    createFlipAnimation(sellIconRef, sellAnimTracker)
                                end
                            }, {
                                Corner = e("UICorner", {
                                    CornerRadius = UDim.new(0, 8)
                                }),
                                Stroke = e("UIStroke", {
                                    Color = Color3.fromRGB(100, 255, 100),
                                    Thickness = 1,
                                    Transparency = 0.5
                                }),
                                
                                ButtonGradient = e("UIGradient", {
                                    Color = ColorSequence.new{
                                        ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 140, 60)),
                                        ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 120, 40))
                                    },
                                    Rotation = 90
                                }),
                                
                                -- Button content container
                                ButtonContent = e("Frame", {
                                    Name = "ButtonContent",
                                    Size = UDim2.new(1, 0, 1, 0),
                                    BackgroundTransparency = 1,
                                    ZIndex = 34
                                }, {
                                    Layout = e("UIListLayout", {
                                        FillDirection = Enum.FillDirection.Horizontal,
                                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                        VerticalAlignment = Enum.VerticalAlignment.Center,
                                        Padding = UDim.new(0, 3),
                                        SortOrder = Enum.SortOrder.LayoutOrder
                                    }),
                                    
                                    SellText = e("TextLabel", {
                                        Name = "SellText",
                                        Size = UDim2.new(0, 0, 1, 0),
                                        AutomaticSize = Enum.AutomaticSize.X,
                                        Text = "SELL",
                                        TextColor3 = Color3.fromRGB(255, 255, 255),
                                        TextSize = buttonTextSize,
            TextWrapped = true,
                                        BackgroundTransparency = 1,
                                        Font = Enum.Font.SourceSansBold,
                                        ZIndex = 35,
                                        LayoutOrder = 1
                                    }, {
                                        TextStroke = e("UIStroke", {
                                            Color = Color3.fromRGB(0, 0, 0),
                                            Thickness = 2,
                                            Transparency = 0.5
                                        })
                                    }),
                                    
                                    SellIcon = e("ImageLabel", {
                                        Name = "SellIcon",
                                        Size = UDim2.new(0, 14, 0, 14),
                                        Image = assets["Currency/Cash/Cash Outline 256.png"] or "",
                                        BackgroundTransparency = 1,
                                        ScaleType = Enum.ScaleType.Fit,
                                        ImageColor3 = Color3.fromRGB(255, 215, 0),
                                        ZIndex = 35,
                                        LayoutOrder = 2,
                                        ref = sellIconRef
                                    }),
                                    
                                    SellAmount = e("TextLabel", {
                                        Name = "SellAmount",
                                        Size = UDim2.new(0, 0, 1, 0),
                                        AutomaticSize = Enum.AutomaticSize.X,
                                        Text = NumberFormatter.format(itemData.sellPrice),
                                        TextColor3 = Color3.fromRGB(255, 255, 255),
                                        TextSize = normalTextSize,
            TextWrapped = true,
                                        BackgroundTransparency = 1,
                                        Font = Enum.Font.SourceSansBold,
                                        ZIndex = 35,
                                        LayoutOrder = 3
                                    }, {
                                        TextStroke = e("UIStroke", {
                                            Color = Color3.fromRGB(0, 0, 0),
                                            Thickness = 2,
                                            Transparency = 0.5
                                        })
                                    })
                                })
                            }),
                            
                            -- Sell All Button
                            SellAllButton = e("TextButton", {
                                Name = "SellAllButton",
                                Size = UDim2.new(1, -10, 0, 20),
                                Position = UDim2.new(0, 5, 0, 195),
                                Text = "",
                                BackgroundColor3 = Color3.fromRGB(255, 165, 0),
                                BorderSizePixel = 0,
                                ZIndex = 33,
                                AutoButtonColor = true,
                                [React.Event.Activated] = function()
                                    handleCropSellAll(itemData.type, itemData.quantity)
                                    createFlipAnimation(cropIconRef, cropAnimTracker)
                                    createFlipAnimation(sellIconRef, sellAnimTracker)
                                end
                            }, {
                                Corner = e("UICorner", {
                                    CornerRadius = UDim.new(0, 8)
                                }),
                                Stroke = e("UIStroke", {
                                    Color = Color3.fromRGB(255, 200, 100),
                                    Thickness = 1,
                                    Transparency = 0.5
                                }),
                                
                                ButtonGradient = e("UIGradient", {
                                    Color = ColorSequence.new{
                                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 185, 50)),
                                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 145, 0))
                                    },
                                    Rotation = 90
                                }),
                                
                                -- Button content container
                                ButtonContent = e("Frame", {
                                    Name = "ButtonContent",
                                    Size = UDim2.new(1, 0, 1, 0),
                                    BackgroundTransparency = 1,
                                    ZIndex = 34
                                }, {
                                    Layout = e("UIListLayout", {
                                        FillDirection = Enum.FillDirection.Horizontal,
                                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                        VerticalAlignment = Enum.VerticalAlignment.Center,
                                        Padding = UDim.new(0, 2),
                                        SortOrder = Enum.SortOrder.LayoutOrder
                                    }),
                                    
                                    SellAllText = e("TextLabel", {
                                        Name = "SellAllText",
                                        Size = UDim2.new(0, 0, 1, 0),
                                        AutomaticSize = Enum.AutomaticSize.X,
                                        Text = "SELL ALL",
                                        TextColor3 = Color3.fromRGB(255, 255, 255),
                                        TextSize = buttonTextSize,
            TextWrapped = true,
                                        BackgroundTransparency = 1,
                                        Font = Enum.Font.SourceSansBold,
                                        ZIndex = 35,
                                        LayoutOrder = 1
                                    }, {
                                        TextStroke = e("UIStroke", {
                                            Color = Color3.fromRGB(0, 0, 0),
                                            Thickness = 2,
                                            Transparency = 0.5
                                        })
                                    }),
                                    
                                    SellAllIcon = e("ImageLabel", {
                                        Name = "SellAllIcon",
                                        Size = UDim2.new(0, 14, 0, 14),
                                        Image = assets["Currency/Cash/Cash Outline 256.png"] or "",
                                        BackgroundTransparency = 1,
                                        ScaleType = Enum.ScaleType.Fit,
                                        ImageColor3 = Color3.fromRGB(255, 215, 0),
                                        ZIndex = 35,
                                        LayoutOrder = 2
                                    }),
                                    
                                    SellAllAmount = e("TextLabel", {
                                        Name = "SellAllAmount",
                                        Size = UDim2.new(0, 0, 1, 0),
                                        AutomaticSize = Enum.AutomaticSize.X,
                                        Text = NumberFormatter.format(itemData.quantity * itemData.sellPrice),
                                        TextColor3 = Color3.fromRGB(255, 255, 255),
                                        TextSize = normalTextSize,
            TextWrapped = true,
                                        BackgroundTransparency = 1,
                                        Font = Enum.Font.SourceSansBold,
                                        ZIndex = 35,
                                        LayoutOrder = 3
                                    }, {
                                        TextStroke = e("UIStroke", {
                                            Color = Color3.fromRGB(0, 0, 0),
                                            Thickness = 2,
                                            Transparency = 0.5
                                        })
                                    })
                                })
                            })
                        })
                    end
                end
                
                return cards
            end)())
        })
    })
    })
end

return InventoryPanel