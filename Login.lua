--// LOGIN UI by WANDEV v5.1 (BotResi Key System - POST)
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- CONFIG
local validateEndpoint = "https://botresi.xyz/keygen/api/validate.php"
local getKeyURL = "https://botresi.xyz/keygen/admin_generate.php"
local scriptURL = "https://your-domain.com/main.lua"

-- Wait for PlayerGui
repeat task.wait() until player:FindFirstChild("PlayerGui")
local guiParent = player.PlayerGui

-- Blur background
local blur = Instance.new("BlurEffect", Lighting)
blur.Size = 0
TweenService:Create(blur, TweenInfo.new(0.4), {Size = 10}):Play()

-- ScreenGui
local screenGui = Instance.new("ScreenGui", guiParent)
screenGui.Name = "KeyLoginUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false

-- Frame (kotak elegan)
local frame = Instance.new("Frame", screenGui)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.new(0.5, 0, 0.5, 0)
frame.Size = UDim2.new(0.8, 0, 0.6, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
frame.BorderSizePixel = 0

-- Border Neon
local border = Instance.new("UIStroke", frame)
border.Thickness = 3
border.Color = Color3.fromRGB(0, 255, 255)
border.Transparency = 0.4
task.spawn(function()
	while frame.Parent do
		local a = TweenService:Create(border, TweenInfo.new(1.2), {Transparency = 0.1})
		a:Play(); a.Completed:Wait()
		local b = TweenService:Create(border, TweenInfo.new(1.2), {Transparency = 0.4})
		b:Play(); b.Completed:Wait()
	end
end)

-- Avatar
local avatar = Instance.new("ImageLabel", frame)
avatar.AnchorPoint = Vector2.new(0, 0.5)
avatar.Position = UDim2.new(0.06, 0, 0.5, 0)
avatar.Size = UDim2.new(0.32, 0, 0.55, 0)
avatar.BackgroundTransparency = 1
avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId="..player.UserId.."&width=150&height=150&format=png"

-- Hello text animation
local hello = Instance.new("TextLabel", frame)
hello.Position = UDim2.new(0.43, 0, 0.1, 0)
hello.Size = UDim2.new(0.5, 0, 0.12, 0)
hello.Font = Enum.Font.GothamBold
hello.TextSize = 24
hello.TextColor3 = Color3.fromRGB(255,255,0)
hello.BackgroundTransparency = 1
hello.TextXAlignment = Enum.TextXAlignment.Left
hello.Text = ""
task.spawn(function()
	local text = "Hello " .. player.Name .. "!"
	for i = 1, #text do
		hello.Text = string.sub(text, 1, i)
		task.wait(0.04)
	end
end)

-- Input key
local input = Instance.new("TextBox", frame)
input.Position = UDim2.new(0.43, 0, 0.33, 0)
input.Size = UDim2.new(0.5, 0, 0.13, 0)
input.PlaceholderText = "Masukkan key..."
input.Font = Enum.Font.Gotham
input.TextSize = 18
input.TextColor3 = Color3.new(1, 1, 1)
input.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
input.ClearTextOnFocus = false
input.Text = ""

-- Tombol Unlock
local unlockBtn = Instance.new("TextButton", frame)
unlockBtn.Position = UDim2.new(0.43, 0, 0.52, 0)
unlockBtn.Size = UDim2.new(0.5, 0, 0.13, 0)
unlockBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 120)
unlockBtn.Text = "UNLOCK"
unlockBtn.Font = Enum.Font.GothamBold
unlockBtn.TextSize = 20
unlockBtn.TextColor3 = Color3.new(0,0,0)

-- Tombol Copy URL
local copyBtn = Instance.new("TextButton", frame)
copyBtn.Position = UDim2.new(0.43, 0, 0.7, 0)
copyBtn.Size = UDim2.new(0.5, 0, 0.13, 0)
copyBtn.BackgroundColor3 = Color3.fromRGB(100, 140, 255)
copyBtn.Text = "COPY URL"
copyBtn.Font = Enum.Font.GothamBold
copyBtn.TextSize = 20
copyBtn.TextColor3 = Color3.new(1,1,1)

-- Status Label
local status = Instance.new("TextLabel", frame)
status.Position = UDim2.new(0.43, 0, 0.86, 0)
status.Size = UDim2.new(0.5, 0, 0.1, 0)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Gotham
status.TextSize = 16
status.TextColor3 = Color3.fromRGB(255,200,100)
status.Text = ""

-- Fungsi Validasi (POST)
local function validateKey(key)
	local ok, resp = pcall(function()
		local body = "key=" .. HttpService:UrlEncode(key)
		return HttpService:PostAsync(validateEndpoint, body, Enum.HttpContentType.ApplicationUrlEncoded, false)
	end)

	if not ok then
		return false, "Server error: " .. tostring(resp)
	end

	local low = string.lower(resp)
	if low:find("valid") and not low:find("invalid") then
		return true, resp
	else
		return false, resp
	end
end

-- Unlock Button
unlockBtn.MouseButton1Click:Connect(function()
	local key = string.gsub(input.Text or "", "%s+", "")
	if key == "" then
		status.Text = "❗ Masukkan key!"
		return
	end

	status.Text = "⏳ Memeriksa key..."
	local ok, resp = validateKey(key)
	if ok then
		status.Text = "✅ Key valid! Memuat script..."
		task.wait(1)
		TweenService:Create(blur, TweenInfo.new(0.3), {Size = 0}):Play()
		blur:Destroy()
		screenGui:Destroy()
		loadstring(game:HttpGet(scriptURL))()
	else
		status.Text = "❌ Key tidak valid."
		warn("[BotResi Response]:", resp)
	end
end)

-- Copy Button
copyBtn.MouseButton1Click:Connect(function()
	if setclipboard then
		setclipboard(getKeyURL)
		status.Text = "🔗 URL disalin ke clipboard!"
	else
		status.Text = "ℹ️ Clipboard tidak didukung"
	end
end)

print("[BotResi] UI login aktif — POST ke", validateEndpoint)
