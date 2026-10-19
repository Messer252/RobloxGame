local Catalog = require("../src/shared/CardCatalog")
local Cards = require("../src/shared/CardEconomy")
local Events = require("../src/shared/ValleyEvents")
local Shape = require("../src/shared/TerrainShape")
local Progression = require("../src/shared/Progression")
local Life = require("../src/shared/BakeryLife")
local Crafting = require("../src/shared/CookieCrafting")
local Recipes = require("../src/shared/Recipes")
local Polish = require("../src/shared/BakeryPolish")
local Layout = require("../src/shared/ConveyorLayout")
return function(test, equal, near, harness, fakeStore)
	test("forty unique animal cards match rarity counts and each has a distinct useful buff", function()
		local counts, names, signatures = {}, {}, {}
		for id, card in ipairs(Catalog.Cards) do
			equal(card.Id, id); assert(not names[card.Name]); names[card.Name] = true
			counts[card.Rarity] = (counts[card.Rarity] or 0) + 1
			assert(#card.Quip > 15 and #card.Animal > 2)
			local key = ""
			for _, stat in ipairs({ "Cash", "Speed", "Sales", "Crumbs", "Mine" }) do
				local n = card.Effects[stat] or 0
				assert(n >= 0 and n <= (stat == "Mine" and 15 or .75)); key ..= ":" .. n
			end
			assert(not signatures[key], card.Name); signatures[key] = true
		end
		equal(#Catalog.Cards, 40)
		for rarity, count in pairs({Common=15,Uncommon=10,Rare=7,Legendary=3,Mythical=5}) do equal(counts[rarity], count) end
	end)
	test("five pack distributions total exactly 100 percent and high-rarity odds increase", function()
		local lastPrice, lastTop = 0, -1
		for _, pack in ipairs(Catalog.Packs) do
			local total = 0
			for _, n in ipairs(pack.Weights) do assert(n >= 0 and n % 1 == 0); total += n end
			equal(total, 10000); assert(pack.Cost > lastPrice)
			assert(pack.Weights[4] + pack.Weights[5] > lastTop)
			lastPrice, lastTop = pack.Cost, pack.Weights[4] + pack.Weights[5]
		end
	end)
	test("every exact rarity roll maps to the published odds, including zero-weight rarities", function()
		for packId, pack in ipairs(Catalog.Packs) do
			local count = {}
			for roll = 0, 9999 do
				local id = assert(Cards.roll(packId, (roll+.5)/10000, .999))
				local rarity = Catalog.Cards[id].Rarity
				count[rarity] = (count[rarity] or 0) + 1
			end
			for i, rarity in ipairs(Catalog.Rarities) do equal(count[rarity] or 0, pack.Weights[i]) end
		end
		equal(Cards.roll(9, .1, .1), nil); equal(Cards.roll(1, 1, .1), nil)
	end)
	test("pack charges and one card grant save atomically and survive a lost response", function()
		local store = fakeStore()
		local manager = harness(store)
		local profile = assert(manager:Load(9100, "packs"))
		profile.data.life.cards.crumbs = 500
		assert(manager:Save(profile))
		store.commitErrorsRemaining = 3
		local function grant(data) return Cards.open(data.life.cards, 2, 33) end
		assert(not manager:GrantReceipt(profile, "cp:test", 1, grant))
		assert(profile.transacting)
		assert(manager:GrantReceipt(profile, "cp:test", 1, grant))
		equal(profile.data.life.cards.crumbs, 150)
		equal(profile.data.life.cards.owned["33"], 1)
		assert(manager:GrantReceipt(profile, "cp:test", 1, grant))
		equal(profile.data.life.cards.owned["33"], 1)
		assert(manager:Save(profile, true))
		profile = assert(manager:Load(9100, "after-pack"))
		equal(profile.data.life.cards.crumbs, 150); equal(profile.data.life.cards.lastCard, 33)
	end)
	test("insufficient pack currency and full duplicate storage never remove crumbs", function()
		local data = Cards.normalize(nil)
		data.crumbs = 99
		assert(not Cards.open(data, 1, 1)); equal(data.crumbs, 99)
		data.crumbs, data.owned["1"] = 1000, 999
		assert(not Cards.open(data, 1, 1)); equal(data.crumbs, 1000)
		assert(not Cards.open(data, 99, 1)); assert(not Cards.open(data, 1, 99))
	end)
	test("two free equip slots reject unknown cards and a third requires verified entitlement", function()
		local data = Cards.normalize({owned={["1"]=2,["2"]=1,["33"]=1}})
		assert(Cards.equip(data,1,false)); assert(Cards.equip(data,2,false))
		assert(not Cards.equip(data,33,false)); assert(not Cards.equip(data,40,true))
		assert(Cards.equip(data,33,true))
		near(Cards.bonuses(data,false).Cash, 1.05)
		near(Cards.bonuses(data,true).Cash, 1.5)
		assert(Cards.equip(data,1,true)); equal(#data.equipped,2)
		local fixed = Cards.normalize({owned={["1"]=1},equipped={1,1,33}})
		equal(#fixed.equipped,1)
	end)
	test("rebirth clears cookies, conveyor, machines, decorations and food but retains cards and crumbs", function()
		local p = Progression.newData()
		p.cash, p.unlocked = 1e8, 30
		Life.add(p.life,{id="before-rebirth",recipe=30})
		p.life.belt, p.life.machines.Packager, p.life.decorations.Roof = 3,true,true
		p.life.buff = {recipe=30,expires=300,seed=1}
		p.life.cards = Cards.normalize({crumbs=456,owned={["33"]=1},equipped={33}})
		assert(Progression.rebirth(p))
		equal(#p.life.inventory,0); equal(p.life.belt,0); equal(p.life.machines.Packager,false)
		equal(p.life.decorations.Roof,false); equal(p.life.buff.expires,0)
		equal(p.life.cards.crumbs,456); equal(p.life.cards.owned["33"],1); equal(p.life.cards.equipped[1],33)
		local restored = Progression.normalize(p)
		equal(restored.life.belt,0); equal(#restored.life.inventory,0); equal(restored.life.cards.crumbs,456)
	end)
	test("bakery milestone rewards have a daily cap and reset on the next UTC day", function()
		local data = Cards.normalize(nil)
		for i=1,120*35 do Cards.production(data,86400,false) end
		equal(data.crumbs,300); equal(data.dailyEarned,300)
		for i=1,120 do Cards.production(data,172800,false) end
		equal(data.crumbs,310); equal(data.dailyEarned,10)
	end)
	test("meteors wait five to thirty minutes and base rewards buy a common to uncommon pack", function()
		equal(Events.meteorDelay(0),300); equal(Events.meteorDelay(1),1800)
		equal(Events.meteorReward(0),Catalog.Packs[1].Cost)
		equal(Events.meteorReward(1),Catalog.Packs[2].Cost)
	end)
	test("hill bounds exclude nearby roads, airborne players, and distant characters", function()
		assert(Events.onHill(-285,11,400))
		assert(not Events.onHill(-285,30,400)); assert(not Events.onHill(0,11,400))
		assert(not Events.onHill(-250,11,400)); assert(not Events.onHill(-285,0,400))
		assert(Events.damage(5,14,.3)<Events.damage(5,14,0))
		equal(Events.damage(5,14,1),Events.damage(5,14,.45))
	end)
	test("each recipe has only two signature toppings and removed universal coatings cannot be purchased", function()
		for index, recipe in ipairs(Recipes) do
			local a,b = assert(Crafting.option(index,"Glaze")), assert(Crafting.option(index,"Sprinkles"))
			assert(a.Name~=b.Name and a.Bonus>0 and b.Bonus>0)
			local p=Progression.newData(); p.cash,p.unlocked=1e15,30
			assert(Progression.buyModifier(p,index,"Glaze")); assert(Progression.buyModifier(p,index,"Sprinkles"))
			assert(not Progression.buyModifier(p,index,"GoldLeaf"))
			near(Crafting.multiplier(p.modifiers[tostring(index)],index),1+a.Bonus+b.Bonus)
			assert(Crafting.cost(recipe,"Sprinkles")>Crafting.cost(recipe,"Glaze"))
		end
		near(Crafting.option(1,"Glaze").Bonus,.2); near(Crafting.option(3,"Glaze").Bonus,.1)
	end)
	test("window door roof and light prerequisites charge only after their supports exist", function()
		local p=Progression.newData(); p.cash=1e6
		assert(not Polish.buyDecoration(p,"Door")); equal(p.cash,1e6)
		assert(Polish.buyDecoration(p,"Walls")); assert(Polish.buyDecoration(p,"Door"))
		assert(not Polish.buyDecoration(p,"Lights")); assert(Polish.buyDecoration(p,"Roof")); assert(Polish.buyDecoration(p,"Lights"))
	end)
	test("spawn and first oven face the road on both mirrored sides", function()
		for _, origin in ipairs({-98,98}) do
			local mirror=origin<0 and 1 or -1
			local spawn=origin+Layout.SpawnX*mirror
			local claim=origin+77*mirror
			local collector=origin+64*mirror
			assert(math.abs(spawn)<40 and math.abs(claim)<30 and math.abs(collector)<40)
			equal(Layout.station(1).lane,1); assert(Layout.station(1).laneX>0)
		end
	end)
	test("natural terrain forms a continuous height field and snow never needs floating geometry", function()
		for x=-1000,1000,25 do for z=-1200,1200,25 do
			local h=Shape.height(x,z)
			assert(h==h and h>-10 and h<400)
			assert(math.abs(h-Shape.height(x+1,z))<5)
			if Shape.snow(x,z,h) then assert(h>130) end
		end end
		assert(Shape.lake(-285,-370)); assert(not Shape.lake(0,0))
		near(Shape.height(0,0),-.6)
	end)
end
