-- World builder for creating physical farm plots
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Logger = require(script.Parent.modules.Logger)

local WorldBuilder = {}

-- Get module logger
local log = Logger.getModuleLogger("WorldBuilder")

-- Farm plot configuration
local PLOT_SIZE = Vector3.new(8, 1, 8)
local PLOT_SPACING = 4 -- Increased spacing for multiplayer visibility
local TOTAL_PLOTS = 6 -- 6 plots in a line for multiplayer

-- Create physical farm plot
local function createFarmPlot(position, plotId)
    -- Main plot base
    local plot = Instance.new("Part")
    plot.Name = "FarmPlot_" .. plotId
    plot.Size = PLOT_SIZE
    plot.Position = position
    plot.Anchored = true
    plot.Material = Enum.Material.Ground
    plot.BrickColor = BrickColor.new("CGA brown") -- Brown dirt
    plot.Shape = Enum.PartType.Block
    plot.TopSurface = Enum.SurfaceType.Smooth
    plot.Parent = Workspace
    
    -- Plot border (slightly raised)
    local border = Instance.new("Part")
    border.Name = "Border"
    border.Size = Vector3.new(PLOT_SIZE.X + 0.4, 0.2, PLOT_SIZE.Z + 0.4)
    border.Position = position + Vector3.new(0, 0.1, 0)
    border.Anchored = true
    border.Material = Enum.Material.Wood
    border.BrickColor = BrickColor.new("Dark orange")
    border.Shape = Enum.PartType.Block
    border.Parent = plot
    
    -- Create invisible plant position marker (no visual part)
    local plantPosition = Instance.new("Part")
    plantPosition.Name = "PlantPosition"
    plantPosition.Size = Vector3.new(0.1, 0.1, 0.1)
    plantPosition.Position = position + Vector3.new(0, 0.55, 0)
    plantPosition.Anchored = true
    plantPosition.Transparency = 1 -- Completely invisible
    plantPosition.CanCollide = false
    plantPosition.Parent = plot
    
    -- Add single context-sensitive ProximityPrompt
    local actionPrompt = Instance.new("ProximityPrompt")
    actionPrompt.Name = "ActionPrompt"
    actionPrompt.ActionText = "Plant Seed" -- Default action
    actionPrompt.KeyboardKeyCode = Enum.KeyCode.E -- Single key for all actions
    actionPrompt.RequiresLineOfSight = false
    actionPrompt.MaxActivationDistance = 6
    actionPrompt.Parent = plot
    
    -- Store plot data
    local plotData = Instance.new("StringValue")
    plotData.Name = "PlotData"
    plotData.Value = "empty" -- empty, planted, watered, ready
    plotData.Parent = plot
    
    local plotIdValue = Instance.new("IntValue")
    plotIdValue.Name = "PlotId"
    plotIdValue.Value = plotId
    plotIdValue.Parent = plot
    
    local seedTypeValue = Instance.new("StringValue")
    seedTypeValue.Name = "SeedType"
    seedTypeValue.Value = ""
    seedTypeValue.Parent = plot
    
    local plantedTimeValue = Instance.new("NumberValue")
    plantedTimeValue.Name = "PlantedTime"
    plantedTimeValue.Value = 0
    plantedTimeValue.Parent = plot
    
    local wateredTimeValue = Instance.new("NumberValue")
    wateredTimeValue.Name = "WateredTime"
    wateredTimeValue.Value = 0
    wateredTimeValue.Parent = plot
    
    -- Create countdown display above plot
    local countdownGui = Instance.new("BillboardGui")
    countdownGui.Name = "CountdownDisplay"
    countdownGui.Size = UDim2.new(0, 100, 0, 50)
    countdownGui.StudsOffset = Vector3.new(0, 3, 0)
    countdownGui.LightInfluence = 0
    countdownGui.Parent = plot
    
    local countdownLabel = Instance.new("TextLabel")
    countdownLabel.Size = UDim2.new(1, 0, 1, 0)
    countdownLabel.BackgroundTransparency = 1
    countdownLabel.Text = ""
    countdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    countdownLabel.TextScaled = true
    countdownLabel.Font = Enum.Font.SourceSansBold
    countdownLabel.TextStrokeTransparency = 0
    countdownLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    countdownLabel.Parent = countdownGui
    
    return plot
end

-- Create a 3D plant model with variation support
function WorldBuilder.createPlant(plot, seedType, growthStage, variation)
    variation = variation or "normal"
    log.trace("createPlant called - seedType:", seedType, "growthStage:", growthStage, "variation:", variation)
    
    -- Remove existing plant if any
    local existingPlant = plot:FindFirstChild("Plant")
    if existingPlant then
        log.trace("Removing existing plant")
        existingPlant:Destroy()
    end
    
    if growthStage == 0 then
        log.trace("GrowthStage is 0, not creating plant")
        return -- No plant to show yet
    end
    
    -- Plant colors by type (using BrickColor names)
    local plantColors = {
        tomato = "Bright red",
        carrot = "Bright orange", 
        wheat = "Bright yellow",
        potato = "CGA brown",
        corn = "Bright yellow"
    }
    
    -- Growth stage sizes
    local sizes = {
        [1] = Vector3.new(0.5, 0.5, 0.5), -- Just planted
        [2] = Vector3.new(1, 2, 1),       -- Growing
        [3] = Vector3.new(1.5, 3, 1.5)    -- Full grown
    }
    
    local plant = Instance.new("Part")
    plant.Name = "Plant"
    plant.Size = sizes[growthStage] or sizes[1]
    plant.Shape = Enum.PartType.Cylinder
    plant.Material = Enum.Material.Neon
    
    -- Apply variation coloring
    if variation == "normal" then
        plant.BrickColor = BrickColor.new(plantColors[seedType] or "Bright green")
    elseif variation == "shiny" then
        plant.BrickColor = BrickColor.new("Bright yellow")
        plant.Material = Enum.Material.ForceField
    elseif variation == "rainbow" then
        plant.BrickColor = BrickColor.new("Magenta")
        plant.Material = Enum.Material.ForceField
    elseif variation == "golden" then
        plant.BrickColor = BrickColor.new("Bright yellow")
        plant.Material = Enum.Material.Gold
    elseif variation == "diamond" then
        plant.BrickColor = BrickColor.new("Institutional white")
        plant.Material = Enum.Material.Diamond
    elseif variation == "dead" then
        plant.BrickColor = BrickColor.new("Really black")
        plant.Material = Enum.Material.Concrete
        plant.Transparency = 0.3  -- Make it slightly transparent/withered
    end
    
    plant.Anchored = true
    plant.CanCollide = false
    plant.TopSurface = Enum.SurfaceType.Smooth
    plant.BottomSurface = Enum.SurfaceType.Smooth
    
    -- Position above the plot
    local plotPosition = plot.Position
    plant.Position = plotPosition + Vector3.new(0, plot.Size.Y/2 + plant.Size.Y/2, 0)
    plant.Orientation = Vector3.new(0, 0, 90) -- Rotate cylinder to be vertical
    plant.Parent = plot
    
    log.debug("Plant created successfully! Size:", plant.Size, "Position:", plant.Position, "Color:", plant.BrickColor.Name)
    
    -- Add special effects for rare variations
    if variation ~= "normal" then
        WorldBuilder.addVariationEffects(plant, variation)
    end
    
    -- Add growth animation
    if growthStage > 1 then
        local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
        local tween = game:GetService("TweenService"):Create(plant, tweenInfo, {
            Size = plant.Size
        })
        
        -- Start small and grow
        plant.Size = Vector3.new(0.1, 0.1, 0.1)
        tween:Play()
    end
    
    return plant
end

-- Add special effects for crop variations
function WorldBuilder.addVariationEffects(plant, variation)
    local attachment = Instance.new("Attachment")
    attachment.Name = "VariationAttachment"
    attachment.Position = Vector3.new(0, plant.Size.Y/2, 0)
    attachment.Parent = plant
    
    if variation == "shiny" then
        local particles = Instance.new("ParticleEmitter")
        particles.Name = "ShinyParticles"
        particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        particles.Lifetime = NumberRange.new(0.5, 1.0)
        particles.Rate = 15
        particles.SpreadAngle = Vector2.new(45, 45)
        particles.Speed = NumberRange.new(1, 3)
        particles.Color = ColorSequence.new(Color3.fromRGB(255, 255, 150))
        particles.Size = NumberSequence.new(0.1)
        particles.Parent = attachment
        
    elseif variation == "rainbow" then
        local particles = Instance.new("ParticleEmitter")
        particles.Name = "RainbowParticles"
        particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        particles.Lifetime = NumberRange.new(0.8, 1.5)
        particles.Rate = 25
        particles.SpreadAngle = Vector2.new(45, 45)
        particles.Speed = NumberRange.new(2, 4)
        particles.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 255))
        }
        particles.Size = NumberSequence.new(0.15)
        particles.Parent = attachment
        
        -- Rainbow color cycling for plant
        spawn(function()
            while plant.Parent do
                for hue = 0, 1, 0.01 do
                    if not plant.Parent then break end
                    plant.Color = Color3.fromHSV(hue, 1, 1)
                    wait(0.1)
                end
            end
        end)
        
    elseif variation == "golden" then
        local particles = Instance.new("ParticleEmitter")
        particles.Name = "GoldenParticles"
        particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        particles.Lifetime = NumberRange.new(1.0, 2.0)
        particles.Rate = 30
        particles.SpreadAngle = Vector2.new(60, 60)
        particles.Speed = NumberRange.new(3, 6)
        particles.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
        particles.Size = NumberSequence.new(0.2)
        particles.Parent = attachment
        
        -- Golden glow effect
        local pointLight = Instance.new("PointLight")
        pointLight.Color = Color3.fromRGB(255, 215, 0)
        pointLight.Brightness = 2
        pointLight.Range = 10
        pointLight.Parent = plant
        
    elseif variation == "diamond" then
        local particles = Instance.new("ParticleEmitter")
        particles.Name = "DiamondParticles"
        particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        particles.Lifetime = NumberRange.new(1.5, 2.5)
        particles.Rate = 50
        particles.SpreadAngle = Vector2.new(90, 90)
        particles.Speed = NumberRange.new(4, 8)
        particles.Color = ColorSequence.new(Color3.fromRGB(185, 242, 255))
        particles.Size = NumberSequence.new(0.3)
        particles.Parent = attachment
        
        -- Diamond sparkle effect
        local pointLight = Instance.new("PointLight")
        pointLight.Color = Color3.fromRGB(185, 242, 255)
        pointLight.Brightness = 3
        pointLight.Range = 15
        pointLight.Parent = plant
        
        -- Sparkling effect
        spawn(function()
            while plant.Parent do
                plant.Transparency = 0
                wait(0.1)
                plant.Transparency = 0.3
                wait(0.1)
            end
        end)
    end
end

-- Update plot visual state with variation support
function WorldBuilder.updatePlotState(plot, state, seedType, variation, waterProgress)
    variation = variation or "normal"
    waterProgress = waterProgress or {current = 0, needed = 1}
    
    local plotData = plot:FindFirstChild("PlotData")
    local actionPrompt = plot:FindFirstChild("ActionPrompt")
    local plantPosition = plot:FindFirstChild("PlantPosition")
    
    if not plotData or not actionPrompt then return end
    
    plotData.Value = state
    
    if state == "empty" then
        -- Dry brown dirt
        plot.BrickColor = BrickColor.new("CGA brown")
        if plantPosition then
            plantPosition.BrickColor = BrickColor.new("CGA brown")
        end
        
        -- Set prompt for planting
        actionPrompt.ActionText = "Plant Seed"
        actionPrompt.Enabled = true
        
        -- Remove any existing plant
        local existingPlant = plot:FindFirstChild("Plant")
        if existingPlant then
            existingPlant:Destroy()
        end
        
    elseif state == "planted" then
        -- Show small plant with variation
        WorldBuilder.createPlant(plot, seedType, 1, variation)
        
        -- Set prompt for watering
        local waterText = "Water Plant"
        if waterProgress and waterProgress.needed > 1 then
            waterText = "Water Plant (" .. waterProgress.current .. "/" .. waterProgress.needed .. ")"
        end
        actionPrompt.ActionText = waterText
        actionPrompt.Enabled = true
        
    elseif state == "growing" then
        -- Show partially grown plant (needs more water) with variation
        WorldBuilder.createPlant(plot, seedType, 1, variation)
        
        -- Set prompt for additional watering
        local waterText = "Water Plant"
        if waterProgress and waterProgress.needed > 1 then
            waterText = "Water Plant (" .. waterProgress.current .. "/" .. waterProgress.needed .. ")"
        end
        actionPrompt.ActionText = waterText
        actionPrompt.Enabled = true
        
    elseif state == "watered" then
        -- Darker, moist dirt
        plot.BrickColor = BrickColor.new("Brown")
        if plantPosition then
            plantPosition.BrickColor = BrickColor.new("Brown")
        end
        
        -- Show growing plant with variation
        WorldBuilder.createPlant(plot, seedType, 2, variation)
        
        -- Plant is growing, no action needed
        actionPrompt.ActionText = "Growing..."
        actionPrompt.Enabled = false
        
    elseif state == "ready" then
        -- Show full grown plant with variation
        local plant = WorldBuilder.createPlant(plot, seedType, 3, variation)
        
        -- Add harvest ready particles (in addition to variation effects)
        if plant then
            local attachment = plant:FindFirstChild("VariationAttachment")
            if not attachment then
                attachment = Instance.new("Attachment")
                attachment.Name = "VariationAttachment"
                attachment.Position = Vector3.new(0, plant.Size.Y/2, 0)
                attachment.Parent = plant
            end
            
            local readyParticles = Instance.new("ParticleEmitter")
            readyParticles.Name = "ReadyParticles"
            readyParticles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
            readyParticles.Lifetime = NumberRange.new(0.5, 1.0)
            readyParticles.Rate = 20
            readyParticles.SpreadAngle = Vector2.new(45, 45)
            readyParticles.Speed = NumberRange.new(2, 4)
            readyParticles.Color = ColorSequence.new(Color3.fromRGB(255, 255, 100)) -- Golden sparkles
            readyParticles.Size = NumberSequence.new(0.1)
            readyParticles.Parent = attachment
            
            log.debug("Added harvest ready particles to " .. variation .. " " .. seedType .. " crop!")
        end
        
        -- Set prompt for harvesting
        actionPrompt.ActionText = "Harvest " .. (seedType or "Crop")
        actionPrompt.Enabled = true
        
    elseif state == "dead" then
        -- Show withered/dead plant
        local plant = WorldBuilder.createPlant(plot, seedType, 1, "dead") -- Use special "dead" variation
        
        -- Change plot to dark/withered appearance
        plot.BrickColor = BrickColor.new("Really black")
        if plantPosition then
            plantPosition.BrickColor = BrickColor.new("Really black")
        end
        
        -- Set prompt for clearing
        actionPrompt.ActionText = "Clear Dead Plant"
        actionPrompt.Enabled = true
    end
end

-- Build the entire farm world with individual player farm areas
function WorldBuilder.buildFarm()
    log.info("Building individual player farm areas...")
    
    -- Get farm configuration from FarmManager
    local FarmManager = require(script.Parent.modules.FarmManager)
    local config = FarmManager.getFarmConfig()
    
    -- Clear existing farms if any
    local existingFarms = Workspace:FindFirstChild("PlayerFarms")
    if existingFarms then
        existingFarms:Destroy()
    end
    
    -- Create main container for all player farms
    local farmsContainer = Instance.new("Folder")
    farmsContainer.Name = "PlayerFarms"
    farmsContainer.Parent = Workspace
    
    -- Remove any existing spawn locations first
    for _, obj in pairs(Workspace:GetChildren()) do
        if obj:IsA("SpawnLocation") then
            obj:Destroy()
        end
    end
    
    -- No central spawn - each farm will have its own spawn location
    
    -- Create individual farm areas
    local totalPlotsCreated = 0
    for farmId = 1, config.totalFarms do
        local farmFolder = WorldBuilder.createIndividualFarm(farmId, config)
        farmFolder.Parent = farmsContainer
        totalPlotsCreated = totalPlotsCreated + config.plotsPerFarm
    end
    
    log.info("Built", config.totalFarms, "individual farms with", totalPlotsCreated, "total plots!")
    return farmsContainer
end

-- Create an individual farm area for a player
function WorldBuilder.createIndividualFarm(farmId, config)
    local FarmManager = require(script.Parent.modules.FarmManager)
    local farmPosition = FarmManager.getFarmPosition(farmId)
    
    -- Create farm folder
    local farmFolder = Instance.new("Folder")
    farmFolder.Name = "Farm_" .. farmId
    
    -- Create farm base/ground
    local farmBase = Instance.new("Part")
    farmBase.Name = "FarmBase"
    farmBase.Size = config.farmSize
    farmBase.Position = farmPosition
    farmBase.Anchored = true
    farmBase.Material = Enum.Material.Grass
    farmBase.BrickColor = BrickColor.new("Bright green")
    farmBase.Shape = Enum.PartType.Block
    farmBase.TopSurface = Enum.SurfaceType.Smooth
    farmBase.Parent = farmFolder
    
    -- Create farm spawn location (in front of the farm)
    local spawnLocation = Instance.new("SpawnLocation")
    spawnLocation.Name = "FarmSpawn_" .. farmId
    spawnLocation.Size = Vector3.new(8, 1, 8)
    -- Position spawn in front of the farm (negative Z direction)
    spawnLocation.Position = farmPosition + Vector3.new(0, 1, -config.farmSize.Z/2 - 6)
    spawnLocation.Anchored = true
    spawnLocation.Material = Enum.Material.Concrete
    spawnLocation.BrickColor = BrickColor.new("Medium stone grey")
    spawnLocation.Transparency = 0.5
    spawnLocation.Enabled = false -- Disabled by default, enabled when player assigned
    spawnLocation.Parent = farmFolder
    
    -- Add a spawn platform visual
    local spawnPlatform = Instance.new("Part")
    spawnPlatform.Name = "SpawnPlatform"
    spawnPlatform.Size = Vector3.new(10, 0.5, 10)
    spawnPlatform.Position = spawnLocation.Position - Vector3.new(0, 0.25, 0)
    spawnPlatform.Anchored = true
    spawnPlatform.Material = Enum.Material.WoodPlanks
    spawnPlatform.BrickColor = BrickColor.new("CGA brown")
    spawnPlatform.Parent = farmFolder
    
    -- Add welcome sign at spawn
    local signPost = Instance.new("Part")
    signPost.Name = "WelcomeSignPost"
    signPost.Size = Vector3.new(0.5, 4, 0.5)
    signPost.Position = spawnLocation.Position + Vector3.new(4, 2, 0)
    signPost.Anchored = true
    signPost.Material = Enum.Material.Wood
    signPost.BrickColor = BrickColor.new("CGA brown")
    signPost.Shape = Enum.PartType.Cylinder
    signPost.Parent = farmFolder
    
    local signBoard = Instance.new("Part")
    signBoard.Name = "WelcomeSignBoard"
    signBoard.Size = Vector3.new(4, 2, 0.2)
    signBoard.Position = signPost.Position + Vector3.new(-2, 1.5, 0)
    signBoard.Anchored = true
    signBoard.Material = Enum.Material.Wood
    signBoard.BrickColor = BrickColor.new("Pine Cone")
    signBoard.Parent = farmFolder
    
    local signGui = Instance.new("SurfaceGui")
    signGui.Face = Enum.NormalId.Front
    signGui.Parent = signBoard
    
    local signText = Instance.new("TextLabel")
    signText.Size = UDim2.new(1, 0, 1, 0)
    signText.BackgroundTransparency = 1
    signText.Text = "🌾 Welcome! 🌾\nFarm #" .. farmId .. "\nPress E to interact"
    signText.TextScaled = true
    signText.TextColor3 = Color3.fromRGB(255, 255, 255)
    signText.Font = Enum.Font.Cartoon
    signText.Parent = signGui
    
    -- Create farm boundary walls
    WorldBuilder.createFarmBoundary(farmFolder, farmPosition, config.farmSize)
    
    -- Create farm sign
    WorldBuilder.createFarmSign(farmFolder, farmPosition, farmId)
    
    -- Create plots in a 3x3 grid within the farm
    local globalPlotId = (farmId - 1) * config.plotsPerFarm + 1
    for row = 1, 3 do
        for col = 1, 3 do
            local plotIndex = (row - 1) * 3 + col
            local plotOffsetX = (col - 2) * (PLOT_SIZE.X + PLOT_SPACING) -- Center the grid
            local plotOffsetZ = (row - 2) * (PLOT_SIZE.Z + PLOT_SPACING)
            local plotPosition = farmPosition + Vector3.new(plotOffsetX, PLOT_SIZE.Y / 2, plotOffsetZ)
            
            local plot = createFarmPlot(plotPosition, globalPlotId)
            plot.Parent = farmFolder
            
            globalPlotId = globalPlotId + 1
        end
    end
    
    log.debug("Created farm", farmId, "at position", farmPosition, "with", config.plotsPerFarm, "plots")
    return farmFolder
end

-- Create boundary walls around a farm
function WorldBuilder.createFarmBoundary(farmFolder, farmPosition, farmSize)
    local wallHeight = 3
    local wallThickness = 1
    
    -- Create 4 walls around the farm perimeter
    local walls = {
        {name = "NorthWall", size = Vector3.new(farmSize.X, wallHeight, wallThickness), offset = Vector3.new(0, wallHeight/2, farmSize.Z/2)},
        {name = "SouthWall", size = Vector3.new(farmSize.X, wallHeight, wallThickness), offset = Vector3.new(0, wallHeight/2, -farmSize.Z/2)},
        {name = "EastWall", size = Vector3.new(wallThickness, wallHeight, farmSize.Z), offset = Vector3.new(farmSize.X/2, wallHeight/2, 0)},
        {name = "WestWall", size = Vector3.new(wallThickness, wallHeight, farmSize.Z), offset = Vector3.new(-farmSize.X/2, wallHeight/2, 0)}
    }
    
    for _, wallData in ipairs(walls) do
        local wall = Instance.new("Part")
        wall.Name = wallData.name
        wall.Size = wallData.size
        wall.Position = farmPosition + wallData.offset
        wall.Anchored = true
        wall.Material = Enum.Material.Brick
        wall.BrickColor = BrickColor.new("Brown")
        wall.Parent = farmFolder
    end
end

-- Create a sign for the farm with character display capability (simplified - no visual clutter)
function WorldBuilder.createFarmSign(farmFolder, farmPosition, farmId)
    -- Create invisible character display area (no platform or wooden sign clutter)
    local characterDisplay = Instance.new("Part")
    characterDisplay.Name = "CharacterDisplay"
    characterDisplay.Size = Vector3.new(15, 20, 5) -- Big display area for character
    characterDisplay.Position = farmPosition + Vector3.new(0, 45, 0) -- High above farm, centered
    characterDisplay.Anchored = true
    characterDisplay.Transparency = 1 -- Completely invisible
    characterDisplay.CanCollide = false
    characterDisplay.Parent = farmFolder
    
    -- Create player name display above character (clean, no background clutter)
    local nameGui = Instance.new("BillboardGui")
    nameGui.Name = "PlayerNameGui"
    nameGui.Size = UDim2.new(0, 400, 0, 80) -- Clean name display
    nameGui.StudsOffset = Vector3.new(0, 15, 0) -- Higher up above the character
    nameGui.MaxDistance = 150 -- Limit visibility distance
    nameGui.Parent = characterDisplay
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1 -- No background - just floating text
    nameLabel.Text = ""
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextStrokeTransparency = 0 -- Add text stroke for visibility
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Parent = nameGui
end

-- Create spawn platform sign
function WorldBuilder.createSpawnSign(spawn)
    local sign = Instance.new("Part")
    sign.Name = "SpawnSign"
    sign.Size = Vector3.new(6, 3, 0.5)
    sign.Position = spawn.Position + Vector3.new(0, 4, 0)
    sign.Anchored = true
    sign.Material = Enum.Material.Neon
    sign.BrickColor = BrickColor.new("Bright blue")
    sign.Parent = spawn
    
    local signGui = Instance.new("BillboardGui")
    signGui.Size = UDim2.new(1, 0, 1, 0)
    signGui.Parent = sign
    
    local signLabel = Instance.new("TextLabel")
    signLabel.Size = UDim2.new(1, 0, 1, 0)
    signLabel.BackgroundTransparency = 1
    signLabel.Text = "🌱 FARMING SERVER 🌱\nWalk around to find your farm!"
    signLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    signLabel.TextScaled = true
    signLabel.Font = Enum.Font.SourceSansBold
    signLabel.Parent = signGui
end

-- Get plot by ID (now searches across all farm areas)
function WorldBuilder.getPlotById(plotId)
    local farmsContainer = Workspace:FindFirstChild("PlayerFarms")
    if not farmsContainer then return nil end
    
    -- Search through all farm areas
    for _, farmFolder in pairs(farmsContainer:GetChildren()) do
        if farmFolder.Name:match("^Farm_") then
            local plot = farmFolder:FindFirstChild("FarmPlot_" .. plotId)
            if plot then
                return plot
            end
        end
    end
    
    return nil
end

-- Get all plots across all farms
function WorldBuilder.getAllPlots()
    local farmsContainer = Workspace:FindFirstChild("PlayerFarms")
    if not farmsContainer then return {} end
    
    local plots = {}
    for _, farmFolder in pairs(farmsContainer:GetChildren()) do
        if farmFolder.Name:match("^Farm_") then
            for _, child in pairs(farmFolder:GetChildren()) do
                if child.Name:match("^FarmPlot_") then
                    table.insert(plots, child)
                end
            end
        end
    end
    
    return plots
end

-- Get plots in a specific farm
function WorldBuilder.getFarmPlots(farmId)
    local farmsContainer = Workspace:FindFirstChild("PlayerFarms")
    if not farmsContainer then return {} end
    
    local farmFolder = farmsContainer:FindFirstChild("Farm_" .. farmId)
    if not farmFolder then return {} end
    
    local plots = {}
    for _, child in pairs(farmFolder:GetChildren()) do
        if child.Name:match("^FarmPlot_") then
            table.insert(plots, child)
        end
    end
    
    return plots
end


-- Update farm sign to show ownership with character display (no clutter signs)
function WorldBuilder.updateFarmSign(farmId, playerName, player)
    local farmsContainer = Workspace:FindFirstChild("PlayerFarms")
    if not farmsContainer then return end
    
    local farmFolder = farmsContainer:FindFirstChild("Farm_" .. farmId)
    if not farmFolder then return end
    
    -- Update character display and name (no wooden/grey sign clutter)
    local characterDisplay = farmFolder:FindFirstChild("CharacterDisplay")
    if characterDisplay then
        local nameGui = characterDisplay:FindFirstChild("PlayerNameGui")
        local nameLabel = nameGui and nameGui:FindFirstChild("NameLabel")
        
        if nameLabel then
            if playerName then
                nameLabel.Text = playerName .. "'s Farm"
                nameLabel.Visible = true
                
                -- Create 3D character model if player is provided
                if player then
                    WorldBuilder.createPlayerCharacterDisplay(characterDisplay, player, farmId)
                end
            else
                nameLabel.Text = ""
                nameLabel.Visible = false
                
                -- Remove character model
                WorldBuilder.clearCharacterDisplay(characterDisplay)
            end
        end
    end
    
    log.debug("Updated farm", farmId, "character display:", playerName or "Available")
end

-- Create a real 3D Roblox character display for the farm sign
function WorldBuilder.createPlayerCharacterDisplay(characterDisplay, player, farmId)
    -- Clear existing character
    WorldBuilder.clearCharacterDisplay(characterDisplay)
    
    log.info("Creating 3D character display for", player.Name, "at", characterDisplay.Position)
    
    -- Method 1: Try to create a proper 3D character using Roblox's character system
    local success, characterModel = pcall(function()
        -- Get the player's humanoid description
        local humanoidDescription = Players:GetHumanoidDescriptionFromUserId(player.UserId)
        
        -- Create a full 3D character model using Roblox's built-in method
        -- Create it in a temporary container first to avoid spawning next to player
        local tempContainer = Instance.new("Folder")
        tempContainer.Name = "TempCharacterContainer"
        tempContainer.Parent = game:GetService("ServerStorage") -- Hidden location
        
        local newCharacter = Players:CreateHumanoidModelFromDescription(humanoidDescription, Enum.HumanoidRigType.R15)
        newCharacter.Name = "PlayerDisplay"
        newCharacter.Parent = tempContainer -- Put in hidden container first
        
        -- Wait for the character to fully generate and appearance to load
        log.info("Waiting for full character appearance to load for", player.Name, "in hidden container")
        wait(5) -- Wait even longer for complete appearance loading
        
        -- List what we actually got
        log.info("Character parts loaded for", player.Name, ":")
        for _, part in pairs(newCharacter:GetChildren()) do
            log.info("- " .. part.Name .. " (" .. part.ClassName .. ")")
        end
        
        -- Remove ONLY animation scripts but keep Humanoid for now
        for _, obj in pairs(newCharacter:GetChildren()) do
            if obj:IsA("Script") or obj:IsA("LocalScript") or obj.Name == "Animate" then
                obj:Destroy()
                log.debug("Removed", obj.Name, "script")
            end
        end
        
        -- Disable humanoid animations but keep it for appearance
        local humanoid = newCharacter:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.PlatformStand = true
            humanoid.Sit = true
            humanoid.WalkSpeed = 0
            humanoid.JumpPower = 0
            humanoid.JumpHeight = 0
            log.debug("Disabled humanoid movement but kept for appearance")
        end
        
        -- Now move the character to the proper display location and set it up
        newCharacter.Parent = characterDisplay -- Move from temp container to display area
        
        -- Get the root part and store original positions
        local humanoidRootPart = newCharacter:FindFirstChild("HumanoidRootPart")
        local originalPositions = {}
        local originalRotations = {}
        
        if humanoidRootPart then
            local rootPosition = humanoidRootPart.Position
            local rootCFrame = humanoidRootPart.CFrame
            
            -- Store original relative positions and rotations
            for _, part in pairs(newCharacter:GetChildren()) do
                if part:IsA("BasePart") and part ~= humanoidRootPart then
                    originalPositions[part] = part.Position - rootPosition
                    originalRotations[part] = rootCFrame:ToObjectSpace(part.CFrame)
                end
            end
            
            -- Collect ALL character parts including accessories
            local characterParts = {}
            local accessories = {}
            
            for _, obj in pairs(newCharacter:GetChildren()) do
                if obj:IsA("BasePart") and obj ~= humanoidRootPart then
                    characterParts[obj] = {
                        relativePos = originalPositions[obj] or Vector3.new(0, 0, 0),
                        relativeCFrame = originalRotations[obj] or CFrame.new()
                    }
                    log.debug("Stored part", obj.Name, "with relative position", characterParts[obj].relativePos)
                elseif obj:IsA("Accessory") then
                    table.insert(accessories, obj)
                    log.debug("Found accessory", obj.Name)
                end
            end
            
            -- Scale and reposition everything
            local scale = 4
            
            -- Position root part at display location FIRST
            humanoidRootPart.CFrame = CFrame.new(characterDisplay.Position)
            humanoidRootPart.Size = humanoidRootPart.Size * scale
            humanoidRootPart.Anchored = true
            humanoidRootPart.CanCollide = false
            
            log.info("Positioned root part for", player.Name, "at", characterDisplay.Position)
            
            -- Scale and reposition all body parts relative to root
            for part, data in pairs(characterParts) do
                if part.Parent then -- Make sure part still exists
                    part.Size = part.Size * scale
                    part.Anchored = true
                    part.CanCollide = false
                    
                    -- Calculate new position maintaining relative spacing
                    local scaledRelativePos = data.relativePos * scale
                    part.CFrame = humanoidRootPart.CFrame * CFrame.new(scaledRelativePos) * data.relativeCFrame
                    
                    log.debug("Repositioned", part.Name, "for", player.Name, "to", part.Position)
                end
            end
            
            -- Handle accessories WITH their attachment system
            for _, accessory in pairs(accessories) do
                local handle = accessory:FindFirstChild("Handle")
                if handle then
                    handle.Size = handle.Size * scale
                    handle.Anchored = true
                    handle.CanCollide = false
                    
                    -- Find the attachment on the accessory and on the character
                    local accessoryAttachment = handle:FindFirstChildOfClass("Attachment")
                    if accessoryAttachment then
                        -- Find corresponding attachment on character (usually head)
                        local attachmentName = accessoryAttachment.Name
                        for _, part in pairs(newCharacter:GetChildren()) do
                            if part:IsA("BasePart") then
                                local characterAttachment = part:FindFirstChild(attachmentName)
                                if characterAttachment then
                                    -- Position accessory relative to character attachment
                                    local offset = accessoryAttachment.CFrame
                                    handle.CFrame = characterAttachment.Parent.CFrame * characterAttachment.CFrame * offset:Inverse()
                                    log.debug("Positioned accessory", accessory.Name, "relative to", part.Name)
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
        
        -- Clean up temp container
        tempContainer:Destroy()
        
        -- Add glow effect to the head
        local head = newCharacter:FindFirstChild("Head")
        if head then
            local pointLight = Instance.new("PointLight")
            pointLight.Color = Color3.fromRGB(255, 255, 255)
            pointLight.Brightness = 2
            pointLight.Range = 25
            pointLight.Parent = head
        end
        
        log.info("Successfully created real 3D character for", player.Name)
        
        -- Notify clients about the new character display for face tracking
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local farmingRemotes = ReplicatedStorage:FindFirstChild("FarmingRemotes")
        if farmingRemotes then
            local characterTrackingRemote = farmingRemotes:FindFirstChild("CharacterTracking")
            if characterTrackingRemote then
                characterTrackingRemote:FireAllClients("characterCreated", {
                    farmId = farmId,
                    playerName = player.Name,
                    userId = player.UserId
                })
            end
        end
        
        return newCharacter
    end)
    
    if not success then
        log.warn("Character creation failed for", player.Name, "- retrying with longer wait...")
        -- Retry with even longer wait time
        success, characterModel = pcall(function()
            -- Try again but wait much longer for appearance
            log.info("Retrying character creation for", player.Name, "with extended wait time")
            
            -- Create it in a temporary container first to avoid spawning next to player
            local tempContainer = Instance.new("Folder")
            tempContainer.Name = "RetryCharacterContainer"
            tempContainer.Parent = game:GetService("ServerStorage")
            
            local humanoidDescription = Players:GetHumanoidDescriptionFromUserId(player.UserId)
            local newCharacter = Players:CreateHumanoidModelFromDescription(humanoidDescription, Enum.HumanoidRigType.R15)
            newCharacter.Name = "PlayerDisplay"
            newCharacter.Parent = tempContainer
            
            -- Wait MUCH longer for complete loading
            log.info("Waiting 10 seconds for complete character loading...")
            wait(10)
            
            -- Disable humanoid but keep for appearance
            local humanoid = newCharacter:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.PlatformStand = true
                humanoid.WalkSpeed = 0
                humanoid.JumpPower = 0
            end
            
            -- Move to display area and position
            newCharacter.Parent = characterDisplay
            
            local humanoidRootPart = newCharacter:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                humanoidRootPart.CFrame = CFrame.new(characterDisplay.Position)
                humanoidRootPart.Anchored = true
                
                -- Scale everything up
                for _, obj in pairs(newCharacter:GetChildren()) do
                    if obj:IsA("BasePart") then
                        obj.Size = obj.Size * 4
                        obj.Anchored = true
                        obj.CanCollide = false
                    elseif obj:IsA("Accessory") then
                        local handle = obj:FindFirstChild("Handle")
                        if handle then
                            handle.Size = handle.Size * 4
                            handle.Anchored = true
                        end
                    end
                end
            end
            
            tempContainer:Destroy()
            log.info("Retry successful for", player.Name)
            return newCharacter
        end)
    end
    
    if not success then
        log.warn("Both methods failed, using fallback display for", player.Name)
        -- Fallback: Create a simple but visible display
        WorldBuilder.createSimpleCharacterDisplay(characterDisplay, player)
        
        -- Still notify clients even for fallback
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local farmingRemotes = ReplicatedStorage:FindFirstChild("FarmingRemotes")
        if farmingRemotes then
            local characterTrackingRemote = farmingRemotes:FindFirstChild("CharacterTracking")
            if characterTrackingRemote then
                characterTrackingRemote:FireAllClients("characterCreated", {
                    farmId = farmId,
                    playerName = player.Name,
                    userId = player.UserId
                })
            end
        end
    end
end

-- Create a simplified character display as fallback
function WorldBuilder.createSimpleCharacterDisplay(characterDisplay, player)
    log.info("Creating simple character display for", player.Name, "UserID:", player.UserId)
    
    local characterModel = Instance.new("Model")
    characterModel.Name = "PlayerDisplay"
    characterModel.Parent = characterDisplay
    
    -- Create much bigger head with player's avatar for show-off factor
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(12, 12, 12) -- Even bigger head for maximum visibility
    head.Position = characterDisplay.Position + Vector3.new(0, 5, 0) -- Adjust position for bigger size
    head.Shape = Enum.PartType.Block
    head.Material = Enum.Material.Neon -- Make it glow for better visibility
    head.BrickColor = BrickColor.new("Light orange")
    head.Anchored = true
    head.CanCollide = false
    head.Parent = characterModel
    
    -- Add player's headshot with maximum valid quality
    local headDecal = Instance.new("Decal")
    headDecal.Texture = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=420&h=420" -- Maximum valid size
    headDecal.Face = Enum.NormalId.Front
    headDecal.Parent = head
    
    -- Add the same decal to multiple faces for better visibility
    local frontDecal = Instance.new("Decal")
    frontDecal.Texture = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=420&h=420"
    frontDecal.Face = Enum.NormalId.Back
    frontDecal.Parent = head
    
    -- Create much bigger body
    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(10, 10, 6) -- Much bigger torso
    torso.Position = characterDisplay.Position + Vector3.new(0, -3, 0) -- Adjust position
    torso.Shape = Enum.PartType.Block
    torso.Material = Enum.Material.Neon -- Make it glow
    torso.BrickColor = BrickColor.new("Bright blue")
    torso.Anchored = true
    torso.CanCollide = false
    torso.Parent = characterModel
    
    -- Try to add player's full body shot with maximum valid quality
    local bodyDecal = Instance.new("Decal")
    bodyDecal.Texture = "rbxthumb://type=AvatarBust&id=" .. player.UserId .. "&w=420&h=420" -- Maximum valid size
    bodyDecal.Face = Enum.NormalId.Front
    bodyDecal.Parent = torso
    
    -- Add glow effect
    local pointLight = Instance.new("PointLight")
    pointLight.Color = Color3.fromRGB(255, 255, 255)
    pointLight.Brightness = 1
    pointLight.Range = 20
    pointLight.Parent = head
    
    log.info("Successfully created large glowing character display for", player.Name, "at", characterDisplay.Position)
end

-- Clear character display
function WorldBuilder.clearCharacterDisplay(characterDisplay)
    local existingModel = characterDisplay:FindFirstChild("PlayerDisplay")
    if existingModel then
        existingModel:Destroy()
    end
end

return WorldBuilder