local Lighting = game:GetService("Lighting")
local Presentation = {}

local cream = Color3.fromRGB(255, 239, 210)
local cocoa = Color3.fromRGB(89, 58, 48)
local gold = Color3.fromRGB(255, 211, 129)
local themes = {
	Color3.fromRGB(126, 192, 171), Color3.fromRGB(225, 146, 157),
	Color3.fromRGB(171, 157, 211), Color3.fromRGB(228, 186, 116),
}

local function part(parent, name, size, frame, tint, material)
	local object = Instance.new("Part")
	object.Name = name
	object.Size = size
	object.CFrame = frame
	object.Color = tint
	object.Material = material or Enum.Material.SmoothPlastic
	object.Anchored = true
	object.CanCollide = false
	object.CanTouch = false
	object.CanQuery = false
	object.TopSurface = Enum.SurfaceType.Smooth
	object.BottomSurface = Enum.SurfaceType.Smooth
	object.Parent = parent
	return object
end

local function light(target, brightness, range)
	local object = Instance.new("PointLight")
	object.Color = Color3.fromRGB(255, 218, 157)
	object.Brightness = brightness
	object.Range = range
	object.Shadows = false
	object.Parent = target
	return object
end

function Presentation.lighting()
	Lighting.ClockTime = 15.5
	Lighting.Brightness = 2.2
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.4
	Lighting.Ambient = Color3.fromRGB(130, 112, 112)
	Lighting.OutdoorAmbient = Color3.fromRGB(162, 151, 135)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 239, 217)
	Lighting.EnvironmentDiffuseScale = 0.65
	Lighting.EnvironmentSpecularScale = 0.4
	Lighting.ExposureCompensation = 0.05
	-- LightingStyle replaced the older, restricted Technology property.
	pcall(function() Lighting.LightingStyle = Enum.LightingStyle.Soft end)
	for _, name in ipairs({ "CookieAtmosphere", "CookieBloom", "CookieColor", "CookieSun" }) do
		local previous = Lighting:FindFirstChild(name)
		if previous then previous:Destroy() end
	end
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "CookieAtmosphere"
	atmosphere.Density = 0.2
	atmosphere.Offset = 0.15
	atmosphere.Color = Color3.fromRGB(255, 239, 220)
	atmosphere.Decay = Color3.fromRGB(194, 174, 159)
	atmosphere.Haze = 1.1
	atmosphere.Glare = 0.08
	atmosphere.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Name = "CookieBloom"
	bloom.Intensity = 0.16
	bloom.Size = 24
	bloom.Threshold = 1.65
	bloom.Parent = Lighting
	local correction = Instance.new("ColorCorrectionEffect")
	correction.Name = "CookieColor"
	correction.Brightness = 0.015
	correction.Contrast = 0.08
	correction.Saturation = 0.1
	correction.TintColor = Color3.fromRGB(255, 249, 240)
	correction.Parent = Lighting
	local sun = Instance.new("SunRaysEffect")
	sun.Name = "CookieSun"
	sun.Intensity = 0.025
	sun.Spread = 0.8
	sun.Parent = Lighting
end

function Presentation.world(world)
	for _, object in ipairs(world:GetDescendants()) do
		if object:IsA("BasePart") and object.Name == "Lamp" then light(object, 0.6, 20) end
	end
	for _, x in ipairs({ -14.6, 14.6 }) do
		part(world, "Cream Path Border", Vector3.new(0.7, 0.25, 1140), CFrame.new(x, 0.15, 0), cream, Enum.Material.Concrete)
	end
	for _, x in ipairs({ -485, 485 }) do
		for index = -2, 2 do
			local hill = part(world, "Pastel Meadow Hill", Vector3.new(105, 70, 118), CFrame.new(x, -19, index * 285),
				Color3.fromRGB(139 + (index % 2) * 9, 177, 132), Enum.Material.Grass)
			hill.Shape = Enum.PartType.Ball
		end
	end
	for _, x in ipairs({ -34, 34 }) do
		local seat = part(world, "Plaza Bench", Vector3.new(12, 0.6, 4), CFrame.new(x, 2.1, 0), cocoa, Enum.Material.WoodPlanks)
		seat.CanCollide = true
		for _, offset in ipairs({ -4, 4 }) do
			part(world, "Bench Leg", Vector3.new(0.6, 2, 3), CFrame.new(x + offset, 1, 0), cocoa, Enum.Material.Metal)
		end
		part(world, "Bench Back", Vector3.new(12, 2.7, 0.5), CFrame.new(x, 3.5, 1.8), cream, Enum.Material.WoodPlanks)
	end
	local base = part(world, "Cookie Monument Plinth", Vector3.new(0.7, 10, 10),
		CFrame.new(0, 0.7, 19) * CFrame.Angles(0, 0, math.pi / 2), cream, Enum.Material.Marble)
	base.Shape = Enum.PartType.Cylinder
	part(world, "Monument Pedestal", Vector3.new(5, 3.4, 5), CFrame.new(0, 2.6, 19), cocoa, Enum.Material.Wood)
end

function Presentation.plot(plot, slot)
	local theme = themes[(slot - 1) % #themes + 1]
	plot.theme = theme
	for _, object in ipairs(plot.model:GetDescendants()) do
		if not object:IsA("BasePart") then continue end
		if object.Name == "Texture_WallTile" then object.Color = cream:Lerp(theme, 0.16) end
		if object.Name == "Canopy Stripe" and object.Color.R < 0.85 then object.Color = theme end
		if object.Name == "Texture_BakeryFloor" then
			object.Color = Color3.fromRGB(240, 221, 195)
			object.Material = Enum.Material.SmoothPlastic
		end
	end
	local function frame(x, y, z)
		return CFrame.new(plot.origin + Vector3.new(x * (plot.mirrorX or 1), y, z * plot.direction))
			* CFrame.Angles(0, plot.direction == 1 and 0 or math.pi, 0)
	end
	for column = 0, 3 do
		for row = 0, 5 do
			if (column + row) % 2 == 0 then
				part(plot.model, "Vanilla Floor Tile", Vector3.new(39.8, 0.035, 39.8), frame(-60 + column * 40, 0.525, -100 + row * 40),
					Color3.fromRGB(255, 243, 223))
			end
		end
	end
	part(plot.model, "Bakery Walkway", Vector3.new(7, 0.035, 232), frame(-24, 0.565, 0), theme:Lerp(cream, 0.55))
	for _, x in ipairs({ -60, -30, 0, 30, 60 }) do
		part(plot.model, "Window Frame", Vector3.new(22, 7.6, 0.28), frame(x, 7.1, -119.9), cocoa)
		local window = part(plot.model, "Pastel Window", Vector3.new(20.7, 6.3, 0.3), frame(x, 7.1, -119.65),
			Color3.fromRGB(190, 220, 219), Enum.Material.Glass)
		window.Transparency = 0.15
		part(plot.model, "Window Mullion", Vector3.new(0.3, 6.5, 0.35), frame(x, 7.1, -119.4), cream)
	end
	for _, z in ipairs({ -80, 40, 112 }) do
		for _, x in ipairs({ -77, 77 }) do
			part(plot.model, "String Light Post", Vector3.new(0.5, 16, 0.5), frame(x, 8, z), cocoa, Enum.Material.Wood)
		end
		local previous
		for index = 0, 10 do
			local x = -77 + index * 15.4
			local y = 16 - math.sin(index / 10 * math.pi) * 1.8
			local anchor = frame(x, y, z).Position
			if previous then
				local length = (anchor - previous).Magnitude
				part(plot.model, "Light Cable", Vector3.new(0.07, 0.07, length),
					CFrame.lookAt((anchor + previous) / 2, anchor), cocoa)
			end
			previous = anchor
			if index == 0 or index == 10 then continue end
			local bulb = part(plot.model, "Warm String Bulb", Vector3.new(0.65, 0.85, 0.65), frame(x, y - 0.35, z), gold, Enum.Material.Neon)
			bulb.Shape = Enum.PartType.Ball
			bulb.CastShadow = false
			if index == 3 or index == 7 then light(bulb, 0.3, 27) end
		end
	end
end

function Presentation.oven(oven)
	local chimney = oven:FindFirstChild("Chimney")
	if not chimney then return nil end
	local attachment = Instance.new("Attachment")
	attachment.Position = Vector3.new(0, chimney.Size.Y / 2, 0)
	attachment.Parent = chimney
	local steam = Instance.new("ParticleEmitter")
	steam.Name = "Bakery Steam"
	steam.Texture = "rbxasset://textures/particles/smoke_main.dds"
	steam.Color = ColorSequence.new(Color3.fromRGB(255, 247, 228))
	steam.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1.9) })
	steam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.25, 0.82), NumberSequenceKeypoint.new(1, 1) })
	steam.Lifetime = NumberRange.new(1.5, 2)
	steam.Speed = NumberRange.new(1.2, 1.7)
	steam.Rate = 0.7
	steam.SpreadAngle = Vector2.new(12, 12)
	steam.RotSpeed = NumberRange.new(-20, 20)
	steam.Acceleration = Vector3.new(0.25, 0.5, 0)
	steam.Enabled = false
	steam.Parent = attachment
	return steam
end

return Presentation
