local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Recipes = require(ReplicatedStorage.CookieTycoon.Recipes)
local Crafting = require(ReplicatedStorage.CookieTycoon.CookieCrafting)
local TextureIds = require(script.Parent.AssetTextures)
local templates = ServerStorage:WaitForChild("CookieCornerAssets")
local AssetLibrary = {}

local allFaces = { Enum.NormalId.Top, Enum.NormalId.Bottom, Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }
local sideFaces = { Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }
local topFace = { Enum.NormalId.Top }
local rules = {
	BakeryFloor = { Faces = topFace, Tile = 16 },
	WallTile = { Faces = sideFaces, Tile = 8 },
	WoodWarm = { Faces = allFaces, Tile = 8 },
	BrushedMetal = { Faces = allFaces, Tile = 8 },
	ConveyorRubber = { Faces = topFace, Tile = 4 },
	OvenBrick = { Faces = sideFaces, Tile = 8 },
	Parchment = { Faces = topFace, Tile = 5 },
	GoldenChip = { Faces = { Enum.NormalId.Right, Enum.NormalId.Left }, Tile = 4 },
	AwningStripe = { Faces = { Enum.NormalId.Top, Enum.NormalId.Bottom }, Tile = 20 },
	CounterMarble = { Faces = topFace, Tile = 8 },
	MeadowGrass = { Faces = topFace, Tile = 12 },
	PathPavers = { Faces = topFace, Tile = 6 },
}

function AssetLibrary.texture(target, key)
	local configured = TextureIds[key]
	if type(configured) ~= "string" or configured == "" then return end
	local digits = configured:match("^(%d+)$") or configured:match("^rbxassetid://(%d+)$")
	if not digits or tonumber(digits) == 0 then
		warn("Cookie Corner: ignored an invalid image asset ID for " .. key)
		return
	end
	local rule = rules[key]
	if key:match("^Cookie%d%d$") then
		-- Native cylinders point along local X. Right faces upward after rotation.
		rule = { Faces = { Enum.NormalId.Right }, Tile = 3.35 }
	end
	if not rule then return end
	for _, face in ipairs(rule.Faces) do
		local texture = Instance.new("Texture")
		texture.Name = "CookieCorner_" .. key .. "_" .. face.Name
		texture.Texture = "rbxassetid://" .. digits
		texture.Face = face
		texture.StudsPerTileU = rule.Tile
		texture.StudsPerTileV = rule.Tile
		texture.Parent = target
	end
end

function AssetLibrary.clone(category, name, parent, pivot)
	local folder = assert(templates:FindFirstChild(category), "Missing asset category: " .. category)
	local template = assert(folder:FindFirstChild(name), "Missing model: " .. name)
	local object = template:Clone()
	for _, descendant in ipairs(object:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local key = descendant.Name:match("^Texture_(.+)$")
			if key then AssetLibrary.texture(descendant, key) end
		end
	end
	object:PivotTo(pivot)
	object.Parent = parent
	return object
end

function AssetLibrary.prop(name, parent, pivot)
	return AssetLibrary.clone("Props", name, parent, pivot)
end

function AssetLibrary.cookie(index, parent, pivot, flags)
	local object = AssetLibrary.clone("Cookies", Recipes[index].Name, nil, pivot)
	local rarity = Crafting.rarity(Recipes[index])
	object.Name = rarity.Name .. " " .. Recipes[index].Name .. " (" .. Crafting.summary(flags) .. ")"
	object:SetAttribute("Rarity", rarity.Name)
	object:SetAttribute("ModifierMask", Crafting.encode(flags))
	local outline = Instance.new("Highlight")
	outline.Name = "RarityOutline"
	outline.Adornee = object
	outline.DepthMode = Enum.HighlightDepthMode.Occluded
	outline.FillTransparency = 1
	outline.OutlineColor = Color3.fromRGB(table.unpack(rarity.Color))
	outline.OutlineTransparency = rarity.Name == "Common" and 0.45 or 0.1
	outline.Parent = object
	local surface = object:FindFirstChild("Vanilla Frosting") and 0.41 or 0.295
	local function topping(name, size, offset, rgb, rotation, shape)
		local piece = Instance.new("Part")
		piece.Name = name
		piece.Size = size
		piece.CFrame = pivot * CFrame.new(offset) * (rotation or CFrame.new())
		piece.Color = Color3.fromRGB(table.unpack(rgb))
		piece.Material = Enum.Material.SmoothPlastic
		piece.Shape = shape or Enum.PartType.Block
		piece.Anchored = true
		piece.CanCollide = false
		piece.CanTouch = false
		piece.CanQuery = false
		piece.TopSurface = Enum.SurfaceType.Smooth
		piece.BottomSurface = Enum.SurfaceType.Smooth
		piece.Parent = object
		return piece
	end
	if flags and flags.Glaze then
		local glaze = topping("Glaze", Vector3.new(0.08, 3.05, 3.05), Vector3.new(0, surface + 0.045, 0),
			Crafting.Modifiers.Glaze.Color, CFrame.Angles(0, 0, math.pi / 2), Enum.PartType.Cylinder)
		glaze.Transparency = 0.25
		for _, x in ipairs({ -1.4, 1.4 }) do
			topping("Glaze Drip", Vector3.new(0.24, 0.3, 0.25), Vector3.new(x, surface - 0.05, 0.3),
				Crafting.Modifiers.Glaze.Color, nil, Enum.PartType.Ball)
		end
		surface += 0.085
	end
	if flags and flags.Sprinkles then
		local colors = { { 255, 101, 152 }, { 91, 220, 205 }, { 255, 218, 82 }, { 164, 133, 255 } }
		for number = 1, 6 do
			local angle = number * 2.399963
			local radius = 0.3 + number * 0.15
			topping("Added Sprinkles", Vector3.new(0.12, 0.09, 0.38), Vector3.new(math.cos(angle) * radius, surface + 0.05, math.sin(angle) * radius),
				colors[(number - 1) % #colors + 1], CFrame.Angles(0, angle, 0))
		end
	end
	if flags and flags.ChocolateDrizzle then
		for number = -1, 1 do
			topping("Chocolate Drizzle", Vector3.new(0.13, 0.09, 2.45), Vector3.new(number * 0.6, surface + 0.065, 0),
				Crafting.Modifiers.ChocolateDrizzle.Color, CFrame.Angles(0, -0.35, 0))
		end
	end
	if flags and flags.CaramelSwirl then
		for number = 1, 6 do
			local angle = number * math.pi / 3
			local radius = 0.4 + number * 0.1
			topping("Caramel Swirl", Vector3.new(0.65, 0.08, 0.15), Vector3.new(math.cos(angle) * radius, surface + 0.09, math.sin(angle) * radius),
				Crafting.Modifiers.CaramelSwirl.Color, CFrame.Angles(0, -angle + math.pi / 2, 0))
		end
	end
	if flags and flags.GoldLeaf then
		for number = 1, 3 do
			local angle = number * math.pi * 2 / 3
			local leaf = topping("Gold Leaf", Vector3.new(0.4, 0.06, 0.28), Vector3.new(math.cos(angle) * 0.8, surface + 0.13, math.sin(angle) * 0.8),
				Crafting.Modifiers.GoldLeaf.Color, CFrame.Angles(0, angle, 0))
			leaf.Material = Enum.Material.Metal
		end
	end
	object.Parent = parent
	if parent and (rarity.Name == "Legendary" or rarity.Name == "Mythic") then
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Name = "Rare Cookie Sparkle"
		sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparkle.Color = ColorSequence.new(Color3.fromRGB(table.unpack(rarity.Color)))
		sparkle.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0) })
		sparkle.Transparency = NumberSequence.new(0.1, 1)
		sparkle.Lifetime = NumberRange.new(0.4, 0.7)
		sparkle.Speed = NumberRange.new(0.5, 1.5)
		sparkle.SpreadAngle = Vector2.new(120, 120)
		sparkle.LightEmission = 0.5
		sparkle.Rate = 2
		sparkle.Parent = object.PrimaryPart
		sparkle:Emit(3)
	end
	return object
end

function AssetLibrary.anchor(object)
	return object:FindFirstChild("LabelAnchor") or object.PrimaryPart
end

return AssetLibrary
