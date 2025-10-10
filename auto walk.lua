--[[ 
WS • Auto Walk (Obsidian UI)
Versi Final (Pause/Resume + Smart Play)
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
-- STATE
----------------------------------------------------------
local recording, replaying = false, false
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local lastPosition = nil
local isClimbing = false
local forceActiveConnection = nil
local allConnections = {}

local platforms, yellowPlatforms, platformData, yellowToRedMapping = {}, {}, {}, {}
local platformCounter = 0
local currentReplayThread, shouldStopReplay = nil, false
local currentPlatformIndex, totalPlatformsToPlay = 0, 0
local forceSpeedMultiplier = 1.0

-- Pause / Resume State
local shouldPauseReplay = false
local pausedState = { isPaused=false, platformIndex=nil, movementIndex=nil, skipPathfind=false }

----------------------------------------------------------
-- HELPERS
----------------------------------------------------------
local function setupCharacterForce(characterToSetup)
    local humanoidToSetup = characterToSetup:WaitForChild("Humanoid")
    humanoidToSetup.StateChanged:Connect(function(_, newState)
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
        local moveSpeed = hum.WalkSpeed * forceSpeedMultiplier
        local dir = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z).Unit
        local horizVel = dir * moveSpeed
        root.AssemblyLinearVelocity = Vector3.new(horizVel.X, root.AssemblyLinearVelocity.Y, horizVel.Z)
    end)
end

local function calculatePath(start, goal)
    local path = PathfindingService:CreatePath()
    path:ComputeAsync(start, goal)
    return path
end

local function isCharacterMoving()
    local pos = character.PrimaryPart.Position
    if lastPosition then
        local dist = (pos - lastPosition).Magnitude
        lastPosition = pos
        return dist > 0.05
    end
    lastPosition = pos
    return false
end

local function UpdateStatus(t)
    if getfenv().__WS_STATUS_LABEL then
        getfenv().__WS_STATUS_LABEL:SetText("Status: " .. t)
    end
end

----------------------------------------------------------
-- PLATFORM SERIALIZER
----------------------------------------------------------
local function serializePlatformData()
    local data={redPlatforms={},yellowPlatforms={},mappings={}}
    for _,p in ipairs(platforms) do
        local moves={}
        for _,m in ipairs(platformData[p] or {}) do
            table.insert(moves,{position={X=m.position.X,Y=m.position.Y,Z=m.position.Z},
            orientation={X=m.orientation.X,Y=m.orientation.Y,Z=m.orientation.Z},isJumping=m.isJumping})
        end
        table.insert(data.redPlatforms,{position={X=p.Position.X,Y=p.Position.Y,Z=p.Position.Z},movements=moves})
    end
    return HttpService:JSONEncode(data)
end

local function deserializePlatformData(json)
    local ok,data = pcall(function()return HttpService:JSONDecode(json)end)
    if not ok then return false end
    for _,p in ipairs(platforms) do p:Destroy() end
    platforms,platformData={},{}
    for _,info in ipairs(data.redPlatforms or {}) do
        local p=Instance.new("Part")
        p.Size=Vector3.new(5,1,5) p.Position=Vector3.new(info.position.X,info.position.Y,info.position.Z)
        p.Anchored=true p.BrickColor=BrickColor.Red() p.CanCollide=false p.Parent=workspace
        platformData[p]={}
        for _,m in ipairs(info.movements or {}) do
            table.insert(platformData[p],{position=Vector3.new(m.position.X,m.position.Y,m.position.Z),
            orientation=Vector3.new(m.orientation.X,m.orientation.Y,m.orientation.Z),isJumping=m.isJumping})
        end
        table.insert(platforms,p)
    end
    return true
end

----------------------------------------------------------
-- REPLAY LOGIC + PAUSE/RESUME
----------------------------------------------------------
local function walkToPlatform(dest)
    local hum = character:WaitForChild("Humanoid")
    local root = character:WaitForChild("HumanoidRootPart")
    local path = calculatePath(root.Position,dest)
    if path.Status==Enum.PathStatus.Success then
        for _,wp in ipairs(path:GetWaypoints()) do
            if shouldStopReplay or shouldPauseReplay then break end
            hum:MoveTo(wp.Position)
            if wp.Action==Enum.PathWaypointAction.Jump then hum.Jump=true end
            hum.MoveToFinished:Wait()
        end
    else
        hum:MoveTo(dest) hum.MoveToFinished:Wait()
    end
end

local function ReplayFrom(startIndex,movIndex,skipPath)
    totalPlatformsToPlay=#platforms
    currentPlatformIndex=math.clamp(startIndex or 1,1,#platforms)
    movIndex=movIndex or 1
    skipPath=skipPath or false
    replaying=true shouldStopReplay=false shouldPauseReplay=false

    for i=currentPlatformIndex,#platforms do
        if shouldStopReplay then break end
        UpdateStatus(("Playing %d/%d"):format(i,totalPlatformsToPlay))
        local p=platforms[i]
        if not skipPath then
            stopForceMovement()
            walkToPlatform(p.Position+Vector3.new(0,3,0))
            if shouldStopReplay or shouldPauseReplay then break end
        end
        local moves=platformData[p]
        if moves and #moves>1 then
            startForceMovement()
            for j=movIndex,#moves-1 do
                if shouldStopReplay then break end
                if shouldPauseReplay then
                    pausedState={isPaused=true,platformIndex=i,movementIndex=j,skipPathfind=true}
                    replaying=false stopForceMovement()
                    UpdateStatus(("Paused @P%d step %d"):format(i,j))
                    return
                end
                local a,b=moves[j],moves[j+1]
                b.isJumping=a.isJumping
                local st,et=tick(),tick()+math.max((b.position-a.position).Magnitude*0.01,0.01)
                while tick()<et do
                    if shouldStopReplay or shouldPauseReplay then break end
                    local alpha=math.clamp((tick()-st)/(et-st),0,1)
                    local pos=a.position:Lerp(b.position,alpha)
                    local rot=CFrame.fromEulerAnglesXYZ(math.rad(a.orientation.X),math.rad(a.orientation.Y),math.rad(a.orientation.Z))
                    local rot2=CFrame.fromEulerAnglesXYZ(math.rad(b.orientation.X),math.rad(b.orientation.Y),math.rad(b.orientation.Z))
                    character:SetPrimaryPartCFrame(CFrame.new(pos)*rot:Lerp(rot2,alpha))
                    if b.isJumping then humanoid.Jump=true end
                    RunService.Heartbeat:Wait()
                end
            end
            stopForceMovement()
        end
        movIndex,skipPath=1,false
        task.wait(0.3)
    end
    replaying=false stopForceMovement()
    UpdateStatus("Completed ✅")
end

local function PauseReplay() if replaying then shouldPauseReplay=true end end
local function ResumeReplay()
    if not pausedState.isPaused then return UpdateStatus("Nothing to resume") end
    local p,m,s=pausedState.platformIndex,pausedState.movementIndex,pausedState.skipPathfind
    pausedState={isPaused=false} task.spawn(function() ReplayFrom(p,m,s) end)
end

local function StopReplay()
    if replaying then shouldStopReplay=true replaying=false stopForceMovement()
        UpdateStatus(("Stopped @P%d"):format(currentPlatformIndex)) end
end

local function GetNearestPlatformIndexFromPosition(pos)
    if #platforms==0 then return 1 end
    local best,dist=1,math.huge
    for i,p in ipairs(platforms) do local d=(p.Position-pos).Magnitude if d<dist then dist=d best=i end end
    return best
end

----------------------------------------------------------
-- OBSIDIAN UI
----------------------------------------------------------
local Window=Library:CreateWindow({Title="WS",Footer="Auto Walk (Obsidian)",Icon=95816097006870,ShowCustomCursor=true})
local Tabs={Main=Window:AddTab("Main Control","zap"),Auto=Window:AddTab("Auto Walk","map-pin"),Theme=Window:AddTab("Setting","settings")}

local StatusBox=Tabs.Main:AddRightGroupbox("Status")
local statusLabel=StatusBox:AddLabel("Status: Idle")
getfenv().__WS_STATUS_LABEL=statusLabel

----------------------------------------------------------
-- AUTO WALK TAB
----------------------------------------------------------
local GLeft=Tabs.Auto:AddLeftGroupbox("Antartika")
local autoStatus=GLeft:AddLabel("Status: Idle")
local PathList={"https://raw.githubusercontent.com/WannBot/Walk/main/Antartika/allpath.json"}
local PathsLoaded={}
local function setAutoStatus(t) pcall(function() autoStatus:Set("Status: "..t) end) end

GLeft:AddButton("📥 Load All",function()
    setAutoStatus("Loading...")
    PathsLoaded={}
    for _,url in ipairs(PathList) do
        local ok,res=pcall(function()return game:HttpGet(url)end)
        if ok and res and #res>100 then table.insert(PathsLoaded,res) end
    end
    setAutoStatus(("%d Path Loaded ✅"):format(#PathsLoaded))
end)

-- ▶ PLAY (nearest)
GLeft:AddButton("▶ Play (nearest)",function()
    if replaying then return end
    if #PathsLoaded==0 then return setAutoStatus("No Path Loaded") end
    setAutoStatus("Preparing...")
    local rp=character:WaitForChild("HumanoidRootPart")
    for i,data in ipairs(PathsLoaded) do
        if deserializePlatformData(data) then
            local startIdx=GetNearestPlatformIndexFromPosition(rp.Position)
            setAutoStatus(("Play %d ▶ @%d"):format(i,startIdx))
            task.spawn(function() ReplayFrom(startIdx,1,false) end)
        end
    end
end)

-- ⏸ Pause
GLeft:AddButton("⏸ Pause",function() if replaying then shouldPauseReplay=true setAutoStatus("Pausing...") end end)

-- ⏵ Resume
GLeft:AddButton("⏵ Resume",function()
    if pausedState.isPaused then setAutoStatus("Resuming...") ResumeReplay()
    else setAutoStatus("Nothing paused") end
end)

-- ⛔ Stop
GLeft:AddButton("⛔ Stop",function() StopReplay() setAutoStatus("Stopped ⛔") end)

----------------------------------------------------------
-- MAIN TAB ACTIONS
----------------------------------------------------------
local MC=Tabs.Main:AddLeftGroupbox("Actions")
MC:AddButton("Stop Replay",StopReplay)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
ThemeManager:SetFolder("WS_UI")
SaveManager:SetFolder("WS_UI/config")
SaveManager:BuildConfigSection(Tabs.Theme)
ThemeManager:ApplyToTab(Tabs.Theme)
Library.ToggleKeybind=Enum.KeyCode.RightShift
