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
	-- Four angular rock faces form a pointed mountain, with a smaller snow crown.
	for index = 1, 32 do
		local angle = index / 32 * math.pi * 2
		local center = Vector3.new(math.cos(angle) * 740, -8, math.sin(angle) * 890)
		local height, width = random:NextNumber(170, 310), random:NextNumber(120, 205)
		for layer = 1, 2 do
			local size = layer == 1 and Vector3.new(width, height, width) or Vector3.new(width * 0.3, height * 0.3, width * 0.3)
			local base = center + Vector3.new(0, layer == 1 and 0 or height * 0.7, 0)
			for face = 0, 3 do
				local rotation = CFrame.Angles(0, face * math.pi / 2 + angle, 0)
				local rock = Instance.new("CornerWedgePart")
				rock.Name, rock.Size = layer == 1 and "Faceted Mountain Face" or "Snowy Summit", Vector3.new(size.X / 2, size.Y, size.Z / 2)
				rock.CFrame = CFrame.new(base) * rotation * CFrame.new(size.X / 4, size.Y / 2, size.Z / 4)
				rock.Color = layer == 1 and Color3.fromRGB(91 + face * 6, 108 + face * 6, 115 + face * 7) or Color3.fromRGB(231, 238, 234)
				rock.Material, rock.Anchored, rock.CanCollide, rock.Parent = layer == 1 and Enum.Material.Rock or Enum.Material.Snow, true, false, folder
			end
		end
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
	-- Layered slate cliff, a river lip, and two falling ribbons rather than a sphere.
	for layer = 0, 3 do
		local cliff = part(folder, "Waterfall Slate Terrace", Vector3.new(36 - layer * 4, 11, 35 - layer * 3), Vector3.new(-358, 5 + layer * 10, -390), Color3.fromRGB(98 + layer * 6, 114 + layer * 5, 112 + layer * 5), Enum.Material.Slate)
		cliff.CFrame *= CFrame.Angles(0, (layer % 2 == 0 and 1 or -1) * 0.09, 0)
	end
	part(folder, "Waterfall Riverbed", Vector3.new(12, 1, 29), Vector3.new(-351, 42, -400), Color3.fromRGB(109, 121, 113), Enum.Material.Slate)
	local river = part(folder, "Waterfall Source Stream", Vector3.new(10, 0.4, 27), Vector3.new(-351, 42.7, -400), Color3.fromRGB(115, 203, 214), Enum.Material.Glass)
	river.CanCollide, river.Transparency = false, 0.35
	local water = part(folder, "Waterfall Mist Anchor", Vector3.one, Vector3.new(-339, 1, -369), Color3.fromRGB(210, 242, 239))
	water.Transparency, water.CanCollide = 1, false
	for strip = 1, 5 do
		local previous
		for i, pos in ipairs({ Vector3.new(-351 + (strip - 3) * 1.8, 42.7, -386), Vector3.new(-343 + (strip - 3) * 1.9, 22, -377), Vector3.new(-337 + (strip - 3) * 2, 0.7, -368) }) do
			local anchor = Instance.new("Attachment")
			anchor.Position, anchor.Parent = pos - water.Position, water
			if previous then
				local beam = Instance.new("Beam")
				beam.Attachment0, beam.Attachment1, beam.Width0, beam.Width1 = previous, anchor, 2.4, 2.9
				beam.Color, beam.Transparency, beam.FaceCamera = ColorSequence.new(Color3.fromRGB(177, 231, 236)), NumberSequence.new(0.2), true
				beam.Texture, beam.TextureSpeed, beam.TextureLength = "rbxasset://textures/particles/smoke_main.dds", 3.5, 7
				beam.Segments, beam.CurveSize0, beam.CurveSize1, beam.Parent = 12, i == 2 and 7 or 3, 2, water
			end
			previous = anchor
		end
	end
	local spray = Instance.new("ParticleEmitter")
	spray.Texture, spray.Rate, spray.Lifetime, spray.Speed = "rbxasset://textures/particles/smoke_main.dds", 24, NumberRange.new(0.7, 1.8), NumberRange.new(2, 5)
	spray.Size, spray.Transparency, spray.Color = NumberSequence.new(3, 6), NumberSequence.new(0.65, 1), ColorSequence.new(Color3.fromRGB(221, 247, 247))
	spray.SpreadAngle, spray.Parent = Vector2.new(65, 65), water
	for i = 1, 7 do
		local foam = part(folder, "Waterfall Foam", Vector3.new(0.08, 3 + i * 0.7, 3 + i * 0.7), Vector3.new(-337 + math.sin(i) * 5, 0.35, -366 + math.cos(i) * 3), Color3.fromRGB(224, 247, 245))
		foam.Shape, foam.CFrame, foam.Transparency, foam.CanCollide = Enum.PartType.Cylinder, foam.CFrame * CFrame.Angles(0, 0, math.pi / 2), 0.45, false
	end
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
