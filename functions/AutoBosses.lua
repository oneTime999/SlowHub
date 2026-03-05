local Tab = _G.BossesTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local bossList = {
    "AnosBoss", "GilgameshBoss", "RimuruBoss", "StrongestofTodayBoss", "StrongestinHistoryBoss", "IchigoBoss", "AizenBoss", "AlucardBoss", "QinShiBoss", "JinwooBoss",
    "SukunaBoss", "GojoBoss", "SaberBoss", "YujiBoss"
}

local difficulties = {"_Normal", "_Medium", "_Hard", "_Extreme"}

local BossSafeZones = {
    ["AnosBoss"] = CFrame.new(950.0978393554688, -0.23529791831970215, 1378.4510498046875),
    ["GilgameshBoss"] = CFrame.new(828.11, -0.39, -1130.76),
    ["RimuruBoss"] = CFrame.new(-1363.4713134765625, 30.04159164428711, 221.3505859375),
    ["StrongestofTodayBoss"] = CFrame.new(181.69, 5.24, -2446.61),
    ["StrongestinHistoryBoss"] = CFrame.new(639.29, 3.67, -2273.30),
    ["IchigoBoss"] = CFrame.new(828.11, -0.39, -1130.76),
    ["AizenBoss"] = CFrame.new(-567.22, 2.57, 1228.49),
    ["AlucardBoss"] = CFrame.new(248.74, 12.09, 927.54),
    ["QinShiBoss"] = CFrame.new(828.11, -0.39, -1130.76),
    ["SaberBoss"] = CFrame.new(828.11, -0.39, -1130.76),
    ["JinwooBoss"] = CFrame.new(248.74, 12.09, 927.54),
    ["SukunaBoss"] = CFrame.new(1571.26, 77.22, -34.11),
    ["GojoBoss"] = CFrame.new(1858.32, 12.98, 338.14),
    ["YujiBoss"] = CFrame.new(1537.92, 12.98, 226.10)
}

for _, bossBaseName in ipairs(bossList) do
    if BossSafeZones[bossBaseName] then
        for _, diff in ipairs(difficulties) do
            BossSafeZones[bossBaseName .. diff] = BossSafeZones[bossBaseName]
        end
    end
end

local State = {
    Connection = nil,
    IsRunning = false,
    CurrentBoss = nil,
    LastTarget = nil,
    HasVisitedSafeZone = false,
    LastHitTime = 0,
    Character = nil,
    HumanoidRootPart = nil,
    NPCsFolder = nil
}

local function InitializeState()
    State.Character = Player.Character
    State.HumanoidRootPart = State.Character and State.Character:FindFirstChild("HumanoidRootPart")
    State.NPCsFolder = workspace:FindFirstChild("NPCs")
end

InitializeState()

Player.CharacterAdded:Connect(function(char)
    State.Character = char
    State.HumanoidRootPart = nil
    task.wait(0.1)
    State.HumanoidRootPart = char:FindFirstChild("HumanoidRootPart")
end)

workspace.ChildAdded:Connect(function(child)
    if child.Name == "NPCs" then
        State.NPCsFolder = child
    end
end)

local function GetHumanoid(model)
    if not model or not model.Parent then return nil end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health > 0 then
        return humanoid
    end
    return nil
end

local function IsAlive(model)
    return GetHumanoid(model) ~= nil
end

local function GetBossBaseName(bossName)
    for _, baseName in ipairs(bossList) do
        if bossName == baseName then
            return baseName
        end
        if string.sub(bossName, 1, #baseName) == baseName then
            return baseName
        end
    end
    return nil
end

local function IsBossSelected(bossName)
    local baseName = GetBossBaseName(bossName)
    if not baseName then return false end
    return _G.SlowHub.SelectedBosses[baseName] == true
end

local function GetSafeZone(bossName)
    local directSafeZone = BossSafeZones[bossName]
    if directSafeZone then
        return directSafeZone
    end
    local baseName = GetBossBaseName(bossName)
    if baseName then
        return BossSafeZones[baseName]
    end
    return nil
end

local function GetPityCount()
    local success, result = pcall(function()
        local playerGui = Player:FindFirstChild("PlayerGui")
        if not playerGui then return nil end
        local bossUI = playerGui:FindFirstChild("BossUI")
        if not bossUI then return nil end
        local mainFrame = bossUI:FindFirstChild("MainFrame")
        if not mainFrame then return nil end
        local bossHPBar = mainFrame:FindFirstChild("BossHPBar")
        if not bossHPBar then return nil end
        local pityLabel = bossHPBar:FindFirstChild("Pity")
        if not pityLabel then return nil end
        return pityLabel.Text
    end)
    if success and result then
        local currentPity = string.match(result, "Pity: (%d+)/25")
        if currentPity then
            return tonumber(currentPity)
        end
    end
    return 0
end

local function IsPityTargetTime()
    if not _G.SlowHub.PriorityPityEnabled then return false end
    if _G.SlowHub.PityTargetBoss == "" then return false end
    return GetPityCount() >= 24
end

local function ShouldSwitchBoss(currentBoss)
    if not currentBoss or not currentBoss.Parent then return true end
    if not IsAlive(currentBoss) then return true end
    local bossBaseName = GetBossBaseName(currentBoss.Name)
    if not bossBaseName then return true end
    if not IsBossSelected(bossBaseName) then return true end
    if _G.SlowHub.PriorityPityEnabled and _G.SlowHub.PityTargetBoss ~= "" then
        local isPityTime = IsPityTargetTime()
        local pityTarget = _G.SlowHub.PityTargetBoss
        if isPityTime then
            if bossBaseName ~= pityTarget then return true end
        else
            if bossBaseName == pityTarget then return true end
        end
    end
    return false
end

local function FindBossByName(bossName)
    if not State.NPCsFolder then return nil end
    local exactMatch = State.NPCsFolder:FindFirstChild(bossName)
    if exactMatch and IsAlive(exactMatch) then
        return exactMatch
    end
    for _, diff in ipairs(difficulties) do
        local variantName = bossName .. diff
        local variant = State.NPCsFolder:FindFirstChild(variantName)
        if variant and IsAlive(variant) then
            return variant
        end
    end
    return nil
end

local function FindValidBoss()
    if not State.NPCsFolder then return nil end
    local pityEnabled = _G.SlowHub.PriorityPityEnabled
    local pityTarget = _G.SlowHub.PityTargetBoss
    if pityEnabled and pityTarget ~= "" then
        if IsPityTargetTime() then
            if IsBossSelected(pityTarget) then
                return FindBossByName(pityTarget)
            end
            return nil
        else
            for _, bossName in ipairs(bossList) do
                if bossName ~= pityTarget and IsBossSelected(bossName) then
                    local found = FindBossByName(bossName)
                    if found then return found end
                end
            end
            return nil
        end
    end
    for bossName, isSelected in pairs(_G.SlowHub.SelectedBosses) do
        if isSelected then
            local found = FindBossByName(bossName)
            if found then return found end
        end
    end
    return nil
end

local function EquipWeapon()
    if not _G.SlowHub.SelectedWeapon then return end
    local success = pcall(function()
        if not State.Character then return end
        local humanoid = State.Character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        local hasEquipped = State.Character:FindFirstChild(_G.SlowHub.SelectedWeapon)
        if hasEquipped then return end
        local backpack = Player:FindFirstChild("Backpack")
        if not backpack then return end
        local weapon = backpack:FindFirstChild(_G.SlowHub.SelectedWeapon)
        if weapon then
            humanoid:EquipTool(weapon)
        end
    end)
    return success
end

local function TeleportToSafeZone(boss)
    if not State.HumanoidRootPart then return false end
    local safeCFrame = GetSafeZone(boss.Name)
    if not safeCFrame then
        return true
    end
    State.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
    State.HumanoidRootPart.CFrame = safeCFrame
    return true
end

local function TeleportToBoss(boss)
    if not State.HumanoidRootPart then return false end
    local bossRoot = boss:FindFirstChild("HumanoidRootPart")
    if not bossRoot then return false end
    State.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
    local offset = CFrame.new(0, _G.SlowHub.BossFarmHeight, _G.SlowHub.BossFarmDistance)
    State.HumanoidRootPart.CFrame = bossRoot.CFrame * offset
    return true
end

local function PerformAttack()
    local currentTime = tick()
    local cooldown = _G.SlowHub.BossFarmCooldown
    if currentTime - State.LastHitTime < cooldown then
        return
    end
    State.LastHitTime = currentTime
    pcall(function()
        local combatSystem = ReplicatedStorage:FindFirstChild("CombatSystem")
        if not combatSystem then return end
        local remotes = combatSystem:FindFirstChild("Remotes")
        if not remotes then return end
        local requestHit = remotes:FindFirstChild("RequestHit")
        if requestHit then
            requestHit:FireServer()
        end
    end)
end

local function ResetState()
    State.CurrentBoss = nil
    State.LastTarget = nil
    State.HasVisitedSafeZone = false
    _G.SlowHub.IsAttackingBoss = false
end

function StopAutoFarm()
    if not State.IsRunning then return end
    State.IsRunning = false
    if State.Connection then
        State.Connection:Disconnect()
        State.Connection = nil
    end
    ResetState()
end

local function FarmLoop()
    if not _G.SlowHub.AutoFarmBosses or not State.IsRunning then
        StopAutoFarm()
        return
    end
    if not State.Character or not State.Character.Parent then
        return
    end
    if not State.HumanoidRootPart then
        State.HumanoidRootPart = State.Character:FindFirstChild("HumanoidRootPart")
        if not State.HumanoidRootPart then
            return
        end
    end
    if State.CurrentBoss and ShouldSwitchBoss(State.CurrentBoss) then
        ResetState()
        task.wait(0.1)
        return
    end
    if not State.CurrentBoss then
        State.CurrentBoss = FindValidBoss()
        if not State.CurrentBoss then
            _G.SlowHub.IsAttackingBoss = false
            return
        end
        State.HasVisitedSafeZone = false
        State.LastTarget = State.CurrentBoss
    end
    local boss = State.CurrentBoss
    _G.SlowHub.IsAttackingBoss = true
    if boss ~= State.LastTarget then
        State.LastTarget = boss
        State.HasVisitedSafeZone = false
    end
    if not State.HasVisitedSafeZone then
        local success = TeleportToSafeZone(boss)
        if success then
            State.HasVisitedSafeZone = true
        end
        task.wait(0.1)
        return
    end
    local success = TeleportToBoss(boss)
    if success then
        EquipWeapon()
        PerformAttack()
    end
end

function StartAutoFarm()
    if State.IsRunning then
        StopAutoFarm()
        task.wait(0.2)
    end
    InitializeState()
    if not State.NPCsFolder then
        return false
    end
    State.IsRunning = true
    State.Connection = RunService.Heartbeat:Connect(FarmLoop)
    return true
end

local function Notify(title, content, duration)
    duration = duration or 3
    pcall(function()
        if _G.WindUI and _G.WindUI.Notify then
            _G.WindUI:Notify({
                Title = title,
                Content = content,
                Duration = duration,
                Icon = "rbxassetid://4483362458"
            })
        end
    end)
end

Tab:Section({Title = "Boss Selection"})

Tab:Dropdown({
    Title = "Select Bosses to Farm",
    Flag = "SelectedBosses",
    Values = bossList,
    Multi = true,
    Default = {},
    Callback = function(Options)
    end
})

Tab:Section({Title = "Pity System (Optional)"})

Tab:Dropdown({
    Title = "Pity Target Boss",
    Flag = "PityTargetBoss",
    Values = bossList,
    Default = "",
    Callback = function(Option)
    end
})

Tab:Toggle({
    Title = "Enable Pity System",
    Flag = "PriorityPityEnabled",
    Default = false,
    Callback = function(Value)
        if _G.SlowHub.AutoFarmBosses and State.IsRunning then
            ResetState()
        end
    end
})

Tab:Section({Title = "Farm Control"})

Tab:Toggle({
    Title = "Auto Farm Selected Bosses",
    Flag = "AutoFarmBosses",
    Default = false,
    Callback = function(Value)
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                Notify("Error", "Please select a weapon first!", 3)
                return
            end
            StartAutoFarm()
        else
            StopAutoFarm()
        end
    end
})

Tab:Slider({
    Title = "Boss Farm Distance",
    Flag = "BossFarmDistance",
    Step = 1,
    Value = {
        Min = 1,
        Max = 10,
        Default = 8,
    },
    Callback = function(Value)
    end
})

Tab:Slider({
    Title = "Boss Farm Height",
    Flag = "BossFarmHeight",
    Step = 1,
    Value = {
        Min = 1,
        Max = 10,
        Default = 5,
    },
    Callback = function(Value)
    end
})

Tab:Slider({
    Title = "Attack Cooldown",
    Flag = "BossFarmCooldown",
    Step = 0.05,
    Value = {
        Min = 0.05,
        Max = 0.5,
        Default = 0.15,
    },
    Callback = function(Value)
    end
})

task.spawn(function()
    task.wait(2)
    if _G.SlowHub.AutoFarmBosses then
        StartAutoFarm()
    end
end)
