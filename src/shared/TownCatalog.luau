local Gear = if script then require(script.Parent.GearCatalog) else require("./GearCatalog")
-- Shared shop, exploration and equipment definitions; all awards are server-owned.
local Town = {
	PackStand = { x = 275, y = 1, z = -315 },
	Blacksmith = { x = 345, y = 1, z = -315 },
	ShopRadius = 22, MarketWidth = 44, MarketDepth = 34, PathZ = -282, PathHalfWidth = 6,
	Paths = {
		{x1=0,z1=-282,x2=375,z2=-282},
		{x1=275,z1=-282,x2=275,z2=-299},
		{x1=345,z1=-282,x2=345,z2=-299},
	},
	DailyCrumbs = 100, PickupCrumbs = 5, PickupCooldown = 180, PickupDailyCap = 600,
	Armor = Gear.Armor,
	Pickups = {
		{-32,0,12},{32,0,12},{-50,0,0},{50,0,0}, {205,0,-282},{310,0,-282},
		{-198,0,280},{198,0,280},{-198,0,-280},{198,0,-280},
		{-198,0,560},{198,0,560},{-198,0,-560},{198,0,-560},
		{-205,0,-15},{205,0,-15},
	},
}
-- Distance to the paved branch and its two shop approaches.
function Town.pathDistance(x,z)
	local distance=math.huge
	for _,path in ipairs(Town.Paths) do
		local dx,dz=path.x2-path.x1,path.z2-path.z1
		local t=math.clamp(((x-path.x1)*dx+(z-path.z1)*dz)/(dx*dx+dz*dz),0,1)
		distance=math.min(distance,math.sqrt((x-path.x1-dx*t)^2+(z-path.z1-dz*t)^2))
	end
	return distance
end
function Town.onRoad(x,y,z)
	return y>=-2 and y<8 and (math.abs(x)<13 and math.abs(z)<575 or Town.pathDistance(x,z)<=Town.PathHalfWidth)
end
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
