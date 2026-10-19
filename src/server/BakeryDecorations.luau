local W, Assets = require(script.Parent.WorldWidgets), require(script.Parent.AssetLibrary)
local Decor = {}
function Decor.create(plot)
	local groups = {}
	for _, key in ipairs({ "Walls", "Windows", "Door", "Plants", "Trees" }) do
		local group = Instance.new("Model")
		group.Name, group.Parent = key .. " Decoration", plot.model
		groups[key] = group
	end
	if plot.shell then plot.shell:Destroy() end
	local plaster = Color3.fromRGB(231, 213, 185)
	W.part(groups.Walls, "Bakery Back Wall", Vector3.new(164, 12, 1.5), W.position(plot, 0, 6.5, -121), plaster, Enum.Material.Brick)
	W.part(groups.Walls, "Garden Wall", Vector3.new(1.5, 8, 244), W.position(plot, -81, 4.5, 0), plaster, Enum.Material.Brick)
	W.part(groups.Walls, "Road Wall", Vector3.new(1.5, 8, 205), W.position(plot, 81, 4.5, -18.5), plaster, Enum.Material.Brick)
	W.part(groups.Walls, "Entrance End Wall", Vector3.new(1.5, 8, 20), W.position(plot, 81, 4.5, 112), plaster, Enum.Material.Brick)
	W.part(groups.Walls, "Back Wall Cornice", Vector3.new(165, 0.7, 2), W.position(plot, 0, 12.8, -121), Color3.fromRGB(107, 77, 55), Enum.Material.Wood)
	for _, p in ipairs(plot.model:GetChildren()) do
		if p.Name == "Window Frame" or p.Name == "Pastel Window" or p.Name == "Window Mullion" then p.Parent = groups.Windows end
		if p.Name == "Planter" then p.Parent = groups.Plants end
	end
	local function at(x, y, z) return CFrame.new(W.position(plot, x, y, z)) end
	local gold, cream = Color3.fromRGB(195, 159, 95), Color3.fromRGB(245, 232, 206)
	-- A freestanding entrance frame leaves the door opening physically clear.
	for _, z in ipairs({ 87, 101 }) do W.part(groups.Door, "Entrance Column", Vector3.new(2, 14, 2), W.position(plot, 81, 7, z), cream, Enum.Material.Brick) end
	W.part(groups.Door, "Entrance Lintel", Vector3.new(2, 2, 16), W.position(plot, 81, 14, 94), gold, Enum.Material.Wood)
	local door = W.part(groups.Door, "Open Glass Door", Vector3.new(0.25, 11, 6), W.position(plot, 73, 6, 85), Color3.fromRGB(182, 224, 222), Enum.Material.Glass)
	door.CFrame *= CFrame.Angles(0, math.pi / 2, 0)
	door.Transparency, door.CanCollide = 0.55, false
	W.part(groups.Door, "Door Handle", Vector3.new(0.3, 2, 0.3), W.position(plot, 70.5, 6, 85.4), gold, Enum.Material.Metal)
	for _, z in ipairs({ -90, -35, 20, 75 }) do
		local tree = Assets.prop("CookieTree", groups.Trees, at(-74, 0.5, z))
		tree:ScaleTo(0.6)
	end
	for _, x in ipairs({ -68, 68 }) do
		local plant = Assets.prop("Planter", groups.Plants, at(x, 0.5, -110))
		plant:ScaleTo(0.7)
	end
	return groups
end
function Decor.refresh(plot, groups)
	for key, model in pairs(groups) do model.Parent = plot.data and plot.data.life.decorations[key] and plot.model or nil end
end
return Decor
