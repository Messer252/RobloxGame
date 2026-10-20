local Players, Tween, Debris = game:GetService("Players"), game:GetService("TweenService"), game:GetService("Debris")
local Shared = game:GetService("ReplicatedStorage").CookieTycoon
local Rules, Cards, Polish, Life = require(Shared.ValleyEvents), require(Shared.CardEconomy), require(Shared.BakeryPolish), require(Shared.BakeryLife)
local Town = require(Shared.TownCatalog)
local W, Assets = require(script.Parent.WorldWidgets), require(script.Parent.AssetLibrary)
local Events = {}
Events.__index = Events
local gold, cocoa = Color3.fromRGB(255, 205, 97), Color3.fromRGB(77, 47, 37)
local rewardText = Rules.HillReward .. " Star Crumbs / " .. Rules.PayoutSeconds .. "s"
local idleText = "COOKIE HILL • PVP ZONE\nHold alone " .. Rules.CaptureSeconds .. "s • " .. rewardText

local function decoration(part)
	part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
	return part
end

local function buildHill(self, folder)
	local center = Vector3.new(Rules.HillX, 0, Rules.HillZ)
	local function piece(name, size, offset, tint, material)
		return W.part(folder, name, size, center + offset, tint, material)
	end
	local function disc(name, radius, y, thickness, tint, material)
		local p = piece(name, Vector3.new(thickness, radius * 2, radius * 2), Vector3.new(0, y, 0), tint, material)
		p.Shape, p.CFrame = Enum.PartType.Cylinder, p.CFrame * CFrame.Angles(0, 0, math.pi / 2)
		return p
	end
	disc("Hill Slate Foundation", 29, 6.25, .9, Color3.fromRGB(87, 103, 107), Enum.Material.Slate)
	disc("Hill Brass Plinth", 26.5, 7.15, .9, gold, Enum.Material.Metal)
	disc("KOTH Cookie Hill", Rules.HillRadius, 8, .6, Color3.fromRGB(206, 153, 91), Enum.Material.Sandstone)
	-- The illuminated ring follows the server's actual PvP radius. All trim is
	-- non-colliding, leaving an open fighting floor without snags or railings.
	self.hillTrim = {}
	for index = 1, 64 do
		local angle = index / 64 * math.pi * 2
		local offset = Vector3.new(math.cos(angle) * Rules.HillRadius, 8.4, math.sin(angle) * Rules.HillRadius)
		local rim = decoration(piece("PvP Boundary Light", Vector3.new(2.4, .16, .45), offset, gold, Enum.Material.Neon))
		rim.CFrame = CFrame.lookAt(rim.Position, center + Vector3.new(0, 8.4, 0))
		table.insert(self.hillTrim, rim)
	end
	for index = 1, 14 do
		local angle, radius = index * 2.39996, 5 + (index % 4) * 4
		local chip = decoration(piece("Arena Chocolate Inlay", Vector3.new(2.3, .08, 1.7), Vector3.new(math.cos(angle) * radius, 8.34, math.sin(angle) * radius), cocoa, Enum.Material.SmoothPlastic))
		chip.CFrame *= CFrame.Angles(0, angle, 0)
	end
	-- Wide steps face the bakeries. Solid risers follow the natural hill slope.
	for step = 1, 8 do
		piece("Hill Entrance Step", Vector3.new(4.2, step + 1, 14), Vector3.new(58 - step * 4, (step - 1) / 2, 0), Color3.fromRGB(143, 157, 153), Enum.Material.Slate)
		decoration(piece("Step Brass Edge", Vector3.new(.2, .06, 14), Vector3.new(60 - step * 4, step + .04, 0), gold, Enum.Material.Metal))
	end
	for _, side in ipairs({-1, 1}) do
		piece("Entrance Stone Foot", Vector3.new(4, 1.5, 4), Vector3.new(41, 5, side * 10), cocoa, Enum.Material.Slate)
		piece("Entrance Pillar", Vector3.new(1.4, 15, 1.4), Vector3.new(41, 12.5, side * 10), cocoa, Enum.Material.Wood)
		local lantern = decoration(piece("Hill Entrance Lantern", Vector3.new(2, 2, 2), Vector3.new(41, 20.8, side * 10), gold, Enum.Material.Neon))
		local light = Instance.new("PointLight")
		light.Color, light.Brightness, light.Range, light.Parent = gold, 1.5, 24, lantern
	end
	local arch = piece("Cookie Hill Entrance Arch", Vector3.new(2, 2.2, 24), Vector3.new(41, 20, 0), cocoa, Enum.Material.Wood)
	local entryText = W.label(arch, "COOKIE HILL\nFight inside the gold ring • Hold alone to earn", 100)
	entryText.Parent.Size, entryText.Parent.StudsOffset = UDim2.fromOffset(310, 55), Vector3.new(0, 4, 0)
	entryText.TextColor3 = gold
	for index = 1, 4 do
		local angle = math.pi / 4 + (index - 1) * math.pi / 2
		local offset = Vector3.new(math.cos(angle) * 33, 0, math.sin(angle) * 33)
		piece("Arena Banner Foot", Vector3.new(3, 1, 3), offset + Vector3.new(0, 6.5, 0), cocoa, Enum.Material.Slate)
		piece("Arena Banner Pole", Vector3.new(.45, 17, .45), offset + Vector3.new(0, 15, 0), gold, Enum.Material.Metal)
		local banner = decoration(piece("Gold Arena Banner", Vector3.new(4.5, 7, .18), offset + Vector3.new(2, 19, 0), Color3.fromRGB(154, 79, 52), Enum.Material.Fabric))
		decoration(piece("Banner Gold Emblem", Vector3.new(1.5, 1.5, .22), banner.Position - center + Vector3.new(0, .5, .1), gold, Enum.Material.Metal))
	end
	-- A tall cookie trophy and warm beacon make the hill visible over the forest.
	local pole = piece("Hill Flagpole", Vector3.new(.7, 27, .7), Vector3.new(-27, 20, 0), gold, Enum.Material.Metal)
	self.flag = decoration(piece("Hill Flag", Vector3.new(9, 5, .18), Vector3.new(-22.5, 28, 0), gold, Enum.Material.Fabric))
	local trophy = decoration(piece("Champion Cookie Trophy", Vector3.new(.9, 9, 9), Vector3.new(-27, 36, 0), Color3.fromRGB(219, 161, 89), Enum.Material.Sandstone))
	trophy.Shape, trophy.CFrame = Enum.PartType.Cylinder, trophy.CFrame * CFrame.Angles(0, math.pi / 2, 0)
	for index = 1, 9 do
		local angle, radius = index * 2.39996, 1 + (index % 3) * 1.15
		local chip = decoration(piece("Trophy Chocolate Chip", Vector3.new(.8, .9, .25), Vector3.new(-27 + math.cos(angle) * radius, 36 + math.sin(angle) * radius, .55), cocoa))
		chip.CFrame *= CFrame.Angles(0, 0, angle)
	end
	decoration(piece("Champion Crown Band", Vector3.new(6, .65, 1.2), Vector3.new(-27, 41, 0), gold, Enum.Material.Metal))
	for index = -1, 1 do
		decoration(piece("Champion Crown Point", Vector3.new(1.2, index == 0 and 2.8 or 2, 1.2), Vector3.new(-27 + index * 2.2, 42, 0), gold, Enum.Material.Metal))
	end
	local beacon = decoration(piece("Hill Golden Beacon", Vector3.new(.5, 32, .5), Vector3.new(-27, 59, 0), gold, Enum.Material.Neon))
	beacon.Transparency, beacon.CastShadow = .65, false
	self.hillText = W.label(pole, idleText, 420)
	self.hillText.Parent.Size, self.hillText.Parent.StudsOffset = UDim2.fromOffset(360, 78), Vector3.new(0, 27, 0)
	self.hillText.TextSize, self.hillText.TextColor3 = 18, gold
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0, 12), self.hillText
end

function Events.start(context)
	local self = setmetatable({ context = context, nextMeteor = os.clock() + Rules.meteorDelay(math.random()), cooldowns = {}, born = {}, hill = {} }, Events)
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "Star Crumb Events", context.World
	self.folder = folder
	buildHill(self, folder)
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
function Events:Announce(kind)
	self.context.Announce(kind)
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
	self:Announce("Incoming")
	Tween:Create(value, TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Value = CFrame.new(target) }):Play()
	task.delay(3, function()
		if self.meteor ~= meteor or not model.Parent then return end
		meteor.landed = true
		self:Announce("Impact")
		local ring = decoration(W.part(self.folder, "Meteor Impact Shockwave", Vector3.new(.15, 8, 8), target - Vector3.new(0, 1.8, 0), gold, Enum.Material.Neon))
		ring.Shape, ring.CFrame, ring.Transparency = Enum.PartType.Cylinder, ring.CFrame * CFrame.Angles(0, 0, math.pi / 2), .25
		Tween:Create(ring, TweenInfo.new(.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(.1, 64, 64), Transparency = 1 }):Play()
		Debris:AddItem(ring, 1)
	end)
end
function Events:Swing(player, pinTool)
	local root = self:Eligible(player)
	if not root or pinTool.Parent ~= player.Character then return false end
	local now = os.clock()
	if now - (self.cooldowns[player] or -math.huge) < .5 then return true end
	self.cooldowns[player] = now
	local state = self.context.Usable(player)
	if not state then return true end
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
				targetHum:TakeDamage(Rules.damage(state.data.life.pin, attack.Damage, defense.Defense + Town.defense(otherState.data.life)))
				local flat = Vector3.new(delta.X, 0, delta.Z)
				if flat.Magnitude > .1 then target:ApplyImpulse((flat.Unit * 18 + Vector3.yAxis * 4) * target.AssemblyMass) end
				return true
			end
		end
	end
	return true
end
function Events:Step()
	local now, occupants, online = os.clock(), {}, {}
	for _, player in ipairs(Players:GetPlayers()) do
		local profile=self.context.GetState(player)
		if profile and not profile.closing and not profile.profile.lost and not player:GetAttribute("AdminFlying") and not player:GetAttribute("AdminInvisible") then online[player.UserId]=true end
		local root = self:Eligible(player)
		local inside = root and Rules.onHill(root.Position.X, root.Position.Y, root.Position.Z) or false
		player:SetAttribute("InCookiePVP", inside)
		player:SetAttribute("NextMeteorSeconds", math.max(0, math.floor(self.nextMeteor - now)))
		if inside then table.insert(occupants, player.UserId) end
	end
	local payout=Rules.hillStep(self.hill,occupants,online,now)
	local owner=self.hill.owner and Players:GetPlayerByUserId(self.hill.owner)
	local candidate=self.hill.candidate and Players:GetPlayerByUserId(self.hill.candidate)
	if payout then
		local player=Players:GetPlayerByUserId(payout)
		local state=player and self.context.Usable(player)
		if state then Cards.award(state.data.life.cards,Rules.HillReward,state.perks.ThirdCardSlot); self.context.Changed(player,state) end
	end
	self.hillText.Text=#occupants>1 and "COOKIE HILL CONTESTED\nRewards paused • PVP ON" or candidate and ("@"..candidate.Name.." capturing • "..math.max(0,math.ceil(Rules.CaptureSeconds-(now-self.hill.capture))).."s\n"..(owner and "Held by @"..owner.Name or "Claim the hill")) or owner and ("@"..owner.Name.." owns COOKIE HILL\n"..rewardText.." • Defend your flag!") or idleText
	for _,player in ipairs(Players:GetPlayers()) do player:SetAttribute("OwnsCookieHill",self.hill.owner==player.UserId) end
	local hillColor = #occupants > 1 and Color3.fromRGB(255, 113, 94) or owner and Color3.fromRGB(124, 235, 169) or gold
	if self.hillColor ~= hillColor then
		self.hillColor, self.flag.Color, self.hillText.TextColor3 = hillColor, hillColor, hillColor
		for _, rim in ipairs(self.hillTrim) do rim.Color = hillColor end
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
