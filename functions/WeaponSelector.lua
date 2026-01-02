local Tab = _G.MainTab
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

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
