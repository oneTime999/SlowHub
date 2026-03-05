local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local Tab = _G.MainTab

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.SelectedWeapon = nil
_G.SlowHub.EquipLoop = false
_G.SlowHub.EquipInterval = _G.SlowHub.EquipInterval or 0.25

local WeaponState = {
    Character = nil,
    Humanoid = nil,
    Backpack = nil,
    EquipLoopConnection = nil
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
    
    local success = pcall(function()
        if not WeaponState.Backpack then
            WeaponState.Backpack = Player:WaitForChild("Backpack")
        end
        
        for _, item in ipairs(WeaponState.Backpack:GetChildren()) do
            if item:IsA("Tool") and not added[item.Name] then
                added[item.Name] = true
                table.insert(weapons, item.Name)
            end
        end
        
        if WeaponState.Character then
            for _, item in ipairs(WeaponState.Character:GetChildren()) do
                if item:IsA("Tool") and not added[item.Name] then
                    added[item.Name] = true
                    table.insert(weapons, item.Name)
                end
            end
        end
    end)
    
    if not success or #weapons == 0 then
        return {"No weapons found"}
    end
    
    return weapons
end

function EquipSelectedTool()
    local weaponName = _G.SlowHub.SelectedWeapon
    
    if not weaponName or weaponName == "" or weaponName == "No weapons found" then
        return false
    end
    
    local success = pcall(function()
        if not WeaponState.Character then return false end
        if not WeaponState.Humanoid then return false end
        if WeaponState.Humanoid.Health <= 0 then return false end
        
        if WeaponState.Character:FindFirstChild(weaponName) then return true end
        
        if not WeaponState.Backpack then return false end
        
        local tool = WeaponState.Backpack:FindFirstChild(weaponName)
        if tool and tool:IsA("Tool") then
            WeaponState.Humanoid:EquipTool(tool)
            return true
        end
        
        return false
    end)
    
    return success
end

local function StartEquipLoop()
    if _G.SlowHub.EquipLoop then return end
    
    _G.SlowHub.EquipLoop = true
    
    WeaponState.EquipLoopConnection = task.spawn(function()
        while _G.SlowHub.EquipLoop do
            EquipSelectedTool()
            task.wait(_G.SlowHub.EquipInterval)
        end
    end)
end

local function StopEquipLoop()
    _G.SlowHub.EquipLoop = false
    
    if WeaponState.EquipLoopConnection then
        WeaponState.EquipLoopConnection = nil
    end
end

local WeaponDropdown = Tab:Dropdown({
    Title = "Select Weapon",
    Values = GetWeapons(),
    Default = "",
    Multi = false,
    Callback = function(Value)
        local weapon = type(Value) == "table" and Value[1] or Value
        
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

Tab:Button({
    Title = "Refresh Weapons",
    Callback = function()
        local newWeapons = GetWeapons()
        WeaponDropdown:Refresh(newWeapons)
    end
})

Tab:Toggle({
    Title = "Loop Equip Tool",
    Default = false,
    Callback = function(state)
        if state then
            StartEquipLoop()
        else
            StopEquipLoop()
        end
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

Tab:Slider({
    Title = "Equip Interval",
    Min = 0.1,
    Max = 1,
    Default = _G.SlowHub.EquipInterval,
    Suffix = "Seconds",
    Callback = function(Value)
        _G.SlowHub.EquipInterval = Value
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})
