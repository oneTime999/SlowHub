local Tab = _G.TeleportsTab
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Player = Players.LocalPlayer

-- Todos os NPCs em ordem alfabética (A-Z) com posições atualizadas
local npcs = {
    ["AlucardBuyer"] = Vector3.new(476.08, 2.80, 1037.77),
    ["AnosBossSummonerNPC"] = Vector3.new(901.43, 1.46, 1293.14),
    ["AnosBuyerNPC"] = Vector3.new(974.96, 74.83, 1511.13),
    ["AnosQuestNPC"] = Vector3.new(727.66, -1.80, 1273.06),
    ["AizenMovesetNPC"] = Vector3.new(-346.13, 12.99, 1402.10),
    ["AizenQuestlineBuff"] = Vector3.new(-892.01, 24.72, 1229.99),
    ["ArtifactsUnlocker"] = Vector3.new(-440.52, 1.78, -1095.86),
    ["ArtifactMilestoneNPC"] = Vector3.new(-423.72, 1.78, -1102.57),
    ["AscendNPC"] = Vector3.new(252.08, 4.09, 715.55),
    ["AtomicBossSummonerNPC"] = Vector3.new(127.93, 2.82, 1879.56),
    ["AtomicBuyer"] = Vector3.new(-176.39, 3.82, 1973.67),
    ["AtomicQuestlineBuff"] = Vector3.new(216.53, -5.36, 2126.92),
    ["BabylonCraftNPC"] = Vector3.new(599.17, 68.68, -1235.86),
    ["BlessedMaidenBuyerNPC"] = Vector3.new(909.36, 8.82, -1188.56),
    ["BlessedMaidenMasteryNPC"] = Vector3.new(940.17, 5.63, -1066.05),
    ["BossRushMerchantNPC"] = Vector3.new(108.38, 6.27, 853.75),
    ["BossRushPortalNPC"] = Vector3.new(106.73, 6.27, 840.04),
    ["BossRushShopNPC"] = Vector3.new(104.72, 6.27, 826.29),
    ["CoinFruitDealer"] = Vector3.new(408.24, 2.83, 802.73),
    ["ConquerorHakiNPC"] = Vector3.new(1942.72, 144.41, -24.46),
    ["CidBuyer"] = Vector3.new(1428.23, 49.22, -976.90),
    ["Cupid"] = Vector3.new(-1060.62, -2.16, -1074.12),
    ["DarkBladeNPC"] = Vector3.new(-132.85, 13.23, -1091.40),
    ["DungeonMerchantNPC"] = Vector3.new(1376.68, 2.11, -889.24),
    ["DungeonPortalsNPC"] = Vector3.new(1426.24, 2.20, -929.14),
    ["EnchantNPC"] = Vector3.new(1402.03, 8.84, 8.62),
    ["ExchangeNPC"] = Vector3.new(732.77, -4.51, -921.04),
    ["GemFruitDealer"] = Vector3.new(400.64, 2.80, 752.18),
    ["GilgameshBuyerNPC"] = Vector3.new(842.49, 64.86, -1002.42),
    ["GojoCraftNPC"] = Vector3.new(-122.01, 1.88, -2094.94),
    ["GojoMasteryNPC"] = Vector3.new(55.53, 39.05, -2066.49),
    ["GojoMovesetNPC"] = Vector3.new(1741.59, 157.30, 514.81),
    ["GrailCraftNPC"] = Vector3.new(606.02, 69.08, -1242.59),
    ["GryphonBuyerNPC"] = Vector3.new(1430.04, 8.88, 277.78),
    ["GroupRewardNPC"] = Vector3.new(-30.99, -3.46, -300.31),
    ["HakiQuestNPC"] = Vector3.new(-498.10, 23.66, -1252.51),
    ["HogyokuQuestNPC"] = Vector3.new(-379.57, 8.73, 1529.38),
    ["IchigoBuyer"] = Vector3.new(-792.50, 5.41, 1019.47),
    ["InfiniteTowerMerchantNPC"] = Vector3.new(1355.99, 0.38, -1456.91),
    ["InfiniteTowerPortalNPC"] = Vector3.new(1344.87, 1.28, -1469.63),
    ["InfiniteTowerStatShopNPC"] = Vector3.new(1336.16, 1.13, -1482.81),
    ["JinwooMovesetNPC"] = Vector3.new(91.23, 2.98, 1097.47),
    ["Katana"] = Vector3.new(106.70, 10.04, -270.52),
    ["MadokaBuyer"] = Vector3.new(146.03, 29.32, -394.60),
    ["MerchantNPC"] = Vector3.new(368.82, 2.80, 783.59),
    ["ObservationBuyer"] = Vector3.new(-713.18, 12.13, -527.29),
    ["QuestNPC1"] = Vector3.new(171.33, 16.31, -214.43),
    ["QuestNPC10"] = Vector3.new(1604.27, 8.84, 429.71),
    ["QuestNPC11"] = Vector3.new(-285.65, -3.37, 1038.72),
    ["QuestNPC12"] = Vector3.new(626.48, 1.88, -1609.55),
    ["QuestNPC13"] = Vector3.new(-19.76, 1.88, -1985.25),
    ["QuestNPC14"] = Vector3.new(-1187.44, 17.90, 338.49),
    ["QuestNPC15"] = Vector3.new(1028.09, 1.46, 1241.73),
    ["QuestNPC16"] = Vector3.new(-1164.99, 2.50, -1189.88),
    ["QuestNPC17"] = Vector3.new(-1408.26, 1603.09, 1642.24),
    ["QuestNPC18"] = Vector3.new(-1786.67, 6.99, -744.57),
    ["QuestNPC19"] = Vector3.new(67.02, -1.14, 1758.81),
    ["QuestNPC2"] = Vector3.new(-7.02, -2.58, -202.54),
    ["QuestNPC3"] = Vector3.new(-519.39, -1.64, 434.31),
    ["QuestNPC4"] = Vector3.new(-467.07, 18.80, 480.44),
    ["QuestNPC5"] = Vector3.new(-687.97, -2.43, -460.26),
    ["QuestNPC6"] = Vector3.new(-863.06, -4.22, -385.56),
    ["QuestNPC7"] = Vector3.new(-388.64, -1.67, -945.01),
    ["QuestNPC8"] = Vector3.new(-550.74, 22.42, -1025.71),
    ["QuestNPC9"] = Vector3.new(1419.06, 8.84, 372.59),
    ["RagnaBuyer"] = Vector3.new(-277.50, 46.63, -1345.33),
    ["RagnaQuestlineBuff"] = Vector3.new(-272.07, -4.24, -1353.34),
    ["RerollStatNPC"] = Vector3.new(373.07, 2.80, 810.10),
    ["RimuruBuyer"] = Vector3.new(-1539.57, 3.65, 66.11),
    ["RimuruMasteryNPC"] = Vector3.new(-1324.74, 15.42, 527.84),
    ["RimuruSummonerNPC"] = Vector3.new(-1235.08, 16.61, 279.55),
    ["SaberAlterBuyerNPC"] = Vector3.new(860.97, 59.97, -1013.69),
    ["SaberAlterMasteryNPC"] = Vector3.new(694.44, 1.54, -1226.83),
    ["ShadowMonarchBuyerNPC"] = Vector3.new(1463.05, 48.96, -901.41),
    ["ShadowMonarchQuestlineBuff"] = Vector3.new(243.94, 26.62, -83.21),
    ["ShadowQuestlineBuff"] = Vector3.new(335.12, 25.51, -377.07),
    ["SkillTreeNPC"] = Vector3.new(-1141.41, 6.34, 212.08),
    ["SlimeCraftNPC"] = Vector3.new(-1167.46, 2.76, 173.57),
    ["SpecPassivesNPC"] = Vector3.new(-1102.29, 5.70, -1238.47),
    ["StorageNPC"] = Vector3.new(329.95, 2.95, 764.06),
    ["StrongestBossSummonerNPC"] = Vector3.new(392.87, -2.23, -2177.80),
    ["StrongestinHistoryBuyerNPC"] = Vector3.new(756.40, 89.15, -1952.94),
    ["StrongestofTodayBuyerNPC"] = Vector3.new(94.53, 149.00, -2638.10),
    ["StrongestShinobiBuyerNPC"] = Vector3.new(-1774.65, 6.33, -383.27),
    ["StrongestShinobiMasteryNPC"] = Vector3.new(-1980.03, 25.20, -373.86),
    ["SukunaCraftNPC"] = Vector3.new(697.82, 1.88, -2042.35),
    ["SukunaMasteryNPC"] = Vector3.new(598.32, 30.15, -2054.80),
    ["SukunaMovesetNPC"] = Vector3.new(1325.80, 162.86, -34.68),
    ["SummonBossNPC"] = Vector3.new(651.81, -3.67, -1021.13),
    ["TitlesNPC"] = Vector3.new(364.23, 2.80, 755.99),
    ["TraitNPC"] = Vector3.new(337.28, 2.80, 813.85),
    ["TrueAizenBossSummonerNPC"] = Vector3.new(-1283.03, 1603.62, 1751.08),
    ["TrueAizenBuyerNPC"] = Vector3.new(-1461.34, 1603.62, 1854.75),
    ["TrueAizenFUnlockNPC"] = Vector3.new(-1220.62, 1692.36, 1864.38),
    ["ValentineMerchantNPC"] = Vector3.new(-1116.44, -3.24, -996.19),
    ["YamatoBuyerNPC"] = Vector3.new(-1287.45, 91.79, -998.27),
    ["YujiBuyerNPC"] = Vector3.new(1240.19, 136.70, 408.19),
}

-- Gera lista ordenada alfabeticamente para o Dropdown
local npcList = {}
for name in pairs(npcs) do table.insert(npcList, name) end
table.sort(npcList)

-- Variáveis do Tween
local currentTween = nil
local lastTweenTarget = nil
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

local function cancelTween()
    if currentTween then
        currentTween:Cancel()
        currentTween = nil
    end
end

-- Sistema de Tween para movimento suave até o NPC
local function moveToTarget(targetPosition)
    if not humanoidRootPart then
        humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return false end
    end

    local currentSpeed = _G.SlowHub.TeleportTweenSpeed or 500
    local distance = (humanoidRootPart.Position - targetPosition).Magnitude

    -- Se já está perto, teleporta direto
    if distance <= 5 then
        cancelTween()
        humanoidRootPart.CFrame = CFrame.new(targetPosition)
        return true
    end

    -- Se o alvo mudou, cancela tween anterior
    if lastTweenTarget then
        local posDiff = (lastTweenTarget - targetPosition).Magnitude
        if posDiff > 1 then
            cancelTween()
        elseif currentTween and currentTween.PlaybackState == Enum.PlaybackState.Playing then
            return false
        end
    end

    lastTweenTarget = targetPosition
    if currentSpeed <= 0 then currentSpeed = 500 end
    local timeToReach = distance / currentSpeed
    local tweenInfo = TweenInfo.new(timeToReach, Enum.EasingStyle.Linear)

    cancelTween()
    currentTween = TweenService:Create(humanoidRootPart, tweenInfo, {CFrame = CFrame.new(targetPosition)})
    currentTween:Play()

    return false
end

Tab:Section({Title = "NPC Teleport"})

Tab:Dropdown({
    Title = "Select NPC (Alphabetical)",
    Flag = "SelectNPCTeleport",
    Values = npcList,
    Multi = false,
    Value = _G.SlowHub.SelectedNPC or npcList[1],
    Callback = function(value)
        local selected = type(value) == "table" and value[1] or value
        _G.SlowHub.SelectedNPC = selected
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})

-- Slider de velocidade do Tween
Tab:Slider({
    Title = "Tween Speed",
    Flag = "TeleportTweenSpeed",
    Step = 10,
    Value = {
        Min = 10,
        Max = 150,
        Default = _G.SlowHub.TeleportTweenSpeed or 150,
    },
    Callback = function(Value)
        _G.SlowHub.TeleportTweenSpeed = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
        cancelTween()
    end,
})

Tab:Button({
    Title = "Teleport to NPC (Tween)",
    Callback = function()
        local targetNPC = _G.SlowHub.SelectedNPC
        if not targetNPC or targetNPC == "" then return end
        local targetPosition = npcs[targetNPC]
        if not targetPosition then return end
        
        pcall(function()
            moveToTarget(targetPosition)
        end)
    end,
})
