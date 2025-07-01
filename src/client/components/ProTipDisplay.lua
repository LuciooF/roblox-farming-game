-- Pro Tip Display Component
-- Shows animated pro tips with rainbow "Pro Tip:" text at bottom center of screen

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local e = React.createElement

-- Import responsive design utilities
local ScreenUtils = require(game:GetService("ReplicatedStorage").Shared.ScreenUtils)

local function ProTipDisplay(props)
    local tipText = props.tipText
    local visible = props.visible or false
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    
    -- State for animation
    local position, setPosition = React.useState(UDim2.new(1, -10, 1.1, 0)) -- Start below screen, right side
    local transparency, setTransparency = React.useState(1)
    
    -- Get responsive scale
    local scale = ScreenUtils.getProportionalScale(screenSize)
    
    -- Calculate sizes
    local maxWidth = math.min(screenSize.X * 0.8, 600 * scale) -- Max 80% of screen width or 600px
    local fontSize = ScreenUtils.getProportionalTextSize(screenSize, 18)
    local paddingSize = ScreenUtils.getProportionalSize(screenSize, 15)
    
    -- Rainbow color animation for "Pro Tip:" text
    local rainbowColor, setRainbowColor = React.useState(Color3.fromHSV(0, 1, 1))
    
    React.useEffect(function()
        if not visible then return end
        
        local startTime = tick()
        local connection
        
        -- Animate rainbow color
        connection = RunService.Heartbeat:Connect(function()
            local elapsed = tick() - startTime
            local hue = (elapsed * 0.5) % 1 -- Complete rainbow cycle every 2 seconds
            setRainbowColor(Color3.fromHSV(hue, 1, 1))
        end)
        
        -- Animate entrance by updating state
        -- (The entrance animation is handled by React state changes)
        
        setPosition(UDim2.new(1, -10, 0.85, 0)) -- Move to bottom right
        setTransparency(0)
        
        -- Schedule exit after 10 seconds
        local exitTimer = task.delay(10, function()
            -- Animate exit
            setPosition(UDim2.new(1, -10, 1.1, 0))
            setTransparency(1)
        end)
        
        return function()
            -- Cleanup
            if connection then
                connection:Disconnect()
            end
            if exitTimer then
                task.cancel(exitTimer)
            end
        end
    end, {visible})
    
    if not visible and transparency >= 1 then
        return nil
    end
    
    return e("Frame", {
        Name = "ProTipContainer",
        Size = UDim2.new(0, maxWidth, 0, 0), -- Height will be automatic
        Position = position,
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        BackgroundTransparency = 0.2 + (transparency * 0.8),
        BorderSizePixel = 0,
        ZIndex = 15, -- Lower than tutorial (20) and other important UI
        AutomaticSize = Enum.AutomaticSize.Y, -- Auto height based on content
    }, {
        -- Corner rounding
        Corner = e("UICorner", {
            CornerRadius = UDim.new(0, 12 * scale)
        }),
        
        -- Subtle glow effect
        Stroke = e("UIStroke", {
            Color = rainbowColor,
            Thickness = 2 * scale,
            Transparency = 0.5 + (transparency * 0.5)
        }),
        
        -- Padding
        Padding = e("UIPadding", {
            PaddingLeft = UDim.new(0, paddingSize),
            PaddingRight = UDim.new(0, paddingSize),
            PaddingTop = UDim.new(0, paddingSize),
            PaddingBottom = UDim.new(0, paddingSize)
        }),
        
        -- Layout
        Layout = e("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 5 * scale)
        }),
        
        -- "Pro Tip:" label with rainbow color
        ProTipLabel = e("TextLabel", {
            Name = "ProTipLabel",
            Size = UDim2.new(0, 0, 0, 0), -- Auto size
            AutomaticSize = Enum.AutomaticSize.XY,
            Text = "Pro Tip:",
            TextColor3 = rainbowColor,
            TextSize = fontSize,
            TextTransparency = transparency,
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            LayoutOrder = 1,
            ZIndex = 16
        }, {
            -- Text stroke for better visibility
            TextStroke = e("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 1.5 * scale,
                Transparency = 0.3 + (transparency * 0.7)
            })
        }),
        
        -- Tip text content
        TipContent = e("TextLabel", {
            Name = "TipContent",
            Size = UDim2.new(1, -80 * scale, 0, 0), -- Leave room for "Pro Tip:" label
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = tipText or "Loading tip...",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = fontSize,
            TextTransparency = transparency,
            TextWrapped = true, -- Enable text wrapping
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            LayoutOrder = 2,
            ZIndex = 16
        }, {
            -- Text stroke for better visibility
            TextStroke = e("UIStroke", {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 1.5 * scale,
                Transparency = 0.3 + (transparency * 0.7)
            })
        })
    })
end

return ProTipDisplay