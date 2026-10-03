--[[
    PhixBlox v2.0 - Complete Roblox Utility Hub
    Structure: Westbound Style (6 Pages)
    Pages: Combat, Visuals, Character, Locations, Miscellaneous, Settings
]]

-- Load UI Library  
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/devanonaufal/phixblox/main/UILibrary.lua"))()

-- Services
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

-- Config with all defaults
local Settings = {
    Combat = {
        AimbotEnabled = false,
        AimbotTarget = "Head",
        AimbotSmooth = 0.1,
        AimbotFOV = 200,
        WallCheck = false,
        ShowFOV = false,
        HitboxExpander = false,
        HitboxSize = 10,
        Spinbot = false,
        SpinbotSpeed = 20
    },
    Visuals = {
        Enabled = false,
        GlowESP = false,
        SkeletonESP = false,
        Nametags = false,
        Tracers = false,
        BoxESP = false,
        VisibleColor = Color3.fromRGB(0, 255, 0),
        InvisibleColor = Color3.fromRGB(255, 0, 0),
        TeamCheck = false
    },
    Character = {
        WalkSpeed = 16,
        JumpPower = 50,
        FlyEnabled = false,
        FlySpeed = 50,
        NoclipEnabled = false,
        InfiniteJump = false,
        AntiRagdoll = false
    },
    Miscellaneous = {
        FullBright = false,
        AmbientColor = Color3.fromRGB(255, 255, 255),
        AntiAFK = false,
        FPSCap = 60,
        ClickTP = false,
        AutoReattach = false,
        AntiKick = false
    },
    CameraFOV = 70
}

local Connections, DrawingObjects, OriginalHitboxes, ESPObjects, FOVCircle = {}, {}, {}, {}, nil
local AntiAFKActive = false

-- Freecam
local FreecamEnabled = false
local function InitFreecam()
    local ContextActionService = game:GetService('ContextActionService')
    local RunService = game:GetService('RunService')
    local pi, abs, clamp, exp, rad, sign, sqrt, tan = math.pi, math.abs, math.clamp, math.exp, math.rad, math.sign, math.sqrt, math.tan

    local NAV_GAIN, PAN_GAIN, FOV_GAIN = Vector3.new(1,1,1)*64, Vector2.new(0.75,1)*8, 300
    local PITCH_LIMIT = rad(90)
    local VEL_STIFFNESS, PAN_STIFFNESS, FOV_STIFFNESS = 1.5, 1.0, 4.0

    local Spring = {}
    Spring.__index = Spring
    function Spring.new(freq, pos)
        local s = setmetatable({}, Spring)
        s.f = freq; s.p = pos; s.v = pos*0; return s
    end
    function Spring:Update(dt, goal)
        local f = self.f*2*pi
        local offset = goal - self.p
        local decay = exp(-f*dt)
        local p1 = goal + (self.v*dt - offset*(f*dt+1))*decay
        self.v = (f*dt*(offset*f - self.v) + self.v)*decay
        self.p = p1; return p1
    end
    function Spring:Reset(pos) self.p = pos; self.v = pos*0 end

    local camPos, camRot, camFov = Vector3.new(), Vector2.new(), 70
    local velS = Spring.new(VEL_STIFFNESS, Vector3.new())
    local panS = Spring.new(PAN_STIFFNESS, Vector2.new())
    local fovS = Spring.new(FOV_STIFFNESS, 0)
    local mouseDelta, mouseWheel = Vector2.new(), 0

    local function StepFreecam(dt)
        -- pan from mouse
        local pan = panS:Update(dt, mouseDelta * (pi/64))
        mouseDelta = Vector2.new()
        -- fov from wheel
        local fov = fovS:Update(dt, mouseWheel)
        mouseWheel = 0
        -- nav from keyboard
        local kv = Vector3.new(
            (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0),
            (UserInputService:IsKeyDown(Enum.KeyCode.E) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.Q) and 1 or 0),
            (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0)
        )
        local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
        local vel = velS:Update(dt, kv * (shift and 0.25 or 1))
        local zf = sqrt(tan(rad(70/2))/tan(rad(camFov/2)))
        camFov = clamp(camFov + fov * FOV_GAIN * (dt/zf), 1, 120)
        camRot = camRot + pan * PAN_GAIN * (dt/zf)
        camRot = Vector2.new(clamp(camRot.x, -PITCH_LIMIT, PITCH_LIMIT), camRot.y % (2*pi))
        local cf = CFrame.new(camPos) * CFrame.fromOrientation(camRot.x, camRot.y, 0) * CFrame.new(vel * NAV_GAIN * dt)
        camPos = cf.p
        Camera.CFrame = cf
        Camera.Focus = cf * CFrame.new(0, 0, -50)
        Camera.FieldOfView = camFov
    end

    local mousePanConn, mouseWheelConn

    local function StartFreecam()
        local cf = Camera.CFrame
        camRot = Vector2.new(cf:ToEulerAnglesYXZ())
        camPos = cf.p
        camFov = Camera.FieldOfView
        velS:Reset(Vector3.new()); panS:Reset(Vector2.new()); fovS:Reset(0)
        Camera.CameraType = Enum.CameraType.Scriptable
        RunService:BindToRenderStep('PhixFreecam', Enum.RenderPriority.Camera.Value, StepFreecam)
        mousePanConn = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                mouseDelta = Vector2.new(-input.Delta.Y, -input.Delta.X)
            elseif input.UserInputType == Enum.UserInputType.MouseWheel then
                mouseWheel = -input.Position.Z
            end
        end)
    end

    local function StopFreecam()
        RunService:UnbindFromRenderStep('PhixFreecam')
        Camera.CameraType = Enum.CameraType.Custom
        Camera.FieldOfView = Settings.CameraFOV
        if mousePanConn then mousePanConn:Disconnect() end
    end

    if FreecamEnabled then StartFreecam() else StopFreecam() end
end

-- Config save/load
local ConfigPath = "PhixBlox_Config.json"
local function LoadConfig()
    pcall(function()
        local data = HttpService:JSONDecode(readfile(ConfigPath))
        for category, settings in pairs(data) do
            if Settings[category] and type(Settings[category]) == "table" then
                for k, v in pairs(settings) do
                    if Settings[category][k] ~= nil then
                        Settings[category][k] = v
                    end
                end
            elseif Settings[category] ~= nil then
                Settings[category] = data[category]
            end
        end
    end)
end

local function SaveConfig()
    pcall(function()
        writefile(ConfigPath, HttpService:JSONEncode(Settings))
    end)
end

-- Drawing helper
local function CreateDrawing(type, props)
    if not Drawing then return nil end
    local drawing = Drawing.new(type)
    for k, v in pairs(props or {}) do
        drawing[k] = v
    end
    table.insert(DrawingObjects, drawing)
    return drawing
end

-- Visibility check
local function IsVisible(target)
    if not Settings.Combat.WallCheck then return true end
    local origin = Camera.CFrame.Position
    local direction = (target.Position - origin)
    local ray = Ray.new(origin, direction)
    local part = Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, target.Parent})
    return part == nil or part:IsDescendantOf(target.Parent)
end

local function GetCharacterParts(char)
    return char:FindFirstChild('HumanoidRootPart'), char:FindFirstChild('Head'), char:FindFirstChild('Torso') or char:FindFirstChild('UpperTorso')
end

-- ESP System (Fixed: cleanup when disabled)
local function UpdateESP(plr)
    if not plr.Character or plr == LocalPlayer or not Settings.Visuals.Enabled then
        -- Cleanup ESP if disabled
        if ESPObjects[plr] then
            for _, obj in pairs(ESPObjects[plr]) do
                if obj and obj.Visible ~= nil then obj.Visible = false end
            end
        end
        return
    end
    
    local char = plr.Character
    local hum = char:FindFirstChildOfClass('Humanoid')
    local hrp, head = GetCharacterParts(char)
    if not hrp or not hum then return end
    
    ESPObjects[plr] = ESPObjects[plr] or {Tracer=nil, Nametag=nil, Skeleton={}}
    local esp = ESPObjects[plr]
    local visible = IsVisible(hrp)
    local color = visible and Settings.Visuals.VisibleColor or Settings.Visuals.InvisibleColor
    
    -- Tracers
    if Settings.Visuals.Tracers then
        if not esp.Tracer then
            esp.Tracer = CreateDrawing('Line', {Thickness=1, Transparency=1, Visible=false})
        end
        if esp.Tracer then
            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                esp.Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                esp.Tracer.To = Vector2.new(pos.X, pos.Y)
                esp.Tracer.Color = color
                esp.Tracer.Visible = true
            else
                esp.Tracer.Visible = false
            end
        end
    elseif esp.Tracer then
        esp.Tracer.Visible = false
    end
    
    -- Nametags (Fixed: hide when off-screen or disabled)
    if Settings.Visuals.Nametags and head then
        local pos, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1, 0))
        if onScreen then
            if not esp.Nametag then
                esp.Nametag = CreateDrawing('Text', {Size=16, Center=true, Outline=true, Font=2, Visible=false})
            end
            if esp.Nametag then
                esp.Nametag.Position = Vector2.new(pos.X, pos.Y)
                esp.Nametag.Text = plr.Name
                esp.Nametag.Color = color
                esp.Nametag.Visible = true
            end
        elseif esp.Nametag then
            esp.Nametag.Visible = false
        end
    elseif esp.Nametag then
        esp.Nametag.Visible = false
    end
    
    -- Glow ESP
    if Settings.Visuals.GlowESP then
        local highlight = char:FindFirstChildOfClass('Highlight')
        if not highlight then
            highlight = Instance.new('Highlight')
            highlight.Name = 'PhixBloxESP'
            highlight.FillColor = color
            highlight.OutlineColor = color
            highlight.FillTransparency = 0.5
            highlight.OutlineTransparency = 0
            highlight.Parent = char
        else
            highlight.FillColor = color
            highlight.OutlineColor = color
        end
    else
        local highlight = char:FindFirstChildOfClass('Highlight')
        if highlight and highlight.Name == 'PhixBloxESP' then
            highlight:Destroy()
        end
    end
end

-- Aimbot
local function GetClosestPlayer()
    local closest, shortest = nil, Settings.Combat.AimbotFOV
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local part = plr.Character:FindFirstChild(Settings.Combat.AimbotTarget)
            if part then
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local mousePos = UserInputService:GetMouseLocation()
                    local distance = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                    if distance < shortest and (not Settings.Combat.WallCheck or IsVisible(part)) then
                        closest, shortest = plr, distance
                    end
                end
            end
        end
    end
    return closest
end

local function UpdateAimbot()
    if not Settings.Combat.AimbotEnabled or not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
    local target = GetClosestPlayer()
    if target and target.Character then
        local part = target.Character:FindFirstChild(Settings.Combat.AimbotTarget)
        if part then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, part.Position), Settings.Combat.AimbotSmooth)
        end
    end
end

-- Character (Fixed: cleanup fly BodyVelocity when disabled)
local function UpdateCharacter()
    local char = LocalPlayer.Character
    if not char then return end
    
    local hum = char:FindFirstChildOfClass('Humanoid')
    if hum then
        hum.WalkSpeed = Settings.Character.WalkSpeed
        hum.JumpPower = Settings.Character.JumpPower
    end
    
    -- Fly (Fixed cleanup)
    local hrp = char:FindFirstChild('HumanoidRootPart')
    if Settings.Character.FlyEnabled and hrp then
        local bv = hrp:FindFirstChild('PhixBloxFly')
        if not bv then
            bv = Instance.new('BodyVelocity')
            bv.Name = 'PhixBloxFly'
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bv.Parent = hrp
        end
        
        local vel = Vector3.new(0, 0, 0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then vel = vel + Camera.CFrame.LookVector * Settings.Character.FlySpeed end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then vel = vel - Camera.CFrame.LookVector * Settings.Character.FlySpeed end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then vel = vel - Camera.CFrame.RightVector * Settings.Character.FlySpeed end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then vel = vel + Camera.CFrame.RightVector * Settings.Character.FlySpeed end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vel = vel + Vector3.new(0, Settings.Character.FlySpeed, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then vel = vel - Vector3.new(0, Settings.Character.FlySpeed, 0) end
        bv.Velocity = vel
    elseif hrp then
        -- Cleanup fly when disabled
        local bv = hrp:FindFirstChild('PhixBloxFly')
        if bv then
            bv:Destroy()
        end
    end
    
    -- Noclip
    if Settings.Character.NoclipEnabled then
        for _, v in ipairs(char:GetDescendants()) do
            if v:IsA('BasePart') then
                v.CanCollide = false
            end
        end
    end
end

-- Combat
local function UpdateCombat()
    -- Hitbox Expander
    if Settings.Combat.HitboxExpander then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local hrp = plr.Character:FindFirstChild('HumanoidRootPart')
                if hrp then
                    if not OriginalHitboxes[plr] then
                        OriginalHitboxes[plr] = hrp.Size
                    end
                    hrp.Size = Vector3.new(Settings.Combat.HitboxSize, Settings.Combat.HitboxSize, Settings.Combat.HitboxSize)
                    hrp.Transparency = 0.8
                    hrp.CanCollide = false
                end
            end
        end
    else
        -- Restore hitboxes
        for plr, size in pairs(OriginalHitboxes) do
            if plr.Character then
                local hrp = plr.Character:FindFirstChild('HumanoidRootPart')
                if hrp then
                    hrp.Size = size
                    hrp.Transparency = 1
                    hrp.CanCollide = true
                end
            end
        end
        OriginalHitboxes = {}
    end
    
    -- Spinbot
    if Settings.Combat.Spinbot and LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
        if hrp then
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(Settings.Combat.SpinbotSpeed), 0)
        end
    end
end

-- Utilities
local function ClickTeleport()
    if not Settings.Miscellaneous.ClickTP or not LocalPlayer.Character then return end
    local hrp = LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
    if not hrp then return end
    
    local ray = Camera:ScreenPointToRay(Mouse.X, Mouse.Y)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    params.FilterType = Enum.RaycastFilterType.Exclude
    
    local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
    if result then
        hrp.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0))
    end
end

local function ServerHop()
    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/'..game.PlaceId..'/servers/Public?sortOrder=Asc&limit=100'))
    end)
    if success and result.data then
        for _, srv in ipairs(result.data) do
            if srv.playing < srv.maxPlayers and srv.id ~= game.JobId then
                game:GetService('TeleportService'):TeleportToPlaceInstance(game.PlaceId, srv.id)
                return
            end
        end
    end
end

local function Rejoin()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end

-- Anti-Kick
local function InitAntiKick()
    if not Settings.Miscellaneous.AntiKick then return end
    if not hookmetamethod or not newcclosure or not getnamecallmethod then return end
    local OldNamecall
    OldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
        local self, msg = ...
        if getnamecallmethod() == "Kick" and self == LocalPlayer and Settings.Miscellaneous.AntiKick then
            return
        end
        return OldNamecall(...)
    end))
end

-- Full Bright
local OriginalLighting = {}
local function ToggleFullBright(enabled)
    if enabled then
        OriginalLighting = {
            Brightness = Lighting.Brightness,
            Ambient = Lighting.Ambient,
            OutdoorAmbient = Lighting.OutdoorAmbient
        }
        Lighting.Brightness = 2
        Lighting.Ambient = Settings.Miscellaneous.AmbientColor
        Lighting.OutdoorAmbient = Settings.Miscellaneous.AmbientColor
    else
        for k, v in pairs(OriginalLighting) do
            Lighting[k] = v
        end
    end
end

-- Anti AFK (Fixed: prevent duplicate connections)
local function InitAntiAFK()
    if Settings.Miscellaneous.AntiAFK and not AntiAFKActive then
        AntiAFKActive = true
        local VirtualUser = game:GetService("VirtualUser")
        table.insert(Connections, LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end))
    end
end

-- Cleanup
local function DestroyScript()
    for _, c in ipairs(Connections) do
        c:Disconnect()
    end
    
    for _, d in ipairs(DrawingObjects) do
        d:Remove()
    end
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then
            local h = plr.Character:FindFirstChildOfClass('Highlight')
            if h and h.Name == 'PhixBloxESP' then
                h:Destroy()
            end
        end
    end
    
    for plr, size in pairs(OriginalHitboxes) do
        if plr.Character then
            local hrp = plr.Character:FindFirstChild('HumanoidRootPart')
            if hrp then
                hrp.Size = size
                hrp.Transparency = 1
                hrp.CanCollide = true
            end
        end
    end
    
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass('Humanoid')
        if hum then
            hum.WalkSpeed = 16
            hum.JumpPower = 50
        end
        
        local hrp = LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
        if hrp then
            local bv = hrp:FindFirstChild('PhixBloxFly')
            if bv then
                bv:Destroy()
            end
        end
    end
    
    Camera.FieldOfView = 70
    ToggleFullBright(false)
    
    print('PhixBlox destroyed successfully')
end

-- UI BUILD (6 Pages: Combat, Visuals, Character, Locations, Miscellaneous, Settings)
local Window = Library.new('PhixBlox v2.0')

local Theme = {
    Background    = Color3.fromRGB(10, 20, 30),
    Glow          = Color3.fromRGB(100, 180, 230),
    Accent        = Color3.fromRGB(15, 30, 45),
    LightContrast = Color3.fromRGB(30, 45, 60),
    DarkContrast  = Color3.fromRGB(20, 30, 40),
    TextColor     = Color3.fromRGB(170, 250, 255)
}

for key, color in pairs(Theme) do
    Window:setTheme(key, color)
end

local Combat = Window:addPage('Combat', 5012544693)
local CombatAimbot = Combat:addSection('Aimbot')
CombatAimbot:addToggle('Enabled', Settings.Combat.AimbotEnabled, function(v) Settings.Combat.AimbotEnabled = v; SaveConfig() end)
CombatAimbot:addToggle('Wall Check', Settings.Combat.WallCheck, function(v) Settings.Combat.WallCheck = v; SaveConfig() end)
CombatAimbot:addToggle('Show FOV', Settings.Combat.ShowFOV, function(v) Settings.Combat.ShowFOV = v; if FOVCircle then FOVCircle.Visible = v end; SaveConfig() end)
CombatAimbot:addSlider('Smooth', Settings.Combat.AimbotSmooth * 100, 0, 100, function(v) Settings.Combat.AimbotSmooth = v / 100; SaveConfig() end)
CombatAimbot:addSlider('FOV', Settings.Combat.AimbotFOV, 50, 500, function(v) Settings.Combat.AimbotFOV = v; if FOVCircle then FOVCircle.Radius = v end; SaveConfig() end)
CombatAimbot:addToggle('Hitbox Expander', Settings.Combat.HitboxExpander, function(v) Settings.Combat.HitboxExpander = v; SaveConfig() end)
CombatAimbot:addSlider('Hitbox Size', Settings.Combat.HitboxSize, 1, 30, function(v) Settings.Combat.HitboxSize = v; SaveConfig() end)
CombatAimbot:addToggle('Spinbot', Settings.Combat.Spinbot, function(v) Settings.Combat.Spinbot = v; SaveConfig() end)
CombatAimbot:addSlider('Spinbot Speed', Settings.Combat.SpinbotSpeed, 1, 50, function(v) Settings.Combat.SpinbotSpeed = v; SaveConfig() end)

Window:SelectPage(Combat, true)

local Visuals = Window:addPage('Visuals', 5012544693)
local VisualsSection = Visuals:addSection('General')
VisualsSection:addToggle('Enabled', Settings.Visuals.Enabled, function(v) Settings.Visuals.Enabled = v; SaveConfig() end)
VisualsSection:addToggle('Team Check', Settings.Visuals.TeamCheck, function(v) Settings.Visuals.TeamCheck = v; SaveConfig() end)
VisualsSection:addToggle('Glow ESP', Settings.Visuals.GlowESP, function(v) Settings.Visuals.GlowESP = v; SaveConfig() end)
VisualsSection:addToggle('Skeleton ESP', Settings.Visuals.SkeletonESP, function(v) Settings.Visuals.SkeletonESP = v; SaveConfig() end)
VisualsSection:addToggle('Nametags', Settings.Visuals.Nametags, function(v) Settings.Visuals.Nametags = v; SaveConfig() end)
VisualsSection:addToggle('Tracers', Settings.Visuals.Tracers, function(v) Settings.Visuals.Tracers = v; SaveConfig() end)
VisualsSection:addToggle('Box ESP', Settings.Visuals.BoxESP, function(v) Settings.Visuals.BoxESP = v; SaveConfig() end)
VisualsSection:addColorPicker('Visible Color', Settings.Visuals.VisibleColor, function(v) Settings.Visuals.VisibleColor = v; SaveConfig() end)
VisualsSection:addColorPicker('Hidden Color', Settings.Visuals.InvisibleColor, function(v) Settings.Visuals.InvisibleColor = v; SaveConfig() end)

local Character = Window:addPage('Character', 5012544693)
local CharacterSection = Character:addSection('Movement')
CharacterSection:addSlider('WalkSpeed', Settings.Character.WalkSpeed, 16, 250, function(v) Settings.Character.WalkSpeed = v; SaveConfig() end)
CharacterSection:addSlider('JumpPower', Settings.Character.JumpPower, 50, 500, function(v) Settings.Character.JumpPower = v; SaveConfig() end)
CharacterSection:addToggle('Fly', Settings.Character.FlyEnabled, function(v) Settings.Character.FlyEnabled = v; SaveConfig() end)
CharacterSection:addSlider('Fly Speed', Settings.Character.FlySpeed, 10, 200, function(v) Settings.Character.FlySpeed = v; SaveConfig() end)
CharacterSection:addToggle('Noclip', Settings.Character.NoclipEnabled, function(v) Settings.Character.NoclipEnabled = v; SaveConfig() end)
CharacterSection:addToggle('Infinite Jump', Settings.Character.InfiniteJump, function(v) Settings.Character.InfiniteJump = v; SaveConfig() end)

local Locations = Window:addPage('Locations', 5012544693)
local LocationsSection = Locations:addSection('Teleport')
LocationsSection:addButton('Spawn', function()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
    if hrp then hrp.CFrame = CFrame.new(0, 50, 0) end
end)
LocationsSection:addButton('Random Player', function()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then table.insert(list, p) end
    end
    if #list == 0 then return end
    local target = list[math.random(#list)]
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
    local thrp = target and target.Character and target.Character:FindFirstChild('HumanoidRootPart')
    if hrp and thrp then hrp.CFrame = thrp.CFrame * CFrame.new(0, 0, 3) end
end)

local Misc = Window:addPage('Miscellaneous', 5012544693)
local MiscSection = Misc:addSection('Utility')
MiscSection:addToggle('Full Bright', Settings.Miscellaneous.FullBright, function(v) Settings.Miscellaneous.FullBright = v; ToggleFullBright(v); SaveConfig() end)
MiscSection:addSlider('Camera FOV', Settings.CameraFOV, 70, 120, function(v) Settings.CameraFOV = v; Camera.FieldOfView = v; SaveConfig() end)
MiscSection:addSlider('FPS Cap', Settings.Miscellaneous.FPSCap, 60, 360, function(v) Settings.Miscellaneous.FPSCap = v; pcall(setfpscap, v); SaveConfig() end)
MiscSection:addToggle('Click Teleport', Settings.Miscellaneous.ClickTP, function(v) Settings.Miscellaneous.ClickTP = v; SaveConfig() end)
MiscSection:addToggle('Anti AFK', Settings.Miscellaneous.AntiAFK, function(v) Settings.Miscellaneous.AntiAFK = v; InitAntiAFK(); SaveConfig() end)
MiscSection:addToggle('Anti Kick', Settings.Miscellaneous.AntiKick, function(v) Settings.Miscellaneous.AntiKick = v; if v then InitAntiKick() end; SaveConfig() end)
MiscSection:addToggle('Free Cam', false, function(v) FreecamEnabled = v; InitFreecam() end)
MiscSection:addButton('Server Hop', ServerHop)
MiscSection:addButton('Rejoin', Rejoin)

local SettingsPage = Window:addPage('Settings', 5012544693)
local SettingsSection = SettingsPage:addSection('Configuration')
SettingsSection:addButton('Save Config', SaveConfig)
SettingsSection:addButton('Load Config', LoadConfig)
SettingsSection:addButton('Destroy Script', DestroyScript)

if Drawing then
    FOVCircle = CreateDrawing('Circle', {Thickness = 2, NumSides = 64, Radius = Settings.Combat.AimbotFOV, Filled = false, Visible = Settings.Combat.ShowFOV, Color = Color3.fromRGB(255, 255, 255), Transparency = 1})
end

table.insert(Connections, RunService.RenderStepped:Connect(function()
    if FOVCircle then
        FOVCircle.Position = UserInputService:GetMouseLocation()
        FOVCircle.Radius = Settings.Combat.AimbotFOV
        FOVCircle.Visible = Settings.Combat.ShowFOV
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then UpdateESP(player) end
    end
    UpdateAimbot()
end))

table.insert(Connections, RunService.Heartbeat:Connect(function()
    UpdateCharacter()
    UpdateCombat()
end))

table.insert(Connections, UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then Window:toggle() end
    if input.KeyCode == Enum.KeyCode.T and Settings.Miscellaneous.ClickTP then ClickTeleport() end
    if input.KeyCode == Enum.KeyCode.Space and Settings.Character.InfiniteJump and LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass('Humanoid')
        if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

LoadConfig()
if Settings.Miscellaneous.AntiKick then InitAntiKick() end
InitAntiAFK()
print('PhixBlox loaded')
