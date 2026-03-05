local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.SelectedIsland = _G.SlowHub.SelectedIsland or nil

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
if saved["SelectedIsland"] ~= nil then _G.SlowHub.SelectedIsland = saved["SelectedIsland"] end

local Locations = {
    ["Starter Island"]=Vector3.new(-87.4421615600586,-2.2058396339416504,-239.1389923095703),
    ["Jungle Island"]=Vector3.new(-446.5873107910156,-3.560742139816284,368.79754638671875),
    ["Desert Island"]=Vector3.new(-694.3856811523438,-2.1328823566436768,-348.5456237792969),
    ["Snow Island"]=Vector3.new(-234.12753295898438,-1.8019909858703613,-979.563720703125),
    ["Sailor Island"]=Vector3.new(235.1376190185547,3.1064343452453613,659.7340698242188),
    ["Shibuya Station"]=Vector3.new(1359.4720458984375,10.515644073486328,249.58221435546875),
    ["Hueco Mundo"]=Vector3.new(-482.868896484375,-2.0586609840393066,936.237060546875),
    ["Boss Island"]=Vector3.new(620.2935791015625,-1.5378512144088745,-1055.6527099609375),
    ["Dungeon Island"]=Vector3.new(1298,4,-841),
    ["Shinjuku Island"]=Vector3.new(365.327392578125,-0.6694481372833252,-1633.190673828125),
    ["Slime Island"]=Vector3.new(-985.4874877929688,-2.1221892833709717,254.98291015625),
    ["Academy Island"]=Vector3.new(1040.2939453125,-2.0211944580078125,1088.76904296875),
}

local LocationList = {}
for name in pairs(Locations) do table.insert(LocationList, name) end
table.sort(LocationList)

local TeleportState = {Character=nil, HumanoidRootPart=nil}

local function InitializeTeleportState()
    TeleportState.Character = Player.Character
    TeleportState.HumanoidRootPart = TeleportState.Character and TeleportState.Character:FindFirstChild("HumanoidRootPart")
end

InitializeTeleportState()

Player.CharacterAdded:Connect(function(char)
    TeleportState.Character = char
    task.wait(0.1)
    TeleportState.HumanoidRootPart = char:FindFirstChild("HumanoidRootPart")
end)

local function TeleportToPosition(position)
    if not TeleportState.HumanoidRootPart then
        TeleportState.HumanoidRootPart = TeleportState.Character and TeleportState.Character:FindFirstChild("HumanoidRootPart")
        if not TeleportState.HumanoidRootPart then return false end
    end
    TeleportState.HumanoidRootPart.CFrame = CFrame.new(position)
    return true
end

local TeleportsTab = _G.TeleportsTab

TeleportsTab:CreateSection({ Title = "Island Teleport" })

TeleportsTab:CreateDropdown({
    Name = "Select Island", Flag = "SelectIsland",
    Options = LocationList,
    CurrentOption = _G.SlowHub.SelectedIsland or LocationList[1],
    MultipleOptions = false,
    Callback = function(value)
        local selected = type(value) == "table" and value[1] or value
        _G.SlowHub.SelectedIsland = selected
        saveConfig("SelectedIsland", selected)
    end,
})

TeleportsTab:CreateButton({
    Name = "Teleport to Island",
    Callback = function()
        local targetIsland = _G.SlowHub.SelectedIsland
        if not targetIsland or targetIsland == "" then return end
        local targetPosition = Locations[targetIsland]
        if not targetPosition then return end
        pcall(function() TeleportToPosition(targetPosition) end)
    end,
})
