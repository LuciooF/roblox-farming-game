-- Client-side ProximityPrompt Handler
-- Intercepts proximity prompts for immediate visual feedback

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ClientLogger = require(script.Parent.ClientLogger)
local PlotInteractionManager = require(script.Parent.PlotInteractionManager)
local PlotUtils = require(script.Parent.PlotUtils)
local log = ClientLogger.getModuleLogger("PlotProximity")

local PlotProximityHandler = {}

local connectedPrompts = {} -- Track connected prompts
local scanConnection = nil -- Main scanning loop connection
local player = Players.LocalPlayer
local MAX_CONNECTIONS = 150 -- Prevent memory overflow from too many connections (increased for 6 farms x 9 plots x 3 prompts = 162 total)

-- Initialize proximity handler
function PlotProximityHandler.initialize()
    log.info("Plot proximity handler initialized")
    
    -- Start scanning for plots
    PlotProximityHandler.scanForPlots()
    
    -- Periodically scan for new plots with error handling (less frequent)
    if not scanConnection then
        scanConnection = spawn(function()
            while true do
                local success, err = pcall(function()
                    wait(30) -- Scan every 30 seconds for new plots (less frequent to reduce spam)
                    PlotProximityHandler.scanForPlots()
                end)
                
                if not success then
                    log.error("Plot scanning error:", err)
                    wait(60) -- Longer wait on error
                end
            end
        end)
    end
end

-- Scan workspace for plots and connect to their ProximityPrompts
function PlotProximityHandler.scanForPlots()
    -- Use PlotUtils to get all plots across all farms
    local plots = PlotUtils.getAllPlots()
    
    local connectionCount = 0
    for _ in pairs(connectedPrompts) do
        connectionCount = connectionCount + 1
    end
    
    log.debug("Scanning plots - Found", #plots, "plots, currently have", connectionCount, "connections")
    
    for _, plot in pairs(plots) do
        local plotIdValue = plot:FindFirstChild("PlotId")
        if plotIdValue then
            local plotId = plotIdValue.Value
            
            -- Connect to the single ActionPrompt
            PlotProximityHandler.connectPrompt(plot, plotId, "ActionPrompt", "action")
        end
    end
end

-- Connect to a specific ProximityPrompt with prediction
function PlotProximityHandler.connectPrompt(plot, plotId, promptName, actionType)
    local prompt = plot:FindFirstChild(promptName)
    if not prompt then return end
    
    -- Check if already connected
    local connectionKey = plotId .. "_" .. promptName
    local existingConnection = connectedPrompts[connectionKey]
    if existingConnection and existingConnection.Connected then
        return -- Already connected and still valid
    elseif existingConnection then
        -- Connection exists but is disconnected, clean it up
        connectedPrompts[connectionKey] = nil
    end
    
    -- Check connection limit BEFORE creating connection
    local connectionCount = 0
    for _ in pairs(connectedPrompts) do
        connectionCount = connectionCount + 1
    end
    
    if connectionCount >= MAX_CONNECTIONS then
        log.warn("Connection limit reached (" .. MAX_CONNECTIONS .. "), skipping new connection for plot", plotId, promptName)
        return
    end
    
    -- Connect with client-side prediction
    local connection = prompt.Triggered:Connect(function(triggeringPlayer)
        if triggeringPlayer ~= player then return end
        
        log.debug("Proximity prompt triggered:", actionType, "on plot", plotId)
        
        -- Immediate visual feedback for context-sensitive action
        local success = false
        if actionType == "action" then
            success = PlotInteractionManager.predictContextualAction(plot, plotId)
        end
        
        if success then
            log.debug("Applied immediate visual feedback for", actionType, "on plot", plotId)
        else
            log.debug("No prediction applied for", actionType, "on plot", plotId)
        end
    end)
    
    -- Store connection to prevent duplicates
    connectedPrompts[connectionKey] = connection
    log.debug("Connected to", promptName, "for plot", plotId, "(", connectionCount + 1, "total connections)")
end

-- Cleanup specific plot connections
function PlotProximityHandler.cleanupPlot(plotId)
    local toRemove = {}
    for connectionKey, connection in pairs(connectedPrompts) do
        if string.find(connectionKey, plotId .. "_") then
            connection:Disconnect()
            table.insert(toRemove, connectionKey)
        end
    end
    
    for _, key in ipairs(toRemove) do
        connectedPrompts[key] = nil
    end
    
    if #toRemove > 0 then
        log.debug("Cleaned up", #toRemove, "connections for plot", plotId)
    end
end

-- Clean up stale connections (for plots that no longer exist or disconnected connections)
function PlotProximityHandler.cleanupStaleConnections()
    local toRemove = {}
    local staleCount = 0
    local disconnectedCount = 0
    
    for connectionKey, connection in pairs(connectedPrompts) do
        local shouldRemove = false
        
        -- Check if connection is disconnected
        if not connection.Connected then
            disconnectedCount = disconnectedCount + 1
            shouldRemove = true
        else
            -- Extract plotId from connectionKey (format: "plotId_promptName")
            local plotId = connectionKey:match("^(.+)_[^_]+$")
            if plotId then
                -- Check if plot still exists
                local plot = PlotUtils.findPlotById(tonumber(plotId))
                if not plot then
                    connection:Disconnect()
                    staleCount = staleCount + 1
                    shouldRemove = true
                end
            end
        end
        
        if shouldRemove then
            table.insert(toRemove, connectionKey)
        end
    end
    
    for _, key in ipairs(toRemove) do
        connectedPrompts[key] = nil
    end
    
    if staleCount > 0 or disconnectedCount > 0 then
        log.info("Cleaned up", staleCount, "stale and", disconnectedCount, "disconnected proximity connections")
    end
end

-- Cleanup connections when plots are removed
function PlotProximityHandler.cleanup()
    -- Stop scanning loop
    if scanConnection then
        scanConnection = nil -- Note: spawn doesn't return a connection object to disconnect
    end
    
    -- Disconnect all prompt connections
    for connectionKey, connection in pairs(connectedPrompts) do
        connection:Disconnect()
    end
    connectedPrompts = {}
    log.info("Cleaned up all proximity prompt connections and scanning loop")
end

return PlotProximityHandler