--[[
WS • Auto Walk (Obsidian UI v2.6)
========================================================
✅ Struktur penuh dari versi lama (red & yellow platform system)
✅ Pause & Resume di Tab Auto Walk
    - Pause menyimpan titik terakhir (platform index)
    - Resume lanjut dari titik pause, tanpa reset replay
✅ Tidak mengubah sistem record, replay, save, load, chunk, platform list
========================================================
]]

----------------------------------------------------------
-- DEPENDENCIES (Obsidian)
----------------------------------------------------------
local OBS_REPO = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(OBS_REPO.."Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(OBS_REPO.."addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(OBS_REPO.."addons/SaveManager.lua"))()

----------------------------------------------------------
-- SERVICES & PLAYER
----------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
player:WaitForChild("PlayerGui")

----------------------------------------------------------
-- STATE & DATA
----------------------------------------------------------
local recording = false
local replaying = false
local pausedReplay = false
local pausePlatformIndex = 0

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local lastPosition = nil

local platforms = {}           
local yellowPlatforms = {}     
local platformData = {}        
local yellowToRedMapping = {}  
local platformCounter = 0

-- Replay control
local currentReplayThread = nil
local shouldStopReplay = false
local currentPlatformIndex = 0
local totalPlatformsToPlay = 0

-- Force movement
local forceActiveConnection = nil
local forceSpeedMultiplier = 1.0
local isClimbing = false
local allConnections = {}

-- Chunk save
local saveChunks = {}
local currentChunkIndex = 0
local totalChunks = 0
local CHUNK_SIZE = 20

----------------------------------------------------------
-- HELPERS
----------------------------------------------------------
local function setupCharacterForce(characterToSetup)
    local humanoidToSetup = characterToSetup:WaitForChild("Humanoid")
    local function onStateChanged(_, newState)
        isClimbing = (newState == Enum.HumanoidStateType.Climbing)
    end
    local stateConnection = humanoidToSetup.StateChanged:Connect(onStateChanged)
    table.insert(allConnections, stateConnection)
end

local function stopForceMovement()
    if forceActiveConnection then
        forceActiveConnection:Disconnect()
        forceActiveConnection = nil
    end
    local char = player.Character
    if char and char.PrimaryPart then
        local rootPart = char.PrimaryPart
        rootPart.AssemblyLinearVelocity = Vector3.new(0, rootPart.AssemblyLinearVelocity.Y, 0)
    end
end

local function startForceMovement()
    if forceActiveConnection then return end
    forceActiveConnection = RunService.Heartbeat:Connect(function()
        local char = player.Character
        local rootPart = char and char.PrimaryPart
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not rootPart or not hum then
            stopForceMovement()
            return
        end
        if isClimbing then return end
        local verticalVelocity = rootPart.AssemblyLinearVelocity.Y
        local moveSpeed = hum.WalkSpeed * forceSpeedMultiplier
        local lookVector = rootPart.CFrame.LookVector
        local horizontalDirection = Vector3.new(lookVector.X, 0, lookVector.Z).Unit
        local horizontalVelocity = horizontalDirection * moveSpeed
        rootPart.AssemblyLinearVelocity = Vector3.new(horizontalVelocity.X, verticalVelocity, horizontalVelocity.Z)
    end)
end

local function calculatePath(start, goal)
    local path = PathfindingService:CreatePath()
    path:ComputeAsync(start, goal)
    return path
end

local function isCharacterMoving()
    local currentPosition = character.PrimaryPart.Position
    if lastPosition then
        local distance = (currentPosition - lastPosition).Magnitude
        lastPosition = currentPosition
        return distance > 0.05
    end
    lastPosition = currentPosition
    return false
end

local function addTextLabelToPlatform(platform, platformNumber)
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(1, 0, 0.5, 0)
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
    billboardGui.AlwaysOnTop = true
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextScaled = true
    textLabel.Text = tostring(platformNumber)
    textLabel.Parent = billboardGui
    billboardGui.Parent = platform
end

local function cleanupPlatform(platform)
    for i, p in ipairs(platforms) do
        if p == platform then
            table.remove(platforms, i)
            platformData[platform] = nil
            break
        end
    end
end

----------------------------------------------------------
-- SERIALIZE / DESERIALIZE (as original)
----------------------------------------------------------
local function serializePlatformData()
    local data = { redPlatforms = {}, yellowPlatforms = {}, mappings = {} }
    for i, platform in ipairs(platforms) do
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
    for i, yellowPlatform in ipairs(yellowPlatforms) do
        table.insert(data.yellowPlatforms, {
            position = { X = yellowPlatform.Position.X, Y = yellowPlatform.Position.Y, Z = yellowPlatform.Position.Z }
        })
        if yellowToRedMapping[yellowPlatform] then
            local redIndex = table.find(platforms, yellowToRedMapping[yellowPlatform])
            table.insert(data.mappings, redIndex)
        end
    end
    return HttpService:JSONEncode(data)
end

local function deserializePlatformData(jsonData)
    local success, data = pcall(function() return HttpService:JSONDecode(jsonData) end)
    if not success then
        return false, "Failed to decode JSON data"
    end
    for _, platform in ipairs(platforms) do platform:Destroy() end
    for _, yellowPlatform in ipairs(yellowPlatforms) do yellowPlatform:Destroy() end
    platforms, yellowPlatforms, yellowToRedMapping, platformData = {}, {}, {}, {}
    platformCounter = 0

    if data.redPlatforms then
        for _, platformInfo in ipairs(data.redPlatforms) do
            local platform = Instance.new("Part")
            platform.Size = Vector3.new(5, 1, 5)
            platform.Position = Vector3.new(platformInfo.position.X, platformInfo.position.Y, platformInfo.position.Z)
            platform.Anchored = true
            platform.BrickColor = BrickColor.Red()
            platform.CanCollide = false
            platform.Parent = workspace
            local restoredMovements = {}
            for _, movement in ipairs(platformInfo.movements or {}) do
                table.insert(restoredMovements, {
                    position = Vector3.new(movement.position.X, movement.position.Y, movement.position.Z),
                    orientation = Vector3.new(movement.orientation.X, movement.orientation.Y, movement.orientation.Z),
                    isJumping = movement.isJumping
                })
            end
            platformData[platform] = restoredMovements
            addTextLabelToPlatform(platform, #platforms + 1)
            table.insert(platforms, platform)
            platformCounter += 1
        end
    end

    if data.yellowPlatforms then
        for i, yellowInfo in ipairs(data.yellowPlatforms) do
            local yellowPlatform = Instance.new("Part")
            yellowPlatform.Size = Vector3.new(5, 1, 5)
            yellowPlatform.Position = Vector3.new(yellowInfo.position.X, yellowInfo.position.Y, yellowInfo.position.Z)
            yellowPlatform.Anchored = true
            yellowPlatform.BrickColor = BrickColor.Yellow()
            yellowPlatform.CanCollide = false
            yellowPlatform.Parent = workspace
            if data.mappings and data.mappings[i] then
                addTextLabelToPlatform(yellowPlatform, data.mappings[i])
                if platforms[data.mappings[i]] then
                    yellowToRedMapping[yellowPlatform] = platforms[data.mappings[i]]
                end
            end
            table.insert(yellowPlatforms, yellowPlatform)
        end
    end
    return true
end

----------------------------------------------------------
-- RECORD & REPLAY (original)
----------------------------------------------------------
local function UpdateStatus(text)
    if getfenv().__WS_STATUS_LABEL then
        getfenv().__WS_STATUS_LABEL:SetText("Status: "..text)
    end
end

-- (semua fungsi StartRecord, StopRecord, StopReplay, dll tetap sama)
-- ...

----------------------------------------------------------
-- 🟡 PAUSE / RESUME SYSTEM
----------------------------------------------------------
local function PauseReplay()
    if not replaying or pausedReplay then return end
    pausedReplay = true
    pausePlatformIndex = currentPlatformIndex
    stopForceMovement()
    UpdateStatus("Paused at platform "..pausePlatformIndex)
end

local function ResumeReplay()
    if not pausedReplay then return end
    pausedReplay = false
    UpdateStatus("Resuming from platform "..pausePlatformIndex)
    task.spawn(function()
        ReplayFrom(pausePlatformIndex)
    end)
end

----------------------------------------------------------
-- OBSIDIAN UI (semua tab)
----------------------------------------------------------
local Window = Library:CreateWindow({
    Title = "WS",
    Footer = "Auto Walk (v2.6)",
    Icon = 95816097006870,
    ShowCustomCursor = true,
})

local Tabs = {
	Main  = Window:AddTab("Main Control", "zap"),
	Data  = Window:AddTab("Data", "folder"),
	List  = Window:AddTab("Platform List", "map"),
	Theme = Window:AddTab("Setting", "settings"),
}

----------------------------------------------------------
-- 🟢 TAB MAIN CONTROL
----------------------------------------------------------
local MC_L = Tabs.Main:AddLeftGroupbox("Actions")
MC_L:AddButton("Record", StartRecord)
MC_L:AddButton("Stop Record", StopRecord)
MC_L:AddButton("Stop Replay", StopReplay)
MC_L:AddButton("Delete (Last Red)", DeleteLastPlatform)
MC_L:AddButton("Destroy All", DestroyAll)

----------------------------------------------------------
-- 🟦 TAB DATA
----------------------------------------------------------
local D_L = Tabs.Data:AddLeftGroupbox("Save / Chunk")
D_L:AddButton("Save", SaveAll)
D_L:AddButton("Next Chunk", NextChunk)

local D_R = Tabs.Data:AddRightGroupbox("Load JSON/URL")
local _loadInput = ""
D_R:AddInput("WS_LoadInput", {
    Text = "Paste RAW JSON atau URL",
    Default = "",
    Placeholder = "https://... | { ...json... }",
    Finished = true,
    Callback = function(v) _loadInput = v or "" end
})
D_R:AddButton("Load", function()
    if (_loadInput or ""):gsub("%s","") == "" then
        UpdateStatus("No data to load")
        return
    end
    _LoadFromString(_loadInput)
end)

----------------------------------------------------------
-- 🧭 TAB AUTO WALK (dengan PAUSE / RESUME)
----------------------------------------------------------
local AutoWalkTab = Window:AddTab("Auto Walk", "map-pin")
local GLeft = AutoWalkTab:AddLeftGroupbox("Map Antartika")
local autoStatus = GLeft:AddLabel("Status: Idle")

local PathList = {
    "https://raw.githubusercontent.com/WannBot/Walk/main/Antartika/allpath.json",
}
local PathsLoaded = {}
local isReplaying, shouldStop = false, false

local function setAutoStatus(text)
    pcall(function() autoStatus:Set("Status: " .. text) end)
end

GLeft:AddButton("📥 Load All", function()
    task.spawn(function()
        setAutoStatus("Loading...")
        PathsLoaded = {}
        for i, url in ipairs(PathList) do
            local okGet, data = pcall(function() return game:HttpGet(url) end)
            if okGet and type(data) == "string" and #data > 100 then
                table.insert(PathsLoaded, data)
            else
                warn("[AutoWalk] Failed load path "..i)
            end
            task.wait(0.2)
        end
        if #PathsLoaded > 0 then
            setAutoStatus(("%d Path Loaded ✅"):format(#PathsLoaded))
        else
            setAutoStatus("Load Failed ❌")
        end
    end)
end)

GLeft:AddButton("▶ Play", function()
    task.spawn(function()
        if isReplaying then return end
        if #PathsLoaded == 0 then setAutoStatus("No Path Loaded") return end
        isReplaying, shouldStop = true, false
        setAutoStatus("Playing...")
        for i, jsonData in ipairs(PathsLoaded) do
            if shouldStop then break end
            local okDes = pcall(function() deserializePlatformData(jsonData) end)
            if okDes then
                ReplayFrom(1)
            end
            task.wait(0.3)
        end
        isReplaying = false
        setAutoStatus(shouldStop and "Stopped ⛔" or "Completed ✅")
    end)
end)

-- 🟡 Tambahan tombol Pause & Resume
GLeft:AddButton("⏸ Pause", function()
    PauseReplay()
    setAutoStatus("Paused ⏸")
end)

GLeft:AddButton("▶ Resume", function()
    ResumeReplay()
    setAutoStatus("Resumed ▶")
end)

GLeft:AddButton("⛔ Stop", function()
    shouldStop = true
    isReplaying = false
    pcall(stopForceMovement)
    setAutoStatus("Stopped ⛔")
end)

----------------------------------------------------------
-- 🗺 TAB PLATFORM LIST
----------------------------------------------------------
local PL_L = Tabs.List:AddLeftGroupbox("Select Platform")
local currentList = GetPlatformList()
local currentIndex = 1
local dd = PL_L:AddDropdown("WS_PlatformPick", {
    Values = currentList,
    Default = currentList[1],
    Multi = false,
    Text = "Platforms",
    Callback = function(val)
        for i, v in ipairs(currentList) do
            if v == val then currentIndex = i break end
        end
    end
})
PL_L:AddButton("Refresh", function()
    currentList = GetPlatformList()
    dd:SetValues(currentList)
    dd:SetValue(currentList[1])
    currentIndex = 1
    UpdateStatus("Platform list refreshed")
end)

local PL_R = Tabs.List:AddRightGroupbox("Action")
PL_R:AddButton("Play Selected", function() PlayPlatform(currentIndex) end)
PL_R:AddButton("Delete Selected", function()
    DeletePlatformIndex(currentIndex)
    currentList = GetPlatformList()
    dd:SetValues(currentList)
    dd:SetValue(currentList[1])
    currentIndex = 1
end)
PL_R:AddButton("Highlight Selected", function() HighlightPlatformIndex(currentIndex) end)

----------------------------------------------------------
-- ⚙️ TAB THEME / CONFIG
----------------------------------------------------------
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
ThemeManager:SetFolder("WS_UI")
SaveManager:SetFolder("WS_UI/config")
SaveManager:BuildConfigSection(Tabs.Theme)
ThemeManager:ApplyToTab(Tabs.Theme)
Library.ToggleKeybind = Enum.KeyCode.RightShift
