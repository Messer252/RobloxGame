local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local shared = ReplicatedStorage:WaitForChild("CookieTycoon")
local Progression = require(shared.Progression)
local Recipes = require(shared.Recipes)
local Crafting = require(shared.CookieCrafting)
local Challenges = require(shared.Challenges)
local ProfileStore = require(script.ProfileStore)
local Settings = require(script.Settings)
local World = require(script.World)
local ChallengeWorld = require(script.ChallengeWorld)
local CommerceServer = require(script.CommerceServer)

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = shared
local requestAction = Instance.new("RemoteEvent")
requestAction.Name = "RequestAction"
requestAction.Parent = remotes
local openShop = Instance.new("RemoteEvent")
openShop.Name = "OpenShop"
openShop.Parent = remotes
local requestPurchase = Instance.new("RemoteEvent")
requestPurchase.Name = "RequestPurchase"
requestPurchase.Parent = remotes
local refreshPasses = Instance.new("RemoteEvent")
refreshPasses.Name = "RefreshPasses"
refreshPasses.Parent = remotes
local feedback = Instance.new("RemoteEvent")
feedback.Name = "Feedback"
feedback.Parent = remotes

local storeOk, store = pcall(function() return DataStoreService:GetDataStore(Settings.DataStoreName) end)
if not storeOk then
	local initializationError = store
	store = { UpdateAsync = function() error(initializationError) end }
end
local profiles = ProfileStore.new(store, {
	clock = os.time, wait = task.wait, copy = Progression.normalize, lease = Settings.SessionLeaseSeconds,
})
local sessions = {}
local pendingLoads = {}
local shuttingDown = false

local function notify(player, message)
	player:SetAttribute("Notice", message)
	player:SetAttribute("NoticeId", (player:GetAttribute("NoticeId") or 0) + 1)
end

local function sync(player, state)
	local data = state.data
	player.leaderstats.Cash.Value = data.cash
	player.leaderstats.Rebirths.Value = data.rebirths
	player.leaderstats.GoldenChips.Value = data.chips
	player:SetAttribute("Bank", data.bank)
	player:SetAttribute("RecipeCount", data.unlocked)
	player:SetAttribute("OvenLevel", data.level)
	player:SetAttribute("Rebirths", data.rebirths)
	player:SetAttribute("GoldenChips", data.chips)
	player:SetAttribute("MusicEnabled", data.audio.music)
	player:SetAttribute("EffectsEnabled", data.audio.effects)
	player:SetAttribute("ChallengeIndex", data.challenges.index)
	player:SetAttribute("ChallengeActive", data.challenges.active)
	player:SetAttribute("ChallengeFound", Challenges.encode(data.challenges))
	player:SetAttribute("ChallengeComplete", Challenges.isComplete(data.challenges))
	for key, level in pairs(data.permanent) do player:SetAttribute(key .. "Level", level) end
	for index = 1, #Recipes do
		player:SetAttribute("RecipeModifiers_" .. index, Crafting.encode(data.modifiers[tostring(index)]))
	end
end

local function usable(player)
	local state = sessions[player]
	if not state or state.closing or state.profile.lost or state.profile.closed then return nil end
	if state.profile.transacting or (state.receiptWorkers or 0) > 0 then return nil end
	if not state.profile.sessionOnly and os.time() >= state.profile.expiresAt then return nil end
	return state
end

local function saveState(player, state, release)
	if state.profile.sessionOnly then return true end
	if not release and (state.profile.saving or state.profile.closing or state.profile.transacting or (state.receiptWorkers or 0) > 0) then return false end
	if not state.closing then player:SetAttribute("DataStatus", "Saving") end
	local ok, reason, detail = profiles:Save(state.profile, release)
	if not state.closing then
		local purchasePending = state.profile.transacting or (state.receiptWorkers or 0) > 0
		player:SetAttribute("DataStatus", purchasePending and "PurchasePending" or ok and "Saved" or "SaveFailed")
		state.nextSave = os.clock() + (ok and Settings.AutosaveSeconds or 10)
	end
	if not ok and reason ~= "busy" then
		warn("Cookie Corner save failed for " .. player.UserId .. ": " .. tostring(reason) .. " " .. tostring(detail or ""))
		if reason == "lost" then
			player:SetAttribute("DataReady", false)
			player:Kick("Your bakery was opened in another server. Rejoin to safely load your latest save.")
		end
	end
	return ok
end

local commerce = CommerceServer.start({
	Profiles = profiles,
	AutosaveSeconds = Settings.AutosaveSeconds,
	GetState = function(player) return sessions[player] end,
	IsLoading = function(player) return pendingLoads[player] == true end,
	IsClosing = function() return shuttingDown end,
	Notify = notify,
	Refresh = function(player, state)
		sync(player, state)
		if state.plot then World.refresh(state.plot, state.data, state.perks) end
	end,
}, requestPurchase, refreshPasses)

local allowedActions = { Collect = true, BuyRecipe = true, BuyModifier = true, UpgradeOven = true, UpgradePermanent = true, Rebirth = true, SetAudioPreferences = true, ChallengeAction = true }
local function onAction(player, action, argument, sourcePlot)
	if type(action) ~= "string" or not allowedActions[action] then return end
	local state = usable(player)
	if not state then return end
	if action == "ChallengeAction" then
		local now = os.clock()
		if now - (state.lastChallengeAction or -math.huge) < 0.5 then return end
		state.lastChallengeAction = now
		if not ChallengeWorld.IsNearNPC(player) then
			notify(player, "Visit Baker Biscuit in the plaza to start or finish a hunt.")
			return
		end
		local success, message, reward = Challenges.interact(state.data, Progression.MAX_CASH)
		if success then
			sync(player, state)
			if state.plot then World.updateBank(state.plot, state.data) end
			state.nextSave = math.min(state.nextSave, now + 2)
			feedback:FireClient(player, (reward or 0) > 0 and "Collect" or "Claim")
		end
		if message then notify(player, message) end
		return
	end
	if action == "SetAudioPreferences" then
		if type(argument) ~= "table" or type(argument.music) ~= "boolean" or type(argument.effects) ~= "boolean" then return end
		local now = os.clock()
		if now - (state.lastAudioPreference or -math.huge) < 0.2 then return end
		state.lastAudioPreference = now
		state.data.audio.music, state.data.audio.effects = argument.music, argument.effects
		player:SetAttribute("MusicEnabled", argument.music)
		player:SetAttribute("EffectsEnabled", argument.effects)
		-- Debounce settings changes; they are included in normal/final saves too.
		state.nextSave = math.min(state.nextSave, now + 5)
		return
	end
	if not state.plot or state.plot.owner ~= player then return end
	-- Prompts carry their source plot; menu actions intentionally work anywhere.
	if sourcePlot and sourcePlot ~= state.plot then return end
	local now = os.clock()
	if now - state.lastAction < 0.2 then return end
	state.lastAction = now
	local data = state.data
	local success, message
	if action == "Collect" then
		local amount = Progression.collect(data)
		success, message = amount > 0, "Collected $" .. Progression.format(amount) .. "."
	elseif action == "BuyRecipe" then
		if argument ~= nil and argument ~= data.unlocked + 1 then return end
		success, message = Progression.buyRecipe(data)
	elseif action == "UpgradeOven" then
		success, message = Progression.upgradeOven(data)
	elseif action == "UpgradePermanent" then
		if type(argument) ~= "string" or not Progression.Permanent[argument] then return end
		success, message = Progression.buyPermanent(data, argument)
	elseif action == "BuyModifier" then
		if type(argument) ~= "table" then return end
		success, message = Progression.buyModifier(data, argument.Recipe, argument.Modifier)
	elseif action == "Rebirth" then
		-- A confirmation for an old rebirth count cannot submit a newer rebirth.
		if argument ~= data.rebirths then return end
		success, message = Progression.rebirth(data)
		if success then state.nextBake = now + Progression.interval(data, state.perks) end
	end
	if success then
		feedback:FireClient(player, action)
		state.nextBake = math.min(state.nextBake, now + Progression.interval(data, state.perks))
		sync(player, state)
		if action == "Collect" then World.updateBank(state.plot, data) else World.refresh(state.plot, data, state.perks) end
		if action == "Rebirth" or action == "UpgradePermanent" or action == "BuyModifier" then
			-- Save the entire reset/reward transaction together, without one write per click.
			state.nextSave = math.min(state.nextSave, now + 2)
		end
	end
	if not success and message then feedback:FireClient(player, "Error") end
	if message then notify(player, message) end
	return success == true
end

World.create(function(player, plot)
	local state = usable(player)
	if not state then return end
	if state.plot then
		notify(player, "You already own a bakery. Use your Bakery menu.")
		return
	end
	if plot.owner then return end
	plot.owner = player
	state.plot = plot
	state.nextBake = os.clock() + Progression.interval(state.data, state.perks)
	player:SetAttribute("HasBakery", true)
	World.refresh(plot, state.data, state.perks)
	task.spawn(World.spawnPlayer, player, plot)
	feedback:FireClient(player, "Claim")
	notify(player, "Bakery claimed! Your saved recipes and upgrades are restored.")
end, onAction, function(player, plot)
	local state = usable(player)
	if state and state.plot == plot and plot.owner == player then openShop:FireClient(player, "Bakery") end
end, function(player, plot)
	local state = usable(player)
	if state and state.plot == plot and plot.owner == player then openShop:FireClient(player, "Workshop") end
end)

ChallengeWorld.create(workspace:WaitForChild("CookieTycoonWorld"), function(player)
	if usable(player) then openShop:FireClient(player, "Challenges") end
end, function(player, itemId)
	local state = usable(player)
	if not state then return end
	local success, message = Challenges.find(state.data, itemId)
	if not success then return end
	sync(player, state)
	state.nextSave = math.min(state.nextSave, os.clock() + 2)
	feedback:FireClient(player, "BuyModifier")
	notify(player, message)
end)

requestAction.OnServerEvent:Connect(function(player, action, argument)
	onAction(player, action, argument, nil)
end)

local function addPlayer(player)
	if pendingLoads[player] or sessions[player] then return end
	pendingLoads[player] = true
	player:SetAttribute("DataReady", false)
	player:SetAttribute("DataStatus", "Loading")
	player:SetAttribute("HasBakery", false)
	player:SetAttribute("NearChallengeNPC", false)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	stats.Parent = player
	for _, name in ipairs({ "Cash", "Rebirths", "GoldenChips" }) do
		local value = Instance.new(name == "Cash" and "NumberValue" or "IntValue")
		value.Name = name
		value.Parent = stats
	end
	local profile, reason, detail = profiles:Load(player.UserId, HttpService:GenerateGUID(false))
	if not profile and reason == "unavailable" and RunService:IsStudio() and Settings.AllowStudioSessionOnly then
		profile = { data = Progression.newData(), sessionOnly = true, expiresAt = math.huge }
		warn("Cookie Corner: Studio session-only mode; this player's progress WILL NOT SAVE.")
	end
	if player.Parent ~= Players or shuttingDown then
		if profile and not profile.sessionOnly then
			local ok = profiles:Save(profile, true)
			if not ok then warn("Cookie Corner: could not release a profile that loaded after departure.") end
		end
		pendingLoads[player] = nil
		return
	end
	if not profile then
		pendingLoads[player] = nil
		warn("Cookie Corner load failed for " .. player.UserId .. ": " .. tostring(reason) .. " " .. tostring(detail or ""))
		local message = "Your bakery could not load. Your saved progress has not been replaced. Please rejoin in a moment."
		if reason == "locked" then message = "Your bakery is still open in another server. Wait a moment, then rejoin." end
		if reason == "unsupported" then message = "Your save needs a compatible game version. Please contact the game creator." end
		player:Kick(message)
		return
	end
	local state = {
		profile = profile, data = profile.data, plot = nil, closing = false,
		perks = { DoubleIncome = false, DoubleSpeed = false }, receiptWorkers = 0,
		nextBake = 0, nextVisual = 0, lastAction = -math.huge,
		nextSave = os.clock() + Settings.AutosaveSeconds + math.random() * 5,
	}
	sessions[player] = state
	state.characterConnection = player.CharacterAdded:Connect(function()
		if not state.closing and state.plot then task.spawn(World.spawnPlayer, player, state.plot) end
	end)
	pendingLoads[player] = nil
	sync(player, state)
	player:SetAttribute("DataStatus", profile.sessionOnly and "SessionOnly" or "Saved")
	player:SetAttribute("DataReady", true)
	commerce:StartPlayer(player)
	notify(player, profile.sessionOnly and "STUDIO SESSION ONLY: progress will not save." or "Progress loaded. Claim any free bakery to continue!")
end

local function closePlayer(player)
	local state = sessions[player]
	if not state or state.closing then return end
	state.closing = true
	if state.characterConnection then state.characterConnection:Disconnect() end
	player:SetAttribute("DataReady", false)
	if state.plot then
		local plot = state.plot
		World.releasePlayer(player, plot)
		state.plot = nil
		plot.owner = nil
		World.refresh(plot, nil)
	end
	saveState(player, state, true)
	sessions[player] = nil
end

Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(closePlayer)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(addPlayer, player) end

task.spawn(function()
	local nextNPCCheck = 0
	while not shuttingDown do
		local now = os.clock()
		local checkNPC = now >= nextNPCCheck
		if checkNPC then nextNPCCheck = now + 0.5 end
		for player, state in pairs(sessions) do
			if checkNPC and not state.closing then player:SetAttribute("NearChallengeNPC", ChallengeWorld.IsNearNPC(player)) end
			if usable(player) and state.plot and now >= state.nextBake then
				local interval = Progression.interval(state.data, state.perks)
				local batches = math.min(5, math.floor((now - state.nextBake) / interval) + 1)
				state.nextBake = now + interval
				state.data.bank = math.min(Progression.MAX_CASH, state.data.bank + Progression.batchValue(state.data, state.perks) * batches)
				World.updateBank(state.plot, state.data)
				sync(player, state)
				if now >= state.nextVisual then
					state.nextVisual = now + 1.6
					World.animate(state.plot, state.data, state.perks)
				end
			end
		end
		task.wait(0.1)
	end
end)

task.spawn(function()
	while not shuttingDown do
		for player, state in pairs(sessions) do
			if not state.closing and not state.profile.sessionOnly then
				if os.time() >= state.profile.expiresAt then
					player:SetAttribute("DataReady", false)
					player:Kick("Saving could not reconnect safely. Please rejoin to load your last saved bakery.")
				elseif os.clock() >= state.nextSave and not state.profile.saving and not state.profile.transacting and state.receiptWorkers == 0 then
					state.nextSave = os.clock() + Settings.AutosaveSeconds
					task.spawn(saveState, player, state, false)
				end
			end
		end
		task.wait(1)
	end
end)

game:BindToClose(function()
	shuttingDown = true
	for player in pairs(sessions) do task.spawn(closePlayer, player) end
	local deadline = os.clock() + 25
	while (next(sessions) or next(pendingLoads)) and os.clock() < deadline do task.wait(0.1) end
	if next(sessions) or next(pendingLoads) then warn("Cookie Corner: shutdown ended before every save request completed.") end
end)
