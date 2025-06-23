-- Fly Controller for Testing
-- Simple fly system to help navigate between farms for testing

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local ClientLogger = require(script.Parent.ClientLogger)
local log = ClientLogger.getModuleLogger("FlyController")

local FlyController = {}

-- Configuration
local FLY_SPEED = 50
local FLY_TOGGLE_KEY = Enum.KeyCode.F -- Press F to toggle fly

-- State
local isFlying = false
local flyConnection = nil
local bodyVelocity = nil
local bodyAngularVelocity = nil
local flyIndicator = nil
local player = Players.LocalPlayer

-- Initialize the fly controller
function FlyController.initialize()
    log.info("Fly controller initialized - Press F to toggle fly mode")
    
    -- Connect to input
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == FLY_TOGGLE_KEY then
            FlyController.toggleFly()
        end
    end)
    
    -- Handle character respawning
    player.CharacterAdded:Connect(function()
        if isFlying then
            -- Wait a moment for character to load, then re-enable fly
            wait(1)
            FlyController.startFlying()
        end
    end)
end

-- Toggle fly mode on/off
function FlyController.toggleFly()
    if isFlying then
        FlyController.stopFlying()
    else
        FlyController.startFlying()
    end
end

-- Start flying
function FlyController.startFlying()
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        log.warn("Cannot start flying - no character or HumanoidRootPart")
        return
    end
    
    local character = player.Character
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character.HumanoidRootPart
    
    if not humanoid or not rootPart then
        log.warn("Cannot start flying - missing humanoid or root part")
        return
    end
    
    isFlying = true
    
    -- Disable normal character physics
    humanoid.PlatformStand = true
    
    -- Create body movers for smooth flying
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = rootPart
    
    bodyAngularVelocity = Instance.new("BodyAngularVelocity")
    bodyAngularVelocity.MaxTorque = Vector3.new(4000, 4000, 4000)
    bodyAngularVelocity.AngularVelocity = Vector3.new(0, 0, 0)
    bodyAngularVelocity.Parent = rootPart
    
    -- Start fly update loop
    flyConnection = RunService.Heartbeat:Connect(function()
        FlyController.updateFly()
    end)
    
    -- Create fly indicator UI
    FlyController.createFlyIndicator()
    
    log.info("Flying enabled! Use WASD to move, Space/Shift for up/down")
end

-- Stop flying
function FlyController.stopFlying()
    if not isFlying then return end
    
    isFlying = false
    
    -- Disconnect update loop
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    
    -- Clean up body movers
    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
    
    if bodyAngularVelocity then
        bodyAngularVelocity:Destroy()
        bodyAngularVelocity = nil
    end
    
    -- Re-enable normal character physics
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.PlatformStand = false
    end
    
    -- Remove fly indicator
    FlyController.removeFlyIndicator()
    
    log.info("Flying disabled")
end

-- Update fly movement based on input
function FlyController.updateFly()
    if not isFlying or not player.Character then return end
    
    local humanoid = player.Character:FindFirstChild("Humanoid")
    local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
    local camera = workspace.CurrentCamera
    
    if not humanoid or not rootPart or not camera then return end
    
    -- Get direct key input instead of using moveVector for more precise control
    local flyDirection = Vector3.new(0, 0, 0)
    
    -- Get camera direction vectors
    local cameraDirection = camera.CFrame.LookVector
    local cameraRight = camera.CFrame.RightVector
    
    -- Direct WASD input for smoother control
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        flyDirection = flyDirection + cameraDirection * FLY_SPEED
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        flyDirection = flyDirection - cameraDirection * FLY_SPEED
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        flyDirection = flyDirection - cameraRight * FLY_SPEED
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        flyDirection = flyDirection + cameraRight * FLY_SPEED
    end
    
    -- Up/down movement
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        flyDirection = flyDirection + Vector3.new(0, FLY_SPEED, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
        flyDirection = flyDirection + Vector3.new(0, -FLY_SPEED, 0)
    end
    
    -- Apply movement with smoother velocity
    if bodyVelocity then
        bodyVelocity.Velocity = flyDirection
    end
    
    -- Keep character upright and facing camera direction
    if bodyAngularVelocity then
        bodyAngularVelocity.AngularVelocity = Vector3.new(0, 0, 0)
    end
    
    -- Keep character orientation aligned with camera for better control feeling
    if rootPart then
        local targetCFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + cameraDirection)
        rootPart.CFrame = rootPart.CFrame:Lerp(targetCFrame, 0.1)
    end
end

-- Get current fly state
function FlyController.isFlying()
    return isFlying
end

-- Create fly mode indicator UI
function FlyController.createFlyIndicator()
    if flyIndicator then return end -- Already exists
    
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Create screen GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FlyIndicator"
    screenGui.Parent = playerGui
    
    -- Create indicator frame
    local frame = Instance.new("Frame")
    frame.Name = "IndicatorFrame"
    frame.Size = UDim2.new(0, 200, 0, 60)
    frame.Position = UDim2.new(1, -220, 0, 20) -- Top right corner
    frame.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    -- Round corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    -- Add fly icon/text
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "✈️ FLY MODE\nWASD + Space/Shift"
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    label.Parent = frame
    
    flyIndicator = screenGui
end

-- Remove fly mode indicator UI
function FlyController.removeFlyIndicator()
    if flyIndicator then
        flyIndicator:Destroy()
        flyIndicator = nil
    end
end

-- Cleanup when leaving
function FlyController.cleanup()
    FlyController.stopFlying()
    log.info("Fly controller cleaned up")
end

return FlyController