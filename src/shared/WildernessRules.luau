local Recipes=if script then require(script.Parent.Recipes) else require("./Recipes")
local Rules={BossInterval=1800,BossLifetime=600,BossX=300,BossZ=410,BossRadius=48,RespawnSeconds=45}
Rules.Zones={{x=-300,z=-220,radius=43},{x=-300,z=-520,radius=42},{x=305,z=285,radius=36}}
function Rules.night(hour) return hour>=18 or hour<6 end
function Rules.inside(x,z,zone) return (x-zone.x)^2+(z-zone.z)^2<=zone.radius^2 end
function Rules.bossZone() return {x=Rules.BossX,z=Rules.BossZ,radius=Rules.BossRadius} end
function Rules.damage(pin,bonus) return 10+math.min(5,pin)*2+math.max(0,math.min(13,pin)-5)*.65+(bonus or 0) end
function Rules.hit(record,id,damage)
	if record.hp<=0 or type(damage)~="number" or damage~=damage or damage<=0 or damage==math.huge then return 0 end
	local actual=math.min(record.hp,damage)
	record.hp-=actual
	record.damage[id]=(record.damage[id] or 0)+actual
	return actual
end
function Rules.reward(record,id)
	local damage=record.damage[id] or 0
	if record.hp>0 or damage<=0 then return nil end
	local share=math.clamp(damage/record.maximum,0,1)
	if record.boss and share<.01 then return nil end
	return {cash=math.floor(record.cashPool*share),dough=math.floor(record.doughPool*share),crumbs=math.floor(record.crumbPool*share)}
end
function Rules.drop(roll,pick)
	if roll>=.2 then return nil end
	local rarity=roll<.014 and "Rare" or roll<.07 and "Uncommon" or "Common"
	local pool={}
	for index,recipe in ipairs(Recipes) do if recipe.Rarity==rarity then table.insert(pool,index) end end
	return pool[math.clamp(math.floor(pick*#pool)+1,1,#pool)]
end
return Rules
