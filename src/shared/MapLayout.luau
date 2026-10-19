local Map = { PlayerCount = 8, Width = 900, Length = 1220 }

function Map.plot(slot)
	if type(slot) ~= "number" or slot % 1 ~= 0 or slot < 1 or slot > Map.PlayerCount then return nil end
	local row = math.floor((slot - 1) / 2) + 1
	local z = ({ -144, 144, -420, 420 })[row]
	return { x = slot % 2 == 0 and 98 or -98, z = z, direction = z < 0 and 1 or -1 }
end

return Map
