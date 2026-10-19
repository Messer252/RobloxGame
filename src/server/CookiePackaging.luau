local Packaging = {}
local function piece(model, root, name, size, offset, color, transparency)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color = name, size, CFrame.new(root.Position + offset), color
	p.Transparency, p.CanCollide, p.CanTouch, p.CanQuery, p.Massless, p.Parent = transparency or 0, false, false, false, true, model
	local weld = Instance.new("WeldConstraint")
	weld.Part0, weld.Part1, weld.Parent = root, p, p
	return p
end
function Packaging.wrap(model, root, scale)
	if model:FindFirstChild("Cookie Wrapper") then return end
	local s = scale or 1
	local p = piece(model, root, "Cookie Wrapper", Vector3.new(4.1, 0.7, 4.1) * s, Vector3.zero, Color3.fromRGB(220, 243, 241), 0.72)
	p.Material = Enum.Material.Glass
end
function Packaging.box(model, root, scale)
	if model:FindFirstChild("Cookie Box Base") then return end
	local s, color = scale or 1, Color3.fromRGB(192, 150, 94)
	piece(model, root, "Cookie Box Base", Vector3.new(4.8, 0.12, 4.8) * s, Vector3.new(0, -0.3, 0) * s, color)
	for _, x in ipairs({ -2.35, 2.35 }) do piece(model, root, "Cookie Box Wall", Vector3.new(0.12, 0.8, 4.8) * s, Vector3.new(x, 0.1, 0) * s, color) end
	for _, z in ipairs({ -2.35, 2.35 }) do piece(model, root, "Cookie Box Wall", Vector3.new(4.8, 0.8, 0.12) * s, Vector3.new(0, 0.1, z) * s, color) end
end
return Packaging
