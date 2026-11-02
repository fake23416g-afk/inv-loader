-- Invisible key loader (проверка ключа на сервере)
local WORKER_URL = "https://keyload.fake23416g.workers.dev/load"
local HttpService = game:GetService("HttpService")


local function notify(text, isError)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Invisible",
            Text = text,
            Duration = 5,
        })
    end)
end

local function getHwid()
    local function fromEnv(name)
        local fn
        local ok, env = pcall(getgenv)
        if ok and type(env) == "table" then
            fn = env[name]
        end
        if type(fn) ~= "function" then
            local globalOk, globalFn = pcall(function()
                return _G[name]
            end)
            if globalOk and type(globalFn) == "function" then
                fn = globalFn
            end
        end
        if type(fn) ~= "function" then
            return nil
        end
        local callOk, value = pcall(fn)
        if callOk and type(value) == "string" and value ~= "" then
            return value
        end
        return nil
    end

    local value = fromEnv("gethwid") or fromEnv("get_hwid") or fromEnv("getHWID")
    if value then
        return value
    end

    local ok, syn = pcall(function()
        return getgenv().syn
    end)
    if ok and type(syn) == "table" and type(syn.get_hwid) == "function" then
        local callOk, hwid = pcall(syn.get_hwid)
        if callOk and type(hwid) == "string" and hwid ~= "" then
            return hwid
        end
    end
    return nil
end

local KEY_FILE = "invisible_key.txt"

local function readSavedKey()
    local ok, content = pcall(function()
        if type(isfile) == "function" and type(readfile) == "function" and isfile(KEY_FILE) then
            return readfile(KEY_FILE)
        end
        return nil
    end)
    if ok and type(content) == "string" and content ~= "" then
        return content:gsub("%s+", "")
    end
    return nil
end

local function saveKey(key)
    pcall(function()
        if type(writefile) == "function" then
            writefile(KEY_FILE, key)
        end
    end)
end

local function launch(source)
    local ok, err = pcall(function()
        if type(source) ~= "string" or #source < 10 then
            error("сервер вернул пустой ответ")
        end
        local chunk, compileError = loadstring(source)
        if not chunk then
            error(tostring(compileError))
        end
        chunk()
    end)
    if not ok then
        notify("Ошибка запуска: " .. tostring(err), true)
    end
end

local hwid = getHwid()

-- Запрашивает скрипт у сервера. Сервер сам проверяет ключ, срок и устройство.
local function fetchScript(key)
    local url = WORKER_URL
        .. "?key=" .. HttpService:UrlEncode(key)
        .. "&hwid=" .. HttpService:UrlEncode(hwid or "")
        .. "&uid=" .. tostring(game:GetService("Players").LocalPlayer.UserId)
    local ok, res = pcall(function()
        return game:HttpGet(url)
    end)
    if not ok or type(res) ~= "string" then
        return nil, "нет связи с сервером"
    end
    if res:sub(1, 6) == "--ERR:" then
        return nil, res:sub(7)
    end
    -- скрипт использует эти данные, чтобы выключиться, когда ключ закончится
    getgenv().INV_AUTH = { url = WORKER_URL, key = key, hwid = hwid or "" }
    return res
end

local saved = readSavedKey()
if saved then
    local source = fetchScript(saved)
    if source then
        launch(source)
        return
    end
end

local playerGui = game:GetService("Players").LocalPlayer
local parent = nil
local ok, coreGui = pcall(function()
    return game:GetService("CoreGui")
end)
if ok and coreGui then
    parent = coreGui
else
    parent = playerGui:WaitForChild("PlayerGui")
end

local screen = Instance.new("ScreenGui")
screen.Name = "InvisibleKeySystem"
screen.ResetOnSpawn = false
screen.DisplayOrder = 10000
screen.IgnoreGuiInset = true
pcall(function()
    syn.protect_gui(screen)
end)
screen.Parent = parent

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 340, 0, 236)
frame.Position = UDim2.new(0.5, -170, 0.5, -118)
frame.BackgroundColor3 = Color3.fromRGB(15, 17, 22)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = screen
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(0, 210, 160)
stroke.Thickness = 1.4

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 30)
title.Position = UDim2.new(0, 10, 0, 10)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 17
title.TextColor3 = Color3.fromRGB(0, 220, 170)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "INVISIBLE | Key System"
title.Parent = frame

local hwidLabel = Instance.new("TextLabel")
hwidLabel.Size = UDim2.new(1, -100, 0, 18)
hwidLabel.Position = UDim2.new(0, 12, 0, 44)
hwidLabel.BackgroundTransparency = 1
hwidLabel.Font = Enum.Font.Code
hwidLabel.TextSize = 11
hwidLabel.TextColor3 = Color3.fromRGB(140, 150, 170)
hwidLabel.TextXAlignment = Enum.TextXAlignment.Left
hwidLabel.TextTruncate = Enum.TextTruncate.AtEnd
hwidLabel.Text = "HWID: " .. (hwid or "недоступен")
hwidLabel.Parent = frame

local copyButton = Instance.new("TextButton")
copyButton.Size = UDim2.new(0, 78, 0, 20)
copyButton.Position = UDim2.new(1, -90, 0, 43)
copyButton.BackgroundColor3 = Color3.fromRGB(30, 36, 46)
copyButton.BorderSizePixel = 0
copyButton.Font = Enum.Font.GothamSemibold
copyButton.TextSize = 11
copyButton.TextColor3 = Color3.fromRGB(200, 210, 230)
copyButton.Text = "Скопировать"
copyButton.Visible = hwid ~= nil
copyButton.Parent = frame
Instance.new("UICorner", copyButton).CornerRadius = UDim.new(0, 6)

copyButton.MouseButton1Click:Connect(function()
    local copied = false
    pcall(function()
        if type(setclipboard) == "function" then
            setclipboard(hwid)
            copied = true
        end
    end)
    if not copied then
        pcall(function()
            toclipboard(hwid)
            copied = true
        end)
    end
    copyButton.Text = copied and "Скопировано" or "Нет доступа"
    task.delay(1.2, function()
        copyButton.Text = "Скопировать"
    end)
end)

local keyBox = Instance.new("TextBox")
keyBox.Size = UDim2.new(1, -24, 0, 36)
keyBox.Position = UDim2.new(0, 12, 0, 72)
keyBox.BackgroundColor3 = Color3.fromRGB(24, 28, 36)
keyBox.BorderSizePixel = 0
keyBox.Font = Enum.Font.Code
keyBox.TextSize = 12
keyBox.TextColor3 = Color3.fromRGB(230, 235, 245)
keyBox.PlaceholderText = "Вставь ключ INV1-..."
keyBox.PlaceholderColor3 = Color3.fromRGB(110, 118, 135)
keyBox.Text = saved or ""
keyBox.ClearTextOnFocus = false
keyBox.Parent = frame
Instance.new("UICorner", keyBox).CornerRadius = UDim.new(0, 8)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -24, 0, 18)
status.Position = UDim2.new(0, 12, 0, 116)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.TextColor3 = Color3.fromRGB(160, 170, 190)
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextTruncate = Enum.TextTruncate.AtEnd
status.Text = "Введи ключ, чтобы запустить скрипт"
status.Parent = frame

local activate = Instance.new("TextButton")
activate.Size = UDim2.new(1, -24, 0, 38)
activate.Position = UDim2.new(0, 12, 0, 142)
activate.BackgroundColor3 = Color3.fromRGB(0, 180, 135)
activate.BorderSizePixel = 0
activate.Font = Enum.Font.GothamBold
activate.TextSize = 14
activate.TextColor3 = Color3.fromRGB(10, 12, 15)
activate.Text = "Активировать ключ"
activate.Parent = frame
Instance.new("UICorner", activate).CornerRadius = UDim.new(0, 8)

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(1, -24, 0, 26)
closeButton.Position = UDim2.new(0, 12, 0, 190)
closeButton.BackgroundColor3 = Color3.fromRGB(26, 30, 38)
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.GothamSemibold
closeButton.TextSize = 12
closeButton.TextColor3 = Color3.fromRGB(190, 198, 214)
closeButton.Text = "Закрыть"
closeButton.Parent = frame
Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0, 7)

local function attempt()
    local key = keyBox.Text:gsub("%s+", ""):upper()
    status.Text = "Проверяю ключ..."
    status.TextColor3 = Color3.fromRGB(160, 170, 190)

    local source, message = fetchScript(key)
    if not source then
        status.Text = message or "Ошибка"
        status.TextColor3 = Color3.fromRGB(255, 95, 95)
        return
    end

    saveKey(key)
    status.Text = "Ключ принят. Запускаю..."
    status.TextColor3 = Color3.fromRGB(80, 220, 140)
    activate.Text = "Запуск..."
    activate.BackgroundColor3 = Color3.fromRGB(0, 130, 100)
    task.wait(0.4)
    screen:Destroy()
    launch(source)
end

activate.MouseButton1Click:Connect(attempt)
keyBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        attempt()
    end
end)
closeButton.MouseButton1Click:Connect(function()
    screen:Destroy()
end)

local dragging = false
local dragStart = nil
local startPosition = nil
frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPosition = frame.Position
    end
end)
frame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
game:GetService("UserInputService").InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPosition.X.Scale, startPosition.X.Offset + delta.X,
            startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
        )
    end
end)
