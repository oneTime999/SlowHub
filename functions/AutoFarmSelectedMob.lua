local Tab = _G.MainTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local MobList = {
    "Thief", "Monkey", "DesertBandit", "FrostRogue", "Sorcerer"
}

if not _G.SlowHub.AutoFarmSelectedMob then
    _G.SlowHub.AutoFarmSelectedMob = false
end

if not _G.SlowHub.SelectedMob then
    _G.SlowHub.SelectedMob = "Thief"
end

if not _G.SlowHub.FarmDistance then
    _G.SlowHub.FarmDistance = 8
end

if not _G.SlowHub.FarmHeight then
    _G.SlowHub.FarmHeight = 4
end

local autoFarmSelectedConnection = nil
local currentSelectedNPCIndex = 1

local function getSelectedNPC(npcName, index)
    return workspace.NPCs:FindFirstChild(npcName .. index)
end

local function getSelectedNPCRootPart(npc)
    if npc and npc:FindFirstChild("HumanoidRootPart") then
        return npc.HumanoidRootPart
    end
    return nil
end

local function getNextSelectedNPC(current)
    local next = current + 1
    if next > 5 then
        return 1
    end
    return next
end

local function EquipWeapon()
    if not _G.SlowHub.SelectedWeapon then return false end
    
    local success, result = pcall(function()
        local backpack = Player:FindFirstChild("Backpack")
        local character = Player.Character
        
        if not character or not character:FindFirstChild("Humanoid") then
            return false
        end
        
        if character:FindFirstChild(_G.SlowHub.SelectedWeapon) then
            return true
        end
        
        if backpack then
            local weapon = backpack:FindFirstChild(_G.SlowHub.SelectedWeapon)
            if weapon then
                character.Humanoid:EquipTool(weapon)
                task.wait(0.1)
                return true
            end
        end
        return false
    end)
    
    return success and result
end

local function stopAutoFarmSelectedMob()
    if autoFarmSelectedConnection then
        autoFarmSelectedConnection:Disconnect()
        autoFarmSelectedConnection = nil
    end
    _G.SlowHub.AutoFarmSelectedMob = false
    currentSelectedNPCIndex = 1
    
    spawn(function()
        task.wait(0.1)
        if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
            Player.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end
    end)
end

local function startAutoFarmSelectedMob()
    stopAutoFarmSelectedMob()
    
    _G.SlowHub.AutoFarmSelectedMob = true
    currentSelectedNPCIndex = 1
    
    spawn(function()
        EquipWeapon()
    end)
    
    autoFarmSelectedConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoFarmSelectedMob then
            stopAutoFarmSelectedMob()
            return
        end
        
        if not Player.Character or not Player.Character:FindFirstChild("HumanoidRootPart") then
            return
        end
        
        local character = Player.Character
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then
            return
        end
        
        local selectedMob = _G.SlowHub.SelectedMob
        local npc = getSelectedNPC(selectedMob, currentSelectedNPCIndex)
        
        if npc and npc.Parent then
            local npcHumanoid = npc:FindFirstChild("Humanoid")
            if npcHumanoid and npcHumanoid.Health <= 0 then
                currentSelectedNPCIndex = getNextSelectedNPC(currentSelectedNPCIndex)
                return
            end
            
            local npcRoot = getSelectedNPCRootPart(npc)
            if npcRoot then
                local playerRoot = character.HumanoidRootPart
                
                spawn(function()
                    EquipWeapon()
                end)
                
                local targetCFrame = npcRoot.CFrame
                local offsetPosition = targetCFrame * CFrame.new(0, _G.SlowHub.FarmHeight, _G.SlowHub.FarmDistance)
                
                local distance = (playerRoot.Position - offsetPosition.Position).Magnitude
                if distance > 3 then
                    playerRoot.CFrame = offsetPosition
                end
                
                if math.random() > 0.6 then
                    pcall(function()
                        ReplicatedStorage.CombatSystem.Remotes.RequestHit:FireServer()
                    end)
                end
            end
        else
            currentSelectedNPCIndex = getNextSelectedNPC(currentSelectedNPCIndex)
        end
    end)
end

Tab:CreateToggle({
    Name = "Auto Farm Selected Mob",
    CurrentValue = _G.SlowHub.AutoFarmSelectedMob,
    Flag = "AutoFarmSelectedMobToggle",
    Callback = function(Value)
        _G.SlowHub.AutoFarmSelectedMob = Value
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                _G.Rayfield:Notify({
                    Title = "Slow Hub",
                    Content = "Select a weapon first!",
                    Duration = 5,
                    Image = 105026320884681
                })
                _G.SlowHub.AutoFarmSelectedMob = false
                return
            end
            if not _G.SlowHub.SelectedMob then
                _G.SlowHub.SelectedMob = "Thief"
            end
            _G.Rayfield:Notify({
                Title = "Slow Hub",
                Content = "Farming: " .. _G.SlowHub.SelectedMob,
                Duration = 4,
                Image = 105026320884681
            })
            task.spawn(startAutoFarmSelectedMob)
        else
            stopAutoFarmSelectedMob()
            _G.Rayfield:Notify({
                Title = "Slow Hub",
                Content = "Auto Farm Selected Mob stopped",
                Duration = 2,
                Image = 105026320884681
            })
        end
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

Tab:CreateDropdown({
    Name = "Selected Mob",
    Options = MobList,
    CurrentOption = _G.SlowHub.SelectedMob or "Thief",
    MultipleOptions = false,
    Flag = "SelectedMobDropdown",
    Callback = function(Option)
        _G.SlowHub.SelectedMob = Option
        currentSelectedNPCIndex = 1
        _G.Rayfield:Notify({
            Title = "Slow Hub",
            Content = "Mob selected: " .. Option,
            Duration = 2,
            Image = 109860946741884
        })
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})

Tab:CreateSlider({
    Name = "Farm Distance",
    Range = {1, 10},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = _G.SlowHub.FarmDistance,
    Flag = "FarmDistanceSlider",
    Callback = function(Value)
        _G.SlowHub.FarmDistance = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
        _G.Rayfield:Notify({
            Title = "Slow Hub",
            Content = "Distance: " .. Value .. " studs",
            Duration = 2,
            Image = 109860946741884
        })
    end,
})

Tab:CreateSlider({
    Name = "Farm Height",
    Range = {1, 10},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = _G.SlowHub.FarmHeight,
    Flag = "FarmHeightSlider",
    Callback = function(Value)
        _G.SlowHub.FarmHeight = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
        _G.Rayfield:Notify({
            Title = "Slow Hub",
            Content = "Height: " .. Value .. " studs",
            Duration = 2,
            Image = 109860946741884
        })
    end,
})

if _G.SlowHub.AutoFarmSelectedMob and _G.SlowHub.SelectedWeapon then
    task.spawn(startAutoFarmSelectedMob)
end
