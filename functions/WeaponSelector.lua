local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local Tab = _G.MainTab

_G.SlowHub = _G.SlowHub or {}
if _G.SlowHub.SelectedWeapon == nil then
    _G.SlowHub.SelectedWeapon = nil
end
if _G.SlowHub.EquipLoop == nil then
    _G.SlowHub.EquipLoop = false
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

local function EquipSelectedTool()
    local weaponName = _G.SlowHub.SelectedWeapon
    
    if not weaponName or weaponName == "" or weaponName == "No weapons found" then 
        return 
    end

    pcall(function()
        local char = Player.Character
        if not char then return end

        local humanoid = char:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return end

        if char:FindFirstChild(weaponName) then
            return
        end

        local backpack = Player:FindFirstChild("Backpack")
        if backpack then
            local tool = backpack:FindFirstChild(weaponName)
            if tool and tool:IsA("Tool") then
                humanoid:EquipTool(tool)
            end
        end
    end)
end

local weapons = GetWeapons()
local currentOption = {""}

if _G.SlowHub.SelectedWeapon and _G.SlowHub.SelectedWeapon ~= "" then
    local found = false
    for _, weapon in ipairs(weapons) do
        if weapon == _G.SlowHub.SelectedWeapon then
            found = true
            break
        end
    end
    
    if found then
        currentOption = {_G.SlowHub.SelectedWeapon}
    else
        _G.SlowHub.SelectedWeapon = nil
        currentOption = {""}
    end
end

local WeaponDropdown = Tab:CreateDropdown({
    Name = "Select Weapon",
    Options = weapons,
    CurrentOption = currentOption,
    MultipleOptions = false,
    Flag = "SelectWeapon",
    Callback = function(Value)
        local weapon = (type(Value) == "table" and Value[1]) or Value
        
        print("Selected Weapon:", weapon) 

        if weapon and weapon ~= "" and weapon ~= "No weapons found" then
            _G.SlowHub.SelectedWeapon = weapon
            EquipSelectedTool()
        else
            _G.SlowHub.SelectedWeapon = nil
        end
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

task.spawn(function()
    task.wait(1)
    
    if _G.SlowHub.SelectedWeapon and _G.SlowHub.SelectedWeapon ~= "" then
        local success, err = pcall(function()
            if WeaponDropdown and typeof(WeaponDropdown) == "table" and WeaponDropdown.Set then
                WeaponDropdown:Set(_G.SlowHub.SelectedWeapon)
                print("WeaponDropdown:Set() applied successfully")
            end
        end)
        
        if not success then
            warn("Failed to set WeaponDropdown value: " .. tostring(err))
        end
    end
end)

local RefreshButton = Tab:CreateButton({
    Name = "Refresh Weapons",
    Callback = function()
        local newWeapons = GetWeapons()
        WeaponDropdown:Refresh(newWeapons)
    end
})

local EquipLoopToggle = Tab:CreateToggle({
    Name = "Loop Equip Tool",
    CurrentValue = _G.SlowHub.EquipLoop or false,
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
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

Player.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    char:WaitForChild("Backpack")
    task.wait(1)
    if _G.SlowHub.EquipLoop then
        EquipSelectedTool()
    end
end)

if _G.SlowHub.SelectedWeapon then
    task.wait(0.5)
    EquipSelectedTool()
end
