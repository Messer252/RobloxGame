local Players, Tween, Debris = game:GetService("Players"), game:GetService("TweenService"), game:GetService("Debris")
local Shared = game:GetService("ReplicatedStorage").CookieTycoon
local Rules, Cards, Polish, Life = require(Shared.ValleyEvents), require(Shared.CardEconomy), require(Shared.BakeryPolish), require(Shared.BakeryLife)
local W, Assets = require(script.Parent.WorldWidgets), require(script.Parent.AssetLibrary)
local Events = {}
Events.__index = Events
function Events.start(context)
	local self = setmetatable({ context = context, nextMeteor = os.clock() + Rules.meteorDelay(math.random()), cooldowns = {}, born = {} }, Events)
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "Star Crumb Events", context.World
	self.folder = folder
	local hill = W.part(folder, "KOTH Cookie Hill", Vector3.new(.6, 48, 48), Vector3.new(Rules.HillX, 8, Rules.HillZ), Color3.fromRGB(162, 125, 75), Enum.Material.Slate)
	hill.Shape, hill.CFrame = Enum.PartType.Cylinder, hill.CFrame * CFrame.Angles(0, 0, math.pi/2)
	local pole = W.part(folder, "Hill Flagpole", Vector3.new(.4, 19, .4), Vector3.new(Rules.HillX, 17, Rules.HillZ), Color3.fromRGB(186, 169, 135), Enum.Material.Metal)
	self.flag = W.part(folder, "Hill Flag", Vector3.new(8, 4, .15), pole.Position + Vector3.new(4, 6, 0), Color3.fromRGB(220, 185, 98))
	self.hillText = W.label(pole, "COOKIE HILL • PVP ZONE\nHold alone 8s • 2 Star Crumbs / 10s", 110)
	self.hillText.Parent.Size, self.hillText.Parent.StudsOffset = UDim2.fromOffset(300, 65), Vector3.new(0, 8, 0)
	local function mark(player)
		self.born[player] = os.clock()
		player.CharacterAdded:Connect(function() self.born[player] = os.clock() end)
	end
	Players.PlayerAdded:Connect(mark)
	Players.PlayerRemoving:Connect(function(player) self.born[player], self.cooldowns[player] = nil, nil end)
	for _, player in ipairs(Players:GetPlayers()) do mark(player) end
	task.spawn(function()
		while folder.Parent do self:Step(); task.wait(.25) end
	end)
	return self
end
function Events:Eligible(player)
	local character = player.Character
	local root, hum = character and character:FindFirstChild("HumanoidRootPart"), character and character:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 or player:GetAttribute("AdminFlying") or player:GetAttribute("AdminInvisible") or os.clock() - (self.born[player] or os.clock()) < 5 then return nil end
	local state = self.context.GetState(player)
	if not state or state.closing or state.profile.lost or state.profile.closed then return nil end
	return root, hum
end
function Events:Announce(text)
	for _, player in ipairs(Players:GetPlayers()) do self.context.Notify(player, text) end
end
function Events:SpawnMeteor()
	local spots = { Vector3.new(270, 3, -490), Vector3.new(-265, 3, -500), Vector3.new(285, 3, 510), Vector3.new(-280, 3, 270) }
	local target = spots[math.random(#spots)]
	local model = Assets.cookie(4, self.folder, CFrame.new(target + Vector3.new(0, 250, 0)))
	model.Name = "Cookie Meteor • Star Crumbs"
	model:ScaleTo(4)
	local core = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	local value = Instance.new("CFrameValue")
	value.Value = model:GetPivot()
	value.Changed:Connect(function(cf) if model.Parent then model:PivotTo(cf) end end)
	value.Parent = model
	local fire = Instance.new("Fire")
	fire.Size, fire.Heat, fire.Parent = 18, 15, core
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness, light.Parent = Color3.fromRGB(255, 165, 78), 35, 2, core
	local meteor = { model = model, core = core, hp = 180, hits = {}, paid = {}, expires = os.clock() + 300, landed = false }
	meteor.label = W.label(core, "COOKIE METEOR\nStrike with your rolling pin • 180 HP", 100)
	meteor.label.Parent.StudsOffset, meteor.label.Parent.Size = Vector3.new(0, 12, 0), UDim2.fromOffset(300, 65)
	self.meteor = meteor
	self:Announce("A cookie meteor is falling! Follow its fire in the outer meadow for Star Crumbs.")
	Tween:Create(value, TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Value = CFrame.new(target) }):Play()
	task.delay(3, function() if self.meteor == meteor then meteor.landed = true end end)
end
function Events:Swing(player, pinTool)
	local root = self:Eligible(player)
	if not root or pinTool.Parent ~= player.Character then return false end
	local now = os.clock()
	if now - (self.cooldowns[player] or -math.huge) < .5 then return true end
	self.cooldowns[player] = now
	local state = self.context.Usable(player)
	local meteor = self.meteor
	if meteor and meteor.landed and meteor.hp > 0 and (meteor.core.Position - root.Position).Magnitude <= 16 then
		local damage = math.min(20, Life.PinPower[state.data.life.pin] + Polish.active(state.data.life, os.time()).Mine + Cards.bonuses(state.data.life.cards, state.perks.ThirdCardSlot).Mine)
		meteor.hp = math.max(0, meteor.hp - damage)
		meteor.hits[player.UserId] = (meteor.hits[player.UserId] or 0) + 1
		meteor.label.Text = "COOKIE METEOR • " .. meteor.hp .. "/180 HP\n3+ hits earns a personal crumb reward"
		if meteor.hp == 0 then meteor.expires = now + 45; meteor.label.Text = "Meteor cracked! Rewards are being saved." end
		return true
	end
	if not Rules.onHill(root.Position.X, root.Position.Y, root.Position.Z) then return false end
	for _, other in ipairs(Players:GetPlayers()) do
		if other == player then continue end
		local target, targetHum = self:Eligible(other)
		if target and Rules.onHill(target.Position.X, target.Position.Y, target.Position.Z) then
			local delta = target.Position - root.Position
			if delta.Magnitude <= 9 and delta:Dot(root.CFrame.LookVector) > 0 then
				local otherState = self.context.GetState(other)
				local attack, defense = Polish.active(state.data.life, os.time()), Polish.active(otherState.data.life, os.time())
				targetHum:TakeDamage(Rules.damage(state.data.life.pin, attack.Damage, defense.Defense))
				local flat = Vector3.new(delta.X, 0, delta.Z)
				if flat.Magnitude > .1 then target:ApplyImpulse((flat.Unit * 18 + Vector3.yAxis * 4) * target.AssemblyMass) end
				return true
			end
		end
	end
	return true
end
function Events:Step()
	local now, occupants = os.clock(), {}
	for _, player in ipairs(Players:GetPlayers()) do
		local root = self:Eligible(player)
		local inside = root and Rules.onHill(root.Position.X, root.Position.Y, root.Position.Z) or false
		player:SetAttribute("InCookiePVP", inside)
		player:SetAttribute("NextMeteorSeconds", math.max(0, math.floor(self.nextMeteor - now)))
		if inside then table.insert(occupants, player) end
	end
	if #occupants == 1 then
		local owner = occupants[1]
		if self.candidate ~= owner then self.candidate, self.capture, self.owner = owner, now, nil end
		if not self.owner and now - self.capture >= Rules.CaptureSeconds then self.owner, self.nextPayout = owner, now + Rules.PayoutSeconds end
		self.hillText.Text = self.owner and ("@" .. owner.Name .. " owns COOKIE HILL\n2 Star Crumbs every 10s • PVP ON") or ("@" .. owner.Name .. " capturing\n" .. math.max(0, math.ceil(Rules.CaptureSeconds - (now-self.capture))) .. "s • PVP ON")
		if self.owner and now >= self.nextPayout then
			self.nextPayout = now + Rules.PayoutSeconds
			local state = self.context.Usable(owner)
			if state then Cards.award(state.data.life.cards, 2, state.perks.ThirdCardSlot); self.context.Changed(owner, state) end
		end
	else
		self.candidate, self.owner = nil, nil
		self.hillText.Text = #occupants > 1 and "COOKIE HILL CONTESTED\nNo rewards until one baker remains • PVP ON" or "COOKIE HILL • PVP ZONE\nHold alone 8s • 2 Star Crumbs / 10s"
	end
	if not self.meteor and now >= self.nextMeteor then self:SpawnMeteor(); self.nextMeteor = now + Rules.meteorDelay(math.random()) end
	local meteor = self.meteor
	if meteor then
		if meteor.hp == 0 then
			for _, player in ipairs(Players:GetPlayers()) do
				if (meteor.hits[player.UserId] or 0) >= 3 and not meteor.paid[player.UserId] then
					local state = self.context.Usable(player)
					if state then
						meteor.paid[player.UserId] = true
						local reward = Cards.award(state.data.life.cards, Rules.meteorReward(math.random()), state.perks.ThirdCardSlot)
						self.context.Changed(player, state); self.context.Notify(player, "Meteor reward: +" .. reward .. " Star Crumbs!")
					end
				end
			end
		end
		if now >= meteor.expires then Debris:AddItem(meteor.model, 0); self.meteor = nil end
	end
end
return Events
