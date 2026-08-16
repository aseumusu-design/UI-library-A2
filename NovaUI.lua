 --[[
  NovaUI v2 — Single-file Roblox UI Library
  Gabungan: NovaUI_Full + NovaUI_Icons + NovaUI_Bubble

  local NovaUI = loadstring(game:HttpGet("https://YOUR-URL/NovaUI.lua"))()
  local Window = NovaUI:CreateWindow({ Title = "Nova Hub", Bubble = true })
  local tab = Window:AddTab({ Text = "Info", Icon = "Info" })
  tab:AddButton({ Text = "Hello", Icon = "Gun", Callback = function() print("hi") end })
--]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local NovaUI = {}
NovaUI.__index = NovaUI
NovaUI.Version = "2.0.1"

local THEME = {
    Background = Color3.fromRGB(17,18,23),
    Surface    = Color3.fromRGB(25,27,34),
    Surface2   = Color3.fromRGB(34,36,45),
    Text       = Color3.fromRGB(242,244,248),
    Muted      = Color3.fromRGB(155,160,172),
    Accent     = Color3.fromRGB(116,92,255),
    Success    = Color3.fromRGB(65,190,120),
    Error      = Color3.fromRGB(235,75,85),
    Warning    = Color3.fromRGB(240,180,65),
    Stroke     = Color3.fromRGB(55,58,70),
}
NovaUI.Theme = THEME

-- Ikon vektor Nova: digambar dari Frame, bukan emoji/font/sprite eksternal.
-- Tiap angka adalah garis x1,y1,x2,y2 dalam kanvas 24x24.
local IconPaths = {
    Menu={{4,6,20,6},{4,12,20,12},{4,18,20,18}},
    OnOff={{12,3,12,11},{7,6,5,8},{5,8,4,12},{4,12,5,16},{5,16,8,19},{8,19,12,20},{12,20,16,19},{16,19,19,16},{19,16,20,12},{20,12,19,8},{19,8,17,6}},
    Sting={{4,13,9,13},{9,13,12,5},{12,5,15,13},{15,13,20,13},{6,18,18,18}},
    Close={{5,5,19,19},{19,5,5,19}},
    Search={{5,5,8,3},{8,3,13,3},{13,3,17,7},{17,7,17,12},{17,12,14,16},{14,16,9,17},{9,17,5,14},{5,14,3,10},{3,10,5,5},{15,15,21,21}},
    Home={{3,11,12,3},{12,3,21,11},{5,10,5,21},{5,21,19,21},{19,21,19,10},{10,21,10,15},{10,15,14,15},{14,15,14,21}},
    Info={{12,10,12,19},{12,5,12,6},{8,3,16,3},{16,3,20,7},{20,7,20,17},{20,17,16,21},{16,21,8,21},{8,21,4,17},{4,17,4,7},{4,7,8,3}},
    Killer={{8,4,16,4},{16,4,20,8},{20,8,20,14},{20,14,16,18},{16,18,15,21},{9,21,8,18},{8,18,4,14},{4,14,4,8},{4,8,8,4},{8,11,10,11},{14,11,16,11},{9,16,12,14},{12,14,15,16}},
    Survival={{12,2,20,6},{20,6,19,14},{19,14,16,19},{16,19,12,22},{12,22,8,19},{8,19,5,14},{5,14,4,6},{4,6,12,2},{8,12,11,15},{11,15,17,9}},
    Teleport={{12,3,17,5},{17,5,20,9},{20,9,20,14},{20,14,17,18},{17,18,12,21},{12,21,7,19},{7,19,4,15},{4,15,4,10},{4,10,7,6},{7,6,12,4},{8,9,15,9},{15,9,15,15},{15,15,10,15}},
    Visual={{2,12,6,8},{6,8,10,6},{10,6,14,6},{14,6,18,8},{18,8,22,12},{22,12,18,16},{18,16,14,18},{14,18,10,18},{10,18,6,16},{6,16,2,12},{9,12,10,9},{10,9,14,9},{14,9,15,12},{15,12,14,15},{14,15,10,15},{10,15,9,12}},
    Settings={{12,3,14,6},{14,6,18,5},{18,5,20,8},{20,8,18,11},{18,11,21,13},{21,13,19,17},{19,17,15,17},{15,17,14,21},{14,21,10,21},{10,21,9,17},{9,17,5,18},{5,18,3,14},{3,14,6,12},{6,12,4,9},{4,9,7,6},{7,6,10,7},{10,7,12,3},{9,12,10,9},{10,9,14,9},{14,9,15,12},{15,12,14,15},{14,15,10,15},{10,15,9,12}},
    Player={{8,3,16,3},{16,3,18,5},{18,5,18,10},{18,10,16,12},{16,12,8,12},{8,12,6,10},{6,10,6,5},{6,5,8,3},{4,21,5,17},{5,17,9,14},{9,14,15,14},{15,14,19,17},{19,17,20,21}},
    Save={{5,3,17,3},{17,3,21,7},{21,7,21,21},{21,21,3,21},{3,21,3,3},{3,3,5,3},{7,3,7,9},{7,9,16,9},{16,9,16,3},{7,21,7,14},{7,14,17,14},{17,14,17,21}},
    Dropdown={{5,8,12,15},{12,15,19,8}},
    Gun={{3,8,15,8},{15,8,20,11},{20,11,15,14},{15,14,11,14},{11,14,9,21},{9,21,5,21},{5,21,7,14},{7,14,3,14},{3,14,3,8}},
    Shoe={{4,5,9,5},{9,5,10,11},{10,11,14,14},{14,14,20,15},{20,15,21,19},{21,19,4,19},{4,19,3,15},{3,15,5,12},{5,12,4,5}},
}
local IconAliases = {Shield="Survival",Skull="Killer",Pistol="Gun",Eye="Visual",Users="Player",Cross="Close",Cross2="Close",Check="Save",Power="OnOff"}
local Icons = {}
Icons.List = {}
for name in pairs(IconPaths) do Icons.List[name] = name end
for name, target in pairs(IconAliases) do Icons.List[name] = target end
function Icons.Get(name) return Icons.List[name] end
function Icons.Search(query)
    query = string.lower(tostring(query or ""))
    local result = {}
    for name, icon in pairs(Icons.List) do
        if string.find(string.lower(name), query, 1, true) then
            table.insert(result, { Name = name, Icon = icon })
        end
    end
    table.sort(result, function(a,b) return a.Name < b.Name end)
    return result
end
function Icons.Names()
    local r = {}
    for n in pairs(Icons.List) do table.insert(r, n) end
    table.sort(r); return r
end
NovaUI.Icons = Icons
function NovaUI:GetIcon(name) return Icons.List[name] end

local ICONS = Icons.List

local function drawIcon(parent, name, size, color)
    local canonical = ICONS[name] or name
    local path = IconPaths[canonical] or IconPaths.Info
    size = math.max(tonumber(size) or 18, 8)
    color = color or THEME.Text

    local canvas = Instance.new("Frame")
    canvas.Name = "NovaIcon_"..tostring(canonical)
    canvas.BackgroundTransparency = 1
    canvas.BorderSizePixel = 0
    canvas.Size = UDim2.fromOffset(size, size)
    -- penting: ikut ZIndex parent supaya tidak tertimbun (ZIndexBehavior = Sibling)
    canvas.ZIndex = (parent and parent:IsA("GuiObject") and parent.ZIndex or 1) + 1
    canvas.Active = false
    canvas.Parent = parent

    local scale = size / 24
    local thickness = math.max(2, math.floor(size / 11 + 0.5))

    local function dot(x, y)
        local d = Instance.new("Frame")
        d.Name = "cap"
        d.AnchorPoint = Vector2.new(.5,.5)
        d.Position = UDim2.fromOffset(x * scale, y * scale)
        d.Size = UDim2.fromOffset(thickness, thickness)
        d.BackgroundColor3 = color
        d.BorderSizePixel = 0
        d.ZIndex = canvas.ZIndex
        d.Parent = canvas
        local r = Instance.new("UICorner"); r.CornerRadius = UDim.new(1,0); r.Parent = d
    end

    for _, line in ipairs(path) do
        local x1,y1,x2,y2 = line[1],line[2],line[3],line[4]
        local dx,dy = (x2-x1)*scale, (y2-y1)*scale
        local length = math.sqrt(dx*dx + dy*dy)
        if length > 0.5 then
            local part = Instance.new("Frame")
            part.Name = "seg"
            part.AnchorPoint = Vector2.new(.5,.5)
            -- posisi pakai offset piksel, bukan scale: aman walau parent belum punya AbsoluteSize
            part.Position = UDim2.fromOffset((x1+x2)/2 * scale, (y1+y2)/2 * scale)
            part.Size = UDim2.fromOffset(math.max(length, thickness), thickness)
            part.Rotation = math.deg(math.atan2(dy, dx))
            part.BackgroundColor3 = color
            part.BackgroundTransparency = 0
            part.BorderSizePixel = 0
            part.ZIndex = canvas.ZIndex
            part.Parent = canvas
            local round = Instance.new("UICorner")
            round.CornerRadius = UDim.new(1,0)
            round.Parent = part
        end
        dot(x1,y1); dot(x2,y2)
    end
    return canvas
end

-- ganti warna semua garis di dalam sebuah ikon
local function recolorIcon(canvas, color)
    if not canvas then return end
    for _, part in ipairs(canvas:GetChildren()) do
        if part:IsA("Frame") then part.BackgroundColor3 = color end
    end
end
Icons.Recolor = recolorIcon

-- cari ikon di dalam sebuah container (nama diawali "NovaIcon_")
local function findIcon(container)
    for _, child in ipairs(container:GetChildren()) do
        if string.sub(child.Name, 1, 9) == "NovaIcon_" then return child end
    end
end
Icons.Find = findIcon

Icons.Draw = drawIcon

-- ============================ HELPERS ============================
local function tween(obj, t, props)
    local tw = TweenService:Create(obj, TweenInfo.new(t or .2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props)
    tw:Play(); return tw
end
local function corner(obj, radius)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, radius or 8); c.Parent = obj
end
local function stroke(obj, color, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or THEME.Stroke
    s.Transparency = transparency or .25
    s.Parent = obj
    return s
end
local function pad(obj, n)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0,n); p.PaddingBottom = UDim.new(0,n)
    p.PaddingLeft = UDim.new(0,n); p.PaddingRight = UDim.new(0,n)
    p.Parent = obj
end
local function makeDraggable(handle, target)
    local dragging, startInput, startPos = false, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; startInput = input.Position; startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - startInput
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

-- ============================ BUBBLE ============================
local Bubble = {}
Bubble.__index = Bubble
function Bubble.new(config)
    config = config or {}
    local self = setmetatable({}, Bubble)
    local gui = Instance.new("ScreenGui")
    gui.Name = config.Name or "NovaUI_Bubble"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = config.Parent or Players.LocalPlayer:WaitForChild("PlayerGui")

    local size = config.Size or 58
    local button = Instance.new("TextButton")
    button.Size = UDim2.fromOffset(size, size)
    button.Position = config.Position or UDim2.new(1, -80, 0.5, -math.floor(size/2))
    button.BackgroundColor3 = config.Color or THEME.Accent
    button.Text = ""
    button.TextColor3 = Color3.new(1,1,1)
    button.TextSize = config.TextSize or 25
    button.Font = Enum.Font.GothamBold
    button.AutoButtonColor = false
    button.Parent = gui
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = button
    stroke(button, Color3.new(1,1,1), .75)
    local bubbleIcon = drawIcon(button, config.Icon or "Menu", math.floor(size*.44), Color3.new(1,1,1))
    bubbleIcon.AnchorPoint = Vector2.new(.5,.5); bubbleIcon.Position = UDim2.fromScale(.5,.5)

    makeDraggable(button, button)
    button.MouseEnter:Connect(function() tween(button,.15,{Size=UDim2.fromOffset(size+5,size+5)}) end)
    button.MouseLeave:Connect(function() tween(button,.15,{Size=UDim2.fromOffset(size,size)}) end)
    button.Activated:Connect(function()
        if config.Callback then
            local ok, err = pcall(config.Callback, self)
            if not ok then warn("[NovaUI Bubble]:", err) end
        end
    end)

    self.Gui = gui; self.Button = button; self.Icon = bubbleIcon
    return self
end
function Bubble:SetIcon(icon)
    if self.Icon then self.Icon:Destroy() end
    local bs = self.Button.AbsoluteSize.X
    if bs < 1 then bs = self.Button.Size.X.Offset end
    if bs < 1 then bs = 58 end
    self.Icon = drawIcon(self.Button, icon or "Menu", math.floor(bs*.44), Color3.new(1,1,1))
    self.Icon.AnchorPoint = Vector2.new(.5,.5); self.Icon.Position = UDim2.fromScale(.5,.5)
end
function Bubble:Destroy() self.Gui:Destroy() end
NovaUI.Bubble = Bubble

-- ============================ WINDOW ============================
function NovaUI:CreateWindow(cfg)
    cfg = cfg or {}
    local gui = Instance.new("ScreenGui")
    gui.Name = cfg.Name or "NovaUI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = cfg.Parent or Players.LocalPlayer:WaitForChild("PlayerGui")

    local winSize = cfg.Size or UDim2.fromOffset(640, 440)
    local main = Instance.new("Frame")
    main.Size = winSize
    main.Position = UDim2.new(.5, -math.floor(winSize.X.Offset/2), .5, -math.floor(winSize.Y.Offset/2))
    main.BackgroundColor3 = THEME.Background
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Parent = gui
    corner(main, 14); stroke(main)

    -- topbar
    local top = Instance.new("Frame")
    top.Size = UDim2.new(1,0,0,52); top.BackgroundColor3 = THEME.Surface; top.BorderSizePixel = 0; top.Parent = main
    corner(top, 14)
    local topFix = Instance.new("Frame")
    topFix.Size = UDim2.new(1,0,0,14); topFix.Position = UDim2.new(0,0,1,-14)
    topFix.BackgroundColor3 = THEME.Surface; topFix.BorderSizePixel = 0; topFix.Parent = top

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(cfg.Icon and 48 or 18,0)
    title.Size = UDim2.new(1,cfg.Icon and -150 or -120,1,0)
    title.Text = cfg.Title or "NovaUI"
    title.TextColor3 = THEME.Text
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = top
    if cfg.Icon then
        local titleIcon = drawIcon(top, cfg.Icon, 20, THEME.Text)
        titleIcon.AnchorPoint = Vector2.new(0,.5); titleIcon.Position = UDim2.new(0,18,.5,0)
    end

    local function topBtn(text, offset)
        local b = Instance.new("TextButton")
        b.Text = text; b.TextColor3 = THEME.Text; b.TextSize = 22; b.Font = Enum.Font.GothamBold
        b.BackgroundTransparency = 1; b.Size = UDim2.fromOffset(46,52); b.Position = UDim2.new(1,offset,0,0)
        b.ZIndex = 3; b.Parent = top
        return b
    end
    local close = topBtn("", -46)
    local minb  = topBtn("−", -92)
    local closeIcon = drawIcon(close,"Close",18,THEME.Text)
    closeIcon.AnchorPoint = Vector2.new(.5,.5); closeIcon.Position = UDim2.fromScale(.5,.5)
    makeDraggable(top, main)

    -- sidebar (tabs w/ icons)
    local sidebar = Instance.new("Frame")
    sidebar.Position = UDim2.fromOffset(0,52)
    sidebar.Size = UDim2.new(0,150,1,-52)
    sidebar.BackgroundColor3 = THEME.Surface
    sidebar.BorderSizePixel = 0
    sidebar.Parent = main
    local sbList = Instance.new("UIListLayout"); sbList.Padding = UDim.new(0,6); sbList.Parent = sidebar
    pad(sidebar, 10)

    -- content host
    local host = Instance.new("Frame")
    host.Position = UDim2.fromOffset(150,52)
    host.Size = UDim2.new(1,-150,1,-52)
    host.BackgroundTransparency = 1
    host.Parent = main

    local Window = { Gui = gui, Main = main, Theme = THEME, Icons = ICONS, Tabs = {} }

    local minimized = false
    minb.Activated:Connect(function()
        minimized = not minimized
        sidebar.Visible = not minimized; host.Visible = not minimized
        tween(main,.2,{Size = minimized and UDim2.new(winSize.X.Scale, winSize.X.Offset, 0, 52) or winSize})
    end)
    close.Activated:Connect(function() gui.Enabled = false end)

    function Window:Toggle() gui.Enabled = not gui.Enabled end
    function Window:Destroy() gui:Destroy() end

    local function makeControls(content)
        local API = {}

        function API:AddLabel(text)
            local l = Instance.new("TextLabel")
            l.BackgroundTransparency = 1; l.Size = UDim2.new(1,0,0,26)
            l.Text = tostring(text or "Label"); l.TextColor3 = THEME.Muted
            l.Font = Enum.Font.GothamBold; l.TextSize = 13
            l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = content
            return l
        end

        function API:AddParagraph(text)
            local l = Instance.new("TextLabel")
            l.BackgroundColor3 = THEME.Surface; l.Size = UDim2.new(1,0,0,0)
            l.AutomaticSize = Enum.AutomaticSize.Y
            l.Text = tostring(text or ""); l.TextColor3 = THEME.Muted
            l.Font = Enum.Font.Gotham; l.TextSize = 13; l.TextWrapped = true
            l.TextXAlignment = Enum.TextXAlignment.Left
            l.TextYAlignment = Enum.TextYAlignment.Top
            l.Parent = content; corner(l,8); pad(l,10)
            return l
        end

        function API:AddButton(c)
            c = c or {}
            local b = Instance.new("TextButton")
            b.AutoButtonColor = false
            b.Size = c.Size or UDim2.new(1,0,0,40)
            b.Text = c.Text or "Button"
            b.TextColor3 = THEME.Text
            b.Font = Enum.Font.GothamMedium
            b.TextSize = 14
            b.BackgroundColor3 = c.Style == "outline" and THEME.Surface or (c.Color or THEME.Accent)
            b.Parent = content
            corner(b,8); stroke(b)
            if c.Icon then
                b.TextXAlignment = Enum.TextXAlignment.Left
                b.Text = "        "..b.Text
                local icon = drawIcon(b,c.Icon,17,THEME.Text)
                icon.AnchorPoint = Vector2.new(0,.5); icon.Position = UDim2.new(0,13,.5,0)
            end
            b.MouseEnter:Connect(function() tween(b,.12,{BackgroundTransparency=.15}) end)
            b.MouseLeave:Connect(function() tween(b,.12,{BackgroundTransparency=0}) end)
            b.Activated:Connect(function()
                if c.Callback then
                    local ok, err = pcall(c.Callback)
                    if not ok then warn("[NovaUI] Button:", err) end
                end
            end)
            return b
        end

        function API:AddToggle(c)
            c = c or {}
            local holder = Instance.new("Frame")
            holder.Size = UDim2.new(1,0,0,42); holder.BackgroundColor3 = THEME.Surface; holder.Parent = content
            corner(holder,8)
            local label = Instance.new("TextLabel")
            label.BackgroundTransparency = 1; label.Position = UDim2.fromOffset(12,0); label.Size = UDim2.new(1,-70,1,0)
            label.Text = c.Text or "Toggle"
            label.TextColor3 = THEME.Text; label.Font = Enum.Font.Gotham; label.TextSize = 14
            label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = holder
            if c.Icon then
                label.Position = UDim2.fromOffset(42,0); label.Size = UDim2.new(1,-100,1,0)
                local icon = drawIcon(holder,c.Icon,17,THEME.Muted)
                icon.AnchorPoint = Vector2.new(0,.5); icon.Position = UDim2.new(0,13,.5,0)
            end
            local sw = Instance.new("TextButton")
            sw.Text = ""; sw.AutoButtonColor = false; sw.Size = UDim2.fromOffset(44,24); sw.Position = UDim2.new(1,-54,.5,-12)
            sw.BackgroundColor3 = THEME.Surface2; sw.Parent = holder; corner(sw,20)
            local knob = Instance.new("Frame")
            knob.Size = UDim2.fromOffset(18,18); knob.Position = UDim2.fromOffset(3,3)
            knob.BackgroundColor3 = THEME.Muted; knob.BorderSizePixel = 0; knob.Parent = sw; corner(knob,20)
            local value = c.Default == true
            local function render()
                tween(sw,.16,{BackgroundColor3 = value and THEME.Accent or THEME.Surface2})
                tween(knob,.16,{
                    Position = value and UDim2.new(1,-21,0,3) or UDim2.fromOffset(3,3),
                    BackgroundColor3 = value and Color3.new(1,1,1) or THEME.Muted,
                })
            end
            sw.Activated:Connect(function()
                value = not value; render()
                if c.Callback then local ok, err = pcall(c.Callback, value); if not ok then warn("[NovaUI] Toggle:", err) end end
            end)
            render()
            return { Instance = holder, GetValue = function() return value end,
                     SetValue = function(v) value = v == true; render(); if c.Callback then pcall(c.Callback, value) end end }
        end

        function API:AddTextbox(c)
            c = c or {}
            local box = Instance.new("TextBox")
            box.Size = UDim2.new(1,0,0,40); box.BackgroundColor3 = THEME.Surface; box.TextColor3 = THEME.Text
            box.PlaceholderColor3 = THEME.Muted; box.PlaceholderText = c.Placeholder or "Ketik di sini..."
            box.Text = c.Default or ""; box.Font = Enum.Font.Gotham; box.TextSize = 14; box.ClearTextOnFocus = false
            box.TextXAlignment = Enum.TextXAlignment.Left; box.Parent = content
            corner(box,8); stroke(box); pad(box,10)
            box.FocusLost:Connect(function()
                if c.Validator then
                    local ok, result = pcall(c.Validator, box.Text)
                    if not ok or result == false then box.Text = ""; warn("[NovaUI] Input tidak valid"); return end
                end
                if c.Callback then pcall(c.Callback, box.Text) end
            end)
            return box
        end

        function API:AddSlider(c)
            c = c or {}
            local minV, maxV = c.Min or 0, c.Max or 100
            local value = math.clamp(c.Value or minV, minV, maxV)
            local holder = Instance.new("Frame"); holder.Size = UDim2.new(1,0,0,54)
            holder.BackgroundTransparency = 1; holder.Parent = content
            local label = Instance.new("TextLabel"); label.BackgroundTransparency = 1; label.Size = UDim2.new(1,0,0,20)
            label.TextColor3 = THEME.Text; label.Font = Enum.Font.Gotham; label.TextSize = 13
            label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = holder
            local bar = Instance.new("TextButton"); bar.Text = ""; bar.AutoButtonColor = false
            bar.Position = UDim2.new(0,0,0,28); bar.Size = UDim2.new(1,0,0,8)
            bar.BackgroundColor3 = THEME.Surface2; bar.Parent = holder; corner(bar,8)
            local fill = Instance.new("Frame"); fill.BackgroundColor3 = THEME.Accent
            fill.BorderSizePixel = 0; fill.Parent = bar; corner(fill,8)
            local function set(pct, fire)
                pct = math.clamp(pct,0,1)
                value = minV + (maxV - minV) * pct
                if c.Round ~= false then value = math.floor(value + .5) end
                label.Text = (c.Text or "Slider").."  "..tostring(value)
                fill.Size = UDim2.new((value - minV)/(maxV - minV),0,1,0)
                if fire ~= false and c.Callback then pcall(c.Callback, value) end
            end
            set((value - minV)/(maxV - minV), false)
            local sliding = false
            local function fromX(x) set((x - bar.AbsolutePosition.X)/bar.AbsoluteSize.X) end
            bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = true; fromX(input.Position.X)
                end
            end)
            UIS.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then sliding = false end
            end)
            UIS.InputChanged:Connect(function(input)
                if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    fromX(input.Position.X)
                end
            end)
            return { Instance = holder, GetValue = function() return value end,
                     SetValue = function(v) set((v - minV)/(maxV - minV)) end }
        end

        function API:AddDropdown(c)
            c = c or {}
            local options = c.Options or {}
            local open = false
            local holder = Instance.new("Frame")
            holder.Size = UDim2.new(1,0,0,40); holder.BackgroundColor3 = THEME.Surface
            holder.ClipsDescendants = true; holder.Parent = content; corner(holder,8)
            local head = Instance.new("TextButton")
            head.Text = c.Default or c.Text or "Dropdown"
            head.TextColor3 = THEME.Text; head.Font = Enum.Font.Gotham; head.TextSize = 14
            head.TextXAlignment = Enum.TextXAlignment.Left; head.BackgroundTransparency = 1
            head.Size = UDim2.new(1,-12,0,40); head.Position = UDim2.fromOffset(12,0); head.Parent = holder
            if c.Icon then
                head.Position = UDim2.fromOffset(42,0); head.Size = UDim2.new(1,-78,0,40)
                local icon = drawIcon(holder,c.Icon,17,THEME.Muted)
                icon.AnchorPoint = Vector2.new(0,.5); icon.Position = UDim2.new(0,13,0,20)
            end
            local arrow = drawIcon(holder,"Dropdown",14,THEME.Muted)
            arrow.AnchorPoint = Vector2.new(1,.5); arrow.Position = UDim2.new(1,-13,0,20)
            local list = Instance.new("ScrollingFrame")
            list.Position = UDim2.fromOffset(6,44); list.Size = UDim2.new(1,-12,0,130)
            list.BackgroundColor3 = THEME.Surface2; list.BorderSizePixel = 0; list.Visible = false
            list.ScrollBarThickness = 2; list.AutomaticCanvasSize = Enum.AutomaticSize.Y
            list.CanvasSize = UDim2.new(); list.Parent = holder; corner(list,8)
            local ll = Instance.new("UIListLayout"); ll.Parent = list
            for _, option in ipairs(options) do
                local item = Instance.new("TextButton")
                item.Text = tostring(option); item.TextColor3 = THEME.Text; item.Font = Enum.Font.Gotham
                item.TextSize = 13; item.BackgroundTransparency = 1; item.Size = UDim2.new(1,0,0,30); item.Parent = list
                item.Activated:Connect(function()
                    head.Text = tostring(option)
                    if c.Callback then pcall(c.Callback, option) end
                    open = false; list.Visible = false; holder.Size = UDim2.new(1,0,0,40)
                end)
            end
            head.Activated:Connect(function()
                open = not open; list.Visible = open
                holder.Size = open and UDim2.new(1,0,0,180) or UDim2.new(1,0,0,40)
            end)
            return holder
        end

        function API:AddKeybind(c)
            c = c or {}
            local key = c.Default or Enum.KeyCode.RightShift
            local b = API:AddButton({ Text = (c.Text or "Keybind").."  ["..key.Name.."]", Style = "outline" })
            local listening = false
            b.Activated:Connect(function()
                listening = true; b.Text = (c.Text or "Keybind").."  [...]"
            end)
            UIS.InputBegan:Connect(function(input, gp)
                if gp then return end
                if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
                if listening then
                    key = input.KeyCode; listening = false
                    b.Text = (c.Text or "Keybind").."  ["..key.Name.."]"
                elseif input.KeyCode == key and c.Callback then
                    pcall(c.Callback)
                end
            end)
            return b
        end

        return API
    end

    -- Notification
    local notifHolder = Instance.new("Frame")
    notifHolder.AnchorPoint = Vector2.new(1,1)
    notifHolder.Position = UDim2.new(1,-18,1,-18)
    notifHolder.Size = UDim2.fromOffset(300,400)
    notifHolder.BackgroundTransparency = 1
    notifHolder.Parent = gui
    local nl = Instance.new("UIListLayout")
    nl.Padding = UDim.new(0,8); nl.VerticalAlignment = Enum.VerticalAlignment.Bottom; nl.Parent = notifHolder

    function Window:Notify(c)
        c = c or {}
        local n = Instance.new("TextLabel")
        n.Size = UDim2.new(1,0,0,0); n.AutomaticSize = Enum.AutomaticSize.Y
        n.BackgroundColor3 = c.Type == "Error" and THEME.Error or (c.Type == "Success" and THEME.Success or THEME.Surface)
        n.TextColor3 = Color3.new(1,1,1); n.Font = Enum.Font.GothamMedium; n.TextSize = 14; n.TextWrapped = true
        n.TextXAlignment = Enum.TextXAlignment.Left
        n.Text = (c.Icon and "      " or "")..(c.Text or "Notification")
        n.Parent = notifHolder; corner(n,10); stroke(n); pad(n,12)
        if c.Icon then
            local icon = drawIcon(n,c.Icon,17,Color3.new(1,1,1))
            icon.AnchorPoint = Vector2.new(0,.5); icon.Position = UDim2.new(0,12,.5,0)
        end
        task.delay(c.Duration or 3, function()
            if n.Parent then tween(n,.2,{TextTransparency=1,BackgroundTransparency=1}); task.wait(.25); n:Destroy() end
        end)
        return n
    end

    -- Tabs
    function Window:AddTab(c)
        c = c or {}
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,0,0,38); btn.AutoButtonColor = false
        btn.BackgroundColor3 = THEME.Surface2; btn.BackgroundTransparency = 1
        btn.Text = "          "..(c.Text or "Tab")
        btn.TextColor3 = THEME.Muted; btn.Font = Enum.Font.GothamMedium; btn.TextSize = 14
        btn.TextXAlignment = Enum.TextXAlignment.Left; btn.Parent = sidebar
        corner(btn,8)
        local tabIcon = drawIcon(btn,c.Icon or "Info",18,THEME.Muted)
        tabIcon.AnchorPoint = Vector2.new(0,.5); tabIcon.Position = UDim2.new(0,11,.5,0)

        local content = Instance.new("ScrollingFrame")
        content.Position = UDim2.fromOffset(14,10)
        content.Size = UDim2.new(1,-28,1,-20)
        content.BackgroundTransparency = 1; content.BorderSizePixel = 0
        content.ScrollBarThickness = 3; content.CanvasSize = UDim2.new()
        content.AutomaticCanvasSize = Enum.AutomaticSize.Y
        content.Visible = false; content.Parent = host
        local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0,8); layout.Parent = content

        local tab = makeControls(content)
        tab.Button = btn; tab.Content = content

        function tab:Select()
            for _, t in ipairs(Window.Tabs) do
                t.Content.Visible = false
                tween(t.Button,.12,{BackgroundTransparency=1})
                t.Button.TextColor3 = THEME.Muted
                recolorIcon(findIcon(t.Button), THEME.Muted)
            end
            content.Visible = true
            tween(btn,.12,{BackgroundTransparency=0, BackgroundColor3=THEME.Accent})
            btn.TextColor3 = THEME.Text
            recolorIcon(tabIcon, THEME.Text)
        end
        btn.Activated:Connect(function() tab:Select() end)

        table.insert(Window.Tabs, tab)
        if #Window.Tabs == 1 then tab:Select() end
        return tab
    end

    -- Bubble toggle
    if cfg.Bubble ~= false then
        Window.BubbleObj = Bubble.new({
            Icon = cfg.BubbleIcon or "Shield",
            Color = THEME.Accent,
            Callback = function() Window:Toggle() end,
        })
    end

    if cfg.ToggleKey ~= false then
        local key = cfg.ToggleKey or Enum.KeyCode.RightShift
        UIS.InputBegan:Connect(function(input, gp)
            if not gp and input.KeyCode == key then Window:Toggle() end
        end)
    end

    return Window
end

return NovaUI
