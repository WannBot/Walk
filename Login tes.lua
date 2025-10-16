--// BOTRESI HUB LOGIN - Final Animated Card UI (v10)
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- Konfigurasi endpoint
local validateEndpoint = "https://botresi.xyz/keygen/api/validate.php"
local getKeyURL = "https://botresi.xyz/keygen/admin_generate.php"
local scriptURL = "https://raw.githubusercontent.com/WannBot/Rbx/main/ScriptUtama.lua"

-- Background blur
local blur = Instance.new("BlurEffect", Lighting)
blur.Size = 0
TweenService:Create(blur, TweenInfo.new(0.4), {Size = 10}):Play()

-- GUI utama
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BotresiFinalUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Frame utama (kotak card)
local frame = Instance.new("Frame", screenGui)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.new(0.5, 0, 0.5, 0)
frame.Size = UDim2.new(0.4, 0, 0.55, 0)
frame.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
frame.BorderSizePixel = 0
frame.ClipsDescendants = true

local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0, 18)

-- Soft shadow (tanpa lancip)
local shadow = Instance.new("ImageLabel", frame)
shadow.AnchorPoint = Vector2.new(0.5, 0.5)
shadow.Position = UDim2.new(0.5, 0, 0.5, 8)
shadow.Size = UDim2.new(1.2, 0, 1.2, 0)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://5554234286" -- soft glow shadow
shadow.ImageTransparency = 0.9
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)

-- Border glow ungu halus
local border = Instance.new("UIStroke", frame)
border.Color = Color3.fromRGB(120, 90, 255)
border.Thickness = 2
border.Transparency = 0.3

-- Avatar Holder
local avatarHolder = Instance.new("Frame", frame)
avatarHolder.AnchorPoint = Vector2.new(0.5, 0)
avatarHolder.Position = UDim2.new(0.5, 0, 0.08, 0)
avatarHolder.Size = UDim2.new(0.35, 0, 0.35, 0)
avatarHolder.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
avatarHolder.BorderSizePixel = 0

local avatarCorner = Instance.new("UICorner", avatarHolder)
avatarCorner.CornerRadius = UDim.new(1, 0)

local avatarGlow = Instance.new("UIStroke", avatarHolder)
avatarGlow.Thickness = 2
avatarGlow.Color = Color3.fromRGB(150,130,255)
avatarGlow.Transparency = 0.15

local avatar = Instance.new("ImageLabel", avatarHolder)
avatar.AnchorPoint = Vector2.new(0.5, 0.5)
avatar.Position = UDim2.new(0.5, 0, 0.5, 0)
avatar.Size = UDim2.new(0.9, 0, 0.9, 0)
avatar.BackgroundTransparency = 1
avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId="..player.UserId.."&width=150&height=150&format=png"
local avatarCorner2 = Instance.new("UICorner", avatar)
avatarCorner2.CornerRadius = UDim.new(1, 0)

-- Label animasi (Hello / Masukkan key)
local username = Instance.new("TextLabel", frame)
username.AnchorPoint = Vector2.new(0.5, 0)
username.Position = UDim2.new(0.5, 0, 0.46, 0)
username.Size = UDim2.new(0.8, 0, 0.07, 0)
username.BackgroundTransparency = 1
username.Font = Enum.Font.FredokaOne -- mirip Kenilla, gaya handwriting halus
username.Text = "Hello " .. player.Name .. "!"
username.TextColor3 = Color3.fromRGB(255, 255, 255)
username.TextScaled = true

-- Animasi teks berulang
task.spawn(function()
	while task.wait(3.5) do
		local t1 = TweenService:Create(username, TweenInfo.new(0.4), {TextTransparency = 1})
		t1:Play()
		t1.Completed:Wait()
		username.Text = "Masukkan key dulu"
		local t2 = TweenService:Create(username, TweenInfo.new(0.4), {TextTransparency = 0})
		t2:Play()
		task.wait(2.5)
		local t3 = TweenService:Create(username, TweenInfo.new(0.4), {TextTransparency = 1})
		t3:Play()
		t3.Completed:Wait()
		username.Text = "Hello " .. player.Name .. "!"
		local t4 = TweenService:Create(username, TweenInfo.new(0.4), {TextTransparency = 0})
		t4:Play()
	end
end)

-- Input key
local input = Instance.new("TextBox", frame)
input.AnchorPoint = Vector2.new(0.5, 0)
input.Position = UDim2.new(0.5, 0, 0.57, 0)
input.Size = UDim2.new(0.8, 0, 0.1, 0)
input.PlaceholderText = "Masukkan key..."
input.Font = Enum.Font.Gotham
input.TextSize = 18
input.TextColor3 = Color3.fromRGB(255,255,255)
input.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
input.Text = ""
local inputCorner = Instance.new("UICorner", input)
inputCorner.CornerRadius = UDim.new(0, 10)

-- Tombol Login
local loginBtn = Instance.new("TextButton", frame)
loginBtn.AnchorPoint = Vector2.new(0.5, 0)
loginBtn.Position = UDim2.new(0.5, 0, 0.71, 0)
loginBtn.Size = UDim2.new(0.8, 0, 0.1, 0)
loginBtn.BackgroundColor3 = Color3.fromRGB(120, 100, 255)
loginBtn.Text = "Login"
loginBtn.Font = Enum.Font.GothamBold
loginBtn.TextSize = 20
loginBtn.TextColor3 = Color3.new(1,1,1)
local loginCorner = Instance.new("UICorner", loginBtn)
loginCorner.CornerRadius = UDim.new(0, 10)

-- Tombol Get Key
local getKeyBtn = Instance.new("TextButton", frame)
getKeyBtn.AnchorPoint = Vector2.new(0.5, 0)
getKeyBtn.Position = UDim2.new(0.5, 0, 0.83, 0)
getKeyBtn.Size = UDim2.new(0.8, 0, 0.1, 0)
getKeyBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
getKeyBtn.Text = "Get Key"
getKeyBtn.Font = Enum.Font.GothamBold
getKeyBtn.TextSize = 20
getKeyBtn.TextColor3 = Color3.new(1,1,1)
local getKeyCorner = Instance.new("UICorner", getKeyBtn)
getKeyCorner.CornerRadius = UDim.new(0, 10)

-- Status label
local status = Instance.new("TextLabel", frame)
status.AnchorPoint = Vector2.new(0.5, 0)
status.Position = UDim2.new(0.5, 0, 0.94, 0)
status.Size = UDim2.new(0.8, 0, 0.05, 0)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Gotham
status.TextSize = 14
status.TextColor3 = Color3.fromRGB(255, 200, 120)
status.Text = ""

-- Validasi Key
local function validateKey(key)
	local body = "key=" .. HttpService:UrlEncode(key)
	local request = (http_request or request or syn and syn.request)
	if not request then return false, "Executor tidak mendukung HTTP request" end

	local response = request({
		Url = validateEndpoint,
		Method = "POST",
		Headers = {["Content-Type"] = "application/x-www-form-urlencoded"},
		Body = body
	})
	if not response or not response.Body then
		return false, "Tidak dapat terhubung ke server"
	end

	local ok, data = pcall(function() return HttpService:JSONDecode(response.Body) end)
	if not ok or not data then
		return false, "Respon server tidak valid"
	end

	if data.valid == true then
		local sisa = tonumber(data.expires_in_seconds or 0)
		local jam = math.floor(sisa / 3600)
		local menit = math.floor((sisa % 3600) / 60)
		return true, ("Key aktif %d jam %d menit lagi"):format(jam, menit)
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

print("[✅] Botresi Hub Final UI aktif dengan animasi teks & soft shadow.")
