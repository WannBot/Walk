--// Select Map UI (Refined Mountain Gradient)
--// by WanBot 2025
--// Smooth, professional, responsive design

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-- MAIN GUI
local gui = Instance.new("ScreenGui")
gui.Name = "MapSelectUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

-- MAIN FRAME
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0.8, 0, 0.7, 0)
mainFrame.Position = UDim2.new(0.1, 0, 0.15, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.ClipsDescendants = true
mainFrame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 20)
corner.Parent = mainFrame

-- HEADER
local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, -40, 0, 45)
header.Position = UDim2.new(0, 15, 0, 0)
header.BackgroundTransparency = 1
header.Text = "Select Map"
header.Font = Enum.Font.GothamBold
header.TextScaled = true
header.TextColor3 = Color3.fromRGB(235, 245, 255)
header.TextXAlignment = Enum.TextXAlignment.Left
header.Parent = mainFrame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -40, 0, 8)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "×"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextScaled = true
closeBtn.TextColor3 = Color3.fromRGB(180, 200, 255)
closeBtn.Parent = mainFrame
closeBtn.MouseButton1Click:Connect(function()
	gui:Destroy()
end)

-- SCROLLING AREA
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -60)
scroll.Position = UDim2.new(0, 10, 0, 50)
scroll.BackgroundTransparency = 1
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.ScrollBarThickness = 6
scroll.ScrollBarImageColor3 = Color3.fromRGB(120, 160, 255)
scroll.Parent = mainFrame

local layout = Instance.new("UIGridLayout")
layout.CellSize = UDim2.new(0.45, 0, 0, 55)
layout.CellPadding = UDim2.new(0, 12, 0, 12)
layout.FillDirectionMaxCells = 2
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 10)
pad.Parent = scroll

-- MAP DATA
local maps = {
	{ name = "ANTARTICA", url = "https://raw.githubusercontent.com/WannBot/Rbx/main/Map/Antartica.lua" },
	{ name = "SOON", url = "" },
	{ name = "SOON", url = "" },
	{ name = "SOON", url = "" },
	{ name = "SOON", url = "" },
	{ name = "SOON", url = "" },
}

-- CREATE BUTTON FUNCTION
local function createButton(map)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 240, 0, 55)
	button.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
	button.AutoButtonColor = false
	button.Text = ""
	button.Parent = scroll

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = button

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(130, 70, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 130, 255))
	}
	gradient.Parent = button

	-- ICON GUNUNG
	local icon = Instance.new("ImageLabel")
	icon.BackgroundTransparency = 1
	icon.Image = "rbxassetid://13709915614" -- ikon gunung minimalis
	icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
	icon.Size = UDim2.new(0, 24, 0, 24)
	icon.Position = UDim2.new(0, 18, 0.5, -12)
	icon.Parent = button

	-- LABEL TEKS
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Text = map.name
	lbl.Font = Enum.Font.GothamSemibold
	lbl.TextColor3 = Color3.new(1, 1, 1)
	lbl.TextScaled = true
	lbl.Size = UDim2.new(1, -60, 1, 0)
	lbl.Position = UDim2.new(0, 60, 0, 0)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(200, 230, 255)
	stroke.Thickness = 0.8
	stroke.Transparency = 0.7
	stroke.Parent = button

	-- Hover anim
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {
			Size = UDim2.new(0, 250, 0, 60)
		}):Play()
		stroke.Transparency = 0.3
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {
			Size = UDim2.new(0, 240, 0, 55)
		}):Play()
		stroke.Transparency = 0.7
	end)

	button.MouseButton1Click:Connect(function()
		if map.url ~= "" then
			loadstring(game:HttpGet(map.url))()
		else
			game.StarterGui:SetCore("SendNotification", {
				Title = "Coming Soon",
				Text = map.name .. " belum tersedia",
				Duration = 3
			})
		end
	end)

	return button
end

-- CREATE ALL BUTTONS
for _, map in ipairs(maps) do
	createButton(map)
end

-- SMOOTH RESIZER (tidak bergeser)
local resizer = Instance.new("Frame")
resizer.Size = UDim2.new(0, 20, 0, 20)
resizer.AnchorPoint = Vector2.new(1, 1)
resizer.Position = UDim2.new(1, -5, 1, -5)
resizer.BackgroundColor3 = Color3.fromRGB(100, 140, 255)
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
