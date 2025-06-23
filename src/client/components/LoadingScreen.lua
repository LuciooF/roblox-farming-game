-- Loading Screen Component
-- Shows a loading screen while the game initializes

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local TweenService = game:GetService("TweenService")
local e = React.createElement

local function LoadingScreen(props)
    local visible = props.visible or false
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    
    -- State for animated dots
    local animationTick, setAnimationTick = React.useState(0)
    
    -- Animate loading dots
    React.useEffect(function()
        if not visible then return end
        
        local running = true
        spawn(function()
            while running and visible do
                wait(0.5)
                if running then
                    setAnimationTick(function(current)
                        return (current + 1) % 4
                    end)
                end
            end
        end)
        
        return function()
            running = false
        end
    end, {visible})
    
    if not visible then
        return nil
    end
    
    -- Generate loading dots based on animation tick
    local dots = ""
    for i = 1, animationTick do
        dots = dots .. "."
    end
    
    local isMobile = screenSize.X < 768
    local scale = isMobile and 0.8 or 1.0
    
    return e("Frame", {
        Name = "LoadingScreen",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(20, 25, 30),
        BorderSizePixel = 0,
        ZIndex = 1000 -- Above everything else
    }, {
        -- Background pattern
        Pattern = e("Frame", {
            Name = "Pattern",
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(25, 30, 35),
            BackgroundTransparency = 0.3,
            BorderSizePixel = 0
        }),
        
        -- Main loading container
        LoadingContainer = e("Frame", {
            Name = "LoadingContainer",
            Size = UDim2.new(0, 400 * scale, 0, 300 * scale),
            Position = UDim2.new(0.5, -200 * scale, 0.5, -150 * scale),
            BackgroundColor3 = Color3.fromRGB(30, 35, 40),
            BackgroundTransparency = 0.1,
            BorderSizePixel = 0
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 20)
            }),
            
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(60, 70, 80),
                Thickness = 2
            }),
            
            -- Farm emoji
            FarmIcon = e("TextLabel", {
                Name = "FarmIcon",
                Size = UDim2.new(0, 80 * scale, 0, 80 * scale),
                Position = UDim2.new(0.5, -40 * scale, 0, 40 * scale),
                Text = "🚜",
                TextColor3 = Color3.fromRGB(100, 200, 100),
                TextScaled = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansBold
            }),
            
            -- Game title
            Title = e("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -40, 0, 40 * scale),
                Position = UDim2.new(0, 20, 0, 130 * scale),
                Text = "🌾 Farming Simulator 🌾",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansBold,
                TextStrokeTransparency = 0.5,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            }),
            
            -- Loading text
            LoadingText = e("TextLabel", {
                Name = "LoadingText", 
                Size = UDim2.new(1, -40, 0, 30 * scale),
                Position = UDim2.new(0, 20, 0, 180 * scale),
                Text = "Loading your farm" .. dots,
                TextColor3 = Color3.fromRGB(200, 200, 200),
                TextScaled = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSans
            }),
            
            -- Progress bar background
            ProgressBarBG = e("Frame", {
                Name = "ProgressBarBG",
                Size = UDim2.new(1, -60, 0, 8 * scale),
                Position = UDim2.new(0, 30, 0, 230 * scale),
                BackgroundColor3 = Color3.fromRGB(40, 45, 50),
                BorderSizePixel = 0
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 4)
                }),
                
                -- Animated progress bar
                ProgressBar = e("Frame", {
                    Name = "ProgressBar",
                    Size = UDim2.new(0.7, 0, 1, 0), -- 70% progress (fake animation)
                    Position = UDim2.new(0, 0, 0, 0),
                    BackgroundColor3 = Color3.fromRGB(100, 200, 100),
                    BorderSizePixel = 0
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 4)
                    }),
                    
                    Gradient = e("UIGradient", {
                        Color = ColorSequence.new{
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 220, 120)),
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 180, 80))
                        },
                        Rotation = 45
                    })
                })
            }),
            
            -- Loading tips
            TipText = e("TextLabel", {
                Name = "TipText",
                Size = UDim2.new(1, -40, 0, 25 * scale),
                Position = UDim2.new(0, 20, 0, 260 * scale),
                Text = "💡 Tip: Water your plants regularly to prevent them from dying!",
                TextColor3 = Color3.fromRGB(150, 150, 150),
                TextScaled = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansItalic
            })
        })
    })
end

return LoadingScreen