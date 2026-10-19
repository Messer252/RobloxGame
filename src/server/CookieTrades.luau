-- Durable two-profile exchange. The immutable journal decides ownership; both
-- profiles retain a recovery reference before the journal can commit.
local Life = if script then require(game:GetService("ReplicatedStorage").CookieTycoon.BakeryLife) else require("../shared/BakeryLife")
local Trades = {}
Trades.__index = Trades
function Trades.new(store, profiles, wait)
	return setmetatable({ store = store, profiles = profiles, wait = wait }, Trades)
end
function Trades:_journal(id, transform)
	for attempt = 1, 3 do
		local ok, result = pcall(function() return self.store:UpdateAsync("Trade_" .. id, transform) end)
		if ok then return result end
		if attempt < 3 then self.wait(attempt) end
	end
	return nil
end
function Trades.apply(data, record, userId)
	if userId ~= record.a and userId ~= record.b then return false, "invalid_participant" end
	if data.life.pendingTrade ~= "" and data.life.pendingTrade ~= record.id then return false, "conflict" end
	if record.state == "Committed" then
		local outgoing, incoming
		if userId == record.a then outgoing, incoming = record.giveA, record.giveB
		elseif userId == record.b then outgoing, incoming = record.giveB, record.giveA
		else return false, "invalid_participant" end
		if outgoing and not Life.find(data.life, outgoing.id) then return false, "missing_cookie" end
		if incoming and not Life.cookie(incoming) then return false, "invalid_cookie" end
		if incoming and Life.find(data.life, incoming.id) then return false, "duplicate_cookie" end
		local finalCount = #data.life.inventory - (outgoing and 1 or 0) + (incoming and 1 or 0)
		if finalCount > Life.capacity(data.life) then return false, "capacity" end
		if outgoing then Life.remove(data.life, outgoing.id) end
		if incoming then table.insert(data.life.inventory, Life.cookie(incoming)) end
	elseif record.state ~= "Aborted" then return false, "undecided" end
	data.life.pendingTrade = ""
	return true
end
function Trades:_grant(profile, key, grant, token)
	for _ = 1, 5 do
		local ok, reason = self.profiles:GrantReceipt(profile, key, 1, grant, token)
		if ok then return true end
		if reason ~= "unavailable" and reason ~= "busy" then return false end
		self.wait(0.5)
	end
	return false
end
function Trades:Recover(profile, userId, forcedId)
	local id = forcedId or profile.data.life.pendingTrade
	if not id or id == "" then return true end
	profile.activityLock = id
	local record = self:_journal(id, function(current)
		if not current then return nil end
		if current.state == "Prepared" then current.state = "Aborted" end
		return current
	end)
	if not record or (record.a ~= userId and record.b ~= userId) then return false end
	local prepareKey = "ct:p:" .. id .. ":" .. userId
	if profile.pendingReceipt and profile.pendingReceipt.Id == prepareKey then
		if not self:_grant(profile, prepareKey, function(data) data.life.pendingTrade = id ; return true end, id) then return false end
	end
	local ok = self:_grant(profile, "ct:a:" .. id .. ":" .. userId, function(data) return Trades.apply(data, record, userId) end, id)
	if ok then profile.activityLock = nil end
	return ok
end
function Trades:Exchange(id, a, aId, aCookieId, b, bId, bCookieId)
	if a.sessionOnly or b.sessionOnly then return false, "Cookie trading needs persistent saves in a published game.", false end
	for _, profile in ipairs({ a, b }) do
		if profile.sessionOnly or profile.closed or profile.closing or profile.lost or profile.saving or profile.transacting
			or profile.activityLock or profile.data.life.pendingTrade ~= "" then return false, "Player saving is busy; try again.", false end
	end
	if aId == bId or not Life.available(a.data.life, aCookieId)
		or (bCookieId and not Life.available(b.data.life, bCookieId)) then return false, "Cookie offer changed.", false end
	if not bCookieId and #b.data.life.inventory >= Life.capacity(b.data.life) then return false, "Their cookie bag is full.", false end
	local record = { id = id, state = "Prepared", a = aId, b = bId,
		giveA = Life.cookie(Life.find(a.data.life, aCookieId)), giveB = bCookieId and Life.cookie(Life.find(b.data.life, bCookieId)) or nil }
	a.activityLock, b.activityLock = id, id
	local created = self:_journal(id, function(current) return current or record end)
	if not created then
		a.activityLock, b.activityLock = nil, nil -- No profile was modified or prepared.
		return false, "Trade saving is unavailable. Nothing was exchanged.", false
	end
	if created.state ~= "Prepared" or created.a ~= aId or created.b ~= bId
		or not created.giveA or created.giveA.id ~= record.giveA.id
		or (created.giveB and created.giveB.id or nil) ~= (record.giveB and record.giveB.id or nil) then
		a.activityLock, b.activityLock = nil, nil
		return false, "Trade reference conflict. Nothing was exchanged.", false
	end
	local prepared = true
	for _, side in ipairs({ { a, aId }, { b, bId } }) do
		if not self:_grant(side[1], "ct:p:" .. id .. ":" .. side[2], function(data) data.life.pendingTrade = id ; return true end, id) then prepared = false ; break end
	end
	local decided = self:_journal(id, function(current)
		if not current then return nil end
		if current.state == "Prepared" then current.state = prepared and "Committed" or "Aborted" end
		return current
	end)
	if not decided then return false, "Trade recovery pending. Your cookies are protected; please wait.", true end
	local recoveredA, recoveredB = self:Recover(a, aId, id), self:Recover(b, bId, id)
	if not recoveredA or not recoveredB then return false, "Trade recovery pending. Please wait or rejoin to recover.", true end
	return decided.state == "Committed", decided.state == "Committed" and "Cookie exchange saved!" or "Trade canceled; both offers were kept.", false
end
return Trades
