local Tab = _G.BossesTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

-- LISTA CORRIGIDA (EXATAMENTE COMO VOCÊ PEDIU)
local bossList = {
    "AizenBoss",
    "QinShiBoss",
    "RagnaBoss",
    "JinwooBoss",
    "SukunaBoss",
    "GojoBoss",
    "SaberBoss"
}

-- SafeZones mapeadas pelos nomes corretos
local BossSafeZones = {
    ["AizenBoss"]  = CFrame.new(-482.868896484375, -2.0586609840393066, 936.237060546875),
    ["QinShiBoss"] = CFrame.new(667.6900024414062, -1.5378512144088745, -1125.218994140625),
    ["SaberBoss"]  = CFrame.new(667.6900024414062, -1.5378512144088745, -1125.218994140625),
    ["RagnaBoss"]  = CFrame.new(282.7808837890625, -2.7751426696777344, -1479.363525390625),
    ["JinwooBoss"] = CFrame.new(235.1376190185547, 3.1064343452453613, 659.7340698242188),
    ["SukunaBoss"] = CFrame.new(1359.4720458984375, 10.515644073486328, 249.58221435546875),
    ["GojoBoss"]   = CFrame.new(1359.4720458984375, 10.515644073486328, 249.58221435546875)
}

_G.SlowHub.SelectedBosses = _G.SlowHub.SelectedBosses or {}

local autoFarmBossConnection = nil
local isRunning = false
local lastTargetBoss = nil
local hasVisitedSafeZone = false

if not _G.SlowHub.BossFarmDistance then _G.SlowHub.BossFarmDistance = 8 end
if not _G.SlowHub.BossFarmHeight then _G.SlowHub.BossFarmHeight = 5 end

local function getAliveBoss()
    -- Procura na pasta NPCs (Padrão do seu script original) ou Enemies como fallback
    local targetFolder = workspace:FindFirstChild("NPCs") or workspace:FindFirstChild("Enemies") or workspace:FindFirstChild("Mobs")
    
    if not targetFolder then return nil end

    for bossName, isSelected in pairs(_G.SlowHub.SelectedBosses) do
        if isSelected then
            local boss = targetFolder:FindFirstChild(bossName)
            if boss and boss:FindFirstChild("Humanoid") and boss.Humanoid.Health > 0 then
                return boss
            end
        end
    end
    return nil
end

local function getBossRootPart(boss)
    if boss and boss:FindFirstChild("HumanoidRootPart") then
        return boss.HumanoidRootPart
    end
    return nil
end

local function EquipWeapon()
    if not _G.SlowHub.SelectedWeapon then return false end
    
    local success = pcall(function()
        local backpack = Player:FindFirstChild("Backpack")
        local character = Player.Character
        
        if not character or not character:FindFirstChild("Humanoid") then
            return false
        end
        
        if character:FindFirstChild(_G.SlowHub.SelectedWeapon) then
            return true
        end
        
        if backpack then
            local weapon = backpack:FindFirstChild(_G.SlowHub.SelectedWeapon)
            if weapon then
                character.Humanoid:EquipTool(weapon)
                task.wait(0.1)
            end
        end
    end)
    
    return success
end

local function stopAutoFarmBoss()
    isRunning = false
    lastTargetBoss = nil
    hasVisitedSafeZone = false
    
    if autoFarmBossConnection then
        autoFarmBossConnection:Disconnect()
        autoFarmBossConnection = nil
    end
    
    _G.SlowHub.AutoFarmBosses = false
    
    pcall(function()
        if Player.Character then
            local playerRoot = Player.Character:FindFirstChild("HumanoidRootPart")
            if playerRoot then
                playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                playerRoot.Anchored = false
            end
        end
    end)
end

local function startAutoFarmBoss()
    if isRunning then
        stopAutoFarmBoss()
        task.wait(0.3)
    end
    
    isRunning = true
    _G.SlowHub.AutoFarmBosses = true
    
    EquipWeapon()
    
    autoFarmBossConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoFarmBosses or not isRunning then
            stopAutoFarmBoss()
            return
        end
        
        local boss = getAliveBoss()
        
        if not boss then
            lastTargetBoss = nil
            hasVisitedSafeZone = false
            return 
        end
        
        local bossHumanoid = boss:FindFirstChild("Humanoid")
        if not bossHumanoid or bossHumanoid.Health <= 0 then
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
            -- Se tiver safezone, vai pra ela. Se não tiver, ignora.
            if safeCFrame then
                pcall(function()
                    playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    playerRoot.CFrame = safeCFrame
                end)
                hasVisitedSafeZone = true 
                return
            else
                hasVisitedSafeZone = true
            end
        end

        local bossRoot = getBossRootPart(boss)
        
        if bossRoot and bossRoot.Parent then
            local humanoid = Player.Character:FindFirstChild("Humanoid")
            
            if humanoid and humanoid.Health > 0 then
                pcall(function()
                    playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    
                    local targetCFrame = bossRoot.CFrame
                    local offsetPosition = targetCFrame * CFrame.new(0, _G.SlowHub.BossFarmHeight, _G.SlowHub.BossFarmDistance)
                    
                    local distance = (playerRoot.Position - offsetPosition.Position).Magnitude
                    if distance > 3 or distance < 1 then
                        playerRoot.CFrame = offsetPosition
                    end
                    
                    EquipWeapon()
                    
                    ReplicatedStorage.CombatSystem.Remotes.RequestHit:FireServer()
                end)
            end
        end
    end)
end

Tab:AddParagraph({
    Title = "Select Bosses",
    Content = "Choose which bosses to farm"
})

for _, bossName in ipairs(bossList) do
    local Toggle = Tab:AddToggle("SelectBoss_" .. bossName, {
        Title = bossName,
        Default = false,
        Callback = function(Value)
            _G.SlowHub.SelectedBosses[bossName] = Value
            
            if _G.SaveConfig then
                _G.SaveConfig()
            end
        end
    })
end

Tab:AddParagraph({
    Title = "Farm Control",
    Content = ""
})

local FarmToggle = Tab:AddToggle("AutoFarmBoss", {
    Title = "Auto Farm Selected Bosses",
    Default = false,
    Callback = function(Value)
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                _G.SlowHub.AutoFarmBosses = false
                if FarmToggle then
                    FarmToggle:SetValue(false)
                end
                _G.Fluent:Notify({Title = "Error", Content = "Select a weapon first!", Duration = 3})
                return
            end
            
            local hasSelected = false
            for _, selected in pairs(_G.SlowHub.SelectedBosses) do
                if selected then
                    hasSelected = true
                    break
                end
            end
            
            if not hasSelected then
                _G.SlowHub.AutoFarmBosses = false
                if FarmToggle then
                    FarmToggle:SetValue(false)
                end
                _G.Fluent:Notify({Title = "Error", Content = "Select at least one Boss!", Duration = 3})
                return
            end
            
            startAutoFarmBoss()
        else
            stopAutoFarmBoss()
        end
        
        _G.SlowHub.AutoFarmBosses = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

local DistanceSlider = Tab:AddSlider("BossFarmDistance", {
    Title = "Boss Farm Distance (studs)",
    Min = 1,
    Max = 10,
    Default = _G.SlowHub.BossFarmDistance,
    Rounding = 0,
    Callback = function(Value)
        _G.SlowHub.BossFarmDistance = Value
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

local HeightSlider = Tab:AddSlider("BossFarmHeight", {
    Title = "Boss Farm Height (studs)",
    Min = 1,
    Max = 10,
    Default = _G.SlowHub.BossFarmHeight,
    Rounding = 0,
    Callback = function(Value)
        _G.SlowHub.BossFarmHeight = Value
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

if _G.SlowHub.AutoFarmBosses and _G.SlowHub.SelectedWeapon then
    task.wait(2)
    startAutoFarmBoss()
end
