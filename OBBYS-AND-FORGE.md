# Obbys, the side market, and enchanted equipment

[Download the updated Studio ZIP](https://github.com/Messer252/RobloxGame/raw/refs/heads/main/CookieCorner_Studio.zip). Extract it, then open **CookieCorner.rbxlx** in Roblox Studio. No new image or audio uploads are required for this update.

## Harder obbys

The three courses now have **14, 18, and 24 landing platforms**. Ordinary platforms are narrower, while hazard platforms have extra room to dodge or jump. The finish is a wider landing area. Platforms have no floating number labels.

- **Easy:** alternating red edge zones teach careful landings.
- **Medium:** red hurdles cross wider platforms; jump over them.
- **Hard:** rotating red sweepers require timing jumps and landings.

The terrain and solid meadow slabs underneath are removed, leaving stone-lined pits. Falling below the route or touching a red hazard returns your character to that course's start and clears the run's checkpoint progress. It keeps any already-earned cash boost. Touch detection uses the character's body and feet, so decorative hats and held rolling pins do not count as hazard contact.

Land on every platform in order. The finish automatically grants the existing five-minute cash boost: **10% Easy, 30% Medium, 50% Hard**. Existing **20/35/50 Star Crumb** finish rewards and five-minute crumb cooldowns remain. A temporarily busy save retries while you stay at the finish. Stronger active cash boosts are preserved; the completion notice explains the actual reward. Flying admins cannot record a run.

## Finding the shops

The Pack House and Bruno's Crustforge now occupy a separate market beyond the bakery rows, above the Easy obby. Follow the road from spawn toward the **Market** sign, then take its marked branch. Both approaches have the same road speed boost as the main road. Terrain, trees, and wildflowers leave the foundations and paths clear.

The two stall centers are `(275, 1, -315)` and `(345, 1, -315)`. The branch crosses the gap between bakery rows at `Z = -282`; it does not pass through plot floors or conveyors. Three representative equipment displays fit inside Bruno's stall; all tiers are available through his menu.

## Thirteen equipment tiers

The original five tiers remain at their original prices. Eight new tiers follow Starforged / Star Cookie. Gear is bought sequentially with collected wallet cash and survives rejoining. **Rebirth resets the rolling pin to Maple (tier 1) and removes armor (tier 0).** Players return home on rebirth so the newly locked mine galleries cannot trap them. Enchantments remain saved; armor enchantment defense and effects activate again after armor is repurchased.

| Tier | Rolling pin | Armor | Price for each | Mining power | Armor defense |
| --- | --- | --- | ---: | ---: | ---: |
| 6 | Peppermint | Peppermint Guard | $12M | 36 | 34% |
| 7 | Honeycomb | Honeycomb Mail | $30M | 43 | 36% |
| 8 | Frosted Crystal | Frosted Crystal | $75M | 51 | 38% |
| 9 | Molten Cocoa | Molten Cocoa | $180M | 60 | 40% |
| 10 | Moon Sugar | Moon Sugar | $450M | 70 | 42% |
| 11 | Prismatic | Prismatic Shell | $1.1B | 81 | 44% |
| 12 | Dragon Crust | Dragon Crust | $2.7B | 93 | 46% |
| 13 | Celestial Baker | Celestial Baker | $6.5B | 106 | 48% |

New models use candy stripes, honeycomb studs, crystal ribs, molten seams, moon inlays, prismatic facets, dragon scales, and celestial cage/crown details. They use native Roblox materials and welded, noncolliding parts. High-tier pins retain access to all five mine galleries; additional galleries are not required to use them.

Combat damage grows more slowly than mining power. Combined armor, food, and enchantment defense is capped at **60%**. Even the strongest pin with the existing largest damage food buff and a Mythical enchantment deals under 50 damage against an unarmored player. PvP remains restricted to Cookie Hill.

## Enchant at Bruno's blacksmith

Open Bruno's menu and select **Enchant equipment**, then choose your rolling pin or armor. Armor must be purchased first. Every roll costs **100 Star Crumbs**, the same earned currency used for packs. This is separate from Golden Chips.

| Rarity | Chance | Pin mining bonus | Pin damage bonus | Armor defense bonus | Effect |
| --- | ---: | ---: | ---: | ---: | --- |
| Common | 50% | +5% | +1 | +1 percentage point | Sparse cream sparks |
| Uncommon | 28% | +10% | +2 | +2 points | Green sparks |
| Rare | 15% | +18% | +3 | +4 points | Blue sparks |
| Legendary | 6% | +28% | +4 | +6 points | Gold sparks and a short motion trail |
| Mythical | 1% | +40% | +5 | +8 points | Violet sparks and a stronger motion trail |

Pin and armor enchantments are separate. Each slot keeps its best rarity through gear upgrades, rebirth, death, and rejoining. **An equal or lower roll still spends 100 crumbs, but does not replace the saved enchantment.** Mythical slots cannot be rolled again. Odds and costs appear before the purchase buttons. Bonuses do not stack from repeated rolls; the equipped slot uses its saved best rarity.

The server chooses the result once and saves it with the charge. A save retry uses the same result; an uncertain save pauses economy actions until recovery. In an explicitly enabled Studio session-only preview, purchases work for that preview but do not persist.

## Updating your published game

Back up your customized Studio place. Carry over your configured **AudioConfig** IDs (including Bubby), **CardCatalog.ArtSheets**, **ShopCatalog**, **AssetTextures**, and **AdminConfig** values into the updated scripts. Keep new configuration fields. Publish into the same experience and restart outdated servers.

The save envelope advances to **version 11**, accepting versions **1–10**. Existing gear is retained when updating or rejoining; it resets only after a successful rebirth. Currencies, cards, receipts, quests, audio preferences, and existing enchantments are retained. Older saves without enchantments start empty. Keep `CookieCorner_PlayerData_v1` and `CookieCorner_CookieTrades_v1`; older server code rejects version-11 records to prevent it from discarding higher gear tiers or enchantments.

## Studio playtest checklist

The cloud checks cover progression, purchases, odds, save/retry/rejoin behavior, pit and road geometry, ordered checkpoints, hazard contact bounds, and embedded source/package integrity. Roblox physics, visuals, live DataStores, and multiplayer behavior still need testing in Studio or a separate published test experience.

1. Run all three obbys with a default avatar, then with cookie speed/jump buffs. Test R6 and R15. Fall into every pit, touch each red hazard, and verify immediate return to the correct start. A clean jump over a hazard must succeed. Check the rotating sweepers at lower frame rates and on touch controls.
2. Complete a course, verify the actual boost and crumb reward, then repeat during its cooldown. Try skipping a platform and walking off the finish while a save is busy. Rejoin/respawn and verify an old partial run cannot award a reward.
3. Visit every plot while eight players occupy them. Follow the branch to both counters; verify speed increases on its paved surfaces and ends when you leave. Check delivery boxes, market roofs, greenery, and lamps for overlap.
4. Purchase successive gear tiers. Inspect both avatar types, held pins, armor, and each enchantment rarity. Verify effects change after enchanting, stay bounded, and disappear when the character/tool is destroyed. Walk through every unlocked cave gate with tiers 6–13.
5. Roll on both slots, test insufficient crumbs and Mythical lockout, then rebirth and rejoin. Verify exactly 100 crumbs per accepted roll and preservation of the best result. Test hill combat against an unarmored player and a fully equipped player.

## Suggested next improvements

These are recommendations, not additional features silently included in this update:

1. **One next-goal panel.** Guide the first session through “start your conveyor → collect cash → upgrade your pin → finish Easy → choose a pack or enchantment.” Show one useful action at a time, then let experienced players dismiss it.
2. **An activity board in the market.** Offer a rotating choice of mining, baking, obby, and customer jobs with similar Star Crumb rewards per minute. Players can fund their next pack or enchantment through the activities they enjoy, without feeling forced to camp the hill.
3. **Protect the pack/enchant choice.** Display each activity's expected crumb reward. Track actual time to a pack and to an enchantment during playtests; tune rewards before adding more currencies. Consider an enchantment pity meter later so a long unlucky streak has a visible endpoint.
4. **Keep cash collection meaningful.** Introduce a machine, decoration, and gear recommendation after a big collection, but show only the next affordable upgrade. Each trip home should end with a clear decision rather than a wall of buttons.
