local Tab = _G.MiscTab
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local codes = {
    "TRAITS",
    "10KMEMBERS",
    "UPDATE1",
    "ARTIFACTS",
    "5KLIKES",
    "DELAYSORRY"
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
