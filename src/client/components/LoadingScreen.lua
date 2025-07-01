-- Modern Loading Screen Component
-- Shows while waiting for player data to load and farm to be assigned
-- Beautiful full-screen design with barn icon and smooth animations

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local TweenService = game:GetService("TweenService")
local e = React.createElement
local assets = require(game:GetService("ReplicatedStorage").Shared.assets)
local ScreenUtils = require(game:GetService("ReplicatedStorage").Shared.ScreenUtils)

local function LoadingScreen(props)
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    
    -- Proper proportional sizing
    local titleTextSize = ScreenUtils.getProportionalTextSize(screenSize, 48)
    local normalTextSize = ScreenUtils.getProportionalTextSize(screenSize, 24)
    local subtitleTextSize = ScreenUtils.getProportionalTextSize(screenSize, 18)
    local smallTextSize = ScreenUtils.getProportionalTextSize(screenSize, 16)
    
    -- Loading animation refs
    local barnIconRef = React.useRef()
    local dotsRef = React.useRef()
    local shimmerRef = React.useRef()
    
    -- Animated loading dots
    React.useEffect(function()
        if not dotsRef.current then return end
        
        local dots = {"", ".", "..", "..."}
        local currentIndex = 1
        
        local function updateDots()
            if dotsRef.current then
                dotsRef.current.Text = "Loading" .. dots[currentIndex]
                currentIndex = currentIndex + 1
                if currentIndex > #dots then
                    currentIndex = 1
                end
            end
        end
        
        -- Update dots every 0.6 seconds
        local connection = task.spawn(function()
            while dotsRef.current do
                updateDots()
                task.wait(0.6)
            end
        end)
        
        return function()
            task.cancel(connection)
        end
    end, {})
    
    -- Floating barn icon animation
    React.useEffect(function()
        if not barnIconRef.current then return end
        
        -- Gentle floating animation
        local floatTween = TweenService:Create(barnIconRef.current,
            TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {Position = UDim2.new(0.5, 0, 0.4, ScreenUtils.getProportionalSize(screenSize, -10))}
        )
        
        floatTween:Play()
        
        return function()
            floatTween:Cancel()
            floatTween:Destroy()
        end
    end, {})
    
    -- Shimmer effect animation
    React.useEffect(function()
        if not shimmerRef.current then return end
        
        local shimmerTween = TweenService:Create(shimmerRef.current,
            TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
            {Position = UDim2.new(1.2, 0, 0, 0)}
        )
        
        shimmerTween:Play()
        
        return function()
            shimmerTween:Cancel()
            shimmerTween:Destroy()
        end
    end, {})
    
    return e("ScreenGui", {
        Name = "LoadingScreen",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 10 -- High display order to appear above everything
    }, {
        -- Full screen background - completely covers screen on mobile
        Background = e("Frame", {
            Name = "Background",
            Size = UDim2.new(1, 0, 1, 0), -- Full screen coverage
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(20, 30, 40),
            BorderSizePixel = 0,
            ZIndex = 100
        }, {
            -- Beautiful gradient background
            Gradient = e("UIGradient", {
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 40, 60)),
                    ColorSequenceKeypoint.new(0.3, Color3.fromRGB(20, 30, 40)),
                    ColorSequenceKeypoint.new(0.7, Color3.fromRGB(15, 25, 35)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 45, 65))
                },
                Rotation = 135
            }),
            
            -- Main content container
            ContentFrame = e("Frame", {
                Name = "ContentFrame",
                Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 500), 0, ScreenUtils.getProportionalSize(screenSize, 400)),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                ZIndex = 101
            }, {
                -- Game title with glow effect
                TitleContainer = e("Frame", {
                    Name = "TitleContainer",
                    Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(screenSize, 80)),
                    Position = UDim2.new(0, 0, 0, 0),
                    BackgroundTransparency = 1,
                    ZIndex = 102
                }, {
                    Title = e("TextLabel", {
                        Name = "Title",
                        Size = UDim2.new(1, 0, 1, 0),
                        Position = UDim2.new(0, 0, 0, 0),
                        Text = "🌾 Farm Life Simulator",
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = titleTextSize,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.GothamBold,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        ZIndex = 103
                    }, {
                        -- Title glow effect
                        TitleStroke = e("UIStroke", {
                            Color = Color3.fromRGB(100, 200, 255),
                            Thickness = 2,
                            Transparency = 0.3
                        }),
                        TitleShadow = e("UIStroke", {
                            Color = Color3.fromRGB(0, 0, 0),
                            Thickness = 4,
                            Transparency = 0.7,
                            ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
                        })
                    }),
                    
                    -- Shimmer effect overlay
                    ShimmerEffect = e("Frame", {
                        Name = "ShimmerEffect",
                        Size = UDim2.new(0.3, 0, 1, 0),
                        Position = UDim2.new(-0.3, 0, 0, 0),
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        BackgroundTransparency = 0.8,
                        BorderSizePixel = 0,
                        ZIndex = 104,
                        ref = shimmerRef
                    }, {
                        Gradient = e("UIGradient", {
                            Color = ColorSequence.new{
                                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 220, 255)),
                                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
                            },
                            Transparency = NumberSequence.new{
                                NumberSequenceKeypoint.new(0, 1),
                                NumberSequenceKeypoint.new(0.5, 0.3),
                                NumberSequenceKeypoint.new(1, 1)
                            },
                            Rotation = 45
                        })
                    })
                }),
                
                -- Beautiful barn icon container with floating animation
                IconContainer = e("Frame", {
                    Name = "IconContainer",
                    Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 160), 0, ScreenUtils.getProportionalSize(screenSize, 160)),
                    Position = UDim2.new(0.5, 0, 0.4, 0),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = Color3.fromRGB(100, 60, 40),
                    BorderSizePixel = 0,
                    ZIndex = 102,
                    ref = barnIconRef
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0.15, 0) -- Rounded square
                    }),
                    
                    -- Beautiful gradient
                    IconGradient = e("UIGradient", {
                        Color = ColorSequence.new{
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 100, 70)),
                            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 80, 50)),
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 60, 40))
                        },
                        Rotation = 135
                    }),
                    
                    -- Glowing border
                    IconStroke = e("UIStroke", {
                        Color = Color3.fromRGB(255, 200, 150),
                        Thickness = 3,
                        Transparency = 0.2
                    }),
                    
                    -- Inner shadow effect
                    ShadowFrame = e("Frame", {
                        Size = UDim2.new(1, -6, 1, -6),
                        Position = UDim2.new(0, 3, 0, 3),
                        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                        BackgroundTransparency = 0.8,
                        BorderSizePixel = 0,
                        ZIndex = 103
                    }, {
                        Corner = e("UICorner", {
                            CornerRadius = UDim.new(0.15, 0)
                        })
                    }),
                    
                    -- Barn icon
                    BarnIcon = e("ImageLabel", {
                        Name = "BarnIcon",
                        Size = UDim2.new(0.7, 0, 0.7, 0),
                        Position = UDim2.new(0.5, 0, 0.5, 0),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Image = assets["General/Barn/Barn Outline 256.png"] or "rbxassetid://130411592268971",
                        BackgroundTransparency = 1,
                        ImageColor3 = Color3.fromRGB(255, 255, 255),
                        ScaleType = Enum.ScaleType.Fit,
                        ZIndex = 104
                    }, {
                        -- Icon glow
                        IconGlow = e("UIStroke", {
                            Color = Color3.fromRGB(255, 220, 180),
                            Thickness = 2,
                            Transparency = 0.5,
                            ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                        })
                    })
                }),
                
                -- Loading text with animated dots
                LoadingText = e("TextLabel", {
                    Name = "LoadingText",
                    Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(screenSize, 50)),
                    Position = UDim2.new(0, 0, 0.75, 0),
                    Text = "Loading...",
                    TextColor3 = Color3.fromRGB(220, 220, 220),
                    TextSize = normalTextSize,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 102,
                    ref = dotsRef
                }, {
                    TextStroke = e("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = 2,
                        Transparency = 0.7
                    })
                }),
                
                -- Subtitle with better styling
                Subtitle = e("TextLabel", {
                    Name = "Subtitle",
                    Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(screenSize, 40)),
                    Position = UDim2.new(0, 0, 0.85, 0),
                    Text = "Preparing your farm and loading player data...",
                    TextColor3 = Color3.fromRGB(180, 180, 180),
                    TextSize = subtitleTextSize,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 102
                }, {
                    TextStroke = e("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = 1,
                        Transparency = 0.8
                    })
                }),
                
                -- Progress indicator dots
                ProgressDots = e("Frame", {
                    Name = "ProgressDots",
                    Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 100), 0, ScreenUtils.getProportionalSize(screenSize, 20)),
                    Position = UDim2.new(0.5, 0, 0.95, 0),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    ZIndex = 102
                }, {
                    Layout = e("UIListLayout", {
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        Padding = UDim.new(0, ScreenUtils.getProportionalSize(screenSize, 15)),
                        SortOrder = Enum.SortOrder.LayoutOrder
                    }),
                    
                    Dot1 = e("Frame", {
                        Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 8), 0, ScreenUtils.getProportionalSize(screenSize, 8)),
                        BackgroundColor3 = Color3.fromRGB(100, 200, 255),
                        BorderSizePixel = 0,
                        LayoutOrder = 1
                    }, {
                        Corner = e("UICorner", { CornerRadius = UDim.new(0.5, 0) })
                    }),
                    
                    Dot2 = e("Frame", {
                        Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 8), 0, ScreenUtils.getProportionalSize(screenSize, 8)),
                        BackgroundColor3 = Color3.fromRGB(100, 200, 255),
                        BorderSizePixel = 0,
                        LayoutOrder = 2
                    }, {
                        Corner = e("UICorner", { CornerRadius = UDim.new(0.5, 0) })
                    }),
                    
                    Dot3 = e("Frame", {
                        Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 8), 0, ScreenUtils.getProportionalSize(screenSize, 8)),
                        BackgroundColor3 = Color3.fromRGB(100, 200, 255),
                        BorderSizePixel = 0,
                        LayoutOrder = 3
                    }, {
                        Corner = e("UICorner", { CornerRadius = UDim.new(0.5, 0) })
                    })
                })
            })
        })
    })
end

return LoadingScreen