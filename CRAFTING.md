# Cookie rarities and toppings

Open **Bakery → Workshop** and use the arrows to choose a recipe. You can also use the **Cookie Workshop** prompt on the prep counter at the back of your bakery.

The workshop shows the recipe's rarity, base value, applied toppings, global income bonus, and final cash value per cookie. Collect cash into your wallet, then buy a topping for an unlocked recipe. Each topping can be added once per recipe and automatically applies to all future cookies of that recipe. Other recipes have their own topping purchases.

## Rarity tiers

Every recipe has a fixed tier. The later recipes unlock higher rarities and multiply the original recipe value:

| Rarity | Base-value multiplier | Recipes |
| --- | --- | --- |
| Common | 1× | Chocolate Chip through Rainbow Sprinkle (1–5) |
| Uncommon | 1.25× | Peanut Butter through Lemon Crinkle (6–10) |
| Rare | 1.75× | Red Velvet through Strawberry Shortcake (11–15) |
| Epic | 2.5× | S'mores through Espresso Fudge (16–20) |
| Legendary | 4× | Pumpkin Spice through Raspberry Truffle (21–25) |
| Mythic | 6× | Maple Pecan through Golden Chocolate Chip (26–30) |

Tier colors appear on oven badges, recipe labels, the workshop, and the outlines of produced cookies. Each produced cookie also displays its rarity, value, and topping count nearby.

## Topping modifiers

Modifiers use **cookie cash**. Their prices scale with the selected recipe's original unlock cost, with a minimum so the free first recipe still has meaningful upgrade costs:

| Topping | Added value bonus | Purchase cost |
| --- | --- | --- |
| Glaze | +20% | Greater of $100 or 25% of the recipe's unlock price |
| Sprinkles | +35% | Greater of $350 or 50% of the recipe's unlock price |
| Chocolate Drizzle | +50% | Greater of $1,000 or 90% of the recipe's unlock price |
| Caramel Swirl | +75% | Greater of $3,000 or 150% of the recipe's unlock price |
| Gold Leaf | +120% | Greater of $12,500 or 300% of the recipe's unlock price |

Cash prices are rounded down to whole currency. Buying a topping adds visible glaze, sprinkles, chocolate stripes, caramel, or gold flakes to that recipe's moving cookie models.

Topping bonuses **add together**. All five give +300%, or **4×** the recipe's value. That topping multiplier then multiplies with rarity and the existing income bonuses:

```text
Cookie value = floor(
    Original recipe value
    × Rarity multiplier
    × (1 + sum of topping bonuses)
    × Golden Batter multiplier
    × Rebirth income multiplier
    × Income pass multiplier
)
```

Every final cookie value is rounded down once to whole cash. A production batch earns the sum of the values shown for its unlocked recipes. Speed upgrades change the interval between batches.

For example, an ordinary Chocolate Chip is worth $5. Adding Glaze raises it to $6. Glaze and Sprinkles together raise it to $7 after rounding. All five toppings raise it to $20 before global income boosts. A Rare Red Velvet starts at `floor($1,150 × 1.75) = $2,012`; all five toppings make it $8,050 before global boosts.

Recipe flavors can already have decorative icing or sprinkles in their base model. The purchased modifier is an additional upgrade and its cash bonus is shown explicitly in the workshop.

## Saving and rebirth

Toppings save separately for each recipe, alongside cash, ovens, rebirths, Golden Chips, and the purchase receipt ledger. A purchased modifier is queued for an early save. Rejoining and claiming another free plot restores the crafted recipes.

**Rebirth resets topping modifiers**, along with cash, banked earnings, recipe unlocks, and oven levels. Golden Chip upgrades and owned passes are retained. The confirmation screen lists the reset before you commit.

Existing saves migrate to save envelope version 3 without changing the DataStore name. Earlier envelopes receive an empty modifier table and retain existing progress and receipt history. Restart old servers when publishing this version so players do not land on game code that cannot open their upgraded saves.

## Customize the system

- `src/shared/Recipes.luau`: each recipe's `Rarity`, base `Value`, and unlock `Cost`.
- `src/shared/CookieCrafting.luau`: rarity multipliers/colors, topping definitions, costs, value bonuses, and attribute encoding.
- `src/shared/Progression.luau`: server-used value calculations, topping purchases, rebirth reset, and save normalization.
- `src/server/AssetLibrary.luau`: rarity outlines and procedural topping geometry.

The game keeps topping data as known boolean flags under string recipe keys. Client requests select only a recipe and modifier; the server checks ownership, unlock state, price, cash balance, and duplicate purchases. Client-supplied prices or claimed bonuses are never used.

## Studio checks

1. Claim a bakery and collect $100. Open Workshop, select Chocolate Chip, and add Glaze. Confirm the wallet loses $100, the displayed cookie value becomes $6, and newly produced cookies have glaze.
2. Add Sprinkles once you have $350. Confirm Glaze remains applied and the recipe is worth $7. The same ingredient's button must show **Applied** and cannot charge again.
3. Change to Oatmeal Raisin after unlocking it. Confirm it has its own toppings and its value changes independently of Chocolate Chip.
4. Browse an Epic, Legendary, or Mythic recipe. Check its fixed rarity multiplier, badge color, and higher value after unlock. Locked recipes must reject modifier purchases.
5. Leave/rejoin with toppings on multiple recipes and verify restoration. With two players, confirm buying a modifier never changes the other player's bakery.
6. Rebirth, then check topping buttons, cookie visuals, and income return to the first recipe's unmodified state while Golden Chip upgrades and owned passes remain.
7. Check the three menu tabs and recipe arrows in the mobile emulator and with a controller.

Cloud tests cover calculations, all 32 topping combinations, forged requests, duplicate buys, save/rejoin, rebirth, legacy migration, and purchase-receipt reconciliation. Roblox Studio is required for the visual, input, and multiplayer checks.
