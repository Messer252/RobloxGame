local Layout = require("../src/shared/ConveyorLayout")
local Routing = require("../src/shared/ConveyorRouting")

local function distanceToEdge(edge, x, z)
	local dx, dz = edge.b.x - edge.a.x, edge.b.z - edge.a.z
	local t = math.clamp(((x - edge.a.x) * dx + (z - edge.a.z) * dz) / (dx * dx + dz * dz), 0, 1)
	return math.sqrt((x - edge.a.x - t * dx)^2 + (z - edge.a.z - t * dz)^2)
end

return function(test, equal, near)
	local paths = Routing.paths()
	local rails = Routing.rails(paths)
	local surfaces = Routing.surfaces(paths)
	local function supported(x, z, tier)
		for _, surface in ipairs(surfaces) do
			if tier and surface.tier > tier then continue end
			local dx, dz = x - surface.x, z - surface.z
			if surface.round then
				if dx * dx + dz * dz <= (surface.width / 2)^2 then return true end
			elseif math.abs(dx * surface.dx + dz * surface.dz) <= surface.length / 2
				and math.abs(-dx * surface.dz + dz * surface.dx) <= surface.width / 2 then return true end
		end
		return false
	end
	test("curved feeders join a shared outlet with gradual forward-facing bends", function()
		equal(#paths, 3)
		for lane, path in ipairs(paths) do
			equal(path[1].x, Layout.LaneXs[lane])
			equal(path[1].z, Layout.BeltBackZ)
			equal(path[#path].x, 0)
			equal(path[#path].z, Layout.MainEndZ)
			local last
			for index = 2, #path do
				local a, b = path[index - 1], path[index]
				assert(b.z > a.z and b.s > a.s)
				local dx, dz = (b.x - a.x) / (b.s - a.s), (b.z - a.z) / (b.s - a.s)
				if last then assert(dx * last.dx + dz * last.dz > math.cos(math.rad(15))) end
				last = { dx = dx, dz = dz }
			end
			near(last.dx, 0)
			near(last.dz, 1)
		end
		assert(Layout.BeltWidth >= 9 and Layout.RailHeight >= 1.8 and Layout.RailThickness >= 0.65)
	end)

	test("no rail or rounded endpoint crosses any lane's travel corridor", function()
		assert(#rails > 0 and #rails < 180)
		for _, edge in ipairs(rails) do
			for step = 0, 20 do
				local t = step / 20
				local x = edge.a.x + (edge.b.x - edge.a.x) * t
				local z = edge.a.z + (edge.b.z - edge.a.z) * t
				for _, path in ipairs(paths) do
					assert(Routing.project(path, x, z).distance - Layout.RailThickness / 2 >= Layout.BeltWidth / 2 - 0.001,
						"Rail intrudes into a moving lane")
				end
			end
		end
	end)

	test("every bend has a coplanar infill point and overlapping belt intervals", function()
		-- These are the exact rectangles and disks consumed by the world builder.
		-- Check each cookie's footprint, not just centerline connectivity.
		for _, path in ipairs(paths) do
			for distance = Layout.CookieRadius + 0.1, path[#path].s - Layout.CookieRadius - 0.1, 0.5 do
				local point = Routing.pointAt(path, distance)
				for angle = 0, 7 do
					local rad = angle * math.pi / 4
					local x, z = point.x + math.cos(rad) * Layout.CookieRadius, point.z + math.sin(rad) * Layout.CookieRadius
					assert(supported(x, z), string.format("Cookie footprint crosses a gap at %.3f, %.3f", x, z))
				end
			end
		end
	end)

	test("all thirty cookie routes clear the rails at ordinary and maximum speed", function()
		local dt, alpha = 0.05, 1 - math.exp(-12 * 0.05)
		for index = 1, Layout.StationCount do
			local station = Layout.station(index)
			local path = paths[station.lane]
			for _, speed in ipairs({ 12, 22 }) do
				for _, offset in ipairs({ -1.5, 0, 1.5 }) do
					local x, z, vx, vz, progress = station.laneX + offset, station.z, 0, speed, 0
					local delivered = false
					for step = 1, 600 do
						local drive = Routing.drive(path, x, z, progress, speed)
						if not drive then
							assert(z >= Layout.MainEndZ - 0.25 and vz > 0, "Route lost guidance before the delivery lip")
							assert(math.abs(x) + Layout.CookieRadius < Layout.BeltWidth / 2)
							delivered = true
							break
						end
						progress = drive.s
						vx, vz = vx + (drive.vx - vx) * alpha, vz + (drive.vz - vz) * alpha
						x, z = x + vx * dt, z + vz * dt
						if step % 4 == 0 then
							for _, edge in ipairs(rails) do
								assert(distanceToEdge(edge, x, z) - Layout.RailThickness / 2 > Layout.CookieRadius + 0.1,
									"A cookie trajectory intersects a rail")
							end
						end
					end
					assert(delivered, "Cookie stalled before reaching the box")
				end
			end
		end
	end)


	test("each conveyor purchase supports its complete route through the merge", function()
		for tier=1,3 do
			for lane=1,tier do
				local path=paths[lane]
				for distance=Layout.CookieRadius+.1,path[#path].s-Layout.CookieRadius-.1,.5 do
					local point=Routing.pointAt(path,distance)
					for angle=0,7 do
						local x=point.x+math.cos(angle*math.pi/4)*Layout.CookieRadius
						local z=point.z+math.sin(angle*math.pi/4)*Layout.CookieRadius
						assert(supported(x,z,tier),string.format("Tier %d leaves lane %d unsupported at %.2f, %.2f",tier,lane,x,z))
					end
				end
			end
		end
	end)

	test("off-belt cookies and cookies over the outlet lip are released to gravity", function()
		equal(Routing.drive(paths[1], -60, 90, 0, 12), nil)
		equal(Routing.drive(paths[2], 0, Layout.MainEndZ, 0, 22), nil)
		local drive = Routing.drive(paths[1], Layout.LaneXs[1], 40, 0, 12)
		assert(drive and drive.vz > 0)
		near(math.sqrt(drive.vx^2 + drive.vz^2), 12)
	end)

	test("oven counters stay outside the thicker rails and first purchases remain near spawn", function()
		for index = 1, Layout.StationCount do
			local station = Layout.station(index)
			local outerRail = station.laneX + Layout.BeltWidth / 2 + Layout.RailThickness + 0.15
			assert(station.x - 3 > outerRail)
			assert(station.z + 3.3 < Layout.BeltFrontZ)
		end
		local nextRecipe = Layout.station(2)
		assert(math.sqrt((nextRecipe.padX - Layout.SpawnX)^2 + (nextRecipe.z - Layout.SpawnZ)^2) < 24)
	end)
end
