local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local Tab = _G.MainTab

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.SelectedWeapon = nil
_G.SlowHub.SelectedWeapons = {} -- Para multi seleção
_G.SlowHub.EquipLoop = false
_G.SlowHub.MultiLoop = false

-- Função de pegar armas
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

-- Equipar arma única
local function EquipSelectedTool()
    local weaponName = _G.SlowHub.SelectedWeapon
    if not weaponName or weaponName == "" or weaponName == "No weapons found" then return end
    
    pcall(function()
        local char = Player.Character
        if not char then return end
        local humanoid = char:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return end
        if char:FindFirstChild(weaponName) then return end
        
        local backpack = Player:FindFirstChild("Backpack")
        if backpack then
            local tool = backpack:FindFirstChild(weaponName)
            if tool and tool:IsA("Tool") then
                humanoid:EquipTool(tool)
            end
        end
    end)
end

-- Loop de troca rápida (Multi)
local function StartMultiLoop()
    task.spawn(function()
        while _G.SlowHub.MultiLoop and #_G.SlowHub.SelectedWeapons > 0 do
            for _, weaponName in ipairs(_G.SlowHub.SelectedWeapons) do
                if not _G.SlowHub.MultiLoop then break end
                
                pcall(function()
                    local char = Player.Character
                    if not char then return end
                    local humanoid = char:FindFirstChild("Humanoid")
                    if not humanoid or humanoid.Health <= 0 then return end
                    
                    -- Desequipar atual
                    if humanoid then
                        humanoid:UnequipTools()
                    end
                    
                    task.wait(0.05) -- Pequena pausa entre trocas
                    
                    -- Equipar próxima
                    local backpack = Player:FindFirstChild("Backpack")
                    if backpack then
                        local tool = backpack:FindFirstChild(weaponName)
                        if tool and tool:IsA("Tool") then
                            humanoid:EquipTool(tool)
                        end
                    end
                end)
                
                task.wait(0.15) -- Velocidade da troca (ajuste conforme necessário)
            end
        end
    end)
end

-- DROPDOWN NORMAL (Seleção Única)
local NormalDropdown = Tab:CreateDropdown({
    Name = "Normal",
    Options = GetWeapons(),
    CurrentOption = {""},
    MultipleOptions = false,
    Flag = "NormalWeapon",
    Callback = function(Value)
        local weapon = (type(Value) == "table" and Value[1]) or Value
        print("Normal Selecionado:", weapon)
        
        -- Desativa o multi se estiver ativo
        _G.SlowHub.MultiLoop = false
        
        if weapon and weapon ~= "" and weapon ~= "No weapons found" then
            _G.SlowHub.SelectedWeapon = weapon
            EquipSelectedTool()
        else
            _G.SlowHub.SelectedWeapon = nil
        end
    end
})

-- DROPDOWN MULTI (Seleção Múltipla)
local MultiDropdown = Tab:CreateDropdown({
    Name = "Multi",
    Options = GetWeapons(),
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "MultiWeapon",
    Callback = function(Value)
        -- Value já é uma tabela quando MultipleOptions = true
        _G.SlowHub.SelectedWeapons = {}
        
        print("Multi Selecionados:")
        for _, weapon in ipairs(Value) do
            if weapon ~= "" and weapon ~= "No weapons found" then
                table.insert(_G.SlowHub.SelectedWeapons, weapon)
                print("- " .. weapon)
            end
        end
        
        -- Se o loop multi estiver ativo, reinicia com novas armas
        if _G.SlowHub.MultiLoop and #_G.SlowHub.SelectedWeapons > 0 then
            _G.SlowHub.MultiLoop = false
            task.wait(0.1)
            _G.SlowHub.MultiLoop = true
            StartMultiLoop()
        end
    end
})

-- Botão Refresh (atualiza ambos)
local RefreshButton = Tab:CreateButton({
    Name = "Refresh Weapons",
    Callback = function()
        local newWeapons = GetWeapons()
        NormalDropdown:Refresh(newWeapons)
        MultiDropdown:Refresh(newWeapons)
    end
})

-- Toggle Loop Normal
local EquipLoopToggle = Tab:CreateToggle({
    Name = "Loop Equip (Normal)",
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

-- Toggle Loop Multi (Troca Rápida)
local MultiLoopToggle = Tab:CreateToggle({
    Name = "Loop Multi (Troca Rápida)",
    CurrentValue = false,
    Flag = "LoopMultiTool",
    Callback = function(state)
        _G.SlowHub.MultiLoop = state
        
        if state and #_G.SlowHub.SelectedWeapons > 0 then
            -- Desativa o normal
            _G.SlowHub.EquipLoop = false
            StartMultiLoop()
        else
            _G.SlowHub.MultiLoop = false
        end
    end
})

-- Conexão ao renascer
Player.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    task.wait(1)
    if _G.SlowHub.EquipLoop then
        EquipSelectedTool()
    elseif _G.SlowHub.MultiLoop and #_G.SlowHub.SelectedWeapons > 0 then
        StartMultiLoop()
    end
end)
