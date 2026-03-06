local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local Tab = _G.MainTab
local Window = _G.Window

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
    if Window.Flags.EquipLoop and Window.Flags.SelectedWeapon then
        EquipSelectedTool()
    end
end)

local function GetWeapons()
    local weapons = {}
    local added = {}

    local backpack = WeaponState.Backpack
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") and not added[item.Name] then
                added[item.Name] = true
                table.insert(weapons, item.Name)
            end
        end
    end

    local char = WeaponState.Character
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
    local weaponName = Window.Flags.SelectedWeapon
    if not weaponName or weaponName == "" or weaponName == "No weapons found" then
        return
    end

    local char = WeaponState.Character
    if not char then return end

    local humanoid = WeaponState.Humanoid
    if not humanoid or humanoid.Health <= 0 then return end

    if char:FindFirstChild(weaponName) then return end

    local tool = WeaponState.Backpack:FindFirstChild(weaponName)
    if tool then
        pcall(function()
            humanoid:EquipTool(tool)
        end)
    end
end

local function StartEquipLoop()
    if WeaponState.EquipLoopThread then return end

    WeaponState.EquipLoopThread = task.spawn(function()
        while Window.Flags.EquipLoop do
            EquipSelectedTool()
            task.wait(Window.Flags.EquipInterval or 0.25)
        end
        WeaponState.EquipLoopThread = nil
    end)
end

local function StopEquipLoop()
    if WeaponState.EquipLoopThread then
        task.cancel(WeaponState.EquipLoopThread)
        WeaponState.EquipLoopThread = nil
    end
end

Tab:Section({Title = "Weapon"})

local WeaponDropdown = Tab:Dropdown({
    Title = "Select Weapon",
    Flag = "SelectedWeapon",
    Values = GetWeapons(),
    Multi = false,
    Callback = function(Value)
        local weapon = type(Value) == "table" and Value[1] or Value
        if weapon and weapon ~= "No weapons found" then
            EquipSelectedTool()
        end
    end
})

Tab:Button({
    Title = "Refresh Weapons",
    Callback = function()
        WeaponDropdown:Refresh(GetWeapons())
    end
})

Tab:Toggle({
    Title = "Loop Equip Tool",
    Flag = "EquipLoop",
    Value = false,
    Callback = function(state)
        if state then
            StartEquipLoop()
        else
            StopEquipLoop()
        end
    end
})

Tab:Slider({
    Title = "Equip Interval",
    Flag = "EquipInterval",
    Step = 0.05,
    Value = {
        Min = 0.1,
        Max = 1,
        Default = 0.25,
    }
})

task.spawn(function()
    task.wait(2)

    WeaponDropdown:Refresh(GetWeapons())

    if Window.Flags.SelectedWeapon then
        WeaponDropdown:Set(Window.Flags.SelectedWeapon)
        EquipSelectedTool()
    end
end)

Player.Backpack.ChildAdded:Connect(function()
    WeaponDropdown:Refresh(GetWeapons())
end)

if Window.Flags.EquipLoop then
    task.spawn(function()
        task.wait(2)
        StartEquipLoop()
    end)
end
