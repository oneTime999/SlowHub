local Tab = _G.ShopTab
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local merchantItemsList = {
    "Rush Key","Clan Reroll","Race Reroll","Trait Reroll","Boss Key","Boss Ticket",
    "Dungeon Key","Haki Color Reroll","Common Chest","Rare Chest","Epic Chest",
    "Legendary Chest","Mythical Chest","Secret Chest",
}

local loopConnection = nil
local isRunning = false

local function purchaseItem(itemName)
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then return end
        local merchantRemotes = remotes:FindFirstChild("MerchantRemotes")
        if not merchantRemotes then return end
        local purchaseRemote = merchantRemotes:FindFirstChild("PurchaseMerchantItem")
        if not purchaseRemote then return end
        purchaseRemote:InvokeServer(itemName)
    end)
end

local function stopMerchantLoop()
    isRunning = false
    if loopConnection then
        loopConnection = nil
    end
    _G.SlowHub.AutoBuyMerchant = false
end

local function startMerchantLoop()
    if isRunning then return end
    if not _G.SlowHub.SelectedMerchantItems or #_G.SlowHub.SelectedMerchantItems == 0 then return end
    isRunning = true
    _G.SlowHub.AutoBuyMerchant = true
    loopConnection = task.spawn(function()
        while isRunning and _G.SlowHub.AutoBuyMerchant do
            if not _G.SlowHub.SelectedMerchantItems or #_G.SlowHub.SelectedMerchantItems == 0 then stopMerchantLoop(); break end
            for _, itemName in ipairs(_G.SlowHub.SelectedMerchantItems) do
                if not _G.SlowHub.AutoBuyMerchant then break end
                purchaseItem(itemName)
                task.wait(_G.SlowHub.MerchantBuyInterval or 0.5)
            end
            task.wait(_G.SlowHub.MerchantCycleInterval or 1)
        end
    end)
end

Tab:Section({Title = "Merchant"})

Tab:Dropdown({
    Title = "Select Merchant Items to Buy",
    Flag = "SelectMerchantItems",
    Values = merchantItemsList,
    Multi = true,
    Value = _G.SlowHub.SelectedMerchantItems or {},
    Callback = function(value)
        _G.SlowHub.SelectedMerchantItems = {}
        if type(value) == "table" then
            for _, item in ipairs(value) do table.insert(_G.SlowHub.SelectedMerchantItems, item) end
        end
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})

Tab:Slider({
    Title = "Buy Interval",
    Flag = "MerchantBuyInterval",
    Step = 0.1,
    Value = {
        Min = 0.1,
        Max = 2,
        Default = _G.SlowHub.MerchantBuyInterval or 0.5,
    },
    Callback = function(Value)
        _G.SlowHub.MerchantBuyInterval = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})

Tab:Slider({
    Title = "Cycle Interval",
    Flag = "MerchantCycleInterval",
    Step = 0.5,
    Value = {
        Min = 0.5,
        Max = 5,
        Default = _G.SlowHub.MerchantCycleInterval or 1,
    },
    Callback = function(Value)
        _G.SlowHub.MerchantCycleInterval = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})

Tab:Toggle({
    Title = "Auto Buy Selected Items",
    Value = _G.SlowHub.AutoBuyMerchant or false,
    Callback = function(Value)
        _G.SlowHub.AutoBuyMerchant = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
        if Value then
            startMerchantLoop()
        else
            stopMerchantLoop()
        end
    end,
})
