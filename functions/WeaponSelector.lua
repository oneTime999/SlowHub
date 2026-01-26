local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local Tab = _G.MainTab -- Certifique-se que sua Tab do Rayfield está criada

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.SelectedWeapon = nil
_G.SlowHub.EquipLoop = false

-- Função para pegar nomes das armas (Inventário + Mão)
local function GetWeaponNames()
    local weaponNames = {}
    local seen = {}

    local function addTools(container)
        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") and not seen[item.Name] then
                seen[item.Name] = true
                table.insert(weaponNames, item.Name)
            end
        end
    end

    if Player.Backpack then addTools(Player.Backpack) end
    if Player.Character then addTools(Player.Character) end

    if #weaponNames == 0 then
        return {"Nenhuma arma encontrada (Clique Refresh)"}
    end
    
    return weaponNames
end

-- Função principal de equipar
local function EquipWeapon(weaponName)
    if not weaponName or weaponName == "" or string.find(weaponName, "Nenhuma arma") then return end
    
    local Character = Player.Character
    if not Character then return end
    
    local Humanoid = Character:FindFirstChild("Humanoid")
    if not Humanoid or Humanoid.Health <= 0 then return end

    -- 1. Verifica se JÁ ESTÁ equipada na mão (Character)
    local equippedTool = Character:FindFirstChild(weaponName)
    if equippedTool then
        -- Se já está na mão, não faz nada (evita spam de animação)
        return 
    end

    -- 2. Procura na Backpack para equipar
    local Backpack = Player:FindFirstChild("Backpack")
    if Backpack then
        local ToolToEquip = Backpack:FindFirstChild(weaponName)
        
        if ToolToEquip then
            Humanoid:EquipTool(ToolToEquip)
            print("Equipando: " .. weaponName) -- Debug no F9
        else
            -- Se não achou na backpack nem na mão, a arma sumiu ou mudou de nome
            -- print("Arma não encontrada no inventário: " .. weaponName)
        end
    end
end

-- Dropdown
local WeaponDropdown = Tab:CreateDropdown({
    Name = "Selecionar Arma",
    Options = GetWeaponNames(),
    CurrentOption = {""},
    MultipleOptions = false,
    Flag = "WeaponSelectFlag",
    Callback = function(Option)
        -- Rayfield retorna tabela { "Nome" }, tratamos isso aqui:
        local selected = (type(Option) == "table" and Option[1]) or Option
        
        print("Opção selecionada: ", selected) -- Debug
        _G.SlowHub.SelectedWeapon = selected
        
        -- Tenta equipar imediatamente ao selecionar
        EquipWeapon(selected)
    end
})

-- Botão Refresh (Caso você ganhe itens novos)
Tab:CreateButton({
    Name = "Atualizar Lista (Refresh)",
    Callback = function()
        WeaponDropdown:Refresh(GetWeaponNames())
    end
})

-- Toggle do Loop
Tab:CreateToggle({
    Name = "Equipar Automaticamente (Loop)",
    CurrentValue = false,
    Flag = "AutoEquipFlag",
    Callback = function(Value)
        _G.SlowHub.EquipLoop = Value
        
        if Value then
            task.spawn(function()
                while _G.SlowHub.EquipLoop do
                    if _G.SlowHub.SelectedWeapon then
                        EquipWeapon(_G.SlowHub.SelectedWeapon)
                    end
                    task.wait(0.5) -- Verifica a cada 0.5s
                end
            end)
        end
    end
})

-- Reconexão ao morrer (Garante que o loop continue funcionando após resetar)
Player.CharacterAdded:Connect(function(newChar)
    task.wait(1.5) -- Espera o jogo carregar o inventário
    if _G.SlowHub.EquipLoop and _G.SlowHub.SelectedWeapon then
        EquipWeapon(_G.SlowHub.SelectedWeapon)
    end
end)
