-- Minimal PlotUI to test React createTextInstance issue
local React = require(game:GetService("ReplicatedStorage").Packages.react)
local e = React.createElement
local Modal = require(script.Parent.Modal)
local assets = require(game:GetService("ReplicatedStorage").Shared.assets)
local CropRegistry = require(game:GetService("ReplicatedStorage").Shared.CropRegistry)
local ScreenUtils = require(game:GetService("ReplicatedStorage").Shared.ScreenUtils)

-- Helper function to play sounds client-side
local function playSound(soundId)
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. soundId
    sound.Volume = 0.5
    sound.Parent = game:GetService("SoundService")
    sound:Play()
    
    -- Clean up after sound finishes
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

-- Helper function to format time in h/m/s format
local function formatTimeHMS(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    
    if hours > 0 then
        return string.format("%dh %dm %ds", hours, minutes, secs)
    elseif minutes > 0 then
        return string.format("%dm %ds", minutes, secs)
    else
        return string.format("%ds", secs)
    end
end

local function PlotUI_Simple(props)
    local visible = props.visible or false
    local onClose = props.onClose or function() end
    local plotData = props.plotData or {}
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    
    -- Responsive sizing
    local scale = ScreenUtils.getProportionalScale(screenSize)
    
    -- Panel sizing - responsive to screen size (made taller for taller card)
    local panelWidth = math.min(screenSize.X * 0.85, ScreenUtils.getProportionalSize(screenSize, 700))
    local panelHeight = math.min(screenSize.Y * 0.90, ScreenUtils.getProportionalSize(screenSize, 620))
    
    -- Text sizes
    local titleTextSize = ScreenUtils.getProportionalTextSize(screenSize, 18)
    local headerTextSize = ScreenUtils.getProportionalTextSize(screenSize, 16)
    local normalTextSize = ScreenUtils.getProportionalTextSize(screenSize, 14)
    local smallTextSize = ScreenUtils.getProportionalTextSize(screenSize, 12)
    local buttonTextSize = ScreenUtils.getProportionalTextSize(screenSize, 15)
    
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
    local lastMaintenanceWater = plotData.lastMaintenanceWater or 0
    local wateredCount = plotData.wateredCount or 0
    local waterNeeded = plotData.waterNeeded or 0
    
    -- Real-time countdown state
    local currentTime, setCurrentTime = React.useState(tick())
    
    -- Local water action tracking for UI feedback
    local lastLocalWaterTime, setLastLocalWaterTime = React.useState(0)
    
    -- Cut plant confirmation state
    local showCutConfirmation, setShowCutConfirmation = React.useState(false)
    
    -- Auto-reset cut confirmation after 5 seconds
    React.useEffect(function()
        if showCutConfirmation then
            local connection = task.delay(5, function()
                setShowCutConfirmation(false)
            end)
            
            -- Cleanup function
            return function()
                task.cancel(connection)
            end
        end
    end, {showCutConfirmation})
    
    -- Calculate water status and ability
    local waterStatus = ""
    local waterStatusColor = Color3.fromRGB(100, 200, 255)
    local canWater = false
    local waterButtonText = "💧 Water"
    
    if state == "empty" then
        waterStatus = "Empty plot"
    elseif state == "planted" or state == "growing" or state == "watered" or state == "ready" then
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
            -- Fully watered - calculate maintenance timing locally
            if cropInfo and cropInfo.maintenanceWaterInterval then
                -- Use lastMaintenanceWater if available, otherwise use lastWateredAt as start time
                local maintenanceStartTime = lastMaintenanceWater > 0 and lastMaintenanceWater or lastWateredAt
                local timeSinceLastMaintenance = currentTime - maintenanceStartTime
                local maintenanceRemaining = cropInfo.maintenanceWaterInterval - timeSinceLastMaintenance
                
                if maintenanceRemaining > 0 then
                    -- Still within maintenance period - show countdown
                    waterStatus = "Water in " .. formatTimeHMS(maintenanceRemaining)
                    waterStatusColor = Color3.fromRGB(100, 200, 100)
                    canWater = false
                    waterButtonText = "💧 Water"
                else
                    -- Maintenance watering needed
                    waterStatus = "Maintenance needed!"
                    waterStatusColor = Color3.fromRGB(255, 200, 100)
                    canWater = true
                    waterButtonText = "💧 Maintenance Water"
                end
            else
                -- No maintenance system - just show watered
                waterStatus = "Watered (" .. waterCountText .. ")"
                waterStatusColor = Color3.fromRGB(100, 200, 100)
                canWater = false
                waterButtonText = "💧 Water"
            end
        elseif onCooldown then
            -- On cooldown and still needs more water - show timer
            canWater = false
            local cooldownFormatted = formatTimeHMS(cooldownRemaining)
            waterStatus = string.format("In %s (%s)", cooldownFormatted, waterCountText)
            waterButtonText = string.format("💧 Water (In %s)", cooldownFormatted)
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
    
    -- Calculate total seeds in inventory (for empty plot shop button)
    local totalSeeds = 0
    if props.playerData and props.playerData.inventory and props.playerData.inventory.seeds then
        for _, count in pairs(props.playerData.inventory.seeds) do
            totalSeeds = totalSeeds + count
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
        
        -- Calculate total boost multiplier (same logic as server)
        local boostMultiplier = 2.0 -- Base online speed boost (2x)
        
        -- Apply debug boost (multiplicative)
        if props.playerData and props.playerData.debugProductionBoost and props.playerData.debugProductionBoost > 0 then
            local debugMultiplier = 1 + (props.playerData.debugProductionBoost / 100)
            boostMultiplier = boostMultiplier * debugMultiplier
        end
        
        -- Apply production gamepass boost (multiplicative)
        if props.playerData and props.playerData.gamepasses and props.playerData.gamepasses.productionBoost then
            boostMultiplier = boostMultiplier * 2.0 -- 2x for production gamepass
        end
        
        -- Apply weather boost (multiplicative) - match server WeatherConfig values
        if props.weatherData and props.weatherData.current and props.weatherData.current.name then
            local weatherName = props.weatherData.current.name
            local weatherMultiplier = 1.0
            if weatherName == "Rainy" then
                weatherMultiplier = 0.9 -- 10% slower growth in rain (matches server)
            elseif weatherName == "Thunderstorm" then
                weatherMultiplier = 0.7 -- 30% slower growth in thunderstorm (matches server)
            elseif weatherName == "Sunny" then
                weatherMultiplier = 1.5 -- 50% faster growth in sun (matches server)
            -- Cloudy = 1.0 (neutral)
            end
            boostMultiplier = boostMultiplier * weatherMultiplier
        end
        
        -- Apply boost multiplier to interval (higher multiplier = faster growth = shorter interval)
        local effectiveInterval = productionInterval / boostMultiplier
        
        local activePlants = maxHarvests - harvestCount
        local stackText = "Stack of " .. tostring(activePlants)
        
        -- Only calculate growth if the plant is FULLY watered AND doesn't need maintenance
        if wateredCount >= waterNeeded then
            -- Use lastWateredAt as the start time for growth calculation
            local growthStartTime = lastWateredAt > 0 and lastWateredAt or plantedAt
            local timeSinceWatered = currentTime - growthStartTime
            
            -- Calculate maintenance timing locally
            local needsMaintenanceNow = false
            if cropInfo and cropInfo.maintenanceWaterInterval then
                local maintenanceStartTime = lastMaintenanceWater > 0 and lastMaintenanceWater or lastWateredAt
                local timeSinceLastMaintenance = currentTime - maintenanceStartTime
                needsMaintenanceNow = timeSinceLastMaintenance >= cropInfo.maintenanceWaterInterval
            end
            
            if needsMaintenanceNow then
                -- Stop growth progress - maintenance needed
                growthProgress = 0
                growthProgressText = tostring(stackText) .. " | No progress - needs watering!"
            else
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
    
    return e(React.Fragment, {}, {
        -- Main Plot UI Modal
        PlotModal = e(Modal, {
            visible = visible,
            onClose = onClose,
            zIndex = 30
        }, {
        PlotContainer = e("Frame", {
            Name = "PlotContainer",
            Size = UDim2.new(0, panelWidth, 0, panelHeight),
            Position = UDim2.new(0.5, -panelWidth/2, 0.5, -panelHeight/2),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 30
        }, {
            PlotPanel = e("Frame", {
                Name = "PlotPanel",
                Size = UDim2.new(0, panelWidth, 0, panelHeight * 0.92),
                Position = UDim2.new(0, 0, 0, ScreenUtils.getProportionalSize(screenSize, 50)),
                BackgroundColor3 = Color3.fromRGB(240, 245, 255),
                BackgroundTransparency = 0.05,
                BorderSizePixel = 0,
                ZIndex = 30
            }, {
                -- Floating Title
                FloatingTitle = e("Frame", {
                    Name = "FloatingTitle",
                    Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 120), 0, ScreenUtils.getProportionalSize(screenSize, 40)),
                    Position = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, -10), 0, ScreenUtils.getProportionalSize(screenSize, -25)),
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
                        TextSize = titleTextSize,
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
                    Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 32), 0, ScreenUtils.getProportionalSize(screenSize, 32)),
                    Position = UDim2.new(1, ScreenUtils.getProportionalSize(screenSize, -16), 0, ScreenUtils.getProportionalSize(screenSize, -16)),
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
                
                -- Card 1: Crop Information Card (basic info only)
                CropCard = state ~= "empty" and e("Frame", {
                    Name = "CropCard",
                    Size = UDim2.new(1, ScreenUtils.getProportionalSize(screenSize, -40), 0, ScreenUtils.getProportionalSize(screenSize, 260)),
                    Position = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 20), 0, ScreenUtils.getProportionalSize(screenSize, 20)),
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
                                Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 80), 0, ScreenUtils.getProportionalSize(screenSize, 80)),
                                Position = UDim2.new(0.5, ScreenUtils.getProportionalSize(screenSize, -40), 0, ScreenUtils.getProportionalSize(screenSize, 20)),
                                Image = cropVisuals.assetId,
                                BackgroundTransparency = 1,
                                ScaleType = Enum.ScaleType.Fit,
                                ZIndex = 33
                            })
                        else
                            return e("TextLabel", {
                                Name = "CropEmoji",
                                Size = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 80), 0, ScreenUtils.getProportionalSize(screenSize, 80)),
                                Position = UDim2.new(0.5, ScreenUtils.getProportionalSize(screenSize, -40), 0, ScreenUtils.getProportionalSize(screenSize, 20)),
                                Text = tostring(cropVisuals and cropVisuals.emoji or "🌱"),
                                TextSize = ScreenUtils.getProportionalTextSize(screenSize, 48),
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
                        Position = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 20), 0, ScreenUtils.getProportionalSize(screenSize, 110)),
                        Text = (function()
                            local cropName = tostring(cropInfo and cropInfo.name or plantName or "Unknown")
                            if state ~= "empty" then
                                return cropName .. " (" .. currentPlantCount .. "/" .. MAX_PLANTS_PER_PLOT .. " planted)"
                            end
                            return cropName
                        end)(),
                        TextColor3 = Color3.fromRGB(60, 60, 60),
                        TextSize = headerTextSize,
                        TextWrapped = true,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.GothamBold,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        ZIndex = 32
                    }),
                    
                    CropDescription = e("TextLabel", {
                        Size = UDim2.new(1, ScreenUtils.getProportionalSize(screenSize, -40), 0, ScreenUtils.getProportionalSize(screenSize, 30)),
                        Position = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 20), 0, ScreenUtils.getProportionalSize(screenSize, 135)),
                        Text = tostring(cropInfo and cropInfo.description or "A wonderful crop to grow!"),
                        TextColor3 = Color3.fromRGB(100, 100, 100),
                        TextSize = normalTextSize,
                        TextWrapped = true,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        ZIndex = 32
                    }),
                    
                    -- Action Buttons (inside crop card)
                    ActionButtons = e("Frame", {
                        Name = "ActionButtons",
                        Size = UDim2.new(1, ScreenUtils.getProportionalSize(screenSize, -20), 0, ScreenUtils.getProportionalSize(screenSize, 90)),
                        Position = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 10), 1, ScreenUtils.getProportionalSize(screenSize, -100)),
                        BackgroundTransparency = 1,
                        ZIndex = 32
                    }, {
                        -- Grid Layout for centered button arrangement
                        UIGridLayout = e("UIGridLayout", {
                            CellPadding = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 10), 0, ScreenUtils.getProportionalSize(screenSize, 10)),
                            CellSize = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 155), 0, ScreenUtils.getProportionalSize(screenSize, 40)),
                            FillDirection = Enum.FillDirection.Horizontal,
                            HorizontalAlignment = Enum.HorizontalAlignment.Center,
                            VerticalAlignment = Enum.VerticalAlignment.Top,
                            SortOrder = Enum.SortOrder.LayoutOrder,
                            StartCorner = Enum.StartCorner.TopLeft
                        }),
                        
                        -- Water Button
                        WaterButton = e("TextButton", {
                            Name = "WaterButton",
                            Text = "",
                            BackgroundColor3 = canWater and Color3.fromRGB(100, 180, 255) or Color3.fromRGB(150, 150, 150),
                            BorderSizePixel = 0,
                            LayoutOrder = 1,
                            ZIndex = 33,
                            [React.Event.Activated] = function()
                                if canWater and props.remotes and props.remotes.farmAction then
                                    props.remotes.farmAction:FireServer("water", plotId)
                                    setLastLocalWaterTime(tick())
                                    playSound("click")
                                end
                            end
                        }, {
                            Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
                            Gradient = e("UIGradient", {
                                Color = canWater and ColorSequence.new{
                                    ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 200, 255)),
                                    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 160, 255))
                                } or ColorSequence.new{
                                    ColorSequenceKeypoint.new(0, Color3.fromRGB(170, 170, 170)),
                                    ColorSequenceKeypoint.new(1, Color3.fromRGB(130, 130, 130))
                                },
                                Rotation = 90
                            }),
                            ButtonText = e("TextLabel", {
                                Size = UDim2.new(1, 0, 1, 0),
                                Text = tostring(waterButtonText),
                                TextColor3 = Color3.fromRGB(255, 255, 255),
                                TextSize = buttonTextSize,
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
                        
                        -- Harvest Button
                        HarvestButton = e("TextButton", {
                            Name = "HarvestButton",
                            Text = "",
                            BackgroundColor3 = canHarvest and Color3.fromRGB(255, 140, 80) or Color3.fromRGB(150, 150, 150),
                            BorderSizePixel = 0,
                            LayoutOrder = 2,
                            ZIndex = 33,
                            [React.Event.Activated] = function()
                                if canHarvest and props.remotes and props.remotes.farmAction then
                                    props.remotes.farmAction:FireServer("harvest", plotId)
                                    playSound("click")
                                end
                            end
                        }, {
                            Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
                            Gradient = e("UIGradient", {
                                Color = canHarvest and ColorSequence.new{
                                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 160, 100)),
                                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 120, 60))
                                } or ColorSequence.new{
                                    ColorSequenceKeypoint.new(0, Color3.fromRGB(170, 170, 170)),
                                    ColorSequenceKeypoint.new(1, Color3.fromRGB(130, 130, 130))
                                },
                                Rotation = 90
                            }),
                            ButtonText = e("TextLabel", {
                                Size = UDim2.new(1, 0, 1, 0),
                                Text = "🌾 Harvest (" .. tostring(currentCropsReady) .. ")",
                                TextColor3 = Color3.fromRGB(255, 255, 255),
                                TextSize = buttonTextSize,
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
                        
                        -- Plant 1 Button
                        PlantOneButton = canPlantOne and e("TextButton", {
                            Name = "PlantOneButton",
                            Text = "",
                            BackgroundColor3 = Color3.fromRGB(100, 200, 100),
                            BorderSizePixel = 0,
                            LayoutOrder = 3,
                            ZIndex = 33,
                            [React.Event.Activated] = function()
                                if props.onOpenPlanting then
                                    props.onOpenPlanting("one")
                                    playSound("click")
                                end
                            end
                        }, {
                            Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
                            Gradient = e("UIGradient", {
                                Color = ColorSequence.new{
                                    ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 220, 120)),
                                    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 180, 80))
                                },
                                Rotation = 90
                            }),
                            ButtonText = e("TextLabel", {
                                Size = UDim2.new(1, 0, 1, 0),
                                Text = "🌱 Plant 1",
                                TextColor3 = Color3.fromRGB(255, 255, 255),
                                TextSize = buttonTextSize,
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
                        }) or nil,
                        
                        -- Plant All Button
                        PlantAllButton = canPlantAll and e("TextButton", {
                            Name = "PlantAllButton",
                            Text = "",
                            BackgroundColor3 = Color3.fromRGB(100, 200, 100),
                            BorderSizePixel = 0,
                            LayoutOrder = 4,
                            ZIndex = 33,
                            [React.Event.Activated] = function()
                                if props.onOpenPlanting then
                                    props.onOpenPlanting("all")
                                    playSound("click")
                                end
                            end
                        }, {
                            Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
                            Gradient = e("UIGradient", {
                                Color = ColorSequence.new{
                                    ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 220, 120)),
                                    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 180, 80))
                                },
                                Rotation = 90
                            }),
                            ButtonText = e("TextLabel", {
                                Size = UDim2.new(1, 0, 1, 0),
                                Text = "🌱 Plant All (" .. tostring(plantAllQuantity) .. ")",
                                TextColor3 = Color3.fromRGB(255, 255, 255),
                                TextSize = buttonTextSize,
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
                        }) or nil,
                        
                        -- Cut Plant Button
                        CutButton = e("TextButton", {
                            Name = "CutButton",
                            Text = "",
                            BackgroundColor3 = Color3.fromRGB(255, 100, 100),
                            BorderSizePixel = 0,
                            LayoutOrder = 5,
                            ZIndex = 33,
                            [React.Event.Activated] = function()
                                if showCutConfirmation then
                                    -- Confirm cut
                                    if props.remotes and props.remotes.farmAction then
                                        props.remotes.farmAction:FireServer("clear", plotId)
                                        playSound("click")
                                        setShowCutConfirmation(false)
                                    end
                                else
                                    -- Show confirmation
                                    setShowCutConfirmation(true)
                                    playSound("click")
                                end
                            end
                        }, {
                            Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
                            Gradient = e("UIGradient", {
                                Color = showCutConfirmation and ColorSequence.new{
                                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 50)),
                                    ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 20, 20))
                                } or ColorSequence.new{
                                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 120, 120)),
                                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 80, 80))
                                },
                                Rotation = 90
                            }),
                            ButtonText = e("TextLabel", {
                                Size = UDim2.new(1, 0, 1, 0),
                                Text = showCutConfirmation and "✂️ Confirm Cut?" or "✂️ Cut Plant",
                                TextColor3 = Color3.fromRGB(255, 255, 255),
                                TextSize = buttonTextSize,
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
                        })
                    })
                }) or e("Frame", {
                    Name = "EmptyPlotCard",
                    Size = UDim2.new(1, ScreenUtils.getProportionalSize(screenSize, -40), 0, ScreenUtils.getProportionalSize(screenSize, 200)),
                    Position = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 20), 0, ScreenUtils.getProportionalSize(screenSize, 50)),
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
                    
                    -- Section 1: Crop Icon (Left)
                    IconSection = e("Frame", {
                        Size = UDim2.new(0.2, 0, 1, 0),
                        Position = UDim2.new(0, 0, 0, 0),
                        BackgroundTransparency = 1,
                        ZIndex = 32
                    }, {
                        EmptyIcon = e("TextLabel", {
                            Size = UDim2.new(0.8, 0, 0.4, 0),
                            Position = UDim2.new(0.1, 0, 0.3, 0),
                            Text = "🌱",
                            TextSize = ScreenUtils.getProportionalTextSize(screenSize, 36),
                            BackgroundTransparency = 1,
                            TextXAlignment = Enum.TextXAlignment.Center,
                            TextYAlignment = Enum.TextYAlignment.Center,
                            ZIndex = 33
                        })
                    }),
                    
                    -- Section 2: Plot Info (Middle-Left)
                    InfoSection = e("Frame", {
                        Size = UDim2.new(0.35, 0, 1, 0),
                        Position = UDim2.new(0.2, 0, 0, 0),
                        BackgroundTransparency = 1,
                        ZIndex = 32
                    }, {
                        PlotTitle = e("TextLabel", {
                            Size = UDim2.new(1, 0, 0.3, 0),
                            Position = UDim2.new(0, 0, 0.15, 0),
                            Text = "Empty Plot",
                            TextColor3 = Color3.fromRGB(80, 80, 80),
                            TextSize = headerTextSize,
                            BackgroundTransparency = 1,
                            Font = Enum.Font.GothamBold,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            TextYAlignment = Enum.TextYAlignment.Center,
                            ZIndex = 33
                        }),
                        PlotStatus = e("TextLabel", {
                            Size = UDim2.new(1, 0, 0.25, 0),
                            Position = UDim2.new(0, 0, 0.45, 0),
                            Text = "Ready for planting",
                            TextColor3 = Color3.fromRGB(100, 150, 100),
                            TextSize = normalTextSize,
                            BackgroundTransparency = 1,
                            Font = Enum.Font.Gotham,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            TextYAlignment = Enum.TextYAlignment.Center,
                            ZIndex = 33
                        }),
                        SeedsAvailable = e("TextLabel", {
                            Size = UDim2.new(1, 0, 0.25, 0),
                            Position = UDim2.new(0, 0, 0.7, 0),
                            Text = totalSeeds > 0 and ("Seeds available: " .. totalSeeds) or "No seeds in inventory",
                            TextColor3 = totalSeeds > 0 and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 100, 100),
                            TextSize = smallTextSize,
                            BackgroundTransparency = 1,
                            Font = Enum.Font.Gotham,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            TextYAlignment = Enum.TextYAlignment.Center,
                            ZIndex = 33
                        })
                    }),
                    
                    -- Section 3: Additional Info (Middle-Right)
                    StatsSection = e("Frame", {
                        Size = UDim2.new(0.25, 0, 1, 0),
                        Position = UDim2.new(0.55, 0, 0, 0),
                        BackgroundTransparency = 1,
                        ZIndex = 32
                    }, {
                        PotentialLabel = e("TextLabel", {
                            Size = UDim2.new(1, 0, 0.3, 0),
                            Position = UDim2.new(0, 0, 0.2, 0),
                            Text = "Potential:",
                            TextColor3 = Color3.fromRGB(80, 80, 80),
                            TextSize = normalTextSize,
                            BackgroundTransparency = 1,
                            Font = Enum.Font.GothamBold,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            TextYAlignment = Enum.TextYAlignment.Center,
                            ZIndex = 33
                        }),
                        MaxPlantsInfo = e("TextLabel", {
                            Size = UDim2.new(1, 0, 0.25, 0),
                            Position = UDim2.new(0, 0, 0.5, 0),
                            Text = "Up to 50 plants",
                            TextColor3 = Color3.fromRGB(100, 100, 100),
                            TextSize = smallTextSize,
                            BackgroundTransparency = 1,
                            Font = Enum.Font.Gotham,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            TextYAlignment = Enum.TextYAlignment.Center,
                            ZIndex = 33
                        })
                    }),
                    
                    -- Section 4: Action Buttons (Right)
                    ButtonSection = e("Frame", {
                        Size = UDim2.new(0.2, 0, 1, 0),
                        Position = UDim2.new(0.8, 0, 0, 0),
                        BackgroundTransparency = 1,
                        ZIndex = 32
                    }, {
                        PlantButton = totalSeeds > 0 and e("TextButton", {
                            Name = "PlantSeedsButton",
                            Size = UDim2.new(0.9, 0, 0.35, 0),
                            Position = UDim2.new(0.05, 0, 0.15, 0),
                            Text = "",
                            BackgroundColor3 = Color3.fromRGB(100, 200, 100),
                            BorderSizePixel = 0,
                            ZIndex = 33,
                            [React.Event.Activated] = function()
                                if props.onOpenPlanting then
                                    props.onOpenPlanting("single")
                                end
                            end
                        }, {
                            Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
                            Gradient = e("UIGradient", {
                                Color = ColorSequence.new{
                                    ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 220, 120)),
                                    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 180, 80))
                                },
                                Rotation = 90
                            }),
                            ButtonText = e("TextLabel", {
                                Size = UDim2.new(1, 0, 1, 0),
                                Text = "🌱 Plant",
                                TextColor3 = Color3.fromRGB(255, 255, 255),
                                TextSize = buttonTextSize,
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
                        }) or e("TextButton", {
                            Name = "GoToShopButton",
                            Size = UDim2.new(0.9, 0, 0.35, 0),
                            Position = UDim2.new(0.05, 0, 0.15, 0),
                            Text = "",
                            BackgroundColor3 = Color3.fromRGB(100, 200, 100),
                            BorderSizePixel = 0,
                            ZIndex = 33,
                            [React.Event.Activated] = function()
                                if props.onOpenShop then
                                    props.onOpenShop()
                                end
                            end
                        }, {
                            Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
                            Gradient = e("UIGradient", {
                                Color = ColorSequence.new{
                                    ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 170, 255)),
                                    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 130, 255))
                                },
                                Rotation = 90
                            }),
                            ButtonText = e("TextLabel", {
                                Size = UDim2.new(1, 0, 1, 0),
                                Text = "🛒 Shop",
                                TextColor3 = Color3.fromRGB(255, 255, 255),
                                TextSize = buttonTextSize,
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
                        
                        PlantAllButton = totalSeeds > 1 and e("TextButton", {
                            Name = "PlantAllButton",
                            Size = UDim2.new(0.9, 0, 0.35, 0),
                            Position = UDim2.new(0.05, 0, 0.55, 0),
                            Text = "",
                            BackgroundColor3 = Color3.fromRGB(100, 200, 100),
                            BorderSizePixel = 0,
                            ZIndex = 33,
                            [React.Event.Activated] = function()
                                if props.onOpenPlanting then
                                    props.onOpenPlanting("all")
                                end
                            end
                        }, {
                            Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
                            Gradient = e("UIGradient", {
                                Color = ColorSequence.new{
                                    ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 200, 100)),
                                    ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 160, 60))
                                },
                                Rotation = 90
                            }),
                            ButtonText = e("TextLabel", {
                                Size = UDim2.new(1, 0, 1, 0),
                                Text = "🌱 Plant All",
                                TextColor3 = Color3.fromRGB(255, 255, 255),
                                TextSize = buttonTextSize,
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
                        }) or nil
                    })
                }),
                
                -- Card 2: Stats and Actions Card (progress, production, buttons)
                StatsCard = state ~= "empty" and e("Frame", {
                    Name = "StatsCard",
                    Size = UDim2.new(1, ScreenUtils.getProportionalSize(screenSize, -40), 0, ScreenUtils.getProportionalSize(screenSize, 200)),
                    Position = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 20), 0, ScreenUtils.getProportionalSize(screenSize, 290)),
                    BackgroundColor3 = Color3.fromRGB(245, 250, 255),
                    BackgroundTransparency = 0.1,
                    BorderSizePixel = 0,
                    ZIndex = 31
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 15)
                    }),
                    Stroke = e("UIStroke", {
                        Color = Color3.fromRGB(180, 200, 255),
                        Thickness = 2,
                        Transparency = 0.3
                    }),
                    Gradient = e("UIGradient", {
                        Color = ColorSequence.new{
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(250, 255, 255)),
                            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(245, 250, 255)),
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(240, 245, 255))
                        },
                        Rotation = 45
                    }),
                    
                    -- Progress Section (inside stats card)
                    ProgressSection = e("Frame", {
                        Name = "ProgressSection",
                        Size = UDim2.new(1, ScreenUtils.getProportionalSize(screenSize, -20), 0, ScreenUtils.getProportionalSize(screenSize, 180)),
                        Position = UDim2.new(0, ScreenUtils.getProportionalSize(screenSize, 10), 0, ScreenUtils.getProportionalSize(screenSize, 10)),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        ZIndex = 32
                    }, {
                        Corner = e("UICorner", {
                            CornerRadius = UDim.new(0, 10)
                        }),
                        
                        -- Progress label
                        ProgressLabel = e("TextLabel", {
                            Size = UDim2.new(0, 80, 0, 20),
                            Position = UDim2.new(0, 10, 0, 10),
                            Text = "Progress:",
                            TextColor3 = Color3.fromRGB(80, 80, 80),
                            TextSize = normalTextSize,
                            BackgroundTransparency = 1,
                            Font = Enum.Font.GothamBold,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 33
                        }),
                        
                        -- Progress Bar
                        ProgressBar = e("Frame", {
                            Name = "ProgressBar",
                            Size = UDim2.new(1, -110, 0, 20),
                            Position = UDim2.new(0, 100, 0, 10),
                            BackgroundColor3 = Color3.fromRGB(200, 200, 200),
                            BorderSizePixel = 0,
                            ZIndex = 33
                        }, {
                            Corner = e("UICorner", {
                                CornerRadius = UDim.new(0, 10)
                            }),
                            -- Progress Fill
                            ProgressFill = e("Frame", {
                                Name = "ProgressFill",
                                Size = UDim2.new(growthProgress, 0, 1, 0),
                                Position = UDim2.new(0, 0, 0, 0),
                                BackgroundColor3 = canHarvest and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(100, 200, 100),
                                BorderSizePixel = 0,
                                ZIndex = 34
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
                                })
                            }),
                            -- Percentage text overlay
                            PercentageText = e("TextLabel", {
                                Size = UDim2.new(1, 0, 1, 0),
                                Position = UDim2.new(0, 0, 0, 0),
                                Text = math.floor(growthProgress * 100) .. "%",
                                TextColor3 = Color3.fromRGB(255, 255, 255),
                                TextSize = smallTextSize,
                                BackgroundTransparency = 1,
                                Font = Enum.Font.GothamBold,
                                TextXAlignment = Enum.TextXAlignment.Center,
                                ZIndex = 35
                            }, {
                                TextStroke = e("UIStroke", {
                                    Color = Color3.fromRGB(0, 0, 0),
                                    Thickness = 1,
                                    Transparency = 0.3
                                })
                            })
                        }),
                        
                        -- Water status
                        WaterText = e("TextLabel", {
                            Size = UDim2.new(1, -20, 0, 25),
                            Position = UDim2.new(0, 10, 0, 35),
                            Text = (function()
                                local statusText = tostring(waterStatus)
                                if statusText:find("Water in") then
                                    -- Make "Water in:" blue and bold
                                    return "<font color='rgb(0,150,255)'><b>Water in:</b></font> " .. statusText:gsub("Water in ", "")
                                else
                                    -- Regular water status, make label bold
                                    return "<b>Water:</b> " .. statusText
                                end
                            end)(),
                            TextColor3 = waterStatusColor,
                            TextSize = normalTextSize,
                            BackgroundTransparency = 1,
                            Font = Enum.Font.Gotham,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            RichText = true,
                            ZIndex = 33
                        }),
                        
                        -- Production rate
                        ProductionText = e("TextLabel", {
                            Size = UDim2.new(1, -20, 0, 25),
                            Position = UDim2.new(0, 10, 0, 65),
                            Text = (function()
                                if cropInfo and cropInfo.productionRate then
                                    local activePlants = maxHarvests - harvestCount
                                    local baseProduction = cropInfo.productionRate * activePlants
                                    
                                    -- Calculate total boost percent
                                    local totalBoostPercent = 100 -- Start with 100% for being online
                                    
                                    -- Apply debug boost
                                    if props.playerData and props.playerData.debugProductionBoost and props.playerData.debugProductionBoost > 0 then
                                        totalBoostPercent = totalBoostPercent + props.playerData.debugProductionBoost
                                    end
                                    
                                    -- Apply production gamepass boost
                                    if props.playerData and props.playerData.gamepasses and props.playerData.gamepasses.productionBoost then
                                        totalBoostPercent = totalBoostPercent + 100
                                    end
                                    
                                    -- Apply weather boost
                                    if props.weatherData and props.weatherData.current and props.weatherData.current.name then
                                        local weatherName = props.weatherData.current.name
                                        if weatherName == "Rainy" then
                                            totalBoostPercent = totalBoostPercent + 20
                                        elseif weatherName == "Thunderstorm" then
                                            totalBoostPercent = totalBoostPercent - 20
                                        elseif weatherName == "Sunny" then
                                            totalBoostPercent = totalBoostPercent + 50
                                        end
                                    end
                                    
                                    local boostedProduction = baseProduction * (1 + totalBoostPercent / 100)
                                    return string.format("<b>Production:</b> %d/h (+%d%% = %d/h)", 
                                        baseProduction, 
                                        math.floor(totalBoostPercent), 
                                        math.floor(boostedProduction))
                                else
                                    return "<b>Production:</b> N/A"
                                end
                            end)(),
                            TextColor3 = Color3.fromRGB(0, 150, 0),
                            TextSize = normalTextSize,
                            BackgroundTransparency = 1,
                            Font = Enum.Font.Gotham,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            RichText = true,
                            ZIndex = 33
                        }),
                        
                        -- Crops Ready
                        CropsReadyText = e("TextLabel", {
                            Size = UDim2.new(1, -20, 0, 25),
                            Position = UDim2.new(0, 10, 0, 95),
                            Text = "Crops Ready: " .. tostring(currentCropsReady),
                            TextColor3 = canHarvest and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(100, 100, 100),
                            TextSize = normalTextSize,
                            BackgroundTransparency = 1,
                            Font = Enum.Font.GothamBold,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 33
                        }),
                        
                        -- Growth status (below other info)
                        GrowthStatusText = e("TextLabel", {
                            Size = UDim2.new(1, -20, 0, 25),
                            Position = UDim2.new(0, 10, 0, 120),
                            Text = tostring(growthProgressText),
                            TextColor3 = Color3.fromRGB(100, 100, 100),
                            TextSize = smallTextSize,
                            BackgroundTransparency = 1,
                            Font = Enum.Font.Gotham,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 33
                        })
                    })
                }) or nil,
                
            })
        })
        }),
        
    })
end

return PlotUI_Simple