-- Boost Panel Component
-- Shows active boosts and their effects in bottom left corner

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local Players = game:GetService("Players")
local SocialService = game:GetService("SocialService")
local e = React.createElement

-- Import responsive design utilities
local ScreenUtils = require(game:GetService("ReplicatedStorage").Shared.ScreenUtils)

local player = Players.LocalPlayer

local function BoostPanel(props)
    local playerData = props.playerData
    local weatherData = props.weatherData or {}
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    
    local scale = ScreenUtils.getCustomScale(screenSize, 0.9, 1)
    local padding = ScreenUtils.getPadding(screenSize, 10, 15)
    
    -- Calculate boosts
    local boosts = {}
    
    -- Gamepass 2x Money Boost
    if playerData.gamepasses and playerData.gamepasses.moneyMultiplier then
        table.insert(boosts, {
            icon = "💰",
            name = "2x Money Boost",
            effect = "+100%",
            effects = {
                "Double money from all crop sales",
                "Permanent gamepass benefit",
                "Stacks with other boosts"
            },
            description = "Your 2x Money Boost gamepass doubles all money earned from selling crops!",
            duration = "Permanent",
            color = Color3.fromRGB(255, 215, 0) -- Gold color
        })
    end
    
    -- Online Time Boost (multiple effects)
    table.insert(boosts, {
        icon = "⏰",
        name = "Online Time",
        effect = "+5%",
        effects = {
            "+5% money from selling crops",
            "+10% chance for bonus crops when harvesting",
            "+3% faster crop growth timers"
        },
        description = "Being online gives you multiple farming advantages! You earn more money, get bonus crops, and crops grow faster.",
        duration = "While online",
        color = Color3.fromRGB(100, 255, 100)
    })
    
    -- Weather-based boosts
    if weatherData.current then
        local weatherName = weatherData.current.name
        if weatherName == "Rainy" or weatherName == "Thunderstorm" then
            table.insert(boosts, {
                icon = "💧",
                name = "Rainy Weather",
                effect = "AUTO",
                effects = {
                    "Free automatic watering of all crops",
                    "Root vegetables (carrot, potato) grow 20% faster",
                    "No water evaporation during rain"
                },
                description = "Rainy weather provides multiple benefits for your farm! Perfect for growing root vegetables.",
                duration = "While " .. weatherName:lower(),
                color = Color3.fromRGB(100, 150, 255)
            })
        elseif weatherName == "Sunny" then
            table.insert(boosts, {
                icon = "☀️",
                name = "Sunny Weather",
                effect = "+15%",
                effects = {
                    "Wheat, corn & tomato grow 20% faster",
                    "+15% chance for golden crops (worth 2x)",
                    "Plants require 30% more watering"
                },
                description = "Sunny weather accelerates growth for sun-loving crops and increases chances of premium harvests!",
                duration = "While sunny",
                color = Color3.fromRGB(255, 255, 100)
            })
        end
    end
    
    -- Friends Boost (check actual friends in this server)
    local friendsOnline = 0
    local friendsList = {}
    
    -- Count friends who are actually in this server
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            -- In a real implementation, you'd check if they're friends
            -- For now, just count other players as potential friends
            -- This should be replaced with actual friendship checking
            local isFriend = false -- TODO: Add actual friend checking
            if isFriend then
                friendsOnline = friendsOnline + 1
                table.insert(friendsList, otherPlayer.Name)
            end
        end
    end
    
    if friendsOnline > 0 then
        local moneyBoost = friendsOnline * 10 -- 10% per friend
        table.insert(boosts, {
            icon = "👥",
            name = "Friends Boost",
            effect = "+" .. moneyBoost .. "%",
            effects = {
                "+" .. moneyBoost .. "% money from all sales",
                "+5% chance for rare seed drops per friend",
                "Shared plot watering (friends can help water)",
                "Friends online: " .. table.concat(friendsList, ", ")
            },
            description = "Having friends online provides multiple cooperative farming benefits!",
            duration = "While friends online",
            color = Color3.fromRGB(255, 150, 255),
            friendsList = friendsList
        })
    else
        -- Encourage inviting friends
        table.insert(boosts, {
            icon = "👤",
            name = "Invite Friends",
            effect = "0%",
            effects = {
                "Get +10% money boost per friend online",
                "Unlock rare seed drops from friends",
                "Enable cooperative plot watering",
                "Share farming achievements and compete"
            },
            description = "Invite friends to unlock powerful cooperative farming features!",
            duration = "Click to invite friends",
            color = Color3.fromRGB(150, 150, 150),
            isInactive = true,
            canInvite = true
        })
    end
    
    -- Hover state for showing descriptions
    local hoveredBoost, setHoveredBoost = React.useState(nil)
    
    if #boosts == 0 then
        return nil -- Don't show anything if no boosts
    end
    
    -- Container for individual boost squares
    local boostSquares = {}
    local squareSize = 35 * scale -- Made smaller
    local spacing = 6 * scale
    
    for i, boost in ipairs(boosts) do
        local xOffset = (i - 1) * (squareSize + spacing)
        
        boostSquares["BoostSquare" .. i] = e("TextButton", {
            Name = "BoostSquare" .. i,
            Size = UDim2.new(0, squareSize, 0, squareSize),
            Position = UDim2.new(0, padding + xOffset, 1, -padding - squareSize),
            BackgroundColor3 = boost.isInactive and Color3.fromRGB(40, 40, 40) or boost.color,
            BackgroundTransparency = boost.isInactive and 0.3 or 0.2,
            BorderSizePixel = 0,
            ZIndex = 15,
            Text = "",
[React.Event.MouseEnter] = function()
                setHoveredBoost(boost)
            end,
            [React.Event.MouseLeave] = function()
                setHoveredBoost(nil)
            end,
            [React.Event.Activated] = function()
                if boost.canInvite then
                    -- Open Roblox invite friends prompt
                    local success, err = pcall(function()
                        SocialService:PromptGameInvite(player)
                    end)
                    if not success then
                    end
                end
            end
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 12)
            }),
            
            Stroke = e("UIStroke", {
                Color = boost.isInactive and Color3.fromRGB(100, 100, 100) or boost.color,
                Thickness = 2,
                Transparency = boost.isInactive and 0.6 or 0.4
            }),
            
            Gradient = boost.isInactive and nil or e("UIGradient", {
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, boost.color),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(
                        math.max(0, boost.color.R * 255 - 30),
                        math.max(0, boost.color.G * 255 - 30),
                        math.max(0, boost.color.B * 255 - 30)
                    ))
                },
                Rotation = 45
            }),
            
            -- Large Icon
            Icon = e("TextLabel", {
                Name = "Icon",
                Size = UDim2.new(0.6, 0, 0.6, 0),
                Position = UDim2.new(0.2, 0, 0.05, 0),
                Text = boost.icon,
                TextColor3 = boost.isInactive and Color3.fromRGB(120, 120, 120) or Color3.fromRGB(255, 255, 255),
                TextSize = 14,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 16
            }),
            
            -- Effect Text (percentage)
            Effect = e("TextLabel", {
                Name = "Effect",
                Size = UDim2.new(1, 0, 0.35, 0),
                Position = UDim2.new(0, 0, 0.65, 0),
                Text = boost.effect,
                TextColor3 = boost.isInactive and Color3.fromRGB(120, 120, 120) or Color3.fromRGB(255, 255, 255),
                TextSize = 8,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 16
            }),
            
        })
    end
    
    -- Add tooltip to the container if there's a hovered boost
    if hoveredBoost then
        boostSquares.Tooltip = e("Frame", {
            Name = "GlobalTooltip",
            Size = UDim2.new(0, 400, 0, 180),
            Position = UDim2.new(0, padding + 100, 1, -padding - squareSize - 190),
            BackgroundColor3 = Color3.fromRGB(255, 255, 0), -- Bright yellow
            BackgroundTransparency = 0,
            BorderSizePixel = 2,
            BorderColor3 = Color3.fromRGB(255, 0, 0), -- Red border
            ZIndex = 2000
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 10)
            }),
            
            Title = e("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -10, 0, 25),
                Position = UDim2.new(0, 5, 0, 5),
                Text = hoveredBoost.icon .. " " .. hoveredBoost.name .. " - " .. hoveredBoost.effect,
                TextColor3 = Color3.fromRGB(0, 0, 0),
                TextSize = 16,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 2001
            }),
            
            Description = e("TextLabel", {
                Name = "Description",
                Size = UDim2.new(1, -10, 0, 25),
                Position = UDim2.new(0, 5, 0, 30),
                Text = hoveredBoost.description,
                TextColor3 = Color3.fromRGB(0, 0, 0),
                TextSize = 11,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSans,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextWrapped = true,
                ZIndex = 2001
            }),
            
            -- Effects list (bulleted)
            Effects = hoveredBoost.effects and e("TextLabel", {
                Name = "Effects",
                Size = UDim2.new(1, -10, 1, -90),
                Position = UDim2.new(0, 5, 0, 55),
                Text = "• " .. table.concat(hoveredBoost.effects, "\n• "),
                TextColor3 = Color3.fromRGB(50, 50, 50),
                TextSize = 10,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSans,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextWrapped = true,
                ZIndex = 2001
            }) or nil,
            
            Duration = e("TextLabel", {
                Name = "Duration",
                Size = UDim2.new(1, -10, 0, 20),
                Position = UDim2.new(0, 5, 1, -25),
                Text = "Duration: " .. hoveredBoost.duration,
                TextColor3 = Color3.fromRGB(100, 100, 100),
                TextSize = 10,
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansItalic,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 2001
            })
        })
    end

    return e("Frame", {
        Name = "BoostContainer",
        Size = UDim2.new(1, 0, 1, 0), -- Full screen container
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = 14
    }, boostSquares)
end

return BoostPanel