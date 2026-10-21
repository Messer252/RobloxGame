local Shared = game:GetService("ReplicatedStorage").CookieTycoon
local Life, Progression = require(Shared.BakeryLife), require(Shared.Progression)
local W, Assets = require(script.Parent.WorldWidgets), require(script.Parent.AssetLibrary)
local Polish = require(Shared.BakeryPolish)
local Decorations = require(script.Parent.BakeryDecorations)
local Cave = require(script.Parent.DoughCave)
require(script.Parent.MineAccess) -- Register gate groups before building cave doors.
local Blueprint=require(Shared.BakeryBlueprint)
local Features = {}
function Features.create(world, plots, action)
	local self = { machines = {}, decorations = {}, decorationPads={}, buildPads = {}, ores = {}, mine = Vector3.new(-231, .7, 108) }
	local mineModel = Instance.new("Model")
	mineModel.Name, mineModel.Parent = "Cookie Dough Mine", world
	local entrance = W.part(mineModel, "Dough Mine Workshop", Vector3.new(28, 1, 20), self.mine, Color3.fromRGB(136, 102, 69), Enum.Material.WoodPlanks)
	W.label(entrance, "COOKIE DOUGH CAVE\nLeft-click to swing • mine dough", 90)
	W.prompt(entrance, "Dough upgrades • pins at side-market blacksmith", 0, function(player) action(player, "OpenMine") end)
	Cave.create(mineModel)
	self.ores = Cave.ores(mineModel)
	for _, plot in ipairs(plots) do
		self.machines[plot] = {}
		self.decorations[plot] = Decorations.create(plot)
		self.decorationPads[plot]={}
		local buildPad = W.part(plot.model, "Build Conveyor", Vector3.new(7, 0.2, 7), W.position(plot, 70, 0.8, 70), Color3.fromRGB(117, 192, 170))
		self.buildPads[plot] = { pad = buildPad, label = W.label(buildPad, "Build first conveyor • FREE", 14) }
		W.prompt(buildPad, "Build / expand conveyor", 0, function(player) action(player, "BuildBelt", nil, plot) end)
		for _, key in ipairs(Polish.DecorationOrder) do
			local pad = W.part(nil, key .. " Decoration Pad", Vector3.new(8, 0.2, 8), W.position(plot,14,.8,-96), Color3.fromRGB(143,116,165))
			local label=W.label(pad,Polish.Decorations[key].Name.."\n$"..Progression.format(Polish.Decorations[key].Cost),16)
			label.Parent.Size,label.TextSize=UDim2.fromOffset(150,44),13
			local prompt=W.prompt(pad,"Buy "..key,0,function(player) action(player,"Decoration",key,plot) end)
			self.decorationPads[plot][key]={pad=pad,label=label,prompt=prompt}
		end
		for index,key in ipairs({"Packager","Boxer","FinishingOven"}) do
			local placement=Blueprint.machine(index)
			local x,z=placement.x,placement.z
			local pad = W.part(plot.model, key .. " Purchase Pad", Vector3.new(8, 0.2, 8), W.position(plot, x, 0.8, z), Color3.fromRGB(106,158,136))
			local record = { pad = pad, label = W.label(pad, key .. "\n$" .. Progression.format(Life.Machines[key].Cost), 14), key = key, visuals = {} }
			record.prompt = W.prompt(pad, "Buy " .. key, 0, function(player) action(player, "Machine", key, plot) end)
			self.machines[plot][key] = record
			if key == "FinishingOven" then
				local oven = Assets.prop("Oven", plot.model, CFrame.new(W.position(plot, 67, 0.5, -38)) * CFrame.Angles(0, -(plot.mirrorX or 1) * math.pi / 2, 0))
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
				local label=W.label(head,key,14)
				record.archLabel=label.Parent
			end
		end
	end
	return self
end
function Features.step(self)
	for plot, groups in pairs(self.decorations) do
		Decorations.refresh(plot, groups)
		local available=Blueprint.available(plot.data and plot.data.life)
		local shown={}
		for index,key in ipairs(available) do
			local placement=Blueprint.pad(index)
			local record=self.decorationPads[plot][key]
			record.pad.Position,record.pad.Parent=W.position(plot,placement.x,.8,placement.z),plot.model
			shown[key]=true
		end
		for key,record in pairs(self.decorationPads[plot]) do if not shown[key] then record.pad.Parent=nil end end
		local tier = plot.data and plot.data.life.belt or 0
		local cost = Polish.BeltCosts[tier + 1]
		self.buildPads[plot].label.Text = cost and ("Build line " .. (tier + 1) .. "\n" .. (cost == 0 and "FREE" or "$" .. Progression.format(cost))) or "All conveyor lines built"
		self.buildPads[plot].pad.Parent=plot.data and cost and plot.model or nil
	end
	for _, node in ipairs(self.ores) do
		if node.hp <= 0 and os.clock() >= node.ready then
			Cave.roll(node, math.random())
		end
	end
	for plot, machines in pairs(self.machines) do
		for key, record in pairs(machines) do
			local owned = plot.data and plot.data.life.machines[key]
			local available=plot.data and Life.machineAvailable(plot.data.life,key)
			record.pad.Parent=(available or owned and key=="FinishingOven") and plot.model or nil
			if record.archLabel then record.archLabel.Enabled=owned==true end
			record.label.Text = owned and (key == "FinishingOven" and "Finishing oven\nHold a cookie • 20s • 3x value" or key .. " installed") or key .. "\n$" .. Progression.format(Life.Machines[key].Cost)
			record.pad.Color = owned and Color3.fromRGB(198, 160, 90) or Color3.fromRGB(119, 194, 161)
			record.prompt.ActionText = owned and (key == "FinishingOven" and "Finish held cookie" or "Machine owned") or "Buy " .. key
			if owned and key == "FinishingOven" and plot.data.life.oven.id then record.label.Text = "Finishing cookie\n" .. math.max(0, plot.data.life.oven.ready - os.time()) .. "s remaining • 3x value" end
			for _, visual in ipairs(record.visuals) do
				visual.part.Transparency = owned and visual.transparency or 1
				visual.part.CanCollide = owned and visual.collision or false
			end
		end
	end
end
return Features
