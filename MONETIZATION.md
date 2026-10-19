# Turn on Robux purchases

The code is included, but **all five Roblox IDs are deliberately `0`**, so purchases are disabled and the shop says **Coming soon**. You chose to leave sales off until you create the offers.

## 1. Create the offers on Roblox

Publish your game to Roblox, then open [Creator Dashboard → Creations](https://create.roblox.com/dashboard/creations) and select **this experience**.

Under **Monetization → Passes**, create these two passes and put them on sale at prices you choose:

| Pass | What the player receives | Code entry |
| --- | --- | --- |
| 2x Cookie Income | Permanent 2× cookie production earnings; stacks with rarity, toppings, Golden Batter, and rebirth bonuses | `Passes.DoubleIncome.Id` |
| 2x Baking Speed | Permanent 2× production speed along the conveyor; works even with fully upgraded baking speed | `Passes.DoubleSpeed.Id` |

These are one-time purchases. The speed pass affects **cookie production frequency**, not walking speed or cookie travel time. Neither pass doubles purchased cash bundles, quest cash rewards, or Golden Chip rewards. Both stay owned through rebirth and rejoin.

Under **Monetization → Developer Products**, create these three products and set prices you choose:

| Developer product | Exact reward per purchase | Code entry |
| --- | --- | --- |
| Pocket of Cookie Cash | $10,000 cookie cash | `Products.CashSmall.Id` |
| Jar of Cookie Cash | $100,000 cookie cash | `Products.CashMedium.Id` |
| Crate of Cookie Cash | $1,000,000 cookie cash | `Products.CashLarge.Id` |

Cash products can be purchased repeatedly. They add spendable in-game currency, which resets on rebirth just like earned cash. The shop states this before purchase. These bundles do not directly grant Golden Chips. Overflow from a full wallet goes into the uncollected-earnings bank, so a successful grant includes the entire amount.

You can use the original cookie PNGs in `assets/textures` as offer icons. Copy each offer's **pass ID** or **developer product ID** from Creator Dashboard. Use the offer IDs, not the place ID, experience ID, icon image ID, or purchase receipt ID.

## 2. Enter the five IDs

In Roblox Studio, open:

**ReplicatedStorage → CookieTycoon → ShopCatalog**

The same source file on GitHub is [src/shared/ShopCatalog.luau](src/shared/ShopCatalog.luau).

Find each `Id = 0` and replace **only the zero** with the matching numeric ID from Roblox. For example, if Roblox gives your income pass an ID, put those digits in the `DoubleIncome` entry:

```lua
DoubleIncome = {
    Id = 0,
    Name = "2x Cookie Income",
    Description = "Double cookie earnings forever. Stacks with Golden Batter and rebirth bonuses.",
}
```

The zero above illustrates the location; replace it with your real number, and keep the rest of the existing entry intact. Do this for both passes and all three products. IDs are public configuration.

You may enable just one offer initially: leave the other IDs at `0`. Invalid or duplicate IDs stay disabled. The same numeric ID cannot represent two different offers of the same type.

If you edit the files through Rojo/GitHub, sync them into Studio with Rojo or rebuild the place. Changes made only on GitHub do not automatically publish to Roblox.

## 3. Publish and check the shop

1. Publish the updated place to **the same experience that owns the offers**. Restart old servers when rolling out this version.
2. Join the game, open **Bakery**, then select the **Shop** tab. Configured offers should show prices fetched from Roblox. Unconfigured offers stay **Coming soon**. The compact sections identify passes as **KEEP FOREVER** and cash as **RESETS ON REBIRTH**.
3. The game fetches prices on each player's client, supporting Roblox's regional/personalized pricing. The native Roblox purchase window shows the final price and asks for confirmation. Set and change Robux prices in Creator Dashboard; there are no hardcoded Robux prices in the scripts.
4. In a separate published test experience, configure test offers belonging to that experience and check the native purchase flow before enabling production sales. Purchases in the live Roblox client can spend real Robux. Use Roblox's available testing tools/modes when checking prompts in Studio; do not treat a closed prompt as proof that a receipt or live entitlement was delivered.

Studio's explicit session-only fallback disables purchases. A real loaded player profile and working Roblox services are required. No external payment service or secret API key is used.

Roblox handles the Robux transaction, applicable fees, and creator revenue accounting. This code grants the in-game benefits; it does not itself perform cash payouts.

## Verify before enabling live offers

- **Canceled purchase:** cancel a native prompt; no cash or pass should be granted.
- **Income pass:** confirm a purchase, then verify the income multiplier doubles and remains active after rebirth and rejoin. It should show **Owned** instead of offering another purchase.
- **Speed pass:** verify the production interval halves. The fastest ordinary interval is 0.4 seconds; the pass permits 0.2 seconds. Decorative cookie animation frequency stays capped.
- **Cash product:** confirm that the full configured amount appears and is saved. Rejoin to verify it persists. Buy the same product again and verify the second distinct purchase awards another bundle.
- **Rebirth:** confirm that bought cash resets, both passes remain owned, and an old receipt cannot award the bundle a second time after the reset.
- **Mobile/controller:** check the scrollable shop tab, readable prices, disabled buttons while a prompt or purchase save is pending, and Roblox's confirmation window.

These engine/transaction checks require Roblox. Cloud validation uses the in-memory DataStore tests and does not charge Robux or create live offers.

## Receipt and save behavior

`CommerceServer` is the sole `MarketplaceService.ProcessReceipt` owner. Product grants are never based on `PromptProductPurchaseFinished` or a client-reported success. The player must have a loaded persistent profile; a free bakery plot is not needed to receive an already purchased cash bundle.

`ProfileStore` saves the cash grant and purchase ID **together in one `UpdateAsync`**. Only a durable grant is acknowledged to Roblox. Receipts are deduplicated across retries, rebirths, and reconnects. Session tokens protect against an old server overwriting a newer session. If a write's result is uncertain, the purchase callback retries locally and freezes ordinary economy changes/saves until it reconciles. On departure, it leaves an uncertain record intact instead of replacing it with pre-purchase cash. A server crash may require a rejoin after the existing session lease expires.

The existing `CookieCorner_PlayerData_v1` DataStore name is retained. Existing version-1, version-2, and version-3 records migrate to the **version-4 save envelope**, retaining receipt history, progression, toppings, and audio preferences while adding quest state. Restart outdated servers when publishing this update: earlier game versions cannot open version-4 records. Keep the new ProfileStore and existing DataStore name; do not roll back to older save code after enabling purchases.

Passes use Roblox's verified server ownership APIs and purchase events. Ownership is checked on join and retried after failures; **Refresh shop** requests another check. A pass purchased outside the running server may need Roblox's cache to update or a rejoin before it appears.

Keep purchase IDs in saved ledgers; do not clear them to save space. New in-game cash prompts stop at 10,000 recorded purchases for a profile, below the normal DataStore-size budget; already-issued receipts remain eligible for fulfillment. Monitor record sizes if you expand the shop substantially.

When retiring a cash product, remove its key from `ProductOrder` to hide its button, but keep its entry in `Products` with the original ID and amount. Pending receipts may arrive later. Create a new product ID when changing an offer's reward, instead of repurposing an existing ID. Unknown, ungranted product receipts remain pending until their original mapping is restored.

To stop offering a pass, hide its key from `PassOrder` but keep its original ID in `Passes` so existing owners continue receiving their permanent benefit.

Official references: [passes](https://create.roblox.com/docs/production/monetization/passes), [developer products](https://create.roblox.com/docs/production/monetization/developer-products), and [MarketplaceService.ProcessReceipt](https://create.roblox.com/docs/reference/engine/classes/MarketplaceService#ProcessReceipt).
