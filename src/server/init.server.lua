-- Main server initialization script
print("Farming Game Server Starting...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Load shared modules
local Shared = ReplicatedStorage:WaitForChild("Shared")

-- Server modules will be added here
local FarmingSystem = require(script:WaitForChild("FarmingSystem"))
local PlayerDataManager = require(script:WaitForChild("PlayerDataManager"))

-- Initialize farming system
FarmingSystem.initialize()

-- Handle player connections
Players.PlayerAdded:Connect(function(player)
    print("Player joined:", player.Name)
    PlayerDataManager.loadPlayerData(player)
end)

Players.PlayerRemoving:Connect(function(player)
    print("Player leaving:", player.Name)
    PlayerDataManager.savePlayerData(player)
end)

print("Farming Game Server Ready!")