local Tab = _G.ShopTab
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MerchantItemsList = {
    "Race Reroll",
    "Trait Reroll",
    "Boss Key",
    "Boss Ticket",
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
                    
                    task.wait(0.3)
                end
            end
        end
        task.wait(0.5)
    end
end)

local Dropdown = Tab:AddDropdown("SelectMerchantItems", {
    Title = "Select Merchant Items to Buy",
    Values = MerchantItemsList,
    Multi = true,
    Default = {},
    Callback = function(Value)
        local selected = {}
        for item, state in pairs(Value) do
            if state then
                table.insert(selected, item)
            end
        end
        _G.SlowHub.SelectedMerchantItems = selected
    end
})

local Toggle = Tab:AddToggle("AutoBuyMerchant", {
    Title = "Auto Buy Selected Items",
    Default = false,
    Callback = function(Value)
        _G.SlowHub.AutoBuyMerchant = Value
        
        if Value and #_G.SlowHub.SelectedMerchantItems == 0 then
            _G.Fluent:Notify({
                Title = "Warning",
                Content = "Select at least one item first!",
                Duration = 3
            })
        end
    end
})
