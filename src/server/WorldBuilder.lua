-- World builder for creating physical farm plots
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local WorldBuilder = {}

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

-- Create a 3D plant model
function WorldBuilder.createPlant(plot, seedType, growthStage)
    -- Remove existing plant if any
    local existingPlant = plot:FindFirstChild("Plant")
    if existingPlant then
        existingPlant:Destroy()
    end
    
    if growthStage == 0 then
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
    plant.BrickColor = BrickColor.new(plantColors[seedType] or "Bright green")
    plant.Anchored = true
    plant.CanCollide = false
    plant.TopSurface = Enum.SurfaceType.Smooth
    plant.BottomSurface = Enum.SurfaceType.Smooth
    
    -- Position above the plot
    local plotPosition = plot.Position
    plant.Position = plotPosition + Vector3.new(0, plot.Size.Y/2 + plant.Size.Y/2, 0)
    plant.Orientation = Vector3.new(0, 0, 90) -- Rotate cylinder to be vertical
    plant.Parent = plot
    
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

-- Update plot visual state
function WorldBuilder.updatePlotState(plot, state, seedType)
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
        -- Show small plant
        WorldBuilder.createPlant(plot, seedType, 1)
        
        plantPrompt.Enabled = false
        waterPrompt.Enabled = true
        harvestPrompt.Enabled = false
        
    elseif state == "growing" then
        -- Show partially grown plant (needs more water)
        WorldBuilder.createPlant(plot, seedType, 1)
        
        plantPrompt.Enabled = false
        waterPrompt.Enabled = true
        harvestPrompt.Enabled = false
        
    elseif state == "watered" then
        -- Darker, moist dirt
        plot.BrickColor = BrickColor.new("Brown")
        if plantPosition then
            plantPosition.BrickColor = BrickColor.new("Brown")
        end
        
        -- Show growing plant
        WorldBuilder.createPlant(plot, seedType, 2)
        
        plantPrompt.Enabled = false
        waterPrompt.Enabled = false
        harvestPrompt.Enabled = false
        
    elseif state == "ready" then
        -- Show full grown plant
        local plant = WorldBuilder.createPlant(plot, seedType, 3)
        
        -- Add particle effects to ready crops
        if plant then
            local attachment = Instance.new("Attachment")
            attachment.Name = "ParticleAttachment"
            attachment.Position = Vector3.new(0, plant.Size.Y/2, 0)
            attachment.Parent = plant
            
            local particles = Instance.new("ParticleEmitter")
            particles.Name = "ReadyParticles"
            particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
            particles.Lifetime = NumberRange.new(0.5, 1.0)
            particles.Rate = 20
            particles.SpreadAngle = Vector2.new(45, 45)
            particles.Speed = NumberRange.new(2, 4)
            particles.Color = ColorSequence.new(Color3.fromRGB(255, 255, 100)) -- Golden sparkles
            particles.Size = NumberSequence.new(0.1)
            particles.Parent = attachment
            
            print("Added sparkle particles to ready crop!")
        end
        
        plantPrompt.Enabled = false
        waterPrompt.Enabled = false
        harvestPrompt.Enabled = true
    end
end

-- Build the entire farm
function WorldBuilder.buildFarm()
    print("Building 3D Farm World...")
    
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
    
    -- Create NPC Merchant (much further from farm)
    local merchantPosition = Vector3.new(40, 1, 0) -- Much further to the right
    
    -- Merchant platform
    local merchantPlatform = Instance.new("Part")
    merchantPlatform.Name = "MerchantPlatform"
    merchantPlatform.Size = Vector3.new(8, 1, 8)
    merchantPlatform.Position = merchantPosition
    merchantPlatform.Anchored = true
    merchantPlatform.Material = Enum.Material.Brick
    merchantPlatform.BrickColor = BrickColor.new("Dark stone grey")
    merchantPlatform.Parent = farm
    
    -- Merchant NPC (simple block character)
    local merchant = Instance.new("Part")
    merchant.Name = "Merchant"
    merchant.Size = Vector3.new(2, 6, 1)
    merchant.Position = merchantPosition + Vector3.new(0, 4, 0)
    merchant.Anchored = true
    merchant.Material = Enum.Material.Plastic
    merchant.BrickColor = BrickColor.new("Bright blue")
    merchant.Shape = Enum.PartType.Block
    merchant.Parent = farm
    
    -- Merchant head
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(1.5, 1.5, 1.5)
    head.Position = merchantPosition + Vector3.new(0, 5.5, 0)
    head.Anchored = true
    head.Material = Enum.Material.Plastic
    head.BrickColor = BrickColor.new("Light orange")
    head.Shape = Enum.PartType.Ball
    head.Parent = merchant
    
    -- Merchant shop sign
    local sign = Instance.new("Part")
    sign.Name = "Sign"
    sign.Size = Vector3.new(4, 3, 0.2)
    sign.Position = merchantPosition + Vector3.new(0, 3, -2)
    sign.Anchored = true
    sign.Material = Enum.Material.Wood
    sign.BrickColor = BrickColor.new("Medium brown")
    sign.Parent = farm
    
    local signText = Instance.new("SurfaceGui")
    signText.Face = Enum.NormalId.Front
    signText.Parent = sign
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "CROP MERCHANT\nSell All Crops\nPress E"
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Parent = signText
    
    -- Merchant selling prompt
    local sellPrompt = Instance.new("ProximityPrompt")
    sellPrompt.Name = "SellAllPrompt"
    sellPrompt.ActionText = "Sell All Crops"
    sellPrompt.KeyboardKeyCode = Enum.KeyCode.E
    sellPrompt.RequiresLineOfSight = false
    sellPrompt.MaxActivationDistance = 15
    sellPrompt.Parent = merchant
    
    -- Create Automation NPC (Gamepass feature)
    local autoPosition = Vector3.new(-45, 1, 0) -- Much further to the left
    
    -- Automation platform
    local autoPlatform = Instance.new("Part")
    autoPlatform.Name = "AutoPlatform"
    autoPlatform.Size = Vector3.new(8, 1, 8)
    autoPlatform.Position = autoPosition
    autoPlatform.Anchored = true
    autoPlatform.Material = Enum.Material.Neon
    autoPlatform.BrickColor = BrickColor.new("Bright green")
    autoPlatform.Parent = farm
    
    -- Automation NPC (robot-like)
    local autoBot = Instance.new("Part")
    autoBot.Name = "AutoBot"
    autoBot.Size = Vector3.new(2, 6, 1)
    autoBot.Position = autoPosition + Vector3.new(0, 4, 0)
    autoBot.Anchored = true
    autoBot.Material = Enum.Material.Neon
    autoBot.BrickColor = BrickColor.new("Lime green")
    autoBot.Shape = Enum.PartType.Block
    autoBot.Parent = farm
    
    -- AutoBot head
    local autoHead = Instance.new("Part")
    autoHead.Name = "Head"
    autoHead.Size = Vector3.new(1.5, 1.5, 1.5)
    autoHead.Position = autoPosition + Vector3.new(0, 5.5, 0)
    autoHead.Anchored = true
    autoBot.Material = Enum.Material.ForceField
    autoHead.BrickColor = BrickColor.new("Electric blue")
    autoHead.Shape = Enum.PartType.Ball
    autoHead.Parent = autoBot
    
    -- AutoBot sign
    local autoSign = Instance.new("Part")
    autoSign.Name = "AutoSign"
    autoSign.Size = Vector3.new(4, 3, 0.2)
    autoSign.Position = autoPosition + Vector3.new(0, 3, -2)
    autoSign.Anchored = true
    autoSign.Material = Enum.Material.Neon
    autoSign.BrickColor = BrickColor.new("Bright green")
    autoSign.Parent = farm
    
    local autoSignText = Instance.new("SurfaceGui")
    autoSignText.Face = Enum.NormalId.Front
    autoSignText.Parent = autoSign
    
    local autoTextLabel = Instance.new("TextLabel")
    autoTextLabel.Size = UDim2.new(1, 0, 1, 0)
    autoTextLabel.BackgroundTransparency = 1
    autoTextLabel.Text = "AUTO-FARMER\nAutomation Menu\nPress E"
    autoTextLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
    autoTextLabel.TextScaled = true
    autoTextLabel.Font = Enum.Font.SourceSansBold
    autoTextLabel.Parent = autoSignText
    
    -- Single automation prompt
    local autoPrompt = Instance.new("ProximityPrompt")
    autoPrompt.Name = "AutoPrompt"
    autoPrompt.ActionText = "Automation Menu"
    autoPrompt.KeyboardKeyCode = Enum.KeyCode.E
    autoPrompt.RequiresLineOfSight = false
    autoPrompt.MaxActivationDistance = 15
    autoPrompt.Parent = autoBot
    
    print("Farm built with " .. (plotId - 1) .. " plots, merchant, and auto-farmer!")
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