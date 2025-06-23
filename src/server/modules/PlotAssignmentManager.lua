-- Plot Assignment Manager
-- Handles automatic assignment and cleanup of plots for multiplayer gameplay
-- Manages the 6 shared plots and assigns them to players automatically

local Players = game:GetService("Players")

local Logger = require(script.Parent.Logger)
local log = Logger.getModuleLogger("PlotAssignment")

local PlotAssignmentManager = {}

-- Storage
local plotAssignments = {} -- [plotId] = {userId, playerName, joinTime}
local playerPlots = {} -- [userId] = plotId
local TOTAL_PLOTS = 6 -- Maximum number of plots available

-- Initialize the plot assignment system
function PlotAssignmentManager.initialize()
    log.info("Initializing plot assignment system with", TOTAL_PLOTS, "plots")
    
    -- Initialize empty plot assignments
    for i = 1, TOTAL_PLOTS do
        plotAssignments[i] = nil
    end
    
    -- Connect to player events
    Players.PlayerAdded:Connect(PlotAssignmentManager.onPlayerJoined)
    Players.PlayerRemoving:Connect(PlotAssignmentManager.onPlayerLeaving)
    
    log.info("Plot assignment system ready!")
end

-- Handle player joining - assign them a plot
function PlotAssignmentManager.onPlayerJoined(player)
    local plotId = PlotAssignmentManager.assignPlotToPlayer(player)
    if plotId then
        log.info("Assigned plot", plotId, "to player", player.Name, "(", player.UserId, ")")
    else
        log.warn("No available plots for player", player.Name, "- server is full")
        -- Could implement a queue system here in the future
    end
end

-- Handle player leaving - free up their plot
function PlotAssignmentManager.onPlayerLeaving(player)
    local plotId = playerPlots[player.UserId]
    if plotId then
        PlotAssignmentManager.unassignPlotFromPlayer(player.UserId)
        log.info("Freed plot", plotId, "from player", player.Name, "(", player.UserId, ")")
    end
end

-- Assign an available plot to a player
function PlotAssignmentManager.assignPlotToPlayer(player)
    local userId = player.UserId
    
    -- Check if player already has a plot
    if playerPlots[userId] then
        log.warn("Player", player.Name, "already has plot", playerPlots[userId])
        return playerPlots[userId]
    end
    
    -- Find first available plot
    for plotId = 1, TOTAL_PLOTS do
        if not plotAssignments[plotId] then
            -- Assign plot to player
            plotAssignments[plotId] = {
                userId = userId,
                playerName = player.Name,
                joinTime = tick()
            }
            playerPlots[userId] = plotId
            
            -- Notify other systems about the assignment
            PlotAssignmentManager.onPlotAssigned(plotId, player)
            
            return plotId
        end
    end
    
    return nil -- No available plots
end

-- Unassign a plot from a player
function PlotAssignmentManager.unassignPlotFromPlayer(userId)
    local plotId = playerPlots[userId]
    if not plotId then
        return false
    end
    
    -- Clear assignment
    plotAssignments[plotId] = nil
    playerPlots[userId] = nil
    
    -- Notify other systems about the unassignment
    PlotAssignmentManager.onPlotUnassigned(plotId, userId)
    
    return true
end

-- Called when a plot is assigned to a player
function PlotAssignmentManager.onPlotAssigned(plotId, player)
    -- Update visual ownership display
    local WorldBuilder = require(script.Parent.Parent.WorldBuilder)
    WorldBuilder.updatePlotOwnership(plotId, player.Name)
    
    -- Initialize plot state in PlotManager
    local PlotManager = require(script.Parent.PlotManager)
    PlotManager.initializePlot(plotId, player.UserId)
    
    -- Store assignment in player data
    local PlayerDataManager = require(script.Parent.PlayerDataManager)
    PlayerDataManager.setAssignedPlot(player, plotId)
    
    log.debug("Plot", plotId, "assigned to", player.Name)
end

-- Called when a plot is unassigned from a player  
function PlotAssignmentManager.onPlotUnassigned(plotId, userId)
    -- Clear visual ownership display
    local WorldBuilder = require(script.Parent.Parent.WorldBuilder)
    WorldBuilder.updatePlotOwnership(plotId, nil)
    
    -- Reset plot state in PlotManager
    local PlotManager = require(script.Parent.PlotManager)
    PlotManager.resetPlot(plotId)
    
    -- Clear assignment from player data (if player still online)
    local Players = game:GetService("Players")
    local player = Players:GetPlayerByUserId(userId)
    if player then
        local PlayerDataManager = require(script.Parent.PlayerDataManager)
        PlayerDataManager.setAssignedPlot(player, nil)
    end
    
    log.debug("Plot", plotId, "unassigned from user", userId)
end

-- Get the player who owns a specific plot
function PlotAssignmentManager.getPlotOwner(plotId)
    local assignment = plotAssignments[plotId]
    if assignment then
        return assignment.userId, assignment.playerName
    end
    return nil, nil
end

-- Get the plot assigned to a specific player
function PlotAssignmentManager.getPlayerPlot(userId)
    return playerPlots[userId]
end

-- Check if a player owns a specific plot
function PlotAssignmentManager.doesPlayerOwnPlot(userId, plotId)
    return playerPlots[userId] == plotId
end

-- Get all current plot assignments (for debugging/admin)
function PlotAssignmentManager.getAllAssignments()
    local assignments = {}
    for plotId = 1, TOTAL_PLOTS do
        local assignment = plotAssignments[plotId]
        if assignment then
            assignments[plotId] = {
                userId = assignment.userId,
                playerName = assignment.playerName,
                joinTime = assignment.joinTime
            }
        else
            assignments[plotId] = nil
        end
    end
    return assignments
end

-- Get number of available plots
function PlotAssignmentManager.getAvailablePlotCount()
    local count = 0
    for plotId = 1, TOTAL_PLOTS do
        if not plotAssignments[plotId] then
            count = count + 1
        end
    end
    return count
end

-- Get number of occupied plots
function PlotAssignmentManager.getOccupiedPlotCount()
    return TOTAL_PLOTS - PlotAssignmentManager.getAvailablePlotCount()
end

-- Force unassign a plot (admin function)
function PlotAssignmentManager.forceUnassignPlot(plotId)
    local assignment = plotAssignments[plotId]
    if assignment then
        local userId = assignment.userId
        PlotAssignmentManager.unassignPlotFromPlayer(userId)
        log.warn("Force unassigned plot", plotId, "from user", userId)
        return true
    end
    return false
end

-- Debug function to print current assignments
function PlotAssignmentManager.printAssignments()
    log.info("Current plot assignments:")
    for plotId = 1, TOTAL_PLOTS do
        local assignment = plotAssignments[plotId]
        if assignment then
            log.info("Plot", plotId, "->", assignment.playerName, "(", assignment.userId, ")")
        else
            log.info("Plot", plotId, "-> AVAILABLE")
        end
    end
end

return PlotAssignmentManager