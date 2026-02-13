local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local Tab = _G.MainTab

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.SelectedWeapons = {}
_G.SlowHub.EquipLoop = false
_G.SlowHub.MultiToolMode = false

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

local function EquipSelectedTools()
    if _G.SlowHub.MultiToolMode then
        pcall(function()
            local char = Player.Character
            if not char then return end

            local humanoid = char:FindFirstChild("Humanoid")
            if not humanoid or humanoid.Health <= 0 then return end

            local backpack = Player:FindFirstChild("Backpack")
            if not backpack then return end

            for _, weaponName in ipairs(_G.SlowHub.SelectedWeapons) do
                if not char:FindFirstChild(weaponName) then
                    local tool = backpack:FindFirstChild(weaponName)
                    if tool and tool:IsA("Tool") then
                        humanoid:EquipTool(tool)
                        task.wait(0.05)
                    end
                end
            end
        end)
    else
        local weaponName = _G.SlowHub.SelectedWeapons[1]
        
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
end

Tab:CreateToggle({
    Name = "Multi Tool Mode",
    CurrentValue = false,
    Flag = "MultiToolMode",
    Callback = function(state)
        _G.SlowHub.MultiToolMode = state
        _G.SlowHub.SelectedWeapons = {}
        
        local newWeapons = GetWeapons()
        WeaponDropdown:Refresh(newWeapons)
        
        if state then
            WeaponDropdown:Set({""})
        else
            WeaponDropdown:Set({""})
        end
    end
})

local WeaponDropdown = Tab:CreateDropdown({
    Name = "Select Weapon",
    Options = GetWeapons(),
    CurrentOption = {""},
    MultipleOptions = function()
        return _G.SlowHub.MultiToolMode
    end,
    Flag = "SelectWeapon",
    Callback = function(Value)
        if _G.SlowHub.MultiToolMode then
            _G.SlowHub.SelectedWeapons = {}
            
            if type(Value) == "table" then
                for _, weapon in ipairs(Value) do
                    if weapon and weapon ~= "" and weapon ~= "No weapons found" then
                        table.insert(_G.SlowHub.SelectedWeapons, weapon)
                    end
                end
            end
            
            print("Selected Weapons:", table.concat(_G.SlowHub.SelectedWeapons, ", "))
        else
            local weapon = (type(Value) == "table" and Value[1]) or Value
            
            print("Selected Weapon:", weapon)
            
            if weapon and weapon ~= "" and weapon ~= "No weapons found" then
                _G.SlowHub.SelectedWeapons = {weapon}
            else
                _G.SlowHub.SelectedWeapons = {}
            end
        end
    end
})

local RefreshButton = Tab:CreateButton({
    Name = "Refresh Weapons",
    Callback = function()
        local newWeapons = GetWeapons()
        WeaponDropdown:Refresh(newWeapons)
    end
})

local EquipLoopToggle = Tab:CreateToggle({
    Name = "Loop Equip Tool",
    CurrentValue = false,
    Flag = "LoopEquipTool",
    Callback = function(state)
        _G.SlowHub.EquipLoop = state

        if state then
            task.spawn(function()
                while _G.SlowHub.EquipLoop do
                    EquipSelectedTools()
                    task.wait(0.25)
                end
            end)
        end
    end
})

Player.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    char:WaitForChild("Backpack")
    task.wait(1)
    if _G.SlowHub.EquipLoop then
        EquipSelectedTools()
    end
end)
