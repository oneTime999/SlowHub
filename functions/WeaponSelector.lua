local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local Tab = _G.MainTab

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

-- Equip 2 tools (first two in backpack)
local function EquipTwoTools()
    pcall(function()
        local char = Player.Character
        local backpack = Player:WaitForChild("Backpack")
        if not char or not backpack then return end
        
        local count = 0
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and count < 2 then
                tool.Parent = char
                count = count + 1
            end
            if count >= 2 then break end
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

-- MULTI Dropdown - Equips 2 tools
local MultiDropdown = Tab:CreateDropdown({
    Name = "Multi",
    Options = {"Equip 2 Tools"},
    CurrentOption = {""},
    MultipleOptions = false,
    Flag = "MultiWeapon",
    Callback = function(Value)
        EquipTwoTools()
    end
})

-- Refresh Button
local RefreshButton = Tab:CreateButton({
    Name = "Refresh",
    Callback = function()
        NormalDropdown:Refresh(GetWeapons())
    end
})
