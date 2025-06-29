-- Top Stats Component
-- Shows money and rebirths with modern UI design matching reference

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local e = React.createElement
local NumberFormatter = require(game:GetService("ReplicatedStorage").Shared.NumberFormatter)
local assets = require(game:GetService("ReplicatedStorage").Shared.assets)
local ScreenUtils = require(game:GetService("ReplicatedStorage").Shared.ScreenUtils)
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local function TopStats(props)
    local playerData = props.playerData or {}
    
    -- Calculate rebirth requirements with safe defaults
    local rebirths = playerData.rebirths or 0
    local money = playerData.money or 0
    local moneyRequired = math.floor(1000 * (2.5 ^ rebirths))
    local canRebirth = money >= moneyRequired
    local multiplier = 1 + (rebirths * 0.5)
    
    -- Check if player has 2x money gamepass
    local has2xMoney = playerData.gamepasses and playerData.gamepasses.moneyMultiplier == true
    
    -- Responsive sizing based on screen size with proportional scaling
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local scale = ScreenUtils.getProportionalScale(screenSize, Vector2.new(1920, 1080), 0.7, 1.5)
    
    -- Proportional text sizes
    local titleTextSize = ScreenUtils.getProportionalTextSize(screenSize, 24)
    local normalTextSize = ScreenUtils.getProportionalTextSize(screenSize, 20)
    local smallTextSize = ScreenUtils.getProportionalTextSize(screenSize, 16)
    local popupTextSize = ScreenUtils.getProportionalTextSize(screenSize, 18)
    
    -- Get text length to determine dynamic sizing
    local moneyText = NumberFormatter.format(money)
    local rebirthText = tostring(rebirths)
    
    -- Dynamic container width based on text length - add extra space for suffixes
    local baseWidth = 120 -- Increased from 100 to give more space for suffixes like "K", "M", etc.
    local moneyWidth = math.max(baseWidth, 80 + (string.len(moneyText) * 10)) * scale -- Increased multiplier and base
    local rebirthWidth = math.max(baseWidth, 80 + (string.len(rebirthText) * 10)) * scale
    
    -- Container dimensions
    local containerHeight = 45 * scale
    local containerSpacing = 25 * scale -- Increased spacing between containers
    local iconSize = 55 * scale -- Larger icon that extends outside
    
    -- Refs for animations
    local cashIconRef = React.useRef()
    local rebirthIconRef = React.useRef()
    local moneyPopupRef = React.useRef()
    local rebirthPopupRef = React.useRef()
    local money2xRef = React.useRef()
    
    -- Previous values to detect changes
    local prevMoney = React.useRef(money)
    local prevRebirths = React.useRef(rebirths)
    
    -- Animation counters to track latest animations
    local moneyAnimationId = React.useRef(0)
    local rebirthAnimationId = React.useRef(0)
    
    -- State for popup text
    local moneyPopupText, setMoneyPopupText = React.useState("")
    local rebirthPopupText, setRebirthPopupText = React.useState("")
    local showMoneyPopup, setShowMoneyPopup = React.useState(false)
    local showRebirthPopup, setShowRebirthPopup = React.useState(false)
    
    -- Money bounce animation when money increases
    React.useEffect(function()
        if not cashIconRef.current then return end
        
        local currentMoney = money
        local previousMoney = prevMoney.current
        
        if currentMoney > previousMoney then
            local difference = currentMoney - previousMoney
            
            -- Icon bounce animation
            local bounceUp = TweenService:Create(cashIconRef.current, 
                TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
                {Position = UDim2.new(0, -iconSize * 0.3, 0.5, -iconSize/2 - 8)}
            )
            
            local bounceDown = TweenService:Create(cashIconRef.current, 
                TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
                {Position = UDim2.new(0, -iconSize * 0.3, 0.5, -iconSize/2)}
            )
            
            bounceUp:Play()
            bounceUp.Completed:Connect(function()
                bounceDown:Play()
            end)
            
            -- Increment animation ID to make this the latest
            moneyAnimationId.current = moneyAnimationId.current + 1
            local currentAnimationId = moneyAnimationId.current
            
            -- Floating text animation
            setMoneyPopupText("+$" .. NumberFormatter.format(difference))
            setShowMoneyPopup(true)
            
            -- Start animation immediately without RunService delay
            task.spawn(function()
                -- Small delay to ensure React has rendered the popup
                task.wait(0.1)
                
                if moneyPopupRef.current and moneyAnimationId.current == currentAnimationId then
                    -- Reset position - centered under the money container
                    moneyPopupRef.current.Position = UDim2.new(0, moneyWidth/2 - 100, 1, 10)
                    moneyPopupRef.current.TextTransparency = 0
                    
                    -- Float up and fade out
                    local floatTween = TweenService:Create(moneyPopupRef.current,
                        TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {
                            Position = UDim2.new(0, moneyWidth/2 - 100, 1, -30),
                            TextTransparency = 1
                        }
                    )
                    
                    floatTween:Play()
                    floatTween.Completed:Connect(function()
                        -- Only hide if this is still the latest animation
                        if moneyAnimationId.current == currentAnimationId then
                            setShowMoneyPopup(false)
                        end
                        floatTween:Destroy()
                    end)
                end
            end)
        end
        
        prevMoney.current = currentMoney
    end, {money, has2xMoney})
    
    -- Rebirth spin animation when rebirths change
    React.useEffect(function()
        if not rebirthIconRef.current then return end
        
        local currentRebirths = rebirths
        local previousRebirths = prevRebirths.current
        
        if currentRebirths ~= previousRebirths then
            local difference = currentRebirths - previousRebirths
            
            -- Icon spin animation
            local spinTween = TweenService:Create(rebirthIconRef.current, 
                TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
                {Rotation = 360}
            )
            
            spinTween:Play()
            spinTween.Completed:Connect(function()
                -- Reset rotation to 0 for next animation
                rebirthIconRef.current.Rotation = 0
            end)
            
            -- Floating text animation (only if difference > 0)
            if difference > 0 then
                -- Increment animation ID to make this the latest
                rebirthAnimationId.current = rebirthAnimationId.current + 1
                local currentAnimationId = rebirthAnimationId.current
                
                setRebirthPopupText("+" .. difference .. " Rebirth" .. (difference > 1 and "s" or ""))
                setShowRebirthPopup(true)
                
                -- Use RunService to wait for next frame and then start animation
                local connection
                connection = game:GetService("RunService").Heartbeat:Connect(function()
                    connection:Disconnect()
                    
                    if rebirthPopupRef.current and rebirthAnimationId.current == currentAnimationId then
                        -- Reset position - centered under the rebirth container
                        -- Calculate position relative to the rebirth container which is positioned at the right
                        local rebirthContainerX = moneyWidth + containerSpacing
                        rebirthPopupRef.current.Position = UDim2.new(0, rebirthContainerX + rebirthWidth/2 - 100, 1, 10)
                        rebirthPopupRef.current.TextTransparency = 0
                        
                        -- Float up and fade out
                        local floatTween = TweenService:Create(rebirthPopupRef.current,
                            TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                            {
                                Position = UDim2.new(0, rebirthContainerX + rebirthWidth/2 - 100, 1, -30),
                                TextTransparency = 1
                            }
                        )
                        
                        floatTween:Play()
                        floatTween.Completed:Connect(function()
                            -- Only hide if this is still the latest animation
                            if rebirthAnimationId.current == currentAnimationId then
                                setShowRebirthPopup(false)
                            end
                            floatTween:Destroy()
                        end)
                    end
                end)
            end
        end
        
        prevRebirths.current = currentRebirths
    end, {rebirths})
    
    -- Bouncing animation for 2x money indicator
    React.useEffect(function()
        if not has2xMoney or not money2xRef.current then return end
        
        local function createBounceAnimation()
            local bounceUp = TweenService:Create(money2xRef.current,
                TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {Position = UDim2.new(1, -15, 0, -5)}
            )
            
            local bounceDown = TweenService:Create(money2xRef.current,
                TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {Position = UDim2.new(1, -15, 0, 5)}
            )
            
            bounceUp:Play()
            bounceUp.Completed:Connect(function()
                bounceDown:Play()
                bounceDown.Completed:Connect(function()
                    task.wait(0.5) -- Pause between bounces
                    createBounceAnimation() -- Loop the animation
                end)
            end)
        end
        
        createBounceAnimation()
    end, {has2xMoney})
    
    return e("Frame", {
        Name = "TopStatsFrame",
        Size = UDim2.new(0, moneyWidth + rebirthWidth + containerSpacing, 0, containerHeight),
        Position = UDim2.new(0.5, -(moneyWidth + rebirthWidth + containerSpacing)/2, 0, 5),
        BackgroundTransparency = 1,
        ZIndex = 10,
        ClipsDescendants = false -- Allow popups to show outside
    }, {
        -- Money Display Container
        MoneyContainer = e("Frame", {
            Name = "MoneyContainer",
            Size = UDim2.new(0, moneyWidth, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            ZIndex = 11,
            ClipsDescendants = false -- Allow icon to extend outside
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 16) -- More rounded corners
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 2,
                Transparency = 0
            }),
            
            -- Cash Icon (extends outside container)
            CashIcon = e("ImageLabel", {
                Name = "CashIcon",
                Size = UDim2.new(0, iconSize, 0, iconSize),
                Position = UDim2.new(0, -iconSize * 0.3, 0.5, -iconSize/2), -- Moved further out
                Image = assets["Currency/Cash/Cash Outline 256.png"] or "", -- Use outline version
                ScaleType = Enum.ScaleType.Fit,
                BackgroundTransparency = 1,
                ZIndex = 12,
                ref = cashIconRef
            }),
            
            -- Money Text (moved right to avoid overlap)
            MoneyText = e("TextLabel", {
                Name = "MoneyText",
                Size = UDim2.new(1, -(iconSize * 0.7 + 5), 1, 0), -- Reduced margin from 10 to 5
                Position = UDim2.new(0, iconSize * 0.7 + 5, 0, 0),
                Text = moneyText,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = titleTextSize,
                TextWrapped = false, -- Changed to false to prevent text wrapping
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 12
            }, {
                -- Text size constraint
                TextSizeConstraint = e("UITextSizeConstraint", {
                    MaxTextSize = ScreenUtils.getProportionalTextSize(screenSize, 24),
                    MinTextSize = ScreenUtils.getProportionalTextSize(screenSize, 16)
                }),
                -- Removed right padding to prevent cutting off suffix letters like "K", "M", etc.
                -- Black outline
                TextStroke = e("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = 2,
                    Transparency = 0.3
                })
            }),
            
            -- 2x Money Indicator (rainbow bouncing when has gamepass)
            Money2xIndicator = has2xMoney and e("TextLabel", {
                Name = "Money2xIndicator",
                Size = UDim2.new(0, 30, 0, 18),
                Position = UDim2.new(1, -15, 0, 0), -- Top right diagonal position
                Text = "2x!",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = ScreenUtils.getProportionalTextSize(screenSize, 14),
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                BackgroundTransparency = 1,
                ZIndex = 18,
                Rotation = 25, -- Diagonal rotation like "\" (northwest facing)
                ref = money2xRef
            }, {
                TextStroke = e("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = 2,
                    Transparency = 0.3
                }),
                RainbowGradient = e("UIGradient", {
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),    -- Red
                        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 165, 0)), -- Orange
                        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)), -- Yellow
                        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),   -- Green
                        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),  -- Blue
                        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(75, 0, 130)), -- Indigo
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(238, 130, 238))  -- Violet
                    }
                })
            }) or nil,
            
            -- Money popup text
            MoneyPopup = showMoneyPopup and e("TextLabel", {
                Name = "MoneyPopup",
                Size = UDim2.new(0, 200, 0, 30),
                Position = UDim2.new(0, moneyWidth/2 - 100, 1, 10),
                Text = moneyPopupText,
                TextColor3 = has2xMoney and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 200, 0), -- Pure white for rainbow gradient, green for normal
                TextSize = popupTextSize,
                TextWrapped = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 15,
                TextStrokeTransparency = 0.5,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                ref = moneyPopupRef
            }, {
                TextSizeConstraint = e("UITextSizeConstraint", {
                    MaxTextSize = ScreenUtils.getProportionalTextSize(screenSize, 20),
                    MinTextSize = ScreenUtils.getProportionalTextSize(screenSize, 16)
                }),
                -- Add rainbow gradient for money popup when has 2x money gamepass
                PopupGradient = has2xMoney and e("UIGradient", {
                    Name = "PopupGradient",
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 0, 0)),    -- Bright Red
                        ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 127, 0)), -- Bright Orange  
                        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)), -- Bright Yellow
                        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),    -- Bright Green
                        ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 127, 255)), -- Bright Blue
                        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(148, 0, 211)), -- Bright Violet
                        ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 0, 255))   -- Bright Magenta
                    },
                    Rotation = 45 -- Diagonal rainbow for better visibility
                }) or nil
            }) or nil
        }),
        
        -- Rebirth Display Container (display only - interaction moved to side buttons)
        RebirthContainer = e("Frame", {
            Name = "RebirthContainer",
            Size = UDim2.new(0, rebirthWidth, 1, 0),
            Position = UDim2.new(1, -rebirthWidth, 0, 0),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            ZIndex = 11,
            ClipsDescendants = false -- Allow icon to extend outside
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 16) -- More rounded corners
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0), -- Always black outline
                Thickness = 2,
                Transparency = 0,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border -- Ensure stroke is applied
            }),
            
            -- Rebirth Icon (extends outside container)
            RebirthIcon = e("ImageLabel", {
                Name = "RebirthIcon",
                Size = UDim2.new(0, iconSize, 0, iconSize),
                Position = UDim2.new(0, -iconSize * 0.3, 0.5, -iconSize/2), -- Moved further out
                Image = assets["General/Rebirth/Rebirth Outline 256.png"] or "", -- Use outline version
                ScaleType = Enum.ScaleType.Fit,
                BackgroundTransparency = 1,
                ZIndex = 12,
                ref = rebirthIconRef
            }),
            
            -- Rebirth Text (moved right to avoid overlap)
            RebirthText = e("TextLabel", {
                Name = "RebirthText",
                Size = UDim2.new(1, -(iconSize * 0.7 + 10), 1, 0),
                Position = UDim2.new(0, iconSize * 0.7 + 5, 0, 0),
                Text = rebirthText,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = titleTextSize,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 12
            }, {
                -- Text size constraint
                TextSizeConstraint = e("UITextSizeConstraint", {
                    MaxTextSize = ScreenUtils.getProportionalTextSize(screenSize, 24),
                    MinTextSize = ScreenUtils.getProportionalTextSize(screenSize, 16)
                }),
                Padding = e("UIPadding", {
                    PaddingRight = UDim.new(0, 10)
                }),
                -- Black outline
                TextStroke = e("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = 2,
                    Transparency = 0.3
                })
            })
        }),
        
        -- Rebirth popup text (positioned at main frame level for proper positioning)
        RebirthPopup = showRebirthPopup and e("TextLabel", {
            Name = "RebirthPopup",
            Size = UDim2.new(0, 200, 0, 30),
            Position = UDim2.new(0, moneyWidth + containerSpacing + rebirthWidth/2 - 100, 1, 10),
            Text = rebirthPopupText,
            TextColor3 = Color3.fromRGB(255, 200, 0),
            TextSize = popupTextSize,
            TextWrapped = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSansBold,
            ZIndex = 15,
            TextStrokeTransparency = 0.5,
            TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
            ref = rebirthPopupRef
        }, {
            TextSizeConstraint = e("UITextSizeConstraint", {
                MaxTextSize = 20 * scale,
                MinTextSize = 16 * scale
            })
        }) or nil,
        
        -- Rebirth Tooltip
        RebirthTooltip = e("Frame", {
            Name = "RebirthTooltip",
            Size = UDim2.new(0, 200 * scale, 0, 70 * scale),
            Position = UDim2.new(0.5, -100 * scale, 1, 5 * scale),
            BackgroundColor3 = Color3.fromRGB(250, 250, 250),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 15
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 10)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 1,
                Transparency = 0
            }),
            TooltipContent = e("Frame", {
                Name = "Content",
                Size = UDim2.new(1, -16, 1, -16),
                Position = UDim2.new(0, 8, 0, 8),
                BackgroundTransparency = 1,
                ZIndex = 16
            }, {
                CurrentLabel = e("TextLabel", {
                    Name = "CurrentLabel",
                    Size = UDim2.new(1, 0, 0.5, -2),
                    Position = UDim2.new(0, 0, 0, 0),
                    Text = "Current: " .. string.format("%.1fx multiplier", multiplier),
                    TextColor3 = Color3.fromRGB(0, 150, 0),
                    TextSize = smallTextSize,
                    TextWrapped = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.SourceSansBold,
                    ZIndex = 16
                }),
                RequirementLabel = e("TextLabel", {
                    Name = "RequirementLabel",
                    Size = UDim2.new(1, 0, 0.5, -2),
                    Position = UDim2.new(0, 0, 0.5, 2),
                    Text = "Next rebirth: $" .. NumberFormatter.format(moneyRequired),
                    TextColor3 = canRebirth and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(200, 50, 50),
                    TextSize = smallTextSize,
                    TextWrapped = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.SourceSans,
                    ZIndex = 16
                })
            })
        })
    })
end

return TopStats