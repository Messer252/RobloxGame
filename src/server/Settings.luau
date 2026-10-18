return {
	-- Use a separate published test experience for persistence testing.
	DataStoreName = "CookieCorner_PlayerData_v1",
	AutosaveSeconds = 45,
	SessionLeaseSeconds = 180,
	-- Explicit opt-in for offline Studio play only. Always ignored on live servers.
	-- Session-only play never reads/writes a fallback profile to the real DataStore.
	AllowStudioSessionOnly = false,
}
