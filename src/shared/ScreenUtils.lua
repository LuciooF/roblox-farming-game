-- Screen Utilities
-- Common utility functions for responsive UI design

local ScreenUtils = {}

-- Determine if device is mobile based on screen size
function ScreenUtils.isMobile(screenSize)
    return screenSize.X < 768
end

-- Get responsive scale factor based on screen size
function ScreenUtils.getScale(screenSize)
    return ScreenUtils.isMobile(screenSize) and 0.8 or 1
end

-- Get responsive scale with custom mobile/desktop values
function ScreenUtils.getCustomScale(screenSize, mobileScale, desktopScale)
    return ScreenUtils.isMobile(screenSize) and mobileScale or desktopScale
end

-- Get proportional scale based on actual screen size (UNIVERSAL)
function ScreenUtils.getProportionalScale(screenSize, baseScreenSize, minScale, maxScale)
    baseScreenSize = baseScreenSize or Vector2.new(1920, 1080) -- Standard 1080p as baseline
    minScale = minScale or 0.5 -- Minimum scale for very small screens
    maxScale = maxScale or 1.8 -- Maximum scale for very large screens
    
    -- Universal scaling based on screen dimensions without isMobile checks
    local scaleX = screenSize.X / baseScreenSize.X
    local scaleY = screenSize.Y / baseScreenSize.Y
    
    -- Use the smaller dimension to ensure UI fits on screen
    local scale = math.min(scaleX, scaleY)
    
    -- Apply a slight adjustment curve for better visual balance
    -- Smaller screens (< 1.0 scale) get slightly boosted, larger screens slightly reduced
    if scale < 1.0 then
        scale = scale * 1.1 -- Boost small screens by 10%
    else
        scale = scale * 0.95 -- Reduce large screens by 5%
    end
    
    return math.max(minScale, math.min(maxScale, scale))
end

-- Get responsive padding based on screen size
function ScreenUtils.getPadding(screenSize, mobilePadding, desktopPadding)
    mobilePadding = mobilePadding or 5
    desktopPadding = desktopPadding or 10
    return ScreenUtils.isMobile(screenSize) and mobilePadding or desktopPadding
end

-- Get responsive text size
function ScreenUtils.getTextSize(screenSize, mobileSize, desktopSize)
    return ScreenUtils.isMobile(screenSize) and mobileSize or desktopSize
end

-- UNIVERSAL PROPORTIONAL HELPERS (No isMobile checks)

-- Get proportional padding value
function ScreenUtils.getProportionalPadding(screenSize, basePadding)
    basePadding = basePadding or 10
    local scale = ScreenUtils.getProportionalScale(screenSize)
    return math.floor(basePadding * scale + 0.5) -- Round to nearest integer
end

-- Get proportional text size
function ScreenUtils.getProportionalTextSize(screenSize, baseTextSize)
    baseTextSize = baseTextSize or 16
    local scale = ScreenUtils.getProportionalScale(screenSize)
    return math.floor(baseTextSize * scale + 0.5)
end

-- Get proportional size (for any dimension)
function ScreenUtils.getProportionalSize(screenSize, baseSize)
    local scale = ScreenUtils.getProportionalScale(screenSize)
    return math.floor(baseSize * scale + 0.5)
end

-- Get proportional UDim2 size
function ScreenUtils.getProportionalUDim2(screenSize, baseX, baseY, scaleX, scaleY)
    local scale = ScreenUtils.getProportionalScale(screenSize)
    scaleX = scaleX or 0
    scaleY = scaleY or 0
    return UDim2.new(scaleX, math.floor(baseX * scale + 0.5), scaleY, math.floor(baseY * scale + 0.5))
end


return ScreenUtils