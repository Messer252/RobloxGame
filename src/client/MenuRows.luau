-- Reuse controls by stable keys so snapshots do not destroy keyboard/controller
-- focus, text entry or a scrolling menu. Factories keep this engine-testable.
local Rows = {}
Rows.__index = Rows

function Rows.new(create)
	return setmetatable({ create = create, records = {}, section = nil }, Rows)
end

function Rows:Begin(section)
	local changed = self.section ~= section
	if changed then
		for _, record in pairs(self.records) do record.object:Destroy() end
		table.clear(self.records)
		self.section = section
	end
	for _, record in pairs(self.records) do record.used = false end
	return changed
end

function Rows:Get(key, kind, action)
	local record = self.records[key]
	if record and record.kind ~= kind then
		record.object:Destroy()
		self.records[key], record = nil, nil
	end
	local created = record == nil
	if not record then
		record = { kind = kind }
		record.object = self.create(kind, function()
			if record.action then record.action() end
		end)
		self.records[key] = record
	end
	record.action, record.used = action, true
	return record.object, created
end

function Rows:Finish()
	for key, record in pairs(self.records) do
		if not record.used then record.object:Destroy(); self.records[key] = nil end
	end
end

return Rows
