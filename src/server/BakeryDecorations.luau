local W, Assets = require(script.Parent.WorldWidgets), require(script.Parent.AssetLibrary)
local Polish = require(game:GetService("ReplicatedStorage").CookieTycoon.BakeryPolish)
local Decor = {}
function Decor.create(plot)
	local groups = {}
	for _, key in ipairs(Polish.DecorationOrder) do
		local group = Instance.new("Model")
		group.Name, group.Parent = key .. " Decoration", plot.model
		groups[key] = group
	end
	if plot.shell then plot.shell:Destroy() end
	for _, p in ipairs(plot.model:GetChildren()) do
		if p.Name == "Window Frame" or p.Name == "Pastel Window" or p.Name == "Window Mullion" then p:Destroy() end
		if p.Name == "Planter" then p.Parent = groups.Plants end
		if p.Name:find("String") or p.Name == "Light Cable" or p.Name == "Warm String Bulb" then p.Parent = groups.Lights end
	end
	local plaster, wood, gold, cream = Color3.fromRGB(231, 216, 192), Color3.fromRGB(115, 81, 59), Color3.fromRGB(195, 159, 95), Color3.fromRGB(245, 232, 206)
	local function p(key, name, size, x, y, z, color, material)
		return W.part(groups[key], name, size, W.position(plot, x, y, z), color, material)
	end
	-- Real openings in one wall, with matching frames/panes rather than floating windows.
	p("Walls", "Window Sill Wall", Vector3.new(164, 5, 1.5), 0, 3, -121, plaster, Enum.Material.Brick)
	p("Walls", "Window Header Wall", Vector3.new(164, 5, 1.5), 0, 16, -121, plaster, Enum.Material.Brick)
	for _, x in ipairs({ -73.5, -42, -14, 14, 42, 73.5 }) do p("Walls", "Window Pier", Vector3.new(math.abs(x) == 73.5 and 17 or 10, 8, 1.5), x, 9.5, -121, plaster, Enum.Material.Brick) end
	p("Walls", "Garden Wall", Vector3.new(1.5, 18, 244), -81, 9.5, 0, plaster, Enum.Material.Brick)
	p("Walls", "Road Wall", Vector3.new(1.5, 18, 205), 81, 9.5, -18.5, plaster, Enum.Material.Brick)
	p("Walls", "Entrance End Wall", Vector3.new(1.5, 18, 20), 81, 9.5, 112, plaster, Enum.Material.Brick)
	p("Walls", "Door Header", Vector3.new(1.5, 5, 18), 81, 16, 93, plaster, Enum.Material.Brick)
	for _, x in ipairs({ -56, -28, 0, 28, 56 }) do
		for _, side in ipairs({ -9.2, 9.2 }) do p("Windows", "Window Jamb", Vector3.new(0.6, 8, 2), x + side, 9.5, -121, wood) end
		for _, y in ipairs({ 5.6, 13.4 }) do p("Windows", "Window Frame", Vector3.new(19, 0.6, 2), x, y, -121, wood) end
		local glass = p("Windows", "Fitted Glass", Vector3.new(17.8, 7.4, 0.2), x, 9.5, -121, Color3.fromRGB(178, 216, 220), Enum.Material.Glass)
		glass.Transparency = 0.6
		p("Windows", "Window Mullion", Vector3.new(0.2, 7.5, 0.4), x, 9.5, -120.7, cream)
	end
	local leaf = Instance.new("Model")
	leaf.Name, leaf.Parent = "Hinged Door Leaf", groups.Door
	local hinge = W.position(plot, 81, 0.5, 85)
	leaf.WorldPivot = CFrame.new(hinge)
	for _, z in ipairs({ 85, 101 }) do p("Door", "Door Jamb", Vector3.new(1.8, 13, 0.8), 81, 7, z, wood) end
	p("Door", "Door Frame Header", Vector3.new(1.8, 0.8, 16.8), 81, 13.5, 93, wood)
	local pane = p("Door", "Door Glass", Vector3.new(0.25, 12, 14.4), 81, 7, 93, Color3.fromRGB(179, 222, 219), Enum.Material.Glass)
	pane.Transparency, pane.Parent = 0.55, leaf
	for _, z in ipairs({ 85.7, 100.3 }) do local edge = p("Door", "Door Stile", Vector3.new(0.5, 12.7, 0.5), 81, 7, z, wood); edge.Parent = leaf end
	for _, y in ipairs({ 1, 13 }) do local edge = p("Door", "Door Rail", Vector3.new(0.5, 0.6, 15), 81, y, 93, wood); edge.Parent = leaf end
	local handle = p("Door", "Door Handle", Vector3.new(0.35, 2, 0.3), 80.5, 7, 98.5, gold, Enum.Material.Metal)
	handle.Parent = leaf
	for _, y in ipairs({ 3, 11 }) do p("Door", "Visible Hinge", Vector3.new(0.8, 0.9, 0.9), 81, y, 85.7, gold, Enum.Material.Metal) end
	local value, open, busy = Instance.new("CFrameValue"), false, false
	value.Value, value.Parent = CFrame.new(hinge), groups.Door
	value.Changed:Connect(function(cf) leaf:PivotTo(cf) end)
	W.prompt(handle, "Open / close door", 0, function()
		if busy then return end
		busy, open = true, not open
		local target = CFrame.new(hinge) * CFrame.Angles(0, open and math.rad(95) * (plot.mirrorX or 1) * plot.direction or 0, 0)
		game:GetService("TweenService"):Create(value, TweenInfo.new(0.45), { Value = target }):Play()
		task.delay(0.5, function() busy = false end)
	end)
	for _, side in ipairs({ -1, 1 }) do
		local roof = p("Roof", "Pitched Roof", Vector3.new(61, 0.7, 247), side * 51, 23, 0, wood, Enum.Material.WoodPlanks)
		roof.CFrame *= CFrame.Angles(0, 0, -side * (plot.mirrorX or 1) * 0.14)
	end
	local skylight = p("Roof", "Long Skylight", Vector3.new(43, 0.4, 245), 0, 27, 0, Color3.fromRGB(195, 226, 229), Enum.Material.Glass)
	skylight.Transparency = 0.65
	for _, x in ipairs({ -45, 0, 45 }) do for _, z in ipairs({ -70, 20, 85 }) do
		p("Lights", "Pendant Cable", Vector3.new(0.1, 5, 0.1), x, 22, z, wood)
		local lamp = p("Lights", "Pendant Shade", Vector3.new(3, 0.4, 3), x, 19.5, z, cream, Enum.Material.Neon)
		lamp.CanCollide = false
		local light = Instance.new("PointLight")
		light.Color, light.Range, light.Brightness, light.Parent = Color3.fromRGB(255, 223, 171), 30, 0.8, lamp
	end end
	for _, z in ipairs({ -90, -35, 20, 75 }) do Assets.prop("CookieTree", groups.Trees, CFrame.new(W.position(plot, -74, 0.5, z))):ScaleTo(0.6) end
	for _, x in ipairs({ -68, 68 }) do Assets.prop("Planter", groups.Plants, CFrame.new(W.position(plot, x, 0.5, -110))):ScaleTo(0.7) end
	for i = 1, 20 do
		local tile = p("Floor", "Herringbone Tile", Vector3.new(8, 0.04, 12), -68 + (i % 4) * 40, 0.62, -105 + math.floor(i / 4) * 40, cream, Enum.Material.WoodPlanks)
		tile.CFrame *= CFrame.Angles(0, i % 2 == 0 and 0.6 or -0.6, 0)
	end
	local plaque = p("Signs", "Bakery Plaque", Vector3.new(0.5, 5, 14), 80.5, 16, 94, gold)
	W.label(plaque, "FRESHLY BAKED", 60)
	for _, z in ipairs({ 105, -105 }) do
		p("Benches", "Cafe Seat", Vector3.new(12, 0.5, 4), -58, 2, z, wood)
		for _, x in ipairs({ -63, -53 }) do p("Benches", "Seat Leg", Vector3.new(0.7, 2, 3), x, 1, z, wood) end
	end
	local bowl = p("Fountain", "Fountain Bowl", Vector3.new(0.8, 12, 12), -60, 1, -70, cream, Enum.Material.Marble)
	bowl.Shape, bowl.CFrame = Enum.PartType.Cylinder, bowl.CFrame * CFrame.Angles(0, 0, math.pi/2)
	local water = p("Fountain", "Fountain Water", Vector3.new(0.2, 10, 10), -60, 1.5, -70, Color3.fromRGB(124, 197, 204), Enum.Material.Glass)
	water.Shape, water.CFrame, water.Transparency = Enum.PartType.Cylinder, water.CFrame * CFrame.Angles(0, 0, math.pi/2), 0.35
	Assets.cookie(1, groups.Fountain, CFrame.new(W.position(plot, -60, 4, -70))):ScaleTo(1.2)
	local case = p("Display", "Glass Cookie Case", Vector3.new(12, 4, 5), 60, 4, -108, Color3.fromRGB(186, 220, 218), Enum.Material.Glass)
	case.Transparency = 0.7
	for i = 1, 4 do Assets.cookie(i, groups.Display, CFrame.new(W.position(plot, 53 + i*2.5, 3, -108))):ScaleTo(0.45) end
	for _, z in ipairs({ -112, 110 }) do
		p("FlowerBeds", "Flower Bed", Vector3.new(20, 0.8, 5), -45, 0.8, z, wood)
		for i = 1, 7 do local flower = p("FlowerBeds", "Flower", Vector3.one, -55 + i*2.5, 1.8, z, Color3.fromHSV(i/9, 0.4, 1)); flower.Shape = Enum.PartType.Ball; flower.CanCollide = false end
	end
	for _, z in ipairs({ -45, 30 }) do Assets.prop("WoodenFence", groups.Fence, CFrame.new(W.position(plot, -77, 0.5, z))) end
	return groups
end
function Decor.refresh(plot, groups)
	for key, model in pairs(groups) do model.Parent = plot.data and plot.data.life.decorations[key] and plot.model or nil end
end
return Decor
