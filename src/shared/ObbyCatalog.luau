local Catalog = {
	{ Id = "Easy", Name = "Cookie Steps", Bonus = 0.1, Count = 10, Width = 7, Gap = 11, Z = -180, MinSeconds = 5, Color = { 139, 208, 166 } },
	{ Id = "Medium", Name = "Sugar Zigzag", Bonus = 0.3, Count = 14, Width = 5, Gap = 10, Z = 0, MinSeconds = 9, Color = { 238, 195, 111 } },
	{ Id = "Hard", Name = "Golden Leap", Bonus = 0.5, Count = 18, Width = 3.5, Gap = 9, Z = 180, MinSeconds = 13, Color = { 205, 145, 181 } },
}

function Catalog.platform(course, stage)
	local zigzag = course.Id == "Easy" and 0 or math.sin(stage * 0.8) * (course.Id == "Hard" and 7 or 4)
	return { x = 230 + stage * course.Gap, y = 4 + (course.Id == "Easy" and 0 or (stage % 3) * 1.1), z = course.Z + zigzag }
end

return Catalog
