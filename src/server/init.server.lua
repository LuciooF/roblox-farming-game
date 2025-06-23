-- Main server initialization script - 3D Farming Game (Modular)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Initialize logging first
local Logger = require(script.modules.Logger)
Logger.initialize()
local log = Logger.getModuleLogger("ServerMain")

log.info("3D Farming Game Server Starting (New Modular System)...")

-- Load new modular farming system
local FarmingSystem = require(script:WaitForChild("FarmingSystemNew"))

-- Initialize modular farming system
FarmingSystem.initialize()

-- Handle player connections
Players.PlayerAdded:Connect(function(player)
    -- Player join logging is handled by RemoteManager
    FarmingSystem.onPlayerJoined(player)
end)

Players.PlayerRemoving:Connect(function(player)
    -- Player leave logging is handled by RemoteManager
    FarmingSystem.onPlayerLeft(player)
end)

log.info("3D Farming Game Server Ready (Modular)!")