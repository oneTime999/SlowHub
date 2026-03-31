local Tab = _G.BossesTab
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local bossConfigs = {
    -- SEM DIFICULDADE (só o nome)
    ["IchigoBoss"] = {Method="Old", InternalName="IchigoBoss"},
    ["QinShiBoss"] = {Method="Old", InternalName="QinShiBoss"},
    ["SaberBoss"] = {Method="Old", InternalName="SaberBoss"},
    
    -- COM DIFICULDADE (Nome + Dificuldade)
    ["Anos"] = {Method="AnosSpecific", InternalName="Anos"},
    ["RimuruBoss"] = {Method="RimuruSpecific", InternalName="Rimuru"},
    ["GilgameshBoss"] = {Method="Gilgamesh", InternalName="GilgameshBoss"},
    ["StrongestofTodayBoss"] = {Method="New", InternalName="StrongestToday"},
    ["StrongestinHistoryBoss"] = {Method="New", InternalName="StrongestHistory"},
    ["BlessedMaidenBoss"] = {Method="Gilgamesh", InternalName="BlessedMaidenBoss"},
    ["SaberAlterBoss"] = {Method="Gilgamesh", InternalName="SaberAlterBoss"},
    
    -- NOVOS BOSSES
    ["AtomicBoss"] = {Method="AtomicSpecific", InternalName="AtomicBoss"},
    ["TrueAizenBoss"] = {Method="TrueAizenSpecific", InternalName="TrueAizenBoss"},
    ["MoonSlayerBoss"] = {Method="MoonSlayerSpecific", InternalName="MoonSlayerBoss"},
}

-- ORDENAÇÃO ALFABÉTICA AUTOMÁTICA (A-Z)
local bossList = {}
for name in pairs(bossConfigs) do table.insert(bossList, name) end
table.sort(bossList)

local difficultyList = {"Normal","Medium","Hard","Extreme"}

local summonConnection = nil
local isSummoning = false
local selectedBosses = {}
local selectedDifficulty = "Normal"
local lastSummonTime = {}

local function isBossAlive(bossName)
    local found = false
    pcall(function()
        if not workspace:FindFirstChild("NPCs") then return end
        -- Verifica o nome exato ou com sufixo de dificuldade (Ex: MoonSlayerBoss_Normal)
        local boss = workspace.NPCs:FindFirstChild(bossName) or workspace.NPCs:FindFirstChild(bossName .. "_" .. selectedDifficulty)
        if not boss then return end
        local humanoid = boss:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 then found = true end
    end)
    return found
end

local function isPitySystemEnabled()
    return _G.SlowHub and _G.SlowHub.PriorityPityEnabled == true
end

local function getPityTargetBoss()
    return _G.SlowHub and _G.SlowHub.PityTargetBoss or ""
end

local function isPityTargetTime()
    if _G.SlowHub and _G.SlowHub.IsPityTargetTime then
        return _G.SlowHub.IsPityTargetTime()
    end
    return false
end

local function getFilteredBossesToSummon()
    local bossesToSummon = {}
    local pityEnabled = isPitySystemEnabled()
    local pityTargetTime = isPityTargetTime()
    local pityTarget = getPityTargetBoss()
    
    for _, selectedBoss in ipairs(selectedBosses) do
        if not bossConfigs[selectedBoss] then continue end
        
        if pityEnabled and pityTarget ~= "" then
            if selectedBoss == pityTarget then
                if pityTargetTime then table.insert(bossesToSummon, selectedBoss) end
            else
                if not pityTargetTime then table.insert(bossesToSummon, selectedBoss) end
            end
        else
            table.insert(bossesToSummon, selectedBoss)
        end
    end
    return bossesToSummon
end

local function summonBoss(currentBossName, config)
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")

        if config.Method == "MoonSlayerSpecific" then
            if remotes and remotes:FindFirstChild("RequestSummonBoss") then
                remotes.RequestSummonBoss:FireServer("MoonSlayerBoss", selectedDifficulty)
            end

        elseif config.Method == "Old" then
            if remotes and remotes:FindFirstChild("RequestSummonBoss") then
                remotes.RequestSummonBoss:FireServer(currentBossName)
            end
            
        elseif config.Method == "Gilgamesh" then
            if remotes and remotes:FindFirstChild("RequestSummonBoss") then
                remotes.RequestSummonBoss:FireServer(config.InternalName, selectedDifficulty)
            end
            
        elseif config.Method == "RimuruSpecific" then
            if remoteEvents and remoteEvents:FindFirstChild("RequestSpawnRimuru") then
                remoteEvents.RequestSpawnRimuru:FireServer(selectedDifficulty)
            elseif remotes and remotes:FindFirstChild("RequestSpawnRimuru") then
                remotes.RequestSpawnRimuru:FireServer(selectedDifficulty)
            end
            
        elseif config.Method == "New" then
            if remotes and remotes:FindFirstChild("RequestSpawnStrongestBoss") then
                remotes.RequestSpawnStrongestBoss:FireServer(config.InternalName, selectedDifficulty)
            end
            
        elseif config.Method == "AnosSpecific" then
            if remotes and remotes:FindFirstChild("RequestSpawnAnosBoss") then
                remotes.RequestSpawnAnosBoss:FireServer(config.InternalName, selectedDifficulty)
            end
            
        elseif config.Method == "AtomicSpecific" then
            if remoteEvents and remoteEvents:FindFirstChild("RequestSpawnAtomic") then
                remoteEvents.RequestSpawnAtomic:FireServer(selectedDifficulty)
            end
            
        elseif config.Method == "TrueAizenSpecific" then
            if remoteEvents and remoteEvents:FindFirstChild("RequestSpawnTrueAizen") then
                remoteEvents.RequestSpawnTrueAizen:FireServer(selectedDifficulty)
            end
        end
    end)
end

local function processBossSummon(currentBossName)
    local config = bossConfigs[currentBossName]
    if not config then return end
    
    if isBossAlive(config.InternalName) then return end
    
    summonBoss(currentBossName, config)
end

local function stopAutoSummon()
    isSummoning = false
    if summonConnection then
        summonConnection:Disconnect()
        summonConnection = nil
    end
    _G.SlowHub.AutoSummonBoss = false
    lastSummonTime = {}
end

local function startAutoSummon()
    if isSummoning then stopAutoSummon(); task.wait(0.2) end
    isSummoning = true
    _G.SlowHub.AutoSummonBoss = true
    lastSummonTime = {}
    
    task.spawn(function()
        while isSummoning and _G.SlowHub.AutoSummonBoss do
            local bossesToSummon = getFilteredBossesToSummon()
            local currentTime = tick()
            
            if #bossesToSummon == 0 then
                task.wait(1)
                continue
            end
            
            for _, bossName in ipairs(bossesToSummon) do
                if not isSummoning then break end
                
                if not lastSummonTime[bossName] or (currentTime - lastSummonTime[bossName]) > 3 then
                    processBossSummon(bossName)
                    lastSummonTime[bossName] = currentTime
                    task.wait(0.5) 
                end
            end
            task.wait(0.5)
        end
    end)
end

Tab:Section({Title = "Summon Settings"})

Tab:Dropdown({
    Title = "Select Bosses to Summon",
    Flag = "SelectBossSummon",
    Values = bossList,
    Multi = true,
    Default = _G.SlowHub.SelectBossSummon or {},
    Callback = function(value)
        selectedBosses = {}
        if type(value) == "table" then
            for _, boss in ipairs(value) do 
                table.insert(selectedBosses, boss) 
            end
        end
        _G.SlowHub.SelectBossSummon = selectedBosses
        if _G.SaveConfig then _G.SaveConfig() end
    end,
})

Tab:Dropdown({
    Title = "Select Difficulty",
    Flag = "SelectBossDifficulty",
    Values = difficultyList,
    Multi = false,
    Default = _G.SlowHub.SelectBossDifficulty or "Normal",
    Callback = function(value)
        selectedDifficulty = type(value) == "table" and value[1] or value
        _G.SlowHub.SelectBossDifficulty = selectedDifficulty
        if _G.SaveConfig then _G.SaveConfig() end
    end,
})

Tab:Toggle({
    Title = "Auto Summon Boss",
    Default = _G.SlowHub.AutoSummonBoss or false,
    Callback = function(Value)
        _G.SlowHub.AutoSummonBoss = Value
        if _G.SaveConfig then _G.SaveConfig() end
        if Value then
            startAutoSummon()
        else
            stopAutoSummon()
        end
    end,
})

if _G.SlowHub.AutoSummonBoss then
    task.wait(2)
    startAutoSummon()
end
