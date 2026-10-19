local Recipes = require(game:GetService("ReplicatedStorage").CookieTycoon.Recipes)
local Assets = require(script.Parent.AssetLibrary)
local Design = {}
function Design.create(index, parent, frame)
	local recipe = Recipes[index]
	local base, accent = Color3.fromRGB(table.unpack(recipe.Color)), Color3.fromRGB(table.unpack(recipe.Accent))
	local model = Instance.new("Model")
	model.Name, model.Parent = recipe.Name .. " Signature Oven", parent
	local family = (index - 1) % 5
	local function p(name, size, x, y, z, color, material, shape)
		local part = Instance.new("Part")
		part.Name, part.Size, part.CFrame, part.Color, part.Material = name, size, frame * CFrame.new(x, y, z), color, material or Enum.Material.Metal
		part.Anchored, part.CanCollide, part.CanTouch, part.Parent = true, true, false, model
		if shape then part.Shape = shape end
		return part
	end
	local body = p("Enamel Oven Body", Vector3.new(4.6, 3.7, 4.5), 0, 0, 0, base:Lerp(Color3.new(1, 1, 1), 0.23), family == 3 and Enum.Material.Brick or Enum.Material.Metal)
	model.PrimaryPart = body
	p("Stone Baking Plinth", Vector3.new(5.3, 0.4, 5), 0, -1.95, 0, accent, Enum.Material.Slate)
	p("Brass Door Frame", Vector3.new(3.7, 2.5, 0.24), 0, -0.15, 2.34, Color3.fromRGB(202, 170, 108))
	p("Window", Vector3.new(3.2, 1.75, 0.1), 0, -0.3, 2.5, Color3.fromRGB(255, 167, 73), Enum.Material.Neon)
	p("Oven Door Handle", Vector3.new(2.5, 0.18, 0.2), 0, 0.85, 2.65, accent)
	for _, x in ipairs({ -1.8, 1.8 }) do
		p("Rounded Casing Edge", Vector3.new(0.35, 3.7, 0.35), x, 0, 2.2, accent)
		p("Dial", Vector3.new(0.38, 0.38, 0.12), x, 1.4, 2.38, Color3.fromRGB(237, 219, 175), Enum.Material.Metal, Enum.PartType.Ball)
	end
	local roof = p("Recipe Canopy", Vector3.new(5.1, 0.5 + family * 0.12, 4.9), 0, 2.0, 0, accent)
	if family == 1 then roof.Shape = Enum.PartType.Ball; roof.Size = Vector3.new(5, 1.5, 4.9) end
	if family == 2 then
		for _, x in ipairs({ -1.8, 0, 1.8 }) do p("Patisserie Crown", Vector3.new(0.5, 0.9, 0.5), x, 2.8, 0, base, Enum.Material.Glass, Enum.PartType.Ball) end
	elseif family == 3 then
		p("Artisan Chimney", Vector3.new(1.1, 1.8, 1.1), -1.2, 3.0, -1.2, accent, Enum.Material.Brick)
	elseif family == 4 then
		for _, x in ipairs({ -1.7, 1.7 }) do p("Crystal Trim", Vector3.new(0.3, 4.3, 0.3), x, 0.3, -2.2, base, Enum.Material.Neon) end
	end
	p("Chimney", Vector3.new(0.7, 0.7, 0.7), 1.4, 2.7, -1.5, Color3.fromRGB(85, 89, 90))
	local badge = p("RecipeBadge", Vector3.new(1.1, 0.35, 1.1), 0, 2.65, 0, base, Enum.Material.SmoothPlastic)
	badge.Transparency = 1
	local cookie = Assets.cookie(index, model, frame * CFrame.new(0, 3.0, 0))
	cookie:ScaleTo(0.45)
	for _, part in ipairs(cookie:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide, part.CanQuery = false, false end end
	return model
end
return Design
