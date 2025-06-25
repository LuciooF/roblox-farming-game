-- Seed Detail Modal Component
-- Shows detailed information about a selected seed

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local e = React.createElement
-- Import unified crop system - REQUIRED for the refactored system
local CropRegistry = require(game:GetService("ReplicatedStorage").Shared.CropRegistry)

local function SeedDetailModal(props)
    local seedType = props.seedType
    local isVisible = props.isVisible or false
    local onClose = props.onClose or function() end
    local onPurchase = props.onPurchase or function() end
    local playerMoney = props.playerMoney or 0
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local weatherData = props.weatherData or {}
    
    local isMobile = screenSize.X < 768
    local scale = isMobile and 0.75 or 0.8
    
    if not isVisible or not seedType then
        return nil
    end
    
    -- Get crop data from CropRegistry
    local cropData = CropRegistry.getCrop(seedType)
    
    if not cropData then return nil end
    
    -- Create enhanced crop data with fun facts and weather descriptions
    local funFacts = {
        wheat = "Wheat has been cultivated for over 10,000 years and feeds more people than any other crop!",
        tomato = "Tomatoes are technically fruits, not vegetables, and come in over 10,000 varieties!",
        carrot = "Carrots were originally purple! Orange carrots were developed in the Netherlands.",
        potato = "Potatoes were the first vegetable grown in space by NASA in 1995!",
        corn = "A single corn plant can produce 1-2 ears, and each ear has about 800 kernels!"
    }
    
    -- Function to format weather effects based on multipliers
    local function getWeatherEffects(weatherMultipliers)
        local effects = {}
        for weather, multiplier in pairs(weatherMultipliers) do
            local growthText, profitText
            
            if multiplier > 1.3 then
                growthText = string.format("%.1fx faster", multiplier)
                profitText = string.format("+%d%%", math.floor((multiplier - 1) * 100))
            elseif multiplier >= 1.1 then
                growthText = string.format("%.1fx faster", multiplier)
                profitText = string.format("+%d%%", math.floor((multiplier - 1) * 100))
            elseif multiplier >= 0.9 then
                growthText = "Normal speed"
                profitText = "Normal"
            else
                growthText = string.format("%.1fx slower", 2 - multiplier)
                profitText = string.format("-%d%%", math.floor((1 - multiplier) * 100))
            end
            
            local waterText = (weather == "Rainy" or weather == "Thunderstorm") and "Auto-watered" or 
                             (weather == "Sunny" and "Needs more water") or "Normal"
            
            effects[weather] = {
                growth = growthText,
                water = waterText,
                profit = profitText
            }
        end
        return effects
    end
    
    -- Function to determine difficulty based on unlock level and rarity
    local function getDifficulty(unlockLevel, rarity)
        if unlockLevel <= 1 then
            return "Beginner"
        elseif unlockLevel <= 5 then
            return "Intermediate"
        else
            return "Advanced"
        end
    end
    
    -- Build the crop object with all needed data
    local crop = {
        emoji = cropData.emoji,
        name = cropData.name,
        description = cropData.description,
        funFact = funFacts[seedType] or "An amazing crop with a rich history!",
        growTime = cropData.growthTime .. " seconds",
        basePrice = cropData.seedCost,
        sellPrice = cropData.basePrice,
        difficulty = getDifficulty(cropData.unlockLevel, cropData.rarity),
        color = cropData.color,
        weatherEffects = getWeatherEffects(cropData.weatherMultipliers),
        waterNeeded = cropData.waterNeeded,
        rarity = cropData.rarity,
        unlockLevel = cropData.unlockLevel
    }
    
    local canAfford = playerMoney >= crop.basePrice
    local profitMargin = crop.sellPrice - crop.basePrice
    
    -- Get current weather information
    local currentWeather = weatherData.current and weatherData.current.name or "Unknown"
    local weatherEffect = crop.weatherEffects[currentWeather] or { growth = "Unknown", water = "Unknown", profit = "Unknown" }
    
    -- Weather interaction state
    local selectedWeatherTab, setSelectedWeatherTab = React.useState(currentWeather ~= "Unknown" and currentWeather or "Sunny")
    
    -- Weather icons
    local weatherIcons = {
        Sunny = "☀️",
        Rainy = "🌧️", 
        Cloudy = "☁️",
        Thunderstorm = "⛈️"
    }
    
    -- Function to get weather effect color
    local function getEffectColor(effectText)
        if effectText:find("+") then
            return Color3.fromRGB(100, 255, 100) -- Green for positive
        elseif effectText:find("-") then
            return Color3.fromRGB(255, 100, 100) -- Red for negative
        else
            return Color3.fromRGB(200, 200, 200) -- Gray for neutral
        end
    end
    
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
                Color = crop.color,
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
                ZIndex = 250,
                [React.Event.Activated] = onClose
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0.5, 0)
                })
            }),
            
            -- Scrollable Content Frame
            ScrollFrame = e("ScrollingFrame", {
                Name = "ScrollFrame",
                Size = UDim2.new(1, -20, 1, -50),
                Position = UDim2.new(0, 10, 0, 40),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ScrollBarThickness = 6,
                ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100),
                ScrollBarImageTransparency = 0.3,
                CanvasSize = UDim2.new(0, 0, 0, 450),
                ScrollingDirection = Enum.ScrollingDirection.Y,
                ZIndex = 202
            }, {
                -- Crop Emoji (Large)
                CropEmoji = e("TextLabel", {
                    Name = "CropEmoji",
                    Size = UDim2.new(0, 80 * scale, 0, 80 * scale),
                    Position = UDim2.new(0.5, -40 * scale, 0, 10),
                    Text = crop.emoji,
                    TextScaled = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.SourceSansBold,
                    ZIndex = 202
                }),
                
                -- Crop Name
                CropName = e("TextLabel", {
                    Name = "CropName",
                    Size = UDim2.new(1, -40, 0, 30),
                    Position = UDim2.new(0, 20, 0, 110),
                    Text = crop.name .. " Crop",
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
                    Size = UDim2.new(1, -40, 0, 30),
                    Position = UDim2.new(0, 20, 0, 145),
                    Text = crop.description,
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
                    Position = UDim2.new(0, 20, 0, 185),
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
                        Size = UDim2.new(1, -20, 0, 15),
                        Position = UDim2.new(0, 10, 0, 5),
                        Text = "⏱️ Grow Time: " .. crop.growTime,
                        TextColor3 = Color3.fromRGB(150, 255, 150),
                        TextScaled = true,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.SourceSans,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        ZIndex = 203
                    }),
                    
                    -- Difficulty and Water Need
                    DifficultyWater = e("TextLabel", {
                        Name = "DifficultyWater",
                        Size = UDim2.new(1, -20, 0, 15),
                        Position = UDim2.new(0, 10, 0, 25),
                        Text = "🎯 " .. crop.difficulty .. " • 💧 Water: " .. crop.waterNeeded,
                        TextColor3 = Color3.fromRGB(200, 200, 255),
                        TextScaled = true,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.SourceSans,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        ZIndex = 203
                    }),
                    
                    -- Buy Price
                    BuyPrice = e("TextLabel", {
                        Name = "BuyPrice",
                        Size = UDim2.new(0.5, -10, 0, 15),
                        Position = UDim2.new(0, 10, 0, 45),
                        Text = "💰 Buy: $" .. crop.basePrice,
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
                        Size = UDim2.new(0.5, -10, 0, 15),
                        Position = UDim2.new(0.5, 0, 0, 45),
                        Text = "💵 Sell: $" .. crop.sellPrice,
                        TextColor3 = Color3.fromRGB(100, 255, 100),
                        TextScaled = true,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.SourceSans,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 203
                    }),
                    
                    -- Profit Calculation
                    Profit = e("TextLabel", {
                        Name = "Profit",
                        Size = UDim2.new(1, -20, 0, 15),
                        Position = UDim2.new(0, 10, 0, 65),
                        Text = "📈 Profit: $" .. profitMargin .. " per harvest",
                        TextColor3 = profitMargin >= 0 and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100),
                        TextScaled = true,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.SourceSans,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        ZIndex = 203
                    })
                }),
                
                -- Purchase Button
                PurchaseButton = e("TextButton", {
                    Name = "PurchaseButton",
                    Size = UDim2.new(0.8, 0, 0, 35),
                    Position = UDim2.new(0.1, 0, 0, 300),
                    Text = canAfford and ("Buy for $" .. crop.basePrice) or ("Need $" .. (crop.basePrice - playerMoney) .. " more"),
                    TextColor3 = canAfford and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(255, 150, 150),
                    TextScaled = true,
                    BackgroundColor3 = canAfford and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(60, 30, 30),
                    BorderSizePixel = 0,
                    Font = Enum.Font.SourceSansBold,
                    ZIndex = 202,
                    [React.Event.Activated] = function()
                        if canAfford then
                            onPurchase(seedType, crop.basePrice)
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
        }) -- Close ModalPanel
    }) -- Close TextButton
end

return SeedDetailModal