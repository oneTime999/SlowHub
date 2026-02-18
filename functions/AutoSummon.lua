local Tab = _G.BossesTab
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BossConfigs = {
    ["RimuruBoss"] = {
        Method = "RimuruSpecific",
        InternalName = "Rimuru"
    },
    ["GilgameshBoss"] = {
        Method = "Gilgamesh",
        InternalName = "GilgameshBoss"
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
local selectedBosses = _G.SlowHub.SelectedSummonBosses or {} 
local selectedDifficulty = _G.SlowHub.SelectedSummonDifficulty or "Normal"

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

local function isPityTargetTime()
    if _G.SlowHub and _G.SlowHub.IsPityTargetTime then
        return _G.SlowHub.IsPityTargetTime()
    end
    return false
end

local function getPityTargetBoss()
    if _G.SlowHub and _G.SlowHub.PityTargetBoss then
        return _G.SlowHub.PityTargetBoss
    end
    return ""
end

local function isPitySystemEnabled()
    if _G.SlowHub and _G.SlowHub.PriorityPityEnabled then
        return _G.SlowHub.PriorityPityEnabled
    end
    return false
end

local function isPityTargetBoss(bossName)
    local pityTarget = getPityTargetBoss()
    if pityTarget == "" then return false end
    return bossName == pityTarget
end

local function stopAutoSummonBoss()
    isSummoningBoss = false
    if autoSummonBossConnection then
        autoSummonBossConnection:Disconnect()
        autoSummonBossConnection = nil
    end
    if _G.SlowHub then _G.SlowHub.AutoSummon = false end
end

local function startAutoSummonBoss()
    if autoSummonBossConnection then stopAutoSummonBoss() end
    
    isSummoningBoss = true
    if _G.SlowHub then _G.SlowHub.AutoSummon = true end
    
    autoSummonBossConnection = RunService.Heartbeat:Connect(function()
        if (_G.SlowHub and not _G.SlowHub.AutoSummon) or not isSummoningBoss then
            stopAutoSummonBoss()
            return
        end
        
        local pityEnabled = isPitySystemEnabled()
        local pityTargetTime = isPityTargetTime()
        local pityTargetBoss = getPityTargetBoss()
        
        local bossesToSummon = {}
        
        for _, selectedBoss in pairs(selectedBosses) do
            local config = BossConfigs[selectedBoss]
            if not config then continue end
            
            if pityEnabled and pityTargetBoss ~= "" then
                if isPityTargetBoss(selectedBoss) then
                    if pityTargetTime then
                        table.insert(bossesToSummon, selectedBoss)
                    end
                else
                    if not pityTargetTime then
                        table.insert(bossesToSummon, selectedBoss)
                    end
                end
            else
                table.insert(bossesToSummon, selectedBoss)
            end
        end
        
        for _, currentBossName in pairs(bossesToSummon) do
            local config = BossConfigs[currentBossName]
            
            if config then
                local namesToCheck = {}
                if config.Method == "New" or config.Method == "RimuruSpecific" or config.Method == "Gilgamesh" then
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
                
                if not bossAlreadyAlive then
                    pcall(function()
                        if config.Method == "RimuruSpecific" then
                            local args = { [1] = selectedDifficulty }
                            if ReplicatedStorage:FindFirstChild("RemoteEvents") and ReplicatedStorage.RemoteEvents:FindFirstChild("RequestSpawnRimuru") then
                                ReplicatedStorage.RemoteEvents.RequestSpawnRimuru:FireServer(unpack(args))
                            elseif ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("RequestSpawnRimuru") then
                                ReplicatedStorage.Remotes.RequestSpawnRimuru:FireServer(unpack(args))
                            end
                        elseif config.Method == "Gilgamesh" then
                            local args = {
                                [1] = config.InternalName,
                                [2] = selectedDifficulty
                            }
                            ReplicatedStorage.Remotes.RequestSummonBoss:FireServer(unpack(args))
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

Tab:CreateSection("Summon Settings")

Tab:CreateDropdown({
    Name = "Select Bosses to Summon",
    Options = BossList,
    CurrentOption = _G.SlowHub.SelectedSummonBosses or {},
    MultipleOptions = true,
    Flag = "SelectBossSummon",
    Callback = function(Value)
        selectedBosses = Value
        _G.SlowHub.SelectedSummonBosses = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

Tab:CreateDropdown({
    Name = "Select Difficulty",
    Options = DifficultyList,
    CurrentOption = {_G.SlowHub.SelectedSummonDifficulty or "Normal"},
    MultipleOptions = false,
    Flag = "SelectBossDifficulty",
    Callback = function(Value)
        local val = (type(Value) == "table" and Value[1]) or Value
        selectedDifficulty = val
        _G.SlowHub.SelectedSummonDifficulty = val
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

Tab:CreateToggle({
    Name = "Auto Summon Boss",
    CurrentValue = _G.SlowHub.AutoSummon or false,
    Flag = "AutoSummonBoss",
    Callback = function(Value)
        if Value then
            if not selectedBosses or #selectedBosses == 0 then
                Rayfield:Notify({
                    Title = "Error",
                    Content = "Please select at least one Boss to summon!",
                    Duration = 3,
                    Image = 4483362458,
                })
                if _G.SlowHub then _G.SlowHub.AutoSummon = false end
                return
            end
            startAutoSummonBoss()
        else
            stopAutoSummonBoss()
        end
        if _G.SlowHub then _G.SlowHub.AutoSummon = Value end
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})
