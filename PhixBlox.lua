--[[
    PhixBlox - Complete Roblox Utility Hub
    Structure: Westbound Style (6 Pages)
    Pages: Combat, Visuals, Character, Locations, Miscellaneous, Settings
]]

-- Load UI Library
local ok, Library = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/devanonaufal/phixblox/main/UILibrary.lua?t=" .. math.floor(tick())))()
end)
if not ok then
    warn("[PhixBlox] UI Library load error: " .. tostring(Library))
    return
end


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
        Nametags = false,
        Tracers = false,
        VisibleColor = Color3.fromRGB(0, 255, 0),
        InvisibleColor = Color3.fromRGB(255, 0, 0)
    },
    Character = {
        WalkSpeed = 16,
        JumpPower = 50,
        FlyEnabled = false,
        FlySpeed = 50,
        NoclipEnabled = false,
        InfiniteJump = false
    },
    Miscellaneous = {
        FullBright = false,
        AmbientColor = Color3.fromRGB(255, 255, 255),
        AntiAFK = false,
        FPSCap = 60,
        ClickTP = false,
        AutoReattach = false,
        AntiKick = false,
        GodMode = false,
        Gravity = 196.2
    },
    CameraFOV = 70
}

local Connections, DrawingObjects, OriginalHitboxes, ESPObjects, FOVCircle = {}, {}, {}, {}, nil


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

    if FreecamEnabled then
        -- Disable fly when freecam starts to avoid conflict
        Settings.Character.FlyEnabled = false
        -- Freeze character di tempat
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild('HumanoidRootPart')
            local hum = char:FindFirstChildOfClass('Humanoid')
            if hrp and not hrp:FindFirstChild('PhixFreezeBV') then
                local bv = Instance.new('BodyVelocity')
                bv.Name = 'PhixFreezeBV'
                bv.Velocity = Vector3.zero
                bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                bv.Parent = hrp
            end
            if hum then hum.WalkSpeed = 0 end
        end
        StartFreecam()
    else
        StopFreecam()
        -- Unfreeze character
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild('HumanoidRootPart')
            local bv = hrp and hrp:FindFirstChild('PhixFreezeBV')
            if bv then bv:Destroy() end
        end
        -- WalkSpeed akan di-restore oleh UpdateCharacter di Heartbeat berikutnya
    end
end

-- Config save/load
-- Color3 tidak bisa JSONEncode langsung → serialize ke {r,g,b,__color3=true}
local ConfigPath = "PhixBlox_Config.json"

local function SerializeSettings(tbl)
    local out = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            out[k] = SerializeSettings(v)
        elseif typeof(v) == "Color3" then
            out[k] = {r = v.R, g = v.G, b = v.B, __color3 = true}
        else
            out[k] = v
        end
    end
    return out
end

local function DeserializeSettings(data, target)
    for k, v in pairs(data) do
        if type(v) == "table" and v.__color3 then
            if target[k] ~= nil then target[k] = Color3.new(v.r, v.g, v.b) end
        elseif type(v) == "table" and target[k] ~= nil and type(target[k]) == "table" then
            DeserializeSettings(v, target[k])
        elseif target[k] ~= nil then
            target[k] = v
        end
    end
end

local function LoadConfig()
    pcall(function()
        local data = HttpService:JSONDecode(readfile(ConfigPath))
        DeserializeSettings(data, Settings)
    end)
end

local function SaveConfig()
    pcall(function()
        writefile(ConfigPath, HttpService:JSONEncode(SerializeSettings(Settings)))
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
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character, target.Parent}
    params.FilterType = Enum.RaycastFilterType.Exclude
    local origin = Camera.CFrame.Position
    local direction = (target.Position - origin)
    local result = Workspace:Raycast(origin, direction, params)
    return result == nil or result.Instance:IsDescendantOf(target.Parent)
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
    
    -- Noclip (restore CanCollide saat dimatikan)
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA('BasePart') then
            if Settings.Character.NoclipEnabled then
                v.CanCollide = false
            elseif v.Name ~= 'HumanoidRootPart' then
                v.CanCollide = true
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
    
end

-- Utilities
local function ClickTeleport()
    if not Settings.Miscellaneous.ClickTP or not LocalPlayer.Character then return end
    local hrp = LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
    if not hrp then return end
    -- Raycast ke posisi mouse
    local unitRay = Camera:ScreenPointToRay(Mouse.X, Mouse.Y)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    params.FilterType = Enum.RaycastFilterType.Exclude
    local result = Workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, params)
    if result then
        hrp.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0))
    end
end

-- Connect click teleport ke MouseButton1 saat fitur aktif
local clickTPConn
local function UpdateClickTPConn()
    if clickTPConn then clickTPConn:Disconnect(); clickTPConn = nil end
    if Settings.Miscellaneous.ClickTP then
        clickTPConn = UserInputService.InputBegan:Connect(function(inp, processed)
            if processed then return end
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                ClickTeleport()
            end
        end)
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

-- Anti-Kick (guard agar hookmetamethod tidak dobel)
local AntiKickHooked = false
local function InitAntiKick()
    if not Settings.Miscellaneous.AntiKick then return end
    if AntiKickHooked then return end
    if not hookmetamethod or not newcclosure or not getnamecallmethod then return end
    AntiKickHooked = true
    local OldNamecall
    OldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
        local self = ...
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

-- Anti AFK
local AntiAFKConn = nil
local function InitAntiAFK()
    if Settings.Miscellaneous.AntiAFK then
        if AntiAFKConn then return end -- already active
        local VirtualUser = game:GetService('VirtualUser')
        AntiAFKConn = LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    else
        if AntiAFKConn then
            AntiAFKConn:Disconnect()
            AntiAFKConn = nil
        end
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
    Workspace.Gravity = 196.2
    ToggleFullBright(false)
    -- Reset God Mode
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass('Humanoid')
        if hum then hum.MaxHealth = 100; hum.Health = 100 end
    end
    -- Stop Freecam if active
    FreecamEnabled = false; pcall(function() RunService:UnbindFromRenderStep('PhixFreecam') end)
    -- Destroy PhixBlox GUI
    local gui = game.Players.LocalPlayer.PlayerGui:FindFirstChild('Excusyz')
    if gui then gui:Destroy() end
    print('PhixBlox destroyed successfully')
end

-- UI BUILD (6 Pages: Combat, Visuals, Character, Locations, Miscellaneous, Settings)
local ok2, Window = pcall(function()
    return Library:CreateWindow({ Name = 'PhixBlox', Icon = 'box' })
end)
if not ok2 then
    warn("[PhixBlox] Window create error: " .. tostring(Window))
    return
end


-- Tab: Combat
local CombatTab = Window:CreateTab({ Name = 'Combat', Icon = 'crosshair' })
local CombatAimbot = CombatTab:CreateSection({ Name = 'Aimbot', Side = 'Left' })
CombatAimbot:CreateToggle({ Name = 'Enabled', Value = Settings.Combat.AimbotEnabled, Callback = function(v) Settings.Combat.AimbotEnabled = v; SaveConfig() end })
CombatAimbot:CreateToggle({ Name = 'Wall Check', Value = Settings.Combat.WallCheck, Callback = function(v) Settings.Combat.WallCheck = v; SaveConfig() end })
CombatAimbot:CreateToggle({ Name = 'Show FOV', Value = Settings.Combat.ShowFOV, Callback = function(v) Settings.Combat.ShowFOV = v; if FOVCircle then FOVCircle.Visible = v end; SaveConfig() end })
CombatAimbot:CreateSlider({ Name = 'Smooth', Min = 0, Max = 100, Value = Settings.Combat.AimbotSmooth * 100, Callback = function(v) Settings.Combat.AimbotSmooth = v / 100; SaveConfig() end })
CombatAimbot:CreateSlider({ Name = 'FOV', Min = 50, Max = 500, Value = Settings.Combat.AimbotFOV, Callback = function(v) Settings.Combat.AimbotFOV = v; if FOVCircle then FOVCircle.Radius = v end; SaveConfig() end })
local CombatExtra = CombatTab:CreateSection({ Name = 'Extras', Side = 'Right' })
CombatExtra:CreateToggle({ Name = 'Hitbox Expander', Value = Settings.Combat.HitboxExpander, Callback = function(v) Settings.Combat.HitboxExpander = v; SaveConfig() end })
CombatExtra:CreateSlider({ Name = 'Hitbox Size', Min = 1, Max = 30, Value = Settings.Combat.HitboxSize, Callback = function(v) Settings.Combat.HitboxSize = v; SaveConfig() end })
CombatExtra:CreateToggle({ Name = 'Spinbot', Value = Settings.Combat.Spinbot, Callback = function(v) Settings.Combat.Spinbot = v; SaveConfig() end })
CombatExtra:CreateSlider({ Name = 'Spinbot Speed', Min = 1, Max = 50, Value = Settings.Combat.SpinbotSpeed, Callback = function(v) Settings.Combat.SpinbotSpeed = v; SaveConfig() end })

local VisualsTab = Window:CreateTab({ Name = 'Visuals', Icon = 'eye' })
local VisualsSection = VisualsTab:CreateSection({ Name = 'ESP', Side = 'Left' })
VisualsSection:CreateToggle({ Name = 'Enabled', Value = Settings.Visuals.Enabled, Callback = function(v) Settings.Visuals.Enabled = v; SaveConfig() end })
VisualsSection:CreateToggle({ Name = 'Glow ESP', Value = Settings.Visuals.GlowESP, Callback = function(v) Settings.Visuals.GlowESP = v; SaveConfig() end })
VisualsSection:CreateToggle({ Name = 'Nametags', Value = Settings.Visuals.Nametags, Callback = function(v) Settings.Visuals.Nametags = v; SaveConfig() end })
VisualsSection:CreateToggle({ Name = 'Tracers', Value = Settings.Visuals.Tracers, Callback = function(v) Settings.Visuals.Tracers = v; SaveConfig() end })
local VisualsColor = VisualsTab:CreateSection({ Name = 'Colors', Side = 'Right' })
VisualsColor:CreateColorPicker({ Name = 'Visible Color', Color = Settings.Visuals.VisibleColor, Callback = function(r, g, b) Settings.Visuals.VisibleColor = Color3.fromRGB(r, g, b); SaveConfig() end })
VisualsColor:CreateColorPicker({ Name = 'Hidden Color', Color = Settings.Visuals.InvisibleColor, Callback = function(r, g, b) Settings.Visuals.InvisibleColor = Color3.fromRGB(r, g, b); SaveConfig() end })

local CharTab = Window:CreateTab({ Name = 'Character', Icon = 'user' })
local CharSection = CharTab:CreateSection({ Name = 'Movement', Side = 'Left' })
CharSection:CreateSlider({ Name = 'WalkSpeed', Min = 16, Max = 250, Value = Settings.Character.WalkSpeed, Callback = function(v) Settings.Character.WalkSpeed = v; SaveConfig() end })
CharSection:CreateSlider({ Name = 'JumpPower', Min = 50, Max = 500, Value = Settings.Character.JumpPower, Callback = function(v) Settings.Character.JumpPower = v; SaveConfig() end })
CharSection:CreateSlider({ Name = 'Fly Speed', Min = 10, Max = 200, Value = Settings.Character.FlySpeed, Callback = function(v) Settings.Character.FlySpeed = v; SaveConfig() end })
local CharSection2 = CharTab:CreateSection({ Name = 'Modes', Side = 'Right' })
CharSection2:CreateToggle({ Name = 'Fly', Value = Settings.Character.FlyEnabled, Callback = function(v) Settings.Character.FlyEnabled = v; SaveConfig() end })
CharSection2:CreateToggle({ Name = 'Noclip', Value = Settings.Character.NoclipEnabled, Callback = function(v) Settings.Character.NoclipEnabled = v; SaveConfig() end })
CharSection2:CreateToggle({ Name = 'Infinite Jump', Value = Settings.Character.InfiniteJump, Callback = function(v) Settings.Character.InfiniteJump = v; SaveConfig() end })

-- Locations
local playerList = {}
local function GetPlayerNames()
    playerList = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(playerList, p.Name) end
    end
    return playerList
end
GetPlayerNames()

-- helper: split by single char delimiter (string.split tidak ada di Lua standard)
local function splitStr(s, sep)
    local parts = {}
    for part in s:gmatch("([^" .. sep .. "]+)") do
        table.insert(parts, part)
    end
    return parts
end

-- Cycle player selector state
local selectedTP = playerList[1]
local coordText = "0,10,0"

local LocTab = Window:CreateTab({ Name = 'Locations', Icon = 'map-pin' })
local TPSection = LocTab:CreateSection({ Name = 'Teleport', Side = 'Left' })

TPSection:CreateTextBox({ Name = 'Coordinates', Placeholder = '0,10,0', Callback = function(v) coordText = v end })
TPSection:CreateButton({ Name = 'Teleport to Coordinates', Callback = function()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
    if not hrp then return end
    local parts = splitStr(coordText, ',')
    local x, y, z = tonumber(parts[1]), tonumber(parts[2]), tonumber(parts[3])
    if x and y and z then hrp.CFrame = CFrame.new(x, y, z) end
end })
TPSection:CreateButton({ Name = 'Copy My Position', Callback = function()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
    if not hrp then return end
    local p = hrp.Position
    local str = math.floor(p.X)..","..math.floor(p.Y)..","..math.floor(p.Z)
    coordText = str
    pcall(setclipboard, str)
end })

local PlayerSection = LocTab:CreateSection({ Name = 'Player TP', Side = 'Right' })
local ddList = PlayerSection:CreateDropdown({ Name = 'Select Player', List = playerList, Callback = function(v) selectedTP = v end })
PlayerSection:CreateButton({ Name = 'Refresh Player List', Callback = function()
    GetPlayerNames()
    ddList:Clear()
    for _, name in ipairs(playerList) do ddList:AddList(name) end
    selectedTP = playerList[1]
end })
PlayerSection:CreateButton({ Name = 'TP to Player', Callback = function()
    if not selectedTP then return end
    local target = Players:FindFirstChild(selectedTP)
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
    local thrp = target and target.Character and target.Character:FindFirstChild('HumanoidRootPart')
    if hrp and thrp then hrp.CFrame = thrp.CFrame * CFrame.new(0, 0, 3) end
end })
PlayerSection:CreateButton({ Name = 'TP Top Player', Callback = function()
    if not selectedTP then return end
    local target = Players:FindFirstChild(selectedTP)
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
    local thrp = target and target.Character and target.Character:FindFirstChild('HumanoidRootPart')
    if hrp and thrp then thrp.CFrame = hrp.CFrame * CFrame.new(0, 0, 3) end
end })

-- Tab: Misc
local MiscTab = Window:CreateTab({ Name = 'Misc', Icon = 'settings' })
local MiscSection = MiscTab:CreateSection({ Name = 'Utility', Side = 'Left' })
MiscSection:CreateToggle({ Name = 'Full Bright', Value = Settings.Miscellaneous.FullBright, Callback = function(v) Settings.Miscellaneous.FullBright = v; ToggleFullBright(v); SaveConfig() end })
MiscSection:CreateSlider({ Name = 'Camera FOV', Min = 70, Max = 120, Value = Settings.CameraFOV, Callback = function(v) Settings.CameraFOV = v; Camera.FieldOfView = v; SaveConfig() end })
MiscSection:CreateSlider({ Name = 'FPS Cap', Min = 60, Max = 360, Value = Settings.Miscellaneous.FPSCap, Callback = function(v) Settings.Miscellaneous.FPSCap = v; pcall(setfpscap, v); SaveConfig() end })
MiscSection:CreateSlider({ Name = 'Gravity', Min = 0, Max = 400, Value = Settings.Miscellaneous.Gravity, Callback = function(v) Settings.Miscellaneous.Gravity = v; Workspace.Gravity = v; SaveConfig() end })
MiscSection:CreateToggle({ Name = 'God Mode', Value = Settings.Miscellaneous.GodMode, Callback = function(v)
    Settings.Miscellaneous.GodMode = v
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass('Humanoid')
        if hum then hum.MaxHealth = v and math.huge or 100; if v then hum.Health = math.huge end end
    end
    SaveConfig()
end })
MiscSection:CreateToggle({ Name = 'Click Teleport', Value = Settings.Miscellaneous.ClickTP, Callback = function(v) Settings.Miscellaneous.ClickTP = v; UpdateClickTPConn(); SaveConfig() end })
MiscSection:CreateToggle({ Name = 'Anti AFK', Value = Settings.Miscellaneous.AntiAFK, Callback = function(v) Settings.Miscellaneous.AntiAFK = v; InitAntiAFK(); SaveConfig() end })
MiscSection:CreateToggle({ Name = 'Anti Kick', Value = Settings.Miscellaneous.AntiKick, Callback = function(v) Settings.Miscellaneous.AntiKick = v; if v then InitAntiKick() end; SaveConfig() end })
MiscSection:CreateToggle({ Name = 'Free Cam', Value = false, Callback = function(v) FreecamEnabled = v; InitFreecam() end })
local MiscTools = MiscTab:CreateSection({ Name = 'Tools', Side = 'Right' })
MiscTools:CreateButton({ Name = 'Server Hop', Callback = ServerHop })
MiscTools:CreateButton({ Name = 'Rejoin', Callback = Rejoin })
MiscTools:CreateButton({ Name = 'Infinite Yield', Callback = function()
    loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infinite-yield/master/infinite-yield.lua'))()
end })
MiscTools:CreateButton({ Name = 'Dex Explorer', Callback = function()
    loadstring(game:HttpGet('https://raw.githubusercontent.com/LorekeeperZinnia/Dex/master/Dex.lua'))()
end })

-- Tab: Settings
local SetTab = Window:CreateTab({ Name = 'Settings', Icon = 'cog' })
local SetSection = SetTab:CreateSection({ Name = 'Configuration', Side = 'Left' })
SetSection:CreateButton({ Name = 'Save Config', Callback = SaveConfig })
SetSection:CreateButton({ Name = 'Load Config', Callback = LoadConfig })
SetSection:CreateButton({ Name = 'Destroy Script', Callback = DestroyScript })

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
    -- Spinbot di RenderStepped agar tidak di-override physics engine
    if Settings.Combat.Spinbot and LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
        if hrp then
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(Settings.Combat.SpinbotSpeed), 0)
        end
    end
end))

table.insert(Connections, RunService.Heartbeat:Connect(function()
    UpdateCharacter()
    UpdateCombat()
end))

table.insert(Connections, UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        local gui = game.Players.LocalPlayer.PlayerGui:FindFirstChild('Excusyz')
        if gui then gui.Enabled = not gui.Enabled end
    end
    -- InfiniteJump: hook via StateChanged per-character (lebih reliable)
    if input.KeyCode == Enum.KeyCode.Space and Settings.Character.InfiniteJump and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass('Humanoid')
        if hum and hum.FloorMaterial ~= Enum.Material.Air then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end))

LoadConfig()
if Settings.Miscellaneous.AntiKick then InitAntiKick() end
InitAntiAFK()

-- Re-apply stats on respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    local hum = char:FindFirstChildOfClass('Humanoid')
    if hum then
        hum.WalkSpeed = Settings.Character.WalkSpeed
        hum.JumpPower = Settings.Character.JumpPower
        if Settings.Miscellaneous.GodMode then
            hum.MaxHealth = math.huge
            hum.Health = math.huge
        end
    end
    Workspace.Gravity = Settings.Miscellaneous.Gravity
end)

print('PhixBlox loaded')
