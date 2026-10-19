-- Pure balance rules for the workshop update. All rolls originate on the server.
local Polish = {}
Polish.WrapZ, Polish.BoxZ = 118.5, 122
Polish.BeltCosts = { 0, 10000, 250000 }
Polish.Decorations = {
	Walls = { Cost = 2500, Name = "Brick walls" }, Windows = { Cost = 6000, Name = "Arched windows" },
	Door = { Cost = 4000, Name = "Bakery entrance" }, Plants = { Cost = 750, Name = "Potted plants" },
	Trees = { Cost = 1500, Name = "Cookie garden" },
}
-- Name, run speed, jump height, mining damage, income %, sale %, regeneration/sec.
local buffs = {
	{ "Chip dash", 8, 0, 0, 0, 0, 0 }, { "Hearty harvest", 2, 0, 2, 0, 0, 1 },
	{ "Sugar hop", 0, 4, 0, 0, 0, 0 }, { "Cocoa strength", 0, 0, 4, 0, 0, 0 },
	{ "Rainbow bounce", 4, 3, 0, 0, 0, 0 }, { "Peanut power", 1, 0, 6, 0, 0, 0 },
	{ "Cinnamon sprint", 10, 1, 0, 0, 0, 0 }, { "Macadamia charm", 0, 0, 0, 0, 25, 0 },
	{ "Ginger grit", 3, 0, 3, 0, 0, 1 }, { "Lemon leap", 3, 6, 0, 0, 0, 0 },
	{ "Velvet recovery", 0, 1, 0, 0, 0, 3 }, { "Mint rush", 14, 0, 0, 0, 0, 0 },
	{ "Caramel closer", 2, 0, 0, 0, 40, 0 }, { "Coconut cloud", 0, 8, 0, 0, 0, 0 },
	{ "Strawberry comfort", 4, 0, 0, 0, 0, 3 }, { "Campfire crafter", 0, 0, 8, 10, 0, 0 },
	{ "Creamy profit", 0, 0, 0, 25, 0, 0 }, { "Matcha focus", 3, 2, 4, 0, 0, 1 },
	{ "Blueberry bound", 5, 7, 0, 0, 0, 0 }, { "Espresso express", 18, 0, 0, 0, 0, 0 },
	{ "Pumpkin prospector", 2, 0, 12, 0, 0, 0 }, { "Rose persuasion", 0, 0, 0, 10, 50, 0 },
	{ "Birthday celebration", 6, 4, 0, 10, 10, 1 }, { "Churro charge", 12, 3, 0, 0, 0, 0 },
	{ "Truffle trader", 4, 0, 0, 0, 65, 0 }, { "Maple miner", 4, 1, 15, 0, 0, 0 },
	{ "Galaxy gravity", 6, 10, 0, 0, 0, 0 }, { "Marshmallow mend", 2, 3, 0, 0, 0, 5 },
	{ "Diamond precision", 0, 0, 20, 15, 0, 0 }, { "Golden baker", 5, 2, 5, 40, 25, 2 },
}
function Polish.buff(recipe)
	local b = buffs[recipe] or buffs[1]
	return { Name = b[1], Speed = b[2], Jump = b[3], Mine = b[4], Income = b[5], Sell = b[6], Regen = b[7], Seconds = 90 }
end
function Polish.describe(recipe)
	local b, parts = Polish.buff(recipe), {}
	for _, entry in ipairs({ { "Speed", " speed" }, { "Jump", " jump" }, { "Mine", " mining" }, { "Income", "% income" }, { "Sell", "% sales" }, { "Regen", " HP/s" } }) do
		if b[entry[1]] > 0 then table.insert(parts, "+" .. b[entry[1]] .. entry[2]) end
	end
	return table.concat(parts, " • ") .. " • 90s"
end
function Polish.active(life, now)
	return life.buff.expires > now and Polish.buff(life.buff.recipe) or { Speed = 0, Jump = 0, Mine = 0, Income = 0, Sell = 0, Regen = 0 }
end
function Polish.buyBelt(data)
	local nextTier = data.life.belt + 1
	local cost = Polish.BeltCosts[nextTier]
	if not cost then return false, "All three conveyor lines are built." end
	if data.cash < cost then return false, "Collect more cash to expand your conveyor." end
	data.cash -= cost
	data.life.belt = nextTier
	return true, "Conveyor line " .. nextTier .. " built!"
end
function Polish.buyDecoration(data, key)
	local item = Polish.Decorations[key]
	if not item or data.life.decorations[key] then return false, "Decoration unavailable or already owned." end
	if data.cash < item.Cost then return false, "Collect more cash for this decoration." end
	data.cash -= item.Cost
	data.life.decorations[key] = true
	return true, item.Name .. " installed!"
end
local styles = {
	{ Name = "Foodie", Appetite = 1.4, Patience = 4 }, { Name = "Bargain hunter", Appetite = 0.85, Patience = 2 },
	{ Name = "Tourist", Appetite = 1.2, Patience = 3 }, { Name = "Collector", Appetite = 1.65, Patience = 3 },
	{ Name = "Hungry local", Appetite = 1.1, Patience = 5 }, { Name = "Busy commuter", Appetite = 1.3, Patience = 1 },
}
function Polish.customer(styleRoll, recipeRoll, moodRoll)
	local style = styles[math.clamp(math.floor(styleRoll * #styles) + 1, 1, #styles)]
	return { Style = style.Name, Favorite = math.clamp(math.floor(recipeRoll * 30) + 1, 1, 30),
		Appetite = style.Appetite, Patience = style.Patience, Mood = 0.85 + moodRoll * 0.4 }
end
function Polish.offer(base, recipe, traits, roll)
	local interest = recipe == traits.Favorite and 1.6 or 1
	local amount = math.max(1, math.floor(base * traits.Appetite * traits.Mood * interest * (0.9 + roll * 0.3)))
	return amount, math.floor(amount * (1.3 + traits.Patience * 0.2))
end
function Polish.negotiate(price, budget, attempts, traits, roll, gainRoll)
	local risk = math.clamp(0.08 + attempts * 0.16 + (3 - traits.Patience) * 0.08, 0.04, 0.95)
	if attempts >= traits.Patience or roll < risk or price >= budget then return false end
	return true, math.min(budget, math.max(price + 1, math.floor(price * (1.06 + gainRoll * 0.24))))
end
return Polish
