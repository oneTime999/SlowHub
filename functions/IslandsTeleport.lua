local Tab = _G.TeleportsTab
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local Locations = {
    ["Starter Island"]   = Vector3.new(-87.4421615600586, -2.2058396339416504, -239.1389923095703),
    ["Jungle Island"]    = Vector3.new(-446.5873107910156, -3.560742139816284, 368.79754638671875),
    ["Desert Island"]    = Vector3.new(-694.3856811523438, -2.1328823566436768, -348.5456237792969),
    ["Snow Island"]      = Vector3.new(-234.12753295898438, -1.8019909858703613, -979.563720703125),
    ["Sailor Island"]    = Vector3.new(235.1376190185547, 3.1064343452453613, 659.7340698242188),
    ["Shibuya Station"]  = Vector3.new(1359.4720458984375, 10.515644073486328, 249.58221435546875),
    ["Hueco Mundo"]      = Vector3.new(-482.868896484375, -2.0586609840393066, 936.237060546875),
    ["Boss Island"]      = Vector3.new(620.2935791015625, -1.5378512144088745, -1055.6527099609375),
    ["Dungeon Island"]   = Vector3.new(1298, 4, -841),
    ["Shinjuku Island"]  = Vector3.new(365.327392578125, -0.6694481372833252, -1633.190673828125),
    ["Valentine Island"] = Vector3.new(-1024.6634521484375, -1.5604705810546875, -1030.836181640625),
    ["Slime Island"]     = Vector3.new(-985.4874877929688, -2.1221892833709717, 254.98291015625)
}

local LocationList = {
    "Starter Island",
    "Jungle Island",
    "Desert Island",
    "Snow Island",
    "Sailor Island",
    "Shibuya Station",
    "Hueco Mundo",
    "Boss Island",
    "Dungeon Island",
    "Shinjuku Island",
    "Valentine Island",
    "Slime Island"
}

local selectedIsland = nil

Tab:CreateDropdown({
    Name = "Select Island",
    Options = LocationList,
    CurrentOption = {""},
    MultipleOptions = false,
    Flag = "SelectIsland",
    Callback = function(Value)
        selectedIsland = (type(Value) == "table" and Value[1]) or Value
    end
})

Tab:CreateButton({
    Name = "Teleport to Island",
    Callback = function()
        if not selectedIsland or selectedIsland == "" then
            _G.Rayfield:Notify({
                Title = "Island Teleport",
                Content = "Select an island first!",
                Duration = 3,
                Image = 4483362458
            })
            return
        end

        local target = Locations[selectedIsland]
        if not target then return end

        pcall(function()
            local character = Player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if root then
                root.CFrame = CFrame.new(target)
            end
        end)
    end
})
