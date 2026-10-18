-- DataStore adapter with no engine dependencies, allowing failure/concurrency tests.
-- All writes check the session token inside UpdateAsync; stale servers cannot overwrite.
local ProfileStore = {}
ProfileStore.__index = ProfileStore

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
			if type(current) ~= "table" or current.Version ~= 1 or type(current.Data) ~= "table" then
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
			Version = 1,
			Data = self.copy(current and current.Data),
			Session = { Id = token, ExpiresAt = self.clock() + self.lease },
			UpdatedAt = self.clock(),
		}
	end)
	if not ok then return nil, "unavailable", result end
	if not result or reason then return nil, reason or "unavailable" end
	return {
		key = key, token = token, data = self.copy(result.Data),
		expiresAt = result.Session.ExpiresAt, saving = false, closing = false, closed = false, lost = false,
	}
end

function ProfileStore:Save(profile, release)
	if profile.closed or profile.lost then return false, "lost" end
	if release then
		profile.closing = true
		while profile.saving do self.wait(0.1) end
		if profile.closed or profile.lost then return false, "lost" end
	elseif profile.saving or profile.closing then
		return false, "busy"
	end
	profile.saving = true
	-- Snapshot after waiting, so a final release includes the newest gameplay state.
	local snapshot = self.copy(profile.data)
	local ok, result = self:_update(profile.key, function(current)
		if type(current) ~= "table" or type(current.Session) ~= "table" or current.Session.Id ~= profile.token then
			return nil
		end
		return {
			Version = 1, Data = snapshot,
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

return ProfileStore
