-- World builder for creating physical farm plots
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Logger = require(script.Parent.modules.Logger)

local WorldBuilder = {}

-- Get module logger
local log = Logger.getModuleLogger("WorldBuilder")

-- Farm plot configuration
local PLOT_SIZE = Vector3.new(8, 1, 8)
local PLOT_SPACING = 2
local FARM_GRID_SIZE = 4 -- 4x4 grid of plots

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
    
    -- Add ProximityPrompts (reduced activation distance to prevent overlap)
    local plantPrompt = Instance.new("ProximityPrompt")
    plantPrompt.Name = "PlantPrompt"
    plantPrompt.ActionText = "Plant Seed"
    plantPrompt.KeyboardKeyCode = Enum.KeyCode.E
    plantPrompt.RequiresLineOfSight = false
    plantPrompt.MaxActivationDistance = 6 -- Reduced from 10
    plantPrompt.Parent = plot
    
    local waterPrompt = Instance.new("ProximityPrompt")
    waterPrompt.Name = "WaterPrompt"
    waterPrompt.ActionText = "Water Plant"
    waterPrompt.KeyboardKeyCode = Enum.KeyCode.R
    waterPrompt.RequiresLineOfSight = false
    waterPrompt.MaxActivationDistance = 6 -- Reduced from 10
    waterPrompt.Enabled = false -- Hidden until planted
    waterPrompt.Parent = plot
    
    local harvestPrompt = Instance.new("ProximityPrompt")
    harvestPrompt.Name = "HarvestPrompt"
    harvestPrompt.ActionText = "Harvest Crop"
    harvestPrompt.KeyboardKeyCode = Enum.KeyCode.F
    harvestPrompt.RequiresLineOfSight = false
    harvestPrompt.MaxActivationDistance = 6 -- Reduced from 10
    harvestPrompt.Enabled = false -- Hidden until ready
    harvestPrompt.Parent = plot
    
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
    local plantPrompt = plot:FindFirstChild("PlantPrompt")
    local waterPrompt = plot:FindFirstChild("WaterPrompt")
    local harvestPrompt = plot:FindFirstChild("HarvestPrompt")
    local plantPosition = plot:FindFirstChild("PlantPosition")
    
    if not plotData then return end
    
    plotData.Value = state
    
    if state == "empty" then
        -- Dry brown dirt
        plot.BrickColor = BrickColor.new("CGA brown")
        if plantPosition then
            plantPosition.BrickColor = BrickColor.new("CGA brown")
        end
        
        plantPrompt.Enabled = true
        waterPrompt.Enabled = false
        harvestPrompt.Enabled = false
        
        -- Remove any existing plant
        local existingPlant = plot:FindFirstChild("Plant")
        if existingPlant then
            existingPlant:Destroy()
        end
        
    elseif state == "planted" then
        -- Show small plant with variation
        WorldBuilder.createPlant(plot, seedType, 1, variation)
        
        plantPrompt.Enabled = false
        waterPrompt.Enabled = true
        harvestPrompt.Enabled = false
        
    elseif state == "growing" then
        -- Show partially grown plant (needs more water) with variation
        WorldBuilder.createPlant(plot, seedType, 1, variation)
        
        plantPrompt.Enabled = false
        waterPrompt.Enabled = true
        harvestPrompt.Enabled = false
        
    elseif state == "watered" then
        -- Darker, moist dirt
        plot.BrickColor = BrickColor.new("Brown")
        if plantPosition then
            plantPosition.BrickColor = BrickColor.new("Brown")
        end
        
        -- Show growing plant with variation
        WorldBuilder.createPlant(plot, seedType, 2, variation)
        
        plantPrompt.Enabled = false
        waterPrompt.Enabled = false
        harvestPrompt.Enabled = false
        
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
        
        plantPrompt.Enabled = false
        waterPrompt.Enabled = false
        harvestPrompt.Enabled = true
    end
end

-- Build the entire farm
function WorldBuilder.buildFarm()
    log.info("Building 3D Farm World...")
    
    -- Clear existing farm if any
    local existingFarm = Workspace:FindFirstChild("Farm")
    if existingFarm then
        existingFarm:Destroy()
    end
    
    -- Create farm container
    local farm = Instance.new("Folder")
    farm.Name = "Farm"
    farm.Parent = Workspace
    
    -- Remove any existing spawn locations first
    for _, obj in pairs(Workspace:GetChildren()) do
        if obj:IsA("SpawnLocation") then
            obj:Destroy()
        end
    end
    
    -- Create single spawn platform (further from farm)
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "MainSpawn"
    spawn.Size = Vector3.new(10, 1, 10)
    spawn.Position = Vector3.new(0, 2, -40) -- Further away and lower
    spawn.Anchored = true
    spawn.Material = Enum.Material.Concrete
    spawn.BrickColor = BrickColor.new("Medium stone grey")
    spawn.Parent = farm
    
    -- Create farm plots in a grid (positioned away from spawn)
    local plotId = 1
    local farmOffsetZ = 20 -- Move farm 20 studs forward from center
    
    for row = 1, FARM_GRID_SIZE do
        for col = 1, FARM_GRID_SIZE do
            local x = (col - 1) * (PLOT_SIZE.X + PLOT_SPACING) - (FARM_GRID_SIZE * (PLOT_SIZE.X + PLOT_SPACING)) / 2
            local z = (row - 1) * (PLOT_SIZE.Z + PLOT_SPACING) - (FARM_GRID_SIZE * (PLOT_SIZE.Z + PLOT_SPACING)) / 2 + farmOffsetZ
            local position = Vector3.new(x, PLOT_SIZE.Y / 2, z)
            
            local plot = createFarmPlot(position, plotId)
            plot.Parent = farm
            
            plotId = plotId + 1
        end
    end
    
    
    log.info("Farm built with " .. (plotId - 1) .. " plots!")
    return farm
end

-- Get plot by ID
function WorldBuilder.getPlotById(plotId)
    local farm = Workspace:FindFirstChild("Farm")
    if not farm then return nil end
    
    return farm:FindFirstChild("FarmPlot_" .. plotId)
end

-- Get all plots
function WorldBuilder.getAllPlots()
    local farm = Workspace:FindFirstChild("Farm")
    if not farm then return {} end
    
    local plots = {}
    for _, child in pairs(farm:GetChildren()) do
        if child.Name:match("^FarmPlot_") then
            table.insert(plots, child)
        end
    end
    
    return plots
end

return WorldBuilder