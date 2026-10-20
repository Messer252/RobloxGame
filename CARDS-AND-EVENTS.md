# Cookie animals, Star Crumbs, and valley update

[Download the current Studio ZIP](https://github.com/Messer252/RobloxGame/raw/refs/heads/main/CookieCorner_Studio.zip). Open `CookieCorner.rbxlx`, copy across your customized product IDs/admin list, publish into the same experience, and restart outdated servers. Keep the existing DataStore names.

## Rebirth and your bakery

Rebirth now **empties the cookie bag**, clears held-cookie tools, resets the conveyor build tier to zero, removes built conveyor geometry and the delivery box, resets machines/mastery/toppings/food effects, and removes purchased decorations. The starter oven remains; build its first conveyor again for free.

**Cards, equipped cards, Star Crumbs, dough, rolling pins, dough upgrades, Golden Chip upgrades, paid passes, audio choices, shop name, and quest progress remain.** Wallet/collection cash resets as before. A pending gift or pack save must settle before rebirth can proceed.

All plots now put their entrance, claim pad, personal spawn and register beside the road. The first recipe lane is on that side too. The collector's gold pad is next to this starting area. A compact floating sign shows the account username and bakery name. Your own sign appears within **180 studs**; other bakery signs appear only within **55 studs** of your character. Signs no longer draw through scenery, and their ownership updates when a bakery is claimed or released. In Cookie Bag → Machines, enter a name and buy **Rename cookie shop** for **$20 million**. Roblox filters the name before charging; a filtering failure charges nothing. Stored names are filtered again when loaded for display.

There are now **14 decoration purchases**: walls, windows, hinged door, skylight roof, pendant lights, plants, cookie trees, herringbone floor, lettering, cafe benches, cookie fountain, display case, flower beds, and fencing. Windows/door/roof require walls; lights require the roof. Frames fit actual wall openings. The door leaf, handle and rails rotate together around a fixed visible hinge. Purchases and their prices appear on the rear decoration pads and Machines page.

## Natural terrain and cookie moon

The disconnected wedge mountains/snowcaps have been removed. A continuous Roblox terrain height field now connects the meadow to rolling foothills, rock slopes, distant snowy ridges, and the map boundary. Snow is a material on those same surfaces, so it cannot float independently of a mountain. Clouds, cooler distance haze, forest trails, wildflowers, grass decoration, and terrain-height tree placement soften the scene. Plot floors, the road, cave and obbys stay usable. Terrain builds in small yielding chunks at server startup; allow it to finish before judging the distant landscape.

At night, a new **chocolate-chip cookie moon** has a baked golden rim, warm cookie face, irregular chocolate chunks, and tiny baked pores. It follows the night sky and hides in daylight. The cookie sun and shared day/night cycle remain.

Terrain now stays six studs below the road, spawn plaza and all eight bakery floors, with a padded border for voxel smoothing. Those areas and their blended shoulders use ground material so native grass cannot poke through the pavers or floors. The surrounding meadow still has grass. Republish the updated place and restart outdated servers to regenerate the terrain.

## Packs and collection

Open **Cookie Bag → Cards**. Five packs each award **one** cookie-animal card. The price and exact rarity odds are shown before opening. All animals within a rarity have equal odds. The server rolls the result; the charge and ownership grant are committed together before the ripping/reveal animation.

| Pack | Star Crumbs | Common | Uncommon | Rare | Legendary | Mythical |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Bakery Friends | 100 | 78% | 19% | 2.7% | 0.25% | 0.05% |
| Woodland Treats | 350 | 50% | 36% | 12% | 1.7% | 0.3% |
| Safari Sweets | 900 | 20% | 43% | 30% | 6% | 1% |
| Dragon's Oven | 2,200 | 5% | 22% | 47% | 22% | 4% |
| Celestial Bakery | 6,000 | 0% | 8% | 37% | 40% | 15% |

There are **15 commons, 10 uncommons, 7 rares, 3 legendaries and 5 mythicals**. Every card has a unique buff or combination: income, production speed, customer sale prices, Star Crumb rewards, or mining damage. Bonuses on equipped cards add within a stat, then multiply the relevant bakery system. Duplicates are retained as extra owned copies; duplicate copies do not stack or occupy multiple slots.

**Two equip slots are free.** Select an owned card to equip/unequip it. The optional third slot is a permanent game pass. In Creator Dashboard, create **Third Card Slot**, set its price to **150 Robux**, and put its ID in **ReplicatedStorage → CookieTycoon → ShopCatalog → Passes → ThirdCardSlot → Id**. The ID is currently 0, so its purchase stays disabled. Roblox supplies the live final price and ownership; client attributes never grant a third slot.

Star Crumbs have no cash-to-crumb or Robux-to-crumb conversion. Cards/crumbs survive rebirth. Pack opening works without saving only in the explicitly labeled session-only Studio preview; published play uses durable profile transactions.

## TCG artwork and frames

The forty cookie animals now use original **hand-drawn anime TCG illustrations** with inked contours, cel shading, action poses and richer rare/fantasy scenes. Card faces have nameplates, rarity pips, framed art, ability panels, flavor text, collector numbers, and animated foil borders for legendary/mythical cards. Names, abilities and quips remain typeset by the UI rather than baked into images.

The ZIP includes four **CookieTCG_01.png** through **CookieTCG_04.png** sheets, ten illustrations per image in a 5×2 grid. It also includes **CardGallery.html**; keep the four images beside it and open it in a browser to search/filter the complete collection.

Upload the four PNGs as Roblox images. In **ReplicatedStorage → CookieTycoon → CardCatalog → ArtSheets**, set each sheet's `Id` to its matching numeric image asset ID. Keep the supplied dimensions, grid and card ranges unchanged. These replace the earlier single CookieAnimals atlas. Native 3D previews work until the new sheet IDs are configured. This cloud environment cannot upload assets into your Roblox account.

The in-game compass has been removed completely. The HUD retains Star Crumbs, active food buffs and the PvP warning, without headings or direction indicators.

## Earning Star Crumbs

The intended grind mixes short jobs, normal bakery play and occasional public events:

- **Biscuit jobs:** 25 base crumbs per completed paid-out task. Accepting or swapping a job awards none.
- **Dough mining:** 1 base crumb for breaking an ore, at most once every 20 seconds per player. Dough rewards remain separate.
- **Production milestones:** 10 base crumbs per 120 bakery batches, capped at 300 base crumbs per UTC day. This source requires a claimed bakery and built conveyor; no offline production is counted.
- **Cookie meteors:** a fresh server schedules a random arrival after **5–30 minutes**, then continues at randomized intervals. The cookie falls with fire into an outer meadow and can be mined with rolling pins. It has 180 HP; hit damage is capped at 20. Players who contribute at least **three hits** each receive their own **100–350 base crumbs** when it breaks. There is no last-hit-only reward. It expires after five minutes if unfinished; eligible present players have 45 seconds after breaking for pending saves to settle and rewards to apply.
- **Cookie Hill:** hold the marked hill in the west meadow alone for **8 seconds**, then receive **10 base crumbs every 10 seconds** while it remains uncontested. Another player pauses rewards and restarts capture. There are no currency rewards for kills.

Equipped crumb cards multiply awards; whole-number rewards round down. The production cap counts base crumbs, before card bonuses. Start with jobs and mining, join meteor events when announced, and choose whether to risk the hill. This should make the first inexpensive pack a goal within a normal session, while premium packs reward saving across sessions. **Actual session timing still needs live-player balance testing**; adjust prices/reward constants after watching first-pack times and how often players save for higher packs.

## Hill combat and food

Cookie Hill now has a raised cookie arena with chocolate inlays, a brass plinth, wide stairs facing the bakeries, an entrance arch, four tall banners, and a crowned cookie trophy with a warm beacon. The elevated sign is visible from farther away. The lit ring marks the actual PvP boundary: gold while available/capturing, green when owned, and red when contested. The arena stays clear of terrain grass and its floor trim has no collision to snag players during combat.

Rolling pins now have five distinct models and finishes. **Maple** has turned wood and grain; **Copper** has dark wood and hammered bands; **Steel** has a fluted metal barrel and textured grips; **Gilded** has marble, gold bands and cookie crests; **Starforged** has a faceted violet crystal barrel and cyan luminous seals. The tool is held by its end grip, and every decorative part is welded and non-colliding. These finishes use built-in Roblox materials, so no texture upload is required. The mine menu and hotbar show the tier names. Existing prices, mining power, combat damage, swing controls and saved upgrade levels remain the same.

**PvP is restricted to Cookie Hill.** Equip a rolling pin and left-click to swing. Both attacker and target must be living characters inside the hill's horizontal/height bounds, close together and in front of the attacker. Swings have a server cooldown. Damage and knockback do not apply on roads, in bakeries, or elsewhere. New characters receive five seconds of event protection. Invisible/flying admins cannot contest, earn, or fight on the hill.

Some cookies now add **pin damage or defense** alongside their existing effects. Examples: Double Chocolate +6 damage, Peanut Butter +8, S'mores +10, Maple Pecan +12, Golden Chocolate Chip +14; Oatmeal Raisin 10% defense, Red Velvet 20%, Toasted Marshmallow 25%, Diamond Vanilla 30%. The bag shows the effects before eating. Defense is capped at 45% in the damage rule. Food still lasts 90 seconds, replaces the previous food effect, and clears on rebirth.

## Signature toppings

Every recipe now has **two special upgrades**, with small visible additions rather than a shared stack of five coatings. Chocolate Chip gets extra chips (+20%) and toasted chunks (+35%); Sugar Cookie gets sprinkles (+10%) and vanilla icing petals (+25%). Other recipes use raisins, oats, citrus zest, nuts, fruit, coconut flakes, marshmallows, cinnamon, matcha, and other matching details.

The two prices remain tied to unlock cost: `$100 + 25%` and `$350 + 50%`. Older saves keep corresponding first/second topping flags; the three removed universal upgrades no longer affect new recipe income or decoration. Stored older cookies also use the recipe's two current topping definitions. See [CRAFTING.md](CRAFTING.md).

## Save upgrade and Studio checks

Save envelope **8** accepts **1–7**, retaining `CookieCorner_PlayerData_v1` and the existing trade journal. New card/currency fields default safely on older saves. Restart outdated servers after publishing.

Automated tests cover exact pack probabilities, unique buffs, equip entitlement/caps, atomic charges and lost-response recovery, rebirth cleanup, daily milestones, meteor bounds, hill damage/bounds, terrain continuity, topping limits, and decoration prerequisites. Complete these Roblox engine checks before public rollout:

1. Test opposite plots, road-side claim/spawn/register positions, large banners, all fourteen decorations, roof/light purchases, door hinges and window fit.
2. Rebirth with a full bag, held cookie, developed bakery, equipped cards, crumbs and food. Verify empty bag, cleared conveyors/box/decorations, retained cards/crumbs and free first-line rebuilding; rejoin too.
3. Let terrain generation finish; walk the meadow/trails, inspect connected mountain/snow surfaces, lake, cave, forest, and nighttime cookie moon. Test eight-client/mobile performance.
4. Upload the four TCG sheets and inspect all forty crops, quips, reveal animation, touch/controller controls, rare art and holographic frames. Test fallback previews with each sheet Id set to 0.
5. Use a separate published test experience for pack-save interruption/rejoin and the third-slot pass. Verify each charge has exactly one card and that unpaid users receive only two active slots.
6. Finish jobs, mine ore, reach production milestones, and test the daily cap. Confirm accepting/swapping tasks, cash bundles and admin cash gifts award no crumbs.
7. Temporarily shorten meteor scheduling only in a private test copy. Test landing, fire, three-hit participation, multiple contributors, damage cap, timeout, and rewards after a busy save.
8. With two players, capture/contest/leave the hill, test pin hit direction/range, food damage/defense, knockback, new-character protection, and zero PvP damage outside the hill. Test flying/invisible admin exclusion.
9. Rename with sufficient/insufficient cash, a filtered name, text-filter failure and rejoin. Confirm filtering failure charges nothing and the public banner never exposes unchecked stored text.
