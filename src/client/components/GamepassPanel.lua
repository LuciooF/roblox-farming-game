-- Gamepass Panel Component
-- Modern card-grid layout inspired by the provided design
-- Shows all available gamepasses with purchase options and owned status

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local e = React.createElement
local assets = require(game:GetService("ReplicatedStorage").Shared.assets)
local ScreenUtils = require(game:GetService("ReplicatedStorage").Shared.ScreenUtils)

local Modal = require(script.Parent.Modal)

-- Sound IDs for button interactions (same as SideButtons)
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
        pcall(function()
            animationTracker.current:Cancel()
        end)
        pcall(function()
            animationTracker.current:Destroy()
        end)
        animationTracker.current = nil
    end
    
    -- Reset rotation to 0 to prevent accumulation
    iconRef.current.Rotation = 0
    
    -- Create flip animation (360 degree rotation for full flip)
    local flipTween = TweenService:Create(iconRef.current,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Rotation = 360}
    )
    
    -- Store reference to current animation
    animationTracker.current = flipTween
    
    flipTween:Play()
    flipTween.Completed:Connect(function()
        -- Reset rotation after animation
        if iconRef.current then
            iconRef.current.Rotation = 0
        end
        -- Clear the tracker
        if animationTracker.current == flipTween then
            animationTracker.current = nil
        end
        flipTween:Destroy()
    end)
end

local function GamepassPanel(props)
    local visible = props.visible or false
    local onClose = props.onClose or function() end
    local onPurchase = props.onPurchase or function() end
    local playerData = props.playerData
    local gamepassData = props.gamepassData or {}
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    
    -- Responsive sizing
    local scale = ScreenUtils.getProportionalScale(screenSize)
    local panelWidth = math.min(screenSize.X * 0.9, ScreenUtils.getProportionalSize(screenSize, 1000))
    local panelHeight = math.min(screenSize.Y * 0.85, ScreenUtils.getProportionalSize(screenSize, 700))
    
    -- Proportional text sizes
    local titleTextSize = ScreenUtils.getProportionalTextSize(screenSize, 32)
    local normalTextSize = ScreenUtils.getProportionalTextSize(screenSize, 18)
    local smallTextSize = ScreenUtils.getProportionalTextSize(screenSize, 14)
    local buttonTextSize = ScreenUtils.getProportionalTextSize(screenSize, 16)
    local cardTitleSize = ScreenUtils.getProportionalTextSize(screenSize, 20)
    local cardValueSize = ScreenUtils.getProportionalTextSize(screenSize, 16)
    
    -- Card grid settings - dynamically adjust columns based on available width
    local minCardWidth = ScreenUtils.getProportionalSize(screenSize, 220)
    local cardsPerRow = math.max(2, math.floor((panelWidth - 100) / (minCardWidth + 15)))
    local availableWidth = panelWidth - 100
    local cardWidth = math.floor((availableWidth / cardsPerRow) - 15)
    local cardHeight = ScreenUtils.getProportionalSize(screenSize, 200) -- Fixed proportional height
    
    -- Enhanced gamepass data - real gamepasses first, then placeholders
    local gamepasses = {
        {
            id = 1277613878,
            key = "moneyMultiplier",
            name = "💰 2x Money Boost",
            description = "Double the money you earn from all crop sales! Stack with other multipliers for massive profits.",
            icon = gamepassData.moneyMultiplier and gamepassData.moneyMultiplier.iconUrl or "rbxassetid://6031068426",
            price = gamepassData.moneyMultiplier and gamepassData.moneyMultiplier.robux or "R$ 99",
            gradientColors = {Color3.fromRGB(255, 200, 50), Color3.fromRGB(255, 150, 0)},
            category = "💰 Economy"
        },
        {
            id = 1276253029,
            key = "flyMode",
            name = "🚁 Fly Mode",
            description = "Soar above your farm with unlimited flight! Fast navigation and perfect farm overview.",
            icon = gamepassData.flyMode and gamepassData.flyMode.iconUrl or "rbxassetid://6031068426",
            price = gamepassData.flyMode and gamepassData.flyMode.robux or "R$ 149",
            gradientColors = {Color3.fromRGB(100, 255, 255), Color3.fromRGB(50, 200, 255)},
            category = "🚁 Movement"
        },
        {
            id = 123456790,
            key = "autoHarvest",
            name = "🤖 Auto Harvest",
            description = "Automatically harvest ready crops on all your plots. Never miss a harvest again!",
            icon = "rbxassetid://6031068426",
            price = "R$ 149",
            gradientColors = {Color3.fromRGB(50, 200, 255), Color3.fromRGB(0, 150, 255)},
            category = "🤖 Automation"
        },
        {
            id = 123456791,
            key = "instantGrowth",
            name = "⚡ Instant Growth",
            description = "Skip all growing time and harvest crops immediately. Perfect for quick farming sessions.",
            icon = "rbxassetid://6031068426",
            price = "R$ 199",
            gradientColors = {Color3.fromRGB(255, 100, 200), Color3.fromRGB(255, 50, 150)},
            category = "⚡ Speed"
        },
        {
            id = 123456792,
            key = "plotMultiplier",
            name = "🏡 Extra Plots",
            description = "Unlock 10 additional plots to expand your farming empire and increase profits.",
            icon = "rbxassetid://6031068426",
            price = "R$ 249",
            gradientColors = {Color3.fromRGB(100, 255, 150), Color3.fromRGB(50, 255, 100)},
            category = "🏡 Expansion"
        },
        {
            id = 123456793,
            key = "vipAccess",
            name = "👑 VIP Access",
            description = "Exclusive VIP areas, special seeds, priority support, and unique cosmetic items.",
            icon = "rbxassetid://6031068426",
            price = "R$ 399",
            gradientColors = {Color3.fromRGB(200, 100, 255), Color3.fromRGB(150, 50, 255)},
            category = "👑 Premium"
        },
        {
            id = 123456794,
            key = "weatherControl",
            name = "🌦️ Weather Control",
            description = "Control the weather on your farm! Create perfect growing conditions anytime.",
            icon = "rbxassetid://6031068426",
            price = "R$ 179",
            gradientColors = {Color3.fromRGB(150, 220, 255), Color3.fromRGB(100, 180, 255)},
            category = "🌦️ Environment"
        },
        -- 6 NEW GAMEPASSES
        {
            id = 123456795,
            key = "megaSeeds",
            name = "🌟 Mega Seeds",
            description = "Unlock exclusive mega seeds that give 5x more crops and grow in rainbow colors!",
            icon = "rbxassetid://6031068426",
            price = "R$ 299",
            gradientColors = {Color3.fromRGB(255, 255, 100), Color3.fromRGB(255, 200, 50)},
            category = "🌟 Special"
        },
        {
            id = 123456796,
            key = "timeWarp",
            name = "⏰ Time Warp",
            description = "Speed up time on your entire farm by 3x! Everything grows faster permanently.",
            icon = "rbxassetid://6031068426",
            price = "R$ 349",
            gradientColors = {Color3.fromRGB(255, 150, 255), Color3.fromRGB(200, 100, 255)},
            category = "⏰ Time"
        },
        {
            id = 123456797,
            key = "goldTouch",
            name = "✨ Golden Touch",
            description = "Everything you touch turns to gold! 10x money from all activities and golden effects.",
            icon = "rbxassetid://6031068426",
            price = "R$ 499",
            gradientColors = {Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 165, 0)},
            category = "✨ Legendary"
        },
        {
            id = 123456798,
            key = "petCompanion",
            name = "🐱 Pet Companion",
            description = "Get an adorable pet that follows you around and helps with farming tasks!",
            icon = "rbxassetid://6031068426",
            price = "R$ 199",
            gradientColors = {Color3.fromRGB(255, 150, 200), Color3.fromRGB(255, 100, 150)},
            category = "🐱 Pets"
        },
        {
            id = 123456800,
            key = "masterFarmer",
            name = "🎓 Master Farmer",
            description = "Unlock all farming techniques, exclusive areas, and become the ultimate farmer!",
            icon = "rbxassetid://6031068426",
            price = "R$ 799",
            gradientColors = {Color3.fromRGB(255, 100, 100), Color3.fromRGB(255, 50, 50)},
            category = "🎓 Ultimate"
        }
    }
    
    -- Check if player owns a gamepass
    local function playerOwnsGamepass(gamepassKey)
        return playerData and playerData.gamepasses and playerData.gamepasses[gamepassKey] == true
    end
    
    -- Sort gamepasses: unowned first, owned last
    table.sort(gamepasses, function(a, b)
        local aOwned = playerOwnsGamepass(a.key)
        local bOwned = playerOwnsGamepass(b.key)
        
        -- If ownership status is different, unowned comes first
        if aOwned ~= bOwned then
            return not aOwned -- false (unowned) comes before true (owned)
        end
        
        -- If both have same ownership status, maintain original order
        return false -- Keep stable sort
    end)
    
    -- Calculate grid dimensions
    local totalRows = math.ceil(#gamepasses / cardsPerRow)
    -- Account for: card heights + spacing between rows + top/bottom padding
    -- Multiply by 1.3 for safety buffer without excessive empty space
    local totalHeight = ((totalRows * cardHeight) + ((totalRows - 1) * 20) + 40) * 1.3
    
    -- Handle gamepass purchase
    local function handlePurchase(gamepassKey)
        if playerOwnsGamepass(gamepassKey) then
            return
        end
        
        if onPurchase then
            onPurchase(gamepassKey)
        end
    end
    
    return e(Modal, {
        visible = visible,
        onClose = onClose,
        zIndex = 30
    }, {
        GamepassContainer = e("Frame", {
            Name = "GamepassContainer",
            Size = UDim2.new(0, panelWidth * scale, 0, panelHeight * scale + 50), -- Extra space for floating title
            Position = UDim2.new(0.5, -panelWidth * scale / 2, 0.5, -(panelHeight * scale + 50) / 2),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 30
        }, {
            
            GamepassPanel = e("Frame", {
                Name = "GamepassPanel",
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
                    BackgroundColor3 = Color3.fromRGB(255, 140, 0),
                    BorderSizePixel = 0,
                    ZIndex = 32
                }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 12)
                }),
                Gradient = e("UIGradient", {
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 160, 50)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 120, 0))
                    },
                    Rotation = 45
                }),
                Stroke = e("UIStroke", {
                    Color = Color3.fromRGB(255, 255, 255),
                    Thickness = 3,
                    Transparency = 0.2
                }),
                TitleText = e("TextLabel", {
                    Size = UDim2.new(1, -10, 1, 0),
                    Position = UDim2.new(0, 5, 0, 0),
                    Text = "🚀 GAMEPASSES",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = titleTextSize,
            TextWrapped = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    ZIndex = 33
                }, {
                    TextStroke = e("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = 2,
                        Transparency = 0.5
                    })
                })
            }),
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 20)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(255, 140, 0),
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
                Text = "Unlock powerful features and boost your farming experience!",
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
                ScrollBarImageColor3 = Color3.fromRGB(100, 150, 255),
                ZIndex = 31
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 15)
                }),
                ContainerGradient = e("UIGradient", {
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(245, 250, 255))
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
                
                -- Generate gamepass cards
                GamepassCards = React.createElement(React.Fragment, {}, (function()
                    local cards = {}
                    
                    for i, gamepass in ipairs(gamepasses) do
                        local isOwned = playerOwnsGamepass(gamepass.key)
                        
                        -- Create refs for each gamepass card's icons
                        local gamepassIconRef = React.useRef(nil)
                        local robuxIconRef = React.useRef(nil)
                        local gamepassAnimTracker = React.useRef(nil)
                        local robuxAnimTracker = React.useRef(nil)
                        
                        cards[gamepass.key] = e("TextButton", {
                            Name = gamepass.key .. "Card",
                            Text = "",
                            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                            BackgroundTransparency = 0.05,
                            BorderSizePixel = 0,
                            ZIndex = 32,
                            LayoutOrder = i,
                            AutoButtonColor = false,
                            [React.Event.MouseEnter] = function()
                                if not isOwned then
                                    playSound("hover")
                                    createFlipAnimation(gamepassIconRef, gamepassAnimTracker)
                                    createFlipAnimation(robuxIconRef, robuxAnimTracker)
                                end
                            end,
                            [React.Event.Activated] = function()
                                if not isOwned then
                                    playSound("click")
                                    createFlipAnimation(gamepassIconRef, gamepassAnimTracker)
                                    createFlipAnimation(robuxIconRef, robuxAnimTracker)
                                    handlePurchase(gamepass.key)
                                end
                            end
                        }, {
                            Corner = e("UICorner", {
                                CornerRadius = UDim.new(0, 15)
                            }),
                            
                            -- Card Gradient Background
                            CardGradient = e("UIGradient", {
                                Color = ColorSequence.new{
                                    ColorSequenceKeypoint.new(0, isOwned and Color3.fromRGB(240, 255, 240) or Color3.fromRGB(255, 255, 255)),
                                    ColorSequenceKeypoint.new(1, isOwned and Color3.fromRGB(220, 245, 220) or Color3.fromRGB(248, 252, 255))
                                },
                                Rotation = 45
                            }),
                            
                            Stroke = e("UIStroke", {
                                Color = isOwned and Color3.fromRGB(100, 200, 100) or gamepass.gradientColors[1],
                                Thickness = 3,
                                Transparency = 0.1
                            }),
                            
                            -- Owned Badge
                            OwnedBadge = isOwned and e("Frame", {
                                Name = "OwnedBadge",
                                Size = UDim2.new(0, 60, 0, 25),
                                Position = UDim2.new(1, -70, 0, 10),
                                BackgroundColor3 = Color3.fromRGB(50, 150, 50),
                                BorderSizePixel = 0,
                                ZIndex = 35
                            }, {
                                Corner = e("UICorner", {
                                    CornerRadius = UDim.new(0, 12)
                                }),
                                BadgeText = e("TextLabel", {
                                    Size = UDim2.new(1, 0, 1, 0),
                                    Text = "OWNED",
                                    TextColor3 = Color3.fromRGB(255, 255, 255),
                                    TextSize = normalTextSize,
            TextWrapped = true,
                                    BackgroundTransparency = 1,
                                    Font = Enum.Font.GothamBold,
                                    ZIndex = 35
                                })
                            }) or nil,
                            
                            -- Category Badge
                            CategoryBadge = e("Frame", {
                                Name = "CategoryBadge",
                                Size = UDim2.new(0, 100, 0, 20),
                                Position = UDim2.new(0, 10, 0, 10),
                                BackgroundColor3 = gamepass.gradientColors[2],
                                BorderSizePixel = 0,
                                ZIndex = 34
                            }, {
                                Corner = e("UICorner", {
                                    CornerRadius = UDim.new(0, 10)
                                }),
                                CategoryText = e("TextLabel", {
                                    Size = UDim2.new(1, 0, 1, 0),
                                    Text = gamepass.category,
                                    TextColor3 = Color3.fromRGB(255, 255, 255),
                                    TextSize = normalTextSize,
            TextWrapped = true,
                                    BackgroundTransparency = 1,
                                    Font = Enum.Font.GothamBold,
                                    ZIndex = 34
                                })
                            }),
                            
                            -- Gamepass Icon
                            IconContainer = e("Frame", {
                                Name = "IconContainer",
                                Size = UDim2.new(0, 60, 0, 60),
                                Position = UDim2.new(0, 15, 0, 40),
                                BackgroundColor3 = Color3.fromRGB(40, 45, 55),
                                BorderSizePixel = 0,
                                ZIndex = 33
                            }, {
                                Corner = e("UICorner", {
                                    CornerRadius = UDim.new(0.5, 0) -- Make it perfectly circular
                                }),
                                IconGradient = e("UIGradient", {
                                    Color = ColorSequence.new{
                                        ColorSequenceKeypoint.new(0, gamepass.gradientColors[1]),
                                        ColorSequenceKeypoint.new(1, gamepass.gradientColors[2])
                                    },
                                    Rotation = 45
                                }),
                                -- White border ring for extra polish
                                IconStroke = e("UIStroke", {
                                    Color = Color3.fromRGB(255, 255, 255),
                                    Thickness = 2,
                                    Transparency = 0.3
                                }),
                                Icon = e("ImageLabel", {
                                    Name = "GamepassIcon",
                                    Size = UDim2.new(0.9, 0, 0.9, 0),
                                    Position = UDim2.new(0.05, 0, 0.05, 0),
                                    Image = gamepass.icon,
                                    BackgroundTransparency = 1,
                                    ImageColor3 = Color3.fromRGB(255, 255, 255),
                                    ZIndex = 34,
                                    ref = gamepassIconRef
                                }, {
                                    -- Make the icon itself circular too for perfect fit
                                    IconCorner = e("UICorner", {
                                        CornerRadius = UDim.new(0.5, 0)
                                    })
                                })
                            }),
                            
                            -- Gamepass Name
                            GamepassName = e("TextLabel", {
                                Name = "GamepassName",
                                Size = UDim2.new(1, -95, 0, 25),
                                Position = UDim2.new(0, 85, 0, 40),
                                Text = gamepass.name,
                                TextColor3 = Color3.fromRGB(40, 50, 80),
                                TextSize = cardTitleSize,
            TextWrapped = true,
                                BackgroundTransparency = 1,
                                Font = Enum.Font.GothamBold,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                ZIndex = 33
                            }),
                            
                            -- Gamepass Description
                            Description = e("TextLabel", {
                                Name = "Description",
                                Size = UDim2.new(1, -95, 0, 35),
                                Position = UDim2.new(0, 85, 0, 65),
                                Text = gamepass.description,
                                TextColor3 = Color3.fromRGB(70, 80, 120),
                                TextSize = ScreenUtils.getProportionalTextSize(screenSize, 12),
                                BackgroundTransparency = 1,
                                Font = Enum.Font.Gotham,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                TextYAlignment = Enum.TextYAlignment.Top,
                                TextWrapped = true,
                                ZIndex = 33
                            }),
                            
                            -- Purchase Button
                            PurchaseButton = e("TextButton", {
                                Name = "PurchaseButton",
                                Size = UDim2.new(1, -20, 0, 35),
                                Position = UDim2.new(0, 10, 1, -45),
                                Text = isOwned and "✅ OWNED" or "",
                                TextColor3 = Color3.fromRGB(255, 255, 255),
                                TextSize = normalTextSize,
            TextWrapped = true,
                                BackgroundColor3 = isOwned and Color3.fromRGB(50, 150, 50) or gamepass.gradientColors[1],
                                BorderSizePixel = 0,
                                Font = Enum.Font.GothamBold,
                                ZIndex = 33,
                                Active = not isOwned,
                                AutoButtonColor = not isOwned,
                                [React.Event.Activated] = not isOwned and function()
                                    handlePurchase(gamepass.key)
                                end or nil
                            }, {
                                Corner = e("UICorner", {
                                    CornerRadius = UDim.new(0, 10)
                                }),
                                ButtonGradient = e("UIGradient", {
                                    Color = ColorSequence.new{
                                        ColorSequenceKeypoint.new(0, isOwned and Color3.fromRGB(60, 180, 60) or gamepass.gradientColors[1]),
                                        ColorSequenceKeypoint.new(1, isOwned and Color3.fromRGB(40, 140, 40) or gamepass.gradientColors[2])
                                    },
                                    Rotation = 45
                                }),
                                ButtonStroke = e("UIStroke", {
                                    Color = Color3.fromRGB(255, 255, 255),
                                    Thickness = 2,
                                    Transparency = 0.2
                                }),
                                TextStroke = e("UIStroke", {
                                    Color = Color3.fromRGB(0, 0, 0),
                                    Thickness = 3,
                                    Transparency = 0.3,
                                    ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
                                }),
                                
                                -- Robux Icon and Price (only for unowned gamepasses)
                                PriceContainer = not isOwned and e("Frame", {
                                    Name = "PriceContainer",
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
                                    
                                    RobuxIcon = e("ImageLabel", {
                                        Name = "RobuxIcon",
                                        Size = UDim2.new(0, 28, 0, 28),
                                        Image = "rbxasset://textures/ui/common/robux.png", -- Official Robux icon (medium)
                                        BackgroundTransparency = 1,
                                        ImageColor3 = Color3.fromRGB(255, 255, 255),
                                        ZIndex = 34,
                                        LayoutOrder = 1,
                                        ref = robuxIconRef
                                    }),
                                    
                                    PriceText = e("TextLabel", {
                                        Name = "PriceText",
                                        Size = UDim2.new(0, 0, 1, 0),
                                        AutomaticSize = Enum.AutomaticSize.X,
                                        Text = gamepass.price:gsub("R%$ ", ""), -- Remove "R$ " prefix
                                        TextColor3 = Color3.fromRGB(255, 255, 255),
                                        TextSize = cardValueSize,
            TextWrapped = true,
                                        BackgroundTransparency = 1,
                                        Font = Enum.Font.GothamBold,
                                        ZIndex = 34,
                                        LayoutOrder = 2
                                    }, {
                                        TextStroke = e("UIStroke", {
                                            Color = Color3.fromRGB(0, 0, 0),
                                            Thickness = 3,
                                            Transparency = 0.3,
                                            ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
                                        })
                                    })
                                }) or nil
                            })
                        })
                    end
                    
                    return cards
                end)())
            })
        })
        })
    })
end

return GamepassPanel