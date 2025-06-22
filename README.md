# Roblox Farming Game

A farming simulation game built with modern Roblox development tools and practices.

## Features

- 🌱 **Plant & Harvest System**: Grow different crops with realistic growth times
- 💧 **Watering Mechanics**: Care for your plants to ensure proper growth
- 🏪 **Shop System**: Buy seeds and equipment to expand your farming operation
- 🌤️ **Climate System**: Dynamic weather and environmental factors affect crop growth
- 📊 **Player Progression**: Level up and earn experience through farming activities
- 💰 **Economy**: Sell crops for profit and reinvest in better equipment
- 🎮 **Modern UI**: React-based interface with responsive design

## Technology Stack

- **Rojo**: Project management and code synchronization
- **Wally**: Package management
- **React-lua**: Modern UI framework for Roblox
- **Rodux**: State management (Redux for Lua)
- **Promise**: Asynchronous operations

## Setup Instructions

### Prerequisites

1. [Roblox Studio](https://create.roblox.com/docs/studio/setting-up-roblox-studio)
2. [Rojo](https://rojo.space/docs/v7/getting-started/installation/)
3. [Wally](https://wally.run/install)

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/LuciooF/roblox-farming-game.git
   cd roblox-farming-game
   ```

2. **Install dependencies**:
   ```bash
   wally install
   ```

3. **Start Rojo server**:
   ```bash
   rojo serve
   ```

4. **Connect to Roblox Studio**:
   - Open Roblox Studio
   - Install the [Rojo plugin](https://create.roblox.com/marketplace/asset/13916111004/Rojo)
   - Click "Connect" in the Rojo plugin
   - Use default address: `localhost:34872`

5. **Test the game**:
   - Press F5 or click "Play" in Studio
   - The farming game UI should appear

## Game Mechanics

### Basic Gameplay

1. **Planting**: Click on empty farm plots to plant seeds (requires seeds in inventory)
2. **Watering**: Click on planted seeds to water them (required for growth)
3. **Harvesting**: Once plants are fully grown, click to harvest crops
4. **Selling**: Use the shop to sell harvested crops for money
5. **Buying**: Purchase new seeds and equipment from the shop

### Crop Types

| Crop | Growth Time | Base Price | Starting Seeds |
|------|-------------|------------|----------------|
| Wheat | 20 seconds | $3 | 2 |
| Tomato | 30 seconds | $5 | 5 |
| Carrot | 45 seconds | $8 | 3 |
| Potato | 60 seconds | $12 | 0 |

### Equipment & Upgrades

- **Watering Can**: Basic tool (included by default)
- **Air Purifier**: Improves air quality for better crop yields ($500)
- **Advanced Soil**: Reduces growth time by 20% ($200)
- **Greenhouse**: Protects crops from weather effects ($1000)

### Climate System

- **Temperature**: Affects growth speed (optimal: 60-80°F)
- **Humidity**: Influences crop health (optimal: 50-70%)
- **Air Quality**: Impacts yield quantity and quality

## Development

### Project Structure

```
src/
├── server/              # Server-side scripts
│   ├── init.server.lua     # Main server initialization
│   ├── FarmingSystem.lua   # Core farming mechanics
│   └── PlayerDataManager.lua # Player data handling
├── client/              # Client-side scripts
│   └── init.client.lua     # Main client initialization
├── shared/              # Shared modules
│   └── GameReducer.lua     # Rodux state management
└── components/          # React-lua UI components
    ├── App.lua             # Main app component
    ├── FarmUI.lua          # Farm plot interface
    ├── PlayerStats.lua     # Player info display
    └── Shop.lua            # Shop interface

default.project.json     # Rojo project configuration
wally.toml              # Package dependencies
```

### State Management

The game uses Rodux for centralized state management with the following structure:

```lua
{
    player = {
        money = 100,
        level = 1,
        experience = 0
    },
    farm = {
        plots = {},
        equipment = {},
        climate = {}
    },
    inventory = {
        seeds = {},
        crops = {},
        tools = {}
    },
    shop = {
        seeds = {},
        equipment = {}
    }
}
```

### Adding New Features

1. **New Crop Types**: Add to `plantGrowthTimes` and `cropPrices` in `FarmingSystem.lua`
2. **New Equipment**: Add to shop data in `GameReducer.lua` and implement effects in `FarmingSystem.lua`
3. **UI Components**: Create new React-lua components in `src/components/`

## Testing

The project includes comprehensive unit tests using TestEZ.

### Running Tests

1. **Install test dependencies**:
   ```bash
   wally install
   ```

2. **Run tests in Roblox Studio**:
   - Sync the project with `rojo serve`
   - Tests will run automatically when the server starts
   - Or run manually: `_G.runFarmingGameTests()`

3. **Test Coverage**:
   - **GameReducer**: State management and action handling
   - **FarmingSystem**: Plant growth, climate, and harvesting logic
   - **PlayerDataManager**: Data persistence and inventory management

### Test Structure

```
tests/
├── GameReducer.spec.lua      # Rodux state management tests
├── FarmingSystem.spec.lua    # Server-side farming logic tests
├── PlayerDataManager.spec.lua # Data management tests
├── init.server.lua          # Automatic test runner
└── run_tests.lua            # Manual test runner
```

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes
4. **Write tests** for new functionality
5. **Run tests** to ensure nothing breaks: `_G.runFarmingGameTests()`
6. Test thoroughly in Roblox Studio
7. Commit your changes: `git commit -m "Add feature description"`
8. Push to your branch: `git push origin feature-name`
9. Create a Pull Request

## License

This project is open source and available under the [MIT License](LICENSE).

## Support

If you encounter any issues or have questions:

1. Check the [Issues](https://github.com/LuciooF/roblox-farming-game/issues) page
2. Create a new issue with detailed information
3. Include your Roblox Studio output logs if relevant

## Roadmap

- [ ] Multiplayer farming plots
- [ ] Seasonal events and crops
- [ ] Advanced greenhouse management
- [ ] Trading system between players
- [ ] Achievement system
- [ ] Mobile UI optimization
- [ ] Sound effects and music