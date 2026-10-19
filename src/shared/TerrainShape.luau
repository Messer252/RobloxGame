-- Continuous height field: the snow is a surface material on the same terrain.
local Shape = {}
local function smooth(x) x = math.clamp(x, 0, 1); return x * x * (3 - 2 * x) end
function Shape.lake(x, z) return x > -355 and x < -215 and z > -425 and z < -315 end
function Shape.height(x, z)
	local edge = math.max(math.abs(x) - 410, math.abs(z) - 570)
	local foothill = smooth(edge / 160)
	local ridge = 0.5 + 0.22 * math.sin(x / 103 + z / 173) + 0.16 * math.cos(z / 97 - x / 181) + 0.09 * math.sin(x / 47 + z / 73)
	local height = -0.6 + foothill * (32 + ridge * 210) + smooth((edge - 160) / 220) * (28 + ridge * 80)
	if edge < 0 and math.abs(x) > 215 then
		local public = not (x < -225 and z > 0 and z < 215) and not (x > 200 and (math.abs(z) < 50 or math.abs(z - 180) < 50 or math.abs(z + 180) < 50))
		if public then height += smooth((math.abs(x) - 215) / 110) * (2.3 + 2.5 * math.sin(z / 51) * math.cos(x / 71)) end
	end
	local hillDistance = math.sqrt((x + 285)^2 + (z - 400)^2)
	if hillDistance < 60 then height = math.max(height, 8 * (1 - smooth((hillDistance - 25) / 35))) end
	return height
end
function Shape.snow(x, z, height) return height > 158 + 12 * math.sin(x / 71) + 9 * math.cos(z / 91) end
return Shape
