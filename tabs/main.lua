local Tab = _G.MainTab
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

-- Seção: Configurações
Tab:AddSection({
    Name = "Configurações"
})

-- Função para pegar armas da Backpack
local function GetWeapons()
    local weapons = {}
    local backpack = Player:FindFirstChild("Backpack")
    local character = Player.Character
    
    if backpack then
        for _, item in pairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                table.insert(weapons, item.Name)
            end
        end
    end
    
    if character then
        for _, item in pairs(character:GetChildren()) do
            if item:IsA("Tool") then
                table.insert(weapons, item.Name)
            end
        end
    end
    
    return weapons
end

-- Dropdown para selecionar arma
Tab:AddDropdown({
    Name = "Selecionar Arma",
    Default = "",
    Options = GetWeapons(),
    Callback = function(Value)
        _G.SlowHub.SelectedWeapon = Value
        _G.OrionLib:MakeNotification({
            Name = "Slow Hub",
            Content = "Arma selecionada: " .. Value,
            Image = "rbxassetid://4483345998",
            Time = 3
        })
    end    
})

-- Botão para atualizar lista de armas
Tab:AddButton({
    Name = "Atualizar Lista de Armas",
    Callback = function()
        local weapons = GetWeapons()
        _G.OrionLib:MakeNotification({
            Name = "Slow Hub",
            Content = "Armas encontradas: " .. #weapons,
            Image = "rbxassetid://4483345998",
            Time = 3
        })
    end    
})

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
