local Tab = _G.MiscTab
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local isHopping = false
local lastHopTime = 0

local function getServers()
    local placeId = game.PlaceId
    local cursor = ""
    local servers = {}
    local maxAttempts = 5
    local attempts = 0
    while cursor and attempts < maxAttempts do
        attempts = attempts + 1
        local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Desc&limit=100"
        if cursor ~= "" then url = url .. "&cursor=" .. HttpService:UrlEncode(cursor) end
        local ok, result = pcall(function() return game:HttpGet(url) end)
        if not ok then break end
        local okDecode, body = pcall(function() return HttpService:JSONDecode(result) end)
        if not okDecode or not body then break end
        if body.data then
            for _, server in ipairs(body.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId
                    and server.playing >= (_G.SlowHub.ServerHopMinPlayers or 1)
                    and server.ping and server.ping <= (_G.SlowHub.ServerHopMaxPing or 300) then
                    table.insert(servers, server.id)
                end
            end
        end
        if #servers > 0 then return servers end
        cursor = body.nextPageCursor
        if not cursor then break end
    end
    return servers
end

local function serverHop()
    if isHopping then return end
    local currentTime = tick()
    if currentTime - lastHopTime < 5 then return end
    isHopping = true
    task.spawn(function()
        local servers = getServers()
        if #servers == 0 then isHopping = false; return end
        local randomServer = servers[math.random(1, #servers)]
        local placeId = game.PlaceId
        lastHopTime = tick()
        local success = pcall(function()
            TeleportService:TeleportToPlaceInstance(placeId, randomServer, Player)
        end)
        if not success then isHopping = false end
    end)
end

Tab:Section({Title = "Server"})

Tab:Slider({
    Title = "Max Ping",
    Flag = "ServerHopMaxPing",
    Step = 50,
    Value = {
        Min = 100,
        Max = 500,
        Default = _G.SlowHub.ServerHopMaxPing or 300,
    },
    Callback = function(Value)
        _G.SlowHub.ServerHopMaxPing = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})

Tab:Slider({
    Title = "Min Players",
    Flag = "ServerHopMinPlayers",
    Step = 1,
    Value = {
        Min = 1,
        Max = 10,
        Default = _G.SlowHub.ServerHopMinPlayers or 1,
    },
    Callback = function(Value)
        _G.SlowHub.ServerHopMinPlayers = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})

Tab:Button({
    Title = "Server Hop",
    Callback = function()
        serverHop()
    end,
})
