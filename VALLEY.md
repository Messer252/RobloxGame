# Cookie valley update

**Current controls and mechanics:** see [the Workshop update](WORKSHOP.md), which replaces the earlier mining prompts, quest waypoints, cookie swaps, generic food buffs, and scenery described below.
Download the latest [Studio ZIP](https://github.com/Messer252/RobloxGame/raw/refs/heads/main/CookieCorner_Studio.zip), extract it, and open `CookieCorner.rbxlx`. Publish to your existing start place and **restart outdated servers**. Keep the existing player DataStore name. Before replacing a customized Studio file, copy across any audio IDs, shop product IDs, and friends you added to AdminConfig.

## Map and travel

- Opposite sides of the road now have mirrored bakeries, including ovens, rail geometry, purchase pads, cookie movement, and personal spawn positions. Claim buttons show the owning account's username.
- The central road has a visible asphalt surface and markings. Walking on it raises speed from **16 to 34**; leaving it returns normal speed. Cookie food bonuses add to either speed.
- **Home** is always beside Bakery in the HUD. It returns you to your own claimed bakery; claim a plot first.
- The valley has a larger cookie forest, chocolate-chip cookies growing on trees, surrounding snow-topped mountains, a swimmable lake, footbridge, and animated waterfall spray. The mountain panorama is built from native 3D scenery, so it needs no skybox image uploads.
- A shared **20-minute day/night cycle** changes sunlight and ambient lighting while keeping night playable. The sun is a large cookie with chocolate chips, following Roblox's actual sun direction. It hides below the horizon at night.

## Collection and recipe upgrades

Production cash must be collected at your own register. **Stand on its gold collection pad** or use the register's prompt. The Bakery menu only shows the balance and directs you there; it cannot collect remotely. The collection pad activates once per entry, so leave and return for another collection. NPC sale earnings also go into the collection balance. Purchased cash bundles, admin gifts, and existing quest prizes retain their documented destinations.

Every topping price now uses **base ingredient price + a percentage of that cookie's unlock price**, instead of making early cookies share the same minimum price. For example, Glaze costs $100 on Chocolate Chip and $162 on Oatmeal Raisin.

Toppings also has a new **cookie mastery** button for the selected recipe. Ten levels add **20% recipe value per level**. The first level costs `floor((100 + unlock price × 0.35) × 1.7^currentLevel)`. Mastery affects production and the quality of newly picked cookies; it does not retroactively change cookies already stored in your bag.

## Pick up, hold, and eat cookies

Nearby conveyor cookies show their recipe and current **inventory value**, including mastery, toppings, wrapping, and boxing. Hold their **Pick up • $value** prompt to store one. Only the owner can pick up cookies from their bakery.

Open **Bakery → Cookie bag • mine • machines**. Select a stored cookie to hold it as a Roblox Tool. Click/tap the equipped cookie, or use **Eat held cookie**, to eat it. Eating consumes exactly one item and gives a **90-second speed boost** plus a recipe-colored cookie pattern and a small random tint on your character. Chocolate Chip, for example, produces a tan skin with chocolate-colored chips. Another snack replaces the active food bonus rather than stacking unlimited speed. Original colors return after expiry. The buff keeps its original expiry through respawn/rejoin.

The bag starts with **20 slots** and can reach **40** through dough upgrades. Picked cookies are extra, bounded collectibles from representative physical production; they do not subtract cash already credited by the production clock. Their inventory values exclude global income passes/rebirth multipliers, while their own rarity, toppings, quality, packaging, and finishing still count. Trading, eating, selling, and baking all validate server ownership.

## Machines along the conveyor

Visit each purchase pad beside your own line:

| Machine | Wallet cost | Result |
| --- | --- | --- |
| Packager | $25,000 | +25% bakery production; cookies passing its arch gain a visible wrapper and 25% inventory value |
| Boxer | $250,000 | +50% bakery production; cookies passing its arch gain a shallow box and 50% inventory value |
| Finishing oven | $2,500,000 | Finish one held inventory cookie in 20 seconds for **3× inventory value**, once per cookie |

Wrappers and boxes attach without adding collision obstacles to the belt. Picking a cookie before an arch means it does not receive that arch's bonus. The finishing oven locks the item in your bag while baking; it cannot be eaten, sold, or traded during that time. The queue survives a normal departure and completes when its timestamp is reached. The oven must be purchased before use, and starting a finish requires being at its pad.

Cash-bought machines, cookie mastery, and toppings reset on rebirth. Stored cookies, dough, rolling pins, and dough upgrades survive. An unfinished oven job is canceled on rebirth and returns the original cookie to normal bag use.

## Roaming customers and bargaining

Customers walk along the public road. Hold a cookie, approach one, and use **Offer held cookie**. The People page shows their initial offer, around **120% of inventory value**.

- **Sell** consumes the offered cookie and adds the agreed amount to your register.
- **Pitch a higher price** can raise the offer, but each attempt risks annoying the customer. After three successful pitches, another attempt always makes them leave. You keep the cookie if bargaining fails.
- **Walk away** ends the conversation without a sale.

Stay near the customer and keep the cookie in hand. Conversations expire after 30 seconds. A customer talks to one player at a time. Bargaining choices are fixed game dialogue; players do not send custom text to other players.

## Cookie trades and gifts

Hold a cookie and **hold E on another player** to ask **“Want a cookie?”**. Both players see the proposed recipe names and values on People:

- If the other player is holding a cookie, the proposal exchanges those two cookies.
- If they hold none, the proposal is a gift of your cookie.

**Both players must confirm.** Either can decline. Offers expire after 45 seconds, require nearby living characters, and are checked again for ownership and space before saving. Items cannot be changed into different offers behind the confirmation screen. A changed/missing/busy cookie cancels the proposal instead of substituting something else.

Trading requires persistent profiles; the explicit session-only Studio preview disables it. A trade briefly pauses ordinary profile mutations. The server saves recovery references in both profiles before a separate journal commits the exchange. Per-profile apply markers prevent replays, and a rejoin resolves an interrupted exchange as either committed or canceled. If saving is unavailable, wait or rejoin when it recovers; do not rename/delete the player store or trade journal.

## Dough mine and rolling pins

The **Cookie Dough Mine** is west of the plaza, around `(-250, 100)`. Everyone receives a rolling-pin Tool. Equip it and hold E on dough ore to strike. Ore shows remaining HP, rewards dough when broken, and regenerates after ten seconds.

At the mine workshop, open Mine to upgrade:

| Rolling pin level | Wallet cost to unlock | Damage per hit |
| --- | --- | --- |
| 1 | Free | 1 |
| 2 | $5,000 | 3 |
| 3 | $50,000 | 7 |
| 4 | $500,000 | 15 |
| 5 | $5,000,000 | 30 |

Dough buys permanent **Mixing** (+10% production per level, 10 levels), **Flow** (+5% baking speed per level, 10 levels), and **Pockets** (+4 inventory slots per level, five levels). Their starting dough costs are 25, 30, and 20, doubling per level. Pins and dough upgrades survive rebirth. The ore's last successful miner receives that ore's reward.

## Obbys and quest navigation

Obbys now detect the actual floor/platform under a character with server raycasts rather than relying on a foot-height estimate and a sometimes-delayed grounded flag. Ordered checkpoints and timing still apply. A completed run remains eligible until the bonus is applied (or a stronger existing bonus is retained), and **Claim boost / return** cannot leave before completion registers. Wait on the finish if you arrive before the minimum course time. Easy/Medium/Hard still grant +10%/+30%/+50% for five minutes; a stronger active bonus is not replaced by a weaker one.

The HUD now includes a **heading compass, direction arrow, target name, and distance** for the next missing hunt item. A local guide beam points toward it. After all items are found, the guide returns to Baker Biscuit so you can claim the prize. Only your own current quest is guided.

## Save upgrade and playtest checklist

Save envelope **7** accepts versions 1–6 and preserves previous cash, paid boosts, receipts, audio, and quest progress. New inventory/dough/machine state lives in the existing `CookieCorner_PlayerData_v1` store. Trade recovery uses `CookieCorner_CookieTrades_v1`. Restart old servers; earlier writers must not drop the new ownership fields.

Automated tests cover inventory validation/capacity, values, buff expiry, costs and rebirth rules, finishing queues, bargaining outcomes, trade confirmation prerequisites, activity locks, journal abort/commit recovery, and lost save responses. Roblox Studio is still required for these engine checks:

1. Claim opposite bakeries and compare their mirrored layouts. Test road speed and Home, then confirm remote collection is disabled and both register/pad collection work.
2. Complete all three obbys with R6 and R15 avatars, including small/large scales and food speed buffs. Wait for the finish acknowledgement, return, and verify the correct timer.
3. Inspect cookie trees, mountains, the lake/bridge/waterfall, day/night lighting, and the cookie sun. Test swimming and Home from the lake. Check performance with eight clients and developed bakeries on your target devices.
4. Pick cookies before/after both machine arches. Check the visible wrapper/box and nearby price label, inventory value, stored quality, and that the rail remains clear.
5. Eat two different recipes, reset, wait for expiry, and rejoin before expiry. Verify speed and original avatar colors/pattern cleanup. Test alongside admin invisibility.
6. Mine every ore tier, upgrade pins, buy all three dough paths, fill the bag, rebirth, and rejoin. Check charges, damage, capacity, and permanent fields.
7. Finish a cookie, leave during baking, and return; verify the item is neither lost nor multiplied twice. Attempt eat/trade/sell while baking, and rebirth during a job.
8. Sell to roaming NPCs, walk away, leave mid-conversation, and over-pitch. Check that only a successful sale consumes the cookie and that proceeds reach the collection register.
9. With two persistent test accounts, trade, gift, decline, walk away, fill a bag, consume an offered cookie before confirming, and leave during saving. Rejoin both accounts and check each unique cookie exists in one inventory. Verify a non-admin cannot grant items or bypass proximity.
10. Test the bag, prompts, compass, Home, and all new pages with keyboard, touch, and controller. Retest existing rebirths, paid receipts, audio settings, and admin tools.
