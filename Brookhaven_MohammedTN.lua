--[[
	╔══════════════════════════════════════════╗
	║        🏡  Brookhaven Hub  🏡             ║
	║          صنع من قبل: محمد TN             ║
	║                 v2.0                     ║
	╚══════════════════════════════════════════╝

	• إظهار / إخفاء الواجهة : RightShift
	• طيران : F   •   اختراق الجدران : N
	• انتقال بالضغط (كمبيوتر) : Ctrl + كليك
	• يدعم الكمبيوتر والجوال
]]

-----------------------------------------------------------
-- الخدمات
-----------------------------------------------------------
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")

local VirtualUser
pcall(function()
	VirtualUser = game:GetService("VirtualUser")
end)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-----------------------------------------------------------
-- الإعدادات الثابتة
-----------------------------------------------------------
local CONFIG = {
	Name = "Brookhaven Hub",
	Version = "v2.0",
	Author = "محمد TN",
	SaveFile = "MohammedTN_Brookhaven.json",
	Width = 690,
	Height = 440,
	Sidebar = 172,
	Themes = {
		{ Name = "بنفسجي", Accent = Color3.fromRGB(124, 92, 255), Accent2 = Color3.fromRGB(0, 190, 255) },
		{ Name = "وردي",   Accent = Color3.fromRGB(255, 80, 160), Accent2 = Color3.fromRGB(255, 160, 90) },
		{ Name = "أخضر",   Accent = Color3.fromRGB(46, 204, 113), Accent2 = Color3.fromRGB(0, 200, 180) },
		{ Name = "ذهبي",   Accent = Color3.fromRGB(255, 190, 40), Accent2 = Color3.fromRGB(255, 110, 40) },
		{ Name = "أحمر",   Accent = Color3.fromRGB(235, 64, 90),  Accent2 = Color3.fromRGB(150, 60, 255) },
	},
}

local THEME = {
	Background   = Color3.fromRGB(11, 11, 18),
	Sidebar      = Color3.fromRGB(16, 16, 27),
	Surface      = Color3.fromRGB(22, 22, 35),
	SurfaceLight = Color3.fromRGB(34, 34, 54),
	Stroke       = Color3.fromRGB(54, 54, 86),
	Accent       = CONFIG.Themes[1].Accent,
	Accent2      = CONFIG.Themes[1].Accent2,
	Text         = Color3.fromRGB(242, 242, 252),
	SubText      = Color3.fromRGB(146, 146, 176),
	Success      = Color3.fromRGB(46, 204, 113),
	Danger       = Color3.fromRGB(235, 77, 75),
	Warning      = Color3.fromRGB(255, 190, 40),
}

local FONT_BOLD = Enum.Font.GothamBold
local FONT_REG = Enum.Font.Gotham

-----------------------------------------------------------
-- تنظيف أي نسخة سابقة
-----------------------------------------------------------
if _G.MohammedTN_Brookhaven_Cleanup then
	pcall(_G.MohammedTN_Brookhaven_Cleanup)
end

-----------------------------------------------------------
-- الحالة
-----------------------------------------------------------
local state = {
	-- الحركة
	speedOn = false, walkSpeed = 50,
	jumpOn = false, jumpPower = 100,
	infJump = false,
	noclip = false,
	fly = false, flySpeed = 70,
	-- السيارات
	carBoost = false, carSpeed = 120,
	carFly = false, carFlySpeed = 90,
	carBrake = false,
	-- التنقّل
	clickTp = false,
	waypoints = {},
	-- الرؤية
	espNames = false, espHighlight = false, espTracers = false, espHealth = true,
	espMaxDistance = 1000,
	-- العالم
	fullbright = false, noFog = false,
	timeLock = false, clockTime = 14,
	fov = 70, fovOn = false,
	-- الحماية
	antiFling = true, antiVoid = true, antiAfk = true, antiSit = false,
	-- الواجهة
	showStats = true, blur = true,
	themeIndex = 1, activePage = 1,
	toggleKey = "RightShift",
	floatingButton = UserInputService.TouchEnabled,
	-- v2.0
	hover = false,
	tpWalk = false, tpWalkSpeed = 3,
	autoJump = false,
	gravityOn = false, gravity = 80,
	freecamSpeed = 60,
	maxZoom = false, firstPerson = false,
	lowGraphics = false, xray = false, fpsUnlock = false, fpsCap = 240,
	trail = false, musicId = "", musicVolume = 0.6,
	deleteMode = false,
	flyKey = "F", noclipKey = "N", screenshotKey = "P",
	-- السكنات
	wearSig = 0, outfits = {}, colorSig = 0, bundleSig = 0,

	-- غير محفوظة
	guiVisible = true,
}

local SAVED_KEYS = {
	"speedOn", "walkSpeed", "jumpOn", "jumpPower", "infJump", "flySpeed",
	"carBoost", "carSpeed", "carFlySpeed", "carBrake", "waypoints",
	"espNames", "espHighlight", "espTracers", "espHealth", "espMaxDistance",
	"fullbright", "noFog", "timeLock", "clockTime", "fov", "fovOn",
	"antiFling", "antiVoid", "antiAfk", "antiSit",
	"showStats", "blur", "themeIndex", "activePage", "toggleKey", "floatingButton",
	"tpWalkSpeed", "autoJump", "gravity", "freecamSpeed", "maxZoom", "firstPerson",
	"fpsUnlock", "fpsCap", "trail", "musicId", "musicVolume", "flyKey", "noclipKey", "screenshotKey",
	"wearSig", "outfits", "colorSig", "bundleSig",
}

local canSave = typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfile) == "function"

do
	if canSave then
		local ok, data = pcall(function()
			if isfile(CONFIG.SaveFile) then
				return HttpService:JSONDecode(readfile(CONFIG.SaveFile))
			end
			return nil
		end)
		if ok and type(data) == "table" then
			for _, key in ipairs(SAVED_KEYS) do
				if data[key] ~= nil and type(data[key]) == type(state[key]) then
					state[key] = data[key]
				end
			end
		end
	end
	state.themeIndex = math.clamp(math.floor(state.themeIndex), 1, #CONFIG.Themes)
	if not pcall(function() return Enum.KeyCode[state.toggleKey] end) then
		state.toggleKey = "RightShift"
	end
end

local savePending = false
local function scheduleSave()
	if not canSave or savePending then return end
	savePending = true
	task.delay(0.6, function()
		savePending = false
		local data = {}
		for _, key in ipairs(SAVED_KEYS) do
			data[key] = state[key]
		end
		pcall(function()
			writefile(CONFIG.SaveFile, HttpService:JSONEncode(data))
		end)
	end)
end

THEME.Accent = CONFIG.Themes[state.themeIndex].Accent
THEME.Accent2 = CONFIG.Themes[state.themeIndex].Accent2

local connections = {}
local function connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(connections, c)
	return c
end

-----------------------------------------------------------
-- أدوات الواجهة
-----------------------------------------------------------
local UI = { AccentRefs = {}, Gradients = {} }

local function create(className, props, children)
	local inst = Instance.new(className)
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then
			inst[k] = v
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

local function accentize(inst, prop, key)
	inst[prop] = THEME[key]
	table.insert(UI.AccentRefs, { inst, prop, key })
	return inst
end

local function corner(radius)
	return create("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
end

local function stroke(color, thickness, transparency)
	return create("UIStroke", {
		Color = color or THEME.Stroke,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function accentGradient(rotation)
	local g = create("UIGradient", {
		Color = ColorSequence.new(THEME.Accent, THEME.Accent2),
		Rotation = rotation or 0,
	})
	table.insert(UI.Gradients, g)
	return g
end

local function tween(obj, time, props, style, direction)
	local t = TweenService:Create(
		obj,
		TweenInfo.new(time, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out),
		props
	)
	t:Play()
	return t
end

local function label(parent, props)
	props.BackgroundTransparency = 1
	props.Font = props.Font or FONT_BOLD
	props.TextColor3 = props.TextColor3 or THEME.Text
	props.Parent = parent
	return create("TextLabel", props)
end

local function isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
end

local function getCharacter()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return character, humanoid, root
end

-----------------------------------------------------------
-- الشاشة الرئيسية
-----------------------------------------------------------
local screenGui = create("ScreenGui", {
	Name = "MohammedTN_Brookhaven",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 50,
	Parent = playerGui,
})

local overlay = create("Frame", {
	Name = "Overlay",
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Parent = screenGui,
})

local blurEffect = create("BlurEffect", { Size = 0, Name = "MohammedTN_Blur", Parent = Lighting })

-----------------------------------------------------------
-- الإشعارات
-----------------------------------------------------------
local toastHolder = create("Frame", {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -16, 1, -16),
	Size = UDim2.new(0, 270, 1, -32),
	BackgroundTransparency = 1,
	ZIndex = 50,
	Parent = screenGui,
}, {
	create("UIListLayout", {
		Padding = UDim.new(0, 8),
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

local toastOrder = 0
local function notify(text, color, icon)
	toastOrder += 1
	local toast = create("Frame", {
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundColor3 = THEME.Surface,
		BackgroundTransparency = 0.05,
		LayoutOrder = toastOrder,
		Position = UDim2.new(1, 40, 0, 0),
		Parent = toastHolder,
	}, { corner(12), stroke(color or THEME.Accent, 1, 0.4) })

	create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.new(0, 32, 0, 32),
		BackgroundColor3 = color or THEME.Accent,
		BackgroundTransparency = 0.75,
		Parent = toast,
	}, {
		corner(16),
		create("TextLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = icon or "🔔",
			TextSize = 15,
			Font = FONT_BOLD,
		}),
	})

	label(toast, {
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(1, -62, 1, 0),
		Text = text,
		TextSize = 13,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	local progress = create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 10, 1, -4),
		Size = UDim2.new(1, -20, 0, 2),
		BackgroundColor3 = color or THEME.Accent,
		BorderSizePixel = 0,
		Parent = toast,
	}, { corner(1) })

	tween(progress, 3, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)
	task.delay(3, function()
		if toast.Parent then
			tween(toast, 0.3, { BackgroundTransparency = 1 }).Completed:Wait()
			toast:Destroy()
		end
	end)
end

-----------------------------------------------------------
-- النافذة
-----------------------------------------------------------
local W, H, SIDE = CONFIG.Width, CONFIG.Height, CONFIG.Sidebar

local mainFrame = create("Frame", {
	Name = "Main",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	Size = UDim2.new(0, W, 0, H),
	BackgroundColor3 = THEME.Background,
	BorderSizePixel = 0,
	Active = true,
	Visible = false,
	Parent = screenGui,
}, { corner(18) })

-- إطار متدرّج يلف حول النافذة
local borderStroke = stroke(Color3.new(1, 1, 1), 2)
borderStroke.Parent = mainFrame
local borderGradient = accentGradient(0)
borderGradient.Parent = borderStroke

-- خلفية زجاجية: دوائر ألوان ناعمة تتحرك ببطء
local decorBlobs = {}
do
	local decor = create("Frame", {
		Name = "Decor",
		Size = UDim2.new(1, -24, 1, -24),
		Position = UDim2.new(0, 12, 0, 12),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 0,
		Parent = mainFrame,
	})
	for i, info in ipairs({ { 0.15, 0.2, 300 }, { 0.75, 0.85, 340 }, { 0.5, 0.5, 220 } }) do
		local blob = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(info[1], 0, info[2], 0),
			Size = UDim2.new(0, info[3], 0, info[3]),
			BackgroundColor3 = Color3.new(1, 1, 1),
			ZIndex = 0,
			Parent = decor,
		}, { corner(info[3] / 2) })
		local g = accentGradient(i * 70)
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.86),
			NumberSequenceKeypoint.new(0.5, 0.92),
			NumberSequenceKeypoint.new(1, 1),
		})
		g.Parent = blob
		decorBlobs[i] = { Frame = blob, X = info[1], Y = info[2], Phase = i * 2.1 }
	end
end

local mainScale = create("UIScale", { Scale = 1, Parent = mainFrame })
local fitScale, openScale = 1, 0

local function applyScale()
	mainScale.Scale = fitScale * openScale
end

local function updateFit()
	local camera = Workspace.CurrentCamera
	if not camera then return end
	local viewport = camera.ViewportSize
	fitScale = math.min(1, (viewport.X * 0.94) / W, (viewport.Y * 0.88) / H)
	applyScale()
end

-- الشريط الجانبي (على اليمين)
local sidebar = create("Frame", {
	Name = "Sidebar",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, 0, 0, 0),
	Size = UDim2.new(0, SIDE, 1, 0),
	BackgroundColor3 = THEME.Sidebar,
	BorderSizePixel = 0,
	Parent = mainFrame,
}, { corner(18) })
-- نغطي الزوايا الداخلية
create("Frame", {
	Size = UDim2.new(0, 20, 1, 0),
	BackgroundColor3 = THEME.Sidebar,
	BorderSizePixel = 0,
	Parent = sidebar,
})
create("Frame", {
	Size = UDim2.new(0, 1, 1, -24),
	Position = UDim2.new(0, 0, 0, 12),
	BackgroundColor3 = THEME.Stroke,
	BackgroundTransparency = 0.4,
	BorderSizePixel = 0,
	Parent = sidebar,
})

-- الشعار
create("Frame", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 16),
	Size = UDim2.new(0, 38, 0, 38),
	BackgroundColor3 = Color3.new(1, 1, 1),
	Parent = sidebar,
}, {
	corner(11),
	accentGradient(45),
	create("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "🏡",
		TextSize = 20,
		Font = FONT_BOLD,
	}),
})
local logoTitle = label(sidebar, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -58, 0, 17),
	Size = UDim2.new(1, -66, 0, 20),
	Text = "Brookhaven",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Right,
})
accentGradient(0).Parent = logoTitle
label(sidebar, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -58, 0, 36),
	Size = UDim2.new(1, -66, 0, 16),
	Text = "HUB  •  " .. CONFIG.Version,
	TextColor3 = THEME.SubText,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Right,
})

local navHolder = create("ScrollingFrame", {
	Position = UDim2.new(0, 8, 0, 70),
	Size = UDim2.new(1, -16, 1, -140),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 0,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	Parent = sidebar,
}, {
	create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
})

local navIndicator = create("Frame", {
	Size = UDim2.new(1, -16, 0, 36),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 0.82,
	BorderSizePixel = 0,
	ZIndex = 0,
	Parent = sidebar,
}, { corner(10), accentGradient(0) })

-- بطاقة المستخدم
local userCard = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -10),
	Size = UDim2.new(1, -16, 0, 52),
	BackgroundColor3 = THEME.Surface,
	Parent = sidebar,
}, { corner(12), stroke(THEME.Stroke, 1, 0.5) })
local avatar = create("ImageLabel", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -8, 0.5, 0),
	Size = UDim2.new(0, 36, 0, 36),
	BackgroundColor3 = THEME.SurfaceLight,
	Image = "",
	Parent = userCard,
}, { corner(18) })
label(userCard, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -50, 0, 9),
	Size = UDim2.new(1, -56, 0, 16),
	Text = player.DisplayName,
	TextSize = 12,
	TextTruncate = Enum.TextTruncate.AtEnd,
	TextXAlignment = Enum.TextXAlignment.Right,
})
label(userCard, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -50, 0, 27),
	Size = UDim2.new(1, -56, 0, 14),
	Text = "@" .. player.Name,
	TextColor3 = THEME.SubText,
	TextSize = 10,
	Font = FONT_REG,
	TextTruncate = Enum.TextTruncate.AtEnd,
	TextXAlignment = Enum.TextXAlignment.Right,
})
task.spawn(function()
	local ok, image = pcall(function()
		return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
	end)
	if ok then
		avatar.Image = image
	end
end)

-- منطقة المحتوى
local content = create("Frame", {
	Name = "Content",
	Size = UDim2.new(1, -SIDE, 1, 0),
	BackgroundTransparency = 1,
	Parent = mainFrame,
})

local header = create("Frame", {
	Size = UDim2.new(1, 0, 0, 60),
	BackgroundTransparency = 1,
	Active = true,
	Parent = content,
})

local pageTitle = label(header, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -18, 0, 12),
	Size = UDim2.new(0.5, 0, 0, 22),
	Text = "",
	TextSize = 19,
	TextXAlignment = Enum.TextXAlignment.Right,
})
label(header, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -18, 0, 35),
	Size = UDim2.new(0.5, 0, 0, 14),
	Text = "صنع من قبل " .. CONFIG.Author,
	TextColor3 = THEME.SubText,
	TextSize = 11,
	Font = FONT_REG,
	TextXAlignment = Enum.TextXAlignment.Right,
})

local function headerButton(text, x, hover)
	local btn = create("TextButton", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, x, 0.5, 0),
		Size = UDim2.new(0, 30, 0, 30),
		BackgroundColor3 = THEME.SurfaceLight,
		AutoButtonColor = false,
		Text = text,
		TextColor3 = THEME.SubText,
		TextSize = 15,
		Font = FONT_BOLD,
		Parent = header,
	}, { corner(9) })
	btn.MouseEnter:Connect(function()
		tween(btn, 0.2, { BackgroundColor3 = hover or THEME.Accent, TextColor3 = THEME.Text })
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, 0.2, { BackgroundColor3 = THEME.SurfaceLight, TextColor3 = THEME.SubText })
	end)
	return btn
end

local closeBtn = headerButton("✕", 14, THEME.Danger)
local hideBtn = headerButton("—", 50)

local searchBox = create("TextBox", {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 88, 0.5, 0),
	Size = UDim2.new(0, 150, 0, 30),
	BackgroundColor3 = THEME.Surface,
	Text = "",
	PlaceholderText = "🔍  بحث...",
	PlaceholderColor3 = THEME.SubText,
	TextColor3 = THEME.Text,
	TextSize = 12,
	Font = FONT_REG,
	ClearTextOnFocus = false,
	TextXAlignment = Enum.TextXAlignment.Right,
	Parent = header,
}, { corner(9), stroke(THEME.Stroke, 1, 0.4), create("UIPadding", { PaddingRight = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10) }) })

local pageHolder = create("Frame", {
	Position = UDim2.new(0, 0, 0, 60),
	Size = UDim2.new(1, 0, 1, -60),
	BackgroundTransparency = 1,
	ClipsDescendants = true,
	Parent = content,
})

-----------------------------------------------------------
-- الصفحات والمكوّنات
-----------------------------------------------------------
local pages = {}
local currentPage
local activeSlider

local function selectPage(index, animated)
	state.activePage = index
	local page = pages[index]
	for i, p in ipairs(pages) do
		p.Frame.Visible = (i == index)
		tween(p.Button.Text, 0.2, { TextColor3 = (i == index) and THEME.Text or THEME.SubText })
		tween(p.Button.Icon, 0.2, { TextTransparency = (i == index) and 0 or 0.35 })
	end
	pageTitle.Text = page.Icon .. "  " .. page.Title
	-- مكان الزر في القائمة الجانبية (ارتفاع 36 + مسافة 4)
	local target = UDim2.new(0, 8, 0, 70 + (index - 1) * 40 - navHolder.CanvasPosition.Y)
	if animated then
		tween(navIndicator, 0.3, { Position = target })
	else
		navIndicator.Position = target
	end
	searchBox.Text = ""
	if animated then
		page.Frame.Position = UDim2.new(0, 0, 0, 14)
		tween(page.Frame, 0.3, { Position = UDim2.new(0, 0, 0, 0) })
	end
end

local function newPage(icon, title)
	local index = #pages + 1
	local frame = create("ScrollingFrame", {
		Name = title,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = pageHolder,
	}, {
		create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
		create("UIPadding", {
			PaddingTop = UDim.new(0, 2),
			PaddingBottom = UDim.new(0, 14),
			PaddingLeft = UDim.new(0, 14),
			PaddingRight = UDim.new(0, 14),
		}),
	})
	accentize(frame, "ScrollBarImageColor3", "Accent")

	local buttonFrame = create("TextButton", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		Text = "",
		LayoutOrder = index,
		ZIndex = 2,
		Parent = navHolder,
	})
	local iconLabel = label(buttonFrame, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.new(0, 22, 0, 22),
		Text = icon,
		TextSize = 16,
		TextTransparency = 0.35,
		ZIndex = 2,
	})
	local textLabel = label(buttonFrame, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -40, 0.5, 0),
		Size = UDim2.new(1, -46, 1, 0),
		Text = title,
		TextColor3 = THEME.SubText,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 2,
	})
	buttonFrame.MouseButton1Click:Connect(function()
		selectPage(index, true)
		scheduleSave()
	end)

	pages[index] = {
		Frame = frame,
		Title = title,
		Icon = icon,
		Order = 0,
		Button = { Frame = buttonFrame, Icon = iconLabel, Text = textLabel },
	}
	currentPage = pages[index]
	return currentPage
end

local function nextOrder()
	currentPage.Order += 1
	return currentPage.Order
end

local function card(height, searchText)
	local cardStroke = stroke(THEME.Stroke, 1, 0.5)
	local c = create("Frame", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = THEME.Surface,
		BackgroundTransparency = 0.12,
		BorderSizePixel = 0,
		LayoutOrder = nextOrder(),
		Parent = currentPage.Frame,
	}, { corner(12), cardStroke })
	c:SetAttribute("Search", searchText or "")
	-- البطاقة تضيء لما تمر عليها
	c.MouseEnter:Connect(function()
		tween(cardStroke, 0.2, { Color = THEME.Accent, Transparency = 0.2 })
	end)
	c.MouseLeave:Connect(function()
		tween(cardStroke, 0.2, { Color = THEME.Stroke, Transparency = 0.5 })
	end)
	return c
end

local function section(text)
	local s = create("Frame", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(),
		Parent = currentPage.Frame,
	})
	s:SetAttribute("Section", true)
	local bar = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 2),
		Size = UDim2.new(0, 3, 0, 14),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = s,
	}, { corner(2) })
	accentGradient(90).Parent = bar
	local text_ = label(s, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 4),
		Size = UDim2.new(1, -10, 1, -4),
		Text = text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	accentize(text_, "TextColor3", "Accent2")
	return s
end

local function titles(parent, title, desc)
	label(parent, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, desc and 9 or 0),
		Size = UDim2.new(1, -110, 0, desc and 18 or parent.Size.Y.Offset),
		Text = title,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	if desc then
		return label(parent, {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -14, 0, 28),
			Size = UDim2.new(1, -110, 0, 14),
			Text = desc,
			TextColor3 = THEME.SubText,
			TextSize = 11,
			Font = FONT_REG,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Right,
		})
	end
	return nil
end

local function makeSwitch(parent, initial, onChanged)
	local switch = create("TextButton", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 14, 0.5, 0),
		Size = UDim2.new(0, 46, 0, 24),
		BackgroundColor3 = THEME.SurfaceLight,
		AutoButtonColor = false,
		Text = "",
		Parent = parent,
	}, { corner(12) })
	local gradient = accentGradient(0)
	gradient.Parent = switch
	local knob = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.new(0, 18, 0, 18),
		BackgroundColor3 = THEME.SubText,
		Parent = switch,
	}, { corner(9) })

	local value = initial
	local api = {}
	local function render(animated)
		gradient.Enabled = value
		switch.BackgroundColor3 = value and Color3.new(1, 1, 1) or THEME.SurfaceLight
		tween(knob, animated and 0.22 or 0, {
			Position = value and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
			BackgroundColor3 = value and Color3.new(1, 1, 1) or THEME.SubText,
		})
	end
	function api.set(newValue, silent)
		if newValue == value then return end
		value = newValue
		render(true)
		if not silent then
			onChanged(value)
		end
	end
	function api.get()
		return value
	end
	switch.MouseButton1Click:Connect(function()
		api.set(not value)
	end)
	render(false)
	return api
end

-- مفتاح تشغيل مربوط بقيمة في state
local switches = {}
local toggleCallbacks = {}
local sliders = {}
local function toggle(title, desc, key, onChange)
	local c = card(54, title .. " " .. (desc or ""))
	titles(c, title, desc)
	local sw = makeSwitch(c, state[key], function(value)
		state[key] = value
		scheduleSave()
		if onChange then
			onChange(value)
		end
	end)
	switches[key] = sw
	toggleCallbacks[key] = onChange
	return sw
end

local function smallButton(parent, text, position, size, primary)
	local btn = create("TextButton", {
		Position = position,
		Size = size,
		BackgroundColor3 = primary and Color3.new(1, 1, 1) or THEME.SurfaceLight,
		AutoButtonColor = false,
		Text = text,
		TextColor3 = primary and Color3.new(1, 1, 1) or THEME.SubText,
		TextSize = 12,
		Font = FONT_BOLD,
		Parent = parent,
	}, { corner(8) })
	if primary then
		accentGradient(0).Parent = btn
	else
		btn.MouseEnter:Connect(function()
			tween(btn, 0.2, { BackgroundColor3 = THEME.Accent, TextColor3 = THEME.Text })
		end)
		btn.MouseLeave:Connect(function()
			tween(btn, 0.2, { BackgroundColor3 = THEME.SurfaceLight, TextColor3 = THEME.SubText })
		end)
	end
	return btn
end

-- بطاقة فيها زر
local function action(title, desc, buttonText, callback)
	local c = card(54, title .. " " .. (desc or ""))
	titles(c, title, desc)
	local btn = smallButton(c, buttonText, UDim2.new(0, 14, 0.5, -15), UDim2.new(0, 84, 0, 30), true)
	btn.MouseButton1Click:Connect(callback)
	return btn, c
end

-- شريط تمرير مربوط بقيمة في state
local function slider(title, key, min, max, step, format, onChange)
	local page = currentPage.Frame
	local c = card(66, title)
	titles(c, title)
	c:FindFirstChildOfClass("TextLabel").Size = UDim2.new(1, -110, 0, 36)

	local badge = create("TextLabel", {
		Position = UDim2.new(0, 14, 0, 8),
		Size = UDim2.new(0, 64, 0, 22),
		BackgroundColor3 = THEME.SurfaceLight,
		Text = "",
		TextSize = 13,
		Font = FONT_BOLD,
		Parent = c,
	}, { corner(6) })
	accentize(badge, "TextColor3", "Accent2")

	local bg = create("Frame", {
		Position = UDim2.new(0, 14, 0, 44),
		Size = UDim2.new(1, -28, 0, 8),
		BackgroundColor3 = THEME.SurfaceLight,
		Active = true,
		Parent = c,
	}, { corner(4) })
	local fill = create("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = bg,
	}, { corner(4), accentGradient(0) })
	local knobStroke = stroke(THEME.Accent, 2)
	accentize(knobStroke, "Color", "Accent")
	local knob = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(0, 16, 0, 16),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 2,
		Parent = bg,
	}, { corner(8), knobStroke })

	local api = {}
	function api.set(value, silent)
		value = math.clamp(math.floor(value / step + 0.5) * step, min, max)
		local percent = (value - min) / (max - min)
		fill.Size = UDim2.new(percent, 0, 1, 0)
		knob.Position = UDim2.new(percent, 0, 0.5, 0)
		badge.Text = string.format(format, value)
		if not silent then
			state[key] = value
			scheduleSave()
			if onChange then
				onChange(value)
			end
		end
	end
	function api.update(x)
		local percent = math.clamp((x - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
		api.set(min + percent * (max - min))
	end
	function api.release()
		page.ScrollingEnabled = true
	end
	bg.InputBegan:Connect(function(input)
		if isPress(input) then
			activeSlider = api
			page.ScrollingEnabled = false
			api.update(input.Position.X)
		end
	end)
	api.set(state[key], true)
	sliders[key] = api
	return api
end

-- بطاقة فيها خانة كتابة + زر
local function inputCard(title, placeholder, buttonText, callback)
	local c = card(84, title)
	titles(c, title)
	c:FindFirstChildOfClass("TextLabel").Size = UDim2.new(1, -28, 0, 36)
	local box = create("TextBox", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 40),
		Size = UDim2.new(1, -120, 0, 30),
		BackgroundColor3 = THEME.SurfaceLight,
		Text = "",
		PlaceholderText = placeholder,
		PlaceholderColor3 = THEME.SubText,
		TextColor3 = THEME.Text,
		TextSize = 13,
		Font = FONT_BOLD,
		ClearTextOnFocus = false,
		Parent = c,
	}, { corner(8), stroke(THEME.Stroke, 1, 0.4) })
	local btn = smallButton(c, buttonText, UDim2.new(0, 14, 0, 40), UDim2.new(0, 92, 0, 30), true)
	btn.MouseButton1Click:Connect(function()
		callback(box.Text, box)
	end)
	box.FocusLost:Connect(function(enter)
		if enter then
			callback(box.Text, box)
		end
	end)
	return box, c
end

-- البحث: يفلتر البطاقات في الصفحة الحالية
connect(searchBox:GetPropertyChangedSignal("Text"), function()
	local page = pages[state.activePage]
	if not page then return end
	local query = searchBox.Text:lower()
	for _, child in ipairs(page.Frame:GetChildren()) do
		if child:IsA("GuiObject") then
			if query == "" then
				child.Visible = true
			elseif child:GetAttribute("Section") then
				child.Visible = false
			elseif child:GetAttribute("Search") then
				child.Visible = string.find(child:GetAttribute("Search"):lower(), query, 1, true) ~= nil
			end
		end
	end
end)

-----------------------------------------------------------
-- أزرار الجوال (فوق / تحت) للطيران
-----------------------------------------------------------
local flyControls = create("Frame", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -24, 0.42, 0),
	Size = UDim2.new(0, 56, 0, 124),
	BackgroundTransparency = 1,
	Visible = false,
	Parent = screenGui,
}, {
	create("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }),
})

local verticalInput = 0
local function flyButton(text, order, value)
	local btn = create("TextButton", {
		Size = UDim2.new(0, 56, 0, 56),
		BackgroundColor3 = THEME.Surface,
		BackgroundTransparency = 0.15,
		AutoButtonColor = false,
		Text = text,
		TextColor3 = THEME.Text,
		TextSize = 22,
		Font = FONT_BOLD,
		LayoutOrder = order,
		Parent = flyControls,
	}, { corner(28), stroke(THEME.Accent, 2, 0.2) })
	btn.InputBegan:Connect(function(input)
		if isPress(input) then
			verticalInput = value
		end
	end)
	btn.InputEnded:Connect(function(input)
		if isPress(input) and verticalInput == value then
			verticalInput = 0
		end
	end)
end
flyButton("⬆", 1, 1)
flyButton("⬇", 2, -1)

-----------------------------------------------------------
-- لوحة الأداء (FPS / البنق)
-----------------------------------------------------------
local statsPanel = create("Frame", {
	Position = UDim2.new(0, 14, 0, 50),
	Size = UDim2.new(0, 150, 0, 30),
	BackgroundColor3 = THEME.Background,
	BackgroundTransparency = 0.25,
	Visible = state.showStats,
	Parent = screenGui,
}, { corner(10), stroke(THEME.Stroke, 1, 0.4) })
local statsLabel = label(statsPanel, {
	Size = UDim2.new(1, 0, 1, 0),
	Text = "",
	TextSize = 12,
	Font = Enum.Font.Code,
})

-----------------------------------------------------------
-- منطق المميزات
-----------------------------------------------------------
local F = {}

-- قيم اللاعب الأصلية
F.Defaults = { WalkSpeed = 16, JumpPower = 50, JumpHeight = 7.2 }

function F.restoreMovement()
	local _, humanoid = getCharacter()
	if not humanoid then return end
	if not state.speedOn then
		humanoid.WalkSpeed = F.Defaults.WalkSpeed
	end
	if not state.jumpOn then
		humanoid.JumpPower = F.Defaults.JumpPower
		humanoid.JumpHeight = F.Defaults.JumpHeight
	end
end

-- الطيران
F.flying = false
function F.setFly(on)
	state.fly = on
	F.flying = on
	local _, humanoid, root = getCharacter()
	if humanoid then
		humanoid.PlatformStand = on and not humanoid.SeatPart
	end
	if not on and root then
		root.AssemblyLinearVelocity = Vector3.zero
	end
	if switches.fly then
		switches.fly.set(on, true)
	end
	flyControls.Visible = (state.fly or state.carFly) and UserInputService.TouchEnabled
end

function F.flyVelocity(speed)
	local camera = Workspace.CurrentCamera
	local _, humanoid = getCharacter()
	local move = humanoid and humanoid.MoveDirection or Vector3.zero
	local look = camera.CFrame.LookVector
	local flatLook = Vector3.new(look.X, 0, look.Z)
	flatLook = flatLook.Magnitude > 0 and flatLook.Unit or Vector3.new(0, 0, -1)
	local flatRight = Vector3.new(-flatLook.Z, 0, flatLook.X)
	local forward = move:Dot(flatLook)
	local right = move:Dot(flatRight)

	local vertical = verticalInput
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsKeyDown(Enum.KeyCode.E) then
		vertical = 1
	elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.Q) then
		vertical = -1
	end

	local direction = look * forward + camera.CFrame.RightVector * right + Vector3.new(0, vertical, 0)
	if direction.Magnitude > 1 then
		direction = direction.Unit
	end
	return direction * speed, flatLook
end

-- الانتقال
function F.teleport(cframe)
	local _, humanoid, root = getCharacter()
	if not root then
		notify("ما لقيت شخصيتك", THEME.Danger, "⚠️")
		return
	end
	if humanoid and humanoid.SeatPart then
		humanoid.Sit = false
		task.wait()
	end
	root.AssemblyLinearVelocity = Vector3.zero
	root.CFrame = cframe
end

function F.teleportToPlayer(target)
	local character = target.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		notify("اللاعب ما عنده شخصية الحين", THEME.Danger, "⚠️")
		return
	end
	F.teleport(root.CFrame * CFrame.new(0, 0, 4))
	notify("انتقلت لـ " .. target.DisplayName, THEME.Success, "📍")
end

-- المراقبة
F.spectating = nil
function F.spectate(target)
	local camera = Workspace.CurrentCamera
	if not target or target == player then
		F.spectating = nil
		local _, humanoid = getCharacter()
		if humanoid then
			camera.CameraSubject = humanoid
		end
		return
	end
	local humanoid = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		F.spectating = target
		camera.CameraSubject = humanoid
		notify("تراقب " .. target.DisplayName, THEME.Accent2, "🎥")
	end
end

-- الإضاءة
F.lightingBackup = {
	Brightness = Lighting.Brightness,
	ClockTime = Lighting.ClockTime,
	FogEnd = Lighting.FogEnd,
	FogStart = Lighting.FogStart,
	GlobalShadows = Lighting.GlobalShadows,
	Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient,
}
F.atmosphereBackup = {}

function F.applyLighting()
	local backup = F.lightingBackup
	if state.fullbright then
		Lighting.Brightness = 2
		Lighting.GlobalShadows = false
		Lighting.Ambient = Color3.fromRGB(178, 178, 178)
		Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
	else
		Lighting.Brightness = backup.Brightness
		Lighting.GlobalShadows = backup.GlobalShadows
		Lighting.Ambient = backup.Ambient
		Lighting.OutdoorAmbient = backup.OutdoorAmbient
	end
	if state.noFog then
		Lighting.FogEnd = 1e6
		Lighting.FogStart = 1e6
		for _, atmosphere in ipairs(Lighting:GetChildren()) do
			if atmosphere:IsA("Atmosphere") then
				if F.atmosphereBackup[atmosphere] == nil then
					F.atmosphereBackup[atmosphere] = atmosphere.Density
				end
				atmosphere.Density = 0
			end
		end
	else
		Lighting.FogEnd = backup.FogEnd
		Lighting.FogStart = backup.FogStart
		for atmosphere, density in pairs(F.atmosphereBackup) do
			if atmosphere.Parent then
				atmosphere.Density = density
			end
		end
		table.clear(F.atmosphereBackup)
	end
end

-- ESP
F.esp = {} -- [player] = { Billboard, Name, Info, Highlight, Tracer }

function F.clearEsp(target)
	local data = F.esp[target]
	if not data then return end
	data.Billboard:Destroy()
	data.Highlight:Destroy()
	data.Tracer:Destroy()
	F.esp[target] = nil
end

function F.getEsp(target)
	local data = F.esp[target]
	if data then return data end
	local billboard = create("BillboardGui", {
		AlwaysOnTop = true,
		Size = UDim2.new(0, 160, 0, 40),
		StudsOffset = Vector3.new(0, 3.2, 0),
		Enabled = false,
		Parent = screenGui,
	})
	local nameLabel = label(billboard, {
		Size = UDim2.new(1, 0, 0, 18),
		Text = target.DisplayName,
		TextSize = 14,
		TextStrokeTransparency = 0.4,
	})
	local infoLabel = label(billboard, {
		Position = UDim2.new(0, 0, 0, 18),
		Size = UDim2.new(1, 0, 0, 16),
		Text = "",
		TextColor3 = THEME.SubText,
		TextSize = 12,
		Font = FONT_REG,
		TextStrokeTransparency = 0.5,
	})
	local highlight = create("Highlight", {
		FillTransparency = 0.75,
		OutlineTransparency = 0,
		DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
		Enabled = false,
		Parent = screenGui,
	})
	local tracer = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BorderSizePixel = 0,
		Visible = false,
		Parent = overlay,
	})
	data = { Billboard = billboard, Name = nameLabel, Info = infoLabel, Highlight = highlight, Tracer = tracer }
	F.esp[target] = data
	return data
end

-- الحماية من الرمي
F.lastSafe = nil
F.lastSafeTime = 0

-- منع الطرد بسبب الخمول
connect(player.Idled, function()
	if state.antiAfk and VirtualUser then
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
	end
end)

-- القفز اللانهائي
connect(UserInputService.JumpRequest, function()
	if state.infJump then
		local _, humanoid = getCharacter()
		if humanoid then
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end)

-- اختراق الجدران + الحماية من الرمي (قبل الفيزياء)
connect(RunService.Stepped, function()
	local character = player.Character
	if not character then return end
	if state.noclip then
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") and part.CanCollide then
				part.CanCollide = false
			end
		end
	end
	if state.antiFling then
		-- اللاعبين الثانيين ما يصطدمون فيك (عندك بس)
		for _, other in ipairs(Players:GetPlayers()) do
			if other ~= player and other.Character then
				for _, part in ipairs(other.Character:GetChildren()) do
					if part:IsA("BasePart") and part.CanCollide then
						part.CanCollide = false
					end
				end
			end
		end
	end
end)

-- الحلقة الرئيسية
F.frames, F.fpsTime, F.fps = 0, os.clock(), 60

connect(RunService.Heartbeat, function(dt)
	local now = os.clock()
	local _, humanoid, root = getCharacter()

	-- السرعة والقفز
	if humanoid then
		if state.speedOn then
			humanoid.WalkSpeed = state.walkSpeed
		end
		if state.jumpOn then
			humanoid.UseJumpPower = true
			humanoid.JumpPower = state.jumpPower
		end
		if state.antiSit and humanoid.Sit then
			humanoid.Sit = false
		end
	end

	local seat = humanoid and humanoid.SeatPart
	local vehicleRoot = seat and seat.AssemblyRootPart

	-- طيران السيارة
	if state.carFly and vehicleRoot then
		local velocity, flatLook = F.flyVelocity(state.carFlySpeed)
		vehicleRoot.AssemblyLinearVelocity = velocity
		vehicleRoot.AssemblyAngularVelocity = Vector3.zero
		vehicleRoot.CFrame = CFrame.lookAt(vehicleRoot.Position, vehicleRoot.Position + flatLook)
	elseif vehicleRoot and seat:IsA("VehicleSeat") then
		-- تسريع السيارة
		local throttle = seat.ThrottleFloat
		if state.carBoost and throttle ~= 0 then
			local look = seat.CFrame.LookVector
			local flat = Vector3.new(look.X, 0, look.Z)
			if flat.Magnitude > 0.1 then
				local current = vehicleRoot.AssemblyLinearVelocity
				local target = flat.Unit * state.carSpeed * throttle
				vehicleRoot.AssemblyLinearVelocity = Vector3.new(target.X, current.Y, target.Z)
			end
		elseif state.carBrake and throttle == 0 then
			-- فرامل قوية لما تترك البنزين
			local current = vehicleRoot.AssemblyLinearVelocity
			vehicleRoot.AssemblyLinearVelocity = Vector3.new(current.X * 0.9, current.Y, current.Z * 0.9)
		end
	end

	-- الطيران
	if F.flying and root and not vehicleRoot then
		local velocity, flatLook = F.flyVelocity(state.flySpeed)
		root.AssemblyLinearVelocity = velocity
		root.CFrame = CFrame.lookAt(root.Position, root.Position + flatLook)
		if humanoid then
			humanoid.PlatformStand = true
		end
	end

	-- الحماية من الرمي والسقوط
	if root then
		local speed = root.AssemblyLinearVelocity.Magnitude
		local spin = root.AssemblyAngularVelocity.Magnitude
		-- الحد يكبر مع السرعة والقفز اللي اخترتها عشان ما يرجعك غلط
		local limit = 220
		if state.speedOn then
			limit = math.max(limit, state.walkSpeed * 1.6)
		end
		if state.jumpOn then
			limit = math.max(limit, state.jumpPower * 1.4)
		end
		local flung = not F.flying and not vehicleRoot and (speed > limit or spin > 40)
		if state.antiFling and flung and F.lastSafe then
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
			root.CFrame = F.lastSafe
		elseif state.antiVoid and root.Position.Y < Workspace.FallenPartsDestroyHeight + 40 and F.lastSafe then
			root.AssemblyLinearVelocity = Vector3.zero
			root.CFrame = F.lastSafe
			notify("رجعتك قبل ما تطيح من الماب", THEME.Warning, "🛡️")
		elseif not flung and now - F.lastSafeTime > 0.5 and humanoid and humanoid.FloorMaterial ~= Enum.Material.Air then
			F.lastSafe = root.CFrame
			F.lastSafeTime = now
		end
	end

	-- الوقت والمجال
	if state.timeLock then
		Lighting.ClockTime = state.clockTime
	end
	if state.fovOn then
		Workspace.CurrentCamera.FieldOfView = state.fov
	end

	-- FPS
	F.frames += 1
	if now - F.fpsTime >= 0.5 then
		F.fps = F.frames / (now - F.fpsTime)
		F.frames, F.fpsTime = 0, now
		if state.showStats then
			local ok, ping = pcall(function()
				return player:GetNetworkPing()
			end)
			statsLabel.Text = string.format(
				"FPS %d  •  %d ms  •  👥 %d",
				math.floor(F.fps + 0.5),
				ok and math.floor(ping * 1000 + 0.5) or 0,
				#Players:GetPlayers()
			)
		end
	end
end)

-- ESP + التتبّع
connect(RunService.RenderStepped, function()
	local camera = Workspace.CurrentCamera
	local _, _, myRoot = getCharacter()
	local anyEsp = state.espNames or state.espHighlight or state.espTracers
	local color = THEME.Accent2

	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			local character = other.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local head = character and character:FindFirstChild("Head")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local distance = (root and myRoot) and (root.Position - myRoot.Position).Magnitude or math.huge
			local visible = anyEsp and root and distance <= state.espMaxDistance

			if visible then
				local data = F.getEsp(other)
				data.Billboard.Adornee = head or root
				data.Billboard.Enabled = state.espNames
				if state.espNames then
					local info = string.format("%d م", math.floor(distance))
					if state.espHealth and humanoid then
						info ..= string.format("  •  ❤ %d", math.floor(humanoid.Health))
					end
					data.Info.Text = info
				end
				data.Highlight.Adornee = character
				data.Highlight.Enabled = state.espHighlight or data.Pinned == true
				data.Highlight.OutlineColor = color
				data.Highlight.FillColor = THEME.Accent

				local screen = camera:WorldToViewportPoint(root.Position)
				if state.espTracers and screen.Z > 0 then
					local viewport = camera.ViewportSize
					local from = Vector2.new(viewport.X / 2, viewport.Y)
					local to = Vector2.new(screen.X, screen.Y)
					local delta = to - from
					data.Tracer.Visible = true
					data.Tracer.BackgroundColor3 = color
					data.Tracer.Size = UDim2.new(0, delta.Magnitude, 0, 1.5)
					data.Tracer.Position = UDim2.new(0, (from.X + to.X) / 2, 0, (from.Y + to.Y) / 2)
					data.Tracer.Rotation = math.deg(math.atan2(delta.Y, delta.X))
				else
					data.Tracer.Visible = false
				end
			elseif F.esp[other] then
				local data = F.esp[other]
				data.Billboard.Enabled = false
				data.Tracer.Visible = false
				-- اللاعب المميّز يدوياً يبقى ملوّن
				data.Highlight.Adornee = character
				data.Highlight.Enabled = data.Pinned == true and character ~= nil
			end
		end
	end
end)

connect(Players.PlayerRemoving, function(other)
	F.clearEsp(other)
	if F.spectating == other then
		F.spectate(nil)
	end
end)

-- إعادة تطبيق بعد الموت
connect(player.CharacterAdded, function(character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid then
		F.Defaults.WalkSpeed = humanoid.WalkSpeed
		F.Defaults.JumpPower = humanoid.JumpPower
		F.Defaults.JumpHeight = humanoid.JumpHeight
	end
	F.lastSafe = nil
	if state.fly then
		F.setFly(false)
	end
end)
do
	local _, humanoid = getCharacter()
	if humanoid then
		F.Defaults.WalkSpeed = humanoid.WalkSpeed < 100 and humanoid.WalkSpeed or 16
		F.Defaults.JumpPower = humanoid.JumpPower
		F.Defaults.JumpHeight = humanoid.JumpHeight
	end
end

-- الانتقال بالضغط
F.tapToTeleport = false
function F.teleportToScreenPoint(position)
	local camera = Workspace.CurrentCamera
	local ray = camera:ScreenPointToRay(position.X, position.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character }
	local hit = Workspace:Raycast(ray.Origin, ray.Direction * 2000, params)
	if hit then
		F.teleport(CFrame.new(hit.Position + Vector3.new(0, 3, 0)))
		return true
	end
	return false
end

-----------------------------------------------------------
-- السكنات: تستخدم ريموتات محرر الأفاتار حق Brookhaven
-- (عشان التغيير يشوفه الكل، مو بس أنت)
-----------------------------------------------------------
local S = {}

S.AccessoryFields = {
	"HatAccessory", "HairAccessory", "FaceAccessory", "NeckAccessory", "ShouldersAccessory",
	"FrontAccessory", "BackAccessory", "WaistAccessory",
}
S.SingleFields = {
	"Shirt", "Pants", "GraphicTShirt", "Face", "Head", "Torso",
	"LeftArm", "RightArm", "LeftLeg", "RightLeg",
}

function S.remote(name)
	local folder = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
	return folder and folder:FindFirstChild(name)
end

function S.description(target)
	local character = (target or player).Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil end
	local ok, desc = pcall(function()
		return humanoid:GetAppliedDescription()
	end)
	return ok and desc or nil
end

-- كل أرقام القطع اللي لابسها اللاعب
function S.assetIds(desc)
	local ids, list = {}, {}
	local function add(id)
		id = tonumber(id)
		if id and id > 0 and not ids[id] then
			ids[id] = true
			table.insert(list, id)
		end
	end
	if not desc then return ids, list end
	for _, field in ipairs(S.AccessoryFields) do
		for id in tostring(desc[field]):gmatch("%d+") do
			add(id)
		end
	end
	for _, field in ipairs(S.SingleFields) do
		add(desc[field])
	end
	pcall(function()
		for _, accessory in ipairs(desc:GetAccessories(true)) do
			add(accessory.AssetId)
		end
	end)
	return ids, list
end

function S.isWearing(id)
	local ids = S.assetIds(S.description())
	return ids[id] == true
end

-- ننتظر لين يتغير اللبس (أو نخلص الوقت)
function S.waitFor(check, timeout)
	local start = os.clock()
	while os.clock() - start < (timeout or 1.5) do
		if check() then
			return true
		end
		task.wait(0.15)
	end
	return check()
end

-- طرق محتملة لإرسال رقم القطعة (Solara ما يقدر يراقب الريموتات، فنجرّب)
S.WearSignatures = {
	function(remote, id) return remote:InvokeServer(id) end,
	function(remote, id) return remote:InvokeServer(tostring(id)) end,
	function(remote, id) return remote:InvokeServer({ id }) end,
	function(remote, id) return remote:InvokeServer(id, true) end,
}

S.busy = false

function S.wear(id, silent)
	id = tonumber(id)
	if not id then
		if not silent then notify("اكتب رقم صحيح", THEME.Danger, "⚠️") end
		return false
	end
	if S.isWearing(id) then
		return true
	end
	local remote = S.remote("Wear")
	if not remote then
		if not silent then notify("ما لقيت ريموت اللبس في هالماب", THEME.Danger, "⚠️") end
		return false
	end

	-- نجرّب الطريقة المحفوظة أول، وبعدين الباقي
	local order = {}
	if state.wearSig > 0 and S.WearSignatures[state.wearSig] then
		table.insert(order, state.wearSig)
	end
	for i = 1, #S.WearSignatures do
		if i ~= state.wearSig then
			table.insert(order, i)
		end
	end

	for _, index in ipairs(order) do
		pcall(S.WearSignatures[index], remote, id)
		if S.waitFor(function() return S.isWearing(id) end, 1.6) then
			if state.wearSig ~= index then
				state.wearSig = index
				scheduleSave()
			end
			return true
		end
	end
	if not silent then
		notify("ما قدرت ألبس " .. id .. " (ممكن القطعة مو مسموحة)", THEME.Danger, "👕")
	end
	return false
end

function S.removeAll()
	local remote = S.remote("RemoveAllAssets")
	if remote then
		pcall(function()
			remote:FireServer()
		end)
	end
end

function S.reset()
	local remote = S.remote("ResetCharacterAppearance")
	if remote then
		pcall(function()
			remote:FireServer()
		end)
	end
	local original = game:GetService("ReplicatedStorage"):FindFirstChild("RE")
	original = original and original:FindFirstChild("1Avata1rOrigina1l")
	if original then
		pcall(function()
			original:FireServer()
		end)
	end
end

-- نسبة القطع المشتركة بين شكلي وقائمة قطع
function S.matchRatio(targetList)
	if #targetList == 0 then return 0 end
	local mine = S.assetIds(S.description())
	local same = 0
	for _, id in ipairs(targetList) do
		if mine[id] then
			same += 1
		end
	end
	return same / #targetList
end

-- يلبس قائمة قطع وحدة وحدة
function S.wearList(list, label_)
	local worn = 0
	for i, id in ipairs(list) do
		if S.wear(id, true) then
			worn += 1
		end
		if label_ then
			label_.Text = string.format("⏳ %d / %d", i, #list)
		end
	end
	return worn
end

function S.copyAvatar(target, statusLabel)
	if S.busy then
		notify("انتظر، فيه عملية شغّالة", THEME.Warning, "⏳")
		return
	end
	local _, list = S.assetIds(S.description(target))
	if #list == 0 then
		notify("ما قدرت أقرأ أفاتار " .. target.DisplayName, THEME.Danger, "⚠️")
		return
	end
	S.busy = true
	notify("أنسخ أفاتار " .. target.DisplayName .. "...", THEME.Accent2, "👕")
	task.spawn(function()
		-- 1) الطريقة المباشرة: ريموت الماب اللي يحوّلك لأفاتار لاعب
		local direct = S.remote("ChangePlayerToAvatar")
		if direct then
			for _, arg in ipairs({ target.UserId, tostring(target.UserId), target.Name }) do
				pcall(function()
					direct:InvokeServer(arg)
				end)
				if S.waitFor(function() return S.matchRatio(list) >= 0.6 end, 2.5) then
					S.busy = false
					if statusLabel then statusLabel.Text = "✓ تم" end
					notify("صرت لابس أفاتار " .. target.DisplayName .. " ✓", THEME.Success, "👕")
					return
				end
			end
		end
		-- 2) الطريقة الاحتياطية: نشيل لبسنا ونلبس قطعهم وحدة وحدة
		S.removeAll()
		task.wait(0.6)
		local worn = S.wearList(list, statusLabel)
		S.busy = false
		if statusLabel then statusLabel.Text = string.format("✓ %d / %d", worn, #list) end
		notify(string.format("نسخت %d من %d قطعة من %s", worn, #list, target.DisplayName), worn > 0 and THEME.Success or THEME.Danger, "👕")
	end)
end

function S.saveOutfit(name)
	local _, list = S.assetIds(S.description())
	if #list == 0 then
		notify("ما قدرت أقرأ لبسك", THEME.Danger, "⚠️")
		return false
	end
	table.insert(state.outfits, { name = name, ids = list })
	scheduleSave()
	notify("تم حفظ الطقم: " .. name .. " (" .. #list .. " قطعة)", THEME.Success, "💾")
	return true
end

function S.wearOutfit(outfit, statusLabel)
	if S.busy then return end
	S.busy = true
	task.spawn(function()
		S.removeAll()
		task.wait(0.6)
		local ids = {}
		for _, id in ipairs(outfit.ids or {}) do
			table.insert(ids, tonumber(id))
		end
		local worn = S.wearList(ids, statusLabel)
		S.busy = false
		if statusLabel then statusLabel.Text = "" end
		notify(string.format("لبست %s (%d / %d)", tostring(outfit.name), worn, #ids), THEME.Success, "👕")
	end)
end

-- كتالوج قطع جاهزة (كل الأرقام متأكد منها من موقع Roblox)
S.Catalog = {
	{ Name = "💇 شعر", Items = {
		{ "Belle Of Belfast", 2956239660 }, { "Pal Hair", 63690008 }, { "True Blue", 451221329 },
		{ "Beanie + Hair", 1103003368 }, { "Beautiful Hair", 16630147 }, { "Straight Blonde", 376526888 },
		{ "Chestnut Bun", 62724852 },
	} },
	{ Name = "😀 وجوه", Items = {
		{ "Smile", 144075659 }, { "Chill", 7074764 }, { "Winning Smile", 616380929 },
		{ "Joyful Smile", 209995366 }, { ":3", 15432080 }, { "Shocked", 147144644 },
		{ "Laughing Fun", 226217449 }, { "Silly Fun", 7699174 }, { "Stitchface", 8329679 },
		{ "Prankster", 20052135 }, { "Err...", 20418658 }, { "YAAAWWN", 162068415 },
	} },
	{ Name = "👑 تيجان", Items = {
		{ "Dominus", 21070012 }, { "Valkyrie", 1365767 }, { "Holiday Crown", 139152472 },
		{ "Rose Crown", 4998742293 }, { "8-Bit Crown", 10159600649 }, { "Gold Star", 95907863633330 },
	} },
	{ Name = "🪽 أجنحة", Items = {
		{ "Angel Wings", 192557913 }, { "Gamer Wings", 5313324044 }, { "Black Wings", 215719598 },
		{ "Devil Wings", 4876357616 }, { "Void Wings", 6472661790 }, { "Purity Wings", 6503401221 },
	} },
	{ Name = "👕 قمصان", Items = {
		{ "Motorcycle", 144076358 }, { "Denim Jacket", 144076436 }, { "Roblox Shirt", 3670737444 },
		{ "Blue Plaid", 398635081 }, { "Teal Shirt", 382537702 }, { "I <3 Pizza", 382537085 },
	} },
	{ Name = "👖 بناطيل", Items = {
		{ "Ripped Skater", 398635338 }, { "Dark Pants", 97118097068276 }, { "Cargo Grey", 12598481285 },
		{ "Pink Skirt", 106532575969759 }, { "Argyle Denim", 8187078621 }, { "Butterfly Ripped", 7001843110 },
	} },
	{ Name = "🧢 قبعات", Items = {
		{ "Red Cap", 48474313 }, { "Roblox Cap", 607702162 }, { "'R' Cap", 417457461 },
		{ "Butterfly Hat", 4849184439 }, { "Bighead", 1048037 }, { "Aviators", 376526673 },
	} },
}

-- أطقم كاملة جاهزة
S.Presets = {
	{ name = "😎 كول", ids = { 451221329, 7074764, 144076358, 398635338, 376526673 } },
	{ name = "👑 ملكي", ids = { 139152472, 16630147, 616380929, 144076436, 398635338, 192557913 } },
	{ name = "😈 شيطان", ids = { 4876357616, 8329679, 1103003368, 398635081, 97118097068276 } },
	{ name = "😇 ملاك", ids = { 6503401221, 376526888, 209995366, 382537702, 398635338 } },
	{ name = "🎮 قيمر", ids = { 5313324044, 63690008, 20052135, 3670737444, 12598481285 } },
	{ name = "💖 كيوت", ids = { 2956239660, 226217449, 4849184439, 382537085, 106532575969759 } },
	{ name = "🖤 دارك", ids = { 6472661790, 1103003368, 147144644, 144076358, 12598481285 } },
	{ name = "⚔️ محارب", ids = { 1365767, 63690008, 7317793, 144076436, 398635338 } },
}

-- بكجات أجسام (Bundles)
S.Bundles = {
	{ "🦴 Korblox", 192 }, { "🎃 Headless", 201 }, { "🤖 Cyborg", 1 },
	{ "🦸 26th Century", 2 }, { "⚔️ Cratus", 412 }, { "🧍 ROBLOX Boy", 109 }, { "👨 Man", 238 },
}

-- ألوان البشرة
S.SkinTones = {
	Color3.fromRGB(255, 204, 153), Color3.fromRGB(234, 184, 146), Color3.fromRGB(204, 142, 105),
	Color3.fromRGB(160, 95, 53), Color3.fromRGB(105, 64, 40), Color3.fromRGB(248, 248, 248),
	Color3.fromRGB(90, 165, 70), Color3.fromRGB(13, 105, 172),
}

S.BodyFields = { "Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg" }

function S.bodySnapshot()
	local desc = S.description()
	if not desc then return "" end
	local parts = {}
	for _, field in ipairs(S.BodyFields) do
		table.insert(parts, tostring(desc[field]))
	end
	return table.concat(parts, ",")
end

-- يجرّب كم طريقة لين يتغير شي، ويحفظ الطريقة اللي اشتغلت
function S.tryAll(signatures, savedKey, call, verify, timeout)
	local order = {}
	local saved = state[savedKey]
	if saved > 0 and signatures[saved] then
		table.insert(order, saved)
	end
	for i = 1, #signatures do
		if i ~= saved then
			table.insert(order, i)
		end
	end
	for _, index in ipairs(order) do
		pcall(call, signatures[index])
		if S.waitFor(verify, timeout or 1.6) then
			if state[savedKey] ~= index then
				state[savedKey] = index
				scheduleSave()
			end
			return true
		end
	end
	return false
end

S.BundleSignatures = {
	function(remote, id) return remote:InvokeServer(id) end,
	function(remote, id) return remote:InvokeServer(tostring(id)) end,
	function(remote, id) return remote:InvokeServer({ id }) end,
}

function S.wearBundle(bundle)
	if S.busy then return end
	local remote = S.remote("WearBundle")
	if not remote then
		notify("ما لقيت ريموت البكجات", THEME.Danger, "⚠️")
		return
	end
	S.busy = true
	task.spawn(function()
		local before = S.bodySnapshot()
		local ok = S.tryAll(S.BundleSignatures, "bundleSig", function(sig)
			return sig(remote, bundle[2])
		end, function()
			return S.bodySnapshot() ~= before
		end, 2.5)
		S.busy = false
		notify(ok and ("لبست " .. bundle[1] .. " ✓") or ("ما قدرت ألبس " .. bundle[1]), ok and THEME.Success or THEME.Danger, "🦴")
	end)
end

S.ColorSignatures = {
	function(remote, color) return remote:FireServer(BrickColor.new(color)) end,
	function(remote, color) return remote:FireServer(color) end,
	function(remote, color) return remote:FireServer(BrickColor.new(color).Color) end,
	function(remote, color) return remote:FireServer("All", BrickColor.new(color)) end,
}

function S.setSkinColor(color)
	local remote = S.remote("ChangeBodyColor")
	if not remote then
		notify("ما لقيت ريموت لون البشرة", THEME.Danger, "⚠️")
		return
	end
	task.spawn(function()
		local target = BrickColor.new(color).Color
		local ok = S.tryAll(S.ColorSignatures, "colorSig", function(sig)
			return sig(remote, color)
		end, function()
			local desc = S.description()
			if not desc then return false end
			local c = desc.HeadColor
			return math.abs(c.R - target.R) + math.abs(c.G - target.G) + math.abs(c.B - target.B) < 0.12
		end)
		notify(ok and "تم تغيير لون البشرة ✓" or "ما قدرت أغيّر اللون", ok and THEME.Success or THEME.Danger, "🎨")
	end)
end

function S.randomOutfit(statusLabel)
	local function pick(categoryIndex)
		local items = S.Catalog[categoryIndex].Items
		return items[math.random(1, #items)][2]
	end
	-- شعر، وجه، قميص، بنطلون، + قطعة من التيجان أو الأجنحة أو القبعات
	local extra = ({ 3, 4, 7 })[math.random(1, 3)]
	S.wearOutfit({ name = "عشوائي", ids = { pick(1), pick(2), pick(5), pick(6), pick(extra) } }, statusLabel)
end

-----------------------------------------------------------
-- مميزات إضافية
-----------------------------------------------------------
local M = {}
M.defaultGravity = Workspace.Gravity
M.defaultZoom = player.CameraMaxZoomDistance
M.defaultCameraMode = player.CameraMode

-- نغيّر مفتاح ونحدّث زرّه وننفّذ اللي مربوط فيه
function M.setToggle(key, value)
	state[key] = value
	if switches[key] then
		switches[key].set(value, true)
	end
	local callback = toggleCallbacks[key]
	if callback then
		callback(value)
	end
	scheduleSave()
end

function M.setSlider(key, value)
	if sliders[key] then
		sliders[key].set(value)
	else
		state[key] = value
		scheduleSave()
	end
end

function M.updateVerticalControls()
	flyControls.Visible = UserInputService.TouchEnabled
		and (state.fly or state.carFly or state.hover or M.freecam == true)
end

function M.applyGravity()
	Workspace.Gravity = state.gravityOn and state.gravity or M.defaultGravity
end

function M.applyCamera()
	player.CameraMaxZoomDistance = state.maxZoom and 5000 or M.defaultZoom
	player.CameraMode = state.firstPerson and Enum.CameraMode.LockFirstPerson or M.defaultCameraMode
end

function M.applyFpsCap()
	if typeof(setfpscap) == "function" then
		pcall(setfpscap, state.fpsUnlock and state.fpsCap or 60)
	elseif state.fpsUnlock then
		notify("الـ Executor ما يدعم فك حد الـ FPS", THEME.Danger, "⚠️")
	end
end

-- المشي بالهوا + المشي السريع + القفز التلقائي
M.hoverY = nil
connect(RunService.Heartbeat, function(dt)
	local _, humanoid, root = getCharacter()
	if not humanoid or not root then return end

	if state.hover and not F.flying and not humanoid.SeatPart then
		M.hoverY = M.hoverY or root.Position.Y
		local vertical = verticalInput
		if UserInputService:IsKeyDown(Enum.KeyCode.E) then
			vertical = 1
		elseif UserInputService:IsKeyDown(Enum.KeyCode.Q) then
			vertical = -1
		end
		M.hoverY += vertical * 25 * dt
		local velocity = root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity = Vector3.new(velocity.X, 0, velocity.Z)
		root.CFrame += Vector3.new(0, M.hoverY - root.Position.Y, 0)
	else
		M.hoverY = nil
	end

	if state.tpWalk and not F.flying and humanoid.MoveDirection.Magnitude > 0 then
		root.CFrame += humanoid.MoveDirection * state.tpWalkSpeed * 10 * dt
	end

	if state.autoJump and humanoid.MoveDirection.Magnitude > 0 and humanoid.FloorMaterial ~= Enum.Material.Air then
		humanoid.Jump = true
	end

	-- الكاميرا الحرّة: الشخصية تثبت مكانها
	if M.freecam then
		humanoid.WalkSpeed = 0
		humanoid.Jump = false
	end
end)

-- الكاميرا الحرّة
M.freecam = false
M.camPos, M.yaw, M.pitch = Vector3.zero, 0, 0
M.rotating, M.rotateTouch = false, nil

function M.setFreecam(on)
	local camera = Workspace.CurrentCamera
	M.freecam = on
	local _, humanoid = getCharacter()
	if on then
		local look = camera.CFrame.LookVector
		M.camPos = camera.CFrame.Position
		M.yaw = math.atan2(-look.X, -look.Z)
		M.pitch = math.asin(math.clamp(look.Y, -1, 1))
		camera.CameraType = Enum.CameraType.Scriptable
	else
		camera.CameraType = Enum.CameraType.Custom
		if humanoid then
			camera.CameraSubject = humanoid
		end
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		F.restoreMovement()
	end
	M.updateVerticalControls()
end

function M.rotate(delta)
	M.yaw -= delta.X * 0.0045
	M.pitch = math.clamp(M.pitch - delta.Y * 0.0045, -1.45, 1.45)
end

connect(RunService.RenderStepped, function(dt)
	if not M.freecam then return end
	local camera = Workspace.CurrentCamera
	local rotation = CFrame.fromOrientation(M.pitch, M.yaw, 0)
	camera.CFrame = CFrame.new(M.camPos) * rotation
	M.camPos += F.flyVelocity(state.freecamSpeed) * dt
	camera.CFrame = CFrame.new(M.camPos) * rotation
end)

connect(UserInputService.InputBegan, function(input, gameProcessed)
	if not M.freecam then return end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		M.rotating = true
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
	elseif input.UserInputType == Enum.UserInputType.Touch and not gameProcessed then
		M.rotateTouch = input
	end
end)
connect(UserInputService.InputChanged, function(input)
	if not M.freecam then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement and M.rotating then
		M.rotate(input.Delta)
	elseif input == M.rotateTouch then
		M.rotate(input.Delta)
	end
end)
connect(UserInputService.InputEnded, function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		M.rotating = false
		if M.freecam then
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end
	elseif input == M.rotateTouch then
		M.rotateTouch = nil
	end
end)

-- معزّز الـ FPS (جرافيكس خفيف)
M.graphicsBackup = {}
M.graphicsBusy = false
M.EffectClasses = { ParticleEmitter = true, Trail = true, Smoke = true, Fire = true, Sparkles = true, Beam = true }

function M.applyLowGraphics()
	if M.graphicsBusy then return end
	M.graphicsBusy = true
	task.spawn(function()
		local count = 0
		if state.lowGraphics then
			pcall(function()
				settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
			end)
			Lighting.GlobalShadows = false
			for _, obj in ipairs(Workspace:GetDescendants()) do
				if not state.lowGraphics then break end
				if obj:IsA("BasePart") then
					if obj.Material ~= Enum.Material.SmoothPlastic or obj.Reflectance > 0 then
						M.graphicsBackup[obj] = { obj.Material, obj.Reflectance }
						obj.Material = Enum.Material.SmoothPlastic
						obj.Reflectance = 0
					end
				elseif (obj:IsA("Decal") or obj:IsA("Texture")) and obj.Name ~= "face" then
					M.graphicsBackup[obj] = obj.Transparency
					obj.Transparency = 1
				elseif M.EffectClasses[obj.ClassName] then
					M.graphicsBackup[obj] = obj.Enabled
					obj.Enabled = false
				end
				count += 1
				if count % 3000 == 0 then
					task.wait()
				end
			end
			notify("معزّز الـ FPS شغّال ⚡", THEME.Success, "⚡")
		else
			for obj, backup in pairs(M.graphicsBackup) do
				if obj.Parent then
					if obj:IsA("BasePart") then
						obj.Material = backup[1]
						obj.Reflectance = backup[2]
					elseif obj:IsA("Decal") or obj:IsA("Texture") then
						obj.Transparency = backup
					else
						obj.Enabled = backup
					end
				end
				count += 1
				if count % 3000 == 0 then
					task.wait()
				end
			end
			table.clear(M.graphicsBackup)
			pcall(function()
				settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
			end)
			if not state.fullbright then
				Lighting.GlobalShadows = F.lightingBackup.GlobalShadows
			end
		end
		M.graphicsBusy = false
	end)
end

-- الرؤية من خلال الجدران (عندك بس)
function M.applyXray()
	task.spawn(function()
		local value = state.xray and 0.65 or 0
		local count = 0
		for _, part in ipairs(Workspace:GetDescendants()) do
			if part:IsA("BasePart") and not (part.Parent and part.Parent:FindFirstChildOfClass("Humanoid")) then
				part.LocalTransparencyModifier = value
			end
			count += 1
			if count % 4000 == 0 then
				task.wait()
			end
		end
	end)
end

-- الحذف بالضغط (عندك بس)
M.deleteMode = false
M.deleted = {}
function M.deleteAt(position)
	local camera = Workspace.CurrentCamera
	local ray = camera:ScreenPointToRay(position.X, position.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character }
	local hit = Workspace:Raycast(ray.Origin, ray.Direction * 2000, params)
	if hit and hit.Instance and not hit.Instance:IsA("Terrain") then
		local part = hit.Instance
		if part.Parent and part.Parent:FindFirstChildOfClass("Humanoid") then return end
		table.insert(M.deleted, { part, part.Parent })
		part.Parent = nil
	end
end
function M.restoreDeleted()
	for _, entry in ipairs(M.deleted) do
		pcall(function()
			entry[1].Parent = entry[2]
		end)
	end
	table.clear(M.deleted)
end

-- ذيل ملوّن (عندك بس)
M.trailParts = {}
function M.applyTrail()
	for _, obj in ipairs(M.trailParts) do
		obj:Destroy()
	end
	table.clear(M.trailParts)
	local _, _, root = getCharacter()
	if not (state.trail and root) then return end
	local a0 = create("Attachment", { Position = Vector3.new(0, 1, 0), Parent = root })
	local a1 = create("Attachment", { Position = Vector3.new(0, -1, 0), Parent = root })
	local trail = create("Trail", {
		Attachment0 = a0,
		Attachment1 = a1,
		Lifetime = 0.7,
		LightEmission = 1,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)),
			ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 200, 40)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 220, 120)),
			ColorSequenceKeypoint.new(0.75, Color3.fromRGB(40, 160, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 80, 255)),
		}),
		Transparency = NumberSequence.new(0.1, 1),
		Parent = root,
	})
	M.trailParts = { a0, a1, trail }
end
connect(player.CharacterAdded, function()
	task.wait(1)
	M.applyTrail()
end)

-- مشغّل الموسيقى (عندك بس)
M.music = create("Sound", { Looped = true, Volume = state.musicVolume, Parent = screenGui })
function M.playMusic(id)
	id = tostring(id):gsub("%D", "")
	if id == "" then
		notify("اكتب رقم الأغنية", THEME.Danger, "⚠️")
		return
	end
	state.musicId = id
	scheduleSave()
	M.music.SoundId = "rbxassetid://" .. id
	M.music.Volume = state.musicVolume
	M.music:Play()
	notify("تشغيل الأغنية " .. id .. " 🎵", THEME.Success, "🎵")
end
function M.stopMusic()
	M.music:Stop()
end

-- وضع التصوير: يخفي كل الواجهات
M.screenshot = false
M.hiddenGuis = {}
M.screenshotButton = create("TextButton", {
	Position = UDim2.new(0, 10, 0, 10),
	Size = UDim2.new(0, 36, 0, 36),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.7,
	Text = "👁",
	TextSize = 18,
	Font = FONT_BOLD,
	Visible = false,
	Parent = create("ScreenGui", {
		Name = "MohammedTN_Screenshot",
		ResetOnSpawn = false,
		DisplayOrder = 999,
		Parent = playerGui,
	}),
}, { corner(18) })

function M.setScreenshot(on)
	M.screenshot = on
	local starterGui = game:GetService("StarterGui")
	if on then
		for _, gui in ipairs(playerGui:GetChildren()) do
			if gui:IsA("ScreenGui") and gui.Enabled and gui ~= M.screenshotButton.Parent then
				gui.Enabled = false
				table.insert(M.hiddenGuis, gui)
			end
		end
		pcall(function()
			starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
		end)
		M.screenshotButton.Visible = true
	else
		for _, gui in ipairs(M.hiddenGuis) do
			if gui.Parent then
				gui.Enabled = true
			end
		end
		table.clear(M.hiddenGuis)
		pcall(function()
			starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
		end)
		M.screenshotButton.Visible = false
	end
end
M.screenshotButton.MouseButton1Click:Connect(function()
	M.setScreenshot(false)
end)

-- السيرفرات
function M.serverHop(lowest)
	notify(lowest and "أدوّر على أقل سيرفر..." or "أدوّر على سيرفر ثاني...", THEME.Accent2, "🌐")
	task.spawn(function()
		local ok, body = pcall(function()
			return game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
		end)
		local decoded, data = false, nil
		if ok then
			decoded, data = pcall(function()
				return HttpService:JSONDecode(body)
			end)
		end
		if not decoded or type(data) ~= "table" or type(data.data) ~= "table" then
			notify("ما قدرت أجيب قائمة السيرفرات", THEME.Danger, "⚠️")
			return
		end
		local candidates = {}
		for _, server in ipairs(data.data) do
			if server.id ~= game.JobId and type(server.playing) == "number"
				and type(server.maxPlayers) == "number" and server.playing < server.maxPlayers
			then
				table.insert(candidates, server)
			end
		end
		if #candidates == 0 then
			notify("ما لقيت سيرفر فاضي", THEME.Danger, "⚠️")
			return
		end
		local target
		if lowest then
			table.sort(candidates, function(a, b)
				return a.playing < b.playing
			end)
			target = candidates[1]
		else
			target = candidates[math.random(1, #candidates)]
		end
		notify("أنتقل لسيرفر فيه " .. target.playing .. " لاعب", THEME.Success, "🌐")
		pcall(function()
			TeleportService:TeleportToPlaceInstance(game.PlaceId, target.id, player)
		end)
	end)
end

function M.rejoin()
	notify("جاري إعادة الدخول...", THEME.Accent2, "🔄")
	pcall(function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
	end)
end

function M.copy(text, what)
	if typeof(setclipboard) == "function" then
		pcall(setclipboard, text)
		notify("تم نسخ " .. what, THEME.Success, "📋")
	else
		notify(text, THEME.Accent2, "📋")
	end
end

function M.formatTime(seconds)
	seconds = math.floor(seconds)
	return string.format("%02d:%02d:%02d", seconds // 3600, (seconds % 3600) // 60, seconds % 60)
end

-- لوحة الأوامر
function M.findPlayer(query)
	query = (query or ""):lower()
	if query == "" then return nil end
	if query == "me" or query == "انا" then return player end
	for _, other in ipairs(Players:GetPlayers()) do
		if other.Name:lower():sub(1, #query) == query or other.DisplayName:lower():sub(1, #query) == query then
			return other
		end
	end
	for _, other in ipairs(Players:GetPlayers()) do
		if other.Name:lower():find(query, 1, true) or other.DisplayName:lower():find(query, 1, true) then
			return other
		end
	end
	return nil
end

local function withPlayer(fn)
	return function(arg)
		local target = M.findPlayer(arg)
		if target then
			fn(target)
		else
			notify("ما لقيت لاعب: " .. tostring(arg), THEME.Danger, "⚠️")
		end
	end
end

local function withNumber(fn)
	return function(arg)
		local n = tonumber(arg)
		if n then
			fn(n)
		else
			notify("اكتب رقم بعد الأمر", THEME.Danger, "⚠️")
		end
	end
end

M.Commands = {
	{ { "fly", "طيران" }, "طيران", function() F.setFly(not state.fly) end },
	{ { "noclip", "جدران" }, "اختراق الجدران", function() M.setToggle("noclip", not state.noclip) end },
	{ { "speed", "سرعة" }, "سرعة [رقم]", withNumber(function(n)
		M.setSlider("walkSpeed", n)
		M.setToggle("speedOn", true)
	end) },
	{ { "jump", "قفز" }, "قفز [رقم]", withNumber(function(n)
		M.setSlider("jumpPower", n)
		M.setToggle("jumpOn", true)
	end) },
	{ { "grav", "جاذبية" }, "جاذبية [رقم]", withNumber(function(n)
		M.setSlider("gravity", n)
		M.setToggle("gravityOn", true)
	end) },
	{ { "hover", "هوا" }, "مشي بالهوا", function() M.setToggle("hover", not state.hover) end },
	{ { "tp", "روح" }, "روح [اسم]", withPlayer(F.teleportToPlayer) },
	{ { "spec", "راقب" }, "راقب [اسم]", withPlayer(F.spectate) },
	{ { "unspec", "وقف" }, "وقف المراقبة", function() F.spectate(nil) end },
	{ { "copy", "انسخ" }, "انسخ [اسم] (أفاتار)", withPlayer(S.copyAvatar) },
	{ { "wear", "لبس" }, "لبس [رقم قطعة]", withNumber(function(n)
		task.spawn(S.wear, n)
	end) },
	{ { "freecam", "كاميرا" }, "كاميرا حرّة", function() M.setFreecam(not M.freecam) end },
	{ { "fps", "خفيف" }, "معزّز الـ FPS", function() M.setToggle("lowGraphics", not state.lowGraphics) end },
	{ { "xray", "اكس" }, "رؤية من خلال الجدران", function() M.setToggle("xray", not state.xray) end },
	{ { "light", "اضاءة" }, "إضاءة كاملة", function() M.setToggle("fullbright", not state.fullbright) end },
	{ { "music", "اغنية" }, "اغنية [رقم]", function(arg) M.playMusic(arg or "") end },
	{ { "stop", "اسكت" }, "إيقاف الأغنية", function() M.stopMusic() end },
	{ { "hop", "سيرفر" }, "سيرفر ثاني", function() M.serverHop(false) end },
	{ { "rejoin", "اعادة" }, "إعادة دخول", function() M.rejoin() end },
	{ { "reset", "موت" }, "ريسبون", function()
		local _, humanoid = getCharacter()
		if humanoid then humanoid.Health = 0 end
	end },
}

function M.runCommand(text)
	text = text:gsub("^%s+", ""):gsub("%s+$", ""):gsub("^[;:/!]", "")
	if text == "" then return end
	local name, arg = text:match("^(%S+)%s*(.*)$")
	name = name:lower()
	for _, command in ipairs(M.Commands) do
		for _, alias in ipairs(command[1]) do
			if alias == name then
				command[3](arg ~= "" and arg or nil)
				return
			end
		end
	end
	notify("أمر غير معروف: " .. name, THEME.Danger, "⌨️")
end

-----------------------------------------------------------
-- صفحة 1: الرئيسية
-----------------------------------------------------------
newPage("🏠", "الرئيسية")

do
	local hero = card(118, "")
	hero:SetAttribute("Search", nil)
	local heroGradient = create("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.82,
		Parent = hero,
	}, { corner(12), accentGradient(20) })
	heroGradient.ZIndex = 0
	local welcome = label(hero, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -18, 0, 18),
		Size = UDim2.new(1, -36, 0, 26),
		Text = "أهلاً " .. player.DisplayName .. " 👋",
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	welcome.TextTruncate = Enum.TextTruncate.AtEnd
	label(hero, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -18, 0, 50),
		Size = UDim2.new(1, -36, 0, 34),
		Text = "أقوى سكربت لـ Brookhaven بالعربي • حركة، طيران، سيارات، تنقّل، مراقبة، حماية والمزيد",
		TextColor3 = THEME.SubText,
		TextSize = 12,
		Font = FONT_REG,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
	local credit = label(hero, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -18, 0, 88),
		Size = UDim2.new(1, -36, 0, 18),
		Text = "✦ صنع من قبل " .. CONFIG.Author .. " ✦",
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	accentGradient(0).Parent = credit
end

section("⚡ اختصارات سريعة")
do
	local quick = card(96, "")
	quick:SetAttribute("Search", nil)
	local grid = create("Frame", {
		Position = UDim2.new(0, 10, 0, 10),
		Size = UDim2.new(1, -20, 1, -20),
		BackgroundTransparency = 1,
		Parent = quick,
	}, {
		create("UIGridLayout", {
			CellSize = UDim2.new(1 / 3, -6, 0.5, -4),
			CellPadding = UDim2.new(0, 8, 0, 8),
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	local quickItems = {
		{ "✈️ طيران", function() F.setFly(not state.fly) end },
		{ "👻 جدران", function()
			state.noclip = not state.noclip
			if switches.noclip then switches.noclip.set(state.noclip, true) end
			notify(state.noclip and "اختراق الجدران شغّال" or "اختراق الجدران طافي", THEME.Accent2, "👻")
		end },
		{ "⚡ سرعة", function()
			state.speedOn = not state.speedOn
			if switches.speedOn then switches.speedOn.set(state.speedOn, true) end
			F.restoreMovement()
		end },
		{ "☀️ إضاءة", function()
			state.fullbright = not state.fullbright
			if switches.fullbright then switches.fullbright.set(state.fullbright, true) end
			F.applyLighting()
		end },
		{ "🔁 ريسبون", function()
			local _, humanoid = getCharacter()
			if humanoid then humanoid.Health = 0 end
		end },
		{ "🔄 إعادة دخول", function()
			notify("جاري إعادة الدخول...", THEME.Accent2, "🔄")
			pcall(function()
				TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
			end)
		end },
	}
	for i, item in ipairs(quickItems) do
		local btn = smallButton(grid, item[1], UDim2.new(), UDim2.new(), false)
		btn.LayoutOrder = i
		btn.TextSize = 12
		btn.MouseButton1Click:Connect(item[2])
	end
end

section("📊 لوحة مباشرة")
do
	local board = card(84, "")
	board:SetAttribute("Search", nil)
	local grid = create("Frame", {
		Position = UDim2.new(0, 10, 0, 10),
		Size = UDim2.new(1, -20, 1, -20),
		BackgroundTransparency = 1,
		Parent = board,
	}, {
		create("UIGridLayout", {
			CellSize = UDim2.new(0.25, -6, 1, 0),
			CellPadding = UDim2.new(0, 8, 0, 0),
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	local tiles = {}
	for i, info in ipairs({ { "⚡", "FPS" }, { "📶", "البنق" }, { "👥", "اللاعبين" }, { "⏱", "السيرفر" } }) do
		local tile = create("Frame", {
			BackgroundColor3 = THEME.SurfaceLight,
			BackgroundTransparency = 0.3,
			LayoutOrder = i,
			Parent = grid,
		}, { corner(10) })
		local value = label(tile, {
			Position = UDim2.new(0, 0, 0, 8),
			Size = UDim2.new(1, 0, 0, 26),
			Text = "—",
			TextSize = 18,
		})
		accentize(value, "TextColor3", "Accent2")
		label(tile, {
			Position = UDim2.new(0, 0, 1, -26),
			Size = UDim2.new(1, 0, 0, 18),
			Text = info[1] .. " " .. info[2],
			TextColor3 = THEME.SubText,
			TextSize = 11,
			Font = FONT_REG,
		})
		tiles[i] = value
	end
	task.spawn(function()
		while screenGui.Parent do
			tiles[1].Text = tostring(math.floor(F.fps + 0.5))
			local ok, ping = pcall(function()
				return player:GetNetworkPing()
			end)
			tiles[2].Text = ok and tostring(math.floor(ping * 1000 + 0.5)) or "—"
			tiles[3].Text = #Players:GetPlayers() .. "/" .. Players.MaxPlayers
			tiles[4].Text = M.formatTime(Workspace.DistributedGameTime)
			task.wait(1)
		end
	end)
end

section("⌨️ الاختصارات")
do
	local keys = card(78, "")
	keys:SetAttribute("Search", nil)
	label(keys, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 10),
		Size = UDim2.new(1, -28, 0, 60),
		Text = string.format(
			"الواجهة: %s   •   طيران: %s   •   جدران: %s\nوضع التصوير: %s   •   انتقال بالضغط: Ctrl + كليك\nالأوامر: من صفحة ⌨️ الأوامر",
			state.toggleKey, state.flyKey, state.noclipKey, state.screenshotKey
		),
		TextColor3 = THEME.SubText,
		TextSize = 12,
		Font = FONT_REG,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
end

-----------------------------------------------------------
-- صفحة 2: الحركة
-----------------------------------------------------------
newPage("🏃", "الحركة")

section("🏃 المشي والقفز")
toggle("سرعة المشي", "تغيير سرعة شخصيتك", "speedOn", function()
	F.restoreMovement()
end)
slider("السرعة", "walkSpeed", 16, 300, 1, "%d")
toggle("قوة القفز", "قفز أعلى بكثير", "jumpOn", function()
	F.restoreMovement()
end)
slider("قوة القفز", "jumpPower", 50, 400, 5, "%d")
toggle("قفز لا نهائي", "تقفز وأنت بالهوا", "infJump")

section("✈️ الطيران")
toggle("الطيران", "طيران باتجاه الكاميرا (F) — أزرار ⬆⬇ للجوال", "fly", function(value)
	F.setFly(value)
end)
slider("سرعة الطيران", "flySpeed", 10, 400, 5, "%d")

section("👻 الجدران")
toggle("اختراق الجدران", "تمشي من خلال أي شي (N)", "noclip")

section("🪂 حركة متقدمة")
toggle("مشي بالهوا", "تمشي بالهوا بنفس الارتفاع • E/Q أو ⬆⬇ للطلوع والنزول", "hover", function()
	M.updateVerticalControls()
end)
toggle("مشي سريع (TP Walk)", "سرعة إضافية بطريقة الانتقال", "tpWalk")
slider("قوة المشي السريع", "tpWalkSpeed", 1, 15, 0.5, "%.1f")
toggle("قفز تلقائي", "يقفز لحاله وأنت تمشي", "autoJump")
toggle("الجاذبية", "جاذبية أقل = قفز أعلى وطيحة أبطأ", "gravityOn", function()
	M.applyGravity()
end)
slider("قوة الجاذبية", "gravity", 5, 400, 5, "%d", function()
	M.applyGravity()
end)

-----------------------------------------------------------
-- صفحة 3: السيارات
-----------------------------------------------------------
newPage("🚗", "السيارات")

section("🚗 سيارتك")
toggle("تسريع السيارة", "سرعة أعلى لسيارتك (VehicleSeat)", "carBoost")
slider("سرعة السيارة", "carSpeed", 40, 600, 10, "%d")
toggle("فرامل قوية", "توقف بسرعة لما تترك البنزين", "carBrake")

section("🛸 السيارة الطائرة")
toggle("سيارة تطير", "اركب أي سيارة وطير فيها باتجاه الكاميرا", "carFly", function()
	flyControls.Visible = (state.fly or state.carFly) and UserInputService.TouchEnabled
end)
slider("سرعة الطيران بالسيارة", "carFlySpeed", 20, 500, 10, "%d")

action("انزل من السيارة", "تنزل فوراً من أي مقعد", "انزل", function()
	local _, humanoid = getCharacter()
	if humanoid then
		humanoid.Sit = false
	end
end)

-----------------------------------------------------------
-- صفحة 4: التنقّل
-----------------------------------------------------------
newPage("📍", "التنقّل")

section("🖱️ انتقال بالضغط")
toggle("انتقال بالضغط", "كمبيوتر: Ctrl + كليك • جوال: شغّله واضغط على الشاشة", "clickTp", function(value)
	F.tapToTeleport = value
end)

section("📌 أماكنك المحفوظة")
local waypointList = create("Frame", {
	Size = UDim2.new(1, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	LayoutOrder = 0,
}, {
	create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
})

local function refreshWaypoints()
	for _, child in ipairs(waypointList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for i, wp in ipairs(state.waypoints) do
		local row = create("Frame", {
			Size = UDim2.new(1, 0, 0, 44),
			BackgroundColor3 = THEME.Surface,
			LayoutOrder = i,
			Parent = waypointList,
		}, { corner(10), stroke(THEME.Stroke, 1, 0.5) })
		label(row, {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -14, 0.5, 0),
			Size = UDim2.new(1, -170, 1, 0),
			Text = "📌 " .. tostring(wp.name),
			TextSize = 13,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Right,
		})
		local go = smallButton(row, "انتقال", UDim2.new(0, 10, 0.5, -13), UDim2.new(0, 70, 0, 26), true)
		go.MouseButton1Click:Connect(function()
			F.teleport(CFrame.new(wp.x, wp.y, wp.z))
			notify("انتقلت لـ " .. tostring(wp.name), THEME.Success, "📍")
		end)
		local del = smallButton(row, "🗑", UDim2.new(0, 86, 0.5, -13), UDim2.new(0, 34, 0, 26), false)
		del.MouseButton1Click:Connect(function()
			table.remove(state.waypoints, i)
			scheduleSave()
			refreshWaypoints()
		end)
	end
end

inputCard("حفظ مكانك الحالي", "اسم المكان (مثلاً: بيتي)", "حفظ", function(text, box)
	local _, _, root = getCharacter()
	if not root then return end
	local name = text:gsub("^%s+", ""):gsub("%s+$", "")
	if name == "" then
		name = "مكان " .. (#state.waypoints + 1)
	end
	local p = root.Position
	table.insert(state.waypoints, { name = name, x = p.X, y = p.Y, z = p.Z })
	scheduleSave()
	refreshWaypoints()
	box.Text = ""
	notify("تم حفظ: " .. name, THEME.Success, "📌")
end)
waypointList.LayoutOrder = nextOrder()
waypointList.Parent = currentPage.Frame
refreshWaypoints()

-----------------------------------------------------------
-- صفحة 5: اللاعبين
-----------------------------------------------------------
newPage("👥", "اللاعبين")

section("🎥 المراقبة")
local spectateCard = card(54, "مراقبة")
local spectateStatus = titles(spectateCard, "المراقبة", "ما تراقب أحد")
do
	local stop = smallButton(spectateCard, "إيقاف", UDim2.new(0, 14, 0.5, -15), UDim2.new(0, 70, 0, 30), true)
	stop.MouseButton1Click:Connect(function()
		F.spectate(nil)
	end)
end

section("👥 قائمة اللاعبين")
local playerList = create("Frame", {
	Size = UDim2.new(1, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	LayoutOrder = nextOrder(),
	Parent = currentPage.Frame,
}, {
	create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
})

local playerRows = {}

local function addPlayerRow(other)
	if other == player or playerRows[other] then return end
	local row = create("Frame", {
		Size = UDim2.new(1, 0, 0, 52),
		BackgroundColor3 = THEME.Surface,
		Parent = playerList,
	}, { corner(10), stroke(THEME.Stroke, 1, 0.5) })
	row:SetAttribute("Search", other.DisplayName .. " " .. other.Name)
	local thumb = create("ImageLabel", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.new(0, 36, 0, 36),
		BackgroundColor3 = THEME.SurfaceLight,
		Parent = row,
	}, { corner(18) })
	task.spawn(function()
		local ok, image = pcall(function()
			return Players:GetUserThumbnailAsync(other.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
		end)
		if ok and thumb.Parent then
			thumb.Image = image
		end
	end)
	label(row, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -54, 0, 8),
		Size = UDim2.new(1, -250, 0, 18),
		Text = other.DisplayName,
		TextSize = 13,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	local info = label(row, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -54, 0, 27),
		Size = UDim2.new(1, -250, 0, 16),
		Text = "@" .. other.Name,
		TextColor3 = THEME.SubText,
		TextSize = 11,
		Font = FONT_REG,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	local tp = smallButton(row, "📍", UDim2.new(0, 10, 0.5, -15), UDim2.new(0, 40, 0, 30), true)
	tp.TextSize = 15
	tp.MouseButton1Click:Connect(function()
		F.teleportToPlayer(other)
	end)
	local watch = smallButton(row, "🎥", UDim2.new(0, 56, 0.5, -15), UDim2.new(0, 40, 0, 30), false)
	watch.TextSize = 15
	watch.MouseButton1Click:Connect(function()
		if F.spectating == other then
			F.spectate(nil)
		else
			F.spectate(other)
		end
	end)
	local copy = smallButton(row, "👕", UDim2.new(0, 148, 0.5, -15), UDim2.new(0, 40, 0, 30), false)
	copy.TextSize = 15
	copy.MouseButton1Click:Connect(function()
		S.copyAvatar(other)
	end)
	local view = smallButton(row, "👁", UDim2.new(0, 102, 0.5, -15), UDim2.new(0, 40, 0, 30), false)
	view.TextSize = 15
	view.MouseButton1Click:Connect(function()
		-- تمييز لاعب واحد بلون
		local data = F.getEsp(other)
		data.Pinned = not data.Pinned
		notify(data.Pinned and ("تم تمييز " .. other.DisplayName) or "تم إلغاء التمييز", THEME.Accent2, "👁")
	end)
	playerRows[other] = { Row = row, Info = info }
end

for _, other in ipairs(Players:GetPlayers()) do
	addPlayerRow(other)
end
connect(Players.PlayerAdded, addPlayerRow)
connect(Players.PlayerRemoving, function(other)
	local data = playerRows[other]
	if data then
		data.Row:Destroy()
		playerRows[other] = nil
	end
end)

-- تحديث المسافات وحالة المراقبة
task.spawn(function()
	while screenGui.Parent do
		local _, _, myRoot = getCharacter()
		for other, data in pairs(playerRows) do
			local root = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
			if root and myRoot then
				data.Info.Text = string.format("@%s  •  %d م", other.Name, math.floor((root.Position - myRoot.Position).Magnitude))
			else
				data.Info.Text = "@" .. other.Name
			end
		end
		spectateStatus.Text = F.spectating and ("تراقب: " .. F.spectating.DisplayName) or "ما تراقب أحد"
		task.wait(1)
	end
end)

-----------------------------------------------------------
-- صفحة: السكنات
-----------------------------------------------------------
newPage("👕", "السكنات")

do
	local info = card(70, "")
	info:SetAttribute("Search", nil)
	label(info, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 10),
		Size = UDim2.new(1, -28, 0, 50),
		Text = "👕 يستخدم محرر الأفاتار حق Brookhaven، فالكل يشوف لبسك.\nأول مرة يجرّب كم طريقة لين يلقى اللي تشتغل ويحفظها.",
		TextColor3 = THEME.SubText,
		TextSize = 12,
		Font = FONT_REG,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
end

-- شبكة أزرار (للأطقم والبكجات والكتالوج)
local function buttonGrid(columns, rowHeight, count, searchText)
	local rows = math.ceil(count / columns)
	local c = card(rows * (rowHeight + 8) + 12, searchText)
	local grid = create("Frame", {
		Position = UDim2.new(0, 10, 0, 10),
		Size = UDim2.new(1, -20, 1, -20),
		BackgroundTransparency = 1,
		Parent = c,
	}, {
		create("UIGridLayout", {
			CellSize = UDim2.new(1 / columns, -6, 0, rowHeight),
			CellPadding = UDim2.new(0, 8, 0, 8),
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	return grid, c
end

section("✨ أطقم جاهزة")
do
	local status = nil
	local grid = buttonGrid(4, 38, #S.Presets, "أطقم جاهزة كول ملكي شيطان ملاك قيمر كيوت دارك محارب")
	for i, preset in ipairs(S.Presets) do
		local btn = smallButton(grid, preset.name, UDim2.new(), UDim2.new(), i == 1)
		btn.LayoutOrder = i
		btn.TextSize = 13
		btn.MouseButton1Click:Connect(function()
			notify("ألبس طقم " .. preset.name .. "...", THEME.Accent2, "✨")
			S.wearOutfit(preset, status)
		end)
	end
	action("🎲 طقم عشوائي", "شعر ووجه وقميص وبنطلون وإكسسوار عشوائي", "عشوائي", function()
		notify("ألبس طقم عشوائي...", THEME.Accent2, "🎲")
		S.randomOutfit()
	end)
end

section("🦴 بكجات الأجسام")
do
	local grid = buttonGrid(4, 38, #S.Bundles, "بكجات korblox headless كوربلوكس هيدلس")
	for i, bundle in ipairs(S.Bundles) do
		local btn = smallButton(grid, bundle[1], UDim2.new(), UDim2.new(), i <= 2)
		btn.LayoutOrder = i
		btn.MouseButton1Click:Connect(function()
			notify("ألبس " .. bundle[1] .. "...", THEME.Accent2, "🦴")
			S.wearBundle(bundle)
		end)
	end
end

section("🛍️ متصفح القطع")
do
	local browser = card(46, "متصفح القطع شعر وجوه تيجان أجنحة قمصان بناطيل قبعات")
	local chips = create("ScrollingFrame", {
		Position = UDim2.new(0, 8, 0, 6),
		Size = UDim2.new(1, -16, 0, 34),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.X,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		CanvasSize = UDim2.new(),
		Parent = browser,
	}, {
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local maxItems = 0
	for _, category in ipairs(S.Catalog) do
		maxItems = math.max(maxItems, #category.Items)
	end
	local grid, gridCard = buttonGrid(3, 34, maxItems, "")
	gridCard:SetAttribute("Search", nil)

	local chipButtons = {}
	local function showCategory(index)
		for _, child in ipairs(grid:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		local category = S.Catalog[index]
		for i, item in ipairs(category.Items) do
			local btn = smallButton(grid, item[1], UDim2.new(), UDim2.new(), false)
			btn.LayoutOrder = i
			btn.MouseButton1Click:Connect(function()
				task.spawn(function()
					if S.wear(item[2]) then
						notify("لبست " .. item[1] .. " ✓", THEME.Success, "🛍️")
					end
				end)
			end)
		end
		local rows = math.ceil(#category.Items / 3)
		gridCard.Size = UDim2.new(1, 0, 0, rows * 42 + 12)
		for i, chip in ipairs(chipButtons) do
			chip.BackgroundColor3 = (i == index) and THEME.Accent or THEME.SurfaceLight
			chip.TextColor3 = (i == index) and THEME.Text or THEME.SubText
		end
	end

	for i, category in ipairs(S.Catalog) do
		local chip = create("TextButton", {
			Size = UDim2.new(0, 84, 1, -4),
			BackgroundColor3 = THEME.SurfaceLight,
			AutoButtonColor = false,
			Text = category.Name,
			TextColor3 = THEME.SubText,
			TextSize = 12,
			Font = FONT_BOLD,
			LayoutOrder = i,
			Parent = chips,
		}, { corner(15) })
		chipButtons[i] = chip
		chip.MouseButton1Click:Connect(function()
			showCategory(i)
		end)
	end
	showCategory(1)
end

section("🎨 لون البشرة")
do
	local tones = card(58, "لون البشرة")
	local row = create("Frame", {
		Position = UDim2.new(0, 12, 0, 12),
		Size = UDim2.new(1, -24, 0, 34),
		BackgroundTransparency = 1,
		Parent = tones,
	}, {
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	for i, color in ipairs(S.SkinTones) do
		local swatch = create("TextButton", {
			Size = UDim2.new(0, 34, 0, 34),
			BackgroundColor3 = color,
			AutoButtonColor = false,
			Text = "",
			LayoutOrder = i,
			Parent = row,
		}, { corner(17), stroke(THEME.Stroke, 2, 0.2) })
		swatch.MouseButton1Click:Connect(function()
			S.setSkinColor(color)
		end)
	end
end

section("🧢 لبس قطعة بالرقم")
inputCard("رقم القطعة (ID)", "مثلاً 48474313", "لبس", function(text)
	local id = tonumber((text:gsub("%D", "")))
	if not id then
		notify("اكتب رقم القطعة", THEME.Danger, "⚠️")
		return
	end
	task.spawn(function()
		if S.wear(id) then
			notify("لبست القطعة " .. id .. " ✓", THEME.Success, "🧢")
		end
	end)
end)

section("👥 نسخ أفاتار لاعب")
do
	local copyCard = card(84, "نسخ أفاتار لاعب")
	titles(copyCard, "اكتب اسم اللاعب (أو جزء منه)")
	copyCard:FindFirstChildOfClass("TextLabel").Size = UDim2.new(1, -28, 0, 36)
	local box = create("TextBox", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 40),
		Size = UDim2.new(1, -170, 0, 30),
		BackgroundColor3 = THEME.SurfaceLight,
		Text = "",
		PlaceholderText = "اسم اللاعب",
		PlaceholderColor3 = THEME.SubText,
		TextColor3 = THEME.Text,
		TextSize = 13,
		Font = FONT_BOLD,
		ClearTextOnFocus = false,
		Parent = copyCard,
	}, { corner(8), stroke(THEME.Stroke, 1, 0.4) })
	local status = label(copyCard, {
		Position = UDim2.new(0, 108, 0, 40),
		Size = UDim2.new(0, 46, 0, 30),
		Text = "",
		TextColor3 = THEME.SubText,
		TextSize = 11,
	})
	local btn = smallButton(copyCard, "نسخ", UDim2.new(0, 14, 0, 40), UDim2.new(0, 88, 0, 30), true)
	btn.MouseButton1Click:Connect(function()
		local query = box.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
		if query == "" then return end
		for _, other in ipairs(Players:GetPlayers()) do
			if other ~= player and (other.Name:lower():find(query, 1, true) or other.DisplayName:lower():find(query, 1, true)) then
				S.copyAvatar(other, status)
				return
			end
		end
		notify("ما لقيت لاعب بهالاسم", THEME.Danger, "⚠️")
	end)
end
action("أو من قائمة اللاعبين", "زر 👕 جنب أي لاعب في صفحة اللاعبين", "فتح", function()
	for i, page in ipairs(pages) do
		if page.Title == "اللاعبين" then
			selectPage(i, true)
		end
	end
end)

section("💾 أطقمك المحفوظة")
local outfitList = create("Frame", {
	Size = UDim2.new(1, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
}, {
	create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
})

local function refreshOutfits()
	for _, child in ipairs(outfitList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for i, outfit in ipairs(state.outfits) do
		local row = create("Frame", {
			Size = UDim2.new(1, 0, 0, 44),
			BackgroundColor3 = THEME.Surface,
			LayoutOrder = i,
			Parent = outfitList,
		}, { corner(10), stroke(THEME.Stroke, 1, 0.5) })
		label(row, {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -14, 0.5, 0),
			Size = UDim2.new(1, -170, 1, 0),
			Text = string.format("👕 %s  (%d)", tostring(outfit.name), #(outfit.ids or {})),
			TextSize = 13,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Right,
		})
		local status = label(row, {
			Position = UDim2.new(0, 126, 0, 0),
			Size = UDim2.new(0, 50, 1, 0),
			Text = "",
			TextColor3 = THEME.SubText,
			TextSize = 11,
		})
		local wearBtn = smallButton(row, "لبس", UDim2.new(0, 10, 0.5, -13), UDim2.new(0, 70, 0, 26), true)
		wearBtn.MouseButton1Click:Connect(function()
			S.wearOutfit(outfit, status)
		end)
		local del = smallButton(row, "🗑", UDim2.new(0, 86, 0.5, -13), UDim2.new(0, 34, 0, 26), false)
		del.MouseButton1Click:Connect(function()
			table.remove(state.outfits, i)
			scheduleSave()
			refreshOutfits()
		end)
	end
end

inputCard("حفظ لبسك الحالي", "اسم الطقم (مثلاً: طقم المدرسة)", "حفظ", function(text, box)
	local name = text:gsub("^%s+", ""):gsub("%s+$", "")
	if name == "" then
		name = "طقم " .. (#state.outfits + 1)
	end
	if S.saveOutfit(name) then
		box.Text = ""
		refreshOutfits()
	end
end)
outfitList.LayoutOrder = nextOrder()
outfitList.Parent = currentPage.Frame
refreshOutfits()

section("🔄 أدوات")
action("شيل كل اللبس", "يشيل كل القطع اللي لابسها", "شيل", function()
	S.removeAll()
	notify("شلت كل اللبس", THEME.Accent2, "👕")
end)
action("رجّع شكلي الأصلي", "يرجّع أفاتار حسابك الحقيقي", "رجوع", function()
	S.reset()
	notify("رجعت لشكلك الأصلي", THEME.Success, "👕")
end)
action("نسيان طريقة اللبس", "إذا تغيّر الماب وصار اللبس ما يشتغل", "إعادة", function()
	state.wearSig = 0
	scheduleSave()
	notify("بيجرّب كل الطرق من جديد المرة الجاية", THEME.Accent2, "🔄")
end)

-----------------------------------------------------------
-- صفحة 6: الرؤية (ESP)
-----------------------------------------------------------
newPage("👁", "الرؤية")

section("👁 كشف اللاعبين")
toggle("الأسماء والمسافة", "اسم كل لاعب ومسافته من خلف الجدران", "espNames")
toggle("إظهار الصحة", "الصحة جنب المسافة", "espHealth")
toggle("تلوين اللاعبين", "إطار ملوّن حول كل لاعب", "espHighlight")
toggle("خطوط التتبّع", "خط من أسفل الشاشة لكل لاعب", "espTracers")
slider("أقصى مسافة", "espMaxDistance", 50, 5000, 50, "%d")

section("🎥 الكاميرا")
toggle("مجال الرؤية", "توسيع زاوية الكاميرا", "fovOn", function(value)
	if not value then
		Workspace.CurrentCamera.FieldOfView = 70
	end
end)
slider("زاوية الرؤية (FOV)", "fov", 30, 120, 1, "%d")

-----------------------------------------------------------
-- صفحة 7: العالم
-----------------------------------------------------------
newPage("🌍", "العالم")

section("☀️ الإضاءة")
toggle("إضاءة كاملة", "كل شي واضح حتى بالليل", "fullbright", F.applyLighting)
toggle("إلغاء الضباب", "تشوف لأبعد مسافة", "noFog", F.applyLighting)

section("🕐 الوقت")
toggle("تثبيت الوقت", "تختار وقت اليوم (عندك بس)", "timeLock", F.applyLighting)
slider("الساعة", "clockTime", 0, 24, 0.25, "%.2f")

section("⚡ الأداء")
toggle("معزّز الـ FPS", "جرافيكس خفيف: يشيل المؤثرات والانعكاسات (عندك بس)", "lowGraphics", function()
	M.applyLowGraphics()
end)
toggle("فك حد الـ FPS", "أكثر من 60 فريم (إذا الـ Executor يدعم)", "fpsUnlock", function()
	M.applyFpsCap()
end)
slider("حد الـ FPS", "fpsCap", 60, 360, 10, "%d", function()
	if state.fpsUnlock then
		M.applyFpsCap()
	end
end)

section("🧱 أدوات العالم")
toggle("رؤية من خلال الجدران", "الجدران تصير شفافة (عندك بس)", "xray", function()
	M.applyXray()
end)
toggle("حذف بالضغط", "اضغط على أي شي يختفي (عندك بس)", "deleteMode", function(value)
	M.deleteMode = value
end)
action("استرجاع المحذوف", "يرجّع كل شي حذفته", "استرجاع", function()
	M.restoreDeleted()
	notify("رجّعت كل المحذوف", THEME.Success, "🧱")
end)

-----------------------------------------------------------
-- صفحة 8: الحماية
-----------------------------------------------------------
newPage("🛡️", "الحماية")

section("🛡️ حمايتك")
toggle("ضد الرمي (Anti-Fling)", "ما أحد يقدر يطيّرك أو يدفعك", "antiFling")
toggle("ضد السقوط", "يرجعك إذا طحت من الماب", "antiVoid")
toggle("ضد الجلوس", "ما أحد يجلسك أو يمسكك (يمنعك تركب سيارة)", "antiSit")
toggle("ضد الطرد (Anti-AFK)", "ما ينطردك بسبب عدم الحركة", "antiAfk")

action("رجوع لآخر مكان آمن", "إذا علقت أو طرت", "رجوع", function()
	if F.lastSafe then
		F.teleport(F.lastSafe)
	end
end)

-----------------------------------------------------------
-- صفحة: الكاميرا
-----------------------------------------------------------
newPage("🎥", "الكاميرا")

section("🎥 كاميرا حرّة")
do
	local c = card(54, "كاميرا حرة freecam")
	titles(c, "الكاميرا الحرّة", "تطير بالكاميرا بدون شخصيتك • لف: كليك يمين أو اسحب بإصبعك")
	local sw
	sw = makeSwitch(c, false, function(value)
		M.setFreecam(value)
	end)
	switches.freecam = sw
end
slider("سرعة الكاميرا", "freecamSpeed", 10, 300, 5, "%d")

section("🔭 إعدادات الكاميرا")
toggle("تكبير بلا حدود", "تبعّد الكاميرا لأي مسافة", "maxZoom", function()
	M.applyCamera()
end)
toggle("منظور أول شخص", "تشوف من عيون شخصيتك", "firstPerson", function()
	M.applyCamera()
end)

-----------------------------------------------------------
-- صفحة: الترفيه
-----------------------------------------------------------
newPage("🎵", "الترفيه")

section("🎵 مشغّل الموسيقى (عندك بس)")
inputCard("رقم الأغنية (Sound ID)", "مثلاً 1837849285", "تشغيل", function(text)
	M.playMusic(text)
end)
slider("الصوت", "musicVolume", 0, 2, 0.05, "%.2f", function(value)
	M.music.Volume = value
end)
action("إيقاف الأغنية", "يوقف الموسيقى", "إيقاف", function()
	M.stopMusic()
end)

section("✨ مؤثرات (عندك بس)")
toggle("ذيل ملوّن", "ذيل بألوان قوس قزح وراك", "trail", function()
	M.applyTrail()
end)

-----------------------------------------------------------
-- صفحة: السيرفر
-----------------------------------------------------------
newPage("🌐", "السيرفر")

section("📊 معلومات السيرفر")
local serverLabels = {}
do
	local c = card(112, "معلومات السيرفر")
	local function row(y, name)
		label(c, {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -14, 0, y),
			Size = UDim2.new(0.5, -14, 0, 18),
			Text = name,
			TextColor3 = THEME.SubText,
			TextSize = 13,
			Font = FONT_REG,
			TextXAlignment = Enum.TextXAlignment.Right,
		})
		return label(c, {
			Position = UDim2.new(0, 14, 0, y),
			Size = UDim2.new(0.5, -14, 0, 18),
			Text = "—",
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
	end
	serverLabels.Players = row(12, "👥 اللاعبين")
	serverLabels.Uptime = row(34, "⏱ عمر السيرفر")
	serverLabels.Ping = row(56, "📶 البنق")
	serverLabels.Place = row(78, "🆔 رقم الماب")
end

section("🔀 التنقّل بين السيرفرات")
action("سيرفر ثاني", "ينقلك لسيرفر عشوائي ثاني", "انتقال", function()
	M.serverHop(false)
end)
action("أقل سيرفر لاعبين", "ينقلك لأفضى سيرفر", "انتقال", function()
	M.serverHop(true)
end)
action("إعادة الدخول", "ترجع لنفس السيرفر", "إعادة", function()
	M.rejoin()
end)
action("نسخ رقم السيرفر", "Job ID حق السيرفر الحالي", "نسخ", function()
	M.copy(game.JobId, "رقم السيرفر")
end)

-----------------------------------------------------------
-- صفحة: الأوامر
-----------------------------------------------------------
newPage("⌨️", "الأوامر")

section("⌨️ اكتب أمر")
do
	local box = inputCard("الأمر", "مثلاً: speed 100  أو  روح احمد", "تنفيذ", function(text, b)
		M.runCommand(text)
		b.Text = ""
	end)
	box.TextXAlignment = Enum.TextXAlignment.Left
end

section("📜 الأوامر المتاحة")
do
	local lines = {}
	for _, command in ipairs(M.Commands) do
		table.insert(lines, string.format("%s  /  %s   —   %s", command[1][1], command[1][2], command[2]))
	end
	local c = card(#lines * 19 + 20, "الأوامر")
	c:SetAttribute("Search", nil)
	label(c, {
		Position = UDim2.new(0, 14, 0, 10),
		Size = UDim2.new(1, -28, 1, -20),
		Text = table.concat(lines, "\n"),
		TextColor3 = THEME.SubText,
		TextSize = 12,
		Font = Enum.Font.Code,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
end

-- تحديث معلومات السيرفر
task.spawn(function()
	while screenGui.Parent do
		serverLabels.Players.Text = string.format("%d / %d", #Players:GetPlayers(), Players.MaxPlayers)
		serverLabels.Uptime.Text = M.formatTime(Workspace.DistributedGameTime)
		local ok, ping = pcall(function()
			return player:GetNetworkPing()
		end)
		serverLabels.Ping.Text = ok and string.format("%d ms", math.floor(ping * 1000 + 0.5)) or "—"
		serverLabels.Place.Text = tostring(game.PlaceId)
		task.wait(1)
	end
end)

-----------------------------------------------------------
-- صفحة 9: الإعدادات
-----------------------------------------------------------
newPage("⚙️", "الإعدادات")

section("🎨 الثيم")
local themeStrokes = {}
local function applyTheme(index)
	state.themeIndex = index
	scheduleSave()
	local theme = CONFIG.Themes[index]
	THEME.Accent = theme.Accent
	THEME.Accent2 = theme.Accent2
	local sequence = ColorSequence.new(THEME.Accent, THEME.Accent2)
	for _, g in ipairs(UI.Gradients) do
		g.Color = sequence
	end
	for _, ref in ipairs(UI.AccentRefs) do
		ref[1][ref[2]] = THEME[ref[3]]
	end
	for i, s in ipairs(themeStrokes) do
		tween(s, 0.2, { Transparency = (i == index) and 0 or 1 })
	end
end
do
	local themeCard = card(64, "ثيم")
	local row = create("Frame", {
		Position = UDim2.new(0, 12, 0, 14),
		Size = UDim2.new(1, -24, 0, 36),
		BackgroundTransparency = 1,
		Parent = themeCard,
	}, {
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	for i, theme in ipairs(CONFIG.Themes) do
		local btn = create("TextButton", {
			Size = UDim2.new(1 / #CONFIG.Themes, -7, 1, 0),
			BackgroundColor3 = Color3.new(1, 1, 1),
			AutoButtonColor = false,
			Text = theme.Name,
			TextColor3 = Color3.new(1, 1, 1),
			TextStrokeTransparency = 0.6,
			TextSize = 12,
			Font = FONT_BOLD,
			LayoutOrder = i,
			Parent = row,
		}, { corner(9), create("UIGradient", { Color = ColorSequence.new(theme.Accent, theme.Accent2) }) })
		local s = stroke(THEME.Text, 2, 1)
		s.Parent = btn
		themeStrokes[i] = s
		btn.MouseButton1Click:Connect(function()
			applyTheme(i)
		end)
	end
end

section("📸 وضع التصوير")
action("وضع التصوير", "يخفي كل الواجهات • زر 👁 فوق يرجّعها (" .. state.screenshotKey .. ")", "تشغيل", function()
	M.setScreenshot(true)
end)

section("🖥️ الواجهة")
toggle("لوحة الأداء", "FPS والبنق وعدد اللاعبين", "showStats", function(value)
	statsPanel.Visible = value
end)
toggle("ضبابية الخلفية", "تأثير ضبابي لما تفتح الواجهة", "blur", function(value)
	tween(blurEffect, 0.3, { Size = (value and state.guiVisible) and 10 or 0 })
end)

local floatingBtn = create("TextButton", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0, 52, 0.5, 0),
	Size = UDim2.new(0, 54, 0, 54),
	BackgroundColor3 = Color3.new(1, 1, 1),
	AutoButtonColor = false,
	Text = "🏡",
	TextSize = 24,
	Font = FONT_BOLD,
	Visible = state.floatingButton,
	ZIndex = 40,
	Parent = screenGui,
}, { corner(27), accentGradient(45), stroke(THEME.Background, 2) })

toggle("زر عائم", "زر على الشاشة لفتح الواجهة (للجوال)", "floatingButton", function(value)
	floatingBtn.Visible = value
end)

section("ℹ️ عن السكربت")
do
	local about = card(90, "")
	about:SetAttribute("Search", nil)
	local name = label(about, {
		Position = UDim2.new(0, 14, 0, 14),
		Size = UDim2.new(1, -28, 0, 24),
		Text = "✦ " .. CONFIG.Author .. " ✦",
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 20,
	})
	accentGradient(0).Parent = name
	label(about, {
		Position = UDim2.new(0, 14, 0, 44),
		Size = UDim2.new(1, -28, 0, 16),
		Text = CONFIG.Name .. "  •  " .. CONFIG.Version,
		TextColor3 = THEME.SubText,
		TextSize = 12,
		Font = FONT_REG,
	})
	label(about, {
		Position = UDim2.new(0, 14, 0, 64),
		Size = UDim2.new(1, -28, 0, 16),
		Text = "شكراً لاستخدامك السكربت ❤",
		TextSize = 12,
	})
end

-----------------------------------------------------------
-- الإظهار / الإخفاء والسحب
-----------------------------------------------------------
-- حركة الفتح: نحرّك قيمة رقمية ونضربها بمقياس الشاشة
local openValue = create("NumberValue", { Value = 0, Parent = screenGui })
openValue.Changed:Connect(function(value)
	openScale = value
	applyScale()
end)

local function setVisible(visible)
	state.guiVisible = visible
	if visible then
		mainFrame.Visible = true
		tween(openValue, 0.35, { Value = 1 }, Enum.EasingStyle.Back)
	else
		tween(openValue, 0.2, { Value = 0 }).Completed:Connect(function()
			if not state.guiVisible then
				mainFrame.Visible = false
			end
		end)
	end
	tween(blurEffect, 0.3, { Size = (visible and state.blur) and 10 or 0 })
end

local dragging, dragStart, startPos
local floatPressed, floatMoved, floatStart, floatStartPos = false, false, nil, nil

header.InputBegan:Connect(function(input)
	if isPress(input) then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position
	end
end)
floatingBtn.InputBegan:Connect(function(input)
	if isPress(input) then
		floatPressed, floatMoved = true, false
		floatStart, floatStartPos = input.Position, floatingBtn.Position
	end
end)

connect(UserInputService.InputChanged, function(input)
	if not isMove(input) then return end
	if activeSlider then
		activeSlider.update(input.Position.X)
	elseif dragging then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	elseif floatPressed then
		local delta = input.Position - floatStart
		if delta.Magnitude > 6 then
			floatMoved = true
		end
		if floatMoved then
			floatingBtn.Position = UDim2.new(
				floatStartPos.X.Scale, floatStartPos.X.Offset + delta.X,
				floatStartPos.Y.Scale, floatStartPos.Y.Offset + delta.Y
			)
		end
	end
end)

-- الانتقال باللمس: ضغطة قصيرة بس (عشان لف الكاميرا ما ينقلك)
local tapStart, tapTime

connect(UserInputService.InputEnded, function(input)
	if input.UserInputType == Enum.UserInputType.Touch and tapStart then
		local moved = (input.Position - tapStart).Magnitude
		local held = os.clock() - tapTime
		tapStart = nil
		if moved < 12 and held < 0.35 then
			if M.deleteMode then
				M.deleteAt(input.Position)
			elseif F.tapToTeleport then
				F.teleportToScreenPoint(input.Position)
			end
		end
	end
	if isPress(input) then
		if activeSlider then
			activeSlider.release()
			activeSlider = nil
		end
		if floatPressed and not floatMoved then
			setVisible(not state.guiVisible)
		end
		floatPressed = false
		dragging = false
	end
end)

connect(UserInputService.InputBegan, function(input, gameProcessed)
	-- الانتقال بالضغط
	if isPress(input) and not gameProcessed then
		if input.UserInputType == Enum.UserInputType.Touch then
			tapStart, tapTime = input.Position, os.clock()
		elseif M.deleteMode and input.UserInputType == Enum.UserInputType.MouseButton1 then
			M.deleteAt(input.Position)
			return
		elseif state.clickTp and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			F.teleportToScreenPoint(input.Position)
			return
		end
	end

	if gameProcessed then return end
	local key = input.KeyCode
	if key.Name == state.toggleKey then
		setVisible(not state.guiVisible)
	elseif key.Name == state.flyKey then
		F.setFly(not state.fly)
		notify(state.fly and "الطيران شغّال" or "الطيران طافي", THEME.Accent2, "✈️")
	elseif key.Name == state.noclipKey then
		M.setToggle("noclip", not state.noclip)
		notify(state.noclip and "اختراق الجدران شغّال" or "اختراق الجدران طافي", THEME.Accent2, "👻")
	elseif key.Name == state.screenshotKey then
		M.setScreenshot(not M.screenshot)
	end
end)

hideBtn.MouseButton1Click:Connect(function()
	setVisible(false)
	notify("الواجهة مخفية — اضغط " .. state.toggleKey .. " أو الزر العائم", THEME.Accent2, "👁")
end)

-- إطار متحرك
connect(RunService.RenderStepped, function()
	local t = os.clock()
	borderGradient.Rotation = (t * 60) % 360
	if state.guiVisible then
		for _, blob in ipairs(decorBlobs) do
			blob.Frame.Position = UDim2.new(
				blob.X + math.sin(t * 0.35 + blob.Phase) * 0.06, 0,
				blob.Y + math.cos(t * 0.3 + blob.Phase) * 0.08, 0
			)
		end
	end
end)

local camConnection
local function watchCamera()
	if camConnection then
		camConnection:Disconnect()
	end
	local camera = Workspace.CurrentCamera
	if camera then
		camConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateFit)
		updateFit()
	end
end
connect(Workspace:GetPropertyChangedSignal("CurrentCamera"), watchCamera)
watchCamera()

-----------------------------------------------------------
-- الإغلاق
-----------------------------------------------------------
local function cleanup()
	state.fly = false
	F.flying = false
	state.noclip = false
	state.speedOn = false
	state.jumpOn = false
	F.restoreMovement()
	local _, humanoid = getCharacter()
	if humanoid then
		humanoid.PlatformStand = false
	end
	state.fullbright, state.noFog, state.timeLock = false, false, false
	F.applyLighting()
	F.spectate(nil)
	for other in pairs(F.esp) do
		F.clearEsp(other)
	end
	for _, c in ipairs(connections) do
		c:Disconnect()
	end
	if camConnection then
		camConnection:Disconnect()
	end
	-- مميزات إضافية
	if M.freecam then
		M.setFreecam(false)
	end
	if M.screenshot then
		M.setScreenshot(false)
	end
	state.gravityOn, state.maxZoom, state.firstPerson = false, false, false
	M.applyGravity()
	M.applyCamera()
	M.restoreDeleted()
	if state.xray then
		state.xray = false
		M.applyXray()
	end
	if state.lowGraphics then
		state.lowGraphics = false
		M.graphicsBusy = false
		M.applyLowGraphics()
	end
	state.trail = false
	M.applyTrail()
	M.screenshotButton.Parent:Destroy()

	blurEffect:Destroy()
	screenGui:Destroy()
	_G.MohammedTN_Brookhaven_Cleanup = nil
end
_G.MohammedTN_Brookhaven_Cleanup = cleanup

closeBtn.MouseButton1Click:Connect(function()
	setVisible(false)
	task.wait(0.25)
	cleanup()
end)

-----------------------------------------------------------
-- شاشة التحميل
-----------------------------------------------------------
applyTheme(state.themeIndex)
F.applyLighting()
F.tapToTeleport = state.clickTp
statsPanel.Visible = state.showStats
M.applyCamera()
M.applyTrail()
if state.fpsUnlock then
	M.applyFpsCap()
end

do
	local splash = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 300, 0, 170),
		BackgroundColor3 = THEME.Background,
		ZIndex = 60,
		Parent = screenGui,
	}, { corner(18) })
	local splashStroke = stroke(Color3.new(1, 1, 1), 2)
	splashStroke.Parent = splash
	accentGradient(0).Parent = splashStroke

	create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 18),
		Size = UDim2.new(0, 56, 0, 56),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = splash,
	}, {
		corner(16),
		accentGradient(45),
		create("TextLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = "🏡",
			TextSize = 30,
			Font = FONT_BOLD,
		}),
	})
	local splashTitle = label(splash, {
		Position = UDim2.new(0, 0, 0, 82),
		Size = UDim2.new(1, 0, 0, 24),
		Text = CONFIG.Name,
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 20,
	})
	accentGradient(0).Parent = splashTitle
	local splashText = label(splash, {
		Position = UDim2.new(0, 0, 0, 108),
		Size = UDim2.new(1, 0, 0, 16),
		Text = "صنع من قبل " .. CONFIG.Author,
		TextColor3 = THEME.SubText,
		TextSize = 12,
		Font = FONT_REG,
	})
	local barBg = create("Frame", {
		Position = UDim2.new(0, 30, 0, 140),
		Size = UDim2.new(1, -60, 0, 6),
		BackgroundColor3 = THEME.SurfaceLight,
		Parent = splash,
	}, { corner(3) })
	local bar = create("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = barBg,
	}, { corner(3), accentGradient(0) })

	local splashScale = create("UIScale", { Scale = 0.8, Parent = splash })
	tween(splashScale, 0.4, { Scale = 1 }, Enum.EasingStyle.Back)

	local steps = { "تحميل الواجهة...", "تجهيز المميزات...", "تحميل اللاعبين...", "جاهز ✓" }
	for i, text in ipairs(steps) do
		splashText.Text = text
		tween(bar, 0.32, { Size = UDim2.new(i / #steps, 0, 1, 0) })
		task.wait(0.35)
	end
	task.wait(0.15)
	tween(splashScale, 0.25, { Scale = 0 }).Completed:Wait()
	splash:Destroy()
end

updateFit()
selectPage(math.clamp(math.floor(state.activePage), 1, #pages), false)
setVisible(true)
notify("أهلاً " .. player.DisplayName .. "! السكربت جاهز", THEME.Success, "🏡")
