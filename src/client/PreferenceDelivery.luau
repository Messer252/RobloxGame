-- Debounce local edits, then retry until the server acknowledges that revision.
-- A pack/trade can temporarily block writes without losing the player's choice.
local Delivery = {}
Delivery.__index = Delivery

function Delivery.new(send)
	return setmetatable({ send = send, revision = 0, pending = nil, nextSend = 0 }, Delivery)
end

function Delivery:Queue(preferences, now)
	self.revision += 1
	self.pending = table.clone(preferences)
	self.pending.Revision = self.revision
	self.nextSend = now + .4
end

function Delivery:Step(now, ready)
	if not ready or not self.pending or now < self.nextSend then return end
	self.nextSend = now + 1
	self.send(table.clone(self.pending))
end

function Delivery:Acknowledge(revision)
	if not self.pending or revision ~= self.revision then return false end
	self.pending = nil
	return true
end

return Delivery
