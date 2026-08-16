-- NovaUI_Icons.lua
-- Searchable icon registry. Use Icons.Get("Discord"), Icons.Search("tele").
local Icons = {}

Icons.List = {
    Home="⌂", Settings="⚙", Search="⌕", Info="ⓘ", Close="×",
    Cross="✕", Cross2="✖", Skull="☠", Shield="🛡", Teleport="✦",
    Shoe="♢", Save="▣", Discord="◈", Menu="☰", More="⋮",
    Play="▶", Pause="Ⅱ", Stop="■", Edit="✎", Trash="♲", Copy="▣",
    Paste="▤", Cloud="☁", Key="⚿", Eye="◉", EyeOff="⊘", Users="♟",
    Server="▥", Globe="◎", Link="↗", Refresh="↻", Download="↓",
    Upload="↑", Bell="♢", Star="★", Heart="♥", Folder="□",
    Code="</>", Game="◆", Target="◎", Palette="◈", Monitor="▣",
    Mobile="▤", Keyboard="⌨", Lock="◆", Unlock="◇", Warning="!",
    Success="✓", Error="×", Bug="♧", Terminal=">_", Gamepad="⌘",
    Camera="◉", Mic="♩", Volume="◖", Mute="◗", Speed="⌁", Flash="ϟ",
    Fire="♨", Crown="♛", Sword="⚔", Crosshair="⊙", Pin="⌖",
    Map="▦", Backpack="▣", Shop="$", Gift="◇", Favorite="★",
}

function Icons.Get(name)
    return Icons.List[name]
end

function Icons.Search(query)
    query=string.lower(tostring(query or ""))
    local result={}
    for name,icon in pairs(Icons.List) do
        if string.find(string.lower(name),query,1,true) then
            table.insert(result,{Name=name,Icon=icon})
        end
    end
    table.sort(result,function(a,b) return a.Name<b.Name end)
    return result
end

function Icons.Names()
    local result={}
    for name in pairs(Icons.List) do table.insert(result,name) end
    table.sort(result)
    return result
end

return Icons
