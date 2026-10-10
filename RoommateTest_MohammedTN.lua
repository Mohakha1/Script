-- 👥 تجربة شريك السكن | صنع من قبل محمد TN
-- يضيف أو يشيل لاعبين كشركاء سكن ببيتك أنت (لازم تكون مالك بيت)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- بيتي: 001_Lots.<lot>.OwnerObj == أنا
local function myHouseModel()
	local lots = Workspace:FindFirstChild("001_Lots")
	if not lots then return nil end
	for _, lot in ipairs(lots:GetChildren()) do
		local ownerObj = lot:FindFirstChild("OwnerObj")
		if ownerObj and ownerObj:IsA("ObjectValue") and ownerObj.Value == player then
			local picked = lot:FindFirstChild("HousePickedByPlayer")
			return picked and picked:FindFirstChild("HouseModel")
		end
	end
	return nil
end

local old = playerGui:FindFirstChild("MohammedTN_Roommate")
if old then
	old:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "MohammedTN_Roommate"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.new(0.5, 0, 0.5, 0)
frame.Size = UDim2.new(0, 320, 0, 360)
frame.BackgroundColor3 = Color3.fromRGB(16, 16, 27)
frame.Active = true
frame.Draggable = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -50, 0, 40)
title.Position = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Text = "👥 شركاء السكن ببيتك"
title.TextColor3 = Color3.fromRGB(242, 242, 252)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Right
title.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -24, 0, 20)
status.Position = UDim2.new(0, 12, 0, 38)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(146, 146, 176)
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.TextXAlignment = Enum.TextXAlignment.Right
status.Text = ""
status.Parent = frame

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 30, 0, 30)
close.Position = UDim2.new(0, 8, 0, 6)
close.Text = "✕"
close.TextColor3 = Color3.new(1, 1, 1)
close.BackgroundColor3 = Color3.fromRGB(235, 77, 75)
close.Font = Enum.Font.GothamBold
close.Parent = frame
Instance.new("UICorner", close).CornerRadius = UDim.new(1, 0)
close.MouseButton1Click:Connect(function()
	gui:Destroy()
end)

local list = Instance.new("ScrollingFrame")
list.Position = UDim2.new(0, 10, 0, 64)
list.Size = UDim2.new(1, -20, 1, -74)
list.BackgroundTransparency = 1
list.ScrollBarThickness = 4
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.Parent = frame
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.Parent = list

local function send(remoteName, target)
	local house = myHouseModel()
	if not house then
		status.Text = "❌ ما عندك بيت — اختار بيت أول"
		return
	end
	local remote = house:FindFirstChild("Permissions:" .. remoteName)
	if not remote then
		status.Text = "❌ ما لقيت الأمر " .. remoteName
		return
	end
	local ok = pcall(function()
		remote:FireServer(target)
	end)
	status.Text = ok and ("✓ انرسل: " .. remoteName .. " → " .. target.DisplayName) or "❌ صار خطأ"
end

local function button(parent, text, x, color, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 56, 0, 26)
	btn.Position = UDim2.new(0, x, 0.5, -13)
	btn.Text = text
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.BackgroundColor3 = color
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12
	btn.Parent = parent
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	btn.MouseButton1Click:Connect(callback)
end

local function refresh()
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	status.Text = myHouseModel() and "✓ لقيت بيتك" or "❌ ما عندك بيت — اختار بيت أول"
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, -6, 0, 40)
			row.BackgroundColor3 = Color3.fromRGB(22, 22, 35)
			row.Parent = list
			Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
			local name = Instance.new("TextLabel")
			name.Size = UDim2.new(1, -140, 1, 0)
			name.Position = UDim2.new(0, 130, 0, 0)
			name.BackgroundTransparency = 1
			name.Text = other.DisplayName
			name.TextColor3 = Color3.fromRGB(242, 242, 252)
			name.Font = Enum.Font.Gotham
			name.TextSize = 13
			name.TextTruncate = Enum.TextTruncate.AtEnd
			name.TextXAlignment = Enum.TextXAlignment.Right
			name.Parent = row
			button(row, "➕ ضيف", 6, Color3.fromRGB(46, 160, 100), function()
				send("AddRoommate", other)
			end)
			button(row, "➖ شيل", 68, Color3.fromRGB(150, 60, 70), function()
				send("RemoveRoommate", other)
			end)
		end
	end
end

refresh()
Players.PlayerAdded:Connect(function()
	if gui.Parent then refresh() end
end)
Players.PlayerRemoving:Connect(function()
	task.defer(function()
		if gui.Parent then refresh() end
	end)
end)
