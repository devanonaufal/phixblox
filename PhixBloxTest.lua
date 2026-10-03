--[[
    PhixBlox v2.0 - Test Version with Error Handling
]]

print("[PhixBlox] Starting...")

-- Test 1: Check if executor supports required functions
local function checkExecutor()
    local required = {
        "loadstring", "game", "Drawing", "writefile", "readfile", 
        "hookmetamethod", "newcclosure", "getnamecallmethod"
    }
    
    for _, func in ipairs(required) do
        if not _G[func] and not getfenv()[func] then
            warn("[PhixBlox] Missing function: " .. func)
        end
    end
end

checkExecutor()

-- Test 2: Load UI Library with error handling
print("[PhixBlox] Loading UI Library...")
local Library, libraryError = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/devanonaufal/phixblox/main/UILibrary.lua"))()
end)

if not Library then
    error("[PhixBlox] Failed to load UI Library: " .. tostring(libraryError))
    return
end

print("[PhixBlox] UI Library loaded successfully!")

-- Services
print("[PhixBlox] Loading services...")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

print("[PhixBlox] Services loaded!")

-- Config
local Settings = {
    Combat = {AimbotEnabled = false, AimbotTarget = "Head", AimbotSmooth = 0.1, AimbotFOV = 200, WallCheck = true, ShowFOV = true, HitboxExpander = false, HitboxSize = 10, Spinbot = false, SpinbotSpeed = 20},
    Visuals = {Enabled = false, GlowESP = false, SkeletonESP = false, Nametags = false, Tracers = false, BoxESP = false, VisibleColor = Color3.fromRGB(0, 255, 0), InvisibleColor = Color3.fromRGB(255, 0, 0), TeamCheck = false},
    Character = {WalkSpeed = 16, JumpPower = 50, FlyEnabled = false, FlySpeed = 50, NoclipEnabled = false, InfiniteJump = false, AntiRagdoll = false},
    Miscellaneous = {FullBright = false, AmbientColor = Color3.fromRGB(255, 255, 255), AntiAFK = false, FPSCap = 60, ClickTP = false, AutoReattach = false, AntiKick = true},
    CameraFOV = 70
}

local Connections, DrawingObjects, OriginalHitboxes, ESPObjects, FOVCircle = {}, {}, {}, {}, nil

print("[PhixBlox] Config initialized!")

-- Test UI Creation
print("[PhixBlox] Creating UI...")
local success, err = pcall(function()
    local Window = Library.new("PhixBlox v2.0 TEST")
    local TestPage = Window:addPage("Test", 5012544693)
    local TestSection = TestPage:addSection("Test Section")
    TestSection:addButton("Test Button", function()
        print("Button clicked!")
    end)
    Window:SelectPage(TestPage, true)
end)

if not success then
    error("[PhixBlox] UI Creation failed: " .. tostring(err))
    return
end

print("[PhixBlox] ✅ UI CREATED SUCCESSFULLY!")
print("[PhixBlox] If you can see the UI, the script is working!")
