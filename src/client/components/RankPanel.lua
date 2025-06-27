-- Rank Panel Component
-- Shows player's current rank and progression

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local RankConfig = require(game:GetService("ReplicatedStorage").Shared.RankConfig)
local e = React.createElement

local function RankPanel(props)
    local playerData = props.playerData
    local onClose = props.onClose
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    
    -- Responsive design
    local isMobile = screenSize.X < 768
    local scale = isMobile and 0.9 or 1
    local panelWidth = isMobile and screenSize.X * 0.95 or math.min(screenSize.X * 0.7, 800)
    local panelHeight = isMobile and screenSize.Y * 0.8 or math.min(screenSize.Y * 0.8, 600)
    
    if not playerData then
        return nil
    end
    
    local rebirths = playerData.rebirths or 0
    local currentRank = RankConfig.getRankForRebirths(rebirths)
    local nextRank, rebirthsNeeded = RankConfig.getNextRank(rebirths)
    local progress = RankConfig.getRankProgress(rebirths)
    local tier = RankConfig.getRankTier(rebirths)
    
    -- Get all ranks for display
    local allRanks = RankConfig.getAllRanks()
    
    return e("Frame", {
        Name = "RankPanel",
        Size = UDim2.new(0, panelWidth, 0, panelHeight),
        Position = UDim2.new(0.5, -panelWidth/2, 0.5, -panelHeight/2),
        BackgroundColor3 = Color3.fromRGB(20, 25, 35),
        BorderSizePixel = 0,
        ZIndex = 15
    }, {
        Corner = e("UICorner", {
            CornerRadius = UDim.new(0, 12)
        }),
        
        Stroke = e("UIStroke", {
            Color = currentRank.color,
            Thickness = 3,
            Transparency = 0.3
        }),
        
        -- Title bar
        TitleBar = e("Frame", {
            Name = "TitleBar", 
            Size = UDim2.new(1, 0, 0, 60),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = currentRank.color,
            BorderSizePixel = 0,
            ZIndex = 16
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 12)
            }),
            
            -- Title text
            Title = e("TextLabel", {
                Size = UDim2.new(1, -120, 1, 0),
                Position = UDim2.new(0, 20, 0, 0),
                BackgroundTransparency = 1,
                Text = "🏆 Player Ranks",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                Font = Enum.Font.SourceSansBold,
                TextStrokeTransparency = 0,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                ZIndex = 17
            }, {
                TextSizeConstraint = e("UITextSizeConstraint", {
                    MaxTextSize = 24,
                    MinTextSize = 16
                })
            }),
            
            -- Close button
            CloseButton = e("TextButton", {
                Size = UDim2.new(0, 40, 0, 40),
                Position = UDim2.new(1, -50, 0.5, -20),
                BackgroundColor3 = Color3.fromRGB(220, 60, 60),
                BorderSizePixel = 0,
                Text = "✕",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 17,
                [React.Event.Activated] = onClose
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 8)
                })
            })
        }),
        
        -- Current rank section
        CurrentRankSection = e("Frame", {
            Name = "CurrentRankSection",
            Size = UDim2.new(1, -20, 0, 120),
            Position = UDim2.new(0, 10, 0, 70),
            BackgroundColor3 = Color3.fromRGB(30, 35, 45),
            BorderSizePixel = 0,
            ZIndex = 16
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 8)
            }),
            
            Stroke = e("UIStroke", {
                Color = currentRank.color,
                Thickness = 2,
                Transparency = 0.5
            }),
            
            -- Current rank display
            CurrentRankFrame = e("Frame", {
                Size = UDim2.new(0.5, -10, 1, -20),
                Position = UDim2.new(0, 10, 0, 10),
                BackgroundTransparency = 1,
                ZIndex = 17
            }, {
                RankLabel = e("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 30),
                    Position = UDim2.new(0, 0, 0, 0),
                    BackgroundTransparency = 1,
                    Text = "Current Rank:",
                    TextColor3 = Color3.fromRGB(200, 200, 200),
                    TextScaled = true,
                    Font = Enum.Font.SourceSans,
                    ZIndex = 18
                }),
                
                RankName = e("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 40),
                    Position = UDim2.new(0, 0, 0, 25),
                    BackgroundTransparency = 1,
                    Text = currentRank.name,
                    TextColor3 = currentRank.color,
                    TextScaled = true,
                    Font = Enum.Font.SourceSansBold,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 18
                }),
                
                RebirthCount = e("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 25),
                    Position = UDim2.new(0, 0, 0, 65),
                    BackgroundTransparency = 1,
                    Text = "🔄 " .. rebirths .. " Rebirths | " .. tier .. " Tier",
                    TextColor3 = Color3.fromRGB(150, 150, 150),
                    TextScaled = true,
                    Font = Enum.Font.SourceSans,
                    ZIndex = 18
                })
            }),
            
            -- Progress section
            ProgressFrame = e("Frame", {
                Size = UDim2.new(0.5, -10, 1, -20),
                Position = UDim2.new(0.5, 0, 0, 10),
                BackgroundTransparency = 1,
                ZIndex = 17
            }, {
                ProgressLabel = e("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 30),
                    Position = UDim2.new(0, 0, 0, 0),
                    BackgroundTransparency = 1,
                    Text = nextRank and "Next Rank:" or "MAX RANK!",
                    TextColor3 = Color3.fromRGB(200, 200, 200),
                    TextScaled = true,
                    Font = Enum.Font.SourceSans,
                    ZIndex = 18
                }),
                
                NextRankName = nextRank and e("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 30),
                    Position = UDim2.new(0, 0, 0, 25),
                    BackgroundTransparency = 1,
                    Text = nextRank.name,
                    TextColor3 = nextRank.color,
                    TextScaled = true,
                    Font = Enum.Font.SourceSansBold,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 18
                }) or nil,
                
                ProgressBarBG = nextRank and e("Frame", {
                    Size = UDim2.new(1, 0, 0, 15),
                    Position = UDim2.new(0, 0, 0, 55),
                    BackgroundColor3 = Color3.fromRGB(50, 50, 50),
                    BorderSizePixel = 0,
                    ZIndex = 18
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 4)
                    }),
                    
                    ProgressBar = e("Frame", {
                        Size = UDim2.new(progress / 100, 0, 1, 0),
                        Position = UDim2.new(0, 0, 0, 0),
                        BackgroundColor3 = nextRank.color,
                        BorderSizePixel = 0,
                        ZIndex = 19
                    }, {
                        Corner = e("UICorner", {
                            CornerRadius = UDim.new(0, 4)
                        })
                    })
                }) or nil,
                
                ProgressText = nextRank and e("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 20),
                    Position = UDim2.new(0, 0, 0, 75),
                    BackgroundTransparency = 1,
                    Text = rebirthsNeeded .. " more rebirths (" .. progress .. "%)",
                    TextColor3 = Color3.fromRGB(150, 150, 150),
                    TextScaled = true,
                    Font = Enum.Font.SourceSans,
                    ZIndex = 18
                }) or e("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 40),
                    Position = UDim2.new(0, 0, 0, 50),
                    BackgroundTransparency = 1,
                    Text = "🌟 You've reached the highest rank!",
                    TextColor3 = Color3.fromRGB(255, 215, 0),
                    TextScaled = true,
                    Font = Enum.Font.SourceSansBold,
                    ZIndex = 18
                })
            })
        }),
        
        -- Scrollable rank list
        ScrollFrame = e("ScrollingFrame", {
            Name = "RankScrollFrame",
            Size = UDim2.new(1, -20, 1, -200),
            Position = UDim2.new(0, 10, 0, 200),
            BackgroundColor3 = Color3.fromRGB(25, 30, 40),
            BorderSizePixel = 0,
            ScrollBarThickness = 8,
            ScrollBarImageColor3 = currentRank.color,
            CanvasSize = UDim2.new(0, 0, 0, #allRanks * 45 + 20),
            ZIndex = 16
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 8)
            }),
            
            Layout = e("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 5),
                HorizontalAlignment = Enum.HorizontalAlignment.Center
            }),
            
            Padding = e("UIPadding", {
                PaddingTop = UDim.new(0, 10),
                PaddingBottom = UDim.new(0, 10),
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10)
            })
        }, React.createElement(React.Fragment, {}, 
            (function()
                local rankElements = {}
                
                for i, rank in ipairs(allRanks) do
                    local isCurrentRank = rank.threshold <= rebirths and 
                        (i == #allRanks or allRanks[i + 1].threshold > rebirths)
                    local isUnlocked = rank.threshold <= rebirths
                    
                    rankElements["Rank" .. i] = e("Frame", {
                        Size = UDim2.new(1, -20, 0, 35),
                        BackgroundColor3 = isCurrentRank and rank.color or 
                            (isUnlocked and Color3.fromRGB(40, 50, 60) or Color3.fromRGB(30, 30, 30)),
                        BackgroundTransparency = isCurrentRank and 0.2 or 0.1,
                        BorderSizePixel = 0,
                        LayoutOrder = i,
                        ZIndex = 17
                    }, {
                        Corner = e("UICorner", {
                            CornerRadius = UDim.new(0, 6)
                        }),
                        
                        Stroke = isCurrentRank and e("UIStroke", {
                            Color = rank.color,
                            Thickness = 2,
                            Transparency = 0
                        }) or nil,
                        
                        RankInfo = e("TextLabel", {
                            Size = UDim2.new(1, -10, 1, 0),
                            Position = UDim2.new(0, 5, 0, 0),
                            BackgroundTransparency = 1,
                            Text = rank.name .. " (" .. rank.threshold .. " rebirths)" .. 
                                (isCurrentRank and " - CURRENT" or "") ..
                                (not isUnlocked and " - LOCKED" or ""),
                            TextColor3 = isUnlocked and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(100, 100, 100),
                            TextScaled = true,
                            Font = isCurrentRank and Enum.Font.SourceSansBold or Enum.Font.SourceSans,
                            TextStrokeTransparency = 0,
                            TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                            ZIndex = 18
                        })
                    })
                end
                
                return rankElements
            end)()
        ))
    })
end

return RankPanel