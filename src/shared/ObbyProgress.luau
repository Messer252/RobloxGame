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

return Progress
