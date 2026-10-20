# Upload Cookie Corner audio and TCG artwork to Roblox

**Yes, `.ogg` audio works.** Roblox accepts `.ogg`, `.mp3`, `.wav`, and `.flac`. For OGG exports, choose **Ogg Vorbis** in your audio editor. Changing a filename's extension does not convert the recording. Each upload must be **under 20 MB**, **under 7 minutes**, and **48 kHz or lower**. Mono or stereo is a simple choice for these clips.

You can open the game before uploading anything. Custom audio and card pictures must be hosted on Roblox before players can hear/see them. Uploading creates asset IDs; you then paste those IDs into the game's configuration and publish the place. Players download the assets automatically when playing.

## 1. Get the files and open your game

1. [Download CookieCorner_Studio.zip](https://github.com/Messer252/RobloxGame/raw/refs/heads/main/CookieCorner_Studio.zip).
2. Extract it: on Windows, right-click → **Extract All**; on Mac, double-click the ZIP.
3. Open **Roblox Studio**. Open your existing game, or use **File → Open from File** to open the extracted `CookieCorner.rbxlx`.
4. If the game has never been published, choose **File → Publish to Roblox** and publish it once. This gives it an experience to grant asset permissions to. It can stay private while you set up assets.
5. Stop any playtest before editing scripts. Open **Explorer** and **Asset Manager** from Studio's **Window** menu; older layouts may put them under **View**.

Use the same creator for the assets and the game: your personal account for a personal game, or the owning group for a group game. Menu wording can vary between Studio versions.

The extracted ZIP includes:

| File | Purpose |
| --- | --- |
| `MeteorCrash.wav` | Full original 8-bit meteor impact |
| `MeteorIncoming.wav` | Optional meteor warning recording |
| `CookieCornerCafe.wav` | Optional full Valley Afterglow background music |
| `CookieTCG_01.png` through `CookieTCG_04.png` | All forty card illustrations, ten per sheet |

Bubby's six voice recordings are your own separate files; they have not been included in this download. They can be `.ogg` files.

**Already have a customized game?** You can configure these assets in that existing game. Opening a fresh download is not necessary just to change asset IDs, provided your game already has the current `AudioConfig` and `CardCatalog.ArtSheets` fields. Keep your existing product IDs, admin names, and other settings when updating a game file.

## 2. Upload the audio

1. Open [Roblox Creator Dashboard](https://create.roblox.com/dashboard/creations).
2. Select the account/group that owns the game.
3. Choose **Creations → Development Items → Audio**.
4. Click **Upload Asset**, select a recording, give it a name, and upload it. Repeat for each file you want to use.
5. Wait for processing and moderation. Keep a note of which file belongs to which asset.
6. Open each uploaded audio asset and copy its **numeric asset ID**. Studio's Asset Manager also offers **Copy Asset ID** when you right-click an uploaded asset.

Suggested names for Bubby's recordings are `BubbyCookie01.ogg` through `BubbyCookie06.ogg`. Trim silence at the beginning/end and keep the six recordings at similar loudness.

### Give the experience permission to play the audio

For each restricted audio asset:

1. Open the asset in Creator Dashboard.
2. Choose **Permissions → Experiences → Add experiences**.
3. Enter your game's **universe ID**, click **Add**, then **Done**.

To find the universe ID, open your game in Creator Dashboard. In a URL such as `.../creations/experiences/123456789/overview`, the number immediately after `experiences/` is the universe ID. The number in a public `roblox.com/games/...` link is a **place ID**, which is different.

The universe ID is used for the permissions screen. The game's audio configuration needs the **audio asset ID**, not the universe ID. If Bubby uploads the recordings on his own account, he must grant your experience permission to use them; being Roblox friends alone does not supply that game permission.

## 3. Connect the audio IDs in Studio

In Explorer, expand **ReplicatedStorage → CookieTycoon**, then double-click **AudioConfig**. This opens the ModuleScript; the settings below are lines of code inside it, not separate Explorer objects.

Use these mappings:

| Recording | Setting inside `AudioConfig` |
| --- | --- |
| `MeteorCrash.wav` or your OGG export of it | `Effects.MeteorCrash` |
| `MeteorIncoming.wav` | `Effects.MeteorIncoming` |
| `CookieCornerCafe.wav` or another background song | `MusicAssetId` |
| Bubby's six voice lines | The six entries in `OvenPurchaseVoices` |

For example, the relevant lines might look like this after you insert your IDs:

```lua
MusicAssetId = 1234567890,
OvenPurchaseVoices = {
    1111111111, 2222222222, 3333333333,
    4444444444, 5555555555, 6666666666,
},
-- Inside the EXISTING Effects table:
MeteorIncoming = 7777777777,
MeteorCrash = 8888888888,
```

**These are example numbers, not working assets.** Replace them with your own numeric audio asset IDs, without quotes or `rbxassetid://`. Change the existing fields; do not replace the entire module with this example or create a second `Effects` table. Keep the commas between entries.

You can upload just the meteor crash first and leave all other IDs at `0`. You can also start with fewer than six Bubby recordings and leave unused voice slots at `0`.

- `MusicAssetId = 0` keeps the built-in background score.
- `Effects.MeteorCrash = 0` keeps the built-in impact cue; the full 8-bit WAV needs its uploaded ID.
- All voice slots at `0` keep the normal oven purchase sound.
- Bubby's lines randomly play **only after successfully buying a new cookie oven/recipe**. Baking-speed upgrades, failed purchases, and other actions keep their own sounds.
- Music and SFX have independent saved volume sliders and mute buttons. Voices and meteor sounds use **SFX**.

## 4. Upload the four card-art sheets

1. In Studio, open **Asset Manager** with your intended game open.
2. Click **Import**. Some older layouts call this **Bulk Import**.
3. Select these four PNGs from the extracted ZIP:

   ```text
   CookieTCG_01.png
   CookieTCG_02.png
   CookieTCG_03.png
   CookieTCG_04.png
   ```

4. Import them as image assets for the game's creator. Wait for upload and moderation to finish.
5. Find the uploaded images in Asset Manager, right-click each, and choose **Copy Asset ID**. Keep a note of the filename next to its ID.
6. If an image is restricted and Roblox reports that the game lacks access, grant the experience permission using the same **Permissions → Experiences** process above.

Upload the **four illustration sheets**, not `Preview.png`. Do not cut them into forty individual cards, crop them, or rearrange the animals. The game's UI draws the card frames, names, quips, buffs, and holographic effects itself. No HTML file is needed or included in the Studio ZIP.

## 5. Connect the image IDs in Studio

1. In Explorer, open **ReplicatedStorage → CookieTycoon → CardCatalog**.
2. Find the `ArtSheets = { ... }` section near the top of the ModuleScript.
3. Replace only the `Id = 0` on each matching filename's row:

   | Filename in the row | Cards | ID to enter |
   | --- | --- | --- |
   | `CookieTCG_01.png` | 001–010 | Uploaded image ID for sheet 01 |
   | `CookieTCG_02.png` | 011–020 | Uploaded image ID for sheet 02 |
   | `CookieTCG_03.png` | 021–030 | Uploaded image ID for sheet 03 |
   | `CookieTCG_04.png` | 031–040 | Uploaded image ID for sheet 04 |

For example, **one existing row** becomes:

```lua
{ Id = 9999999999, File = "CookieTCG_01.png", Width = 1983, Height = 793, Columns = 5, Rows = 2, First = 1, Last = 10 },
```

Replace the example ID with your actual image ID. Keep `Width`, `Height`, `Columns`, `Rows`, `First`, and `Last` as supplied. The `File` field identifies the sheet; it does not upload a local file by itself. An unset sheet uses the native 3D card previews.

If you uploaded through Creator Dashboard as a **Decal**, its listing ID can differ from the underlying image ID. Prefer the image entry in Studio Asset Manager. If needed, insert that uploaded decal from Toolbox → Inventory onto a temporary part, select the resulting Decal in Explorer, and inspect its **Texture** property; use the number from that image content ID. Remove the temporary part afterward.

## 6. Publish and check

1. Save your edits and choose **File → Publish to Roblox**. Use your existing experience so you keep the same game and saved progress.
2. Restart outdated servers from the game's Creator Dashboard server-management page.
3. Join the published game through the Roblox app, then check with a friend's account too. Seeing an asset as its owner in Studio does not prove the experience has permission to use it.
4. Turn **SFX ON** and raise its slider. Buy several different ovens to check Bubby's random lines. One loaded recording may repeat; multiple loaded recordings avoid immediate repeats.
5. Turn **Music ON** and raise its slider to check an uploaded background track, if configured.
6. Open **Cookie Bag → Collection** and use **View card** on cards you own. Check illustrations from each configured sheet as your collection grows. The ZIP's `Preview.png` is a static preview; it does not prove Roblox uploads are connected.
7. Meteors normally arrive after a random **5–30 minutes**. Check the incoming warning and crash when one lands. Their banners still appear if SFX is muted.

## If something does not work

| Symptom | Check |
| --- | --- |
| Audio upload rejected | Export a real supported format; use Ogg Vorbis for `.ogg`, 48 kHz or lower, under 20 MB/7 minutes. Re-export as WAV if your editor's OGG is rejected. |
| Audio is silent for everyone | Confirm moderation, experience permission, the numeric audio ID, and SFX/Music mute and volume. Open Studio **Output** for asset-loading errors. |
| You still hear the old purchase cue | Voices may still have zero IDs or lack loading permission. Buy a new recipe oven, not a baking-speed upgrade. |
| You still hear the built-in crash cue | The uploaded crash has not loaded; check `Effects.MeteorCrash` and permissions. |
| The card shows a native 3D creature | That sheet's `Id` is still 0 or invalid. |
| The card art is blank | Check image moderation, experience access, and whether you copied an image ID or a decal listing ID. |
| The wrong animal appears | Verify that the IDs match filenames 01–04 and that the sheet dimensions/grid/ranges were not changed. |
| The illustration looks soft/blurry | Use the updated `CardArt` renderer described below, allow the image to finish loading, and confirm you uploaded the original sheets rather than `Preview.png` or a screenshot. |
| Only old servers show old assets | Publish the configuration changes and restart outdated servers. |
| Chrome/antivirus blocks a download | Keep protection enabled and check the exact file and threat name in Protection history. An older Studio ZIP included an optional `CardGallery.html` preview; it has been removed from the current Studio ZIP. If the new package is still flagged, stop and report the new detection rather than bypassing it. |

You do **not** need to put your files on sale, publish them to the public Creator Store, or make the game public just to test these uploads. Upload/moderate the assets, give the experience access, and publish its configured asset IDs.

## Update the card renderer without re-entering your audio/image IDs

The updated renderer displays the complete uploaded sheet behind a clipped illustration window instead of using a small `ImageRectSize` crop. This gives Roblox a larger image to render, keeps the correct animal selected when an uploaded texture is resampled, and preserves the illustration's proportions. It also preloads the viewed sheet. The original four uploads and IDs still work.

For an existing configured game, you can replace **one ModuleScript**:

1. Stop the playtest in Studio.
2. In Explorer, open **StarterPlayer → StarterPlayerScripts → TycoonUI → CardArt**.
3. Open the [updated CardArt source on GitHub](https://github.com/Messer252/RobloxGame/blob/main/src/client/CardArt.luau). Use GitHub's **Copy raw file** button to copy the complete code.
4. Replace the contents of the existing `CardArt` ModuleScript with that code. Updating only this module preserves your `AudioConfig` and `CardCatalog` asset IDs, product IDs, and other settings.
5. Publish and start a fresh playtest/server.

Roblox can still serve lower-resolution textures while loading or on devices with restricted texture memory. Rendering changes cannot restore detail already missing from an uploaded source. If it remains blurry, compare the original PNG with the in-game illustration and check whether the surrounding text is also blurry.

Official references: [Roblox audio requirements and upload steps](https://create.roblox.com/docs/audio/assets), [Asset Manager](https://create.roblox.com/docs/projects/assets/manager), and [asset permissions](https://create.roblox.com/docs/projects/assets/privacy).
