# Cookie Corner original asset pack

**Free to use, change, and publish in monetized games. No attribution required.**
Original models and texture images are dedicated under CC0; see `LICENSE.txt`.

## Included

- `models/CookieCornerAssets.rbxmx`: 30 cookie models and 20 bakery/landscape props.
- `textures/`: 42 seamless, 512 × 512 RGB PNGs. `Cookie01` through `Cookie30` follow the game's recipe order; the other 12 images cover floors, walls, wood, metal, conveyors, brick, parchment, gold, awnings, marble, grass, and paths.
- `previews/Models.png` and `previews/Textures.png`: visual catalogs.
- `manifest.json`: model inventory, texture names, dimensions, and SHA-256 hashes.

Every model uses anchored Roblox Parts, a transparent `Root` as its PrimaryPart,
and built-in materials. There are no embedded scripts, external meshes, or
required image asset IDs. The models work immediately without importing PNGs.
The style uses simple shapes and colored toppings rather than photorealistic meshes.

## Use the models in Studio

1. In Explorer, right-click **ServerStorage** and select **Insert from File**. Select `models/CookieCornerAssets.rbxmx`.
2. Expand `CookieCornerAssets`. `Cookies` contains all 30 recipe models and `Props` contains the bakery set.
3. Copy an individual model into Workspace to edit or display it. Templates share the same origin, so inserting the entire pack into Workspace will stack them together.
4. Move models using Studio's Model tools. Keep the transparent `Root` PrimaryPart when using the supplied game scripts. Static models are anchored; disable collisions on moving decorative cookies.

The updated game already contains this pack in ServerStorage and creates the
bakery and cookie animations from it. Open `CookieCorner.rbxlx` to use that setup.

The 20 props are Oven, Conveyor, CollectionRegister, UpgradeConsole,
RebirthPedestal, ClaimPad, BakerySign, BakeryFloor, BakeryShell, BakeryAwning,
IngredientBins, DoughMixer, CoolingRack, PrepCounter, WoodenFence, Lamppost,
CookieTree, Planter, SpawnPlaza, and PathSegment. Purchase pads reuse the ClaimPad
model at a smaller size with each cookie's color. Signs and screens are decorative;
the game's scripts provide their labels, prompts, and behavior.

## Use the PNG textures

Roblox cannot use a PNG from your computer by its local path. Upload images to
your own experience/account before applying them:

1. Open the published experience in Studio and use **Asset Manager** to import the desired PNG files. Use the image assets' IDs after Roblox processes them.
2. In the supplied game, open `ServerScriptService > Tycoon > AssetTextures`. Paste each numeric image asset ID, as a quoted string, into its matching slot; for example `BakeryFloor = "YOUR_NUMERIC_IMAGE_ID"`. Replace the example with the real digits. Empty slots keep native materials.
3. Restart Play so the world is rebuilt. The game's AssetLibrary applies those textures to parts named `Texture_<slot name>`, and applies grass and path textures to their surfaces.

For another game, add a Texture to a Part, set its `Texture` property to your
uploaded image ID, choose the face, and set StudsPerTileU/V. Start with 8 studs
for surfaces and adjust to taste. Cookie cylinders are rotated upright: their
**local Right face** is the visible top. Use about **3.35 studs** for a cookie top.
The floor's top face works well at 16 studs per tile. All 42 images have matching
opposite borders for tiling.

PNG IDs are deliberately empty in the supplied game: no assets have been
uploaded to your Roblox account on your behalf. Roblox's image processing and
availability still apply after import. Built-in materials remain usable meanwhile.

## Regenerate or customize

In the game repository, install Python 3, Pillow, and NumPy, then run:

```sh
python tools/build_assets.py
python -m unittest discover -s tests -p 'test_assets.py'
```

`tools/build_assets.py` defines the original geometry and procedural images. It
reads cookie names and colors from `src/shared/Recipes.luau`. Models contain no
runtime generator scripts. For individual edits, modify a cloned template in
Studio; regenerating replaces the generated asset files.
