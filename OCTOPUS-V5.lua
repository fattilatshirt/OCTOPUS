-- =============================================
-- KEY SYSTEM — Google Sheets Backend
-- =============================================
-- INSTRUCTIONS:
--   1) Create the Google Sheet and Apps Script as explained
--   2) Replace KEY_SERVER with your Web App URL
--   3) Insert keys into the Google Sheet
-- =============================================

local KEY_SERVER = "https://script.google.com/macros/s/AKfycbz_oUxeY6IHjgPAsS5d-FJTmKaHuS_BsCIlS1SkzT10ZBBGDh-6z3qMGGZrecnyr9w/exec"

local HttpService   = game:GetService("HttpService")
local TweenService2 = game:GetService("TweenService")
local Players2      = game:GetService("Players")
local plr2          = Players2.LocalPlayer
local pGui2         = plr2:WaitForChild("PlayerGui")

-- Logged user tier (nil = not logged in, "FREE", "VIP")
local userTier = nil

-- =============================================
-- LOGIN SCREEN
-- =============================================
local loginGui = Instance.new("ScreenGui")
loginGui.Name           = "KeyLogin"
loginGui.ResetOnSpawn   = false
loginGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
loginGui.IgnoreGuiInset = true
loginGui.Parent         = pGui2

-- Dark overlay
local overlay = Instance.new("Frame")
overlay.Size             = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
overlay.BackgroundTransparency = 0.3
overlay.BorderSizePixel  = 0
overlay.Parent           = loginGui

-- Center card
local card = Instance.new("Frame")
card.Size             = UDim2.new(0, 340, 0, 200)
card.Position         = UDim2.new(0.5, -170, 0.5, -100)
card.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
card.BorderSizePixel  = 0
card.Parent           = loginGui

local _cardCorner = Instance.new("UICorner")
_cardCorner.CornerRadius = UDim.new(0, 6)
_cardCorner.Parent = card

local _cardStroke = Instance.new("UIStroke")
_cardStroke.Color     = Color3.fromRGB(160, 0, 200)
_cardStroke.Thickness = 1.5
_cardStroke.Parent    = card

-- Title
local loginTitle = Instance.new("TextLabel")
loginTitle.Size               = UDim2.new(1, 0, 0, 36)
loginTitle.BackgroundTransparency = 1
loginTitle.Text               = "🔐  OCTOPUS V5"
loginTitle.TextColor3         = Color3.fromRGB(215, 215, 218)
loginTitle.TextSize           = 15
loginTitle.Font               = Enum.Font.GothamBold
loginTitle.Parent             = card

-- Subtitle
local loginSub = Instance.new("TextLabel")
loginSub.Size               = UDim2.new(1, 0, 0, 20)
loginSub.Position           = UDim2.new(0, 0, 0, 34)
loginSub.BackgroundTransparency = 1
loginSub.Text               = "Enter your Key to continue"
loginSub.TextColor3         = Color3.fromRGB(130, 130, 138)
loginSub.TextSize           = 11
loginSub.Font               = Enum.Font.Gotham
loginSub.Parent             = card

-- Key input field
local keyBox = Instance.new("TextBox")
keyBox.Size             = UDim2.new(1, -32, 0, 32)
keyBox.Position         = UDim2.new(0, 16, 0, 66)
keyBox.BackgroundColor3 = Color3.fromRGB(38, 38, 42)
keyBox.BorderSizePixel  = 0
keyBox.Text             = ""
keyBox.PlaceholderText  = "e.g. FREE-XXXX-XXXX  or  VIP-XXXX-XXXX"
keyBox.PlaceholderColor3 = Color3.fromRGB(90, 90, 100)
keyBox.TextColor3       = Color3.fromRGB(215, 215, 218)
keyBox.TextSize         = 11
keyBox.Font             = Enum.Font.Gotham
keyBox.ClearTextOnFocus = false
keyBox.Parent           = card

local _kbCorner = Instance.new("UICorner")
_kbCorner.CornerRadius = UDim.new(0, 4)
_kbCorner.Parent = keyBox

local _kbStroke = Instance.new("UIStroke")
_kbStroke.Color     = Color3.fromRGB(58, 58, 64)
_kbStroke.Thickness = 1
_kbStroke.Parent    = keyBox

-- Confirm button
local confirmBtn = Instance.new("TextButton")
confirmBtn.Size             = UDim2.new(1, -32, 0, 32)
confirmBtn.Position         = UDim2.new(0, 16, 0, 108)
confirmBtn.BackgroundColor3 = Color3.fromRGB(160, 0, 200)
confirmBtn.BorderSizePixel  = 0
confirmBtn.Text             = "Login"
confirmBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
confirmBtn.TextSize         = 12
confirmBtn.Font             = Enum.Font.GothamBold
confirmBtn.Parent           = card

local _cbCorner = Instance.new("UICorner")
_cbCorner.CornerRadius = UDim.new(0, 4)
_cbCorner.Parent = confirmBtn

-- Status label (error / loading)
local statusLbl = Instance.new("TextLabel")
statusLbl.Size               = UDim2.new(1, -16, 0, 20)
statusLbl.Position           = UDim2.new(0, 8, 0, 148)
statusLbl.BackgroundTransparency = 1
statusLbl.Text               = ""
statusLbl.TextColor3         = Color3.fromRGB(255, 80, 80)
statusLbl.TextSize           = 11
statusLbl.Font               = Enum.Font.Gotham
statusLbl.Parent             = card

-- Tier badge (shown after login)
local tierBadge = Instance.new("TextLabel")
tierBadge.Size               = UDim2.new(1, -16, 0, 20)
tierBadge.Position           = UDim2.new(0, 8, 0, 170)
tierBadge.BackgroundTransparency = 1
tierBadge.Text               = ""
tierBadge.TextColor3         = Color3.fromRGB(255, 215, 0)
tierBadge.TextSize           = 11
tierBadge.Font               = Enum.Font.GothamBold
tierBadge.Parent             = card

-- =============================================
-- HWID GENERATION
-- Combines ClientId + Username for a unique device ID
-- =============================================
local function getHWID()
    local clientId = "unknown"
    pcall(function()
        clientId = game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    local username = plr2.Name or "unknown"
    -- Simple hash: sum of bytes of the combined string
    local raw = clientId .. "|" .. username
    local hash = 0
    for i = 1, #raw do
        hash = (hash * 31 + string.byte(raw, i)) % 2147483647
    end
    return string.format("HWID-%s-%d", username:sub(1,6):upper(), hash)
end

local MY_HWID = getHWID()

-- =============================================
-- KEY VERIFICATION FUNCTION
-- =============================================
local function verifyKey(key)
    statusLbl.Text      = "⏳ Verifying..."
    statusLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    confirmBtn.Active   = false

    -- Compatible with exploit executors (Xeno, Synapse, KRNL, etc.)
    local httpFunc = (syn and syn.request) or (http and http.request) or (typeof(request) == "function" and request) or nil

    if not httpFunc then
        statusLbl.Text      = "❌ Executor does not support HTTP"
        statusLbl.TextColor3 = Color3.fromRGB(255, 80, 80)
        confirmBtn.Active   = true
        return
    end

    local ok, response = pcall(function()
        return httpFunc({
            Url    = KEY_SERVER .. "?key=" .. key .. "&hwid=" .. MY_HWID,
            Method = "GET",
        })
    end)

    confirmBtn.Active = true

    if not ok or not response then
        statusLbl.Text      = "❌ Server connection error"
        statusLbl.TextColor3 = Color3.fromRGB(255, 80, 80)
        return
    end

    local result = response.Body or ""

    if result == "EXPIRED" then
        statusLbl.Text      = "⌛ Key expired!"
        statusLbl.TextColor3 = Color3.fromRGB(255, 160, 0)
        return
    elseif result == "INVALID" then
        statusLbl.Text      = "❌ Invalid key"
        statusLbl.TextColor3 = Color3.fromRGB(255, 80, 80)
        return
    elseif result == "HWID_MISMATCH" then
        statusLbl.Text      = "🔒 Key already activated on another device"
        statusLbl.TextColor3 = Color3.fromRGB(255, 80, 80)
        return
    elseif result:sub(1, 3) == "OK:" then
        userTier = result:sub(4) -- "FREE" o "VIP"

        local badgeColor = userTier == "VIP"
            and Color3.fromRGB(255, 215, 0)
            or  Color3.fromRGB(120, 200, 120)

        tierBadge.Text      = "✅ " .. userTier .. " Access — Loading..."
        tierBadge.TextColor3 = badgeColor
        statusLbl.Text       = ""

        task.delay(1.2, function()
            loginGui:Destroy()
        end)
        return
    else
        statusLbl.Text      = "❌ Unrecognized server response"
        statusLbl.TextColor3 = Color3.fromRGB(255, 80, 80)
    end
end

-- Connect the button
confirmBtn.MouseButton1Click:Connect(function()
    local k = keyBox.Text:gsub("%s", "")
    if k == "" then
        statusLbl.Text      = "⚠️ Please enter a key"
        statusLbl.TextColor3 = Color3.fromRGB(255, 160, 0)
        return
    end
    verifyKey(k)
end)

-- Submit with Enter
keyBox.FocusLost:Connect(function(enter)
    if enter then
        local k = keyBox.Text:gsub("%s", "")
        if k ~= "" then verifyKey(k) end
    end
end)

-- Wait for login to complete before loading the menu
repeat task.wait(0.1) until userTier ~= nil
task.wait(0.3) -- small pause to avoid flash

-- =============================================
-- HELPER FUNCTION: tabs locked for FREE users
-- =============================================
-- (used below in switchTab)
local function isVIP()
    return userTier == "VIP"
end

-- =============================================
-- END KEY SYSTEM — main menu follows
-- =============================================

-- LocalScript: MenuPanel - Cheater Simulator
-- Dark/Purple theme | Place in: StarterPlayerScripts or StarterGui

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local player           = Players.LocalPlayer
local playerGui        = player:WaitForChild("PlayerGui")
local camera           = workspace.CurrentCamera
local mouse            = player:GetMouse()

-- =============================================
-- ESP SETTINGS
-- =============================================
local espSettings = {
    PlayerESP = {
        enabled             = false,
        fillColor           = Color3.fromRGB(170, 0, 210),
        fillTransparency    = 0.6,
        outlineColor        = Color3.fromRGB(170, 0, 210),
        outlineTransparency = 0,
    },
    NametagESP = {
        enabled        = false,
        textColor      = Color3.fromRGB(255, 255, 255),
        textSize       = 14,
        strokeColor    = Color3.fromRGB(0, 0, 0),
        verticalOffset = 2.4,
    },
    DistanceESP = {
        enabled        = false,
        textColor      = Color3.fromRGB(200, 150, 255),
        textSize       = 12,
        strokeColor    = Color3.fromRGB(0, 0, 0),
        verticalOffset = 1.2,
    },
}

-- =============================================
-- AIMBOT SETTINGS
-- =============================================
local aimbotSettings = {
    silentAim  = { enabled = false },
    fovCircle  = { enabled = false, radius = 120, color = Color3.fromRGB(170, 0, 210), thickness = 1.5 },
    smoothness = { enabled = false, value = 0.15 },
    targetLock = { enabled = false },
    targetPart = "Head",
}

local espObjects    = {}
local fovCircleObj  = nil
local currentTarget = nil

-- =============================================
-- SPINBOT SETTINGS
-- =============================================
local spinbotSettings = {
    spin      = { enabled = false, speed = 20 },
    jitter    = { enabled = false, intensity = 15 },
    axis      = "Y",
    keybind   = Enum.KeyCode.Unknown,
    useKeybind = false,
}
local spinAngle = 0

-- =============================================
-- AUTO AIM SETTINGS
-- =============================================
local autoAimSettings = {
    enabled    = false,
    mode       = "AutoClick",
    targetPart = "Head",
    radius     = 80,
    delay      = 0.1,
    wallCheck  = true,
}
local lastShot = 0

-- =============================================
-- MISC SETTINGS
-- =============================================
local miscSettings = {
    noclip     = { enabled = false },
    fly        = { enabled = false, speed = 50 },
    walkSpeed  = { value = 16 },
    jumpPower  = { value = 50 },
    infiniteJump = { enabled = false },
    fullBright = { enabled = false },
    noFog      = { enabled = false },
    antiAFK    = { enabled = false },
}
local flyBodyVelocity = nil
local flyBodyGyro    = nil
local defaultFog = nil

-- =============================================
-- DARK/PURPLE COLOR PALETTE
-- =============================================
local C = {
    bg          = Color3.fromRGB(26,  26,  26),
    panelBg     = Color3.fromRGB(32,  32,  32),
    sectionHdr  = Color3.fromRGB(38,  38,  42),
    item        = Color3.fromRGB(44,  44,  48),
    itemHover   = Color3.fromRGB(54,  54,  60),
    accent      = Color3.fromRGB(160,  0, 200),
    accentHover = Color3.fromRGB(190, 30, 230),
    text        = Color3.fromRGB(215, 215, 218),
    textDim     = Color3.fromRGB(130, 130, 138),
    checkOff    = Color3.fromRGB(58,  58,  64),
    checkOn     = Color3.fromRGB(160,  0, 200),
    sliderTrack = Color3.fromRGB(52,  52,  58),
    sliderFill  = Color3.fromRGB(160,  0, 200),
    btnNeutral  = Color3.fromRGB(58,  58,  66),
    btnActive   = Color3.fromRGB(160,  0, 200),
    headerBg    = Color3.fromRGB(18,  18,  18),
    tabBg       = Color3.fromRGB(22,  22,  22),
    tabActive   = Color3.fromRGB(44,  44,  48),
}

-- =============================================
-- SCREEN GUI
-- =============================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "MenuPanel"
screenGui.ResetOnSpawn   = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent         = playerGui

-- =============================================
-- MAIN FRAME  560 x 460
-- =============================================
local mainFrame = Instance.new("Frame")
mainFrame.Name            = "MainFrame"
mainFrame.Size            = UDim2.new(0, 560, 0, 460)
mainFrame.Position        = UDim2.new(0.5, -280, 0.5, -230)
mainFrame.BackgroundColor3 = C.bg
mainFrame.BorderSizePixel = 0
mainFrame.Parent          = screenGui

local _mc = Instance.new("UICorner"); _mc.CornerRadius = UDim.new(0, 4); _mc.Parent = mainFrame

local borderStroke = Instance.new("UIStroke")
borderStroke.Color     = C.accent
borderStroke.Thickness = 1
borderStroke.Parent    = mainFrame

-- =============================================
-- HEADER  (28px)
-- =============================================
local header = Instance.new("Frame")
header.Size             = UDim2.new(1, 0, 0, 28)
header.BackgroundColor3 = C.headerBg
header.BorderSizePixel  = 0
header.Parent           = mainFrame
-- Fix bottom corners
local _hc = Instance.new("UICorner"); _hc.CornerRadius = UDim.new(0,4); _hc.Parent = header
local _hfix = Instance.new("Frame")
_hfix.Size = UDim2.new(1,0,0.5,0); _hfix.Position = UDim2.new(0,0,0.5,0)
_hfix.BackgroundColor3 = C.headerBg; _hfix.BorderSizePixel = 0; _hfix.Parent = header

-- Left accent stripe on header
local hStripe = Instance.new("Frame")
hStripe.Size = UDim2.new(0,3,1,0); hStripe.BackgroundColor3 = C.accent
hStripe.BorderSizePixel = 0; hStripe.Parent = header

local titleLabel = Instance.new("TextLabel")
titleLabel.Size               = UDim2.new(1, -120, 1, 0)
titleLabel.Position           = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text               = "OCTOPUS V5"
titleLabel.TextColor3         = C.text
titleLabel.TextSize           = 12
titleLabel.Font               = Enum.Font.GothamBold
titleLabel.TextXAlignment     = Enum.TextXAlignment.Left
titleLabel.Parent             = header

-- Tier badge in header (FREE green / VIP purple+gold)
local menuTierBadge = Instance.new("TextLabel")
menuTierBadge.Size               = UDim2.new(0, 60, 0, 16)
menuTierBadge.Position           = UDim2.new(1, -94, 0.5, -8)
menuTierBadge.BackgroundColor3   = (userTier == "VIP")
    and Color3.fromRGB(120, 0, 160) or Color3.fromRGB(40, 90, 40)
menuTierBadge.BorderSizePixel    = 0
menuTierBadge.Text               = (userTier == "VIP") and "⭐ VIP" or "FREE"
menuTierBadge.TextColor3         = (userTier == "VIP")
    and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(140, 255, 140)
menuTierBadge.TextSize           = 10
menuTierBadge.Font               = Enum.Font.GothamBold
menuTierBadge.Parent             = header
local _mtbCorner = Instance.new("UICorner")
_mtbCorner.CornerRadius = UDim.new(0, 3)
_mtbCorner.Parent = menuTierBadge

local closeBtn = Instance.new("TextButton")
closeBtn.Size             = UDim2.new(0, 28, 0, 20)
closeBtn.Position         = UDim2.new(1, -30, 0.5, -10)
closeBtn.BackgroundTransparency = 1
closeBtn.Text             = "✕"
closeBtn.TextColor3       = C.textDim
closeBtn.TextSize         = 12
closeBtn.Font             = Enum.Font.GothamBold
closeBtn.Parent           = header
closeBtn.MouseEnter:Connect(function() closeBtn.TextColor3 = Color3.fromRGB(255,80,80) end)
closeBtn.MouseLeave:Connect(function() closeBtn.TextColor3 = C.textDim end)

-- =============================================
-- TAB BAR  (28px, at y=28)
-- =============================================
local tabBar = Instance.new("Frame")
tabBar.Size             = UDim2.new(1, 0, 0, 28)
tabBar.Position         = UDim2.new(0, 0, 0, 28)
tabBar.BackgroundColor3 = C.tabBg
tabBar.BorderSizePixel  = 0
tabBar.Parent           = mainFrame

-- bottom border line
local tabLine = Instance.new("Frame")
tabLine.Size = UDim2.new(1,0,0,1); tabLine.Position = UDim2.new(0,0,1,-1)
tabLine.BackgroundColor3 = C.accent; tabLine.BorderSizePixel = 0; tabLine.Parent = tabBar

local TAB_NAMES = {"ESP", "Aimbot", "Spinbot", "Misc"}
local tabBtns       = {}
local tabIndicators = {}
local tabW = math.floor(560 / #TAB_NAMES)

for i, name in ipairs(TAB_NAMES) do
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(0, tabW, 1, 0)
    btn.Position         = UDim2.new(0, (i-1)*tabW, 0, 0)
    btn.BackgroundColor3 = C.tabBg
    btn.BorderSizePixel  = 0
    btn.Text             = name
    btn.TextColor3       = C.textDim
    btn.TextSize         = 12
    btn.Font             = Enum.Font.GothamBold
    btn.Parent           = tabBar
    table.insert(tabBtns, btn)

    -- Active underline indicator
    local ind = Instance.new("Frame")
    ind.Size             = UDim2.new(0.6, 0, 0, 2)
    ind.Position         = UDim2.new(0.2, 0, 1, -2)
    ind.BackgroundColor3 = C.accent
    ind.BorderSizePixel  = 0
    ind.Visible          = false
    ind.Parent           = btn
    table.insert(tabIndicators, ind)
end

-- =============================================
-- CONTENT AREA  (below tabs, y=56)
-- =============================================
local contentArea = Instance.new("Frame")
contentArea.Size             = UDim2.new(1, 0, 1, -56)
contentArea.Position         = UDim2.new(0, 0, 0, 56)
contentArea.BackgroundTransparency = 1
contentArea.BorderSizePixel  = 0
contentArea.Parent           = mainFrame

-- Create page frames (one per tab)
local tabPages = {}
for _ = 1, #TAB_NAMES do
    local p = Instance.new("Frame")
    p.Size             = UDim2.new(1, 0, 1, 0)
    p.BackgroundTransparency = 1
    p.BorderSizePixel  = 0
    p.Visible          = false
    p.Parent           = contentArea
    table.insert(tabPages, p)
end

local espPage     = tabPages[1]
local aimbotPage  = tabPages[2]
local spinbotPage = tabPages[3]
local miscPage    = tabPages[4]

-- Lock overlay builder for VIP-only tabs
-- Uses an invisible TextButton as a click blocker over all content
local lockOverlays = {}
local function makeLockOverlay(page, tabName)
    -- Semi-transparent dark background
    local ov = Instance.new("Frame")
    ov.Size             = UDim2.new(1, 0, 1, 0)
    ov.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    ov.BackgroundTransparency = 0.1
    ov.BorderSizePixel  = 0
    ov.ZIndex           = 10
    ov.Parent           = page

    -- TextButton covering EVERYTHING and absorbing all clicks — nothing passes through
    local clickBlocker = Instance.new("TextButton")
    clickBlocker.Size             = UDim2.new(1, 0, 1, 0)
    clickBlocker.BackgroundTransparency = 1
    clickBlocker.Text             = ""
    clickBlocker.ZIndex           = 12
    clickBlocker.AutoButtonColor  = false
    clickBlocker.Parent           = ov
    -- do nothing on click — only used to block inputs
    clickBlocker.MouseButton1Click:Connect(function() end)

    local lockLbl = Instance.new("TextLabel")
    lockLbl.Size               = UDim2.new(1, 0, 0, 60)
    lockLbl.Position           = UDim2.new(0, 0, 0.35, 0)
    lockLbl.BackgroundTransparency = 1
    lockLbl.Text               = "🔒  " .. tabName .. "\nRequires VIP Key"
    lockLbl.TextColor3         = Color3.fromRGB(160, 0, 200)
    lockLbl.TextSize            = 14
    lockLbl.Font               = Enum.Font.GothamBold
    lockLbl.TextWrapped        = true
    lockLbl.ZIndex             = 13
    lockLbl.Parent             = ov
    return ov
end

-- Add lock overlay to VIP-only tabs if user is FREE
if not isVIP() then
    local vipTabNames = {"Aimbot", "Spinbot", "Misc"}
    local vipTabIndexes = {2, 3, 4}
    for n, idx in ipairs(vipTabIndexes) do
        lockOverlays[idx] = makeLockOverlay(tabPages[idx], vipTabNames[n])
    end
end

-- Tab switching
local function switchTab(idx)
    -- Block VIP tabs for FREE users
    if not isVIP() and (idx == 2 or idx == 3 or idx == 4) then
        idx = 1 -- redirect to ESP tab
    end
    for i, page in ipairs(tabPages) do
        page.Visible           = (i == idx)
        tabBtns[i].TextColor3  = (i == idx) and C.text or C.textDim
        tabBtns[i].BackgroundColor3 = (i == idx) and C.tabActive or C.tabBg
        tabIndicators[i].Visible = (i == idx)
    end
end

for i, btn in ipairs(tabBtns) do
    local idx = i
    btn.MouseButton1Click:Connect(function()
        if not isVIP() and (idx == 2 or idx == 3 or idx == 4) then
            -- Show lock overlay of clicked tab (but don't open it)
            for i2, page in ipairs(tabPages) do
                page.Visible = (i2 == idx)
                tabBtns[i2].TextColor3 = (i2 == idx) and C.text or C.textDim
                tabBtns[i2].BackgroundColor3 = (i2 == idx) and C.tabActive or C.tabBg
                tabIndicators[i2].Visible = (i2 == idx)
            end
        else
            switchTab(idx)
        end
    end)
end
switchTab(1)

-- =============================================
-- LAYOUT HELPERS
-- =============================================
local function colorToHex(c3)
    return string.format("#%02X%02X%02X",
        math.floor(c3.R*255), math.floor(c3.G*255), math.floor(c3.B*255))
end
local function hexToColor(hex)
    hex = hex:gsub("#","")
    if #hex ~= 6 then return nil end
    local r,g,b = tonumber(hex:sub(1,2),16), tonumber(hex:sub(3,4),16), tonumber(hex:sub(5,6),16)
    if not r or not g or not b then return nil end
    return Color3.fromRGB(r,g,b)
end

-- Scrollable column  (xRel=0 or 0.5, wRel=0.5 or 1)
local function makeColumn(parent, xOff, wPx)
    local sf = Instance.new("ScrollingFrame")
    sf.Size                   = UDim2.new(0, wPx, 1, -6)
    sf.Position               = UDim2.new(0, xOff, 0, 3)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel        = 0
    sf.ScrollBarThickness     = 3
    sf.ScrollBarImageColor3   = C.accent
    sf.CanvasSize             = UDim2.new(0, 0, 0, 0)
    sf.Parent                 = parent

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding   = UDim.new(0, 2)
    layout.Parent    = sf

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        sf.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 6)
    end)

    return sf
end

-- Section header bar
local function makeSection(parent, title, order)
    local hdr = Instance.new("Frame")
    hdr.Size             = UDim2.new(1, 0, 0, 20)
    hdr.BackgroundColor3 = C.sectionHdr
    hdr.BorderSizePixel  = 0
    hdr.LayoutOrder      = order or 0
    hdr.Parent           = parent

    local stripe = Instance.new("Frame")
    stripe.Size             = UDim2.new(0, 3, 1, 0)
    stripe.BackgroundColor3 = C.accent
    stripe.BorderSizePixel  = 0
    stripe.Parent           = hdr

    local lbl = Instance.new("TextLabel")
    lbl.Size               = UDim2.new(1, -10, 1, 0)
    lbl.Position           = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = title
    lbl.TextColor3         = C.text
    lbl.TextSize           = 11
    lbl.Font               = Enum.Font.GothamBold
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Parent             = hdr
    return hdr
end

-- Simple spacer
local function makeSpacer(parent, h, order)
    local s = Instance.new("Frame")
    s.Size             = UDim2.new(1, 0, 0, h)
    s.BackgroundTransparency = 1
    s.BorderSizePixel  = 0
    s.LayoutOrder      = order or 0
    s.Parent           = parent
end

-- Checkbox row  (no gear)
local function makeCheckRow(parent, labelText, getEnabled, setEnabled, order)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, 22)
    row.BackgroundColor3 = C.item
    row.BorderSizePixel  = 0
    row.LayoutOrder      = order or 0
    row.Parent           = parent

    local box = Instance.new("Frame")
    box.Size             = UDim2.new(0, 12, 0, 12)
    box.Position         = UDim2.new(0, 6, 0.5, -6)
    box.BackgroundColor3 = getEnabled() and C.checkOn or C.checkOff
    box.BorderSizePixel  = 0
    box.Parent           = row

    local chkLbl = Instance.new("TextLabel")
    chkLbl.Size               = UDim2.new(1, 0, 1, 0)
    chkLbl.BackgroundTransparency = 1
    chkLbl.Text               = getEnabled() and "✓" or ""
    chkLbl.TextColor3         = Color3.fromRGB(255, 255, 255)
    chkLbl.TextSize           = 9
    chkLbl.Font               = Enum.Font.GothamBold
    chkLbl.Parent             = box

    local lbl = Instance.new("TextLabel")
    lbl.Size               = UDim2.new(1, -26, 1, 0)
    lbl.Position           = UDim2.new(0, 24, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = labelText
    lbl.TextColor3         = C.text
    lbl.TextSize           = 11
    lbl.Font               = Enum.Font.Gotham
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Parent             = row

    local clickBtn = Instance.new("TextButton")
    clickBtn.Size             = UDim2.new(1, 0, 1, 0)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text             = ""
    clickBtn.Parent           = row
    clickBtn.MouseButton1Click:Connect(function()
        local on = not getEnabled(); setEnabled(on)
        box.BackgroundColor3 = on and C.checkOn or C.checkOff
        chkLbl.Text = on and "✓" or ""
    end)
    return row
end

-- Checkbox row WITH gear button (for ESP)
local activePanelFrame = nil
local function closeActivePanel()
    if activePanelFrame then activePanelFrame:Destroy(); activePanelFrame = nil end
end

local function makeCheckRowGear(parent, labelText, getEnabled, setEnabled, settingKey, order)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, 22)
    row.BackgroundColor3 = C.item
    row.BorderSizePixel  = 0
    row.LayoutOrder      = order or 0
    row.Parent           = parent

    local box = Instance.new("Frame")
    box.Size             = UDim2.new(0, 12, 0, 12)
    box.Position         = UDim2.new(0, 6, 0.5, -6)
    box.BackgroundColor3 = getEnabled() and C.checkOn or C.checkOff
    box.BorderSizePixel  = 0
    box.Parent           = row

    local chkLbl = Instance.new("TextLabel")
    chkLbl.Size               = UDim2.new(1, 0, 1, 0)
    chkLbl.BackgroundTransparency = 1
    chkLbl.Text               = getEnabled() and "✓" or ""
    chkLbl.TextColor3         = Color3.fromRGB(255, 255, 255)
    chkLbl.TextSize           = 9
    chkLbl.Font               = Enum.Font.GothamBold
    chkLbl.Parent             = box

    local lbl = Instance.new("TextLabel")
    lbl.Size               = UDim2.new(1, -50, 1, 0)
    lbl.Position           = UDim2.new(0, 24, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = labelText
    lbl.TextColor3         = C.text
    lbl.TextSize           = 11
    lbl.Font               = Enum.Font.Gotham
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Parent             = row

    local gearBtn = Instance.new("TextButton")
    gearBtn.Size             = UDim2.new(0, 22, 0, 16)
    gearBtn.Position         = UDim2.new(1, -25, 0.5, -8)
    gearBtn.BackgroundColor3 = C.btnNeutral
    gearBtn.BorderSizePixel  = 0
    gearBtn.Text             = "⚙"
    gearBtn.TextColor3       = C.textDim
    gearBtn.TextSize         = 10
    gearBtn.Font             = Enum.Font.GothamBold
    gearBtn.Parent           = row
    local _gc = Instance.new("UICorner"); _gc.CornerRadius = UDim.new(0,2); _gc.Parent = gearBtn
    gearBtn.MouseEnter:Connect(function() gearBtn.BackgroundColor3 = C.accent end)
    gearBtn.MouseLeave:Connect(function() gearBtn.BackgroundColor3 = C.btnNeutral end)

    local clickBtn = Instance.new("TextButton")
    clickBtn.Size             = UDim2.new(1, -30, 1, 0)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text             = ""
    clickBtn.Parent           = row
    clickBtn.MouseButton1Click:Connect(function()
        local on = not getEnabled(); setEnabled(on)
        box.BackgroundColor3 = on and C.checkOn or C.checkOff
        chkLbl.Text = on and "✓" or ""
    end)

    gearBtn.MouseButton1Click:Connect(function()
        if activePanelFrame and activePanelFrame:GetAttribute("key") == settingKey then
            closeActivePanel(); return
        end
        closeActivePanel()
        -- Open settings panel to the RIGHT of main menu
        local s = espSettings[settingKey]
        local isPlayer = (settingKey == "PlayerESP")
        local panelH = isPlayer and 240 or 220

        local panel = Instance.new("Frame")
        panel:SetAttribute("key", settingKey)
        panel.Size             = UDim2.new(0, 200, 0, panelH)
        panel.Position         = UDim2.new(1, 6, 0, 0)
        panel.BackgroundColor3 = C.panelBg
        panel.BorderSizePixel  = 0
        panel.ZIndex           = 10
        panel.Parent           = mainFrame
        activePanelFrame       = panel
        local _pc = Instance.new("UICorner"); _pc.CornerRadius = UDim.new(0,4); _pc.Parent = panel
        local _ps = Instance.new("UIStroke"); _ps.Color = C.accent; _ps.Thickness = 1; _ps.Parent = panel

        -- Panel title
        local ptitle = Instance.new("TextLabel")
        ptitle.Size = UDim2.new(1,-8,0,18); ptitle.Position = UDim2.new(0,8,0,4)
        ptitle.BackgroundTransparency = 1
        ptitle.Text = settingKey .. " Settings"
        ptitle.TextColor3 = C.accent; ptitle.TextSize = 10; ptitle.Font = Enum.Font.GothamBold
        ptitle.TextXAlignment = Enum.TextXAlignment.Left; ptitle.Parent = panel

        local y = 26

        local function addLabel(txt, yy)
            local l = Instance.new("TextLabel")
            l.Size = UDim2.new(1,-12,0,14); l.Position = UDim2.new(0,8,0,yy)
            l.BackgroundTransparency=1; l.Text=txt; l.TextColor3=C.textDim
            l.TextSize=9; l.Font=Enum.Font.Gotham
            l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=panel
        end
        local function addColorRow(labelTxt, yy, getCol, setCol)
            addLabel(labelTxt, yy)
            local prev = Instance.new("Frame")
            prev.Size=UDim2.new(0,16,0,14); prev.Position=UDim2.new(0,8,0,yy+14)
            prev.BackgroundColor3=getCol(); prev.BorderSizePixel=0; prev.Parent=panel
            local hbox = Instance.new("TextBox")
            hbox.Size=UDim2.new(0,90,0,14); hbox.Position=UDim2.new(0,28,0,yy+14)
            hbox.BackgroundColor3=Color3.fromRGB(50,50,56); hbox.BorderSizePixel=0
            hbox.Text=colorToHex(getCol()); hbox.TextColor3=C.text
            hbox.TextSize=9; hbox.Font=Enum.Font.GothamBold; hbox.ClearTextOnFocus=false; hbox.Parent=panel
            local _hb=Instance.new("UICorner"); _hb.CornerRadius=UDim.new(0,2); _hb.Parent=hbox
            hbox.FocusLost:Connect(function()
                local nc=hexToColor(hbox.Text)
                if nc then prev.BackgroundColor3=nc; setCol(nc)
                else hbox.Text=colorToHex(getCol()) end
            end)
        end
        local function addSliderMini(labelTxt, yy, minV, maxV, curV, fmt, cb)
            addLabel(labelTxt.." "..string.format(fmt,curV), yy)
            local track = Instance.new("Frame")
            track.Size=UDim2.new(1,-16,0,4); track.Position=UDim2.new(0,8,0,yy+14)
            track.BackgroundColor3=C.sliderTrack; track.BorderSizePixel=0; track.Parent=panel
            local _tr=Instance.new("UICorner"); _tr.CornerRadius=UDim.new(1,0); _tr.Parent=track
            local fill2=Instance.new("Frame")
            fill2.Size=UDim2.new((curV-minV)/(maxV-minV),0,1,0)
            fill2.BackgroundColor3=C.accent; fill2.BorderSizePixel=0; fill2.Parent=track
            local _fr=Instance.new("UICorner"); _fr.CornerRadius=UDim.new(1,0); _fr.Parent=fill2
            local knob2=Instance.new("TextButton")
            knob2.Size=UDim2.new(0,10,0,10); knob2.AnchorPoint=Vector2.new(0.5,0.5)
            knob2.Position=UDim2.new((curV-minV)/(maxV-minV),0,0.5,0)
            knob2.BackgroundColor3=Color3.fromRGB(220,220,220); knob2.BorderSizePixel=0
            knob2.Text=""; knob2.Parent=track
            local _kr=Instance.new("UICorner"); _kr.CornerRadius=UDim.new(1,0); _kr.Parent=knob2
            local d=false
            knob2.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then d=true end end)
            UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then d=false end end)
            UserInputService.InputChanged:Connect(function(i)
                if d and i.UserInputType==Enum.UserInputType.MouseMovement then
                    local rel=math.clamp((i.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
                    local val=math.floor((minV+rel*(maxV-minV))*100+0.5)/100
                    fill2.Size=UDim2.new(rel,0,1,0); knob2.Position=UDim2.new(rel,0,0.5,0); cb(val)
                end
            end)
        end

        if isPlayer then
            addColorRow("Fill Color",  y,   function() return s.fillColor end,    function(c) s.fillColor=c end); y=y+36
            addSliderMini("Fill Transparency", y, 0, 1, s.fillTransparency, "%.2f", function(v) s.fillTransparency=v end); y=y+30
            addColorRow("Outline Color", y,  function() return s.outlineColor end, function(c) s.outlineColor=c end); y=y+36
            addSliderMini("Outline Transparency", y, 0, 1, s.outlineTransparency, "%.2f", function(v) s.outlineTransparency=v end)
        else
            addColorRow("Text Color", y,    function() return s.textColor end,  function(c) s.textColor=c end); y=y+36
            addSliderMini("Text Size", y, 8, 36, s.textSize, "%.0f px", function(v) s.textSize=v end); y=y+30
            addColorRow("Stroke Color", y,  function() return s.strokeColor end, function(c) s.strokeColor=c end); y=y+36
            addSliderMini("Vertical Offset", y, 0, 6, s.verticalOffset, "%.1f", function(v) s.verticalOffset=v end)
        end
    end)
    return row
end

-- Slider row (for columns)
local function makeSlider(parent, labelText, minVal, maxVal, currentVal, fmt, onChange, order)
    local container = Instance.new("Frame")
    container.Size             = UDim2.new(1, 0, 0, 38)
    container.BackgroundColor3 = C.item
    container.BorderSizePixel  = 0
    container.LayoutOrder      = order or 0
    container.Parent           = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.65,0,0,14); lbl.Position = UDim2.new(0,6,0,4)
    lbl.BackgroundTransparency=1; lbl.Text=labelText; lbl.TextColor3=C.textDim
    lbl.TextSize=10; lbl.Font=Enum.Font.Gotham
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=container

    local valLbl = Instance.new("TextLabel")
    valLbl.Size=UDim2.new(0.35,-6,0,14); valLbl.Position=UDim2.new(0.65,0,0,4)
    valLbl.BackgroundTransparency=1; valLbl.Text=string.format(fmt,currentVal)
    valLbl.TextColor3=C.accent; valLbl.TextSize=10; valLbl.Font=Enum.Font.GothamBold
    valLbl.TextXAlignment=Enum.TextXAlignment.Right; valLbl.Parent=container

    local track = Instance.new("Frame")
    track.Size=UDim2.new(1,-12,0,4); track.Position=UDim2.new(0,6,0,24)
    track.BackgroundColor3=C.sliderTrack; track.BorderSizePixel=0; track.Parent=container
    local _tr=Instance.new("UICorner"); _tr.CornerRadius=UDim.new(1,0); _tr.Parent=track

    local fill = Instance.new("Frame")
    fill.Size=UDim2.new((currentVal-minVal)/(maxVal-minVal),0,1,0)
    fill.BackgroundColor3=C.sliderFill; fill.BorderSizePixel=0; fill.Parent=track
    local _fr=Instance.new("UICorner"); _fr.CornerRadius=UDim.new(1,0); _fr.Parent=fill

    local knob = Instance.new("TextButton")
    knob.Size=UDim2.new(0,10,0,10); knob.AnchorPoint=Vector2.new(0.5,0.5)
    knob.Position=UDim2.new((currentVal-minVal)/(maxVal-minVal),0,0.5,0)
    knob.BackgroundColor3=Color3.fromRGB(220,220,225); knob.BorderSizePixel=0
    knob.Text=""; knob.Parent=track
    local _kr=Instance.new("UICorner"); _kr.CornerRadius=UDim.new(1,0); _kr.Parent=knob

    local dragging = false
    knob.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
            local rel=math.clamp((i.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
            local val=math.floor((minVal+rel*(maxVal-minVal))*100+0.5)/100
            fill.Size=UDim2.new(rel,0,1,0); knob.Position=UDim2.new(rel,0,0.5,0)
            valLbl.Text=string.format(fmt,val); onChange(val)
        end
    end)
    return container
end

-- Color row
local function makeColorRow(parent, labelText, getCurrentColor, onChange, order)
    local row = Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,22); row.BackgroundColor3=C.item
    row.BorderSizePixel=0; row.LayoutOrder=order or 0; row.Parent=parent

    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(0.5,0,1,0); lbl.Position=UDim2.new(0,6,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=labelText; lbl.TextColor3=C.textDim
    lbl.TextSize=10; lbl.Font=Enum.Font.Gotham
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=row

    local prev=Instance.new("Frame")
    prev.Size=UDim2.new(0,16,0,14); prev.Position=UDim2.new(0.5,2,0.5,-7)
    prev.BackgroundColor3=getCurrentColor(); prev.BorderSizePixel=0; prev.Parent=row

    local hbox=Instance.new("TextBox")
    hbox.Size=UDim2.new(0,68,0,16); hbox.Position=UDim2.new(0.5,22,0.5,-8)
    hbox.BackgroundColor3=Color3.fromRGB(50,50,58); hbox.BorderSizePixel=0
    hbox.Text=colorToHex(getCurrentColor()); hbox.TextColor3=C.text
    hbox.TextSize=10; hbox.Font=Enum.Font.GothamBold; hbox.ClearTextOnFocus=false; hbox.Parent=row
    local _hb=Instance.new("UICorner"); _hb.CornerRadius=UDim.new(0,2); _hb.Parent=hbox
    hbox.FocusLost:Connect(function()
        local nc=hexToColor(hbox.Text)
        if nc then prev.BackgroundColor3=nc; onChange(nc)
        else hbox.Text=colorToHex(getCurrentColor()) end
    end)
    return row
end

-- Selector buttons row (e.g. Head / HumanoidRootPart / UpperTorso)
local function makeSelectorRow(parent, options, getCurrentVal, onChange, order)
    local container = Instance.new("Frame")
    container.Size=UDim2.new(1,0,0,22); container.BackgroundColor3=C.item
    container.BorderSizePixel=0; container.LayoutOrder=order or 0; container.Parent=parent

    local btns = {}
    local n = #options
    for i, opt in ipairs(options) do
        local btn = Instance.new("TextButton")
        btn.Size=UDim2.new(1/n,-4,0,16); btn.Position=UDim2.new((i-1)/n,2,0.5,-8)
        btn.BackgroundColor3=(opt==getCurrentVal()) and C.btnActive or C.btnNeutral
        btn.BorderSizePixel=0; btn.Text=opt; btn.TextColor3=C.text
        btn.TextSize=10; btn.Font=Enum.Font.GothamBold; btn.Parent=container
        local _bc=Instance.new("UICorner"); _bc.CornerRadius=UDim.new(0,2); _bc.Parent=btn
        table.insert(btns, btn)
        btn.MouseButton1Click:Connect(function()
            onChange(opt)
            for _,b in ipairs(btns) do
                b.BackgroundColor3=(b.Text==opt) and C.btnActive or C.btnNeutral
            end
        end)
    end
    return container
end

-- Small label row (info/hint)
local function makeLabelRow(parent, text, order)
    local row = Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,18); row.BackgroundTransparency=1
    row.BorderSizePixel=0; row.LayoutOrder=order or 0; row.Parent=parent
    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,-6,1,0); lbl.Position=UDim2.new(0,6,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=text; lbl.TextColor3=C.textDim
    lbl.TextSize=10; lbl.Font=Enum.Font.Gotham
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=row
    return row
end

-- Keybind row (for spinbot)
local keybindBtnRef = nil
local listeningForKey = false
local function makeKeybindRow(parent, order)
    local row = Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,22); row.BackgroundColor3=C.item
    row.BorderSizePixel=0; row.LayoutOrder=order or 0; row.Parent=parent

    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(0.45,0,1,0); lbl.Position=UDim2.new(0,6,0,0)
    lbl.BackgroundTransparency=1
    lbl.Text="Key: "..(spinbotSettings.keybind==Enum.KeyCode.Unknown and "none" or spinbotSettings.keybind.Name)
    lbl.TextColor3=C.textDim; lbl.TextSize=10; lbl.Font=Enum.Font.Gotham
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=row

    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(0.52,0,0,16); btn.Position=UDim2.new(0.46,0,0.5,-8)
    btn.BackgroundColor3=C.btnNeutral; btn.BorderSizePixel=0
    btn.Text="Click to bind"; btn.TextColor3=C.text; btn.TextSize=9
    btn.Font=Enum.Font.GothamBold; btn.Parent=row
    local _bc=Instance.new("UICorner"); _bc.CornerRadius=UDim.new(0,2); _bc.Parent=btn
    keybindBtnRef = {btn=btn, lbl=lbl}

    btn.MouseButton1Click:Connect(function()
        if listeningForKey then return end
        listeningForKey=true
        btn.Text="Listening..."
        btn.BackgroundColor3=Color3.fromRGB(160,120,0)
    end)
    return row
end

UserInputService.InputBegan:Connect(function(inp, processed)
    if listeningForKey and inp.UserInputType==Enum.UserInputType.Keyboard then
        listeningForKey=false
        spinbotSettings.keybind=inp.KeyCode
        if keybindBtnRef then
            keybindBtnRef.btn.Text=inp.KeyCode.Name
            keybindBtnRef.btn.BackgroundColor3=C.btnActive
            keybindBtnRef.lbl.Text="Key: "..inp.KeyCode.Name
        end
    end
end)

-- =============================================
-- ESP PAGE  (single wide column)
-- =============================================
local espCol = makeColumn(espPage, 0, 558)

makeSection(espCol, "Visual ESP", 1)
makeCheckRowGear(espCol, "Player ESP",   function() return espSettings.PlayerESP.enabled end,   function(v) espSettings.PlayerESP.enabled=v end,   "PlayerESP",  2)
makeCheckRowGear(espCol, "Nametag ESP",  function() return espSettings.NametagESP.enabled end,  function(v) espSettings.NametagESP.enabled=v end,  "NametagESP", 3)
makeCheckRowGear(espCol, "Distance ESP", function() return espSettings.DistanceESP.enabled end, function(v) espSettings.DistanceESP.enabled=v end, "DistanceESP",4)
makeSpacer(espCol, 6, 5)
makeLabelRow(espCol, "Click ⚙ to customize colors & size for each ESP type", 6)
makeLabelRow(espCol, "Press  [M]  to toggle this menu", 7)

-- =============================================
-- AIMBOT PAGE  (two columns)
-- =============================================
local aimLeftCol  = makeColumn(aimbotPage, 0, 276)
local aimRightCol = makeColumn(aimbotPage, 280, 276)

-- LEFT: Aimbot controls
makeSection(aimLeftCol, "Aimbot", 1)
makeCheckRow(aimLeftCol, "Silent Aim",    function() return aimbotSettings.silentAim.enabled end,  function(v) aimbotSettings.silentAim.enabled=v end,  2)
makeCheckRow(aimLeftCol, "Target Lock",   function() return aimbotSettings.targetLock.enabled end, function(v) aimbotSettings.targetLock.enabled=v; if not v then currentTarget=nil end end, 3)
makeCheckRow(aimLeftCol, "Aim Smoothness",function() return aimbotSettings.smoothness.enabled end, function(v) aimbotSettings.smoothness.enabled=v end, 4)
makeSlider(aimLeftCol, "Smoothness (low=fast)", 0.01, 1, aimbotSettings.smoothness.value, "%.2f", function(v) aimbotSettings.smoothness.value=v end, 5)

makeSpacer(aimLeftCol, 4, 6)

-- LEFT: FOV Circle
makeSection(aimLeftCol, "FOV Circle", 7)

local fovCheckRow = makeCheckRow(aimLeftCol, "FOV Circle", function() return aimbotSettings.fovCircle.enabled end,
    function(v) aimbotSettings.fovCircle.enabled=v; if fovCircleObj then fovCircleObj.Visible=v end end, 8)

makeSlider(aimLeftCol, "FOV Radius (px)", 30, 1000, aimbotSettings.fovCircle.radius, "%.0f", function(v)
    aimbotSettings.fovCircle.radius=v
    if fovCircleObj then fovCircleObj.Radius=v end
end, 9)

makeColorRow(aimLeftCol, "FOV Color", function() return aimbotSettings.fovCircle.color end, function(c)
    aimbotSettings.fovCircle.color=c
    if fovCircleObj then pcall(function() fovCircleObj.Color=c end) end
end, 10)

-- RIGHT: Target
makeSection(aimRightCol, "Target", 1)
makeLabelRow(aimRightCol, "Target Part:", 2)
makeSelectorRow(aimRightCol, {"Head","UpperTorso","HRP"}, function() return aimbotSettings.targetPart end, function(v)
    local remap = {Head="Head", UpperTorso="UpperTorso", HRP="HumanoidRootPart"}
    aimbotSettings.targetPart = remap[v] or v
    currentTarget = nil
end, 3)
makeSpacer(aimRightCol, 4, 4)

-- RIGHT: Auto Aim
makeSection(aimRightCol, "Auto Aim", 5)
makeCheckRow(aimRightCol, "Auto Aim Enabled", function() return autoAimSettings.enabled end, function(v) autoAimSettings.enabled=v end, 6)
makeLabelRow(aimRightCol, "Mode:", 7)
makeSelectorRow(aimRightCol, {"AutoClick","Triggerbot"}, function() return autoAimSettings.mode end, function(v) autoAimSettings.mode=v end, 8)
makeSlider(aimRightCol, "Radius (px)", 10, 400, autoAimSettings.radius, "%.0f", function(v) autoAimSettings.radius=v end, 9)
makeSlider(aimRightCol, "Delay (s)",  0.01, 2, autoAimSettings.delay, "%.2f", function(v) autoAimSettings.delay=v end, 10)
makeCheckRow(aimRightCol, "Wall Check", function() return autoAimSettings.wallCheck end, function(v) autoAimSettings.wallCheck=v end, 11)

-- =============================================
-- SPINBOT PAGE  (two columns)
-- =============================================
local spinLeftCol  = makeColumn(spinbotPage, 0, 276)
local spinRightCol = makeColumn(spinbotPage, 280, 276)

-- LEFT: Spinbot
makeSection(spinLeftCol, "Spinbot", 1)
makeCheckRow(spinLeftCol, "Continuous Spin", function() return spinbotSettings.spin.enabled end, function(v) spinbotSettings.spin.enabled=v end, 2)
makeSlider(spinLeftCol, "Speed (degrees/frame)", 1, 1000, spinbotSettings.spin.speed, "%.0f°", function(v) spinbotSettings.spin.speed=v end, 3)
makeSpacer(spinLeftCol, 4, 4)
makeSection(spinLeftCol, "Jitter", 5)
makeCheckRow(spinLeftCol, "Jitter Active", function() return spinbotSettings.jitter.enabled end, function(v) spinbotSettings.jitter.enabled=v end, 6)
makeSlider(spinLeftCol, "Intensity (°)", 1, 1000, spinbotSettings.jitter.intensity, "%.0f°", function(v) spinbotSettings.jitter.intensity=v end, 7)

-- RIGHT: Settings
makeSection(spinRightCol, "Settings", 1)
makeLabelRow(spinRightCol, "Rotation Axis:", 2)
makeSelectorRow(spinRightCol, {"Y Axis","X Axis","Z Axis"}, function()
    return spinbotSettings.axis.." Axis"
end, function(v)
    spinbotSettings.axis = v:sub(1,1) -- "Y", "X", or "Z"
    spinAngle = 0
end, 3)
makeSpacer(spinRightCol, 4, 4)
makeCheckRow(spinRightCol, "Use Keybind", function() return spinbotSettings.useKeybind end, function(v) spinbotSettings.useKeybind=v end, 5)
makeKeybindRow(spinRightCol, 6)

-- =============================================
-- MISC PAGE  (two columns)
-- =============================================
local miscLeftCol  = makeColumn(miscPage, 0, 276)
local miscRightCol = makeColumn(miscPage, 280, 276)

-- LEFT: Movement
makeSection(miscLeftCol, "Movement", 1)
makeCheckRow(miscLeftCol, "NoClip", function() return miscSettings.noclip.enabled end,
    function(v) miscSettings.noclip.enabled = v end, 2)
makeCheckRow(miscLeftCol, "Fly", function() return miscSettings.fly.enabled end,
    function(v)
        miscSettings.fly.enabled = v
        local char = player.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        if v then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = true end
            flyBodyGyro = Instance.new("BodyGyro")
            flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            flyBodyGyro.P = 9e4; flyBodyGyro.D = 1e3
            flyBodyGyro.CFrame = root.CFrame
            flyBodyGyro.Parent = root
            flyBodyVelocity = Instance.new("BodyVelocity")
            flyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            flyBodyVelocity.Velocity = Vector3.zero
            flyBodyVelocity.Parent = root
        else
            if flyBodyGyro    then flyBodyGyro:Destroy();    flyBodyGyro=nil    end
            if flyBodyVelocity then flyBodyVelocity:Destroy(); flyBodyVelocity=nil end
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = false end
        end
    end, 3)
makeSlider(miscLeftCol, "Fly Speed", 10, 1000, miscSettings.fly.speed, "%.0f", function(v)
    miscSettings.fly.speed = v
end, 4)
makeSpacer(miscLeftCol, 4, 5)
makeSlider(miscLeftCol, "Walk Speed", 8, 1000, miscSettings.walkSpeed.value, "%.0f", function(v)
    miscSettings.walkSpeed.value = v
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = v end
end, 6)
makeSlider(miscLeftCol, "Jump Power", 0, 1000, miscSettings.jumpPower.value, "%.0f", function(v)
    miscSettings.jumpPower.value = v
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.JumpPower = v end
end, 7)
makeCheckRow(miscLeftCol, "Infinite Jump", function() return miscSettings.infiniteJump.enabled end,
    function(v) miscSettings.infiniteJump.enabled = v end, 8)

-- RIGHT: Visual / Utility
makeSection(miscRightCol, "Visual", 1)
makeCheckRow(miscRightCol, "Full Bright", function() return miscSettings.fullBright.enabled end,
    function(v)
        miscSettings.fullBright.enabled = v
        if v then
            game:GetService("Lighting").Brightness = 2
            game:GetService("Lighting").ClockTime  = 14
            game:GetService("Lighting").FogEnd     = 100000
        else
            game:GetService("Lighting").Brightness = 1
            game:GetService("Lighting").ClockTime  = 14
            game:GetService("Lighting").FogEnd     = defaultFog or 100000
        end
    end, 2)
makeCheckRow(miscRightCol, "No Fog", function() return miscSettings.noFog.enabled end,
    function(v)
        miscSettings.noFog.enabled = v
        game:GetService("Lighting").FogEnd = v and 100000 or (defaultFog or 100000)
    end, 3)

makeSpacer(miscRightCol, 4, 4)
makeSection(miscRightCol, "Utility", 5)
makeCheckRow(miscRightCol, "Anti-AFK", function() return miscSettings.antiAFK.enabled end,
    function(v) miscSettings.antiAFK.enabled = v end, 6)

makeSpacer(miscRightCol, 4, 7)
makeLabelRow(miscRightCol, "Fly: WASD + Space/C to go up/down", 8)
makeLabelRow(miscRightCol, "Press  [M]  to open/close the menu", 9)

-- =============================================
-- DRAG HEADER
-- =============================================
local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
header.InputBegan:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1 then
        dragging=true; dragStart=inp.Position; startPos=mainFrame.Position
        inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then dragging=false end end)
    end
end)
header.InputChanged:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseMovement then dragInput=inp end
end)
UserInputService.InputChanged:Connect(function(inp)
    if inp==dragInput and dragging then
        local d=inp.Position-dragStart
        mainFrame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
    end
end)

closeBtn.MouseButton1Click:Connect(function() closeActivePanel(); mainFrame.Visible=false end)
UserInputService.InputBegan:Connect(function(inp, proc)
    if proc then return end
    if inp.KeyCode==Enum.KeyCode.M then
        mainFrame.Visible=not mainFrame.Visible
        if not mainFrame.Visible then closeActivePanel() end
    end
end)

-- =============================================
-- FOV CIRCLE (Drawing API)
-- =============================================
local ok, drawing = pcall(function() return Drawing end)
if ok and drawing then
    fovCircleObj           = Drawing.new("Circle")
    fovCircleObj.Visible   = false
    fovCircleObj.Thickness = aimbotSettings.fovCircle.thickness
    fovCircleObj.Color     = aimbotSettings.fovCircle.color
    fovCircleObj.Radius    = aimbotSettings.fovCircle.radius
    fovCircleObj.Filled    = false
    fovCircleObj.NumSides  = 64
end

-- =============================================
-- AIMBOT UTILITIES
-- =============================================
local function getTargetPart(char)
    return char and char:FindFirstChild(aimbotSettings.targetPart)
end

local function isAlive(target)
    if not target or not target.Character then return false end
    local hum = target.Character:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function isEnemy(target)
    if not target then return false end
    if not player.Team or not target.Team then return true end
    return player.Team ~= target.Team
end

local function isVisible(part)
    if not part then return false end
    local localChar = player.Character
    local camPos    = camera.CFrame.Position
    local ignore    = {camera}
    if localChar then table.insert(ignore, localChar) end
    local rayDir    = part.Position - camPos
    local rayResult = workspace:FindPartOnRayWithIgnoreList(Ray.new(camPos, rayDir), ignore, false, true)
    if not rayResult then return true end
    local hitModel = rayResult:FindFirstAncestorOfClass("Model")
    for _, target in ipairs(Players:GetPlayers()) do
        if target == player then continue end
        if target.Character and hitModel == target.Character then return true end
    end
    return false
end

local function getClosestTarget()
    local vp        = camera.ViewportSize
    local center    = Vector2.new(vp.X/2, vp.Y/2)
    local fovRadius = aimbotSettings.fovCircle.enabled and aimbotSettings.fovCircle.radius or math.huge
    local best, bestDist = nil, fovRadius

    for _, target in ipairs(Players:GetPlayers()) do
        if target == player then continue end
        if not isEnemy(target) then continue end
        if not isAlive(target) then continue end
        local part = getTargetPart(target.Character)
        if not part then continue end
        if not isVisible(part) then continue end
        local screen, onScreen = camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        local dist2D = (Vector2.new(screen.X, screen.Y) - center).Magnitude
        if dist2D < bestDist then bestDist=dist2D; best=target end
    end
    return best
end

-- =============================================
-- ESP LOGIC
-- =============================================
local function clearESP()
    for _, obj in pairs(espObjects) do if obj and obj.Parent then obj:Destroy() end end
    espObjects = {}
end

-- =============================================
-- RENDERSTEPPED: ESP + FOV + Target Lock
-- =============================================
RunService.RenderStepped:Connect(function(dt)
    -- FOV circle
    if fovCircleObj then
        fovCircleObj.Visible = aimbotSettings.fovCircle.enabled
        if aimbotSettings.fovCircle.enabled then
            local vp = camera.ViewportSize
            fovCircleObj.Position  = Vector2.new(vp.X/2, vp.Y/2)
            fovCircleObj.Radius    = aimbotSettings.fovCircle.radius
            fovCircleObj.Color     = aimbotSettings.fovCircle.color
            fovCircleObj.Thickness = aimbotSettings.fovCircle.thickness
        end
    end

    -- Target Lock + Smoothness
    if aimbotSettings.targetLock.enabled or aimbotSettings.smoothness.enabled then
        if currentTarget then
            local part = getTargetPart(currentTarget.Character)
            if not isAlive(currentTarget) or not isVisible(part) then currentTarget=nil end
        end
        if not currentTarget then currentTarget=getClosestTarget() end
        if currentTarget then
            local part = getTargetPart(currentTarget.Character)
            if part then
                local targetCF = CFrame.lookAt(camera.CFrame.Position, part.Position)
                if aimbotSettings.targetLock.enabled then
                    if aimbotSettings.smoothness.enabled then
                        local alpha = math.clamp(dt/aimbotSettings.smoothness.value, 0, 1)
                        camera.CFrame = camera.CFrame:Lerp(targetCF, alpha)
                    else
                        camera.CFrame = targetCF
                    end
                elseif aimbotSettings.smoothness.enabled then
                    local alpha = math.clamp(dt/aimbotSettings.smoothness.value, 0, 1)
                    camera.CFrame = camera.CFrame:Lerp(targetCF, alpha)
                end
            end
        end
    end

    -- ESP
    clearESP()
    local anyESP = espSettings.PlayerESP.enabled or espSettings.NametagESP.enabled or espSettings.DistanceESP.enabled
    if not anyESP then return end

    local localChar = player.Character
    local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")

    for _, target in ipairs(Players:GetPlayers()) do
        if target == player then continue end
        if not isEnemy(target) then continue end
        local char = target.Character; if not char then continue end
        local root = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        if not root or not head then continue end
        local distance = localRoot and math.floor((localRoot.Position-root.Position).Magnitude) or 0

        if espSettings.PlayerESP.enabled then
            local s  = espSettings.PlayerESP
            local hl = Instance.new("Highlight")
            hl.Adornee             = char
            hl.FillColor           = s.fillColor
            hl.FillTransparency    = s.fillTransparency
            hl.OutlineColor        = s.outlineColor
            hl.OutlineTransparency = s.outlineTransparency
            hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Parent              = screenGui
            table.insert(espObjects, hl)
        end

        if espSettings.NametagESP.enabled then
            local s  = espSettings.NametagESP
            local bb = Instance.new("BillboardGui")
            bb.Adornee=head; bb.Size=UDim2.new(0,140,0,30)
            bb.StudsOffset=Vector3.new(0,s.verticalOffset,0); bb.AlwaysOnTop=true; bb.Parent=screenGui
            local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1
            lbl.Text=target.DisplayName; lbl.TextColor3=s.textColor; lbl.TextStrokeColor3=s.strokeColor
            lbl.TextStrokeTransparency=0; lbl.TextSize=s.textSize; lbl.Font=Enum.Font.GothamBold; lbl.Parent=bb
            table.insert(espObjects, bb)
        end

        if espSettings.DistanceESP.enabled then
            local s  = espSettings.DistanceESP
            local bb = Instance.new("BillboardGui")
            bb.Adornee=head; bb.Size=UDim2.new(0,110,0,24)
            local yOff = espSettings.NametagESP.enabled and (espSettings.NametagESP.verticalOffset-1.2) or s.verticalOffset
            bb.StudsOffset=Vector3.new(0,yOff,0); bb.AlwaysOnTop=true; bb.Parent=screenGui
            local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1
            lbl.Text=distance.." m"; lbl.TextColor3=s.textColor; lbl.TextStrokeColor3=s.strokeColor
            lbl.TextStrokeTransparency=0; lbl.TextSize=s.textSize; lbl.Font=Enum.Font.Gotham; lbl.Parent=bb
            table.insert(espObjects, bb)
        end
    end
end)

-- =============================================
-- SILENT AIM (hookmetamethod)
-- =============================================
local oldMouseIndex
local oldMouseNamecall

local function getSilentTarget()
    if not aimbotSettings.silentAim.enabled then return nil end
    local target = getClosestTarget()
    if not target then return nil end
    return getTargetPart(target.Character)
end

pcall(function()
    oldMouseIndex = hookmetamethod(game, "__index", function(self, key)
        if not aimbotSettings.silentAim.enabled then return oldMouseIndex(self, key) end
        if self == mouse then
            local silentPart = getSilentTarget()
            if silentPart then
                if key == "Target" then return silentPart end
                if key == "Hit"    then return silentPart.CFrame end
            end
        end
        return oldMouseIndex(self, key)
    end)
end)

pcall(function()
    oldMouseNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        if not aimbotSettings.silentAim.enabled then return oldMouseNamecall(self, ...) end
        local method = getnamecallmethod()
        if method=="FindPartOnRayWithIgnoreList" or method=="FindPartOnRay" or method=="Raycast" then
            local silentPart = getSilentTarget()
            if silentPart then
                return silentPart, silentPart.Position, Vector3.new(0,1,0), Enum.Material.SmoothPlastic
            end
        end
        return oldMouseNamecall(self, ...)
    end)
end)

-- =============================================
-- SPINBOT LOGIC
-- =============================================
RunService.RenderStepped:Connect(function()
    local char = player.Character; if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end

    local keybindActive = true
    if spinbotSettings.useKeybind and spinbotSettings.keybind ~= Enum.KeyCode.Unknown then
        keybindActive = UserInputService:IsKeyDown(spinbotSettings.keybind)
    end

    local doSpin   = spinbotSettings.spin.enabled and keybindActive
    local doJitter = spinbotSettings.jitter.enabled and keybindActive

    if not doSpin and not doJitter then
        if spinAngle ~= 0 then
            spinAngle = 0
            root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, 0, 0)
        end
        return
    end

    if doSpin then spinAngle = (spinAngle + spinbotSettings.spin.speed) % 360 end

    local jOff = 0
    if doJitter then jOff = (math.random()*2-1) * spinbotSettings.jitter.intensity end

    local pos   = root.Position
    local angle = spinAngle + jOff
    local axis  = spinbotSettings.axis
    local newCF
    if axis == "Y" then
        newCF = CFrame.new(pos) * CFrame.Angles(0, math.rad(angle), 0)
    elseif axis == "X" then
        newCF = CFrame.new(pos) * CFrame.Angles(math.rad(angle), 0, 0)
    else
        newCF = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(angle))
    end
    root.CFrame = newCF
end)

-- =============================================
-- AUTO AIM LOGIC
-- =============================================
local function getAutoAimTarget()
    local vp     = camera.ViewportSize
    local center = Vector2.new(vp.X/2, vp.Y/2)
    local best, bestDist = nil, autoAimSettings.radius

    for _, target in ipairs(Players:GetPlayers()) do
        if target == player then continue end
        if not isEnemy(target) then continue end
        local char = target.Character; if not char then continue end
        local hum  = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        local part = char:FindFirstChild(autoAimSettings.targetPart); if not part then continue end
        if autoAimSettings.wallCheck and not isVisible(part) then continue end
        local screen, onScreen = camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        local dist2D = (Vector2.new(screen.X, screen.Y) - center).Magnitude
        if dist2D < bestDist then bestDist=dist2D; best=target end
    end
    return best
end

local function simulateClick()
    if mouse1click then
        pcall(mouse1click)
    elseif mouse1press then
        pcall(mouse1press)
        task.delay(0.05, function() pcall(mouse1release) end)
    else
        local vInputService = game:GetService("VirtualInputManager")
        if vInputService then
            pcall(function()
                vInputService:SendMouseButtonEvent(0,0,0,true,game,0)
                task.delay(0.05, function() vInputService:SendMouseButtonEvent(0,0,0,false,game,0) end)
            end)
        end
    end
end

local function isCursorOnTarget(target)
    local char = target and target.Character; if not char then return false end
    local unitRay = camera:ScreenPointToRay(mouse.X, mouse.Y)
    local ray = Ray.new(unitRay.Origin, unitRay.Direction * 1000)
    local localChar = player.Character
    local ignore = {camera}
    if localChar then table.insert(ignore, localChar) end
    local hit = workspace:FindPartOnRayWithIgnoreList(ray, ignore)
    if not hit then return false end
    return hit:IsDescendantOf(char)
end

RunService.Heartbeat:Connect(function()
    if not autoAimSettings.enabled then return end
    local now = tick()
    if now - lastShot < autoAimSettings.delay then return end
    local target = getAutoAimTarget()
    if not target then return end
    if autoAimSettings.mode == "AutoClick" then
        simulateClick(); lastShot=now
    elseif autoAimSettings.mode == "Triggerbot" then
        if isCursorOnTarget(target) then simulateClick(); lastShot=now end
    end
end)

-- =============================================
-- MISC LOGIC
-- =============================================

-- Save default fog
defaultFog = game:GetService("Lighting").FogEnd

-- NoClip: disables character collision every step
RunService.Stepped:Connect(function()
    if not miscSettings.noclip.enabled then return end
    local char = player.Character; if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end)

-- Fly: flight control using camera direction
RunService.RenderStepped:Connect(function(dt)
    if not miscSettings.fly.enabled then return end
    local char = player.Character; if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
    if not flyBodyVelocity or not flyBodyGyro then return end

    local speed = miscSettings.fly.speed
    local camCF = camera.CFrame
    local vel   = Vector3.zero

    if UserInputService:IsKeyDown(Enum.KeyCode.W) then vel = vel + camCF.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then vel = vel - camCF.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then vel = vel - camCF.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then vel = vel + camCF.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vel = vel + Vector3.yAxis end
    if UserInputService:IsKeyDown(Enum.KeyCode.C)     then vel = vel - Vector3.yAxis end

    flyBodyVelocity.Velocity = vel.Magnitude > 0 and (vel.Unit * speed) or Vector3.zero
    flyBodyGyro.CFrame = camCF
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if not miscSettings.infiniteJump.enabled then return end
    local char = player.Character; if not char then return end
    local hum  = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    hum:ChangeState(Enum.HumanoidStateType.Jumping)
end)

-- Anti-AFK: virtually move the character every ~4min
local lastAFK = 0
RunService.Heartbeat:Connect(function()
    if not miscSettings.antiAFK.enabled then return end
    local now = tick()
    if now - lastAFK > 240 then
        lastAFK = now
        local vInput = game:GetService("VirtualInputManager")
        pcall(function()
            vInput:SendKeyEvent(true,  Enum.KeyCode.ButtonB, false, game)
            vInput:SendKeyEvent(false, Enum.KeyCode.ButtonB, false, game)
        end)
    end
end)

-- Apply WalkSpeed/JumpPower on character respawn
player.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid")
    hum.WalkSpeed = miscSettings.walkSpeed.value
    hum.JumpPower = miscSettings.jumpPower.value
    -- Re-enable fly if it was active
    if miscSettings.fly.enabled then
        miscSettings.fly.enabled = false
        task.wait(0.5)
        -- Re-trigger enable
        local root = char:WaitForChild("HumanoidRootPart")
        hum.PlatformStand = true
        flyBodyGyro = Instance.new("BodyGyro")
        flyBodyGyro.MaxTorque = Vector3.new(9e9,9e9,9e9); flyBodyGyro.P=9e4; flyBodyGyro.D=1e3
        flyBodyGyro.CFrame = root.CFrame; flyBodyGyro.Parent = root
        flyBodyVelocity = Instance.new("BodyVelocity")
        flyBodyVelocity.MaxForce = Vector3.new(9e9,9e9,9e9)
        flyBodyVelocity.Velocity = Vector3.zero; flyBodyVelocity.Parent = root
        miscSettings.fly.enabled = true
    end
end)
