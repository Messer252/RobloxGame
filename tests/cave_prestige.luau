local Mine=require("../src/shared/MiningCatalog")
local Shape=require("../src/shared/TerrainShape")
local Progression=require("../src/shared/Progression")
local Grants=require("../src/server/AdminRewards")
local Permissions=require("../src/server/AdminPermissions")
local Cards=require("../src/shared/CardEconomy")
local Camera=require("../src/shared/CameraLockRules")
return function(test,equal,near,harness,fakeStore)
	test("every cave ore pool rolls its intended weights and stays in its own gallery",function()
		local seen={}
		for tier,zone in ipairs(Mine.Zones) do
			local counts,total={},0
			for i=0,99 do local id=Mine.roll(tier,(i+.5)/100); counts[id]=(counts[id] or 0)+1 end
			for _,entry in ipairs(zone.Pool) do
				local id,weight=entry[1],entry[2]
				equal(counts[id],weight); total+=weight; assert(not seen[id]); seen[id]=true
				local ore=Mine.Ores[id]
				assert(ore and Mine.Rarities[ore.Rarity] and ore.HP>0 and ore.Dough>0 and ore.Respawn>=10)
				equal(ore.HP%1,0); equal(ore.Dough%1,0)
			end
			equal(total,100)
			equal(Mine.roll(tier,0),zone.Pool[1][1]); equal(Mine.roll(tier,1),zone.Pool[#zone.Pool][1])
		end
		for id in pairs(Mine.Ores) do assert(seen[id]) end
		equal(Mine.roll(6,.5),nil); equal(Mine.roll(1,0/0),nil)
	end)
	test("cave access and mining enforce the owned pin tier regardless of damage bonuses",function()
		for tier,zone in ipairs(Mine.Zones) do
			for pin=1,13 do
				equal(Mine.allowed(pin,tier),pin>=tier)
				for _,entry in ipairs(zone.Pool) do equal(Mine.canMine(pin,tier,entry[1]),pin>=tier) end
			end
		end
		assert(not Mine.canMine(5,1,"Starlight"))
		for _,pin in ipairs({0,14,1.5,"5",math.huge,0/0}) do assert(not Mine.allowed(pin,2)) end
	end)
	test("all twenty ore placements fit inside carved rooms away from the central passage",function()
		local points=Mine.positions(); equal(#points,20)
		for _,p in ipairs(points) do
			assert(Mine.interior(p.x,p.z))
			assert(math.abs(p.z-108)>20)
			for dx=-4,4,4 do for dz=-4,4,4 do
				assert(Mine.interior(p.x+dx,p.z+dz))
				assert(Mine.mound(p.x+dx,p.z+dz)>27)
				assert(Mine.carve(p.x+dx,p.z+dz,4))
			end end
		end
	end)
	test("terrain carving leaves a cave floor and roof without filling roads or nearby plots",function()
		for x=-380,-228,4 do
			assert(Mine.carve(x,108,0) and Mine.carve(x,108,20))
			assert(not Mine.carve(x,108,-4) and not Mine.carve(x,108,24))
		end
		assert(not Mine.carve(0,108,4)); assert(not Mine.carve(-320,200,4))
		for z=-560,560,20 do assert(Shape.height(0,z)<=-6) end
		for _,x in ipairs({-98,98}) do for _,z in ipairs({-420,-144,144,420}) do assert(Shape.height(x,z)<=-6) end end
		near(Mine.mound(-421,108),0); near(Mine.mound(-219,108),0)
		assert(Shape.height(-320,108)>27)
		assert(Shape.height(-231,108)<=-6 and not Shape.grassAllowed(-231,108))
	end)
	test("saved cash increases Golden Chip payouts with diminishing returns and a fivefold cap",function()
		local data=Progression.newData(); data.unlocked=18
		for _,entry in ipairs({{5000000,5},{7200000,6},{20000000,10},{45000000,15},{125000000,25},{1e15,25}}) do
			data.cash=entry[1]; data.bank=0
			local requirement=Progression.rebirthRequirement(data)
			equal(requirement.Reward,entry[2]); equal(requirement.Bonus,entry[2]-5)
		end
		data.cash,data.bank=8000000,12000000
		equal(Progression.rebirthRequirement(data).Reward,10)
		assert(Progression.rebirth(data)); equal(data.chips,10); equal(data.bank,0)
		assert(not Progression.rebirth(data)); equal(data.chips,10)
	end)
	test("every displayed next-chip threshold pays exactly at its integer cash target",function()
		for rebirth=0,49 do
			local data=Progression.newData(); data.rebirths=rebirth
			local current=Progression.rebirthRequirement(data)
			while current.NextCash do
				local target,reward=current.NextCash,current.Reward
				data.cash=target-1
				equal(Progression.rebirthRequirement(data).Reward,reward)
				data.cash=target
				current=Progression.rebirthRequirement(data)
				equal(current.Reward,reward+1)
			end
			equal(current.Reward,current.BaseReward*5)
		end
	end)
	test("bonus rebirth checks recipe requirements and chip capacity before clearing progress",function()
		local data=Progression.newData(); data.cash=20000000
		assert(not Progression.rebirth(data)); equal(data.cash,20000000)
		data.unlocked=18; data.chips=Progression.MAX_CHIPS-9
		assert(not Progression.rebirth(data)); equal(data.cash,20000000); equal(data.rebirths,0)
		data.chips-=1
		assert(Progression.rebirth(data)); equal(data.chips,Progression.MAX_CHIPS)
	end)
	test("only verified admins can grant Golden Chips and Star Crumbs",function()
		for _,action in ipairs({"GiveGoldenChips","GiveStarCrumbs"}) do
			assert(Permissions.authorize({[11]=true},11,action,22))
			assert(not Permissions.authorize({[11]=true},22,action,22))
		end
	end)
	test("admin chip and crumb gifts are exact, capped, and never consume daily claim limits",function()
		local data=Progression.newData(); data.life.cards.claimDay=12; data.life.cards.pickupEarned=100
		assert(Grants.grant(data,"GiveGoldenChips",50,10000)); equal(data.chips,50)
		assert(Grants.grant(data,"GiveStarCrumbs",125,100000)); equal(data.life.cards.crumbs,125)
		equal(data.life.cards.claimDay,12); equal(data.life.cards.pickupEarned,100); equal(data.cash,0)
		for _,action in ipairs({"GiveGoldenChips","GiveStarCrumbs"}) do
			for _,amount in ipairs({0,-1,1.5,0/0,math.huge,"100",{},100001}) do assert(not Grants.grant(data,action,amount,100000)) end
		end
		data.chips=Progression.MAX_CHIPS; data.life.cards.crumbs=Cards.MaxCrumbs
		assert(not Grants.grant(data,"GiveGoldenChips",1,10000))
		assert(not Grants.grant(data,"GiveStarCrumbs",1,100000))
	end)
	test("admin currency gifts survive rebirth while mining pins reset across save rejoin",function()
		local store=fakeStore(); local manager=harness(store)
		local profile=assert(manager:Load(1501,"cave-admin"))
		profile.data.life.pin=4; profile.data.cash=20000000; profile.data.unlocked=18
		assert(Grants.grant(profile.data,"GiveGoldenChips",100,10000))
		assert(Grants.grant(profile.data,"GiveStarCrumbs",350,100000))
		assert(Progression.rebirth(profile.data))
		assert(manager:Save(profile,true))
		local restored=assert(manager:Load(1501,"cave-admin-return"))
		equal(restored.data.chips,110); equal(restored.data.life.cards.crumbs,350); equal(restored.data.life.pin,1)
	end)
	test("combat camera lock releases for menus, typing, flight, death and non-player cameras",function()
		local state={requested=true,alive=true,focused=true}
		assert(Camera.active(state))
		for _,key in ipairs({"typing","menu","flying","seated","platform","scripted"}) do
			state[key]=true; assert(not Camera.active(state)); state[key]=false
			assert(Camera.active(state))
		end
		for _,key in ipairs({"requested","alive","focused"}) do
			state[key]=false; assert(not Camera.active(state)); state[key]=true
		end
	end)
end
