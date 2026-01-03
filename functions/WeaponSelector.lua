local Tab = _G.MainTab
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.SelectedWeapon = nil
_G.SlowHub.EquipLoop = false

-- Pega todas as tools do Backpack e do Character
local function GetWeapons()
    local weapons = {}
    local added = {}

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

    if #weapons == 0 then
        table.insert(weapons, "No weapons found")
    end

    return weapons
end

-- Equipa a tool selecionada
local function EquipSelectedTool()
    if not _G.SlowHub.SelectedWeapon then return end
    if not Player.Character then return end

    local humanoid = Player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local backpack = Player:FindFirstChild("Backpack")
    if not backpack then return end

    local tool = backpack:FindFirstChild(_G.SlowHub.SelectedWeapon)
    if tool and tool:IsA("Tool") then
        humanoid:EquipTool(tool)
    end
end

-- Dropdown
local weaponDropdown = Tab:CreateDropdown({
    Name = "Select Weapon",
    Options = GetWeapons(),
    CurrentOption = GetWeapons()[1],
    Flag = "WeaponDropdown",
    Callback = function(Value)
        if Value ~= "No weapons found" then
            _G.SlowHub.SelectedWeapon = Value
            EquipSelectedTool() -- equipa instantaneamente ao escolher
        end
    end
})

-- Toggle de equipar em loop
Tab:CreateToggle({
    Name = "Equip Tool",
    Default = false,
    Callback = function(Value)
        _G.SlowHub.EquipLoop = Value

        if Value then
            task.spawn(function()
                while _G.SlowHub.EquipLoop do
                    EquipSelectedTool()
                    task.wait(0.3)
                end
            end)
        end
    end
})
