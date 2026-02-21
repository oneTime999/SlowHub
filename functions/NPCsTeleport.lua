local Tab = _G.TeleportsTab
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local NPCs = {
    ["SummonBossNPC"]              = Vector3.new(651.8101806640625, -3.6741936206817627, -1021.1312255859375),
    ["ExchangeNPC"]                = Vector3.new(732.7742309570312, -4.511749267578125, -921.0400390625),
    ["HakiQuestNPC"]               = Vector3.new(-497.9392395019531, 23.657915115356445, -1252.6405029296875),
    ["EnchantNPC"]                 = Vector3.new(1402.0318603515625, 8.840030670166016, 8.6171073913574),
    ["TitlesNPC"]                  = Vector3.new(364.2301025390625, 2.799835681915283, 755.9888305664062),
    ["GemFruitDealer"]             = Vector3.new(400.6419372558594, 2.799835205078125, 752.1758422851562),
    ["CoinFruitDealer"]            = Vector3.new(408.24456787109375, 2.8298196792602539, 802.734130859375),
    ["TraitNPC"]                   = Vector3.new(337.2843017578125, 2.799835205078125, 813.8465576171875),
    ["MerchantNPC"]                = Vector3.new(368.8177185058594, 2.799835205078125, 783.58984375),
    ["RerollStatNPC"]              = Vector3.new(373.0717468261719, 2.799835205078125, 810.0983276367188),
    ["StorageNPC"]                 = Vector3.new(329.9494934082031, 2.9452056884765625, 764.059326171875),
    ["AlucardBuyer"]               = Vector3.new(476.0772399902344, 2.799835205078125, 1037.7681884765625),
    ["AscendNPC"]                  = Vector3.new(252.08216857910156, 4.089679241180420, 715.5545654296875),
    ["GroupRewardNPC"]             = Vector3.new(-30.986343383789062, -3.461075782775879, -300.314697265625),
    ["Katana"]                     = Vector3.new(106.69941711425781, 10.036863327026367, -270.5188293457031),
    ["DarkBladeNPC"]               = Vector3.new(-132.51644897460938, 14.76722240447998, -1091.2698974609375),
    ["ObservationBuyer"]           = Vector3.new(-713.1829223632812, 12.133977890014648, -527.289794921875),
    ["ArtifactsUnlocker"]          = Vector3.new(-440.51638793945312, 1.7797914743423462, -1095.8607177734375),
    ["ArtifactMilestoneNPC"]       = Vector3.new(-423.71615600585938, 1.7797914743423462, -1102.5701904296875),
    ["RagnaBuyer"]                 = Vector3.new(-277.49841308593750, 46.627536773681640, -1345.3275146484375),
    ["RagnaQuestlineBuff"]         = Vector3.new(-272.07086181640625, -4.235350131988525, -1353.3377685546875),
    ["BlessingNPC"]                = Vector3.new(1420.9478759765625, 8.840031623840332, 11.212580680847168),
    ["DungeonPortalsNPC"]          = Vector3.new(1426.2393798828125, 2.202561378479004, -929.140380859375),
    ["DungeonMerchantNPC"]         = Vector3.new(1376.6802978515625, 2.107670307159424, -889.2369995117188),
    ["CidBuyer"]                   = Vector3.new(1428.2298583984375, 49.22114562988281, -976.904296875),
    ["ShadowQuestlineBuff"]        = Vector3.new(335.12347412109375, 25.505559921264648, -377.073486328125),
    ["QinShiBuyer"]                = Vector3.new(760.7242431640625, 14.598579406738281, -1266.1395263671875),
    ["AizenQuestlineBuff"]         = Vector3.new(-892.0050659179688, 24.720260620117188, 1229.994140625),
    ["AizenMovesetNPC"]            = Vector3.new(-346.1345520019531, 12.991233825683594, 1402.10009765625),
    ["IchigoBuyer"]                = Vector3.new(-792.5028076171875, 5.405630111694336, 1019.4747924804688),
    ["YujiBuyerNPC"]               = Vector3.new(1240.19626953125, 136.70077514648438, 408.1883544921875),
    ["ConquerorHakiNPC"]           = Vector3.new(1942.717529296875, 144.406005859375, -24.579298019409180),
    ["JinwooMovesetNPC"]           = Vector3.new(91.22600555419922, 2.984231710433960, 1097.46630859375),
    ["GojoCraftNPC"]               = Vector3.new(-122.00872802734375, 1.8821269273757935, -2094.937255859375),
    ["GojoMasteryNPC"]             = Vector3.new(55.52754211425781, 39.04626464843750, -2066.4926757812500),
    ["GojoMovesetNPC"]             = Vector3.new(1741.5926513671875, 157.30050659179688, 514.8050537109375),
    ["SukunaCraftNPC"]             = Vector3.new(697.8233642578125, 1.882115244865417, -2042.352783203125),
    ["SukunaMasteryNPC"]           = Vector3.new(598.3160400390625, 30.15283203125, -2054.802978515625),
    ["SukunaMovesetNPC"]           = Vector3.new(1325.801025390625, 162.859649658203125, -34.6844749450683),
    ["StrongestofTodayBuyerNPC"]   = Vector3.new(94.52934265136719, 148.99818420410156, -2638.101318359375),
    ["StrongestinHistoryBuyerNPC"] = Vector3.new(756.39794921875, 89.146316528320310, -1952.936279296875),
    ["StrongestBossSummonerNPC"]   = Vector3.new(392.8700256347656, -2.2286527156829834, -2177.801513671875),
    ["BabylonCraftNPC"]            = Vector3.new(599.1744384765625, 68.6766357421875, -1235.864990234375),
    ["GrailCraftNPC"]              = Vector3.new(606.0234985351562, 69.0794906616211, -1242.5926513671875),
    ["GilgameshBuyerNPC"]          = Vector3.new(842.4886474609375, 64.8641128540039, -1002.4154052734375),
    ["RimuruBuyer"]                = Vector3.new(-1539.5665283203125, 3.647789239883423, 66.1064453125),
    ["RimuruMasteryNPC"]           = Vector3.new(-1324.7435302734375, 15.418346405029297, 527.8409423828125),
    ["RimuruSummonerNPC"]          = Vector3.new(-1235.082763671875, 16.613021850585938, 279.5498352050781),
    ["MadokaBuyer"]                = Vector3.new(-1149.3486328125, -4.610758304595947, -1395.1700439453125),
    ["Cupid"]                      = Vector3.new(-1060.621826171875, -2.1614086627960205, -1074.1229248046875),
    ["ValentineMerchantNPC"]       = Vector3.new(-1116.442626953125, -3.235420703887939, -996.1893310546875),
    ["SlimeCraftNPC"]              = Vector3.new(-1167.4620361328125, 2.755218029022217, 173.57208251953125),
    ["SkillTreeNPC"]               = Vector3.new(-1141.411376953125, 6.342375755310059, 212.076324462890620),
}

local NPCList = {
    "SummonBossNPC",
    "ExchangeNPC",
    "HakiQuestNPC",
    "EnchantNPC",
    "TitlesNPC",
    "GemFruitDealer",
    "CoinFruitDealer",
    "TraitNPC",
    "MerchantNPC",
    "RerollStatNPC",
    "StorageNPC",
    "AlucardBuyer",
    "AscendNPC",
    "GroupRewardNPC",
    "Katana",
    "DarkBladeNPC",
    "ObservationBuyer",
    "ArtifactsUnlocker",
    "ArtifactMilestoneNPC",
    "RagnaBuyer",
    "RagnaQuestlineBuff",
    "BlessingNPC",
    "DungeonPortalsNPC",
    "DungeonMerchantNPC",
    "CidBuyer",
    "ShadowQuestlineBuff",
    "QinShiBuyer",
    "AizenQuestlineBuff",
    "AizenMovesetNPC",
    "IchigoBuyer",
    "YujiBuyerNPC",
    "ConquerorHakiNPC",
    "JinwooMovesetNPC",
    "GojoCraftNPC",
    "GojoMasteryNPC",
    "GojoMovesetNPC",
    "SukunaCraftNPC",
    "SukunaMasteryNPC",
    "SukunaMovesetNPC",
    "StrongestofTodayBuyerNPC",
    "StrongestinHistoryBuyerNPC",
    "StrongestBossSummonerNPC",
    "BabylonCraftNPC",
    "GrailCraftNPC",
    "GilgameshBuyerNPC",
    "RimuruBuyer",
    "RimuruMasteryNPC",
    "RimuruSummonerNPC",
    "MadokaBuyer",
    "Cupid",
    "ValentineMerchantNPC",
    "SlimeCraftNPC",
    "SkillTreeNPC",
}

local selectedNPC = nil

Tab:CreateSection("NPC Teleport")

Tab:CreateDropdown({
    Name = "Select NPC",
    Options = NPCList,
    CurrentOption = {""},
    MultipleOptions = false,
    Flag = "SelectNPCTeleport",
    Callback = function(Value)
        selectedNPC = (type(Value) == "table" and Value[1]) or Value
    end
})

Tab:CreateButton({
    Name = "Teleport to NPC",
    Callback = function()
        if not selectedNPC or selectedNPC == "" then
            _G.Rayfield:Notify({
                Title = "NPC Teleport",
                Content = "Select an NPC first!",
                Duration = 3,
                Image = 4483362458
            })
            return
        end

        local target = NPCs[selectedNPC]
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
