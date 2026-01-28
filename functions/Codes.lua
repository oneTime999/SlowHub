local Tab = _G.MiscTab
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Lista de códigos atualizada baseada no decompiled script
local codes = {
    "UPDATE2",
    "DUNGEONS",
    "20KMEMBERS",
    "DELAYSORRY",
    "2MVISITS",
    "15KLIKES",
    "5KCCU",
    "SORRYFORBUGS",
    "3MVISITS"
}

local function redeemAllCodes()
    for _, code in ipairs(codes) do
        pcall(function()
            -- InvokeServer geralmente requer que o evento exista exatamente neste caminho
            ReplicatedStorage.RemoteEvents.CodeRedeem:InvokeServer(code)
        end)
        task.wait(0.5) -- Usei task.wait pois é mais otimizado que o wait antigo
    end
end

local Button = Tab:CreateButton({
    Name = "Redeem All Codes",
    Callback = function()
        redeemAllCodes()
    end
})
