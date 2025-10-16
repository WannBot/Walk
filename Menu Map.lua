--// UI Select Map (Draggable, Scrollable, Resizable)
--// By WanBot

local player = game.Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "MapSelectUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- FRAME UTAMA
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 500, 0, 350)
mainFrame.Position = UDim2.new(0.5, -250, 0.5, -175)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = gui

-- HEADER
local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
header.Text = "Select Map"
header.Font = Enum.Font.GothamBold
header.TextColor3 = Color3.new(1,1,1)
header.TextScaled = true
header.Parent = mainFrame

-- CLOSE BUTTON
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -40, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 75, 75)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.TextScaled = true
closeBtn.Parent = mainFrame
closeBtn.MouseButton1Click:Connect(function()
	gui:Destroy()
end)

-- SCROLL FRAME
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -60)
scroll.Position = UDim2.new(0, 10, 0, 50)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.ScrollBarThickness = 8
scroll.BackgroundTransparency = 1
scroll.Parent = mainFrame

-- GRID LAYOUT
local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0, 115, 0, 50)
grid.CellPadding = UDim2.new(0, 10, 0, 10)
grid.FillDirectionMaxCells = 4
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = scroll

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 5)
padding.PaddingLeft = UDim.new(0, 5)
padding.Parent = scroll

-- DAFTAR MAP (nama + link loadstring)
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

-- BUAT BUTTON MAP
for _, map in ipairs(maps) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 100, 0, 40)
	btn.Text = map.name
	btn.Font = Enum.Font.GothamBold
	btn.TextScaled = true
	btn.TextColor3 = Color3.new(1,1,1)
	btn.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
	btn.AutoButtonColor = true
	btn.Parent = scroll

	btn.MouseButton1Click:Connect(function()
		if map.url ~= "" then
			loadstring(game:HttpGet(map.url))()
		else
			game.StarterGui:SetCore("SendNotification", {
				Title = "Unavailable";
				Text = map.name .. " is coming soon!";
				Duration = 3;
			})
		end
	end)
end

-- AUTO RESIZE SCROLL
grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scroll.CanvasSize = UDim2.new(0, 0, 0, grid.AbsoluteContentSize.Y + 20)
end)

-- RESIZER FRAME (pojok kanan bawah)
local resizer = Instance.new("Frame")
resizer.Size = UDim2.new(0, 20, 0, 20)
resizer.Position = UDim2.new(1, -20, 1, -20)
resizer.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
resizer.Active = true
resizer.Draggable = true
resizer.Parent = mainFrame

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

game:GetService("UserInputService").InputChanged:Connect(function(input)
	if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - startPos
		mainFrame.Size = UDim2.new(0, math.max(300, startSize.X.Offset + delta.X), 0, math.max(200, startSize.Y.Offset + delta.Y))
	end
end)
