# Cookie animal card art

`CookieAnimals.png` is original generated artwork: an **8-column × 5-row** atlas containing all forty cookie animals, ordered exactly like `src/shared/CardCatalog.luau`. Row five contains the three legendary and five mythical animals. Higher rarities have richer backgrounds and detail; legendary/mythical card frames animate a holographic color sheen in the game.

To use the illustrated art in Roblox:

1. Upload **CookieAnimals.png** as a Roblox image through Studio's Asset Manager or Creator Dashboard, using the experience's creator account/group.
2. Copy the resulting **image asset ID** into **ReplicatedStorage → CookieTycoon → CardCatalog → ArtAssetId** (replace 0).
3. Keep `ArtColumns = 8`, `ArtRows = 5`, `ArtWidth = 1586`, and `ArtHeight = 992` unchanged.
4. Publish and test as another player. The game crops each card from that one image; forty separate uploads are unnecessary.

Roblox requires a hosted image asset ID; a PNG inside a local Studio ZIP cannot serve as an ImageLabel texture by itself. Before the upload is configured, the card UI uses original native 3D cookie-animal previews, while names, quips, rarities, buffs, and pack mechanics still work.

The atlas and the complete card/pack/economy guide are included in the Studio ZIP. Card names, flavor text, and effects are authored in CardCatalog. Art is decorative; all pack rolls, ownership, currency, and equipped bonuses are server-authoritative.
