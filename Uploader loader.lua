-- =============================================
--  LOADER OUROBOROS - VERSI DELTA EXECUTOR
--  Dikhususkan untuk Delta di HP Android
-- =============================================

-- [[ 1. KONFIGURASI (WAJIB GANTI) ]]
local CONFIG = {
    -- Ganti dengan URL RAW Pastebin daftar key-mu
    KEY_DB_URL = "https://pastebin.com/raw/i5cv2QnV",  -- <<< GANTI INI
    
    -- Ganti dengan Shortlink-mu
    SHORTLINK_URL = "https://link-hub.net/8288902/2INkRQdbqAV1",  -- <<< GANTI INI
    
    -- Ganti dengan URL skrip utama
    MAIN_SCRIPT_URL = "https://raw.githubusercontent.com/joustingmatch/Ouroboros/main/loader.lua"  -- <<< GANTI INI
}

-- [[ 2. FUNGSI KHUSUS DELTA ]]
local function delta_http_get(url)
    -- Delta menggunakan fungsi "request" atau "http.request"
    local methods = {
        function() 
            return request({ 
                Url = url, 
                Method = "GET" 
            }) 
        end,
        function()
            return http.request({ 
                Url = url, 
                Method = "GET" 
            })
        end,
        function()
            return game:HttpGet(url)
        end
    }
    
    for _, method in ipairs(methods) do
        local success, result = pcall(method)
        if success and result then
            if type(result) == "table" and result.Body then
                return result.Body
            elseif type(result) == "string" then
                return result
            end
        end
    end
    return nil
end

local function delta_open_browser(url)
    -- Delta: coba berbagai cara buka browser
    local methods = {
        function() open_url(url) end,
        function() syn and syn.url_open(url) end,
        function() 
            -- Fallback: tampilkan link di console
            print("🔗 BUKA LINK INI: " .. url)
        end
    }
    
    for _, method in ipairs(methods) do
        local success = pcall(method)
        if success then return true end
    end
    return false
end

-- [[ 3. FUNGSI HWID UNTUK DELTA ]]
local function get_hwid()
    -- Delta biasanya pakai game:GetService
    if game:GetService("RbxAnalyticsService") then
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end
    return os.getenv("USERNAME") or "DeltaUser"
end

-- [[ 4. BACA/TULIS FILE (Delta mendukung) ]]
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

-- [[ 5. AMBIL DATABASE KEY ]]
local function fetch_keys_from_remote()
    local response = delta_http_get(CONFIG.KEY_DB_URL)
    if response then
        local success, decoded = pcall(game:GetService("HttpService").JSONDecode, game:GetService("HttpService"), response)
        if success and type(decoded) == "table" then
            return decoded
        end
    end
    return nil
end

-- [[ 6. FUNGSI VERIFIKASI ]]
local function verify_key(input_key, hwid)
    local key_db = fetch_keys_from_remote()
    if not key_db then
        return false, "Gagal ambil database. Cek internet atau URL Pastebin."
    end
    
    local key_data = key_db[input_key]
    if not key_data then
        return false, "Key tidak terdaftar! Periksa ejaan."
    end
    
    local is_lifetime = (key_data.expiry_hours == -1)
    local file_name = "Ouroboros_" .. input_key:gsub(" ", "_") .. ".dat"
    
    local saved = read_file(file_name)
    if saved then
        local saved_hwid, saved_time = saved:match("(.-)|(.+)")
        saved_time = tonumber(saved_time)
        
        if saved_hwid ~= hwid then
            return false, "HWID tidak cocok! Key sudah dipakai PC lain."
        end
        
        if not is_lifetime then
            local elapsed = os.time() - saved_time
            if elapsed >= (key_data.expiry_hours * 3600) then
                return false, "Masa aktif 12 jam habis! Beli premium."
            end
        end
        return true, "Verifikasi berhasil!"
    else
        write_file(file_name, hwid .. "|" .. tostring(os.time()))
        return true, "Key berhasil diaktivasi!"
    end
end

-- [[ 7. TAMPILAN GUI SEDERHANA UNTUK DELTA ]]
local function show_gui()
    local player = game.Players.LocalPlayer
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "KeySystem"
    screenGui.Parent = player.PlayerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 350, 0, 240)
    frame.Position = UDim2.new(0.5, -175, 0.5, -120)
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
    
    local btnLink = Instance.new("TextButton")
    btnLink.Size = UDim2.new(0.8, 0, 0, 40)
    btnLink.Position = UDim2.new(0.1, 0, 0.25, 0)
    btnLink.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
    btnLink.Text = "🌐 DAPATKAN KEY"
    btnLink.TextColor3 = Color3.fromRGB(255,255,255)
    btnLink.TextSize = 14
    btnLink.Font = Enum.Font.Gotham
    btnLink.Parent = frame
    btnLink.MouseButton1Click:Connect(function()
        local opened = delta_open_browser(CONFIG.SHORTLINK_URL)
        if opened then
            status.Text = "✅ Link dibuka! Cek browser."
            status.TextColor3 = Color3.fromRGB(100, 255, 100)
        else
            status.Text = "⚠️ Buka manual: " .. CONFIG.SHORTLINK_URL
            status.TextColor3 = Color3.fromRGB(255, 200, 0)
        end
    end)
    
    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(0.8, 0, 0, 35)
    textBox.Position = UDim2.new(0.1, 0, 0.48, 0)
    textBox.PlaceholderText = "Masukkan Key..."
    textBox.Text = ""
    textBox.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    textBox.TextColor3 = Color3.fromRGB(255,255,255)
    textBox.TextSize = 14
    textBox.Font = Enum.Font.Gotham
    textBox.Parent = frame
    
    local btnVerify = Instance.new("TextButton")
    btnVerify.Size = UDim2.new(0.4, 0, 0, 35)
    btnVerify.Position = UDim2.new(0.3, 0, 0.68, 0)
    btnVerify.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    btnVerify.Text = "✅ VERIFIKASI"
    btnVerify.TextColor3 = Color3.fromRGB(255,255,255)
    btnVerify.TextSize = 16
    btnVerify.Font = Enum.Font.GothamBold
    btnVerify.Parent = frame
    
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 30)
    status.Position = UDim2.new(0, 0, 0.88, 0)
    status.BackgroundTransparency = 1
    status.Text = "Klik tombol hijau untuk verifikasi"
    status.TextColor3 = Color3.fromRGB(200, 200, 200)
    status.TextSize = 13
    status.Font = Enum.Font.Gotham
    status.Parent = frame
    
    btnVerify.MouseButton1Click:Connect(function()
        local key = textBox.Text
        if key == "" then
            status.Text = "⚠️ Masukkan key dulu!"
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
    end)
end

-- [[ 8. JALANKAN ]]
pcall(show_gui)
