-- Side Buttons Component
-- Modern 6-button design inspired by reference with clean styling

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local e = React.createElement
-- Import responsive design utilities - REQUIRED for the refactored system
local ScreenUtils = require(game:GetService("ReplicatedStorage").Shared.ScreenUtils)
local assets = require(game:GetService("ReplicatedStorage").Shared.assets)

-- Sound IDs for button interactions
local HOVER_SOUND_ID = "rbxassetid://15675059323"
local CLICK_SOUND_ID = "rbxassetid://6324790483"

-- Pre-create sounds for better performance
local hoverSound = Instance.new("Sound")
hoverSound.SoundId = HOVER_SOUND_ID
hoverSound.Volume = 0.3
hoverSound.Parent = SoundService

local clickSound = Instance.new("Sound")
clickSound.SoundId = CLICK_SOUND_ID
clickSound.Volume = 0.4
clickSound.Parent = SoundService

-- Function to play sound effects (much faster now)
local function playSound(soundType)
    if soundType == "hover" and hoverSound then
        hoverSound:Play()
    elseif soundType == "click" and clickSound then
        clickSound:Play()
    end
end

-- Function to create icon spin animation with anti-stacking
local function createIconSpin(iconRef, animationTracker)
    if not iconRef.current then return end
    
    -- Cancel any existing animation for this icon
    if animationTracker.current then
        animationTracker.current:Cancel()
        animationTracker.current:Destroy()
    end
    
    -- Reset rotation to 0 to prevent accumulation
    iconRef.current.Rotation = 0
    
    -- Create new animation
    local spinTween = TweenService:Create(iconRef.current,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Rotation = 360}
    )
    
    -- Store reference to current animation
    animationTracker.current = spinTween
    
    spinTween:Play()
    spinTween.Completed:Connect(function()
        -- Reset rotation after animation
        if iconRef.current then
            iconRef.current.Rotation = 0
        end
        -- Clear the tracker
        if animationTracker.current == spinTween then
            animationTracker.current = nil
        end
        spinTween:Destroy()
    end)
end

local function SideButtons(props)
    local onShopClick = props.onShopClick or function() end
    local onInventoryClick = props.onInventoryClick or function() end
    local onWeatherClick = props.onWeatherClick or function() end
    local onGamepassClick = props.onGamepassClick or function() end
    local onRankClick = props.onRankClick or function() end
    local onPetsClick = props.onPetsClick or function() end
    local onRebirthClick = props.onRebirthClick or function() end
    local tutorialData = props.tutorialData
    
    -- Responsive sizing using ScreenUtils
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local isMobile = screenSize.X < 768
    local scale = ScreenUtils.getCustomScale(screenSize, 0.9, 1)
    
    -- Mobile-specific sizing
    local buttonSize = isMobile and 35 * scale or 40 * scale -- Smaller on mobile
    local iconSize = isMobile and 20 * scale or 24 * scale -- Smaller icons on mobile
    local spacing = isMobile and 8 * scale or 10 * scale -- Tighter spacing on mobile
    
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
    
    -- Icon refs for spin animations
    local shopIconRef = React.useRef(nil)
    local inventoryIconRef = React.useRef(nil)
    local weatherIconRef = React.useRef(nil)
    local gamepassIconRef = React.useRef(nil)
    local rebirthIconRef = React.useRef(nil)
    local petsIconRef = React.useRef(nil)
    local petsSoonTextRef = React.useRef(nil)
    
    -- Animation trackers to prevent stacking
    local shopAnimTracker = React.useRef(nil)
    local inventoryAnimTracker = React.useRef(nil)
    local weatherAnimTracker = React.useRef(nil)
    local gamepassAnimTracker = React.useRef(nil)
    local rebirthAnimTracker = React.useRef(nil)
    local petsAnimTracker = React.useRef(nil)
    
    -- Bouncing animation for both icon and text + rainbow color cycling
    React.useEffect(function()
        
        local function startBounceAnimation()
            if petsSoonTextRef.current and petsIconRef.current then
                -- Bounce animation for text
                local textBounce = TweenService:Create(petsSoonTextRef.current,
                    TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                    {Position = UDim2.new(0.5, 0, 0.5, -22)}
                )
                
                -- Bounce animation for icon (smaller bounce)
                local iconBounce = TweenService:Create(petsIconRef.current,
                    TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                    {Position = UDim2.new(0.5, -iconSize/2, 0.5, -iconSize/2 - 3)}
                )
                
                textBounce:Play()
                iconBounce:Play()
                
                return {textBounce, iconBounce}
            end
        end
        
        local function startRainbowAnimation()
            if petsSoonTextRef.current then
                -- Bright, high-contrast colors for visibility
                local rainbowColors = {
                    Color3.fromRGB(255, 50, 50),   -- Bright Red
                    Color3.fromRGB(255, 150, 0),   -- Bright Orange
                    Color3.fromRGB(255, 255, 0),   -- Bright Yellow
                    Color3.fromRGB(0, 255, 100),   -- Bright Green
                    Color3.fromRGB(0, 255, 255),   -- Bright Cyan
                    Color3.fromRGB(255, 100, 255), -- Bright Magenta
                }
                
                local function cycleColors(colorIndex)
                    if not petsSoonTextRef.current then return end
                    
                    local nextIndex = (colorIndex % #rainbowColors) + 1
                    local colorTween = TweenService:Create(petsSoonTextRef.current,
                        TweenInfo.new(0.5, Enum.EasingStyle.Linear),
                        {TextColor3 = rainbowColors[nextIndex]}
                    )
                    
                    colorTween:Play()
                    colorTween.Completed:Connect(function()
                        colorTween:Destroy()
                        cycleColors(nextIndex)
                    end)
                end
                
                -- Start the cycle
                cycleColors(1)
            end
        end
        
        local bounceAnimations = startBounceAnimation()
        startRainbowAnimation()
        
        return function()
            if bounceAnimations then
                for _, anim in ipairs(bounceAnimations) do
                    if anim then
                        anim:Cancel()
                        anim:Destroy()
                    end
                end
            end
            -- Color animations will clean up automatically when component unmounts
        end
    end, {})
    
    -- Inventory glow effect
    React.useEffect(function()
        if not shouldHighlightInventory or not inventoryGlowRef.current then
            -- If we're not highlighting, make sure any existing tween is cancelled
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
        
        -- Cleanup function to cancel tween
        return function()
            if glowTween then
                glowTween:Cancel()
                glowTween:Destroy()
                glowTween = nil
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
        
        -- Cleanup function to cancel tween
        return function()
            if glowTween then
                glowTween:Cancel()
                glowTween:Destroy()
                glowTween = nil
            end
        end
    end, {shouldHighlightShop})
    
    return e("Frame", {
        Name = "SideButtonsFrame",
        Size = isMobile and 
            UDim2.new(0, (2 * buttonSize) + spacing, 0, (3 * buttonSize) + (2 * spacing)) or -- 2x3 grid on mobile
            UDim2.new(0, buttonSize, 0, (6 * buttonSize) + (5 * spacing)), -- 1x6 column on desktop
        Position = isMobile and 
            UDim2.new(1, -((2 * buttonSize) + spacing + 15 * scale), 0, 80 * scale) or -- Top-right on mobile, away from thumbstick completely
            UDim2.new(0, 20 * scale, 0.5, -((6 * buttonSize) + (5 * spacing))/2), -- Left-center on desktop
        BackgroundTransparency = 1,
        ZIndex = 10
    }, {
        Layout = isMobile and e("UIGridLayout", {
            CellSize = UDim2.new(0, buttonSize, 0, buttonSize),
            CellPadding = UDim2.new(0, spacing, 0, spacing),
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Top,
            SortOrder = Enum.SortOrder.LayoutOrder
        }) or e("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Top,
            Padding = UDim.new(0, spacing),
            SortOrder = Enum.SortOrder.LayoutOrder
        }),
        
        -- Shop Button
        ShopButton = e("TextButton", {
            Name = "ShopButton",
            Size = UDim2.new(0, buttonSize, 0, buttonSize),
            Text = "",
            BackgroundColor3 = shouldHighlightShop and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = 11,
            LayoutOrder = 1,
            [React.Event.Activated] = function()
                playSound("click")
                createIconSpin(shopIconRef, shopAnimTracker)
                onShopClick()
            end,
            [React.Event.MouseEnter] = function()
                playSound("hover")
                createIconSpin(shopIconRef, shopAnimTracker)
            end
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0.5, 0)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = shouldHighlightShop and 3 or 2,
                Transparency = 0,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            }),
            Icon = e("ImageLabel", {
                Name = "ShopIcon",
                Size = UDim2.new(0, iconSize, 0, iconSize),
                Position = UDim2.new(0.5, -iconSize/2, 0.5, -iconSize/2),
                Image = assets["Plus/Plus Outline 64.png"],
                ScaleType = Enum.ScaleType.Fit,
                BackgroundTransparency = 1,
                ZIndex = 12,
                ref = shopIconRef
            })
        }),
        
        -- Inventory Button
        InventoryButton = e("TextButton", {
            Name = "InventoryButton",
            Size = UDim2.new(0, buttonSize, 0, buttonSize),
            Text = "",
            BackgroundColor3 = shouldHighlightInventory and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = 11,
            LayoutOrder = 2,
            [React.Event.Activated] = function()
                playSound("click")
                createIconSpin(inventoryIconRef, inventoryAnimTracker)
                onInventoryClick()
            end,
            [React.Event.MouseEnter] = function()
                playSound("hover")
                createIconSpin(inventoryIconRef, inventoryAnimTracker)
            end
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0.5, 0)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = shouldHighlightInventory and 3 or 2,
                Transparency = 0,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            }),
            Icon = e("ImageLabel", {
                Name = "InventoryIcon",
                Size = UDim2.new(0, iconSize, 0, iconSize),
                Position = UDim2.new(0.5, -iconSize/2, 0.5, -iconSize/2),
                Image = assets["Hamburger Menu/Hamburger Menu Outline 64.png"],
                ScaleType = Enum.ScaleType.Fit,
                BackgroundTransparency = 1,
                ZIndex = 12,
                ref = inventoryIconRef
            })
        }),
        
        -- Weather Button
        WeatherButton = e("TextButton", {
            Name = "WeatherButton",
            Size = UDim2.new(0, buttonSize, 0, buttonSize),
            Text = "",
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = 11,
            LayoutOrder = 3,
            [React.Event.Activated] = function()
                playSound("click")
                createIconSpin(weatherIconRef, weatherAnimTracker)
                onWeatherClick()
            end,
            [React.Event.MouseEnter] = function()
                playSound("hover")
                createIconSpin(weatherIconRef, weatherAnimTracker)
            end
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0.5, 0)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 2,
                Transparency = 0,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            }),
            Icon = e("ImageLabel", {
                Name = "WeatherIcon",
                Size = UDim2.new(0, iconSize, 0, iconSize),
                Position = UDim2.new(0.5, -iconSize/2, 0.5, -iconSize/2),
                Image = assets["Calendar/Calendar Outline 256.png"],
                ScaleType = Enum.ScaleType.Fit,
                BackgroundTransparency = 1,
                ZIndex = 12,
                ref = weatherIconRef
            })
        }),
        
        -- Gamepass Button
        GamepassButton = e("TextButton", {
            Name = "GamepassButton",
            Size = UDim2.new(0, buttonSize, 0, buttonSize),
            Text = "",
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = 11,
            LayoutOrder = 4,
            [React.Event.Activated] = function()
                playSound("click")
                createIconSpin(gamepassIconRef, gamepassAnimTracker)
                onGamepassClick()
            end,
            [React.Event.MouseEnter] = function()
                playSound("hover")
                createIconSpin(gamepassIconRef, gamepassAnimTracker)
            end
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0.5, 0)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 2,
                Transparency = 0,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            }),
            Icon = e("ImageLabel", {
                Name = "GamepassIcon",
                Size = UDim2.new(0, iconSize, 0, iconSize),
                Position = UDim2.new(0.5, -iconSize/2, 0.5, -iconSize/2),
                Image = assets["Premium/Premium Outline 64.png"],
                ScaleType = Enum.ScaleType.Fit,
                BackgroundTransparency = 1,
                ZIndex = 12,
                ref = gamepassIconRef
            })
        }),
        
        -- Rebirth Button
        RebirthButton = e("TextButton", {
            Name = "RebirthButton",
            Size = UDim2.new(0, buttonSize, 0, buttonSize),
            Text = "",
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = 11,
            LayoutOrder = 5,
            [React.Event.Activated] = function()
                playSound("click")
                createIconSpin(rebirthIconRef, rebirthAnimTracker)
                onRebirthClick()
            end,
            [React.Event.MouseEnter] = function()
                playSound("hover")
                createIconSpin(rebirthIconRef, rebirthAnimTracker)
            end
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0.5, 0)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 2,
                Transparency = 0,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            }),
            Icon = e("ImageLabel", {
                Name = "RebirthIcon",
                Size = UDim2.new(0, iconSize, 0, iconSize),
                Position = UDim2.new(0.5, -iconSize/2, 0.5, -iconSize/2),
                Image = assets["General/Rebirth/Rebirth Outline 64.png"],
                ScaleType = Enum.ScaleType.Fit,
                BackgroundTransparency = 1,
                ZIndex = 12,
                ref = rebirthIconRef
            })
        }),
        
        -- Rank Button
        RankButton = e("TextButton", {
            Name = "RankButton",
            Size = UDim2.new(0, buttonSize, 0, buttonSize),
            Text = "",
            BackgroundColor3 = Color3.fromRGB(255, 215, 0), -- Gold color for rank
            BorderSizePixel = 0,
            ZIndex = 11,
            LayoutOrder = 6,
            [React.Event.Activated] = function()
                playSound("click")
                onRankClick()
            end,
            [React.Event.MouseEnter] = function()
                playSound("hover")
            end
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 12)
            }),
            Shadow = e("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 3,
                Transparency = 0,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            }),
            Icon = e("TextLabel", {
                Name = "RankIcon",
                Size = UDim2.new(0, iconSize, 0, iconSize),
                Position = UDim2.new(0.5, -iconSize/2, 0.5, -iconSize/2),
                Text = "🏆", -- Crown/trophy emoji for ranks
                TextScaled = true,
                Font = Enum.Font.SourceSansBold,
                BackgroundTransparency = 1,
                ZIndex = 12
            })
        }),
        
        -- Pets Button (Secret Debug Access!)
        PetsButton = e("TextButton", {
            Name = "PetsButton",
            Size = UDim2.new(0, buttonSize, 0, buttonSize),
            Text = "",
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = 11,
            LayoutOrder = 7,
            [React.Event.Activated] = function()
                playSound("click")
                createIconSpin(petsIconRef, petsAnimTracker)
                onPetsClick()
            end,
            [React.Event.MouseEnter] = function()
                playSound("hover")
                createIconSpin(petsIconRef, petsAnimTracker)
            end
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0.5, 0)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 2,
                Transparency = 0,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            }),
            Icon = e("ImageLabel", {
                Name = "PetsIcon",
                Size = UDim2.new(0, iconSize, 0, iconSize),
                Position = UDim2.new(0.5, -iconSize/2, 0.5, -iconSize/2),
                Image = assets["General/Paw/Paw Outline 256.png"],
                ScaleType = Enum.ScaleType.Fit,
                BackgroundTransparency = 1,
                ZIndex = 12,
                ref = petsIconRef
            }),
            -- Main text with double stroke (simpler approach)
            SoonText = e("TextLabel", {
                Name = "SoonText",
                Size = UDim2.new(0, 40, 0, 12),
                Position = UDim2.new(0.5, 0, 0.5, -18), -- Position inside the button, above center
                AnchorPoint = Vector2.new(0.5, 0.5),
                Text = "SOON!",
                TextColor3 = Color3.fromRGB(255, 50, 50), -- Will be animated to rainbow
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0), -- Black stroke
                TextStrokeTransparency = 0, -- Solid black stroke
                TextScaled = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Rotation = -15, -- Tilted text
                ZIndex = 13,
                ref = petsSoonTextRef
            }, {
                TextSizeConstraint = e("UITextSizeConstraint", {
                    MaxTextSize = 10,
                    MinTextSize = 6
                })
            })
        })
    })
end

return SideButtons