-- 🔐 Login Key UI Obsidian (Versi fix tampil input & tombol)
local HttpService = game:GetService("HttpService")

-- Load Obsidian Library
local OBS_REPO = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(OBS_REPO.."Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(OBS_REPO.."addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(OBS_REPO.."addons/SaveManager.lua"))()

-- URL API
local API_URL = "https://botresi.xyz/keygen/api/validate.php"

-- Fungsi ubah durasi ke tulisan
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

-- 🪟 Buat Window & Tab
local Window = Library:CreateWindow({
    Title = "Botresi Key Login",
    Size = UDim2.new(0, 400, 0, 230),
})

local Tab = Window:CreateTab({
    Title = "Auth 🔑",
    Icon = "rbxassetid://7743868255"
})

-- 🧩 Section utama
local Section = Tab:CreateSection("Masukkan Key untuk Login")

-- Input Key
local KeyInput = Section:AddTextbox({
    Title = "Input Key",
    Default = "",
    Placeholder = "Masukkan key di sini...",
    Callback = function() end
})

-- Label status
local StatusLabel = Section:AddLabel({ Title = "Status: Idle" })

-- Tombol Login
Section:AddButton({
    Title = "Login Sekarang",
    Callback = function()
        local key = KeyInput.Value or ""
        if key == "" then
            StatusLabel:SetTitle("Status: Masukkan key terlebih dahulu!")
            return
        end

        StatusLabel:SetTitle("Status: Memeriksa key...")

        local success, result = pcall(function()
            local body = HttpService:JSONEncode({ key = key })
            return HttpService:PostAsync(API_URL, body, Enum.HttpContentType.ApplicationJson)
        end)

        if not success then
            StatusLabel:SetTitle("Status: Gagal koneksi ke server")
            return
        end

        local data = HttpService:JSONDecode(result)
        if data.success then
            local dur = humanDuration(data.duration_seconds or 0)
            StatusLabel:SetTitle("Status: ✅ Key valid ("..dur..")")
        else
            StatusLabel:SetTitle("Status: ❌ "..(data.message or "Key tidak valid"))
        end
    end
})

-- Tombol Load Key tersimpan (opsional)
Section:AddButton({
    Title = "Load Saved Key",
    Callback = function()
        local saved = SaveManager:Load("auth_key")
        if saved and saved ~= "" then
            KeyInput:SetValue(saved)
            StatusLabel:SetTitle("Status: Key dimuat dari SaveManager")
        else
            StatusLabel:SetTitle("Status: Tidak ada key tersimpan")
        end
    end
})

-- Tema
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
