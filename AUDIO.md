# Graphics, music, and sound

The refreshed game has warm afternoon lighting, soft color grading and bloom, four pastel bakery themes, checkerboard floors, windows, string lights, a cookie monument, benches, oven steam, clearer world labels, and a highlighted next recipe. The HUD and menu have borders, gradients, hover/focus feedback, animated opening/toasts, and small reward bursts. Legendary and Mythic cookies sparkle.

## Music and SFX buttons

Two buttons sit below the main Bakery button in the HUD:

- **Music: ON/OFF** controls background music for that player.
- **SFX: ON/OFF** controls interface and gameplay sound effects independently.

The controls work with mouse, touch, and gamepad selection. They do not mute another player or Roblox's own character sounds. Preferences are saved with the player's profile, work before claiming a bakery, and survive rebirth. Temporary **STUDIO SESSION ONLY** play cannot persist them.

Music waits for the profile to load, so a returning player who muted it does not hear a new song before their preference arrives. Settings changes are debounced and queued for an early save after approximately five seconds, and are included in normal/final saves. Avoid force-closing immediately after changing a setting when checking persistence.

## Included original audio

`assets/audio` contains an original **42.67-second, 90 BPM** café loop and nine short cues. The recording combines soft keys, a bell melody, bass, and quiet percussion. All recordings are stereo 32 kHz, 16-bit PCM WAV files under Roblox's upload limits. The music has a continuous loop boundary.

| File | Use |
| --- | --- |
| `CookieCornerCafe.wav` | Looping café background music |
| `Click.wav` | Menu/button interaction |
| `Claim.wav` | Claim a bakery |
| `Collect.wav` | Collect cookie cash |
| `BuyRecipe.wav` | Unlock a recipe |
| `UpgradeOven.wav` | Upgrade baking speed |
| `BuyModifier.wav` | Add a topping |
| `UpgradePermanent.wav` | Buy a Golden Chip upgrade |
| `Rebirth.wav` | Confirm and complete a rebirth |
| `Error.wav` | A rejected gameplay purchase/action |

The composition and recordings are original and **CC0**, including commercial use; see [assets/LICENSE.txt](assets/LICENSE.txt). No downloaded music, copyrighted songs, or third-party recordings were used to generate these files.

## Playback before uploading audio

All audio asset IDs start at `0`. In that configuration, the client plays a lighter arrangement of the original melody and bass, plus the action cues, by pitching Roblox's bundled `electronicpingshort.wav` chime. That arrangement uses the same musical score but does not reproduce the mixed WAV's instruments or percussion.

The game references the chime installed with Roblox; it does not redistribute that sample. No Creator Store music IDs or private third-party audio are required. If a client cannot load the bundled chime, upload the supplied recordings as described below. The game continues running if audio cannot load.

## Use the full mixed recording in Roblox

Uploading the music once gives the game the full keys/bass/percussion version. You can upload the sound effects too, or keep their default chime arrangement.

1. Download the included WAV files from `assets/audio` on GitHub, or extract the updated free-assets ZIP supplied in the chat.
2. Open the **published** experience in Studio, then open **Asset Manager** from **Window** or **Home**.
3. Use its import button to upload `CookieCornerCafe.wav` under the appropriate account/group. Alternatively, use Creator Dashboard → **Development Items → Audio → Upload Asset**.
4. Wait for Roblox's processing/moderation to finish. Copy the resulting **audio asset ID**.
5. Grant the intended experience permission to use the audio through the asset's configuration/permissions page if needed. Use the correct experience/universe when granting permissions; a place ID is different.
6. With the playtest stopped, open **ReplicatedStorage → CookieTycoon → AudioConfig** in Explorer.
7. Replace the music entry's zero with your numeric audio asset ID:

   ```lua
   MusicAssetId = 0,
   ```

   The zero above marks the setting to change. Use the real digits Roblox gave you, without quotes.

8. For each uploaded sound effect, replace the matching zero under `Effects` with its audio asset ID. For example, `Collect.wav` maps to `Effects.Collect`. Leave other entries at `0` to keep their default arrangement.
9. Publish to the same experience, start a new session, and check playback. A configured recording is used once it loads; the chime arrangement covers playback while an uploaded recording is unavailable.

You can adjust `MusicVolume` and `EffectsVolume` in AudioConfig; values between `0` and `1` are sensible starting points. Changing `ChimeMidi` retunes only the built-in sampler. Roblox's master volume still applies to everything.

No audio has been uploaded to your Roblox account on your behalf. A `.wav` on GitHub or your computer cannot be played directly by a published Roblox game; uploaded recordings need Roblox asset IDs and experience permissions.

## Code locations

- `src/server/Presentation.luau`: lighting, pastel decoration, bulbs, windows, and oven steam.
- `src/server/World.luau`: claim/recipe indicators, world labels, and the cookie monument.
- `src/client/init.client.luau`: HUD styling, audio buttons, menu animation, and reward bursts.
- `src/client/AudioController.luau`: local music scheduling, voice pools, cues, mute controls, and preference submission.
- `src/shared/AudioConfig.luau`: uploaded audio IDs, volumes, and bundled sample tuning.
- `src/shared/MusicScore.luau`: generated melody/bass and cue timing.
- `tools/build_audio.py`: original composition and synthesis; run with Python 3 and NumPy to regenerate the recordings and Luau score.

Audio is local to each client. Music and SFX have separate SoundGroups. The sampler reuses a fixed pool of 12 music voices and 8 effect voices, skips stale notes after a frame stall, and cancels queued cues when effects are muted. One music scheduler is used per player; toggling does not start extra loops.

Gameplay cues are sent only to the affected player after the server accepts the action. No rewards or purchases depend on audio playback. Decoration does not change the economy, required recipe count, or rebirth prices. Steam uses low particle rates, lights do not cast additional dynamic shadows, and each plot uses one next-recipe outline.

## Check in Studio and Roblox

1. Start a player playtest with either valid save access or the explicit Studio session-only fallback. Check lighting, entrance lights, floor/wall colors, menu readability, and the next unlock indicator.
2. Claim a bakery: hear the claim cue and see steam from the active oven. Check that locked ovens are not steaming.
3. Collect cash, unlock a recipe, add a topping, and upgrade an oven. Each should have its own success cue. A rejected physical-pad purchase should play the quieter error cue.
4. Toggle Music off. Sound effects should continue. Toggle SFX off. Music should continue if enabled. With both off, neither channel should play. Toggle rapidly and check that no extra music layers appear.
5. Die/reset your character and confirm the HUD/audio do not duplicate.
6. In a persistent session, mute music, leave normally after the setting has saved, and rejoin. Confirm the saved button states restore before music starts. Repeat with SFX, and after a rebirth.
7. Test with two clients: toggling one client's audio must not mute the other client.
8. Check the audio buttons, open menu, and reward bursts on a small screen and with a controller. Check frame rate with several developed bakeries and lower graphics settings.
9. If using uploaded audio, join through the Roblox app and verify the full track and cues work with the experience's permissions. Check Output for asset-load errors in Studio.

Cloud checks cover saved preferences, save/rejoin/rebirth and receipt preservation, bounded score/cue data, and actual WAV hashes, format limits, levels, fade-outs, and loop continuity. They cannot verify Roblox rendering, sample availability, live audio permissions, or the listening experience; complete the engine checks above before release.

Official reference: [Roblox audio assets and uploads](https://create.roblox.com/docs/audio/assets).
