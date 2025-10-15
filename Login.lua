--// UI LOGIN BY WANDEV
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

-- CONFIG
local validKey = "RostoKey123" -- ubah key kamu di sini
local scriptURL = "https://your-domain.com/main.lua" -- ubah ke URL loadstring kamu

-- SCREEN GUI
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "KeyLogin"
screenGui.ResetOnSpawn = false

-- FRAME UTAMA
local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 520, 0, 280)
frame.Position = UDim2.new(0.5, -260, 0.5, -140)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
frame.BorderSizePixel = 0
frame.BackgroundTransparency = 0.05
frame.ClipsDescendants = true

-- FOTO AVATAR
local avatar = Instance.new("ImageLabel", frame)
avatar.Size = UDim2.new(0, 140, 0, 140)
avatar.Position = UDim2.new(0, 25, 0, 70)
avatar.BackgroundTransparency = 1
avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId="..player.UserId.."&width=150&height=150&format=png"

-- NAMA & HELLO
local hello = Instance.new("TextLabel", frame)
hello.Size = UDim2.new(0, 300, 0, 40)
hello.Position = UDim2.new(0, 180, 0, 40)
hello.Text = ""
hello.Font = Enum.Font.GothamBold
hello.TextSize = 22
hello.TextColor3 = Color3.fromRGB(255, 255, 0)
hello.BackgroundTransparency = 1

local username = player.Name
task.spawn(function()
	for i = 1, #("Hello "..username.."!") do
		hello.Text = string.sub("Hello "..username.."!", 1, i)
		task.wait(0.05)
	end
end)

-- INPUT KEY
local input = Instance.new("TextBox", frame)
input.PlaceholderText = "Masukkan key..."
input.Font = Enum.Font.Gotham
input.TextSize = 18
input.Size = UDim2.new(0, 280, 0, 40)
input.Position = UDim2.new(0, 180, 0, 100)
input.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
input.TextColor3 = Color3.new(1, 1, 1)
input.Text = ""

-- UNLOCK BUTTON
local unlockBtn = Instance.new("TextButton", frame)
unlockBtn.Size = UDim2.new(0, 280, 0, 40)
unlockBtn.Position = UDim2.new(0, 180, 0, 150)
unlockBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 120)
unlockBtn.Text = "UNLOCK"
unlockBtn.Font = Enum.Font.GothamBold
unlockBtn.TextSize = 20
unlockBtn.TextColor3 = Color3.new(0,0,0)

-- COPY URL BUTTON
local copyBtn = Instance.new("TextButton", frame)
copyBtn.Size = UDim2.new(0, 280, 0, 40)
copyBtn.Position = UDim2.new(0, 180, 0, 200)
copyBtn.BackgroundColor3 = Color3.fromRGB(100, 140, 255)
copyBtn.Text = "COPY URL"
copyBtn.Font = Enum.Font.GothamBold
copyBtn.TextSize = 20
copyBtn.TextColor3 = Color3.new(1,1,1)

-- STATUS
local statusLabel = Instance.new("TextLabel", frame)
statusLabel.Size = UDim2.new(0, 280, 0, 30)
statusLabel.Position = UDim2.new(0, 180, 0, 250)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 16
statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
statusLabel.Text = ""

-- BUTTON FUNCTION
unlockBtn.MouseButton1Click:Connect(function()
	local key = input.Text
	if key == validKey then
		statusLabel.Text = "✅ Key benar! Memuat script..."
		task.wait(1)
		frame:Destroy()
		loadstring(game:HttpGet(scriptURL))()
	else
		statusLabel.Text = "❌ Key salah, coba lagi."
	end
end)

copyBtn.MouseButton1Click:Connect(function()
	setclipboard("https://your-getkey-url.com/")
	statusLabel.Text = "🔗 URL disalin ke clipboard!"
end)
