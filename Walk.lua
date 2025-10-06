-- ___ LocalScript ___
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local hrp = char:WaitForChild("HumanoidRootPart")

-- Load WindUI dari GitHub main.lua (example entry point)
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/main.lua"))()

-- (Pastikan `main.lua` yang kamu load sudah melakukan require ke file inti UI)

-- STATE
local walkEnabled, jumpEnabled, noclipEnabled = false, false, false
local walkSpeedValue, jumpPowerValue = 16, 50
local autoWalkActive = false

-- Noclip loop
RunService.Stepped:Connect(function()
	if noclipEnabled and player.Character then
		for _, part in ipairs(player.Character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end
end)

-- Fungsinya
local function applyWalk()
	if walkEnabled then
		hum.WalkSpeed = walkSpeedValue
	else
		hum.WalkSpeed = 16
	end
end

local function applyJump()
	if jumpEnabled then
		hum.JumpPower = jumpPowerValue
	else
		hum.JumpPower = 50
	end
end

local function stopAutoWalk()
	autoWalkActive = false
end

local function playPathFile(filename)
	if not isfile(filename .. ".json") then
		warn("Path file tidak ditemukan:", filename)
		return
	end
	autoWalkActive = true
	local json = readfile(filename .. ".json")
	local pts = HttpService:JSONDecode(json)
	for _, p in ipairs(pts) do
		if not autoWalkActive then break end
		local target = Vector3.new(p.X, p.Y, p.Z)
		hum:MoveTo(target)
		hum.MoveToFinished:Wait()
	end
	autoWalkActive = false
end

-- UI Setup dengan WindUI
local Window = WindUI:CreateWindow({
	Name = "Controller",
	ConfigurationSaving = false
})

-- Tab Main
local TabMain = Window:CreateTab("Main Fiture")
TabMain:CreateDropdown({
	Name = "WalkSpeed",
	Options = {"10","16","25","35","50"},
	CurrentOption = {"16"},
	Callback = function(opt)
		walkSpeedValue = tonumber(opt[1])
		applyWalk()
	end
})
TabMain:CreateToggle({
	Name = "WalkSpeed ON/OFF",
	CurrentValue = false,
	Callback = function(state)
		walkEnabled = state
		applyWalk()
	end
})
TabMain:CreateDropdown({
	Name = "JumpPower",
	Options = {"25","50","75","100","150"},
	CurrentOption = {"50"},
	Callback = function(opt)
		jumpPowerValue = tonumber(opt[1])
		applyJump()
	end
})
TabMain:CreateToggle({
	Name = "JumpPower ON/OFF",
	CurrentValue = false,
	Callback = function(state)
		jumpEnabled = state
		applyJump()
	end
})
TabMain:CreateToggle({
	Name = "NoClip ON/OFF",
	CurrentValue = false,
	Callback = function(state)
		noclipEnabled = state
	end
})

-- Tab Auto Walk
local TabAuto = Window:CreateTab("Auto Walk")
TabAuto:CreateLabel("Map: Antartika")
TabAuto:CreateToggle({
	Name = "PLAY ALL",
	CurrentValue = false,
	Callback = function(state)
		if state then
			-- jalankan semua path secara berurutan
			task.spawn(function()
				playPathFile("Path1")
				if not state then return end
				playPathFile("Path2")
				if not state then return end
				playPathFile("Path3")
				if not state then return end
				playPathFile("Path4")
			end)
		else
			stopAutoWalk()
		end
	end
})
TabAuto:CreateToggle({
	Name = "BC > CP1",
	CurrentValue = false,
	Callback = function(state)
		if state then playPathFile("Path1") else stopAutoWalk() end
	end
})
TabAuto:CreateToggle({
	Name = "CP1 > CP2",
	CurrentValue = false,
	Callback = function(state)
		if state then playPathFile("Path2") else stopAutoWalk() end
	end
})
TabAuto:CreateToggle({
	Name = "CP2 > CP3",
	CurrentValue = false,
	Callback = function(state)
		if state then playPathFile("Path3") else stopAutoWalk() end
	end
})
TabAuto:CreateToggle({
	Name = "CP3 > CP4",
	CurrentValue = false,
	Callback = function(state)
		if state then playPathFile("Path4") else stopAutoWalk() end
	end
})
TabAuto:CreateToggle({
	Name = "CP4 > Finish",
	CurrentValue = false,
	Callback = function(state)
		if state then playPathFile("Path5") else stopAutoWalk() end
	end
})

-- Tab Setting
local TabSetting = Window:CreateTab("Setting")
TabSetting:CreateDropdown({
	Name = "Theme",
	Options = {"Dark","Light","Ocean","Emerald","Crimson"},
	CurrentOption = {"Dark"},
	Callback = function(opt)
		WindUI:SetTheme(opt[1])  -- atau method untuk ganti tema sesuai WindUI versi ini
	end
})
