local Catalog = if script then require(script.Parent.CardCatalog) else require("./CardCatalog")
local Town = if script then require(script.Parent.TownCatalog) else require("./TownCatalog")
local Cards = { MaxCrumbs = 1e9 }
local function integer(n, fallback, cap)
	return type(n) == "number" and n == n and math.abs(n) < math.huge and math.clamp(math.floor(n), 0, cap) or fallback
end
function Cards.normalize(raw)
	raw = type(raw) == "table" and raw or {}
	local result = { crumbs = integer(raw.crumbs, 0, Cards.MaxCrumbs), owned = {}, equipped = {}, milestone = integer(raw.milestone, 0, 1e9), daily = integer(raw.daily, 0, 4102444800), dailyEarned = integer(raw.dailyEarned, 0, 600), lastCard = integer(raw.lastCard, 0, #Catalog.Cards) }
	result.claimDay, result.pickupDay = integer(raw.claimDay,0,4102444800),integer(raw.pickupDay,0,4102444800)
	result.pickupEarned, result.pickups, result.obbyClaims = integer(raw.pickupEarned,0,Town.PickupDailyCap),{},{}
	for id=1,#Town.Pickups do result.pickups[tostring(id)]=integer(type(raw.pickups)=="table" and raw.pickups[tostring(id)],0,4102444800) end
	for _,key in ipairs({"Easy","Medium","Hard"}) do result.obbyClaims[key]=integer(type(raw.obbyClaims)=="table" and raw.obbyClaims[key],0,4102444800) end
	for id = 1, #Catalog.Cards do
		local n = integer(type(raw.owned) == "table" and raw.owned[tostring(id)], 0, 999)
		if n > 0 then result.owned[tostring(id)] = n end
	end
	if type(raw.equipped) == "table" then for _, id in ipairs(raw.equipped) do
		if Catalog.Cards[id] and result.owned[tostring(id)] and not table.find(result.equipped, id) and #result.equipped < 3 then table.insert(result.equipped, id) end
	end end
	return result
end
function Cards.bonuses(data, third)
	local bonus = { Cash = 1, Speed = 1, Sales = 1, Crumbs = 1, Mine = 0 }
	for slot, id in ipairs(data.equipped) do
		if slot <= (third and 3 or 2) and data.owned[tostring(id)] then
			for stat, amount in pairs(Catalog.Cards[id].Effects) do bonus[stat] += amount end
		end
	end
	return bonus
end
function Cards.equip(data, id, third)
	if type(id) ~= "number" or not Catalog.Cards[id] or not data.owned[tostring(id)] then return false, "You do not own that card." end
	local index = table.find(data.equipped, id)
	if index then table.remove(data.equipped, index); return true, "Card unequipped." end
	if #data.equipped >= (third and 3 or 2) then return false, "Unequip a card first. Two slots are free." end
	table.insert(data.equipped, id)
	return true, "Card equipped! Bonuses apply to your claimed bakery."
end
function Cards.roll(packId, rarityRoll, cardRoll)
	local pack = Catalog.Packs[packId]
	if not pack or type(rarityRoll) ~= "number" or rarityRoll ~= rarityRoll or rarityRoll < 0 or rarityRoll >= 1 or type(cardRoll) ~= "number" or cardRoll ~= cardRoll or cardRoll < 0 or cardRoll >= 1 then return nil end
	local running, rarity = 0, nil
	for index, weight in ipairs(pack.Weights) do running += weight; if rarityRoll * 10000 < running then rarity = Catalog.Rarities[index]; break end end
	local pool = {}
	for id, card in ipairs(Catalog.Cards) do if card.Rarity == rarity then table.insert(pool, id) end end
	return pool[math.floor(cardRoll * #pool) + 1]
end
function Cards.open(data, packId, cardId)
	local pack, card = Catalog.Packs[packId], Catalog.Cards[cardId]
	if not pack or not card then return false, "Unknown pack." end
	local rarity = table.find(Catalog.Rarities, card.Rarity)
	if not rarity or pack.Weights[rarity] <= 0 then return false, "That card is not in this pack." end
	if data.crumbs < pack.Cost then return false, "Earn more Star Crumbs first." end
	local count = data.owned[tostring(cardId)] or 0
	if count >= 999 then return false, "Card storage limit reached; no crumbs spent." end
	data.crumbs -= pack.Cost
	data.owned[tostring(cardId)], data.lastCard = count + 1, cardId
	return true, card.Name .. " • " .. card.Rarity
end
function Cards.award(data, amount, third)
	local gain = math.max(0, math.floor(amount * Cards.bonuses(data, third).Crumbs))
	local actual = math.min(Cards.MaxCrumbs - data.crumbs, gain)
	data.crumbs += actual
	return actual
end
function Cards.claimDaily(data, now, third)
	local day=math.floor(now/86400)
	if data.claimDay>=day then return false,"Come back tomorrow for another daily pack allowance." end
	if data.crumbs>=Cards.MaxCrumbs then return false,"Spend some Star Crumbs first." end
	data.claimDay=day
	return true,Cards.award(data,Town.DailyCrumbs,third)
end
function Cards.pickup(data,id,now,third)
	if type(id)~="number" or id%1~=0 or not Town.Pickups[id] then return false,"Unknown crumb." end
	local key,day=tostring(id),math.floor(now/86400)
	if data.pickupDay~=day then data.pickupDay,data.pickupEarned=day,0 end
	if data.pickups[key]>now then return false,"This crumb is resting. Try another trail." end
	if data.pickupEarned>=Town.PickupDailyCap then return false,"Trail limit reached today. Jobs, ore, meteors and the hill still pay." end
	if data.crumbs>=Cards.MaxCrumbs then return false,"Spend some Star Crumbs first." end
	local base=math.min(Town.PickupCrumbs,Town.PickupDailyCap-data.pickupEarned)
	data.pickups[key],data.pickupEarned=now+Town.PickupCooldown,data.pickupEarned+base
	return true,Cards.award(data,base,third)
end
function Cards.obby(data,difficulty,now,third)
	local reward=({Easy=20,Medium=35,Hard=50})[difficulty]
	if not reward or (data.obbyClaims[difficulty] or 0)>now or data.crumbs>=Cards.MaxCrumbs then return 0 end
	data.obbyClaims[difficulty]=now+300
	return Cards.award(data,reward,third)
end
-- Only active bakery production calls this. Cap this source at 600 crumbs/day;
-- meteors, jobs and contested hill rewards remain independent.
function Cards.production(data, now, third)
	local day = math.floor(now / 86400)
	if data.daily ~= day then data.daily, data.dailyEarned = day, 0 end
	data.milestone += 1
	if data.milestone % 60 ~= 0 or data.dailyEarned >= 600 then return 0 end
	local reward = math.min(10, 600 - data.dailyEarned)
	data.dailyEarned += reward
	return Cards.award(data, reward, third)
end
return Cards
