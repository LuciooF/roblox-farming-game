-- Shop Seed Card Component
-- Displays shop seed with info button and buy button

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local NumberFormatter = require(game:GetService("ReplicatedStorage").Shared.NumberFormatter)
local CropRegistry = require(game:GetService("ReplicatedStorage").Shared.CropRegistry)
local ScreenUtils = require(game:GetService("ReplicatedStorage").Shared.ScreenUtils)
local e = React.createElement

local function ShopSeedCard(props)
    local seedType = props.seedType
    local price = props.price or 0
    local onInfo = props.onInfo or function() end
    local onBuy = props.onBuy or function() end
    local playerMoney = props.playerMoney or 0
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    
    local scale = ScreenUtils.getProportionalScale(screenSize)
    
    -- Get crop data from registry
    local cropData = CropRegistry.getCrop(seedType)
    
    local emoji = cropData and cropData.emoji or "🌱"
    local color = cropData and cropData.color or Color3.fromRGB(100, 200, 100)
    local assetId = cropData and cropData.assetId
    local cropName = cropData and cropData.name or seedType
    local rarity = cropData and cropData.rarity or "common"
    local canAfford = playerMoney >= price
    
    -- Rarity border colors
    local rarityColors = {
        common = Color3.fromRGB(150, 150, 150),
        uncommon = Color3.fromRGB(100, 255, 100), 
        rare = Color3.fromRGB(100, 100, 255),
        epic = Color3.fromRGB(255, 100, 255),
        legendary = Color3.fromRGB(255, 215, 0)
    }
    local borderColor = rarityColors[rarity] or rarityColors.common
    
    return e("Frame", {
        Name = seedType .. "ShopCard",
        Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 100), 0, ScreenUtils.getProportionalSize(screenSize, 140)),
        BackgroundColor3 = canAfford and Color3.fromRGB(40, 45, 50) or Color3.fromRGB(25, 25, 25),
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        ZIndex = 10
    }, {
        Corner = e("UICorner", {
            CornerRadius = UDim.new(0, 8)
        }),
        
        Stroke = e("UIStroke", {
            Color = canAfford and borderColor or Color3.fromRGB(80, 80, 80),
            Thickness = canAfford and 3 or 1,
            Transparency = canAfford and 0.2 or 0.7
        }),
        
        -- Icon (Asset icon if available, otherwise emoji)
        IconContainer = assetId and e("ImageLabel", {
            Name = "CropIcon",
            Size = UDim2.new(0, 35 * scale, 0, 35 * scale),
            Position = UDim2.new(0.5, -17.5 * scale, 0, 3),
            Image = assetId,
            BackgroundTransparency = 1,
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 11
        }) or e("TextLabel", {
            Name = "Emoji",
            Size = UDim2.new(1, 0, 0, 30 * scale),
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
            Size = UDim2.new(1, -6, 0, 20 * scale),
            Position = UDim2.new(0, 3, 0, 35 * scale),
            Text = cropName,
            TextColor3 = canAfford and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(120, 120, 120),
            TextScaled = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSansBold,
            ZIndex = 11
        }),
        
        -- Price
        PriceLabel = e("TextLabel", {
            Name = "Price",
            Size = UDim2.new(1, -6, 0, 18 * scale),
            Position = UDim2.new(0, 3, 0, 55 * scale),
            Text = "$" .. NumberFormatter.format(price),
            TextColor3 = canAfford and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 150, 150),
            TextScaled = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSans,
            ZIndex = 11
        }),
        
        -- Info Button
        InfoButton = e("TextButton", {
            Name = "InfoButton",
            Size = UDim2.new(0, 40 * scale, 0, 20 * scale),
            Position = UDim2.new(0, 5, 0, 75 * scale),
            Text = "ℹ️ Info",
            TextColor3 = Color3.fromRGB(150, 200, 255),
            TextScaled = true,
            BackgroundColor3 = Color3.fromRGB(30, 50, 70),
            BorderSizePixel = 0,
            Font = Enum.Font.SourceSans,
            ZIndex = 12,
            [React.Event.Activated] = function()
                onInfo(seedType)
            end
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 4)
            })
        }),
        
        -- Buy Button  
        BuyButton = e("TextButton", {
            Name = "BuyButton",
            Size = UDim2.new(0, 45 * scale, 0, 20 * scale),
            Position = UDim2.new(1, -50 * scale, 0, 75 * scale),
            Text = "💰 $" .. NumberFormatter.format(price),
            TextColor3 = canAfford and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(255, 150, 150),
            TextScaled = true,
            BackgroundColor3 = canAfford and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(60, 30, 30),
            BorderSizePixel = 0,
            Font = Enum.Font.SourceSansBold,
            ZIndex = 12,
            [React.Event.Activated] = function()
                if canAfford then
                    onBuy(seedType, price)
                end
            end
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 4)
            })
        }),
        
        -- Status Label
        StatusLabel = e("TextLabel", {
            Name = "StatusLabel",
            Size = UDim2.new(1, -6, 0, 15 * scale),
            Position = UDim2.new(0, 3, 0, 100 * scale),
            Text = canAfford and "✅ Available" or "❌ Can't afford",
            TextColor3 = canAfford and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 150, 150),
            TextScaled = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSans,
            ZIndex = 11
        }),
        
        -- Unavailable Overlay
        UnavailableOverlay = not canAfford and e("Frame", {
            Name = "UnavailableOverlay",
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 0.7,
            BorderSizePixel = 0,
            ZIndex = 14
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 8)
            })
        }) or nil
    })
end

return ShopSeedCard