-- 📡 مسجّل الريموتات | صنع من قبل محمد TN
-- يسجّل كل ريموت ترسله اللعبة داخل ReplicatedStorage.Remotes

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- نراقب ReplicatedStorage.Remotes إذا موجود، وإلا كل الريموتات في اللعبة
local remotes = ReplicatedStorage:FindFirstChild("Remotes")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local IGNORED = { Ping = true }
-- نحد كل ريموت بـ 4 تسجيلات بالثانية عشان ما تنزحم القائمة
local rateWindow, rateCounts = os.clock(), {}
local MAX_LOGS = 40
local logs = {}
local startTime = os.clock()

local function serialize(value, depth)
	depth = depth or 0
	local kind = typeof(value)
	if kind == "string" then
		return string.format("%q", value)
	elseif kind == "number" then
		return (value % 1 == 0) and tostring(value) or string.format("%.3f", value)
	elseif kind == "Vector3" then
		return string.format("Vector3.new(%.2f, %.2f, %.2f)", value.X, value.Y, value.Z)
	elseif kind == "Vector2" then
		return string.format("Vector2.new(%.2f, %.2f)", value.X, value.Y)
	elseif kind == "CFrame" then
		local p, l = value.Position, value.LookVector
		return string.format("CFrame(pos=%.2f,%.2f,%.2f look=%.2f,%.2f,%.2f)", p.X, p.Y, p.Z, l.X, l.Y, l.Z)
	elseif kind == "Instance" then
		return value:GetFullName()
	elseif kind == "EnumItem" then
		return tostring(value)
	elseif kind == "table" then
		if depth > 2 then return "{...}" end
		local parts = {}
		for k, v in pairs(value) do
			table.insert(parts, "[" .. serialize(k, depth + 1) .. "]=" .. serialize(v, depth + 1))
		end
		return "{" .. table.concat(parts, ", ") .. "}"
	end
	return tostring(value) .. " (" .. kind .. ")"
end

-- الواجهة
local gui = Instance.new("ScreenGui")
gui.Name = "MohammedTN_RemoteLogger"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local frame = Instance.new("ScrollingFrame")
frame.Size = UDim2.new(0.55, 0, 0.5, 0)
frame.Position = UDim2.new(0.02, 0, 0.25, 0)
frame.BackgroundColor3 = Color3.fromRGB(14, 14, 22)
frame.BackgroundTransparency = 0.15
frame.AutomaticCanvasSize = Enum.AutomaticSize.XY
frame.CanvasSize = UDim2.new()
frame.Parent = gui

local box = Instance.new("TextBox")
box.Size = UDim2.new(1, 0, 0, 0)
box.AutomaticSize = Enum.AutomaticSize.XY
box.BackgroundTransparency = 1
box.TextColor3 = Color3.fromRGB(240, 240, 250)
box.Font = Enum.Font.Code
box.TextSize = 13
box.TextXAlignment = Enum.TextXAlignment.Left
box.TextYAlignment = Enum.TextYAlignment.Top
box.ClearTextOnFocus = false
box.TextEditable = false
box.MultiLine = true
box.Text = "📡 جاهز — كن حارس واضغط زر الكف ثم زر القفز"
box.Parent = frame

local function makeButton(text, x, color, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 90, 0, 34)
	btn.Position = UDim2.new(0.02, x, 0.25, -38)
	btn.Text = text
	btn.TextSize = 15
	btn.Font = Enum.Font.GothamBold
	btn.BackgroundColor3 = color
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Parent = gui
	btn.MouseButton1Click:Connect(callback)
	return btn
end

local function render()
	box.Text = table.concat(logs, "\n")
end

makeButton("نسخ", 0, Color3.fromRGB(46, 160, 100), function()
	if typeof(setclipboard) == "function" then
		pcall(setclipboard, table.concat(logs, "\n"))
		box.Text = "✓ تم النسخ\n\n" .. table.concat(logs, "\n")
	end
end)

makeButton("مسح", 96, Color3.fromRGB(80, 80, 110), function()
	table.clear(logs)
	startTime = os.clock()
	box.Text = "تم المسح"
end)

local active = true
makeButton("إغلاق", 192, Color3.fromRGB(235, 77, 75), function()
	active = false
	gui:Destroy()
end)

local function addLog(remote, method, args)
	if not active then return end
	local now = os.clock()
	if now - rateWindow > 1 then
		rateWindow = now
		table.clear(rateCounts)
	end
	rateCounts[remote] = (rateCounts[remote] or 0) + 1
	if rateCounts[remote] > 4 then return end
	local parts = {}
	for i = 1, args.n do
		parts[i] = serialize(args[i])
	end
	local line = string.format(
		"[%.1fs] %s:%s(%s)",
		os.clock() - startTime,
		remote:GetFullName():gsub("^ReplicatedStorage%.", ""),
		method,
		table.concat(parts, ", ")
	)
	table.insert(logs, line)
	if #logs > MAX_LOGS then
		table.remove(logs, 1)
	end
	render()
end

-- مراقبة الريموتات
if typeof(hookmetamethod) ~= "function" or typeof(getnamecallmethod) ~= "function" then
	box.Text = "❌ الـ Executor ما يدعم hookmetamethod"
	return
end

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
	if active and not checkcaller() then
		local method = getnamecallmethod()
		if (method == "FireServer" or method == "InvokeServer")
			and typeof(self) == "Instance"
			and not IGNORED[self.Name]
			and (not remotes or self:IsDescendantOf(remotes))
		then
			local args = table.pack(...)
			task.spawn(addLog, self, method, args)
		end
	end
	return oldNamecall(self, ...)
end)
