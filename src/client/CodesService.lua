-- Codes Service
-- Handles code redemption and validation

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RewardsService = require(script.Parent.RewardsService)

local CodesService = {}

-- Initialize the service
function CodesService.initialize(remotes)
    -- Listen for code redemption responses
    if remotes.redeemCode then
        remotes.redeemCode.OnClientEvent:Connect(function(success, responseData)
            if success and responseData then
                print("[INFO] Code redeemed successfully:", responseData.code)
                
                -- Show reward using RewardsService
                if responseData.rewardType == "money" then
                    RewardsService.showMoneyReward(
                        responseData.rewardAmount,
                        "Code '" .. responseData.code .. "' redeemed!"
                    )
                elseif responseData.rewardType == "seeds" then
                    -- Future seed reward implementation
                    RewardsService.showReward({
                        type = "seeds",
                        amount = responseData.rewardAmount,
                        seedType = responseData.seedType,
                        title = "Seeds Received!",
                        description = "Code '" .. responseData.code .. "' gave you " .. responseData.rewardAmount .. " " .. responseData.seedType .. " seeds!",
                        iconAsset = "General/Seeds/Seeds Outline 256.png",
                        color = Color3.fromRGB(85, 170, 85),
                        rarity = "common"
                    })
                end
                
                -- Return success to UI
                if CodesService.onRedeemCallback then
                    CodesService.onRedeemCallback(true, responseData.code, nil)
                end
            else
                print("[WARN] Code redemption failed")
                
                -- Handle different types of failures
                local errorMessage = "Invalid or already redeemed code!"
                local errorType = "generic"
                
                if responseData and responseData.error then
                    if responseData.error == "like_favorite_required" then
                        errorType = "like_favorite_required"
                        errorMessage = responseData.message or "Please join our group and favorite the game!"
                        
                        -- Show the like/favorite popup instead of normal error
                        if responseData.groupId and _G.showLikeFavoritePopup then
                            -- Calculate remaining time client-side using timestamp
                            local currentTime = os.time()
                            local timestamp = responseData.timestamp or currentTime
                            local waitTime = responseData.waitTime or 120
                            local remainingTime = math.max(0, waitTime - (currentTime - timestamp))
                            
                            _G.showLikeFavoritePopup(responseData.groupId, remainingTime)
                            return -- Don't show the error in UI, the popup handles it
                        else
                            -- Fallback to old method if popup not available
                            CodesService.promptGroupJoinAndFavorite(responseData.groupId, responseData.waitTime or 120)
                        end
                    elseif responseData.error == "already_redeemed" then
                        errorType = "already_redeemed"
                        errorMessage = responseData.message or "You have already redeemed this code!"
                    end
                end
                
                -- Return failure to UI
                if CodesService.onRedeemCallback then
                    CodesService.onRedeemCallback(false, nil, {type = errorType, message = errorMessage})
                end
            end
        end)
    end
    
    -- Listen for clear codes responses
    if remotes.clearCodes then
        remotes.clearCodes.OnClientEvent:Connect(function(success)
            if success then
                print("[INFO] Codes cleared successfully")
            else
                print("[WARN] Failed to clear codes")
            end
        end)
    end
end

-- Redeem a code
function CodesService.redeemCode(code, remotes)
    if not code or code == "" then
        print("[WARN] No code provided")
        return false
    end
    
    -- Trim whitespace and convert to uppercase
    code = string.upper(string.gsub(code, "^%s*(.-)%s*$", "%1"))
    
    print("[INFO] Attempting to redeem code:", code)
    
    if remotes.redeemCode then
        remotes.redeemCode:FireServer(code)
        return true
    else
        warn("Redeem code remote not available")
        return false
    end
end

-- Prompt player to join group and favorite the game
function CodesService.promptGroupJoinAndFavorite(groupId, waitTime)
    local SocialService = game:GetService("SocialService")
    local MarketplaceService = game:GetService("MarketplaceService")
    local StarterGui = game:GetService("StarterGui")
    
    print("[INFO] Prompting player to join group", groupId, "and favorite the game")
    
    -- Show a notification to the player about the requirements
    local success, err = pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Join & Favorite Required!";
            Text = "Please join our group and favorite the game to unlock codes!";
            Duration = 5;
        })
    end)
    
    if not success then
        print("[WARN] Failed to show notification:", err)
    end
    
    -- Try to use TeleportService to show game page (this is limited but works in some cases)
    local success2, err2 = pcall(function()
        -- Note: This won't work in Studio but will work in live game
        -- Players will need to manually join group and favorite
        print("[INFO] Please manually join group ID:", groupId, "and favorite this game")
        print("[INFO] Group link: https://www.roblox.com/groups/" .. tostring(groupId))
    end)
    
    -- Show console message with instructions
    print("[INFO] To redeem codes:")
    print("1. Join our group: https://www.roblox.com/groups/" .. tostring(groupId))
    print("2. Favorite this game (click the star on the game page)")
    print("3. Wait", waitTime, "seconds after your first attempt")
    print("4. Try redeeming the code again!")
end

-- Clear all redeemed codes (debug function)
function CodesService.clearCodes(remotes)
    print("[INFO] Clearing all redeemed codes...")
    
    if remotes.clearCodes then
        remotes.clearCodes:FireServer()
        return true
    else
        warn("Clear codes remote not available")
        return false
    end
end

-- Set callback for UI updates
function CodesService.setRedeemCallback(callback)
    CodesService.onRedeemCallback = callback
end

return CodesService