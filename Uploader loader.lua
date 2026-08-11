-- =============================================
--  LOADER OUROBOROS - VERSI DELTA (TOMBIK KLIK)
--  FIX: Tombol bisa diklik dengan TouchTap
-- =============================================

-- [[ KONFIGURASI (SESUAIKAN DENGAN PUNYAMU) ]]
local CONFIG = {
    KEY_DB_URL = "https://pastebin.com/raw/i5cv2QnV",
    SHORTLINK_URL = "https://link-hub.net/8288902/2INkRQdbqAV1",
    MAIN_SCRIPT_URL = "https://raw.githubusercontent.com/joustingmatch/Ouroboros/main/loader.lua"
}

-- [[ FUNGSI GET HWID ]]
local function get_hwid()
    if syn and syn.get_hwid then return syn.get_hwid() end
    if game:GetService("RbxAnalyticsService") then
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end
    return os.getenv("USERNAME") or "UnknownHWID"
end

-- [[ HTTP REQUEST KHUSUS DELTA ]]
local function http_request_delta(url)
    local methods = {
        function() 
            local result = request({ Url = url, Method = "GET" })
            if result and result.Body then return result.Body end
        end,
        function() 
            local result = http.request({ Url = url, Method = "GET" })
            if result and result.Body then return result.Body end
        end,
        function() 
            return game:HttpGet(url) 
        end,
        function() 
            return syn.request({ Url = url, Method = "GET" }).Body 
        end
    }
    
    for _, method in ipairs(methods) do
        local success, result = pcall(method)
        if success and result then
            return result
        end
    end
    return nil
end

-- [[ FUNGSI BUKA BROWSER ]]
local function open_browser(url)
    local methods = {
        function() open_url(url) end,
        function() syn and syn.url_open(url) end,
        function() os.execute("start " .. url) end,
        function() print("🔗 BUKA LINK: " .. url) end
    }
    for _, method in ipairs(methods) do
        if method then
            local success = pcall(method)
            if success then return true end
        end
    end
    return false
end

-- [[ FUNGSI BACA/TULIS FILE ]]
local function read_file(path)
    if readfile then
        local s, d = pcall(readfile, path)
        if s then return d end
    end
    return nil
end

local function write_file(path, data)
    if writefile then
        pcall(writefile, path, data)
    end
end

-- [[ AMBIL DATABASE KEY ]]
local function fetch_keys_from_remote()
    local response = http_request_delta(CONFIG.KEY_DB_URL)
    if response then
        local success, decoded = pcall(game:GetService("HttpService").JSONDecode, game:GetService("HttpService"), response)
        if success and type(decoded) == "table" then
            return decoded
        end
    end
    return nil
end

-- [[ FUNGSI VERIFIKASI ]]
local function verify_key(input_key, hwid)
    local key_db = fetch_keys_from_remote()
    if not key_db then
        return false, "Gagal mengambil database key. Cek koneksi internet."
    end
    
    local key_data = key_db[input_key]
    if not key_data then
        return false, "Key tidak terdaftar! Pastikan ejaan benar."
    end
    
    local is_lifetime = (key_data.expiry_hours == -1)
    local file_name = "Ouroboros_" .. input_key:gsub(" ", "_") .. ".dat"
    
    local saved = read_file(file_name)
    if saved then
        local saved_hwid, saved_time = saved:match("(.-)|(.+)")
        saved_time = tonumber(saved_time)
        
        if saved_hwid ~= hwid then
            return false, "HWID tidak cocok! Key ini sudah dipakai di PC lain."
        end
        
        if not is_lifetime then
            local elapsed = os.time() - saved_time
            if elapsed >= (key_data.expiry_hours * 3600) then
                return false, "Masa aktif 12 jam sudah habis! Beli premium untuk lifetime."
            end
        end
        return true, "Verifikasi berhasil!"
    else
        write_file(file_name, hwid .. "|" .. tostring(os.time()))
        return true, "Key berhasil diaktivasi untuk PC ini!"
    end
end

-- [[ ========== GUI FIX TOTAL UNTUK DELTA ========== ]]
local function show_gui()
    local player = game.Players.LocalPlayer
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "KeySystem"
    screenGui.Parent = player.PlayerGui
    
    -- Frame utama
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 380, 0, 250)
    frame.Position = UDim2.new(0.5, -190, 0.5, -125)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "🔐 VERIFIKASI KEY"
    title.TextColor3 = Color3.fromRGB(255, 200, 100)
    title.TextSize = 22
    title.Font = Enum.Font.GothamBold
    title.Parent = frame
    
    -- === TOMBOL LINK (Dengan TouchTap) ===
    local btnLink = Instance.new("TextButton")
    btnLink.Size = UDim2.new(0.8, 0, 0, 40)
    btnLink.Position = UDim2.new(0.1, 0, 0.28, 0)
    btnLink.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
    btnLink.Text = "🌐 DAPATKAN KEY (Buka Shortlink)"
    btnLink.TextColor3 = Color3.fromRGB(255,255,255)
    btnLink.TextSize = 14
    btnLink.Font = Enum.Font.Gotham
    btnLink.AutoButtonColor = true
    btnLink.Parent = frame
    
    -- === INPUT KEY ===
    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(0.8, 0, 0, 35)
    textBox.Position = UDim2.new(0.1, 0, 0.52, 0)
    textBox.PlaceholderText = "Masukkan Key di sini..."
    textBox.Text = ""
    textBox.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    textBox.TextColor3 = Color3.fromRGB(255,255,255)
    textBox.TextSize = 14
    textBox.Font = Enum.Font.Gotham
    textBox.Parent = frame
    
    -- === TOMBOL VERIFIKASI (Dengan TouchTap) ===
    local btnVerify = Instance.new("TextButton")
    btnVerify.Size = UDim2.new(0.4, 0, 0, 40)
    btnVerify.Position = UDim2.new(0.3, 0, 0.72, 0)
    btnVerify.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    btnVerify.Text = "✅ VERIFIKASI"
    btnVerify.TextColor3 = Color3.fromRGB(255,255,255)
    btnVerify.TextSize = 16
    btnVerify.Font = Enum.Font.GothamBold
    btnVerify.AutoButtonColor = true
    btnVerify.Parent = frame
    
    -- === STATUS LABEL ===
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 30)
    status.Position = UDim2.new(0, 0, 0.9, 0)
    status.BackgroundTransparency = 1
    status.Text = "Klik tombol hijau untuk verifikasi"
    status.TextColor3 = Color3.fromRGB(200, 200, 200)
    status.TextSize = 13
    status.Font = Enum.Font.Gotham
    status.Parent = frame
    
    -- ========================================
    --  FIX UTAMA: EVENT UNTUK DELTA
    --  Pakai TouchTap dan MouseButton1Click
    -- ========================================
    
    -- Event Tombol Link (pakai 2 metode sekaligus)
    local function onLinkClick()
        open_browser(CONFIG.SHORTLINK_URL)
        status.Text = "✅ Link dibuka! Cek browser, masukkan key."
        status.TextColor3 = Color3.fromRGB(100, 255, 100)
    end
    
    btnLink.MouseButton1Click:Connect(onLinkClick)
    btnLink.TouchTap:Connect(onLinkClick)  -- Khusus Delta
    
    -- Event Tombol Verifikasi (pakai 2 metode sekaligus)
    local function onVerifyClick()
        local key = textBox.Text
        if key == "" then
            status.Text = "⚠️ Masukkan key terlebih dahulu!"
            status.TextColor3 = Color3.fromRGB(255, 200, 0)
            return
        end
        
        status.Text = "⏳ Memverifikasi..."
        status.TextColor3 = Color3.fromRGB(255, 200, 0)
        
        local hwid = get_hwid()
        local success, message = verify_key(key, hwid)
        
        if success then
            status.Text = "✅ " .. message
            status.TextColor3 = Color3.fromRGB(0, 255, 0)
            wait(0.8)
            screenGui:Destroy()
            loadstring(game:HttpGet(CONFIG.MAIN_SCRIPT_URL))()
        else
            status.Text = "❌ " .. message
            status.TextColor3 = Color3.fromRGB(255, 50, 50)
        end
    end
    
    btnVerify.MouseButton1Click:Connect(onVerifyClick)
    btnVerify.TouchTap:Connect(onVerifyClick)  -- Khusus Delta
end

-- [[ EKSEKUSI ]]
pcall(show_gui)
