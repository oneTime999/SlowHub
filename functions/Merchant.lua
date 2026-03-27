local Tab = _G.ShopTab
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ORDENAÇÃO ALFABÉTICA AUTOMÁTICA (A-Z)
local merchantItemsList = {
    "Boss Key",
    "Boss Ticket",
    "Clan Reroll",
    "Common Chest",
    "Dungeon Key",
    "Epic Chest",
    "Haki Color Reroll",
    "Legendary Chest",
    "Mythical Chest",
    "Race Reroll",
    "Rare Chest",
    "Rush Key",
    "Secret Chest",
    "Trait Reroll",
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
            if not _G.SlowHub.SelectedMerchantItems or #_G.SlowHub.SelectedMerchantItems == 0 then 
                stopMerchantLoop(); 
                break 
            end
            -- Compra todos os itens selecionados na velocidade máxima (sem delay)
            for _, itemName in ipairs(_G.SlowHub.SelectedMerchantItems) do
                if not _G.SlowHub.AutoBuyMerchant then break end
                purchaseItem(itemName)
                -- REMOVIDO: task.wait() - compra instantânea
            end
            -- REMOVIDO: task.wait() entre ciclos - loop infinito rápido
        end
    end)
end

Tab:Section({Title = "Merchant"})

-- ORDEM ALFABÉTICA: Boss Key -> Boss Ticket -> Clan Reroll -> Common Chest -> Dungeon Key -> Epic Chest -> Haki Color Reroll -> Legendary Chest -> Mythical Chest -> Race Reroll -> Rare Chest -> Rush Key -> Secret Chest -> Trait Reroll
Tab:Dropdown({
    Title = "Select Merchant Items to Buy",
    Flag = "SelectMerchantItems",
    Values = merchantItemsList, -- Já ordenado alfabeticamente
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

-- REMOVIDO: Slider de Buy Interval
-- REMOVIDO: Slider de Cycle Interval

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
