-- Character Face Tracker
-- Makes all farm character displays always face the local player

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local ClientLogger = require(script.Parent.ClientLogger)
local log = ClientLogger.getModuleLogger("CharacterFaceTracker")

local CharacterFaceTracker = {}

-- Configuration
local UPDATE_FREQUENCY = 0.1 -- Update every 0.1 seconds (10 FPS)
local lastUpdateTime = 0

-- State
local trackingConnection = nil
local player = Players.LocalPlayer

-- Initialize the face tracking system
function CharacterFaceTracker.initialize()
    
    -- Set up server communication
    CharacterFaceTracker.setupServerCommunication()
    
    -- Start the tracking loop
    CharacterFaceTracker.startTracking()
end

-- Set up communication with server for character updates
function CharacterFaceTracker.setupServerCommunication()
    -- Wait for the CharacterTracking remote
    local farmingRemotes = game:GetService("ReplicatedStorage"):WaitForChild("FarmingRemotes")
    local characterTrackingRemote = farmingRemotes:WaitForChild("CharacterTracking")
    
    -- Listen for character creation events from server
    characterTrackingRemote.OnClientEvent:Connect(function(eventType, data)
        if eventType == "characterCreated" then
            -- Client tracking will automatically pick up the new character
        end
    end)
    
    log.debug("Set up server communication for character tracking")
end

-- Start tracking character displays
function CharacterFaceTracker.startTracking()
    if trackingConnection then
        return -- Already running
    end
    
    trackingConnection = RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        if currentTime - lastUpdateTime >= UPDATE_FREQUENCY then
            CharacterFaceTracker.updateCharacterFacing()
            lastUpdateTime = currentTime
        end
    end)
    
    log.debug("Character face tracking started")
end

-- Stop tracking character displays
function CharacterFaceTracker.stopTracking()
    if trackingConnection then
        trackingConnection:Disconnect()
        trackingConnection = nil
    end
    
    log.debug("Character face tracking stopped")
end

-- Update all character displays to face the player
function CharacterFaceTracker.updateCharacterFacing()
    local playerCharacter = player.Character
    if not playerCharacter then return end
    
    local playerPosition = playerCharacter:FindFirstChild("HumanoidRootPart")
    if not playerPosition then return end
    
    local cameraPosition = playerPosition.Position
    
    -- Find all farm character displays
    local farmsContainer = Workspace:FindFirstChild("PlayerFarms")
    if not farmsContainer then return end
    
    -- Go through all farms and update character facing
    for _, farmFolder in pairs(farmsContainer:GetChildren()) do
        if farmFolder.Name:match("^Farm_") then
            local characterDisplay = farmFolder:FindFirstChild("CharacterDisplay")
            if characterDisplay then
                local playerDisplayModel = characterDisplay:FindFirstChild("PlayerDisplay")
                if playerDisplayModel then
                    CharacterFaceTracker.faceCharacterToward(playerDisplayModel, cameraPosition)
                end
            end
        end
    end
end

-- Make a specific character model face toward a position
function CharacterFaceTracker.faceCharacterToward(characterModel, targetPosition)
    local humanoidRootPart = characterModel:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local characterPosition = humanoidRootPart.Position
    local direction = (targetPosition - characterPosition)
    direction = Vector3.new(direction.X, 0, direction.Z).Unit -- Keep Y at 0 for upright character
    
    -- Calculate the rotation to face the target
    local newLookDirection = CFrame.lookAt(characterPosition, characterPosition + direction)
    local currentCFrame = humanoidRootPart.CFrame
    
    -- Create target rotation (preserve position, update rotation)
    local targetCFrame = CFrame.new(currentCFrame.Position) * newLookDirection.Rotation
    
    -- Smooth the rotation for better visual effect
    local smoothedCFrame = currentCFrame:Lerp(targetCFrame, 0.15)
    
    -- Store original relative transforms for ALL parts including accessories BEFORE moving root
    local relativeTransforms = {}
    local accessories = {}
    
    -- Collect body parts
    for _, part in pairs(characterModel:GetChildren()) do
        if part:IsA("BasePart") and part ~= humanoidRootPart then
            relativeTransforms[part] = currentCFrame:ToObjectSpace(part.CFrame)
        elseif part:IsA("Accessory") then
            table.insert(accessories, part)
        end
    end
    
    -- Update root part
    humanoidRootPart.CFrame = smoothedCFrame
    
    -- Apply the rotation to all body parts to keep them in sync
    for _, part in pairs(characterModel:GetChildren()) do
        if part:IsA("BasePart") and part ~= humanoidRootPart and relativeTransforms[part] then
            -- Apply the relative transform to the new root position
            part.CFrame = smoothedCFrame * relativeTransforms[part]
        end
    end
    
    -- Handle accessories separately to maintain attachment relationships
    for _, accessory in pairs(accessories) do
        local handle = accessory:FindFirstChild("Handle")
        if handle then
            -- Find the attachment on the accessory
            local accessoryAttachment = handle:FindFirstChildOfClass("Attachment")
            if accessoryAttachment then
                -- Find the corresponding attachment on the character
                local attachmentName = accessoryAttachment.Name
                for _, part in pairs(characterModel:GetChildren()) do
                    if part:IsA("BasePart") then
                        local characterAttachment = part:FindFirstChild(attachmentName)
                        if characterAttachment then
                            -- Position accessory relative to character attachment
                            local attachmentCFrame = part.CFrame * characterAttachment.CFrame
                            local accessoryOffset = accessoryAttachment.CFrame:Inverse()
                            handle.CFrame = attachmentCFrame * accessoryOffset
                            break
                        end
                    end
                end
            end
        end
    end
end

-- Rotate all character parts to maintain proper orientation
function CharacterFaceTracker.rotateCharacterParts(characterModel, rotationCFrame)
    local humanoidRootPart = characterModel:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local rootPosition = humanoidRootPart.Position
    
    -- Rotate all body parts around the root part
    for _, part in pairs(characterModel:GetChildren()) do
        if part:IsA("BasePart") and part ~= humanoidRootPart then
            -- Calculate the relative position from root
            local relativePosition = part.Position - rootPosition
            -- Rotate the relative position
            local rotatedPosition = rotationCFrame * relativePosition
            -- Set the new position
            part.Position = rootPosition + rotatedPosition
            -- Also rotate the part itself
            part.CFrame = CFrame.new(part.Position) * rotationCFrame
        end
    end
end

-- Cleanup when leaving
function CharacterFaceTracker.cleanup()
    CharacterFaceTracker.stopTracking()
end

return CharacterFaceTracker