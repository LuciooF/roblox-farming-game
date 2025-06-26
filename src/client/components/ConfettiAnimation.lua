-- Confetti Animation Component
-- Creates a celebratory confetti effect for gamepass purchases

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local e = React.createElement
local TweenService = game:GetService("TweenService")

local function ConfettiAnimation(props)
    local visible = props.visible or false
    local onComplete = props.onComplete or function() end
    local screenSize = props.screenSize or Vector2.new(1024, 768)
    
    -- Create confetti particles
    local confettiColors = {
        Color3.fromRGB(255, 215, 0),  -- Gold
        Color3.fromRGB(255, 140, 0),  -- Orange
        Color3.fromRGB(50, 205, 50),  -- Lime Green
        Color3.fromRGB(0, 191, 255),  -- Deep Sky Blue
        Color3.fromRGB(255, 20, 147), -- Deep Pink
        Color3.fromRGB(138, 43, 226), -- Blue Violet
        Color3.fromRGB(255, 69, 0),   -- Red Orange
        Color3.fromRGB(0, 255, 127)   -- Spring Green
    }
    
    local numParticles = 30
    local particles = {}
    
    -- Generate random confetti particles
    for i = 1, numParticles do
        local startX = math.random(0, screenSize.X)
        local startY = -20
        local endX = startX + math.random(-100, 100)
        local endY = screenSize.Y + 50
        local color = confettiColors[math.random(1, #confettiColors)]
        local rotation = math.random(0, 360)
        local size = math.random(8, 16)
        
        particles[i] = {
            startX = startX,
            startY = startY,
            endX = endX,
            endY = endY,
            color = color,
            rotation = rotation,
            size = size,
            delay = math.random(0, 50) / 100 -- Random delay 0-0.5 seconds
        }
    end
    
    React.useEffect(function()
        if visible then
            -- Auto-hide after animation completes
            local timer = task.wait(3) -- Animation duration
            task.spawn(function()
                task.wait(3)
                if onComplete then
                    onComplete()
                end
            end)
        end
    end, {visible})
    
    if not visible then
        return nil
    end
    
    -- Create confetti particles as UI elements
    local confettiElements = {}
    
    for i, particle in ipairs(particles) do
        confettiElements["Particle" .. i] = e("Frame", {
            Name = "ConfettiParticle" .. i,
            Size = UDim2.new(0, particle.size, 0, particle.size),
            Position = UDim2.new(0, particle.startX, 0, particle.startY),
            BackgroundColor3 = particle.color,
            BorderSizePixel = 0,
            ZIndex = 100,
            Rotation = particle.rotation,
            
            -- Animate the particle
            [React.Event.AncestryChanged] = function(gui)
                if gui.Parent then
                    task.wait(particle.delay)
                    
                    -- Fall animation
                    local fallTween = TweenService:Create(gui, 
                        TweenInfo.new(2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                        {
                            Position = UDim2.new(0, particle.endX, 0, particle.endY),
                            Rotation = particle.rotation + 720, -- Two full rotations
                            Transparency = 1
                        }
                    )
                    
                    fallTween:Play()
                    
                    -- Clean up after animation
                    fallTween.Completed:Connect(function()
                        if gui and gui.Parent then
                            gui:Destroy()
                        end
                    end)
                end
            end
        }, {
            Corner = e("UICorner", {
                CornerRadius = UDim.new(0, 2)
            })
        })
    end
    
    return e("ScreenGui", {
        Name = "ConfettiAnimation",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true
    }, {
        -- Confetti Container
        ConfettiContainer = e("Frame", {
            Name = "ConfettiContainer",
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            ZIndex = 100
        }, confettiElements),
        
        -- Celebration Text
        CelebrationText = e("TextLabel", {
            Name = "CelebrationText",
            Size = UDim2.new(0, 400, 0, 80),
            Position = UDim2.new(0.5, -200, 0.3, -40),
            Text = "🎉 GAMEPASS PURCHASED! 🎉",
            TextColor3 = Color3.fromRGB(255, 215, 0),
            TextScaled = true,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSansBold,
            TextStrokeTransparency = 0,
            TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
            ZIndex = 101,
            
            -- Animate celebration text
            [React.Event.AncestryChanged] = function(gui)
                if gui.Parent then
                    -- Pulse animation
                    local pulseTween = TweenService:Create(gui,
                        TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
                        {
                            Size = UDim2.new(0, 450, 0, 90)
                        }
                    )
                    
                    pulseTween:Play()
                    
                    -- Fade out after 2 seconds
                    task.wait(2)
                    local fadeOutTween = TweenService:Create(gui,
                        TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {
                            TextTransparency = 1,
                            TextStrokeTransparency = 1
                        }
                    )
                    
                    fadeOutTween:Play()
                end
            end
        })
    })
end

return ConfettiAnimation