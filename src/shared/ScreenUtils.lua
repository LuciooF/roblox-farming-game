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


return ScreenUtils