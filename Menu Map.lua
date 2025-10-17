--// Select Map UI - Gradient Mountain Button Style
--// by WanBot

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "MapSelectUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

-- FRAME UTAMA
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0.85, 0, 0.75, 0)
mainFrame.Position = UDim2.new(0.075, 0, 0.125, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(10, 14, 18)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.ClipsDescendants = true
mainFrame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 25)
corner.Parent = mainFrame

-- GLOW RING
local glow = Instance.new("ImageLabel")
glow.Name = "Glow"
glow.Size = UDim2.new(1, 80, 1, 80)
glow.Position = UDim2.new(0.5, 0, 0.5, 0)
glow.AnchorPoint = Vector2.new(0.5, 0.5)
glow.BackgroundTransparency = 1
glow.Image = "rbxassetid://5028857084"
glow.ImageColor3 = Color3.fromRGB(120, 200, 255)
glow.ImageTransparency = 0.8
glow.ZIndex = 0
glow.Parent = mainFrame

-- HEADER
local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, 0, 0, 45)
header.BackgroundTransparency = 1
header.Text = "Select Map"
header.Font = Enum.Font.GothamBold
header.TextScaled = true
header.TextColor3 = Color3.fromRGB(210, 240, 255)
header.Parent = mainFrame

-- CLOSE BUTTON
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 35, 0, 35)
closeBtn.Position = UDim2.new(1, -45, 0, 5)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "×"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextColor3 = Color3.fromRGB(150, 200, 255)
closeBtn.TextScaled = true
closeBtn.Parent = mainFrame
closeBtn.MouseButton1Click:Connect(function()
	gui:Destroy()
end)

-- SCROLL
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -70)
scroll.Position = UDim2.new(0, 10, 0, 60)
scroll.BackgroundTransparency = 1
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollBarThickness = 6
scroll.ScrollBarImageColor3 = Color3.fromRGB(130, 180, 255)
scroll.Parent = mainFrame

local layout = Instance.new("UIGridLayout")
layout.CellSize = UDim2.new(0.45, 0, 0, 60)
layout.CellPadding = UDim2.new(0, 15, 0, 15)
layout.FillDirectionMaxCells = 2
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 10)
pad.Parent = scroll

-- DAFTAR MAP
local maps = {
	{ name = "ANTARTICA", url = "https://raw.githubusercontent.com/WannBot/Rbx/main/Map/Antartica.lua" },
	{ name = "SOON", url = "" },
	{ name = "SOON", url = "" },
	{ name = "SOON", url = "" },
	{ name = "SOON", url = "" },
	{ name = "SOON", url = "" },
}

-- GRADIENT BUTTON STYLE
local function createGradientButton(text)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 250, 0, 60)
	button.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
	button.AutoButtonColor = false
	button.Text = ""
	button.Parent = scroll

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = button

	-- GRADIENT
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 70, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 140, 255))
	}
	gradient.Rotation = 0
	gradient.Parent = button

	-- ICON + TEXT
	local icon = Instance.new("TextLabel")
	icon.Text = "⛰️"
	icon.Size = UDim2.new(0, 40, 1, 0)
	icon.BackgroundTransparency = 1
	icon.TextScaled = true
	icon.Font = Enum.Font.GothamBold
	icon.TextColor3 = Color3.new(1, 1, 1)
	icon.Parent = button

	local lbl = Instance.new("TextLabel")
	lbl.Text = text
	lbl.Size = UDim2.new(1, -40, 1, 0)
	lbl.Position = UDim2.new(0, 40, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = Color3.new(1, 1, 1)
	lbl.Font = Enum.Font.GothamSemibold
	lbl.TextScaled = true
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = button

	-- GLOW EFFECT (stroke halus)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(180, 220, 255)
	stroke.Thickness = 1
	stroke.Transparency = 0.8
	stroke.Parent = button

	-- Hover animation
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {Size = UDim2.new(0, 260, 0, 65)}):Play()
		stroke.Transparency = 0.4
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {Size = UDim2.new(0, 250, 0, 60)}):Play()
		stroke.Transparency = 0.8
	end)

	return button
end

-- BUAT TOMBOL UNTUK SETIAP MAP
for _, map in ipairs(maps) do
	local btn = createGradientButton(map.name)
	btn.MouseButton1Click:Connect(function()
		if map.url ~= "" then
			loadstring(game:HttpGet(map.url))()
		else
			game.StarterGui:SetCore("SendNotification", {
				Title = "Coming Soon";
				Text = map.name .. " map belum tersedia";
				Duration = 3;
			})
		end
	end)
end

-- RESIZER
local resizer = Instance.new("Frame")
resizer.Size = UDim2.new(0, 22, 0, 22)
resizer.AnchorPoint = Vector2.new(1, 1)
resizer.Position = UDim2.new(1, -6, 1, -6)
resizer.BackgroundColor3 = Color3.fromRGB(90, 140, 255)
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
