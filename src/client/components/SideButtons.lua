-- Side Buttons Component
-- Shows inventory and shop buttons with responsive design

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local e = React.createElement
-- Import responsive design utilities - REQUIRED for the refactored system
local ScreenUtils = require(game:GetService("ReplicatedStorage").Shared.ScreenUtils)

local function SideButtons(props)
    local onShopClick = props.onShopClick or function() end
    local onInventoryClick = props.onInventoryClick or function() end
    local onWeatherClick = props.onWeatherClick or function() end
    local onGamepassClick = props.onGamepassClick or function() end
    local onSettingsClick = props.onSettingsClick or function() end
    local tutorialData = props.tutorialData
    
    -- Responsive sizing using ScreenUtils
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local scale = ScreenUtils.getCustomScale(screenSize, 0.9, 1)
    local buttonSize = ScreenUtils.getCustomScale(screenSize, 45, 40)
    local spacing = ScreenUtils.getCustomScale(screenSize, 50, 45)
    
    -- Check if buttons should be highlighted for tutorial
    local shouldHighlightInventory = false
    local shouldHighlightShop = false
    
    if tutorialData and tutorialData.step then
        if tutorialData.step.id == "sell_crops" then
            shouldHighlightInventory = true
        elseif tutorialData.step.id == "buy_corn" then
            shouldHighlightShop = true
        end
    end
    
    -- Create animated glow effects when highlighted
    local inventoryGlowRef = React.useRef(nil)
    local shopGlowRef = React.useRef(nil)
    
    -- Inventory glow effect
    React.useEffect(function()
        if not shouldHighlightInventory or not inventoryGlowRef.current then
            return
        end
        
        -- Create pulsing glow animation
        local function startGlowAnimation()
            local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
            local tween = TweenService:Create(inventoryGlowRef.current, tweenInfo, {
                BackgroundTransparency = 0.4,
                Size = UDim2.new(1, 30, 1, 30),
                Position = UDim2.new(0, -15, 0, -15)
            })
            tween:Play()
            return tween
        end
        
        local glowTween = startGlowAnimation()
        
        return function()
            if glowTween then
                glowTween:Cancel()
            end
        end
    end, {shouldHighlightInventory})
    
    -- Shop glow effect
    React.useEffect(function()
        if not shouldHighlightShop or not shopGlowRef.current then
            return
        end
        
        -- Create pulsing glow animation
        local function startGlowAnimation()
            local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
            local tween = TweenService:Create(shopGlowRef.current, tweenInfo, {
                BackgroundTransparency = 0.4,
                Size = UDim2.new(1, 30, 1, 30),
                Position = UDim2.new(0, -15, 0, -15)
            })
            tween:Play()
            return tween
        end
        
        local glowTween = startGlowAnimation()
        
        return function()
            if glowTween then
                glowTween:Cancel()
            end
        end
    end, {shouldHighlightShop})
    
    return e("Frame", {
        Name = "SideButtonsFrame",
        Size = UDim2.new(0, buttonSize * scale, 0, (buttonSize + 5) * 5 * scale), -- Five buttons with spacing
        Position = UDim2.new(0, ScreenUtils.getPadding(screenSize, 15, 20), 0.5, -(buttonSize + 5) * 2 * scale), -- Left middle with padding
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
            BackgroundColor3 = shouldHighlightShop and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(160, 82, 45),
            BorderSizePixel = 0,
            Font = Enum.Font.SourceSansBold,
            ZIndex = 11,
            [React.Event.Activated] = onShopClick
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 15)
            }),
            Stroke = e("UIStroke", {
                Color = shouldHighlightShop and Color3.fromRGB(255, 255, 0) or Color3.fromRGB(210, 150, 100),
                Thickness = shouldHighlightShop and 4 or 2,
                Transparency = shouldHighlightShop and 0 or 0.3
            }),
            Gradient = e("UIGradient", {
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, shouldHighlightShop and Color3.fromRGB(255, 255, 100) or Color3.fromRGB(180, 102, 65)),
                    ColorSequenceKeypoint.new(1, shouldHighlightShop and Color3.fromRGB(255, 180, 0) or Color3.fromRGB(140, 62, 25))
                },
                Rotation = 90
            }),
            -- Glowing effect when highlighted
            GlowEffect = shouldHighlightShop and e("Frame", {
                Name = "GlowEffect",
                Size = UDim2.new(1, 20, 1, 20),
                Position = UDim2.new(0, -10, 0, -10),
                BackgroundColor3 = Color3.fromRGB(255, 255, 0),
                BackgroundTransparency = 0.7,
                BorderSizePixel = 0,
                ZIndex = 10, -- Behind the button
                ref = shopGlowRef
            }, {
                GlowCorner = e("UICorner", {
                    CornerRadius = UDim.new(0, 20)
                }),
                GlowGradient = e("UIGradient", {
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 100)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 0))
                    },
                    Rotation = 90
                })
            }) or nil
        }),
        
        InventoryButton = e("TextButton", {
            Name = "InventoryButton",
            Size = UDim2.new(0, buttonSize * scale, 0, buttonSize * scale),
            Text = "🎒",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextScaled = true,
            BackgroundColor3 = shouldHighlightInventory and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(85, 85, 170),
            BorderSizePixel = 0,
            Font = Enum.Font.SourceSansBold,
            ZIndex = 11,
            [React.Event.Activated] = onInventoryClick
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 15)
            }),
            Stroke = e("UIStroke", {
                Color = shouldHighlightInventory and Color3.fromRGB(255, 255, 0) or Color3.fromRGB(120, 120, 220),
                Thickness = shouldHighlightInventory and 4 or 2,
                Transparency = shouldHighlightInventory and 0 or 0.3
            }),
            Gradient = e("UIGradient", {
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, shouldHighlightInventory and Color3.fromRGB(255, 255, 100) or Color3.fromRGB(105, 105, 190)),
                    ColorSequenceKeypoint.new(1, shouldHighlightInventory and Color3.fromRGB(255, 180, 0) or Color3.fromRGB(65, 65, 150))
                },
                Rotation = 90
            }),
            -- Glowing effect when highlighted
            GlowEffect = shouldHighlightInventory and e("Frame", {
                Name = "GlowEffect",
                Size = UDim2.new(1, 20, 1, 20),
                Position = UDim2.new(0, -10, 0, -10),
                BackgroundColor3 = Color3.fromRGB(255, 255, 0),
                BackgroundTransparency = 0.7,
                BorderSizePixel = 0,
                ZIndex = 10, -- Behind the button
                ref = inventoryGlowRef
            }, {
                GlowCorner = e("UICorner", {
                    CornerRadius = UDim.new(0, 20)
                }),
                GlowGradient = e("UIGradient", {
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 100)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 0))
                    },
                    Rotation = 90
                })
            }) or nil
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
        
        GamepassButton = e("TextButton", {
            Name = "GamepassButton",
            Size = UDim2.new(0, buttonSize * scale, 0, buttonSize * scale),
            Text = "🚀",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextScaled = true,
            BackgroundColor3 = Color3.fromRGB(255, 140, 0),
            BorderSizePixel = 0,
            Font = Enum.Font.SourceSansBold,
            ZIndex = 11,
            [React.Event.Activated] = onGamepassClick
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 15)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(255, 200, 100),
                Thickness = 2,
                Transparency = 0.3
            }),
            Gradient = e("UIGradient", {
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 160, 20)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 120, 0))
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