local P=require("../src/shared/Progression")
local Life=require("../src/shared/BakeryLife")
local Earnings=require("../src/shared/Earnings")
local Rewards=require("../src/shared/PurchaseRewards")
local Wild=require("../src/shared/WildernessRules")
local Prizes=require("../src/shared/WildernessRewards")
local Recipes=require("../src/shared/Recipes")
local Preview=require("../src/shared/PreviewCatalog")
local Shape=require("../src/shared/TerrainShape")
local Map=require("../src/shared/MapLayout")
local Town=require("../src/shared/TownCatalog")
local Obbys=require("../src/shared/ObbyCatalog")
local Contracts=require("../src/shared/BakeryContracts")
local Challenges=require("../src/shared/Challenges")
local Admin=require("../src/server/AdminRewards")
return function(test,equal,near,harness,fakeStore)
 test("lifetime earnings survive spending and rebirth; collecting never earns twice",function()
  local p=P.newData()
  assert(Rewards.cash(p,100000000,P.MAX_CASH))
  Earnings.record(p,250); p.bank+=250
  equal(p.lifetimeCash,100000250)
  assert(P.buyRecipe(p)); local total=p.lifetimeCash
  equal(P.collect(p),250); equal(p.lifetimeCash,total)
  p.unlocked=30; p.permanent.Starter=2
  assert(P.rebirth(p)); equal(p.cash,2000); equal(p.lifetimeCash,total+2000)
  equal(P.normalize(p).lifetimeCash,p.lifetimeCash)
 end)
 test("legacy earnings migrate wallet plus register once without inventing spent history",function()
  local p=P.normalize({cash=850,bank=150,rebirths=70})
  equal(p.lifetimeCash,1000); equal(p.rebirths,70)
  p.cash=0; p.bank=0
  equal(P.normalize(p).lifetimeCash,1000)
  equal(P.normalize({cash=100,bank=20,lifetimeCash=5000}).lifetimeCash,5000)
  equal(P.normalize({cash=100,bank=20,lifetimeCash=0/0}).lifetimeCash,120)
 end)
 test("late rebirth costs and income keep growing beyond fifty and save at large values",function()
  local p=P.newData()
  for _,n in ipairs({11,49,50,100,500,1000}) do
   p.rebirths=n
   local cost,value=P.rebirthRequirement(p).Cash,P.recipeValue(p,1)
   p.rebirths+=1
   local nextCost,nextValue=P.rebirthRequirement(p).Cash,P.recipeValue(p,1)
   assert(nextCost>cost and nextValue>value)
   near(nextCost/cost,1.16,1e-8)
   assert(nextCost/cost>nextValue/value)
  end
  p.rebirths=50; p.unlocked=30; p.bank=P.rebirthRequirement(p).Cash
  assert(P.rebirth(p)); equal(p.rebirths,51)
  p.rebirths=1000; p.cash=1e120; p.bank=1e121; p.lifetimeCash=1e200
  local restored=P.normalize(p)
  equal(restored.cash,p.cash); equal(restored.lifetimeCash,p.lifetimeCash); equal(restored.rebirths,1000)
  for _,n in ipairs({5000,1000000000}) do
   p.rebirths=n; p.cash=P.MAX_CASH; p.bank=P.MAX_CASH
   local req=P.rebirthRequirement(p)
   assert(req.Cash==req.Cash and req.Cash<math.huge and req.Reward<math.huge)
   assert(P.batchValue(p)<math.huge)
  end
 end)
 test("large lifetime totals encode into sortable finite integer leaderboard scores",function()
  local last=-1
  for _,n in ipairs({0,1,100,1e12,1e12+100,1e15,1e50,1e100,1e200,1e300}) do
   local score=Earnings.score(n)
   assert(score>last and score%1==0 and score<2^53)
   local decoded=Earnings.decode(score)
   if n>0 then assert(math.abs(decoded/n-1)<1e-10) else equal(decoded,0) end
   last=score
  end
  equal(Earnings.score(0/0),nil); equal(Earnings.score(math.huge),nil)
  local p=P.newData(); p.lifetimeCash=1e300; Earnings.record(p,1e300)
  equal(p.lifetimeCash,1e300)
 end)
 test("mine movement upgrades stack with cookies and all bought mine levels reset on rebirth",function()
  local p=P.newData(); p.life.dough=100000
  for _,key in ipairs(Life.DoughOrder) do
   assert(Life.upgradeDough(p,key)); equal(p.life.upgrades[key],1)
  end
  equal(Life.speed(p.life,100),1); equal(Life.jump(p.life,100),.5)
  Life.add(p.life,{id="food",recipe=1}); assert(Life.eat(p.life,"food",100,1))
  assert(Life.speed(p.life,101)>1)
  local dough=p.life.dough
  p.unlocked=30; p.cash=P.rebirthRequirement(p).Cash
  assert(P.rebirth(p))
  for _,key in ipairs(Life.DoughOrder) do equal(p.life.upgrades[key],0) end
  equal(p.life.dough,dough); equal(Life.speed(p.life,101),0); equal(Life.jump(p.life,101),0)
 end)
 test("purchase preview allowlist covers every gear tier, recipe and pack without accepting arbitrary models",function()
  for i=1,13 do assert(Preview.resolve("Pin:"..i)); assert(Preview.resolve("Armor:"..i)) end
  for i=1,30 do assert(Preview.resolve("Oven:"..i)); assert(Preview.resolve("Cookie:"..i)) end
  for i=1,5 do assert(Preview.resolve("Pack:"..i)) end
  for _,key in ipairs({"Decoration:Door","Decoration:Roof","Machine:Packager","Prop:RebirthPedestal"}) do assert(Preview.resolve(key)) end
  for _,key in ipairs({"Pin:0","Pin:99","Pin:01","Cookie:NaN","Pack:6","Prop:Script","Decoration:Unknown",string.rep("x",100)}) do equal(Preview.resolve(key),nil) end
  equal(Preview.resolve({}),nil)
 end)
 test("night boundary and wilderness zones protect tycoons, market, roads and obbys",function()
  assert(Wild.night(18)); assert(Wild.night(0)); assert(Wild.night(5.99))
  assert(not Wild.night(6)); assert(not Wild.night(17.99))
  local zones=table.clone(Wild.Zones); table.insert(zones,Wild.bossZone())
  for _,z in ipairs(zones) do
   for slot=1,8 do
    local p=Map.plot(slot)
    local dx,dz=math.max(0,math.abs(z.x-p.x)-82),math.max(0,math.abs(z.z-p.z)-122)
    assert(dx*dx+dz*dz>(z.radius+5)^2)
   end
   for angle=0,359 do
    local x,y=z.x+math.cos(math.rad(angle))*z.radius,z.z+math.sin(math.rad(angle))*z.radius
    assert(not Obbys.inPit(x,y,10)); assert(not Town.onRoad(x,2,y))
    assert(not Town.near(Town.PackStand,x,2,y)); assert(not Town.near(Town.Blacksmith,x,2,y))
   end
  end
  local b=Wild.bossZone()
  for x=b.x-b.radius,b.x+b.radius,4 do for z=b.z-b.radius,b.z+b.radius,4 do
   if Wild.inside(x,z,b) then assert(Shape.height(x,z)<0); assert(not Shape.grassAllowed(x,z)) end
  end end
  equal(Wild.BossInterval,1800)
 end)
 test("boss awards use actual damage, reject tag farming and cannot gain credit from overkill",function()
  local r={boss=true,hp=1000,maximum=1000,damage={},cashPool=2000000,doughPool=400,crumbPool=30}
  equal(Wild.hit(r,1,0/0),0); equal(Wild.hit(r,1,-1),0); equal(Wild.hit(r,1,math.huge),0)
  Wild.hit(r,1,5); Wild.hit(r,2,300)
  equal(Wild.reward(r,2),nil)
  equal(Wild.hit(r,3,999999),695)
  equal(Wild.hit(r,1,100),0); equal(Wild.reward(r,1),nil)
  local a,b=Wild.reward(r,2),Wild.reward(r,3)
  equal(a.cash,600000); equal(b.cash,1390000)
  assert(a.dough<b.dough and a.crumbs<b.crumbs)
  equal(Wild.reward(r,4),nil)
 end)
 test("night cookie drops are twenty percent and never exceed rare",function()
  local counts={Common=0,Uncommon=0,Rare=0,none=0}
  for i=0,9999 do
   local drop=Wild.drop(i/10000,(i%100)/100)
   if drop then local rarity=Recipes[drop].Rarity; assert(counts[rarity]); counts[rarity]+=1 else counts.none+=1 end
  end
  equal(counts.none,8000); equal(counts.Rare,140); equal(counts.Uncommon,560); equal(counts.Common,1300)
 end)
 test("defeat rewards commit once across uncertain saves, collection and rejoin",function()
  local store=fakeStore(); local manager=harness(store); local p=assert(manager:Load(720,"beasts"))
  local reward={cash=10000,dough=20,crumbs=4,cookie=8}
  local function grant(data) return Prizes.grant(data,reward,"drop-720") end
  store.commitErrorsRemaining=3
  assert(not manager:GrantReceipt(p,"beast-720",1,grant))
  equal(store.records.Player_720.Data.lifetimeCash,10000)
  assert(manager:GrantReceipt(p,"beast-720",1,grant))
  equal(p.data.lifetimeCash,10000); equal(p.data.bank,10000); equal(p.data.cash,0)
  P.collect(p.data); equal(p.data.lifetimeCash,10000)
  assert(manager:GrantReceipt(p,"beast-720",1,grant)); equal(p.data.life.cards.crumbs,4)
  assert(manager:Save(p,true)); p=assert(manager:Load(720,"beasts-rejoin"))
  assert(manager:GrantReceipt(p,"beast-720",1,grant))
  equal(p.data.lifetimeCash,10000); equal(p.data.cash,10000); equal(p.data.bank,0); equal(#p.data.life.inventory,1)
 end)
 test("full bags turn monster cookie drops into dough without discarding cash or crumbs",function()
  local p=P.newData()
  for i=1,Life.capacity(p.life) do assert(Life.add(p.life,{id="stored"..i,recipe=1})) end
  local count=#p.life.inventory
  Prizes.grant(p,{cash=500,dough=8,crumbs=1,cookie=1},"newdrop")
  equal(#p.life.inventory,count); equal(p.life.dough,13); equal(p.bank,500); equal(p.life.cards.crumbs,1)
 end)
 test("quest and admin cash awards increase lifetime but chip grants and failed awards do not",function()
  local p=P.newData()
  assert(Admin.grant(p,"GiveWalletCash",100,1000)); assert(Admin.grant(p,"GiveBankCash",200,1000))
  equal(p.lifetimeCash,300)
  assert(Admin.grant(p,"GiveGoldenChips",2,1000)); equal(p.lifetimeCash,300)
  assert(not Admin.grant(p,"GiveBankCash",-100,1000)); equal(p.lifetimeCash,300)
  assert(Challenges.interact(p,P.MAX_CASH))
  local catalog=require("../src/shared/ChallengeCatalog")
  for _,id in ipairs(catalog.Challenges[p.challenges.index].Items) do p.challenges.found[id]=true end
  local before=p.cash+p.bank
  assert(Challenges.interact(p,P.MAX_CASH))
  equal(p.lifetimeCash,300+p.cash+p.bank-before)
  local total=p.lifetimeCash
  Contracts.assign(p,100,0,0,0)
  p.life.contract.progress=p.life.contract.target
  local prize=p.life.contract.reward
  assert(Contracts.interact(p,200,0,0,0))
  equal(p.lifetimeCash,total+prize)
 end)
end
