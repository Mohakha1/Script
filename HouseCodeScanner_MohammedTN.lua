-- 🔎 فحص كود البيت | صنع من قبل محمد TN
-- يدوّر بكل سكربتات اللعبة على الكود اللي يقفل البيت ويطرد ويفتح الأبواب

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- النافذة أول عشان تشوف التقدّم
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
box.TextSize = 15
box.TextXAlignment = Enum.TextXAlignment.Left
box.TextYAlignment = Enum.TextYAlignment.Top
box.ClearTextOnFocus = false
box.TextEditable = true
box.MultiLine = true
box.Text = "⏳ جاري الفحص..."
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

local lines = {}
local function add(text)
	table.insert(lines, text)
end
local function status(text)
	box.Text = "⏳ " .. text .. "\n\n" .. table.concat(lines, "\n")
end

local function short(obj)
	return (obj:GetFullName():gsub("^Players%.[^%.]+%.PlayerGui%.MainGUIHandler%.", "Gui.")
		:gsub("^Players%.[^%.]+%.PlayerScripts%.", "PS."):gsub("^ReplicatedStorage%.", "RS."))
end

local getconsts = (debug and debug.getconstants) or getconstants
local getprotos = (debug and debug.getprotos) or getprotos
add("decompile: " .. tostring(typeof(decompile) == "function")
	.. "  getscriptclosure: " .. tostring(typeof(getscriptclosure) == "function")
	.. "  getconstants: " .. tostring(typeof(getconsts) == "function"))

-- 1) شو يرجّع decompile للسكربت اللي لقيناه قبل
local handler = playerGui:FindFirstChild("MainGUIHandler")
local houseControl = handler and handler:FindFirstChild("HouseControl")
houseControl = houseControl and houseControl:FindFirstChild("LocalHouseControl")
if houseControl and typeof(decompile) == "function" then
	local ok, source = pcall(decompile, houseControl)
	source = tostring(source)
	add("LocalHouseControl: " .. (ok and "تم" or "خطأ") .. " — الطول " .. #source)
	add("أوله: " .. source:sub(1, 250):gsub("\n", " ⏎ "))
end
add("")

-- 2) نجمع كل السكربتات
local KEYWORDS = { "LockDoor", "Lock", "Disallow", "Door", "Kick", "Ban", "Permission", "Roommate" }
local scripts = {}
local function collect(root)
	if not root then return end
	for _, obj in ipairs(root:GetDescendants()) do
		if obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
			table.insert(scripts, obj)
		end
	end
end
collect(playerGui)
collect(player:FindFirstChild("PlayerScripts"))
collect(ReplicatedStorage)
add("عدد السكربتات: " .. #scripts)
add("")

local function matches(text)
	for _, keyword in ipairs(KEYWORDS) do
		if text:find(keyword, 1, true) then
			return true
		end
	end
	return false
end

-- 3) طريقة سريعة: النصوص الثابتة داخل كل سكربت
local hits = {}
if typeof(getscriptclosure) == "function" and typeof(getconsts) == "function" then
	add("== نصوص لها علاقة بالبيت ==")
	for i, script in ipairs(scripts) do
		if i % 25 == 0 then
			status("نصوص " .. i .. "/" .. #scripts)
			task.wait()
		end
		local found, seen = {}, {}
		local function scan(fn, depth)
			if depth > 6 or #found > 25 then return end
			local ok, consts = pcall(getconsts, fn)
			if ok and type(consts) == "table" then
				for _, c in pairs(consts) do
					if type(c) == "string" and #c < 80 and not seen[c] and matches(c) then
						seen[c] = true
						table.insert(found, c)
					end
				end
			end
			if typeof(getprotos) == "function" then
				local okP, protos = pcall(getprotos, fn)
				if okP and type(protos) == "table" then
					for _, proto in pairs(protos) do
						scan(proto, depth + 1)
					end
				end
			end
		end
		local ok, closure = pcall(getscriptclosure, script)
		if ok and type(closure) == "function" then
			scan(closure, 0)
		end
		if #found > 0 then
			table.insert(hits, script)
			add(short(script) .. ":")
			add("   " .. table.concat(found, " | "))
		end
	end
	add("")
end

-- 4) نقرأ كود السكربتات اللي فيها كلمات البيت (أو كلها إذا ما في طريقة سريعة)
if typeof(decompile) == "function" then
	add("== أسطر الكود ==")
	local list = #hits > 0 and hits or scripts
	local printed, checked = 0, 0
	for _, script in ipairs(list) do
		if printed >= 80 or checked >= 120 then break end
		checked += 1
		status("كود " .. checked .. "/" .. math.min(#list, 120))
		local ok, source = pcall(decompile, script)
		if ok and type(source) == "string" and matches(source) then
			local header = false
			local number = 0
			for line in (source .. "\n"):gmatch("(.-)\n") do
				number += 1
				local trimmed = line:gsub("^%s+", "")
				if (trimmed:find("FireServer", 1, true) or trimmed:find("InvokeServer", 1, true)
					or trimmed:find("Disallow", 1, true) or trimmed:find("LockDoor", 1, true)) then
					if not header then
						header = true
						add("-- " .. short(script))
					end
					printed += 1
					add(number .. ": " .. trimmed:sub(1, 170))
					if printed >= 80 then break end
				end
			end
		end
		task.wait()
	end
end

local result = table.concat(lines, "\n")
print(result)
pcall(function()
	setclipboard(result)
end)
pcall(function()
	writefile("MohammedTN_HouseCode.txt", result)
end)
box.Text = "✅ خلص — صوّر الشاشة (وانزل وصوّر الباقي)\n\n" .. result
