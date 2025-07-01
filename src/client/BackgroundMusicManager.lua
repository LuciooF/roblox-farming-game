-- Background Music Manager
-- Handles playing background music with seamless looping

local SoundService = game:GetService("SoundService")

local BackgroundMusicManager = {}

-- Simple logging functions for BackgroundMusicManager
local function logWarn(...) warn("[WARN] BackgroundMusicManager:", ...) end

-- Music configuration
local MUSIC_ID = "rbxassetid://1840384075" -- User-specified music
local MUSIC_VOLUME = 0.3 -- 30% volume for background music
local FADE_TIME = 2 -- Seconds for fade in/out

-- Current music sound object
local currentMusic = nil
local isMusicEnabled = true
local hasInitialized = false

-- Function to create and configure music sound
local function createMusicSound()
    local music = Instance.new("Sound")
    music.Name = "BackgroundMusic"
    music.SoundId = MUSIC_ID
    music.Volume = 0 -- Start at 0 for fade in
    music.Looped = true -- Enable looping
    music.Parent = SoundService
    
    return music
end

-- Function to fade in music
local function fadeInMusic(music)
    local TweenService = game:GetService("TweenService")
    
    -- Create fade in tween
    local fadeIn = TweenService:Create(
        music,
        TweenInfo.new(FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Volume = MUSIC_VOLUME}
    )
    
    fadeIn:Play()
end

-- Function to fade out music
local function fadeOutMusic(music, callback)
    local TweenService = game:GetService("TweenService")
    
    -- Create fade out tween
    local fadeOut = TweenService:Create(
        music,
        TweenInfo.new(FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Volume = 0}
    )
    
    fadeOut:Play()
    fadeOut.Completed:Connect(function()
        if callback then
            callback()
        end
    end)
    
end

-- Function to start background music
function BackgroundMusicManager.startMusic()
    -- Enable music when explicitly starting
    isMusicEnabled = true
    
    if currentMusic then
        return
    end
    
    -- Create new music sound
    currentMusic = createMusicSound()
    
    -- Handle loading and playback
    local function attemptPlay()
        if currentMusic and currentMusic.IsLoaded then
            currentMusic:Play()
            fadeInMusic(currentMusic)
        else
            if currentMusic then
                currentMusic.Loaded:Connect(function()
                    currentMusic:Play()
                    fadeInMusic(currentMusic)
                end)
            end
        end
    end
    
    -- Try to play immediately or wait for loading
    pcall(attemptPlay)
    
    -- Handle music ending (shouldn't happen with Looped = true, but just in case)
    if currentMusic then
        currentMusic.Ended:Connect(function()
            if isMusicEnabled then
                BackgroundMusicManager.startMusic()
            end
        end)
    end
end

-- Function to stop background music
function BackgroundMusicManager.stopMusic()
    -- Disable music when explicitly stopping
    isMusicEnabled = false
    
    if not currentMusic then
        return
    end
    
    fadeOutMusic(currentMusic, function()
        if currentMusic then
            currentMusic:Stop()
            currentMusic:Destroy()
            currentMusic = nil
        end
    end)
end

-- Function to toggle music on/off
function BackgroundMusicManager.toggleMusic()
    isMusicEnabled = not isMusicEnabled
    
    if isMusicEnabled then
        BackgroundMusicManager.startMusic()
    else
        BackgroundMusicManager.stopMusic()
    end
    
    return isMusicEnabled
end

-- Function to set music volume
function BackgroundMusicManager.setVolume(volume)
    MUSIC_VOLUME = math.clamp(volume, 0, 1)
    
    if currentMusic then
        local TweenService = game:GetService("TweenService")
        local volumeTween = TweenService:Create(
            currentMusic,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad),
            {Volume = MUSIC_VOLUME}
        )
        volumeTween:Play()
    end
    
end

-- Function to check if music is playing
function BackgroundMusicManager.isPlaying()
    return currentMusic ~= nil and currentMusic.IsPlaying
end

-- Function to check if music is enabled
function BackgroundMusicManager.isEnabled()
    return isMusicEnabled
end

-- Function to set initial music state from player data
function BackgroundMusicManager.setInitialState(enabled)
    if hasInitialized then
        return
    end
    
    hasInitialized = true
    isMusicEnabled = enabled
    
    if enabled then
        -- Start music after a short delay
        spawn(function()
            wait(0.5) -- Short delay to ensure everything is loaded
            BackgroundMusicManager.startMusic()
        end)
    end
end

-- Initialize the music manager (no longer starts music automatically)
function BackgroundMusicManager.initialize()
    -- No longer starts music automatically - waits for setInitialState to be called
end

-- Cleanup function
function BackgroundMusicManager.cleanup()
    BackgroundMusicManager.stopMusic()
end

return BackgroundMusicManager