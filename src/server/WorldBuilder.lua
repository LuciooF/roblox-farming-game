-- World builder for creating physical farm plots
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Logger = require(script.Parent.modules.Logger)
-- Import unified crop system - REQUIRED for the refactored system
local CropRegistry = require(game:GetService("ReplicatedStorage").Shared.CropRegistry)
local NumberFormatter = require(game:GetService("ReplicatedStorage").Shared.NumberFormatter)
local assets = require(game:GetService("ReplicatedStorage").Shared.assets)

local WorldBuilder = {}

-- Get module logger
local log = Logger.getModuleLogger("WorldBuilder")

-- Helper function to get mobile-friendly BillboardGui size
local function getBillboardGuiSize(baseWidth, baseHeight)
    -- Reduce the size by 30% to make text more appropriate for mobile devices
    -- This helps prevent the text from being too large on smaller screens
    local mobileScale = 0.7
    return UDim2.new(0, math.floor(baseWidth * mobileScale), 0, math.floor(baseHeight * mobileScale))
end

-- Template farm system
local USE_TEMPLATE_FARM = true -- Template is ready!

-- Helper function to show/hide decorative wheat model by scaling
local function setWheatVisibility(plot, visible)
    local wheatModel = plot:FindFirstChild("Wheat")
    if not wheatModel then return end
    
    if visible then
        -- Show wheat model by scaling all parts to normal size
        for _, child in pairs(wheatModel:GetDescendants()) do
            if child:IsA("BasePart") then
                local originalSize = child:GetAttribute("OriginalSize")
                local originalPosition = child:GetAttribute("OriginalPosition")
                
                if originalSize then
                    child.Size = originalSize
                end
                if originalPosition then
                    child.Position = originalPosition
                end
            end
        end
    else
        -- Hide wheat model by scaling all parts to tiny size
        for _, child in pairs(wheatModel:GetDescendants()) do
            if child:IsA("BasePart") then
                -- Store original size and position if not already stored
                if not child:GetAttribute("OriginalSize") then
                    child:SetAttribute("OriginalSize", child.Size)
                    child:SetAttribute("OriginalPosition", child.Position)
                end
                
                -- Scale to very small size
                child.Size = child.Size * 0.01
            end
        end
    end
end

-- Setup necessary components for plot interactions
local function setupPlotComponents(plot)
    -- Get the interaction part (for Models, use PrimaryPart; for Parts, use the Part itself)
    local interactionPart = plot
    if plot:IsA("Model") then
        if plot.PrimaryPart then
            interactionPart = plot.PrimaryPart
        else
            -- Fallback: look for a part named "PlotBase", "Core", or similar
            local basePart = plot:FindFirstChild("PlotBase") or plot:FindFirstChild("Core") or plot:FindFirstChild("Base")
            if basePart and basePart:IsA("BasePart") then
                interactionPart = basePart
            else
                -- Final fallback: find first Part
                for _, child in pairs(plot:GetChildren()) do
                    if child:IsA("BasePart") then
                        interactionPart = child
                        break
                    end
                end
            end
        end
    end
    
    if not interactionPart or not interactionPart:IsA("BasePart") then
        log.error("Could not find valid interaction part for plot:", plot.Name)
        return
    end
    
    -- Add plot-specific planting prompt to the interaction part
    local actionPrompt = interactionPart:FindFirstChild("ActionPrompt")
    if not actionPrompt then
        actionPrompt = Instance.new("ProximityPrompt")
        actionPrompt.Name = "ActionPrompt"
        actionPrompt.ActionText = "Plant Crop"
        actionPrompt.KeyboardKeyCode = Enum.KeyCode.E
        actionPrompt.RequiresLineOfSight = false
        actionPrompt.MaxActivationDistance = 8
        actionPrompt.UIOffset = Vector2.new(0, 24)
        actionPrompt.Parent = interactionPart
        
        -- Connect plot interaction to open UI
        actionPrompt.Triggered:Connect(function(player)
            local plotIdValue = plot:FindFirstChild("PlotId")
            local farmIdValue = plot:FindFirstChild("FarmId")
            if plotIdValue and farmIdValue then
                local FarmManager = require(script.Parent.modules.FarmManager)
                local globalPlotId = FarmManager.getGlobalPlotId(farmIdValue.Value, plotIdValue.Value)
                
                -- Send plot UI open request to client
                local RemoteManager = require(script.Parent.modules.RemoteManager)
                RemoteManager.openPlotUI(player, globalPlotId)
            end
        end)
    end
    
    -- Water hose removed - watering is now handled through the Plot UI system
    -- Clean up any existing water hose on both the plot and interaction part
    local existingHose = plot:FindFirstChild("WaterHose")
    if existingHose then
        existingHose:Destroy()
    end
    if interactionPart ~= plot then
        local existingHoseOnPart = interactionPart:FindFirstChild("WaterHose")
        if existingHoseOnPart then
            existingHoseOnPart:Destroy()
        end
    end
    
    -- Store plot data if it doesn't exist
    local plotData = plot:FindFirstChild("PlotData")
    if not plotData then
        plotData = Instance.new("StringValue")
        plotData.Name = "PlotData"
        plotData.Value = "empty"
        plotData.Parent = plot
    end
    
    -- Add seed type value if it doesn't exist
    local seedTypeValue = plot:FindFirstChild("SeedType")
    if not seedTypeValue then
        seedTypeValue = Instance.new("StringValue")
        seedTypeValue.Name = "SeedType"
        seedTypeValue.Value = ""
        seedTypeValue.Parent = plot
    end
    
    -- Add planted time value if it doesn't exist
    local plantedTimeValue = plot:FindFirstChild("PlantedTime")
    if not plantedTimeValue then
        plantedTimeValue = Instance.new("NumberValue")
        plantedTimeValue.Name = "PlantedTime"
        plantedTimeValue.Value = 0
        plantedTimeValue.Parent = plot
    end
    
    -- Add watered time value if it doesn't exist
    local wateredTimeValue = plot:FindFirstChild("WateredTime")
    if not wateredTimeValue then
        wateredTimeValue = Instance.new("NumberValue")
        wateredTimeValue.Name = "WateredTime"
        wateredTimeValue.Value = 0
        wateredTimeValue.Parent = plot
    end
    
    -- Create invisible plant position marker if it doesn't exist
    local plantPosition = interactionPart:FindFirstChild("PlantPosition")
    if not plantPosition then
        plantPosition = Instance.new("Part")
        plantPosition.Name = "PlantPosition"
        plantPosition.Size = Vector3.new(0.1, 0.1, 0.1)
        plantPosition.Position = interactionPart.Position + Vector3.new(0, 0.55, 0)
        plantPosition.Anchored = true
        plantPosition.Transparency = 1
        plantPosition.CanCollide = false
        plantPosition.Parent = interactionPart
    end
    
    -- Create countdown display if it doesn't exist (attach to interaction part for Models)
    local countdownGui = interactionPart:FindFirstChild("CountdownDisplay")
    if not countdownGui then
        countdownGui = Instance.new("BillboardGui")
        countdownGui.Name = "CountdownDisplay"
        countdownGui.Size = getBillboardGuiSize(160, 80) -- Mobile-friendly scaling applied
        countdownGui.StudsOffset = Vector3.new(0, 4.5, 0) -- Higher up to avoid blocking crop
        countdownGui.LightInfluence = 0
        countdownGui.Parent = interactionPart
        
        local countdownLabel = Instance.new("TextLabel")
        countdownLabel.Size = UDim2.new(1, 0, 1, 0)
        countdownLabel.BackgroundTransparency = 1
        countdownLabel.Text = ""
        countdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        countdownLabel.TextScaled = true
        countdownLabel.Font = Enum.Font.SourceSansBold
        countdownLabel.TextStrokeTransparency = 0
        countdownLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        countdownLabel.TextXAlignment = Enum.TextXAlignment.Center -- Center align for better readability
        countdownLabel.TextYAlignment = Enum.TextYAlignment.Center
        countdownLabel.Parent = countdownGui
    end
end

-- Update plot references after cloning from template
local function updatePlotReferences(farmFolder, farmId)
    local plotIndex = 1
    local plots = {}
    
    -- Find all plots in the template farm and sort them
    for _, child in ipairs(farmFolder:GetDescendants()) do
        if child.Name:match("^Plot%d+$") and (child:IsA("Model") or child:IsA("BasePart")) then
            table.insert(plots, child)
            print("Found plot:", child.Name, "Type:", child.ClassName)
        end
    end
    
    print("Before sorting - found", #plots, "plots")
    for i, plot in ipairs(plots) do
        print("  ", i, ":", plot.Name)
    end
    
    -- Sort plots by name for consistent ordering (numerically, not alphabetically)
    table.sort(plots, function(a, b) 
        local numA = tonumber(a.Name:match("(%d+)")) or 0
        local numB = tonumber(b.Name:match("(%d+)")) or 0
        print("Comparing", a.Name, "(", numA, ") vs", b.Name, "(", numB, ") - result:", numA < numB)
        return numA < numB
    end)
    
    print("After sorting:")
    for i, plot in ipairs(plots) do
        print("  ", i, ":", plot.Name)
    end
    
    -- Update each plot with proper ID and ensure all components exist
    for _, plot in ipairs(plots) do
        -- Update plot ID for PlotManager (local ID 1-40)
        local plotIdValue = plot:FindFirstChild("PlotId")
        if not plotIdValue then
            plotIdValue = Instance.new("IntValue")
            plotIdValue.Name = "PlotId"
            plotIdValue.Parent = plot
        end
        
        -- Use local plot ID (1-40 per farm)
        plotIdValue.Value = plotIndex
        
        -- Also add farm ID for easy reference
        local farmIdValue = plot:FindFirstChild("FarmId") 
        if not farmIdValue then
            farmIdValue = Instance.new("IntValue")
            farmIdValue.Name = "FarmId"
            farmIdValue.Parent = plot
        end
        farmIdValue.Value = farmId
        
        -- Ensure plot has all necessary components for interactions
        setupPlotComponents(plot)
        
        log.debug("Updated plot", plot.Name, "to local ID", plotIndex, "in farm", farmId)
        plotIndex = plotIndex + 1
    end
    
    log.info("Updated", #plots, "plots in farm", farmId)
    return #plots -- Return actual plot count
end

-- Create farm from template
local function createFarmFromTemplate(farmId, position)
    local templateFarm = Workspace:FindFirstChild("FarmTemplate")
    if not templateFarm then
        log.error("FarmTemplate not found in Workspace!")
        return nil
    end
    
    log.info("Creating farm", farmId, "from template at position", position)
    
    -- Clone the template
    local newFarm = templateFarm:Clone()
    newFarm.Name = "Farm_" .. farmId
    
    -- Ensure PlayerFarms folder exists
    local playerFarms = Workspace:FindFirstChild("PlayerFarms")
    if not playerFarms then
        playerFarms = Instance.new("Folder")
        playerFarms.Name = "PlayerFarms"
        playerFarms.Parent = Workspace
    end
    
    newFarm.Parent = playerFarms
    
    -- Move farm to correct position
    local templateCFrame, templateSize = templateFarm:GetBoundingBox()
    local templateCenter = templateCFrame.Position
    
    -- Find the FarmSpawn part to use as reference for ground level positioning
    local farmSpawn = nil
    for _, child in ipairs(newFarm:GetDescendants()) do
        if child:IsA("SpawnLocation") and child.Name:match("FarmSpawn") then
            farmSpawn = child
            -- FIX: Rename the spawn location to match the farm ID
            farmSpawn.Name = "FarmSpawn_" .. farmId
            log.info("🔧 TEMPLATE FIX: Renamed spawn location to", farmSpawn.Name, "for farm", farmId)
            break
        end
    end
    
    if not farmSpawn then
        log.debug("🏗️ FARM CREATION: No FarmSpawn found! Falling back to original method")
        -- Fallback to old method if no spawn found
        local lowestY = math.huge
        for _, child in ipairs(newFarm:GetDescendants()) do
            if child:IsA("BasePart") then
                local partBottom = child.Position.Y - (child.Size.Y / 2)
                if partBottom < lowestY then
                    lowestY = partBottom
                end
            end
        end
        farmSpawn = {Position = Vector3.new(0, lowestY + 0.5, 0), Size = Vector3.new(1, 1, 1)} -- Mock object
    end
    
    -- Use the spawn's bottom as our reference point for ground level
    local spawnBottom = farmSpawn.Position.Y - (farmSpawn.Size.Y / 2)
    log.debug("🏗️ FARM CREATION: Using FarmSpawn", farmSpawn.Name or "FALLBACK", "at position", farmSpawn.Position, "with bottom at Y:", spawnBottom)
    
    -- Find the actual ground level (top surface of baseplate)
    local groundLevel = 0.5 -- Standard Roblox baseplate level
    local baseplate = Workspace:FindFirstChild("Baseplate")
    if baseplate then
        -- Use the top surface of the baseplate as ground level
        groundLevel = baseplate.Position.Y + (baseplate.Size.Y / 2)
        log.debug("🏗️ FARM CREATION: Found baseplate - Position:", baseplate.Position, "Size:", baseplate.Size, "Top surface Y:", groundLevel)
    else
        log.debug("🏗️ FARM CREATION: No baseplate found, using default ground level:", groundLevel)
    end
    
    -- Calculate ABSOLUTE positioning - put the FarmSpawn bottom at ground level
    -- We want the spawn to sit exactly on the baseplate surface
    local yOffsetNeeded = groundLevel - spawnBottom
    
    -- Calculate horizontal offset to move farm to target position
    local horizontalOffset = Vector3.new(position.X - templateCenter.X, 0, position.Z - templateCenter.Z)
    
    -- Combine horizontal movement with vertical positioning
    local absoluteOffset = Vector3.new(horizontalOffset.X, yOffsetNeeded, horizontalOffset.Z)
    
    log.debug("🏗️ FARM CREATION: Farm", farmId, "SPAWN positioning - TemplateCenter:", templateCenter, "SpawnBottom:", spawnBottom, "GroundLevel:", groundLevel, "YOffsetNeeded:", yOffsetNeeded, "AbsoluteOffset:", absoluteOffset)
    
    -- Move all parts in the farm using absolute positioning
    local partsMoved = 0
    for _, child in ipairs(newFarm:GetDescendants()) do
        if child:IsA("BasePart") then
            local oldPos = child.Position
            child.Position = child.Position + absoluteOffset
            partsMoved = partsMoved + 1
            if partsMoved <= 3 then -- Log first few parts
                log.debug("🏗️ FARM CREATION: Moved part", child.Name, "from", oldPos, "to", child.Position)
            end
        end
    end
    
    log.debug("🏗️ FARM CREATION: Moved", partsMoved, "parts for farm", farmId, "with absolute offset:", absoluteOffset)
    
    -- Verify the result by checking the spawn position
    if farmSpawn and farmSpawn.Parent then
        local newSpawnBottom = farmSpawn.Position.Y - (farmSpawn.Size.Y / 2)
        log.debug("🏗️ FARM CREATION: VERIFICATION - FarmSpawn bottom now at Y:", newSpawnBottom, "(should be ~", groundLevel, ")")
        log.debug("🏗️ FARM CREATION: ERROR ANALYSIS - Expected:", groundLevel, "Actual:", newSpawnBottom, "Difference:", newSpawnBottom - groundLevel, "studs")
    end
    
    -- Update plot references for PlotManager
    updatePlotReferences(newFarm, farmId)
    
    -- Create farm sign with character display
    WorldBuilder.createFarmSign(newFarm, position, farmId)
    
    -- Set up Portal UI if Portal exists
    WorldBuilder.setupPortalUI(newFarm, farmId)
    
    log.info("Farm", farmId, "created from template successfully")
    return newFarm
end

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
    actionPrompt.ActionText = "Open Plot UI" -- Opens the plot management UI
    actionPrompt.KeyboardKeyCode = Enum.KeyCode.E 
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
    countdownGui.Size = getBillboardGuiSize(100, 50) -- Mobile-friendly scaling applied
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
    
    local plant
    
    -- Get crop data from registry
    local cropData = CropRegistry.getCrop(seedType)
    
    if not cropData then
        log.error("Unknown crop type:", seedType, "- check CropRegistry")
        error("Invalid crop type: " .. tostring(seedType))
    end
    
    -- Use asset icon if available, then 3D mesh, then basic part
    if cropData and cropData.assetId then
        -- Create Part with BillboardGui for 2D asset icons
        plant = Instance.new("Part")
        plant.Name = "Plant"
        plant.Size = Vector3.new(1, 1, 1) -- Minimal size for billboard
        plant.Material = Enum.Material.ForceField
        plant.Transparency = 1 -- Invisible part, only show the icon
        
        -- Create BillboardGui for the crop icon
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "CropIcon"
        billboard.Size = UDim2.new(0, 100, 0, 100) -- Base size
        billboard.StudsOffset = Vector3.new(0, 0.5, 0) -- Slightly above ground
        billboard.LightInfluence = 0
        billboard.MaxDistance = 30 -- Only visible when close
        billboard.Parent = plant
        
        -- Create ImageLabel for the crop icon
        local iconLabel = Instance.new("ImageLabel")
        iconLabel.Name = "Icon"
        iconLabel.Size = UDim2.new(1, 0, 1, 0)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Image = cropData.assetId
        iconLabel.Parent = billboard
        
        -- Scale based on growth stage
        local scaleMultipliers = {
            [1] = 0.4, -- Just planted - small
            [2] = 0.7, -- Growing - medium
            [3] = 1.0  -- Full grown - full size
        }
        local scale = scaleMultipliers[growthStage] or 0.4
        billboard.Size = UDim2.new(0, 100 * scale, 0, 100 * scale)
        
        log.debug("Created asset icon for", seedType, "with asset ID", cropData.assetId, "scale", scale)
    elseif cropData.meshId then
        -- Create Part with SpecialMesh for 3D assets
        plant = Instance.new("Part")
        plant.Name = "Plant"
        plant.Size = Vector3.new(2, 2, 2) -- Base size for asset scaling
        plant.Material = Enum.Material.Plastic
        plant.Transparency = 0 -- Make visible now that we use CropRegistry
        
        -- Add the 3D mesh
        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.FileMesh
        mesh.MeshId = "rbxassetid://" .. cropData.meshId
        
        -- Scale based on growth stage
        local scaleMultipliers = {
            [1] = 0.3, -- Just planted - small
            [2] = 0.6, -- Growing - medium
            [3] = 1.0  -- Full grown - full size
        }
        local scale = scaleMultipliers[growthStage] or 0.3
        mesh.Scale = Vector3.new(scale, scale, scale)
        mesh.Parent = plant
        
        log.debug("Created 3D mesh for", seedType, "with ID", cropData.meshId, "scale", scale)
    else
        -- Use basic part for crops without 3D assets or icons
        plant = Instance.new("Part")
        plant.Name = "Plant"
        plant.Size = sizes[growthStage] or sizes[1]
        plant.Shape = Enum.PartType.Cylinder
        plant.Material = Enum.Material.Neon
    end
    
    -- Apply basic crop coloring from CropRegistry
    if cropData and cropData.color then
        plant.Color = cropData.color
    else
        -- Fallback to a default color if no crop data
        plant.Color = Color3.fromRGB(100, 200, 100)
    end
    
    -- Dead plants no longer exist - variation "dead" removed
    
    plant.Anchored = true
    plant.CanCollide = false
    plant.TopSurface = Enum.SurfaceType.Smooth
    plant.BottomSurface = Enum.SurfaceType.Smooth
    
    -- Get the interaction part for positioning (works for both Parts and Models)
    local interactionPart = plot
    if plot:IsA("Model") then
        if plot.PrimaryPart then
            interactionPart = plot.PrimaryPart
        else
            -- Fallback: look for PlotBase or similar
            local basePart = plot:FindFirstChild("PlotBase") or plot:FindFirstChild("Core") or plot:FindFirstChild("Base")
            if basePart and basePart:IsA("BasePart") then
                interactionPart = basePart
            else
                -- Final fallback: find first Part
                for _, child in pairs(plot:GetChildren()) do
                    if child:IsA("BasePart") then
                        interactionPart = child
                        break
                    end
                end
            end
        end
    end
    
    -- Position the plant using interaction part
    local plotPosition = interactionPart.Position
    local plotSize = interactionPart.Size
    
    if cropData.meshId then
        -- Position 3D mesh assets appropriately
        plant.Position = plotPosition + Vector3.new(0, plotSize.Y/2 + 0.5, 0) -- Slightly above ground
        plant.Orientation = Vector3.new(0, math.random(0, 360), 0) -- Random Y rotation for variety
    else
        -- Position other plants above the plot
        plant.Position = plotPosition + Vector3.new(0, plotSize.Y/2 + plant.Size.Y/2, 0)
        plant.Orientation = Vector3.new(0, 0, 90) -- Rotate cylinder to be vertical
    end
    
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
function WorldBuilder.updatePlotState(plot, state, seedType, variation, waterProgress, _, plotIndex, requiredRebirth, viewingPlayer)
    variation = variation or "normal"
    waterProgress = waterProgress or {current = 0, needed = 1}
    plotIndex = plotIndex or 1
    requiredRebirth = requiredRebirth or 0
    
    -- Get farmId from the plot's FarmId value
    local farmIdValue = plot:FindFirstChild("FarmId")
    local farmId = farmIdValue and farmIdValue.Value or 1
    
    -- Get the interaction part (for Models, use PrimaryPart; for Parts, use the Part itself)
    local interactionPart = plot
    if plot:IsA("Model") then
        if plot.PrimaryPart then
            interactionPart = plot.PrimaryPart
        else
            -- Fallback: look for a part named "PlotBase", "Core", or similar
            local basePart = plot:FindFirstChild("PlotBase") or plot:FindFirstChild("Core") or plot:FindFirstChild("Base")
            if basePart and basePart:IsA("BasePart") then
                interactionPart = basePart
            else
                -- Final fallback: find first Part
                for _, child in pairs(plot:GetChildren()) do
                    if child:IsA("BasePart") then
                        interactionPart = child
                        break
                    end
                end
            end
        end
    end
    
    local plotData = plot:FindFirstChild("PlotData")
    local actionPrompt = interactionPart:FindFirstChild("ActionPrompt")
    local plantPosition = interactionPart:FindFirstChild("PlantPosition")
    
    if not plotData or not actionPrompt then return end
    
    plotData.Value = state
    
    if state == "empty" then
        -- Hide decorative plant models when plot is empty
        setWheatVisibility(plot, false)
        
        -- Restore visibility first (in case it was invisible)
        interactionPart.Transparency = 0
        if plantPosition then
            plantPosition.Transparency = 1 -- Keep plant position invisible
        end
        
        -- Restore border if it exists
        local border = interactionPart:FindFirstChild("Border")
        if border then
            border.Transparency = 0
        end
        
        -- Restore countdown display
        local countdownDisplay = interactionPart:FindFirstChild("CountdownDisplay")
        if countdownDisplay then
            countdownDisplay.Enabled = true
        end
        
        -- Dry brown dirt
        interactionPart.BrickColor = BrickColor.new("CGA brown")
        if plantPosition then
            plantPosition.BrickColor = BrickColor.new("CGA brown")
        end
        
        -- All plots use the same UI prompt
        actionPrompt.ActionText = "Open Plot UI"
        actionPrompt.Enabled = true
        
        -- Remove any existing plant
        local existingPlant = plot:FindFirstChild("Plant")
        if existingPlant then
            existingPlant:Destroy()
        end
        
        -- Remove lock indicator if present (plot was unlocked)
        local lockIndicator = interactionPart:FindFirstChild("LockIndicator")
        if lockIndicator then
            lockIndicator:Destroy()
        end
        
        -- Remove rebirth effects if present
        local rebirthIndicator = plot:FindFirstChild("RebirthIndicator")
        if rebirthIndicator then
            rebirthIndicator:Destroy()
        end
        
        local mysticalGlow = plot:FindFirstChild("MysticalGlow")
        if mysticalGlow then
            mysticalGlow:Destroy()
        end
        
        local proximityShine = plot:FindFirstChild("ProximityShine")
        if proximityShine then
            proximityShine:Destroy()
        end
        
    elseif state == "planted" then
        -- Show decorative plant models when something is planted
        setWheatVisibility(plot, true)
        
        -- Light brown dirt for planted crops
        interactionPart.BrickColor = BrickColor.new("Nougat")
        if plantPosition then
            plantPosition.BrickColor = BrickColor.new("Nougat")
        end
        
        -- Show small plant with variation
        WorldBuilder.createPlant(plot, seedType, 1, variation)
        
        -- All plots use the same UI prompt
        actionPrompt.ActionText = "Open Plot UI"
        actionPrompt.Enabled = true
        
    elseif state == "growing" then
        -- Show decorative plant models when something is planted
        setWheatVisibility(plot, true)
        
        -- Light brown dirt for growing crops
        interactionPart.BrickColor = BrickColor.new("Nougat")
        if plantPosition then
            plantPosition.BrickColor = BrickColor.new("Nougat")
        end
        
        -- Show partially grown plant (needs more water) with variation
        WorldBuilder.createPlant(plot, seedType, 1, variation)
        
        -- All plots use the same UI prompt
        actionPrompt.ActionText = "Open Plot UI"
        actionPrompt.Enabled = true
        
    elseif state == "watered" then
        -- Show decorative plant models when something is planted
        setWheatVisibility(plot, true)
        
        -- Darker, moist dirt
        interactionPart.BrickColor = BrickColor.new("Brown")
        if plantPosition then
            plantPosition.BrickColor = BrickColor.new("Brown")
        end
        
        -- Show growing plant with variation
        WorldBuilder.createPlant(plot, seedType, 2, variation)
        
        -- All plots use the same UI prompt
        actionPrompt.ActionText = "Open Plot UI"
        actionPrompt.Enabled = true
        
    elseif state == "ready" then
        -- Show decorative plant models when something is planted
        setWheatVisibility(plot, true)
        
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
        
        -- All plots use the same UI prompt
        actionPrompt.ActionText = "Open Plot UI"
        actionPrompt.Enabled = true
        
    elseif state == "locked" then
        -- Calculate the price for this specific plot first
        local plotIdValue = plot:FindFirstChild("PlotId")
        local globalPlotId = plotIdValue and plotIdValue.Value or 1
        
        -- Convert global plot ID to local plot index (1-10 for each farm)
        local FarmManager = require(script.Parent.modules.FarmManager)
        local farmId, plotIndex = FarmManager.getFarmAndPlotFromGlobalId(globalPlotId)
        
        -- Use the EXACT same pricing formula as PlayerDataManager with rebirth scaling
        local plotPrice = 0
        if plotIndex == 1 then
            plotPrice = 0 -- First plot is free
        else
            local basePrice
            local priceMultiplier
            
            -- Plots 2-10 have increasing prices
            if plotIndex <= 10 then
                basePrice = 50
                priceMultiplier = math.pow(1.3, plotIndex - 2)
            else
                -- Plots beyond 10 cost more
                basePrice = 500
                priceMultiplier = math.pow(1.5, plotIndex - 11)
            end
            
            local baseTotal = basePrice * priceMultiplier
            
            -- Apply rebirth scaling: +0.5x per rebirth (so 10 rebirths = 5x price)
            local rebirths = 0
            if viewingPlayer then
                local PlayerDataManager = require(script.Parent.modules.PlayerDataManager)
                local playerData = PlayerDataManager.getPlayerData(viewingPlayer)
                rebirths = playerData and playerData.rebirths or 0
            end
            local rebirthMultiplier = 1 + (0.5 * rebirths)
            
            plotPrice = math.floor(baseTotal * rebirthMultiplier)
        end
        
        -- Hide decorative wheat models for locked plots
        setWheatVisibility(plot, false)
        
        -- Restore visibility first (in case it was invisible)
        interactionPart.Transparency = 0
        if plantPosition then
            plantPosition.Transparency = 1 -- Keep plant position invisible
        end
        
        -- Restore border if it exists
        local border = interactionPart:FindFirstChild("Border")
        if border then
            border.Transparency = 0
        end
        
        -- Restore countdown display
        local countdownDisplay = interactionPart:FindFirstChild("CountdownDisplay")
        if countdownDisplay then
            countdownDisplay.Enabled = true
        end
        
        -- Show locked plot appearance - bright red to be distinct
        interactionPart.BrickColor = BrickColor.new("Bright red")
        if plantPosition then
            plantPosition.BrickColor = BrickColor.new("Bright red")
        end
        
        -- Remove any existing plant
        local existingPlant = plot:FindFirstChild("Plant")
        if existingPlant then
            existingPlant:Destroy()
        end
        
        -- Remove rebirth effects if transitioning from rebirth_locked state
        local rebirthIndicator = plot:FindFirstChild("RebirthIndicator")
        if rebirthIndicator then
            rebirthIndicator:Destroy()
        end
        
        local mysticalGlow = plot:FindFirstChild("MysticalGlow")
        if mysticalGlow then
            mysticalGlow:Destroy()
        end
        
        local proximityShine = plot:FindFirstChild("ProximityShine")
        if proximityShine then
            proximityShine:Destroy()
        end
        
        -- Only show price to farm owner
        local shouldShowPrice = false
        if viewingPlayer then
            -- Check if viewing player owns this farm
            local FarmManager = require(script.Parent.modules.FarmManager)
            local playerFarmId = FarmManager.getPlayerFarm(viewingPlayer.UserId)
            shouldShowPrice = (playerFarmId == farmId)
        end
        
        -- Create price indicator if it doesn't exist and player should see price
        local lockIndicator = interactionPart:FindFirstChild("LockIndicator")
        
        if not lockIndicator and shouldShowPrice then
            -- Create invisible attachment point for the GUI
            lockIndicator = Instance.new("Part")
            lockIndicator.Name = "LockIndicator"
            lockIndicator.Size = Vector3.new(0.1, 0.1, 0.1)
            lockIndicator.Position = interactionPart.Position + Vector3.new(0, 4, 0)
            lockIndicator.Anchored = true
            lockIndicator.CanCollide = false
            lockIndicator.Transparency = 1 -- Make it invisible
            lockIndicator.Parent = interactionPart
            
            -- Add price display GUI with better scaling
            local priceGui = Instance.new("BillboardGui")
            priceGui.Name = "PriceGui"
            priceGui.Size = getBillboardGuiSize(100, 60) -- Mobile-friendly scaling applied
            priceGui.StudsOffset = Vector3.new(0, 0, 0)
            priceGui.MaxDistance = 50 -- Prevent it from being visible too far away
            priceGui.LightInfluence = 0 -- Always bright
            priceGui.Parent = lockIndicator
            
            -- plotPrice is already calculated above
            
            -- Background frame for better visibility
            local background = Instance.new("Frame")
            background.Size = UDim2.new(1, 0, 1, 0)
            background.Position = UDim2.new(0, 0, 0, 0)
            background.BackgroundTransparency = 1 -- No background
            background.BorderSizePixel = 0
            background.Parent = priceGui
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = background
            
            -- Cash icon (same as TopStats)
            local cashIcon = Instance.new("ImageLabel")
            cashIcon.Name = "CashIcon"
            cashIcon.Size = UDim2.new(0, 24, 0, 24)
            cashIcon.Position = UDim2.new(0, 5, 0.5, -12)
            cashIcon.BackgroundTransparency = 1
            cashIcon.Image = assets["Currency/Cash/Cash Outline 256.png"] or ""
            cashIcon.ImageColor3 = Color3.fromRGB(255, 255, 255) -- White icon
            cashIcon.ScaleType = Enum.ScaleType.Fit
            cashIcon.Parent = background
            
            -- Price text label (positioned next to icon)
            local priceLabel = Instance.new("TextLabel")
            priceLabel.Name = "PriceLabel"
            priceLabel.Size = UDim2.new(1, -35, 1, -10) -- Make room for icon
            priceLabel.Position = UDim2.new(0, 30, 0, 5) -- Start after icon
            priceLabel.BackgroundTransparency = 1
            priceLabel.Text = plotPrice == 0 and "FREE" or NumberFormatter.format(plotPrice)
            priceLabel.TextColor3 = Color3.fromRGB(0, 255, 0) -- Green text
            priceLabel.TextScaled = true
            priceLabel.Font = Enum.Font.SourceSansBold
            priceLabel.TextStrokeTransparency = 0
            priceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0) -- Black outline
            priceLabel.Parent = background
        elseif lockIndicator and not shouldShowPrice then
            -- Hide price indicator from non-owners
            lockIndicator:Destroy()
        elseif lockIndicator and shouldShowPrice then
            -- Update existing price indicator for owner
            local priceGui = lockIndicator:FindFirstChild("PriceGui")
            if priceGui then
                local background = priceGui:FindFirstChild("Frame")
                if background then
                    local priceLabel = background:FindFirstChild("PriceLabel")
                    if priceLabel then
                        priceLabel.Text = plotPrice == 0 and "FREE" or NumberFormatter.format(plotPrice)
                    end
                end
            end
        end
        
        -- Enable action prompt for locked plots to allow purchase
        actionPrompt.ActionText = plotPrice == 0 and "Claim Free Plot" or "Purchase Plot (" .. NumberFormatter.format(plotPrice) .. ")"
        actionPrompt.Enabled = true
        
    elseif state == "rebirth_locked" then
        -- Hide decorative wheat models for rebirth-locked plots
        setWheatVisibility(plot, false)
        
        -- Restore visibility first (in case it was invisible)
        interactionPart.Transparency = 0
        if plantPosition then
            plantPosition.Transparency = 1 -- Keep plant position invisible
        end
        
        -- Restore border if it exists
        local border = interactionPart:FindFirstChild("Border")
        if border then
            border.Transparency = 0
        end
        
        -- Restore countdown display
        local countdownDisplay = interactionPart:FindFirstChild("CountdownDisplay")
        if countdownDisplay then
            countdownDisplay.Enabled = true
        end
        
        -- Show rebirth-locked plot appearance - dark gray to indicate unavailable
        interactionPart.BrickColor = BrickColor.new("Dark stone grey")
        if plantPosition then
            plantPosition.BrickColor = BrickColor.new("Dark stone grey")
        end
        
        -- Remove any existing plant
        local existingPlant = plot:FindFirstChild("Plant")
        if existingPlant then
            existingPlant:Destroy()
        end
        
        -- Remove old lock indicator since these show rebirth requirements
        local lockIndicator = interactionPart:FindFirstChild("LockIndicator")
        if lockIndicator then
            lockIndicator:Destroy()
        end
        
        -- Create rebirth requirement indicator
        local rebirthIndicator = interactionPart:FindFirstChild("RebirthIndicator")
        if not rebirthIndicator then
            rebirthIndicator = Instance.new("Part")
            rebirthIndicator.Name = "RebirthIndicator"
            rebirthIndicator.Size = Vector3.new(0.1, 0.1, 0.1)
            rebirthIndicator.Position = interactionPart.Position + Vector3.new(0, 5.5, 0)
            rebirthIndicator.Anchored = true
            rebirthIndicator.CanCollide = false
            rebirthIndicator.Transparency = 1
            rebirthIndicator.Parent = interactionPart
            
            -- Add rebirth requirement GUI
            local rebirthGui = Instance.new("BillboardGui")
            rebirthGui.Name = "RebirthGui"
            rebirthGui.Size = getBillboardGuiSize(140, 100) -- Mobile-friendly scaling applied
            rebirthGui.StudsOffset = Vector3.new(0, 0, 0)
            rebirthGui.MaxDistance = 50
            rebirthGui.LightInfluence = 0
            rebirthGui.Parent = rebirthIndicator
            
            -- No background frame - just like price displays
            
            -- Rebirth icon using asset
            local rebirthIcon = Instance.new("ImageLabel")
            rebirthIcon.Name = "RebirthIcon"
            rebirthIcon.Size = UDim2.new(0, 30, 0, 30)
            rebirthIcon.Position = UDim2.new(0.5, -15, 0, 5)
            rebirthIcon.BackgroundTransparency = 1
            rebirthIcon.Image = assets["General/Rebirth/Rebirth Outline 256.png"] or ""
            rebirthIcon.ImageColor3 = Color3.fromRGB(255, 215, 0) -- Golden color
            rebirthIcon.ScaleType = Enum.ScaleType.Fit
            rebirthIcon.Parent = rebirthGui
            
            -- Rebirth requirement text - same style as price displays
            local rebirthLabel = Instance.new("TextLabel")
            rebirthLabel.Name = "RebirthLabel"
            rebirthLabel.Size = UDim2.new(1, 0, 0, 60)
            rebirthLabel.Position = UDim2.new(0, 0, 0, 40)
            rebirthLabel.BackgroundTransparency = 1
            rebirthLabel.Text = "REBIRTH " .. requiredRebirth .. "\nREQUIRED"
            rebirthLabel.TextColor3 = Color3.fromRGB(200, 50, 80) -- Darker red text
            rebirthLabel.TextScaled = true
            rebirthLabel.Font = Enum.Font.SourceSansBold
            rebirthLabel.TextStrokeTransparency = 0
            rebirthLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0) -- Black outline
            rebirthLabel.Parent = rebirthGui
        else
            -- Update existing rebirth indicator with new required rebirth
            local rebirthGui = rebirthIndicator:FindFirstChild("RebirthGui")
            if rebirthGui then
                local rebirthLabel = rebirthGui:FindFirstChild("RebirthLabel")
                if rebirthLabel then
                    rebirthLabel.Text = "REBIRTH " .. requiredRebirth .. "\nREQUIRED"
                end
            end
        end
        
        -- Add mystical glow effect
        WorldBuilder.addMysticalGlow(plot)
        
        -- Add proximity-based shine effect
        WorldBuilder.addProximityShine(plot, requiredRebirth)
        
        -- Show rebirth requirement message
        actionPrompt.ActionText = "Requires Rebirth " .. requiredRebirth
        actionPrompt.Enabled = false -- Can't purchase yet
        
    elseif state == "invisible" then
        -- Hide decorative wheat models for invisible plots
        setWheatVisibility(plot, false)
        
        -- Make plot completely invisible - future rebirth tiers
        -- Hide the entire plot by making it non-existent visually
        interactionPart.Transparency = 1
        interactionPart.CanCollide = false
        interactionPart.CanTouch = false
        
        if plantPosition then
            plantPosition.Transparency = 1
            plantPosition.CanCollide = false
        end
        
        -- Hide all child parts recursively
        for _, child in pairs(plot:GetChildren()) do
            if child:IsA("BasePart") then
                child.Transparency = 1
                child.CanCollide = false
                child.CanTouch = false
            elseif child:IsA("SurfaceGui") or child:IsA("BillboardGui") then
                child.Enabled = false
            end
        end
        
        -- Hide border if it exists
        local border = plot:FindFirstChild("Border")
        if border then
            border.Transparency = 1
            border.CanCollide = false
        end
        
        -- Remove any existing plant
        local existingPlant = plot:FindFirstChild("Plant")
        if existingPlant then
            existingPlant:Destroy()
        end
        
        -- Remove all UI elements
        local lockIndicator = interactionPart:FindFirstChild("LockIndicator")
        if lockIndicator then
            lockIndicator:Destroy()
        end
        
        local countdownDisplay = interactionPart:FindFirstChild("CountdownDisplay")
        if countdownDisplay then
            countdownDisplay.Enabled = false
        end
        
        -- Disable interaction completely
        actionPrompt.Enabled = false
        actionPrompt.ActionText = ""
        actionPrompt.MaxActivationDistance = 0
        
    -- Dead state removed - plants no longer die
    end
    
    -- Water hose removed - watering is now handled through Plot UI
end

-- Water hose functionality removed - watering is now handled through the Plot UI
function WorldBuilder.updateWaterHoseVisibility(plot, state)
    -- Deprecated function - kept for compatibility
end

-- Build the entire farm world with individual player farm areas
function WorldBuilder.buildFarm()
    log.info("🏗️ FARM SYSTEM: Building individual player farm areas - START")
    
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
        log.info("Creating farm", farmId, "of", config.totalFarms)
        local farmFolder
        
        if USE_TEMPLATE_FARM then
            -- Use template system
            local FarmManager = require(script.Parent.modules.FarmManager)
            local farmPosition = FarmManager.getFarmPosition(farmId)
            log.debug("🏗️ FARM SYSTEM: Creating template farm", farmId, "at position", farmPosition)
            farmFolder = createFarmFromTemplate(farmId, farmPosition)
            if farmFolder then
                farmFolder.Parent = farmsContainer
                -- Count actual plots in template
                local plotCount = 0
                for _, child in ipairs(farmFolder:GetDescendants()) do
                    if child.Name:match("Plot") and child:IsA("BasePart") then
                        plotCount = plotCount + 1
                    end
                end
                totalPlotsCreated = totalPlotsCreated + plotCount
                log.info("Successfully created farm", farmId, "with", plotCount, "plots")
            else
                log.error("Failed to create template farm", farmId)
            end
        else
            -- Use original code generation
            farmFolder = WorldBuilder.createIndividualFarm(farmId, config)
            farmFolder.Parent = farmsContainer
            if farmFolder then
                totalPlotsCreated = totalPlotsCreated + config.maxPlotsPerFarm
            end
        end
    end
    
    log.info("🏗️ FARM SYSTEM: Built", config.totalFarms, "individual farms with", totalPlotsCreated, "total plots! - COMPLETE")
    return farmsContainer
end

-- Debug function to recreate farms
function WorldBuilder.recreateFarms()
    log.warn("🔧 DEBUG: Recreating all farms...")
    return WorldBuilder.buildFarm()
end

-- Simple function to fix farm spawn positions to match baseplate level
function WorldBuilder.fixFarmSpawnPositions()
    -- Find baseplate level
    local groundLevel = 0.5 -- Default
    local baseplate = Workspace:FindFirstChild("Baseplate")
    if baseplate then
        groundLevel = baseplate.Position.Y + (baseplate.Size.Y / 2)
        log.warn("🔧 FIX SPAWNS: Found baseplate at Y level:", groundLevel)
    else
        log.warn("🔧 FIX SPAWNS: No baseplate found, using default:", groundLevel)
    end
    
    -- Find all farms and fix their spawn positions
    local playerFarms = Workspace:FindFirstChild("PlayerFarms")
    if not playerFarms then
        log.warn("🔧 FIX SPAWNS: No PlayerFarms folder found")
        return
    end
    
    local fixed = 0
    for _, farmFolder in pairs(playerFarms:GetChildren()) do
        if farmFolder.Name:match("^Farm_") then
            -- Find the farm spawn
            for _, child in pairs(farmFolder:GetChildren()) do
                if child.Name:match("^FarmSpawn_") and child:IsA("SpawnLocation") then
                    local oldY = child.Position.Y
                    local newY = groundLevel + 0.5 -- Spawn slightly above ground
                    child.Position = Vector3.new(child.Position.X, newY, child.Position.Z)
                    log.warn("🔧 FIX SPAWNS: Fixed", child.Name, "from Y:", oldY, "to Y:", newY)
                    fixed = fixed + 1
                end
            end
        end
    end
    
    log.warn("🔧 FIX SPAWNS: Fixed", fixed, "farm spawn positions")
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
    
    -- Create plots in a 4x4 grid within the farm (16 max plots)
    local globalPlotId = (farmId - 1) * config.maxPlotsPerFarm + 1
    for row = 1, 4 do
        for col = 1, 4 do
            local plotIndex = (row - 1) * 4 + col
            local plotOffsetX = (col - 2.5) * (PLOT_SIZE.X + PLOT_SPACING) -- Center the 4x4 grid
            local plotOffsetZ = (row - 2.5) * (PLOT_SIZE.Z + PLOT_SPACING)
            local plotPosition = farmPosition + Vector3.new(plotOffsetX, PLOT_SIZE.Y / 2, plotOffsetZ)
            
            local plot = createFarmPlot(plotPosition, globalPlotId)
            plot.Parent = farmFolder
            
            globalPlotId = globalPlotId + 1
        end
    end
    
    log.debug("Created farm", farmId, "at position", farmPosition, "with", config.maxPlotsPerFarm, "plots")
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

-- Create a sign for the farm with character display capability
function WorldBuilder.createFarmSign(farmFolder, farmPosition, farmId)
    -- Create invisible character display area
    local characterDisplay = Instance.new("Part")
    characterDisplay.Name = "CharacterDisplay"
    characterDisplay.Size = Vector3.new(15, 20, 5) -- Big display area for character
    characterDisplay.Position = farmPosition + Vector3.new(0, 100, 0) -- Much higher above farm
    characterDisplay.Anchored = true
    characterDisplay.Transparency = 1 -- Completely invisible
    characterDisplay.CanCollide = false
    characterDisplay.Parent = farmFolder
    
    -- Create farm name display
    local nameDisplay = Instance.new("Part")
    nameDisplay.Name = "FarmNameDisplay"
    nameDisplay.Size = Vector3.new(0.1, 0.1, 0.1) -- Small invisible part for GUI
    nameDisplay.Position = farmPosition + Vector3.new(0, 120, 0) -- Above character display
    nameDisplay.Anchored = true
    nameDisplay.Transparency = 1
    nameDisplay.CanCollide = false
    nameDisplay.Parent = farmFolder
    
    local nameGui = Instance.new("BillboardGui")
    nameGui.Name = "FarmNameGui"
    nameGui.Size = getBillboardGuiSize(200, 40) -- Mobile-friendly scaling applied
    nameGui.StudsOffset = Vector3.new(0, 0, 0)
    nameGui.MaxDistance = 100  -- Default for available farms
    nameGui.LightInfluence = 0
    nameGui.Parent = nameDisplay
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "FarmNameLabel"
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = "Available Farm"
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextStrokeTransparency = 0
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
function WorldBuilder.getPlotById(globalPlotId)
    local farmsContainer = Workspace:FindFirstChild("PlayerFarms")
    if not farmsContainer then return nil end
    
    -- Convert global plot ID to farm ID and local plot ID
    local FarmManager = require(script.Parent.modules.FarmManager)
    local farmId, localPlotId = FarmManager.getFarmAndPlotFromGlobalId(globalPlotId)
    
    -- Find the specific farm
    local farmFolder = farmsContainer:FindFirstChild("Farm_" .. farmId)
    if not farmFolder then return nil end
    
    -- Search through all objects in the farm looking for the right PlotId value
    -- Look for both BasePart (old plots) and Model (new plots)
    for _, child in pairs(farmFolder:GetDescendants()) do
        if (child:IsA("BasePart") or child:IsA("Model")) and child.Name:match("Plot") then
            local plotIdValue = child:FindFirstChild("PlotId")
            if plotIdValue and plotIdValue.Value == localPlotId then
                return child
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


-- Update only the farm nameplate text without touching character display
function WorldBuilder.updateFarmNameOnly(farmId, playerName, player)
    local farmsContainer = Workspace:FindFirstChild("PlayerFarms")
    if not farmsContainer then return end
    
    local farmFolder = farmsContainer:FindFirstChild("Farm_" .. farmId)
    if not farmFolder then return end
    
    -- Update farm name display ONLY (don't touch character)
    local nameDisplay = farmFolder:FindFirstChild("FarmNameDisplay")
    if nameDisplay then
        local nameGui = nameDisplay:FindFirstChild("FarmNameGui")
        if nameGui then
            local nameLabel = nameGui:FindFirstChild("FarmNameLabel")
            if nameLabel then
                if playerName and player then
                    -- Get player's rank information
                    local PlayerDataManager = require(script.Parent.modules.PlayerDataManager)
                    local RankConfig = require(game:GetService("ReplicatedStorage").Shared.RankConfig)
                    
                    local playerData = PlayerDataManager.getPlayerData(player)
                    
                    if playerData then
                        local rebirths = playerData.rebirths or 0
                        local rankInfo = RankConfig.getRankForRebirths(rebirths)
                        
                        -- Set farm name on first line, rank on second line
                        nameLabel.Text = playerName .. "'s Farm\n" .. rankInfo.name
                        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
                    else
                        nameLabel.Text = playerName .. "'s Farm"
                        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
                    end
                    
                    nameGui.MaxDistance = 250  -- Occupied farms visible from further away
                else
                    nameLabel.Text = "Available Farm"
                    nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200) -- Gray for available
                    nameGui.MaxDistance = 100  -- Available farms only visible when closer
                end
            end
        end
    end
end

-- Update farm sign to show ownership with character display and farm name
function WorldBuilder.updateFarmSign(farmId, playerName, player)
    local farmsContainer = Workspace:FindFirstChild("PlayerFarms")
    if not farmsContainer then return end
    
    local farmFolder = farmsContainer:FindFirstChild("Farm_" .. farmId)
    if not farmFolder then return end
    
    -- Update character display
    local characterDisplay = farmFolder:FindFirstChild("CharacterDisplay")
    if characterDisplay then
        if player then
            -- Create 3D character model if player is provided
            WorldBuilder.createPlayerCharacterDisplay(characterDisplay, player, farmId)
        else
            -- Remove character model when no player
            WorldBuilder.clearCharacterDisplay(characterDisplay)
        end
    end
    
    -- Update farm name display
    local nameDisplay = farmFolder:FindFirstChild("FarmNameDisplay")
    if nameDisplay then
        local nameGui = nameDisplay:FindFirstChild("FarmNameGui")
        if nameGui then
            local nameLabel = nameGui:FindFirstChild("FarmNameLabel")
            if nameLabel then
                if playerName and player then
                    -- Get player's rank information
                    local PlayerDataManager = require(script.Parent.modules.PlayerDataManager)
                    local RankConfig = require(game:GetService("ReplicatedStorage").Shared.RankConfig)
                    
                    local playerData = PlayerDataManager.getPlayerData(player)
                    
                    if playerData then
                        local rebirths = playerData.rebirths or 0
                        local rankInfo = RankConfig.getRankForRebirths(rebirths)
                        
                        -- Set farm name on first line, rank on second line
                        nameLabel.Text = playerName .. "'s Farm\n" .. rankInfo.name
                        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
                    else
                        nameLabel.Text = playerName .. "'s Farm"
                        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
                    end
                    
                    nameGui.MaxDistance = 250  -- Occupied farms visible from further away
                else
                    nameLabel.Text = "Available Farm"
                    nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200) -- Gray for available
                    nameGui.MaxDistance = 100  -- Available farms only visible when closer
                end
            end
        end
    end
    
    if playerName and player then
        local PlayerDataManager = require(script.Parent.modules.PlayerDataManager)
        local playerData = PlayerDataManager.getPlayerData(player)
        if playerData then
            local RankConfig = require(game:GetService("ReplicatedStorage").Shared.RankConfig)
            local rebirths = playerData.rebirths or 0
            local rankInfo = RankConfig.getRankForRebirths(rebirths)
            log.info("🏠 Updated farm", farmId, "nameplate for", playerName, "with rank:", rankInfo.name)
        else
            log.warn("🏠 No player data found when updating farm nameplate for", playerName)
        end
    else
        log.debug("🏠 Updated farm", farmId, "display:", playerName or "Available")
    end
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
                elseif obj:IsA("Accessory") then
                    table.insert(accessories, obj)
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
        WorldBuilder.createSimpleCharacterDisplay(characterDisplay, player, farmId)
        
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
    
    -- FALLBACK TELEPORTATION: When character display is created, also teleport the real player
    log.info("🎯 FALLBACK TELEPORTATION: Character display created for", player.Name, "- Teleporting real player to farm", farmId)
    
    -- Find the real player character and teleport them to their assigned farm
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local farmModel = workspace.PlayerFarms:FindFirstChild("Farm_" .. farmId)
        if farmModel then
            local farmSpawn = farmModel:FindFirstChild("FarmSpawn_" .. farmId)
            if farmSpawn then
                local humanoidRootPart = player.Character.HumanoidRootPart
                local currentPos = humanoidRootPart.Position
                local targetPos = farmSpawn.Position
                local distance = (currentPos - targetPos).Magnitude
                
                if distance > 20 then -- Only teleport if they're far from their farm
                    humanoidRootPart.CFrame = farmSpawn.CFrame + Vector3.new(0, 3, 0)
                    log.info("🎯 TELEPORTED REAL PLAYER", player.Name, "to farm", farmId, "spawn (was", distance, "studs away)")
                else
                    log.info("🎯 Player", player.Name, "already close to farm", farmId, "spawn (", distance, "studs away)")
                end
            else
                log.warn("⚠️ Could not teleport", player.Name, "- No spawn point found for farm", farmId)
            end
        else
            log.warn("⚠️ Could not teleport", player.Name, "- Farm", farmId, "not found")
        end
    else
        log.info("ℹ️ Player", player.Name, "character not ready for teleportation yet")
    end
end

-- Create a simplified character display as fallback
function WorldBuilder.createSimpleCharacterDisplay(characterDisplay, player, farmId)
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
    
    -- FALLBACK TELEPORTATION: When simple character display is created, also teleport the real player
    if farmId then
        log.info("🎯 FALLBACK TELEPORTATION (Simple): Character display created for", player.Name, "- Teleporting real player to farm", farmId)
        
        -- Find the real player character and teleport them to their assigned farm
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local farmModel = workspace.PlayerFarms:FindFirstChild("Farm_" .. farmId)
            if farmModel then
                local farmSpawn = farmModel:FindFirstChild("FarmSpawn_" .. farmId)
                if farmSpawn then
                    local humanoidRootPart = player.Character.HumanoidRootPart
                    local currentPos = humanoidRootPart.Position
                    local targetPos = farmSpawn.Position
                    local distance = (currentPos - targetPos).Magnitude
                    
                    if distance > 20 then -- Only teleport if they're far from their farm
                        humanoidRootPart.CFrame = farmSpawn.CFrame + Vector3.new(0, 3, 0)
                        log.info("🎯 TELEPORTED REAL PLAYER (Simple)", player.Name, "to farm", farmId, "spawn (was", distance, "studs away)")
                    else
                        log.info("🎯 Player", player.Name, "already close to farm", farmId, "spawn (", distance, "studs away)")
                    end
                else
                    log.warn("⚠️ Could not teleport", player.Name, "- No spawn point found for farm", farmId)
                end
            else
                log.warn("⚠️ Could not teleport", player.Name, "- Farm", farmId, "not found")
            end
        else
            log.info("ℹ️ Player", player.Name, "character not ready for teleportation yet")
        end
    end
end

-- Clear character display
function WorldBuilder.clearCharacterDisplay(characterDisplay)
    local existingModel = characterDisplay:FindFirstChild("PlayerDisplay")
    if existingModel then
        existingModel:Destroy()
    end
end

-- Add mystical glow effect to next-tier plots
function WorldBuilder.addMysticalGlow(plot)
    -- Remove existing glow if any
    local existingGlow = plot:FindFirstChild("MysticalGlow")
    if existingGlow then
        existingGlow:Destroy()
    end
    
    -- Get the interaction part for positioning (works for both Parts and Models)
    local interactionPart = plot
    if plot:IsA("Model") then
        if plot.PrimaryPart then
            interactionPart = plot.PrimaryPart
        else
            -- Fallback: look for PlotBase or similar
            local basePart = plot:FindFirstChild("PlotBase") or plot:FindFirstChild("Core") or plot:FindFirstChild("Base")
            if basePart and basePart:IsA("BasePart") then
                interactionPart = basePart
            else
                -- Final fallback: find first Part
                for _, child in pairs(plot:GetChildren()) do
                    if child:IsA("BasePart") then
                        interactionPart = child
                        break
                    end
                end
            end
        end
    end
    
    -- Create mystical glow effect
    local glowPart = Instance.new("Part")
    glowPart.Name = "MysticalGlow"
    glowPart.Size = interactionPart.Size + Vector3.new(1, 0.2, 1) -- Slightly larger than plot
    glowPart.Position = interactionPart.Position + Vector3.new(0, 0.1, 0)
    glowPart.Anchored = true
    glowPart.CanCollide = false
    glowPart.Material = Enum.Material.ForceField
    glowPart.BrickColor = BrickColor.new("Bright yellow")
    glowPart.Transparency = 0.7
    glowPart.Parent = plot
    
    -- Add pulsing effect
    spawn(function()
        while glowPart.Parent do
            for i = 0.7, 0.9, 0.05 do
                if not glowPart.Parent then break end
                glowPart.Transparency = i
                wait(0.1)
            end
            for i = 0.9, 0.7, -0.05 do
                if not glowPart.Parent then break end
                glowPart.Transparency = i
                wait(0.1)
            end
        end
    end)
    
    -- Add light source for extra effect
    local pointLight = Instance.new("PointLight")
    pointLight.Color = Color3.fromRGB(255, 215, 0)
    pointLight.Brightness = 1
    pointLight.Range = 15
    pointLight.Parent = glowPart
end

-- Add proximity-based shine effect
function WorldBuilder.addProximityShine(plot, requiredRebirth)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    
    -- Get the interaction part for positioning (works for both Parts and Models)
    local interactionPart = plot
    if plot:IsA("Model") then
        if plot.PrimaryPart then
            interactionPart = plot.PrimaryPart
        else
            -- Fallback: look for PlotBase or similar
            local basePart = plot:FindFirstChild("PlotBase") or plot:FindFirstChild("Core") or plot:FindFirstChild("Base")
            if basePart and basePart:IsA("BasePart") then
                interactionPart = basePart
            else
                -- Final fallback: find first Part
                for _, child in pairs(plot:GetChildren()) do
                    if child:IsA("BasePart") then
                        interactionPart = child
                        break
                    end
                end
            end
        end
    end
    
    -- Create shine effect (initially hidden)
    local shinePart = Instance.new("Part")
    shinePart.Name = "ProximityShine"
    shinePart.Size = interactionPart.Size + Vector3.new(0.5, 1, 0.5)
    shinePart.Position = interactionPart.Position + Vector3.new(0, 0.5, 0)
    shinePart.Anchored = true
    shinePart.CanCollide = false
    shinePart.Material = Enum.Material.Neon
    shinePart.BrickColor = BrickColor.new("Bright yellow")
    shinePart.Transparency = 1 -- Start hidden
    shinePart.Parent = plot
    
    -- Add particles for extra effect
    local attachment = Instance.new("Attachment")
    attachment.Position = Vector3.new(0, 0, 0)
    attachment.Parent = shinePart
    
    local particles = Instance.new("ParticleEmitter")
    particles.Name = "ShineParticles"
    particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    particles.Lifetime = NumberRange.new(1.0, 2.0)
    particles.Rate = 0 -- Start with no particles
    particles.SpreadAngle = Vector2.new(45, 45)
    particles.Speed = NumberRange.new(2, 5)
    particles.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
    particles.Size = NumberSequence.new(0.2)
    particles.Parent = attachment
    
    -- Proximity detection
    local proximityConnection
    proximityConnection = RunService.Heartbeat:Connect(function()
        if not plot.Parent then
            proximityConnection:Disconnect()
            return
        end
        
        local nearbyPlayer = nil
        local closestDistance = math.huge
        
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local distance = (player.Character.HumanoidRootPart.Position - interactionPart.Position).Magnitude
                if distance < 20 and distance < closestDistance then -- Within 20 studs
                    nearbyPlayer = player
                    closestDistance = distance
                end
            end
        end
        
        if nearbyPlayer and closestDistance < 20 then
            -- Player is nearby - show shine effect
            local intensity = 1 - (closestDistance / 20) -- Closer = more intense
            shinePart.Transparency = 0.3 + (0.4 * intensity) -- 0.3 to 0.7 transparency
            particles.Rate = math.floor(50 * intensity) -- 0 to 50 particles
        else
            -- No player nearby - hide effect
            shinePart.Transparency = 1
            particles.Rate = 0
        end
    end)
end

-- Set up Portal UI with rebirth requirement text
function WorldBuilder.setupPortalUI(farm, farmId)
    -- Look for Portal part in the farm template structure
    local portalPart = nil
    
    -- Search for Portal part in ParallaxPortal/Instances/Portal model/Portal
    local parallaxPortal = farm:FindFirstChild("ParallaxPortal")
    if parallaxPortal then
        local instances = parallaxPortal:FindFirstChild("Instances")
        if instances then
            local portalModel = instances:FindFirstChild("Portal model")
            if portalModel then
                portalPart = portalModel:FindFirstChild("Portal")
            end
        end
    end
    
    -- If not found, try to find any part named "Portal" anywhere in the farm
    if not portalPart then
        for _, child in ipairs(farm:GetDescendants()) do
            if child:IsA("BasePart") and child.Name == "Portal" then
                portalPart = child
                break
            end
        end
    end
    
    if not portalPart then
        log.debug("No Portal part found in farm", farmId, "- skipping Portal UI setup")
        return
    end
    
    log.info("Setting up Portal UI for farm", farmId, "on part:", portalPart.Name)
    
    -- Remove any existing Portal indicator
    local existingIndicator = portalPart:FindFirstChild("PortalIndicator")
    if existingIndicator then
        existingIndicator:Destroy()
    end
    
    -- Create Portal requirement indicator (same as rebirth plots)
    local portalIndicator = Instance.new("Part")
    portalIndicator.Name = "PortalIndicator"
    portalIndicator.Size = Vector3.new(0.1, 0.1, 0.1)
    portalIndicator.Position = portalPart.Position + Vector3.new(0, 5, 0) -- Above the portal
    portalIndicator.Anchored = true
    portalIndicator.CanCollide = false
    portalIndicator.Transparency = 1
    portalIndicator.Parent = portalPart
    
    -- Add Portal requirement GUI (same style as rebirth requirement)
    local portalGui = Instance.new("BillboardGui")
    portalGui.Name = "PortalGui"
    portalGui.Size = getBillboardGuiSize(160, 100) -- Mobile-friendly scaling applied
    portalGui.StudsOffset = Vector3.new(0, 0, 0)
    portalGui.MaxDistance = 50
    portalGui.LightInfluence = 0
    portalGui.Parent = portalIndicator
    
    -- Portal icon (use rebirth icon for now, or create a portal-specific one)
    local portalIcon = Instance.new("ImageLabel")
    portalIcon.Name = "PortalIcon"
    portalIcon.Size = UDim2.new(0, 30, 0, 30)
    portalIcon.Position = UDim2.new(0.5, -15, 0, 5)
    portalIcon.BackgroundTransparency = 1
    portalIcon.Image = assets["General/Rebirth/Rebirth Outline 256.png"] or "" -- Using rebirth icon for now
    portalIcon.ImageColor3 = Color3.fromRGB(255, 215, 0) -- Golden color
    portalIcon.ScaleType = Enum.ScaleType.Fit
    portalIcon.Parent = portalGui
    
    -- Portal requirement text - same style as rebirth requirement
    local portalLabel = Instance.new("TextLabel")
    portalLabel.Name = "PortalLabel"
    portalLabel.Size = UDim2.new(1, 0, 0, 60)
    portalLabel.Position = UDim2.new(0, 0, 0, 40)
    portalLabel.BackgroundTransparency = 1
    portalLabel.Text = "THE EXCITING BARN! \nUNLOCKS AT\n30 REBIRTHS!"
    portalLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Golden color like rebirth
    portalLabel.TextScaled = true
    portalLabel.Font = Enum.Font.SourceSansBold
    portalLabel.TextStrokeTransparency = 0
    portalLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0) -- Black outline
    portalLabel.Parent = portalGui
    
    log.info("Portal UI setup complete for farm", farmId)
end

return WorldBuilder