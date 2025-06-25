-- Plot Utilities Module
-- Common plot-finding and utility functions shared across client modules

local Workspace = game:GetService("Workspace")

local ClientLogger = require(script.Parent.ClientLogger)
local log = ClientLogger.getModuleLogger("PlotUtils")

local PlotUtils = {}

-- Find plot by global ID (converts to farm+local ID system)
function PlotUtils.findPlotById(globalPlotId)
    local farmsContainer = Workspace:FindFirstChild("PlayerFarms")
    if not farmsContainer then 
        log.warn("No PlayerFarms found in Workspace when looking for plot", globalPlotId)
        return nil 
    end
    
    -- Convert global plot ID to farm ID and local plot ID
    local MAX_PLOTS_PER_FARM = 40
    local farmId = math.floor((globalPlotId - 1) / MAX_PLOTS_PER_FARM) + 1
    local localPlotId = ((globalPlotId - 1) % MAX_PLOTS_PER_FARM) + 1
    
    log.debug("Looking for global plot", globalPlotId, "-> farm", farmId, "local plot", localPlotId)
    
    -- Find the specific farm
    local farmFolder = farmsContainer:FindFirstChild("Farm_" .. farmId)
    if not farmFolder then
        log.warn("Could not find Farm_" .. farmId .. " for global plot", globalPlotId)
        return nil
    end
    
    -- Search for plot with matching local PlotId in this farm
    for _, child in pairs(farmFolder:GetDescendants()) do
        if child:IsA("BasePart") and child.Name:match("Plot") then
            local plotIdValue = child:FindFirstChild("PlotId")
            if plotIdValue and plotIdValue.Value == localPlotId then
                log.debug("Found global plot", globalPlotId, "as local plot", localPlotId, "in", farmFolder.Name)
                return child
            end
        end
    end
    
    log.debug("Plot", localPlotId, "not found in farm", farmId, "- may not be created yet for global plot", globalPlotId)
    return nil
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