local Tab = _G.MainTab
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.SelectedWeapon = nil
_G.SlowHub.EquipLoop = false

-- Normaliza valor do dropdown (string ou table)
local function normalizeDropdownValue(Value)
    if typeof(Value) == "table" then
        return Value[1]
    end
    return Value
end

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

    return #weapons > 0 and weapons or {"No weapons found"}
end

local function findTool(name)
    if not name then return nil end

    local backpack = Player:FindFirstChild("Backpack")
    if backpack then
        local tool = backpack:FindFirstChild(name)
        if tool then return tool end
    end

    if Player.Character then
        local tool = Player.Character:FindFirstChild(name)
        if tool then return tool end
    end
end

local function EquipSelectedTool()
    local weaponName = _G.SlowHub.SelectedWeapon
    if not weaponName then return end

    local char = Player.Character
    if not char then return end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local tool = findTool(weaponName)
    if tool and tool:IsA("Tool") then
        pcall(function()
            humanoid:EquipTool(tool)
        end)
    end
end

-- Dropdown (corrigido)
Tab:CreateDropdown({
    Name = "Select Weapon",
    Options = GetWeapons(),
    Flag = "WeaponDropdown",
    Callback = function(Value)
        local weapon = normalizeDropdownValue(Value)

        if weapon and weapon ~= "No weapons found" then
            _G.SlowHub.SelectedWeapon = weapon
            EquipSelectedTool()
        else
            _G.SlowHub.SelectedWeapon = nil
        end
    end
})

-- Toggle Equip em Loop
Tab:CreateToggle({
    Name = "Equip Tool",
    Default = false,
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

-- Reequipar após respawn
Player.CharacterAdded:Connect(function()
    if _G.SlowHub.EquipLoop then
        task.wait(1)
        EquipSelectedTool()
    end
end)
