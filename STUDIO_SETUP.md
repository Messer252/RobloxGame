# Cookie Corner Tycoon: full Roblox Studio setup guide

This guide takes you from the supplied game file to a published, playable Roblox game. You do not need a terminal, Rojo, or any plugins when using the ready-made place file.

For the card illustrations, Bubby's voice recordings, meteor crash, and optional full music mix, follow the separate [audio and TCG artwork upload guide](UPLOAD-ASSETS.md). OGG audio is supported.

The place includes all game scripts, 30 cookie models, 20 bakery props, three merging physical conveyors per bakery, rarities, toppings, Golden Chip rebirths, NPC scavenger hunts, calm music, and progress saving. Robux purchases remain disabled until you configure your own offers.

## 1. Download the game and install Studio

1. [Download CookieCorner_Studio.zip from GitHub](https://github.com/Messer252/RobloxGame/raw/refs/heads/main/CookieCorner_Studio.zip). Extract the ZIP to get **CookieCorner.rbxlx**, the complete game. On Windows, right-click the ZIP and choose **Extract All**; on Mac, double-click the ZIP. You can also open [the place file on GitHub](CookieCorner.rbxlx) and click **Download raw file**.
2. Install [Roblox Studio](https://create.roblox.com/docs/studio/setup) on a **Windows PC or Mac**. Studio does not run on a phone or tablet.
3. Open Studio and sign in to the Roblox account that will own the game, or an account with permission to publish for your group.

Use **CookieCorner.rbxlx**, which is the complete place. The free-assets ZIP contains reusable art; opening that alone does not install the game.

The ready-to-open place and game ZIP are available at the **top level of this GitHub repository**. If you use GitHub's **Code → Download ZIP** instead, extract that repository ZIP and find `CookieCorner.rbxlx` inside `RobloxGame-main`. You do not upload the `src` or `assets` folders to Studio. The developer-only `build/` folder remains ignored; see [Building a place from GitHub](#building-a-place-from-github) only if you want to rebuild the source yourself.

## 2. Open the place file

1. In Studio, choose **File → Open from File** and select `CookieCorner.rbxlx`. Some versions shorten this to **Open**.
2. Open **Explorer** from the **Window** menu or **Home** tab. On older Studio layouts, panels may be under **View**.
3. Open **Output** from the **Window** menu or **Script** tab. This is where script errors and saving messages appear.
4. Confirm that Explorer contains these objects:

   ```text
   ReplicatedStorage
     CookieTycoon
   ServerStorage
     CookieCornerAssets
   ServerScriptService
     Tycoon
       Settings
   StarterPlayer
     StarterPlayerScripts
       TycoonUI
   ```

**An empty-looking map before Play is expected.** The server builds the plaza, eight bakeries with merging conveyors, ovens, purchase pads, and Baker Biscuit's hidden items when a game session starts. The reusable models are stored in ServerStorage until then.

You do not need to insert the models again or upload the PNG textures to make the supplied place work.

## 3. Optional: preview immediately before publishing

The default game requires a successful save-data connection before letting a player join. An unpublished local file cannot use the normal Roblox DataStore, so enable the temporary Studio preview first:

1. Make sure no playtest is running.
2. In Explorer, expand **ServerScriptService → Tycoon**.
3. Double-click **Settings**.
4. Change only this line:

   ```lua
   AllowStudioSessionOnly = true,
   ```

5. Start a player playtest using the toolbar's **Play** button. Depending on your Studio version, select **Test** or **Play** in the testing dropdown; do not choose **Run**, which does not create your player.
6. Wait for the world to load, claim a bakery, and try the controls in step 6 below.
7. The HUD should say **Preview • not saved** when the temporary fallback is being used. You may also see a **STUDIO SESSION ONLY** notice. That session's progress does **not** save, and purchases are disabled.
8. Click **Stop**. In Settings, change the line back to:

   ```lua
   AllowStudioSessionOnly = false,
   ```

This option only permits a temporary fallback when Studio cannot access saved data. It does not bypass a profile locked by another session, and it is ignored by live Roblox servers. If Studio already has API access, it can still load real saved data even with this option enabled.

Make script changes while the playtest is stopped. Ordinary edits made inside a running simulation are discarded when it ends.

## 4. Publish your game to Roblox

1. Stop the playtest.
2. Choose **File → Publish**. Older Studio versions call this **Publish to Roblox**.
3. For a new game, fill in the game details. If Studio asks for a creator, choose your account or the intended group.
4. Suggested name: **Cookie Corner Tycoon**.
5. Suggested description:

   > Build your own cookie conveyor! Unlock 30 recipes, add glaze and sprinkles, upgrade your bakery, and rebirth for Golden Chips. Help Baker Biscuit find hidden treasures for bonus cash. Your progress saves between visits.

6. Complete the initial **Save/Create** dialog. Keep the game restricted to yourself or invited testers while checking it. If Studio shows release or audience options, leave access restricted until step 9.
7. Wait for Studio to confirm the upload succeeded.
8. Open [Creator Dashboard → Creations](https://create.roblox.com/dashboard/creations), choose the correct creator account/group, and select your game.

If you **already have a Roblox game** and want to replace its place with this file, use **File → Publish As** / **Publish to Roblox As…**. Select the existing game and its **start place**, then overwrite that place after saving a backup of anything you want to keep. Do not add the file as an unrelated extra place: players join the start place by default.

Publishing to GitHub or publishing a Codex environment does not upload a game to Roblox. This Studio publishing step does.

### Set the server size to eight players

The game has eight bakery plots:

1. In Creator Dashboard, open your game.
2. Go to **Configurations → Places** and select the **start place**, marked with a star.
3. In that place's settings, find **Maximum Players**, set it to **8**, and save the change. Some Studio versions also expose the place configuration through **Experience Settings → Places**.

A larger server size does not create more bakeries. Extra players would have to wait for an available plot.

## 5. Set up saving correctly

### Play in the Roblox app: no API toggle needed

Once published, the game uses Roblox DataStoreService in live Roblox servers automatically. You do not need an API key, an external database, or **Allow HTTP Requests**.

Keep **ServerScriptService → Tycoon → Settings** configured as supplied:

```lua
DataStoreName = "CookieCorner_PlayerData_v1",
AutosaveSeconds = 45,
SessionLeaseSeconds = 180,
AllowStudioSessionOnly = false,
```

Those are entries inside the existing `return { ... }` table; do not replace the entire script with just these lines.

Keep the same **game/experience** and DataStore name when publishing updates. A different experience has separate saves, even if its scripts use the same name.

### Optional: test persistent saves inside Studio

Roblox disables Studio access to DataStores by default. For Studio persistence testing, use a **separate published test experience**:

1. With the playtest stopped, use **File → Publish As** to create a separate game named something like **Cookie Corner TEST**.
2. Confirm Studio is now editing that test experience.
3. Open **File → Experience Settings**; older versions call this **Game Settings**.
4. Select **Security**.
5. Turn on **Enable Studio Access to API Services**, then click **Save**.
6. Leave `AllowStudioSessionOnly = false` so a save failure is visible instead of becoming a temporary preview.
7. Start a player playtest.

Studio uses the published experience's actual data. Keep this API toggle off for the production game and use the test copy for Studio persistence checks. The test copy's progress will not transfer to the production experience.

When you finish, reopen the intended production game using Creator Dashboard's **Edit in Studio** before publishing production changes. Check the name so you do not accidentally publish an update to the test copy.

## 6. Test the gameplay

You can do these checks in the temporary preview, the published Studio test copy, or the Roblox app as an authorized player.

1. Walk to an unclaimed bakery's green claim pad. Use the **Claim free bakery** prompt; on a keyboard, tap the displayed key (normally **E**) once. There is no held delay.
2. Claiming moves you beside your free Chocolate Chip oven and the first cookie purchase. Your bakery has **three feeder lanes merging into one delivery belt and box**. After building the first line, Chocolate Chip produces automatically; a fresh profile earns **$5 per batch about every three seconds** before upgrades.
3. First use **Build Conveyor** beside your starter oven to build the free first line. Production starts after construction. Stand on your register's **gold collection pad**, or use its **Collect cash** prompt to move earnings into your wallet. Waiting builds uncollected earnings; it does not spend or collect them for you.
4. Open **Bakery**. The five tabs are **Bakery**, **Toppings**, **Quests**, **Shop**, and **Audio**. Bakery lets you buy recipe/speed upgrades remotely; collecting cash, constructing lines, and purchasing decorations require visiting your own pads. **Golden Chips & rebirth** expands the permanent upgrades and rebirth controls.
5. Collect **$250**, then stand on the highlighted **Oatmeal Raisin** purchase pad for about **0.28 seconds**. No key or held prompt is needed. It buys once, reveals the next station, and both starting recipes produce **$17 per batch** before other upgrades. Only unlocked ovens and the next purchase appear; progression continues along the same belt.
6. In **Toppings**, select Chocolate Chip. Buy **Glaze** for $100: its value should become $6. Later, add **Sprinkles** for $350: with both toppings, its rounded value should become $7.
7. Check that toppings apply to the selected recipe, and that its button changes to **✓ Added** after a purchase. Other recipes have separate topping purchases.
8. Buy the first **$500 speed upgrade**, using **Faster conveyor** in Bakery or standing on your physical speed pad. Check that the batch interval changes from 3 to 2.4 seconds. Step off and re-enter a physical pad before buying another level; remaining on it must not repeatedly spend your cash.
9. Browse later recipes to see the higher rarity tiers and their value bonuses. These are fixed recipe rarities, not random drops. Reset your character and check that you respawn beside your own starter oven while you own the bakery.
10. Visit **Baker Biscuit** in the plaza, use his talk prompt, and press **Ask for a task**. Check **Quests** for a randomized activity such as mining, baking, selling, or an occasional search, then return to claim its cash reward. The tracker opens anywhere; accepting and claiming require standing near Biscuit. See [the quest guide](QUESTS.md).
11. Open **Shop**. **Coming soon** is correct while the offer IDs are still `0`.
12. Check **Output** for script errors and save warnings.

Beside the Bakery button, **Music ON/OFF** and **SFX ON/OFF** control audio independently. Two **0–100% volume sliders** in **Bakery → Audio** save separate music and SFX levels. The new **Valley Afterglow** built-in score plays without an upload. The ZIP includes `CookieCornerCafe.wav`, its optional full mix; upload that and set `AudioConfig.MusicAssetId` only if you want to use the recording. See [the audio setup guide](AUDIO.md). Sound effects work immediately.

For a longer progression test, expand **Bakery → Golden Chips & rebirth**. The first rebirth needs **18 recipes** and **$5 million in wallet cash plus uncollected earnings**. Cancel the confirmation once to check that nothing resets. On a confirmed rebirth, expect **5 Golden Chips**, reset cash/recipes/speed/toppings, and preserved permanent Golden Chip upgrades. Owned passes, permanent paid income tiers, audio preferences, and quest progress also survive rebirth. Active obby timers retain their original expiry. Claimed quest cash follows the normal cash reset, and completed hunts do not become repeatable.

Visit the three obbys in the east meadow. Easy grants +10%, Medium +30%, and Hard +50% cookie income for five minutes. Land on every platform in order; falling returns you to the start. Use the finish prompt to return to the plaza. See [the expansion playtest guide](EXPANSION.md) for conveyor, eight-player, obby, NPC, and leaderboard checks.

## 7. Verify that leaving and rejoining restores progress

Use a persistent session, not one labeled **Preview • not saved**. The best final check is in the regular Roblox app:

1. In Creator Dashboard, copy your game's Roblox URL from its options menu, or open its Roblox details page.
2. Sign in as the creator or another player with access and press the green **Play** button. This launches the Roblox app. Keep access restricted while testing.
3. Claim a bakery, collect some cash, unlock a recipe, and buy a topping or speed upgrade. Accept a quest and find one item too.
4. Leave some earnings uncollected too, so you can check both balances.
5. Wait roughly **60 seconds** to allow an autosave and check the HUD for a successful saved status.
6. Leave the game normally, then join the **same experience with the same account**.
7. Claim any available bakery. Your wallet, saved uncollected earnings, recipes, toppings, speed levels, rebirths, Golden Chips, and permanent upgrades should return. Verify your audio choices and active quest's found items too.

You must claim a plot on every visit; the plot itself is not permanently reserved. Income starts after claiming, and there is **no offline income** while logged off.

If the game says your bakery is still open in another server, close the other session and wait up to **three minutes** before trying again. A crashed session can leave a temporary save lock. Do not rename or delete the DataStore to clear this message.

## 8. Test multiplayer and supported devices

1. In Studio's testing dropdown, select **Server & Clients**, choose **2** clients, then start the test.
2. Have each player claim a different bakery. Repeat with **8 clients** to verify all eight plots and check performance on your target devices.
3. Confirm that collecting or buying on someone else's plot has no effect on their money or upgrades.
4. Buy a topping for one player and check that the other player's cookies do not change. Have both accept the same quest, then find an item as one player: the second player's item and progress must remain available.
5. Reset a character and confirm it returns to its owner's bakery. Have one player leave and confirm that their plot becomes available to claim without retaining that player's progress.
6. End the whole test session using **End Session** / **Cleanup**.
7. Use Studio's **Device Simulator** to check the menu on a phone-sized screen. Check all five tabs, scrolling, topping arrows, the collapsed Golden Chips section, step-on purchase pads, and instant prompts. If you plan to enable consoles, test controller input too.

Use the published test experience with Studio API access for saved multiplayer tests. The temporary preview can also be used when API access is unavailable. With API access disabled and the fallback left false, the test players will be unable to load their profiles.

Only advertise device support you have checked. Start with desktop, then enable other supported devices in the game's settings after checking their controls and layout.

## 9. Make it playable by other people

Uploading the place and releasing it publicly are separate steps. Restricted/private access lets authorized people test; public access lets eligible Roblox users discover and join it.

1. Finish the gameplay and save checks above.
2. Complete the publishing/release flow shown by Studio or Creator Dashboard, including Roblox's **Maturity & Compliance** questionnaire. Answer based on the actual content in your game.
3. Follow the eligibility checks Roblox shows for your account and chosen audience. Requirements can include age checks, verification, 2FA, and additional review or eligibility for younger audiences. A public release does not automatically grant all-ages access. See the [current official release requirements](https://create.roblox.com/docs/production/publishing/publish-games-and-places#release-requirements).
4. In Creator Dashboard, open your game and go to **Publish settings → Manage Audience → Manage access**. In layouts using the older navigation, look for **Audience → Access Settings** or **Privacy**.
5. Choose **Public** access. If you want everyone eligible to join rather than only friends, turn off the **Friends** restriction. Save the access changes.
6. Review the allowed ages, regions, and supported devices. Complete any remaining release requirements shown by Roblox.
7. Copy the Roblox game-page link and send that link to players. They join using the green **Play** button in the Roblox app.
8. Ask an account without creator/edit permissions to open the link and confirm it can join under your chosen audience settings.

For testing with friends before public release, use Roblox's early-tester/playtester invitations and permissions. Your own ability to join does not prove that everyone else has access.

## 10. Optional: upload the PNG textures

The game is already playable with its included models and native Roblox materials. Uploading the extra images is optional.

1. Download and extract **CookieCorner_FreeAssets.zip** from the chat, or get the `assets/textures` folder from GitHub using **Code → Download ZIP**.
2. Open the published game in Studio.
3. Open **Asset Manager** from **Window** or **Home** and use its import control to upload the desired PNGs under the appropriate creator account/group.
4. Wait for Roblox to process the images, then copy their image asset IDs.
5. Open **ServerScriptService → Tycoon → AssetTextures**.
6. Replace an empty string in the matching slot with the actual numeric image ID, kept inside quotes. For example, a bakery-floor ID belongs in `BakeryFloor`.
7. Restart the playtest to rebuild the world with those textures, then publish the update when satisfied.

See [the asset guide](assets/README.md) for the full inventory and texture mapping. Empty IDs keep the built-in materials. You do not need to upload all 42 images at once.

## 11. Optional: enable Robux purchases later

Sales are intentionally disabled in this build, as requested. Leave the IDs at `0` if you are not ready to sell anything.

When ready, create offers belonging to this exact production experience in **Creator Dashboard → Monetization**:

| Offer type | Offer | Studio configuration |
| --- | --- | --- |
| Pass | Permanent 2× cookie income | `Passes.DoubleIncome.Id` |
| Pass | Permanent 2× baking speed | `Passes.DoubleSpeed.Id` |
| Developer product | $10,000 cookie cash | `Products.CashSmall.Id` |
| Developer product | $100,000 cookie cash | `Products.CashMedium.Id` |
| Developer product | $1,000,000 cookie cash | `Products.CashLarge.Id` |

Set your prices in Roblox. Paste the corresponding pass/product IDs into **ReplicatedStorage → CookieTycoon → ShopCatalog**, replacing only the matching zeros. Publish the updated place to that same experience.

Follow [the full monetization guide](MONETIZATION.md) for creation, testing, and reward verification before enabling live offers. A test experience needs its own offers. Purchases in the live Roblox app can spend real Robux.

The speed pass speeds up baking. Bought cash resets on rebirth; permanent passes remain owned. Roblox supplies prices and purchase confirmation prompts.

## 12. Publish future updates without losing saves

1. Open the intended production start place from Creator Dashboard's **Edit in Studio**, or open an updated ready-made place file.
2. Stop any playtest before editing.
3. If editing the production start place directly, choose **File → Publish**. If importing a new local file, choose **Publish As**, select the existing production game and its start place, and overwrite that place.
4. Keep `CookieCorner_PlayerData_v1` and the current save code. Publishing an updated place does not itself erase player progress.
5. In Creator Dashboard, use **Configurations → Server management → Restart Servers** and select outdated servers when the update needs everyone on the new code. In particular, restart older servers when rolling out this version's inventory and trade save format.
6. Join through the Roblox app to check the published update.

The current **version-9 save envelope** accepts versions **1–8** and preserves progression, receipts, quests, and audio including cookie armor and saved daily/trail/obby reward cooldowns. Earlier game versions cannot read version-9 records. Keep `CookieCorner_PlayerData_v1` and do not roll back to older save code after players have saved with this build.

Keep these three copies in mind:

| Location | What it contains | How to update it |
| --- | --- | --- |
| GitHub | Source code and reusable assets | Commit and push source/art changes |
| Your `.rbxlx` / open Studio project | The editable place | Save locally or synchronize/rebuild from source |
| Roblox | The uploaded version players join | Publish from Studio |

Edits made only in Studio do not automatically update GitHub. A GitHub push does not automatically update Roblox. Also, opening an older downloaded place and publishing it can overwrite newer Studio changes, including configured offer or texture IDs; carry those settings into the updated file first.

## Troubleshooting

| What you see | What to check |
| --- | --- |
| The editor looks empty | Expected before Play: the scripts generate the world when the server starts. |
| Only models appear, with no working game | Open the complete `CookieCorner.rbxlx`, not just the asset pack. Check the script hierarchy in step 2. |
| No character or player menu | Start a player **Test/Play** session instead of **Run**. |
| “Your bakery could not load” in Studio | Publish a separate test experience and enable Studio API access, or use the explicitly temporary preview in step 3. Read Output for the actual error. |
| “Your bakery could not load” in the Roblox app | Check service status/errors and rejoin. The Studio API toggle does not control live-server saving. Do not delete saved data to fix access errors. |
| “Preview • not saved” / “STUDIO SESSION ONLY” | Progress will not save in that temporary session. Use a persistent test experience or the Roblox app for saving checks. |
| “Your bakery is still open in another server” | Close other sessions, wait up to three minutes, and rejoin. |
| “Your save needs a compatible game version” | Join a server running the latest game code; restart outdated servers. Keep the current ProfileStore and the existing DataStore name. |
| No money is being produced | Claim a free bakery. Collect the accumulated earnings into your wallet before buying. |
| Progress appears missing | Use the same Roblox account and experience, claim a bakery, and confirm the DataStore name has not changed. Temporary preview progress and test-experience saves are separate. |
| A cookie pad does not purchase | Collect cash into your wallet, stand on your own highlighted next-cookie pad for about 0.28 seconds, and step off before trying another purchase. You cannot buy on another player's plot. |
| Only one or two ovens appear | Expected at the start: future stations reveal in order as you unlock recipes along the belt. |
| “Visit Baker Biscuit” on a quest button | The tracker works anywhere, but starting and claiming require being near Biscuit in the plaza. |
| The Shop says “Coming soon” | Expected until you create your own offers and configure their IDs. |
| Friends cannot join | Check release completion, audience permissions, friends restrictions, age/region eligibility, and the exact game-page link. |
| A PNG is missing | Check the uploaded image ID, creator permissions, and processing/moderation status. The game can use native materials without it. |
| The live game still has old features | Publish the intended start place, restart outdated servers, and rejoin. Saving locally or pushing GitHub alone does not publish. |

## Building a place from GitHub

Skip this section if you downloaded the ready-made `.rbxlx` or game ZIP above. This is the optional source-development route.

1. Download/clone this repository.
2. Install [Rojo 7.7.1](https://github.com/rojo-rbx/rojo/releases/tag/v7.7.1).
3. Open a terminal in the repository directory. Create a `build` folder if needed.
4. Run:

   ```sh
   rojo build default.project.json -o build/CookieCorner.rbxlx
   ```

5. Open that generated file in Studio and follow this guide from step 2. The build embeds the scripts and the model pack.

For live source editing, use `rojo serve default.project.json` with the Studio Rojo plugin. If you prefer to assemble the source manually, follow the exact script/model hierarchy in [README.md](README.md#open-in-roblox-studio), including the ModuleScripts nested under the Tycoon Script.

## Configure admin access

`unbenator` is already in **ServerScriptService → Tycoon → AdminConfig → Usernames**. Add friends' exact account usernames there, in quotes with commas, then publish and restart outdated servers. Admins open **Bakery → Admin tools**. See [ADMINS.md](ADMINS.md) for wallet/earnings gifts, moderation, teleports, invisibility, and stable user IDs.

## Before sharing the game

- [ ] The complete place is published to the intended production start place.
- [ ] Maximum Players is 8.
- [ ] Claiming, baking, collecting, recipe unlocks, and toppings work.
- [ ] Claiming and respawning place the owner beside the starter oven; three feeder lanes merge into one delivery belt and box.
- [ ] Step-on purchases trigger once per entry and cannot spend another player's cash.
- [ ] NPC hunts, per-player hidden items, and once-only rewards work and persist.
- [ ] Moving belts carry players and cookies toward the delivery box on both plot orientations.
- [ ] Easy/Medium/Hard obby bonuses and their five-minute expiry have been checked.
- [ ] Server cash/rebirth rankings update and Zach's Box is visible near spawn.
- [ ] Leaving and rejoining in the Roblox app restores progress.
- [ ] Multiplayer ownership and target-device controls have been checked.
- [ ] The chosen audience can join through the Roblox game-page link.
- [ ] Purchases remain disabled, or the configured offers have passed the monetization checks.

The place packager verifies all **77 source scripts**, the model pack, and the built-in music score. The Studio ZIP includes the original soundtrack WAV plus the new meteor warning and 8-bit crash WAVs. Built-in score/cues play immediately; uploaded full mixes are optional. Other original WAV effects remain in the repository. Roblox Studio and live-server gameplay, device, audio, saving, and transaction checks must still be completed in Roblox; the cloud environment cannot run the Roblox engine.

Official references: [Studio installation](https://create.roblox.com/docs/studio/setup), [publishing and audience requirements](https://create.roblox.com/docs/production/publishing/publish-games-and-places), [Studio DataStore access](https://create.roblox.com/docs/cloud-services/data-stores#enable-studio-access), [testing modes](https://create.roblox.com/docs/studio/testing-modes), and [server updates](https://create.roblox.com/docs/projects/update-games). Roblox's menu labels and release requirements can change; follow the current prompts if your layout differs.

For the map, Home button, cookie bag, eating, mining, machines, customer sales, trading, and quest clues, follow [the cookie valley guide](VALLEY.md). Before overwriting a customized place, copy your audio/product IDs and AdminConfig username additions into the new file.

For current controls, building, mining, free gifts, random jobs, buffs, scenery, and flight, use [WORKSHOP.md](WORKSHOP.md).

The latest [cards/events guide](CARDS-AND-EVENTS.md) covers the four-sheet TCG animal art upload, optional 150 Robux card-slot pass, Star Crumb balance, meteors, PvP hill, natural terrain, decorations, plot entrance layout, and rebirth cleanup. All card/crumb state persists through rebirth; bag cookies and conveyors now reset.

The [spawn market update guide](MARKET-UPDATE.md) covers the Pack House, Bruno’s blacksmith, armor, easier Star Crumbs, online hill ownership, decoration paths and the new Bakery → Audio settings location.
