-- Reusable Modal Component
-- Provides background click detection and proper modal behavior for UI panels
--
-- Usage Example:
--   return e(Modal, {
--       visible = visible,
--       onClose = onClose,
--       zIndex = 20,                    -- Optional: custom Z-index
--       closeOnBackgroundClick = true   -- Optional: enable/disable background click closing (default: true)
--   }, {
--       YourContent = e("Frame", {
--           -- Your UI content here
--       })
--   })

local React = require(game:GetService("ReplicatedStorage").Packages.react)
local e = React.createElement

local function Modal(props)
    local visible = props.visible or false
    local onClose = props.onClose or function() end
    local children = props.children or {}
    local zIndex = props.zIndex or 20
    local closeOnBackgroundClick = props.closeOnBackgroundClick ~= false -- Default to true
    
    -- Don't render anything if not visible
    if not visible then
        return nil
    end
    
    -- Simple approach: put background detector below content, content on top with higher Z-index
    local modalChildren = {}
    
    -- Add background detector if enabled
    if closeOnBackgroundClick then
        modalChildren.BackgroundDetector = e("TextButton", {
            Name = "ModalBackgroundDetector",
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = zIndex - 1,
            Active = true, -- Need this for click detection
            AutoButtonColor = false, -- Disable visual effects
            Modal = false, -- Don't steal input focus
            [React.Event.Activated] = function()
                onClose()
            end
        })
    end
    
    -- Add all content children with higher Z-index
    for key, child in pairs(children) do
        modalChildren[key] = child
    end
    
    return e("Frame", {
        Name = "ModalContainer",
        Size = UDim2.new(1, 0, 1, 0), -- Full screen
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = zIndex - 1
    }, modalChildren)
end

return Modal