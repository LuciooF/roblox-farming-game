-- Seed Card Component
-- Displays individual seed with emoji, name, price, and quantity

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local e = React.createElement

local function SeedCard(props)
    local seedType = props.seedType
    local quantity = props.quantity or 0
    local price = props.price or 0
    local onClick = props.onClick or function() end
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    
    local isMobile = screenSize.X < 768
    local scale = isMobile and 0.8 or 1
    
    -- Seed emojis
    local seedEmojis = {
        wheat = "🌾",
        tomato = "🍅", 
        carrot = "🥕",
        potato = "🥔",
        corn = "🌽"
    }
    
    -- Seed colors
    local seedColors = {
        wheat = Color3.fromRGB(255, 215, 0),
        tomato = Color3.fromRGB(255, 99, 71),
        carrot = Color3.fromRGB(255, 140, 0),
        potato = Color3.fromRGB(139, 69, 19),
        corn = Color3.fromRGB(255, 255, 0)
    }
    
    local emoji = seedEmojis[seedType] or "🌱"
    local color = seedColors[seedType] or Color3.fromRGB(100, 200, 100)
    local isAvailable = quantity > 0
    
    return e("TextButton", {
        Name = seedType .. "Card",
        Size = UDim2.new(0, 100 * scale, 0, 120 * scale),
        BackgroundColor3 = isAvailable and Color3.fromRGB(40, 45, 50) or Color3.fromRGB(25, 25, 25),
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        ZIndex = 10,
        [React.Event.Activated] = function()
            onClick(seedType)
        end,
        [React.Event.MouseEnter] = function(gui)
            -- Hover effect
            gui.BackgroundColor3 = isAvailable and Color3.fromRGB(50, 55, 60) or Color3.fromRGB(35, 35, 35)
        end,
        [React.Event.MouseLeave] = function(gui)
            gui.BackgroundColor3 = isAvailable and Color3.fromRGB(40, 45, 50) or Color3.fromRGB(25, 25, 25)
        end
    }, {
        Corner = e("UICorner", {
            CornerRadius = UDim.new(0, 8)
        }),
        
        Stroke = e("UIStroke", {
            Color = isAvailable and color or Color3.fromRGB(80, 80, 80),
            Thickness = isAvailable and 2 or 1,
            Transparency = isAvailable and 0.3 or 0.7
        }),
        
        -- Emoji
        EmojiLabel = e("TextLabel", {
            Name = "Emoji",
            Size = UDim2.new(1, 0, 0, 40 * scale),
            Position = UDim2.new(0, 0, 0, 5),
            Text = emoji,
            TextScaled = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSansBold,
            ZIndex = 11
        }),
        
        -- Seed Name
        NameLabel = e("TextLabel", {
            Name = "SeedName",
            Size = UDim2.new(1, -6, 0, 25 * scale),
            Position = UDim2.new(0, 3, 0, 45 * scale),
            Text = seedType:upper(),
            TextColor3 = isAvailable and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(120, 120, 120),
            TextScaled = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSansBold,
            ZIndex = 11
        }),
        
        -- Price
        PriceLabel = e("TextLabel", {
            Name = "Price",
            Size = UDim2.new(1, -6, 0, 20 * scale),
            Position = UDim2.new(0, 3, 0, 70 * scale),
            Text = "$" .. price,
            TextColor3 = Color3.fromRGB(100, 255, 100),
            TextScaled = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSans,
            ZIndex = 11
        }),
        
        -- Quantity Badge
        QuantityBadge = quantity > 0 and e("Frame", {
            Name = "QuantityBadge",
            Size = UDim2.new(0, 25 * scale, 0, 25 * scale),
            Position = UDim2.new(1, -30 * scale, 0, 5),
            BackgroundColor3 = Color3.fromRGB(255, 100, 100),
            BorderSizePixel = 0,
            ZIndex = 12
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0.5, 0)
            }),
            
            QuantityText = e("TextLabel", {
                Name = "QuantityText",
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                Text = tostring(quantity),
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 13
            })
        }) or nil,
        
        -- Unavailable Overlay
        UnavailableOverlay = not isAvailable and e("Frame", {
            Name = "UnavailableOverlay",
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
            ZIndex = 14
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 8)
            }),
            
            OutOfStockText = e("TextLabel", {
                Name = "OutOfStock",
                Size = UDim2.new(1, 0, 0, 30),
                Position = UDim2.new(0, 0, 0.5, -15),
                Text = "OUT OF STOCK",
                TextColor3 = Color3.fromRGB(255, 100, 100),
                TextScaled = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 15
            })
        }) or nil
    })
end

return SeedCard