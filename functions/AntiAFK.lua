local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.AntiAFK = _G.SlowHub.AntiAFK or false

local CONFIG_FOLDER = "SlowHub"
local CONFIG_FILE = CONFIG_FOLDER .. "/config.json"

local function ensureFolder()
    if not isfolder(CONFIG_FOLDER) then
        makefolder(CONFIG_FOLDER)
    end
end

local function loadConfig()
    ensureFolder()
    if isfile(CONFIG_FILE) then
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(CONFIG_FILE))
        end)
        if ok and type(data) == "table" then
            return data
        end
    end
    return {}
end

local function saveConfig(key, value)
    ensureFolder()
    local current = loadConfig()
    current[key] = value
    pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(current))
    end)
end

local saved = loadConfig()
if saved["AntiAFK"] ~= nil then
    _G.SlowHub.AntiAFK = saved["AntiAFK"]
end

local antiAfkConnection = nil
local idledConnection = nil

local function stopAntiAfk()
    if antiAfkConnection then
        antiAfkConnection:Disconnect()
        antiAfkConnection = nil
    end
    if idledConnection then
        idledConnection:Disconnect()
        idledConnection = nil
    end
    _G.SlowHub.AntiAFK = false
end

local function startAntiAfk()
    if antiAfkConnection or idledConnection then
        stopAntiAfk()
    end

    _G.SlowHub.AntiAFK = true

    idledConnection = Player.Idled:Connect(function()
        if not _G.SlowHub.AntiAFK then
            stopAntiAfk()
            return
        end
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)

    antiAfkConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AntiAFK then
            stopAntiAfk()
        end
    end)
end

local Window = WindUI:CreateWindow({
    Title = "SlowHub",
    Icon = "geist:shield",
    Author = "Misc Utilities",
    Folder = "SlowHub",
    Size = UDim2.fromOffset(520, 380),
    Theme = "Dark",
    HidePanelBackground = false,
    NewElements = false,
})

local MiscTab = Window:CreateTab({
    Title = "Misc",
    Icon = "geist:settings",
})

_G.MiscTab = MiscTab

MiscTab:CreateSection({ Title = "Player" })

MiscTab:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = _G.SlowHub.AntiAFK,
    Flag = "AntiAFK",
    Callback = function(value)
        _G.SlowHub.AntiAFK = value
        if value then
            startAntiAfk()
        else
            stopAntiAfk()
        end
        saveConfig("AntiAFK", value)
    end,
})

if _G.SlowHub.AntiAFK then
    task.wait(2)
    startAntiAfk()
end
