local Tab = _G.ShopTab
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local MeeleNPCs = {
    ["Qin Shi"] = function() return workspace:FindFirstChild("SukunaMovesetNPC") end,
    ["Sukuna"] = function() return workspace:FindFirstChild("GojoMovesetNPC") end,
    ["Gojo"] = function() return workspace.ServiceNPCs:FindFirstChild("ExchangeNPC") end
}

_G.SlowHub.SelectedMeeleNPC = _G.SlowHub.SelectedMeeleNPC or "Qin Shi"

local function normalizeValue(Value)
    if type(Value) == "table" then
        return tostring(Value[1] or "")
    end
    return tostring(Value or "")
end

local function getModelRoot(model)
    if not model then return nil end
    
    if model:IsA("Model") then
        return model:FindFirstChild("HumanoidRootPart") or 
               model:FindFirstChild("Torso") or 
               model:FindFirstChild("Head") or
               model.PrimaryPart
    end
    
    return model
end

local function teleportToNPC()
    pcall(function()
        local selectedMeele = _G.SlowHub.SelectedMeeleNPC
        
        if not selectedMeele or selectedMeele == "" then
            return
        end
        
        local getNPC = MeeleNPCs[selectedMeele]
        if not getNPC then
            return
        end
        
        local npc = getNPC()
        
        if npc and Player.Character then
            local npcRoot = getModelRoot(npc)
            local playerRoot = Player.Character:FindFirstChild("HumanoidRootPart")
            
            if npcRoot and playerRoot then
                playerRoot.CFrame = npcRoot.CFrame * CFrame.new(0, 0, 5)
            end
        end
    end)
end

Tab:CreateDropdown({
    Name = "Select Meele NPC",
    Options = {"Qin Shi", "Sukuna", "Gojo"},
    CurrentOption = {_G.SlowHub.SelectedMeeleNPC},
    Flag = "MeeleNPCDropdown",
    Callback = function(Option)
        pcall(function()
            _G.SlowHub.SelectedMeeleNPC = normalizeValue(Option)
        end)
    end
})

Tab:CreateButton({
    Name = "Teleport to NPC",
    Callback = function()
        teleportToNPC()
    end,
})
