local Catalog = {
	Rarities = { "Common", "Uncommon", "Rare", "Legendary", "Mythical" },
	Colors = { Common = { 193, 193, 180 }, Uncommon = { 106, 204, 142 }, Rare = { 100, 171, 244 }, Legendary = { 247, 197, 91 }, Mythical = { 217, 140, 239 } },
	-- Exact odds in hundredths of a percent. Packs use earned currency only.
	Packs = {
		{ Name = "Bakery Friends", Cost = 100, Weights = { 7800, 1900, 270, 25, 5 } },
		{ Name = "Woodland Treats", Cost = 350, Weights = { 5000, 3600, 1200, 170, 30 } },
		{ Name = "Safari Sweets", Cost = 900, Weights = { 2000, 4300, 3000, 600, 100 } },
		{ Name = "Dragon's Oven", Cost = 2200, Weights = { 500, 2200, 4700, 2200, 400 } },
		{ Name = "Celestial Bakery", Cost = 6000, Weights = { 0, 800, 3700, 4000, 1500 } },
	},
	Cards = {},
	-- Upload assets/cards/CookieAnimals.png as one Roblox image and enter its ID.
	ArtAssetId = 0, ArtColumns = 8, ArtRows = 5, ArtWidth = 1586, ArtHeight = 992,
}
local entries = {
	{ "Chocolate Chip Monkey", "Monkey", "Swings by for the freshest batch.", "Cash", 0.05 },
	{ "Oatmeal Raisin Otter", "Otter", "Keeps the river and the register flowing.", "Speed", 0.04 },
	{ "Sugar Cookie Bunny", "Bunny", "One hop ahead of the morning rush.", "Cash", 0.04, "Speed", 0.01 },
	{ "Double Chocolate Bear", "Bear", "A big soft spot for small cookies.", "Mine", 1 },
	{ "Rainbow Sprinkle Mouse", "Mouse", "Tiny paws. Tremendous presentation.", "Sales", 0.07 },
	{ "Peanut Butter Puppy", "Dog", "A loyal helper with sticky paws.", "Cash", 0.03, "Mine", 1 },
	{ "Snickerdoodle Fox", "Fox", "Knows a shortcut to the cooling rack.", "Speed", 0.03, "Sales", 0.03 },
	{ "Macadamia Koala", "Koala", "Naps between very important taste tests.", "Cash", 0.06 },
	{ "Gingerbread Squirrel", "Squirrel", "Stocks the pantry for a rainy day.", "Crumbs", 0.05 },
	{ "Lemon Crinkle Duck", "Duck", "A little zest makes a big splash.", "Speed", 0.05 },
	{ "Red Velvet Panda", "Panda", "Every batch deserves a gentle hug.", "Cash", 0.03, "Sales", 0.04 },
	{ "Mint Chocolate Kitten", "Cat", "Purrfectly cool under pressure.", "Crumbs", 0.04, "Speed", 0.01 },
	{ "Caramel Raccoon", "Raccoon", "The lid was already open. Probably.", "Sales", 0.08 },
	{ "Coconut Hedgehog", "Hedgehog", "Soft heart. Extra crunchy coat.", "Mine", 2 },
	{ "Strawberry Hamster", "Hamster", "Cheeks full of tomorrow's specials.", "Cash", 0.02, "Crumbs", 0.03 },
	{ "S'mores Owl", "Owl", "The night shift smells wonderful.", "Cash", 0.10 },
	{ "Cookies & Cream Penguin", "Penguin", "Slides into every order on time.", "Speed", 0.08 },
	{ "Matcha Deer", "Deer", "Brings a little calm to the kitchen.", "Cash", 0.06, "Speed", 0.04 },
	{ "Blueberry Seal", "Seal", "Applauds every fresh tray.", "Sales", 0.15 },
	{ "Espresso Sloth", "Sloth", "Finally, a reason to hurry.", "Speed", 0.10 },
	{ "Pumpkin Red Panda", "Panda", "Autumn is a flavor, not a season.", "Crumbs", 0.10 },
	{ "Pistachio Peacock", "Peacock", "Dresses every cookie for the occasion.", "Cash", 0.08, "Sales", 0.08 },
	{ "Birthday Llama", "Llama", "Every day is somebody's birthday.", "Mine", 4 },
	{ "Churro Capybara", "Capybara", "No rush. Just a very efficient bakery.", "Speed", 0.06, "Crumbs", 0.05 },
	{ "Raspberry Bat", "Bat", "Delivers truffles after sunset.", "Cash", 0.07, "Crumbs", 0.06 },
	{ "Snickerdoodle Hippo", "Hippo", "A cinnamon smile as wide as the river.", "Cash", 0.20 },
	{ "Chocolate Chip Tiger", "Tiger", "Stripes, chips, and impeccable timing.", "Speed", 0.15 },
	{ "Lemon Lynx", "Cat", "Spots a sweet deal from a mile away.", "Sales", 0.30 },
	{ "Caramel Stag", "Deer", "Golden antlers. Golden opportunities.", "Cash", 0.12, "Crumbs", 0.10 },
	{ "Coconut Snow Leopard", "Cat", "Silent paws keep the ovens humming.", "Speed", 0.10, "Mine", 5 },
	{ "Blueberry Griffin", "Griffin", "Guards the last slice with great dignity.", "Crumbs", 0.18 },
	{ "Espresso Raven", "Raven", "Forecast: another record batch.", "Cash", 0.12, "Speed", 0.08 },
	{ "Mint Chocolate Dragon", "Dragon", "Breathes cool mint. Bakes hot profits.", "Cash", 0.45, "Speed", 0.15 },
	{ "Golden Chip Lion", "Lion", "The mane attraction at every bake sale.", "Crumbs", 0.30, "Sales", 0.25 },
	{ "Red Velvet Phoenix", "Phoenix", "Every fresh start rises beautifully.", "Cash", 0.30, "Mine", 10 },
	{ "Galaxy Brownie Kirin", "Kirin", "A constellation in every crumb.", "Cash", 0.65, "Crumbs", 0.20 },
	{ "Diamond Vanilla Wolf", "Wolf", "Howls softly so the dough can rest.", "Speed", 0.30, "Mine", 15 },
	{ "Marshmallow Pegasus", "Pegasus", "Cloud-soft wings. Sky-high standards.", "Cash", 0.45, "Speed", 0.20 },
	{ "Pistachio Rose Hydra", "Hydra", "Five heads. One very organized kitchen.", "Sales", 0.75, "Crumbs", 0.25 },
	{ "Maple Celestial Turtle", "Turtle", "Carries a whole bakery of possibilities.", "Cash", 0.40, "Crumbs", 0.35 },
}
for id, e in ipairs(entries) do
	local rarity = id <= 15 and "Common" or id <= 25 and "Uncommon" or id <= 32 and "Rare" or id <= 35 and "Legendary" or "Mythical"
	local effects = { [e[4]] = e[5] }
	if e[6] then effects[e[6]] = e[7] end
	Catalog.Cards[id] = { Id = id, Name = e[1], Animal = e[2], Quip = e[3], Rarity = rarity, Effects = effects }
end
return Catalog
