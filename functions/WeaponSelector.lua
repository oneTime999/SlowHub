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
Tab:CreateDropdown({
    Name = "Select Weapon",
    Options = GetWeapons(),
    CurrentOption = "",
    Flag = "WeaponDropdown",
    Callback = function(Value)
        _G.SlowHub.SelectedWeapon = Value
        _G.Rayfield:Notify({
            Title = "Slow Hub",
            Content = "Weapon selected: " .. Value,
            Duration = 3,
            Image = 4483345998
        })
    end
})

-- Botão para atualizar lista de armas
Tab:CreateButton({
    Name = "Refresh Weapon List",
    Callback = function()
        local weapons = GetWeapons()
        _G.Rayfield:Notify({
            Title = "Slow Hub",
            Content = "Weapons found: " .. #weapons,
            Duration = 3,
            Image = 4483345998
        })
    end
})
