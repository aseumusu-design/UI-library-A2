-- NovaUI_Bubble.lua
-- Floating draggable bubble/logo controller.
-- Usage:
-- local Bubble = require(...) or loadstring(...)
-- Bubble.new({Icon="Home", Text="NovaUI", Callback=function(window) ... end})

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Bubble = {}
Bubble.__index = Bubble

local ICONS = {
    Home="⌂", Settings="⚙", Search="⌕", Info="ⓘ", Close="×",
    Cross="✕", Cross2="✖", Skull="☠", Shield="🛡", Teleport="✦",
    Shoe="♢", Save="▣", Discord="◈", Menu="☰", Star="★", Target="◎",
    Game="◆", Code="</>", Palette="◈", Users="♟", Server="▥",
    Globe="◎", Flash="ϟ", Fire="♨", Crown="♛", Sword="⚔",
}

function Bubble.new(config)
    config=config or {}
    local self=setmetatable({},Bubble)
    local player=Players.LocalPlayer
    local gui=Instance.new("ScreenGui")
    gui.Name=config.Name or "NovaUI_Bubble"
    gui.ResetOnSpawn=false
    gui.Parent=config.Parent or player:WaitForChild("PlayerGui")

    local button=Instance.new("TextButton")
    button.Size=UDim2.fromOffset(config.Size or 58,config.Size or 58)
    button.Position=config.Position or UDim2.new(1,-80,0.5,-29)
    button.BackgroundColor3=config.Color or Color3.fromRGB(116,92,255)
    button.Text=ICONS[config.Icon] or config.Icon or "N"
    button.TextColor3=Color3.new(1,1,1)
    button.TextSize=config.TextSize or 25
    button.Font=Enum.Font.GothamBold
    button.AutoButtonColor=false
    button.Parent=gui

    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(1,0); c.Parent=button
    local s=Instance.new("UIStroke"); s.Color=Color3.new(1,1,1); s.Transparency=.75; s.Parent=button

    local dragging=false
    local startPos,startInput
    button.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true; startInput=input.Position; startPos=button.Position
            input.Changed:Connect(function()
                if input.UserInputState==Enum.UserInputState.End then dragging=false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
            local d=input.Position-startInput
            button.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
        end
    end)

    button.MouseEnter:Connect(function()
        TweenService:Create(button,TweenInfo.new(.15),{Size=UDim2.fromOffset((config.Size or 58)+5,(config.Size or 58)+5)}):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button,TweenInfo.new(.15),{Size=UDim2.fromOffset(config.Size or 58,config.Size or 58)}):Play()
    end)
    button.Activated:Connect(function()
        if config.Callback then
            local ok,err=pcall(config.Callback,self)
            if not ok then warn("[NovaUI Bubble]:",err) end
        end
    end)

    self.Gui=gui
    self.Button=button
    return self
end

function Bubble:SetIcon(icon)
    self.Button.Text=ICONS[icon] or icon or "N"
end

function Bubble:Destroy()
    self.Gui:Destroy()
end

return Bubble
