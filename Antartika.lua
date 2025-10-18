--[[ 
WS • Auto Walk (Obsidian UI)
- UI: Obsidian (Library + ThemeManager + SaveManager)
- 3 Tabs: Main Control, Data, Platform List
- Status label real-time (tanpa "WS" prefix)
- Seluruh logika (record, replay, save, load, pathfinding, force move, chunking) disalin dari script lama dan TIDAK DIUBAH secara fungsional.

Catatan:
- Tidak membuat ScreenGui/Instance.new UI lama lagi.
- Semua tombol/event di-wire ke fungsi yang setara dengan versi lama.
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
-- STATE & DATA (disalin dari script lama)
----------------------------------------------------------
local recording = false
local replaying = false
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local lastPosition = nil

local platforms = {}           -- Red platforms (Part)
local yellowPlatforms = {}     -- Yellow platforms (Part)
local platformData = {}        -- [platform] = { {position=Vector3, orientation=Vector3, isJumping=bool}, ...}
local yellowToRedMapping = {}  -- [yellowPart] = redPart
local platformCounter = 0

-- Replay control
local currentReplayThread = nil
local shouldStopReplay = false
local currentPlatformIndex = 0
local totalPlatformsToPlay = 0

-- === PAUSE / RESUME STATE ===
local shouldPauseReplay = false
local pausedState = {
    isPaused = false,
    platformIndex = nil,   -- index platform saat pause
    movementIndex = 1,     -- step movement dalam platform (1..#movements-1)
    skipPathfind = false,  -- resume tidak perlu pathfind ulang kalau pause di tengah movement
}

-- === PAUSE / RESUME API ===
local function PauseReplay()
    -- tidak perlu cek 'replaying', biar bisa dipencet kapan pun saat replay
    if shouldStopReplay then return end
    shouldPauseReplay = true
    UpdateStatus("Pausing...")
end

local function ResumeReplay()
    if not pausedState.isPaused or not pausedState.platformIndex then
        UpdateStatus("Nothing to resume")
        return
    end
    shouldPauseReplay = false
    UpdateStatus(("Resuming @P%d step %d"):format(pausedState.platformIndex, pausedState.movementIndex or 1))
    task.spawn(function()
        ReplayFrom(pausedState.platformIndex)  -- movementIndex akan dipakai di ReplayFrom (lihat patch #2)
    end)
end

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
-- HELPERS: Character/Force Movement (disalin)
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
        local horizontalDirection = Vector3.new(lookVector.X, 0, lookVector.Z)
        if horizontalDirection.Magnitude < 1e-5 then return end
        horizontalDirection = horizontalDirection.Unit
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
-- SERIALIZE / DESERIALIZE (disalin)
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
    if not data or type(data) ~= "table" then
        return false, "Invalid data format"
    end

    -- Clear existing
    for _, platform in ipairs(platforms) do platform:Destroy() end
    for _, yellowPlatform in ipairs(yellowPlatforms) do yellowPlatform:Destroy() end
    platforms, yellowPlatforms, yellowToRedMapping, platformData = {}, {}, {}, {}
    platformCounter = 0

    -- Red platforms
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
            if platformInfo.movements then
                for _, movement in ipairs(platformInfo.movements) do
                    table.insert(restoredMovements, {
                        position = Vector3.new(movement.position.X, movement.position.Y, movement.position.Z),
                        orientation = Vector3.new(movement.orientation.X, movement.orientation.Y, movement.orientation.Z),
                        isJumping = movement.isJumping
                    })
                end
            end
            platformData[platform] = restoredMovements

            addTextLabelToPlatform(platform, #platforms + 1)
            table.insert(platforms, platform)
            platformCounter += 1
        end
    end

    -- Yellow + mappings
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
-- RECORD / STOP / DELETE / DESTROY (dibuat fungsi)
----------------------------------------------------------
local function UpdateStatus(text)
    if getfenv().__WS_STATUS_LABEL then
        getfenv().__WS_STATUS_LABEL:SetText("Status: " .. text)
    end
    if getgenv().AutoWalkStatusLabel then
        pcall(function()
            getgenv().AutoWalkStatusLabel:SetText("Status: " .. text)
        end)
    end
end

local function StartRecord()
    if recording then return end
    recording = true
    UpdateStatus("Recording")

    -- Jika sudah ada yellow, jalan ke titik terakhir dulu
    if #yellowPlatforms > 0 then
        local lastYellowPlatform = yellowPlatforms[#yellowPlatforms]
        local humanoidCurrent = character:WaitForChild("Humanoid")
        local rootPart = character:WaitForChild("HumanoidRootPart")
        if humanoidCurrent and humanoidCurrent.Health > 0 then
            local path = calculatePath(rootPart.Position, lastYellowPlatform.Position + Vector3.new(0,3,0))
            if path.Status == Enum.PathStatus.Success then
                for _, waypoint in ipairs(path:GetWaypoints()) do
                    humanoidCurrent:MoveTo(waypoint.Position)
                    if waypoint.Action == Enum.PathWaypointAction.Jump then
                        humanoidCurrent.Jump = true
                    end
                    humanoidCurrent.MoveToFinished:Wait()
                end
            else
                humanoidCurrent:MoveTo(lastYellowPlatform.Position + Vector3.new(0,3,0))
                humanoidCurrent.MoveToFinished:Wait()
            end
        end
    else
        -- Penjaga (no-op)
        if character and character.PrimaryPart then
            character:SetPrimaryPartCFrame(CFrame.new(character.PrimaryPart.Position))
        end
    end

    -- Buat red platform baru
    platformCounter += 1
    local platform = Instance.new("Part")
    platform.Name = "Platform " .. platformCounter
    platform.Size = Vector3.new(5, 1, 5)
    platform.Position = character.PrimaryPart.Position - Vector3.new(0, 3, 0)
    platform.Anchored = true
    platform.BrickColor = BrickColor.Red()
    platform.CanCollide = false
    platform.Parent = workspace
    addTextLabelToPlatform(platform, platformCounter)
    table.insert(platforms, platform)
    platformData[platform] = {}

    -- Rekam per Heartbeat
    task.spawn(function()
        while recording do
            if not platform or not platform.Parent then
                recording = false
                UpdateStatus("Error: Missing Red Platform (Recording Stopped)")
                break
            end
            if isCharacterMoving() then
                table.insert(platformData[platform], {
                    position   = character.PrimaryPart.Position,
                    orientation= character.PrimaryPart.Orientation,
                    isJumping  = humanoid.Jump
                })
            end
            RunService.Heartbeat:Wait()
        end
    end)
end

local function StopRecord()
    if not recording then return end
    recording = false
    UpdateStatus("Stopped Recording")

    local yellowPlatform = Instance.new("Part")
    yellowPlatform.Size = Vector3.new(5, 1, 5)
    yellowPlatform.Position = character.PrimaryPart.Position - Vector3.new(0, 3, 0)
    yellowPlatform.Anchored = true
    yellowPlatform.BrickColor = BrickColor.Yellow()
    yellowPlatform.CanCollide = false
    yellowPlatform.Parent = workspace

    addTextLabelToPlatform(yellowPlatform, platformCounter)
    table.insert(yellowPlatforms, yellowPlatform)
    yellowToRedMapping[yellowPlatform] = platforms[#platforms]
end

local function StopReplay()
    if replaying then
        shouldStopReplay = true
        replaying = false
        stopForceMovement()
        if character:FindFirstChild("Humanoid") and character:FindFirstChild("HumanoidRootPart") then
            character.Humanoid:MoveTo(character.HumanoidRootPart.Position)
        end
        UpdateStatus(("Stopped at Platform %d/%d"):format(math.max(currentPlatformIndex-1,0), totalPlatformsToPlay))
        task.delay(1.0, function() UpdateStatus("Idle") end)
    end
end

local function DestroyAll()
    for _, platform in ipairs(platforms) do platform:Destroy() end
    for _, yellowPlatform in ipairs(yellowPlatforms) do yellowPlatform:Destroy() end
    platforms, yellowPlatforms, platformData, yellowToRedMapping = {}, {}, {}, {}
    platformCounter = 0
    stopForceMovement()
    for _, c in ipairs(allConnections) do c:Disconnect() end
    allConnections = {}
    UpdateStatus("Idle")
end

local function DeleteLastPlatform()
    if #platforms == 0 then return end
    local lastPlatform = platforms[#platforms]
    lastPlatform:Destroy()
    cleanupPlatform(lastPlatform)

    -- hapus label/tampilan (di UI baru ini list pakai dropdown -> akan di-refresh)
    platformCounter -= 1

    -- Bersihkan yellow yang map ke platform yang sudah dihapus
    for yellowPlatform, redPlatform in pairs(yellowToRedMapping) do
        if not table.find(platforms, redPlatform) then
            yellowPlatform:Destroy()
            yellowToRedMapping[yellowPlatform] = nil
            local idx = table.find(yellowPlatforms, yellowPlatform)
            if idx then table.remove(yellowPlatforms, idx) end
        end
    end
end

----------------------------------------------------------
-- SAVE / NEXT CHUNK / LOAD (URL/RAW + stacking) (disalin)
----------------------------------------------------------
-- NOTE: SaveAll DIMODIF agar menyimpan ke folder AutoWalk (sesuai permintaan),
--       tetapi tetap mempertahankan mekanisme chunking (struktur tidak dihapus).
local function SaveAll()
    local jsonData = serializePlatformData()

    -- buat folder
    local folder = "AutoWalk"
    if not isfolder(folder) then
        makefolder(folder)
    end

    if #jsonData > 190000 then
        -- pecah ke beberapa file, tetap menghormati logika chunk lama
        local allData = HttpService:JSONDecode(jsonData)
        saveChunks = {}
        local redCount = #allData.redPlatforms
        totalChunks = math.ceil(redCount / CHUNK_SIZE)

        for chunkIndex = 1, totalChunks do
            local startIndex = (chunkIndex-1)*CHUNK_SIZE + 1
            local endIndex = math.min(chunkIndex*CHUNK_SIZE, redCount)
            local chunk = { redPlatforms = {}, yellowPlatforms = {}, mappings = {} }
            for i = startIndex, endIndex do
                table.insert(chunk.redPlatforms, allData.redPlatforms[i])
            end
            for i, mapping in ipairs(allData.mappings or {}) do
                if mapping >= startIndex and mapping <= endIndex then
                    table.insert(chunk.yellowPlatforms, (allData.yellowPlatforms or {})[i])
                    table.insert(chunk.mappings, mapping - startIndex + 1)
                end
            end
            local chunkJson = HttpService:JSONEncode(chunk)
            saveChunks[chunkIndex] = chunkJson

            -- simpan ke file
            local filename = ("%s/PathChunk_%d_of_%d_%s.json"):format(
                folder, chunkIndex, totalChunks, os.date("%Y%m%d_%H%M%S")
            )
            writefile(filename, chunkJson)
        end

        currentChunkIndex = 1
        UpdateStatus(("Saved %d chunk files to '%s' (press Next Chunk if needed)"):format(totalChunks, folder))
    else
        -- simpan satu file utuh
        local filename = ("%s/Path_%s.json"):format("AutoWalk", os.date("%Y%m%d_%H%M%S"))
        writefile(filename, jsonData)

        -- reset info chunk agar tombol Next Chunk tetap ada tapi tidak error
        saveChunks, currentChunkIndex, totalChunks = {}, 0, 0
        UpdateStatus("Saved to '".. filename .."'")
    end
end

local function NextChunk()
    -- fungsi ini dibiarkan sesuai struktur lama (tetap ada),
    -- walau sekarang SaveAll menulis langsung ke file.
    if #saveChunks > 0 and currentChunkIndex < totalChunks then
        currentChunkIndex += 1
        setclipboard(saveChunks[currentChunkIndex])  -- biarkan perilaku lama
        UpdateStatus(("Chunk %d/%d copied (also saved to files)"):format(currentChunkIndex, totalChunks))
    elseif currentChunkIndex == totalChunks and totalChunks > 0 then
        UpdateStatus("All chunks have been copied")
    else
        UpdateStatus("No chunks to copy")
    end
end

local function _LoadFromString(input)
    local loadedSuccessfully = false
    if input:match("^https?://") then
        UpdateStatus("Loading 0%")
        local ok, response = pcall(function() return game:HttpGet(input) end)
        if ok and response then
            -- coba stacked line-per-line
            local combinedData = { redPlatforms={}, yellowPlatforms={}, mappings={} }
            local redOffset = 0
            local stackedOK = false
            for jsonStr in response:gmatch("[^\r\n]+") do
                local okj, chunk = pcall(function() return HttpService:JSONDecode(jsonStr) end)
                if okj and type(chunk)=="table" and type(chunk.redPlatforms)=="table" then
                    stackedOK = true
                    for _, rp in ipairs(chunk.redPlatforms) do table.insert(combinedData.redPlatforms, rp) end
                    if type(chunk.yellowPlatforms)=="table" then
                        for i, yp in ipairs(chunk.yellowPlatforms) do
                            table.insert(combinedData.yellowPlatforms, yp)
                            if type(chunk.mappings)=="table" and chunk.mappings[i] then
                                table.insert(combinedData.mappings, chunk.mappings[i] + redOffset)
                            end
                        end
                    end
                    redOffset += #chunk.redPlatforms
                end
            end
            if stackedOK then
                local combinedJson = HttpService:JSONEncode(combinedData)
                local ok2 = deserializePlatformData(combinedJson)
                loadedSuccessfully = ok2 and true or false
            else
                loadedSuccessfully = deserializePlatformData(response)
            end
        else
            UpdateStatus("Load failed (URL)")
            return
        end
    else
        -- RAW input: coba stacked
        local combinedData = { redPlatforms={}, yellowPlatforms={}, mappings={} }
        local redOffset = 0
        local stackedOK = false
        for jsonStr in input:gmatch("[^\r\n]+") do
            local okj, chunk = pcall(function() return HttpService:JSONDecode(jsonStr) end)
            if okj and type(chunk)=="table" and type(chunk.redPlatforms)=="table" then
                stackedOK = true
                for _, rp in ipairs(chunk.redPlatforms) do table.insert(combinedData.redPlatforms, rp) end
                if type(chunk.yellowPlatforms)=="table" then
                    for i, yp in ipairs(chunk.yellowPlatforms) do
                        table.insert(combinedData.yellowPlatforms, yp)
                        if type(chunk.mappings)=="table" and chunk.mappings[i] then
                            table.insert(combinedData.mappings, chunk.mappings[i] + redOffset)
                        end
                    end
                end
                redOffset += #chunk.redPlatforms
            end
        end
        if stackedOK then
            local combinedJson = HttpService:JSONEncode(combinedData)
            local ok2 = deserializePlatformData(combinedJson)
            loadedSuccessfully = ok2 and true or false
        else
            loadedSuccessfully = deserializePlatformData(input)
        end
    end

    if loadedSuccessfully then
        UpdateStatus("Platform data loaded")
    else
        UpdateStatus("Failed to parse/load data")
    end
end

----------------------------------------------------------
-- REPLAY PLATFORM (disalin, DITAMBAH dukungan Pause)
----------------------------------------------------------
local function walkToPlatform(destination)
	local humanoidCurrent = character:WaitForChild("Humanoid")
	local rootPart = character:WaitForChild("HumanoidRootPart")
	if not humanoidCurrent or humanoidCurrent.Health <= 0 then return end

	local path = calculatePath(rootPart.Position, destination)
	if path.Status == Enum.PathStatus.Success then
		local waypoints = path:GetWaypoints()
		for _, waypoint in ipairs(waypoints) do
			if shouldStopReplay or shouldPauseReplay then break end

			local deltaY = waypoint.Position.Y - rootPart.Position.Y
			if deltaY > 4 then
				-- >>> Tangga atau climb terdeteksi <<<
				humanoidCurrent:ChangeState(Enum.HumanoidStateType.Climbing)

				-- Buat tali visual sementara
				local rope = Instance.new("Part")
				rope.Name = "ClimbRope"
				rope.Anchored = true
				rope.CanCollide = false
				rope.Material = Enum.Material.Fabric
				rope.Color = Color3.fromRGB(180, 150, 100)
				rope.Size = Vector3.new(0.2, math.abs(deltaY), 0.2)
				rope.CFrame = CFrame.new(rootPart.Position:Lerp(waypoint.Position, 0.5))
				rope.Parent = workspace

				-- Gerak vertikal bertahap (biar tidak ngesot)
				local step = math.sign(deltaY)
				local totalStep = math.abs(math.floor(deltaY))
				for n = 1, totalStep do
					if shouldStopReplay or shouldPauseReplay then break end
					rootPart.CFrame = rootPart.CFrame + Vector3.new(0, step, 0)
					task.wait(0.05)
				end

				rope:Destroy()
				humanoidCurrent:ChangeState(Enum.HumanoidStateType.Running)
			else
				-- Jalan datar normal
				humanoidCurrent:MoveTo(waypoint.Position)
				if waypoint.Action == Enum.PathWaypointAction.Jump then
					humanoidCurrent.Jump = true
				end
				humanoidCurrent.MoveToFinished:Wait()
			end
		end
	else
		humanoidCurrent:MoveTo(destination)
		humanoidCurrent.MoveToFinished:Wait()
	end
end

-- Area climb spesifik dari map Ice_Climbing%.1
local climbObj = workspace:FindFirstChild("Ice_Climbing%.1", true)
if climbObj and climbObj:FindFirstChild("Touch_Detectors") then
	local bottom = climbObj.Touch_Detectors:FindFirstChild("Bottom")
	if bottom and bottom:FindFirstChild("Bottom") then
		local climbPart = bottom.Bottom
		climbPart.Touched:Connect(function(hit)
			if hit.Parent == character then
				local hum = character:FindFirstChildOfClass("Humanoid")
				if hum then
					hum:ChangeState(Enum.HumanoidStateType.Climbing)
					UpdateStatus("🧗‍♂️ Climbing Ice Wall...")
				end
			end
		end)
	end
end

local shouldPauseReplay = false
local pausedState = {
    isPaused = false,
    platformIndex = nil,
    movementIndex = 1,
    skipPathfind = false
}

-- Cari platform terdekat dari posisi pemain
local function GetNearestPlatformIndex()
    if #platforms == 0 then return 1 end
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return 1 end

    local nearestIndex, nearestDist = 1, math.huge
    for i, platform in ipairs(platforms) do
        if platform and platform:IsA("BasePart") then
            local dist = (root.Position - platform.Position).Magnitude
            if dist < nearestDist then
                nearestDist = dist
                nearestIndex = i
            end
        end
    end
    return nearestIndex
end

local function ReplayFrom(indexStart, movementIndexStart)
    totalPlatformsToPlay = #platforms
    currentPlatformIndex = indexStart

    -- Jika resume dari pause, mulai dari step & platform terakhir
    local movementStartIndex = (pausedState.isPaused and pausedState.movementIndex) or movementIndexStart or 1
    local skipPathfindWhenResuming = (pausedState.isPaused and pausedState.skipPathfind) or false

    -- Bersihkan flag pause
    if pausedState.isPaused then
        pausedState.isPaused = false
    end

    for i = indexStart, #platforms do
        if shouldStopReplay then break end
        currentPlatformIndex = i
        UpdateStatus(("Playing from Platform %d/%d"):format(currentPlatformIndex, totalPlatformsToPlay))
        local currentPlatform = platforms[i]

        -- Phase 1: pathfind ke platform (kecuali resume di tengah movement)
        if not skipPathfindWhenResuming then
            stopForceMovement()
            walkToPlatform(currentPlatform.Position + Vector3.new(0,3,0))
            if shouldStopReplay then break end
            if shouldPauseReplay then
                pausedState.isPaused = true
                pausedState.platformIndex = i
                pausedState.movementIndex = 1
                pausedState.skipPathfind = true
                UpdateStatus(("Paused at Platform %d/%d"):format(i, totalPlatformsToPlay))
                return
            end
        end

        -- Phase 2: interpolasi movement
        local movements = platformData[currentPlatform]
        if movements and #movements > 1 then
            startForceMovement()
            for j = movementStartIndex, #movements-1 do
                if shouldStopReplay then break end
                if shouldPauseReplay then
                    pausedState.isPaused = true
                    pausedState.platformIndex = i
                    pausedState.movementIndex = j
                    pausedState.skipPathfind = true
                    stopForceMovement()
                    UpdateStatus(("Paused at P%d step %d"):format(i, j))
                    return
                end

                local a = movements[j]
                local b = movements[j+1]
                b.isJumping = a.isJumping

                local startTime = tick()
                local distance = (b.position - a.position).Magnitude
                local duration = math.max(distance * 0.01, 0.01)
                local endTime = startTime + duration

                while tick() < endTime do
                    if shouldStopReplay then break end
                    if shouldPauseReplay then
                        pausedState.isPaused = true
                        pausedState.platformIndex = i
                        pausedState.movementIndex = j
                        pausedState.skipPathfind = true
                        stopForceMovement()
                        UpdateStatus(("Paused at P%d step %d"):format(i, j))
                        return
                    end
                    local alpha = math.clamp((tick() - startTime)/duration, 0, 1)
                    local pos = a.position:Lerp(b.position, alpha)
                    local cfA = CFrame.fromEulerAnglesXYZ(
                        math.rad(a.orientation.X), math.rad(a.orientation.Y), math.rad(a.orientation.Z)
                    )
                    local cfB = CFrame.fromEulerAnglesXYZ(
                        math.rad(b.orientation.X), math.rad(b.orientation.Y), math.rad(b.orientation.Z)
                    )
                    local rot = cfA:Lerp(cfB, alpha)
                    character:SetPrimaryPartCFrame(CFrame.new(pos) * rot)
                    if b.isJumping then humanoid.Jump = true end
                    RunService.Heartbeat:Wait()
                end
            end
            stopForceMovement()
        end

        task.wait(0.5)
        movementStartIndex = 1
        skipPathfindWhenResuming = false
    end

    if not shouldStopReplay then
        UpdateStatus("Completed all platforms")
        task.wait(1)
    end
    replaying = false
    UpdateStatus("Idle")
    stopForceMovement()
end

-- === PAUSE / RESUME HANDLER ===
local function PauseReplay()
    if shouldPauseReplay then return end
    shouldPauseReplay = true
    UpdateStatus("Pausing...")
end

local function ResumeReplay()
    if not pausedState.isPaused or not pausedState.platformIndex then
        UpdateStatus("Tidak ada replay yang dipause")
        return
    end
    shouldPauseReplay = false
    shouldStopReplay = false
    UpdateStatus(("Resuming ▶ Platform %d step %d"):format(
        pausedState.platformIndex or 1,
        pausedState.movementIndex or 1
    ))
    task.spawn(function()
        ReplayFrom(pausedState.platformIndex, pausedState.movementIndex)
    end)
end

local function PlayPlatform(index)
    if replaying then return end
    if currentReplayThread then shouldStopReplay = true task.wait() end
    if not index or index < 1 or index > #platforms then
        UpdateStatus("Invalid platform index")
        return
    end
    replaying = true
    shouldStopReplay = false
    shouldPauseReplay = false
    currentReplayThread = task.spawn(function()
        ReplayFrom(index)
        currentReplayThread = nil
    end)
end

----------------------------------------------------------
-- PLATFORM LIST HELPERS (untuk Tab Platform List)
----------------------------------------------------------
local function GetPlatformList()
    local list = {}
    for i = 1, #platforms do
        list[i] = ("Platform %d"):format(i)
    end
    if #list == 0 then list = {"(no platforms)"} end
    return list
end

local function DeletePlatformIndex(idx)
    if not idx or idx < 1 or idx > #platforms then return end
    local p = platforms[idx]
    if p then p:Destroy() end
    cleanupPlatform(p)
    -- bersihkan yellow yang map ke platform ini
    for yellowPlatform, redPlatform in pairs(yellowToRedMapping) do
        if redPlatform == p then
            yellowPlatform:Destroy()
            yellowToRedMapping[yellowPlatform] = nil
            local iy = table.find(yellowPlatforms, yellowPlatform)
            if iy then table.remove(yellowPlatforms, iy) end
        end
    end
    platformCounter = #platforms
end

local function HighlightPlatformIndex(idx)
    if not idx or idx < 1 or idx > #platforms then return end
    local p = platforms[idx]
    if not p then return end
    local old = p.Color
    p.Color = Color3.fromRGB(0, 255, 0)
    task.delay(0.5, function() if p and p.Parent then p.Color = old end end)
end

----------------------------------------------------------
-- RESPAWN HANDLER (disalin)
----------------------------------------------------------
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = newCharacter:WaitForChild("Humanoid")
    lastPosition = nil
    UpdateStatus("Idle")

    for _, c in ipairs(allConnections) do c:Disconnect() end
    allConnections = {}
    setupCharacterForce(newCharacter)

    if recording then
        platforms, yellowPlatforms, platformData, yellowToRedMapping = {}, {}, {}, {}
        platformCounter = 0
    end

    stopForceMovement()
    shouldStopReplay = true
    replaying = false
    shouldPauseReplay = false
    pausedState = { isPaused=false, platformIndex=nil, movementIndex=nil, skipPathfind=false }
    if currentReplayThread then
        task.cancel(currentReplayThread)
        currentReplayThread = nil
    end
end)

if player.Character then setupCharacterForce(player.Character) end

----------------------------------------------------------
-- OBSIDIAN UI
----------------------------------------------------------
local Window = Library:CreateWindow({
    Title = "WS",
    Footer = "Auto Walk (Obsidian)",
    Icon = 95816097006870,
    ShowCustomCursor = true,
})

local Tabs = {
	Main  = Window:AddTab("Main Control", "zap"),
	Data  = Window:AddTab("Data", "folder"),
	List  = Window:AddTab("Platform List", "map"),
	Theme = Window:AddTab("Setting", "settings"),
}

---------------------------------------------------------
-- 🧭 AUTO WALK TAB (Antartika) — FIX: Full Working + Pause/Resume
---------------------------------------------------------
task.spawn(function()
    while not Window or typeof(Window.AddTab) ~= "function" do
        task.wait(0.25)
    end

    local okInit, errInit = pcall(function()
        local AutoWalkTab = Window:AddTab("Auto Walk", "map-pin")
        local GLeft = AutoWalkTab:AddLeftGroupbox("Map Antartika")
        local autoStatus = GLeft:AddLabel("Status: Idle")
getgenv().AutoWalkStatusLabel = autoStatus

-- versi baru: sinkron langsung lewat UpdateStatus global
local function setAutoStatus(text)
    pcall(function()
        if getgenv().AutoWalkStatusLabel then
            getgenv().AutoWalkStatusLabel:SetText("Status: " .. text)
        end
        UpdateStatus(text) -- panggil juga label utama
    end)
				end

        local PathList = {
            "https://raw.githubusercontent.com/WannBot/Walk/main/Antartika/allpath.json",
        }

        local PathsLoaded = {}
        local isReplaying_AW, shouldStop_AW = false, false

        

        -----------------------------------------------------
        -- 📥 LOAD ALL PATHS
        -----------------------------------------------------
        GLeft:AddButton("📥 Load All", function()
            task.spawn(function()
                setAutoStatus("Loading...")
                PathsLoaded = {}

                for i, url in ipairs(PathList) do
                    local okGet, data = pcall(function()
                        return game:HttpGet(url)
                    end)
                    if okGet and type(data) == "string" and #data > 100 then
                        table.insert(PathsLoaded, data)
                        print(("[AutoWalk] ✅ Loaded Path %d (%d bytes)"):format(i, #data))
                    else
                        warn("[AutoWalk] ⚠️ Gagal load Path "..i.." → "..tostring(url))
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

		-----------------------------------------------------
        -- ▶ PLAY ALL PATHS (gunakan ReplayFrom)
        -----------------------------------------------------
        
        -- ▶ Play
GLeft:AddButton("▶ Play", function()
    task.spawn(function()
        if #PathsLoaded == 0 then
            setAutoStatus("No Path Loaded")
            return
        end

        -- reset flag global
        shouldStopReplay = false
        shouldPauseReplay = false
        pausedState = { isPaused=false, platformIndex=nil, movementIndex=1, skipPathfind=false }

        setAutoStatus("Playing...")
        for i, jsonData in ipairs(PathsLoaded) do
            if shouldStopReplay then break end

            setAutoStatus(("Loading Path %d..."):format(i))
            local okDes = pcall(function()
                deserializePlatformData(jsonData)
            end)

            if okDes then
                setAutoStatus(("Replaying Path %d ▶"):format(i))
                replaying = true
                local okPlay = pcall(function()
    local nearest = GetNearestPlatformIndex()
    setAutoStatus(("Nearest Platform: %d"):format(nearest))
    ReplayFrom(nearest)
end)
                replaying = false
                if not okPlay then
                    warn("[AutoWalk] Replay error on Path "..i)
                end
            else
                warn("[AutoWalk] Deserialize error Path "..i)
            end
            task.wait(0.3)
        end

        if shouldStopReplay then
            setAutoStatus("Stopped ⛔")
        else
            setAutoStatus("Completed ✅")
        end
    end)
end)

-- ⏸ Pause
GLeft:AddButton("⏸ Pause", function()
    PauseReplay()
    setAutoStatus("Paused ⏸")
end)

-- ▶ Resume
GLeft:AddButton("▶ Resume", function()
    ResumeReplay()
    setAutoStatus("Resumed ▶")
end)

-- ⛔ Stop
GLeft:AddButton("⛔ Stop", function()
    shouldStopReplay = true
    shouldPauseReplay = false
    pausedState = { isPaused=false, platformIndex=nil, movementIndex=1, skipPathfind=false }
    StopReplay()  -- pakai fungsi global agar status & force move rapi
    setAutoStatus("Stopped ⛔")
        end)     
			end)
				
    if not okInit then
        warn("[AutoWalk Tab Init Error]:", errInit)
    end
end)


-- 🔧 Status Label global (pojok bawah)
local StatusBox = Tabs.Main:AddRightGroupbox("Status")
local statusLabel = StatusBox:AddLabel("Status: Idle")
getfenv().__WS_STATUS_LABEL = statusLabel

-- ===== Tab Main Control
local MC_L = Tabs.Main:AddLeftGroupbox("Actions")
MC_L:AddButton("Record", StartRecord)
MC_L:AddButton("Stop Record", StopRecord)
MC_L:AddButton("Stop Replay", StopReplay)
MC_L:AddButton("Delete (Last Red)", DeleteLastPlatform)
MC_L:AddButton("Destroy All", DestroyAll)

-- ===== Tab Data
local D_L = Tabs.Data:AddLeftGroupbox("Save / Chunk")
D_L:AddButton("Save", SaveAll)            -- << dimodif: save ke folder AutoWalk (tetap hormati chunk)
D_L:AddButton("Next Chunk", NextChunk)    -- << tetap ada (struktur dipertahankan)

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

-- ===== Tab Platform List
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

-- ===== Theme / Config
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
ThemeManager:SetFolder("WS_UI")
SaveManager:SetFolder("WS_UI/config")
SaveManager:BuildConfigSection(Tabs.Theme)
ThemeManager:ApplyToTab(Tabs.Theme)
Library.ToggleKeybind = Enum.KeyCode.RightShift
