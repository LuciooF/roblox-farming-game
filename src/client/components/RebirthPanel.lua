-- Modern Rebirth Panel Component
-- Shows current rebirth status, benefits, and next rebirth preview

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local e = React.createElement
local assets = require(game:GetService("ReplicatedStorage").Shared.assets)
local NumberFormatter = require(game:GetService("ReplicatedStorage").Shared.NumberFormatter)
local ScreenUtils = require(game:GetService("ReplicatedStorage").Shared.ScreenUtils)

-- Simple logging functions for RebirthPanel
local function logInfo(...) print("[INFO] RebirthPanel:", ...) end
local function logWarn(...) warn("[WARN] RebirthPanel:", ...) end

local function RebirthPanel(props)
    local playerData = props.playerData
    local visible = props.visible or false
    local onClose = props.onClose or function() end
    local remotes = props.remotes or {}
    
    -- Calculate rebirth data
    local currentRebirths = playerData.rebirths or 0
    local currentMultiplier = 1 + (currentRebirths * 0.5)
    local nextRebirths = currentRebirths + 1
    local nextMultiplier = 1 + (nextRebirths * 0.5)
    local rebirthCost = math.floor(1000 * (2.5 ^ currentRebirths))
    local canAfford = playerData.money >= rebirthCost
    local progress = math.min((playerData.money / rebirthCost) * 100, 100)
    
    -- Calculate dates
    local currentDate = os.date("*t")
    local achievedDate = currentRebirths > 0 and os.date("%B %d, %Y") or "Not achieved yet"
    
    -- Smarter prediction based on progress
    local function calculatePrediction()
        if canAfford then
            return "Today!", "You can afford it now!"
        end
        
        if progress <= 0 then
            return "Tomorrow", "No progress yet, assuming 1 day"
        end
        
        -- Estimate based on current progress (assume linear progression)
        -- If they have X% progress, estimate they'll need (100-X)/X times as long to finish
        local remainingProgress = 100 - progress
        local estimatedDays = math.max(1, math.ceil(remainingProgress / math.max(progress, 1)))
        
        local explanation = string.format("Based on %.1f%% progress", progress)
        
        if estimatedDays == 1 then
            return "Tomorrow", explanation
        elseif estimatedDays <= 7 then
            return "In " .. estimatedDays .. " days", explanation
        else
            return "In 1 week+", "More than a week needed"
        end
    end
    
    local nextDateText, predictionExplanation = calculatePrediction()
    
    -- Responsive sizing
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local scale = ScreenUtils.getProportionalScale(screenSize)
    local panelWidth = math.min(screenSize.X * 0.9, ScreenUtils.getProportionalSize(screenSize, 900))
    local panelHeight = math.min(screenSize.Y * 0.85, ScreenUtils.getProportionalSize(screenSize, 650))
    
    -- Proportional text sizes
    local titleTextSize = ScreenUtils.getProportionalTextSize(screenSize, 32)
    local normalTextSize = ScreenUtils.getProportionalTextSize(screenSize, 18)
    local smallTextSize = ScreenUtils.getProportionalTextSize(screenSize, 14)
    local buttonTextSize = ScreenUtils.getProportionalTextSize(screenSize, 22) -- Bigger button text
    local cardTitleSize = ScreenUtils.getProportionalTextSize(screenSize, 20)
    local cardValueSize = ScreenUtils.getProportionalTextSize(screenSize, 24) -- Bigger for rebirth numbers and boosts
    local largeValueSize = ScreenUtils.getProportionalTextSize(screenSize, 28) -- Even bigger for main rebirth count
    
    -- Handle rebirth action
    local function handleRebirth()
        if canAfford and remotes.rebirthRemote then
            remotes.rebirthRemote:FireServer()
            onClose()
        end
    end
    
    -- Handle Robux rebirth purchase
    local function handleRobuxRebirth()
        local REBIRTH_PRODUCT_ID = 3320263208
        
        -- Prompt the purchase
        local success, error = pcall(function()
            MarketplaceService:PromptProductPurchase(game.Players.LocalPlayer, REBIRTH_PRODUCT_ID)
        end)
        
        if not success then
            warn("Failed to prompt Robux rebirth purchase:", error)
        end
    end
    
    -- Get Robux price for the developer product
    local robuxPrice, setRobuxPrice = React.useState("...")
    
    React.useEffect(function()
        local success, productInfo = pcall(function()
            return MarketplaceService:GetProductInfo(3320263208, Enum.InfoType.Product)
        end)
        
        if success and productInfo then
            setRobuxPrice(productInfo.PriceInRobux or "?")
        else
            setRobuxPrice("?")
        end
    end, {})
    
    return e("Frame", {
        Name = "RebirthContainer",
        Size = UDim2.new(0, panelWidth, 0, panelHeight + 50),
        Position = UDim2.new(0.5, -panelWidth / 2, 0.5, -(panelHeight + 50) / 2),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = visible,
        ZIndex = 30
    }, {
        
        RebirthPanel = e("Frame", {
            Name = "RebirthPanel",
            Size = UDim2.new(0, panelWidth, 0, panelHeight),
            Position = UDim2.new(0, 0, 0, 50),
            BackgroundColor3 = Color3.fromRGB(240, 245, 255),
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
            ZIndex = 30
        }, {
            -- Floating Title
            FloatingTitle = e("Frame", {
                Name = "FloatingTitle",
                Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 200), 0, ScreenUtils.getProportionalSize(screenSize, 40)),
                Position = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, -10), 0, ScreenUtils.getProportionalSize(screenSize, -25)),
                BackgroundColor3 = Color3.fromRGB(255, 140, 0),
                BorderSizePixel = 0,
                ZIndex = 32
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 12)
                }),
                Gradient = e("UIGradient", {
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 180, 50)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 120, 0))
                    },
                    Rotation = 45
                }),
                Stroke = e("UIStroke", {
                    Color = Color3.fromRGB(255, 255, 255),
                    Thickness = 3,
                    Transparency = 0.2
                }),
                TitleContent = e("Frame", {
                    Size = UDim2.new(1, -10, 1, 0),
                    Position = UDim2.new(0, 5, 0, 0),
                    BackgroundTransparency = 1,
                    ZIndex = 33
                }, {
                    Layout = e("UIListLayout", {
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        Padding = UDim.new(0, 5),
                        SortOrder = Enum.SortOrder.LayoutOrder
                    }),
                    
                    RebirthIcon = e("ImageLabel", {
                        Name = "RebirthIcon",
                        Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 24), 0, ScreenUtils.getProportionalSize(screenSize, 24)),
                        Image = assets["General/Rebirth/Rebirth Outline 256.png"] or "",
                        BackgroundTransparency = 1,
                        ScaleType = Enum.ScaleType.Fit,
                        ImageColor3 = Color3.fromRGB(255, 255, 255),
                        ZIndex = 34,
                        LayoutOrder = 1
                    }),
                    
                    TitleText = e("TextLabel", {
                        Size = UDim2.new(0, 0, 1, 0),
                        AutomaticSize = Enum.AutomaticSize.X,
                        Text = "REBIRTHS",
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = normalTextSize,
            TextWrapped = true,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.GothamBold,
                        ZIndex = 34,
                        LayoutOrder = 2
                    }, {
                        TextStroke = e("UIStroke", {
                            Color = Color3.fromRGB(0, 0, 0),
                            Thickness = 2,
                            Transparency = 0.5
                        })
                    })
                })
            }),
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 20)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(255, 140, 0),
                Thickness = 3,
                Transparency = 0.1
            }),
            Gradient = e("UIGradient", {
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(0.3, Color3.fromRGB(250, 245, 255)),
                    ColorSequenceKeypoint.new(0.7, Color3.fromRGB(245, 240, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(240, 235, 255))
                },
                Rotation = 135
            }),
            
            -- Close Button
            CloseButton = e("ImageButton", {
                Name = "CloseButton",
                Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 32), 0, ScreenUtils.getProportionalSize(screenSize, 32)),
                Position = UDim2.new(1, ScreenUtils.getProportionalSize(screenSize, -16), 0, ScreenUtils.getProportionalSize(screenSize, -16)),
                Image = assets["X Button/X Button 64.png"],
                ImageColor3 = Color3.fromRGB(255, 255, 255),
                ScaleType = Enum.ScaleType.Fit,
                BackgroundColor3 = Color3.fromRGB(255, 100, 100),
                BorderSizePixel = 0,
                ZIndex = 34,
                [React.Event.Activated] = onClose
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 6)
                }),
                Gradient = e("UIGradient", {
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 140, 140)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 60, 60))
                    },
                    Rotation = 90
                }),
                Stroke = e("UIStroke", {
                    Color = Color3.fromRGB(255, 255, 255),
                    Thickness = 2,
                    Transparency = 0.2
                })
            }),
            
            -- Main Content
            MainContent = e("Frame", {
                Name = "MainContent",
                Size = UDim2.new(1, ScreenUtils.getProportionalSize(screenSize, -40), 1, ScreenUtils.getProportionalSize(screenSize, -80)),
                Position = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 20), 0, ScreenUtils.getProportionalSize(screenSize, 40)),
                BackgroundTransparency = 1,
                ZIndex = 31
            }, {
                -- Info Text
                InfoText = e("TextLabel", {
                    Size = UDim2.new(1, 0, 0, ScreenUtils.getProportionalSize(screenSize, 40)),
                    Position = UDim2.new(0, 0, 0, 0),
                    Text = "🌟 Rebirth resets your progress but gives you permanent stacking benefits! 🌟",
                    TextColor3 = Color3.fromRGB(100, 50, 150),
                    TextSize = titleTextSize,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextWrapped = true,
                    ZIndex = 32
                }),
                
                -- Stats Container
                StatsContainer = e("Frame", {
                    Size = UDim2.new(1, 0, 0.6, ScreenUtils.getProportionalSize(screenSize, -50)),
                    Position = UDim2.new(0, 0, 0, ScreenUtils.getProportionalSize(screenSize, 50)),
                    BackgroundTransparency = 1,
                    ZIndex = 31
                }, {
                    -- Current Stats
                    CurrentStats = e("Frame", {
                        Size = UDim2.new(0.4, -10, 1, 0),
                        Position = UDim2.new(0, 0, 0, 0),
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        BackgroundTransparency = 0.1,
                        BorderSizePixel = 0,
                        ZIndex = 32
                    }, {
                        Corner = e("UICorner", {
                            CornerRadius = UDim.new(0, 15)
                        }),
                        Stroke = e("UIStroke", {
                            Color = Color3.fromRGB(200, 150, 255),
                            Thickness = 2,
                            Transparency = 0.3
                        }),
                        
                        Title = e("TextLabel", {
                            Size = UDim2.new(1, 0, 0, 30),
                            Position = UDim2.new(0, 0, 0, 10),
                            Text = "CURRENT STATUS",
                            TextColor3 = Color3.fromRGB(150, 100, 200),
                            TextSize = normalTextSize,
            TextWrapped = true,
                            BackgroundTransparency = 1,
                            Font = Enum.Font.GothamBold,
                            ZIndex = 33
                        }),
                        
                        RebirthCount = e("Frame", {
                            Size = UDim2.new(1, -20, 0, 40),
                            Position = UDim2.new(0, 10, 0, 50),
                            BackgroundTransparency = 1,
                            ZIndex = 33
                        }, {
                            Layout = e("UIListLayout", {
                                FillDirection = Enum.FillDirection.Horizontal,
                                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                                VerticalAlignment = Enum.VerticalAlignment.Center,
                                Padding = UDim.new(0, 10)
                            }),
                            
                            RebirthIcon = e("ImageLabel", {
                                Size = UDim2.new(0, 35, 0, 35),
                                Image = assets["General/Rebirth/Rebirth Outline 256.png"] or "",
                                BackgroundTransparency = 1,
                                ScaleType = Enum.ScaleType.Fit,
                                ZIndex = 34
                            }),
                            
                            RebirthText = e("TextLabel", {
                                Size = UDim2.new(0, 0, 1, 0),
                                AutomaticSize = Enum.AutomaticSize.X,
                                Text = tostring(currentRebirths),
                                TextColor3 = Color3.fromRGB(255, 255, 255),
                                TextSize = largeValueSize,
                                TextWrapped = true,
                                BackgroundTransparency = 1,
                                Font = Enum.Font.GothamBold,
                                ZIndex = 34
                            }, {
                                TextStroke = e("UIStroke", {
                                    Color = Color3.fromRGB(0, 0, 0),
                                    Thickness = 2,
                                    Transparency = 0
                                })
                            })
                        }),
                        
                        Benefits = e("Frame", {
                            Size = UDim2.new(1, -20, 0, 40),
                            Position = UDim2.new(0, 10, 0, 95),
                            BackgroundTransparency = 1,
                            ZIndex = 33
                        }, {
                            Layout = e("UIListLayout", {
                                FillDirection = Enum.FillDirection.Horizontal,
                                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                                VerticalAlignment = Enum.VerticalAlignment.Center,
                                Padding = UDim.new(0, 5)
                            }),
                            
                            BenefitIcon = e("ImageLabel", {
                                Size = UDim2.new(0, 30, 0, 30),
                                Image = assets["General/Upgrade/Upgrade Outline 256.png"] or "",
                                BackgroundTransparency = 1,
                                ScaleType = Enum.ScaleType.Fit,
                                ImageColor3 = Color3.fromRGB(255, 200, 0),
                                ZIndex = 34
                            }),
                            
                            BenefitText = e("TextLabel", {
                                Size = UDim2.new(0, 0, 1, 0),
                                AutomaticSize = Enum.AutomaticSize.X,
                                Text = string.format("%.1fx Boost", currentMultiplier),
                                TextColor3 = Color3.fromRGB(255, 255, 255),
                                TextSize = cardValueSize,
                                TextWrapped = true,
                                BackgroundTransparency = 1,
                                Font = Enum.Font.GothamBold,
                                ZIndex = 34
                            }, {
                                TextStroke = e("UIStroke", {
                                    Color = Color3.fromRGB(0, 0, 0),
                                    Thickness = 2,
                                    Transparency = 0
                                })
                            })
                        }),
                        
                        DateAchieved = e("TextLabel", {
                            Size = UDim2.new(1, -20, 0, 30),
                            Position = UDim2.new(0, 10, 0, 145),
                            Text = "Achieved: " .. achievedDate,
                            TextColor3 = Color3.fromRGB(100, 100, 100),
                            TextSize = normalTextSize,
                            BackgroundTransparency = 1,
                            Font = Enum.Font.Gotham,
                            TextXAlignment = Enum.TextXAlignment.Center,
                            ZIndex = 33
                        })
                    }),
                    
                    -- Arrow
                    Arrow = e("ImageLabel", {
                        Size = UDim2.new(0, 60, 0, 60),
                        Position = UDim2.new(0.5, -30, 0.5, -30),
                        Image = assets["ui/Arrow 2/Arrow 2 Right Outline 256.png"] or "rbxasset://textures/ui/Controls/RotateRight.png",
                        BackgroundTransparency = 1,
                        ScaleType = Enum.ScaleType.Fit,
                        ImageColor3 = Color3.fromRGB(255, 140, 0),
                        ZIndex = 35
                    }),
                    
                    -- Next Stats
                    NextStats = e("Frame", {
                        Size = UDim2.new(0.4, -10, 1, 0),
                        Position = UDim2.new(0.6, 10, 0, 0),
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        BackgroundTransparency = 0.1,
                        BorderSizePixel = 0,
                        ZIndex = 32
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
                                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 245, 200)),
                                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 235, 150))
                            },
                            Rotation = 90
                        }),
                        
                        -- Shiny effect
                        ShineEffect = e("Frame", {
                            Size = UDim2.new(0.3, 0, 1, 0),
                            Position = UDim2.new(-0.3, 0, 0, 0),
                            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                            BackgroundTransparency = 0.7,
                            BorderSizePixel = 0,
                            ZIndex = 35
                        }, {
                            Corner = e("UICorner", {
                                CornerRadius = UDim.new(0, 15)
                            }),
                            Gradient = e("UIGradient", {
                                Color = ColorSequence.new{
                                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
                                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
                                },
                                Transparency = NumberSequence.new{
                                    NumberSequenceKeypoint.new(0, 1),
                                    NumberSequenceKeypoint.new(0.5, 0.3),
                                    NumberSequenceKeypoint.new(1, 1)
                                },
                                Rotation = 45
                            })
                        }),
                        
                        Title = e("TextLabel", {
                            Size = UDim2.new(1, 0, 0, 30),
                            Position = UDim2.new(0, 0, 0, 10),
                            Text = "NEXT REBIRTH",
                            TextColor3 = Color3.fromRGB(255, 150, 0),
                            TextSize = normalTextSize,
            TextWrapped = true,
                            BackgroundTransparency = 1,
                            Font = Enum.Font.GothamBold,
                            ZIndex = 33
                        }),
                        
                        NextRebirthCount = e("Frame", {
                            Size = UDim2.new(1, -20, 0, 40),
                            Position = UDim2.new(0, 10, 0, 50),
                            BackgroundTransparency = 1,
                            ZIndex = 33
                        }, {
                            Layout = e("UIListLayout", {
                                FillDirection = Enum.FillDirection.Horizontal,
                                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                                VerticalAlignment = Enum.VerticalAlignment.Center,
                                Padding = UDim.new(0, 10)
                            }),
                            
                            RebirthIcon = e("ImageLabel", {
                                Size = UDim2.new(0, 35, 0, 35),
                                Image = assets["General/Rebirth/Rebirth Outline 256.png"] or "",
                                BackgroundTransparency = 1,
                                ScaleType = Enum.ScaleType.Fit,
                                ZIndex = 34
                            }),
                            
                            RebirthText = e("TextLabel", {
                                Size = UDim2.new(0, 0, 1, 0),
                                AutomaticSize = Enum.AutomaticSize.X,
                                Text = tostring(nextRebirths),
                                TextColor3 = Color3.fromRGB(255, 255, 255),
                                TextSize = largeValueSize,
                                TextWrapped = true,
                                BackgroundTransparency = 1,
                                Font = Enum.Font.GothamBold,
                                ZIndex = 34
                            }, {
                                TextStroke = e("UIStroke", {
                                    Color = Color3.fromRGB(0, 0, 0),
                                    Thickness = 2,
                                    Transparency = 0
                                })
                            })
                        }),
                        
                        NextBenefits = e("Frame", {
                            Size = UDim2.new(1, -20, 0, 40),
                            Position = UDim2.new(0, 10, 0, 95),
                            BackgroundTransparency = 1,
                            ZIndex = 33
                        }, {
                            Layout = e("UIListLayout", {
                                FillDirection = Enum.FillDirection.Horizontal,
                                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                                VerticalAlignment = Enum.VerticalAlignment.Center,
                                Padding = UDim.new(0, 5)
                            }),
                            
                            BenefitIcon = e("ImageLabel", {
                                Size = UDim2.new(0, 30, 0, 30),
                                Image = assets["General/Upgrade/Upgrade Outline 256.png"] or "",
                                BackgroundTransparency = 1,
                                ScaleType = Enum.ScaleType.Fit,
                                ImageColor3 = Color3.fromRGB(255, 200, 0),
                                ZIndex = 34
                            }),
                            
                            BenefitText = e("TextLabel", {
                                Size = UDim2.new(0, 0, 1, 0),
                                AutomaticSize = Enum.AutomaticSize.X,
                                Text = string.format("%.1fx Boost", nextMultiplier),
                                TextColor3 = Color3.fromRGB(255, 255, 255),
                                TextSize = cardValueSize,
                                TextWrapped = true,
                                BackgroundTransparency = 1,
                                Font = Enum.Font.GothamBold,
                                ZIndex = 34
                            }, {
                                TextStroke = e("UIStroke", {
                                    Color = Color3.fromRGB(0, 0, 0),
                                    Thickness = 2,
                                    Transparency = 0
                                })
                            })
                        }),
                        
                        DatePredicted = e("TextLabel", {
                            Size = UDim2.new(1, -20, 0, 30),
                            Position = UDim2.new(0, 10, 0, 145),
                            Text = "Predicted: " .. nextDateText,
                            TextColor3 = Color3.fromRGB(100, 100, 100),
                            TextSize = normalTextSize,
                            BackgroundTransparency = 1,
                            Font = Enum.Font.Gotham,
                            TextXAlignment = Enum.TextXAlignment.Center,
                            ZIndex = 33
                        }),
                        
                        -- Prediction Explanation
                        PredictionExplanation = e("TextLabel", {
                            Size = UDim2.new(1, -20, 0, 20),
                            Position = UDim2.new(0, 10, 0, 175),
                            Text = predictionExplanation,
                            TextColor3 = Color3.fromRGB(120, 120, 120),
                            TextSize = smallTextSize,
                            BackgroundTransparency = 1,
                            Font = Enum.Font.Gotham,
                            TextXAlignment = Enum.TextXAlignment.Center,
                            ZIndex = 33
                        })
                    })
                }),
                
                -- Progress Section (fills bottom space)
                ProgressSection = e("Frame", {
                    Size = UDim2.new(1, 0, 0, 150),
                    Position = UDim2.new(0, 0, 1, -150),
                    BackgroundTransparency = 1,
                    ZIndex = 31
                }, {
                    ProgressTitle = e("TextLabel", {
                        Size = UDim2.new(1, 0, 0, 25),
                        Position = UDim2.new(0, 0, 0, 0),
                        Text = "Progress to Next Rebirth",
                        TextColor3 = Color3.fromRGB(100, 100, 100),
                        TextSize = normalTextSize,
            TextWrapped = true,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.GothamBold,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        ZIndex = 32
                    }),
                    
                    -- Progress Bar Background
                    ProgressBarBg = e("Frame", {
                        Size = UDim2.new(1, -60, 0, 30),
                        Position = UDim2.new(0, 30, 0, 35),
                        BackgroundColor3 = Color3.fromRGB(200, 200, 200),
                        BorderSizePixel = 0,
                        ZIndex = 32
                    }, {
                        Corner = e("UICorner", {
                            CornerRadius = UDim.new(0, 15)
                        }),
                        
                        -- Progress Bar Fill
                        ProgressFill = e("Frame", {
                            Size = UDim2.new(progress / 100, 0, 1, 0),
                            Position = UDim2.new(0, 0, 0, 0),
                            BackgroundColor3 = Color3.fromRGB(255, 200, 0),
                            BorderSizePixel = 0,
                            ZIndex = 33
                        }, {
                            Corner = e("UICorner", {
                                CornerRadius = UDim.new(0, 15)
                            }),
                            Gradient = e("UIGradient", {
                                Color = ColorSequence.new{
                                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 100)),
                                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 180, 0))
                                },
                                Rotation = 90
                            })
                        }),
                        
                        -- Progress Text
                        ProgressText = e("TextLabel", {
                            Size = UDim2.new(1, 0, 1, 0),
                            Text = string.format("%.1f%%", progress),
                            TextColor3 = Color3.fromRGB(255, 255, 255),
                            TextSize = normalTextSize,
            TextWrapped = true,
                            BackgroundTransparency = 1,
                            Font = Enum.Font.GothamBold,
                            ZIndex = 34
                        }, {
                            TextStroke = e("UIStroke", {
                                Color = Color3.fromRGB(0, 0, 0),
                                Thickness = 2,
                                Transparency = 0.5
                            })
                        })
                    }),
                    
                    -- Money Status
                    MoneyStatus = e("TextLabel", {
                        Size = UDim2.new(1, 0, 0, 20),
                        Position = UDim2.new(0, 0, 0, 70),
                        Text = "$" .. NumberFormatter.format(playerData.money) .. " / $" .. NumberFormatter.format(rebirthCost),
                        TextColor3 = Color3.fromRGB(100, 100, 100),
                        TextSize = normalTextSize,
            TextWrapped = true,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        ZIndex = 32
                    }),
                    
                    -- Rebirth Button (responsive width) - now smaller to make room for Robux button
                    RebirthButton = e("TextButton", {
                        Size = UDim2.new(0.48, -5, 0, 50),
                        Position = UDim2.new(0.02, 0, 0, 100),
                        Text = "",
                        BackgroundColor3 = canAfford and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(180, 80, 80),
                        BackgroundTransparency = canAfford and 0 or 0.3,
                        BorderSizePixel = 0,
                        AutoButtonColor = canAfford,
                        ZIndex = 32,
                        [React.Event.Activated] = canAfford and handleRebirth or nil
                    }, {
                        Corner = e("UICorner", {
                            CornerRadius = UDim.new(0, 10)
                        }),
                        Stroke = e("UIStroke", {
                            Color = canAfford and Color3.fromRGB(80, 160, 80) or Color3.fromRGB(120, 40, 40),
                            Thickness = 3,
                            Transparency = canAfford and 0.2 or 0.5
                        }),
                        Gradient = e("UIGradient", {
                            Color = canAfford and ColorSequence.new{
                                ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 220, 120)),
                                ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 180, 80))
                            } or ColorSequence.new{
                                ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 100, 100)),
                                ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 60, 60))
                            },
                            Rotation = 90
                        }),
                        
                        ButtonContent = e("Frame", {
                            Size = UDim2.new(1, 0, 1, 0),
                            BackgroundTransparency = 1,
                            ZIndex = 33
                        }, {
                            Layout = e("UIListLayout", {
                                FillDirection = Enum.FillDirection.Horizontal,
                                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                VerticalAlignment = Enum.VerticalAlignment.Center,
                                Padding = UDim.new(0, 10),
                                SortOrder = Enum.SortOrder.LayoutOrder
                            }),
                            
                            ButtonText = e("TextLabel", {
                                Size = UDim2.new(0, 0, 0.8, 0),
                                AutomaticSize = Enum.AutomaticSize.X,
                                Text = canAfford and "REBIRTH" or "NEED",
                                TextColor3 = Color3.fromRGB(255, 255, 255),
                                TextSize = buttonTextSize,
                                TextWrapped = true,
                                BackgroundTransparency = 1,
                                Font = Enum.Font.GothamBold,
                                ZIndex = 34,
                                LayoutOrder = 1
                            }, {
                                TextStroke = e("UIStroke", {
                                    Color = Color3.fromRGB(0, 0, 0),
                                    Thickness = 2,
                                    Transparency = 0
                                })
                            }),
                            
                            CashIcon = e("ImageLabel", {
                                Size = UDim2.new(0, 25, 0, 25),
                                Image = assets["Currency/Cash/Cash Outline 256.png"] or "",
                                BackgroundTransparency = 1,
                                ScaleType = Enum.ScaleType.Fit,
                                ImageColor3 = Color3.fromRGB(255, 255, 255),
                                ZIndex = 34,
                                LayoutOrder = 2
                            }),
                            
                            CostText = e("TextLabel", {
                                Size = UDim2.new(0, 0, 0.8, 0),
                                AutomaticSize = Enum.AutomaticSize.X,
                                Text = NumberFormatter.format(rebirthCost),
                                TextColor3 = Color3.fromRGB(255, 255, 255),
                                TextSize = buttonTextSize,
                                TextWrapped = true,
                                BackgroundTransparency = 1,
                                Font = Enum.Font.GothamBold,
                                ZIndex = 34,
                                LayoutOrder = 3
                            }, {
                                TextStroke = e("UIStroke", {
                                    Color = Color3.fromRGB(0, 0, 0),
                                    Thickness = 2,
                                    Transparency = 0
                                })
                            })
                        })
                    }),
                    
                    -- Robux Rebirth Button (instant rebirth for Robux)
                    RobuxRebirthButton = e("TextButton", {
                        Size = UDim2.new(0.48, -5, 0, 50),
                        Position = UDim2.new(0.52, 5, 0, 100),
                        Text = "",
                        BackgroundColor3 = Color3.fromRGB(100, 200, 100), -- Green color
                        BackgroundTransparency = 0,
                        BorderSizePixel = 0,
                        AutoButtonColor = true,
                        ZIndex = 32,
                        [React.Event.Activated] = handleRobuxRebirth
                    }, {
                        Corner = e("UICorner", {
                            CornerRadius = UDim.new(0, 10)
                        }),
                        Stroke = e("UIStroke", {
                            Color = Color3.fromRGB(80, 160, 80),
                            Thickness = 3,
                            Transparency = 0.2
                        }),
                        Gradient = e("UIGradient", {
                            Color = ColorSequence.new{
                                ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 220, 120)),
                                ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 180, 80))
                            },
                            Rotation = 90
                        }),
                        
                        ButtonContent = e("Frame", {
                            Size = UDim2.new(1, 0, 1, 0),
                            BackgroundTransparency = 1,
                            ZIndex = 33
                        }, {
                            Layout = e("UIListLayout", {
                                FillDirection = Enum.FillDirection.Horizontal,
                                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                VerticalAlignment = Enum.VerticalAlignment.Center,
                                Padding = UDim.new(0, 3),
                                SortOrder = Enum.SortOrder.LayoutOrder
                            }),
                            
                            RebirthIcon = e("ImageLabel", {
                                Size = UDim2.new(0, 18, 0, 18),
                                Image = assets["General/Rebirth/Rebirth Outline 256.png"],
                                BackgroundTransparency = 1,
                                ScaleType = Enum.ScaleType.Fit,
                                ImageColor3 = Color3.fromRGB(255, 255, 255),
                                ZIndex = 34,
                                LayoutOrder = 1
                            }),
                            
                            RobuxIcon = e("ImageLabel", {
                                Size = UDim2.new(0, 16, 0, 16),
                                Image = "rbxasset://textures/ui/common/robux.png",
                                BackgroundTransparency = 1,
                                ScaleType = Enum.ScaleType.Fit,
                                ImageColor3 = Color3.fromRGB(255, 255, 255),
                                ZIndex = 34,
                                LayoutOrder = 2
                            }),
                            
                            PriceText = e("TextLabel", {
                                Size = UDim2.new(0, 0, 0.7, 0),
                                AutomaticSize = Enum.AutomaticSize.X,
                                Text = robuxPrice,
                                TextColor3 = Color3.fromRGB(255, 255, 255),
                                TextSize = buttonTextSize * 0.8,
                                TextWrapped = true,
                                BackgroundTransparency = 1,
                                Font = Enum.Font.GothamBold,
                                ZIndex = 34,
                                LayoutOrder = 3
                            }, {
                                TextStroke = e("UIStroke", {
                                    Color = Color3.fromRGB(0, 0, 0),
                                    Thickness = 2,
                                    Transparency = 0
                                })
                            }),
                            
                            ButtonText = e("TextLabel", {
                                Size = UDim2.new(0, 0, 0.7, 0),
                                AutomaticSize = Enum.AutomaticSize.X,
                                Text = " Rebirth!",
                                TextColor3 = Color3.fromRGB(255, 255, 255),
                                TextSize = buttonTextSize * 0.8,
                                TextWrapped = true,
                                BackgroundTransparency = 1,
                                Font = Enum.Font.GothamBold,
                                ZIndex = 34,
                                LayoutOrder = 4
                            }, {
                                TextStroke = e("UIStroke", {
                                    Color = Color3.fromRGB(0, 0, 0),
                                    Thickness = 2,
                                    Transparency = 0
                                })
                            })
                        })
                    })
                })
            })
        })
    })
end

return RebirthPanel