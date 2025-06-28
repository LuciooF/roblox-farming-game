-- Music Button Component
-- Small music toggle button for bottom left corner

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local e = React.createElement
local assets = require(game:GetService("ReplicatedStorage").Shared.assets)
local ScreenUtils = require(game:GetService("ReplicatedStorage").Shared.ScreenUtils)
local BackgroundMusicManager = require(script.Parent.Parent.BackgroundMusicManager)

-- Sound IDs for button interactions
local HOVER_SOUND_ID = "rbxassetid://15675059323"
local CLICK_SOUND_ID = "rbxassetid://6324790483"

-- Pre-create sounds for better performance
local hoverSound = Instance.new("Sound")
hoverSound.SoundId = HOVER_SOUND_ID
hoverSound.Volume = 0.3
hoverSound.Parent = SoundService

local clickSound = Instance.new("Sound")
clickSound.SoundId = CLICK_SOUND_ID
clickSound.Volume = 0.4
clickSound.Parent = SoundService

-- Function to play sound effects
local function playSound(soundType)
    if soundType == "hover" and hoverSound then
        hoverSound:Play()
    elseif soundType == "click" and clickSound then
        clickSound:Play()
    end
end

-- Function to create flip animation for music button
local function createFlipAnimation(iconRef, animationTracker)
    if not iconRef.current then return end
    
    -- Cancel any existing animation for this icon
    if animationTracker.current then
        pcall(function()
            animationTracker.current:Cancel()
        end)
        pcall(function()
            animationTracker.current:Destroy()
        end)
        animationTracker.current = nil
    end
    
    -- Reset rotation to 0 to prevent accumulation
    iconRef.current.Rotation = 0
    
    -- Create flip animation
    local flipTween = TweenService:Create(iconRef.current,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Rotation = 360}
    )
    
    -- Store reference to current animation
    animationTracker.current = flipTween
    
    flipTween:Play()
    flipTween.Completed:Connect(function()
        -- Reset rotation after animation
        if iconRef.current then
            iconRef.current.Rotation = 0
        end
        -- Clear the tracker
        if animationTracker.current == flipTween then
            animationTracker.current = nil
        end
        flipTween:Destroy()
    end)
end

local function MusicButton(props)
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local playerData = props.playerData or {}
    local remotes = props.remotes or {}
    
    -- Don't show the button until player data is loaded
    if not playerData.isInitialized then
        return nil
    end
    
    -- Music state - get from player data, default to true only if no settings exist
    local initialMusicState = true
    if playerData.settings and playerData.settings.musicEnabled ~= nil then
        initialMusicState = playerData.settings.musicEnabled
    end
    local musicEnabled, setMusicEnabled = React.useState(initialMusicState)
    
    -- Animation refs
    local musicIconRef = React.useRef(nil)
    local musicAnimTracker = React.useRef(nil)
    
    local scale = ScreenUtils.getProportionalScale(screenSize)
    
    -- Button sizing to match side buttons
    local buttonSize = ScreenUtils.getProportionalSize(screenSize, 55)
    
    -- Sync music state when player data changes
    React.useEffect(function()
        if playerData.settings and playerData.settings.musicEnabled ~= nil then
            setMusicEnabled(playerData.settings.musicEnabled)
        end
    end, {playerData.settings})
    
    -- Apply music setting through BackgroundMusicManager when state changes
    React.useEffect(function()
        if musicEnabled then
            BackgroundMusicManager.startMusic()
        else
            BackgroundMusicManager.stopMusic()
        end
    end, {musicEnabled})
    
    -- Handle music toggle
    local function toggleMusic()
        playSound("click")
        createFlipAnimation(musicIconRef, musicAnimTracker)
        
        local newMusicState = not musicEnabled
        setMusicEnabled(newMusicState)
        
        -- Send preference to server
        if remotes.MusicPreference then
            remotes.MusicPreference:FireServer(newMusicState)
        end
        
        -- Music state change will be handled by the useEffect above
    end
    
    return e("Frame", {
        Name = "MusicButtonContainer",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = 14
    }, {
        -- Music Button (bottom right corner)
        MusicButton = e("TextButton", {
            Name = "MusicButton",
            Size = UDim2.new(0, buttonSize, 0, buttonSize),
            Position = UDim2.new(1, -(buttonSize + ScreenUtils.getProportionalPadding(screenSize, 20)), 1, -(buttonSize + ScreenUtils.getProportionalPadding(screenSize, 20))), -- Bottom right corner
            Text = "",
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = 15,
            [React.Event.Activated] = toggleMusic,
            [React.Event.MouseEnter] = function()
                playSound("hover")
                createFlipAnimation(musicIconRef, musicAnimTracker)
            end
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0.5, 0) -- Make it circular
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0), -- Black outline
                Thickness = 2,
                Transparency = 0,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            }),
            Gradient = e("UIGradient", {
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, musicEnabled and Color3.fromRGB(180, 255, 180) or Color3.fromRGB(255, 180, 180)),
                    ColorSequenceKeypoint.new(1, musicEnabled and Color3.fromRGB(120, 220, 120) or Color3.fromRGB(220, 120, 120))
                },
                Rotation = 45
            }),
            
            -- Music Icon (centered in circle)
            MusicIcon = e("ImageLabel", {
                Name = "MusicIcon",
                Size = UDim2.new(0, 32, 0, 32),
                Position = UDim2.new(0.5, -16, 0.5, -16), -- Perfectly centered
                Image = musicEnabled and assets["ui/Music/Music 256.png"] or assets["ui/Music Off/Music Off Outline 256.png"],
                BackgroundTransparency = 1,
                ScaleType = Enum.ScaleType.Fit,
                ImageColor3 = Color3.fromRGB(255, 255, 255),
                ZIndex = 16,
                ref = musicIconRef
            })
        })
    })
end

return MusicButton