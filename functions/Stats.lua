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

local Dropdown = Tab:AddDropdown("SelectStat", {
    Title = "Select Stat",
    Values = {"Melee", "Defense", "Sword", "Power"},
    Default = nil,
    Callback = function(Value)
        pcall(function()
            _G.SlowHub.SelectedStat = tostring(Value)
        end)
    end
})

local Toggle = Tab:AddToggle("StatLoop", {
    Title = "Enable Stat Loop",
    Default = false,
    Callback = function(Value)
        pcall(function()
            if Value then
                if not _G.SlowHub.SelectedStat then
                    _G.Fluent:Notify({Title = "Error", Content = "Select a Stat first!", Duration = 3})
                    if Toggle then Toggle:SetValue(false) end
                    return
                end
                startStatLoop()
            else
                stopStatLoop()
            end
        end)
    end
})
