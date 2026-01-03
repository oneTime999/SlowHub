-- LocalScript (cliente)
local Tab = _G.MainTab
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.SelectedWeapon = nil
_G.SlowHub.EquipLoop = false

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

local function findToolByName(name)
    if not name then return nil end
    local backpack = Player:FindFirstChild("Backpack")
    if backpack then
        local t = backpack:FindFirstChild(name)
        if t and t:IsA("Tool") then return t end
    end
    if Player.Character then
        local t = Player.Character:FindFirstChild(name)
        if t and t:IsA("Tool") then return t end
    end
    return nil
end

local function EquipSelectedTool()
    local name = _G.SlowHub.SelectedWeapon
    if not name then return end
    local char = Player.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local tool = findToolByName(name)
    if not tool then return end
    pcall(function()
        humanoid:EquipTool(tool)
    end)
end

-- cria dropdown com os itens atuais
local options = GetWeapons()
local currentOption = options[1]
if currentOption == "No weapons found" then currentOption = nil end
_G.SlowHub.SelectedWeapon = currentOption

local weaponDropdown = Tab:CreateDropdown({
    Name = "Select Weapon",
    Options = GetWeapons(),
    CurrentOption = currentOption or (GetWeapons()[1] or "No weapons found"),
    Flag = "WeaponDropdown",
    Callback = function(Value)
        if Value and Value ~= "No weapons found" then
            _G.SlowHub.SelectedWeapon = Value
            EquipSelectedTool()
        else
            _G.SlowHub.SelectedWeapon = nil
        end
    end
})

-- toggle que equipa em loop
Tab:CreateToggle({
    Name = "Equip Tool",
    Default = false,
    Callback = function(Value)
        _G.SlowHub.EquipLoop = Value
        if Value then
            task.spawn(function()
                while _G.SlowHub.EquipLoop do
                    EquipSelectedTool()
                    task.wait(0.5)
                end
            end)
        end
    end
})

-- reequipa após respawn se necessário
Player.CharacterAdded:Connect(function()
    if _G.SlowHub.EquipLoop and _G.SlowHub.SelectedWeapon then
        task.wait(1)
        EquipSelectedTool()
    end
end)
