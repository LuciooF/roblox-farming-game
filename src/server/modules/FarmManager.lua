-- Farm Manager
-- Handles individual player farm assignment and management
-- Each player gets their own farm area with multiple plots and potential expansions

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Logger = require(script.Parent.Logger)
local log = Logger.getModuleLogger("FarmManager")

local FarmManager = {}

-- Configuration
local TOTAL_FARMS = 6 -- Maximum number of farms available
local PLOTS_PER_FARM = 9 -- Each farm starts with 9 plots (3x3 grid)
local FARM_SIZE = Vector3.new(100, 1, 100) -- Size of each farm area
local FARM_SPACING = 120 -- Space between farm centers

-- Storage
local farmAssignments = {} -- [farmId] = {userId, playerName, joinTime}
local playerFarms = {} -- [userId] = farmId
local farmPositions = {} -- [farmId] = Vector3 position

-- Initialize the farm management system
function FarmManager.initialize()
    log.info("Initializing farm management system with", TOTAL_FARMS, "farms")
    
    -- Calculate farm positions in a circle around spawn
    FarmManager.calculateFarmPositions()
    
    -- Initialize empty farm assignments
    for i = 1, TOTAL_FARMS do
        farmAssignments[i] = nil
    end
    
    -- Player events are now handled by FarmingSystemNew to avoid duplicate connections
    -- FarmingSystemNew will call FarmManager.onPlayerJoined and onPlayerLeaving
    
    log.info("Farm management system ready!")
end

-- Calculate positions for all farms in a circle around spawn
function FarmManager.calculateFarmPositions()
    local spawnPosition = Vector3.new(0, 0, 0) -- Center spawn
    local radius = FARM_SPACING * 2 -- Distance from spawn to farms
    
    for i = 1, TOTAL_FARMS do
        local angle = (i - 1) * (2 * math.pi / TOTAL_FARMS) -- Evenly distributed around circle
        local x = spawnPosition.X + radius * math.cos(angle)
        local z = spawnPosition.Z + radius * math.sin(angle)
        local y = spawnPosition.Y
        
        farmPositions[i] = Vector3.new(x, y, z)
        log.debug("Farm", i, "positioned at", farmPositions[i])
    end
end

-- Handle player joining - assign them a farm
function FarmManager.onPlayerJoined(player)
    local farmId = FarmManager.assignFarmToPlayer(player)
    if farmId then
        log.info("Assigned farm", farmId, "to player", player.Name, "(", player.UserId, ")")
        
        -- Enable the spawn location for this farm
        FarmManager.setPlayerSpawn(player, farmId)
        
        -- If player already has a character (studio testing), respawn them
        if player.Character then
            player:LoadCharacter()
        end
    else
        log.warn("No available farms for player", player.Name, "- server is full")
        -- Could implement a queue system or spectator mode here
    end
end

-- Handle player leaving - free up their farm
function FarmManager.onPlayerLeaving(player)
    local farmId = playerFarms[player.UserId]
    if farmId then
        -- Disable the spawn location for this farm
        FarmManager.disableSpawn(farmId)
        
        FarmManager.unassignFarmFromPlayer(player.UserId)
        log.info("Freed farm", farmId, "from player", player.Name, "(", player.UserId, ")")
    end
end

-- Assign an available farm to a player
function FarmManager.assignFarmToPlayer(player)
    local userId = player.UserId
    
    -- Check if player already has a farm
    if playerFarms[userId] then
        log.warn("Player", player.Name, "already has farm", playerFarms[userId])
        return playerFarms[userId]
    end
    
    -- Find first available farm
    for farmId = 1, TOTAL_FARMS do
        if not farmAssignments[farmId] then
            -- Assign farm to player
            farmAssignments[farmId] = {
                userId = userId,
                playerName = player.Name,
                joinTime = tick()
            }
            playerFarms[userId] = farmId
            
            -- Notify other systems about the assignment
            FarmManager.onFarmAssigned(farmId, player)
            
            return farmId
        end
    end
    
    return nil -- No available farms
end

-- Unassign a farm from a player
function FarmManager.unassignFarmFromPlayer(userId)
    local farmId = playerFarms[userId]
    if not farmId then
        return false
    end
    
    -- Clear assignment
    farmAssignments[farmId] = nil
    playerFarms[userId] = nil
    
    -- Notify other systems about the unassignment
    FarmManager.onFarmUnassigned(farmId, userId)
    
    return true
end

-- Called when a farm is assigned to a player
function FarmManager.onFarmAssigned(farmId, player)
    -- Update farm sign with character display
    local WorldBuilder = require(script.Parent.Parent.WorldBuilder)
    WorldBuilder.updateFarmSign(farmId, player.Name, player)
    
    -- Initialize farm plots in PlotManager
    local PlotManager = require(script.Parent.PlotManager)
    for plotIndex = 1, PLOTS_PER_FARM do
        local globalPlotId = FarmManager.getGlobalPlotId(farmId, plotIndex)
        PlotManager.initializePlot(globalPlotId, player.UserId)
    end
    
    -- Store assignment in player data
    local PlayerDataManager = require(script.Parent.PlayerDataManager)
    PlayerDataManager.setAssignedFarm(player, farmId)
    
    log.debug("Farm", farmId, "assigned to", player.Name)
end

-- Called when a farm is unassigned from a player
function FarmManager.onFarmUnassigned(farmId, userId)
    -- Clear farm sign and character display
    local WorldBuilder = require(script.Parent.Parent.WorldBuilder)
    WorldBuilder.updateFarmSign(farmId, nil, nil)
    
    -- Reset all farm plots in PlotManager
    local PlotManager = require(script.Parent.PlotManager)
    for plotIndex = 1, PLOTS_PER_FARM do
        local globalPlotId = FarmManager.getGlobalPlotId(farmId, plotIndex)
        PlotManager.resetPlot(globalPlotId)
    end
    
    -- Clear assignment from player data (if player still online)
    local Players = game:GetService("Players")
    local player = Players:GetPlayerByUserId(userId)
    if player then
        local PlayerDataManager = require(script.Parent.PlayerDataManager)
        PlayerDataManager.setAssignedFarm(player, nil)
    end
    
    log.debug("Farm", farmId, "unassigned from user", userId)
end

-- Convert farm and plot index to global plot ID
function FarmManager.getGlobalPlotId(farmId, plotIndex)
    return (farmId - 1) * PLOTS_PER_FARM + plotIndex
end

-- Convert global plot ID back to farm and plot index
function FarmManager.getFarmAndPlotFromGlobalId(globalPlotId)
    local farmId = math.floor((globalPlotId - 1) / PLOTS_PER_FARM) + 1
    local plotIndex = ((globalPlotId - 1) % PLOTS_PER_FARM) + 1
    return farmId, plotIndex
end

-- Get the player who owns a specific farm
function FarmManager.getFarmOwner(farmId)
    local assignment = farmAssignments[farmId]
    if assignment then
        return assignment.userId, assignment.playerName
    end
    return nil, nil
end

-- Get the farm assigned to a specific player
function FarmManager.getPlayerFarm(userId)
    return playerFarms[userId]
end

-- Check if a player owns a specific farm
function FarmManager.doesPlayerOwnFarm(userId, farmId)
    return playerFarms[userId] == farmId
end

-- Check if a plot belongs to a player (via farm ownership)
function FarmManager.doesPlayerOwnPlot(userId, globalPlotId)
    local farmId, plotIndex = FarmManager.getFarmAndPlotFromGlobalId(globalPlotId)
    return FarmManager.doesPlayerOwnFarm(userId, farmId)
end

-- Get farm position
function FarmManager.getFarmPosition(farmId)
    return farmPositions[farmId]
end

-- Set player's spawn location to their farm
function FarmManager.setPlayerSpawn(player, farmId)
    -- Find the farm's spawn location
    local farmFolder = workspace.PlayerFarms:FindFirstChild("Farm_" .. farmId)
    if not farmFolder then
        log.warn("Cannot set spawn - farm folder not found for farm", farmId)
        return false
    end
    
    local spawnLocation = farmFolder:FindFirstChild("FarmSpawn_" .. farmId)
    if not spawnLocation then
        log.warn("Cannot set spawn - spawn location not found for farm", farmId)
        return false
    end
    
    -- Enable this spawn location
    spawnLocation.Enabled = true
    
    -- Set player's RespawnLocation
    player.RespawnLocation = spawnLocation
    
    log.debug("Set spawn location for", player.Name, "to farm", farmId)
    return true
end

-- Disable spawn location when player leaves
function FarmManager.disableSpawn(farmId)
    local farmFolder = workspace.PlayerFarms:FindFirstChild("Farm_" .. farmId)
    if farmFolder then
        local spawnLocation = farmFolder:FindFirstChild("FarmSpawn_" .. farmId)
        if spawnLocation then
            spawnLocation.Enabled = false
            log.debug("Disabled spawn location for farm", farmId)
        end
    end
end

-- Teleport player to another player's farm (for visiting)
function FarmManager.teleportPlayerToOtherFarm(visitor, targetUserId)
    local targetFarmId = playerFarms[targetUserId]
    if not targetFarmId then
        return false, "Player doesn't have a farm"
    end
    
    if not visitor.Character or not visitor.Character:FindFirstChild("HumanoidRootPart") then
        return false, "No character to teleport"
    end
    
    -- Find target farm's spawn location
    local farmFolder = workspace.PlayerFarms:FindFirstChild("Farm_" .. targetFarmId)
    if not farmFolder then
        return false, "Target farm not found"
    end
    
    local spawnLocation = farmFolder:FindFirstChild("FarmSpawn_" .. targetFarmId)
    if not spawnLocation then
        return false, "Target farm spawn not found"
    end
    
    -- Teleport to the spawn location
    visitor.Character.HumanoidRootPart.CFrame = CFrame.new(spawnLocation.Position + Vector3.new(0, 3, 0))
    
    local targetPlayer = Players:GetPlayerByUserId(targetUserId)
    local targetName = targetPlayer and targetPlayer.Name or "Unknown Player"
    log.info(visitor.Name, "visited", targetName .. "'s farm (Farm " .. targetFarmId .. ")")
    
    return true, "Teleported to " .. targetName .. "'s farm"
end

-- Get all current farm assignments (for debugging/admin)
function FarmManager.getAllAssignments()
    local assignments = {}
    for farmId = 1, TOTAL_FARMS do
        local assignment = farmAssignments[farmId]
        if assignment then
            assignments[farmId] = {
                userId = assignment.userId,
                playerName = assignment.playerName,
                joinTime = assignment.joinTime,
                position = farmPositions[farmId]
            }
        else
            assignments[farmId] = nil
        end
    end
    return assignments
end

-- Get number of available farms
function FarmManager.getAvailableFarmCount()
    local count = 0
    for farmId = 1, TOTAL_FARMS do
        if not farmAssignments[farmId] then
            count = count + 1
        end
    end
    return count
end

-- Get number of occupied farms
function FarmManager.getOccupiedFarmCount()
    return TOTAL_FARMS - FarmManager.getAvailableFarmCount()
end

-- Debug function to print current assignments
function FarmManager.printAssignments()
    log.info("Current farm assignments:")
    for farmId = 1, TOTAL_FARMS do
        local assignment = farmAssignments[farmId]
        if assignment then
            local pos = farmPositions[farmId]
            log.info("Farm", farmId, "->", assignment.playerName, "(", assignment.userId, ") at", pos)
        else
            log.info("Farm", farmId, "-> AVAILABLE at", farmPositions[farmId])
        end
    end
end

-- Get farm configuration info
function FarmManager.getFarmConfig()
    return {
        totalFarms = TOTAL_FARMS,
        plotsPerFarm = PLOTS_PER_FARM,
        farmSize = FARM_SIZE,
        farmSpacing = FARM_SPACING
    }
end

return FarmManager