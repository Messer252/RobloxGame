local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("CookieTycoon")
local Catalog = require(shared.ShopCatalog)
local Rewards = require(shared.PurchaseRewards)
local Progression = require(shared.Progression)
local Commerce = {}
Commerce.__index = Commerce
local GRANTED = Enum.ProductPurchaseDecision.PurchaseGranted
local PENDING = Enum.ProductPurchaseDecision.NotProcessedYet

function Commerce:_state(player)
	local state = self.context.GetState(player)
	if not state or state.closing or state.profile.closed or state.profile.closing or state.profile.lost then return nil end
	if not state.profile.sessionOnly and os.time() >= state.profile.expiresAt then return nil end
	return state
end

function Commerce:_syncPerks(player, state)
	if self.context.GetState(player) ~= state or state.closing then return end
	player:SetAttribute("DoubleIncomeOwned", state.perks.DoubleIncome == true)
	player:SetAttribute("DoubleSpeedOwned", state.perks.DoubleSpeed == true)
	player:SetAttribute("ThirdCardSlotOwned", state.perks.ThirdCardSlot == true)
	player:SetAttribute("PassesReady", state.passesReady == true)
	state.nextBake = math.min(state.nextBake, os.clock() + Progression.interval(state.data, state.perks))
	self.context.Refresh(player, state)
end

function Commerce:RefreshPasses(player)
	local state = self:_state(player)
	if not state or state.checkingPasses then return end
	state.checkingPasses = true
	local allChecked = true
	-- Keep honoring owned passes even if their buttons are hidden from PassOrder.
	for key, configured in pairs(Catalog.Passes) do
		local offer = Catalog.resolve("Pass", configured.Id)
		if offer then
			local ok, owned
			for attempt = 1, 3 do
				ok, owned = pcall(function() return MarketplaceService:UserOwnsGamePassAsync(player.UserId, offer.Id) end)
				if ok then break end
				if attempt < 3 then task.wait(attempt) end
				if self:_state(player) ~= state then break end
			end
			if self:_state(player) ~= state then
				state.checkingPasses = false
				return
			end
			if ok then
				-- Preserve a confirmed purchase if a cached ownership read is stale.
				state.perks[key] = state.perks[key] == true or owned == true
			else
				allChecked = false
				warn("Cookie Corner: could not check pass ownership for " .. player.UserId .. " (" .. key .. ").")
			end
		end
	end
	state.checkingPasses = false
	state.passesReady = allChecked
	self:_syncPerks(player, state)
	if not allChecked then
		task.delay(30, function() if self:_state(player) == state then self:RefreshPasses(player) end end)
	end
end

function Commerce:StartPlayer(player)
	local state = self:_state(player)
	if not state then return end
	player:SetAttribute("CommerceReady", not state.profile.sessionOnly)
	player:SetAttribute("PurchasePending", false)
	player:SetAttribute("ShopPromptOpen", false)
	task.spawn(function() self:RefreshPasses(player) end)
end

function Commerce:Prompt(player, kind, key)
	if (kind ~= "Pass" and kind ~= "Product") or type(key) ~= "string" then return end
	local state = self:_state(player)
	if not state or state.profile.sessionOnly or state.profile.transacting or (state.receiptWorkers or 0) > 0 then return end
	if state.shopPrompt or os.clock() - (state.lastShopPrompt or -math.huge) < 3 then return end
	local offer = Catalog.offer(kind, key)
	if not offer then
		self.context.Notify(player, "This item is not available yet.")
		return
	end
	if kind == "Product" and offer.BoostTier and offer.BoostTier ~= state.data.boosts.paidTier + 1 then
		self.context.Notify(player, "Buy the next permanent income stage shown in the shop.")
		return
	end
	state.lastShopPrompt = os.clock()
	-- Set this before any yielding ownership request, preventing overlapping prompts.
	local prompt = { Kind = kind, Id = offer.Id }
	state.shopPrompt = prompt
	player:SetAttribute("ShopPromptOpen", true)
	local function cancel(message)
		if state.shopPrompt == prompt then state.shopPrompt = nil end
		player:SetAttribute("ShopPromptOpen", false)
		if message then self.context.Notify(player, message) end
	end
	if kind == "Pass" then
		local ok, owned = pcall(function() return MarketplaceService:UserOwnsGamePassAsync(player.UserId, offer.Id) end)
		if self:_state(player) ~= state then
			cancel()
			return
		end
		if not ok then
			cancel("Ownership could not be checked. Please try again shortly.")
			return
		end
		if owned or state.perks[key] then
			state.perks[key] = true
			self:_syncPerks(player, state)
			cancel("You already own " .. offer.Name .. ".")
			return
		end
	else
		if offer.Cash and not Rewards.canFitCash(state.data, offer.Cash, Progression.MAX_CASH) then
			cancel("Spend some cookie cash before buying another bundle.")
			return
		end
		local receiptCount = 0
		for _ in pairs(state.profile.receipts) do receiptCount += 1 end
		if receiptCount >= Catalog.MaxPromptedReceipts then
			cancel("Cash bundles are unavailable for this bakery. Please contact the creator.")
			return
		end
	end
	if self:_state(player) ~= state or state.profile.transacting or (state.receiptWorkers or 0) > 0 then
		cancel()
		return
	end
	local ok = pcall(function()
		if kind == "Pass" then MarketplaceService:PromptGamePassPurchase(player, offer.Id)
		else MarketplaceService:PromptProductPurchase(player, offer.Id) end
	end)
	if not ok then cancel("Roblox could not open the purchase window. Please try again.") end
end

function Commerce:_fulfill(player, state, receipt, product)
	local attempt = 0
	while player.Parent == Players and not self.context.IsClosing() do
		if self:_state(player) ~= state or state.profile.sessionOnly then return PENDING end
		local ok, reason, detail = self.context.Profiles:GrantReceipt(state.profile, receipt.PurchaseId, receipt.ProductId, function(data)
			return Rewards.product(data, product, Progression.MAX_CASH)
		end)
		if ok then
			if self.context.GetState(player) == state and not state.closing then
				state.nextSave = os.clock() + self.context.AutosaveSeconds
				self.context.Refresh(player, state)
				if reason ~= "duplicate" then
					self.context.Notify(player, product.BoostTier and (2 ^ product.BoostTier .. "x permanent cookie income saved! Survives rebirth.")
						or "$" .. Progression.format(product.Cash) .. " cookie cash purchased and saved! Cash resets on rebirth.")
				end
			end
			return GRANTED -- The cash AND receipt ID are now durable in the same record.
		end
		if reason == "busy" then
			task.wait(0.2)
		elseif reason == "unavailable" then
			attempt += 1
			warn("Cookie Corner: purchase save pending for " .. player.UserId .. ": " .. tostring(detail or reason))
			if attempt == 1 then self.context.Notify(player, "Your purchase is waiting for saving to reconnect. Please wait.") end
			task.wait(math.min(10, attempt * 2))
		else
			warn("Cookie Corner: purchase not acknowledged for " .. player.UserId .. ": " .. tostring(reason))
			if reason == "lost" then
				player:Kick("Your purchase is pending on a newer bakery session. Rejoin to load it safely.")
			elseif reason == "capacity" then
				self.context.Notify(player, "Your cash bundle is pending. Spend some cash and rejoin to receive it.")
			end
			return PENDING
		end
	end
	return PENDING
end

function Commerce:ProcessReceipt(receipt)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then return PENDING end
	-- Roblox does not periodically retry NotProcessedYet. Wait for this join's
	-- profile load and retry transient save failures inside the callback itself.
	while self.context.IsLoading(player) and player.Parent == Players and not self.context.IsClosing() do task.wait(0.1) end
	local state = self:_state(player)
	if not state or state.profile.sessionOnly then return PENDING end
	-- An already durable receipt remains acknowledgeable even after an offer is
	-- retired. New/ungranted receipts still need their original product mapping.
	if state.profile.receipts[receipt.PurchaseId] == receipt.ProductId then return GRANTED end
	local product = Catalog.resolve("Product", receipt.ProductId)
	if not product or not Catalog.validProduct(product) then
		warn("Cookie Corner: unconfigured product receipt " .. tostring(receipt.ProductId) .. "; it remains pending.")
		return PENDING
	end
	state.receiptWorkers = (state.receiptWorkers or 0) + 1
	player:SetAttribute("PurchasePending", true)
	player:SetAttribute("DataStatus", "PurchasePending")
	local ok, decision = pcall(function() return self:_fulfill(player, state, receipt, product) end)
	state.receiptWorkers -= 1
	if self.context.GetState(player) == state and not state.closing then
		local pending = state.profile.transacting or state.receiptWorkers > 0
		player:SetAttribute("PurchasePending", pending)
		player:SetAttribute("DataStatus", pending and "PurchasePending" or ok and "Saved" or "SaveFailed")
	end
	if not ok then
		warn("Cookie Corner receipt handler failed: " .. tostring(decision))
		return PENDING
	end
	return decision
end

function Commerce.start(context, requestPurchase, refreshPasses)
	local self = setmetatable({ context = context }, Commerce)
	-- This is the experience's only ProcessReceipt owner. Never grant products
	-- from PromptProductPurchaseFinished or a client-supplied success message.
	MarketplaceService.ProcessReceipt = function(receipt) return self:ProcessReceipt(receipt) end
	requestPurchase.OnServerEvent:Connect(function(player, kind, key) self:Prompt(player, kind, key) end)
	refreshPasses.OnServerEvent:Connect(function(player)
		local state = self:_state(player)
		if not state or os.clock() - (state.lastPassRefresh or -math.huge) < 10 then return end
		state.lastPassRefresh = os.clock()
		task.spawn(function() self:RefreshPasses(player) end)
	end)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, id, wasPurchased)
		local state = self:_state(player)
		if not state then return end
		if state.shopPrompt and state.shopPrompt.Kind == "Pass" and state.shopPrompt.Id == id then
			state.shopPrompt = nil
			player:SetAttribute("ShopPromptOpen", false)
		end
		local pass, key = Catalog.resolve("Pass", id)
		if wasPurchased and pass then
			-- This event is server-side: Roblox supplies the confirmed final outcome.
			state.perks[key] = true
			self:_syncPerks(player, state)
			context.Notify(player, pass.Name .. " unlocked! It stays through every rebirth.")
		end
	end)
	MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, id)
		local player = Players:GetPlayerByUserId(userId)
		local state = player and self:_state(player)
		if state and state.shopPrompt and state.shopPrompt.Kind == "Product" and state.shopPrompt.Id == id then
			state.shopPrompt = nil
			player:SetAttribute("ShopPromptOpen", false)
		end
	end)
	return self
end

return Commerce
