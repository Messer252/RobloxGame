-- Continuous height field: the snow is a surface material on the same terrain.
local Map = if script then require(script.Parent.MapLayout) else require("./MapLayout")
local Town = if script then require(script.Parent.TownCatalog) else require("./TownCatalog")
local Mine = if script then require(script.Parent.MiningCatalog) else require("./MiningCatalog")
local Obbys = if script then require(script.Parent.ObbyCatalog) else require("./ObbyCatalog")
local Wilderness=if script then require(script.Parent.WildernessRules) else require("./WildernessRules")
local Shape = {}
local function smooth(x) x = math.clamp(x, 0, 1); return x * x * (3 - 2 * x) end
local plots = {}
for slot = 1, Map.PlayerCount do table.insert(plots, Map.plot(slot)) end

-- Include a six-stud shoulder beyond the floor/pavers. Terrain uses four-stud
-- voxels, and native grass blades can otherwise grow through the thin parts.
local function clearanceDistance(x, z)
	local distance = math.max(math.abs(x) - 20, math.abs(z) - 586)
	distance=math.min(distance,math.sqrt((x-Wilderness.BossX)^2+(z-Wilderness.BossZ)^2)-Wilderness.BossRadius-6)
	-- Keep the cave workshop and its approach free of terrain and grass.
	distance = math.min(distance, math.max(math.abs(x + 229) - 15, math.abs(z - 108) - 17))
	distance = math.min(distance, math.sqrt(x * x + z * z) - 33)
	for _,point in ipairs({Town.PackStand,Town.Blacksmith}) do
		distance=math.min(distance,math.max(math.abs(x-point.x)-Town.MarketWidth/2-6,math.abs(z-point.z)-Town.MarketDepth/2-6))
	end
	-- Padded public walkways connect the plaza to both market foundations.
	distance=math.min(distance,Town.pathDistance(x,z)-Town.PathHalfWidth-6)
	for _, plot in ipairs(plots) do
		-- BakeryFloor is 164 x 244; mirroring does not change its footprint.
		distance = math.min(distance, math.max(math.abs(x - plot.x) - 88, math.abs(z - plot.z) - 128))
	end
	return distance
end

function Shape.grassAllowed(x, z)
	return not Obbys.inPit(x,z,8) and clearanceDistance(x, z) >= 12 and (x + 285)^2 + (z - 400)^2 > 34^2
end
function Shape.lake(x, z) return x > -355 and x < -215 and z > -425 and z < -315 end
function Shape.height(x, z)
	if Obbys.inPit(x,z) then return -20 end
	local distance = clearanceDistance(x, z)
	if distance <= 0 then return -6 end
	local edge = math.max(math.abs(x) - 410, math.abs(z) - 570)
	local foothill = smooth(edge / 160)
	local ridge = 0.5 + 0.22 * math.sin(x / 103 + z / 173) + 0.16 * math.cos(z / 97 - x / 181) + 0.09 * math.sin(x / 47 + z / 73)
	local height = -0.6 + foothill * (32 + ridge * 210) + smooth((edge - 160) / 220) * (28 + ridge * 80)
	if edge < 0 and math.abs(x) > 215 then
		local public = not (x < -225 and z > 0 and z < 215) and not (x > 200 and (math.abs(z) < 50 or math.abs(z - 180) < 50 or math.abs(z + 180) < 50))
		if public then height += smooth((math.abs(x) - 215) / 110) * (2.3 + 2.5 * math.sin(z / 51) * math.cos(x / 71)) end
	end
	local hillDistance = math.sqrt((x + 285)^2 + (z - 400)^2)
	-- A broad, grass-free crown supports the arena without clipping its deck.
	if hillDistance < 60 then height = math.max(height, 6 * (1 - smooth((hillDistance - 31) / 29))) end
	-- Keep the terrain well below constructed surfaces, then blend back into
	-- the meadow. Ground material on this shoulder also suppresses grass blades.
	local clearance = 1 - smooth(distance / 12)
	height += (math.min(height, -6) - height) * clearance
	-- A continuous grassy/rocky mound surrounds the carved dough cavern.
	local mound = Mine.mound(x,z)
	if mound>0 then height = math.max(height, mound) end
	return height
end
function Shape.snow(x, z, height) return height > 158 + 12 * math.sin(x / 71) + 9 * math.cos(z / 91) end
return Shape
