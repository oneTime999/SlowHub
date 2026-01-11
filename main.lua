local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

_G.SlowHub = {
    AutoFarmLevel = false,
    AutoFarmBosses = false,
    AutoSummon = false,
    AutoFarmMiniBosses = false,
    AutoFarmSelectedMob = false,
    AutoSkill = false,
    AutoChest = false,
    AutoHaki = false,
    AutoObservation = false,
    Codes = false,
    Shop = false,
    NPC = false,
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
            AutoSkill = _G.SlowHub.AutoSkill,
            AutoObservation = _G.SlowHub.AutoObservation
        }
        writefile(configFile, HttpService:JSONEncode(data))
    end)
end

local function LoadConfig()
    if not isfile(configFile) then return end
    pcall(function()
        local data = HttpService:JSONDecode(readfile(configFile))
        _G.SlowHub.AutoFarmLevel = data.AutoFarmLevel or false
        _G.SlowHub.AutoFarmBosses = data.AutoFarmBosses or false
        _G.SlowHub.AutoHaki = data.AutoHaki or false
        _G.SlowHub.AntiAFK = data.AntiAFK or false
        _G.SlowHub.AutoSkill = data.AutoSkill or false
        _G.SlowHub.AutoObservation = data.AutoObservation or false
    end)
end

_G.SaveConfig = SaveConfig
LoadConfig()

local Window = Fluent:CreateWindow({
    Title = "Slow Hub",
    SubTitle = "by oneTime and Vagner",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Bosses = Window:AddTab({ Title = "Bosses", Icon = "skull" }),
    Shop = Window:AddTab({ Title = "Shop", Icon = "shopping-cart" }),
    Stats = Window:AddTab({ Title = "Stats", Icon = "bar-chart" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "settings" })
}

_G.MainTab = Tabs.Main
_G.BossesTab = Tabs.Bosses
_G.ShopTab = Tabs.Shop
_G.StatsTab = Tabs.Stats
_G.MiscTab = Tabs.Misc
_G.Fluent = Fluent

loadstring(game:HttpGet("https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/main.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/bosses.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/shop.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/stats.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/misc.lua"))()

Window:SelectTab(1)

task.spawn(function()
    while task.wait(30) do
        SaveConfig()
    end
end)

Fluent:Notify({
    Title = "Slow Hub",
    Content = "Script loaded successfully!",
    Duration = 5
})
