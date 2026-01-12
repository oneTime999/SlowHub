local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Window = Fluent:CreateWindow({
    Title = "Slow Hub", SubTitle = "v1.0", TabWidth = 160, Size = UDim2.fromOffset(580, 460),
    Acrylic = false, Theme = "Darker", MinimizeKey = Enum.KeyCode.LeftControl
})

_G.SlowHub.Window = Window

local function LoadTab(url, name)
    local success, tab = pcall(function()
        return loadstring(game:HttpGet(url))(_G.SlowHub)
    end)
    if success and tab then
        Window:AddTab(tab)
    end
end

LoadTab("https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/main.lua", "Main")
LoadTab("https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/bosses.lua", "Bosses")
LoadTab("https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/shop.lua", "Shop")
LoadTab("https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/stats.lua", "Stats")
LoadTab("https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/misc.lua", "Misc")

Fluent:Notify({Title = "Slow Hub", Content = "Carregado com sucesso!", Duration = 4})
