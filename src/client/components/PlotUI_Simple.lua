-- Minimal PlotUI to test React createTextInstance issue
local React = require(game:GetService("ReplicatedStorage").Packages.react)
local e = React.createElement
local Modal = require(script.Parent.Modal)
local assets = require(game:GetService("ReplicatedStorage").Shared.assets)
local CropRegistry = require(game:GetService("ReplicatedStorage").Shared.CropRegistry)

local function PlotUI_Simple(props)
    local visible = props.visible or false
    local onClose = props.onClose or function() end
    local plotData = props.plotData or {}
    
    -- Extract plot state info
    local state = plotData.state or "empty"
    local seedType = plotData.seedType or ""
    local plantName = seedType:gsub("^%l", string.upper)
    local harvestCount = plotData.harvestCount or 0
    local maxHarvests = plotData.maxHarvests or 0
    local accumulatedCrops = plotData.accumulatedCrops or 0
    local plotId = plotData.plotId
    
    -- Get crop info from registry
    local cropInfo = seedType ~= "" and CropRegistry.getCrop(seedType) or nil
    local cropVisuals = cropInfo
    
    -- Extract additional plot timing data
    local plantedAt = plotData.plantedAt or 0
    local lastWateredAt = plotData.lastWateredAt or 0
    local growthTime = plotData.growthTime or 60
    local waterTime = plotData.waterTime or 30
    local lastWaterActionTime = plotData.lastWaterActionTime or 0
    local waterCooldownSeconds = plotData.waterCooldownSeconds or 30
    local weatherEffects = plotData.weatherEffects or {}
    local onlineBonus = plotData.onlineBonus or false
    local needsMaintenanceWater = plotData.needsMaintenanceWater or false
    local wateredCount = plotData.wateredCount or 0
    local waterNeeded = plotData.waterNeeded or 0
    
    -- Real-time countdown state
    local currentTime, setCurrentTime = React.useState(tick())
    
    -- Local water action tracking for UI feedback
    local lastLocalWaterTime, setLastLocalWaterTime = React.useState(0)
    
    -- Calculate water status and ability
    local waterStatus = ""
    local waterStatusColor = Color3.fromRGB(100, 200, 255)
    local canWater = false
    local waterButtonText = "💧 Water"
    
    if state == "empty" then
        waterStatus = "Empty plot"
    elseif state == "planted" or state == "growing" or state == "watered" then
        -- Show water count and status
        local waterCountText = tostring(wateredCount) .. "/" .. tostring(waterNeeded)
        
        -- First check if we're on cooldown from last water action
        local onCooldown = false
        local cooldownRemaining = 0
        
        -- Use server time if available, otherwise use local tracking
        local effectiveLastWaterTime = lastWaterActionTime > 0 and lastWaterActionTime or lastLocalWaterTime
        
        if effectiveLastWaterTime > 0 then
            local timeSinceLastWater = currentTime - effectiveLastWaterTime
            cooldownRemaining = waterCooldownSeconds - timeSinceLastWater
            onCooldown = cooldownRemaining > 0
        end
        
        if wateredCount >= waterNeeded then
            -- Fully watered - no need to show cooldown timer
            waterStatus = "Watered (" .. waterCountText .. ")"
            waterStatusColor = Color3.fromRGB(100, 200, 100)
            canWater = false
            waterButtonText = "💧 Water"
        elseif onCooldown then
            -- On cooldown and still needs more water - show timer
            canWater = false
            local cooldownMinutes = math.floor(cooldownRemaining / 60)
            local cooldownSecondsRem = math.floor(cooldownRemaining % 60)
            if cooldownMinutes > 0 then
                waterStatus = string.format("In %dm %ds (%s)", cooldownMinutes, cooldownSecondsRem, waterCountText)
                waterButtonText = string.format("💧 Water (In %dm %ds)", cooldownMinutes, cooldownSecondsRem)
            else
                waterStatus = string.format("In %ds (%s)", cooldownSecondsRem, waterCountText)
                waterButtonText = string.format("💧 Water (In %ds)", cooldownSecondsRem)
            end
            waterStatusColor = Color3.fromRGB(255, 200, 100)
        elseif wateredCount < waterNeeded then
            -- Needs water and not on cooldown
            waterStatus = "Now! (" .. waterCountText .. ")"
            waterStatusColor = Color3.fromRGB(255, 100, 100)
            canWater = true
            waterButtonText = "💧 Water"
        end
    elseif needsMaintenanceWater then
        waterStatus = "Maintenance needed!"
        waterStatusColor = Color3.fromRGB(255, 100, 100)
        canWater = true
        waterButtonText = "💧 Water"
    else
        waterStatus = "No water needed"
        waterButtonText = "💧 Water"
    end
    
    -- Calculate plot capacity and available planting space
    local MAX_PLANTS_PER_PLOT = 50
    local activePlants = maxHarvests - harvestCount
    local currentPlantCount = state == "empty" and 0 or activePlants
    local availableSpace = MAX_PLANTS_PER_PLOT - currentPlantCount
    
    -- Calculate available seeds/crops for current crop type
    local currentCropCount = 0
    if seedType ~= "" and props.playerData and props.playerData.inventory then
        if props.playerData.inventory.seeds then
            currentCropCount = currentCropCount + (props.playerData.inventory.seeds[seedType] or 0)
        end
        if props.playerData.inventory.crops then
            currentCropCount = currentCropCount + (props.playerData.inventory.crops[seedType] or 0)
        end
    end
    
    -- Calculate how many we can actually plant (limited by space and inventory)
    local plantAllQuantity = math.min(availableSpace, currentCropCount)
    local canPlantOne = availableSpace > 0 and currentCropCount > 0
    local canPlantAll = plantAllQuantity > 1
    
    -- Calculate growth progress and harvest status
    local growthProgress = 0
    local growthProgressText = "0% grown"
    local canHarvest = false
    local currentCropsReady = accumulatedCrops or 0
    
    -- Simple harvest logic: if we have crops accumulated, we can harvest
    if currentCropsReady > 0 then
        canHarvest = true
    end
    
    if state ~= "empty" and cropInfo then
        local productionRate = cropInfo.productionRate or 1
        local productionInterval = 3600 / productionRate -- seconds per crop
        local effectiveInterval = productionInterval * 0.5 -- Online bonus
        
        local activePlants = maxHarvests - harvestCount
        local stackText = "Stack of " .. tostring(activePlants)
        
        -- Only calculate growth if the plant is FULLY watered
        if wateredCount >= waterNeeded then
            -- Use lastWateredAt as the start time for growth calculation
            local growthStartTime = lastWateredAt > 0 and lastWateredAt or plantedAt
            local timeSinceWatered = currentTime - growthStartTime
            local cycleProgress = (timeSinceWatered % effectiveInterval) / effectiveInterval
            growthProgress = math.min(cycleProgress, 1)
            
            local progressPercent = math.floor(growthProgress * 100)
            growthProgressText = tostring(stackText) .. " | " .. tostring(progressPercent) .. "% grown"
            
            -- Calculate expected crops based on completed cycles
            local completedCycles = math.floor(timeSinceWatered / effectiveInterval)
            local expectedNewCrops = completedCycles * activePlants
            
            -- Update current crops ready (accumulated + new from completed cycles)
            if growthProgress >= 1 then
                -- At least one cycle complete, calculate total crops
                currentCropsReady = math.max(currentCropsReady, (accumulatedCrops or 0) + expectedNewCrops)
            end
            
            -- Update harvest status based on crops available
            if currentCropsReady > 0 then
                canHarvest = true
                if growthProgress >= 1 then
                    growthProgressText = tostring(stackText) .. " | Ready to harvest!"
                end
            elseif growthProgress >= 1 then
                -- Cycle complete but no crops yet - still allow harvest attempt
                canHarvest = true
                growthProgressText = tostring(stackText) .. " | Ready!"
            end
        else
            -- Plant is not watered yet, show waiting state
            growthProgress = 0
            growthProgressText = tostring(stackText) .. " | Waiting for water"
            -- But still allow harvest if we have accumulated crops
            if currentCropsReady > 0 then
                canHarvest = true
            end
        end
    end
    
    -- Update timer every second for real-time countdown
    React.useEffect(function()
        local connection = game:GetService("RunService").Heartbeat:Connect(function()
            setCurrentTime(tick())
        end)
        
        return function()
            connection:Disconnect()
        end
    end, {})
    
    return e(Modal, {
        visible = visible,
        onClose = onClose,
        zIndex = 30
    }, {
        PlotContainer = e("Frame", {
            Name = "PlotContainer",
            Size = UDim2.new(0, 700, 0, 650),
            Position = UDim2.new(0.5, -350, 0.5, -325),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 30
        }, {
            PlotPanel = e("Frame", {
                Name = "PlotPanel",
                Size = UDim2.new(0, 700, 0, 600),
                Position = UDim2.new(0, 0, 0, 50),
                BackgroundColor3 = Color3.fromRGB(240, 245, 255),
                BackgroundTransparency = 0.05,
                BorderSizePixel = 0,
                ZIndex = 30
            }, {
                -- Floating Title
                FloatingTitle = e("Frame", {
                    Name = "FloatingTitle",
                    Size = UDim2.new(0, 120, 0, 40),
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
                    TitleText = e("TextLabel", {
                        Size = UDim2.new(1, 0, 1, 0),
                        Text = "PLOT",
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = 18,
                        TextWrapped = true,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.GothamBold,
                        TextXAlignment = Enum.TextXAlignment.Center,
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
                    Image = assets["X Button/X Button 64.png"] or "",
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
                
                -- Crop Card (only show if not empty)
                CropCard = state ~= "empty" and e("Frame", {
                    Name = "CropCard",
                    Size = UDim2.new(1, -40, 0, 180),
                    Position = UDim2.new(0, 20, 0, 20),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BackgroundTransparency = 0.1,
                    BorderSizePixel = 0,
                    ZIndex = 31
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 15)
                    }),
                    Stroke = e("UIStroke", {
                        Color = Color3.fromRGB(200, 255, 200),
                        Thickness = 2,
                        Transparency = 0.3
                    }),
                    Gradient = e("UIGradient", {
                        Color = ColorSequence.new{
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(250, 255, 250)),
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(245, 255, 245))
                        },
                        Rotation = 45
                    }),
                    
                    -- Crop Icon (centered)
                    CropIcon = (function()
                        if cropVisuals and cropVisuals.assetId then
                            return e("ImageLabel", {
                                Name = "CropIcon",
                                Size = UDim2.new(0, 80, 0, 80),
                                Position = UDim2.new(0.5, -40, 0, 20),
                                Image = cropVisuals.assetId,
                                BackgroundTransparency = 1,
                                ScaleType = Enum.ScaleType.Fit,
                                ZIndex = 33
                            })
                        else
                            return e("TextLabel", {
                                Name = "CropEmoji",
                                Size = UDim2.new(0, 80, 0, 80),
                                Position = UDim2.new(0.5, -40, 0, 20),
                                Text = tostring(cropVisuals and cropVisuals.emoji or "🌱"),
                                TextSize = 48,
                                TextWrapped = true,
                                BackgroundTransparency = 1,
                                Font = Enum.Font.SourceSansBold,
                                TextXAlignment = Enum.TextXAlignment.Center,
                                ZIndex = 33
                            })
                        end
                    end)(),
                    
                    -- Crop Info (centered)
                    CropName = e("TextLabel", {
                        Size = UDim2.new(1, -40, 0, 30),
                        Position = UDim2.new(0, 20, 0, 110),
                        Text = tostring(cropInfo and cropInfo.name or plantName or "Unknown"),
                        TextColor3 = Color3.fromRGB(60, 60, 60),
                        TextSize = 20,
                        TextWrapped = true,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.GothamBold,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        ZIndex = 32
                    }),
                    
                    CropDescription = e("TextLabel", {
                        Size = UDim2.new(1, -40, 0, 40),
                        Position = UDim2.new(0, 20, 0, 145),
                        Text = tostring(cropInfo and cropInfo.description or "A wonderful crop to grow!"),
                        TextColor3 = Color3.fromRGB(100, 100, 100),
                        TextSize = 14,
                        TextWrapped = true,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        ZIndex = 32
                    })
                }) or e("TextLabel", {
                    Size = UDim2.new(1, -40, 0, 100),
                    Position = UDim2.new(0, 20, 0, 50),
                    Text = "Empty Plot - Ready for planting!",
                    TextColor3 = Color3.fromRGB(100, 100, 100),
                    TextSize = 18,
                    TextWrapped = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 31
                }),
                
                -- Action Buttons Section (only for empty plots)
                ActionButtons = state == "empty" and e("Frame", {
                    Name = "ActionButtons",
                    Size = UDim2.new(1, -40, 0, 60),
                    Position = UDim2.new(0, 20, 1, -80),
                    BackgroundTransparency = 1,
                    ZIndex = 31
                }, {
                    PlantSeedsButton = e("TextButton", {
                        Name = "PlantSeedsButton",
                        Size = UDim2.new(0, 200, 0, 50),
                        Position = UDim2.new(0.5, -100, 0, 0),
                        Text = "Plant Seeds",
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = 18,
                        TextWrapped = true,
                        BackgroundColor3 = Color3.fromRGB(100, 200, 100),
                        BorderSizePixel = 0,
                        Font = Enum.Font.GothamBold,
                        ZIndex = 32,
                        [React.Event.Activated] = function()
                            if props.onOpenPlanting then
                                props.onOpenPlanting("single")
                            end
                        end
                    }, {
                        Corner = e("UICorner", {
                            CornerRadius = UDim.new(0, 12)
                        }),
                        Gradient = e("UIGradient", {
                            Color = ColorSequence.new{
                                ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 220, 120)),
                                ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 180, 80))
                            },
                            Rotation = 90
                        }),
                        Stroke = e("UIStroke", {
                            Color = Color3.fromRGB(255, 255, 255),
                            Thickness = 2,
                            Transparency = 0.2
                        }),
                        TextStroke = e("UIStroke", {
                            Color = Color3.fromRGB(0, 0, 0),
                            Thickness = 1,
                            Transparency = 0.7
                        })
                    })
                }) or nil,
                
                -- Progress Section (only for planted plots)
                ProgressSection = state ~= "empty" and e("Frame", {
                    Name = "ProgressSection",
                    Size = UDim2.new(1, -40, 0, 120),
                    Position = UDim2.new(0, 20, 0, 220),
                    BackgroundColor3 = Color3.fromRGB(250, 255, 250),
                    BackgroundTransparency = 0.3,
                    BorderSizePixel = 0,
                    ZIndex = 31
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 12)
                    }),
                    Stroke = e("UIStroke", {
                        Color = Color3.fromRGB(180, 220, 180),
                        Thickness = 2,
                        Transparency = 0.4
                    }),
                    
                    -- Production Status Label
                    ProductionLabel = e("TextLabel", {
                        Size = UDim2.new(1, -30, 0, 20),
                        Position = UDim2.new(0, 15, 0, 5),
                        Text = tostring(growthProgressText),
                        TextColor3 = Color3.fromRGB(80, 80, 80),
                        TextSize = 14,
                        TextWrapped = true,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.GothamBold,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 32
                    }),
                    
                    -- Growth Progress Bar
                    GrowthLabel = e("TextLabel", {
                        Size = UDim2.new(0, 100, 0, 20),
                        Position = UDim2.new(0, 15, 0, 30),
                        Text = "Progress:",
                        TextColor3 = Color3.fromRGB(80, 80, 80),
                        TextSize = 14,
                        TextWrapped = true,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.GothamBold,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 32
                    }),
                    
                    GrowthBar = e("Frame", {
                        Name = "GrowthBar",
                        Size = UDim2.new(1, -130, 0, 20),
                        Position = UDim2.new(0, 115, 0, 30),
                        BackgroundColor3 = Color3.fromRGB(200, 200, 200),
                        BorderSizePixel = 0,
                        ZIndex = 32
                    }, {
                        Corner = e("UICorner", {
                            CornerRadius = UDim.new(0, 10)
                        }),
                        GrowthFill = e("Frame", {
                            Name = "GrowthFill",
                            Size = UDim2.new(growthProgress, 0, 1, 0),
                            Position = UDim2.new(0, 0, 0, 0),
                            BackgroundColor3 = canHarvest and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(100, 200, 100),
                            BorderSizePixel = 0,
                            ZIndex = 33
                        }, {
                            Corner = e("UICorner", {
                                CornerRadius = UDim.new(0, 10)
                            }),
                            Gradient = e("UIGradient", {
                                Color = ColorSequence.new{
                                    ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 220, 120)),
                                    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 180, 80))
                                }
                            })
                        })
                    }),
                    
                    -- Water Status
                    WaterLabel = e("TextLabel", {
                        Size = UDim2.new(0, 100, 0, 20),
                        Position = UDim2.new(0, 15, 0, 60),
                        Text = "Water:",
                        TextColor3 = Color3.fromRGB(80, 80, 80),
                        TextSize = 14,
                        TextWrapped = true,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.GothamBold,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 32
                    }),
                    
                    WaterStatus = e("TextLabel", {
                        Size = UDim2.new(1, -130, 0, 20),
                        Position = UDim2.new(0, 115, 0, 60),
                        Text = tostring(waterStatus),
                        TextColor3 = waterStatusColor,
                        TextSize = 14,
                        TextWrapped = true,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 32
                    }),
                    
                    -- Crop Count Info
                    CropCountLabel = e("TextLabel", {
                        Size = UDim2.new(0, 100, 0, 20),
                        Position = UDim2.new(0, 15, 0, 85),
                        Text = "Crops Ready:",
                        TextColor3 = Color3.fromRGB(80, 80, 80),
                        TextSize = 14,
                        TextWrapped = true,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.GothamBold,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 32
                    }),
                    
                    CropCount = e("TextLabel", {
                        Size = UDim2.new(1, -130, 0, 20),
                        Position = UDim2.new(0, 115, 0, 85),
                        Text = tostring(currentCropsReady),
                        TextColor3 = canHarvest and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(100, 100, 100),
                        TextSize = 14,
                        TextWrapped = true,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.GothamBold,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 32
                    })
                }) or nil,
                
                -- Planted Plot Action Buttons (only for planted plots)
                PlantedActionButtons = state ~= "empty" and e("Frame", {
                    Name = "PlantedActionButtons",
                    Size = UDim2.new(1, -40, 0, 120),
                    Position = UDim2.new(0, 20, 0, 360),
                    BackgroundTransparency = 1,
                    ZIndex = 31
                }, {
                    -- Grid Layout for 2x3 button arrangement
                    UIGridLayout = e("UIGridLayout", {
                        CellPadding = UDim2.new(0, 10, 0, 10),
                        CellSize = UDim2.new(0, 210, 0, 45),
                        FillDirection = Enum.FillDirection.Horizontal,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        StartCorner = Enum.StartCorner.TopLeft
                    }),
                    
                    -- Only render buttons when they're usable
                    -- Row 1, Column 1: Water (LayoutOrder 1)
                    WaterButton = canWater and e("TextButton", {
                        Name = "WaterButton",
                        LayoutOrder = 1,
                        Text = waterButtonText,
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = 16,
                        TextWrapped = true,
                        BackgroundColor3 = Color3.fromRGB(60, 150, 220),
                        BorderSizePixel = 0,
                        Font = Enum.Font.GothamBold,
                        ZIndex = 32,
                        [React.Event.Activated] = function()
                            setLastLocalWaterTime(tick())
                            props.remotes.farmAction:FireServer("water", plotId)
                        end
                    }, {
                        Corner = e("UICorner", {
                            CornerRadius = UDim.new(0, 10)
                        }),
                        Gradient = e("UIGradient", {
                            Color = ColorSequence.new{
                                ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 170, 240)),
                                ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 130, 200))
                            },
                            Rotation = 90
                        }),
                        Stroke = e("UIStroke", {
                            Color = Color3.fromRGB(255, 255, 255),
                            Thickness = 2,
                            Transparency = 0.3
                        }),
                        TextStroke = e("UIStroke", {
                            Color = Color3.fromRGB(0, 0, 0),
                            Thickness = 3,
                            Transparency = 0.2
                        })
                    }) or nil,
                    
                    -- Row 1, Column 2: Harvest (LayoutOrder 2)
                    HarvestButton = canHarvest and e("TextButton", {
                        Name = "HarvestButton",
                        LayoutOrder = 2,
                        Text = (currentCropsReady > 0) and ("🌾 Harvest (" .. tostring(currentCropsReady) .. ")") or "🌾 Harvest",
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = 16,
                        TextWrapped = true,
                        BackgroundColor3 = Color3.fromRGB(255, 200, 50),
                        BorderSizePixel = 0,
                        Font = Enum.Font.GothamBold,
                        ZIndex = 32,
                        [React.Event.Activated] = function()
                            props.remotes.farmAction:FireServer("harvest", plotId)
                        end
                    }, {
                        Corner = e("UICorner", {
                            CornerRadius = UDim.new(0, 10)
                        }),
                        Gradient = e("UIGradient", {
                            Color = ColorSequence.new{
                                ColorSequenceKeypoint.new(0, Color3.fromRGB(240, 180, 80)),
                                ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 140, 40))
                            },
                            Rotation = 90
                        }),
                        Stroke = e("UIStroke", {
                            Color = Color3.fromRGB(255, 255, 255),
                            Thickness = 2,
                            Transparency = 0.3
                        }),
                        TextStroke = e("UIStroke", {
                            Color = Color3.fromRGB(0, 0, 0),
                            Thickness = 3,
                            Transparency = 0.2
                        })
                    }) or nil,
                    
                    -- Row 2, Column 1: Plant (1) (LayoutOrder 3)
                    Plant1Button = canPlantOne and e("TextButton", {
                        Name = "Plant1Button",
                        LayoutOrder = 3,
                        Text = "🌱 Plant (1)",
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = 16,
                        TextWrapped = true,
                        BackgroundColor3 = Color3.fromRGB(100, 200, 100),
                        BorderSizePixel = 0,
                        Font = Enum.Font.GothamBold,
                        ZIndex = 32,
                        [React.Event.Activated] = function()
                            props.remotes.farmAction:FireServer("plant", plotId, seedType, 1)
                        end
                    }, {
                        Corner = e("UICorner", {
                            CornerRadius = UDim.new(0, 10)
                        }),
                        Gradient = e("UIGradient", {
                            Color = ColorSequence.new{
                                ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 220, 120)),
                                ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 180, 80))
                            },
                            Rotation = 90
                        }),
                        Stroke = e("UIStroke", {
                            Color = Color3.fromRGB(255, 255, 255),
                            Thickness = 2,
                            Transparency = 0.3
                        }),
                        TextStroke = e("UIStroke", {
                            Color = Color3.fromRGB(0, 0, 0),
                            Thickness = 3,
                            Transparency = 0.2
                        })
                    }) or nil,
                    
                    -- Row 2, Column 2: Plant All (LayoutOrder 4)
                    PlantAllButton = canPlantAll and e("TextButton", {
                        Name = "PlantAllButton",
                        LayoutOrder = 4,
                        Text = "🌱 Plant All (" .. tostring(plantAllQuantity) .. ")",
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = 16,
                        TextWrapped = true,
                        BackgroundColor3 = Color3.fromRGB(100, 200, 100),
                        BorderSizePixel = 0,
                        Font = Enum.Font.GothamBold,
                        ZIndex = 32,
                        [React.Event.Activated] = function()
                            props.remotes.farmAction:FireServer("plant", plotId, seedType, plantAllQuantity)
                        end
                    }, {
                        Corner = e("UICorner", {
                            CornerRadius = UDim.new(0, 10)
                        }),
                        Gradient = e("UIGradient", {
                            Color = ColorSequence.new{
                                ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 220, 120)),
                                ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 180, 80))
                            },
                            Rotation = 90
                        }),
                        Stroke = e("UIStroke", {
                            Color = Color3.fromRGB(255, 255, 255),
                            Thickness = 2,
                            Transparency = 0.3
                        }),
                        TextStroke = e("UIStroke", {
                            Color = Color3.fromRGB(0, 0, 0),
                            Thickness = 3,
                            Transparency = 0.2
                        })
                    }) or nil,
                    
                    -- Row 3, Column 1: Cut Plant (LayoutOrder 5) - always available for planted plots
                    CutButton = e("TextButton", {
                        Name = "CutButton",
                        LayoutOrder = 5,
                        Text = "✂️ Cut Plant",
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = 16,
                        TextWrapped = true,
                        BackgroundColor3 = Color3.fromRGB(200, 80, 80),
                        BorderSizePixel = 0,
                        Font = Enum.Font.GothamBold,
                        ZIndex = 32,
                        [React.Event.Activated] = function()
                            props.remotes.cutPlant:FireServer(plotId)
                        end
                    }, {
                        Corner = e("UICorner", {
                            CornerRadius = UDim.new(0, 10)
                        }),
                        Gradient = e("UIGradient", {
                            Color = ColorSequence.new{
                                ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 100, 100)),
                                ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 60, 60))
                            },
                            Rotation = 90
                        }),
                        Stroke = e("UIStroke", {
                            Color = Color3.fromRGB(255, 255, 255),
                            Thickness = 2,
                            Transparency = 0.3
                        }),
                        TextStroke = e("UIStroke", {
                            Color = Color3.fromRGB(0, 0, 0),
                            Thickness = 3,
                            Transparency = 0.2
                        })
                    })
                }) or nil,
                
                -- Boost and Status Information Section
                BoostSection = e("Frame", {
                    Name = "BoostSection",
                    Size = UDim2.new(1, -40, 0, 80),
                    Position = UDim2.new(0, 20, 0, 500),
                    BackgroundColor3 = Color3.fromRGB(255, 250, 240),
                    BackgroundTransparency = 0.2,
                    BorderSizePixel = 0,
                    ZIndex = 31
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 12)
                    }),
                    Stroke = e("UIStroke", {
                        Color = Color3.fromRGB(220, 180, 100),
                        Thickness = 2,
                        Transparency = 0.4
                    }),
                    
                    -- Boost Title
                    BoostTitle = e("TextLabel", {
                        Size = UDim2.new(1, 0, 0, 25),
                        Position = UDim2.new(0, 0, 0, 5),
                        Text = "🌟 Active Boosts & Status",
                        TextColor3 = Color3.fromRGB(150, 100, 50),
                        TextSize = 16,
                        TextWrapped = true,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.GothamBold,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        ZIndex = 32
                    }),
                    
                    -- Weather Effects
                    WeatherBoost = weatherEffects and weatherEffects.growthMultiplier and weatherEffects.growthMultiplier > 1 and e("TextLabel", {
                        Size = UDim2.new(0, 150, 0, 20),
                        Position = UDim2.new(0, 10, 0, 35),
                        Text = "🌦️ Weather: +" .. tostring(math.floor((weatherEffects.growthMultiplier - 1) * 100)) .. "%",
                        TextColor3 = Color3.fromRGB(60, 120, 180),
                        TextSize = 14,
                        TextWrapped = true,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 32
                    }) or nil,
                    
                    -- Online Bonus
                    OnlineBoost = onlineBonus and e("TextLabel", {
                        Size = UDim2.new(0, 150, 0, 20),
                        Position = UDim2.new(0, 180, 0, 35),
                        Text = "⚡ Online: +100%",
                        TextColor3 = Color3.fromRGB(100, 200, 100),
                        TextSize = 14,
                        TextWrapped = true,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 32
                    }) or nil,
                    
                    -- Maintenance Water Status
                    MaintenanceStatus = needsMaintenanceWater and e("TextLabel", {
                        Size = UDim2.new(0, 200, 0, 20),
                        Position = UDim2.new(0, 350, 0, 35),
                        Text = "🔧 Needs Maintenance Water",
                        TextColor3 = Color3.fromRGB(200, 150, 50),
                        TextSize = 14,
                        TextWrapped = true,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.GothamBold,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 32
                    }) or nil,
                    
                    -- Plot State Info
                    StateInfo = e("TextLabel", {
                        Size = UDim2.new(1, -20, 0, 20),
                        Position = UDim2.new(0, 10, 0, 35),
                        Text = "📍 Plot ID: " .. tostring(plotId or "Unknown") .. " | State: " .. tostring(state):gsub("^%l", string.upper),
                        TextColor3 = Color3.fromRGB(100, 100, 100),
                        TextSize = 12,
                        TextWrapped = true,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 32
                    }),
                    
                    -- Debug Info
                    DebugInfo = e("TextLabel", {
                        Size = UDim2.new(1, -20, 0, 20),
                        Position = UDim2.new(0, 10, 0, 55),
                        Text = "🔧 Progress: " .. tostring(math.floor(growthProgress * 100)) .. "% | Can Harvest: " .. tostring(canHarvest) .. " | Crops Ready: " .. tostring(currentCropsReady) .. " | Accumulated: " .. tostring(accumulatedCrops),
                        TextColor3 = Color3.fromRGB(80, 80, 80),
                        TextSize = 12,
                        TextWrapped = true,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 32
                    }),
                    
                                    -- Water Debug Info
                    WaterDebugInfo = e("TextLabel", {
                        Size = UDim2.new(1, -20, 0, 20),
                        Position = UDim2.new(0, 10, 0, 75),
                        Text = "💧 Can Water: " .. tostring(canWater) .. " | Last Water: " .. tostring(lastWaterActionTime) .. " | WaterCount: " .. tostring(wateredCount) .. "/" .. tostring(waterNeeded),
                        TextColor3 = Color3.fromRGB(80, 80, 80),
                        TextSize = 12,
                        TextWrapped = true,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 32
                    }),
                    
                    -- Growth Debug Info
                    GrowthDebugInfo = e("TextLabel", {
                        Size = UDim2.new(1, -20, 0, 20),
                        Position = UDim2.new(0, 10, 0, 115),
                        Text = "🌱 PlantedAt: " .. tostring(plantedAt) .. " | LastWatered: " .. tostring(lastWateredAt) .. " | StartTime: " .. tostring((lastWateredAt > 0 and lastWateredAt or plantedAt)),
                        TextColor3 = Color3.fromRGB(80, 80, 80),
                        TextSize = 12,
                        TextWrapped = true,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 32
                    }),
                    
                    -- Plot Data Debug
                    PlotDataDebug = e("TextLabel", {
                        Size = UDim2.new(1, -20, 0, 20),
                        Position = UDim2.new(0, 10, 0, 95),
                        Text = "🔍 PlotData Keys: " .. table.concat((function()
                            local keys = {}
                            for k, v in pairs(plotData) do
                                table.insert(keys, tostring(k) .. "=" .. tostring(v))
                            end
                            return keys
                        end)(), ", "),
                        TextColor3 = Color3.fromRGB(80, 80, 80),
                        TextSize = 10,
                        TextWrapped = true,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 32
                    })
                })
            })
        })
    })
end

return PlotUI_Simple