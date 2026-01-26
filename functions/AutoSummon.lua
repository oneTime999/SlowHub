local Tab = _G.BossesTab
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BossList = {
    "QinShiBoss",
    "SaberBoss"
}

local autoSummonBossConnection = nil
local isSummoningBoss = false
local selectedBoss = nil

local function isBossAlive(bossName)
    local found = false
    pcall(function()
        for _, obj in pairs(workspace.NPCs:GetChildren()) do
            if obj.Name == bossName then
                local humanoid = obj:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    found = true
                end
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
        
        if isBossAlive(selectedBoss) then
            return 
        end
        
        pcall(function()
            ReplicatedStorage.Remotes.RequestSummonBoss:FireServer(selectedBoss)
        end)
    end)
end

-- UI RAYFIELD
Tab:CreateDropdown({
    Name = "Select Boss to Summon",
    Options = BossList,
    CurrentOption = {""},
    MultipleOptions = false,
    Flag = "SelectBossSummon",
    Callback = function(Value)
        -- Correção para Tabela vs String
        local val = (type(Value) == "table" and Value[1]) or Value
        selectedBoss = val
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
                    Title = "Erro",
                    Content = "Selecione um Boss para invocar!",
                    Duration = 3,
                    Image = 4483362458,
                })
                return
            end
            startAutoSummonBoss()
        else
            stopAutoSummonBoss()
        end
        _G.SlowHub.AutoSummonBoss = Value
    end
})
