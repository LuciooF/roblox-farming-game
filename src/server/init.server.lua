-- Main server initialization script - 3D Farming Game (Modular)
print("🌱 3D Farming Game Server Starting (New Modular System)...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Load new modular farming system
local FarmingSystem = require(script:WaitForChild("FarmingSystemNew"))

-- Initialize modular farming system
FarmingSystem.initialize()

-- Handle player connections
Players.PlayerAdded:Connect(function(player)
    print("Player joined the farm:", player.Name)
    FarmingSystem.onPlayerJoined(player)
end)

Players.PlayerRemoving:Connect(function(player)
    print("Player left the farm:", player.Name)
    FarmingSystem.onPlayerLeft(player)
end)

print("🌱 3D Farming Game Server Ready (Modular)!")