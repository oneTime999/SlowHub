local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer

local SCRIPT_ID = "33714296afe58acfdbf28f4c6e3a6837"

_G.script_key = nil

local configFolder = "SlowHub"
local keyFile = configFolder .. "/key.txt"

if not isfolder(configFolder) then
    makefolder(configFolder)
end

local function SaveKey(key)
    pcall(function()
        writefile(keyFile, key)
    end)
end

local function LoadSavedKey()
    if isfile(keyFile) then
        local success, key = pcall(function()
            return readfile(keyFile)
        end)
        if success and key and #key == 32 then
            return key
        end
    end
    return nil
end

local function DeleteSavedKey()
    pcall(function()
        if isfile(keyFile) then
            delfile(keyFile)
        end
    end)
end

local function CheckKey(key)
    if not key or #key ~= 32 then
        return {
            code = "KEY_INVALID",
            message = "Key must be 32 characters long"
        }
    end
    
    local success, api = pcall(function()
        return loadstring(game:HttpGet("https://sdkapi-public.luarmor.net/library.lua"))()
    end)
    
    if not success then
        return {
            code = "ERROR",
            message = "Failed to load LuaRmor library"
        }
    end
    
    api.script_id = SCRIPT_ID
    
    local status = api.check_key(key)
    return status
end

local AuthWindow = nil

local function CreateAuthWindow()
    AuthWindow = Fluent:CreateWindow({
        Title = "Slow Hub - Authentication",
        SubTitle = "Enter your key to continue",
        TabWidth = 160,
        Size = UDim2.fromOffset(500, 350),
        Acrylic = false,
        Theme = "Darker",
        MinimizeKey = Enum.KeyCode.LeftControl
    })
    
    local AuthTab = AuthWindow:AddTab({ Title = "Login", Icon = "key" })
    
    AuthTab:AddParagraph({
        Title = "Welcome to Slow Hub!",
        Content = "Please enter your key below to access the script.\n\nDon't have a key? Contact our Discord server."
    })
    
    local enteredKey = ""
    local isAuthenticating = false
    
    local KeyInput = AuthTab:AddInput("KeyInput", {
        Title = "Enter Key",
        Placeholder = "Paste your 32-character key here",
        Callback = function(Value)
            enteredKey = Value
        end
    })
    
    local StatusLabel = AuthTab:AddParagraph({
        Title = "Status",
        Content = "Waiting for key..."
    })
    
    local function UpdateStatus(title, content)
        StatusLabel.Title = title
        StatusLabel.Content = content
    end
    
    AuthTab:AddButton({
        Title = "Verify Key",
        Callback = function()
            if isAuthenticating then
                return
            end
            
            if not enteredKey or enteredKey == "" then
                UpdateStatus("❌ Error", "Please enter a key first!")
                return
            end
            
            isAuthenticating = true
            UpdateStatus("⏳ Checking...", "Validating your key with LuaRmor...")
            
            task.spawn(function()
                local status = CheckKey(enteredKey)
                
                if status.code == "KEY_VALID" then
                    UpdateStatus("✅ Success!", "Key is valid! Loading Slow Hub...")
                    
                    SaveKey(enteredKey)
                    _G.script_key = enteredKey
                    
                    task.wait(1.5)
                    
                    AuthWindow:Destroy()
                    AuthWindow = nil
                    
                    task.wait(0.5)
                    
                    pcall(LoadMainHub)
                    
                elseif status.code == "KEY_HWID_LOCKED" then
                    UpdateStatus("⚠️ HWID Locked", "This key is linked to another device.\nUse /resethwid in Discord bot to reset.")
                    isAuthenticating = false
                    
                elseif status.code == "KEY_EXPIRED" then
                    UpdateStatus("❌ Expired", "Your key has expired.\nContact support to renew.")
                    DeleteSavedKey()
                    isAuthenticating = false
                    
                elseif status.code == "KEY_BANNED" then
                    UpdateStatus("❌ Banned", "This key has been blacklisted.\nContact support for details.")
                    DeleteSavedKey()
                    isAuthenticating = false
                    
                elseif status.code == "KEY_INCORRECT" then
                    UpdateStatus("❌ Invalid Key", "Key does not exist or has been deleted.")
                    isAuthenticating = false
                    
                else
                    UpdateStatus("❌ Error", "An error occurred: " .. (status.message or "Unknown error"))
                    isAuthenticating = false
                end
            end)
        end
    })
    
    AuthTab:AddButton({
        Title = "Clear Saved Key",
        Callback = function()
            DeleteSavedKey()
            UpdateStatus("🗑️ Cleared", "Saved key has been deleted.")
        end
    })
    
    AuthTab:AddParagraph({
        Title = "Need Help?",
        Content = "Join our Discord server for support:\ndiscord.gg/slowhub"
    })
end

function LoadMainHub()
    if not _G.script_key then
        return
    end

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
        SelectedWeapon = nil
    }

    local configFile = configFolder .. "/config.json"

    local function SaveConfig()
        pcall(function()
            local data = {
                AutoFarmLevel = _G.SlowHub.AutoFarmLevel,
                AutoFarmBosses = _G.SlowHub.AutoFarmBosses,
                AutoHaki = _G.SlowHub.AutoHaki,
                AntiAFK = _G.SlowHub.AntiAFK,
                AutoSkill = _G.SlowHub.AutoSkill,
                AutoObservation = _G.SlowHub.AutoObservation
            }
            
            local json = HttpService:JSONEncode(data)
            writefile(configFile, json)
        end)
    end

    local function LoadConfig()
        if not isfile(configFile) then
            return
        end
        
        pcall(function()
            local json = readfile(configFile)
            local data = HttpService:JSONDecode(json)
            
            _G.SlowHub.AutoFarmLevel = data.AutoFarmLevel or false
            _G.SlowHub.AutoFarmBosses = data.AutoFarmBosses or false
            _G.SlowHub.AutoHaki = data.AutoHaki or false
            _G.SlowHub.AntiAFK = data.AntiAFK or false
            _G.SlowHub.AutoSkill = data.AutoSkill or false
            _G.SlowHub.AutoObservation = data.AutoObservation or false
        end)
    end

    _G.SaveConfig = SaveConfig
    LoadConfig()

    local Window = Fluent:CreateWindow({
        Title = "Slow Hub",
        SubTitle = "by oneTime and Vagner",
        TabWidth = 160,
        Size = UDim2.fromOffset(580, 460),
        Acrylic = false,
        Theme = "Darker",
        MinimizeKey = Enum.KeyCode.LeftControl
    })

    pcall(function()
        task.wait(0.5)
        for _, gui in pairs(game:GetService("CoreGui"):GetChildren()) do
            if gui.Name == "ScreenGui" then
                local mainFrame = gui:FindFirstChild("Frame")
                if mainFrame then
                    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
                    
                    for _, obj in pairs(mainFrame:GetDescendants()) do
                        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                            if obj.Name:find("Tab") or obj.Parent and obj.Parent.Name:find("Tab") then
                                obj.TextSize = 16
                                obj.Font = Enum.Font.GothamBold
                            end
                        end
                    end
                end
            end
        end
    end)

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

    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/main.lua"))()
    end)
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/bosses.lua"))()
    end)
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/shop.lua"))()
    end)
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/stats.lua"))()
    end)
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/misc.lua"))()
    end)

    task.spawn(function()
        while task.wait(30) do
            SaveConfig()
        end
    end)

    task.spawn(function()
        local GUI = game:GetService("CoreGui"):WaitForChild("ScreenGui", 10)
        if GUI then
            game:GetService("RunService").Heartbeat:Connect(function()
                if not GUI.Parent then
                    SaveConfig()
                end
            end)
        end
    end)

    Fluent:Notify({
        Title = "Slow Hub",
        Content = "Successfully loaded!",
        Duration = 5
    })
end

local savedKey = LoadSavedKey()

if savedKey then
    local status = CheckKey(savedKey)
    
    if status.code == "KEY_VALID" then
        _G.script_key = savedKey
        task.wait(0.5)
        pcall(LoadMainHub)
    else
        DeleteSavedKey()
        CreateAuthWindow()
    end
else
    CreateAuthWindow()
end
