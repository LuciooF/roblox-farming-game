-- Debug Panel Component
-- Provides debug controls for testing rebirth and datastore functions

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Logger = require(script.Parent.Parent.ClientLogger)
local log = Logger.getModuleLogger("DebugPanel")

local DebugPanel = {}

-- State
local debugFrame = nil
local isVisible = false

-- Create the debug panel UI
function DebugPanel.create()
    if debugFrame then
        debugFrame:Destroy()
    end
    
    -- Create ScreenGui first
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DebugPanelScreen"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui
    
    -- Create main debug frame with modern styling
    debugFrame = Instance.new("Frame")
    debugFrame.Name = "DebugPanel"
    debugFrame.Size = UDim2.new(0, 280, 0, 480)
    debugFrame.Position = UDim2.new(0.5, -140, 0.5, -240)
    debugFrame.BackgroundColor3 = Color3.fromRGB(240, 245, 255)
    debugFrame.BackgroundTransparency = 0.05
    debugFrame.BorderSizePixel = 0
    debugFrame.Visible = false
    debugFrame.ZIndex = 1000
    debugFrame.Parent = screenGui
    
    log.info("Debug panel created with ScreenGui wrapper")
    
    -- Add modern corner styling
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = debugFrame
    
    -- Add modern stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 100, 150) -- Debug pink theme
    stroke.Thickness = 3
    stroke.Transparency = 0.1
    stroke.Parent = debugFrame
    
    -- Add modern gradient background
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.3, Color3.fromRGB(250, 240, 255)),
        ColorSequenceKeypoint.new(0.7, Color3.fromRGB(245, 230, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(240, 220, 255))
    }
    gradient.Rotation = 135
    gradient.Parent = debugFrame
    
    -- Floating Title (positioned outside main panel like other UIs)
    local titleFrame = Instance.new("Frame")
    titleFrame.Name = "FloatingTitle"
    titleFrame.Size = UDim2.new(0, 220, 0, 40)
    titleFrame.Position = UDim2.new(0, -10, 0, -25)
    titleFrame.BackgroundColor3 = Color3.fromRGB(255, 100, 150)
    titleFrame.BorderSizePixel = 0
    titleFrame.ZIndex = 1002
    titleFrame.Parent = debugFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleFrame
    
    local titleGradient = Instance.new("UIGradient")
    titleGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 140, 180)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 80, 140))
    }
    titleGradient.Rotation = 45
    titleGradient.Parent = titleFrame
    
    local titleStroke = Instance.new("UIStroke")
    titleStroke.Color = Color3.fromRGB(255, 255, 255)
    titleStroke.Thickness = 3
    titleStroke.Transparency = 0.2
    titleStroke.Parent = titleFrame
    
    -- Title text
    local title = Instance.new("TextLabel")
    title.Name = "TitleText"
    title.Size = UDim2.new(1, -10, 1, 0)
    title.Position = UDim2.new(0, 5, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🐛 DEBUG PANEL 🐛"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.ZIndex = 1003
    title.Parent = titleFrame
    
    local titleTextStroke = Instance.new("UIStroke")
    titleTextStroke.Color = Color3.fromRGB(0, 0, 0)
    titleTextStroke.Thickness = 2
    titleTextStroke.Transparency = 0.5
    titleTextStroke.Parent = title
    
    -- Create buttons container with modern styling
    local buttonsFrame = Instance.new("Frame")
    buttonsFrame.Name = "ButtonsFrame"
    buttonsFrame.Size = UDim2.new(1, -40, 1, -70)
    buttonsFrame.Position = UDim2.new(0, 20, 0, 50)
    buttonsFrame.BackgroundColor3 = Color3.fromRGB(250, 252, 255)
    buttonsFrame.BackgroundTransparency = 0.2
    buttonsFrame.BorderSizePixel = 0
    buttonsFrame.ZIndex = 1001
    buttonsFrame.Parent = debugFrame
    
    local buttonsCorner = Instance.new("UICorner")
    buttonsCorner.CornerRadius = UDim.new(0, 15)
    buttonsCorner.Parent = buttonsFrame
    
    local buttonsGradient = Instance.new("UIGradient")
    buttonsGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(245, 255, 245))
    }
    buttonsGradient.Rotation = 45
    buttonsGradient.Parent = buttonsFrame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.Padding = UDim.new(0, 8)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.Parent = buttonsFrame
    
    local buttonsPadding = Instance.new("UIPadding")
    buttonsPadding.PaddingTop = UDim.new(0, 15)
    buttonsPadding.PaddingLeft = UDim.new(0, 15)
    buttonsPadding.PaddingRight = UDim.new(0, 15)
    buttonsPadding.PaddingBottom = UDim.new(0, 15)
    buttonsPadding.Parent = buttonsFrame
    
    -- +1 Rebirth button
    local addRebirthBtn = DebugPanel.createButton("+1 Rebirth", Color3.fromRGB(0, 200, 0))
    addRebirthBtn.LayoutOrder = 1
    addRebirthBtn.Parent = buttonsFrame
    addRebirthBtn.MouseButton1Click:Connect(function()
        DebugPanel.addRebirth()
    end)
    
    -- Reset Rebirths button
    local resetRebirthsBtn = DebugPanel.createButton("Reset Rebirths", Color3.fromRGB(200, 100, 0))
    resetRebirthsBtn.LayoutOrder = 2
    resetRebirthsBtn.Parent = buttonsFrame
    resetRebirthsBtn.MouseButton1Click:Connect(function()
        DebugPanel.resetRebirths()
    end)
    
    -- Reset Datastore button
    local resetDatastoreBtn = DebugPanel.createButton("Reset Datastore", Color3.fromRGB(200, 0, 0))
    resetDatastoreBtn.LayoutOrder = 3
    resetDatastoreBtn.Parent = buttonsFrame
    resetDatastoreBtn.MouseButton1Click:Connect(function()
        DebugPanel.resetDatastore()
    end)
    
    -- Perform Rebirth button (using normal system)
    local performRebirthBtn = DebugPanel.createButton("Perform Rebirth", Color3.fromRGB(100, 0, 200))
    performRebirthBtn.LayoutOrder = 4
    performRebirthBtn.Parent = buttonsFrame
    performRebirthBtn.MouseButton1Click:Connect(function()
        DebugPanel.performRebirth()
    end)
    
    -- Add 10k Money button
    local addMoneyBtn = DebugPanel.createButton("Add $10k", Color3.fromRGB(50, 200, 50))
    addMoneyBtn.LayoutOrder = 5
    addMoneyBtn.Parent = buttonsFrame
    addMoneyBtn.MouseButton1Click:Connect(function()
        DebugPanel.addMoney()
    end)
    
    -- Check Gamepass button
    local checkGamepassBtn = DebugPanel.createButton("Check Gamepass", Color3.fromRGB(255, 140, 0))
    checkGamepassBtn.LayoutOrder = 6
    checkGamepassBtn.Parent = buttonsFrame
    checkGamepassBtn.MouseButton1Click:Connect(function()
        DebugPanel.checkGamepass()
    end)
    
    -- Test Rewards button
    local testRewardsBtn = DebugPanel.createButton("Test Rewards", Color3.fromRGB(255, 100, 255))
    testRewardsBtn.LayoutOrder = 7
    testRewardsBtn.Parent = buttonsFrame
    testRewardsBtn.MouseButton1Click:Connect(function()
        DebugPanel.testRewards()
    end)
    
    -- Close button
    local closeBtn = DebugPanel.createButton("Close Panel", Color3.fromRGB(100, 100, 100))
    closeBtn.LayoutOrder = 8
    closeBtn.Parent = buttonsFrame
    closeBtn.MouseButton1Click:Connect(function()
        DebugPanel.hide()
    end)
    
    log.info("Debug panel created")
end

-- Create a button with modern styling matching other UI components
function DebugPanel.createButton(text, color)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 0, 45)
    button.BackgroundColor3 = color
    button.Text = ""
    button.BorderSizePixel = 0
    button.ZIndex = 1002
    button.AutoButtonColor = false
    
    -- Modern corner styling
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = button
    
    -- Modern stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(
        math.max(0, color.R * 255 - 40),
        math.max(0, color.G * 255 - 40),
        math.max(0, color.B * 255 - 40)
    )
    stroke.Thickness = 2
    stroke.Transparency = 0.2
    stroke.Parent = button
    
    -- Modern gradient
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(
            math.min(255, color.R * 255 + 30),
            math.min(255, color.G * 255 + 30),
            math.min(255, color.B * 255 + 30)
        )),
        ColorSequenceKeypoint.new(1, color)
    }
    gradient.Rotation = 90
    gradient.Parent = button
    
    -- Button text with stroke
    local buttonText = Instance.new("TextLabel")
    buttonText.Size = UDim2.new(1, 0, 1, 0)
    buttonText.BackgroundTransparency = 1
    buttonText.Text = text
    buttonText.TextColor3 = Color3.fromRGB(255, 255, 255)
    buttonText.TextScaled = true
    buttonText.Font = Enum.Font.SourceSansBold
    buttonText.ZIndex = 1003
    buttonText.Parent = button
    
    local textStroke = Instance.new("UIStroke")
    textStroke.Color = Color3.fromRGB(0, 0, 0)
    textStroke.Thickness = 2
    textStroke.Transparency = 0.5
    textStroke.Parent = buttonText
    
    -- 3D Shadow effect
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 2, 1, 2)
    shadow.Position = UDim2.new(0, 2, 0, 2)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.7
    shadow.BorderSizePixel = 0
    shadow.ZIndex = 1001
    shadow.Parent = button
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 10)
    shadowCorner.Parent = shadow
    
    -- Enhanced hover effects
    local originalColor = color
    local originalStrokeColor = stroke.Color
    
    button.MouseEnter:Connect(function()
        local lighterColor = Color3.fromRGB(
            math.min(255, color.R * 255 + 40),
            math.min(255, color.G * 255 + 40),
            math.min(255, color.B * 255 + 40)
        )
        button.BackgroundColor3 = lighterColor
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(
                math.min(255, lighterColor.R * 255 + 20),
                math.min(255, lighterColor.G * 255 + 20),
                math.min(255, lighterColor.B * 255 + 20)
            )),
            ColorSequenceKeypoint.new(1, lighterColor)
        }
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = originalColor
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(
                math.min(255, originalColor.R * 255 + 30),
                math.min(255, originalColor.G * 255 + 30),
                math.min(255, originalColor.B * 255 + 30)
            )),
            ColorSequenceKeypoint.new(1, originalColor)
        }
    end)
    
    return button
end

-- Show the debug panel
function DebugPanel.show()
    if not debugFrame then
        DebugPanel.create()
    end
    if debugFrame then
        debugFrame.Visible = true
        isVisible = true
        log.info("Debug panel shown - frame exists and set to visible")
    else
        log.error("Debug panel frame not found!")
    end
end

-- Hide the debug panel
function DebugPanel.hide()
    if debugFrame then
        debugFrame.Visible = false
        isVisible = false
        log.info("Debug panel hidden")
    end
end

-- Toggle the debug panel
function DebugPanel.toggle()
    if isVisible then
        DebugPanel.hide()
    else
        DebugPanel.show()
    end
end

-- Debug function: Add rebirth
function DebugPanel.addRebirth()
    local remotes = ReplicatedStorage:WaitForChild("FarmingRemotes")
    local debugRemote = remotes:WaitForChild("DebugActions")
    
    debugRemote:FireServer("addRebirth")
    log.info("Requested +1 rebirth via debug")
end

-- Debug function: Reset rebirths
function DebugPanel.resetRebirths()
    local remotes = ReplicatedStorage:WaitForChild("FarmingRemotes")
    local debugRemote = remotes:WaitForChild("DebugActions")
    
    debugRemote:FireServer("resetRebirths")
    log.info("Requested rebirth reset via debug")
end

-- Debug function: Reset datastore
function DebugPanel.resetDatastore()
    local remotes = ReplicatedStorage:WaitForChild("FarmingRemotes")
    local debugRemote = remotes:WaitForChild("DebugActions")
    
    debugRemote:FireServer("resetDatastore")
    log.info("Requested datastore reset via debug")
end

-- Debug function: Perform rebirth (normal system)
function DebugPanel.performRebirth()
    local remotes = ReplicatedStorage:WaitForChild("FarmingRemotes")
    local rebirthRemote = remotes:WaitForChild("PerformRebirth")
    
    rebirthRemote:FireServer()
    log.info("Requested normal rebirth")
end

-- Debug function: Add money
function DebugPanel.addMoney()
    local remotes = ReplicatedStorage:WaitForChild("FarmingRemotes")
    local debugRemote = remotes:WaitForChild("DebugActions")
    
    debugRemote:FireServer("addMoney", 10000)
    log.info("Requested +$10,000 via debug")
    
    -- Show reward animation
    local RewardsService = require(script.Parent.Parent.RewardsService)
    RewardsService.showMoneyReward(10000, "Debug money reward for testing!")
end

-- Debug function: Check gamepass ownership
function DebugPanel.checkGamepass()
    local remotes = ReplicatedStorage:WaitForChild("FarmingRemotes")
    local debugRemote = remotes:WaitForChild("DebugActions")
    
    debugRemote:FireServer("checkGamepass")
    log.info("Requested gamepass ownership check")
end

-- Debug function: Test different reward types
function DebugPanel.testRewards()
    local RewardsService = require(script.Parent.Parent.RewardsService)
    
    -- Test multiple rewards in sequence
    RewardsService.showMoneyReward(1500, "You found some coins!")
    
    -- Test future pet reward (will queue after money)
    RewardsService.showPetReward("dog", "Golden Retriever", "A loyal farming companion!")
    
    -- Test future boost reward (will queue after pet)
    RewardsService.showBoostReward("Growth Speed", 30, 2, "Your crops grow faster!")
    
    log.info("Queued test rewards")
end


-- Handle keyboard shortcut (F9 to toggle debug panel)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F9 then
        DebugPanel.toggle()
    end
end)

-- Initialize
DebugPanel.create()

return DebugPanel