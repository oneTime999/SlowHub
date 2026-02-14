local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local autoCraftConnection = nil
local lastCraftTime = 0

local function stopAutoCraft()
    if autoCraftConnection then
        autoCraftConnection:Disconnect()
        autoCraftConnection = nil
    end
    _G.SlowHub.AutoCraftSlime = false
end

local function startAutoCraft()
    if autoCraftConnection then
        stopAutoCraft()
    end

    _G.SlowHub.AutoCraftSlime = true

    autoCraftConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoCraftSlime then
            stopAutoCraft()
            return
        end

        if tick() - lastCraftTime >= 2 then
            lastCraftTime = tick()
            pcall(function()
                local args = {
                    [1] = "SlimeKey",
                }
                ReplicatedStorage.Remotes.RequestSlimeCraft:InvokeServer(unpack(args))
            end)
        end
    end)
end

local Toggle = _G.MiscTab:CreateToggle({
    Name = "Auto Craft Slime Key",
    CurrentValue = _G.SlowHub.AutoCraftSlime or false,
    Flag = "AutoCraftSlimeKey",
    Callback = function(Value)
        if Value then
            startAutoCraft()
        else
            stopAutoCraft()
        end
        
        _G.SlowHub.AutoCraftSlime = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

if _G.SlowHub.AutoCraftSlime then
    task.wait(2)
    startAutoCraft()
end
