# Claude Development Notes

## 🚨 Critical Development Guidelines

### **File Size & Modularity**
- **NEVER create files >300 lines** - break into modules immediately
- **Separate concerns**: UI, logic, data, and configuration should be in different files
- **Use composition over inheritance** - small, focused modules that work together
- **Example**: Instead of one massive `FarmingSystem.lua`, we have `PlotManager.lua`, `SeedDropSystem.lua`, `GameConfig.lua`, etc.

### **Sound System**
- **All sound calls are commented out** - no sound assets loaded yet
- **Uncomment sounds** when assets are available by removing `--` from SoundManager calls
- **Client sound errors**: SoundClient module exists but isn't always available

### **UI Architecture**
- **Fallback system in place**: React UI → Simple emoji UI if React unavailable
- **Mobile responsive**: UI scales based on screen size detection
- **Component structure**: Each UI element should be its own component/module

### **Configuration Management**
- **GameConfig.lua**: Central place for all game constants
- **Never hardcode values** in business logic - always reference GameConfig
- **Missing properties cause nil errors** - ensure all seed configs have required fields

### **Error Prevention Patterns**
- **Always check for nil** before accessing nested properties
- **Use pcall** for operations that might fail (DataStore, external services)
- **Default values**: `local value = data.field or defaultValue`

### **Code Organization Best Practices**
```lua
-- ✅ Good: Modular structure
src/
├── server/
│   ├── modules/           -- Small, focused modules
│   │   ├── GameConfig.lua -- Configuration only
│   │   ├── PlotManager.lua -- Plot logic only  
│   │   └── SeedDropSystem.lua -- Seed drops only
│   └── FarmingSystemNew.lua -- Orchestrator only
├── client/
│   ├── components/        -- UI components
│   └── init.client.lua    -- Main client coordinator
```

### **Roblox-Specific Notes**
- **RemoteEvents**: Always validate server-side, never trust client
- **DataStore errors**: Wrap in pcall, provide fallbacks for Studio mode
- **Color vs BrickColor**: Use `BrickColor.new()` for Parts, `Color3.fromRGB()` for UI
- **Script loading order**: ServerScript → RemoteEvents → ClientScript

### **Logging System** ⚠️ CRITICAL
- **ALWAYS use Logger**: Never use `print()` statements - use Logger.info(), Logger.debug(), etc.
- **Log hierarchy**: ERROR(1) → WARN(2) → INFO(3) → TRACE(4) → DEBUG(5)
- **Hierarchical filtering**: Selecting level 3 shows levels 1, 2, and 3
- **Module loggers**: Use `local log = Logger.getModuleLogger("ModuleName")` then `log.info(...)`
- **Level usage**: ERROR for critical issues, WARN for problems, INFO for important events, TRACE for detailed flow, DEBUG for development details
- **Client logging**: Use `ClientLogger.lua` for client-side logging (same API as server Logger)
- **NO EXCEPTIONS**: Any new code MUST use the logging system - no print() statements allowed

### **Testing & Debugging**
- **Test suite available**: `_G.runFarmingGameTests()` in server console
- **Development mode**: Hot reload support when in Studio
- **Fallback detection**: Client automatically detects missing dependencies
- **Rojo running externally**: User runs `rojo serve` in separate terminal - DO NOT run rojo commands

### **Performance Considerations**
- **Limit active systems**: SeedDropSystem cleans up old seeds automatically
- **Efficient updates**: UI only updates when data changes
- **Memory management**: Clean up event connections when objects are destroyed

### **Future Enhancements**
- **React system ready**: Full component library exists, just needs React packages
- **Sound system ready**: All hooks in place, just need audio assets
- **Mobile optimization**: UI is responsive but could be further optimized

## 🛠️ Quick Commands

### **Test the game:**
```lua
-- In server console:
_G.runFarmingGameTests()
```

### **Enable sounds when assets are ready:**
```lua
-- Remove -- from these lines in relevant files:
-- SoundManager.playPlantSound(plot.Position)
-- SoundClient.playClickSound()
```

### **Switch to React UI:**
1. Install react and react-roblox packages via Wally
2. Client will automatically detect and use full React system

---
*Last updated: 2025-01-22*
*Remember: Small files, big impact! 🎯*