# Cookie rarities and signature toppings

Recipes retain their six existing rarity tiers: Common 1×, Uncommon 1.25×, Rare 1.75×, Epic 2.5×, Legendary 4× and Mythic 6×. These are recipe rarities; the new animal-card collection has its own five rarity tiers.

Each recipe now offers **two matching toppings** in Bakery → Toppings. Each can be bought once per recipe with wallet cash. Examples:

| Cookie | First upgrade | Second upgrade |
| --- | --- | --- |
| Chocolate Chip | Extra chocolate chips +20% | Toasted chocolate chunks +35% |
| Oatmeal Raisin | Plump raisins +20% | Toasted oat crumble +30% |
| Sugar Cookie | Rainbow sprinkles +10% | Vanilla icing petals +25% |
| Lemon Crinkle | Fresh lemon zest +20% | Lemon sugar crystals +30% |
| Mint Chocolate | Mint chocolate curls +20% | Peppermint pieces +35% |
| S'mores | Graham cracker bits +20% | Mini marshmallows +35% |
| Golden Chocolate Chip | Golden chocolate chips +30% | Honeycomb shards +45% |

All thirty definitions are in `src/shared/RecipeToppings.luau`. The first upgrade costs `$100 + floor(unlock cost × 0.25)`; the second costs `$350 + floor(unlock cost × 0.5)`. They add small recipe-specific visual details, preserving the underlying cookie instead of covering every recipe with the same icing.

Topping bonuses add: Chocolate Chip with both uses `1 + 0.20 + 0.35 = 1.55×`. That factor multiplies recipe rarity, mastery and production bonuses. Stored-cookie prices count their own toppings/mastery/packaging/finishing, without global production multipliers.

The first/second slots retain the internal save keys `Glaze` and `Sprinkles` for migration. The old ChocolateDrizzle, CaramelSwirl and GoldLeaf upgrades are removed from purchasing, current recipe bonuses, and visuals. Earlier saves retain corresponding first/second flags; older stored cookies use the current recipe definitions. Rebirth clears current toppings and inventory.

Cookie mastery remains ten levels at +20% recipe value per level. Card production and cash boosts stack separately; see [cards and events](CARDS-AND-EVENTS.md).

## Studio checks

Select different unlocked recipes and verify only two correctly named upgrades appear, prices scale, each charges once, and additions look different across recipes. Check Chocolate Chip chips, Sugar Cookie sprinkles, Lemon zest and S'mores marshmallows. Rejoin to verify flags, inspect nearby conveyor prices, and rebirth to confirm the reset. Check all mirrored plots for oven/tray clearance.
