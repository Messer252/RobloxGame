"""Build and check the ready-to-open Studio downloads published on GitHub.

Run from any directory: python tools/package_studio.py --rojo /path/to/rojo
Requires Rojo 7.7.1; no third-party Python packages are needed.
"""
from __future__ import annotations

import argparse
from pathlib import Path
import shutil
import subprocess
from xml.etree import ElementTree as ET
from zipfile import ZIP_DEFLATED, ZipFile

ROOT = Path(__file__).resolve().parents[1]
PLACE = ROOT / "CookieCorner.rbxlx"
ARCHIVE = ROOT / "CookieCorner_Studio.zip"
MUSIC = ROOT / "assets/audio/friend/cookiecookieloop1.ogg"

START_HERE = """COOKIE CORNER TYCOON - OPEN IN ROBLOX STUDIO

1. Extract this ZIP. The game file is CookieCorner.rbxlx.
2. Install Roblox Studio on Windows or Mac and sign in.
3. Choose File > Open from File (or Open), then select CookieCorner.rbxlx.
4. Choose File > Publish (or Publish to Roblox) to save a new game to your
   Roblox account. Keep access restricted while testing.
   For an existing game, use File > Publish As, select that game's start place,
   and overwrite it after backing up anything you want to keep.
5. Set Maximum Players to 8 in the start place's settings.
6. Open the published game's Roblox page as its owner and click Play.
   Saving works automatically in the Roblox app once the place is published.

THE EDITOR LOOKS EMPTY?
The scripts build the bakeries when a server starts. This is expected.

PLAYING THE GAME
Claim a free bakery at its green pad. You arrive beside the starter oven.
Stand on the next gold cookie pad to buy it with cookie cash; no held E key.
Open Bakery for short controls, Toppings, Quests, and the optional Robux shop.
Talk to Baker Biscuit in the plaza to start a hidden-item hunt for a cash bonus.

WANT TO PREVIEW AN UNPUBLISHED FILE IN STUDIO?
Before pressing Play, open Explorer > ServerScriptService > Tycoon > Settings.
Change AllowStudioSessionOnly = false to AllowStudioSessionOnly = true.
This permits a temporary Studio preview when save data is unavailable.
Progress marked Preview / not saved or STUDIO SESSION ONLY does not save.
Stop the test and change the setting back to false before testing persistent saving.
For saving inside Studio, use a separate published test experience and enable
Studio Access to API Services in its Experience Settings > Security.

FULL SETUP, SAVING, AND PUBLIC ACCESS GUIDE:
https://github.com/Messer252/RobloxGame/blob/main/STUDIO_SETUP.md

ADMIN TOOLS
unbenator is configured as an admin. To add friends, stop the playtest and open
ServerScriptService > Tycoon > AdminConfig. Add their account usernames inside
Usernames in quotes, separated by commas. Publish and restart outdated servers.
Admins open Bakery > Admin tools for kick, spawn return, teleport, bring-player,
wallet/earnings cash gifts, and self-invisibility. Full guide: ADMINS.md in this ZIP.

UPDATING AN EXISTING GAME
Keep the existing DataStore name. After publishing this version, restart outdated
servers: save formats 1-5 migrate to version 6 with existing progress and receipts preserved.
Permanent Robux income tiers survive rebirth. Sales need your own product IDs.
Three obbys grant five-minute income bonuses. See EXPANSION.md on GitHub.
The conveyor update widens the tracks, adds taller rounded outer rails, closes
curve joints, and guides physical cookies through the merge without teleporting.

COOKIE VALLEY FEATURES
See VALLEY.md in this ZIP for the full feature and playtest guide. Home returns
you to your bakery; the road increases walking speed. Collect production cash
at your own register/gold pad. Nearby conveyor cookies show their value.
Bakery > Cookie bag opens inventory, mining, machines, customers, and trades.
The map includes a cookie forest, lake/waterfall, mountains, and day/night.
Before replacing a customized place, copy across your audio IDs, product IDs,
and friends added to AdminConfig. Restart outdated servers after publishing.

NEW BACKGROUND SONG / SAVED VOLUME SLIDERS
This ZIP includes your friend's cookiecookieloop1.ogg. Upload it to Roblox as
audio, grant this experience access, then open ReplicatedStorage > CookieTycoon >
AudioConfig and set MusicAssetId to the resulting numeric Roblox audio ID.
Publish again. Background music stays silent until this is configured.
The song loops at its original speed. Music and SFX have independent saved
0-100% sliders and mute buttons in the HUD. Use drag, tap, or the +/- buttons.
The supplied song is not included in the free asset pack's CC0 license.
Full upload and permissions guide:
https://github.com/Messer252/RobloxGame/blob/main/AUDIO.md

You open CookieCorner.rbxlx in Studio; you do not upload this ZIP or the
src/assets folders as a Roblox model. Scripts and models are already included.
"""


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rojo", default="rojo", help="Rojo executable (default: rojo)")
    options = parser.parse_args()
    subprocess.run([options.rojo, "build", "default.project.json", "-o", str(PLACE)], cwd=ROOT, check=True)

    tree = ET.parse(PLACE).getroot()
    embedded = {}
    for item in tree.iter("Item"):
        properties = item.find("Properties")
        if properties is None:
            continue
        values = {node.get("name"): node.text or "" for node in properties}
        if "Source" in values:
            name = values["Name"]
            assert name not in embedded, f"Duplicate script name: {name}"
            embedded[name] = values["Source"]
    sources = list((ROOT / "src").rglob("*.luau"))
    assert len(embedded) == len(sources), "Packaged script count differs from source"
    for source in sources:
        name = {"init.server.luau": "Tycoon", "init.client.luau": "TycoonUI"}.get(source.name, source.stem)
        assert embedded.get(name) == source.read_text(), f"Stale or missing script: {source}"
    pack = next((item for item in tree.iter("Item")
                 if item.findtext("Properties/string[@name='Name']") == "CookieCornerAssets"), None)
    assert pack is not None, "The game is missing its embedded model pack"

    with ZipFile(ARCHIVE, "w", ZIP_DEFLATED) as archive:
        archive.write(PLACE, PLACE.name)
        archive.writestr("START_HERE.txt", START_HERE)
        archive.write(MUSIC, MUSIC.name)
        archive.write(ROOT / "AUDIO.md", "AUDIO.md")
        archive.write(ROOT / "ADMINS.md", "ADMINS.md")
        archive.write(ROOT / "VALLEY.md", "VALLEY.md")
        archive.write(MUSIC.parent / "README.md", "SONG_CREDIT.txt")
    with ZipFile(ARCHIVE) as archive:
        assert archive.testzip() is None, "Download ZIP failed its integrity check"
        assert archive.read(PLACE.name) == PLACE.read_bytes()
        assert archive.read(MUSIC.name) == MUSIC.read_bytes(), "Packaged song differs from the supplied original"
    # Keep the older local download path current too; build/ stays untracked.
    (ROOT / "build").mkdir(exist_ok=True)
    shutil.copyfile(PLACE, ROOT / "build" / PLACE.name)
    print(f"Verified {len(sources)} embedded scripts and the model pack.")
    print(f"Ready for GitHub: {PLACE.name} and {ARCHIVE.name}")


if __name__ == "__main__":
    main()
