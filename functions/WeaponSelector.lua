local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local Tab = _G.MainTab -- Certifique-se que a Tab está definida

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.SelectedWeapon = nil
_G.SlowHub.EquipLoop = false

-- 1. Função de pegar armas (Mantida idêntica à lógica original)
local function GetWeapons()
    local weapons = {}
    local added = {}

    pcall(function()
        local backpack = Player:WaitForChild("Backpack")

        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") and not added[item.Name] then
                added[item.Name] = true
                table.insert(weapons, item.Name)
            end
        end

        if Player.Character then
            for _, item in ipairs(Player.Character:GetChildren()) do
                if item:IsA("Tool") and not added[item.Name] then
                    added[item.Name] = true
                    table.insert(weapons, item.Name)
                end
            end
        end
    end)

    return #weapons > 0 and weapons or {"No weapons found"}
end

-- 2. Função de encontrar e equipar (Otimizada para funcionar no Rayfield)
local function EquipSelectedTool()
    local weaponName = _G.SlowHub.SelectedWeapon
    
    if not weaponName or weaponName == "" or weaponName == "No weapons found" then 
        return 
    end

    pcall(function()
        local char = Player.Character
        if not char then return end

        local humanoid = char:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return end

        -- Se a arma JÁ estiver na mão, não fazemos nada (evita bugs)
        if char:FindFirstChild(weaponName) then
            return
        end

        -- Procura na Backpack para equipar
        local backpack = Player:FindFirstChild("Backpack")
        if backpack then
            local tool = backpack:FindFirstChild(weaponName)
            if tool and tool:IsA("Tool") then
                humanoid:EquipTool(tool)
            end
        end
    end)
end

-- 3. Criação do Dropdown (AQUI ESTAVA O ERRO)
local WeaponDropdown = Tab:CreateDropdown({
    Name = "Select Weapon",
    Options = GetWeapons(),
    CurrentOption = {""}, -- Rayfield pede uma tabela aqui
    MultipleOptions = false,
    Flag = "SelectWeapon",
    Callback = function(Value)
        -- CORREÇÃO: Rayfield retorna uma tabela { "Nome" }. Precisamos pegar o primeiro item.
        local weapon = (type(Value) == "table" and Value[1]) or Value
        
        -- Debug para garantir que está pegando o nome (pressione F9 para ver)
        print("Arma Selecionada:", weapon) 

        if weapon and weapon ~= "" and weapon ~= "No weapons found" then
            _G.SlowHub.SelectedWeapon = weapon
            EquipSelectedTool()
        else
            _G.SlowHub.SelectedWeapon = nil
        end
    end
})

-- 4. Botão de Refresh
local RefreshButton = Tab:CreateButton({
    Name = "Refresh Weapons",
    Callback = function()
        local newWeapons = GetWeapons()
        -- Atualiza a lista do dropdown no Rayfield
        WeaponDropdown:Refresh(newWeapons)
    end
})

-- 5. Toggle de Loop
local EquipLoopToggle = Tab:CreateToggle({
    Name = "Loop Equip Tool",
    CurrentValue = false,
    Flag = "LoopEquipTool",
    Callback = function(state)
        _G.SlowHub.EquipLoop = state

        if state then
            task.spawn(function()
                while _G.SlowHub.EquipLoop do
                    EquipSelectedTool()
                    task.wait(0.25)
                end
            end)
        end
    end
})

-- 6. Conexão ao renascer
Player.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    char:WaitForChild("Backpack")
    task.wait(1)
    if _G.SlowHub.EquipLoop then
        EquipSelectedTool()
    end
end)
