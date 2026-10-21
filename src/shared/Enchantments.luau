-- Earned Star Crumbs only. Roll server-side once; never replace a better result.
local Enchant = { Cost=100, Rarities={
	{Name="Common",Weight=50,Color={222,209,182},Mine=.05,Damage=1,Defense=.01,Rate=2},
	{Name="Uncommon",Weight=28,Color={116,211,143},Mine=.10,Damage=2,Defense=.02,Rate=4},
	{Name="Rare",Weight=15,Color={107,175,245},Mine=.18,Damage=3,Defense=.04,Rate=6},
	{Name="Legendary",Weight=6,Color={246,189,80},Mine=.28,Damage=4,Defense=.06,Rate=9},
	{Name="Mythical",Weight=1,Color={224,135,241},Mine=.40,Damage=5,Defense=.08,Rate=12},
} }
function Enchant.normalize(raw)
	local result={Pin=0,Armor=0}
	for key in pairs(result) do
		local n=type(raw)=="table" and raw[key]
		if type(n)=="number" and n%1==0 and n>=0 and n<=#Enchant.Rarities then result[key]=n end
	end
	return result
end
function Enchant.roll(value)
	assert(type(value)=="number" and value>=0 and value<=1,"Invalid enchant roll")
	local remaining=math.min(value,1-1e-10)*100
	for index,rarity in ipairs(Enchant.Rarities) do
		if remaining<rarity.Weight then return index end
		remaining-=rarity.Weight
	end
	return #Enchant.Rarities
end
function Enchant.effect(life,slot)
	return Enchant.Rarities[life.enchants and life.enchants[slot]] or {Mine=0,Damage=0,Defense=0}
end
function Enchant.apply(profile,slot,rolled)
	if slot~="Pin" and slot~="Armor" then return false,"Choose a rolling pin or armor." end
	if type(rolled)~="number" or rolled%1~=0 or not Enchant.Rarities[rolled] then return false,"Invalid enchantment." end
	local life=profile.life
	if slot=="Armor" and life.armor<1 then return false,"Buy armor before enchanting it." end
	life.enchants=Enchant.normalize(life.enchants)
	local previous=life.enchants[slot]
	if previous==#Enchant.Rarities then return false,"Mythical enchantment already owned!" end
	if life.cards.crumbs<Enchant.Cost then return false,"You need 100 Star Crumbs." end
	life.cards.crumbs-=Enchant.Cost
	life.enchants[slot]=math.max(previous,rolled)
	local result=Enchant.Rarities[rolled].Name
	if rolled<=previous then return true,"Rolled "..result..". Your saved "..Enchant.Rarities[previous].Name.." enchantment stays." end
	return true,result.." "..slot.." enchantment! It stays through gear upgrades and rebirth."
end
return Enchant
