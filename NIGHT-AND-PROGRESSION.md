# Night creatures, lasting earnings, and purchase previews

The [combat follow-up](COMBAT-AND-OBBY.md) adds six E/Q abilities purchasable with dough at the mine, R6/R15 move animations, and contact-based obby finishes with queued reward retries. Combat ability purchases reset on rebirth.

## Rebirths and all-time cash

The old 50-rebirth finish and $100B late-game cost ceiling are removed. The original first eleven rebirth requirements stay familiar; after that, each requirement rises by 16%. The rebirth income factor keeps its existing `1 + 0.15r` bonus and gains an additional compounding 12% per rebirth beyond eleven. Costs therefore grow somewhat faster than income. Recipe requirements still stop at 30.

| Completed rebirths | Next cash + register requirement | Rebirth income factor alone |
| --- | ---: | ---: |
| 0 | $5M | 1× |
| 1 | $12.5M | 1.15× |
| 11 | $100B | 2.65× |
| 25 | about $799B | 23.21× |
| 50 | about $32.65T | 706.2× |
| 100 | about $5.46e16 | 384,200× |

Saving beyond the requirement still increases Golden Chips with diminishing returns, up to five times the base reward. Wallet and register balances both qualify. Rebirth remains a confirmed action.

This is open-ended progression for normal play, with finite storage safeguards: cash/earnings up to `1e300`, requirements up to `1e298`, and one billion rebirths. Very large figures use scientific notation and Roblox's floating-point precision; dollar-level precision eventually decreases. These guards prevent invalid infinite values from breaking saves.

The player list and global cash board now show **All-Time Cash**. Production counts when it enters the register. Quest rewards, NPC sales, monster rewards, cash bundles, admin cash gifts, and rebirth starter cash also count. Collecting moves existing money and does not count again. Spending and rebirth never subtract from this total. Cookie gifts and pickups do not earn money until a sale/reward actually pays it.

**Existing saves:** previous versions did not store cumulative earnings. Their starting total is saved wallet cash plus uncollected cash. Previously spent money cannot be reconstructed. From this update onward, earnings accumulate across sessions and rebirths.

Global boards still include offline players, refresh approximately every minute, and use committed saves. A fresh all-time cash index automatically imports existing profiles; allow time for this to fill in. The rebirth board remains across servers. Very large cash scores use a sortable logarithmic encoding; the displayed number comes from the actual profile when available. Very close enormous totals can share an index score.

## Mine upgrades and reset rules

All purchased mine upgrades now reset on a successful rebirth. Existing levels remain until you actually rebirth. Unspent cookie dough stays saved.

| Upgrade | Per-level benefit | Levels | Starting dough cost |
| --- | --- | ---: | ---: |
| Mixing | +10% production value | 10 | 25 |
| Flow | +5% baking speed | 10 | 30 |
| Pockets | +4 bag slots | 5 | 20 |
| Sprint | +1 walking speed | 5 | 35 |
| Leap | +0.5 jump height | 5 | 40 |

Costs double per purchased level. Sprint and Leap stack with active cookie buffs. Rebirth also clears bag cookies, conveyors, machines, decorations, toppings, mastery, armor and pin tiers; pins return to Maple. Cards, Star Crumbs, unspent dough, Golden Chips, permanent upgrades, enchantments, paid entitlements and all-time earnings stay. Saved armor enchantments reactivate when armor is repurchased.

## HUD, previews and aiming

Use **−** at the top-right of Cookie Corner to collapse it to your wallet and money ready to collect. **+** restores the controls and progress. The same control works on phones. Music/SFX mute buttons and saved volume sliders are together under **Bakery → Audio**.

Purchase cards have rotating 3D previews of ovens, cookies/toppings, pins, armor, packs, decorations and machines. The previews use local game models and need no asset upload. Only visible cards animate, and models are cached. Prices, affordability, proximity requirements, and server validation still apply. Enchantment previews show the equipment being enchanted, not a promised random outcome.

**Shift** toggles aim lock; Ctrl no longer activates it. R3 and the Aim button remain available. Menus, typing, losing focus, death, sitting and admin flight cancel the lock. Press Shift again when ready. Closing a menu cannot silently recapture the cursor. Ctrl retains its separate admin-flight descend action.

## Wilderness encounters

Small cookie monsters appear from **18:00 through 05:59** in three wilderness clearings, away from tycoons, shops, roads, the mine and obbys. Up to two can occupy each area. They roam, chase nearby living players within their home area, and telegraph attacks with a red ground circle. They disappear at dawn. Newly respawned players get five seconds before creatures target them.

Equip your rolling pin and left-click/tap to fight. Better pins, pin enchants, and cookie damage buffs help; armor, armor enchants, and defense cookies reduce incoming damage. Verified admin flight/invisibility cannot be used to farm these rewards. Small monsters split $750 and 8 dough by actual damage dealt. Each eligible contributor has a 20% cookie-drop chance: Common 65%, Uncommon 28%, Rare 7% of successful drops. No higher-rarity cookie drops. Full bags convert a dropped cookie into 5 extra dough.

**The Crumb Colossus** appears about every 30 minutes in the round arena in the east wilderness, near `(300, 410)`. Its notice board counts down and a server announcement calls players over. The boss stays up to ten minutes. Fight together with rolling pins, leave red attack zones, or jump over its warned stomps.

Boss health and its shared reward pool scale with the number of players present at spawn:

- Health: `1400 + 650 × (players − 1)`.
- Cash pool: `$2,000,000 × players`.
- Dough pool: `250 + 100 × players`.
- Star Crumb pool: `20 + 5 × players`.

Deal at least 1% of the boss's health to qualify. Each online contributor gets their damage fraction of the pool, rounded down; higher damage earns more cash. Overkill never inflates credit. Payout requires defeating the creature; timed-out bosses give no prize. Cash goes to your collection register. Currency storage limits still apply. Each payout uses a unique saved receipt so retries/rejoining cannot duplicate it. A service outage can delay a payout; leave/rejoin only after the save status settles when possible.

## Updating your place

1. Back up your customized place and configured IDs.
2. Download the new `CookieCorner.rbxlx`, open it in Studio, and copy over your **AudioConfig** (including Bubby), **CardCatalog.ArtSheets**, **ShopCatalog**, **AssetTextures**, and **AdminConfig** values.
3. Publish over the same experience/start place and restart outdated servers. Keep `CookieCorner_PlayerData_v1` and `CookieCorner_CookieTrades_v1`.
4. Save format **12** accepts formats **1–11**. Older server scripts cannot read the new format safely. Do not replace the new save code with an older copy.

No additional audio, image, model or paid product upload is required for this update. Preview sessions still do not save.

## Checks before opening to players

Automated checks cover the actual progression, lifetime migration, reward transactions, damage credit, cookie-drop distribution, large ranking scores, map clearance and catalog validation. They do not execute Roblox rendering, pathfinding, input or live services.

Use a separate published test experience and a two-player Studio session:

- Earn, collect, spend, rebirth and rejoin. Confirm the wallet resets, mine levels reset, unspent dough stays, and all-time cash only grows. Confirm both global boards update after saving.
- Try the HUD collapsed/expanded on a narrow phone emulator. Open each purchase category and verify models, wrapped text, scrolling, costs and clicks. Revisit a category to check cached previews.
- Toggle Shift, open chat/menus, tab away, die, respawn and fly as an admin. Cursor and character rotation must recover without a rejoin; Ctrl must not toggle aiming.
- Try Sprint/Leap with and without food, then rebirth while buffed. Recheck ordinary movement and cave access with the Maple pin.
- For faster encounter testing, change `WildernessRules.BossInterval` to 30 **in the test place only**, then restart Play. Restore 1800 before publishing. Set `Lighting.ClockTime` to 22 in the server test session to reach nighttime; the ordinary cycle continues from there.
- Walk into/out of each creature area, test attacks against obstacles, and check red telegraphs, armor reduction and rewards with two contributors. Beat a boss and verify that the heavier contributor receives more cash and that collecting/rejoining cannot duplicate the payout.

Suggested next balancing pass: add a short first-visit task chain—mine dough, buy Sprint, fight a night creature, then open a pack—so players discover the side activities in a clear order. Keep boss rewards mainly cash/dough so packs remain meaningful exploration goals.
