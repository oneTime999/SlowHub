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

_G.SlowHub.SelectedStat = nil
_G.SlowHub.StatLoopEnabled = false

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

local Dropdown = Tab:CreateDropdown({
    Name = "Select Stat",
    Options = {"Melee", "Defense", "Sword", "Power"},
    CurrentOption = "Select a Stat",
    Flag = "SelectStat",
    Callback = function(Value)
        _G.SlowHub.SelectedStat = Value
    end
})

local Toggle = Tab:CreateToggle({
    Name = "Enable Stat Loop",
    CurrentValue = false,
    Flag = "StatLoop",
    Callback = function(Value)
        if Value then
            if not _G.SlowHub.SelectedStat or _G.SlowHub.SelectedStat == "Select a Stat" then
                _G.Rayfield:Notify({
                    Title = "Error",
                    Content = "Select a Stat first!",
                    Duration = 3,
                    Image = 4483362458
                })
                Toggle:Set(false)
                return
            end
            startStatLoop()
        else
            stopStatLoop()
        end
    end
})
