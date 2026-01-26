local Tab = _G.MainTab
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.SelectedWeapon = nil
_G.SlowHub.EquipLoop = false

local function GetWeapons()
    local weapons = {}
    local added = {}

    pcall(function()
        local backpack = Player:WaitForChild("Backpack", 5)
        if backpack then
            for _, item in ipairs(backpack:GetChildren()) do
                if item:IsA("Tool") and not added[item.Name] then
                    added[item.Name] = true
                    table.insert(weapons, item.Name)
                end
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

    table.sort(weapons) -- Ordenar alfabeticamente
    return #weapons > 0 and weapons or {"No weapons found"}
end

local function findToolByName(name)
    if not name or name == "" or name == "No weapons found" then 
        return nil 
    end

    local tool = nil
    
    pcall(function()
        -- Primeiro verificar se já está equipado
        if Player.Character then
            local charTool = Player.Character:FindFirstChild(name)
            if charTool and charTool:IsA("Tool") then
                tool = charTool
                return
            end
        end

        -- Depois verificar na backpack
        local backpack = Player:FindFirstChild("Backpack")
        if backpack then
            local backpackTool = backpack:FindFirstChild(name)
            if backpackTool and backpackTool:IsA("Tool") then
                tool = backpackTool
                return
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

    local success = pcall(function()
        local char = Player.Character
        if not char then 
            warn("[SlowHub] Character not found")
            return 
        end

        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid then 
            warn("[SlowHub] Humanoid not found")
            return 
        end

        -- Verificar se já está equipado
        if char:FindFirstChild(weaponName) then
            print("[SlowHub] Weapon already equipped:", weaponName)
            return
        end

        -- Buscar o tool
        local tool = findToolByName(weaponName)
        
        if tool then
            -- Garantir que o tool está na backpack antes de equipar
            if tool.Parent == char then
                print("[SlowHub] Weapon already in character:", weaponName)
                return
            end
            
            if tool.Parent ~= Player.Backpack then
                tool.Parent = Player.Backpack
                task.wait(0.1)
            end
            
            -- Equipar
            humanoid:EquipTool(tool)
            print("[SlowHub] Equipped weapon:", weaponName)
        else
            warn("[SlowHub] Weapon not found:", weaponName)
        end
    end)

    if not success then
        warn("[SlowHub] Failed to equip weapon:", weaponName)
    end
end

-- Criar Dropdown
local WeaponDropdown = Tab:CreateDropdown({
    Name = "Select Weapon",
    Options = GetWeapons(),
    CurrentOption = nil,
    Flag = "SelectWeapon",
    Callback = function(Value)
        local weapon = tostring(Value)
        
        print("[SlowHub] Weapon selected from dropdown:", weapon)
        
        if weapon ~= "" and weapon ~= "No weapons found" then
            _G.SlowHub.SelectedWeapon = weapon
            
            -- Pequeno delay para garantir que tudo está pronto
            task.wait(0.1)
            
            -- Equipar imediatamente
            EquipSelectedTool()
            
            -- Salvar configuração
            if _G.SaveConfig then
                _G.SaveConfig()
            end
        else
            _G.SlowHub.SelectedWeapon = nil
        end
    end
})

-- Botão de Refresh
local RefreshButton = Tab:CreateButton({
    Name = "Refresh Weapons",
    Callback = function()
        local newWeapons = GetWeapons()
        
        print("[SlowHub] Weapons refreshed. Found:", #newWeapons)
        
        pcall(function()
            WeaponDropdown:Refresh(newWeapons)
        end)
        
        if _G.Rayfield then
            _G.Rayfield:Notify({
                Title = "Weapons Refreshed",
                Content = "Found " .. #newWeapons .. " weapon(s)",
                Duration = 3,
                Image = 4483362458
            })
        end
    end
})

-- Toggle de Loop Equip
local EquipLoopToggle = Tab:CreateToggle({
    Name = "Loop Equip Tool",
    CurrentValue = false,
    Flag = "LoopEquipTool",
    Callback = function(state)
        _G.SlowHub.EquipLoop = state

        if state then
            task.spawn(function()
                while _G.SlowHub.EquipLoop do
                    if _G.SlowHub.SelectedWeapon then
                        EquipSelectedTool()
                    end
                    task.wait(0.25)
                end
            end)
            
            print("[SlowHub] Loop Equip enabled")
        else
            print("[SlowHub] Loop Equip disabled")
        end
    end
})

-- Re-equipar ao respawnar
Player.CharacterAdded:Connect(function(char)
    print("[SlowHub] Character respawned, waiting to equip...")
    
    -- Aguardar o character carregar completamente
    local humanoid = char:WaitForChild("Humanoid", 10)
    if not humanoid then return end
    
    task.wait(1) -- Aguardar backpack carregar
    
    if _G.SlowHub.SelectedWeapon then
        print("[SlowHub] Attempting to re-equip:", _G.SlowHub.SelectedWeapon)
        EquipSelectedTool()
    end
end)

-- Auto-equipar se já tinha uma arma selecionada
if _G.SlowHub.SelectedWeapon and _G.SlowHub.SelectedWeapon ~= "" then
    task.wait(1)
    print("[SlowHub] Auto-equipping saved weapon:", _G.SlowHub.SelectedWeapon)
    EquipSelectedTool()
end

print("[SlowHub] Weapon System loaded successfully!")
