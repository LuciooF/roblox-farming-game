-- Inventory Slots Component
-- Shows a compact grid of inventory slots that opens a crop modal when clicked

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local e = React.createElement

local function InventorySlots(props)
    local playerData = props.playerData or {}
    local onOpenCropView = props.onOpenCropView or function() end
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    
    -- Responsive sizing
    local isMobile = screenSize.X < 768
    local scale = isMobile and 0.8 or 1
    local slotSize = isMobile and 35 or 42
    local spacing = 4
    local slotsPerRow = 5
    local rows = 2
    
    -- Calculate panel size
    local panelWidth = (slotsPerRow * slotSize + (slotsPerRow - 1) * spacing + 20) * scale
    local panelHeight = (rows * slotSize + (rows - 1) * spacing + 20) * scale
    
    -- Get crop data organized by type
    local function getCropData()
        local crops = {}
        if playerData.inventory and playerData.inventory.crops then
            local cropTypes = {"wheat", "carrot", "tomato", "potato", "corn"}
            for _, cropType in ipairs(cropTypes) do
                local quantity = playerData.inventory.crops[cropType] or 0
                if quantity > 0 then
                    table.insert(crops, {type = cropType, quantity = quantity})
                end
            end
        end
        return crops
    end
    
    -- Get crop emoji for display
    local function getCropEmoji(cropType)
        local emojis = {
            wheat = "🌾",
            carrot = "🥕", 
            tomato = "🍅",
            potato = "🥔",
            corn = "🌽"
        }
        return emojis[cropType] or "❓"
    end
    
    -- Generate slots (10 total)
    local function generateSlots()
        local slots = {}
        local crops = getCropData()
        
        for i = 1, 10 do
            local crop = crops[i] -- Will be nil if no crop for this slot
            local isEmpty = crop == nil
            
            slots["Slot" .. i] = e("Frame", {
                Name = "Slot" .. i,
                Size = UDim2.new(0, slotSize * scale, 0, slotSize * scale),
                BackgroundColor3 = isEmpty and Color3.fromRGB(40, 40, 40) or Color3.fromRGB(60, 45, 30),
                BackgroundTransparency = 0.1,
                BorderSizePixel = 0,
                ZIndex = 16,
                LayoutOrder = i
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 4)
                }),
                Stroke = e("UIStroke", {
                    Color = isEmpty and Color3.fromRGB(80, 80, 80) or Color3.fromRGB(150, 120, 80),
                    Thickness = 1,
                    Transparency = 0.5
                }),
                
                -- Crop icon (if has crop)
                CropIcon = not isEmpty and e("TextLabel", {
                    Name = "CropIcon",
                    Size = UDim2.new(0.7, 0, 0.7, 0),
                    Position = UDim2.new(0.15, 0, 0.05, 0),
                    Text = getCropEmoji(crop.type),
                    TextScaled = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.SourceSansBold,
                    ZIndex = 17
                }) or nil,
                
                -- Quantity label (if has crop)
                Quantity = not isEmpty and e("TextLabel", {
                    Name = "Quantity",
                    Size = UDim2.new(1, 0, 0.3, 0),
                    Position = UDim2.new(0, 0, 0.7, 0),
                    Text = tostring(crop.quantity),
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextScaled = true,
                    BackgroundTransparency = 1,
                    Font = Enum.Font.SourceSansBold,
                    TextStrokeTransparency = 0.5,
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 17
                }) or nil
            })
        end
        
        return slots
    end
    
    return e("TextButton", {
        Name = "InventorySlots",
        Size = UDim2.new(0, panelWidth, 0, panelHeight),
        Position = UDim2.new(1, -panelWidth - 10, 0, 60),
        BackgroundColor3 = Color3.fromRGB(25, 20, 30),
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 15,
        [React.Event.Activated] = onOpenCropView,
        [React.Event.MouseEnter] = function(gui)
            gui.BackgroundColor3 = Color3.fromRGB(35, 28, 40)
        end,
        [React.Event.MouseLeave] = function(gui)
            gui.BackgroundColor3 = Color3.fromRGB(25, 20, 30)
        end
    }, {
        Corner = e("UICorner", {
            CornerRadius = UDim.new(0, 8)
        }),
        Stroke = e("UIStroke", {
            Color = Color3.fromRGB(100, 150, 255),
            Thickness = 2,
            Transparency = 0.3
        }),
        Gradient = e("UIGradient", {
            Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 28, 40)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 15, 25))
            },
            Rotation = 45
        }),
        
        -- Title
        Title = e("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, -10, 0, 16),
            Position = UDim2.new(0, 5, 0, 2),
            Text = "🎒 Inventory",
            TextColor3 = Color3.fromRGB(200, 200, 255),
            TextScaled = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSansBold,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 16
        }),
        
        -- Slots container
        SlotsContainer = e("Frame", {
            Name = "SlotsContainer",
            Size = UDim2.new(1, -10, 1, -25),
            Position = UDim2.new(0, 5, 0, 20),
            BackgroundTransparency = 1,
            ZIndex = 16
        }, (function()
            local children = {
                ListLayout = e("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Top,
                    Padding = UDim.new(0, spacing),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Wraps = true -- Allow wrapping to next row
                })
            }
            
            -- Add all slots
            local slots = generateSlots()
            for key, slot in pairs(slots) do
                children[key] = slot
            end
            
            return children
        end)()),
        
        -- Click hint
        ClickHint = e("TextLabel", {
            Name = "ClickHint",
            Size = UDim2.new(1, -10, 0, 12),
            Position = UDim2.new(0, 5, 1, -14),
            Text = "Click to view crops",
            TextColor3 = Color3.fromRGB(150, 150, 150),
            TextSize = 8,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSansItalic,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 16
        })
    })
end

return InventorySlots