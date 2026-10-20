-- Durable ranking index and read cache. Engine-free so outages and offline
-- saves can be tested without contacting Roblox services.
local ProfileStore = if script then require(script.Parent.ProfileStore) else require("./ProfileStore")
local Rankings = {}
Rankings.__index = Rankings
local keys = { "cash", "rebirths" }
local function userId(value)
	local id = tonumber(value)
	return id and id > 0 and id < 2^53 and id % 1 == 0 and id or nil
end
local function score(value)
	return type(value) == "number" and value == value and value >= 0 and value < 2^53 and math.floor(value) or nil
end
function Rankings.new(stores, readProfile, lookupName, clock)
	return setmetatable({ stores = stores, readProfile = readProfile, lookupName = lookupName, clock = clock,
		pending = {}, versions = {}, completed = {}, nextWrite = {}, names = {}, rows = {}, status = {} }, Rankings)
end
function Rankings:Queue(id)
	id = userId(id)
	if not id then return nil end
	self.versions[id] = (self.versions[id] or 0) + 1
	self.pending[id] = self.versions[id]
	return self.versions[id]
end
function Rankings:_complete(id, version, now)
	self.completed[id] = version
	if self.pending[id] == version then self.pending[id] = nil end
	self.nextWrite[id] = now + 30
end
function Rankings:FlushOne()
	local now, id, version = self.clock()
	for candidate, generation in pairs(self.pending) do
		if now >= (self.nextWrite[candidate] or 0) then id, version = candidate, generation; break end
	end
	if not id then return false end
	self.nextWrite[id] = now + 5
	-- Always read committed profile data, never unsaved wallet state or client
	-- input. This also lets the one-time backfill index offline players.
	local ok, saved = pcall(self.readProfile, id)
	if not ok then return false, "read_failed" end
	if saved ~= nil then
		if type(saved) ~= "table" or type(saved.Version) ~= "number" or saved.Version % 1 ~= 0 or saved.Version < 1 or saved.Version > ProfileStore.CURRENT_VERSION or type(saved.Data) ~= "table" then
			self:_complete(id, version, now)
			return true, "unsupported_profile"
		end
		local values = { cash = score(saved.Data.cash), rebirths = score(saved.Data.rebirths) }
		if values.cash == nil or values.rebirths == nil then self:_complete(id, version, now); return true, "invalid_scores" end
		for _, key in ipairs(keys) do
			local written = pcall(function() self.stores[key]:SetAsync(tostring(id), values[key]) end)
			if not written then return false, "write_failed" end
		end
		-- A departing server can still be finishing an index write while another
		-- server saves a newer wallet. Re-read after writing and repair that race,
		-- including decreases, instead of leaving an offline player stale forever.
		local checked, latest = pcall(self.readProfile, id)
		if not checked then return false, "read_failed" end
		if type(latest) ~= "table" or type(latest.Data) ~= "table" or latest.Data.cash ~= saved.Data.cash or latest.Data.rebirths ~= saved.Data.rebirths then
			self:Queue(id)
			return false, "changed_during_write"
		end
	end
	self:_complete(id, version, now)
	return true
end
function Rankings:_name(id)
	local now, cached = self.clock(), self.names[id]
	if cached and cached.expires > now then return cached.value end
	local ok, name = pcall(self.lookupName, id)
	ok = ok and type(name) == "string" and name ~= ""
	if not ok then
		name = cached and cached.value or ("User " .. id)
	end
	self.names[id] = { value = name, expires = now + (ok and 3600 or 60) }
	return name
end
function Rankings:Refresh(key)
	if not self.stores[key] then return false end
	local ok, entries = pcall(function() return self.stores[key]:GetSortedAsync(false, 8):GetCurrentPage() end)
	if not ok then
		self.status[key] = self.rows[key] and "Cached • reconnecting" or "Global rankings unavailable"
		return false
	end
	local rows = {}
	for _, entry in ipairs(entries) do
		local id, value = userId(entry.key), score(entry.value)
		if id and value then table.insert(rows, { userId = id, name = self:_name(id), [key] = value }) end
	end
	table.sort(rows, function(a, b) return a[key] == b[key] and a.userId < b.userId or a[key] > b[key] end)
	self.rows[key], self.status[key] = rows, "Saved rankings • refresh every 60s"
	return true
end
function Rankings:Get(key)
	return self.rows[key] or {}, self.status[key] or "Loading global rankings…"
end
function Rankings:Backfill(profileStore, cursor, lease, wait, closing)
	local ok, pages = pcall(function() return profileStore:ListKeysAsync("Player_", 20, cursor, true) end)
	if not ok then return false end
	while not closing() do
		local goals = {}
		for _, key in ipairs(pages:GetCurrentPage()) do
			local id = tonumber(key.KeyName:match("^Player_(%d+)$"))
			if id then goals[id] = self:Queue(id) end
		end
		local renew = self.clock() + 45
		while not closing() do
			local complete = true
			for id, version in pairs(goals) do if (self.completed[id] or 0) < version then complete = false end end
			if complete then break end
			if self.clock() >= renew then
				if not lease(nil, false) then return false end
				renew = self.clock() + 45
			end
			wait(1)
		end
		if closing() then return false end
		if pages.IsFinished then return lease(nil, true) end
		-- Cursor points to the NEXT page. Persist it after indexing this page,
		-- before advancing, so a restart cannot skip unindexed offline profiles.
		if not lease(pages.Cursor, false) then return false end
		local advanced = pcall(function() pages:AdvanceToNextPageAsync() end)
		if not advanced then return false end
	end
	return false
end
return Rankings
