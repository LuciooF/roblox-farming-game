-- Tutorial Manager Module
-- Handles tutorial progression, rewards, and completion tracking

local Logger = require(script.Parent.Logger)
local GameConfig = require(script.Parent.GameConfig)
local PlayerDataManager = require(script.Parent.PlayerDataManager)
local NotificationManager = require(script.Parent.NotificationManager)
local RemoteManager = require(script.Parent.RemoteManager)

local TutorialManager = {}

-- Get module logger
local log = Logger.getModuleLogger("TutorialManager")

-- Tutorial steps configuration
local TUTORIAL_STEPS = {
    {
        id = "welcome",
        title = "🌱 Welcome to the Farm!",
        description = "Welcome to your new farming adventure! Let's learn the basics.",
        instruction = "Click 'Next' to continue or 'Skip' to skip the tutorial (you'll miss rewards!)",
        reward = {money = 50},
        action = "continue"
    },
    {
        id = "buy_crops",
        title = "🛒 Buy Your First Crops", 
        description = "You need crops to start farming! Any crops will work to get started.",
        instruction = "Click the 🛒 Shop button on the left, then buy any crops (like wheat or carrot)",
        reward = {money = 25},
        action = "buy_crop"
    },
    {
        id = "plant_seed",
        title = "🌱 Plant Your Crop",
        description = "Great! Now you have crops. Time to plant your first crop.",
        instruction = "Walk to any brown farm plot and press E when the 'Plant Seed' prompt appears",
        reward = {money = 50},
        action = "plant_seed"
    },
    {
        id = "water_plant",
        title = "💧 Water Your Plant",
        description = "Excellent! Your seed is planted. Now it needs water to grow.",
        instruction = "Press R when the 'Water Plant' prompt appears",
        reward = {money = 50},
        action = "water_plant"
    },
    {
        id = "wait_growth",
        title = "⏰ Wait for Growth",
        description = "Nice watering! Your plant is now growing. Wheat only takes 15 seconds.",
        instruction = "Wait for your plant to sparkle with particles - then it's ready!",
        reward = {money = 25},
        action = "plant_ready"
    },
    {
        id = "harvest_crop",
        title = "🌾 Harvest Your Crop",
        description = "Your plant is ready! Those sparkles mean it's time to harvest.",
        instruction = "Press F when the 'Harvest Crop' prompt appears",
        reward = {money = 100},
        action = "harvest_crop"
    },
    {
        id = "sell_crops",
        title = "💰 Sell Your Crops",
        description = "Fantastic! You harvested your first crop. Now let's sell it for money.",
        instruction = "Click the 💰 'Sell All' button on the left side panel to sell your crops",
        reward = {money = 100},
        action = "sell_crops"
    },
    {
        id = "seed_drops",
        title = "🎁 Discover Seed Drops",
        description = "Amazing! You've completed the basic farming loop. There are rare seeds that drop from the sky!",
        instruction = "Check out the seed drop tube on the far left for rare seeds",
        reward = {money = 200},
        action = "visit_seed_drops"
    },
    {
        id = "complete",
        title = "🎉 Tutorial Complete!",
        description = "Congratulations! You're now a farming expert! Keep growing crops, buying rare seeds, and earning money to unlock rebirths!",
        instruction = "Tutorial completed! You earned 600 coins total. Happy farming!",
        reward = {money = 0},
        action = "complete"
    }
}

-- Initialize tutorial for a player (now uses ProfileStore persistence)
function TutorialManager.initializePlayer(player)
    local tutorialProgress = PlayerDataManager.getTutorialProgress(player)
    if not tutorialProgress then
        log.warn("Could not get tutorial progress for", player.Name)
        return
    end
    
    -- Check if player has already completed tutorial
    if tutorialProgress.completed then
        log.info("Player", player.Name, "has already completed tutorial - sending completion status")
        -- Send completion status to client for reset button
        local remotes = RemoteManager.getRemotes()
        if remotes.tutorialRemote then
            remotes.tutorialRemote:FireClient(player, {
                completed = true,
                action = "hide"
            })
        end
        return
    end
    
    -- Check if player is in middle of tutorial
    if tutorialProgress.currentStep > 1 then
        log.info("Resuming tutorial for player", player.Name, "at step", tutorialProgress.currentStep)
    else
        log.info("Starting new tutorial for player", player.Name)
    end
    
    -- Send current tutorial step to client
    TutorialManager.sendTutorialStep(player)
end

-- Send current tutorial step to client
function TutorialManager.sendTutorialStep(player)
    local tutorialProgress = PlayerDataManager.getTutorialProgress(player)
    if not tutorialProgress then return end
    
    if tutorialProgress.completed then
        return
    end
    
    local currentStep = TUTORIAL_STEPS[tutorialProgress.currentStep]
    if not currentStep then
        return
    end
    
    -- Send tutorial data to client
    local remotes = RemoteManager.getRemotes()
    if remotes.tutorialRemote then
        local tutorialData = {
            step = currentStep,
            stepNumber = tutorialProgress.currentStep,
            totalSteps = #TUTORIAL_STEPS
        }
        log.debug("Sending tutorial step", tutorialProgress.currentStep, "to", player.Name, ":", currentStep.title)
        remotes.tutorialRemote:FireClient(player, tutorialData)
    else
        log.error("Tutorial remote not found!")
    end
end

-- Progress tutorial to next step
function TutorialManager.progressTutorial(player, action, data)
    local tutorialProgress = PlayerDataManager.getTutorialProgress(player)
    if not tutorialProgress then return end
    
    if tutorialProgress.completed then
        return
    end
    
    local currentStep = TUTORIAL_STEPS[tutorialProgress.currentStep]
    if not currentStep then
        return
    end
    
    -- Check if action matches expected action OR if sending "continue" to a step that allows it
    if currentStep.action ~= action and not (currentStep.action == "continue" and action == "continue") then
        log.debug("Tutorial action mismatch: expected", currentStep.action, "got", action)
        return
    end
    
    -- Special checks for specific actions
    if action == "buy_crop" and currentStep.target then
        log.debug("Buy crop check: expected", currentStep.target, "got", data and data.cropType or "nil")
        if not data or data.cropType ~= currentStep.target then
            log.debug("Buy crop failed target check")
            return
        end
        log.debug("Buy crop passed target check")
    end
    
    -- Mark current step as completed and give reward
    local rewardAmount = 0
    if currentStep.reward and currentStep.reward.money > 0 then
        rewardAmount = currentStep.reward.money
        PlayerDataManager.addMoney(player, rewardAmount)
        NotificationManager.sendMoney(player, 
            "🎉 Tutorial Reward: +" .. rewardAmount .. " coins!")
    end
    
    -- Mark step as completed in persistent storage
    PlayerDataManager.markTutorialStepCompleted(player, currentStep.id, rewardAmount)
    
    -- Move to next step
    local nextStep = tutorialProgress.currentStep + 1
    PlayerDataManager.setTutorialStep(player, nextStep)
    
    -- Check if tutorial is complete
    if nextStep > #TUTORIAL_STEPS then
        TutorialManager.completeTutorial(player)
    else
        -- Send next step
        TutorialManager.sendTutorialStep(player)
    end
    
    -- Sync player data
    RemoteManager.syncPlayerData(player)
end

-- Complete tutorial
function TutorialManager.completeTutorial(player)
    -- Mark tutorial as completed in persistent storage
    PlayerDataManager.completeTutorial(player, false)
    
    -- Hide tutorial UI and send completion status
    local remotes = RemoteManager.getRemotes()
    if remotes.tutorialRemote then
        remotes.tutorialRemote:FireClient(player, {
            completed = true,
            action = "hide"
        })
    end
    
    NotificationManager.sendNotification(player, "🎉 Tutorial completed! You're ready to farm!")
    log.info("Player completed tutorial:", player.Name)
end

-- Skip tutorial
function TutorialManager.skipTutorial(player)
    local tutorialProgress = PlayerDataManager.getTutorialProgress(player)
    if not tutorialProgress then return end
    
    if tutorialProgress.completed then
        return
    end
    
    -- Mark tutorial as completed and skipped in persistent storage
    PlayerDataManager.completeTutorial(player, true)
    
    -- Hide tutorial UI and send completion status
    local remotes = RemoteManager.getRemotes()
    if remotes.tutorialRemote then
        remotes.tutorialRemote:FireClient(player, {
            completed = true,
            action = "hide"
        })
    end
    
    NotificationManager.sendWarning(player, "⚠️ Tutorial skipped. You missed out on 600 coins in rewards!")
    log.info("Player skipped tutorial:", player.Name)
end

-- Handle tutorial action from client
function TutorialManager.handleTutorialAction(player, actionType, data)
    log.debug("Tutorial action from", player.Name, ":", actionType)
    if actionType == "next" then
        TutorialManager.progressTutorial(player, "continue", data)
    elseif actionType == "skip" then
        TutorialManager.skipTutorial(player)
    elseif actionType == "reset" then
        -- Debug action to reset tutorial
        print("🎯 Resetting tutorial for", player.Name)
        PlayerDataManager.resetTutorial(player)
        TutorialManager.initializePlayer(player)
    else
        log.warn("Unknown tutorial action:", actionType, "from", player.Name)
    end
end

-- Check if player should receive tutorial progress for game actions
function TutorialManager.checkGameAction(player, action, data)
    local tutorialProgress = PlayerDataManager.getTutorialProgress(player)
    if not tutorialProgress then return end
    
    if tutorialProgress.completed then
        return
    end
    
    local currentStep = TUTORIAL_STEPS[tutorialProgress.currentStep]
    if not currentStep then
        return
    end
    
    -- Only progress if the action matches the current step's expected action
    if currentStep.action == action then
        log.debug("Tutorial action matches current step:", action, "for step", tutorialProgress.currentStep)
        TutorialManager.progressTutorial(player, action, data)
    else
        log.debug("Tutorial action ignored:", action, "expected:", currentStep.action, "for step", tutorialProgress.currentStep)
    end
end

-- Get tutorial state for player (now from ProfileStore)
function TutorialManager.getTutorialState(player)
    return PlayerDataManager.getTutorialProgress(player)
end

-- Player left - no cleanup needed (ProfileStore handles persistence)
function TutorialManager.onPlayerLeft(player)
    -- No local state to clean up - everything is in ProfileStore
    log.debug("Tutorial state preserved for", player.Name, "in ProfileStore")
end

return TutorialManager