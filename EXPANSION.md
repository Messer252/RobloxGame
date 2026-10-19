# Eight-player map, conveyors, and obbys

Download the updated [Studio ZIP](https://github.com/Messer252/RobloxGame/raw/refs/heads/main/CookieCorner_Studio.zip), extract it, and open `CookieCorner.rbxlx` in Studio. Publish it to your existing start place, keep the existing DataStore name, and restart outdated servers. Set **Maximum Players to 8** in the start place's Creator Dashboard settings; a place file cannot change that account setting for you. Follow [the full publishing guide](STUDIO_SETUP.md).

## Map and conveyors

Eight claimable bakeries sit along an extended central path. Claiming and respawning still put you beside your starter oven and first purchase. Each bakery has three feeder lanes, ten ovens per lane, smooth curved merges, one shared delivery belt, and an open collection box. The collection register is beside the box.

The belts are now **9 studs wide**, with **1.8-stud-tall, 0.65-stud-thick rails**. Smooth curves replace the previous sharp diagonal junctions. Flat, overlapping belt panels and coplanar circular infill close the gaps at each bend. Rails are generated only around exposed boundaries; inner rails are clipped back before entering another lane, with rounded low-friction joints. Decorative supports, arrow markings, feed trays, and rail trim cannot collide with cookies. Oven counters and the toppings counter are moved clear of the wider tracks.

The belt surfaces use anchored `AssemblyLinearVelocity`, high-friction contact, and arrows derived from their actual world direction. They carry unanchored objects and characters standing on them. North and south bakeries reverse the world direction together, so arrows, movement, and collection stay aligned. Speed upgrades increase belt travel speed within a 12–22 studs/second cap.

Cookies are welded, server-owned physical models. A transparent cylinder provides their collision against belts, walls, boxes, and players. Cookie-to-cookie collisions are disabled to limit jams. Visible decorations stay welded to the body. An orientation constraint keeps each cookie flat. Gentle server-side velocity guidance follows the assigned feeder through the curve into the shared outlet, while preserving gravity and physical collisions; the cookie is never tweened or teleported along the route. Guidance stops at the delivery lip or when a cookie leaves the belt. The register still works as before, and the starter oven/purchase remain beside personal spawn. Each bakery caps representative cookies at ten, emits at most two per visual update, and cleans them up after collection or 30 seconds.

**Earnings still use the authoritative server production clock.** The physical cookies represent production; they are not a one-to-one cash ledger. Moving, blocking, or touching one cannot mint extra cash or steal another player's earnings. The box removes delivered models, and the register/menu collects the same saved earnings balance as before. Only unlocked ovens and the next purchase appear. Purchases still work by standing on the pad, once per entry.

## Obby rewards

The east meadow has three courses:

| Course | Platforms | Cookie income bonus | Duration |
| --- | --- | --- | --- |
| Easy | 10 | +10% | 5 minutes |
| Medium | 14 | +30% | 5 minutes |
| Hard | 18 | +50% | 5 minutes |

Stand on the start pad, then land on each platform in order. Falling onto the reset floor returns you to the start. The finish prompt returns you to the plaza after the finish has registered. The server checks living characters, grounded feet, ordered checkpoints, and minimum completion times. Clients cannot send a completion/reward request.

Only one obby bonus is active. Completing the same or a harder course starts a fresh five-minute timer; a weaker course cannot replace or refresh a stronger active bonus. Timers use real time and keep counting while logged off. Rebirth preserves the existing expiry rather than resetting it. The HUD shows the remaining time. Bonuses multiply other production bonuses and do not multiply purchased cash, quest cash prizes, or Golden Chips.

The Shop's separate [permanent income stages](MONETIZATION.md#permanent-escalating-income-upgrades) never expire and survive rebirth. Those purchases require your developer product IDs and matching Roblox prices before they can sell.

## Plaza details

Baker Biscuit is a standard Roblox R6 Humanoid character in chef clothes. The game requests a Roblox-generated avatar, with a standard R6 jointed fallback if avatar loading is unavailable. The original spoon, whisk, and sugar cube now use rounded metal geometry, curved whisk wires, and a granular sugar surface. They need no texture uploads.

Two boards rank **current-server players** by spendable wallet cash and rebirths, refreshing every two seconds. Ties use user IDs for stable ordering. These are not global or lifetime rankings. Roblox's player list also retains Cash, Rebirths, and GoldenChips. A taped cardboard box labeled **Zach's Box** sits beside the central spawn plaza.

## Playtest in Roblox Studio

The cloud cannot run Roblox physics, avatars, multiplayer, or purchase prompts. Complete these engine checks before sharing the update:

1. Start **Server & Clients** with eight clients. Claim every plot, reset characters, free/reclaim a plot, and check performance on your target devices. Verify distant plots are reachable along the path.
2. Test both map orientations. Stand still on each feeder and merge: the belt must carry you in the arrow direction. Follow cookies through left, center, and right merges into the box at both ordinary and maximum travel speed. Let several batches run from all three lanes, including all 30 recipes with toppings. Check that no rail ends cross the merge, the wider track clears oven counters, every curve is supported at one height, and cookies drop into the box. Push a cookie toward a rail and verify it slides past without tipping; push one off and confirm gravity takes over. Verify its decorations stay attached. Also stand on the moving curve as a player.
3. Confirm collecting cash works even if a cookie is blocked or falls off, and touching a cookie/box cannot grant duplicate earnings. Leaving/rejoining restores the bank, not discarded physical cookie instances.
4. Complete all three obbys. Check +10%, +30%, and +50%, the HUD countdown, expiry after five minutes, stronger/same-course refresh, weaker-course rejection, fall reset, and return prompt. Skipping a checkpoint, jumping straight to the finish, or resetting a character must not grant the bonus.
5. Rebirth with a boost active, then leave and rejoin. Verify the permanent tier stays and the obby keeps its original wall-clock expiry. Check a temporary bonus expiring while logged off.
6. Verify Biscuit's character and prompts in online and asset-unavailable previews. Complete a hunt and inspect the spoon, whisk, and sugar cube on mobile too.
7. Collect/spend wallet cash and rebirth as different players. Verify both plaza rankings update, departure removes the row, and Zach's Box label is readable.
8. Before enabling sales, follow the [purchase checks](MONETIZATION.md#verify-before-enabling-live-offers), including cancel, durable receipt, next-tier eligibility, rebirth, and rejoin.

The deterministic conveyor checks use the actual floor/rail geometry and test **180 horizontal trajectories**: all 30 ovens at two speeds and three starting offsets. They check rail clearance, full cookie-footprint support across joints, curve continuity, outlet release, and counter clearance. These are geometry and steering checks, not a Roblox physics simulation.

Save envelope **6** migrates versions 1–5. Keep `CookieCorner_PlayerData_v1` and the latest save code; older servers cannot read the new envelope. Studio's optional session-only preview does not save and disables purchases.

The [cookie valley update](VALLEY.md) adds mirrored plots, travel, scenery, inventory, machines, mining, trading, and improved obby finish detection. Use its current playtest checklist alongside this guide.
