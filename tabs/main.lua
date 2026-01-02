local Tab = _G.MainTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

-- Seção: Auto Farm
Tab:AddSection({
    Name = "Auto Farm"
})

-- Carregar Auto Level
loadstring(game:HttpGet(githubBase .. "AutoLevel.lua"))()

-- Carregar Auto Boss
loadstring(game:HttpGet(githubBase .. "AutoBoss.lua"))()

-- Seção: Haki
Tab:AddSection({
    Name = "Haki"
})

-- Carregar Auto Haki
loadstring(game:HttpGet(githubBase .. "AutoHaki.lua"))()

-- Seção: Controles
Tab:AddSection({
    Name = "Controles"
})

Tab:AddButton({
    Name = "Desativar Tudo",
    Callback = function()
        _G.SlowHub.AutoFarmLevel = false
        _G.SlowHub.AutoFarmBoss = false
        _G.SlowHub.AutoHaki = false
        
        _G.OrionLib:MakeNotification({
            Name = "Slow Hub",
            Content = "Todos os farms desativados!",
            Image = "rbxassetid://4483345998",
            Time = 3
        })
    end    
})
