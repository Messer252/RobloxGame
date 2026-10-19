-- Plain geometry and entry state shared by the world builder and engine-free tests.
local Layout = {
	StationCount = 30,
	StationSpacing = 7,
	FirstStationZ = 74,
	OvenX = -44.8,
	OvenScale = 0.45,
	PadX = -53.5,
	SpawnX = -52,
	SpawnZ = 71,
	BeltWidth = 9,
	BeltFrontZ = 78,
	BeltBackZ = -8,
	RailHeight = 1.8,
	RailThickness = 0.65,
	CookieRadius = 1.725,
	MainStartZ = 118,
	MainEndZ = 126,
	BoxZ = 134,
	BeltTop = 4.4,
	LaneXs = { -36, 0, 36 },
	CookieY = 4.78,
	CookieSpeed = 12,
	MaxVisualCookies = 10,
	StepDwell = 0.28,
	StepCooldown = 0.8,
}

function Layout.station(index)
	if type(index) ~= "number" or index % 1 ~= 0 or index < 1 or index > Layout.StationCount then return nil end
	local lane = math.floor((index - 1) / 10) + 1
	local laneX = Layout.LaneXs[lane]
	return { x = laneX - 8.8, z = Layout.FirstStationZ - ((index - 1) % 10) * Layout.StationSpacing,
		padX = laneX - 17.5, scale = Layout.OvenScale, lane = lane, laneX = laneX }
end

function Layout.speed(interval)
	return math.clamp(Layout.CookieSpeed * 3 / math.max(0.2, interval or 3), 12, 22)
end

function Layout.segments()
	-- Logical connections; ConveyorRouting expands these into connected curves.
	local result = {}
	for _, x in ipairs(Layout.LaneXs) do
		table.insert(result, { ax = x, az = Layout.BeltBackZ, bx = x, bz = Layout.BeltFrontZ })
		table.insert(result, { ax = x, az = Layout.BeltFrontZ, bx = 0, bz = Layout.MainStartZ })
	end
	table.insert(result, { ax = 0, az = Layout.MainStartZ, bx = 0, bz = Layout.MainEndZ })
	return result
end

function Layout.belt()
	return { x = 0, z = (Layout.BeltFrontZ + Layout.BeltBackZ) / 2,
		width = Layout.BeltWidth, length = Layout.BeltFrontZ - Layout.BeltBackZ }
end

function Layout.travelDuration(z, interval)
	local cadence = type(interval) == "number" and interval > 0 and interval < math.huge and interval or 3
	local distance = math.max(0, Layout.BeltFrontZ - z)
	return math.clamp(distance / Layout.speed(cadence), 0.65, 9.5)
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
