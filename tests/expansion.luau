local Boosts = require("../src/shared/Boosts")
local Progression = require("../src/shared/Progression")
local Map = require("../src/shared/MapLayout")
local Layout = require("../src/shared/ConveyorLayout")
local Courses = require("../src/shared/ObbyCatalog")
local Obby = require("../src/shared/ObbyProgress")
local Ranks = require("../src/shared/LeaderboardRanks")
local Catalog = require("../src/shared/ShopCatalog")
local Rewards = require("../src/shared/PurchaseRewards")
local ProfileStore = require("../src/server/ProfileStore")

return function(test, equal, near, harness, fakeStore)
	test("eight unique bakery footprints fit inside the expanded map without overlap", function()
		equal(Map.PlayerCount, 8)
		for i = 1, Map.PlayerCount do
			local a = assert(Map.plot(i))
			assert(math.abs(a.x) + 82 < Map.Width / 2)
			assert(math.abs(a.z) + 141 < Map.Length / 2)
			equal(a.direction, a.z < 0 and 1 or -1)
			for j = i + 1, Map.PlayerCount do
				local b = Map.plot(j)
				assert(math.abs(a.x - b.x) >= 164 or math.abs(a.z - b.z) >= 244)
			end
		end
		equal(Map.plot(0), nil)
		equal(Map.plot(9), nil)
	end)

	test("three ten-oven feeders merge into one belt ending at a collection box", function()
		local segments = Layout.segments()
		equal(#segments, 7)
		for lane, x in ipairs(Layout.LaneXs) do
			local feeder, merge = segments[lane * 2 - 1], segments[lane * 2]
			equal(feeder.ax, x)
			equal(feeder.bx, merge.ax)
			equal(feeder.bz, merge.az)
			equal(merge.bx, 0)
			equal(merge.bz, segments[7].az)
			for index = (lane - 1) * 10 + 1, lane * 10 do equal(Layout.station(index).laneX, x) end
		end
		for _, segment in ipairs(segments) do assert(segment.bz > segment.az) end
		assert(Layout.BoxZ - 7 >= Layout.MainEndZ)
		assert(Layout.BeltTop > 3.7) -- Box wall top is below the belt lip.
		equal(Layout.speed(3), 12)
		equal(Layout.speed(0.2), 22)
	end)

	test("three distinct obbys fit in the meadow with reachable default-character gaps", function()
		equal(#Courses, 3)
		for _, course in ipairs(Courses) do
			equal(Boosts.ObbyBonuses[course.Id], course.Bonus)
			local previous = { x = 230, y = 0.4, z = course.Z }
			for stage = 1, course.Count do
				local p = Courses.platform(course, stage)
				assert(p.x + course.Width / 2 < Map.Width / 2)
				assert(math.abs(p.z) + course.Width / 2 < Map.Length / 2)
				assert(p.y - previous.y <= 5) -- Default jump height exceeds this.
				local distance = math.sqrt((p.x - previous.x)^2 + (p.z - previous.z)^2)
				assert(distance - course.Width < 8)
				previous = p
			end
		end
	end)

	test("obby reward requires ordered checkpoints and minimum completion time", function()
		local course = Courses[1]
		local run = Obby.start(course, 100)
		assert(not Obby.advance(run, course, 2, 101))
		assert(not Obby.advance(run, Courses[2], 1, 101))
		assert(not Obby.advance(run, course, 1, 100.1))
		for stage = 1, course.Count - 1 do
			local accepted, complete = Obby.advance(run, course, stage, 100 + stage * 0.3)
			assert(accepted and not complete)
		end
		assert(not Obby.advance(run, course, course.Count, 103))
		local accepted, complete = Obby.advance(run, course, course.Count, 105)
		assert(accepted and complete)
		assert(not Obby.advance(run, course, course.Count, 106))
	end)

	test("each obby bonus expires at exactly five minutes and weaker runs cannot refresh it", function()
		for difficulty, bonus in pairs(Boosts.ObbyBonuses) do
			local data = Progression.newData()
			assert(Boosts.awardObby(data, difficulty, 1000))
			equal(data.boosts.obbyExpires, 1300)
			near(Boosts.obbyMultiplier(data.boosts, 1299), 1 + bonus)
			equal(Boosts.obbyMultiplier(data.boosts, 1300), 1)
		end
		local data = Progression.newData()
		assert(Boosts.awardObby(data, "Hard", 1000))
		assert(not Boosts.awardObby(data, "Easy", 1100))
		equal(data.boosts.obbyExpires, 1300)
		assert(Boosts.awardObby(data, "Hard", 1200))
		equal(data.boosts.obbyExpires, 1500)
		assert(Boosts.awardObby(data, "Easy", 1500))
		near(Boosts.obbyMultiplier(data.boosts, 1500), 1.1)
	end)

	test("permanent income and active obby boosts survive rebirth and normalization", function()
		local data = Progression.newData()
		assert(Boosts.grantPaid(data, 2))
		assert(Boosts.grantPaid(data, 1)) -- Delayed lower receipt cannot downgrade.
		assert(Boosts.awardObby(data, "Medium", 1000))
		data.cash, data.unlocked = Progression.MAX_CASH, 30
		assert(Progression.rebirth(data))
		local restored = Progression.normalize(data)
		equal(restored.boosts.paidTier, 2)
		equal(restored.boosts.obbyExpires, 1300)
		near(Boosts.multiplier(restored.boosts, 1200), 5.2)
		equal(Boosts.multiplier(restored.boosts, 1300), 4)
	end)

	test("paid, pass, rebirth, Golden Batter, and one obby bonus multiply income only", function()
		local data = Progression.newData()
		data.rebirths, data.permanent.Yield = 2, 4
		Boosts.grantPaid(data, 2)
		Boosts.awardObby(data, "Medium", 1000)
		near(Progression.multiplier(data, { DoubleIncome = true, Now = 1100 }), 2 * 1.3 * 2 * 4 * 1.3)
		assert(Rewards.cash(data, 10000, Progression.MAX_CASH))
		equal(data.cash, 10000)
	end)

	test("invalid boost fields cannot grant infinite entitlements or extend timers", function()
		for _, bad in ipairs({ math.huge, -math.huge, 0/0, "12", false }) do
			local state = Boosts.normalize({ paidTier = bad, obbyBonus = 1, obbyExpires = bad })
			equal(state.paidTier, 0)
			equal(state.obbyBonus, 0)
			equal(state.obbyExpires, 0)
		end
		assert(not Boosts.grantPaid(Progression.newData(), 1.2))
		assert(not Boosts.grantPaid(Progression.newData(), Boosts.MaxPaidTier + 1))
	end)

	test("largest paid entitlement cannot overflow exact currency limits", function()
		local data = Progression.newData()
		data.rebirths, data.permanent.Yield, data.unlocked = Progression.MAX_REBIRTHS, 20, 30
		Boosts.grantPaid(data, Boosts.MaxPaidTier)
		for i = 1, 30 do data.modifiers[tostring(i)] = { Glaze = true, Sprinkles = true, ChocolateDrizzle = true } end
		local amount = Progression.batchValue(data, { DoubleIncome = true })
		assert(amount > 0 and amount <= Progression.MAX_CASH and amount % 1 == 0)
	end)

	test("income stages double entitlement and suggested price while all offers start disabled", function()
		for tier = 1, Boosts.MaxPaidTier do
			local offer = Catalog.Products["IncomeTier" .. tier]
			equal(offer.BoostTier, tier)
			equal(offer.SuggestedRobux, 20 * 2^(tier-1))
			equal(offer.Id, 0)
			assert(Catalog.validProduct(offer))
			equal(Catalog.offer("Product", "IncomeTier" .. tier), nil)
		end
	end)

	test("cash and rebirth rankings use descending scores with stable user ID ties", function()
		local rows = { { userId = 3, cash = 20, rebirths = 0 }, { userId = 2, cash = 50, rebirths = 1 }, { userId = 1, cash = 50, rebirths = 3 } }
		local cash = Ranks.sort(rows, "cash")
		equal(cash[1].userId, 1)
		equal(cash[2].userId, 2)
		equal(cash[3].userId, 3)
		equal(Ranks.sort(rows, "rebirths")[1].rebirths, 3)
		equal(rows[1].userId, 3)
	end)

	test("version-4 profiles migrate paid boosts without losing old receipts or preferences", function()
		local store = fakeStore()
		local data = Progression.newData()
		data.cash, data.audio.music, data.boosts = 321, false, nil
		store.records.Player_900 = { Version = 4, Data = data, Receipts = { old = 9123 } }
		local profile = assert(harness(store):Load(900, "boost-migration"))
		equal(profile.data.cash, 321)
		equal(profile.data.audio.music, false)
		equal(profile.data.boosts.paidTier, 0)
		equal(profile.receipts.old, 9123)
		equal(store.records.Player_900.Version, ProfileStore.CURRENT_VERSION)
	end)

	test("permanent product receipts commit once, survive rejoin, and retain five-minute expiry", function()
		local store = fakeStore()
		local manager = harness(store)
		local profile = assert(manager:Load(901, "income-first"))
		Boosts.awardObby(profile.data, "Hard", 1000)
		local grant = function(data) return Rewards.product(data, Catalog.Products.IncomeTier2, Progression.MAX_CASH) end
		assert(manager:GrantReceipt(profile, "income-paid", 9940, grant))
		local ok, reason = manager:GrantReceipt(profile, "income-paid", 9940, grant)
		assert(ok)
		equal(reason, "duplicate")
		assert(manager:Save(profile, true))
		profile = assert(manager:Load(901, "income-rejoin"))
		equal(profile.data.boosts.paidTier, 2)
		equal(profile.data.boosts.obbyExpires, 1300)
		equal(profile.receipts["income-paid"], 9940)
	end)

	test("lost receipt-save response reconciles the permanent tier without a second reward", function()
		local store = fakeStore()
		local manager = harness(store)
		local profile = assert(manager:Load(902, "income-uncertain"))
		store.commitErrorsRemaining = 3
		local grant = function(data) return Rewards.product(data, Catalog.Products.IncomeTier1, Progression.MAX_CASH) end
		assert(not manager:GrantReceipt(profile, "income-lost-response", 9920, grant))
		assert(profile.transacting)
		assert(manager:GrantReceipt(profile, "income-lost-response", 9920, grant))
		equal(profile.data.boosts.paidTier, 1)
		equal(profile.data.cash, 0)
		equal(profile.receipts["income-lost-response"], 9920)
	end)
end
