local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local Tab = _G.BossesTab

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.AutoSummonBoss = false
_G.SlowHub.SummonInterval = _G.SlowHub.SummonInterval or 0.5

local BossConfigs = {
    ["Anos"] = {
        Method = "AnosSpecific",
        InternalName = "Anos"
    },
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

table.sort(BossList)

local DifficultyList = {
    "Normal",
    "Medium",
    "Hard",
    "Extreme"
}

local SummonState = {
    Connection = nil,
    IsSummoning = false,
    SelectedBosses = {},
    SelectedDifficulty = "Normal"
}

local function IsBossAlive(bossName)
    local found = false
    
    pcall(function()
        if not workspace:FindFirstChild("NPCs") then return end
        
        local boss = workspace.NPCs:FindFirstChild(bossName)
        if not boss then return end
        
        local humanoid = boss:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 then
            found = true
        end
    end)
    
    return found
end

local function IsPitySystemEnabled()
    if not _G.SlowHub then return false end
    return _G.SlowHub.PriorityPityEnabled == true
end

local function GetPityTargetBoss()
    if not _G.SlowHub then return "" end
    return _G.SlowHub.PityTargetBoss or ""
end

local function IsPityTargetTime()
    if not _G.SlowHub then return false end
    if _G.SlowHub.IsPityTargetTime then
        return _G.SlowHub.IsPityTargetTime()
    end
    return false
end

local function IsPityTargetBoss(bossName)
    local pityTarget = GetPityTargetBoss()
    if pityTarget == "" then return false end
    return bossName == pityTarget
end

local function GetFilteredBossesToSummon()
    local bossesToSummon = {}
    
    local pityEnabled = IsPitySystemEnabled()
    local pityTargetTime = IsPityTargetTime()
    
    for _, selectedBoss in ipairs(SummonState.SelectedBosses) do
        local config = BossConfigs[selectedBoss]
        if not config then continue end
        
        if pityEnabled then
            if IsPityTargetBoss(selectedBoss) then
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
    
    return bossesToSummon
end

local function GetNamesToCheck(config, currentBossName)
    local namesToCheck = {}
    
    if config.Method == "New" or config.Method == "RimuruSpecific" or config.Method == "Gilgamesh" or config.Method == "AnosSpecific" then
        table.insert(namesToCheck, config.InternalName .. "_" .. SummonState.SelectedDifficulty)
        table.insert(namesToCheck, currentBossName .. "_" .. SummonState.SelectedDifficulty)
    else
        table.insert(namesToCheck, currentBossName)
        table.insert(namesToCheck, config.InternalName)
    end
    
    return namesToCheck
end

local function SummonBoss(currentBossName, config)
    local success = pcall(function()
        if config.Method == "RimuruSpecific" then
            local args = {SummonState.SelectedDifficulty}
            
            local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            
            if remoteEvents and remoteEvents:FindFirstChild("RequestSpawnRimuru") then
                remoteEvents.RequestSpawnRimuru:FireServer(unpack(args))
            elseif remotes and remotes:FindFirstChild("RequestSpawnRimuru") then
                remotes.RequestSpawnRimuru:FireServer(unpack(args))
            end
            
        elseif config.Method == "Gilgamesh" then
            local args = {
                config.InternalName,
                SummonState.SelectedDifficulty
            }
            
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes and remotes:FindFirstChild("RequestSummonBoss") then
                remotes.RequestSummonBoss:FireServer(unpack(args))
            end
            
        elseif config.Method == "New" then
            local args = {
                config.InternalName,
                SummonState.SelectedDifficulty
            }
            
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes and remotes:FindFirstChild("RequestSpawnStrongestBoss") then
                remotes.RequestSpawnStrongestBoss:FireServer(unpack(args))
            end
            
        elseif config.Method == "AnosSpecific" then
            local args = {
                config.InternalName,
                SummonState.SelectedDifficulty
            }
            
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes and remotes:FindFirstChild("RequestSpawnAnosBoss") then
                remotes.RequestSpawnAnosBoss:FireServer(unpack(args))
            end
            
        else
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes and remotes:FindFirstChild("RequestSummonBoss") then
                remotes.RequestSummonBoss:FireServer(currentBossName)
            end
        end
    end)
    
    return success
end

local function ProcessBossSummon(currentBossName)
    local config = BossConfigs[currentBossName]
    if not config then return end
    
    local namesToCheck = GetNamesToCheck(config, currentBossName)
    
    local bossAlreadyAlive = false
    for _, name in ipairs(namesToCheck) do
        if IsBossAlive(name) then
            bossAlreadyAlive = true
            break
        end
    end
    
    if not bossAlreadyAlive then
        SummonBoss(currentBossName, config)
    end
end

local function SummonLoop()
    if not _G.SlowHub.AutoSummonBoss then
        StopAutoSummonBoss()
        return
    end
    
    local bossesToSummon = GetFilteredBossesToSummon()
    
    for _, bossName in ipairs(bossesToSummon) do
        ProcessBossSummon(bossName)
    end
end

local function StopAutoSummonBoss()
    SummonState.IsSummoning = false
    
    if SummonState.Connection then
        SummonState.Connection:Disconnect()
        SummonState.Connection = nil
    end
    
    _G.SlowHub.AutoSummonBoss = false
end

local function StartAutoSummonBoss()
    if SummonState.IsSummoning then
        StopAutoSummonBoss()
        task.wait(0.2)
    end
    
    SummonState.IsSummoning = true
    _G.SlowHub.AutoSummonBoss = true
    
    SummonState.Connection = RunService.Heartbeat:Connect(function()
        SummonLoop()
        task.wait(_G.SlowHub.SummonInterval)
    end)
end

local function Notify(title, content, duration)
    duration = duration or 3
    
    pcall(function()
        if _G.WindUI and _G.WindUI.Notify then
            _G.WindUI:Notify({
                Title = title,
                Content = content,
                Duration = duration,
                Icon = "rbxassetid://4483362458"
            })
        end
    end)
end

Tab:Section({Title = "Summon Settings"})

Tab:Dropdown({
    Title = "Select Bosses to Summon",
    Values = BossList,
    Multi = true,
    Default = {},
    Callback = function(Value)
        SummonState.SelectedBosses = {}
        
        if type(Value) == "table" then
            for _, boss in ipairs(Value) do
                table.insert(SummonState.SelectedBosses, boss)
            end
        end
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

Tab:Dropdown({
    Title = "Select Difficulty",
    Values = DifficultyList,
    Default = "Normal",
    Callback = function(Value)
        local val = type(Value) == "table" and Value[1] or Value
        SummonState.SelectedDifficulty = val
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

Tab:Slider({
    Title = "Summon Interval",
    Step = 0.1,
    Value = {
        Min = 0.1,
        Max = 2,
        Default = _G.SlowHub.SummonInterval,
    },
    Callback = function(Value)
        _G.SlowHub.SummonInterval = Value
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

Tab:Toggle({
    Title = "Auto Summon Boss",
    Default = false,
    Callback = function(Value)
        if Value then
            if not SummonState.SelectedBosses or #SummonState.SelectedBosses == 0 then
                Notify("Error", "Please select at least one Boss to summon!", 3)
                return
            end
            
            StartAutoSummonBoss()
        else
            StopAutoSummonBoss()
        end
        
        _G.SlowHub.AutoSummonBoss = Value
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})
