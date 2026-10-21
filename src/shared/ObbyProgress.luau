local Progress = {}

function Progress.start(course, now)
	return { course = course.Id, stage = 0, started = now, last = now }
end

function Progress.advance(run, course, stage, now)
	if not run or run.course ~= course.Id or stage ~= run.stage + 1 or stage > course.Count then return false end
	if now - run.last < 0.22 then return false end
	if stage == course.Count and now - run.started < course.MinSeconds then return false end
	run.stage, run.last = stage, now
	return true, stage == course.Count
end

function Progress.canFinish(run,course,onFinish)
	return run~=nil and run.course==course.Id and run.stage==course.Count and not run.awarded and onFinish==true
end

-- Coordinates are relative to the rotated hazard. Ignore hats, armor and held
-- tools: only the character's body/feet should trip a restart zone.
function Progress.hazardContact(x,y,z,width,height,depth,standingHeight)
	return math.abs(x)<=width/2+.65 and math.abs(z)<=depth/2+.65 and math.abs(y)<=height/2+(standingHeight+2)/2
end

return Progress
