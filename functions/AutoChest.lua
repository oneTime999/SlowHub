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
local AutoChest = false
local lastChestTime = 0
local CHEST_DELAY = 0.5

local function stopAutoChest()
    isChestRunning = false
    AutoChest = false
    
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
    AutoChest = true
    lastChestTime = tick()
    
    autoChestConnection = RunService.Heartbeat:Connect(function()
        if not AutoChest or not isChestRunning then
            stopAutoChest()
            return
        end
        
        local currentTime = tick()
        if currentTime - lastChestTime >= CHEST_DELAY then
            local chestName = ChestConfig[selectedChest]
            
            pcall(function()
                ReplicatedStorage.Remotes.UseItem:FireServer("Use", chestName, 1)
            end)
            
            lastChestTime = currentTime
        end
    end)
end

local Dropdown = Tab:AddDropdown("SelectChest", {
    Title = "Select Chest",
    Values = chestList,
    Default = 1, -- Common Chest é o primeiro
    Callback = function(Value)
        selectedChest = tostring(Value)
    end
})

local Toggle = Tab:AddToggle("AutoChest", {
    Title = "Auto Chest",
    Default = AutoChest,
    Callback = function(Value)
        AutoChest = Value
        
        if Value then
            startAutoChest()
        else
            stopAutoChest()
        end
    end
})
