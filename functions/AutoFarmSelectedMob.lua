local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local Tab = _G.MainTab -- Ou a aba onde você coloca este script

local MobList = {"Thief", "Monkey", "DesertBandit", "FrostRogue", "Sorcerer", "Hollow"}
local QuestConfig = {
    ["Thief"] = "QuestNPC1",
    ["Monkey"] = "QuestNPC3", 
    ["DesertBandit"] = "QuestNPC5",
    ["FrostRogue"] = "QuestNPC7",
    ["Sorcerer"] = "QuestNPC9",
    ["Hollow"] = "QuestNPC11"
}

local MobSafeZones = {
    ["Thief"]        = CFrame.new(-94.74494171142578, -1.985839605331421, -244.80184936523438),
    ["Monkey"]       = CFrame.new(-446.5873107910156, -3.560742139816284, 368.79754638671875),
    ["DesertBandit"] = CFrame.new(-768.9750366210938, -2.1328823566436768, -361.69775390625),
    ["FrostRogue"]   = CFrame.new(-223.8474884033203, -1.8019909858703613, -1062.9384765625),
    ["Sorcerer"]     = CFrame.new(1359.4720458984375, 10.515644073486328, 249.58221435546875),
    ["Hollow"]       = CFrame.new(-482.868896484375, -2.0586609840393066, 936.237060546875)
}

local autoFarmSelectedConnection = nil
local questLoopActive = false
local selectedMob = nil
local currentNPCIndex = 1
local lastTargetName = nil
local hasVisitedSafeZone = false
local wasAttackingBoss = false -- Variável de controle de retorno

if not _G.SlowHub.FarmDistance then _G.SlowHub.FarmDistance = 8 end
if not _G.SlowHub.FarmHeight then _G.SlowHub.FarmHeight = 4 end

local function getNPC(npcName, index)
    return workspace.NPCs:FindFirstChild(npcName .. index)
end

local function getNPCRootPart(npc)
    if npc and npc:FindFirstChild("HumanoidRootPart") then
        return npc.HumanoidRootPart
    end
    return nil
end

local function getNextNPC(current, maxCount)
    local next = current + 1
    if next > maxCount then return 1 end
    return next
end

local function getQuestForMob(mobName)
    return QuestConfig[mobName] or "QuestNPC1"
end

local function getMobConfig(mobName)
    return {
        npc = mobName,
        quest = getQuestForMob(mobName),
        count = 5 
    }
end

local function EquipWeapon()
    if not _G.SlowHub.SelectedWeapon then return false end
    
    local success = pcall(function()
        local backpack = Player:FindFirstChild("Backpack")
        local character = Player.Character
        
        if not character or not character:FindFirstChild("Humanoid") then return false end
        if character:FindFirstChild(_G.SlowHub.SelectedWeapon) then return true end
        
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

local function stopAutoFarmSelectedMob()
    if autoFarmSelectedConnection then
        autoFarmSelectedConnection:Disconnect()
        autoFarmSelectedConnection = nil
    end
    
    questLoopActive = false
    _G.SlowHub.AutoFarmSelectedMob = false
    currentNPCIndex = 1
    lastTargetName = nil
    hasVisitedSafeZone = false
    wasAttackingBoss = false
    
    pcall(function()
        if Player.Character then
            local playerRoot = Player.Character:FindFirstChild("HumanoidRootPart")
            if playerRoot then
                playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                -- playerRoot.Anchored = false
            end
        end
    end)
end

local function startQuestLoop(questName)
    if questLoopActive then return end
    questLoopActive = true
    
    task.spawn(function()
        while questLoopActive and _G.SlowHub.AutoFarmSelectedMob do
            -- Só pega quest se estiver ativado E NÃO estiver matando Boss
            if _G.SlowHub.AutoQuestSelectedMob and not _G.SlowHub.IsAttackingBoss then
                pcall(function()
                    ReplicatedStorage.RemoteEvents.QuestAccept:FireServer(questName)
                end)
            end
            task.wait(2)
        end
    end)
end

local function startAutoFarmSelectedMob()
    if autoFarmSelectedConnection then
        stopAutoFarmSelectedMob()
    end
    
    _G.SlowHub.AutoFarmSelectedMob = true
    currentNPCIndex = 1
    wasAttackingBoss = false
    
    local config = getMobConfig(selectedMob)
    EquipWeapon()
    
    startQuestLoop(config.quest)
    
    local lastNPCSwitch = 0
    local NPC_SWITCH_DELAY = 0
    local lastAttack = 0
    
    autoFarmSelectedConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoFarmSelectedMob then
            stopAutoFarmSelectedMob()
            return
        end

        -- === LÓGICA DE PRIORIDADE DO BOSS ===
        if _G.SlowHub.IsAttackingBoss then
            wasAttackingBoss = true
            return -- Pausa o farm de Mob e deixa o Boss Farm agir
        end

        -- Retorno seguro: Se estava no Boss, reseta Safe Zone
        if wasAttackingBoss then
            hasVisitedSafeZone = false
            wasAttackingBoss = false
        end
        -- ===================================
        
        local playerRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not playerRoot then return end
        
        local now = tick()
        local config = getMobConfig(selectedMob)
        
        -- Reset de SafeZone se trocar o mob no menu
        if selectedMob ~= lastTargetName then
            lastTargetName = selectedMob
            hasVisitedSafeZone = false
        end

        -- Ir para SafeZone primeiro
        if not hasVisitedSafeZone then
            local safeCFrame = MobSafeZones[selectedMob]
            if safeCFrame and safeCFrame.Position ~= Vector3.new(0,0,0) then
                pcall(function()
                    playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    playerRoot.CFrame = safeCFrame
                end)
                hasVisitedSafeZone = true
                return -- Espera um frame
            else
                hasVisitedSafeZone = true
            end
        end

        -- Lógica de atacar o NPC
        local npc = getNPC(config.npc, currentNPCIndex)
        local npcAlive = npc and npc.Parent and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0
        
        if not npcAlive then
            if (now - lastNPCSwitch) > NPC_SWITCH_DELAY then
                currentNPCIndex = getNextNPC(currentNPCIndex, config.count)
                lastNPCSwitch = now
                return
            end
        else
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
                    
                    if (now - lastAttack) > 0.15 then
                        ReplicatedStorage.CombatSystem.Remotes.RequestHit:FireServer()
                        lastAttack = now
                    end
                end)
            end
        end
    end)
end

-- UI ELEMENTS
local Dropdown = Tab:AddDropdown("SelectMob", {
    Title = "Select Mob",
    Values = MobList,
    Default = nil,
    Callback = function(Value)
        local wasRunning = _G.SlowHub.AutoFarmSelectedMob
        
        if wasRunning then
            stopAutoFarmSelectedMob()
            task.wait(0.3)
        end
        
        selectedMob = tostring(Value)
        currentNPCIndex = 1
        
        if wasRunning then
            startAutoFarmSelectedMob()
        end
    end
})

local Toggle = Tab:AddToggle("AutoFarmSelectedMob", {
    Title = "Auto Farm Selected Mob",
    Default = false,
    Callback = function(Value)
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                _G.Fluent:Notify({Title = "Error", Content = "Select a weapon first!", Duration = 3})
                if Toggle then Toggle:SetValue(false) end
                return
            end
            
            if not selectedMob then
                _G.Fluent:Notify({Title = "Error", Content = "Select a Mob first!", Duration = 3})
                if Toggle then Toggle:SetValue(false) end
                return
            end
            
            startAutoFarmSelectedMob()
        else
            stopAutoFarmSelectedMob()
        end
        
        _G.SlowHub.AutoFarmSelectedMob = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

local QuestToggle = Tab:AddToggle("AutoQuestSelectedMob", {
    Title = "Auto Quest Selected Mob",
    Default = false,
    Callback = function(Value)
        _G.SlowHub.AutoQuestSelectedMob = Value
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
