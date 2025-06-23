-- Hand Item Component
-- Creates a visual representation of the selected item in the player's hand

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local HandItem = {}

-- Item colors for different seeds/crops
local itemColors = {
    -- Seeds
    wheat = Color3.fromRGB(255, 215, 0), -- Golden
    carrot = Color3.fromRGB(255, 140, 0), -- Orange
    tomato = Color3.fromRGB(255, 69, 0),  -- Red-orange
    potato = Color3.fromRGB(160, 82, 45), -- Brown
    corn = Color3.fromRGB(255, 215, 0),   -- Golden
}

-- Get item color based on type and name
local function getItemColor(item)
    if not item then return Color3.fromRGB(100, 100, 100) end
    
    local key = item.name
    -- Remove variation prefixes for crops
    if item.type == "crop" then
        key = item.name:gsub("Shiny ", ""):gsub("Rainbow ", ""):gsub("Golden ", ""):gsub("Diamond ", "")
    end
    
    return itemColors[key] or Color3.fromRGB(100, 200, 100)
end

-- Create or update hand item
function HandItem.updateHandItem(player, selectedItem)
    if not player or not player.Character then return end
    
    local character = player.Character
    local rightArm = character:FindFirstChild("Right Arm") or character:FindFirstChild("RightHand")
    
    if not rightArm then return end
    
    -- Remove existing hand item
    local existingItem = rightArm:FindFirstChild("HandItem")
    if existingItem then
        existingItem:Destroy()
    end
    
    -- Don't create item if no selection
    if not selectedItem then return end
    
    -- Create new hand item
    local handItem = Instance.new("Part")
    handItem.Name = "HandItem"
    handItem.Size = Vector3.new(0.8, 0.8, 0.8) -- Small sphere
    handItem.Shape = Enum.PartType.Ball
    handItem.Material = Enum.Material.Neon
    handItem.Color = getItemColor(selectedItem)
    handItem.Anchored = false
    handItem.CanCollide = false
    handItem.TopSurface = Enum.SurfaceType.Smooth
    handItem.BottomSurface = Enum.SurfaceType.Smooth
    
    -- Add special effects for rare crops
    if selectedItem.type == "crop" and selectedItem.name:find("Shiny") then
        handItem.Material = Enum.Material.ForceField
        
        -- Add sparkle effect
        local attachment = Instance.new("Attachment")
        attachment.Parent = handItem
        
        local particles = Instance.new("ParticleEmitter")
        particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        particles.Lifetime = NumberRange.new(0.3, 0.8)
        particles.Rate = 10
        particles.SpreadAngle = Vector2.new(45, 45)
        particles.Speed = NumberRange.new(1, 2)
        particles.Color = ColorSequence.new(Color3.fromRGB(255, 255, 150))
        particles.Size = NumberSequence.new(0.1)
        particles.Parent = attachment
    elseif selectedItem.type == "crop" and selectedItem.name:find("Rainbow") then
        handItem.Material = Enum.Material.ForceField
        
        -- Rainbow color cycling
        spawn(function()
            while handItem.Parent do
                for hue = 0, 1, 0.02 do
                    if not handItem.Parent then break end
                    handItem.Color = Color3.fromHSV(hue, 1, 1)
                    wait(0.1)
                end
            end
        end)
    end
    
    -- Weld to hand
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = rightArm
    weld.Part1 = handItem
    weld.Parent = handItem
    
    -- Position in hand
    handItem.CFrame = rightArm.CFrame * CFrame.new(0, -1, -0.5)
    handItem.Parent = rightArm
    
    -- Add gentle floating animation
    spawn(function()
        local startTime = tick()
        local connection
        connection = RunService.Heartbeat:Connect(function()
            if not handItem.Parent then
                connection:Disconnect()
                return
            end
            
            local elapsed = tick() - startTime
            local offset = math.sin(elapsed * 3) * 0.1
            handItem.CFrame = rightArm.CFrame * CFrame.new(0, -1 + offset, -0.5)
        end)
    end)
end

-- Remove hand item
function HandItem.removeHandItem(player)
    if not player or not player.Character then return end
    
    local character = player.Character
    local rightArm = character:FindFirstChild("Right Arm") or character:FindFirstChild("RightHand")
    
    if not rightArm then return end
    
    local existingItem = rightArm:FindFirstChild("HandItem")
    if existingItem then
        existingItem:Destroy()
    end
end

-- React hook for managing hand item
function HandItem.useHandItem(selectedItem, visible)
    local player = Players.LocalPlayer
    
    React.useEffect(function()
        if visible and selectedItem then
            HandItem.updateHandItem(player, selectedItem)
        else
            HandItem.removeHandItem(player)
        end
        
        -- Cleanup on unmount
        return function()
            HandItem.removeHandItem(player)
        end
    end, {selectedItem, visible})
end

return HandItem