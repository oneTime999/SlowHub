local Tab = _G.ShopTab
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local NPCs = {
    ["EnchantNPC"] = function() return workspace.ServiceNPCs:FindFirstChild("EnchantNPC") end,
    ["ExchangeNPC"] = function() return workspace.ServiceNPCs:FindFirstChild("ExchangeNPC") end,
    ["GroupRewardNPC"] = function() return workspace.ServiceNPCs:FindFirstChild("GroupRewardNPC") end,
    ["HakiQuestNPC"] = function() return workspace.ServiceNPCs:FindFirstChild("HakiQuestNPC") end,
    ["StorageNPC"] = function() return workspace.ServiceNPCs:FindFirstChild("StorageNPC") end,
    ["SummonBossNPC"] = function() return workspace.ServiceNPCs:FindFirstChild("SummonBossNPC") end,
    ["TitlesNPC"] = function() return workspace.ServiceNPCs:FindFirstChild("TitlesNPC") end,
    ["TraitNPC"] = function() return workspace.ServiceNPCs:FindFirstChild("TraitNPC") end,
    ["ObservationBuyer"] = function() return workspace.ServiceNPCs:FindFirstChild("ObservationBuyer") end
}

_G.SlowHub.SelectedNPC = _G.SlowHub.SelectedNPC or "EnchantNPC"

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
        local selectedNPC = _G.SlowHub.SelectedNPC
        
        if not selectedNPC or selectedNPC == "" then
            return
        end
        
        local getNPC = NPCs[selectedNPC]
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
    Name = "Select NPC",
    Options = {
        "EnchantNPC", 
        "ExchangeNPC", 
        "GroupRewardNPC", 
        "HakiQuestNPC", 
        "StorageNPC", 
        "SummonBossNPC",
        "TitlesNPC", 
        "TraitNPC",
        "ObservationBuyer"
    },
    CurrentOption = {_G.SlowHub.SelectedNPC},
    Flag = "NPCDropdown",
    Callback = function(Option)
        pcall(function()
            _G.SlowHub.SelectedNPC = normalizeValue(Option)
        end)
    end
})

Tab:CreateButton({
    Name = "Teleport to NPC",
    Callback = function()
        teleportToNPC()
    end,
})
