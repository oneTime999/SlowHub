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
    local maxNPCs = (mobName == "Hollow") and 1 or 5
    return {
        npc = mobName,
        quest = getQuestForMob(mobName),
        count = maxNPCs
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
    local NPC_SWITCH_DELAY = 0  -- SUPER RÁPIDO como no Auto Farm Level!
    
    autoFarmSelectedConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoFarmSelectedMob or not isRunning then
            stopAutoFarmSelectedMob()
            return
        end
        
        local config = getMobConfig(selectedMob)
        local now = tick()
        
        -- Tenta encontrar NPC atual (igual ao Auto Farm Level)
        local npc = getNPC(config.npc, currentNPCIndex)
        local npcAlive = npc and npc.Parent and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0
        
        -- Se NPC não existe ou está morto, troca INSTANTANEAMENTE (igual ao Auto Farm Level)
        if not npcAlive then
            if (now - lastNPCSwitch) > NPC_SWITCH_DELAY then
                currentNPCIndex = getNextNPC(currentNPCIndex, config.count)
                lastNPCSwitch = now
                return
            end
        else
            -- NPC encontrado e vivo, ataca (igual ao Auto Farm Level)
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

Tab:CreateDropdown({
    Name = "Select Mob",
    Options = MobList,
    CurrentOption = "Thief",
    Flag = "SelectedMobDropdown",
    Callback = function(Option)
        local wasRunning = isRunning
        
        if wasRunning then
            stopAutoFarmSelectedMob()
            task.wait(0.3)
        end
        
        if type(Option) == "table" then
            selectedMob = Option[1] or "Thief"
        else
            selectedMob = tostring(Option)
        end
        currentNPCIndex = 1
        
        if wasRunning then
            startAutoFarmSelectedMob()
            pcall(function()
                _G.Rayfield:Notify({
                    Title = "Slow Hub",
                    Content = "Farming: " .. selectedMob .. (_G.SlowHub.AutoQuestSelectedMob and " (with quest)" or ""),
                    Duration = 4,
                    Image = 105026320884681
                })
            end)
        end
    end
})

Tab:CreateToggle({
    Name = "Auto Farm Selected Mob",
    CurrentValue = false,
    Flag = "AutoFarmSelectedMobToggle",
    Callback = function(Value)
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                pcall(function()
                    _G.Rayfield:Notify({
                        Title = "Slow Hub",
                        Content = "Select a weapon first!",
                        Duration = 5,
                        Image = 105026320884681
                    })
                end)
                return
            end
            
            local config = getMobConfig(selectedMob)
            pcall(function()
                _G.Rayfield:Notify({
                    Title = "Slow Hub",
                    Content = "Farming: " .. config.npc .. " (Quest: " .. config.quest .. ")",
                    Duration = 4,
                    Image = 105026320884681
                })
            end)
            
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

Tab:CreateToggle({
    Name = "Auto Quest Selected Mob",
    CurrentValue = false,
    Flag = "AutoQuestSelectedMobToggle",
    Callback = function(Value)
        _G.SlowHub.AutoQuestSelectedMob = Value
        
        if _G.SlowHub.AutoFarmSelectedMob and isRunning then
            local config = getMobConfig(selectedMob)
            if Value then
                startAutoQuestLoop(config.quest)
                pcall(function()
                    _G.Rayfield:Notify({
                        Title = "Slow Hub",
                        Content = "Quest enabled for " .. selectedMob,
                        Duration = 3,
                        Image = 105026320884681
                    })
                end)
            else
                stopAutoQuestLoop()
                pcall(function()
                    _G.Rayfield:Notify({
                        Title = "Slow Hub",
                        Content = "Quest disabled - pure farming",
                        Duration = 3,
                        Image = 105026320884681
                    })
                end)
            end
        end
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

Tab:CreateSlider({
    Name = "Farm Distance",
    Range = {1, 10},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = _G.SlowHub.FarmDistance,
    Flag = "FarmDistanceSlider",
    Callback = function(Value)
        _G.SlowHub.FarmDistance = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})

Tab:CreateSlider({
    Name = "Farm Height",
    Range = {1, 10},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = _G.SlowHub.FarmHeight,
    Flag = "FarmHeightSlider",
    Callback = function(Value)
        _G.SlowHub.FarmHeight = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end, 
})
