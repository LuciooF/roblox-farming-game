-- Sound Management Module
-- Handles all game audio including background music and sound effects

local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(script.Parent.Logger)

local SoundManager = {}

-- Get module logger
local log = Logger.getModuleLogger("SoundManager")

-- Sound configurations with Roblox built-in asset IDs
local SoundConfig = {
    -- Background Music (peaceful farming themes)
    backgroundMusic = {
        "rbxasset://sounds/music/Birthday.mp3", -- Peaceful tune
        "rbxasset://sounds/music/Ode_to_Joy.mp3" -- Classical and calm
    },
    
    -- Farming Action Sounds
    actions = {
        plant = "rbxasset://sounds/impact_dirt.mp3", -- Dirt sound for planting
        water = "rbxasset://sounds/splash_small.mp3", -- Water splash
        harvest = "rbxasset://sounds/snap.mp3", -- Snap sound for harvesting
        sell = "rbxasset://sounds/electronicpingbeep.mp3" -- Success beep
    },
    
    -- UI Sounds
    ui = {
        click = "rbxasset://sounds/button_click.mp3",
        notification = "rbxasset://sounds/notification.mp3",
        rebirth = "rbxasset://sounds/victory.mp3" -- Special sound for rebirth
    },
    
    -- System Sounds
    system = {
        plantDeath = "rbxasset://sounds/break_wood.mp3", -- Plant withering
        plantReady = "rbxasset://sounds/coin.mp3" -- Crop ready chime
    }
}

-- Sound settings
local SoundSettings = {
    backgroundMusicVolume = 0.3,
    actionSoundVolume = 0.6,
    uiSoundVolume = 0.5,
    systemSoundVolume = 0.4
}

-- Storage
local backgroundMusicSound = nil
local soundEffects = {}

-- Initialize sound system
function SoundManager.initialize()
    log.info("Initializing audio system... (sounds disabled)")
    
    -- Sounds are disabled to prevent loading errors
    -- Uncomment these lines when sound assets are available:
    -- SoundManager.setupBackgroundMusic()
    -- SoundManager.setupSoundEffects()
    
    log.info("Audio system ready! (sounds disabled)")
end


-- Play action sound (server-side, plays for all nearby players)
function SoundManager.playActionSound(soundName, position)
    if not soundEffects[soundName] then return end
    
    -- Create a temporary sound at the position
    local sound = soundEffects[soundName]:Clone()
    sound.Parent = game.Workspace
    
    -- Position the sound if provided
    if position then
        local part = Instance.new("Part")
        part.Name = "SoundEmitter"
        part.Size = Vector3.new(1, 1, 1)
        part.Position = position
        part.Anchored = true
        part.Transparency = 1
        part.CanCollide = false
        part.Parent = game.Workspace
        sound.Parent = part
        
        -- Clean up after sound finishes
        spawn(function()
            sound:Play()
            wait(sound.TimeLength + 0.5)
            if part.Parent then
                part:Destroy()
            end
        end)
    else
        -- Play globally
        sound:Play()
        spawn(function()
            wait(sound.TimeLength + 0.5)
            if sound.Parent then
                sound:Destroy()
            end
        end)
    end
end


-- Farming action sounds
function SoundManager.playPlantSound(position)
    SoundManager.playActionSound("plant", position)
end

function SoundManager.playWaterSound(position)
    SoundManager.playActionSound("water", position)
end

function SoundManager.playHarvestSound(position)
    SoundManager.playActionSound("harvest", position)
end

function SoundManager.playSellSound()
    SoundManager.playActionSound("sell")
end


function SoundManager.playPlantReadySound(position)
    SoundManager.playActionSound("plantReady", position)
end

function SoundManager.playRebirthSound()
    SoundManager.playActionSound("rebirth")
end


return SoundManager