-- Standalone test runner script for development
-- This can be run in Roblox Studio to execute tests

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Function to run tests in Studio
local function runTests()
    print("🌱 Farming Game - Test Runner")
    print("=====================================")
    
    -- Check if packages are available
    local packagesFolder = ReplicatedStorage:FindFirstChild("Packages")
    if not packagesFolder then
        warn("❌ Packages folder not found. Run 'wally install' first.")
        return false
    end
    
    local testEZ = packagesFolder:FindFirstChild("TestEZ")
    if not testEZ then
        warn("❌ TestEZ not found in packages. Check wally.toml dependencies.")
        return false
    end
    
    print("✅ TestEZ found, starting tests...")
    
    -- Load TestEZ
    local TestEZ = require(testEZ)
    
    -- Find tests folder
    local testsFolder = script.Parent:FindFirstChild("tests")
    if not testsFolder then
        warn("❌ Tests folder not found")
        return false
    end
    
    print("📁 Found test files:")
    for _, child in ipairs(testsFolder:GetChildren()) do
        if child:IsA("ModuleScript") and child.Name:match("%.spec$") then
            print("  - " .. child.Name)
        end
    end
    
    -- Collect test modules
    local testModules = {}
    for _, child in ipairs(testsFolder:GetChildren()) do
        if child:IsA("ModuleScript") and child.Name:match("%.spec$") then
            table.insert(testModules, child)
        end
    end
    
    if #testModules == 0 then
        warn("❌ No test files found (should end with .spec.lua)")
        return false
    end
    
    print("\n🧪 Running " .. #testModules .. " test suite(s)...")
    print("=====================================")
    
    -- Run tests
    local success, results = pcall(function()
        return TestEZ.TestBootstrap:run(testModules, TestEZ.Reporters.TextReporter)
    end)
    
    if not success then
        warn("❌ Test execution failed: " .. tostring(results))
        return false
    end
    
    print("\n📊 Final Results:")
    print("=====================================")
    
    if results.failureCount == 0 then
        print("🎉 All tests passed!")
        print("✅ " .. results.successCount .. " assertions successful")
        
        if results.skippedCount and results.skippedCount > 0 then
            print("⏭️  " .. results.skippedCount .. " tests skipped")
        end
        
        return true
    else
        print("❌ Some tests failed")
        print("✅ Passed: " .. results.successCount)
        print("❌ Failed: " .. results.failureCount)
        
        if results.skippedCount and results.skippedCount > 0 then
            print("⏭️  Skipped: " .. results.skippedCount)
        end
        
        return false
    end
end

-- Instructions for use
print([[
🌱 Farming Game Test Runner
===========================

To run tests:
1. Make sure you've run 'wally install' to get TestEZ
2. In Roblox Studio, run this script or call runTests()
3. Check the output window for results

For automated testing:
- Tests will run automatically when the server starts
- Use the tests/init.server.lua for continuous testing

]])

-- Export the function for manual use
_G.runFarmingGameTests = runTests

-- Auto-run if this script is executed directly
if script.Parent == game.ServerScriptService then
    runTests()
end

return {
    runTests = runTests
}