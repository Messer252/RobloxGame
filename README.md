# Cookie Corner Tycoon

**[Download the complete game for Roblox Studio](https://github.com/Messer252/RobloxGame/raw/refs/heads/main/CookieCorner_Studio.zip)**

Extract the ZIP, then open **CookieCorner.rbxlx** using Studio's **File → Open from File**. The scripts and models are included; no terminal, plugins, or manual assembly are needed. Follow [the full setup guide](STUDIO_SETUP.md) to preview, enable saving, and publish. You can also open [CookieCorner.rbxlx](CookieCorner.rbxlx) on GitHub and use **Download raw file**.

An eight-player Roblox cookie tycoon with 30 recipes, 15 baking-speed levels, Golden Chip rebirths, three permanent upgrade paths, and saved progress. Each bakery has **three wide, curved feeder conveyors merging into one delivery line**, with taller rounded rails, connected flat surfaces, ovens unlocked along the lanes, and a cookie collection box at the end. Claim a free bakery to arrive beside your starter oven and first purchase; respawning returns you there while you own that plot. Bake automatically, collect earnings, and progress along the belt.

Stand on your next cookie's purchase pad for about **0.28 seconds** to buy it with cookie cash; no held key is needed. Step off before buying again. The speed pad works the same way. The **Bakery** button opens four short tabs: **Bakery**, **Toppings**, **Quests**, and **Shop**. Unlock cookies or speed up production from Bakery; collect earnings at your own register or gold collection pad; expand **Golden Chips & rebirth** for permanent upgrades and rebirth confirmation.

See [the full cookie valley feature guide and playtest checklist](VALLEY.md) for mirrored plots, the fast road and Home button, cookie forests, lake/waterfall, mountain scenery, day/night and the cookie sun. Pick up, eat, sell, or trade stored cookies; buy conveyor machines, mine dough, upgrade rolling pins, and follow the quest compass. Nearby conveyor cookies show their current value. Cash from production and customer sales must be collected at your own register.

The [Workshop update](WORKSHOP.md) adds a hotbar cookie bag, left-click rolling-pin mining inside a cave, paid conveyor expansion and decorations, thirty different cookie buffs, recipe-themed ovens, varied NPC personalities/appearances, free gifts with notifications, randomized activity quests without waypoints, harder obbys, admin flight, and improved mountain/waterfall/leaderboard models. New players build their first conveyor for free; old saves retain built lines.

**Valley Afterglow** is a new original ambient soundtrack. Its built-in score plays immediately; an optional full WAV mix is included in the Studio ZIP. Music and SFX have separate saved mute buttons and 0–100% volume sliders. The friend's old song is no longer selected. See [audio setup](AUDIO.md).

Recipes have **six rarity tiers**, from Common (1×) to Mythic (6×). In **Toppings**, buy Glaze, Sprinkles, Chocolate Drizzle, Caramel Swirl, and Gold Leaf for individual recipes to increase their value and add visible decorations. See [rarity and topping details](CRAFTING.md).

Meet **Baker Biscuit** in the plaza for four saved scavenger hunts. Get randomized mining, selling, eating, gifting, baking, obby, or occasional search tasks in **Quests**, then return for a cash bonus. Old active hunts remain finishable. Job state survives rebirth and rejoining. See [quests and rewards](QUESTS.md).

The lineup grows from chocolate chip and oatmeal raisin through peanut butter, snickerdoodle, red velvet, s'mores, matcha, birthday cake, galaxy brownie, and Golden Chocolate Chip. Only unlocked ovens and the next purchase appear along the conveyor. Cookie animations are capped independently of production to keep late-game part creation bounded.

The game includes an original **free asset pack**: 30 cookie models, 20 bakery props, and 42 seamless PNG textures. Models already power the generated bakeries and physical cookies, using native Roblox materials. See [asset previews and import instructions](assets/README.md); the original assets are CC0, including for monetized games. Optional PNG image IDs are configured in `src/server/AssetTextures.luau` after uploading the images to Roblox.

The **Shop** tab includes permanent 2× income and 2× baking-speed passes plus repeatable $10K/$100K/$1M cash bundles. Sales are disabled until you create the Roblox offers and enter their IDs. Follow the [step-by-step monetization setup](MONETIZATION.md). Roblox supplies live prices and confirmation prompts; the server verifies ownership and saves product rewards with their receipt IDs before acknowledging them.

Try the **Easy, Medium, and Hard obbys** east of the bakeries for **+10%, +30%, and +50% cookie income for five minutes**. The strongest active bonus wins. The Shop supports permanent income stages starting at **2× for 20 Robux**, then **4× for 40**, doubling each stage; sales remain disabled until you create the matching developer products. See [map, conveyors, obbys, and playtest checks](EXPANSION.md) and [purchase setup](MONETIZATION.md). The plaza includes live server cash/rebirth rankings and **Zach's Box**. Biscuit now uses a standard Roblox R6 character with improved treasure props.

**Admin tools:** `unbenator` is configured as an admin. Add friends by account username in **ServerScriptService → Tycoon → AdminConfig**, publish, and restart outdated servers. Admins open **Bakery → Admin tools** to kick, return/teleport/bring players, grant wallet or uncollected cash, toggle self-invisibility, and fly. See [the admin setup guide](ADMINS.md).

## Open in Roblox Studio

**New to Studio? Use the game download above and follow the [full upload, saving, testing, and publishing guide](STUDIO_SETUP.md).** The steps below are for developers building or assembling the GitHub source.

With Rojo **7.7.1** installed:

```sh
rojo build default.project.json -o build/CookieCorner.rbxlx
```

Create the `build` directory first if necessary, then open the generated place in Studio. For live editing, run `rojo serve default.project.json` and connect the Studio Rojo plugin.

After changing source scripts or models, run `python tools/package_studio.py` with Rojo on your PATH (or pass `--rojo /path/to/rojo`) and commit both root download files. This rebuilds `CookieCorner.rbxlx` and `CookieCorner_Studio.zip`, checks that every script matches source, and verifies the ZIP.

Without Rojo, create this structure in a new Baseplate place and paste each file into the matching script. The modules under `Tycoon` must be children of that **Script**, not siblings:

```text
ReplicatedStorage
  CookieTycoon (Folder)
    BakeryPolish (ModuleScript) <- src/shared/BakeryPolish.luau
    BakeryContracts (ModuleScript) <- src/shared/BakeryContracts.luau
    BakeryLife (ModuleScript)       <- src/shared/BakeryLife.luau
    Recipes (ModuleScript)          <- src/shared/Recipes.luau
    Progression (ModuleScript)      <- src/shared/Progression.luau
    ShopCatalog (ModuleScript)      <- src/shared/ShopCatalog.luau
    PurchaseRewards (ModuleScript)  <- src/shared/PurchaseRewards.luau
    CookieCrafting (ModuleScript)   <- src/shared/CookieCrafting.luau
    AudioConfig (ModuleScript)      <- src/shared/AudioConfig.luau
    AudioPreferences (ModuleScript) <- src/shared/AudioPreferences.luau
    MusicScore (ModuleScript)       <- src/shared/MusicScore.luau
    ConveyorLayout (ModuleScript)   <- src/shared/ConveyorLayout.luau
    ConveyorRouting (ModuleScript)  <- src/shared/ConveyorRouting.luau
    ChallengeCatalog (ModuleScript) <- src/shared/ChallengeCatalog.luau
    Challenges (ModuleScript)       <- src/shared/Challenges.luau
    Boosts (ModuleScript)           <- src/shared/Boosts.luau
    MapLayout (ModuleScript)        <- src/shared/MapLayout.luau
    ObbyCatalog (ModuleScript)      <- src/shared/ObbyCatalog.luau
    ObbyProgress (ModuleScript)     <- src/shared/ObbyProgress.luau
    LeaderboardRanks (ModuleScript) <- src/shared/LeaderboardRanks.luau
ServerStorage
  CookieCornerAssets (Model)        <- insert assets/models/CookieCornerAssets.rbxmx
ServerScriptService
  Tycoon (Script)                   <- src/server/init.server.luau
    AdminConfig (ModuleScript)      <- src/server/AdminConfig.luau
    AdminPermissions (ModuleScript) <- src/server/AdminPermissions.luau
    AdminRewards (ModuleScript)     <- src/server/AdminRewards.luau
    AdminServer (ModuleScript)      <- src/server/AdminServer.luau
    AdminVisibility (ModuleScript)  <- src/server/AdminVisibility.luau
    ProfileStore (ModuleScript)     <- src/server/ProfileStore.luau
    BakeryFeatures (ModuleScript) <- src/server/BakeryFeatures.luau
    BakeryLifeServer (ModuleScript) <- src/server/BakeryLifeServer.luau
    CookieAppearance (ModuleScript) <- src/server/CookieAppearance.luau
    CookieCustomers (ModuleScript) <- src/server/CookieCustomers.luau
    CookiePackaging (ModuleScript) <- src/server/CookiePackaging.luau
    CookieTools (ModuleScript) <- src/server/CookieTools.luau
    CookieTrades (ModuleScript) <- src/server/CookieTrades.luau
    PlotMirror (ModuleScript) <- src/server/PlotMirror.luau
    ValleyWorld (ModuleScript) <- src/server/ValleyWorld.luau
    WorldWidgets (ModuleScript) <- src/server/WorldWidgets.luau
    DoughCave (ModuleScript) <- src/server/DoughCave.luau
    OvenDesign (ModuleScript) <- src/server/OvenDesign.luau
    BakeryDecorations (ModuleScript) <- src/server/BakeryDecorations.luau
    CustomerStyle (ModuleScript) <- src/server/CustomerStyle.luau
    AdminFlight (ModuleScript) <- src/server/AdminFlight.luau
    Settings (ModuleScript)         <- src/server/Settings.luau
    World (ModuleScript)            <- src/server/World.luau
    Presentation (ModuleScript)     <- src/server/Presentation.luau
    AssetLibrary (ModuleScript)     <- src/server/AssetLibrary.luau
    AssetTextures (ModuleScript)    <- src/server/AssetTextures.luau
    CommerceServer (ModuleScript)   <- src/server/CommerceServer.luau
    StepPads (ModuleScript)         <- src/server/StepPads.luau
    ChallengeWorld (ModuleScript)   <- src/server/ChallengeWorld.luau
    BakerAvatar (ModuleScript)      <- src/server/BakerAvatar.luau
    ConveyorWorld (ModuleScript)    <- src/server/ConveyorWorld.luau
    ObbyWorld (ModuleScript)        <- src/server/ObbyWorld.luau
    PlazaExtras (ModuleScript)      <- src/server/PlazaExtras.luau
StarterPlayer
  StarterPlayerScripts
    TycoonUI (LocalScript)          <- src/client/init.client.luau
      BakeryLifeClient (ModuleScript) <- src/client/BakeryLifeClient.luau
      AdminFlightClient (ModuleScript) <- src/client/AdminFlightClient.luau
      AudioController (ModuleScript) <- src/client/AudioController.luau
      VolumeSlider (ModuleScript)    <- src/client/VolumeSlider.luau
      AdminPanel (ModuleScript)      <- src/client/AdminPanel.luau
```

The server generates the map and remotes. Set the experience's maximum player count to **8**, matching the number of bakeries. If more players join, they must wait for a plot to become available. Recipe and baking-speed pads purchase when their owner stands on them; claim, register, counter, NPC, and hidden-item prompts activate without a held delay using keyboard, controller, or touch. The menu supports touch and scrolling.

## Enable saving

1. Publish the place to a Roblox experience. Live servers use Roblox DataStoreService automatically; no external account keys are needed.
2. For Studio persistence checks, use a **separate published test experience** and enable **Studio Access to API Services** in its security settings. Studio can access that experience's real player data.
3. Press Play, earn money and unlock a recipe, then stop and rejoin. Claim any free plot: your saved cash, uncollected earnings, recipes, toppings, speed levels, rebirths, Golden Chips, permanent upgrades, audio preferences, and quest progress should return.

`src/server/Settings.luau` selects `CookieCorner_PlayerData_v1`. Keep the same DataStore name to retain saves. Changing it starts a separate save namespace.

Saves use `UpdateAsync`, a renewable three-minute session lease, three attempts per operation, autosaves about every 45 seconds, early checkpoints after important upgrades and quest changes, and final saves on departure and server shutdown. A newer session's token prevents an old server from overwriting it. Save problems appear in the HUD and server output. An unrecoverable load failure stops the join instead of creating a replacement profile. A failed departure or crashed server can leave its lease active for up to three minutes before a reconnect succeeds.

The current **version-7 save envelope** accepts existing versions 1–6 and preserves progression, receipts, quests, and audio while adding inventory, dough upgrades, machines, and trade recovery. Keep `CookieCorner_PlayerData_v1` and restart outdated servers when publishing this update. Earlier game versions cannot open version-7 records.

For offline Studio development only, explicitly set `AllowStudioSessionOnly = true` in Settings. If DataStore access is unavailable, Studio then starts a clearly labeled temporary session that **does not save**. This fallback never writes temporary data into a saved profile and is ignored on live servers. Locked or incompatible saves do not fall back.

No income accrues while logged off or before claiming a plot. The last saved uncollected earnings are retained. A server crash during a DataStore outage can roll back progress since the last successful save.

## Rebirth and Golden Chips

The first rebirth requires **18 unlocked recipes** and **$5 million in cash + uncollected earnings**, and awards **5 Golden Chips**. Subsequent requirements scale with your completed rebirth count `r`:

- Required recipes: `min(30, 18 + 2r)`.
- Required cash + bank: `min(100 billion, 5 million x 2.5^r)`. The cap keeps later rebirths reachable.
- Golden Chip reward: `5 + 2r`.
- Each rebirth adds another 15% to the rebirth income bonus. There are 50 rebirths available.

Open **Bakery → Golden Chips & rebirth** to review rebirth or buy permanent upgrades. Rebirth requires confirmation and resets wallet cash, banked earnings, recipe unlocks, baking-speed levels, topping modifiers, cash-bought machines, and cookie mastery. Stored cookies, dough, rolling pins, and dough upgrades survive. It preserves rebirths, Golden Chips, owned passes, audio preferences, quest progress, and these permanent upgrades:

| Upgrade | Effect | Levels | Next level cost at current level `l` |
| --- | --- | --- | --- |
| Golden Batter | +25% cookie income per level | 20 | `3 + 2l` Golden Chips |
| Golden Flame | +8% baking speed per level | 10 | `4 + 3l` Golden Chips |
| Golden Nest Egg | Start each rebirth with `$500 x level²` | 10 | `2 + 2l` Golden Chips |

Batter and rebirth income factors multiply. Oven upgrades and Golden Flame speed factors multiply, with a minimum ordinary 0.4-second production interval; the optional speed pass halves that interval further, and dough Flow divides it by up to another 1.5. Nest Egg applies when rebirthing; purchasing it does not immediately grant cash. Currency, costs, ownership, upgrade caps, and rebirth eligibility are enforced on the server.

With the rarity bonuses, the first-run simulation reaches rebirth in about 38 minutes of production with the tested recipe/speed purchase strategy, without toppings or quest rewards. This excludes travel and collection delays; it is a balance estimate, not an engine playtest.

## Validation

With the official Luau CLI installed, run from this directory:

```sh
luau tests/run.luau
find src tests -name '*.luau' -print0 | xargs -0 luau-analyze
```

The 143 deterministic Luau tests exercise the actual economy and storage adapter with an in-memory DataStore: rebirth requirements and resets, upgrade costs and caps, save/rejoin restoration, retries, in-flight saves, conflicting sessions, stale writes, unsupported save formats, progression pacing, paid-pass stacking, receipt replay protection, lost purchase-save responses, rarity values, modifier stacking and encoding, duplicate topping purchases, save migration, persisted audio preferences, music/cue bounds, conveyor geometry and pad entry/retries, quest progress and rewards, eight-plot geometry, merging lane connections, ordered obby completion, timed bonus expiry, permanent tier migration/receipts, leaderboard sorting, rail clearance, connected floor coverage, 180 cookie trajectories through the curves, admin identity checks, protected actions, cash-grant limits, and gift save/rejoin behavior. Additional tests cover inventory, food buffs, dough upgrades, finishing queues, and durable trade commit/abort recovery. They do not contact Roblox's live DataStore or payment services.

To regenerate and check the original art, install Python 3, Pillow, and NumPy, then run `python tools/build_assets.py` and `python -m unittest discover -s tests -p 'test_assets.py'`. The eight asset checks cover model completeness, script-free contents, valid pivots and transforms, texture hashes, tiling edges, and game integration. Previews in `assets/previews` are offline renders of the geometry, not Roblox screenshots.

Run `python tools/build_audio.py` to regenerate the original audio and its shared Luau score. Four audio checks (`python -m unittest discover -s tests -p 'test_audio.py'`) verify WAV integrity, upload constraints, levels, silence-free bars, cue fade-outs, and loop continuity.

Complete these engine checks in Studio:

- Claim a bakery, build the free first conveyor, and confirm the initial chocolate chip oven adds $5 roughly every three seconds. Collect, buy oatmeal raisin for $250, and confirm both recipes contribute $17 per batch.
- Claim a plot and verify you arrive beside Chocolate Chip and the Oatmeal Raisin purchase pad. Reset your character and verify you return to your own bakery.
- Stand on Oatmeal Raisin's pad with $250 and verify one purchase after about 0.28 seconds, with no held key. Remain still: the next recipe must not buy automatically. Step off and walk to the next highlighted pad to continue.
- Stand on an unaffordable recipe pad, collect enough cash at the register, and confirm the pad buys once when the server is ready. It must recover from a temporarily busy action without requiring another entry.
- Buy the first $500 speed upgrade and confirm the displayed interval drops to 2.4 seconds. All ovens should feed the merging conveyor network, with later ovens revealed in sequence.
- In Server & Clients mode, use two players. Attempt to collect, upgrade, or unlock recipes on the other player's plot: those requests must have no effect. Leave and verify the empty plot becomes claimable without giving its new owner the departing player's progress.
- In a private test experience, reach rebirth requirements. Review then cancel a rebirth and confirm nothing changes. Confirm a rebirth and verify the reset, 5-chip reward, and 15% income bonus. Buy a permanent upgrade, leave, rejoin, and verify the reward and upgrade persist together.
- Stop/rejoin with both wallet cash and uncollected earnings, plus unlocked cookies and oven upgrades. Verify all saved fields restore after claiming a different plot. Check server output for save errors.
- Check the four tabs, collapsed Golden Chips section, rebirth confirmation, step pads, and instant prompts with Studio's mobile emulator and a controller.
- Before enabling sales, complete the [purchase checks](MONETIZATION.md#verify-before-enabling-live-offers) using offers belonging to a separate published test experience.
- Complete the [Toppings checks](CRAFTING.md#studio-checks) for decoration visuals, per-recipe restoration, rarity labels, and the rebirth reset.
- Complete the [graphics and audio checks](AUDIO.md#check-in-studio-and-roblox), including independent mute buttons, saved settings, two-client isolation, respawn, and uploaded-audio permissions if configured.
- Complete the [quest checks](QUESTS.md), including per-player hidden items, NPC proximity, save/rejoin, once-only rewards, and rebirth persistence.

Roblox Studio/Roblox servers are required for engine, multiplayer, UI, and live persistence validation; the Linux cloud environment runs the deterministic tests, static analysis, compilation, and Rojo packaging.
