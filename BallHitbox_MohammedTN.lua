--[[
	╔══════════════════════════════════════════╗
	║        ⚽  موسّع هيتبوكس الكرة  ⚽         ║
	║          صنع من قبل: محمد TN             ║
	╚══════════════════════════════════════════╝

	• زر إظهار / إخفاء الواجهة : RightShift
	• يدعم الكمبيوتر والجوال (لمس)
]]

-----------------------------------------------------------
-- الخدمات
-----------------------------------------------------------
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-----------------------------------------------------------
-- الإعدادات
-----------------------------------------------------------
local CONFIG = {
	ToggleKey = Enum.KeyCode.RightShift,
	BallName = "Ball",
	DefaultSize = 1,
	MinSize = 0.5,
	MaxSize = 10,
	HitboxTransparency = 0.5,
	Author = "محمد TN",
}

-----------------------------------------------------------
-- الألوان
-----------------------------------------------------------
local THEME = {
	Background   = Color3.fromRGB(14, 14, 22),
	Surface      = Color3.fromRGB(22, 22, 34),
	SurfaceLight = Color3.fromRGB(34, 34, 52),
	Stroke       = Color3.fromRGB(58, 58, 88),
	Accent       = Color3.fromRGB(124, 92, 255),
	Accent2      = Color3.fromRGB(0, 190, 255),
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
-- الحالة
-----------------------------------------------------------
local state = {
	enabled = false,
	showHitbox = true,
	size = CONFIG.DefaultSize,
	guiVisible = true,
	minimized = false,
}

local trackedBalls = {} -- [part] = { Size, Transparency, CanCollide, Conn }
local connections = {}

local function connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(connections, c)
	return c
end

-----------------------------------------------------------
-- أدوات مساعدة للواجهة
-----------------------------------------------------------
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
	return create("UIGradient", {
		Color = ColorSequence.new(THEME.Accent, THEME.Accent2),
		Rotation = rotation or 0,
	})
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

-----------------------------------------------------------
-- الواجهة الرئيسية
-----------------------------------------------------------
local FULL_SIZE = UDim2.new(0, 320, 0, 352)
local MINI_SIZE = UDim2.new(0, 320, 0, 58)

local screenGui = create("ScreenGui", {
	Name = "MohammedTN_HitboxGui",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = playerGui,
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

-- خط متدرّج أعلى الواجهة
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

-- أيقونة
local iconHolder = create("Frame", {
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

-- أزرار التحكم (إغلاق / تصغير)
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
		tween(btn, 0.2, { BackgroundColor3 = hoverColor, TextColor3 = THEME.Text })
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, 0.2, { BackgroundColor3 = THEME.SurfaceLight, TextColor3 = THEME.SubText })
	end)
	return btn
end

local closeBtn = titleButton("✕", 14, THEME.Danger)
local minimizeBtn = titleButton("—", 50, THEME.Accent)

-----------------------------------------------------------
-- منطقة المحتوى
-----------------------------------------------------------
local content = create("Frame", {
	Name = "Content",
	Position = UDim2.new(0, 14, 0, 70),
	Size = UDim2.new(1, -28, 1, -84),
	BackgroundTransparency = 1,
	Parent = mainFrame,
}, {
	create("UIListLayout", {
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

local function card(height, order)
	return create("Frame", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = THEME.Surface,
		BorderSizePixel = 0,
		LayoutOrder = order,
		Parent = content,
	}, { corner(10), stroke(THEME.Stroke, 1, 0.4) })
end

local function cardTitle(parent, title, subtitle)
	create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, subtitle and 9 or 0),
		Size = UDim2.new(1, -90, 0, subtitle and 18 or parent.Size.Y.Offset),
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = THEME.Text,
		TextSize = 15,
		Font = FONT_BOLD,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = parent,
	})
	if subtitle then
		return create("TextLabel", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -14, 0, 28),
			Size = UDim2.new(1, -90, 0, 14),
			BackgroundTransparency = 1,
			Text = subtitle,
			TextColor3 = THEME.SubText,
			TextSize = 12,
			Font = FONT_REG,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = parent,
		})
	end
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
	gradient.Enabled = false
	gradient.Parent = switch

	local knob = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.new(0, 20, 0, 20),
		BackgroundColor3 = THEME.SubText,
		Parent = switch,
	}, { corner(10) })

	local value = initial
	local function render(animated)
		local t = animated and 0.25 or 0
		gradient.Enabled = value
		switch.BackgroundColor3 = value and Color3.new(1, 1, 1) or THEME.SurfaceLight
		tween(knob, t, {
			Position = value and UDim2.new(1, -23, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
			BackgroundColor3 = value and Color3.new(1, 1, 1) or THEME.SubText,
		})
	end

	switch.MouseButton1Click:Connect(function()
		value = not value
		render(true)
		onChanged(value)
	end)

	render(false)
	return switch
end

-----------------------------------------------------------
-- بطاقة: التفعيل
-----------------------------------------------------------
local enableCard = card(54, 1)
local statusText = cardTitle(enableCard, "تفعيل الهيتبوكس", "الحالة: متوقف")

-----------------------------------------------------------
-- بطاقة: إظهار الهيتبوكس
-----------------------------------------------------------
local visualCard = card(54, 2)
cardTitle(visualCard, "إظهار الهيتبوكس", "جعل الكرة شفافة لرؤية الحجم")

-----------------------------------------------------------
-- بطاقة: الحجم
-----------------------------------------------------------
local sizeCard = card(92, 3)

create("TextLabel", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 10),
	Size = UDim2.new(0.6, 0, 0, 20),
	BackgroundTransparency = 1,
	Text = "حجم الهيتبوكس",
	TextColor3 = THEME.Text,
	TextSize = 15,
	Font = FONT_BOLD,
	TextXAlignment = Enum.TextXAlignment.Right,
	Parent = sizeCard,
})

local valueBadge = create("TextLabel", {
	Position = UDim2.new(0, 14, 0, 8),
	Size = UDim2.new(0, 56, 0, 24),
	BackgroundColor3 = THEME.SurfaceLight,
	Text = "",
	TextColor3 = THEME.Accent2,
	TextSize = 14,
	Font = FONT_BOLD,
	Parent = sizeCard,
}, { corner(6) })

local resetBtn = create("TextButton", {
	Position = UDim2.new(0, 76, 0, 8),
	Size = UDim2.new(0, 56, 0, 24),
	BackgroundColor3 = THEME.SurfaceLight,
	AutoButtonColor = false,
	Text = "إعادة",
	TextColor3 = THEME.SubText,
	TextSize = 12,
	Font = FONT_BOLD,
	Parent = sizeCard,
}, { corner(6) })

local sliderBg = create("Frame", {
	Position = UDim2.new(0, 14, 0, 48),
	Size = UDim2.new(1, -28, 0, 10),
	BackgroundColor3 = THEME.SurfaceLight,
	Active = true,
	Parent = sizeCard,
}, { corner(5) })

local sliderFill = create("Frame", {
	Size = UDim2.new(0, 0, 1, 0),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BorderSizePixel = 0,
	Parent = sliderBg,
}, { corner(5), accentGradient(0) })

local sliderKnob = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0, 0, 0.5, 0),
	Size = UDim2.new(0, 18, 0, 18),
	BackgroundColor3 = Color3.new(1, 1, 1),
	ZIndex = 2,
	Parent = sliderBg,
}, { corner(9), stroke(THEME.Accent, 2) })

-- حدود الشريط
create("TextLabel", {
	Position = UDim2.new(0, 14, 0, 66),
	Size = UDim2.new(0.5, -14, 0, 14),
	BackgroundTransparency = 1,
	Text = string.format("x%.1f", CONFIG.MinSize),
	TextColor3 = THEME.SubText,
	TextSize = 11,
	Font = FONT_REG,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = sizeCard,
})

create("TextLabel", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 66),
	Size = UDim2.new(0.5, -14, 0, 14),
	BackgroundTransparency = 1,
	Text = string.format("x%.1f", CONFIG.MaxSize),
	TextColor3 = THEME.SubText,
	TextSize = 11,
	Font = FONT_REG,
	TextXAlignment = Enum.TextXAlignment.Right,
	Parent = sizeCard,
})

-----------------------------------------------------------
-- شريط المعلومات
-----------------------------------------------------------
local infoCard = card(40, 4)

local ballCountLabel = create("TextLabel", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -14, 0.5, 0),
	Size = UDim2.new(0.5, -14, 1, 0),
	BackgroundTransparency = 1,
	Text = "الكرات المكتشفة: 0",
	TextColor3 = THEME.Text,
	TextSize = 13,
	Font = FONT_BOLD,
	TextXAlignment = Enum.TextXAlignment.Right,
	Parent = infoCard,
})

create("TextLabel", {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 14, 0.5, 0),
	Size = UDim2.new(0.5, -14, 1, 0),
	BackgroundTransparency = 1,
	Text = "إخفاء: " .. CONFIG.ToggleKey.Name,
	TextColor3 = THEME.SubText,
	TextSize = 12,
	Font = FONT_REG,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = infoCard,
})

-----------------------------------------------------------
-- الإشعارات
-----------------------------------------------------------
local toastHolder = create("Frame", {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -16, 1, -16),
	Size = UDim2.new(0, 260, 1, -32),
	BackgroundTransparency = 1,
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

	local label = create("TextLabel", {
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(1, -28, 1, 0),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = THEME.Text,
		TextTransparency = 1,
		TextSize = 13,
		Font = FONT_BOLD,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = toast,
	})

	tween(toast, 0.3, { BackgroundTransparency = 0.05 })
	tween(toastStroke, 0.3, { Transparency = 0.3 })
	tween(bar, 0.3, { BackgroundTransparency = 0 })
	tween(label, 0.3, { TextTransparency = 0 })

	task.delay(2.5, function()
		if not toast.Parent then return end
		tween(toast, 0.3, { BackgroundTransparency = 1 })
		tween(toastStroke, 0.3, { Transparency = 1 })
		tween(bar, 0.3, { BackgroundTransparency = 1 })
		tween(label, 0.3, { TextTransparency = 1 }).Completed:Wait()
		toast:Destroy()
	end)
end

-----------------------------------------------------------
-- منطق الكرة
-----------------------------------------------------------
local function countBalls()
	local n = 0
	for _ in pairs(trackedBalls) do
		n += 1
	end
	return n
end

local function refreshBallCount()
	ballCountLabel.Text = "الكرات المكتشفة: " .. countBalls()
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

local function addBall(part)
	if not part:IsA("BasePart") or trackedBalls[part] then return end

	local props = {
		Size = part.Size,
		Transparency = part.Transparency,
		CanCollide = part.CanCollide,
	}
	props.Conn = part.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			props.Conn:Disconnect()
			trackedBalls[part] = nil
			refreshBallCount()
		end
	end)

	trackedBalls[part] = props
	refreshBallCount()
end

connect(Workspace.DescendantAdded, function(descendant)
	if descendant.Name == CONFIG.BallName then
		addBall(descendant)
	end
end)

for _, descendant in ipairs(Workspace:GetDescendants()) do
	if descendant.Name == CONFIG.BallName then
		addBall(descendant)
	end
end

connect(RunService.Heartbeat, function()
	if not state.enabled then return end

	for part, props in pairs(trackedBalls) do
		if part.Parent then
			local targetSize = props.Size * state.size
			local targetTransparency = state.showHitbox and CONFIG.HitboxTransparency or props.Transparency

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
	end
end)

-----------------------------------------------------------
-- ربط الواجهة بالمنطق
-----------------------------------------------------------
makeSwitch(enableCard, state.enabled, function(value)
	state.enabled = value
	statusText.Text = value and "الحالة: يعمل ✓" or "الحالة: متوقف"
	statusText.TextColor3 = value and THEME.Success or THEME.SubText
	if value then
		notify("تم تفعيل الهيتبوكس ✓", THEME.Success)
	else
		restoreAll()
		notify("تم إيقاف الهيتبوكس", THEME.Danger)
	end
end)

makeSwitch(visualCard, state.showHitbox, function(value)
	state.showHitbox = value
end)

-- الشريط
local function setSize(value, animated)
	state.size = math.clamp(value, CONFIG.MinSize, CONFIG.MaxSize)
	local percent = (state.size - CONFIG.MinSize) / (CONFIG.MaxSize - CONFIG.MinSize)
	local t = animated and 0.25 or 0
	tween(sliderFill, t, { Size = UDim2.new(percent, 0, 1, 0) })
	tween(sliderKnob, t, { Position = UDim2.new(percent, 0, 0.5, 0) })
	valueBadge.Text = string.format("x%.1f", state.size)
end

local function sizeFromX(x)
	local percent = math.clamp((x - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
	-- تقريب لأقرب 0.1
	local value = CONFIG.MinSize + percent * (CONFIG.MaxSize - CONFIG.MinSize)
	return math.floor(value * 10 + 0.5) / 10
end

local sliderDragging = false

local function isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
end

sliderBg.InputBegan:Connect(function(input)
	if isPress(input) then
		sliderDragging = true
		tween(sliderKnob, 0.15, { Size = UDim2.new(0, 22, 0, 22) })
		setSize(sizeFromX(input.Position.X), false)
	end
end)

resetBtn.MouseEnter:Connect(function()
	tween(resetBtn, 0.2, { BackgroundColor3 = THEME.Accent, TextColor3 = THEME.Text })
end)
resetBtn.MouseLeave:Connect(function()
	tween(resetBtn, 0.2, { BackgroundColor3 = THEME.SurfaceLight, TextColor3 = THEME.SubText })
end)
resetBtn.MouseButton1Click:Connect(function()
	setSize(CONFIG.DefaultSize, true)
	notify("تمت إعادة الحجم إلى الافتراضي", THEME.Accent2)
end)

-- السحب (للواجهة وللشريط)
local windowDragging = false
local dragStart, startPos

titleBar.InputBegan:Connect(function(input)
	if isPress(input) then
		windowDragging = true
		dragStart = input.Position
		startPos = mainFrame.Position
	end
end)

connect(UserInputService.InputChanged, function(input)
	if not isMove(input) then return end

	if sliderDragging then
		setSize(sizeFromX(input.Position.X), false)
	elseif windowDragging then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end
end)

connect(UserInputService.InputEnded, function(input)
	if isPress(input) then
		if sliderDragging then
			tween(sliderKnob, 0.15, { Size = UDim2.new(0, 18, 0, 18) })
		end
		sliderDragging = false
		windowDragging = false
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

connect(UserInputService.InputBegan, function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == CONFIG.ToggleKey then
		setVisible(not state.guiVisible)
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
	restoreAll()
	for part, props in pairs(trackedBalls) do
		if props.Conn then
			props.Conn:Disconnect()
		end
		trackedBalls[part] = nil
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
setSize(CONFIG.DefaultSize, false)
refreshBallCount()
setVisible(true)
notify("مرحباً! تم تحميل السكربت — صنع من قبل " .. CONFIG.Author, THEME.Accent)
