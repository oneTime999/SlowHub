local Tab = _G.BossesTab
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BossConfigs = {
    ["RimuruBoss"] = {
        Method = "New",
        InternalName = "Rimuru" -- O Remote usa isso, mas o modelo pode ser RimuruBoss_Normal
    },
    ["StrongestofTodayBoss"] = {
        Method = "New",
        InternalName = "StrongestToday"
    },
    ["StrongestinHistoryBoss"] = {
        Method = "New",
        InternalName = "StrongestHistory"
    },
    ["IchigoBoss"] = {
        Method = "Old",
        InternalName = "IchigoBoss"
    },
    ["QinShiBoss"] = {
        Method = "Old",
        InternalName = "QinShiBoss"
    },
    ["SaberBoss"] = {
        Method = "Old",
        InternalName = "SaberBoss"
    }
}

local BossList = {}
for name, _ in pairs(BossConfigs) do
    table.insert(BossList, name)
end

local DifficultyList = {
    "Normal",
    "Medium",
    "Hard",
    "Extreme"
}

local autoSummonBossConnection = nil
local isSummoningBoss = false
local selectedBoss = nil
local selectedDifficulty = "Normal"

-- Função de verificação melhorada
local function isBossAlive(bossName)
    local found = false
    pcall(function()
        local boss = workspace.NPCs:FindFirstChild(bossName)
        if boss then
            local humanoid = boss:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                found = true
            end
        end
    end)
    return found
end

local function stopAutoSummonBoss()
    isSummoningBoss = false
    if autoSummonBossConnection then
        autoSummonBossConnection:Disconnect()
        autoSummonBossConnection = nil
    end
    if _G.SlowHub then _G.SlowHub.AutoSummonBoss = false end
end

local function startAutoSummonBoss()
    if autoSummonBossConnection then stopAutoSummonBoss() end
    
    isSummoningBoss = true
    if _G.SlowHub then _G.SlowHub.AutoSummonBoss = true end
    
    autoSummonBossConnection = RunService.Heartbeat:Connect(function()
        if (_G.SlowHub and not _G.SlowHub.AutoSummonBoss) or not isSummoningBoss then
            stopAutoSummonBoss()
            return
        end
        
        local config = BossConfigs[selectedBoss]
        if not config then return end

        -- LÓGICA CORRIGIDA AQUI
        -- Verifica múltiplas possibilidades de nome para garantir que encontre o Boss
        local namesToCheck = {}
        
        if config.Method == "New" then
            -- Possibilidade 1: Baseado no InternalName (Ex: Rimuru_Normal)
            table.insert(namesToCheck, config.InternalName .. "_" .. selectedDifficulty)
            -- Possibilidade 2: Baseado na Chave/Seleção (Ex: RimuruBoss_Normal) - Correção solicitada
            table.insert(namesToCheck, selectedBoss .. "_" .. selectedDifficulty)
        else
            table.insert(namesToCheck, selectedBoss)
            table.insert(namesToCheck, config.InternalName)
        end
        
        local bossAlreadyAlive = false
        for _, name in ipairs(namesToCheck) do
            if isBossAlive(name) then
                bossAlreadyAlive = true
                break
            end
        end
        
        if bossAlreadyAlive then
            return 
        end
        
        pcall(function()
            if config.Method == "New" then
                local args = {
                    [1] = config.InternalName,
                    [2] = selectedDifficulty
                }
                ReplicatedStorage.Remotes.RequestSpawnStrongestBoss:FireServer(unpack(args))
            else
                ReplicatedStorage.Remotes.RequestSummonBoss:FireServer(selectedBoss)
            end
        end)
    end)
end

-- UI
Tab:CreateSection("Summon Settings")

Tab:CreateDropdown({
    Name = "Select Boss to Summon",
    Options = BossList,
    CurrentOption = {""},
    MultipleOptions = false,
    Flag = "SelectBossSummon",
    Callback = function(Value)
        local val = (type(Value) == "table" and Value[1]) or Value
        selectedBoss = val
    end
})

Tab:CreateDropdown({
    Name = "Select Difficulty (New Bosses Only)",
    Options = DifficultyList,
    CurrentOption = {"Normal"},
    MultipleOptions = false,
    Flag = "SelectBossDifficulty",
    Callback = function(Value)
        local val = (type(Value) == "table" and Value[1]) or Value
        selectedDifficulty = val
    end
})

Tab:CreateToggle({
    Name = "Auto Summon Boss",
    CurrentValue = false,
    Flag = "AutoSummonBoss",
    Callback = function(Value)
        if Value then
            if not selectedBoss or selectedBoss == "" then
                Rayfield:Notify({
                    Title = "Error",
                    Content = "Please select a Boss to summon!",
                    Duration = 3,
                    Image = 4483362458,
                })
                if _G.SlowHub then _G.SlowHub.AutoSummonBoss = false end
                return
            end
            startAutoSummonBoss()
        else
            stopAutoSummonBoss()
        end
        if _G.SlowHub then _G.SlowHub.AutoSummonBoss = Value end
    end
})
