-- Plot Utilities Module
-- Common plot-finding and utility functions shared across client modules

local Workspace = game:GetService("Workspace")

local ClientLogger = require(script.Parent.ClientLogger)
local log = ClientLogger.getModuleLogger("PlotUtils")

local PlotUtils = {}

-- Find plot by ID in workspace (searches across all farm areas)
function PlotUtils.findPlotById(plotId)
    local farmsContainer = Workspace:FindFirstChild("PlayerFarms")
    if not farmsContainer then 
        log.warn("No PlayerFarms found in Workspace when looking for plot", plotId)
        return nil 
    end
    
    -- Search through all farm areas
    local availablePlots = {}
    for _, farmFolder in pairs(farmsContainer:GetChildren()) do
        if farmFolder.Name:match("^Farm_") then
            for _, plot in pairs(farmFolder:GetChildren()) do
                local plotIdValue = plot:FindFirstChild("PlotId")
                if plotIdValue then
                    table.insert(availablePlots, tostring(plotIdValue.Value))
                    if plotIdValue.Value == plotId then
                        log.debug("Found plot", plotId, "successfully in", farmFolder.Name)
                        return plot
                    end
                end
            end
        end
    end
    
    log.warn("Could not find plot", plotId, "in workspace. Available plots:", table.concat(availablePlots, ", "))
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