--// LOGIN UI by WANDEV v3.2 (Blur + Remote Key Validation)
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- CONFIG
local validateEndpoint = "https://botresi.xyz/keygen/api/validate.php"
local getKeyURL = "https://botresi.xyz/keygen/admin_generate.php"
local scriptURL = "https://your-domain.com/main.lua"          -- ubah sesuai URL loadstring utama
-- (tidak lagi pakai local validKey; server yang validasi)

-- WAIT UNTIL PlayerGui READY
repeat task.wait() until player:FindFirstChild("PlayerGui")
local parentGui = player:FindFirstChild("PlayerGui")

-- CREATE BLUR (will be removed on close)
local blur = Instance.new("BlurEffect")
blur.Name = "LoginUIBlur"
blur.Size = 0
blur.Parent = Lighting

-- Tween in blur
local blurTween = TweenService:Create(blur, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {Size = 10})
blurTween:Play()

-- CREATE SCREENGUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "KeyLoginUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = parentGui

-- MAIN FRAME (square-ish, responsive)
local frame = Instance.new("Frame")
frame.Name = "MainFrame"
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.new(0.5, 0, 0.5, 0)
frame.Size = UDim2.new(0.78, 0, 0.6, 0) -- kotak-ish, responsive
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
frame.BorderSizePixel = 0
frame.Parent = screenGui

-- UIStroke (neon border with soft pulse)
local border = Instance.new("UIStroke")
border.Thickness = 3
border.Color = Color3.fromRGB(0, 255, 255)
border.Transparency = 0.35
border.Parent = frame

task.spawn(function()
	while frame.Parent do
		local t1 = TweenService:Create(border, TweenInfo.new(1.6, Enum.EasingStyle.Sine), {Transparency = 0.08})
		t1:Play(); t1.Completed:Wait()
		local t2 = TweenService:Create(border, TweenInfo.new(1.6, Enum.EasingStyle.Sine), {Transparency = 0.35})
		t2:Play(); t2.Completed:Wait()
	end
end)

-- AVATAR
local avatar = Instance.new("ImageLabel")
avatar.AnchorPoint = Vector2.new(0, 0.5)
avatar.Position = UDim2.new(0.06, 0, 0.5, 0)
avatar.Size = UDim2.new(0.32, 0, 0.55, 0)
avatar.BackgroundTransparency = 1
avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=150&height=150&format=png"
avatar.Parent = frame

-- HELLO TEXT (typewriter)
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

local textToType = "Hello " .. player.Name .. "!"
task.spawn(function()
	for i = 1, #textToType do
		hello.Text = string.sub(textToType, 1, i)
		task.wait(0.04)
	end
end)

-- INPUT KEY
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

-- UNLOCK BUTTON
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

-- COPY URL BUTTON
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

-- STATUS
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

-- Helper: safe HTTP POST trying JSON then form-encoded
local function tryValidateKey(key)
	-- returns success(boolean), responseText (string)
	if not key or key == "" then
		return false, "empty key"
	end

	-- 1) Try JSON POST (Content-Type: application/json)
	local ok, resp = pcall(function()
		local body = HttpService:JSONEncode({ key = key })
		return HttpService:PostAsync(validateEndpoint, body, Enum.HttpContentType.ApplicationJson, false)
	end)
	if ok then
		print("[KeyCheck] JSON POST response:", resp)
		return true, resp
	end
	print("[KeyCheck] JSON POST failed:", resp)

	-- 2) Try form-urlencoded POST (key=...)
	local ok2, resp2 = pcall(function()
		local form = "key=" .. HttpService:UrlEncode(key)
		return HttpService:PostAsync(validateEndpoint, form, Enum.HttpContentType.ApplicationUrlEncoded, false)
	end)
	if ok2 then
		print("[KeyCheck] Form POST response:", resp2)
		return true, resp2
	end
	print("[KeyCheck] Form POST failed:", resp2)

	-- 3) Try GET fallback (if server allows it)
	local ok3, resp3 = pcall(function()
		local url = validateEndpoint .. "?key=" .. HttpService:UrlEncode(key)
		return HttpService:GetAsync(url, true)
	end)
	if ok3 then
		print("[KeyCheck] GET response:", resp3)
		return true, resp3
	end
	print("[KeyCheck] GET failed:", resp3)

	return false, "all requests failed"
end

-- parse common JSON response safely
local function parseValidFromResponse(respText)
	if not respText or respText == "" then return nil, "empty response" end
	-- try JSON decode
	local ok, data = pcall(function() return HttpService:JSONDecode(respText) end)
	if ok and type(data) == "table" then
		-- common keys: valid, status, success, message, meta.valid
		if data.valid ~= nil then return data.valid, data end
		if data.success ~= nil then return data.success == true, data end
		if data.status ~= nil and tostring(data.status):lower() == "ok" then return true, data end
		-- nested meta.valid
		if data.meta and data.meta.valid ~= nil then return data.meta.valid, data end
		-- sometimes response includes code/message
		if data.message and tostring(data.message):lower():match("valid") then return true, data end
		return nil, data
	end
	-- not JSON — try simple text
	local lower = tostring(respText):lower()
	if lower:find("valid") or lower:find("true") then return true, respText end
	if lower:find("invalid") or lower:find("false") then return false, respText end
	return nil, respText
end

-- CLEANUP function when UI closed
local function cleanupAndClose()
	-- tween blur out
	local out = TweenService:Create(blur, TweenInfo.new(0.45, Enum.EasingStyle.Sine), {Size = 0})
	out:Play()
	out.Completed:Wait()
	if blur and blur.Parent then blur:Destroy() end
	if screenGui and screenGui.Parent then screenGui:Destroy() end
end

-- BUTTONS BEHAVIOR
unlockBtn.MouseButton1Click:Connect(function()
	local key = tostring(input.Text or ""):gsub("%s+", "")
	if key == "" then
		statusLabel.Text = "❗ Masukkan key dulu."
		return
	end

	statusLabel.Text = "⏳ Memeriksa key..."
	print("[KeyCheck] mencoba memvalidasi key:", key)

	local ok, resp = tryValidateKey(key)
	if not ok then
		statusLabel.Text = "❌ Gagal menghubungi server: "..tostring(resp)
		print("[KeyCheck] semua percobaan request gagal:", resp)
		return
	end

	-- parse
	local valid, parsed = parseValidFromResponse(resp)
	print("[KeyCheck] parse result:", valid, parsed)
	if valid == true then
		statusLabel.Text = "✅ Key valid! Memuat script..."
		task.wait(0.8)
		cleanupAndClose()
		-- load main script
		local success, err = pcall(function()
			loadstring(game:HttpGet(scriptURL))()
		end)
		if not success then
			warn("[LoadMain] gagal load script:", err)
		end
	elseif valid == false then
		statusLabel.Text = "❌ Key tidak valid."
	else
		-- unknown response: show raw and let user know
		statusLabel.Text = "⚠️ Respon tidak terduga. Cek console."
		warn("[KeyCheck] respon tidak jelas:", parsed)
	end
end)

copyBtn.MouseButton1Click:Connect(function()
	if setclipboard then
		setclipboard(getKeyURL)
		statusLabel.Text = "🔗 URL disalin ke clipboard!"
	else
		statusLabel.Text = "ℹ️ Executor tidak mendukung clipboard."
	end
end)

-- safety: if player leaves / respawn, cleanup
player.AncestryChanged:Connect(function()
	if not player:IsDescendantOf(game) then
		if blur and blur.Parent then blur:Destroy() end
	end
end)

print("[WANDEV] Login UI loaded — mencoba koneksi ke:", validateEndpoint)
