-- Loading Screen Component
-- Shows while waiting for player data to load and farm to be assigned

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local TweenService = game:GetService("TweenService")
local e = React.createElement

local function LoadingScreen(props)
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    
    -- Responsive sizing
    local isMobile = screenSize.X < 768
    local scale = isMobile and 0.9 or 1
    
    -- Loading animation state
    local loadingRef = React.useRef()
    local dotsRef = React.useRef()
    
    -- Animated loading dots
    React.useEffect(function()
        if not dotsRef.current then return end
        
        local dots = {".", "..", "...", ""}
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
        
        -- Update dots every 0.5 seconds
        local connection = task.spawn(function()
            while dotsRef.current do
                updateDots()
                task.wait(0.5)
            end
        end)
        
        return function()
            task.cancel(connection)
        end
    end, {})
    
    -- Spinning farm icon animation
    React.useEffect(function()
        if not loadingRef.current then return end
        
        local spinTween = TweenService:Create(loadingRef.current,
            TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
            {Rotation = 360}
        )
        
        spinTween:Play()
        
        return function()
            spinTween:Cancel()
            spinTween:Destroy()
        end
    end, {})
    
    return e("ScreenGui", {
        Name = "LoadingScreen",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 10 -- High display order to appear above everything
    }, {
        -- Full screen background (mobile-aware - doesn't block touch controls)
        Background = e("TextButton", {
            Name = "Background",
            Size = isMobile and UDim2.new(1, 0, 1, -200) or UDim2.new(1, 0, 1, 0), -- Leave bottom space for mobile controls
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(25, 35, 45),
            BorderSizePixel = 0,
            ZIndex = 100,
            Text = "",
            AutoButtonColor = false,
            Active = not isMobile -- Don't capture input on mobile to allow touch controls
        }, {
            -- Gradient overlay
            Gradient = e("UIGradient", {
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 40, 55)),
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(25, 35, 45)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 45, 60))
                },
                Rotation = 45
            }),
            
            -- Main content container
            ContentFrame = e("Frame", {
                Name = "ContentFrame",
                Size = UDim2.new(0, 400 * scale, 0, 300 * scale),
                Position = UDim2.new(0.5, -200 * scale, 0.5, -150 * scale),
                BackgroundTransparency = 1,
                ZIndex = 101
            }, {
                -- Game title
                Title = e("TextLabel", {
                    Name = "Title",
                    Size = UDim2.new(1, 0, 0, 60 * scale),
                    Position = UDim2.new(0, 0, 0, 0),
                    Text = "🌾 Farming Simulator",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextScaled = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.SourceSansBold,
                    TextStrokeTransparency = 0.5,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 102
                }, {
                    TextSizeConstraint = e("UITextSizeConstraint", {
                        MaxTextSize = 48 * scale,
                        MinTextSize = 24 * scale
                    })
                }),
                
                -- Loading icon (spinning farm/plant icon)
                LoadingIcon = e("Frame", {
                    Name = "LoadingIcon",
                    Size = UDim2.new(0, 120 * scale, 0, 120 * scale),
                    Position = UDim2.new(0.5, -60 * scale, 0, 80 * scale),
                    BackgroundColor3 = Color3.fromRGB(60, 120, 60),
                    BorderSizePixel = 0,
                    ZIndex = 102,
                    ref = loadingRef
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0.5, 0)
                    }),
                    
                    Stroke = e("UIStroke", {
                        Color = Color3.fromRGB(80, 140, 80),
                        Thickness = 3,
                        Transparency = 0.3
                    }),
                    
                    -- Icon text (plant emoji)
                    IconText = e("TextLabel", {
                        Size = UDim2.new(1, 0, 1, 0),
                        Position = UDim2.new(0, 0, 0, 0),
                        Text = "🌱",
                        TextScaled = true,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.SourceSansBold,
                        ZIndex = 103
                    }, {
                        TextSizeConstraint = e("UITextSizeConstraint", {
                            MaxTextSize = 60 * scale,
                            MinTextSize = 30 * scale
                        })
                    })
                }),
                
                -- Loading text with animated dots
                LoadingText = e("TextLabel", {
                    Name = "LoadingText",
                    Size = UDim2.new(1, 0, 0, 40 * scale),
                    Position = UDim2.new(0, 0, 0, 220 * scale),
                    Text = "Loading...",
                    TextColor3 = Color3.fromRGB(200, 200, 200),
                    TextScaled = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.SourceSans,
                    ZIndex = 102,
                    ref = dotsRef
                }, {
                    TextSizeConstraint = e("UITextSizeConstraint", {
                        MaxTextSize = 24 * scale,
                        MinTextSize = 16 * scale
                    })
                }),
                
                -- Subtitle
                Subtitle = e("TextLabel", {
                    Name = "Subtitle",
                    Size = UDim2.new(1, 0, 0, 30 * scale),
                    Position = UDim2.new(0, 0, 0, 260 * scale),
                    Text = "Preparing your farm and loading player data...",
                    TextColor3 = Color3.fromRGB(150, 150, 150),
                    TextScaled = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.SourceSansItalic,
                    ZIndex = 102
                }, {
                    TextSizeConstraint = e("UITextSizeConstraint", {
                        MaxTextSize = 18 * scale,
                        MinTextSize = 12 * scale
                    })
                })
            })
        })
    })
end

return LoadingScreen