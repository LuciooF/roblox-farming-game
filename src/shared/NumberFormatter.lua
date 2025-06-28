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
    
    if num >= 1e63 then -- Vigintillion
        formatted = string.format("%.1fV", num / 1e63)
    elseif num >= 1e60 then -- Novemdecillion
        formatted = string.format("%.1fNd", num / 1e60)
    elseif num >= 1e57 then -- Octodecillion
        formatted = string.format("%.1fOd", num / 1e57)
    elseif num >= 1e54 then -- Septendecillion
        formatted = string.format("%.1fSpd", num / 1e54)
    elseif num >= 1e51 then -- Sexdecillion
        formatted = string.format("%.1fSxd", num / 1e51)
    elseif num >= 1e48 then -- Quindecillion
        formatted = string.format("%.1fQid", num / 1e48)
    elseif num >= 1e45 then -- Quattuordecillion
        formatted = string.format("%.1fQd", num / 1e45)
    elseif num >= 1e42 then -- Tredecillion
        formatted = string.format("%.1fTd", num / 1e42)
    elseif num >= 1e39 then -- Duodecillion
        formatted = string.format("%.1fDd", num / 1e39)
    elseif num >= 1e36 then -- Undecillion
        formatted = string.format("%.1fUd", num / 1e36)
    elseif num >= 1e33 then -- Decillion
        formatted = string.format("%.1fDc", num / 1e33)
    elseif num >= 1e30 then -- Nonillion
        formatted = string.format("%.1fN", num / 1e30)
    elseif num >= 1e27 then -- Octillion
        formatted = string.format("%.1fO", num / 1e27)
    elseif num >= 1e24 then -- Septillion
        formatted = string.format("%.1fSp", num / 1e24)
    elseif num >= 1e21 then -- Sextillion
        formatted = string.format("%.1fSx", num / 1e21)
    elseif num >= 1e18 then -- Quintillion
        formatted = string.format("%.1fQi", num / 1e18)
    elseif num >= 1e15 then -- Quadrillion
        formatted = string.format("%.1fQ", num / 1e15)
    elseif num >= 1e12 then -- Trillion
        formatted = string.format("%.1fT", num / 1e12)
    elseif num >= 1e9 then -- Billion
        formatted = string.format("%.1fB", num / 1e9)
    elseif num >= 1e6 then -- Million
        formatted = string.format("%.1fM", num / 1e6)
    elseif num >= 1e3 then -- Thousand
        formatted = string.format("%.1fK", num / 1e3)
    else
        -- Small numbers show exact value
        formatted = tostring(math.floor(num))
    end
    
    -- Remove unnecessary ".0" decimal points only (e.g., "1.0K" -> "1K", but keep "1.3K" as "1.3K")
    formatted = formatted:gsub("%.0K$", "K")
    formatted = formatted:gsub("%.0M$", "M")  
    formatted = formatted:gsub("%.0B$", "B")
    formatted = formatted:gsub("%.0T$", "T")
    formatted = formatted:gsub("%.0Q$", "Q")
    formatted = formatted:gsub("%.0Qi$", "Qi")
    formatted = formatted:gsub("%.0Sx$", "Sx")
    formatted = formatted:gsub("%.0Sp$", "Sp")
    formatted = formatted:gsub("%.0O$", "O")
    formatted = formatted:gsub("%.0N$", "N")
    formatted = formatted:gsub("%.0Dc$", "Dc")
    formatted = formatted:gsub("%.0Ud$", "Ud")
    formatted = formatted:gsub("%.0Dd$", "Dd")
    formatted = formatted:gsub("%.0Td$", "Td")
    formatted = formatted:gsub("%.0Qd$", "Qd")
    formatted = formatted:gsub("%.0Qid$", "Qid")
    formatted = formatted:gsub("%.0Sxd$", "Sxd")
    formatted = formatted:gsub("%.0Spd$", "Spd")
    formatted = formatted:gsub("%.0Od$", "Od")
    formatted = formatted:gsub("%.0Nd$", "Nd")
    formatted = formatted:gsub("%.0V$", "V")
    
    return negative and "-" .. formatted or formatted
end


return NumberFormatter