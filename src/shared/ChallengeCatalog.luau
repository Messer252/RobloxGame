-- Original, finite scavenger hunts. Positions stay in public areas so another
-- player's bakery ownership never prevents a discovery.
return {
	NPCName = "Baker Biscuit",
	NPCPosition = { 9, 0, -15 },
	Challenges = {
		{
			Id = "PlazaPeek", Name = "Plaza Peek", Reward = 500,
			Hint = "I misplaced three baking tools near the plaza. Can you spot them?",
			Items = { "GoldenSpoon", "SugarCube", "PinkWhisk" },
		},
		{
			Id = "BakersTrail", Name = "Baker's Trail", Reward = 2500,
			Hint = "Follow the path and peek around a cookie tree.",
			Items = { "RollingPin", "BlueCookieTin", "StarCutter" },
		},
		{
			Id = "SweetDetour", Name = "Sweet Detour", Reward = 15000,
			Hint = "A few sweet supplies escaped to the edges of the meadow.",
			Items = { "SprinkleJar", "CaramelBottle", "LostMitten" },
		},
		{
			Id = "BiscuitTreasure", Name = "Biscuit's Treasure", Reward = 75000,
			Hint = "One last search! My favorite treasures are hiding in plain sight.",
			Items = { "MeasuringCup", "RecipeBook", "GoldenCookieChip" },
		},
	},
	Items = {
		GoldenSpoon = { Name = "Golden Spoon", Kind = "Spoon", Hint = "Look underneath the left plaza bench.", Position = { -34, 0.9, -1 }, Color = { 240, 190, 77 } },
		SugarCube = { Name = "Sugar Cube", Kind = "Cube", Hint = "A lamp on the left path, toward the north.", Position = { -11.5, 0.8, -65 }, Color = { 255, 246, 224 } },
		PinkWhisk = { Name = "Pink Whisk", Kind = "Whisk", Hint = "Peek behind the right plaza bench.", Position = { 34, 1.0, 3 }, Color = { 244, 157, 178 } },
		RollingPin = { Name = "Rolling Pin", Kind = "RollingPin", Hint = "Beside the cookie tree on the right, south of the plaza.", Position = { 188, 1.0, 81 }, Color = { 191, 139, 88 } },
		BlueCookieTin = { Name = "Blue Cookie Tin", Kind = "Tin", Hint = "Follow the main path south; check its right edge.", Position = { 12, 1.0, 106 }, Color = { 126, 181, 200 } },
		StarCutter = { Name = "Star Cutter", Kind = "Star", Hint = "Farther north, near the left edge of the main path.", Position = { -12, 1.0, -136 }, Color = { 238, 193, 106 } },
		SprinkleJar = { Name = "Sprinkle Jar", Kind = "Jar", Hint = "The far northwest cookie tree has a colorful secret.", Position = { -188, 1.0, -222 }, Color = { 223, 161, 192 } },
		CaramelBottle = { Name = "Caramel Bottle", Kind = "Bottle", Hint = "Check the left edge of the main path, far to the south.", Position = { -12, 1.0, 181 }, Color = { 219, 157, 77 } },
		LostMitten = { Name = "Lost Oven Mitt", Kind = "Mitten", Hint = "Try the cookie tree in the far southeast corner.", Position = { 188, 1.0, 222 }, Color = { 156, 196, 153 } },
		MeasuringCup = { Name = "Measuring Cup", Kind = "Cup", Hint = "A cookie tree on the left, just north of the plaza.", Position = { -188, 1.0, -83 }, Color = { 168, 207, 215 } },
		RecipeBook = { Name = "Secret Recipe Book", Kind = "Book", Hint = "Head all the way north along the main path.", Position = { 10, 0.7, -247 }, Color = { 182, 130, 151 } },
		GoldenCookieChip = { Name = "Golden Cookie Chip", Kind = "Chip", Hint = "Look behind the cookie monument in the plaza.", Position = { 0, 1.0, 27 }, Color = { 247, 200, 85 } },
	},
}
