# 🌾 3D Farming Game for Roblox

A modern, React-based 3D farming simulation game built for Roblox with advanced UI components, modular server architecture, and comprehensive progression systems.

## 🎮 Game Overview

This is a sophisticated farming simulation where players:
- **Plant and grow crops** with realistic growth timers and watering mechanics
- **Manage inventory** using a Minecraft-style hotbar with expandable slots
- **Progress through rebirths** with increasing crop value multipliers
- **Unlock premium features** through gamepasses and automation systems
- **Follow guided tutorials** to learn game mechanics progressively

### Key Features

- 🌱 **Dynamic Crop System**: Multiple seed types with different rarities, growth times, and values
- 🎒 **Expandable Inventory**: Hotbar system with purchasable slots and left-packing organization
- 🔄 **Rebirth Progression**: Prestige system that increases crop value multipliers
- 🤖 **Automation Features**: Premium tools for batch planting, watering, and harvesting
- 📚 **Tutorial System**: Guided onboarding for new players
- 🎨 **Modern UI**: React-based responsive interface with smooth animations
- 🔊 **Audio Integration**: Comprehensive sound system for immersive gameplay

## 🏗️ Architecture

### Client-Side (React-based)
```
src/client/
├── components/          # React UI components
│   ├── MainUI.lua          # Root UI component
│   ├── HotbarInventory.lua # Minecraft-style inventory hotbar
│   ├── ShopPanel.lua       # Seed purchasing interface
│   ├── PremiumPanel.lua    # Gamepass and premium features
│   └── TutorialPanel.lua   # Interactive tutorial system
├── ClientLogger.lua     # Client-side logging system
├── LogCommands.client.lua # Development debugging tools
└── init.client.lua      # Client initialization
```

### Server-Side (Modular Architecture)
```
src/server/
├── modules/             # Core game systems
│   ├── GameConfig.lua      # Game balance and configuration
│   ├── PlayerDataManager.lua # Player data and inventory
│   ├── PlotManager.lua     # Farm plot state management
│   ├── RemoteManager.lua   # Client-server communication
│   ├── AutomationSystem.lua # Premium automation features
│   ├── NotificationManager.lua # Player notifications
│   └── TutorialManager.lua # Tutorial progression tracking
├── FarmingSystemNew.lua # Main game coordinator
├── WorldBuilder.lua     # 3D world generation
└── init.server.lua      # Server initialization
```

## 🚀 Getting Started

### Prerequisites
- Roblox Studio
- Basic knowledge of Lua and Roblox development

### Installation
1. Clone this repository
2. Open the project in Roblox Studio
3. The game will automatically initialize server and client systems
4. Start playtesting to explore the farming mechanics

### Development Setup
- **Logging**: Use `/loglevel DEBUG` in Studio for detailed logs
- **Testing**: Built-in tutorial system guides through all features
- **Debugging**: Comprehensive logging system tracks all game events

## 🎯 Game Systems

### Farming Mechanics
- **Plot Management**: Interactive 3D plots with ProximityPrompts
- **Growth Timers**: Real-time crop growth with visual feedback
- **Watering System**: Plants require water to grow and can die without care
- **Harvest Cooldowns**: Realistic farming timers prevent exploitation

### Economy & Progression
- **Seed Rarities**: Common, uncommon, rare, epic, and legendary seeds
- **Dynamic Pricing**: Crop values scale with rarity and rebirth multipliers
- **Rebirth System**: Prestige mechanic that resets progress for permanent bonuses
- **Premium Features**: Gamepass-locked automation and convenience tools

### User Interface
- **Responsive Design**: Adapts to mobile and desktop screen sizes
- **Inventory Management**: Drag-free hotbar selection with keyboard shortcuts (1-9)
- **Real-time Updates**: Live inventory sync and growth countdown displays
- **Accessibility**: Clear visual feedback and intuitive interactions

## 🔧 Technical Features

### Performance Optimizations
- **Separated Game Loops**: Growth monitoring (5s) vs UI updates (1s)
- **Efficient State Management**: Minimal re-renders with React hooks
- **Smart Caching**: Optimized data structures for plot and player management

### Code Quality
- **Modular Design**: Clear separation of concerns across all systems
- **Comprehensive Logging**: Multi-level logging system for debugging
- **Error Handling**: Robust error management with user-friendly notifications
- **Clean Architecture**: SOLID principles applied throughout codebase

### Security & Anti-Cheat
- **Server-Side Validation**: All critical game logic validated on server
- **Rate Limiting**: RemoteEvent protection against exploitation
- **Data Integrity**: Player data validation and sanitization

## 🛠️ Development

### Key Components
- **React Integration**: Modern UI patterns with functional components and hooks
- **State Management**: Centralized player data with automatic synchronization
- **Event System**: Comprehensive RemoteEvent architecture for client-server communication
- **Configuration**: Centralized game balance in `GameConfig.lua`

### Extension Points
- **New Crops**: Add entries to `GameConfig.Plants` with growth parameters
- **UI Components**: Create React components in `client/components/`
- **Game Mechanics**: Extend modules in `server/modules/` for new features
- **Automation**: Add premium features through `AutomationSystem.lua`

### Crop Configuration Example
```lua
-- In GameConfig.lua
GameConfig.Plants.newCrop = {
    growthTime = 45,        -- seconds to grow
    waterNeeded = 2,        -- water cycles required
    basePrice = 20,         -- base sell price
    seedCost = 35,          -- cost to buy seeds
    description = "A new exotic crop",
    harvestCooldown = 20,   -- seconds between harvests
    deathTime = 300         -- seconds until plant dies without water
}
```

### Adding UI Components
```lua
-- Create new component in client/components/
local function NewComponent(props)
    return React.createElement("Frame", {
        Size = UDim2.new(0, 200, 0, 100),
        BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    })
end

return NewComponent
```

## 📈 Game Progression

### Inventory System
- **9 Main Slots**: Always visible with keyboard shortcuts (1-9)
- **Expandable Slots**: Purchase additional slots for $50 each
- **Smart Packing**: Items automatically organize left-to-right
- **Visual Selection**: Clear indicators show which item is selected
- **Hand Display**: Selected items appear in player's hand

### Rebirth System
- **Money Requirements**: Increasing thresholds for each rebirth
- **Crop Multipliers**: Permanent bonuses to crop sale values
- **Preserved Progress**: Inventory slots and some achievements carry over
- **Prestige Levels**: Visual indicators of player progression

### Premium Features
- **Automation Tools**: Batch plant, water, harvest, and sell operations
- **Premium UI**: Enhanced interfaces for gamepass owners
- **Exclusive Content**: Special crops and equipment for premium players

## 🧪 Testing & Debugging

### Built-in Tools
- **Log Commands**: `/loglevel`, `/logtest` for development debugging
- **Tutorial System**: Step-by-step guidance for testing all features
- **Real-time Monitoring**: Server and client logging for issue tracking

### Development Commands (Studio Only)
```
/loglevel DEBUG     # Enable detailed logging
/loglevel INFO      # Standard logging level
/logtest           # Test all log levels
```

## 📁 Project Structure

```
src/
├── client/
│   ├── components/          # React UI components (14 files)
│   ├── ClientLogger.lua     # Client logging system
│   ├── LogCommands.client.lua # Debug commands
│   └── init.client.lua      # Client entry point
├── server/
│   ├── modules/             # Core game modules (11 files)
│   ├── FarmingSystemNew.lua # Main game coordinator
│   ├── WorldBuilder.lua     # 3D world generation
│   └── init.server.lua      # Server entry point
└── shared/                  # (Currently unused)
```

## 🎯 Recent Improvements

This codebase has been significantly refactored for better maintainability:

- ✅ **Removed Legacy Code**: Eliminated ~1,800 lines of unused legacy systems
- ✅ **Performance Optimization**: Separated growth monitoring from UI updates
- ✅ **Debug Cleanup**: Replaced print statements with proper logging
- ✅ **Architecture Cleanup**: Consolidated to single, modular farming system
- ✅ **UI Improvements**: Fixed slot ordering and responsive design issues

## 🤝 Contributing

This project demonstrates modern Roblox development practices:
- **React-based UI**: Functional components with hooks
- **Modular Server Design**: Clean separation of concerns
- **Comprehensive Logging**: Multi-level debugging system
- **Type Safety**: Consistent parameter validation
- **Performance Focus**: Optimized loops and efficient data structures

## 📄 License

This project is for educational purposes and demonstrates advanced Roblox game development patterns using React and modular architecture.

---

*Built with ❤️ using React-lua, modern Lua patterns, and Roblox best practices*