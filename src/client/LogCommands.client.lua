-- Client-side log commands for development
-- Provides fallback chat commands and debug access

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Initialize client-side logging
local ClientLogger = require(script.Parent.ClientLogger)
local log = ClientLogger.getModuleLogger("LogCommands")

local player = Players.LocalPlayer

-- Wait for log command remote
local farmingRemotes = ReplicatedStorage:WaitForChild("FarmingRemotes")
local logCommandRemote = farmingRemotes:WaitForChild("LogCommand")

-- Chat command handler (fallback for when UI isn't available)
local function onChatted(message)
    local lowercaseMessage = message:lower()
    
    if lowercaseMessage:sub(1, 9) == "/loglevel" then
        local level = message:sub(11):upper()
        if level == "" then
            logCommandRemote:FireServer("getlevel")
        else
            logCommandRemote:FireServer("setlevel", level)
        end
    elseif lowercaseMessage == "/logtest" then
        logCommandRemote:FireServer("test")
    end
end

-- Only enable chat commands in Studio
if game:GetService("RunService"):IsStudio() then
    if player.Character then
        player.Chatted:Connect(onChatted)
    else
        player.CharacterAdded:Connect(function()
            player.Chatted:Connect(onChatted)
        end)
    end
end