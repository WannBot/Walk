-- Contoh: Login Key menggunakan Obsidian UI
-- Pastikan executor mendukung HttpRequest/HttpService dan HttpEnabled = true

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- load Obsidian (sesuaikan URL jika beda)
local OBS_REPO = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(OBS_REPO.."Library.lua"))()
local SaveManager  = loadstring(game:HttpGet(OBS_REPO.."addons/SaveManager.lua"))()

-- ganti jadi endpoint verifikasi key milikmu
local API_URL = "https://botresi.xyz/keygen/api/validate.php"

-- helper: ubah durasi seconds -> human readable (contoh server mungkin beri seconds)
local function humanDuration(seconds)
    seconds = tonumber(seconds) or 0
    if seconds <= 0 then return "Expired" end
    local hours = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    if hours > 0 then
        return tostring(hours) .. " Hours"
    elseif mins > 0 then
        return tostring(mins) .. " Minutes"
    else
        return tostring(seconds) .. " Seconds"
    end
end

-- Create UI
local Window = Library:CreateWindow({
    Title = "Auth Key",
    Size = UDim2.new(0, 360, 0, 180),
})

local section = Window:CreateSection("Login menggunakan Key")

local keyInput = section:CreateTextBox({
    Text = "",
    Placeholder = "Masukkan key di sini...",
    ClearTextOnFocus = false,
})

local statusLabel = section:CreateLabel("Status: Idle")

local loginBtn = section:CreateButton({
    Text = "Login",
    Callback = function()
        local key = keyInput.Text or ""
        if key == "" then
            statusLabel:SetText("Status: Masukkan key dulu")
            return
        end

        statusLabel:SetText("Status: Memeriksa key...")
        -- request body; sesuaikan format API (POST/GET)
        local ok, result = pcall(function()
            -- contoh POST JSON
            local body = HttpService:JSONEncode({ key = key })
            local resp = HttpService:PostAsync(API_URL, body, Enum.HttpContentType.ApplicationJson)
            return resp
        end)

        if not ok then
            statusLabel:SetText("Status: Error koneksi. Cek HTTPExecutor.")
            return
        end

        -- parse response (asumsi JSON)
        local parsed
        local success, err = pcall(function()
            parsed = HttpService:JSONDecode(result)
        end)
        if not success or type(parsed) ~= "table" then
            -- jika API mengembalikan plain text, kamu bisa adjust parsing
            statusLabel:SetText("Status: Respon tidak valid dari server")
            return
        end

        -- contoh struktur respons yang diharapkan:
        -- { success = true/false, message = "string", duration_seconds = 3600, data = {...} }
        if parsed.success then
            local displayDuration = humanDuration(parsed.duration_seconds)
            statusLabel:SetText("Status: Login sukses — Duration: "..displayDuration)
            -- simpan key lokal (opsional)
            SaveManager:Save("auth_key", key)
            -- lakukan tindakan setelah login, mis. enable fitur
            -- doSomethingAfterLogin(parsed.data)
        else
            statusLabel:SetText("Status: Gagal — "..(parsed.message or "Invalid key"))
        end
    end,
})

local saveBtn = section:CreateButton({
    Text = "Load saved key",
    Callback = function()
        local saved = SaveManager:Load("auth_key")
        if saved and saved ~= "" then
            keyInput:SetText(saved)
            statusLabel:SetText("Status: Key dimuat")
        else
            statusLabel:SetText("Status: Tidak ada key tersimpan")
        end
    end,
})
