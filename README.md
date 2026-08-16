# NovaUI Full Lua Pack

Isi ZIP:
- `NovaUI_Full.lua` — library UI single-file.
- `NovaUI_Bubble.lua` — bubble/logo floating button.
- `NovaUI_Icons.lua` — searchable icon registry.

## Contoh

```lua
local NovaUI = require(game.ReplicatedStorage.NovaUI_Full)
local ui = NovaUI:CreateWindow({Title="My Menu"})

ui:AddButton({Text="Discord", Icon="Discord"})
ui:AddToggle({Text="Enabled", Default=true})
ui:AddSlider({Text="Power", Min=0, Max=100, Value=50})
ui:AddTextbox({Placeholder="Search..."})
ui:AddDropdown({Text="Mode", Options={"A","B","C"}})
ui:Notify({Text="Loaded!", Type="Success", Icon="Check"})
```

Untuk GitHub, jadikan masing-masing `.lua` sebagai file terpisah. Jika memakai
`loadstring`, gunakan hanya pada environment/project yang memang kamu kontrol
dan patuhi aturan platform Roblox.

Catatan: beberapa emoji/simbol dapat tampil berbeda tergantung font/device.
`NovaUI_Icons.lua` sengaja dibuat sebagai registry ringan agar nanti mudah
diganti ke asset image Roblox milik developer.
