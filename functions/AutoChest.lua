local Tab = _G.MainTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local ChestConfig = {
    ["Common Chest"] = "Common Chest",
    ["Rare Chest"] = "Rare Chest", 
    ["Epic Chest"] = "Epic Chest",
    ["Legendary Chest"] = "Legendary Chest",
    ["Mythical Chest"] = "Mythical Chest"
}

local chestList = {"Common Chest", "Rare Chest", "Epic Chest", "Legendary Chest", "Mythical Chest"}

local autoChestConnection = nil
local selectedChest = "Common Chest"
local isChestRunning = false
local AutoChest = false  -- ✅ Variável AutoChest

local CHEST_DELAY = 0.5

local function stopAutoChest()
    isChestRunning = false
    AutoChest = false  -- ✅ Usa AutoChest
    
    if autoChestConnection then
        autoChestConnection:Disconnect()
        autoChestConnection = nil
    end
end

local function startAutoChest()
    if isChestRunning then
        stopAutoChest()
        task.wait(0.3)
    end
    
    isChestRunning = true
    AutoChest = true  -- ✅ Usa AutoChest
    
    autoChestConnection = RunService.Heartbeat:Connect(function()
        if not AutoChest or not isChestRunning then  -- ✅ Usa AutoChest
            stopAutoChest()
            return
        end
        
        local chestName = ChestConfig[selectedChest]
        
        pcall(function()
            ReplicatedStorage.Remotes.UseItem:FireServer("Use", chestName, 1)
        end)
        
        task.wait(CHEST_DELAY)
    end)
end

-- DROPDOWN
Tab:CreateDropdown({
    Name = "Select Chest",
    Options = chestList,
    CurrentOption = "Common Chest",
    Flag = "SelectedChest",
    Callback = function(Option)
        if type(Option) == "table" then
            selectedChest = Option[1] or "Common Chest"
        else
            selectedChest = tostring(Option)
        end
        
        pcall(function()
            _G.Rayfield:Notify({
                Title = "Slow Hub",
                Content = "Chest: " .. selectedChest,
                Duration = 3,
                Image = 105026320884681
            })
        end)
    end
})

-- TOGGLE
Tab:CreateToggle({
    Name = "AutoChest",
    CurrentValue = AutoChest,  -- ✅ Usa AutoChest
    Flag = "AutoChestToggle",
    Callback = function(Value)
        AutoChest = Value  -- ✅ Usa AutoChest
        
        if Value then
            pcall(function()
                _G.Rayfield:Notify({
                    Title = "Slow Hub",
                    Content = "AutoChest: " .. selectedChest .. " (0.5s)",
                    Duration = 4,
                    Image = 105026320884681
                })
            end)
            startAutoChest()
        else
            stopAutoChest()
            pcall(function()
                _G.Rayfield:Notify({
                    Title = "Slow Hub",
                    Content = "AutoChest parado",
                    Duration = 2,
                    Image = 105026320884681
                })
            end)
        end
    end
})
