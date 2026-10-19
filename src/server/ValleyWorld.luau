local Lighting = game:GetService("Lighting")
local Valley = {}
local function part(parent, name, size, position, color, material)
	local p = Instance.new("Part")
	p.Name, p.Size, p.Position, p.Color, p.Material = name, size, position, color, material or Enum.Material.SmoothPlastic
	p.Anchored, p.TopSurface, p.BottomSurface, p.Parent = true, Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth, parent
	return p
end
function Valley.create(parent)
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "Cookie Mountain Valley", parent
	for _, object in ipairs(Lighting:GetChildren()) do if object:IsA("Sky") then object:Destroy() end end
	local sky = Instance.new("Sky")
	sky.Name, sky.CelestialBodiesShown, sky.StarCount, sky.Parent = "Mountain Valley Sky", false, 3000, Lighting
	local random = Random.new(23057)
	for _, z in ipairs({ -297, 297 }) do
		part(folder, "Fast Road", Vector3.new(24, 0.12, 546), Vector3.new(0, 0.5, z), Color3.fromRGB(72, 76, 77), Enum.Material.Asphalt)
	end
	for z = -550, 550, 20 do
		if math.abs(z) > 25 then
			local stripe = part(folder, "Road Speed Stripe", Vector3.new(0.4, 0.04, 7), Vector3.new(0, 0.58, z), Color3.fromRGB(246, 205, 111))
			stripe.CanCollide = false
		end
	end
	for index = 1, 48 do
		local angle = index / 48 * math.pi * 2
		local position = Vector3.new(math.cos(angle) * 720, 15, math.sin(angle) * 850)
		local height = random:NextNumber(150, 290)
		local mountain = part(folder, "Valley Mountain", Vector3.new(190, height, 180), position + Vector3.new(0, height / 2 - 45, 0), Color3.fromRGB(94, 117, 127), Enum.Material.Rock)
		mountain.Shape = Enum.PartType.Ball
		local peak = part(folder, "Snow Peak", Vector3.new(100, height * 0.28, 95), position + Vector3.new(0, height - 65, 0), Color3.fromRGB(230, 239, 235), Enum.Material.Snow)
		peak.Shape = Enum.PartType.Ball
		mountain.CanCollide, peak.CanCollide = false, false
	end
	for index = 1, 175 do
		local x = (index % 2 == 0 and -1 or 1) * random:NextNumber(225, 425)
		local z = random:NextNumber(-570, 570)
		local lake = x < -205 and z > -450 and z < -295
		local mine = x < -210 and math.abs(z - 120) < 75
		local obby = x > 215 and (math.abs(z) < 45 or math.abs(z - 180) < 45 or math.abs(z + 180) < 45)
		if lake or mine or obby or math.abs(z) < 22 then continue end
		local height = random:NextNumber(12, 23)
		local pos = Vector3.new(x, 0, z)
		part(folder, "Cookie Tree Trunk", Vector3.new(2.2, height, 2.2), pos + Vector3.new(0, height / 2, 0), Color3.fromRGB(100, 68, 43), Enum.Material.Wood)
		local crown = part(folder, "Cookie Forest Canopy", Vector3.new(17, 15, 17), pos + Vector3.new(0, height, 0), Color3.fromRGB(random:NextInteger(69, 104), random:NextInteger(126, 158), 85), Enum.Material.Grass)
		crown.Shape, crown.CanCollide = Enum.PartType.Ball, false
		for fruit = 1, 3 do
			local angle = fruit / 3 * math.pi * 2
			local center = pos + Vector3.new(math.cos(angle) * 7, height - 3, math.sin(angle) * 7)
			local cookie = part(folder, "Tree Cookie", Vector3.new(0.5, 3.4, 3.4), center, Color3.fromRGB(201, 148, 82))
			cookie.Shape, cookie.CanCollide = Enum.PartType.Cylinder, false
			for chip = 1, 5 do
				local c = part(folder, "Chocolate Chip", Vector3.new(0.2, 0.45, 0.45), center + Vector3.new(0.3, math.sin(chip * 2) * 1.1, math.cos(chip * 2) * 1.1), Color3.fromRGB(69, 43, 30))
				c.Shape, c.CanCollide = Enum.PartType.Ball, false
			end
		end
	end
	workspace.Terrain:FillBlock(CFrame.new(-285, -14, -370), Vector3.new(140, 4, 110), Enum.Material.Rock)
	workspace.Terrain:FillBlock(CFrame.new(-285, -6, -370), Vector3.new(140, 12, 110), Enum.Material.Water)
	workspace.Terrain.WaterColor, workspace.Terrain.WaterTransparency = Color3.fromRGB(63, 158, 178), 0.3
	workspace.Terrain.WaterReflectance, workspace.Terrain.WaterWaveSize = 0.35, 0.12
	for index = 1, 18 do
		local a = index / 18 * math.pi * 2
		local rock = part(folder, "Lake Shore", Vector3.new(16, 5, 13), Vector3.new(-285 + math.cos(a) * 72, -1, -370 + math.sin(a) * 57), Color3.fromRGB(128, 138, 131), Enum.Material.Slate)
		rock.Shape = Enum.PartType.Ball
	end
	local cliff = part(folder, "Waterfall Cliff", Vector3.new(40, 45, 45), Vector3.new(-356, 17, -390), Color3.fromRGB(112, 126, 126), Enum.Material.Rock)
	cliff.Shape = Enum.PartType.Ball
	local water = part(folder, "Waterfall", Vector3.new(12, 36, 1.8), Vector3.new(-339, 18, -370), Color3.fromRGB(155, 223, 229), Enum.Material.Glass)
	water.Transparency, water.CanCollide = 0.25, false
	local source = Instance.new("Attachment")
	source.Position, source.Parent = Vector3.new(0, 18, 0), water
	local falling = Instance.new("ParticleEmitter")
	falling.Texture, falling.EmissionDirection, falling.Rate = "rbxasset://textures/particles/smoke_main.dds", Enum.NormalId.Bottom, 14
	falling.Lifetime, falling.Speed, falling.Acceleration, falling.SpreadAngle = NumberRange.new(1, 1.5), NumberRange.new(18, 22), Vector3.new(0, -30, 0), Vector2.new(15, 2)
	falling.Size, falling.Transparency, falling.Color, falling.Parent = NumberSequence.new(2), NumberSequence.new(0.65, 1), ColorSequence.new(Color3.fromRGB(209, 244, 247)), source
	local spray = Instance.new("ParticleEmitter")
	spray.Texture, spray.Rate, spray.Lifetime, spray.Speed = "rbxasset://textures/particles/smoke_main.dds", 10, NumberRange.new(0.8, 1.5), NumberRange.new(1, 4)
	spray.Size, spray.Transparency, spray.Color = NumberSequence.new(4), NumberSequence.new(0.7, 1), ColorSequence.new(Color3.fromRGB(212, 245, 246))
	local foam = part(folder, "Waterfall Foam", Vector3.new(16, 0.2, 7), Vector3.new(-339, 0.2, -370), Color3.fromRGB(224, 247, 245))
	foam.Transparency, foam.CanCollide, spray.Parent = 0.35, false, foam
	for index = 0, 18 do
		part(folder, "Lake Footbridge Plank", Vector3.new(7.4, 0.5, 8), Vector3.new(-355 + index * 7.5, 2.5 + math.sin(index / 18 * math.pi) * 3, -337), Color3.fromRGB(137, 99, 64), Enum.Material.WoodPlanks)
	end
	local epoch = os.clock()
	task.spawn(function()
		while folder.Parent do
			local hour = (9 + (os.clock() - epoch) * 24 / 1200) % 24
			local daylight = math.clamp(math.sin((hour - 6) / 12 * math.pi) * 1.6, 0, 1)
			Lighting.ClockTime, Lighting.Brightness = hour, 0.9 + daylight * 1.5
			Lighting.Ambient = Color3.fromRGB(57, 69, 92):Lerp(Color3.fromRGB(131, 139, 149), daylight)
			Lighting.OutdoorAmbient = Color3.fromRGB(66, 83, 113):Lerp(Color3.fromRGB(157, 171, 183), daylight)
			Lighting.ExposureCompensation = 0.05 + (1 - daylight) * 0.08
			task.wait(0.5)
		end
	end)
	return folder
end
return Valley
