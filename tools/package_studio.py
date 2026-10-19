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

UPDATING AN EXISTING GAME
Keep the existing DataStore name. After publishing this version, restart outdated
servers: save formats 1-4 migrate to version 5 with quest progress and receipts preserved.
Permanent Robux income tiers survive rebirth. Sales need your own product IDs.
Three obbys grant five-minute income bonuses. See EXPANSION.md on GitHub.

OPTIONAL FULL MUSIC RECORDING / AUDIO SETUP:
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
    with ZipFile(ARCHIVE) as archive:
        assert archive.testzip() is None, "Download ZIP failed its integrity check"
        assert archive.read(PLACE.name) == PLACE.read_bytes()
    # Keep the older local download path current too; build/ stays untracked.
    (ROOT / "build").mkdir(exist_ok=True)
    shutil.copyfile(PLACE, ROOT / "build" / PLACE.name)
    print(f"Verified {len(sources)} embedded scripts and the model pack.")
    print(f"Ready for GitHub: {PLACE.name} and {ARCHIVE.name}")


if __name__ == "__main__":
    main()
