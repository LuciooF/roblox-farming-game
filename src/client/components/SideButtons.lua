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
        if animationTracker.current and animationTracker.current.Destroy then
            animationTracker.current:Destroy()
        end
        animationTracker.current = nil
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
    local onPetsClick = props.onPetsClick or function() end
    local onRebirthClick = props.onRebirthClick or function() end
    local onComingSoonClick = props.onComingSoonClick or function() end
    local tutorialData = props.tutorialData
    
    -- Tooltip state
    local tooltipText, setTooltipText = React.useState("")
    local tooltipVisible, setTooltipVisible = React.useState(false)
    local mousePosition, setMousePosition = React.useState(Vector2.new(0, 0))
    
    -- Mouse tracking for tooltip positioning
    React.useEffect(function()
        local connection
        local mouse = game.Players.LocalPlayer:GetMouse()
        
        local function updateMousePosition()
            setMousePosition(Vector2.new(mouse.X, mouse.Y))
        end
        
        if tooltipVisible then
            connection = game:GetService("RunService").Heartbeat:Connect(updateMousePosition)
        end
        
        return function()
            if connection then
                connection:Disconnect()
            end
        end
    end, {tooltipVisible})
    
    -- Tooltip helper functions
    local function showTooltip(text)
        setTooltipText(text)
        setTooltipVisible(true)
    end
    
    local function hideTooltip()
        setTooltipVisible(false)
    end
    
    -- Responsive sizing using ScreenUtils with proportional scaling
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local scale = ScreenUtils.getProportionalScale(screenSize)
    
    -- Proportional sizing
    local buttonSize = ScreenUtils.getProportionalSize(screenSize, 55)
    local iconSize = ScreenUtils.getProportionalSize(screenSize, 32)
    local spacing = ScreenUtils.getProportionalSize(screenSize, 12)
    
    -- Proportional text sizes
    local tooltipTextSize = ScreenUtils.getProportionalTextSize(screenSize, 20)
    local smallTextSize = ScreenUtils.getProportionalTextSize(screenSize, 12)
    local soonTextSize = ScreenUtils.getProportionalTextSize(screenSize, 10)
    
    -- Check if buttons should be highlighted for tutorial
    local shouldHighlightInventory = false
    local shouldHighlightShop = false
    local shouldHighlightRebirth = false
    
    if tutorialData and tutorialData.step then
        if tutorialData.step.id == "sell_crops" then
            shouldHighlightInventory = true
        elseif tutorialData.step.id == "buy_banana" then
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
    local comingSoonIconRef = React.useRef(nil)
    local comingSoonTextRef = React.useRef(nil)
    
    -- Animation trackers to prevent stacking
    local shopAnimTracker = React.useRef(nil)
    local inventoryAnimTracker = React.useRef(nil)
    local weatherAnimTracker = React.useRef(nil)
    local gamepassAnimTracker = React.useRef(nil)
    local rebirthAnimTracker = React.useRef(nil)
    local petsAnimTracker = React.useRef(nil)
    local comingSoonAnimTracker = React.useRef(nil)
    
    -- Bouncing animation for both pets and coming soon buttons + rainbow color cycling
    React.useEffect(function()
        
        local function startBounceAnimation()
            local animations = {}
            
            -- Pets button animations
            if petsSoonTextRef.current and petsIconRef.current then
                -- Bounce animation for pets text
                local petsTextBounce = TweenService:Create(petsSoonTextRef.current,
                    TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                    {Position = UDim2.new(0.5, 0, 0.5, -22)}
                )
                
                -- Bounce animation for pets icon (smaller bounce)
                local petsIconBounce = TweenService:Create(petsIconRef.current,
                    TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                    {Position = UDim2.new(0.5, -iconSize/2, 0.5, -iconSize/2 - 3)}
                )
                
                petsTextBounce:Play()
                petsIconBounce:Play()
                
                table.insert(animations, petsTextBounce)
                table.insert(animations, petsIconBounce)
            end
            
            -- Coming Soon button animations
            if comingSoonTextRef.current and comingSoonIconRef.current then
                -- Bounce animation for coming soon text
                local comingSoonTextBounce = TweenService:Create(comingSoonTextRef.current,
                    TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                    {Position = UDim2.new(0.5, 0, 0.5, -22)}
                )
                
                -- Bounce animation for coming soon icon (smaller bounce)
                local comingSoonIconBounce = TweenService:Create(comingSoonIconRef.current,
                    TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                    {Position = UDim2.new(0.5, -iconSize/2, 0.5, -iconSize/2 - 3)}
                )
                
                comingSoonTextBounce:Play()
                comingSoonIconBounce:Play()
                
                table.insert(animations, comingSoonTextBounce)
                table.insert(animations, comingSoonIconBounce)
            end
            
            return animations
        end
        
        local function startRainbowAnimation()
            -- Pets rainbow animation
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
            
            -- Coming Soon rainbow animation (slightly different timing)
            if comingSoonTextRef.current then
                local rainbowColors = {
                    Color3.fromRGB(255, 50, 50),   -- Bright Red
                    Color3.fromRGB(255, 150, 0),   -- Bright Orange
                    Color3.fromRGB(255, 255, 0),   -- Bright Yellow
                    Color3.fromRGB(0, 255, 100),   -- Bright Green
                    Color3.fromRGB(0, 255, 255),   -- Bright Cyan
                    Color3.fromRGB(255, 100, 255), -- Bright Magenta
                }
                
                local function cycleColorsComingSoon(colorIndex)
                    if not comingSoonTextRef.current then return end
                    
                    local nextIndex = (colorIndex % #rainbowColors) + 1
                    local colorTween = TweenService:Create(comingSoonTextRef.current,
                        TweenInfo.new(0.6, Enum.EasingStyle.Linear),
                        {TextColor3 = rainbowColors[nextIndex]}
                    )
                    
                    colorTween:Play()
                    colorTween.Completed:Connect(function()
                        colorTween:Destroy()
                        cycleColorsComingSoon(nextIndex)
                    end)
                end
                
                -- Start the cycle with slight offset
                wait(0.2)
                cycleColorsComingSoon(3) -- Start at different color
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
    
    -- Use aspect ratio to determine layout instead of screen width
    local aspectRatio = screenSize.X / screenSize.Y
    local isCompactLayout = aspectRatio < 1.5 -- Compact layout for portrait or square screens
    
    return e("Frame", {
        Name = "SideButtonsFrame",
        Size = isCompactLayout and 
            UDim2.new(0, (2 * buttonSize) + spacing, 0, (4 * buttonSize) + (3 * spacing)) or -- 2x4 grid on compact screens
            UDim2.new(0, buttonSize, 0, (7 * buttonSize) + (6 * spacing)), -- 1x7 column on wide screens
        Position = isCompactLayout and 
            UDim2.new(1, -((2 * buttonSize) + spacing + ScreenUtils.getProportionalSize(screenSize, 5)), 0, ScreenUtils.getProportionalSize(screenSize, 80)) or -- Top-right on compact (minimal margin)
            UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 20), 0.5, -((7 * buttonSize) + (6 * spacing))/2), -- Left-center on wide
        BackgroundTransparency = 1,
        ZIndex = 10
    }, {
        Layout = isCompactLayout and e("UIGridLayout", {
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
            [React.Event.MouseEnter] = function(rbx)
                playSound("hover")
                createIconSpin(shopIconRef, shopAnimTracker)
                showTooltip("Shop - Buy seeds and crops")
            end,
            [React.Event.MouseLeave] = function()
                hideTooltip()
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
                Image = assets["General/Shop/Shop Outline 256.png"],
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
            [React.Event.MouseEnter] = function(rbx)
                playSound("hover")
                createIconSpin(inventoryIconRef, inventoryAnimTracker)
                showTooltip("Inventory - Manage your crops")
            end,
            [React.Event.MouseLeave] = function()
                hideTooltip()
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
                Image = assets["General/Barn/Barn Outline 256.png"],
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
            [React.Event.MouseEnter] = function(rbx)
                playSound("hover")
                createIconSpin(weatherIconRef, weatherAnimTracker)
                showTooltip("Weather - Check farm conditions")
            end,
            [React.Event.MouseLeave] = function()
                hideTooltip()
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
            [React.Event.MouseEnter] = function(rbx)
                playSound("hover")
                createIconSpin(gamepassIconRef, gamepassAnimTracker)
                showTooltip("Gamepasses - Unlock premium features")
            end,
            [React.Event.MouseLeave] = function()
                hideTooltip()
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
            BackgroundColor3 = shouldHighlightRebirth and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = 11,
            LayoutOrder = 5,
            [React.Event.Activated] = function()
                playSound("click")
                createIconSpin(rebirthIconRef, rebirthAnimTracker)
                onRebirthClick()
            end,
            [React.Event.MouseEnter] = function(rbx)
                playSound("hover")
                createIconSpin(rebirthIconRef, rebirthAnimTracker)
                showTooltip("Rebirth - Reset for bonuses")
            end,
            [React.Event.MouseLeave] = function()
                hideTooltip()
            end
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0.5, 0)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = shouldHighlightRebirth and 3 or 2,
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
        
        -- Pets Button (Secret Debug Access!)
        PetsButton = e("TextButton", {
            Name = "PetsButton",
            Size = UDim2.new(0, buttonSize, 0, buttonSize),
            Text = "",
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = 11,
            LayoutOrder = 6,
            [React.Event.Activated] = function()
                playSound("click")
                createIconSpin(petsIconRef, petsAnimTracker)
                onPetsClick()
            end,
            [React.Event.MouseEnter] = function(rbx)
                playSound("hover")
                createIconSpin(petsIconRef, petsAnimTracker)
                
                -- Check authorization and show appropriate tooltip
                local remoteFolder = game:GetService("ReplicatedStorage"):FindFirstChild("FarmingRemotes")
                local checkDebugAuth = remoteFolder and remoteFolder:FindFirstChild("CheckDebugAuth")
                
                if checkDebugAuth then
                    local success, isAuthorized = pcall(function()
                        return checkDebugAuth:InvokeServer()
                    end)
                    
                    if success and isAuthorized then
                        showTooltip("Debug Panel")
                    else
                        showTooltip("Pets! Soon")
                    end
                else
                    -- In studio or testing - show debug tooltip
                    showTooltip("Debug Panel")
                end
            end,
            [React.Event.MouseLeave] = function()
                hideTooltip()
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
                Position = UDim2.new(0.5, -iconSize/2, 0.5, -iconSize/2 + 3), -- Moved down slightly to center better with text
                Image = assets["General/Pet/Pet Brown Outline 256.png"] or "",
                ScaleType = Enum.ScaleType.Fit,
                BackgroundTransparency = 1,
                ZIndex = 12,
                ref = petsIconRef
            }),
            -- Main text with double stroke (simpler approach)
            SoonText = e("TextLabel", {
                Name = "SoonText",
                Size = UDim2.new(0, 50, 0, 16), -- Made wider and taller
                Position = UDim2.new(0.5, 0, 0.5, -20), -- Position inside the button, above center
                AnchorPoint = Vector2.new(0.5, 0.5),
                Text = "SOON!",
                TextColor3 = Color3.fromRGB(255, 50, 50), -- Will be animated to rainbow
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0), -- Black stroke
                TextStrokeTransparency = 0, -- Solid black stroke
                TextSize = soonTextSize,
                TextWrapped = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Rotation = -15, -- Tilted text
                ZIndex = 13,
                ref = petsSoonTextRef
            }, {
                TextSizeConstraint = e("UITextSizeConstraint", {
                    MaxTextSize = 14, -- Increased from 10 to 14
                    MinTextSize = 8   -- Increased from 6 to 8
                })
            })
        }),
        
        -- Coming Soon Button (Mysterious Potion Feature)
        ComingSoonButton = e("TextButton", {
            Name = "ComingSoonButton",
            Size = UDim2.new(0, buttonSize, 0, buttonSize),
            Text = "",
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = 11,
            LayoutOrder = 7,
            [React.Event.Activated] = function()
                playSound("click")
                createIconSpin(comingSoonIconRef, comingSoonAnimTracker)
                onComingSoonClick()
            end,
            [React.Event.MouseEnter] = function(rbx)
                playSound("hover")
                createIconSpin(comingSoonIconRef, comingSoonAnimTracker)
                showTooltip("??? - Something mysterious is brewing...")
            end,
            [React.Event.MouseLeave] = function()
                hideTooltip()
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
                Name = "ComingSoonIcon",
                Size = UDim2.new(0, iconSize, 0, iconSize),
                Position = UDim2.new(0.5, -iconSize/2, 0.5, -iconSize/2 + 3), -- Moved down slightly to center better with text
                Image = "rbxassetid://111808847228811", -- Potion icon
                ImageColor3 = Color3.fromRGB(0, 0, 0), -- Make it black for mystery
                ScaleType = Enum.ScaleType.Fit,
                BackgroundTransparency = 1,
                ZIndex = 12,
                ref = comingSoonIconRef
            }),
            -- Main text with double stroke (simpler approach)
            SoonText = e("TextLabel", {
                Name = "ComingSoonText",
                Size = UDim2.new(0, 50, 0, 16), -- Made wider and taller
                Position = UDim2.new(0.5, 0, 0.5, -20), -- Position inside the button, above center
                AnchorPoint = Vector2.new(0.5, 0.5),
                Text = "SOON!",
                TextColor3 = Color3.fromRGB(255, 50, 50), -- Will be animated to rainbow
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0), -- Black stroke
                TextStrokeTransparency = 0, -- Solid black stroke
                TextSize = soonTextSize,
                TextWrapped = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Rotation = -15, -- Tilted text
                ZIndex = 13,
                ref = comingSoonTextRef
            }, {
                TextSizeConstraint = e("UITextSizeConstraint", {
                    MaxTextSize = 14, -- Increased from 10 to 14
                    MinTextSize = 8   -- Increased from 6 to 8
                })
            })
        }),
        
        -- Tooltip Component (positioned at mouse cursor) - Modern clean style
        Tooltip = tooltipVisible and e("ScreenGui", {
            Name = "TooltipGui",
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            ResetOnSpawn = false
        }, {
            -- Direct text label with no background frame for cleaner look
            TooltipText = e("TextLabel", {
                Name = "TooltipText",
                Size = UDim2.new(0, 0, 0, 0), -- Auto-size based on text
                Position = UDim2.new(0, mousePosition.X + 15 * scale, 0, mousePosition.Y - 30 * scale), -- Scaled offset from cursor
                AnchorPoint = Vector2.new(0, 0.5),
                AutomaticSize = Enum.AutomaticSize.XY,
                Text = tooltipText,
                TextColor3 = Color3.fromRGB(255, 255, 255), -- Clean white text
                TextSize = tooltipTextSize,
                TextWrapped = true,
                BackgroundTransparency = 1, -- No background
                Font = Enum.Font.GothamBold, -- Bold font for better readability
                TextStrokeTransparency = 0, -- Solid black outline
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0), -- Black outline
                ZIndex = 200, -- Very high ZIndex to appear above everything
            }, {
                -- Add padding for better text spacing
                Padding = e("UIPadding", {
                    PaddingTop = UDim.new(0, 4 * scale),
                    PaddingBottom = UDim.new(0, 4 * scale),
                    PaddingLeft = UDim.new(0, 8 * scale),
                    PaddingRight = UDim.new(0, 8 * scale)
                })
            })
        }) or nil
    })
end

return SideButtons