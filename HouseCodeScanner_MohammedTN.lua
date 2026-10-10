-- 🔎 فحص كود البيت | صنع من قبل محمد TN
-- يقرأ سكربتات البيت باللعبة ويطلّع الأسطر اللي ترسل أوامر (قفل، طرد، أبواب)

local Players = game:GetService("Players")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local lines = {}
local function add(text)
	table.insert(lines, text)
end

if typeof(decompile) ~= "function" then
	add("❌ برنامج التشغيل ما يدعم decompile")
end

local handler = playerGui:FindFirstChild("MainGUIHandler")
local targets = {}
if handler then
	for _, name in ipairs({ "HouseControl", "HouseControlPanel", "Client2Client" }) do
		local holder = handler:FindFirstChild(name)
		if holder then
			if holder:IsA("LocalScript") or holder:IsA("ModuleScript") then
				table.insert(targets, holder)
			end
			for _, obj in ipairs(holder:GetDescendants()) do
				if obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
					table.insert(targets, obj)
				end
			end
		end
	end
end
if #targets == 0 then
	add("ما لقيت سكربتات البيت — افتح قائمة البيت وجرب مرة ثانية")
end

-- الأسطر المهمة بس
local patterns = { "FireServer", "InvokeServer", "Permissions", "Lock", "Disallow", "Door", "Kick", "Ban" }
local MAX_LINES = 70
local total = 0
for _, script in ipairs(targets) do
	if total >= MAX_LINES then break end
	local ok, source = pcall(decompile, script)
	add("===== " .. script:GetFullName():gsub("^Players%.[^%.]+%.PlayerGui%.MainGUIHandler%.", "") .. " =====")
	if not ok or type(source) ~= "string" then
		add("(ما قدر يقرأه)")
	else
		local seen = {}
		local number = 0
		for line in (source .. "\n"):gmatch("(.-)\n") do
			number += 1
			local trimmed = line:gsub("^%s+", "")
			for _, pattern in ipairs(patterns) do
				if trimmed:find(pattern, 1, true) and not seen[trimmed] then
					seen[trimmed] = true
					total += 1
					add(number .. ": " .. trimmed:sub(1, 160))
					break
				end
			end
			if total >= MAX_LINES then break end
		end
	end
	add("")
end

local result = table.concat(lines, "\n")
print(result)
pcall(function()
	setclipboard(result)
end)
pcall(function()
	writefile("MohammedTN_HouseCode.txt", result)
end)

-- نافذة كبيرة للتصوير
local gui = Instance.new("ScreenGui")
gui.Name = "MohammedTN_HouseCode"
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
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local box = Instance.new("TextBox")
box.Size = UDim2.new(1, -20, 0, 0)
box.Position = UDim2.new(0, 10, 0, 10)
box.AutomaticSize = Enum.AutomaticSize.XY
box.BackgroundTransparency = 1
box.TextColor3 = Color3.fromRGB(240, 240, 250)
box.Font = Enum.Font.Code
box.TextSize = 16
box.TextXAlignment = Enum.TextXAlignment.Left
box.TextYAlignment = Enum.TextYAlignment.Top
box.ClearTextOnFocus = false
box.TextEditable = true
box.MultiLine = true
box.Text = "📸 صوّر الشاشة (وانزل وصوّر الباقي)\n\n" .. result
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
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 23)
close.MouseButton1Click:Connect(function()
	gui:Destroy()
end)
