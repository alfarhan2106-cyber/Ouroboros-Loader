-- =============================================
--  LOADER OUROBOROS + SISTEM KEY (HWID + EXPIRY)
--  IKUTI PANDUAN UNTUK MENGGANTI BAGIAN YANG WAJIB
-- =============================================

-- [[ 1. KONFIGURASI (WAJIB GANTI) ]]
local CONFIG = {
    -- Ganti dengan URL RAW Pastebin daftar key-mu
    KEY_DB_URL = "https://pastebin.com/raw/i5cv2QnV", -- <<< GANTI INI
    
    -- Ganti dengan Shortlink-mu (Linkvertise / Adf.ly)
    SHORTLINK_URL = "https://link-hub.net/8288902/2INkRQdbqAV1", -- <<< GANTI INI
    
    -- Ganti dengan URL skrip utama Ouroboros (bisa taruh di repo ini juga)
    MAIN_SCRIPT_URL = "https://raw.githubusercontent.com/joustingmatch/Ouroboros/main/loader.lua" -- <<< GANTI INI (misal kamu buat file main_script.lua nanti)
}

-- [[ 2. FUNGSI DASAR UNTUK EKSEKUTOR (JANGAN DIUBAH) ]]
local function get_hwid()
    if syn and syn.get_hwid then return syn.get_hwid() end
    if game:GetService("RbxAnalyticsService") then
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end
    return os.getenv("USERNAME") or "UnknownHWID"
end

local function http_request(data)
    local methods = {syn and syn.request, http_request, request, http and http.request}
    for _, method in ipairs(methods) do
        if method then
            local success, result = pcall(method, data)
            if success then return result end
        end
    end
    error("Tidak ada metode HTTP yang didukung oleh executor ini!")
end

local function open_browser(url)
    local methods = {syn and syn.url_open, open_url, function(u) os.execute("start " .. u) end}
    for _, method in ipairs(methods) do
        if method then
            pcall(method, url)
            return
        end
    end
    warn("Buka link manual: " .. url)
end

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

-- [[ 3. AMBIL DAFTAR KEY DARI PASTEBIN (REMOTE) ]]
local function fetch_keys_from_remote()
    local response = http_request({
        Url = CONFIG.KEY_DB_URL,
        Method = "GET"
    })
    if response and response.Body then
        local decoded = game:GetService("HttpService"):JSONDecode(response.Body)
        if type(decoded) == "table" then
            return decoded
        end
    end
    return nil
end

-- [[ 4. FUNGSI VERIFIKASI UTAMA ]]
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
        -- Aktivasi pertama
        write_file(file_name, hwid .. "|" .. tostring(os.time()))
        return true, "Key berhasil diaktivasi untuk PC ini!"
    end
end

-- [[ 5. TAMPILAN GUI ]]
local function show_gui()
    local player = game.Players.LocalPlayer
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "KeySystem"
    screenGui.Parent = player.PlayerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 380, 0, 220)
    frame.Position = UDim2.new(0.5, -190, 0.5, -110)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "🔐 VERIFIKASI KEY"
    title.TextColor3 = Color3.fromRGB(255, 200, 100)
    title.TextSize = 22
    title.Font = Enum.Font.GothamBold
    title.Parent = frame
    
    -- Tombol buka shortlink
    local btnLink = Instance.new("TextButton")
    btnLink.Size = UDim2.new(0.8, 0, 0, 35)
    btnLink.Position = UDim2.new(0.1, 0, 0.3, 0)
    btnLink.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
    btnLink.Text = "🌐 DAPATKAN KEY (Buka Shortlink)"
    btnLink.TextColor3 = Color3.fromRGB(255,255,255)
    btnLink.TextSize = 14
    btnLink.Font = Enum.Font.Gotham
    btnLink.Parent = frame
    btnLink.MouseButton1Click:Connect(function()
        open_browser(CONFIG.SHORTLINK_URL)
        status.Text = "✅ Link dibuka! Cek browser, masukkan key."
        status.TextColor3 = Color3.fromRGB(100, 255, 100)
    end)
    
    -- TextBox input key
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
    
    -- Tombol Verifikasi
    local btnVerify = Instance.new("TextButton")
    btnVerify.Size = UDim2.new(0.4, 0, 0, 35)
    btnVerify.Position = UDim2.new(0.3, 0, 0.72, 0)
    btnVerify.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    btnVerify.Text = "✅ VERIFIKASI"
    btnVerify.TextColor3 = Color3.fromRGB(255,255,255)
    btnVerify.TextSize = 16
    btnVerify.Font = Enum.Font.GothamBold
    btnVerify.Parent = frame
    
    -- Status label
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 30)
    status.Position = UDim2.new(0, 0, 0.9, 0)
    status.BackgroundTransparency = 1
    status.Text = "Klik tombol hijau untuk verifikasi"
    status.TextColor3 = Color3.fromRGB(200, 200, 200)
    status.TextSize = 13
    status.Font = Enum.Font.Gotham
    status.Parent = frame
    
    -- Event klik verifikasi
    btnVerify.MouseButton1Click:Connect(function()
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
            
            -- Jalankan skrip utama
            loadstring(game:HttpGet(CONFIG.MAIN_SCRIPT_URL))()
        else
            status.Text = "❌ " .. message
            status.TextColor3 = Color3.fromRGB(255, 50, 50)
        end
    end)
end

-- [[ 6. EKSEKUSI ]]
pcall(show_gui)
