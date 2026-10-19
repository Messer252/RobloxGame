local W = require(script.Parent.WorldWidgets)
local Cave = {}
function Cave.create(parent)
	local stone, dark = Color3.fromRGB(89, 79, 73), Color3.fromRGB(57, 51, 50)
	local function rock(name, size, pos, angle)
		local p = Instance.new("WedgePart")
		p.Name, p.Size, p.CFrame, p.Color, p.Material = name, size, CFrame.new(pos) * CFrame.Angles(0, angle or 0, 0), stone, Enum.Material.Slate
		p.Anchored, p.Parent = true, parent
		return p
	end
	W.part(parent, "Cave Floor", Vector3.new(135, 1, 166), Vector3.new(-320, 0, 108), dark, Enum.Material.Rock)
	W.part(parent, "Cave Ceiling", Vector3.new(135, 8, 166), Vector3.new(-320, 26, 108), stone, Enum.Material.Slate)
	W.part(parent, "Cave Back Wall", Vector3.new(9, 32, 166), Vector3.new(-387, 13, 108), stone, Enum.Material.Rock)
	for _, z in ipairs({ 25, 191 }) do
		W.part(parent, "Cave Side Wall", Vector3.new(135, 32, 9), Vector3.new(-320, 13, z), stone, Enum.Material.Rock)
		for i = 1, 7 do rock("Faceted Cave Buttress", Vector3.new(17, 24 + i % 3 * 4, 16), Vector3.new(-260 - i * 17, 12, z + (z < 100 and 7 or -7)), i * 0.8) end
	end
	for _, z in ipairs({ 55, 153 }) do W.part(parent, "Cave Entrance Pillar", Vector3.new(12, 31, 67), Vector3.new(-251, 14, z), stone, Enum.Material.Rock) end
	W.part(parent, "Cave Entrance Lintel", Vector3.new(16, 12, 42), Vector3.new(-250, 24, 104), dark, Enum.Material.Slate)
	for _, z in ipairs({ 85, 123 }) do
		W.part(parent, "Mine Timber Upright", Vector3.new(3, 21, 3), Vector3.new(-244, 10.5, z), Color3.fromRGB(119, 80, 47), Enum.Material.Wood)
	end
	W.part(parent, "Mine Timber Header", Vector3.new(4, 3, 44), Vector3.new(-244, 21, 104), Color3.fromRGB(119, 80, 47), Enum.Material.Wood)
	for index = 1, 10 do
		local x, z = -268 - (index % 5) * 24, index <= 5 and 40 or 175
		rock("Hanging Cave Crystal", Vector3.new(3, 8, 3), Vector3.new(x, 20, z), index)
		local lamp = W.part(parent, "Amber Cave Lantern", Vector3.new(1, 1.6, 1), Vector3.new(x, 12, z), Color3.fromRGB(255, 207, 126), Enum.Material.Neon)
		lamp.CanCollide = false
		local light = Instance.new("PointLight")
		light.Color, light.Brightness, light.Range, light.Parent = lamp.Color, 1.5, 32, lamp
	end
	for index = 1, 8 do
		local x = -274 - index * 12
		rock("Rocky Cave Roof", Vector3.new(20, 16, 174), Vector3.new(x, 30, 108), index % 2 * math.pi)
	end
end
function Cave.health(node)
	local gui = node.label.Parent
	gui.StudsOffsetWorldSpace, gui.StudsOffset, gui.AlwaysOnTop = Vector3.new(0, 6, 0), Vector3.zero, true
	gui.Size, gui.MaxDistance = UDim2.fromOffset(160, 52), 30
	node.label.Size, node.label.BackgroundTransparency, node.label.TextSize = UDim2.new(1, 0, 0, 28), 1, 13
	local track = Instance.new("Frame")
	track.Position, track.Size, track.BackgroundColor3, track.BorderSizePixel, track.Parent = UDim2.fromOffset(5, 31), UDim2.new(1, -10, 0, 10), Color3.fromRGB(45, 35, 29), 0, gui
	local bar = Instance.new("Frame")
	bar.Size, bar.BackgroundColor3, bar.BorderSizePixel, bar.Parent = UDim2.fromScale(1, 1), Color3.fromRGB(242, 196, 103), 0, track
	for _, element in ipairs({ track, bar }) do local corner = Instance.new("UICorner"); corner.CornerRadius, corner.Parent = UDim.new(1, 0), element end
	node.bar = bar
end
return Cave
