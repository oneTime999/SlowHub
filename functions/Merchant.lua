local Tab = _G.ShopTab
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MerchantItemsList = {
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

task.spawn(function()
    while true do
        if _G.SlowHub.AutoBuyMerchant then
            if #_G.SlowHub.SelectedMerchantItems > 0 then
                for _, itemName in pairs(_G.SlowHub.SelectedMerchantItems) do
                    if not _G.SlowHub.AutoBuyMerchant then break end
                    
                    pcall(function()
                        ReplicatedStorage.Remotes.MerchantRemotes.PurchaseMerchantItem:InvokeServer(itemName)
                    end)
                    
                    task.wait(0)
                end
            end
        end
        task.wait(0)
    end
end)

local Dropdown = Tab:CreateDropdown({
    Name = "Select Merchant Items to Buy",
    Options = MerchantItemsList,
    CurrentOption = {"Select Items"},
    MultipleOptions = true,
    Flag = "SelectMerchantItems",
    Callback = function(Value)
        _G.SlowHub.SelectedMerchantItems = Value
    end
})

local Toggle = Tab:CreateToggle({
    Name = "Auto Buy Selected Items",
    CurrentValue = false,
    Flag = "AutoBuyMerchant",
    Callback = function(Value)
        _G.SlowHub.AutoBuyMerchant = Value
        
        if Value and #_G.SlowHub.SelectedMerchantItems == 0 then
            _G.Rayfield:Notify({
                Title = "Warning",
                Content = "Select at least one item first!",
                Duration = 3,
                Image = 4483362458
            })
        end
    end
})
