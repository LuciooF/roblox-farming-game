-- Tutorial Panel Component
-- Modern clean tutorial UI positioned at bottom middle with floating title

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local TweenService = game:GetService("TweenService")
local e = React.createElement
-- Import responsive design utilities
local ScreenUtils = require(game:GetService("ReplicatedStorage").Shared.ScreenUtils)

local function TutorialPanel(props)
    local tutorialData = props.tutorialData
    local visible = props.visible or false
    local onNext = props.onNext or function() end
    local onSkip = props.onSkip or function() end
    
    -- Calculate total tutorial rewards (client-side calculation)  
    local totalTutorialRewards = 25 + 25 + 30 + 30 + 40 + 50 + 100 + 50 + 500 -- = 850 coins
    
    if not tutorialData or not tutorialData.step then
        return nil
    end
    
    local step = tutorialData.step
    local stepNumber = tutorialData.stepNumber or 1
    local totalSteps = tutorialData.totalSteps or 10
    
    -- Responsive sizing using ScreenUtils - scale everything proportionally
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local scale = ScreenUtils.getProportionalScale(screenSize)
    
    -- Original desktop sizes - these will be scaled down proportionally
    local panelWidth = 380
    local baseHeight = 140
    local extraHeight = step.instruction and 35 or 0
    local panelHeight = baseHeight + extraHeight
    
    -- Mobile detection
    local isMobile = ScreenUtils.isMobile(screenSize)
    
    -- Dynamic button sizes based on text  
    local nextButtonText = step.id == "complete" and "Done ✓" or (step.action == "auto" and "Next (Auto)" or "Next")
    local nextButtonWidth = step.action == "auto" and 100 or 80
    
    
    -- Create shake animation effect
    local shakeRef = React.useRef(nil)
    
    React.useEffect(function()
        if not visible or not shakeRef.current then return end
        
        local shakeTweens = {} -- Store all shake tweens for cleanup
        
        local function shakeAnimation()
            if not shakeRef.current then return end
            
            local originalPosition = shakeRef.current.Position
            
            -- Create a more complex shake with rotation and position changes
            local shakeInfo1 = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local shakeInfo2 = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local shakeInfo3 = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local shakeInfo4 = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            
            -- Shake sequence: right-up, left-down, right-down, left-up, return to center
            local shake1 = TweenService:Create(shakeRef.current, shakeInfo1, {
                Position = originalPosition + UDim2.new(0, 3, 0, -2)
            })
            
            local shake2 = TweenService:Create(shakeRef.current, shakeInfo2, {
                Position = originalPosition + UDim2.new(0, -2, 0, 3)
            })
            
            local shake3 = TweenService:Create(shakeRef.current, shakeInfo3, {
                Position = originalPosition + UDim2.new(0, 2, 0, 2)
            })
            
            local shake4 = TweenService:Create(shakeRef.current, shakeInfo4, {
                Position = originalPosition
            })
            
            -- Store tweens for cleanup
            table.insert(shakeTweens, shake1)
            table.insert(shakeTweens, shake2)
            table.insert(shakeTweens, shake3)
            table.insert(shakeTweens, shake4)
            
            -- Chain the shakes
            shake1:Play()
            shake1.Completed:Connect(function()
                shake2:Play()
                shake2.Completed:Connect(function()
                    shake3:Play()
                    shake3.Completed:Connect(function()
                        shake4:Play()
                    end)
                end)
            end)
        end
        
        -- Use RunService connection instead of recursive task.spawn
        local lastShakeTime = 0
        local connection = game:GetService("RunService").Heartbeat:Connect(function()
            local currentTime = tick()
            if currentTime - lastShakeTime >= 8 then -- Shake every 8 seconds
                shakeAnimation()
                lastShakeTime = currentTime
            end
        end)
        
        return function()
            -- Clean up connection
            if connection then
                connection:Disconnect()
                connection = nil
            end
            
            -- Clean up all shake tweens
            for _, tween in pairs(shakeTweens) do
                if tween then
                    tween:Cancel()
                    tween:Destroy()
                end
            end
            shakeTweens = {}
        end
    end, {visible})
    
    -- Auto-progression for "auto" action steps
    React.useEffect(function()
        if visible and step.action == "auto" then
            -- Auto-progress after 4 seconds to give user time to read
            local timer = task.delay(4, function()
                -- Auto-progress to next step
                onNext()
            end)
            
            return function()
                -- Clean up timer if component unmounts or changes
                if timer then
                    task.cancel(timer)
                end
            end
        end
    end, {visible, step.action, step.id})
    
    return e("Frame", {
        Name = "TutorialContainer",
        Size = UDim2.new(0, (panelWidth + 40) * scale, 0, (panelHeight + 40) * scale), -- Extra space for floating title
        Position = UDim2.new(0.5, -((panelWidth + 40) * scale) / 2, 1, -((panelHeight + 60) * scale)), -- Bottom middle
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = visible,
        ZIndex = 20, -- Lowered from 60 to 20 so other panels can appear on top
        ref = shakeRef
    }, {
        -- Floating Title (positioned on top left, half in/half out like GP UI)
        FloatingTitle = e("Frame", {
            Name = "FloatingTitle",
            Size = UDim2.new(0, 120 * scale, 0, 35 * scale),
            Position = UDim2.new(0, -10 * scale, 0, 10 * scale), -- Top left, half in/half out of main panel
            BackgroundColor3 = Color3.fromRGB(100, 150, 255),
            BorderSizePixel = 0,
            ZIndex = 22
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 12 * scale)
            }),
            Gradient = e("UIGradient", {
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 180, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 140, 255))
                },
                Rotation = 45
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(255, 255, 255),
                Thickness = 2 * scale,
                Transparency = 0.3
            }),
            TitleText = e("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                Text = "📚 TUTORIAL",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 20 * scale,
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                TextWrapped = true,
                ZIndex = 23
            }, {
                TextStroke = e("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = 2 * scale,
                    Transparency = 0.5
                })
            })
        }),
        
        -- Main Panel
        MainPanel = e("Frame", {
            Name = "TutorialPanel",
            Size = UDim2.new(0, panelWidth * scale, 0, panelHeight * scale),
            Position = UDim2.new(0, 0, 0, 40 * scale), -- Below floating title
            BackgroundColor3 = Color3.fromRGB(245, 250, 255),
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
            ZIndex = 21
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 15 * scale)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(100, 150, 255),
                Thickness = 3 * scale,
                Transparency = 0.1
            }),
            Gradient = e("UIGradient", {
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(248, 252, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(240, 248, 255))
                },
                Rotation = 135
            }),
            
            
            -- Content Container
            ContentContainer = e("Frame", {
                Name = "ContentContainer",
                Size = UDim2.new(1, -20 * scale, 1, -50 * scale), -- Leave space for progress bar
                Position = UDim2.new(0, 10 * scale, 0, 10 * scale),
                BackgroundTransparency = 1,
                ZIndex = 22
            }, {
                -- Step Title
                StepTitle = e("TextLabel", {
                    Name = "StepTitle",
                    Size = UDim2.new(1, -80 * scale, 0, 25 * scale),
                    Position = UDim2.new(0, 0, 0, 0),
                    Text = step.title,
                    TextColor3 = Color3.fromRGB(40, 60, 120),
                    TextSize = 22 * scale,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    ZIndex = 22
                }),
                
                -- Step Counter with Percentage
                StepCounter = e("TextLabel", {
                    Name = "StepCounter",
                    Size = UDim2.new(0, 90 * scale, 0, 20 * scale),
                    Position = UDim2.new(1, -90 * scale, 0, 2 * scale),
                    Text = stepNumber .. "/" .. totalSteps .. " (" .. math.floor((stepNumber / totalSteps) * 100) .. "%)",
                    TextColor3 = Color3.fromRGB(100, 120, 160),
                    TextSize = 15 * scale,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    ZIndex = 22
                }),
                
                -- Description
                Description = e("TextLabel", {
                    Name = "Description",
                    Size = UDim2.new(1, 0, 0, (step.instruction and 35 or 45) * scale), -- Reduced height to make room for instruction
                    Position = UDim2.new(0, 0, 0, 25 * scale),
                    Text = step.description,
                    TextColor3 = Color3.fromRGB(70, 80, 120),
                    TextSize = (isMobile and 14 or 16) * scale,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    TextWrapped = true,
                    ZIndex = 22
                }),
                
                -- Instruction (how to complete the step) - Allow text wrapping with padding
                Instruction = step.instruction and e("TextLabel", {
                    Name = "Instruction",
                    Size = UDim2.new(1, 0, 0, 30 * scale), -- Height for text wrapping
                    Position = UDim2.new(0, 0, 0, 65 * scale), -- Moved down to avoid overlap with description
                    Text = "📍 " .. (step.instruction and step.instruction:gsub("Click on any gray plot", "Follow the yellow trail to the FREE plot and click on it") or step.instruction),
                    TextColor3 = Color3.fromRGB(100, 150, 255),
                    TextSize = (isMobile and 14 or 16) * scale,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    TextWrapped = true, -- Allow text wrapping
                    ZIndex = 22
                }) or nil,
                
                -- Reward Display (green rectangle aligned with skip button, fully inside UI)
                RewardDisplay = step.reward and step.reward.money > 0 and e("Frame", {
                    Name = "RewardDisplay",
                    Size = UDim2.new(0, 80 * scale, 0, 28 * scale), -- Same height as buttons
                    Position = UDim2.new(1, -90 * scale, 1, -35 * scale), -- Right side of card, same line as buttons
                    BackgroundColor3 = Color3.fromRGB(50, 180, 50),
                    BackgroundTransparency = 0.05,
                    BorderSizePixel = 0,
                    ZIndex = 23
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 10 * scale)
                    }),
                    Gradient = e("UIGradient", {
                        Color = ColorSequence.new{
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 200, 60)),
                            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(40, 160, 40)),
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 140, 30))
                        },
                        Rotation = 135
                    }),
                    Stroke = e("UIStroke", {
                        Color = Color3.fromRGB(80, 220, 80),
                        Thickness = 2 * scale,
                        Transparency = 0.2
                    }),
                    RewardText = e("TextLabel", {
                        Size = UDim2.new(1, 0, 1, 0),
                        Text = "🎁 $" .. step.reward.money,
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = 15 * scale,
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        TextStrokeTransparency = 0.3,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.GothamBold,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        ZIndex = 24
                    })
                }) or nil,
                
                -- Next Button (show for continue and auto actions, improved styling)
                NextButton = (step.action == "continue" or step.action == "auto") and e("TextButton", {
                    Name = "NextButton",
                    Size = UDim2.new(0, nextButtonWidth * scale, 0, 28 * scale),
                    Position = UDim2.new(1, -nextButtonWidth * scale, 1, -35 * scale), -- Moved down to avoid covering text
                    Text = "",
                    BackgroundColor3 = Color3.fromRGB(50, 150, 50),
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    ZIndex = 23,
                    [React.Event.Activated] = onNext
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 8 * scale)
                    }),
                    Gradient = e("UIGradient", {
                        Color = ColorSequence.new{
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 200, 80)),
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 140, 40))
                        },
                        Rotation = 45
                    }),
                    Stroke = e("UIStroke", {
                        Color = Color3.fromRGB(255, 255, 255),
                        Thickness = 2 * scale,
                        Transparency = 0.2
                    }),
                    -- White text label with black stroke
                    ButtonText = e("TextLabel", {
                        Name = "ButtonText",
                        Size = UDim2.new(1, 0, 1, 0),
                        Position = UDim2.new(0, 0, 0, 0),
                        Text = nextButtonText,
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = 17 * scale,
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        TextStrokeTransparency = 0,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.GothamBold,
                        ZIndex = 24
                    })
                }) or nil
            }),
            
            -- Progress Bar (at bottom of main panel)
            ProgressContainer = e("Frame", {
                Name = "ProgressContainer",
                Size = UDim2.new(1, -20 * scale, 0, 20 * scale),
                Position = UDim2.new(0, 10 * scale, 1, -25 * scale),
                BackgroundTransparency = 1,
                ZIndex = 22
            }, {
                ProgressBG = e("Frame", {
                    Name = "ProgressBackground",
                    Size = UDim2.new(1, 0, 0, 6 * scale),
                    Position = UDim2.new(0, 0, 0, 7 * scale),
                    BackgroundColor3 = Color3.fromRGB(200, 210, 230),
                    BorderSizePixel = 0,
                    ZIndex = 22
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 3 * scale)
                    }),
                    ProgressFill = e("Frame", {
                        Name = "ProgressFill",
                        Size = UDim2.new(stepNumber / totalSteps, 0, 1, 0),
                        Position = UDim2.new(0, 0, 0, 0),
                        BackgroundColor3 = Color3.fromRGB(100, 150, 255),
                        BorderSizePixel = 0,
                        ZIndex = 23
                    }, {
                        Corner = e("UICorner", {
                            CornerRadius = UDim.new(0, 3 * scale)
                        }),
                        Gradient = e("UIGradient", {
                            Color = ColorSequence.new{
                                ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 180, 255)),
                                ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 140, 255))
                            }
                        })
                    })
                })
            })
        })
    })
end

return TutorialPanel