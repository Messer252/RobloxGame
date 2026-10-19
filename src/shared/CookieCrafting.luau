local Toppings = if script then require(script.Parent.RecipeToppings) else require("./RecipeToppings")
local Recipes = if script then require(script.Parent.Recipes) else require("./Recipes")
-- Fixed recipe tiers and cash-bought toppings. These definitions are shared by
-- the server economy, workshop UI, and cookie visuals; no random rolls are used.
local Crafting = {
	RarityOrder = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" },
	Rarities = {
		Common = { Name = "Common", Multiplier = 1, Color = { 209, 210, 218 } },
		Uncommon = { Name = "Uncommon", Multiplier = 1.25, Color = { 112, 221, 148 } },
		Rare = { Name = "Rare", Multiplier = 1.75, Color = { 105, 180, 255 } },
		Epic = { Name = "Epic", Multiplier = 2.5, Color = { 196, 134, 255 } },
		Legendary = { Name = "Legendary", Multiplier = 4, Color = { 255, 199, 75 } },
		Mythic = { Name = "Mythic", Multiplier = 6, Color = { 255, 111, 165 } },
	},
	ModifierOrder = { "Glaze", "Sprinkles", "ChocolateDrizzle", "CaramelSwirl", "GoldLeaf" },
	Modifiers = {
		Glaze = { Name = "Glaze", Bonus = 0.20, MinimumCost = 100, CostFactor = 0.25, Color = { 255, 244, 221 } },
		Sprinkles = { Name = "Sprinkles", Bonus = 0.35, MinimumCost = 350, CostFactor = 0.50, Color = { 255, 129, 177 } },
		ChocolateDrizzle = { Name = "Chocolate Drizzle", Bonus = 0.50, MinimumCost = 1000, CostFactor = 0.90, Color = { 83, 43, 29 } },
		CaramelSwirl = { Name = "Caramel Swirl", Bonus = 0.75, MinimumCost = 3000, CostFactor = 1.50, Color = { 225, 153, 59 } },
		GoldLeaf = { Name = "Gold Leaf", Bonus = 1.20, MinimumCost = 12500, CostFactor = 3, Color = { 255, 210, 78 } },
	},
}

function Crafting.rarity(recipe)
	return Crafting.Rarities[recipe.Rarity] or Crafting.Rarities.Common
end

function Crafting.option(recipe, key)
	local index = type(recipe) == "number" and recipe or table.find(Recipes, recipe)
	local slot = key == "Glaze" and 1 or key == "Sprinkles" and 2 or nil
	if not index or not slot then return nil end
	local item = Toppings[index][slot]
	return { Name = item[1], Bonus = item[2], Style = item[3], MinimumCost = slot == 1 and 100 or 350, CostFactor = slot == 1 and 0.25 or 0.5, Color = Recipes[index].Accent }
end
function Crafting.cost(recipe, key)
	local modifier = Crafting.option(recipe, key)
	if not modifier then return nil end
	return modifier.MinimumCost + math.floor(recipe.Cost * modifier.CostFactor)
end

function Crafting.multiplier(flags, recipe)
	local bonus = 0
	for _, key in ipairs(Crafting.ModifierOrder) do
		local definition = recipe and Crafting.option(recipe, key) or (not recipe and Crafting.Modifiers[key] or nil)
		if definition and flags and flags[key] == true then bonus += definition.Bonus end
	end
	return 1 + bonus -- Add topping bonuses, then multiply with rarity and income boosts.
end

function Crafting.encode(flags)
	local mask = 0
	for index, key in ipairs(Crafting.ModifierOrder) do
		if flags and flags[key] == true then mask += 2 ^ (index - 1) end
	end
	return mask
end

function Crafting.decode(mask)
	local flags = {}
	if type(mask) ~= "number" or mask ~= mask or math.abs(mask) == math.huge then return flags end
	mask = math.clamp(math.floor(mask), 0, 2 ^ #Crafting.ModifierOrder - 1)
	for index, key in ipairs(Crafting.ModifierOrder) do
		if bit32.band(mask, 2 ^ (index - 1)) ~= 0 then flags[key] = true end
	end
	return flags
end

function Crafting.summary(flags, recipe)
	local names = {}
	for _, key in ipairs(Crafting.ModifierOrder) do
		local definition = recipe and Crafting.option(recipe, key) or (not recipe and Crafting.Modifiers[key] or nil)
		if definition and flags and flags[key] == true then table.insert(names, definition.Name) end
	end
	return #names == 0 and "Plain" or table.concat(names, " + ")
end

return Crafting
