# Spawn market, bakery upgrades, and softer lighting

**Later update:** Both shops now occupy a separate fast-road branch, equipment has 13 tiers, and Bruno offers Star Crumb enchantments. See [Obbys and forge](OBBYS-AND-FORGE.md) for current locations, prices, and save-version details.

[Download the updated Studio ZIP](https://github.com/Messer252/RobloxGame/raw/refs/heads/main/CookieCorner_Studio.zip). Extract it and open `CookieCorner.rbxlx`. Before replacing a customized place, copy across your `AudioConfig` IDs (including Bubby's clips), `CardCatalog.ArtSheets` image IDs, `ShopCatalog` product/pass IDs, `AssetTextures` image IDs, and `AdminConfig` usernames. Publish into the same experience and restart outdated servers. No new audio or image uploads are required for these features.

Both stalls have paved approaches with cleared terrain, keeping grass beneath their floors.

## Where to open packs

Visit the **Crumbkin Pack House** in the side market beyond the bakery rows; follow the marked fast-road branch. Use the counter's **Browse packs & claim daily crumbs** prompt. You can shop without claiming a bakery. Purchases only work while you are near the stall; walking away disables them.

Claim the daily gift to afford a Bakery Friends pack immediately. The five pack prices and rarity probabilities are unchanged. Select **Show odds** for a pack to inspect its exact distribution before buying. Each pack still awards one card, and duplicates remain in your collection.

A purchased pack appears as a foil booster. Press **RIP OPEN** for the shake, torn foil, falling wrapper, rarity-colored burst and rising card reveal. **Skip animation** shows the saved result immediately. Opening animations cannot reroll a card: the server saves the currency charge and card together before revealing either. Skipping, disconnecting, or closing the reveal cannot remove a committed card.

Select **Cookie Bag → Collection** to view and equip owned cards anywhere. The bag no longer sells packs. Two equipped card slots remain free; the optional third-slot pass stays disabled until configured with your own Roblox pass ID.

## Easier Star Crumbs

These are base amounts; equipped Star Crumb cards can increase them. There is still no Robux-to-crumb or cash-to-crumb conversion.

| Activity | Reward and limits |
| --- | --- |
| Pack House daily gift | 100 once per UTC calendar day; enough for the cheapest pack |
| Public trail pickups | 5 each; 16 shared locations with individual player cooldowns of 3 minutes; up to 600 base crumbs per UTC day |
| Completed Biscuit job | 50 when you collect its reward |
| Dough ore | 3 on breaking ore, at most once every 10 seconds per player |
| Active bakery production | 10 every 60 batches, up to 600 base crumbs per UTC day |
| Easy / Medium / Hard obby | 20 / 35 / 50, with a separate saved 5-minute cooldown per difficulty |
| Cookie meteor | 100–350 for each present player contributing at least 3 hits |
| Captured Cookie Hill | 10 every 10 seconds while held and uncontested |

Daily gifts, trail cooldowns, production totals and obby reward cooldowns survive rebirth and rejoining. Production and trail caps count base rewards before card bonuses; their caps are separate. Obby cash buffs still last five minutes and use the strongest active bonus. Completing a weaker course can still award its eligible crumbs.

Trail pickups disappear locally after collection and return when your own cooldown expires; another player's pickup does not consume yours. After the daily trail limit, jobs, mining, obbys and events still provide other ways to earn currency. Actual first-pack and premium-pack pacing needs testing with players.

## Hill ownership after leaving

Stand on the hill alone for eight seconds to capture it. You can then return to your bakery and keep earning **10 base Star Crumbs every 10 seconds**, provided you remain online in that server. The HUD indicates when you own the hill.

Multiple players on the hill pause payouts. Another player standing there alone for eight seconds takes ownership. A partial capture interrupted by leaving does not transfer ownership. Logging out releases the hill; ownership and offline income do not carry between servers. There is no catch-up payout after lag, a blocked profile transaction, or downtime. Flying/invisible admins are ineligible.

## Bruno's blacksmith

Visit **Bruno Crustforge**, at the side-market stall next to the Pack House, for rolling-pin and cookie-armor upgrades. Use the counter or Bruno's prompt. Purchases use collected wallet cash and only work near the stall.

The original five rolling-pin tiers retain their distinct models, costs and mining power. Eight further pin and armor tiers and enchantments are documented in [Obbys and forge](OBBYS-AND-FORGE.md). Pin upgrades have moved out of the mine menu. The cave workshop still sells Mixing, Flow and Pockets upgrades for dough.

| Cookie armor | Price | Rolling-pin damage reduction |
| --- | ---: | ---: |
| Oat Guard | $1,500 | 5% |
| Cocoa Plate | $15,000 | 10% |
| Sugarsteel | $100,000 | 17% |
| Golden Crust | $750,000 | 24% |
| Star Cookie | $5,000,000 | 32% |

Buy tiers in order; each purchase equips the new armor. Fitted breastplates, chocolate rivets, shoulder pieces, greaves and a helm band follow standard R6/R15 character parts. Higher tiers change materials and trim. Armor has no collision or weight and reappears after respawning. **Armor and rolling pins survive rebirth and rejoining.** Armor adds to food defense, with a combined 60% damage-reduction cap in the current forge update. Player combat remains restricted to Cookie Hill.

## Clearer controls and fitted decorations

The HUD has spaced Bakery/Home/Music/SFX controls in automatically sized rows. Full music and sound-effect sliders now live under **Bakery → Audio**. Menu tabs wrap into additional rows on narrower screens, and their scrolling contents move down with them. World prompts show one interaction at a time.

Decoration buttons come from the shared catalog. Three progression paths expose only the next available purchase in each path:

- **Structure:** walls → fitted windows → hinged door → skylight roof → warm pendant lights.
- **Garden:** potted plants → cookie trees → flower borders → fencing → cookie fountain.
- **Café:** warm oak floor → seating → display cabinet → bakery lettering.

Rear purchase pads automatically arrange into a spaced two-column grid. Bought and locked pads are hidden, while newly unlocked purchases appear. Machines follow **first conveyor → Packager → Boxer → Finishing Oven**, with only the next eligible machine pad shown. The owned finishing-oven interaction remains available. The build-line pad disappears after the third conveyor purchase. Menu purchases still require standing by the corresponding available pad in your own bakery.

Wall/window dimensions share the same bakery footprint. A road-side doorway stays aligned with its jamb and fixed hinge. Roof wings meet the skylight, and pendants sit below it. Garden and café purchases occupy the outer side of the bakery, leaving production lanes clear. Existing purchased decoration and machine flags are kept; older owners do not have to repurchase missing prerequisites. Rebirth still removes these cash-bought bakery upgrades.

## Lighting

Daytime brightness, exposure, ambient light, bloom and reflections are lower, and the day/night controller preserves those settings. Floors now use muted wood colors rather than near-white tiles. Bought floors use continuous oak planks; pendant and forge lights are soft and local. These changes need a visual check at your usual Roblox graphics quality and on mobile devices.

## Saving, updating, and playtesting

The current **version-10 save envelope** accepts versions **1–9**, retaining receipts, currencies, cards, quest progress, audio choices, paid entitlements and gift recovery. New armor and reward fields receive safe defaults. Keep `CookieCorner_PlayerData_v1` and `CookieCorner_CookieTrades_v1`; do not switch to fresh stores or run older save code after this update.

Automated checks exercise hill transfer/logout, reward caps/cooldowns across receipts/rejoin/rebirth, armor purchases and migration, machine prerequisites, decoration progression, public pickup placement and responsive row geometry. Complete these checks in a separate published Roblox test experience:

1. With two players, capture the hill, leave it, verify continued ten-second payments, contest it, transfer ownership, and log out. Confirm no rewards after logout or outside that server.
2. Visit both stalls from spawn. Claim a daily gift and rip/skip packs. Walk away and try another purchase. Rejoin to verify cards, crumbs, armor, rolling pins and claim cooldowns restore.
3. Try each armor tier on R6 and R15 avatars, respawn, and test capped defense using food and rolling pins on the hill. Confirm no damage elsewhere.
4. Build all three decoration paths on opposite plots; verify hinges, windows, roof fit, soft lights, available pads and clear conveyor lanes. Test rebirth cleanup and retained gear.
5. Check desktop, phone portrait/landscape and controller navigation. Inspect wrapped tabs, scrolling, slider touch input, repeated pack reveals, animation skipping and a simulated save failure.
6. Inspect noon, dusk and night at low/high graphics quality. Ensure floors stay readable, cave lighting works and eight-client performance remains acceptable.

The cloud environment can build and check source, storage rules and packages; it cannot run Roblox Studio, live DataStores, multiplayer physics, avatar rendering or audio playback.
