--// Select Map UI - Neon Aqua Glow Edition
--// by WanBot

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "MapSelectUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

-- FRAME UTAMA
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0.4, 0, 0.55, 0)
mainFrame.Position = UDim2.new(0.1, 0, 0.15, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(10, 14, 18)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.ClipsDescendants = true
mainFrame.Parent = gui

-- CARD SHAPE
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 20)
corner.Parent = mainFrame

-- GLOW LUAR (tepi frame hijau lembut)
local glow = Instance.new("ImageLabel")
glow.Name = "Glow"
glow.Size = UDim2.new(1, 60, 1, 60)
glow.Position = UDim2.new(0.5, 0, 0.5, 0)
glow.AnchorPoint = Vector2.new(0.5, 0.5)
glow.BackgroundTransparency = 1
glow.Image = "rbxassetid://5028857084" -- soft glow texture Roblox
glow.ImageColor3 = Color3.fromRGB(0, 255, 180)
glow.ImageTransparency = 0.7
glow.ZIndex = 0
glow.Parent = mainFrame

-- HEADER
local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, 0, 0, 45)
header.BackgroundTransparency = 1
header.Text = "Select Map"
header.Font = Enum.Font.GothamBold
header.TextScaled = true
header.TextColor3 = Color3.fromRGB(180, 255, 230)
header.TextTransparency = 0
header.ZIndex = 2
header.Parent = mainFrame

-- CLOSE BUTTON
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 35, 0, 35)
closeBtn.Position = UDim2.new(1, -45, 0, 5)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "×"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextColor3 = Color3.fromRGB(0, 255, 180)
closeBtn.TextScaled = true
closeBtn.ZIndex = 2
closeBtn.Parent = mainFrame
closeBtn.MouseButton1Click:Connect(function()
	gui:Destroy()
end)

-- SCROLL FRAME
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -70)
scroll.Position = UDim2.new(0, 10, 0, 60)
scroll.BackgroundTransparency = 1
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollBarThickness = 6
scroll.ScrollBarImageColor3 = Color3.fromRGB(0, 255, 180)
scroll.Parent = mainFrame

local layout = Instance.new("UIGridLayout")
layout.CellSize = UDim2.new(0.23, 0, 0, 55)
layout.CellPadding = UDim2.new(0, 12, 0, 12)
layout.FillDirectionMaxCells = 4
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 10)
pad.Parent = scroll

-- LIST MAP
local maps = {
	{ name = "ANTARTICA", url = "https://raw.githubusercontent.com/WannBot/Walk/refs/heads/main/Antartika.lua" },
	{ name = "SOON", url = "" },
	{ name = "SOON", url = "" },
	{ name = "SOON", url = "" },
	{ name = "SOON", url = "" },
	{ name = "SOON", url = "" },
	{ name = "SOON", url = "" },
	{ name = "SOON", url = "" },
}

-- BUAT BUTTON MAP (Outline neon style)
for _, map in ipairs(maps) do
	local btn = Instance.new("TextButton")
	btn.Text = map.name
	btn.Font = Enum.Font.GothamMedium
	btn.TextScaled = true
	btn.TextColor3 = Color3.fromRGB(0, 255, 180)
	btn.BackgroundColor3 = Color3.fromRGB(15, 20, 25)
	btn.AutoButtonColor = false
	btn.Parent = scroll

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = btn

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 255, 180)
	stroke.Thickness = 1.5
	stroke.Transparency = 0.2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = btn

	btn.MouseEnter:Connect(function()
		btn.BackgroundColor3 = Color3.fromRGB(20, 30, 35)
		stroke.Thickness = 2
	end)

	btn.MouseLeave:Connect(function()
		btn.BackgroundColor3 = Color3.fromRGB(15, 20, 25)
		stroke.Thickness = 1.5
	end)

	btn.MouseButton1Click:Connect(function()
		if map.url ~= "" then
			loadstring(game:HttpGet(map.url))()
		else
			game.StarterGui:SetCore("SendNotification", {
				Title = "Unavailable";
				Text = map.name .. " coming soon!";
				Duration = 3;
			})
		end
	end)
end

-- RESIZER (fix posisi stabil)
local resizer = Instance.new("Frame")
resizer.Size = UDim2.new(0, 22, 0, 22)
resizer.AnchorPoint = Vector2.new(1, 1)
resizer.Position = UDim2.new(1, -6, 1, -6)
resizer.BackgroundColor3 = Color3.fromRGB(0, 255, 180)
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
		mainFrame.Size = UDim2.new(0, math.clamp(startSize.X.Offset + delta.X, 280, 800),
			0, math.clamp(startSize.Y.Offset + delta.Y, 200, 600))
	end
end)

-- AUTO ADAPT saat orientasi HP berubah
UIS.OrientationChanged:Connect(function()
	task.wait(0.2)
	if workspace.CurrentCamera.ViewportSize.X > workspace.CurrentCamera.ViewportSize.Y then
		mainFrame.Size = UDim2.new(0.7, 0, 0.6, 0)
		mainFrame.Position = UDim2.new(0.15, 0, 0.2, 0)
	else
		mainFrame.Size = UDim2.new(0.9, 0, 0.75, 0)
		mainFrame.Position = UDim2.new(0.05, 0, 0.125, 0)
	end
end)
