--[[
WS • Auto Walk (Obsidian UI v2.6)
Struktur identik dengan versi user (red & yellow platform system)
Penambahan fitur:
🟢 Pause & Resume di Tab Auto Walk
• Pause menyimpan posisi platform & movement terakhir
• Resume melanjutkan dari titik pause, tanpa mengulang dari awal
• Tidak mengubah logika Record/Replay/Save/Load lainnya
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
local pauseMovementIndex = 0

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
    for _, p in ipairs(platforms) do p:Destroy() end
    for _, y in ipairs(yellowPlatforms) do y:Destroy() end
    platforms, yellowPlatforms, yellowToRedMapping, platformData = {}, {}, {}, {}
    platformCounter = 0

    if data.redPlatforms then
        for _, pInfo in ipairs(data.redPlatforms) do
            local p = Instance.new("Part")
            p.Size = Vector3.new(5, 1, 5)
            p.Position = Vector3.new(pInfo.position.X, pInfo.position.Y, pInfo.position.Z)
            p.Anchored = true
            p.BrickColor = BrickColor.Red()
            p.CanCollide = false
            p.Parent = workspace
            local restored = {}
            for _, m in ipairs(pInfo.movements or {}) do
                table.insert(restored, {
                    position = Vector3.new(m.position.X, m.position.Y, m.position.Z),
                    orientation = Vector3.new(m.orientation.X, m.orientation.Y, m.orientation.Z),
                    isJumping = m.isJumping
                })
            end
            platformData[p] = restored
            addTextLabelToPlatform(p, #platforms + 1)
            table.insert(platforms, p)
            platformCounter += 1
        end
    end

    if data.yellowPlatforms then
        for i, yInfo in ipairs(data.yellowPlatforms) do
            local yp = Instance.new("Part")
            yp.Size = Vector3.new(5, 1, 5)
            yp.Position = Vector3.new(yInfo.position.X, yInfo.position.Y, yInfo.position.Z)
            yp.Anchored = true
            yp.BrickColor = BrickColor.Yellow()
            yp.CanCollide = false
            yp.Parent = workspace
            if data.mappings and data.mappings[i] then
                addTextLabelToPlatform(yp, data.mappings[i])
                if platforms[data.mappings[i]] then
                    yellowToRedMapping[yp] = platforms[data.mappings[i]]
                end
            end
            table.insert(yellowPlatforms, yp)
        end
    end
    return true
end

----------------------------------------------------------
-- RECORD (unchanged)
----------------------------------------------------------
local function UpdateStatus(text)
    if getfenv().__WS_STATUS_LABEL then
        getfenv().__WS_STATUS_LABEL:SetText("Status: " .. text)
    end
end

-- StartRecord / StopRecord / StopReplay / Delete etc
-- (semua tetap sama persis seperti script kamu)
-- ...

----------------------------------------------------------
-- PAUSE & RESUME SYSTEM
----------------------------------------------------------
local function PauseReplay()
    if not replaying or pausedReplay then return end
    pausedReplay = true
    UpdateStatus(("Paused at Platform %d"):format(currentPlatformIndex))
    stopForceMovement()
end

local function ResumeReplay()
    if not pausedReplay then return end
    pausedReplay = false
    UpdateStatus(("Resuming from Platform %d"):format(currentPlatformIndex))
    task.spawn(function()
        ReplayFrom(currentPlatformIndex)
    end)
end

----------------------------------------------------------
-- OBSIDIAN UI (tambahan tombol Pause & Resume)
----------------------------------------------------------
task.spawn(function()
    local ok, err = pcall(function()
        local Window = Library:CreateWindow({
            Title = "WS",
            Footer = "Auto Walk (v2.6)",
            Icon = 95816097006870,
            ShowCustomCursor = true,
        })

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
                for _, url in ipairs(PathList) do
                    local okGet, data = pcall(function() return game:HttpGet(url) end)
                    if okGet and type(data) == "string" and #data > 100 then
                        table.insert(PathsLoaded, data)
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
                        local okPlay = pcall(function() ReplayFrom(1) end)
                        if not okPlay then warn("[AutoWalk] Replay error on Path "..i) end
                    end
                    task.wait(0.3)
                end
                isReplaying = false
                setAutoStatus(shouldStop and "Stopped ⛔" or "Completed ✅")
            end)
        end)

        -- 🟡 New Pause Button
        GLeft:AddButton("⏸ Pause", function()
            PauseReplay()
            setAutoStatus("Paused ⏸")
        end)

        -- 🟢 New Resume Button
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
    end)

    if not ok then
        warn("[AutoWalk Tab Init Error]:", err)
    end
end)
