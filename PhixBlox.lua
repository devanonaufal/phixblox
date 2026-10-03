--[[
    PhixBlox v2.0 - Complete Roblox Utility Hub
    Structure: Westbound Style (6 Pages)
]]

print("[PhixBlox] Starting...")

-- Load UI Library
print("[PhixBlox] Loading UI Library...")
local success, Library = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/devanonaufal/phixblox/main/UILibrary.lua"))()
end)

if not success then
    error("[PhixBlox] UI Library failed: " .. tostring(Library))
    return
end
print("[PhixBlox] UI Library OK")

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

print("[PhixBlox] Services loaded")

-- Config
local Settings = {
    Combat = {AimbotEnabled = false, AimbotTarget = "Head", AimbotSmooth = 0.1, AimbotFOV = 200, WallCheck = true, ShowFOV = true, HitboxExpander = false, HitboxSize = 10, Spinbot = false, SpinbotSpeed = 20},
    Visuals = {Enabled = false, GlowESP = false, Nametags = false, Tracers = false, VisibleColor = Color3.fromRGB(0, 255, 0), InvisibleColor = Color3.fromRGB(255, 0, 0)},
    Character = {WalkSpeed = 16, JumpPower = 50, FlyEnabled = false, FlySpeed = 50, NoclipEnabled = false, InfiniteJump = false},
    Miscellaneous = {FullBright = false, AntiAFK = false, FPSCap = 60, ClickTP = false, AntiKick = true},
    CameraFOV = 70
}

local Connections, DrawingObjects, ESPObjects, FOVCircle = {}, {}, {}, nil

-- Basic functions
local function SaveConfig() pcall(function() writefile("PhixBlox.json", HttpService:JSONEncode(Settings)) end) end
local function LoadConfig() pcall(function() local data = HttpService:JSONDecode(readfile("PhixBlox.json")); for k,v in pairs(data) do if Settings[k] then for k2,v2 in pairs(v) do if Settings[k][k2] ~= nil then Settings[k][k2] = v2 end end end end end) end
local function CreateDrawing(t, p) if not Drawing then return nil end local d = Drawing.new(t); for k,v in pairs(p or {}) do d[k] = v end table.insert(DrawingObjects, d); return d end

print("[PhixBlox] Creating UI...")

-- UI
local Window = Library.new("PhixBlox v2.0")

local Combat = Window:addPage("Combat", 5012544693)
local CombatSection = Combat:addSection("Aimbot & Combat")
CombatSection:addToggle("Aimbot", Settings.Combat.AimbotEnabled, function(v) Settings.Combat.AimbotEnabled = v; SaveConfig() end)
CombatSection:addToggle("Show FOV", Settings.Combat.ShowFOV, function(v) Settings.Combat.ShowFOV = v; SaveConfig() end)
CombatSection:addSlider("FOV", Settings.Combat.AimbotFOV, 50, 500, function(v) Settings.Combat.AimbotFOV = v; if FOVCircle then FOVCircle.Radius = v end; SaveConfig() end)
CombatSection:addSlider("Smooth", Settings.Combat.AimbotSmooth * 100, 0, 100, function(v) Settings.Combat.AimbotSmooth = v/100; SaveConfig() end)

local Visuals = Window:addPage("Visuals", 5012544693)
local VisualsSection = Visuals:addSection("ESP")
VisualsSection:addToggle("Enabled", Settings.Visuals.Enabled, function(v) Settings.Visuals.Enabled = v; SaveConfig() end)
VisualsSection:addToggle("Glow ESP", Settings.Visuals.GlowESP, function(v) Settings.Visuals.GlowESP = v; SaveConfig() end)
VisualsSection:addToggle("Nametags", Settings.Visuals.Nametags, function(v) Settings.Visuals.Nametags = v; SaveConfig() end)
VisualsSection:addToggle("Tracers", Settings.Visuals.Tracers, function(v) Settings.Visuals.Tracers = v; SaveConfig() end)

local Character = Window:addPage("Character", 5012544693)
local CharSection = Character:addSection("Movement")
CharSection:addSlider("WalkSpeed", Settings.Character.WalkSpeed, 16, 250, function(v) Settings.Character.WalkSpeed = v; SaveConfig() end)
CharSection:addSlider("JumpPower", Settings.Character.JumpPower, 50, 500, function(v) Settings.Character.JumpPower = v; SaveConfig() end)
CharSection:addToggle("Fly", Settings.Character.FlyEnabled, function(v) Settings.Character.FlyEnabled = v; SaveConfig() end)
CharSection:addSlider("Fly Speed", Settings.Character.FlySpeed, 10, 200, function(v) Settings.Character.FlySpeed = v; SaveConfig() end)
CharSection:addToggle("Noclip", Settings.Character.NoclipEnabled, function(v) Settings.Character.NoclipEnabled = v; SaveConfig() end)

local Misc = Window:addPage("Miscellaneous", 5012544693)
local MiscSection = Misc:addSection("Utility")
MiscSection:addToggle("Full Bright", Settings.Miscellaneous.FullBright, function(v) Settings.Miscellaneous.FullBright = v; if v then Lighting.Brightness=2; Lighting.Ambient=Color3.new(1,1,1) end; SaveConfig() end)
MiscSection:addSlider("Camera FOV", Settings.CameraFOV, 70, 120, function(v) Settings.CameraFOV = v; Camera.FieldOfView = v; SaveConfig() end)
MiscSection:addToggle("Click TP (T)", Settings.Miscellaneous.ClickTP, function(v) Settings.Miscellaneous.ClickTP = v; SaveConfig() end)
MiscSection:addButton("Rejoin", function() game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer) end)

local SettingsPage = Window:addPage("Settings", 5012544693)
local SettingsSection = SettingsPage:addSection("Config")
SettingsSection:addButton("Save", SaveConfig)
SettingsSection:addButton("Load", LoadConfig)

Window:SelectPage(Combat, true)

print("[PhixBlox] UI created!")

-- FOV Circle
if Drawing then
    FOVCircle = CreateDrawing("Circle", {Thickness=2, NumSides=64, Radius=Settings.Combat.AimbotFOV, Filled=false, Visible=Settings.Combat.ShowFOV, Color=Color3.fromRGB(255,255,255), Transparency=1})
end

-- Main Loop
table.insert(Connections, RunService.RenderStepped:Connect(function()
    if FOVCircle and Settings.Combat.ShowFOV then
        FOVCircle.Position = UserInputService:GetMouseLocation()
        FOVCircle.Visible = true
    elseif FOVCircle then
        FOVCircle.Visible = false
    end
    
    -- Character mods
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = Settings.Character.WalkSpeed
            hum.JumpPower = Settings.Character.JumpPower
        end
        
        -- Fly
        if Settings.Character.FlyEnabled then
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local bv = hrp:FindFirstChild("PhixBloxFly") or Instance.new("BodyVelocity")
                bv.Name = "PhixBloxFly"
                bv.MaxForce = Vector3.new(9e9,9e9,9e9)
                local vel = Vector3.new(0,0,0)
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then vel = vel + Camera.CFrame.LookVector * Settings.Character.FlySpeed end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then vel = vel - Camera.CFrame.LookVector * Settings.Character.FlySpeed end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then vel = vel - Camera.CFrame.RightVector * Settings.Character.FlySpeed end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then vel = vel + Camera.CFrame.RightVector * Settings.Character.FlySpeed end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vel = vel + Vector3.new(0, Settings.Character.FlySpeed, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then vel = vel - Vector3.new(0, Settings.Character.FlySpeed, 0) end
                bv.Velocity = vel
                bv.Parent = hrp
            end
        end
        
        -- Noclip
        if Settings.Character.NoclipEnabled then
            for _,v in ipairs(LocalPlayer.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end
    end
    
    Camera.FieldOfView = Settings.CameraFOV
end))

-- Input
table.insert(Connections, UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then Window:toggle() end
    if input.KeyCode == Enum.KeyCode.T and Settings.Miscellaneous.ClickTP and LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local ray = Camera:ScreenPointToRay(Mouse.X, Mouse.Y)
            local params = RaycastParams.new()
            params.FilterDescendantsInstances = {LocalPlayer.Character}
            local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
            if result then hrp.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0)) end
        end
    end
end))

LoadConfig()
print("[PhixBlox] Loaded! Press Right Shift to toggle")
