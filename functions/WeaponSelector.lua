local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- Certifique-se de que _G.MainTab está definido antes deste script rodar!
local Tab = _G.MainTab 

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.SelectedWeapon = nil
_G.SlowHub.EquipLoop = false

-- Função para obter armas (Backpack + Character)
local function GetWeapons()
    local weapons = {}
    local seen = {} -- Evita duplicatas na lista

    local function scan(container)
        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") and not seen[item.Name] then
                seen[item.Name] = true
                table.insert(weapons, item.Name)
            end
        end
    end

    pcall(function()
        if Player.Backpack then scan(Player.Backpack) end
        if Player.Character then scan(Player.Character) end
    end)

    -- Rayfield precisa de pelo menos uma opção para não bugar visualmente
    return #weapons > 0 and weapons or {"Nenhuma arma encontrada"}
end

-- Função para equipar a arma selecionada
local function EquipSelectedTool()
    local weaponName = _G.SlowHub.SelectedWeapon
    
    -- Verificações de segurança
    if not weaponName or weaponName == "" or weaponName == "Nenhuma arma encontrada" then return end
    if not Player.Character or not Player.Character:FindFirstChild("Humanoid") then return end

    local Humanoid = Player.Character:FindFirstChild("Humanoid")
    if Humanoid.Health <= 0 then return end -- Não tenta equipar se estiver morto

    -- Verifica se já está equipada
    local currentTool = Player.Character:FindFirstChild(weaponName)
    if currentTool then return end -- Já está na mão

    -- Procura na Backpack e equipa
    local backpack = Player:FindFirstChild("Backpack")
    if backpack then
        local tool = backpack:FindFirstChild(weaponName)
        if tool then
            Humanoid:EquipTool(tool)
        end
    end
end

-- Criação do Dropdown
local WeaponDropdown = Tab:CreateDropdown({
    Name = "Selecionar Arma",
    Options = GetWeapons(),
    CurrentOption = {"Nenhuma arma encontrada"}, -- Rayfield V2 geralmente espera uma tabela aqui
    MultipleOptions = false,
    Flag = "SelectWeapon",
    Callback = function(Option)
        -- CORREÇÃO CRÍTICA: Rayfield retorna uma tabela { "NomeDaArma" }
        local weaponName = (type(Option) == "table" and Option[1]) or Option
        
        print("Arma Selecionada:", weaponName) -- Debug para ver se está funcionando

        if weaponName and weaponName ~= "Nenhuma arma encontrada" then
            _G.SlowHub.SelectedWeapon = weaponName
            EquipSelectedTool()
        else
            _G.SlowHub.SelectedWeapon = nil
        end
    end
})

-- Botão de Refresh
Tab:CreateButton({
    Name = "Atualizar Lista de Armas",
    Callback = function()
        -- Atualiza as opções do dropdown existente
        WeaponDropdown:Refresh(GetWeapons())
    end
})

-- Toggle do Loop Equip
Tab:CreateToggle({
    Name = "Loop Equip (Equipar Automaticamente)",
    CurrentValue = false,
    Flag = "LoopEquipTool",
    Callback = function(Value)
        _G.SlowHub.EquipLoop = Value
        
        if Value then
            task.spawn(function()
                while _G.SlowHub.EquipLoop do
                    EquipSelectedTool()
                    task.wait(0.5) -- Um delay pequeno evita lag
                end
            end)
        end
    end
})

-- Reconectar ao morrer/renascer
Player.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    char:WaitForChild("Backpack") -- Espera carregar o inventário
    task.wait(1)
    
    if _G.SlowHub.EquipLoop then
        EquipSelectedTool()
    end
end)
