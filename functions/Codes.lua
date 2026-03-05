local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tab = _G.MiscTab

_G.SlowHub.CodeRedeemDelay = _G.SlowHub.CodeRedeemDelay or 0.5

local Codes = {
    "SORRYFORBUGS",
    "BADISSUESSORRY",
    "BOSSRUSH",
    "VERYBIGUPDATESOON",
    "SINOFPRIDE",
    "15KFOLLOWTY",
    "ROGUEALLIES",
    "RUSHKEYCODE",
    "SORRYSUDDENRESTART"
}

local RedeemState = {
    IsRedeeming = false
}

local function Notify(title, content, duration)
    duration = duration or 3
    pcall(function()
        if _G.WindUI and _G.WindUI.Notify then
            _G.WindUI:Notify({
                Title = title,
                Content = content,
                Duration = duration,
                Icon = "rbxassetid://4483362458"
            })
        end
    end)
end

local function RedeemCode(code)
    local success = pcall(function()
        local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if not remoteEvents then return end
        local codeRedeem = remoteEvents:FindFirstChild("CodeRedeem")
        if not codeRedeem then return end
        codeRedeem:InvokeServer(code)
    end)
    return success
end

local function RedeemAllCodes()
    if RedeemState.IsRedeeming then
        Notify("Codes", "Already redeeming codes!", 3)
        return
    end
    RedeemState.IsRedeeming = true
    task.spawn(function()
        Notify("Codes", "Redeeming " .. #Codes .. " codes...", 3)
        local successCount = 0
        local failCount = 0
        for _, code in ipairs(Codes) do
            if not RedeemState.IsRedeeming then break end
            local success = RedeemCode(code)
            if success then
                successCount = successCount + 1
            else
                failCount = failCount + 1
            end
            task.wait(_G.SlowHub.CodeRedeemDelay)
        end
        RedeemState.IsRedeeming = false
        Notify("Codes", "Redeemed: " .. successCount .. " | Failed: " .. failCount, 3)
    end)
end

Tab:Section({Title = "Codes"})

Tab:Slider({
    Title = "Redeem Delay",
    Step = 0.1,
    Value = {
        Min = 0.1,
        Max = 2,
        Default = _G.SlowHub.CodeRedeemDelay,
    },
    Callback = function(Value)
        _G.SlowHub.CodeRedeemDelay = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

Tab:Button({
    Title = "Redeem All Codes",
    Callback = function()
        RedeemAllCodes()
    end
})
