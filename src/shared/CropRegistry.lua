-- Unified Crop Registry
-- Single source of truth for ALL crop data: visuals, economics, growth, weather, etc.

local CropRegistry = {}

-- Import assets for crop icons
local assets = require(script.Parent.assets)

-- Get appropriate logger based on environment
local log
local RunService = game:GetService("RunService")
if RunService:IsServer() then
    local Logger = require(game:GetService("ServerScriptService").Server.modules.Logger)
    log = Logger.getModuleLogger("CropRegistry")
else
    local ClientLogger = require(game:GetService("StarterPlayer").StarterPlayerScripts.Client.ClientLogger)
    log = ClientLogger.getModuleLogger("CropRegistry")
end

-- Helper function to get asset ID for a crop
local function getAssetId(cropName)
    -- Handle special cases for multi-word crop names and naming differences
    local assetName = cropName
    if cropName == "Bell Pepper" then
        assetName = "Bell Pepper"
    elseif cropName == "Lettuce Leaf" then
        assetName = "Lettuce Leaf" 
    elseif cropName == "Chilli Pepper" then
        assetName = "Chilli Pepper"
    elseif cropName == "Sweet Potato" then
        assetName = "Sweet Potato"
    elseif cropName == "Pea Pod" then
        assetName = "Pea Pod"
    elseif cropName == "Garlic" then
        assetName = "Garlic" -- Check if it should be different
    end
    
    -- Try multiple naming patterns
    local attempts = {
        "vector-food-pack/" .. assetName .. "/" .. assetName:lower():gsub(" ", "-") .. "-64.png",
        "vector-food-pack/" .. assetName .. "/" .. assetName:lower() .. "-64.png",
        "vector-food-pack/" .. assetName .. "/" .. assetName:lower():gsub(" ", "") .. "-64.png"
    }
    
    for _, attempt in ipairs(attempts) do
        if assets[attempt] then
            return assets[attempt]
        end
    end
    
    return "rbxasset://textures/face.png" -- fallback
end

-- Crop definitions with ALL properties in one place
local CROPS = {
    -- === COMMON CROPS (Unlock Level 1-5) ===
    wheat = {
        name = "Wheat", description = "Common fast-growing grain that feeds the world", rarity = "common",
        seedCost = 10, basePrice = 5, growthTime = 15, waterNeeded = 1, harvestCooldown = 10, maxHarvestCycles = 5,
        emoji = "🌾", color = Color3.fromRGB(255, 255, 100), assetId = getAssetId("Wheat"),
        weatherMultipliers = {Sunny = 1.0, Cloudy = 0.9, Rainy = 1.2, Thunderstorm = 0.7},
        canGrowInSeason = {"Spring", "Summer", "Fall"}, soilTypes = {"any"}, unlockLevel = 1
    },
    carrot = {
        name = "Carrot", description = "Common orange root vegetable packed with vitamins", rarity = "common",
        seedCost = 25, basePrice = 15, growthTime = 30, waterNeeded = 2, harvestCooldown = 15, maxHarvestCycles = 3,
        emoji = "🥕", color = Color3.fromRGB(255, 140, 0), assetId = getAssetId("Carrot"),
        weatherMultipliers = {Sunny = 1.1, Cloudy = 1.0, Rainy = 1.3, Thunderstorm = 0.8},
        canGrowInSeason = {"Spring", "Summer", "Fall"}, soilTypes = {"any"}, unlockLevel = 1
    },
    potato = {
        name = "Potato", description = "Common hearty root vegetable, perfect for any meal", rarity = "common",
        seedCost = 35, basePrice = 25, growthTime = 60, waterNeeded = 2, harvestCooldown = 20, maxHarvestCycles = 3,
        emoji = "🥔", color = Color3.fromRGB(139, 69, 19), assetId = getAssetId("Potato"),
        weatherMultipliers = {Sunny = 0.9, Cloudy = 1.2, Rainy = 1.1, Thunderstorm = 1.0},
        canGrowInSeason = {"Spring", "Fall"}, soilTypes = {"any"}, unlockLevel = 2
    },
    onion = {
        name = "Onion", description = "Common pungent bulb that adds flavor to everything", rarity = "common",
        seedCost = 20, basePrice = 12, growthTime = 40, waterNeeded = 1, harvestCooldown = 15, maxHarvestCycles = 4,
        emoji = "🧅", color = Color3.fromRGB(255, 248, 220), assetId = getAssetId("Onion"),
        weatherMultipliers = {Sunny = 1.0, Cloudy = 1.1, Rainy = 0.9, Thunderstorm = 0.8},
        canGrowInSeason = {"Spring", "Summer", "Fall"}, soilTypes = {"any"}, unlockLevel = 2
    },
    lettuce = {
        name = "Lettuce", description = "Common leafy green perfect for salads", rarity = "common",
        seedCost = 15, basePrice = 8, growthTime = 25, waterNeeded = 2, harvestCooldown = 12, maxHarvestCycles = 4,
        emoji = "🥬", color = Color3.fromRGB(0, 255, 0), assetId = getAssetId("Lettuce Leaf"),
        weatherMultipliers = {Sunny = 0.8, Cloudy = 1.2, Rainy = 1.3, Thunderstorm = 0.9},
        canGrowInSeason = {"Spring", "Fall"}, soilTypes = {"any"}, unlockLevel = 3
    },
    
    -- === UNCOMMON CROPS (Unlock Level 5-15) ===
    tomato = {
        name = "Tomato", description = "Uncommon juicy fruit that's technically a vegetable", rarity = "uncommon",
        seedCost = 50, basePrice = 35, growthTime = 45, waterNeeded = 2, harvestCooldown = 20, maxHarvestCycles = 4,
        emoji = "🍅", color = Color3.fromRGB(255, 69, 0), assetId = getAssetId("Tomato"),
        weatherMultipliers = {Sunny = 1.3, Cloudy = 0.8, Rainy = 1.0, Thunderstorm = 0.6},
        canGrowInSeason = {"Summer"}, soilTypes = {"rich", "any"}, unlockLevel = 5
    },
    corn = {
        name = "Corn", description = "Uncommon golden grain that grows tall and proud", rarity = "uncommon",
        seedCost = 120, basePrice = 80, growthTime = 90, waterNeeded = 3, harvestCooldown = 30, maxHarvestCycles = 2,
        emoji = "🌽", color = Color3.fromRGB(255, 215, 0), assetId = getAssetId("Corn"),
        weatherMultipliers = {Sunny = 1.4, Cloudy = 0.7, Rainy = 1.1, Thunderstorm = 0.5},
        canGrowInSeason = {"Summer"}, soilTypes = {"rich"}, unlockLevel = 6
    },
    broccoli = {
        name = "Broccoli", description = "Uncommon green superfood packed with nutrients", rarity = "uncommon",
        seedCost = 60, basePrice = 45, growthTime = 55, waterNeeded = 3, harvestCooldown = 25, maxHarvestCycles = 3,
        emoji = "🥦", color = Color3.fromRGB(34, 139, 34), assetId = getAssetId("Broccoli"),
        weatherMultipliers = {Sunny = 0.9, Cloudy = 1.3, Rainy = 1.2, Thunderstorm = 0.7},
        canGrowInSeason = {"Spring", "Fall"}, soilTypes = {"rich"}, unlockLevel = 7
    },
    cucumber = {
        name = "Cucumber", description = "Uncommon crisp and refreshing vine vegetable", rarity = "uncommon",
        seedCost = 45, basePrice = 30, growthTime = 50, waterNeeded = 3, harvestCooldown = 18, maxHarvestCycles = 4,
        emoji = "🥒", color = Color3.fromRGB(0, 255, 127), assetId = getAssetId("Cucumber"),
        weatherMultipliers = {Sunny = 1.2, Cloudy = 1.0, Rainy = 1.4, Thunderstorm = 0.8},
        canGrowInSeason = {"Summer"}, soilTypes = {"any"}, unlockLevel = 8
    },
    cabbage = {
        name = "Cabbage", description = "Uncommon hearty leafy vegetable perfect for soups", rarity = "uncommon",
        seedCost = 65, basePrice = 40, growthTime = 70, waterNeeded = 2, harvestCooldown = 28, maxHarvestCycles = 2,
        emoji = "🥬", color = Color3.fromRGB(144, 238, 144), assetId = getAssetId("Cabbage"),
        weatherMultipliers = {Sunny = 0.8, Cloudy = 1.3, Rainy = 1.1, Thunderstorm = 1.0},
        canGrowInSeason = {"Fall", "Winter"}, soilTypes = {"any"}, unlockLevel = 9
    },
    
    -- === RARE CROPS (Unlock Level 15-25) ===
    eggplant = {
        name = "Eggplant", description = "Rare purple beauty that's surprisingly versatile", rarity = "rare",
        seedCost = 150, basePrice = 100, growthTime = 80, waterNeeded = 3, harvestCooldown = 35, maxHarvestCycles = 3,
        emoji = "🍆", color = Color3.fromRGB(75, 0, 130), assetId = getAssetId("Eggplant"),
        weatherMultipliers = {Sunny = 1.5, Cloudy = 0.8, Rainy = 0.9, Thunderstorm = 0.6},
        canGrowInSeason = {"Summer"}, soilTypes = {"rich"}, unlockLevel = 15
    },
    bell_pepper = {
        name = "Bell Pepper", description = "Rare colorful pepper with sweet crunch", rarity = "rare",
        seedCost = 180, basePrice = 120, growthTime = 85, waterNeeded = 3, harvestCooldown = 40, maxHarvestCycles = 3,
        emoji = "🫑", color = Color3.fromRGB(255, 165, 0), assetId = getAssetId("Bell Pepper"),
        weatherMultipliers = {Sunny = 1.6, Cloudy = 0.7, Rainy = 0.8, Thunderstorm = 0.5},
        canGrowInSeason = {"Summer"}, soilTypes = {"rich"}, unlockLevel = 18
    },
    pumpkin = {
        name = "Pumpkin", description = "Rare orange giant perfect for autumn festivities", rarity = "rare",
        seedCost = 200, basePrice = 150, growthTime = 120, waterNeeded = 4, harvestCooldown = 50, maxHarvestCycles = 1,
        emoji = "🎃", color = Color3.fromRGB(255, 117, 24), assetId = getAssetId("Pumpkin"),
        weatherMultipliers = {Sunny = 1.3, Cloudy = 1.0, Rainy = 1.1, Thunderstorm = 0.7},
        canGrowInSeason = {"Fall"}, soilTypes = {"rich"}, unlockLevel = 20
    },
    
    -- === FRUITS (Mixed Rarities) ===
    strawberry = {
        name = "Strawberry", description = "Uncommon sweet red berry loved by all", rarity = "uncommon",
        seedCost = 80, basePrice = 60, growthTime = 65, waterNeeded = 3, harvestCooldown = 25, maxHarvestCycles = 4,
        emoji = "🍓", color = Color3.fromRGB(255, 0, 127), assetId = getAssetId("Strawberry"),
        weatherMultipliers = {Sunny = 1.4, Cloudy = 1.0, Rainy = 1.2, Thunderstorm = 0.8},
        canGrowInSeason = {"Spring", "Summer"}, soilTypes = {"rich"}, unlockLevel = 10
    },
    apple = {
        name = "Apple", description = "Rare crisp fruit that keeps the doctor away", rarity = "rare",
        seedCost = 250, basePrice = 180, growthTime = 150, waterNeeded = 3, harvestCooldown = 60, maxHarvestCycles = 5,
        emoji = "🍎", color = Color3.fromRGB(255, 0, 0), assetId = getAssetId("Apple"),
        weatherMultipliers = {Sunny = 1.2, Cloudy = 1.1, Rainy = 1.0, Thunderstorm = 0.8},
        canGrowInSeason = {"Fall"}, soilTypes = {"rich"}, unlockLevel = 22
    },
    orange = {
        name = "Orange", description = "Rare citrus fruit bursting with vitamin C", rarity = "rare",
        seedCost = 300, basePrice = 200, growthTime = 140, waterNeeded = 4, harvestCooldown = 55, maxHarvestCycles = 4,
        emoji = "🍊", color = Color3.fromRGB(255, 165, 0), assetId = getAssetId("Orange"),
        weatherMultipliers = {Sunny = 1.6, Cloudy = 0.8, Rainy = 0.9, Thunderstorm = 0.6},
        canGrowInSeason = {"Summer", "Fall"}, soilTypes = {"rich"}, unlockLevel = 25
    },
    
    -- === EPIC CROPS (Unlock Level 30+) ===
    avocado = {
        name = "Avocado", description = "Epic creamy superfruit loved by millennials", rarity = "epic",
        seedCost = 500, basePrice = 350, growthTime = 180, waterNeeded = 4, harvestCooldown = 70, maxHarvestCycles = 3,
        emoji = "🥑", color = Color3.fromRGB(107, 142, 35), assetId = getAssetId("Avocado"),
        weatherMultipliers = {Sunny = 1.5, Cloudy = 1.0, Rainy = 1.1, Thunderstorm = 0.7},
        canGrowInSeason = {"Summer"}, soilTypes = {"rich"}, unlockLevel = 30
    },
    dragonfruit = {
        name = "Dragonfruit", description = "Epic exotic fruit with vibrant pink skin", rarity = "epic",
        seedCost = 800, basePrice = 500, growthTime = 200, waterNeeded = 5, harvestCooldown = 80, maxHarvestCycles = 2,
        emoji = "🐉", color = Color3.fromRGB(255, 20, 147), assetId = getAssetId("Dragonfruit"),
        weatherMultipliers = {Sunny = 1.8, Cloudy = 0.6, Rainy = 0.7, Thunderstorm = 0.5},
        canGrowInSeason = {"Summer"}, soilTypes = {"rich"}, unlockLevel = 35
    },
    
    -- === MORE FRUITS ===
    banana = {
        name = "Banana", description = "Uncommon tropical fruit rich in potassium", rarity = "uncommon",
        seedCost = 90, basePrice = 65, growthTime = 75, waterNeeded = 3, harvestCooldown = 30, maxHarvestCycles = 4,
        emoji = "🍌", color = Color3.fromRGB(255, 255, 0), assetId = getAssetId("Banana"),
        weatherMultipliers = {Sunny = 1.5, Cloudy = 0.9, Rainy = 1.1, Thunderstorm = 0.7},
        canGrowInSeason = {"Summer"}, soilTypes = {"rich"}, unlockLevel = 12
    },
    blueberry = {
        name = "Blueberry", description = "Uncommon antioxidant-rich superfruit", rarity = "uncommon",
        seedCost = 70, basePrice = 55, growthTime = 60, waterNeeded = 3, harvestCooldown = 22, maxHarvestCycles = 5,
        emoji = "🫐", color = Color3.fromRGB(72, 61, 139), assetId = getAssetId("Blueberry"),
        weatherMultipliers = {Sunny = 1.3, Cloudy = 1.1, Rainy = 1.2, Thunderstorm = 0.8},
        canGrowInSeason = {"Summer"}, soilTypes = {"any"}, unlockLevel = 11
    },
    cherry = {
        name = "Cherry", description = "Rare sweet stone fruit perfect for desserts", rarity = "rare",
        seedCost = 220, basePrice = 160, growthTime = 110, waterNeeded = 3, harvestCooldown = 45, maxHarvestCycles = 4,
        emoji = "🍒", color = Color3.fromRGB(220, 20, 60), assetId = getAssetId("Cherry"),
        weatherMultipliers = {Sunny = 1.4, Cloudy = 1.0, Rainy = 0.9, Thunderstorm = 0.7},
        canGrowInSeason = {"Spring", "Summer"}, soilTypes = {"rich"}, unlockLevel = 16
    },
    coconut = {
        name = "Coconut", description = "Rare tropical nut with refreshing water", rarity = "rare",
        seedCost = 280, basePrice = 190, growthTime = 160, waterNeeded = 4, harvestCooldown = 70, maxHarvestCycles = 2,
        emoji = "🥥", color = Color3.fromRGB(139, 69, 19), assetId = getAssetId("Coconut"),
        weatherMultipliers = {Sunny = 1.8, Cloudy = 0.6, Rainy = 0.8, Thunderstorm = 0.5},
        canGrowInSeason = {"Summer"}, soilTypes = {"rich"}, unlockLevel = 24
    },
    grapes = {
        name = "Grapes", description = "Rare clustered fruit perfect for wine", rarity = "rare",
        seedCost = 240, basePrice = 170, growthTime = 130, waterNeeded = 3, harvestCooldown = 50, maxHarvestCycles = 3,
        emoji = "🍇", color = Color3.fromRGB(128, 0, 128), assetId = getAssetId("Grapes"),
        weatherMultipliers = {Sunny = 1.5, Cloudy = 0.9, Rainy = 0.8, Thunderstorm = 0.6},
        canGrowInSeason = {"Fall"}, soilTypes = {"rich"}, unlockLevel = 19
    },
    kiwi = {
        name = "Kiwi", description = "Rare fuzzy fruit with green flesh", rarity = "rare",
        seedCost = 200, basePrice = 140, growthTime = 100, waterNeeded = 3, harvestCooldown = 40, maxHarvestCycles = 4,
        emoji = "🥝", color = Color3.fromRGB(173, 255, 47), assetId = getAssetId("Kiwi"),
        weatherMultipliers = {Sunny = 1.2, Cloudy = 1.2, Rainy = 1.1, Thunderstorm = 0.8},
        canGrowInSeason = {"Spring", "Fall"}, soilTypes = {"rich"}, unlockLevel = 17
    },
    lemon = {
        name = "Lemon", description = "Rare sour citrus fruit full of vitamin C", rarity = "rare",
        seedCost = 260, basePrice = 180, growthTime = 120, waterNeeded = 4, harvestCooldown = 45, maxHarvestCycles = 4,
        emoji = "🍋", color = Color3.fromRGB(255, 255, 0), assetId = getAssetId("Lemon"),
        weatherMultipliers = {Sunny = 1.7, Cloudy = 0.7, Rainy = 0.8, Thunderstorm = 0.5},
        canGrowInSeason = {"Summer"}, soilTypes = {"rich"}, unlockLevel = 21
    },
    lime = {
        name = "Lime", description = "Rare green citrus with zesty flavor", rarity = "rare",
        seedCost = 250, basePrice = 175, growthTime = 115, waterNeeded = 4, harvestCooldown = 42, maxHarvestCycles = 4,
        emoji = "🟢", color = Color3.fromRGB(50, 205, 50), assetId = getAssetId("Lime"),
        weatherMultipliers = {Sunny = 1.6, Cloudy = 0.8, Rainy = 0.9, Thunderstorm = 0.6},
        canGrowInSeason = {"Summer"}, soilTypes = {"rich"}, unlockLevel = 20
    },
    mango = {
        name = "Mango", description = "Epic tropical king of fruits", rarity = "epic",
        seedCost = 450, basePrice = 320, growthTime = 170, waterNeeded = 4, harvestCooldown = 65, maxHarvestCycles = 3,
        emoji = "🥭", color = Color3.fromRGB(255, 165, 0), assetId = getAssetId("Mango"),
        weatherMultipliers = {Sunny = 1.6, Cloudy = 0.8, Rainy = 1.0, Thunderstorm = 0.6},
        canGrowInSeason = {"Summer"}, soilTypes = {"rich"}, unlockLevel = 28
    },
    pear = {
        name = "Pear", description = "Rare sweet and juicy autumn fruit", rarity = "rare",
        seedCost = 230, basePrice = 165, growthTime = 125, waterNeeded = 3, harvestCooldown = 48, maxHarvestCycles = 4,
        emoji = "🍐", color = Color3.fromRGB(154, 205, 50), assetId = getAssetId("Pear"),
        weatherMultipliers = {Sunny = 1.3, Cloudy = 1.1, Rainy = 1.0, Thunderstorm = 0.8},
        canGrowInSeason = {"Fall"}, soilTypes = {"rich"}, unlockLevel = 18
    },
    pineapple = {
        name = "Pineapple", description = "Epic spiky tropical delicacy", rarity = "epic",
        seedCost = 600, basePrice = 400, growthTime = 190, waterNeeded = 5, harvestCooldown = 75, maxHarvestCycles = 2,
        emoji = "🍍", color = Color3.fromRGB(255, 215, 0), assetId = getAssetId("Pineapple"),
        weatherMultipliers = {Sunny = 1.8, Cloudy = 0.6, Rainy = 0.7, Thunderstorm = 0.4},
        canGrowInSeason = {"Summer"}, soilTypes = {"rich"}, unlockLevel = 32
    },
    raspberry = {
        name = "Raspberry", description = "Uncommon tart red berry", rarity = "uncommon",
        seedCost = 85, basePrice = 65, growthTime = 55, waterNeeded = 3, harvestCooldown = 20, maxHarvestCycles = 5,
        emoji = "🍇", color = Color3.fromRGB(227, 11, 92), assetId = getAssetId("Raspberry"),
        weatherMultipliers = {Sunny = 1.2, Cloudy = 1.1, Rainy = 1.3, Thunderstorm = 0.9},
        canGrowInSeason = {"Summer"}, soilTypes = {"any"}, unlockLevel = 13
    },
    watermelon = {
        name = "Watermelon", description = "Epic giant summer refresher", rarity = "epic",
        seedCost = 550, basePrice = 380, growthTime = 180, waterNeeded = 6, harvestCooldown = 80, maxHarvestCycles = 1,
        emoji = "🍉", color = Color3.fromRGB(255, 20, 147), assetId = getAssetId("Watermelon"),
        weatherMultipliers = {Sunny = 1.7, Cloudy = 0.7, Rainy = 1.2, Thunderstorm = 0.5},
        canGrowInSeason = {"Summer"}, soilTypes = {"rich"}, unlockLevel = 31
    },
    
    -- === MORE VEGETABLES ===
    garlic = {
        name = "Garlic", description = "Common pungent bulb that wards off vampires", rarity = "common",
        seedCost = 30, basePrice = 18, growthTime = 45, waterNeeded = 1, harvestCooldown = 18, maxHarvestCycles = 3,
        emoji = "🧄", color = Color3.fromRGB(255, 248, 220), assetId = getAssetId("Garlic"),
        weatherMultipliers = {Sunny = 1.0, Cloudy = 1.1, Rainy = 0.9, Thunderstorm = 0.8},
        canGrowInSeason = {"Spring", "Fall"}, soilTypes = {"any"}, unlockLevel = 4
    },
    ginger = {
        name = "Ginger", description = "Uncommon spicy root with healing properties", rarity = "uncommon",
        seedCost = 75, basePrice = 55, growthTime = 65, waterNeeded = 2, harvestCooldown = 25, maxHarvestCycles = 3,
        emoji = "🫚", color = Color3.fromRGB(205, 133, 63), assetId = getAssetId("Ginger"),
        weatherMultipliers = {Sunny = 1.1, Cloudy = 1.2, Rainy = 1.0, Thunderstorm = 0.9},
        canGrowInSeason = {"Spring", "Summer", "Fall"}, soilTypes = {"rich"}, unlockLevel = 14
    },
    leek = {
        name = "Leek", description = "Uncommon mild onion relative", rarity = "uncommon",
        seedCost = 55, basePrice = 38, growthTime = 50, waterNeeded = 2, harvestCooldown = 20, maxHarvestCycles = 3,
        emoji = "🥬", color = Color3.fromRGB(144, 238, 144), assetId = getAssetId("Leek"),
        weatherMultipliers = {Sunny = 0.9, Cloudy = 1.2, Rainy = 1.1, Thunderstorm = 0.8},
        canGrowInSeason = {"Fall", "Winter"}, soilTypes = {"any"}, unlockLevel = 9
    },
    mushroom = {
        name = "Mushroom", description = "Rare fungi that grows in dark places", rarity = "rare",
        seedCost = 160, basePrice = 110, growthTime = 75, waterNeeded = 2, harvestCooldown = 30, maxHarvestCycles = 4,
        emoji = "🍄", color = Color3.fromRGB(160, 82, 45), assetId = getAssetId("Mushroom"),
        weatherMultipliers = {Sunny = 0.6, Cloudy = 1.5, Rainy = 1.8, Thunderstorm = 1.2},
        canGrowInSeason = {"Fall", "Winter"}, soilTypes = {"rich"}, unlockLevel = 15
    },
    olive = {
        name = "Olive", description = "Rare Mediterranean fruit for oil", rarity = "rare",
        seedCost = 190, basePrice = 130, growthTime = 95, waterNeeded = 2, harvestCooldown = 35, maxHarvestCycles = 5,
        emoji = "🫒", color = Color3.fromRGB(107, 142, 35), assetId = getAssetId("Olive"),
        weatherMultipliers = {Sunny = 1.4, Cloudy = 0.9, Rainy = 0.7, Thunderstorm = 0.6},
        canGrowInSeason = {"Summer", "Fall"}, soilTypes = {"rich"}, unlockLevel = 16
    },
    pea_pod = {
        name = "Pea Pod", description = "Common green pods full of sweet peas", rarity = "common",
        seedCost = 25, basePrice = 16, growthTime = 35, waterNeeded = 2, harvestCooldown = 15, maxHarvestCycles = 4,
        emoji = "🟢", color = Color3.fromRGB(50, 205, 50), assetId = getAssetId("Pea Pod"),
        weatherMultipliers = {Sunny = 1.0, Cloudy = 1.1, Rainy = 1.2, Thunderstorm = 0.9},
        canGrowInSeason = {"Spring", "Summer"}, soilTypes = {"any"}, unlockLevel = 3
    },
    sweet_potato = {
        name = "Sweet Potato", description = "Uncommon orange root vegetable", rarity = "uncommon",
        seedCost = 65, basePrice = 45, growthTime = 70, waterNeeded = 2, harvestCooldown = 25, maxHarvestCycles = 3,
        emoji = "🍠", color = Color3.fromRGB(255, 140, 0), assetId = getAssetId("Sweet Potato"),
        weatherMultipliers = {Sunny = 1.2, Cloudy = 1.0, Rainy = 1.1, Thunderstorm = 0.9},
        canGrowInSeason = {"Fall"}, soilTypes = {"any"}, unlockLevel = 8
    },
    zucchini = {
        name = "Zucchini", description = "Uncommon versatile summer squash", rarity = "uncommon",
        seedCost = 48, basePrice = 32, growthTime = 52, waterNeeded = 3, harvestCooldown = 18, maxHarvestCycles = 4,
        emoji = "🥒", color = Color3.fromRGB(0, 128, 0), assetId = getAssetId("Zucchini"),
        weatherMultipliers = {Sunny = 1.3, Cloudy = 1.0, Rainy = 1.2, Thunderstorm = 0.8},
        canGrowInSeason = {"Summer"}, soilTypes = {"any"}, unlockLevel = 7
    },
    chilli_pepper = {
        name = "Chilli Pepper", description = "Rare fiery hot pepper", rarity = "rare",
        seedCost = 170, basePrice = 115, growthTime = 80, waterNeeded = 3, harvestCooldown = 35, maxHarvestCycles = 4,
        emoji = "🌶️", color = Color3.fromRGB(255, 0, 0), assetId = getAssetId("Chilli Pepper"),
        weatherMultipliers = {Sunny = 1.6, Cloudy = 0.8, Rainy = 0.7, Thunderstorm = 0.5},
        canGrowInSeason = {"Summer"}, soilTypes = {"rich"}, unlockLevel = 17
    },
    basil = {
        name = "Basil", description = "Common aromatic herb for cooking", rarity = "common",
        seedCost = 18, basePrice = 10, growthTime = 20, waterNeeded = 2, harvestCooldown = 10, maxHarvestCycles = 6,
        emoji = "🌿", color = Color3.fromRGB(0, 128, 0), assetId = getAssetId("Basil"),
        weatherMultipliers = {Sunny = 1.2, Cloudy = 1.0, Rainy = 1.1, Thunderstorm = 0.8},
        canGrowInSeason = {"Spring", "Summer"}, soilTypes = {"any"}, unlockLevel = 2
    },
    acorn = {
        name = "Acorn", description = "Epic oak tree seed with magical properties", rarity = "epic",
        seedCost = 700, basePrice = 450, growthTime = 220, waterNeeded = 4, harvestCooldown = 90, maxHarvestCycles = 1,
        emoji = "🌰", color = Color3.fromRGB(139, 69, 19), assetId = getAssetId("Acorn"),
        weatherMultipliers = {Sunny = 1.2, Cloudy = 1.3, Rainy = 1.1, Thunderstorm = 0.8},
        canGrowInSeason = {"Fall"}, soilTypes = {"rich"}, unlockLevel = 33
    },
    
    -- === LEGENDARY CROPS (Unlock Level 50+) ===
    golden_corn = {
        name = "Golden Corn", description = "Legendary magical corn that shimmers with gold", rarity = "legendary",
        seedCost = 2000, basePrice = 1200, growthTime = 300, waterNeeded = 6, harvestCooldown = 120, maxHarvestCycles = 1,
        emoji = "👑", color = Color3.fromRGB(255, 215, 0), assetId = getAssetId("Corn"), -- Uses corn asset with golden effect
        weatherMultipliers = {Sunny = 2.0, Cloudy = 0.5, Rainy = 0.8, Thunderstorm = 0.3},
        canGrowInSeason = {"Summer"}, soilTypes = {"rich"}, unlockLevel = 50
    }
}

-- Rarity definitions with multipliers
local RARITIES = {
    common = {
        dropChance = 70,
        color = Color3.fromRGB(200, 200, 200),
        multiplier = 1.0,
        name = "Common"
    },
    uncommon = {
        dropChance = 20,
        color = Color3.fromRGB(100, 255, 100),
        multiplier = 1.5,
        name = "Uncommon"
    },
    rare = {
        dropChance = 7,
        color = Color3.fromRGB(100, 100, 255),
        multiplier = 3.0,
        name = "Rare"
    },
    epic = {
        dropChance = 2.5,
        color = Color3.fromRGB(255, 100, 255),
        multiplier = 5.0,
        name = "Epic"
    },
    legendary = {
        dropChance = 0.5,
        color = Color3.fromRGB(255, 215, 0),
        multiplier = 10.0,
        name = "Legendary"
    }
}

-- Basic variation definitions (simplified)
local VARIATIONS = {
    normal = {
        chance = 100,
        multiplier = 1.0,
        prefix = "",
        color = nil -- Uses default crop color
    },
    dead = {
        chance = 0,
        multiplier = 0,
        prefix = "Dead ",
        color = Color3.fromRGB(100, 50, 50) -- Dead plants are dark brown
    }
}

-- API Functions
function CropRegistry.getCrop(cropId)
    return CROPS[cropId]
end

function CropRegistry.getAllCrops()
    return CROPS
end

function CropRegistry.getCropsByRarity(rarity)
    local crops = {}
    for id, crop in pairs(CROPS) do
        if crop.rarity == rarity then
            crops[id] = crop
        end
    end
    return crops
end

function CropRegistry.getCropsByUnlockLevel(level)
    local crops = {}
    for id, crop in pairs(CROPS) do
        if crop.unlockLevel <= level then
            crops[id] = crop
        end
    end
    return crops
end

function CropRegistry.getRarity(rarityId)
    return RARITIES[rarityId]
end

function CropRegistry.getAllRarities()
    return RARITIES
end

function CropRegistry.getVariation(variationId)
    return VARIATIONS[variationId]
end

function CropRegistry.getAllVariations()
    return VARIATIONS
end

-- Calculate final price with rarity and variation multipliers
function CropRegistry.calculatePrice(cropId, rarity, variation)
    local crop = CROPS[cropId]
    if not crop then return 0 end
    
    local rarityData = RARITIES[rarity or "common"]
    local variationData = VARIATIONS[variation or "normal"]
    
    return math.floor(crop.basePrice * (rarityData.multiplier or 1) * (variationData.multiplier or 1))
end

-- Get weather multiplier for a crop
function CropRegistry.getWeatherMultiplier(cropId, weatherType)
    local crop = CROPS[cropId]
    if not crop or not crop.weatherMultipliers then return 1.0 end
    
    return crop.weatherMultipliers[weatherType] or 1.0
end

-- Check if crop can grow in current season
function CropRegistry.canGrowInSeason(cropId, season)
    local crop = CROPS[cropId]
    if not crop or not crop.canGrowInSeason then return true end
    
    for _, allowedSeason in ipairs(crop.canGrowInSeason) do
        if allowedSeason == season then
            return true
        end
    end
    return false
end

-- Get crop visual data (emoji, color, mesh)
function CropRegistry.getVisuals(cropId, variation)
    local crop = CROPS[cropId]
    if not crop then return nil end
    
    local variationData = VARIATIONS[variation or "normal"]
    if not variationData then
        -- Fallback to normal variation if invalid variation provided
        variationData = VARIATIONS["normal"]
    end
    
    local color = (variationData and variationData.color) or crop.color
    local prefix = (variationData and variationData.prefix) or ""
    
    return {
        emoji = crop.emoji,
        color = color,
        meshId = crop.meshId,
        assetId = crop.assetId,
        name = prefix .. crop.name
    }
end

-- Validate crop data on module load
local function validateCrops()
    for id, crop in pairs(CROPS) do
        assert(crop.name, "Crop " .. id .. " missing name")
        assert(crop.seedCost, "Crop " .. id .. " missing seedCost")
        assert(crop.basePrice, "Crop " .. id .. " missing basePrice")
        assert(crop.growthTime, "Crop " .. id .. " missing growthTime")
        assert(RARITIES[crop.rarity], "Crop " .. id .. " has invalid rarity: " .. tostring(crop.rarity))
    end
end

-- Initialize
validateCrops()

return CropRegistry