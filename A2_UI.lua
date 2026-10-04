-- ============================================================================
--  A2 UI  —  Custom UI Library (self-contained, TANPA WindUI)
--  Dibuat sendiri buat A2 HUB. API-compatible dengan pemakaian di script.
--  Nama UI: "A2"
-- ============================================================================
local A2UI = {}
A2UI.__index = A2UI
A2UI.Version = "2.0.0-standalone"

local CoreGui        = game:GetService("CoreGui")
local Players        = game:GetService("Players")
local HttpService    = game:GetService("HttpService")
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local function guiParent()
    -- gethui adalah parent paling stabil pada executor; PlayerGui adalah
    -- fallback resmi untuk LocalScript. CoreGui dicoba terakhir karena pada
    -- client biasa assignment ke CoreGui dapat ditolak oleh Roblox.
    local p
    pcall(function()
        if type(gethui) == "function" then p = gethui() end
    end)
    if p then return p end

    pcall(function()
        local player = Players.LocalPlayer
        if player then p = player:WaitForChild("PlayerGui", 10) end
    end)
    if p then return p end

    pcall(function() p = CoreGui end)
    return p
end

-- -------------------------------------------------------------- WEBHOOK ----
-- Nama fungsi request berbeda-beda pada executor. Tidak ada request yang
-- dikirim saat library di-load; pengiriman hanya terjadi melalui Webhook().
local function getRequestFunction()
    if type(request) == "function" then return request end
    if type(http_request) == "function" then return http_request end
    if syn and type(syn.request) == "function" then return syn.request end
    if http and type(http.request) == "function" then return http.request end
    return nil
end

local function validWebhookUrl(url)
    if type(url) ~= "string" then return false end
    return url:match("^https://discord%.com/api/webhooks/") ~= nil
        or url:match("^https://discordapp%.com/api/webhooks/") ~= nil
end

-- ---------------------------------------------------------------- THEME ----
-- hex() aman: kalau Color3.fromHex gak ada di client, fallback manual.
local function hex(s)
    local ok, c = pcall(function() return Color3.fromHex(s) end)
    if ok and c then return c end
    local r = (tonumber(s:sub(1, 2), 16) or 0) / 255
    local g = (tonumber(s:sub(3, 4), 16) or 0) / 255
    local b = (tonumber(s:sub(5, 6), 16) or 0) / 255
    return Color3.new(r, g, b)
end

local C = {
    bg      = hex("0c0d12"),
    panel   = hex("13151e"),
    card    = hex("191c27"),
    card2   = hex("232736"),
    stroke  = hex("2a2e3f"),
    text    = hex("e9ebf5"),
    dim     = hex("8b90a8"),
    accent  = hex("30ff6a"),
    accent2 = hex("00c2ff"),
    good    = hex("10c550"),
    bad     = hex("ef4f1d"),
    warn    = hex("eca201"),
    purple  = hex("7775f2"),
    blue    = hex("257af7"),
    grey    = hex("83889e"),
}
A2UI.Theme = C

-- ------------------------------------------------------------- HELPERS ----
local function mk(class, props)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then o[k] = v end
    end
    if props and props.Parent then o.Parent = props.Parent end
    return o
end

local function corner(parent, r)
    return mk("UICorner", { CornerRadius = UDim.new(0, r or 8), Parent = parent })
end

local function stroke(parent, color, thick, trans)
    return mk("UIStroke", { Color = color or C.stroke, Thickness = thick or 1, Transparency = trans or 0.5, Parent = parent })
end

local function pad(parent, t, r, b, l)
    return mk("UIPadding", {
        PaddingTop = UDim.new(0, t or 0), PaddingRight = UDim.new(0, r or 0),
        PaddingBottom = UDim.new(0, b or 0), PaddingLeft = UDim.new(0, l or 0), Parent = parent,
    })
end

local function textGlow(label, color, strength)
    if not label then return end
    label.TextStrokeColor3 = color or C.accent
    label.TextStrokeTransparency = strength or 0.72
end

local function shineText(label, color)
    if not label then return end
    local base = color or C.text
    local shine = mk("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, base),
            ColorSequenceKeypoint.new(0.42, base),
            ColorSequenceKeypoint.new(0.50, C.text),
            ColorSequenceKeypoint.new(0.58, base),
            ColorSequenceKeypoint.new(1, base),
        }),
        Offset = Vector2.new(-1, 0), Rotation = 18, Parent = label,
    })
    local tween
    local function sweep()
        if not shine.Parent then return end
        shine.Offset = Vector2.new(-1, 0)
        tween = TweenService:Create(shine, TweenInfo.new(2.2, Enum.EasingStyle.Sine), {
            Offset = Vector2.new(1, 0),
        })
        tween.Completed:Connect(function()
            if shine.Parent then task.delay(1.1, sweep) end
        end)
        tween:Play()
    end
    sweep()
    return shine
end

local ICON_ASSETS = {
    home = 6031075938, settings = 6031071053, link = 6031071057,
    rocket = 6031075926, tractor = 6031075926, package = 6031071057,
    send = 6031071057, check = 6031071053, save = 6031071053,
    ["folder-plus"] = 6031075938, pin = 6031071053, download = 6031071057,
    ["trash-2"] = 6031071053, ["refresh-cw"] = 6031075938,
    ["clipboard-copy"] = 6031071057, clipboard = 6031071057,
    ["circle-x"] = 6031071053, pause = 6031071053, play = 6031071057,
    activity = 6031071057, info = 6031075938, ["info-circle"] = 6031075938,
    ["rotate-ccw"] = 6031075938, ["list-plus"] = 6031071057,
    ["plug-zap"] = 6031071057, ["triangle-alert"] = 6031071053,
    hourglass = 6031071053,
}

local function assetUri(value)
    if type(value) == "number" then
        return "rbxassetid://" .. tostring(math.floor(value))
    end
    if type(value) ~= "string" then return nil end
    if value:match("^rbxassetid://%d+$") then return value end
    if value:match("^%d+$") then return "rbxassetid://" .. value end
    local named = ICON_ASSETS[value:lower()]
    if named then return "rbxassetid://" .. tostring(named) end
    return nil
end

local function makeIcon(parent, value, props)
    props = props or {}
    local uri = assetUri(value)
    if uri then
        local image = mk("ImageLabel", {
            Size = props.Size or UDim2.new(0, 22, 0, 22),
            Position = props.Position or UDim2.new(0, 0, 0, 0),
            AnchorPoint = props.AnchorPoint,
            BackgroundTransparency = 1, Image = uri,
            ImageColor3 = props.Color or C.dim, ImageTransparency = props.Transparency or 0,
            ScaleType = Enum.ScaleType.Fit, Parent = parent,
        })
        if props.Glow then stroke(image, props.Color or C.accent, 1, 0.35) end
        return image, true
    end
    local text = mk("TextLabel", {
        Size = props.Size or UDim2.new(0, 22, 0, 22),
        Position = props.Position or UDim2.new(0, 0, 0, 0),
        AnchorPoint = props.AnchorPoint,
        BackgroundTransparency = 1, Text = tostring(value or "•"),
        Font = Enum.Font.GothamBold, TextSize = props.TextSize or 14,
        TextColor3 = props.Color or C.dim, TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center, Parent = parent,
    })
    if props.Glow then textGlow(text, props.Color or C.accent, 0.62) end
    return text, false
end

local function vlist(parent, gap, align)
    return mk("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, gap or 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = align or Enum.HorizontalAlignment.Left, Parent = parent,
    })
end

local function hlist(parent, gap, valign)
    return mk("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, gap or 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = valign or Enum.VerticalAlignment.Center, Parent = parent,
    })
end

-- Global drag manager (biar gak bikin koneksi numpuk)
local activeDrag = nil
UserInputService.InputChanged:Connect(function(input)
    if activeDrag and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - activeDrag.start
        activeDrag.frame.Position = UDim2.new(
            activeDrag.pos.X.Scale, activeDrag.pos.X.Offset + d.X,
            activeDrag.pos.Y.Scale, activeDrag.pos.Y.Offset + d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        activeDrag = nil
    end
end)

function A2UI:SetWebhook(url)
    url = tostring(url or ""):gsub("%s+$", "")
    if url == "" then
        self.WebhookURL = nil
        return false, "URL webhook kosong"
    end
    if not validWebhookUrl(url) then
        return false, "URL harus berupa Discord webhook yang valid"
    end
    self.WebhookURL = url
    return true
end

function A2UI:Webhook(opts)
    opts = opts or {}
    local url = opts.URL or self.WebhookURL
    if not validWebhookUrl(url) then
        return false, "Webhook belum diatur atau URL tidak valid"
    end

    local now = os.clock()
    if self._lastWebhook and now - self._lastWebhook < 1 then
        return false, "Tunggu sebentar sebelum mengirim webhook lagi"
    end

    local req = getRequestFunction()
    if not req then
        return false, "Executor tidak menyediakan fungsi HTTP request"
    end

    local payload = {
        username = opts.Username or "A2 HUB",
        content = opts.Content or "A2 HUB status update",
    }
    if opts.Embeds then payload.embeds = opts.Embeds end

    local okEncode, body = pcall(function() return HttpService:JSONEncode(payload) end)
    if not okEncode then return false, "Gagal membuat payload webhook" end

    local ok, response = pcall(function()
        return req({
            Url = url,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = body,
        })
    end)
    if not ok then return false, tostring(response) end

    self._lastWebhook = now
    local status = type(response) == "table" and (response.StatusCode or response.Status) or nil
    if status and tonumber(status) and (tonumber(status) < 200 or tonumber(status) >= 300) then
        return false, "Discord menolak request (HTTP " .. tostring(status) .. ")"
    end
    return true, response
end

-- Alias yang lebih mudah dibaca saat dipanggil dari script farm/AFK.
A2UI.SendWebhook = A2UI.Webhook

local function draggable(frame, handle)
    handle = handle or frame
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            activeDrag = { frame = frame, start = input.Position, pos = frame.Position }
        end
    end)
end

-- --------------------------------------------------------- NOTIFICATION ----
local notifHolder
function A2UI:Notify(opts)
    opts = opts or {}
    local parent = guiParent()
    if not notifHolder or not notifHolder.Parent then
        notifHolder = mk("Frame", {
            Name = "A2Notifs", Size = UDim2.new(0, 300, 1, -20),
            Position = UDim2.new(1, -312, 0, 10), BackgroundTransparency = 1,
            ZIndex = 5000, Parent = parent,
        })
        vlist(notifHolder, 8, Enum.HorizontalAlignment.Right)
    end

    local card = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = C.card, BackgroundTransparency = 0, BorderSizePixel = 0,
        LayoutOrder = -os.clock(), ZIndex = 5001, Parent = notifHolder,
    })
    corner(card, 10)
    stroke(card, C.stroke, 1, 0.3)
    pad(card, 10, 12, 10, 12)

    local accent = mk("Frame", {
        Size = UDim2.new(0, 3, 1, -16), Position = UDim2.new(0, 0, 0, 8),
        BackgroundColor3 = C.accent, BorderSizePixel = 0, Parent = card,
    })
    corner(accent, 2)

    local holder = mk("Frame", {
        Size = UDim2.new(1, -14, 0, 0), Position = UDim2.new(0, 12, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = card,
    })
    vlist(holder, 2)

    mk("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1,
        Text = opts.Title or "A2", Font = Enum.Font.GothamBold, TextSize = 13,
        TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y, Parent = holder,
    })
    if opts.Content then
        mk("TextLabel", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1, Text = opts.Content, Font = Enum.Font.Gotham,
            TextSize = 11, TextColor3 = C.dim, TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true, Parent = holder,
        })
    end

    -- slide-in animation
    card.Position = UDim2.new(1, 40, 0, 0)
    TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Quint), { Position = UDim2.new(0, 0, 0, 0) }):Play()

    task.delay(tonumber(opts.Duration) or 4, function()
        if card and card.Parent then
            local out = TweenService:Create(card, TweenInfo.new(0.25), { BackgroundTransparency = 1 })
            out:Play()
            for _, d in ipairs(card:GetDescendants()) do
                if d:IsA("TextLabel") then
                    TweenService:Create(d, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
                elseif d:IsA("Frame") then
                    TweenService:Create(d, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
                end
            end
            task.wait(0.3)
            pcall(function() card:Destroy() end)
        end
    end)
end

-- --------------------------------------------------------------- WINDOW ----
function A2UI:CreateWindow(opts)
    opts = opts or {}
    local self = setmetatable({}, A2UI)
    self.Tabs = {}
    self._tabCount = 0
    self._visible = true

    local parent = guiParent()
    if not parent then
        error("[A2 UI] Tidak menemukan parent GUI yang valid (PlayerGui/gethui/CoreGui)")
    end

    -- Hapus instance lama agar script yang di-execute ulang tidak membuat
    -- window tertutup/tertumpuk di bawah window sebelumnya.
    pcall(function()
        local old = parent:FindFirstChild("A2UI")
        if old then old:Destroy() end
    end)

    local gui = mk("ScreenGui", {
        Name = "A2UI", ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 9999, Enabled = true,
    })
    -- Attach ke parent yang valid + verifikasi benar-benar ke-parent.
    pcall(function() gui.Parent = parent end)
    if not gui.Parent then
        pcall(function()
            gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui", 10)
        end)
    end
    if not gui.Parent then
        error("[A2 UI] ScreenGui gagal dipasang ke parent")
    end
    gui.Enabled = true
    self.Gui = gui
    pcall(function() print("[A2 UI] GUI terpasang di: " .. tostring(gui.Parent)) end)

    local main = mk("Frame", {
        Name = "A2Main", Size = UDim2.new(0, 640, 0, 440),
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundColor3 = C.bg, ClipsDescendants = true,
        BorderSizePixel = 0, Parent = gui,
    })
    corner(main, 14); stroke(main, C.stroke, 1, 0.25)
    self.Main = main

    local scale = mk("UIScale", { Parent = main })
    local function fit()
        local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
        -- Ukuran default diperkecil agar tidak memenuhi layar, tetapi tetap
        -- menyesuaikan resolusi dan tidak keluar dari viewport.
        local s = 0.78 * math.min(1, (vp.X - 30) / 640, (vp.Y - 30) / 440)
        if s < 0.45 then s = 0.45 end
        scale.Scale = s
    end
    fit()
    pcall(function()
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
    end)

    -- topbar
    local top = mk("Frame", {
        Name = "Top", Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = C.panel,
        BorderSizePixel = 0, Parent = main,
    })
    corner(top, 14)
    mk("Frame", { Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 1, -14),
        BackgroundColor3 = C.panel, BorderSizePixel = 0, Parent = top })
    draggable(main, top)
    mk("Frame", { Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2),
        BackgroundColor3 = C.accent, BorderSizePixel = 0, Parent = top })

    local logo = mk("Frame", { Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(0, 12, 0.5, -15),
        BackgroundColor3 = C.accent, BorderSizePixel = 0, Parent = top })
    corner(logo, 8)
    local logoText = mk("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "A2",
        Font = Enum.Font.GothamBlack, TextSize = 15, TextColor3 = C.bg, Parent = logo })
    textGlow(logoText, C.text, 0.55)

    local titleText = mk("TextLabel", { Size = UDim2.new(0, 270, 0, 20), Position = UDim2.new(0, 52, 0, 7),
        BackgroundTransparency = 1, Text = opts.Title or "A2", Font = Enum.Font.GothamBold,
        TextSize = 15, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left, Parent = top })
    textGlow(titleText, C.accent, 0.78)
    if opts.Shine ~= false then shineText(titleText, C.accent) end
    mk("TextLabel", { Size = UDim2.new(0, 270, 0, 14), Position = UDim2.new(0, 52, 0, 26),
        BackgroundTransparency = 1, Text = opts.Author or "", Font = Enum.Font.Gotham,
        TextSize = 11, TextColor3 = C.dim, TextXAlignment = Enum.TextXAlignment.Left, Parent = top })

    local status = mk("Frame", {
        Size = UDim2.new(0, 78, 0, 22), Position = UDim2.new(1, -164, 0.5, -11),
        BackgroundColor3 = C.card2, BorderSizePixel = 0, Parent = top,
    })
    corner(status, 7)
    mk("Frame", {
        Size = UDim2.new(0, 6, 0, 6), Position = UDim2.new(0, 9, 0.5, -3),
        BackgroundColor3 = C.accent, BorderSizePixel = 0, Parent = status,
    })
    corner(status:FindFirstChildOfClass("Frame"), 3)
    local statusText = mk("TextLabel", {
        Size = UDim2.new(1, -23, 1, 0), Position = UDim2.new(0, 20, 0, 0),
        BackgroundTransparency = 1, Text = opts.Status or "ONLINE", Font = Enum.Font.GothamBold,
        TextSize = 9, TextColor3 = C.accent, TextXAlignment = Enum.TextXAlignment.Left, Parent = status,
    })
    textGlow(statusText, C.accent, 0.62)

    local function winBtn(x, txt, col, cb)
        local b = mk("TextButton", {
            Size = UDim2.new(0, 26, 0, 26), Position = UDim2.new(1, x, 0.5, -13),
            BackgroundColor3 = C.card2, BorderSizePixel = 0, Text = txt,
            Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = col or C.dim,
            AutoButtonColor = false, Parent = top,
        })
        corner(b, 8)
        b.MouseButton1Click:Connect(cb)
        return b
    end
    winBtn(-70, "-", C.dim, function() self:Minimize() end)
    winBtn(-38, "X", C.bad, function() self:Close() end)

    -- sidebar
    local side = mk("Frame", {
        Name = "Side", Size = UDim2.new(0, 152, 1, -46), Position = UDim2.new(0, 0, 0, 46),
        BackgroundColor3 = C.panel, BorderSizePixel = 0, Parent = main,
    })
    mk("Frame", { Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = C.stroke, BorderSizePixel = 0, Parent = side })
    mk("TextLabel", {
        Size = UDim2.new(1, -20, 0, 26), Position = UDim2.new(0, 10, 0, 8),
        BackgroundTransparency = 1, Text = opts.SidebarTitle or "NAVIGATION", Font = Enum.Font.GothamBold,
        TextSize = 9, TextColor3 = C.dim, TextXAlignment = Enum.TextXAlignment.Left, Parent = side,
    })
    local sideScroll = mk("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, -42), Position = UDim2.new(0, 0, 0, 42),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 2, ScrollBarImageColor3 = C.stroke,
        CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = side,
    })
    vlist(sideScroll, 4, Enum.HorizontalAlignment.Center)
    pad(sideScroll, 8, 8, 8, 8)
    self.SideScroll = sideScroll

    -- content
    local content = mk("Frame", {
        Name = "Content", Size = UDim2.new(1, -152, 1, -46), Position = UDim2.new(0, 152, 0, 46),
        BackgroundColor3 = C.bg, BorderSizePixel = 0, Parent = main,
    })
    self.Content = content

    -- floating open button
    if opts.OpenButton and opts.OpenButton.Enabled ~= false then
        local ob = mk("TextButton", {
            Name = "A2Open", Size = UDim2.new(0, 54, 0, 54),
            Position = UDim2.new(0, 20, 0.5, -27), BackgroundColor3 = C.accent,
            BorderSizePixel = 0, Text = "A2", Font = Enum.Font.GothamBlack,
            TextSize = 18, TextColor3 = C.bg, AutoButtonColor = false,
            Visible = false, Parent = gui,
        })
        corner(ob, 16); stroke(ob, C.accent2, 2, 0.2)
        draggable(ob)
        ob.MouseButton1Click:Connect(function() self:Open() end)
        self.OpenBtn = ob
    end

    self.Minimized = false
    return self
end

function A2UI:Open()
    self._visible = true
    if self.Main then self.Main.Visible = true end
    if self.OpenBtn then self.OpenBtn.Visible = false end
end

function A2UI:Close()
    self._visible = false
    if self.Main then self.Main.Visible = false end
    if self.OpenBtn then self.OpenBtn.Visible = true end
end

function A2UI:Minimize()
    self.Minimized = not self.Minimized
    if self.Minimized then
        self:Close()
    else
        self:Open()
    end
end

function A2UI:Tag(opts)
    -- Tag cuma badge kecil di topbar; kita tampilkan sebagai teks subtitle tambahan
    opts = opts or {}
    if opts.Title and self.Main then
        local top = self.Main:FindFirstChild("Top")
        if top then
            local badge = mk("TextLabel", {
                Size = UDim2.new(0, 0, 0, 18), AutomaticSize = Enum.AutomaticSize.X,
                Position = UDim2.new(1, -108, 0.5, -9), BackgroundColor3 = C.card2,
                BackgroundTransparency = 0, Text = "  " .. tostring(opts.Title) .. "  ",
                Font = Enum.Font.GothamMedium, TextSize = 10, TextColor3 = C.dim, Parent = top,
            })
            corner(badge, 6)
        end
    end
end

-- ------------------------------------------------------------------ TAB ----
local Tab = {}
Tab.__index = Tab

function A2UI:Tab(opts)
    opts = opts or {}
    self._tabCount = self._tabCount + 1
    local idx = self._tabCount
    local tab = setmetatable({}, Tab)
    tab.Window = self
    tab._count = 0

    local btn = mk("TextButton", {
        Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = C.card2,
        BackgroundTransparency = 1, BorderSizePixel = 0, Text = "",
        AutoButtonColor = false, LayoutOrder = idx, Parent = self.SideScroll,
    })
    corner(btn, 10)
    local icon, iconIsImage = makeIcon(btn, opts.Icon or "•", {
        Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(0, 10, 0.5, -11),
        Color = C.dim, Glow = true,
    })
    local hl = mk("Frame", { Size = UDim2.new(0, 3, 0, 18), Position = UDim2.new(0, 0, 0.5, -9),
        BackgroundColor3 = C.accent, BorderSizePixel = 0, Visible = false, Parent = btn })
    corner(hl, 2)
    local lbl = mk("TextLabel", {
        Size = UDim2.new(1, -42, 1, 0), Position = UDim2.new(0, 36, 0, 0),
        BackgroundTransparency = 1, Text = opts.Title or ("Tab " .. idx),
        Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.dim,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = btn,
    })
    tab._btn, tab._hl, tab._lbl, tab._icon, tab._iconIsImage = btn, hl, lbl, icon, iconIsImage

    local page = mk("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = C.stroke,
        CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false, Parent = self.Content,
    })
    vlist(page, 10, Enum.HorizontalAlignment.Left)
    pad(page, 14, 14, 14, 14)
    tab._page = page

    btn.MouseButton1Click:Connect(function() self:SelectTab(tab) end)
    btn.MouseEnter:Connect(function()
        if self._currentTab ~= tab then
            TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundTransparency = 0.75 }):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if self._currentTab ~= tab then
            TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundTransparency = 1 }):Play()
        end
    end)
    self.Tabs[#self.Tabs + 1] = tab
    if #self.Tabs == 1 then self:SelectTab(tab) end
    return tab
end

function A2UI:SelectTab(tab)
    for _, t in ipairs(self.Tabs) do
        local on = (t == tab)
        t._page.Visible = on
        t._btn.BackgroundTransparency = on and 0 or 1
        t._hl.Visible = on
        t._lbl.TextColor3 = on and C.text or C.dim
        if t._iconIsImage then
            t._icon.ImageColor3 = on and C.accent or C.dim
        else
            t._icon.TextColor3 = on and C.accent or C.dim
            t._icon.TextStrokeColor3 = C.accent
            t._icon.TextStrokeTransparency = on and 0.38 or 1
        end
    end
    self._currentTab = tab
end

function Tab:Space()
    mk("Frame", { Size = UDim2.new(1, 0, 0, 2), BackgroundTransparency = 1, Parent = self._page })
end

-- -------------------------------------------------------------- SECTION ----
local Section = {}
Section.__index = Section

function Tab:Section(opts)
    opts = opts or {}
    local sec = setmetatable({}, Section)
    sec.Tab = self
    sec._count = 0

    local card = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = C.card, BorderSizePixel = 0, Parent = self._page,
    })
    corner(card, 12); stroke(card, C.stroke, 1, 0.55)
    local inner = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, Parent = card,
    })
    vlist(inner, 8, Enum.HorizontalAlignment.Left)
    pad(inner, 12, 12, 12, 12)

    if opts.Title then
        local h = mk("TextLabel", {
            Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = opts.Title,
            Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.accent,
            TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = -1000, Parent = inner,
        })
    end
    sec._inner = inner
    sec._card = card
    return sec
end

function Section:Space()
    mk("Frame", { Size = UDim2.new(1, 0, 0, 2), BackgroundTransparency = 1,
        LayoutOrder = self._count, Parent = self._inner })
end

-- Row helper: bikin baris judul + deskripsi, balikin (row, titleLabel, descLabel)
function Section:_row(title, desc)
    self._count = self._count + 1
    local row = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, LayoutOrder = self._count, Parent = self._inner,
    })
    local textHolder = mk("Frame", {
        Size = UDim2.new(1, -56, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, Parent = row,
    })
    vlist(textHolder, 2)
    local t = mk("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, Text = title or "", Font = Enum.Font.GothamMedium,
        TextSize = 13, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true, Parent = textHolder,
    })
    local d
    if desc and desc ~= "" then
        d = mk("TextLabel", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1, Text = desc, Font = Enum.Font.Gotham,
            TextSize = 11, TextColor3 = C.dim, TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true, Parent = textHolder,
        })
    end
    return row, t, d
end

-- --------------------------------------------------------------- TOGGLE ----
function Section:Toggle(opts)
    opts = opts or {}
    local row = self:_row(opts.Title, opts.Desc)
    local state = opts.Value and true or false

    local sw = mk("Frame", {
        Size = UDim2.new(0, 42, 0, 22), Position = UDim2.new(1, -42, 0, 0),
        BackgroundColor3 = C.card2, BorderSizePixel = 0, Parent = row,
    })
    corner(sw, 11)
    local knob = mk("Frame", {
        Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(0, 3, 0.5, -8),
        BackgroundColor3 = C.dim, BorderSizePixel = 0, Parent = sw,
    })
    corner(knob, 8)

    local obj = {}
    local function render()
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
            BackgroundColor3 = state and C.bg or C.dim,
        }):Play()
        TweenService:Create(sw, TweenInfo.new(0.15), {
            BackgroundColor3 = state and C.accent or C.card2,
        }):Play()
    end
    render()

    local function setState(v, fire)
        state = v and true or false
        render()
        if fire ~= false and opts.Callback then
            task.spawn(function() opts.Callback(state) end)
        end
    end

    local hit = mk("TextButton", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "",
        Parent = row,
    })
    hit.MouseButton1Click:Connect(function() setState(not state, true) end)

    obj.Set = function(v, fire) setState(v, fire) end
    obj.Get = function() return state end
    return obj
end

-- --------------------------------------------------------------- SLIDER ----
function Section:Slider(opts)
    opts = opts or {}
    local v = opts.Value or {}
    local min = tonumber(v.Min) or 0
    local max = tonumber(v.Max) or 100
    if max < min then min, max = max, min end
    local step = tonumber(opts.Step) or 1
    local cur = tonumber(v.Default) or min
    if cur < min then cur = min end
    if cur > max then cur = max end

    local row = self:_row(opts.Title, opts.Desc)
    local range = max - min
    local alpha = range > 0 and (cur - min) / range or 0
    -- value badge
    local badge = mk("TextLabel", {
        Size = UDim2.new(0, 0, 0, 18), AutomaticSize = Enum.AutomaticSize.X,
        Position = UDim2.new(1, -52, 0, 0), BackgroundColor3 = C.card2,
        Text = "  " .. tostring(cur) .. "  ", Font = Enum.Font.GothamMedium,
        TextSize = 11, TextColor3 = C.accent, Parent = row,
    })
    corner(badge, 6)

    -- track
    local track = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 8), Position = UDim2.new(0, 0, 0, 26),
        BackgroundColor3 = C.card2, BorderSizePixel = 0, Parent = row,
    })
    corner(track, 4)
    local fill = mk("Frame", {
        Size = UDim2.new(alpha, 0, 1, 0),
        BackgroundColor3 = C.accent, BorderSizePixel = 0, Parent = track,
    })
    corner(fill, 4)
    local knob = mk("Frame", {
        Size = UDim2.new(0, 16, 0, 16), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(alpha, 0, 0.5, 0),
        BackgroundColor3 = C.text, BorderSizePixel = 0, Parent = track,
    })
    corner(knob, 8); stroke(knob, C.accent, 2, 0)

    local dragging = false
    local function setVal(val, fire)
        val = math.clamp(val, min, max)
        if step > 0 then val = math.floor(val / step + 0.5) * step end
        cur = val
        local a = range > 0 and (cur - min) / range or 0
        fill.Size = UDim2.new(a, 0, 1, 0)
        knob.Position = UDim2.new(a, 0, 0.5, 0)
        badge.Text = "  " .. tostring(cur) .. "  "
        if fire ~= false and opts.Callback then
            task.spawn(function() opts.Callback(cur) end)
        end
    end

    local function fromX(x)
        local a = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        setVal(min + a * (max - min), true)
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            fromX(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            fromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    local obj = {}
    obj.Set = function(val) setVal(val, false) end
    obj.Get = function() return cur end
    return obj
end

-- --------------------------------------------------------------- BUTTON ----
local function colorOf(c)
    if typeof(c) == "Color3" then return c end
    if type(c) == "string" then return C[c:lower()] or C.accent end
    return C.accent
end

function Section:Button(opts)
    opts = opts or {}
    self._count = self._count + 1
    local col = colorOf(opts.Color)

    local btn = mk("TextButton", {
        Size = UDim2.new(1, 0, 0, opts.Desc and 44 or 34),
        BackgroundColor3 = col, BackgroundTransparency = 0.82, BorderSizePixel = 0,
        Text = "", AutoButtonColor = false, LayoutOrder = self._count, Parent = self._inner,
    })
    corner(btn, 9); stroke(btn, col, 1, 0.4)

    local title = mk("TextLabel", {
        Size = UDim2.new(1, opts.Icon and -38 or -16, 0, 16), Position = UDim2.new(0, opts.Icon and 30 or 8, 0, opts.Desc and 6 or 9),
        BackgroundTransparency = 1, Text = opts.Title or "Button",
        Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.text,
        TextXAlignment = opts.Justify == "Center" and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
        Parent = btn,
    })
    if opts.Icon then
        makeIcon(btn, opts.Icon, {
            Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(0, 7, 0.5, -11),
            Color = col, Glow = true,
        })
    end
    if opts.Glow then textGlow(title, col, tonumber(opts.GlowStrength) or 0.72) end
    if opts.Shine then shineText(title, col) end
    if opts.Desc then
        mk("TextLabel", {
            Size = UDim2.new(1, -16, 0, 14), Position = UDim2.new(0, 8, 0, 24),
            BackgroundTransparency = 1, Text = opts.Desc, Font = Enum.Font.Gotham,
            TextSize = 10, TextColor3 = C.dim,
            TextXAlignment = opts.Justify == "Center" and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
            Parent = btn,
        })
    end

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundTransparency = 0.68 }):Play()
        if opts.Glow then TweenService:Create(title, TweenInfo.new(0.12), { TextStrokeTransparency = 0.35 }):Play() end
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundTransparency = 0.82 }):Play()
        if opts.Glow then TweenService:Create(title, TweenInfo.new(0.12), { TextStrokeTransparency = tonumber(opts.GlowStrength) or 0.72 }):Play() end
    end)
    btn.MouseButton1Click:Connect(function()
        if opts.Callback then task.spawn(function() opts.Callback() end) end
    end)
    return btn
end

-- ---------------------------------------------------------------- INPUT ----
function Section:Input(opts)
    opts = opts or {}
    self._count = self._count + 1
    local row = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, LayoutOrder = self._count, Parent = self._inner,
    })
    mk("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Text = opts.Title or "Input",
        Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = C.text,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
    })
    local box = mk("TextBox", {
        Size = UDim2.new(1, 0, 0, 34), Position = UDim2.new(0, 0, 0, 20),
        BackgroundColor3 = C.card2, BorderSizePixel = 0, Text = opts.Value or "",
        PlaceholderText = opts.Placeholder or "", PlaceholderColor3 = C.dim,
        Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.text,
        TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Parent = row,
    })
    corner(box, 8); stroke(box, C.stroke, 1, 0.5)
    pad(box, 0, 10, 0, 10)

    box.Focused:Connect(function() stroke(box, C.accent, 1, 0.2) end)
    box.FocusLost:Connect(function()
        stroke(box, C.stroke, 1, 0.5)
        if opts.Callback then task.spawn(function() opts.Callback(box.Text) end) end
    end)
    return box
end

-- ------------------------------------------------------------- DROPDOWN ----
function Section:Dropdown(opts)
    opts = opts or {}
    self._count = self._count + 1
    local values = opts.Values or {}
    local current = opts.Value
    local open = false

    local row = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, LayoutOrder = self._count, Parent = self._inner,
    })
    mk("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Text = opts.Title or "Dropdown",
        Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = C.text,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
    })
    local btn = mk("TextButton", {
        Size = UDim2.new(1, 0, 0, 34), Position = UDim2.new(0, 0, 0, 20),
        BackgroundColor3 = C.card2, BorderSizePixel = 0,
        Text = "  " .. tostring(current or "Pilih..."), Font = Enum.Font.Gotham,
        TextSize = 12, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false, Parent = row,
    })
    corner(btn, 8); stroke(btn, C.stroke, 1, 0.5)

    local listFrame = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 1, 4),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.panel,
        BorderSizePixel = 0, Visible = false, ZIndex = 50, Parent = btn,
    })
    corner(listFrame, 8); stroke(listFrame, C.stroke, 1, 0.3)
    local listScroll = mk("ScrollingFrame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
        ScrollBarImageColor3 = C.stroke, CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = listFrame,
    })
    vlist(listScroll, 2)
    pad(listScroll, 6, 6, 6, 6)
    mk("UISizeConstraint", { MaxSize = Vector2.new(9999, 180), Parent = listScroll })

    local obj = {}
    local function rebuild()
        for _, ch in ipairs(listScroll:GetChildren()) do
            if ch:IsA("TextButton") then ch:Destroy() end
        end
        for i, val in ipairs(values) do
            local it = mk("TextButton", {
                Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = C.card,
                BackgroundTransparency = (tostring(val) == tostring(current)) and 0.6 or 1,
                BorderSizePixel = 0, Text = "  " .. tostring(val), Font = Enum.Font.Gotham,
                TextSize = 11, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left,
                AutoButtonColor = false, LayoutOrder = i, Parent = listScroll,
            })
            corner(it, 6)
            it.MouseButton1Click:Connect(function()
                current = val
                btn.Text = "  " .. tostring(val)
                open = false
                listFrame.Visible = false
                if opts.Callback then task.spawn(function() opts.Callback(val) end) end
            end)
        end
    end
    rebuild()

    btn.MouseButton1Click:Connect(function()
        open = not open
        listFrame.Visible = open
        if open then rebuild() end
    end)

    obj.Refresh = function(newValues)
        values = newValues or {}
        rebuild()
    end
    obj.Select = function(val)
        current = val
        btn.Text = "  " .. tostring(val)
    end
    obj.Get = function() return current end
    return obj
end

-- ------------------------------------------------------------ PARAGRAPH ----
function Section:Paragraph(opts)
    opts = opts or {}
    self._count = self._count + 1
    local col = colorOf(opts.Color)
    local card = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = C.card2, BackgroundTransparency = 0.4, BorderSizePixel = 0,
        LayoutOrder = self._count, Parent = self._inner,
    })
    corner(card, 9)
    local bar = mk("Frame", { Size = UDim2.new(0, 3, 1, -12), Position = UDim2.new(0, 0, 0, 6),
        BackgroundColor3 = col, BorderSizePixel = 0, Parent = card })
    corner(bar, 2)
    local holder = mk("Frame", { Size = UDim2.new(1, -16, 0, 0), Position = UDim2.new(0, 12, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = card })
    vlist(holder, 2)
    pad(holder, 8, 4, 8, 0)

    local title = mk("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, Text = opts.Title or "", Font = Enum.Font.GothamBold,
        TextSize = 12, TextColor3 = col, TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true, Parent = holder,
    })
    if opts.Shine then shineText(title, col) end
    local desc = mk("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, Text = opts.Desc or "", Font = Enum.Font.Gotham,
        TextSize = 11, TextColor3 = C.dim, TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true, Parent = holder,
    })

    local obj = {}
    obj.SetTitle = function(t) title.Text = t end
    obj.SetDesc = function(d) desc.Text = d end
    obj.Set = function(t, d)
        if t then title.Text = t end
        if d then desc.Text = d end
    end
    return obj
end

-- Tab-level shortcuts (biar sama kaya WindUI: Tab:Button, Tab:Paragraph)
function Tab:Button(opts) return self:Section({}):Button(opts) end
function Tab:Paragraph(opts) return self:Section({}):Paragraph(opts) end
function Tab:Toggle(opts) return self:Section({}):Toggle(opts) end
function Tab:Input(opts) return self:Section({}):Input(opts) end
function Tab:Dropdown(opts) return self:Section({}):Dropdown(opts) end
function Tab:Slider(opts) return self:Section({}):Slider(opts) end

-- ----------------------------------------------------------- SAFE BOOT ------
function A2UI:Boot(opts)
    local ok, result = pcall(function()
        return self:CreateWindow(opts or {})
    end)
    if ok and result then
        self.LastError = nil
        return result
    end

    local err = tostring(result)
    self.LastError = err
    warn("[A2 UI] CreateWindow gagal: " .. err)

    local parent = guiParent()
    if not parent then return nil, err end
    local fallback
    local fallbackOk, fallbackErr = pcall(function()
        local old = parent:FindFirstChild("A2UI_Fallback")
        if old then old:Destroy() end
        local gui = mk("ScreenGui", {
            Name = "A2UI_Fallback", ResetOnSpawn = false,
            IgnoreGuiInset = true, DisplayOrder = 10000, Parent = parent,
        })
        local card = mk("Frame", {
            Size = UDim2.new(0, 360, 0, 150),
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
            BackgroundColor3 = C.panel, BorderSizePixel = 0, Parent = gui,
        })
        corner(card, 16); stroke(card, C.accent, 1, 0.2)
        mk("TextLabel", {
            Size = UDim2.new(1, -28, 0, 26), Position = UDim2.new(0, 14, 0, 14),
            BackgroundTransparency = 1, Text = "A2 UI Compatibility Mode",
            Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = C.accent,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = card,
        })
        mk("TextLabel", {
            Size = UDim2.new(1, -28, 0, 70), Position = UDim2.new(0, 14, 0, 48),
            BackgroundTransparency = 1, Text = "Library loaded, tetapi window lengkap gagal dibuat.\n" .. err,
            Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.text,
            TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top, Parent = card,
        })
        fallback = gui
    end)
    if not fallbackOk then warn("[A2 UI] Fallback juga gagal: " .. tostring(fallbackErr)) end
    return nil, err
end

-- ---------------------------------------------------------------- AUTO MOUNT
-- File ini sering dijalankan langsung dengan executor, bukan di-require
-- sebagai ModuleScript. Pada mode tersebut, return A2UI saja tidak akan
-- menampilkan apa pun, jadi buat window minimal yang langsung terlihat.
-- Saat dipakai sebagai ModuleScript, auto-mount tidak dijalankan agar API
-- library tetap aman dan caller tetap mengontrol pembuatan window sendiri.
local function isModuleScript()
    local ok, result = pcall(function()
        return script and script:IsA("ModuleScript")
    end)
    return ok and result == true
end

local skipAutoMount = false
pcall(function()
    if type(getgenv) == "function" then
        skipAutoMount = getgenv().A2UI_NO_AUTOMOUNT == true
    end
end)

if not isModuleScript() and not skipAutoMount then
    local defer = (task and task.defer) or (task and task.spawn) or spawn
    defer(function()
        local ok, err = pcall(function()
            local window, bootErr = A2UI:Boot({
                Title = "A2 HUB",
                Author = "A2 UI Library",
                SidebarTitle = "MENU",
                Status = "READY",
                OpenButton = { Enabled = true },
            })
            if not window then error(bootErr or "Boot gagal") end
            local home = window:Tab({ Title = "Home", Icon = 6031075938 })
            local homeSection = home:Section({ Title = "Welcome" })
            homeSection:Paragraph({
                Title = "UI berhasil muncul",
                Desc = "Template aktif. Gunakan tab di kiri untuk mengatur fitur hub kamu.",
                Color = "accent", Shine = true,
            })
            homeSection:Button({ Title = "Test Notification", Icon = 6031071053, Glow = true, Shine = true, Callback = function()
                A2UI:Notify({ Title = "A2 HUB", Content = "Template berjalan dengan normal." })
            end })

            local farm = window:Tab({ Title = "Farm", Icon = 6031075926 })
            local farmSection = farm:Section({ Title = "Farm Control" })
            farmSection:Toggle({ Title = "Enable Farm", Desc = "Aktifkan loop farm otomatis.", Value = false,
                Callback = function(enabled)
                    window:Webhook({ Content = enabled and "Farm dimulai." or "Farm dihentikan." })
                end })
            farmSection:Slider({ Title = "Farm Delay", Desc = "Jeda antar aksi.", Step = 0.1,
                Value = { Min = 0.1, Max = 10, Default = 1 } })
            farmSection:Button({ Title = "Start Farm", Icon = 6031071057, Glow = true, Shine = true, Color = "good" })

            local settings = window:Tab({ Title = "Settings", Icon = 6031071053 })
            local settingsSection = settings:Section({ Title = "General" })
            settingsSection:Dropdown({ Title = "Mode", Values = { "Legit", "Fast", "AFK" }, Value = "Legit" })
            settingsSection:Input({ Title = "Target Name", Placeholder = "Masukkan nama target..." })
            settingsSection:Toggle({ Title = "Auto Execute", Desc = "Hanya template UI; logic executor disambungkan di script utama." })

            local webhookSection = settings:Section({ Title = "Discord Webhook" })
            local webhookInput = webhookSection:Input({
                Title = "Webhook URL",
                Placeholder = "https://discord.com/api/webhooks/...",
                Callback = function(url)
                    local ok, reason = window:SetWebhook(url)
                    A2UI:Notify({
                        Title = ok and "Webhook tersimpan" or "Webhook gagal",
                        Content = ok and "URL hanya disimpan di sesi ini." or reason,
                    })
                end,
            })
            webhookSection:Button({
                Title = "Test Webhook",
                Desc = "Kirim satu pesan percobaan ke Discord.",
                Color = "purple",
                Callback = function()
                    local ok, reason = window:Webhook({ Content = "Test webhook dari A2 HUB berhasil." })
                    A2UI:Notify({
                        Title = ok and "Webhook terkirim" or "Webhook gagal",
                        Content = ok and "Cek channel Discord kamu." or reason,
                    })
                end,
            })
        end)
        if not ok then
            warn("[A2 UI] Gagal membuat window: " .. tostring(err))
        end
    end)
end

return A2UI
