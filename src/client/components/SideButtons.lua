-- Side Buttons Component
-- Shows inventory and shop buttons with responsive design

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local e = React.createElement
-- Import responsive design utilities - REQUIRED for the refactored system
local ScreenUtils = require(game:GetService("ReplicatedStorage").Shared.ScreenUtils)

local function SideButtons(props)
    local onShopClick = props.onShopClick or function() end
    local onWeatherClick = props.onWeatherClick or function() end
    local onSellClick = props.onSellClick or function() end
    local onSettingsClick = props.onSettingsClick or function() end
    
    -- Responsive sizing using ScreenUtils
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local scale = ScreenUtils.getCustomScale(screenSize, 0.9, 1)
    local buttonSize = ScreenUtils.getCustomScale(screenSize, 45, 40)
    local spacing = ScreenUtils.getCustomScale(screenSize, 50, 45)
    
    return e("Frame", {
        Name = "SideButtonsFrame",
        Size = UDim2.new(0, buttonSize * scale, 0, (buttonSize + 5) * 4 * scale), -- Four buttons with spacing
        Position = UDim2.new(0, ScreenUtils.getPadding(screenSize, 15, 20), 0.5, -(buttonSize + 5) * 1.5 * scale), -- Left middle with padding
        BackgroundTransparency = 1,
        ZIndex = 10
    }, {
        Layout = e("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Top,
            Padding = UDim.new(0, 5)
        }),
        
        ShopButton = e("TextButton", {
            Name = "ShopButton",
            Size = UDim2.new(0, buttonSize * scale, 0, buttonSize * scale),
            Text = "🛒",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextScaled = true,
            BackgroundColor3 = Color3.fromRGB(160, 82, 45),
            BorderSizePixel = 0,
            Font = Enum.Font.SourceSansBold,
            ZIndex = 11,
            [React.Event.Activated] = onShopClick
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 15)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(210, 150, 100),
                Thickness = 2,
                Transparency = 0.3
            }),
            Gradient = e("UIGradient", {
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 102, 65)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 62, 25))
                },
                Rotation = 90
            })
        }),
        
        SellButton = e("TextButton", {
            Name = "SellButton",
            Size = UDim2.new(0, buttonSize * scale, 0, buttonSize * scale),
            Text = "💰",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextScaled = true,
            BackgroundColor3 = Color3.fromRGB(255, 165, 0),
            BorderSizePixel = 0,
            Font = Enum.Font.SourceSansBold,
            ZIndex = 11,
            [React.Event.Activated] = onSellClick
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 15)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(255, 215, 100),
                Thickness = 2,
                Transparency = 0.3
            }),
            Gradient = e("UIGradient", {
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 185, 20)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(235, 145, 0))
                },
                Rotation = 90
            })
        }),
        
        WeatherButton = e("TextButton", {
            Name = "WeatherButton",
            Size = UDim2.new(0, buttonSize * scale, 0, buttonSize * scale),
            Text = "🌤️",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextScaled = true,
            BackgroundColor3 = Color3.fromRGB(100, 150, 255),
            BorderSizePixel = 0,
            Font = Enum.Font.SourceSansBold,
            ZIndex = 11,
            [React.Event.Activated] = onWeatherClick
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 15)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(150, 200, 255),
                Thickness = 2,
                Transparency = 0.3
            }),
            Gradient = e("UIGradient", {
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 170, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 130, 235))
                },
                Rotation = 90
            })
        }),
        
        SettingsButton = e("TextButton", {
            Name = "SettingsButton",
            Size = UDim2.new(0, buttonSize * scale, 0, buttonSize * scale),
            Text = "⚙️",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextScaled = true,
            BackgroundColor3 = Color3.fromRGB(100, 100, 100),
            BorderSizePixel = 0,
            Font = Enum.Font.SourceSansBold,
            ZIndex = 11,
            [React.Event.Activated] = onSettingsClick
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 15)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(150, 150, 150),
                Thickness = 2,
                Transparency = 0.3
            }),
            Gradient = e("UIGradient", {
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 120, 120)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 80, 80))
                },
                Rotation = 90
            })
        })
    })
end

return SideButtons