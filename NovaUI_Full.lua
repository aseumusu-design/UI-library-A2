-- NovaUI_Full.lua
-- Single-file Roblox UI library.
-- Usage:
-- local NovaUI = loadstring(game:HttpGet("YOUR_RAW_URL"))()
-- local Window = NovaUI:CreateWindow({Title="NovaUI", Size=UDim2.fromOffset(620,420)})
-- Window:AddButton({Text="Hello", Callback=function() print("Hello") end})
-- Window:AddToggle({Text="Enabled", Default=true, Callback=function(v) print(v) end})
-- Window:AddSlider({Text="Volume", Min=0, Max=100, Value=50, Callback=function(v) print(v) end})
-- Window:AddTextbox({Text="Name", Placeholder="Type...", Callback=function(v) print(v) end})
-- Window:AddDropdown({Text="Mode", Options={"Easy","Normal","Hard"}, Callback=function(v) print(v) end})

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local NovaUI = {}
NovaUI.__index = NovaUI

local THEME = {
    Background = Color3.fromRGB(17,18,23),
    Surface = Color3.fromRGB(25,27,34),
    Surface2 = Color3.fromRGB(34,36,45),
    Text = Color3.fromRGB(242,244,248),
    Muted = Color3.fromRGB(155,160,172),
    Accent = Color3.fromRGB(116,92,255),
    Success = Color3.fromRGB(65,190,120),
    Error = Color3.fromRGB(235,75,85),
    Warning = Color3.fromRGB(240,180,65),
    Stroke = Color3.fromRGB(55,58,70),
}

local ICONS = {
    Home="⌂", Settings="⚙", Search="⌕", Info="ⓘ", Close="×",
    Check="✓", Cross="✕", Cross2="✖", Skull="☠", Shield="🛡",
    Teleport="✦", Shoe="♢", Save="▣", Discord="◈", Menu="☰",
    More="⋮", Play="▶", Pause="Ⅱ", Stop="■", Edit="✎", Trash="♲",
    Copy="▣", Cloud="☁", Key="⚿", Eye="◉", EyeOff="⊘", Users="♟",
    Server="▥", Globe="◎", Bug="♧", Terminal=">_", Gamepad="⌘",
    Camera="◉", Mic="♩", Volume="◖", Mute="◗", Speed="⌁",
    Flash="ϟ", Fire="♨", Crown="♛", Sword="⚔", Crosshair="⊙",
    Pin="⌖", Map="▦", Backpack="▣", Shop="$", Gift="◇", Star="★",
    Heart="♥", Folder="□", Code="</>", Target="◎", Palette="◈",
    Monitor="▣", Mobile="▤", Keyboard="⌨", Plus="+", Minus="−",
    Arrow="›", Lock="◆", Unlock="◇", Warning="!", Success="✓",
    Error="×", Refresh="↻", Download="↓", Upload="↑", Link="↗",
}

local function tween(obj, t, props)
    local tw = TweenService:Create(obj, TweenInfo.new(t or .2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

local function corner(obj, radius)
    local c=Instance.new("UICorner")
    c.CornerRadius=UDim.new(0,radius or 8)
    c.Parent=obj
end

local function stroke(obj, color)
    local s=Instance.new("UIStroke")
    s.Color=color or THEME.Stroke
    s.Transparency=.25
    s.Parent=obj
end

function NovaUI:CreateWindow(cfg)
    cfg=cfg or {}
    local gui=Instance.new("ScreenGui")
    gui.Name=cfg.Name or "NovaUI"
    gui.ResetOnSpawn=false
    gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    gui.Parent=cfg.Parent or Players.LocalPlayer:WaitForChild("PlayerGui")

    local main=Instance.new("Frame")
    main.Size=cfg.Size or UDim2.fromOffset(620,430)
    main.Position=UDim2.new(.5,-310,.5,-215)
    main.BackgroundColor3=THEME.Background
    main.BorderSizePixel=0
    main.Parent=gui
    corner(main,12)
    stroke(main)

    local top=Instance.new("Frame")
    top.Size=UDim2.new(1,0,0,52)
    top.BackgroundColor3=THEME.Surface
    top.BorderSizePixel=0
    top.Parent=main
    corner(top,12)

    local title=Instance.new("TextLabel")
    title.BackgroundTransparency=1
    title.Position=UDim2.fromOffset(16,0)
    title.Size=UDim2.new(1,-110,1,0)
    title.Text=cfg.Title or "NovaUI"
    title.TextColor3=THEME.Text
    title.Font=Enum.Font.GothamBold
    title.TextSize=16
    title.TextXAlignment=Enum.TextXAlignment.Left
    title.Parent=top

    local close=Instance.new("TextButton")
    close.Text="×"
    close.TextColor3=THEME.Text
    close.TextSize=22
    close.Font=Enum.Font.GothamBold
    close.BackgroundTransparency=1
    close.Size=UDim2.fromOffset(46,52)
    close.Position=UDim2.new(1,-46,0,0)
    close.Parent=top
    close.Activated:Connect(function() gui:Destroy() end)

    local min=Instance.new("TextButton")
    min.Text="−"
    min.TextColor3=THEME.Text
    min.TextSize=22
    min.Font=Enum.Font.GothamBold
    min.BackgroundTransparency=1
    min.Size=UDim2.fromOffset(46,52)
    min.Position=UDim2.new(1,-92,0,0)
    min.Parent=top

    local content=Instance.new("ScrollingFrame")
    content.Position=UDim2.fromOffset(12,64)
    content.Size=UDim2.new(1,-24,1,-76)
    content.BackgroundTransparency=1
    content.BorderSizePixel=0
    content.ScrollBarThickness=3
    content.AutomaticCanvasSize=Enum.AutomaticSize.Y
    content.Parent=main

    local layout=Instance.new("UIListLayout")
    layout.Padding=UDim.new(0,8)
    layout.Parent=content

    local dragging=false
    local dragStart,startPos
    top.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true; dragStart=input.Position; startPos=main.Position
            input.Changed:Connect(function()
                if input.UserInputState==Enum.UserInputState.End then dragging=false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
            local d=input.Position-dragStart
            main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
        end
    end)

    local minimized=false
    min.Activated:Connect(function()
        minimized=not minimized
        content.Visible=not minimized
        tween(main,.2,{Size=minimized and UDim2.new(main.Size.X.Scale,main.Size.X.Offset,0,52) or (cfg.Size or UDim2.fromOffset(620,430))})
    end)

    local Window={Gui=gui,Main=main,Content=content,Theme=THEME,Icons=ICONS}

    function Window:AddLabel(text)
        local l=Instance.new("TextLabel")
        l.BackgroundTransparency=1
        l.Size=UDim2.new(1,0,0,30)
        l.Text=text or "Label"
        l.TextColor3=THEME.Text
        l.Font=Enum.Font.GothamBold
        l.TextSize=14
        l.TextXAlignment=Enum.TextXAlignment.Left
        l.Parent=content
        return l
    end

    function Window:AddButton(c)
        c=c or {}
        local b=Instance.new("TextButton")
        b.AutoButtonColor=false
        b.Size=c.Size or UDim2.new(1,0,0,40)
        b.Text=(c.Icon and (ICONS[c.Icon] or c.Icon).."  " or "")..(c.Text or "Button")
        b.TextColor3=THEME.Text
        b.Font=Enum.Font.GothamMedium
        b.TextSize=14
        b.BackgroundColor3=c.Style=="outline" and THEME.Background or (c.Color or THEME.Accent)
        b.Parent=content
        corner(b,8); stroke(b)
        b.MouseEnter:Connect(function() tween(b,.12,{BackgroundTransparency=.08}) end)
        b.MouseLeave:Connect(function() tween(b,.12,{BackgroundTransparency=0}) end)
        b.Activated:Connect(function()
            if c.Callback then
                local ok,err=pcall(c.Callback)
                if not ok then warn("[NovaUI] Button:",err) end
            end
        end)
        return b
    end

    function Window:AddToggle(c)
        c=c or {}
        local holder=Instance.new("Frame")
        holder.Size=UDim2.new(1,0,0,42); holder.BackgroundColor3=THEME.Surface; holder.Parent=content
        corner(holder,8)
        local label=Instance.new("TextLabel")
        label.BackgroundTransparency=1; label.Position=UDim2.fromOffset(12,0); label.Size=UDim2.new(1,-70,1,0)
        label.Text=c.Text or "Toggle"; label.TextColor3=THEME.Text; label.Font=Enum.Font.Gotham; label.TextSize=14
        label.TextXAlignment=Enum.TextXAlignment.Left; label.Parent=holder
        local sw=Instance.new("TextButton")
        sw.Text=""; sw.AutoButtonColor=false; sw.Size=UDim2.fromOffset(44,24); sw.Position=UDim2.new(1,-54,.5,-12)
        sw.BackgroundColor3=THEME.Surface2; sw.Parent=holder; corner(sw,20)
        local knob=Instance.new("Frame")
        knob.Size=UDim2.fromOffset(18,18); knob.Position=UDim2.fromOffset(3,3); knob.BackgroundColor3=THEME.Muted
        knob.Parent=sw; corner(knob,20)
        local value=c.Default==true
        local function render()
            tween(sw,.16,{BackgroundColor3=value and THEME.Accent or THEME.Surface2})
            tween(knob,.16,{Position=value and UDim2.new(1,-21,0,3) or UDim2.fromOffset(3,3),BackgroundColor3=value and Color3.new(1,1,1) or THEME.Muted})
        end
        sw.Activated:Connect(function()
            value=not value; render()
            if c.Callback then local ok,err=pcall(c.Callback,value); if not ok then warn("[NovaUI] Toggle:",err) end end
        end)
        render()
        return {Instance=holder,GetValue=function() return value end,SetValue=function(v) value=v==true;render() end}
    end

    function Window:AddTextbox(c)
        c=c or {}
        local box=Instance.new("TextBox")
        box.Size=UDim2.new(1,0,0,40); box.BackgroundColor3=THEME.Surface; box.TextColor3=THEME.Text
        box.PlaceholderColor3=THEME.Muted; box.PlaceholderText=c.Placeholder or "Type here..."
        box.Text=c.Default or ""; box.Font=Enum.Font.Gotham; box.TextSize=14; box.ClearTextOnFocus=false
        box.TextXAlignment=Enum.TextXAlignment.Left; box.Parent=content; corner(box,8); stroke(box)
        if c.Password then box.TextEditable=true; box.TextTransparency=0; box.TextXAlignment=Enum.TextXAlignment.Left end
        box.FocusLost:Connect(function()
            if c.Validator then
                local ok,result=pcall(c.Validator,box.Text)
                if not ok or result==false then
                    box.Text=""
                    warn("[NovaUI] Invalid textbox input")
                    return
                end
            end
            if c.Callback then pcall(c.Callback,box.Text) end
        end)
        return box
    end

    function Window:AddSlider(c)
        c=c or {}
        local min,max=c.Min or 0,c.Max or 100
        local value=math.clamp(c.Value or min,min,max)
        local holder=Instance.new("Frame"); holder.Size=UDim2.new(1,0,0,54); holder.BackgroundTransparency=1; holder.Parent=content
        local label=Instance.new("TextLabel"); label.BackgroundTransparency=1; label.Size=UDim2.new(1,0,0,20)
        label.Text=(c.Text or "Slider").."  "..tostring(value); label.TextColor3=THEME.Text; label.Font=Enum.Font.Gotham; label.TextSize=13; label.TextXAlignment=Enum.TextXAlignment.Left; label.Parent=holder
        local bar=Instance.new("TextButton"); bar.Text=""; bar.AutoButtonColor=false; bar.Position=UDim2.new(0,0,0,28); bar.Size=UDim2.new(1,0,0,8); bar.BackgroundColor3=THEME.Surface2; bar.Parent=holder; corner(bar,8)
        local fill=Instance.new("Frame"); fill.Size=UDim2.new((value-min)/(max-min),0,1,0); fill.BackgroundColor3=THEME.Accent; fill.Parent=bar; corner(fill,8)
        local function set(x)
            local pct=math.clamp(x,0,1); value=min+(max-min)*pct
            label.Text=(c.Text or "Slider").."  "..string.format("%.2f",value)
            fill.Size=UDim2.new(pct,0,1,0)
            if c.Callback then pcall(c.Callback,value) end
        end
        bar.Activated:Connect(function(input)
            local x=(input.Position.X-bar.AbsolutePosition.X)/bar.AbsoluteSize.X
            set(x)
        end)
        return {Instance=holder,SetValue=function(v) set((v-min)/(max-min)) end,GetValue=function() return value end}
    end

    function Window:AddDropdown(c)
        c=c or {}
        local options=c.Options or {}
        local open=false
        local holder=Instance.new("Frame"); holder.Size=UDim2.new(1,0,0,40); holder.BackgroundColor3=THEME.Surface; holder.ClipsDescendants=true; holder.Parent=content; corner(holder,8)
        local head=Instance.new("TextButton"); head.Text=c.Text or "Dropdown"; head.TextColor3=THEME.Text; head.Font=Enum.Font.Gotham; head.TextSize=14; head.TextXAlignment=Enum.TextXAlignment.Left
        head.BackgroundTransparency=1; head.Size=UDim2.new(1,-12,0,40); head.Position=UDim2.fromOffset(12,0); head.Parent=holder
        local list=Instance.new("ScrollingFrame"); list.Position=UDim2.fromOffset(6,44); list.Size=UDim2.new(1,-12,0,130); list.BackgroundColor3=THEME.Surface2; list.Visible=false; list.ScrollBarThickness=2; list.Parent=holder
        local ll=Instance.new("UIListLayout"); ll.Parent=list
        for _,option in ipairs(options) do
            local item=Instance.new("TextButton"); item.Text=tostring(option); item.TextColor3=THEME.Text; item.Font=Enum.Font.Gotham; item.TextSize=13; item.BackgroundTransparency=1; item.Size=UDim2.new(1,0,0,30); item.Parent=list
            item.Activated:Connect(function()
                head.Text=tostring(option)
                if c.Callback then pcall(c.Callback,option) end
                open=false; list.Visible=false; holder.Size=UDim2.new(1,0,0,40)
            end)
        end
        head.Activated:Connect(function()
            open=not open; list.Visible=open
            holder.Size=open and UDim2.new(1,0,0,180) or UDim2.new(1,0,0,40)
        end)
        return holder
    end

    function Window:Notify(c)
        c=c or {}
        local n=Instance.new("TextLabel")
        n.AnchorPoint=Vector2.new(1,1); n.Position=UDim2.new(1,-18,1,-18); n.Size=UDim2.fromOffset(300,64)
        n.BackgroundColor3=c.Type=="Error" and THEME.Error or (c.Type=="Success" and THEME.Success or THEME.Surface)
        n.TextColor3=Color3.new(1,1,1); n.Font=Enum.Font.GothamMedium; n.TextSize=14; n.TextWrapped=true
        n.Text=(c.Icon and (ICONS[c.Icon] or c.Icon).."  " or "")..(c.Text or "Notification")
        n.Parent=gui; corner(n,10); stroke(n)
        task.delay(c.Duration or 3,function()
            if n.Parent then tween(n,.2,{TextTransparency=1,BackgroundTransparency=1}); task.wait(.22); n:Destroy() end
        end)
        return n
    end

    return Window
end

function NovaUI:GetIcon(name)
    return ICONS[name] or "?"
end

return NovaUI
