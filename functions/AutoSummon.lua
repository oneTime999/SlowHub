local Tab = _G.BossesTab
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BossConfigs = {
    ["RimuruBoss"] = {
        Method = "RimuruSpecific",
        InternalName = "Rimuru"
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
local selectedBosses = {} -- Alterado para tabela para suportar múltiplos
local selectedDifficulty = "Normal"

-- Função de verificação de vida
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
        
        -- AQUI É A MUDANÇA PRINCIPAL: Loop através de todos os bosses selecionados
        for _, currentBossName in pairs(selectedBosses) do
            local config = BossConfigs[currentBossName]
            
            if config then
                -- Verificação de nome para o boss atual do loop
                local namesToCheck = {}
                
                if config.Method == "New" or config.Method == "RimuruSpecific" then
                    table.insert(namesToCheck, config.InternalName .. "_" .. selectedDifficulty)
                    table.insert(namesToCheck, currentBossName .. "_" .. selectedDifficulty)
                else
                    table.insert(namesToCheck, currentBossName)
                    table.insert(namesToCheck, config.InternalName)
                end
                
                local bossAlreadyAlive = false
                for _, name in ipairs(namesToCheck) do
                    if isBossAlive(name) then
                        bossAlreadyAlive = true
                        break
                    end
                end
                
                -- Se este boss específico não estiver vivo, tenta spawnar
                if not bossAlreadyAlive then
                    pcall(function()
                        if config.Method == "RimuruSpecific" then
                            local args = { [1] = selectedDifficulty }
                            if ReplicatedStorage:FindFirstChild("RemoteEvents") and ReplicatedStorage.RemoteEvents:FindFirstChild("RequestSpawnRimuru") then
                                ReplicatedStorage.RemoteEvents.RequestSpawnRimuru:FireServer(unpack(args))
                            elseif ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("RequestSpawnRimuru") then
                                ReplicatedStorage.Remotes.RequestSpawnRimuru:FireServer(unpack(args))
                            end
                            
                        elseif config.Method == "New" then
                            local args = {
                                [1] = config.InternalName,
                                [2] = selectedDifficulty
                            }
                            ReplicatedStorage.Remotes.RequestSpawnStrongestBoss:FireServer(unpack(args))
                        else
                            ReplicatedStorage.Remotes.RequestSummonBoss:FireServer(currentBossName)
                        end
                    end)
                end
            end
        end
    end)
end

-- UI
Tab:CreateSection("Summon Settings")

Tab:CreateDropdown({
    Name = "Select Bosses to Summon", -- Atualizado nome para plural
    Options = BossList,
    CurrentOption = {""},
    MultipleOptions = true, -- Isso permite selecionar vários
    Flag = "SelectBossSummon",
    Callback = function(Value)
        -- Agora aceitamos a tabela inteira, não apenas o [1]
        selectedBosses = Value
    end
})

Tab:CreateDropdown({
    Name = "Select Difficulty",
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
            -- Verifica se a tabela está vazia
            if not selectedBosses or #selectedBosses == 0 then
                Rayfield:Notify({
                    Title = "Error",
                    Content = "Please select at least one Boss to summon!",
                    Duration = 3,
                    Image = 4483362458,
                })
                if _G.SlowHub then _G.SlowHub.AutoSummonBoss = false end
                -- Resetar toggle visualmente pode necessitar de código extra dependendo da Lib, mas o return previne o loop
                return
            end
            startAutoSummonBoss()
        else
            stopAutoSummonBoss()
        end
        if _G.SlowHub then _G.SlowHub.AutoSummonBoss = Value end
    end
})
