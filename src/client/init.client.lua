-- 3D Farming Game Client
print("🌱 3D Farming Game Client Starting...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for farming remotes
local farmingRemotes = ReplicatedStorage:WaitForChild("FarmingRemotes")
local syncRemote = farmingRemotes:WaitForChild("SyncPlayerData")
local buyRemote = farmingRemotes:WaitForChild("BuyItem")
local sellRemote = farmingRemotes:WaitForChild("SellCrop")
local togglePremiumRemote = farmingRemotes:WaitForChild("TogglePremium")
local rebirthRemote = farmingRemotes:WaitForChild("PerformRebirth")

-- Player data
local playerData = {
    money = 100,
    rebirths = 0,
    inventory = {
        seeds = {},
        crops = {}
    },
    gamepasses = {}
}

-- Create simple UI
local function createUI()
    -- Remove any existing UI
    local existingUI = playerGui:FindFirstChild("FarmingUI")
    if existingUI then
        existingUI:Destroy()
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FarmingUI"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true -- Ignore Roblox topbar
    screenGui.Parent = playerGui
    
    -- Top center stats (Money and Rebirths)
    local topStatsFrame = Instance.new("Frame")
    topStatsFrame.Name = "TopStatsFrame"
    topStatsFrame.Size = UDim2.new(0, 200, 0, 30)
    topStatsFrame.Position = UDim2.new(0.5, -100, 0, 10)
    topStatsFrame.BackgroundTransparency = 1
    topStatsFrame.Parent = screenGui
    
    -- Money display (M)
    local moneyButton = Instance.new("TextButton")
    moneyButton.Name = "MoneyButton"
    moneyButton.Size = UDim2.new(0, 90, 0, 30)
    moneyButton.Position = UDim2.new(0, 0, 0, 0)
    moneyButton.Text = "M: $" .. playerData.money
    moneyButton.TextColor3 = Color3.fromRGB(85, 255, 85)
    moneyButton.TextScaled = true
    moneyButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    moneyButton.BackgroundTransparency = 0.2
    moneyButton.BorderSizePixel = 0
    moneyButton.Font = Enum.Font.SourceSansBold
    moneyButton.Parent = topStatsFrame
    
    local moneyCorner = Instance.new("UICorner")
    moneyCorner.CornerRadius = UDim.new(0, 6)
    moneyCorner.Parent = moneyButton
    
    -- Rebirth display (R)
    local rebirthButton = Instance.new("TextButton")
    rebirthButton.Name = "RebirthButton"
    rebirthButton.Size = UDim2.new(0, 100, 0, 30)
    rebirthButton.Position = UDim2.new(0, 100, 0, 0)
    rebirthButton.Text = "R: " .. playerData.rebirths
    rebirthButton.TextColor3 = Color3.fromRGB(255, 215, 0)
    rebirthButton.TextScaled = true
    rebirthButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    rebirthButton.BackgroundTransparency = 0.2
    rebirthButton.BorderSizePixel = 0
    rebirthButton.Font = Enum.Font.SourceSansBold
    rebirthButton.Parent = topStatsFrame
    
    local rebirthCorner = Instance.new("UICorner")
    rebirthCorner.CornerRadius = UDim.new(0, 6)
    rebirthCorner.Parent = rebirthButton
    
    -- Rebirth tooltip (initially hidden)
    local rebirthTooltip = Instance.new("Frame")
    rebirthTooltip.Name = "RebirthTooltip"
    rebirthTooltip.Size = UDim2.new(0, 180, 0, 50)
    rebirthTooltip.Position = UDim2.new(0, 110, 0, 35)
    rebirthTooltip.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    rebirthTooltip.BackgroundTransparency = 0.1
    rebirthTooltip.BorderSizePixel = 0
    rebirthTooltip.Visible = false
    rebirthTooltip.Parent = topStatsFrame
    
    local tooltipCorner = Instance.new("UICorner")
    tooltipCorner.CornerRadius = UDim.new(0, 6)
    tooltipCorner.Parent = rebirthTooltip
    
    local tooltipLabel = Instance.new("TextLabel")
    tooltipLabel.Name = "TooltipLabel"
    tooltipLabel.Size = UDim2.new(1, -10, 1, -5)
    tooltipLabel.Position = UDim2.new(0, 5, 0, 2)
    tooltipLabel.Text = "Need $1,000 for next rebirth"
    tooltipLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    tooltipLabel.TextScaled = true
    tooltipLabel.BackgroundTransparency = 1
    tooltipLabel.Font = Enum.Font.SourceSans
    tooltipLabel.Parent = rebirthTooltip
    
    -- Hover events for rebirth button
    rebirthButton.MouseEnter:Connect(function()
        local moneyRequired = math.floor(1000 * (2.5 ^ playerData.rebirths))
        local multiplier = 1 + (playerData.rebirths * 0.5)
        tooltipLabel.Text = "Current: " .. multiplier .. "x multiplier\nNext rebirth: $" .. moneyRequired
        rebirthTooltip.Visible = true
    end)
    
    rebirthButton.MouseLeave:Connect(function()
        rebirthTooltip.Visible = false
    end)
    
    -- Rebirth click handler
    rebirthButton.Activated:Connect(function()
        rebirthRemote:FireServer()
    end)
    
    
    
    -- Left side compact UI buttons
    local leftButtonsFrame = Instance.new("Frame")
    leftButtonsFrame.Name = "LeftButtonsFrame"
    leftButtonsFrame.Size = UDim2.new(0, 40, 0, 200)
    leftButtonsFrame.Position = UDim2.new(0, 10, 0, 60)
    leftButtonsFrame.BackgroundTransparency = 1
    leftButtonsFrame.Parent = screenGui
    
    -- Inventory button (I)
    local invButton = Instance.new("TextButton")
    invButton.Name = "InventoryButton"
    invButton.Size = UDim2.new(0, 35, 0, 35)
    invButton.Position = UDim2.new(0, 0, 0, 0)
    invButton.Text = "I"
    invButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    invButton.TextScaled = true
    invButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    invButton.BorderSizePixel = 0
    invButton.Font = Enum.Font.SourceSansBold
    invButton.Parent = leftButtonsFrame
    
    local invButtonCorner = Instance.new("UICorner")
    invButtonCorner.CornerRadius = UDim.new(0, 6)
    invButtonCorner.Parent = invButton
    
    -- Inventory panel (initially hidden)
    local invFrame = Instance.new("Frame")
    invFrame.Name = "InventoryFrame"
    invFrame.Size = UDim2.new(0, 220, 0, 180)
    invFrame.Position = UDim2.new(0, 60, 0, 60)
    invFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    invFrame.BackgroundTransparency = 0.2
    invFrame.BorderSizePixel = 0
    invFrame.Visible = false
    invFrame.Parent = screenGui
    
    local invCorner = Instance.new("UICorner")
    invCorner.CornerRadius = UDim.new(0, 8)
    invCorner.Parent = invFrame
    
    -- Inventory title
    local invTitle = Instance.new("TextLabel")
    invTitle.Size = UDim2.new(1, -20, 0, 25)
    invTitle.Position = UDim2.new(0, 10, 0, 5)
    invTitle.Text = "Inventory"
    invTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    invTitle.TextScaled = true
    invTitle.BackgroundTransparency = 1
    invTitle.Font = Enum.Font.SourceSansBold
    invTitle.Parent = invFrame
    
    -- Seeds section
    local seedsLabel = Instance.new("TextLabel")
    seedsLabel.Name = "SeedsLabel"
    seedsLabel.Size = UDim2.new(1, -20, 0, 100)
    seedsLabel.Position = UDim2.new(0, 10, 0, 35)
    seedsLabel.Text = "Seeds:\nWheat: 0\nTomato: 0\nCarrot: 0\nPotato: 0\nCorn: 0"
    seedsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    seedsLabel.TextScaled = true
    seedsLabel.BackgroundTransparency = 1
    seedsLabel.Font = Enum.Font.SourceSans
    seedsLabel.TextXAlignment = Enum.TextXAlignment.Left
    seedsLabel.TextYAlignment = Enum.TextYAlignment.Top
    seedsLabel.Parent = invFrame
    
    -- Crops section
    local cropsLabel = Instance.new("TextLabel")
    cropsLabel.Name = "CropsLabel"
    cropsLabel.Size = UDim2.new(1, -20, 0, 60)
    cropsLabel.Position = UDim2.new(0, 10, 0, 140)
    cropsLabel.Text = "Crops: None"
    cropsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    cropsLabel.TextScaled = true
    cropsLabel.BackgroundTransparency = 1
    cropsLabel.Font = Enum.Font.SourceSans
    cropsLabel.TextXAlignment = Enum.TextXAlignment.Left
    cropsLabel.TextYAlignment = Enum.TextYAlignment.Top
    cropsLabel.Parent = invFrame
    
    -- Shop button (S)
    local shopButton = Instance.new("TextButton")
    shopButton.Name = "ShopButton"
    shopButton.Size = UDim2.new(0, 35, 0, 35)
    shopButton.Position = UDim2.new(0, 0, 0, 45)
    shopButton.Text = "S"
    shopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    shopButton.TextScaled = true
    shopButton.BackgroundColor3 = Color3.fromRGB(160, 82, 45)
    shopButton.BorderSizePixel = 0
    shopButton.Font = Enum.Font.SourceSansBold
    shopButton.Parent = leftButtonsFrame
    
    local shopCorner = Instance.new("UICorner")
    shopCorner.CornerRadius = UDim.new(0, 6)
    shopCorner.Parent = shopButton
    
    -- Shop panel (initially hidden)
    local shopFrame = Instance.new("Frame")
    shopFrame.Name = "ShopFrame"
    shopFrame.Size = UDim2.new(0, 280, 0, 220)
    shopFrame.Position = UDim2.new(0, 60, 0, 110)
    shopFrame.BackgroundColor3 = Color3.fromRGB(139, 69, 19)
    shopFrame.BorderSizePixel = 0
    shopFrame.Visible = false
    shopFrame.Parent = screenGui
    
    local shopFrameCorner = Instance.new("UICorner")
    shopFrameCorner.CornerRadius = UDim.new(0, 8)
    shopFrameCorner.Parent = shopFrame
    
    -- Shop title
    local shopTitle = Instance.new("TextLabel")
    shopTitle.Size = UDim2.new(1, -20, 0, 30)
    shopTitle.Position = UDim2.new(0, 10, 0, 5)
    shopTitle.Text = "Farming Shop"
    shopTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    shopTitle.TextScaled = true
    shopTitle.BackgroundTransparency = 1
    shopTitle.Font = Enum.Font.SourceSansBold
    shopTitle.Parent = shopFrame
    
    -- Shop buttons (strategic farming options)
    local shopItems = {
        {name = "Wheat Seeds - Fast/Low", type = "seeds", item = "wheat", price = 1},
        {name = "Tomato Seeds - Med/Good", type = "seeds", item = "tomato", price = 3},
        {name = "Carrot Seeds - Steady", type = "seeds", item = "carrot", price = 8},
        {name = "Potato Seeds - Slow/High", type = "seeds", item = "potato", price = 25},
        {name = "Corn Seeds - Premium", type = "seeds", item = "corn", price = 80}
    }
    
    for i, itemData in ipairs(shopItems) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, -20, 0, 30)
        button.Position = UDim2.new(0, 10, 0, 30 + i * 35)
        button.Text = itemData.name .. " - $" .. itemData.price
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextScaled = true
        button.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
        button.BorderSizePixel = 0
        button.Font = Enum.Font.SourceSans
        button.Parent = shopFrame
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 4)
        buttonCorner.Parent = button
        
        button.Activated:Connect(function()
            if playerData.money >= itemData.price then
                buyRemote:FireServer(itemData.type, itemData.item, itemData.price)
            end
        end)
    end
    
    -- Shop toggle
    shopButton.Activated:Connect(function()
        shopFrame.Visible = not shopFrame.Visible
    end)
    
    -- Premium button (P)
    local gamepassButton = Instance.new("TextButton")
    gamepassButton.Name = "GamepassButton"
    gamepassButton.Size = UDim2.new(0, 35, 0, 35)
    gamepassButton.Position = UDim2.new(0, 0, 0, 90)
    gamepassButton.Text = "P"
    gamepassButton.TextColor3 = Color3.fromRGB(0, 0, 0)
    gamepassButton.TextScaled = true
    gamepassButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    gamepassButton.BorderSizePixel = 0
    gamepassButton.Font = Enum.Font.SourceSansBold
    gamepassButton.Parent = leftButtonsFrame
    
    local gamepassCorner = Instance.new("UICorner")
    gamepassCorner.CornerRadius = UDim.new(0, 6)
    gamepassCorner.Parent = gamepassButton
    
    -- Gamepass info panel (initially hidden)
    local gamepassFrame = Instance.new("Frame")
    gamepassFrame.Name = "GamepassFrame"
    gamepassFrame.Size = UDim2.new(0, 280, 0, 200)
    gamepassFrame.Position = UDim2.new(0, 60, 0, 160)
    gamepassFrame.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    gamepassFrame.BorderSizePixel = 0
    gamepassFrame.Visible = false
    gamepassFrame.Parent = screenGui
    
    local gamepassFrameCorner = Instance.new("UICorner")
    gamepassFrameCorner.CornerRadius = UDim.new(0, 8)
    gamepassFrameCorner.Parent = gamepassFrame
    
    -- Gamepass title
    local gamepassTitle = Instance.new("TextLabel")
    gamepassTitle.Size = UDim2.new(1, -20, 0, 30)
    gamepassTitle.Position = UDim2.new(0, 10, 0, 5)
    gamepassTitle.Text = "Premium Automation"
    gamepassTitle.TextColor3 = Color3.fromRGB(0, 0, 0)
    gamepassTitle.TextScaled = true
    gamepassTitle.BackgroundTransparency = 1
    gamepassTitle.Font = Enum.Font.SourceSansBold
    gamepassTitle.Parent = gamepassFrame
    
    -- Gamepass description
    local gamepassDesc = Instance.new("TextLabel")
    gamepassDesc.Name = "GamepassDesc"
    gamepassDesc.Size = UDim2.new(1, -20, 0, 120)
    gamepassDesc.Position = UDim2.new(0, 10, 0, 40)
    gamepassDesc.Text = "Testing Mode - Toggle Premium!\n\nFeatures:\n• Plant all empty plots automatically\n• Harvest all ready crops at once\n• Use the AutoBot NPC on the far left"
    gamepassDesc.TextColor3 = Color3.fromRGB(0, 0, 0)
    gamepassDesc.TextScaled = true
    gamepassDesc.BackgroundTransparency = 1
    gamepassDesc.Font = Enum.Font.SourceSans
    gamepassDesc.TextXAlignment = Enum.TextXAlignment.Left
    gamepassDesc.TextYAlignment = Enum.TextYAlignment.Top
    gamepassDesc.Parent = gamepassFrame
    
    -- Toggle button
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(1, -20, 0, 30)
    toggleButton.Position = UDim2.new(0, 10, 0, 165)
    toggleButton.Text = "Premium: OFF (Click to Toggle)"
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.TextScaled = true
    toggleButton.BackgroundColor3 = Color3.fromRGB(220, 20, 60)
    toggleButton.BorderSizePixel = 0
    toggleButton.Font = Enum.Font.SourceSansBold
    toggleButton.Parent = gamepassFrame
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 4)
    toggleCorner.Parent = toggleButton
    
    -- Toggle premium when clicked
    toggleButton.Activated:Connect(function()
        togglePremiumRemote:FireServer()
    end)
    
    -- Inventory toggle
    invButton.Activated:Connect(function()
        invFrame.Visible = not invFrame.Visible
    end)
    
    -- Gamepass toggle
    gamepassButton.Activated:Connect(function()
        gamepassFrame.Visible = not gamepassFrame.Visible
    end)
    
    return screenGui
end

-- Update UI with current player data
local function updateUI()
    local ui = playerGui:FindFirstChild("FarmingUI")
    if not ui then return end
    
    -- Update top stats
    local moneyButton = ui.TopStatsFrame:FindFirstChild("MoneyButton")
    local rebirthButton = ui.TopStatsFrame:FindFirstChild("RebirthButton")
    
    if moneyButton then
        moneyButton.Text = "M: $" .. playerData.money
    end
    
    if rebirthButton then
        local moneyRequired = math.floor(1000 * (2.5 ^ playerData.rebirths))
        local canRebirth = playerData.money >= moneyRequired
        
        rebirthButton.Text = "R: " .. playerData.rebirths
        
        if canRebirth then
            rebirthButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0) -- Gold when can rebirth
        else
            rebirthButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40) -- Dark when can't
        end
        
        -- Update tooltip if it exists
        local tooltip = ui.TopStatsFrame:FindFirstChild("RebirthTooltip")
        if tooltip and tooltip.Visible then
            local tooltipLabel = tooltip:FindFirstChild("TooltipLabel")
            if tooltipLabel then
                local multiplier = 1 + (playerData.rebirths * 0.5)
                tooltipLabel.Text = "Current: " .. multiplier .. "x multiplier\nNext rebirth: $" .. moneyRequired
            end
        end
    end
    
    -- Update inventory
    local invFrame = ui:FindFirstChild("InventoryFrame")
    if invFrame then
        local seedsLabel = invFrame:FindFirstChild("SeedsLabel")
        if seedsLabel then
            local seedsText = "Seeds:"
            if playerData.inventory and playerData.inventory.seeds then
                for seedType, count in pairs(playerData.inventory.seeds) do
                    seedsText = seedsText .. "\n" .. seedType:gsub("^%l", string.upper) .. ": " .. count
                end
            else
                seedsText = "Seeds: No data"
            end
            seedsLabel.Text = seedsText
        end
        
        local cropsLabel = invFrame:FindFirstChild("CropsLabel")
        if cropsLabel then
            local cropsText = "Crops:"
            local hasCrops = false
            if playerData.inventory and playerData.inventory.crops then
                for cropType, count in pairs(playerData.inventory.crops) do
                    if count > 0 then
                        cropsText = cropsText .. "\n" .. cropType:gsub("^%l", string.upper) .. ": " .. count
                        hasCrops = true
                    end
                end
            end
            if not hasCrops then
                cropsText = "Crops: None"
            end
            cropsLabel.Text = cropsText
        end
    end
    
    -- Update gamepass status (if needed in future)
    -- Currently gamepass UI is handled separately
end

-- Handle player data sync from server
syncRemote.OnClientEvent:Connect(function(newPlayerData)
    playerData = newPlayerData
    updateUI()
end)

-- Create initial UI
wait(1) -- Wait a moment for everything to load
createUI()
updateUI()

print("🌱 3D Farming Game Client Ready!")