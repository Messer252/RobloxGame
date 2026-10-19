local Players, Http = game:GetService("Players"), game:GetService("HttpService")
local Shared = game:GetService("ReplicatedStorage").CookieTycoon
local Life, Recipes, Crafting = require(Shared.BakeryLife), require(Shared.Recipes), require(Shared.CookieCrafting)
local W, Features = require(script.Parent.WorldWidgets), require(script.Parent.BakeryFeatures)
local Tools, Appearance = require(script.Parent.CookieTools), require(script.Parent.CookieAppearance)
local Customers = require(script.Parent.CookieCustomers)
local Packaging = require(script.Parent.CookiePackaging)
local Server = {}
Server.__index = Server
function Server.start(context)
	local self = setmetatable({ context = context, runtime = {}, offers = {}, pickups = setmetatable({}, { __mode = "k" }) }, Server)
	local function remote(name)
		local r = Instance.new("RemoteEvent")
		r.Name, r.Parent = name, context.Remotes
		return r
	end
	self.action, self.stateRemote, self.open = remote("LifeAction"), remote("LifeState"), remote("OpenLife")
	self.features = Features.create(context.World, context.Plots, function(...) self:Action(...) end)
	self.customers = Customers.create(context.World, function(player, customer) self:OfferCustomer(player, customer) end)
	context.OnCookie(function(...) self:Cookie(...) end)
	self.action.OnServerEvent:Connect(function(player, action, argument) self:Action(player, action, argument) end)
	Players.PlayerRemoving:Connect(function(player)
		self:CancelTrade(player)
		local runtime = self.runtime[player]
		if runtime then self:CloseBargain(runtime); Appearance.clear(runtime) end
		if runtime and runtime.appearance then runtime.appearance:Disconnect() end
		self.runtime[player] = nil
	end)
	task.spawn(function()
		while context.World.Parent do
			Features.step(self.features)
			for model, pickup in pairs(self.pickups) do
				if not model.Parent or not model.PrimaryPart or not model.PrimaryPart.Parent then self.pickups[model] = nil
				elseif pickup.plot.data then
					local z = (model.PrimaryPart.Position.Z - pickup.plot.origin.Z) * pickup.plot.direction
					local machines = pickup.plot.data.life.machines
					if z >= 120 and machines.Packager then pickup.cookie.wrapped = true; Packaging.wrap(model, model.PrimaryPart) end
					if z >= 124 and machines.Boxer then pickup.cookie.boxed = true; Packaging.box(model, model.PrimaryPart) end
					local worth = Life.value(pickup.cookie)
					pickup.label.Text = Recipes[pickup.cookie.recipe].Name .. "\n$" .. context.Format(worth)
					pickup.prompt.ActionText = "Pick up • $" .. context.Format(worth)
					model:SetAttribute("CashValue", worth)
				end
			end
			for _, player in ipairs(Players:GetPlayers()) do
				local state = context.GetState(player)
				if state and not state.closing then
					if self.offers[player] and not self.offers[player].committing and self.offers[player].expires < os.clock() then self:CancelTrade(player) end
					local runtime = self:Runtime(player)
					runtime.data = state.data
					if player.Character ~= runtime.character then
						runtime.character, runtime.held, runtime.cookieTool = player.Character, nil, nil
						self:TradePrompt(player)
					end
					local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
					if root and not root:FindFirstChild("CookieTradePrompt") then self:TradePrompt(player) end
					if not runtime.pinTool or not runtime.pinTool.Parent or runtime.pinLevel ~= state.data.life.pin then
						if runtime.pinTool then runtime.pinTool:Destroy() end
						runtime.pinLevel, runtime.pinTool = state.data.life.pin, Tools.pin(player, state.data.life.pin)
					end
					if runtime.cookieTool and not runtime.cookieTool.Parent then runtime.cookieTool, runtime.held = nil, nil end
					if context.Usable(player) and Life.finishOven(state.data.life, os.time()) then
						self:Changed(player, state)
						context.Notify(player, "Your finishing oven is done! The cookie is worth 3x.")
					end
					if runtime.bargain and (runtime.bargain.expires < os.clock() or not W.near(player, runtime.bargain.customer.root.Position, 16)) then self:CloseBargain(runtime) end
					Appearance.step(player, runtime)
					self:Refresh(player)
				end
			end
			task.wait(0.25)
		end
	end)
	return self
end
function Server:Runtime(player)
	if not self.runtime[player] then
		local runtime = { player = player }
		runtime.appearance = player.CharacterAppearanceLoaded:Connect(function() Appearance.clear(runtime) end)
		self.runtime[player] = runtime
	end
	return self.runtime[player]
end
function Server:Held(player)
	local runtime = self:Runtime(player)
	return runtime.cookieTool and runtime.cookieTool.Parent == player.Character and runtime.held or nil
end
function Server:Refresh(player)
	local state, runtime = self.context.GetState(player), self:Runtime(player)
	if not state or state.closing then return end
	local b, trade = runtime.bargain, self.offers[player]
	local snapshot = { life = state.data.life, held = self:Held(player), hasPlot = state.plot ~= nil,
		busy = state.profile.activityLock ~= nil or state.profile.transacting == true }
	if b then snapshot.bargain = { name = b.customer.name, price = b.price, attempts = b.attempts, item = b.item } end
	if trade then snapshot.trade = { id = trade.id, from = trade.a.Name, to = trade.b.Name,
		giveA = Recipes[trade.itemA.recipe].Name .. " • $" .. self.context.Format(Life.value(trade.itemA)),
		giveB = trade.itemB and (Recipes[trade.itemB.recipe].Name .. " • $" .. self.context.Format(Life.value(trade.itemB))) or "Gift (no cookie requested)",
		confirmed = trade.confirmed[player] == true, otherConfirmed = trade.confirmed[player == trade.a and trade.b or trade.a] == true } end
	local signature = Http:JSONEncode(snapshot)
	if signature ~= runtime.lastSnapshot then runtime.lastSnapshot = signature ; self.stateRemote:FireClient(player, snapshot) end
	player:SetAttribute("HeldCookieId", self:Held(player))
	player:SetAttribute("CookieTradeBusy", snapshot.busy)
end
function Server:Changed(player, state)
	state.nextSave = math.min(state.nextSave, os.clock() + 2)
	self.context.Changed(player, state)
	self:Refresh(player)
end
function Server:ClearTool(player)
	local runtime = self:Runtime(player)
	if runtime.cookieTool then runtime.cookieTool:Destroy() end
	runtime.cookieTool, runtime.held = nil, nil
end
function Server:Cookie(plot, model, index, data)
	local cookie = { id = Http:GenerateGUID(false), recipe = index, mask = Crafting.encode(data.modifiers[tostring(index)]),
		quality = data.life.recipeLevels[tostring(index)], wrapped = false, boxed = false, baked = false }
	local pickup = { plot = plot, cookie = cookie }
	self.pickups[model] = pickup
	local root = model.PrimaryPart
	local worth = Life.value(cookie)
	model:SetAttribute("CashValue", worth)
	local text = W.label(root, Recipes[index].Name .. "\n$" .. self.context.Format(worth), 20)
	text.Parent.Size, text.TextSize, text.Parent.MaxDistance = UDim2.fromOffset(156, 36), 12, 18
	pickup.label = text
	text.Parent.StudsOffset = Vector3.new(0, 2, 0)
	pickup.prompt = W.prompt(root, "Pick up • $" .. self.context.Format(worth), 0.2, function(player)
		local state = self.context.Usable(player)
		if not state or plot.owner ~= player or model:GetAttribute("Collected") or model:GetAttribute("InventoryClaimed") then return end
		local ok, message = Life.add(state.data.life, cookie)
		if not ok then self.context.Notify(player, message) ; return end
		model:SetAttribute("InventoryClaimed", true)
		model:Destroy()
		self:Changed(player, state)
		self.context.Notify(player, "Cookie stored! Open Cookie bag to hold, eat, sell, or trade it.")
	end)
end
function Server:CloseBargain(runtime)
	if runtime.bargain and runtime.bargain.customer.reservedBy == runtime.player then
		runtime.bargain.customer.reservedUntil, runtime.bargain.customer.reservedBy = 0, nil
		runtime.bargain.customer.depart = true
	end
	runtime.bargain = nil
end
function Server:OfferCustomer(player, customer)
	local state, runtime = self.context.Usable(player), self:Runtime(player)
	if not state or not self:Held(player) or not Life.available(state.data.life, runtime.held) then self.context.Notify(player, "Hold a cookie from your bag first.") ; return end
	if customer.reservedUntil > os.clock() then self.context.Notify(player, "This customer is already talking to someone.") ; return end
	self:CloseBargain(runtime)
	local item = Life.find(state.data.life, runtime.held)
	customer.reservedUntil, customer.reservedBy = os.clock() + 30, player
	runtime.bargain = { customer = customer, item = item.id, base = Life.value(item), price = math.floor(Life.value(item) * 1.2), attempts = 0, expires = os.clock() + 30 }
	customer.label.Text = customer.name .. "\nLet's talk cookies!"
	self:Refresh(player)
	self.open:FireClient(player, "Customer")
end
function Server:TradePrompt(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local prompt = W.prompt(root, "Want a cookie?", 1, function(sender) self:Invite(sender, player) end)
	prompt.Name, prompt.ObjectText = "CookieTradePrompt", "@" .. player.Name
	prompt:SetAttribute("TargetUserId", player.UserId)
end
function Server:CancelTrade(player)
	local offer = self.offers[player]
	if not offer or offer.committing then return end
	self.offers[offer.a], self.offers[offer.b] = nil, nil
	for _, p in ipairs({ offer.a, offer.b }) do if p.Parent then self:Refresh(p) end end
end
function Server:Invite(a, b)
	local root = b.Character and b.Character:FindFirstChild("HumanoidRootPart")
	if a == b or not root or not W.near(a, root.Position, 12) then return end
	local sa, sb = self.context.Usable(a), self.context.Usable(b)
	if not sa or not sb or self.offers[a] or self.offers[b] then return end
	local ra, rb = self:Runtime(a), self:Runtime(b)
	if not self:Held(a) or not Life.available(sa.data.life, ra.held) then self.context.Notify(a, "Hold the cookie you want to offer first.") ; return end
	local itemB = self:Held(b) and Life.available(sb.data.life, rb.held) and Life.find(sb.data.life, rb.held) or nil
	local offer = { id = Http:GenerateGUID(false), a = a, b = b, itemA = Life.cookie(Life.find(sa.data.life, ra.held)), itemB = itemB and Life.cookie(itemB) or nil,
		confirmed = {}, expires = os.clock() + 45 }
	self.offers[a], self.offers[b] = offer, offer
	for _, p in ipairs({ a, b }) do self:Refresh(p) ; self.open:FireClient(p, "Trade") end
end
function Server:Confirm(player, id)
	local offer = self.offers[player]
	if not offer or offer.id ~= id or offer.committing then return end
	local root = offer.b.Character and offer.b.Character:FindFirstChild("HumanoidRootPart")
	if not root or offer.expires < os.clock() or not W.near(offer.a, root.Position, 12) then self:CancelTrade(player) ; return end
	local sa, sb = self.context.Usable(offer.a), self.context.Usable(offer.b)
	if not sa or not sb then return end
	if not Life.available(sa.data.life, offer.itemA.id)
		or not Life.sameCookie(Life.find(sa.data.life, offer.itemA.id), offer.itemA)
		or (offer.itemB and (not Life.available(sb.data.life, offer.itemB.id)
			or not Life.sameCookie(Life.find(sb.data.life, offer.itemB.id), offer.itemB))) then self:CancelTrade(player) ; return end
	offer.confirmed[player] = true
	if not offer.confirmed[offer.a] or not offer.confirmed[offer.b] then self:Refresh(offer.a) ; self:Refresh(offer.b) ; return end
	offer.committing = true
	self:ClearTool(offer.a)
	self:ClearTool(offer.b)
	task.spawn(function()
		local ok, message, pending = self.context.Trades:Exchange(offer.id, sa.profile, offer.a.UserId, offer.itemA.id, sb.profile, offer.b.UserId, offer.itemB and offer.itemB.id)
		if pending then
			for _ = 1, 12 do
				local doneA = self.context.Trades:Recover(sa.profile, offer.a.UserId, offer.id)
				local doneB = self.context.Trades:Recover(sb.profile, offer.b.UserId, offer.id)
				if doneA and doneB then pending = false ; break end
				task.wait(2)
			end
		end
		self.offers[offer.a], self.offers[offer.b] = nil, nil
		for _, entry in ipairs({ { offer.a, sa }, { offer.b, sb } }) do
			if entry[1].Parent then
				self.context.Notify(entry[1], pending and "Trade recovery is waiting for saving. Rejoin to recover safely." or message)
				self.context.Changed(entry[1], entry[2])
				self:Refresh(entry[1])
			elseif not entry[2].profile.activityLock then self.context.Profiles:Save(entry[2].profile, true) end
		end
		if not ok and not pending and offer.a.Parent then self.context.Notify(offer.a, message) end
	end)
end
function Server:Action(player, action, argument, plot)
	if type(action) ~= "string" then return end
	local runtime = self:Runtime(player)
	if os.clock() - (runtime.lastAction or -math.huge) < 0.15 then return end
	runtime.lastAction = os.clock()
	local state = self.context.Usable(player)
	if not state then return end
	local data, ok, message = state.data, false, nil
	if action == "Snapshot" then runtime.lastSnapshot = nil ; self:Refresh(player) ; return
	elseif action == "OpenMine" then self.open:FireClient(player, "Mine") ; return
	elseif action == "Home" then
		if state.plot then self.context.Home(player, state.plot) else self.context.Notify(player, "Claim a bakery first.") end
		return
	elseif action == "Equip" then
		if type(argument) ~= "string" or not Life.available(data.life, argument) then return end
		self:ClearTool(player)
		local item = Life.find(data.life, argument)
		runtime.cookieTool = Tools.cookie(player, item, function(id) runtime.held = id ; self:Refresh(player) end, function() self:Action(player, "Eat", item.id) end)
		self:Refresh(player)
		return
	elseif action == "Eat" then
		if argument ~= self:Held(player) then return end
		ok, message = Life.eat(data.life, argument, os.time(), math.random(1, 1000000))
		if ok then self:ClearTool(player) end
	elseif action == "UpgradeRecipe" then ok, message = Life.upgradeRecipe(data, argument)
	elseif action == "Mine" then
		local node = argument
		if type(node) ~= "table" or not table.find(self.features.ores, node) or node.hp <= 0 or not W.near(player, node.part.Position) then return end
		if not runtime.pinTool or runtime.pinTool.Parent ~= player.Character then self.context.Notify(player, "Equip your rolling pin first.") ; return end
		if os.clock() - (runtime.lastMine or 0) < 0.4 then return end
		runtime.lastMine = os.clock()
		node.hp = math.max(0, node.hp - Life.PinPower[data.life.pin])
		node.label.Text = "Dough ore • " .. node.hp .. " HP"
		if node.hp == 0 then
			data.life.dough = math.min(1e9, data.life.dough + node.reward)
			node.ready, node.part.Transparency, node.part.CanCollide, node.prompt.Enabled = os.clock() + 10, 1, false, false
			for _, chip in ipairs(node.chips) do chip.Transparency = 1 end
			ok, message = true, "+" .. node.reward .. " cookie dough!"
		end
	elseif action == "Pin" or action == "Dough" then
		if not W.near(player, self.features.mine, 22) then self.context.Notify(player, "Visit the dough mine workshop to upgrade.") ; return end
		if action == "Pin" then ok, message = Life.upgradePin(data) else ok, message = Life.upgradeDough(data, argument) end
	elseif action == "Machine" or action == "Bake" then
		local key = action == "Bake" and "FinishingOven" or argument
		if type(key) ~= "string" or not state.plot or (plot and state.plot ~= plot) then return end
		local machine = self.features.machines[state.plot][key]
		if not machine or not W.near(player, machine.pad.Position, 16) then self.context.Notify(player, "Visit that machine's purchase pad beside your conveyor.") ; return end
		if key == "FinishingOven" and data.life.machines[key] then
			ok, message = Life.startOven(data, self:Held(player), os.time())
			if ok then self:ClearTool(player) end
		else ok, message = Life.buyMachine(data, key) end
	elseif action == "Pitch" or action == "Sell" or action == "WalkAway" then
		local b = runtime.bargain
		if not b then return end
		if action == "WalkAway" then self:CloseBargain(runtime) ; self:Refresh(player) ; return end
		if b.customer.reservedBy ~= player or b.expires < os.clock() or not W.near(player, b.customer.root.Position, 12) or b.item ~= self:Held(player) or not Life.available(data.life, b.item) then self:CloseBargain(runtime) ; self:Refresh(player) ; return end
		if action == "Pitch" then
			local accepted, price = Life.pitch(b.base, b.attempts, math.random())
			if accepted then b.attempts += 1 ; b.price = price ; message = "They like your pitch!" else b.customer.label.Text = b.customer.name .. "\nToo pushy! I'm leaving." ; self:CloseBargain(runtime) ; message = "The customer got annoyed and walked away." end
		elseif b.price <= Life.MaxCurrency - data.bank then
			Life.remove(data.life, b.item)
			data.bank += b.price
			ok, message = true, "Sold! $" .. self.context.Format(b.price) .. " added to your collection register."
			self:ClearTool(player)
			self:CloseBargain(runtime)
		else message = "Collect earnings first; your register is full." end
	elseif action == "ConfirmTrade" then self:Confirm(player, argument) ; return
	elseif action == "CancelTrade" then self:CancelTrade(player) ; return
	end
	if ok then self:Changed(player, state) else self:Refresh(player) end
	if message then self.context.Notify(player, message) end
end
return Server
