local Tab = _G.MainTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer

-- Configurações de NPCs por nível
local LevelConfig = {
    {minLevel = 1, maxLevel = 249, quest = "QuestNPC1", npc = "Thief"},
    {minLevel = 250, maxLevel = 749, quest = "QuestNPC3", npc = "Monkey"},
    {minLevel = 750, maxLevel = 1499, quest = "QuestNPC5", npc = "DesertBandit"},
    {minLevel = 1500, maxLevel = 2999, quest = "QuestNPC7", npc = "DesertBandit"},
    {minLevel = 3000, maxLevel = 99999, quest = "QuestNPC9", npc = "Sorcerer"}
}

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

-- Função para aceitar quest
local function AcceptQuest(questName)
    pcall(function()
        ReplicatedStorage.RemoteEvents.QuestAccept:FireServer(questName)
    end)
end

-- Função para abandonar quest
local function AbandonQuest()
    pcall(function()
        ReplicatedStorage.RemoteEvents.QuestAbandon:FireServer()
    end)
end

-- Função para atacar NPC
local function AttackNPC(npc)
    if not npc or not npc:FindFirstChild("Humanoid") or npc.Humanoid.Health <= 0 then
        return false
    end
    
    local character = Player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    pcall(function()
        local npcPos = npc.HumanoidRootPart.Position
        local hrp = character.HumanoidRootPart
        
        -- Congelar o player no ar (não cai)
        hrp.Anchored = true
        
        -- Teleportar 10 studs acima do NPC
        hrp.CFrame = CFrame.new(npcPos.X, npcPos.Y + 10, npcPos.Z)
        
        -- Equipar arma
        EquipWeapon()
        
        -- Atacar
        ReplicatedStorage.CombatSystem.Remotes.RequestHit:FireServer()
    end)
    
    return true
end

-- Função principal do Auto Farm
local function AutoFarmLoop()
    -- Equipar arma ao iniciar
    EquipWeapon()
    
    while _G.SlowHub.AutoFarmLevel do
        wait(0.1)
        
        pcall(function()
            local config = GetCurrentConfig()
            local npcFolder = workspace.NPCs
            
            -- Aceitar quest
            AcceptQuest(config.quest)
            
            -- Garantir que a arma está equipada
            EquipWeapon()
            
            -- Procurar NPCs para matar
            local foundNPC = false
            for i = 1, 5 do
                local npcName = config.npc .. i
                local npc = npcFolder:FindFirstChild(npcName)
                
                if npc and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 then
                    foundNPC = true
                    AttackNPC(npc)
                    break
                end
            end
            
            -- Se não encontrou nenhum NPC vivo, espera respawn
            if not foundNPC then
                wait(2)
            end
        end)
    end
    
    -- Desancorar player ao desativar
    local character = Player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        character.HumanoidRootPart.Anchored = false
    end
    
    -- Abandonar quest ao desativar
    AbandonQuest()
end

-- Toggle Auto Farm Level
Tab:CreateToggle({
    Name = "Auto Farm Level",
    CurrentValue = false,
    Flag = "AutoFarmLevelToggle",
    Callback = function(Value)
        _G.SlowHub.AutoFarmLevel = Value
        
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
            
            spawn(AutoFarmLoop)
        else
            _G.Rayfield:Notify({
                Title = "Slow Hub",
                Content = "Auto Farm disabled!",
                Duration = 3,
                Image = 4483345998
            })
        end
    end
})
