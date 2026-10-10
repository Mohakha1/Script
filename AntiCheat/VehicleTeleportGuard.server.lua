--[[
	VehicleTeleportGuard (Script)
	ضعه في: ServerScriptService
	يكشف ويمنع النقل الفجائي للمركبات (VehicleSeat) وللاعبين، والنزول تحت الأرض.

	الفكرة: السيرفر يراقب كل مركبة كل إطار. إذا قطعت مسافة أكبر من الممكن
	فيزيائياً أو نزلت تحت حد معين، يتم:
	  1) سحب Network Ownership من العميل وإعادتها للسيرفر.
	  2) إرجاع المركبة واللاعب لآخر موقع سليم.
	  3) تسجيل مخالفة، وطرد اللاعب بعد عدد معين من المخالفات.
]]

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local CONFIG = {
	MaxVehicleSpeed   = 250,   -- أقصى سرعة مسموحة (studs/s) — عدّلها حسب أسرع مركبة لديك
	MaxPlayerSpeed    = 120,   -- للاعب غير الجالس
	TeleportDistance  = 40,    -- أي قفزة في إطار واحد أكبر من هذا = نقل فوري
	MinY              = -10,   -- أي موقع تحت هذا = تحت الأرض (اضبطه حسب خريطتك)
	Grace             = 1.25,  -- هامش تسامح للـ lag
	StrikesToKick     = 3,
	StrikeDecay       = 30,    -- ثوانٍ لمسح مخالفة واحدة
	OwnershipLockTime = 5,     -- مدة إبقاء الملكية عند السيرفر بعد المخالفة
}

-- حالة كل مركبة: [seat] = { root, lastCF, lastTime, lockedUntil }
local vehicles = {}
-- حالة كل لاعب: [player] = { lastCF, lastTime, strikes, lastStrike }
local playersState = {}

local function getVehicleModel(seat)
	local m = seat:FindFirstAncestorOfClass("Model")
	return (m and m ~= workspace) and m or nil
end

local function getPivot(seat)
	local m = getVehicleModel(seat)
	return m and m:GetPivot() or seat.CFrame
end

local function setPivot(seat, cf)
	local m = getVehicleModel(seat)
	if m then m:PivotTo(cf) else seat.CFrame = cf end
	seat.AssemblyLinearVelocity = Vector3.zero
	seat.AssemblyAngularVelocity = Vector3.zero
end

local function lockOwnership(seat, lock)
	if not seat:CanSetNetworkOwnership() then return end
	if lock then
		seat:SetNetworkOwner(nil) -- السيرفر يتولى الفيزياء
	else
		seat:SetNetworkOwnershipAuto()
	end
end

local function strike(player, reason)
	if not player then return end
	local st = playersState[player]
	if not st then return end
	local now = os.clock()
	if now - st.lastStrike > CONFIG.StrikeDecay then
		st.strikes = math.max(0, st.strikes - 1)
	end
	st.strikes += 1
	st.lastStrike = now
	warn(("[AntiCheat] %s (%d) — %s — مخالفة %d/%d"):format(
		player.Name, player.UserId, reason, st.strikes, CONFIG.StrikesToKick))

	if st.strikes >= CONFIG.StrikesToKick then
		-- هنا يمكنك أيضاً حفظ الحظر في DataStore
		player:Kick("تم اكتشاف نشاط غير طبيعي (Vehicle Teleport).")
	end
end

local function isBadMove(lastCF, newCF, dt, maxSpeed)
	local newPos = newCF.Position
	if newPos.Y < CONFIG.MinY then
		return true, ("تحت الأرض Y=%.1f"):format(newPos.Y)
	end
	local dist = (newPos - lastCF.Position).Magnitude
	if dist > CONFIG.TeleportDistance and dist > maxSpeed * dt * CONFIG.Grace then
		return true, ("قفزة %.1f studs في %.3fs"):format(dist, dt)
	end
	if dt > 0 and dist / dt > maxSpeed * CONFIG.Grace and dist > 5 then
		return true, ("سرعة %.0f studs/s"):format(dist / dt)
	end
	return false
end

local function registerSeat(seat)
	if vehicles[seat] then return end
	vehicles[seat] = { lastCF = getPivot(seat), lastTime = os.clock(), lockedUntil = 0 }
	seat.AncestryChanged:Connect(function(_, parent)
		if not parent then vehicles[seat] = nil end
	end)
end

for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("VehicleSeat") then registerSeat(d) end
end
workspace.DescendantAdded:Connect(function(d)
	if d:IsA("VehicleSeat") then registerSeat(d) end
end)

Players.PlayerAdded:Connect(function(player)
	playersState[player] = { strikes = 0, lastStrike = 0 }
	player.CharacterAdded:Connect(function(char)
		local hrp = char:WaitForChild("HumanoidRootPart", 10)
		if hrp then
			local st = playersState[player]
			st.lastCF, st.lastTime, st.spawnGrace = hrp.CFrame, os.clock(), os.clock() + 2
		end
	end)
end)
Players.PlayerRemoving:Connect(function(p) playersState[p] = nil end)

-- استخدم هذه الدالة عند نقل اللاعب بشكل شرعي من السيرفر حتى لا يُكشف خطأً
_G.AntiCheatTeleport = function(player, cf)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	hrp.CFrame = cf
	local st = playersState[player]
	if st then st.lastCF, st.lastTime = cf, os.clock() end
end

RunService.Heartbeat:Connect(function()
	local now = os.clock()

	-- 1) مراقبة المركبات
	for seat, v in pairs(vehicles) do
		local cf = getPivot(seat)
		local dt = now - v.lastTime
		local occupant = seat.Occupant
		local driver = occupant and Players:GetPlayerFromCharacter(occupant.Parent)

		local bad, reason = isBadMove(v.lastCF, cf, dt, CONFIG.MaxVehicleSpeed)
		if bad then
			lockOwnership(seat, true)
			v.lockedUntil = now + CONFIG.OwnershipLockTime
			setPivot(seat, v.lastCF)                 -- إرجاع المركبة
			if driver then
				strike(driver, "مركبة: " .. reason)
				local st = playersState[driver]
				if st then st.lastTime = now end     -- اللاعب رجع مع المركبة
			end
			-- لا نحدّث lastCF: آخر موقع سليم يبقى كما هو
			v.lastTime = now
		else
			v.lastCF, v.lastTime = cf, now
			if v.lockedUntil > 0 and now > v.lockedUntil then
				v.lockedUntil = 0
				lockOwnership(seat, false)
			end
		end
	end

	-- 2) مراقبة اللاعبين (يغطي إعادة اللاعب لموقعه بعد النزول من المركبة)
	for player, st in pairs(playersState) do
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hum and hrp and st.lastCF and hum.Health > 0 then
			local cf = hrp.CFrame
			local dt = now - st.lastTime
			local seated = hum.SeatPart ~= nil
			local inGrace = st.spawnGrace and now < st.spawnGrace

			if seated or inGrace then
				-- المركبة تُراقب بالأعلى؛ نتابع الموقع فقط
				st.lastCF, st.lastTime = cf, now
			else
				local bad, reason = isBadMove(st.lastCF, cf, dt, CONFIG.MaxPlayerSpeed)
				if bad then
					hrp.AssemblyLinearVelocity = Vector3.zero
					hrp.CFrame = st.lastCF                 -- إرجاع للاعب لآخر موقع سليم
					strike(player, "لاعب: " .. reason)
					st.lastTime = now
				else
					st.lastCF, st.lastTime = cf, now
				end
			end
		end
	end
end)

print("[AntiCheat] VehicleTeleportGuard يعمل.")
