local Tab = _G.BossesTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local bossList = {
    "AizenBoss",
    "QinShiBoss",
    "RagnaBoss",
    "JinwooBoss",
    "SukunaBoss",
    "GojoBoss",
    "SaberBoss"
}

-- --- CONFIGURAÇÃO DAS POSIÇÕES INICIAIS (SAFE ZONES) ---
local BossSafeZones = {
    ["AizenBoss"]  = CFrame.new(-482.868896484375, -2.0586609840393066, 936.237060546875),
    
    ["QinShiBoss"] = CFrame.new(667.6900024414062, -1.5378512144088745, -1125.218994140625), -- Chin e Saber
    ["SaberBoss"]  = CFrame.new(667.6900024414062, -1.5378512144088745, -1125.218994140625), -- Chin e Saber
    
    ["RagnaBoss"]  = CFrame.new(282.7808837890625, -2.7751426696777344, -1479.363525390625),
    
    ["JinwooBoss"] = CFrame.new(235.1376190185547, 3.1064343452453613, 659.7340698242188),
    
    ["SukunaBoss"] = CFrame.new(1359.4720458984375, 10.515644073486328, 249.58221435546875), -- Gojo e Sukuna
    ["GojoBoss"]   = CFrame.new(1359.4720458984375, 10.515644073486328, 249.58221435546875)  -- Gojo e Sukuna
}
-- -------------------------------------------------------

_G.SlowHub.SelectedBosses = _G.SlowHub.SelectedBosses or {}

local autoFarmBossConnection = nil
local isRunning = false
local lastTargetBoss = nil        -- Armazena qual foi o último boss focado
local hasVisitedSafeZone = false  -- Controle para saber se já foi no tp inicial

if not _G.SlowHub.BossFarmDistance then _G.SlowHub.BossFarmDistance = 8 end
if not _G.SlowHub.BossFarmHeight then _G.SlowHub.BossFarmHeight = 5 end

-- Busca primeiro boss vivo e selecionado
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
    lastTargetBoss = nil        -- Reseta o alvo
    hasVisitedSafeZone = false  -- Reseta a verificação
    
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
        
        -- Busca boss vivo
        local boss = getAliveBoss()
        
        if not boss then
            -- Se não tem boss vivo, reseta as variáveis para quando um nascer
            lastTargetBoss = nil
            hasVisitedSafeZone = false
            return 
        end
        
        local bossHumanoid = boss:FindFirstChild("Humanoid")
        if not bossHumanoid or bossHumanoid.Health <= 0 then
            return
        end
        
        -- LÓGICA DO TELEPORTE INICIAL
        -- Se mudou de boss (ou o boss renasceu e é uma nova instancia), reseta o flag
        if boss ~= lastTargetBoss then
            lastTargetBoss = boss
            hasVisitedSafeZone = false
        end

        local playerRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not playerRoot then return end

        -- Se ainda não visitou a zona segura, vai pra lá primeiro
        if not hasVisitedSafeZone then
            local safeCFrame = BossSafeZones[boss.Name]
            if safeCFrame then
                pcall(function()
                    playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    playerRoot.CFrame = safeCFrame
                end)
                
                -- Pequeno delay visual para garantir que chegou
                -- Como estamos no Heartbeat, não use task.wait() longo aqui, 
                -- mas o return faz ele tentar de novo no próximo frame.
                -- Vamos considerar visitado assim que o TP for executado.
                hasVisitedSafeZone = true 
                return
            else
                -- Se não tiver coordenada configurada, pula essa etapa
                hasVisitedSafeZone = true
            end
        end

        -- LÓGICA DE FARM (Só acontece se hasVisitedSafeZone for true)
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

-- Seção de seleção de bosses
Tab:AddParagraph({
    Title = "Select Bosses",
    Content = "Choose which bosses to farm"
})

-- Cria um toggle para cada boss
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

-- Seção de controle
Tab:AddParagraph({
    Title = "Farm Control",
    Content = ""
})

local FarmToggle = Tab:AddToggle("AutoFarmBoss", {
    Title = "Auto Farm Selected Bosses",
    Default = false,
    Callback = function(Value)
        if Value then
            -- Verifica se tem arma selecionada
            if not _G.SlowHub.SelectedWeapon then
                _G.SlowHub.AutoFarmBosses = false
                if FarmToggle then
                    FarmToggle:SetValue(false)
                end
                _G.Fluent:Notify({Title = "Erro", Content = "Selecione uma arma primeiro!", Duration = 3})
                return
            end
            
            -- Verifica se pelo menos 1 boss foi selecionado
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
                _G.Fluent:Notify({Title = "Erro", Content = "Selecione pelo menos um Boss!", Duration = 3})
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

-- Auto-start se estava ativo
if _G.SlowHub.AutoFarmBosses and _G.SlowHub.SelectedWeapon then
    task.wait(2)
    startAutoFarmBoss()
end
