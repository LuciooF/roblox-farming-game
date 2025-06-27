-- Rain Effect Manager
-- Creates and manages rain particle effects for watering animations

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ClientLogger = require(script.Parent.ClientLogger)

local log = ClientLogger.getModuleLogger("RainEffect")

local RainEffectManager = {}

-- Create rain particle effect over a plot
function RainEffectManager.createRainEffect(plot)
    if not plot then
        log.warn("No plot provided for rain effect")
        return
    end
    
    log.debug("Creating rain effect for plot")
    
    -- Create a part to attach the particle emitter to
    local rainPart = Instance.new("Part")
    rainPart.Name = "RainEffect"
    rainPart.Anchored = true
    rainPart.CanCollide = false
    rainPart.Transparency = 1
    rainPart.Size = Vector3.new(10, 0.1, 10)
    rainPart.Position = plot.Position + Vector3.new(0, 10, 0) -- Position above plot
    rainPart.Parent = workspace
    
    -- Create particle emitter for rain drops
    local rainEmitter = Instance.new("ParticleEmitter")
    rainEmitter.Name = "RainDrops"
    
    -- Rain drop appearance
    rainEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds" -- Use sparkles as water drops
    rainEmitter.Color = ColorSequence.new(Color3.fromRGB(150, 200, 255)) -- Light blue
    rainEmitter.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(0.8, 0.5),
        NumberSequenceKeypoint.new(1, 1)
    }
    rainEmitter.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(1, 0.1)
    }
    
    -- Rain behavior
    rainEmitter.Rate = 50 -- Drops per second
    rainEmitter.Lifetime = NumberRange.new(1, 1.5)
    rainEmitter.Speed = NumberRange.new(15, 20)
    rainEmitter.SpreadAngle = Vector2.new(10, 10) -- Slight spread
    rainEmitter.VelocityInheritance = 0
    rainEmitter.EmissionDirection = Enum.NormalId.Bottom
    rainEmitter.Acceleration = Vector3.new(0, -10, 0) -- Gravity effect
    
    -- Add some rotation for realism
    rainEmitter.RotSpeed = NumberRange.new(-180, 180)
    rainEmitter.Rotation = NumberRange.new(0, 360)
    
    rainEmitter.Parent = rainPart
    
    -- Create splash particles at ground level
    local splashPart = Instance.new("Part")
    splashPart.Name = "SplashEffect"
    splashPart.Anchored = true
    splashPart.CanCollide = false
    splashPart.Transparency = 1
    splashPart.Size = Vector3.new(8, 0.1, 8)
    splashPart.Position = plot.Position + Vector3.new(0, 0.5, 0) -- Just above plot surface
    splashPart.Parent = workspace
    
    local splashEmitter = Instance.new("ParticleEmitter")
    splashEmitter.Name = "WaterSplash"
    splashEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    splashEmitter.Color = ColorSequence.new(Color3.fromRGB(200, 230, 255))
    splashEmitter.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(1, 1)
    }
    splashEmitter.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(1, 0.3)
    }
    splashEmitter.Rate = 20
    splashEmitter.Lifetime = NumberRange.new(0.3, 0.5)
    splashEmitter.Speed = NumberRange.new(2, 4)
    splashEmitter.SpreadAngle = Vector2.new(45, 45)
    splashEmitter.EmissionDirection = Enum.NormalId.Top
    splashEmitter.VelocityInheritance = 0
    splashEmitter.Parent = splashPart
    
    -- Stop and clean up after 5 seconds
    task.wait(5) -- Let particles run for 5 seconds
    rainEmitter.Enabled = false
    splashEmitter.Enabled = false
    
    -- Clean up after particles finish
    Debris:AddItem(rainPart, 7) -- Give extra time for particles to fade
    Debris:AddItem(splashPart, 7)
    
    -- Optional: Add sound effect (commented out as sounds aren't loaded yet)
    -- SoundManager.playWaterSound(plot.Position)
    
    log.debug("Rain effect created successfully")
end


return RainEffectManager