local Earnings = if script then require(script.Parent.Earnings) else require("./Earnings")
local Catalog = if script then require(script.Parent.ChallengeCatalog) else require("./ChallengeCatalog")
local Contracts = {}
Contracts.Kinds = { "Mine", "Sell", "Eat", "Gift", "Bake", "Obby", "Find" }
Contracts.Titles = { Mine = "Dough for the bakery", Sell = "Customer service", Eat = "Taste tester", Gift = "Share something sweet", Bake = "Production shift", Obby = "Baker's agility", Find = "Lost supplies" }
local function integer(v, fallback, maximum)
	return type(v) == "number" and v == v and math.abs(v) < math.huge and math.clamp(math.floor(v), 0, maximum) or fallback
end
function Contracts.normalize(raw)
	raw = type(raw) == "table" and raw or {}
	local state = { cycle = integer(raw.cycle, 0, 1e9), kind = table.find(Contracts.Kinds, raw.kind) and raw.kind or "",
		target = integer(raw.target, 0, 100), progress = integer(raw.progress, 0, 100), reward = integer(raw.reward, 0, 2000000),
		items = {}, found = {}, assigned = integer(raw.assigned, 0, 4102444800), lastKind = table.find(Contracts.Kinds, raw.lastKind) and raw.lastKind or "" }
	if type(raw.items) == "table" then
		for _, id in ipairs(raw.items) do
			if Catalog.Items[id] and not table.find(state.items, id) and #state.items < 3 then table.insert(state.items, id) end
		end
	end
	if type(raw.found) == "table" then for _, id in ipairs(state.items) do if raw.found[id] == true then state.found[id] = true end end end
	if state.kind == "Find" then
		state.target, state.progress = #state.items, 0
		for _ in pairs(state.found) do state.progress += 1 end
	end
	state.progress = math.min(state.target, state.progress)
	return state
end
function Contracts.assign(data, now, kindRoll, targetRoll, itemRoll)
	local old = Contracts.normalize(data.life.contract)
	local index = math.clamp(math.floor(kindRoll * #Contracts.Kinds) + 1, 1, #Contracts.Kinds)
	if Contracts.Kinds[index] == old.lastKind then index = index % #Contracts.Kinds + 1 end
	local state = Contracts.normalize({ kind = Contracts.Kinds[index], lastKind = old.lastKind, cycle = old.cycle, assigned = now })
	local targets = { Mine = 2 + math.floor(targetRoll * 5), Sell = 1 + math.floor(targetRoll * 3), Eat = 1 + math.floor(targetRoll * 3), Gift = 1, Bake = 15 + math.floor(targetRoll * 45), Obby = 1, Find = 2 }
	state.target = targets[state.kind]
	state.reward = math.min(2000000, math.floor((800 + data.unlocked * 150) * (0.8 + targetRoll * 0.8)))
	if state.kind == "Find" then
		local ids = {}
		for id in pairs(Catalog.Items) do table.insert(ids, id) end
		table.sort(ids)
		local start = math.clamp(math.floor(itemRoll * #ids) + 1, 1, #ids)
		state.items = { ids[start], ids[(start + 4) % #ids + 1] }
	end
	data.life.contract = state
	return true, "New task: " .. Contracts.Titles[state.kind] .. ". Check Quests for details.", 0
end
function Contracts.record(data, kind, amount, item)
	local state = data.life.contract
	if not state or state.kind ~= kind or state.progress >= state.target then return false end
	if kind == "Find" then
		if not table.find(state.items, item) or state.found[item] then return false end
		state.found[item] = true
	end
	state.progress = math.min(state.target, state.progress + math.clamp(math.floor(amount or 1), 0, 100))
	return true
end
function Contracts.interact(data, now, kindRoll, targetRoll, itemRoll, skip)
	local state = data.life.contract
	if state.kind == "" then return Contracts.assign(data, now, kindRoll, targetRoll, itemRoll) end
	if state.progress < state.target then
		if skip then
			if now - state.assigned < 60 then return false, "Try this task for a minute before asking for a different one." end
			state.lastKind = state.kind
			return Contracts.assign(data, now, kindRoll, targetRoll, itemRoll)
		end
		return false, "Task progress: " .. state.progress .. "/" .. state.target .. ". Check Quests for details."
	end
	local room = math.max(0, Earnings.Limit - data.cash)
	if room + math.max(0, Earnings.Limit - data.bank) < state.reward then return false, "Make room for the reward first." end
	local reward = state.reward
	Earnings.record(data,reward)
	data.cash += math.min(room, reward)
	data.bank += math.max(0, reward - room)
	data.life.contract = Contracts.normalize({ cycle = state.cycle + 1, lastKind = state.kind })
	return true, "Task complete! +$" .. reward, reward
end
return Contracts
