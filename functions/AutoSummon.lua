local Tab = _G.BossesTab
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BossList = {
    "QinShiBoss",
    "SaberBoss",
    "StrongestofTodayBoss", -- Novo
    "StrongestinHistoryBoss" -- Novo
}

local DifficultyList = {
    "Normal",
    "Medium",
    "Hard",
    "Extreme"
}

-- Configuração padrão
local autoSummonBossConnection = nil
local isSummoningBoss = false
local selectedBoss = nil
local selectedDifficulty = "Normal" -- Valor padrão

-- Tabela para identificar quais bosses precisam de sufixo de dificuldade
local bossesWithDifficulty = {
    ["StrongestofTodayBoss"] = true,
    ["StrongestinHistoryBoss"] = true
}

local function isBossAlive(bossName)
    local found = false
    pcall(function()
        -- Verifica na pasta de NPCs se o boss com o nome EXATO existe
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
    _G.SlowHub.AutoSummonBoss = false
end

local function startAutoSummonBoss()
    if autoSummonBossConnection then stopAutoSummonBoss() end
    
    isSummoningBoss = true
    _G.SlowHub.AutoSummonBoss = true
    
    autoSummonBossConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoSummonBoss or not isSummoningBoss then
            stopAutoSummonBoss()
            return
        end
        
        -- Formata o nome final do Boss
        local finalBossName = selectedBoss
        
        -- Se o boss selecionado for um dos novos, adiciona a dificuldade (ex: _Extreme)
        if bossesWithDifficulty[selectedBoss] then
            finalBossName = selectedBoss .. "_" .. selectedDifficulty
        end
        
        -- Verifica se esse boss específico já está vivo
        if isBossAlive(finalBossName) then
            return 
        end
        
        -- Tenta invocar
        pcall(function()
            ReplicatedStorage.Remotes.RequestSummonBoss:FireServer(finalBossName)
        end)
    end)
end

-- === RAYFIELD UI === --

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
    CurrentOption = {"Normal"}, -- Padrão Normal
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
                _G.SlowHub.AutoSummonBoss = false
                return
            end
            startAutoSummonBoss()
        else
            stopAutoSummonBoss()
        end
        _G.SlowHub.AutoSummonBoss = Value
    end
})
