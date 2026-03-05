local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local Player = Players.LocalPlayer

local Tab = _G.MiscTab

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.RejoinDelay = _G.SlowHub.RejoinDelay or 0.5

local RejoinState = {
    IsRejoining = false
}

local function Notify(title, content, duration)
    duration = duration or 3
    
    pcall(function()
        if _G.Rayfield and _G.Rayfield.Notify then
            _G.Rayfield:Notify({
                Title = title,
                Content = content,
                Duration = duration,
                Image = 4483362458
            })
        end
    end)
end

local function RejoinServer()
    if RejoinState.IsRejoining then
        Notify("Rejoin", "Already rejoining!", 3)
        return
    end
    
    RejoinState.IsRejoining = true
    
    Notify("Rejoin", "Rejoining server...", 3)
    
    task.spawn(function()
        task.wait(_G.SlowHub.RejoinDelay)
        
        local playerCount = #Players:GetPlayers()
        local placeId = game.PlaceId
        local jobId = game.JobId
        
        if playerCount <= 1 then
            local success = pcall(function()
                Player:Kick("\nRejoining...")
            end)
            
            task.wait(0.5)
            
            pcall(function()
                TeleportService:Teleport(placeId, Player)
            end)
        else
            local success = pcall(function()
                TeleportService:TeleportToPlaceInstance(placeId, jobId, Player)
            end)
            
            if not success then
                Notify("Rejoin", "Rejoin failed! Trying normal teleport...", 3)
                task.wait(0.5)
                
                pcall(function()
                    TeleportService:Teleport(placeId, Player)
                end)
            end
        end
    end)
end

Tab:CreateSection("Server")

Tab:CreateSlider({
    Name = "Rejoin Delay",
    Range = {0, 3},
    Increment = 0.5,
    Suffix = "Seconds",
    CurrentValue = _G.SlowHub.RejoinDelay,
    Flag = "RejoinDelay",
    Callback = function(Value)
        _G.SlowHub.RejoinDelay = Value
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

Tab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        RejoinServer()
    end
})
