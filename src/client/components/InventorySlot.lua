-- Inventory Slot Component
-- Individual Minecraft-style inventory slot

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local e = React.createElement

local function InventorySlot(props)
    local slotIndex = props.slotIndex or 1
    local item = props.item -- {type, name, quantity} or nil if empty
    local size = props.size or 60
    local isEmpty = props.isEmpty or false
    local isSelected = props.isSelected or false
    local isMainSlot = props.isMainSlot or false -- Whether this is one of the main 9 slots
    local displayNumber = props.displayNumber -- Number to display (1-9 for main slots, nil for extra)
    local onSelect = props.onSelect or function() end
    local onInfoClick = props.onInfoClick or nil
    local onRightClick = props.onRightClick or nil
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local layoutOrder = props.LayoutOrder or slotIndex -- Use explicit LayoutOrder or fall back to slotIndex
    
    -- Item data for display
    local itemData = {
        -- Seeds
        wheat = { emoji = "🌾", color = Color3.fromRGB(255, 215, 0) },
        carrot = { emoji = "🥕", color = Color3.fromRGB(255, 140, 0) },
        tomato = { emoji = "🍅", color = Color3.fromRGB(255, 69, 0) },
        potato = { emoji = "🥔", color = Color3.fromRGB(160, 82, 45) },
        corn = { emoji = "🌽", color = Color3.fromRGB(255, 215, 0) }
    }
    
    -- Get display info for item
    local function getItemDisplay()
        if not item then
            return { emoji = "", color = Color3.fromRGB(100, 100, 100) }
        end
        
        local key = item.name
        if item.type == "crop" then
            -- Remove variation prefixes for crops
            key = item.name:gsub("Shiny ", ""):gsub("Rainbow ", ""):gsub("Golden ", ""):gsub("Diamond ", "")
        end
        
        return itemData[key] or { emoji = "❓", color = Color3.fromRGB(200, 200, 200) }
    end
    
    local displayInfo = getItemDisplay()
    
    -- Add right-click detection via UserInputService
    React.useEffect(function()
        if not onRightClick then return end
        
        local UserInputService = game:GetService("UserInputService")
        
        local function onInput(input, gameProcessed)
            if gameProcessed then return end
            if input.UserInputType == Enum.UserInputType.MouseButton2 then -- Right-click
                -- Check if mouse is over this slot (basic check)
                -- Note: This is a simplified approach - a more robust solution would use proper hit detection
                onRightClick(slotIndex, item)
            end
        end
        
        local connection = UserInputService.InputBegan:Connect(onInput)
        
        return function()
            connection:Disconnect()
        end
    end, {onRightClick, slotIndex, item})
    
    -- Calculate transparency and colors based on state
    local backgroundTransparency = isEmpty and 0.8 or 0.2
    local borderColor = isEmpty and Color3.fromRGB(40, 40, 40) or (isSelected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(120, 120, 120))
    local borderTransparency = isEmpty and 0.7 or (isSelected and 0.0 or 0.3)
    local strokeColor = isSelected and Color3.fromRGB(255, 255, 255) or displayInfo.color -- White border when selected
    local strokeThickness = isSelected and 3 or (isEmpty and 1 or 2) -- Slightly thicker stroke when selected
    
    return e("TextButton", {
        Name = "InventorySlot" .. slotIndex,
        Size = UDim2.new(0, size, 0, size),
        BackgroundColor3 = isEmpty and Color3.fromRGB(60, 60, 60) or Color3.fromRGB(80, 80, 80),
        BackgroundTransparency = backgroundTransparency,
        BorderSizePixel = 2,
        BorderColor3 = borderColor,
        Text = "",
        ZIndex = 15,
        LayoutOrder = layoutOrder, -- Ensure proper ordering
        [React.Event.Activated] = function()
            -- Always select the slot when clicked
            onSelect(slotIndex)
        end
    }, {
        Corner = e("UICorner", {
            CornerRadius = UDim.new(0, 4)
        }),
        
        Stroke = e("UIStroke", {
            Color = strokeColor,
            Thickness = strokeThickness,
            Transparency = borderTransparency
        }),
        
        -- Slot number indicator (top-left corner) - only for main slots 1-9
        SlotNumber = displayNumber and e("TextLabel", {
            Name = "SlotNumber",
            Size = UDim2.new(0.3, 0, 0.3, 0),
            Position = UDim2.new(0, 2, 0, 2),
            Text = tostring(displayNumber),
            TextColor3 = isMainSlot and Color3.fromRGB(255, 255, 100) or Color3.fromRGB(150, 150, 150), -- Highlight main slots
            TextScaled = true,
            BackgroundTransparency = 1,
            Font = isMainSlot and Enum.Font.SourceSansBold or Enum.Font.SourceSansLight,
            TextStrokeTransparency = 0.3,
            TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
            ZIndex = 16
        }) or nil,
        
        -- Item icon (if not empty)
        ItemIcon = not isEmpty and item and e("TextLabel", {
            Name = "ItemIcon",
            Size = UDim2.new(0.7, 0, 0.7, 0),
            Position = UDim2.new(0.15, 0, 0.1, 0),
            Text = displayInfo.emoji,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextScaled = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSansBold,
            ZIndex = 16
        }) or nil,
        
        -- Quantity badge (if item has quantity > 1) - positioned bottom-right
        QuantityBadge = not isEmpty and item and item.quantity > 1 and e("TextLabel", {
            Name = "QuantityBadge",
            Size = UDim2.new(0.5, 0, 0.3, 0),
            Position = UDim2.new(0.55, 0, 0.75, 0),
            Text = tostring(item.quantity),
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextScaled = true,
            BackgroundColor3 = Color3.fromRGB(40, 40, 40),
            BackgroundTransparency = 0.3,
            BorderSizePixel = 0,
            Font = Enum.Font.SourceSansBold,
            ZIndex = 17
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0.3, 0)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(200, 200, 200),
                Thickness = 1
            })
        }) or nil,
        
        -- Empty slot indicator (if empty)
        EmptyIndicator = isEmpty and e("TextLabel", {
            Name = "EmptyIndicator",
            Size = UDim2.new(0.6, 0, 0.6, 0),
            Position = UDim2.new(0.2, 0, 0.2, 0),
            Text = "⬜",
            TextColor3 = Color3.fromRGB(100, 100, 100),
            TextScaled = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSansLight,
            TextTransparency = 0.8,
            ZIndex = 16
        }) or nil,
        
        -- Simple selection highlight (only for selected slots)
        SelectionHighlight = isSelected and e("Frame", {
            Name = "SelectionHighlight",
            Size = UDim2.new(1, -4, 1, -4),
            Position = UDim2.new(0, 2, 0, 2),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.85,
            BorderSizePixel = 0,
            ZIndex = 17
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 2)
            })
        }) or nil,
        
        -- Hover effect (subtle highlight for non-selected)
        HoverFrame = not isSelected and e("Frame", {
            Name = "HoverFrame",
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1, -- Will be animated on hover
            BorderSizePixel = 0,
            ZIndex = 16
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 4)
            })
        }) or nil,
        
        -- Info button (only for crops/seeds)
        InfoButton = (not isEmpty and item and (item.type == "crop" or item.type == "seed") and onInfoClick) and e("TextButton", {
            Name = "InfoButton",
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(1, -18, 1, -18),
            Text = "i",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextScaled = true,
            BackgroundColor3 = Color3.fromRGB(50, 100, 200),
            BackgroundTransparency = 0.2,
            BorderSizePixel = 0,
            Font = Enum.Font.SourceSansBold,
            ZIndex = 18,
            [React.Event.Activated] = function()
                if onInfoClick then
                    onInfoClick(item)
                end
            end
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0.5, 0)
            })
        }) or nil
    })
end

return InventorySlot