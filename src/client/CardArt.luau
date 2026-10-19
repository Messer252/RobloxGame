local Catalog = require(game:GetService("ReplicatedStorage").CookieTycoon.CardCatalog)
local Art = {}
function Art.mount(parent, card, size)
	if type(Catalog.ArtAssetId) == "number" and Catalog.ArtAssetId > 0 then
		local image = Instance.new("ImageLabel")
		image.ScaleType = Enum.ScaleType.Crop
		image.BackgroundTransparency, image.Size, image.Image = 1, size, "rbxassetid://" .. Catalog.ArtAssetId
		local w, h = Catalog.ArtWidth / Catalog.ArtColumns, Catalog.ArtHeight / Catalog.ArtRows
		image.ImageRectOffset = Vector2.new(math.floor((card.Id-1)%8*w)+2, math.floor(math.floor((card.Id-1)/8)*h)+2)
		image.ImageRectSize, image.Parent = Vector2.new(math.floor(w)-4, math.floor(h)-4), parent
		return image
	end
	-- Original 3D cookie-animal fallback works before the generated atlas is uploaded.
	local view, scene, camera = Instance.new("ViewportFrame"), Instance.new("WorldModel"), Instance.new("Camera")
	view.Size, view.BackgroundColor3, view.Ambient, view.LightColor = size, Color3.fromRGB(230, 218, 193), Color3.fromRGB(190, 183, 167), Color3.fromRGB(255, 236, 198)
	view.LightDirection, view.Parent, scene.Parent, camera.Parent, view.CurrentCamera = Vector3.new(-1, -1, -2), parent, view, view, camera
	local palette = { Color3.fromRGB(198, 145, 87), Color3.fromRGB(175, 119, 76), Color3.fromRGB(237, 211, 157), Color3.fromRGB(99, 60, 42), Color3.fromRGB(230, 175, 154), Color3.fromRGB(148, 200, 160) }
	local base = palette[(card.Id - 1) % #palette + 1]
	if card.Id == 33 then base = Color3.fromRGB(140, 205, 165) end
	local function p(name, position, shapeSize, color, shape)
		local part = Instance.new("Part")
		part.Name, part.Anchored, part.Size, part.Position, part.Color, part.Shape, part.Parent = name, true, shapeSize, position, color, shape or Enum.PartType.Ball, scene
		return part
	end
	p("Cookie body", Vector3.new(0, 0, 0), Vector3.new(2, 2.1, 1.25), base)
	p("Cookie head", Vector3.new(0, 1.1, -.2), Vector3.new(2.15, 1.8, 1.4), base)
	p("Cream muzzle", Vector3.new(0, .8, -1), Vector3.new(1.1, .65, .28), Color3.fromRGB(244, 224, 185))
	local bunny = card.Animal == "Bunny"
	for _, side in ipairs({ -1, 1 }) do
		p("Ear", Vector3.new(side*.8, bunny and 2.4 or 1.8, -.2), Vector3.new(.55, bunny and 1.6 or .6, .4), base)
		p("Eye", Vector3.new(side*.43, 1.25, -.9), Vector3.new(.28, .34, .12), Color3.fromRGB(48, 35, 31))
		p("Eye shine", Vector3.new(side*.43-.04, 1.32, -.97), Vector3.new(.07, .09, .04), Color3.new(1,1,1))
		p("Paw", Vector3.new(side*.7, -.85, -.3), Vector3.new(.8, .55, .8), base)
	end
	p("Nose", Vector3.new(0, .95, -1.19), Vector3.new(.2, .15, .1), Color3.fromRGB(72, 45, 32))
	for i = 1, 9 do p("Chocolate chip", Vector3.new(math.sin(i*2.4)*.8, -.55+(i%4)*.35, -.67), Vector3.new(.19,.16,.1), Color3.fromRGB(86,53,34)) end
	if card.Id >= 26 then
		for _, side in ipairs({ -1, 1 }) do
			p("Sugar horn", Vector3.new(side*.6, 2.1, -.1), Vector3.new(.25,.7,.25), Color3.fromRGB(246,215,139))
			if card.Id >= 31 then
				local wing = Instance.new("WedgePart")
				wing.Size, wing.CFrame, wing.Color, wing.Anchored, wing.Parent = Vector3.new(.25, 1.8, 2.6), CFrame.new(side*1.5,.6,.4)*CFrame.Angles(0,0,side*.7), base:Lerp(Color3.new(1,1,1), .2), true, scene
			end
		end
	end
	camera.CFrame = CFrame.lookAt(Vector3.new(3,2.3,-7.5), Vector3.new(0,.8,0))
	return view
end
return Art
