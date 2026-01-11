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

-- Sistema de seleção múltipla de bosses
local selectedBosses = {}
for _, boss in ipairs(bossList) do
    selectedBosses[boss] = false
end

local autoFarmBossConnection = nil
local currentBossIndex = 1
local isRunning = false

if not _G.SlowHub.BossFarmDistance then
    _G.SlowHub.BossFarmDistance = 8
end

if not _G.SlowHub.BossFarmHeight then
    _G.SlowHub.BossFarmHeight = 5
end

-- Retorna lista de bosses selecionados
local function getSelectedBosses()
    local selected = {}
    for boss, enabled in pairs(selectedBosses) do
        if enabled then
            table.insert(selected, boss)
        end
    end
    return selected
end

-- Pega o próximo boss vivo da lista
local function getNextAliveBoss()
    local selected = getSelectedBosses()
    if #selected == 0 then return nil end
    
    -- Procura boss vivo começando do índice atual
    for i = 1, #selected do
        local index = ((currentBossIndex - 1 + i - 1) % #selected) + 1
        local bossName = selected[index]
        local boss = workspace.NPCs:FindFirstChild(bossName)
        
        if boss and boss.Parent then
            local humanoid = boss:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                currentBossIndex = index
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
                wait(0.1)
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
        wait(0.3)
    end
    
    local selected = getSelectedBosses()
    if #selected == 0 then
        return
    end
    
    isRunning = true
    _G.SlowHub.AutoFarmBosses = true
    currentBossIndex = 1
    
    EquipWeapon()
    
    autoFarmBossConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoFarmBosses or not isRunning then
            stopAutoFarmBoss()
            return
        end
        
        local boss = getNextAliveBoss()
        
        if boss and boss.Parent then
            local bossHumanoid = boss:FindFirstChild("Humanoid")
            
            if bossHumanoid and bossHumanoid.Health <= 0 then
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
        end
    end)
end

-- Cria toggles individuais para cada boss
Tab:AddParagraph({
    Title = "Select Bosses to Farm",
    Content = "Enable multiple bosses"
})

for _, bossName in ipairs(bossList) do
    Tab:AddToggle("Boss_" .. bossName, {
        Title = bossName,
        Default = false,
        Callback = function(Value)
            selectedBosses[bossName] = Value
            
            -- Se está farmando, reinicia para aplicar mudanças
            if isRunning then
                stopAutoFarmBoss()
                wait(0.1)
                if #getSelectedBosses() > 0 then
                    startAutoFarmBoss()
                end
            end
        end
    })
end

Tab:AddParagraph({
    Title = "Farm Control",
    Content = ""
})

local Toggle = Tab:AddToggle("AutoFarmBoss", {
    Title = "Auto Farm Selected Bosses",
    Default = _G.SlowHub.AutoFarmBosses,
    Callback = function(Value)
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                return
            end
            
            if #getSelectedBosses() == 0 then
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
