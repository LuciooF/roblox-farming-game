-- Tutorial Panel Component
-- Modern clean tutorial UI positioned at bottom middle with floating title

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local TweenService = game:GetService("TweenService")
local e = React.createElement

local function TutorialPanel(props)
    local tutorialData = props.tutorialData
    local visible = props.visible or false
    local onNext = props.onNext or function() end
    local onSkip = props.onSkip or function() end
    
    -- Skip confirmation state
    local showSkipConfirm, setShowSkipConfirm = React.useState(false)
    
    -- Calculate total tutorial rewards (client-side calculation)
    local totalTutorialRewards = 25 + 25 + 30 + 30 + 40 + 50 + 100 + 50 + 500 -- = 850 coins
    
    if not tutorialData or not tutorialData.step then
        return nil
    end
    
    local step = tutorialData.step
    local stepNumber = tutorialData.stepNumber or 1
    local totalSteps = tutorialData.totalSteps or 10
    
    -- Responsive sizing - dynamic based on content
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local isMobile = screenSize.X < 768
    local scale = isMobile and 0.9 or 1
    local panelWidth = isMobile and 320 or 380
    
    -- Dynamic sizing - allow for instruction on separate line with padding
    local baseHeight = isMobile and 120 or 140
    local extraHeight = step.instruction and 35 or 0 -- Add height for instruction + padding
    local panelHeight = baseHeight + extraHeight
    
    -- Dynamic button sizes based on text
    local nextButtonText = step.id == "complete" and "Done ✓" or (stepNumber == 1 and "Start Tutorial" or "Next")
    local nextButtonWidth = stepNumber == 1 and 110 or 80 -- Wider for "Start Tutorial"
    
    -- Skip confirmation handlers
    local function handleSkipRequest()
        setShowSkipConfirm(true)
    end
    
    local function handleSkipConfirm()
        setShowSkipConfirm(false)
        onSkip()
    end
    
    local function handleSkipCancel()
        setShowSkipConfirm(false)
    end
    
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
    
    return e("Frame", {
        Name = "TutorialContainer",
        Size = UDim2.new(0, panelWidth * scale, 0, panelHeight * scale + 40), -- Extra space for floating title
        Position = UDim2.new(0.5, -(panelWidth * scale) / 2, 1, -(panelHeight * scale + 60)), -- Bottom middle
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = visible,
        ZIndex = 60,
        ref = shakeRef
    }, {
        -- Floating Title (positioned on top left, half in/half out like GP UI)
        FloatingTitle = e("Frame", {
            Name = "FloatingTitle",
            Size = UDim2.new(0, 120, 0, 35),
            Position = UDim2.new(0, -10, 0, 10), -- Top left, half in/half out of main panel
            BackgroundColor3 = Color3.fromRGB(100, 150, 255),
            BorderSizePixel = 0,
            ZIndex = 62
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 12)
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
                Thickness = 2,
                Transparency = 0.3
            }),
            TitleText = e("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                Text = "📚 TUTORIAL",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                ZIndex = 63
            }, {
                TextStroke = e("UIStroke", {
                    Color = Color3.fromRGB(0, 0, 0),
                    Thickness = 2,
                    Transparency = 0.5
                })
            })
        }),
        
        -- Main Panel
        MainPanel = e("Frame", {
            Name = "TutorialPanel",
            Size = UDim2.new(0, panelWidth * scale, 0, panelHeight * scale),
            Position = UDim2.new(0, 0, 0, 40), -- Below floating title
            BackgroundColor3 = Color3.fromRGB(245, 250, 255),
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
            ZIndex = 61
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 15)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(100, 150, 255),
                Thickness = 3,
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
                Size = UDim2.new(1, -20, 1, -50), -- Leave space for progress bar
                Position = UDim2.new(0, 10, 0, 10),
                BackgroundTransparency = 1,
                ZIndex = 62
            }, {
                -- Step Title
                StepTitle = e("TextLabel", {
                    Name = "StepTitle",
                    Size = UDim2.new(1, -80, 0, 25),
                    Position = UDim2.new(0, 0, 0, 0),
                    Text = step.title,
                    TextColor3 = Color3.fromRGB(40, 60, 120),
                    TextScaled = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 62
                }),
                
                -- Step Counter with Percentage
                StepCounter = e("TextLabel", {
                    Name = "StepCounter",
                    Size = UDim2.new(0, 90, 0, 20),
                    Position = UDim2.new(1, -90, 0, 2),
                    Text = stepNumber .. "/" .. totalSteps .. " (" .. math.floor((stepNumber / totalSteps) * 100) .. "%)",
                    TextColor3 = Color3.fromRGB(100, 120, 160),
                    TextScaled = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    ZIndex = 62
                }),
                
                -- Description
                Description = e("TextLabel", {
                    Name = "Description",
                    Size = UDim2.new(1, 0, 0, step.instruction and 25 or 35),
                    Position = UDim2.new(0, 0, 0, 25),
                    Text = stepNumber == 1 and (step.description .. "\n\nClick 'Start Tutorial' to begin.") or step.description,
                    TextColor3 = Color3.fromRGB(70, 80, 120),
                    TextSize = isMobile and 11 or 13,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    TextWrapped = true,
                    ZIndex = 62
                }),
                
                -- Instruction (how to complete the step) - Allow text wrapping with padding
                Instruction = step.instruction and e("TextLabel", {
                    Name = "Instruction",
                    Size = UDim2.new(1, 0, 0, 25), -- Height for instruction
                    Position = UDim2.new(0, 0, 0, 50),
                    Text = "📍 " .. (step.instruction and step.instruction:gsub("Click on any gray plot", "Follow the yellow trail to the FREE plot and click on it") or step.instruction),
                    TextColor3 = Color3.fromRGB(100, 150, 255),
                    TextSize = isMobile and 11 or 13,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    TextWrapped = true, -- Allow text wrapping
                    ZIndex = 62
                }) or nil,
                
                -- Reward Display (green rectangle in bottom right, half outside UI)
                RewardDisplay = step.reward and step.reward.money > 0 and e("Frame", {
                    Name = "RewardDisplay",
                    Size = UDim2.new(0, 100, 0, 25),
                    Position = UDim2.new(1, -50, 1, -12), -- Half outside the UI, similar to floating title
                    BackgroundColor3 = Color3.fromRGB(50, 180, 50),
                    BackgroundTransparency = 0.05,
                    BorderSizePixel = 0,
                    ZIndex = 63
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 10)
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
                        Thickness = 2,
                        Transparency = 0.2
                    }),
                    RewardText = e("TextLabel", {
                        Size = UDim2.new(1, 0, 1, 0),
                        Text = "🎁 $" .. step.reward.money,
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = 11,
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        TextStrokeTransparency = 0.3,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.GothamBold,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        ZIndex = 64
                    })
                }) or nil,
                
                -- Skip Button (left side)
                SkipButton = e("TextButton", {
                    Name = "SkipButton",
                    Size = UDim2.new(0, 60, 0, 28),
                    Position = UDim2.new(0, 0, 1, -40), -- More padding from bottom and instruction
                    Text = "",
                    BackgroundColor3 = Color3.fromRGB(150, 150, 150),
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    ZIndex = 63,
                    [React.Event.Activated] = handleSkipRequest
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 8)
                    }),
                    Gradient = e("UIGradient", {
                        Color = ColorSequence.new{
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 180, 180)),
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 120, 120))
                        },
                        Rotation = 45
                    }),
                    Stroke = e("UIStroke", {
                        Color = Color3.fromRGB(255, 255, 255),
                        Thickness = 1,
                        Transparency = 0.4
                    }),
                    -- White text label with black stroke
                    ButtonText = e("TextLabel", {
                        Name = "ButtonText",
                        Size = UDim2.new(1, 0, 1, 0),
                        Position = UDim2.new(0, 0, 0, 0),
                        Text = "Skip",
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = 14,
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        TextStrokeTransparency = 0,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.GothamBold,
                        ZIndex = 64
                    })
                }),
                
                -- Next Button (only if continue action, improved styling)
                NextButton = step.action == "continue" and e("TextButton", {
                    Name = "NextButton",
                    Size = UDim2.new(0, nextButtonWidth, 0, 28),
                    Position = UDim2.new(1, -nextButtonWidth, 1, -40), -- More padding from bottom and instruction
                    Text = "",
                    BackgroundColor3 = Color3.fromRGB(50, 150, 50),
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    ZIndex = 63,
                    [React.Event.Activated] = onNext
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 8)
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
                        Thickness = 2,
                        Transparency = 0.2
                    }),
                    -- White text label with black stroke
                    ButtonText = e("TextLabel", {
                        Name = "ButtonText",
                        Size = UDim2.new(1, 0, 1, 0),
                        Position = UDim2.new(0, 0, 0, 0),
                        Text = nextButtonText,
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = 14,
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        TextStrokeTransparency = 0,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.GothamBold,
                        ZIndex = 64
                    })
                }) or nil
            }),
            
            -- Progress Bar (at bottom of main panel)
            ProgressContainer = e("Frame", {
                Name = "ProgressContainer",
                Size = UDim2.new(1, -20, 0, 20),
                Position = UDim2.new(0, 10, 1, -25),
                BackgroundTransparency = 1,
                ZIndex = 62
            }, {
                ProgressBG = e("Frame", {
                    Name = "ProgressBackground",
                    Size = UDim2.new(1, 0, 0, 6),
                    Position = UDim2.new(0, 0, 0, 7),
                    BackgroundColor3 = Color3.fromRGB(200, 210, 230),
                    BorderSizePixel = 0,
                    ZIndex = 62
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 3)
                    }),
                    ProgressFill = e("Frame", {
                        Name = "ProgressFill",
                        Size = UDim2.new(stepNumber / totalSteps, 0, 1, 0),
                        Position = UDim2.new(0, 0, 0, 0),
                        BackgroundColor3 = Color3.fromRGB(100, 150, 255),
                        BorderSizePixel = 0,
                        ZIndex = 63
                    }, {
                        Corner = e("UICorner", {
                            CornerRadius = UDim.new(0, 3)
                        }),
                        Gradient = e("UIGradient", {
                            Color = ColorSequence.new{
                                ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 180, 255)),
                                ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 140, 255))
                            }
                        })
                    })
                })
            }),
            
            -- Skip Confirmation Dialog
            SkipConfirmDialog = showSkipConfirm and e("Frame", {
                Name = "SkipConfirmDialog",
                Size = UDim2.new(0, 280, 0, 120),
                Position = UDim2.new(0.5, -140, 0.5, -60),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                ZIndex = 70
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 12)
                }),
                Stroke = e("UIStroke", {
                    Color = Color3.fromRGB(255, 100, 100),
                    Thickness = 3,
                    Transparency = 0.1
                }),
                Gradient = e("UIGradient", {
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(250, 245, 245))
                    },
                    Rotation = 135
                }),
                
                -- Warning Title
                WarningTitle = e("TextLabel", {
                    Size = UDim2.new(1, -20, 0, 25),
                    Position = UDim2.new(0, 10, 0, 10),
                    Text = "⚠️ Skip Tutorial?",
                    TextColor3 = Color3.fromRGB(200, 50, 50),
                    TextScaled = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 71
                }),
                
                -- Warning Message
                WarningMessage = e("TextLabel", {
                    Size = UDim2.new(1, -20, 0, 40),
                    Position = UDim2.new(0, 10, 0, 35),
                    Text = "You'll miss out on " .. totalTutorialRewards .. " coins in tutorial rewards and can't get them back. Are you sure?",
                    TextColor3 = Color3.fromRGB(80, 80, 80),
                    TextSize = 12,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    TextWrapped = true,
                    ZIndex = 71
                }),
                
                -- Cancel Button
                CancelButton = e("TextButton", {
                    Size = UDim2.new(0, 80, 0, 25),
                    Position = UDim2.new(0, 40, 1, -35),
                    Text = "",
                    BackgroundColor3 = Color3.fromRGB(150, 150, 150),
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    ZIndex = 72,
                    [React.Event.Activated] = handleSkipCancel
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 6)
                    }),
                    CancelText = e("TextLabel", {
                        Size = UDim2.new(1, 0, 1, 0),
                        Text = "Cancel",
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = 12,
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        TextStrokeTransparency = 0,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.GothamBold,
                        ZIndex = 73
                    })
                }),
                
                -- Confirm Skip Button
                ConfirmButton = e("TextButton", {
                    Size = UDim2.new(0, 80, 0, 25),
                    Position = UDim2.new(1, -120, 1, -35),
                    Text = "",
                    BackgroundColor3 = Color3.fromRGB(200, 50, 50),
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    ZIndex = 72,
                    [React.Event.Activated] = handleSkipConfirm
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 6)
                    }),
                    ConfirmText = e("TextLabel", {
                        Size = UDim2.new(1, 0, 1, 0),
                        Text = "Skip",
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = 12,
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        TextStrokeTransparency = 0,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.GothamBold,
                        ZIndex = 73
                    })
                })
            }) or nil
        })
    })
end

return TutorialPanel