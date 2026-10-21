local Catalog = {
	{ Id = "Easy", Name = "Cookie Steps", Bonus = 0.1, Count = 14, Width = 4.8, Gap = 11, Z = -180, MinSeconds = 8, Color = { 139, 208, 166 } },
	{ Id = "Medium", Name = "Sugar Zigzag", Bonus = 0.3, Count = 18, Width = 3.8, Gap = 10, Z = 0, MinSeconds = 11, Color = { 238, 195, 111 } },
	{ Id = "Hard", Name = "Golden Leap", Bonus = 0.5, Count = 24, Width = 2.8, Gap = 8.1, Z = 180, MinSeconds = 15, Color = { 205, 145, 181 } },
}

function Catalog.platform(course, stage)
	local zigzag = math.sin(stage * 0.85) * (course.Id == "Hard" and 5.5 or course.Id == "Medium" and 4.2 or 1.4)
	local hazard = stage < course.Count and stage % (course.Id == "Easy" and 4 or 3) == 0
	return { x = 230 + stage * course.Gap, y = 3.9 + (stage % 3) * (course.Id == "Easy" and 0.7 or 1.25), z = course.Z + zigzag,
		width = stage == course.Count and 9 or hazard and 7 or course.Width,
		hazard = hazard and (course.Id == "Easy" and "Edge" or course.Id == "Medium" and "Hurdle" or "Sweeper") or nil }
end

function Catalog.pit(course) return {236,444,course.Z-26,course.Z+26} end
function Catalog.inPit(x,z,padding)
	padding=padding or 0
	for _,course in ipairs(Catalog) do
		local r=Catalog.pit(course)
		if x>=r[1]-padding and x<=r[2]+padding and z>=r[3]-padding and z<=r[4]+padding then return true end
	end
	return false
end
-- Subtract each pit from the meadow slabs too; clearing Terrain alone leaves
-- a solid Part floor. The lake's existing opening remains untouched.
function Catalog.groundRegions()
	local regions={{-450,-355,-610,610},{-215,450,-610,610},{-355,-215,-610,-425},{-355,-215,-315,610}}
	for _,course in ipairs(Catalog) do
		local hole=Catalog.pit(course)
		local nextRegions={}
		for _,r in ipairs(regions) do
			local x1,x2,z1,z2=math.max(r[1],hole[1]),math.min(r[2],hole[2]),math.max(r[3],hole[3]),math.min(r[4],hole[4])
			if x1>=x2 or z1>=z2 then table.insert(nextRegions,r)
			else
				for _,piece in ipairs({{r[1],x1,r[3],r[4]},{x2,r[2],r[3],r[4]},{x1,x2,r[3],z1},{x1,x2,z2,r[4]}}) do
					if piece[2]>piece[1] and piece[4]>piece[3] then table.insert(nextRegions,piece) end
				end
			end
		end
		regions=nextRegions
	end
	return regions
end
return Catalog
