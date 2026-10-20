local Recipes = if script then require(script.Parent.Recipes) else require("./Recipes")
local Crafting = if script then require(script.Parent.CookieCrafting) else require("./CookieCrafting")
local Polish = if script then require(script.Parent.BakeryPolish) else require("./BakeryPolish")
local Contracts = if script then require(script.Parent.BakeryContracts) else require("./BakeryContracts")
local Cards = if script then require(script.Parent.CardEconomy) else require("./CardEconomy")
local Life = { MaxCurrency = 1e15, MaxInventory = 40, OvenSeconds = 20 }
Life.Machines = { Packager = { Cost = 25000, Bonus = 0.25 }, Boxer = { Cost = 250000, Bonus = 0.5 }, FinishingOven = { Cost = 2500000, Bonus = 0 } }
Life.PinCosts = { 0, 5000, 50000, 500000, 5000000 }
Life.PinPower = { 1, 3, 7, 15, 30 }
Life.PinNames = { "Maple", "Copper", "Steel", "Gilded", "Starforged" }
Life.DoughUpgrades = { Mixing = { Max = 10, Cost = 25 }, Flow = { Max = 10, Cost = 30 }, Pockets = { Max = 5, Cost = 20 } }
local function integer(v, default, minimum, maximum)
	return type(v) == "number" and v == v and math.abs(v) < math.huge and math.clamp(math.floor(v), minimum, maximum) or default
end
function Life.cookie(raw)
	if type(raw) ~= "table" or type(raw.id) ~= "string" or #raw.id < 1 or #raw.id > 80 then return nil end
	if type(raw.recipe) ~= "number" or raw.recipe % 1 ~= 0 or not Recipes[raw.recipe] then return nil end
	return { id = raw.id, recipe = raw.recipe, mask = integer(raw.mask, 0, 0, 31),
		quality = integer(raw.quality, 0, 0, 10), baked = raw.baked == true, wrapped = raw.wrapped == true, boxed = raw.boxed == true }
end
function Life.sameCookie(a, b)
	a, b = Life.cookie(a), Life.cookie(b)
	if not a or not b then return false end
	for key, value in pairs(a) do if b[key] ~= value then return false end end
	return true
end
function Life.normalize(raw)
	raw = type(raw) == "table" and raw or {}
	local data = { inventory = {}, dough = integer(raw.dough, 0, 0, 1e9), pin = integer(raw.pin, 1, 1, 5),
		upgrades = {}, machines = {}, recipeLevels = {}, oven = {}, buff = { recipe = 1, expires = 0, seed = 1 }, pendingTrade = "", belt = integer(raw.belt, 0, 0, 3), decorations = {}, contract = Contracts.normalize(raw.contract), cards = Cards.normalize(raw.cards), shopName = type(raw.shopName) == "string" and string.sub(raw.shopName, 1, 60) or "" }
	data.armor=integer(raw.armor,0,0,5)
	for key in pairs(Polish.Decorations) do data.decorations[key] = type(raw.decorations) == "table" and raw.decorations[key] == true or false end
	local seen = {}
	if type(raw.inventory) == "table" then
		for _, v in ipairs(raw.inventory) do
			local cookie = Life.cookie(v)
			if cookie and not seen[cookie.id] and #data.inventory < Life.MaxInventory then
				seen[cookie.id] = true
				table.insert(data.inventory, cookie)
			end
		end
	end
	for key, definition in pairs(Life.DoughUpgrades) do data.upgrades[key] = integer(type(raw.upgrades) == "table" and raw.upgrades[key], 0, 0, definition.Max) end
	for key in pairs(Life.Machines) do data.machines[key] = type(raw.machines) == "table" and raw.machines[key] == true or false end
	for i = 1, #Recipes do data.recipeLevels[tostring(i)] = integer(type(raw.recipeLevels) == "table" and raw.recipeLevels[tostring(i)], 0, 0, 10) end
	if type(raw.oven) == "table" and seen[raw.oven.id] then data.oven = { id = raw.oven.id, ready = integer(raw.oven.ready, 0, 0, 4102444800) } end
	if type(raw.buff) == "table" then data.buff = { recipe = integer(raw.buff.recipe, 1, 1, #Recipes), expires = integer(raw.buff.expires, 0, 0, 4102444800), seed = integer(raw.buff.seed, 1, 1, 1000000) } end
	if type(raw.pendingTrade) == "string" and #raw.pendingTrade <= 80 then data.pendingTrade = raw.pendingTrade end
	return data
end
function Life.capacity(data) return 20 + data.upgrades.Pockets * 4 end
function Life.find(data, id)
	for i, cookie in ipairs(data.inventory) do if cookie.id == id then return cookie, i end end
	return nil
end
function Life.available(data, id)
	return data.pendingTrade == "" and data.oven.id ~= id and Life.find(data, id) ~= nil
end
function Life.value(cookie)
	local recipe = Recipes[cookie.recipe]
	return math.floor(recipe.Value * Crafting.rarity(recipe).Multiplier * Crafting.multiplier(Crafting.decode(cookie.mask), cookie.recipe)
		* (1 + (cookie.quality or 0) * 0.2) * (cookie.wrapped and 1.25 or 1) * (cookie.boxed and 1.5 or 1) * (cookie.baked and 3 or 1))
end
function Life.add(data, cookie)
	local valid = Life.cookie(cookie)
	if not valid or Life.find(data, valid.id) or #data.inventory >= Life.capacity(data) then return false, "Your cookie bag is full or this cookie is already stored." end
	table.insert(data.inventory, valid)
	return true
end
function Life.remove(data, id)
	local cookie, index = Life.find(data, id)
	if not cookie then return nil end
	table.remove(data.inventory, index)
	return cookie
end
function Life.eat(data, id, now, seed)
	if not Life.available(data, id) then return false, "That cookie is busy or missing." end
	local cookie = Life.remove(data, id)
	data.buff = { recipe = cookie.recipe, expires = now + 90, seed = seed }
	return true, "Yum! Cookie look and speed boost for 90 seconds."
end
function Life.speed(data, now)
	return Polish.active(data, now).Speed
end
function Life.production(data, now)
	return (1 + Polish.active(data, now or os.time()).Income / 100) * (1 + data.upgrades.Mixing * 0.1) * (data.machines.Packager and 1.25 or 1) * (data.machines.Boxer and 1.5 or 1)
end
function Life.process(cookie, machines, z)
	local changed = false
	if machines.Packager and z >= Polish.WrapZ and not cookie.wrapped then cookie.wrapped, changed = true, true end
	if machines.Boxer and z >= Polish.BoxZ and not cookie.boxed then cookie.boxed, changed = true, true end
	return changed
end
function Life.buyMachine(profile, key)
	local definition = Life.Machines[key]
	if not definition or profile.life.machines[key] then return false, "Machine unavailable or already owned." end
	if not Life.machineAvailable(profile.life,key) then return false,"Build a conveyor, then unlock the previous processing machine first." end
	if profile.cash < definition.Cost then return false, "Collect more wallet cash for this machine." end
	profile.cash -= definition.Cost
	profile.life.machines[key] = true
	return true, key .. " installed!"
end
function Life.machineAvailable(life,key)
	if not Life.Machines[key] or life.machines[key] or life.belt<1 then return false end
	return key=="Packager" or key=="Boxer" and life.machines.Packager or key=="FinishingOven" and life.machines.Boxer or false
end
function Life.upgradeRecipe(profile, index)
	if type(index) ~= "number" or index % 1 ~= 0 or not Recipes[index] or index > profile.unlocked then return false, "Unlock that recipe first." end
	local key = tostring(index)
	local level = profile.life.recipeLevels[key]
	if level >= 10 then return false, "Recipe mastered!" end
	local cost = Life.recipeCost(index, level)
	if profile.cash < cost then return false, "You need more wallet cash for this recipe upgrade." end
	profile.cash -= cost
	profile.life.recipeLevels[key] += 1
	return true, Recipes[index].Name .. " upgraded! +20% recipe income."
end
function Life.recipeCost(index, level) return math.floor((100 + Recipes[index].Cost * 0.35) * 1.7 ^ level) end
function Life.upgradeDough(profile, key)
	local definition = Life.DoughUpgrades[key]
	if not definition then return false, "Unknown dough upgrade." end
	local level = profile.life.upgrades[key]
	if level >= definition.Max then return false, "Dough upgrade maxed." end
	local cost = definition.Cost * 2 ^ level
	if profile.life.dough < cost then return false, "Mine more dough ore first." end
	profile.life.dough -= cost
	profile.life.upgrades[key] += 1
	return true, key .. " upgraded permanently!"
end
function Life.upgradePin(profile)
	local cost = Life.PinCosts[profile.life.pin + 1]
	if not cost then return false, "Best rolling pin owned!" end
	if profile.cash < cost then return false, "Collect more cash for a better rolling pin." end
	profile.cash -= cost
	profile.life.pin += 1
	return true, Life.PinNames[profile.life.pin] .. " rolling pin unlocked!"
end
function Life.startOven(profile, id, now)
	local data = profile.life
	if not data.machines.FinishingOven then return false, "Buy your $2.5M finishing oven first." end
	if data.oven.id then return false, "The finishing oven is busy." end
	if not Life.available(data, id) then return false, "Hold an available cookie first." end
	if Life.find(data, id).baked then return false, "This cookie has already been finished." end
	data.oven = { id = id, ready = now + Life.OvenSeconds }
	return true, "Finishing cookie: 20 seconds, then 3x inventory value."
end
function Life.finishOven(data, now)
	if not data.oven.id or now < data.oven.ready then return false end
	local cookie = Life.find(data, data.oven.id)
	if cookie then cookie.baked = true end
	data.oven = {}
	return cookie ~= nil
end
function Life.pitch(base, attempt, roll)
	if attempt >= 3 or roll < 0.15 + attempt * 0.2 then return false end
	return true, math.floor(base * (1.2 + (attempt + 1) * 0.2))
end
return Life
