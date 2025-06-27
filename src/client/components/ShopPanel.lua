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
    local isMobile = screenSize.X < 768
    local scale = isMobile and 0.85 or 1
    local panelWidth = isMobile and 700 or 900
    local panelHeight = isMobile and 500 or 650
    
    -- Card sizing
    local cardWidth = isMobile and 140 or 160
    local cardHeight = isMobile and 180 or 200
    local cardsPerRow = math.floor((panelWidth - 80) / (cardWidth + 20))
    
    -- Get shop crops from CropRegistry based on player's unlock level
    local playerRebirths = playerData and playerData.rebirths or 0
    local playerLevel = playerRebirths + 1 -- Simple level calculation
    
    local shopSeeds = {}
    for cropId, crop in pairs(CropRegistry.getAllCrops()) do
        if crop.unlockLevel <= playerLevel then
            table.insert(shopSeeds, {
                type = cropId,
                price = crop.seedCost,
                crop = crop,
                visual = CropRegistry.getVisuals(cropId)
            })
        end
    end
    
    -- Sort by unlock level, then by price
    table.sort(shopSeeds, function(a, b)
        if a.crop.unlockLevel == b.crop.unlockLevel then
            return a.price < b.price
        end
        return a.crop.unlockLevel < b.crop.unlockLevel
    end)
    
    -- Calculate grid dimensions
    local totalRows = math.ceil(#shopSeeds / cardsPerRow)
    local totalHeight = (totalRows * (cardHeight + 20)) + 40
    
    -- Handle crop purchase
    local function handleSeedPurchase(seedType, price)
        if remotes.buySeed then
            remotes.buySeed:FireServer(seedType, price)
            playSound("click")
        end
    end
    
    -- Rarity colors for borders and effects
    local rarityColors = {
        common = {Color3.fromRGB(150, 150, 150), Color3.fromRGB(180, 180, 180)},
        uncommon = {Color3.fromRGB(100, 255, 100), Color3.fromRGB(150, 255, 150)}, 
        rare = {Color3.fromRGB(100, 100, 255), Color3.fromRGB(150, 150, 255)},
        epic = {Color3.fromRGB(255, 100, 255), Color3.fromRGB(255, 150, 255)},
        legendary = {Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 235, 50)}
    }
    
    return e(Modal, {
        visible = visible,
        onClose = onClose,
        title = "🌱 Seed Shop",
        size = UDim2.new(0, panelWidth * scale, 0, panelHeight * scale)
    }, {
        -- Main Content Area
        ContentFrame = e("Frame", {
            Name = "ContentFrame",
            Size = UDim2.new(1, 0, 1, -60),
            Position = UDim2.new(0, 0, 0, 60),
            BackgroundTransparency = 1,
            ZIndex = 31
        }, {
            -- Seeds Container with Grid
            SeedsContainer = e("ScrollingFrame", {
                Name = "SeedsContainer",
                Size = UDim2.new(1, -40, 1, 0),
                Position = UDim2.new(0, 20, 0, 0),
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
                        local canAfford = (playerData.money or 0) >= seedData.price
                        local rarity = seedData.crop.rarity or "common"
                        local colors = rarityColors[rarity] or rarityColors.common
                        
                        -- Create refs for animation
                        local cropIconRef = React.useRef(nil)
                        local priceIconRef = React.useRef(nil)
                        local cropAnimTracker = React.useRef(nil)
                        local priceAnimTracker = React.useRef(nil)
                        
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
                                Thickness = canAfford and 3 or 1,
                                Transparency = canAfford and 0.1 or 0.5
                            }),
                            
                            -- Crop Icon
                            CropIcon = seedData.visual and seedData.visual.assetId and e("ImageLabel", {
                                Name = "CropIcon",
                                Size = UDim2.new(0, 60, 0, 60),
                                Position = UDim2.new(0.5, -30, 0, 15),
                                Image = seedData.visual.assetId,
                                BackgroundTransparency = 1,
                                ScaleType = Enum.ScaleType.Fit,
                                ZIndex = 33,
                                [React.Ref] = cropIconRef
                            }) or e("TextLabel", {
                                Name = "CropEmoji",
                                Size = UDim2.new(1, 0, 0, 50),
                                Position = UDim2.new(0, 0, 0, 15),
                                Text = seedData.visual and seedData.visual.emoji or "🌱",
                                TextScaled = true,
                                BackgroundTransparency = 1,
                                Font = Enum.Font.SourceSansBold,
                                ZIndex = 33,
                                [React.Ref] = cropIconRef
                            }),
                            
                            -- Crop Name
                            CropName = e("TextLabel", {
                                Name = "CropName",
                                Size = UDim2.new(1, -10, 0, 25),
                                Position = UDim2.new(0, 5, 0, 80),
                                Text = seedData.crop.name,
                                TextColor3 = canAfford and Color3.fromRGB(40, 40, 40) or Color3.fromRGB(120, 120, 120),
                                TextScaled = true,
                                BackgroundTransparency = 1,
                                Font = Enum.Font.SourceSansBold,
                                ZIndex = 33
                            }),
                            
                            -- Rarity Badge
                            RarityBadge = e("Frame", {
                                Name = "RarityBadge",
                                Size = UDim2.new(0, 60, 0, 15),
                                Position = UDim2.new(0.5, -30, 0, 105),
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
                                    TextScaled = true,
                                    BackgroundTransparency = 1,
                                    Font = Enum.Font.SourceSansBold,
                                    ZIndex = 34
                                })
                            }),
                            
                            -- Price
                            PriceFrame = e("Frame", {
                                Name = "PriceFrame",
                                Size = UDim2.new(1, -10, 0, 25),
                                Position = UDim2.new(0, 5, 0, 125),
                                BackgroundColor3 = canAfford and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 150, 150),
                                BackgroundTransparency = 0.3,
                                BorderSizePixel = 0,
                                ZIndex = 33
                            }, {
                                Corner = e("UICorner", {
                                    CornerRadius = UDim.new(0, 8)
                                }),
                                PriceIcon = e("ImageLabel", {
                                    Name = "PriceIcon",
                                    Size = UDim2.new(0, 16, 0, 16),
                                    Position = UDim2.new(0, 5, 0.5, -8),
                                    Image = assets["General/Coin/Coin 64.png"] or "",
                                    BackgroundTransparency = 1,
                                    ScaleType = Enum.ScaleType.Fit,
                                    ZIndex = 34,
                                    [React.Ref] = priceIconRef
                                }),
                                PriceText = e("TextLabel", {
                                    Size = UDim2.new(1, -25, 1, 0),
                                    Position = UDim2.new(0, 22, 0, 0),
                                    Text = NumberFormatter.format(seedData.price),
                                    TextColor3 = canAfford and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(180, 0, 0),
                                    TextScaled = true,
                                    BackgroundTransparency = 1,
                                    Font = Enum.Font.SourceSansBold,
                                    TextXAlignment = Enum.TextXAlignment.Left,
                                    ZIndex = 34
                                })
                            }),
                            
                            -- Purchase Overlay for unaffordable items
                            UnaffordableOverlay = not canAfford and e("Frame", {
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
                                    Text = "🔒",
                                    TextColor3 = Color3.fromRGB(255, 255, 255),
                                    TextScaled = true,
                                    BackgroundTransparency = 1,
                                    Font = Enum.Font.SourceSansBold,
                                    ZIndex = 36
                                })
                            })
                        })
                    end
                    
                    return cards
                end)())
            })
        })
    })
end

return ShopPanel