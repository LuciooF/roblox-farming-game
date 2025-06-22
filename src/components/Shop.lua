-- Shop UI component
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages.react)

local function ShopItem(props)
    local item = props.item
    local itemKey = props.itemKey
    local itemType = props.itemType
    local player = props.player
    local dispatch = props.dispatch
    
    local canAfford = player.money >= item.price
    
    local function handlePurchase()
        if canAfford then
            dispatch({
                type = "BUY_ITEM",
                item = itemKey,
                itemType = itemType,
                cost = item.price,
                quantity = 1
            })
        end
    end
    
    return React.createElement("TextButton", {
        Name = itemKey,
        Size = UDim2.new(1, -20, 0, 30),
        Position = UDim2.new(0, 10, 0, props.index * 35),
        Text = item.name .. " - $" .. item.price,
        TextColor3 = canAfford and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150),
        TextScaled = true,
        BackgroundColor3 = canAfford and Color3.fromRGB(70, 130, 180) or Color3.fromRGB(100, 100, 100),
        BorderSizePixel = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        Font = Enum.Font.SourceSans,
        [React.Event.Activated] = handlePurchase
    }, {
        UICorner = React.createElement("UICorner", {
            CornerRadius = UDim.new(0, 4)
        })
    })
end

local function Shop(props)
    local shop = props.shop
    local player = props.player
    local inventory = props.inventory
    local dispatch = props.dispatch
    
    local shopVisible, setShopVisible = React.useState(false)
    
    local function toggleShop()
        setShopVisible(not shopVisible)
    end
    
    local seedItems = {}
    local index = 0
    for seedKey, seedData in pairs(shop.seeds) do
        seedItems[seedKey] = React.createElement(ShopItem, {
            item = seedData,
            itemKey = seedKey,
            itemType = "seed",
            player = player,
            dispatch = dispatch,
            index = index
        })
        index = index + 1
    end
    
    local equipmentItems = {}
    for equipKey, equipData in pairs(shop.equipment) do
        equipmentItems[equipKey] = React.createElement(ShopItem, {
            item = equipData,
            itemKey = equipKey,
            itemType = "equipment",
            player = player,
            dispatch = dispatch,
            index = index
        })
        index = index + 1
    end
    
    return React.createElement("Frame", {
        Name = "ShopContainer",
        Size = UDim2.new(0, 1, 0, 1),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1
    }, {
        ShopButton = React.createElement("TextButton", {
            Name = "ShopButton",
            Size = UDim2.new(0, 100, 0, 40),
            Position = UDim2.new(1, -120, 0, 20),
            Text = "Shop",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextScaled = true,
            BackgroundColor3 = Color3.fromRGB(160, 82, 45),
            BorderSizePixel = 2,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Font = Enum.Font.SourceSansBold,
            [React.Event.Activated] = toggleShop
        }, {
            UICorner = React.createElement("UICorner", {
                CornerRadius = UDim.new(0, 8)
            })
        }),
        
        ShopFrame = shopVisible and React.createElement("Frame", {
            Name = "ShopFrame",
            Size = UDim2.new(0, 300, 0, 400),
            Position = UDim2.new(1, -320, 0, 70),
            BackgroundColor3 = Color3.fromRGB(139, 69, 19),
            BorderSizePixel = 2,
            BorderColor3 = Color3.fromRGB(0, 0, 0)
        }, {
            UICorner = React.createElement("UICorner", {
                CornerRadius = UDim.new(0, 8)
            }),
            
            Title = React.createElement("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -20, 0, 30),
                Position = UDim2.new(0, 10, 0, 5),
                Text = "Shop",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansBold
            }),
            
            SeedsTitle = React.createElement("TextLabel", {
                Name = "SeedsTitle",
                Size = UDim2.new(1, -20, 0, 25),
                Position = UDim2.new(0, 10, 0, 40),
                Text = "Seeds",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansBold
            }),
            
            SeedsContainer = React.createElement("Frame", {
                Name = "SeedsContainer",
                Size = UDim2.new(1, 0, 0, 150),
                Position = UDim2.new(0, 0, 0, 70),
                BackgroundTransparency = 1
            }, seedItems),
            
            EquipmentTitle = React.createElement("TextLabel", {
                Name = "EquipmentTitle",
                Size = UDim2.new(1, -20, 0, 25),
                Position = UDim2.new(0, 10, 0, 230),
                Text = "Equipment",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansBold
            }),
            
            EquipmentContainer = React.createElement("Frame", {
                Name = "EquipmentContainer",
                Size = UDim2.new(1, 0, 0, 150),
                Position = UDim2.new(0, 0, 0, 260),
                BackgroundTransparency = 1
            }, equipmentItems)
        }) or nil
    })
end

return Shop