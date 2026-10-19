# Graphics, music, and sound

The refreshed game has warm afternoon lighting, soft color grading and bloom, four pastel bakery themes, checkerboard floors, windows, string lights, a cookie monument, benches, oven steam, clearer world labels, and a highlighted next recipe. The HUD and menu have borders, gradients, hover/focus feedback, animated opening/toasts, and small reward bursts. Legendary and Mythic cookies sparkle.

## Music and SFX volume

The HUD keeps separate **Music ON/OFF** and **SFX ON/OFF** buttons and now has two **0–100% volume sliders**. Drag or tap a slider, or use its **− / +** buttons for five-percentage-point adjustments. The buttons work with gamepad selection; a selected slider also accepts Left/Right or D-pad Left/Right. Music defaults to **24%** and SFX to **55%**.

Each slider adjusts only that channel for the current player. Zero is silent; muting preserves the slider's value so unmuting restores it. Moving a slider while muted changes the saved level without unmuting. Roblox's master volume still applies. These controls cover game music and cues, not Roblox's own character sounds.

Mute states and volume levels save with the player profile and survive rejoin, respawn, and rebirth. Old profiles keep their mute choices and receive the default levels. Settings wait for the profile before playback starts and are debounced for an early save about five seconds after a change. Session-only Studio previews cannot save. Keep the existing DataStore name and restart outdated servers when publishing this update.

## Your friend's background song

The selected song is **cookiecookieloop1.ogg**, supplied by the project owner and made by their friend. The original file is preserved unchanged: stereo Ogg Vorbis, 44.1 kHz, approximately **44.14 seconds**, 2.15 MB. It plays at its original speed with `Sound.Looped = true`. See [the supplied song and credit](assets/audio/friend/README.md).

This song is **not covered by the original asset pack's CC0 license**. No broader license for the friend's recording was supplied. The earlier generated café music and nine original SFX remain available under their original CC0 license.

**Roblox cannot play an OGG directly from GitHub or embed it as playable audio in a place file.** Upload the song to Roblox and put its audio ID in the game. The updated Studio ZIP includes the OGG beside the place file. The HUD shows **Music pending** until an audio ID is configured, **Music loading** while it loads, and **Music unavailable** if the configured recording cannot load. Background music stays silent until setup is complete; the old synthesized background tune is disabled by default. Sound effects still work with the bundled chime.

## Upload the new song once

1. Download the updated [Studio ZIP](https://github.com/Messer252/RobloxGame/raw/refs/heads/main/CookieCorner_Studio.zip) and extract it. It contains `CookieCorner.rbxlx`, `cookiecookieloop1.ogg`, this guide, and instructions. You can also [download the song directly](https://github.com/Messer252/RobloxGame/raw/refs/heads/main/assets/audio/friend/cookiecookieloop1.ogg).
2. In **Creator Dashboard → Development Items → Audio → Upload Asset**, upload `cookiecookieloop1.ogg` under the account or group that owns the game. Studio's Asset Manager audio import is another option. Follow Roblox's current upload prompts.
3. Wait for processing/moderation, then copy the **audio asset ID**. Grant your game/experience permission to use that audio in the asset's permissions settings. Use the experience/universe ID where requested, rather than its individual place ID.
4. With the playtest stopped, open **ReplicatedStorage → CookieTycoon → AudioConfig** in Studio's Explorer.
5. Change `MusicAssetId = 0` to `MusicAssetId = YOUR_NUMERIC_AUDIO_ID`, using the actual digits without quotes. Keep `FallbackMusicEnabled = false` to avoid the earlier background tune.
6. Publish to your existing start place and restart outdated servers. Join through the Roblox app and check the song loops, each slider works, and mute/volume choices restore after rejoin. If silent, check Output for audio permissions or moderation errors.

No audio has been uploaded to your Roblox account on your behalf. Adding a file to GitHub does not create a Roblox audio asset. If you already uploaded this recording, use its existing permitted audio ID instead of uploading again.

## Sound effects and earlier music

The nine original CC0 effects in `assets/audio` remain `Click.wav`, `Claim.wav`, `Collect.wav`, `BuyRecipe.wav`, `UpgradeOven.wav`, `BuyModifier.wav`, `UpgradePermanent.wav`, `Rebirth.wav`, and `Error.wav`. They work immediately using the bundled Roblox chime. Optionally upload the WAVs and set their matching IDs under `AudioConfig.Effects` for the full recordings. They use the SFX slider in either mode.

`CookieCornerCafe.wav` and its generated 66 BPM score are retained as earlier optional assets, not the selected background song. `tools/build_audio.py` regenerates those original files and cues without replacing your friend's OGG. The old music sampler only runs if an administrator deliberately sets `FallbackMusicEnabled = true`.

## Code locations

- `src/client/AudioController.luau`: local looping track, separate SoundGroups, fades, cues, mute, volume, and debounced preference submission.
- `src/client/VolumeSlider.luau`: mouse/touch sliders and keyboard/gamepad adjustment.
- `src/shared/AudioPreferences.luau`: default levels, finite-number validation, bounded values, and save migration.
- `src/shared/AudioConfig.luau`: Roblox audio IDs and optional sampler settings.
- `src/server/init.server.luau`: server-validated settings and save scheduling.
- `src/server/Presentation.luau`: lighting and bakery decoration.

## Check in Studio and Roblox

1. Configure the uploaded song's ID and experience permission, start a player playtest, and listen through at least two loops. The old background tune must not play while the new song loads or if its asset is unavailable.
2. Drag each slider independently through 0%, a mid-level, and 100%. Tap both ends and drag beyond the track: levels must stay within 0–100%. Release the drag outside the slider, then move the pointer: volume must stop changing.
3. Mute Music while leaving SFX on, then reverse. Change levels while muted, then unmute: each saved level should return. At zero, that channel must be silent. Adjust SFX and collect cash to hear its cue at the new level.
4. In a persistent session, set different levels and mute states, wait for a saved status, leave normally, and rejoin. Check both values, no audible startup burst, and independence after a rebirth or purchase.
5. Reset your character and confirm audio/UI do not duplicate. With two clients, changing one player's audio must not affect the other.
6. Test touch dragging on a small screen, controller plus/minus activation, selected-slider left/right input, focus visibility, and readability. Check that both sliders fit below the HUD buttons.
7. Without an audio ID, music should remain silent while the rest of the game and SFX continue. Check configured but unpermitted audio too, then restore the correct ID and permission.

Cloud checks cover preference validation, legacy saves, rejoin/rebirth and receipt preservation, original WAV integrity, and unchanged OGG bytes. Roblox playback, moderation, permissions, dragging, and device controls still require these engine checks.

Official reference: [Roblox audio assets and uploads](https://create.roblox.com/docs/audio/assets).
