local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local Http = game:GetService("HttpService")
local Rankings = require(script.Parent.GlobalRankings)
local Server = {}
Server.__index = Server

local function unavailable()
	error("Global leaderboard storage is unavailable")
end
function Server.start(profileStore, settings)
	local stores = {}
	for key, suffix in pairs({cash = "AllTimeCash", rebirths = "Rebirths"}) do
		local ok, store = pcall(function() return DataStoreService:GetOrderedDataStore(settings.DataStoreName .. "_Global" .. suffix .. "_v1") end)
		stores[key] = ok and store or {SetAsync = unavailable, GetSortedAsync = unavailable}
	end
	local options = Instance.new("DataStoreGetOptions")
	options.UseCache = false
	local self = setmetatable({ closing = false, backfillDone = false }, Server)
	self.index = Rankings.new(stores, function(id) return profileStore:GetAsync("Player_" .. id, options) end,
		function(id) return Players:GetNameFromUserIdAsync(id) end, os.clock)
	task.spawn(function()
		while not self.closing do
			self.writing = true
			local success, _, reason = pcall(function() return self.index:FlushOne() end)
			self.writing = false
			if not success then reason = "index_worker_failed" end
			if reason and os.clock() >= (self.nextWarning or 0) then
				self.nextWarning = os.clock() + 60
				warn("Cookie Corner: global ranking " .. ((reason == "unsupported_profile" or reason == "invalid_scores") and "skipped an incompatible save: " or "update pending: ") .. reason)
			end
			-- At most 30 ordered writes/minute while importing old saves.
			task.wait(4)
		end
	end)
	task.spawn(function()
		while not self.closing do
			self.index:Refresh("cash")
			self.index:Refresh("rebirths")
			task.wait(60)
		end
	end)
	task.spawn(function()
		while not self.closing and not self.backfillDone do
			self:Backfill(profileStore, settings)
			if not self.backfillDone then task.wait(60) end
		end
	end)
	return self
end
function Server:Queue(id) return self.index:Queue(id) end
function Server:Get(key) return self.index:Get(key) end
function Server:Shutdown(deadline)
	self.closing = true
	while self.writing and os.clock() < deadline do task.wait(.1) end
	if self.writing then return end
	-- Final profile saves take priority; use any remaining shutdown time to
	-- publish their final rankings, bypassing only the ordinary write cooldown.
	for id in pairs(self.index.pending) do self.index.nextWrite[id] = 0 end
	while next(self.index.pending) and os.clock() < deadline do
		self.index:FlushOne()
		task.wait(.1)
	end
end

-- One server imports old offline profiles at a time. A saved cursor and lease
-- resume interrupted work without scanning every profile on every server join.
function Server:Backfill(profileStore, settings)
	local token = Http:GenerateGUID(false)
	local ok, migration = pcall(function() return DataStoreService:GetDataStore(settings.DataStoreName .. "_GlobalBackfill_v2") end)
	if not ok then return end
	local function lease(cursor, done, claim)
		local succeeded, result = pcall(function()
			return migration:UpdateAsync("Import", function(current)
				current = current or {}
				if current.Done then return current end
				if current.Owner ~= token and (not claim or (current.Expires or 0) > os.time()) then return nil end
				return {Owner = token, Expires = os.time() + 180, Cursor = cursor or current.Cursor or "", Done = done == true}
			end)
		end)
		return succeeded and result or nil
	end
	local claim = lease(nil, false, true)
	if not claim then return end
	if claim.Done then self.backfillDone = true; return end
	self.backfillDone = self.index:Backfill(profileStore, claim.Cursor, function(cursor, done)
		local renewed = lease(cursor, done, false)
		return renewed ~= nil and renewed.Owner == token
	end, task.wait, function() return self.closing end)
end
return Server
