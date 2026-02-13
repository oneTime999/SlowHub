local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local Tab = _G.MainTab

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.AutoEquip = false

-- Get weapons list
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

-- Equip single tool
local function EquipTool(toolName)
    pcall(function()
        local char = Player.Character
        local backpack = Player:WaitForChild("Backpack")
        if not char or not backpack then return end
        
        local tool = backpack:FindFirstChild(toolName)
        if tool and tool:IsA("Tool") then
            tool.Parent = char
        end
    end)
end

-- Equip all tools
local function EquipAllTools()
    pcall(function()
        local char = Player.Character
        if not char then return end
        
        local backpack = Player:WaitForChild("Backpack")
        if not backpack then return end
        
        -- Equip all from backpack
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                tool.Parent = char
            end
        end
    end)
end

-- Unequip all tools
local function UnequipAllTools()
    pcall(function()
        local char = Player.Character
        local backpack = Player:WaitForChild("Backpack")
        if not char or not backpack then return end
        
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                tool.Parent = backpack
            end
        end
    end)
end

-- NORMAL Dropdown - Select single weapon
local NormalDropdown = Tab:CreateDropdown({
    Name = "Normal",
    Options = GetWeapons(),
    CurrentOption = {""},
    MultipleOptions = false,
    Flag = "NormalWeapon",
    Callback = function(Value)
        local weapon = (type(Value) == "table" and Value[1]) or Value
        
        if weapon and weapon ~= "" and weapon ~= "No weapons found" then
            EquipTool(weapon)
        end
    end
})

-- MULTI Dropdown - Equips ALL tools (no selection needed)
local MultiDropdown = Tab:CreateDropdown({
    Name = "Multi",
    Options = {"Equip All Tools"},
    CurrentOption = {""},
    MultipleOptions = false,
    Flag = "MultiWeapon",
    Callback = function(Value)
        EquipAllTools()
    end
})

-- Refresh Button
local RefreshButton = Tab:CreateButton({
    Name = "Refresh Weapons",
    Callback = function()
        local newWeapons = GetWeapons()
        NormalDropdown:Refresh(newWeapons)
    end
})

-- Equip All Button
local EquipAllButton = Tab:CreateButton({
    Name = "Equip All",
    Callback = function()
        EquipAllTools()
    end
})

-- Unequip All Button
local UnequipAllButton = Tab:CreateButton({
    Name = "Unequip All",
    Callback = function()
        UnequipAllTools()
    end
})

-- Auto Equip Toggle
local AutoEquipToggle = Tab:CreateToggle({
    Name = "Auto Equip All",
    CurrentValue = false,
    Flag = "AutoEquipAll",
    Callback = function(state)
        _G.SlowHub.AutoEquip = state
        
        if state then
            task.spawn(function()
                while _G.SlowHub.AutoEquip do
                    EquipAllTools()
                    task.wait(0.001)
                end
            end)
        end
    end
})

-- Respawn connection
Player.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    task.wait(0.5)
    
    if _G.SlowHub.AutoEquip then
        EquipAllTools()
    end
end)
