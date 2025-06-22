-- Notification Management Module
-- Handles all player notifications and UI messages

local NotificationManager = {}

-- Send notification to player
function NotificationManager.sendNotification(player, message)
    spawn(function()
        -- Create a temporary GUI notification
        local playerGui = player:WaitForChild("PlayerGui")
        
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "Notification_" .. tick()
        screenGui.Parent = playerGui
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 300, 0, 50)
        frame.Position = UDim2.new(0.5, -150, 0, 100)
        frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        frame.BackgroundTransparency = 0.3
        frame.BorderSizePixel = 0
        frame.Parent = screenGui
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = frame
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -20, 1, -10)
        label.Position = UDim2.new(0, 10, 0, 5)
        label.Text = message
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextScaled = true
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.SourceSansBold
        label.Parent = frame
        
        -- Fade out after 3 seconds
        wait(3)
        
        local tweenService = game:GetService("TweenService")
        local tween = tweenService:Create(frame, TweenInfo.new(1), {BackgroundTransparency = 1})
        local textTween = tweenService:Create(label, TweenInfo.new(1), {TextTransparency = 1})
        
        tween:Play()
        textTween:Play()
        
        tween.Completed:Connect(function()
            screenGui:Destroy()
        end)
    end)
end

-- Send notification about plant death
function NotificationManager.sendPlantDeathNotification(playerId, seedType, reason)
    local player = game.Players:GetPlayerByUserId(playerId)
    if player then
        NotificationManager.sendNotification(player, "Your " .. seedType .. " died! " .. reason)
    end
end

-- Send notification about rebirth
function NotificationManager.sendRebirthNotification(player, rebirthInfo)
    local message = "REBIRTH! You are now Rebirth " .. rebirthInfo.newRebirths .. "!\nCrop value multiplier: " .. rebirthInfo.multiplier .. "x"
    NotificationManager.sendNotification(player, message)
end

-- Send notification about automation results
function NotificationManager.sendAutomationNotification(player, success, message, details)
    if success and details then
        -- Add details to message
        if details.cropsGained then
            for cropType, amount in pairs(details.cropsGained) do
                message = message .. "\n" .. amount .. " " .. cropType
            end
        elseif details.itemsSold then
            for cropType, amount in pairs(details.itemsSold) do
                message = message .. "\n" .. amount .. " " .. cropType
            end
        end
    end
    
    NotificationManager.sendNotification(player, message)
end

return NotificationManager