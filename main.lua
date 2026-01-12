local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer
local SCRIPT_ID = "33714296afe58acfdbf28f4c6e3a6837"

_G.SlowHub = {}

if getgenv().LRM_IsUserPremium or getgenv().LRM_IsUserAuthenticated then
    _G.script_key = "LUARMOR_AUTHENTICATED"
    task.wait(1)
    loadstring(game:HttpGet("https://raw.githubusercontent.com/oneTime999/SlowHub/main/hub.lua"))()
    return
end

_G.script_key = getgenv().script_key or nil

local configFolder = "SlowHub"
local keyFile = configFolder .. "/key.txt"

if not isfolder(configFolder) then makefolder(configFolder) end

local function SaveKey(key) pcall(function() writefile(keyFile, key) end) end
local function LoadSavedKey() 
    if isfile(keyFile) then
        local success, key = pcall(function() return readfile(keyFile) end)
        if success and key and #key == 32 then return key end
    end 
    return nil 
end
local function DeleteSavedKey() pcall(function() if isfile(keyFile) then delfile(keyFile) end end) end

local function CheckKey(key)
    local success, result = pcall(function()
        return game:HttpGet("https://api.luarmor.net/files/v3/check_key.lua?key=" .. key .. "&script_id=" .. SCRIPT_ID)
    end)
    if success then
        local decoded = HttpService:JSONDecode(result)
        return decoded
    end
    return {code = "ERROR"}
end

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local function CreateAuthWindow()
    local Window = Fluent:CreateWindow({
        Title = "Slow Hub", SubTitle = "Key Auth", TabWidth = 160, Size = UDim2.fromOffset(500, 350),
        Acrylic = false, Theme = "Darker", MinimizeKey = Enum.KeyCode.LeftControl
    })
    
    local Tab = Window:AddTab({ Title = "Auth", Icon = "key" })
    local enteredKey = ""
    
    Tab:AddInput("KeyInput", {
        Title = "Key", PlaceholderText = "32 character key...", TextDisappear = false,
        Callback = function(Text) enteredKey = Text end
    })
    
    Tab:AddButton({
        Title = "Verify", Callback = function()
            if #enteredKey ~= 32 then 
                Fluent:Notify({Title = "Error", Content = "Key deve ter 32 caracteres", Duration = 3})
                return 
            end
            
            Tab:AddParagraph("Status", "Verificando...")
            task.spawn(function()
                local status = CheckKey(enteredKey)
                if status.code == "KEY_VALID" then
                    SaveKey(enteredKey)
                    _G.script_key = enteredKey
                    Fluent:Notify({Title = "Sucesso", Content = "Carregando Slow Hub...", Duration = 3})
                    task.wait(2)
                    Window:Destroy()
                    task.wait(0.5)
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/oneTime999/SlowHub/main/hub.lua"))()
                else
                    Tab:AddParagraph("Status", "Key inválida!")
                    Fluent:Notify({Title = "Erro", Content = "Key inválida", Duration = 3})
                end
            end)
        end
    })
end

local savedKey = LoadSavedKey()
if _G.script_key and #_G.script_key == 32 then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/oneTime999/SlowHub/main/hub.lua"))()
elseif savedKey then
    local status = CheckKey(savedKey)
    if status.code == "KEY_VALID" then
        _G.script_key = savedKey
        loadstring(game:HttpGet("https://raw.githubusercontent.com/oneTime999/SlowHub/main/hub.lua"))()
    else
        DeleteSavedKey()
        CreateAuthWindow()
    end
else
    CreateAuthWindow()
end
