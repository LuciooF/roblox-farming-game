# Mobile Scaling Analysis

## Current State

### isMobile Usage Statistics
- **24 UI components** use `isMobile` detection
- Detection threshold: `screenSize.X < 768` pixels
- All components use conditional logic: `isMobile and mobileValue or desktopValue`

### Common Usage Patterns

1. **Panel Sizing**
   - Mobile: 95% of screen width, 85% of screen height
   - Desktop: 70-85% of screen width (max 700-1100px), 75-80% of screen height (max 600-750px)

2. **Button/Icon Sizes**
   - Mobile: 40-50px buttons, 24px icons
   - Desktop: 55-60px buttons, 32px icons

3. **Text Sizes**
   - Mobile: 10-12px
   - Desktop: 12-14px

4. **Grid Layouts**
   - Mobile: 2 columns
   - Desktop: 4 columns

5. **Spacing/Padding**
   - Mobile: 5-10px
   - Desktop: 10-12px

## Issues with Current Approach

1. **Binary Detection**: Only two states (mobile/desktop) doesn't account for tablets, small laptops, or large phones
2. **Fixed Threshold**: 768px is arbitrary and doesn't adapt to actual screen density or device capabilities
3. **Maintenance Burden**: Every component needs duplicate values for mobile and desktop
4. **Inconsistent Scaling**: Some components use custom scales, others use fixed multipliers

## Recommendation: Universal Proportional Scaling

### Benefits
1. **Smooth Scaling**: Adapts to any screen size without jarring transitions
2. **Single Values**: One set of base values that scale proportionally
3. **Better Tablet Support**: Works well on all screen sizes
4. **Easier Maintenance**: Less conditional logic, fewer magic numbers

### Implementation Strategy

1. **Keep ScreenUtils.getProportionalScale()**: Already provides smooth scaling
2. **Gradually migrate components** to use proportional scaling instead of binary checks
3. **Use base values** designed for 1920x1080 and let them scale
4. **Special cases only** for truly mobile-specific needs (e.g., touch targets)

### Example Migration

**Before (Binary):**
```lua
local buttonSize = isMobile and 40 or 55
local panelWidth = isMobile and screenSize.X * 0.95 or math.min(screenSize.X * 0.7, 700)
```

**After (Proportional):**
```lua
local scale = ScreenUtils.getProportionalScale(screenSize)
local buttonSize = 55 * scale -- Base size for 1920x1080
local panelWidth = math.min(screenSize.X * 0.7, 700 * scale)
```

## PlotUI Specific Fix

The resize issue was caused by:
1. Fixed `ButtonsContainer` height of 250px
2. Harvest button appearing at fixed Y=165 position
3. No dynamic adjustment when buttons appear/disappear

**Solution Applied:**
- Dynamic container height calculation based on visible buttons
- Dynamic button positioning that adjusts to visible elements
- Proper spacing between buttons

## Next Steps

1. **Test PlotUI fix** to ensure harvest button doesn't cause resize issues
2. **Create migration plan** for moving components to proportional scaling
3. **Identify truly mobile-specific features** (if any) that need special handling
4. **Update ScreenUtils** with more helper functions for common patterns