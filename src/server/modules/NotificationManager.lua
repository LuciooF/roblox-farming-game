-- Enhanced Notification Management Module
-- Handles all player notifications with toast-style stacking system

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NotificationManager = {}

-- Storage for active notifications per player
local activeNotifications = {}

-- Constants
local NOTIFICATION_WIDTH = 280
local NOTIFICATION_HEIGHT = 40
local NOTIFICATION_MARGIN = 8
local NOTIFICATION_DURATION = 4
local FADE_DURATION = 0.5

-- Initialize notification system for player
local function initializeNotificationSystem(player)
    if activeNotifications[player] then return end
    
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Create persistent notification container
    local containerGui = Instance.new("ScreenGui")
    containerGui.Name = "NotificationContainer"
    containerGui.ResetOnSpawn = false
    containerGui.IgnoreGuiInset = true
    containerGui.Parent = playerGui
    
    local container = Instance.new("Frame")
    container.Name = "NotificationFrame"
    container.Size = UDim2.new(0, NOTIFICATION_WIDTH, 1, 0)
    container.Position = UDim2.new(1, -NOTIFICATION_WIDTH - 10, 0, 10)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Parent = containerGui
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Padding = UDim.new(0, NOTIFICATION_MARGIN)
    layout.Parent = container
    
    activeNotifications[player] = {
        container = container,
        notifications = {},
        count = 0,
        messageTracker = {} -- Track duplicate messages with timestamps
    }
end

-- Create individual notification toast
local function createNotificationToast(player, message, notificationType)
    local data = activeNotifications[player]
    if not data then return end
    
    local notificationId = data.count + 1
    data.count = notificationId
    
    -- Determine notification style based on type
    local bgColor = Color3.fromRGB(40, 40, 50)
    local textColor = Color3.fromRGB(255, 255, 255)
    local borderColor = Color3.fromRGB(100, 100, 120)
    
    if notificationType == "success" then
        bgColor = Color3.fromRGB(30, 60, 30)
        borderColor = Color3.fromRGB(100, 200, 100)
    elseif notificationType == "warning" then
        bgColor = Color3.fromRGB(60, 50, 20)
        borderColor = Color3.fromRGB(255, 200, 100)
    elseif notificationType == "error" then
        bgColor = Color3.fromRGB(60, 30, 30)
        borderColor = Color3.fromRGB(255, 100, 100)
    elseif notificationType == "money" then
        bgColor = Color3.fromRGB(30, 50, 30)
        borderColor = Color3.fromRGB(255, 215, 0)
        textColor = Color3.fromRGB(255, 215, 0)
    end
    
    -- Create notification frame
    local notification = Instance.new("Frame")
    notification.Name = "Notification_" .. notificationId
    notification.Size = UDim2.new(0, NOTIFICATION_WIDTH, 0, NOTIFICATION_HEIGHT)
    notification.BackgroundColor3 = bgColor
    notification.BackgroundTransparency = 0.1
    notification.BorderSizePixel = 0
    notification.Parent = data.container
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notification
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = borderColor
    stroke.Thickness = 1
    stroke.Transparency = 0.3
    stroke.Parent = notification
    
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(1.2 * bgColor.R * 255, 1.2 * bgColor.G * 255, 1.2 * bgColor.B * 255)),
        ColorSequenceKeypoint.new(1, bgColor)
    }
    gradient.Rotation = 90
    gradient.Parent = notification
    
    -- Create text label
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -16, 1, -8)
    label.Position = UDim2.new(0, 8, 0, 4)
    label.Text = message
    label.TextColor3 = textColor
    label.TextSize = 14
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.SourceSans
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextWrapped = true
    label.Parent = notification
    
    -- Animate in
    notification.Position = UDim2.new(1, 50, 0, 0)
    notification.BackgroundTransparency = 1
    label.TextTransparency = 1
    stroke.Transparency = 1
    
    local slideIn = TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0)
    })
    local fadeIn = TweenService:Create(notification, TweenInfo.new(0.3), {
        BackgroundTransparency = 0.1
    })
    local textFadeIn = TweenService:Create(label, TweenInfo.new(0.3), {
        TextTransparency = 0
    })
    local strokeFadeIn = TweenService:Create(stroke, TweenInfo.new(0.3), {
        Transparency = 0.3
    })
    
    slideIn:Play()
    fadeIn:Play()
    textFadeIn:Play()
    strokeFadeIn:Play()
    
    -- Store reference
    local notificationData = {
        frame = notification,
        id = notificationId,
        timestamp = tick(),
        messageKey = nil -- Will be set by sendNotification
    }
    table.insert(data.notifications, notificationData)
    
    -- Auto-remove after duration
    notificationData.removeConnection = spawn(function()
        wait(NOTIFICATION_DURATION)
        NotificationManager.removeNotification(player, notificationId)
    end)
    
    return notificationId
end

-- Remove specific notification
function NotificationManager.removeNotification(player, notificationId)
    local data = activeNotifications[player]
    if not data then return end
    
    for i, notif in ipairs(data.notifications) do
        if notif.id == notificationId then
            local frame = notif.frame
            local label = frame:FindFirstChild("TextLabel")
            local stroke = frame:FindFirstChild("UIStroke")
            
            -- Clean up message tracker for this notification
            if notif.messageKey and data.messageTracker[notif.messageKey] then
                data.messageTracker[notif.messageKey] = nil
            end
            
            -- Disconnect remove connection if it exists
            if notif.removeConnection then
                notif.removeConnection:Disconnect()
            end
            
            -- Animate out
            local slideOut = TweenService:Create(frame, TweenInfo.new(FADE_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 50, 0, 0)
            })
            local fadeOut = TweenService:Create(frame, TweenInfo.new(FADE_DURATION), {
                BackgroundTransparency = 1
            })
            
            if label then
                local textFadeOut = TweenService:Create(label, TweenInfo.new(FADE_DURATION), {
                    TextTransparency = 1
                })
                textFadeOut:Play()
            end
            
            if stroke then
                local strokeFadeOut = TweenService:Create(stroke, TweenInfo.new(FADE_DURATION), {
                    Transparency = 1
                })
                strokeFadeOut:Play()
            end
            
            slideOut:Play()
            fadeOut:Play()
            
            fadeOut.Completed:Connect(function()
                frame:Destroy()
            end)
            
            table.remove(data.notifications, i)
            break
        end
    end
end

-- Send notification to player with optional type
function NotificationManager.sendNotification(player, message, notificationType)
    notificationType = notificationType or "info"
    
    -- Initialize system if needed
    if not activeNotifications[player] then
        initializeNotificationSystem(player)
    end
    
    local data = activeNotifications[player]
    local currentTime = tick()
    
    -- Check for duplicate messages within the last 3 seconds
    local messageKey = message .. "_" .. notificationType
    local tracker = data.messageTracker[messageKey]
    
    if tracker and (currentTime - tracker.lastTime) < 3 then
        -- Update existing notification with counter
        tracker.count = tracker.count + 1
        tracker.lastTime = currentTime
        
        -- Find and update the existing notification
        for _, notif in ipairs(data.notifications) do
            if notif.messageKey == messageKey then
                local label = notif.frame:FindFirstChild("TextLabel")
                if label then
                    if tracker.count == 2 then
                        label.Text = message .. " (x2)"
                    else
                        -- Update counter in existing text
                        label.Text = message .. " (x" .. tracker.count .. ")"
                    end
                end
                
                -- Reset the auto-remove timer
                if notif.removeConnection then
                    notif.removeConnection:Disconnect()
                end
                notif.removeConnection = spawn(function()
                    wait(NOTIFICATION_DURATION)
                    NotificationManager.removeNotification(player, notif.id)
                end)
                return
            end
        end
    else
        -- New message or message has expired
        data.messageTracker[messageKey] = {
            count = 1,
            lastTime = currentTime
        }
    end
    
    -- Limit max notifications to prevent spam
    if #data.notifications >= 10 then
        -- Remove oldest notification
        local oldest = data.notifications[1]
        if oldest then
            NotificationManager.removeNotification(player, oldest.id)
        end
    end
    
    local notificationId = createNotificationToast(player, message, notificationType)
    
    -- Store the message key for deduplication
    for _, notif in ipairs(data.notifications) do
        if notif.id == notificationId then
            notif.messageKey = messageKey
            break
        end
    end
end

-- Convenience methods for different notification types
function NotificationManager.sendSuccess(player, message)
    NotificationManager.sendNotification(player, message, "success")
end

function NotificationManager.sendWarning(player, message)
    NotificationManager.sendNotification(player, message, "warning")
end

function NotificationManager.sendError(player, message)
    NotificationManager.sendNotification(player, message, "error")
end

function NotificationManager.sendMoney(player, message)
    NotificationManager.sendNotification(player, message, "money")
end

-- Clean up when player leaves
function NotificationManager.onPlayerLeft(player)
    if activeNotifications[player] then
        activeNotifications[player] = nil
    end
end

-- Send notification about plant death
function NotificationManager.sendPlantDeathNotification(playerId, seedType, reason)
    local player = game.Players:GetPlayerByUserId(playerId)
    if player then
        NotificationManager.sendError(player, "🥀 " .. seedType .. " died! " .. reason)
    end
end

-- Send notification about rebirth
function NotificationManager.sendRebirthNotification(player, rebirthInfo)
    local message = "⭐ REBIRTH! Level " .. rebirthInfo.newRebirths .. " (" .. rebirthInfo.multiplier .. "x multiplier)"
    NotificationManager.sendSuccess(player, message)
end

-- Send notification about automation results
function NotificationManager.sendAutomationNotification(player, success, message, details)
    local notificationType = success and "success" or "error"
    
    if success and details then
        -- Create shorter, cleaner messages for automation
        if details.cropsGained then
            local totalCrops = 0
            for _, amount in pairs(details.cropsGained) do
                totalCrops = totalCrops + amount
            end
            message = "🚜 Harvested " .. totalCrops .. " crops"
        elseif details.itemsSold then
            local totalItems = 0
            for _, amount in pairs(details.itemsSold) do
                totalItems = totalItems + amount
            end
            message = "💰 Sold " .. totalItems .. " items"
        elseif details.plantsWatered then
            message = "💧 Watered " .. details.plantsWatered .. " plants"
        elseif details.seedsPlanted then
            message = "🌱 Planted " .. details.seedsPlanted .. " seeds"
        end
    end
    
    NotificationManager.sendNotification(player, message, notificationType)
end

return NotificationManager