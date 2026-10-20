-- Shared geology and access rules. All rewards and pin checks run on the server.
local Mine = { Floor = .5, Ceiling = 22, MinX = -382, MaxX = -250, MinZ = 35, MaxZ = 181 }
Mine.Rarities = {
	Common={171,158,132}, Uncommon={116,175,125}, Rare={106,165,210},
	Epic={175,125,207}, Legendary={225,179,82}, Mythical={130,225,215},
}
Mine.Zones = {
	{ Name="Flour Hollow", Pin=1, X=-264, GateX=-250, Color={185,163,125}, Pool={{"Flour",70},{"Cocoa",25},{"Honey",5}} },
	{ Name="Caramel Gallery", Pin=2, X=-289, GateX=-277, Color={181,126,73}, Pool={{"Butter",55},{"Caramel",35},{"Fudge",10}} },
	{ Name="Sugar Grotto", Pin=3, X=-314, GateX=-302, Color={137,168,177}, Pool={{"Sugar",65},{"Mint",30},{"Ruby",5}} },
	{ Name="Golden Oven Vault", Pin=4, X=-339, GateX=-327, Color={196,156,80}, Pool={{"Amber",60},{"Golden",35},{"Royal",5}} },
	{ Name="Starlight Depths", Pin=5, X=-367, GateX=-352, Color={127,133,179}, Pool={{"Cosmic",75},{"Starlight",25}} },
}
Mine.Ores = {
	Flour={Name="Flour Dough",Rarity="Common",HP=6,Dough=4,Respawn=12,Color={190,171,139}},
	Cocoa={Name="Cocoa Dough",Rarity="Uncommon",HP=10,Dough=9,Respawn=15,Color={133,90,63}},
	Honey={Name="Honeycomb Dough",Rarity="Rare",HP=15,Dough=18,Respawn=20,Color={207,161,80}},
	Butter={Name="Butter Dough",Rarity="Common",HP=18,Dough=16,Respawn=15,Color={209,185,123}},
	Caramel={Name="Caramel Vein",Rarity="Uncommon",HP=27,Dough=28,Respawn=18,Color={189,120,62}},
	Fudge={Name="Fudge Geode",Rarity="Rare",HP=36,Dough=45,Respawn=25,Color={115,73,61}},
	Sugar={Name="Crystal Sugar",Rarity="Rare",HP=42,Dough=45,Respawn=18,Color={173,204,208}},
	Mint={Name="Mint Quartz",Rarity="Epic",HP=63,Dough=75,Respawn=24,Color={113,179,150}},
	Ruby={Name="Cherry Ruby",Rarity="Legendary",HP=84,Dough=120,Respawn=32,Color={193,105,123}},
	Amber={Name="Baked Amber",Rarity="Epic",HP=90,Dough=110,Respawn=22,Color={186,127,58}},
	Golden={Name="Golden Batter",Rarity="Legendary",HP=135,Dough=180,Respawn=30,Color={218,173,67}},
	Royal={Name="Royal Cocoa",Rarity="Mythical",HP=180,Dough=280,Respawn=40,Color={153,115,189}},
	Cosmic={Name="Cosmic Cookie Ore",Rarity="Legendary",HP=180,Dough=260,Respawn=28,Color={115,116,179}},
	Starlight={Name="Starlight Dough",Rarity="Mythical",HP=270,Dough=450,Respawn=40,Color={118,213,201}},
}
function Mine.roll(zoneId, roll)
	local zone=Mine.Zones[zoneId]
	if not zone or type(roll)~="number" or roll~=roll then return nil end
	local cursor=math.clamp(roll,0,1)*100
	for _,entry in ipairs(zone.Pool) do cursor-=entry[2]; if cursor<0 then return entry[1] end end
	return zone.Pool[#zone.Pool][1]
end
function Mine.allowed(pin,zoneId)
	return type(pin)=="number" and pin%1==0 and pin>=1 and pin<=5 and Mine.Zones[zoneId]~=nil and pin>=Mine.Zones[zoneId].Pin
end
function Mine.canMine(pin,zoneId,oreId)
	if not Mine.allowed(pin,zoneId) then return false end
	for _,entry in ipairs(Mine.Zones[zoneId].Pool) do if entry[1]==oreId then return true end end
	return false
end
function Mine.interior(x,z)
	return (x>=Mine.MinX and x<=Mine.MaxX and z>=Mine.MinZ and z<=Mine.MaxZ)
		or (x>Mine.MaxX and x<=-224 and z>=96 and z<=120)
end
function Mine.mound(x,z)
	local d=math.max(math.abs(x+320)/101,math.abs(z-108)/108)
	if d>=1 then return 0 end
	local t=math.clamp((1-d)*3.8,0,1)
	return t*t*(3-2*t)*(34+3*math.sin(x/19)*math.cos(z/23))
end
function Mine.carve(x,z,bottom)
	-- Four-stud voxel cells: leave a rock floor, open headroom through y=24.
	return Mine.interior(x,z) and bottom>=0 and bottom<24
end
function Mine.positions()
	local points={}
	for tier,zone in ipairs(Mine.Zones) do
		for index,z in ipairs({54,80,136,162}) do
			table.insert(points,{zone=tier,x=zone.X+(index%2==0 and 2 or -2),z=z})
		end
	end
	return points
end
return Mine
