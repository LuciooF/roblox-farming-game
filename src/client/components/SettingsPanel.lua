-- Settings Panel Component
-- Provides debug controls and settings for development

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local e = React.createElement
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local assets = require(game:GetService("ReplicatedStorage").Shared.assets)
local Players = game:GetService("Players")

local ScreenUtils = require(ReplicatedStorage.Shared.ScreenUtils)
local ClientLogger = require(script.Parent.Parent.ClientLogger)

local log = ClientLogger.getModuleLogger("SettingsPanel")
local player = Players.LocalPlayer

local function SettingsPanel(props)
    local visible = props.visible or false
    local onClose = props.onClose or function() end
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    
    -- Calculate responsive sizing
    local scale = ScreenUtils.getCustomScale(screenSize, 1, 0.8)
    local panelWidth = math.min(400 * scale, screenSize.X * 0.9)
    local panelHeight = math.min(500 * scale, screenSize.Y * 0.8)
    
    if not visible then
        return nil
    end
    
    -- Debug action handlers
    local function addRebirth()
        local remotes = ReplicatedStorage:FindFirstChild("FarmingRemotes")
        if remotes then
            local debugRemote = remotes:FindFirstChild("DebugActions")
            if debugRemote then
                debugRemote:FireServer("addRebirth")
                log.info("Requested +1 rebirth via settings")
            end
        end
    end
    
    local function resetRebirths()
        local remotes = ReplicatedStorage:FindFirstChild("FarmingRemotes")
        if remotes then
            local debugRemote = remotes:FindFirstChild("DebugActions")
            if debugRemote then
                debugRemote:FireServer("resetRebirths")
                log.info("Requested rebirth reset via settings")
            end
        end
    end
    
    local function resetDatastore()
        local remotes = ReplicatedStorage:FindFirstChild("FarmingRemotes")
        if remotes then
            local debugRemote = remotes:FindFirstChild("DebugActions")
            if debugRemote then
                debugRemote:FireServer("resetDatastore")
                log.info("Requested datastore reset via settings")
            end
        end
    end
    
    local function performRebirth()
        local remotes = ReplicatedStorage:FindFirstChild("FarmingRemotes")
        if remotes then
            local rebirthRemote = remotes:FindFirstChild("PerformRebirth")
            if rebirthRemote then
                rebirthRemote:FireServer()
                log.info("Requested normal rebirth via settings")
            end
        end
    end
    
    local function addMoney()
        local remotes = ReplicatedStorage:FindFirstChild("FarmingRemotes")
        if remotes then
            local debugRemote = remotes:FindFirstChild("DebugActions")
            if debugRemote then
                debugRemote:FireServer("addMoney", 1000) -- Add $1000
                log.info("Requested +$1000 via settings")
            end
        end
    end
    
    return e("Frame", {
        Name = "SettingsPanel",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        ZIndex = 100
    }, {
        -- Main panel
        MainPanel = e("Frame", {
            Name = "MainPanel",
            Size = UDim2.new(0, panelWidth, 0, panelHeight),
            Position = UDim2.new(0.5, -panelWidth/2, 0.5, -panelHeight/2),
            BackgroundColor3 = Color3.fromRGB(40, 40, 40),
            BorderSizePixel = 0,
            ZIndex = 101
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 12)
            }),
            
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(255, 100, 100),
                Thickness = 3
            }),
            
            -- Title bar
            TitleBar = e("Frame", {
                Name = "TitleBar",
                Size = UDim2.new(1, 0, 0, 50),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundColor3 = Color3.fromRGB(255, 100, 100),
                BorderSizePixel = 0,
                ZIndex = 102
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 12)
                }),
                
                Title = e("TextLabel", {
                    Name = "Title",
                    Size = UDim2.new(1, -60, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Text = "🛠️ DEBUG SETTINGS",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextScaled = true,
                    Font = Enum.Font.SourceSansBold,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 103
                }),
                
                CloseButton = e("ImageButton", {
                    Name = "CloseButton",
                    Size = UDim2.new(0, 40, 0, 40),
                    Position = UDim2.new(1, -45, 0, 5),
                    BackgroundColor3 = Color3.fromRGB(200, 50, 50),
                    Image = assets["X Button/X Button 64.png"],
                    ImageColor3 = Color3.fromRGB(255, 255, 255),
                    ScaleType = Enum.ScaleType.Fit,
                    BorderSizePixel = 0,
                    ZIndex = 103,
                    [React.Event.Activated] = onClose
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 8)
                    })
                })
            }),
            
            -- Content area
            Content = e("ScrollingFrame", {
                Name = "Content",
                Size = UDim2.new(1, -20, 1, -70),
                Position = UDim2.new(0, 10, 0, 60),
                BackgroundTransparency = 1,
                ScrollBarThickness = 8,
                CanvasSize = UDim2.new(0, 0, 0, 400),
                ZIndex = 102
            }, {
                Layout = e("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Top,
                    Padding = UDim.new(0, 10),
                    SortOrder = Enum.SortOrder.LayoutOrder
                }),
                
                Padding = e("UIPadding", {
                    PaddingLeft = UDim.new(0, 5),
                    PaddingRight = UDim.new(0, 5),
                    PaddingTop = UDim.new(0, 10)
                }),
                
                -- Rebirth section
                RebirthLabel = e("TextLabel", {
                    Name = "RebirthLabel",
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundTransparency = 1,
                    Text = "🔄 REBIRTH CONTROLS",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextScaled = true,
                    Font = Enum.Font.SourceSansBold,
                    LayoutOrder = 1,
                    ZIndex = 103
                }),
                
                AddRebirthBtn = e("TextButton", {
                    Name = "AddRebirthBtn",
                    Size = UDim2.new(1, 0, 0, 40),
                    BackgroundColor3 = Color3.fromRGB(0, 150, 0),
                    Text = "+1 Rebirth",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextScaled = true,
                    Font = Enum.Font.SourceSans,
                    BorderSizePixel = 0,
                    LayoutOrder = 2,
                    ZIndex = 103,
                    [React.Event.Activated] = addRebirth
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 6)
                    })
                }),
                
                ResetRebirthsBtn = e("TextButton", {
                    Name = "ResetRebirthsBtn", 
                    Size = UDim2.new(1, 0, 0, 40),
                    BackgroundColor3 = Color3.fromRGB(200, 100, 0),
                    Text = "Reset Rebirths",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextScaled = true,
                    Font = Enum.Font.SourceSans,
                    BorderSizePixel = 0,
                    LayoutOrder = 3,
                    ZIndex = 103,
                    [React.Event.Activated] = resetRebirths
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 6)
                    })
                }),
                
                PerformRebirthBtn = e("TextButton", {
                    Name = "PerformRebirthBtn",
                    Size = UDim2.new(1, 0, 0, 40),
                    BackgroundColor3 = Color3.fromRGB(100, 0, 200),
                    Text = "Perform Rebirth (Normal)",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextScaled = true,
                    Font = Enum.Font.SourceSans,
                    BorderSizePixel = 0,
                    LayoutOrder = 4,
                    ZIndex = 103,
                    [React.Event.Activated] = performRebirth
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 6)
                    })
                }),
                
                -- Money section
                MoneyLabel = e("TextLabel", {
                    Name = "MoneyLabel",
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundTransparency = 1,
                    Text = "💰 MONEY CONTROLS",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextScaled = true,
                    Font = Enum.Font.SourceSansBold,
                    LayoutOrder = 5,
                    ZIndex = 103
                }),
                
                AddMoneyBtn = e("TextButton", {
                    Name = "AddMoneyBtn",
                    Size = UDim2.new(1, 0, 0, 40),
                    BackgroundColor3 = Color3.fromRGB(255, 165, 0),
                    Text = "+$1000",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextScaled = true,
                    Font = Enum.Font.SourceSans,
                    BorderSizePixel = 0,
                    LayoutOrder = 6,
                    ZIndex = 103,
                    [React.Event.Activated] = addMoney
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 6)
                    })
                }),
                
                -- Data section
                DataLabel = e("TextLabel", {
                    Name = "DataLabel",
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundTransparency = 1,
                    Text = "💾 DATA CONTROLS",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextScaled = true,
                    Font = Enum.Font.SourceSansBold,
                    LayoutOrder = 7,
                    ZIndex = 103
                }),
                
                ResetDatastoreBtn = e("TextButton", {
                    Name = "ResetDatastoreBtn",
                    Size = UDim2.new(1, 0, 0, 40),
                    BackgroundColor3 = Color3.fromRGB(200, 0, 0),
                    Text = "⚠️ RESET ALL DATA ⚠️",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextScaled = true,
                    Font = Enum.Font.SourceSansBold,
                    BorderSizePixel = 0,
                    LayoutOrder = 8,
                    ZIndex = 103,
                    [React.Event.Activated] = resetDatastore
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 6)
                    })
                }),
                
                -- Warning text
                WarningText = e("TextLabel", {
                    Name = "WarningText",
                    Size = UDim2.new(1, 0, 0, 60),
                    BackgroundTransparency = 1,
                    Text = "⚠️ WARNING: These are debug controls!\nUse only for testing purposes.\nData changes are permanent!",
                    TextColor3 = Color3.fromRGB(255, 200, 200),
                    TextScaled = true,
                    Font = Enum.Font.SourceSans,
                    TextWrapped = true,
                    LayoutOrder = 9,
                    ZIndex = 103
                })
            })
        })
    })
end

return SettingsPanel