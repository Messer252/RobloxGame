# Mine combat training and reliable obby prizes

## Learn a move

Visit the **cookie dough mine workshop** and open **Mine**. Combat Training appears above mine upgrades. Pay cookie dough to unlock a move, then select any owned move at the workshop to equip it for free. You can equip one E move and one Q move. All six are available without Robux.

| Key | Move | Dough | Cooldown | Effect |
| --- | --- | ---: | ---: | --- |
| E | Crumb Dodge | 100 | 6 seconds | Dash forward; avoid rolling-pin/monster combat damage for 0.4 seconds |
| E | Rolling Spin | 300 | 9 seconds | Animated spinning sweep, 10-stud radius, 1.4× pin damage |
| E | Sugar Guard | 500 | 14 seconds | Guard stance and visible shield; take 45% less combat damage for 2.5 seconds |
| Q | Cookie Slam | 150 | 10 seconds | Leap and deal 1.8× pin damage within 11 studs on landing |
| Q | Cocoa Burst | 450 | 12 seconds | Wind up a cocoa shockwave, 13-stud radius, 1.65× pin damage |
| Q | Crust Breaker | 800 | 16 seconds | Heavy forward strike, 15-stud reach, 2.5× pin damage |

Equip your rolling pin, then press E or Q. Touchscreen buttons show your equipped moves and cooldowns; controller L1/R1 use E/Q respectively. Visible E interaction prompts take priority, so shopping, cookie pickups and gifting still work. Use the touch/click ability button if you intentionally want a move beside a prompt.

Moves require a living, grounded character to begin. Cookie Slam strikes only when it lands within its cast window. Death, rebirth, unequipping the pin or leaving the allowed range cancels a pending strike. Cooldowns are controlled by the server and changing moves cannot bypass them. Basic pin swings wait until the active move ends. Guard is a defensive stance, not a way to attack during damage reduction.

Abilities hit cookie monsters and the Colossus. They damage other players **only while both players are inside Cookie Hill**. Walls block ability damage. Dodge/Guard reduce combat damage, not falls or obby hazards. Obby courses and approaches disable abilities; admin flight/invisibility cannot be used to cast them.

Purchases and equipped slots save between visits. **Rebirth clears all ability unlocks and equipped slots**, along with bought mine upgrades, armor and pins. Unspent dough stays. This keeps combat training part of each bakery run.

Animation uses procedural R6/R15 joint poses, a spinning pin stance, guard shield and impact shockwaves. Existing PinSwing/OreHit cues respect your SFX settings. **No animation, audio or model upload is needed.**

## Obby finish fixes

A short landing could previously fall between periodic checks. That left a required platform unrecorded, so reaching the finish silently failed. Landing contact events now complement the standing check, and extremely brief legitimate landings no longer fail an arbitrary per-platform delay. The standing check ignores other players, tools and scenery that could obscure its floor ray.

Start at the green pad and land on each platform in order. The minimum course duration still applies, and duplicate contacts cannot skip stages. Falls and red hazards still restart the course. If a platform was skipped or the run never started, the game now explains what happened.

A validated finish creates a pending claim. If your profile is temporarily busy with a purchase or gift save, the claim retries in that server until it can pay. You can move away or respawn without invalidating an already validated finish. The claim pays once and can never be mistaken for another course's prize. Leave the server only after the payout message; an uncommitted pending claim is not stored across logout.

The finish's **Return to plaza** prompt also retries validation/payment before teleporting you. It cannot return you as though you had won without confirming the prize first.

Rewards remain:

- Easy: +10% cookie income for five minutes; 20 base Star Crumbs.
- Medium: +30% income for five minutes; 35 base Star Crumbs.
- Hard: +50% income for five minutes; 50 base Star Crumbs.

A stronger active boost is kept. Star Crumbs have a saved five-minute cooldown per difficulty; the finish message now shows when that prize is available again, or says the crumb wallet is full. Equipped card bonuses can increase the crumb award. Valid completions still progress obby quests during those cooldowns.

## Update and playtest

This is included with the [night/progression update](NIGHT-AND-PROGRESSION.md), using save format 12 and the existing DataStore names. Keep your configured audio/image/product IDs and admin usernames when copying the update into your place. Publish into the same experience and restart outdated servers.

Automated tests cover buying/equipping, malformed saves, cooldown bypass attempts, pose bounds, defenses, damage regions, rebirth/rejoin, quick obby landings and claims delayed by saves. Before publishing broadly, check in a two-player Studio test:

1. Buy/equip every move at the mine. Verify E prompts still open shops/pickups and mobile ability buttons remain reachable.
2. Test each animation on R6 and R15. Dodge toward a wall; it should stop safely. Unequip or die during a windup and confirm it does not hit afterward.
3. Fight on the hill, then outside it. Only the hill should allow player damage. Test armor, food buffs, Dodge and Guard against monsters and another player.
4. Finish all three obbys with quick consecutive jumps, while another avatar stands nearby, and during a temporarily busy save. Verify one prize, the correct difficulty, a clear message, and no replay by pressing Return repeatedly.
5. Verify that no E/Q move can bypass the obby, that red hazards still restart, and that rebirth removes moves without erasing unspent dough.

Studio physics, animation rendering, pathfinding and live DataStores are not executable in the cloud test environment; those checks still need Studio.
