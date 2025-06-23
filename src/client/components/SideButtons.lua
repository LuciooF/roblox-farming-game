-- Side Buttons Component
-- Shows inventory and shop buttons with responsive design

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local e = React.createElement

local function SideButtons(props)
    local onShopClick = props.onShopClick or function() end
    
    -- Responsive sizing
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local isMobile = screenSize.X < 768
    local scale = isMobile and 0.9 or 1
    local buttonSize = isMobile and 45 or 40
    local spacing = isMobile and 50 or 45
    
    return e("Frame", {
        Name = "ShopFrame",
        Size = UDim2.new(0, buttonSize * scale, 0, buttonSize * scale),
        Position = UDim2.new(0, isMobile and 5 or 10, 0, isMobile and 80 or 60),
        BackgroundTransparency = 1,
        ZIndex = 10
    }, {
        ShopButton = e("TextButton", {
            Name = "ShopButton",
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
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
                CornerRadius = UDim.new(0, 8)
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
        })
    })
end

return SideButtons