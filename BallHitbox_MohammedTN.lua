--[[
	╔══════════════════════════════════════════╗
	║        ⚽  موسّع هيتبوكس الكرة  ⚽         ║
	║          صنع من قبل: محمد TN             ║
	║                 v4.2                     ║
	╚══════════════════════════════════════════╝

	• إظهار / إخفاء الواجهة : RightShift  (قابل للتغيير)
	• تشغيل / إيقاف الهيتبوكس : H          (قابل للتغيير)
	• توقّع مسار الشوت: فيزياء كاملة (جاذبية + قوة الكرة + ارتداد + تعويض البنق)
	• يدعم الكمبيوتر والجوال (زر عائم للجوال)
	• حفظ الإعدادات تلقائياً (إذا كان الـ Executor يدعم writefile)
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

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-----------------------------------------------------------
-- الإعدادات الثابتة
-----------------------------------------------------------
local CONFIG = {
	Version = "v4.2",
	Author = "محمد TN",
	SaveFile = "MohammedTN_Hitbox_v4.json",
	MinSize = 0.5,
	MaxSize = 10,
	SizePresets = { 2, 4, 6, 8 },
	AutoSizeRange = 40,          -- كل 40 مسافة يتضاعف الحجم في الوضع التلقائي
	AlertSound = "rbxasset://sounds/electronicpingshort.wav",
	Prediction = {
		Step = 1 / 60,           -- دقة المحاكاة (60 خطوة بالثانية)
		PointEvery = 3,          -- نرسم نقطة كل 3 خطوات
		MaxBounces = 4,
		MaxBalls = 3,            -- أقصى عدد كرات نتوقع مسارها بنفس الوقت
		MinSpeed = 4,            -- أقل سرعة نعتبر فيها الكرة متحركة
		MaxRange = 350,          -- أبعد مسافة للكرة عنك
		SettleSpeed = 2.5,       -- تحت هذه السرعة العمودية الكرة تتدحرج ونوقف
		CalibrationRate = 0.12,  -- سرعة المعايرة التلقائية
		CalibrationLimit = 80,   -- نتجاهل القفزات الكبيرة (اصطدامات)
	},
	Analysis = {
		KickJump = 18,           -- زيادة مفاجئة بالسرعة = ركلة
		MinShotSpeed = 25,       -- أقل سرعة نعتبرها شوت
		RecordTime = 3,          -- مدة تسجيل المسار الحقيقي بعد الشوت
		MaxOrigins = 20,         -- عدد أماكن التسديد المحفوظة
		KickerRange = 10,        -- أبعد مسافة بين اللاعب والكرة لحظة الركلة
		PossessionRange = 7,     -- الكرة "عند" اللاعب إذا كانت أقرب من كذا
		PossessionSpeed = 15,    -- وأبطأ من كذا
		LearnCount = 3,          -- نتعلم من آخر 3 شوتات لكل لاعب
		MaxOpponents = 2,        -- أقصى عدد خصوم نتوقع شوتهم
	},
	OutlineColors = {
		Color3.fromRGB(124, 92, 255),
		Color3.fromRGB(0, 190, 255),
		Color3.fromRGB(46, 204, 113),
		Color3.fromRGB(255, 200, 0),
		Color3.fromRGB(235, 77, 75),
		Color3.fromRGB(255, 255, 255),
	},
	Themes = {
		{ Name = "بنفسجي", Accent = Color3.fromRGB(124, 92, 255), Accent2 = Color3.fromRGB(0, 190, 255) },
		{ Name = "أحمر",   Accent = Color3.fromRGB(235, 64, 90),  Accent2 = Color3.fromRGB(255, 140, 60) },
		{ Name = "أخضر",   Accent = Color3.fromRGB(46, 204, 113), Accent2 = Color3.fromRGB(0, 200, 180) },
		{ Name = "ذهبي",   Accent = Color3.fromRGB(255, 190, 40), Accent2 = Color3.fromRGB(255, 120, 40) },
	},
	-- ضع روابطك هنا لتظهر في صفحة "عن السكربت" (اتركها فارغة لإخفائها)
	Links = {
		{ Name = "ديسكورد", Url = "" },
		{ Name = "يوتيوب", Url = "" },
	},
}

-----------------------------------------------------------
-- الألوان
-----------------------------------------------------------
local THEME = {
	Background   = Color3.fromRGB(13, 13, 20),
	Surface      = Color3.fromRGB(21, 21, 32),
	SurfaceLight = Color3.fromRGB(33, 33, 50),
	Stroke       = Color3.fromRGB(56, 56, 86),
	Accent       = CONFIG.Themes[1].Accent,
	Accent2      = CONFIG.Themes[1].Accent2,
	Text         = Color3.fromRGB(240, 240, 250),
	SubText      = Color3.fromRGB(148, 148, 176),
	Success      = Color3.fromRGB(46, 204, 113),
	Danger       = Color3.fromRGB(235, 77, 75),
	Warning      = Color3.fromRGB(255, 190, 40),
}

local FONT_BOLD = Enum.Font.GothamBold
local FONT_REG = Enum.Font.Gotham

-----------------------------------------------------------
-- تنظيف أي نسخة سابقة من السكربت
-----------------------------------------------------------
if _G.MohammedTN_Hitbox_Cleanup then
	pcall(_G.MohammedTN_Hitbox_Cleanup)
end

-----------------------------------------------------------
-- الحالة (القيم المحفوظة + قيم التشغيل)
-----------------------------------------------------------
local state = {
	-- محفوظة
	ballName = "Ball",
	size = 1,
	autoSize = false,
	axisX = 1,
	axisY = 1,
	axisZ = 1,
	showHitbox = true,
	transparency = 0.5,
	outline = true,
	colorIndex = 2,
	pulse = false,
	esp = false,
	tracer = false,
	prediction = true,
	predictTime = 2.5,
	predictBounces = true,
	predictLag = true,
	predictCalibrate = true,
	predictLanding = true,
	predictClosest = true,
	predictLabels = true,
	goalEntry = true,
	showGoalFrame = true,
	goals = {},
	goalWidth = 24,
	goalHeight = 8,
	showReplay = true,
	showOrigins = false,
	shotAssist = true,
	assistCamera = false,
	opponentPredict = true,
	alert = false,
	alertDistance = 15,
	toggleKey = "RightShift",
	quickKey = "H",
	themeIndex = 1,
	floatingButton = UserInputService.TouchEnabled,
	activeTab = 1,

	-- غير محفوظة
	enabled = false,
	guiVisible = true,
	minimized = false,
}

local SAVED_KEYS = {
	"ballName", "size", "autoSize", "axisX", "axisY", "axisZ", "showHitbox",
	"transparency", "outline", "colorIndex", "pulse", "esp", "tracer",
	"prediction", "predictTime", "predictBounces", "predictLag", "predictCalibrate",
	"predictLanding", "predictClosest", "predictLabels", "goalEntry", "showGoalFrame",
	"goals", "goalWidth", "goalHeight", "showReplay", "showOrigins", "shotAssist", "assistCamera", "opponentPredict", "alert", "alertDistance", "toggleKey",
	"quickKey", "themeIndex", "floatingButton", "activeTab",
}

-----------------------------------------------------------
-- حفظ / تحميل الإعدادات
-----------------------------------------------------------
local canSave = typeof(writefile) == "function"
	and typeof(readfile) == "function"
	and typeof(isfile) == "function"

local function loadSettings()
	if not canSave then return end
	local ok, data = pcall(function()
		if isfile(CONFIG.SaveFile) then
			return HttpService:JSONDecode(readfile(CONFIG.SaveFile))
		end
		return nil
	end)
	if not ok or type(data) ~= "table" then return end
	for _, key in ipairs(SAVED_KEYS) do
		if data[key] ~= nil and type(data[key]) == type(state[key]) then
			state[key] = data[key]
		end
	end
	-- التحقق من القيم
	local goals = {}
	for _, g in ipairs(state.goals) do
		if type(g) == "table" and #g >= 5 and type(g[1]) == "number" then
			table.insert(goals, g)
		end
	end
	state.goals = goals
	state.colorIndex = math.clamp(math.floor(state.colorIndex), 1, #CONFIG.OutlineColors)
	state.themeIndex = math.clamp(math.floor(state.themeIndex), 1, #CONFIG.Themes)
	if not pcall(function() return Enum.KeyCode[state.toggleKey] end) then state.toggleKey = "RightShift" end
	if not pcall(function() return Enum.KeyCode[state.quickKey] end) then state.quickKey = "H" end
end

local savePending = false
local function scheduleSave()
	if not canSave or savePending then return end
	savePending = true
	task.delay(0.5, function()
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

loadSettings()
THEME.Accent = CONFIG.Themes[state.themeIndex].Accent
THEME.Accent2 = CONFIG.Themes[state.themeIndex].Accent2

-- [part] = { Size, Transparency, CanCollide, Mass, Conn, Box, Esp, EspLabel, Tracer, Calib, LastVel, LastVelTime }
local trackedBalls = {}
local connections = {}

local function connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(connections, c)
	return c
end

-----------------------------------------------------------
-- أدوات مساعدة للواجهة
-----------------------------------------------------------
local accentRefs = {}   -- عناصر تتغير مع الثيم
local gradients = {}

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

-- ربط خاصية بلون من الثيم ليتحدّث عند تغيير الثيم
local function accentize(inst, prop, key)
	inst[prop] = THEME[key]
	table.insert(accentRefs, { inst, prop, key })
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
	table.insert(gradients, g)
	return g
end

local function tween(obj, time, props, style)
	local t = TweenService:Create(
		obj,
		TweenInfo.new(time, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		props
	)
	t:Play()
	return t
end

local function isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
end

local function hoverButton(btn, normalColor)
	btn.MouseEnter:Connect(function()
		tween(btn, 0.2, { BackgroundColor3 = THEME.Accent, TextColor3 = THEME.Text })
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, 0.2, { BackgroundColor3 = normalColor, TextColor3 = THEME.SubText })
	end)
end

-----------------------------------------------------------
-- الواجهة الرئيسية
-----------------------------------------------------------
local FULL_SIZE = UDim2.new(0, 360, 0, 500)
local MINI_SIZE = UDim2.new(0, 360, 0, 58)

local screenGui = create("ScreenGui", {
	Name = "MohammedTN_HitboxGui",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = playerGui,
})

-- طبقة الرسم (خطوط التتبّع) خلف الواجهة
local overlay = create("Frame", {
	Name = "Overlay",
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Parent = screenGui,
})

local mainFrame = create("Frame", {
	Name = "Main",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	Size = FULL_SIZE,
	BackgroundColor3 = THEME.Background,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Active = true,
	Parent = screenGui,
}, {
	corner(16),
	stroke(THEME.Stroke, 1.5),
})

local mainScale = create("UIScale", { Scale = 0, Parent = mainFrame })

create("Frame", {
	Size = UDim2.new(1, 0, 0, 3),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BorderSizePixel = 0,
	ZIndex = 5,
	Parent = mainFrame,
}, { accentGradient(0) })

-----------------------------------------------------------
-- شريط العنوان
-----------------------------------------------------------
local titleBar = create("Frame", {
	Name = "TitleBar",
	Size = UDim2.new(1, 0, 0, 58),
	BackgroundColor3 = THEME.Surface,
	BorderSizePixel = 0,
	Active = true,
	Parent = mainFrame,
})

create("Frame", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -14, 0.5, 0),
	Size = UDim2.new(0, 36, 0, 36),
	BackgroundColor3 = Color3.new(1, 1, 1),
	Parent = titleBar,
}, {
	corner(10),
	accentGradient(45),
	create("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "⚽",
		TextSize = 20,
		Font = FONT_BOLD,
		TextColor3 = THEME.Text,
	}),
})

create("TextLabel", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -60, 0, 10),
	Size = UDim2.new(1, -150, 0, 22),
	BackgroundTransparency = 1,
	Text = "موسّع هيتبوكس الكرة",
	TextColor3 = THEME.Text,
	TextSize = 17,
	Font = FONT_BOLD,
	TextXAlignment = Enum.TextXAlignment.Right,
	Parent = titleBar,
})

create("TextLabel", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -60, 0, 32),
	Size = UDim2.new(1, -150, 0, 16),
	BackgroundTransparency = 1,
	Text = "صنع من قبل " .. CONFIG.Author .. "  •  " .. CONFIG.Version,
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 12,
	Font = FONT_BOLD,
	TextXAlignment = Enum.TextXAlignment.Right,
	Parent = titleBar,
}, { accentGradient(0) })

local function titleButton(text, xOffset, hoverColor)
	local btn = create("TextButton", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, xOffset, 0.5, 0),
		Size = UDim2.new(0, 30, 0, 30),
		BackgroundColor3 = THEME.SurfaceLight,
		AutoButtonColor = false,
		Text = text,
		TextColor3 = THEME.SubText,
		TextSize = 16,
		Font = FONT_BOLD,
		Parent = titleBar,
	}, { corner(8) })
	btn.MouseEnter:Connect(function()
		tween(btn, 0.2, { BackgroundColor3 = hoverColor or THEME.Accent, TextColor3 = THEME.Text })
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, 0.2, { BackgroundColor3 = THEME.SurfaceLight, TextColor3 = THEME.SubText })
	end)
	return btn
end

local closeBtn = titleButton("✕", 14, THEME.Danger)
local minimizeBtn = titleButton("—", 50)

-----------------------------------------------------------
-- التبويبات
-----------------------------------------------------------
local TAB_NAMES = { "⚽ هيتبوكس", "🎯 توقّع", "📊 تحليل", "🎨 مظهر", "🧭 أدوات", "⚙️ إعدادات" }
local TAB_COUNT = #TAB_NAMES

local tabBar = create("Frame", {
	Name = "Tabs",
	Position = UDim2.new(0, 12, 0, 66),
	Size = UDim2.new(1, -24, 0, 36),
	BackgroundColor3 = THEME.Surface,
	BorderSizePixel = 0,
	Parent = mainFrame,
}, { corner(10), stroke(THEME.Stroke, 1, 0.5) })

local tabIndicator = create("Frame", {
	Size = UDim2.new(1 / TAB_COUNT, -10, 1, -8),
	Position = UDim2.new(0, 5, 0, 4),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BorderSizePixel = 0,
	Parent = tabBar,
}, { corner(8), accentGradient(0) })

local pageHolder = create("Frame", {
	Name = "Pages",
	Position = UDim2.new(0, 0, 0, 108),
	Size = UDim2.new(1, 0, 1, -108),
	BackgroundTransparency = 1,
	Parent = mainFrame,
})

local pages = {}
local currentPage

-- التبويب الأول على اليمين (ترتيب عربي)
local function tabPosition(index)
	return UDim2.new((TAB_COUNT - index) / TAB_COUNT, 5, 0, 4)
end

local function selectTab(index, animated)
	state.activeTab = index
	for i, page in ipairs(pages) do
		page.Frame.Visible = (i == index)
		tween(page.Button, 0.2, { TextColor3 = (i == index) and THEME.Text or THEME.SubText })
	end
	tween(tabIndicator, animated and 0.3 or 0, { Position = tabPosition(index) })
end

local function newPage(title)
	local index = #pages + 1
	local frame = create("ScrollingFrame", {
		Name = "Page" .. index,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false,
		Parent = pageHolder,
	}, {
		create("UIListLayout", {
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		create("UIPadding", {
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 14),
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
		}),
	})
	accentize(frame, "ScrollBarImageColor3", "Accent")

	local button = create("TextButton", {
		Size = UDim2.new(1 / TAB_COUNT, 0, 1, 0),
		Position = UDim2.new((TAB_COUNT - index) / TAB_COUNT, 0, 0, 0),
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = THEME.SubText,
		TextScaled = true,
		Font = FONT_BOLD,
		ZIndex = 2,
		Parent = tabBar,
	}, {
		create("UITextSizeConstraint", { MaxTextSize = 12, MinTextSize = 8 }),
		create("UIPadding", { PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 3) }),
	})
	button.MouseButton1Click:Connect(function()
		selectTab(index, true)
		scheduleSave()
	end)

	pages[index] = { Frame = frame, Button = button, Order = 0 }
	currentPage = pages[index]
	return currentPage
end

local function nextOrder()
	currentPage.Order += 1
	return currentPage.Order
end

local function card(height)
	return create("Frame", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = THEME.Surface,
		BorderSizePixel = 0,
		LayoutOrder = nextOrder(),
		Parent = currentPage.Frame,
	}, { corner(12), stroke(THEME.Stroke, 1, 0.45) })
end

local function label(parent, props)
	props.BackgroundTransparency = 1
	props.Font = props.Font or FONT_BOLD
	props.TextColor3 = props.TextColor3 or THEME.Text
	props.Parent = parent
	return create("TextLabel", props)
end

local function sectionHeader(text)
	local header = label(currentPage.Frame, {
		Size = UDim2.new(1, 0, 0, 20),
		Text = text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
		LayoutOrder = nextOrder(),
	})
	accentize(header, "TextColor3", "Accent2")
end

local function cardHeading(parent, text, y)
	return label(parent, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, y or 10),
		Size = UDim2.new(1, -150, 0, 20),
		Text = text,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Right,
	})
end

local function cardTitle(parent, title, subtitle)
	label(parent, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 9),
		Size = UDim2.new(1, -90, 0, 18),
		Text = title,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	return label(parent, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 28),
		Size = UDim2.new(1, -90, 0, 14),
		Text = subtitle,
		TextColor3 = THEME.SubText,
		TextSize = 12,
		Font = FONT_REG,
		TextXAlignment = Enum.TextXAlignment.Right,
	})
end

-- مفتاح تشغيل/إيقاف متحرّك
local function makeSwitch(parent, initial, onChanged)
	local switch = create("TextButton", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 14, 0.5, 0),
		Size = UDim2.new(0, 48, 0, 26),
		BackgroundColor3 = THEME.SurfaceLight,
		AutoButtonColor = false,
		Text = "",
		Parent = parent,
	}, { corner(13) })

	local gradient = accentGradient(0)
	gradient.Parent = switch

	local knob = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.new(0, 20, 0, 20),
		BackgroundColor3 = THEME.SubText,
		Parent = switch,
	}, { corner(10) })

	local value = initial
	local api = {}

	local function render(animated)
		gradient.Enabled = value
		switch.BackgroundColor3 = value and Color3.new(1, 1, 1) or THEME.SurfaceLight
		tween(knob, animated and 0.25 or 0, {
			Position = value and UDim2.new(1, -23, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
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

	switch.MouseButton1Click:Connect(function()
		api.set(not value)
	end)

	render(false)
	return api
end

-- بطاقة فيها عنوان + مفتاح مربوط بقيمة في state
local function switchCard(title, subtitle, key, onExtra)
	local c = card(54)
	local sub = cardTitle(c, title, subtitle)
	local sw = makeSwitch(c, state[key], function(value)
		state[key] = value
		scheduleSave()
		if onExtra then
			onExtra(value)
		end
	end)
	return sw, sub, c
end

-- شريط تمرير قابل لإعادة الاستخدام (الرقم يظهر فوقه على اليسار)
local activeSlider = nil

local function makeSlider(parent, y, min, max, step, initial, format, onChanged)
	local page = currentPage.Frame

	local bg = create("Frame", {
		Position = UDim2.new(0, 14, 0, y),
		Size = UDim2.new(1, -28, 0, 10),
		BackgroundColor3 = THEME.SurfaceLight,
		Active = true,
		Parent = parent,
	}, { corner(5) })

	local fill = create("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = bg,
	}, { corner(5), accentGradient(0) })

	local knobStroke = stroke(THEME.Accent, 2)
	accentize(knobStroke, "Color", "Accent")
	local knob = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, 18, 0, 18),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 2,
		Parent = bg,
	}, { corner(9), knobStroke })

	local badge = create("TextLabel", {
		Position = UDim2.new(0, 14, 0, y - 38),
		Size = UDim2.new(0, 60, 0, 24),
		BackgroundColor3 = THEME.SurfaceLight,
		Text = "",
		TextSize = 14,
		Font = FONT_BOLD,
		Parent = parent,
	}, { corner(6) })
	accentize(badge, "TextColor3", "Accent2")

	local api = { value = initial }

	function api.set(value, animated, silent)
		value = math.clamp(math.floor(value / step + 0.5) * step, min, max)
		api.value = value
		local percent = (value - min) / (max - min)
		local t = animated and 0.25 or 0
		tween(fill, t, { Size = UDim2.new(percent, 0, 1, 0) })
		tween(knob, t, { Position = UDim2.new(percent, 0, 0.5, 0) })
		badge.Text = string.format(format, value)
		if not silent then
			onChanged(value)
		end
	end

	function api.update(x)
		local percent = math.clamp((x - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
		api.set(min + percent * (max - min), false)
	end

	function api.release()
		page.ScrollingEnabled = true
		tween(knob, 0.15, { Size = UDim2.new(0, 18, 0, 18) })
	end

	bg.InputBegan:Connect(function(input)
		if isPress(input) then
			activeSlider = api
			page.ScrollingEnabled = false
			tween(knob, 0.15, { Size = UDim2.new(0, 22, 0, 22) })
			api.update(input.Position.X)
		end
	end)

	api.set(initial, false, true)
	return api
end

-- بطاقة فيها عنوان + شريط مربوط بقيمة في state
local function sliderCard(title, key, min, max, step, format)
	local c = card(70)
	cardHeading(c, title)
	return makeSlider(c, 46, min, max, step, state[key], format, function(value)
		state[key] = value
		scheduleSave()
	end)
end

local function smallButton(parent, text, position, size)
	local btn = create("TextButton", {
		Position = position,
		Size = size,
		BackgroundColor3 = THEME.SurfaceLight,
		AutoButtonColor = false,
		Text = text,
		TextColor3 = THEME.SubText,
		TextSize = 12,
		Font = FONT_BOLD,
		Parent = parent,
	}, { corner(6) })
	hoverButton(btn, THEME.SurfaceLight)
	return btn
end

local function horizontalRow(parent, y, height, alignment)
	return create("Frame", {
		Position = UDim2.new(0, 14, 0, y),
		Size = UDim2.new(1, -28, 0, height),
		BackgroundTransparency = 1,
		Parent = parent,
	}, {
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = alignment or Enum.HorizontalAlignment.Left,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
end

-- سطر معلومات (اسم على اليمين وقيمة على اليسار)
local function statRow(parent, y, name)
	label(parent, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, y),
		Size = UDim2.new(0.55, -14, 0, 18),
		Text = name,
		TextColor3 = THEME.SubText,
		TextSize = 13,
		Font = FONT_REG,
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	return label(parent, {
		Position = UDim2.new(0, 14, 0, y),
		Size = UDim2.new(0.45, -14, 0, 18),
		Text = "—",
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
end

-----------------------------------------------------------
-- الإشعارات
-----------------------------------------------------------
local toastHolder = create("Frame", {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -16, 1, -16),
	Size = UDim2.new(0, 260, 1, -32),
	BackgroundTransparency = 1,
	ZIndex = 10,
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
local function notify(text, color)
	toastOrder += 1
	local toast = create("Frame", {
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = THEME.Surface,
		BackgroundTransparency = 1,
		LayoutOrder = toastOrder,
		Parent = toastHolder,
	}, { corner(10) })

	local toastStroke = stroke(THEME.Stroke, 1, 1)
	toastStroke.Parent = toast

	local bar = create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0, 4, 1, 0),
		BackgroundColor3 = color or THEME.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = toast,
	}, { corner(2) })

	local toastLabel = label(toast, {
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(1, -28, 1, 0),
		Text = text,
		TextTransparency = 1,
		TextSize = 13,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	tween(toast, 0.3, { BackgroundTransparency = 0.05 })
	tween(toastStroke, 0.3, { Transparency = 0.3 })
	tween(bar, 0.3, { BackgroundTransparency = 0 })
	tween(toastLabel, 0.3, { TextTransparency = 0 })

	task.delay(2.5, function()
		if not toast.Parent then return end
		tween(toast, 0.3, { BackgroundTransparency = 1 })
		tween(toastStroke, 0.3, { Transparency = 1 })
		tween(bar, 0.3, { BackgroundTransparency = 1 })
		tween(toastLabel, 0.3, { TextTransparency = 1 }).Completed:Wait()
		toast:Destroy()
	end)
end

local alertSound = create("Sound", {
	SoundId = CONFIG.AlertSound,
	Volume = 1,
	Parent = screenGui,
})

-----------------------------------------------------------
-- منطق الكرة
-----------------------------------------------------------
local ballCountLabel, nearestLabel -- تُنشأ لاحقاً في بطاقة المعلومات

local function outlineColor()
	return CONFIG.OutlineColors[state.colorIndex]
end

local function countBalls()
	local n = 0
	for _ in pairs(trackedBalls) do
		n += 1
	end
	return n
end

local function refreshBallCount()
	if ballCountLabel then
		ballCountLabel.Text = tostring(countBalls())
	end
end

local function restoreBall(part, props)
	if part.Parent then
		part.Size = props.Size
		part.Transparency = props.Transparency
		part.CanCollide = props.CanCollide
	end
end

local function restoreAll()
	for part, props in pairs(trackedBalls) do
		restoreBall(part, props)
	end
end

local function untrackBall(part)
	local props = trackedBalls[part]
	if not props then return end
	restoreBall(part, props)
	props.Conn:Disconnect()
	props.Box:Destroy()
	props.Esp:Destroy()
	props.Tracer:Destroy()
	trackedBalls[part] = nil
	refreshBallCount()
end

local function addBall(part)
	if not part:IsA("BasePart") or trackedBalls[part] then return end

	local props = {
		Size = part.Size,
		Transparency = part.Transparency,
		CanCollide = part.CanCollide,
		-- الكتلة الأصلية (قبل تكبير الهيتبوكس) لحساب قوة الكرة بدقة
		Mass = math.max(part.AssemblyMass, 0.01),
		Calib = Vector3.zero,
		LastVel = part.AssemblyLinearVelocity,
		LastVelTime = os.clock(),
	}

	-- إطار يوضّح حدود الهيتبوكس
	props.Box = create("SelectionBox", {
		Adornee = part,
		Color3 = outlineColor(),
		LineThickness = 0.05,
		SurfaceTransparency = 1,
		Visible = false,
		Parent = playerGui,
	})

	-- مؤشر فوق الكرة: المسافة + السرعة
	props.Esp = create("BillboardGui", {
		Adornee = part,
		AlwaysOnTop = true,
		Size = UDim2.new(0, 150, 0, 26),
		StudsOffset = Vector3.new(0, 3, 0),
		Enabled = false,
		Parent = playerGui,
	})
	local espBg = create("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = THEME.Background,
		BackgroundTransparency = 0.25,
		Parent = props.Esp,
	}, { corner(8) })
	local espStroke = stroke(THEME.Accent, 1.5)
	espStroke.Parent = espBg
	accentize(espStroke, "Color", "Accent")
	props.EspLabel = label(props.Esp, {
		Size = UDim2.new(1, 0, 1, 0),
		Text = "⚽",
		TextSize = 13,
		ZIndex = 2,
	})

	-- خط التتبّع
	props.Tracer = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = outlineColor(),
		BorderSizePixel = 0,
		Visible = false,
		Parent = overlay,
	})

	props.Conn = part.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			untrackBall(part)
		end
	end)

	trackedBalls[part] = props
	refreshBallCount()
end

local function scanForBalls()
	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if descendant.Name == state.ballName then
			addBall(descendant)
		end
	end
end

local function rescan()
	for part in pairs(trackedBalls) do
		untrackBall(part)
	end
	scanForBalls()
	refreshBallCount()
end

connect(Workspace.DescendantAdded, function(descendant)
	if descendant.Name == state.ballName then
		addBall(descendant)
	end
end)

local function getRootPosition()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return root and root.Position
end

local function drawLine(frame, a, b)
	local delta = b - a
	frame.Size = UDim2.new(0, delta.Magnitude, 0, 2)
	frame.Position = UDim2.new(0, (a.X + b.X) / 2, 0, (a.Y + b.Y) / 2)
	frame.Rotation = math.deg(math.atan2(delta.Y, delta.X))
end

-----------------------------------------------------------
-- توقّع مسار الشوت (محاكاة فيزيائية)
-----------------------------------------------------------
local vizFolder = create("Folder", {
	Name = "MohammedTN_Prediction",
	Parent = Workspace.CurrentCamera,
})

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

-- نتجاهل الكرات واللاعبين ورسوماتنا عند فحص الاصطدام
local function refreshRayFilter()
	local list = { vizFolder }
	for part in pairs(trackedBalls) do
		table.insert(list, part)
	end
	for _, name in ipairs({ "Footballs", "Characters" }) do
		local folder = Workspace:FindFirstChild(name)
		if folder then
			table.insert(list, folder)
		end
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character then
			table.insert(list, plr.Character)
		end
	end
	rayParams.FilterDescendantsInstances = list
end

-- قوة الكرة (BodyForce / VectorForce) مقسومة على كتلتها الأصلية
local function ballForceAcceleration(part, props)
	local total = Vector3.zero
	for _, child in ipairs(part:GetChildren()) do
		if child:IsA("BodyForce") then
			total += child.Force
		elseif child:IsA("VectorForce") and child.Enabled then
			local force = child.Force
			if child.RelativeTo == Enum.ActuatorRelativeTo.Attachment0 and child.Attachment0 then
				force = child.Attachment0.WorldCFrame:VectorToWorldSpace(force)
			end
			total += force
		end
	end
	return total / props.Mass
end

local function modelAcceleration(part, props)
	return Vector3.new(0, -Workspace.Gravity, 0) + ballForceAcceleration(part, props)
end

-- معايرة تلقائية: نقارن التسارع الحقيقي بالمحسوب ونصحح الفرق
local function calibrate(part, props, now)
	local velocity = part.AssemblyLinearVelocity
	if velocity == props.LastVel then return end -- ما وصل تحديث جديد من السيرفر
	local dt = now - props.LastVelTime
	if dt > 0.005 and dt < 0.25 then
		local measured = (velocity - props.LastVel) / dt
		local residual = measured - modelAcceleration(part, props)
		local P = CONFIG.Prediction
		if residual.Magnitude < P.CalibrationLimit then
			props.Calib = props.Calib:Lerp(residual, P.CalibrationRate)
		else
			-- اصطدام أو ركلة: نخفف المعايرة بدل ما نخربها
			props.Calib *= 0.5
		end
	end
	props.LastVel = velocity
	props.LastVelTime = now
end

local function networkLag()
	local ok, ping = pcall(function()
		return player:GetNetworkPing()
	end)
	return ok and math.clamp(ping, 0, 0.5) or 0
end

-- يحاكي حركة الكرة ويرجع نقاط المسار والأحداث المهمة
-- options: { NoLag = true, Duration = ثواني } (للمقارنة مع المسار الحقيقي)
local function simulate(part, props, rootPos, options)
	options = options or {}
	local P = CONFIG.Prediction
	local step = P.Step
	local duration = options.Duration or state.predictTime
	local radius = math.min(props.Size.X, props.Size.Y, props.Size.Z) / 2
	local accel = modelAcceleration(part, props)
	if state.predictCalibrate then
		accel += props.Calib
	end

	-- Position / Velocity: نحاكي شوت افتراضي (مساعد التسديد)
	local pos = options.Position or part.Position
	local vel = options.Velocity or part.AssemblyLinearVelocity

	-- تعويض البنق: الكرة الحقيقية متقدمة عن اللي نشوفه
	if state.predictLag and not options.NoLag and not options.Velocity then
		local lag = networkLag()
		pos += vel * lag + 0.5 * accel * lag * lag
		vel += accel * lag
	end

	-- الكرة على الأرض وتتدحرج: نلغي الجاذبية باتجاه الأرض ونرفعها شوي
	-- (فحص الاصطدام يتجاهل السطح اللي الكرة لامسته من البداية)
	local ground = Workspace:Raycast(pos, Vector3.new(0, -(radius + 0.35), 0), rayParams)
	if ground and ground.Normal.Y > 0.6 and vel:Dot(ground.Normal) < P.SettleSpeed then
		local normal = ground.Normal
		accel -= normal * accel:Dot(normal)
		vel -= normal * math.min(vel:Dot(normal), 0)
		pos = ground.Position + normal * (radius + 0.05)
	end

	local physical = part.CurrentPhysicalProperties
	local elasticity = physical and physical.Elasticity or 0.5
	local friction = physical and physical.Friction or 0.3

	local result = {
		Points = { pos },
		Times = { 0 },     -- وقت كل نقطة (لحساب دخول المرمى ومقارنة الدقة)
		Radius = radius,
		Bounces = {},
		Landing = nil,    -- { Position, Time, Normal }
		Closest = nil,    -- { Position, Time, Distance }
		Start = pos,
	}

	local t = 0
	local stepIndex = 0
	local bounces = 0

	local function checkClosest(point, time)
		if not rootPos then return end
		local distance = (point - rootPos).Magnitude
		if not result.Closest or distance < result.Closest.Distance then
			result.Closest = { Position = point, Time = time, Distance = distance }
		end
	end

	checkClosest(pos, 0)

	local function addPoint(point, time)
		table.insert(result.Points, point)
		table.insert(result.Times, time)
	end

	while t < duration do
		local nextVel = vel + accel * step
		local move = (vel + nextVel) * 0.5 * step
		local hit = move.Magnitude > 1e-4 and Workspace:Spherecast(pos, radius, move, rayParams)

		if hit then
			local fraction = math.clamp(hit.Distance / move.Magnitude, 0, 1)
			pos += move.Unit * hit.Distance
			vel += accel * step * fraction
			t += step * fraction
			addPoint(pos, t)
			checkClosest(pos, t)

			local normal = hit.Normal
			if not result.Landing and normal.Y > 0.6 then
				result.Landing = { Position = pos - normal * radius, Time = t, Normal = normal }
			end
			table.insert(result.Bounces, pos - normal * radius)

			if not state.predictBounces or bounces >= P.MaxBounces then
				break
			end

			-- ارتداد: نعكس السرعة العمودية ونخفف الأفقية بالاحتكاك
			local vn = vel:Dot(normal)
			if vn < 0 then
				local normalVel = normal * vn
				local tangentVel = vel - normalVel
				vel = tangentVel * (1 - math.clamp(friction, 0, 1) * 0.25) - normalVel * elasticity
			end
			if normal.Y > 0.6 and math.abs(vel:Dot(normal)) < P.SettleSpeed then
				-- الكرة صارت تتدحرج: نكمل الحساب على الأرض (الشوتات الأرضية)
				vel -= normal * vel:Dot(normal)
				accel -= normal * accel:Dot(normal)
				pos += normal * 0.05
				if vel.Magnitude < 1 then
					break -- الكرة وقفت
				end
			else
				pos += normal * 0.02
			end
			bounces += 1
		else
			pos += move
			vel = nextVel
			t += step
			stepIndex += 1
			if stepIndex % P.PointEvery == 0 then
				addPoint(pos, t)
			end
			checkClosest(pos, t)
		end
	end

	addPoint(pos, t)
	return result
end

-- مخزن قطع الرسم (نعيد استخدامها بدل ما ننشئ قطع كل فريم)
local pool = { Segment = {}, Bounce = {}, Landing = {}, Closest = {}, Goal = {}, Origin = {} }
local used = { Segment = 0, Bounce = 0, Landing = 0, Closest = 0, Goal = 0, Origin = 0 }

local function vizPart(shape, size)
	return create("Part", {
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
		Locked = true,
		Material = Enum.Material.Neon,
		Shape = shape,
		Size = size,
		Transparency = 1,
		Parent = vizFolder,
	})
end

local function vizLabel(adornee, offset)
	local billboard = create("BillboardGui", {
		Adornee = adornee,
		-- ما نرسمها فوق كل شي عشان ما تغطي الكرة
		AlwaysOnTop = false,
		LightInfluence = 0,
		MaxDistance = 220,
		Size = UDim2.new(0, 96, 0, 20),
		StudsOffset = offset,
		Enabled = false,
		Parent = vizFolder,
	})
	create("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = THEME.Background,
		BackgroundTransparency = 0.35,
		Parent = billboard,
	}, { corner(6) })
	local text = label(billboard, {
		Size = UDim2.new(1, 0, 1, 0),
		Text = "",
		TextSize = 11,
		ZIndex = 2,
	})
	return billboard, text
end

local factories = {
	Segment = function()
		return { Part = vizPart(Enum.PartType.Block, Vector3.new(0.18, 0.18, 1)) }
	end,
	Bounce = function()
		return { Part = vizPart(Enum.PartType.Ball, Vector3.new(0.6, 0.6, 0.6)) }
	end,
	Landing = function()
		local part = vizPart(Enum.PartType.Cylinder, Vector3.new(0.15, 4, 4))
		local billboard, text = vizLabel(part, Vector3.new(0, 2.5, 0))
		return { Part = part, Billboard = billboard, Text = text }
	end,
	Closest = function()
		local part = vizPart(Enum.PartType.Ball, Vector3.new(1.1, 1.1, 1.1))
		local billboard, text = vizLabel(part, Vector3.new(0, 2, 0))
		return { Part = part, Billboard = billboard, Text = text }
	end,
	Goal = function()
		local part = vizPart(Enum.PartType.Block, Vector3.new(2.4, 2.4, 0.15))
		local billboard, text = vizLabel(part, Vector3.new(0, 2.4, 0))
		return { Part = part, Billboard = billboard, Text = text }
	end,
	Origin = function()
		return { Part = vizPart(Enum.PartType.Cylinder, Vector3.new(0.12, 1.6, 1.6)) }
	end,
}

local function take(kind)
	used[kind] += 1
	local item = pool[kind][used[kind]]
	if not item then
		item = factories[kind]()
		pool[kind][used[kind]] = item
	end
	return item
end

local function hideUnused()
	for kind, list in pairs(pool) do
		for i = used[kind] + 1, #list do
			local item = list[i]
			item.Part.Transparency = 1
			if item.Billboard then
				item.Billboard.Enabled = false
			end
		end
		used[kind] = 0
	end
end

local function drawSegment(a, b, color, transparency, thickness)
	local length = (b - a).Magnitude
	if length < 0.05 then return end
	thickness = thickness or 0.18
	local seg = take("Segment").Part
	seg.Size = Vector3.new(thickness, thickness, length)
	seg.CFrame = CFrame.lookAt((a + b) / 2, b)
	seg.Color = color
	seg.Transparency = transparency
end

local function drawPrediction(result, color, showLabels, ballPos, clearRadius)
	local points = result.Points
	local count = #points
	for i = 1, count - 1 do
		local a, b = points[i], points[i + 1]
		-- ما نرسم داخل الكرة نفسها عشان تبان واضحة
		local insideBall = (a - ballPos).Magnitude < clearRadius and (b - ballPos).Magnitude < clearRadius
		if not insideBall then
			-- يبهت الخط كل ما بعد في المستقبل
			drawSegment(a, b, color, 0.1 + 0.6 * (i / count))
		end
	end

	if state.predictBounces then
		for _, point in ipairs(result.Bounces) do
			local bounce = take("Bounce").Part
			bounce.CFrame = CFrame.new(point)
			bounce.Color = color
			bounce.Transparency = 0.25
		end
	end

	if state.predictLanding and result.Landing then
		local marker = take("Landing")
		local landing = result.Landing
		marker.Part.CFrame = CFrame.new(landing.Position + landing.Normal * 0.08) * CFrame.Angles(0, 0, math.pi / 2)
		marker.Part.Color = color
		marker.Part.Transparency = 0.35
		marker.Text.Text = string.format("⏱ %.2f ث", landing.Time)
		marker.Text.TextColor3 = color
		marker.Billboard.Enabled = showLabels
	end

	local closest = result.Closest
	if state.predictClosest and closest and closest.Time > 0.05
		and (closest.Position - ballPos).Magnitude > clearRadius
	then
		local marker = take("Closest")
		marker.Part.CFrame = CFrame.new(closest.Position)
		marker.Part.Color = THEME.Warning
		marker.Part.Transparency = 0.3
		marker.Text.Text = string.format("↔ %.1f م • %.2f ث", closest.Distance, closest.Time)
		marker.Text.TextColor3 = THEME.Warning
		marker.Billboard.Enabled = showLabels
	end
end

-----------------------------------------------------------
-- الحلقة الرئيسية
-----------------------------------------------------------
local predictionLabels = {} -- تُنشأ في صفحة التوقّع
local statLabels = {}       -- تُنشأ في صفحة التحليل

-----------------------------------------------------------
-- التحليل: المرمى + الإحصائيات + آخر شوت
-----------------------------------------------------------
local UP = Vector3.new(0, 1, 0)
local goalCache = nil

-- المرمى محفوظ كـ { x, y, z, nx, nz }: نقطة نص خط المرمى + اتجاه الملعب
local function getGoals()
	if goalCache then return goalCache end
	goalCache = {}
	for _, g in ipairs(state.goals) do
		if type(g) == "table" and #g >= 5 then
			local normal = Vector3.new(g[4], 0, g[5])
			if normal.Magnitude > 0.1 then
				normal = normal.Unit
				table.insert(goalCache, {
					Origin = Vector3.new(g[1], g[2], g[3]),
					Normal = normal,
					Right = UP:Cross(normal),
				})
			end
		end
	end
	return goalCache
end

-- أول مرة يقطع فيها المسار خط المرمى (من جهة الملعب)
local function findGoalCrossing(result)
	local points, times = result.Points, result.Times
	local best
	for _, goal in ipairs(getGoals()) do
		for i = 1, #points - 1 do
			local a, b = points[i], points[i + 1]
			local da = (a - goal.Origin):Dot(goal.Normal)
			local db = (b - goal.Origin):Dot(goal.Normal)
			if da > 0 and db <= 0 then
				local alpha = da / (da - db)
				local point = a:Lerp(b, alpha)
				local time = times[i] + (times[i + 1] - times[i]) * alpha
				local lateral = (point - goal.Origin):Dot(goal.Right)
				local height = point.Y - goal.Origin.Y
				-- نعرض الشوتات اللي تمر قريب من المرمى بس
				if math.abs(lateral) <= state.goalWidth and height <= state.goalHeight * 2 then
					local inside = math.abs(lateral) <= state.goalWidth / 2 + result.Radius
						and height >= -result.Radius
						and height <= state.goalHeight + result.Radius
					if not best or time < best.Time then
						best = { Position = point, Time = time, Inside = inside, Goal = goal }
					end
				end
				break
			end
		end
	end
	return best
end

local function drawGoalCrossing(crossing, showLabels)
	local marker = take("Goal")
	local color = crossing.Inside and THEME.Danger or THEME.Warning
	marker.Part.CFrame = CFrame.lookAt(crossing.Position, crossing.Position + crossing.Goal.Normal)
	marker.Part.Color = color
	marker.Part.Transparency = 0.3
	marker.Text.Text = string.format(crossing.Inside and "🥅 هدف • %.2f ث" or "↗ برّا • %.2f ث", crossing.Time)
	marker.Text.TextColor3 = color
	marker.Billboard.Enabled = showLabels
end

local function drawGoalFrames()
	local white = Color3.new(1, 1, 1)
	for _, goal in ipairs(getGoals()) do
		local half = goal.Right * (state.goalWidth / 2)
		local top = UP * state.goalHeight
		local left, right = goal.Origin - half, goal.Origin + half
		drawSegment(left, left + top, white, 0.45, 0.25)
		drawSegment(right, right + top, white, 0.45, 0.25)
		drawSegment(left + top, right + top, white, 0.45, 0.25)
		drawSegment(left, right, white, 0.6, 0.15)
	end
end

-- إحصائيات الشوتات
local stats = { Shots = 0, MaxSpeed = 0, TotalSpeed = 0, LastSpeed = 0, LastError = nil }
local shotOrigins = {}
local lastShot = nil -- { Ball, StartTime, Predicted, Actual, ActualTimes, LastSample, Done }

local function refreshStats()
	if not statLabels.Shots then return end
	statLabels.Shots.Text = tostring(stats.Shots)
	statLabels.Max.Text = stats.Shots > 0 and string.format("%.1f", stats.MaxSpeed) or "—"
	statLabels.Avg.Text = stats.Shots > 0 and string.format("%.1f", stats.TotalSpeed / stats.Shots) or "—"
	statLabels.Last.Text = stats.Shots > 0 and string.format("%.1f", stats.LastSpeed) or "—"
	statLabels.Error.Text = stats.LastError and string.format("%.2f م", stats.LastError) or "—"
end

-- مكان الكرة المتوقع في وقت معيّن
local function pointAtTime(points, times, t)
	for i = 2, #points do
		if times[i] >= t then
			local t0, t1 = times[i - 1], times[i]
			local alpha = t1 > t0 and (t - t0) / (t1 - t0) or 0
			return points[i - 1]:Lerp(points[i], alpha)
		end
	end
	return nil
end

-- نقارن المسار الحقيقي بالمتوقع ونحسب متوسط الخطأ
local function finishShot()
	if not lastShot or lastShot.Done then return end
	lastShot.Done = true
	local predicted = lastShot.Predicted
	local total, count = 0, 0
	for i = 2, #lastShot.Actual do
		local expected = pointAtTime(predicted.Points, predicted.Times, lastShot.ActualTimes[i])
		if expected then
			total += (expected - lastShot.Actual[i]).Magnitude
			count += 1
		end
	end
	if count > 0 then
		stats.LastError = total / count
		refreshStats()
	end
end

-- تعلّم أسلوب الشوت: نحفظ سرعة الكرة بالنسبة لاتجاه اللاعب (قدام / فوق / يمين)
local kickHistory = {}   -- [UserId] = { {F, U, R}, ... }
local globalHistory = {}

local function flatForward(vector)
	local flat = Vector3.new(vector.X, 0, vector.Z)
	return flat.Magnitude > 0.05 and flat.Unit or nil
end

local function toLocalShot(forward, velocity)
	local right = forward:Cross(UP)
	return { F = velocity:Dot(forward), U = velocity.Y, R = velocity:Dot(right) }
end

local function fromLocalShot(forward, shot)
	local right = forward:Cross(UP)
	return forward * shot.F + UP * shot.U + right * shot.R
end

local function averageShot(list, count)
	local n = math.min(#list, count)
	if n == 0 then return nil end
	local f, u, r = 0, 0, 0
	for i = #list - n + 1, #list do
		f += list[i].F
		u += list[i].U
		r += list[i].R
	end
	return { F = f / n, U = u / n, R = r / n }
end

local function learnedShot(userId)
	local own = kickHistory[userId]
	return (own and averageShot(own, CONFIG.Analysis.LearnCount))
		or averageShot(globalHistory, 10)
end

local function rootOf(plr)
	local character = plr.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

-- أقرب لاعب للكرة لحظة الركلة = اللي سددها
local function findKicker(position)
	local best, bestRoot, bestDistance = nil, nil, CONFIG.Analysis.KickerRange
	for _, plr in ipairs(Players:GetPlayers()) do
		local root = rootOf(plr)
		if root then
			local distance = (root.Position - position).Magnitude
			if distance < bestDistance then
				best, bestRoot, bestDistance = plr, root, distance
			end
		end
	end
	return best, bestRoot
end

local learnLabel -- يُنشأ في صفحة التحليل

local function refreshLearnLabel()
	if not learnLabel then return end
	local own = kickHistory[player.UserId]
	learnLabel.Text = string.format("شوتاتك: %d  •  كل الشوتات: %d", own and #own or 0, #globalHistory)
end

local function learnKick(part, velocity)
	-- الكرة تحركت شوي بعد الركلة، فنرجع لمكانها قبل فريم تقريباً
	local kicker, root = findKicker(part.Position - velocity / 60)
	if not kicker then return end
	local forward = flatForward(root.CFrame.LookVector)
	if not forward then return end
	local shot = toLocalShot(forward, velocity)
	local list = kickHistory[kicker.UserId] or {}
	kickHistory[kicker.UserId] = list
	table.insert(list, shot)
	table.insert(globalHistory, shot)
	if #list > 10 then table.remove(list, 1) end
	if #globalHistory > 30 then table.remove(globalHistory, 1) end
	refreshLearnLabel()
end

local function onKick(part, props, speed, now)
	learnKick(part, part.AssemblyLinearVelocity)
	finishShot()
	stats.Shots += 1
	stats.TotalSpeed += speed
	stats.LastSpeed = speed
	stats.MaxSpeed = math.max(stats.MaxSpeed, speed)
	refreshStats()

	table.insert(shotOrigins, part.Position - Vector3.new(0, props.Size.Y / 2, 0))
	if #shotOrigins > CONFIG.Analysis.MaxOrigins then
		table.remove(shotOrigins, 1)
	end

	-- نحفظ التوقّع لحظة الركلة (بدون تعويض البنق لأننا نقارن باللي نشوفه)
	lastShot = {
		Ball = part,
		StartTime = now,
		Predicted = simulate(part, props, nil, { NoLag = true, Duration = CONFIG.Analysis.RecordTime }),
		Actual = { part.Position },
		ActualTimes = { 0 },
		LastSample = now,
		Done = false,
	}
end

local function updateShotRecording(now)
	if not lastShot or lastShot.Done then return end
	local ball = lastShot.Ball
	local elapsed = now - lastShot.StartTime
	if not ball.Parent or elapsed > CONFIG.Analysis.RecordTime then
		finishShot()
	elseif now - lastShot.LastSample >= 1 / 30 then
		lastShot.LastSample = now
		table.insert(lastShot.Actual, ball.Position)
		table.insert(lastShot.ActualTimes, elapsed)
	end
end

local function drawReplay()
	if not lastShot then return end
	local actual = lastShot.Actual
	for i = 1, #actual - 1 do
		drawSegment(actual[i], actual[i + 1], Color3.new(1, 1, 1), 0.15, 0.14)
	end
	local predicted = lastShot.Predicted.Points
	for i = 1, #predicted - 1 do
		drawSegment(predicted[i], predicted[i + 1], outlineColor(), 0.55, 0.12)
	end
end

-- يرسم مسار شوت افتراضي حسب أسلوب اللاعب واتجاهه
local function drawAssistPath(part, props, plr, forward, color, showLabels)
	local shot = learnedShot(plr.UserId)
	if not shot then return false end
	local result = simulate(part, props, nil, {
		Position = part.Position,
		Velocity = fromLocalShot(forward, shot),
	})
	local points = result.Points
	for i = 1, #points - 1 do
		drawSegment(points[i], points[i + 1], color, 0.2 + 0.5 * (i / #points), 0.14)
	end
	local crossing = state.goalEntry and findGoalCrossing(result)
	if crossing then
		drawGoalCrossing(crossing, showLabels)
	end
	return true
end

local function sameTeam(a, b)
	return a.Team ~= nil and a.Team == b.Team
end

local function drawShotAssists(camera)
	if not (state.shotAssist or state.opponentPredict) then return end
	local A = CONFIG.Analysis

	-- مين معه الكرة: أقرب كرة بطيئة لكل لاعب
	local possessions = {}
	for part, props in pairs(trackedBalls) do
		if part.Parent and part.AssemblyLinearVelocity.Magnitude < A.PossessionSpeed then
			for _, plr in ipairs(Players:GetPlayers()) do
				local root = rootOf(plr)
				if root then
					local distance = (root.Position - part.Position).Magnitude
					local current = possessions[plr]
					if distance < A.PossessionRange and (not current or distance < current.Distance) then
						possessions[plr] = { Part = part, Props = props, Root = root, Distance = distance }
					end
				end
			end
		end
	end

	local mine = possessions[player]
	if state.shotAssist and mine then
		local look = state.assistCamera and camera.CFrame.LookVector or mine.Root.CFrame.LookVector
		local forward = flatForward(look)
		if forward then
			drawAssistPath(mine.Part, mine.Props, player, forward, THEME.Success, state.predictLabels)
		end
	end

	if state.opponentPredict then
		local count = 0
		for plr, info in pairs(possessions) do
			if count >= A.MaxOpponents then break end
			if plr ~= player and not sameTeam(plr, player) then
				local forward = flatForward(info.Root.CFrame.LookVector)
				if forward and drawAssistPath(info.Part, info.Props, plr, forward, THEME.Danger, false) then
					count += 1
				end
			end
		end
	end
end

local function drawOrigins()
	for _, point in ipairs(shotOrigins) do
		local origin = take("Origin").Part
		origin.CFrame = CFrame.new(point + Vector3.new(0, 0.07, 0)) * CFrame.Angles(0, 0, math.pi / 2)
		origin.Color = THEME.Warning
		origin.Transparency = 0.4
	end
end

local lastInfoUpdate = 0
local lastFilterUpdate = 0
local alertActive = false

connect(RunService.RenderStepped, function()
	local camera = Workspace.CurrentCamera
	local rootPos = getRootPosition()
	local nearest = math.huge
	local now = os.clock()
	local pulse = (math.sin(now * 5) + 1) / 2
	local P = CONFIG.Prediction

	if vizFolder.Parent ~= camera then
		vizFolder.Parent = camera
	end
	if now - lastFilterUpdate > 0.5 then
		lastFilterUpdate = now
		refreshRayFilter()
	end

	local moving = {}

	for part, props in pairs(trackedBalls) do
		if not part.Parent then
			props.Tracer.Visible = false
			continue
		end

		local distance = rootPos and (part.Position - rootPos).Magnitude
		if distance then
			nearest = math.min(nearest, distance)
		end

		-- تطبيق الهيتبوكس
		if state.enabled then
			local mult = state.size
			if state.autoSize and distance then
				mult = math.min(mult * (1 + distance / CONFIG.AutoSizeRange), CONFIG.MaxSize * 1.5)
			end
			local targetSize = props.Size * mult * Vector3.new(state.axisX, state.axisY, state.axisZ)
			local targetTransparency = state.showHitbox and state.transparency or props.Transparency

			if part.Size ~= targetSize then
				part.Size = targetSize
			end
			if part.Transparency ~= targetTransparency then
				part.Transparency = targetTransparency
			end
			if part.CanCollide then
				part.CanCollide = false
			end
		end

		-- الإطار + النبض
		props.Box.Visible = state.enabled and state.outline
		if props.Box.Visible then
			if state.pulse then
				props.Box.LineThickness = 0.03 + 0.06 * pulse
				props.Box.Transparency = 0.5 * (1 - pulse)
			else
				props.Box.LineThickness = 0.05
				props.Box.Transparency = 0
			end
		end

		-- المؤشر: المسافة والسرعة
		local velocity = part.AssemblyLinearVelocity
		props.Esp.Enabled = state.esp
		if state.esp then
			-- المؤشر دايماً فوق الكرة حتى لو الهيتبوكس كبير
			props.Esp.StudsOffset = Vector3.new(0, part.Size.Y / 2 + 1.5, 0)
			props.EspLabel.Text = string.format(
				"⚽ %s م  •  ⚡ %.0f",
				distance and string.format("%.1f", distance) or "—",
				velocity.Magnitude
			)
		end

		-- خط التتبّع
		local ballScreen = camera:WorldToViewportPoint(part.Position)
		local rootScreen = rootPos and camera:WorldToViewportPoint(rootPos)
		if state.tracer and rootScreen and ballScreen.Z > 0 and rootScreen.Z > 0 then
			props.Tracer.Visible = true
			drawLine(props.Tracer, Vector2.new(rootScreen.X, rootScreen.Y), Vector2.new(ballScreen.X, ballScreen.Y))
		else
			props.Tracer.Visible = false
		end

		-- كشف الشوت: زيادة مفاجئة في سرعة الكرة
		local speed = velocity.Magnitude
		local prevSpeed = props.PrevSpeed or speed
		props.PrevSpeed = speed
		if speed - prevSpeed > CONFIG.Analysis.KickJump
			and speed > CONFIG.Analysis.MinShotSpeed
			and now - (props.LastKick or 0) > 0.5
		then
			props.LastKick = now
			onKick(part, props, speed, now)
		end

		-- المعايرة تشتغل دايماً عشان تكون جاهزة لما تنطلق الكرة
		calibrate(part, props, now)

		if state.prediction and velocity.Magnitude > P.MinSpeed and (not distance or distance < P.MaxRange) then
			table.insert(moving, { Part = part, Props = props, Distance = distance or 0, Speed = velocity.Magnitude })
		end
	end

	-- توقّع المسار لأقرب الكرات المتحركة
	local focus
	if state.prediction then
		table.sort(moving, function(a, b)
			return a.Distance < b.Distance
		end)
		local color = outlineColor()
		for i = 1, math.min(#moving, P.MaxBalls) do
			local entry = moving[i]
			local result = simulate(entry.Part, entry.Props, rootPos)
			local part = entry.Part
			-- الكتابات بس للكرة الأقرب عشان ما تزحم الشاشة
			local showLabels = state.predictLabels and i == 1
			local clearRadius = math.max(part.Size.X, part.Size.Y, part.Size.Z) * 0.6 + 0.5
			drawPrediction(result, color, showLabels, part.Position, clearRadius)

			local crossing = state.goalEntry and findGoalCrossing(result)
			if crossing then
				drawGoalCrossing(crossing, showLabels)
			end
			if i == 1 then
				focus = { Entry = entry, Result = result, Crossing = crossing }
			end
		end
	end

	updateShotRecording(now)
	if state.goalEntry and state.showGoalFrame then
		drawGoalFrames()
	end
	if state.showReplay then
		drawReplay()
	end
	if state.showOrigins then
		drawOrigins()
	end
	drawShotAssists(camera)
	hideUnused()

	-- تنبيه قرب الكرة
	if state.alert and nearest <= state.alertDistance then
		if not alertActive then
			alertActive = true
			pcall(function() alertSound:Play() end)
			notify("⚠️ الكرة قريبة منك!", THEME.Danger)
		end
	elseif nearest > state.alertDistance + 3 then
		alertActive = false
	end

	-- تحديث المعلومات
	if now - lastInfoUpdate > 0.15 then
		lastInfoUpdate = now
		if nearestLabel then
			nearestLabel.Text = nearest < math.huge and string.format("%.1f م", nearest) or "—"
		end
		if predictionLabels.Speed then
			if focus then
				local result = focus.Result
				predictionLabels.Speed.Text = string.format("%.1f", focus.Entry.Speed)
				predictionLabels.Landing.Text = result.Landing and string.format("%.2f ث", result.Landing.Time) or "—"
				predictionLabels.Closest.Text = result.Closest
					and string.format("%.1f م (%.2f ث)", result.Closest.Distance, result.Closest.Time)
					or "—"
				predictionLabels.Calib.Text = string.format("%.1f", focus.Entry.Props.Calib.Magnitude)
				local crossing = focus.Crossing
				predictionLabels.Goal.Text = crossing
					and string.format(crossing.Inside and "هدف بعد %.2f ث" or "برّا (%.2f ث)", crossing.Time)
					or (#getGoals() == 0 and "حدّد المرمى من تبويب التحليل" or "ما تروح للمرمى")
			else
				predictionLabels.Speed.Text = "لا توجد كرة متحركة"
				predictionLabels.Landing.Text = "—"
				predictionLabels.Closest.Text = "—"
				predictionLabels.Calib.Text = "—"
				predictionLabels.Goal.Text = "—"
			end
			predictionLabels.Ping.Text = string.format("%d ms", math.floor(networkLag() * 1000 + 0.5))
		end
	end
end)

-----------------------------------------------------------
-- صفحة 1: الهيتبوكس
-----------------------------------------------------------
newPage(TAB_NAMES[1])

local function statusSuffix()
	return "  •  اختصار: " .. state.quickKey
end

local enableCard = card(54)
local statusText = cardTitle(enableCard, "تفعيل الهيتبوكس", "الحالة: متوقف" .. statusSuffix())

local function refreshStatus()
	statusText.Text = (state.enabled and "الحالة: يعمل ✓" or "الحالة: متوقف") .. statusSuffix()
	statusText.TextColor3 = state.enabled and THEME.Success or THEME.SubText
end

local enableSwitch = makeSwitch(enableCard, state.enabled, function(value)
	state.enabled = value
	refreshStatus()
	if value then
		notify("تم تفعيل الهيتبوكس ✓", THEME.Success)
	else
		restoreAll()
		notify("تم إيقاف الهيتبوكس", THEME.Danger)
	end
end)

-- الحجم + أحجام سريعة
local sizeCard = card(118)
cardHeading(sizeCard, "حجم الهيتبوكس")

local sizeSlider = makeSlider(sizeCard, 48, CONFIG.MinSize, CONFIG.MaxSize, 0.1, state.size, "x%.1f", function(value)
	state.size = value
	scheduleSave()
end)

local resetBtn = smallButton(sizeCard, "إعادة", UDim2.new(0, 80, 0, 10), UDim2.new(0, 56, 0, 24))
resetBtn.MouseButton1Click:Connect(function()
	sizeSlider.set(1, true)
	notify("تمت إعادة الحجم إلى الافتراضي", THEME.Accent2)
end)

local presetRow = horizontalRow(sizeCard, 74, 30)
local presetCount = #CONFIG.SizePresets
for i, preset in ipairs(CONFIG.SizePresets) do
	local btn = smallButton(
		presetRow,
		"x" .. preset,
		UDim2.new(),
		UDim2.new(1 / presetCount, -8 * (presetCount - 1) / presetCount, 1, 0)
	)
	btn.LayoutOrder = i
	btn.TextSize = 13
	btn.MouseButton1Click:Connect(function()
		sizeSlider.set(preset, true)
	end)
end

switchCard("حجم تلقائي حسب المسافة", "يكبر الهيتبوكس كلما ابتعدت الكرة", "autoSize")

sectionHeader("📐 تكبير كل اتجاه")

local axisCard = card(196)
local axisSliders = {}
local axes = {
	{ key = "axisX", name = "العرض (X)" },
	{ key = "axisY", name = "الارتفاع (Y)" },
	{ key = "axisZ", name = "الطول (Z)" },
}
for i, axis in ipairs(axes) do
	local y = 46 + (i - 1) * 60
	cardHeading(axisCard, axis.name, y - 36)
	axisSliders[i] = makeSlider(axisCard, y, 0.25, 3, 0.05, state[axis.key], "x%.2f", function(value)
		state[axis.key] = value
		scheduleSave()
	end)
end

local axisResetCard = card(44)
local axisResetBtn = smallButton(axisResetCard, "إعادة الاتجاهات إلى x1", UDim2.new(0, 14, 0, 8), UDim2.new(1, -28, 0, 28))
axisResetBtn.TextSize = 13
axisResetBtn.MouseButton1Click:Connect(function()
	for _, slider in ipairs(axisSliders) do
		slider.set(1, true)
	end
end)

-----------------------------------------------------------
-- صفحة 2: التوقّع
-----------------------------------------------------------
newPage(TAB_NAMES[2])

switchCard("توقّع مسار الشوت", "خط ثلاثي الأبعاد يوضح وين رح تروح الكرة", "prediction")

local liveCard = card(166)
cardHeading(liveCard, "📊 قراءة مباشرة")
predictionLabels.Speed = statRow(liveCard, 38, "سرعة الكرة")
predictionLabels.Landing = statRow(liveCard, 58, "تنزل بعد")
predictionLabels.Goal = statRow(liveCard, 78, "دخول المرمى")
predictionLabels.Closest = statRow(liveCard, 98, "أقرب مرور منك")
predictionLabels.Calib = statRow(liveCard, 118, "تصحيح المعايرة")
predictionLabels.Ping = statRow(liveCard, 138, "البنق")

sliderCard("مدة التوقّع (ثانية)", "predictTime", 0.5, 5, 0.25, "%.2f")

sectionHeader("🔬 الدقة")
switchCard("حساب الارتداد", "يحسب ارتداد الكرة من الأرض والقائم والعارضة", "predictBounces")
switchCard("تعويض البنق", "يقدّم الكرة لمكانها الحقيقي في السيرفر", "predictLag")
switchCard("معايرة تلقائية", "يتعلم انحناء الكرة من حركتها ويصحح المسار", "predictCalibrate")

sectionHeader("📍 العلامات")
switchCard("مكان النزول", "دائرة مكان نزول الكرة مع الوقت", "predictLanding")
switchCard("أقرب نقطة لك", "وين رح تمر الكرة أقرب شي منك", "predictClosest")
switchCard("إظهار الكتابات", "الوقت والمسافة فوق العلامات", "predictLabels")

-----------------------------------------------------------
-- صفحة 3: التحليل
-----------------------------------------------------------
newPage(TAB_NAMES[3])

sectionHeader("🥅 المرمى")
switchCard("نقطة دخول المرمى", "وين ومتى الكرة رح تدخل المرمى", "goalEntry")
switchCard("إظهار حدود المرمى", "خطوط توضّح المرمى اللي حفظته", "showGoalFrame")

local goalCard = card(124)
cardHeading(goalCard, "حفظ المرمى")
label(goalCard, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 32),
	Size = UDim2.new(1, -28, 0, 30),
	Text = "قف على خط المرمى بالنص، ووجهك للملعب، واضغط حفظ",
	TextColor3 = THEME.SubText,
	TextSize = 12,
	Font = FONT_REG,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Right,
})
local goalStatus = label(goalCard, {
	Position = UDim2.new(0, 14, 0, 10),
	Size = UDim2.new(0, 120, 0, 20),
	Text = "",
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
})

local function refreshGoalStatus()
	goalCache = nil
	local n = #getGoals()
	goalStatus.Text = "المحفوظ: " .. n .. " / 2"
	goalStatus.TextColor3 = n > 0 and THEME.Success or THEME.SubText
end

local function saveGoal(index)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		notify("ما لقيت شخصيتك", THEME.Danger)
		return
	end
	local look = root.CFrame.LookVector
	local facing = Vector3.new(look.X, 0, look.Z)
	if facing.Magnitude < 0.1 then return end
	facing = facing.Unit
	local ground = Workspace:Raycast(root.Position, Vector3.new(0, -25, 0), rayParams)
	local base = ground and ground.Position or (root.Position - Vector3.new(0, 3, 0))
	-- ما نترك فراغ في القائمة (عشان JSON يحفظها صح)
	index = math.min(index, #state.goals + 1)
	state.goals[index] = { base.X, base.Y, base.Z, facing.X, facing.Z }
	scheduleSave()
	refreshGoalStatus()
	notify("تم حفظ المرمى " .. index .. " ✓", THEME.Success)
end

local goalRow = horizontalRow(goalCard, 80, 30)
for i, info in ipairs({
	{ "حفظ مرمى 1", function() saveGoal(1) end },
	{ "حفظ مرمى 2", function() saveGoal(2) end },
	{ "مسح", function()
		state.goals = {}
		scheduleSave()
		refreshGoalStatus()
		notify("تم مسح المرامي", THEME.Accent2)
	end },
}) do
	local btn = smallButton(goalRow, info[1], UDim2.new(), UDim2.new(1 / 3, -6, 1, 0))
	btn.LayoutOrder = i
	btn.MouseButton1Click:Connect(info[2])
end
refreshGoalStatus()

sliderCard("عرض المرمى", "goalWidth", 6, 50, 0.5, "%.1f")
sliderCard("ارتفاع المرمى", "goalHeight", 3, 20, 0.5, "%.1f")

sectionHeader("📈 إحصائيات الشوتات")
local statsCard = card(156)
statLabels.Shots = statRow(statsCard, 12, "عدد الشوتات")
statLabels.Max = statRow(statsCard, 34, "أقوى شوت")
statLabels.Avg = statRow(statsCard, 56, "متوسط السرعة")
statLabels.Last = statRow(statsCard, 78, "آخر شوت")
statLabels.Error = statRow(statsCard, 100, "خطأ التوقّع (متوسط)")
local resetStatsBtn = smallButton(statsCard, "تصفير الإحصائيات", UDim2.new(0, 14, 0, 122), UDim2.new(1, -28, 0, 26))
resetStatsBtn.MouseButton1Click:Connect(function()
	stats = { Shots = 0, MaxSpeed = 0, TotalSpeed = 0, LastSpeed = 0, LastError = nil }
	table.clear(shotOrigins)
	lastShot = nil
	refreshStats()
end)
refreshStats()

sectionHeader("🔁 آخر شوت")
switchCard("عرض آخر شوت", "الحقيقي (أبيض) جنب المتوقّع (ملوّن)", "showReplay")
switchCard("أماكن التسديد", "علامة مكان آخر 20 شوت", "showOrigins")

sectionHeader("🧠 مساعد التسديد")
switchCard("خط شوتك المتوقّع", "لما الكرة عندك: وين رح تروح إذا سددت (أخضر)", "shotAssist")
switchCard("حسب اتجاه الكاميرا", "شغّله إذا الشوت في الماب يمشي مع الكاميرا", "assistCamera")
switchCard("توقّع شوت الخصم", "تقريبي: من اتجاهه وأسلوب شوتاته (أحمر)", "opponentPredict")

local learnCard = card(58)
label(learnCard, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 8),
	Size = UDim2.new(1, -28, 0, 18),
	Text = "يتعلّم من كل شوت ينسدد في السيرفر",
	TextColor3 = THEME.SubText,
	TextSize = 12,
	Font = FONT_REG,
	TextXAlignment = Enum.TextXAlignment.Right,
})
learnLabel = label(learnCard, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 30),
	Size = UDim2.new(1, -28, 0, 18),
	Text = "",
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Right,
})
refreshLearnLabel()

-----------------------------------------------------------
-- صفحة 4: المظهر
-----------------------------------------------------------
newPage(TAB_NAMES[4])

switchCard("إظهار الهيتبوكس", "جعل الكرة شفافة لرؤية الحجم", "showHitbox")
sliderCard("شفافية الكرة", "transparency", 0, 0.95, 0.05, "%.2f")
switchCard("إطار الهيتبوكس", "خطوط ملوّنة توضّح حدود الكرة", "outline")
switchCard("تأثير النبض", "الإطار يلمع ويتحرك باستمرار", "pulse")

local colorCard = card(84)
cardHeading(colorCard, "لون الإطار والمسار")

local colorRow = horizontalRow(colorCard, 42, 30, Enum.HorizontalAlignment.Right)
local colorStrokes = {}

local function selectColor(index)
	state.colorIndex = index
	scheduleSave()
	for i, s in ipairs(colorStrokes) do
		tween(s, 0.2, { Transparency = (i == index) and 0 or 1 })
	end
	local color = outlineColor()
	for _, props in pairs(trackedBalls) do
		props.Box.Color3 = color
		props.Tracer.BackgroundColor3 = color
	end
end

for i, color in ipairs(CONFIG.OutlineColors) do
	local swatch = create("TextButton", {
		Size = UDim2.new(0, 30, 0, 30),
		BackgroundColor3 = color,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = i,
		Parent = colorRow,
	}, { corner(15) })
	local s = stroke(THEME.Text, 2, 1)
	s.Parent = swatch
	colorStrokes[i] = s
	swatch.MouseButton1Click:Connect(function()
		selectColor(i)
	end)
end

local themeCard = card(84)
cardHeading(themeCard, "ثيم الواجهة")

local themeRow = horizontalRow(themeCard, 42, 30, Enum.HorizontalAlignment.Right)
local themeStrokes = {}

local function applyTheme(index)
	state.themeIndex = index
	scheduleSave()
	local theme = CONFIG.Themes[index]
	THEME.Accent = theme.Accent
	THEME.Accent2 = theme.Accent2
	local sequence = ColorSequence.new(THEME.Accent, THEME.Accent2)
	for _, g in ipairs(gradients) do
		g.Color = sequence
	end
	for _, ref in ipairs(accentRefs) do
		ref[1][ref[2]] = THEME[ref[3]]
	end
	for i, s in ipairs(themeStrokes) do
		tween(s, 0.2, { Transparency = (i == index) and 0 or 1 })
	end
end

for i, theme in ipairs(CONFIG.Themes) do
	local btn = create("TextButton", {
		Size = UDim2.new(0, 64, 0, 30),
		BackgroundColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = false,
		Text = theme.Name,
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeTransparency = 0.6,
		TextSize = 12,
		Font = FONT_BOLD,
		LayoutOrder = i,
		Parent = themeRow,
	}, {
		corner(8),
		create("UIGradient", { Color = ColorSequence.new(theme.Accent, theme.Accent2) }),
	})
	local s = stroke(THEME.Text, 2, 1)
	s.Parent = btn
	themeStrokes[i] = s
	btn.MouseButton1Click:Connect(function()
		applyTheme(i)
		notify("تم تغيير الثيم إلى " .. theme.Name, THEME.Accent)
	end)
end

-----------------------------------------------------------
-- صفحة 5: أدوات
-----------------------------------------------------------
newPage(TAB_NAMES[5])

switchCard("مؤشر الكرة", "المسافة والسرعة فوق الكرة من خلف الجدران", "esp")
switchCard("خط التتبّع", "خط من شخصيتك إلى الكرة", "tracer")
switchCard("تنبيه قرب الكرة", "صوت وإشعار لما تقترب الكرة منك", "alert")
sliderCard("مسافة التنبيه", "alertDistance", 5, 50, 1, "%d م")

local nameCard = card(84)
cardHeading(nameCard, "اسم الكرة في اللعبة")

local nameBox = create("TextBox", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 40),
	Size = UDim2.new(1, -100, 0, 30),
	BackgroundColor3 = THEME.SurfaceLight,
	Text = state.ballName,
	PlaceholderText = "مثال: Ball",
	PlaceholderColor3 = THEME.SubText,
	TextColor3 = THEME.Text,
	TextSize = 14,
	Font = FONT_BOLD,
	ClearTextOnFocus = false,
	Parent = nameCard,
}, { corner(6), stroke(THEME.Stroke, 1) })

local searchBtn = smallButton(nameCard, "بحث", UDim2.new(0, 14, 0, 40), UDim2.new(0, 66, 0, 30))
searchBtn.TextSize = 13

local function applyBallName()
	local name = nameBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
	if name == "" then
		nameBox.Text = state.ballName
		return
	end
	state.ballName = name
	scheduleSave()
	rescan()
	local n = countBalls()
	if n > 0 then
		notify("تم العثور على " .. n .. " كرة باسم " .. name, THEME.Success)
	else
		notify("لا توجد كرة باسم " .. name, THEME.Danger)
	end
end

searchBtn.MouseButton1Click:Connect(applyBallName)
nameBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		applyBallName()
	end
end)

-----------------------------------------------------------
-- صفحة 6: الإعدادات
-----------------------------------------------------------
newPage(TAB_NAMES[6])

-- تغيير أزرار الاختصار
local capturing = nil -- { key = "toggleKey", button = btn }
local keyInfoLabel -- يُنشأ في بطاقة المعلومات

local function refreshKeyInfo()
	if keyInfoLabel then
		keyInfoLabel.Text = state.toggleKey .. " / " .. state.quickKey
	end
	refreshStatus()
end

local function keybindCard(title, key)
	local c = card(54)
	cardTitle(c, title, "اضغط على الزر ثم اختر مفتاحاً جديداً")
	local btn = smallButton(c, state[key], UDim2.new(0, 14, 0, 12), UDim2.new(0, 92, 0, 30))
	btn.TextSize = 13
	btn.MouseButton1Click:Connect(function()
		if capturing then
			capturing.button.Text = state[capturing.key]
		end
		capturing = { key = key, button = btn }
		btn.Text = "اضغط زر..."
	end)
end

keybindCard("زر إظهار الواجهة", "toggleKey")
keybindCard("زر تشغيل الهيتبوكس", "quickKey")

-- الزر العائم (للجوال)
local floatingBtn = create("TextButton", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0, 50, 0.5, 0),
	Size = UDim2.new(0, 52, 0, 52),
	BackgroundColor3 = Color3.new(1, 1, 1),
	AutoButtonColor = false,
	Text = "⚽",
	TextSize = 24,
	Font = FONT_BOLD,
	TextColor3 = THEME.Text,
	Visible = state.floatingButton,
	ZIndex = 20,
	Parent = screenGui,
}, { corner(26), accentGradient(45), stroke(THEME.Background, 2) })

switchCard("زر عائم", "زر صغير على الشاشة لفتح الواجهة (للجوال)", "floatingButton", function(value)
	floatingBtn.Visible = value
end)

-- حفظ الإعدادات
local saveCard = card(54)
cardTitle(
	saveCard,
	"حفظ الإعدادات",
	canSave and "يتم الحفظ تلقائياً ✓" or "الـ Executor لا يدعم الحفظ"
)
local resetSettingsBtn = smallButton(saveCard, "حذف المحفوظ", UDim2.new(0, 14, 0, 12), UDim2.new(0, 92, 0, 30))
resetSettingsBtn.MouseButton1Click:Connect(function()
	if not canSave then
		notify("الحفظ غير مدعوم في هذا الـ Executor", THEME.Danger)
		return
	end
	pcall(function()
		if typeof(delfile) == "function" then
			delfile(CONFIG.SaveFile)
		else
			writefile(CONFIG.SaveFile, "{}")
		end
	end)
	notify("تم حذف الإعدادات المحفوظة — أعد تشغيل السكربت", THEME.Accent2)
end)

sectionHeader("📊 معلومات")

local infoCard = card(86)
ballCountLabel = statRow(infoCard, 12, "الكرات المكتشفة")
nearestLabel = statRow(infoCard, 34, "أقرب كرة")
keyInfoLabel = statRow(infoCard, 56, "الواجهة / الهيتبوكس")

sectionHeader("ℹ️ عن السكربت")

local links = {}
for _, link in ipairs(CONFIG.Links) do
	if link.Url ~= "" then
		table.insert(links, link)
	end
end

local aboutCard = card(96 + #links * 38)

local aboutTitle = label(aboutCard, {
	Position = UDim2.new(0, 14, 0, 12),
	Size = UDim2.new(1, -28, 0, 24),
	Text = "✦ " .. CONFIG.Author .. " ✦",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 20,
})
accentGradient(0).Parent = aboutTitle

label(aboutCard, {
	Position = UDim2.new(0, 14, 0, 40),
	Size = UDim2.new(1, -28, 0, 16),
	Text = "موسّع هيتبوكس الكرة  •  " .. CONFIG.Version,
	TextColor3 = THEME.SubText,
	TextSize = 12,
	Font = FONT_REG,
})

label(aboutCard, {
	Position = UDim2.new(0, 14, 0, 62),
	Size = UDim2.new(1, -28, 0, 18),
	Text = "شكراً لاستخدامك السكربت ❤",
	TextSize = 13,
})

for i, link in ipairs(links) do
	local y = 92 + (i - 1) * 38
	label(aboutCard, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, y),
		Size = UDim2.new(1, -120, 0, 30),
		Text = link.Name,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	local copyBtn = smallButton(aboutCard, "نسخ الرابط", UDim2.new(0, 14, 0, y), UDim2.new(0, 92, 0, 30))
	copyBtn.MouseButton1Click:Connect(function()
		if typeof(setclipboard) == "function" then
			pcall(setclipboard, link.Url)
			notify("تم نسخ رابط " .. link.Name, THEME.Success)
		else
			notify(link.Url, THEME.Accent2)
		end
	end)
end

-----------------------------------------------------------
-- السحب والإدخال
-----------------------------------------------------------
local windowDragging = false
local dragStart, startPos

local floatPressed = false
local floatMoved = false
local floatStart, floatStartPos

titleBar.InputBegan:Connect(function(input)
	if isPress(input) then
		windowDragging = true
		dragStart = input.Position
		startPos = mainFrame.Position
	end
end)

floatingBtn.InputBegan:Connect(function(input)
	if isPress(input) then
		floatPressed = true
		floatMoved = false
		floatStart = input.Position
		floatStartPos = floatingBtn.Position
	end
end)

connect(UserInputService.InputChanged, function(input)
	if not isMove(input) then return end

	if activeSlider then
		activeSlider.update(input.Position.X)
	elseif windowDragging then
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

-- إظهار / إخفاء
local function setVisible(visible)
	state.guiVisible = visible
	if visible then
		mainFrame.Visible = true
		tween(mainScale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	else
		tween(mainScale, 0.25, { Scale = 0 }).Completed:Connect(function()
			if not state.guiVisible then
				mainFrame.Visible = false
			end
		end)
	end
end

connect(UserInputService.InputEnded, function(input)
	if isPress(input) then
		if activeSlider then
			activeSlider.release()
			activeSlider = nil
		end
		if floatPressed and not floatMoved then
			setVisible(not state.guiVisible)
		end
		floatPressed = false
		windowDragging = false
	end
end)

connect(UserInputService.InputBegan, function(input, gameProcessed)
	-- التقاط زر اختصار جديد
	if capturing and input.UserInputType == Enum.UserInputType.Keyboard then
		local c = capturing
		capturing = nil
		if input.KeyCode ~= Enum.KeyCode.Escape then
			state[c.key] = input.KeyCode.Name
			scheduleSave()
			notify("تم تعيين الزر: " .. input.KeyCode.Name, THEME.Success)
		end
		c.button.Text = state[c.key]
		refreshKeyInfo()
		return
	end

	if gameProcessed then return end
	if input.KeyCode.Name == state.toggleKey then
		setVisible(not state.guiVisible)
	elseif input.KeyCode.Name == state.quickKey then
		enableSwitch.set(not state.enabled)
	end
end)

-- التصغير
minimizeBtn.MouseButton1Click:Connect(function()
	state.minimized = not state.minimized
	minimizeBtn.Text = state.minimized and "+" or "—"
	tween(mainFrame, 0.35, { Size = state.minimized and MINI_SIZE or FULL_SIZE })
end)

-- الإغلاق الكامل
local function cleanup()
	state.enabled = false
	for part in pairs(trackedBalls) do
		untrackBall(part)
	end
	for _, c in ipairs(connections) do
		c:Disconnect()
	end
	table.clear(connections)
	if vizFolder then
		vizFolder:Destroy()
	end
	if screenGui then
		screenGui:Destroy()
	end
	_G.MohammedTN_Hitbox_Cleanup = nil
end

_G.MohammedTN_Hitbox_Cleanup = cleanup

closeBtn.MouseButton1Click:Connect(function()
	tween(mainScale, 0.25, { Scale = 0 }).Completed:Wait()
	cleanup()
end)

-----------------------------------------------------------
-- البدء
-----------------------------------------------------------
selectColor(state.colorIndex)
applyTheme(state.themeIndex)
selectTab(math.clamp(math.floor(state.activeTab), 1, TAB_COUNT), false)
scanForBalls()
refreshBallCount()
refreshRayFilter()
refreshKeyInfo()
setVisible(true)
notify("مرحباً! تم تحميل السكربت " .. CONFIG.Version .. " — صنع من قبل " .. CONFIG.Author, THEME.Accent)
