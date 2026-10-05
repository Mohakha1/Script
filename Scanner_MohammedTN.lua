-- 🔍 سكربت فحص الماب | صنع من قبل محمد TN
-- يجمع أزرار الجوال والريموتات وينسخها للحافظة

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local lines = {}

local function add(text)
	table.insert(lines, text)
end

-- عدد الدوال المربوطة بإشارة معيّنة (يوضح الزر يشتغل بأي طريقة)
local function connectionCount(obj, signalName)
	if typeof(getconnections) ~= "function" then return "?" end
	local ok, result = pcall(function()
		return #getconnections(obj[signalName])
	end)
	return ok and result or "-"
end

local function describe(obj)
	local info = obj.Name .. " [" .. obj.ClassName .. "]"
	if obj:IsA("GuiObject") and not obj.Visible then
		info ..= " (مخفي)"
	end
	if obj:IsA("GuiButton") then
		info ..= string.format(
			" {Activated=%s Click=%s Down=%s InputBegan=%s}",
			tostring(connectionCount(obj, "Activated")),
			tostring(connectionCount(obj, "MouseButton1Click")),
			tostring(connectionCount(obj, "MouseButton1Down")),
			tostring(connectionCount(obj, "InputBegan"))
		)
	end
	return info
end

local function dump(obj, depth, maxDepth, filter)
	if depth > maxDepth then return end
	if not filter or filter(obj) then
		add(string.rep("  ", depth) .. describe(obj))
	end
	for _, child in ipairs(obj:GetChildren()) do
		dump(child, depth + 1, maxDepth, filter)
	end
end

add("===== أزرار الجوال (Main > Game > Mobile) =====")
local mobile = playerGui:FindFirstChild("Main")
mobile = mobile and mobile:FindFirstChild("Game")
mobile = mobile and mobile:FindFirstChild("Mobile")
if mobile then
	dump(mobile, 0, 6)
else
	add("ما لقيت Mobile")
end

add("")
add("===== كل الأزرار في PlayerGui =====")
for _, obj in ipairs(playerGui:GetDescendants()) do
	if obj:IsA("GuiButton") and obj.Visible then
		local path = obj:GetFullName():gsub("^.-PlayerGui%.", "")
		add(path .. " " .. describe(obj):gsub("^[^%[]+", ""))
	end
end

add("")
add("===== الريموتات (ReplicatedStorage) =====")
for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
	if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("UnreliableRemoteEvent") then
		add(obj:GetFullName() .. " [" .. obj.ClassName .. "]")
	end
end

add("")
add("===== الكرة =====")
local footballs = workspace:FindFirstChild("Footballs")
local ball = footballs and footballs:FindFirstChild("Ball")
if ball then
	dump(ball, 0, 2)
end

local result = table.concat(lines, "\n")
print(result)

local copied = false
if typeof(setclipboard) == "function" then
	copied = pcall(setclipboard, result)
end
if typeof(writefile) == "function" then
	pcall(writefile, "MohammedTN_Scan.txt", result)
end

-- نافذة تعرض النتيجة
local gui = Instance.new("ScreenGui")
gui.Name = "MohammedTN_Scanner"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local frame = Instance.new("ScrollingFrame")
frame.Size = UDim2.new(0.8, 0, 0.7, 0)
frame.Position = UDim2.new(0.1, 0, 0.15, 0)
frame.BackgroundColor3 = Color3.fromRGB(14, 14, 22)
frame.AutomaticCanvasSize = Enum.AutomaticSize.XY
frame.CanvasSize = UDim2.new()
frame.Parent = gui

local box = Instance.new("TextBox")
box.Size = UDim2.new(1, 0, 0, 0)
box.AutomaticSize = Enum.AutomaticSize.XY
box.BackgroundTransparency = 1
box.TextColor3 = Color3.fromRGB(240, 240, 250)
box.Font = Enum.Font.Code
box.TextSize = 14
box.TextXAlignment = Enum.TextXAlignment.Left
box.TextYAlignment = Enum.TextYAlignment.Top
box.ClearTextOnFocus = false
box.TextEditable = false
box.MultiLine = true
box.Text = (copied and "✓ تم النسخ — الصقه لـ Claude\n\n" or "الصق هذا لـ Claude (أو صوّره)\n\n") .. result
box.Parent = frame

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 40, 0, 40)
close.Position = UDim2.new(0.9, -40, 0.15, -44)
close.Text = "✕"
close.TextSize = 22
close.BackgroundColor3 = Color3.fromRGB(235, 77, 75)
close.TextColor3 = Color3.new(1, 1, 1)
close.Parent = gui
close.MouseButton1Click:Connect(function()
	gui:Destroy()
end)
