-- NovaUI Showcase (langsung tampil semua)
local ok, NovaUI = pcall(function()
    return loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/aseumusu-design/UI-library-A2/refs/heads/main/NovaUI_Full.lua"
    ))()
end)
if not ok or type(NovaUI) ~= "table" then
    warn("[NovaUI] gagal load:", NovaUI)
    return
end

local Window = NovaUI:CreateWindow({
    Title = "Nova Hub — Showcase",
    Size  = UDim2.fromOffset(640, 480),
})

-- ===== KOMPONEN =====
Window:AddLabel("Komponen")

Window:AddButton({ Text = "Tombol Biasa", Icon = "Play",
    Callback = function() print("klik!") end })

Window:AddButton({ Text = "Tombol Outline", Icon = "Shield", Style = "outline",
    Callback = function() print("outline!") end })

Window:AddToggle({ Text = "Aktifkan Fitur", Default = true,
    Callback = function(v) print("toggle:", v) end })

Window:AddSlider({ Text = "Kecepatan", Min = 16, Max = 200, Value = 50,
    Callback = function(v) print("slider:", v) end })

Window:AddTextbox({ Text = "Nama", Placeholder = "Ketik nama...",
    Callback = function(t) print("textbox:", t) end })

Window:AddDropdown({ Text = "Mode", Options = { "Easy", "Normal", "Hard" },
    Callback = function(v) print("dropdown:", v) end })

-- ===== SEMUA IKON =====
Window:AddLabel("Semua Ikon")

local names = {}
for name in pairs(Window.Icons) do names[#names + 1] = name end
table.sort(names)

for _, name in ipairs(names) do
    Window:AddButton({
        Text = name,
        Icon = name,
        Callback = function()
            setclipboard and setclipboard(name)
            print("ikon:", name, Window.Icons[name])
        end,
    })
end

print("[NovaUI] tampil,", #names, "ikon dimuat")
