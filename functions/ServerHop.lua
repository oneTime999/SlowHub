local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.ServerHopMaxPing = _G.SlowHub.ServerHopMaxPing or 300
_G.SlowHub.ServerHopMinPlayers = _G.SlowHub.ServerHopMinPlayers or 1

local CONFIG_FOLDER = "SlowHub"
local CONFIG_FILE = CONFIG_FOLDER .. "/config.json"

local function ensureFolder()
    if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
end

local function loadConfig()
    ensureFolder()
    if isfile(CONFIG_FILE) then
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_FILE)) end)
        if ok and type(data) == "table" then return data end
    end
    return {}
end

local function saveConfig(key, value)
    ensureFolder()
    local current = loadConfig()
    current[key] = value
    pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(current)) end)
end

local saved = loadConfig()
if saved["ServerHopMaxPing"] ~= nil then _G.SlowHub.ServerHopMaxPing = saved["ServerHopMaxPing"] end
if saved["ServerHopMinPlayers"] ~= nil then _G.SlowHub.ServerHopMinPlayers = saved["ServerHopMinPlayers"] end

local ServerHopState = {IsHopping=false, LastHopTime=0}

local function GetServers()
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
                    and server.playing >= _G.SlowHub.ServerHopMinPlayers
                    and server.ping and server.ping <= _G.SlowHub.ServerHopMaxPing then
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

local function ServerHop()
    if ServerHopState.IsHopping then return end
    local currentTime = tick()
    if currentTime - ServerHopState.LastHopTime < 5 then return end
    ServerHopState.IsHopping = true
    task.spawn(function()
        local servers = GetServers()
        if #servers == 0 then ServerHopState.IsHopping = false; return end
        local randomServer = servers[math.random(1, #servers)]
        local placeId = game.PlaceId
        ServerHopState.LastHopTime = tick()
        local success = pcall(function()
            TeleportService:TeleportToPlaceInstance(placeId, randomServer, Player)
        end)
        if not success then ServerHopState.IsHopping = false end
    end)
end

local MiscTab = _G.MiscTab

MiscTab:CreateSection({ Title = "Server" })

MiscTab:CreateSlider({
    Name = "Max Ping", Flag = "ServerHopMaxPing",
    Range = { 100, 500 }, Increment = 50,
    CurrentValue = _G.SlowHub.ServerHopMaxPing,
    Callback = function(value)
        _G.SlowHub.ServerHopMaxPing = value
        saveConfig("ServerHopMaxPing", value)
    end,
})

MiscTab:CreateSlider({
    Name = "Min Players", Flag = "ServerHopMinPlayers",
    Range = { 1, 10 }, Increment = 1,
    CurrentValue = _G.SlowHub.ServerHopMinPlayers,
    Callback = function(value)
        _G.SlowHub.ServerHopMinPlayers = value
        saveConfig("ServerHopMinPlayers", value)
    end,
})

MiscTab:CreateButton({
    Name = "Server Hop",
    Callback = function()
        ServerHop()
    end,
})
