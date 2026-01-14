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
local selectedChest = nil
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
            if selectedChest then
                local chestName = ChestConfig[selectedChest]
                
                pcall(function()
                    ReplicatedStorage.Remotes.UseItem:FireServer("Use", chestName, 1)
                end)
                
                lastChestTime = currentTime
            end
        end
    end)
end

local Dropdown = Tab:AddDropdown("SelectChest", {
    Title = "Select Chest",
    Values = chestList,
    Default = nil,
    Callback = function(Value)
        selectedChest = tostring(Value)
    end
})

local Toggle = Tab:AddToggle("AutoChest", {
    Title = "Auto Chest",
    Default = false,
    Callback = function(Value)
        if Value then
            if not selectedChest then
                _G.Fluent:Notify({Title = "Error", Content = "Select a Chest first!", Duration = 3})
                if Toggle then Toggle:SetValue(false) end
                return
            end
            
            AutoChest = true
            startAutoChest()
        else
            stopAutoChest()
        end
    end
})
