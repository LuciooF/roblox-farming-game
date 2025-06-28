-- Double Jump Controller
-- Handles double jump functionality for the player character

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local ClientLogger = require(script.Parent.ClientLogger)
local log = ClientLogger.getModuleLogger("DoubleJumpController")

local DoubleJumpController = {}

-- Configuration
local DOUBLE_JUMP_POWER = 50 -- Jump force for double jump
local DOUBLE_JUMP_HEIGHT = 16 -- How high the double jump goes
local COOLDOWN_TIME = 0.1 -- Minimum time between jumps to prevent spam

-- State tracking
local player = Players.LocalPlayer
local character = nil
local humanoid = nil
local rootPart = nil
local canDoubleJump = false
local hasDoubleJumped = false
local lastJumpTime = 0
local isGrounded = false

-- Sound effects (optional - can be uncommented when sound assets are available)
-- local jumpSound = Instance.new("Sound")
-- jumpSound.SoundId = "rbxassetid://131961136" -- Default jump sound
-- jumpSound.Volume = 0.5
-- jumpSound.Parent = SoundService

-- Function to check if character is grounded
local function checkGrounded()
    if not rootPart then return false end
    
    -- Raycast downward to check if we're on the ground
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {character}
    
    local rayOrigin = rootPart.Position
    local rayDirection = Vector3.new(0, -5, 0) -- Check 5 studs below
    
    local rayResult = workspace:Raycast(rayOrigin, rayDirection, rayParams)
    return rayResult ~= nil
end

-- Function to perform double jump
local function performDoubleJump()
    if not humanoid or not rootPart then return end
    
    local currentTime = tick()
    if currentTime - lastJumpTime < COOLDOWN_TIME then return end
    
    log.debug("Performing double jump")
    
    -- Apply upward velocity for double jump
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
    bodyVelocity.Velocity = Vector3.new(0, DOUBLE_JUMP_HEIGHT, 0)
    bodyVelocity.Parent = rootPart
    
    -- Remove the body velocity after a short time
    game:GetService("Debris"):AddItem(bodyVelocity, 0.3)
    
    -- Mark that we've used our double jump
    hasDoubleJumped = true
    canDoubleJump = false
    lastJumpTime = currentTime
    
    -- Play sound effect (commented out until sound assets are available)
    -- if jumpSound then
    --     jumpSound:Play()
    -- end
    
    -- Visual effect (optional - could add particles here)
    log.debug("Double jump performed successfully")
end

-- Handle input for jumping
local function onInputBegan(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Space then
        local currentTime = tick()
        if currentTime - lastJumpTime < COOLDOWN_TIME then return end
        
        -- Check if we're grounded
        local grounded = checkGrounded()
        
        if grounded then
            -- First jump - enable double jump
            canDoubleJump = true
            hasDoubleJumped = false
            lastJumpTime = currentTime
            log.debug("First jump detected, double jump enabled")
        elseif canDoubleJump and not hasDoubleJumped then
            -- Second jump in air - perform double jump
            performDoubleJump()
        end
    end
end

-- Monitor when character lands to reset double jump
local function onHeartbeat()
    if not humanoid or not rootPart then return end
    
    local grounded = checkGrounded()
    
    if grounded and not isGrounded then
        -- Just landed
        canDoubleJump = false
        hasDoubleJumped = false
        log.debug("Character landed, double jump reset")
    end
    
    isGrounded = grounded
end

-- Setup character references
local function setupCharacter(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    
    -- Reset state
    canDoubleJump = false
    hasDoubleJumped = false
    isGrounded = true
    
    log.info("Double jump controller setup for character:", character.Name)
end

-- Initialize the controller
function DoubleJumpController.initialize()
    log.info("Initializing double jump controller")
    
    -- Connect input handling
    UserInputService.InputBegan:Connect(onInputBegan)
    
    -- Connect heartbeat for ground checking
    RunService.Heartbeat:Connect(onHeartbeat)
    
    -- Setup for current character
    if player.Character then
        setupCharacter(player.Character)
    end
    
    -- Setup for future characters
    player.CharacterAdded:Connect(setupCharacter)
    
    log.info("Double jump controller initialized successfully")
end

-- Cleanup function
function DoubleJumpController.cleanup()
    log.info("Cleaning up double jump controller")
    -- Note: In a real implementation, you'd store connections and disconnect them here
end

return DoubleJumpController