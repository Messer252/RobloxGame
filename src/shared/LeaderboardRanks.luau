local Ranks = {}

function Ranks.sort(records, key)
	local rows = {}
	for _, record in ipairs(records) do table.insert(rows, record) end
	table.sort(rows, function(a, b)
		if a[key] == b[key] then return a.userId < b.userId end
		return a[key] > b[key]
	end)
	return rows
end

return Ranks
