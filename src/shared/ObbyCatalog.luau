local Catalog = {
	{ Id = "Easy", Name = "Cookie Steps", Bonus = 0.1, Count = 10, Width = 5.8, Gap = 11.7, Z = -180, MinSeconds = 5, Color = { 139, 208, 166 } },
	{ Id = "Medium", Name = "Sugar Zigzag", Bonus = 0.3, Count = 14, Width = 4.1, Gap = 10.8, Z = 0, MinSeconds = 9, Color = { 238, 195, 111 } },
	{ Id = "Hard", Name = "Golden Leap", Bonus = 0.5, Count = 18, Width = 2.8, Gap = 9.3, Z = 180, MinSeconds = 13, Color = { 205, 145, 181 } },
}

function Catalog.platform(course, stage)
	local zigzag = math.sin(stage * 0.85) * (course.Id == "Hard" and 5.5 or course.Id == "Medium" and 4.2 or 1.4)
	return { x = 230 + stage * course.Gap, y = 3.9 + (stage % 3) * (course.Id == "Easy" and 0.7 or 1.25), z = course.Z + zigzag }
end

return Catalog
