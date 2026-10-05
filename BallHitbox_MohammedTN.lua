--[[
	╔══════════════════════════════════════════╗
	║        ⚽  موسّع هيتبوكس الكرة  ⚽         ║
	║          صنع من قبل: محمد TN             ║
	║                 v3.2                     ║
	╚══════════════════════════════════════════╝

	• إظهار / إخفاء الواجهة : RightShift  (قابل للتغيير)
	• تشغيل / إيقاف الهيتبوكس : H          (قابل للتغيير)
	• يدعم الكمبيوتر والجوال (زر عائم للجوال)
	• حفظ الإعدادات تلقائياً (إذا كان الـ Executor يدعم writefile)
	• تصدّي تلقائي: اختر زر التصدّي وزر القفز من الشاشة مرة وحدة
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
local GuiService = game:GetService("GuiService")
local VirtualInputManager = nil
pcall(function()
	VirtualInputManager = game:GetService("VirtualInputManager")
end)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-----------------------------------------------------------
-- الإعدادات الثابتة
-----------------------------------------------------------
local CONFIG = {
	Version = "v3.2",
	Author = "محمد TN",
	SaveFile = "MohammedTN_Hitbox.json",
	MinSize = 0.5,
	MaxSize = 10,
	SizePresets = { 2, 4, 6, 8 },
	AutoSizeRange = 40,       -- كل 40 مسافة يتضاعف الحجم في الوضع التلقائي
	PredictionDots = 10,
	PredictionStep = 0.08,    -- ثواني بين كل نقطة في توقّع المسار
	AlertSound = "rbxasset://sounds/electronicpingshort.wav",
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
	Background   = Color3.fromRGB(14, 14, 22),
	Surface      = Color3.fromRGB(22, 22, 34),
	SurfaceLight = Color3.fromRGB(34, 34, 52),
	Stroke       = Color3.fromRGB(58, 58, 88),
	Accent       = CONFIG.Themes[1].Accent,
	Accent2      = CONFIG.Themes[1].Accent2,
	Text         = Color3.fromRGB(240, 240, 250),
	SubText      = Color3.fromRGB(150, 150, 178),
	Success      = Color3.fromRGB(46, 204, 113),
	Danger       = Color3.fromRGB(235, 77, 75),
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
	colorIndex = 1,
	pulse = false,
	esp = false,
	tracer = false,
	prediction = false,
	alert = false,
	alertDistance = 15,
	toggleKey = "RightShift",
	quickKey = "H",
	themeIndex = 1,
	floatingButton = UserInputService.TouchEnabled,
	autoSave = false,
	standButtonPath = "",
	diveButtonPath = "",
	reactionTime = 0.35,
	standRange = 4,
	diveRange = 14,
	saveCooldown = 1,
	faceBall = true,
	useRemote = true,
	saveReach = 6,
	autoDive = true,

	-- غير محفوظة
	enabled = false,
	guiVisible = true,
	minimized = false,
}

local SAVED_KEYS = {
	"ballName", "size", "autoSize", "axisX", "axisY", "axisZ", "showHitbox",
	"transparency", "outline", "colorIndex", "pulse", "esp", "tracer",
	"prediction", "alert", "alertDistance", "toggleKey", "quickKey",
	"themeIndex", "floatingButton", "autoSave", "standButtonPath", "diveButtonPath",
	"reactionTime", "standRange", "diveRange", "saveCooldown", "faceBall",
	"useRemote", "saveReach", "autoDive",
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
	end)
	if not ok or type(data) ~= "table" then return end
	for _, key in ipairs(SAVED_KEYS) do
		if data[key] ~= nil and type(data[key]) == type(state[key]) then
			state[key] = data[key]
		end
	end
	-- التحقق من القيم
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

-- [part] = { Size, Transparency, CanCollide, Conn, Box, Esp, EspLabel, Tracer, Dots }
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
local FULL_SIZE = UDim2.new(0, 340, 0, 480)
local MINI_SIZE = UDim2.new(0, 340, 0, 58)

local screenGui = create("ScreenGui", {
	Name = "MohammedTN_HitboxGui",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = playerGui,
})

-- طبقة الرسم (خطوط التتبّع ونقاط المسار) خلف الواجهة
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
	corner(14),
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
	Size = UDim2.new(1, -140, 0, 22),
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
	Size = UDim2.new(1, -140, 0, 16),
	BackgroundTransparency = 1,
	Text = "صنع من قبل " .. CONFIG.Author,
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 13,
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
-- منطقة المحتوى (قابلة للتمرير)
-----------------------------------------------------------
local content = create("ScrollingFrame", {
	Name = "Content",
	Position = UDim2.new(0, 0, 0, 62),
	Size = UDim2.new(1, 0, 1, -62),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 3,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	Parent = mainFrame,
}, {
	create("UIListLayout", {
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
	create("UIPadding", {
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 14),
		PaddingLeft = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 14),
	}),
})
accentize(content, "ScrollBarImageColor3", "Accent")

local cardOrder = 0
local function card(height)
	cardOrder += 1
	return create("Frame", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = THEME.Surface,
		BorderSizePixel = 0,
		LayoutOrder = cardOrder,
		Parent = content,
	}, { corner(10), stroke(THEME.Stroke, 1, 0.4) })
end

local function label(parent, props)
	props.BackgroundTransparency = 1
	props.Font = props.Font or FONT_BOLD
	props.TextColor3 = props.TextColor3 or THEME.Text
	props.Parent = parent
	return create("TextLabel", props)
end

local function sectionHeader(text)
	cardOrder += 1
	local header = label(content, {
		Size = UDim2.new(1, 0, 0, 18),
		Text = text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
		LayoutOrder = cardOrder,
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
		Size = UDim2.new(0, 56, 0, 24),
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
		tween(knob, 0.15, { Size = UDim2.new(0, 18, 0, 18) })
	end

	bg.InputBegan:Connect(function(input)
		if isPress(input) then
			activeSlider = api
			content.ScrollingEnabled = false
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
		ballCountLabel.Text = "الكرات المكتشفة: " .. countBalls()
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
	for _, dot in ipairs(props.Dots) do
		dot:Destroy()
	end
	trackedBalls[part] = nil
	refreshBallCount()
end

local function addBall(part)
	if not part:IsA("BasePart") or trackedBalls[part] then return end

	local props = {
		Size = part.Size,
		Transparency = part.Transparency,
		CanCollide = part.CanCollide,
		Dots = {},
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

	-- نقاط توقّع المسار
	for i = 1, CONFIG.PredictionDots do
		props.Dots[i] = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.new(0, 8, 0, 8),
			BackgroundColor3 = outlineColor(),
			BackgroundTransparency = i / (CONFIG.PredictionDots + 2),
			BorderSizePixel = 0,
			Visible = false,
			Parent = overlay,
		}, { corner(4) })
	end

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

local function hideOverlay(props)
	props.Tracer.Visible = false
	for _, dot in ipairs(props.Dots) do
		dot.Visible = false
	end
end

local lastInfoUpdate = 0
local alertActive = false

connect(RunService.RenderStepped, function()
	local camera = Workspace.CurrentCamera
	local rootPos = getRootPosition()
	local nearest = math.huge
	local now = os.clock()
	local pulse = (math.sin(now * 5) + 1) / 2

	for part, props in pairs(trackedBalls) do
		if not part.Parent then
			hideOverlay(props)
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

		-- توقّع المسار
		local showPrediction = state.prediction and velocity.Magnitude > 2
		local gravity = Vector3.new(0, -Workspace.Gravity, 0)
		for i, dot in ipairs(props.Dots) do
			if showPrediction then
				local t = i * CONFIG.PredictionStep
				local point = part.Position + velocity * t + 0.5 * gravity * t * t
				local screen = camera:WorldToViewportPoint(point)
				dot.Visible = screen.Z > 0
				dot.Position = UDim2.new(0, screen.X, 0, screen.Y)
			else
				dot.Visible = false
			end
		end
	end

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
	if nearestLabel and now - lastInfoUpdate > 0.2 then
		lastInfoUpdate = now
		nearestLabel.Text = nearest < math.huge
			and string.format("أقرب كرة: %.1f م", nearest)
			or "أقرب كرة: —"
	end
end)

-----------------------------------------------------------
-- القسم: الأساسي
-----------------------------------------------------------
sectionHeader("⚙️ الأساسي")

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

local resetBtn = smallButton(sizeCard, "إعادة", UDim2.new(0, 76, 0, 10), UDim2.new(0, 56, 0, 24))
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

-----------------------------------------------------------
-- القسم: متقدم (تكبير كل اتجاه)
-----------------------------------------------------------
sectionHeader("📐 متقدم")

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
-- القسم: المظهر
-----------------------------------------------------------
sectionHeader("🎨 المظهر")

switchCard("إظهار الهيتبوكس", "جعل الكرة شفافة لرؤية الحجم", "showHitbox")
sliderCard("شفافية الكرة", "transparency", 0, 0.95, 0.05, "%.2f")
switchCard("إطار الهيتبوكس", "خطوط ملوّنة توضّح حدود الكرة", "outline")
switchCard("تأثير النبض", "الإطار يلمع ويتحرك باستمرار", "pulse")

local colorCard = card(84)
cardHeading(colorCard, "لون الإطار والخطوط")

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
		for _, dot in ipairs(props.Dots) do
			dot.BackgroundColor3 = color
		end
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

-----------------------------------------------------------
-- القسم: أدوات
-----------------------------------------------------------
sectionHeader("🧭 أدوات")

switchCard("مؤشر الكرة", "المسافة والسرعة فوق الكرة من خلف الجدران", "esp")
switchCard("خط التتبّع", "خط من شخصيتك إلى الكرة", "tracer")
switchCard("توقّع مسار الكرة", "نقاط توضّح وين رح تروح الكرة", "prediction")
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
-- القسم: التصدّي التلقائي
-----------------------------------------------------------
sectionHeader("🧤 التصدّي التلقائي")

local saveButtons = {}  -- [kind] = GuiButton
local picking = nil     -- "stand" أو "dive" أثناء اختيار الزر
local saveCount = 0

-- مسار الزر داخل PlayerGui (لإيجاده مرة ثانية بعد الموت أو إعادة التشغيل)
local function buttonPath(btn)
	local names = {}
	local node = btn
	while node and node ~= playerGui do
		table.insert(names, 1, node.Name)
		node = node.Parent
	end
	return node == playerGui and table.concat(names, "/") or ""
end

local function resolvePath(path)
	if path == "" then return nil end
	local node = playerGui
	for name in string.gmatch(path, "[^/]+") do
		node = node:FindFirstChild(name)
		if not node then return nil end
	end
	return node:IsA("GuiButton") and node or nil
end

local function getSaveButton(kind)
	local btn = saveButtons[kind]
	if btn and btn.Parent then return btn end
	btn = resolvePath(state[kind .. "ButtonPath"])
	saveButtons[kind] = btn
	return btn
end

-- يضغط زر اللعبة: أولاً عبر getconnections ثم بنقرة وهمية
local function pressButton(btn)
	if not btn or not btn.Parent then return end
	if typeof(getconnections) == "function" then
		for _, signalName in ipairs({ "Activated", "MouseButton1Click", "MouseButton1Down", "TouchTap" }) do
			local fired = false
			pcall(function()
				for _, conn in ipairs(getconnections(btn[signalName])) do
					fired = true
					conn:Fire()
				end
			end)
			if fired then return end
		end
	end
	if VirtualInputManager then
		pcall(function()
			local center = btn.AbsolutePosition + btn.AbsoluteSize / 2
			local layer = btn:FindFirstAncestorWhichIsA("ScreenGui")
			if not (layer and layer.IgnoreGuiInset) then
				center += GuiService:GetGuiInset()
			end
			VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 0)
			task.wait(0.05)
			VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 0)
		end)
	end
end

-- أصغر زر من أزرار اللعبة تحت نقطة اللمس
local function findButtonAt(position)
	local inset = GuiService:GetGuiInset()
	for _, offset in ipairs({ Vector2.zero, inset, -inset }) do
		local best, bestArea = nil, math.huge
		for _, obj in ipairs(playerGui:GetDescendants()) do
			if obj:IsA("GuiButton") and obj.Visible and not obj:IsDescendantOf(screenGui) then
				local layer = obj:FindFirstAncestorWhichIsA("ScreenGui")
				if layer and layer.Enabled then
					local p = position + offset
					if layer.IgnoreGuiInset then
						p += inset
					end
					local a, s = obj.AbsolutePosition, obj.AbsoluteSize
					local area = s.X * s.Y
					if p.X >= a.X and p.X <= a.X + s.X and p.Y >= a.Y and p.Y <= a.Y + s.Y and area < bestArea then
						best, bestArea = obj, area
					end
				end
			end
		end
		if best then
			return best
		end
	end
	return nil
end

local _, autoSaveSub = switchCard(
	"تفعيل التصدّي التلقائي",
	"عدد التصدّيات: 0",
	"autoSave",
	function(value)
		notify(value and "تم تفعيل التصدّي التلقائي 🧤" or "تم إيقاف التصدّي التلقائي", value and THEME.Success or THEME.Danger)
	end
)

local pickLabels = {}

local function refreshPickLabels()
	for kind, lbl in pairs(pickLabels) do
		local btn = getSaveButton(kind)
		lbl.Text = btn and ("✓ تم الاختيار: " .. btn.Name) or "لم يتم اختيار زر بعد"
		lbl.TextColor3 = btn and THEME.Success or THEME.SubText
	end
end

local function pickCard(title, kind)
	local c = card(54)
	pickLabels[kind] = cardTitle(c, title, "")
	local pickBtn = smallButton(c, "اختيار", UDim2.new(0, 14, 0, 12), UDim2.new(0, 56, 0, 30))
	pickBtn.TextSize = 13
	local testBtn = smallButton(c, "تجربة", UDim2.new(0, 76, 0, 12), UDim2.new(0, 56, 0, 30))
	testBtn.TextSize = 13

	pickBtn.MouseButton1Click:Connect(function()
		picking = kind
		mainFrame.Visible = false
		notify("اضغط الحين على " .. title .. " في شاشة اللعبة", THEME.Accent2)
	end)

	testBtn.MouseButton1Click:Connect(function()
		local btn = getSaveButton(kind)
		if btn then
			task.spawn(pressButton, btn)
			notify("تم ضغط الزر للتجربة", THEME.Accent2)
		else
			notify("اختر الزر أولاً", THEME.Danger)
		end
	end)
end

pickCard("زر التصدّي (واقف)", "stand")
pickCard("زر القفز (زاوية)", "dive")
refreshPickLabels()

local function finishPicking(position)
	local kind = picking
	picking = nil
	local btn = findButtonAt(position)
	if btn then
		saveButtons[kind] = btn
		state[kind .. "ButtonPath"] = buttonPath(btn)
		scheduleSave()
		notify("تم اختيار الزر ✓", THEME.Success)
	else
		notify("ما لقيت زر في هذا المكان، جرّب مرة ثانية", THEME.Danger)
	end
	refreshPickLabels()
	task.delay(0.3, function()
		mainFrame.Visible = state.guiVisible
	end)
end

-- ريموتات الماب (Remotes.Game.Touch / Touch.Kick / Ragdoll)
local function findGameRemote(...)
	local node = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
	for _, name in ipairs({ ... }) do
		node = node and node:FindFirstChild(name)
	end
	return node
end

-- نفس اللي ترسله اللعبة لما الكرة تلمس يد الحارس
local function remoteSave(ball, root)
	local touchRemote = findGameRemote("Game", "Touch")
	if not touchRemote then return end
	local kickRemote = touchRemote:FindFirstChild("Kick")
	local data = {
		ball,
		"Save",
		0.19,
		{ Right = false, Ground = false, Left = false },
		root.CFrame,
		Vector3.zero,
	}
	task.spawn(function()
		pcall(function()
			touchRemote:InvokeServer(data)
		end)
	end)
	if kickRemote then
		pcall(function()
			kickRemote:FireServer(data)
		end)
	end
end

-- قفزة نحو مكان وصول الكرة (اللعبة تقفز على جهازك ثم ترسل Ragdoll)
local function remoteDive(root, offset, t)
	local flat = Vector3.new(offset.X, 0, offset.Z)
	if flat.Magnitude < 0.5 then return end
	local speed = math.clamp(flat.Magnitude / math.max(t, 0.15), 20, 60)
	root.CFrame = CFrame.lookAt(root.Position, root.Position + flat)
	root.AssemblyLinearVelocity = flat.Unit * speed + Vector3.new(0, 12, 0)
	local ragdollRemote = findGameRemote("Game", "Ragdoll")
	if ragdollRemote then
		pcall(function()
			ragdollRemote:FireServer()
		end)
	end
end

switchCard("استخدام الريموت (أدق)", "يرسل التصدّي للسيرفر مباشرة بدون أزرار", "useRemote")
sliderCard("مسافة مسك الكرة", "saveReach", 2, 15, 0.5, "%.1f")
switchCard("قفز تلقائي", "يقفز نحو الكرة إذا كانت بعيدة على جنب", "autoDive")
sliderCard("وقت ردة الفعل (ثانية)", "reactionTime", 0.1, 1, 0.05, "%.2f")
sliderCard("مدى التصدّي واقف", "standRange", 1, 10, 0.5, "%.1f")
sliderCard("أقصى مدى للقفز", "diveRange", 4, 30, 1, "%d")
sliderCard("وقت الانتظار بين كل تصدّي", "saveCooldown", 0.3, 3, 0.1, "%.1f")
switchCard("توجيه اللاعب نحو الكرة", "يلف اللاعب باتجاه الكرة قبل التصدّي", "faceBall")

local lastSaveTime = 0
local lastDiveTime = 0

local function faceTowards(root, direction)
	local flat = Vector3.new(direction.X, 0, direction.Z)
	if flat.Magnitude > 0.1 then
		root.CFrame = CFrame.lookAt(root.Position, root.Position + flat)
	end
end

local function countSave()
	saveCount += 1
	autoSaveSub.Text = "عدد التصدّيات: " .. saveCount
end

connect(RunService.Heartbeat, function()
	if not state.autoSave or picking then return end
	local now = os.clock()
	if now - lastSaveTime < state.saveCooldown then return end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	-- best: أخطر كرة قادمة (أقرب وقت وصول) • nearest: أقرب كرة تتحرك نحوك
	local best, nearest, nearestDistance = nil, nil, math.huge
	for part in pairs(trackedBalls) do
		if part.Parent then
			local velocity = part.AssemblyLinearVelocity
			local speed = velocity.Magnitude
			local rel = part.Position - root.Position
			local distance = rel.Magnitude

			if speed > 3 and rel:Dot(velocity) < 0 and distance < nearestDistance then
				nearest, nearestDistance = part, distance
			end

			if speed > 8 then
				local t = -rel:Dot(velocity) / (speed * speed)
				if t > 0 and t <= state.reactionTime then
					local closest = rel + velocity * t
					local flat = Vector3.new(closest.X, 0, closest.Z)
					local miss = flat.Magnitude
					if math.abs(closest.Y) < 12 and miss <= state.diveRange and (not best or t < best.t) then
						best = { t = t, miss = miss, offset = flat, part = part }
					end
				end
			end
		end
	end

	-- طريقة الريموت: نمسك الكرة لما توصل لمسافة المسك
	if state.useRemote and findGameRemote("Game", "Touch") then
		if nearest and nearestDistance <= state.saveReach then
			lastSaveTime = now
			if state.faceBall then
				faceTowards(root, nearest.Position - root.Position)
			end
			remoteSave(nearest, root)
			countSave()
		elseif state.autoDive and best and best.miss > state.standRange and now - lastDiveTime > 1.5 then
			lastDiveTime = now
			remoteDive(root, best.offset, best.t)
		end
		return
	end

	-- طريقة الأزرار
	if not best then return end
	local standBtn = getSaveButton("stand")
	local diveBtn = getSaveButton("dive")
	local btn
	if best.miss <= state.standRange then
		btn = standBtn or diveBtn
	else
		btn = diveBtn or standBtn
	end
	if not btn then return end

	lastSaveTime = now
	if state.faceBall then
		faceTowards(root, best.miss > 0.5 and best.offset or (best.part.Position - root.Position))
	end
	task.spawn(pressButton, btn)
	countSave()
end)

-----------------------------------------------------------
-- القسم: الإعدادات
-----------------------------------------------------------
sectionHeader("🛠️ الإعدادات")

-- تغيير أزرار الاختصار
local capturing = nil -- { key = "toggleKey", button = btn }
local keyInfoLabel -- يُنشأ في بطاقة المعلومات

local function refreshKeyInfo()
	if keyInfoLabel then
		keyInfoLabel.Text = "الواجهة: " .. state.toggleKey .. "  •  الهيتبوكس: " .. state.quickKey
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

-- الثيمات
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

-----------------------------------------------------------
-- القسم: معلومات
-----------------------------------------------------------
sectionHeader("📊 معلومات")

local infoCard = card(84)

ballCountLabel = label(infoCard, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 10),
	Size = UDim2.new(1, -28, 0, 18),
	Text = "الكرات المكتشفة: 0",
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Right,
})

nearestLabel = label(infoCard, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 32),
	Size = UDim2.new(1, -28, 0, 18),
	Text = "أقرب كرة: —",
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Right,
})

keyInfoLabel = label(infoCard, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 56),
	Size = UDim2.new(1, -28, 0, 16),
	Text = "",
	TextColor3 = THEME.SubText,
	TextSize = 12,
	Font = FONT_REG,
	TextXAlignment = Enum.TextXAlignment.Right,
})

-----------------------------------------------------------
-- القسم: عن السكربت
-----------------------------------------------------------
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
			content.ScrollingEnabled = true
		end
		if floatPressed and not floatMoved then
			setVisible(not state.guiVisible)
		end
		floatPressed = false
		windowDragging = false
	end
end)

connect(UserInputService.InputBegan, function(input, gameProcessed)
	-- اختيار زر التصدّي من شاشة اللعبة
	if picking and isPress(input) then
		finishPicking(Vector2.new(input.Position.X, input.Position.Y))
		return
	end

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
scanForBalls()
refreshBallCount()
refreshKeyInfo()
setVisible(true)
notify("مرحباً! تم تحميل السكربت — صنع من قبل " .. CONFIG.Author, THEME.Accent)
