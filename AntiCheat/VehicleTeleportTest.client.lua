--[[
	VehicleTeleportTest (LocalScript)
	ضعه في: StarterPlayer > StarterPlayerScripts
	الغرض: محاكاة سلوك الـ Executors لاختبار نظام الحماية في السيرفر فقط.
	احذفه (أو اجعل ENABLED = false) قبل نشر اللعبة.

	لماذا يعمل هذا من العميل؟
	عندما يجلس اللاعب في VehicleSeat يمنحه روبلوكس "Network Ownership" للمركبة،
	فيصبح العميل هو من يحسب فيزياء المركبة، وأي تغيير في موقعها يتكرر إلى السيرفر.
	هذه بالضبط الثغرة التي يستغلها المخترقون.
]]

local ENABLED       = true
local TRIGGER_KEY   = Enum.KeyCode.F8          -- زر تشغيل الاختبار
local TARGET_OFFSET = Vector3.new(0, -60, 0)   -- إزاحة تحت الأرض نسبةً لموقع المركبة
local TARGET_ABS    = nil                      -- أو ضع Vector3 لإحداثيات مطلقة، مثال: Vector3.new(500, -40, 500)
local HOLD_TIME     = 1.5                      -- مدة البقاء في الموقع الهدف (ثوانٍ)

if not ENABLED then return end

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

local player = Players.LocalPlayer
local running = false

local function log(...)
	print("[VehicleTeleportTest]", ...)
end

-- يجد أقرب VehicleSeat غير مشغول في الـ Workspace
local function findVehicleSeat(fromPos)
	local best, bestDist
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("VehicleSeat") and not obj.Occupant then
			local d = (obj.Position - fromPos).Magnitude
			if not bestDist or d < bestDist then
				best, bestDist = obj, d
			end
		end
	end
	return best
end

-- يعيد الموديل الذي يحتوي المقعد (الحافلة) أو المقعد نفسه إن لم يوجد موديل
local function getVehicleRoot(seat)
	local model = seat:FindFirstAncestorOfClass("Model")
	if model and model ~= workspace then
		return model
	end
	return seat
end

local function pivot(obj, cf)
	if obj:IsA("Model") then
		obj:PivotTo(cf)
	else
		obj.CFrame = cf
	end
end

local function getPivot(obj)
	return obj:IsA("Model") and obj:GetPivot() or obj.CFrame
end

local function runTest()
	if running then return end
	running = true

	local character = player.Character
	local humanoid  = character and character:FindFirstChildOfClass("Humanoid")
	local hrp       = character and character:FindFirstChild("HumanoidRootPart")
	if not (humanoid and hrp) then
		log("لا توجد شخصية.")
		running = false
		return
	end

	-- 1) حفظ موقع الشخصية محلياً
	local savedCFrame = hrp.CFrame
	log("تم حفظ الموقع:", savedCFrame.Position)

	-- 2) البحث عن VehicleSeat
	local seat = findVehicleSeat(hrp.Position)
	if not seat then
		log("لم يتم العثور على VehicleSeat فارغ.")
		running = false
		return
	end
	local vehicle = getVehicleRoot(seat)
	local vehicleOriginal = getPivot(vehicle)
	log("المركبة:", vehicle:GetFullName())

	-- 3) الانتقال إلى المقعد والجلوس (للحصول على Network Ownership)
	hrp.CFrame = seat.CFrame + Vector3.new(0, 3, 0)
	task.wait(0.1)
	seat:Sit(humanoid)

	local t0 = os.clock()
	while humanoid.SeatPart ~= seat and os.clock() - t0 < 2 do
		RunService.Heartbeat:Wait()
	end
	if humanoid.SeatPart ~= seat then
		log("فشل الجلوس في المقعد.")
		hrp.CFrame = savedCFrame
		running = false
		return
	end
	task.wait(0.3) -- انتظار انتقال ملكية الشبكة للعميل

	-- 4) نقل الحافلة مع اللاعب فجأة إلى الإحداثيات الهدف / تحت الأرض
	local targetPos = TARGET_ABS or (vehicleOriginal.Position + TARGET_OFFSET)
	local targetCF  = CFrame.new(targetPos) * (vehicleOriginal - vehicleOriginal.Position)
	log("نقل المركبة إلى:", targetPos)

	local holdUntil = os.clock() + HOLD_TIME
	while os.clock() < holdUntil and humanoid.SeatPart == seat do
		-- نكرر النقل كل إطار لأن الجاذبية/التصادم قد تحرك المركبة
		pivot(vehicle, targetCF)
		RunService.Heartbeat:Wait()
	end

	-- 5) إعادة اللاعب لموقعه الأصلي
	humanoid.Sit = false
	humanoid.Jump = true
	task.wait(0.1)
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.CFrame = savedCFrame
	log("تمت إعادة اللاعب. راقب سجل السيرفر لمعرفة هل تم كشف الحركة.")

	running = false
end

UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == TRIGGER_KEY then
		task.spawn(runTest)
	end
end)

log("جاهز. اضغط", TRIGGER_KEY.Name, "لتشغيل الاختبار.")
