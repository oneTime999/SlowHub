local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local Tab = _G.MainTab

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.SelectedWeapon = nil
_G.SlowHub.SelectedWeapons = {}
_G.SlowHub.EquipLoop = false
_G.SlowHub.MultiLoop = false
_G.SlowHub.UltraFastLoop = false

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

-- MÉTODO 1: Equipar TODOS de uma vez (simultâneo)
local function EquipAllAtOnce()
    pcall(function()
        local char = Player.Character
        if not char then return end
        local humanoid = char:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return end
        
        local backpack = Player:FindFirstChild("Backpack")
        if not backpack then return end
        
        -- Tenta equipar todas as tools selecionadas simultaneamente
        for _, weaponName in ipairs(_G.SlowHub.SelectedWeapons) do
            task.spawn(function()
                local tool = backpack:FindFirstChild(weaponName)
                if tool and tool:IsA("Tool") then
                    humanoid:EquipTool(tool)
                end
            end)
        end
    end)
end

-- MÉTODO 2: Troca ULTRA RÁPIDA (quase imperceptível)
local function StartUltraFastLoop()
    task.spawn(function()
        while _G.SlowHub.UltraFastLoop and #_G.SlowHub.SelectedWeapons > 0 do
            -- Roda TODAS as armas em paralelo com delay mínimo
            for _, weaponName in ipairs(_G.SlowHub.SelectedWeapons) do
                task.spawn(function()
                    pcall(function()
                        local char = Player.Character
                        if not char then return end
                        local humanoid = char:FindFirstChild("Humanoid")
                        if not humanoid or humanoid.Health <= 0 then return end
                        
                        local backpack = Player:FindFirstChild("Backpack")
                        if backpack then
                            local tool = backpack:FindFirstChild(weaponName)
                            if tool and tool:IsA("Tool") then
                                humanoid:EquipTool(tool)
                            end
                        end
                    end)
                end)
            end
            task.wait(0.03) -- 30ms - velocidade máxima estável
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
        
        -- Desativa outros loops
        _G.SlowHub.MultiLoop = false
        _G.SlowHub.UltraFastLoop = false
        
        if weapon and weapon ~= "" and weapon ~= "No weapons found" then
            _G.SlowHub.SelectedWeapon = weapon
            EquipSelectedTool()
        else
            _G.SlowHub.SelectedWeapon = nil
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
        
        -- Se ultra fast estiver ativo, reinicia
        if _G.SlowHub.UltraFastLoop and #_G.SlowHub.SelectedWeapons > 0 then
            _G.SlowHub.UltraFastLoop = false
            task.wait(0.05)
            _G.SlowHub.UltraFastLoop = true
            StartUltraFastLoop()
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

-- Toggle Loop Normal
local EquipLoopToggle = Tab:CreateToggle({
    Name = "Loop Equip (Normal)",
    CurrentValue = false,
    Flag = "LoopEquipTool",
    Callback = function(state)
        _G.SlowHub.EquipLoop = state
        _G.SlowHub.UltraFastLoop = false
        
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

-- Toggle ALL AT ONCE (Equipa todos simultaneamente)
local AllAtOnceToggle = Tab:CreateToggle({
    Name = "Equipar TODOS de Uma Vez",
    CurrentValue = false,
    Flag = "AllAtOnce",
    Callback = function(state)
        _G.SlowHub.EquipLoop = false
        _G.SlowHub.UltraFastLoop = false
        
        if state and #_G.SlowHub.SelectedWeapons > 0 then
            -- Equipa imediatamente e fica repetindo
            task.spawn(function()
                while state do
                    EquipAllAtOnce()
                    task.wait(0.1)
                end
            end)
        end
    end
})

-- Toggle ULTRA FAST (Troca mais rápida possível)
local UltraFastToggle = Tab:CreateToggle({
    Name = "ULTRA FAST (Troca Rápida)",
    CurrentValue = false,
    Flag = "UltraFast",
    Callback = function(state)
        _G.SlowHub.EquipLoop = false
        _G.SlowHub.UltraFastLoop = state
        
        if state and #_G.SlowHub.SelectedWeapons > 0 then
            StartUltraFastLoop()
        else
            _G.SlowHub.UltraFastLoop = false
        end
    end
})

-- Conexão ao renascer
Player.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    task.wait(0.5)
    
    if _G.SlowHub.EquipLoop then
        EquipSelectedTool()
    elseif _G.SlowHub.UltraFastLoop and #_G.SlowHub.SelectedWeapons > 0 then
        StartUltraFastLoop()
    end
end)
