local Tab = _G.MainTab
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local function GetWeapons()
    local weapons = {}
    
    pcall(function()
        local backpack = Player:WaitForChild("Backpack")
        
        for _, item in pairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                table.insert(weapons, item.Name)
            end
        end
        
        if Player.Character then
            for _, item in pairs(Player.Character:GetChildren()) do
                if item:IsA("Tool") then
                    local found = false
                    for _, weaponName in pairs(weapons) do
                        if weaponName == item.Name then
                            found = true
                            break
                        end
                    end
                    if not found then
                        table.insert(weapons, item.Name)
                    end
                end
            end
        end
    end)
    
    if #weapons == 0 then
        table.insert(weapons, "No weapons found")
    end
    
    return weapons
end

local function EquipWeapon(weaponName)
    pcall(function()
        local backpack = Player:WaitForChild("Backpack")
        local character = Player.Character or Player.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")
        
        local tool = backpack:FindFirstChild(weaponName)
        
        if tool and tool:IsA("Tool") then
            humanoid:EquipTool(tool)
        end
    end)
end

local weaponDropdown = Tab:CreateDropdown({
    Name = "Select Weapon",
    Options = GetWeapons(),
    CurrentOption = GetWeapons()[1] or "No weapons found",
    Flag = "WeaponDropdown",
    Callback = function(Value)
        if Value and Value ~= "No weapons found" then
            _G.SlowHub.SelectedWeapon = Value
            EquipWeapon(Value)
        end
    end
})
