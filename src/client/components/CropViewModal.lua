-- Crop View Modal Component
-- Shows all crops in a detailed modal view when inventory is clicked

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local e = React.createElement

local Modal = require(script.Parent.Modal)
local CropCard = require(script.Parent.CropCard)

local function CropViewModal(props)
    local playerData = props.playerData or {}
    local visible = props.visible or false
    local onClose = props.onClose or function() end
    local onSellCrop = props.onSellCrop or function() end
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    
    -- Responsive sizing
    local isMobile = screenSize.X < 768
    local scale = isMobile and 0.85 or 1
    local panelWidth = isMobile and 500 or 600
    local panelHeight = isMobile and 400 or 500
    
    -- Get available crops for display
    local function getAvailableCrops()
        local crops = {}
        if playerData.inventory and playerData.inventory.crops then
            local cropTypes = {"wheat", "carrot", "tomato", "potato", "corn"}
            for _, cropType in ipairs(cropTypes) do
                local count = playerData.inventory.crops[cropType] or 0
                if count > 0 then
                    table.insert(crops, {type = cropType, quantity = count})
                end
            end
        end
        return crops
    end
    
    -- Handle crop selling
    local function handleCropSell(cropType, quantity, totalValue)
        if onSellCrop then
            onSellCrop(cropType, quantity)
        end
    end
    
    -- Calculate total sell value for all crops
    local function getTotalSellValue()
        local total = 0
        local availableCrops = getAvailableCrops()
        
        -- Base prices (should match CropRegistry basePrice)
        local basePrices = {
            wheat = 5,
            carrot = 15,
            tomato = 35,
            potato = 25,
            corn = 80
        }
        
        for _, cropData in ipairs(availableCrops) do
            local basePrice = basePrices[cropData.type] or 10
            total = total + (basePrice * cropData.quantity)
        end
        
        return total
    end
    
    -- Handle sell all crops
    local function handleSellAll()
        local availableCrops = getAvailableCrops()
        for _, cropData in ipairs(availableCrops) do
            if cropData.quantity > 0 then
                onSellCrop(cropData.type, cropData.quantity)
            end
        end
    end
    
    return e(Modal, {
        visible = visible,
        onClose = onClose,
        zIndex = 25
    }, {
        CropViewPanel = e("Frame", {
            Name = "CropViewPanel",
            Size = UDim2.new(0, panelWidth * scale, 0, panelHeight * scale),
            Position = UDim2.new(0.5, -panelWidth * scale / 2, 0.5, -panelHeight * scale / 2),
            BackgroundColor3 = Color3.fromRGB(30, 35, 40),
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
            ZIndex = 25
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 15)
            }),
            Stroke = e("UIStroke", {
                Color = Color3.fromRGB(100, 150, 255),
                Thickness = 3,
                Transparency = 0.3
            }),
            Gradient = e("UIGradient", {
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 45, 50)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 30, 35))
                },
                Rotation = 45
            }),
            
            -- Close Button
            CloseButton = e("TextButton", {
                Name = "CloseButton",
                Size = UDim2.new(0, 30, 0, 30),
                Position = UDim2.new(1, -40, 0, 10),
                Text = "✕",
                TextColor3 = Color3.fromRGB(255, 100, 100),
                TextScaled = true,
                BackgroundColor3 = Color3.fromRGB(50, 25, 25),
                BorderSizePixel = 0,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 27,
                [React.Event.Activated] = onClose
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0.5, 0)
                })
            }),
            
            -- Title
            Title = e("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -60, 0, 40),
                Position = UDim2.new(0, 20, 0, 15),
                Text = "🎒 Your Harvested Crops",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 26
            }),
            
            -- Subtitle
            Subtitle = e("TextLabel", {
                Name = "Subtitle",
                Size = UDim2.new(1, -40, 0, 25),
                Position = UDim2.new(0, 20, 0, 50),
                Text = "Click any crop card to sell it for coins!",
                TextColor3 = Color3.fromRGB(200, 200, 200),
                TextScaled = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansItalic,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 26
            }),
            
            -- Sell All Button with total value
            SellAllButton = #getAvailableCrops() > 0 and e("TextButton", {
                Name = "SellAllButton",
                Size = UDim2.new(0, 160, 0, 25),
                Position = UDim2.new(0.5, -80, 0, 75),
                Text = "💰 Sell All ($" .. getTotalSellValue() .. ")",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                BackgroundColor3 = Color3.fromRGB(255, 140, 0),
                BorderSizePixel = 0,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 27,
                [React.Event.Activated] = handleSellAll,
                [React.Event.MouseEnter] = function(gui)
                    gui.BackgroundColor3 = Color3.fromRGB(255, 160, 20)
                end,
                [React.Event.MouseLeave] = function(gui)
                    gui.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
                end
            }, {
                Corner = e("UICorner", {
                    CornerRadius = UDim.new(0, 8)
                }),
                Stroke = e("UIStroke", {
                    Color = Color3.fromRGB(255, 200, 100),
                    Thickness = 2,
                    Transparency = 0.3
                })
            }) or nil,
            
            -- Crops Container
            CropsContainer = e("ScrollingFrame", {
                Name = "CropsContainer",
                Size = UDim2.new(1, -40, 1, -110),
                Position = UDim2.new(0, 20, 0, 105),
                BackgroundColor3 = Color3.fromRGB(20, 25, 30),
                BackgroundTransparency = 0.3,
                BorderSizePixel = 0,
                ScrollBarThickness = 8,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                CanvasSize = UDim2.new(0, 0, 0, math.max(400, math.ceil(#getAvailableCrops() / 3) * 150)),
                ZIndex = 26
            }, (function()
                local availableCrops = getAvailableCrops()
                local children = {}
                
                if #availableCrops == 0 then
                    -- No grid layout for empty message - just center it
                    children.EmptyMessage = e("TextLabel", {
                        Name = "EmptyMessage",
                        Size = UDim2.new(0, 350, 0, 140),
                        Position = UDim2.new(0.5, -175, 0.5, -70),
                        Text = "No crops harvested yet!\n\nHarvest some crops from your plots\nto see them here.",
                        TextColor3 = Color3.fromRGB(150, 150, 150),
                        TextSize = 20,
                        BackgroundTransparency = 1,
                        Font = Enum.Font.SourceSansItalic,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        ZIndex = 27
                    })
                else
                    -- Grid layout for crop cards
                    children.Corner = e("UICorner", {
                        CornerRadius = UDim.new(0, 8)
                    })
                    
                    children.GridLayout = e("UIGridLayout", {
                        CellSize = UDim2.new(0, 160, 0, 140),
                        CellPadding = UDim2.new(0, 10, 0, 10),
                        HorizontalAlignment = Enum.HorizontalAlignment.Left,
                        VerticalAlignment = Enum.VerticalAlignment.Top,
                        SortOrder = Enum.SortOrder.LayoutOrder
                    })
                    
                    children.Padding = e("UIPadding", {
                        PaddingTop = UDim.new(0, 10),
                        PaddingLeft = UDim.new(0, 10),
                        PaddingRight = UDim.new(0, 10),
                        PaddingBottom = UDim.new(0, 10)
                    })
                    
                    -- Add crop cards
                    for i, cropData in ipairs(availableCrops) do
                        children[cropData.type] = e(CropCard, {
                            cropType = cropData.type,
                            quantity = cropData.quantity,
                            onSell = handleCropSell,
                            screenSize = screenSize,
                            LayoutOrder = i
                        })
                    end
                end
                
                return children
            end)())
        })
    })
end

return CropViewModal