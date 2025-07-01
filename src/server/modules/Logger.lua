-- Professional Logging System
-- Supports multiple log levels with runtime configuration

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Logger = {}

-- Log levels (hierarchical: lower number = higher priority)
local LOG_LEVELS = {
    ERROR = 1,   -- Critical errors (highest priority)
    WARN = 2,    -- Warnings
    INFO = 3,    -- General information
    TRACE = 4,   -- Detailed trace information
    DEBUG = 5    -- Debug information (lowest priority)
}

-- Current log level (can be changed at runtime)
local currentLogLevel = LOG_LEVELS.DEBUG -- Changed to DEBUG to show all logs for debugging

-- Color codes for different log levels
local LOG_COLORS = {
    [LOG_LEVELS.ERROR] = "🔴",
    [LOG_LEVELS.WARN] = "🟡", 
    [LOG_LEVELS.INFO] = "🔵",
    [LOG_LEVELS.DEBUG] = "🟢",
    [LOG_LEVELS.TRACE] = "⚪"
}

-- Module names for better organization
local moduleNames = {}

-- Set current log level
function Logger.setLevel(level)
    if type(level) == "string" then
        level = LOG_LEVELS[level:upper()]
    end
    
    if level and level >= LOG_LEVELS.ERROR and level <= LOG_LEVELS.DEBUG then
        currentLogLevel = level
        Logger.info("Logger", "Log level changed to: " .. Logger.getLevelName(level))
        return true
    else
        Logger.error("Logger", "Invalid log level: " .. tostring(level))
        return false
    end
end

-- Get current log level
function Logger.getLevel()
    return currentLogLevel
end

-- Get level name from number
function Logger.getLevelName(level)
    for name, num in pairs(LOG_LEVELS) do
        if num == level then
            return name
        end
    end
    return "UNKNOWN"
end

-- Register a module name for better logging
function Logger.registerModule(moduleName)
    moduleNames[moduleName] = true
    return moduleName
end

-- Core logging function
local function log(level, moduleName, message, ...)
    -- Check if we should log this level (show this level and all higher priority levels)
    if level > currentLogLevel then
        return
    end
    
    -- Format the message
    local args = {...}
    if #args > 0 then
        -- Convert all arguments to strings and concatenate
        local argStrings = {}
        for i, arg in ipairs(args) do
            argStrings[i] = tostring(arg)
        end
        message = message .. " " .. table.concat(argStrings, " ")
    end
    
    -- Get timestamp
    local timestamp = os.date("%H:%M:%S")
    
    -- Format: [TIME] ICON [LEVEL] [MODULE] Message
    local levelName = Logger.getLevelName(level)
    local icon = LOG_COLORS[level] or "⚫"
    local formattedMessage = string.format("[%s] %s [%s] [%s] %s", 
        timestamp, icon, levelName, moduleName or "UNKNOWN", message)
    
    -- Output based on level
    if level == LOG_LEVELS.ERROR then
        warn(formattedMessage)
    else
        print(formattedMessage)
    end
end

-- Public logging functions
function Logger.error(moduleName, message, ...)
    log(LOG_LEVELS.ERROR, moduleName, message, ...)
end

function Logger.warn(moduleName, message, ...)
    log(LOG_LEVELS.WARN, moduleName, message, ...)
end

function Logger.info(moduleName, message, ...)
    log(LOG_LEVELS.INFO, moduleName, message, ...)
end

function Logger.debug(moduleName, message, ...)
    log(LOG_LEVELS.DEBUG, moduleName, message, ...)
end

function Logger.trace(moduleName, message, ...)
    log(LOG_LEVELS.TRACE, moduleName, message, ...)
end

-- Convenience function for module-specific loggers
function Logger.getModuleLogger(moduleName)
    Logger.registerModule(moduleName)
    
    return {
        error = function(message, ...) Logger.error(moduleName, message, ...) end,
        warn = function(message, ...) Logger.warn(moduleName, message, ...) end,
        info = function(message, ...) Logger.info(moduleName, message, ...) end,
        debug = function(message, ...) Logger.debug(moduleName, message, ...) end,
        trace = function(message, ...) Logger.trace(moduleName, message, ...) end,
    }
end

-- Remote command handling for in-game log level changes
local function setupRemoteCommands()
    local remoteFolder = ReplicatedStorage:FindFirstChild("FarmingRemotes")
    if not remoteFolder then
        -- Create if it doesn't exist
        remoteFolder = Instance.new("Folder")
        remoteFolder.Name = "FarmingRemotes"
        remoteFolder.Parent = ReplicatedStorage
    end
    
    local logCommandRemote = remoteFolder:FindFirstChild("LogCommand")
    if not logCommandRemote then
        logCommandRemote = Instance.new("RemoteEvent")
        logCommandRemote.Name = "LogCommand"
        logCommandRemote.Parent = remoteFolder
    end
    
    logCommandRemote.OnServerEvent:Connect(function(player, command, ...)
        -- Only allow in Studio or for developers
        if not RunService:IsStudio() then
            return
        end
        
        if command == "setlevel" then
            local level = ...
            local success = Logger.setLevel(level)
            if success then
                Logger.info("Logger", player.Name .. " changed log level to " .. tostring(level))
            end
        elseif command == "getlevel" then
            Logger.info("Logger", "Current log level: " .. Logger.getLevelName(currentLogLevel))
        elseif command == "test" then
            Logger.error("Logger", "Test ERROR message")
            Logger.warn("Logger", "Test WARN message") 
            Logger.info("Logger", "Test INFO message")
            Logger.trace("Logger", "Test TRACE message")
            Logger.debug("Logger", "Test DEBUG message")
        end
    end)
end

-- Initialize the logger
function Logger.initialize()
    setupRemoteCommands()
    Logger.info("Logger", "Logging system initialized - Level: " .. Logger.getLevelName(currentLogLevel))
    Logger.debug("Logger", "Available levels: ERROR(1), WARN(2), INFO(3), TRACE(4), DEBUG(5)")
end

-- Export log levels for external use
Logger.LEVELS = LOG_LEVELS

return Logger