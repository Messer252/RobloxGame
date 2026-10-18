-- Run with the official Luau CLI from the repository root: luau tests/run.luau
local Recipes = require("../src/shared/Recipes")
local Progression = require("../src/shared/Progression")
local ProfileStore = require("../src/server/ProfileStore")
local Catalog = require("../src/shared/ShopCatalog")
local Rewards = require("../src/shared/PurchaseRewards")
local passed, failed = 0, 0

local function equal(actual, expected)
	assert(actual == expected, "expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local function near(actual, expected)
	assert(math.abs(actual - expected) < 0.000001, "values differ: " .. actual .. " vs " .. expected)
end
local function test(name, callback)
	local ok, message = pcall(callback)
	if ok then
		passed += 1
		print("PASS " .. name)
	else
		failed += 1
		print("FAIL " .. name .. ": " .. tostring(message))
	end
end
local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, child in pairs(value) do result[key] = copy(child) end
	return result
end
local function same(actual, expected)
	if type(actual) ~= "table" or type(expected) ~= "table" then
		equal(actual, expected)
		return
	end
	for key, value in pairs(actual) do same(value, expected[key]) end
	for key, value in pairs(expected) do same(actual[key], value) end
end

local function fakeStore()
	local store = { records = {}, calls = 0, errorsRemaining = 0, commitErrorsRemaining = 0 }
	function store:UpdateAsync(key, transform)
		self.calls += 1
		if self.errorsRemaining > 0 then
			self.errorsRemaining -= 1
			error("simulated DataStore outage")
		end
		local result = transform(copy(self.records[key]))
		if self.beforeCommit then
			local callback = self.beforeCommit
			self.beforeCommit = nil
			callback(self, key)
			-- Roblox may rerun the transform if another server writes concurrently.
			result = transform(copy(self.records[key]))
		end
		if result == nil then return nil end
		self.records[key] = copy(result)
		if self.commitErrorsRemaining > 0 then
			self.commitErrorsRemaining -= 1
			error("simulated network error AFTER a successful commit")
		end
		return copy(result)
	end
	return store
end

local function harness(store)
	local time = 1000
	local onWait
	local manager = ProfileStore.new(store, {
		clock = function() return time end,
		wait = function(seconds)
			time += seconds
			if onWait then onWait() end
		end,
		copy = Progression.normalize,
		lease = 180,
	})
	return manager, function(seconds) time += seconds end, function(callback) onWait = callback end
end

test("30 unique cookies with increasing costs, income, and valid colors", function()
	equal(#Recipes, 30)
	local names = {}
	for index, recipe in ipairs(Recipes) do
		assert(not names[recipe.Name])
		names[recipe.Name] = true
		if index > 1 then
			assert(recipe.Cost > Recipes[index - 1].Cost)
			assert(recipe.Value > Recipes[index - 1].Value)
		end
		for _, rgb in ipairs({ recipe.Color, recipe.Accent }) do
			equal(#rgb, 3)
			for _, channel in ipairs(rgb) do assert(channel >= 0 and channel <= 255) end
		end
	end
end)

test("initial production and oven upgrade charge", function()
	local data = Progression.newData()
	equal(Progression.batchValue(data), 5)
	equal(Progression.interval(data), 3)
	local before = copy(data)
	assert(not Progression.upgradeOven(data))
	same(data, before)
	data.cash = 500
	assert(Progression.upgradeOven(data))
	equal(data.cash, 0)
	equal(data.level, 2)
	near(Progression.interval(data), 2.4)
end)

test("recipe unlocks require funds, charge exactly, and stop at the end", function()
	local data = Progression.newData()
	assert(not Progression.buyRecipe(data))
	equal(data.unlocked, 1)
	for index = 2, #Recipes do
		data.cash = Recipes[index].Cost
		assert(Progression.buyRecipe(data))
		equal(data.cash, 0)
		equal(data.unlocked, index)
	end
	assert(not Progression.buyRecipe(data))
	equal(data.unlocked, 30)
end)

test("collection keeps overflow in the bank without deleting earnings", function()
	local data = Progression.newData()
	data.cash = Progression.MAX_CASH - 10
	data.bank = 50
	equal(Progression.collect(data), 10)
	equal(data.cash, Progression.MAX_CASH)
	equal(data.bank, 40)
	equal(Progression.collect(data), 0)
	equal(data.bank, 40)
end)

test("failed rebirth changes no currency, recipes, or upgrades", function()
	local data = Progression.newData()
	data.cash = 5000000
	local before = copy(data)
	assert(not Progression.rebirth(data))
	same(data, before)
	data.unlocked = 18
	data.cash = 4999999
	before = copy(data)
	assert(not Progression.rebirth(data))
	same(data, before)
end)

test("rebirth counts banked cash, resets the run, and retains permanent upgrades", function()
	local data = Progression.newData()
	data.cash, data.bank, data.unlocked, data.level = 2000000, 3000000, 18, 9
	data.chips = 2
	data.permanent = { Yield = 2, Speed = 1, Starter = 3 }
	assert(Progression.rebirth(data))
	equal(data.cash, 4500)
	equal(data.bank, 0)
	equal(data.unlocked, 1)
	equal(data.level, 1)
	equal(data.rebirths, 1)
	equal(data.chips, 7)
	same(data.permanent, { Yield = 2, Speed = 1, Starter = 3 })
	local requirement = Progression.rebirthRequirement(data)
	equal(requirement.Cash, 12500000)
	equal(requirement.Recipes, 20)
	equal(requirement.Reward, 7)
	assert(not Progression.rebirth(data)) -- Replayed confirmation cannot award twice.
	equal(data.chips, 7)
end)

test("Golden Chip upgrades spend only chips and improve the correct stat", function()
	local data = Progression.newData()
	data.cash, data.bank, data.chips = 1234, 98, 10
	assert(Progression.buyPermanent(data, "Yield"))
	equal(data.chips, 7)
	equal(data.permanent.Yield, 1)
	near(Progression.multiplier(data), 1.25)
	equal(Progression.batchValue(data), 6)
	assert(Progression.buyPermanent(data, "Speed"))
	equal(data.chips, 3)
	near(Progression.interval(data), 3 / 1.08)
	assert(Progression.buyPermanent(data, "Starter"))
	equal(data.chips, 1)
	equal(data.cash, 1234)
	equal(data.bank, 98)
	local before = copy(data)
	assert(not Progression.buyPermanent(data, "Yield"))
	assert(not Progression.buyPermanent(data, "NotARealUpgrade"))
	same(data, before)
end)

test("all upgrade caps and rebirth limits refuse further charges", function()
	local data = Progression.newData()
	data.cash, data.chips = Progression.MAX_CASH, 100000
	data.level = Progression.MAX_OVEN_LEVEL
	assert(not Progression.upgradeOven(data))
	for key, definition in pairs(Progression.Permanent) do
		data.permanent[key] = definition.Max
		assert(not Progression.buyPermanent(data, key))
	end
	data.rebirths = Progression.MAX_REBIRTHS
	data.unlocked = 30
	local before = copy(data)
	assert(not Progression.rebirth(data))
	same(data, before)
	assert(Progression.interval(data) >= 0.4)
	local requirement = Progression.rebirthRequirement(data)
	equal(requirement.Recipes, 30)
	equal(requirement.Cash, Progression.MAX_REBIRTH_CASH)
end)

test("saved data validation rejects non-finite values and copies nested upgrades", function()
	local input = {
		cash = 0 / 0, bank = math.huge, unlocked = 999, level = -1, rebirths = 1.9, chips = -100,
		permanent = { Yield = 1000, Speed = "bad", Starter = 2 }, plot = "must not persist",
	}
	local data = Progression.normalize(input)
	equal(data.cash, 0)
	equal(data.bank, 0)
	equal(data.unlocked, 30)
	equal(data.level, 1)
	equal(data.rebirths, 1)
	equal(data.chips, 0)
	equal(data.permanent.Yield, 20)
	equal(data.permanent.Speed, 0)
	equal(data.plot, nil)
	data.permanent.Starter = 4
	equal(input.permanent.Starter, 2)
end)

test("new profile acquires a session lease and renews it when saved", function()
	local store = fakeStore()
	local manager, advance = harness(store)
	local profile = assert(manager:Load(1, "server-A"))
	equal(profile.data.unlocked, 1)
	equal(store.records.Player_1.Session.Id, "server-A")
	equal(profile.expiresAt, 1180)
	advance(45)
	profile.data.cash = 100
	assert(manager:Save(profile, false))
	equal(store.records.Player_1.Data.cash, 100)
	equal(profile.expiresAt, 1225)
end)

test("leave/rejoin restores cash, uncollected earnings, recipes, rebirths, and upgrades", function()
	local store = fakeStore()
	local manager = harness(store)
	local profile = assert(manager:Load(99, "session-A"))
	profile.data = { cash = 123456, bank = 789, unlocked = 21, level = 8, rebirths = 3, chips = 17, permanent = { Yield = 4, Speed = 3, Starter = 2 } }
	local expected = copy(profile.data)
	assert(manager:Save(profile, true))
	equal(store.records.Player_99.Session, nil)
	assert(profile.closed)
	local rejoined = assert(manager:Load(99, "session-B"))
	same(rejoined.data, expected)
	equal(store.records.Player_99.Session.Id, "session-B")
end)

test("active session rejects a second server without overwriting any data", function()
	local store = fakeStore()
	local manager = harness(store)
	assert(manager:Load(5, "server-A"))
	local before = copy(store.records.Player_5)
	local profile, reason = manager:Load(5, "server-B")
	equal(profile, nil)
	equal(reason, "locked")
	same(store.records.Player_5, before)
end)

test("expired lease can reconnect and a stale server can never overwrite the new session", function()
	local store = fakeStore()
	local manager, advance = harness(store)
	local old = assert(manager:Load(6, "server-A"))
	advance(181)
	local current = assert(manager:Load(6, "server-B"))
	current.data.cash = 200
	assert(manager:Save(current, false))
	old.data.cash = 999999
	local ok, reason = manager:Save(old, false)
	equal(ok, false)
	equal(reason, "lost")
	equal(old.lost, true)
	equal(store.records.Player_6.Data.cash, 200)
	equal(store.records.Player_6.Session.Id, "server-B")
end)

test("transient save failures retry and eventually persist the same snapshot", function()
	local store = fakeStore()
	local manager = harness(store)
	local profile = assert(manager:Load(7, "server-A"))
	profile.data.cash = 555
	store.errorsRemaining = 2
	local beforeCalls = store.calls
	assert(manager:Save(profile, false))
	equal(store.calls - beforeCalls, 3)
	equal(store.records.Player_7.Data.cash, 555)
	equal(profile.saving, false)
end)

test("failed load never creates default data over an existing profile", function()
	local store = fakeStore()
	local manager = harness(store)
	local old = assert(manager:Load(8, "server-A"))
	old.data.cash = 9000
	assert(manager:Save(old, true))
	local before = copy(store.records.Player_8)
	store.errorsRemaining = 3
	local profile, reason = manager:Load(8, "server-B")
	equal(profile, nil)
	equal(reason, "unavailable")
	same(store.records.Player_8, before)
end)

test("unsupported or malformed profile envelopes are preserved for recovery", function()
	for _, record in ipairs({
		{ Version = 999, Data = { cash = 123 } },
		{ Version = 1, Data = "broken" },
		{ Version = 1, Data = {}, Session = { Id = 123 } },
	}) do
		local store = fakeStore()
		store.records.Player_9 = copy(record)
		local manager = harness(store)
		local profile, reason = manager:Load(9, "server-A")
		equal(profile, nil)
		equal(reason, "unsupported")
		same(store.records.Player_9, record)
	end
end)

test("failed save leaves the last persisted data intact and can recover later", function()
	local store = fakeStore()
	local manager = harness(store)
	local profile = assert(manager:Load(10, "server-A"))
	profile.data.cash = 700
	store.errorsRemaining = 3
	local ok, reason = manager:Save(profile, false)
	equal(ok, false)
	equal(reason, "unavailable")
	equal(store.records.Player_10.Data.cash, 0)
	equal(profile.data.cash, 700)
	equal(profile.saving, false)
	assert(manager:Save(profile, false))
	equal(store.records.Player_10.Data.cash, 700)
end)

test("release waits for an in-flight save and snapshots the latest state", function()
	local store = fakeStore()
	local manager, _, onWait = harness(store)
	local profile = assert(manager:Load(11, "server-A"))
	profile.saving = true
	onWait(function()
		profile.data.cash = 333
		profile.data.bank = 123
		profile.saving = false
	end)
	assert(manager:Save(profile, true))
	equal(store.records.Player_11.Data.cash, 333)
	equal(store.records.Player_11.Data.bank, 123)
	equal(store.records.Player_11.Session, nil)
end)

test("UpdateAsync conflict reruns cannot overwrite another session's data", function()
	local store = fakeStore()
	local manager = harness(store)
	local profile = assert(manager:Load(12, "server-A"))
	profile.data.cash = 111
	store.beforeCommit = function(currentStore, key)
		currentStore.records[key].Session = { Id = "server-B", ExpiresAt = 2000 }
		currentStore.records[key].Data.cash = 888
	end
	local ok, reason = manager:Save(profile, false)
	equal(ok, false)
	equal(reason, "lost")
	equal(store.records.Player_12.Data.cash, 888)
end)

test("rebirth and permanent purchases survive a complete save/rejoin cycle", function()
	local store = fakeStore()
	local manager = harness(store)
	local profile = assert(manager:Load(13, "server-A"))
	profile.data.unlocked = 18
	profile.data.bank = 5000000
	assert(Progression.rebirth(profile.data))
	assert(Progression.buyPermanent(profile.data, "Yield"))
	equal(profile.data.chips, 2)
	assert(manager:Save(profile, true))
	local restored = assert(manager:Load(13, "server-B"))
	equal(restored.data.rebirths, 1)
	equal(restored.data.unlocked, 1)
	equal(restored.data.bank, 0)
	equal(restored.data.chips, 2)
	equal(restored.data.permanent.Yield, 1)
	near(Progression.multiplier(restored.data), 1.25 * 1.15)
end)

-- A deterministic pacing simulation uses actual production and purchasing functions.
test("a new player can reach rebirth with normal production and cash purchases", function()
	local data = Progression.newData()
	local seconds = 0
	local cycles = 0
	while data.unlocked < 18 or data.cash + data.bank < 5000000 do
		seconds += Progression.interval(data)
		data.bank += Progression.batchValue(data)
		Progression.collect(data)
		local nextRecipe = Recipes[data.unlocked + 1]
		if data.unlocked < 18 and nextRecipe and data.cash >= nextRecipe.Cost then
			assert(Progression.buyRecipe(data))
		elseif data.level < Progression.MAX_OVEN_LEVEL then
			-- Invest in speed when it is cheaper than the next required recipe.
			local cost = Progression.ovenCost(data)
			if cost <= (nextRecipe and nextRecipe.Cost or 5000000) and data.cash >= cost then
				assert(Progression.upgradeOven(data))
			end
		end
		cycles += 1
		assert(cycles < 1000000, "progression never reached the first rebirth")
	end
	assert(Progression.rebirth(data))
	assert(seconds > 1800 and seconds < 28800, "unexpected first-run pacing: " .. seconds .. " seconds")
	print(string.format("  Simulated first rebirth: %.1f minutes of production (no walking/collection delay)", seconds / 60))
end)

test("verified income and speed passes stack and retain a real 2x effect at the speed floor", function()
	local data = Progression.newData()
	equal(Progression.batchValue(data, { DoubleIncome = true }), 10)
	near(Progression.interval(data, { DoubleSpeed = true }), 1.5)
	data.level, data.permanent.Speed, data.permanent.Yield, data.rebirths = 15, 10, 4, 3
	near(Progression.multiplier(data, { DoubleIncome = true }), Progression.multiplier(data) * 2)
	near(Progression.interval(data), .4)
	near(Progression.interval(data, { DoubleSpeed = true }), .2)
end)

test("rebirth keeps externally verified passes without saving fake client ownership", function()
	local data = Progression.newData()
	data.unlocked, data.bank = 18, 5000000
	local perks = { DoubleIncome = true, DoubleSpeed = true }
	assert(Progression.rebirth(data))
	equal(perks.DoubleIncome, true)
	near(Progression.interval(data, perks), 1.5)
	data.perks = perks
	data.DoubleIncomeOwned = true
	local normalized = Progression.normalize(data)
	equal(normalized.perks, nil)
	equal(normalized.DoubleIncomeOwned, nil)
end)

test("cash bundles award the full amount with bank overflow and no partial grants", function()
	local data = Progression.newData()
	data.cash = Progression.MAX_CASH - 5
	assert(Rewards.cash(data, 10000, Progression.MAX_CASH))
	equal(data.cash, Progression.MAX_CASH)
	equal(data.bank, 9995)
	data.bank = Progression.MAX_CASH
	local before = copy(data)
	assert(not Rewards.cash(data, 10000, Progression.MAX_CASH))
	same(data, before)
end)

local function withCatalog(callback)
	local ids = {}
	for _, kind in ipairs({ "Passes", "Products" }) do
		ids[kind] = {}
		for key, entry in pairs(Catalog[kind]) do ids[kind][key] = entry.Id end
	end
	local order = copy(Catalog.ProductOrder)
	local ok, message = pcall(callback)
	for kind, entries in pairs(ids) do for key, id in pairs(entries) do Catalog[kind][key].Id = id end end
	Catalog.ProductOrder = order
	assert(ok, message)
end

test("unconfigured and duplicate IDs cannot open purchases or resolve the wrong reward", function()
	withCatalog(function()
		for _, entry in pairs(Catalog.Products) do entry.Id = 0 end
		equal(Catalog.offer("Product", "CashSmall"), nil)
		Catalog.Products.CashSmall.Id = 123
		assert(Catalog.offer("Product", "CashSmall"))
		Catalog.Products.CashMedium.Id = 123
		equal(Catalog.offer("Product", "CashSmall"), nil)
		equal(Catalog.resolve("Product", 123), nil)
		equal(Catalog.offer("InvalidKind", "CashSmall"), nil)
	end)
end)

test("retiring a product hides its sale button but retains receipt fulfillment", function()
	withCatalog(function()
		Catalog.Products.CashSmall.Id = 123
		Catalog.ProductOrder = { "CashMedium", "CashLarge" }
		equal(Catalog.offer("Product", "CashSmall"), nil)
		equal(Catalog.resolve("Product", 123), Catalog.Products.CashSmall)
	end)
end)

local function grantCash(data) return Rewards.cash(data, 10000, Progression.MAX_CASH) end

test("legacy saves migrate without losing cash or progress and acquire an empty receipt ledger", function()
	local store = fakeStore()
	local data = Progression.newData()
	data.cash, data.bank, data.unlocked = 99, 44, 7
	store.records.Player_20 = { Version = 1, Data = copy(data) }
	local manager = harness(store)
	local profile = assert(manager:Load(20, "server-A"))
	same(profile.data, data)
	same(profile.receipts, {})
	equal(store.records.Player_20.Version, 2)
end)

test("one atomic receipt write saves the reward and purchase ID before success", function()
	local store = fakeStore()
	local manager = harness(store)
	local profile = assert(manager:Load(21, "server-A"))
	local alias = profile.data
	assert(manager:GrantReceipt(profile, "purchase-A", 123, grantCash))
	equal(profile.data, alias)
	equal(profile.data.cash, 10000)
	equal(store.records.Player_21.Data.cash, 10000)
	equal(store.records.Player_21.Receipts["purchase-A"], 123)
	equal(profile.transacting, false)
end)

test("duplicate receipts cannot restore spent cash or award a second time after rejoin", function()
	local store = fakeStore()
	local manager = harness(store)
	local profile = assert(manager:Load(22, "server-A"))
	assert(manager:GrantReceipt(profile, "purchase-A", 123, grantCash))
	profile.data.cash = 400
	assert(manager:GrantReceipt(profile, "purchase-A", 123, grantCash))
	equal(profile.data.cash, 400)
	assert(manager:Save(profile, true))
	local nextProfile = assert(manager:Load(22, "server-B"))
	assert(manager:GrantReceipt(nextProfile, "purchase-A", 123, grantCash))
	equal(nextProfile.data.cash, 400)
	equal(store.records.Player_22.Data.cash, 400)
end)

test("receipt ledger survives rebirth, so an old purchase cannot be replayed for cash", function()
	local store = fakeStore()
	local manager = harness(store)
	local profile = assert(manager:Load(23, "server-A"))
	assert(manager:GrantReceipt(profile, "purchase-A", 123, grantCash))
	profile.data.unlocked, profile.data.bank = 18, 5000000
	assert(Progression.rebirth(profile.data))
	assert(manager:Save(profile, true))
	local nextProfile = assert(manager:Load(23, "server-B"))
	assert(manager:GrantReceipt(nextProfile, "purchase-A", 123, grantCash))
	equal(nextProfile.data.cash, 0)
	equal(nextProfile.data.rebirths, 1)
end)

test("UpdateAsync reruns calculate a purchase from a fresh copy, never doubling its reward", function()
	local store = fakeStore()
	local manager = harness(store)
	local profile = assert(manager:Load(24, "server-A"))
	store.beforeCommit = function(current, key) current.records[key].UpdatedAt = 1234 end
	assert(manager:GrantReceipt(profile, "purchase-A", 123, grantCash))
	equal(profile.data.cash, 10000)
	equal(store.records.Player_24.Data.cash, 10000)
end)

test("lost response after commit reconciles the persisted reward on retry", function()
	local store = fakeStore()
	local manager = harness(store)
	local profile = assert(manager:Load(25, "server-A"))
	store.commitErrorsRemaining = 1
	assert(manager:GrantReceipt(profile, "purchase-A", 123, grantCash))
	equal(profile.data.cash, 10000)
	equal(store.records.Player_25.Data.cash, 10000)
	equal(profile.transacting, false)
end)

test("ambiguous receipt failures freeze saves until reconciliation, preserving a committed reward", function()
	local store = fakeStore()
	local manager = harness(store)
	local profile = assert(manager:Load(26, "server-A"))
	store.commitErrorsRemaining = 3
	local ok, reason = manager:GrantReceipt(profile, "purchase-A", 123, grantCash)
	equal(ok, false)
	equal(reason, "unavailable")
	equal(profile.transacting, true)
	equal(profile.data.cash, 0)
	equal(store.records.Player_26.Data.cash, 10000)
	local saved, saveReason = manager:Save(profile, false)
	equal(saved, false)
	equal(saveReason, "receipt_pending")
	equal(store.records.Player_26.Data.cash, 10000)
	assert(manager:GrantReceipt(profile, "purchase-A", 123, grantCash))
	equal(profile.data.cash, 10000)
	equal(profile.transacting, false)
	assert(manager:Save(profile, false))
	equal(store.records.Player_26.Data.cash, 10000)
end)

test("departure never overwrites an uncertain paid reward; rejoin acknowledges it once", function()
	local store = fakeStore()
	local manager, advance = harness(store)
	local profile = assert(manager:Load(27, "server-A"))
	store.commitErrorsRemaining = 3
	assert(not manager:GrantReceipt(profile, "purchase-A", 123, grantCash))
	local ok, reason = manager:Save(profile, true)
	equal(ok, false)
	equal(reason, "receipt_pending")
	equal(store.records.Player_27.Data.cash, 10000)
	advance(181)
	local nextProfile = assert(manager:Load(27, "server-B"))
	assert(manager:GrantReceipt(nextProfile, "purchase-A", 123, grantCash))
	equal(nextProfile.data.cash, 10000)
end)

test("outage before any receipt commit remains retryable after a crashed session expires", function()
	local store = fakeStore()
	local manager, advance = harness(store)
	local profile = assert(manager:Load(28, "server-A"))
	profile.data.cash = 17
	assert(manager:Save(profile, false))
	store.errorsRemaining = 3
	assert(not manager:GrantReceipt(profile, "purchase-A", 123, grantCash))
	equal(store.records.Player_28.Data.cash, 17)
	equal(store.records.Player_28.Receipts["purchase-A"], nil)
	advance(181)
	local nextProfile = assert(manager:Load(28, "server-B"))
	assert(manager:GrantReceipt(nextProfile, "purchase-A", 123, grantCash))
	equal(nextProfile.data.cash, 10017)
end)

test("simultaneous receipts serialize while an uncertain first purchase is reconciled", function()
	local store = fakeStore()
	local manager = harness(store)
	local profile = assert(manager:Load(29, "server-A"))
	store.commitErrorsRemaining = 3
	assert(not manager:GrantReceipt(profile, "purchase-A", 123, grantCash))
	local ok, reason = manager:GrantReceipt(profile, "purchase-B", 456, grantCash)
	equal(ok, false)
	equal(reason, "busy")
	assert(manager:GrantReceipt(profile, "purchase-A", 123, grantCash))
	assert(manager:GrantReceipt(profile, "purchase-B", 456, grantCash))
	equal(profile.data.cash, 20000)
	equal(store.records.Player_29.Receipts["purchase-B"], 456)
end)

test("a competing server can cancel an old receipt transaction without granting or acknowledging it", function()
	local store = fakeStore()
	local manager = harness(store)
	local profile = assert(manager:Load(30, "server-A"))
	store.beforeCommit = function(current, key)
		current.records[key].Session = { Id = "server-B", ExpiresAt = 2000 }
		current.records[key].Data.cash = 777
	end
	local ok, reason = manager:GrantReceipt(profile, "purchase-A", 123, grantCash)
	equal(ok, false)
	equal(reason, "lost")
	equal(profile.lost, true)
	equal(store.records.Player_30.Data.cash, 777)
	equal(store.records.Player_30.Receipts["purchase-A"], nil)
end)

test("receipt capacity failure leaves no acknowledgement and can retry after spending", function()
	local store = fakeStore()
	local manager = harness(store)
	local profile = assert(manager:Load(31, "server-A"))
	profile.data.cash, profile.data.bank = Progression.MAX_CASH, Progression.MAX_CASH
	local ok, reason = manager:GrantReceipt(profile, "purchase-A", 123, grantCash)
	equal(ok, false)
	equal(reason, "capacity")
	equal(profile.transacting, false)
	equal(store.records.Player_31.Receipts["purchase-A"], nil)
	profile.data.cash -= 10000
	assert(manager:GrantReceipt(profile, "purchase-A", 123, grantCash))
	equal(profile.data.cash, Progression.MAX_CASH)
end)

test("receipt arriving during an autosave waits without recording an ungranted reward", function()
	local store = fakeStore()
	local manager = harness(store)
	local profile = assert(manager:Load(32, "server-A"))
	profile.saving = true
	local ok, reason = manager:GrantReceipt(profile, "purchase-A", 123, grantCash)
	equal(ok, false)
	equal(reason, "busy")
	equal(profile.pendingReceipt, nil)
	equal(store.records.Player_32.Receipts["purchase-A"], nil)
	profile.saving = false
	assert(manager:GrantReceipt(profile, "purchase-A", 123, grantCash))
	equal(profile.data.cash, 10000)
end)

test("malformed receipts and conflicting product identities cannot grant cash", function()
	local store = fakeStore()
	local manager = harness(store)
	local profile = assert(manager:Load(33, "server-A"))
	assert(not manager:GrantReceipt(profile, "", 123, grantCash))
	assert(not manager:GrantReceipt(profile, "purchase-A", 0, grantCash))
	equal(profile.pendingReceipt, nil)
	assert(manager:GrantReceipt(profile, "purchase-A", 123, grantCash))
	assert(not manager:GrantReceipt(profile, "purchase-A", 456, grantCash))
	equal(profile.data.cash, 10000)
end)

print(string.format("\n%d passed, %d failed", passed, failed))
if failed > 0 then error("Cookie Corner tests failed") end
