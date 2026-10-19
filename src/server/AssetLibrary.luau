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
	object.Name = rarity.Name .. " " .. Recipes[index].Name .. " (" .. Crafting.summary(flags, index) .. ")"
	object:SetAttribute("Rarity", rarity.Name)
	object:SetAttribute("ModifierMask", Crafting.encode(flags))
	local outline = Instance.new("Highlight")
	outline.Name = "RarityOutline"
	outline.Adornee = object
	outline.DepthMode = Enum.HighlightDepthMode.Occluded
	outline.FillTransparency = 1
	outline.OutlineColor = Color3.fromRGB(table.unpack(rarity.Color))
	outline.OutlineTransparency = rarity.Name == "Common" and 1 or 0.35
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
	for slot, key in ipairs({ "Glaze", "Sprinkles" }) do
		if not flags or not flags[key] then continue end
		local option = Crafting.option(index, key)
		local shade = option.Color
		if option.Style == "Cream" or option.Style == "Flakes" then shade = { 248, 233, 197 } end
		if option.Style == "Dust" then shade = Recipes[index].Color end
		for n = 1, option.Style == "Dust" and 10 or 5 do
			local angle, radius = n * 2.399 + slot, 0.4 + (n % 4) * 0.25
			local shape, size = Enum.PartType.Ball, Vector3.new(.27, .18, .24)
			if option.Style == "Flakes" or option.Style == "Sprinkles" or option.Style == "Seeds" then shape, size = Enum.PartType.Block, Vector3.new(.1, .06, .33)
			elseif option.Style == "Dust" then size = Vector3.new(.07, .025, .07)
			elseif option.Style == "Cream" then size = Vector3.new(.35, .24, .35)
			elseif option.Style == "Fruit" then size = Vector3.new(.3, .15, .42)
			elseif option.Style == "Chunks" or option.Style == "Crystals" then shape, size = Enum.PartType.Block, Vector3.new(.25, .2, .22)
			elseif option.Style == "Swirl" then shape, size = Enum.PartType.Block, Vector3.new(.1, .07, .65) end
			local tint = option.Style == "Sprinkles" and ({ { 248, 155, 177 }, { 134, 211, 184 }, { 242, 203, 112 } })[n % 3 + 1] or shade
			topping(option.Name, size, Vector3.new(math.cos(angle)*radius, surface + .06 + (slot-1)*.035, math.sin(angle)*radius), tint, CFrame.Angles(0, angle, 0), shape)
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
