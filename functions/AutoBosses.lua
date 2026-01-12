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

-- Tabela para rastrear quais bosses estão selecionados
_G.SlowHub.SelectedBosses = _G.SlowHub.SelectedBosses or {}

local autoFarmBossConnection = nil
local isRunning = false

if not _G.SlowHub.BossFarmDistance then
    _G.SlowHub.BossFarmDistance = 8
end

if not _G.SlowHub.BossFarmHeight then
    _G.SlowHub.BossFarmHeight = 5
end

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
            return -- Nenhum boss vivo encontrado, espera
        end
        
        local bossHumanoid = boss:FindFirstChild("Humanoid")
        if not bossHumanoid or bossHumanoid.Health <= 0 then
            return
        end
        
        local bossRoot = getBossRootPart(boss)
        
        if bossRoot and bossRoot.Parent and Player.Character then
            local playerRoot = Player.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = Player.Character:FindFirstChild("Humanoid")
            
            if playerRoot and humanoid and humanoid.Health > 0 then
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
