-- Tutorial Panel Component
-- Shows tutorial steps in bottom right with skip option

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local e = React.createElement

local function TutorialPanel(props)
    local tutorialData = props.tutorialData
    local visible = props.visible or false
    local onNext = props.onNext or function() end
    local onSkip = props.onSkip or function() end
    
    if not tutorialData or not tutorialData.step then
        return nil
    end
    
    local step = tutorialData.step
    local stepNumber = tutorialData.stepNumber or 1
    local totalSteps = tutorialData.totalSteps or 10
    
    -- Responsive sizing
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local isMobile = screenSize.X < 768
    local scale = isMobile and 0.85 or 1
    local panelWidth = isMobile and 280 or 300
    local panelHeight = isMobile and 180 or 200
    
    return e("Frame", {
        Name = "TutorialPanel",
        Size = UDim2.new(0, panelWidth * scale, 0, panelHeight * scale),
        Position = UDim2.new(1, -(panelWidth + 20) * scale, 1, -(panelHeight + 20) * scale), -- Back to bottom-right
        BackgroundColor3 = Color3.fromRGB(25, 25, 35),
        BackgroundTransparency = visible and 0.05 or 1,
        BorderSizePixel = 0,
        Visible = visible,
        ZIndex = 60 -- Above LogLevelPanel (50-52) but not excessive
    }, {
        Corner = e("UICorner", {
            CornerRadius = UDim.new(0, 10)
        }),
        Stroke = e("UIStroke", {
            Color = Color3.fromRGB(100, 200, 255),
            Thickness = 2,
            Transparency = 0.3
        }),
        Gradient = e("UIGradient", {
            Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 50)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 35))
            },
            Rotation = 90
        }),
        
        -- Progress Bar Background
        ProgressBG = e("Frame", {
            Name = "ProgressBackground",
            Size = UDim2.new(1, -20, 0, 4),
            Position = UDim2.new(0, 10, 0, 8),
            BackgroundColor3 = Color3.fromRGB(50, 50, 50),
            BorderSizePixel = 0,
            ZIndex = 61
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 2)
            }),
            -- Progress Bar Fill
            ProgressFill = e("Frame", {
                Name = "ProgressFill",
                Size = UDim2.new(stepNumber / totalSteps, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundColor3 = Color3.fromRGB(100, 200, 255),
                BorderSizePixel = 0,
                ZIndex = 62
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 2)
                }),
                Gradient = e("UIGradient", {
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 220, 255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 180, 255))
                    }
                })
            })
        }),
        
        -- Step Counter
        StepCounter = e("TextLabel", {
            Name = "StepCounter",
            Size = UDim2.new(0, 80, 0, 20),
            Position = UDim2.new(1, -90, 0, 18),
            Text = "Step " .. stepNumber .. "/" .. totalSteps,
            TextColor3 = Color3.fromRGB(150, 150, 150),
            TextScaled = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSans,
            ZIndex = 63
        }),
        
        -- Title
        Title = e("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, -20, 0, 30),
            Position = UDim2.new(0, 10, 0, 25),
            Text = step.title,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextScaled = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSansBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 63
        }),
        
        -- Description
        Description = e("TextLabel", {
            Name = "Description",
            Size = UDim2.new(1, -20, 0, 30),
            Position = UDim2.new(0, 10, 0, 55),
            Text = step.description,
            TextColor3 = Color3.fromRGB(200, 200, 200),
            TextScaled = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSans,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            ZIndex = 63
        }),
        
        -- Instruction
        Instruction = e("TextLabel", {
            Name = "Instruction",
            Size = UDim2.new(1, -20, 0, 25),
            Position = UDim2.new(0, 10, 0, 90),
            Text = step.instruction,
            TextColor3 = Color3.fromRGB(100, 200, 255),
            TextScaled = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSansBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            ZIndex = 63
        }),
        
        -- Reward Display (positioned before buttons to avoid overlap)
        RewardDisplay = step.reward and step.reward.money > 0 and e("TextLabel", {
            Name = "RewardDisplay",
            Size = UDim2.new(1, -20, 0, 18),
            Position = UDim2.new(0, 10, 0, 120),
            Text = "💰 +" .. step.reward.money,
            TextColor3 = Color3.fromRGB(255, 215, 0),
            TextScaled = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSansBold,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 63
        }) or nil,
        
        -- Buttons Frame
        ButtonsFrame = e("Frame", {
            Name = "ButtonsFrame",
            Size = UDim2.new(1, -20, 0, 30),
            Position = UDim2.new(0, 10, 0, 145),
            BackgroundTransparency = 1,
            ZIndex = 63
        }, {
            -- Skip Button
            SkipButton = e("TextButton", {
                Name = "SkipButton",
                Size = UDim2.new(0, 50, 0, 25),
                Position = UDim2.new(0, 0, 0, 0),
                Text = "Skip",
                TextColor3 = Color3.fromRGB(255, 150, 150),
                TextScaled = true,
                BackgroundColor3 = Color3.fromRGB(80, 40, 40),
                BorderSizePixel = 0,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 64,
                [React.Event.Activated] = onSkip
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 6)
                }),
                Stroke = e("UIStroke", {
                    Color = Color3.fromRGB(255, 100, 100),
                    Thickness = 1,
                    Transparency = 0.5
                })
            }),
            
            
            -- Next Button (conditional)
            NextButton = step.action == "continue" and e("TextButton", {
                Name = "NextButton",
                Size = UDim2.new(0, 60, 0, 25),
                Position = UDim2.new(1, -60, 0, 0),
                Text = step.id == "complete" and "Done" or "Next",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                BackgroundColor3 = Color3.fromRGB(40, 120, 40),
                BorderSizePixel = 0,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 64,
                [React.Event.Activated] = onNext
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 6)
                }),
                Stroke = e("UIStroke", {
                    Color = Color3.fromRGB(100, 255, 100),
                    Thickness = 1,
                    Transparency = 0.5
                }),
                Gradient = e("UIGradient", {
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 140, 60)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 120, 40))
                    },
                    Rotation = 90
                })
            }) or nil
        })
    })
end

return TutorialPanel