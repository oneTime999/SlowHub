local Tab = _G.StatsTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer

local StatsMap = {
    ["Melee"] = function() 
        return ReplicatedStorage.RemoteEvents.AllocateStat:FireServer("Melee", 1)
    end,
    ["Defense"] = function()
        return ReplicatedStorage.RemoteEvents.AllocateStat:FireServer("Defense", 1)
    end,
    ["Sword"] = function()
        return ReplicatedStorage.RemoteEvents.AllocateStat:FireServer("Sword", 1)
    end,
    ["Power"] = function()
        return ReplicatedStorage.RemoteEvents.AllocateStat:FireServer("Power", 1)
    end
}

_G.SlowHub.SelectedStat = _G.SlowHub.SelectedStat or ""

_G.SlowHub.StatLoopEnabled = _G.SlowHub.StatLoopEnabled or false

local function normalizeValue(Value)
    if type(Value) == "table" then
        return tostring(Value[1] or "")
    end
    return tostring(Value or "")
end

local function statLoopFunction()
    while _G.SlowHub.StatLoopEnabled do
        pcall(function()
            local selectedStat = _G.SlowHub.SelectedStat
            
            if not selectedStat or selectedStat == "" then
                return
            end
            
            local allocateFunction = StatsMap[selectedStat]
            if not allocateFunction then
                return
            end
            
            allocateFunction()
        end)
        task.wait(0.1)
    end
end

local function startStatLoop()
    pcall(function()
        local selectedStat = _G.SlowHub.SelectedStat
        
        if not selectedStat or selectedStat == "" then
            _G.SlowHub.StatLoopEnabled = false
            return
        end
        
        if not _G.SlowHub.StatLoopEnabled then
            _G.SlowHub.StatLoopEnabled = true
            task.spawn(statLoopFunction)
        end
    end)
end

local function stopStatLoop()
    pcall(function()
        _G.SlowHub.StatLoopEnabled = false
    end)
end

Tab:CreateDropdown({
    Name = "Select Stat",
    Options = {"Melee", "Defense", "Sword", "Power"},
    CurrentOption = {_G.SlowHub.SelectedStat},
    Flag = "StatDropdown",
    Callback = function(Option)
        pcall(function()
            _G.SlowHub.SelectedStat = normalizeValue(Option)
        end)
    end
})

Tab:CreateToggle({
    Name = "Enable Stat Loop",
    CurrentValue = _G.SlowHub.StatLoopEnabled,
    Flag = "StatLoopToggle",
    Callback = function(Value)
        pcall(function()
            if Value then
                startStatLoop()
            else
                stopStatLoop()
            end
        end)
    end
})
