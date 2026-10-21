local Gear=require("../src/shared/GearCatalog")
local Enchant=require("../src/shared/Enchantments")
local Life=require("../src/shared/BakeryLife")
local Progression=require("../src/shared/Progression")
local Profiles=require("../src/server/ProfileStore")
local Obbys=require("../src/shared/ObbyCatalog")
local Run=require("../src/shared/ObbyProgress")
local Shape=require("../src/shared/TerrainShape")
local Town=require("../src/shared/TownCatalog")
local Map=require("../src/shared/MapLayout")
local Events=require("../src/shared/ValleyEvents")
local Mine=require("../src/shared/MiningCatalog")

return function(test,equal,near,harness,fakeStore)
	test("all thirteen gear tiers purchase sequentially and expose finite mining and defense values",function()
		equal(#Gear.Pins,13); equal(#Gear.Armor,13)
		local p=Progression.newData()
		p.cash=1e14
		for tier=2,13 do
			local before=p.cash
			assert(Life.upgradePin(p)); equal(p.life.pin,tier)
			equal(p.cash,before-Gear.Pins[tier].Cost)
			assert(Gear.Pins[tier].Power>Gear.Pins[tier-1].Power)
			assert(Gear.Pins[tier].Cost>Gear.Pins[tier-1].Cost)
			assert(Gear.Armor[tier].Defense>Gear.Armor[tier-1].Defense)
			for zone=1,#Mine.Zones do equal(Mine.allowed(tier,zone),tier>=zone) end
		end
		local before=p.cash
		assert(not Life.upgradePin(p)); equal(p.cash,before)
		equal(Life.normalize({pin=999,armor=999}).pin,13)
		equal(Life.normalize({pin=999,armor=999}).armor,13)
	end)
	test("enchant odds hit every exact boundary and invalid saved ranks are discarded",function()
		local total=0
		for rank,rarity in ipairs(Enchant.Rarities) do
			equal(Enchant.roll(total/100),rank)
			equal(Enchant.roll((total+rarity.Weight-.001)/100),rank)
			total+=rarity.Weight
		end
		equal(total,100); equal(Enchant.roll(1),5)
		for _,bad in ipairs({-1,6,1.5,"5",math.huge,0/0}) do
			local v=Enchant.normalize({Pin=bad,Armor=bad})
			equal(v.Pin,0); equal(v.Armor,0)
		end
	end)
	test("enchants charge earned crumbs, preserve the best roll, and reject unowned or maxed gear",function()
		local p=Progression.newData()
		p.life.cards.crumbs=1000
		assert(not Enchant.apply(p,"Armor",5)); equal(p.life.cards.crumbs,1000)
		assert(not Enchant.apply(p,"Wallet",5)); equal(p.life.cards.crumbs,1000)
		assert(not Enchant.apply(p,"Pin",0)); equal(p.life.cards.crumbs,1000)
		assert(Enchant.apply(p,"Pin",3)); equal(p.life.enchants.Pin,3); equal(p.life.cards.crumbs,900)
		assert(Enchant.apply(p,"Pin",1)); equal(p.life.enchants.Pin,3); equal(p.life.cards.crumbs,800)
		assert(Enchant.apply(p,"Pin",3)); equal(p.life.enchants.Pin,3); equal(p.life.cards.crumbs,700)
		assert(Enchant.apply(p,"Pin",5)); equal(p.life.enchants.Pin,5); equal(p.life.cards.crumbs,600)
		assert(not Enchant.apply(p,"Pin",5)); equal(p.life.cards.crumbs,600)
		p.life.armor=1; p.life.cards.crumbs=99
		assert(not Enchant.apply(p,"Armor",1)); equal(p.life.cards.crumbs,99)
		equal(p.life.enchants.Armor,0)
	end)
	test("enchanted gear persists across upgrades, rebirth, save and rejoin",function()
		local store=fakeStore(); local manager=harness(store)
		local profile=assert(manager:Load(9901,"forge-first")); local p=profile.data
		p.life.cards.crumbs=600; p.cash=1e14; p.unlocked=30
		assert(Town.buyArmor(p)); assert(Enchant.apply(p,"Armor",4)); assert(Enchant.apply(p,"Pin",5))
		for _=1,12 do assert(Life.upgradePin(p)); assert(Town.buyArmor(p)) end
		assert(Progression.rebirth(p))
		equal(p.life.pin,13); equal(p.life.armor,13)
		equal(p.life.enchants.Pin,5); equal(p.life.enchants.Armor,4); equal(p.life.cards.crumbs,400)
		assert(manager:Save(profile,true))
		profile=assert(manager:Load(9901,"forge-return")); p=profile.data
		equal(p.life.pin,13); equal(p.life.armor,13); equal(p.life.enchants.Pin,5); equal(p.life.enchants.Armor,4)
		near(Enchant.effect(p.life,"Pin").Mine,.4)
		near(Life.miningPower(p.life),106*1.4)
		near(Enchant.effect(p.life,"Armor").Defense,.06)
	end)
	test("version-nine migration preserves existing equipment and starts enchantments empty",function()
		local store=fakeStore(); local p=Progression.newData()
		p.cash=35000000; p.life.pin=5; p.life.armor=5; p.life.cards.crumbs=700; p.life.enchants=nil
		store.records.Player_9902={Version=9,Data=p,Receipts={earlier=1234}}
		local profile=assert(harness(store):Load(9902,"forge-migrate"))
		equal(store.records.Player_9902.Version,Profiles.CURRENT_VERSION)
		equal(profile.data.life.enchants.Pin,0); equal(profile.data.life.enchants.Armor,0)
		equal(profile.data.life.pin,5); equal(profile.data.life.armor,5)
		equal(profile.data.life.cards.crumbs,700); equal(profile.data.cash,35000000)
		equal(profile.receipts.earlier,1234)
	end)
	test("uncertain enchant writes reconcile one frozen roll and one crumb charge",function()
		local store=fakeStore(); local manager=harness(store)
		local profile=assert(manager:Load(9903,"forge-receipt"))
		profile.data.life.cards.crumbs=500
		store.commitErrorsRemaining=3
		local function grant(data) return Enchant.apply(data,"Pin",4) end
		assert(not manager:GrantReceipt(profile,"ce:test",1,grant))
		assert(profile.transacting)
		assert(manager:GrantReceipt(profile,"ce:test",1,grant))
		equal(profile.data.life.enchants.Pin,4); equal(profile.data.life.cards.crumbs,400)
		assert(manager:GrantReceipt(profile,"ce:test",1,grant))
		equal(profile.data.life.cards.crumbs,400)
		assert(manager:Save(profile,true))
		profile=assert(manager:Load(9903,"forge-recovered"))
		equal(profile.data.life.cards.crumbs,400); equal(profile.data.life.enchants.Pin,4)
	end)
	test("gear and enchant combat bonuses stay bounded independently of mining power",function()
		local p=Progression.newData()
		p.life.pin,p.life.armor,p.life.enchants.Pin,p.life.enchants.Armor=13,13,5,5
		local offense=Enchant.effect(p.life,"Pin").Damage
		local defense=Town.defense(p.life)+Enchant.effect(p.life,"Armor").Defense
		assert(defense<.60 and defense>.48)
		local hit=Events.damage(13,offense,0)
		assert(hit>Events.damage(5,0,0) and hit<=31)
		assert(Events.damage(13,offense+14,0)<50)
		assert(Events.damage(13,offense,defense)>=12)
		equal(Events.damage(13,offense,1),Events.damage(13,offense,.60))
	end)
	test("all obby pits remove terrain and meadow slabs while preserving start approaches and lake",function()
		local regions=Obbys.groundRegions()
		local function covered(x,z)
			for _,r in ipairs(regions) do if x>r[1] and x<r[2] and z>r[3] and z<r[4] then return true end end
			return false
		end
		for _,course in ipairs(Obbys) do
			local r=Obbys.pit(course)
			assert(covered(230,course.Z)); assert(not covered(300,course.Z))
			for x=r[1]+1,r[2]-1,3 do for z=r[3]+1,r[4]-1,3 do
				assert(not covered(x,z)); equal(Shape.height(x,z),-20); assert(not Shape.grassAllowed(x,z))
			end end
		end
		assert(not covered(-285,-370)); assert(covered(0,0))
		for slot=1,8 do local p=Map.plot(slot); assert(covered(p.x,p.z)) end
	end)
	test("harder obbys retain reachable landings and provide wider hazard and finish platforms",function()
		for difficulty,course in ipairs(Obbys) do
			assert(course.Count>=({14,18,24})[difficulty])
			local previous={x=230,y=.4,z=course.Z,width=10}
			local hazards=0
			for index=1,course.Count do
				local p=Obbys.platform(course,index)
				local gap=math.sqrt((p.x-previous.x)^2+(p.z-previous.z)^2)-(p.width+previous.width)/2
				assert(gap<8 and p.y-previous.y<=5)
				assert(Obbys.inPit(p.x-p.width/2,p.z-p.width/2))
				assert(Obbys.inPit(p.x+p.width/2,p.z+p.width/2))
				if p.hazard then
					hazards+=1; assert(p.width>=7)
					equal(p.hazard,({"Edge","Hurdle","Sweeper"})[difficulty])
				end
				previous=p
			end
			assert(hazards>=3); assert(previous.width>=9)
		end
	end)
	test("finish retries require actual final-platform contact and reset runs lose checkpoint progress",function()
		local course=Obbys[3]; local run=Run.start(course,0)
		for stage=1,course.Count do assert(Run.advance(run,course,stage,stage*2)) end
		assert(Run.canFinish(run,course,true))
		assert(not Run.canFinish(run,course,false))
		assert(not Run.canFinish(run,Obbys[1],true))
		run.awarded=true; assert(not Run.canFinish(run,course,true))
		run=Run.start(course,100)
		equal(run.stage,0); assert(not Run.canFinish(run,course,true))
		assert(not Run.advance(run,course,course.Count,200))
	end)
	test("hazards catch standing feet and side contact while allowing a clean jump over them",function()
		assert(Run.hazardContact(0,0,0,.55,.9,6.4,3))
		assert(Run.hazardContact(.85,2.5,0,.55,.9,6.4,3))
		assert(not Run.hazardContact(1.1,0,0,.55,.9,6.4,3))
		assert(not Run.hazardContact(0,3.1,0,.55,.9,6.4,3))
		assert(not Run.hazardContact(0,0,4,.55,.9,6.4,3))
	end)
	test("market roofs and fast path stay outside every bakery and all three obbys",function()
		for _,shop in ipairs({Town.PackStand,Town.Blacksmith}) do
			for slot=1,8 do
				local plot=Map.plot(slot)
				assert(math.abs(shop.x-plot.x)>82+23 or math.abs(shop.z-plot.z)>122+18)
			end
			assert(not Obbys.inPit(shop.x,shop.z,24))
			assert(Town.pathDistance(shop.x,shop.z+17)<=17)
		end
		for _,path in ipairs(Town.Paths) do for t=0,1,.01 do
			local x,z=path.x1+(path.x2-path.x1)*t,path.z1+(path.z2-path.z1)*t
			assert(Town.onRoad(x,4,z)); assert(not Town.onRoad(x,20,z))
			assert(Shape.height(x,z)<=-6 and not Shape.grassAllowed(x,z))
			for slot=1,8 do local p=Map.plot(slot)
				assert(math.abs(x-p.x)>82+Town.PathHalfWidth or math.abs(z-p.z)>122+Town.PathHalfWidth)
			end
		end end
		assert(Town.onRoad(0,4,0)); assert(not Town.onRoad(35,4,0))
	end)
end
