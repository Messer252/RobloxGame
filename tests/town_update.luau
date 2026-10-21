local Shape=require("../src/shared/TerrainShape")
local Town=require("../src/shared/TownCatalog")
local Blueprint=require("../src/shared/BakeryBlueprint")
local Flow=require("../src/client/UIFlow")
local Cards=require("../src/shared/CardEconomy")
local Events=require("../src/shared/ValleyEvents")
local Progression=require("../src/shared/Progression")
local Life=require("../src/shared/BakeryLife")
local Polish=require("../src/shared/BakeryPolish")
local Map=require("../src/shared/MapLayout")
return function(test,equal,near,harness,fakeStore)
	test("captured hill pays its online owner away from the hill without catch-up bursts",function()
		local hill,online={},{[11]=true}
		equal(Events.hillStep(hill,{11},online,0),nil)
		equal(Events.hillStep(hill,{11},online,8),nil); equal(hill.owner,11)
		equal(Events.hillStep(hill,{},online,17),nil)
		equal(Events.hillStep(hill,{},online,18),11)
		equal(Events.hillStep(hill,{},online,1000),11)
		equal(Events.hillStep(hill,{},online,1000),nil)
		equal(Events.hillStep(hill,{},online,1009),nil)
		equal(Events.hillStep(hill,{},online,1010),11)
	end)
	test("contesting pauses hill income and a full capture transfers future payments",function()
		local hill,online={owner=11,nextPayout=10},{[11]=true,[22]=true}
		equal(Events.hillStep(hill,{11,22},online,10),nil)
		equal(Events.hillStep(hill,{},online,19),nil)
		equal(Events.hillStep(hill,{},online,20),11)
		Events.hillStep(hill,{22},online,21)
		Events.hillStep(hill,{},online,25) -- Leaving interrupts a capture.
		Events.hillStep(hill,{22},online,26)
		equal(hill.owner,11)
		Events.hillStep(hill,{22},online,34); equal(hill.owner,22)
		equal(Events.hillStep(hill,{},online,44),22)
	end)
	test("logging out releases the hill and cannot create offline income",function()
		local hill={owner=11,nextPayout=10}
		equal(Events.hillStep(hill,{},{},10),nil); equal(hill.owner,nil)
		equal(Events.hillStep(hill,{}, {[11]=true},100),nil)
		Events.hillStep(hill,{11},{[11]=true},101)
		equal(hill.owner,nil) -- Rejoining needs a new capture.
	end)
	test("daily gifts and trail cooldowns survive saving, paid receipts, rejoin and rebirth",function()
		local manager=harness(fakeStore())
		local p=assert(manager:Load(9400,"town"))
		local now=86400+100
		assert(Cards.claimDaily(p.data.life.cards,now,false))
		assert(Cards.pickup(p.data.life.cards,1,now,false))
		equal(p.data.life.cards.crumbs,105)
		assert(not Cards.claimDaily(p.data.life.cards,now+1,false))
		assert(not Cards.pickup(p.data.life.cards,1,now+179,false))
		assert(manager:GrantReceipt(p,"paid:town",123,function(data) data.cash+=50; return true end))
		assert(manager:Save(p,true))
		p=assert(manager:Load(9400,"town-rejoin"))
		equal(p.receipts["paid:town"],123)
		assert(not Cards.claimDaily(p.data.life.cards,now+2,false))
		assert(not Cards.pickup(p.data.life.cards,1,now+179,false))
		assert(Cards.pickup(p.data.life.cards,1,now+180,false))
		p.data.cash,p.data.unlocked=1e8,30
		assert(Progression.rebirth(p.data))
		assert(not Cards.claimDaily(p.data.life.cards,now+3,false))
		assert(not Cards.pickup(p.data.life.cards,1,now+181,false))
		assert(Cards.claimDaily(p.data.life.cards,172800,false))
		equal(p.data.life.cards.crumbs,210)
	end)
	test("trail pickups have independent persisted daily caps and reject forged or full-wallet claims",function()
		local data=Cards.normalize(nil)
		local now=86400
		for i=0,119 do assert(Cards.pickup(data,i%16+1,now+i*180,false)) end
		equal(data.crumbs,600); equal(data.pickupEarned,600)
		assert(not Cards.pickup(data,1,now+22000,false))
		assert(not Cards.pickup(data,0,now+22000,false)); assert(not Cards.pickup(data,1.5,now+22000,false))
		assert(Cards.pickup(data,1,172800,false)); equal(data.pickupEarned,5)
		local full=Cards.normalize({crumbs=Cards.MaxCrumbs})
		assert(not Cards.pickup(full,1,86400,false)); equal(full.pickups["1"],0)
		assert(not Cards.claimDaily(full,86400,false)); equal(full.claimDay,0)
	end)
	test("obby crumb prizes are independent of boosts and persist their five-minute replay guards",function()
		local data=Cards.normalize(nil)
		equal(Cards.obby(data,"Easy",86400,false),20)
		equal(Cards.obby(data,"Medium",86400,false),35)
		equal(Cards.obby(data,"Hard",86400,false),50)
		data=Cards.normalize(data)
		equal(Cards.obby(data,"Easy",86699,false),0)
		equal(Cards.obby(data,"Hard",86699,false),0)
		equal(Cards.obby(data,"Fake",86700,false),0)
		equal(Cards.obby(data,"Easy",86700,false),20)
		equal(data.crumbs,125)
	end)
	test("armor advances one paid tier at a time, bounds defense and resets on rebirth",function()
		local p=Progression.newData()
		equal(p.life.armor,0); equal(Town.defense(p.life),0)
		assert(not Town.buyArmor(p)); equal(p.life.armor,0); equal(p.cash,0)
		p.cash=1e13
		for tier,item in ipairs(Town.Armor) do
			local before=p.cash
			assert(Town.buyArmor(p)); equal(p.cash,before-item.Cost); equal(p.life.armor,tier)
			near(Town.defense(p.life),item.Defense)
		end
		local before=p.cash
		assert(not Town.buyArmor(p)); equal(p.cash,before)
		p.unlocked=30
		assert(Progression.rebirth(p)); equal(p.life.armor,0)
		equal(Progression.normalize(p).life.armor,0)
		equal(Events.damage(5,14,Town.defense(p.life)+.3),Events.damage(5,14,.3))
	end)
	test("version-eight saves migrate to armor defaults while keeping cards, crumbs and receipts",function()
		local store=fakeStore()
		local old=Progression.newData()
		old.life.armor=nil
		old.life.cards=Cards.normalize({crumbs=234,owned={["33"]=1},equipped={33}})
		store.records.Player_9401={Version=8,Data=old,Receipts={previous=123}}
		local manager=harness(store)
		local p=assert(manager:Load(9401,"new-town"))
		equal(p.data.life.armor,0); equal(p.data.life.cards.crumbs,234)
		equal(p.data.life.cards.equipped[1],33); equal(p.receipts.previous,123)
		p.data.cash=Town.Armor[1].Cost
		assert(Town.buyArmor(p.data)); assert(manager:Save(p,true))
		p=assert(manager:Load(9401,"town-again"))
		equal(store.records.Player_9401.Version,require("../src/server/ProfileStore").CURRENT_VERSION); equal(p.data.life.armor,1)
	end)
	test("catalog decoration pads form three spaced upgrade paths with no dead ends",function()
		local p=Progression.newData(); p.cash=1e9
		local purchased=0
		while true do
			local available=Blueprint.available(p.life)
			if #available==0 then break end
			assert(#available<=3)
			for i,key in ipairs(available) do
				local a=Blueprint.pad(i)
				assert(a.x-a.width/2>=-82 and a.x+a.width/2<=82)
				assert(a.z-a.depth/2>=-122 and a.z+a.depth/2<=122)
				for j=1,i-1 do local b=Blueprint.pad(j); assert(math.abs(a.x-b.x)>=a.width+8 or math.abs(a.z-b.z)>=a.depth+8) end
				local def=Polish.Decorations[key]
				assert(not def.Requires or p.life.decorations[def.Requires])
				assert(Polish.buyDecoration(p,key)); purchased+=1
			end
		end
		equal(purchased,#Polish.DecorationOrder)
	end)
	test("machine purchases follow conveyor and processing prerequisites without premature charges",function()
		local p=Progression.newData(); p.cash=1e8
		for _,key in ipairs({"Packager","Boxer","FinishingOven"}) do assert(not Life.machineAvailable(p.life,key)); assert(not Life.buyMachine(p,key)) end
		equal(p.cash,1e8); assert(Polish.buyBelt(p))
		assert(Life.machineAvailable(p.life,"Packager")); assert(not Life.buyMachine(p,"Boxer"))
		assert(Life.buyMachine(p,"Packager")); assert(not Life.machineAvailable(p.life,"Packager"))
		assert(not Life.buyMachine(p,"FinishingOven")); assert(Life.buyMachine(p,"Boxer")); assert(Life.buyMachine(p,"FinishingOven"))
	end)
	test("responsive button rows stay within phone, tablet and desktop widths with fixed gaps",function()
		for _,width in ipairs({180,240,292,320,400,492,800}) do
			for _,n in ipairs({4,5,14}) do
				local columns,cell,total=Flow.metrics(n,width,82,5,8,38)
				assert(columns>=1 and columns<=5 and columns<=n)
				assert(columns*cell+(columns-1)*8<=width)
				equal(total,math.ceil(n/columns)*46-8)
			end
		end
	end)
	test("market foundations and their plaza walkways cannot grow grass through the floor",function()
		for _,point in ipairs({Town.PackStand,Town.Blacksmith}) do
			for x=point.x-Town.MarketWidth/2-4,point.x+Town.MarketWidth/2+4,4 do
				for z=point.z-Town.MarketDepth/2-4,point.z+Town.MarketDepth/2+4,4 do
					assert(Shape.height(x,z)<=-6 and not Shape.grassAllowed(x,z))
				end
			end
		end
		for x=0,375,2 do for z=Town.PathZ-Town.PathHalfWidth-4,Town.PathZ+Town.PathHalfWidth+4,2 do
			assert(Shape.height(x,z)<=-6 and not Shape.grassAllowed(x,z))
		end end
	end)
	test("spawn shops and trail crumbs occupy public space and require nearby ground-level players",function()
		for _,point in ipairs({Town.PackStand,Town.Blacksmith}) do
			assert(Town.near(point,point.x+22,point.y,point.z))
			assert(not Town.near(point,point.x+22.1,point.y,point.z))
			assert(not Town.near(point,point.x,point.y+13,point.z))
		end
		for _,point in ipairs(Town.Pickups) do
			for slot=1,8 do local plot=Map.plot(slot); assert(math.abs(point[1]-plot.x)>82 or math.abs(point[3]-plot.z)>122) end
		end
	end)
end
