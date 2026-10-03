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
        WallCheck = true,
        ShowFOV = true,
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
        AntiKick = true
    },
    CameraFOV = 70
}

local Connections, DrawingObjects, OriginalHitboxes, ESPObjects, FOVCircle = {}, {}, {}, {}, nil
local AntiAFKActive = false

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
    
    Camera.FieldOfView = Settings.CameraFOV
end

-- Utilities
local function ClickTeleport()
    if not Settings.Miscellaneous.ClickTP or not LocalPlayer.Character then return end
    local hrp = LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
    if not hrp then return end
    
    local ray = Camera:ScreenPointToRay(Mouse.X, Mouse.Y)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    params.FilterType = Enum.RaycastFilterType.Blacklist
    
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
