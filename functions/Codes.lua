local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tab = _G.MiscTab

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.CodeRedeemDelay = _G.SlowHub.CodeRedeemDelay or 0.5

local Codes = {
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

local RedeemState = {
    IsRedeeming = false
}

local function Notify(title, content, duration)
    duration = duration or 3
    
    pcall(function()
        if _G.Rayfield and _G.Rayfield.Notify then
            _G.Rayfield:Notify({
                Title = title,
                Content = content,
                Duration = duration,
                Image = 4483362458
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

Tab:CreateSection("Codes")

Tab:CreateSlider({
    Name = "Redeem Delay",
    Range = {0.1, 2},
    Increment = 0.1,
    Suffix = "Seconds",
    CurrentValue = _G.SlowHub.CodeRedeemDelay,
    Flag = "CodeRedeemDelay",
    Callback = function(Value)
        _G.SlowHub.CodeRedeemDelay = Value
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

Tab:CreateButton({
    Name = "Redeem All Codes",
    Callback = function()
        RedeemAllCodes()
    end
})
