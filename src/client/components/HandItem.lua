-- Hand Item Component
-- Creates a visual representation of the selected item in the player's hand

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
-- Import unified crop system - REQUIRED for the refactored system
local CropRegistry = require(game:GetService("ReplicatedStorage").Shared.CropRegistry)
-- Try to import ClientLogger, fallback if not available
local ClientLogger
local hasClientLogger = pcall(function()
    ClientLogger = require(script.Parent.Parent.ClientLogger)
end)

if not hasClientLogger then
    ClientLogger = {
        getModuleLogger = function(name)
            return {
                info = function(...) print("[INFO]", name, ...) end,
                debug = function(...) print("[DEBUG]", name, ...) end,
                warn = function(...) warn("[WARN]", name, ...) end,
                error = function(...) error("[ERROR] " .. name .. ": " .. table.concat({...}, " ")) end
            }
        end
    }
end

local log = ClientLogger.getModuleLogger("HandItem")

local HandItem = {}

-- Get item color based on type and name using CropRegistry
local function getItemColor(item)
    if not item then return Color3.fromRGB(100, 100, 100) end
    
    local key = item.name
    -- Remove variation prefixes for crops
    if item.type == "crop" then
        key = item.name:gsub("Shiny ", ""):gsub("Rainbow ", ""):gsub("Golden ", ""):gsub("Diamond ", "")
    end
    
    local cropData = CropRegistry.getCrop(key)
    if cropData then
        return cropData.color
    end
    
    return Color3.fromRGB(100, 200, 100) -- Default for non-crops
end

-- Create 3D model for specific items
local function create3DModel(item)
    if not item then return nil end
    
    local key = item.name
    -- Remove variation prefixes for crops
    if item.type == "crop" then
        key = item.name:gsub("Shiny ", ""):gsub("Rainbow ", ""):gsub("Golden ", ""):gsub("Diamond ", "")
    end
    
    local modelId
    
    local cropData = CropRegistry.getCrop(key)
    if cropData and cropData.meshId then
        modelId = cropData.meshId
    end
    
    if not modelId then return nil end
    
    -- Create part with mesh (avoiding MeshPart due to security restrictions)
    local part = Instance.new("Part")
    part.Name = "HandItem"
    part.Size = Vector3.new(0.8, 0.8, 0.8) -- Base size for hand item
    part.Material = Enum.Material.Plastic
    part.Transparency = 1 -- Make base part invisible
    part.CanCollide = false
    part.Anchored = false
    
    -- Create the mesh
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = "rbxassetid://" .. modelId
    mesh.Scale = Vector3.new(0.4, 0.4, 0.4) -- Scale for hand item
    mesh.Parent = part
    
    log.debug("Created hand item 3D model for", key, "with mesh ID", modelId)
    return part
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
    
    -- Try to create 3D model first, fall back to colored sphere
    local handItem = create3DModel(selectedItem)
    
    if not handItem then
        -- Create default colored sphere
        handItem = Instance.new("Part")
        handItem.Name = "HandItem"
        handItem.Size = Vector3.new(0.8, 0.8, 0.8) -- Small sphere
        handItem.Shape = Enum.PartType.Ball
        handItem.Material = Enum.Material.Neon
        handItem.Color = getItemColor(selectedItem)
        handItem.Anchored = false
        handItem.CanCollide = false
        handItem.TopSurface = Enum.SurfaceType.Smooth
        handItem.BottomSurface = Enum.SurfaceType.Smooth
    end
    
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
    
    -- Simple weld to hand without animation (no physics interference)
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = rightArm
    weld.Part1 = handItem
    weld.Parent = handItem
    
    -- Position in hand (static, no animation)
    handItem.CFrame = rightArm.CFrame * CFrame.new(0, -1, -0.5)
    handItem.Parent = rightArm
end

-- Remove hand item
function HandItem.removeHandItem(player)
    if not player or not player.Character then return end
    
    local character = player.Character
    local rightArm = character:FindFirstChild("Right Arm") or character:FindFirstChild("RightHand")
    
    if not rightArm then return end
    
    -- Remove hand item
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