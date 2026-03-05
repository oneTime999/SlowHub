local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.AutoBuyMerchant = _G.SlowHub.AutoBuyMerchant or false
_G.SlowHub.SelectedMerchantItems = _G.SlowHub.SelectedMerchantItems or {}
_G.SlowHub.MerchantBuyInterval = _G.SlowHub.MerchantBuyInterval or 0.5
_G.SlowHub.MerchantCycleInterval = _G.SlowHub.MerchantCycleInterval or 1

local CONFIG_FOLDER = "SlowHub"
local CONFIG_FILE = CONFIG_FOLDER .. "/config.json"

local function ensureFolder()
    if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
end

local function loadConfig()
    ensureFolder()
    if isfile(CONFIG_FILE) then
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_FILE)) end)
        if ok and type(data) == "table" then return data end
    end
    return {}
end

local function saveConfig(key, value)
    ensureFolder()
    local current = loadConfig()
    current[key] = value
    pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(current)) end)
end

local saved = loadConfig()
local merchantFlags = {"AutoBuyMerchant","SelectedMerchantItems","MerchantBuyInterval","MerchantCycleInterval"}
for _, flag in ipairs(merchantFlags) do
    if saved[flag] ~= nil then _G.SlowHub[flag] = saved[flag] end
end

local MerchantItemsList = {
    "Rush Key","Clan Reroll","Race Reroll","Trait Reroll","Boss Key","Boss Ticket",
    "Dungeon Key","Haki Color Reroll","Common Chest","Rare Chest","Epic Chest",
    "Legendary Chest","Mythical Chest","Secret Chest",
}

local MerchantState = {LoopConnection=nil, IsRunning=false}

local function PurchaseItem(itemName)
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

function StopMerchantLoop()
    MerchantState.IsRunning = false
    if MerchantState.LoopConnection then
        MerchantState.LoopConnection = nil
    end
    _G.SlowHub.AutoBuyMerchant = false
end

function StartMerchantLoop()
    if MerchantState.IsRunning then return end
    if #_G.SlowHub.SelectedMerchantItems == 0 then return end
    MerchantState.IsRunning = true
    _G.SlowHub.AutoBuyMerchant = true
    MerchantState.LoopConnection = task.spawn(function()
        while MerchantState.IsRunning and _G.SlowHub.AutoBuyMerchant do
            if #_G.SlowHub.SelectedMerchantItems == 0 then StopMerchantLoop(); break end
            for _, itemName in ipairs(_G.SlowHub.SelectedMerchantItems) do
                if not _G.SlowHub.AutoBuyMerchant then break end
                PurchaseItem(itemName)
                task.wait(_G.SlowHub.MerchantBuyInterval)
            end
            task.wait(_G.SlowHub.MerchantCycleInterval)
        end
    end)
end

local ShopTab = _G.ShopTab

ShopTab:CreateSection({ Title = "Merchant" })

ShopTab:CreateDropdown({
    Name = "Select Merchant Items to Buy", Flag = "SelectMerchantItems",
    Options = MerchantItemsList, CurrentOption = _G.SlowHub.SelectedMerchantItems,
    MultipleOptions = true,
    Callback = function(value)
        _G.SlowHub.SelectedMerchantItems = {}
        if type(value) == "table" then
            for _, item in ipairs(value) do table.insert(_G.SlowHub.SelectedMerchantItems, item) end
        end
        saveConfig("SelectedMerchantItems", _G.SlowHub.SelectedMerchantItems)
    end,
})

ShopTab:CreateSlider({
    Name = "Buy Interval", Flag = "MerchantBuyInterval",
    Range = { 0.1, 2 }, Increment = 0.1,
    CurrentValue = _G.SlowHub.MerchantBuyInterval,
    Callback = function(value)
        _G.SlowHub.MerchantBuyInterval = value
        saveConfig("MerchantBuyInterval", value)
    end,
})

ShopTab:CreateSlider({
    Name = "Cycle Interval", Flag = "MerchantCycleInterval",
    Range = { 0.5, 5 }, Increment = 0.5,
    CurrentValue = _G.SlowHub.MerchantCycleInterval,
    Callback = function(value)
        _G.SlowHub.MerchantCycleInterval = value
        saveConfig("MerchantCycleInterval", value)
    end,
})

ShopTab:CreateToggle({
    Name = "Auto Buy Selected Items", Flag = "AutoBuyMerchant",
    CurrentValue = _G.SlowHub.AutoBuyMerchant,
    Callback = function(value)
        _G.SlowHub.AutoBuyMerchant = value
        saveConfig("AutoBuyMerchant", value)
        if value then
            StartMerchantLoop()
        else
            StopMerchantLoop()
        end
    end,
})
