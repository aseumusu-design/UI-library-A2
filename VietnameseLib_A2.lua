local Library = {}

local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')
local TweenService = game:GetService('TweenService')
local CoreGui = game:GetService('CoreGui')

local Mobile = if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then true else false

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

-- ═══════ THEME COLORS (cyan + tím neon trên đen sâu) ═══════
-- ═════════ PREMIUM CLEAN DARK PRESET ═════════
local THEME = {
    PRIMARY      = Color3.fromRGB(122, 92, 255),   -- tím premium
    SECONDARY    = Color3.fromRGB(24, 200, 255),   -- electric blue
    GLOW         = Color3.fromRGB(120, 110, 255),  -- glow active dịu
    BG_DEEP      = Color3.fromRGB(11, 13, 18),     -- bg sâu nhất
    BG_PANEL     = Color3.fromRGB(15, 17, 23),     -- panel chính (spec)
    BG_ROW       = Color3.fromRGB(22, 25, 33),     -- row
    BG_HOVER     = Color3.fromRGB(30, 36, 52),     -- hover (spec)
    STROKE_DARK  = Color3.fromRGB(60, 70, 95),     -- viền mờ sạch (spec)
    TEXT_BRIGHT  = Color3.fromRGB(220, 225, 235),  -- text premium (spec)
    TEXT_DIM     = Color3.fromRGB(140, 150, 175),
}

-- Gradient mặc định: trắng-cyan-tím
-- Gradient chính: tím → electric blue (spec)
local GRADIENT_HOT = ColorSequence.new{
    ColorSequenceKeypoint.new(0, THEME.PRIMARY),
    ColorSequenceKeypoint.new(1, THEME.SECONDARY)
}

-- Gradient title: trắng → tím → blue (nhẹ)
local GRADIENT_TITLE = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(245, 248, 255)),
    ColorSequenceKeypoint.new(0.6, THEME.PRIMARY),
    ColorSequenceKeypoint.new(1, THEME.SECONDARY)
}

function Library:Parent()
    if not RunService:IsStudio() then
        return (gethui and gethui()) or CoreGui
    end
    return PlayerGui
end

function Library:Create(Class, Properties)
    local Creations = Instance.new(Class)
    for prop, value in Properties do
        Creations[prop] = value
    end
    return Creations
end

function Library:Draggable(a)
    local Dragging, DragInput, DragStart, StartPosition = nil, nil, nil, nil
    local function Update(input)
        local Delta = input.Position - DragStart
        local pos = UDim2.new(StartPosition.X.Scale, StartPosition.X.Offset + Delta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y)
        TweenService:Create(a, TweenInfo.new(0.3), {Position = pos}):Play()
    end
    a.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragStart = input.Position
            StartPosition = a.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then Dragging = false end
            end)
        end
    end)
    a.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            DragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == DragInput and Dragging then Update(input) end
    end)
end

function Library:Button(Parent): TextButton
    return Library:Create("TextButton", {
        Name = "Click", Parent = Parent,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 1,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.SourceSans, Text = "",
        TextColor3 = Color3.fromRGB(0, 0, 0), TextSize = 14,
        ZIndex = Parent.ZIndex + 3
    })
end

function Library:Tween(info)
    return TweenService:Create(info.v, TweenInfo.new(info.t, Enum.EasingStyle[info.s], Enum.EasingDirection[info.d]), info.g)
end

function Library.Effect(c, p)
    p.ClipsDescendants = true
    local Mouse = LocalPlayer:GetMouse()
    local relativeX = Mouse.X - c.AbsolutePosition.X
    local relativeY = Mouse.Y - c.AbsolutePosition.Y
    if relativeX < 0 or relativeY < 0 or relativeX > c.AbsoluteSize.X or relativeY > c.AbsoluteSize.Y then return end

    -- Ripple effect tím premium
    local ripple = Library:Create("Frame", {
        Parent = p, BackgroundColor3 = THEME.PRIMARY,
        BackgroundTransparency = 0.5, BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, relativeX, 0, relativeY),
        Size = UDim2.new(0, 0, 0, 0), ZIndex = p.ZIndex
    })
    Library:Create("UICorner", { Parent = ripple, CornerRadius = UDim.new(1, 0) })

    local tw = TweenService:Create(ripple, TweenInfo.new(1.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, c.AbsoluteSize.X * 1.5, 0, c.AbsoluteSize.X * 1.5),
        BackgroundTransparency = 1
    })
    tw.Completed:Once(function() ripple:Destroy() end)
    tw:Play()
end

function Library:Asset(rbx)
    if typeof(rbx) == 'number' then return "rbxassetid://" .. rbx end
    if typeof(rbx) == 'string' and rbx:find('rbxassetid://') then return rbx end
    return rbx
end

function Library:NewRows(Parent, Title, Desciption)
    local Rows = Library:Create("Frame", {
        Name = "Rows", Parent = Parent,
        BackgroundColor3 = THEME.BG_ROW,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 40)
    })

    -- Viền cyan glow nhẹ
    Library:Create("UIStroke", {
        Parent = Rows, Color = THEME.STROKE_DARK, Thickness = 1, Transparency = 0.55
    })
    Library:Create("UICorner", { Parent = Rows, CornerRadius = UDim.new(0, 10) })

    Library:Create("UIListLayout", {
        Parent = Rows, Padding = UDim.new(0, 6),
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center
    })
    Library:Create("UIPadding", { Parent = Rows, PaddingBottom = UDim.new(0, 6), PaddingTop = UDim.new(0, 5) })

    local Vectorize_1 = Library:Create("Frame", {
        Name = "Vectorize", Parent = Rows, BackgroundTransparency = 1,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0)
    })
    Library:Create("UIPadding", { Parent = Vectorize_1, PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })

    local Right_1 = Library:Create("Frame", { Name = "Right", Parent = Vectorize_1, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0) })
    Library:Create("UIListLayout", { Parent = Right_1, HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center })

    local Left_1 = Library:Create("Frame", { Name = "Left", Parent = Vectorize_1, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0) })
    local Text_1 = Library:Create("Frame", { Name = "Text", Parent = Left_1, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0) })
    Library:Create("UIListLayout", { Parent = Text_1, HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center })

    Library:Create("TextLabel", {
        Name = "Title", Parent = Text_1, AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = -1,
        Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(1, 0, 0, 13),
        Font = Enum.Font.GothamSemibold, RichText = true, Text = Title,
        TextColor3 = THEME.TEXT_BRIGHT, TextSize = 12,
        TextStrokeTransparency = 0.7, TextXAlignment = Enum.TextXAlignment.Left
    })

    local Title_1 = Rows.Vectorize.Left.Text.Title
    Title_1.TextColor3 = Color3.fromRGB(235, 238, 245)
    Title_1.TextStrokeTransparency = 1

    Library:Create("TextLabel", {
        Name = "Desc", Parent = Text_1, AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(1, 0, 0, 10),
        Font = Enum.Font.GothamMedium, RichText = true, Text = Desciption,
        TextColor3 = Color3.fromRGB(155, 165, 185), TextSize = 11,
        TextStrokeTransparency = 1, TextTransparency = 0,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    -- Hover row (subtle)
    local rowBtn = Library:Button(Rows)
    rowBtn.ZIndex = 0  -- để không chặn click bên trong
    local origRowBG = Rows.BackgroundColor3
    rowBtn.MouseEnter:Connect(function()
        TweenService:Create(Rows, TweenInfo.new(0.18), {
            BackgroundColor3 = Color3.fromRGB(28, 32, 42)
        }):Play()
    end)
    rowBtn.MouseLeave:Connect(function()
        TweenService:Create(Rows, TweenInfo.new(0.18), {
            BackgroundColor3 = origRowBG
        }):Play()
    end)
    
    return Rows
end

function Library:Window(Args)
    local Title = Args.Title or "Xova's Project"
    local SubTitle = Args.SubTitle or "Made by s1nve"

    local Xova = Library:Create("ScreenGui", {
        Name = "XovaNeon", Parent = Library:Parent(),
        ZIndexBehavior = Enum.ZIndexBehavior.Global, IgnoreGuiInset = true
    })

    local Background_1 = Library:Create("Frame", {
        Name = "Background", Parent = Xova,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = THEME.BG_PANEL,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 500, 0, 350)
    })

    -- Stroke neon cyan ngoài
    -- Stroke glow dịu cho panel chính (spec)
    Library:Create("UIStroke", {
        Parent = Background_1,
        Color = THEME.GLOW,
        Thickness = 1.5,
        Transparency = 0.35
    })

    -- Main panel radius (spec)
    Library:Create("UICorner", { Parent = Background_1, CornerRadius = UDim.new(0, 16) })

    -- Background gradient subtle (premium depth)
    Library:Create("UIGradient", {
        Parent = Background_1,
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, THEME.BG_PANEL),
            ColorSequenceKeypoint.new(1, THEME.BG_DEEP)
        },
        Rotation = 135
    })

    function Library:IsDropdownOpen()
        for _, v in pairs(Background_1:GetChildren()) do
            if v.Name == "Dropdown" and v.Visible then return true end
        end
    end

    -- Shadow gấp đôi để nổi bật
    -- Shadow premium mềm chiều sâu cao (spec)
    Library:Create("ImageLabel", {
        Name = "Shadow", Parent = Background_1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 180, 1, 180), ZIndex = 0,
        Image = "rbxassetid://8992230677",
        ImageColor3 = THEME.GLOW, ImageTransparency = 0.72,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(99, 99, 99, 99)
    })

    -- Header
    local Header_1 = Library:Create("Frame", {
        Name = "Header", Parent = Background_1,
        BackgroundTransparency = 1, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 40)
    })

    -- Thanh phân cách dưới header
    local divider = Library:Create("Frame", {
        Parent = Header_1, BackgroundColor3 = THEME.PRIMARY,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 15, 1, -1),
        Size = UDim2.new(1, -30, 0, 1)
    })
    Library:Create("UIGradient", {
        Parent = divider,
        Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(1, 1)
        }
    })

    local Return_1 = Library:Create("ImageLabel", {
        Name = "Return", Parent = Header_1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        Position = UDim2.new(0, 25, 0.5, 1),
        Size = UDim2.new(0, 27, 0, 27),
        Image = "rbxassetid://130391877219356",
        ImageColor3 = THEME.PRIMARY, Visible = false
    })
    Library:Create("UIGradient", { Parent = Return_1, Rotation = 90, Color = GRADIENT_TITLE })

    local HeadScale_1 = Library:Create("Frame", {
        Name = "HeadScale", Parent = Header_1,
        AnchorPoint = Vector2.new(1, 0), BackgroundTransparency = 1,
        BorderSizePixel = 0, Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(1, 0, 1, 0)
    })
    Library:Create("UIListLayout", { Parent = HeadScale_1, FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center })
    Library:Create("UIPadding", { Parent = HeadScale_1, PaddingBottom = UDim.new(0, 15), PaddingLeft = UDim.new(0, 15), PaddingRight = UDim.new(0, 15), PaddingTop = UDim.new(0, 20) })

    local Info_1 = Library:Create("Frame", { Name = "Info", Parent = HeadScale_1, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, -100, 0, 28) })
    Library:Create("UIListLayout", { Parent = Info_1, HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder })

    local Title_1 = Library:Create("TextLabel", {
        Name = "Title", Parent = Info_1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(1, 0, 0, 14),
        Font = Enum.Font.GothamBold, RichText = true, Text = Title,
        TextColor3 = THEME.PRIMARY, TextSize = 16,
        TextStrokeTransparency = 0.7, TextXAlignment = Enum.TextXAlignment.Left
    })
    Library:Create("UIGradient", { Parent = Title_1, Color = GRADIENT_TITLE, Rotation = 90 })

    Library:Create("TextLabel", {
        Name = "SubTitle", Parent = Info_1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(1, 0, 0, 10),
        Font = Enum.Font.GothamMedium, RichText = true, Text = SubTitle,
        TextColor3 = Color3.fromRGB(155, 165, 185), TextSize = 11,
        TextStrokeTransparency = 1, TextTransparency = 0,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local Expires_1 = Library:Create("Frame", { Name = "Expires", Parent = HeadScale_1, BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.new(0.787, 0, -3.5, 0), Size = UDim2.new(0, 100, 0, 40) })
    Library:Create("UIListLayout", { Parent = Expires_1, Padding = UDim.new(0, 10), FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center })

    local Asset_1 = Library:Create("ImageLabel", {
        Name = "Asset", Parent = Expires_1,
        BackgroundTransparency = 1, BorderSizePixel = 0,
        Size = UDim2.new(0, 20, 0, 20),
        Image = "rbxassetid://100865348188048",
        ImageColor3 = THEME.PRIMARY, LayoutOrder = 1
    })
    Library:Create("UIGradient", { Parent = Asset_1, Color = GRADIENT_TITLE, Rotation = 90 })

    local Info_2 = Library:Create("Frame", { Name = "Info", Parent = Expires_1, AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(1, 0, 0, 28) })
    Library:Create("UIListLayout", { Parent = Info_2, HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder })

    local Title_2 = Library:Create("TextLabel", {
        Name = "Title", Parent = Info_2,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(1, 0, 0, 14),
        Font = Enum.Font.GothamSemibold, RichText = true, Text = "Expires at",
        TextColor3 = THEME.PRIMARY, TextSize = 13,
        TextStrokeTransparency = 0.7, TextXAlignment = Enum.TextXAlignment.Right
    })
    Library:Create("UIGradient", { Parent = Title_2, Color = GRADIENT_TITLE, Rotation = 90 })

    local THETIME = Library:Create("TextLabel", {
        Name = "Time", Parent = Info_2,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(1, 0, 0, 10),
        Font = Enum.Font.GothamMedium, RichText = true, Text = "00:00:00 Hours",
        TextColor3 = Color3.fromRGB(155, 165, 185), TextSize = 11,
        TextStrokeTransparency = 1, TextTransparency = 0,
        TextXAlignment = Enum.TextXAlignment.Right
    })

    -- Scale (body) - phần content
    local Scale_1 = Library:Create("Frame", {
        Name = "Scale", Parent = Background_1,
        AnchorPoint = Vector2.new(0, 1), BackgroundTransparency = 1,
        BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 1, -40)
    })

    local Home_1 = Library:Create("Frame", { Name = "Home", Parent = Scale_1, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0) })
    Library:Create("UIPadding", { Parent = Home_1, PaddingBottom = UDim.new(0, 15), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) })

    local MainTabsScrolling = Library:Create("ScrollingFrame", {
        Name = "ScrollingFrame", Parent = Home_1, Active = true,
        BackgroundTransparency = 1, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0), ClipsDescendants = true,
        ScrollBarThickness = 0, ScrollingDirection = Enum.ScrollingDirection.XY
    })
    Library:Create("UIPadding", { Parent = MainTabsScrolling, PaddingBottom = UDim.new(0, 1), PaddingLeft = UDim.new(0, 1), PaddingRight = UDim.new(0, 1), PaddingTop = UDim.new(0, 1) })

    local UIListLayout_1 = Library:Create("UIListLayout", { Parent = MainTabsScrolling, Padding = UDim.new(0, 10), FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Wraps = true })
    UIListLayout_1:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        MainTabsScrolling.CanvasSize = UDim2.new(0, 0, 0, UIListLayout_1.AbsoluteContentSize.Y + 15)
    end)

    local PageService = Library:Create("UIPageLayout", { Parent = Scale_1 })

    local Window = { Gui = Xova, Main = Background_1 }
    function Window:Open() self.Main.Visible = true end
    function Window:Close() self.Main.Visible = false end

    function Window:NewPage(Args)
        local Title = Args.Title or "Unknow"
        local Desc = Args.Desc or "Description"
        local Icon = Args.Icon or 127194456372995

        local NewTabs = Library:Create("Frame", {
            Name = "NewTabs", Parent = MainTabsScrolling,
            BackgroundColor3 = THEME.BG_PANEL,
            BorderSizePixel = 0, Size = UDim2.new(0, 230, 0, 55)
        })
        local Click = Library:Button(NewTabs)
        -- Tab radius (spec)
        Library:Create("UICorner", { Parent = NewTabs, CornerRadius = UDim.new(0, 12) })

        -- Tab active glow dịu (spec)
        Library:Create("UIStroke", {
            Parent = NewTabs, Color = THEME.GLOW,
            Thickness = 1.5, Transparency = 0.35
        })

        local Banner_1 = Library:Create("ImageLabel", {
            Name = "Banner", Parent = NewTabs,
            BackgroundTransparency = 1, BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            Image = "rbxassetid://125411502674016",
            ImageColor3 = THEME.PRIMARY, ImageTransparency = 0.3,
            ScaleType = Enum.ScaleType.Crop
        })
        Library:Create("UICorner", { Parent = Banner_1, CornerRadius = UDim.new(0, 10) })

        -- Tab banner gradient tím -> electric blue (spec)
        Library:Create("UIGradient", {
            Parent = Banner_1,
            Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, THEME.PRIMARY),
                ColorSequenceKeypoint.new(1, THEME.SECONDARY)
            },
            Transparency = NumberSequence.new{
                NumberSequenceKeypoint.new(0, 0.5),
                NumberSequenceKeypoint.new(1, 0.8)
            }
        })

        local Info_1 = Library:Create("Frame", { Name = "Info", Parent = NewTabs, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0) })
        Library:Create("UIListLayout", { Parent = Info_1, Padding = UDim.new(0, 10), FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center })
        Library:Create("UIPadding", { Parent = Info_1, PaddingLeft = UDim.new(0, 15) })

        local Icon_1 = Library:Create("ImageLabel", {
            Name = "Icon", Parent = Info_1,
            BackgroundTransparency = 1, BorderSizePixel = 0,
            LayoutOrder = -1, Size = UDim2.new(0, 25, 0, 25),
            Image = Library:Asset(Icon), ImageColor3 = THEME.PRIMARY
        })
        Library:Create("UIGradient", { Parent = Icon_1, Color = GRADIENT_TITLE, Rotation = 90 })

        local Text_1 = Library:Create("Frame", { Name = "Text", Parent = Info_1, BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.new(0.111, 0, 0.144, 0), Size = UDim2.new(0, 150, 0, 32) })
        Library:Create("UIListLayout", { Parent = Text_1, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center })

        local Title_1 = Library:Create("TextLabel", {
            Name = "Title", Parent = Text_1,
            BackgroundTransparency = 1, BorderSizePixel = 0,
            Size = UDim2.new(0, 150, 0, 14),
            Font = Enum.Font.GothamBold, RichText = true, Text = Title,
            TextColor3 = THEME.PRIMARY, TextSize = 15,
            TextStrokeTransparency = 0.4, TextXAlignment = Enum.TextXAlignment.Left
        })
        Library:Create("UIGradient", { Parent = Title_1, Color = GRADIENT_TITLE, Rotation = 90 })

        Library:Create("TextLabel", {
            Name = "Desc", Parent = Text_1, BackgroundTransparency = 1,
            BorderSizePixel = 0, Size = UDim2.new(0.9, 0, 0, 10),
            Font = Enum.Font.GothamMedium, RichText = true, Text = Desc,
            TextColor3 = THEME.TEXT_DIM, TextSize = 10,
            TextStrokeTransparency = 0.5, TextTransparency = 0.2,
            TextXAlignment = Enum.TextXAlignment.Left
        })

        local NewPage = Library:Create("Frame", { Name = "NewPage", Parent = Scale_1, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0) })

        local PageScrolling_1 = Library:Create("ScrollingFrame", {
            Name = "PageScrolling", Parent = NewPage, Active = true,
            BackgroundTransparency = 1, BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0), ClipsDescendants = true,
            ScrollBarThickness = 0, ScrollingDirection = Enum.ScrollingDirection.XY
        })
        Library:Create("UIPadding", { Parent = PageScrolling_1, PaddingBottom = UDim.new(0, 1), PaddingLeft = UDim.new(0, 15), PaddingRight = UDim.new(0, 15), PaddingTop = UDim.new(0, 1) })

        local UIListLayout_2 = Library:Create("UIListLayout", { Parent = PageScrolling_1, Padding = UDim.new(0, 5), FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder })
        UIListLayout_2:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            PageScrolling_1.CanvasSize = UDim2.new(0, 0, 0, UIListLayout_2.AbsoluteContentSize.Y + 15)
        end)

        local function OnChangPage()
            Library:Tween({ v = HeadScale_1, t = 0.2, s = "Exponential", d = "Out", g = { Size = UDim2.new(1, -30, 1, 0) } }):Play()
            Return_1.Visible = true
            PageService:JumpTo(NewPage)
        end

        local Page = {}

        function Page:Section(Text)
            local title = type(Text) == "table" and (Text.Title or "") or tostring(Text or "")
            local Title = Library:Create("TextLabel", {
                Name = "Title", Parent = PageScrolling_1,
                AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1,
                BorderSizePixel = 0, LayoutOrder = 0,
                Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(1, 0, 0, 20),
                Font = Enum.Font.GothamBold, RichText = true, Text = " " .. title,
                TextColor3 = THEME.PRIMARY, TextSize = 15,
                TextStrokeTransparency = 0.7, TextXAlignment = Enum.TextXAlignment.Left
            })
            Library:Create("UIGradient", { Parent = Title, Color = GRADIENT_TITLE, Rotation = 90 })
            return self
        end

        function Page:Space()
            Library:Create("Frame", { Name = "Space", Parent = PageScrolling_1, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 6) })
            return self
        end

        function Page:Input(Args)
            Args = Args or {}
            local Rows = Library:NewRows(PageScrolling_1, Args.Title or "Input", Args.Desc or "")
            local Box = Library:Create("TextBox", { Parent = Rows.Vectorize.Right, BackgroundColor3 = THEME.BG_DEEP, BorderSizePixel = 0, Size = UDim2.new(0, 150, 0, 25), Text = tostring(Args.Value or ""), PlaceholderText = Args.Placeholder or "", TextColor3 = THEME.TEXT_BRIGHT, PlaceholderColor3 = THEME.TEXT_DIM, TextSize = 11, Font = Enum.Font.Gotham, ClearTextOnFocus = false })
            Library:Create("UICorner", { Parent = Box, CornerRadius = UDim.new(0, 8) })
            Box.FocusLost:Connect(function() if Args.Callback then Args.Callback(Box.Text) end end)
            return { Set = function(_, v) Box.Text = tostring(v or "") end, Get = function() return Box.Text end, Instance = Box }
        end

        function Page:Slider(Args)
            Args = Args or {}
            local min, max = tonumber(Args.Min or (Args.Value and Args.Value.Min)) or 0, tonumber(Args.Max or (Args.Value and Args.Value.Max)) or 100
            local current = tonumber(Args.Default or (Args.Value and Args.Value.Default) or Args.Value) or min
            local step = tonumber(Args.Step or 1) or 1
            local obj = { Value = current }
            local button
            local function update(v)
                current = math.clamp(tonumber(v) or min, min, max); obj.Value = current
                if button then button.Text = tostring(current) end
                if Args.Callback then Args.Callback(current) end
            end
            button = self:Button({ Title = Args.Title or "Slider", Desc = Args.Desc or (tostring(min) .. " - " .. tostring(max)), Text = tostring(current), Callback = function() update(current + step > max and min or current + step) end })
            function obj:Set(v) update(v) end
            function obj:SetMin(v) min = tonumber(v) or min end
            function obj:SetMax(v) max = tonumber(v) or max end
            return obj
        end

        function Page:Dropdown(Args)
            Args = Args or {}
            local values = Args.Values or Args.List or {}
            local current = Args.Value or values[1]
            local obj = { Value = current }
            local button
            local function label(v) return type(v) == "table" and (v.Title or v.Value or "") or tostring(v or "") end
            local function select(v) current = v; obj.Value = v; if button then button.Text = label(v) end; if Args.Callback then Args.Callback(v) end end
            button = self:Button({ Title = Args.Title or "Dropdown", Desc = Args.Desc or "Pilih opsi", Text = label(current), Callback = function()
                local index = 1; for i, v in ipairs(values) do if label(v) == label(current) then index = i break end end
                select(values[index % #values + 1])
            end })
            function obj:Select(v) select(v) end
            function obj:Set(v) select(v) end
            function obj:Refresh(v) values = v or {}; if values[1] then select(values[1]) end end
            return obj
        end

        function Page:Paragraph(Args)
            local Title = Args.Title; local Desc = Args.Desc; local Icon = Args.Image
            local Rows = Library:NewRows(PageScrolling_1, Title, Desc)
            local Left = Rows.Vectorize.Left.Text; local Right = Rows.Vectorize.Right
            local IconLabel = Library:Create("ImageLabel", {
                Parent = Right, AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1, BorderSizePixel = 0,
                Position = UDim2.new(0, 0.5, 0.5, 1), Size = UDim2.new(0, 20, 0, 20),
                Image = Library:Asset(Icon), ImageColor3 = THEME.PRIMARY
            })
            Library:Create("UIGradient", { Parent = IconLabel, Color = GRADIENT_TITLE, Rotation = 90 })
            local Data = { Title = Title, Desc = Desc, Icon = IconLabel, Instance = Rows }
            local obj = setmetatable({}, {
                __newindex = function(t, k, v)
                    rawset(Data, k, v)
                    if k == "Title" then Left.Title.Text = tostring(v)
                    elseif k == "Desc" then Left.Desc.Text = tostring(v) end
                end,
                __index = Data
            })
            function obj:SetTitle(v) obj.Title = v end
            function obj:SetDesc(v) obj.Desc = v end
            function obj:Set(title, desc) if title then obj.Title = title end; if desc then obj.Desc = desc end end
            return obj
        end

        function Page:Button(Args)
            local Title = Args.Title; local Desc = Args.Desc
            local Text = Args.Text or "Click"; local Callback = Args.Callback
            local Rows = Library:NewRows(PageScrolling_1, Title, Desc)
            local Right = Rows.Vectorize.Right

            local Button = Library:Create("Frame", {
                Name = "Button", Parent = Right,
                BackgroundColor3 = THEME.PRIMARY,
                BorderSizePixel = 0,
                Position = UDim2.new(0.73, 0, 0.166, 0),
                Size = UDim2.new(0, 75, 0, 25)
            })
            -- Button radius (spec)
            Library:Create("UICorner", { Parent = Button, CornerRadius = UDim.new(0, 12) })
            -- Gradient button tím -> electric blue (spec)
            Library:Create("UIGradient", {
                Parent = Button,
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, THEME.PRIMARY),
                    ColorSequenceKeypoint.new(1, THEME.SECONDARY)
                },
                Rotation = 45
            })
            -- Stroke nhẹ
            Library:Create("UIStroke", { Parent = Button, Color = Color3.fromRGB(255,255,255), Thickness = 0.5, Transparency = 0.6 })

            local TextLabel = Library:Create("TextLabel", {
                Name = "Title", Parent = Button,
                AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1,
                BorderSizePixel = 0, Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(1, 0, 1, 0),
                Font = Enum.Font.GothamBold, RichText = true, Text = Text,
                TextColor3 = Color3.fromRGB(0, 20, 30), TextSize = 11,
                TextStrokeTransparency = 1
            })
            Button.Size = UDim2.new(0, TextLabel.TextBounds.X + 40, 0, 25)
            local Click = Library:Button(Button)
            
            -- Hover nhẹ (spec)
            local origBG = Button.BackgroundColor3
            Click.MouseEnter:Connect(function()
                TweenService:Create(Button, TweenInfo.new(0.18), {
                    BackgroundColor3 = THEME.BG_HOVER
                }):Play()
            end)
            Click.MouseLeave:Connect(function()
                TweenService:Create(Button, TweenInfo.new(0.18), {
                    BackgroundColor3 = origBG
                }):Play()
            end)
            
            local function Onlick()
                if Library:IsDropdownOpen() then return end
                task.spawn(Library.Effect, Click, Button)
                if Callback then Callback() end
            end
            Click.MouseButton1Click:Connect(Onlick)
            return Click
        end

        function Page:Toggle(Args)
            local Title = Args.Title; local Desc = Args.Desc
            local Value = Args.Value or false; local Callback = Args.Callback or function() end
            local Rows = Library:NewRows(PageScrolling_1, Title, Desc)
            local Left = Rows.Vectorize.Left.Text; local Right = Rows.Vectorize.Right
            local TitleLabel = Left.Title

            local Background = Library:Create("Frame", {
                Name = "Background", Parent = Right,
                BackgroundColor3 = Color3.fromRGB(10, 12, 17),
                BorderSizePixel = 0, Size = UDim2.new(0, 20, 0, 20)
            })
            local UIStroke = Library:Create("UIStroke", { Parent = Background, Color = THEME.STROKE_DARK, Thickness = 1, Transparency = 0.55 })
            Library:Create("UICorner", { Parent = Background, CornerRadius = UDim.new(0, 8) })

            local Highligh_1 = Library:Create("Frame", {
                Name = "Highligh", Parent = Background,
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = THEME.PRIMARY,
                BorderSizePixel = 0, Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(0, 20, 0, 20)
            })
            Library:Create("UICorner", { Parent = Highligh_1, CornerRadius = UDim.new(0, 8) })
            -- Toggle gradient tím -> electric blue (spec)
            Library:Create("UIGradient", {
                Parent = Highligh_1,
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, THEME.PRIMARY),
                    ColorSequenceKeypoint.new(1, THEME.SECONDARY)
                },
                Rotation = 45
            })

            local ImageLabel_1 = Library:Create("ImageLabel", {
                Parent = Highligh_1, AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1, BorderSizePixel = 0,
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(0.45, 0, 0.45, 0),
                Image = "rbxassetid://86682186031062"
            })
            local Click = Library:Button(Background)
            local Data = { Title = Title, Desc = Desc, Value = Value }

            local function OnChanged(value)
                if value then
                    Callback(Data.Value)
                    ImageLabel_1.Size = UDim2.new(0.85, 0, 0.85, 0)
                    TitleLabel.TextColor3 = THEME.PRIMARY
                    Library:Tween({ v = Highligh_1, t = 0.5, s = "Exponential", d = "Out", g = { BackgroundTransparency = 0 } }):Play()
                    Library:Tween({ v = ImageLabel_1, t = 0.5, s = "Exponential", d = "Out", g = { ImageTransparency = 0 } }):Play()
                    Library:Tween({ v = ImageLabel_1, t = 0.3, s = "Exponential", d = "Out", g = { Size = UDim2.new(0.5, 0, 0.5, 0) } }):Play()
                    UIStroke.Thickness = 0
                else
                    Callback(Data.Value)
                    TitleLabel.TextColor3 = THEME.TEXT_BRIGHT
                    Library:Tween({ v = Highligh_1, t = 0.5, s = "Exponential", d = "Out", g = { BackgroundTransparency = 1 } }):Play()
                    Library:Tween({ v = ImageLabel_1, t = 0.5, s = "Exponential", d = "Out", g = { ImageTransparency = 1 } }):Play()
                    UIStroke.Thickness = 1
                end
            end

            local function Init() Data.Value = not Data.Value; OnChanged(Data.Value) end
            local Attribute = setmetatable({}, {
                __newindex = function(t, k, v)
                    rawset(Data, k, v)
                    if k == "Title" then Left.Title.Text = tostring(v)
                    elseif k == "Desc" then Left.Desc.Text = tostring(v)
                    elseif k == "Value" then Data.Value = v; OnChanged(v) end
                end, __index = Data
            })
            function Attribute:Set(v) Attribute.Value = v end
            Click.MouseButton1Click:Connect(function() if Library:IsDropdownOpen() then return end; Init() end)
            OnChanged(Data.Value)
            return Attribute
        end

        -- Hover cho tab card (spec)
        local origTabBG = NewTabs.BackgroundColor3
        Click.MouseEnter:Connect(function()
            TweenService:Create(NewTabs, TweenInfo.new(0.18), {
                BackgroundColor3 = THEME.BG_HOVER
            }):Play()
        end)
        Click.MouseLeave:Connect(function()
            TweenService:Create(NewTabs, TweenInfo.new(0.18), {
                BackgroundColor3 = origTabBG
            }):Play()
        end)

        Click.MouseButton1Click:Connect(OnChangPage)
        return Page
    end

    do
        PageService:JumpTo(Home_1)
        Library:Draggable(Background_1)
        PageService.HorizontalAlignment = Enum.HorizontalAlignment.Left
        PageService.EasingStyle = Enum.EasingStyle.Exponential
        PageService.TweenTime = 0.5
        PageService.GamepadInputEnabled = false
        PageService.ScrollWheelInputEnabled = false
        PageService.TouchInputEnabled = false
        Library.PageService = PageService
        Scale_1.ClipsDescendants = true

        local Return_Button = Library:Button(Return_1)
        local function OnReturn()
            Return_1.Visible = false
            Library:Tween({ v = HeadScale_1, t = 0.3, s = "Exponential", d = "Out", g = { Size = UDim2.new(1, 0, 1, 0) } }):Play()
            PageService:JumpTo(Home_1)
        end

        do
            local ToggleScreen = Library:Create("ScreenGui", { Name = "XovaToggle", Parent = Library:Parent(), ZIndexBehavior = Enum.ZIndexBehavior.Global, IgnoreGuiInset = true })
            local Pillow_1 = Library:Create("TextButton", {
                Name = "Pillow", Parent = ToggleScreen,
                BackgroundColor3 = THEME.BG_PANEL,
                BorderSizePixel = 0, Position = UDim2.new(0.06, 0, 0.15, 0),
                Size = UDim2.new(0, 50, 0, 50), Text = ""
            })
            Library:Create("UICorner", { Parent = Pillow_1, CornerRadius = UDim.new(1, 0) })
            local pStroke = Library:Create("UIStroke", { Parent = Pillow_1, Color = THEME.PRIMARY, Thickness = 2, Transparency = 0.2 })
            
            local logo = Library:Create("ImageLabel", {
                Name = "Logo", Parent = Pillow_1,
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1, BorderSizePixel = 0,
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(0.5, 0, 0.5, 0),
                Image = "rbxassetid://134528790539968",
                ImageColor3 = THEME.PRIMARY,
                Rotation = 0
            })
            
            -- Ring outline xoay liên tục
            local ring = Library:Create("ImageLabel", {
                Parent = Pillow_1,
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(1.3, 0, 1.3, 0),
                Image = "rbxassetid://7948482113",
                ImageColor3 = THEME.PRIMARY,
                ImageTransparency = 0.65,
                ZIndex = 0,
                Rotation = 0
            })
            
            Library:Draggable(Pillow_1)
            
            -- Sound tit tit
            local snd1 = Library:Create("Sound", {
                Parent = Pillow_1,
                SoundId = "rbxassetid://6895079853",
                Volume = 0.6
            })
            local snd2 = Library:Create("Sound", {
                Parent = Pillow_1,
                SoundId = "rbxassetid://4612375233",
                Volume = 0.5
            })
            
            local isAnim = false
            local function toggleMenu()
                if isAnim then return end
                isAnim = true
                
                pcall(function() snd1:Play() end)
                task.delay(0.08, function() pcall(function() snd2:Play() end) end)
                
                -- Xoay logo 360
                TweenService:Create(logo,
                    TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                    { Rotation = logo.Rotation + 360 }
                ):Play()
                
                -- Xoay ring ngược chiều
                TweenService:Create(ring,
                    TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                    { Rotation = ring.Rotation - 360 }
                ):Play()
                
                -- Pulse pillow
                local pulse1 = TweenService:Create(Pillow_1,
                    TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    { Size = UDim2.new(0, 44, 0, 44) }
                )
                pulse1:Play()
                pulse1.Completed:Connect(function()
                    TweenService:Create(Pillow_1,
                        TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                        { Size = UDim2.new(0, 50, 0, 50) }
                    ):Play()
                end)
                
                -- Glow flash stroke
                TweenService:Create(pStroke, TweenInfo.new(0.15), { Thickness = 4, Transparency = 0 }):Play()
                task.delay(0.15, function()
                    TweenService:Create(pStroke, TweenInfo.new(0.4), { Thickness = 2, Transparency = 0.2 }):Play()
                end)
                
                -- Toggle menu visibility
                Background_1.Visible = not Background_1.Visible
                
                task.delay(0.6, function() isAnim = false end)
            end
            
            Pillow_1.MouseButton1Click:Connect(toggleMenu)
            
            -- Spinner ring idle (xoay liên tục nhẹ)
            task.spawn(function()
                while ring and ring.Parent do
                    TweenService:Create(ring,
                        TweenInfo.new(8, Enum.EasingStyle.Linear),
                        { Rotation = ring.Rotation + 360 }
                    ):Play()
                    task.wait(8)
                end
            end)
            
            UserInputService.InputBegan:Connect(function(Input, Processed)
                if Processed then return end
                if Input.KeyCode == Enum.KeyCode.LeftControl then toggleMenu() end
            end)
        end

        do
            local WindowSize = 1.45
            local Scaler = Library:Create("UIScale", { Parent = Xova, Scale = if Mobile then 1 else WindowSize })
            function Library:SetTimeValue(Value) THETIME.Text = Value end
        end

        Return_Button.MouseButton1Click:Connect(OnReturn)
    end

    return Window
end

return Library
