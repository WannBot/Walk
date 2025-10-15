--// LOGIN UI by WANDEV v4 (Validasi Ketat Key dari Website)
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- CONFIG
local validateEndpoint = "https://botresi.xyz/keygen/api/validate.php"  -- endpoint validasi
local getKeyURL = "https://botresi.xyz/keygen/admin_generate.php"
local scriptURL = "https://your-domain.com/main.lua"

-- WAIT PlayerGui
repeat task.wait() until player:FindFirstChild("PlayerGui")
local parentGui = player:FindFirstChild("PlayerGui")

-- BLUR background
local blur = Instance.new("BlurEffect")
blur.Name = "LoginUIBlur"
blur.Size = 0
blur.Parent = Lighting
TweenService:Create(blur, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {Size = 10}):Play()

-- GUI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "KeyLoginUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = parentGui

-- Frame (kotak-ish)
local frame = Instance.new("Frame")
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.new(0.5, 0, 0.5, 0)
frame.Size = UDim2.new(0.78, 0, 0.6, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
frame.BorderSizePixel = 0
frame.Parent = screenGui

-- Border neon
local border = Instance.new("UIStroke")
border.Thickness = 3
border.Color = Color3.fromRGB(0, 255, 255)
border.Transparency = 0.35
border.Parent = frame
-- animasi glow border
task.spawn(function()
	while frame.Parent do
		local t1 = TweenService:Create(border, TweenInfo.new(1.6, Enum.EasingStyle.Sine), {Transparency = 0.08})
		t1:Play(); t1.Completed:Wait()
		local t2 = TweenService:Create(border, TweenInfo.new(1.6, Enum.EasingStyle.Sine), {Transparency = 0.35})
		t2:Play(); t2.Completed:Wait()
	end
end)

-- Avatar
local avatar = Instance.new("ImageLabel")
avatar.AnchorPoint = Vector2.new(0, 0.5)
avatar.Position = UDim2.new(0.06, 0, 0.5, 0)
avatar.Size = UDim2.new(0.32, 0, 0.55, 0)
avatar.BackgroundTransparency = 1
avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=150&height=150&format=png"
avatar.Parent = frame

-- Teks Hello (typing)
local hello = Instance.new("TextLabel")
hello.AnchorPoint = Vector2.new(0, 0)
hello.Position = UDim2.new(0.43, 0, 0.12, 0)
hello.Size = UDim2.new(0.5, 0, 0.12, 0)
hello.Font = Enum.Font.GothamBold
hello.TextSize = 24
hello.TextColor3 = Color3.fromRGB(255, 255, 0)
hello.BackgroundTransparency = 1
hello.TextXAlignment = Enum.TextXAlignment.Left
hello.Text = ""
hello.Parent = frame

task.spawn(function()
	local textToType = "Hello " .. player.Name .. "!"
	for i = 1, #textToType do
		hello.Text = string.sub(textToType, 1, i)
		task.wait(0.04)
	end
end)

-- Input key
local input = Instance.new("TextBox")
input.AnchorPoint = Vector2.new(0, 0)
input.Position = UDim2.new(0.43, 0, 0.33, 0)
input.Size = UDim2.new(0.5, 0, 0.13, 0)
input.PlaceholderText = "Masukkan key..."
input.Font = Enum.Font.Gotham
input.TextSize = 18
input.TextColor3 = Color3.new(1, 1, 1)
input.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
input.ClearTextOnFocus = false
input.Parent = frame

-- Unlock button
local unlockBtn = Instance.new("TextButton")
unlockBtn.AnchorPoint = Vector2.new(0, 0)
unlockBtn.Position = UDim2.new(0.43, 0, 0.52, 0)
unlockBtn.Size = UDim2.new(0.5, 0, 0.13, 0)
unlockBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 120)
unlockBtn.Text = "UNLOCK"
unlockBtn.Font = Enum.Font.GothamBold
unlockBtn.TextSize = 20
unlockBtn.TextColor3 = Color3.new(0,0,0)
unlockBtn.Parent = frame

-- Copy URL button
local copyBtn = Instance.new("TextButton")
copyBtn.AnchorPoint = Vector2.new(0, 0)
copyBtn.Position = UDim2.new(0.43, 0, 0.7, 0)
copyBtn.Size = UDim2.new(0.5, 0, 0.13, 0)
copyBtn.BackgroundColor3 = Color3.fromRGB(100, 140, 255)
copyBtn.Text = "COPY URL"
copyBtn.Font = Enum.Font.GothamBold
copyBtn.TextSize = 20
copyBtn.TextColor3 = Color3.new(1,1,1)
copyBtn.Parent = frame

-- Status label
local statusLabel = Instance.new("TextLabel")
statusLabel.AnchorPoint = Vector2.new(0, 0)
statusLabel.Position = UDim2.new(0.43, 0, 0.86, 0)
statusLabel.Size = UDim2.new(0.5, 0, 0.1, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 16
statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
statusLabel.Text = ""
statusLabel.Parent = frame

-- Fungsi validasi ketat (hanya terima valid = true dari server)
local function validateKeyStrict(key)
	if not key or key == "" then
		return false, "Key kosong"
	end
	local ok, resp = pcall(function()
		-- kirim POST form-urlencode
		local form = "key=" .. HttpService:UrlEncode(key)
		return HttpService:PostAsync(validateEndpoint, form, Enum.HttpContentType.ApplicationUrlEncoded, false)
	end)
	if not ok then
		return false, "Request gagal: " .. tostring(resp)
	end

	-- parse JSON
	local valid, parsed = nil, nil
	local success, data = pcall(function() return HttpService:JSONDecode(resp) end)
	if success and type(data) == "table" then
		-- server harus mengembalikan field "valid" = true
		if data.valid == true then
			valid = true
		else
			valid = false
		end
		parsed = data
	else
		-- jika bukan JSON, coba periksa kata "valid" di string
		local low = resp:lower()
		if low:find("valid") then
			valid = true
		elseif low:find("invalid") then
			valid = false
		else
			-- tak terdefinisi
			return false, "Respon tidak valid"
		end
	end

	if valid then
		return true, parsed
	else
		return false, parsed
	end
end

-- Cleanup UI & blur
local function cleanup()
	TweenService:Create(blur, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {Size = 0}):Play()
	if screenGui then screenGui:Destroy() end
	if blur.Parent then blur:Destroy() end
end

-- Tombol Unlock logic
unlockBtn.MouseButton1Click:Connect(function()
	local key = tostring(input.Text or ""):gsub("%s+", "")
	if key == "" then
		statusLabel.Text = "❗ Masukkan key!"
		return
	end

	statusLabel.Text = "⏳ Memeriksa key..."
	print("[Validate] Mengirim key:", key)
	local ok, result = validateKeyStrict(key)
	print("[Validate] Hasil:", ok, result)
	if ok then
		statusLabel.Text = "✅ Key valid! Memuat script..."
		task.wait(0.8)
		cleanup()
		local success, err = pcall(function()
			loadstring(game:HttpGet(scriptURL))()
		end)
		if not success then
			warn("[LoadMain] Gagal load script:", err)
		end
	else
		statusLabel.Text = "❌ Key tidak valid: " .. tostring(result)
	end
end)

copyBtn.MouseButton1Click:Connect(function()
	if setclipboard then
		setclipboard(getKeyURL)
		statusLabel.Text = "🔗 URL disalin ke clipboard!"
	else
		statusLabel.Text = "ℹ️ Clipboard tidak didukung"
	end
end)

print("[WANDEV] UI login siap, validasi endpoint:", validateEndpoint)
