local Recipes = if script then require(script.Parent.Recipes) else require("./Recipes")
local Crafting = if script then require(script.Parent.CookieCrafting) else require("./CookieCrafting")
local Challenges = if script then require(script.Parent.Challenges) else require("./Challenges")
local Boosts = if script then require(script.Parent.Boosts) else require("./Boosts")

local Progression = {}
Progression.MAX_CASH = 1e15 -- Keep all currency integers below double precision limits.
Progression.MAX_CHIPS = 1000000000
Progression.MAX_REBIRTH_CASH = 100000000000 -- Cap prestige requirements at $100B for the late game.
Progression.MAX_OVEN_LEVEL = 15
Progression.MAX_REBIRTHS = 50
Progression.PermanentOrder = { "Yield", "Speed", "Starter" }
Progression.Permanent = {
	Yield = { Name = "Golden Batter", Max = 20, BaseCost = 3, StepCost = 2, Description = "+25% cookie income per level" },
	Speed = { Name = "Golden Flame", Max = 10, BaseCost = 4, StepCost = 3, Description = "+8% permanent baking speed per level" },
	Starter = { Name = "Golden Nest Egg", Max = 10, BaseCost = 2, StepCost = 2, Description = "Start each rebirth with $500 x level squared" },
}

local function integer(value, default, minimum, maximum)
	if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
		return default
	end
	return math.clamp(math.floor(value), minimum, maximum)
end

function Progression.newData()
	return {
		cash = 0, bank = 0, unlocked = 1, level = 1, rebirths = 0, chips = 0,
		permanent = { Yield = 0, Speed = 0, Starter = 0 }, modifiers = {},
		audio = { music = true, effects = true }, challenges = Challenges.normalize(nil), boosts = Boosts.normalize(nil),
	}
end

-- Returns a fresh, serializable copy. Runtime fields and unknown keys never enter a save.
function Progression.normalize(raw)
	local data = Progression.newData()
	if type(raw) ~= "table" then return data end
	data.cash = integer(raw.cash, 0, 0, Progression.MAX_CASH)
	data.bank = integer(raw.bank, 0, 0, Progression.MAX_CASH)
	data.unlocked = integer(raw.unlocked, 1, 1, #Recipes)
	data.level = integer(raw.level, 1, 1, Progression.MAX_OVEN_LEVEL)
	data.rebirths = integer(raw.rebirths, 0, 0, Progression.MAX_REBIRTHS)
	data.chips = integer(raw.chips, 0, 0, Progression.MAX_CHIPS)
	data.challenges = Challenges.normalize(raw.challenges)
	data.boosts = Boosts.normalize(raw.boosts)
	if type(raw.audio) == "table" then
		for key in pairs(data.audio) do
			if type(raw.audio[key]) == "boolean" then data.audio[key] = raw.audio[key] end
		end
	end
	if type(raw.permanent) == "table" then
		for key, upgrade in pairs(Progression.Permanent) do
			data.permanent[key] = integer(raw.permanent[key], 0, 0, upgrade.Max)
		end
	end
	if type(raw.modifiers) == "table" then
		for index = 1, data.unlocked do
			local recipeKey = tostring(index)
			local source = raw.modifiers[recipeKey]
			if type(source) == "table" then
				local flags = {}
				for _, key in ipairs(Crafting.ModifierOrder) do
					if source[key] == true then flags[key] = true end
				end
				if next(flags) then data.modifiers[recipeKey] = flags end
			end
		end
	end
	return data
end

function Progression.format(value)
	for _, unit in ipairs({ { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }) do
		if value >= unit[1] then return string.format("%.2f%s", value / unit[1], unit[2]) end
	end
	return tostring(math.floor(value))
end

function Progression.multiplier(data, perks)
	return (1 + data.permanent.Yield * 0.25) * (1 + data.rebirths * 0.15)
		* (perks and perks.DoubleIncome and 2 or 1)
		* Boosts.multiplier(data.boosts, perks and perks.Now or os.time())
end

function Progression.interval(data, perks)
	local normalInterval = math.max(0.4, 3 / ((1 + (data.level - 1) * 0.25) * (1 + data.permanent.Speed * 0.08)))
	return normalInterval / (perks and perks.DoubleSpeed and 2 or 1)
end

function Progression.recipeValue(data, index, perks)
	local flags = data.modifiers and data.modifiers[tostring(index)]
	return math.min(Progression.MAX_CASH, math.floor(Recipes[index].Value * Crafting.rarity(Recipes[index]).Multiplier
		* Crafting.multiplier(flags) * Progression.multiplier(data, perks)))
end

function Progression.batchValue(data, perks)
	local total = 0
	for index = 1, data.unlocked do total = math.min(Progression.MAX_CASH, total + Progression.recipeValue(data, index, perks)) end
	return total
end

function Progression.buyModifier(data, index, key)
	if type(index) ~= "number" or index ~= math.floor(index) or index < 1 or index > data.unlocked then
		return false, "Unlock that cookie recipe before decorating it."
	end
	if type(key) ~= "string" or not Crafting.Modifiers[key] then return false, "Unknown cookie modifier." end
	local recipeKey = tostring(index)
	local flags = data.modifiers and data.modifiers[recipeKey]
	if flags and flags[key] then return false, "This recipe already has " .. Crafting.Modifiers[key].Name .. "." end
	local cost = Crafting.cost(Recipes[index], key)
	if data.cash < cost then return false, "You need $" .. Progression.format(cost) .. " in your wallet for this modifier." end
	data.cash -= cost
	if not data.modifiers then data.modifiers = {} end
	if not flags then
		flags = {}
		data.modifiers[recipeKey] = flags
	end
	flags[key] = true
	return true, Crafting.Modifiers[key].Name .. " added to " .. Recipes[index].Name .. "!"
end

function Progression.ovenCost(data)
	return math.floor(500 * data.level * data.level * 1.6 ^ (data.level - 1))
end

function Progression.permanentCost(data, key)
	local upgrade = Progression.Permanent[key]
	if not upgrade or data.permanent[key] >= upgrade.Max then return nil end
	return upgrade.BaseCost + upgrade.StepCost * data.permanent[key]
end

function Progression.rebirthRequirement(data)
	return {
		Cash = math.min(Progression.MAX_REBIRTH_CASH, math.floor(5000000 * 2.5 ^ data.rebirths)),
		Recipes = math.min(#Recipes, 18 + data.rebirths * 2),
		Reward = 5 + data.rebirths * 2,
	}
end

function Progression.collect(data)
	local amount = math.min(data.bank, Progression.MAX_CASH - data.cash)
	data.cash += amount
	data.bank -= amount
	return amount
end

function Progression.buyRecipe(data)
	local recipe = Recipes[data.unlocked + 1]
	if not recipe then return false, "Every recipe is unlocked!" end
	if data.cash < recipe.Cost then return false, "Collect more cash to unlock " .. recipe.Name .. "." end
	data.cash -= recipe.Cost
	data.unlocked += 1
	return true, recipe.Name .. " is now baking!"
end

function Progression.upgradeOven(data)
	if data.level >= Progression.MAX_OVEN_LEVEL then return false, "Your ovens are at maximum level." end
	local cost = Progression.ovenCost(data)
	if data.cash < cost then return false, "You need $" .. Progression.format(cost) .. " in your wallet for this oven upgrade." end
	data.cash -= cost
	data.level += 1
	return true, "All ovens upgraded to level " .. data.level .. "!"
end

function Progression.buyPermanent(data, key)
	local cost = Progression.permanentCost(data, key)
	if not cost then return false, "That Golden Chip upgrade is unavailable or maxed." end
	if data.chips < cost then return false, "You need " .. cost .. " Golden Chips for this upgrade." end
	data.chips -= cost
	data.permanent[key] += 1
	return true, Progression.Permanent[key].Name .. " upgraded!"
end

function Progression.rebirth(data)
	if data.rebirths >= Progression.MAX_REBIRTHS then return false, "You have reached the rebirth cap!" end
	local requirement = Progression.rebirthRequirement(data)
	if data.unlocked < requirement.Recipes or data.cash + data.bank < requirement.Cash then
		return false, "Rebirth needs " .. requirement.Recipes .. " recipes and $" .. Progression.format(requirement.Cash) .. " in cash + uncollected earnings."
	end
	if data.chips + requirement.Reward > Progression.MAX_CHIPS then return false, "Spend some Golden Chips before rebirthing." end
	data.rebirths += 1
	data.chips += requirement.Reward
	data.cash = 500 * data.permanent.Starter ^ 2
	data.bank = 0
	data.unlocked = 1
	data.level = 1
	data.modifiers = {}
	return true, "Reborn! +" .. requirement.Reward .. " Golden Chips. Permanent upgrades are kept; recipe modifiers reset."
end

return Progression
