--// BOTRESI HUB LOGIN - Modern Card UI Style
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- Konfigurasi endpoint
local validateEndpoint = "https://botresi.xyz/keygen/api/validate.php"
local getKeyURL = "https://botresi.xyz/keygen/admin_generate.php"
local scriptURL = "https://raw.githubusercontent.com/WannBot/Rbx/main/ScriptUtama.lua"

-- Siapkan PlayerGui
repeat task.wait() until player:FindFirstChild("PlayerGui")
local guiParent = player.PlayerGui

-- Background blur
local blur = Instance.new("BlurEffect", Lighting)
blur.Size = 0
TweenService:Create(blur, TweenInfo.new(0.4), {Size = 10}):Play()

-- ScreenGui
local screenGui = Instance.new("ScreenGui", guiParent)
screenGui.Name = "BotresiModernLogin"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false

-- Frame utama (Card)
local frame = Instance.new("Frame", screenGui)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.new(0.5, 0, 0.5, 0)
frame.Size = UDim2.new(0.8, 0, 0.65, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
frame.BorderSizePixel = 0

-- Shadow effect
local shadow = Instance.new("ImageLabel", frame)
shadow.AnchorPoint = Vector2.new(0.5, 0.5)
shadow.Position = UDim2.new(0.5, 0, 0.5, 10)
shadow.Size = UDim2.new(1.1, 0, 1.2, 0)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://1316045217"
shadow.ImageColor3 = Color3.new(0, 0, 0)
shadow.ImageTransparency = 0.85
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(10, 10, 118, 118)

-- Border halus biru keunguan
local border = Instance.new("UIStroke", frame)
border.Color = Color3.fromRGB(120, 90, 255)
border.Thickness = 2
border.Transparency = 0.2
border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- Sudut bulat
local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0, 18)

-- Avatar Player
local avatar = Instance.new("ImageLabel", frame)
avatar.AnchorPoint = Vector2.new(0.5, 0)
avatar.Position = UDim2.new(0.5, 0, 0.07, 0)
avatar.Size = UDim2.new(0.28, 0, 0.3, 0)
avatar.BackgroundTransparency = 1
avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId="..player.UserId.."&width=150&height=150&format=png"
local avatarCorner = Instance.new("UICorner", avatar)
avatarCorner.CornerRadius = UDim.new(1, 0)

-- Username Label
local username = Instance.new("TextLabel", frame)
username.AnchorPoint = Vector2.new(0.5, 0)
username.Position = UDim2.new(0.5, 0, 0.39, 0)
username.Size = UDim2.new(0.8, 0, 0.08, 0)
username.BackgroundTransparency = 1
username.Font = Enum.Font.GothamBold
username.Text = player.Name
username.TextColor3 = Color3.fromRGB(255, 255, 255)
username.TextScaled = true

-- Input Key
local input = Instance.new("TextBox", frame)
input.AnchorPoint = Vector2.new(0.5, 0)
input.Position = UDim2.new(0.5, 0, 0.52, 0)
input.Size = UDim2.new(0.8, 0, 0.11, 0)
input.PlaceholderText = "Masukkan key..."
input.Font = Enum.Font.Gotham
input.TextSize = 18
input.TextColor3 = Color3.fromRGB(255,255,255)
input.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
input.Text = ""
local inputCorner = Instance.new("UICorner", input)
inputCorner.CornerRadius = UDim.new(0, 8)

-- Tombol Login (Ungu)
local loginBtn = Instance.new("TextButton", frame)
loginBtn.AnchorPoint = Vector2.new(0.5, 0)
loginBtn.Position = UDim2.new(0.5, 0, 0.67, 0)
loginBtn.Size = UDim2.new(0.8, 0, 0.1, 0)
loginBtn.BackgroundColor3 = Color3.fromRGB(110, 90, 255)
loginBtn.Text = "Login"
loginBtn.Font = Enum.Font.GothamBold
loginBtn.TextSize = 20
loginBtn.TextColor3 = Color3.new(1,1,1)
local loginCorner = Instance.new("UICorner", loginBtn)
loginCorner.CornerRadius = UDim.new(0, 8)

-- Garis pemisah
local divider = Instance.new("TextLabel", frame)
divider.AnchorPoint = Vector2.new(0.5, 0)
divider.Position = UDim2.new(0.5, 0, 0.78, 0)
divider.Size = UDim2.new(0.8, 0, 0.04, 0)
divider.Text = "──────────  OR  ──────────"
divider.TextColor3 = Color3.fromRGB(130,130,130)
divider.Font = Enum.Font.Gotham
divider.TextSize = 14
divider.BackgroundTransparency = 1

-- Tombol Get Key (Hitam)
local getKeyBtn = Instance.new("TextButton", frame)
getKeyBtn.AnchorPoint = Vector2.new(0.5, 0)
getKeyBtn.Position = UDim2.new(0.5, 0, 0.84, 0)
getKeyBtn.Size = UDim2.new(0.8, 0, 0.1, 0)
getKeyBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
getKeyBtn.Text = "Get Key"
getKeyBtn.Font = Enum.Font.GothamBold
getKeyBtn.TextSize = 20
getKeyBtn.TextColor3 = Color3.new(1,1,1)
local getKeyCorner = Instance.new("UICorner", getKeyBtn)
getKeyCorner.CornerRadius = UDim.new(0, 8)

-- Label Status
local status = Instance.new("TextLabel", frame)
status.AnchorPoint = Vector2.new(0.5, 0)
status.Position = UDim2.new(0.5, 0, 0.95, 0)
status.Size = UDim2.new(0.8, 0, 0.05, 0)
status.Text = ""
status.TextColor3 = Color3.fromRGB(255, 200, 120)
status.Font = Enum.Font.Gotham
status.TextSize = 14
status.BackgroundTransparency = 1

-- Fungsi Validasi Key
local function validateKey(key)
	local body = "key=" .. HttpService:UrlEncode(key)
	local request = (http_request or request or syn and syn.request)
	if not request then
		return false, "Executor tidak mendukung HTTP request"
	end

	local response = request({
		Url = validateEndpoint,
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/x-www-form-urlencoded"
		},
		Body = body
	})

	if not response or not response.Body then
		return false, "Tidak dapat terhubung ke server"
	end

	local success, data = pcall(function()
		return HttpService:JSONDecode(response.Body)
	end)

	if not success or not data then
		return false, "Respon server tidak valid"
	end

	if data.valid == true then
		local sisa = tonumber(data.expires_in_seconds or 0)
		local jam = math.floor(sisa / 3600)
		local menit = math.floor((sisa % 3600) / 60)
		local info = ("Key aktif %d jam %d menit lagi"):format(jam, menit)
		return true, info
	else
		return false, "Key tidak valid atau expired"
	end
end

-- Tombol Login
loginBtn.MouseButton1Click:Connect(function()
	local key = string.gsub(input.Text or "", "%s+", "")
	if key == "" then
		status.Text = "❗ Masukkan key terlebih dahulu"
		return
	end
	status.Text = "⏳ Memeriksa key..."
	local ok, info = validateKey(key)
	if ok then
		status.Text = "✅ Key valid! " .. info
		task.wait(1.5)
		TweenService:Create(blur, TweenInfo.new(0.3), {Size = 0}):Play()
		task.wait(0.3)
		blur:Destroy()
		screenGui:Destroy()
		loadstring(game:HttpGet(scriptURL))()
	else
		status.Text = "❌ " .. tostring(info)
	end
end)

-- Tombol Get Key
getKeyBtn.MouseButton1Click:Connect(function()
	if setclipboard then
		setclipboard(getKeyURL)
		status.Text = "🔗 URL disalin ke clipboard!"
	else
		status.Text = "ℹ️ Clipboard tidak didukung executor"
	end
end)
