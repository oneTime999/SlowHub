local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local Tab = _G.MainTab

local WeaponState = {
    Character = nil,
    Humanoid = nil,
    Backpack = nil,
    EquipLoopThread = nil
}

local function InitializeWeaponState()
    WeaponState.Character = Player.Character
    WeaponState.Humanoid = WeaponState.Character and WeaponState.Character:FindFirstChildOfClass("Humanoid")
    WeaponState.Backpack = Player:FindFirstChild("Backpack")
end

InitializeWeaponState()

Player.CharacterAdded:Connect(function(char)
    WeaponState.Character = char
    WeaponState.Humanoid = nil
    WeaponState.Backpack = nil
    task.wait(0.1)
    WeaponState.Humanoid = char:FindFirstChildOfClass("Humanoid")
    WeaponState.Backpack = Player:FindFirstChild("Backpack")
    task.wait(0.9)
    if _G.SlowHub.EquipLoop and _G.SlowHub.SelectedWeapon then
        EquipSelectedTool()
    end
end)

local function GetWeapons()
    local weapons = {}
    local added = {}

    local backpack = WeaponState.Backpack or Player:FindFirstChild("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") and not added[item.Name] then
                added[item.Name] = true
                table.insert(weapons, item.Name)
            end
        end
    end

    local char = WeaponState.Character or Player.Character
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") and not added[item.Name] then
                added[item.Name] = true
                table.insert(weapons, item.Name)
            end
        end
    end

    if #weapons == 0 then
        return {"No weapons found"}
    end
    return weapons
end

function EquipSelectedTool()
    local weaponName = _G.SlowHub.SelectedWeapon
    if not weaponName or weaponName == "" or weaponName == "No weapons found" then
        return false
    end

    local char = WeaponState.Character or Player.Character
    if not char then return false end

    local humanoid = WeaponState.Humanoid or char:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end

    if char:FindFirstChild(weaponName) then return true end

    local backpack = WeaponState.Backpack or Player:FindFirstChild("Backpack")
    if not backpack then return false end

    local tool = backpack:FindFirstChild(weaponName)
    if tool and tool:IsA("Tool") then
        local ok = pcall(function()
            humanoid:EquipTool(tool)
        end)
        return ok
    end

    return false
end

local function StartEquipLoop()
    if WeaponState.EquipLoopThread then return end
    _G.SlowHub.EquipLoop = true

    WeaponState.EquipLoopThread = task.spawn(function()
        while _G.SlowHub.EquipLoop do
            EquipSelectedTool()
            task.wait(_G.SlowHub.EquipInterval or 0.25)
        end
        WeaponState.EquipLoopThread = nil
    end)
end

local function StopEquipLoop()
    _G.SlowHub.EquipLoop = false
    if WeaponState.EquipLoopThread then
        task.cancel(WeaponState.EquipLoopThread)
        WeaponState.EquipLoopThread = nil
    end
end

Tab:Section({Title = "Weapon"})

local WeaponDropdown = Tab:Dropdown({
    Title = "Select Weapon",
    Flag = "SelectedWeapon",              -- ✅ ADICIONADO
    Values = GetWeapons(),
    Default = _G.SlowHub.SelectedWeapon or "",  -- ✅ Value → Default
    Multi = false,
    Callback = function(Value)
        local weapon = type(Value) == "table" and Value[1] or Value
        if weapon and weapon ~= "" and weapon ~= "No weapons found" then
            _G.SlowHub.SelectedWeapon = weapon
            EquipSelectedTool()
        else
            _G.SlowHub.SelectedWeapon = nil
        end
        if _G.SaveConfig then _G.SaveConfig() end
    end
})

Tab:Button({
    Title = "Refresh Weapons",
    Callback = function()
        local newWeapons = GetWeapons()
        WeaponDropdown:Refresh(newWeapons)
    end
})

Tab:Toggle({
    Title = "Loop Equip Tool",
    Flag = "EquipLoop",                   -- ✅ ADICIONADO
    Default = _G.SlowHub.EquipLoop or false,  -- ✅ Value → Default
    Callback = function(state)
        if state then
            StartEquipLoop()
        else
            StopEquipLoop()
        end
        if _G.SaveConfig then _G.SaveConfig() end
    end
})

Tab:Slider({
    Title = "Equip Interval",
    Flag = "EquipInterval",               -- ✅ ADICIONADO
    Min = 0.1,                            -- ✅ tirado do Value = {}
    Max = 1,
    Default = _G.SlowHub.EquipInterval or 0.25,
    Step = 0.05,
    Callback = function(Value)
        _G.SlowHub.EquipInterval = Value
        if _G.SaveConfig then _G.SaveConfig() end
    end
})

-- Restaura estado salvo ao carregar
if _G.SlowHub.SelectedWeapon then
    task.spawn(function()
        task.wait(1)
        EquipSelectedTool()
    end)
end

if _G.SlowHub.EquipLoop then
    task.spawn(function()
        task.wait(1.5)
        StartEquipLoop()
    end)
end
