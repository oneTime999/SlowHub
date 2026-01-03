local Tab = _G.MainTab
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.SelectedWeapon = nil
_G.SlowHub.EquipLoop = false

-- Normaliza o valor do dropdown
local function normalizeValue(Value)
    if type(Value) == "table" then
        return tostring(Value[1] or "")
    end
    return tostring(Value or "")
end

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

local function findToolByName(name)
    if not name or name == "" or name == "No weapons found" then 
        return nil 
    end

    local tool = nil
    
    pcall(function()
        local backpack = Player:FindFirstChild("Backpack")
        if backpack then
            tool = backpack:FindFirstChild(name)
            if tool and tool:IsA("Tool") then return end
        end

        if Player.Character then
            local charTool = Player.Character:FindFirstChild(name)
            if charTool and charTool:IsA("Tool") then
                tool = charTool
            end
        end
    end)
    
    return tool
end

local function EquipSelectedTool()
    local weaponName = _G.SlowHub.SelectedWeapon
    if not weaponName or weaponName == "" or weaponName == "No weapons found" then 
        return 
    end

    pcall(function()
        local char = Player.Character
        if not char then return end

        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end

        local tool = findToolByName(weaponName)
        if tool then
            humanoid:EquipTool(tool)
        end
    end)
end

-- Dropdown corrigido
Tab:CreateDropdown({
    Name = "Select Weapon",
    Options = GetWeapons(),
    Flag = "WeaponDropdown",
    Callback = function(Value)
        -- Normaliza o valor recebido
        local weapon = normalizeValue(Value)
        
        if weapon ~= "" and weapon ~= "No weapons found" then
            _G.SlowHub.SelectedWeapon = weapon
            print("Weapon selected:", weapon)
            EquipSelectedTool()
        else
            _G.SlowHub.SelectedWeapon = nil
        end
    end
})

-- Toggle para equipar em loop
Tab:CreateToggle({
    Name = "Loop Equip Tool",
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
Player.CharacterAdded:Connect(function(char)
    task.wait(1)
    if _G.SlowHub.EquipLoop then
        EquipSelectedTool()
    end
end)
