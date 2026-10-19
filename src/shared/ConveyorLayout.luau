-- Plain geometry and entry state shared by the world builder and engine-free tests.
local Layout = {
	StationCount = 30,
	StationSpacing = 7,
	FirstStationZ = 102,
	OvenX = -6.8,
	OvenScale = 0.45,
	PadX = -15.5,
	SpawnX = -14,
	SpawnZ = 99,
	BeltWidth = 6.2,
	BeltFrontZ = 112,
	BeltBackZ = -112,
	CookieY = 2.1,
	CookieSpeed = 24,
	MaxVisualCookies = 10,
	StepDwell = 0.28,
	StepCooldown = 0.8,
}

function Layout.station(index)
	if type(index) ~= "number" or index % 1 ~= 0 or index < 1 or index > Layout.StationCount then return nil end
	return { x = Layout.OvenX, z = Layout.FirstStationZ - (index - 1) * Layout.StationSpacing,
		padX = Layout.PadX, scale = Layout.OvenScale }
end

function Layout.belt()
	return { x = 0, z = (Layout.BeltFrontZ + Layout.BeltBackZ) / 2,
		width = Layout.BeltWidth, length = Layout.BeltFrontZ - Layout.BeltBackZ }
end

function Layout.travelDuration(z, interval)
	local cadence = type(interval) == "number" and interval > 0 and interval < math.huge and interval or 3
	local speedFactor = 3 / cadence
	local distance = math.max(0, Layout.BeltFrontZ - z)
	return math.clamp(distance / (Layout.CookieSpeed * speedFactor), 0.65, 9.5)
end

-- The point is the character's feet, expressed in the pad's own coordinate frame.
-- A small vertical tolerance accommodates decorative pads just above the floor.
function Layout.insidePad(x, y, z, width, depth)
	return math.abs(x) <= width / 2 and math.abs(z) <= depth / 2 and math.abs(y) <= 1.35
end

-- An attempted entry is latched until its server action is resolved below.
-- Successful purchases require leaving the pad before another purchase.
function Layout.step(previous, now, inside, available)
	if not inside then return nil, false end
	if not previous then return { enteredAt = now, fired = false }, false end
	if not previous.fired and available and now - previous.enteredAt >= Layout.StepDwell then
		return { enteredAt = previous.enteredAt, fired = true }, true
	end
	return previous, false
end

function Layout.resolveStep(previous, accepted)
	if not previous or accepted == true then return previous end
	-- A throttle or busy save may reject a valid attempt. Preserve its dwell time
	-- and permit a retry after the controller's cooldown without another entry.
	return { enteredAt = previous.enteredAt, fired = false }
end

return Layout
