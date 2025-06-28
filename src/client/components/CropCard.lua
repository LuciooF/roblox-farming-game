-- Crop Card Component
-- Displays individual harvested crops with emoji, name, quantity, and sell functionality

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local NumberFormatter = require(game:GetService("ReplicatedStorage").Shared.NumberFormatter)
local ScreenUtils = require(game:GetService("ReplicatedStorage").Shared.ScreenUtils)
local e = React.createElement

local function CropCard(props)
    local cropType = props.cropType
    local quantity = props.quantity or 0
    local onSell = props.onSell or function() end
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    
    local scale = ScreenUtils.getProportionalScale(screenSize)
    
    -- Crop display data (NOTE: Sell prices are calculated server-side based on rebirths, variations, etc.)
    local cropData = {
        wheat = { emoji = "🌾", basePrice = 5, color = Color3.fromRGB(255, 255, 100) },
        carrot = { emoji = "🥕", basePrice = 15, color = Color3.fromRGB(255, 140, 0) },
        tomato = { emoji = "🍅", basePrice = 35, color = Color3.fromRGB(255, 99, 71) },
        potato = { emoji = "🥔", basePrice = 25, color = Color3.fromRGB(139, 69, 19) },
        corn = { emoji = "🌽", basePrice = 80, color = Color3.fromRGB(255, 215, 0) },
        banana = { emoji = "🍌", basePrice = 150, color = Color3.fromRGB(255, 255, 0) },
        strawberry = { emoji = "🍓", basePrice = 100, color = Color3.fromRGB(255, 20, 147) },
        -- Special variations (multiply base prices)
        ["Shiny wheat"] = { emoji = "✨🌾", basePrice = 10, color = Color3.fromRGB(255, 255, 150) },
        ["Rainbow wheat"] = { emoji = "🌈🌾", basePrice = 25, color = Color3.fromRGB(255, 100, 255) },
        ["Golden wheat"] = { emoji = "💛🌾", basePrice = 50, color = Color3.fromRGB(255, 215, 0) },
        ["Diamond wheat"] = { emoji = "💎🌾", basePrice = 125, color = Color3.fromRGB(185, 242, 255) }
    }
    
    -- Fallback for unknown crops
    local crop = cropData[cropType] or { 
        emoji = "🌱", 
        basePrice = 10, 
        color = Color3.fromRGB(100, 200, 100) 
    }
    
    local totalValue = crop.basePrice * quantity
    local hasQuantity = quantity > 0
    
    return e("Frame", {
        Name = cropType:gsub("%s", "") .. "CropCard",
        Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 100), 0, ScreenUtils.getProportionalSize(screenSize, 125)),
        BackgroundColor3 = hasQuantity and Color3.fromRGB(40, 45, 50) or Color3.fromRGB(25, 25, 25),
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        ZIndex = 10
    }, {
        Corner = e("UICorner", {
            CornerRadius = UDim.new(0, 8)
        }),
        
        Stroke = e("UIStroke", {
            Color = hasQuantity and crop.color or Color3.fromRGB(80, 80, 80),
            Thickness = hasQuantity and 2 or 1,
            Transparency = hasQuantity and 0.3 or 0.7
        }),
        
        -- Emoji
        EmojiLabel = e("TextLabel", {
            Name = "Emoji",
            Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(screenSize, 30)),
            Position = UDim2.new(0, 0, 0, 5),
            Text = crop.emoji,
            TextScaled = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSansBold,
            ZIndex = 11
        }),
        
        -- Crop Name
        NameLabel = e("TextLabel", {
            Name = "CropName",
            Size = UDim2.new(1, -6, 0, ScreenUtils.getProportionalSize(screenSize, 18)),
            Position = UDim2.new(0, 3, 0, ScreenUtils.getProportionalSize(screenSize, 35)),
            Text = cropType:upper(),
            TextColor3 = hasQuantity and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(120, 120, 120),
            TextScaled = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSansBold,
            ZIndex = 11
        }),
        
        -- Quantity Badge
        QuantityBadge = quantity > 0 and e("Frame", {
            Name = "QuantityBadge",
            Size = UDim2.new(0, 25 * scale, 0, 20 * scale),
            Position = UDim2.new(1, -30 * scale, 0, 5),
            BackgroundColor3 = Color3.fromRGB(85, 255, 85),
            BorderSizePixel = 0,
            ZIndex = 12
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 10)
            }),
            QuantityText = e("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                Text = NumberFormatter.format(quantity),
                TextColor3 = Color3.fromRGB(0, 0, 0),
                TextScaled = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 13
            })
        }) or nil,
        
        -- Crop Name
        CropName = e("TextLabel", {
            Name = "CropName",
            Size = UDim2.new(1, -6, 0, 16 * scale),
            Position = UDim2.new(0, 3, 0, 55 * scale),
            Text = cropType:gsub("^%l", string.upper),
            TextColor3 = hasQuantity and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150),
            TextScaled = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSansBold,
            ZIndex = 11
        }),
        
        -- Price Per Unit
        PricePerUnit = hasQuantity and e("TextLabel", {
            Name = "PricePerUnit",
            Size = UDim2.new(1, -6, 0, 14 * scale),
            Position = UDim2.new(0, 3, 0, 72 * scale),
            Text = "$" .. NumberFormatter.format(crop.basePrice) .. " each",
            TextColor3 = Color3.fromRGB(100, 255, 100),
            TextScaled = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSans,
            ZIndex = 11
        }) or nil,
        
        -- Sell One Button
        SellOneButton = quantity > 0 and e("TextButton", {
            Name = "SellOneButton",
            Size = UDim2.new(1, -10, 0, 15 * scale),
            Position = UDim2.new(0, 5, 0, 88 * scale),
            Text = "",
            BackgroundColor3 = Color3.fromRGB(40, 120, 40),
            BorderSizePixel = 0,
            ZIndex = 12,
            [React.Event.Activated] = function()
                onSell(cropType, 1, crop.basePrice)
            end,
            [React.Event.MouseEnter] = function(gui)
                gui.BackgroundColor3 = Color3.fromRGB(50, 140, 50)
            end,
            [React.Event.MouseLeave] = function(gui)
                gui.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
            end
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 6)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(100, 255, 100),
                Thickness = 1,
                Transparency = 0.5
            }),
            Content = e("Frame", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                ZIndex = 13
            }, {
                Layout = e("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 3)
                }),
                SellText = e("TextLabel", {
                    Size = UDim2.new(0, 0, 1, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    Text = "SELL",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextScaled = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.SourceSansBold,
                    ZIndex = 14
                }, {
                    TextStroke = e("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = 2,
                        Transparency = 0.5
                    })
                }),
                CashIcon = e("ImageLabel", {
                    Size = UDim2.new(0, 12 * scale, 0, 12 * scale),
                    Image = assets["Currency/Cash/Cash Outline 256.png"] or "",
                    BackgroundTransparency = 1,
                    ScaleType = Enum.ScaleType.Fit,
                    ImageColor3 = Color3.fromRGB(255, 215, 0),
                    ZIndex = 14
                }),
                PriceText = e("TextLabel", {
                    Size = UDim2.new(0, 0, 1, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    Text = NumberFormatter.format(crop.basePrice),
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextScaled = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.SourceSansBold,
                    ZIndex = 14
                }, {
                    TextStroke = e("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = 2,
                        Transparency = 0.5
                    })
                })
            })
        }) or nil,
        
        -- Sell All Button
        SellAllButton = quantity > 0 and e("TextButton", {
            Name = "SellAllButton",
            Size = UDim2.new(1, -10, 0, 15 * scale),
            Position = UDim2.new(0, 5, 0, 105 * scale),
            Text = "",
            BackgroundColor3 = Color3.fromRGB(255, 140, 0),
            BorderSizePixel = 0,
            ZIndex = 12,
            [React.Event.Activated] = function()
                onSell(cropType, quantity, totalValue)
            end,
            [React.Event.MouseEnter] = function(gui)
                gui.BackgroundColor3 = Color3.fromRGB(255, 160, 20)
            end,
            [React.Event.MouseLeave] = function(gui)
                gui.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
            end
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 6)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(255, 200, 100),
                Thickness = 1,
                Transparency = 0.5
            }),
            Content = e("Frame", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                ZIndex = 13
            }, {
                Layout = e("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 2)
                }),
                SellAllText = e("TextLabel", {
                    Size = UDim2.new(0, 0, 1, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    Text = "SELL ALL",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextScaled = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.SourceSansBold,
                    ZIndex = 14
                }, {
                    TextStroke = e("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = 2,
                        Transparency = 0.5
                    })
                }),
                CashIcon = e("ImageLabel", {
                    Size = UDim2.new(0, 12 * scale, 0, 12 * scale),
                    Image = assets["Currency/Cash/Cash Outline 256.png"] or "",
                    BackgroundTransparency = 1,
                    ScaleType = Enum.ScaleType.Fit,
                    ImageColor3 = Color3.fromRGB(255, 215, 0),
                    ZIndex = 14
                }),
                PriceText = e("TextLabel", {
                    Size = UDim2.new(0, 0, 1, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    Text = NumberFormatter.format(totalValue),
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextScaled = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.SourceSansBold,
                    ZIndex = 14
                }, {
                    TextStroke = e("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = 2,
                        Transparency = 0.5
                    })
                })
            })
        }) or nil,
        
        -- Empty State Message
        EmptyMessage = quantity == 0 and e("TextLabel", {
            Name = "EmptyMessage",
            Size = UDim2.new(1, -10, 0, 30 * scale),
            Position = UDim2.new(0, 5, 0, 95 * scale),
            Text = "None owned",
            TextColor3 = Color3.fromRGB(120, 120, 120),
            TextScaled = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSansItalic,
            ZIndex = 11
        }) or nil
    })
end

return CropCard