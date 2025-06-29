-- Fly Button Component
-- Toggle button for flying mode next to the music button

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local MarketplaceService = game:GetService("MarketplaceService")
local e = React.createElement
local assets = require(game:GetService("ReplicatedStorage").Shared.assets)
local ScreenUtils = require(game:GetService("ReplicatedStorage").Shared.ScreenUtils)
local FlyController = require(script.Parent.Parent.FlyController)

-- Fly gamepass ID
local FLY_GAMEPASS_ID = 1286467321

-- Sound IDs for button interactions (same as music button)
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

-- Function to create flip animation for fly button
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

local function FlyButton(props)
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local playerData = props.playerData or {}
    local onGamepassToggle = props.onGamepassToggle or function() end
    
    -- Don't show the button until player data is loaded
    if not playerData.isInitialized then
        return nil
    end
    
    -- Check if player has fly gamepass
    local hasGamepass = playerData.gamepasses and playerData.gamepasses.flyMode == true
    
    -- Get current flying state from FlyController
    local isFlying, setIsFlying = React.useState(FlyController.isFlying())
    
    -- Animation refs
    local flyIconRef = React.useRef(nil)
    local flyAnimTracker = React.useRef(nil)
    
    local scale = ScreenUtils.getProportionalScale(screenSize)
    
    -- Button sizing to match music button
    local buttonSize = ScreenUtils.getProportionalSize(screenSize, 55)
    
    -- Update flying state when FlyController state changes
    React.useEffect(function()
        local connection = FlyController.onFlyStateChanged:Connect(function(newState)
            setIsFlying(newState)
        end)
        
        return function()
            connection:Disconnect()
        end
    end, {})
    
    -- Handle fly toggle
    local function toggleFly()
        playSound("click")
        createFlipAnimation(flyIconRef, flyAnimTracker)
        
        if hasGamepass then
            -- Toggle flying mode
            FlyController.toggleFly()
        else
            -- Instead of prompting directly, open the gamepass panel
            print("DEBUG FlyButton: Opening gamepass panel for fly purchase")
            
            -- Find and trigger the gamepass panel opening
            local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
            local farmingUI = playerGui:FindFirstChild("FarmingUI")
            if farmingUI then
                -- Trigger gamepass panel visibility through a global or event
                -- For now, just show a message
                print("Please use the Gamepass Panel to purchase Fly Mode")
            end
        end
    end
    
    return e("Frame", {
        Name = "FlyButtonContainer",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = 14
    }, {
        -- Fly Button (to the left of music button)
        FlyButton = e("TextButton", {
            Name = "FlyButton",
            Size = UDim2.new(0, buttonSize, 0, buttonSize),
            Position = UDim2.new(1, -(buttonSize + ScreenUtils.getProportionalPadding(screenSize, 20)) - (buttonSize + ScreenUtils.getProportionalPadding(screenSize, 10)), 1, -(buttonSize + ScreenUtils.getProportionalPadding(screenSize, 20))), -- To the left of music button
            Text = "",
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = 15,
            [React.Event.Activated] = toggleFly,
            [React.Event.MouseEnter] = function()
                playSound("hover")
                createFlipAnimation(flyIconRef, flyAnimTracker)
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
                    ColorSequenceKeypoint.new(0, (hasGamepass and isFlying) and Color3.fromRGB(180, 255, 180) or Color3.fromRGB(255, 180, 180)),
                    ColorSequenceKeypoint.new(1, (hasGamepass and isFlying) and Color3.fromRGB(120, 220, 120) or Color3.fromRGB(220, 120, 120))
                },
                Rotation = 45
            }),
            
            -- Content Container for icon and text
            ContentContainer = e("Frame", {
                Name = "ContentContainer",
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                ZIndex = 16
            }, {
                -- Fly Icon (centered in button)
                FlyIcon = e("ImageLabel", {
                    Name = "FlyIcon",
                    Size = UDim2.new(0, 26, 0, 26),
                    Position = UDim2.new(0.5, -13, 0.5, -13), -- Perfectly centered
                    Image = assets["Items/Wing/Wing Rainbow Outline 256.png"] or "rbxassetid://89119796236913",
                    BackgroundTransparency = 1,
                    ScaleType = Enum.ScaleType.Fit,
                    ImageColor3 = Color3.fromRGB(255, 255, 255),
                    ZIndex = 17,
                    ref = flyIconRef
                }),
                
                -- Fly Text (below icon, outside button)
                FlyText = e("TextLabel", {
                    Name = "FlyText",
                    Size = UDim2.new(1, 0, 0, 14),
                    Position = UDim2.new(0, 0, 1, 2), -- Just below the button
                    Text = "Fly!",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = ScreenUtils.getProportionalTextSize(screenSize, 11),
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    BackgroundTransparency = 1,
                    ZIndex = 17
                }, {
                    TextStroke = e("UIStroke", {
                        Color = Color3.fromRGB(0, 0, 0),
                        Thickness = 1,
                        Transparency = 0.3
                    })
                })
            })
        })
    })
end

return FlyButton