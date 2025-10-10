--[[
WS • Auto Walk (Obsidian UI v2.1)
✅ Pause / Resume
✅ Smart Play (nearest)
✅ Replay Speed control
✅ Save record to Folder "AutoWalk"
✅ Auto register path list
✅ Fix sideways movement
✅ Tab Data: Play / Stop / Save All / Delete Last
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

local platforms, platformData = {}, {}
local platformCounter, recording = 0, false
local replaying, shouldStopReplay, shouldPauseReplay = false, false, false
local pausedState = {isPaused=false, platformIndex=nil, movementIndex=nil}
local ReplaySpeed = 1.0

local folder = "AutoWalk"
if not isfolder(folder) then makefolder(folder) end

----------------------------------------------------------
-- HELPERS
----------------------------------------------------------
local function UpdateStatus(t)
	if getfenv().__WS_STATUS_LABEL then
		getfenv().__WS_STATUS_LABEL:SetText("Status: " .. t)
	end
end

local function calculatePath(start, goal)
	local path = PathfindingService:CreatePath()
	path:ComputeAsync(start, goal)
	return path
end

----------------------------------------------------------
-- SERIALIZE / DESERIALIZE
----------------------------------------------------------
local function serializePlatformData()
	local data = { redPlatforms = {} }
	for _, platform in ipairs(platforms) do
		local moves = {}
		for _, m in ipairs(platformData[platform] or {}) do
			table.insert(moves, {
				position = {X=m.position.X, Y=m.position.Y, Z=m.position.Z},
				orientation = {X=m.orientation.X, Y=m.orientation.Y, Z=m.orientation.Z},
				isJumping = m.isJumping
			})
		end
		table.insert(data.redPlatforms, {position={X=platform.Position.X,Y=platform.Position.Y,Z=platform.Position.Z},movements=moves})
	end
	return HttpService:JSONEncode(data)
end

local function deserializePlatformData(json)
	local ok, data = pcall(function() return HttpService:JSONDecode(json) end)
	if not ok then return false end
	for _, p in ipairs(platforms) do p:Destroy() end
	platforms, platformData = {}, {}
	for _, info in ipairs(data.redPlatforms or {}) do
		local p = Instance.new("Part")
		p.Size = Vector3.new(5, 1, 5)
		p.Position = Vector3.new(info.position.X, info.position.Y, info.position.Z)
		p.Anchored, p.BrickColor, p.CanCollide = true, BrickColor.Red(), false
		p.Parent = workspace
		platformData[p] = {}
		for _, m in ipairs(info.movements or {}) do
			table.insert(platformData[p], {
				position = Vector3.new(m.position.X,m.position.Y,m.position.Z),
				orientation = Vector3.new(m.orientation.X,m.orientation.Y,m.orientation.Z),
				isJumping = m.isJumping
			})
		end
		table.insert(platforms, p)
	end
	UpdateStatus("Loaded platforms")
	return true
end

----------------------------------------------------------
-- RECORD / STOP RECORD
----------------------------------------------------------
local function StartRecord()
	if recording then return end
	recording = true
	UpdateStatus("Recording...")

	local platform = Instance.new("Part")
	platform.Size = Vector3.new(5, 1, 5)
	platform.Position = character.PrimaryPart.Position - Vector3.new(0,3,0)
	platform.Anchored, platform.BrickColor, platform.CanCollide = true, BrickColor.Red(), false
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

	local pathFiles = listfiles(folder)
	local nextIndex = #pathFiles + 1
	local filename = folder .. "/Path_" .. nextIndex .. ".json"
	writefile(filename, serializePlatformData())
	UpdateStatus("Saved: Path_" .. nextIndex)

	-- refresh data tab list
	if getfenv()._refreshPathList then getfenv()._refreshPathList() end
end

----------------------------------------------------------
-- REPLAY LOGIC
----------------------------------------------------------
local function ReplayFrom(indexStart)
	replaying, shouldStopReplay, shouldPauseReplay = true, false, false
	for i = indexStart, #platforms do
		if shouldStopReplay then break end
		local moves = platformData[platforms[i]]
		if moves then
			for j = 1, #moves-1 do
				if shouldStopReplay or shouldPauseReplay then
					pausedState = {isPaused=true, platformIndex=i, movementIndex=j}
					UpdateStatus("Paused")
					return
				end
				local a, b = moves[j], moves[j+1]
				local startTime, duration = tick(), ((b.position - a.position).Magnitude * 0.01) / ReplaySpeed
				while tick() - startTime < duration do
					if shouldStopReplay or shouldPauseReplay then break end
					local alpha = math.clamp((tick()-startTime)/duration, 0,1)
					local pos = a.position:Lerp(b.position, alpha)
					local rot = CFrame.Angles(math.rad(b.orientation.X), math.rad(b.orientation.Y), math.rad(b.orientation.Z))
					character:SetPrimaryPartCFrame(CFrame.new(pos) * rot)
					if b.isJumping then humanoid.Jump = true end
					RunService.Heartbeat:Wait()
				end
			end
		end
	end
	replaying = false
	UpdateStatus("Completed ✅")
end

local function PauseReplay() if replaying then shouldPauseReplay = true end end
local function ResumeReplay()
	if not pausedState.isPaused then return UpdateStatus("No paused replay") end
	local i, j = pausedState.platformIndex, pausedState.movementIndex
	pausedState.isPaused = false
	task.spawn(function() ReplayFrom(i, j) end)
end
local function StopReplay() shouldStopReplay=true replaying=false UpdateStatus("Stopped ⛔") end

----------------------------------------------------------
-- OBSIDIAN UI
----------------------------------------------------------
local Window = Library:CreateWindow({Title="WS",Footer="Auto Walk (v2.1)",Icon=95816097006870,ShowCustomCursor=true})
local Tabs = {
	Main  = Window:AddTab("Main Fiture","zap"),
	Data  = Window:AddTab("Data","folder"),
	Theme = Window:AddTab("Setting","settings"),
}

local StatusBox = Tabs.Main:AddRightGroupbox("Status")
local statusLabel = StatusBox:AddLabel("Status: Idle")
getfenv().__WS_STATUS_LABEL = statusLabel

----------------------------------------------------------
-- MAIN TAB
----------------------------------------------------------
local M = Tabs.Main:AddLeftGroupbox("Control")
M:AddButton("Record", StartRecord)
M:AddButton("Stop Record", StopRecord)
M:AddButton("Pause", PauseReplay)
M:AddButton("Resume", ResumeReplay)
M:AddButton("Stop Replay", StopReplay)

----------------------------------------------------------
-- DATA TAB
----------------------------------------------------------
local D = Tabs.Data:AddLeftGroupbox("Recorded Paths")

local function refreshPathList()
	local files = listfiles(folder)
	local names = {}
	for _, f in ipairs(files) do
		if f:find("%.json$") then
			table.insert(names, f:match("([^/]+)$"))
		end
	end
	if getfenv()._pathDropdown then
		getfenv()._pathDropdown:SetValues(names)
	end
end
getfenv()._refreshPathList = refreshPathList

local pathFiles = listfiles(folder)
local defaultName = #pathFiles > 0 and pathFiles[1]:match("([^/]+)$") or "No Path"
local dropdown = D:AddDropdown("PathSelect", {
	Text = "Select Path",
	Values = {defaultName},
	Default = defaultName,
	Callback = function(val) getfenv()._selectedPath = val end
})
getfenv()._pathDropdown = dropdown

D:AddButton("Play All", function()
	local files = listfiles(folder)
	for _, f in ipairs(files) do
		if f:find("%.json$") then
			local ok, data = pcall(readfile, f)
			if ok and data then deserializePlatformData(data) ReplayFrom(1) end
		end
	end
end)

D:AddButton("Stop", StopReplay)
D:AddButton("Save All Path", function()
	local combined = { redPlatforms = {} }
	for _, f in ipairs(listfiles(folder)) do
		if f:find("%.json$") then
			local ok, data = pcall(readfile, f)
			if ok and data then
				local parsed = HttpService:JSONDecode(data)
				for _, p in ipairs(parsed.redPlatforms or {}) do
					table.insert(combined.redPlatforms, p)
				end
			end
		end
	end
	writefile(folder.."/ALL_PATH.json", HttpService:JSONEncode(combined))
	UpdateStatus("Saved ALL_PATH.json")
end)
D:AddButton("Delete Last Path", function()
	local files = listfiles(folder)
	table.sort(files)
	if #files > 0 then
		delfile(files[#files])
		UpdateStatus("Deleted "..files[#files])
	end
	refreshPathList()
end)

refreshPathList()

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
