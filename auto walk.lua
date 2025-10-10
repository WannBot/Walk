--[[
WS • Auto Walk (Obsidian UI v2.5)
- Fix orientasi avatar (no nyamping) via CFrame.lookAt (horizontal forward)
- Stop Record → tambahkan sebagai Path# di Tab "Data" (tidak langsung save ke disk)
- Tab "Data": Dropdown Path, ▶ Play, ⛔ Stop, 💾 Save All Paths (gabung), 🗑 Delete Last Path
- Replay Speed slider (0.5x - 3x)
]]

----------------------------------------------------------
-- DEPENDENCIES (Obsidian)
----------------------------------------------------------
local OBS_REPO = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(OBS_REPO.."Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(OBS_REPO.."addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(OBS_REPO.."addons/SaveManager.lua"))()

----------------------------------------------------------
-- SERVICES
----------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
player:WaitForChild("PlayerGui")

----------------------------------------------------------
-- GLOBAL STATES
----------------------------------------------------------
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local platforms, yellowPlatforms, platformData, yellowToRedMapping = {}, {}, {}, {}
local platformCounter, recording = 0, false

local replaying, shouldStopReplay, shouldPauseReplay = false, false, false
local pausedState = { isPaused=false, platformIndex=nil, movementIndex=nil, skipPathfind=false }
local currentPlatformIndex, totalPlatformsToPlay = 0, 0

local isClimbing = false
local forceActiveConnection = nil
local allConnections = {}
local forceSpeedMultiplier = 1.0
local ReplaySpeed = 1.0  -- default

-- Kumpulan hasil record (in-memory, bukan file)
-- setiap item: { name="Path 1", json="<serialized>" }
local RecordedPaths = {}

----------------------------------------------------------
-- HELPERS
----------------------------------------------------------
local function UpdateStatus(t)
	if getfenv().__WS_STATUS_LABEL then
		getfenv().__WS_STATUS_LABEL:SetText("Status: " .. t)
	end
end

local function setupCharacterForce(characterToSetup)
	local hum = characterToSetup:WaitForChild("Humanoid")
	hum.StateChanged:Connect(function(_, newState)
		isClimbing = (newState == Enum.HumanoidStateType.Climbing)
	end)
end
setupCharacterForce(character)

local function stopForceMovement()
	if forceActiveConnection then forceActiveConnection:Disconnect() forceActiveConnection=nil end
	local root = character.PrimaryPart
	if root then root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0) end
end

local function startForceMovement()
	if forceActiveConnection then return end
	forceActiveConnection = RunService.Heartbeat:Connect(function()
		local root, hum = character.PrimaryPart, character:FindFirstChildOfClass("Humanoid")
		if not root or not hum or isClimbing then return end
		local moveSpeed = hum.WalkSpeed * forceSpeedMultiplier * ReplaySpeed
		local dir = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
		if dir.Magnitude < 1e-5 then return end
		dir = dir.Unit
		local vel = dir * moveSpeed
		root.AssemblyLinearVelocity = Vector3.new(vel.X, root.AssemblyLinearVelocity.Y, vel.Z)
	end)
end

local function calculatePath(start, goal)
	local path = PathfindingService:CreatePath()
	path:ComputeAsync(start, goal)
	return path
end

----------------------------------------------------------
-- SERIALIZE & DESERIALIZE
----------------------------------------------------------
local function serializePlatformData()
	local data = { redPlatforms = {}, yellowPlatforms = {}, mappings = {} }
	for _, platform in ipairs(platforms) do
		local movementsData = {}
		for _, movement in ipairs(platformData[platform] or {}) do
			table.insert(movementsData, {
				position = { X = movement.position.X, Y = movement.position.Y, Z = movement.position.Z },
				orientation = { X = movement.orientation.X, Y = movement.orientation.Y, Z = movement.orientation.Z },
				isJumping = movement.isJumping
			})
		end
		table.insert(data.redPlatforms, {
			position = { X = platform.Position.X, Y = platform.Position.Y, Z = platform.Position.Z },
			movements = movementsData
		})
	end
	return HttpService:JSONEncode(data)
end

local function deserializePlatformData(jsonData)
	local ok, data = pcall(function() return HttpService:JSONDecode(jsonData) end)
	if not ok then return false end
	-- bersihkan world sebelumnya
	for _, p in ipairs(platforms) do p:Destroy() end
	platforms, platformData = {}, {}
	for _, info in ipairs(data.redPlatforms or {}) do
		local p = Instance.new("Part")
		p.Size = Vector3.new(5, 1, 5)
		p.Position = Vector3.new(info.position.X, info.position.Y, info.position.Z)
		p.Anchored = true
		p.BrickColor = BrickColor.Red()
		p.CanCollide = false
		p.Parent = workspace
		platformData[p] = {}
		for _, m in ipairs(info.movements or {}) do
			table.insert(platformData[p], {
				position = Vector3.new(m.position.X, m.position.Y, m.position.Z),
				orientation = Vector3.new(m.orientation.X, m.orientation.Y, m.orientation.Z),
				isJumping = m.isJumping
			})
		end
		table.insert(platforms, p)
	end
	UpdateStatus("Loaded platforms")
	return true
end

----------------------------------------------------------
-- RECORD & STOP RECORD (ke memory list)
----------------------------------------------------------
local function StartRecord()
	if recording then return end
	recording = true
	UpdateStatus("Recording...")
	platformCounter += 1

	local platform = Instance.new("Part")
	platform.Size = Vector3.new(5, 1, 5)
	platform.Position = character.PrimaryPart.Position - Vector3.new(0,3,0)
	platform.Anchored = true
	platform.BrickColor = BrickColor.Red()
	platform.CanCollide = false
	platform.Parent = workspace
	table.insert(platforms, platform)
	platformData[platform] = {}

	task.spawn(function()
		while recording do
			table.insert(platformData[platform], {
				position = character.PrimaryPart.Position,
				orientation = character.PrimaryPart.Orientation,
				isJumping = humanoid.Jump
			})
			RunService.Heartbeat:Wait()
		end
	end)
end

local function StopRecord()
	if not recording then return end
	recording = false
	UpdateStatus("Stopped Recording")

	-- masukkan hasil record ke list "RecordedPaths" (in-memory), tidak langsung save file
	local json = serializePlatformData()
	local idx = #RecordedPaths + 1
	table.insert(RecordedPaths, { name = ("Path %d"):format(idx), json = json })
	UpdateStatus(("Added to Data: Path %d"):format(idx))

	-- refresh UI Data list (dropdown)
	if getfenv().__WS_REFRESH_DATA then
		pcall(getfenv().__WS_REFRESH_DATA)
	end
end

----------------------------------------------------------
-- REPLAY LOGIC (Fix orientasi pakai lookAt)
----------------------------------------------------------
local function GetNearestPlatformIndexFromPosition(pos)
	if #platforms == 0 then return 1 end
	local best, bestDist = 1, math.huge
	for i, p in ipairs(platforms) do
		local d = (p.Position - pos).Magnitude
		if d < bestDist then bestDist = d best = i end
	end
	return best
end

local function walkToPlatform(dest)
	local hum, root = character:WaitForChild("Humanoid"), character:WaitForChild("HumanoidRootPart")
	local path = calculatePath(root.Position, dest)
	if path.Status == Enum.PathStatus.Success then
		for _, wp in ipairs(path:GetWaypoints()) do
			if shouldStopReplay or shouldPauseReplay then break end
			hum:MoveTo(wp.Position)
			if wp.Action == Enum.PathWaypointAction.Jump then hum.Jump = true end
			hum.MoveToFinished:Wait()
		end
	else
		hum:MoveTo(dest)
		hum.MoveToFinished:Wait()
	end
end

local function ReplayFrom(indexStart, movementStart, skipPath)
	totalPlatformsToPlay = #platforms
	currentPlatformIndex = indexStart or 1
	replaying, shouldStopReplay, shouldPauseReplay = true, false, false

	for i = currentPlatformIndex, #platforms do
		if shouldStopReplay then break end
		UpdateStatus(("Playing %d/%d"):format(i, totalPlatformsToPlay))
		local p = platforms[i]
		if not skipPath then walkToPlatform(p.Position + Vector3.new(0,3,0)) end

		local moves = platformData[p]
		if moves and #moves > 1 then
			startForceMovement()
			for j = movementStart or 1, #moves-1 do
				if shouldStopReplay or shouldPauseReplay then
					stopForceMovement()
					UpdateStatus("Stopped")
					return
				end
				local a, b = moves[j], moves[j+1]

				-- durasi di-scale oleh ReplaySpeed
				local distance = (b.position - a.position).Magnitude
				local duration = math.max(distance * 0.01, 0.01) / math.max(ReplaySpeed, 0.01)
				local t0, t1 = tick(), tick() + duration

				-- arah horizontal (hindari tilt Y), untuk lookAt
				local flatDir = Vector3.new((b.position - a.position).X, 0, (b.position - a.position).Z)
				if flatDir.Magnitude < 1e-4 then
					flatDir = character.PrimaryPart.CFrame.LookVector -- pertahankan arah sebelumnya
				else
					flatDir = flatDir.Unit
				end

				while tick() < t1 do
					if shouldStopReplay or shouldPauseReplay then break end
					local alpha = math.clamp((tick() - t0) / duration, 0, 1)
					local pos = a.position:Lerp(b.position, alpha)
					-- Rotasi realistik: arahkan menghadap ke depan (horizontal)
					local lookTarget = pos + Vector3.new(flatDir.X, 0, flatDir.Z)
					character:SetPrimaryPartCFrame(CFrame.lookAt(pos, lookTarget))
					if a.isJumping then humanoid.Jump = true end
					RunService.Heartbeat:Wait()
				end
			end
			stopForceMovement()
		end
	end

	UpdateStatus("Completed ✅")
	replaying = false
end

local function StopReplay()
	if replaying then shouldStopReplay = true replaying = false stopForceMovement() end
	UpdateStatus("Stopped ⛔")
end

----------------------------------------------------------
-- OBSIDIAN UI
----------------------------------------------------------
local Window = Library:CreateWindow({Title="WS",Footer="Auto Walk (v2.5)",Icon=95816097006870,ShowCustomCursor=true})
local Tabs = {
	Main  = Window:AddTab("Main Control","zap"),
	Auto  = Window:AddTab("Auto Walk","map-pin"),
	Data  = Window:AddTab("Data","folder"),
	Theme = Window:AddTab("Setting","settings"),
}

-- Status
local StatusBox = Tabs.Main:AddRightGroupbox("Status")
local statusLabel = StatusBox:AddLabel("Status: Idle")
getfenv().__WS_STATUS_LABEL = statusLabel

----------------------------------------------------------
-- MAIN CONTROL
----------------------------------------------------------
local M = Tabs.Main:AddLeftGroupbox("Actions")
M:AddButton("Record", StartRecord)
M:AddButton("Stop Record", StopRecord)
M:AddButton("Stop Replay", StopReplay)

----------------------------------------------------------
-- AUTO WALK (untuk source path online + speed)
----------------------------------------------------------
local A = Tabs.Auto:AddLeftGroupbox("Auto")
local PathList = {"https://raw.githubusercontent.com/WannBot/Walk/main/Antartika/allpath.json"}
local PathsLoaded = {}

A:AddButton("📥 Load Path", function()
	PathsLoaded = {}
	for _, url in ipairs(PathList) do
		local ok, data = pcall(function() return game:HttpGet(url) end)
		if ok and data then table.insert(PathsLoaded, data) end
	end
	UpdateStatus(("%d Path Loaded"):format(#PathsLoaded))
end)

A:AddButton("▶ Play (Nearest)", function()
	if #PathsLoaded == 0 then return UpdateStatus("No Path") end
	local rp = character:WaitForChild("HumanoidRootPart")
	for _, data in ipairs(PathsLoaded) do
		if deserializePlatformData(data) then
			local idx = GetNearestPlatformIndexFromPosition(rp.Position)
			task.spawn(function() ReplayFrom(idx) end)
		end
	end
end)

A:AddButton("⛔ Stop", StopReplay)

A:AddSlider("Speed", {
	Text="Replay Speed",
	Min=0.5, Max=3, Default=1, Rounding=1, Compact=false,
	Callback=function(v) ReplaySpeed = v UpdateStatus("Speed x"..v) end
})

----------------------------------------------------------
-- DATA TAB: daftar path hasil record + kontrol
----------------------------------------------------------
local DataLeft = Tabs.Data:AddLeftGroupbox("Recorded Paths")
local SelectedPathIndex = 1
local PathsDropdown = nil

local function buildPathNames()
	local names = {}
	for i, item in ipairs(RecordedPaths) do
		names[i] = item.name or ("Path "..i)
	end
	if #names == 0 then names = {"(no paths)"} end
	return names
end

local function refreshDataUI()
	local values = buildPathNames()
	if PathsDropdown then
		PathsDropdown:SetValues(values)
		PathsDropdown:SetValue(values[math.clamp(SelectedPathIndex,1,#values)])
	end
end

-- expose untuk dipanggil dari StopRecord
getfenv().__WS_REFRESH_DATA = refreshDataUI

PathsDropdown = DataLeft:AddDropdown("WS_PathsDD", {
	Values = buildPathNames(),
	Default = "Select Path",
	Multi = false,
	Text = "Paths",
	Callback = function(val)
		-- map text -> index
		for i, item in ipairs(RecordedPaths) do
			if item.name == val then SelectedPathIndex = i return end
		end
		-- jika "(no paths)"
		SelectedPathIndex = 1
	end
})

DataLeft:AddButton("Refresh", function()
	refreshDataUI()
	UpdateStatus("Data refreshed")
end)

-- ▶ Play per-path (pakai ReplayFrom tanpa Pause/Resume button khusus)
DataLeft:AddButton("▶ Play Selected", function()
	if #RecordedPaths == 0 then return UpdateStatus("No recorded paths") end
	local entry = RecordedPaths[math.clamp(SelectedPathIndex,1,#RecordedPaths)]
	if not entry or not entry.json then return UpdateStatus("Invalid path") end
	if deserializePlatformData(entry.json) then
		task.spawn(function() ReplayFrom(1) end)
	end
end)

-- ⛔ Stop per-path
DataLeft:AddButton("⛔ Stop Selected", function()
	StopReplay()
end)

-- 🗑 Hapus path terakhir dari memory list
DataLeft:AddButton("🗑 Delete Last Path", function()
	if #RecordedPaths == 0 then return UpdateStatus("No recorded paths") end
	table.remove(RecordedPaths, #RecordedPaths)
	UpdateStatus("Deleted last path from list")
	SelectedPathIndex = math.clamp(SelectedPathIndex,1,#RecordedPaths)
	refreshDataUI()
end)

-- 💾 Save All Paths (GABUNG ke satu file JSON)
DataLeft:AddButton("💾 Save All Paths", function()
	if #RecordedPaths == 0 then return UpdateStatus("Nothing to save") end
	local folder = "AutoWalk"
	if not isfolder(folder) then makefolder(folder) end

	-- gabungkan semua ke satu file: { paths: [ {name, data:<object>} ] }
	local bundle = { paths = {} }
	for _, item in ipairs(RecordedPaths) do
		local ok, obj = pcall(function() return HttpService:JSONDecode(item.json) end)
		if ok and type(obj) == "table" then
			table.insert(bundle.paths, { name = item.name, data = obj })
		end
	end
	local out = HttpService:JSONEncode(bundle)
	local filename = folder .. "/allpaths.json"
	writefile(filename, out)
	UpdateStatus("Saved → " .. filename)
end)

----------------------------------------------------------
-- THEME / CONFIG
----------------------------------------------------------
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
ThemeManager:SetFolder("WS_UI")
SaveManager:SetFolder("WS_UI/config")
SaveManager:BuildConfigSection(Tabs.Theme)
ThemeManager:ApplyToTab(Tabs.Theme)
Library.ToggleKeybind = Enum.KeyCode.RightShift

----------------------------------------------------------
-- RESPAWN SAFETY
----------------------------------------------------------
player.CharacterAdded:Connect(function(newChar)
	character = newChar
	humanoid = newChar:WaitForChild("Humanoid")
	setupCharacterForce(newChar)
	stopForceMovement()
	shouldStopReplay, shouldPauseReplay, replaying = true, false, false
	UpdateStatus("Idle (respawn)")
end)
