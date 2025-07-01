-- Modern Boost Panel Component
-- Single boost button that opens a detailed panel showing all active boosts
-- Matches the modern UI design patterns used throughout the game

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local SocialService = game:GetService("SocialService")
local e = React.createElement
local assets = require(game:GetService("ReplicatedStorage").Shared.assets)
local ScreenUtils = require(game:GetService("ReplicatedStorage").Shared.ScreenUtils)

local Modal = require(script.Parent.Modal)
local NumberFormatter = require(game:GetService("ReplicatedStorage").Shared.NumberFormatter)

local player = Players.LocalPlayer

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

-- Function to create flip animation for boost button
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
    
    -- Create flip animation
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

local function BoostPanel(props)
    local playerData = props.playerData
    local gamepassData = props.gamepassData or {}
    local weatherData = props.weatherData or {}
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    
    -- Panel visibility state
    local panelVisible, setPanelVisible = React.useState(false)
    
    -- Animation refs
    local boostIconRef = React.useRef(nil)
    local boostAnimTracker = React.useRef(nil)
    
    local scale = ScreenUtils.getProportionalScale(screenSize)
    
    -- Proportional text sizes
    local titleTextSize = ScreenUtils.getProportionalTextSize(screenSize, 32)
    local normalTextSize = ScreenUtils.getProportionalTextSize(screenSize, 18)
    local smallTextSize = ScreenUtils.getProportionalTextSize(screenSize, 14)
    local buttonTextSize = ScreenUtils.getProportionalTextSize(screenSize, 16)
    local cardTitleSize = ScreenUtils.getProportionalTextSize(screenSize, 20)
    local cardValueSize = ScreenUtils.getProportionalTextSize(screenSize, 16)
    local tinyTextSize = ScreenUtils.getProportionalTextSize(screenSize, 12)
    
    -- Button sizing to match side buttons
    local buttonSize = ScreenUtils.getProportionalSize(screenSize, 55)
    
    -- Panel sizing
    local panelWidth = math.min(screenSize.X * 0.9, ScreenUtils.getProportionalSize(screenSize, 900))
    local panelHeight = math.min(screenSize.Y * 0.85, ScreenUtils.getProportionalSize(screenSize, 600))
    
    -- Calculate all boosts
    local boosts = {}
    
    -- Gamepass 2x Money Boost
    if playerData.gamepasses and playerData.gamepasses.moneyMultiplier then
        table.insert(boosts, {
            icon = gamepassData.moneyMultiplier and gamepassData.moneyMultiplier.iconUrl or "rbxassetid://1277613878",
            name = "2x Money Boost",
            effect = "+100%",
            effects = {
                "Double money from all crop sales",
                "Permanent gamepass benefit",
                "Stacks with other boosts",
                "Rainbow money popup effects",
                "Bouncing 2x indicator on money display"
            },
            description = "Your 2x Money Boost gamepass doubles all money earned from selling crops and adds special visual effects!",
            duration = "Permanent",
            color = Color3.fromRGB(255, 215, 0), -- Gold color
            category = "💎 Premium"
        })
    end
    
    -- Gamepass 2x Production Boost
    if playerData.gamepasses and playerData.gamepasses.productionBoost then
        table.insert(boosts, {
            icon = gamepassData.productionBoost and gamepassData.productionBoost.iconUrl or "rbxassetid://1283605505",
            name = "2x Production",
            effect = "+100%",
            effects = {
                "Double speed of all crop production",
                "All plants grow twice as fast",
                "More crops per hour",
                "Permanent gamepass benefit",
                "Stacks with other production boosts"
            },
            description = "Your 2x Production gamepass doubles the speed of all crop growth, meaning faster harvests and more profits!",
            duration = "Permanent",
            color = Color3.fromRGB(0, 255, 127), -- Spring green color
            category = "💎 Premium"
        })
    end
    
    -- Debug Production Boost (if active)
    if playerData.debugProductionBoost and playerData.debugProductionBoost > 0 then
        table.insert(boosts, {
            icon = "🐛",
            name = "Debug Production Boost",
            effect = "+" .. playerData.debugProductionBoost .. "%",
            effects = {
                "+" .. playerData.debugProductionBoost .. "% faster crop growth",
                "Debug boost for testing",
                "Stacks with online boost"
            },
            description = "DEBUG: This is a temporary boost for testing production rates!",
            duration = "Until removed",
            color = Color3.fromRGB(255, 0, 255), -- Magenta for debug
            category = "🐛 Debug"
        })
    end
    
    -- Online Time Boost
    table.insert(boosts, {
        icon = "⏰",
        name = "Online Time",
        effect = "+100%",
        effects = {
            "+100% faster crop growth (2x speed)",
            "Crops grow twice as fast while online",
            "Essential for efficient farming"
        },
        description = "Being online doubles your crop growth speed! This is the most important boost for active farmers.",
        duration = "While online",
        color = Color3.fromRGB(100, 255, 100),
        category = "🌟 Activity"
    })
    
    -- Weather-based boosts (affects all crops equally)
    if weatherData.current then
        local weatherName = weatherData.current.name
        if weatherName == "Rainy" or weatherName == "Thunderstorm" then
            local multiplier = weatherName == "Rainy" and "90%" or "70%"
            table.insert(boosts, {
                icon = "💧",
                name = weatherName .. " Weather",
                effect = multiplier,
                effects = {
                    "Free automatic watering of all crops",
                    "All plants grow at " .. multiplier .. " speed",
                    "No water evaporation during rain"
                },
                description = "Rainy weather provides automatic watering but slightly slower growth for all crops.",
                duration = "While " .. weatherName:lower(),
                color = Color3.fromRGB(100, 150, 255),
                category = "🌦️ Weather"
            })
        elseif weatherName == "Sunny" then
            table.insert(boosts, {
                icon = "☀️",
                name = "Sunny Weather",
                effect = "+50%",
                effects = {
                    "All plants grow 50% faster",
                    "Plants require 30% more watering"
                },
                description = "Sunny weather boosts growth speed for all crops!",
                duration = "While sunny",
                color = Color3.fromRGB(255, 255, 100),
                category = "🌦️ Weather"
            })
        elseif weatherName == "Cloudy" then
            table.insert(boosts, {
                icon = "☁️",
                name = "Cloudy Weather", 
                effect = "0%",
                effects = {
                    "All plants grow at normal speed",
                    "Normal water requirements"
                },
                description = "Cloudy weather provides neutral conditions for all crops.",
                duration = "While cloudy",
                color = Color3.fromRGB(200, 200, 200),
                category = "🌦️ Weather"
            })
        end
    end
    
    -- Friends Boost (simplified for now)
    local friendsOnline = 0
    if friendsOnline > 0 then
        local moneyBoost = friendsOnline * 10
        table.insert(boosts, {
            icon = "👥",
            name = "Friends Boost",
            effect = "+" .. moneyBoost .. "%",
            effects = {
                "+" .. moneyBoost .. "% money from all sales",
                "+5% chance for rare seed drops per friend",
                "Shared plot watering (friends can help water)"
            },
            description = "Having friends online provides multiple cooperative farming benefits!",
            duration = "While friends online",
            color = Color3.fromRGB(255, 150, 255),
            category = "👥 Social"
        })
    end
    
    -- Calculate total boost count and effect
    local totalBoosts = #boosts
    local totalMoneyMultiplier = 1.0
    
    for _, boost in ipairs(boosts) do
        if boost.effect:match("%%") then
            local percent = tonumber(boost.effect:match("([%d%.]+)"))
            if percent and percent > 0 then -- Only add non-zero percentages
                totalMoneyMultiplier = totalMoneyMultiplier + (percent / 100)
            end
        end
    end
    
    -- Don't show button if no boosts
    if totalBoosts == 0 then
        return nil
    end
    
    -- Handle panel toggle
    local function togglePanel()
        playSound("click")
        createFlipAnimation(boostIconRef, boostAnimTracker)
        setPanelVisible(not panelVisible)
    end
    
    -- Handle panel close
    local function handleClose()
        setPanelVisible(false)
    end
    
    -- Calculate grid for boost cards - responsive layout
    local minCardWidth = ScreenUtils.getProportionalSize(screenSize, 250)
    local cardsPerRow = math.max(1, math.floor((panelWidth - 120) / (minCardWidth + 20)))
    local cardWidth = (panelWidth - 120) / cardsPerRow - 20
    local cardHeight = ScreenUtils.getProportionalSize(screenSize, 180)
    local totalRows = math.ceil(totalBoosts / cardsPerRow)
    -- Account for: card heights + spacing between rows + top/bottom padding
    -- Multiply by 1.3 for safety buffer without excessive empty space
    local totalHeight = ((totalRows * cardHeight) + ((totalRows - 1) * 20) + 40) * 1.3
    
    return e("Frame", {
        Name = "BoostSystem",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = 14
    }, {
        -- Boost Button (bottom left corner)
        BoostButton = e("TextButton", {
            Name = "BoostButton",
            Size = UDim2.new(0, buttonSize, 0, buttonSize),
            Position = UDim2.new(0, ScreenUtils.getProportionalPadding(screenSize, 20), 1, -(buttonSize + ScreenUtils.getProportionalPadding(screenSize, 20))),
            Text = "",
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = 15,
            [React.Event.Activated] = togglePanel,
            [React.Event.MouseEnter] = function()
                playSound("hover")
                createFlipAnimation(boostIconRef, boostAnimTracker)
            end
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0.5, 0) -- Make it circular
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0), -- Black outline
                Thickness = 2,
                Transparency = 0,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            }),
            Gradient = e("UIGradient", {
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 245, 180)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 220, 100))
                },
                Rotation = 45
            }),
            
            
            -- Boost Icon (centered in circle)
            BoostIcon = e("ImageLabel", {
                Name = "BoostIcon",
                Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 32), 0, ScreenUtils.getProportionalSize(screenSize, 32)),
                Position = UDim2.new(0.5, ScreenUtils.getProportionalSize(screenSize, -16), 0.5, ScreenUtils.getProportionalSize(screenSize, -16)), -- Perfectly centered
                Image = assets["Player/Boost/Boost Yellow Outline 256.png"] or "",
                BackgroundTransparency = 1,
                ScaleType = Enum.ScaleType.Fit,
                ImageColor3 = Color3.fromRGB(255, 215, 0),
                ZIndex = 16,
                ref = boostIconRef
            }),
            
            -- Boost Count Badge (top left)
            CountBadge = e("Frame", {
                Name = "CountBadge",
                Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 24), 0, ScreenUtils.getProportionalSize(screenSize, 16)),
                Position = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, -6), 0, ScreenUtils.getProportionalSize(screenSize, -4)), -- Top left, slightly outside circle
                BackgroundColor3 = Color3.fromRGB(255, 80, 80),
                BorderSizePixel = 0,
                ZIndex = 17
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 8)
                }),
                CountText = e("TextLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = tostring(totalBoosts),
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.getProportionalTextSize(screenSize, 12),
            TextWrapped = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    ZIndex = 18
                }, {
                    TextStroke = e("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = 2,
                        Transparency = 0.5
                    })
                })
            }),
            
            -- Effect Badge (bottom right)
            EffectBadge = e("Frame", {
                Name = "EffectBadge",
                Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 65), 0, ScreenUtils.getProportionalSize(screenSize, 18)), -- Made even wider and taller to fit larger numbers
                Position = UDim2.new(1, ScreenUtils.getProportionalSize(screenSize, -60), 1, ScreenUtils.getProportionalSize(screenSize, -10)), -- Moved further down to avoid blocking icon
                BackgroundColor3 = Color3.fromRGB(80, 255, 80),
                BorderSizePixel = 0,
                ZIndex = 17
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 9)
                }),
                EffectText = e("TextLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = (function()
                        local percentValue = (totalMoneyMultiplier - 1) * 100
                        return "+" .. NumberFormatter.format(percentValue) .. "%"
                    end)(),
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.getProportionalTextSize(screenSize, 11), -- Slightly smaller text to ensure it fits
            TextWrapped = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    ZIndex = 18
                }, {
                    TextStroke = e("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = 2,
                        Transparency = 0.5
                    })
                })
            })
        }),
        
        -- Boost Panel Modal
        BoostModal = panelVisible and e(Modal, {
            visible = panelVisible,
            onClose = handleClose,
            zIndex = 30
        }, {
            BoostContainer = e("Frame", {
                Name = "BoostContainer",
                Size = UDim2.new(0, panelWidth, 0, panelHeight + 50),
                Position = UDim2.new(0.5, -panelWidth / 2, 0.5, -(panelHeight + 50) / 2),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 30
            }, {
                BoostPanel = e("Frame", {
                    Name = "BoostPanel",
                    Size = UDim2.new(0, panelWidth, 0, panelHeight),
                    Position = UDim2.new(0, 0, 0, 50),
                    BackgroundColor3 = Color3.fromRGB(240, 245, 255),
                    BackgroundTransparency = 0.05,
                    BorderSizePixel = 0,
                    ZIndex = 30
                }, {
                    -- Floating Title (Boost-themed gold)
                    FloatingTitle = e("Frame", {
                        Name = "FloatingTitle",
                        Size = UDim2.new(0, 200, 0, 40),
                        Position = UDim2.new(0, -10, 0, -25),
                        BackgroundColor3 = Color3.fromRGB(255, 215, 0),
                        BorderSizePixel = 0,
                        ZIndex = 32
                    }, {
                        Corner = e("UICorner", {
                            CornerRadius = UDim.new(0, 12)
                        }),
                        Gradient = e("UIGradient", {
                            Color = ColorSequence.new{
                                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 235, 50)),
                                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 195, 0))
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
                            Text = "⭐ ACTIVE BOOSTS",
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
                        Color = Color3.fromRGB(255, 215, 0),
                        Thickness = 3,
                        Transparency = 0.1
                    }),
                    
                    Gradient = e("UIGradient", {
                        Color = ColorSequence.new{
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                            ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 250, 240)),
                            ColorSequenceKeypoint.new(0.7, Color3.fromRGB(255, 245, 220)),
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 240, 200))
                        },
                        Rotation = 135
                    }),
                    
                    -- Close Button
                    CloseButton = e("ImageButton", {
                        Name = "CloseButton",
                        Size = UDim2.new(0, 32, 0, 32),
                        Position = UDim2.new(1, -16, 0, -16),
                        Image = assets["X Button/X Button 64.png"],
                        ImageColor3 = Color3.fromRGB(255, 255, 255),
                        ScaleType = Enum.ScaleType.Fit,
                        BackgroundColor3 = Color3.fromRGB(255, 100, 100),
                        BorderSizePixel = 0,
                        ZIndex = 34,
                        [React.Event.Activated] = handleClose
                    }, {
                        Corner = e("UICorner", {
                            CornerRadius = UDim.new(0, 6)
                        }),
                        Gradient = e("UIGradient", {
                            Color = ColorSequence.new{
                                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 140, 140)),
                                ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 60, 60))
                            },
                            Rotation = 90
                        }),
                        Stroke = e("UIStroke", {
                            Color = Color3.fromRGB(255, 255, 255),
                            Thickness = 2,
                            Transparency = 0.2
                        }),
                        Shadow = e("Frame", {
                            Name = "Shadow",
                            Size = UDim2.new(1, 2, 1, 2),
                            Position = UDim2.new(0, 2, 0, 2),
                            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                            BackgroundTransparency = 0.7,
                            BorderSizePixel = 0,
                            ZIndex = 33
                        }, {
                            Corner = e("UICorner", {
                                CornerRadius = UDim.new(0, 6)
                            })
                        })
                    }),
                    
                    -- Subtitle
                    Subtitle = e("TextLabel", {
                        Name = "Subtitle",
                        Size = UDim2.new(1, -80, 0, 25),
                        Position = UDim2.new(0, 40, 0, 15),
                        Text = "All your active farming boosts and their effects",
                        TextColor3 = Color3.fromRGB(60, 80, 140),
                        TextSize = normalTextSize,
            TextWrapped = true,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        ZIndex = 31
                    }),
                    
                    -- Summary Stats
                    SummaryStats = e("Frame", {
                        Name = "SummaryStats",
                        Size = UDim2.new(1, -40, 0, 30),
                        Position = UDim2.new(0, 20, 0, 45),
                        BackgroundColor3 = Color3.fromRGB(255, 250, 200),
                        BackgroundTransparency = 0.3,
                        BorderSizePixel = 0,
                        ZIndex = 31
                    }, {
                        Corner = e("UICorner", {
                            CornerRadius = UDim.new(0, 10)
                        }),
                        Stroke = e("UIStroke", {
                            Color = Color3.fromRGB(255, 215, 0),
                            Thickness = 2,
                            Transparency = 0.4
                        }),
                        
                        SummaryText = e("TextLabel", {
                            Size = UDim2.new(1, -20, 1, 0),
                            Position = UDim2.new(0, 10, 0, 0),
                            Text = string.format("🚀 Total Boost: +%.0f%% | 🎯 Active Boosts: %d", (totalMoneyMultiplier - 1) * 100, totalBoosts),
                            TextColor3 = Color3.fromRGB(80, 60, 0),
                            TextSize = normalTextSize,
            TextWrapped = true,
                            BackgroundTransparency = 1,
                            Font = Enum.Font.GothamBold,
                            TextXAlignment = Enum.TextXAlignment.Center,
                            ZIndex = 32
                        })
                    }),
                    
                    -- Scrollable Cards Container
                    CardsContainer = e("ScrollingFrame", {
                        Name = "CardsContainer",
                        Size = UDim2.new(1, -40, 1, -120),
                        Position = UDim2.new(0, 20, 0, 85),
                        BackgroundColor3 = Color3.fromRGB(250, 252, 255),
                        BackgroundTransparency = 0.2,
                        BorderSizePixel = 0,
                        ScrollBarThickness = 12,
                        ScrollingDirection = Enum.ScrollingDirection.Y,
                        CanvasSize = UDim2.new(0, 0, 0, totalHeight),
                        ScrollBarImageColor3 = Color3.fromRGB(255, 215, 0),
                        ZIndex = 31
                    }, {
                        Corner = e("UICorner", {
                            CornerRadius = UDim.new(0, 15)
                        }),
                        ContainerGradient = e("UIGradient", {
                            Color = ColorSequence.new{
                                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 250, 240))
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
                        
                        -- Generate boost cards
                        BoostCards = React.createElement(React.Fragment, {}, (function()
                            local cards = {}
                            
                            for i, boost in ipairs(boosts) do
                                cards[boost.name] = e("Frame", {
                                    Name = boost.name .. "Card",
                                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                    BackgroundTransparency = 0.05,
                                    BorderSizePixel = 0,
                                    ZIndex = 32,
                                    LayoutOrder = i
                                }, {
                                    Corner = e("UICorner", {
                                        CornerRadius = UDim.new(0, 15)
                                    }),
                                    
                                    Stroke = e("UIStroke", {
                                        Color = boost.color,
                                        Thickness = 3,
                                        Transparency = 0.1
                                    }),
                                    
                                    CardGradient = e("UIGradient", {
                                        Color = ColorSequence.new{
                                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                                            ColorSequenceKeypoint.new(1, Color3.fromRGB(248, 252, 255))
                                        },
                                        Rotation = 45
                                    }),
                                    
                                    -- Category Badge
                                    CategoryBadge = e("Frame", {
                                        Name = "CategoryBadge",
                                        Size = UDim2.new(0, 120, 0, 20),
                                        Position = UDim2.new(0, 10, 0, 10),
                                        BackgroundColor3 = boost.color,
                                        BorderSizePixel = 0,
                                        ZIndex = 34
                                    }, {
                                        Corner = e("UICorner", {
                                            CornerRadius = UDim.new(0, 10)
                                        }),
                                        CategoryText = e("TextLabel", {
                                            Size = UDim2.new(1, 0, 1, 0),
                                            Text = boost.category,
                                            TextColor3 = Color3.fromRGB(255, 255, 255),
                                            TextSize = normalTextSize,
            TextWrapped = true,
                                            BackgroundTransparency = 1,
                                            Font = Enum.Font.GothamBold,
                                            ZIndex = 34
                                        }, {
                                            TextStroke = e("UIStroke", {
                                                Color = Color3.fromRGB(0, 0, 0),
                                                Thickness = 2,
                                                Transparency = 0.5
                                            })
                                        })
                                    }),
                                    
                                    -- Boost Icon (handle both emoji and image assets)
                                    BoostIcon = (function()
                                        local isImageAsset = type(boost.icon) == "string" and boost.icon:find("rbxassetid://")
                                        if isImageAsset then
                                            return e("ImageLabel", {
                                                Name = "BoostIcon",
                                                Size = UDim2.new(0.2, 0, 0.22, 0), -- 20% width, 22% height of card
                                                Position = UDim2.new(0.5, 0, 0.25, 0), -- Centered horizontally, 25% from top
                                                AnchorPoint = Vector2.new(0.5, 0.5),
                                                Image = boost.icon,
                                                BackgroundTransparency = 1,
                                                ScaleType = Enum.ScaleType.Fit,
                                                ImageColor3 = Color3.fromRGB(255, 255, 255), -- Keep original colors for gamepass icons
                                                ZIndex = 33
                                            })
                                        else
                                            return e("TextLabel", {
                                                Name = "BoostIcon",
                                                Size = UDim2.new(0.25, 0, 0.28, 0), -- 25% width, 28% height of card
                                                Position = UDim2.new(0.5, 0, 0.25, 0), -- Centered horizontally, 25% from top
                                                AnchorPoint = Vector2.new(0.5, 0.5),
                                                Text = boost.icon,
                                                TextSize = normalTextSize * 1.5, -- Make emojis 50% bigger
                                                TextWrapped = true,
                                                BackgroundTransparency = 1,
                                                Font = Enum.Font.SourceSansBold,
                                                ZIndex = 33
                                            })
                                        end
                                    end)(),
                                    
                                    -- Boost Name
                                    BoostName = e("TextLabel", {
                                        Name = "BoostName",
                                        Size = UDim2.new(0.9, 0, 0.15, 0), -- 90% width, 15% height of card
                                        Position = UDim2.new(0.05, 0, 0.5, 0), -- 5% from left, 50% from top
                                        Text = boost.name,
                                        TextColor3 = Color3.fromRGB(40, 40, 40),
                                        TextSize = normalTextSize,
                                        TextWrapped = true,
                                        BackgroundTransparency = 1,
                                        Font = Enum.Font.GothamBold,
                                        TextXAlignment = Enum.TextXAlignment.Center,
                                        TextYAlignment = Enum.TextYAlignment.Center,
                                        ZIndex = 33
                                    }),
                                    
                                    -- Effect Badge (positioned below name, above description)
                                    EffectBadge = e("Frame", {
                                        Name = "EffectBadge",
                                        Size = UDim2.new(0.35, 0, 0.12, 0), -- 35% width, 12% height of card
                                        Position = UDim2.new(0.5, 0, 0.68, 0), -- Centered horizontally, 68% from top
                                        AnchorPoint = Vector2.new(0.5, 0.5),
                                        BackgroundColor3 = boost.color,
                                        BorderSizePixel = 0,
                                        ZIndex = 33
                                    }, {
                                        Corner = e("UICorner", {
                                            CornerRadius = UDim.new(0, 10)
                                        }),
                                        EffectText = e("TextLabel", {
                                            Size = UDim2.new(1, 0, 1, 0),
                                            Text = boost.effect,
                                            TextColor3 = Color3.fromRGB(255, 255, 255),
                                            TextSize = normalTextSize,
            TextWrapped = true,
                                            BackgroundTransparency = 1,
                                            Font = Enum.Font.GothamBold,
                                            ZIndex = 34
                                        }, {
                                            TextStroke = e("UIStroke", {
                                                Color = Color3.fromRGB(0, 0, 0),
                                                Thickness = 2,
                                                Transparency = 0.5
                                            })
                                        })
                                    }),
                                    
                                    -- Description (positioned below effect badge)
                                    Description = e("TextLabel", {
                                        Name = "Description",
                                        Size = UDim2.new(0.9, 0, 0.18, 0), -- 90% width, 18% height of card
                                        Position = UDim2.new(0.05, 0, 0.76, 0), -- 5% from left, 76% from top
                                        Text = boost.description,
                                        TextColor3 = Color3.fromRGB(70, 80, 120),
                                        TextSize = ScreenUtils.getProportionalTextSize(screenSize, 11),
                                        BackgroundTransparency = 1,
                                        Font = Enum.Font.Gotham, -- Regular weight for readability
                                        TextXAlignment = Enum.TextXAlignment.Center,
                                        TextYAlignment = Enum.TextYAlignment.Top,
                                        TextWrapped = true,
                                        ZIndex = 33
                                    }),
                                    
                                    -- Duration (fixed positioning to stay within card)
                                    Duration = e("TextLabel", {
                                        Name = "Duration",
                                        Size = UDim2.new(1, -10, 0, 15),
                                        Position = UDim2.new(0, 5, 1, -20), -- Bottom of card with 20px margin
                                        Text = "⏱️ " .. boost.duration,
                                        TextColor3 = Color3.fromRGB(120, 120, 120),
                                        TextSize = normalTextSize,
                                        TextWrapped = true,
                                        BackgroundTransparency = 1,
                                        Font = Enum.Font.GothamMedium,
                                        TextXAlignment = Enum.TextXAlignment.Center,
                                        ZIndex = 33
                                    })
                                })
                            end
                            
                            return cards
                        end)())
                    })
                })
            })
        }) or nil
    })
end

return BoostPanel