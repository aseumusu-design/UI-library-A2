-- ============================================================================
--  A2 UI  —  Custom UI Library (self-contained, TANPA WindUI)
--  Dibuat sendiri buat A2 HUB. API-compatible dengan pemakaian di script.
--  Nama UI: "A2"
-- ============================================================================
local A2UI = {}
A2UI.__index = A2UI

local CoreGui        = game:GetService("CoreGui")
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local function guiParent()
    -- Coba beberapa parent biar GUI PASTI ke-attach (tiap executor beda-beda)
    local p
    pcall(function() if gethui then p = gethui() end end)
    if not p then pcall(function() p = CoreGui end) end
    if not p then
        pcall(function()
            p = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui", 5)
        end)
    end
    return p
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

    local gui = mk("ScreenGui", {
        Name = "A2UI", ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 9999, Enabled = true,
    })
    -- Attach ke parent yang valid + verifikasi benar-benar ke-parent
    local parent = guiParent()
    pcall(function() gui.Parent = parent end)
    if not gui.Parent then
        pcall(function()
            gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui", 5)
        end)
    end
    self.Gui = gui
    pcall(function() print("[A2 UI] GUI terpasang di: " .. tostring(gui.Parent)) end)

    local main = mk("Frame", {
        Name = "A2Main", Size = UDim2.new(0, 640, 0, 440),
        Position = UDim2.new(0.5, -320, 0.5, -220), BackgroundColor3 = C.bg,
        BorderSizePixel = 0, Parent = gui,
    })
    corner(main, 14); stroke(main, C.stroke, 1, 0.25)
    self.Main = main

    local scale = mk("UIScale", { Parent = main })
    local function fit()
        local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
        local s = math.min(1, (vp.X - 30) / 640, (vp.Y - 30) / 440)
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
    mk("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "A2",
        Font = Enum.Font.GothamBlack, TextSize = 15, TextColor3 = C.bg, Parent = logo })

    mk("TextLabel", { Size = UDim2.new(0, 320, 0, 20), Position = UDim2.new(0, 52, 0, 7),
        BackgroundTransparency = 1, Text = opts.Title or "A2", Font = Enum.Font.GothamBold,
        TextSize = 15, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left, Parent = top })
    mk("TextLabel", { Size = UDim2.new(0, 320, 0, 14), Position = UDim2.new(0, 52, 0, 26),
        BackgroundTransparency = 1, Text = opts.Author or "", Font = Enum.Font.Gotham,
        TextSize = 11, TextColor3 = C.dim, TextXAlignment = Enum.TextXAlignment.Left, Parent = top })

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
    local sideScroll = mk("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
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
    local hl = mk("Frame", { Size = UDim2.new(0, 3, 0, 18), Position = UDim2.new(0, 0, 0.5, -9),
        BackgroundColor3 = C.accent, BorderSizePixel = 0, Visible = false, Parent = btn })
    corner(hl, 2)
    local lbl = mk("TextLabel", {
        Size = UDim2.new(1, -18, 1, 0), Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1, Text = opts.Title or ("Tab " .. idx),
        Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.dim,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = btn,
    })
    tab._btn, tab._hl, tab._lbl = btn, hl, lbl

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
        if fire ~= false and opts.Callbac
