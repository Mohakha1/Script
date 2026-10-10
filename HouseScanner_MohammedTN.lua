-- 🏠 فحص البيت | صنع من قبل محمد TN
-- شغّله وأنت مالك بيت، وصوّر الشاشة كلها (انزل وصوّر الباقي)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local lines = {}
local function add(text)
	table.insert(lines, text)
end

local function supports(name)
	local ok, value = pcall(function()
		return getfenv(0)[name]
	end)
	return ok and value ~= nil
end

local function short(obj)
	return (obj:GetFullName():gsub("^Workspace%.", "W."):gsub("^Players%.[^%.]+%.PlayerGui%.", "Gui."))
end

-- 1) دعم الـ Executor
local features = {}
for _, name in ipairs({ "fireclickdetector", "fireproximityprompt", "firetouchinterest", "decompile", "getgc", "getsenv", "getscriptclosure", "firesignal", "getconnections" }) do
	table.insert(features, (supports(name) and "✓ " or "✗ ") .. name)
end
add("== Executor ==")
add(table.concat(features, "  "))
add("")

-- 2) ندوّر على أي شي مكتوب فيه اسمي أو رقمي بالماب
add("== أشياء فيها اسمك (" .. player.Name .. ") ==")
local myName, myId = player.Name, player.UserId
local found, houseRoots = 0, {}
for _, obj in ipairs(Workspace:GetDescendants()) do
	if found >= 25 then break end
	local hit = nil
	if obj:IsA("ObjectValue") and obj.Value == player then
		hit = "ObjectValue=" .. obj.Name
	elseif obj:IsA("StringValue") and (obj.Value == myName or obj.Value == tostring(myId)) then
		hit = "StringValue=" .. obj.Name
	elseif (obj:IsA("IntValue") or obj:IsA("NumberValue")) and obj.Value == myId then
		hit = "IntValue=" .. obj.Name
	else
		for key, value in pairs(obj:GetAttributes()) do
			if value == myName or value == myId or value == tostring(myId) then
				hit = "Attribute " .. key
				break
			end
		end
	end
	if hit then
		found += 1
		add(short(obj) .. "  [" .. hit .. "]")
		-- أعلى موديل تحت مجلد بالـ Workspace = البيت غالباً
		local node = obj
		while node.Parent and node.Parent ~= Workspace and node.Parent.Parent ~= Workspace do
			node = node.Parent
		end
		houseRoots[node] = true
	end
end
if found == 0 then
	add("ما لقيت شي — تأكد إنك مختار بيت")
end
add("")

-- 3) محتويات البيت: أبواب وأزرار
for root in pairs(houseRoots) do
	add("== داخل: " .. short(root) .. " ==")
	local count = 0
	for _, obj in ipairs(root:GetDescendants()) do
		if obj:IsA("ClickDetector") or obj:IsA("ProximityPrompt") or obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")
			or obj:IsA("BindableEvent") or obj:IsA("Script") or obj:IsA("LocalScript") then
			count += 1
			if count > 30 then break end
			local extra = obj:IsA("ProximityPrompt") and ("  '" .. obj.ActionText .. "'") or ""
			add(obj.ClassName .. ": " .. short(obj) .. extra)
		end
	end
	if count == 0 then
		add("ما فيه أزرار/أبواب قابلة للضغط")
		local names = {}
		for _, child in ipairs(root:GetChildren()) do
			table.insert(names, child.Name)
			if #names >= 25 then break end
		end
		add("الأبناء: " .. table.concat(names, ", "))
	end
	add("")
end

-- 4) قوائم البيت باللعبة (أزرار قفل/طرد/باب)
add("== أزرار البيت بالواجهة ==")
local keywords = { "house", "home", "lock", "kick", "ban", "door", "permission", "property", "lot" }
local guiCount = 0
for _, obj in ipairs(playerGui:GetDescendants()) do
	if guiCount >= 30 then break end
	if obj:IsA("GuiButton") or obj:IsA("LocalScript") then
		local text = (obj.Name .. " " .. (obj:IsA("TextButton") and obj.Text or "")):lower()
		for _, keyword in ipairs(keywords) do
			if text:find(keyword, 1, true) then
				guiCount += 1
				add(obj.ClassName .. ": " .. short(obj))
				break
			end
		end
	end
end
if guiCount == 0 then
	add("ما لقيت — افتح قائمة البيت باللعبة وشغّل الفحص مرة ثانية")
end
add("")

-- 5) كل ريموتات RE
add("== ReplicatedStorage.RE ==")
local re = ReplicatedStorage:FindFirstChild("RE")
if re then
	local names = {}
	for _, obj in ipairs(re:GetChildren()) do
		table.insert(names, obj.Name)
	end
	add(table.concat(names, "  "))
end

local result = table.concat(lines, "\n")
print(result)
if supports("setclipboard") then
	pcall(setclipboard, result)
end
if supports("writefile") then
	pcall(writefile, "MohammedTN_HouseScan.txt", result)
end

-- نافذة كبيرة للتصوير
local gui = Instance.new("ScreenGui")
gui.Name = "MohammedTN_HouseScanner"
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
box.TextSize = 17
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
