-- Like Favorite Popup Component
-- Shows countdown timer for group join and favorite requirements

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local ScreenUtils = require(game:GetService("ReplicatedStorage").Shared.ScreenUtils)
local assets = require(game:GetService("ReplicatedStorage").Shared.assets)
local StarterGui = game:GetService("StarterGui")
local e = React.createElement

local function LikeFavoritePopup(props)
    local visible = props.visible
    local onClose = props.onClose
    local waitTimeSeconds = props.waitTimeSeconds or 120
    local groupId = props.groupId or 1019485148  -- Your actual group ID
    local gameId = 136067542867963  -- Your game ID
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    
    -- State for countdown
    local timeRemaining, setTimeRemaining = React.useState(waitTimeSeconds)
    local hasShownFavoritePrompt, setHasShownFavoritePrompt = React.useState(false)
    
    -- Countdown effect
    React.useEffect(function()
        if not visible or timeRemaining <= 0 then
            return
        end
        
        local connection = task.spawn(function()
            while timeRemaining > 0 and visible do
                task.wait(1)
                setTimeRemaining(function(current)
                    return math.max(0, current - 1)
                end)
            end
        end)
        
        return function()
            if connection then
                task.cancel(connection)
            end
        end
    end, {visible, timeRemaining})
    
    -- Show favorite prompt immediately when popup opens
    React.useEffect(function()
        if not visible or hasShownFavoritePrompt then
            return
        end
        
        -- Show prompt immediately without delay
        setHasShownFavoritePrompt(true)
        
        -- Try to show the favorite prompt with proper service
        local success, err = pcall(function()
            local AvatarEditorService = game:GetService("AvatarEditorService")
            AvatarEditorService:PromptSetFavorite(gameId, Enum.AvatarItemType.Asset, true)
        end)
        
        if not success then
            print("[WARN] Failed to show favorite prompt:", err)
        end
    end, {visible, hasShownFavoritePrompt})
    
    -- Responsive sizing
    local scale = ScreenUtils.getProportionalScale(screenSize)
    local popupWidth = ScreenUtils.getProportionalSize(screenSize, 400)
    local popupHeight = ScreenUtils.getProportionalSize(screenSize, 320)
    
    -- Text sizes
    local titleTextSize = ScreenUtils.getProportionalTextSize(screenSize, 24)
    local normalTextSize = ScreenUtils.getProportionalTextSize(screenSize, 18)
    local timerTextSize = ScreenUtils.getProportionalTextSize(screenSize, 32)
    local buttonTextSize = ScreenUtils.getProportionalTextSize(screenSize, 16)
    
    -- Format time as MM:SS
    local function formatTime(seconds)
        local minutes = math.floor(seconds / 60)
        local secs = seconds % 60
        return string.format("%02d:%02d", minutes, secs)
    end
    
    if not visible then return nil end
    
    return e("Frame", {
        Name = "LikeFavoriteOverlay",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        ZIndex = 50
    }, {
        PopupContainer = e("Frame", {
            Name = "PopupContainer",
            Size = UDim2.new(0, popupWidth, 0, popupHeight),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(245, 250, 255),
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
            ZIndex = 51
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 20)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(100, 150, 255),
                Thickness = 3,
                Transparency = 0.1
            }),
            Gradient = e("UIGradient", {
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(0.3, Color3.fromRGB(240, 245, 255)),
                    ColorSequenceKeypoint.new(0.7, Color3.fromRGB(230, 240, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 235, 255))
                },
                Rotation = 135
            }),
            
            -- Title
            Title = e("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -40, 0, ScreenUtils.getProportionalSize(screenSize, 40)),
                Position = UDim2.new(0, 20, 0, 20),
                Text = "🌟 Join & Favorite Required! 🌟",
                TextColor3 = Color3.fromRGB(50, 100, 200),
                TextSize = titleTextSize,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                BackgroundTransparency = 1,
                ZIndex = 52
            }, {
                TextStroke = e("UIStroke", {
                    Color = Color3.fromRGB(255, 255, 255),
                    Thickness = 2,
                    Transparency = 0.3
                })
            }),
            
            -- Instructions
            Instructions = e("TextLabel", {
                Name = "Instructions",
                Size = UDim2.new(1, -40, 0, ScreenUtils.getProportionalSize(screenSize, 60)),
                Position = UDim2.new(0, 20, 0, 80),
                Text = "Please join our group and favorite the game to unlock codes!\n\nClick the star on the favorite prompt that just appeared.\nCome back when the timer reaches 00:00",
                TextColor3 = Color3.fromRGB(80, 80, 80),
                TextSize = normalTextSize,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Top,
                BackgroundTransparency = 1,
                TextWrapped = true,
                ZIndex = 52
            }),
            
            -- Timer Display
            TimerContainer = e("Frame", {
                Name = "TimerContainer",
                Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 150), 0, ScreenUtils.getProportionalSize(screenSize, 60)),
                Position = UDim2.new(0.5, 0, 0, ScreenUtils.getProportionalSize(screenSize, 160)),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundColor3 = timeRemaining <= 10 and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 200, 100),
                BorderSizePixel = 0,
                ZIndex = 52
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 15)
                }),
                Stroke = e("UIStroke", {
                    Color = Color3.fromRGB(255, 255, 255),
                    Thickness = 3,
                    Transparency = 0.2
                }),
                Gradient = e("UIGradient", {
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, timeRemaining <= 10 and Color3.fromRGB(255, 140, 140) or Color3.fromRGB(140, 220, 140)),
                        ColorSequenceKeypoint.new(1, timeRemaining <= 10 and Color3.fromRGB(200, 60, 60) or Color3.fromRGB(60, 180, 60))
                    },
                    Rotation = 90
                }),
                TimerText = e("TextLabel", {
                    Name = "TimerText",
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = formatTime(timeRemaining),
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = timerTextSize,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    BackgroundTransparency = 1,
                    ZIndex = 53
                }, {
                    TextStroke = e("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = 2,
                        Transparency = 0.3
                    })
                })
            }),
            
            -- Favorite Game Button
            FavoriteButton = e("TextButton", {
                Name = "FavoriteButton",
                Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 150), 0, ScreenUtils.getProportionalSize(screenSize, 40)),
                Position = UDim2.new(0.5, 0, 0, ScreenUtils.getProportionalSize(screenSize, 240)),
                AnchorPoint = Vector2.new(0.5, 0),
                Text = "⭐ Favorite Game",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = buttonTextSize,
                Font = Enum.Font.GothamBold,
                BackgroundColor3 = Color3.fromRGB(255, 200, 50),
                BorderSizePixel = 0,
                ZIndex = 53,
                [React.Event.Activated] = function()
                    -- Manually trigger the favorite prompt
                    local success, err = pcall(function()
                        local AvatarEditorService = game:GetService("AvatarEditorService")
                        AvatarEditorService:PromptSetFavorite(gameId, Enum.AvatarItemType.Asset, true)
                    end)
                    
                    if not success then
                        print("[WARN] Failed to show favorite prompt:", err)
                    end
                end
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 8)
                }),
                Gradient = e("UIGradient", {
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 80)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(235, 180, 30))
                    },
                    Rotation = 90
                }),
                Stroke = e("UIStroke", {
                    Color = Color3.fromRGB(255, 255, 255),
                    Thickness = 2,
                    Transparency = 0.2
                })
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
                ZIndex = 54,
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
            })
        })
    })
end

return LikeFavoritePopup