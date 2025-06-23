-- Seed Detail Modal Component
-- Shows detailed information about a selected seed

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local e = React.createElement

local function SeedDetailModal(props)
    local seedType = props.seedType
    local isVisible = props.isVisible or false
    local onClose = props.onClose or function() end
    local onPurchase = props.onPurchase or function() end
    local playerMoney = props.playerMoney or 0
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    
    local isMobile = screenSize.X < 768
    local scale = isMobile and 0.75 or 0.8
    
    if not isVisible or not seedType then
        return nil
    end
    
    -- Seed data
    local seedData = {
        wheat = {
            emoji = "🌾",
            name = "Wheat",
            description = "The foundation of farming! Wheat is reliable, fast-growing, and always in demand.",
            funFact = "Wheat has been cultivated for over 10,000 years and feeds more people than any other crop!",
            growTime = "15 seconds",
            basePrice = 10,
            sellPrice = 5,
            difficulty = "Beginner",
            color = Color3.fromRGB(255, 215, 0)
        },
        tomato = {
            emoji = "🍅",
            name = "Tomato", 
            description = "Juicy and profitable! Tomatoes take longer to grow but offer great returns.",
            funFact = "Tomatoes are technically fruits, not vegetables, and come in over 10,000 varieties!",
            growTime = "45 seconds",
            basePrice = 50,
            sellPrice = 35,
            difficulty = "Intermediate",
            color = Color3.fromRGB(255, 99, 71)
        },
        carrot = {
            emoji = "🥕",
            name = "Carrot",
            description = "Crunchy and nutritious! Carrots are steady earners for patient farmers.",
            funFact = "Carrots were originally purple! Orange carrots were developed in the Netherlands.",
            growTime = "30 seconds", 
            basePrice = 25,
            sellPrice = 15,
            difficulty = "Beginner",
            color = Color3.fromRGB(255, 140, 0)
        },
        potato = {
            emoji = "🥔",
            name = "Potato",
            description = "The versatile staple! Potatoes are hardy and provide consistent income.",
            funFact = "Potatoes were the first vegetable grown in space by NASA in 1995!",
            growTime = "60 seconds",
            basePrice = 35,
            sellPrice = 25,
            difficulty = "Intermediate",
            color = Color3.fromRGB(139, 69, 19)
        },
        corn = {
            emoji = "🌽",
            name = "Corn",
            description = "Golden treasure! Corn takes time but rewards dedicated farmers handsomely.",
            funFact = "A single corn plant can produce 1-2 ears, and each ear has about 800 kernels!",
            growTime = "90 seconds",
            basePrice = 120,
            sellPrice = 80,
            difficulty = "Advanced",
            color = Color3.fromRGB(255, 255, 0)
        }
    }
    
    local seed = seedData[seedType]
    if not seed then return nil end
    
    local canAfford = playerMoney >= seed.basePrice
    local profitMargin = seed.sellPrice - seed.basePrice
    
    return e("TextButton", {
        Name = "SeedDetailModalBackground",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Text = "",
        ZIndex = 200,
        [React.Event.Activated] = onClose -- Click background to close
    }, {
        -- Modal Panel
        ModalPanel = e("Frame", {
            Name = "SeedDetailModal",
            Size = UDim2.new(0, 350 * scale, 0, 420 * scale),
            Position = UDim2.new(0.5, -175 * scale, 0.5, -210 * scale),
            BackgroundColor3 = Color3.fromRGB(30, 35, 40),
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
            ZIndex = 201
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 15)
            }),
            
            Stroke = e("UIStroke", {
                Color = seed.color,
                Thickness = 3,
                Transparency = 0.3
            }),
            
            Gradient = e("UIGradient", {
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 45, 50)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 30, 35))
                },
                Rotation = 45
            }),
            
            -- Close Button
            CloseButton = e("TextButton", {
                Name = "CloseButton",
                Size = UDim2.new(0, 30, 0, 30),
                Position = UDim2.new(1, -40, 0, 10),
                Text = "✕",
                TextColor3 = Color3.fromRGB(255, 100, 100),
                TextScaled = true,
                BackgroundColor3 = Color3.fromRGB(50, 25, 25),
                BorderSizePixel = 0,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 202,
                [React.Event.Activated] = onClose
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0.5, 0)
                })
            }),
            
            -- Seed Emoji (Large)
            SeedEmoji = e("TextLabel", {
                Name = "SeedEmoji",
                Size = UDim2.new(0, 80 * scale, 0, 80 * scale),
                Position = UDim2.new(0.5, -40 * scale, 0, 20),
                Text = seed.emoji,
                TextScaled = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 202
            }),
            
            -- Seed Name
            SeedName = e("TextLabel", {
                Name = "SeedName",
                Size = UDim2.new(1, -40, 0, 30),
                Position = UDim2.new(0, 20, 0, 110),
                Text = seed.name .. " Seeds",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 202
            }),
            
            -- Description
            Description = e("TextLabel", {
                Name = "Description",
                Size = UDim2.new(1, -40, 0, 45),
                Position = UDim2.new(0, 20, 0, 145),
                Text = seed.description,
                TextColor3 = Color3.fromRGB(200, 200, 200),
                TextScaled = true,
                TextWrapped = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSans,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Top,
                ZIndex = 202
            }),
            
            -- Stats Frame
            StatsFrame = e("Frame", {
                Name = "StatsFrame",
                Size = UDim2.new(1, -40, 0, 80),
                Position = UDim2.new(0, 20, 0, 200),
                BackgroundColor3 = Color3.fromRGB(20, 25, 30),
                BackgroundTransparency = 0.3,
                BorderSizePixel = 0,
                ZIndex = 202
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 10)
                }),
                
                -- Growth Time
                GrowTime = e("TextLabel", {
                    Name = "GrowTime",
                    Size = UDim2.new(0.5, -10, 0, 18),
                    Position = UDim2.new(0, 10, 0, 5),
                    Text = "⏱️ Grow Time: " .. seed.growTime,
                    TextColor3 = Color3.fromRGB(150, 255, 150),
                    TextScaled = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.SourceSans,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 203
                }),
                
                -- Difficulty
                Difficulty = e("TextLabel", {
                    Name = "Difficulty", 
                    Size = UDim2.new(0.5, -10, 0, 18),
                    Position = UDim2.new(0.5, 0, 0, 5),
                    Text = "📊 " .. seed.difficulty,
                    TextColor3 = seed.difficulty == "Beginner" and Color3.fromRGB(100, 255, 100) or 
                              seed.difficulty == "Intermediate" and Color3.fromRGB(255, 255, 100) or 
                              Color3.fromRGB(255, 150, 100),
                    TextScaled = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.SourceSans,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 203
                }),
                
                -- Buy Price
                BuyPrice = e("TextLabel", {
                    Name = "BuyPrice",
                    Size = UDim2.new(0.5, -10, 0, 18),
                    Position = UDim2.new(0, 10, 0, 28),
                    Text = "💰 Buy: $" .. seed.basePrice,
                    TextColor3 = canAfford and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(255, 150, 150),
                    TextScaled = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.SourceSans,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 203
                }),
                
                -- Sell Price
                SellPrice = e("TextLabel", {
                    Name = "SellPrice",
                    Size = UDim2.new(0.5, -10, 0, 18),
                    Position = UDim2.new(0.5, 0, 0, 28),
                    Text = "💵 Sell: $" .. seed.sellPrice,
                    TextColor3 = Color3.fromRGB(100, 255, 100),
                    TextScaled = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.SourceSans,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 203
                }),
                
                -- Profit
                Profit = e("TextLabel", {
                    Name = "Profit",
                    Size = UDim2.new(1, -20, 0, 18),
                    Position = UDim2.new(0, 10, 0, 50),
                    Text = "📈 Profit: $" .. profitMargin .. " (" .. math.floor(profitMargin/seed.basePrice*100) .. "%)",
                    TextColor3 = Color3.fromRGB(255, 215, 0),
                    TextScaled = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.SourceSansBold,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 203
                })
            }),
            
            -- Fun Fact
            FunFact = e("TextLabel", {
                Name = "FunFact",
                Size = UDim2.new(1, -40, 0, 35),
                Position = UDim2.new(0, 20, 0, 290),
                Text = "💡 " .. seed.funFact,
                TextColor3 = Color3.fromRGB(150, 200, 255),
                TextScaled = true,
                TextWrapped = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansItalic,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Top,
                ZIndex = 202
            }),
            
            -- Purchase Button
            PurchaseButton = e("TextButton", {
                Name = "PurchaseButton",
                Size = UDim2.new(0.8, 0, 0, 35),
                Position = UDim2.new(0.1, 0, 0, 335),
                Text = canAfford and ("Buy for $" .. seed.basePrice) or ("Need $" .. (seed.basePrice - playerMoney) .. " more"),
                TextColor3 = canAfford and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(255, 150, 150),
                TextScaled = true,
                BackgroundColor3 = canAfford and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(60, 30, 30),
                BorderSizePixel = 0,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 202,
                [React.Event.Activated] = function()
                    if canAfford then
                        onPurchase(seedType, seed.basePrice)
                        onClose()
                    end
                end
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 8)
                }),
                
                Stroke = e("UIStroke", {
                    Color = canAfford and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100),
                    Thickness = 2,
                    Transparency = 0.5
                })
            })
        })
    })
end

return SeedDetailModal