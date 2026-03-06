local Tab = _G.MiscTab
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local Player = Players.LocalPlayer

local isRejoining = false

local function rejoinServer()
    if isRejoining then return end
    isRejoining = true
    task.spawn(function()
        task.wait(_G.SlowHub.RejoinDelay or 0.5)
        local playerCount = #Players:GetPlayers()
        local placeId = game.PlaceId
        local jobId = game.JobId
        if playerCount <= 1 then
            pcall(function() Player:Kick("\nRejoining...") end)
            task.wait(0.5)
            pcall(function() TeleportService:Teleport(placeId, Player) end)
        else
            local success = pcall(function()
                TeleportService:TeleportToPlaceInstance(placeId, jobId, Player)
            end)
            if not success then
                task.wait(0.5)
                pcall(function() TeleportService:Teleport(placeId, Player) end)
            end
        end
    end)
end

Tab:Section({Title = "Server"})

Tab:Slider({
    Title = "Rejoin Delay",
    Flag = "RejoinDelay",
    Step = 0.5,
    Value = {
        Min = 0,
        Max = 3,
        Default = _G.SlowHub.RejoinDelay or 0.5,
    },
    Callback = function(Value)
        _G.SlowHub.RejoinDelay = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})

Tab:Button({
    Title = "Rejoin Server",
    Callback = function()
        rejoinServer()
    end,
})
