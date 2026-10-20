-- Original, coordinated outfits built from local parts; no clothing IDs needed.
local Style = {}
local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end
local cream, cocoa, brass = rgb(242,230,205),rgb(64,42,34),rgb(194,147,75)
local profiles = {
	{ skin=rgb(223,174,131), hair=rgb(65,42,31), coat=rgb(65,119,109), pants=rgb(61,68,74), accent=rgb(219,171,93), style="Cap", outfit="Varsity", scale=1 },
	{ skin=rgb(141,91,64), hair=rgb(39,29,25), coat=rgb(178,111,89), pants=rgb(58,53,62), accent=rgb(239,205,146), style="Bob", outfit="Cardigan", scale=.97, glasses=true },
	{ skin=rgb(244,205,165), hair=rgb(136,77,44), coat=rgb(121,104,148), pants=rgb(65,63,73), accent=rgb(213,193,151), style="Bun", outfit="Scarf", scale=1.03 },
	{ skin=rgb(182,126,88), hair=rgb(48,36,29), coat=rgb(85,129,159), pants=rgb(56,62,75), accent=rgb(231,195,112), style="Sweep", outfit="Varsity", scale=.98, glasses=true },
	{ skin=rgb(240,192,145), hair=rgb(158,81,39), coat=rgb(173,121,69), pants=rgb(65,77,66), accent=rgb(235,220,186), style="Beanie", outfit="Scarf", scale=1.02 },
	{ skin=rgb(103,70,51), hair=rgb(40,31,28), coat=rgb(111,139,104), pants=rgb(67,56,51), accent=rgb(231,201,143), style="Curls", outfit="Cardigan", scale=1 },
}
function Style.apply(model,role,variant)
	local p=profiles[(variant-1)%#profiles+1]
	if role=="Baker" then p={skin=rgb(232,185,140),hair=rgb(99,64,40),coat=cream,pants=rgb(62,86,77),accent=rgb(86,139,119),style="Chef",outfit="Apron",scale=1.02}
	elseif role=="Smith" then p={skin=rgb(164,110,77),hair=rgb(57,40,31),coat=rgb(107,119,117),pants=rgb(56,57,61),accent=rgb(113,70,45),style="Smith",outfit="Apron",scale=1.07}
	elseif role=="PackHost" then p={skin=rgb(238,196,153),hair=rgb(73,47,36),coat=rgb(67,119,111),pants=rgb(66,57,78),accent=rgb(221,177,92),style="Beret",outfit="Vest",scale=.98} end
	local head,torso=model.Head,model.Torso
	for _,part in ipairs(model:GetChildren()) do
		if part:IsA("BasePart") then
			part.Color=part.Name:find("Leg") and p.pants or part.Name=="Torso" and p.coat or p.skin
			if part.Name:find("Leg") or part.Name=="Torso" then part.Material=Enum.Material.Fabric end
		end
	end
	local outfit=Instance.new("Folder"); outfit.Name,outfit.Parent="Tailored Outfit",model
	local function add(name,anchor,size,offset,color,shape,material)
		local part=Instance.new("Part")
		part.Name,part.Size,part.CFrame,part.Color=name,size,anchor.CFrame*offset,color
		part.Shape,part.Material=shape or Enum.PartType.Block,material or Enum.Material.SmoothPlastic
		part.CanCollide,part.CanTouch,part.CanQuery,part.Massless=false,false,false,true
		part.TopSurface,part.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
		part.Parent=outfit
		local weld=Instance.new("WeldConstraint"); weld.Part0,weld.Part1,weld.Parent=anchor,part,part
		return part
	end
	local function cloth(name,anchor,size,offset,color)
		return add(name,anchor,size,offset,color,nil,Enum.Material.Fabric)
	end
	local function badge(anchor,x,y,z,radius)
		add("Cookie Medallion",anchor,Vector3.new(.07,radius*2,radius*2),CFrame.new(x,y,z)*CFrame.Angles(0,math.pi/2,0),brass,Enum.PartType.Cylinder)
		for index=1,4 do
			local angle=index*2.4
			add("Medallion Chocolate",anchor,Vector3.new(.055,.055,.035),CFrame.new(x+math.cos(angle)*radius*.52,y+math.sin(angle)*radius*.52,z-.05),cocoa,Enum.PartType.Ball)
		end
	end
	-- Sleeves/cuffs follow the arms, instead of leaving bare blocky shoulders.
	for _,side in ipairs({"Left","Right"}) do
		local arm,leg=model[side.." Arm"],model[side.." Leg"]
		cloth("Tailored Sleeve",arm,Vector3.new(1.035,1.32,1.035),CFrame.new(0,.32,0),p.coat)
		cloth("Sleeve Cuff",arm,Vector3.new(1.06,.15,1.06),CFrame.new(0,-.37,0),p.accent)
		add("Rounded Leather Shoe",leg,Vector3.new(.98,.38,1.16),CFrame.new(0,-.81,-.07),cocoa)
		add("Shoe Sole",leg,Vector3.new(1.01,.09,1.19),CFrame.new(0,-.96,-.07),rgb(38,35,32))
		for i=1,2 do cloth("Shoe Stitch",leg,Vector3.new(.4,.045,.035),CFrame.new(0,-.72-i*.07,-.661),p.accent) end
	end
	cloth("Waistband",torso,Vector3.new(2.025,.14,1.025),CFrame.new(0,-.88,0),p.pants)
	cloth("Shirt Placket",torso,Vector3.new(.12,1.5,.045),CFrame.new(0,0,-.53),p.accent)
	for _,side in ipairs({-1,1}) do
		cloth("Folded Collar",torso,Vector3.new(.42,.34,.075),CFrame.new(side*.29,.77,-.56)*CFrame.Angles(0,0,side*.4),cream)
	end
	for i=1,3 do add("Brass Fastener",torso,Vector3.new(.09,.09,.055),CFrame.new(0,.45-i*.34,-.57),brass,Enum.PartType.Ball,Enum.Material.Metal) end
	if p.outfit=="Apron" then
		cloth("Apron Bib",torso,Vector3.new(1.45,1.5,.08),CFrame.new(0,-.18,-.59),p.accent)
		for _,x in ipairs({-.62,.62}) do cloth("Apron Strap",torso,Vector3.new(.14,.65,.08),CFrame.new(x,.62,-.57),p.accent) end
		cloth("Apron Hem",torso,Vector3.new(1.49,.1,.09),CFrame.new(0,-.9,-.64),cream)
		cloth("Stitched Apron Pocket",torso,Vector3.new(.76,.39,.08),CFrame.new(0,-.48,-.67),p.accent:Lerp(cream,.14))
		cloth("Pocket Piping",torso,Vector3.new(.78,.045,.09),CFrame.new(0,-.29,-.72),cream)
		badge(torso,-.44,.28,-.69,.15)
	elseif p.outfit=="Scarf" then
		cloth("Soft Scarf Wrap",torso,Vector3.new(1.4,.26,1.1),CFrame.new(0,.91,0),p.accent)
		cloth("Scarf Tail",torso,Vector3.new(.36,1,.12),CFrame.new(.49,.32,-.6)*CFrame.Angles(0,0,-.12),p.accent)
		for i=1,3 do cloth("Scarf Fringe",torso,Vector3.new(.055,.17,.1),CFrame.new(.3+i*.1,-.24,-.62),cream) end
	elseif p.outfit=="Cardigan" or p.outfit=="Vest" then
		for _,x in ipairs({-.61,.61}) do
			cloth("Front Pocket",torso,Vector3.new(.48,.37,.07),CFrame.new(x,-.5,-.56),p.coat:Lerp(cream,.16))
		end
		badge(torso,-.58,.45,-.62,.16)
	else
		cloth("Varsity Hem",torso,Vector3.new(2.03,.2,1.03),CFrame.new(0,-.79,0),p.accent)
		badge(torso,-.56,.4,-.61,.23)
	end
	-- Hair stays behind the face; each silhouette reads clearly at player height.
	add("Hair Crown",head,Vector3.new(1.95,.55,1.12),CFrame.new(0,.42,.06),p.hair,Enum.PartType.Ball)
	add("Back Hair",head,Vector3.new(1.75,.65,.24),CFrame.new(0,.12,.51),p.hair,Enum.PartType.Ball)
	if p.style=="Chef" then
		cloth("Chef Hat Band",head,Vector3.new(1.8,.3,1.06),CFrame.new(0,.63,0),cream)
		for _,x in ipairs({-.48,0,.48}) do add("Pleated Toque",head,Vector3.new(.9,.85,1.12),CFrame.new(x,1.02,.04),cream,Enum.PartType.Ball,Enum.Material.Fabric) end
		for _,x in ipairs({-.6,-.3,0,.3,.6}) do cloth("Toque Stitch",head,Vector3.new(.025,.22,.025),CFrame.new(x,.66,-.545),rgb(207,193,168)) end
	elseif p.style=="Cap" or p.style=="Beret" or p.style=="Beanie" then
		add("Cloth Hat Crown",head,Vector3.new(2.04,.78,1.2),CFrame.new(p.style=="Beret" and .16 or 0,.65,.02)*CFrame.Angles(0,0,p.style=="Beret" and -.16 or 0),p.coat,Enum.PartType.Ball,Enum.Material.Fabric)
		cloth("Hat Band",head,Vector3.new(1.92,.18,1.12),CFrame.new(0,.48,0),p.accent)
		if p.style=="Cap" then add("Curved Cap Visor",head,Vector3.new(1.92,.13,.87),CFrame.new(0,.5,-.55),p.coat,Enum.PartType.Ball) end
		if p.style=="Beanie" then add("Hat Pom",head,Vector3.new(.42,.42,.42),CFrame.new(0,1.07,0),p.accent,Enum.PartType.Ball,Enum.Material.Fabric) end
	elseif p.style=="Bob" or p.style=="Bun" then
		for _,x in ipairs({-.86,.86}) do add("Face Framing Hair",head,Vector3.new(.36,1,.92),CFrame.new(x,-.04,.15),p.hair,Enum.PartType.Ball) end
		if p.style=="Bun" then
			add("Pinned Hair Bun",head,Vector3.new(.85,.85,.8),CFrame.new(0,.65,.53),p.hair,Enum.PartType.Ball)
			add("Hair Ribbon",head,Vector3.new(.72,.13,.12),CFrame.new(0,.64,.96),p.accent)
		end
	else
		for i=1,5 do add("Sculpted Hair Lock",head,Vector3.new(.49,.36,.56),CFrame.new((i-3)*.32,.54+(i%2)*.06,-.29)*CFrame.Angles(0,0,-.22),p.hair,Enum.PartType.Ball) end
	end
	if p.glasses or p.style=="Smith" then
		local y=p.style=="Smith" and .57 or .12
		for _,x in ipairs({-.42,.42}) do
			-- Open frames leave the original Roblox eyes visible.
			for _,dy in ipairs({-.16,.16}) do add("Eyewear Rim",head,Vector3.new(.65,.045,.07),CFrame.new(x,y+dy,-.65),cocoa) end
			for _,dx in ipairs({-.30,.30}) do add("Eyewear Side",head,Vector3.new(.045,.32,.07),CFrame.new(x+dx,y,-.65),cocoa) end
			if p.style=="Smith" then
				local lens=add("Forge Safety Lens",head,Vector3.new(.55,.25,.035),CFrame.new(x,y,-.66),brass,nil,Enum.Material.Glass)
				lens.Transparency=.3
			end
		end
		add("Eyewear Bridge",head,Vector3.new(.22,.045,.07),CFrame.new(0,y,-.65),cocoa)
	end
	if role=="Smith" then
		add("Trimmed Beard",head,Vector3.new(1.05,.27,.22),CFrame.new(0,-.43,-.45),p.hair,Enum.PartType.Ball)
		for _,x in ipairs({-.74,.74}) do add("Leather Apron Rivet",torso,Vector3.new(.09,.09,.05),CFrame.new(x,-.12,-.65),brass,Enum.PartType.Ball,Enum.Material.Metal) end
	end
	model:SetAttribute("NPCRole",role)
	model:ScaleTo(p.scale)
end
return Style
