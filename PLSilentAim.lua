local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local Settings = {
    Enabled = true,
    TeamCheck = true,
    WallCheck = true,
    DeathCheck = true,
    ForceFieldCheck = true,
    HitChance = 100,
    MissSpread = 5,
    FOV = 90,
    ShowFOV = true,
    ShowTargetLine = true,
    ToggleKey = Enum.KeyCode.RightShift,
    AimPart = "Head",
    RandomAimParts = false,
    AimPartsList = {"Head", "Torso", "HumanoidRootPart", "LeftArm", "RightArm", "LeftLeg", "RightLeg"}
}

local GunRemotes = ReplicatedStorage:WaitForChild("GunRemotes", 10)
local ShootEvent = GunRemotes and GunRemotes:WaitForChild("ShootEvent", 10)

if not ShootEvent then return end

local WallCheckParams = RaycastParams.new()
WallCheckParams.FilterType = Enum.RaycastFilterType.Exclude
WallCheckParams.IgnoreWater = true
WallCheckParams.RespectCanCollide = true

local Visuals = {
    Gui = nil,
    Circle = nil,
    Line = nil
}

local function CreateVisuals()
    local sg = Instance.new("ScreenGui")
    sg.Name = "SilentAimVisuals"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    
    pcall(function()
        sg.Parent = CoreGui
    end)
    if not sg.Parent then
        sg.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    Visuals.Gui = sg

    local circleFrame = Instance.new("Frame")
    circleFrame.Name = "FOVCircle"
    circleFrame.BackgroundTransparency = 1
    circleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    circleFrame.Visible = false
    circleFrame.Parent = sg

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 0, 0)
    stroke.Thickness = 2
    stroke.Transparency = 0.3
    stroke.Parent = circleFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = circleFrame

    Visuals.Circle = circleFrame

    local lineFrame = Instance.new("Frame")
    lineFrame.Name = "TargetLine"
    lineFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    lineFrame.BorderSizePixel = 0
    lineFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    lineFrame.Visible = false
    lineFrame.Parent = sg
    Visuals.Line = lineFrame
end

CreateVisuals()

local IsShooting = false
local LastShot = 0
local CurrentTarget = nil
local LastTargetUpdate = 0
local TARGET_UPDATE_INTERVAL = 0.05

local TracerPool = {
    bullets = {},
    tasers = {},
    maxPoolSize = 20
}

local function GetPooledPart(pool, createFunc)
    for i, part in ipairs(pool) do
        if not part.Parent then
            return table.remove(pool, i)
        end
    end
    if #pool < TracerPool.maxPoolSize then
        return createFunc()
    end
    return createFunc()
end

local function ReturnToPool(pool, part)
    part.Parent = nil
    if #pool < TracerPool.maxPoolSize then
        table.insert(pool, part)
    else
        part:Destroy()
    end
end

local function CreateBaseBulletPart()
    local bullet = Instance.new("Part")
    bullet.Name = "PooledBullet"
    bullet.Anchored = true
    bullet.CanCollide = false
    bullet.CastShadow = false
    bullet.Material = Enum.Material.Neon
    bullet.BrickColor = BrickColor.Yellow()
    
    local mesh = Instance.new("BlockMesh", bullet)
    mesh.Scale = Vector3.new(0.5, 0.5, 1)
    
    return bullet
end

local function CreateBaseTaserPart()
    local bullet = Instance.new("Part")
    bullet.Name = "PooledTaser"
    bullet.Anchored = true
    bullet.CanCollide = false
    bullet.CastShadow = false
    bullet.Material = Enum.Material.Neon
    bullet.BrickColor = BrickColor.new("Cyan")
    
    local mesh = Instance.new("BlockMesh", bullet)
    mesh.Scale = Vector3.new(0.8, 0.8, 1)
    
    return bullet
end

for i = 1, 5 do
    table.insert(TracerPool.bullets, CreateBaseBulletPart())
    table.insert(TracerPool.tasers, CreateBaseTaserPart())
end

local PartMappings = {
    ["Torso"] = {"Torso", "UpperTorso", "LowerTorso"},
    ["LeftArm"] = {"Left Arm", "LeftUpperArm", "LeftLowerArm", "LeftHand"},
    ["RightArm"] = {"Right Arm", "RightUpperArm", "RightLowerArm", "RightHand"},
    ["LeftLeg"] = {"Left Leg", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot"},
    ["RightLeg"] = {"Right Leg", "RightUpperLeg", "RightLowerLeg", "RightFoot"}
}

local function GetBodyPart(character, partName)
    if not character then return nil end
    
    local directPart = character:FindFirstChild(partName)
    if directPart then return directPart end

    local mappings = PartMappings[partName]
    if mappings then
        for _, name in ipairs(mappings) do
            local part = character:FindFirstChild(name)
            if part then return part end
        end
    end

    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
end

local function GetTargetPart(character)
    if not character then return nil end
    local partName
    if Settings.RandomAimParts then
        local partsList = Settings.AimPartsList
        partName = (partsList and #partsList > 0) and partsList[math.random(1, #partsList)] or "Head"
    else
        partName = Settings.AimPart
    end
    return GetBodyPart(character, partName)
end

local function GetMissPosition(targetPos)
    local x = math.random(-100, 100)
    local y = math.random(-100, 100)
    local z = math.random(-100, 100)
    local mag = math.sqrt(x*x + y*y + z*z)
    if mag > 0 then
        x, y, z = x/mag, y/mag, z/mag
    end
    return targetPos + Vector3.new(x * Settings.MissSpread, y * Settings.MissSpread, z * Settings.MissSpread)
end

local ActiveSounds = {}
local function PlayGunSound(gun)
    if not gun then return end
    local handle = gun:FindFirstChild("Handle")
    if not handle then return end

    local shootSound = handle:FindFirstChild("ShootSound")
    if shootSound then
        local soundKey = gun:GetFullName() .. "_shoot"
        local sound = ActiveSounds[soundKey]
        
        if not sound or not sound.Parent then
            sound = shootSound:Clone()
            sound.Parent = handle
            ActiveSounds[soundKey] = sound
        end
        
        sound:Play()
    end
end

local function CreateProjectileTracer(startPos, endPos, gun)
    local distance = (endPos - startPos).Magnitude
    local isTaser = gun:GetAttribute("Projectile") == "Taser"
    
    local bullet 
    if isTaser then
        bullet = GetPooledPart(TracerPool.tasers, CreateBaseTaserPart)
    else
        bullet = GetPooledPart(TracerPool.bullets, CreateBaseBulletPart)
    end

    bullet.Transparency = 0.5
    bullet.Size = Vector3.new(0.2, 0.2, distance)
    bullet.CFrame = CFrame.new(endPos, startPos) * CFrame.new(0, 0, -distance / 2)
    bullet.Parent = workspace
    
    local tweenInfo = TweenInfo.new(isTaser and 0.8 or 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    local fade = TweenService:Create(bullet, tweenInfo, { Transparency = 1 })
    
    fade:Play()
    fade.Completed:Once(function()
        if isTaser then
            ReturnToPool(TracerPool.tasers, bullet)
        else
            ReturnToPool(TracerPool.bullets, bullet)
        end
    end)
end

local function IsPlayerDead(plr)
    if not plr or not plr.Character then return true end
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    return not hum or hum.Health <= 0
end

local function HasForceField(plr)
    if not plr or not plr.Character then return false end
    return plr.Character:FindFirstChildOfClass("ForceField") ~= nil
end

local function IsWallBetween(startPos, endPos, targetCharacter)
    local myChar = LocalPlayer.Character
    if not myChar then return true end
    
    WallCheckParams.FilterDescendantsInstances = { myChar }
    local direction = endPos - startPos
    local distance = direction.Magnitude
    local result = workspace:Raycast(startPos, direction.Unit * distance, WallCheckParams)

    if not result then return false end
    
    local hitPart = result.Instance
    if targetCharacter and hitPart:IsDescendantOf(targetCharacter) then return false end

    if hitPart.Transparency >= 0.8 or not hitPart.CanCollide then
        return false 
    end
    return true
end

local function IsValidTargetQuick(plr)
    if not plr or plr == LocalPlayer or not plr.Character then return false end
    if not GetTargetPart(plr.Character) then return false end
    if Settings.DeathCheck and IsPlayerDead(plr) then return false end
    if Settings.ForceFieldCheck and HasForceField(plr) then return false end
    if Settings.TeamCheck and plr.Team == LocalPlayer.Team then return false end
    return true
end

local function IsValidTargetFull(plr)
    if not IsValidTargetQuick(plr) then return false end
    
    if Settings.WallCheck then
        local myChar = LocalPlayer.Character
        local myHead = myChar and myChar:FindFirstChild("Head")
        local targetPart = GetTargetPart(plr.Character)
        if myHead and targetPart then
            if IsWallBetween(myHead.Position, targetPart.Position, plr.Character) then 
                return false 
            end
        end
    end
    return true
end

local function RollHitChance()
    if Settings.HitChance >= 100 then return true end
    if Settings.HitChance <= 0 then return false end
    return math.random(1, 100) <= Settings.HitChance
end

local function GetClosestTarget()
    local camera = workspace.CurrentCamera
    if not camera then return nil end
    
    local mousePos = UserInputService:GetMouseLocation()
    local candidates = {}

    for _, plr in ipairs(Players:GetPlayers()) do
        if IsValidTargetQuick(plr) then
            local targetPart = GetTargetPart(plr.Character)
            if targetPart then
                local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < Settings.FOV then
                        table.insert(candidates, {player = plr, distance = dist})
                    end
                end
            end
        end
    end

    table.sort(candidates, function(a, b) return a.distance < b.distance end)

    for _, candidate in ipairs(candidates) do
        if IsValidTargetFull(candidate.player) then
            return candidate.player
        end
    end
    
    return nil
end

local function GetEquippedGun()
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and tool:GetAttribute("ToolType") == "Gun" then
            return tool
        end
    end
    return nil
end

local CachedBulletsLabel = nil
local function UpdateAmmoGUI(ammo, maxAmmo)
    pcall(function()
        if not CachedBulletsLabel or not CachedBulletsLabel.Parent then
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if not playerGui then return end
            local home = playerGui:FindFirstChild("Home")
            if not home then return end
            local hud = home:FindFirstChild("hud")
            if not hud then return end
            local gunFrame = hud:FindFirstChild("BottomRightFrame") and hud.BottomRightFrame:FindFirstChild("GunFrame")
            if not gunFrame then return end
            CachedBulletsLabel = gunFrame:FindFirstChild("BulletsLabel")
        end
        
        if CachedBulletsLabel then
            CachedBulletsLabel.Text = ammo .. "/" .. maxAmmo
        end
    end)
end

local function FireSilentAim(gun)
    local ammo = gun:GetAttribute("Local_CurrentAmmo") or 0
    if ammo <= 0 then return false end

    local fireRate = gun:GetAttribute("FireRate") or 0.12
    local now = tick()
    if now - LastShot < fireRate then return false end

    local char = LocalPlayer.Character
    local myHead = char and char:FindFirstChild("Head")
    if not myHead then return false end

    local hitPos, hitPart

    if Settings.Enabled and CurrentTarget and CurrentTarget.Character and IsValidTargetFull(CurrentTarget) then
        local targetPart = GetTargetPart(CurrentTarget.Character)
        if targetPart then
            if RollHitChance() then
                hitPos = targetPart.Position
                hitPart = targetPart
            else
                hitPos = GetMissPosition(targetPart.Position)
                hitPart = nil
            end
        end
    end

    if not hitPos then
        local mousePos = UserInputService:GetMouseLocation()
        local camera = workspace.CurrentCamera
        local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
        
        WallCheckParams.FilterDescendantsInstances = {char}
        local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, WallCheckParams)
        
        if result then
            hitPos = result.Position
            hitPart = result.Instance
        else
            hitPos = ray.Origin + (ray.Direction * 1000)
        end
    end

    gun:SetAttribute("Local_IsShooting", true)

    local muzzle = gun:FindFirstChild("Muzzle")
    local visualStart = muzzle and muzzle.Position or myHead.Position
    
    local projectileCount = gun:GetAttribute("ProjectileCount") or 1
    local bullets = table.create(projectileCount)
    for i = 1, projectileCount do
        bullets[i] = { myHead.Position, hitPos, hitPart }
    end

    LastShot = now
    PlayGunSound(gun)

    for i = 1, projectileCount do
        local ox = math.random(-10, 10) / 100
        local oy = math.random(-10, 10) / 100
        local oz = math.random(-10, 10) / 100
        CreateProjectileTracer(visualStart, hitPos + Vector3.new(ox, oy, oz), gun)
    end

    ShootEvent:FireServer(bullets)

    local newAmmo = ammo - 1
    gun:SetAttribute("Local_CurrentAmmo", newAmmo)
    UpdateAmmoGUI(newAmmo, gun:GetAttribute("MaxAmmo") or 0)

    return true
end

local function HandleAction(actionName, inputState, inputObject)
    if actionName == "SilentAimShoot" then
        if inputState == Enum.UserInputState.Begin then
            local gun = GetEquippedGun()
            if not gun then 
                return Enum.ContextActionResult.Pass 
            end
            
            if not gun:GetAttribute("AutoFire") then
                IsShooting = true
                FireSilentAim(gun)
                IsShooting = false
            else
                IsShooting = true
            end
            
            return Enum.ContextActionResult.Sink
        elseif inputState == Enum.UserInputState.End then
            IsShooting = false
            return Enum.ContextActionResult.Sink
        end
    end
    return Enum.ContextActionResult.Pass
end

pcall(function()
    ContextActionService:BindActionAtPriority("SilentAimShoot", HandleAction, false, 3000, Enum.UserInputType.MouseButton1)
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Settings.ToggleKey then
        Settings.Enabled = not Settings.Enabled
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "Silent Aim",
                Text = "Enabled: " .. tostring(Settings.Enabled),
                Duration = 3,
            })
        end)
    end
end)

RunService.RenderStepped:Connect(function()
    local mousePos = UserInputService:GetMouseLocation()
    
    if Visuals.Circle then
        Visuals.Circle.Visible = Settings.ShowFOV and Settings.Enabled
        if Visuals.Circle.Visible then
            Visuals.Circle.Size = UDim2.new(0, Settings.FOV * 2, 0, Settings.FOV * 2)
            Visuals.Circle.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)
        end
    end

    local now = tick()
    if Settings.Enabled and (now - LastTargetUpdate) >= TARGET_UPDATE_INTERVAL then
        LastTargetUpdate = now
        CurrentTarget = GetClosestTarget()
    elseif not Settings.Enabled then
        CurrentTarget = nil
    end

    if Visuals.Line then
        local shouldShow = Settings.ShowTargetLine and Settings.Enabled and CurrentTarget and CurrentTarget.Character
        Visuals.Line.Visible = shouldShow
        
        if shouldShow then
            local targetPart = GetTargetPart(CurrentTarget.Character)
            if targetPart then
                local camera = workspace.CurrentCamera
                local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                
                if onScreen then
                    local startPos = mousePos
                    local endPos = Vector2.new(screenPos.X, screenPos.Y)
                    local distance = (endPos - startPos).Magnitude
                    local center = (startPos + endPos) / 2
                    local rotation = math.atan2(endPos.Y - startPos.Y, endPos.X - startPos.X)
                    
                    Visuals.Line.Size = UDim2.new(0, distance, 0, 2)
                    Visuals.Line.Position = UDim2.new(0, center.X, 0, center.Y)
                    Visuals.Line.Rotation = math.deg(rotation)
                else
                    Visuals.Line.Visible = false
                end
            end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if not IsShooting then return end
    local gun = GetEquippedGun()
    if gun and gun:GetAttribute("AutoFire") then
        FireSilentAim(gun)
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    CachedBulletsLabel = nil
    CurrentTarget = nil
    IsShooting = false
    
    for key, sound in pairs(ActiveSounds) do
        if sound and sound.Parent then
            sound:Destroy()
        end
    end
    table.clear(ActiveSounds)
end)

pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "Silent Aim",
        Text = "Loaded, RShift toggle",
        Duration = 5,
    })
end)
