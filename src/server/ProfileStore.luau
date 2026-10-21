-- DataStore adapter with no engine dependencies, allowing failure/concurrency tests.
-- All writes check the session token inside UpdateAsync; stale servers cannot overwrite.
local ProfileStore = {}
ProfileStore.__index = ProfileStore
-- Version 11 preserves dormant armor enchantments after a gear-reset rebirth.
-- Older servers would erase them when normalizing an unarmored profile.
ProfileStore.CURRENT_VERSION = 11

local function validRecord(current)
	if type(current) ~= "table" or type(current.Version) ~= "number" or current.Version % 1 ~= 0
		or current.Version < 1 or current.Version > ProfileStore.CURRENT_VERSION or type(current.Data) ~= "table" then return false end
	if current.Receipts ~= nil and type(current.Receipts) ~= "table" then return false end
	if current.Version >= 2 and current.Receipts == nil then return false end
	for id, productId in pairs(current.Receipts or {}) do
		if type(id) ~= "string" or #id == 0 or #id > 200 or type(productId) ~= "number"
			or productId <= 0 or productId >= 2 ^ 53 or productId ~= math.floor(productId) then return false end
	end
	return true
end

local function receiptsCopy(receipts)
	local result = {}
	for id, productId in pairs(receipts or {}) do result[id] = productId end
	return result
end

function ProfileStore.new(store, options)
	return setmetatable({
		store = store,
		clock = options.clock,
		wait = options.wait,
		copy = options.copy,
		lease = options.lease or 180,
	}, ProfileStore)
end

function ProfileStore:_update(key, transform)
	local lastError
	for attempt = 1, 3 do
		local success, result = pcall(function() return self.store:UpdateAsync(key, transform) end)
		if success then return true, result end
		lastError = result
		if attempt < 3 then self.wait(attempt) end
	end
	return false, lastError
end

function ProfileStore:Load(userId, token)
	local key = "Player_" .. tostring(userId)
	local reason
	local ok, result = self:_update(key, function(current)
		reason = nil
		if current ~= nil then
			if not validRecord(current) then
				reason = "unsupported"
				return nil
			end
			local session = current.Session
			if session ~= nil then
				if type(session) ~= "table" or type(session.Id) ~= "string" or type(session.ExpiresAt) ~= "number" then
					reason = "unsupported"
					return nil
				end
				if session.Id ~= token and session.ExpiresAt > self.clock() then
					reason = "locked"
					return nil
				end
			end
		end
		return {
			Version = ProfileStore.CURRENT_VERSION,
			Data = self.copy(current and current.Data),
			Receipts = receiptsCopy(current and current.Receipts),
			Session = { Id = token, ExpiresAt = self.clock() + self.lease },
			UpdatedAt = self.clock(),
		}
	end)
	if not ok then return nil, "unavailable", result end
	if not result or reason then return nil, reason or "unavailable" end
	return {
		key = key, token = token, data = self.copy(result.Data),
		receipts = receiptsCopy(result.Receipts), transacting = false,
		expiresAt = result.Session.ExpiresAt, saving = false, closing = false, closed = false, lost = false,
	}
end

function ProfileStore:Save(profile, release)
	if profile.closed or profile.lost then return false, "lost" end
	if profile.activityLock then return false, "activity_pending" end
	if release then
		profile.closing = true
		while profile.saving do self.wait(0.1) end
		if profile.closed or profile.lost then return false, "lost" end
	elseif profile.saving or profile.closing then
		return false, "busy"
	end
	-- An ambiguous receipt write may already have committed. Never overwrite its
	-- reward with the old local snapshot, including during departure/shutdown.
	if profile.transacting then return false, "receipt_pending" end
	profile.saving = true
	-- Snapshot after waiting, so a final release includes the newest gameplay state.
	local snapshot = self.copy(profile.data)
	local ok, result = self:_update(profile.key, function(current)
		if not validRecord(current) or type(current.Session) ~= "table" or current.Session.Id ~= profile.token then
			return nil
		end
		return {
			Version = ProfileStore.CURRENT_VERSION, Data = snapshot, Receipts = receiptsCopy(current.Receipts),
			Session = if release then nil else { Id = profile.token, ExpiresAt = self.clock() + self.lease },
			UpdatedAt = self.clock(),
		}
	end)
	profile.saving = false
	if not ok then return false, "unavailable", result end
	if not result then
		profile.lost = true
		return false, "lost"
	end
	if release then profile.closed = true else profile.expiresAt = result.Session.ExpiresAt end
	return true
end

function ProfileStore:GrantReceipt(profile, receiptId, productId, grant, activityToken)
	if profile.activityLock and profile.activityLock ~= activityToken then return false, "busy" end
	if type(receiptId) ~= "string" or #receiptId == 0 or #receiptId > 200
		or type(productId) ~= "number" or productId <= 0 or productId >= 2 ^ 53 or productId ~= math.floor(productId) then
		return false, "invalid"
	end
	if profile.receipts and profile.receipts[receiptId] then
		return profile.receipts[receiptId] == productId, "duplicate"
	end
	if profile.closed or profile.closing or profile.lost or profile.sessionOnly then return false, "unavailable_profile" end
	if profile.saving then return false, "busy" end
	if profile.pendingReceipt and (profile.pendingReceipt.Id ~= receiptId or profile.pendingReceipt.ProductId ~= productId) then
		return false, "busy"
	end
	if not profile.pendingReceipt then
		profile.pendingReceipt = { Id = receiptId, ProductId = productId, Snapshot = self.copy(profile.data) }
	end
	profile.transacting = true
	profile.saving = true
	local reason
	local ok, result = self:_update(profile.key, function(current)
		reason = nil
		if not validRecord(current) or type(current.Session) ~= "table" or current.Session.Id ~= profile.token then
			reason = "lost"
			return nil
		end
		local ledger = receiptsCopy(current.Receipts)
		local data
		if ledger[receiptId] then
			if ledger[receiptId] ~= productId then
				reason = "conflict"
				return nil
			end
			data = current.Data -- A prior attempt may have committed despite a network error.
		else
			-- UpdateAsync can call this transform multiple times. Always start from
			-- the same frozen snapshot, never from a previously rewarded copy.
			data = self.copy(profile.pendingReceipt.Snapshot)
			local granted, failure = grant(data)
			if not granted then
				reason = failure or "invalid_reward"
				return nil
			end
			ledger[receiptId] = productId
		end
		return {
			Version = ProfileStore.CURRENT_VERSION, Data = data, Receipts = ledger,
			Session = { Id = profile.token, ExpiresAt = self.clock() + self.lease }, UpdatedAt = self.clock(),
		}
	end)
	profile.saving = false
	if not ok then
		-- Keep the economy frozen until retry/rejoin reconciles the uncertain write.
		return false, "unavailable", result
	end
	if not result then
		profile.pendingReceipt = nil
		profile.transacting = false
		if reason == "lost" then profile.lost = true end
		return false, reason or "unavailable"
	end
	-- Preserve the table identity used by the running tycoon state.
	table.clear(profile.data)
	for key, value in pairs(self.copy(result.Data)) do profile.data[key] = value end
	profile.receipts = receiptsCopy(result.Receipts)
	profile.expiresAt = result.Session.ExpiresAt
	profile.pendingReceipt = nil
	profile.transacting = false
	return true, "granted"
end

return ProfileStore
