-- Top Stats Component
-- Shows money and rebirths with emojis and responsive design

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local e = React.createElement
local NumberFormatter = require(game:GetService("ReplicatedStorage").Shared.NumberFormatter)

local function TopStats(props)
    local playerData = props.playerData or {}
    local onRebirthClick = props.onRebirthClick or function() end
    
    -- Check if data is loading
    local isLoading = playerData.loading
    
    -- Calculate rebirth requirements
    local moneyRequired = math.floor(1000 * (2.5 ^ (playerData.rebirths or 0)))
    local canRebirth = (playerData.money or 0) >= moneyRequired
    local multiplier = 1 + ((playerData.rebirths or 0) * 0.5)
    
    -- Responsive sizing based on screen size
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local isMobile = screenSize.X < 768
    local scale = isMobile and 0.8 or 1
    
    return e("Frame", {
        Name = "TopStatsFrame",
        Size = UDim2.new(0, 220 * scale, 0, 40 * scale),
        Position = UDim2.new(0.5, -110 * scale, 0, 10),
        BackgroundTransparency = 1,
        ZIndex = 10
    }, {
        -- Money Display
        MoneyButton = e("TextButton", {
            Name = "MoneyButton",
            Size = UDim2.new(0, 100 * scale, 0, 35 * scale),
            Position = UDim2.new(0, 0, 0, 0),
            Text = isLoading and "💰 Loading..." or "💰 $" .. NumberFormatter.format(playerData.money or 0),
            TextColor3 = Color3.fromRGB(85, 255, 85),
            TextScaled = true,
            BackgroundColor3 = Color3.fromRGB(40, 40, 40),
            BackgroundTransparency = 0.1,
            BorderSizePixel = 0,
            Font = Enum.Font.SourceSansBold,
            ZIndex = 11
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 8)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(85, 255, 85),
                Thickness = 2,
                Transparency = 0.3
            }),
            Padding = e("UIPadding", {
                PaddingLeft = UDim.new(0, 4),
                PaddingRight = UDim.new(0, 4),
                PaddingTop = UDim.new(0, 2),
                PaddingBottom = UDim.new(0, 2)
            })
        }),
        
        -- Rebirth Display
        RebirthButton = e("TextButton", {
            Name = "RebirthButton",
            Size = UDim2.new(0, 110 * scale, 0, 35 * scale),
            Position = UDim2.new(0, 110 * scale, 0, 0),
            Text = isLoading and "⭐ ..." or "⭐ " .. (playerData.rebirths or 0),
            TextColor3 = canRebirth and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200),
            TextScaled = true,
            BackgroundColor3 = canRebirth and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(60, 60, 60),
            BackgroundTransparency = 0.1,
            BorderSizePixel = 0,
            Font = Enum.Font.SourceSansBold,
            ZIndex = 11,
            [React.Event.Activated] = onRebirthClick,
            [React.Event.MouseEnter] = function(rbx)
                -- Show tooltip
                local tooltip = rbx.Parent:FindFirstChild("RebirthTooltip")
                if tooltip then
                    tooltip.Visible = true
                end
            end,
            [React.Event.MouseLeave] = function(rbx)
                -- Hide tooltip
                local tooltip = rbx.Parent:FindFirstChild("RebirthTooltip")
                if tooltip then
                    tooltip.Visible = false
                end
            end
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 8)
            }),
            Stroke = e("UIStroke", {
                Color = canRebirth and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(100, 100, 100),
                Thickness = 2,
                Transparency = 0.3
            }),
            Padding = e("UIPadding", {
                PaddingLeft = UDim.new(0, 4),
                PaddingRight = UDim.new(0, 4),
                PaddingTop = UDim.new(0, 2),
                PaddingBottom = UDim.new(0, 2)
            })
        }),
        
        -- Rebirth Tooltip
        RebirthTooltip = e("Frame", {
            Name = "RebirthTooltip",
            Size = UDim2.new(0, 200 * scale, 0, 60 * scale),
            Position = UDim2.new(0, 120 * scale, 0, 40 * scale),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 0.1,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 15
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 8)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(255, 215, 0),
                Thickness = 1,
                Transparency = 0.5
            }),
            TooltipLabel = e("TextLabel", {
                Name = "TooltipLabel",
                Size = UDim2.new(1, -10, 1, -5),
                Position = UDim2.new(0, 5, 0, 2),
                Text = isLoading and "Loading..." or "Current: " .. multiplier .. "x multiplier\nNext rebirth: $" .. NumberFormatter.format(moneyRequired),
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSans,
                ZIndex = 16
            })
        })
    })
end

return TopStats