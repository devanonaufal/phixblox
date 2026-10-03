-- PhixBlox Simple Test (No Dependencies)
print("=== PhixBlox Test Started ===")
print("If you see this, loadstring works!")

-- Test 1: Basic Lua
print("Test 1: Lua OK")

-- Test 2: Roblox Services
local success1, Players = pcall(function() return game:GetService("Players") end)
print("Test 2: Services " .. (success1 and "OK" or "FAILED"))

-- Test 3: Drawing API
local success2 = pcall(function() Drawing.new("Circle") end)
print("Test 3: Drawing API " .. (success2 and "OK" or "FAILED"))

-- Test 4: File Functions
local success3 = pcall(function() writefile("test.txt", "test") end)
print("Test 4: File API " .. (success3 and "OK" or "FAILED"))

-- Test 5: Hook Functions
local success4 = pcall(function() hookmetamethod(game, "__namecall", function() end) end)
print("Test 5: Hook API " .. (success4 and "OK" or "FAILED"))

print("=== All Tests Complete ===")
print("Copy this output and send to developer!")
