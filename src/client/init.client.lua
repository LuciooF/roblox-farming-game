-- Main client initialization script
print("Farming Game Client Starting...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Wait for packages
local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages.React)
local ReactRoblox = require(Packages.ReactRoblox)
local Rodux = require(Packages.Rodux)

-- Load shared modules
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Components = ReplicatedStorage:WaitForChild("Components")

-- Initialize store
local gameReducer = require(Shared:WaitForChild("GameReducer"))
local store = Rodux.Store.new(gameReducer)

-- Initialize UI
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local root = ReactRoblox.createRoot(PlayerGui)

local App = require(Components:WaitForChild("App"))
root:render(React.createElement(App, { store = store }))

print("Farming Game Client Ready!")