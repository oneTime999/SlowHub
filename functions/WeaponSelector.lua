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
    WeaponState.Character = Player.Character or Player.CharacterAdded:Wait()
    WeaponState.Humanoid = WeaponState.Character:FindFirstChildOfClass("Humanoid")
    WeaponState.Backpack = Player:WaitForChild("Backpack")
end

InitializeWeaponState()

Player.CharacterAdded:Connect(function(char)
    WeaponState.Character = char
    WeaponState.Humanoid = char:WaitForChild("Humanoid")
    WeaponState.Backpack = Player:WaitForChild("Backpack")
    task.wait(0.5)
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

    table.sort(weapons)
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

local initialWeapons = GetWeapons()
local savedWeapon = _G.SlowHub.SelectedWeapon

if savedWeapon and savedWeapon ~= "" and savedWeapon ~= "No weapons found" then
    local found = false
    for _, v in ipairs(initialWeapons) do
        if v == savedWeapon then
            found = true
            break
        end
    end
    if not found then
        if initialWeapons[1] == "No weapons found" then
            initialWeapons = {savedWeapon}
        else
            table.insert(initialWeapons, 1, savedWeapon)
        end
    end
end

local WeaponDropdown = Tab:Dropdown({
    Title = "Select Weapon",
    Flag = "SelectedWeapon",
    Values = initialWeapons,
    Value = savedWeapon or "",
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
        local weapons = GetWeapons()
        if _G.SlowHub.SelectedWeapon then
            table.insert(weapons, 1, _G.SlowHub.SelectedWeapon)
        end
        WeaponDropdown:Refresh(weapons)
        if _G.SlowHub.SelectedWeapon then
            WeaponDropdown:Set(_G.SlowHub.SelectedWeapon)
        end
    end
})

Tab:Toggle({
    Title = "Loop Equip Tool",
    Flag = "EquipLoop",
    Value = _G.SlowHub.EquipLoop or false,
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
    Flag = "EquipInterval",
    Step = 0.05,
    Value = {
        Min = 0.1,
        Max = 1,
        Default = _G.SlowHub.EquipInterval or 0.25,
    },
    Callback = function(Value)
        _G.SlowHub.EquipInterval = Value
        if _G.SaveConfig then _G.SaveConfig() end
    end
})

task.spawn(function()
    task.wait(2)

    local weapons = GetWeapons()
    if _G.SlowHub.SelectedWeapon then
        table.insert(weapons, 1, _G.SlowHub.SelectedWeapon)
    end

    WeaponDropdown:Refresh(weapons)

    if _G.SlowHub.SelectedWeapon then
        WeaponDropdown:Set(_G.SlowHub.SelectedWeapon)
        EquipSelectedTool()
    end
end)

Player.Backpack.ChildAdded:Connect(function()
    local weapons = GetWeapons()
    if _G.SlowHub.SelectedWeapon then
        table.insert(weapons, 1, _G.SlowHub.SelectedWeapon)
    end
    WeaponDropdown:Refresh(weapons)
end)

if _G.SlowHub.EquipLoop then
    task.spawn(function()
        task.wait(2)
        StartEquipLoop()
    end)
end
