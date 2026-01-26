local Tab = _G.BossesTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local bossList = {
    "AizenBoss", "QinShiBoss", "RagnaBoss", "JinwooBoss", 
    "SukunaBoss", "GojoBoss", "SaberBoss", "YujiBoss"
}

local BossSafeZones = {
    ["AizenBoss"]  = CFrame.new(-567.2230834960938, 2.5787253379821777, 1228.4903564453125),
    ["QinShiBoss"] = CFrame.new(828.1129150390625, -0.39719152450561523, -1130.7666015625),
    ["SaberBoss"]  = CFrame.new(828.1129150390625, -0.39719152450561523, -1130.7666015625),
    ["RagnaBoss"]  = CFrame.new(340.0000915527344, 2.613438606262207, -1688.000244140625),
    ["JinwooBoss"] = CFrame.new(248.741516, 12.0932379, 927.542053, -0.156446099, 0, 0.987686574, 0, 1, 0, -0.987686574, 0, -0.156446099),
    ["SukunaBoss"] = CFrame.new(1571.26672, 77.2205429, -34.1126976, 0.142485321, 0, 0.989796937, 0, 1, 0, -0.989796937, 0, 0.142485321),
    ["GojoBoss"]   = CFrame.new(1858.32666, 12.9861355, 338.140015, 0.96272552, -0, -0.270480245, 0, 1, -0, 0.270480245, 0, 0.96272552),
    ["YujiBoss"]   = CFrame.new(1537.9287109375, 12.986135482788086, 226.10824584960938)
}

_G.SlowHub.SelectedBosses = _G.SlowHub.SelectedBosses or {}
if not _G.SlowHub.BossFarmDistance then _G.SlowHub.BossFarmDistance = 8 end
if not _G.SlowHub.BossFarmHeight then _G.SlowHub.BossFarmHeight = 5 end

local autoFarmBossConnection = nil
local isRunning = false
local lastTargetBoss = nil
local hasVisitedSafeZone = false

local function getAliveBoss()
    for bossName, isSelected in pairs(_G.SlowHub.SelectedBosses) do
        if isSelected then
            local boss = workspace.NPCs:FindFirstChild(bossName)
            if boss and boss.Parent then
                local humanoid = boss:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    return boss
                end
            end
        end
    end
    return nil
end

local function EquipWeapon()
    if not _G.SlowHub.SelectedWeapon then return false end
    pcall(function()
        local character = Player.Character
        if character and character:FindFirstChild("Humanoid") and not character:FindFirstChild(_G.SlowHub.SelectedWeapon) then
            local backpack = Player:FindFirstChild("Backpack")
            if backpack then
                local weapon = backpack:FindFirstChild(_G.SlowHub.SelectedWeapon)
                if weapon then character.Humanoid:EquipTool(weapon) end
            end
        end
    end)
end

local function stopAutoFarmBoss()
    isRunning = false
    lastTargetBoss = nil
    hasVisitedSafeZone = false
    _G.SlowHub.IsAttackingBoss = false
    
    if autoFarmBossConnection then
        autoFarmBossConnection:Disconnect()
        autoFarmBossConnection = nil
    end
    _G.SlowHub.AutoFarmBosses = false
end

local function startAutoFarmBoss()
    if isRunning then stopAutoFarmBoss() task.wait(0.2) end
    isRunning = true
    _G.SlowHub.AutoFarmBosses = true
    
    autoFarmBossConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoFarmBosses or not isRunning then
            stopAutoFarmBoss()
            return
        end
        
        local boss = getAliveBoss()
        
        if boss then
            _G.SlowHub.IsAttackingBoss = true
        else
            _G.SlowHub.IsAttackingBoss = false
            lastTargetBoss = nil
            hasVisitedSafeZone = false
            return 
        end

        if boss ~= lastTargetBoss then
            lastTargetBoss = boss
            hasVisitedSafeZone = false
        end

        local playerRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not playerRoot then return end

        if not hasVisitedSafeZone then
            local safeCFrame = BossSafeZones[boss.Name]
            if safeCFrame then
                playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                playerRoot.CFrame = safeCFrame
                hasVisitedSafeZone = true 
                return
            else
                hasVisitedSafeZone = true
            end
        end

        local bossRoot = boss:FindFirstChild("HumanoidRootPart")
        if bossRoot then
            pcall(function()
                playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                
                local targetCFrame = bossRoot.CFrame * CFrame.new(0, _G.SlowHub.BossFarmHeight, _G.SlowHub.BossFarmDistance)
                playerRoot.CFrame = targetCFrame
                
                EquipWeapon()
                ReplicatedStorage.CombatSystem.Remotes.RequestHit:FireServer()
            end)
        end
    end)
end

Tab:CreateParagraph({Name = "Select Bosses", Content = "Select which bosses to prioritize over Level Farm."})

for _, bossName in ipairs(bossList) do
    Tab:CreateToggle({
        Name = bossName,
        CurrentValue = false,
        Flag = "SelectBoss_" .. bossName,
        Callback = function(Value)
            _G.SlowHub.SelectedBosses[bossName] = Value
            if _G.SaveConfig then _G.SaveConfig() end
        end
    })
end

Tab:CreateParagraph({Name = "Farm Control", Content = ""})

local FarmToggle = Tab:CreateToggle({
    Name = "Auto Farm Selected Bosses (Priority)",
    CurrentValue = false,
    Flag = "AutoFarmBoss",
    Callback = function(Value)
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                _G.SlowHub.AutoFarmBosses = false
                if FarmToggle then FarmToggle:Set(false) end
                Rayfield:Notify({
                    Title = "Error",
                    Content = "Select a weapon first!",
                    Duration = 3,
                    Image = 4483362458
                })
                return
            end
            startAutoFarmBoss()
        else
            stopAutoFarmBoss()
        end
        _G.SlowHub.AutoFarmBosses = Value
    end
})

Tab:CreateSlider({
    Name = "Boss Farm Distance (studs)",
    Range = {1, 10},
    Increment = 1,
    CurrentValue = _G.SlowHub.BossFarmDistance,
    Flag = "BossFarmDistance",
    Callback = function(Value)
        _G.SlowHub.BossFarmDistance = Value
    end
})

Tab:CreateSlider({
    Name = "Boss Farm Height (studs)",
    Range = {1, 10},
    Increment = 1,
    CurrentValue = _G.SlowHub.BossFarmHeight,
    Flag = "BossFarmHeight",
    Callback = function(Value)
        _G.SlowHub.BossFarmHeight = Value
    end
})

if _G.SlowHub.AutoFarmBosses and _G.SlowHub.SelectedWeapon then
    task.wait(2)
    startAutoFarmBoss()
end
