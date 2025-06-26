-- Number Formatter Utility
-- Formats large numbers into readable formats (100k, 10M, 10B, etc.)

local NumberFormatter = {}

-- Format a number into a readable string
function NumberFormatter.format(num)
    if not num or type(num) ~= "number" then
        return "0"
    end
    
    -- Handle negative numbers
    local negative = num < 0
    num = math.abs(num)
    
    local formatted
    
    if num >= 1e15 then -- Quadrillion
        formatted = string.format("%.1fQ", num / 1e15)
    elseif num >= 1e12 then -- Trillion
        formatted = string.format("%.1fT", num / 1e12)
    elseif num >= 1e9 then -- Billion
        formatted = string.format("%.1fB", num / 1e9)
    elseif num >= 1e6 then -- Million
        formatted = string.format("%.1fM", num / 1e6)
    elseif num >= 1e3 then -- Thousand
        formatted = string.format("%.1fk", num / 1e3)
    else
        -- Small numbers show exact value
        formatted = tostring(math.floor(num))
    end
    
    -- Remove unnecessary decimal points (e.g., "1.0k" -> "1k")
    formatted = formatted:gsub("%.0", "")
    
    return negative and "-" .. formatted or formatted
end

-- Format with commas for full display (e.g., in detailed views)
function NumberFormatter.formatWithCommas(num)
    if not num or type(num) ~= "number" then
        return "0"
    end
    
    local negative = num < 0
    num = math.abs(num)
    
    local formatted = tostring(math.floor(num))
    local k
    
    while true do
        formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then
            break
        end
    end
    
    return negative and "-" .. formatted or formatted
end

return NumberFormatter