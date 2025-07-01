-- Debug Panel Component
-- Provides debug controls for testing rebirth and datastore functions

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Simple logging functions for DebugPanel
local function logError(...) error("[ERROR] DebugPanel: " .. table.concat({...}, " ")) end

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
    debugFrame.Size = UDim2.new(0, 300, 0, 500)
    debugFrame.Position = UDim2.new(0.5, -150, 0.5, -250)
    debugFrame.BackgroundColor3 = Color3.fromRGB(240, 245, 255)
    debugFrame.BackgroundTransparency = 0.05
    debugFrame.BorderSizePixel = 0
    debugFrame.Visible = false
    debugFrame.ZIndex = 1000
    debugFrame.Parent = screenGui
    
    
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
    titleFrame.Size = UDim2.new(0, 240, 0, 40)
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
    
    -- Close button (X) in top right
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 18
    closeButton.Font = Enum.Font.GothamBold
    closeButton.BorderSizePixel = 0
    closeButton.ZIndex = 1004
    closeButton.Parent = titleFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton
    
    local closeStroke = Instance.new("UIStroke")
    closeStroke.Color = Color3.fromRGB(200, 0, 0)
    closeStroke.Thickness = 2
    closeStroke.Transparency = 0.2
    closeStroke.Parent = closeButton
    
    -- Close button click handler
    closeButton.MouseButton1Click:Connect(function()
        DebugPanel.hide()
    end)
    
    -- Close button hover effects
    closeButton.MouseEnter:Connect(function()
        closeButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    end)
    
    closeButton.MouseLeave:Connect(function()
        closeButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    end)
    
    -- Create scrollable buttons container with modern styling
    local buttonsFrame = Instance.new("ScrollingFrame")
    buttonsFrame.Name = "ButtonsFrame"
    buttonsFrame.Size = UDim2.new(1, -40, 1, -70)
    buttonsFrame.Position = UDim2.new(0, 20, 0, 50)
    buttonsFrame.BackgroundColor3 = Color3.fromRGB(250, 252, 255)
    buttonsFrame.BackgroundTransparency = 0.2
    buttonsFrame.BorderSizePixel = 0
    buttonsFrame.ZIndex = 1001
    buttonsFrame.Parent = debugFrame
    
    -- Scrolling frame properties
    buttonsFrame.ScrollBarThickness = 8
    buttonsFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 100, 150)
    buttonsFrame.ScrollBarImageTransparency = 0.3
    buttonsFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be set automatically
    buttonsFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    buttonsFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    
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
    
    -- Add 100% Boost button
    local addBoostBtn = DebugPanel.createButton("Add 100% Boost", Color3.fromRGB(255, 215, 0))
    addBoostBtn.LayoutOrder = 8
    addBoostBtn.Parent = buttonsFrame
    addBoostBtn.MouseButton1Click:Connect(function()
        DebugPanel.addProductionBoost()
    end)
    
    -- Remove 100% Boost button
    local removeBoostBtn = DebugPanel.createButton("Remove 100% Boost", Color3.fromRGB(150, 150, 150))
    removeBoostBtn.LayoutOrder = 9
    removeBoostBtn.Parent = buttonsFrame
    removeBoostBtn.MouseButton1Click:Connect(function()
        DebugPanel.removeProductionBoost()
    end)
    
    -- Clear Codes button
    local clearCodesBtn = DebugPanel.createButton("Clear Codes", Color3.fromRGB(255, 200, 0))
    clearCodesBtn.LayoutOrder = 10
    clearCodesBtn.Parent = buttonsFrame
    clearCodesBtn.MouseButton1Click:Connect(function()
        DebugPanel.clearCodes()
    end)
    
    -- Show Random Pro Tip button
    local proTipBtn = DebugPanel.createButton("Show Random Pro Tip", Color3.fromRGB(255, 100, 200))
    proTipBtn.LayoutOrder = 11
    proTipBtn.Parent = buttonsFrame
    proTipBtn.MouseButton1Click:Connect(function()
        DebugPanel.showRandomProTip()
    end)
    
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
    else
        logError("Debug panel frame not found!")
    end
end

-- Hide the debug panel
function DebugPanel.hide()
    if debugFrame then
        debugFrame.Visible = false
        isVisible = false
    end
end

-- Toggle the debug panel
-- Check if player is authorized for debug
function DebugPanel.checkAuthorization()
    local remoteFolder = ReplicatedStorage:FindFirstChild("FarmingRemotes")
    local checkDebugAuth = remoteFolder and remoteFolder:FindFirstChild("CheckDebugAuth")
    
    if checkDebugAuth then
        local success, isAuthorized = pcall(function()
            return checkDebugAuth:InvokeServer()
        end)
        return success and isAuthorized
    else
        -- In studio or testing environment - allow access
        return true
    end
end

function DebugPanel.toggle()
    -- 🔒 SECURITY CHECK: Only allow authorized users
    if not DebugPanel.checkAuthorization() then
        -- Silently ignore for unauthorized users
        return
    end
    
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
end

-- Debug function: Reset rebirths
function DebugPanel.resetRebirths()
    local remotes = ReplicatedStorage:WaitForChild("FarmingRemotes")
    local debugRemote = remotes:WaitForChild("DebugActions")
    
    debugRemote:FireServer("resetRebirths")
end

-- Debug function: Reset datastore
function DebugPanel.resetDatastore()
    local remotes = ReplicatedStorage:WaitForChild("FarmingRemotes")
    local debugRemote = remotes:WaitForChild("DebugActions")
    
    debugRemote:FireServer("resetDatastore")
end

-- Debug function: Perform rebirth (normal system)
function DebugPanel.performRebirth()
    local remotes = ReplicatedStorage:WaitForChild("FarmingRemotes")
    local rebirthRemote = remotes:WaitForChild("PerformRebirth")
    
    rebirthRemote:FireServer()
end

-- Debug function: Add money
function DebugPanel.addMoney()
    local remotes = ReplicatedStorage:WaitForChild("FarmingRemotes")
    local debugRemote = remotes:WaitForChild("DebugActions")
    
    debugRemote:FireServer("addMoney", 10000)
    
    -- Show reward animation
    local RewardsService = require(script.Parent.Parent.RewardsService)
    RewardsService.showMoneyReward(10000, "Debug money reward for testing!")
end

-- Debug function: Check gamepass ownership
function DebugPanel.checkGamepass()
    local remotes = ReplicatedStorage:WaitForChild("FarmingRemotes")
    local debugRemote = remotes:WaitForChild("DebugActions")
    
    debugRemote:FireServer("checkGamepass")
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
    
end

-- Debug function: Clear all redeemed codes
function DebugPanel.clearCodes()
    local CodesService = require(script.Parent.Parent.CodesService)
    local remotes = ReplicatedStorage:WaitForChild("FarmingRemotes")
    
    -- Use the CodesService clear function
    local success = CodesService.clearCodes({
        clearCodes = remotes:WaitForChild("ClearCodes")
    })
    
    if success then
    else
        logError("Failed to clear codes - remote not available")
    end
end

-- Show a random pro tip (debug function)
function DebugPanel.showRandomProTip()
    local ProTipsManager = require(script.Parent.Parent.ProTipsManager)
    
    -- Get a random tip from the available tips (same as ProTipsManager)
    local tips = {
        -- Basic farming tips
        "Plant crops in all your plots to maximize your income!",
        "Water your crops regularly to speed up their growth time.",
        "Save up for better seeds - they give much higher profits!",
        "Check the shop for special seeds with unique properties.",
        "Harvest crops as soon as they're ready to start growing new ones.",
        
        -- Rebirth system tips
        "Rebirth to unlock massive production boosts, better plants, and more plots! Your progress resets but permanent bonuses make it worth it!",
        "Each rebirth increases your chances of growing rare crops and unlocks access to new exciting worlds with unique opportunities!",
        
        -- Plot stacking tips
        "Stack up to 50 plants in the same plot for incredible production! Example: 1 wheat at 50/hour + 1 more = 100/hour from that plot!",
        "Higher stack counts mean exponential profits - always try to fill your plots to maximum capacity!",
        
        -- Ranking and competition
        "Climb the ranks to reach the top of the leaderboard and show off your rarest plants to other players!",
        "Compete with friends to see who can build the most profitable farm empire!",
        
        -- Offline optimization tips
        "Going offline? Plant crops with long water maintenance times! Wheat only produces for 2 hours offline, but some crops last 12+ hours!",
        "Before logging off, water all crops and choose long-duration plants to maximize your offline earnings!",
        "Plan your offline strategy: longer-lasting crops mean more money when you return!",
        
        -- Advanced tips
        "Mix different crop types to discover powerful combinations and unlock hidden bonuses!",
        "The weather affects your crop growth - use it to your advantage for faster harvests!",
        "Higher tier plots can grow multiple crops at once - upgrade wisely!",
        "Some rare seeds can only be found during special events - don't miss out!",
        "Expand your farm by purchasing adjacent plots for maximum growing space!",
        "The golden watering can waters all nearby crops at once - a huge time saver!",
        "Combine harvesting with production boosts for maximum profit per hour!",
        
        -- Social and progression tips
        "Join friends in their farms to help them water crops and learn new strategies!",
        "Click on other players' farms to visit and discover new farming techniques!",
        "Complete the tutorial for easy starting money and essential farming knowledge!",
        "Check daily for free rewards and bonuses to boost your farm's growth!"
    }
    
    local randomTip = tips[math.random(1, #tips)]
    ProTipsManager.showTipNow(randomTip)
end


-- Handle keyboard shortcut (F9 to toggle debug panel)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F9 then
        DebugPanel.toggle()
    end
end)

-- Add 100% production boost
function DebugPanel.addProductionBoost()
    local FarmingRemotes = ReplicatedStorage:WaitForChild("FarmingRemotes")
    local debugRemote = FarmingRemotes:WaitForChild("DebugActions")
    
    debugRemote:FireServer("addProductionBoost", 100)
end

-- Remove 100% production boost
function DebugPanel.removeProductionBoost()
    local FarmingRemotes = ReplicatedStorage:WaitForChild("FarmingRemotes")
    local debugRemote = FarmingRemotes:WaitForChild("DebugActions")
    
    debugRemote:FireServer("removeProductionBoost", 100)
end

-- Initialize debug panel
DebugPanel.create()

return DebugPanel