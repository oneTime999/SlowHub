local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.CodeRedeemDelay = _G.SlowHub.CodeRedeemDelay or 0.5

local CONFIG_FOLDER = "SlowHub"
local CONFIG_FILE = CONFIG_FOLDER .. "/config.json"

local function ensureFolder()
    if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
end

local function loadConfig()
    ensureFolder()
    if isfile(CONFIG_FILE) then
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_FILE)) end)
        if ok and type(data) == "table" then return data end
    end
    return {}
end

local function saveConfig(key, value)
    ensureFolder()
    local current = loadConfig()
    current[key] = value
    pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(current)) end)
end

local saved = loadConfig()
if saved["CodeRedeemDelay"] ~= nil then _G.SlowHub.CodeRedeemDelay = saved["CodeRedeemDelay"] end

local Codes = {
    "SORRYFORBUGS","BADISSUESSORRY","BOSSRUSH","VERYBIGUPDATESOON","SINOFPRIDE",
    "15KFOLLOWTY","ROGUEALLIES","RUSHKEYCODE","SORRYSUDDENRESTART",
}

local RedeemState = {IsRedeeming = false}

local function RedeemCode(code)
    return pcall(function()
        local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if not remoteEvents then return end
        local codeRedeem = remoteEvents:FindFirstChild("CodeRedeem")
        if not codeRedeem then return end
        codeRedeem:InvokeServer(code)
    end)
end

local function RedeemAllCodes()
    if RedeemState.IsRedeeming then return end
    RedeemState.IsRedeeming = true
    task.spawn(function()
        for _, code in ipairs(Codes) do
            if not RedeemState.IsRedeeming then break end
            RedeemCode(code)
            task.wait(_G.SlowHub.CodeRedeemDelay)
        end
        RedeemState.IsRedeeming = false
    end)
end

local MiscTab = _G.MiscTab

MiscTab:CreateSection({ Title = "Codes" })

MiscTab:CreateSlider({
    Name = "Redeem Delay",
    Flag = "CodeRedeemDelay",
    Range = { 0.1, 2 },
    Increment = 0.1,
    CurrentValue = _G.SlowHub.CodeRedeemDelay,
    Callback = function(value)
        _G.SlowHub.CodeRedeemDelay = value
        saveConfig("CodeRedeemDelay", value)
    end,
})

MiscTab:CreateButton({
    Name = "Redeem All Codes",
    Callback = function()
        RedeemAllCodes()
    end,
})
