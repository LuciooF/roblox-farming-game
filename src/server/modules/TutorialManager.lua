-- Tutorial Manager Module
-- Handles tutorial progression, rewards, and completion tracking

local Logger = require(script.Parent.Logger)
local GameConfig = require(script.Parent.GameConfig)
local PlayerDataManager = require(script.Parent.PlayerDataManager)
-- -- local NotificationManager = require(script.Parent.NotificationManager)
local RemoteManager = require(script.Parent.RemoteManager)

local TutorialManager = {}

-- Get module logger
local log = Logger.getModuleLogger("TutorialManager")

-- Tutorial steps configuration
local TUTORIAL_STEPS = {
    {
        id = "first_plot",
        title = "🏡 Your First Plot",
        description = "You start with no plots! Let's get your first plot for FREE.",
        instruction = "Follow the yellow trail to the FREE plot and press E to claim it!",
        reward = {money = 5},
        action = "buy_plot",
        arrowTarget = {type = "plot", plotId = nil} -- Points to closest unowned plot
    },
    {
        id = "plant_seed",
        title = "🌱 Plant Your First Crop",
        description = "Perfect! You own a plot. Now plant one of your starter crops.",
        instruction = "Walk to your brown plot and press E to plant a crop",
        reward = {money = 10},
        action = "plant_seed",
        arrowTarget = {type = "plot", plotId = 1} -- Points to first owned plot
    },
    {
        id = "water_plant",
        title = "💧 Water Your Plant",
        description = "Excellent! Your seed is planted. Now it needs water to grow.",
        instruction = "Open the Plot UI (press E on the plot) and click Water Crops",
        reward = {money = 10},
        action = "water_plant",
        arrowTarget = {type = "plot", plotId = 1} -- Points to planted plot
    },
    {
        id = "harvest_crop",
        title = "🌾 Harvest Your Crop",
        description = "When your plant sparkles with particles, it's ready to harvest!",
        instruction = "Wait for your crop to grow and harvest it!",
        reward = {money = 15},
        action = "harvest_crop",
        arrowTarget = {type = "plot", plotId = 1} -- Points to ready plot
    },
    {
        id = "sell_crops",
        title = "💰 Sell Your Crops",
        description = "Great harvest! Now let's turn those crops into money.",
        instruction = "Click the inventory button (🏚️) then click 'Sell All'",
        reward = {money = 20},
        action = "sell_crops",
        arrowTarget = nil -- No arrow, just shiny effect
    },
    {
        id = "stack_plants",
        title = "📚 Learn to Stack Plants",
        description = "Pro tip: You can plant multiple of the same crop on one plot to double your production!",
        instruction = "Plant another wheat seed on the same plot you just harvested to stack it!",
        reward = {money = 15},
        action = "plant_seed",
        arrowTarget = {type = "plot", plotId = 1} -- Points to the plot they just harvested
    },
    {
        id = "buy_banana",
        title = "🍌 The Banana Challenge",
        description = "Now for the real test! Banana sells for much more than starter crops.",
        instruction = "Farm and sell crops until you can buy banana from the shop!",
        reward = {money = 25},
        action = "buy_crop",
        target = "banana",
        arrowTarget = nil -- No arrow, just shiny effect
    },
    {
        id = "plant_banana",
        title = "🍌 Plant Your Banana",
        description = "Excellent work saving up! Banana takes longer to grow but it's worth it.",
        instruction = "Plant your banana seed in an empty plot",
        reward = {money = 30},
        action = "plant_banana",
        arrowTarget = {type = "plot", plotId = nil} -- Points to any empty plot
    }
}

-- Calculate total tutorial rewards
local function getTotalTutorialRewards()
    local total = 0
    for _, step in ipairs(TUTORIAL_STEPS) do
        if step.reward and step.reward.money then
            total = total + step.reward.money
        end
    end
    return total
end

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
    
    -- Validate and skip completed steps before sending tutorial
    TutorialManager.validateAndSkipCompletedSteps(player)
    
    -- Send current tutorial step to client
    TutorialManager.sendTutorialStep(player)
end

-- Validate and skip already completed steps
function TutorialManager.validateAndSkipCompletedSteps(player)
    local tutorialProgress = PlayerDataManager.getTutorialProgress(player)
    if not tutorialProgress or tutorialProgress.completed then return end
    
    local playerData = PlayerDataManager.getPlayerData(player)
    if not playerData then return end
    
    local currentStep = tutorialProgress.currentStep
    local skippedSteps = false
    
    -- Check each step to see if it's already completed
    while currentStep <= #TUTORIAL_STEPS do
        local step = TUTORIAL_STEPS[currentStep]
        if not step then break end
        
        local shouldSkip = false
        
        -- Check if step prerequisites are already met
        if step.id == "first_plot" then
            -- Skip if player already owns any plots
            local ownedPlots = PlayerDataManager.getUnlockedPlots(player)
            if ownedPlots > 0 then
                shouldSkip = true
                log.info("Skipping plot tutorial step - player already owns", ownedPlots, "plots")
            end
        elseif step.id == "plant_seed" then
            -- Skip if player has any planted crops or accumulated crops
            if playerData.plots then
                for _, plotState in pairs(playerData.plots) do
                    if plotState.state == "planted" or plotState.state == "growing" or plotState.state == "ready" or (plotState.accumulatedCrops and plotState.accumulatedCrops > 0) then
                        shouldSkip = true
                        log.info("Skipping plant tutorial step - player already has planted crops")
                        break
                    end
                end
            end
        elseif step.id == "water_plant" then
            -- Skip if player has watered plants
            if playerData.plots then
                for _, plotState in pairs(playerData.plots) do
                    if plotState.wateredCount and plotState.wateredCount > 0 then
                        shouldSkip = true
                        log.info("Skipping water tutorial step - player already has watered plants")
                        break
                    end
                end
            end
        elseif step.id == "harvest_crop" then
            -- Skip if player has money from selling or has crops in inventory
            if playerData.money > 25 or (playerData.inventory and playerData.inventory.crops) then
                local hasCrops = false
                for cropType, count in pairs(playerData.inventory.crops or {}) do
                    if count > 1 then -- More than starting wheat
                        hasCrops = true
                        break
                    end
                end
                if hasCrops then
                    shouldSkip = true
                    log.info("Skipping harvest tutorial step - player already has harvested crops")
                end
            end
        end
        
        if shouldSkip then
            -- Mark step as completed and move to next
            PlayerDataManager.markTutorialStepCompleted(player, step.id, 0) -- No reward for skipped steps
            currentStep = currentStep + 1
            skippedSteps = true
        else
            -- Found a step that's not completed yet
            break
        end
    end
    
    if skippedSteps then
        -- Update the current step
        PlayerDataManager.setTutorialStep(player, currentStep)
        log.info("Skipped tutorial steps for", player.Name, "- now at step", currentStep)
        
        -- Check if we've completed all steps
        if currentStep > #TUTORIAL_STEPS then
            TutorialManager.completeTutorial(player)
            return
        end
    end
end

-- Send current tutorial step to client
function TutorialManager.sendTutorialStep(player)
    local tutorialProgress = PlayerDataManager.getTutorialProgress(player)
    if not tutorialProgress then return end
    
    if tutorialProgress.completed then
        return
    end
    
    -- Check if current step is already completed, and skip if needed
    TutorialManager.validateAndSkipCompletedSteps(player)
    
    -- Re-get tutorial progress in case it was updated by validation
    tutorialProgress = PlayerDataManager.getTutorialProgress(player)
    if not tutorialProgress or tutorialProgress.completed then
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
            totalSteps = #TUTORIAL_STEPS,
            arrowTarget = currentStep.arrowTarget
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
    
    log.warn("📚 Tutorial progress check - Step:", tutorialProgress.currentStep, "Action:", action, "Player:", player.Name)
    
    -- Check if action matches expected action OR if sending "continue" to a step that allows it
    if currentStep.action ~= action and not (currentStep.action == "continue" and action == "continue") then
        -- Special override for plant_banana
        if not (currentStep.action == "plant_banana" and action == "plant_seed") then
            log.debug("Tutorial action mismatch: expected", currentStep.action, "got", action)
            return
        end
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
    
    -- Check for plant_banana action (when planting banana specifically)
    if action == "plant_seed" and currentStep.action == "plant_banana" then
        if not data or data.seedType ~= "banana" then
            log.debug("Plant banana check failed - expected banana, got", data and data.seedType or "nil")
            return
        end
        log.debug("Plant banana check passed")
        -- Override the action to match the expected action
        action = "plant_banana"
    end
    
    -- Mark current step as completed and give reward
    local rewardAmount = 0
    if currentStep.reward and currentStep.reward.money > 0 then
        rewardAmount = currentStep.reward.money
        PlayerDataManager.addMoney(player, rewardAmount)
        
        -- Use the rewards system for nice animations
        local rewardDescription = "🎉 Tutorial Step Complete!\n" .. currentStep.title
        RemoteManager.sendMoneyReward(player, rewardAmount, rewardDescription)
    end
    
    -- Mark step as completed in persistent storage
    PlayerDataManager.markTutorialStepCompleted(player, currentStep.id, rewardAmount)
    
    -- Move to next step
    local nextStep = tutorialProgress.currentStep + 1
    PlayerDataManager.setTutorialStep(player, nextStep)
    
    log.warn("📈 Tutorial advanced to step", nextStep, "for", player.Name)
    
    -- Check if tutorial is complete
    if nextStep > #TUTORIAL_STEPS then
        TutorialManager.completeTutorial(player)
    else
        -- Send next step
        log.warn("📨 Sending tutorial step", nextStep, "to", player.Name)
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
    
--     NotificationManager.sendNotification(player, "🎉 Tutorial completed! You're ready to farm!")
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
    
    local totalRewards = getTotalTutorialRewards()
--     NotificationManager.sendWarning(player, "⚠️ Tutorial skipped. You missed out on " .. totalRewards .. " coins in rewards!")
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
        log.info("🎯 Resetting tutorial for", player.Name)
        PlayerDataManager.resetTutorial(player)
        TutorialManager.initializePlayer(player)
    else
        log.warn("Unknown tutorial action:", actionType, "from", player.Name)
    end
end

-- Check if player should receive tutorial progress for game actions
function TutorialManager.checkGameAction(player, action, data)
    local tutorialProgress = PlayerDataManager.getTutorialProgress(player)
    if not tutorialProgress then 
        log.warn("No tutorial progress found for", player.Name, "when checking action:", action)
        return 
    end
    
    if tutorialProgress.completed then
        log.debug("Tutorial already completed for", player.Name, "- ignoring action:", action)
        return
    end
    
    local currentStep = TUTORIAL_STEPS[tutorialProgress.currentStep]
    if not currentStep then
        log.warn("Invalid tutorial step", tutorialProgress.currentStep, "for", player.Name)
        return
    end
    
    -- Special case: Check if this is a plant_banana step and we're planting banana
    if currentStep.action == "plant_banana" and action == "plant_seed" then
        if data and data.seedType == "banana" then
            log.warn("🍌 Special case: Planting banana detected for plant_banana step!")
            TutorialManager.progressTutorial(player, action, data)
            return
        end
    end
    
    -- Only progress if the action matches the current step's expected action
    if currentStep.action == action then
        log.warn("✅ Tutorial action matches! Action:", action, "Step:", tutorialProgress.currentStep, "Player:", player.Name)
        TutorialManager.progressTutorial(player, action, data)
    else
        log.warn("❌ Tutorial action mismatch. Got:", action, "Expected:", currentStep.action, "Step:", tutorialProgress.currentStep, "Player:", player.Name)
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