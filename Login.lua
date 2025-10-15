--// LOGIN UI BY WANDEV (Mobile Friendly + Lightning Animation)
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-- CONFIG
local validKey = "RostoKey123" -- ubah sesuai key kamu
local scriptURL = "https://your-domain.com/main.lua" -- ubah ke URL loadstring kamu
local getKeyURL = "https://your-getkey-url.com/" -- link copy URL

-- GUI
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "KeyLoginUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false

-- FRAME UTAMA (Responsive)
local frame = Instance.new("Frame", screenGui)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.new(0.5, 0, 0.5, 0)
frame.Size = UDim2.new(0.9, 0, 0.55, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
frame.BorderSizePixel = 0
frame.BackgroundTransparency = 0.05
frame.ClipsDescendants = true

-- Efek Lightning (kilatan petir)
local lightning = Instance.new("Frame", frame)
lightning.BackgroundColor3 = Color3.fromRGB(255, 255, 200)
lightning.BackgroundTransparency = 1
lightning.BorderSizePixel = 0
lightning.Size = UDim2.new(1, 0, 1, 0)
lightning.ZIndex = 5

task.spawn(function()
	while true do
		local flash = TweenService:Create(lightning, TweenInfo.new(0.1), {BackgroundTransparency = 0.3})
		flash:Play()
		task.wait(0.1)
		local fade = TweenService:Create(lightning, TweenInfo.new(0.2), {BackgroundTransparency = 1})
		fade:Play()
		task.wait(math.random(3,7)) -- jeda kilat acak
	end
end)

-- AVATAR PLAYER
local avatar = Instance.new("ImageLabel", frame)
avatar.AnchorPoint = Vector2.new(0, 0.5)
avatar.Position = UDim2.new(0.05, 0, 0.5, 0)
avatar.Size = UDim2.new(0.35, 0, 0.6, 0)
avatar.BackgroundTransparency = 1
avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId="..player.UserId.."&width=150&height=150&format=png"

-- NAMA & HELLO
local hello = Instance.new("TextLabel", frame)
hello.AnchorPoint = Vector2.new(0, 0)
hello.Position = UDim2.new(0.45, 0, 0.1, 0)
hello.Size = UDim2.new(0.5, 0, 0.15, 0)
hello.Font = Enum.Font.GothamBold
hello.TextSize = 22
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
input.Position = UDim2.new(0.45, 0, 0.35, 0)
input.Size = UDim2.new(0.5, 0, 0.15, 0)
input.PlaceholderText = "Masukkan key..."
input.Font = Enum.Font.Gotham
input.TextSize = 18
input.TextColor3 = Color3.new(1, 1, 1)
input.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
input.Text = ""

-- UNLOCK BUTTON
local unlockBtn = Instance.new("TextButton", frame)
unlockBtn.AnchorPoint = Vector2.new(0, 0)
unlockBtn.Position = UDim2.new(0.45, 0, 0.55, 0)
unlockBtn.Size = UDim2.new(0.5, 0, 0.12, 0)
unlockBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 120)
unlockBtn.Text = "UNLOCK"
unlockBtn.Font = Enum.Font.GothamBold
unlockBtn.TextSize = 20
unlockBtn.TextColor3 = Color3.new(0,0,0)

-- COPY URL BUTTON
local copyBtn = Instance.new("TextButton", frame)
copyBtn.AnchorPoint = Vector2.new(0, 0)
copyBtn.Position = UDim2.new(0.45, 0, 0.7, 0)
copyBtn.Size = UDim2.new(0.5, 0, 0.12, 0)
copyBtn.BackgroundColor3 = Color3.fromRGB(100, 140, 255)
copyBtn.Text = "COPY URL"
copyBtn.Font = Enum.Font.GothamBold
copyBtn.TextSize = 20
copyBtn.TextColor3 = Color3.new(1,1,1)

-- STATUS TEXT
local statusLabel = Instance.new("TextLabel", frame)
statusLabel.AnchorPoint = Vector2.new(0, 0)
statusLabel.Position = UDim2.new(0.45, 0, 0.86, 0)
statusLabel.Size = UDim2.new(0.5, 0, 0.1, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 16
statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
statusLabel.Text = ""

-- BUTTON FUNCTIONS
unlockBtn.MouseButton1Click:Connect(function()
	local key = input.Text
	if key == validKey then
		statusLabel.Text = "⚡ Key benar! Memuat script..."
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
