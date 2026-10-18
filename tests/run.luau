-- Run with the official Luau CLI from the repository root: luau tests/run.luau
local Recipes = require("../src/shared/Recipes")
local Progression = require("../src/shared/Progression")
local ProfileStore = require("../src/server/ProfileStore")
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
	local store = { records = {}, calls = 0, errorsRemaining = 0 }
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

print(string.format("\n%d passed, %d failed", passed, failed))
if failed > 0 then error("Cookie Corner tests failed") end
