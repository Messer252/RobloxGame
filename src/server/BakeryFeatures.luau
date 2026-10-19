local Shared = game:GetService("ReplicatedStorage").CookieTycoon
local Life, Progression = require(Shared.BakeryLife), require(Shared.Progression)
local W, Assets = require(script.Parent.WorldWidgets), require(script.Parent.AssetLibrary)
local Polish = require(Shared.BakeryPolish)
local Decorations = require(script.Parent.BakeryDecorations)
local Cave = require(script.Parent.DoughCave)
local Features = {}
function Features.create(world, plots, action)
	local self = { machines = {}, decorations = {}, buildPads = {}, ores = {}, mine = Vector3.new(-250, 2, 100) }
	local mineModel = Instance.new("Model")
	mineModel.Name, mineModel.Parent = "Cookie Dough Mine", world
	local entrance = W.part(mineModel, "Dough Mine Workshop", Vector3.new(28, 1, 20), self.mine, Color3.fromRGB(136, 102, 69), Enum.Material.WoodPlanks)
	W.label(entrance, "COOKIE DOUGH CAVE\nLeft-click to swing • mine dough", 90)
	W.prompt(entrance, "Rolling pins & dough upgrades", 0, function(player) action(player, "OpenMine") end)
	Cave.create(mineModel)
	for i = 1, 16 do
		local x, z = -285 - ((i - 1) % 4) * 24, 75 + math.floor((i - 1) / 4) * 25
		local maximum = ({ 6, 18, 45 })[(i - 1) % 3 + 1]
		local ore = W.part(mineModel, "Dough Ore", Vector3.new(10, 7, 9), Vector3.new(x, 3, z), Color3.fromRGB(184, 137, 84), Enum.Material.Ground)
		ore.CFrame *= CFrame.Angles(0, i * 0.45, 0)
		ore.Size = Vector3.new(7.5, 5.5, 7)
		local node = { part = ore, hp = maximum, maximum = maximum, reward = math.ceil(maximum / 2), ready = 0, chips = {} }
		node.label = W.label(ore, "Dough ore • " .. maximum .. " HP", 30)
		Cave.health(node)
		ore:SetAttribute("DoughOre", true)
		for facet = 1, 3 do
			local p = Instance.new("WedgePart")
			p.Name, p.Size, p.CFrame, p.Color = "Faceted Dough Rock", Vector3.new(4, 5, 5), ore.CFrame * CFrame.Angles(0, facet * 2.1, 0) * CFrame.new(2.5, -0.3, 0), Color3.fromRGB(172 + facet * 7, 126 + facet * 5, 79)
			p.Anchored, p.CanCollide, p.Material, p.Parent = true, false, Enum.Material.Sandstone, mineModel
			table.insert(node.chips, p)
		end
		for chip = 1, 4 do
			local p = W.part(mineModel, "Ore Chocolate Seam", Vector3.new(0.7, 0.7, 0.7), ore.Position + Vector3.new(math.sin(chip) * 3, 2, math.cos(chip) * 2), Color3.fromRGB(82, 51, 32))
			p.CanCollide = false
			table.insert(node.chips, p)
		end
		table.insert(self.ores, node)
	end
	for _, plot in ipairs(plots) do
		self.machines[plot] = {}
		self.decorations[plot] = Decorations.create(plot)
		local buildPad = W.part(plot.model, "Build Conveyor", Vector3.new(7, 0.2, 7), W.position(plot, 60, 0.8, 64), Color3.fromRGB(117, 192, 170))
		self.buildPads[plot] = { pad = buildPad, label = W.label(buildPad, "Build first conveyor • FREE", 45) }
		W.prompt(buildPad, "Build / expand conveyor", 0, function(player) action(player, "BuildBelt", nil, plot) end)
		for index, key in ipairs(Polish.DecorationOrder) do
			local pad = W.part(plot.model, key .. " Decoration Pad", Vector3.new(5, 0.2, 5), W.position(plot, 30 + ((index - 1) % 5) * 10, 0.8, -55 - math.floor((index - 1) / 5) * 12), Color3.fromRGB(187, 156, 202))
			W.label(pad, Polish.Decorations[key].Name .. "\n$" .. Progression.format(Polish.Decorations[key].Cost), 26)
			W.prompt(pad, "Buy " .. key, 0, function(player) action(player, "Decoration", key, plot) end)
		end
		for _, entry in ipairs({ { "Packager", -18, 115 }, { "Boxer", 18, 110 }, { "FinishingOven", 53, 75 } }) do
			local key, x, z = table.unpack(entry)
			local pad = W.part(plot.model, key .. " Purchase Pad", Vector3.new(6, 0.3, 6), W.position(plot, x, 0.8, z), Color3.fromRGB(119, 194, 161), Enum.Material.Neon)
			local record = { pad = pad, label = W.label(pad, key .. "\n$" .. Progression.format(Life.Machines[key].Cost), 50), key = key, visuals = {} }
			record.prompt = W.prompt(pad, "Buy " .. key, 0, function(player) action(player, "Machine", key, plot) end)
			self.machines[plot][key] = record
			if key == "FinishingOven" then
				local oven = Assets.prop("Oven", plot.model, CFrame.new(W.position(plot, x, 0.5, z - 10)) * CFrame.Angles(0, -(plot.mirrorX or 1) * math.pi / 2, 0))
				oven:ScaleTo(0.8)
				for _, p in ipairs(oven:GetDescendants()) do if p:IsA("BasePart") then table.insert(record.visuals, { part = p, transparency = p.Transparency, collision = p.CanCollide }) end end
			else
				local gateZ = key == "Packager" and Polish.WrapZ or Polish.BoxZ
				local color = key == "Packager" and Color3.fromRGB(112, 181, 172) or Color3.fromRGB(193, 145, 92)
				for _, side in ipairs({ -7.3, 7.3 }) do
					local leg = W.part(plot.model, key .. " Arch Leg", Vector3.new(0.8, 8, 0.8), W.position(plot, side, 4, gateZ), color, Enum.Material.Metal)
					leg.CanCollide = false
					table.insert(record.visuals, { part = leg, transparency = 0, collision = false })
				end
				local head = W.part(plot.model, key .. " Processing Arch", Vector3.new(15.5, 1.3, 1.3), W.position(plot, 0, 8.4, gateZ), color, Enum.Material.Metal)
				head.CanCollide = false
				table.insert(record.visuals, { part = head, transparency = 0, collision = false })
				W.label(head, key, 35)
			end
		end
	end
	return self
end
function Features.step(self)
	for plot, groups in pairs(self.decorations) do
		Decorations.refresh(plot, groups)
		local tier = plot.data and plot.data.life.belt or 0
		local cost = Polish.BeltCosts[tier + 1]
		self.buildPads[plot].label.Text = cost and ("Build line " .. (tier + 1) .. "\n" .. (cost == 0 and "FREE" or "$" .. Progression.format(cost))) or "All conveyor lines built"
	end
	for _, node in ipairs(self.ores) do
		if node.hp <= 0 and os.clock() >= node.ready then
			node.hp, node.part.Transparency, node.part.CanCollide = node.maximum, 0, true
			node.label.Parent.Enabled = true
			node.bar.Size = UDim2.fromScale(1, 1)
			for _, chip in ipairs(node.chips) do chip.Transparency = 0 end
			node.label.Text = "Dough ore • " .. node.hp .. " HP"
		end
	end
	for plot, machines in pairs(self.machines) do
		for key, record in pairs(machines) do
			local owned = plot.data and plot.data.life.machines[key]
			record.label.Text = owned and (key == "FinishingOven" and "Finishing oven\nHold a cookie • 20s • 3x value" or key .. " installed") or key .. "\n$" .. Progression.format(Life.Machines[key].Cost)
			record.pad.Color = owned and Color3.fromRGB(198, 160, 90) or Color3.fromRGB(119, 194, 161)
			record.prompt.ActionText = owned and (key == "FinishingOven" and "Finish held cookie" or "Machine owned") or "Buy " .. key
			if owned and key == "FinishingOven" and plot.data.life.oven.id then record.label.Text = "Finishing cookie\n" .. math.max(0, plot.data.life.oven.ready - os.time()) .. "s remaining • 3x value" end
			for _, visual in ipairs(record.visuals) do
				visual.part.Transparency = owned and visual.transparency or math.max(0.8, visual.transparency)
				visual.part.CanCollide = owned and visual.collision or false
			end
		end
	end
end
return Features
