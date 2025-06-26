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
    
    -- Create main debug frame
    debugFrame = Instance.new("Frame")
    debugFrame.Name = "DebugPanel"
    debugFrame.Size = UDim2.new(0, 250, 0, 400)
    debugFrame.Position = UDim2.new(1, -260, 0, 10) -- Top right corner
    debugFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    debugFrame.BorderSizePixel = 2
    debugFrame.BorderColor3 = Color3.fromRGB(255, 0, 0) -- Red border for debug
    debugFrame.Visible = false
    debugFrame.Parent = playerGui
    
    -- Add corner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = debugFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    title.Text = "🐛 DEBUG PANEL 🐛"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = debugFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = title
    
    -- Create buttons container
    local buttonsFrame = Instance.new("Frame")
    buttonsFrame.Name = "ButtonsFrame"
    buttonsFrame.Size = UDim2.new(1, -20, 1, -50)
    buttonsFrame.Position = UDim2.new(0, 10, 0, 40)
    buttonsFrame.BackgroundTransparency = 1
    buttonsFrame.Parent = debugFrame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.Padding = UDim.new(0, 5)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = buttonsFrame
    
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
    
    -- Check Gamepass button
    local checkGamepassBtn = DebugPanel.createButton("Check Gamepass", Color3.fromRGB(255, 140, 0))
    checkGamepassBtn.LayoutOrder = 5
    checkGamepassBtn.Parent = buttonsFrame
    checkGamepassBtn.MouseButton1Click:Connect(function()
        DebugPanel.checkGamepass()
    end)
    
    -- Close button
    local closeBtn = DebugPanel.createButton("Close Panel", Color3.fromRGB(100, 100, 100))
    closeBtn.LayoutOrder = 6
    closeBtn.Parent = buttonsFrame
    closeBtn.MouseButton1Click:Connect(function()
        DebugPanel.hide()
    end)
    
    log.info("Debug panel created")
end

-- Create a button with consistent styling
function DebugPanel.createButton(text, color)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 35)
    button.BackgroundColor3 = color
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextScaled = true
    button.Font = Enum.Font.SourceSans
    button.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = button
    
    -- Hover effect
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(
            math.min(255, color.R * 255 + 30),
            math.min(255, color.G * 255 + 30),
            math.min(255, color.B * 255 + 30)
        )
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = color
    end)
    
    return button
end

-- Show the debug panel
function DebugPanel.show()
    if not debugFrame then
        DebugPanel.create()
    end
    debugFrame.Visible = true
    isVisible = true
    log.info("Debug panel shown")
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

-- Debug function: Check gamepass ownership
function DebugPanel.checkGamepass()
    local remotes = ReplicatedStorage:WaitForChild("FarmingRemotes")
    local debugRemote = remotes:WaitForChild("DebugActions")
    
    debugRemote:FireServer("checkGamepass")
    log.info("Requested gamepass ownership check")
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