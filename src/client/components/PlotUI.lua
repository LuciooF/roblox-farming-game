-- Modern Plot UI Component
-- Clean, informative UI for plot management with real-time updates

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local TweenService = game:GetService("TweenService")
local e = React.createElement
local ClientLogger = require(script.Parent.Parent.ClientLogger)
local RainEffectManager = require(script.Parent.Parent.RainEffectManager)
local PlotUtils = require(script.Parent.Parent.PlotUtils)
local PlotGrowthCalculator = require(script.Parent.Parent.PlotGrowthCalculator)
local ScreenUtils = require(game:GetService("ReplicatedStorage").Shared.ScreenUtils)
local CropRegistry = require(game:GetService("ReplicatedStorage").Shared.CropRegistry)
local NumberFormatter = require(game:GetService("ReplicatedStorage").Shared.NumberFormatter)
local assets = require(game:GetService("ReplicatedStorage").Shared.assets)
local Modal = require(script.Parent.Modal)

local log = ClientLogger.getModuleLogger("PlotUI")

local function PlotUI(props)
    local plotData = props.plotData or {}
    local visible = props.visible or false
    local onClose = props.onClose or function() end
    local remotes = props.remotes or {}
    local playerData = props.playerData
    local onOpenShop = props.onOpenShop or function() end
    local onOpenPlanting = props.onOpenPlanting or function() end
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    
    -- Responsive sizing
    local scale = ScreenUtils.getProportionalScale(screenSize)
    local panelWidth = math.min(screenSize.X * 0.9, ScreenUtils.getProportionalSize(screenSize, 700))
    local panelHeight = math.min(screenSize.Y * 0.85, ScreenUtils.getProportionalSize(screenSize, 600))
    
    -- Proportional text sizes
    local titleTextSize = ScreenUtils.getProportionalTextSize(screenSize, 32)
    local normalTextSize = ScreenUtils.getProportionalTextSize(screenSize, 18)
    local smallTextSize = ScreenUtils.getProportionalTextSize(screenSize, 14)
    local buttonTextSize = ScreenUtils.getProportionalTextSize(screenSize, 16)
    local cardTitleSize = ScreenUtils.getProportionalTextSize(screenSize, 20)
    local cardValueSize = ScreenUtils.getProportionalTextSize(screenSize, 16)
    
    -- Extract plot state info
    local plotId = plotData.plotId
    local state = plotData.state or "empty"
    local seedType = plotData.seedType or ""
    local plantName = seedType:gsub("^%l", string.upper)
    local harvestCount = plotData.harvestCount or 0
    local maxHarvests = plotData.maxHarvests or 0
    local accumulatedCrops = plotData.accumulatedCrops or 0
    local wateredCount = plotData.wateredCount or 0
    local waterNeeded = plotData.waterNeeded or 0
    
    -- Timing data
    local plantedAt = plotData.plantedAt or 0
    local lastWateredAt = plotData.lastWateredAt or 0
    local growthTime = plotData.growthTime or 60
    local waterTime = plotData.waterTime or 30
    
    -- Water cooldown data
    local lastWaterActionTime = plotData.lastWaterActionTime or 0
    local waterCooldownSeconds = plotData.waterCooldownSeconds or 30
    
    -- Boost data
    local weatherEffects = plotData.weatherEffects or {}
    local onlineBonus = plotData.onlineBonus or false
    
    -- Maintenance watering data
    local needsMaintenanceWater = plotData.needsMaintenanceWater or false
    local lastMaintenanceWater = plotData.lastMaintenanceWater or 0
    local maintenanceWaterInterval = plotData.maintenanceWaterInterval or 43200 -- 12 hours
    
    -- Real-time countdown state
    local currentTime, setCurrentTime = React.useState(tick())
    
    -- Hover state for production preview
    local showProductionPreview, setShowProductionPreview = React.useState(false)
    local plantAllHover, setPlantAllHover = React.useState(false)
    
    -- Plot growth status from new calculator
    local plotStatus, setPlotStatus = React.useState(nil)
    
    -- Update timer every second for real-time countdown and growth calculations
    React.useEffect(function()
        local connection = game:GetService("RunService").Heartbeat:Connect(function()
            setCurrentTime(tick())
            
            -- Temporarily disable new growth calculator to debug React issue
            setPlotStatus(nil)
            
            -- TODO: Re-enable once React text issue is resolved
            -- if plotData and plotData.seedType and plotData.seedType ~= "" then
            --     local success, result = pcall(function()
            --         local lastOnlineAt = playerData and playerData.lastOnlineAt or tick()
            --         local playerBoosts = {
            --             onlineBoost = onlineBonus and 2.0 or 1.0,
            --             globalMultiplier = weatherEffects and weatherEffects.growthMultiplier or 1.0
            --         }
            --         return PlotGrowthCalculator.getPlotStatus(plotData, lastOnlineAt, playerBoosts)
            --     end)
            --     if success and result then
            --         setPlotStatus(result)
            --     else
            --         setPlotStatus(nil)
            --     end
            -- else
            --     setPlotStatus(nil)
            -- end
        end)
        
        return function()
            connection:Disconnect()
        end
    end, {plotData, playerData, onlineBonus, weatherEffects})
    
    -- Get crop info from registry
    local cropInfo = seedType ~= "" and CropRegistry.getCrop(seedType) or nil
    local cropVisuals = cropInfo -- Use crop data directly since it contains all visual info
    
    -- Check if player has more of the current crop type
    local currentCropCount = 0
    if seedType ~= "" then
        if playerData.inventory and playerData.inventory.seeds then
            currentCropCount = currentCropCount + (playerData.inventory.seeds[seedType] or 0)
        end
        if playerData.inventory and playerData.inventory.crops then
            currentCropCount = currentCropCount + (playerData.inventory.crops[seedType] or 0)
        end
    end
    
    -- Calculate total seeds/crops available for Plant All display
    local totalAvailableSeeds = 0
    if playerData.inventory then
        if playerData.inventory.seeds then
            for _, quantity in pairs(playerData.inventory.seeds) do
                totalAvailableSeeds = totalAvailableSeeds + (quantity or 0)
            end
        end
        if playerData.inventory.crops then
            for _, quantity in pairs(playerData.inventory.crops) do
                totalAvailableSeeds = totalAvailableSeeds + (quantity or 0)
            end
        end
    end
    
    -- Plot capacity calculation (max 50 plants per plot)
    local MAX_PLANTS_PER_PLOT = 50
    local activePlants = maxHarvests - harvestCount
    local currentPlantCount = state == "empty" and 0 or activePlants
    local availableSpace = MAX_PLANTS_PER_PLOT - currentPlantCount
    local canPlantMore = availableSpace > 0
    
    -- Calculate how many we can actually plant (limited by space and inventory)
    local plantAllQuantity = math.min(availableSpace or 0, totalAvailableSeeds or 0)
    
    -- Production rates (for preview) - actual calculations are in PlotGrowthCalculator
    local baseProductionPerHour = (cropInfo and cropInfo.productionRate) or 0 -- crops per hour per plant
    local totalProductionPerHour = baseProductionPerHour * activePlants
    local productionWithOneMore = baseProductionPerHour * (activePlants + 1)
    local actualPlantsAfterPlantAll = activePlants + plantAllQuantity
    local productionWithPlantAll = baseProductionPerHour * actualPlantsAfterPlantAll
    
    -- Calculate water countdown or status
    local waterStatus = ""
    local waterStatusColor = Color3.fromRGB(100, 200, 255)
    local canWater = false
    
    if state == "empty" then
        waterStatus = "Empty plot"
    elseif state == "planted" or state == "growing" then
        if wateredCount < waterNeeded then
            waterStatus = "Now!"
            waterStatusColor = Color3.fromRGB(255, 100, 100)
            canWater = true
        else
            waterStatus = "Watered"
        end
    elseif needsMaintenanceWater then
        waterStatus = "Now!"
        waterStatusColor = Color3.fromRGB(255, 100, 100)
        canWater = true
    else
        -- Calculate time until next maintenance water
        local timeSinceLastMaintenance = currentTime - lastMaintenanceWater
        local timeUntilNextMaintenance = maintenanceWaterInterval - timeSinceLastMaintenance
        
        if timeUntilNextMaintenance > 0 then
            local hours = math.floor(timeUntilNextMaintenance / 3600)
            local minutes = math.floor((timeUntilNextMaintenance % 3600) / 60)
            local seconds = math.floor(timeUntilNextMaintenance % 60)
            
            if hours > 0 then
                waterStatus = string.format("%dh %dm", hours, minutes)
            elseif minutes > 0 then
                waterStatus = string.format("%dm %ds", minutes, seconds)
            else
                waterStatus = string.format("%ds", seconds)
            end
        else
            waterStatus = "Now!"
            waterStatusColor = Color3.fromRGB(255, 100, 100)
            canWater = true
        end
    end
    
    -- Check water cooldown
    if canWater and lastWaterActionTime > 0 then
        local timeSinceLastWater = currentTime - lastWaterActionTime
        local cooldownRemaining = waterCooldownSeconds - timeSinceLastWater
        
        if cooldownRemaining > 0 then
            canWater = false
            local cooldownMinutes = math.floor(cooldownRemaining / 60)
            local cooldownSeconds = math.floor(cooldownRemaining % 60)
            if cooldownMinutes > 0 then
                waterStatus = string.format("Cooldown %dm %ds", cooldownMinutes, cooldownSeconds)
            else
                waterStatus = string.format("Cooldown %ds", cooldownSeconds)
            end
            waterStatusColor = Color3.fromRGB(255, 200, 100)
        end
    end
    
    -- Calculate growth progress using new PlotGrowthCalculator
    local growthProgress = 0
    local growthProgressText = "0% grown"
    local currentCropsReady = accumulatedCrops or 0 -- Default to plot data
    local effectiveProductionRate = baseProductionPerHour * activePlants
    local nextCropTimeText = "Calculating..."
    
    -- Temporarily use old growth calculation logic
    if state ~= "empty" and cropInfo then
        local productionRate = cropInfo.productionRate or 1
        local productionInterval = 3600 / productionRate -- seconds per crop
        
        -- Apply online bonus (2x speed when player is online)
        local effectiveInterval = productionInterval * 0.5 -- Assume player is online for UI
        
        if state == "watered" or state == "ready" then
            -- Calculate time since planting or last harvest
            local timeSinceStart = currentTime - (plantedAt or 0)
            local cycleProgress = (timeSinceStart % effectiveInterval) / effectiveInterval
            growthProgress = math.min(cycleProgress, 1)
            
            -- Show stack info and growth progress
            local stackText = "Stack of " .. tostring(activePlants)
            local progressPercent = math.floor(growthProgress * 100)
            growthProgressText = tostring(stackText) .. " | " .. tostring(progressPercent) .. "% grown"
            
            -- Only show "Ready to harvest!" when hitting 1k crop limit
            local CROP_LIMIT = 1000
            if accumulatedCrops >= CROP_LIMIT then
                growthProgress = 1
                growthProgressText = tostring(stackText) .. " | Ready to harvest!"
            elseif growthProgress >= 1 then
                -- Crop cycle complete but not at limit - keep producing
                growthProgress = 1
                growthProgressText = tostring(stackText) .. " | Producing..."
            end
        end
    end
    
    -- Final safety check to ensure growthProgressText is always a valid string
    growthProgressText = tostring(growthProgressText or "0% grown")
    
    -- Action handlers
    local function handlePlant()
        if remotes.farmAction then
            log.info("Planting 1 more", seedType, "on plot", plotId)
            remotes.farmAction:FireServer("plant", plotId, seedType, 1)
        end
    end
    
    local function handleWater()
        if remotes.farmAction then
            log.info("Watering plot", plotId)
            remotes.farmAction:FireServer("water", plotId)
            
            -- Create rain effect
            local plot = PlotUtils.findPlotById(plotId)
            if plot then
                RainEffectManager.createRainEffect(plot)
            end
        end
    end
    
    local function handleHarvest()
        if remotes.farmAction then
            local harvestAmount = currentCropsReady > 0 and currentCropsReady or (accumulatedCrops or 0)
            log.info("Harvesting plot", plotId, "- expected amount:", harvestAmount)
            remotes.farmAction:FireServer("harvest", plotId, harvestAmount)
        end
    end
    
    return e(Modal, {
        visible = visible,
        onClose = onClose,
        zIndex = 30
    }, {
        PlotContainer = e("Frame", {
            Name = "PlotContainer",
            Size = UDim2.new(0, panelWidth * scale, 0, panelHeight * scale + 50),
            Position = UDim2.new(0.5, -panelWidth * scale / 2, 0.5, -(panelHeight * scale + 50) / 2),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 30
        }, {
            PlotPanel = e("Frame", {
                Name = "PlotPanel",
                Size = UDim2.new(0, panelWidth * scale, 0, panelHeight * scale),
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
                        Size = UDim2.new(1, -10, 1, 0),
                        Position = UDim2.new(0, 5, 0, 0),
                        Text = "PLOT UI",
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
                    Color = Color3.fromRGB(100, 200, 100),
                    Thickness = 3,
                    Transparency = 0.1
                }),
                
                Gradient = e("UIGradient", {
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                        ColorSequenceKeypoint.new(0.3, Color3.fromRGB(250, 255, 250)),
                        ColorSequenceKeypoint.new(0.7, Color3.fromRGB(245, 255, 245)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(240, 250, 240))
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
                
                -- Main Content Container
                ContentContainer = e("Frame", {
                    Size = UDim2.new(1, -40, 1, -40),
                    Position = UDim2.new(0, 20, 0, 20),
                    BackgroundTransparency = 1,
                    ZIndex = 31
                }, {
                    -- Crop Card Section
                    CropCard = state ~= "empty" and e("Frame", {
                        Name = "CropCard",
                        Size = UDim2.new(1, 0, 0, 180),
                        Position = UDim2.new(0, 0, 0, 0),
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        BackgroundTransparency = 0.1,
                        BorderSizePixel = 0,
                        ZIndex = 32
                    }, {
                        Corner = e("UICorner", {
                            CornerRadius = UDim.new(0, 15)
                        }),
                        
                        Stroke = e("UIStroke", {
                            Color = cropInfo and (CropRegistry.rarities[cropInfo.rarity] and CropRegistry.rarities[cropInfo.rarity].color or Color3.fromRGB(150, 150, 150)) or Color3.fromRGB(150, 150, 150),
                            Thickness = 3,
                            Transparency = 0.2
                        }),
                        
                        CardGradient = e("UIGradient", {
                            Color = ColorSequence.new{
                                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                                ColorSequenceKeypoint.new(1, Color3.fromRGB(248, 252, 255))
                            },
                            Rotation = 45
                        }),
                        
                        -- Crop Icon
                        CropIcon = (function()
                            if cropVisuals and cropVisuals.assetId then
                                return e("ImageLabel", {
                                    Name = "CropIcon",
                                    Size = UDim2.new(0, 80, 0, 80),
                                    Position = UDim2.new(0, 20, 0.5, -40),
                                    Image = cropVisuals.assetId,
                                    BackgroundTransparency = 1,
                                    ScaleType = Enum.ScaleType.Fit,
                                    ZIndex = 33
                                })
                            else
                                return e("TextLabel", {
                                    Name = "CropEmoji",
                                    Size = UDim2.new(0, 80, 0, 80),
                                    Position = UDim2.new(0, 20, 0.5, -40),
                                    Text = tostring(cropVisuals and cropVisuals.emoji or "🌱"),
                                    TextSize = normalTextSize,
                                    TextWrapped = true,
                                    BackgroundTransparency = 1,
                                    Font = Enum.Font.SourceSansBold,
                                    ZIndex = 33
                                })
                            end
                        end)(),
                        
                        -- Crop Info
                        CropName = e("TextLabel", {
                            Size = UDim2.new(0, 200, 0, 30),
                            Position = UDim2.new(0, 120, 0, 20),
                            Text = plantName,
                            TextColor3 = Color3.fromRGB(40, 40, 40),
                            TextSize = normalTextSize,
            TextWrapped = true,
                            BackgroundTransparency = 1,
                            Font = Enum.Font.GothamBold,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 33
                        }),
                        
                        -- Rarity Badge
                        RarityBadge = cropInfo and e("Frame", {
                            Size = UDim2.new(0, 80, 0, 20),
                            Position = UDim2.new(0, 120, 0, 55),
                            BackgroundColor3 = CropRegistry.rarities[cropInfo.rarity] and CropRegistry.rarities[cropInfo.rarity].color or Color3.fromRGB(150, 150, 150),
                            BorderSizePixel = 0,
                            ZIndex = 33
                        }, {
                            Corner = e("UICorner", {
                                CornerRadius = UDim.new(0, 10)
                            }),
                            RarityText = e("TextLabel", {
                                Size = UDim2.new(1, 0, 1, 0),
                                Text = cropInfo.rarity:upper(),
                                TextColor3 = Color3.fromRGB(255, 255, 255),
                                TextSize = normalTextSize,
            TextWrapped = true,
                                BackgroundTransparency = 1,
                                Font = Enum.Font.GothamBold,
                                ZIndex = 34
                            })
                        }) or nil,
                        
                        -- Stats Grid
                        StatsGrid = e("Frame", {
                            Size = UDim2.new(0.5, -20, 0, 60),
                            Position = UDim2.new(0, 120, 0, 90),
                            BackgroundTransparency = 1,
                            ZIndex = 33
                        }, {
                            -- Water Status
                            WaterFrame = e("Frame", {
                                Size = UDim2.new(0.5, -5, 1, 0),
                                Position = UDim2.new(0, 0, 0, 0),
                                BackgroundTransparency = 1,
                                ZIndex = 33
                            }, {
                                WaterLabel = e("TextLabel", {
                                    Size = UDim2.new(1, 0, 0, 20),
                                    Text = "Water in:",
                                    TextColor3 = Color3.fromRGB(120, 120, 120),
                                    TextSize = normalTextSize,
            TextWrapped = true,
                                    BackgroundTransparency = 1,
                                    Font = Enum.Font.Gotham,
                                    TextXAlignment = Enum.TextXAlignment.Left,
                                    ZIndex = 33
                                }),
                                WaterValue = e("TextLabel", {
                                    Size = UDim2.new(1, 0, 0, 35),
                                    Position = UDim2.new(0, 0, 0, 20),
                                    Text = waterStatus,
                                    TextColor3 = waterStatusColor,
                                    TextSize = normalTextSize,
            TextWrapped = true,
                                    BackgroundTransparency = 1,
                                    Font = Enum.Font.GothamBold,
                                    TextXAlignment = Enum.TextXAlignment.Left,
                                    ZIndex = 33
                                })
                            }),
                            
                            -- Production Rate
                            ProductionFrame = e("Frame", {
                                Size = UDim2.new(0.5, -5, 1, 0),
                                Position = UDim2.new(0.5, 5, 0, 0),
                                BackgroundTransparency = 1,
                                ZIndex = 33
                            }, {
                                ProductionLabel = e("TextLabel", {
                                    Size = UDim2.new(1, 0, 0, 20),
                                    Text = "Production:",
                                    TextColor3 = Color3.fromRGB(120, 120, 120),
                                    TextSize = normalTextSize,
            TextWrapped = true,
                                    BackgroundTransparency = 1,
                                    Font = Enum.Font.Gotham,
                                    TextXAlignment = Enum.TextXAlignment.Left,
                                    ZIndex = 33
                                }),
                                -- Production display with multi-color support for hover effects
                                ProductionContainer = e("Frame", {
                                    Size = UDim2.new(1, 0, 0, 25),
                                    Position = UDim2.new(0, 0, 0, 20),
                                    BackgroundTransparency = 1,
                                    ZIndex = 33
                                }, {
                                    Layout = e("UIListLayout", {
                                        FillDirection = Enum.FillDirection.Horizontal,
                                        HorizontalAlignment = Enum.HorizontalAlignment.Left,
                                        VerticalAlignment = Enum.VerticalAlignment.Center,
                                        Padding = UDim.new(0, 0),
                                        SortOrder = Enum.SortOrder.LayoutOrder
                                    }),
                                    
                                    -- Current production (always green)
                                    CurrentProduction = e("TextLabel", {
                                        Size = UDim2.new(0, 0, 1, 0),
                                        AutomaticSize = Enum.AutomaticSize.X,
                                        Text = waterStatus == "Now!" and "0/h" or (tostring(NumberFormatter.format(totalProductionPerHour) or totalProductionPerHour or 0) .. "/h"),
                                        TextColor3 = waterStatus == "Now!" and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 200, 100),
                                        TextSize = normalTextSize,
            TextWrapped = true,
                                        BackgroundTransparency = 1,
                                        Font = Enum.Font.GothamBold,
                                        TextXAlignment = Enum.TextXAlignment.Left,
                                        ZIndex = 33,
                                        LayoutOrder = 1
                                    }, {
                                        TextStroke = e("UIStroke", {
                                            Color = Color3.fromRGB(0, 0, 0),
                                            Thickness = 2,
                                            Transparency = 0.3
                                        })
                                    }),
                                    
                                    -- Arrow and new production (darker green, only show on hover)
                                    HoverProduction = (showProductionPreview or plantAllHover) and e("TextLabel", {
                                        Size = UDim2.new(0, 0, 1, 0),
                                        AutomaticSize = Enum.AutomaticSize.X,
                                        Text = waterStatus == "Now!" and " → 0/h" or 
                                            (plantAllHover and (" → " .. tostring(NumberFormatter.format(productionWithPlantAll) or productionWithPlantAll or 0) .. "/h") or (" → " .. tostring(NumberFormatter.format(productionWithOneMore) or productionWithOneMore or 0) .. "/h")),
                                        TextColor3 = waterStatus == "Now!" and Color3.fromRGB(200, 80, 80) or Color3.fromRGB(60, 140, 60), -- Red if needs water, darker green otherwise
                                        TextSize = normalTextSize,
            TextWrapped = true,
                                        BackgroundTransparency = 1,
                                        Font = Enum.Font.GothamBold,
                                        TextXAlignment = Enum.TextXAlignment.Left,
                                        ZIndex = 33,
                                        LayoutOrder = 2
                                    }, {
                                        TextStroke = e("UIStroke", {
                                            Color = Color3.fromRGB(0, 0, 0),
                                            Thickness = 2,
                                            Transparency = 0.3
                                        })
                                    }) or nil
                                }),
                                
                                -- Water needed explanation text
                                WaterNeededText = (waterStatus == "Now!") and e("TextLabel", {
                                    Size = UDim2.new(1, 0, 0, 10),
                                    Position = UDim2.new(0, 0, 0, 45),
                                    Text = "(Because it needs water!)",
                                    TextColor3 = Color3.fromRGB(200, 50, 50),
                                    TextSize = smallTextSize,
                                    BackgroundTransparency = 1,
                                    Font = Enum.Font.Gotham,
                                    TextXAlignment = Enum.TextXAlignment.Left,
                                    ZIndex = 33
                                }) or nil
                            })
                        }),
                        
                        -- Active Plants & Crops Generated
                        InfoRow = e("Frame", {
                            Size = UDim2.new(1, -260, 0, 25),
                            Position = UDim2.new(1, -240, 0, 20),
                            BackgroundTransparency = 1,
                            ZIndex = 33
                        }, {
                            PlantsInfo = e("TextLabel", {
                                Size = UDim2.new(0.5, -5, 1, 0),
                                Position = UDim2.new(0, 0, 0, 0),
                                Text = "🌱 Plants: " .. tostring(activePlants) .. "/" .. tostring(MAX_PLANTS_PER_PLOT),
                                TextColor3 = Color3.fromRGB(100, 100, 100),
                                TextSize = normalTextSize,
            TextWrapped = true,
                                BackgroundTransparency = 1,
                                Font = Enum.Font.GothamMedium,
                                TextXAlignment = Enum.TextXAlignment.Right,
                                ZIndex = 33
                            }),
                            -- Removed CropsInfo - harvest amount now only shown on harvest button
                        })
                    }) or nil,
                    
                    -- Growth Progress Bar
                    GrowthProgressContainer = (state ~= "empty") and e("Frame", {
                        Size = UDim2.new(1, 0, 0, 25),
                        Position = UDim2.new(0, 0, 1, -35),
                        BackgroundTransparency = 1,
                        ZIndex = 33
                    }, {
                        ProgressLabel = e("TextLabel", {
                            Size = UDim2.new(1, 0, 0, 12),
                            Position = UDim2.new(0, 0, 0, 5),
                            Text = growthProgressText,
                            TextColor3 = growthProgress >= 1 and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(100, 100, 100),
                            TextSize = smallTextSize,
                            BackgroundTransparency = 1,
                            Font = Enum.Font.GothamMedium,
                            TextXAlignment = Enum.TextXAlignment.Center,
                            ZIndex = 33
                        }),
                        
                        ProgressBarBG = e("Frame", {
                            Size = UDim2.new(1, 0, 0, 6),
                            Position = UDim2.new(0, 0, 0, 22),
                            BackgroundColor3 = Color3.fromRGB(200, 200, 200),
                            BorderSizePixel = 0,
                            ZIndex = 33
                        }, {
                            Corner = e("UICorner", {
                                CornerRadius = UDim.new(0, 4)
                            }),
                            
                            ProgressBar = e("Frame", {
                                Size = UDim2.new(growthProgress, 0, 1, 0),
                                Position = UDim2.new(0, 0, 0, 0),
                                BackgroundColor3 = growthProgress >= 1 and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(50, 150, 255),
                                BorderSizePixel = 0,
                                ZIndex = 34
                            }, {
                                Corner = e("UICorner", {
                                    CornerRadius = UDim.new(0, 4)
                                })
                            })
                        })
                    }) or nil,
                    
                    -- Empty Plot Message
                    EmptyPlotMessage = state == "empty" and e("Frame", {
                        Name = "EmptyMessage",
                        Size = UDim2.new(1, 0, 0, 180),
                        Position = UDim2.new(0, 0, 0, 0),
                        BackgroundColor3 = Color3.fromRGB(250, 250, 250),
                        BackgroundTransparency = 0.1,
                        BorderSizePixel = 0,
                        ZIndex = 32
                    }, {
                        Corner = e("UICorner", {
                            CornerRadius = UDim.new(0, 15)
                        }),
                        
                        Stroke = e("UIStroke", {
                            Color = Color3.fromRGB(200, 200, 200),
                            Thickness = 2,
                            Transparency = 0.3
                        }),
                        
                        EmptyIcon = e("TextLabel", {
                            Size = UDim2.new(0, 80, 0, 80),
                            Position = UDim2.new(0.5, -40, 0, 20),
                            Text = "🌱",
                            TextSize = normalTextSize,
            TextWrapped = true,
                            BackgroundTransparency = 1,
                            Font = Enum.Font.SourceSansBold,
                            ZIndex = 33
                        }),
                        
                        EmptyText = e("TextLabel", {
                            Size = UDim2.new(1, -40, 0, 40),
                            Position = UDim2.new(0, 20, 0, 110),
                            Text = "Empty Plot - Ready for planting!",
                            TextColor3 = Color3.fromRGB(100, 100, 100),
                            TextSize = normalTextSize,
            TextWrapped = true,
                            BackgroundTransparency = 1,
                            Font = Enum.Font.GothamBold,
                            TextXAlignment = Enum.TextXAlignment.Center,
                            ZIndex = 33
                        })
                    }) or nil,
                    
                    -- Action Buttons Container
                    -- Calculate dynamic height based on visible buttons
                    ButtonsContainerHeight = (function()
                        local height = 0
                        if state == "empty" then
                            height = 50 -- Plant Seeds button only
                        else
                            -- Plant/Plant All buttons
                            if activePlants < 50 and (currentCropCount > 0 or availableSpace > 1) then
                                height = height + 60 + 10 -- button + spacing
                            end
                            -- Water button
                            if state ~= "dead" then
                                height = height + 60 + 10 -- button + spacing
                            end
                            -- Harvest button - use new calculator results
                            if currentCropsReady > 0 or (growthProgress >= 1 and state == "watered") then
                                height = height + 60 + 10 -- button + spacing
                            end
                            height = math.max(height - 10, 0) -- Remove last spacing
                        end
                        return height
                    end)(),
                    
                    ButtonsContainer = e("Frame", {
                        Size = UDim2.new(1, 0, 0, ButtonsContainerHeight),
                        Position = UDim2.new(0, 0, 0, 200),
                        BackgroundTransparency = 1,
                        ZIndex = 31
                    }, {
                        -- Plant Seeds Button (for empty plots)
                        PlantSeedsButton = (state == "empty") and e("TextButton", {
                            Name = "PlantSeedsButton",
                            Size = UDim2.new(0, 220, 0, 50),
                            Position = UDim2.new(0.5, -110, 0, 0),
                            BackgroundColor3 = Color3.fromRGB(100, 200, 100),
                            Text = "",
                            BorderSizePixel = 0,
                            ZIndex = 32,
                            [React.Event.Activated] = onOpenPlanting
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
                                Thickness = 2,
                                Transparency = 0.2
                            }),
                            
                            ButtonText = e("TextLabel", {
                                Size = UDim2.new(1, 0, 1, 0),
                                Text = "Plant Crops!",
                                TextColor3 = Color3.fromRGB(255, 255, 255),
                                TextSize = normalTextSize,
            TextWrapped = true,
                                BackgroundTransparency = 1,
                                Font = Enum.Font.GothamBold,
                                TextXAlignment = Enum.TextXAlignment.Center,
                                ZIndex = 33
                            }, {
                                TextStroke = e("UIStroke", {
                                    Color = Color3.fromRGB(0, 0, 0),
                                    Thickness = 2,
                                    Transparency = 0.3
                                })
                            })
                        }) or nil,
                        
                        -- Plant More Button (for existing plots)
                        PlantButton = (state ~= "empty" and state ~= "dead" and activePlants < 50 and currentCropCount > 0) and e("TextButton", {
                            Name = "PlantButton",
                            Size = UDim2.new(0.5, -5, 0, 60),
                            Position = UDim2.new(0, 0, 0, 0),
                            BackgroundColor3 = Color3.fromRGB(120, 200, 120),
                            Text = "",
                            BorderSizePixel = 0,
                            ZIndex = 32,
                            [React.Event.MouseEnter] = function()
                                setShowProductionPreview(true)
                            end,
                            [React.Event.MouseLeave] = function()
                                setShowProductionPreview(false)
                            end,
                            [React.Event.Activated] = handlePlant
                        }, {
                            Corner = e("UICorner", {
                                CornerRadius = UDim.new(0, 12)
                            }),
                            
                            Gradient = e("UIGradient", {
                                Color = ColorSequence.new{
                                    ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 220, 140)),
                                    ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 180, 100))
                                },
                                Rotation = 90
                            }),
                            
                            Stroke = e("UIStroke", {
                                Color = Color3.fromRGB(80, 160, 80),
                                Thickness = 2,
                                Transparency = 0.2
                            }),
                            
                            PlantMoreText = e("TextLabel", {
                                Size = UDim2.new(1, -20, 1, 0),
                                Position = UDim2.new(0, 10, 0, 0),
                                Text = "🌱 Plant (1)",
                                TextColor3 = Color3.fromRGB(255, 255, 255),
                                TextSize = normalTextSize,
            TextWrapped = true,
                                BackgroundTransparency = 1,
                                Font = Enum.Font.GothamBold,
                                TextXAlignment = Enum.TextXAlignment.Center,
                                ZIndex = 33
                            }, {
                                TextStroke = e("UIStroke", {
                                    Color = Color3.fromRGB(0, 0, 0),
                                    Thickness = 2,
                                    Transparency = 0.7
                                })
                            })
                        }) or nil,
                        
                        -- Plant All Button (for existing plots with space)
                        PlantAllExistingButton = (state ~= "empty" and state ~= "dead" and availableSpace > 1 and currentCropCount > 0) and e("TextButton", {
                            Name = "PlantAllExistingButton",
                            Size = UDim2.new(0.5, -5, 0, 60),
                            Position = UDim2.new(0.5, 5, 0, 0),
                            BackgroundColor3 = Color3.fromRGB(80, 160, 200),
                            Text = "",
                            BorderSizePixel = 0,
                            ZIndex = 32,
                            [React.Event.MouseEnter] = function()
                                setPlantAllHover(true)
                            end,
                            [React.Event.MouseLeave] = function()
                                setPlantAllHover(false)
                            end,
                            [React.Event.Activated] = function()
                                if onOpenPlanting then
                                    onOpenPlanting("all") -- Pass "all" mode to indicate plant all
                                end
                            end
                        }, {
                            Corner = e("UICorner", {
                                CornerRadius = UDim.new(0, 12)
                            }),
                            
                            Gradient = e("UIGradient", {
                                Color = ColorSequence.new{
                                    ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 180, 220)),
                                    ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 140, 180))
                                },
                                Rotation = 90
                            }),
                            
                            Stroke = e("UIStroke", {
                                Color = Color3.fromRGB(60, 140, 200),
                                Thickness = 2,
                                Transparency = 0.2
                            }),
                            
                            ButtonContent = e("Frame", {
                                Size = UDim2.new(1, -20, 1, 0),
                                Position = UDim2.new(0, 10, 0, 0),
                                BackgroundTransparency = 1,
                                ZIndex = 33
                            }, {
                                MainText = e("TextLabel", {
                                    Size = UDim2.new(1, 0, 0.6, 0),
                                    Position = UDim2.new(0, 0, 0, 0),
                                    Text = "🌱 Plant (" .. tostring(plantAllQuantity) .. ")",
                                    TextColor3 = Color3.fromRGB(255, 255, 255),
                                    TextSize = normalTextSize,
            TextWrapped = true,
                                    BackgroundTransparency = 1,
                                    Font = Enum.Font.GothamBold,
                                    TextXAlignment = Enum.TextXAlignment.Center,
                                    ZIndex = 33
                                }, {
                                    TextStroke = e("UIStroke", {
                                        Color = Color3.fromRGB(0, 0, 0),
                                        Thickness = 2,
                                        Transparency = 0.7
                                    })
                                }),
                                
                                SubText = e("TextLabel", {
                                    Size = UDim2.new(1, 0, 0.4, 0),
                                    Position = UDim2.new(0, 0, 0.6, 0),
                                    Text = "(All you have)",
                                    TextColor3 = Color3.fromRGB(220, 220, 220),
                                    TextSize = normalTextSize,
            TextWrapped = true,
                                    BackgroundTransparency = 1,
                                    Font = Enum.Font.Gotham,
                                    TextXAlignment = Enum.TextXAlignment.Center,
                                    ZIndex = 33
                                }, {
                                    TextStroke = e("UIStroke", {
                                        Color = Color3.fromRGB(0, 0, 0),
                                        Thickness = 2,
                                        Transparency = 0.7
                                    })
                                })
                            })
                        }) or (state ~= "empty" and state ~= "dead" and activePlants < 50 and currentCropCount == 0) and e("TextButton", {
                            Name = "PlantButton",
                            Size = UDim2.new(1, 0, 0, 60),
                            Position = UDim2.new(0, 0, 0, 0),
                            BackgroundColor3 = Color3.fromRGB(100, 100, 100),
                            Text = "",
                            BorderSizePixel = 0,
                            ZIndex = 32,
                            Active = false,
                            AutoButtonColor = false
                        }, {
                            Corner = e("UICorner", {
                                CornerRadius = UDim.new(0, 12)
                            }),
                            
                            Stroke = e("UIStroke", {
                                Color = Color3.fromRGB(80, 80, 80),
                                Thickness = 2,
                                Transparency = 0.2
                            }),
                            
                            ButtonContent = e("Frame", {
                                Size = UDim2.new(1, -20, 1, 0),
                                Position = UDim2.new(0, 10, 0, 0),
                                BackgroundTransparency = 1,
                                ZIndex = 33
                            }, {
                                MainText = e("TextLabel", {
                                    Size = UDim2.new(1, 0, 1, 0),
                                    Text = "🌱 Plant More (No " .. tostring(plantName) .. " available)",
                                    TextColor3 = Color3.fromRGB(150, 150, 150),
                                    TextSize = normalTextSize,
            TextWrapped = true,
                                    BackgroundTransparency = 1,
                                    Font = Enum.Font.GothamBold,
                                    TextXAlignment = Enum.TextXAlignment.Center,
                                    ZIndex = 33
                                })
                            })
                        }) or nil,
                        
                        -- Harvest Button (show if crops ready from calculator OR if progress shows ready)
                        HarvestButton = (currentCropsReady > 0 or (growthProgress >= 1 and state == "watered")) and e("TextButton", {
                            Name = "HarvestButton",
                            Size = UDim2.new(1, 0, 0, 60),
                            Position = UDim2.new(0, 0, 0, (function()
                                local yPos = 0
                                -- Add space for plant buttons if visible
                                if activePlants < 50 and (currentCropCount > 0 or availableSpace > 1) then
                                    yPos = yPos + 70
                                end
                                -- Add space for water button if visible
                                if state ~= "dead" then
                                    yPos = yPos + 70
                                end
                                return yPos
                            end)()),
                            BackgroundColor3 = Color3.fromRGB(255, 200, 0),
                            Text = "",
                            BorderSizePixel = 0,
                            ZIndex = 32,
                            [React.Event.Activated] = handleHarvest
                        }, {
                            Corner = e("UICorner", {
                                CornerRadius = UDim.new(0, 12)
                            }),
                            
                            Gradient = e("UIGradient", {
                                Color = ColorSequence.new{
                                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 50)),
                                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 180, 0))
                                },
                                Rotation = 90
                            }),
                            
                            Stroke = e("UIStroke", {
                                Color = Color3.fromRGB(200, 150, 0),
                                Thickness = 2,
                                Transparency = 0.2
                            }),
                            
                            -- Shine effect
                            ShineEffect = e("Frame", {
                                Size = UDim2.new(0.3, 0, 1, 0),
                                Position = UDim2.new(-0.3, 0, 0, 0),
                                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                BackgroundTransparency = 0.7,
                                BorderSizePixel = 0,
                                ZIndex = 33
                            }, {
                                Corner = e("UICorner", {
                                    CornerRadius = UDim.new(0, 12)
                                }),
                                ShineGradient = e("UIGradient", {
                                    Transparency = NumberSequence.new{
                                        NumberSequenceKeypoint.new(0, 1),
                                        NumberSequenceKeypoint.new(0.5, 0.3),
                                        NumberSequenceKeypoint.new(1, 1)
                                    },
                                    Rotation = 30
                                })
                            }),
                            
                            HarvestText = e("TextLabel", {
                                Size = UDim2.new(1, -20, 1, 0),
                                Position = UDim2.new(0, 10, 0, 0),
                                Text = tostring(cropVisuals and cropVisuals.emoji or "🌾") .. " Harvest (" .. tostring(currentCropsReady > 0 and currentCropsReady or activePlants) .. ")",
                                TextColor3 = Color3.fromRGB(50, 50, 50),
                                TextSize = normalTextSize,
                                TextWrapped = true,
                                BackgroundTransparency = 1,
                                Font = Enum.Font.GothamBold,
                                TextXAlignment = Enum.TextXAlignment.Center,
                                ZIndex = 34
                            })
                        }) or nil,
                        
                        -- Water Button
                        WaterButton = (state ~= "empty" and state ~= "dead") and e("TextButton", {
                            Name = "WaterButton",
                            Size = UDim2.new(1, 0, 0, 60),
                            Position = UDim2.new(0, 0, 0, (activePlants < 50 and currentCropCount > 0) and 70 or 0),
                            BackgroundColor3 = canWater and Color3.fromRGB(100, 180, 255) or Color3.fromRGB(120, 120, 120),
                            Text = "",
                            BorderSizePixel = 0,
                            ZIndex = 32,
                            Active = canWater,
                            AutoButtonColor = canWater,
                            [React.Event.Activated] = canWater and handleWater or nil
                        }, {
                            Corner = e("UICorner", {
                                CornerRadius = UDim.new(0, 12)
                            }),
                            
                            Gradient = canWater and e("UIGradient", {
                                Color = ColorSequence.new{
                                    ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 200, 255)),
                                    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 160, 255))
                                },
                                Rotation = 90
                            }) or nil,
                            
                            Stroke = e("UIStroke", {
                                Color = canWater and Color3.fromRGB(60, 140, 200) or Color3.fromRGB(80, 80, 80),
                                Thickness = 2,
                                Transparency = 0.2
                            }),
                            
                            -- Shine effect for when water is needed
                            ShineEffect = canWater and waterStatus == "Now!" and e("Frame", {
                                Size = UDim2.new(0.3, 0, 1, 0),
                                Position = UDim2.new(-0.3, 0, 0, 0),
                                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                BackgroundTransparency = 0.7,
                                BorderSizePixel = 0,
                                ZIndex = 33
                            }, {
                                Corner = e("UICorner", {
                                    CornerRadius = UDim.new(0, 12)
                                }),
                                ShineGradient = e("UIGradient", {
                                    Transparency = NumberSequence.new{
                                        NumberSequenceKeypoint.new(0, 1),
                                        NumberSequenceKeypoint.new(0.5, 0.3),
                                        NumberSequenceKeypoint.new(1, 1)
                                    },
                                    Rotation = 30
                                })
                            }) or nil,
                            
                            WaterText = e("TextLabel", {
                                Size = UDim2.new(1, -20, 1, 0),
                                Position = UDim2.new(0, 10, 0, 0),
                                Text = canWater and "💧 Water" or (tostring(waterStatus):find("Cooldown") and "💧 Water (" .. tostring(waterStatus):gsub("Cooldown ", "In ") .. ")" or "💧 Water"),
                                TextColor3 = canWater and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150),
                                TextSize = normalTextSize,
                                TextWrapped = true,
                                BackgroundTransparency = 1,
                                Font = Enum.Font.GothamBold,
                                TextXAlignment = Enum.TextXAlignment.Center,
                                ZIndex = 34
                            }, {
                                TextStroke = canWater and e("UIStroke", {
                                    Color = Color3.fromRGB(0, 0, 0),
                                    Thickness = 2,
                                    Transparency = 0.7
                                }) or nil
                            })
                        }) or nil
                    })
                })
            })
        })
    })
end

return PlotUI