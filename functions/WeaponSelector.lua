local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.SelectedWeapon = nil
_G.SlowHub.EquipLoop = false
_G.SlowHub.EquipInterval = _G.SlowHub.EquipInterval or 0.25

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
if saved["SelectedWeapon"] ~= nil then _G.SlowHub.SelectedWeapon = saved["SelectedWeapon"] end
if saved["EquipInterval"] ~= nil then _G.SlowHub.EquipInterval = saved["EquipInterval"] end

local WeaponState = {
    Character=nil, Humanoid=nil, Backpack=nil, EquipLoopConnection=nil,
}

local function InitializeWeaponState()
    WeaponState.Character = Player.Character
    WeaponState.Humanoid = WeaponState.Character and WeaponState.Character:FindFirstChildOfClass("Humanoid")
    WeaponState.Backpack = Player:FindFirstChild("Backpack")
end

InitializeWeaponState()

Player.CharacterAdded:Connect(function(char)
    WeaponState.Character = char
    WeaponState.Humanoid = nil
    WeaponState.Backpack = nil
    task.wait(0.1)
    WeaponState.Humanoid = char:FindFirstChildOfClass("Humanoid")
    WeaponState.Backpack = Player:FindFirstChild("Backpack")
    task.wait(0.9)
    if _G.SlowHub.EquipLoop and _G.SlowHub.SelectedWeapon then
        EquipSelectedTool()
    end
end)

local function GetWeapons()
    local weapons = {}
    local added = {}
    pcall(function()
        if not WeaponState.Backpack then
            WeaponState.Backpack = Player:WaitForChild("Backpack")
        end
        for _, item in ipairs(WeaponState.Backpack:GetChildren()) do
            if item:IsA("Tool") and not added[item.Name] then
                added[item.Name] = true
                table.insert(weapons, item.Name)
            end
        end
        if WeaponState.Character then
            for _, item in ipairs(WeaponState.Character:GetChildren()) do
                if item:IsA("Tool") and not added[item.Name] then
                    added[item.Name] = true
                    table.insert(weapons, item.Name)
                end
            end
        end
    end)
    if #weapons == 0 then return {"No weapons found"} end
    return weapons
end

function EquipSelectedTool()
    local weaponName = _G.SlowHub.SelectedWeapon
    if not weaponName or weaponName == "" or weaponName == "No weapons found" then return false end
    return pcall(function()
        if not WeaponState.Character or not WeaponState.Humanoid then return end
        if WeaponState.Humanoid.Health <= 0 then return end
        if WeaponState.Character:FindFirstChild(weaponName) then return end
        if not WeaponState.Backpack then return end
        local tool = WeaponState.Backpack:FindFirstChild(weaponName)
        if tool and tool:IsA("Tool") then WeaponState.Humanoid:EquipTool(tool) end
    end)
end

local function StartEquipLoop()
    if _G.SlowHub.EquipLoop then return end
    _G.SlowHub.EquipLoop = true
    WeaponState.EquipLoopConnection = task.spawn(function()
        while _G.SlowHub.EquipLoop do
            EquipSelectedTool()
            task.wait(_G.SlowHub.EquipInterval)
        end
    end)
end

local function StopEquipLoop()
    _G.SlowHub.EquipLoop = false
    WeaponState.EquipLoopConnection = nil
end

local MainTab = _G.MainTab

MainTab:Section({ Title = "Weapon" })

local WeaponDropdown = MainTab:Dropdown({
    Title = "Select Weapon", Flag = "SelectWeapon",
    Values = GetWeapons(),
    Default = _G.SlowHub.SelectedWeapon or "",
    Multi = false,
    Callback = function(value)
        local weapon = type(value) == "table" and value[1] or value
        if weapon and weapon ~= "" and weapon ~= "No weapons found" then
            _G.SlowHub.SelectedWeapon = weapon
            saveConfig("SelectedWeapon", weapon)
            EquipSelectedTool()
        else
            _G.SlowHub.SelectedWeapon = nil
            saveConfig("SelectedWeapon", nil)
        end
    end,
})

MainTab:Button({
    Title = "Refresh Weapons",
    Callback = function()
        local newWeapons = GetWeapons()
        WeaponDropdown:Refresh(newWeapons)
    end,
})

MainTab:Toggle({
    Title = "Loop Equip Tool", Flag = "LoopEquipTool",
    Default = false,
    Callback = function(state)
        if state then StartEquipLoop() else StopEquipLoop() end
    end,
})

MainTab:Slider({
    Title = "Equip Interval", Flag = "EquipInterval",
    Value = { Min = 0.1, Max = 1, Default = _G.SlowHub.EquipInterval },
    Step = 0.05,
    Callback = function(value)
        _G.SlowHub.EquipInterval = value
        saveConfig("EquipInterval", value)
    end,
})
