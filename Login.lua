--// LOGIN UI by WANDEV v3 (Kotak + Border Neon)
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-- CONFIG
local validKey = "123"
local scriptURL = "loadstring(game:HttpGet("https://raw.githubusercontent.com/WannBot/Walk/refs/heads/main/auto%20walk.lua"))()"
local getKeyURL = "https://your-getkey-url.com/"

-- GUI SETUP
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "KeyLoginUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false

-- FRAME UTAMA (lebih kotak & responsive)
local frame = Instance.new("Frame", screenGui)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.new(0.5, 0, 0.5, 0)
frame.Size = UDim2.new(0.8, 0, 0.6, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
frame.BorderSizePixel = 0
frame.ClipsDescendants = true

-- BORDER NEON CYAN (tanpa efek gerak)
local border = Instance.new("UIStroke", frame)
border.Thickness = 3
border.Color = Color3.fromRGB(0, 255, 255)
border.Transparency = 0.4

-- ANIMASI PULSASI BORDER (soft glow)
task.spawn(function()
	while frame.Parent do
		local pulseOut = TweenService:Create(border, TweenInfo.new(1.2), {Transparency = 0.15})
		pulseOut:Play()
		pulseOut.Completed:Wait()
		local pulseIn = TweenService:Create(border, TweenInfo.new(1.2), {Transparency = 0.4})
		pulseIn:Play()
		pulseIn.Completed:Wait()
	end
end)

-- AVATAR PLAYER
local avatar = Instance.new("ImageLabel", frame)
avatar.AnchorPoint = Vector2.new(0, 0.5)
avatar.Position = UDim2.new(0.06, 0, 0.5, 0)
avatar.Size = UDim2.new(0.32, 0, 0.55, 0)
avatar.BackgroundTransparency = 1
avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId="..player.UserId.."&width=150&height=150&format=png"

-- TEKS "HELLO USERNAME"
local hello = Instance.new("TextLabel", frame)
hello.AnchorPoint = Vector2.new(0, 0)
hello.Position = UDim2.new(0.43, 0, 0.12, 0)
hello.Size = UDim2.new(0.5, 0, 0.12, 0)
hello.Font = Enum.Font.GothamBold
hello.TextSize = 24
hello.TextColor3 = Color3.fromRGB(255, 255, 0)
hello.BackgroundTransparency = 1
hello.TextXAlignment = Enum.TextXAlignment.Left
hello.Text = ""

-- ANIMASI MENGETIK
local textToType = "Hello " .. player.Name .. "!"
task.spawn(function()
	for i = 1, #textToType do
		hello.Text = string.sub(textToType, 1, i)
		task.wait(0.05)
	end
end)

-- INPUT KEY
local input = Instance.new("TextBox", frame)
input.AnchorPoint = Vector2.new(0, 0)
input.Position = UDim2.new(0.43, 0, 0.33, 0)
input.Size = UDim2.new(0.5, 0, 0.13, 0)
input.PlaceholderText = "Masukkan key..."
input.Font = Enum.Font.Gotham
input.TextSize = 18
input.TextColor3 = Color3.new(1, 1, 1)
input.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
input.Text = ""

-- UNLOCK BUTTON
local unlockBtn = Instance.new("TextButton", frame)
unlockBtn.AnchorPoint = Vector2.new(0, 0)
unlockBtn.Position = UDim2.new(0.43, 0, 0.52, 0)
unlockBtn.Size = UDim2.new(0.5, 0, 0.13, 0)
unlockBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 120)
unlockBtn.Text = "UNLOCK"
unlockBtn.Font = Enum.Font.GothamBold
unlockBtn.TextSize = 20
unlockBtn.TextColor3 = Color3.new(0,0,0)
unlockBtn.AutoButtonColor = true

-- COPY URL BUTTON
local copyBtn = Instance.new("TextButton", frame)
copyBtn.AnchorPoint = Vector2.new(0, 0)
copyBtn.Position = UDim2.new(0.43, 0, 0.7, 0)
copyBtn.Size = UDim2.new(0.5, 0, 0.13, 0)
copyBtn.BackgroundColor3 = Color3.fromRGB(100, 140, 255)
copyBtn.Text = "COPY URL"
copyBtn.Font = Enum.Font.GothamBold
copyBtn.TextSize = 20
copyBtn.TextColor3 = Color3.new(1,1,1)

-- STATUS LABEL
local statusLabel = Instance.new("TextLabel", frame)
statusLabel.AnchorPoint = Vector2.new(0, 0)
statusLabel.Position = UDim2.new(0.43, 0, 0.86, 0)
statusLabel.Size = UDim2.new(0.5, 0, 0.1, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 16
statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
statusLabel.Text = ""

-- FUNGSI TOMBOL
unlockBtn.MouseButton1Click:Connect(function()
	local key = input.Text
	if key == validKey then
		statusLabel.Text = "✅ Key benar! Memuat script..."
		task.wait(1)
		frame:Destroy()
		loadstring(game:HttpGet(scriptURL))()
	else
		statusLabel.Text = "❌ Key salah, coba lagi!"
	end
end)

copyBtn.MouseButton1Click:Connect(function()
	setclipboard(getKeyURL)
	statusLabel.Text = "🔗 URL disalin ke clipboard!"
end)
