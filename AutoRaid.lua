repeat task.wait() until game:IsLoaded()
assert(game.PlaceId == 13358463560, 'Game not supported')

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService('TweenService')
local TeleportService = game:GetService('TeleportService')

local Client = Players.LocalPlayer or Players:GetPropertyChangedSignal('LocalPlayer'):Connect(function()
    Client = Players.LocalPlayer
end)

local MobsFolder = workspace:WaitForChild('Mobs')
local EventsFolder = ReplicatedStorage:WaitForChild('Events')

local RaidServer = workspace:GetAttribute('BossServer')
local ActiveTween

if (RaidServer) then
    task.spawn(function()
        local StartTime = os.time()
        while os.time() - StartTime < getgenv().TimeBeforeKick do
            task.wait(1)
        end
        TeleportService:Teleport(13358463560)
    end)
    
    repeat task.wait() until #MobsFolder:GetChildren() > 0
else
    EventsFolder:WaitForChild('Raid'):FireServer()
    
    local PartyRemote = EventsFolder:WaitForChild('Party')
    PartyRemote:FireServer('Create', 'Christmas')
    PartyRemote:FireServer('Start')
end

local GetChar = function(Player)
    return Player and Player.Character
end

local GetRoot = function(Char)
    return Char and Char:FindFirstChild('HumanoidRootPart')
end

local GetHum = function(Char)
    return Char and Char:FindFirstChildWhichIsA('Humanoid')
end

local GetBackpack = function(Player)
    return Player and Player:FindFirstChildWhichIsA('Backpack')
end

local function EquipTool()
    local Char = GetChar(Client)
    local Hum = GetHum(Char)

    if not (Char and Hum) then return end

    local Tool = (function()
        local Backpack = GetBackpack(Client)
        
        for Index, Value in (Backpack and Backpack:GetChildren() or {}) do
            if (Value:IsA('Tool') and Value.Name == 'Combat') then
                return Value
            end
        end
    end)()

    if (Tool) then
        Hum:EquipTool(Tool)
    end

    return Char:FindFirstChildWhichIsA('Tool')
end

local function GetNearestMob()
    local Char = GetChar(Client)
    if not (MobsFolder and Char) then return end
    
    local Root = GetRoot(Char)
    if (not Root) then return end
    
    local ShortestDistance, NearestMob = math.huge
    for _, Mob in (MobsFolder:GetChildren()) do
        local MobHumanoid = GetHum(Mob)
        local MobRoot = GetRoot(Mob)
        
        if MobHumanoid and MobHumanoid.Health > 0 and MobRoot then
            local Distance = vector.magnitude(MobRoot.Position - Root.Position)

            if (Distance < ShortestDistance) then
                NearestMob = Mob
                ShortestDistance = Distance
            end
        end
    end

    return NearestMob
end

local function TweenToTarget(Target)
    local Char = GetChar(Client)
    if not Char then return end
    
    local HumanoidRootPart = GetRoot(Char)
    local TargetRoot = Target and GetRoot(Target)
    
    if not HumanoidRootPart or not TargetRoot or Target.Humanoid.Health <= 0 then return end
    
    local TweenCFrame = CFrame.new(TargetRoot.CFrame * CFrame.new(0, 0, -4).Position, TargetRoot.Position)
    
    if ActiveTween then ActiveTween:Cancel() end
    ActiveTween = TweenService:Create(HumanoidRootPart, TweenInfo.new(getgenv().Speed, Enum.EasingStyle.Linear), {CFrame = TweenCFrame})
    ActiveTween:Play()
end

shared.AutoFarmEnabled = not shared.AutoFarmEnabled
--print(shared.AutoFarmEnabled)

if (MobsFolder and RaidServer) then
    while (shared.AutoFarmEnabled and MobsFolder) do
        local NearestMob = GetNearestMob()
        local Char = GetChar(Client)

        if Char and NearestMob then
            TweenToTarget(NearestMob)
            
            local CombatTool = EquipTool()

            if (CombatTool) then
                EventsFolder:WaitForChild('Puts').OnClientInvoke = function() return true end
                CombatTool:Activate()
            end
        end

        task.wait()
    end
end
