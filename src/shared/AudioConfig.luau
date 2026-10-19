-- Optional: upload assets/audio/*.wav to Roblox and enter YOUR audio asset IDs.
-- Zero uses a sparse, softened local arrangement; no audio uploads are required.
-- Uploaded audio must be approved and permitted for this experience.
return {
	MusicAssetId = 0,
	MusicVolume = 0.24,
	MusicAttackSeconds = 0.18,
	MusicReleaseSeconds = 0.35,
	EffectsVolume = 0.55,
	BundledChime = "rbxasset://sounds/electronicpingshort.wav",
	ChimeMidi = 72,
	Effects = {
		Click = 0, Claim = 0, Collect = 0, BuyRecipe = 0, UpgradeOven = 0,
		BuyModifier = 0, UpgradePermanent = 0, Rebirth = 0, Error = 0,
	},
}
