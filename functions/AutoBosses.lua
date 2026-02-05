local Tab = _G.BossesTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

-- Lista de nomes base (para o menu)
local bossList = {
    "AizenBoss", "AlucardBoss", "QinShiBoss", "JinwooBoss", 
    "SukunaBoss", "GojoBoss", "SaberBoss", "YujiBoss",
    "StrongestofTodayBoss", "StrongestinHistoryBoss" -- Novos Bosses
}

-- Lista de dificuldades para verificar
local difficulties = {"_Normal", "_Medium", "_Hard", "_Extreme"}

-- Configuração inicial das SafeZones
local BossSafeZones = {
    ["AizenBoss"]  = CFrame.new(-567.22, 2.57, 1228.49),
    ["AlucardBoss"] = CFrame.new(248.74, 12.09, 927.54),
    ["QinShiBoss"] = CFrame.new(828.11, -0.39, -1130.76),
    ["SaberBoss"]  = CFrame.new(828.11, -0.39, -1130.76),
    ["JinwooBoss"] = CFrame.new(248.74, 12.09, 927.54),
    ["SukunaBoss"] = CFrame.new(1571.26, 77.22, -34.11),
    ["GojoBoss"]   = CFrame.new(1858.32, 12.98, 338.14),
    ["YujiBoss"]   = CFrame.new(1537.92, 12.98, 226.10),
    
    -- Coordenadas base para os novos bosses
    ["StrongestofTodayBoss"] = CFrame.new(181.69, 5.24, -2446.61),
    ["StrongestinHistoryBoss"] = CFrame.new(639.29, 3.67, -2273.30)
}

-- Adiciona automaticamente as variações de dificuldade na tabela de SafeZones
-- Isso garante que se o script achar o "_Extreme", ele saiba onde ficar
for _, bossBaseName in ipairs({"StrongestofTodayBoss", "StrongestinHistoryBoss"}) do
    if BossSafeZones[bossBaseName] then
        for _, diff in ipairs(difficulties) do
            BossSafeZones[bossBaseName .. diff] = BossSafeZones[bossBaseName]
        end
    end
end

_G.SlowHub.SelectedBosses = _G.SlowHub.SelectedBosses or {}
if not _G.SlowHub.BossFarmDistance then _G.SlowHub.BossFarmDistance = 8 end
if not _G.SlowHub.BossFarmHeight then _G.SlowHub.BossFarmHeight = 5 end

local autoFarmBossConnection = nil
local isRunning = false
local lastTargetBoss = nil
local hasVisitedSafeZone = false

-- Função auxiliar para verificar vida
local function checkHumanoid(model)
    if model and model.Parent then
        local humanoid = model:FindFirstChild("Humanoid")
        if humanoid and humanoid.Health > 0 then
            return true
        end
    end
    return false
end

local function getAliveBoss()
    local npcs = workspace:FindFirstChild("NPCs")
    if not npcs then return nil end

    for bossName, isSelected in pairs(_G.SlowHub.SelectedBosses) do
        if isSelected then
            -- 1. Tenta achar o boss com nome exato (Bosses antigos)
            local exactBoss = npcs:FindFirstChild(bossName)
            if exactBoss and checkHumanoid(exactBoss) then
                return exactBoss
            end

            -- 2. Tenta achar as variações de dificuldade (Bosses novos)
            for _, diff in ipairs(difficulties) do
                local variantName = bossName .. diff
                local variantBoss = npcs:FindFirstChild(variantName)
                if variantBoss and checkHumanoid(variantBoss) then
                    return variantBoss
                end
            end
        end
    end
    return nil
end

local function EquipWeapon()
    if not _G.SlowHub.SelectedWeapon then return end
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

        -- Lógica da SafeZone
        if not hasVisitedSafeZone then
            -- Procura a SafeZone pelo nome exato do boss (incluindo _Extreme se for o caso)
            local safeCFrame = BossSafeZones[boss.Name]
            
            -- Se não achar pelo nome completo, tenta achar pelo nome base (fallback)
            if not safeCFrame then
                for baseName, _ in pairs(_G.SlowHub.SelectedBosses) do
                    if string.find(boss.Name, baseName) then
                        safeCFrame = BossSafeZones[baseName]
                        break
                    end
                end
            end

            if safeCFrame then
                playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                playerRoot.CFrame = safeCFrame
                hasVisitedSafeZone = true 
                return
            else
                -- Se não tiver SafeZone configurada, ignora e vai atacar
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

-- === RAYFIELD UI === --

Tab:CreateParagraph({Title = "Select Bosses", Content = "Select which bosses to prioritize over Level Farm."})

for _, bossName in ipairs(bossList) do
    Tab:CreateToggle({
        Name = bossName,
        CurrentValue = false,
        Flag = "SelectBoss_" .. bossName,
        Callback = function(Value)
            _G.SlowHub.SelectedBosses[bossName] = Value
        end
    })
end

Tab:CreateSection("Farm Control")

local FarmToggle = Tab:CreateToggle({
    Name = "Auto Farm Selected Bosses (Priority)",
    CurrentValue = false,
    Flag = "AutoFarmBoss",
    Callback = function(Value)
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                -- Rayfield Notification (Assumindo que o Rayfield já está carregado no _G ou localmente)
                if Rayfield then
                    Rayfield:Notify({
                        Title = "Error",
                        Content = "Please select a weapon first!",
                        Duration = 3,
                        Image = 4483362458,
                    })
                end
                _G.SlowHub.AutoFarmBosses = false
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
    Name = "Boss Farm Distance",
    Range = {1, 10},
    Increment = 1,
    Suffix = "Studs",
    CurrentValue = _G.SlowHub.BossFarmDistance,
    Flag = "BossFarmDistance",
    Callback = function(Value)
        _G.SlowHub.BossFarmDistance = Value
    end
})

Tab:CreateSlider({
    Name = "Boss Farm Height",
    Range = {1, 10},
    Increment = 1,
    Suffix = "Studs",
    CurrentValue = _G.SlowHub.BossFarmHeight,
    Flag = "BossFarmHeight",
    Callback = function(Value)
        _G.SlowHub.BossFarmHeight = Value
    end
})
