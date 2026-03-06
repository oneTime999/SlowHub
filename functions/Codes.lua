local Tab = _G.MiscTab
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local codes = {
    "35KCCUWOW","SORRYFORBUGS","BADISSUESSORRY","BOSSRUSH","VERYBIGUPDATESOON","SINOFPRIDE",
    "15KFOLLOWTY","ROGUEALLIES","RUSHKEYCODE","SORRYSUDDENRESTART",
}

local isRedeeming = false

local function redeemCode(code)
    return pcall(function()
        local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if not remoteEvents then return end
        local codeRedeem = remoteEvents:FindFirstChild("CodeRedeem")
        if not codeRedeem then return end
        codeRedeem:InvokeServer(code)
    end)
end

local function redeemAllCodes()
    if isRedeeming then return end
    isRedeeming = true
    task.spawn(function()
        for _, code in ipairs(codes) do
            if not isRedeeming then break end
            redeemCode(code)
            task.wait(_G.SlowHub.CodeRedeemDelay or 0.5)
        end
        isRedeeming = false
    end)
end

Tab:Section({Title = "Codes"})

Tab:Slider({
    Title = "Redeem Delay",
    Flag = "CodeRedeemDelay",
    Step = 0.1,
    Value = {
        Min = 0.1,
        Max = 2,
        Default = _G.SlowHub.CodeRedeemDelay or 0.5,
    },
    Callback = function(Value)
        _G.SlowHub.CodeRedeemDelay = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})

Tab:Button({
    Title = "Redeem All Codes",
    Callback = function()
        redeemAllCodes()
    end,
})
