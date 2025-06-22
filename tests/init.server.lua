-- Test runner for the farming game (disabled for initial testing)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("🧪 Test Suite Available (run manually with _G.runFarmingGameTests())")

-- Disabled automatic test running for initial setup
--[[ 
-- Wait for packages to load
local Packages = ReplicatedStorage:WaitForChild("Packages")
local TestEZ = require(Packages.TestEZ)

-- Run all tests in the tests folder
local testResults = TestEZ.TestBootstrap:run({
    script.Parent.GameReducer,
    script.Parent.FarmingSystem,
    script.Parent.PlayerDataManager
}, TestEZ.Reporters.TextReporter)

if testResults.failureCount == 0 then
    print("✅ All tests passed!")
else
    warn("❌ " .. testResults.failureCount .. " test(s) failed")
end

print("📊 Test Summary:")
print("  - Total: " .. (testResults.successCount + testResults.failureCount))
print("  - Passed: " .. testResults.successCount)
print("  - Failed: " .. testResults.failureCount)
print("  - Skipped: " .. (testResults.skippedCount or 0))

return testResults
--]]