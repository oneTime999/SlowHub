local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local Tab = _G.MainTab

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.SelectedWeapon = nil
_G.SlowHub.SelectedWeapons = {}
_G.SlowHub.AutoEquip = false
_G.SlowHub.AutoLoop = false

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

-- EQUIPAR TODOS (Método direto - Parent change)
local function EquipAllTools()
    pcall(function()
        local char = Player.Character
        local backpack = Player:WaitForChild("Backpack")
        if not char or not backpack then return end
        
        for _, tool in pairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                tool.Parent = char
            end
        end
    end)
end

-- EQUIPAR SELECIONADOS (Multi)
local function EquipSelectedTools()
    pcall(function()
        local char = Player.Character
        local backpack = Player:WaitForChild("Backpack")
        if not char or not backpack then return end
        
        for _, weaponName in ipairs(_G.SlowHub.SelectedWeapons) do
            local tool = backpack:FindFirstChild(weaponName)
            if tool and tool:IsA("Tool") then
                tool.Parent = char
            end
        end
    end)
end

-- EQUIPAR ÚNICO
local function EquipSingleTool(weaponName)
    pcall(function()
        local char = Player.Character
        local backpack = Player:WaitForChild("Backpack")
        if not char or not backpack then return end
        
        local tool = backpack:FindFirstChild(weaponName)
        if tool and tool:IsA("Tool") then
            tool.Parent = char
        end
    end)
end

-- DESEQUIPAR TODOS
local function UnequipAllTools()
    pcall(function()
        local char = Player.Character
        local backpack = Player:WaitForChild("Backpack")
        if not char or not backpack then return end
        
        for _, tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                tool.Parent = backpack
            end
        end
    end)
end

-- DROPDOWN NORMAL
local NormalDropdown = Tab:CreateDropdown({
    Name = "Normal",
    Options = GetWeapons(),
    CurrentOption = {""},
    MultipleOptions = false,
    Flag = "NormalWeapon",
    Callback = function(Value)
        local weapon = (type(Value) == "table" and Value[1]) or Value
        _G.SlowHub.AutoEquip = false
        
        if weapon and weapon ~= "" and weapon ~= "No weapons found" then
            _G.SlowHub.SelectedWeapon = weapon
            EquipSingleTool(weapon)
        end
    end
})

-- DROPDOWN MULTI
local MultiDropdown = Tab:CreateDropdown({
    Name = "Multi",
    Options = GetWeapons(),
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "MultiWeapon",
    Callback = function(Value)
        _G.SlowHub.SelectedWeapons = {}
        
        for _, weapon in ipairs(Value) do
            if weapon ~= "" and weapon ~= "No weapons found" then
                table.insert(_G.SlowHub.SelectedWeapons, weapon)
            end
        end
        
        -- Auto equipa se toggle estiver on
        if _G.SlowHub.AutoEquip then
            EquipSelectedTools()
        end
    end
})

-- Botão Refresh
local RefreshButton = Tab:CreateButton({
    Name = "Refresh Weapons",
    Callback = function()
        local newWeapons = GetWeapons()
        NormalDropdown:Refresh(newWeapons)
        MultiDropdown:Refresh(newWeapons)
    end
})

-- Botão Equipar TODOS (Instantâneo)
local EquipAllButton = Tab:CreateButton({
    Name = "Equipar TODOS (Backpack)",
    Callback = function()
        EquipAllTools()
    end
})

-- Botão Desequipar TODOS
local UnequipAllButton = Tab:CreateButton({
    Name = "Desequipar TODOS",
    Callback = function()
        UnequipAllTools()
    end
})

-- Toggle Auto Equip (Loop rápido)
local AutoEquipToggle = Tab:CreateToggle({
    Name = "Auto Equip Selecionados",
    CurrentValue = false,
    Flag = "AutoEquip",
    Callback = function(state)
        _G.SlowHub.AutoEquip = state
        
        if state then
            task.spawn(function()
                while _G.SlowHub.AutoEquip do
                    EquipSelectedTools()
                    task.wait(0.001) -- 1ms delay (ultra rápido)
                end
            end)
        end
    end
})

-- Toggle Auto Loop (Equipa/Desequipa rápido)
local AutoLoopToggle = Tab:CreateToggle({
    Name = "Auto Loop (Equip/Unequip)",
    CurrentValue = false,
    Flag = "AutoLoop",
    Callback = function(state)
        _G.SlowHub.AutoLoop = state
        
        if state then
            task.spawn(function()
                local equipping = true
                while _G.SlowHub.AutoLoop do
                    if equipping then
                        EquipSelectedTools()
                    else
                        UnequipAllTools()
                    end
                    equipping = not equipping
                    task.wait(0.001) -- 1ms
                end
            end)
        end
    end
})

-- Conexão ao renascer
Player.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    task.wait(0.5)
    
    if _G.SlowHub.AutoEquip then
        EquipSelectedTools()
    end
end)
