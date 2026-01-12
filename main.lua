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
            message = "Failed to load library"
        }
    end
    
    api.script_id = SCRIPT_ID
    
    local status = api.check_key(key)
    return status
end

local function CreateAuthWindow()
    local AuthWindow = Fluent:CreateWindow({
        Title = "Slow Hub - Authentication",
        SubTitle = "Enter your key",
        TabWidth = 160,
        Size = UDim2.fromOffset(500, 350),
        Acrylic = false,
        Theme = "Darker",
        MinimizeKey = Enum.KeyCode.LeftControl
    })
    
    local AuthTab = AuthWindow:AddTab({ Title = "Key", Icon = "key" })
    
    local enteredKey = ""
    local isAuthenticating = false
    
    local KeyInput = AuthTab:AddInput("KeyInput", {
        Title = "Key",
        Placeholder = "Enter 32-character key",
        Callback = function(Value)
            enteredKey = Value
        end
    })
    
    AuthTab:AddButton({
        Title = "Verify",
        Callback = function()
            if isAuthenticating then
                return
            end
            
            if not enteredKey or enteredKey == "" then
                return
            end
            
            isAuthenticating = true
            
            task.spawn(function()
                local status = CheckKey(enteredKey)
                
                if status.code == "KEY_VALID" then
                    SaveKey(enteredKey)
                    _G.script_key = enteredKey
                    
                    task.wait(2)
                    
                    AuthWindow:Destroy()
                    
                    task.wait(0.5)
                    
                    pcall(LoadMainHub)
                    
                end
                isAuthenticating = false
            end)
        end
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
