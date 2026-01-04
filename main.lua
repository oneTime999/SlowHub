local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

_G.SlowHub = {
    AutoFarmLevel = false,
    AutoFarmBosses = false,
    AutoFarmMiniBosses = false,
    AutoSkill = false,
    AutoChest = false,
    AutoHaki = false,
    Codes = false,
    Shop = false,
    Stats = false,
    AntiAFK = false,
    SelectedWeapon = nil
}

local HttpService = game:GetService("HttpService")
local configFolder = "SlowHub"
local configFile = configFolder .. "/config.json"

if not isfolder(configFolder) then
    makefolder(configFolder)
end

local function SaveConfig()
    pcall(function()
        local data = {
            AutoFarmLevel = _G.SlowHub.AutoFarmLevel,
            AutoFarmBosses = _G.SlowHub.AutoFarmBosses,
            AutoHaki = _G.SlowHub.AutoHaki,
            AntiAFK = _G.SlowHub.AntiAFK,
            AutoSkill = _G.SlowHub.AutoSkill
        }
        
        local json = HttpService:JSONEncode(data)
        writefile(configFile, json)
    end)
end

local function LoadConfig()
    if not isfile(configFile) then
        return
    end
    
    pcall(function()
        local json = readfile(configFile)
        local data = HttpService:JSONDecode(json)
        
        _G.SlowHub.AutoFarmLevel = data.AutoFarmLevel or false
        _G.SlowHub.AutoFarmBosses = data.AutoFarmBosses or false
        _G.SlowHub.AutoHaki = data.AutoHaki or false
        _G.SlowHub.AntiAFK = data.AntiAFK or false
        _G.SlowHub.AutoSkill = data.AutoSkill or false
    end)
end

_G.SaveConfig = SaveConfig

LoadConfig()

local Window = Rayfield:CreateWindow({
    Name = "Slow Hub",
    LoadingTitle = "Slow Hub",
    LoadingSubtitle = "by oneTime999",
    ConfigurationSaving = {
        Enabled = false
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = false
})

_G.MainTab = Window:CreateTab("Main", 125686055318100)
_G.BossesTab = Window:CreateTab("Bosses", 105026320884681)
_G.ShopTab = Window:CreateTab("Shop", 102424048012641)
_G.StatsTab = Window:CreateTab("Stats", 109860946741884)
_G.MiscTab = Window:CreateTab("Misc", 140369423520801)

_G.Rayfield = Rayfield

loadstring(game:HttpGet("https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/main.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/bosses.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/shop.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/stats.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/misc.lua"))()

game:GetService("Players").LocalPlayer.PlayerGui:WaitForChild("RayfieldLibrary", 10)
local RayfieldUI = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("RayfieldLibrary")

if RayfieldUI then
    game:GetService("RunService").Heartbeat:Connect(function()
        if not RayfieldUI.Parent then
            SaveConfig()
        end
    end)
end

task.spawn(function()
    while task.wait(30) do
        SaveConfig()
    end
end)

Rayfield:Notify({
    Title = "Slow Hub",
    Content = "Successfully loaded!",
    Duration = 5,
    Image = 125686055318100
})
