local Tab = _G.BossesTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local BossList = {
    "QinShiBoss",
    "SaberBoss"
}

local autoSummonBossConnection = nil
local isSummoningBoss = false
local selectedBoss = nil

local function isBossAlive(bossName)
    pcall(function()
        for _, obj in pairs(workspace:GetChildren()) do
            if obj.Name:find(bossName) or obj.Name == bossName then
                local humanoid = obj:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    return true
                end
            end
        end
    end)
    return false
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
    if autoSummonBossConnection then
        stopAutoSummonBoss()
    end
    
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

local Dropdown = Tab:AddDropdown("SelectBossSummon", {
    Title = "Select Boss",
    Values = BossList,
    Default = nil,
    Callback = function(Value)
        selectedBoss = tostring(Value)
    end
})

local Toggle = Tab:AddToggle("AutoSummonBoss", {
    Title = "Auto Summon Boss",
    Default = false,
    Callback = function(Value)
        if Value then
            if not selectedBoss then
                _G.Fluent:Notify({Title = "Error", Content = "Select a Boss to summon first!", Duration = 3})
                if Toggle then Toggle:SetValue(false) end
                return
            end
            startAutoSummonBoss()
        else
            stopAutoSummonBoss()
        end
        
        _G.SlowHub.AutoSummonBoss = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

if _G.SlowHub.AutoSummonBoss and selectedBoss then
    task.wait(2)
    startAutoSummonBoss()
end
