-- Weather Panel Component
-- Shows current weather and forecast, with debug controls

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local e = React.createElement

local function WeatherPanel(props)
    local weatherData = props.weatherData or {}
    local visible = props.visible or false
    local onClose = props.onClose or function() end
    local remotes = props.remotes or {}
    local isDebugMode = props.isDebugMode or true -- Enable for testing
    
    -- Responsive sizing
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local isMobile = screenSize.X < 768
    local scale = isMobile and 0.85 or 1
    local panelWidth = isMobile and 350 or 400
    local panelHeight = isMobile and 280 or 320
    
    -- Current weather info
    local currentWeather = weatherData.current or {}
    local forecast = weatherData.forecast or {}
    local weatherTypes = weatherData.types or {}
    
    -- Get current weather display info
    local currentName = currentWeather.name or "Unknown"
    local currentData = currentWeather.data or {}
    local currentEmoji = currentData.emoji or "❓"
    local currentDescription = currentData.description or "No weather data"
    local timeRemaining = currentWeather.timeRemaining or 0
    
    -- Format time remaining
    local function formatTime(seconds)
        local minutes = math.floor(seconds / 60)
        local secs = math.floor(seconds % 60)
        return string.format("%d:%02d", minutes, secs)
    end
    
    -- Handle debug weather change
    local function handleWeatherChange(weatherName)
        print("🌤️ [WeatherPanel] Button clicked for weather:", weatherName)
        print("🌤️ [WeatherPanel] isDebugMode:", isDebugMode)
        print("🌤️ [WeatherPanel] weatherRemote exists:", remotes.weatherRemote ~= nil)
        
        if remotes.weatherRemote and isDebugMode then
            print("🌤️ [WeatherPanel] Firing server with force_change for:", weatherName)
            remotes.weatherRemote:FireServer("force_change", weatherName)
        else
            print("🌤️ [WeatherPanel] NOT firing server - weatherRemote:", remotes.weatherRemote ~= nil, "debugMode:", isDebugMode)
        end
    end
    
    -- Weather effect indicators
    local function getEffectText(effects)
        local effectTexts = {}
        
        if effects.autoWater then
            table.insert(effectTexts, "💧 Auto-waters crops")
        end
        
        if effects.globalGrowthMultiplier then
            local multiplier = effects.globalGrowthMultiplier
            if multiplier > 1 then
                table.insert(effectTexts, "⚡ " .. math.floor(multiplier * 100) .. "% growth speed")
            elseif multiplier < 1 then
                table.insert(effectTexts, "🐌 " .. math.floor(multiplier * 100) .. "% growth speed")
            end
        end
        
        if effects.damageChance and effects.damageChance > 0 then
            table.insert(effectTexts, "⚠️ " .. math.floor(effects.damageChance * 100) .. "% damage chance")
        end
        
        return table.concat(effectTexts, "\n")
    end
    
    return React.createElement(React.Fragment, {}, {
        -- Main Weather Panel
        WeatherPanel = e("Frame", {
            Name = "WeatherPanel",
            Size = UDim2.new(0, panelWidth * scale, 0, panelHeight * scale),
            Position = UDim2.new(1, -panelWidth * scale - 10, 0, 10), -- Top right corner
            BackgroundColor3 = Color3.fromRGB(30, 35, 45),
            BackgroundTransparency = visible and 0.05 or 1,
            BorderSizePixel = 0,
            Visible = visible,
            ZIndex = 15
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 12)
            }),
            
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(100, 150, 255),
                Thickness = 2,
                Transparency = 0.3
            }),
            
            Gradient = e("UIGradient", {
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 50, 65)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 30, 40))
                },
                Rotation = 45
            }),
            
            -- Close Button
            CloseButton = e("TextButton", {
                Name = "CloseButton",
                Size = UDim2.new(0, 25, 0, 25),
                Position = UDim2.new(1, -35, 0, 8),
                Text = "✕",
                TextColor3 = Color3.fromRGB(255, 100, 100),
                TextScaled = true,
                BackgroundColor3 = Color3.fromRGB(50, 25, 25),
                BorderSizePixel = 0,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 17,
                [React.Event.Activated] = onClose
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0.5, 0)
                })
            }),
            
            -- Title
            Title = e("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -50, 0, 30),
                Position = UDim2.new(0, 15, 0, 8),
                Text = "🌤️ Weather Station",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 16
            }),
            
            -- Current Weather Section
            CurrentWeatherFrame = e("Frame", {
                Name = "CurrentWeather",
                Size = UDim2.new(1, -20, 0, 80),
                Position = UDim2.new(0, 10, 0, 45),
                BackgroundColor3 = Color3.fromRGB(20, 25, 35),
                BorderSizePixel = 0,
                ZIndex = 16
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 8)
                }),
                
                -- Weather Icon
                WeatherIcon = e("TextLabel", {
                    Name = "Icon",
                    Size = UDim2.new(0, 50, 0, 50),
                    Position = UDim2.new(0, 10, 0, 15),
                    Text = currentEmoji,
                    TextScaled = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.SourceSansBold,
                    ZIndex = 17
                }),
                
                -- Weather Name
                WeatherName = e("TextLabel", {
                    Name = "Name",
                    Size = UDim2.new(0, 150, 0, 25),
                    Position = UDim2.new(0, 70, 0, 10),
                    Text = currentName,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextScaled = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.SourceSansBold,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 17
                }),
                
                -- Time Remaining
                TimeRemaining = e("TextLabel", {
                    Name = "TimeRemaining",
                    Size = UDim2.new(0, 150, 0, 20),
                    Position = UDim2.new(0, 70, 0, 35),
                    Text = "Changes in: " .. formatTime(timeRemaining),
                    TextColor3 = Color3.fromRGB(200, 200, 200),
                    TextScaled = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.SourceSans,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 17
                }),
                
                -- Weather Effects
                WeatherEffects = e("TextLabel", {
                    Name = "Effects",
                    Size = UDim2.new(0, 150, 0, 20),
                    Position = UDim2.new(0, 70, 0, 55),
                    Text = getEffectText(currentData.effects or {}),
                    TextColor3 = Color3.fromRGB(150, 200, 255),
                    TextSize = 10,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.SourceSans,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    ZIndex = 17
                })
            }),
            
            -- Forecast Section
            ForecastTitle = e("TextLabel", {
                Name = "ForecastTitle",
                Size = UDim2.new(1, -20, 0, 20),
                Position = UDim2.new(0, 10, 0, 135),
                Text = "📅 Forecast",
                TextColor3 = Color3.fromRGB(200, 200, 200),
                TextScaled = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 16
            }),
            
            -- Forecast Items
            ForecastContainer = e("ScrollingFrame", {
                Name = "ForecastContainer",
                Size = UDim2.new(1, -20, 0, 60),
                Position = UDim2.new(0, 10, 0, 160),
                BackgroundColor3 = Color3.fromRGB(15, 20, 30),
                BorderSizePixel = 0,
                ScrollBarThickness = 6,
                ScrollingDirection = Enum.ScrollingDirection.X,
                CanvasSize = UDim2.new(0, #forecast * 80, 0, 60),
                ZIndex = 16
            }, React.createElement("UICorner", {
                CornerRadius = UDim.new(0, 6)
            }), React.createElement("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                VerticalAlignment = Enum.VerticalAlignment.Top,
                Padding = UDim.new(0, 5)
            }), React.createElement("UIPadding", {
                PaddingTop = UDim.new(0, 5),
                PaddingLeft = UDim.new(0, 5),
                PaddingRight = UDim.new(0, 5),
                PaddingBottom = UDim.new(0, 5)
            }), (function()
                local forecastItems = {}
                for i, forecastWeather in ipairs(forecast) do
                    forecastItems["Forecast" .. i] = e("Frame", {
                        Name = "ForecastItem" .. i,
                        Size = UDim2.new(0, 70, 0, 50),
                        BackgroundColor3 = Color3.fromRGB(25, 30, 40),
                        BorderSizePixel = 0,
                        ZIndex = 17
                    }, {
                        Corner = e("UICorner", {
                            CornerRadius = UDim.new(0, 4)
                        }),
                        Icon = e("TextLabel", {
                            Size = UDim2.new(1, 0, 0, 25),
                            Position = UDim2.new(0, 0, 0, 0),
                            Text = (forecastWeather.data and forecastWeather.data.emoji) or "❓",
                            TextScaled = true,
                            BackgroundTransparency = 1,
                            Font = Enum.Font.SourceSansBold,
                            ZIndex = 18
                        }),
                        Time = e("TextLabel", {
                            Size = UDim2.new(1, 0, 0, 15),
                            Position = UDim2.new(0, 0, 0, 25),
                            Text = "+" .. (forecastWeather.hoursFromNow or 0) .. "h",
                            TextColor3 = Color3.fromRGB(180, 180, 180),
                            TextSize = 10,
                            BackgroundTransparency = 1,
                            Font = Enum.Font.SourceSans,
                            ZIndex = 18
                        }),
                        Name = e("TextLabel", {
                            Size = UDim2.new(1, 0, 0, 10),
                            Position = UDim2.new(0, 0, 0, 40),
                            Text = forecastWeather.name or "Unknown",
                            TextColor3 = Color3.fromRGB(150, 150, 150),
                            TextSize = 8,
                            BackgroundTransparency = 1,
                            Font = Enum.Font.SourceSans,
                            ZIndex = 18
                        })
                    })
                end
                return forecastItems
            end)()),
            
            -- Debug Controls (only show in debug mode)
            DebugSection = isDebugMode and e("Frame", {
                Name = "DebugControls",
                Size = UDim2.new(1, -20, 0, 40),
                Position = UDim2.new(0, 10, 0, 230),
                BackgroundColor3 = Color3.fromRGB(40, 20, 20),
                BorderSizePixel = 0,
                ZIndex = 16
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 6)
                }),
                DebugLabel = e("TextLabel", {
                    Size = UDim2.new(0, 80, 1, 0),
                    Position = UDim2.new(0, 5, 0, 0),
                    Text = "🔧 Debug:",
                    TextColor3 = Color3.fromRGB(255, 150, 150),
                    TextSize = 12,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.SourceSansBold,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 17
                }),
                
                -- Weather change buttons
                ButtonContainer = e("ScrollingFrame", {
                    Size = UDim2.new(1, -90, 1, -5),
                    Position = UDim2.new(0, 85, 0, 2.5),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ScrollBarThickness = 4,
                    ScrollingDirection = Enum.ScrollingDirection.X,
                    CanvasSize = UDim2.new(0, (#weatherTypes * 70), 0, 35),
                    ZIndex = 17
                }, React.createElement("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Left,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 3)
                }), (function()
                    local buttons = {}
                    for weatherName, weatherInfo in pairs(weatherTypes) do
                        buttons[weatherName .. "Button"] = e("TextButton", {
                            Name = weatherName .. "Button",
                            Size = UDim2.new(0, 65, 0, 30),
                            Text = (weatherInfo.emoji or "") .. "\n" .. weatherName,
                            TextColor3 = Color3.fromRGB(255, 255, 255),
                            TextSize = 10,
                            BackgroundColor3 = weatherName == currentName and Color3.fromRGB(50, 100, 50) or Color3.fromRGB(30, 30, 50),
                            BorderSizePixel = 0,
                            Font = Enum.Font.SourceSans,
                            ZIndex = 18,
                            [React.Event.Activated] = function()
                                handleWeatherChange(weatherName)
                            end,
                            [React.Event.MouseEnter] = function(gui)
                                if weatherName ~= currentName then
                                    gui.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
                                end
                            end,
                            [React.Event.MouseLeave] = function(gui)
                                if weatherName ~= currentName then
                                    gui.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
                                end
                            end
                        }, {
                            Corner = e("UICorner", {
                                CornerRadius = UDim.new(0, 4)
                            })
                        })
                    end
                    return buttons
                end)())
            }) or nil
        })
    })
end

return WeatherPanel