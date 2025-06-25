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

-- Get responsive position offset
function ScreenUtils.getPositionOffset(screenSize, mobileOffset, desktopOffset)
    return ScreenUtils.isMobile(screenSize) and mobileOffset or desktopOffset
end

-- Calculate centered position for an element
function ScreenUtils.getCenteredPosition(elementSize, padding)
    padding = padding or 0
    return UDim2.new(0.5, -elementSize.X.Offset/2, 0.5, -elementSize.Y.Offset/2)
end

-- Get safe area insets for mobile devices
function ScreenUtils.getSafeAreaInsets(screenSize)
    if not ScreenUtils.isMobile(screenSize) then
        return {top = 0, bottom = 0, left = 0, right = 0}
    end
    
    -- Approximate safe area for mobile (notches, home indicators, etc.)
    return {
        top = 44,    -- Status bar + notch
        bottom = 34, -- Home indicator
        left = 0,
        right = 0
    }
end

return ScreenUtils