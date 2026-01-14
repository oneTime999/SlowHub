LRM_INIT_SCRIPT(function()
    local api = loadstring(game:HttpGet("https://sdkapi-public.luarmor.net/library.lua"))()
    api.script_id = "33714296afe58acfdbf28f4c6e3a6837"

    local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    local configFolder = "SlowHub"
    local keyFile = configFolder .. "/key.txt"
    local authenticated = false
    local finalKey = ""

    if not isfolder(configFolder) then makefolder(configFolder) end

    local function SaveKey(key) pcall(function() writefile(keyFile, key) end) end
    
    local function LoadSavedKey() 
        if isfile(keyFile) then
            local success, key = pcall(function() return readfile(keyFile) end)
            if success and key and #key == 32 then return key end
        end 
        return nil 
    end
    
    local function DeleteSavedKey() pcall(function() if isfile(keyFile) then delfile(keyFile) end end) end

    local function CreateAuthWindow()
        local Window = Fluent:CreateWindow({
            Title = "Slow Hub", SubTitle = "Key System", TabWidth = 160, Size = UDim2.fromOffset(500, 350),
            Acrylic = true, Theme = "Darker", MinimizeKey = Enum.KeyCode.K
        })
        
        local Tab = Window:AddTab({ Title = "Auth", Icon = "key" })
        local enteredKey = ""
        
        Tab:AddInput("KeyInput", {
            Title = "License Key", Placeholder = "Enter 32 character key...", TextDisappear = false,
            Callback = function(Text) enteredKey = Text end
        })
        
        local StatusParagraph = Tab:AddParagraph({
            Title = "Status",
            Content = "Waiting for input..."
        })
        
        Tab:AddButton({
            Title = "Verify Key", Callback = function()
                if #enteredKey ~= 32 then 
                    Fluent:Notify({Title = "Error", Content = "Key must be 32 characters long", Duration = 3})
                    return 
                end
                
                StatusParagraph:SetDesc("Checking key...")
                
                local status = api.check_key(enteredKey)
                
                if status.code == "KEY_VALID" then
                    SaveKey(enteredKey)
                    finalKey = enteredKey
                    StatusParagraph:SetDesc("Authenticated! Loading...")
                    Fluent:Notify({Title = "Success", Content = "Authenticated! Loading...", Duration = 3})
                    task.wait(1.5)
                    Window:Destroy()
                    authenticated = true
                elseif status.code == "KEY_HWID_LOCKED" then
                     Fluent:Notify({Title = "Error", Content = "HWID Mismatch (Reset needed)", Duration = 5})
                     StatusParagraph:SetDesc("Error: HWID Mismatch")
                elseif status.code == "KEY_EXPIRED" then
                     Fluent:Notify({Title = "Error", Content = "Key Expired", Duration = 5})
                     StatusParagraph:SetDesc("Error: Expired")
                else
                    Fluent:Notify({Title = "Error", Content = "Invalid Key", Duration = 3})
                    StatusParagraph:SetDesc("Error: Invalid Key")
                end
            end
        })
    end

    local savedKey = LoadSavedKey()
    if savedKey then
        local status = api.check_key(savedKey)
        if status.code == "KEY_VALID" then
            finalKey = savedKey
            authenticated = true
        else
            DeleteSavedKey()
            CreateAuthWindow()
        end
    else
        CreateAuthWindow()
    end

    while not authenticated do
        task.wait()
    end

    script_key = finalKey
end)

local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

_G.SlowHub = {
    AutoFarmLevel = false,
    AutoFarmBosses = false,
    AutoSummon = false,
    AutoFarmMiniBosses = false,
    AutoFarmSelectedMob = false,
    AutoSkill = false,
    AutoChest = false,
    AutoHaki = false,
    AutoObservation = false,
    Codes = false,
    Shop = false,
    NPC = false,
    Stats = false,
    AntiAFK = false,
    SelectedWeapon = nil,
    Theme = "Darker"
}

local configFolder = "SlowHub"
local configFile = configFolder .. "/config.json"

if not isfolder(configFolder) then makefolder(configFolder) end

local function SaveConfig()
    pcall(function()
        local data = {
            AutoFarmLevel = _G.SlowHub.AutoFarmLevel,
            AutoFarmBosses = _G.SlowHub.AutoFarmBosses,
            AutoHaki = _G.SlowHub.AutoHaki,
            AntiAFK = _G.SlowHub.AntiAFK,
            AutoSkill = _G.SlowHub.AutoSkill,
            AutoObservation = _G.SlowHub.AutoObservation,
            AutoSummon = _G.SlowHub.AutoSummon,
            AutoFarmMiniBosses = _G.SlowHub.AutoFarmMiniBosses,
            AutoChest = _G.SlowHub.AutoChest,
            Theme = _G.SlowHub.Theme
        }
        writefile(configFile, HttpService:JSONEncode(data))
    end)
end

local function LoadConfig()
    if not isfile(configFile) then return end
    pcall(function()
        local data = HttpService:JSONDecode(readfile(configFile))
        _G.SlowHub.AutoFarmLevel = data.AutoFarmLevel or false
        _G.SlowHub.AutoFarmBosses = data.AutoFarmBosses or false
        _G.SlowHub.AutoHaki = data.AutoHaki or false
        _G.SlowHub.AntiAFK = data.AntiAFK or false
        _G.SlowHub.AutoSkill = data.AutoSkill or false
        _G.SlowHub.AutoObservation = data.AutoObservation or false
        _G.SlowHub.AutoSummon = data.AutoSummon or false
        _G.SlowHub.AutoFarmMiniBosses = data.AutoFarmMiniBosses or false
        _G.SlowHub.AutoChest = data.AutoChest or false
        _G.SlowHub.Theme = data.Theme or "Darker"
    end)
end

_G.SaveConfig = SaveConfig
LoadConfig()

local Window = Fluent:CreateWindow({
    Title = "Slow Hub", 
    SubTitle = "v1.0", 
    TabWidth = 160, 
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = _G.SlowHub.Theme, 
    MinimizeKey = Enum.KeyCode.K
})

_G.SlowHub.Window = Window

local function CreateMobileUI()
    local ScreenGui = Instance.new("ScreenGui")
    local ImageButton = Instance.new("ImageButton")
    local UICorner = Instance.new("UICorner")

    ScreenGui.Name = "SlowHubMobileButton"
    
    if pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end) then
    else ScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end

    ImageButton.Parent = ScreenGui
    ImageButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    ImageButton.BackgroundTransparency = 0.5 
    ImageButton.Position = UDim2.new(0.9, -60, 0.4, 0)
    ImageButton.Size = UDim2.new(0, 50, 0, 50)
    ImageButton.Image = "rbxassetid://116746146580891"
    ImageButton.Draggable = true
    ImageButton.Active = true

    UICorner.CornerRadius = UDim.new(1, 0)
    UICorner.Parent = ImageButton

    ImageButton.MouseButton1Click:Connect(function()
        if Window then
            Window:Minimize()
        end
    end)
end

if UserInputService.TouchEnabled then
    CreateMobileUI()
end

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Bosses = Window:AddTab({ Title = "Bosses", Icon = "skull" }),
    Shop = Window:AddTab({ Title = "Shop", Icon = "shopping-cart" }),
    Stats = Window:AddTab({ Title = "Stats", Icon = "bar-chart" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "settings" })
}

_G.MainTab = Tabs.Main
_G.BossesTab = Tabs.Bosses
_G.ShopTab = Tabs.Shop
_G.StatsTab = Tabs.Stats
_G.MiscTab = Tabs.Misc
_G.Fluent = Fluent
_G.Options = Fluent.Options

local tabsToLoad = {
    "https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/main.lua",
    "https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/bosses.lua",
    "https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/shop.lua",
    "https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/stats.lua",
    "https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/misc.lua"
}

for _, url in ipairs(tabsToLoad) do
    task.spawn(function()
        pcall(loadstring(game:HttpGet(url)))
    end)
end

local SettingsTab = Window:AddTab({ Title = "Settings", Icon = "settings" })
_G.SettingsTab = SettingsTab

SettingsTab:AddDropdown("Theme", {
    Title = "Select Theme",
    Values = {"Dark", "Darker", "Light", "Aqua", "Amethyst", "Rose"},
    Default = _G.SlowHub.Theme,
    Callback = function(Value)
        Fluent:SetTheme(Value)
        _G.SlowHub.Theme = Value
        SaveConfig()
    end
})

task.spawn(function()
    while task.wait(30) do
        SaveConfig()
    end
end)

Fluent:Notify({Title = "Slow Hub", Content = "Loaded successfully!", Duration = 5})
