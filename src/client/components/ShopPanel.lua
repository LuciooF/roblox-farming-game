-- Modern Shop Panel Component  
-- Modern card-grid layout matching GamepassPanel design
-- Shows crops with beautiful cards, rarity indicators, and purchase options

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local e = React.createElement
local assets = require(game:GetService("ReplicatedStorage").Shared.assets)
local ClientLogger = require(script.Parent.Parent.ClientLogger)
local CropRegistry = require(game:GetService("ReplicatedStorage").Shared.CropRegistry)
local NumberFormatter = require(game:GetService("ReplicatedStorage").Shared.NumberFormatter)
local ScreenUtils = require(game:GetService("ReplicatedStorage").Shared.ScreenUtils)

local log = ClientLogger.getModuleLogger("ShopPanel")
local Modal = require(script.Parent.Modal)

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

local function ShopPanel(props)
    local playerData = props.playerData
    local visible = props.visible or false
    local onClose = props.onClose or function() end
    local remotes = props.remotes or {}
    
    -- Debug shop visibility
    React.useEffect(function()
        log.debug("ShopPanel visibility changed to:", visible)
    end, {visible})
    
    -- Responsive sizing
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
    
    -- Dynamic panel sizing based on screen dimensions - much wider for 4 columns
    local panelWidth = math.min(screenSize.X * 0.95, ScreenUtils.getProportionalSize(screenSize, 1400))
    local panelHeight = math.min(screenSize.Y * 0.85, ScreenUtils.getProportionalSize(screenSize, 750))
    
    -- Card sizing - target 4 columns, allow dynamic adjustment based on screen
    local targetColumns = 4
    local availableWidth = panelWidth - 100
    local cardSpacing = 15
    local cardWidth = math.floor((availableWidth / targetColumns) - cardSpacing)
    local minCardWidth = ScreenUtils.getProportionalSize(screenSize, 180) -- Smaller minimum
    local cardsPerRow = targetColumns
    
    -- Ensure cards aren't too small, adjust columns if needed
    if cardWidth < minCardWidth then
        cardsPerRow = math.max(3, math.floor(availableWidth / (minCardWidth + cardSpacing)))
        cardWidth = math.floor((availableWidth / cardsPerRow) - cardSpacing)
    end
    local cardHeight = ScreenUtils.getProportionalSize(screenSize, 280) -- Fixed proportional height
    
    -- Organize crops by rarity categories with unlock requirements (2-3 items per category)
    local categories = {
        {name = "Common", rarity = "common", unlockRebirths = 0},
        {name = "Basic", rarity = "basic", unlockRebirths = 1},
        {name = "Uncommon", rarity = "uncommon", unlockRebirths = 3},
        {name = "Quality", rarity = "quality", unlockRebirths = 5},
        {name = "Rare", rarity = "rare", unlockRebirths = 8},
        {name = "Premium", rarity = "premium", unlockRebirths = 12},
        {name = "Epic", rarity = "epic", unlockRebirths = 16},
        {name = "Elite", rarity = "elite", unlockRebirths = 20},
        {name = "Legendary", rarity = "legendary", unlockRebirths = 25},
        {name = "Mythic", rarity = "mythic", unlockRebirths = 35},
        {name = "Ancient", rarity = "ancient", unlockRebirths = 50},
        {name = "Divine", rarity = "divine", unlockRebirths = 75},
        {name = "Celestial", rarity = "celestial", unlockRebirths = 100},
        {name = "Cosmic", rarity = "cosmic", unlockRebirths = 150},
        {name = "Universal", rarity = "universal", unlockRebirths = 250}
    }
    
    -- Get current player rebirths
    local playerRebirths = playerData.rebirths or 0
    
    -- Get all shop crops organized by category
    local shopSeeds = {}
    for _, category in ipairs(categories) do
        local categoryUnlocked = playerRebirths >= category.unlockRebirths
        
        for cropId, crop in pairs(CropRegistry.crops) do
            if crop.rarity == category.rarity then
                table.insert(shopSeeds, {
                    type = cropId,
                    price = crop.seedCost,
                    crop = crop,
                    visual = crop,
                    category = category.name,
                    categoryUnlocked = categoryUnlocked,
                    requiredRebirths = category.unlockRebirths
                })
            end
        end
    end
    
    -- Sort by category unlock level, then by price
    table.sort(shopSeeds, function(a, b)
        if a.requiredRebirths == b.requiredRebirths then
            return a.price < b.price
        end
        return a.requiredRebirths < b.requiredRebirths
    end)
    
    -- Calculate grid dimensions
    local totalRows = math.ceil(#shopSeeds / cardsPerRow)
    -- Account for: card heights + spacing between rows + top/bottom padding
    -- Multiply by 1.3 for safety buffer without excessive empty space
    local totalHeight = ((totalRows * cardHeight) + ((totalRows - 1) * 20) + 40) * 1.3
    
    log.info("Shop Panel: Total items:", #shopSeeds, "Cards per row:", cardsPerRow, "Total rows:", totalRows, "Canvas height:", totalHeight, "Card width:", cardWidth)
    
    -- Handle crop purchase
    local function handleSeedPurchase(seedType, price)
        if remotes.buy then
            remotes.buy:FireServer("crops", seedType, price)
            playSound("click")
        end
    end
    
    -- Rarity colors for borders and effects
    local rarityColors = {
        common = {Color3.fromRGB(150, 150, 150), Color3.fromRGB(180, 180, 180)},
        basic = {Color3.fromRGB(139, 69, 19), Color3.fromRGB(160, 100, 50)},
        uncommon = {Color3.fromRGB(100, 255, 100), Color3.fromRGB(150, 255, 150)}, 
        quality = {Color3.fromRGB(0, 191, 255), Color3.fromRGB(50, 200, 255)},
        rare = {Color3.fromRGB(100, 100, 255), Color3.fromRGB(150, 150, 255)},
        premium = {Color3.fromRGB(255, 140, 0), Color3.fromRGB(255, 165, 50)},
        epic = {Color3.fromRGB(255, 100, 255), Color3.fromRGB(255, 150, 255)},
        elite = {Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 69, 69)},
        legendary = {Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 235, 50)},
        mythic = {Color3.fromRGB(255, 20, 147), Color3.fromRGB(255, 69, 147)},
        ancient = {Color3.fromRGB(139, 0, 139), Color3.fromRGB(186, 85, 211)},
        divine = {Color3.fromRGB(255, 255, 255), Color3.fromRGB(240, 240, 255)},
        celestial = {Color3.fromRGB(135, 206, 250), Color3.fromRGB(176, 224, 230)},
        cosmic = {Color3.fromRGB(75, 0, 130), Color3.fromRGB(138, 43, 226)},
        universal = {Color3.fromRGB(25, 25, 112), Color3.fromRGB(72, 61, 139)}
    }
    
    return e("Frame", {
        Name = "ShopContainer",
        Size = UDim2.new(0, panelWidth * scale, 0, panelHeight * scale + 50), -- Extra space for floating title
        Position = UDim2.new(0.5, -panelWidth * scale / 2, 0.5, -(panelHeight * scale + 50) / 2),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = visible,
        ZIndex = 30
    }, {
        
        ShopPanel = e("Frame", {
            Name = "ShopPanel",
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
                Size = UDim2.new(0, 160, 0, 40),
                Position = UDim2.new(0, -10, 0, -25), -- Much closer to main panel
                BackgroundColor3 = Color3.fromRGB(255, 100, 150),
                BorderSizePixel = 0,
                ZIndex = 32
            }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 12)
            }),
            Gradient = e("UIGradient", {
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 120, 170)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 80, 130))
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
                
                ShopIcon = e("ImageLabel", {
                    Name = "ShopIcon",
                    Size = UDim2.new(0, 24, 0, 24),
                    Image = assets["General/Shop/Shop Outline 256.png"],
                    BackgroundTransparency = 1,
                    ScaleType = Enum.ScaleType.Fit,
                    ImageColor3 = Color3.fromRGB(255, 255, 255),
                    ZIndex = 34,
                    LayoutOrder = 1
                }),
                
                TitleText = e("TextLabel", {
                    Size = UDim2.new(0, 0, 1, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    Text = "SHOP",
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
            Color = Color3.fromRGB(255, 100, 150),
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
            Text = "Buy seeds to grow amazing crops on your farm!",
            TextColor3 = Color3.fromRGB(60, 80, 140),
            TextSize = smallTextSize,
            TextWrapped = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 31
        }),
        
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
                
                -- Generate crop cards
                CropCards = React.createElement(React.Fragment, {}, (function()
                    local cards = {}
                    
                    for i, seedData in ipairs(shopSeeds) do
                        local canAfford = (playerData.money or 0) >= seedData.price and seedData.categoryUnlocked
                        local rarity = seedData.crop.rarity or "common"
                        local colors = rarityColors[rarity] or rarityColors.common
                        local isLocked = not seedData.categoryUnlocked
                        
                        -- Animation refs - simplified without React.useRef in loop
                        local cropIconRef = {current = nil}
                        local priceIconRef = {current = nil}
                        local cropAnimTracker = {current = nil}
                        local priceAnimTracker = {current = nil}
                        
                        cards[seedData.type] = e("TextButton", {
                            Name = seedData.type .. "Card",
                            Text = "",
                            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                            BackgroundTransparency = canAfford and 0.05 or 0.3,
                            BorderSizePixel = 0,
                            ZIndex = 32,
                            LayoutOrder = i,
                            AutoButtonColor = false,
                            [React.Event.MouseEnter] = function()
                                if canAfford then
                                    playSound("hover")
                                    createFlipAnimation(cropIconRef, cropAnimTracker)
                                end
                            end,
                            [React.Event.Activated] = function()
                                if canAfford then
                                    handleSeedPurchase(seedData.type, seedData.price)
                                    createFlipAnimation(cropIconRef, cropAnimTracker)
                                    createFlipAnimation(priceIconRef, priceAnimTracker)
                                end
                            end
                        }, {
                            Corner = e("UICorner", {
                                CornerRadius = UDim.new(0, 15)
                            }),
                            
                            -- Card Gradient Background
                            CardGradient = e("UIGradient", {
                                Color = ColorSequence.new{
                                    ColorSequenceKeypoint.new(0, canAfford and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(240, 240, 240)),
                                    ColorSequenceKeypoint.new(1, canAfford and Color3.fromRGB(248, 252, 255) or Color3.fromRGB(230, 230, 230))
                                },
                                Rotation = 45
                            }),
                            
                            Stroke = e("UIStroke", {
                                Color = canAfford and colors[1] or Color3.fromRGB(150, 150, 150),
                                Thickness = canAfford and 3 or 2,
                                Transparency = canAfford and 0.1 or 0.3
                            }),
                            
                            -- Black outline for card
                            BlackOutline = e("UIStroke", {
                                Color = Color3.fromRGB(0, 0, 0),
                                Thickness = 1,
                                Transparency = 0.7,
                                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                            }),
                            
                            -- Crop Icon (question mark if locked)
                            CropIcon = (function()
                                if isLocked then
                                    return e("ImageLabel", {
                                        Name = "QuestionIcon",
                                        Size = UDim2.new(0, 60, 0, 60),
                                        Position = UDim2.new(0.5, -30, 0, 15),
                                        Image = assets["ui/Question Mark/Question Mark Outline 256.png"] or "",
                                        ImageColor3 = Color3.fromRGB(100, 100, 100),
                                        BackgroundTransparency = 1,
                                        ScaleType = Enum.ScaleType.Fit,
                                        ZIndex = 33,
                                        ref = cropIconRef
                                    })
                                elseif seedData.visual and seedData.visual.assetId then
                                    return e("ImageLabel", {
                                        Name = "CropIcon",
                                        Size = UDim2.new(0, 60, 0, 60),
                                        Position = UDim2.new(0.5, -30, 0, 15),
                                        Image = seedData.visual.assetId:gsub("-64%.png", "-outline-256.png"):gsub("-256%.png", "-outline-256.png"),
                                        BackgroundTransparency = 1,
                                        ScaleType = Enum.ScaleType.Fit,
                                        ZIndex = 33,
                                        ref = cropIconRef
                                    })
                                else
                                    return e("TextLabel", {
                                        Name = "CropEmoji",
                                        Size = UDim2.new(1, 0, 0, 50),
                                        Position = UDim2.new(0, 0, 0, 15),
                                        Text = tostring(seedData.visual and seedData.visual.emoji or "🌱"),
                                        TextSize = normalTextSize,
                                        TextWrapped = true,
                                        BackgroundTransparency = 1,
                                        Font = Enum.Font.SourceSansBold,
                                        ZIndex = 33,
                                        ref = cropIconRef
                                    })
                                end
                            end)(),
                            
                            -- Crop Name (mysterious if locked)
                            CropName = e("TextLabel", {
                                Name = "CropName",
                                Size = UDim2.new(1, -10, 0, 20),
                                Position = UDim2.new(0, 5, 0, 80),
                                Text = isLocked and "??? ??? ???" or tostring(seedData.crop.name or seedData.type or "Unknown"),
                                TextColor3 = canAfford and Color3.fromRGB(40, 40, 40) or Color3.fromRGB(120, 120, 120),
                                TextSize = cardTitleSize,
            TextWrapped = true,
                                BackgroundTransparency = 1,
                                Font = Enum.Font.SourceSansBold,
                                ZIndex = 33
                            }),
                            
                            -- Crop Description (mysterious if locked)
                            CropDescription = e("TextLabel", {
                                Name = "CropDescription",
                                Size = UDim2.new(1, -10, 0, 25),
                                Position = UDim2.new(0, 5, 0, 100),
                                Text = isLocked and "???" or (seedData.crop.description or "A wonderful crop to grow!"),
                                TextColor3 = canAfford and Color3.fromRGB(70, 80, 120) or Color3.fromRGB(100, 100, 100),
                                TextSize = smallTextSize,
                                BackgroundTransparency = 1,
                                Font = Enum.Font.Gotham,
                                TextXAlignment = Enum.TextXAlignment.Center,
                                TextYAlignment = Enum.TextYAlignment.Top,
                                TextWrapped = true,
                                ZIndex = 33
                            }),
                            
                            -- Water and Production Stats Table
                            StatsTable = not isLocked and e("Frame", {
                                Name = "StatsTable",
                                Size = UDim2.new(1, -10, 0, 30),
                                Position = UDim2.new(0, 5, 0, 125),
                                BackgroundTransparency = 1,
                                ZIndex = 33
                            }, {
                                Layout = e("UIListLayout", {
                                    FillDirection = Enum.FillDirection.Vertical,
                                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                    VerticalAlignment = Enum.VerticalAlignment.Top,
                                    Padding = UDim.new(0, 2),
                                    SortOrder = Enum.SortOrder.LayoutOrder
                                }),
                                
                                -- Headers row
                                HeadersRow = e("Frame", {
                                    Name = "HeadersRow",
                                    Size = UDim2.new(1, 0, 0, 12),
                                    BackgroundTransparency = 1,
                                    LayoutOrder = 1,
                                    ZIndex = 34
                                }, {
                                    WaterHeader = e("TextLabel", {
                                        Size = UDim2.new(0.5, -10, 1, 0),
                                        Position = UDim2.new(0, 0, 0, 0),
                                        Text = "Water Needed",
                                        TextColor3 = canAfford and Color3.fromRGB(0, 100, 200) or Color3.fromRGB(120, 120, 120),
                                        TextSize = normalTextSize,
            TextWrapped = true,
                                        BackgroundTransparency = 1,
                                        Font = Enum.Font.GothamBold,
                                        TextXAlignment = Enum.TextXAlignment.Center,
                                        ZIndex = 35
                                    }),
                                    
                                    ProductionHeader = e("TextLabel", {
                                        Size = UDim2.new(0.5, -10, 1, 0),
                                        Position = UDim2.new(0.5, 10, 0, 0),
                                        Text = "Production",
                                        TextColor3 = canAfford and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(120, 120, 120),
                                        TextSize = normalTextSize,
            TextWrapped = true,
                                        BackgroundTransparency = 1,
                                        Font = Enum.Font.GothamBold,
                                        TextXAlignment = Enum.TextXAlignment.Center,
                                        ZIndex = 35
                                    })
                                }),
                                
                                -- Values row
                                ValuesRow = e("Frame", {
                                    Name = "ValuesRow",
                                    Size = UDim2.new(1, 0, 0, 14),
                                    BackgroundTransparency = 1,
                                    LayoutOrder = 2,
                                    ZIndex = 34
                                }, {
                                    WaterValue = e("TextLabel", {
                                        Size = UDim2.new(0.5, -10, 1, 0),
                                        Position = UDim2.new(0, 0, 0, 0),
                                        Text = tostring(seedData.crop.waterNeeded),
                                        TextColor3 = canAfford and Color3.fromRGB(0, 100, 200) or Color3.fromRGB(120, 120, 120),
                                        TextSize = normalTextSize,
            TextWrapped = true,
                                        BackgroundTransparency = 1,
                                        Font = Enum.Font.GothamBold,
                                        TextXAlignment = Enum.TextXAlignment.Center,
                                        ZIndex = 35
                                    }),
                                    
                                    ProductionValue = e("TextLabel", {
                                        Size = UDim2.new(0.5, -10, 1, 0),
                                        Position = UDim2.new(0.5, 10, 0, 0),
                                        Text = tostring(seedData.crop.productionRate or 0) .. "/h",
                                        TextColor3 = canAfford and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(120, 120, 120),
                                        TextSize = normalTextSize,
            TextWrapped = true,
                                        BackgroundTransparency = 1,
                                        Font = Enum.Font.GothamBold,
                                        TextXAlignment = Enum.TextXAlignment.Center,
                                        ZIndex = 35
                                    })
                                })
                            }) or nil,
                            
                            -- Rarity Badge
                            RarityBadge = e("Frame", {
                                Name = "RarityBadge",
                                Size = UDim2.new(0, 60, 0, 15),
                                Position = UDim2.new(0.5, -30, 0, 160),
                                BackgroundColor3 = colors[1],
                                BorderSizePixel = 0,
                                ZIndex = 33
                            }, {
                                Corner = e("UICorner", {
                                    CornerRadius = UDim.new(0, 8)
                                }),
                                RarityText = e("TextLabel", {
                                    Size = UDim2.new(1, 0, 1, 0),
                                    Text = tostring(rarity or "common"):upper(),
                                    TextColor3 = Color3.fromRGB(255, 255, 255),
                                    TextSize = smallTextSize,
            TextWrapped = true,
                                    BackgroundTransparency = 1,
                                    Font = Enum.Font.SourceSansBold,
                                    ZIndex = 34
                                })
                            }),
                            
                            -- Buy Button
                            BuyButton = e("TextButton", {
                                Name = "BuyButton",
                                Size = UDim2.new(1, -10, 0, 30),
                                Position = UDim2.new(0, 5, 0, 185),
                                Text = "",
                                BackgroundColor3 = canAfford and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(150, 150, 150),
                                BorderSizePixel = 0,
                                ZIndex = 33,
                                Active = canAfford,
                                AutoButtonColor = canAfford,
                                [React.Event.Activated] = canAfford and function()
                                    handleSeedPurchase(seedData.type, seedData.price)
                                    createFlipAnimation(cropIconRef, cropAnimTracker)
                                    createFlipAnimation(priceIconRef, priceAnimTracker)
                                end or nil
                            }, {
                                Corner = e("UICorner", {
                                    CornerRadius = UDim.new(0, 10)
                                }),
                                Stroke = e("UIStroke", {
                                    Color = canAfford and Color3.fromRGB(80, 160, 80) or Color3.fromRGB(120, 120, 120),
                                    Thickness = 2,
                                    Transparency = 0.2
                                }),
                                
                                -- Black outline for button
                                BlackOutline = e("UIStroke", {
                                    Color = Color3.fromRGB(0, 0, 0),
                                    Thickness = 1,
                                    Transparency = 0.6,
                                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                                }),
                                ButtonGradient = e("UIGradient", {
                                    Color = ColorSequence.new{
                                        ColorSequenceKeypoint.new(0, canAfford and Color3.fromRGB(120, 220, 120) or Color3.fromRGB(170, 170, 170)),
                                        ColorSequenceKeypoint.new(1, canAfford and Color3.fromRGB(80, 180, 80) or Color3.fromRGB(130, 130, 130))
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
                                        Padding = UDim.new(0, 5),
                                        SortOrder = Enum.SortOrder.LayoutOrder
                                    }),
                                    
                                    CashIcon = e("ImageLabel", {
                                        Name = "CashIcon",
                                        Size = UDim2.new(0, 20, 0, 20),
                                        Image = assets["Currency/Cash/Cash Outline 256.png"] or "",
                                        BackgroundTransparency = 1,
                                        ScaleType = Enum.ScaleType.Fit,
                                        ZIndex = 35,
                                        LayoutOrder = 1,
                                        ref = priceIconRef
                                    }),
                                    
                                    PriceText = e("TextLabel", {
                                        Name = "PriceText",
                                        Size = UDim2.new(0, 0, 1, 0),
                                        AutomaticSize = Enum.AutomaticSize.X,
                                        Text = isLocked and "???" or tostring(NumberFormatter.format(seedData.price) or seedData.price or 0),
                                        TextColor3 = canAfford and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200),
                                        TextSize = cardValueSize,
            TextWrapped = true,
                                        BackgroundTransparency = 1,
                                        Font = Enum.Font.SourceSansBold,
                                        ZIndex = 35,
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
                            
                            -- Lock Overlay for category-locked items
                            CategoryLockOverlay = isLocked and e("Frame", {
                                Name = "CategoryLockOverlay",
                                Size = UDim2.new(1, 0, 1, 0),
                                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                                BackgroundTransparency = 0.7,
                                BorderSizePixel = 0,
                                ZIndex = 35
                            }, {
                                Corner = e("UICorner", {
                                    CornerRadius = UDim.new(0, 15)
                                }),
                                LockIcon = e("TextLabel", {
                                    Size = UDim2.new(1, 0, 0, 25),
                                    Position = UDim2.new(0, 0, 0.4, -12),
                                    Text = "🔒",
                                    TextColor3 = Color3.fromRGB(255, 255, 255),
                                    TextSize = normalTextSize,
            TextWrapped = true,
                                    BackgroundTransparency = 1,
                                    Font = Enum.Font.SourceSansBold,
                                    ZIndex = 36
                                }),
                                RequirementText = e("TextLabel", {
                                    Size = UDim2.new(1, -5, 0, 20),
                                    Position = UDim2.new(0, 2.5, 0.6, -10),
                                    Text = tostring(seedData.requiredRebirths or 0) .. " rebirths",
                                    TextColor3 = Color3.fromRGB(255, 200, 100),
                                    TextSize = normalTextSize,
            TextWrapped = true,
                                    BackgroundTransparency = 1,
                                    Font = Enum.Font.SourceSansBold,
                                    ZIndex = 36
                                }, {
                                    TextStroke = e("UIStroke", {
                                        Color = Color3.fromRGB(0, 0, 0),
                                        Thickness = 2,
                                        Transparency = 0.3
                                    })
                                })
                            }) or nil,
                            
                            -- Money Overlay for unaffordable items (only if category is unlocked)
                            UnaffordableOverlay = (not canAfford and seedData.categoryUnlocked) and e("Frame", {
                                Name = "UnaffordableOverlay",
                                Size = UDim2.new(1, 0, 1, 0),
                                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                                BackgroundTransparency = 0.6,
                                BorderSizePixel = 0,
                                ZIndex = 35
                            }, {
                                Corner = e("UICorner", {
                                    CornerRadius = UDim.new(0, 15)
                                }),
                                LockIcon = e("TextLabel", {
                                    Size = UDim2.new(1, 0, 0, 30),
                                    Position = UDim2.new(0, 0, 0.5, -15),
                                    Text = "💰",
                                    TextColor3 = Color3.fromRGB(255, 255, 255),
                                    TextSize = normalTextSize,
            TextWrapped = true,
                                    BackgroundTransparency = 1,
                                    Font = Enum.Font.SourceSansBold,
                                    ZIndex = 36
                                })
                            }) or nil
                        })
                    end
                    
                    return cards
                end)())
            })
        })
    })
end

return ShopPanel