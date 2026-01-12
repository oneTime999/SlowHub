local Tab = _G.MainTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local LevelConfig = {
    {minLevel = 1, maxLevel = 249, quest = "QuestNPC1", npc = "Thief", count = 5},
    {minLevel = 250, maxLevel = 749, quest = "QuestNPC3", npc = "Monkey", count = 5},
    {minLevel = 750, maxLevel = 1499, quest = "QuestNPC5", npc = "DesertBandit", count = 5},
    {minLevel = 1500, maxLevel = 2999, quest = "QuestNPC7", npc = "FrostRogue", count = 5},
    {minLevel = 3000, maxLevel = 5499, quest = "QuestNPC9", npc = "Sorcerer", count = 5},
    {minLevel = 5500, maxLevel = 99999, quest = "QuestNPC11", npc = "Hollow", count = 5}
}

-- --- COORDENADAS DOS TP INICIAIS (SAFE ZONES) ---
local NPCSafeZones = {
    ["Thief"]        = CFrame.new(-94.74494171142578, -1.985839605331421, -244.80184936523438),
    ["Monkey"]       = CFrame.new(-446.5873107910156, -3.560742139816284, 368.79754638671875),
    ["DesertBandit"] = CFrame.new(-768.9750366210938, -2.1328823566436768, -361.69775390625),
    ["FrostRogue"]   = CFrame.new(-223.8474884033203, -1.8019909858703613, -1062.9384765625),
    ["Sorcerer"]     = CFrame.new(1359.4720458984375, 10.515644073486328, 249.58221435546875),
    ["Hollow"]       = CFrame.new(-482.868896484375, -2.0586609840393066, 936.237060546875) -- Mesma do Aizen
}
-- ------------------------------------------------

local autoLevelConnection = nil
local autoLevelQuestLoop = nil
local currentNPCIndex = 1
local lastTargetNPCName = nil   -- Para saber quando trocou de mob
local hasVisitedSafeZone = false -- Controle do TP inicial

if not _G.SlowHub.FarmDistance then _G.SlowHub.FarmDistance = 8 end
if not _G.SlowHub.FarmHeight then _G.SlowHub.FarmHeight = 4 end

local function GetPlayerLevel()
    local success, level = pcall(function()
        return Player.Data.Level.Value
    end)
    return success and level or 1
end

local function GetCurrentConfig()
    local level = GetPlayerLevel()
    for _, config in pairs(LevelConfig) do
        if level >= config.minLevel and level <= config.maxLevel then
            return config
        end
    end
    return LevelConfig[1]
end

local function getNextNPC(current, maxCount)
    local next = current + 1
    if next > maxCount then
        return 1
    end
    return next
end

local function getNPC(npcName, index)
    return workspace.NPCs:FindFirstChild(npcName .. index)
end

local function getNPCRootPart(npc)
    if npc and npc:FindFirstChild("HumanoidRootPart") then
        return npc.HumanoidRootPart
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

local function stopAutoLevel()
    if autoLevelConnection then
        autoLevelConnection:Disconnect()
        autoLevelConnection = nil
    end
    if autoLevelQuestLoop then
        autoLevelQuestLoop:Disconnect()
        autoLevelQuestLoop = nil
    end
    _G.SlowHub.AutoFarmLevel = false
    currentNPCIndex = 1
    lastTargetNPCName = nil
    hasVisitedSafeZone = false
    
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

local function startAutoLevel()
    if autoLevelConnection then
        stopAutoLevel()
    end
    
    _G.SlowHub.AutoFarmLevel = true
    currentNPCIndex = 1
    
    local config = GetCurrentConfig()
    
    EquipWeapon()
    
    -- Loop de Quest
    autoLevelQuestLoop = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoFarmLevel then
            if autoLevelQuestLoop then
                autoLevelQuestLoop:Disconnect()
                autoLevelQuestLoop = nil
            end
            return
        end
        
        config = GetCurrentConfig()
        
        pcall(function()
            ReplicatedStorage.RemoteEvents.QuestAccept:FireServer(config.quest)
        end)
    end)
    
    local lastNPCSwitch = 0
    local NPC_SWITCH_DELAY = 0  -- Troca instantânea
    
    -- Loop Principal de Movimento/Ataque
    autoLevelConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoFarmLevel then
            stopAutoLevel()
            return
        end
        
        config = GetCurrentConfig()
        local now = tick()
        
        -- LÓGICA DE SAFE ZONE (Igual do Boss)
        -- Verifica se trocamos de mob (ex: upei do level 249 pro 250)
        if config.npc ~= lastTargetNPCName then
            lastTargetNPCName = config.npc
            hasVisitedSafeZone = false -- Reseta para obrigar a ir no TP inicial
        end

        local playerRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not playerRoot then return end

        -- Se ainda não foi na Safe Zone deste mob, vai agora
        if not hasVisitedSafeZone then
            local safeCFrame = NPCSafeZones[config.npc]
            if safeCFrame and safeCFrame.Position ~= Vector3.new(0,0,0) then
                pcall(function()
                    playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    playerRoot.CFrame = safeCFrame
                end)
                hasVisitedSafeZone = true
                return -- Espera o próximo frame para começar a caçar
            else
                hasVisitedSafeZone = true -- Se não tem coordenada, libera direto
            end
        end

        -- LÓGICA DE FARM (Só roda se hasVisitedSafeZone for true)
        
        -- Tenta encontrar NPC atual
        local npc = getNPC(config.npc, currentNPCIndex)
        local npcAlive = npc and npc.Parent and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0
        
        -- Se NPC não existe ou está morto, troca INSTANTANEAMENTE
        if not npcAlive then
            if (now - lastNPCSwitch) > NPC_SWITCH_DELAY then
                currentNPCIndex = getNextNPC(currentNPCIndex, config.count)
                lastNPCSwitch = now
                return
            end
        else
            -- NPC encontrado e vivo, ataca
            lastNPCSwitch = now
            
            local npcRoot = getNPCRootPart(npc)
            local humanoid = Player.Character:FindFirstChild("Humanoid")
            
            if npcRoot and npcRoot.Parent and humanoid and humanoid.Health > 0 then
                pcall(function()
                    playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    
                    local targetCFrame = npcRoot.CFrame
                    local offsetPosition = targetCFrame * CFrame.new(0, _G.SlowHub.FarmHeight, _G.SlowHub.FarmDistance)
                    
                    local distance = (playerRoot.Position - offsetPosition.Position).Magnitude
                    if distance > 3 or distance < 1 then
                        playerRoot.CFrame = offsetPosition
                    end
                    
                    EquipWeapon()
                    
                    if math.random() > 0.6 then -- Kill Aura
                        ReplicatedStorage.CombatSystem.Remotes.RequestHit:FireServer()
                    end
                end)
            end
        end
    end)
end

local Toggle = Tab:AddToggle("AutoFarmLevel", {
    Title = "Auto Farm Level",
    Default = _G.SlowHub.AutoFarmLevel,
    Callback = function(Value)
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                _G.Fluent:Notify({Title = "Erro", Content = "Selecione uma arma primeiro!", Duration = 3})
                if Toggle then Toggle:SetValue(false) end
                return
            end
            
            startAutoLevel()
        else
            stopAutoLevel()
        end
        
        _G.SlowHub.AutoFarmLevel = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

local DistanceSlider = Tab:AddSlider("FarmDistance", {
    Title = "Farm Distance (studs)",
    Min = 1,
    Max = 10,
    Default = _G.SlowHub.FarmDistance,
    Rounding = 0,
    Callback = function(Value)
        _G.SlowHub.FarmDistance = Value
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

local HeightSlider = Tab:AddSlider("FarmHeight", {
    Title = "Farm Height (studs)",
    Min = 1,
    Max = 10,
    Default = _G.SlowHub.FarmHeight,
    Rounding = 0,
    Callback = function(Value)
        _G.SlowHub.FarmHeight = Value
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

if _G.SlowHub.AutoFarmLevel and _G.SlowHub.SelectedWeapon then
    task.wait(2)
    startAutoLevel()
end
