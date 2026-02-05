local Tab = _G.BossesTab
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BossList = {
    "QinShiBoss",
    "SaberBoss",
    "StrongestofTodayBoss",
    "StrongestinHistoryBoss"
}

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

local bossesWithDifficulty = {
    ["StrongestofTodayBoss"] = true,
    ["StrongestinHistoryBoss"] = true
}

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
        
        local workspaceCheckName = selectedBoss
        
        if bossesWithDifficulty[selectedBoss] then
            workspaceCheckName = selectedBoss .. "_" .. selectedDifficulty
        end
        
        if isBossAlive(workspaceCheckName) then
            return 
        end
        
        pcall(function()
            if bossesWithDifficulty[selectedBoss] then
                ReplicatedStorage.Remotes.RequestSummonBoss:FireServer(selectedBoss, selectedDifficulty)
            else
                ReplicatedStorage.Remotes.RequestSummonBoss:FireServer(selectedBoss)
            end
        end)
    end)
end

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
