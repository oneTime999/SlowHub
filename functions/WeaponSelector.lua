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
        table.insert(weapons, "Nenhuma arma encontrada")
    end
    
    return weapons
end

-- Função para equipar a arma
local function EquipWeapon(weaponName)
    pcall(function()
        local backpack = Player:FindFirstChild("Backpack")
        local character = Player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        
        if not character or not humanoid then return end
        
        -- Procurar a arma na mochila
        if backpack then
            local weapon = backpack:FindFirstChild(weaponName)
            if weapon and weapon:IsA("Tool") then
                -- Método 1: Mover para o personagem
                weapon.Parent = character
                return
            end
        end
    end)
end

-- Dropdown para selecionar arma
local weaponDropdown = Tab:CreateDropdown({
    Name = "Selecionar Arma",
    Options = GetWeapons(),
    CurrentOption = "",
    Flag = "WeaponDropdown",
    Callback = function(Value)
        if Value and Value ~= "Nenhuma arma encontrada" then
            _G.SlowHub.SelectedWeapon = Value
            EquipWeapon(Value)
        end
    end
})

-- Botão para atualizar lista de armas
Tab:CreateButton({
    Name = "Atualizar Lista de Armas",
    Callback = function()
        pcall(function()
            local weapons = GetWeapons()
            weaponDropdown:Refresh(weapons)
        end)
    end
})
