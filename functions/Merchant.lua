local Tab = _G.ShopTab
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MerchantItemsList = {
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

_G.SlowHub.AutoBuyMerchant = false
_G.SlowHub.SelectedMerchantItems = {}

local merchantLoopRunning = false

local function startMerchantLoop()
    if merchantLoopRunning then return end
    merchantLoopRunning = true

    task.spawn(function()
        while merchantLoopRunning and _G.SlowHub.AutoBuyMerchant do
            if #_G.SlowHub.SelectedMerchantItems > 0 then
                for _, itemName in pairs(_G.SlowHub.SelectedMerchantItems) do
                    if not _G.SlowHub.AutoBuyMerchant then break end
                    pcall(function()
                        ReplicatedStorage.Remotes.MerchantRemotes.PurchaseMerchantItem:InvokeServer(itemName)
                    end)
                    task.wait(0.5) -- Throttle entre cada compra
                end
            end
            task.wait(1) -- Delay entre cada ciclo completo
        end
        merchantLoopRunning = false
    end)
end

local function stopMerchantLoop()
    merchantLoopRunning = false
    _G.SlowHub.AutoBuyMerchant = false
end

Tab:CreateDropdown({
    Name = "Select Merchant Items to Buy",
    Options = MerchantItemsList,
    CurrentOption = {"Select Items"},
    MultipleOptions = true,
    Flag = "SelectMerchantItems",
    Callback = function(Value)
        _G.SlowHub.SelectedMerchantItems = Value
    end
})

Tab:CreateToggle({
    Name = "Auto Buy Selected Items",
    CurrentValue = false,
    Flag = "AutoBuyMerchant",
    Callback = function(Value)
        _G.SlowHub.AutoBuyMerchant = Value

        if Value then
            if #_G.SlowHub.SelectedMerchantItems == 0 then
                _G.Rayfield:Notify({
                    Title = "Warning",
                    Content = "Select at least one item first!",
                    Duration = 3,
                    Image = 4483362458
                })
                _G.SlowHub.AutoBuyMerchant = false
                return
            end
            startMerchantLoop()
        else
            stopMerchantLoop()
        end
    end
})
