# Music and sound

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

Regenerate the original composition and effects with `python tools/build_audio.py`. Its score is exported to `src/shared/MusicScore.luau`, and audio hashes/durations to `assets/audio/manifest.json`. Python requires NumPy. Rebuild the Studio downloads after any source or audio change.

## Check in Studio and Roblox

- Hear the new composition with MusicAssetId 0 and fallback enabled. Confirm the old friend recording never starts.
- Drag, tap, and use +/- on both sliders. Test mute independently; Music 0% must not silence SFX.
- Rejoin and verify both mute states and volumes restore. Compare two clients with different choices.
- Reset the avatar and verify no duplicate music players or cue bursts.
- Check the loop boundary, quiet passages, cue levels, and mobile controls at comfortable device volume.
- If using the uploaded full mix, verify it loads for another account in the published experience, not just its owner. Test permission failure and sampler fallback.

The cloud environment validates WAV integrity, levels, loop continuity, score bounds, scripts, and packaging. Roblox Studio/live clients are required to validate engine audio playback and uploaded-asset permissions.
