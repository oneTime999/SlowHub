local Tab = _G.MainTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local MobList = {"Thief", "Monkey", "DesertBandit", "FrostRogue", "Sorcerer", "Hollow"}
local QuestConfig = {
    ["Thief"] = "QuestNPC1",
    ["Monkey"] = "QuestNPC3", 
    ["DesertBandit"] = "QuestNPC5",
    ["FrostRogue"] = "QuestNPC7",
    ["Sorcerer"] = "QuestNPC9",
    ["Hollow"] = "QuestNPC11"
}

local autoFarmSelectedConnection = nil
local autoQuestLoop = nil
local selectedMob = "Thief"
local currentNPCIndex = 1
local isRunning = false

if not _G.SlowHub.FarmDistance then
    _G.SlowHub.FarmDistance = 8
end

if not _G.SlowHub.FarmHeight then
    _G.SlowHub.FarmHeight = 4
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

local function getNextNPC(current, maxCount)
    local next = current + 1
    if next > maxCount then
        return 1
    end
    return next
end

local function getQuestForMob(mobName)
    return QuestConfig[mobName] or "QuestNPC1"
end

local function getMobConfig(mobName)
    -- CORRIGIDO: TODOS os mobs (incluindo Hollow) têm 5 NPCs agora
    return {
        npc = mobName,
        quest = getQuestForMob(mobName),
        count = 5  -- ✅ TODOS = 5 NPCs (Hollow1, Hollow2, Hollow3, Hollow4, Hollow5)
    }
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

local function stopAutoFarmSelectedMob()
    isRunning = false
    if autoFarmSelectedConnection then
        autoFarmSelectedConnection:Disconnect()
        autoFarmSelectedConnection = nil
    end
    if autoQuestLoop then
        autoQuestLoop:Disconnect()
        autoQuestLoop = nil
    end
    _G.SlowHub.AutoFarmSelectedMob = false
    _G.SlowHub.AutoQuestSelectedMob = false
    currentNPCIndex = 1
    
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

local function startAutoQuestLoop(questName)
    if autoQuestLoop then return end
    
    autoQuestLoop = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoFarmSelectedMob or not isRunning then
            return
        end
        
        pcall(function()
            ReplicatedStorage.RemoteEvents.QuestAccept:FireServer(questName)
        end)
    end)
end

local function stopAutoQuestLoop()
    if autoQuestLoop then
        autoQuestLoop:Disconnect()
        autoQuestLoop = nil
    end
end

local function startAutoFarmSelectedMob()
    if autoFarmSelectedConnection then
        stopAutoFarmSelectedMob()
    end
    
    isRunning = true
    _G.SlowHub.AutoFarmSelectedMob = true
    currentNPCIndex = 1
    
    local config = getMobConfig(selectedMob)
    EquipWeapon()
    
    -- Inicia loop de quest SE ativado
    if _G.SlowHub.AutoQuestSelectedMob then
        startAutoQuestLoop(config.quest)
    end
    
    local lastNPCSwitch = 0
    local NPC_SWITCH_DELAY = 0
    
    autoFarmSelectedConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoFarmSelectedMob or not isRunning then
            stopAutoFarmSelectedMob()
            return
        end
        
        local config = getMobConfig(selectedMob)
        local now = tick()
        
        -- Procura NPC atual
        local npc = getNPC(config.npc, currentNPCIndex)
        local npcAlive = npc and npc.Parent and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0
        
        -- SE NPC não existe OU está morto → TROCA IMEDIATAMENTE
        if not npcAlive then
            if (now - lastNPCSwitch) > NPC_SWITCH_DELAY then
                currentNPCIndex = getNextNPC(currentNPCIndex, config.count)
                lastNPCSwitch = now
                return
            end
        else
            -- NPC vivo → ataca
            lastNPCSwitch = now
            
            local npcRoot = getNPCRootPart(npc)
            
            if npcRoot and npcRoot.Parent and Player.Character then
                local playerRoot = Player.Character:FindFirstChild("HumanoidRootPart")
                local humanoid = Player.Character:FindFirstChild("Humanoid")
                
                if playerRoot and humanoid and humanoid.Health > 0 then
                    pcall(function()
                        playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        
                        local targetCFrame = npcRoot.CFrame
                        local offsetPosition = targetCFrame * CFrame.new(0, _G.SlowHub.FarmHeight, _G.SlowHub.FarmDistance)
                        
                        local distance = (playerRoot.Position - offsetPosition.Position).Magnitude
                        if distance > 3 or distance < 1 then
                            playerRoot.CFrame = offsetPosition
                        end
                        
                        EquipWeapon()
                        
                        if math.random() > 0.6 then
                            ReplicatedStorage.CombatSystem.Remotes.RequestHit:FireServer()
                        end
                    end)
                end
            end
        end
    end)
end

local Dropdown = Tab:AddDropdown("SelectMob", {
    Title = "Select Mob",
    Values = MobList,
    Default = 1, -- Thief é o primeiro
    Callback = function(Value)
        local wasRunning = isRunning
        
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
        
        if _G.SlowHub.AutoFarmSelectedMob and isRunning then
            local config = getMobConfig(selectedMob)
            if Value then
                startAutoQuestLoop(config.quest)
            else
                stopAutoQuestLoop()
            end
        end
        
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
