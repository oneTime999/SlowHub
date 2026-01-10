local Tab = _G.MiscTab
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local codes = {
    "RELEASE",
    "UPDATE0.5",
    "TRAITS",
    "NEWYEAR",
    "CHRISTMAS",
    "3000CCU",
    "3KLIKES",
    "4KLIKES",
    "10KMEMBERS",
    "UPDATE1",
    "ARTIFACTS",
    "5KLIKES",
    "DELAYSORRY",
    "500KVISITS"
}

local function redeemAllCodes()
    for _, code in ipairs(codes) do
        pcall(function()
            ReplicatedStorage.RemoteEvents.CodeRedeem:InvokeServer(code)
        end)
        wait(0.5)
    end
end

Tab:CreateButton({
    Name = "Redeem All Codes",
    Callback = function()
        redeemAllCodes()
    end
})
