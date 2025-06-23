-- Premium Panel Component
-- Shows premium automation features with responsive design

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local e = React.createElement

local function PremiumPanel(props)
    local playerData = props.playerData or {}
    local visible = props.visible or false
    local onClose = props.onClose or function() end
    local onTogglePremium = props.onTogglePremium or function() end
    
    -- Responsive sizing
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local isMobile = screenSize.X < 768
    local scale = isMobile and 0.85 or 1
    local panelWidth = isMobile and 320 or 300
    local panelHeight = isMobile and 240 or 220
    
    -- Check if player has premium (simplified for testing)
    local hasPremium = playerData.gamepasses and playerData.gamepasses.autoPlant or false
    
    return e("Frame", {
        Name = "PremiumPanel",
        Size = UDim2.new(0, panelWidth * scale, 0, panelHeight * scale),
        Position = UDim2.new(0, (isMobile and 55 or 60) * scale, 0, (isMobile and 180 or 160) * scale),
        BackgroundColor3 = Color3.fromRGB(40, 30, 0),
        BackgroundTransparency = visible and 0.05 or 1,
        BorderSizePixel = 0,
        Visible = visible,
        ZIndex = 12
    }, {
        Corner = e("UICorner", {
            CornerRadius = UDim.new(0, 12)
        }),
        Stroke = e("UIStroke", {
            Color = Color3.fromRGB(255, 215, 0),
            Thickness = 2,
            Transparency = 0.3
        }),
        Gradient = e("UIGradient", {
            Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 45, 0)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 30, 0))
            },
            Rotation = 90
        }),
        
        -- Close Button
        CloseButton = e("TextButton", {
            Name = "CloseButton",
            Size = UDim2.new(0, 25, 0, 25),
            Position = UDim2.new(1, -30, 0, 5),
            Text = "✖",
            TextColor3 = Color3.fromRGB(255, 100, 100),
            TextScaled = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSansBold,
            ZIndex = 14,
            [React.Event.Activated] = onClose
        }),
        
        -- Title
        Title = e("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, -40, 0, 30),
            Position = UDim2.new(0, 15, 0, 8),
            Text = "👑 Premium Automation",
            TextColor3 = Color3.fromRGB(255, 215, 0),
            TextScaled = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSansBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 13
        }),
        
        -- Description
        Description = e("TextLabel", {
            Name = "Description",
            Size = UDim2.new(1, -30, 0, 80),
            Position = UDim2.new(0, 15, 0, 45),
            Text = "🔥 Testing Mode - Toggle Premium!\\n\\n✨ Features:\\n🤖 Plant all empty plots automatically\\n🌾 Harvest all ready crops at once\\n🚀 Use the AutoBot NPC on the far left",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextScaled = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSans,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            ZIndex = 13
        }),
        
        -- Status
        StatusLabel = e("TextLabel", {
            Name = "StatusLabel",
            Size = UDim2.new(1, -30, 0, 25),
            Position = UDim2.new(0, 15, 0, 135),
            Text = "Current Status: " .. (hasPremium and "🟢 ACTIVE" or "🔴 INACTIVE"),
            TextColor3 = hasPremium and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100),
            TextScaled = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSansBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 13
        }),
        
        -- Toggle Button
        ToggleButton = e("TextButton", {
            Name = "ToggleButton",
            Size = UDim2.new(1, -30, 0, 35),
            Position = UDim2.new(0, 15, 0, 170),
            Text = hasPremium and "🔴 Disable Premium" or "🟢 Enable Premium",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextScaled = true,
            BackgroundColor3 = hasPremium and Color3.fromRGB(220, 60, 60) or Color3.fromRGB(60, 220, 60),
            BorderSizePixel = 0,
            Font = Enum.Font.SourceSansBold,
            ZIndex = 14,
            [React.Event.Activated] = onTogglePremium
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 8)
            }),
            Stroke = e("UIStroke", {
                Color = hasPremium and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 255, 100),
                Thickness = 2,
                Transparency = 0.3
            }),
            Gradient = e("UIGradient", {
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, hasPremium and Color3.fromRGB(240, 80, 80) or Color3.fromRGB(80, 240, 80)),
                    ColorSequenceKeypoint.new(1, hasPremium and Color3.fromRGB(200, 40, 40) or Color3.fromRGB(40, 200, 40))
                },
                Rotation = 90
            })
        })
    })
end

return PremiumPanel