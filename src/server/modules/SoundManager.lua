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

-- Setup background music
function SoundManager.setupBackgroundMusic()
    -- Create background music sound
    backgroundMusicSound = Instance.new("Sound")
    backgroundMusicSound.Name = "BackgroundMusic"
    backgroundMusicSound.SoundId = SoundConfig.backgroundMusic[1]
    backgroundMusicSound.Volume = SoundSettings.backgroundMusicVolume
    backgroundMusicSound.Looped = true
    backgroundMusicSound.EmitterSize = 100 -- Large area
    backgroundMusicSound.Parent = game.Workspace
    
    -- Start playing
    backgroundMusicSound:Play()
    
    -- Change music every 5 minutes
    spawn(function()
        while true do
            wait(300) -- 5 minutes
            SoundManager.changeBackgroundMusic()
        end
    end)
end

-- Change background music to a different track
function SoundManager.changeBackgroundMusic()
    if backgroundMusicSound then
        local currentId = backgroundMusicSound.SoundId
        local musicList = SoundConfig.backgroundMusic
        
        -- Pick a different track
        local newId = currentId
        while newId == currentId do
            newId = musicList[math.random(1, #musicList)]
        end
        
        -- Fade out current, fade in new
        local tweenService = game:GetService("TweenService")
        local fadeOut = tweenService:Create(backgroundMusicSound, TweenInfo.new(2), {Volume = 0})
        
        fadeOut:Play()
        fadeOut.Completed:Connect(function()
            backgroundMusicSound.SoundId = newId
            backgroundMusicSound.Volume = SoundSettings.backgroundMusicVolume
            backgroundMusicSound:Play()
        end)
    end
end

-- Setup sound effects in ReplicatedStorage for client access
function SoundManager.setupSoundEffects()
    local soundFolder = Instance.new("Folder")
    soundFolder.Name = "SoundEffects"
    soundFolder.Parent = ReplicatedStorage
    
    -- Create action sounds
    for actionName, soundId in pairs(SoundConfig.actions) do
        local sound = Instance.new("Sound")
        sound.Name = actionName
        sound.SoundId = soundId
        sound.Volume = SoundSettings.actionSoundVolume
        sound.Parent = soundFolder
        soundEffects[actionName] = sound
    end
    
    -- Create UI sounds
    for uiName, soundId in pairs(SoundConfig.ui) do
        local sound = Instance.new("Sound")
        sound.Name = uiName
        sound.SoundId = soundId
        sound.Volume = SoundSettings.uiSoundVolume
        sound.Parent = soundFolder
        soundEffects[uiName] = sound
    end
    
    -- Create system sounds
    for systemName, soundId in pairs(SoundConfig.system) do
        local sound = Instance.new("Sound")
        sound.Name = systemName
        sound.SoundId = soundId
        sound.Volume = SoundSettings.systemSoundVolume
        sound.Parent = soundFolder
        soundEffects[systemName] = sound
    end
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

-- Play system sound (server-side notification sounds)
function SoundManager.playSystemSound(soundName)
    SoundManager.playActionSound(soundName)
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

-- Special event sounds
function SoundManager.playPlantDeathSound(position)
    SoundManager.playActionSound("plantDeath", position)
end

function SoundManager.playPlantReadySound(position)
    SoundManager.playActionSound("plantReady", position)
end

function SoundManager.playRebirthSound()
    SoundManager.playActionSound("rebirth")
end

-- Volume controls
function SoundManager.setBackgroundMusicVolume(volume)
    SoundSettings.backgroundMusicVolume = math.clamp(volume, 0, 1)
    if backgroundMusicSound then
        backgroundMusicSound.Volume = SoundSettings.backgroundMusicVolume
    end
end

function SoundManager.setSoundEffectVolume(category, volume)
    volume = math.clamp(volume, 0, 1)
    
    if category == "actions" then
        SoundSettings.actionSoundVolume = volume
    elseif category == "ui" then
        SoundSettings.uiSoundVolume = volume
    elseif category == "system" then
        SoundSettings.systemSoundVolume = volume
    end
    
    -- Update existing sounds
    for soundName, sound in pairs(soundEffects) do
        if SoundConfig[category] and SoundConfig[category][soundName] then
            sound.Volume = volume
        end
    end
end

-- Toggle background music on/off
function SoundManager.toggleBackgroundMusic()
    if backgroundMusicSound then
        if backgroundMusicSound.Volume > 0 then
            backgroundMusicSound.Volume = 0
            return false -- Music off
        else
            backgroundMusicSound.Volume = SoundSettings.backgroundMusicVolume
            return true -- Music on
        end
    end
    return false
end

return SoundManager