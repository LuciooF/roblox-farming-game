-- Farm Environment Module
-- Creates beautiful farm environments with trees, decorations, and structures

local Logger = require(script.Parent.Logger)
local log = Logger.getModuleLogger("FarmEnvironment")

local FarmEnvironment = {}

-- Environment configuration
local ENVIRONMENT_CONFIG = {
    -- Trees
    trees = {
        {type = "oak", model = 1330647122, scale = 1.2, color = Color3.fromRGB(91, 154, 76)},
        {type = "pine", model = 1330650651, scale = 1.0, color = Color3.fromRGB(76, 142, 61)},
        {type = "apple", model = 13822628710, scale = 0.8, color = Color3.fromRGB(91, 154, 76)}
    },
    
    -- Decorative elements
    decorations = {
        {type = "rock", model = 1330647498, scale = 0.8, color = Color3.fromRGB(120, 120, 120)},
        {type = "flower", model = 1330648198, scale = 0.6, color = Color3.fromRGB(255, 100, 150)},
        {type = "grass", model = 13822569200, scale = 0.5, color = Color3.fromRGB(91, 154, 76)}
    },
    
    -- Structures
    structures = {
        {type = "fence", model = 1330649142, scale = 1.0, color = Color3.fromRGB(139, 69, 19)},
        {type = "gate", model = 1330649500, scale = 1.2, color = Color3.fromRGB(139, 69, 19)},
        {type = "barn", model = 13822570305, scale = 1.5, color = Color3.fromRGB(139, 69, 19)}
    }
}

-- Create a tree at specified position
local function createTree(position, treeType, farmFolder)
    local treeConfig = ENVIRONMENT_CONFIG.trees[1] -- Default to oak
    for _, tree in ipairs(ENVIRONMENT_CONFIG.trees) do
        if tree.type == treeType then
            treeConfig = tree
            break
        end
    end
    
    -- Create trunk
    local trunk = Instance.new("Part")
    trunk.Name = "TreeTrunk_" .. treeType
    trunk.Size = Vector3.new(2, 14, 2) * treeConfig.scale -- Thinner and taller trunk
    trunk.Material = Enum.Material.Wood
    trunk.BrickColor = BrickColor.new("Brown")
    trunk.Position = position + Vector3.new(0, 7 * treeConfig.scale, 0) -- Half height above ground
    trunk.Anchored = true
    trunk.CanCollide = true
    trunk.Parent = farmFolder
    
    log.debug("Created tree trunk at", trunk.Position, "with size", trunk.Size)
    
    -- Don't add mesh to trunk - keep it as simple part
    
    -- Add leaves
    local leaves = Instance.new("Part")
    leaves.Name = "TreeLeaves_" .. treeType
    leaves.Size = Vector3.new(12, 10, 12) * treeConfig.scale -- Bigger leaves
    leaves.Position = position + Vector3.new(0, 15 * treeConfig.scale, 0) -- Higher on top of trunk
    leaves.Material = Enum.Material.Grass
    leaves.Color = treeConfig.color
    leaves.Anchored = true
    leaves.CanCollide = false
    leaves.Shape = Enum.PartType.Ball
    leaves.Parent = farmFolder
    
    return trunk
end

-- Create decorative elements
local function createDecoration(position, decorationType, farmFolder)
    local decorConfig = ENVIRONMENT_CONFIG.decorations[1] -- Default
    for _, decor in ipairs(ENVIRONMENT_CONFIG.decorations) do
        if decor.type == decorationType then
            decorConfig = decor
            break
        end
    end
    
    local decoration = Instance.new("Part")
    decoration.Name = "Decoration_" .. decorationType
    decoration.Size = Vector3.new(1, 1, 1) * decorConfig.scale
    decoration.Position = position
    decoration.Anchored = true
    decoration.CanCollide = false
    decoration.Color = decorConfig.color
    decoration.Parent = farmFolder
    
    if decorationType == "rock" then
        decoration.Material = Enum.Material.Rock
        decoration.Shape = Enum.PartType.Ball
    elseif decorationType == "flower" then
        decoration.Material = Enum.Material.Neon
        decoration.Shape = Enum.PartType.Cylinder
        decoration.Size = Vector3.new(0.2, 0.8, 0.2)
    end
    
    return decoration
end

-- Create farm pathway
local function createPathway(startPos, endPos, farmFolder)
    local distance = (endPos - startPos).Magnitude
    local direction = (endPos - startPos).Unit
    local pathWidth = 6
    
    for i = 0, distance, 2 do
        local pathPart = Instance.new("Part")
        pathPart.Name = "Pathway"
        pathPart.Size = Vector3.new(pathWidth, 0.2, 2)
        pathPart.Position = startPos + direction * i
        pathPart.Material = Enum.Material.Concrete
        pathPart.Color = Color3.fromRGB(180, 180, 160)
        pathPart.Anchored = true
        pathPart.CanCollide = false
        pathPart.Parent = farmFolder
    end
end

-- Create entrance gate
local function createEntrance(position, farmFolder, ownerName)
    -- Calculate rotation to face AWAY from center (into the farm)
    local directionFromCenter = (position - Vector3.new(0, position.Y, 0)).Unit
    local rotation = CFrame.lookAt(position, position + directionFromCenter)
    
    -- Gate posts (taller)
    for i = -1, 1, 2 do
        local post = Instance.new("Part")
        post.Name = "GatePost"
        post.Size = Vector3.new(1.5, 12, 1.5)
        post.CFrame = rotation * CFrame.new(i * 5, 6, 0)
        post.Material = Enum.Material.Wood
        post.BrickColor = BrickColor.new("Brown")
        post.Anchored = true
        post.CanCollide = true
        post.Parent = farmFolder
    end
    
    -- Gate arch (higher and wider)
    local arch = Instance.new("Part")
    arch.Name = "GateArch"
    arch.Size = Vector3.new(12, 1.5, 1.5)
    arch.CFrame = rotation * CFrame.new(0, 11, 0)
    arch.Material = Enum.Material.Wood
    arch.BrickColor = BrickColor.new("Brown")
    arch.Anchored = true
    arch.CanCollide = false
    arch.Parent = farmFolder
    
    -- Farm sign (bigger and higher)
    local sign = Instance.new("Part")
    sign.Name = "FarmSign"
    sign.Size = Vector3.new(8, 3, 0.2)
    sign.CFrame = rotation * CFrame.new(0, 9, 0)
    sign.Material = Enum.Material.Wood
    sign.BrickColor = BrickColor.new("Bright yellow")
    sign.Anchored = true
    sign.CanCollide = false
    sign.Parent = farmFolder
    
    -- Sign text
    local signText = Instance.new("SurfaceGui")
    signText.Face = Enum.NormalId.Front
    signText.Parent = sign
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = ownerName and (ownerName .. "'s Farm") or "🌾 FARM 🌾"
    textLabel.TextColor3 = Color3.fromRGB(139, 69, 19)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.Antique
    textLabel.Parent = signText
end

-- Create farm building (barn/farmhouse)
local function createFarmBuilding(position, buildingType, farmFolder)
    local building = Instance.new("Part")
    building.Name = "FarmBuilding_" .. buildingType
    building.Size = Vector3.new(12, 8, 8)
    building.Position = position
    building.Material = Enum.Material.Wood
    building.BrickColor = BrickColor.new("Brown")
    building.Anchored = true
    building.CanCollide = true
    building.Parent = farmFolder
    
    -- Roof
    local roof = Instance.new("WedgePart")
    roof.Name = "Roof"
    roof.Size = Vector3.new(8, 4, 14)
    roof.Position = position + Vector3.new(0, 6, 0)
    roof.Material = Enum.Material.Slate
    roof.BrickColor = BrickColor.new("Really red")
    roof.Anchored = true
    roof.CanCollide = false
    roof.Parent = farmFolder
    
    -- Door
    local door = Instance.new("Part")
    door.Name = "Door"
    door.Size = Vector3.new(3, 6, 0.2)
    door.Position = position + Vector3.new(0, -1, 4)
    door.Material = Enum.Material.Wood
    door.BrickColor = BrickColor.new("Dark brown")
    door.Anchored = true
    door.CanCollide = false
    door.Parent = farmFolder
    
    return building
end

-- Enhance a single farm with environmental decorations
function FarmEnvironment.enhanceFarm(farmId)
    local workspace = game:GetService("Workspace")
    local playerFarms = workspace:FindFirstChild("PlayerFarms")
    if not playerFarms then
        log.warn("PlayerFarms folder not found")
        return false
    end
    
    local farmFolder = playerFarms:FindFirstChild("Farm_" .. farmId)
    if not farmFolder then
        log.warn("Farm", farmId, "not found")
        return false
    end
    
    log.info("Enhancing farm", farmId, "with environment decorations...")
    
    -- Get owner info first
    local FarmManager = require(script.Parent.FarmManager)
    local ownerId, ownerName = FarmManager.getFarmOwner(farmId)
    
    -- Calculate actual farm center from plots
    local farmCenter = Vector3.new(0, 0, 0)
    local plotCount = 0
    for _, child in ipairs(farmFolder:GetChildren()) do
        if child.Name:match("^FarmPlot_") and child:IsA("Model") then
            local plotPart = child:FindFirstChild("Plot")
            if plotPart then
                farmCenter = farmCenter + plotPart.Position
                plotCount = plotCount + 1
            end
        end
    end
    if plotCount > 0 then
        farmCenter = farmCenter / plotCount
    end
    
    -- Find spawn point
    local spawnPoint = farmFolder:FindFirstChild("FarmSpawn_" .. farmId)
    local entrancePosition = farmCenter -- default
    
    -- Hardcode entrance positions based on farm layout
    log.info("Setting entrance for farm", farmId, "at center", farmCenter)
    
    if farmId == 1 then
        -- Farm 1: entrance on right side (east edge)
        entrancePosition = farmCenter + Vector3.new(45, 0, 0)
        log.info("Farm 1: entrance on RIGHT SIDE")
    elseif farmId == 2 or farmId == 3 then
        -- Farms 2,3: entrance on bottom (south edge)
        entrancePosition = farmCenter + Vector3.new(0, 0, -45)
        log.info("Farm", farmId, ": entrance on BOTTOM")
    elseif farmId == 4 then
        -- Farm 4: entrance on left side (west edge)
        entrancePosition = farmCenter + Vector3.new(-45, 0, 0)
        log.info("Farm 4: entrance on LEFT SIDE")
    elseif farmId == 5 or farmId == 6 then
        -- Farms 5,6: entrance on top (north edge)
        entrancePosition = farmCenter + Vector3.new(0, 0, 45)
        log.info("Farm", farmId, ": entrance on TOP")
    end
    
    log.info("Final entrance position:", entrancePosition)
    
    if true then -- Always create entrance
        
        -- Remove ALL existing environment elements to force fresh rebuild
        local elementsToRemove = {
            "FarmEntrance", "WelcomeSignBoard", "WelcomeSignPost",
            "GatePost", "GateArch", "FarmSign", "TreeTrunk_oak", "TreeTrunk_pine", "TreeTrunk_apple",
            "TreeLeaves_oak", "TreeLeaves_pine", "TreeLeaves_apple",
            "Decoration_rock", "Decoration_flower", "Decoration_grass",
            "Pathway", "FarmNameDisplay"
        }
        
        for _, elementName in ipairs(elementsToRemove) do
            local element = farmFolder:FindFirstChild(elementName)
            if element then
                element:Destroy()
                log.debug("Removed existing", elementName)
            end
        end
        
        -- Also remove by pattern matching
        for _, child in ipairs(farmFolder:GetChildren()) do
            if child.Name:match("^Tree") or child.Name:match("^Decoration") or 
               child.Name:match("^Gate") or child.Name:match("^Farm") or
               child.Name:match("^Pathway") then
                child:Destroy()
                log.debug("Removed existing element:", child.Name)
            end
        end
        
        -- DON'T move spawn point - it breaks the entire spawning system
        -- Just use the hardcoded entrance position calculated above
        
        -- Create new entrance at the calculated position
        createEntrance(entrancePosition, farmFolder, ownerName)
    end
    
    local farmSize = 50 -- Approximate farm size
    
    -- Create pathway from entrance to farm center
    local pathStart = entrancePosition
    local pathEnd = farmCenter
    createPathway(pathStart, pathEnd, farmFolder)
    
    -- Place trees around the farm perimeter (within bounds - farm is 100x100)
    local treePositions = {
        farmCenter + Vector3.new(-35, 0, -35),
        farmCenter + Vector3.new(35, 0, -35),
        farmCenter + Vector3.new(-35, 0, 35),
        farmCenter + Vector3.new(35, 0, 35),
        farmCenter + Vector3.new(-35, 0, 0),
        farmCenter + Vector3.new(35, 0, 0),
        farmCenter + Vector3.new(0, 0, -35),
        farmCenter + Vector3.new(0, 0, 35)
    }
    
    log.info("Placing trees around farm center:", farmCenter)
    
    local treeTypes = {"oak", "pine", "apple"}
    for i, pos in ipairs(treePositions) do
        local treeType = treeTypes[(i % #treeTypes) + 1]
        createTree(pos, treeType, farmFolder)
    end
    
    -- Add decorative elements
    local decorPositions = {
        farmCenter + Vector3.new(-20, 0, -20),
        farmCenter + Vector3.new(20, 0, -20),
        farmCenter + Vector3.new(-20, 0, 20),
        farmCenter + Vector3.new(20, 0, 20),
        farmCenter + Vector3.new(-30, 0, 10),
        farmCenter + Vector3.new(30, 0, -10)
    }
    
    local decorTypes = {"rock", "flower", "grass", "rock", "flower", "grass"}
    for i, pos in ipairs(decorPositions) do
        createDecoration(pos, decorTypes[i], farmFolder)
    end
    
    -- Add floating farm name above center
    if ownerName then
        local nameDisplay = Instance.new("Part")
        nameDisplay.Name = "FarmNameDisplay"
        nameDisplay.Size = Vector3.new(0.1, 0.1, 0.1)
        nameDisplay.Position = farmCenter + Vector3.new(0, 50, 0) -- High above farm
        nameDisplay.Transparency = 1
        nameDisplay.Anchored = true
        nameDisplay.CanCollide = false
        nameDisplay.Parent = farmFolder
        
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 300, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 0, 0)
        billboard.AlwaysOnTop = false
        billboard.Parent = nameDisplay
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = ownerName .. "'s Farm"
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        nameLabel.TextStrokeTransparency = 0
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.Antique
        nameLabel.Parent = billboard
    end
    
    log.info("Farm", farmId, "environment enhancement complete!")
    return true
end

-- Enhance all existing farms
function FarmEnvironment.enhanceAllFarms()
    local workspace = game:GetService("Workspace")
    local playerFarms = workspace:FindFirstChild("PlayerFarms")
    if not playerFarms then
        log.warn("🌳 PlayerFarms folder not found")
        return 0
    end
    
    log.info("🌳 Found PlayerFarms, scanning for farms...")
    local enhanced = 0
    for _, child in ipairs(playerFarms:GetChildren()) do
        log.info("🌳 Checking child:", child.Name, "Type:", child.ClassName)
        if child:IsA("Folder") and child.Name:match("^Farm_(%d+)$") then
            local farmId = tonumber(child.Name:match("^Farm_(%d+)$"))
            log.info("🌳 Found farm folder:", child.Name, "ID:", farmId)
            if farmId and FarmEnvironment.enhanceFarm(farmId) then
                enhanced = enhanced + 1
            end
        end
    end
    
    log.info("🌳 Enhanced", enhanced, "farms with environmental decorations")
    return enhanced
end

-- Initialize farm environment system
function FarmEnvironment.initialize()
    log.info("🌳 Farm Environment system initializing...")
    
    -- Enhance all existing farms
    local enhanced = FarmEnvironment.enhanceAllFarms()
    
    log.info("🌳 Farm Environment system ready! Enhanced", enhanced, "farms")
end

return FarmEnvironment