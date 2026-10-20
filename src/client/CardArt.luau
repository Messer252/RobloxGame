local Catalog = if script then require(game:GetService("ReplicatedStorage").CookieTycoon.CardCatalog) else require("../shared/CardCatalog")
local Art = {}

-- Position the complete sheet behind a clipping frame. Relative coordinates
-- stay correct if Roblox serves a smaller texture or the UI uses UIScale.
function Art.layout(sheet, index, width, height)
	if width <= 0 or height <= 0 then return nil end
	local col, row = index % sheet.Columns, math.floor(index / sheet.Columns)
	local cellW, cellH = sheet.Width / sheet.Columns, sheet.Height / sheet.Rows
	local left, top = math.floor(col * cellW) + 2, math.floor(row * cellH) + 2
	local cropW = math.floor((col + 1) * cellW) - 2 - left
	local cropH = math.floor((row + 1) * cellH) - 2 - top
	local scale = math.max(width / cropW, height / cropH)
	return {
		Width = sheet.Width * scale / width, Height = sheet.Height * scale / height,
		X = .5 - (left + cropW / 2) * scale / width,
		Y = .5 - (top + cropH / 2) * scale / height,
	}
end

function Art.mount(parent, card, size)
	local sheet, index = Catalog.art(card.Id)
	if sheet and type(sheet.Id) == "number" and sheet.Id > 0 and sheet.Width > 0 and sheet.Height > 0 then
		local window = Instance.new("Frame")
		window.Name, window.Size, window.BackgroundTransparency = "CardIllustration", size, 1
		window.BorderSizePixel, window.ClipsDescendants, window.Parent = 0, true, parent
		local image = Instance.new("ImageLabel")
		image.Name, image.BackgroundTransparency, image.BorderSizePixel = "FullResolutionSheet", 1, 0
		image.ScaleType, image.ResampleMode = Enum.ScaleType.Stretch, Enum.ResamplerMode.Default
		image.Image, image.Visible, image.Parent = "rbxassetid://" .. sheet.Id, false, window
		local function layout()
			local transform = Art.layout(sheet, index, window.AbsoluteSize.X, window.AbsoluteSize.Y)
			if not transform then image.Visible = false; return end
			image.Size = UDim2.fromScale(transform.Width, transform.Height)
			image.Position = UDim2.fromScale(transform.X, transform.Y)
			image.ZIndex, image.Visible = window.ZIndex, true
		end
		local resize = window:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
		local layer = window:GetPropertyChangedSignal("ZIndex"):Connect(function() image.ZIndex = window.ZIndex end)
		window.Destroying:Connect(function() resize:Disconnect(); layer:Disconnect() end)
		layout()
		-- Request the original asset directly; thumbnails and the static Preview
		-- image are never used for an in-game card illustration.
		task.spawn(function() pcall(function() game:GetService("ContentProvider"):PreloadAsync({ image }) end) end)
		return window
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
