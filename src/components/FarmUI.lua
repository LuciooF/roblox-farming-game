-- Farm UI component
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages.React)

local function PlotButton(props)
    local plotId = props.plotId
    local plot = props.plot
    local inventory = props.inventory
    local dispatch = props.dispatch
    
    local function handleClick()
        if plot then
            -- Check if ready to harvest
            local growthTime = 30 -- 30 seconds for testing
            local timeSinceWatered = plot.lastWatered and (tick() - plot.lastWatered) or 0
            
            if plot.watered and timeSinceWatered >= growthTime then
                -- Harvest
                dispatch({
                    type = "HARVEST_CROP",
                    plotId = plotId,
                    cropType = plot.seedType,
                    amount = 1
                })
                
                dispatch({
                    type = "GAIN_EXPERIENCE",
                    amount = 10
                })
            elseif not plot.watered then
                -- Water plant
                dispatch({
                    type = "WATER_PLANT",
                    plotId = plotId
                })
            end
        else
            -- Plant seed (use first available seed)
            for seedType, count in pairs(inventory.seeds) do
                if count > 0 then
                    dispatch({
                        type = "PLANT_SEED",
                        plotId = plotId,
                        seedType = seedType,
                        soilType = "basic"
                    })
                    break
                end
            end
        end
    end
    
    local buttonText = "Empty"
    local buttonColor = Color3.fromRGB(139, 69, 19) -- Brown
    
    if plot then
        local growthTime = 30
        local timeSinceWatered = plot.lastWatered and (tick() - plot.lastWatered) or 0
        
        if plot.watered and timeSinceWatered >= growthTime then
            buttonText = "Harvest " .. plot.seedType
            buttonColor = Color3.fromRGB(34, 139, 34) -- Green
        elseif plot.watered then
            buttonText = plot.seedType .. " (Growing)"
            buttonColor = Color3.fromRGB(255, 165, 0) -- Orange
        else
            buttonText = plot.seedType .. " (Water)"
            buttonColor = Color3.fromRGB(255, 255, 0) -- Yellow
        end
    end
    
    return React.createElement("TextButton", {
        Name = "Plot" .. plotId,
        Size = UDim2.new(0, 80, 0, 80),
        Position = UDim2.new(0, (plotId % 3) * 90 + 10, 0, math.floor(plotId / 3) * 90 + 10),
        Text = buttonText,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextScaled = true,
        BackgroundColor3 = buttonColor,
        BorderSizePixel = 2,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        Font = Enum.Font.SourceSansBold,
        [React.Event.Activated] = handleClick
    }, {
        UICorner = React.createElement("UICorner", {
            CornerRadius = UDim.new(0, 8)
        })
    })
end

local function FarmUI(props)
    local farm = props.farm
    local inventory = props.inventory
    local dispatch = props.dispatch
    
    local plotElements = {}
    
    -- Create 9 plots (3x3 grid)
    for i = 0, 8 do
        plotElements["Plot" .. i] = React.createElement(PlotButton, {
            plotId = i,
            plot = farm.plots[i],
            inventory = inventory,
            dispatch = dispatch
        })
    end
    
    return React.createElement("Frame", {
        Name = "FarmUI",
        Size = UDim2.new(0, 290, 0, 300),
        Position = UDim2.new(0.5, -145, 0.5, -150),
        BackgroundColor3 = Color3.fromRGB(34, 139, 34),
        BorderSizePixel = 2,
        BorderColor3 = Color3.fromRGB(0, 100, 0)
    }, {
        UICorner = React.createElement("UICorner", {
            CornerRadius = UDim.new(0, 8)
        }),
        
        Title = React.createElement("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, -20, 0, 30),
            Position = UDim2.new(0, 10, 0, 5),
            Text = "Farm Plots",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextScaled = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSansBold
        }),
        
        PlotsContainer = React.createElement("Frame", {
            Name = "PlotsContainer",
            Size = UDim2.new(1, -20, 1, -50),
            Position = UDim2.new(0, 10, 0, 40),
            BackgroundTransparency = 1
        }, plotElements)
    })
end

return FarmUI