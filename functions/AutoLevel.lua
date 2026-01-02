local Tab = _G.MainTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

-- Configurações de NPCs por nível
local LevelConfig = {
    {minLevel = 1, maxLevel = 249, quest = "QuestNPC1", npc = "Thief", count = 5},
    {minLevel = 250, maxLevel = 749, quest = "QuestNPC3", npc = "Monkey", count = 5},
    {minLevel = 750, maxLevel = 1499, quest = "QuestNPC5", npc = "DesertBandit", count = 5},
    {minLevel = 1500, maxLevel = 2999, quest = "QuestNPC7", npc = "DesertBandit", count = 5},
    {minLevel = 3000, maxLevel = 99999, quest = "QuestNPC9", npc = "Sorcerer", count = 5}
}

-- Variáveis de controle
local autoLevelConnection = nil
local autoLevelQuestLoop = nil
local currentNPCIndex = 1

-- Função para pegar o nível do player
local function GetPlayerLevel()
    local success, level = pcall(function()
        return Player.Data.Level.Value
    end)
    return success and level or 1
end

-- Função para pegar a configuração baseada no nível
local function GetCurrentConfig()
    local level = GetPlayerLevel()
    for _, config in pairs(LevelConfig) do
        if level >= config.minLevel and level <= config.maxLevel then
            return config
        end
    end
    return LevelConfig[1]
end

-- Função para pegar próximo NPC
local function getNextNPC(current, maxCount)
    local next = current + 1
    if next > maxCount then
        return 1
    end
    return next
end

-- Função para pegar NPC
local function getNPC(npcName, index)
    return workspace.NPCs:FindFirstChild(npcName .. index)
end

-- Função para pegar RootPart do NPC
local function getNPCRootPart(npc)
    if npc and npc:FindFirstChild("HumanoidRootPart") then
        return npc.HumanoidRootPart
    end
    return nil
end

-- Função para equipar arma
local function EquipWeapon()
    if not _G.SlowHub.SelectedWeapon then return false end
    
    local backpack = Player:FindFirstChild("Backpack")
    local character = Player.Character
    
    if not character or not character:FindFirstChild("Humanoid") then
        return false
    end
    
    -- Verificar se a arma já está equipada
    if character:FindFirstChild(_G.SlowHub.SelectedWeapon) then
        return true
    end
    
    -- Equipar da backpack
    if backpack then
        local weapon = backpack:FindFirstChild(_G.SlowHub.SelectedWeapon)
        if weapon then
            character.Humanoid:EquipTool(weapon)
            wait(0.1)
            return true
        end
    end
    
    return false
end

-- Função para parar Auto Level
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
    
    -- Stop player movement and unanchor
    if Player.Character then
        local playerRoot = Player.Character:FindFirstChild("HumanoidRootPart")
        if playerRoot then
            playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            playerRoot.Anchored = false
        end
    end
    
    -- Abandonar quest
    pcall(function()
        ReplicatedStorage.RemoteEvents.QuestAbandon:FireServer()
    end)
end

-- Função para iniciar Auto Level
local function startAutoLevel()
    if autoLevelConnection then
        stopAutoLevel()
    end
    
    _G.SlowHub.AutoFarmLevel = true
    currentNPCIndex = 1
    
    local config = GetCurrentConfig()
    
    -- Equipar arma ao iniciar
    EquipWeapon()
    
    -- Quest accept loop (continuous)
    autoLevelQuestLoop = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoFarmLevel then
            if autoLevelQuestLoop then
                autoLevelQuestLoop:Disconnect()
                autoLevelQuestLoop = nil
            end
            return
        end
        
        -- Atualizar config se mudou de nível
        config = GetCurrentConfig()
        
        pcall(function()
            ReplicatedStorage.RemoteEvents.QuestAccept:FireServer(config.quest)
        end)
    end)
    
    local lastDeathTimes = {}
    for i = 1, config.count do
        lastDeathTimes[i] = 0
    end
    
    local lastCheck = 0
    local lastNPCFound = nil
    
    autoLevelConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoFarmLevel then
            stopAutoLevel()
            return
        end
        
        -- Atualizar config se mudou de nível
        config = GetCurrentConfig()
        
        local now = tick()
        local npc = getNPC(config.npc, currentNPCIndex)
        
        if npc and npc.Parent then
            lastNPCFound = now
            
            -- Check _DeathTime more frequently (every 0.1 second)
            if now - lastCheck >= 0.1 then
                lastCheck = now
                local deathTimeAttr = npc:GetAttribute("_DeathTime")
                
                -- Check if NPC died (_DeathTime appeared or changed)
                if deathTimeAttr and deathTimeAttr > 0 then
                    if lastDeathTimes[currentNPCIndex] == 0 then
                        lastDeathTimes[currentNPCIndex] = deathTimeAttr
                    elseif deathTimeAttr ~= lastDeathTimes[currentNPCIndex] then
                        -- NPC died, switch immediately
                        lastDeathTimes[currentNPCIndex] = deathTimeAttr
                        currentNPCIndex = getNextNPC(currentNPCIndex, config.count)
                        return
                    end
                end
            end
            
            -- Farm current NPC
            local npcRoot = getNPCRootPart(npc)
            
            if npcRoot and npcRoot.Parent and Player.Character then
                local playerRoot = Player.Character:FindFirstChild("HumanoidRootPart")
                local humanoid = Player.Character:FindFirstChild("Humanoid")
                
                if playerRoot and humanoid and humanoid.Health > 0 then
                    -- Remove any unwanted velocity
                    playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    
                    -- Keep player near NPC with safer teleport (10 studs above, 5 studs forward)
                    local targetCFrame = npcRoot.CFrame
                    local offsetPosition = targetCFrame * CFrame.new(0, 5, 8)
                    
                    -- Only teleport if distance is reasonable
                    local distance = (playerRoot.Position - offsetPosition.Position).Magnitude
                    if distance > 3 or distance < 1 then
                        playerRoot.CFrame = offsetPosition
                    end
                    
                    -- Equipar arma
                    EquipWeapon()
                    
                    -- Attack NPC
                    pcall(function()
                        ReplicatedStorage.CombatSystem.Remotes.RequestHit:FireServer()
                    end)
                end
            end
        else
            -- NPC not found, stay still and wait
            if Player.Character then
                local playerRoot = Player.Character:FindFirstChild("HumanoidRootPart")
                if playerRoot then
                    -- Keep player grounded and still
                    playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                end
            end
            
            -- Wait 2 seconds before switching to next NPC
            if lastNPCFound == nil or (now - lastNPCFound) > 2 then
                currentNPCIndex = getNextNPC(currentNPCIndex, config.count)
                lastNPCFound = now
            end
        end
    end)
end

-- Toggle Auto Farm Level
Tab:CreateToggle({
    Name = "Auto Farm Level",
    CurrentValue = false,
    Flag = "AutoFarmLevelToggle",
    Callback = function(Value)
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                _G.Rayfield:Notify({
                    Title = "Slow Hub",
                    Content = "Please select a weapon first!",
                    Duration = 5,
                    Image = 4483345998
                })
                return
            end
            
            local config = GetCurrentConfig()
            _G.Rayfield:Notify({
                Title = "Slow Hub",
                Content = "Auto Farm enabled! Farming: " .. config.npc,
                Duration = 3,
                Image = 4483345998
            })
            
            startAutoLevel()
        else
            _G.Rayfield:Notify({
                Title = "Slow Hub",
                Content = "Auto Farm disabled!",
                Duration = 3,
                Image = 4483345998
            })
            stopAutoLevel()
        end
    end
})
