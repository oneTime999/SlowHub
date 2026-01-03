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

-- Inicializa configurações se não existirem
if not _G.SlowHub.FarmDistance then
    _G.SlowHub.FarmDistance = 8
end

if not _G.SlowHub.FarmPosition then
    _G.SlowHub.FarmPosition = "Front"
end

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

-- Função para calcular a posição baseada no dropdown
local function CalculateFarmPosition(npcCFrame)
    local distance = _G.SlowHub.FarmDistance
    local position = _G.SlowHub.FarmPosition
    
    if position == "Top" then
        -- Em cima do mob
        return npcCFrame + Vector3.new(0, distance, 0)
    elseif position == "Bottom" then
        -- Em baixo do mob
        return npcCFrame + Vector3.new(0, -distance, 0)
    else -- Front (padrão)
        -- Na frente do mob
        return npcCFrame + (npcCFrame.LookVector * distance) + Vector3.new(0, 4, 0)
    end
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
    
    pcall(function()
        if Player.Character then
            local playerRoot = Player.Character:FindFirstChild("HumanoidRootPart")
            if playerRoot then
                playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                playerRoot.Anchored = false
            end
        end
    end)
    
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
    
    EquipWeapon()
    
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
    
    local lastNPCFound = nil
    
    autoLevelConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoFarmLevel then
            stopAutoLevel()
            return
        end
        
        config = GetCurrentConfig()
        
        local now = tick()
        local npc = getNPC(config.npc, currentNPCIndex)
        
        if npc and npc.Parent then
            local npcHumanoid = npc:FindFirstChild("Humanoid")
            
            if npcHumanoid and npcHumanoid.Health <= 0 then
                currentNPCIndex = getNextNPC(currentNPCIndex, config.count)
                return
            end
            
            lastNPCFound = now
            
            local npcRoot = getNPCRootPart(npc)
            
            if npcRoot and npcRoot.Parent and Player.Character then
                local playerRoot = Player.Character:FindFirstChild("HumanoidRootPart")
                local humanoid = Player.Character:FindFirstChild("Humanoid")
                
                if playerRoot and humanoid and humanoid.Health > 0 then
                    pcall(function()
                        playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        
                        -- Calcula a posição usando a função
                        local targetPosition = CalculateFarmPosition(npcRoot.CFrame)
                        
                        -- Move o player para a posição
                        playerRoot.CFrame = CFrame.new(targetPosition.Position, npcRoot.Position)
                        
                        EquipWeapon()
                        
                        ReplicatedStorage.CombatSystem.Remotes.RequestHit:FireServer()
                    end)
                end
            end
        else
            pcall(function()
                if Player.Character then
                    local playerRoot = Player.Character:FindFirstChild("HumanoidRootPart")
                    if playerRoot then
                        playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    end
                end
            end)
            
            if lastNPCFound == nil or (now - lastNPCFound) > 0.3 then
                currentNPCIndex = getNextNPC(currentNPCIndex, config.count)
                lastNPCFound = now
            end
        end
    end)
end

-- Toggle Auto Farm Level
Tab:CreateToggle({
    Name = "Auto Farm Level",
    CurrentValue = _G.SlowHub.AutoFarmLevel,
    Flag = "AutoFarmLevelToggle",
    Callback = function(Value)
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                pcall(function()
                    _G.Rayfield:Notify({
                        Title = "Slow Hub",
                        Content = "Please select a weapon first!",
                        Duration = 5,
                        Image = 105026320884681
                    })
                end)
                return
            end
            
            local config = GetCurrentConfig()
            pcall(function()
                _G.Rayfield:Notify({
                    Title = "Slow Hub",
                    Content = "Farming: " .. config.npc,
                    Duration = 3,
                    Image = 105026320884681
                })
            end)
            
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

-- Dropdown para escolher posição
Tab:CreateDropdown({
    Name = "Farm Position",
    Options = {"Front", "Top", "Bottom"},
    CurrentOption = {"Front"},
    MultipleOptions = false,
    Flag = "FarmPositionDropdown",
    Callback = function(Option)
        -- Option pode vir como tabela em alguns casos
        local selected = type(Option) == "table" and Option[1] or Option
        _G.SlowHub.FarmPosition = selected
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
        
        local messages = {
            Front = "in front of the mob",
            Top = "on top of the mob",
            Bottom = "below the mob"
        }
        
        pcall(function()
            _G.Rayfield:Notify({
                Title = "Slow Hub",
                Content = "Now farming " .. (messages[selected] or ""),
                Duration = 2,
                Image = 105026320884681
            })
        end)
    end,
})

-- Slider para controlar distância
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
        
        pcall(function()
            _G.Rayfield:Notify({
                Title = "Slow Hub",
                Content = "Distance: " .. Value .. " studs",
                Duration = 2,
                Image = 105026320884681
            })
        end)
    end,
})

-- Auto iniciar se estava ativado
if _G.SlowHub.AutoFarmLevel and _G.SlowHub.SelectedWeapon then
    task.wait(2)
    startAutoLevel()
end
