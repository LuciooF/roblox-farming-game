-- Planting Panel Component
-- Shows player's inventory in a scrollable list for planting seeds
-- Displays relevant information: watering needed, production per hour, price

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local e = React.createElement
local assets = require(game:GetService("ReplicatedStorage").Shared.assets)
local ClientLogger = require(script.Parent.Parent.ClientLogger)
local CropRegistry = require(game:GetService("ReplicatedStorage").Shared.CropRegistry)
local NumberFormatter = require(game:GetService("ReplicatedStorage").Shared.NumberFormatter)
local ScreenUtils = require(game:GetService("ReplicatedStorage").Shared.ScreenUtils)

local log = ClientLogger.getModuleLogger("PlantingPanel")
local Modal = require(script.Parent.Modal)

-- Sound IDs for button interactions
local HOVER_SOUND_ID = "rbxassetid://15675059323"
local CLICK_SOUND_ID = "rbxassetid://6324790483"

-- Pre-create sounds for better performance
local hoverSound = Instance.new("Sound")
hoverSound.SoundId = HOVER_SOUND_ID
hoverSound.Volume = 0.3
hoverSound.Parent = SoundService

local clickSound = Instance.new("Sound")
clickSound.SoundId = CLICK_SOUND_ID
clickSound.Volume = 0.4
clickSound.Parent = SoundService

-- Function to play sound effects
local function playSound(soundType)
    if soundType == "hover" and hoverSound then
        hoverSound:Play()
    elseif soundType == "click" and clickSound then
        clickSound:Play()
    end
end

-- Function to create flip animation for icons
local function createFlipAnimation(iconRef, animationTracker)
    if not iconRef.current then return end
    
    -- Cancel any existing animation for this icon
    if animationTracker.current then
        pcall(function()
            animationTracker.current:Cancel()
        end)
        pcall(function()
            animationTracker.current:Destroy()
        end)
        animationTracker.current = nil
    end
    
    -- Reset rotation to 0 to prevent accumulation
    iconRef.current.Rotation = 0
    
    -- Create new animation
    animationTracker.current = TweenService:Create(
        iconRef.current,
        TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Rotation = 360 }
    )
    
    animationTracker.current:Play()
end

local function PlantingPanel(props)
    local playerData = props.playerData
    local visible = props.visible or false
    local onClose = props.onClose or function() end
    local onPlant = props.onPlant or function() end -- function(seedType, quantity)
    local plotData = props.plotData or {}
    local plantingMode = props.plantingMode or "single" -- "single" or "all"
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    
    -- Calculate available plot space for "all" mode
    local MAX_PLANTS_PER_PLOT = 50
    local currentPlants = 0
    if plotData.state and plotData.state ~= "empty" then
        currentPlants = (plotData.maxHarvests or 0) - (plotData.harvestCount or 0)
    end
    local availableSpace = MAX_PLANTS_PER_PLOT - currentPlants
    
    -- Debug planting panel visibility
    React.useEffect(function()
        log.debug("PlantingPanel visibility changed to:", visible)
    end, {visible})
    
    -- Responsive sizing
    local scale = ScreenUtils.getProportionalScale(screenSize)
    local panelWidth = math.min(screenSize.X * 0.9, ScreenUtils.getProportionalSize(screenSize, 800))
    local panelHeight = math.min(screenSize.Y * 0.85, ScreenUtils.getProportionalSize(screenSize, 600))
    
    -- Proportional text sizes
    local titleTextSize = ScreenUtils.getProportionalTextSize(screenSize, 32)
    local normalTextSize = ScreenUtils.getProportionalTextSize(screenSize, 18)
    local smallTextSize = ScreenUtils.getProportionalTextSize(screenSize, 14)
    local buttonTextSize = ScreenUtils.getProportionalTextSize(screenSize, 16)
    local cardTitleSize = ScreenUtils.getProportionalTextSize(screenSize, 20)
    local cardValueSize = ScreenUtils.getProportionalTextSize(screenSize, 16)
    
    -- Get plantable seeds from inventory
    local plantableSeeds = {}
    
    -- Debug logging to see what's in the inventory
    React.useEffect(function()
        if visible then
            log.info("PlantingPanel opened - debugging inventory:")
            log.info("playerData exists:", playerData ~= nil)
            if playerData then
                log.info("playerData.inventory exists:", playerData.inventory ~= nil)
                if playerData.inventory then
                    log.info("inventory.seeds exists:", playerData.inventory.seeds ~= nil)
                    log.info("inventory.crops exists:", playerData.inventory.crops ~= nil)
                    if playerData.inventory.seeds then
                        log.info("Seeds in inventory:", playerData.inventory.seeds)
                        for k, v in pairs(playerData.inventory.seeds) do
                            log.info("  Seed:", k, "Quantity:", v)
                        end
                    end
                    if playerData.inventory.crops then
                        log.info("Crops in inventory:", playerData.inventory.crops)
                        for k, v in pairs(playerData.inventory.crops) do
                            log.info("  Crop:", k, "Quantity:", v)
                        end
                    end
                end
            end
        end
    end, {visible, playerData})
    
    -- Check both seeds and crops in inventory
    if playerData.inventory then
        -- Check seeds first
        if playerData.inventory.seeds then
            for seedType, quantity in pairs(playerData.inventory.seeds) do
                if quantity > 0 then
                    local crop = CropRegistry.getCrop(seedType)
                    local visual = crop -- Use crop data directly since it contains all visual info
                    if crop and visual then
                        table.insert(plantableSeeds, {
                            type = seedType,
                            quantity = quantity,
                            crop = crop,
                            visual = visual
                        })
                    end
                end
            end
        end
        
        -- Also check crops that can be planted as seeds
        if playerData.inventory.crops then
            for cropType, quantity in pairs(playerData.inventory.crops) do
                if quantity > 0 then
                    local crop = CropRegistry.getCrop(cropType)
                    local visual = crop -- Use crop data directly since it contains all visual info
                    if crop and visual then
                        -- Check if we already have this from seeds to avoid duplicates
                        local alreadyExists = false
                        for _, existingSeed in ipairs(plantableSeeds) do
                            if existingSeed.type == cropType then
                                -- Add crop quantity to existing seed quantity
                                existingSeed.quantity = existingSeed.quantity + quantity
                                alreadyExists = true
                                break
                            end
                        end
                        
                        if not alreadyExists then
                            table.insert(plantableSeeds, {
                                type = cropType,
                                quantity = quantity,
                                crop = crop,
                                visual = visual
                            })
                        end
                    end
                end
            end
        end
    end
    
    -- Sort by rarity and then by name for consistent ordering
    table.sort(plantableSeeds, function(a, b)
        local rarityOrder = {
            common = 1, basic = 2, uncommon = 3, quality = 4, rare = 5,
            premium = 6, epic = 7, elite = 8, legendary = 9, mythic = 10,
            ancient = 11, divine = 12, celestial = 13, cosmic = 14, universal = 15
        }
        local aRarity = rarityOrder[a.crop.rarity] or 999
        local bRarity = rarityOrder[b.crop.rarity] or 999
        
        if aRarity == bRarity then
            return a.crop.name < b.crop.name
        end
        return aRarity < bRarity
    end)
    
    -- Calculate scroll height for all seed cards
    local cardHeight = ScreenUtils.getProportionalSize(screenSize, 100)
    local cardSpacing = 10
    local totalCards = #plantableSeeds
    local totalHeight = (totalCards * cardHeight) + ((totalCards - 1) * cardSpacing) + 40 -- padding
    
    -- Handle seed planting
    local function handlePlant(seedType)
        playSound("click")
        if onPlant then
            local quantity = 1 -- Default for single mode
            
            if plantingMode == "all" then
                -- Calculate how many we can plant
                local seedCount = 0
                if playerData.inventory and playerData.inventory.seeds then
                    seedCount = seedCount + (playerData.inventory.seeds[seedType] or 0)
                end
                if playerData.inventory and playerData.inventory.crops then
                    seedCount = seedCount + (playerData.inventory.crops[seedType] or 0)
                end
                
                -- Plant the minimum of available space and seeds owned
                quantity = math.min(availableSpace, seedCount)
                quantity = math.max(1, quantity) -- At least 1
            end
            
            onPlant(seedType, quantity)
        end
        -- onClose() is now handled by onPlant in MainUI
    end
    
    -- Rarity colors for borders and effects
    local rarityColors = {
        common = Color3.fromRGB(150, 150, 150),
        basic = Color3.fromRGB(139, 69, 19),
        uncommon = Color3.fromRGB(100, 255, 100),
        quality = Color3.fromRGB(0, 191, 255),
        rare = Color3.fromRGB(100, 100, 255),
        premium = Color3.fromRGB(255, 140, 0),
        epic = Color3.fromRGB(255, 100, 255),
        elite = Color3.fromRGB(255, 0, 0),
        legendary = Color3.fromRGB(255, 215, 0),
        mythic = Color3.fromRGB(255, 20, 147),
        ancient = Color3.fromRGB(139, 0, 139),
        divine = Color3.fromRGB(255, 255, 255),
        celestial = Color3.fromRGB(135, 206, 250),
        cosmic = Color3.fromRGB(75, 0, 130),
        universal = Color3.fromRGB(25, 25, 112)
    }
    
    return e(Modal, {
        visible = visible,
        onClose = onClose,
        zIndex = 30
    }, {
        PlantingContainer = e("Frame", {
            Name = "PlantingContainer",
            Size = UDim2.new(0, panelWidth, 0, panelHeight + 50),
            Position = UDim2.new(0.5, -panelWidth / 2, 0.5, -(panelHeight + 50) / 2),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 30
        }, {
            PlantingPanel = e("Frame", {
                Name = "PlantingPanel",
                Size = UDim2.new(0, panelWidth, 0, panelHeight),
                Position = UDim2.new(0, 0, 0, 50),
                BackgroundColor3 = Color3.fromRGB(240, 255, 240),
                BackgroundTransparency = 0.05,
                BorderSizePixel = 0,
                ZIndex = 30
            }, {
                -- Floating Title
                FloatingTitle = e("Frame", {
                    Name = "FloatingTitle",
                    Size = UDim2.new(0, 180, 0, 40),
                    Position = UDim2.new(0, -10, 0, -25),
                    BackgroundColor3 = Color3.fromRGB(100, 200, 100),
                    BorderSizePixel = 0,
                    ZIndex = 32
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 12)
                    }),
                    Gradient = e("UIGradient", {
                        Color = ColorSequence.new{
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 220, 120)),
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 180, 80))
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
                        
                        PlantIcon = e("ImageLabel", {
                            Name = "PlantIcon",
                            Size = UDim2.new(0, 24, 0, 24),
                            Image = assets["General/Plant/Plant Outline 256.png"] or "",
                            BackgroundTransparency = 1,
                            ScaleType = Enum.ScaleType.Fit,
                            ImageColor3 = Color3.fromRGB(255, 255, 255),
                            ZIndex = 34,
                            LayoutOrder = 1
                        }),
                        
                        TitleText = e("TextLabel", {
                            Size = UDim2.new(0, 0, 1, 0),
                            AutomaticSize = Enum.AutomaticSize.X,
                            Text = plantingMode == "all" and "PLANT ALL SEEDS" or "PLANT SEEDS",
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
                    Color = Color3.fromRGB(100, 200, 100),
                    Thickness = 3,
                    Transparency = 0.1
                }),
                
                Gradient = e("UIGradient", {
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                        ColorSequenceKeypoint.new(0.3, Color3.fromRGB(250, 255, 250)),
                        ColorSequenceKeypoint.new(0.7, Color3.fromRGB(245, 255, 245)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(240, 255, 240))
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
                
                -- Subtitle
                Subtitle = e("TextLabel", {
                    Name = "Subtitle",
                    Size = UDim2.new(1, -80, 0, 25),
                    Position = UDim2.new(0, 40, 0, 15),
                    Text = totalCards > 0 and 
                        (plantingMode == "all" and 
                            ("Choose seed to fill " .. availableSpace .. " slots (from " .. totalCards .. " types)") or 
                            ("Choose from " .. totalCards .. " available seeds")
                        ) or "No seeds available to plant",
                    TextColor3 = Color3.fromRGB(60, 120, 60),
                    TextSize = normalTextSize,
            TextWrapped = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 31
                }),
                
                -- Seeds Container
                SeedsContainer = totalCards > 0 and e("ScrollingFrame", {
                    Name = "SeedsContainer",
                    Size = UDim2.new(1, -40, 1, -80),
                    Position = UDim2.new(0, 20, 0, 50),
                    BackgroundColor3 = Color3.fromRGB(250, 255, 250),
                    BackgroundTransparency = 0.2,
                    BorderSizePixel = 0,
                    ScrollBarThickness = 12,
                    ScrollingDirection = Enum.ScrollingDirection.Y,
                    CanvasSize = UDim2.new(0, 0, 0, totalHeight),
                    ScrollBarImageColor3 = Color3.fromRGB(100, 200, 100),
                    ZIndex = 31
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 15)
                    }),
                    ContainerGradient = e("UIGradient", {
                        Color = ColorSequence.new{
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(245, 255, 245))
                        },
                        Rotation = 45
                    }),
                    
                    -- List Layout
                    ListLayout = e("UIListLayout", {
                        FillDirection = Enum.FillDirection.Vertical,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Top,
                        Padding = UDim.new(0, cardSpacing),
                        SortOrder = Enum.SortOrder.LayoutOrder
                    }),
                    
                    Padding = e("UIPadding", {
                        PaddingTop = UDim.new(0, 20),
                        PaddingLeft = UDim.new(0, 20),
                        PaddingRight = UDim.new(0, 20),
                        PaddingBottom = UDim.new(0, 20)
                    }),
                    
                    -- Generate seed cards
                    SeedCards = React.createElement(React.Fragment, {}, (function()
                        local cards = {}
                        
                        for i, seedData in ipairs(plantableSeeds) do
                            local crop = seedData.crop
                            local rarity = crop.rarity or "common"
                            local rarityColor = rarityColors[rarity] or rarityColors.common
                            
                            -- Get production per hour from crop registry
                            local productionPerHour = crop.productionRate or 0
                            
                            -- Animation refs
                            local seedIconRef = React.useRef(nil)
                            local seedAnimTracker = React.useRef(nil)
                            
                            cards[seedData.type] = e("TextButton", {
                                Name = seedData.type .. "Card",
                                Size = UDim2.new(1, -40, 0, cardHeight),
                                Text = "",
                                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                BackgroundTransparency = 0.05,
                                BorderSizePixel = 0,
                                ZIndex = 32,
                                LayoutOrder = i,
                                AutoButtonColor = false,
                                [React.Event.MouseEnter] = function()
                                    playSound("hover")
                                    createFlipAnimation(seedIconRef, seedAnimTracker)
                                end,
                                [React.Event.Activated] = function()
                                    handlePlant(seedData.type)
                                    createFlipAnimation(seedIconRef, seedAnimTracker)
                                end
                            }, {
                                Corner = e("UICorner", {
                                    CornerRadius = UDim.new(0, 12)
                                }),
                                
                                Stroke = e("UIStroke", {
                                    Color = rarityColor,
                                    Thickness = 3,
                                    Transparency = 0.1
                                }),
                                
                                CardGradient = e("UIGradient", {
                                    Color = ColorSequence.new{
                                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                                        ColorSequenceKeypoint.new(1, Color3.fromRGB(248, 255, 248))
                                    },
                                    Rotation = 45
                                }),
                                
                                -- Seed Icon
                                SeedIcon = seedData.visual and seedData.visual.assetId and e("ImageLabel", {
                                    Name = "SeedIcon",
                                    Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 70), 0, ScreenUtils.getProportionalSize(screenSize, 70)),
                                    Position = UDim2.new(0, 15, 0.5, -ScreenUtils.getProportionalSize(screenSize, 35)),
                                    Image = seedData.visual.assetId:gsub("-64%.png", "-outline-256.png"):gsub("-256%.png", "-outline-256.png"),
                                    BackgroundTransparency = 1,
                                    ScaleType = Enum.ScaleType.Fit,
                                    ZIndex = 33,
                                    ref = seedIconRef
                                }) or e("TextLabel", {
                                    Name = "SeedEmoji",
                                    Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 70), 0, ScreenUtils.getProportionalSize(screenSize, 70)),
                                    Position = UDim2.new(0, 15, 0.5, -ScreenUtils.getProportionalSize(screenSize, 35)),
                                    Text = seedData.visual and seedData.visual.emoji or "🌱",
                                    TextSize = normalTextSize,
            TextWrapped = true,
                                    BackgroundTransparency = 1,
                                    Font = Enum.Font.SourceSansBold,
                                    ZIndex = 33,
                                    ref = seedIconRef
                                }),
                                
                                -- Seed Name
                                SeedName = e("TextLabel", {
                                    Name = "SeedName",
                                    Size = UDim2.new(0, 150, 0, 20),
                                    Position = UDim2.new(0, 100, 0, 10),
                                    Text = crop.name,
                                    TextColor3 = Color3.fromRGB(40, 40, 40),
                                    TextSize = normalTextSize,
            TextWrapped = true,
                                    BackgroundTransparency = 1,
                                    Font = Enum.Font.GothamBold,
                                    TextXAlignment = Enum.TextXAlignment.Left,
                                    ZIndex = 33
                                }),
                                
                                -- Rarity Badge
                                RarityBadge = e("Frame", {
                                    Name = "RarityBadge",
                                    Size = UDim2.new(0, 70, 0, 16),
                                    Position = UDim2.new(0, 100, 0, 35),
                                    BackgroundColor3 = rarityColor,
                                    BorderSizePixel = 0,
                                    ZIndex = 33
                                }, {
                                    Corner = e("UICorner", {
                                        CornerRadius = UDim.new(0, 8)
                                    }),
                                    RarityText = e("TextLabel", {
                                        Size = UDim2.new(1, 0, 1, 0),
                                        Text = rarity:upper(),
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
                                
                                -- Quantity Badge
                                QuantityBadge = e("Frame", {
                                    Name = "QuantityBadge",
                                    Size = UDim2.new(0, 50, 0, 20),
                                    Position = UDim2.new(0, 100, 0, 55),
                                    BackgroundColor3 = Color3.fromRGB(80, 160, 80),
                                    BorderSizePixel = 0,
                                    ZIndex = 33
                                }, {
                                    Corner = e("UICorner", {
                                        CornerRadius = UDim.new(0, 10)
                                    }),
                                    QuantityText = e("TextLabel", {
                                        Size = UDim2.new(1, 0, 1, 0),
                                        Text = "x" .. NumberFormatter.format(seedData.quantity),
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
                                
                                -- Stats Container (middle column - between left info and right buttons)
                                StatsContainer = e("Frame", {
                                    Name = "StatsContainer",
                                    Size = UDim2.new(0, 180, 1, -20),
                                    Position = UDim2.new(0, 200, 0, 10),
                                    BackgroundTransparency = 1,
                                    ZIndex = 33
                                }, {
                                    StatsLayout = e("UIListLayout", {
                                        FillDirection = Enum.FillDirection.Vertical,
                                        HorizontalAlignment = Enum.HorizontalAlignment.Left,
                                        VerticalAlignment = Enum.VerticalAlignment.Center,
                                        Padding = UDim.new(0, 5),
                                        SortOrder = Enum.SortOrder.LayoutOrder
                                    }),
                                    
                                    -- Water Needed
                                    WaterStat = e("Frame", {
                                        Name = "WaterStat",
                                        Size = UDim2.new(1, 0, 0, 18),
                                        BackgroundTransparency = 1,
                                        LayoutOrder = 1
                                    }, {
                                        Layout = e("UIListLayout", {
                                            FillDirection = Enum.FillDirection.Horizontal,
                                            VerticalAlignment = Enum.VerticalAlignment.Center,
                                            Padding = UDim.new(0, 5)
                                        }),
                                        WaterIcon = e("TextLabel", {
                                            Size = UDim2.new(0, 16, 0, 16),
                                            Text = "💧",
                                            TextSize = normalTextSize,
            TextWrapped = true,
                                            BackgroundTransparency = 1,
                                            Font = Enum.Font.SourceSansBold,
                                            LayoutOrder = 1
                                        }),
                                        WaterText = e("TextLabel", {
                                            Size = UDim2.new(0, 0, 1, 0),
                                            AutomaticSize = Enum.AutomaticSize.X,
                                            Text = "Waters needed: " .. crop.waterNeeded,
                                            TextColor3 = Color3.fromRGB(0, 100, 255),
                                            TextSize = ScreenUtils.getProportionalTextSize(screenSize, 14),
                                            BackgroundTransparency = 1,
                                            Font = Enum.Font.Gotham,
                                            TextXAlignment = Enum.TextXAlignment.Left,
                                            LayoutOrder = 2
                                        })
                                    }),
                                    
                                    -- Production Rate
                                    ProductionStat = e("Frame", {
                                        Name = "ProductionStat",
                                        Size = UDim2.new(1, 0, 0, 18),
                                        BackgroundTransparency = 1,
                                        LayoutOrder = 2
                                    }, {
                                        Layout = e("UIListLayout", {
                                            FillDirection = Enum.FillDirection.Horizontal,
                                            VerticalAlignment = Enum.VerticalAlignment.Center,
                                            Padding = UDim.new(0, 5)
                                        }),
                                        ProductionIcon = e("TextLabel", {
                                            Size = UDim2.new(0, 16, 0, 16),
                                            Text = "⚡",
                                            TextSize = normalTextSize,
            TextWrapped = true,
                                            BackgroundTransparency = 1,
                                            Font = Enum.Font.SourceSansBold,
                                            LayoutOrder = 1
                                        }),
                                        ProductionText = e("TextLabel", {
                                            Size = UDim2.new(0, 0, 1, 0),
                                            AutomaticSize = Enum.AutomaticSize.X,
                                            Text = "Production: " .. productionPerHour .. "/hour",
                                            TextColor3 = Color3.fromRGB(255, 50, 50),
                                            TextSize = ScreenUtils.getProportionalTextSize(screenSize, 14),
                                            BackgroundTransparency = 1,
                                            Font = Enum.Font.Gotham,
                                            TextXAlignment = Enum.TextXAlignment.Left,
                                            LayoutOrder = 2
                                        })
                                    }),
                                    
                                    -- Sell Price
                                    PriceStat = e("Frame", {
                                        Name = "PriceStat",
                                        Size = UDim2.new(1, 0, 0, 18),
                                        BackgroundTransparency = 1,
                                        LayoutOrder = 3
                                    }, {
                                        Layout = e("UIListLayout", {
                                            FillDirection = Enum.FillDirection.Horizontal,
                                            VerticalAlignment = Enum.VerticalAlignment.Center,
                                            Padding = UDim.new(0, 5)
                                        }),
                                        PriceIcon = e("ImageLabel", {
                                            Size = UDim2.new(0, 16, 0, 16),
                                            Image = assets["Currency/Cash/Cash Outline 256.png"] or "",
                                            BackgroundTransparency = 1,
                                            ScaleType = Enum.ScaleType.Fit,
                                            ImageColor3 = Color3.fromRGB(255, 215, 0),
                                            LayoutOrder = 1
                                        }),
                                        PriceText = e("TextLabel", {
                                            Size = UDim2.new(0, 0, 1, 0),
                                            AutomaticSize = Enum.AutomaticSize.X,
                                            Text = "Sell price: $" .. NumberFormatter.format(crop.basePrice),
                                            TextColor3 = Color3.fromRGB(50, 180, 50),
                                            TextSize = ScreenUtils.getProportionalTextSize(screenSize, 14),
                                            BackgroundTransparency = 1,
                                            Font = Enum.Font.Gotham,
                                            TextXAlignment = Enum.TextXAlignment.Left,
                                            LayoutOrder = 2
                                        })
                                    })
                                }),
                                
                                -- Button Container (rightmost column - relative to card)
                                ButtonContainer = e("Frame", {
                                    Name = "ButtonContainer",
                                    Size = UDim2.new(0, 100, 1, -10),
                                    Position = UDim2.new(1, -110, 0, 5),
                                    BackgroundTransparency = 1,
                                    ZIndex = 34
                                }, {
                                    ButtonLayout = e("UIListLayout", {
                                        FillDirection = Enum.FillDirection.Vertical,
                                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                        VerticalAlignment = Enum.VerticalAlignment.Center,
                                        Padding = UDim.new(0, 5),
                                        SortOrder = Enum.SortOrder.LayoutOrder
                                    }),
                                    
                                    -- Plant Button
                                    PlantButton = e("TextButton", {
                                        Name = "PlantButton",
                                        Size = UDim2.new(0, 90, 0, 30),
                                        Text = "PLANT",
                                        TextColor3 = Color3.fromRGB(255, 255, 255),
                                        TextTransparency = 0,
                                        TextSize = ScreenUtils.getProportionalTextSize(screenSize, 14),
                                        TextWrapped = true,
                                        BackgroundColor3 = Color3.fromRGB(100, 200, 100),
                                        BorderSizePixel = 0,
                                        Font = Enum.Font.GothamBold,
                                        ZIndex = 35,
                                        LayoutOrder = 1,
                                        AutoButtonColor = false,
                                        [React.Event.Activated] = function()
                                            handlePlant(seedData.type)
                                        end
                                    }, {
                                        Corner = e("UICorner", {
                                            CornerRadius = UDim.new(0, 8)
                                        }),
                                        ButtonGradient = e("UIGradient", {
                                            Color = ColorSequence.new{
                                                ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 220, 120)),
                                                ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 180, 80))
                                            },
                                            Rotation = 45
                                        }),
                                        ButtonStroke = e("UIStroke", {
                                            Color = Color3.fromRGB(255, 255, 255),
                                            Thickness = 2,
                                            Transparency = 0.2
                                        }),
                                        TextStroke = e("UIStroke", {
                                            Color = Color3.fromRGB(0, 0, 0),
                                            Thickness = 2,
                                            Transparency = 0
                                        })
                                    }),
                                    
                                    -- Plant All Button (only show if we have more than 1 seed and space for more than 1)
                                    PlantAllButton = (seedData.quantity > 1 and availableSpace > 1) and e("TextButton", {
                                        Name = "PlantAllButton",
                                        Size = UDim2.new(0, 90, 0, 30),
                                        Text = "PLANT ALL (" .. math.min(seedData.quantity, availableSpace) .. ")",
                                        TextColor3 = Color3.fromRGB(255, 255, 255),
                                        TextTransparency = 0,
                                        TextSize = ScreenUtils.getProportionalTextSize(screenSize, 12),
                                        TextWrapped = true,
                                        BackgroundColor3 = Color3.fromRGB(100, 200, 100),
                                        BorderSizePixel = 0,
                                        Font = Enum.Font.GothamBold,
                                        ZIndex = 35,
                                        LayoutOrder = 2,
                                        AutoButtonColor = false,
                                        [React.Event.Activated] = function()
                                            local plantQuantity = math.min(seedData.quantity, availableSpace)
                                            onPlant(seedData.type, plantQuantity)
                                            -- onClose() is handled by onPlant now
                                        end
                                    }, {
                                        Corner = e("UICorner", {
                                            CornerRadius = UDim.new(0, 8)
                                        }),
                                        ButtonGradient = e("UIGradient", {
                                            Color = ColorSequence.new{
                                                ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 220, 120)),
                                                ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 180, 80))
                                            },
                                            Rotation = 45
                                        }),
                                        ButtonStroke = e("UIStroke", {
                                            Color = Color3.fromRGB(255, 255, 255),
                                            Thickness = 2,
                                            Transparency = 0.2
                                        }),
                                        TextStroke = e("UIStroke", {
                                            Color = Color3.fromRGB(0, 0, 0),
                                            Thickness = 2,
                                            Transparency = 0
                                        })
                                    }) or nil
                                })
                            })
                        end
                        
                        return cards
                    end)())
                }) or e("Frame", {
                    Name = "EmptyState",
                    Size = UDim2.new(1, -40, 1, -80),
                    Position = UDim2.new(0, 20, 0, 50),
                    BackgroundColor3 = Color3.fromRGB(250, 250, 250),
                    BackgroundTransparency = 0.2,
                    BorderSizePixel = 0,
                    ZIndex = 31
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 15)
                    }),
                    EmptyText = e("TextLabel", {
                        Size = UDim2.new(1, -40, 0, 100),
                        Position = UDim2.new(0, 20, 0.5, -50),
                        Text = "🌱\n\nNo seeds available!\nVisit the shop to buy seeds.",
                        TextColor3 = Color3.fromRGB(120, 120, 120),
                        TextSize = 18,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        ZIndex = 32
                    })
                })
            })
        })
    })
end

return PlantingPanel