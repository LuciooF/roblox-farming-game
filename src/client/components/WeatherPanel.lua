-- Modern Weather Panel Component
-- Clean white design showing current weather and 3-day forecast based on real days

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local e = React.createElement
local assets = require(game:GetService("ReplicatedStorage").Shared.assets)
local ScreenUtils = require(game:GetService("ReplicatedStorage").Shared.ScreenUtils)

local Modal = require(script.Parent.Modal)

-- Sound IDs for UI interactions
local HOVER_SOUND_ID = "rbxassetid://15675059323"
local CLICK_SOUND_ID = "rbxassetid://6324790483"

-- Weather icon mappings - using hardcoded working asset ID temporarily
local WEATHER_ICONS = {
    Sunny = "rbxassetid://79801759978961",
    Cloudy = "rbxassetid://79801759978961", 
    Rainy = "rbxassetid://79801759978961",
    Thunderstorm = "rbxassetid://79801759978961"
}

local function WeatherPanel(props)
    local weatherData = props.weatherData or {}
    local visible = props.visible or false
    local onClose = props.onClose or function() end
    local remotes = props.remotes or {}
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    
    -- Responsive sizing
    local scale = ScreenUtils.getProportionalScale(screenSize)
    local panelWidth = math.min(screenSize.X * 0.9, ScreenUtils.getProportionalSize(screenSize, 600))
    local panelHeight = math.min(screenSize.Y * 0.85, ScreenUtils.getProportionalSize(screenSize, 520))
    
    -- Proportional text sizes
    local titleTextSize = ScreenUtils.getProportionalTextSize(screenSize, 32)
    local normalTextSize = ScreenUtils.getProportionalTextSize(screenSize, 18)
    local smallTextSize = ScreenUtils.getProportionalTextSize(screenSize, 14)
    local buttonTextSize = ScreenUtils.getProportionalTextSize(screenSize, 16)
    local cardTitleSize = ScreenUtils.getProportionalTextSize(screenSize, 20)
    local cardValueSize = ScreenUtils.getProportionalTextSize(screenSize, 16)
    
    -- Current weather info
    local currentWeather = weatherData.current or {}
    local forecast = weatherData.forecast or {}
    
    -- Current weather display data
    local weatherName = currentWeather.name or "Unknown"
    local weatherDesc = currentWeather.data and currentWeather.data.description or "No weather data"
    local gameplayDesc = currentWeather.data and currentWeather.data.gameplayDescription or ""
    local temperature = currentWeather.temperature or 72
    local dayName = currentWeather.dayName or "Unknown"
    
    -- Get weather icon - prefer server data, fallback to local mapping
    local weatherIcon = ""
    if currentWeather.data and currentWeather.data.icon then
        weatherIcon = currentWeather.data.icon
    else
        weatherIcon = WEATHER_ICONS[weatherName] or ""
    end
    
    -- Debug: Only log if icon is empty
    if weatherIcon == "" then
        print("WeatherPanel - No icon found for weather:", weatherName)
    end
    
    -- Pre-create sounds for better performance
    local hoverSound = React.useRef(nil)
    local clickSound = React.useRef(nil)
    
    React.useEffect(function()
        if not hoverSound.current then
            hoverSound.current = Instance.new("Sound")
            hoverSound.current.SoundId = HOVER_SOUND_ID
            hoverSound.current.Volume = 0.3
            hoverSound.current.Parent = SoundService
        end
        
        if not clickSound.current then
            clickSound.current = Instance.new("Sound")
            clickSound.current.SoundId = CLICK_SOUND_ID
            clickSound.current.Volume = 0.3
            clickSound.current.Parent = SoundService
        end
        
        return function()
            if hoverSound.current then
                hoverSound.current:Destroy()
            end
            if clickSound.current then
                clickSound.current:Destroy()
            end
        end
    end, {})
    
    -- Function to create weather emoji with hover effects (no images)
    local function createWeatherIcon(weatherType, size, position, zIndex)
        local iconRef = React.useRef(nil)
        local animationTracker = React.useRef(nil)
        
        -- Get emoji for weather type
        local emoji = "☀️" -- Default sunny
        if weatherType == "Sunny" then emoji = "☀️"
        elseif weatherType == "Cloudy" then emoji = "☁️"  
        elseif weatherType == "Rainy" then emoji = "🌧️"
        elseif weatherType == "Thunderstorm" then emoji = "⛈️"
        end
        
        local function createIconFlip()
            if animationTracker.current then
                animationTracker.current:Cancel()
                animationTracker.current:Destroy()
            end
            
            if iconRef.current then
                iconRef.current.Rotation = 0
                local flipTween = TweenService:Create(iconRef.current,
                    TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                    {Rotation = 360}
                )
                
                animationTracker.current = flipTween
                flipTween:Play()
                
                flipTween.Completed:Connect(function()
                    if iconRef.current then
                        iconRef.current.Rotation = 0
                    end
                end)
            end
        end
        
        return e("TextButton", {
            Name = "WeatherEmoji",
            Size = size,
            Position = position,
            Text = emoji,
            TextSize = normalTextSize,
            TextWrapped = true,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSansBold,
            ZIndex = zIndex,
            ref = iconRef,
            [React.Event.MouseEnter] = function()
                if hoverSound.current then
                    hoverSound.current:Play()
                end
                createIconFlip()
            end,
            [React.Event.Activated] = function()
                if clickSound.current then
                    clickSound.current:Play()
                end
                createIconFlip()
            end
        }, {
            TextStroke = e("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 2,
                Transparency = 0.3
            })
        })
    end
    
    return e(Modal, {
        visible = visible,
        onClose = onClose,
        zIndex = 30
    }, {
        WeatherContainer = e("Frame", {
            Name = "WeatherContainer",
            Size = UDim2.new(0, panelWidth, 0, panelHeight + 50),
            Position = UDim2.new(0.5, -panelWidth / 2, 0.5, -(panelHeight + 50) / 2),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 30
        }, {
            WeatherPanel = e("Frame", {
                Name = "WeatherPanel",
                Size = UDim2.new(0, panelWidth, 0, panelHeight),
                Position = UDim2.new(0, 0, 0, 50),
                BackgroundColor3 = Color3.fromRGB(240, 245, 255),
                BackgroundTransparency = 0.05,
                BorderSizePixel = 0,
                ZIndex = 30
            }, {
                -- Floating Title (Weather-themed purple)
                FloatingTitle = e("Frame", {
                    Name = "FloatingTitle",
                    Size = UDim2.new(0, 180, 0, 40),
                    Position = UDim2.new(0, -10, 0, -25),
                    BackgroundColor3 = Color3.fromRGB(150, 100, 255),
                    BorderSizePixel = 0,
                    ZIndex = 32
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 12)
                    }),
                    Gradient = e("UIGradient", {
                        Color = ColorSequence.new{
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(170, 130, 255)),
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(130, 80, 255))
                        },
                        Rotation = 45
                    }),
                    Stroke = e("UIStroke", {
                        Color = Color3.fromRGB(255, 255, 255),
                        Thickness = 3,
                        Transparency = 0.2
                    }),
                    TitleText = e("TextLabel", {
                        Size = UDim2.new(1, -10, 1, 0),
                        Position = UDim2.new(0, 5, 0, 0),
                        Text = "⛅ WEATHER",
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = normalTextSize,
            TextWrapped = true,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.GothamBold,
                        ZIndex = 33
                    }, {
                        TextStroke = e("UIStroke", {
                            Color = Color3.fromRGB(0, 0, 0),
                            Thickness = 2,
                            Transparency = 0.5
                        })
                    })
                }),
                
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 20)
                }),
                
                Stroke = e("UIStroke", {
                    Color = Color3.fromRGB(150, 100, 255),
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
                    Size = UDim2.new(0, 32, 0, 32),
                    Position = UDim2.new(1, -16, 0, -16),
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
                    }),
                    Shadow = e("Frame", {
                        Name = "Shadow",
                        Size = UDim2.new(1, 2, 1, 2),
                        Position = UDim2.new(0, 2, 0, 2),
                        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                        BackgroundTransparency = 0.7,
                        BorderSizePixel = 0,
                        ZIndex = 33
                    }, {
                        Corner = e("UICorner", {
                            CornerRadius = UDim.new(0, 6)
                        })
                    })
            }),
            
                -- Title Section
                TitleSection = e("Frame", {
                    Name = "TitleSection",
                    Size = UDim2.new(1, -40, 0, 60),
                    Position = UDim2.new(0, 20, 0, 20),
                BackgroundTransparency = 1,
                ZIndex = 32
            }, {
                Title = e("TextLabel", {
                    Name = "Title",
                    Size = UDim2.new(1, 0, 0, 40),
                    Position = UDim2.new(0, 0, 0, 0),
                    Text = "🌤️ Weather Station",
                    TextColor3 = Color3.fromRGB(50, 50, 50),
                    TextSize = normalTextSize,
            TextWrapped = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 32
                }, {
                    TextSizeConstraint = e("UITextSizeConstraint", {
                        MaxTextSize = 24,
                        MinTextSize = 16
                    })
                }),
                
                Subtitle = e("TextLabel", {
                    Name = "Subtitle",
                    Size = UDim2.new(1, 0, 0, 20),
                    Position = UDim2.new(0, 0, 0, 45),
                    Text = "Real-time weather forecast for your farm",
                    TextColor3 = Color3.fromRGB(120, 120, 120),
                    TextSize = normalTextSize,
            TextWrapped = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 32
                }, {
                    TextSizeConstraint = e("UITextSizeConstraint", {
                        MaxTextSize = 16 * scale,
                        MinTextSize = 12 * scale
                    })
                }),
                
                StrategyTip = e("TextLabel", {
                    Name = "StrategyTip",
                    Size = UDim2.new(1, 0, 0, 20),
                    Position = UDim2.new(0, 0, 0, 70),
                    Text = "💡 Weather affects your farm! Plan strategically with the forecast.",
                    TextColor3 = Color3.fromRGB(60, 120, 60),
                    TextSize = normalTextSize,
            TextWrapped = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 32
                }, {
                    TextSizeConstraint = e("UITextSizeConstraint", {
                        MaxTextSize = 14 * scale,
                        MinTextSize = 10 * scale
                    })
                })
            }),
            
            -- Current Weather Card
            CurrentWeatherCard = e("Frame", {
                Name = "CurrentWeatherCard",
                Size = UDim2.new(1, -40, 0, 180),
                Position = UDim2.new(0, 20, 0, 140),
                BackgroundColor3 = Color3.fromRGB(248, 250, 252),
                BorderSizePixel = 0,
                ZIndex = 32
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 15)
                }),
                
                Stroke = e("UIStroke", {
                    Color = Color3.fromRGB(220, 220, 220),
                    Thickness = 1,
                    Transparency = 0
                }),
                
                -- Centered Weather Content Container
                WeatherContent = e("Frame", {
                    Name = "WeatherContent",
                    Size = UDim2.new(1, 0, 1, 0),
                    Position = UDim2.new(0, 0, 0, 0),
                    BackgroundTransparency = 1,
                    ZIndex = 33
                }, {
                    Layout = e("UIListLayout", {
                        FillDirection = Enum.FillDirection.Vertical,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        Padding = UDim.new(0, 8),
                        SortOrder = Enum.SortOrder.LayoutOrder
                    }),
                    
                    -- Weather Icon (Centered) 
                    WeatherIconContainer = e("Frame", {
                        Name = "WeatherIconContainer",
                        Size = UDim2.new(0, 80, 0, 80),
                        BackgroundTransparency = 1,
                        ZIndex = 33,
                        LayoutOrder = 1
                    }, {
                        WeatherIcon = createWeatherIcon(
                            weatherName,
                            UDim2.new(1, 0, 1, 0),
                            UDim2.new(0, 0, 0, 0),
                            34
                        )
                    }),
                    
                    -- Weather Name and Day (Centered)
                    WeatherInfo = e("Frame", {
                        Name = "WeatherInfo",
                        Size = UDim2.new(1, -20, 0, 60),
                        BackgroundTransparency = 1,
                        ZIndex = 33,
                        LayoutOrder = 2
                    }, {
                        WeatherName = e("TextLabel", {
                            Name = "WeatherName",
                            Size = UDim2.new(1, 0, 0, 25),
                            Position = UDim2.new(0, 0, 0, 0),
                            Text = weatherName,
                            TextColor3 = Color3.fromRGB(30, 30, 30),
                            TextSize = normalTextSize,
            TextWrapped = true,
                            BackgroundTransparency = 1,
                            Font = Enum.Font.GothamBold,
                            TextXAlignment = Enum.TextXAlignment.Center,
                            ZIndex = 33
                        }, {
                            TextSizeConstraint = e("UITextSizeConstraint", {
                                MaxTextSize = 24 * scale,
                                MinTextSize = 18 * scale
                            })
                        }),
                        
                        DayInfo = e("TextLabel", {
                            Name = "DayInfo",
                            Size = UDim2.new(1, 0, 0, 18),
                            Position = UDim2.new(0, 0, 0, 25),
                            Text = dayName,
                            TextColor3 = Color3.fromRGB(100, 100, 100),
                            TextSize = normalTextSize,
            TextWrapped = true,
                            BackgroundTransparency = 1,
                            Font = Enum.Font.Gotham,
                            TextXAlignment = Enum.TextXAlignment.Center,
                            ZIndex = 33
                        }, {
                            TextSizeConstraint = e("UITextSizeConstraint", {
                                MaxTextSize = 16 * scale,
                                MinTextSize = 12 * scale
                            })
                        }),
                        
                        Temperature = e("TextLabel", {
                            Name = "Temperature",
                            Size = UDim2.new(1, 0, 0, 17),
                            Position = UDim2.new(0, 0, 0, 43),
                            Text = temperature .. "°F",
                            TextColor3 = Color3.fromRGB(60, 60, 60),
                            TextSize = normalTextSize,
            TextWrapped = true,
                            BackgroundTransparency = 1,
                            Font = Enum.Font.GothamBold,
                            TextXAlignment = Enum.TextXAlignment.Center,
                            ZIndex = 33
                        }, {
                            TextSizeConstraint = e("UITextSizeConstraint", {
                                MaxTextSize = 18 * scale,
                                MinTextSize = 12 * scale
                            })
                        })
                    }),
                    
                    -- Weather Description (Centered)
                    Description = e("TextLabel", {
                        Name = "Description",
                        Size = UDim2.new(1, -30, 0, 20),
                        Text = weatherDesc,
                        TextColor3 = Color3.fromRGB(80, 80, 80),
                        TextSize = 12 * scale,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        TextWrapped = true,
                        ZIndex = 33,
                        LayoutOrder = 3
                    })
                })
            }),
            
            -- Forecast Section
            ForecastSection = e("Frame", {
                Name = "ForecastSection",
                Size = UDim2.new(1, -40, 0, 140),
                Position = UDim2.new(0, 20, 0, 340),
                BackgroundTransparency = 1,
                ZIndex = 32
            }, {
                ForecastTitle = e("TextLabel", {
                    Name = "ForecastTitle",
                    Size = UDim2.new(1, 0, 0, 30),
                    Position = UDim2.new(0, 0, 0, 0),
                    Text = "📅 3-Day Forecast",
                    TextColor3 = Color3.fromRGB(50, 50, 50),
                    TextSize = normalTextSize,
            TextWrapped = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 32
                }, {
                    TextSizeConstraint = e("UITextSizeConstraint", {
                        MaxTextSize = 20 * scale,
                        MinTextSize = 16 * scale
                    })
                }),
                
                -- Forecast Cards Container
                ForecastContainer = e("Frame", {
                    Name = "ForecastContainer",
                    Size = UDim2.new(1, 0, 0, 100),
                    Position = UDim2.new(0, 0, 0, 40),
                    BackgroundTransparency = 1,
                    ZIndex = 32
                }, {
                    Layout = e("UIListLayout", {
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Top,
                        Padding = UDim.new(0, 15),
                        SortOrder = Enum.SortOrder.LayoutOrder
                    }),
                    
                    -- Generate forecast cards
                    ForecastCards = React.createElement(React.Fragment, {}, (function()
                        local forecastCards = {}
                        
                        for i, forecastDay in ipairs(forecast) do
                            if i <= 3 then -- Only show 3 days
                                local dayWeatherName = forecastDay.name or "Unknown"
                                local dayWeatherData = forecastDay.data or {}
                                local dayName = forecastDay.dayName or "Day " .. i
                                
                                -- Get weather icon - prefer server data, fallback to local mapping
                                local dayIcon = ""
                                if dayWeatherData.icon then
                                    dayIcon = dayWeatherData.icon
                                else
                                    dayIcon = WEATHER_ICONS[dayWeatherName] or ""
                                end
                                
                                forecastCards["ForecastCard" .. i] = e("Frame", {
                                    Name = "ForecastCard" .. i,
                                    Size = UDim2.new(0, 160, 0, 100),
                                    BackgroundColor3 = Color3.fromRGB(252, 252, 252),
                                    BorderSizePixel = 0,
                                    ZIndex = 33,
                                    LayoutOrder = i
                                }, {
                                    Corner = e("UICorner", {
                                        CornerRadius = UDim.new(0, 12)
                                    }),
                                    
                                    Stroke = e("UIStroke", {
                                        Color = Color3.fromRGB(230, 230, 230),
                                        Thickness = 1,
                                        Transparency = 0
                                    }),
                                    
                                    -- Day Name
                                    DayName = e("TextLabel", {
                                        Name = "DayName",
                                        Size = UDim2.new(1, -10, 0, 20),
                                        Position = UDim2.new(0, 5, 0, 5),
                                        Text = dayName,
                                        TextColor3 = Color3.fromRGB(60, 60, 60),
                                        TextSize = normalTextSize,
            TextWrapped = true,
                                        BackgroundTransparency = 1,
                                        Font = Enum.Font.GothamBold,
                                        TextXAlignment = Enum.TextXAlignment.Center,
                                        ZIndex = 34
                                    }, {
                                        TextSizeConstraint = e("UITextSizeConstraint", {
                                            MaxTextSize = 14 * scale,
                                            MinTextSize = 10 * scale
                                        })
                                    }),
                                    
                                    -- Weather Icon (Interactive)
                                    WeatherIcon = createWeatherIcon(
                                        dayWeatherName,
                                        UDim2.new(0, 40, 0, 40),
                                        UDim2.new(0.5, -20, 0, 30),
                                        34
                                    ),
                                    
                                    -- Weather Name
                                    WeatherName = e("TextLabel", {
                                        Name = "WeatherName",
                                        Size = UDim2.new(1, -10, 0, 15),
                                        Position = UDim2.new(0, 5, 0, 75),
                                        Text = dayWeatherName,
                                        TextColor3 = Color3.fromRGB(80, 80, 80),
                                        TextSize = normalTextSize,
            TextWrapped = true,
                                        BackgroundTransparency = 1,
                                        Font = Enum.Font.Gotham,
                                        TextXAlignment = Enum.TextXAlignment.Center,
                                        ZIndex = 34
                                    }, {
                                        TextSizeConstraint = e("UITextSizeConstraint", {
                                            MaxTextSize = 12 * scale,
                                            MinTextSize = 8 * scale
                                        })
                                    })
                                })
                            end
                        end
                        
                        return forecastCards
                    end)())
                })
            })
        })
    })
    })
end

return WeatherPanel