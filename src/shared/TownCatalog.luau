-- Shared shop, exploration and equipment definitions; all awards are server-owned.
local Town = {
	PackStand = { x = -102, y = 1, z = 0 },
	Blacksmith = { x = 102, y = 1, z = 0 },
	ShopRadius = 22, MarketWidth = 44, MarketDepth = 34, PathZ = 12, PathHalfWidth = 4,
	DailyCrumbs = 100, PickupCrumbs = 5, PickupCooldown = 180, PickupDailyCap = 600,
	Armor = {
		{ Name = "Oat Guard", Cost = 1500, Defense = .05, Color = {173,129,81}, Trim = {101,70,46} },
		{ Name = "Cocoa Plate", Cost = 15000, Defense = .10, Color = {99,65,48}, Trim = {181,143,87} },
		{ Name = "Sugarsteel", Cost = 100000, Defense = .17, Color = {148,174,184}, Trim = {82,111,129} },
		{ Name = "Golden Crust", Cost = 750000, Defense = .24, Color = {205,154,67}, Trim = {110,77,43} },
		{ Name = "Star Cookie", Cost = 5000000, Defense = .32, Color = {96,77,153}, Trim = {111,215,223} },
	},
	Pickups = {
		{-32,0,12},{32,0,12},{-50,0,0},{50,0,0}, {-155,0,0},{155,0,0},
		{-198,0,280},{198,0,280},{-198,0,-280},{198,0,-280},
		{-198,0,560},{198,0,560},{-198,0,-560},{198,0,-560},
		{-205,0,-15},{205,0,-15},
	},
}
function Town.near(point, x, y, z)
	return type(x)=="number" and type(y)=="number" and type(z)=="number" and (x-point.x)^2+(z-point.z)^2<=Town.ShopRadius^2 and math.abs(y-point.y)<=12
end
function Town.buyArmor(profile)
	local tier = profile.life.armor + 1
	local item = Town.Armor[tier]
	if not item then return false, "Best cookie armor owned!" end
	if profile.cash < item.Cost then return false, "Collect more wallet cash for this armor." end
	profile.cash -= item.Cost
	profile.life.armor = tier
	return true, item.Name .. " equipped!"
end
function Town.defense(life) return Town.Armor[life.armor] and Town.Armor[life.armor].Defense or 0 end
return Town
