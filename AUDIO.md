# Music and sound

New to uploading assets? Follow [Upload audio and TCG artwork](UPLOAD-ASSETS.md) for the complete walkthrough. **`.ogg` files are supported**; export Ogg Vorbis, 48 kHz or lower, under 20 MB and seven minutes per file.

The current soundtrack is **Valley Afterglow**, a new original 68 BPM ambient composition, about 113 seconds long. It replaces the previously selected friend recording. The quiet built-in score uses Roblox's bundled instrument sample and starts without uploading audio. Independent Music/SFX mute buttons and saved 0–100% sliders remain in the HUD.

The full original mix is `assets/audio/CookieCornerCafe.wav`, also included in the Studio ZIP. The built-in score and WAV share the composition; their instrument rendering differs. Original generated music and effects are CC0. The friend's old recording remains archived in `assets/audio/friend` with its separate credit/license and is not selected or bundled in the current Studio ZIP.

## Optional full-mix upload

1. In Roblox Creator Dashboard, open your creations/assets and upload `CookieCornerCafe.wav` as audio. Select the same creator (you or your group) that owns the experience.
2. Wait for processing/moderation. Open the audio's permissions and grant your experience access if required.
3. Copy the numeric audio asset ID.
4. In Studio, open **ReplicatedStorage → CookieTycoon → AudioConfig**. Set `MusicAssetId = 0` to that numeric ID and keep `MusicName = "Valley Afterglow"`.
5. Publish and restart outdated servers. A loaded full mix replaces the sampler automatically. If loading fails, the built-in score remains available.

Do not enter a filename, universe ID, place ID, or web URL in `MusicAssetId`. You do not need an uploaded ID to hear the built-in composition.

## Effects and settings

`AudioConfig.Effects` accepts optional uploaded IDs for the included action WAV files; 0 uses the built-in cues. Music and SFX use separate local SoundGroups. Muting and volume affect only the current player and are saved with the bakery profile. Playback does not restart when moving a volume slider.

## Bubby's oven purchase voices

Six slots are ready for Bubby's different **"cookie cookie"** recordings. A random loaded line replaces the normal purchase sound **only after the server confirms buying a new cookie oven/recipe**. Failed purchases, baking-speed upgrades, toppings, cash collection, and other actions keep their own sounds. Only the buyer hears the line, through their SFX mute/volume settings. The next purchase avoids repeating the previous recording when another is available; rapid purchases replace the prior line instead of overlapping voices. Playback keeps his original voice pitch.

1. Record/export six short clips, preferably WAV, MP3, or OGG, with similar loudness and little silence at either end.
2. Upload each in **Roblox Creator Dashboard → Creations → Development Items → Audio** (menu names can vary). Use the account/group that owns the game and wait for moderation/processing.
3. In each audio asset's permissions, grant the game/experience access if needed. An audio ID alone does not grant permission.
4. In Studio, stop Play and open **ReplicatedStorage → CookieTycoon → AudioConfig**. Replace the six zeros in `OvenPurchaseVoices`, for example:

   ```lua
   OvenPurchaseVoices = { 1111111111, 2222222222, 3333333333, 4444444444, 5555555555, 6666666666 },
   ```

   Those are example numbers; enter your actual numeric audio asset IDs. You can start with fewer uploaded clips and leave unused slots at 0.
5. Publish the place and restart outdated servers. You can open and test the game before the recordings are uploaded; empty or unavailable slots use the existing purchase cue.

The recordings have not been supplied yet. No substitute voice is included. Keep your configured audio IDs when downloading a newer game file.

Regenerate the original composition and effects with `python tools/build_audio.py`. Its score is exported to `src/shared/MusicScore.luau`, and audio hashes/durations to `assets/audio/manifest.json`. Python requires NumPy. Rebuild the Studio downloads after any source or audio change.

## Meteor announcement and original 8-bit crash

Everyone in the current server receives a **COOKIE METEOR INCOMING!** banner when the fall begins, followed by **COOKIE METEOR LANDED!** at impact three seconds later. The impact banner explains the three-hit participation reward, and an expanding shockwave marks the landing. These announcements stay visible even with SFX muted. They concern the meteor in that server; they do not announce unrelated meteors in other servers.

The new original **MeteorCrash.wav** is a 2.1-second arcade crash made from a stepped square-wave dive, crunchy quantized noise, bass impact and short stereo echoes. **MeteorIncoming.wav** is the optional warning cue. Both are CC0, included in the Studio ZIP, and available under `assets/audio/`. A built-in descending alert/impact cue works immediately; Roblox cannot play a local WAV file directly from a place.

To hear the **full 8-bit crash**, upload `MeteorCrash.wav` as Roblox audio under the game's creator, grant the experience access, and enter its numeric ID in **ReplicatedStorage → CookieTycoon → AudioConfig → Effects → MeteorCrash**. Optionally upload `MeteorIncoming.wav` and configure `Effects.MeteorIncoming` too. Publish and restart outdated servers. Zero IDs, pending moderation, or unavailable recordings keep the built-in cue. Both use each listener's saved SFX mute and volume; music volume stays independent.

## Check in Studio and Roblox

- Hear the new composition with MusicAssetId 0 and fallback enabled. Confirm the old friend recording never starts.
- Drag, tap, and use +/- on both sliders. Test mute independently; Music 0% must not silence SFX.
- Rejoin and verify both mute states and volumes restore. Compare two clients with different choices.
- Reset the avatar and verify no duplicate music players or cue bursts.
- Check the loop boundary, quiet passages, cue levels, and mobile controls at comfortable device volume.
- If using the uploaded full mix, verify it loads for another account in the published experience, not just its owner. Test permission failure and sampler fallback.
- Configure Bubby's clips and buy several different ovens. Confirm varied lines, no immediate repeat when multiple recordings are loaded, and no overlapping voices. A failed purchase or speed upgrade must not trigger them. Test SFX mute, 0% volume, a second client, and an unavailable clip's fallback.
- In a private two-player test, trigger a meteor and confirm both clients see the incoming and impact banners, one crash per impact, and the shockwave. Test different SFX levels/mute states, the built-in fallback, and the uploaded crash's experience permissions.

The cloud environment validates WAV integrity, levels, loop continuity, score bounds, scripts, and packaging. Roblox Studio/live clients are required to validate engine audio playback and uploaded-asset permissions.
