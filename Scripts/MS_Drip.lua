--========================================================--
--                    MAKIMA SCRIPTS                     --
--                      MakimaDev                         --
--========================================================--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local HttpService = game:GetService("HttpService")
local PathfindingService = game:GetService("PathfindingService")

local LocalPlayer = Players.LocalPlayer

--========================================================--
-- CONFIGURAÇÕES
--========================================================--

local WINDUI_URL =
    "https://github.com/Footagesus/WindUI/releases/download/1.6.66/main.lua"

local DISCORD_URL =
    "https://discord.gg/4aEBbw7BQf"

--========================================================--
-- FUNÇÃO HTTP SEGURA
--========================================================--

local function SafeHttpGet(url)

    local success, result = pcall(function()
        return game:HttpGet(url)
    end)

    if not success then

        warn("[Makima Scripts] HTTP ERROR:")
        warn(url)
        warn(result)

        return nil
    end

    if type(result) ~= "string" or result == "" then

        warn("[Makima Scripts] Resposta HTTP vazia:")
        warn(url)

        return nil
    end

    return result
end

--========================================================--
-- CARREGAR WINDUI
--========================================================--

local WindUISource = SafeHttpGet(WINDUI_URL)

if not WindUISource then
    warn("[Makima Scripts] Não foi possível carregar o WindUI.")
    return
end

local WindUI

do

    local success, result = pcall(function()

        local fn = loadstring(WindUISource)

        if not fn then
            error("WindUI retornou código inválido.")
        end

        return fn()

    end)

    if not success then

        warn("[Makima Scripts] Erro ao iniciar WindUI:")
        warn(result)

        return
    end

    WindUI = result
end

if not WindUI then
    warn("[Makima Scripts] WindUI não carregou.")
    return
end

--========================================================--
-- PANDA AUTH - PUSL V4
--========================================================--
-- O Panda Auth controla a Key e o link de obtenção.
-- Não há Kick() quando a Key é inválida/expirada.

local PANDA_SERVICE_ID = "mskey"
local PANDA_LIB_URL = "https://secure.pandauth.com/pv4/lib"

local PUSL
do
    local success, result = pcall(function()
        local source = game:HttpGet(PANDA_LIB_URL)
        local loader = loadstring(source)
        if type(loader) ~= "function" then
            error("Panda Auth retornou código inválido.")
        end
        return loader()
    end)

    if not success or type(result) ~= "table" then
        warn("[Makima Scripts] Falha ao carregar Panda Auth:", result)
        return
    end

    PUSL = result
end

if type(PUSL.configure) ~= "function" or type(PUSL.validate) ~= "function" then
    warn("[Makima Scripts] Panda Auth incompatível: configure()/validate() não encontrados.")
    return
end

local pandaConfigured = pcall(function()
    PUSL.configure({
        serviceId = PANDA_SERVICE_ID,
    })
end)

if not pandaConfigured then
    warn("[Makima Scripts] Não foi possível configurar o serviço Panda Auth.")
    return
end

local function GetPandaKeyLink()
    if type(PUSL.getKeyUrl) ~= "function" then
        return nil
    end

    local success, link = pcall(function()
        return PUSL.getKeyUrl()
    end)

    if success and type(link) == "string" and link ~= "" then
        return link
    end

    return nil
end

local function ValidateKey(key)
    if type(key) ~= "string" then
        return false
    end

    key = key:gsub("^%s+", ""):gsub("%s+$", "")
    if key == "" then
        return false
    end

    local success, result = pcall(function()
        return PUSL.validate(key)
    end)

    if not success or type(result) ~= "table" then
        warn("[Makima Scripts] Erro ao validar Key no Panda Auth:", result)
        return false
    end

    if result.success == true then
        pcall(function()
            getgenv().SCRIPT_KEY = key
        end)
        return true
    end

    warn("[Makima Scripts] Key recusada pelo Panda Auth:", tostring(result.message or result.error or "INVALID"))
    return false
end

local PANDA_KEY_URL = GetPandaKeyLink()

--========================================================--
-- TEMA
--========================================================--

pcall(function()

    WindUI:AddTheme({

        Name = "MakimaRed",

        Accent = Color3.fromRGB(
            190,
            20,
            45
        ),

        Background = Color3.fromRGB(
            12,
            9,
            10
        ),

        Outline = Color3.fromRGB(
            90,
            25,
            35
        ),

        Text = Color3.fromRGB(
            245,
            245,
            245
        ),

        Placeholder = Color3.fromRGB(
            130,
            125,
            128
        ),

        Button = Color3.fromRGB(
            55,
            22,
            28
        ),

        Icon = Color3.fromRGB(
            255,
            80,
            100
        ),
    })

end)

pcall(function()
    WindUI:SetTheme("MakimaRed")
end)

--========================================================--
-- WINDOW + KEYSYSTEM NATIVO
--========================================================--

local Window = WindUI:CreateWindow({

    Title = "Makima Scripts",

    Author = "by MakimaDev",

    Icon = "flame",

    Folder = "MakimaScriptsAuthV2",

    Size = UDim2.fromOffset(
        580,
        460
    ),

    Transparent = false,

    Theme = "MakimaRed",

    Resizable = true,

    SideBarWidth = 180,

    --====================================================--
    -- KEY SYSTEM DO PRÓPRIO WINDUI
    --====================================================--

    KeySystem = {

        Title = "Makima Scripts",

        Note = "Insira sua Key para continuar.",

        URL = PANDA_KEY_URL or "",

        SaveKey = true,

        KeyValidator = function(key)

            return ValidateKey(key)

        end,
    },
})

--========================================================--
-- NOTIFICAÇÃO
--========================================================--

local function Notify(title, content, duration)

    pcall(function()

        WindUI:Notify({

            Title = title,

            Content = content,

            Duration = duration or 3,

        })

    end)

end

--========================================================--
-- CLIPBOARD
--========================================================--

local function Copy(text)

    if type(setclipboard) ~= "function" then

        Notify(
            "Clipboard",
            "Seu executor não suporta copiar para a área de transferência.",
            4
        )

        return
    end

    local success = pcall(function()
        setclipboard(text)
    end)

    if success then

        Notify(
            "Copiado",
            "Link copiado para a área de transferência.",
            2
        )

    end
end

--========================================================--
-- DRIP MENU | SCRIPTS INTEGRADOS (cada um roda só quando clicado)
--========================================================--

local DripExtras = {}

DripExtras.AutoJJs = function()
    --[[
    ✦ DRIP MENU AUTO JJs ✦
    Sistema avançado de automação
    Design exclusivo por Willz
    ]]

    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local TweenService = game:GetService("TweenService")
    local CoreGui = game:GetService("CoreGui")
    local NotificationService = game:GetService("StarterGui")

    local LocalPlayer = Players.LocalPlayer

    pcall(function()
        if CoreGui:FindFirstChild("DripMenuAutoJJs") then
            CoreGui.DripMenuAutoJJs:Destroy()
        end
    end)

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "DripMenuAutoJJs"
    ScreenGui.Parent = CoreGui
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local Frame = Instance.new("Frame")
    Frame.Parent = ScreenGui
    Frame.Size = UDim2.new(0, 310, 0, 265)
    Frame.Position = UDim2.new(0.5, -155, 0.5, -132)
    Frame.BackgroundColor3 = Color3.fromRGB(10, 8, 18)
    Frame.BorderSizePixel = 0
    Frame.ClipsDescendants = true

    local FrameCorner = Instance.new("UICorner")
    FrameCorner.Parent = Frame
    FrameCorner.CornerRadius = UDim.new(0, 18)

    local FrameStroke = Instance.new("UIStroke")
    FrameStroke.Parent = Frame
    FrameStroke.Color = Color3.fromRGB(60, 45, 80)
    FrameStroke.Thickness = 1.5
    FrameStroke.Transparency = 0.2

    local Gradient = Instance.new("UIGradient")
    Gradient.Parent = Frame
    Gradient.Rotation = 135
    Gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 8, 22)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(15, 10, 28)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 6, 18))
    })

    local TopGlow = Instance.new("Frame")
    TopGlow.Parent = Frame
    TopGlow.Size = UDim2.new(1, 0, 0, 3)
    TopGlow.Position = UDim2.new(0, 0, 0, 0)
    TopGlow.BorderSizePixel = 0
    TopGlow.BackgroundColor3 = Color3.fromRGB(150, 0, 255)

    local GlowGradient = Instance.new("UIGradient")
    GlowGradient.Parent = TopGlow
    GlowGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.8),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 0.8)
    })

    -- =========================================================
    -- HEADER
    -- =========================================================

    local Header = Instance.new("Frame")
    Header.Parent = Frame
    Header.BackgroundTransparency = 1
    Header.Size = UDim2.new(1, -24, 0, 52)
    Header.Position = UDim2.new(0, 12, 0, 5)

    -- =========================================================
    -- ÍCONE
    -- =========================================================

    local Icon = Instance.new("Frame")
    Icon.Parent = Header
    Icon.Size = UDim2.new(0, 38, 0, 38)
    Icon.Position = UDim2.new(0, 0, 0.5, -19)
    Icon.BackgroundColor3 = Color3.fromRGB(120, 0, 210)
    Icon.BorderSizePixel = 0

    local IconCorner = Instance.new("UICorner")
    IconCorner.Parent = Icon
    IconCorner.CornerRadius = UDim.new(0, 11)

    local IconGradient = Instance.new("UIGradient")
    IconGradient.Parent = Icon
    IconGradient.Rotation = 45
    IconGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 0, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 0, 200))
    })

    local IconImage = Instance.new("ImageLabel")
    IconImage.Name = "IconImage"
    IconImage.Parent = Icon
    IconImage.BackgroundTransparency = 1
    IconImage.Size = UDim2.new(1, -6, 1, -6)
    IconImage.Position = UDim2.new(0, 3, 0, 3)
    IconImage.Image = "rbxassetid://11392905305"
    IconImage.ScaleType = Enum.ScaleType.Fit

    -- =========================================================
    -- TÍTULO
    -- =========================================================

    local TextLabel = Instance.new("TextLabel")
    TextLabel.Name = "KeepVisible"
    TextLabel.Parent = Header
    TextLabel.BackgroundTransparency = 1
    TextLabel.Position = UDim2.new(0, 48, 0, 4)
    TextLabel.Size = UDim2.new(1, -90, 0, 24)
    TextLabel.Font = Enum.Font.GothamBold
    TextLabel.Text = "AUTO JJs DRIP"
    TextLabel.TextXAlignment = Enum.TextXAlignment.Left
    TextLabel.TextSize = 20
    TextLabel.TextColor3 = Color3.fromRGB(220, 210, 255)

    local Subtitle = Instance.new("TextLabel")
    Subtitle.Parent = Header
    Subtitle.BackgroundTransparency = 1
    Subtitle.Position = UDim2.new(0, 48, 0, 27)
    Subtitle.Size = UDim2.new(1, -90, 0, 17)
    Subtitle.Font = Enum.Font.Gotham
    Subtitle.Text = "by Willz • Polichinelos"
    Subtitle.TextXAlignment = Enum.TextXAlignment.Left
    Subtitle.TextSize = 11
    Subtitle.TextColor3 = Color3.fromRGB(140, 120, 180)

    -- =========================================================
    -- BOTÃO MINIMIZAR
    -- =========================================================

    local TextButton = Instance.new("TextButton")
    TextButton.Name = "KeepVisible"
    TextButton.Parent = Header
    TextButton.Size = UDim2.new(0, 34, 0, 34)
    TextButton.Position = UDim2.new(1, -34, 0.5, -17)
    TextButton.BackgroundColor3 = Color3.fromRGB(25, 18, 40)
    TextButton.BorderSizePixel = 0
    TextButton.Text = "−"
    TextButton.Font = Enum.Font.GothamBold
    TextButton.TextSize = 21
    TextButton.TextColor3 = Color3.fromRGB(200, 190, 220)
    TextButton.AutoButtonColor = false

    local MinCorner = Instance.new("UICorner")
    MinCorner.Parent = TextButton
    MinCorner.CornerRadius = UDim.new(0, 10)

    TextButton.MouseEnter:Connect(function()
        TweenService:Create(TextButton, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(45, 30, 70)
        }):Play()
    end)

    TextButton.MouseLeave:Connect(function()
        TweenService:Create(TextButton, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(25, 18, 40)
        }):Play()
    end)

    -- =========================================================
    -- DIVISÓRIA
    -- =========================================================

    local Divider = Instance.new("Frame")
    Divider.Parent = Frame
    Divider.Position = UDim2.new(0, 15, 0, 59)
    Divider.Size = UDim2.new(1, -30, 0, 1)
    Divider.BorderSizePixel = 0
    Divider.BackgroundColor3 = Color3.fromRGB(60, 40, 80)

    -- =========================================================
    -- VELOCIDADE
    -- =========================================================

    local IntervalLabel = Instance.new("TextLabel")
    IntervalLabel.Parent = Frame
    IntervalLabel.BackgroundTransparency = 1
    IntervalLabel.Position = UDim2.new(0, 17, 0, 70)
    IntervalLabel.Size = UDim2.new(0, 100, 0, 17)
    IntervalLabel.Font = Enum.Font.GothamMedium
    IntervalLabel.Text = "VELOCIDADE"
    IntervalLabel.TextXAlignment = Enum.TextXAlignment.Left
    IntervalLabel.TextSize = 10
    IntervalLabel.TextColor3 = Color3.fromRGB(150, 130, 180)

    local TextBox = Instance.new("TextBox")
    TextBox.Parent = Frame
    TextBox.Size = UDim2.new(0, 130, 0, 38)
    TextBox.Position = UDim2.new(0, 15, 0, 88)
    TextBox.BackgroundColor3 = Color3.fromRGB(20, 15, 35)
    TextBox.BorderSizePixel = 0
    TextBox.Font = Enum.Font.GothamBold
    TextBox.PlaceholderText = "0.8s"
    TextBox.Text = "0.8"
    TextBox.TextColor3 = Color3.fromRGB(220, 210, 255)
    TextBox.PlaceholderColor3 = Color3.fromRGB(110, 90, 140)
    TextBox.TextSize = 15
    TextBox.ClearTextOnFocus = false

    local BoxCorner = Instance.new("UICorner")
    BoxCorner.Parent = TextBox
    BoxCorner.CornerRadius = UDim.new(0, 10)

    local BoxStroke = Instance.new("UIStroke")
    BoxStroke.Parent = TextBox
    BoxStroke.Color = Color3.fromRGB(70, 50, 90)
    BoxStroke.Thickness = 1

    local WarningLabel = Instance.new("TextLabel")
    WarningLabel.Parent = Frame
    WarningLabel.BackgroundTransparency = 1
    WarningLabel.Position = UDim2.new(0, 155, 0, 90)
    WarningLabel.Size = UDim2.new(0, 140, 0, 34)
    WarningLabel.Font = Enum.Font.Gotham
    WarningLabel.Text = "⚠️ mínimo 0.6"
    WarningLabel.TextColor3 = Color3.fromRGB(255, 180, 60)
    WarningLabel.TextSize = 9
    WarningLabel.TextXAlignment = Enum.TextXAlignment.Left
    WarningLabel.TextWrapped = true

    -- =========================================================
    -- LIMITE
    -- =========================================================

    local LimitLabel = Instance.new("TextLabel")
    LimitLabel.Parent = Frame
    LimitLabel.BackgroundTransparency = 1
    LimitLabel.Position = UDim2.new(0, 17, 0, 132)
    LimitLabel.Size = UDim2.new(0, 100, 0, 17)
    LimitLabel.Font = Enum.Font.GothamMedium
    LimitLabel.Text = "LIMITE"
    LimitLabel.TextXAlignment = Enum.TextXAlignment.Left
    LimitLabel.TextSize = 10
    LimitLabel.TextColor3 = Color3.fromRGB(150, 130, 180)

    local LimitBox = Instance.new("TextBox")
    LimitBox.Parent = Frame
    LimitBox.Size = UDim2.new(0, 130, 0, 38)
    LimitBox.Position = UDim2.new(0, 15, 0, 150)
    LimitBox.BackgroundColor3 = Color3.fromRGB(20, 15, 35)
    LimitBox.BorderSizePixel = 0
    LimitBox.Font = Enum.Font.GothamBold
    LimitBox.PlaceholderText = "∞"
    LimitBox.Text = ""
    LimitBox.TextColor3 = Color3.fromRGB(220, 210, 255)
    LimitBox.PlaceholderColor3 = Color3.fromRGB(110, 90, 140)
    LimitBox.TextSize = 15
    LimitBox.ClearTextOnFocus = false

    local LimitCorner = Instance.new("UICorner")
    LimitCorner.Parent = LimitBox
    LimitCorner.CornerRadius = UDim.new(0, 10)

    local LimitStroke = Instance.new("UIStroke")
    LimitStroke.Parent = LimitBox
    LimitStroke.Color = Color3.fromRGB(70, 50, 90)
    LimitStroke.Thickness = 1

    local WarningLabel2 = Instance.new("TextLabel")
    WarningLabel2.Parent = Frame
    WarningLabel2.BackgroundTransparency = 1
    WarningLabel2.Position = UDim2.new(0, 155, 0, 152)
    WarningLabel2.Size = UDim2.new(0, 140, 0, 34)
    WarningLabel2.Font = Enum.Font.Gotham
    WarningLabel2.Text = "⚠️ mínimo 1"
    WarningLabel2.TextColor3 = Color3.fromRGB(255, 180, 60)
    WarningLabel2.TextSize = 9
    WarningLabel2.TextXAlignment = Enum.TextXAlignment.Left
    WarningLabel2.TextWrapped = true

    -- =========================================================
    -- TOGGLE
    -- =========================================================

    local TextButton2 = Instance.new("TextButton")
    TextButton2.Parent = Frame
    TextButton2.Size = UDim2.new(1, -30, 0, 48)
    TextButton2.Position = UDim2.new(0, 15, 0, 196)
    TextButton2.BackgroundColor3 = Color3.fromRGB(22, 15, 38)
    TextButton2.BorderSizePixel = 0
    TextButton2.Font = Enum.Font.GothamBlack
    TextButton2.Text = "●  OFF"
    TextButton2.TextColor3 = Color3.fromRGB(255, 80, 100)
    TextButton2.TextSize = 17
    TextButton2.AutoButtonColor = false

    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.Parent = TextButton2
    ToggleCorner.CornerRadius = UDim.new(0, 12)

    local ToggleStroke = Instance.new("UIStroke")
    ToggleStroke.Parent = TextButton2
    ToggleStroke.Color = Color3.fromRGB(80, 40, 70)
    ToggleStroke.Thickness = 1

    -- =========================================================
    -- RODAPÉ
    -- =========================================================

    local TextLabel3 = Instance.new("TextLabel")
    TextLabel3.Parent = Frame
    TextLabel3.BackgroundTransparency = 1
    TextLabel3.Position = UDim2.new(0, 0, 1, -17)
    TextLabel3.Size = UDim2.new(1, 0, 0, 13)
    TextLabel3.Font = Enum.Font.Gotham
    TextLabel3.Text = "Drip • Willz Edition"
    TextLabel3.TextColor3 = Color3.fromRGB(90, 70, 120)
    TextLabel3.TextSize = 9

    -- =========================================================
    -- MINIMIZAR
    -- =========================================================

    local minimized = false
    local FrameSize = Frame.Size

    TextButton.MouseButton1Click:Connect(function()
        minimized = not minimized

        if minimized then
            for _, child in pairs(Frame:GetChildren()) do
                if child:IsA("GuiObject") and child.Name ~= "KeepVisible" then
                    child.Visible = false
                end
            end

            Header.Visible = true
            TextButton.Visible = true

            TweenService:Create(
                Frame,
                TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                {
                    Size = UDim2.new(0, 310, 0, 62)
                }
            ):Play()

            TextButton.Text = "+"
            return
        end

        TweenService:Create(
            Frame,
            TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {
                Size = FrameSize
            }
        ):Play()

        for _, child in pairs(Frame:GetChildren()) do
            if child:IsA("GuiObject") then
                child.Visible = true
            end
        end

        TextButton.Visible = true
        TextLabel.Visible = true
        TextButton.Text = "−"
    end)

    -- =========================================================
    -- ARRASTAR
    -- =========================================================

    local dragging
    local dragInput
    local dragStart
    local startPos

    Frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            dragStart = input.Position
            startPos = Frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    Frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then

            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart

            Frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    -- =========================================================
    -- CONFIGURAÇÕES
    -- =========================================================

    local active = false
    local interval = 0.8
    local maxCount = math.huge
    local currentCount = 0
    local processingLock = false
    local stopRequested = false

    local KeyMap = {
        Q = Enum.KeyCode.Q,
        E = Enum.KeyCode.E
    }

    -- =========================================================
    -- NOTIFICAÇÃO
    -- =========================================================

    local function showNotification(text)
        pcall(function()
            NotificationService:SetCore("SendNotification", {
                Title = "DRIP MENU",
                Text = text,
                Duration = 3
            })
        end)
    end

    -- =========================================================
    -- VELOCIDADE
    -- =========================================================

    local function updateInterval()
        local raw = TextBox.Text:gsub("%s+", "")

        if raw == "" then
            interval = 0.8
            TextBox.Text = "0.8"
            return
        end

        local num = tonumber(raw)

        if num and num >= 0.6 then
            interval = num
            TextBox.Text = tostring(interval)
        else
            showNotification("VOCÊ É CEGO? O MÍNIMO É 0.6!")
            TextBox.Text = "0.8"
            interval = 0.8
        end
    end

    -- =========================================================
    -- LIMITE
    -- =========================================================

    local function updateLimit()
        local raw = LimitBox.Text:gsub("%s+", "")

        if raw == "" then
            maxCount = math.huge
            return
        end

        local num = tonumber(raw)

        if num and num >= 1 then
            maxCount = math.floor(num)
            LimitBox.Text = tostring(maxCount)
        else
            maxCount = math.huge
            LimitBox.Text = ""
        end
    end

    local function resetCounter()
        currentCount = 0
    end

    local function reachedLimit()
        return currentCount >= maxCount
    end

    TextBox.FocusLost:Connect(updateInterval)

    LimitBox.FocusLost:Connect(function()
        updateLimit()
        resetCounter()
    end)

    -- =========================================================
    -- UI DO TOGGLE
    -- =========================================================

    local function updateToggleUI(isActive)
        if isActive then

            TextButton2.Text = "●  ON"
            TextButton2.TextColor3 = Color3.fromRGB(120, 255, 180)

            TweenService:Create(
                TextButton2,
                TweenInfo.new(0.15),
                {
                    BackgroundColor3 = Color3.fromRGB(25, 45, 35)
                }
            ):Play()

            TweenService:Create(
                ToggleStroke,
                TweenInfo.new(0.15),
                {
                    Color = Color3.fromRGB(60, 180, 100)
                }
            ):Play()

        else

            TextButton2.Text = "●  OFF"
            TextButton2.TextColor3 = Color3.fromRGB(255, 80, 100)

            TweenService:Create(
                TextButton2,
                TweenInfo.new(0.15),
                {
                    BackgroundColor3 = Color3.fromRGB(22, 15, 38)
                }
            ):Play()

            TweenService:Create(
                ToggleStroke,
                TweenInfo.new(0.15),
                {
                    Color = Color3.fromRGB(80, 40, 70)
                }
            ):Play()

        end
    end

    -- =========================================================
    -- PARAR
    -- =========================================================

    local function stopAuto()
        stopRequested = true
        active = false
        processingLock = false

        updateToggleUI(false)

        stopRequested = false
    end

    -- =========================================================
    -- TOGGLE PRINCIPAL
    -- =========================================================

    TextButton2.MouseButton1Click:Connect(function()

        if processingLock then
            stopRequested = true
            return
        end

        if active then
            stopAuto()
            return
        end

        active = true

        updateInterval()
        updateLimit()
        resetCounter()
        updateToggleUI(true)

    end)

    -- =========================================================
    -- LOOP AUTO JJs (CORrigido)
    -- =========================================================

    task.spawn(function()

        local processed = {}

        while true do

            if interval > 0 then
                task.wait(0.01)
            else
                task.wait()
            end

            if active and not processingLock then

                if stopRequested or reachedLimit() then
                    stopAuto()
                    task.wait()
                    continue
                end

                processingLock = true

                pcall(function()

                    local polichinelos = LocalPlayer:FindFirstChild("PlayerGui")

                    if polichinelos then
                        polichinelos = polichinelos:FindFirstChild("Polichinelos")
                    end

                    if polichinelos then
                        polichinelos = polichinelos:FindFirstChild("Screen")
                    end

                    if polichinelos and active then

                        local found = false

                        for _, button in ipairs(polichinelos:GetChildren()) do

                            if stopRequested or not active or reachedLimit() then
                                stopAuto()
                                processingLock = false
                                return
                            end

                            if not button:IsA("ImageButton")
                                or not button.Visible
                                or processed[button]
                                or button:GetAttribute("Completed") then
                                continue
                            end

                            local label = button:FindFirstChildWhichIsA("TextLabel")

                            if not label or label.Text == "" then
                                continue
                            end

                            local keyText = tostring(label.Text):upper():gsub("%s+", "")

                            -- Travamento estrito antes de qualquer ação
                            if currentCount >= maxCount then
                                stopAuto()
                                processingLock = false
                                return
                            end

                            processed[button] = true
                            found = true

                            currentCount = currentCount + 1
                            if currentCount > maxCount then
                                currentCount = maxCount
                                stopAuto()
                                processingLock = false
                                return
                            end

                            if not UserInputService.TouchEnabled and KeyMap[keyText] then

                                local key = KeyMap[keyText]

                                pcall(function()
                                    VirtualInputManager:SendKeyEvent(
                                        true,
                                        key,
                                        false,
                                        game
                                    )

                                    task.wait(0.01)

                                    VirtualInputManager:SendKeyEvent(
                                        false,
                                        key,
                                        false,
                                        game
                                    )
                                end)

                            elseif button then

                                pcall(function()

                                    firesignal(button.MouseButton1Down)
                                    firesignal(button.MouseButton1Click)
                                    firesignal(button.TouchTap)

                                    button:Activate()

                                    local x =
                                        button.AbsolutePosition.X
                                        + button.AbsoluteSize.X / 2

                                    local y =
                                        button.AbsolutePosition.Y
                                        + button.AbsoluteSize.Y / 2

                                    VirtualInputManager:SendMouseButtonEvent(
                                        x,
                                        y,
                                        0,
                                        true,
                                        game,
                                        1
                                    )

                                    task.wait(0.01)

                                    VirtualInputManager:SendMouseButtonEvent(
                                        x,
                                        y,
                                        0,
                                        false,
                                        game,
                                        1
                                    )

                                end)
                            end

                            local remote = ReplicatedStorage:FindFirstChild("Remotes")

                            if remote then
                                remote = remote:FindFirstChild("Polichinelos")
                            end

                            if remote then
                                remote:FireServer("Add", 1)
                            end

                            if currentCount >= maxCount then
                                stopAuto()
                                processingLock = false
                                return
                            end

                            if interval > 0 then
                                task.wait(interval)
                            end

                            processingLock = false
                            return
                        end

                        if not found then
                            task.wait(0.1)
                        end
                    end

                end)

                processingLock = false

                if #processed > 15 then
                    table.clear(processed)
                end

            end
        end

    end)
end

DripExtras.Algema = function()
    --[[
        GUI Mobile Otimizada com Auto Spam de Resistência
        Tema Preto
        - Arrastável no mobile/PC
        - Botão minimizar
        - Botão flutuante para mostrar novamente
        - Botão fechar
        - by willz
    ]]

    local Players = game:GetService("Players")
    local Player = Players.LocalPlayer
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local RunService = game:GetService("RunService")

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ExecutorGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = Player:WaitForChild("PlayerGui")

    -- =========================================================
    -- JANELA PRINCIPAL
    -- =========================================================

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 340, 0, 210)
    MainFrame.Position = UDim2.new(0.5, -170, 0.5, -105)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 16)
    Corner.Parent = MainFrame

    -- =========================================================
    -- BARRA DE TÍTULO
    -- =========================================================

    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 50)
    TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame

    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 16)
    TitleCorner.Parent = TitleBar

    local TitleFix = Instance.new("Frame")
    TitleFix.Size = UDim2.new(1, 0, 0, 16)
    TitleFix.Position = UDim2.new(0, 0, 1, -16)
    TitleFix.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    TitleFix.BorderSizePixel = 0
    TitleFix.Parent = TitleBar

    local IconCircle = Instance.new("Frame")
    IconCircle.Size = UDim2.new(0, 10, 0, 10)
    IconCircle.Position = UDim2.new(0, 18, 0.5, -5)
    IconCircle.BackgroundColor3 = Color3.fromRGB(80, 150, 255)
    IconCircle.BorderSizePixel = 0
    IconCircle.Parent = TitleBar

    local IconCorner = Instance.new("UICorner")
    IconCorner.CornerRadius = UDim.new(1, 0)
    IconCorner.Parent = IconCircle

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -125, 1, 0)
    TitleLabel.Position = UDim2.new(0, 35, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "✦ Auto Soltar • by willz"
    TitleLabel.TextColor3 = Color3.new(1, 1, 1)
    TitleLabel.TextSize = 17
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.Parent = TitleBar

    -- =========================================================
    -- BOTÃO MINIMIZAR
    -- =========================================================

    local MinimizeButton = Instance.new("TextButton")
    MinimizeButton.Name = "MinimizeButton"
    MinimizeButton.Size = UDim2.new(0, 36, 0, 36)
    MinimizeButton.Position = UDim2.new(1, -86, 0.5, -18)
    MinimizeButton.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    MinimizeButton.BorderSizePixel = 0
    MinimizeButton.Text = "−"
    MinimizeButton.TextColor3 = Color3.fromRGB(220, 220, 220)
    MinimizeButton.TextSize = 24
    MinimizeButton.Font = Enum.Font.GothamBold
    MinimizeButton.Parent = TitleBar

    local MinCorner = Instance.new("UICorner")
    MinCorner.CornerRadius = UDim.new(1, 0)
    MinCorner.Parent = MinimizeButton

    -- =========================================================
    -- BOTÃO FECHAR
    -- =========================================================

    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.Size = UDim2.new(0, 36, 0, 36)
    CloseButton.Position = UDim2.new(1, -44, 0.5, -18)
    CloseButton.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    CloseButton.BorderSizePixel = 0
    CloseButton.Text = "✕"
    CloseButton.TextColor3 = Color3.fromRGB(220, 220, 220)
    CloseButton.TextSize = 18
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.Parent = TitleBar

    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(1, 0)
    CloseCorner.Parent = CloseButton

    -- =========================================================
    -- DIVISÓRIA
    -- =========================================================

    local Divider = Instance.new("Frame")
    Divider.Size = UDim2.new(1, -30, 0, 1)
    Divider.Position = UDim2.new(0, 15, 0, 50)
    Divider.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
    Divider.BackgroundTransparency = 0.5
    Divider.BorderSizePixel = 0
    Divider.Parent = MainFrame

    -- =========================================================
    -- CONTEÚDO
    -- =========================================================

    local ContentFrame = Instance.new("Frame")
    ContentFrame.Size = UDim2.new(1, 0, 1, -60)
    ContentFrame.Position = UDim2.new(0, 0, 0, 55)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Parent = MainFrame

    local DescLabel = Instance.new("TextLabel")
    DescLabel.Size = UDim2.new(1, -30, 0, 25)
    DescLabel.Position = UDim2.new(0, 15, 0, 5)
    DescLabel.BackgroundTransparency = 1
    DescLabel.Text = "Ative para disparar continuamente"
    DescLabel.TextColor3 = Color3.fromRGB(130, 130, 145)
    DescLabel.TextSize = 13
    DescLabel.Font = Enum.Font.Gotham
    DescLabel.TextXAlignment = Enum.TextXAlignment.Center
    DescLabel.Parent = ContentFrame

    -- =========================================================
    -- BOTÃO TOGGLE
    -- =========================================================

    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Name = "ToggleButton"
    ToggleButton.Size = UDim2.new(0, 240, 0, 50)
    ToggleButton.Position = UDim2.new(0.5, -120, 0.5, -2)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    ToggleButton.BorderSizePixel = 2
    ToggleButton.BorderColor3 = Color3.fromRGB(200, 50, 50)
    ToggleButton.Text = "AUTO SOLTAR: [ OFF ]"
    ToggleButton.TextColor3 = Color3.new(1, 1, 1)
    ToggleButton.TextSize = 15
    ToggleButton.Font = Enum.Font.GothamBold
    ToggleButton.Parent = ContentFrame

    local ButtonCorner = Instance.new("UICorner")
    ButtonCorner.CornerRadius = UDim.new(0, 10)
    ButtonCorner.Parent = ToggleButton

    -- =========================================================
    -- STATUS
    -- =========================================================

    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, -30, 0, 25)
    StatusLabel.Position = UDim2.new(0, 15, 1, -30)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "● Desativado"
    StatusLabel.TextColor3 = Color3.fromRGB(110, 110, 125)
    StatusLabel.TextSize = 13
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Center
    StatusLabel.Parent = ContentFrame

    -- =========================================================
    -- BOTÃO FLUTUANTE
    -- =========================================================

    local ShowButton = Instance.new("TextButton")
    ShowButton.Name = "ShowButton"
    ShowButton.Size = UDim2.new(0, 55, 0, 55)
    ShowButton.Position = UDim2.new(0, 20, 0.5, -27)
    ShowButton.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    ShowButton.BorderSizePixel = 2
    ShowButton.BorderColor3 = Color3.fromRGB(60, 110, 220)
    ShowButton.Text = "✦"
    ShowButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ShowButton.TextSize = 25
    ShowButton.Font = Enum.Font.GothamBold
    ShowButton.Visible = false
    ShowButton.Parent = ScreenGui

    local ShowCorner = Instance.new("UICorner")
    ShowCorner.CornerRadius = UDim.new(1, 0)
    ShowCorner.Parent = ShowButton

    -- =========================================================
    -- ARRASTAR
    -- =========================================================

    local dragging = false
    local dragInput
    local dragStart
    local startPos

    local function updateDrag(input)
    	local delta = input.Position - dragStart

    	MainFrame.Position = UDim2.new(
    		startPos.X.Scale,
    		startPos.X.Offset + delta.X,
    		startPos.Y.Scale,
    		startPos.Y.Offset + delta.Y
    	)
    end

    TitleBar.InputBegan:Connect(function(input)
    	if input.UserInputType == Enum.UserInputType.MouseButton1
    		or input.UserInputType == Enum.UserInputType.Touch then

    		dragging = true
    		dragStart = input.Position
    		startPos = MainFrame.Position

    		input.Changed:Connect(function()
    			if input.UserInputState == Enum.UserInputState.End then
    				dragging = false
    			end
    		end)
    	end
    end)

    TitleBar.InputChanged:Connect(function(input)
    	if input.UserInputType == Enum.UserInputType.MouseMovement
    		or input.UserInputType == Enum.UserInputType.Touch then

    		dragInput = input
    	end
    end)

    UserInputService.InputChanged:Connect(function(input)
    	if input == dragInput and dragging then
    		updateDrag(input)
    	end
    end)

    -- =========================================================
    -- MINIMIZAR
    -- =========================================================

    local function Minimize()
    	local tween = TweenService:Create(
    		MainFrame,
    		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
    		{
    			Size = UDim2.new(0, 340, 0, 0)
    		}
    	)

    	tween:Play()
    	tween.Completed:Wait()

    	MainFrame.Visible = false
    	ShowButton.Visible = true
    end

    MinimizeButton.Activated:Connect(Minimize)

    -- =========================================================
    -- MOSTRAR
    -- =========================================================

    local function ShowGUI()
    	ShowButton.Visible = false
    	MainFrame.Visible = true
    	MainFrame.Size = UDim2.new(0, 340, 0, 0)

    	TweenService:Create(
    		MainFrame,
    		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    		{
    			Size = UDim2.new(0, 340, 0, 210)
    		}
    	):Play()
    end

    ShowButton.Activated:Connect(ShowGUI)

    -- =========================================================
    -- FECHAR
    -- =========================================================

    CloseButton.Activated:Connect(function()
    	TweenService:Create(
    		MainFrame,
    		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
    		{
    			Size = UDim2.new(0, 0, 0, 0)
    		}
    	):Play()

    	task.wait(0.2)
    	ScreenGui:Destroy()
    end)

    -- =========================================================
    -- LÓGICA DO TOGGLE (SPAM DE RESISTÊNCIA)
    -- =========================================================

    local toggleState = false
    local spamLoop = nil

    local function ToggleAuto()
    	toggleState = not toggleState

    	if toggleState then
    		ToggleButton.Text = "AUTO SOLTAR: [ ON ]"
    		StatusLabel.Text = "● Disparando sem parar..."
    		StatusLabel.TextColor3 = Color3.fromRGB(80, 220, 100)

    		TweenService:Create(
    			ToggleButton,
    			TweenInfo.new(0.2),
    			{
    				BackgroundColor3 = Color3.fromRGB(20, 80, 30),
    				BorderColor3 = Color3.fromRGB(60, 200, 80)
    			}
    		):Play()

    		-- Inicia um loop utilizando Heartbeat para disparar o RemoteEvent continuamente enquanto o toggle estiver ativo
    		spamLoop = RunService.Heartbeat:Connect(function()
    			if not toggleState then return end
			
    			pcall(function()
    				local Event = ReplicatedStorage.Remotes.Events.Prison.Algemar
    				Event:FireServer("Resistência")
    			end)
    		end)
    	else
    		ToggleButton.Text = "AUTO SOLTAR: [ OFF ]"
    		StatusLabel.Text = "● Desativado"
    		StatusLabel.TextColor3 = Color3.fromRGB(110, 110, 125)

    		TweenService:Create(
    			ToggleButton,
    			TweenInfo.new(0.2),
    			{
    				BackgroundColor3 = Color3.fromRGB(30, 30, 40),
    				BorderColor3 = Color3.fromRGB(200, 50, 50)
    			}
    		):Play()

    		if spamLoop then
    			spamLoop:Disconnect()
    			spamLoop = nil
    		end
    	end
    end

    ToggleButton.Activated:Connect(ToggleAuto)

    -- =========================================================
    -- ANIMAÇÃO INICIAL
    -- =========================================================

    MainFrame.Size = UDim2.new(0, 0, 0, 0)

    task.wait(0.1)

    TweenService:Create(
    	MainFrame,
    	TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    	{
    		Size = UDim2.new(0, 340, 0, 210)
    	}
    ):Play()
end

DripExtras.Kart = function()
    -- ========================================================================
    -- HIPERCARRO V12 LUXURY EDITION - CART | by prodigizx
    -- ========================================================================

    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local Backpack = LocalPlayer:WaitForChild("Backpack")
    local RunService = game:GetService("RunService")
    local StarterGui = game:GetService("StarterGui")

    local isMounted = false
    local tool = nil
    local carModel = nil
    local bodyVelocity = nil
    local renderConnection = nil
    local currentSpeed = 0
    local displayedSpeed = 0 

    -- Variáveis da HUD Next-Gen
    local screenGui = nil
    local speedLabel = nil
    local gearLabel = nil
    local rpmBar = nil
    local fuelLabel = nil

    -- Configurações de Hipercarro
    local MAX_SPEED = 260       
    local ACCELERATION = 4.2    
    local DECELERATION = 5.5    
    local TURN_SPEED = 6.0      

    -- Função para exibir a notificação nativa no canto da tela
    local function showNotification()
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "CART EQUIPADO",
                Text = "Pronto para se tornar o Relâmpago Marquinhos",
                Duration = 5
            })
        end)
    end

    -- Função para criar a HUD Digital Next-Gen no topo esquerdo
    local function createSpeedometer()
        local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    
        if playerGui:FindFirstChild("CarHUD") then
            playerGui.CarHUD:Destroy()
        end

        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "CarHUD"
        screenGui.ResetOnSpawn = false
        screenGui.Enabled = false 

        local mainFrame = Instance.new("Frame")
        mainFrame.Name = "MainFrame"
        mainFrame.Size = UDim2.new(0, 230, 0, 80)
        mainFrame.Position = UDim2.new(0, 25, 0, 25)
        mainFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
        mainFrame.BackgroundTransparency = 0.15
        mainFrame.BorderSizePixel = 0
        mainFrame.Parent = screenGui

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = mainFrame

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(212, 175, 55) -- Dourado Luxo
        stroke.Transparency = 0.2
        stroke.Thickness = 2
        stroke.Parent = mainFrame

        speedLabel = Instance.new("TextLabel")
        speedLabel.Name = "SpeedLabel"
        speedLabel.Size = UDim2.new(0, 130, 0, 38)
        speedLabel.Position = UDim2.new(0, 12, 0, 5)
        speedLabel.BackgroundTransparency = 1
        speedLabel.Font = Enum.Font.GothamBlack
        speedLabel.Text = "0"
        speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        speedLabel.TextSize = 34
        speedLabel.TextXAlignment = Enum.TextXAlignment.Left
        speedLabel.Parent = mainFrame

        local unitLabel = Instance.new("TextLabel")
        unitLabel.Size = UDim2.new(0, 40, 0, 20)
        unitLabel.Position = UDim2.new(0, 95, 0, 18)
        unitLabel.BackgroundTransparency = 1
        unitLabel.Font = Enum.Font.GothamBold
        unitLabel.Text = "MPH"
        unitLabel.TextColor3 = Color3.fromRGB(212, 175, 55)
        unitLabel.TextSize = 13
        unitLabel.TextXAlignment = Enum.TextXAlignment.Left
        unitLabel.Parent = mainFrame

        gearLabel = Instance.new("TextLabel")
        gearLabel.Name = "GearLabel"
        gearLabel.Size = UDim2.new(0, 50, 0, 38)
        gearLabel.Position = UDim2.new(1, -62, 0, 5)
        gearLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
        gearLabel.Font = Enum.Font.GothamBlack
        gearLabel.Text = "N"
        gearLabel.TextColor3 = Color3.fromRGB(212, 175, 55)
        gearLabel.TextSize = 20
        gearLabel.Parent = mainFrame

        local gearCorner = Instance.new("UICorner")
        gearCorner.CornerRadius = UDim.new(0, 8)
        gearCorner.Parent = gearLabel

        local rpmBg = Instance.new("Frame")
        rpmBg.Size = UDim2.new(0, 206, 0, 6)
        rpmBg.Position = UDim2.new(0, 12, 0, 50)
        rpmBg.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
        rpmBg.BorderSizePixel = 0
        rpmBg.Parent = mainFrame

        local rpmBgCorner = Instance.new("UICorner")
        rpmBgCorner.CornerRadius = UDim.new(0, 3)
        rpmBgCorner.Parent = rpmBg

        rpmBar = Instance.new("Frame")
        rpmBar.Name = "RpmBar"
        rpmBar.Size = UDim2.new(0, 0, 1, 0)
        rpmBar.BackgroundColor3 = Color3.fromRGB(212, 175, 55)
        rpmBar.BorderSizePixel = 0
        rpmBar.Parent = rpmBg

        local rpmBarCorner = Instance.new("UICorner")
        rpmBarCorner.CornerRadius = UDim.new(0, 3)
        rpmBarCorner.Parent = rpmBar

        fuelLabel = Instance.new("TextLabel")
        fuelLabel.Name = "FuelLabel"
        fuelLabel.Size = UDim2.new(1, -24, 0, 16)
        fuelLabel.Position = UDim2.new(0, 12, 0, 58)
        fuelLabel.BackgroundTransparency = 1
        fuelLabel.Font = Enum.Font.GothamBold
        fuelLabel.Text = "✦ CART | by prodigizx"
        fuelLabel.TextColor3 = Color3.fromRGB(150, 140, 110)
        fuelLabel.TextSize = 9
        fuelLabel.TextXAlignment = Enum.TextXAlignment.Left
        fuelLabel.Parent = mainFrame

        screenGui.Parent = playerGui
    end

    -- Forward declarations
    local dismountCar
    local mountCar

    -- Ferramenta para equipar com o nome CART fixo na Hotbar
    local function createCarTool()
        if Backpack:FindFirstChild("CART") or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("CART")) then 
            return 
        end

        tool = Instance.new("Tool")
        tool.Name = "CART"
        tool.ToolTip = "CART"
        tool.RequiresHandle = true

        local handle = Instance.new("Part")
        handle.Name = "Handle"
        handle.Size = Vector3.new(1.0, 1.0, 1.0)
        handle.Transparency = 1 
        handle.CanCollide = false
        handle.Parent = tool

        tool.Unequipped:Connect(function()
            if isMounted then 
                dismountCar() 
            end
        end)

        tool.Activated:Connect(function()
            if not isMounted then 
                mountCar() 
            else 
                dismountCar() 
            end
        end)

        tool.Parent = Backpack
    end

    -- Função para montar no Hipercarro
    function mountCar()
        if isMounted then return end
    
        local character = LocalPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChild("Humanoid")
        if not rootPart or not humanoid then return end

        isMounted = true
        currentSpeed = 0
        displayedSpeed = 0

        humanoid.Sit = true
        humanoid.AutoRotate = false

        if screenGui then
            screenGui.Enabled = true
        end

        carModel = Instance.new("Model")
        carModel.Name = "CartModelProdigio"

        local chassis = Instance.new("Part")
        chassis.Name = "Chassis"
        chassis.Size = Vector3.new(4.2, 0.8, 9.4)
        chassis.CFrame = rootPart.CFrame * CFrame.new(0, -0.7, 0)
        chassis.Anchored = false
        chassis.CanCollide = true
        chassis.Massless = false
        chassis.Color = Color3.fromRGB(15, 15, 15)
        chassis.Material = Enum.Material.Glass
        chassis.Parent = carModel

        local goldStripe = Instance.new("Part")
        goldStripe.Size = Vector3.new(0.6, 0.85, 9.5)
        goldStripe.CFrame = chassis.CFrame * CFrame.new(0, 0.02, 0)
        goldStripe.Anchored = false
        goldStripe.CanCollide = false
        goldStripe.Color = Color3.fromRGB(212, 175, 55)
        goldStripe.Material = Enum.Material.Neon
        goldStripe.Parent = carModel

        local wStripe = Instance.new("WeldConstraint")
        wStripe.Part0 = chassis
        wStripe.Part1 = goldStripe
        wStripe.Parent = goldStripe

        local seatPart = Instance.new("Part")
        seatPart.Size = Vector3.new(2.2, 0.4, 2.2)
        seatPart.CFrame = chassis.CFrame * CFrame.new(0, 0.4, 0.2)
        seatPart.Anchored = false
        seatPart.CanCollide = false
        seatPart.Color = Color3.fromRGB(25, 25, 25)
        seatPart.Material = Enum.Material.SmoothPlastic
        seatPart.Parent = carModel

        local wSeat = Instance.new("WeldConstraint")
        wSeat.Part0 = chassis
        wSeat.Part1 = seatPart
        wSeat.Parent = seatPart

        local cabin = Instance.new("Part")
        cabin.Size = Vector3.new(3.1, 0.85, 3.8)
        cabin.CFrame = chassis.CFrame * CFrame.new(0, 0.95, 0.2)
        cabin.Anchored = false
        cabin.CanCollide = false
        cabin.Color = Color3.fromRGB(10, 10, 10)
        cabin.Material = Enum.Material.Glass
        cabin.Transparency = 0.2
        cabin.Parent = carModel

        local wCabin = Instance.new("WeldConstraint")
        wCabin.Part0 = chassis
        wCabin.Part1 = cabin
        wCabin.Parent = cabin

        local hood = Instance.new("Part")
        hood.Size = Vector3.new(3.6, 0.6, 3.4)
        hood.CFrame = chassis.CFrame * CFrame.new(0, 0.25, -3.0)
        hood.Anchored = false
        hood.CanCollide = false
        hood.Color = Color3.fromRGB(20, 20, 20)
        hood.Material = Enum.Material.SmoothPlastic
        hood.Parent = carModel

        local wHood = Instance.new("WeldConstraint")
        wHood.Part0 = chassis
        wHood.Part1 = hood
        wHood.Parent = hood

        for i = -1, 1, 2 do
            local led = Instance.new("Part")
            led.Size = Vector3.new(0.9, 0.18, 0.2)
            led.CFrame = hood.CFrame * CFrame.new(i * 1.2, -0.05, -1.7)
            led.Anchored = false
            led.CanCollide = false
            led.Color = Color3.fromRGB(255, 230, 120)
            led.Material = Enum.Material.Neon
            led.Parent = carModel

            local wLed = Instance.new("WeldConstraint")
            wLed.Part0 = chassis
            wLed.Part1 = led
            wLed.Parent = led
        end

        local wing = Instance.new("Part")
        wing.Size = Vector3.new(3.9, 0.25, 1.5)
        wing.CFrame = chassis.CFrame * CFrame.new(0, 1.2, 4.0)
        wing.Anchored = false
        wing.CanCollide = false
        wing.Color = Color3.fromRGB(10, 10, 10)
        wing.Material = Enum.Material.SmoothPlastic
        wing.Parent = carModel

        local wWing = Instance.new("WeldConstraint")
        wWing.Part0 = chassis
        wWing.Part1 = wing
        wWing.Parent = wing

        local wingAccent = Instance.new("Part")
        wingAccent.Size = Vector3.new(3.9, 0.08, 0.3)
        wingAccent.CFrame = wing.CFrame * CFrame.new(0, 0.12, 0)
        wingAccent.Anchored = false
        wingAccent.CanCollide = false
        wingAccent.Color = Color3.fromRGB(212, 175, 55)
        wingAccent.Material = Enum.Material.Neon
        wingAccent.Parent = carModel

        local wWingAccent = Instance.new("WeldConstraint")
        wWingAccent.Part0 = chassis
        wWingAccent.Part1 = wingAccent
        wWingAccent.Parent = wingAccent

        local wheelOffsets = {
            Vector3.new(2.3, -0.1, 3.1),   
            Vector3.new(-2.3, -0.1, 3.1),  
            Vector3.new(2.3, -0.1, -3.1),  
            Vector3.new(-2.3, -0.1, -3.1)  
        }

        for _, offset in ipairs(wheelOffsets) do
            local wheel = Instance.new("Part")
            wheel.Size = Vector3.new(1.1, 1.6, 1.6)
            wheel.CFrame = chassis.CFrame * CFrame.new(offset)
            wheel.Color = Color3.fromRGB(30, 30, 30)
            wheel.Material = Enum.Material.Metal
            wheel.CanCollide = false
            wheel.Shape = Enum.PartType.Cylinder
            wheel.Parent = carModel

            local wWheel = Instance.new("WeldConstraint")
            wWheel.Part0 = chassis
            wWheel.Part1 = wheel
            wWheel.Parent = wheel
        end

        local weld = Instance.new("WeldConstraint")
        weld.Part0 = rootPart
        weld.Part1 = chassis
        weld.Parent = chassis

        carModel.Parent = character

        bodyVelocity = Instance.new("LinearVelocity")
        bodyVelocity.Attachment0 = Instance.new("Attachment", rootPart)
        bodyVelocity.MaxForce = 60000
        bodyVelocity.VectorVelocity = Vector3.new(0, 0, 0)
        bodyVelocity.Parent = rootPart
        bodyVelocity.Attachment0.Position = Vector3.new(0, 0.2, 0)

        local currentLookVector = rootPart.CFrame.LookVector

        renderConnection = RunService.RenderStepped:Connect(function(dt)
            if not isMounted or not rootPart or not humanoid then return end
        
            humanoid.Sit = true
            local moveDir = humanoid.MoveDirection
        
            if moveDir.Magnitude > 0 then
                currentSpeed = math.min(currentSpeed + (ACCELERATION * (MAX_SPEED * dt)), MAX_SPEED)
            
                local targetLook = Vector3.new(moveDir.X, 0, moveDir.Z).Unit
                currentLookVector = currentLookVector:Lerp(targetLook, TURN_SPEED * dt)
            
                local targetVelocity = currentLookVector * currentSpeed
                bodyVelocity.VectorVelocity = Vector3.new(targetVelocity.X, math.min(rootPart.AssemblyLinearVelocity.Y, 2), targetVelocity.Z)
            
                rootPart.CFrame = CFrame.new(rootPart.Position, rootPart.Position + currentLookVector)
            else
                currentSpeed = math.max(currentSpeed - (DECELERATION * (MAX_SPEED * dt)), 0)
            
                if currentSpeed > 0 then
                    local targetVelocity = currentLookVector * currentSpeed
                    bodyVelocity.VectorVelocity = Vector3.new(targetVelocity.X, math.min(rootPart.AssemblyLinearVelocity.Y, 2), targetVelocity.Z)
                else
                    bodyVelocity.VectorVelocity = Vector3.new(0, -12, 0)
                end
            end

            displayedSpeed = displayedSpeed + (currentSpeed - displayedSpeed) * (dt * 4.0)

            if speedLabel then
                speedLabel.Text = math.floor(displayedSpeed)
            end

            if rpmBar then
                local rpmPercent = math.clamp(displayedSpeed / MAX_SPEED, 0, 1)
                rpmBar.Size = UDim2.new(rpmPercent, 0, 1, 0)
            
                if rpmPercent > 0.88 then
                    rpmBar.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
                else
                    rpmBar.BackgroundColor3 = Color3.fromRGB(212, 175, 55)
                end
            end

            if gearLabel then
                if displayedSpeed < 4 then
                    gearLabel.Text = "N"
                elseif displayedSpeed < 40 then
                    gearLabel.Text = "1"
                elseif displayedSpeed < 90 then
                    gearLabel.Text = "2"
                elseif displayedSpeed < 140 then
                    gearLabel.Text = "3"
                elseif displayedSpeed < 190 then
                    gearLabel.Text = "4"
                elseif displayedSpeed < 230 then
                    gearLabel.Text = "5"
                else
                    gearLabel.Text = "6"
                end
            end
        end)
    end

    -- Desmontar e restaurar o estado do personagem de forma limpa
    function dismountCar()
        if not isMounted then return end
        isMounted = false
        currentSpeed = 0
        displayedSpeed = 0

        if screenGui then
            screenGui.Enabled = false
        end

        if renderConnection then
            renderConnection:Disconnect()
            renderConnection = nil
        end

        if bodyVelocity then
            bodyVelocity:Destroy()
            bodyVelocity = nil
        end

        if carModel then
            carModel:Destroy()
            carModel = nil
        end

        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if humanoid then
                humanoid.Sit = false
                humanoid.AutoRotate = true
                task.delay(0.1, function()
                    if humanoid then
                        humanoid.PlatformStand = false
                    end
                end)
            end
            if rootPart then
                rootPart.CFrame = rootPart.CFrame + Vector3.new(0, 3, 0)
            end
        end
    end

    LocalPlayer.CharacterAdded:Connect(function(newChar)
        isMounted = false
        carModel = nil
        currentSpeed = 0
        displayedSpeed = 0
        task.wait(1)
        Backpack = newChar:WaitForChild("Backpack")
        createSpeedometer()
        createCarTool()
    end)

    createSpeedometer()
    createCarTool()
    showNotification()

    print("[CART] Carregado com sucesso! by: prodigizx")
end

DripExtras.FakePatente = function()
    -- ========================================================================
    -- SISTEMA RP DEFINITIVO - ABA DE CORES + SELETOR DE DEVICE (CELULAR/CONSOLE/PC)
    -- ========================================================================

    local Players = game:GetService("Players")
    local CoreGui = game:GetService("CoreGui")
    local UserInputService = game:GetService("UserInputService")
    local LocalPlayer = Players.LocalPlayer

    local isCustomTagActive = false
    local customData = {
        PlayerName = LocalPlayer.Name,
        RankText = "[CI] Cidadão",
        SubText = "N/A",
        RankColor = Color3.fromRGB(255, 220, 50),
        TextColor = Color3.fromRGB(255, 255, 255),
        DeviceType = "Nenhum" -- Opções: "Nenhum", "Celular", "Controle", "PC"
    }

    -- Função para limpar a tag original e aplicar a customizada
    local function activateCustomTag()
        local character = LocalPlayer.Character
        if not character then return end
        local head = character:FindFirstChild("Head")
        local humanoid = character:FindFirstChild("Humanoid")
        if not head or not humanoid then return end

        -- Desativa tag nativa do Roblox
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        humanoid.NameDisplayDistance = 0
        humanoid.HealthDisplayDistance = 0

        for _, obj in ipairs(head:GetChildren()) do
            if obj:IsA("BillboardGui") or obj.Name == "NameTag" or obj.Name == "RealRPTag" then
                obj:Destroy()
            end
        end
    
        for _, obj in ipairs(character:GetChildren()) do
            if obj:IsA("BillboardGui") or (obj:IsA("Model") and obj.Name == "HumanoidParameters") then
                obj:Destroy()
            end
        end

        -- Criação da Nova Tag
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "RealRPTag"
        billboard.Size = UDim2.new(0, 220, 0, 55)
        billboard.StudsOffset = Vector3.new(0, 2.0, 0)
        billboard.AlwaysOnTop = true
        billboard.Adornee = head

        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, 0, 1, 0)
        container.BackgroundTransparency = 1
        container.Parent = billboard

        local layout = Instance.new("UIListLayout")
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.VerticalAlignment = Enum.VerticalAlignment.Center
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, -3) -- Linhas bem coladas
        layout.Parent = container

        -- Linha 1: Device opcional + Ponto + Nick
        local line1 = Instance.new("TextLabel")
        line1.Size = UDim2.new(1, 0, 0, 16)
        line1.BackgroundTransparency = 1
        line1.TextColor3 = customData.TextColor
        line1.TextSize = 13
        line1.Font = Enum.Font.SourceSansBold
        line1.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        line1.TextStrokeTransparency = 0.2
        line1.LayoutOrder = 1

        local deviceIcon = ""
        if customData.DeviceType == "Celular" then
            deviceIcon = "📱 • "
        elseif customData.DeviceType == "Controle" then
            deviceIcon = "🎮 • "
        elseif customData.DeviceType == "PC" then
            deviceIcon = "💻 • "
        else
            deviceIcon = "" -- Nenhum
        end

        line1.Text = deviceIcon .. customData.PlayerName
        line1.Parent = container

        -- Linha 2: Cargo / Patente
        local line2 = Instance.new("TextLabel")
        line2.Size = UDim2.new(1, 0, 0, 15)
        line2.BackgroundTransparency = 1
        line2.Text = customData.RankText
        line2.TextColor3 = customData.RankColor
        line2.TextSize = 12
        line2.Font = Enum.Font.SourceSansBold
        line2.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        line2.TextStrokeTransparency = 0.2
        line2.LayoutOrder = 2
        line2.Parent = container

        -- Linha 3: Subtexto
        local line3 = Instance.new("TextLabel")
        line3.Size = UDim2.new(1, 0, 0, 14)
        line3.BackgroundTransparency = 1
        line3.Text = customData.SubText
        line3.TextColor3 = Color3.fromRGB(200, 200, 200)
        line3.TextSize = 11
        line3.Font = Enum.Font.SourceSansBold
        line3.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        line3.TextStrokeTransparency = 0.3
        line3.LayoutOrder = 3
        line3.Parent = container

        billboard.Parent = head
        isCustomTagActive = true
    end

    -- ========================================================================
    -- PAINEL DE CONTROLE ARRASTÁVEL COM ABAS (PRINCIPAL E CORES)
    -- ========================================================================
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RPControlPanel"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = CoreGui

    local openButton = Instance.new("TextButton")
    openButton.Size = UDim2.new(0, 110, 0, 35)
    openButton.Position = UDim2.new(0, 20, 0, 20)
    openButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    openButton.TextColor3 = Color3.fromRGB(0, 255, 128)
    openButton.Text = "⚙️ Painel Tag"
    openButton.TextSize = 14
    openButton.Font = Enum.Font.SourceSansBold
    openButton.Parent = screenGui

    local uiCornerBtn = Instance.new("UICorner")
    uiCornerBtn.CornerRadius = UDim.new(0, 8)
    uiCornerBtn.Parent = openButton

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 280, 0, 375)
    mainFrame.Position = UDim2.new(0, 140, 0, 20)
    mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = screenGui

    local uiCornerMain = Instance.new("UICorner")
    uiCornerMain.CornerRadius = UDim.new(0, 10)
    uiCornerMain.Parent = mainFrame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 32)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Painel RP - Completo"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 15
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = mainFrame

    -- Sistema de Arrastar a Janela
    local dragging, dragInput, dragStart, startPos
    titleLabel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)

    titleLabel.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Botões de Alternância de Abas (Configuração vs Cores)
    local tabMainBtn = Instance.new("TextButton")
    tabMainBtn.Size = UDim2.new(0, 130, 0, 26)
    tabMainBtn.Position = UDim2.new(0, 10, 0, 35)
    tabMainBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    tabMainBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    tabMainBtn.Text = "✏️ Configurações"
    tabMainBtn.TextSize = 12
    tabMainBtn.Font = Enum.Font.SourceSansBold
    tabMainBtn.Parent = mainFrame
    Instance.new("UICorner", tabMainBtn).CornerRadius = UDim.new(0, 5)

    local tabColorsBtn = Instance.new("TextButton")
    tabColorsBtn.Size = UDim2.new(0, 130, 0, 26)
    tabColorsBtn.Position = UDim2.new(0, 140, 0, 35)
    tabColorsBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    tabColorsBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
    tabColorsBtn.Text = "🎨 Paleta de Cores"
    tabColorsBtn.TextSize = 12
    tabColorsBtn.Font = Enum.Font.SourceSansBold
    tabColorsBtn.Parent = mainFrame
    Instance.new("UICorner", tabColorsBtn).CornerRadius = UDim.new(0, 5)

    -- Container da Aba de Configurações
    local configContainer = Instance.new("Frame")
    configContainer.Size = UDim2.new(1, 0, 1, -70)
    configContainer.Position = UDim2.new(0, 0, 0, 68)
    configContainer.BackgroundTransparency = 1
    configContainer.Visible = true
    configContainer.Parent = mainFrame

    local function createInput(name, placeholder, defaultText, posY)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0, 260, 0, 14)
        label.Position = UDim2.new(0, 10, 0, posY)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = Color3.fromRGB(180, 180, 180)
        label.TextSize = 11
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.SourceSansBold
        label.Parent = configContainer

        local box = Instance.new("TextBox")
        box.Size = UDim2.new(0, 260, 0, 24)
        box.Position = UDim2.new(0, 10, 0, posY + 14)
        box.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        box.TextColor3 = Color3.fromRGB(255, 255, 255)
        box.Text = defaultText
        box.PlaceholderText = placeholder
        box.TextSize = 12
        box.Font = Enum.Font.SourceSans
        box.Parent = configContainer

        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)
        return box
    end

    local nameBox = createInput("Seu Nick:", "Digite o nome...", customData.PlayerName, 0)
    local rankBox = createInput("Cargo / Patente:", "Digite o cargo...", customData.RankText, 45)
    local subBox = createInput("Subtexto:", "Digite o subtexto...", customData.SubText, 90)

    -- Seletor de Device (Nenhum, Celular, Controle, PC)
    local deviceLabel = Instance.new("TextLabel")
    deviceLabel.Size = UDim2.new(0, 260, 0, 14)
    deviceLabel.Position = UDim2.new(0, 10, 0, 135)
    deviceLabel.BackgroundTransparency = 1
    deviceLabel.Text = "Estilo do Device (Ícone):"
    deviceLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    deviceLabel.TextSize = 11
    deviceLabel.TextXAlignment = Enum.TextXAlignment.Left
    deviceLabel.Font = Enum.Font.SourceSansBold
    deviceLabel.Parent = configContainer

    local devices = {"Nenhum", "Celular", "Controle", "PC"}
    local devButtons = {}
    for i, devName in ipairs(devices) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 61, 0, 22)
        b.Position = UDim2.new(0, 10 + ((i-1) * 66), 0, 152)
        b.BackgroundColor3 = (customData.DeviceType == devName) and Color3.fromRGB(0, 170, 100) or Color3.fromRGB(60, 60, 60)
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.Text = devName
        b.TextSize = 10
        b.Font = Enum.Font.SourceSansBold
        b.Parent = configContainer
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)

        b.MouseButton1Click:Connect(function()
            customData.DeviceType = devName
            for _, btn in pairs(devButtons) do
                btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            end
            b.BackgroundColor3 = Color3.fromRGB(0, 170, 100)
        end)
        devButtons[devName] = b
    end

    local applyBtn = Instance.new("TextButton")
    applyBtn.Size = UDim2.new(0, 260, 0, 30)
    applyBtn.Position = UDim2.new(0, 10, 0, 235)
    applyBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 100)
    applyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    applyBtn.Text = "▶ Aplicar Tag Agora"
    applyBtn.TextSize = 13
    applyBtn.Font = Enum.Font.SourceSansBold
    applyBtn.Parent = configContainer
    Instance.new("UICorner", applyBtn).CornerRadius = UDim.new(0, 6)

    -- Container da Aba de Cores (Paleta Gigante + RGB)
    local colorsContainer = Instance.new("ScrollingFrame")
    colorsContainer.Size = UDim2.new(1, 0, 1, -70)
    colorsContainer.Position = UDim2.new(0, 0, 0, 68)
    colorsContainer.BackgroundTransparency = 1
    colorsContainer.Visible = false
    colorsContainer.CanvasSize = UDim2.new(0, 0, 0, 310)
    colorsContainer.ScrollBarThickness = 4
    colorsContainer.Parent = mainFrame

    local colorPaletteTitle = Instance.new("TextLabel")
    colorPaletteTitle.Size = UDim2.new(0, 260, 0, 15)
    colorPaletteTitle.Position = UDim2.new(0, 10, 0, 5)
    colorPaletteTitle.BackgroundTransparency = 1
    colorPaletteTitle.Text = "Paleta Completa (Do Claro ao Escuro):"
    colorPaletteTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
    colorPaletteTitle.TextSize = 11
    colorPaletteTitle.TextXAlignment = Enum.TextXAlignment.Left
    colorPaletteTitle.Font = Enum.Font.SourceSansBold
    colorPaletteTitle.Parent = colorsContainer

    -- Matriz gigante de cores organizadas por tons
    local colorPalette = {
        -- Azuis (Claro ao Escuro)
        Color3.fromRGB(180, 220, 255), Color3.fromRGB(100, 180, 255), Color3.fromRGB(50, 130, 255), Color3.fromRGB(0, 80, 200), Color3.fromRGB(0, 40, 120),
        -- Vermelhos e Rosas (Claro ao Escuro)
        Color3.fromRGB(255, 180, 180), Color3.fromRGB(255, 100, 100), Color3.fromRGB(230, 40, 40), Color3.fromRGB(160, 10, 10), Color3.fromRGB(90, 0, 0),
        -- Verdes (Claro ao Escuro)
        Color3.fromRGB(180, 255, 180), Color3.fromRGB(100, 255, 100), Color3.fromRGB(40, 200, 40), Color3.fromRGB(10, 130, 10), Color3.fromRGB(0, 70, 0),
        -- Amarelos e Laranjas (Claro ao Escuro)
        Color3.fromRGB(255, 255, 150), Color3.fromRGB(255, 220, 50), Color3.fromRGB(255, 165, 0), Color3.fromRGB(210, 100, 0), Color3.fromRGB(130, 50, 0),
        -- Roxos e Magentas (Claro ao Escuro)
        Color3.fromRGB(230, 180, 255), Color3.fromRGB(180, 100, 255), Color3.fromRGB(130, 30, 220), Color3.fromRGB(80, 0, 150), Color3.fromRGB(40, 0, 80),
        -- Cinzas e Pretos (Claro ao Escuro)
        Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 200), Color3.fromRGB(130, 130, 130), Color3.fromRGB(70, 70, 70), Color3.fromRGB(20, 20, 20)
    }

    for i, col in ipairs(colorPalette) do
        local row = math.floor((i - 1) / 5)
        local colIdx = (i - 1) % 5

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 48, 0, 24)
        btn.Position = UDim2.new(0, 10 + (colIdx * 53), 0, 25 + (row * 28))
        btn.BackgroundColor3 = col
        btn.Text = ""
        btn.Parent = colorsContainer
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

        btn.MouseButton1Click:Connect(function()
            customData.RankColor = col
        end)
    end

    -- Entrada RGB personalizada na aba de cores
    local rgbLabel = Instance.new("TextLabel")
    rgbLabel.Size = UDim2.new(0, 260, 0, 15)
    rgbLabel.Position = UDim2.new(0, 10, 0, 200)
    rgbLabel.BackgroundTransparency = 1
    rgbLabel.Text = "Ou digite o valor RGB (ex: 255,100,0):"
    rgbLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    rgbLabel.TextSize = 11
    rgbLabel.TextXAlignment = Enum.TextXAlignment.Left
    rgbLabel.Font = Enum.Font.SourceSansBold
    rgbLabel.Parent = colorsContainer

    local rgbBox = Instance.new("TextBox")
    rgbBox.Size = UDim2.new(0, 260, 0, 26)
    rgbBox.Position = UDim2.new(0, 10, 0, 218)
    rgbBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    rgbBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    rgbBox.PlaceholderText = "R, G, B (0-255)"
    rgbBox.TextSize = 12
    rgbBox.Font = Enum.Font.SourceSans
    rgbBox.Parent = colorsContainer
    Instance.new("UICorner", rgbBox).CornerRadius = UDim.new(0, 5)

    rgbBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local r, g, b = rgbBox.Text:match("(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
            if r and g and b then
                customData.RankColor = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
            end
        end
    end)

    -- Troca de Abas (Comportamento Visual)
    tabMainBtn.MouseButton1Click:Connect(function()
        configContainer.Visible = true
        colorsContainer.Visible = false
        tabMainBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        tabMainBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        tabColorsBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        tabColorsBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
    end)

    tabColorsBtn.MouseButton1Click:Connect(function()
        configContainer.Visible = false
        colorsContainer.Visible = true
        tabColorsBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        tabColorsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        tabMainBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        tabMainBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
    end)

    openButton.MouseButton1Click:Connect(function()
        mainFrame.Visible = not mainFrame.Visible
    end)

    applyBtn.MouseButton1Click:Connect(function()
        customData.PlayerName = nameBox.Text
        customData.RankText = rankBox.Text
        customData.SubText = subBox.Text
    
        activateCustomTag()
        mainFrame.Visible = false
    end)

    LocalPlayer.CharacterAdded:Connect(function(newCharacter)
        task.wait(1)
        if isCustomTagActive then
            activateCustomTag()
        end
    end)
end

DripExtras.Gravador = function()
    -- ======================================================================== --
    -- GRAVADOR DE ROTA PARA O DRIP AUTO PARKOUR (COM TESTE E CORREÇÃO)
    -- ======================================================================== --

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer

    -- Cria uma interface simples na tela para controlar a gravação e testes
    local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
    ScreenGui.Name = "PathRecorderGui"
    ScreenGui.ResetOnSpawn = false

    local MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.Size = UDim2.new(0, 220, 0, 200)
    MainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true

    local UICorner = Instance.new("UICorner", MainFrame)
    UICorner.CornerRadius = UDim.new(0, 8)

    local Title = Instance.new("TextLabel", MainFrame)
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.BackgroundTransparency = 1
    Title.Font = Enum.Font.GothamBold
    Title.Text = "GRAVADOR DRIP"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 12

    local StatusLabel = Instance.new("TextLabel", MainFrame)
    StatusLabel.Size = UDim2.new(1, -20, 0, 25)
    StatusLabel.Position = UDim2.new(0, 10, 0, 30)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.Text = "Status: Parado"
    StatusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    StatusLabel.TextSize = 11

    -- Botão Gravar / Parar
    local RecordBtn = Instance.new("TextButton", MainFrame)
    RecordBtn.Size = UDim2.new(1, -20, 0, 32)
    RecordBtn.Position = UDim2.new(0, 10, 0, 60)
    RecordBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    RecordBtn.Font = Enum.Font.GothamBold
    RecordBtn.Text = "INICIAR GRAVAÇÃO"
    RecordBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    RecordBtn.TextSize = 11
    local BtnCorner = Instance.new("UICorner", RecordBtn)
    BtnCorner.CornerRadius = UDim.new(0, 6)

    -- Botão Testar Rota Gravada
    local TestBtn = Instance.new("TextButton", MainFrame)
    TestBtn.Size = UDim2.new(1, -20, 0, 32)
    TestBtn.Position = UDim2.new(0, 10, 0, 98)
    TestBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 180)
    TestBtn.Font = Enum.Font.GothamBold
    TestBtn.Text = "▶ TESTAR ROTA GRAVADA"
    TestBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    TestBtn.TextSize = 11
    local TestCorner = Instance.new("UICorner", TestBtn)
    TestCorner.CornerRadius = UDim.new(0, 6)

    -- Botão Copiar Resultado
    local CopyBtn = Instance.new("TextButton", MainFrame)
    CopyBtn.Size = UDim2.new(1, -20, 0, 32)
    CopyBtn.Position = UDim2.new(0, 10, 0, 136)
    CopyBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    CopyBtn.Font = Enum.Font.GothamBold
    CopyBtn.Text = "COPIAR CÓDIGO GERADO"
    CopyBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    CopyBtn.TextSize = 11
    local CopyCorner = Instance.new("UICorner", CopyBtn)
    CopyCorner.CornerRadius = UDim.new(0, 6)

    local recordedData = {}
    local isRecording = false
    local recordingConnection = nil
    local playbackConnection = nil
    local startTime = 0
    local antigravidade = nil
    local originalCollides = {}

    local function stopPlayback()
        if playbackConnection then
            playbackConnection:Disconnect()
            playbackConnection = nil
        end
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if antigravidade then
            antigravidade:Destroy()
            antigravidade = nil
        end
        if hum then
            hum.AutoRotate = true
        end
        for parte, status in pairs(originalCollides) do
            if parte and parte.Parent then
                parte.CanCollide = status
            end
        end
        table.clear(originalCollides)
    end

    RecordBtn.MouseButton1Click:Connect(function()
        if playbackConnection then stopPlayback() end
        isRecording = not isRecording
    
        if isRecording then
            recordedData = {}
            startTime = os.clock()
            RecordBtn.Text = "PARAR GRAVAÇÃO"
            RecordBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
            StatusLabel.Text = "Status: Gravando..."
        
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")
        
            if not hrp then return end
        
            recordingConnection = RunService.Heartbeat:Connect(function()
                local currentTime = os.clock() - startTime
                local cf = hrp.CFrame
                local vel = hrp.AssemblyLinearVelocity
                local state = hum and hum:GetState() or Enum.HumanoidStateType.Running
            
                table.insert(recordedData, {
                    Time = currentTime,
                    CF = {cf:GetComponents()},
                    Velocity = {vel.X, vel.Y, vel.Z},
                    State = state
                })
            end)
        else
            if recordingConnection then
                recordingConnection:Disconnect()
                recordingConnection = nil
            end
            RecordBtn.Text = "INICIAR GRAVAÇÃO"
            RecordBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
            StatusLabel.Text = "Status: Gravado! (" .. #recordedData .. " pts)"
        end
    end)

    -- Sistema de Testar a Rota Gravada Localmente
    TestBtn.MouseButton1Click:Connect(function()
        if isRecording then
            StatusLabel.Text = "Pare a gravação antes de testar!"
            return
        end
        if #recordedData == 0 then
            StatusLabel.Text = "Nenhuma rota gravada!"
            return
        end
    
        if playbackConnection then
            stopPlayback()
            StatusLabel.Text = "Status: Teste cancelado."
            return
        end

        StatusLabel.Text = "Status: Reproduzindo teste..."
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        if not hrp or not hum then return end

        local startCF = CFrame.new(unpack(recordedData[1].CF))
        hum.WalkSpeed = 22
        hum:MoveTo(startCF.Position)

        local reached = false
        local conn
        conn = hum.MoveToFinished:Connect(function()
            reached = true
            if conn then conn:Disconnect() end
        end)

        local timeout = tick() + 4
        while not reached and tick() < timeout do
            task.wait(0.1)
        end
        if conn then conn:Disconnect() end

        hum.AutoRotate = false
        antigravidade = Instance.new("BodyForce", hrp)
        antigravidade.Force = Vector3.new(0, 0, 0)

        for _, parte in ipairs(char:GetChildren()) do
            if parte:IsA("BasePart") then
                originalCollides[parte] = parte.CanCollide
                parte.CanCollide = false
            end
        end

        local pstartTime = os.clock()
        local totalPoints = #recordedData
        local currentIndex = 1

        playbackConnection = RunService.Heartbeat:Connect(function()
            local elapsedTime = os.clock() - pstartTime
            while currentIndex < totalPoints and elapsedTime >= recordedData[currentIndex + 1].Time do
                currentIndex = currentIndex + 1
            end
            if currentIndex >= totalPoints then
                stopPlayback()
                StatusLabel.Text = "Status: Teste concluído!"
                return
            end
        
            local p0 = recordedData[currentIndex]
            local p1 = recordedData[currentIndex + 1]
            local alpha = (p1.Time - p0.Time > 0) and math.clamp((elapsedTime - p0.Time) / (p1.Time - p0.Time), 0, 1) or 1
        
            local cf0 = CFrame.new(unpack(p0.CF))
            local cf1 = CFrame.new(unpack(p1.CF))
            hrp.CFrame = cf0:Lerp(cf1, alpha)

            local totalMass = 0
            for _, parte in ipairs(char:GetChildren()) do
                if parte:IsA("BasePart") then
                    totalMass = totalMass + parte:GetMass()
                end
            end
            if antigravidade and antigravidade.Parent then
                antigravidade.Force = Vector3.new(0, totalMass * workspace.Gravity, 0)
            end
            if p1.Velocity then
                hrp.AssemblyLinearVelocity = Vector3.new(p1.Velocity[1], p1.Velocity[2], p1.Velocity[3])
            end
            if p0.State then
                pcall(function()
                    hum:ChangeState(p0.State)
                end)
            end
        end)
    end)

    CopyBtn.MouseButton1Click:Connect(function()
        if #recordedData == 0 then
            StatusLabel.Text = "Status: Nada gravado ainda!"
            return
        end
    
        local result = "return {\n"
        for _, node in ipairs(recordedData) do
            local cfStr = table.concat(node.CF, ", ")
            local velStr = table.concat(node.Velocity, ", ")
            local stateName = typeof(node.State) == "EnumItem" and node.State.Name or "Running"
        
            result = result .. string.format("    {Time = %.3f, CF = {%s}, Velocity = {%s}, State = Enum.HumanoidStateType.%s},\n", 
                node.Time, cfStr, velStr, stateName)
        end
        result = result .. "}"
    
        if setclipboard then
            setclipboard(result)
            StatusLabel.Text = "Status: Copiado com sucesso!"
        else
            StatusLabel.Text = "Status: Sem suporte a clipboard (veja F9)."
            print(result)
        end
    end)
end

DripExtras.Hierarquia = function()
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")

    local Player = Players.LocalPlayer

    local Ranks = {
        {
            Category = "Hierarquia Militar",
            Ranks = {
                {"CR", "Criador"},
                {"SCR", "Sub Criador"},
            }
        },
        {
            Category = "Administração",
            Ranks = {
                {"ADM-G", "Administrador Geral"},
                {"ADM", "Administrador"},
                {"SUP-ADM", "Supervisor Administrativo"},
                {"MOD", "Moderador"},
            }
        },
        {
            Category = "Supremacia",
            Ranks = {
                {"SC", "Sócios"},
            }
        },
        {
            Category = "Alto Comando",
            Ranks = {
                {"CMT", "Comandante"},
                {"SCMT", "Subcomandante"},
            }
        },
        {
            Category = "Oficiais da Elite",
            Ranks = {
                {"ER", "Elite Real"},
                {"ES", "Elite Secreta"},
                {"EM", "Elite Militar"},
            }
        },
        {
            Category = "Oficiais Generais",
            Ranks = {
                {"GEN EX", "General de Exército"},
                {"GEN DV", "General de Divisão"},
                {"GEN BDA", "General de Brigada"},
            }
        },
        {
            Category = "Oficiais Superiores",
            Ranks = {
                {"CEL", "Coronel"},
                {"TEN-CEL", "Tenente Coronel"},
                {"MAJ", "Major"},
            }
        },
        {
            Category = "Oficiais Intermediários",
            Ranks = {
                {"CAP", "Capitão"},
            }
        },
        {
            Category = "Oficiais Subalternos",
            Ranks = {
                {"1° TEN", "Primeiro Tenente"},
                {"2° TEN", "Segundo Tenente"},
                {"ASP", "Aspirante a Oficial"},
            }
        },
        {
            Category = "Praças Especiais",
            Ranks = {
                {"CT", "Cadete"},
            }
        },
        {
            Category = "Graduados",
            Ranks = {
                {"ST", "Subtenente"},
                {"1° SGT", "Primeiro Sargento"},
                {"2° SGT", "Segundo Sargento"},
                {"3° SGT", "Terceiro Sargento"},
            }
        },
        {
            Category = "Praças",
            Ranks = {
                {"CB", "Cabo"},
                {"SLD", "Soldado"},
                {"REC", "Recruta"},
            }
        }
    }

    local function Create(class, properties, parent)
        local object = Instance.new(class)

        for property, value in pairs(properties or {}) do
            object[property] = value
        end

        object.Parent = parent
        return object
    end

    local ScreenGui = Create("ScreenGui", {
        Name = "HierarquiaMilitar",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    }, Player:WaitForChild("PlayerGui"))

    local Main = Create("Frame", {
        Name = "Main",
        Size = UDim2.new(0, 360, 0, 430),
        Position = UDim2.new(0.5, -180, 0.5, -215),
        BackgroundColor3 = Color3.fromRGB(9, 9, 9),
        BorderSizePixel = 0,
        ClipsDescendants = true
    }, ScreenGui)

    Create("UICorner", {
        CornerRadius = UDim.new(0, 10)
    }, Main)

    Create("UIStroke", {
        Color = Color3.fromRGB(40, 40, 40),
        Thickness = 1
    }, Main)

    local Top = Create("Frame", {
        Name = "Top",
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = Color3.fromRGB(14, 14, 14),
        BorderSizePixel = 0
    }, Main)

    Create("UICorner", {
        CornerRadius = UDim.new(0, 10)
    }, Top)

    local Title = Create("TextLabel", {
        Size = UDim2.new(1, -105, 0, 24),
        Position = UDim2.new(0, 13, 0, 7),
        BackgroundTransparency = 1,
        Text = "HIERARQUIA MILITAR",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left
    }, Top)

    local By = Create("TextLabel", {
        Size = UDim2.new(1, -105, 0, 17),
        Position = UDim2.new(0, 13, 0, 30),
        BackgroundTransparency = 1,
        Text = "By Willz",
        TextColor3 = Color3.fromRGB(105, 105, 105),
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left
    }, Top)

    local Minimize = Create("TextButton", {
        Size = UDim2.new(0, 32, 0, 30),
        Position = UDim2.new(1, -72, 0, 13),
        BackgroundColor3 = Color3.fromRGB(24, 24, 24),
        Text = "—",
        TextColor3 = Color3.fromRGB(225, 225, 225),
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false
    }, Top)

    Create("UICorner", {
        CornerRadius = UDim.new(0, 7)
    }, Minimize)

    local Close = Create("TextButton", {
        Size = UDim2.new(0, 32, 0, 30),
        Position = UDim2.new(1, -36, 0, 13),
        BackgroundColor3 = Color3.fromRGB(24, 24, 24),
        Text = "×",
        TextColor3 = Color3.fromRGB(255, 90, 90),
        TextSize = 19,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false
    }, Top)

    Create("UICorner", {
        CornerRadius = UDim.new(0, 7)
    }, Close)

    local Scroll = Create("ScrollingFrame", {
        Name = "Ranks",
        Size = UDim2.new(1, -14, 1, -64),
        Position = UDim2.new(0, 7, 0, 61),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Color3.fromRGB(65, 65, 65),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    }, Main)

    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 2),
        PaddingRight = UDim.new(0, 4),
        PaddingTop = UDim.new(0, 2),
        PaddingBottom = UDim.new(0, 8)
    }, Scroll)

    Create("UIListLayout", {
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, Scroll)

    local function Notify(message)
        local notification = Create("TextLabel", {
            Size = UDim2.new(0, 190, 0, 36),
            Position = UDim2.new(0.5, -95, 1, -48),
            BackgroundColor3 = Color3.fromRGB(20, 20, 20),
            Text = message,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 11,
            Font = Enum.Font.GothamMedium,
            ZIndex = 50
        }, Main)

        Create("UICorner", {
            CornerRadius = UDim.new(0, 7)
        }, notification)

        Create("UIStroke", {
            Color = Color3.fromRGB(45, 45, 45),
            Thickness = 1
        }, notification)

        task.delay(1.3, function()
            if notification then
                notification:Destroy()
            end
        end)
    end

    local function CopyRank(rankName)
        if setclipboard then
            setclipboard(rankName)
            Notify("Copiado: " .. rankName)
        elseif toclipboard then
            toclipboard(rankName)
            Notify("Copiado: " .. rankName)
        else
            Notify("Clipboard não suportado.")
        end
    end

    local order = 0

    for _, category in ipairs(Ranks) do
        order += 1

        Create("TextLabel", {
            LayoutOrder = order,
            Size = UDim2.new(1, -4, 0, 23),
            BackgroundTransparency = 1,
            Text = category.Category,
            TextColor3 = Color3.fromRGB(220, 220, 220),
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left
        }, Scroll)

        for _, rank in ipairs(category.Ranks) do
            order += 1

            local abbreviation = rank[1]
            local rankName = rank[2]

            local Row = Create("Frame", {
                LayoutOrder = order,
                Size = UDim2.new(1, -4, 0, 38),
                BackgroundColor3 = Color3.fromRGB(16, 16, 16),
                BorderSizePixel = 0
            }, Scroll)

            Create("UICorner", {
                CornerRadius = UDim.new(0, 7)
            }, Row)

            Create("TextLabel", {
                Size = UDim2.new(1, -88, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = "[" .. abbreviation .. "]  " .. rankName,
                TextColor3 = Color3.fromRGB(235, 235, 235),
                TextSize = 10,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd
            }, Row)

            local Copy = Create("TextButton", {
                Size = UDim2.new(0, 67, 0, 27),
                Position = UDim2.new(1, -74, 0.5, -13),
                BackgroundColor3 = Color3.fromRGB(35, 145, 70),
                Text = "COPIAR",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 9,
                Font = Enum.Font.GothamBold,
                AutoButtonColor = false
            }, Row)

            Create("UICorner", {
                CornerRadius = UDim.new(0, 6)
            }, Copy)

            Copy.MouseEnter:Connect(function()
                Copy.BackgroundColor3 = Color3.fromRGB(45, 175, 85)
            end)

            Copy.MouseLeave:Connect(function()
                Copy.BackgroundColor3 = Color3.fromRGB(35, 145, 70)
            end)

            Copy.MouseButton1Click:Connect(function()
                CopyRank(rankName)
            end)
        end
    end

    local dragging = false
    local dragStart
    local startPosition

    Top.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            dragStart = input.Position
            startPosition = Main.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging then
            if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then

                local delta = input.Position - dragStart

                Main.Position = UDim2.new(
                    startPosition.X.Scale,
                    startPosition.X.Offset + delta.X,
                    startPosition.Y.Scale,
                    startPosition.Y.Offset + delta.Y
                )
            end
        end
    end)

    local minimized = false

    Minimize.MouseButton1Click:Connect(function()
        minimized = not minimized

        if minimized then
            Scroll.Visible = false
            Main.Size = UDim2.new(0, 360, 0, 56)
            Minimize.Text = "+"
        else
            Scroll.Visible = true
            Main.Size = UDim2.new(0, 360, 0, 430)
            Minimize.Text = "—"
        end
    end)

    Close.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)
end

DripExtras.LaserGun = function()
    -- Configurações principais
    local Tool = Instance.new("Tool")
    local Handle = Instance.new("Part")
    Handle.Name = "Handle"
    Handle.Size = Vector3.new(1, 1, 1)
    Handle.Transparency = 1  -- Torna invisível
    Handle.CanCollide = false
    Handle.Parent = Tool

    -- Configuração de sons (substitua pelos IDs reais)
    local FireSound = Instance.new("Sound")
    FireSound.Name = "Fire"
    FireSound.SoundId = "rbxassetid://130785434"  -- Som de laser
    FireSound.Volume = 0.7
    FireSound.Parent = Handle

    local ReloadSound = Instance.new("Sound")
    ReloadSound.Name = "Reload"
    ReloadSound.SoundId = "rbxassetid://131147061"  -- Som de recarga
    ReloadSound.Volume = 0.5
    ReloadSound.Parent = Handle

    local HitFadeSound = Instance.new("Sound")
    HitFadeSound.Name = "HitFade"
    HitFadeSound.SoundId = "rbxassetid://138186576"  -- Som de impacto
    HitFadeSound.Volume = 0.8
    HitFadeSound.Parent = Handle

    -- Configuração de luz
    local PointLight = Instance.new("PointLight")
    PointLight.Name = "PointLight"
    PointLight.Brightness = 5
    PointLight.Range = 10
    PointLight.Color = Color3.fromRGB(0, 255, 255)
    PointLight.Enabled = false  -- Só liga quando equipado
    PointLight.Parent = Handle

    -- Variáveis globais
    local Players = game:GetService("Players")
    local Debris = game:GetService("Debris")
    local RunService = game:GetService("RunService")

    local Speed = 100
    local Duration = 5
    local NozzleOffset = Vector3.new(0, 0.4, -1.1)
    local ToolEnabled = true

    -- Referências
    local Character, Player, Humanoid

    -- Função para criar o projétil base
    local function CreateBaseShot()
        local BaseShot = Instance.new("Part")
        BaseShot.Name = "LaserShot"
        BaseShot.BrickColor = BrickColor.new("Toothpaste")
        BaseShot.Material = Enum.Material.Neon
        BaseShot.Shape = Enum.PartType.Block
        BaseShot.Size = Vector3.new(0.2, 0.2, 3)
        BaseShot.CanCollide = false
        BaseShot.Locked = true
        BaseShot.Anchored = false
    
        -- Efeitos visuais
        local SelectionBox = Instance.new("SelectionBox")
        SelectionBox.Adornee = BaseShot
        SelectionBox.Color3 = Color3.fromRGB(0, 255, 255)
        SelectionBox.LineThickness = 0.05
        SelectionBox.Parent = BaseShot
    
        local Light = Instance.new("PointLight")
        Light.Brightness = 10
        Light.Range = 8
        Light.Color = Color3.fromRGB(0, 255, 255)
        Light.Parent = BaseShot
    
        -- Som de impacto
        local Sound = HitFadeSound:Clone()
        Sound.Parent = BaseShot
    
        return BaseShot
    end

    -- Função para equipar a ferramenta
    local function Equipped()
        Character = Tool.Parent
        Player = Players:GetPlayerFromCharacter(Character)
        Humanoid = Character:FindFirstChildOfClass("Humanoid")
    
        if Humanoid then
            PointLight.Enabled = true
        end
    end

    -- Função para desequipar
    local function Unequipped()
        PointLight.Enabled = false
    end

    -- Função para marcar o humanoide
    local function TagHumanoid(humanoid, player)
        local CreatorTag = Instance.new("ObjectValue")
        CreatorTag.Name = "creator"
        CreatorTag.Value = player
        Debris:AddItem(CreatorTag, 2)
        CreatorTag.Parent = humanoid
    end

    -- Função para encontrar o personagem atingido
    local function FindCharacterAncestor(part)
        if part and part ~= workspace then
            local humanoid = part:FindFirstChildOfClass("Humanoid")
            if humanoid then
                return part, humanoid
            else
                return FindCharacterAncestor(part.Parent)
            end
        end
        return nil
    end

    -- Efeito de desmaterialização
    local function Dematerialize(character, humanoid, hitPart)
        if not character or not humanoid then return end
    
        humanoid.WalkSpeed = 0
    
        -- Congela todas as partes
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Anchored = true
                part.Transparency = 0
            
                -- Adiciona efeito visual
                local box = Instance.new("SelectionBox")
                box.Adornee = part
                box.Color3 = Color3.fromRGB(0, 255, 255)
                box.Parent = part
            
                local light = Instance.new("PointLight")
                light.Color = Color3.fromRGB(0, 255, 255)
                light.Brightness = 5
                light.Range = 5
                light.Parent = part
            elseif part:IsA("Script") or part:IsA("LocalScript") then
                part:Destroy()
            end
        end
    
        -- Efeito de fade out
        for i = 0, 1, 0.05 do
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Transparency = i
                end
            end
            wait(0.05)
        end
    
        -- Destroi o personagem
        character:BreakJoints()
        humanoid.Health = 0
        Debris:AddItem(character, 1)
    end

    -- Função de disparo
    local function Activated()
        if not ToolEnabled or not Humanoid or Humanoid.Health <= 0 then return end
    
        ToolEnabled = false
        FireSound:Play()
    
        -- Calcula a direção do disparo
        local handleCF = Handle.CFrame
        local startPos = handleCF.Position + handleCF:VectorToWorldSpace(NozzleOffset)
    
        -- Usa a posição do mouse ou frente do personagem
        local targetPos
        if Player then
            local mouse = Player:GetMouse()
            targetPos = mouse.Hit.Position
        else
            targetPos = startPos + (Humanoid.RootPart.CFrame.LookVector * 100)
        end
    
        local direction = (targetPos - startPos).Unit
    
        -- Cria o projétil
        local laser = CreateBaseShot()
        laser.CFrame = CFrame.new(startPos, startPos + direction) * CFrame.new(0, 0, -laser.Size.Z/2)
        laser.Parent = workspace
    
        -- Movimentação do projétil
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Velocity = direction * Speed
        bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bodyVelocity.Parent = laser
    
        -- Detecção de colisão
        laser.Touched:Connect(function(hit)
            if not hit or not hit.Parent then return end
        
            local character, humanoid = FindCharacterAncestor(hit)
            if character and humanoid and character ~= Character then
                -- Toca o som de impacto
                if laser:FindFirstChild("HitFade") then
                    local sound = laser:FindFirstChild("HitFade")
                    sound.Parent = hit
                    sound:Play()
                end
            
                -- Aplica o efeito
                Dematerialize(character, humanoid, hit)
            end
        
            laser:Destroy()
        end)
    
        -- Remove o projétil após um tempo
        Debris:AddItem(laser, Duration)
    
        -- Tempo de recarga
        wait(0.5)
        ReloadSound:Play()
        wait(0.5)
        ToolEnabled = true
    end

    -- Conexões de eventos
    Tool.Equipped:Connect(Equipped)
    Tool.Unequipped:Connect(Unequipped)
    Tool.Activated:Connect(Activated)

    -- Finaliza a ferramenta
    Tool.Name = "LaserGun"
    Tool.ToolTip = "Disintegrator Ray"
    Tool.Parent = game.Players.LocalPlayer.Backpack
end

DripExtras.PortalGun = function()
    -- ========================================================================
    -- PORTAL GUN - NOME DO TOOL + NOME 3D FLUTUANTE
    -- ========================================================================

    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local Backpack = LocalPlayer:WaitForChild("Backpack")
    local TweenService = game:GetService("TweenService")

    local tool = nil
    local isTeleporting = false

    -- Efeito de Portal Dimensional
    local function playPortalGunEffect(startPos, endPos)
        local character = LocalPlayer.Character
        if not character then return end
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChild("Humanoid")
        if not rootPart or not humanoid then return end

        humanoid.PlatformStand = true

        -- Fenda de Saída (Origem)
        local portalOrigin = Instance.new("Part")
        portalOrigin.Shape = Enum.PartType.Cylinder
        portalOrigin.Size = Vector3.new(0.2, 5, 5)
        portalOrigin.CFrame = rootPart.CFrame * CFrame.new(0, 0, -2.5) * CFrame.Angles(0, math.rad(90), 0)
        portalOrigin.Anchored = true
        portalOrigin.CanCollide = false
        portalOrigin.Material = Enum.Material.Neon
        portalOrigin.BrickColor = BrickColor.new("Lime green")
        portalOrigin.Transparency = 0.2
        portalOrigin.Parent = workspace

        local portalRing1 = Instance.new("Part")
        portalRing1.Shape = Enum.PartType.Cylinder
        portalRing1.Size = Vector3.new(0.3, 7, 7)
        portalRing1.CFrame = portalOrigin.CFrame
        portalRing1.Anchored = true
        portalRing1.CanCollide = false
        portalRing1.Material = Enum.Material.Neon
        portalRing1.BrickColor = BrickColor.new("Cyan")
        portalRing1.Transparency = 0.4
        portalRing1.Parent = workspace

        local suckTween = TweenService:Create(rootPart, TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {
            CFrame = portalOrigin.CFrame * CFrame.new(0, 0, -1.5)
        })
        suckTween:Play()

        local expandOrigin1 = TweenService:Create(portalOrigin, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = Vector3.new(0.05, 8, 8),
            Transparency = 1
        })
        local expandOrigin2 = TweenService:Create(portalRing1, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = Vector3.new(0.05, 10, 10),
            Transparency = 1
        })
        expandOrigin1:Play()
        expandOrigin2:Play()

        task.wait(0.35)
        portalOrigin:Destroy()
        portalRing1:Destroy()

        -- Salto Dimensional
        local landingCFrame = CFrame.new(endPos + Vector3.new(0, 3, 0))
        rootPart.CFrame = landingCFrame

        -- Fenda de Entrada (Destino)
        local portalDest = Instance.new("Part")
        portalDest.Shape = Enum.PartType.Cylinder
        portalDest.Size = Vector3.new(0.05, 8, 8)
        portalDest.CFrame = landingCFrame * CFrame.new(0, 0, -2.5) * CFrame.Angles(0, math.rad(90), 0)
        portalDest.Anchored = true
        portalDest.CanCollide = false
        portalDest.Material = Enum.Material.Neon
        portalDest.BrickColor = BrickColor.new("Lime green")
        portalDest.Transparency = 0.1
        portalDest.Parent = workspace

        local portalRing2 = Instance.new("Part")
        portalRing2.Shape = Enum.PartType.Cylinder
        portalRing2.Size = Vector3.new(0.05, 10, 10)
        portalRing2.CFrame = portalDest.CFrame
        portalRing2.Anchored = true
        portalRing2.CanCollide = false
        portalRing2.Material = Enum.Material.Neon
        portalRing2.BrickColor = BrickColor.new("Cyan")
        portalRing2.Transparency = 0.3
        portalRing2.Parent = workspace

        rootPart.CFrame = portalDest.CFrame * CFrame.new(0, 0, 2)

        local shrinkDest1 = TweenService:Create(portalDest, TweenInfo.new(0.45, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
            Size = Vector3.new(0.2, 2, 2),
            Transparency = 1
        })
        local shrinkDest2 = TweenService:Create(portalRing2, TweenInfo.new(0.45, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
            Size = Vector3.new(0.2, 3, 3),
            Transparency = 1
        })
        shrinkDest1:Play()
        shrinkDest2:Play()

        task.wait(0.45)
        portalDest:Destroy()
        portalRing2:Destroy()

        humanoid.PlatformStand = false
    end

    -- Função para Criar a Portal Gun com Nome e Nome Flutuante Ativo
    local function createPortalGunTool()
        if Backpack:FindFirstChild("Portal Gun") or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Portal Gun")) then 
            return 
        end

        tool = Instance.new("Tool")
        tool.Name = "Portal Gun" -- Nome oficial do Tool no inventário
        tool.RequiresHandle = true
        tool.TextureId = "rbxassetid://0"

        -- ========================================================================
        -- HANDLE (Cabo / Empunhadura principal onde o boneco segura)
        -- ========================================================================
        local handle = Instance.new("Part")
        handle.Name = "Handle"
        handle.Size = Vector3.new(0.4, 0.9, 0.4)
        handle.BrickColor = BrickColor.new("Dark stone grey")
        handle.Material = Enum.Material.SmoothPlastic
        handle.CanCollide = false

        -- Chassi Principal da Arma
        local chassis = Instance.new("Part")
        chassis.Size = Vector3.new(0.5, 0.6, 1.5)
        chassis.BrickColor = BrickColor.new("Medium stone grey")
        chassis.Material = Enum.Material.Metal
        chassis.CFrame = handle.CFrame * CFrame.new(0, 0.6, -0.3)
        chassis.CanCollide = false
        chassis.Parent = handle

        local w1 = Instance.new("WeldConstraint")
        w1.Part0 = handle
        w1.Part1 = chassis
        w1.Parent = chassis

        -- Detalhe Lateral Superior
        local topStripe = Instance.new("Part")
        topStripe.Size = Vector3.new(0.55, 0.2, 1.2)
        topStripe.BrickColor = BrickColor.new("Black")
        topStripe.Material = Enum.Material.Glass
        topStripe.CFrame = chassis.CFrame * CFrame.new(0, 0.35, -0.1)
        topStripe.CanCollide = false
        topStripe.Parent = handle

        local w2 = Instance.new("WeldConstraint")
        w2.Part0 = handle
        w2.Part1 = topStripe
        w2.Parent = topStripe

        -- Canos Duplos Emissores na Frente
        local barrel1 = Instance.new("Part")
        barrel1.Size = Vector3.new(0.25, 0.25, 0.8)
        barrel1.BrickColor = BrickColor.new("Dark stone grey")
        barrel1.Material = Enum.Material.Metal
        barrel1.CFrame = chassis.CFrame * CFrame.new(-0.12, 0.05, -0.95)
        barrel1.CanCollide = false
        barrel1.Parent = handle

        local w3 = Instance.new("WeldConstraint")
        w3.Part0 = handle
        w3.Part1 = barrel1
        w3.Parent = barrel1

        local barrel2 = Instance.new("Part")
        barrel2.Size = Vector3.new(0.25, 0.25, 0.8)
        barrel2.BrickColor = BrickColor.new("Dark stone grey")
        barrel2.Material = Enum.Material.Metal
        barrel2.CFrame = chassis.CFrame * CFrame.new(0.12, 0.05, -0.95)
        barrel2.CanCollide = false
        barrel2.Parent = handle

        local w4 = Instance.new("WeldConstraint")
        w4.Part0 = handle
        w4.Part1 = barrel2
        w4.Parent = barrel2

        -- Emissor Neon Verde (Ponta dos Canos)
        local tipGlow = Instance.new("Part")
        tipGlow.Shape = Enum.PartType.Cylinder
        tipGlow.Size = Vector3.new(0.1, 0.6, 0.6)
        tipGlow.BrickColor = BrickColor.new("Lime green")
        tipGlow.Material = Enum.Material.Neon
        tipGlow.CFrame = chassis.CFrame * CFrame.new(0, 0.05, -1.35) * CFrame.Angles(0, math.rad(90), 0)
        tipGlow.CanCollide = false
        tipGlow.Parent = handle

        local w5 = Instance.new("WeldConstraint")
        w5.Part0 = handle
        w5.Part1 = tipGlow
        w5.Parent = tipGlow

        -- Núcleo Esférico de Energia Central
        local coreBulb = Instance.new("Part")
        coreBulb.Shape = Enum.PartType.Ball
        coreBulb.Size = Vector3.new(0.7, 0.7, 0.7)
        coreBulb.BrickColor = BrickColor.new("Lime green")
        coreBulb.Material = Enum.Material.Neon
        coreBulb.CFrame = chassis.CFrame * CFrame.new(0, 0.35, 0.1)
        coreBulb.CanCollide = false
        coreBulb.Parent = handle

        local w6 = Instance.new("WeldConstraint")
        w6.Part0 = handle
        w6.Part1 = coreBulb
        w6.Parent = coreBulb

        -- Anel de Proteção de Vidro do Núcleo
        local coreGlass = Instance.new("Part")
        coreGlass.Shape = Enum.PartType.Cylinder
        coreGlass.Size = Vector3.new(0.8, 0.75, 0.75)
        coreGlass.BrickColor = BrickColor.new("Cyan")
        coreGlass.Material = Enum.Material.Glass
        coreGlass.Transparency = 0.5
        coreGlass.CFrame = chassis.CFrame * CFrame.new(0, 0.35, 0.1) * CFrame.Angles(0, 0, math.rad(90))
        coreGlass.CanCollide = false
        coreGlass.Parent = handle

        local w7 = Instance.new("WeldConstraint")
        w7.Part0 = handle
        w7.Part1 = coreGlass
        w7.Parent = coreGlass

        -- ========================================================================
        -- NOME FLUTUANTE (BillboardGui) - Exibe o nome do Tool no 3D
        -- ========================================================================
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ToolNameDisplay"
        billboard.Size = UDim2.new(0, 150, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 2.2, 0)
        billboard.AlwaysOnTop = true

        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = tool.Name -- Puxa o nome diretamente da ferramenta
        textLabel.TextColor3 = Color3.fromRGB(0, 255, 128)
        textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        textLabel.TextStrokeTransparency = 0.2
        textLabel.TextSize = 18
        textLabel.Font = Enum.Font.FredokaOne
        textLabel.Parent = billboard

        billboard.Parent = handle
        handle.Parent = tool

        -- Evento de Clique / Disparo
        tool.Activated:Connect(function()
            if isTeleporting then return end
        
            local mouse = LocalPlayer:GetMouse()
            local targetPosition = mouse.Hit.Position
        
            local character = LocalPlayer.Character
            local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        
            if rootPart then
                isTeleporting = true
                local currentPos = rootPart.Position
            
                playPortalGunEffect(currentPos, targetPosition)
            
                task.wait(0.75)
                isTeleporting = false
            end
        end)

        tool.Parent = Backpack
    end

    LocalPlayer.CharacterAdded:Connect(function(newChar)
        task.wait(1)
        Backpack = newChar:WaitForChild("Backpack")
        createPortalGunTool()
    end)

    createPortalGunTool()

    print("[Portal Gun] Nome configurado no Tool e exibição 3D ativada com sucesso!")
end

DripExtras.BoostFPS = function()
    -- Script GUI Otimizador Extremo (Versão Ultra Max FPS - Sem bug de texto)
    local CoreGui = game:GetService("CoreGui")
    local Lighting = game:GetService("Lighting")
    local RunService = game:GetService("RunService")
    local Terrain = workspace:FindFirstChildOfClass('Terrain')

    -- Remove interface antiga se já estiver aberta
    if CoreGui:FindFirstChild("ProdigioZX_Hub") then
        CoreGui["ProdigioZX_Hub"]:Destroy()
    end

    -- ScreenGui Principal
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ProdigioZX_Hub"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = CoreGui

    ----------------------------------------------------
    -- MOSTRADOR DE FPS (Arrastável)
    ----------------------------------------------------
    local FpsFrame = Instance.new("Frame")
    FpsFrame.Name = "FpsFrame"
    FpsFrame.Size = UDim2.new(0, 110, 0, 35)
    FpsFrame.Position = UDim2.new(1, -120, 0, 10)
    FpsFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    FpsFrame.BorderSizePixel = 0
    FpsFrame.Active = true
    FpsFrame.Draggable = true
    FpsFrame.Parent = ScreenGui

    local FpsCorner = Instance.new("UICorner")
    FpsCorner.CornerRadius = UDim.new(0, 6)
    FpsCorner.Parent = FpsFrame

    local FpsStroke = Instance.new("UIStroke")
    FpsStroke.Color = Color3.fromRGB(255, 255, 255)
    FpsStroke.Thickness = 1
    FpsStroke.Parent = FpsFrame

    local FpsLabel = Instance.new("TextLabel")
    FpsLabel.Name = "FpsLabel"
    FpsLabel.Size = UDim2.new(1, 0, 1, 0)
    FpsLabel.BackgroundTransparency = 1
    FpsLabel.Text = "FPS: --"
    FpsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    FpsLabel.TextSize = 14
    FpsLabel.Font = Enum.Font.ArialBold
    FpsLabel.Parent = FpsFrame

    local lastUpdate = tick()
    local frameCount = 0

    RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
        local now = tick()
        if now - lastUpdate >= 1 then
            FpsLabel.Text = "FPS: " .. tostring(frameCount)
            frameCount = 0
            lastUpdate = now
        end
    end)

    ----------------------------------------------------
    -- JANELA PRINCIPAL
    ----------------------------------------------------
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 320, 0, 190)
    MainFrame.Position = UDim2.new(0.5, -160, 0.5, -95)
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Color3.fromRGB(255, 255, 255)
    MainStroke.Thickness = 1
    MainStroke.Parent = MainFrame

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = MainFrame

    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, 0, 0, 45)
    Title.Position = UDim2.new(0, 0, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "ULTRA FPS BOOST"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 20
    Title.Font = Enum.Font.ArialBold
    Title.Parent = MainFrame

    local BoostButton = Instance.new("TextButton")
    BoostButton.Name = "BoostButton"
    BoostButton.Size = UDim2.new(0.85, 0, 0, 45)
    BoostButton.Position = UDim2.new(0.075, 0, 0.55, -10)
    BoostButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    BoostButton.Text = "OTIMIZAR AGORA"
    BoostButton.TextColor3 = Color3.fromRGB(0, 0, 0)
    BoostButton.TextSize = 16
    BoostButton.Font = Enum.Font.ArialBold
    BoostButton.Parent = MainFrame

    local ButtonCorner = Instance.new("UICorner")
    ButtonCorner.CornerRadius = UDim.new(0, 6)
    ButtonCorner.Parent = BoostButton

    ----------------------------------------------------
    -- FUNÇÃO DE OTIMIZAÇÃO ULTRA EXTREMA
    ----------------------------------------------------
    local function applyUltraFpsBoost()
        pcall(function()
            -- Configurações globais de renderização no mínimo
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level00

            -- Limpeza total da iluminação e pós-processamento
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            Lighting.Brightness = 0
            Lighting.ClockTime = 12
            Lighting.ExposureCompensation = 0
        
            for _, effect in ipairs(Lighting:GetChildren()) do
                if effect:IsA("PostEffect") or effect:IsA("Atmosphere") or effect:IsA("Sky") or effect:IsA("Clouds") or effect:IsA("SunRaysEffect") or effect:IsA("BloomEffect") or effect:IsA("BlurEffect") then
                    effect:Destroy()
                end
            end

            if sethiddenproperty then
                pcall(function() sethiddenproperty(Lighting, "Technology", Enum.Technology.Compatibility) end)
            end

            -- Desativa detalhes de terreno e água
            if Terrain then
                Terrain.WaterWaveSize = 0
                Terrain.WaterWaveSpeed = 0
                Terrain.WaterReflectance = 0
                Terrain.WaterTransparency = 0
                if sethiddenproperty then
                    pcall(function() sethiddenproperty(Terrain, "Decoration", false) end)
                end
            end

            -- Função para stripping completo de recursos
            local function optimize(v)
                -- A alteração de fonte dos textos foi removida para impedir o bug das letras
                if v:IsA("BasePart") then
                    v.Material = Enum.Material.SmoothPlastic
                    v.Reflectance = 0
                    v.CastShadow = false
                elseif v:IsA("MeshPart") then
                    v.Material = Enum.Material.SmoothPlastic
                    v.TextureID = ""
                    v.Reflectance = 0
                    v.CastShadow = false
                elseif v:IsA("SpecialMesh") then
                    v.TextureId = ""
                elseif v:IsA("Clothing") or v:IsA("ShirtGraphic") or v:IsA("CharacterMesh") then
                    v:Destroy()
                elseif v:IsA("Decal") or v:IsA("Texture") then
                    v:Destroy()
                elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") or v:IsA("Beam") then
                    v.Enabled = false
                    v:Destroy()
                elseif v:IsA("PostEffect") or v:IsA("Explosion") or v:IsA("Highlight") or v:IsA("SelectionBox") then
                    v:Destroy()
                elseif v:IsA("Sound") then
                    v:Stop()
                end
            end

            -- Aplica nos objetos existentes
            for _, v in ipairs(game:GetDescendants()) do
                optimize(v)
            end

            -- Aplica automaticamente em novos objetos gerados
            game.DescendantAdded:Connect(function(v)
                task.wait()
                optimize(v)
            end)

            -- Coleta agressiva de lixo da memória
            collectgarbage("collect")
        end)
    end

    ----------------------------------------------------
    -- AÇÃO DO BOTÃO
    ----------------------------------------------------
    BoostButton.MouseButton1Click:Connect(function()
        MainFrame.Visible = false

        local LoadingFrame = Instance.new("Frame")
        LoadingFrame.Name = "LoadingFrame"
        LoadingFrame.Size = UDim2.new(1, 0, 1, 0)
        LoadingFrame.Position = UDim2.new(0, 0, 0, 0)
        LoadingFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
        LoadingFrame.ZIndex = 10
        LoadingFrame.Parent = ScreenGui

        local LoadingTitle = Instance.new("TextLabel")
        LoadingTitle.Size = UDim2.new(1, 0, 0, 30)
        LoadingTitle.Position = UDim2.new(0, 0, 0.42, 0)
        LoadingTitle.BackgroundTransparency = 1
        LoadingTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
        LoadingTitle.TextSize = 24
        LoadingTitle.Font = Enum.Font.ArialBold
        LoadingTitle.Text = "ULTRA OTIMIZADOR"
        LoadingTitle.ZIndex = 11
        LoadingTitle.Parent = LoadingFrame

        local LoadingText = Instance.new("TextLabel")
        LoadingText.Size = UDim2.new(1, 0, 0, 30)
        LoadingText.Position = UDim2.new(0, 0, 0.50, 0)
        LoadingText.BackgroundTransparency = 1
        LoadingText.TextColor3 = Color3.fromRGB(180, 180, 180)
        LoadingText.TextSize = 16
        LoadingText.Font = Enum.Font.Arial
        LoadingText.Text = "REMOVENDO BRILHOS E EFEITOS..."
        LoadingText.ZIndex = 11
        LoadingText.Parent = LoadingFrame

        task.spawn(function()
            task.wait(0.8)
            LoadingText.Text = "APLICANDO REDUÇÃO DE TEXTURAS..."
        
            task.spawn(applyUltraFpsBoost)
        
            task.wait(1.0)
            LoadingText.Text = "LIMPANDO MEMÓRIA RAM..."
        
            task.wait(1.0)
            MainFrame:Destroy()
            LoadingFrame:Destroy()
        end)
    end)
end

--========================================================--
-- DRIP MENU | FUNÇÕES (cada aba é isolada: se uma falhar, as outras carregam)
--========================================================--

local function LoadDripMenu()

    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local Lighting = game:GetService("Lighting")

    local Player = Players.LocalPlayer
    local PlayerGui = Player:WaitForChild("PlayerGui")
    local player = Player
    local RunService = game:GetService("RunService")
    local SoundService = game:GetService("SoundService")
    local HttpService = game:GetService("HttpService")

    local function GetChar()
    	local char = player.Character
    	if char then
    		local root = char:FindFirstChild("HumanoidRootPart")
    		local hum = char:FindFirstChild("Humanoid")
    		return char, root, hum
    	end
    	return nil, nil, nil
    end

    local function EquipToolByName(toolNameKeyword)
    	local char = player.Character
    	local backpack = player:FindFirstChildOfClass("Backpack")
    	if not char then return end
    	local equipped = char:FindFirstChildOfClass("Tool")
    	if equipped and string.find(string.lower(equipped.Name), string.lower(toolNameKeyword)) then
    		return
    	end
    	if backpack then
    		for _, tool in ipairs(backpack:GetChildren()) do
    			if tool:IsA("Tool") and string.find(string.lower(tool.Name), string.lower(toolNameKeyword)) then
    				char.Humanoid:EquipTool(tool)
    				break
    			end
    		end
    	end
    end

    local TimerGui = Instance.new("ScreenGui")
    TimerGui.Name = "DripFarmTimer"
    TimerGui.ResetOnSpawn = false
    TimerGui.IgnoreGuiInset = true
    TimerGui.Parent = PlayerGui
    local TimerLabel = Instance.new("TextLabel")
    TimerLabel.Name = "TimerLabel"
    TimerLabel.Size = UDim2.new(0, 320, 0, 28)
    TimerLabel.Position = UDim2.new(0.5, -160, 0, 12)
    TimerLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    TimerLabel.BackgroundTransparency = 0.25
    TimerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TimerLabel.TextSize = 13
    TimerLabel.Font = Enum.Font.GothamMedium
    TimerLabel.Text = ""
    TimerLabel.Visible = false
    TimerLabel.Parent = TimerGui
    Instance.new("UICorner", TimerLabel).CornerRadius = UDim.new(0, 6)

    do
        local ok, err = pcall(function()
            local ConfigTab = Window:Tab({
                Title = "Config",
                Icon = "settings",
            })

            ConfigTab:Section({
                Title = "Performance"
            })

            ConfigTab:Button({
                Title = "Anti-Lag Potato Mode",
                Desc = "Reduz efeitos visuais para melhorar o desempenho",
                Icon = "zap",

                Callback = function()

                    local Lighting = game:GetService("Lighting")
                    local Workspace = game:GetService("Workspace")
                    local Terrain = Workspace:FindFirstChildOfClass("Terrain")

                    pcall(function()
                        Lighting.GlobalShadows = false
                        Lighting.FogEnd = 9e9
                        Lighting.Brightness = 1
                        Lighting.ClockTime = 12

                        for _, v in ipairs(Lighting:GetChildren()) do
                            if v:IsA("PostEffect")
                                or v:IsA("BloomEffect")
                                or v:IsA("BlurEffect")
                                or v:IsA("ColorCorrectionEffect")
                                or v:IsA("SunRaysEffect")
                                or v:IsA("Atmosphere") then

                                v:Destroy()
                            end
                        end
                    end)

                    pcall(function()
                        if Terrain then
                            Terrain.WaterWaveSize = 0
                            Terrain.WaterWaveSpeed = 0
                            Terrain.WaterReflectance = 0
                            Terrain.WaterTransparency = 0

                            if sethiddenproperty then
                                sethiddenproperty(
                                    Terrain,
                                    "Decoration",
                                    false
                                )
                            end
                        end
                    end)

                    pcall(function()
                        settings().Rendering.QualityLevel =
                            Enum.QualityLevel.Level01
                    end)

                    pcall(function()
                        settings().Rendering.GraphicsMode =
                            Enum.GraphicsMode.NoGraphics
                    end)

                    pcall(function()
                        local UserGameSettings =
                            UserSettings():GetService(
                                "UserGameSettings"
                            )

                        UserGameSettings.SavedQualityLevel =
                            Enum.SavedQualityLevel.Level1

                        UserGameSettings.MasterVolume = 0.5
                    end)

                    local function optimizePart(obj)

                        pcall(function()

                            if obj:IsA("BasePart") then

                                obj.Material =
                                    Enum.Material.SmoothPlastic

                                obj.Reflectance = 0
                                obj.CastShadow = false

                            elseif obj:IsA("Decal")
                                or obj:IsA("Texture") then

                                obj:Destroy()

                            elseif obj:IsA("ParticleEmitter")
                                or obj:IsA("Trail")
                                or obj:IsA("Fire")
                                or obj:IsA("Smoke")
                                or obj:IsA("Sparkles") then

                                obj:Destroy()

                            elseif obj:IsA("Explosion") then

                                obj:Destroy()

                            end

                        end)
                    end

                    for _, obj in ipairs(
                        Workspace:GetDescendants()
                    ) do
                        optimizePart(obj)
                    end

                    if not _G.DripAntiLagConnection then

                        _G.DripAntiLagConnection =
                            Workspace.DescendantAdded:Connect(
                                function(obj)

                                    task.spawn(function()
                                        optimizePart(obj)
                                    end)

                                end
                            )

                    end

                    pcall(function()
                        if setfpscap then
                            setfpscap(999)
                        end
                    end)

                    WindUI:Notify({
                        Title = "Anti-Lag",
                        Content = "Potato Mode ativado!",
                        Icon = "zap",
                        Duration = 4,
                    })

                    print(
                        "[Drip Menu] Modo batata"
                    )
                end,
            })
        end)
        if not ok then warn("[Makima Scripts] Aba Drip \"Config\" falhou:", err) end
    end

    do
        local ok, err = pcall(function()
            local MacroTab = Window:Tab({
                Title = "Parkour",
                Icon = "video",
            })

            MacroTab:Section({
                Title = "Rotas de Parkour"
            })

            MacroTab:Paragraph({
                Title = "Rotas prontas",
                Desc = "Aqui estão rotas de parkour já feitas. Selecione o sistema abaixo para acessar e executar as rotas disponíveis."
            })

            MacroTab:Button({
                Title = "Rotas Prontas",
                Desc = "Abrir rotas de parkour já gravadas",
                Icon = "route",
                Callback = function()
                    loadstring(game:HttpGet(
                        "https://raw.githubusercontent.com/SpaceXecho/0000/refs/heads/main/obfuscated_script-1787435003096.lua.txt"
                    ))()
                end,
            })

            MacroTab:Section({
                Title = "Gravador"
            })

            MacroTab:Button({
                Title = "Gravar Parkour",
                Desc = "Abrir o gravador de parkour",
                Icon = "video",
                Callback = function()
                    loadstring(game:HttpGet(
                        "https://raw.githubusercontent.com/SpaceXecho/MiniHub/refs/heads/main/mini%20huh%20ZX.lua%20(1).txt"
                    ))()
                end,
            })
        end)
        if not ok then warn("[Makima Scripts] Aba Drip \"Parkour\" falhou:", err) end
    end

    do
        local ok, err = pcall(function()
            local FarmTab = Window:Tab({
            	Title = "Fazenda",
            	Icon = "leaf",
            })

            FarmTab:Section({ Title = "Gerenciador de Missões" })

            local FarmConfig = { Enabled = false, SelectedMission = "Lixo" }
            local collectedTrash = {}
            local hasBoughtScythe = false
            local ignoredGrass = {}
            local activeVisualHighlights = {}

            local function ClearActiveHighlights()
            	for _, hl in pairs(activeVisualHighlights) do
            		if hl and hl.Parent then hl:Destroy() end
            	end
            	activeVisualHighlights = {}
            end

            local function GetClosestPromptByAction(actionText, ignoreTable)
            	local char, root, hum = GetChar()
            	if not root then return nil end
            	local closestPrompt, shortestDist = nil, math.huge
            	for _, obj in ipairs(workspace:GetDescendants()) do
            		if obj:IsA("ProximityPrompt") and obj.ActionText == actionText then
            			local parentPart = obj.Parent
            			if parentPart and parentPart:IsA("BasePart") then
            				local skip = false
            				if ignoreTable then
            					for _, oldPart in pairs(ignoreTable) do
            						if oldPart == parentPart then skip = true; break end
            					end
            				end
            				if not skip then
            					local dist = (root.Position - parentPart.Position).Magnitude
            					if dist < shortestDist then
            						shortestDist = dist
            						closestPrompt = obj
            					end
            				end
            			end
            		end
            	end
            	return closestPrompt
            end

            FarmTab:Dropdown({
            	Title = "Escolher Missão",
            	Desc = "Selecione Lixo, Grama ou Caixa",
            	Values = { "Lixo", "Grama", "Caixa" },
            	Value = "Lixo",
            	Callback = function(opt)
            		FarmConfig.SelectedMission = opt
            		WindUI:Notify({
            			Title = "Missão",
            			Content = "Selecionado: " .. tostring(opt),
            			Icon = "check",
            			Duration = 2,
            		})
            	end,
            })

            FarmTab:Toggle({
            	Title = "Ativar Auto Missões",
            	Desc = "Liga/desliga o farm automático",
            	Value = false,
            	Callback = function(Value)
            		FarmConfig.Enabled = Value
            		if not Value then
            			TimerLabel.Visible = false
            			ClearActiveHighlights()
            		end
            	end,
            })

            task.spawn(function()
            	while true do
            		task.wait(0.5)
            		if FarmConfig.Enabled then
            			pcall(function()
            				ClearActiveHighlights()
            				for _, obj in ipairs(workspace:GetDescendants()) do
            					if obj:IsA("ProximityPrompt") then
            						local isTarget = false
            						if FarmConfig.SelectedMission == "Lixo" and (obj.ActionText == "Recolher" or obj.ActionText == "Jogar Lixo") then
            							isTarget = true
            						elseif FarmConfig.SelectedMission == "Grama" and (obj.ActionText == "Comprar [2500$]" or obj.ActionText == "Cortar [Requer Foice]") then
            							isTarget = true
            						elseif FarmConfig.SelectedMission == "Caixa" and (string.find(string.lower(obj.ActionText), "caixa") or string.find(string.lower(obj.ActionText), "pegar") or string.find(string.lower(obj.Name), "caixa")) then
            							isTarget = true
            						end
            						if isTarget and obj.Parent and obj.Parent:IsA("BasePart") then
            							local part = obj.Parent
            							local highlight = Instance.new("Highlight")
            							highlight.Name = "ProdigizxGreenESP"
            							highlight.Adornee = part
            							highlight.FillColor = Color3.fromRGB(0, 255, 0)
            							highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            							highlight.FillTransparency = 0.4
            							highlight.OutlineTransparency = 0
            							highlight.Parent = part
            							table.insert(activeVisualHighlights, highlight)
            						end
            					end
            				end

            				local char, root, hum = GetChar()
            				if root and hum then
            					if FarmConfig.SelectedMission == "Lixo" then
            						TimerLabel.Visible = false
            						local collectPrompt = GetClosestPromptByAction("Recolher", collectedTrash)
            						if collectPrompt and collectPrompt.Parent and FarmConfig.Enabled then
            							local part = collectPrompt.Parent
            							if part:IsA("BasePart") then
            								table.insert(collectedTrash, part)
            								if #collectedTrash > 20 then table.remove(collectedTrash, 1) end
            								root.CFrame = part.CFrame + Vector3.new(0, 3, 0)
            								task.wait(0.3)
            								pcall(function() fireproximityprompt(collectPrompt) end)
            							end
            						end
            						task.wait(0.3)
            						local dropPrompt = GetClosestPromptByAction("Jogar Lixo", nil)
            						if dropPrompt and dropPrompt.Parent and FarmConfig.Enabled then
            							local part = dropPrompt.Parent
            							if part:IsA("BasePart") then
            								root.CFrame = part.CFrame + Vector3.new(0, 3, 0)
            								task.wait(0.3)
            								pcall(function() fireproximityprompt(dropPrompt) end)
            							end
            						end
            					elseif FarmConfig.SelectedMission == "Grama" then
            						TimerLabel.Visible = false
            						EquipToolByName("Foice")
            						if not hasBoughtScythe then
            							local buyPrompt = GetClosestPromptByAction("Comprar [2500$]", nil)
            							if buyPrompt and buyPrompt.Parent and FarmConfig.Enabled then
            								local part = buyPrompt.Parent
            								if part:IsA("BasePart") then
            									root.CFrame = part.CFrame + Vector3.new(0, 3, 0)
            									task.wait(0.4)
            									pcall(function() fireproximityprompt(buyPrompt) end)
            									task.wait(1)
            									hasBoughtScythe = true
            								end
            							end
            						else
            							local cutPrompt = GetClosestPromptByAction("Cortar [Requer Foice]", ignoredGrass)
            							if cutPrompt and cutPrompt.Parent and FarmConfig.Enabled then
            								local part = cutPrompt.Parent
            								if part:IsA("BasePart") then
            									table.insert(ignoredGrass, part)
            									if #ignoredGrass > 15 then table.remove(ignoredGrass, 1) end
            									root.CFrame = part.CFrame + Vector3.new(0, 3, 0)
            									task.wait(0.3)
            									pcall(function() fireproximityprompt(cutPrompt) end)
            								end
            							end
            						end
            					elseif FarmConfig.SelectedMission == "Caixa" then
            						TimerLabel.Visible = true
            						TimerLabel.Text = "Status: Buscando caixa..."
            						local boxPrompt = nil
            						for _, obj in ipairs(workspace:GetDescendants()) do
            							if obj:IsA("ProximityPrompt") then
            								local actionLower = string.lower(obj.ActionText)
            								local parentName = string.lower(obj.Parent and obj.Parent.Name or "")
            								if string.find(actionLower, "caixa") or string.find(actionLower, "pegar") or string.find(parentName, "caixa") then
            									boxPrompt = obj
            									break
            								end
            							end
            						end

            						if boxPrompt and boxPrompt.Parent and boxPrompt.Parent:IsA("BasePart") and FarmConfig.Enabled then
            							local part = boxPrompt.Parent
            							root.CFrame = part.CFrame + Vector3.new(0, 3, 0)
            							task.wait(0.4)
            							pcall(function() fireproximityprompt(boxPrompt) end)
            							task.wait(0.5)

            							if not FarmConfig.Enabled then return end

            							root.CFrame = CFrame.new(442, 4, -224)
            							task.wait(1)

            							if not FarmConfig.Enabled then return end

            							root.CFrame = CFrame.new(-595, 8, -13973)
							
            							WindUI:Notify({
            								Title = "Missão Caixa",
            								Content = "Caixa entregue com sucesso!",
            								Icon = "check",
            								Duration = 3,
            							})
							
            							local waitTime = 30
            							while waitTime > 0 and FarmConfig.Enabled do
            								TimerLabel.Text = "Próximo reinício em: " .. waitTime .. "s"
            								task.wait(1)
            								waitTime = waitTime - 1
            							end
            						else
            							TimerLabel.Text = "Status: Nenhuma caixa encontrada..."
            							task.wait(1)
            						end
            					end
            				end
            			end)
            		else
            			TimerLabel.Visible = false
            		end
            	end
            end)
        end)
        if not ok then warn("[Makima Scripts] Aba Drip \"Farm\" falhou:", err) end
    end

    do
        local ok, err = pcall(function()
            local Players = game:GetService("Players")
            local RunService = game:GetService("RunService")

            local player = Players.LocalPlayer

            --==================================================
            -- CHARACTERS TAB
            --==================================================

            local CharactersTab = Window:Tab({
                Title = "Characters",
                Icon = "user"
            })

            --==================================================
            -- INVISÍVEL FE
            --==================================================

            CharactersTab:Section({
                Title = "Invisível FE"
            })

            CharactersTab:Paragraph({
                Title = "Invisível FE",
                Desc = "Deixa apenas um clone visual totalmente imóvel no lugar do seu corpo real. Seu personagem real fica oculto e separado do clone."
            })

            local InvisibleEnabled = false

            local UNDERGROUND_DISTANCE = 75
            local MOVE_SPEED = 16
            local JUMP_POWER = 50

            local character
            local humanoid
            local root

            local visualCharacter
            local visualHumanoid
            local visualRoot

            local undergroundPosition
            local visualPosition

            local verticalVelocity = 0
            local grounded = true

            local renderConnection
            local characterAddedConnection

            local originalParts = {}

            --==================================================
            -- UTILIDADES
            --==================================================

            local function saveOriginalCharacter()
                originalParts = {}

                if not character then
                    return
                end

                for _, obj in ipairs(character:GetDescendants()) do
                    if obj:IsA("BasePart") then
                        originalParts[obj] = {
                            Transparency = obj.Transparency,
                            CanCollide = obj.CanCollide,
                            CanTouch = obj.CanTouch,
                            CanQuery = obj.CanQuery,
                            Massless = obj.Massless
                        }

                    elseif obj:IsA("Decal") or obj:IsA("Texture") then
                        originalParts[obj] = {
                            Transparency = obj.Transparency
                        }
                    end
                end
            end

            local function restoreCharacter()
                for obj, data in pairs(originalParts) do
                    if obj and obj.Parent then
                        if obj:IsA("BasePart") then
                            obj.Transparency = data.Transparency
                            obj.CanCollide = data.CanCollide
                            obj.CanTouch = data.CanTouch
                            obj.CanQuery = data.CanQuery
                            obj.Massless = data.Massless

                        elseif obj:IsA("Decal") or obj:IsA("Texture") then
                            obj.Transparency = data.Transparency
                        end
                    end
                end

                originalParts = {}
            end

            local function hideRealCharacter()
                if not character then
                    return
                end

                for _, obj in ipairs(character:GetDescendants()) do
                    if obj:IsA("BasePart") then
                        obj.Transparency = 1
                        obj.CanCollide = false
                        obj.CanTouch = false
                        obj.CanQuery = false
                        obj.Massless = true

                    elseif obj:IsA("Decal") or obj:IsA("Texture") then
                        obj.Transparency = 1
                    end
                end

                if humanoid then
                    humanoid.AutoRotate = false
                end
            end

            local function destroyVisualCharacter()
                if visualCharacter then
                    visualCharacter:Destroy()
                    visualCharacter = nil
                end

                visualHumanoid = nil
                visualRoot = nil
            end

            --==================================================
            -- CRIA CLONE VISUAL
            --==================================================

            local function createVisualCharacter()
                if not character or not root then
                    return false
                end

                character.Archivable = true

                destroyVisualCharacter()

                visualCharacter = character:Clone()

                if not visualCharacter then
                    return false
                end

                visualCharacter.Name = "VisualCharacter"

                for _, obj in ipairs(visualCharacter:GetDescendants()) do

                    if obj:IsA("Script")
                    or obj:IsA("LocalScript")
                    or obj:IsA("ModuleScript") then

                        obj:Destroy()

                    elseif obj:IsA("BasePart") then
                        obj.CanCollide = false
                        obj.CanTouch = false
                        obj.CanQuery = false
                        obj.Massless = true
                        obj.Anchored = false

                    elseif obj:IsA("Decal")
                    or obj:IsA("Texture") then
                        obj.Transparency = 0
                    end
                end

                visualHumanoid = visualCharacter:FindFirstChildOfClass("Humanoid")
                visualRoot = visualCharacter:FindFirstChild("HumanoidRootPart")

                if not visualRoot then
                    visualCharacter:Destroy()
                    visualCharacter = nil
                    return false
                end

                if visualHumanoid then
                    visualHumanoid.AutoRotate = false
                    visualHumanoid.DisplayDistanceType =
                        Enum.HumanoidDisplayDistanceType.None

                    visualHumanoid.WalkSpeed = MOVE_SPEED
                    visualHumanoid.JumpPower = JUMP_POWER
                    visualHumanoid.UseJumpPower = true
                end

                visualCharacter.Parent = workspace

                visualPosition = root.Position

                visualCharacter:PivotTo(
                    root.CFrame
                )

                return true
            end

            --==================================================
            -- CONFIGURA PERSONAGEM
            --==================================================

            local function setupCharacter(newCharacter)
                if not InvisibleEnabled then
                    return
                end

                character = newCharacter

                humanoid = character:WaitForChild("Humanoid")
                root = character:WaitForChild("HumanoidRootPart")

                saveOriginalCharacter()

                undergroundPosition =
                    root.Position - Vector3.new(
                        0,
                        UNDERGROUND_DISTANCE,
                        0
                    )

                visualPosition = root.Position

                verticalVelocity = 0
                grounded = true

                if not createVisualCharacter() then
                    return
                end

                task.wait()

                hideRealCharacter()

                local camera = workspace.CurrentCamera

                if camera and visualHumanoid then
                    camera.CameraSubject = visualHumanoid
                end
            end

            --==================================================
            -- ATIVA
            --==================================================

            local function enableInvisible()
                if InvisibleEnabled then
                    return
                end

                InvisibleEnabled = true

                character =
                    player.Character
                    or player.CharacterAdded:Wait()

                humanoid =
                    character:FindFirstChildOfClass("Humanoid")

                root =
                    character:FindFirstChild("HumanoidRootPart")

                if not humanoid or not root then
                    InvisibleEnabled = false
                    return
                end

                setupCharacter(character)

                -- Evita criar conexão duplicada
                if renderConnection then
                    renderConnection:Disconnect()
                    renderConnection = nil
                end

                renderConnection = RunService.RenderStepped:Connect(function(deltaTime)

                    if not InvisibleEnabled then
                        return
                    end

                    if not character
                    or not character.Parent
                    or not humanoid
                    or not root
                    or not visualCharacter
                    or not visualCharacter.Parent
                    or not visualHumanoid
                    or not visualRoot then
                        return
                    end

                    --==========================================
                    -- CORPO REAL
                    --==========================================

                    root.CFrame =
                        CFrame.new(undergroundPosition)

                    root.AssemblyLinearVelocity =
                        Vector3.zero

                    root.AssemblyAngularVelocity =
                        Vector3.zero

                    for _, obj in ipairs(character:GetDescendants()) do
                        if obj:IsA("BasePart") then
                            obj.CanCollide = false
                            obj.CanTouch = false
                            obj.CanQuery = false
                            obj.Transparency = 1
                        end
                    end

                    --==========================================
                    -- MOVIMENTO DO CLONE
                    --==========================================

                    local moveDirection =
                        humanoid.MoveDirection

                    if moveDirection.Magnitude > 0 then

                        local direction = Vector3.new(
                            moveDirection.X,
                            0,
                            moveDirection.Z
                        )

                        if direction.Magnitude > 0 then

                            direction = direction.Unit

                            visualPosition +=
                                direction *
                                MOVE_SPEED *
                                deltaTime

                            visualCharacter:PivotTo(
                                CFrame.lookAt(
                                    visualPosition,
                                    visualPosition + direction
                                )
                            )
                        end
                    end

                    --==========================================
                    -- PULO
                    --==========================================

                    if humanoid.Jump and grounded then

                        verticalVelocity = JUMP_POWER
                        grounded = false

                        humanoid.Jump = false
                    end

                    --==========================================
                    -- GRAVIDADE
                    --==========================================

                    if not grounded then

                        verticalVelocity -=
                            workspace.Gravity *
                            deltaTime

                        visualPosition += Vector3.new(
                            0,
                            verticalVelocity * deltaTime,
                            0
                        )

                        local groundY =
                            undergroundPosition.Y +
                            UNDERGROUND_DISTANCE

                        if visualPosition.Y <= groundY then

                            visualPosition = Vector3.new(
                                visualPosition.X,
                                groundY,
                                visualPosition.Z
                            )

                            verticalVelocity = 0
                            grounded = true
                        end
                    end

                    --==========================================
                    -- MANTÉM CLONE NA POSIÇÃO
                    --==========================================

                    local currentPivot =
                        visualCharacter:GetPivot()

                    local rotationOnly =
                        currentPivot -
                        currentPivot.Position

                    visualCharacter:PivotTo(
                        CFrame.new(visualPosition) *
                        rotationOnly
                    )

                    --==========================================
                    -- CÂMERA
                    --==========================================

                    local camera =
                        workspace.CurrentCamera

                    if camera
                    and camera.CameraSubject ~= visualHumanoid then

                        camera.CameraSubject =
                            visualHumanoid
                    end
                end)

                --==============================================
                -- RESPAWN
                --==============================================

                if characterAddedConnection then
                    characterAddedConnection:Disconnect()
                    characterAddedConnection = nil
                end

                characterAddedConnection =
                    player.CharacterAdded:Connect(function(newCharacter)

                        if not InvisibleEnabled then
                            return
                        end

                        task.wait(0.2)

                        if InvisibleEnabled then
                            setupCharacter(newCharacter)
                        end
                    end)
            end

            --==================================================
            -- DESATIVA
            --==================================================

            local function disableInvisible()

                InvisibleEnabled = false

                if renderConnection then
                    renderConnection:Disconnect()
                    renderConnection = nil
                end

                if characterAddedConnection then
                    characterAddedConnection:Disconnect()
                    characterAddedConnection = nil
                end

                destroyVisualCharacter()

                if character and character.Parent then

                    restoreCharacter()

                    if humanoid then
                        humanoid.AutoRotate = true
                    end
                end

                character = nil
                humanoid = nil
                root = nil

                undergroundPosition = nil
                visualPosition = nil

                verticalVelocity = 0
                grounded = true

                -- Devolve a câmera para o personagem real
                local currentCharacter = player.Character

                if currentCharacter then
                    local currentHumanoid =
                        currentCharacter:FindFirstChildOfClass("Humanoid")

                    if currentHumanoid then
                        local camera =
                            workspace.CurrentCamera

                        if camera then
                            camera.CameraSubject =
                                currentHumanoid
                        end
                    end
                end
            end

            CharactersTab:Toggle({
                Title = "Invisível FE",
                Desc = "Esconde seu corpo real e mantém um clone visual no local original.",
                Value = false,

                Callback = function(Value)

                    if Value then
                        enableInvisible()
                    else
                        disableInvisible()
                    end

                end
            })

            CharactersTab:Section({
                Title = "Fly"
            })

            CharactersTab:Button({
                Title = "Fly",
                Desc = "Ativa o Fly.",
                Callback = function()
                    local success, err = pcall(function()
                        loadstring(game:HttpGet(
                            "https://raw.githubusercontent.com/SpaceXecho/Voar/refs/heads/main/FlyGuiV3.txt"
                        ))()
                    end)

                    if not success then
                        warn("Erro ao executar o Fly: " .. tostring(err))
                    end
                end
            })

            CharactersTab:Section({
                Title = "Movement"
            })

            local NoclipEnabled = false
            local NoclipConnection

            local function setNoclip(enabled)
                local character = player.Character
                if not character then return end

                for _, obj in ipairs(character:GetDescendants()) do
                    if obj:IsA("BasePart") then
                        obj.CanCollide = not enabled
                    end
                end
            end

            CharactersTab:Toggle({
                Title = "Noclip",
                Desc = "Permite atravessar objetos e paredes.",
                Value = false,

                Callback = function(Value)
                    NoclipEnabled = Value

                    if NoclipConnection then
                        NoclipConnection:Disconnect()
                        NoclipConnection = nil
                    end

                    if Value then
                        NoclipConnection = RunService.Stepped:Connect(function()
                            setNoclip(true)
                        end)
                    else
                        setNoclip(false)
                    end
                end
            })
        end)
        if not ok then warn("[Makima Scripts] Aba Drip \"Characters\" falhou:", err) end
    end

    do
        local ok, err = pcall(function()
            local EspTab = Window:Tab({ 
            	Title = "ESP", 
            	Icon = "eye", 
            })
            EspTab:Section({ Title = "Configurações do ESP" })

            local ESP = { 
            	Enabled = false, 
            	Boxes = false, 
            	Lines = false, 
            	Names = false, 
            	Distance = false, 
            	Ranks = false, 
            	MaxDistance = 1000, 
            	MaxPlayers = 10, 
            	Color = Color3.fromRGB(255, 140, 0) 
            } 
            local ESP_LinesPool = {} 

            local function GetOrCreateLine(index)
            	if not ESP_LinesPool[index] then
            		if not Drawing or not Drawing.new then
            			return nil
            		end
            		local ok, line = pcall(function()
            			return Drawing.new("Line")
            		end)
            		if not ok or not line then
            			return nil
            		end
            		line.Visible = false
            		line.Color = ESP.Color
            		line.Thickness = 1
            		line.Transparency = 1
            		ESP_LinesPool[index] = line
            	end
            	return ESP_LinesPool[index]
            end

            local function CleanESP(char) 
            	if not char then return end 
            	local hl = char:FindFirstChild("PRDG_Highlight") 
            	local bb = char:FindFirstChild("PRDG_Billboard") 
            	if hl then hl:Destroy() end 
            	if bb then bb:Destroy() end 
            end

            local function ApplyESP(targetPlayer) 
            	if targetPlayer == player then return end 
            	local function SetupCharacter(char) 		
            		if not char then return end 		
            		CleanESP(char) 		
            		local root = char:WaitForChild("HumanoidRootPart", 5) 		
            		if not root then return end 		
            		local hl = Instance.new("Highlight") 		
            		hl.Name = "PRDG_Highlight" 		
            		hl.FillColor = ESP.Color 		
            		hl.OutlineColor = Color3.fromRGB(255, 255, 255) 		
            		hl.FillTransparency = 0.5 		
            		hl.Enabled = false 		
            		hl.Parent = char 		
            		local bb = Instance.new("BillboardGui") 		
            		bb.Name = "PRDG_Billboard" 		
            		bb.Adornee = root 		
            		bb.Size = UDim2.new(0, 200, 0, 50) 		
            		bb.StudsOffset = Vector3.new(0, 3.5, 0) 		
            		bb.AlwaysOnTop = true 		
            		bb.Enabled = false 		
            		local txt = Instance.new("TextLabel") 		
            		txt.Name = "InfoText" 		
            		txt.Size = UDim2.new(1, 0, 1, 0) 		
            		txt.BackgroundTransparency = 1 		
            		txt.TextColor3 = ESP.Color 		
            		txt.TextSize = 13 		
            		txt.Font = Enum.Font.SourceSansBold 		
            		txt.Parent = bb 		
            		bb.Parent = char 	
            	end 	
            	if targetPlayer.Character then SetupCharacter(targetPlayer.Character) end 	
            	targetPlayer.CharacterAdded:Connect(SetupCharacter) 
            end

            for _, p in ipairs(Players:GetPlayers()) do ApplyESP(p) end 
            Players.PlayerAdded:Connect(ApplyESP)

            RunService.RenderStepped:Connect(function() 	
            	local myChar = player.Character 	
            	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart") 	
            	local cam = workspace.CurrentCamera 	
            	local sortedPlayers = {} 	
            	for _, line in pairs(ESP_LinesPool) do line.Visible = false end 	
            	if myRoot then 
            		for _, p in ipairs(Players:GetPlayers()) do 
            			if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then 
            				local hum = p.Character:FindFirstChildOfClass("Humanoid") 
            				if hum and hum.Health > 0 then 
            					local root = p.Character.HumanoidRootPart 
            					local dist = (myRoot.Position - root.Position).Magnitude 
            					if dist <= ESP.MaxDistance then 
            						table.insert(sortedPlayers, {player = p, Distance = dist}) 
            					end 
            				end 
            			end 
            		end 
            		table.sort(sortedPlayers, function(a, b) return a.Distance < b.Distance end) 
            	end 	
            	for _, p in ipairs(Players:GetPlayers()) do 
            		if p ~= player and p.Character then 
            			local char = p.Character 
            			local hl = char:FindFirstChild("PRDG_Highlight") 
            			local bb = char:FindFirstChild("PRDG_Billboard") 
            			if hl then hl.Enabled = false end 
            			if bb then bb.Enabled = false end 
            		end 
            	end 	
            	if ESP.Enabled and #sortedPlayers > 0 then 
            		local limit = math.min(ESP.MaxPlayers, #sortedPlayers) 
            		for i = 1, limit do 
            			local entry = sortedPlayers[i] 
            			local p = entry.player 
            			if p and p.Character then 
            				local char = p.Character 
            				local hl = char:FindFirstChild("PRDG_Highlight") 
            				local bb = char:FindFirstChild("PRDG_Billboard") 
            				if hl then hl.Enabled = ESP.Boxes end 
            				if bb then bb.Enabled = (ESP.Names or ESP.Distance or ESP.Ranks) end 
            				if ESP.Lines then 
            					local root = char:FindFirstChild("HumanoidRootPart") 
            					if root then 
            						local screenPos, onScreen = cam:WorldToViewportPoint(root.Position) 
            						if onScreen then 
            							local line = GetOrCreateLine(i)
            							if line then
            								line.Visible = true
            								line.Color = ESP.Color
            								line.From = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
            								line.To = Vector2.new(screenPos.X, screenPos.Y)
            							end 
            						end 
            					end 
            				end 
            				if myRoot then 
            					local root = char:FindFirstChild("HumanoidRootPart") 
            					if root then 
            						local dist = entry.Distance 
            						local txt = bb and bb:FindFirstChild("InfoText") 
            						if txt then 
            							local str = "" 
            							if ESP.Names then str = str .. p.Name end 
            							if ESP.Ranks then 
            								local leaderstats = p:FindFirstChild("leaderstats") 
            								local rankVal = leaderstats and (leaderstats:FindFirstChild("Patente") or leaderstats:FindFirstChild("Rank") or leaderstats:FindFirstChild("Level")) 
            								local rankText = rankVal and tostring(rankVal.Value) or "Sem Patente" 
            								str = str .. " [" .. rankText .. "]" 
            							end 
            							if ESP.Distance then str = str .. " (" .. math.floor(dist) .. "m)" end 
            							txt.Text = str 
            						end 
            					end 
            				end 
            			end 
            		end 
            	end 
            end)

            EspTab:Input({ 
            	Title = "Qtd de Jogadores no ESP", 
            	Desc = "Máximo de jogadores exibidos", 
            	Placeholder = "Ex: 10", 
            	Value = "10", 
            	Callback = function(Text) 
            		ESP.MaxPlayers = tonumber(Text) or 10 
            	end, 
            })
            EspTab:Toggle({ 
            	Title = "Ativar ESP Geral", 
            	Desc = "Liga/desliga o ESP", 
            	Value = false, 
            	Callback = function(Value) ESP.Enabled = Value end, 
            })
            EspTab:Toggle({ 
            	Title = "Caixas / Highlight", 
            	Desc = "Mostra highlight nos jogadores", 
            	Value = false, 
            	Callback = function(Value) ESP.Boxes = Value end, 
            })
            EspTab:Toggle({ 
            	Title = "Linhas (ESP Lines)", 
            	Desc = "Linhas do centro da tela até o jogador", 
            	Value = false, 
            	Callback = function(Value) ESP.Lines = Value end, 
            })
            EspTab:Toggle({ 
            	Title = "Mostrar Nomes", 
            	Desc = "Exibe o nome do jogador", 
            	Value = false, 
            	Callback = function(Value) ESP.Names = Value end, 
            })
            EspTab:Toggle({ 
            	Title = "Mostrar Distância", 
            	Desc = "Exibe a distância em metros", 
            	Value = false, 
            	Callback = function(Value) ESP.Distance = Value end, 
            })
            EspTab:Toggle({ 
            	Title = "Ver Patentes / Ranks", 
            	Desc = "Exibe patente/rank do leaderstats", 
            	Value = false, 
            	Callback = function(Value) ESP.Ranks = Value end, 
            })
        end)
        if not ok then warn("[Makima Scripts] Aba Drip \"ESP\" falhou:", err) end
    end

    do
        local ok, err = pcall(function()
            local MusicTab = Window:Tab({ 
            	Title = "Rádio", 
            	Icon = "music", 
            })
            MusicTab:Section({ Title = "Tocador de Música" })

            local Music_System = { SoundId = "9043887091", Volume = 1, Instance = nil }

            MusicTab:Input({ 
            	Title = "ID do Áudio", 
            	Desc = "Cole o ID do áudio do Roblox", 
            	Placeholder = "Cole o ID aqui", 
            	Value = "9043887091", 
            	Callback = function(Text) 
            		if Text ~= "" then Music_System.SoundId = Text end 
            	end, 
            })
            MusicTab:Button({ 
            	Title = "Tocar Música", 
            	Desc = "Reproduz o áudio em loop", 
            	Icon = "play", 
            	Callback = function() 
            		if Music_System.Instance then Music_System.Instance:Destroy() end 
            		local cleanID = string.match(tostring(Music_System.SoundId), "%d+") 
            		if cleanID then 
            			local sound = Instance.new("Sound") 
            			sound.SoundId = "rbxassetid://" .. cleanID 
            			sound.Volume = Music_System.Volume 
            			sound.Looped = true 
            			sound.Parent = SoundService 
            			sound:Play() 
            			Music_System.Instance = sound 
            			WindUI:Notify({ 
            				Title = "Rádio", 
            				Content = "Tocando!", 
            				Icon = "music", 
            				Duration = 2, 
            			}) 
            		end 
            	end, 
            })
            MusicTab:Button({ 
            	Title = "Parar Música", 
            	Desc = "Para e remove o som atual", 
            	Icon = "square", 
            	Callback = function() 
            		if Music_System.Instance then 
            			Music_System.Instance:Destroy() 
            			Music_System.Instance = nil 
            			WindUI:Notify({ 
            				Title = "Rádio", 
            				Content = "Parado", 
            				Icon = "check", 
            				Duration = 2, 
            			}) 
            		end 
            	end, 
            })
        end)
        if not ok then warn("[Makima Scripts] Aba Drip \"Radio\" falhou:", err) end
    end

    do
        local ok, err = pcall(function()
            local AutoJJSTab = Window:Tab({ 
            	Title = "Auto JJS", 
            	Icon = "settings", 
            })
            AutoJJSTab:Section({ Title = "Função Automática" })
            AutoJJSTab:Button({ 
            	Title = "Executar Auto JJS", 
            	Desc = "Carrega o script de Auto JJs", 
            	Icon = "play", 
            	Callback = function() 
            		DripExtras.AutoJJs() 
            		WindUI:Notify({ 
            			Title = "Auto JJS", 
            			Content = "Script executado!", 
            			Icon = "check", 
            			Duration = 3, 
            		}) 
            	end, 
            })
        end)
        if not ok then warn("[Makima Scripts] Aba Drip \"AutoJJs\" falhou:", err) end
    end

    do
        local ok, err = pcall(function()
            local ParkourTab = Window:Tab({ 
            	Title = "Auxílios", 
            	Icon = "footprints", 
            })
            ParkourTab:Section({ Title = "PRODIGIZX MINI HUB ⛩️" })

            local ParkourEnabled = false 
            local Hitboxes = {} 
            local data = { 
            	{pos = Vector3.new(185.03, 5.04, -661.62), size = Vector3.new(4.00, 0.50, 16.00)}, 
            	{pos = Vector3.new(185.39, 13.26, -661.39), size = Vector3.new(4.00, 0.50, 16.00)}, 
            	{pos = Vector3.new(185.11, 21.28, -661.68), size = Vector3.new(4.00, 0.50, 16.00)}, 
            	{pos = Vector3.new(185.30, 29.29, -661.72), size = Vector3.new(4.00, 0.50, 16.00)}, 
            	{pos = Vector3.new(186.08, 37.36, -661.76), size = Vector3.new(4.00, 0.50, 16.00)}, 
            	{pos = Vector3.new(186.08, 45.36, -661.76), size = Vector3.new(4.00, 0.50, 16.00)}, 
            	{pos = Vector3.new(186.25, 53.36, -661.86), size = Vector3.new(4.00, 0.50, 16.00)}, 
            	{pos = Vector3.new(185.82, 61.36, -662.00), size = Vector3.new(4.00, 0.50, 16.00)}, 
            	{pos = Vector3.new(185.60, 69.40, -661.98), size = Vector3.new(4.00, 0.50, 16.00)}, 
            	{pos = Vector3.new(185.71, 77.42, -661.90), size = Vector3.new(4.00, 0.50, 15.00)}, 
            	{pos = Vector3.new(185.28, 85.44, -662.14), size = Vector3.new(4.00, 0.50, 16.00)}, 
            	{pos = Vector3.new(185.42, 93.48, -662.05), size = Vector3.new(4.00, 0.50, 16.00)}, 
            	{pos = Vector3.new(185.08, 5.26, -618.66), size = Vector3.new(4.00, 0.50, 16.00)}, 
            	{pos = Vector3.new(185.36, 13.28, -618.65), size = Vector3.new(4.00, 0.50, 15.00)}, 
            	{pos = Vector3.new(185.32, 21.29, -618.70), size = Vector3.new(4.00, 0.50, 16.00)}, 
            	{pos = Vector3.new(185.65, 29.34, -618.67), size = Vector3.new(4.00, 0.50, 16.00)}, 
            	{pos = Vector3.new(186.12, 37.36, -618.43), size = Vector3.new(4.00, 0.50, 15.00)}, 
            	{pos = Vector3.new(186.30, 45.34, -617.87), size = Vector3.new(5.00, 0.50, 16.00)}, 
            	{pos = Vector3.new(185.41, 53.36, -618.05), size = Vector3.new(4.00, 0.50, 15.00)}, 
            	{pos = Vector3.new(185.62, 61.40, -617.79), size = Vector3.new(4.00, 0.50, 16.00)}, 
            	{pos = Vector3.new(185.58, 69.40, -617.79), size = Vector3.new(4.00, 0.50, 17.00)}, 
            	{pos = Vector3.new(185.87, 77.42, -618.33), size = Vector3.new(4.00, 0.50, 15.00)}, 
            	{pos = Vector3.new(185.73, 85.44, -618.62), size = Vector3.new(4.00, 0.50, 16.00)}, 
            	{pos = Vector3.new(185.68, 93.48, -618.49), size = Vector3.new(4.00, 0.50, 15.00)}, 
            	{pos = Vector3.new(270.22, 4.24, -661.72), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(277.86, 4.24, -655.56), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(269.80, 4.24, -649.96), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(284.45, 4.24, -660.72), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(284.59, 4.24, -650.23), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(267.14, 5.04, -627.94), size = Vector3.new(4.00, 0.50, 32.00)}, 
            	{pos = Vector3.new(288.33, 5.04, -627.86), size = Vector3.new(4.00, 0.50, 31.00)}, 
            	{pos = Vector3.new(277.48, 7.63, -591.97), size = Vector3.new(4.00, 0.50, 27.00)}, 
            	{pos = Vector3.new(271.76, 7.64, -569.98), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(279.08, 7.64, -567.95), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(265.48, 7.64, -564.93), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(271.34, 7.64, -559.70), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(259.46, 7.64, -561.92), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(260.50, 7.64, -554.72), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(250.93, 7.64, -561.91), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(248.66, 7.64, -554.60), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(243.06, 7.64, -565.74), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(235.96, 7.64, -560.93), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(240.08, 7.64, -592.47), size = Vector3.new(4.00, 0.50, 27.00)}, 
            	{pos = Vector3.new(394.19, 5.06, -850.78), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(389.19, 7.45, -855.82), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(392.91, 5.06, -861.09), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(384.07, 10.15, -855.95), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(377.51, 12.94, -855.73), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(370.87, 14.68, -855.83), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(365.12, 16.20, -856.03), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(358.50, 17.61, -855.96), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(351.76, 19.27, -856.05), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(345.37, 20.53, -855.83), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(339.00, 21.54, -855.95), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(334.51, 21.54, -850.11), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(328.83, 21.54, -855.97), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(335.00, 21.54, -861.70), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(324.43, 21.54, -861.35), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(324.69, 21.54, -850.36), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(318.73, 21.54, -855.70), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(313.47, 21.54, -861.90), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(308.27, 21.54, -855.88), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(314.49, 21.54, -850.04), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(303.58, 21.54, -861.59), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(303.61, 21.54, -850.61), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(298.50, 21.54, -856.16), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(393.87, 2.87, -892.93), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(394.65, 2.87, -902.16), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(389.37, 5.04, -892.40), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(389.57, 5.04, -903.24), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(383.37, 7.79, -892.63), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(383.64, 7.79, -903.27), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(378.64, 9.35, -892.48), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(378.64, 9.35, -903.24), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(373.27, 11.53, -892.90), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(372.82, 11.53, -903.33), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(368.47, 11.53, -892.69), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(367.91, 11.53, -903.02), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(362.88, 11.53, -894.04), size = Vector3.new(4.00, 0.50, 7.00)}, 
            	{pos = Vector3.new(358.03, 11.53, -901.74), size = Vector3.new(4.00, 0.50, 6.00)}, 
            	{pos = Vector3.new(352.36, 11.53, -894.75), size = Vector3.new(4.00, 0.50, 6.00)}, 
            	{pos = Vector3.new(347.47, 11.53, -899.21), size = Vector3.new(4.00, 0.50, 6.00)}, 
            	{pos = Vector3.new(333.21, 11.53, -897.81), size = Vector3.new(5.00, 0.50, 12.00)}, 
            	{pos = Vector3.new(325.73, 11.53, -898.53), size = Vector3.new(5.00, 0.50, 12.00)}, 
            	{pos = Vector3.new(318.25, 11.53, -897.79), size = Vector3.new(5.00, 0.50, 11.00)}, 
            	{pos = Vector3.new(310.71, 11.53, -898.95), size = Vector3.new(5.00, 0.50, 12.00)}, 
            	{pos = Vector3.new(303.10, 11.53, -898.29), size = Vector3.new(5.00, 0.50, 12.00)}, 
            	{pos = Vector3.new(295.54, 11.53, -898.01), size = Vector3.new(5.00, 0.50, 12.00)}, 
            	{pos = Vector3.new(288.21, 11.53, -898.79), size = Vector3.new(5.00, 0.50, 12.00)}, 
            	{pos = Vector3.new(149.54, 1.04, -856.00), size = Vector3.new(3.00, 0.50, 13.00)}, 
            	{pos = Vector3.new(148.21, 7.50, -855.93), size = Vector3.new(4.00, 0.50, 13.00)}, 
            	{pos = Vector3.new(148.27, 13.38, -856.27), size = Vector3.new(4.00, 0.50, 13.00)}, 
            	{pos = Vector3.new(162.71, 13.70, -859.82), size = Vector3.new(8.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(170.73, 13.70, -852.89), size = Vector3.new(8.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(181.41, 13.70, -859.17), size = Vector3.new(8.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(190.97, 13.70, -853.25), size = Vector3.new(8.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(217.92, 12.53, -848.28), size = Vector3.new(32.00, 0.50, 4.00)}, 
            	{pos = Vector3.new(217.99, 13.04, -863.62), size = Vector3.new(29.00, 0.50, 4.00)}, 
            	{pos = Vector3.new(243.52, 12.04, -855.57), size = Vector3.new(14.00, 0.50, 3.00)}, 
            	{pos = Vector3.new(150.43, 5.27, -897.87), size = Vector3.new(4.00, 0.50, 16.00)}, 
            	{pos = Vector3.new(150.71, 13.28, -898.27), size = Vector3.new(4.00, 0.50, 17.00)}, 
            	{pos = Vector3.new(150.28, 21.29, -898.42), size = Vector3.new(4.00, 0.50, 15.00)}, 
            	{pos = Vector3.new(150.45, 29.30, -898.11), size = Vector3.new(4.00, 0.50, 16.00)}, 
            	{pos = Vector3.new(150.52, 37.31, -898.44), size = Vector3.new(4.00, 0.50, 15.00)}, 
            	{pos = Vector3.new(150.56, 45.32, -897.73), size = Vector3.new(4.00, 0.50, 15.00)}, 
            	{pos = Vector3.new(150.95, 53.33, -898.02), size = Vector3.new(4.00, 0.50, 16.00)}, 
            	{pos = Vector3.new(167.23, 53.26, -903.84), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(172.90, 53.26, -900.06), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(167.09, 53.26, -890.73), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(181.65, 53.26, -902.00), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(180.48, 53.26, -893.06), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(201.10, 53.33, -897.28), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(212.50, 53.33, -897.85), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(225.52, 53.33, -898.25), size = Vector3.new(5.00, 0.50, 5.00)}, 
            	{pos = Vector3.new(237.61, 53.33, -897.82), size = Vector3.new(5.00, 0.50, 5.00)}, 
            }

            local function CreateHitboxes() 
            	for _, v in ipairs(data) do 
            		local p = Instance.new("Part", workspace) 
            		p.Name = "VAKHA_Hitbox" 
            		p.Size = v.size 
            		p.Position = v.pos 
            		p.Anchored = true 
            		p.Transparency = 1 
            		local Box = Instance.new("SelectionBox", p) 
            		Box.Adornee = p 
            		Box.Color3 = Color3.fromRGB(150, 60, 0) 
            		Box.SurfaceColor3 = Color3.fromRGB(255, 140, 0) 
            		Box.SurfaceTransparency = 0.5 
            		Box.LineThickness = 0.08 
            		table.insert(Hitboxes, p) 
            	end 
            end

            ParkourTab:Toggle({ 
            	Title = "Drip menu auxiliares ⛩️ (Parkours)", 
            	Desc = "Ativa/desativa as hitboxes de parkour", 
            	Value = false, 
            	Callback = function(Value) 
            		ParkourEnabled = Value 
            		if ParkourEnabled then 
            			CreateHitboxes() 
            			WindUI:Notify({ 
            				Title = "Parkour", 
            				Content = "Hitboxes ativados!", 
            				Icon = "check", 
            				Duration = 2, 
            			}) 
            		else 
            			for _, v in ipairs(Hitboxes) do 
            				if v and v.Parent then v:Destroy() end 
            			end 
            			Hitboxes = {} 
            			WindUI:Notify({ 
            				Title = "Parkour", 
            				Content = "Hitboxes removidos!", 
            				Icon = "check", 
            				Duration = 2, 
            			}) 
            		end 
            	end, 
            })

            RunService.Heartbeat:Connect(function() 
            	if not ParkourEnabled then return end 
            	local char = player.Character 
            	local hrp = char and char:FindFirstChild("HumanoidRootPart") 
            	if not hrp then return end 
            	local velY = hrp.AssemblyLinearVelocity.Y 
            	for _, part in ipairs(Hitboxes) do 
            		if part and part.Parent then 
            			part.CanCollide = (velY <= 0.5 and hrp.Position.Y > (part.Position.Y + part.Size.Y / 2 - 1)) 
            		end 
            	end 
            end)
        end)
        if not ok then warn("[Makima Scripts] Aba Drip \"Auxilios\" falhou:", err) end
    end

    do
        local ok, err = pcall(function()
            local CombatTab = Window:Tab({ Title = "Combat", Icon = "swords", })
            CombatTab:Section({ Title = "Hitbox Expander" })

            local HitboxConfig = { Enabled = false, Size = 5, Transparency = 0.5, Color = Color3.fromRGB(255, 140, 0) } 
            local OriginalSizes = {} 

            local function RestoreHitboxes() 
                for p, originalSize in pairs(OriginalSizes) do 
                    if p and p.Character then 
                        local root = p.Character:FindFirstChild("HumanoidRootPart") 
                        if root then 
                            root.Size = originalSize 
                            root.Transparency = 1 
                            local box = root:FindFirstChild("ProdigizxHitboxVisual") 
                            if box then box:Destroy() end 
                        end 
                    end 
                end 
                OriginalSizes = {} 
            end

            CombatTab:Toggle({ 
                Title = "Ativar Hitbox Expander", 
                Desc = "Aumenta o tamanho da hitbox dos jogadores", 
                Value = false, 
                Callback = function(Value) 
                    HitboxConfig.Enabled = Value 
                    if not Value then RestoreHitboxes() end 
                end 
            })
            CombatTab:Input({ 
                Title = "Tamanho da Hitbox", 
                Desc = "Valor entre 2 e 50", 
                Placeholder = "Ex: 5", 
                Value = "5", 
                Callback = function(Text) 
                    local num = tonumber(Text) 
                    if num then HitboxConfig.Size = math.clamp(num, 2, 50) end 
                end 
            })
            CombatTab:Input({ 
                Title = "Transparência", 
                Desc = "Valor entre 0 e 1", 
                Placeholder = "Ex: 0.5", 
                Value = "0.5", 
                Callback = function(Text) 
                    local num = tonumber(Text) 
                    if num then HitboxConfig.Transparency = math.clamp(num, 0, 1) end 
                end 
            })

            RunService.RenderStepped:Connect(function() 
                if not HitboxConfig.Enabled then return end 
                for _, p in ipairs(Players:GetPlayers()) do 
                    if p ~= player and p.Character then 
                        local root = p.Character:FindFirstChild("HumanoidRootPart") 
                        local hum = p.Character:FindFirstChildOfClass("Humanoid") 
                        if root and hum and hum.Health > 0 then 
                            if not OriginalSizes[p] then OriginalSizes[p] = root.Size end 
                            local targetSize = Vector3.new(HitboxConfig.Size, HitboxConfig.Size, HitboxConfig.Size) 
                            if root.Size ~= targetSize then 
                                root.Size = targetSize 
                                root.CanCollide = false 
                            end 
                            local visualBox = root:FindFirstChild("ProdigizxHitboxVisual") 
                            if not visualBox then 
                                visualBox = Instance.new("SelectionBox") 
                                visualBox.Name = "ProdigizxHitboxVisual" 
                                visualBox.Adornee = root 
                                visualBox.Parent = root 
                            end 
                            visualBox.Color3 = HitboxConfig.Color 
                            visualBox.SurfaceColor3 = HitboxConfig.Color 
                            visualBox.SurfaceTransparency = HitboxConfig.Transparency 
                            visualBox.LineThickness = 0.05 
                        end 
                    end 
                end 
            end)

            Players.PlayerRemoving:Connect(function(p) OriginalSizes[p] = nil end)

            CombatTab:Section({
                Title = "Loja"
            })

            CombatTab:Paragraph({
                Title = "Script de Loja",
                Desc = "Abre uma loja com opções de compra/equipamento de itens."
            })

            CombatTab:Button({
                Title = "Abrir Loja",
                Desc = "Executa o script da loja",
                Callback = function()
                    local success, err = pcall(function()
                        loadstring(game:HttpGet("https://raw.githubusercontent.com/SpaceXecho/Gun/refs/heads/main/obfuscated_script-1787610239075.lua.txt"))()
                    end)

                    if not success then
                        warn("Erro ao abrir a loja: " .. tostring(err))
                    end
                end
            })
        end)
        if not ok then warn("[Makima Scripts] Aba Drip \"Combat\" falhou:", err) end
    end

    do
        local ok, err = pcall(function()
            local CharsTab = Window:Tab({ Title = "Chars", Icon = "user", })

            local function CopyCharCommand(charName) 
                local command = ";char me " .. charName 
                if setclipboard then 
                    setclipboard(command) 
                elseif toclipboard then 
                    toclipboard(command) 
                end 
                WindUI:Notify({ 
                    Title = "Chars", 
                    Content = "Comando copiado: " .. command, 
                    Duration = 2 
                }) 
            end

            CharsTab:Button({ Title = "NEMOKJK", Description = "Copiar ;char me NEMOKJK", Callback = function() CopyCharCommand("NEMOKJK") end })
            CharsTab:Button({ Title = "Mk_luluhh", Description = "Copiar ;char me Mk_luluhh", Callback = function() CopyCharCommand("Mk_luluhh") end })
            CharsTab:Button({ Title = "Gabriel_USSF", Description = "Copiar ;char me Gabriel_USSF", Callback = function() CopyCharCommand("Gabriel_USSF") end })
            CharsTab:Button({ Title = "Poug", Description = "Copiar ;char me Poug", Callback = function() CopyCharCommand("Poug") end })
            CharsTab:Button({ Title = "therealtoddyx", Description = "Copiar ;char me therealtoddyx", Callback = function() CopyCharCommand("therealtoddyx") end })
            CharsTab:Button({ Title = "Zscoupz_00", Description = "Copiar ;char me Zscoupz_00", Callback = function() CopyCharCommand("Zscoupz_00") end })
            CharsTab:Button({ Title = "OIIILUKAZ", Description = "Copiar ;char me OIIILUKAZ", Callback = function() CopyCharCommand("OIIILUKAZ") end })
            CharsTab:Button({ Title = "oboina05", Description = "Copiar ;char me oboina05", Callback = function() CopyCharCommand("oboina05") end })
            CharsTab:Button({ Title = "Futuro_marechal", Description = " Somente Marechal | Copiar ;char me Futuro_marechal", Callback = function() CopyCharCommand("Futuro_marechal") end })
            CharsTab:Button({ Title = "Murilo_ms1", Description = "Copiar ;char me Murilo_ms1", Callback = function() CopyCharCommand("Murilo_ms1") end })
            CharsTab:Button({ Title = "Feiquinbr", Description = "Copiar ;char me Feiquinbr", Callback = function() CopyCharCommand("Feiquinbr") end })
            CharsTab:Button({ Title = "Brasil2020p", Description = "Copiar ;char me Brasil2020p", Callback = function() CopyCharCommand("Brasil2020p") end })
            CharsTab:Button({ Title = "s4enrique", Description = "Copiar ;char me s4enrique", Callback = function() CopyCharCommand("s4enrique") end })
            CharsTab:Button({ Title = "admdorminhoco", Description = "Copiar ;char me admdorminhoco", Callback = function() CopyCharCommand("admdorminhoco") end })
            CharsTab:Button({ Title = "fazerftw", Description = "Copiar ;char me fazerftw", Callback = function() CopyCharCommand("fazerftw") end })
            CharsTab:Button({ Title = "danielgamer8464", Description = "Copiar ;char me danielgamer8464", Callback = function() CopyCharCommand("danielgamer8464") end })
            CharsTab:Button({ Title = "marasawfan", Description = "Copiar ;char me marasawfan", Callback = function() CopyCharCommand("marasawfan") end })
            CharsTab:Button({ Title = "apoiata", Description = "Copiar ;char me apoiata", Callback = function() CopyCharCommand("apoiata") end })
            CharsTab:Button({ Title = "tommacena975", Description = "Copiar ;char me tommacena975", Callback = function() CopyCharCommand("tommacena975") end })
        end)
        if not ok then warn("[Makima Scripts] Aba Drip \"Chars\" falhou:", err) end
    end

    do
        local ok, err = pcall(function()
            local TafTab = Window:Tab({
                Title = "Tools",
                Icon = "clipboard",
            })

            TafTab:Section({
                Title = "Ferramentas"
            })

            TafTab:Button({
                Title = "TAFs",
                Desc = "Abrir Cola TAFs",
                Icon = "clipboard",
                Callback = function()

                    local success, err = pcall(function()

                        local Players = game:GetService("Players")
                        local UserInputService = game:GetService("UserInputService")
                        local TweenService = game:GetService("TweenService")

                        local player = Players.LocalPlayer
                        local playerGui = player:WaitForChild("PlayerGui")

                        -- Evita criar a GUI duas vezes
                        local oldGui = playerGui:FindFirstChild("DripTAF")
                        if oldGui then
                            oldGui:Destroy()
                        end

                        -- Paleta de Cores
                        local C = {
                            Background = Color3.fromRGB(15, 17, 23),
                            Sidebar = Color3.fromRGB(20, 23, 30),
                            Card = Color3.fromRGB(26, 30, 40),
                            CardHover = Color3.fromRGB(35, 40, 52),
                            Accent = Color3.fromRGB(0, 122, 255),
                            AccentHover = Color3.fromRGB(50, 150, 255),
                            Text = Color3.fromRGB(240, 243, 246),
                            TextDim = Color3.fromRGB(115, 125, 140),
                            Success = Color3.fromRGB(46, 204, 113),
                            Border = Color3.fromRGB(40, 46, 60)
                        }

                        -- GUI
                        local ScreenGui = Instance.new("ScreenGui")
                        ScreenGui.Name = "DripTAF"
                        ScreenGui.ResetOnSpawn = false
                        ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
                        ScreenGui.Parent = playerGui

                        -- Botão de alternar
                        local ToggleBtn = Instance.new("TextButton")
                        ToggleBtn.Name = "Toggle"
                        ToggleBtn.Size = UDim2.new(0, 180, 0, 46)
                        ToggleBtn.Position = UDim2.new(0, 25, 0.5, -23)
                        ToggleBtn.BackgroundColor3 = C.Accent
                        ToggleBtn.Text = "☰ DRIP TAF"
                        ToggleBtn.TextColor3 = Color3.new(1, 1, 1)
                        ToggleBtn.TextSize = 13
                        ToggleBtn.Font = Enum.Font.SourceSansBold
                        ToggleBtn.AutoButtonColor = false
                        ToggleBtn.Parent = ScreenGui

                        local ToggleCorner = Instance.new("UICorner")
                        ToggleCorner.CornerRadius = UDim.new(0, 12)
                        ToggleCorner.Parent = ToggleBtn

                        -- Janela principal
                        local MainFrame = Instance.new("Frame")
                        MainFrame.Name = "MainFrame"
                        MainFrame.Size = UDim2.new(0, 640, 0, 460)
                        MainFrame.Position = UDim2.new(0.5, -320, 0.5, -230)
                        MainFrame.BackgroundColor3 = C.Background
                        MainFrame.Visible = false
                        MainFrame.ClipsDescendants = true
                        MainFrame.Parent = ScreenGui

                        local MainCorner = Instance.new("UICorner")
                        MainCorner.CornerRadius = UDim.new(0, 16)
                        MainCorner.Parent = MainFrame

                        -- Cabeçalho
                        local Header = Instance.new("Frame")
                        Header.Size = UDim2.new(1, 0, 0, 65)
                        Header.BackgroundColor3 = C.Sidebar
                        Header.BorderSizePixel = 0
                        Header.Parent = MainFrame

                        local Title = Instance.new("TextLabel")
                        Title.Size = UDim2.new(1, -140, 1, 0)
                        Title.Position = UDim2.new(0, 24, 0, 0)
                        Title.BackgroundTransparency = 1
                        Title.Text = "DRIP TAF"
                        Title.TextColor3 = C.Text
                        Title.TextSize = 15
                        Title.Font = Enum.Font.SourceSansBold
                        Title.TextXAlignment = Enum.TextXAlignment.Left
                        Title.Parent = Header

                        local CloseBtn = Instance.new("TextButton")
                        CloseBtn.Size = UDim2.new(0, 34, 0, 34)
                        CloseBtn.Position = UDim2.new(1, -45, 0.5, -17)
                        CloseBtn.BackgroundColor3 = C.Card
                        CloseBtn.Text = "✕"
                        CloseBtn.TextColor3 = C.Text
                        CloseBtn.TextSize = 14
                        CloseBtn.Font = Enum.Font.SourceSansBold
                        CloseBtn.AutoButtonColor = false
                        CloseBtn.Parent = Header

                        local CloseCorner = Instance.new("UICorner")
                        CloseCorner.CornerRadius = UDim.new(0, 10)
                        CloseCorner.Parent = CloseBtn

                        -- Sidebar
                        local Sidebar = Instance.new("ScrollingFrame")
                        Sidebar.Size = UDim2.new(0, 200, 1, -65)
                        Sidebar.Position = UDim2.new(0, 0, 0, 65)
                        Sidebar.BackgroundColor3 = C.Sidebar
                        Sidebar.BorderSizePixel = 0
                        Sidebar.CanvasSize = UDim2.new(0, 0, 0, 500)
                        Sidebar.ScrollBarThickness = 2
                        Sidebar.ScrollBarImageColor3 = C.Accent
                        Sidebar.Parent = MainFrame

                        local SidebarList = Instance.new("UIListLayout")
                        SidebarList.SortOrder = Enum.SortOrder.LayoutOrder
                        SidebarList.Padding = UDim.new(0, 6)
                        SidebarList.Parent = Sidebar

                        local SidebarPadding = Instance.new("UIPadding")
                        SidebarPadding.PaddingTop = UDim.new(0, 12)
                        SidebarPadding.PaddingLeft = UDim.new(0, 10)
                        SidebarPadding.PaddingRight = UDim.new(0, 10)
                        SidebarPadding.Parent = Sidebar

                        -- Área de conteúdo
                        local ContentArea = Instance.new("Frame")
                        ContentArea.Size = UDim2.new(1, -200, 1, -65)
                        ContentArea.Position = UDim2.new(0, 200, 0, 65)
                        ContentArea.BackgroundColor3 = C.Background
                        ContentArea.ClipsDescendants = true
                        ContentArea.Parent = MainFrame

                        local PagesFolder = Instance.new("Folder")
                        PagesFolder.Parent = ContentArea

                        local currentTab = nil
                        local tabData = {}

                        -- Card
                        local function createCard(parent, text, copy)
                            local Card = Instance.new("Frame")
                            Card.Size = UDim2.new(1, 0, 0, 55)
                            Card.BackgroundColor3 = C.Card
                            Card.Parent = parent

                            local CardCorner = Instance.new("UICorner")
                            CardCorner.CornerRadius = UDim.new(0, 10)
                            CardCorner.Parent = Card

                            local TextLabel = Instance.new("TextLabel")
                            TextLabel.Size = UDim2.new(1, -90, 1, 0)
                            TextLabel.Position = UDim2.new(0, 15, 0, 0)
                            TextLabel.BackgroundTransparency = 1
                            TextLabel.Text = text
                            TextLabel.TextColor3 = C.Text
                            TextLabel.TextSize = 13
                            TextLabel.Font = Enum.Font.SourceSans
                            TextLabel.TextWrapped = true
                            TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                            TextLabel.Parent = Card

                            local CopyBtn = Instance.new("TextButton")
                            CopyBtn.Size = UDim2.new(0, 75, 0, 28)
                            CopyBtn.Position = UDim2.new(1, -83, 0.5, -14)
                            CopyBtn.BackgroundColor3 = C.Accent
                            CopyBtn.Text = "Copiar"
                            CopyBtn.TextColor3 = Color3.new(1, 1, 1)
                            CopyBtn.TextSize = 11
                            CopyBtn.Font = Enum.Font.SourceSansBold
                            CopyBtn.AutoButtonColor = false
                            CopyBtn.Parent = Card

                            local CopyCorner = Instance.new("UICorner")
                            CopyCorner.CornerRadius = UDim.new(0, 8)
                            CopyCorner.Parent = CopyBtn

                            CopyBtn.MouseButton1Click:Connect(function()
                                pcall(function()
                                    if setclipboard then
                                        setclipboard(copy)
                                    end
                                end)

                                CopyBtn.Text = "✔ Copiado"
                                CopyBtn.BackgroundColor3 = C.Success

                                task.wait(1.5)

                                if CopyBtn and CopyBtn.Parent then
                                    CopyBtn.Text = "Copiar"
                                    CopyBtn.BackgroundColor3 = C.Accent
                                end
                            end)

                            return Card
                        end

                        -- Seleção de abas
                        local function selectTab(name, btn, label, icon, page)
                            if currentTab == name then
                                return
                            end

                            if currentTab then
                                local prev = tabData[currentTab]

                                if prev then
                                    TweenService:Create(
                                        prev.btn,
                                        TweenInfo.new(0.2),
                                        {BackgroundTransparency = 1}
                                    ):Play()

                                    prev.label.TextColor3 = C.TextDim
                                    prev.icon.TextColor3 = C.TextDim
                                end

                                local prevPage = PagesFolder:FindFirstChild(currentTab .. "_Page")

                                if prevPage then
                                    prevPage.Visible = false
                                end
                            end

                            currentTab = name

                            TweenService:Create(
                                btn,
                                TweenInfo.new(0.2),
                                {BackgroundTransparency = 0}
                            ):Play()

                            btn.BackgroundColor3 = C.Card
                            label.TextColor3 = C.Text
                            icon.TextColor3 = C.Accent

                            if page then
                                page.Visible = true
                            end
                        end

                        -- Criar aba
                        local function createTab(name, icon)
                            local TabBtn = Instance.new("TextButton")
                            TabBtn.Size = UDim2.new(1, 0, 0, 40)
                            TabBtn.BackgroundTransparency = 1
                            TabBtn.Text = ""
                            TabBtn.AutoButtonColor = false
                            TabBtn.Parent = Sidebar

                            local TabCorner = Instance.new("UICorner")
                            TabCorner.CornerRadius = UDim.new(0, 8)
                            TabCorner.Parent = TabBtn

                            local TabLayout = Instance.new("UIListLayout")
                            TabLayout.FillDirection = Enum.FillDirection.Horizontal
                            TabLayout.Padding = UDim.new(0, 12)
                            TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                            TabLayout.Parent = TabBtn

                            local TabPadding = Instance.new("UIPadding")
                            TabPadding.PaddingLeft = UDim.new(0, 12)
                            TabPadding.Parent = TabBtn

                            local IconLabel = Instance.new("TextLabel")
                            IconLabel.Size = UDim2.new(0, 20, 1, 0)
                            IconLabel.BackgroundTransparency = 1
                            IconLabel.Text = icon
                            IconLabel.TextSize = 15
                            IconLabel.TextColor3 = C.TextDim
                            IconLabel.Parent = TabBtn

                            local NameLabel = Instance.new("TextLabel")
                            NameLabel.Size = UDim2.new(1, -35, 1, 0)
                            NameLabel.BackgroundTransparency = 1
                            NameLabel.Text = name
                            NameLabel.TextColor3 = C.TextDim
                            NameLabel.TextSize = 12
                            NameLabel.Font = Enum.Font.SourceSans
                            NameLabel.TextXAlignment = Enum.TextXAlignment.Left
                            NameLabel.Parent = TabBtn

                            local Page = Instance.new("Frame")
                            Page.Name = name .. "_Page"
                            Page.Size = UDim2.new(1, -20, 1, -20)
                            Page.Position = UDim2.new(0, 10, 0, 10)
                            Page.BackgroundTransparency = 1
                            Page.Visible = false
                            Page.Parent = PagesFolder

                            local Scroll = Instance.new("ScrollingFrame")
                            Scroll.Size = UDim2.new(1, 0, 1, 0)
                            Scroll.BackgroundTransparency = 1
                            Scroll.CanvasSize = UDim2.new(0, 0, 0, 800)
                            Scroll.ScrollBarThickness = 3
                            Scroll.ScrollBarImageColor3 = C.Accent
                            Scroll.Parent = Page

                            local PageLayout = Instance.new("UIListLayout")
                            PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
                            PageLayout.Padding = UDim.new(0, 8)
                            PageLayout.Parent = Scroll

                            PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                                Scroll.CanvasSize = UDim2.new(
                                    0,
                                    0,
                                    0,
                                    PageLayout.AbsoluteContentSize.Y + 20
                                )
                            end)

                            -- Conteúdo
                            if name == "BFE" then

                                createCard(Scroll, "👻 BFE = Fantasma.", "BFE = Fantasma.")
                                createCard(Scroll, "👤 Criador: MaxTheJp1. Criado: 1983.", "MaxTheJp1")
                                createCard(Scroll, "🛡️ O escudo do BFE possui fundo preto com bordas amarelas.", "O escudo do BFE possui fundo preto com bordas amarelas.")
                                createCard(Scroll, "🎖️ Comandante: NATANHMELLO4.", "NATANHMELLO4")
                                createCard(Scroll, "🎖️ Subcomandante: RenanFoxiy.", "RenanFoxiy")
                                createCard(Scroll, "👻 Lema BFE:\n⚔️ Qualquer missão, em qualquer lugar, a qualquer hora, de qualquer maneira.", "Qualquer missão, em qualquer lugar, a qualquer hora, de qualquer maneira.")
                                createCard(Scroll, "🫡 Saudações, senhores Agentes.", "Saudações, senhores Agentes.")
                                createCard(Scroll, "🫡 Saudações, senhores Fantasmas.", "Saudações, senhores Fantasmas.")
                                createCard(Scroll, "🫡 Saudações, senhor Agente.", "Saudações, senhor Agente.")
                                createCard(Scroll, "🫡 Saudações, senhor Fantasma.", "Saudações, senhor Fantasma.")
                                createCard(Scroll, "📜 Com licença, senhor Agente.", "Com licença, senhor Agente.")
                                createCard(Scroll, "📜 Com licença, senhor Fantasma.", "Com licença, senhor Fantasma.")
                                createCard(Scroll, "📜 Licença, senhor Agente.", "Licença, senhor Agente.")
                                createCard(Scroll, "📜 Licença, senhor Fantasma.", "Licença, senhor Fantasma.")

                            elseif name == "BPE" then

                                createCard(Scroll, "👮 BPE = Policial.", "BPE = Policial.")
                                createCard(Scroll, "🎖️ Comandante: zCostasz.", "zCostasz")
                                createCard(Scroll, "🎖️ Subcomandante: Matheuslindo587.", "Matheuslindo587")
                                createCard(Scroll, "📜 Lema:\nOrientar o Responsável, Corrigir o Irresponsável, Prender o Incorrigível.", "Orientar o Responsável, Corrigir o Irresponsável, Prender o Incorrigível.")
                                createCard(Scroll, "🗣️ PRONOMES;", "")
                                createCard(Scroll, "🫡 Saudações, senhores Policiais.", "Saudações, senhores Policiais.")
                                createCard(Scroll, "🫡 Saudação, senhor Policial.", "Saudação, senhor Policial.")

                            elseif name == "BAC" then

                                createCard(Scroll, "💀 BAC = INFORMAÇÕES", "BAC = INFORMAÇÕES")
                                createCard(Scroll, "👤 Dono: MateusHgz.", "MateusHgz")
                                createCard(Scroll, "🎖️ Comandante: SasukeePro202.", "SasukeePro202")
                                createCard(Scroll, "🎖️ Subcomandante: DanielSxS2.", "DanielSxS2")
                                createCard(Scroll, "⚔️ Lema da BAC:\nO máximo de confusão, morte e destruição na retaguarda do inimigo.", "O máximo de confusão, morte e destruição na retaguarda do inimigo.")
                                createCard(Scroll, "🐎 Lema REC-MEC:\nHaverá sempre uma Cavalaria! & Aço na mente, motor no peito e honra na missão!", "Haverá sempre uma Cavalaria! & Aço na mente, motor no peito e honra na missão!")
                                createCard(Scroll, "👮 Lema BPE:\nOrientar o Responsável, Corrigir o Irresponsável, Prender o Incorrigível.", "Orientar o Responsável, Corrigir o Irresponsável, Prender o Incorrigível.")
                                createCard(Scroll, "🫡 SAUDAÇÕES:\nSaudações, senhor Comando.", "Saudações, senhor Comando.")
                                createCard(Scroll, "🫡 Saudações, senhores Comandos.", "Saudações, senhores Comandos.")
                                createCard(Scroll, "🫡 Saudações, senhores Policiais.", "Saudações, senhores Policiais.")
                                createCard(Scroll, "🫡 Saudações, senhor Policial.", "Saudações, senhor Policial.")

                            elseif name == "CIE" then

                                createCard(Scroll, "🕵️ CIE = Agente.", "CIE = Agente.")
                                createCard(Scroll, "👤 Criador: vicofjgfhf.", "vicofjgfhf")
                                createCard(Scroll, "👤 Sub criador: RIP_dabfj8w.", "RIP_dabfj8w")
                                createCard(Scroll, "🎖️ Comandante: eriqurrr.", "eriqurrr")
                                createCard(Scroll, "🎖️ Subcomandante: nohanrtop.", "nohanrtop")
                                createCard(Scroll, "🧠 Lema CIE:\nInteligência para Vitória & Saber para Prever.", "Inteligência para Vitória & Saber para Prever.")
                                createCard(Scroll, "👻 Lema BFE:\nQualquer missão, em qualquer lugar, a qualquer hora, de qualquer maneira.", "Qualquer missão, em qualquer lugar, a qualquer hora, de qualquer maneira.")
                                createCard(Scroll, "🫡 Saudações, senhores Agentes.", "Saudações, senhores Agentes.")
                                createCard(Scroll, "🫡 Saudações, senhores Fantasmas.", "Saudações, senhores Fantasmas.")
                                createCard(Scroll, "🫡 Saudações, senhor Agente.", "Saudações, senhor Agente.")
                                createCard(Scroll, "🫡 Saudações, senhor Fantasma.", "Saudações, senhor Fantasma.")

                            elseif name == "CYBER" then

                                createCard(Scroll, "💻 CYBER = Analista.", "CYBER = Analista.")
                                createCard(Scroll, "👤 Criador: wAnTee16j5156.", "wAnTee16j5156")
                                createCard(Scroll, "👑 Dono: MaxTheJp1.", "MaxTheJp1")
                                createCard(Scroll, "👑 Dono: ItsMeLyrio.", "ItsMeLyrio")
                                createCard(Scroll, "👑 Dono: Gabriel2444q.", "Gabriel2444q")
                                createCard(Scroll, "🎖️ Comandante: highhandry98.", "highhandry98")
                                createCard(Scroll, "🛡️ Lema:\nSegurança no ciberespaço, soberania para a Nação.", "Segurança no ciberespaço, soberania para a Nação.")
                                createCard(Scroll, "🤝 Saudações, senhores Analistas.", "Saudações, senhores Analistas.")
                                createCard(Scroll, "🔒 JURO:\nGUARDAR SIGILO SOBRE TUDO QUE VER E OUVIR NO COMDCIBER!", "GUARDAR SIGILO SOBRE TUDO QUE VER E OUVIR NO COMDCIBER!")

                            elseif name == "Caat" then

                                createCard(Scroll, "🌵 CAATINGA = Guardiões da Caatinga.", "CAATINGA = Guardiões da Caatinga.")
                                createCard(Scroll, "🎖️ Subcomandante: gabrielcm04.", "gabrielcm04")
                                createCard(Scroll, "🌵 Lema:\nO pai cria, a mãe educa e a Caatinga elimina.", "O pai cria, a mãe educa e a Caatinga elimina.")
                                createCard(Scroll, "🫡 Saudações, senhores Guardiões.", "Saudações, senhores Guardiões.")

                            elseif name == "Rec-Mec" then

                                createCard(Scroll, "🐎 REC-MEC = Cavaleiros.", "REC-MEC = Cavaleiros.")
                                createCard(Scroll, "🎖️ Comandante: terro_2433.", "terro_2433")
                                createCard(Scroll, "🎖️ Subcomandante: Contanum5bl.", "Contanum5bl")
                                createCard(Scroll, "⚔️ Lema:\nHaverá sempre uma Cavalaria!", "Haverá sempre uma Cavalaria!")
                                createCard(Scroll, "🫡 Saudações, senhores Cavaleiros.", "Saudações, senhores Cavaleiros.")
                                createCard(Scroll, "📢 ATENÇÃO PELOTÃO, MARCHEM!", "ATENÇÃO PELOTÃO, MARCHEM!")

                            elseif name == "AMAN" then

                                createCard(Scroll, "🎓 AMAN = Academia Militar.", "AMAN = Academia Militar.")
                                createCard(Scroll, "⭐ Lema:\nCasa de Valores, Escola de Líderes.", "Casa de Valores, Escola de Líderes.")
                                createCard(Scroll, "🫡 Saudações, senhores Cadetes.", "Saudações, senhores Cadetes.")

           

                            end

                            TabBtn.MouseButton1Click:Connect(function()
                                selectTab(name, TabBtn, NameLabel, IconLabel, Page)
                            end)

                            tabData[name] = {btn = TabBtn, label = NameLabel, icon = IconLabel}

                            return TabBtn, NameLabel, IconLabel, Page
                        end

                        ToggleBtn.MouseButton1Click:Connect(function()
                            MainFrame.Visible = not MainFrame.Visible
                        end)

                        CloseBtn.MouseButton1Click:Connect(function()
                            MainFrame.Visible = false
                        end)

                        -- Criar as abas
                        local tafList = {
                            {"BFE", "👻"},
                            {"BPE", "👮"},
                            {"BAC", "💀"},
                            {"CIE", "🕵️"},
                            {"CYBER", "💻"},
                            {"Caat", "🌵"},
                            {"Rec-Mec", "🐎"},
                            {"AMAN", "🎓"},
                        }

                        for i, info in ipairs(tafList) do
                            local tb, nl, il, pg = createTab(info[1], info[2])
                            if i == 1 then
                                selectTab(info[1], tb, nl, il, pg)
                            end
                        end
                    end)

                    if not success then
                        warn("Erro ao abrir TAFs:", err)
                    end
                end,
            })

            TafTab:Button({
                Title = "Auto Gramática",
                Desc = "Abrir o Auto Gramática e corrigir automaticamente a gramática",
                Icon = "spell-check",
                Callback = function()
                    local success, err = pcall(function()
                        loadstring(game:HttpGet("https://raw.githubusercontent.com/SpaceXecho/AutoGramatic/refs/heads/main/obfuscated_script-1787614685489.lua.txt"))()
                    end)
                    if not success then
                        warn("Erro ao abrir o Auto Gramática:", err)
                    end
                end,
            })
        end)
        if not ok then warn("[Makima Scripts] Aba Drip \"Tools\" falhou:", err) end
    end

end

local dripOk, dripErr = pcall(LoadDripMenu)
if not dripOk then
    warn("[Makima Scripts] Falha ao carregar o Drip Menu:", dripErr)
    Notify("Drip Menu", "Algumas funções não carregaram.", 4)
end

--========================================================--
-- ABA EXTRAS (scripts do Drip Menu)
--========================================================--

local ExtrasTab = Window:Tab({
    Title = "Extras",
    Icon = "package",
})

ExtrasTab:Paragraph({
    Title = "Scripts do Drip Menu",
    Desc = "Cada botão abre o script correspondente.",
    Color = "Red",
})

local function AddExtra(title, desc, icon, fn)
    ExtrasTab:Button({
        Title = title,
        Desc = desc,
        Icon = icon,
        Callback = function()
            local ok, err = pcall(fn)
            if ok then
                Notify(title, "Executado.", 2)
            else
                warn("[Makima Scripts] " .. title .. ":", err)
                Notify(title, "Erro ao executar. Veja o console (F9).", 4)
            end
        end,
    })
end

AddExtra("Auto Spam de Algema", "Spam de resistência quando estiver algemado.", "lock", DripExtras.Algema)
AddExtra("Drip Kart", "Kart do Drip Menu.", "car", DripExtras.Kart)
AddExtra("Fake Patente", "Patente RP com cores e seletor de device.", "badge", DripExtras.FakePatente)
AddExtra("Gravador de Rota", "Grava rotas para o Auto Parkour.", "video", DripExtras.Gravador)
AddExtra("Hierarquia", "Lista de patentes e cargos.", "list", DripExtras.Hierarquia)
AddExtra("Laser Gun", "Entrega a Laser Gun.", "zap", DripExtras.LaserGun)
AddExtra("Portal Gun", "Entrega a Portal Gun.", "circle-dot", DripExtras.PortalGun)
AddExtra("Boost FPS", "Otimizador de FPS (Guiris).", "gauge", DripExtras.BoostFPS)

--========================================================--
-- OUTROS (CHAT + LINK DA KEY)
--========================================================--

local OutrosTab = Window:Tab({
    Title = "Outros",
    Icon = "settings",
})

OutrosTab:Button({
    Title = "Liberar Chat",
    Desc = "Reativa o Chat do Roblox.",
    Callback = function()
        pcall(function()
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
        end)
        pcall(function()
            StarterGui:SetCore("ChatActive", true)
        end)
        pcall(function()
            TextChatService.ChatWindowConfiguration.Enabled = true
        end)
        pcall(function()
            TextChatService.ChatInputBarConfiguration.Enabled = true
        end)
        Notify("Chat", "Comando executado.", 3)
    end,
})

OutrosTab:Button({
    Title = "Copiar Link da Key",
    Desc = "Copia o link para obter sua Key.",
    Callback = function()
        local link = GetPandaKeyLink()
        if link then
            Copy(link)
        else
            Notify("Panda Auth", "Não foi possível obter o link da Key.", 4)
        end
    end,
})

--========================================================--
-- CRÉDITOS
--========================================================--

local CreditosTab = Window:Tab({
    Title = "Créditos",
    Icon = "heart",
})

CreditosTab:Paragraph({
    Title = "Makima Scripts",
    Desc = "Hub desenvolvida por MakimaDev.",
    Color = "Red",
})

CreditosTab:Paragraph({
    Title = "Criador",
    Desc = "MakimaDev",
    Color = "Red",
})

CreditosTab:Paragraph({
    Title = "Funções do Drip Menu",
    Desc = "willz e prodigiozx",
    Color = "Red",
})

CreditosTab:Button({
    Title = "Discord",
    Desc = "discord.gg/4aEBbw7BQf",
    Callback = function()
        Copy(DISCORD_URL)
    end,
})

--========================================================--
-- FINAL
--========================================================--

Notify("Makima Scripts", "Hub carregada.", 3)

print("[Makima Scripts] Carregada.")
