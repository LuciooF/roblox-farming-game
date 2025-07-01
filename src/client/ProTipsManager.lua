-- Pro Tips Manager
-- Manages the queue and display of pro tips

local ProTipsManager = {}

-- Storage
local currentTipCallback = nil
local tipQueue = {}
local isShowingTip = false
local playerDataGetter = nil

-- Pro tips for farming success
local PRO_TIPS = {
    -- Basic farming tips
    "Plant crops in all your plots to maximize your income!",
    "Water your crops regularly to speed up their growth time.",
    "Save up for better seeds - they give much higher profits!",
    "Check the shop for special seeds with unique properties.",
    "Harvest crops as soon as they're ready to start growing new ones.",
    
    -- Rebirth system tips
    "Rebirth to unlock massive production boosts, better plants, and more plots! Your progress resets but permanent bonuses make it worth it!",
    "Each rebirth increases your chances of growing rare crops and unlocks access to new exciting worlds with unique opportunities!",
    
    -- Plot stacking tips
    "Stack up to 50 plants in the same plot for incredible production! Example: 1 wheat at 50/hour + 1 more = 100/hour from that plot!",
    "Higher stack counts mean exponential profits - always try to fill your plots to maximum capacity!",
    
    -- Ranking and competition
    "Climb the ranks to reach the top of the leaderboard and show off your rarest plants to other players!",
    "Compete with friends to see who can build the most profitable farm empire!",
    
    -- Offline optimization tips
    "Going offline? Plant crops with long water maintenance times! Wheat only produces for 2 hours offline, but some crops last 12+ hours!",
    "Before logging off, water all crops and choose long-duration plants to maximize your offline earnings!",
    "Plan your offline strategy: longer-lasting crops mean more money when you return!",
    
    -- Advanced tips
    "The weather affects your crop growth - use it to your advantage for faster harvests! (Check the forecast in the game!)",
    "All plots can grow multiple crops at once - upgrade wisely!",
    "Some rare seeds can only be found during special events - don't miss out!",
    "Expand your farm by purchasing adjacent plots for maximum growing space!",
    "Combine harvesting with production boosts for maximum profit per hour!",
    
    -- Social and progression tips
    "Join friends in their farms to help them water crops and learn new strategies!",
    "Click on other players' farms to visit and discover new farming techniques!",
    "Complete the tutorial for easy starting money and essential farming knowledge!",
    "Check daily for free rewards and bonuses to boost your farm's growth!"
}

-- Initialize the manager
function ProTipsManager.init(showTipCallback, getPlayerDataCallback)
    currentTipCallback = showTipCallback
    playerDataGetter = getPlayerDataCallback
    
    -- Start showing random tips periodically
    task.spawn(function()
        -- Wait a bit before showing first tip
        task.wait(30)
        
        while true do
            -- Random interval between 1-2 minutes (60-120 seconds)
            local waitTime = math.random(60, 120)
            task.wait(waitTime)
            
            -- Check if player has 5+ rebirths - if so, stop showing tips
            if playerDataGetter then
                local playerData = playerDataGetter()
                if playerData and playerData.rebirths and playerData.rebirths >= 5 then
                    -- Skip showing tip for experienced players (5+ rebirths)
                    continue
                end
            end
            
            local randomTip = PRO_TIPS[math.random(1, #PRO_TIPS)]
            ProTipsManager.showTip(randomTip)
        end
    end)
end

-- Show a specific tip
function ProTipsManager.showTip(tipText)
    if not currentTipCallback then
        warn("ProTipsManager: No callback set")
        return
    end
    
    -- Add to queue if already showing a tip
    if isShowingTip then
        table.insert(tipQueue, tipText)
        return
    end
    
    isShowingTip = true
    currentTipCallback(tipText, true)
    
    -- Hide after 11 seconds (1 second after animation starts)
    task.delay(11, function()
        currentTipCallback(nil, false)
        isShowingTip = false
        
        -- Show next tip in queue after a short delay
        if #tipQueue > 0 then
            local nextTip = table.remove(tipQueue, 1)
            task.wait(1)
            ProTipsManager.showTip(nextTip)
        end
    end)
end

-- Show a tip immediately (useful for context-sensitive tips)
function ProTipsManager.showTipNow(tipText)
    -- Clear queue and show this tip
    tipQueue = {}
    ProTipsManager.showTip(tipText)
end

-- Add context-sensitive tips
function ProTipsManager.onPlayerAction(action, data)
    local contextTips = {
        plantedFirstCrop = "Great job! Now water your crop to help it grow faster!",
        boughtFirstPlot = "Excellent! More plots mean more income. Keep expanding!",
        firstHarvest = "Nice harvest! Try planting different seeds to see what grows best!",
        firstRebirth = "Congratulations on your first rebirth! You now have permanent bonuses!",
        unlockedNewArea = "New area unlocked! Explore to find rare seeds and special plots!",
        reachedLevel10 = "Level 10! You can now access premium seeds in the shop!",
        firstMultiHarvest = "Multi-harvest! Some crops give multiple yields - very profitable!",
        discoveredCombo = "Crop combo discovered! Plant these together for bonus yields!"
    }
    
    local tip = contextTips[action]
    if tip then
        ProTipsManager.showTipNow(tip)
    end
end

return ProTipsManager