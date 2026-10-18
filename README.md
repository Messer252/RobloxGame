# Cookie Corner Tycoon

A four-player Roblox cookie tycoon with 30 recipes, 15 oven levels, Golden Chip rebirths, three permanent upgrade paths, and saved progress. Claim any free bakery, bake automatically, collect earnings, and unlock recipes in order. The Bakery menu lets you collect and purchase from anywhere after claiming a plot; physical pads also work.

Recipes now have **six rarity tiers**, from Common (1×) to Mythic (6×). In the **Cookie Workshop**, buy Glaze, Sprinkles, Chocolate Drizzle, Caramel Swirl, and Gold Leaf for individual recipes to increase their value and add visible toppings. See [rarity, modifier, and workshop details](CRAFTING.md).

The lineup grows from chocolate chip and oatmeal raisin through peanut butter, snickerdoodle, red velvet, s'mores, matcha, birthday cake, galaxy brownie, and Golden Chocolate Chip. Each bakery has five rows of six ovens. Cookie animations are capped independently of production to keep late-game part creation bounded.

The game includes an original **free asset pack**: 30 cookie models, 20 bakery props, and 42 seamless PNG textures. Models already power the generated bakeries and animated cookies, using native Roblox materials. See [asset previews and import instructions](assets/README.md); the original assets are CC0, including for monetized games. Optional PNG image IDs are configured in `src/server/AssetTextures.luau` after uploading the images to Roblox.

The **Robux Shop** includes permanent 2× income and 2× baking-speed passes plus repeatable $10K/$100K/$1M cash bundles. Sales are disabled until you create the Roblox offers and enter their IDs. Follow the [step-by-step monetization setup](MONETIZATION.md). Roblox supplies live prices and confirmation prompts; the server verifies ownership and saves product rewards with their receipt IDs before acknowledging them.

## Open in Roblox Studio

**New to Studio? Follow the [full upload, saving, testing, and publishing guide](STUDIO_SETUP.md).** If you have the ready-made `CookieCorner.rbxlx` supplied in the chat, open it directly in Studio; no terminal or plugins are needed. The steps below are for building or assembling the GitHub source.

With Rojo **7.7.1** installed:

```sh
rojo build default.project.json -o build/CookieCorner.rbxlx
```

Create the `build` directory first if necessary, then open the generated place in Studio. For live editing, run `rojo serve default.project.json` and connect the Studio Rojo plugin.

Without Rojo, create this structure in a new Baseplate place and paste each file into the matching script. The modules under `Tycoon` must be children of that **Script**, not siblings:

```text
ReplicatedStorage
  CookieTycoon (Folder)
    Recipes (ModuleScript)          <- src/shared/Recipes.luau
    Progression (ModuleScript)      <- src/shared/Progression.luau
    ShopCatalog (ModuleScript)      <- src/shared/ShopCatalog.luau
    PurchaseRewards (ModuleScript)  <- src/shared/PurchaseRewards.luau
    CookieCrafting (ModuleScript)   <- src/shared/CookieCrafting.luau
ServerStorage
  CookieCornerAssets (Model)        <- insert assets/models/CookieCornerAssets.rbxmx
ServerScriptService
  Tycoon (Script)                   <- src/server/init.server.luau
    ProfileStore (ModuleScript)     <- src/server/ProfileStore.luau
    Settings (ModuleScript)         <- src/server/Settings.luau
    World (ModuleScript)            <- src/server/World.luau
    AssetLibrary (ModuleScript)     <- src/server/AssetLibrary.luau
    AssetTextures (ModuleScript)    <- src/server/AssetTextures.luau
    CommerceServer (ModuleScript)   <- src/server/CommerceServer.luau
StarterPlayer
  StarterPlayerScripts
    TycoonUI (LocalScript)          <- src/client/init.client.luau
```

The server generates the map and remotes. Set the experience's maximum player count to **4**, matching the number of bakeries. If more players join, they must wait for a plot to become available. Use proximity prompts with a keyboard, controller, or touch; the menu also supports touch and scrolling.

## Enable saving

1. Publish the place to a Roblox experience. Live servers use Roblox DataStoreService automatically; no external account keys are needed.
2. For Studio persistence checks, use a **separate published test experience** and enable **Studio Access to API Services** in its security settings. Studio can access that experience's real player data.
3. Press Play, earn money and unlock a recipe, then stop and rejoin. Claim any free plot: your saved cash, uncollected earnings, recipes, toppings, ovens, rebirths, Golden Chips, and permanent upgrades should return.

`src/server/Settings.luau` selects `CookieCorner_PlayerData_v1`. Keep the same DataStore name to retain saves. Changing it starts a separate save namespace.

Saves use `UpdateAsync`, a renewable three-minute session lease, three attempts per operation, autosaves about every 45 seconds, early checkpoints after rebirth, permanent upgrades, and modifier purchases, and final saves on departure and server shutdown. A newer session's token prevents an old server from overwriting it. Save problems appear in the HUD and server output. An unrecoverable load failure stops the join instead of creating a replacement profile. A failed departure or crashed server can leave its lease active for up to three minutes before a reconnect succeeds.

For offline Studio development only, explicitly set `AllowStudioSessionOnly = true` in Settings. If DataStore access is unavailable, Studio then starts a clearly labeled temporary session that **does not save**. This fallback never writes temporary data into a saved profile and is ignored on live servers. Locked or incompatible saves do not fall back.

No income accrues while logged off or before claiming a plot. The last saved uncollected earnings are retained. A server crash during a DataStore outage can roll back progress since the last successful save.

## Rebirth and Golden Chips

The first rebirth requires **18 unlocked recipes** and **$5 million in cash + uncollected earnings**, and awards **5 Golden Chips**. Subsequent requirements scale with your completed rebirth count `r`:

- Required recipes: `min(30, 18 + 2r)`.
- Required cash + bank: `min(100 billion, 5 million x 2.5^r)`. The cap keeps later rebirths reachable.
- Golden Chip reward: `5 + 2r`.
- Each rebirth adds another 15% to the rebirth income bonus. There are 50 rebirths available.

Rebirth requires confirmation and resets wallet cash, banked earnings, recipe unlocks, oven levels, and topping modifiers. It preserves rebirths, Golden Chips, owned passes, and these permanent upgrades:

| Upgrade | Effect | Levels | Next level cost at current level `l` |
| --- | --- | --- | --- |
| Golden Batter | +25% cookie income per level | 20 | `3 + 2l` Golden Chips |
| Golden Flame | +8% baking speed per level | 10 | `4 + 3l` Golden Chips |
| Golden Nest Egg | Start each rebirth with `$500 x level²` | 10 | `2 + 2l` Golden Chips |

Batter and rebirth income factors multiply. Oven upgrades and Golden Flame speed factors multiply, with a minimum ordinary 0.4-second production interval; the optional speed pass halves that interval further. Nest Egg applies when rebirthing; purchasing it does not immediately grant cash. Currency, costs, ownership, upgrade caps, and rebirth eligibility are enforced on the server.

With the rarity bonuses, the first-run simulation reaches rebirth in about 38 minutes of production with the tested recipe/speed purchase strategy, without buying toppings. This excludes travel and collection delays; it is a balance estimate, not an engine playtest.

## Validation

With the official Luau CLI installed, run from this directory:

```sh
luau tests/run.luau
find src tests -name '*.luau' -print0 | xargs -0 luau-analyze
```

The 54 deterministic tests exercise the actual economy and storage adapter with an in-memory DataStore: rebirth requirements and resets, upgrade costs and caps, save/rejoin restoration, retries, in-flight saves, conflicting sessions, stale writes, unsupported save formats, progression pacing, paid-pass stacking, receipt replay protection, lost purchase-save responses, rarity values, modifier stacking and encoding, duplicate topping purchases, and save migration. They do not contact Roblox's live DataStore or payment services.

To regenerate and check the original art, install Python 3, Pillow, and NumPy, then run `python tools/build_assets.py` and `python -m unittest discover -s tests -p 'test_assets.py'`. The eight asset checks cover model completeness, script-free contents, valid pivots and transforms, texture hashes, tiling edges, and game integration. Previews in `assets/previews` are offline renders of the geometry, not Roblox screenshots.

Complete these engine checks in Studio:

- Claim a bakery and confirm the initial chocolate chip oven adds $5 roughly every three seconds. Collect, buy oatmeal raisin for $250, and confirm both recipes contribute $17 per batch.
- Buy the first $500 oven upgrade and confirm the displayed interval drops to 2.4 seconds. Unlock later recipes and verify their ovens activate in the five-row layout.
- In Server & Clients mode, use two players. Attempt to collect, upgrade, or unlock recipes on the other player's plot: those requests must have no effect. Leave and verify the empty plot becomes claimable without giving its new owner the departing player's progress.
- In a private test experience, reach rebirth requirements. Review then cancel a rebirth and confirm nothing changes. Confirm a rebirth and verify the reset, 5-chip reward, and 15% income bonus. Buy a permanent upgrade, leave, rejoin, and verify the reward and upgrade persist together.
- Stop/rejoin with both wallet cash and uncollected earnings, plus unlocked cookies and oven upgrades. Verify all saved fields restore after claiming a different plot. Check server output for save errors.
- Check the scrolling menu, rebirth confirmation, and proximity prompts with Studio's mobile emulator and a controller.
- Before enabling sales, complete the [purchase checks](MONETIZATION.md#verify-before-enabling-live-offers) using offers belonging to a separate published test experience.
- Complete the [Cookie Workshop checks](CRAFTING.md#studio-checks) for topping visuals, per-recipe restoration, rarity labels, and the rebirth reset.

Roblox Studio/Roblox servers are required for engine, multiplayer, UI, and live persistence validation; the Linux cloud environment runs the deterministic tests, static analysis, compilation, and Rojo packaging.
