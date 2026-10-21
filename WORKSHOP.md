# Workshop polish update

Current reset rules, saving version and earnings are documented in [Night & progression](NIGHT-AND-PROGRESSION.md).

**Current controls and prices:** [Spawn market and bakery update](MARKET-UPDATE.md) covers armor, pin shopping at spawn, pack opening, daily rewards, fitted decorations and hill ownership.
**Latest behavior:** [Cookie animals and events update](CARDS-AND-EVENTS.md) supersedes older rebirth retention, terrain, entrance placement, decorations, and topping details below.
[Download the Studio game](https://github.com/Messer252/RobloxGame/raw/refs/heads/main/CookieCorner_Studio.zip). Extract it and open `CookieCorner.rbxlx`. Copy your customized product IDs, audio IDs (if you want an optional uploaded mix), and AdminConfig usernames before replacing your old place. Publish into the same experience and restart outdated servers.

## Hotbar, cave, and mining

**Cookie Bag** is now a Tool in the normal Roblox hotbar/backpack. Select it to open inventory; it puts itself away so you can choose a cookie or rolling pin. The Bakery shortcut also remains.

The dough mine is an enclosed rock cave west of the plaza with a timber entrance, layered roof, lanterns, and faceted dough deposits. Ore names and HP bars sit **above** each deposit and render in front of it. Equip your rolling pin and **left-click / tap the tool activation control** near a rock to swing. There is no E mining prompt. The server chooses the closest deposit in front of you within reach, checks the equipped pin and swing cooldown, and applies damage. Broken deposits hide their health bars and regenerate after ten seconds.

## Build the bakery

New players start with an unbuilt conveyor. Visit **Build Conveyor** beside the starter oven:

| Line | Cost | Access |
| --- | --- | --- |
| First | Free | First ten recipe stations and connected delivery outlet |
| Second | $10,000 | Middle line and recipes 11–20 |
| Third | $250,000 | Last line and recipes 21–30 |

Production starts after building the first line. The next recipe cannot be bought until its line exists. Existing saves from before this update retain all three built lines. Conveyors and purchased decorations reset on rebirth. Cards and Star Crumbs survive.

Buy **walls ($2,500), windows ($6,000), entrance/door ($4,000), plants ($750), and cookie trees ($1,500)** from the decoration pads at the rear of your own bakery. The Machines page shows these purchases too; you still need to visit the appropriate pads. These are cookie-cash purchases, with no Robux required. Purchases are checked and saved on the server.

Each recipe now has a themed enamel oven with recipe colors, matching trim, a cookie display, brass fittings, warm glass, and one of five different roof/body treatments. Cookie models have rounded baked shoulders and softer toppings. NPCs use standard Roblox rigs with original hair, hats, glasses, jackets, and shoes, in different colors and sizes. The world and model pack need no external image uploads.

## Packager fix

Packaging now runs with conveyor movement rather than a slower UI/update poll. The wrapping arch is at local belt distance **118.5** and the boxer at **122**, before the delivery lip at 126. Crossing a processing threshold applies the owned upgrade once, including when a fast cookie skips across a threshold between updates. Wrappers and boxes are welded visual parts with no collision. Nearby prices update immediately. Pickup before the arch keeps the earlier value; pickup after it includes the bonus. Production income retains the packager's 1.25× and boxer's 1.5× multipliers.

## Cookie effects

All **30 recipes have different effects**, shown in the bag before eating. Examples:

| Cookie | 90-second effect |
| --- | --- |
| Chocolate Chip | +8 running speed |
| Sugar Cookie | +4 jump height |
| Double Chocolate | +4 mining damage |
| White Chocolate Macadamia | +25% customer sale prices |
| Mint Chocolate | +14 running speed |
| Cookies & Cream | +25% production income |
| Galaxy Brownie | +6 running speed and +10 jump height |
| Toasted Marshmallow | +2 speed, +3 jump height, and 5 HP/second recovery |
| Golden Chocolate Chip | +5 speed, +2 jump, +5 mining damage, +40% production, +25% sales, and 2 HP/second |

Eating still changes your avatar's cookie colors/pattern. A new snack replaces the previous effect. Expiry, recipe, and pattern seed save; the remaining time is not refreshed by rejoining. Health recovery never revives a dead player or exceeds MaxHealth. Food does not multiply purchased cash, quest prizes, or the value stored on an inventory cookie.

## Customers and free gifts

Customers now have randomized **personality, favorite recipe, mood, patience, appearance, and budget**. Their initial offer varies; favorite cookies attract higher offers. Each pitch rolls a different increase and a rising rejection risk. Prices cannot exceed that customer's budget, and impatience can end the conversation sooner. Food sale bonuses influence the initial offer. Selling consumes one cookie and puts the proceeds in your collection register.

Hold E on another player while holding a cookie to offer a **free gift**. Both players receive an onscreen notification and a gift panel. The sender confirms sending; the receiver accepts or declines. **No cash, Robux, or return cookie is charged**, even if the receiver is holding a cookie. Their existing inventory stays theirs. Capacity, proximity, expiry, and ownership checks still apply. Saved transaction recovery protects an interrupted gift. Older unfinished exchanges can still recover through the existing journal.

## Quests and obbys

Item waypoints, guide beams, distance targets, and objective arrows have been removed. The compass has also been removed in the latest art update. Biscuit now gives randomized jobs for **mining, customer sales, eating, gifting, baking batches, finishing any obby, or finding two randomly selected supplies**. Search jobs use written clues. Rewards and required quantities vary, and the next job avoids the previous job type. Return to Biscuit to collect each reward once and ask for another job. After trying an unfinished job for 60 seconds, you can ask for a replacement. Job assignment and progress save. Previously active treasure hunts remain finishable before the new jobs begin.

All three obbys have narrower platforms, longer gaps, more height changes, and zigzags. **There are no numbered platform signs.** Start and finish signs remain. Every platform must still be landed on in order. Server floor detection and finish acknowledgement remain; a busy save delays acknowledgement until it can apply the bonus safely. Rewards remain +10%/+30%/+50% income for five minutes.

## Scenery, music, and admin flight

The valley now uses faceted pointed mountains and snowy summits instead of spherical mountains. The waterfall has a stepped slate cliff, a top stream, moving curved water ribbons, and foam/mist at the lake. Giant spherical meadow hills were removed. Leaderboards have brass frames, two posts, stone feet, individual alternating rows, highlighted top ranks, and aligned amounts.

The selected music is now **Valley Afterglow**, a new original 113-second, 68 BPM ambient loop. The game plays its quiet built-in score immediately, without using the friend's recording or needing an uploaded audio ID. Music and SFX keep their independent saved sliders/mutes. The ZIP includes `CookieCornerCafe.wav`, the full original mix; optionally upload it and set AudioConfig.MusicAssetId for that recording. The built-in sampler and uploaded full mix use the same composition but different instrument rendering. The earlier friend recording is retained in the repository as an archived file and is no longer selected or bundled in the Studio ZIP.

Admins open **Bakery → Admin tools → My flight**. WASD steers with the camera, Space rises, Ctrl/Q descends. Touch controls have up/down buttons and the normal movement stick. Movement is server-authorized for the configured admin's own character. Flight turns off on death, respawn, or departure and is not a saved entitlement.

## Save and Studio checks

Save envelope **9** accepts versions **1–8**, retaining the same `CookieCorner_PlayerData_v1` and trade journal. New saved fields include build tier, decorations, and the current randomized job. Keep the stores and restart older servers after publishing.

Automated checks cover the economy, packaging thresholds, unique buffs/expiry, customer rolls/budgets, job rewards/migration, gift persistence, and flight permissions. Roblox Studio is still required to verify:

1. Hotbar bag behavior, left-click/touch pin swings, ore selection and health bar visibility inside the cave.
2. A fresh profile's free first line, paid additions, recipe gating, decoration visibility/door clearance, rejoin, and an old profile retaining its built lines.
3. Packager and boxer visuals/prices at minimum and maximum production speeds, before/after pickup, on both mirrored sides.
4. All oven variants, customers and walking animations, waterfall, mountains, signs, day/night, and eight-player performance on target devices.
5. Every food effect, expiry/respawn, health cap, mining, production, sales, and interaction with admin invisibility/flight.
6. Gifts with two published test accounts: both notices, accept/decline, full bag, sender departure, receiver holding a cookie, and interrupted saving. Neither player's money should change.
7. All seven job types, swapping after a minute, search clues without waypoints, once-only rewards, rejoin, and completing a previously active hunt.
8. Three harder obbys with default R6/R15 avatars, finish retries during saving, and the correct boost timer.
9. Flight controls/cleanup on keyboard, gamepad movement, and touch; a non-admin must be unable to enable flight through remotes.
10. New music, sliders/mutes, rejoin, optional full-mix permissions, and no fallback to the friend's song.
