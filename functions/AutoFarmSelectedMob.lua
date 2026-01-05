local Tab = _G.MainTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local MobList = {"Thief", "Monkey", "DesertBandit", "FrostRogue", "Sorcerer"}
local autoFarmSelectedConnection = nil
local selectedMob = "Thief"
local isRunning = false

if not _G.SlowHub.FarmDistance then
    _G.SlowHub.FarmDistance = 8
end

if not _G.SlowHub.FarmHeight then
    _G.SlowHub.FarmHeight = 4
end

local function getSelectedMobNPC()
    return workspace.NPCs:FindFirstChild(selectedMob .. currentSelectedNPCIndex) or workspace.NPCs:FindFirstChild(selectedMob .. "1")
end

local function getSelectedMobRootPart(npc)
    if npc and npc:FindFirstChild("HumanoidRootPart") then
        return npc.HumanoidRootPart
    end
    return nil
end

local currentSelectedNPCIndex = 1
local function getNextSelectedNPC()
    currentSelectedNPCIndex = currentSelectedNPCIndex + 1
    if currentSelectedNPCIndex > 5 then
        currentSelectedNPCIndex = 1
    end
end

local function EquipWeapon()
    if not _G.SlowHub.SelectedWeapon then return end
    pcall(function()
        local backpack = Player:FindFirstChild("Backpack")
        local character = Player.Character
        if not character or not character:FindFirstChild("Humanoid") then return end
        if character:FindFirstChild(_G.SlowHub.SelectedWeapon) then return end
        if backpack then
            local weapon = backpack:FindFirstChild(_G.SlowHub.SelectedWeapon)
            if weapon then
                character.Humanoid:EquipTool(weapon)
            end
        end
    end)
end

local function stopAutoFarmSelectedMob()
    isRunning = false
    if autoFarmSelectedConnection then
        autoFarmSelectedConnection:Disconnect()
        autoFarmSelectedConnection = nil
    end
    _G.SlowHub.AutoFarmSelectedMob = false
end

local function startAutoFarmSelectedMob()
    if isRunning then
        stopAutoFarmSelectedMob()
        task.wait(0.3)
    end
    
    isRunning = true
    _G.SlowHub.AutoFarmSelectedMob = true
    
    EquipWeapon()
    
    autoFarmSelectedConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoFarmSelectedMob or not isRunning then
            stopAutoFarmSelectedMob()
            return
        end
        
        local npc = getSelectedMobNPC()
        
        if npc and npc.Parent then
            local npcHumanoid = npc:FindFirstChild("Humanoid")
            if npcHumanoid and npcHumanoid.Health <= 0 then
                getNextSelectedNPC()
                task.wait(0.5)
                return
            end
            
            local npcRoot = getSelectedMobRootPart(npc)
            
            if npcRoot and npcRoot.Parent and Player.Character then
                local playerRoot = Player.Character:FindFirstChild("HumanoidRootPart")
                local humanoid = Player.Character:FindFirstChild("Humanoid")
                
                if playerRoot and humanoid and humanoid.Health > 0 then
                    pcall(function()
                        playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        
                        local targetCFrame = npcRoot.CFrame
                        local offsetPosition = targetCFrame * CFrame.new(0, _G.SlowHub.FarmHeight, _G.SlowHub.FarmDistance)
                        
                        local distance = (playerRoot.Position - offsetPosition.Position).Magnitude
                        if distance > 3 or distance < 1 then
                            playerRoot.CFrame = offsetPosition
                        end
                        
                        EquipWeapon()
                        ReplicatedStorage.CombatSystem.Remotes.RequestHit:FireServer()
                    end)
                end
            end
        else
            getNextSelectedNPC()
        end
    end)
end

Tab:CreateDropdown({
    Name = "Select Mob",
    Options = MobList,
    CurrentOption = "Thief",
    Flag = "SelectedMobDropdown",
    Callback = function(Option)
        local wasRunning = isRunning
        
        if wasRunning then
            stopAutoFarmSelectedMob()
            task.wait(0.3)
        end
        
        if type(Option) == "table" then
            selectedMob = Option[1] or "Thief"
        else
            selectedMob = tostring(Option)
        end
        currentSelectedNPCIndex = 1
        
        if wasRunning then
            startAutoFarmSelectedMob()
            pcall(function()
                _G.Rayfield:Notify({
                    Title = "Slow Hub",
                    Content = "Farming: " .. selectedMob,
                    Duration = 4,
                    Image = 105026320884681
                })
            end)
        end
    end
})

Tab:CreateToggle({
    Name = "Auto Farm Selected Mob",
    CurrentValue = false,
    Flag = "AutoFarmSelectedMobToggle",
    Callback = function(Value)
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                pcall(function()
                    _G.Rayfield:Notify({
                        Title = "Slow Hub",
                        Content = "Select a weapon first!",
                        Duration = 5,
                        Image = 105026320884681
                    })
                end)
                return
            end
            
            pcall(function()
                _G.Rayfield:Notify({
                    Title = "Slow Hub",
                    Content = "Farming: " .. selectedMob,
                    Duration = 4,
                    Image = 105026320884681
                })
            end)
            
            startAutoFarmSelectedMob()
        else
            stopAutoFarmSelectedMob()
        end
        
        _G.SlowHub.AutoFarmSelectedMob = Value
    end
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
    end,
})
