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

-- Equip all tools from backpack
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

-- Unequip all tools to backpack
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

-- Normal Dropdown (Single selection)
local NormalDropdown = Tab:CreateDropdown({
    Name = "Normal",
    Options = GetWeapons(),
    CurrentOption = {""},
    MultipleOptions = false,
    Flag = "NormalWeapon",
    Callback = function(Value)
        local weapon = (type(Value) == "table" and Value[1]) or Value
        
        if weapon and weapon ~= "" and weapon ~= "No weapons found" then
            pcall(function()
                local char = Player.Character
                local backpack = Player:WaitForChild("Backpack")
                if not char or not backpack then return end
                
                local tool = backpack:FindFirstChild(weapon)
                if tool and tool:IsA("Tool") then
                    tool.Parent = char
                end
            end)
        end
    end
})

-- Multi Dropdown (Equip All - same as equip all button)
local MultiDropdown = Tab:CreateDropdown({
    Name = "Multi",
    Options = GetWeapons(),
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "MultiWeapon",
    Callback = function(Value)
        -- Just equip all regardless of selection
        EquipAllTools()
    end
})

-- Refresh Button
local RefreshButton = Tab:CreateButton({
    Name = "Refresh Weapons",
    Callback = function()
        local newWeapons = GetWeapons()
        NormalDropdown:Refresh(newWeapons)
        MultiDropdown:Refresh(newWeapons)
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

-- Auto Equip Toggle (Fast loop)
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

-- Character respawn connection
Player.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    task.wait(0.5)
    
    if _G.SlowHub.AutoEquip then
        EquipAllTools()
    end
end)
