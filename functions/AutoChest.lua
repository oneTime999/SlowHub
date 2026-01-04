local Tab = _G.MainTab  -- Tab Misc
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

if not _G.SlowHub.ChestDelay then
    _G.SlowHub.ChestDelay = 1
end

local function stopAutoChest()
    isChestRunning = false
    
    if autoChestConnection then
        autoChestConnection:Disconnect()
        autoChestConnection = nil
    end
    
    _G.SlowHub.AutoOpenChests = false
end

local function startAutoChest()
    if isChestRunning then
        stopAutoChest()
        task.wait(0.3)
    end
    
    isChestRunning = true
    _G.SlowHub.AutoOpenChests = true
    
    autoChestConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoOpenChests or not isChestRunning then
            stopAutoChest()
            return
        end
        
        local chestName = ChestConfig[selectedChest]
        local delay = _G.SlowHub.ChestDelay or 1
        
        pcall(function()
            ReplicatedStorage.Remotes.UseItem:FireServer("Use", chestName, 1)
        end)
        
        task.wait(delay)
    end)
end

-- DROPDOWN DE CHESTS
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
                Content = "Chest selecionado: " .. selectedChest,
                Duration = 3,
                Image = 105026320884681
            })
        end)
    end
})

-- TOGGLE AUTO OPEN CHEST
Tab:CreateToggle({
    Name = "Auto Open Chests",
    CurrentValue = _G.SlowHub.AutoOpenChests or false,
    Flag = "AutoOpenChestsToggle",
    Callback = function(Value)
        if Value then
            pcall(function()
                _G.Rayfield:Notify({
                    Title = "Slow Hub",
                    Content = "Abrindo: " .. selectedChest .. " (Delay: " .. (_G.SlowHub.ChestDelay or 1) .. "s)",
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
                    Content = "Auto Chests parado",
                    Duration = 2,
                    Image = 105026320884681
                })
            end)
        end
        
        _G.SlowHub.AutoOpenChests = Value
    end
})

-- SLIDER DE DELAY
Tab:CreateSlider({
    Name = "Chest Delay",
    Range = {0.1, 5},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = _G.SlowHub.ChestDelay or 1,
    Flag = "ChestDelaySlider",
    Callback = function(Value)
        _G.SlowHub.ChestDelay = Value
        pcall(function()
            _G.Rayfield:Notify({
                Title = "Slow Hub",
                Content = "Delay: " .. Value .. "s",
                Duration = 2,
                Image = 109860946741884
            })
        end)
    end,
})
