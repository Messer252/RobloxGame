-- Called by tests/run.luau's shared harness; pure Luau, no Roblox engine needed.
local Catalog = require("../src/shared/ChallengeCatalog")
local Challenges = require("../src/shared/Challenges")

return function(test, equal)
	local function profile()
		return { cash = 0, bank = 0, challenges = Challenges.normalize(nil) }
	end
	local function findAll(data)
		for _, itemId in ipairs(Catalog.Challenges[data.challenges.index].Items) do
			assert(Challenges.find(data, itemId))
		end
	end

	test("challenge catalog has twelve unique treasures and reachable public positions", function()
		local seen = {}
		local count = 0
		for _, quest in ipairs(Catalog.Challenges) do
			equal(#quest.Items, 3)
			assert(quest.Reward > 0 and quest.Reward == math.floor(quest.Reward))
			for _, itemId in ipairs(quest.Items) do
				assert(not seen[itemId])
				seen[itemId] = true
				count += 1
				local item = Catalog.Items[itemId]
				assert(item and #item.Hint > 0)
				local x, y, z = table.unpack(item.Position)
				assert(math.abs(x) <= 200 and y >= 0 and y < 3 and math.abs(z) <= 260)
				-- The four bakery footprints start at x +/-16, z +/-22;
				-- every treasure is on the public center path, plaza or outer grass.
				assert(math.abs(x) <= 14 or math.abs(z) <= 10 or math.abs(x) >= 184)
			end
		end
		equal(count, 12)
	end)

	test("challenge normalization strips unknown flags and cannot carry inactive discoveries", function()
		local inactive = Challenges.normalize({ index = 1, active = false, found = { GoldenSpoon = true } })
		equal(next(inactive.found), nil)
		local raw = { index = 1, active = true, found = { GoldenSpoon = true, PinkWhisk = 1, RollingPin = true, cheated = true } }
		local active = Challenges.normalize(raw)
		equal(Challenges.count(active), 1)
		equal(Challenges.encode(active), 1)
		equal(active.found.RollingPin, nil)
		equal(active.found.cheated, nil)
		active.found.GoldenSpoon = nil
		equal(raw.found.GoldenSpoon, true)
	end)

	test("challenge normalization handles malformed indexes and finished state", function()
		for _, index in ipairs({ "1", false, math.huge, -math.huge, 0 / 0 }) do
			equal(Challenges.normalize({ index = index }).index, 1)
		end
		local finished = Challenges.normalize({ index = 999, active = true, found = { GoldenCookieChip = true } })
		equal(Challenges.isComplete(finished), true)
		equal(finished.active, false)
		equal(next(finished.found), nil)
	end)

	test("hunts require accepting and reject foreign or duplicate discoveries", function()
		local data = profile()
		equal(Challenges.find(data, "GoldenSpoon"), false)
		equal(Challenges.interact(data), true)
		equal(data.challenges.active, true)
		equal(Challenges.find(data, "RollingPin"), false)
		equal(Challenges.find(data, "not-an-item"), false)
		equal(Challenges.find(data, "GoldenSpoon"), true)
		equal(Challenges.find(data, "GoldenSpoon"), false)
		equal(Challenges.count(data.challenges), 1)
		equal(Challenges.interact(data), false)
		equal(data.cash, 0)
		equal(data.challenges.index, 1)
	end)

	test("finding all items permits one reward and advances to a fresh inactive hunt", function()
		local data = profile()
		assert(Challenges.interact(data))
		findAll(data)
		equal(Challenges.ready(data.challenges), true)
		equal(Challenges.encode(data.challenges), 7)
		local success, _, reward = Challenges.interact(data)
		equal(success, true)
		equal(reward, 500)
		equal(data.cash, 500)
		equal(data.challenges.index, 2)
		equal(data.challenges.active, false)
		equal(next(data.challenges.found), nil)
		assert(Challenges.interact(data)) -- Accepting next hunt never repeats a reward.
		equal(data.cash, 500)
		equal(Challenges.find(data, "GoldenSpoon"), false)
	end)

	test("reward overflow moves into bank without dropping cash", function()
		local data = profile()
		assert(Challenges.interact(data))
		findAll(data)
		data.cash = 999
		assert(Challenges.interact(data, 1000))
		equal(data.cash, 1000)
		equal(data.bank, 499)
	end)

	test("a full wallet and register preserve completed hunt until reward fits", function()
		local data = profile()
		assert(Challenges.interact(data))
		findAll(data)
		data.cash, data.bank = 1000, 1000
		local before = data.challenges
		equal(Challenges.interact(data, 1000), false)
		equal(data.challenges, before)
		equal(data.cash, 1000)
		equal(data.bank, 1000)
		equal(Challenges.ready(data.challenges), true)
		data.cash = 500
		assert(Challenges.interact(data, 1000))
		equal(data.cash, 1000)
		equal(data.challenges.index, 2)
	end)

	test("all hunts are finite and cannot replay after completion", function()
		local data = profile()
		local expected = 0
		for _, quest in ipairs(Catalog.Challenges) do
			assert(Challenges.interact(data))
			findAll(data)
			assert(Challenges.interact(data))
			expected += quest.Reward
		end
		equal(data.cash, expected)
		equal(Challenges.isComplete(data.challenges), true)
		equal(Challenges.interact(data), false)
		equal(Challenges.find(data, "GoldenCookieChip"), false)
		equal(data.cash, expected)
	end)
end
