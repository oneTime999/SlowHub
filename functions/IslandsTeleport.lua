local Tab = _G.TeleportsTab
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local locations = {
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

local locationList = {}
for name in pairs(locations) do table.insert(locationList, name) end
table.sort(locationList)

local character = nil
local humanoidRootPart = nil

local function initialize()
    character = Player.Character
    humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
end

initialize()

Player.CharacterAdded:Connect(function(char)
    character = char
    task.wait(0.1)
    humanoidRootPart = char:FindFirstChild("HumanoidRootPart")
end)

local function teleportToPosition(position)
    if not humanoidRootPart then
        humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return false end
    end
    humanoidRootPart.CFrame = CFrame.new(position)
    return true
end

Tab:Section({Title = "Island Teleport"})

Tab:Dropdown({
    Title = "Select Island",
    Flag = "SelectIsland",
    Values = locationList,
    Multi = false,
    Value = _G.SlowHub.SelectedIsland or locationList[1],
    Callback = function(value)
        local selected = type(value) == "table" and value[1] or value
        _G.SlowHub.SelectedIsland = selected
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})

Tab:Button({
    Title = "Teleport to Island",
    Callback = function()
        local targetIsland = _G.SlowHub.SelectedIsland
        if not targetIsland or targetIsland == "" then return end
        local targetPosition = locations[targetIsland]
        if not targetPosition then return end
        pcall(function() teleportToPosition(targetPosition) end)
    end,
})
