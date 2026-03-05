local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tab = _G.ShopTab

_G.SlowHub.AutoBuyMerchant = _G.SlowHub.AutoBuyMerchant or false
_G.SlowHub.SelectedMerchantItems = _G.SlowHub.SelectedMerchantItems or {}
_G.SlowHub.MerchantBuyInterval = _G.SlowHub.MerchantBuyInterval or 0.5
_G.SlowHub.MerchantCycleInterval = _G.SlowHub.MerchantCycleInterval or 1

local MerchantItemsList = {
    "Rush Key",
    "Clan Reroll",
    "Race Reroll",
    "Trait Reroll",
    "Boss Key",
    "Boss Ticket",
    "Dungeon Key",
    "Haki Color Reroll",
    "Common Chest",
    "Rare Chest",
    "Epic Chest",
    "Legendary Chest",
    "Mythical Chest",
    "Secret Chest"
}

local MerchantState = {
    LoopConnection = nil,
    IsRunning = false
}

local function PurchaseItem(itemName)
    local success = pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then return end
        local merchantRemotes = remotes:FindFirstChild("MerchantRemotes")
        if not merchantRemotes then return end
        local purchaseRemote = merchantRemotes:FindFirstChild("PurchaseMerchantItem")
        if not purchaseRemote then return end
        purchaseRemote:InvokeServer(itemName)
    end)
    return success
end

local function MerchantLoop()
    if not _G.SlowHub.AutoBuyMerchant then
        StopMerchantLoop()
        return
    end
    if #_G.SlowHub.SelectedMerchantItems == 0 then
        StopMerchantLoop()
        return
    end
    for _, itemName in ipairs(_G.SlowHub.SelectedMerchantItems) do
        if not _G.SlowHub.AutoBuyMerchant then break end
        PurchaseItem(itemName)
        task.wait(_G.SlowHub.MerchantBuyInterval)
    end
    task.wait(_G.SlowHub.MerchantCycleInterval)
end

local function StopMerchantLoop()
    MerchantState.IsRunning = false
    if MerchantState.LoopConnection then
        MerchantState.LoopConnection = nil
    end
    _G.SlowHub.AutoBuyMerchant = false
end

local function StartMerchantLoop()
    if MerchantState.IsRunning then return end
    if #_G.SlowHub.SelectedMerchantItems == 0 then return end
    MerchantState.IsRunning = true
    _G.SlowHub.AutoBuyMerchant = true
    MerchantState.LoopConnection = task.spawn(function()
        while MerchantState.IsRunning and _G.SlowHub.AutoBuyMerchant do
            MerchantLoop()
        end
    end)
end

local function Notify(title, content, duration)
    duration = duration or 3
    pcall(function()
        if _G.WindUI and _G.WindUI.Notify then
            _G.WindUI:Notify({
                Title = title,
                Content = content,
                Duration = duration,
                Icon = "rbxassetid://4483362458"
            })
        end
    end)
end

Tab:Section({Title = "Merchant"})

Tab:Dropdown({
    Title = "Select Merchant Items to Buy",
    Values = MerchantItemsList,
    Multi = true,
    Default = _G.SlowHub.SelectedMerchantItems,
    Callback = function(Value)
        _G.SlowHub.SelectedMerchantItems = {}
        if type(Value) == "table" then
            for _, item in ipairs(Value) do
                table.insert(_G.SlowHub.SelectedMerchantItems, item)
            end
        end
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

Tab:Slider({
    Title = "Buy Interval",
    Step = 0.1,
    Value = {
        Min = 0.1,
        Max = 2,
        Default = _G.SlowHub.MerchantBuyInterval,
    },
    Callback = function(Value)
        _G.SlowHub.MerchantBuyInterval = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

Tab:Slider({
    Title = "Cycle Interval",
    Step = 0.5,
    Value = {
        Min = 0.5,
        Max = 5,
        Default = _G.SlowHub.MerchantCycleInterval,
    },
    Callback = function(Value)
        _G.SlowHub.MerchantCycleInterval = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

Tab:Toggle({
    Title = "Auto Buy Selected Items",
    Default = _G.SlowHub.AutoBuyMerchant or false,
    Callback = function(Value)
        _G.SlowHub.AutoBuyMerchant = Value
        if Value then
            if #_G.SlowHub.SelectedMerchantItems == 0 then
                Notify("Warning", "Select at least one item first!", 3)
                _G.SlowHub.AutoBuyMerchant = false
                return
            end
            StartMerchantLoop()
        else
            StopMerchantLoop()
        end
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})
