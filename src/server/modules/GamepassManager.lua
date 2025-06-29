-- Gamepass Management Module (DEPRECATED)
-- This module was used for testing automation features that are no longer available
-- Real gamepass functionality is now handled by GamepassService.lua

local GamepassManager = {}

-- Legacy testing storage (kept for backward compatibility)
local testingGamepasses = {} -- [userId] = deprecated automation gamepasses

-- DEPRECATED: Check if player has specific gamepass 
-- This functionality has been moved to GamepassService
function GamepassManager.hasGamepass(player, gamepassType)
    -- All automation gamepasses have been removed
    -- Return false for any automation gamepass checks
    return false
end

-- DEPRECATED: Toggle specific gamepass for testing
function GamepassManager.toggleGamepass(player, gamepassType)
    -- Automation gamepasses no longer exist
    return false, "Automation gamepasses are no longer available"
end

-- DEPRECATED: Get all gamepass statuses for player
function GamepassManager.getGamepassStatuses(player)
    -- Return empty table since automation gamepasses are removed
    return {}
end

-- DEPRECATED: Show automation menu to player
function GamepassManager.getAutomationMenuText(player)
    return "AUTOMATION MENU:\n\nNo automation gamepasses available.\n\nReal gamepasses: 2x Money Boost & Fly Mode\nAvailable in the Gamepass Panel!"
end

-- DEPRECATED: Validate gamepass for automation action
function GamepassManager.validateAutomation(player, actionType)
    -- All automation features have been removed
    return false, "Automation features are no longer available"
end

return GamepassManager