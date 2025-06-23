-- Seed Drop System Module
-- Handles dropping rare seeds from the sky and pickup mechanics

local Logger = require(script.Parent.Logger)
local GameConfig = require(script.Parent.GameConfig)
local PlayerDataManager = require(script.Parent.PlayerDataManager)
local NotificationManager = require(script.Parent.NotificationManager)
local SoundManager = require(script.Parent.SoundManager)

local SeedDropSystem = {}

-- Get module logger
local log = Logger.getModuleLogger("SeedDropSystem")

-- Storage
local droppedSeeds = {} -- Active seeds on the ground
local seedDropCounter = 0

-- Initialize the seed drop system
function SeedDropSystem.initialize()
    log.info("Initializing sky seed drops...")
    
    -- Create the drop tube
    SeedDropSystem.createDropTube()
    
    -- Start the drop loop
    SeedDropSystem.startDropLoop()
    
    log.info("Ready!")
end

-- Create the drop tube visual
function SeedDropSystem.createDropTube()
    local tubePosition = GameConfig.World.skyDropPosition
    
    -- Create tube container
    local tubeFolder = Instance.new("Folder")
    tubeFolder.Name = "SeedDropTube"
    tubeFolder.Parent = game.Workspace
    
    -- Create vertical tube walls (hollow tube effect)
    for i = 1, 4 do
        local wall = Instance.new("Part")
        wall.Name = "TubeWall_" .. i
        wall.Size = Vector3.new(1, 30, 8)
        wall.Anchored = true
        wall.Material = Enum.Material.Metal
        wall.BrickColor = BrickColor.new("Dark stone grey")
        wall.Shape = Enum.PartType.Block
        wall.CanCollide = false -- Seeds pass through
        wall.Parent = tubeFolder
        
        -- Position walls to form a square tube
        if i == 1 then
            wall.Position = tubePosition + Vector3.new(3.5, -15, 0) -- Right wall
        elseif i == 2 then
            wall.Position = tubePosition + Vector3.new(-3.5, -15, 0) -- Left wall
        elseif i == 3 then
            wall.Size = Vector3.new(8, 30, 1)
            wall.Position = tubePosition + Vector3.new(0, -15, 3.5) -- Back wall
        else
            wall.Size = Vector3.new(8, 30, 1)
            wall.Position = tubePosition + Vector3.new(0, -15, -3.5) -- Front wall
        end
    end
    
    -- Tube opening indicator (bottom ring)
    local opening = Instance.new("Part")
    opening.Name = "TubeOpening"
    opening.Size = Vector3.new(8, 1, 8)
    opening.Position = tubePosition - Vector3.new(0, 31, 0)
    opening.Anchored = true
    opening.Material = Enum.Material.Neon
    opening.BrickColor = BrickColor.new("Bright blue")
    opening.Shape = Enum.PartType.Block
    opening.Transparency = 0.5 -- Semi-transparent so seeds can be seen
    opening.CanCollide = false -- Seeds pass through
    opening.Parent = tubeFolder
    
    
    -- Tube sign (positioned away from drop path)
    local sign = Instance.new("Part")
    sign.Name = "TubeSign"
    sign.Size = Vector3.new(6, 4, 0.2)
    sign.Position = tubePosition + Vector3.new(8, -10, 0) -- Further away from drop path
    sign.Anchored = true
    sign.Material = Enum.Material.Neon
    sign.BrickColor = BrickColor.new("Bright green")
    sign.CanCollide = false -- Just in case
    sign.Parent = tubeFolder
    
    local signText = Instance.new("SurfaceGui")
    signText.Face = Enum.NormalId.Front
    signText.Parent = sign
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "SEED DROP\nTUBE\nRare Seeds!"
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Parent = signText
    
    log.debug("Created seed drop tube at position:", tubePosition)
end

-- Start the continuous seed dropping
function SeedDropSystem.startDropLoop()
    spawn(function()
        while true do
            wait(GameConfig.World.seedDropInterval)
            
            -- Clean up old seeds first
            SeedDropSystem.cleanupOldSeeds()
            
            -- Drop a new seed if under limit
            if #droppedSeeds < GameConfig.World.maxSeedsOnGround then
                SeedDropSystem.dropRandomSeed()
            end
        end
    end)
end

-- Drop a random seed from the sky
function SeedDropSystem.dropRandomSeed()
    -- Determine rarity based on chances
    local rarity, seedType = SeedDropSystem.rollSeedRarity()
    local seedConfig = GameConfig.SeedRarities[rarity].seeds[seedType]
    
    if not seedConfig then return end
    
    seedDropCounter = seedDropCounter + 1
    local seedId = "seed_" .. seedDropCounter
    
    -- Create the physical seed object
    local seed = Instance.new("Part")
    seed.Name = "DroppedSeed_" .. seedId
    seed.Size = Vector3.new(2, 2, 2)
    seed.Position = GameConfig.World.skyDropPosition
    seed.Shape = Enum.PartType.Ball
    seed.Material = Enum.Material.Neon
    seed.Color = GameConfig.CropColors[seedType] or Color3.fromRGB(100, 200, 100)
    seed.Anchored = false
    seed.CanCollide = true
    seed.TopSurface = Enum.SurfaceType.Smooth
    seed.BottomSurface = Enum.SurfaceType.Smooth
    seed.Parent = game.Workspace
    
    -- Add physics properties for bouncy effect
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
    bodyVelocity.Velocity = Vector3.new(
        math.random(-10, 10), -- Random X spread
        -50, -- Fall speed
        math.random(-10, 10)  -- Random Z spread
    )
    bodyVelocity.Parent = seed
    
    -- Remove velocity after a short time to let it settle
    spawn(function()
        wait(2)
        if bodyVelocity.Parent then
            bodyVelocity:Destroy()
        end
    end)
    
    -- Create floating label showing seed info
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "SeedInfo"
    billboardGui.Size = UDim2.new(0, 120, 0, 60)
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
    billboardGui.LightInfluence = 0
    billboardGui.Parent = seed
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.Text = rarity:upper() .. " " .. seedType:upper()
    nameLabel.TextColor3 = GameConfig.SeedRarities[rarity].color
    nameLabel.TextScaled = true
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Parent = billboardGui
    
    local priceLabel = Instance.new("TextLabel")
    priceLabel.Size = UDim2.new(1, 0, 0.4, 0)
    priceLabel.Position = UDim2.new(0, 0, 0.6, 0)
    priceLabel.Text = "$" .. seedConfig.seedCost
    priceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    priceLabel.TextScaled = true
    priceLabel.BackgroundTransparency = 1
    priceLabel.Font = Enum.Font.SourceSans
    priceLabel.TextStrokeTransparency = 0
    priceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    priceLabel.Parent = billboardGui
    
    -- Add pickup prompt
    local pickupPrompt = Instance.new("ProximityPrompt")
    pickupPrompt.Name = "PickupPrompt"
    pickupPrompt.ActionText = "Buy " .. seedType:upper()
    pickupPrompt.KeyboardKeyCode = Enum.KeyCode.E
    pickupPrompt.RequiresLineOfSight = false
    pickupPrompt.MaxActivationDistance = 10
    pickupPrompt.Parent = seed
    
    -- Handle pickup
    pickupPrompt.Triggered:Connect(function(player)
        SeedDropSystem.handleSeedPickup(player, seedId, rarity, seedType, seedConfig)
    end)
    
    -- Add particle effects for rare seeds
    if rarity ~= "common" then
        SeedDropSystem.addSeedParticles(seed, rarity)
    end
    
    -- Store seed data
    droppedSeeds[seedId] = {
        part = seed,
        rarity = rarity,
        seedType = seedType,
        config = seedConfig,
        dropTime = tick()
    }
    
    -- Play drop sound
    -- SoundManager.playSystemSound("plantReady")
    
    log.info("Dropped " .. rarity .. " " .. seedType .. " seed from sky!")
end

-- Handle seed pickup by player
function SeedDropSystem.handleSeedPickup(player, seedId, rarity, seedType, seedConfig)
    local seedData = droppedSeeds[seedId]
    if not seedData then return end
    
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return end
    
    -- Check if player can afford the seed
    if playerData.money < seedConfig.seedCost then
        NotificationManager.sendNotification(player, "Need $" .. seedConfig.seedCost .. " for " .. seedType .. "!")
        return
    end
    
    -- Purchase the seed
    local success = PlayerDataManager.removeMoney(player, seedConfig.seedCost)
    if success then
        PlayerDataManager.addToInventory(player, "seeds", seedType, 1)
        
        -- Remove the seed from the world
        if seedData.part.Parent then
            seedData.part:Destroy()
        end
        droppedSeeds[seedId] = nil
        
        -- Play pickup sound
        -- SoundManager.playSellSound()
        
        -- Notify player
        local message = "Bought " .. rarity:upper() .. " " .. seedType:upper() .. " seed!"
        NotificationManager.sendNotification(player, message)
        
        -- Sync player data
        local RemoteManager = require(script.Parent.RemoteManager)
        RemoteManager.syncPlayerData(player)
        
        log.info(player.Name .. " bought " .. rarity .. " " .. seedType .. " seed for $" .. seedConfig.seedCost)
    end
end

-- Add particle effects to rare seeds
function SeedDropSystem.addSeedParticles(seed, rarity)
    local attachment = Instance.new("Attachment")
    attachment.Name = "ParticleAttachment"
    attachment.Parent = seed
    
    local particles = Instance.new("ParticleEmitter")
    particles.Name = "RarityParticles"
    particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    particles.Lifetime = NumberRange.new(0.5, 1.5)
    particles.Rate = rarity == "legendary" and 50 or (rarity == "epic" and 30 or 15)
    particles.SpreadAngle = Vector2.new(45, 45)
    particles.Speed = NumberRange.new(2, 6)
    particles.Color = ColorSequence.new(GameConfig.SeedRarities[rarity].color)
    particles.Size = NumberSequence.new(0.2)
    particles.Parent = attachment
end

-- Clean up old seeds that have been on ground too long
function SeedDropSystem.cleanupOldSeeds()
    local currentTime = tick()
    local toRemove = {}
    
    for seedId, seedData in pairs(droppedSeeds) do
        if currentTime - seedData.dropTime > GameConfig.World.seedLifetime then
            -- Remove expired seed
            if seedData.part.Parent then
                seedData.part:Destroy()
            end
            table.insert(toRemove, seedId)
        end
    end
    
    -- Clean up storage
    for _, seedId in ipairs(toRemove) do
        droppedSeeds[seedId] = nil
    end
    
    if #toRemove > 0 then
        log.debug("Cleaned up " .. #toRemove .. " expired seeds")
    end
end

-- Roll for seed rarity and type
function SeedDropSystem.rollSeedRarity()
    local roll = math.random() * 100
    local cumulative = 0
    
    -- Check rarities in order (common to legendary)
    local rarityOrder = {"legendary", "epic", "rare", "uncommon", "common"}
    
    for _, rarity in ipairs(rarityOrder) do
        cumulative = cumulative + GameConfig.SeedRarities[rarity].dropChance
        if roll <= cumulative then
            -- Pick random seed from this rarity
            local seeds = {}
            for seedType, _ in pairs(GameConfig.SeedRarities[rarity].seeds) do
                table.insert(seeds, seedType)
            end
            
            local selectedSeed = seeds[math.random(1, #seeds)]
            return rarity, selectedSeed
        end
    end
    
    -- Fallback to common wheat
    return "common", "wheat"
end

-- Get all dropped seeds (for admin/debug)
function SeedDropSystem.getDroppedSeeds()
    return droppedSeeds
end

-- Force drop a specific seed (for testing)
function SeedDropSystem.forceDropSeed(rarity, seedType)
    if GameConfig.SeedRarities[rarity] and GameConfig.SeedRarities[rarity].seeds[seedType] then
        -- Temporarily modify the config to guarantee this drop
        local originalChances = {}
        for r, data in pairs(GameConfig.SeedRarities) do
            originalChances[r] = data.dropChance
            data.dropChance = r == rarity and 100 or 0
        end
        
        SeedDropSystem.dropRandomSeed()
        
        -- Restore original chances
        for r, chance in pairs(originalChances) do
            GameConfig.SeedRarities[r].dropChance = chance
        end
        
        return true
    end
    return false
end

return SeedDropSystem