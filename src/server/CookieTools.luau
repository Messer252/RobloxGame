local Assets = require(script.Parent.AssetLibrary)
local Packaging = require(script.Parent.CookiePackaging)
local Life = require(game:GetService("ReplicatedStorage").CookieTycoon.BakeryLife)
local Tools = {}
local pinStyles = {
	{ Length = 3.2, Diameter = .72, Body = Color3.fromRGB(204, 158, 99), Material = Enum.Material.Wood, Grip = Color3.fromRGB(111, 69, 40), Trim = Color3.fromRGB(154, 99, 54) },
	{ Length = 3.4, Diameter = .84, Body = Color3.fromRGB(114, 67, 39), Material = Enum.Material.Wood, Grip = Color3.fromRGB(73, 45, 32), Trim = Color3.fromRGB(212, 127, 75) },
	{ Length = 3.5, Diameter = .94, Body = Color3.fromRGB(182, 202, 211), Material = Enum.Material.Metal, Grip = Color3.fromRGB(48, 66, 78), Trim = Color3.fromRGB(88, 119, 139) },
	{ Length = 3.6, Diameter = 1.02, Body = Color3.fromRGB(241, 227, 198), Material = Enum.Material.Marble, Grip = Color3.fromRGB(75, 107, 89), Trim = Color3.fromRGB(242, 189, 74) },
	{ Length = 3.8, Diameter = 1.12, Body = Color3.fromRGB(79, 58, 148), Material = Enum.Material.Glass, Grip = Color3.fromRGB(39, 41, 83), Trim = Color3.fromRGB(115, 235, 250) },
}

local function pinModel(tool, level)
	local style = pinStyles[level]
	local handle
	local function piece(name, size, cf, tint, material, shape)
		local p = Instance.new("Part")
		p.Name, p.Size, p.CFrame, p.Color = name, size, cf, tint
		p.Shape, p.Material = shape or Enum.PartType.Cylinder, material or Enum.Material.Metal
		p.CanCollide, p.CanTouch, p.CanQuery, p.Massless = false, false, false, true
		p.TopSurface, p.BottomSurface, p.Parent = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth, tool
		if handle then
			local weld = Instance.new("WeldConstraint")
			weld.Part0, weld.Part1, weld.Parent = handle, p, p
		end
		return p
	end
	-- The actual held handle sits at the end, so the barrel extends out of the
	-- player's hand. All decorative parts share one non-colliding welded assembly.
	handle = piece("Handle", Vector3.new(.9, .32, .32), CFrame.new(), style.Grip, level == 3 and Enum.Material.DiamondPlate or Enum.Material.Wood)
	local centerX = -.55 - style.Length / 2
	local farX = -style.Length - 1.1
	piece("Turned End Grip", Vector3.new(.9, .32, .32), CFrame.new(farX, 0, 0), style.Grip, handle.Material)
	piece(Life.PinNames[level] .. " Barrel", Vector3.new(style.Length, style.Diameter, style.Diameter), CFrame.new(centerX, 0, 0), style.Body, style.Material)
	for _, x in ipairs({ -.53, -style.Length - .57 }) do
		piece("Barrel End Cap", Vector3.new(.15, style.Diameter * .9, style.Diameter * .9), CFrame.new(x, 0, 0), style.Trim, level == 1 and Enum.Material.Wood or Enum.Material.Metal)
	end
	for _, x in ipairs({ 0, farX }) do
		for band = -1, 1 do
			piece("Turned Grip Ring", Vector3.new(.06, .36, .36), CFrame.new(x + band * .22, 0, 0), style.Trim, level >= 4 and Enum.Material.Metal or handle.Material)
		end
		piece("Grip Pommel", Vector3.new(.18, .42, .42), CFrame.new(x + (x == 0 and .49 or -.49), 0, 0), style.Trim, level == 5 and Enum.Material.Neon or Enum.Material.Metal)
	end
	if level == 1 then
		-- Warm wood grain and thin turned grooves keep the starter handmade.
		for _, offset in ipairs({ -.95, .95 }) do
			piece("Maple Turning Groove", Vector3.new(.045, .735, .735), CFrame.new(centerX + offset, 0, 0), style.Trim, Enum.Material.Wood)
		end
	elseif level == 2 then
		for _, offset in ipairs({ -1.25, 0, 1.25 }) do
			piece("Hammered Copper Band", Vector3.new(.2, .9, .9), CFrame.new(centerX + offset, 0, 0), style.Trim, Enum.Material.CorrodedMetal)
		end
	elseif level == 3 then
		for _, offset in ipairs({ -1.35, 1.35 }) do
			piece("Steel Reinforcement Collar", Vector3.new(.3, 1.06, 1.06), CFrame.new(centerX + offset, 0, 0), style.Trim, Enum.Material.DiamondPlate)
		end
		for index = 1, 8 do
			local angle = index / 8 * math.pi * 2
			piece("Steel Barrel Flute", Vector3.new(2.3, .07, .07), CFrame.new(centerX, math.cos(angle) * .47, math.sin(angle) * .47), Color3.fromRGB(110, 140, 157), Enum.Material.Metal, Enum.PartType.Block)
		end
	elseif level == 4 then
		for _, offset in ipairs({ -1.4, -1.15, 1.15, 1.4 }) do
			piece("Gilded Marble Band", Vector3.new(.09, 1.08, 1.08), CFrame.new(centerX + offset, 0, 0), style.Trim)
		end
		for index = 1, 6 do
			local angle = index / 6 * math.pi * 2
			local crest = piece("Golden Cookie Crest", Vector3.new(.4, .08, .4), CFrame.new(centerX, math.cos(angle) * .53, math.sin(angle) * .53) * CFrame.Angles(angle, 0, 0), style.Trim, Enum.Material.Metal, Enum.PartType.Block)
			crest.CFrame *= CFrame.Angles(0, math.pi / 4, 0)
		end
	else
		for index = 1, 8 do
			local angle = index / 8 * math.pi * 2
			piece("Starforged Crystal Facet", Vector3.new(3.45, .14, .4), CFrame.new(centerX, math.cos(angle) * .52, math.sin(angle) * .52) * CFrame.Angles(angle, 0, 0), index % 2 == 0 and Color3.fromRGB(148, 116, 224) or style.Body, Enum.Material.Glass, Enum.PartType.Block)
		end
		for _, offset in ipairs({ -1.65, 0, 1.65 }) do
			piece("Starforged Luminous Seal", Vector3.new(.07, 1.18, 1.18), CFrame.new(centerX + offset, 0, 0), style.Trim, Enum.Material.Neon)
		end
	end
	return handle
end

function Tools.pin(player, level, onSwing)
	local tool = Instance.new("Tool")
	tool.Name, tool.CanBeDropped = Life.PinNames[level] .. " Rolling Pin", false
	tool.ToolTip = "Tier " .. level .. "/5 • Left-click to mine or swing in Cookie Hill"
	tool:SetAttribute("RollingPinTier", level)
	pinModel(tool, level)
	tool.Grip = CFrame.Angles(0, 0, math.pi / 2)
	local idle, swinging = tool.Grip, false
	tool.Activated:Connect(function()
		if swinging or tool.Parent ~= player.Character then return end
		swinging = true
		local tween = game:GetService("TweenService")
		tween:Create(tool, TweenInfo.new(0.1), { Grip = idle * CFrame.Angles(-1.1, 0, 0) }):Play()
		task.delay(0.1, function()
			if tool.Parent == player.Character then
				tween:Create(tool, TweenInfo.new(0.12), { Grip = idle * CFrame.Angles(0.9, 0, 0) }):Play()
				onSwing()
			end
		end)
		task.delay(0.3, function() if tool.Parent then tween:Create(tool, TweenInfo.new(0.12), { Grip = idle }):Play() end end)
		task.delay(0.5, function() swinging = false end)
	end)
	tool.Parent = player:FindFirstChildOfClass("Backpack")
	return tool
end
function Tools.bag(player, onOpen)
	local tool = Instance.new("Tool")
	tool.Name, tool.ToolTip, tool.RequiresHandle, tool.CanBeDropped = "Cookie Bag", "Open your cookie inventory", false, false
	tool:SetAttribute("CookieBag", true)
	tool.Equipped:Connect(function()
		onOpen()
		task.defer(function()
			local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if hum and tool.Parent == player.Character then hum:UnequipTools() end
		end)
	end)
	tool.Parent = player:FindFirstChildOfClass("Backpack")
	return tool
end
function Tools.cookie(player, cookie, onHeld, onEat)
	local tool = Instance.new("Tool")
	tool.Name, tool.CanBeDropped = "Cookie: " .. require(game:GetService("ReplicatedStorage").CookieTycoon.Recipes)[cookie.recipe].Name, false
	tool:SetAttribute("InventoryCookieId", cookie.id)
	local handle = Instance.new("Part")
	handle.Name, handle.Size, handle.Transparency, handle.CanCollide, handle.Massless, handle.Parent = "Handle", Vector3.new(0.3, 0.3, 0.3), 1, false, true, tool
	local flags = require(game:GetService("ReplicatedStorage").CookieTycoon.CookieCrafting).decode(cookie.mask)
	local model = Assets.cookie(cookie.recipe, tool, CFrame.new(), flags)
	model:ScaleTo(0.6)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored, part.CanCollide, part.CanTouch, part.Massless = false, false, false, true
			local weld = Instance.new("WeldConstraint")
			weld.Part0, weld.Part1, weld.Parent = handle, part, handle
		end
	end
	if cookie.wrapped then Packaging.wrap(model, handle, 0.6) end
	if cookie.boxed then Packaging.box(model, handle, 0.6) end
	tool.Equipped:Connect(function() onHeld(cookie.id) end)
	tool.Unequipped:Connect(function() onHeld(nil) end)
	tool.Activated:Connect(onEat)
	tool.Parent = player:FindFirstChildOfClass("Backpack")
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then humanoid:EquipTool(tool) end
	return tool
end
return Tools
