-- Edit this ModuleScript in ServerScriptService > Tycoon > AdminConfig.
-- Use Roblox ACCOUNT usernames, not display names. Publish and restart servers.
return {
	AutoExperienceOwner = true, -- Personal experiences only; never grants a group ID.
	Usernames = {
		"unbenator",
		-- "FriendUsername",
	},
	-- Optional permanent account IDs: these keep working after username changes.
	UserIds = {
		-- 123456789,
	},
	MaxGoldenChipGrant = 10000,
	MaxStarCrumbGrant = 100000,
	MaxCashGrant = 1000000000, -- Maximum per admin action; integer cookie cash.
}
