-- Player stats UI component
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages.React)

local function PlayerStats(props)
    local player = props.player
    local dispatch = props.dispatch
    
    return React.createElement("Frame", {
        Name = "PlayerStats",
        Size = UDim2.new(0, 250, 0, 100),
        Position = UDim2.new(0, 20, 0, 20),
        BackgroundColor3 = Color3.fromRGB(50, 50, 50),
        BorderSizePixel = 2,
        BorderColor3 = Color3.fromRGB(100, 100, 100)
    }, {
        UICorner = React.createElement("UICorner", {
            CornerRadius = UDim.new(0, 8)
        }),
        
        Title = React.createElement("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, -20, 0, 25),
            Position = UDim2.new(0, 10, 0, 5),
            Text = "Player Stats",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextScaled = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSansBold
        }),
        
        MoneyLabel = React.createElement("TextLabel", {
            Name = "MoneyLabel",
            Size = UDim2.new(1, -20, 0, 20),
            Position = UDim2.new(0, 10, 0, 30),
            Text = "$" .. tostring(player.money),
            TextColor3 = Color3.fromRGB(85, 255, 85),
            TextScaled = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSans,
            TextXAlignment = Enum.TextXAlignment.Left
        }),
        
        LevelLabel = React.createElement("TextLabel", {
            Name = "LevelLabel", 
            Size = UDim2.new(1, -20, 0, 20),
            Position = UDim2.new(0, 10, 0, 55),
            Text = "Level " .. tostring(player.level) .. " (" .. tostring(player.experience) .. " XP)",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextScaled = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSans,
            TextXAlignment = Enum.TextXAlignment.Left
        })
    })
end

return PlayerStats