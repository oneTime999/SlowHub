local Tab = _G.SettingsTab
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Player = game:GetService("Players").LocalPlayer

Tab:AddButton({
    Title = "Server Hop",
    Description = "Search and join a different server",
    Callback = function()
        local PlaceId = game.PlaceId
        local function GetServers()
            local Cursor = ""
            local Servers = {}
            while Cursor do
                local URL = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"
                if Cursor ~= "" then
                    URL = URL .. "&cursor=" .. Cursor
                end
                local success, result = pcall(function()
                    return game:HttpGet(URL)
                end)
                if success then
                    local Body = HttpService:JSONDecode(result)
                    if Body and Body.data then
                        for _, v in pairs(Body.data) do
                            if v.playing < v.maxPlayers and v.id ~= game.JobId then
                                table.insert(Servers, v.id)
                            end
                        end
                    end
                    if #Servers > 0 then return Servers end
                    if Body.nextPageCursor then
                        Cursor = Body.nextPageCursor
                    else
                        break
                    end
                else
                    break
                end
            end
            return Servers
        end
        local ServerList = GetServers()
        if #ServerList > 0 then
            local RandomServer = ServerList[math.random(1, #ServerList)]
            TeleportService:TeleportToPlaceInstance(PlaceId, RandomServer, Player)
        else
            _G.Fluent:Notify({Title = "Server Hop", Content = "No other servers found!", Duration = 3})
        end
    end
})
