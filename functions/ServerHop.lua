local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local Tab = _G.MiscTab

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.ServerHopMaxPing = _G.SlowHub.ServerHopMaxPing or 300
_G.SlowHub.ServerHopMinPlayers = _G.SlowHub.ServerHopMinPlayers or 1

local ServerHopState = {
    IsHopping = false,
    LastHopTime = 0
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

local function GetServers()
    local placeId = game.PlaceId
    local cursor = ""
    local servers = {}
    local maxAttempts = 5
    local attempts = 0
    
    while cursor and attempts < maxAttempts do
        attempts = attempts + 1
        
        local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Desc&limit=100"
        if cursor ~= "" then
            url = url .. "&cursor=" .. HttpService:UrlEncode(cursor)
        end
        
        local success, result = pcall(function()
            return game:HttpGet(url)
        end)
        
        if not success then
            break
        end
        
        local successDecode, body = pcall(function()
            return HttpService:JSONDecode(result)
        end)
        
        if not successDecode or not body then
            break
        end
        
        if body.data then
            for _, server in ipairs(body.data) do
                local validServer = server.playing < server.maxPlayers 
                    and server.id ~= game.JobId
                    and server.playing >= _G.SlowHub.ServerHopMinPlayers
                    and (server.ping and server.ping <= _G.SlowHub.ServerHopMaxPing)
                
                if validServer then
                    table.insert(servers, server.id)
                end
            end
        end
        
        if #servers > 0 then
            return servers
        end
        
        cursor = body.nextPageCursor
        if not cursor then
            break
        end
    end
    
    return servers
end

local function ServerHop()
    if ServerHopState.IsHopping then
        Notify("Server Hop", "Already hopping!", 3)
        return
    end
    
    local currentTime = tick()
    if currentTime - ServerHopState.LastHopTime < 5 then
        Notify("Server Hop", "Please wait before hopping again!", 3)
        return
    end
    
    ServerHopState.IsHopping = true
    
    task.spawn(function()
        local servers = GetServers()
        
        if #servers == 0 then
            Notify("Server Hop", "No suitable servers found!", 3)
            ServerHopState.IsHopping = false
            return
        end
        
        local randomServer = servers[math.random(1, #servers)]
        local placeId = game.PlaceId
        
        ServerHopState.LastHopTime = tick()
        
        local success = pcall(function()
            TeleportService:TeleportToPlaceInstance(placeId, randomServer, Player)
        end)
        
        if not success then
            Notify("Server Hop", "Teleport failed!", 3)
            ServerHopState.IsHopping = false
        end
    end)
end

Tab:CreateSection("Server")

Tab:CreateSlider({
    Name = "Max Ping",
    Range = {100, 500},
    Increment = 50,
    Suffix = "ms",
    CurrentValue = _G.SlowHub.ServerHopMaxPing,
    Flag = "ServerHopMaxPing",
    Callback = function(Value)
        _G.SlowHub.ServerHopMaxPing = Value
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

Tab:CreateSlider({
    Name = "Min Players",
    Range = {1, 10},
    Increment = 1,
    Suffix = "Players",
    CurrentValue = _G.SlowHub.ServerHopMinPlayers,
    Flag = "ServerHopMinPlayers",
    Callback = function(Value)
        _G.SlowHub.ServerHopMinPlayers = Value
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

Tab:CreateButton({
    Name = "Server Hop",
    Callback = function()
        ServerHop()
    end
})
