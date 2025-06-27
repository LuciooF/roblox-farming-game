-- Hotbar Inventory Component
-- Minecraft-style sliding hotbar with expandable slots

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local TweenService = game:GetService("TweenService")
local e = React.createElement
local assets = require(game:GetService("ReplicatedStorage").Shared.assets)
local ClientLogger = require(script.Parent.Parent.ClientLogger)

local log = ClientLogger.getModuleLogger("HotbarInventory")

local InventorySlot = require(script.Parent.InventorySlot)
local HandItem = require(script.Parent.HandItem)

local function HotbarInventory(props)
    local playerData = props.playerData or {}
    local visible = props.visible or false
    local remotes = props.remotes or {}
    local onShowInfo = props.onShowInfo -- Handler from parent to show info modal
    
    
    -- Responsive sizing
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local isMobile = screenSize.X < 768
    local scale = isMobile and 0.8 or 1
    local slotSize = isMobile and 50 or 60
    
    -- State for hotbar (9 main slots + expandable slots)
    local animationRef = React.useRef()
    local selectedSlot, setSelectedSlot = React.useState(1) -- Track selected slot (1-indexed)
    local extraSlots = playerData.extraSlots or 0 -- Additional slots beyond the main 9
    
    -- Animation state
    local animationPlaying, setAnimationPlaying = React.useState(false)
    
    -- Constants for hotbar layout
    local MAIN_SLOTS = 9 -- Fixed 9 main slots
    local totalSlots = MAIN_SLOTS + extraSlots
    local totalSlotsToShow = totalSlots + 1 -- +1 for the plus button
    local fixedSlotsToShow = math.min(10, totalSlotsToShow) -- Show max 10 slots in fixed width (9 + plus button, or fewer if no extra slots)
    local hotbarWidth = fixedSlotsToShow * (slotSize * scale + 8) + 16 -- Fixed width based on visible slots
    
    -- Get inventory data organized left to right (left-packed)
    local function getInventoryItems()
        local items = {}
        
        -- Add crops in consistent order (crops are now plantable)
        if playerData.inventory and playerData.inventory.crops then
            local cropTypes = {"wheat", "carrot", "tomato", "potato", "corn"} -- Consistent order
            for _, cropType in ipairs(cropTypes) do
                local quantity = playerData.inventory.crops[cropType] or 0
                if quantity > 0 then
                    table.insert(items, {type = "crop", name = cropType, quantity = quantity})
                end
            end
            
        end
        
        return items
    end
    
    -- Get items for a specific slot (1-indexed, left-packed)
    local function getItemForSlot(slotIndex)
        local allItems = getInventoryItems()
        return allItems[slotIndex] -- Returns nil if slot is empty
    end
    
    -- Get currently selected item
    local function getSelectedItem()
        return getItemForSlot(selectedSlot)
    end
    
    -- Auto-select first available item when inventory changes (but don't sync to server automatically)
    React.useEffect(function()
        local allItems = getInventoryItems()
        if #allItems > 0 then
            -- If current selection is empty, select first available item (UI only)
            if not getItemForSlot(selectedSlot) then
                setSelectedSlot(1)
            end
        else
            -- No items available, select slot 1 anyway (UI only)
            setSelectedSlot(1)
        end
    end, {playerData})
    
    -- Handle slot selection
    local function handleSlotSelect(slotIndex)
        -- Check if slot has an item before selecting
        local item = getItemForSlot(slotIndex)
        
        if item then
            setSelectedSlot(slotIndex)
        end
    end
    
    -- Handle crop info display
    local function handleCropInfo(item)
        if onShowInfo then
            -- Extract the base crop type from the item name (remove variation prefixes)
            local cropType = item.name
            if item.type == "crop" then
                -- Remove variation prefixes for crops
                cropType = item.name:gsub("Shiny ", ""):gsub("Rainbow ", ""):gsub("Golden ", ""):gsub("Diamond ", "")
            end
            
            onShowInfo(cropType)
        end
    end
    
    -- Keyboard input handling for slot selection (1-9)
    React.useEffect(function()
        local UserInputService = game:GetService("UserInputService")
        
        local function onKeyPressed(input, gameProcessed)
            if gameProcessed or not visible then return end
            
            -- Check for number keys 1-9
            if input.UserInputType == Enum.UserInputType.Keyboard then
                local keyCode = input.KeyCode
                local slotNumbers = {
                    [Enum.KeyCode.One] = 1,
                    [Enum.KeyCode.Two] = 2,
                    [Enum.KeyCode.Three] = 3,
                    [Enum.KeyCode.Four] = 4,
                    [Enum.KeyCode.Five] = 5,
                    [Enum.KeyCode.Six] = 6,
                    [Enum.KeyCode.Seven] = 7,
                    [Enum.KeyCode.Eight] = 8,
                    [Enum.KeyCode.Nine] = 9
                }
                
                local slotNumber = slotNumbers[keyCode]
                if slotNumber and slotNumber <= MAIN_SLOTS then
                    -- Check if slot has an item before selecting
                    local item = getItemForSlot(slotNumber)
                    
                    if item then
                        setSelectedSlot(slotNumber)
                    end
                end
            end
        end
        
        local connection = UserInputService.InputBegan:Connect(onKeyPressed)
        
        return function()
            connection:Disconnect()
        end
    end, {visible, MAIN_SLOTS})
    
    -- Sync selection to server when selectedSlot changes OR when inventory updates
    React.useEffect(function()
        -- Send current selection to server whenever slot changes or inventory updates
        local selectedItem = getItemForSlot(selectedSlot)
        
        if remotes.selectedItem then
            remotes.selectedItem:FireServer(selectedItem)
        end
    end, {selectedSlot, playerData}) -- Sync when selectedSlot changes OR when playerData updates
    
    -- Hand item management - show selected item in player's hand
    React.useEffect(function()
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        
        if visible then
            local selectedItem = getSelectedItem()
            HandItem.updateHandItem(player, selectedItem)
        else
            HandItem.removeHandItem(player)
        end
        
        -- Cleanup when component unmounts
        return function()
            HandItem.removeHandItem(player)
        end
    end, {selectedSlot, visible, playerData})
    
    -- Animation effect when visibility changes
    React.useEffect(function()
        if not animationRef.current then return end
        
        local tweenInfo = TweenInfo.new(
            0.3, -- Duration
            Enum.EasingStyle.Back,
            Enum.EasingDirection.Out
        )
        
        if visible then
            setAnimationPlaying(true)
            -- Slide up and fade in (positioned at very bottom)
            local slideTween = TweenService:Create(animationRef.current, tweenInfo, {
                Position = UDim2.new(0.5, -hotbarWidth/2, 1, -(slotSize * scale + 16)),
                BackgroundTransparency = 0.1
            })
            slideTween:Play()
            slideTween.Completed:Connect(function()
                setAnimationPlaying(false)
            end)
        else
            -- Slide down and fade out
            local slideTween = TweenService:Create(animationRef.current, tweenInfo, {
                Position = UDim2.new(0.5, -hotbarWidth/2, 1, 20),
                BackgroundTransparency = 1
            })
            slideTween:Play()
        end
    end, {visible, hotbarWidth, scale})
    
    -- Handle slot purchase
    local function handleSlotPurchase()
        if remotes.buySlot then
            remotes.buySlot:FireServer()
        end
    end
    
    -- Handle right-click on inventory slot to cycle through available crops
    local function handleSlotRightClick(slotIndex, currentItem)
        if not currentItem or currentItem.type ~= "crop" then return end
        
        log.debug("Right-clicked slot", slotIndex, "- cycling through available crops")
        
        -- Get all available crop types (crops with quantity > 0)
        local availableCrops = {}
        local cropsOrder = {"wheat", "carrot", "tomato", "potato", "corn"} -- Consistent order
        
        for _, cropType in ipairs(cropsOrder) do
            local quantity = (playerData.inventory and playerData.inventory.crops and playerData.inventory.crops[cropType]) or 0
            if quantity > 0 then
                table.insert(availableCrops, cropType)
            end
        end
        
        if #availableCrops <= 1 then
            log.debug("Only one crop type available, no cycling needed")
            return
        end
        
        -- Find current crop in available list and cycle to next one
        local currentIndex = 1
        for i, cropType in ipairs(availableCrops) do
            if cropType == currentItem.name then
                currentIndex = i
                break
            end
        end
        
        -- Cycle to next crop (wrap around to beginning)
        local nextIndex = (currentIndex % #availableCrops) + 1
        local nextCrop = availableCrops[nextIndex]
        
        log.debug("Cycling from", currentItem.name, "to", nextCrop, "in slot", slotIndex)
        
        -- Select this slot and it will automatically show the next available crop
        setSelectedSlot(slotIndex)
    end
    
    -- Tooltip state
    local showTooltip, setShowTooltip = React.useState(false)
    
    -- Generate slot elements (9 main slots + extra slots + plus button)
    local function generateSlots()
        local slotElements = {} -- Use array to preserve order
        
        
        -- Create all slots (main 9 + extra slots) in order
        for i = 1, totalSlots do
            local item = getItemForSlot(i) -- Left-packed items
            local isSelected = selectedSlot == i
            local isMainSlot = i <= MAIN_SLOTS
            local displayNumber = isMainSlot and i or nil -- Only show numbers 1-9 for main slots
            
            
            -- Add slot to array in correct order
            table.insert(slotElements, e(InventorySlot, {
                slotIndex = i,
                item = item,
                size = slotSize * scale,
                isEmpty = item == nil,
                isSelected = isSelected,
                isMainSlot = isMainSlot,
                displayNumber = displayNumber,
                onSelect = handleSlotSelect,
                onInfoClick = item and item.type == "crop" and handleCropInfo or nil,
                onRightClick = handleSlotRightClick,
                screenSize = screenSize,
                LayoutOrder = i -- Explicitly set layout order
            }))
        end
        
        -- Add the plus button for purchasing new slots (always last)
        table.insert(slotElements, e("ImageButton", {
            Name = "PlusButton",
            Size = UDim2.new(0, slotSize * scale, 0, slotSize * scale),
            BackgroundColor3 = Color3.fromRGB(40, 120, 40),
            BackgroundTransparency = 0.2,
            BorderSizePixel = 2,
            BorderColor3 = Color3.fromRGB(80, 200, 80),
            Image = assets["Plus/Plus 64.png"],
            ImageColor3 = Color3.fromRGB(255, 255, 255),
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 15,
            LayoutOrder = totalSlots + 1, -- Explicitly set layout order for plus button
            [React.Event.Activated] = handleSlotPurchase,
            [React.Event.MouseEnter] = function()
                setShowTooltip(true)
            end,
            [React.Event.MouseLeave] = function()
                setShowTooltip(false)
            end
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 4)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(80, 200, 80),
                Thickness = 2,
                Transparency = 0.3
            }),
            -- Cost label
            CostLabel = e("TextLabel", {
                Name = "CostLabel",
                Size = UDim2.new(1, 0, 0.25, 0),
                Position = UDim2.new(0, 0, 0.75, 0),
                Text = "$50",
                TextColor3 = Color3.fromRGB(255, 255, 100),
                TextScaled = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansBold,
                TextStrokeTransparency = 0.3,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                ZIndex = 16
            }),
            -- Tooltip
            Tooltip = e("TextLabel", {
                Name = "Tooltip",
                Size = UDim2.new(3, 0, 0.8, 0),
                Position = UDim2.new(-1, 0, -0.9, 0),
                Text = "Buy permanent inventory slot",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                BackgroundColor3 = Color3.fromRGB(20, 20, 20),
                BackgroundTransparency = 0.1,
                BorderSizePixel = 0,
                Font = Enum.Font.SourceSans,
                Visible = showTooltip,
                ZIndex = 20
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 4)
                }),
                Stroke = e("UIStroke", {
                    Color = Color3.fromRGB(100, 100, 100),
                    Thickness = 1,
                    Transparency = 0.5
                })
            })
        }))
        
        return slotElements
    end
    
    return e("Frame", {
        Name = "HotbarInventory",
        Size = UDim2.new(0, hotbarWidth, 0, slotSize * scale + 16), -- Fixed size regardless of extra slots
        Position = UDim2.new(0.5, -hotbarWidth/2, 1, 20), -- Start hidden below screen
        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        BackgroundTransparency = visible and 0.1 or 1,
        BorderSizePixel = 0,
        Visible = true, -- Always visible for animation
        ZIndex = 14,
        ref = animationRef
    }, {
        Corner = e("UICorner", {
            CornerRadius = UDim.new(0, 8)
        }),
        Stroke = e("UIStroke", {
            Color = Color3.fromRGB(100, 100, 100),
            Thickness = 2,
            Transparency = 0.3
        }),
        
        -- Scrollable container when there are more than 10 total elements (9 + plus button)
        SlotsContainer = totalSlotsToShow > 10 and e("ScrollingFrame", {
            Name = "SlotsContainer",
            Size = UDim2.new(1, -16, 1, -16),
            Position = UDim2.new(0, 8, 0, 8),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Color3.fromRGB(150, 150, 150),
            ScrollBarImageTransparency = 0.5,
            CanvasSize = UDim2.new(0, totalSlotsToShow * (slotSize * scale + 8), 1, 0),
            ScrollingDirection = Enum.ScrollingDirection.X,
            ZIndex = 14
        }, (function()
            -- Try using direct children array approach
            local slots = generateSlots()
            local children = {
                ListLayout = e("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Left,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 8),
                    SortOrder = Enum.SortOrder.LayoutOrder -- Explicitly use LayoutOrder for sorting
                })
            }
            
            -- Add slots using React.createElement directly
            for i, slot in ipairs(slots) do
                children[i] = slot
            end
            
            return children
        end)()) or e("Frame", {
            Name = "SlotsContainer",
            Size = UDim2.new(1, -16, 1, -16),
            Position = UDim2.new(0, 8, 0, 8),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 14
        }, (function()
            -- Try using direct children array approach
            local slots = generateSlots()
            local children = {
                ListLayout = e("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 8),
                    SortOrder = Enum.SortOrder.LayoutOrder -- Explicitly use LayoutOrder for sorting
                })
            }
            
            -- Add slots using React.createElement directly
            for i, slot in ipairs(slots) do
                children[i] = slot
            end
            
            return children
        end)())
    })
end

return HotbarInventory