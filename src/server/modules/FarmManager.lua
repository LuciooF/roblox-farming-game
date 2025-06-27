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
local BASE_PLOTS_PER_FARM = 9 -- Each farm starts with 9 plots (3x3 grid)  
local MAX_PLOTS_PER_FARM = 40 -- Maximum plots per farm (from template)
local FARM_SIZE = Vector3.new(200, 1, 200) -- Increased size for template farms
local FARM_SPACING = 300 -- Increased spacing for larger template farms

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
    local radius = FARM_SPACING * 1.2 -- Reduced distance from spawn to farms (was *2)
    
    log.info("Calculating positions for", TOTAL_FARMS, "farms at radius", radius, "from center")
    
    for i = 1, TOTAL_FARMS do
        local angle = (i - 1) * (2 * math.pi / TOTAL_FARMS) -- Evenly distributed around circle
        local x = spawnPosition.X + radius * math.cos(angle)
        local z = spawnPosition.Z + radius * math.sin(angle)
        local y = spawnPosition.Y
        
        farmPositions[i] = Vector3.new(x, y, z)
        log.info("Farm", i, "positioned at", farmPositions[i]) -- Changed to info to see in logs
    end
end

-- Handle player joining - assign them a farm
function FarmManager.onPlayerJoined(player)
    local farmId = FarmManager.assignFarmToPlayer(player)
    if farmId then
        log.info("Assigned farm", farmId, "to player", player.Name, "(", player.UserId, ")")
        
        -- Enable the spawn location for this farm
        FarmManager.setPlayerSpawn(player, farmId)
        
        -- Don't respawn here - let FarmingSystemNew handle spawning
        -- if player.Character then
        --     player:LoadCharacter()
        -- end
    else
        log.warn("No available farms for player", player.Name, "- server is full")
        -- Could implement a queue system or spectator mode here
    end
    
    return farmId
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
    local totalStart = tick()
    log.error("🔄 onFarmAssigned STARTED for:", player.Name, "farm:", farmId)
    
    -- Update farm sign with character display (make async to avoid blocking)
    local signStart = tick()
    local WorldBuilder = require(script.Parent.Parent.WorldBuilder)
    
    -- Do farm sign update asynchronously so it doesn't block player loading
    spawn(function()
        log.error("🔄 Starting async farm sign update for:", player.Name)
        WorldBuilder.updateFarmSign(farmId, player.Name, player)
        log.error("🔄 Async farm sign update completed for:", player.Name, "in", (tick() - signStart), "seconds")
    end)
    log.error("🔄 Farm sign update started asynchronously")
    
    -- Initialize all plots in PlotManager
    local PlotManager = require(script.Parent.PlotManager)
    local PlayerDataManager = require(script.Parent.PlayerDataManager)
    
    -- Initialize owned plots with saved data
    local plotInitStart = tick()
    log.error("🔄 Starting plot initialization loop for", MAX_PLOTS_PER_FARM, "plots")
    for plotIndex = 1, MAX_PLOTS_PER_FARM do
        local globalPlotId = FarmManager.getGlobalPlotId(farmId, plotIndex)
        
        if PlayerDataManager.isPlotOwned(player, plotIndex) then
            -- This plot is owned - initialize with player data
            PlotManager.initializePlot(globalPlotId, player.UserId, player)
            
            -- Update the visual state of the plot to match the loaded data
            local plotState = PlotManager.getPlotState(globalPlotId)
            if plotState then
                log.info("Restoring owned plot", plotIndex, "for", player.Name, "- state:", plotState.state, "seed:", plotState.seedType)
                
                local plot = WorldBuilder.getPlotById(globalPlotId)
                if plot then
                    WorldBuilder.updatePlotState(plot, plotState.state, plotState.seedType, plotState.variation)
                end
                
                -- Send plot data to client
                local RemoteManager = require(script.Parent.RemoteManager)
                RemoteManager.sendPlotUpdate(globalPlotId, plotState)
            end
        else
            -- This plot is unowned - initialize as locked
            PlotManager.initializePlot(globalPlotId, nil, nil)
        end
    end
    log.error("🔄 Plot initialization loop completed in:", (tick() - plotInitStart), "seconds")
    
    -- Update visual states for all plots based on ownership
    local visualStart = tick()
    local playerData = PlayerDataManager.getPlayerData(player)
    local rebirths = playerData and playerData.rebirths or 0
    log.error("🔄 Starting visual state updates for", MAX_PLOTS_PER_FARM, "plots")
    
    for plotIndex = 1, MAX_PLOTS_PER_FARM do
        local globalPlotId = FarmManager.getGlobalPlotId(farmId, plotIndex)
        local plot = WorldBuilder.getPlotById(globalPlotId)
        if plot then
            local visibilityState, requiredRebirth = PlayerDataManager.getPlotVisibilityState(player, plotIndex)
            
            if visibilityState == "unlocked" then
                -- Owned plot - already handled above
                log.debug("Plot", plotIndex, "is owned by", player.Name)
            elseif visibilityState == "locked" then
                -- Plot is available for purchase (red with price)
                WorldBuilder.updatePlotState(plot, "locked", "", nil, nil, nil, plotIndex)
                log.info("Plot", plotIndex, "set to PURCHASABLE for", player.Name)
            elseif visibilityState == "next_tier" then
                -- Visible but shows rebirth requirement (gray, no price)
                WorldBuilder.updatePlotState(plot, "rebirth_locked", "", nil, nil, nil, plotIndex, requiredRebirth)
                log.info("Plot", plotIndex, "set to NEXT-TIER (rebirth", requiredRebirth, "required) for", player.Name)
            else -- invisible
                -- Completely hidden for future rebirth tiers
                WorldBuilder.updatePlotState(plot, "invisible", "")
                log.info("Plot", plotIndex, "set to INVISIBLE for", player.Name)
            end
        else
            log.warn("Plot", plotIndex, "not found in world for", player.Name)
        end
    end
    
    -- Store assignment in player data
    local PlayerDataManager = require(script.Parent.PlayerDataManager)
    PlayerDataManager.setAssignedFarm(player, farmId)
    
    log.error("🔄 Visual state updates completed in:", (tick() - visualStart), "seconds")
    log.error("🔄 onFarmAssigned TOTAL TIME:", (tick() - totalStart), "seconds for", player.Name)
    
    -- Notify player about online boost
    local NotificationManager = require(script.Parent.NotificationManager)
    NotificationManager.sendSuccess(player, "⚡ Online Boost Active! Crops grow 2x faster while you're here!")
end

-- Called when a farm is unassigned from a player
function FarmManager.onFarmUnassigned(farmId, userId)
    -- Clear farm sign and character display
    local WorldBuilder = require(script.Parent.Parent.WorldBuilder)
    WorldBuilder.updateFarmSign(farmId, nil, nil)
    
    -- Reset plot visuals to empty state but keep plot states in PlotManager memory
    -- (plot states are preserved in player data and will be restored when they rejoin)
    local WorldBuilder = require(script.Parent.Parent.WorldBuilder)
    for plotIndex = 1, MAX_PLOTS_PER_FARM do
        local globalPlotId = FarmManager.getGlobalPlotId(farmId, plotIndex)
        local plot = WorldBuilder.getPlotById(globalPlotId)
        if plot then
            -- Only reset the visual appearance, not the plot state data
            WorldBuilder.updatePlotState(plot, "empty", "")
        end
    end
    
    -- Clear plot states from memory (but they remain in player data)
    local PlotManager = require(script.Parent.PlotManager)
    for plotIndex = 1, MAX_PLOTS_PER_FARM do
        local globalPlotId = FarmManager.getGlobalPlotId(farmId, plotIndex)
        PlotManager.clearPlotFromMemory(globalPlotId)
    end
    
    -- Clear assignment from player data (if player still online)
    local Players = game:GetService("Players")
    local player = Players:GetPlayerByUserId(userId)
    if player then
        local PlayerDataManager = require(script.Parent.PlayerDataManager)
        PlayerDataManager.setAssignedFarm(player, nil)
    end
    
    log.info("Farm", farmId, "unassigned from user", userId, "- plot states preserved in player data")
end

-- Convert farm and plot index to global plot ID
function FarmManager.getGlobalPlotId(farmId, plotIndex)
    return (farmId - 1) * MAX_PLOTS_PER_FARM + plotIndex
end

-- Convert global plot ID back to farm and plot index
function FarmManager.getFarmAndPlotFromGlobalId(globalPlotId)
    local farmId = math.floor((globalPlotId - 1) / MAX_PLOTS_PER_FARM) + 1
    local plotIndex = ((globalPlotId - 1) % MAX_PLOTS_PER_FARM) + 1
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

-- Alias for client requests
function FarmManager.getPlayerFarmId(userId)
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

-- Unlock a new plot for a player
function FarmManager.unlockPlot(player)
    local farmId = playerFarms[player.UserId]
    if not farmId then
        return false, "Player doesn't have a farm assigned"
    end
    
    local PlayerDataManager = require(script.Parent.PlayerDataManager)
    local success, message = PlayerDataManager.purchasePlot(player)
    
    if success then
        -- Get the newly unlocked plot count
        local unlockedPlots = PlayerDataManager.getUnlockedPlots(player)
        local newPlotIndex = unlockedPlots
        
        -- Initialize the new plot
        local PlotManager = require(script.Parent.PlotManager)
        local globalPlotId = FarmManager.getGlobalPlotId(farmId, newPlotIndex)
        PlotManager.initializePlot(globalPlotId, player.UserId, player)
        
        -- Update the visual state to unlocked/empty
        local WorldBuilder = require(script.Parent.Parent.WorldBuilder)
        local plot = WorldBuilder.getPlotById(globalPlotId)
        if plot then
            WorldBuilder.updatePlotState(plot, "empty", "")
            log.info("Unlocked plot", newPlotIndex, "for", player.Name)
        end
        
        -- Update all plots for this farm to reflect new unlock status
        for plotIndex = 1, MAX_PLOTS_PER_FARM do
            local checkGlobalPlotId = FarmManager.getGlobalPlotId(farmId, plotIndex)
            local checkPlot = WorldBuilder.getPlotById(checkGlobalPlotId)
            if checkPlot then
                if plotIndex <= unlockedPlots then
                    -- Plot is unlocked, ensure it's not showing locked state
                    local plotState = PlotManager.getPlotState(checkGlobalPlotId)
                    if plotState then
                        WorldBuilder.updatePlotState(checkPlot, plotState.state, plotState.seedType, plotState.variation)
                    else
                        WorldBuilder.updatePlotState(checkPlot, "empty", "")
                    end
                else
                    -- Plot is still locked - use progressive visibility system
                    local visibilityState, requiredRebirth = PlayerDataManager.getPlotVisibilityState(player, plotIndex)
                    
                    if visibilityState == "locked" then
                        WorldBuilder.updatePlotState(checkPlot, "locked", "", nil, nil, nil, plotIndex) -- Purchasable with price
                    elseif visibilityState == "next_tier" then
                        WorldBuilder.updatePlotState(checkPlot, "rebirth_locked", "", nil, nil, nil, plotIndex, requiredRebirth) -- Visible, needs rebirth
                    else -- invisible
                        WorldBuilder.updatePlotState(checkPlot, "invisible", "") -- Hidden
                    end
                end
            end
        end
        
        -- Send updates to client
        local RemoteManager = require(script.Parent.RemoteManager)
        if RemoteManager.sendPlotUpdate then
            local plotState = PlotManager.getPlotState(globalPlotId)
            RemoteManager.sendPlotUpdate(globalPlotId, plotState)
        end
    end
    
    return success, message
end

-- Get farm configuration info
function FarmManager.getFarmConfig()
    return {
        totalFarms = TOTAL_FARMS,
        basePlotsPerFarm = BASE_PLOTS_PER_FARM,
        maxPlotsPerFarm = MAX_PLOTS_PER_FARM,
        farmSize = FARM_SIZE,
        farmSpacing = FARM_SPACING
    }
end

return FarmManager