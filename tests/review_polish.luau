local Delivery=require("../src/client/PreferenceDelivery")
local Rows=require("../src/client/MenuRows")
local Rewards=require("../src/shared/ObbyRewards")
local Cards=require("../src/shared/CardEconomy")
local Progression=require("../src/shared/Progression")
local Contracts=require("../src/shared/BakeryContracts")
return function(test,equal,near)
	test("audio edits wait through busy transactions and retry until acknowledged",function()
		local sent,blocked,server={},true,nil
		local delivery
		delivery=Delivery.new(function(payload)
			table.insert(sent,payload)
			if not blocked then server=payload; delivery:Acknowledge(payload.Revision) end
		end)
		delivery:Queue({music=false,musicVolume=.15,effects=true,effectsVolume=.8},0)
		delivery:Step(.39,true); equal(#sent,0)
		delivery:Step(.4,false); equal(#sent,0)
		delivery:Step(.41,true); equal(#sent,1); assert(delivery.pending)
		delivery:Step(.8,true); equal(#sent,1)
		blocked=false
		delivery:Step(1.42,true); equal(#sent,2); equal(delivery.pending,nil)
		equal(server.music,false); near(server.musicVolume,.15); near(server.effectsVolume,.8)
		delivery:Step(5,true); equal(#sent,2)
	end)
	test("rapid slider changes coalesce and an old acknowledgment cannot discard the final choice",function()
		local sent={}
		local delivery=Delivery.new(function(payload) table.insert(sent,payload) end)
		local input={musicVolume=.1}
		delivery:Queue(input,0); input.musicVolume=1
		delivery:Step(.41,true); near(sent[1].musicVolume,.1)
		local old=sent[1].Revision
		delivery:Queue({musicVolume=.2},.5)
		delivery:Queue({musicVolume=.8},.6)
		assert(not delivery:Acknowledge(old))
		delivery:Step(.99,true); equal(#sent,1)
		delivery:Step(1.01,true); equal(#sent,2); near(sent[2].musicVolume,.8)
		assert(delivery:Acknowledge(sent[2].Revision)); equal(delivery.pending,nil)
	end)
	test("menu snapshots reuse controls and replace purchase callbacks without duplicate listeners",function()
		local created=0
		local rows=Rows.new(function(kind,activate)
			created+=1
			return {kind=kind,activate=activate,Destroy=function(self) self.destroyed=true end}
		end)
		local bought=0
		assert(rows:Begin("Smith"))
		local pin=rows:Get("pin","Button",function() bought+=1 end)
		local name=rows:Get("name","Input"); name.Text="My typed bakery"
		rows:Finish()
		assert(not rows:Begin("Smith"))
		equal(rows:Get("pin","Button",function() bought+=10 end),pin)
		equal(rows:Get("name","Input"),name)
		rows:Finish()
		equal(created,2); equal(name.Text,"My typed bakery")
		pin.activate(); equal(bought,10) -- Uses only the latest action.
	end)
	test("menu reconciliation removes completed purchases and disposes rows when tabs change",function()
		local rows=Rows.new(function(kind,activate) return {kind=kind,activate=activate,Destroy=function(self) self.destroyed=true end} end)
		rows:Begin("Smith")
		local old=rows:Get("pin","Button",function() error("outdated purchase") end)
		local armor=rows:Get("armor","Button",function() end)
		rows:Finish()
		rows:Begin("Smith")
		local owned=rows:Get("pin","Label")
		rows:Finish()
		assert(old.destroyed and armor.destroyed and not owned.destroyed)
		equal(rows.records.armor,nil)
		rows:Begin("Bag"); rows:Finish(); assert(owned.destroyed); equal(next(rows.records),nil)
	end)
	test("valid obby completions advance quests despite stronger boosts and reward cooldowns",function()
		local data=Progression.newData()
		data.boosts.obbyBonus,data.boosts.obbyExpires=.5,87000
		data.life.cards.obbyClaims.Easy=86900
		data.life.contract=Contracts.normalize({kind="Obby",target=1,progress=0,reward=800})
		local completed,message,changed=Rewards.complete(data,"Easy",86400,false)
		assert(completed and changed); assert(message:find("stronger") and message:find("Quest"))
		equal(data.life.contract.progress,1); equal(data.life.cards.crumbs,0)
		equal(data.boosts.obbyExpires,87000); near(data.boosts.obbyBonus,.5)
		local _,_,again=Rewards.complete(data,"Easy",86401,false); equal(again,false)
	end)
	test("obby messages include the actual reward and a full crumb wallet consumes no cooldown",function()
		local data=Progression.newData()
		local complete,message,changed=Rewards.complete(data,"Medium",86400,false)
		assert(complete and changed); assert(message:find("35 Star Crumbs")); near(data.boosts.obbyBonus,.3)
		local before=data.life.cards.crumbs
		assert(not Rewards.complete(data,"Unknown",86400,false)); equal(data.life.cards.crumbs,before)
		local cards=Cards.normalize({crumbs=Cards.MaxCrumbs})
		equal(Cards.obby(cards,"Hard",86400,false),0); equal(cards.obbyClaims.Hard,0)
		cards.crumbs-=50
		equal(Cards.obby(cards,"Hard",86401,false),50)
	end)
end
