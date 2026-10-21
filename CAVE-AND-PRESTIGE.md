# Cave, rebirth rewards, and PvP controls

[Download the updated Studio game](https://github.com/Messer252/RobloxGame/raw/refs/heads/main/CookieCorner_Studio.zip). Extract it and open `CookieCorner.rbxlx` in Roblox Studio.

## Cookie Dough Cave

The cave sits inside a continuous terrain mound with the valley's rock material and grassy roof. Its entrance has a cleared stone approach, timber supports and warm lanterns. Five connected galleries replace the old single room. The workshop remains at the entrance; Bruno in the side market sells the rolling-pin upgrades.

| Gallery | Required pin | Ore pool and respawn chances |
| --- | --- | --- |
| Flour Hollow | Maple, tier 1 | Flour Dough 70% common; Cocoa Dough 25% uncommon; Honeycomb Dough 5% rare |
| Caramel Gallery | Copper, tier 2 | Butter Dough 55% common; Caramel Vein 35% uncommon; Fudge Geode 10% rare |
| Sugar Grotto | Steel, tier 3 | Crystal Sugar 65% rare; Mint Quartz 30% epic; Cherry Ruby 5% legendary |
| Golden Oven Vault | Gilded, tier 4 | Baked Amber 60% epic; Golden Batter 35% legendary; Royal Cocoa 5% mythical |
| Starlight Depths | Starforged, tier 5 | Cosmic Cookie Ore 75% legendary; Starlight Dough 25% mythical |

Each gallery has four ore nodes. When a mined node respawns, its type and rarity reroll from that gallery's pool. Nodes have distinct colors and crystalline seams; the overhead display shows the ore, rarity, health and dough reward. Respawn times range from 12 to 40 seconds. Better galleries give more dough per node but require stronger pins.

Owning the required pin opens that gallery's seal for you without opening it for lower-tier players. Equip the pin and left-click/tap to mine. The server also checks the owned pin tier, proximity and line of sight before allowing damage. Food or card damage bonuses cannot replace a required pin. Rebirth resets your pin to Maple and relocks higher galleries until you buy better pins again. The forge update adds tiers 6–13; all retain access to every gallery and increase mining power.

Rolling pins now play a whoosh on accepted swings, including misses, and a separate impact cue when damaging ore. Both respect your saved SFX mute/volume. A built-in whoosh works without uploading audio. The ZIP also includes original **PinSwing.wav** and **OreHit.wav**; upload them if you want those recordings, grant your experience permission, then set `AudioConfig.Effects.PinSwing` and `AudioConfig.Effects.OreHit`. If a recording is unavailable, a built-in cue remains. See [the upload guide](UPLOAD-ASSETS.md).

## Save cash for more Golden Chips

Rebirth still requires the same recipe count and minimum **wallet cash + uncollected earnings**. Saving beyond that minimum increases the Golden Chip reward. The menu and confirmation show your current payout, base reward, savings bonus and the total cash needed for the next chip.

The payout is `floor(base reward × sqrt(total cash / required cash))`, bounded between the base reward and **5× the base reward**. Integer cash thresholds are checked on the server. This rewards waiting while keeping increasingly large bonuses harder to obtain.

For the first rebirth, with 18 recipes unlocked:

| Wallet + uncollected earnings | Golden Chips |
| ---: | ---: |
| $5 million | 5 |
| $7.2 million | 6 |
| $20 million | 10 |
| $45 million | 15 |
| $125 million or more | 25, maximum |

All current run cash is still reset when you rebirth. Currencies, cards, enchantments and permanent upgrades are retained. Armor is removed and rolling pins reset to Maple. Spending cash before confirming can reduce the displayed payout. The server computes the final reward from the actual balances when you confirm.

## Admin currency gifts

Open **Bakery → Admin tools**, select an online account, enter a positive whole amount and choose **Give Golden Chips** or **Give Star Crumbs**. These give exactly the entered amount; income/card multipliers do not increase admin gifts and daily earning limits are not consumed.

`AdminConfig` now includes `MaxGoldenChipGrant = 10000` and `MaxStarCrumbGrant = 100000`, per action. Cash grants retain their existing limit. Grants require the target's profile to be loaded and available, reject amounts exceeding a balance cap, and queue an early save. Golden Chips and Star Crumbs survive rebirth and rejoining after a successful save. Preview sessions do not save. [Admin setup](ADMINS.md) explains username access.

## Shift camera lock

Press **Shift** to toggle shoulder camera lock. Both left/right Shift keys work; Ctrl does not toggle it. **R3** works on a controller; the HUD's **Aim** button also works with mouse or touch. While enabled, your character faces the camera's horizontal direction and a small reticle marks the center. First-person view keeps its centered camera.

Lock cancels while a game menu, card reveal, Roblox menu, chat/text entry, purchase prompt or admin flight is active. It also releases when unfocused, seated or using a scripted camera. Your cursor returns for menus; press Shift again to enable aiming after closing them. Death/respawn clears the toggle. During admin flight, Ctrl keeps its descend function.

## Updating and checks

Back up your customized place first. Copy your configured values into the new scripts: `AudioConfig` IDs including Bubby's clips, `CardCatalog.ArtSheets`, `ShopCatalog`, `AssetTextures`, and `AdminConfig` usernames. Keep the new configuration fields when copying values. Publish into the same experience and restart outdated servers. Keep the existing DataStore names; the save envelope is now version 12 (see OBBYS-AND-FORGE.md).

The suite contains **209 Luau tests and 16 Python tests**. New checks cover exact ore probabilities, pin requirements, cave/road geometry, every next-chip threshold, grant permissions/caps, save/rejoin behavior and camera suspension rules. All **87 source scripts** are compiled and packaged. Automated checks do not run Roblox's physics, terrain renderer, input or live audio.

Before sharing widely, use a separate published test experience to check:

1. Walk through the entrance and each gallery with two different pin tiers. Confirm seals permit only the eligible player, and new pins remain effective after respawn/rejoin. Try mining through a divider and with an under-tier pin plus a food buff.
2. Mine each ore type, check the dough reward/health bar, and wait for rerolls. Inspect the entrance, walls and grassy roof at low/high graphics quality; ensure the workshop and roads remain clear.
3. Swing at air, ore and on Cookie Hill. Check the whoosh, impact, SFX mute/volume and optional audio permissions.
4. Inspect a rebirth at the minimum and at a higher savings threshold. Cancel once, then confirm and rejoin. Verify the exact awarded chips and normal run reset.
5. Grant both currencies as an admin and verify rejection for normal players, invalid amounts and full balances. Rejoin the recipient after saving.
6. Toggle Shift, Ctrl, R3 and touch Aim; try combat, first person, menus, typing, card reveals, purchases, death and admin flight. Ensure cursor control returns whenever needed.
