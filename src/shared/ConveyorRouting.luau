-- Engine-free centerlines, exposed boundary rails, and physical-cookie guidance.
local Layout = if script then require(script.Parent.ConveyorLayout) else require("./ConveyorLayout")
local Routing = {}

local function length(x, z) return math.sqrt(x * x + z * z) end
local function append(path, x, z)
	local previous = path[#path]
	table.insert(path, { x = x, z = z, s = previous and previous.s + length(x - previous.x, z - previous.z) or 0 })
end

function Routing.paths()
	local paths = {}
	for _, x in ipairs(Layout.LaneXs) do
		local path = {}
		append(path, x, Layout.BeltBackZ)
		append(path, x, Layout.BeltFrontZ)
		-- Smoothstep has a forward tangent at both ends: no square elbow.
		for index = 1, 24 do
			local t = index / 24
			append(path, x * (1 - 3 * t * t + 2 * t * t * t), Layout.BeltFrontZ + (Layout.MainStartZ - Layout.BeltFrontZ) * t)
		end
		append(path, 0, Layout.MainEndZ)
		table.insert(paths, path)
	end
	return paths
end

function Routing.pointAt(path, distance)
	distance = math.clamp(distance, 0, path[#path].s)
	for index = 2, #path do
		local a, b = path[index - 1], path[index]
		if distance <= b.s or index == #path then
			local span = b.s - a.s
			local t = (distance - a.s) / span
			return { x = a.x + (b.x - a.x) * t, z = a.z + (b.z - a.z) * t,
				dx = (b.x - a.x) / span, dz = (b.z - a.z) / span }
		end
	end
	return nil
end

function Routing.project(path, x, z)
	local nearest = { distance = math.huge, s = 0 }
	for index = 2, #path do
		local a, b = path[index - 1], path[index]
		local dx, dz = b.x - a.x, b.z - a.z
		local t = math.clamp(((x - a.x) * dx + (z - a.z) * dz) / (dx * dx + dz * dz), 0, 1)
		local distance = length(x - a.x - dx * t, z - a.z - dz * t)
		if distance < nearest.distance then nearest = { distance = distance, s = a.s + (b.s - a.s) * t } end
	end
	return nearest
end

function Routing.surfaces(paths)
	local surfaces, seen = {}, {}
	for lane, path in ipairs(paths) do
		for index = 2, #path do
			local a, b = path[index - 1], path[index]
			local span = b.s - a.s
			local dx, dz = (b.x - a.x) / span, (b.z - a.z) / span
			local key = string.format("%.3f/%.3f/%.3f/%.3f", a.x, a.z, b.x, b.z)
			if not seen[key] then
				seen[key] = true
				table.insert(surfaces, { x = (a.x + b.x) / 2, z = (a.z + b.z) / 2,
					dx = dx, dz = dz, width = Layout.BeltWidth, length = span + 0.12, tier = lane })
			end
			if index < #path then
				local joinKey = string.format("join/%.3f/%.3f", b.x, b.z)
				if not seen[joinKey] then
					seen[joinKey] = true
					local c = path[index + 1]
					local nextSpan = c.s - b.s
					local vx, vz = dx + (c.x - b.x) / nextSpan, dz + (c.z - b.z) / nextSpan
					local magnitude = length(vx, vz)
					table.insert(surfaces, { x = b.x, z = b.z, dx = vx / magnitude, dz = vz / magnitude,
						width = Layout.BeltWidth, round = true, tier = lane })
				end
			end
		end
	end
	return surfaces
end

function Routing.drive(path, x, z, previous, speed)
	local nearest = Routing.project(path, x, z)
	-- Once off the belt or beyond the lip, physics takes over. Never teleport.
	if nearest.distance > Layout.BeltWidth / 2 or z >= Layout.MainEndZ - 0.25 then return nil end
	local progress = math.max(previous or 0, nearest.s)
	local target = Routing.pointAt(path, progress + math.clamp(speed * 0.2, 2, 4))
	local dx, dz = target.x - x, target.z - z
	local magnitude = length(dx, dz)
	if magnitude < 0.01 then return nil end
	return { vx = dx / magnitude * speed, vz = dz / magnitude * speed, s = progress }
end

local function boundary(path, sign)
	local points = {}
	local offset = Layout.BeltWidth / 2 + Layout.RailThickness / 2 + 0.15
	for index, p in ipairs(path) do
		local a, b = path[math.max(1, index - 1)], path[math.min(#path, index + 1)]
		local before = length(p.x - a.x, p.z - a.z)
		local after = length(b.x - p.x, b.z - p.z)
		local ax, az = before > 0 and (p.x - a.x) / before or 0, before > 0 and (p.z - a.z) / before or 0
		local bx, bz = after > 0 and (b.x - p.x) / after or ax, after > 0 and (b.z - p.z) / after or az
		if before == 0 then ax, az = bx, bz end
		local dx, dz = ax + bx, az + bz
		local span = length(dx, dz)
		dx, dz = dx / span, dz / span
		local miter = offset / math.max(0.9, dx * bx + dz * bz)
		table.insert(points, { x = p.x - dz * miter * sign, z = p.z + dx * miter * sign })
	end
	return points
end

function Routing.rails(paths)
	local rails, seen = {}, {}
	local function clear(lane, x, z)
		for otherLane, path in ipairs(paths) do
			if otherLane ~= lane and Routing.project(path, x, z).distance < Layout.BeltWidth / 2 + Layout.RailThickness / 2 + 0.125 then return false end
		end
		return true
	end
	for lane, path in ipairs(paths) do
		for _, sign in ipairs({ -1, 1 }) do
			local edge = boundary(path, sign)
			for index = 2, #edge do
				local a, b = edge[index - 1], edge[index]
				local steps = math.ceil(length(b.x - a.x, b.z - a.z) / 0.25)
				local first
				local function emit(last)
					if not first or last <= first then return end
					local function at(t) return { x = a.x + (b.x - a.x) * t, z = a.z + (b.z - a.z) * t } end
					local start, finish = at(first), at(last)
					local key = string.format("%.2f/%.2f/%.2f/%.2f", start.x, start.z, finish.x, finish.z)
					if not seen[key] then
						seen[key] = true
						table.insert(rails, { a = start, b = finish, tier = lane })
					end
				end
				for step = 0, steps do
					local t = step / steps
					local safe = clear(lane, a.x + (b.x - a.x) * t, a.z + (b.z - a.z) * t)
					if safe and not first then first = t
					elseif not safe and first then
						emit((step - 1) / steps)
						first = nil
					end
				end
				emit(1)
			end
		end
	end
	return rails
end

return Routing
