-- Plot Utilities Module
-- Common plot-finding and utility functions shared across client modules

local Workspace = game:GetService("Workspace")

-- Configurable logging functions for PlotUtils
local DEBUG_ENABLED = false -- Set to true only for debugging plot issues
local function logDebug(...) 
    if DEBUG_ENABLED then
        print("[DEBUG] PlotUtils:", ...) 
    end
end
local function logWarn(...) warn("[WARN] PlotUtils:", ...) end

local PlotUtils = {}

-- Cache for plot lookups to avoid repeated searches
local plotCache = {} -- [globalPlotId] = plotInstance
local lastCacheTime = {} -- [globalPlotId] = tick() when cached
local CACHE_DURATION = 10 -- Cache for 10 seconds

-- Clear cached plot if it no longer exists
local function validateCachedPlot(globalPlotId, cachedPlot)
    if not cachedPlot or not cachedPlot.Parent then
        plotCache[globalPlotId] = nil
        lastCacheTime[globalPlotId] = nil
        return false
    end
    return true
end

-- Find plot by global ID (converts to farm+local ID system) with caching
function PlotUtils.findPlotById(globalPlotId)
    -- Check cache first
    local cachedPlot = plotCache[globalPlotId]
    local cacheTime = lastCacheTime[globalPlotId]
    
    if cachedPlot and cacheTime and (tick() - cacheTime) < CACHE_DURATION then
        -- Validate cached plot still exists
        if validateCachedPlot(globalPlotId, cachedPlot) then
            return cachedPlot
        end
    end
    
    -- Cache miss or invalid - do the lookup
    local farmsContainer = Workspace:FindFirstChild("PlayerFarms")
    if not farmsContainer then 
        logWarn("No PlayerFarms found in Workspace when looking for plot", globalPlotId)
        return nil 
    end
    
    -- Convert global plot ID to farm ID and local plot ID
    local MAX_PLOTS_PER_FARM = 40
    local farmId = math.floor((globalPlotId - 1) / MAX_PLOTS_PER_FARM) + 1
    local localPlotId = ((globalPlotId - 1) % MAX_PLOTS_PER_FARM) + 1
    
    logDebug("Looking for global plot", globalPlotId, "-> farm", farmId, "local plot", localPlotId)
    
    -- Find the specific farm
    local farmFolder = farmsContainer:FindFirstChild("Farm_" .. farmId)
    if not farmFolder then
        logWarn("Could not find Farm_" .. farmId .. " for global plot", globalPlotId)
        return nil
    end
    
    -- Search for plot with matching local PlotId in this farm
    for _, child in pairs(farmFolder:GetDescendants()) do
        if child:IsA("BasePart") and child.Name:match("Plot") then
            local plotIdValue = child:FindFirstChild("PlotId")
            if plotIdValue and plotIdValue.Value == localPlotId then
                logDebug("Found global plot", globalPlotId, "as local plot", localPlotId, "in", farmFolder.Name)
                
                -- Cache the result
                plotCache[globalPlotId] = child
                lastCacheTime[globalPlotId] = tick()
                
                return child
            end
        end
    end
    
    logDebug("Plot", localPlotId, "not found in farm", farmId, "- may not be created yet for global plot", globalPlotId)
    return nil
end

-- Clear cache for a specific plot (call when plot is destroyed/moved)
function PlotUtils.clearPlotCache(globalPlotId)
    plotCache[globalPlotId] = nil
    lastCacheTime[globalPlotId] = nil
end

-- Clear entire cache (call when farms are rebuilt)
function PlotUtils.clearAllPlotCache()
    plotCache = {}
    lastCacheTime = {}
end

-- Get all plots across all farms
function PlotUtils.getAllPlots()
    local farmsContainer = Workspace:FindFirstChild("PlayerFarms")
    if not farmsContainer then return {} end
    
    local plots = {}
    for _, farmFolder in pairs(farmsContainer:GetChildren()) do
        if farmFolder.Name:match("^Farm_") then
            for _, child in pairs(farmFolder:GetChildren()) do
                if child.Name:match("^FarmPlot_") then
                    table.insert(plots, child)
                end
            end
        end
    end
    
    return plots
end

-- Get plots in a specific farm
function PlotUtils.getFarmPlots(farmId)
    local farmsContainer = Workspace:FindFirstChild("PlayerFarms")
    if not farmsContainer then return {} end
    
    local farmFolder = farmsContainer:FindFirstChild("Farm_" .. farmId)
    if not farmFolder then return {} end
    
    local plots = {}
    for _, child in pairs(farmFolder:GetChildren()) do
        if child.Name:match("^FarmPlot_") then
            table.insert(plots, child)
        end
    end
    
    return plots
end

-- Validate plot exists and get its data
function PlotUtils.validatePlot(plotId)
    local plot = PlotUtils.findPlotById(plotId)
    if not plot then
        return nil, "Plot not found"
    end
    
    local plotIdValue = plot:FindFirstChild("PlotId")
    local plotData = plot:FindFirstChild("PlotData")
    
    if not plotIdValue or not plotData then
        return nil, "Plot missing required data"
    end
    
    return plot, nil
end

return PlotUtils