-- Original TCG frame: game text stays readable and independent of illustration assets.
local Shared = game:GetService("ReplicatedStorage").CookieTycoon
local Catalog, Art = require(Shared.CardCatalog), require(script.Parent.CardArt)
local Tween = game:GetService("TweenService")
local CardFrame = {}
function CardFrame.create(parent, card, description)
	local rarity = Color3.fromRGB(table.unpack(Catalog.Colors[card.Rarity]))
	local rank = table.find(Catalog.Rarities, card.Rarity) or 1
	local frame = Instance.new("Frame")
	frame.Name, frame.Size, frame.BackgroundColor3, frame.BorderSizePixel, frame.ZIndex, frame.Parent = "TradingCard", UDim2.fromOffset(352, 520), Color3.fromRGB(29, 32, 39), 0, 51, parent
	local function panel(name, x, y, w, h, color, z)
		local p = Instance.new("Frame")
		p.Name, p.Position, p.Size, p.BackgroundColor3, p.BorderSizePixel, p.ZIndex, p.Parent = name, UDim2.fromOffset(x,y), UDim2.fromOffset(w,h), color, 0, z or 52, frame
		return p
	end
	local function corner(object, radius)
		local c = Instance.new("UICorner"); c.CornerRadius, c.Parent = UDim.new(0,radius), object
	end
	local function stroke(object, color, width)
		local s = Instance.new("UIStroke"); s.Color, s.Thickness, s.Parent = color, width, object
	end
	local function text(value, x, y, w, h, size, color, font)
		local t = Instance.new("TextLabel")
		t.Position, t.Size, t.Text, t.TextSize, t.TextColor3 = UDim2.fromOffset(x,y), UDim2.fromOffset(w,h), value, size, color
		t.BackgroundTransparency, t.TextWrapped, t.Font, t.TextXAlignment, t.ZIndex, t.Parent = 1, true, font or Enum.Font.GothamBold, Enum.TextXAlignment.Left, 56, frame
		return t
	end
	local ink, cream = Color3.fromRGB(37,34,32), Color3.fromRGB(245,235,209)
	corner(frame, 14); stroke(frame, Color3.fromRGB(14,16,20), 3)
	local rim = panel("Foil Rim", 6,6,340,508,rarity)
	corner(rim,10)
	local field = panel("Card Stock",12,12,328,496,Color3.fromRGB(222,203,165),53)
	corner(field,7)
	local wash = Instance.new("UIGradient")
	wash.Color, wash.Rotation, wash.Parent = ColorSequence.new(Color3.fromRGB(247,237,209),Color3.fromRGB(190,168,127)),90,field
	panel("Nameplate",19,20,314,45,Color3.fromRGB(39,45,53),54)
	local name = text(card.Name,27,23,273,39,20,Color3.fromRGB(255,244,216))
	name.TextScaled = true
	local nameSize = Instance.new("UITextSizeConstraint")
	nameSize.MinTextSize, nameSize.MaxTextSize, nameSize.Parent = 12,21,name
	local emblem = panel("Rarity Emblem",310,35,12,12,rarity,56)
	emblem.Rotation = 45
	text(string.upper(card.Animal) .. " / BAKERY COMPANION",23,67,240,20,10,ink)
	local stars = text(string.rep("◆",rank),260,67,68,20,10,ink)
	stars.TextXAlignment = Enum.TextXAlignment.Right
	local artBorder = panel("Illustration Keyline",19,91,314,252,Color3.fromRGB(42,43,44),54)
	stroke(artBorder,Color3.fromRGB(151,127,87),1)
	local art = Art.mount(frame,card,UDim2.fromOffset(308,246))
	art.Position, art.ZIndex = UDim2.fromOffset(22,94),55
	panel("Rarity Ribbon",20,347,312,23,rarity,54)
	text(string.upper(card.Rarity) .. "  •  COOKIE CORNER",27,348,298,21,11,ink)
	local rules = panel("Ability Box",20,377,312,69,cream,54)
	stroke(rules,Color3.fromRGB(153,130,95),1)
	text("BAKERY AURA",28,382,292,17,11,Color3.fromRGB(102,74,38))
	text(description,28,402,294,36,15,ink)
	panel("Flavor Rule",22,453,308,1,Color3.fromRGB(159,137,103),54)
	text('“' .. card.Quip .. '”',25,459,302,31,15,Color3.fromRGB(80,66,49),Enum.Font.Garamond)
	text("CRUMBKIN  /  FIRST BATCH",23,493,230,15,9,ink)
	local number = text(string.format("%03d / 040",card.Id),258,493,70,15,10,ink)
	number.TextXAlignment = Enum.TextXAlignment.Right
	if rank >= 4 then
		local foil = Instance.new("UIGradient")
		foil.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(245,205,105)),ColorSequenceKeypoint.new(.25,Color3.fromRGB(146,228,237)),ColorSequenceKeypoint.new(.5,Color3.fromRGB(222,154,237)),ColorSequenceKeypoint.new(.75,Color3.fromRGB(244,234,173)),ColorSequenceKeypoint.new(1,Color3.fromRGB(245,205,105))})
		foil.Parent = rim
		local animation = Tween:Create(foil,TweenInfo.new(5,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,-1),{Rotation=360})
		animation:Play()
		frame.Destroying:Connect(function() animation:Cancel() end)
	elseif rank == 3 then
		local shine = Instance.new("UIGradient")
		shine.Color,shine.Rotation,shine.Parent = ColorSequence.new(rarity,Color3.fromRGB(217,239,255)),35,rim
	end
	return frame
end
return CardFrame
