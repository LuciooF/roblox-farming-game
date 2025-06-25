-- Tutorial Reset Button Component
-- Shows only when tutorial is completed, for debug purposes

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local e = React.createElement

local function TutorialResetButton(props)
    local remotes = props.remotes
    local visible = props.visible or false
    
    if not visible then
        return nil
    end
    
    -- Responsive sizing
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    local isMobile = screenSize.X < 768
    local scale = isMobile and 0.85 or 1
    local buttonSize = 60 * scale
    
    return e("TextButton", {
        Name = "TutorialResetButton",
        Size = UDim2.new(0, buttonSize, 0, 30 * scale),
        Position = UDim2.new(1, -(buttonSize + 20) * scale, 1, -40 * scale), -- Bottom right
        Text = "Reset Tutorial",
        TextColor3 = Color3.fromRGB(255, 255, 150),
        TextScaled = true,
        BackgroundColor3 = Color3.fromRGB(60, 60, 40),
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Font = Enum.Font.SourceSans,
        ZIndex = 100, -- High z-index to be on top
        [React.Event.Activated] = function()
            print("🎯 Debug: Resetting tutorial")
            if remotes and remotes.tutorialActionRemote then
                remotes.tutorialActionRemote:FireServer("reset")
            end
        end
    }, {
        Corner = e("UICorner", {
            CornerRadius = UDim.new(0, 8)
        }),
        Stroke = e("UIStroke", {
            Color = Color3.fromRGB(255, 255, 100),
            Thickness = 1,
            Transparency = 0.3
        }),
        Gradient = e("UIGradient", {
            Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 80, 60)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 60, 40))
            },
            Rotation = 90
        })
    })
end

return TutorialResetButton