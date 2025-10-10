--[[
WS • Auto Walk (Obsidian UI v2.0)
✅ Pause / Resume
✅ Smart Play (nearest)
✅ Replay Speed control
✅ Save record to Folder "AutoWalk"
✅ Full feature restoration
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
		local dir = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z).Unit
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
-- RECORD & STOP RECORD
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

	-- buat folder AutoWalk di device executor
	local folder = "AutoWalk"
	if not isfolder(folder) then makefolder(folder) end

	local filename = folder .. "/record_" .. os.date("%Y%m%d_%H%M%S") .. ".json"
	local data = serializePlatformData()
	writefile(filename, data)
	UpdateStatus("Saved to " .. filename)
end

----------------------------------------------------------
-- REPLAY LOGIC
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
					pausedState = {isPaused=true, platformIndex=i, movementIndex=j, skipPathfind=true}
					stopForceMovement()
					UpdateStatus("Paused")
					return
				end
				local a, b = moves[j], moves[j+1]
				local startTime, duration = tick(), ((b.position - a.position).Magnitude * 0.01) / ReplaySpeed
				while tick() - startTime < duration do
					if shouldStopReplay or shouldPauseReplay then break end
					local alpha = math.clamp((tick() - startTime) / duration, 0, 1)
					local pos = a.position:Lerp(b.position, alpha)
					character:SetPrimaryPartCFrame(CFrame.new(pos))
					RunService.Heartbeat:Wait()
				end
			end
			stopForceMovement()
		end
	end

	UpdateStatus("Completed ✅")
	replaying = false
end

local function PauseReplay() if replaying then shouldPauseReplay = true end end
local function ResumeReplay()
	if not pausedState.isPaused then return UpdateStatus("No paused replay") end
	local p, m, s = pausedState.platformIndex, pausedState.movementIndex, pausedState.skipPathfind
	pausedState.isPaused = false
	task.spawn(function() ReplayFrom(p, m, s) end)
end

local function StopReplay()
	if replaying then shouldStopReplay = true replaying = false stopForceMovement() end
	UpdateStatus("Stopped ⛔")
end

----------------------------------------------------------
-- OBSIDIAN UI
----------------------------------------------------------
local Window = Library:CreateWindow({Title="WS",Footer="Auto Walk (v2.0)",Icon=95816097006870,ShowCustomCursor=true})
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
-- MAIN CONTROL TAB
----------------------------------------------------------
local M = Tabs.Main:AddLeftGroupbox("Actions")
M:AddButton("Record", StartRecord)
M:AddButton("Stop Record", StopRecord)
M:AddButton("Stop Replay", StopReplay)

----------------------------------------------------------
-- AUTO WALK TAB
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
A:AddButton("⏸ Pause", PauseReplay)
A:AddButton("⏵ Resume", ResumeReplay)
A:AddButton("⛔ Stop", StopReplay)
A:AddSlider("Speed", {Text="Replay Speed", Min=0.5, Max=3, Default=1, Rounding=1, Compact=false, Callback=function(v)
	ReplaySpeed = v
	UpdateStatus("Speed x"..v)
end})

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
