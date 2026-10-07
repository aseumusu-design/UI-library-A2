
-- ============================================================================
--  A2 FUSION UI  —  VietnameseLib Theme × A2 UI Engine
--  Versi: 3.1.1-fusion
--
--  Fitur:
--   • Intro splash "A2" saat script di-execute (auto-detect environment)
--   • Deteksi executor + nama game, ditampilkan di intro & window
--   • Theme: neon ungu (#7A5CFF) + electric blue (#18C8FF) di atas hitam pekat
--   • Semua elemen: Window, Tab, Section, Toggle, Slider, Button, Input,
--     Dropdown, Paragraph, Notify, Webhook, Floating toggle, Hotkey
--   • KONFIRMASI YES/NO saat tombol X ditekan (tidak langsung hilang)
--   • Animasi buka/tutup/minimize lebih smooth (scale + easing)
--   • Ikon gambar Roblox asset ID (nama ikon atau ID custom)
--   • Anti-AFK (VirtualUser) • Config: auto-save, save/load slot, auto-load
--   • Auto-Execute on rejoin: tulis loader ke folder Autoexecute executor
--   • API publik: semua fungsi di bawah bisa dipakai orang lain
--   • Jika di-require sebagai ModuleScript → hanya return library (tanpa intro)
-- ============================================================================
local A2UI = {}
A2UI.__index = A2UI
A2UI.Version = "3.1.1-fusion"

local CoreGui           = game:GetService("CoreGui")
local Players           = game:GetService("Players")
local HttpService       = game:GetService("HttpService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer
local Mobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ═══════════════════════ THEME (dari VietnameseLib — premium neon) ═══════
local C = {
    primary   = Color3.fromRGB(122, 92, 255),   -- ungu premium
    secondary = Color3.fromRGB(24, 200, 255),   -- electric blue
    glow      = Color3.fromRGB(120, 110, 255),  -- glow aktif
    bgDeep    = Color3.fromRGB(11, 13, 18),
    bgPanel   = Color3.fromRGB(15, 17, 23),
    bgRow     = Color3.fromRGB(22, 25, 33),
    bgHover   = Color3.fromRGB(30, 36, 52),
    stroke    = Color3.fromRGB(60, 70, 95),
    text      = Color3.fromRGB(220, 225, 235),
    dim       = Color3.fromRGB(140, 150, 175),
    white     = Color3.fromRGB(245, 248, 255),
    good      = Color3.fromRGB(46, 204, 113),
    bad       = Color3.fromRGB(239, 79, 79),
    warn      = Color3.fromRGB(236, 162, 1),
}
A2UI.Theme = C

local GRADIENT_HOT = ColorSequence.new({
    ColorSequenceKeypoint.new(0, C.primary),
    ColorSequenceKeypoint.new(1, C.secondary),
})
local GRADIENT_TITLE = ColorSequence.new({
    ColorSequenceKeypoint.new(0, C.white),
    ColorSequenceKeypoint.new(0.6, C.primary),
    ColorSequenceKeypoint.new(1, C.secondary),
})
local GRADIENT_PANEL = ColorSequence.new({
    ColorSequenceKeypoint.new(0, C.bgPanel),
    ColorSequenceKeypoint.new(1, C.bgDeep),
})

-- ═══════════════════════ ENVIRONMENT DETECTION ════════════════════════════
local function detectExecutor()
    if type(identifyexecutor) == "function" then
        local ok, name = pcall(identifyexecutor)
        if ok and name and tostring(name) ~= "" then return tostring(name) end
    end
    if type(getexecutorname) == "function" then
        local ok, name = pcall(getexecutorname)
        if ok and name and tostring(name) ~= "" then return tostring(name) end
    end
    if RunService:IsStudio() then return "Roblox Studio" end
    return "Unknown Executor"
end

local function getPlaceName()
    local ok, info = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId)
    end)
    if ok and info and info.Name then return info.Name end
    return game.Name
end

local A2_ENV = {
    Executor = detectExecutor(),
    Place    = getPlaceName(),
    PlaceId  = game.PlaceId,
    User     = LocalPlayer and LocalPlayer.Name or "Player",
    Mobile   = Mobile,
}
A2UI.Env = A2_ENV

-- ═══════════════════════ GUI PARENT RESOLUTION ════════════════════════════
local function guiParent()
    local p
    pcall(function()
        if type(gethui) == "function" then p = gethui() end
    end)
    if p then return p end
    pcall(function()
        if LocalPlayer then p = LocalPlayer:WaitForChild("PlayerGui", 10) end
    end)
    if p then return p end
    pcall(function() p = CoreGui end)
    return p
end

-- ═══════════════════════ WEBHOOK HELPERS ══════════════════════════════════
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

function A2UI:SetWebhook(url)
    url = tostring(url or ""):gsub("%s+$", "")
    if url == "" then self.WebhookURL = nil; return false, "URL webhook kosong" end
    if not validWebhookUrl(url) then return false, "URL harus Discord webhook yang valid" end
    self.WebhookURL = url
    return true
end

function A2UI:Webhook(opts)
    opts = opts or {}
    local url = opts.URL or self.WebhookURL
    if not validWebhookUrl(url) then return false, "Webhook belum diatur / URL tidak valid" end

    local now = os.clock()
    if self._lastWebhook and now - self._lastWebhook < 1 then
        return false, "Tunggu sebentar sebelum kirim webhook lagi"
    end

    local req = getRequestFunction()
    if not req then return false, "Executor tidak punya fungsi HTTP request" end

    local payload = {
        username = opts.Username or "A2 FUSION",
        content = opts.Content or "A2 status update",
    }
    if opts.Embeds then payload.embeds = opts.Embeds end

    local okEncode, body = pcall(function() return HttpService:JSONEncode(payload) end)
    if not okEncode then return false, "Gagal encode payload" end

    local ok, response = pcall(function()
        return req({ Url = url, Method = "POST",
            Headers = { ["Content-Type"] = "application/json" }, Body = body })
    end)
    if not ok then return false, tostring(response) end

    self._lastWebhook = now
    local status = type(response) == "table" and (response.StatusCode or response.Status) or nil
    if status and tonumber(status) and (tonumber(status) < 200 or tonumber(status) >= 300) then
        return false, "Discord menolak (HTTP " .. tostring(status) .. ")"
    end
    return true, response
end
A2UI.SendWebhook = A2UI.Webhook


-- ═══════════════════════ ANTI-AFK ═════════════════════════════════════════
local VirtualUser = game:GetService("VirtualUser")
local antiAFKEnabled = false
if LocalPlayer then
    LocalPlayer.Idled:Connect(function()
        if antiAFKEnabled then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    end)
end

function A2UI:SetAntiAFK(enabled)
    antiAFKEnabled = enabled and true or false
    return antiAFKEnabled
end
function A2UI:IsAntiAFK() return antiAFKEnabled end

-- ═══════════════════════ CONFIG SAVE / LOAD / AUTO-SAVE ═══════════════════
-- Setiap elemen yang dibuat dengan opts.Flag otomatis ikut tersimpan.
-- File tersimpan di: A2Fusion/Configs/<nama>.json  (via writefile executor)
local CONFIG_DIR = "A2Fusion/Configs"

function A2UI:RegisterConfigElement(flag, getFn, setFn)
    if type(flag) ~= "string" or flag == "" then return end
    self._configElements = self._configElements or {}
    self._configElements[flag] = { Get = getFn, Set = setFn }
    -- Nilai config yang dimuat sebelum elemen dibuat langsung diterapkan di sini
    if self._pendingConfig and self._pendingConfig[flag] ~= nil and type(setFn) == "function" then
        local v = self._pendingConfig[flag]
        self._pendingConfig[flag] = nil
        task.defer(function() pcall(setFn, v) end)
    end
end

local function ensureDir(path)
    if type(makefolder) ~= "function" then return end
    local acc = ""
    for part in tostring(path):gmatch("[^/]+") do
        acc = (acc == "" and part) or (acc .. "/" .. part)
        pcall(function()
            if not (isfolder and isfolder(acc)) then makefolder(acc) end
        end)
    end
end
A2UI._ensureDir = ensureDir

-- Daftar nama config yang ada di A2Fusion/Configs (tanpa .json)
function A2UI:ListConfigs()
    ensureDir("A2Fusion/Configs")
    local out = {}
    if type(listfiles) ~= "function" then return out end
    local ok, files = pcall(listfiles, "A2Fusion/Configs")
    if not ok or type(files) ~= "table" then return out end
    for _, f in ipairs(files) do
        local name = tostring(f):gsub("\\", "/"):match("([^/]+)%.json$")
        if name then table.insert(out, name) end
    end
    table.sort(out)
    return out
end

function A2UI:DeleteConfig(name)
    if type(delfile) ~= "function" then return false, "Executor tidak support delfile" end
    local ok, err = pcall(delfile, "A2Fusion/Configs/" .. tostring(name) .. ".json")
    return ok, ok and ("Config '" .. tostring(name) .. "' dihapus") or tostring(err)
end

function A2UI:_autoSave()
    if self._autoSavePending then return end
    self._autoSavePending = true
    task.delay(1.2, function()
        self._autoSavePending = false
        pcall(function() self:SaveConfig("autosave") end)
    end)
end

function A2UI:SaveConfig(name)
    name = tostring(name or "default")
    if type(writefile) ~= "function" then return false, "Executor tidak support writefile" end
    self._configElements = self._configElements or {}
    local data = {}
    for flag, el in pairs(self._configElements) do
        local ok, v = pcall(el.Get)
        if ok then data[flag] = v end
    end
    ensureDir(CONFIG_DIR)
    local okE, body = pcall(function() return HttpService:JSONEncode(data) end)
    if not okE then return false, "Gagal encode config" end
    local okW, err = pcall(function() return writefile(CONFIG_DIR .. "/" .. name .. ".json", body) end)
    if not okW then return false, tostring(err) end
    return true, CONFIG_DIR .. "/" .. name .. ".json"
end

function A2UI:LoadConfig(name)
    name = tostring(name or "default")
    if type(readfile) ~= "function" then return false, "Executor tidak support readfile" end
    local okR, body = pcall(function() return readfile(CONFIG_DIR .. "/" .. name .. ".json") end)
    if not okR or type(body) ~= "string" then return false, "Config '" .. name .. "' tidak ditemukan" end
    local okD, data = pcall(function() return HttpService:JSONDecode(body) end)
    if not okD or type(data) ~= "table" then return false, "File config rusak / bukan JSON" end
    self._configElements = self._configElements or {}
    local applied, missing = 0, 0
    for flag, value in pairs(data) do
        local el = self._configElements[flag]
        if el and type(el.Set) == "function" then
            pcall(function() el.Set(value) end)
            applied = applied + 1
        else
            -- elemen belum dibuat: simpan, nanti diterapkan saat elemen muncul
            self._pendingConfig = self._pendingConfig or {}
            self._pendingConfig[flag] = value
            missing = missing + 1
        end
    end
    return true, "Applied " .. applied .. " nilai" .. (missing > 0 and (" • " .. missing .. " menunggu elemen") or "")
end

-- ═══════════════════════ AUTO-EXECUTE ON REJOIN ═══════════════════════════
-- Cara pakai:
--   1) Host loader.lua kamu (isi: loadstring ke script utama) di GitHub raw/dll
--   2) window:SetLoaderURL("https://raw.githubusercontent.com/USER/REPO/main/A2Loader.lua")
--   3) window:InstallAutoExecute()  → menulis loader ke semua folder
--      autoexecute yang umum (Autoexecute/autoexecute/AutoExec/autoexec)
--   4) Sekali install → setiap rejoin/change server UI auto load lagi
A2UI.LoaderURL = ""

function A2UI:SetLoaderURL(url)
    url = tostring(url or ""):gsub("%s+$", "")
    if url == "" or not url:match("^https?://") then return false, "URL loader tidak valid" end
    self.LoaderURL = url
    return true
end

function A2UI:InstallAutoExecute(loaderUrl)
    loaderUrl = tostring(loaderUrl or ""):gsub("%s+$", "")
    if loaderUrl == "" then loaderUrl = tostring(self.LoaderURL or ""):gsub("%s+$", "") end
    if loaderUrl == "" or not loaderUrl:match("^https?://") then
        return false, "Isi Loader URL dulu — host loader.lua kamu (misal GitHub raw), lalu paste URL-nya"
    end
    if type(writefile) ~= "function" then return false, "Executor tidak support writefile" end
    local loaderCode = "-- A2 FUSION auto-loader (jangan dihapus)\nloadstring(game:HttpGet(" .. string.format("%q", loaderUrl) .. "))()"
    local folders = { "Autoexecute", "autoexecute", "AutoExec", "autoexec" }
    local written = {}
    for _, folder in ipairs(folders) do
        pcall(function()
            if isfolder and not isfolder(folder) then makefolder(folder) end
        end)
        local okW = pcall(function()
            writefile(folder .. "/A2Fusion_Loader.lua", loaderCode)
        end)
        if okW then table.insert(written, folder .. "/A2Fusion_Loader.lua") end
    end
    if #written == 0 then return false, "Gagal menulis loader ke semua folder autoexecute" end
    return true, table.concat(written, "\n")
end

-- ═══════════════════════ FOLDER AUTO-EXEC KHUSUS UI ═══════════════════════
-- Taruh file .lua / .txt di folder workspace:  A2Fusion/AutoExec/
--   • Isi file berupa kode Lua  → langsung dijalankan
--   • Isi file berupa 1 URL     → otomatis loadstring(game:HttpGet(URL))()
--   • Isi file "loadstring(game:HttpGet(...))()" juga bisa
-- Semua file dijalankan berurutan (A-Z) begitu UI terbuka.
-- Matikan dengan toggle "Auto Execute" (disimpan di A2Fusion/autoexec_enabled.txt)
A2UI.AutoExecDir = "A2Fusion/AutoExec"

function A2UI:IsAutoExecEnabled()
    if type(readfile) ~= "function" then return true end
    local ok, v = pcall(readfile, "A2Fusion/autoexec_enabled.txt")
    if not ok or type(v) ~= "string" then return true end
    return not v:match("^%s*0")
end

function A2UI:SetAutoExecEnabled(on)
    ensureDir("A2Fusion")
    if type(writefile) == "function" then
        pcall(writefile, "A2Fusion/autoexec_enabled.txt", on and "1" or "0")
    end
end

function A2UI:RunAutoExecFolder()
    local dir = self.AutoExecDir
    ensureDir(dir)
    if type(listfiles) ~= "function" or type(readfile) ~= "function" then
        return false, "Executor tidak support listfiles/readfile"
    end
    local ok, files = pcall(listfiles, dir)
    if not ok or type(files) ~= "table" then return false, "Folder " .. dir .. " tidak bisa dibaca" end
    table.sort(files)
    local ran, failed = 0, {}
    local compile = loadstring or load
    for _, path in ipairs(files) do
        local p = tostring(path):gsub("\\", "/")
        local fname = p:match("([^/]+)$") or p
        if fname:lower():match("%.lua$") or fname:lower():match("%.txt$") or fname:lower():match("%.luau$") then
            local okR, src = pcall(readfile, path)
            if okR and type(src) == "string" then
                src = src:gsub("^\239\187\191", "") -- buang BOM
                local trimmed = src:match("^%s*(.-)%s*$")
                if trimmed:match("^https?://%S+$") then
                    local okH, body = pcall(function() return game:HttpGet(trimmed) end)
                    src = okH and body or nil
                end
                if src and trimmed ~= "" then
                    local fn, cerr = compile(src, "=" .. fname)
                    if fn then
                        ran = ran + 1
                        task.spawn(function()
                            local okX, xerr = pcall(fn)
                            if not okX then warn("[A2 AutoExec] " .. fname .. ": " .. tostring(xerr)) end
                        end)
                    else
                        table.insert(failed, fname)
                        warn("[A2 AutoExec] compile " .. fname .. ": " .. tostring(cerr))
                    end
                else
                    table.insert(failed, fname)
                end
            end
        end
    end
    local msg = ran .. " file dijalankan dari " .. dir
    if #failed > 0 then msg = msg .. " • gagal: " .. table.concat(failed, ", ") end
    return true, msg, ran
end

-- ═══════════════════════ INSTANCE HELPERS ═════════════════════════════════
local function mk(class, props)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then o[k] = v end
    end
    if props and props.Parent then o.Parent = props.Parent end
    return o
end

local function corner(parent, r) return mk("UICorner", { CornerRadius = UDim.new(0, r or 8), Parent = parent }) end

local function stroke(parent, color, thick, trans, grad)
    local s = mk("UIStroke", {
        Color = color or C.stroke, Thickness = thick or 1,
        Transparency = trans or 0.5, Parent = parent,
    })
    if grad then
        mk("UIGradient", { Color = GRADIENT_HOT, Rotation = 45, Parent = s })
    end
    return s
end

local function pad(parent, t, r, b, l)
    return mk("UIPadding", {
        PaddingTop = UDim.new(0, t or 0), PaddingRight = UDim.new(0, r or 0),
        PaddingBottom = UDim.new(0, b or 0), PaddingLeft = UDim.new(0, l or 0), Parent = parent,
    })
end

local function textGlow(label, color, strength)
    if not label then return end
    label.TextStrokeColor3 = color or C.primary
    label.TextStrokeTransparency = strength or 0.7
end

-- Efek shine (cahaya menyapu teks) — signature Vietnamese premium
local function shineText(label, color)
    if not label then return end
    local base = color or C.text
    local shine = mk("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, base),
            ColorSequenceKeypoint.new(0.42, base),
            ColorSequenceKeypoint.new(0.50, C.white),
            ColorSequenceKeypoint.new(0.58, base),
            ColorSequenceKeypoint.new(1, base),
        }),
        Offset = Vector2.new(-1, 0), Rotation = 18, Parent = label,
    })
    local tween
    local function sweep()
        if not shine.Parent then return end
        shine.Offset = Vector2.new(-1, 0)
        tween = TweenService:Create(shine, TweenInfo.new(2.2, Enum.EasingStyle.Sine), { Offset = Vector2.new(1, 0) })
        tween.Completed:Connect(function()
            if shine.Parent then task.delay(1.2, sweep) end
        end)
        tween:Play()
    end
    sweep()
    return shine
end

-- Lucide sprite assets, from SiriusSoftwareLtd/Rayfield icons.lua (48px).
-- Each entry: Roblox image ID, crop size, crop offset. No HTTP dependency.
local ICON_ASSETS = {
    home = { 16898613509, Vector2.new(48, 48), Vector2.new(820, 147) },
    settings = { 16898613777, Vector2.new(48, 48), Vector2.new(771, 257) },
    link = { 16898613509, Vector2.new(48, 48), Vector2.new(918, 453) },
    rocket = { 16898613699, Vector2.new(48, 48), Vector2.new(918, 147) },
    package = { 16898613613, Vector2.new(48, 48), Vector2.new(918, 196) },
    send = { 16898613699, Vector2.new(48, 48), Vector2.new(967, 857) },
    check = { 16898612819, Vector2.new(48, 48), Vector2.new(710, 869) },
    save = { 16898613699, Vector2.new(48, 48), Vector2.new(918, 453) },
    pin = { 16898613699, Vector2.new(48, 48), Vector2.new(918, 0) },
    download = { 16898613044, Vector2.new(48, 48), Vector2.new(820, 906) },
    trash = { 16898613869, Vector2.new(48, 48), Vector2.new(918, 514) },
    refresh = { 16898613699, Vector2.new(48, 48), Vector2.new(404, 869) },
    clipboard = { 16898613044, Vector2.new(48, 48), Vector2.new(49, 869) },
    play = { 16898613699, Vector2.new(48, 48), Vector2.new(918, 257) },
    pause = { 16898613699, Vector2.new(48, 48), Vector2.new(0, 771) },
    info = { 16898613509, Vector2.new(48, 48), Vector2.new(612, 869) },
    hourglass = { 16898613509, Vector2.new(48, 48), Vector2.new(49, 918) },
    star = { 16898613777, Vector2.new(48, 48), Vector2.new(967, 147) },
    bolt = { 16898612819, Vector2.new(48, 48), Vector2.new(306, 820) },
    shield = { 16898613777, Vector2.new(48, 48), Vector2.new(869, 0) },
    user = { 16898613869, Vector2.new(48, 48), Vector2.new(661, 869) },
    farm = { 16898612629, Vector2.new(48, 48), Vector2.new(869, 710) },
    survival = { 16898613509, Vector2.new(48, 48), Vector2.new(661, 771) },
    combat = { 16898613777, Vector2.new(48, 48), Vector2.new(967, 759) },
    player = { 16898613869, Vector2.new(48, 48), Vector2.new(661, 869) },
    power = { 16898613699, Vector2.new(48, 48), Vector2.new(820, 147) },
    key = { 16898613509, Vector2.new(48, 48), Vector2.new(869, 404) },
    mail = { 16898613613, Vector2.new(48, 48), Vector2.new(820, 0) },
    menu = { 16898613613, Vector2.new(48, 48), Vector2.new(49, 820) },
    warning = { 16898612629, Vector2.new(48, 48), Vector2.new(771, 98) },
    target = { 16898613044, Vector2.new(48, 48), Vector2.new(453, 869) },
    coins = { 16898613044, Vector2.new(48, 48), Vector2.new(869, 612) },
    heart = { 16898613509, Vector2.new(48, 48), Vector2.new(661, 771) },
    sword = { 16898613777, Vector2.new(48, 48), Vector2.new(710, 967) },
    close = { 16898613869, Vector2.new(48, 48), Vector2.new(869, 906) },
    minimize = { 16898613613, Vector2.new(48, 48), Vector2.new(771, 196) },
}
A2UI.Icons = ICON_ASSETS

local function assetUri(value)
    if type(value) == "number" and value > 0 and value < math.huge then
        return "rbxassetid://" .. string.format("%.0f", math.floor(value))
    end
    if type(value) ~= "string" then return nil end
    value = value:match("^%s*(.-)%s*$")
    if value:match("^rbxassetid://%d+$") then return value end
    if value:match("^%d+$") then return "rbxassetid://" .. value end
    local id = value:match("^https?://www%.roblox%.com/asset/%?id=(%d+)")
    if id then return "rbxassetid://" .. id end
    return nil
end

function A2UI:SetIcon(name, id)
    local uri = assetUri(id)
    if type(name) ~= "string" or not uri then return false, "Nama / asset ID ikon tidak valid" end
    ICON_ASSETS[name:lower()] = { uri }
    return true
end

local function makeIcon(parent, value, props)
    props = props or {}
    local named = type(value) == "string" and ICON_ASSETS[value:lower()] or nil
    local uri = assetUri(value)
    if not uri then
        if not named then
            if value ~= nil then warn("[A2 UI] Ikon tidak dikenal: " .. tostring(value) .. "; memakai info") end
            named = ICON_ASSETS.info
        end
        uri = assetUri(named[1])
    end
    local image = mk("ImageLabel", {
        Size = props.Size or UDim2.new(0, 22, 0, 22),
        Position = props.Position or UDim2.new(0, 0, 0, 0),
        AnchorPoint = props.AnchorPoint,
        BackgroundTransparency = 1, Image = uri,
        ImageColor3 = props.Color or C.dim,
        ImageTransparency = props.Transparency or 0,
        ImageRectSize = named and named[2] or Vector2.new(0, 0),
        ImageRectOffset = named and named[3] or Vector2.new(0, 0),
        ScaleType = Enum.ScaleType.Fit, Parent = parent,
    })
    return image, true
end

-- GuiObjects must be inside a ScreenGui, not directly under PlayerGui/CoreGui.
local function overlayGui(parent)
    local gui = parent:FindFirstChild("A2Overlays")
    if not gui or not gui:IsA("ScreenGui") then
        if gui then gui:Destroy() end
        gui = mk("ScreenGui", {
            Name = "A2Overlays", ResetOnSpawn = false, IgnoreGuiInset = true,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 10000,
            Parent = parent,
        })
    end
    return gui
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

-- Global drag manager
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


-- ═══════════════════════ CONFIRM DIALOG (YES / NO) ════════════════════════
-- A2UI:Confirm({ Title, Content, YesText, NoText, Callback = function(yes) end })
function A2UI:Confirm(opts)
    opts = opts or {}
    local parent = guiParent()
    if not parent then return end
    parent = overlayGui(parent)
    local old = parent:FindFirstChild("A2Confirm")
    if old then old:Destroy() end

    local overlay = mk("Frame", {
        Name = "A2Confirm", Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(5, 6, 10), BackgroundTransparency = 0.45,
        BorderSizePixel = 0, ZIndex = 9000, Parent = parent,
    })
    TweenService:Create(overlay, TweenInfo.new(0.18), { BackgroundTransparency = 0.35 }):Play()

    local dismiss = mk("TextButton", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
        Text = "", ZIndex = 9000, Parent = overlay,
    })

    local card = mk("Frame", {
        Size = UDim2.new(0, 330, 0, 160), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 26), BackgroundColor3 = C.bgPanel,
        BorderSizePixel = 0, ZIndex = 9001, Parent = overlay,
    })
    corner(card, 14)
    stroke(card, C.glow, 1.5, 0.3)
    mk("UIGradient", { Color = GRADIENT_PANEL, Rotation = 135, Parent = card })

    local iconLbl = mk("TextLabel", {
        Size = UDim2.new(0, 34, 0, 34), Position = UDim2.new(0, 16, 0, 14),
        BackgroundColor3 = C.bgRow, BorderSizePixel = 0, Text = "",
        Font = Enum.Font.GothamBlack, TextSize = 18, TextColor3 = C.warn, Parent = card,
    })
    makeIcon(iconLbl, "warning", { Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(0, 6, 0, 6), Color = C.warn })
    corner(iconLbl, 10)
    stroke(iconLbl, C.warn, 1, 0.4)

    local title = mk("TextLabel", {
        Size = UDim2.new(1, -70, 0, 20), Position = UDim2.new(0, 60, 0, 19),
        BackgroundTransparency = 1, Text = opts.Title or "Konfirmasi",
        Font = Enum.Font.GothamBlack, TextSize = 15, TextColor3 = C.white,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = card,
    })
    mk("UIGradient", { Color = GRADIENT_TITLE, Rotation = 90, Parent = title })
    textGlow(title, C.primary, 0.7)

    mk("TextLabel", {
        Size = UDim2.new(1, -32, 0, 46), Position = UDim2.new(0, 16, 0, 56),
        BackgroundTransparency = 1, Text = opts.Content or "",
        Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.dim,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true, Parent = card,
    })

    local closed = false
    local finish
    local function mkBtn(x, w, text, col, result)
        local b = mk("TextButton", {
            Size = UDim2.new(0, w, 0, 34), Position = UDim2.new(1, x, 1, -46),
            BackgroundColor3 = col, BackgroundTransparency = 0.82, BorderSizePixel = 0,
            Text = text, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.white,
            AutoButtonColor = false, ZIndex = 9002, Parent = card,
        })
        corner(b, 9)
        stroke(b, col, 1, 0.35)
        b.MouseEnter:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.12), { BackgroundTransparency = 0.6 }):Play()
        end)
        b.MouseLeave:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.12), { BackgroundTransparency = 0.82 }):Play()
        end)
        b.MouseButton1Click:Connect(function() finish(result) end)
        return b
    end

    finish = function(result)
        if closed then return end
        closed = true
        TweenService:Create(card, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, 0, 0.5, 14),
        }):Play()
        for _, d in ipairs(card:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextButton") then
                TweenService:Create(d, TweenInfo.new(0.15), { TextTransparency = 1 }):Play()
            elseif d:IsA("Frame") then
                pcall(function()
                    TweenService:Create(d, TweenInfo.new(0.15), { BackgroundTransparency = 1 }):Play()
                end)
            end
        end
        TweenService:Create(overlay, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
        task.delay(0.22, function() pcall(function() overlay:Destroy() end) end)
        if opts.Callback then task.spawn(function() opts.Callback(result) end) end
    end

    dismiss.MouseButton1Click:Connect(function() finish(false) end)

    mkBtn(-146, 130, opts.YesText or "Ya, Tutup", C.bad, true)
    mkBtn(-246, 90, opts.NoText or "Batal", Color3.fromRGB(52, 58, 78), false)

    TweenService:Create(card, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, 0.5, 0),
    }):Play()
end

-- ═══════════════════════ INTRO SPLASH "A2" ════════════════════════════════
local function PlayIntro(parent, done)
    local intro = mk("ScreenGui", {
        Name = "A2Intro", IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 100000,
        Parent = parent,
    })

    -- background hitam pekat + vignette gradient ala Vietnamese
    local bg = mk("Frame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = C.bgDeep,
        BorderSizePixel = 0, Parent = intro,
    })
    mk("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, C.bgDeep),
            ColorSequenceKeypoint.new(0.55, Color3.fromRGB(14, 15, 26)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 20, 48)),
        }),
        Rotation = 125, Parent = bg,
    })

    -- glow orbs ambient
    for i, pos in ipairs({
        UDim2.new(0.18, 0, 0.25, 0), UDim2.new(0.82, 0, 0.75, 0), UDim2.new(0.5, 0, 0.95, 0),
    }) do
        local orb = mk("Frame", {
            Size = UDim2.new(0, 340, 0, 340), AnchorPoint = Vector2.new(0.5, 0.5),
            Position = pos, BackgroundColor3 = (i == 2) and C.secondary or C.primary,
            BackgroundTransparency = 0.86, BorderSizePixel = 0, Parent = bg,
        })
        corner(orb, 999)
        local t = TweenService:Create(orb, TweenInfo.new(6 + i, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Position = pos + UDim2.new(0, (i % 2 == 0) and 60 or -60, 0, (i % 2 == 0) and -40 or 40),
        })
        t.Completed:Connect(function() end)
        t:Play()
    end

    local center = mk("Frame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = intro,
    })
    local cl = mk("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 14),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center, Parent = center,
    })

    -- Logo badge
    local badge = mk("Frame", {
        Size = UDim2.new(0, 92, 0, 92), BackgroundColor3 = C.bgPanel,
        BackgroundTransparency = 1, BorderSizePixel = 0,
        LayoutOrder = 1, Parent = center,
    })
    corner(badge, 26)
    stroke(badge, C.glow, 2, 0.1, true)
    local badgeText = mk("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "A2",
        Font = Enum.Font.GothamBlack, TextSize = 44, TextColor3 = C.white, Parent = badge,
    })
    textGlow(badgeText, C.primary, 0.35)
    mk("UIGradient", { Color = GRADIENT_TITLE, Rotation = 90, Parent = badgeText })
    badge.Size = UDim2.new(0, 0, 0, 0)

    -- Judul
    local title = mk("TextLabel", {
        Size = UDim2.new(0, 500, 0, 40), BackgroundTransparency = 1, Text = "A2 FUSION",
        Font = Enum.Font.GothamBlack, TextSize = 38, TextColor3 = C.white,
        TextStrokeTransparency = 0.6, LayoutOrder = 2, Parent = center,
    })
    mk("UIGradient", { Color = GRADIENT_TITLE, Rotation = 90, Parent = title })
    textGlow(title, C.primary, 0.55)
    title.TextTransparency = 1
    shineText(title, C.white)

    -- Subtitle: environment detection
    local sub = mk("TextLabel", {
        Size = UDim2.new(0, 600, 0, 16), BackgroundTransparency = 1,
        Text = "EXECUTOR: " .. string.upper(A2_ENV.Executor) .. "   •   PLACE: " .. string.upper(A2_ENV.Place),
        Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = C.dim,
        LayoutOrder = 3, Parent = center,
    })
    sub.TextTransparency = 1

    local sub2 = mk("TextLabel", {
        Size = UDim2.new(0, 600, 0, 14), BackgroundTransparency = 1,
        Text = "USER: " .. A2_ENV.User .. "   •   PLACE ID: " .. tostring(A2_ENV.PlaceId),
        Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.dim,
        TextTransparency = 1, LayoutOrder = 4, Parent = center,
    })

    -- Loading bar
    local barHolder = mk("Frame", {
        Size = UDim2.new(0, 260, 0, 6), BackgroundColor3 = C.bgRow,
        BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = 5, Parent = center,
    })
    corner(barHolder, 3)
    stroke(barHolder, C.stroke, 1, 0.5)
    local barFill = mk("Frame", {
        Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = C.primary,
        BorderSizePixel = 0, Parent = barHolder,
    })
    corner(barFill, 3)
    mk("UIGradient", { Color = GRADIENT_HOT, Rotation = 0, Parent = barFill })

    local status = mk("TextLabel", {
        Size = UDim2.new(0, 400, 0, 13), BackgroundTransparency = 1,
        Text = "INITIALIZING...", Font = Enum.Font.GothamMedium, TextSize = 10,
        TextColor3 = C.primary, TextTransparency = 1, LayoutOrder = 6, Parent = center,
    })
    textGlow(status, C.primary, 0.6)

    -- ══ Animasi urutan ══
    local STEPS = { "LOADING ENVIRONMENT...", "INJECTING UI ENGINE...", "BUILDING INTERFACE...", "READY" }

    local function seq()
        -- badge pop
        TweenService:Create(badge, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 92, 0, 92), BackgroundTransparency = 0,
        }):Play()
        task.wait(0.35)
        TweenService:Create(title, TweenInfo.new(0.5), { TextTransparency = 0 }):Play()
        task.wait(0.2)
        TweenService:Create(sub, TweenInfo.new(0.45), { TextTransparency = 0 }):Play()
        TweenService:Create(sub2, TweenInfo.new(0.45), { TextTransparency = 0 }):Play()
        TweenService:Create(barHolder, TweenInfo.new(0.3), { BackgroundTransparency = 0 }):Play()
        TweenService:Create(status, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()

        for i, step in ipairs(STEPS) do
            status.Text = step
            local a = i / #STEPS
            TweenService:Create(barFill, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {
                Size = UDim2.new(a, 0, 1, 0),
            }):Play()
            task.wait(0.45)
        end

        -- Flash "READY" lalu tutup
        TweenService:Create(badge, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()
        TweenService:Create(badge, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {
            Size = UDim2.new(0, 110, 0, 110),
        }):Play()
        task.wait(0.35)

        -- fade out intro
        local fade = TweenService:Create(bg, TweenInfo.new(0.5), { BackgroundTransparency = 1 })
        fade:Play()
        for _, d in ipairs(intro:GetDescendants()) do
            if d:IsA("TextLabel") then
                TweenService:Create(d, TweenInfo.new(0.45), { TextTransparency = 1 }):Play()
            elseif d:IsA("Frame") or d:IsA("ImageLabel") then
                pcall(function()
                    TweenService:Create(d, TweenInfo.new(0.45), { BackgroundTransparency = 1 }):Play()
                end)
            end
        end
        task.wait(0.55)
        pcall(function() intro:Destroy() end)
        if done then task.spawn(done) end
    end

    task.spawn(seq)
end

-- ═══════════════════════ NOTIFICATION ═════════════════════════════════════
local notifHolder
function A2UI:Notify(opts)
    opts = opts or {}
    local parent = guiParent()
    if not parent then return end
    parent = overlayGui(parent)
    if not notifHolder or not notifHolder.Parent then
        notifHolder = mk("Frame", {
            Name = "A2Notifs", Size = UDim2.new(0, 310, 1, -20),
            Position = UDim2.new(1, -322, 0, 10), BackgroundTransparency = 1,
            ZIndex = 5000, Parent = parent,
        })
        vlist(notifHolder, 8, Enum.HorizontalAlignment.Right)
    end

    local accentColor = (opts.Color and C[opts.Color:lower()]) or C.primary

    local card = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = C.bgRow, BorderSizePixel = 0,
        LayoutOrder = -os.clock(), ZIndex = 5001, Parent = notifHolder,
    })
    corner(card, 10)
    stroke(card, C.glow, 1, 0.4)

    local bar = mk("Frame", {
        Size = UDim2.new(0, 3, 1, -14), Position = UDim2.new(0, 0, 0, 7),
        BackgroundColor3 = accentColor, BorderSizePixel = 0, Parent = card,
    })
    corner(bar, 2)

    local holder = mk("Frame", {
        Size = UDim2.new(1, -18, 0, 0), Position = UDim2.new(0, 12, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = card,
    })
    vlist(holder, 2)
    pad(holder, 10, 8, 10, 0)

    local t = mk("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1,
        Text = opts.Title or "A2", Font = Enum.Font.GothamBold, TextSize = 13,
        TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y, Parent = holder,
    })
    textGlow(t, accentColor, 0.75)
    if opts.Content then
        mk("TextLabel", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1, Text = opts.Content, Font = Enum.Font.Gotham,
            TextSize = 11, TextColor3 = C.dim, TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true, Parent = holder,
        })
    end

    card.Position = UDim2.new(1, 50, 0, 0)
    TweenService:Create(card, TweenInfo.new(0.28, Enum.EasingStyle.Quint), { Position = UDim2.new(0, 0, 0, 0) }):Play()

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

-- ═══════════════════════ CREATE WINDOW ════════════════════════════════════
function A2UI:CreateWindow(opts)
    opts = opts or {}
    local self = setmetatable({}, A2UI)
    self.Tabs = {}
    self._tabCount = 0
    self._visible = true
    self._configElements = {}
    self.LoaderURL = A2UI.LoaderURL

    local parent = guiParent()
    if not parent then error("[A2 UI] Parent GUI tidak ditemukan") end

    pcall(function()
        local old = parent:FindFirstChild("A2FusionUI")
        if old then old:Destroy() end
        local oldIntro = parent:FindFirstChild("A2Intro")
        if oldIntro then oldIntro:Destroy() end
    end)

    local gui = mk("ScreenGui", {
        Name = "A2FusionUI", ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 9999, Enabled = true,
    })
    pcall(function() gui.Parent = parent end)
    if not gui.Parent then
        pcall(function() gui.Parent = LocalPlayer:WaitForChild("PlayerGui", 10) end)
    end
    if not gui.Parent then error("[A2 UI] ScreenGui gagal dipasang") end
    self.Gui = gui

    local main = mk("Frame", {
        Name = "A2Main", Size = UDim2.new(0, 660, 0, 450),
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, -30),
        BackgroundColor3 = C.bgPanel, ClipsDescendants = true, BorderSizePixel = 0,
        Visible = false, Parent = gui,
    })
    corner(main, 16)
    stroke(main, C.glow, 1.5, 0.35)          -- glow ungu Vietnamese
    mk("UIGradient", { Color = GRADIENT_PANEL, Rotation = 135, Parent = main })
    self.Main = main

    -- Shadow glow
    mk("ImageLabel", {
        Name = "Shadow", AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 160, 1, 160), ZIndex = 0,
        Image = "rbxassetid://8992230677", ImageColor3 = C.glow,
        ImageTransparency = 0.75, ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(99, 99, 99, 99), Parent = main,
    })

    -- Entrance animation awal
    main.Position = UDim2.new(0.5, 0, 0.5, 20)
    main.Size = UDim2.new(0, 0, 0, 0)
    main.BackgroundTransparency = 1

    -- UIScale responsive
    local scale = mk("UIScale", { Parent = main })
    local function fit()
        local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
        local s = 0.82 * math.min(1, (vp.X - 30) / 660, (vp.Y - 30) / 450)
        if s < 0.45 then s = 0.45 end
        if Mobile then s = math.min(s, 0.72) end
        self._fitScale = s
        scale.Scale = s
    end
    fit()
    pcall(function()
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
    end)

    -- ── TOPBAR ──
    local top = mk("Frame", {
        Name = "Top", Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = C.bgDeep,
        BackgroundTransparency = 0.35, BorderSizePixel = 0, Parent = main,
    })
    corner(top, 16)
    mk("Frame", { Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 0, 1, -16),
        BackgroundColor3 = C.bgDeep, BackgroundTransparency = 0.35, BorderSizePixel = 0, Parent = top })
    draggable(main, top)

    -- divider gradient di bawah header (khas Vietnamese)
    local divider = mk("Frame", {
        Size = UDim2.new(1, -28, 0, 1), Position = UDim2.new(0, 14, 1, -1),
        BackgroundColor3 = C.primary, BorderSizePixel = 0, Parent = top,
    })
    mk("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Parent = divider,
    })

    local logo = mk("Frame", {
        Size = UDim2.new(0, 32, 0, 32), Position = UDim2.new(0, 14, 0.5, -16),
        BackgroundColor3 = C.bgRow, BorderSizePixel = 0, Parent = top,
    })
    corner(logo, 10)
    stroke(logo, C.primary, 1.5, 0.2, true)
    local logoText = mk("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "A2",
        Font = Enum.Font.GothamBlack, TextSize = 16, TextColor3 = C.white, Parent = logo,
    })
    mk("UIGradient", { Color = GRADIENT_TITLE, Rotation = 90, Parent = logoText })
    textGlow(logoText, C.primary, 0.5)

    local titleText = mk("TextLabel", {
        Size = UDim2.new(0, 300, 0, 20), Position = UDim2.new(0, 56, 0, 8),
        BackgroundTransparency = 1, Text = opts.Title or "A2 FUSION",
        Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = C.white,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = top,
    })
    mk("UIGradient", { Color = GRADIENT_TITLE, Rotation = 90, Parent = titleText })
    textGlow(titleText, C.primary, 0.75)
    if opts.Shine ~= false then shineText(titleText, C.white) end

    mk("TextLabel", {
        Size = UDim2.new(0, 300, 0, 14), Position = UDim2.new(0, 56, 0, 27),
        BackgroundTransparency = 1, Text = opts.Author or ("by " .. A2_ENV.User),
        Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.dim,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = top,
    })

    -- status pill (executor detect)
    local status = mk("Frame", {
        Size = UDim2.new(0, 0, 0, 22), AutomaticSize = Enum.AutomaticSize.X,
        Position = UDim2.new(1, -196, 0.5, -11),
        BackgroundColor3 = C.bgRow, BorderSizePixel = 0, Parent = top,
    })
    corner(status, 7)
    stroke(status, C.stroke, 1, 0.5)
    local dot = mk("Frame", {
        Size = UDim2.new(0, 6, 0, 6), Position = UDim2.new(0, 9, 0.5, -3),
        BackgroundColor3 = C.good, BorderSizePixel = 0, Parent = status,
    })
    corner(dot, 3)
    local statusText = mk("TextLabel", {
        Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
        Position = UDim2.new(0, 21, 0, 0),
        BackgroundTransparency = 1, Text = string.upper(opts.Status or A2_ENV.Executor) .. "  ",
        Font = Enum.Font.GothamBold, TextSize = 9, TextColor3 = C.good,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = status,
    })
    textGlow(statusText, C.good, 0.6)

    local function winBtn(x, iconName, col, cb)
        local b = mk("TextButton", {
            Size = UDim2.new(0, 26, 0, 26), Position = UDim2.new(1, x, 0.5, -13),
            BackgroundColor3 = C.bgRow, BorderSizePixel = 0, Text = "",
            Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = col or C.dim,
            AutoButtonColor = false, Parent = top,
        })
        makeIcon(b, iconName, { Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(0, 5, 0, 5), Color = col or C.dim })
        corner(b, 8)
        b.MouseEnter:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = C.bgHover }):Play()
        end)
        b.MouseLeave:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = C.bgRow }):Play()
        end)
        b.MouseButton1Click:Connect(cb)
        return b
    end
    winBtn(-70, "minimize", C.dim, function() self:Minimize() end)
    winBtn(-38, "close", C.bad, function()
        A2UI:Confirm({
            Title = "Tutup A2 FUSION?",
            Content = "UI akan ditutup. Bisa dibuka lagi lewat tombol A2 mengambang atau tombol CTRL.",
            YesText = "Ya, Tutup",
            NoText = "Batal",
            Callback = function(yes)
                if yes then self:Close() end
            end,
        })
    end)

    -- ── SIDEBAR ──
    local side = mk("Frame", {
        Name = "Side", Size = UDim2.new(0, 156, 1, -48), Position = UDim2.new(0, 0, 0, 48),
        BackgroundColor3 = C.bgDeep, BackgroundTransparency = 0.45, BorderSizePixel = 0, Parent = main,
    })
    mk("Frame", { Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = C.stroke, BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = side })
    mk("TextLabel", {
        Size = UDim2.new(1, -20, 0, 24), Position = UDim2.new(0, 12, 0, 8),
        BackgroundTransparency = 1, Text = opts.SidebarTitle or "NAVIGATION",
        Font = Enum.Font.GothamBold, TextSize = 9, TextColor3 = C.dim,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = side,
    })
    local sideScroll = mk("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, -40), Position = UDim2.new(0, 0, 0, 40),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 2, ScrollBarImageColor3 = C.primary,
        CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = side,
    })
    vlist(sideScroll, 4, Enum.HorizontalAlignment.Center)
    pad(sideScroll, 8, 8, 8, 8)
    self.SideScroll = sideScroll

    -- ── CONTENT ──
    local content = mk("Frame", {
        Name = "Content", Size = UDim2.new(1, -156, 1, -48), Position = UDim2.new(0, 156, 0, 48),
        BackgroundColor3 = C.bgPanel, BackgroundTransparency = 1, BorderSizePixel = 0, Parent = main,
    })
    self.Content = content

    -- ── FLOATING TOGGLE (pill ala Vietnamese) ──
    if not opts.OpenButton or opts.OpenButton.Enabled ~= false then
        local ob = mk("TextButton", {
            Name = "A2Open", Size = UDim2.new(0, 52, 0, 52),
            Position = UDim2.new(0, 18, 0.5, -26), BackgroundColor3 = C.bgPanel,
            BorderSizePixel = 0, Text = "", AutoButtonColor = false,
            Visible = false, Parent = gui,
        })
        corner(ob, 999)
        stroke(ob, C.primary, 2, 0.2)
        local obText = mk("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "A2",
            Font = Enum.Font.GothamBlack, TextSize = 17, TextColor3 = C.white, Parent = ob,
        })
        mk("UIGradient", { Color = GRADIENT_TITLE, Rotation = 90, Parent = obText })
        textGlow(obText, C.primary, 0.4)
        local obRing = mk("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(1.3, 0, 1.3, 0),
            Image = "rbxassetid://7948482113", ImageColor3 = C.primary,
            ImageTransparency = 0.6, ZIndex = 0, Parent = ob,
        })
        draggable(ob)
        ob.MouseButton1Click:Connect(function()
            self:Open()
            TweenService:Create(obText, TweenInfo.new(0.5, Enum.EasingStyle.Back), { Rotation = obText.Rotation + 360 }):Play()
            task.spawn(function()
                while obRing.Parent do
                    TweenService:Create(obRing, TweenInfo.new(8, Enum.EasingStyle.Linear), { Rotation = obRing.Rotation + 360 }):Play()
                    task.wait(8)
                end
            end)
        end)
        self.OpenBtn = ob
    end

    -- Hotkey
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.LeftControl then
            if self._visible then self:Close() else self:Open() end
        end
    end)

    self.Minimized = false
    if opts.Visible ~= false then self:ShowWindow() end
    return self
end

function A2UI:ShowWindow()
    if not self.Main then return end
    self._visible = true
    self.Main.Visible = true
    self.Main.BackgroundTransparency = 1
    TweenService:Create(self.Main, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 660, 0, 450),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 0,
    }):Play()
end

function A2UI:Open()
    self._visible = true
    if self.Main then
        self.Main.Visible = true
        local sc = self.Main:FindFirstChildOfClass("UIScale")
        if sc then sc.Scale = (self._fitScale or 1) * 0.9 end
        TweenService:Create(self.Main, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 660, 0, 450),
            Position = UDim2.new(0.5, 0, 0.5, 0),
        }):Play()
        if sc then
            TweenService:Create(sc, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = self._fitScale or 1 }):Play()
        end
    end
    if self.OpenBtn then self.OpenBtn.Visible = false end
end

function A2UI:Close()
    self._visible = false
    if self.Main then
        local sc = self.Main:FindFirstChildOfClass("UIScale")
        TweenService:Create(self.Main, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 660, 0, 450),
            Position = UDim2.new(0.5, 0, 0.5, 26),
        }):Play()
        if sc then
            TweenService:Create(sc, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Scale = (self._fitScale or 1) * 0.9 }):Play()
        end
        task.delay(0.3, function()
            if self.Main then
                self.Main.Visible = false
                self.Main.Position = UDim2.new(0.5, 0, 0.5, 0)
            end
            if sc then sc.Scale = self._fitScale or 1 end
        end)
    end
    if self.OpenBtn then self.OpenBtn.Visible = true end
end

function A2UI:Minimize()
    self.Minimized = not self.Minimized
    if self.Minimized then self:Close() else self:Open() end
end

function A2UI:Tag(opts)
    opts = opts or {}
    if opts.Title and self.Main then
        local top = self.Main:FindFirstChild("Top")
        if top then
            local badge = mk("TextLabel", {
                Size = UDim2.new(0, 0, 0, 18), AutomaticSize = Enum.AutomaticSize.X,
                Position = UDim2.new(1, -98, 0.5, -9), BackgroundColor3 = C.bgRow,
                Text = "  " .. tostring(opts.Title) .. "  ", Font = Enum.Font.GothamMedium,
                TextSize = 10, TextColor3 = C.dim, Parent = top,
            })
            corner(badge, 6)
        end
    end
end

-- ═══════════════════════ TAB ══════════════════════════════════════════════
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
        Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = C.bgRow,
        BackgroundTransparency = 1, BorderSizePixel = 0, Text = "",
        AutoButtonColor = false, LayoutOrder = idx, Parent = self.SideScroll,
    })
    corner(btn, 10)
    local icon, iconIsImage = makeIcon(btn, opts.Icon or "info", {
        Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(0, 10, 0.5, -11),
        Color = C.dim,
    })
    local hl = mk("Frame", {
        Size = UDim2.new(0, 3, 0, 18), Position = UDim2.new(0, 0, 0.5, -9),
        BackgroundColor3 = C.primary, BorderSizePixel = 0, Visible = false, Parent = btn,
    })
    corner(hl, 2)
    mk("UIGradient", { Color = GRADIENT_HOT, Rotation = 90, Parent = hl })

    local lbl = mk("TextLabel", {
        Size = UDim2.new(1, -42, 1, 0), Position = UDim2.new(0, 36, 0, 0),
        BackgroundTransparency = 1, Text = opts.Title or ("Tab " .. idx),
        Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.dim,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = btn,
    })
    tab._btn, tab._hl, tab._lbl, tab._icon, tab._iconIsImage = btn, hl, lbl, icon, iconIsImage

    local page = mk("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = C.primary,
        CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false, Parent = self.Content,
    })
    vlist(page, 10, Enum.HorizontalAlignment.Left)
    pad(page, 14, 14, 14, 14)
    tab._page = page

    btn.MouseButton1Click:Connect(function() self:SelectTab(tab) end)
    btn.MouseEnter:Connect(function()
        if self._currentTab ~= tab then
            TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundTransparency = 0.7 }):Play()
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
            t._icon.ImageColor3 = on and C.secondary or C.dim
        else
            t._icon.TextColor3 = on and C.secondary or C.dim
        end
        if on then
            stroke(t._btn, C.glow, 1, 0.35)
        else
            local s = t._btn:FindFirstChildOfClass("UIStroke")
            if s then s:Destroy() end
        end
    end
    self._currentTab = tab
end

function Tab:Space()
    mk("Frame", { Size = UDim2.new(1, 0, 0, 2), BackgroundTransparency = 1, Parent = self._page })
end

-- ═══════════════════════ SECTION ══════════════════════════════════════════
local Section = {}
Section.__index = Section

function Tab:Section(opts)
    opts = opts or {}
    local sec = setmetatable({}, Section)
    sec.Tab = self
    sec._count = 0

    local card = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = C.bgRow, BorderSizePixel = 0, Parent = self._page,
    })
    corner(card, 12)
    stroke(card, C.stroke, 1, 0.55)

    local inner = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, Parent = card,
    })
    vlist(inner, 8, Enum.HorizontalAlignment.Left)
    pad(inner, 12, 12, 12, 12)

    if opts.Title then
        local h = mk("TextLabel", {
            Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = opts.Title,
            Font = Enum.Font.GothamBlack, TextSize = 14, TextColor3 = C.white,
            TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = -1000, Parent = inner,
        })
        mk("UIGradient", { Color = GRADIENT_TITLE, Rotation = 90, Parent = h })
        textGlow(h, C.primary, 0.75)
    end
    sec._inner = inner
    return sec
end

function Section:Space()
    mk("Frame", { Size = UDim2.new(1, 0, 0, 2), BackgroundTransparency = 1,
        LayoutOrder = self._count, Parent = self._inner })
end

function Section:_row(title, desc)
    self._count = self._count + 1
    local row = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, LayoutOrder = self._count, Parent = self._inner,
    })
    local textHolder = mk("Frame", {
        Size = UDim2.new(1, -60, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, Parent = row,
    })
    vlist(textHolder, 2)
    local t = mk("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, Text = title or "", Font = Enum.Font.GothamBold,
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

-- ═══════════════════════ TOGGLE ═══════════════════════════════════════════
function Section:Toggle(opts)
    opts = opts or {}
    local row = self:_row(opts.Title, opts.Desc)
    local state = opts.Value and true or false

    local sw = mk("Frame", {
        Size = UDim2.new(0, 42, 0, 22), Position = UDim2.new(1, -42, 0, 0),
        BackgroundColor3 = C.bgHover, BorderSizePixel = 0, Parent = row,
    })
    corner(sw, 11)
    stroke(sw, C.stroke, 1, 0.5)

    local knob = mk("Frame", {
        Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(0, 3, 0.5, -8),
        BackgroundColor3 = C.dim, BorderSizePixel = 0, Parent = sw,
    })
    corner(knob, 8)

    local function render()
        TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quart), {
            Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
            BackgroundColor3 = state and C.white or C.dim,
        }):Play()
        TweenService:Create(sw, TweenInfo.new(0.18, Enum.EasingStyle.Quart), {
            BackgroundColor3 = state and C.primary or C.bgHover,
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
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = row,
    })
    hit.MouseButton1Click:Connect(function() setState(not state, true) end)

    -- Config save/load support (pakai opts.Flag)
    if opts.Flag and self.Tab and self.Tab.Window then
        local w = self.Tab.Window
        local _set = setState
        setState = function(v, fire)
            _set(v, fire)
            if fire ~= false then w:_autoSave() end
        end
        w:RegisterConfigElement(opts.Flag,
            function() return state end,
            function(v) setState(v, false) end)
    end

    return { Set = function(_, v, f) setState(v, f) end, Get = function() return state end }
end

-- ═══════════════════════ SLIDER ═══════════════════════════════════════════
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

    local badge = mk("TextLabel", {
        Size = UDim2.new(0, 0, 0, 18), AutomaticSize = Enum.AutomaticSize.X,
        Position = UDim2.new(1, -56, 0, 0), BackgroundColor3 = C.bgHover,
        Text = "  " .. tostring(cur) .. "  ", Font = Enum.Font.GothamMedium,
        TextSize = 11, TextColor3 = C.secondary, Parent = row,
    })
    corner(badge, 6)

    local track = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 8), Position = UDim2.new(0, 0, 0, 26),
        BackgroundColor3 = C.bgHover, BorderSizePixel = 0, Parent = row,
    })
    corner(track, 4)
    local fill = mk("Frame", {
        Size = UDim2.new(alpha, 0, 1, 0), BackgroundColor3 = C.primary,
        BorderSizePixel = 0, Parent = track,
    })
    corner(fill, 4)
    mk("UIGradient", { Color = GRADIENT_HOT, Rotation = 0, Parent = fill })

    local knob = mk("Frame", {
        Size = UDim2.new(0, 16, 0, 16), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(alpha, 0, 0.5, 0), BackgroundColor3 = C.white,
        BorderSizePixel = 0, Parent = track,
    })
    corner(knob, 8)
    stroke(knob, C.secondary, 2, 0)

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
            dragging = true; fromX(input.Position.X)
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

    -- Config save/load support (pakai opts.Flag)
    if opts.Flag and self.Tab and self.Tab.Window then
        local w = self.Tab.Window
        local _set = setVal
        setVal = function(val, fire)
            _set(val, fire)
            if fire ~= false then w:_autoSave() end
        end
        w:RegisterConfigElement(opts.Flag,
            function() return cur end,
            function(v) setVal(v, false) end)
    end

    return { Set = function(_, val) setVal(val, false) end, Get = function() return cur end }
end

-- ═══════════════════════ BUTTON ═══════════════════════════════════════════
local function colorOf(c)
    if typeof(c) == "Color3" then return c end
    if type(c) == "string" then return C[c:lower()] or C.primary end
    return C.primary
end

function Section:Button(opts)
    opts = opts or {}
    self._count = self._count + 1
    local col = colorOf(opts.Color)

    local btn = mk("TextButton", {
        Size = UDim2.new(1, 0, 0, opts.Desc and 44 or 36),
        BackgroundColor3 = col, BackgroundTransparency = 0.85, BorderSizePixel = 0,
        Text = "", AutoButtonColor = false, LayoutOrder = self._count, Parent = self._inner,
    })
    corner(btn, 10)
    stroke(btn, col, 1, 0.35)

    local title = mk("TextLabel", {
        Size = UDim2.new(1, opts.Icon and -38 or -16, 0, 16),
        Position = UDim2.new(0, opts.Icon and 32 or 10, 0, opts.Desc and 7 or 10),
        BackgroundTransparency = 1, Text = opts.Title or "Button",
        Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.text,
        TextXAlignment = opts.Justify == "Center" and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
        Parent = btn,
    })
    if opts.Icon then
        makeIcon(btn, opts.Icon, {
            Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(0, 8, 0.5, -11),
            Color = col,
        })
    end
    if opts.Glow then textGlow(title, col, tonumber(opts.GlowStrength) or 0.72) end
    if opts.Shine then shineText(title, col) end
    if opts.Desc then
        mk("TextLabel", {
            Size = UDim2.new(1, -16, 0, 14), Position = UDim2.new(0, 10, 0, 25),
            BackgroundTransparency = 1, Text = opts.Desc, Font = Enum.Font.Gotham,
            TextSize = 10, TextColor3 = C.dim,
            TextXAlignment = opts.Justify == "Center" and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
            Parent = btn,
        })
    end

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundTransparency = 0.65 }):Play()
        if opts.Glow then TweenService:Create(title, TweenInfo.new(0.12), { TextStrokeTransparency = 0.35 }):Play() end
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundTransparency = 0.85 }):Play()
        if opts.Glow then TweenService:Create(title, TweenInfo.new(0.12), { TextStrokeTransparency = tonumber(opts.GlowStrength) or 0.72 }):Play() end
    end)
    btn.MouseButton1Click:Connect(function()
        if opts.Callback then task.spawn(function() opts.Callback() end) end
    end)
    return btn
end

-- ═══════════════════════ INPUT ════════════════════════════════════════════
function Section:Input(opts)
    opts = opts or {}
    self._count = self._count + 1
    local row = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, LayoutOrder = self._count, Parent = self._inner,
    })
    mk("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1,
        Text = opts.Title or "Input", Font = Enum.Font.GothamBold,
        TextSize = 12, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    local box = mk("TextBox", {
        Size = UDim2.new(1, 0, 0, 34), Position = UDim2.new(0, 0, 0, 20),
        BackgroundColor3 = C.bgHover, BorderSizePixel = 0, Text = opts.Value or "",
        PlaceholderText = opts.Placeholder or "", PlaceholderColor3 = C.dim,
        Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.text,
        TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Parent = row,
    })
    corner(box, 8); stroke(box, C.stroke, 1, 0.5)
    pad(box, 0, 10, 0, 10)

    box.Focused:Connect(function() stroke(box, C.secondary, 1, 0.15) end)
    box.FocusLost:Connect(function()
        stroke(box, C.stroke, 1, 0.5)
        if opts.Flag and self.Tab and self.Tab.Window then self.Tab.Window:_autoSave() end
        if opts.Callback then task.spawn(function() opts.Callback(box.Text) end) end
    end)

    -- Config save/load support (pakai opts.Flag)
    if opts.Flag and self.Tab and self.Tab.Window then
        self.Tab.Window:RegisterConfigElement(opts.Flag,
            function() return box.Text end,
            function(v)
                box.Text = tostring(v or "")
                if opts.Callback then pcall(function() opts.Callback(box.Text) end) end
            end)
    end

    return box
end

-- ═══════════════════════ DROPDOWN ═════════════════════════════════════════
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
        Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1,
        Text = opts.Title or "Dropdown", Font = Enum.Font.GothamBold,
        TextSize = 12, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    local btn = mk("TextButton", {
        Size = UDim2.new(1, 0, 0, 34), Position = UDim2.new(0, 0, 0, 20),
        BackgroundColor3 = C.bgHover, BorderSizePixel = 0,
        Text = "  " .. tostring(current or "Pilih..."), Font = Enum.Font.Gotham,
        TextSize = 12, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false, Parent = row,
    })
    corner(btn, 8); stroke(btn, C.stroke, 1, 0.5)

    local listFrame = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 0, 58),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.bgPanel,
        BorderSizePixel = 0, Visible = false, Parent = row,
    })
    corner(listFrame, 8); stroke(listFrame, C.glow, 1, 0.3)
    local listScroll = mk("ScrollingFrame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
        ScrollBarImageColor3 = C.primary, CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = listFrame,
    })
    vlist(listScroll, 2); pad(listScroll, 6, 6, 6, 6)
    mk("UISizeConstraint", { MaxSize = Vector2.new(9999, 180), Parent = listScroll })

    local obj = {}
    local function rebuild()
        for _, ch in ipairs(listScroll:GetChildren()) do
            if ch:IsA("TextButton") then ch:Destroy() end
        end
        for i, val in ipairs(values) do
            local selected = tostring(val) == tostring(current)
            local it = mk("TextButton", {
                Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = selected and C.primary or C.bgRow,
                BackgroundTransparency = selected and 0.7 or 1,
                BorderSizePixel = 0, Text = "  " .. tostring(val), Font = Enum.Font.Gotham,
                TextSize = 11, TextColor3 = selected and C.white or C.text,
                TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false,
                LayoutOrder = i, Parent = listScroll,
            })
            corner(it, 6)
            it.MouseButton1Click:Connect(function()
                current = val
                btn.Text = "  " .. tostring(val)
                open = false
                listFrame.Visible = false
                if opts.Flag and self.Tab and self.Tab.Window then self.Tab.Window:_autoSave() end
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

    -- Config save/load support (pakai opts.Flag)
    if opts.Flag and self.Tab and self.Tab.Window then
        self.Tab.Window:RegisterConfigElement(opts.Flag,
            function() return current end,
            function(v) obj.Select(v) end)
    end

    obj.Refresh = function(newValues) values = newValues or {}; rebuild() end
    obj.Select = function(val)
        current = val; btn.Text = "  " .. tostring(val)
        if opts.Callback then task.spawn(function() pcall(opts.Callback, val) end) end
    end
    obj.Get = function() return current end
    return obj
end

-- ═══════════════════════ PARAGRAPH ════════════════════════════════════════
function Section:Paragraph(opts)
    opts = opts or {}
    self._count = self._count + 1
    local col = colorOf(opts.Color)
    local card = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = C.bgHover, BackgroundTransparency = 0.5, BorderSizePixel = 0,
        LayoutOrder = self._count, Parent = self._inner,
    })
    corner(card, 9)
    local bar = mk("Frame", {
        Size = UDim2.new(0, 3, 1, -12), Position = UDim2.new(0, 0, 0, 6),
        BackgroundColor3 = col, BorderSizePixel = 0, Parent = card,
    })
    corner(bar, 2)
    mk("UIGradient", { Color = GRADIENT_HOT, Rotation = 90, Parent = bar })

    local holder = mk("Frame", {
        Size = UDim2.new(1, -16, 0, 0), Position = UDim2.new(0, 12, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = card,
    })
    vlist(holder, 2); pad(holder, 8, 4, 8, 0)

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
    return {
        SetTitle = function(_, t) title.Text = t end,
        SetDesc = function(_, d) desc.Text = d end,
        Set = function(_, t, d)
            if t then title.Text = t end
            if d then desc.Text = d end
        end,
    }
end

-- Tab-level shortcuts
function Tab:Button(opts) return self:Section({}):Button(opts) end
function Tab:Paragraph(opts) return self:Section({}):Paragraph(opts) end
function Tab:Toggle(opts) return self:Section({}):Toggle(opts) end
function Tab:Input(opts) return self:Section({}):Input(opts) end
function Tab:Dropdown(opts) return self:Section({}):Dropdown(opts) end
function Tab:Slider(opts) return self:Section({}):Slider(opts) end

-- ═══════════════════════ BOOT + AUTO MOUNT ════════════════════════════════
function A2UI:Boot(opts)
    local ok, result = pcall(function() return self:CreateWindow(opts or {}) end)
    if ok and result then
        self.LastError = nil
        return result
    end
    self.LastError = tostring(result)
    warn("[A2 UI] CreateWindow gagal: " .. self.LastError)
    return nil, self.LastError
end

-- Jika di-require sebagai ModuleScript → kembalikan library saja (tanpa intro)
local function isModuleScript()
    local ok, result = pcall(function()
        -- Executor loadstring may inherit a ModuleScript as its global script.
        if type(getgenv) == "function" or type(identifyexecutor) == "function"
            or type(getexecutorname) == "function" then return false end
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

function A2UI:MountDemo()
    if self._demoMounting then return end
    self._demoMounting = true
    local defer = (task and task.defer) or (task and task.spawn) or spawn
    defer(function()
        local parent = guiParent()
        if not parent then
            warn("[A2 UI] Tidak menemukan parent GUI")
            return
        end

        -- ══ INTRO DULU, WINDOW MUNCUL SETELAH INTRO SELESAI ══
        local mounted = false
        local function mount()
            if mounted then return end
            mounted = true
            A2UI._demoMounting = false
            local window = A2UI:Boot({
                Title = "A2 FUSION",
                Author = "Theme: Vietnamese Neon • Engine: A2",
                SidebarTitle = "MENU",
                Status = A2_ENV.Executor,
                OpenButton = { Enabled = true },
            })
            if not window then return end
            A2UI.Window = window
            window:ShowWindow()
            A2UI:Notify({
                Title = "A2 FUSION siap",
                Content = "Executor: " .. A2_ENV.Executor .. " • " .. A2_ENV.Place,
                Color = "primary",
            })

            -- ── Contoh tab Home ──
            local home = window:Tab({ Title = "Home", Icon = "home" })
            local hs = home:Section({ Title = "Environment" })
            hs:Paragraph({
                Title = "Execution detected",
                Desc = "Executor: " .. A2_ENV.Executor
                    .. "\nPlace: " .. A2_ENV.Place .. " (ID: " .. tostring(A2_ENV.PlaceId) .. ")"
                    .. "\nUser: " .. A2_ENV.User .. (A2_ENV.Mobile and " • Mobile" or " • Desktop"),
                Color = "primary", Shine = true,
            })
            hs:Button({ Title = "Test Notification", Icon = "bolt", Glow = true, Shine = true, Callback = function()
                A2UI:Notify({ Title = "A2 FUSION", Content = "Semua sistem berjalan normal.", Color = "secondary" })
            end })

            -- ── Contoh tab Farm ──
            local farm = window:Tab({ Title = "Farm", Icon = "rocket" })
            local fs = farm:Section({ Title = "Farm Control" })
            fs:Toggle({ Title = "Enable Farm", Desc = "Aktifkan loop farm otomatis.", Value = false, Flag = "farm.enabled",
                Callback = function(enabled)
                    A2UI:Notify({ Title = "Farm", Content = enabled and "Farm dimulai." or "Farm dihentikan.", Color = enabled and "good" or "bad" })
                end })
            fs:Slider({ Title = "Farm Delay", Desc = "Jeda antar aksi.", Step = 0.1, Flag = "farm.delay",
                Value = { Min = 0.1, Max = 10, Default = 1 } })
            fs:Button({ Title = "Start Farm", Icon = "play", Glow = true, Shine = true, Color = "good" })

            -- ── Contoh tab Settings ──
            local settings = window:Tab({ Title = "Settings", Icon = "settings" })
            local ss = settings:Section({ Title = "General" })
            ss:Dropdown({ Title = "Mode", Values = { "Legit", "Fast", "AFK" }, Value = "Legit" })
            ss:Input({ Title = "Target Name", Placeholder = "Masukkan nama target..." })
            ss:Toggle({ Title = "Auto Execute", Desc = "Jalankan semua file di A2Fusion/AutoExec saat UI dibuka.",
                Value = A2UI:IsAutoExecEnabled(),
                Callback = function(v) A2UI:SetAutoExecEnabled(v) end })
            ss:Button({ Title = "Jalankan AutoExec Sekarang", Icon = "play", Color = "good", Callback = function()
                local okx, resx = A2UI:RunAutoExecFolder()
                A2UI:Notify({ Title = okx and "AutoExec" or "AutoExec gagal", Content = tostring(resx), Duration = 6 })
            end })
            ss:Toggle({ Title = "Anti-AFK", Desc = "Cegah kick karena idle.", Flag = "misc.antiafk",
                Callback = function(v) A2UI:SetAntiAFK(v) end })
            local cs = settings:Section({ Title = "Config" })
            local cfgName = "slot1"
            cs:Input({ Title = "Nama Config", Placeholder = "slot1", Callback = function(t)
                if t ~= "" then cfgName = t end
            end })
            local cfgDrop
            cfgDrop = cs:Dropdown({ Title = "Pilih Config", Values = A2UI:ListConfigs(), Value = "Pilih...",
                Callback = function(v)
                    cfgName = tostring(v)
                    local okc, resc = window:LoadConfig(cfgName)
                    A2UI:Notify({ Title = okc and ("Config '" .. cfgName .. "' dimuat") or "Gagal load", Content = tostring(resc) })
                end })
            cs:Button({ Title = "Simpan Config", Icon = "save", Color = "secondary", Callback = function()
                local okc, resc = window:SaveConfig(cfgName)
                cfgDrop.Refresh(A2UI:ListConfigs())
                A2UI:Notify({ Title = okc and "Config disimpan" or "Gagal simpan", Content = tostring(resc) })
            end })
            cs:Button({ Title = "Refresh Daftar", Icon = "refresh", Callback = function()
                cfgDrop.Refresh(A2UI:ListConfigs())
            end })
            cs:Button({ Title = "Hapus Config", Icon = "close", Color = "bad", Callback = function()
                local okc, resc = A2UI:DeleteConfig(cfgName)
                cfgDrop.Refresh(A2UI:ListConfigs())
                A2UI:Notify({ Title = okc and "Dihapus" or "Gagal hapus", Content = tostring(resc) })
            end })

            local ws = settings:Section({ Title = "Discord Webhook" })
            ws:Input({
                Title = "Webhook URL",
                Placeholder = "https://discord.com/api/webhooks/...",
                Callback = function(url)
                    local okw, reason = window:SetWebhook(url)
                    A2UI:Notify({ Title = okw and "Webhook tersimpan" or "Webhook gagal", Content = okw and "URL hanya disimpan di sesi ini." or reason })
                end,
            })
            ws:Button({
                Title = "Test Webhook", Desc = "Kirim satu pesan percobaan ke Discord.", Color = "primary",
                Callback = function()
                    local okw, reason = window:Webhook({ Content = "Test webhook dari A2 FUSION berhasil." })
                    A2UI:Notify({ Title = okw and "Webhook terkirim" or "Webhook gagal", Content = okw and "Cek channel Discord kamu." or reason })
                end,
            })

            -- ── Contoh tab Survival ──
            local sv = window:Tab({ Title = "Survival", Icon = "survival" })
            local svs = sv:Section({ Title = "Survival Features" })
            svs:Toggle({ Title = "Auto Heal", Desc = "Heal otomatis saat HP rendah.", Flag = "survival.autoheal" })
            svs:Toggle({ Title = "God Mode", Flag = "survival.god" })
            svs:Slider({ Title = "Heal Threshold", Step = 5, Flag = "survival.threshold",
                Value = { Min = 0, Max = 100, Default = 40 } })

            -- ── Auto-Execute: rejoin = UI auto load lagi ──
            local ax = settings:Section({ Title = "Auto-Execute (rejoin auto load)" })
            ax:Input({ Title = "Loader URL", Flag = "loader.url",
                Placeholder = "https://raw.githubusercontent.com/USER/REPO/main/A2Loader.lua",
                Callback = function(url)
                    if url ~= "" then window:SetLoaderURL(url) end
                end })
            ax:Button({ Title = "Install Auto-Execute", Desc = "Tulis loader ke folder Autoexecute executor.",
                Icon = "bolt", Glow = true, Shine = true, Color = "good",
                Callback = function()
                    local oke, res = window:InstallAutoExecute()
                    A2UI:Notify({ Title = oke and "Auto-execute terinstall" or "Gagal install",
                        Content = tostring(res), Duration = 6 })
                end })

            -- Jalankan folder A2Fusion/AutoExec langsung saat UI terbuka
            task.spawn(function()
                if A2UI:IsAutoExecEnabled() then
                    local okx, resx, n = A2UI:RunAutoExecFolder()
                    if okx and (n or 0) > 0 then
                        A2UI:Notify({ Title = "AutoExec", Content = tostring(resx), Duration = 5 })
                    end
                end
            end)
            -- Auto-load config terakhir tiap UI dibuka
            task.delay(0.6, function()
                local okc, resc = window:LoadConfig("autosave")
                if okc then
                    A2UI:Notify({ Title = "Auto-load config", Content = tostring(resc) })
                end
            end)
        end
        -- Intro failures must never prevent the main window from opening.
        task.delay(8, function()
            if mounted then return end
            warn("[A2 UI] Intro timeout; membuka window langsung")
            local intro = parent:FindFirstChild("A2Intro")
            if intro then intro:Destroy() end
            mount()
        end)
        local ok, err = pcall(function() PlayIntro(parent, mount) end)
        if not ok then
            warn("[A2 UI] Intro gagal: " .. tostring(err))
            mount()
        end
    end)
end

if not isModuleScript() and not skipAutoMount then
    A2UI:MountDemo()
end

return A2UI
