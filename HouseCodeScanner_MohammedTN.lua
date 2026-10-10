-- 🔎 فحص كود البيت (3) | صنع من قبل محمد TN
-- يطلّع كود LocalHouseControl كامل، وأوامر موديول PlayersHouse

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

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

local function source(script)
	local ok, result = pcall(decompile, script)
	if ok and type(result) == "string" then
		return result
	end
	return nil
end

local function eachLine(text, fn)
	local number = 0
	for line in (text .. "\n"):gmatch("(.-)\n") do
		number += 1
		if fn(number, line) == false then break end
	end
end

-- 1) LocalHouseControl كامل (قصير)
local handler = playerGui:FindFirstChild("MainGUIHandler")
local houseControl = handler and handler:FindFirstChild("HouseControl")
houseControl = houseControl and houseControl:FindFirstChild("LocalHouseControl")
add("===== LocalHouseControl =====")
local hcSource = houseControl and source(houseControl)
if hcSource then
	eachLine(hcSource, function(n, line)
		if line:match("%S") and not line:find("lua.expert", 1, true) then
			add(n .. ": " .. line:gsub("^%s+", ""):sub(1, 170))
		end
	end)
else
	add("(ما لقيته)")
end
add("")

-- 2) Client_To_Client حول TryDisallow
local p8 = playerGui:FindFirstChild("Player8Handler")
local c2c = p8 and p8:FindFirstChild("Client_To_Client")
add("===== Client_To_Client (الطرد) =====")
local c2cSource = c2c and source(c2c)
if c2cSource then
	eachLine(c2cSource, function(n, line)
		if (n >= 225 and n <= 240) or (n >= 296 and n <= 330) then
			if line:match("%S") then
				add(n .. ": " .. line:gsub("^%s+", ""):sub(1, 170))
			end
		end
		if n > 330 then return false end
	end)
else
	add("(ما لقيته)")
end
add("")

-- 3) موديول PlayersHouse: كل الدوال والأوامر
local modules = {}
for _, root in ipairs({ ReplicatedStorage, playerGui, player:FindFirstChild("PlayerScripts") }) do
	if root then
		for _, obj in ipairs(root:GetDescendants()) do
			if obj:IsA("ModuleScript") and (obj.Name == "PlayersHouse" or obj.Name:find("Permission") or obj.Name:find("HouseControl")) then
				table.insert(modules, obj)
			end
		end
	end
end
for _, module in ipairs(modules) do
	add("===== " .. module:GetFullName():gsub("^Players%.[^%.]+%.", "") .. " =====")
	local text = source(module)
	if text then
		local printed = 0
		eachLine(text, function(n, line)
			local t = line:gsub("^%s+", "")
			if t:find("function", 1, true) or t:find("Invoke", 1, true) or t:find("Fire", 1, true)
				or t:find("Lock", 1, true) or t:find("Door", 1, true) or t:find("Permissions:", 1, true)
				or t:find("require", 1, true) then
				printed += 1
				add(n .. ": " .. t:sub(1, 170))
			end
			if printed >= 90 then return false end
		end)
	else
		add("(ما قدر يقرأه)")
	end
	add("")
end
if #modules == 0 then
	add("ما لقيت موديول PlayersHouse")
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
