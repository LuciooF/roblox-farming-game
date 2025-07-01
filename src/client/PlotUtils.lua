-- Plot Utilities Module
-- Common plot-finding and utility functions shared across client modules

local Workspace = game:GetService("Workspace")

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
    
    
    -- Find the specific farm
    local farmFolder = farmsContainer:FindFirstChild("Farm_" .. farmId)
    if not farmFolder then
        logWarn("Could not find Farm_" .. farmId .. " for global plot", globalPlotId)
        return nil
    end
    
    -- Search for plot with matching local PlotId in this farm
    -- First check in Plots folder (new structure)
    local plotsFolder = farmFolder:FindFirstChild("Plots")
    if plotsFolder then
        for _, child in pairs(plotsFolder:GetChildren()) do
            if (child:IsA("Model") or child:IsA("BasePart")) and child.Name:match("Plot") then
                local plotIdValue = child:FindFirstChild("PlotId")
                if plotIdValue and plotIdValue.Value == localPlotId then
                    
                    -- Cache the result
                    plotCache[globalPlotId] = child
                    lastCacheTime[globalPlotId] = tick()
                    
                    return child
                end
            end
        end
    end
    
    -- Fallback: search descendants for backward compatibility
    for _, child in pairs(farmFolder:GetDescendants()) do
        if (child:IsA("BasePart") or child:IsA("Model")) and child.Name:match("Plot") then
            local plotIdValue = child:FindFirstChild("PlotId")
            if plotIdValue and plotIdValue.Value == localPlotId then
                
                -- Cache the result
                plotCache[globalPlotId] = child
                lastCacheTime[globalPlotId] = tick()
                
                return child
            end
        end
    end
    
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
    -- Look for Plots folder first
    local plotsFolder = farmFolder:FindFirstChild("Plots")
    if plotsFolder then
        -- Get plots from Plots folder
        for _, plot in pairs(plotsFolder:GetChildren()) do
            if plot:IsA("Model") and plot.Name:match("^Plot") then
                table.insert(plots, plot)
            end
        end
    else
        -- Fallback: check direct children (old structure)
        for _, child in pairs(farmFolder:GetChildren()) do
            if (child:IsA("Model") or child:IsA("BasePart")) and child.Name:match("^Plot") then
                table.insert(plots, child)
            end
        end
    end
    
    return plots
end

-- Get the interaction part for a plot (for proximity prompts, positioning, etc.)
function PlotUtils.getPlotInteractionPart(plot)
    if not plot then return nil end
    
    -- If it's already a Part, return it
    if plot:IsA("BasePart") then
        return plot
    end
    
    -- If it's a Model, use PrimaryPart
    if plot:IsA("Model") then
        if plot.PrimaryPart then
            return plot.PrimaryPart
        end
        
        -- Fallback: look for a part named "PlotBase", "Core", or similar
        local basePart = plot:FindFirstChild("PlotBase") or plot:FindFirstChild("Core") or plot:FindFirstChild("Base")
        if basePart and basePart:IsA("BasePart") then
            return basePart
        end
        
        -- Final fallback: return the first Part found
        for _, child in pairs(plot:GetChildren()) do
            if child:IsA("BasePart") then
                return child
            end
        end
    end
    
    return nil
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