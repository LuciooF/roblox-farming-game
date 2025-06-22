-- Main App component
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages.react)

local Components = ReplicatedStorage:WaitForChild("Components")
local FarmUI = require(Components:WaitForChild("FarmUI"))
local PlayerStats = require(Components:WaitForChild("PlayerStats"))
local Shop = require(Components:WaitForChild("Shop"))

local function App(props)
    local store = props.store
    local state, setState = React.useState(store:getState())
    
    -- Subscribe to store changes
    React.useEffect(function()
        local connection = store.changed:connect(function(newState)
            setState(newState)
        end)
        
        return function()
            connection:disconnect()
        end
    end, {})
    
    local function dispatch(action)
        store:dispatch(action)
    end
    
    return React.createElement("ScreenGui", {
        Name = "FarmingGameUI",
        ResetOnSpawn = false
    }, {
        PlayerStats = React.createElement(PlayerStats, {
            player = state.player,
            dispatch = dispatch
        }),
        
        FarmUI = React.createElement(FarmUI, {
            farm = state.farm,
            inventory = state.inventory,
            dispatch = dispatch
        }),
        
        Shop = React.createElement(Shop, {
            shop = state.shop,
            player = state.player,
            inventory = state.inventory,
            dispatch = dispatch
        })
    })
end

return App