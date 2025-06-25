-- Plot UI Component
-- Interactive UI panel for plot management (plant, water, remove)

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local e = React.createElement
local ClientLogger = require(script.Parent.Parent.ClientLogger)
local RainEffectManager = require(script.Parent.Parent.RainEffectManager)
local PlotUtils = require(script.Parent.Parent.PlotUtils)

local log = ClientLogger.getModuleLogger("PlotUI")

local function PlotUI(props)
    local plotData = props.plotData or {}
    local visible = props.visible or false
    local onClose = props.onClose or function() end
    local remotes = props.remotes or {}
    local playerData = props.playerData or {}
    local onOpenShop = props.onOpenShop or function() end
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    
    -- Responsive sizing
    local isMobile = screenSize.X < 768
    local scale = isMobile and 0.85 or 1
    local panelWidth = isMobile and 400 or 480
    local panelHeight = isMobile and 480 or 550
    
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
    local deathTime = plotData.deathTime or 120
    
    -- Water cooldown data
    local lastWaterActionTime = plotData.lastWaterActionTime or 0
    local waterCooldownSeconds = plotData.waterCooldownSeconds or 30
    
    -- Boost data
    local weatherEffects = plotData.weatherEffects or {}
    local onlineBonus = plotData.onlineBonus or false
    local variation = plotData.variation or "normal"
    
    -- Get available seeds from player inventory
    -- Check both seeds and crops (crops can be planted)
    local availableSeeds = {}
    
    -- Check seeds inventory
    if playerData.inventory and playerData.inventory.seeds then
        for seedType, count in pairs(playerData.inventory.seeds) do
            if count > 0 then
                table.insert(availableSeeds, seedType)
            end
        end
    end
    
    -- Also check crops inventory (crops can be replanted)
    if playerData.inventory and playerData.inventory.crops then
        for cropType, count in pairs(playerData.inventory.crops) do
            if count > 0 and not table.find(availableSeeds, cropType) then
                table.insert(availableSeeds, cropType)
            end
        end
    end
    
    -- Sort seeds alphabetically
    table.sort(availableSeeds)
    
    -- Default selection: current seed type or first available seed
    local defaultSeed = (seedType ~= "" and seedType) or (availableSeeds[1] or "wheat")
    local selectedSeed, setSelectedSeed = React.useState(defaultSeed)
    local showSeedDropdown, setShowSeedDropdown = React.useState(false)
    local showRemoveConfirmation, setShowRemoveConfirmation = React.useState(false)
    
    -- Real-time countdown state
    local currentTime, setCurrentTime = React.useState(tick())
    
    -- Update timer every second for real-time countdown
    React.useEffect(function()
        local connection = game:GetService("RunService").Heartbeat:Connect(function()
            setCurrentTime(tick())
        end)
        
        return function()
            connection:Disconnect()
        end
    end, {})
    
    -- Action handlers
    local function handlePlant(quantity)
        quantity = quantity or 1 -- Default to planting 1
        if remotes.farmAction then
            log.info("Planting", quantity, selectedSeed, "on plot", plotId)
            remotes.farmAction:FireServer("plant", plotId, selectedSeed, quantity)
            -- Don't close the UI - let it update with new data
        end
    end
    
    local function handleWater()
        if remotes.farmAction then
            log.info("Watering plot", plotId)
            remotes.farmAction:FireServer("water", plotId)
            
            -- Create rain effect on the plot
            local plot = PlotUtils.findPlotById(plotId)
            if plot then
                RainEffectManager.createRainEffect(plot)
            end
            
            -- Don't close the UI - let it update with new data
        end
    end
    
    local function handleRemove()
        if remotes.farmAction then
            log.info("Removing crop from plot", plotId)
            remotes.farmAction:FireServer("clear", plotId)
            setShowRemoveConfirmation(false) -- Hide confirmation dialog
            
            -- Don't close the UI - let it update with new data
        end
    end
    
    local function handleRemoveRequest()
        setShowRemoveConfirmation(true)
    end
    
    local function handleCancelRemove()
        setShowRemoveConfirmation(false)
    end
    
    local function handleHarvest()
        if remotes.farmAction then
            log.info("Harvesting plot", plotId)
            remotes.farmAction:FireServer("harvest", plotId)
            
            -- Don't close the UI - let it update with new data
        end
    end
    
    -- Calculate timing and boosts (using real-time currentTime state)
    local nextCropTime = ""
    local activeBoosts = {}
    local effectiveGrowthTime = growthTime
    
    -- Calculate water cooldown and availability
    local waterCooldownRemaining = 0
    local canWater = true
    local waterCooldownText = ""
    local waterBlockReason = ""
    
    -- Check if plot needs more water
    if wateredCount >= waterNeeded then
        canWater = false
        waterBlockReason = "Fully watered"
    elseif lastWaterActionTime > 0 then
        local timeSinceLastWater = currentTime - lastWaterActionTime
        waterCooldownRemaining = waterCooldownSeconds - timeSinceLastWater
        
        if waterCooldownRemaining > 0 then
            canWater = false
            local minutes = math.floor(waterCooldownRemaining / 60)
            local seconds = math.floor(waterCooldownRemaining % 60)
            if minutes > 0 then
                waterCooldownText = string.format("%dm %ds", minutes, seconds)
            else
                waterCooldownText = string.format("%ds", seconds)
            end
            waterBlockReason = "Cooldown: " .. waterCooldownText
        end
    end
    
    -- Calculate active boosts
    if onlineBonus then
        table.insert(activeBoosts, "👤 Online (+faster)")
        effectiveGrowthTime = effectiveGrowthTime * 0.5 -- 2x speed when online
    end
    
    if weatherEffects.name then
        if weatherEffects.benefitsThisCrop then
            table.insert(activeBoosts, weatherEffects.emoji .. " " .. weatherEffects.name .. " (+20%)")
            effectiveGrowthTime = effectiveGrowthTime * (1 / weatherEffects.growthMultiplier)
        elseif weatherEffects.growthMultiplier ~= 1.0 then
            local effect = weatherEffects.growthMultiplier > 1.0 and "+" or ""
            local percent = math.floor((weatherEffects.growthMultiplier - 1.0) * 100)
            table.insert(activeBoosts, weatherEffects.emoji .. " " .. weatherEffects.name .. " (" .. effect .. percent .. "%)")
            effectiveGrowthTime = effectiveGrowthTime * (1 / weatherEffects.growthMultiplier)
        else
            table.insert(activeBoosts, weatherEffects.emoji .. " " .. weatherEffects.name)
        end
        
        if weatherEffects.autoWater then
            table.insert(activeBoosts, "🌧️ Auto-watering")
        end
    end
    
    if variation and variation ~= "normal" then
        table.insert(activeBoosts, "✨ " .. variation:gsub("^%l", string.upper) .. " variant")
    end
    
    -- Calculate production rate based on number of plants and multipliers
    local productionRate = 0
    local baseProductionPerHour = 0
    local totalProductionPerHour = 0
    local activePlants = maxHarvests - harvestCount
    local showNextReadyCountdown = false
    local showFinalHarvest = false
    
    -- Get base production rate from crop config (will need to fetch from server or store in plotData)
    -- For now, using approximate rates based on common crops
    local baseRates = {
        wheat = 12,
        carrot = 8,
        tomato = 6,
        potato = 10,
        corn = 4,
        banana = 2,
        strawberry = 3
    }
    
    if seedType and seedType ~= "" then
        baseProductionPerHour = baseRates[seedType] or 5 -- Default to 5/hour if not found
        
        -- Calculate total production: base rate × plants × multipliers
        totalProductionPerHour = baseProductionPerHour * activePlants
        
        -- Apply weather multiplier
        if weatherEffects.growthMultiplier then
            totalProductionPerHour = totalProductionPerHour * weatherEffects.growthMultiplier
        end
        
        -- Apply online bonus (2x speed)
        if onlineBonus then
            totalProductionPerHour = totalProductionPerHour * 2
        end
        
        productionRate = math.floor(totalProductionPerHour * 10) / 10 -- Round to 1 decimal
    end
    
    if state == "watered" and maxHarvests > harvestCount then
        -- Plants are growing, show when next crop will be ready
        local timeSinceWater = currentTime - lastWateredAt
        local timeRemaining = effectiveGrowthTime - timeSinceWater
        
        if timeRemaining > 0 then
            local minutes = math.floor(timeRemaining / 60)
            local seconds = math.floor(timeRemaining % 60)
            if minutes > 0 then
                nextCropTime = string.format("%dm %ds", minutes, seconds)
            else
                nextCropTime = string.format("%ds", seconds)
            end
            showNextReadyCountdown = true
        else
            nextCropTime = "Ready now!"
            showNextReadyCountdown = true
        end
    elseif state == "ready" and maxHarvests > harvestCount then
        -- Some crops ready, more still growing - show production rate but no timer
        nextCropTime = "" -- Don't show timer here to avoid duplication
        showNextReadyCountdown = false
    elseif state == "ready" and maxHarvests <= harvestCount then
        -- All plants consumed, only crops remain - time to harvest
        nextCropTime = ""
        showFinalHarvest = true
    elseif state == "planted" or state == "growing" then
        nextCropTime = "Needs water first"
        showNextReadyCountdown = false
    end
    
    -- Check if player has more of the current crop type for "Add More" functionality
    local currentCropCount = 0
    if seedType ~= "" then
        if playerData.inventory and playerData.inventory.seeds then
            currentCropCount = currentCropCount + (playerData.inventory.seeds[seedType] or 0)
        end
        if playerData.inventory and playerData.inventory.crops then
            currentCropCount = currentCropCount + (playerData.inventory.crops[seedType] or 0)
        end
    end
    local hasMoreOfCurrentCrop = currentCropCount > 0
    
    -- Create seed selection elements
    local seedSelectorElements = {}
    
    if state == "empty" and #availableSeeds > 0 then
        -- Create scrollable seed selector
        local seedElements = {}
        for i, seed in ipairs(availableSeeds) do
            -- Get count from both seeds and crops inventories
            local seedCount = 0
            if playerData.inventory and playerData.inventory.seeds then
                seedCount = seedCount + (playerData.inventory.seeds[seed] or 0)
            end
            if playerData.inventory and playerData.inventory.crops then
                seedCount = seedCount + (playerData.inventory.crops[seed] or 0)
            end
            seedElements["Seed" .. i] = e("TextButton", {
                Size = UDim2.new(1, -10, 0, 40),
                Position = UDim2.new(0, 5, 0, (i-1) * 45),
                BackgroundColor3 = selectedSeed == seed and Color3.fromRGB(80, 150, 80) or Color3.fromRGB(60, 55, 65),
                Text = seed:gsub("^%l", string.upper) .. " (" .. seedCount .. ")",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                Font = Enum.Font.SourceSans,
                [React.Event.Activated] = function()
                    setSelectedSeed(seed)
                    setShowSeedDropdown(false)
                end
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 6)
                })
            })
        end
        
        seedSelectorElements = {
            SeedDropdownButton = e("TextButton", {
                Size = UDim2.new(1, 0, 0, 50),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundColor3 = Color3.fromRGB(60, 55, 65),
                Text = "📦 Select Seed: " .. selectedSeed:gsub("^%l", string.upper),
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                Font = Enum.Font.SourceSans,
                [React.Event.Activated] = function()
                    setShowSeedDropdown(not showSeedDropdown)
                end
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 8)
                })
            }),
            
            SeedDropdownList = showSeedDropdown and e("ScrollingFrame", {
                Size = UDim2.new(1, 0, 0, math.min(200, #availableSeeds * 45)),
                Position = UDim2.new(0, 0, 0, 55),
                BackgroundColor3 = Color3.fromRGB(40, 35, 45),
                BackgroundTransparency = 0.1,
                BorderSizePixel = 0,
                ScrollBarThickness = 8,
                CanvasSize = UDim2.new(0, 0, 0, #availableSeeds * 45),
                ZIndex = 25
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 8)
                }),
                Seeds = e("Frame", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1
                }, seedElements)
            }) or nil
        }
    end

    return e("Frame", {
        Name = "PlotUI",
        Size = UDim2.new(0, panelWidth * scale, 0, panelHeight * scale),
        Position = UDim2.new(0.5, -panelWidth * scale / 2, 0.5, -panelHeight * scale / 2),
        BackgroundColor3 = Color3.fromRGB(25, 20, 30),
        BackgroundTransparency = visible and 0.05 or 1,
        BorderSizePixel = 0,
        Visible = visible,
        ZIndex = 20
    }, {
        Corner = e("UICorner", {
            CornerRadius = UDim.new(0, 12)
        }),
        Stroke = e("UIStroke", {
            Color = state == "ready" and Color3.fromRGB(255, 215, 0) or 
                   state == "dead" and Color3.fromRGB(255, 100, 100) or 
                   Color3.fromRGB(100, 200, 100),
            Thickness = 2,
            Transparency = 0.3
        }),
        
        -- Header
        Header = e("Frame", {
            Size = UDim2.new(1, 0, 0, 60),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(35, 30, 40),
            BorderSizePixel = 0
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 12)
            }),
            BottomCover = e("Frame", {
                Size = UDim2.new(1, 0, 0, 12),
                Position = UDim2.new(0, 0, 1, -12),
                BackgroundColor3 = Color3.fromRGB(35, 30, 40),
                BorderSizePixel = 0
            }),
            
            Title = e("TextLabel", {
                Size = UDim2.new(1, -100, 1, 0),
                Position = UDim2.new(0, 20, 0, 0),
                BackgroundTransparency = 1,
                Text = "🌱 Plot " .. (plotId or "") .. " Management",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                Font = Enum.Font.SourceSansBold,
                TextXAlignment = Enum.TextXAlignment.Left
            }),
            
            CloseButton = e("TextButton", {
                Size = UDim2.new(0, 40, 0, 40),
                Position = UDim2.new(1, -50, 0, 10),
                BackgroundColor3 = Color3.fromRGB(200, 50, 50),
                Text = "✕",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                Font = Enum.Font.SourceSansBold,
                [React.Event.Activated] = onClose
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 8)
                })
            })
        }),
        
        -- Main Content - Scrollable
        ContentScroll = e("ScrollingFrame", {
            Size = UDim2.new(1, -20, 1, -80),
            Position = UDim2.new(0, 10, 0, 70),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 6,
            CanvasSize = UDim2.new(0, 0, 0, 600), -- Will adjust based on content
            ZIndex = 21
        }, {
            ContentLayout = e("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                Padding = UDim.new(0, 15),
                SortOrder = Enum.SortOrder.LayoutOrder
            }),
            
            -- Status Section
            StatusSection = e("Frame", {
                Size = UDim2.new(1, 0, 0, 80),
                BackgroundColor3 = Color3.fromRGB(40, 35, 45),
                BackgroundTransparency = 0.3,
                BorderSizePixel = 0,
                LayoutOrder = 1
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 10)
                }),
                
                StatusTitle = e("TextLabel", {
                    Size = UDim2.new(1, -20, 0, 25),
                    Position = UDim2.new(0, 10, 0, 5),
                    BackgroundTransparency = 1,
                    Text = "📊 Current Status",
                    TextColor3 = Color3.fromRGB(200, 200, 200),
                    TextScaled = true,
                    Font = Enum.Font.SourceSansBold,
                    TextXAlignment = Enum.TextXAlignment.Left
                }),
                
                StatusLabel = e("TextLabel", {
                    Size = UDim2.new(1, -20, 0, 40),
                    Position = UDim2.new(0, 10, 0, 30),
                    BackgroundTransparency = 1,
                    Text = state == "empty" and "🌱 Empty Plot - Ready for planting!" or
                           state == "planted" and "🌱 " .. plantName .. " planted - " .. nextCropTime or
                           state == "growing" and "🌱 " .. plantName .. " planted - " .. nextCropTime or
                           state == "watered" and "🌿 " .. plantName .. " growing - Next: " .. nextCropTime or
                           state == "ready" and "🌟 " .. plantName .. " ready! (" .. accumulatedCrops .. " crops)" or
                           state == "dead" and "💀 " .. plantName .. " has died" or "Unknown state",
                    TextColor3 = state == "ready" and Color3.fromRGB(255, 215, 0) or 
                                state == "dead" and Color3.fromRGB(255, 100, 100) or 
                                state == "watered" and Color3.fromRGB(100, 255, 150) or
                                Color3.fromRGB(255, 255, 255),
                    TextScaled = true,
                    Font = Enum.Font.SourceSans,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
            }),
            
            -- Status & Timing Section (if not empty)
            StatusSection = state ~= "empty" and e("Frame", {
                Size = UDim2.new(1, 0, 0, 135),
                BackgroundColor3 = Color3.fromRGB(40, 35, 45),
                BackgroundTransparency = 0.3,
                BorderSizePixel = 0,
                LayoutOrder = 2
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 10)
                }),
                
                StatusTitle = e("TextLabel", {
                    Size = UDim2.new(1, -20, 0, 25),
                    Position = UDim2.new(0, 10, 0, 5),
                    BackgroundTransparency = 1,
                    Text = "📊 Plot Status & Timing",
                    TextColor3 = Color3.fromRGB(200, 200, 200),
                    TextScaled = true,
                    Font = Enum.Font.SourceSansBold,
                    TextXAlignment = Enum.TextXAlignment.Left
                }),
                
                StatusGrid = e("Frame", {
                    Size = UDim2.new(1, -20, 0, 100),
                    Position = UDim2.new(0, 10, 0, 30),
                    BackgroundTransparency = 1
                }, {
                    GridLayout = e("UIGridLayout", {
                        CellSize = UDim2.new(0.5, -5, 0, 18),
                        CellPadding = UDim2.new(0, 5, 0, 2),
                        SortOrder = Enum.SortOrder.LayoutOrder
                    }),
                    
                    -- Plant Count
                    PlantsInfo = e("TextLabel", {
                        BackgroundTransparency = 1,
                        Text = "🌱 Plants: " .. (maxHarvests - harvestCount) .. "/" .. maxHarvests,
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextScaled = true,
                        Font = Enum.Font.SourceSans,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        LayoutOrder = 1
                    }),
                    
                    -- Ready Crops (if any)
                    ReadyInfo = accumulatedCrops > 0 and e("TextLabel", {
                        BackgroundTransparency = 1,
                        Text = "🎁 Ready: " .. accumulatedCrops,
                        TextColor3 = Color3.fromRGB(255, 215, 0),
                        TextScaled = true,
                        Font = Enum.Font.SourceSansBold,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        LayoutOrder = 2
                    }) or nil,
                    
                    -- Water Status
                    WaterStatus = e("TextLabel", {
                        BackgroundTransparency = 1,
                        Text = "💧 Water: " .. wateredCount .. "/" .. waterNeeded,
                        TextColor3 = Color3.fromRGB(100, 200, 255),
                        TextScaled = true,
                        Font = Enum.Font.SourceSans,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        LayoutOrder = 3
                    }),
                    
                    -- Water Status/Cooldown (if can't water)
                    WaterStatus = not canWater and e("TextLabel", {
                        BackgroundTransparency = 1,
                        Text = waterCooldownRemaining > 0 and "⏳ Water in: " .. waterCooldownText or "✅ " .. waterBlockReason,
                        TextColor3 = waterCooldownRemaining > 0 and Color3.fromRGB(255, 150, 150) or Color3.fromRGB(150, 255, 150),
                        TextScaled = true,
                        Font = Enum.Font.SourceSansBold,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        LayoutOrder = 4
                    }) or nil,
                    
                    -- Next Crop Timer (if applicable)
                    NextCropTimer = showNextReadyCountdown and nextCropTime ~= "" and e("TextLabel", {
                        BackgroundTransparency = 1,
                        Text = nextCropTime == "Ready now!" and "⚡ Ready now!" or "⏰ Next in: " .. nextCropTime,
                        TextColor3 = nextCropTime == "Ready now!" and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 200, 100),
                        TextScaled = true,
                        Font = nextCropTime == "Ready now!" and Enum.Font.SourceSansBold or Enum.Font.SourceSans,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        LayoutOrder = 5
                    }) or nil,
                    
                    -- Production Rate (if producing)
                    ProductionRate = productionRate > 0 and activePlants > 0 and e("TextLabel", {
                        BackgroundTransparency = 1,
                        Text = (function()
                            local baseTotal = activePlants * baseProductionPerHour
                            local hasMultipliers = (weatherEffects.growthMultiplier and weatherEffects.growthMultiplier ~= 1.0) or onlineBonus
                            
                            if hasMultipliers then
                                return "📈 " .. activePlants .. " plants × " .. baseProductionPerHour .. "/h → " .. productionRate .. "/h"
                            else
                                return "📈 " .. activePlants .. " plants × " .. baseProductionPerHour .. "/h = " .. productionRate .. "/h"
                            end
                        end)(),
                        TextColor3 = Color3.fromRGB(150, 255, 150),
                        TextScaled = true,
                        Font = Enum.Font.SourceSans,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        LayoutOrder = 6
                    }) or nil
                })
            }) or nil,
            
            -- Active Boosts Section (if there are boosts)
            BoostsSection = #activeBoosts > 0 and e("Frame", {
                Size = UDim2.new(1, 0, 0, 40 + math.ceil(#activeBoosts / 2) * 25),
                BackgroundColor3 = Color3.fromRGB(50, 45, 55),
                BackgroundTransparency = 0.3,
                BorderSizePixel = 0,
                LayoutOrder = 2.5
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 10)
                }),
                
                BoostsTitle = e("TextLabel", {
                    Size = UDim2.new(1, -20, 0, 25),
                    Position = UDim2.new(0, 10, 0, 5),
                    BackgroundTransparency = 1,
                    Text = "⚡ Active Boosts",
                    TextColor3 = Color3.fromRGB(200, 200, 200),
                    TextScaled = true,
                    Font = Enum.Font.SourceSansBold,
                    TextXAlignment = Enum.TextXAlignment.Left
                }),
                
                BoostsGrid = e("Frame", {
                    Size = UDim2.new(1, -20, 0, math.ceil(#activeBoosts / 2) * 25),
                    Position = UDim2.new(0, 10, 0, 30),
                    BackgroundTransparency = 1
                }, (function()
                    local boostElements = {
                        GridLayout = e("UIGridLayout", {
                            CellSize = UDim2.new(0.5, -5, 0, 20),
                            CellPadding = UDim2.new(0, 5, 0, 2),
                            SortOrder = Enum.SortOrder.LayoutOrder
                        })
                    }
                    
                    for i, boost in ipairs(activeBoosts) do
                        boostElements["Boost" .. i] = e("TextLabel", {
                            BackgroundTransparency = 1,
                            Text = boost,
                            TextColor3 = Color3.fromRGB(150, 255, 150),
                            TextScaled = true,
                            Font = Enum.Font.SourceSans,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            LayoutOrder = i
                        })
                    end
                    
                    return boostElements
                end)())
            }) or nil,
            
            -- Seed Selection Section (for empty plots)
            SeedSection = state == "empty" and #availableSeeds > 0 and e("Frame", {
                Size = UDim2.new(1, 0, 0, showSeedDropdown and 280 or 110),
                BackgroundColor3 = Color3.fromRGB(40, 35, 45),
                BackgroundTransparency = 0.3,
                BorderSizePixel = 0,
                LayoutOrder = 3
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 10)
                }),
                
                SeedTitle = e("TextLabel", {
                    Size = UDim2.new(1, -20, 0, 25),
                    Position = UDim2.new(0, 10, 0, 5),
                    BackgroundTransparency = 1,
                    Text = "🌾 Select Seed to Plant",
                    TextColor3 = Color3.fromRGB(200, 200, 200),
                    TextScaled = true,
                    Font = Enum.Font.SourceSansBold,
                    TextXAlignment = Enum.TextXAlignment.Left
                }),
                
                SeedContent = e("Frame", {
                    Size = UDim2.new(1, -20, 0, showSeedDropdown and 240 or 70),
                    Position = UDim2.new(0, 10, 0, 35),
                    BackgroundTransparency = 1
                }, seedSelectorElements)
            }) or nil,
            
            -- Empty Plot Message (no seeds)
            EmptyMessage = state == "empty" and #availableSeeds == 0 and e("Frame", {
                Size = UDim2.new(1, 0, 0, 120),
                BackgroundColor3 = Color3.fromRGB(60, 50, 40),
                BackgroundTransparency = 0.3,
                BorderSizePixel = 0,
                LayoutOrder = 3
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 10)
                }),
                
                EmptyLabel = e("TextLabel", {
                    Size = UDim2.new(1, -20, 0, 50),
                    Position = UDim2.new(0, 10, 0, 10),
                    BackgroundTransparency = 1,
                    Text = "📦 No seeds available!\nYou need seeds to plant crops.",
                    TextColor3 = Color3.fromRGB(255, 200, 100),
                    TextScaled = true,
                    Font = Enum.Font.SourceSans,
                    TextXAlignment = Enum.TextXAlignment.Center
                }),
                
                ShopButton = e("TextButton", {
                    Size = UDim2.new(1, -20, 0, 40),
                    Position = UDim2.new(0, 10, 0, 70),
                    BackgroundColor3 = Color3.fromRGB(100, 150, 100),
                    Text = "🛒 Open Shop to Buy Seeds",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextScaled = true,
                    Font = Enum.Font.SourceSansBold,
                    [React.Event.Activated] = function()
                        onOpenShop()
                        onClose() -- Close the plot UI when opening shop
                    end
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 8)
                    })
                })
            }) or nil,
            
            -- Next Ready Countdown Section (when crops are growing and stacking)
            NextReadySection = showNextReadyCountdown and e("Frame", {
                Size = UDim2.new(1, 0, 0, 60),
                BackgroundColor3 = Color3.fromRGB(50, 60, 40),
                BackgroundTransparency = 0.3,
                BorderSizePixel = 0,
                LayoutOrder = 3.5
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 10)
                }),
                
                MessageLabel = e("TextLabel", {
                    Size = UDim2.new(1, -20, 1, -20),
                    Position = UDim2.new(0, 10, 0, 10),
                    BackgroundTransparency = 1,
                    Text = "🌱 Next ready: " .. nextCropTime .. " (+" .. (maxHarvests - harvestCount) .. " plants growing)",
                    TextColor3 = Color3.fromRGB(150, 255, 150),
                    TextScaled = true,
                    Font = Enum.Font.SourceSansBold,
                    TextXAlignment = Enum.TextXAlignment.Center
                })
            }) or nil,
            
            -- Final Harvest Section (when all plants are consumed, only crops remain)
            FinalHarvestSection = showFinalHarvest and e("Frame", {
                Size = UDim2.new(1, 0, 0, 60),
                BackgroundColor3 = Color3.fromRGB(60, 50, 40),
                BackgroundTransparency = 0.3,
                BorderSizePixel = 0,
                LayoutOrder = 3.5
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 10)
                }),
                
                MessageLabel = e("TextLabel", {
                    Size = UDim2.new(1, -20, 1, -20),
                    Position = UDim2.new(0, 10, 0, 10),
                    BackgroundTransparency = 1,
                    Text = "🎁 All plants harvested! " .. accumulatedCrops .. " crops ready to collect!",
                    TextColor3 = Color3.fromRGB(255, 215, 0),
                    TextScaled = true,
                    Font = Enum.Font.SourceSansBold,
                    TextXAlignment = Enum.TextXAlignment.Center
                })
            }) or nil,
            
            -- Action Buttons Section
            ActionsSection = e("Frame", {
                Size = UDim2.new(1, 0, 0, 200),
                BackgroundTransparency = 1,
                LayoutOrder = 4
            }, {
                ButtonLayout = e("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    Padding = UDim.new(0, 10),
                    SortOrder = Enum.SortOrder.LayoutOrder
                }),
                
                -- Plant Button (for empty plots)
                PlantButton = (state == "empty" and #availableSeeds > 0) and e("TextButton", {
                    Size = UDim2.new(1, 0, 0, 45),
                    BackgroundColor3 = Color3.fromRGB(100, 200, 100),
                    Text = "🌱 Plant " .. selectedSeed:gsub("^%l", string.upper),
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextScaled = true,
                    Font = Enum.Font.SourceSansBold,
                    LayoutOrder = 1,
                    [React.Event.Activated] = function() handlePlant(1) end
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 8)
                    })
                }) or nil,
                
                -- Plant More Options (for existing crops) - only if player has more
                PlantMoreSection = (state ~= "empty" and state ~= "dead" and maxHarvests - harvestCount < 50 and hasMoreOfCurrentCrop) and e("Frame", {
                    Size = UDim2.new(1, 0, 0, 100),
                    BackgroundTransparency = 1,
                    LayoutOrder = 1
                }, {
                    SectionLayout = e("UIListLayout", {
                        FillDirection = Enum.FillDirection.Vertical,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        Padding = UDim.new(0, 5),
                        SortOrder = Enum.SortOrder.LayoutOrder
                    }),
                    
                    SectionTitle = e("TextLabel", {
                        Size = UDim2.new(1, 0, 0, 20),
                        BackgroundTransparency = 1,
                        Text = "🌱 Plant More " .. plantName .. " (" .. currentCropCount .. " available)",
                        TextColor3 = Color3.fromRGB(200, 200, 200),
                        TextScaled = true,
                        Font = Enum.Font.SourceSansBold,
                        LayoutOrder = 1
                    }),
                    
                    ButtonsGrid = e("Frame", {
                        Size = UDim2.new(1, 0, 0, 70),
                        BackgroundTransparency = 1,
                        LayoutOrder = 2
                    }, {
                        GridLayout = e("UIGridLayout", {
                            CellSize = UDim2.new(0.32, -5, 0, 30),
                            CellPadding = UDim2.new(0, 5, 0, 5),
                            SortOrder = Enum.SortOrder.LayoutOrder
                        }),
                        
                        Plant1Button = e("TextButton", {
                            BackgroundColor3 = Color3.fromRGB(150, 180, 100),
                            Text = "+1",
                            TextColor3 = Color3.fromRGB(255, 255, 255),
                            TextScaled = true,
                            Font = Enum.Font.SourceSansBold,
                            LayoutOrder = 1,
                            [React.Event.Activated] = function() handlePlant(1) end
                        }, {
                            Corner = e("UICorner", {
                                CornerRadius = UDim.new(0, 6)
                            })
                        }),
                        
                        Plant5Button = currentCropCount >= 5 and e("TextButton", {
                            BackgroundColor3 = Color3.fromRGB(140, 170, 90),
                            Text = "+5",
                            TextColor3 = Color3.fromRGB(255, 255, 255),
                            TextScaled = true,
                            Font = Enum.Font.SourceSansBold,
                            LayoutOrder = 2,
                            [React.Event.Activated] = function() handlePlant(5) end
                        }, {
                            Corner = e("UICorner", {
                                CornerRadius = UDim.new(0, 6)
                            })
                        }) or nil,
                        
                        Plant10Button = currentCropCount >= 10 and e("TextButton", {
                            BackgroundColor3 = Color3.fromRGB(130, 160, 80),
                            Text = "+10",
                            TextColor3 = Color3.fromRGB(255, 255, 255),
                            TextScaled = true,
                            Font = Enum.Font.SourceSansBold,
                            LayoutOrder = 3,
                            [React.Event.Activated] = function() handlePlant(10) end
                        }, {
                            Corner = e("UICorner", {
                                CornerRadius = UDim.new(0, 6)
                            })
                        }) or nil
                    })
                }) or nil,
                
                -- No More Crops Message (when they want to plant more but don't have any)
                NoMoreCropsMessage = (state ~= "empty" and state ~= "dead" and maxHarvests - harvestCount < 50 and not hasMoreOfCurrentCrop) and e("Frame", {
                    Size = UDim2.new(1, 0, 0, 80),
                    BackgroundColor3 = Color3.fromRGB(60, 50, 40),
                    BackgroundTransparency = 0.3,
                    BorderSizePixel = 0,
                    LayoutOrder = 1
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 8)
                    }),
                    
                    MessageLabel = e("TextLabel", {
                        Size = UDim2.new(1, -20, 0, 35),
                        Position = UDim2.new(0, 10, 0, 5),
                        BackgroundTransparency = 1,
                        Text = "📦 No more " .. plantName .. " to plant!",
                        TextColor3 = Color3.fromRGB(255, 200, 100),
                        TextScaled = true,
                        Font = Enum.Font.SourceSans,
                        TextXAlignment = Enum.TextXAlignment.Center
                    }),
                    
                    ShopSuggestion = e("TextButton", {
                        Size = UDim2.new(1, -20, 0, 30),
                        Position = UDim2.new(0, 10, 0, 45),
                        BackgroundColor3 = Color3.fromRGB(100, 150, 100),
                        Text = "🛒 Buy More " .. plantName,
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextScaled = true,
                        Font = Enum.Font.SourceSansBold,
                        [React.Event.Activated] = function()
                            onOpenShop()
                            onClose()
                        end
                    }, {
                        Corner = e("UICorner", {
                            CornerRadius = UDim.new(0, 6)
                        })
                    })
                }) or nil,
                
                -- Water Button
                WaterButton = (state == "planted" or state == "growing") and e("TextButton", {
                    Size = UDim2.new(1, 0, 0, 45),
                    BackgroundColor3 = canWater and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(80, 80, 80),
                    Text = canWater and "💧 Water Crops" or "💧 " .. (waterCooldownRemaining > 0 and "On Cooldown" or "Fully Watered"),
                    TextColor3 = canWater and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 160, 160),
                    TextScaled = true,
                    Font = Enum.Font.SourceSansBold,
                    LayoutOrder = 2,
                    Active = canWater,
                    AutoButtonColor = canWater,
                    [React.Event.Activated] = canWater and handleWater or nil
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 8)
                    })
                }) or nil,
                
                -- Harvest Button
                HarvestButton = state == "ready" and e("TextButton", {
                    Size = UDim2.new(1, 0, 0, 45),
                    BackgroundColor3 = Color3.fromRGB(255, 215, 0),
                    Text = "🎁 Harvest " .. accumulatedCrops .. " " .. plantName,
                    TextColor3 = Color3.fromRGB(50, 50, 50),
                    TextScaled = true,
                    Font = Enum.Font.SourceSansBold,
                    LayoutOrder = 1,
                    [React.Event.Activated] = handleHarvest
                }, {
                    Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 8)
                    })
                }) or nil,
                
                -- Remove Button or Confirmation
                RemoveSection = (state ~= "empty") and e("Frame", {
                    Size = UDim2.new(1, 0, 0, showRemoveConfirmation and 80 or 40),
                    BackgroundTransparency = 1,
                    LayoutOrder = 5
                }, {
                    RemoveLayout = e("UIListLayout", {
                        FillDirection = Enum.FillDirection.Vertical,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        Padding = UDim.new(0, 5),
                        SortOrder = Enum.SortOrder.LayoutOrder
                    }),
                    
                    -- Initial Remove Button (if not confirming)
                    RemoveButton = not showRemoveConfirmation and e("TextButton", {
                        Size = UDim2.new(1, 0, 0, 40),
                        BackgroundColor3 = Color3.fromRGB(200, 50, 50),
                        Text = state == "dead" and "🗑️ Clear Dead Crop" or "❌ Remove " .. plantName,
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextScaled = true,
                        Font = Enum.Font.SourceSansBold,
                        LayoutOrder = 1,
                        [React.Event.Activated] = state == "dead" and handleRemove or handleRemoveRequest
                    }, {
                        Corner = e("UICorner", {
                            CornerRadius = UDim.new(0, 8)
                        })
                    }) or nil,
                    
                    -- Confirmation Text (if confirming)
                    ConfirmationText = showRemoveConfirmation and e("TextLabel", {
                        Size = UDim2.new(1, 0, 0, 30),
                        BackgroundTransparency = 1,
                        Text = "⚠️ Remove all plants? No rewards!",
                        TextColor3 = Color3.fromRGB(255, 200, 100),
                        TextScaled = true,
                        Font = Enum.Font.SourceSansBold,
                        LayoutOrder = 1
                    }) or nil,
                    
                    -- Confirmation Buttons (if confirming)
                    ConfirmationButtons = showRemoveConfirmation and e("Frame", {
                        Size = UDim2.new(1, 0, 0, 40),
                        BackgroundTransparency = 1,
                        LayoutOrder = 2
                    }, {
                        ButtonLayout = e("UIListLayout", {
                            FillDirection = Enum.FillDirection.Horizontal,
                            HorizontalAlignment = Enum.HorizontalAlignment.Center,
                            Padding = UDim.new(0, 10),
                            SortOrder = Enum.SortOrder.LayoutOrder
                        }),
                        
                        CancelButton = e("TextButton", {
                            Size = UDim2.new(0.45, 0, 1, 0),
                            BackgroundColor3 = Color3.fromRGB(100, 100, 100),
                            Text = "Cancel",
                            TextColor3 = Color3.fromRGB(255, 255, 255),
                            TextScaled = true,
                            Font = Enum.Font.SourceSansBold,
                            LayoutOrder = 1,
                            [React.Event.Activated] = handleCancelRemove
                        }, {
                            Corner = e("UICorner", {
                                CornerRadius = UDim.new(0, 6)
                            })
                        }),
                        
                        ConfirmButton = e("TextButton", {
                            Size = UDim2.new(0.45, 0, 1, 0),
                            BackgroundColor3 = Color3.fromRGB(200, 50, 50),
                            Text = "Remove All",
                            TextColor3 = Color3.fromRGB(255, 255, 255),
                            TextScaled = true,
                            Font = Enum.Font.SourceSansBold,
                            LayoutOrder = 2,
                            [React.Event.Activated] = handleRemove
                        }, {
                            Corner = e("UICorner", {
                                CornerRadius = UDim.new(0, 6)
                            })
                        })
                    }) or nil
                }) or nil
            })
        })
    })
end

return PlotUI