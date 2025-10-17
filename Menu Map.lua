--// Select Map UI (Final Responsive Mountain Style)
--// by WanBot 2025

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "MapSelectUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

----------------------------------------------------
-- FRAME UTAMA
----------------------------------------------------
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 420, 0, 280) -- ukuran pas seperti screenshot
mainFrame.Position = UDim2.new(0.5, -210, 0.5, -140)
mainFrame.BackgroundColor3 = Color3.fromRGB(10, 14, 20)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.ClipsDescendants = true
mainFrame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 18)
corner.Parent = mainFrame

-- Stroke halus pinggiran
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(60, 100, 255)
stroke.Thickness = 1.5
stroke.Transparency = 0.6
stroke.Parent = mainFrame

----------------------------------------------------
-- HEADER
----------------------------------------------------
local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, -40, 0, 40)
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
closeBtn.Position = UDim2.new(1, -38, 0, 5)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "×"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextScaled = true
closeBtn.TextColor3 = Color3.fromRGB(180, 200, 255)
closeBtn.Parent = mainFrame
closeBtn.MouseButton1Click:Connect(function()
	gui:Destroy()
end)

----------------------------------------------------
-- SCROLL FRAME
----------------------------------------------------
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -55)
scroll.Position = UDim2.new(0, 10, 0, 45)
scroll.BackgroundTransparency = 1
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollBarThickness = 6
scroll.ScrollBarImageColor3 = Color3.fromRGB(100, 160, 255)
scroll.Parent = mainFrame

local layout = Instance.new("UIGridLayout")
layout.CellSize = UDim2.new(0.46, 0, 0.25, 0) -- responsif
layout.CellPadding = UDim2.new(0, 10, 0, 10)
layout.FillDirectionMaxCells = 2
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 10)
pad.Parent = scroll

----------------------------------------------------
-- MAP LIST
----------------------------------------------------
local maps = {
	{ name = "ANTARTICA", url = "https://raw.githubusercontent.com/WannBot/Rbx/main/Map/Antartica.lua" },
	{ name = "SOON", url = "" },
	{ name = "SOON", url = "" },
	{ name = "SOON", url = "" },
	{ name = "SOON", url = "" },
	{ name = "SOON", url = "" },
}

----------------------------------------------------
-- FUNGSI BUAT TOMBOL
----------------------------------------------------
local function createButton(map)
	local button = Instance.new("TextButton")
	button.BackgroundColor3 = Color3.fromRGB(90, 90, 255)
	button.AutoButtonColor = false
	button.Text = ""
	button.Parent = scroll

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = button

	-- Gradasi
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(130, 70, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 110, 255))
	}
	gradient.Parent = button

	-- Ikon Gunung (emoji ⛰️ agar ringan di mobile)
	local icon = Instance.new("TextLabel")
	icon.BackgroundTransparency = 1
	icon.Text = "⛰️"
	icon.Font = Enum.Font.Gotham
	icon.TextColor3 = Color3.new(1, 1, 1)
	icon.TextScaled = true
	icon.Size = UDim2.new(0.3, 0, 1, 0)
	icon.Position = UDim2.new(0, 5, 0, 0)
	icon.TextXAlignment = Enum.TextXAlignment.Center
	icon.Parent = button

	-- Label teks
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Text = map.name
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextColor3 = Color3.new(1, 1, 1)
	lbl.TextScaled = true
	lbl.Size = UDim2.new(0.7, -10, 1, 0)
	lbl.Position = UDim2.new(0.3, 0, 0, 0)
	lbl.TextXAlignment = Enum.TextXAlignment.Center
	lbl.Parent = button

	-- Hover animasi lembut
	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = Color3.fromRGB(110, 110, 255)
	end)
	button.MouseLeave:Connect(function()
		button.BackgroundColor3 = Color3.fromRGB(90, 90, 255)
	end)

	-- Click Action
	button.MouseButton1Click:Connect(function()
		if map.url ~= "" then
			loadstring(game:HttpGet(map.url))()
		else
			game.StarterGui:SetCore("SendNotification", {
				Title = "Coming Soon",
				Text = map.name .. " belum tersedia",
				Duration = 3,
			})
		end
	end)
end

-- Buat semua tombol
for _, map in ipairs(maps) do
	createButton(map)
end

----------------------------------------------------
-- RESIZER
----------------------------------------------------
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
		local newX = math.clamp(startSize.X.Offset + delta.X, 350, 600)
		local newY = math.clamp(startSize.Y.Offset + delta.Y, 250, 400)
		mainFrame.Size = UDim2.new(0, newX, 0, newY)
	end
end)
