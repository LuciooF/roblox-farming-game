-- Client-side Logger
-- Simple client logger that mirrors server Logger functionality

local ClientLogger = {}

-- Log levels (same as server)
local LOG_LEVELS = {
    ERROR = 1,
    WARN = 2,
    INFO = 3,
    TRACE = 4,
    DEBUG = 5
}

-- Current log level (default to INFO)
local currentLogLevel = LOG_LEVELS.INFO

-- Color codes for different log levels
local LOG_COLORS = {
    [LOG_LEVELS.ERROR] = "🔴",
    [LOG_LEVELS.WARN] = "🟡", 
    [LOG_LEVELS.INFO] = "🔵",
    [LOG_LEVELS.TRACE] = "🟠",
    [LOG_LEVELS.DEBUG] = "🟢"
}

-- Get level name from number
local function getLevelName(level)
    for name, num in pairs(LOG_LEVELS) do
        if num == level then
            return name
        end
    end
    return "UNKNOWN"
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
    local levelName = getLevelName(level)
    local icon = LOG_COLORS[level] or "⚫"
    local formattedMessage = string.format("[%s] %s [%s] [%s] %s", 
        timestamp, icon, levelName, moduleName or "CLIENT", message)
    
    -- Output based on level
    if level == LOG_LEVELS.ERROR then
        warn(formattedMessage)
    else
        print(formattedMessage)
    end
end

-- Public logging functions
function ClientLogger.error(moduleName, message, ...)
    log(LOG_LEVELS.ERROR, moduleName, message, ...)
end

function ClientLogger.warn(moduleName, message, ...)
    log(LOG_LEVELS.WARN, moduleName, message, ...)
end

function ClientLogger.info(moduleName, message, ...)
    log(LOG_LEVELS.INFO, moduleName, message, ...)
end

function ClientLogger.trace(moduleName, message, ...)
    log(LOG_LEVELS.TRACE, moduleName, message, ...)
end

function ClientLogger.debug(moduleName, message, ...)
    log(LOG_LEVELS.DEBUG, moduleName, message, ...)
end

-- Set log level (can be called by remote)
function ClientLogger.setLevel(level)
    if type(level) == "string" then
        level = LOG_LEVELS[level:upper()]
    end
    
    if level and level >= LOG_LEVELS.ERROR and level <= LOG_LEVELS.DEBUG then
        currentLogLevel = level
        ClientLogger.info("ClientLogger", "Client log level changed to: " .. getLevelName(level))
        return true
    else
        ClientLogger.error("ClientLogger", "Invalid log level: " .. tostring(level))
        return false
    end
end

-- Convenience function for module-specific loggers
function ClientLogger.getModuleLogger(moduleName)
    return {
        error = function(message, ...) ClientLogger.error(moduleName, message, ...) end,
        warn = function(message, ...) ClientLogger.warn(moduleName, message, ...) end,
        info = function(message, ...) ClientLogger.info(moduleName, message, ...) end,
        trace = function(message, ...) ClientLogger.trace(moduleName, message, ...) end,
        debug = function(message, ...) ClientLogger.debug(moduleName, message, ...) end,
    }
end

-- Export log levels
ClientLogger.LEVELS = LOG_LEVELS

return ClientLogger