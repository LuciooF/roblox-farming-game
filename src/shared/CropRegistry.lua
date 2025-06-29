-- Unified Crop Registry
-- Single source of truth for ALL crop data: visuals, economics, growth, weather, etc.

local CropRegistry = {}

-- Simple logging functions for CropRegistry
local function logWarn(...) warn("[WARN] CropRegistry:", ...) end

-- Helper function to ensure all crops have watering properties
local function ensureWateringProperties()
    for cropId, crop in pairs(CropRegistry.crops) do
        -- Add default watering properties if missing
        if not crop.waterCooldown then
            -- Scale based on rarity: common=20s, basic=25s, uncommon=30s, quality=35s, rare=40s, epic=50s
            local cooldownByRarity = {common=20, basic=25, uncommon=30, quality=35, rare=40, epic=50, premium=45, legendary=60}
            crop.waterCooldown = cooldownByRarity[crop.rarity] or 30
        end
        
        if not crop.maintenanceWaterInterval then
            -- Scale based on rarity: common=2h, basic=3h, uncommon=4h, quality=5h, rare=6h, epic=8h
            local intervalByRarity = {common=7200, basic=10800, uncommon=14400, quality=18000, rare=21600, epic=28800, premium=25200, legendary=36000}
            crop.maintenanceWaterInterval = intervalByRarity[crop.rarity] or 14400
        end
    end
end

-- All crop definitions with their actual asset IDs
CropRegistry.crops = {
    -- === STARTER CROPS (0 rebirths) - Basic farming ===
    wheat = {
        name = "Wheat", description = "Basic grain. Starter crop with low, steady production.", rarity = "common",
        seedCost = 25, basePrice = 50, growthTime = 45, waterNeeded = 1, harvestCooldown = 25, maxHarvestCycles = 2,
        productionRate = 32, -- crops per hour (18 * 1.75 = 31.5 → 32)
        waterCooldown = 15, maintenanceWaterInterval = 7200, -- 15s between waters, 2h maintenance
        emoji = "🌾", color = Color3.fromRGB(255, 215, 0), assetId = "rbxassetid://140570058506125",
        weatherMultipliers = {Sunny = 1.0, Cloudy = 1.0, Rainy = 1.2, Thunderstorm = 0.8},
        canGrowInSeason = {"Spring", "Summer", "Fall"}, soilTypes = {"any"}, unlockLevel = 0
    },
    carrot = {
        name = "Carrot", description = "Slightly better than wheat. Good for learning upgrade decisions.", rarity = "common",
        seedCost = 30, basePrice = 65, growthTime = 60, waterNeeded = 2, harvestCooldown = 30, maxHarvestCycles = 2,
        productionRate = 30, -- crops per hour (17 * 1.75 = 29.75 → 30)
        waterCooldown = 20, maintenanceWaterInterval = 7200, -- 20s between waters, 2h maintenance
        emoji = "🥕", color = Color3.fromRGB(255, 140, 0), assetId = "rbxassetid://114053695832489",
        weatherMultipliers = {Sunny = 1.1, Cloudy = 1.0, Rainy = 1.3, Thunderstorm = 0.8},
        canGrowInSeason = {"Spring", "Summer", "Fall"}, soilTypes = {"any"}, unlockLevel = 1
    },
    basil = {
        name = "Basil", description = "First 'premium' common crop. Noticeably better production with higher engagement.", rarity = "common",
        seedCost = 35, basePrice = 80, growthTime = 40, waterNeeded = 2, harvestCooldown = 20, maxHarvestCycles = 3,
        productionRate = 34, -- crops per hour (19 * 1.75 = 33.25 → 34)
        waterCooldown = 15, maintenanceWaterInterval = 5400, -- 15s between waters, 1.5h maintenance
        emoji = "🌿", color = Color3.fromRGB(0, 128, 0), assetId = "rbxassetid://72581622377784",
        weatherMultipliers = {Sunny = 1.2, Cloudy = 1.0, Rainy = 1.1, Thunderstorm = 0.8},
        canGrowInSeason = {"Spring", "Summer"}, soilTypes = {"any"}, unlockLevel = 2
    },
    
    -- === BASIC CROPS (1 rebirth) ===
    potato = {
        name = "Potato", description = "First real upgrade. Meaningful investment jump but much better production.", rarity = "basic",
        seedCost = 60, basePrice = 120, growthTime = 90, waterNeeded = 2, harvestCooldown = 35, maxHarvestCycles = 2,
        productionRate = 42, -- crops per hour (24 * 1.75 = 42)
        waterCooldown = 25, maintenanceWaterInterval = 12600, -- 25s between waters, 3.5h maintenance
        emoji = "🥔", color = Color3.fromRGB(139, 69, 19), assetId = "rbxassetid://120507660425268",
        weatherMultipliers = {Sunny = 0.9, Cloudy = 1.2, Rainy = 1.1, Thunderstorm = 1.0},
        canGrowInSeason = {"Spring", "Fall"}, soilTypes = {"any"}, unlockLevel = 2
    },
    onion = {
        name = "Onion", description = "Alternative basic strategy. Faster cycles than potato but similar production per hour.", rarity = "basic", 
        seedCost = 50, basePrice = 110, growthTime = 60, waterNeeded = 1, harvestCooldown = 25, maxHarvestCycles = 3,
        productionRate = 41, -- crops per hour (23 * 1.75 = 40.25 → 41)
        waterCooldown = 20, maintenanceWaterInterval = 10800, -- 20s between waters, 3h maintenance
        emoji = "🧅", color = Color3.fromRGB(255, 248, 220), assetId = "rbxassetid://93568818219118",
        weatherMultipliers = {Sunny = 1.0, Cloudy = 1.1, Rainy = 0.9, Thunderstorm = 0.8},
        canGrowInSeason = {"Spring", "Summer", "Fall"}, soilTypes = {"any"}, unlockLevel = 2
    },
    lettuce = {
        name = "Lettuce", description = "High-engagement basic crop. More cycles than potato/onion for higher total production.", rarity = "basic",
        seedCost = 45, basePrice = 100, growthTime = 45, waterNeeded = 2, harvestCooldown = 20, maxHarvestCycles = 4,
        productionRate = 44, -- crops per hour (25 * 1.75 = 43.75 → 44)
        waterCooldown = 22, maintenanceWaterInterval = 9000, -- 22s between waters, 2.5h maintenance
        emoji = "🥬", color = Color3.fromRGB(0, 255, 0), assetId = "rbxassetid://113533874261264",
        weatherMultipliers = {Sunny = 0.8, Cloudy = 1.2, Rainy = 1.3, Thunderstorm = 0.9},
        canGrowInSeason = {"Spring", "Fall"}, soilTypes = {"any"}, unlockLevel = 3
    },
    
    -- === UNCOMMON CROPS (3 rebirths) ===
    tomato = {
        name = "Tomato", description = "Big step up. Requires 3+ rebirths. Major investment for much better production.", rarity = "uncommon",
        seedCost = 80, basePrice = 180, growthTime = 75, waterNeeded = 2, harvestCooldown = 30, maxHarvestCycles = 2,
        productionRate = 51, -- crops per hour (29 * 1.75 = 50.75 → 51)
        waterCooldown = 30, maintenanceWaterInterval = 14400, -- 30s between waters, 4h maintenance
        emoji = "🍅", color = Color3.fromRGB(255, 69, 0), assetId = "rbxassetid://82679436859901",
        weatherMultipliers = {Sunny = 1.3, Cloudy = 0.8, Rainy = 1.0, Thunderstorm = 0.6},
        canGrowInSeason = {"Summer"}, soilTypes = {"rich", "any"}, unlockLevel = 5
    },
    strawberry = {
        name = "Strawberry", description = "High-engagement uncommon alternative. More cycles and water than tomato for higher total production.", rarity = "uncommon",
        seedCost = 70, basePrice = 160, growthTime = 60, waterNeeded = 3, harvestCooldown = 25, maxHarvestCycles = 3,
        productionRate = 56, -- crops per hour (32 * 1.75 = 56)
        waterCooldown = 25, maintenanceWaterInterval = 12600, -- 25s between waters, 3.5h maintenance
        emoji = "🍓", color = Color3.fromRGB(255, 20, 147), assetId = "rbxassetid://130478011574632",
        weatherMultipliers = {Sunny = 1.4, Cloudy = 0.9, Rainy = 1.2, Thunderstorm = 0.7},
        canGrowInSeason = {"Spring", "Summer"}, soilTypes = {"rich"}, unlockLevel = 8
    },
    
    -- === QUALITY CROPS (5 rebirths) ===
    corn = {
        name = "Corn", description = "Elite tier. Requires 5+ rebirths. Massive investment but great AFK production.", rarity = "quality",
        seedCost = 150, basePrice = 250, growthTime = 120, waterNeeded = 3, harvestCooldown = 40, maxHarvestCycles = 2,
        productionRate = 62, -- crops per hour (35 * 1.75 = 61.25 → 62)
        waterCooldown = 35, maintenanceWaterInterval = 18000, -- 35s between waters, 5h maintenance
        emoji = "🌽", color = Color3.fromRGB(255, 215, 0), assetId = "rbxassetid://109417883174426",
        weatherMultipliers = {Sunny = 1.5, Cloudy = 0.7, Rainy = 0.8, Thunderstorm = 0.5},
        canGrowInSeason = {"Summer"}, soilTypes = {"rich"}, unlockLevel = 15
    },
    broccoli = {
        name = "Broccoli", description = "Intensive quality alternative. Higher engagement than corn but better total production for active farmers.", rarity = "quality",
        seedCost = 120, basePrice = 220, growthTime = 80, waterNeeded = 4, harvestCooldown = 30, maxHarvestCycles = 3,
        productionRate = 67, -- crops per hour (38 * 1.75 = 66.5 → 67)
        waterCooldown = 30, maintenanceWaterInterval = 16200, -- 30s between waters, 4.5h maintenance
        emoji = "🥦", color = Color3.fromRGB(34, 139, 34), assetId = "rbxassetid://123124952300810",
        weatherMultipliers = {Sunny = 0.9, Cloudy = 1.3, Rainy = 1.4, Thunderstorm = 1.0},
        canGrowInSeason = {"Fall", "Winter"}, soilTypes = {"rich"}, unlockLevel = 18
    },
    
    -- === RARE CROPS (8 rebirths) ===
    eggplant = {
        name = "Eggplant", description = "End-game rare crop. Requires 8+ rebirths. Ultimate investment for ultimate AFK production.", rarity = "rare",
        seedCost = 250, basePrice = 350, growthTime = 180, waterNeeded = 4, harvestCooldown = 60, maxHarvestCycles = 2,
        productionRate = 69, -- crops per hour (39 * 1.75 = 68.25 → 69)
        waterCooldown = 40, maintenanceWaterInterval = 21600, -- 40s between waters, 6h maintenance
        emoji = "🍆", color = Color3.fromRGB(102, 51, 153), assetId = "rbxassetid://74822805417152",
        weatherMultipliers = {Sunny = 1.6, Cloudy = 0.6, Rainy = 0.9, Thunderstorm = 0.4},
        canGrowInSeason = {"Summer"}, soilTypes = {"rich"}, unlockLevel = 25
    },
    bell_pepper = {
        name = "Bell Pepper", description = "Rare colorful crunchy pepper", rarity = "rare",
        seedCost = 100, basePrice = 280, growthTime = 100, waterNeeded = 3, harvestCooldown = 30, maxHarvestCycles = 3,
        productionRate = 65, -- crops per hour (37 * 1.75 = 64.75 → 65)
        emoji = "🫑", color = Color3.fromRGB(255, 69, 0), assetId = "rbxassetid://111455597124644",
        weatherMultipliers = {Sunny = 1.5, Cloudy = 0.8, Rainy = 1.0, Thunderstorm = 0.6},
        canGrowInSeason = {"Summer"}, soilTypes = {"rich"}, unlockLevel = 22
    },
    apple = {
        name = "Apple", description = "Rare crisp red fruit", rarity = "rare",
        seedCost = 110, basePrice = 320, growthTime = 150, waterNeeded = 3, harvestCooldown = 40, maxHarvestCycles = 2,
        productionRate = 67, -- crops per hour (38 * 1.75 = 66.5 → 67)
        emoji = "🍎", color = Color3.fromRGB(255, 0, 0), assetId = "rbxassetid://81432100896234",
        weatherMultipliers = {Sunny = 1.3, Cloudy = 1.1, Rainy = 1.0, Thunderstorm = 0.8},
        canGrowInSeason = {"Fall"}, soilTypes = {"rich"}, unlockLevel = 28
    },
    
    -- === PREMIUM CROPS (12 rebirths) ===
    avocado = {
        name = "Avocado", description = "Premium creamy green superfruit", rarity = "premium",
        seedCost = 200, basePrice = 450, growthTime = 180, waterNeeded = 5, harvestCooldown = 50, maxHarvestCycles = 2,
        productionRate = 77, -- crops per hour (44 * 1.75 = 77)
        emoji = "🥑", color = Color3.fromRGB(128, 128, 0), assetId = "rbxassetid://136576807068056",
        weatherMultipliers = {Sunny = 1.8, Cloudy = 0.5, Rainy = 0.7, Thunderstorm = 0.3},
        canGrowInSeason = {"Summer"}, soilTypes = {"rich"}, unlockLevel = 35
    },
    mango = {
        name = "Mango", description = "Premium tropical golden fruit", rarity = "premium",
        seedCost = 180, basePrice = 420, growthTime = 160, waterNeeded = 4, harvestCooldown = 45, maxHarvestCycles = 2,
        productionRate = 76, -- crops per hour (43 * 1.75 = 75.25 → 76)
        emoji = "🥭", color = Color3.fromRGB(255, 165, 0), assetId = "rbxassetid://88817010585250",
        weatherMultipliers = {Sunny = 2.0, Cloudy = 0.4, Rainy = 0.6, Thunderstorm = 0.2},
        canGrowInSeason = {"Summer"}, soilTypes = {"rich"}, unlockLevel = 32
    },
    
    -- === ADDITIONAL CROPS ===
    -- Common tier
    acorn = {
        name = "Acorn", description = "Common nut from oak trees", rarity = "common",
        seedCost = 30, basePrice = 75, growthTime = 50, waterNeeded = 2, harvestCooldown = 20, maxHarvestCycles = 3,
        productionRate = 32, -- crops per hour (18 * 1.75 = 31.5 → 32)
        emoji = "🌰", color = Color3.fromRGB(139, 69, 19), assetId = "rbxassetid://95784772367264",
        weatherMultipliers = {Sunny = 1.0, Cloudy = 1.1, Rainy = 1.2, Thunderstorm = 0.9},
        canGrowInSeason = {"Fall"}, soilTypes = {"any"}, unlockLevel = 3
    },
    banana = {
        name = "Banana", description = "Common tropical yellow fruit", rarity = "common",
        seedCost = 45, basePrice = 90, growthTime = 70, waterNeeded = 3, harvestCooldown = 25, maxHarvestCycles = 3,
        productionRate = 35, -- crops per hour (20 * 1.75 = 35)
        emoji = "🍌", color = Color3.fromRGB(255, 255, 0), assetId = "rbxassetid://108309405334667",
        weatherMultipliers = {Sunny = 1.4, Cloudy = 0.8, Rainy = 0.9, Thunderstorm = 0.6},
        canGrowInSeason = {"Summer"}, soilTypes = {"rich"}, unlockLevel = 10
    },
    beet = {
        name = "Beet", description = "Basic deep red root vegetable", rarity = "basic",
        seedCost = 35, basePrice = 95, growthTime = 55, waterNeeded = 2, harvestCooldown = 18, maxHarvestCycles = 3,
        productionRate = 35, -- crops per hour (20 * 1.75 = 35)
        emoji = "🟣", color = Color3.fromRGB(128, 0, 128), assetId = "rbxassetid://81134380244930",
        weatherMultipliers = {Sunny = 0.9, Cloudy = 1.2, Rainy = 1.3, Thunderstorm = 1.0},
        canGrowInSeason = {"Fall", "Winter"}, soilTypes = {"any"}, unlockLevel = 6
    },
    
    -- More crops with proper progression...
    blueberry = {
        name = "Blueberry", description = "Quality small blue antioxidant berry", rarity = "quality",
        seedCost = 65, basePrice = 200, growthTime = 80, waterNeeded = 3, harvestCooldown = 22, maxHarvestCycles = 4,
        productionRate = 58, -- crops per hour (33 * 1.75 = 57.75 → 58)
        emoji = "🫐", color = Color3.fromRGB(0, 0, 255), assetId = "rbxassetid://134817217399309",
        weatherMultipliers = {Sunny = 1.2, Cloudy = 1.1, Rainy = 1.3, Thunderstorm = 0.8},
        canGrowInSeason = {"Summer"}, soilTypes = {"rich"}, unlockLevel = 16
    },
    cabbage = {
        name = "Cabbage", description = "Basic large leafy green vegetable", rarity = "basic",
        seedCost = 40, basePrice = 105, growthTime = 65, waterNeeded = 3, harvestCooldown = 20, maxHarvestCycles = 2,
        productionRate = 41, -- crops per hour (23 * 1.75 = 40.25 → 41)
        emoji = "🥬", color = Color3.fromRGB(0, 128, 0), assetId = "rbxassetid://99690187975513",
        weatherMultipliers = {Sunny = 0.8, Cloudy = 1.3, Rainy = 1.4, Thunderstorm = 1.1},
        canGrowInSeason = {"Fall", "Winter"}, soilTypes = {"any"}, unlockLevel = 7
    },
    cherry = {
        name = "Cherry", description = "Premium sweet red stone fruit", rarity = "premium",
        seedCost = 150, basePrice = 380, growthTime = 140, waterNeeded = 4, harvestCooldown = 35, maxHarvestCycles = 3,
        productionRate = 74, -- crops per hour (42 * 1.75 = 73.5 → 74)
        emoji = "🍒", color = Color3.fromRGB(220, 20, 60), assetId = "rbxassetid://112370010373286",
        weatherMultipliers = {Sunny = 1.5, Cloudy = 0.9, Rainy = 1.1, Thunderstorm = 0.7},
        canGrowInSeason = {"Spring", "Summer"}, soilTypes = {"rich"}, unlockLevel = 30
    },
    chilli_pepper = {
        name = "Chilli Pepper", description = "Rare spicy hot pepper", rarity = "rare",
        seedCost = 90, basePrice = 260, growthTime = 110, waterNeeded = 3, harvestCooldown = 28, maxHarvestCycles = 4,
        productionRate = 65, -- crops per hour (37 * 1.75 = 64.75 → 65)
        emoji = "🌶️", color = Color3.fromRGB(255, 0, 0), assetId = "rbxassetid://91457579328256",
        weatherMultipliers = {Sunny = 1.7, Cloudy = 0.6, Rainy = 0.8, Thunderstorm = 0.4},
        canGrowInSeason = {"Summer"}, soilTypes = {"rich"}, unlockLevel = 24
    },
    coconut = {
        name = "Coconut", description = "Premium tropical hard shell fruit", rarity = "premium",
        seedCost = 220, basePrice = 500, growthTime = 200, waterNeeded = 5, harvestCooldown = 60, maxHarvestCycles = 1,
        productionRate = 79, -- crops per hour (45 * 1.75 = 78.75 → 79)
        emoji = "🥥", color = Color3.fromRGB(139, 69, 19), assetId = "rbxassetid://108920797750746",
        weatherMultipliers = {Sunny = 2.2, Cloudy = 0.3, Rainy = 0.5, Thunderstorm = 0.2},
        canGrowInSeason = {"Summer"}, soilTypes = {"rich"}, unlockLevel = 38
    },
    dragonfruit = {
        name = "Dragonfruit", description = "Epic exotic pink tropical fruit", rarity = "epic",
        seedCost = 500, basePrice = 800, growthTime = 250, waterNeeded = 6, harvestCooldown = 80, maxHarvestCycles = 1,
        productionRate = 97, -- crops per hour (55 * 1.75 = 96.25 → 97)
        emoji = "🐉", color = Color3.fromRGB(255, 20, 147), assetId = "rbxassetid://108650683954995",
        weatherMultipliers = {Sunny = 2.5, Cloudy = 0.2, Rainy = 0.3, Thunderstorm = 0.1},
        canGrowInSeason = {"Summer"}, soilTypes = {"rich"}, unlockLevel = 50
    },
    
    -- === REMAINING CROPS ===
    cucumber = {
        name = "Cucumber", description = "Uncommon crisp refreshing vine vegetable", rarity = "uncommon",
        seedCost = 45, basePrice = 140, growthTime = 50, waterNeeded = 3, harvestCooldown = 18, maxHarvestCycles = 4,
        productionRate = 48, -- crops per hour (27 * 1.75 = 47.25 → 48)
        emoji = "🥒", color = Color3.fromRGB(0, 255, 127), assetId = "rbxassetid://71839373020814",
        weatherMultipliers = {Sunny = 1.2, Cloudy = 1.0, Rainy = 1.4, Thunderstorm = 0.8},
        canGrowInSeason = {"Summer"}, soilTypes = {"any"}, unlockLevel = 9
    },
    garlic = {
        name = "Garlic", description = "Basic pungent white bulb", rarity = "basic",
        seedCost = 25, basePrice = 85, growthTime = 45, waterNeeded = 1, harvestCooldown = 16, maxHarvestCycles = 4,
        productionRate = 34, -- crops per hour (19 * 1.75 = 33.25 → 34)
        emoji = "🧄", color = Color3.fromRGB(255, 255, 255), assetId = "rbxassetid://107780504354953",
        weatherMultipliers = {Sunny = 1.0, Cloudy = 1.1, Rainy = 0.9, Thunderstorm = 0.8},
        canGrowInSeason = {"Fall", "Winter"}, soilTypes = {"any"}, unlockLevel = 4
    },
    ginger = {
        name = "Ginger", description = "Quality spicy aromatic root", rarity = "quality",
        seedCost = 70, basePrice = 230, growthTime = 85, waterNeeded = 3, harvestCooldown = 26, maxHarvestCycles = 3,
        productionRate = 62, -- crops per hour (35 * 1.75 = 61.25 → 62)
        emoji = "🫚", color = Color3.fromRGB(255, 165, 0), assetId = "rbxassetid://82192283660274",
        weatherMultipliers = {Sunny = 1.3, Cloudy = 1.1, Rainy = 1.2, Thunderstorm = 0.9},
        canGrowInSeason = {"Summer", "Fall"}, soilTypes = {"rich"}, unlockLevel = 17
    },
    grapes = {
        name = "Grapes", description = "Premium sweet purple vine fruit", rarity = "premium",
        seedCost = 160, basePrice = 400, growthTime = 150, waterNeeded = 4, harvestCooldown = 42, maxHarvestCycles = 3,
        productionRate = 74, -- crops per hour (42 * 1.75 = 73.5 → 74)
        emoji = "🍇", color = Color3.fromRGB(128, 0, 128), assetId = "rbxassetid://130848305552214",
        weatherMultipliers = {Sunny = 1.6, Cloudy = 0.8, Rainy = 1.0, Thunderstorm = 0.6},
        canGrowInSeason = {"Summer", "Fall"}, soilTypes = {"rich"}, unlockLevel = 33
    },
    kiwi = {
        name = "Kiwi", description = "Rare fuzzy green tropical fruit", rarity = "rare",
        seedCost = 95, basePrice = 300, growthTime = 105, waterNeeded = 3, harvestCooldown = 32, maxHarvestCycles = 3,
        productionRate = 67, -- crops per hour (38 * 1.75 = 66.5 → 67)
        emoji = "🥝", color = Color3.fromRGB(0, 128, 0), assetId = "rbxassetid://127539635387675",
        weatherMultipliers = {Sunny = 1.4, Cloudy = 1.0, Rainy = 1.1, Thunderstorm = 0.7},
        canGrowInSeason = {"Spring", "Summer"}, soilTypes = {"rich"}, unlockLevel = 26
    },
    leek = {
        name = "Leek", description = "Basic long green onion family vegetable", rarity = "basic",
        seedCost = 30, basePrice = 90, growthTime = 50, waterNeeded = 2, harvestCooldown = 18, maxHarvestCycles = 3,
        productionRate = 34, -- crops per hour (19 * 1.75 = 33.25 → 34)
        emoji = "🥬", color = Color3.fromRGB(0, 128, 0), assetId = "rbxassetid://124453459445284",
        weatherMultipliers = {Sunny = 0.9, Cloudy = 1.2, Rainy = 1.3, Thunderstorm = 1.0},
        canGrowInSeason = {"Fall", "Winter"}, soilTypes = {"any"}, unlockLevel = 5
    },
    lime = {
        name = "Lime", description = "Uncommon sour green citrus fruit", rarity = "uncommon",
        seedCost = 55, basePrice = 150, growthTime = 60, waterNeeded = 3, harvestCooldown = 22, maxHarvestCycles = 4,
        productionRate = 48, -- crops per hour (27 * 1.75 = 47.25 → 48)
        emoji = "🟢", color = Color3.fromRGB(0, 255, 0), assetId = "rbxassetid://85061352037649",
        weatherMultipliers = {Sunny = 1.5, Cloudy = 0.7, Rainy = 0.8, Thunderstorm = 0.5},
        canGrowInSeason = {"Summer"}, soilTypes = {"rich"}, unlockLevel = 11
    },
    lemon = {
        name = "Lemon", description = "Uncommon sour yellow citrus fruit", rarity = "uncommon",
        seedCost = 50, basePrice = 145, growthTime = 55, waterNeeded = 3, harvestCooldown = 20, maxHarvestCycles = 4,
        productionRate = 48, -- crops per hour (27 * 1.75 = 47.25 → 48)
        emoji = "🍋", color = Color3.fromRGB(255, 255, 0), assetId = "rbxassetid://120961167936429",
        weatherMultipliers = {Sunny = 1.5, Cloudy = 0.7, Rainy = 0.8, Thunderstorm = 0.5},
        canGrowInSeason = {"Summer"}, soilTypes = {"rich"}, unlockLevel = 12
    },
    mushroom = {
        name = "Mushroom", description = "Quality earthy fungi", rarity = "quality",
        seedCost = 85, basePrice = 240, growthTime = 95, waterNeeded = 4, harvestCooldown = 28, maxHarvestCycles = 3,
        productionRate = 62, -- crops per hour (35 * 1.75 = 61.25 → 62)
        emoji = "🍄", color = Color3.fromRGB(139, 69, 19), assetId = "rbxassetid://92410776982531",
        weatherMultipliers = {Sunny = 0.6, Cloudy = 1.4, Rainy = 1.6, Thunderstorm = 1.2},
        canGrowInSeason = {"Fall", "Winter"}, soilTypes = {"rich"}, unlockLevel = 19
    },
    olive = {
        name = "Olive", description = "Premium Mediterranean tree fruit", rarity = "premium",
        seedCost = 170, basePrice = 430, growthTime = 170, waterNeeded = 4, harvestCooldown = 48, maxHarvestCycles = 2,
        productionRate = 76, -- crops per hour (43 * 1.75 = 75.25 → 76)
        emoji = "🫒", color = Color3.fromRGB(128, 128, 0), assetId = "rbxassetid://113045433386174",
        weatherMultipliers = {Sunny = 1.8, Cloudy = 0.6, Rainy = 0.7, Thunderstorm = 0.4},
        canGrowInSeason = {"Summer", "Fall"}, soilTypes = {"rich"}, unlockLevel = 34
    },
    orange = {
        name = "Orange", description = "Quality sweet citrus fruit", rarity = "quality",
        seedCost = 60, basePrice = 190, growthTime = 75, waterNeeded = 3, harvestCooldown = 24, maxHarvestCycles = 4,
        productionRate = 56, -- crops per hour (32 * 1.75 = 56)
        emoji = "🍊", color = Color3.fromRGB(255, 165, 0), assetId = "rbxassetid://84221612085092",
        weatherMultipliers = {Sunny = 1.4, Cloudy = 0.8, Rainy = 0.9, Thunderstorm = 0.6},
        canGrowInSeason = {"Summer", "Fall"}, soilTypes = {"rich"}, unlockLevel = 14
    },
    pea_pod = {
        name = "Pea Pod", description = "Basic green pod vegetable", rarity = "basic",
        seedCost = 22, basePrice = 70, growthTime = 35, waterNeeded = 2, harvestCooldown = 14, maxHarvestCycles = 5,
        productionRate = 32, -- crops per hour (18 * 1.75 = 31.5 → 32)
        emoji = "🟢", color = Color3.fromRGB(0, 128, 0), assetId = "rbxassetid://85646341943675",
        weatherMultipliers = {Sunny = 1.0, Cloudy = 1.2, Rainy = 1.3, Thunderstorm = 0.9},
        canGrowInSeason = {"Spring", "Summer"}, soilTypes = {"any"}, unlockLevel = 4
    },
    peach = {
        name = "Peach", description = "Premium sweet fuzzy stone fruit", rarity = "premium",
        seedCost = 140, basePrice = 370, growthTime = 130, waterNeeded = 4, harvestCooldown = 38, maxHarvestCycles = 3,
        productionRate = 74, -- crops per hour (42 * 1.75 = 73.5 → 74)
        emoji = "🍑", color = Color3.fromRGB(255, 218, 185), assetId = "rbxassetid://120174829152445",
        weatherMultipliers = {Sunny = 1.6, Cloudy = 0.8, Rainy = 1.0, Thunderstorm = 0.6},
        canGrowInSeason = {"Summer"}, soilTypes = {"rich"}, unlockLevel = 31
    },
    pear = {
        name = "Pear", description = "Quality sweet green fruit", rarity = "quality",
        seedCost = 55, basePrice = 185, growthTime = 70, waterNeeded = 3, harvestCooldown = 22, maxHarvestCycles = 3,
        productionRate = 56, -- crops per hour (32 * 1.75 = 56)
        emoji = "🍐", color = Color3.fromRGB(144, 238, 144), assetId = "rbxassetid://88540568147794",
        weatherMultipliers = {Sunny = 1.3, Cloudy = 1.0, Rainy = 1.1, Thunderstorm = 0.8},
        canGrowInSeason = {"Fall"}, soilTypes = {"rich"}, unlockLevel = 13
    },
    pumpkin = {
        name = "Pumpkin", description = "Quality large orange seasonal fruit", rarity = "quality",
        seedCost = 75, basePrice = 210, growthTime = 100, waterNeeded = 4, harvestCooldown = 35, maxHarvestCycles = 1,
        productionRate = 58, -- crops per hour (33 * 1.75 = 57.75 → 58)
        emoji = "🎃", color = Color3.fromRGB(255, 140, 0), assetId = "rbxassetid://112579140905383",
        weatherMultipliers = {Sunny = 1.2, Cloudy = 1.1, Rainy = 1.0, Thunderstorm = 0.8},
        canGrowInSeason = {"Fall"}, soilTypes = {"rich"}, unlockLevel = 20
    },
    radish = {
        name = "Radish", description = "Basic small spicy root vegetable", rarity = "basic",
        seedCost = 18, basePrice = 60, growthTime = 30, waterNeeded = 2, harvestCooldown = 12, maxHarvestCycles = 4,
        productionRate = 30, -- crops per hour (17 * 1.75 = 29.75 → 30)
        emoji = "🔴", color = Color3.fromRGB(255, 0, 0), assetId = "rbxassetid://89959180913127",
        weatherMultipliers = {Sunny = 1.1, Cloudy = 1.1, Rainy = 1.2, Thunderstorm = 0.9},
        canGrowInSeason = {"Spring", "Fall"}, soilTypes = {"any"}, unlockLevel = 3
    },
    raspberry = {
        name = "Raspberry", description = "Rare small red tart berry", rarity = "rare",
        seedCost = 85, basePrice = 270, growthTime = 90, waterNeeded = 3, harvestCooldown = 28, maxHarvestCycles = 5,
        productionRate = 65, -- crops per hour (37 * 1.75 = 64.75 → 65)
        emoji = "🔴", color = Color3.fromRGB(220, 20, 60), assetId = "rbxassetid://95869445700170",
        weatherMultipliers = {Sunny = 1.3, Cloudy = 1.0, Rainy = 1.2, Thunderstorm = 0.8},
        canGrowInSeason = {"Summer"}, soilTypes = {"rich"}, unlockLevel = 23
    },
    sweet_potato = {
        name = "Sweet Potato", description = "Uncommon orange root vegetable", rarity = "uncommon",
        seedCost = 42, basePrice = 130, growthTime = 65, waterNeeded = 2, harvestCooldown = 22, maxHarvestCycles = 3,
        productionRate = 44, -- crops per hour (25 * 1.75 = 43.75 → 44)
        emoji = "🍠", color = Color3.fromRGB(255, 140, 0), assetId = "rbxassetid://138434765079329",
        weatherMultipliers = {Sunny = 1.2, Cloudy = 1.0, Rainy = 1.1, Thunderstorm = 0.9},
        canGrowInSeason = {"Fall"}, soilTypes = {"any"}, unlockLevel = 10
    },
    turnip = {
        name = "Turnip", description = "Basic white root vegetable", rarity = "basic",
        seedCost = 28, basePrice = 80, growthTime = 40, waterNeeded = 2, harvestCooldown = 16, maxHarvestCycles = 3,
        productionRate = 32, -- crops per hour (18 * 1.75 = 31.5 → 32)
        emoji = "🤍", color = Color3.fromRGB(255, 255, 255), assetId = "rbxassetid://72606027292079",
        weatherMultipliers = {Sunny = 0.9, Cloudy = 1.2, Rainy = 1.3, Thunderstorm = 1.0},
        canGrowInSeason = {"Fall", "Winter"}, soilTypes = {"any"}, unlockLevel = 6
    },
    watermelon = {
        name = "Watermelon", description = "Rare large juicy summer fruit", rarity = "rare",
        seedCost = 130, basePrice = 340, growthTime = 140, waterNeeded = 5, harvestCooldown = 45, maxHarvestCycles = 1,
        productionRate = 67, -- crops per hour (38 * 1.75 = 66.5 → 67)
        emoji = "🍉", color = Color3.fromRGB(255, 20, 147), assetId = "rbxassetid://110550262608282",
        weatherMultipliers = {Sunny = 1.8, Cloudy = 0.5, Rainy = 0.7, Thunderstorm = 0.3},
        canGrowInSeason = {"Summer"}, soilTypes = {"rich"}, unlockLevel = 27
    },
    zucchini = {
        name = "Zucchini", description = "Uncommon green summer squash", rarity = "uncommon",
        seedCost = 38, basePrice = 125, growthTime = 48, waterNeeded = 3, harvestCooldown = 18, maxHarvestCycles = 4,
        productionRate = 44, -- crops per hour (25 * 1.75 = 43.75 → 44)
        emoji = "🥒", color = Color3.fromRGB(0, 128, 0), assetId = "rbxassetid://128287838345862",
        weatherMultipliers = {Sunny = 1.3, Cloudy = 0.9, Rainy = 1.1, Thunderstorm = 0.7},
        canGrowInSeason = {"Summer"}, soilTypes = {"any"}, unlockLevel = 9
    }
}

-- Rarity definitions
CropRegistry.rarities = {
    common = {
        color = Color3.fromRGB(169, 169, 169), -- Gray
        sortOrder = 1,
        description = "Easy to grow, available from the start"
    },
    basic = {
        color = Color3.fromRGB(255, 255, 255), -- White
        sortOrder = 2,
        description = "Simple crops that require some experience"
    },
    uncommon = {
        color = Color3.fromRGB(0, 255, 0), -- Green
        sortOrder = 3,
        description = "Better crops with improved yields"
    },
    quality = {
        color = Color3.fromRGB(0, 191, 255), -- Deep Sky Blue
        sortOrder = 4,
        description = "High-quality crops with great returns"
    },
    rare = {
        color = Color3.fromRGB(128, 0, 128), -- Purple
        sortOrder = 5,
        description = "Rare crops that require skill to grow"
    },
    premium = {
        color = Color3.fromRGB(255, 215, 0), -- Gold
        sortOrder = 6,
        description = "Premium crops with exceptional value"
    },
    epic = {
        color = Color3.fromRGB(255, 140, 0), -- Dark Orange
        sortOrder = 7,
        description = "Epic crops for master farmers"
    },
    legendary = {
        color = Color3.fromRGB(255, 69, 0), -- Red Orange
        sortOrder = 8,
        description = "Legendary crops of immense value"
    }
}

-- Initialize watering properties for all crops
ensureWateringProperties()

-- Helper functions
function CropRegistry.getCrop(cropType)
    return CropRegistry.crops[cropType]
end

-- Get watering cooldown for a specific crop
function CropRegistry.getWaterCooldown(cropType)
    local crop = CropRegistry.crops[cropType]
    return crop and crop.waterCooldown or 30 -- fallback to 30s
end

-- Get maintenance watering interval for a specific crop
function CropRegistry.getMaintenanceWaterInterval(cropType)
    local crop = CropRegistry.crops[cropType]
    return crop and crop.maintenanceWaterInterval or 14400 -- fallback to 4h
end

function CropRegistry.getAllCrops()
    return CropRegistry.crops
end

function CropRegistry.getCropsByRarity(rarity)
    local result = {}
    for cropType, cropData in pairs(CropRegistry.crops) do
        if cropData.rarity == rarity then
            result[cropType] = cropData
        end
    end
    return result
end

function CropRegistry.getCropsList()
    local list = {}
    for cropType, cropData in pairs(CropRegistry.crops) do
        table.insert(list, {
            type = cropType,
            data = cropData
        })
    end
    
    -- Sort by rarity, then by unlock level
    table.sort(list, function(a, b)
        local rarityOrderA = CropRegistry.rarities[a.data.rarity].sortOrder
        local rarityOrderB = CropRegistry.rarities[b.data.rarity].sortOrder
        
        if rarityOrderA == rarityOrderB then
            return a.data.unlockLevel < b.data.unlockLevel
        end
        return rarityOrderA < rarityOrderB
    end)
    
    return list
end

function CropRegistry.getRarityInfo(rarity)
    return CropRegistry.rarities[rarity]
end

return CropRegistry