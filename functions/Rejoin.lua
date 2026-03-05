local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.RejoinDelay = _G.SlowHub.RejoinDelay or 0.5

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
if saved["RejoinDelay"] ~= nil then _G.SlowHub.RejoinDelay = saved["RejoinDelay"] end

local RejoinState = {IsRejoining = false}

local function RejoinServer()
    if RejoinState.IsRejoining then return end
    RejoinState.IsRejoining = true
    task.spawn(function()
        task.wait(_G.SlowHub.RejoinDelay)
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

local MiscTab = _G.MiscTab

MiscTab:CreateSection({ Title = "Server" })

MiscTab:CreateSlider({
    Name = "Rejoin Delay", Flag = "RejoinDelay",
    Range = { 0, 3 }, Increment = 0.5,
    CurrentValue = _G.SlowHub.RejoinDelay,
    Callback = function(value)
        _G.SlowHub.RejoinDelay = value
        saveConfig("RejoinDelay", value)
    end,
})

MiscTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        RejoinServer()
    end,
})
