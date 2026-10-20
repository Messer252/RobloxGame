-- Original Valley Afterglow score plays locally; optional full mix upload uses MusicAssetId.
return {
	MusicAssetId = 0,
	MusicName = "Valley Afterglow",
	FallbackMusicEnabled = true,
	MusicAttackSeconds = 0.18,
	MusicReleaseSeconds = 0.35,
	BundledChime = "rbxasset://sounds/electronicpingshort.wav",
	ChimeMidi = 72,
	BundledSwing = "rbxasset://sounds/swordslash.wav", -- Built-in whoosh; optional PinSwing upload overrides it.
	-- Bubby's six "cookie cookie" recordings. Upload each as Roblox audio,
	-- grant this experience access, and replace the zeros with numeric asset IDs.
	-- Only successful new-oven purchases use these; 0 keeps the existing cue.
	OvenPurchaseVoices = { 0, 0, 0, 0, 0, 0 },
	Effects = {
		Click = 0, Claim = 0, Collect = 0, BuyRecipe = 0, UpgradeOven = 0,
		BuyModifier = 0, UpgradePermanent = 0, Rebirth = 0, Error = 0,
		MeteorIncoming = 0, MeteorCrash = 0, PinSwing = 0, OreHit = 0,
	},
}
