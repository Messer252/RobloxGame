-- Engine-independent movement limits, progress detection and diagonal walk pose.
local Rules = { Speed = 8, Refresh = 1.5, StuckAfter = 2.5, Reach = 1.4, MaxWaypointTime = 15 }
function Rules.destination(z, side, roll, distanceRoll)
	local direction = roll < .5 and -1 or 1
	if z > 450 then direction = -1 elseif z < -450 then direction = 1 end
	return side * 5, math.clamp(z + direction * (28 + math.clamp(distanceRoll, 0, 1) * 38), -520, 520)
end
function Rules.watch(x, z, now)
	return { x = x, z = z, movedAt = now, started = now }
end
function Rules.check(watch, x, y, z, goalX, goalY, goalZ, now)
	if (x-goalX)^2 + (z-goalZ)^2 <= Rules.Reach^2 and math.abs(y-goalY) < 3.5 then return "arrived" end
	if (x-watch.x)^2 + (z-watch.z)^2 >= .6^2 then watch.x,watch.z,watch.movedAt=x,z,now end
	if now-watch.movedAt >= Rules.StuckAfter or now-watch.started >= Rules.MaxWaypointTime then return "blocked" end
	return "walking"
end
function Rules.pose(phase, amount)
	local stride = math.sin(phase) * .48 * math.clamp(amount, 0, 1)
	return { leftHip = stride, rightHip = -stride, leftShoulder = -stride*.75, rightShoulder = stride*.75 }
end
return Rules
