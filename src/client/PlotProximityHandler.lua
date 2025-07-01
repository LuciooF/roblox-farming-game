-- Client-side ProximityPrompt Handler
-- Intercepts proximity prompts for immediate visual feedback

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Simple logging removed ClientLogger
local PlotInteractionManager = require(script.Parent.PlotInteractionManager)
local PlotUtils = require(script.Parent.PlotUtils)

local PlotProximityHandler = {}

local connectedPrompts = {} -- Track connected prompts
local scanConnection = nil -- Main scanning loop connection
local player = Players.LocalPlayer
local MAX_CONNECTIONS = 150 -- Prevent memory overflow from too many connections (increased for 6 farms x 9 plots x 3 prompts = 162 total)

-- Initialize proximity handler
function PlotProximityHandler.initialize()
    
    -- Start scanning for plots
    PlotProximityHandler.scanForPlots()
    
    -- Periodically scan for new plots with error handling (more frequent initially)
    if not scanConnection then
        scanConnection = spawn(function()
            local scanInterval = 5 -- Start with frequent scanning
            local maxInterval = 30
            
            while true do
                local success, err = pcall(function()
                    wait(scanInterval)
                    local plotCount = PlotProximityHandler.scanForPlots()
                    
                    -- If we found plots, reduce scanning frequency
                    if plotCount > 0 then
                        scanInterval = math.min(scanInterval + 5, maxInterval)
                    else
                        -- If no plots found, keep scanning frequently
                        scanInterval = 5
                    end
                end)
                
                if not success then
                    error("[ERROR]", "Plot scanning error:", err)
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
    
    
    local newConnections = 0
    for _, plot in pairs(plots) do
        local plotIdValue = plot:FindFirstChild("PlotId")
        if plotIdValue then
            local plotId = plotIdValue.Value
            
            -- Connect to the single ActionPrompt (will skip if already connected)
            local connected = PlotProximityHandler.connectPrompt(plot, plotId, "ActionPrompt", "action")
            if connected then
                newConnections = newConnections + 1
            end
        else
            warn("[WARN]", "⚠️ Plot without PlotId found:", plot.Name)
        end
    end
    
    if newConnections > 0 then
    end
    
    return #plots -- Return number of plots found
end

-- Connect to a specific ProximityPrompt with prediction
function PlotProximityHandler.connectPrompt(plot, plotId, promptName, actionType)
    local prompt = plot:FindFirstChild(promptName)
    if not prompt then 
        warn("[WARN]", "⚠️ No", promptName, "found on plot", plotId)
        return 
    end
    
    
    -- Check if already connected
    local connectionKey = plotId .. "_" .. promptName
    local existingConnection = connectedPrompts[connectionKey]
    if existingConnection and existingConnection.Connected then
        return false -- Already connected and still valid
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
        warn("[WARN]", "Connection limit reached (" .. MAX_CONNECTIONS .. "), skipping new connection for plot", plotId, promptName)
        return false
    end
    
    -- Connect with client-side prediction
    local connection = prompt.Triggered:Connect(function(triggeringPlayer)
        if triggeringPlayer ~= player then return end
        
        
        -- Immediate visual feedback for context-sensitive action
        local success = false
        if actionType == "action" then
            success = PlotInteractionManager.predictContextualAction(plot, plotId)
        end
        
        if success then
        else
            warn("[WARN]", "❌ No prediction applied for", actionType, "on plot", plotId)
        end
    end)
    
    -- Store connection to prevent duplicates
    connectedPrompts[connectionKey] = connection
    
    return true -- Successfully connected
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
end

return PlotProximityHandler