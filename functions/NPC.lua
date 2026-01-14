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
    ["ObservationBuyer"] = function() return workspace.ServiceNPCs:FindFirstChild("ObservationBuyer") end,
    ["ArtifactsUnlocker"] = function() return workspace.ServiceNPCs:FindFirstChild("ArtifactsUnlocker") end,
    ["ArtifactMilestoneNPC"] = function() return workspace.ServiceNPCs:FindFirstChild("ArtifactMilestoneNPC") end
}

_G.SlowHub.SelectedNPC = nil

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

local Dropdown = Tab:AddDropdown("SelectNPC", {
    Title = "Select NPC",
    Values = {
        "EnchantNPC", 
        "ExchangeNPC", 
        "GroupRewardNPC", 
        "HakiQuestNPC", 
        "StorageNPC", 
        "SummonBossNPC",
        "TitlesNPC", 
        "TraitNPC",
        "ObservationBuyer",
        "ArtifactsUnlocker",
        "ArtifactMilestoneNPC"
    },
    Default = nil,
    Callback = function(Value)
        pcall(function()
            _G.SlowHub.SelectedNPC = tostring(Value)
        end)
    end
})

local Button = Tab:AddButton({
    Title = "Teleport to NPC",
    Callback = function()
        teleportToNPC()
    end
})
