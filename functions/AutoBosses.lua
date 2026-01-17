local Tab = _G.BossesTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local bossList = {
    "AizenBoss", "QinShiBoss", "RagnaBoss", "JinwooBoss", 
    "SukunaBoss", "GojoBoss", "SaberBoss", "YujiBoss" -- Yuji Adicionado
}

-- SafeZones configuradas
local BossSafeZones = {
    ["AizenBoss"]  = CFrame.new(-482.868896484375, -2.0586609840393066, 936.237060546875),
    ["QinShiBoss"] = CFrame.new(667.6900024414062, -1.5378512144088745, -1125.218994140625),
    ["SaberBoss"]  = CFrame.new(667.6900024414062, -1.5378512144088745, -1125.218994140625),
    ["RagnaBoss"]  = CFrame.new(282.7808837890625, -2.7751426696777344, -1479.363525390625),
    ["JinwooBoss"] = CFrame.new(235.1376190185547, 3.1064343452453613, 659.7340698242188),
    ["SukunaBoss"] = CFrame.new(1359.4720458984375, 10.515644073486328, 249.58221435546875),
    ["GojoBoss"]   = CFrame.new(1359.4720458984375, 10.515644073486328, 249.58221435546875),
    -- YujiBoss usando a mesma SafeZone do Sukuna/Gojo
    ["YujiBoss"]   = CFrame.new(1359.4720458984375, 10.515644073486328, 249.58221435546875)
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
    _G.SlowHub.IsAttackingBoss = false -- Libera o Farm de Level/Mob
    
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
        
        -- === PRIORIDADE GLOBAL ===
        if boss then
            _G.SlowHub.IsAttackingBoss = true -- Pausa os outros farms e assume controle
        else
            _G.SlowHub.IsAttackingBoss = false -- Libera os outros farms
            lastTargetBoss = nil
            hasVisitedSafeZone = false
            return 
        end
        -- =========================

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

-- Interface Gráfica
Tab:AddParagraph({Title = "Select Bosses", Content = "Select which bosses to prioritize over Level Farm."})

for _, bossName in ipairs(bossList) do
    Tab:AddToggle("SelectBoss_" .. bossName, {
        Title = bossName,
        Default = false,
        Callback = function(Value)
            _G.SlowHub.SelectedBosses[bossName] = Value
            if _G.SaveConfig then _G.SaveConfig() end
        end
    })
end

Tab:AddParagraph({Title = "Farm Control", Content = ""})

local FarmToggle = Tab:AddToggle("AutoFarmBoss", {
    Title = "Auto Farm Selected Bosses (Priority)",
    Default = false,
    Callback = function(Value)
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                _G.SlowHub.AutoFarmBosses = false
                if FarmToggle then FarmToggle:SetValue(false) end
                _G.Fluent:Notify({Title = "Error", Content = "Select a weapon first!", Duration = 3})
                return
            end
            startAutoFarmBoss()
        else
            stopAutoFarmBoss()
        end
        _G.SlowHub.AutoFarmBosses = Value
    end
})

Tab:AddSlider("BossFarmDistance", {
    Title = "Boss Farm Distance (studs)",
    Min = 1, Max = 10, Default = _G.SlowHub.BossFarmDistance, Rounding = 0,
    Callback = function(Value)
        _G.SlowHub.BossFarmDistance = Value
    end
})

Tab:AddSlider("BossFarmHeight", {
    Title = "Boss Farm Height (studs)",
    Min = 1, Max = 10, Default = _G.SlowHub.BossFarmHeight, Rounding = 0,
    Callback = function(Value)
        _G.SlowHub.BossFarmHeight = Value
    end
})

-- Auto Start se já estiver ativado nas configs salvas
if _G.SlowHub.AutoFarmBosses and _G.SlowHub.SelectedWeapon then
    task.wait(2)
    startAutoFarmBoss()
end
