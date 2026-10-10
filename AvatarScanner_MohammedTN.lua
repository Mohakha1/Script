-- 🔍 فحص ريموتات الأفاتار | صنع من قبل محمد TN
-- ما يحتاج hookmetamethod ولا setclipboard: يعرض النتيجة بخط كبير للتصوير

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local KEYWORDS = {
	"wear", "avatar", "outfit", "body", "color", "colour", "skin", "cloth", "shirt",
	"pant", "hat", "hair", "accessor", "face", "character", "costume", "item", "equip",
	"size", "scale", "height", "emote", "animation", "tool",
}

local function isAvatarRelated(name)
	local lower = name:lower()
	for _, keyword in ipairs(KEYWORDS) do
		if lower:find(keyword, 1, true) then
			return true
		end
	end
	return false
end

local function supports(name)
	local ok, value = pcall(function()
		return getfenv(0)[name]
	end)
	return ok and value ~= nil
end

local lines = {}
local function add(text)
	table.insert(lines, text)
end

local executor = "؟"
if supports("identifyexecutor") then
	pcall(function()
		executor = tostring(identifyexecutor())
	end)
end
add("Executor: " .. executor)
local features = {}
for _, name in ipairs({ "hookmetamethod", "getnamecallmethod", "hookfunction", "getconnections", "setclipboard", "writefile", "firesignal" }) do
	table.insert(features, (supports(name) and "✓ " or "✗ ") .. name)
end
add(table.concat(features, "  "))
add("")

local related, others = {}, {}
for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
	if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("UnreliableRemoteEvent") then
		local path = obj:GetFullName():gsub("^ReplicatedStorage%.", "")
		local entry = path .. "  [" .. (obj:IsA("RemoteFunction") and "Function" or "Event") .. "]"
		if isAvatarRelated(obj.Name) then
			table.insert(related, entry)
		else
			table.insert(others, entry)
		end
	end
end

add("===== 👕 ريموتات الأفاتار (" .. #related .. ") =====")
for _, entry in ipairs(related) do
	add(entry)
end
add("")
add("===== باقي الريموتات (" .. #others .. ") =====")
for _, entry in ipairs(others) do
	add(entry)
end

local result = table.concat(lines, "\n")
print(result)

local copied = false
if supports("setclipboard") then
	copied = pcall(setclipboard, result)
end
if supports("writefile") then
	pcall(writefile, "MohammedTN_AvatarScan.txt", result)
end

-- نافذة كبيرة للتصوير
local gui = Instance.new("ScreenGui")
gui.Name = "MohammedTN_AvatarScanner"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.Parent = playerGui

local frame = Instance.new("ScrollingFrame")
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.new(0.5, 0, 0.52, 0)
frame.Size = UDim2.new(0.92, 0, 0.82, 0)
frame.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
frame.ScrollBarThickness = 8
frame.AutomaticCanvasSize = Enum.AutomaticSize.XY
frame.CanvasSize = UDim2.new()
frame.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

-- قابل للتحديد عشان تقدر تنسخ يدوي (ضغطة طويلة)
local box = Instance.new("TextBox")
box.Size = UDim2.new(1, -20, 0, 0)
box.Position = UDim2.new(0, 10, 0, 10)
box.AutomaticSize = Enum.AutomaticSize.XY
box.BackgroundTransparency = 1
box.TextColor3 = Color3.fromRGB(240, 240, 250)
box.Font = Enum.Font.Code
box.TextSize = 18
box.TextXAlignment = Enum.TextXAlignment.Left
box.TextYAlignment = Enum.TextYAlignment.Top
box.ClearTextOnFocus = false
box.TextEditable = true
box.MultiLine = true
box.Text = (copied and "✓ تم النسخ — الصقه لـ Claude\n\n" or "📸 صوّر الشاشة (وانزل وصوّر الباقي)\n\n") .. result
box.Parent = frame

local close = Instance.new("TextButton")
close.AnchorPoint = Vector2.new(1, 0)
close.Position = UDim2.new(0.96, 0, 0.06, 0)
close.Size = UDim2.new(0, 46, 0, 46)
close.Text = "✕"
close.TextSize = 24
close.Font = Enum.Font.GothamBold
close.BackgroundColor3 = Color3.fromRGB(235, 77, 75)
close.TextColor3 = Color3.new(1, 1, 1)
close.Parent = gui
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 23)
closeCorner.Parent = close
close.MouseButton1Click:Connect(function()
	gui:Destroy()
end)
