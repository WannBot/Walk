--// Select Map UI - Aquatic Dark Card Style
--// Fully mobile friendly (auto size adapt), smooth, professional

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "MapSelectUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

-- FRAME UTAMA (CARD)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0.8, 0, 0.7, 0)
mainFrame.Position = UDim2.new(0.1, 0, 0.15, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 28, 38) -- aquatic dark
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.ClipsDescendants = true
mainFrame.Parent = gui

local shadow = Instance.new("UICorner")
shadow.CornerRadius = UDim.new(0, 18)
shadow.Parent = mainFrame

local blur = Instance.new("UIStroke")
blur.Thickness = 1
blur.Color = Color3.fromRGB(40, 90, 120)
blur.Transparency = 0.3
blur.Parent = mainFrame

-- HEADER
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 45)
header.BackgroundColor3 = Color3.fromRGB(28, 42, 55)
header.BorderSizePixel = 0
header.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 18)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.Text = "Select Map"
title.Size = UDim2.new(1, -50, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamSemibold
title.TextColor3 = Color3.fromRGB(230, 240, 255)
title.TextScaled = true
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

-- CLOSE BUTTON
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 35, 0, 35)
closeBtn.Position = UDim2.new(1, -40, 0.5, -17)
closeBtn.AnchorPoint = Vector2.new(0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.TextScaled = true
closeBtn.AutoButtonColor = false
closeBtn.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(1, 0)
closeCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
	gui:Destroy()
end)

-- SCROLL FRAME (isi tombol MAP)
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -65)
scroll.Position = UDim2.new(0, 10, 0, 55)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.ScrollBarThickness = 8
scroll.BackgroundTransparency = 1
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = mainFrame

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0.23, 0, 0, 55) -- responsive size
grid.CellPadding = UDim2.new(0, 10, 0, 10)
grid.FillDirectionMaxCells = 4
grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = scroll

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 10)
padding.PaddingLeft = UDim.new(0, 10)
padding.Parent = scroll

-- DAFTAR MAP
local maps = {
	{ name = "ANTARTICA", url = "https://raw.githubusercontent.com/WannBot/Rbx/main/Map/Antartica.lua" },
	{ name = "SOON", url = "" },
	{ name = "SOON", url = "" },
	{ name = "SOON", url = "" },
	{ name = "SOON", url = "" },
	{ name = "SOON", url = "" },
	{ name = "SOON", url = "" },
	{ name = "SOON", url = "" },
}

-- BUAT BUTTON MAP (CARD BUTTON)
for _, map in ipairs(maps) do
	local btn = Instance.new("TextButton")
	btn.Text = map.name
	btn.Font = Enum.Font.GothamMedium
	btn.TextScaled = true
	btn.TextColor3 = Color3.fromRGB(230, 240, 255)
	btn.BackgroundColor3 = Color3.fromRGB(36, 48, 58)
	btn.AutoButtonColor = false
	btn.ClipsDescendants = true
	btn.Parent = scroll

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = btn

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(50, 100, 150)
	stroke.Thickness = 1
	stroke.Transparency = 0.5
	stroke.Parent = btn

	btn.MouseEnter:Connect(function()
		btn:TweenSize(UDim2.new(0.23, 0, 0, 60), "Out", "Quad", 0.15, true)
		btn.BackgroundColor3 = Color3.fromRGB(50, 70, 90)
	end)

	btn.MouseLeave:Connect(function()
		btn:TweenSize(UDim2.new(0.23, 0, 0, 55), "Out", "Quad", 0.15, true)
		btn.BackgroundColor3 = Color3.fromRGB(36, 48, 58)
	end)

	btn.MouseButton1Click:Connect(function()
		if map.url ~= "" then
			loadstring(game:HttpGet(map.url))()
		else
			game.StarterGui:SetCore("SendNotification", {
				Title = "Unavailable",
				Text = map.name .. " is coming soon!",
				Duration = 3,
			})
		end
	end)
end

-- RESIZER (fix posisi stabil)
local resizer = Instance.new("Frame")
resizer.Size = UDim2.new(0, 22, 0, 22)
resizer.AnchorPoint = Vector2.new(1, 1)
resizer.Position = UDim2.new(1, -6, 1, -6)
resizer.BackgroundColor3 = Color3.fromRGB(60, 100, 130)
resizer.Active = true
resizer.Parent = mainFrame

local resCorner = Instance.new("UICorner")
resCorner.CornerRadius = UDim.new(1, 0)
resCorner.Parent = resizer

local resizing = false
local startPos, startSize

resizer.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		resizing = true
		startPos = input.Position
		startSize = mainFrame.Size
	end
end)

resizer.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		resizing = false
	end
end)

UIS.InputChanged:Connect(function(input)
	if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - startPos
		local newX = math.clamp(startSize.X.Offset + delta.X, 280, 800)
		local newY = math.clamp(startSize.Y.Offset + delta.Y, 200, 600)
		mainFrame.Size = UDim2.new(0, newX, 0, newY)
	end
end)

-- AUTO SCALE SAAT ROTASI HP
UIS.OrientationChanged:Connect(function()
	task.wait(0.2)
	if UIS:IsTenFootInterface() then return end
	if workspace.CurrentCamera.ViewportSize.X > workspace.CurrentCamera.ViewportSize.Y then
		mainFrame.Size = UDim2.new(0.7, 0, 0.6, 0)
		mainFrame.Position = UDim2.new(0.15, 0, 0.2, 0)
	else
		mainFrame.Size = UDim2.new(0.9, 0, 0.75, 0)
		mainFrame.Position = UDim2.new(0.05, 0, 0.125, 0)
	end
end)
