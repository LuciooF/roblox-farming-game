-- Gamepass Management Module
-- Handles all gamepass/premium functionality and automation features

local GameConfig = require(script.Parent.GameConfig)

local GamepassManager = {}

-- Storage for testing gamepasses
local testingGamepasses = {} -- [userId] = {autoPlant, autoWater, autoHarvest, autoSell}

-- Check if player has specific gamepass
function GamepassManager.hasGamepass(player, gamepassType)
    local userId = tostring(player.UserId)
    local playerPasses = testingGamepasses[userId] or {}
    return playerPasses[gamepassType] or false
end

-- Toggle specific gamepass for testing
function GamepassManager.toggleGamepass(player, gamepassType)
    local userId = tostring(player.UserId)
    if not testingGamepasses[userId] then
        testingGamepasses[userId] = {}
    end
    
    testingGamepasses[userId][gamepassType] = not (testingGamepasses[userId][gamepassType] or false)
    
    local status = testingGamepasses[userId][gamepassType] and "enabled" or "disabled"
    local passName = GameConfig.Gamepasses[gamepassType].name
    
    return testingGamepasses[userId][gamepassType], passName .. " " .. status .. " for testing!"
end

-- Get all gamepass statuses for player
function GamepassManager.getGamepassStatuses(player)
    local userId = tostring(player.UserId)
    return testingGamepasses[userId] or {}
end

-- Show automation menu to player
function GamepassManager.getAutomationMenuText(player)
    local statuses = GamepassManager.getGamepassStatuses(player)
    
    local message = "AUTOMATION MENU:\n"
    for passType, config in pairs(GameConfig.Gamepasses) do
        local status = statuses[passType] and "ON" or "OFF"
        message = message .. "\n" .. config.name .. ": " .. status
    end
    message = message .. "\n\nUse Premium Panel to toggle!"
    
    return message
end

-- Validate gamepass for automation action
function GamepassManager.validateAutomation(player, actionType)
    local gamepassMap = {
        plant = "autoPlant",
        water = "autoWater", 
        harvest = "autoHarvest",
        sell = "autoSell"
    }
    
    local requiredPass = gamepassMap[actionType]
    if not requiredPass then
        return false, "Invalid automation type"
    end
    
    if not GamepassManager.hasGamepass(player, requiredPass) then
        local passName = GameConfig.Gamepasses[requiredPass].name
        return false, passName .. " gamepass required!"
    end
    
    return true, "Automation authorized"
end

return GamepassManager