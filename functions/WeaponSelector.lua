local Tab = _G.MainTab
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

-- Função para pegar armas da Backpack
local function GetWeapons()
    local weapons = {}
    
    pcall(function()
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
    end)
    
    -- Se não encontrou nenhuma arma, adicionar placeholder
    if #weapons == 0 then
        table.insert(weapons, "No weapons found")
    end
    
    return weapons
end

-- Dropdown para selecionar arma
local weaponDropdown = Tab:CreateDropdown({
    Name = "Select Weapon",
    Options = GetWeapons(),
    CurrentOption = "",
    Flag = "WeaponDropdown",
    Callback = function(Value)
        if Value and Value ~= "No weapons found" then
            _G.SlowHub.SelectedWeapon = Value
        end
    end
})

-- Botão para atualizar lista de armas
Tab:CreateButton({
    Name = "Refresh Weapon List",
    Callback = function()
        pcall(function()
            local weapons = GetWeapons()
            
            -- Atualizar dropdown
            weaponDropdown:Refresh(weapons)
        end)
    end
})
