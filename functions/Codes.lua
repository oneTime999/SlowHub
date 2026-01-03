local Tab = _G.MiscTab
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local codes = {
    "RELEASE",
    "UPDATE0.5",
    "TRAITS",
    "NEWYEAR",
    "CHRISTMAS",
    "200KVISITS",
    "3000CCU",
    "3KLIKES",
    "QUESTBUGFIXSORRY",
    "4KLIKES"
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
