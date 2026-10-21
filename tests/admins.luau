local Permissions = require("../src/server/AdminPermissions")
local AdminRewards = require("../src/server/AdminRewards")
local Progression = require("../src/shared/Progression")
local PurchaseRewards = require("../src/shared/PurchaseRewards")

return function(test, equal, harness, fakeStore)
	test("admin usernames resolve to server-verified IDs with case-insensitive deduplication", function()
		local calls = 0
		local admins, errors = Permissions.resolve({ Usernames = { " @CookieFriend ", "COOKIEFRIEND", "OtherFriend" } }, function(name)
			calls += 1
			return ({ cookiefriend = 11, otherfriend = 22 })[name]
		end)
		equal(calls, 2)
		equal(#errors, 0)
		equal(admins[11], true)
		equal(admins[22], true)
		equal(admins.CookieFriend, nil)
	end)

	test("personal experience ownership is opt-in and group ownership never grants a user role", function()
		local lookup = function() error("no lookup expected") end
		local personal = Permissions.resolve({ AutoExperienceOwner = true }, lookup, 44)
		equal(personal[44], true)
		local disabled = Permissions.resolve({ AutoExperienceOwner = false }, lookup, 44)
		equal(disabled[44], nil)
		local group = Permissions.resolve({ AutoExperienceOwner = true }, lookup, nil)
		equal(next(group), nil)
	end)

	test("explicit admin IDs remain valid without a username lookup or after a rename", function()
		local admins = Permissions.resolve({ UserIds = { 10, 20, 10 } }, function() error("names not configured") end)
		equal(admins[10], true)
		equal(admins[20], true)
		assert(Permissions.authorize(admins, 10, "ReturnToSpawn", 20))
	end)

	test("failed and malformed username lookups fail closed without matching display names", function()
		local admins, errors = Permissions.resolve({ Usernames = { "MissingUser", "NetworkError", "BadResult", "Display Name", "@", string.rep("a", 21) } }, function(name)
			if name == "networkerror" then error("Roblox lookup unavailable") end
			if name == "badresult" then return math.huge end
			return nil
		end)
		equal(next(admins), nil)
		equal(#errors, 6)
		assert(not Permissions.authorize(admins, 99, "Kick", 12))
	end)

	test("invalid admin IDs cannot grant access and unknown keys do not become permissions", function()
		local admins, errors = Permissions.resolve({ UserIds = { 0, -1, 2.5, math.huge, 0/0, "11" }, IsAdmin = true }, function() return 11 end)
		equal(next(admins), nil)
		equal(#errors, 6)
		assert(not Permissions.authorize(admins, 11, "Kick", 12))
	end)

	test("only allowlisted actors can use the supported admin actions", function()
		local admins = { [11] = true, [22] = true, [33] = false }
		for _, actor in ipairs({ 12, 33, 0, -1 }) do
			assert(not Permissions.authorize(admins, actor, "Kick", 44))
			assert(not Permissions.authorize(admins, actor, "ReturnToSpawn", 44))
		end
		assert(Permissions.authorize(admins, 11, "Kick", 44))
		assert(Permissions.authorize(admins, 11, "ReturnToSpawn", 44))
		for _, action in ipairs({ "GiveWalletCash", "GiveBankCash", "GoToPlayer", "BringPlayer" }) do
			assert(Permissions.authorize(admins, 11, action, 44))
			assert(not Permissions.authorize(admins, 12, action, 44))
		end
		for _, action in ipairs({ "SetAdmin", "GiveCash", "ResetProgress", "Ban", true, {} }) do
			assert(not Permissions.authorize(admins, 11, action, 44))
		end
	end)

	test("invisibility is restricted to the verified admin's own character", function()
		local admins = { [11] = true, [22] = true }
		assert(Permissions.authorize(admins, 11, "SetInvisible", 11))
		assert(not Permissions.authorize(admins, 11, "SetInvisible", 22))
		assert(not Permissions.authorize(admins, 33, "SetInvisible", 33))
	end)

	test("admin cash grants change only the selected balance without multiplying the amount", function()
		local data = Progression.newData()
		data.rebirths, data.boosts.paidTier = 20, 12
		assert(AdminRewards.grant(data, "GiveWalletCash", 1234, 1e9))
		equal(data.cash, 1234)
		equal(data.bank, 0)
		assert(AdminRewards.grant(data, "GiveBankCash", 5678, 1e9))
		equal(data.cash, 1234)
		equal(data.bank, 5678)
		equal(data.chips, 0)
		equal(data.boosts.paidTier, 12)
	end)

	test("admin cash validates whole positive amounts, grant caps, and currency space", function()
		local data = Progression.newData()
		for _, amount in ipairs({ -1, 0, 1.5, "1000", {}, math.huge, 0/0, 1e9 + 1 }) do
			assert(not AdminRewards.grant(data, "GiveWalletCash", amount, 1e9))
			equal(data.cash, 0)
		end
		assert(not AdminRewards.grant(data, "GiveChips", 5, 1e9))
		assert(not AdminRewards.grant(data, "GiveWalletCash", 1, math.huge))
		data.cash, data.bank = Progression.MAX_CASH, Progression.MAX_CASH
		assert(not AdminRewards.grant(data, "GiveWalletCash", 6, 1e9))
		assert(not AdminRewards.grant(data, "GiveBankCash", 1, 1e9))
		equal(data.cash, Progression.MAX_CASH)
		data.cash=100
		assert(AdminRewards.grant(data, "GiveWalletCash", 5, 1e9))
		equal(data.cash, 105)
	end)

	test("admin gifts persist through receipt saves and rejoin while retaining existing progress", function()
		local store = fakeStore()
		local manager = harness(store)
		local profile = assert(manager:Load(930, "admin-gifts"))
		profile.data.unlocked, profile.data.audio.musicVolume = 5, 0.32
		assert(AdminRewards.grant(profile.data, "GiveWalletCash", 1000, 1e9))
		assert(AdminRewards.grant(profile.data, "GiveBankCash", 2500, 1e9))
		assert(manager:GrantReceipt(profile, "admin-gift-receipt", 12345, function(data)
			return PurchaseRewards.cash(data, 10000, Progression.MAX_CASH)
		end))
		assert(manager:Save(profile, true))
		local restored = assert(manager:Load(930, "admin-gifts-rejoin"))
		equal(restored.data.cash, 11000)
		equal(restored.data.bank, 2500)
		equal(restored.data.unlocked, 5)
		equal(restored.data.audio.musicVolume, 0.32)
		equal(restored.receipts["admin-gift-receipt"], 12345)
	end)

	test("admins cannot kick themselves or another admin but can return either to spawn", function()
		local admins = { [11] = true, [22] = true }
		assert(not Permissions.authorize(admins, 11, "Kick", 11))
		assert(not Permissions.authorize(admins, 11, "Kick", 22))
		assert(Permissions.authorize(admins, 11, "ReturnToSpawn", 11))
		assert(Permissions.authorize(admins, 11, "ReturnToSpawn", 22))
	end)

	test("forged admin targets cannot reach player lookup or mutate the admin roster", function()
		local admins = { [11] = true }
		for _, target in ipairs({ false, {}, "22", 1.5, math.huge, 0/0, 2^53 }) do
			assert(not Permissions.authorize(admins, 11, "Kick", target))
			assert(not Permissions.authorize(admins, 11, "ReturnToSpawn", target))
		end
		equal(admins[11], true)
		equal(admins[22], nil)
		-- Studio test clients can have negative IDs; live membership still uses positive IDs only.
		assert(Permissions.authorize(admins, 11, "ReturnToSpawn", -1))
	end)
end
