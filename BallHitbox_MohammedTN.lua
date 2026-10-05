--[[
	╔══════════════════════════════════════════╗
	║        ⚽  موسّع هيتبوكس الكرة  ⚽         ║
	║          صنع من قبل: محمد TN             ║
	╚══════════════════════════════════════════╝

	• إظهار / إخفاء الواجهة : RightShift
	• تشغيل / إيقاف الهيتبوكس بسرعة : H
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
	QuickToggleKey = Enum.KeyCode.H,
	BallName = "Ball",
	DefaultSize = 1,
	MinSize = 0.5,
	MaxSize = 10,
	DefaultTransparency = 0.5,
	SizePresets = { 2, 4, 6, 8 },
	OutlineColors = {
		Color3.fromRGB(124, 92, 255),
		Color3.fromRGB(0, 190, 255),
		Color3.fromRGB(46, 204, 113),
		Color3.fromRGB(255, 200, 0),
		Color3.fromRGB(235, 77, 75),
		Color3.fromRGB(255, 255, 255),
	},
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
	transparency = CONFIG.DefaultTransparency,
	outline = true,
	outlineColor = CONFIG.OutlineColors[1],
	esp = false,
	size = CONFIG.DefaultSize,
	guiVisible = true,
	minimized = false,
}

-- [part] = { Size, Transparency, CanCollide, Conn, Box, Esp, EspLabel }
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

local function isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
end

local function hoverButton(btn, normalColor, hoverColor)
	btn.MouseEnter:Connect(function()
		tween(btn, 0.2, { BackgroundColor3 = hoverColor, TextColor3 = THEME.Text })
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, 0.2, { BackgroundColor3 = normalColor, TextColor3 = THEME.SubText })
	end)
end

-----------------------------------------------------------
-- الواجهة الرئيسية
-----------------------------------------------------------
local FULL_SIZE = UDim2.new(0, 340, 0, 460)
local MINI_SIZE = UDim2.new(0, 340, 0, 58)

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
	hoverButton(btn, THEME.SurfaceLight, hoverColor)
	return btn
end

local closeBtn = titleButton("✕", 14, THEME.Danger)
local minimizeBtn = titleButton("—", 50, THEME.Accent)

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
	ScrollBarImageColor3 = THEME.Accent,
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

local function sectionHeader(text)
	cardOrder += 1
	create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = THEME.Accent2,
		TextSize = 13,
		Font = FONT_BOLD,
		TextXAlignment = Enum.TextXAlignment.Right,
		LayoutOrder = cardOrder,
		Parent = content,
	})
end

local function label(parent, props)
	props.BackgroundTransparency = 1
	props.Font = props.Font or FONT_BOLD
	props.TextColor3 = props.TextColor3 or THEME.Text
	props.Parent = parent
	return create("TextLabel", props)
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
		local t = animated and 0.25 or 0
		gradient.Enabled = value
		switch.BackgroundColor3 = value and Color3.new(1, 1, 1) or THEME.SurfaceLight
		tween(knob, t, {
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

-- شريط تمرير قابل لإعادة الاستخدام
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

	local knob = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, 18, 0, 18),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 2,
		Parent = bg,
	}, { corner(9), stroke(THEME.Accent, 2) })

	local badge = create("TextLabel", {
		Position = UDim2.new(0, 14, 0, 8),
		Size = UDim2.new(0, 56, 0, 24),
		BackgroundColor3 = THEME.SurfaceLight,
		Text = "",
		TextColor3 = THEME.Accent2,
		TextSize = 14,
		Font = FONT_BOLD,
		Parent = parent,
	}, { corner(6) })

	local api = { value = initial }

	function api.set(value, animated)
		value = math.clamp(math.floor(value / step + 0.5) * step, min, max)
		api.value = value
		local percent = (value - min) / (max - min)
		local t = animated and 0.25 or 0
		tween(fill, t, { Size = UDim2.new(percent, 0, 1, 0) })
		tween(knob, t, { Position = UDim2.new(percent, 0, 0.5, 0) })
		badge.Text = string.format(format, value)
		onChanged(value)
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

	api.set(initial, false)
	return api
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
	hoverButton(btn, THEME.SurfaceLight, THEME.Accent)
	return btn
end

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

-----------------------------------------------------------
-- منطق الكرة
-----------------------------------------------------------
local ballCountLabel, nearestLabel -- تُنشأ لاحقاً في بطاقة المعلومات

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
	trackedBalls[part] = nil
	refreshBallCount()
end

local function addBall(part)
	if not part:IsA("BasePart") or trackedBalls[part] then return end

	local props = {
		Size = part.Size,
		Transparency = part.Transparency,
		CanCollide = part.CanCollide,
	}

	-- إطار يوضّح حدود الهيتبوكس
	props.Box = create("SelectionBox", {
		Adornee = part,
		Color3 = state.outlineColor,
		LineThickness = 0.05,
		SurfaceTransparency = 1,
		Visible = false,
		Parent = playerGui,
	})

	-- مؤشر فوق الكرة يعرض المسافة
	props.Esp = create("BillboardGui", {
		Adornee = part,
		AlwaysOnTop = true,
		Size = UDim2.new(0, 110, 0, 26),
		StudsOffset = Vector3.new(0, 3, 0),
		Enabled = false,
		Parent = playerGui,
	})
	create("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = THEME.Background,
		BackgroundTransparency = 0.25,
		Parent = props.Esp,
	}, { corner(8), stroke(THEME.Accent, 1.5) })
	props.EspLabel = label(props.Esp, {
		Size = UDim2.new(1, 0, 1, 0),
		Text = "⚽",
		TextSize = 13,
		ZIndex = 2,
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
		if descendant.Name == CONFIG.BallName then
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
	if descendant.Name == CONFIG.BallName then
		addBall(descendant)
	end
end)

local function getRootPosition()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return root and root.Position
end

local lastInfoUpdate = 0

connect(RunService.Heartbeat, function()
	local rootPos = getRootPosition()
	local nearest = math.huge

	for part, props in pairs(trackedBalls) do
		if part.Parent then
			-- تطبيق الهيتبوكس
			if state.enabled then
				local targetSize = props.Size * state.size
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

			props.Box.Visible = state.enabled and state.outline
			props.Esp.Enabled = state.esp

			if rootPos then
				local distance = (part.Position - rootPos).Magnitude
				nearest = math.min(nearest, distance)
				if state.esp then
					props.EspLabel.Text = string.format("⚽ %.1f م", distance)
				end
			end
		end
	end

	local now = os.clock()
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

local enableCard = card(54)
local statusText = cardTitle(enableCard, "تفعيل الهيتبوكس", "الحالة: متوقف  •  اختصار: " .. CONFIG.QuickToggleKey.Name)

local enableSwitch = makeSwitch(enableCard, state.enabled, function(value)
	state.enabled = value
	statusText.Text = (value and "الحالة: يعمل ✓" or "الحالة: متوقف") .. "  •  اختصار: " .. CONFIG.QuickToggleKey.Name
	statusText.TextColor3 = value and THEME.Success or THEME.SubText
	if value then
		notify("تم تفعيل الهيتبوكس ✓", THEME.Success)
	else
		restoreAll()
		notify("تم إيقاف الهيتبوكس", THEME.Danger)
	end
end)

-- الحجم
local sizeCard = card(118)
label(sizeCard, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 10),
	Size = UDim2.new(0.5, 0, 0, 20),
	Text = "حجم الهيتبوكس",
	TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Right,
})

local sizeSlider = makeSlider(sizeCard, 48, CONFIG.MinSize, CONFIG.MaxSize, 0.1, CONFIG.DefaultSize, "x%.1f", function(value)
	state.size = value
end)

local resetBtn = smallButton(sizeCard, "إعادة", UDim2.new(0, 76, 0, 8), UDim2.new(0, 56, 0, 24))
resetBtn.MouseButton1Click:Connect(function()
	sizeSlider.set(CONFIG.DefaultSize, true)
	notify("تمت إعادة الحجم إلى الافتراضي", THEME.Accent2)
end)

-- أزرار الأحجام السريعة
local presetRow = create("Frame", {
	Position = UDim2.new(0, 14, 0, 74),
	Size = UDim2.new(1, -28, 0, 30),
	BackgroundTransparency = 1,
	Parent = sizeCard,
}, {
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

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

-----------------------------------------------------------
-- القسم: المظهر
-----------------------------------------------------------
sectionHeader("🎨 المظهر")

local visualCard = card(54)
cardTitle(visualCard, "إظهار الهيتبوكس", "جعل الكرة شفافة لرؤية الحجم")
makeSwitch(visualCard, state.showHitbox, function(value)
	state.showHitbox = value
end)

local transparencyCard = card(70)
label(transparencyCard, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 10),
	Size = UDim2.new(0.5, 0, 0, 20),
	Text = "شفافية الكرة",
	TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Right,
})
makeSlider(transparencyCard, 46, 0, 0.95, 0.05, state.transparency, "%.2f", function(value)
	state.transparency = value
end)

local outlineCard = card(54)
cardTitle(outlineCard, "إطار الهيتبوكس", "خطوط ملوّنة توضّح حدود الكرة")
makeSwitch(outlineCard, state.outline, function(value)
	state.outline = value
end)

local colorCard = card(84)
label(colorCard, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 10),
	Size = UDim2.new(1, -28, 0, 20),
	Text = "لون الإطار",
	TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Right,
})

local swatchRow = create("Frame", {
	Position = UDim2.new(0, 14, 0, 40),
	Size = UDim2.new(1, -28, 0, 30),
	BackgroundTransparency = 1,
	Parent = colorCard,
}, {
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

local swatchStrokes = {}
local function selectColor(color)
	state.outlineColor = color
	for c, s in pairs(swatchStrokes) do
		tween(s, 0.2, { Transparency = (c == color) and 0 or 1 })
	end
	for _, props in pairs(trackedBalls) do
		props.Box.Color3 = color
	end
end

for i, color in ipairs(CONFIG.OutlineColors) do
	local swatch = create("TextButton", {
		Size = UDim2.new(0, 30, 0, 30),
		BackgroundColor3 = color,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = i,
		Parent = swatchRow,
	}, { corner(15) })
	local s = stroke(THEME.Text, 2, 1)
	s.Parent = swatch
	swatchStrokes[color] = s
	swatch.MouseButton1Click:Connect(function()
		selectColor(color)
	end)
end

-----------------------------------------------------------
-- القسم: أدوات
-----------------------------------------------------------
sectionHeader("🧭 أدوات")

local espCard = card(54)
cardTitle(espCard, "مؤشر الكرة", "يعرض مكان الكرة والمسافة من خلف الجدران")
makeSwitch(espCard, state.esp, function(value)
	state.esp = value
end)

local nameCard = card(84)
label(nameCard, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 10),
	Size = UDim2.new(1, -28, 0, 20),
	Text = "اسم الكرة في اللعبة",
	TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Right,
})

local nameBox = create("TextBox", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 40),
	Size = UDim2.new(1, -100, 0, 30),
	BackgroundColor3 = THEME.SurfaceLight,
	Text = CONFIG.BallName,
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
		nameBox.Text = CONFIG.BallName
		return
	end
	CONFIG.BallName = name
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

label(infoCard, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 56),
	Size = UDim2.new(1, -28, 0, 16),
	Text = "الواجهة: " .. CONFIG.ToggleKey.Name .. "  •  الهيتبوكس: " .. CONFIG.QuickToggleKey.Name,
	TextColor3 = THEME.SubText,
	TextSize = 12,
	Font = FONT_REG,
	TextXAlignment = Enum.TextXAlignment.Right,
})

-- توقيع
cardOrder += 1
local signature = label(content, {
	Size = UDim2.new(1, 0, 0, 20),
	Text = "✦ صنع بواسطة " .. CONFIG.Author .. " ✦",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 13,
	LayoutOrder = cardOrder,
})
accentGradient(0).Parent = signature

-----------------------------------------------------------
-- السحب والإدخال
-----------------------------------------------------------
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

	if activeSlider then
		activeSlider.update(input.Position.X)
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
		if activeSlider then
			activeSlider.release()
			activeSlider = nil
			content.ScrollingEnabled = true
		end
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
	elseif input.KeyCode == CONFIG.QuickToggleKey then
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
selectColor(state.outlineColor)
scanForBalls()
refreshBallCount()
setVisible(true)
notify("مرحباً! تم تحميل السكربت — صنع من قبل " .. CONFIG.Author, THEME.Accent)
