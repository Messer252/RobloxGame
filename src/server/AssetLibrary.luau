local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Recipes = require(ReplicatedStorage.CookieTycoon.Recipes)
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

function AssetLibrary.cookie(index, parent, pivot)
	return AssetLibrary.clone("Cookies", Recipes[index].Name, parent, pivot)
end

function AssetLibrary.anchor(object)
	return object:FindFirstChild("LabelAnchor") or object.PrimaryPart
end

return AssetLibrary
