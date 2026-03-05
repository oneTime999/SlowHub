local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.AutoHaki = _G.SlowHub.AutoHaki or false

local CONFIG_FOLDER = "SlowHub"
local CONFIG_FILE = CONFIG_FOLDER .. "/config.json"

local function ensureFolder()
    if not isfolder(CONFIG_FOLDER) then
        makefolder(CONFIG_FOLDER)
    end
end

local function loadConfig()
    ensureFolder()
    if isfile(CONFIG_FILE) then
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(CONFIG_FILE))
        end)
        if ok and type(data) == "table" then
            return data
        end
    end
    return {}
end

local function saveConfig(key, value)
    ensureFolder()
    local current = loadConfig()
    current[key] = value
    pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(current))
    end)
end

local saved = loadConfig()
if saved["AutoHaki"] ~= nil then _G.SlowHub.AutoHaki = saved["AutoHaki"] end

local autoHakiConnection = nil
local respawnConnection = nil
local lastToggleTime = 0
local COOLDOWN_TIME = 3

local armParts = { "Left Arm", "Right Arm" }

local function isAlive()
    local character = Player.Character
    if not character then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function hasHakiEffect()
    local character = Player.Character
    if not character then return false end
    for _, armName in ipairs(armParts) do
        local arm = character:FindFirstChild(armName)
        if arm then
            local effect = arm:FindFirstChild("3")
            if effect and effect:IsA("ParticleEmitter") then
                return true
            end
        end
    end
    return false
end

local function toggleHaki()
    pcall(function()
        ReplicatedStorage.RemoteEvents.HakiRemote:FireServer("Toggle")
    end)
end

local function stopAutoHaki()
    if autoHakiConnection then
        autoHakiConnection:Disconnect()
        autoHakiConnection = nil
    end
    if respawnConnection then
        respawnConnection:Disconnect()
        respawnConnection = nil
    end
    lastToggleTime = 0
end

local function startAutoHaki()
    if autoHakiConnection then
        autoHakiConnection:Disconnect()
        autoHakiConnection = nil
    end
    lastToggleTime = 0
    autoHakiConnection = RunService.Heartbeat:Connect(function()
        if not isAlive() then return end
        local now = tick()
        if now - lastToggleTime >= COOLDOWN_TIME then
            if not hasHakiEffect() then
                toggleHaki()
                lastToggleTime = now
            end
        end
    end)
end

local function setupRespawnHandler()
    if respawnConnection then
        respawnConnection:Disconnect()
    end
    respawnConnection = Player.CharacterAdded:Connect(function(newCharacter)
        task.wait(1)
        local humanoid = newCharacter:WaitForChild("Humanoid", 5)
        if humanoid then
            task.wait(0.5)
            if not hasHakiEffect() then
                toggleHaki()
                lastToggleTime = tick()
            end
        end
    end)
end

local MiscTab = _G.MiscTab

MiscTab:CreateSection({ Title = "Haki" })

MiscTab:CreateToggle({
    Name = "Auto Haki",
    Flag = "AutoHaki",
    CurrentValue = _G.SlowHub.AutoHaki,
    Callback = function(value)
        _G.SlowHub.AutoHaki = value
        saveConfig("AutoHaki", value)
        if value then
            startAutoHaki()
            setupRespawnHandler()
        else
            stopAutoHaki()
        end
    end,
})

task.spawn(function()
    task.wait(2)
    if _G.SlowHub.AutoHaki then
        startAutoHaki()
        setupRespawnHandler()
    end
end)
