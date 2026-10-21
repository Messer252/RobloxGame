"""Build and check the ready-to-open Studio downloads published on GitHub.

Run from any directory: python tools/package_studio.py --rojo /path/to/rojo
Requires Rojo 7.7.1; no third-party Python packages are needed.
"""
from __future__ import annotations

import argparse
import re
from pathlib import Path
import shutil
import subprocess
from xml.etree import ElementTree as ET
from zipfile import ZIP_DEFLATED, ZipFile

ROOT = Path(__file__).resolve().parents[1]
PLACE = ROOT / "CookieCorner.rbxlx"
ARCHIVE = ROOT / "CookieCorner_Studio.zip"
MUSIC = ROOT / "assets/audio/CookieCornerCafe.wav"
EFFECT_AUDIO = [ROOT / "assets/audio/MeteorCrash.wav", ROOT / "assets/audio/MeteorIncoming.wav", ROOT / "assets/audio/PinSwing.wav", ROOT / "assets/audio/OreHit.wav"]

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
Open Bakery for Toppings, Quests, Audio levels, and the optional Robux shop.
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

AUDIO AND TCG IMAGE UPLOAD GUIDE:
Open UPLOAD-ASSETS.md in this ZIP, or read it on GitHub:
https://github.com/Messer252/RobloxGame/blob/main/UPLOAD-ASSETS.md
OGG audio is supported. The guide covers permissions and every asset ID slot.

ADMIN TOOLS
unbenator is configured as an admin. To add friends, stop the playtest and open
ServerScriptService > Tycoon > AdminConfig. Add their account usernames inside
Usernames in quotes, separated by commas. Publish and restart outdated servers.
Admins open Bakery > Admin tools for kick, spawn return, teleport, bring-player,
wallet/earnings cash gifts, and self-invisibility. Full guide: ADMINS.md in this ZIP.

UPDATING AN EXISTING GAME
Keep the existing DataStore name. After publishing this version, restart outdated
servers: save formats 1-11 migrate to version 12 with existing progress and receipts preserved.
Permanent Robux income tiers survive rebirth. Sales need your own product IDs.
Three obbys grant five-minute income bonuses. See EXPANSION.md on GitHub.
The conveyor update widens the tracks, adds taller rounded outer rails, closes
curve joints, and guides physical cookies through the merge without teleporting.

COMBAT ABILITIES AND OBBY FINISHES
Read COMBAT-AND-OBBY.md. Buy E/Q moves with dough at the mine workshop,
equip your pin, and use E/Q or the touch buttons. Six moves have animations,
cooldowns and server-validated combat. Abilities reset on rebirth.
Obby landing contacts now complement polling; validated prizes retry through
busy saves. Finish messages explain any Star Crumb cooldown.

NIGHT AND PROGRESSION UPDATE
Read NIGHT-AND-PROGRESSION.md. Rebirths now continue past 50 with growing
requirements and income. Cash rankings track lifetime earnings across rebirths.
Existing totals start from saved wallet + bank; old spent cash is unrecoverable.
Bought mine upgrades reset on rebirth; unspent dough stays. Sprint/Leap improve
movement. Collapse the HUD with minus. Purchase cards now have 3D previews.
Fight night creatures and a co-op boss every 30 minutes in the east wilderness.
Audio mute buttons and sliders are together in Bakery > Audio.

COOKIE VALLEY FEATURES
See VALLEY.md in this ZIP for the full feature and playtest guide. Home returns
you to your bakery; the road increases walking speed. Collect production cash
at your own register/gold pad. Nearby conveyor cookies show their value.
Bakery > Cookie bag opens inventory, mining, machines, customers, and trades.
The map includes a cookie forest, lake/waterfall, mountains, and day/night.
Before replacing a customized place, copy across your audio IDs, product IDs,
and friends added to AdminConfig. Restart outdated servers after publishing.

CAVE AND PRESTIGE UPDATE
Read CAVE-AND-PRESTIGE.md. Explore five ore galleries unlocked by better pins.
Save extra cash for bonus Golden Chips; the rebirth menu previews your payout.
Admins can grant Golden Chips and Star Crumbs. Shift, controller R3 or
the Aim button toggles shoulder camera lock. It cancels for menus and flight; toggle it again when ready.
PinSwing.wav and OreHit.wav are optional uploads; built-in cues work first.

OBBYS, SIDE MARKET AND ENCHANTED GEAR
Read OBBYS-AND-FORGE.md. Harder obbys have cleared pits and red restart hazards.
The side-market branch extends the fast road to the Pack House and blacksmith.
There are 13 rolling-pin and armor tiers. Open Enchant equipment at Bruno to
roll for 100 Star Crumbs; your best enchantment stays through rebirth/upgrades.
Rebirth resets your pin to Maple and removes armor. Enchantments stay saved;
armor enchantments activate again when you repurchase armor.
New gear models and rarity effects require no additional uploads.

NPC MOVEMENT AND MODELS
See NPC-UPDATE.md for the walking changes and Studio playtest checklist.
Customers use short pathfinding routes and resume after bargaining. All NPCs
have new fitted outfits, and Poppy now serves the Pack House counter.
No additional asset uploads are required.

CODE REVIEW AND POLISH
See POLISH-REVIEW.md for fixes and focused playtests. Starter conveyors now
keep their complete route through the merge. Menus preserve typed shop names
and focus during updates. Audio choices retry while transactions are busy.
Obby finishes show their actual rewards and consistently advance quests.

SPAWN MARKET UPDATE
See MARKET-UPDATE.md in this ZIP for controls, prices and playtests.
Visit Bruno at the side-market blacksmith for cookie armor and better rolling pins.
Claim 100 daily crumbs at the Pack House; earn more from public trail pickups,
jobs, mining, production and obbys. Captured hills keep paying while you remain
online in that server until contested or recaptured. Logging out releases them.
Decoration pads unlock in three spaced paths. New fitted walls/windows/doors,
roof and soft lighting leave conveyor lanes clear. Floors are less bright.

NEW WORKSHOP CONTROLS AND MUSIC
Select Cookie Bag in the Roblox hotbar to open inventory. Enter the cave and
left-click with your rolling pin to swing; there is no E mining prompt.
New players build the first conveyor free at Build Conveyor before producing.
Buy more lines, walls, windows, doors, plants, and trees with cookie cash.
Cookie sharing is a free gift with accept/decline notifications, never a fee.
Biscuit gives varied randomized jobs; item waypoints have been removed.
See CARDS-AND-EVENTS.md for the latest features, prices, and playtests.
Rebirth clears bag cookies, conveyors, machines and decorations; cards and Star
Crumbs survive. Entrances/registers now face the road and terrain is continuous.
Visit the Crumbkin Pack House in the side market to buy and rip five earned-currency
packs. Cookie Bag > Collection views/equips your 40 animal cards (two free slots).
Upload CookieTCG_01.png through CookieTCG_04.png as Roblox images and set
each matching Id in CardCatalog.ArtSheets. The compass is removed.
Preview.png shows the card artwork. The optional browser gallery is not included
in this Studio download; the game does not need it.
The optional third card-slot pass needs your own ID and a 150 Robux price in
Creator Dashboard. It stays disabled at ID 0. See the full guide for setup.
Meteors arrive every random 5-30 minutes; Cookie Hill is the only PvP area.
Meteor arrivals and impacts have server-wide banners and built-in audio cues.
Upload the included MeteorCrash.wav to Roblox for the full original 8-bit crash,
grant the experience permission, then set AudioConfig.Effects.MeteorCrash.
Both plaza boards now show saved global rankings, including offline players.
Existing saves import gradually in the background; boards refresh every minute.

Valley Afterglow is the new original ambient soundtrack. Its built-in score
plays immediately; Music and SFX retain independent saved volume sliders.
Volume sliders are now under Bakery > Audio.
CookieCornerCafe.wav is the optional full mix. To use it, upload it to Roblox,
grant your experience access, and put its numeric ID in AudioConfig.MusicAssetId.
The previous friend's song is no longer selected or included in this ZIP.
See AUDIO.md for optional upload instructions and playback checks.

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
    parents = {child: item for item in tree.iter("Item") for child in item.findall("Item")}
    local_require = re.compile(r'require\(script((?:\.Parent)*)(?:\.([A-Za-z_]\w*)|:WaitForChild\("([A-Za-z_]\w*)"\))\)')
    for item in tree.iter("Item"):
        source = item.findtext("Properties/ProtectedString[@name='Source']")
        if not source:
            continue
        for ancestry, direct, waited in local_require.findall(source):
            parent = item
            for _ in range(ancestry.count(".Parent")):
                parent = parents.get(parent)
                assert parent is not None, "Local require climbs above its script tree"
            name = direct or waited
            target = next((child for child in parent.findall("Item")
                           if child.findtext("Properties/string[@name='Name']") == name), None)
            assert target is not None and target.get("class") == "ModuleScript", f"Missing local module: {name}"
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
        for effect in EFFECT_AUDIO:
            archive.write(effect, effect.name)
        archive.write(ROOT / "COMBAT-AND-OBBY.md", "COMBAT-AND-OBBY.md")
        archive.write(ROOT / "NIGHT-AND-PROGRESSION.md", "NIGHT-AND-PROGRESSION.md")
        archive.write(ROOT / "AUDIO.md", "AUDIO.md")
        archive.write(ROOT / "UPLOAD-ASSETS.md", "UPLOAD-ASSETS.md")
        archive.write(ROOT / "ADMINS.md", "ADMINS.md")
        archive.write(ROOT / "VALLEY.md", "VALLEY.md")
        archive.write(ROOT / "WORKSHOP.md", "WORKSHOP.md")
        archive.write(ROOT / "MARKET-UPDATE.md", "MARKET-UPDATE.md")
        archive.write(ROOT / "POLISH-REVIEW.md", "POLISH-REVIEW.md")
        archive.write(ROOT / "NPC-UPDATE.md", "NPC-UPDATE.md")
        archive.write(ROOT / "CAVE-AND-PRESTIGE.md", "CAVE-AND-PRESTIGE.md")
        archive.write(ROOT / "OBBYS-AND-FORGE.md", "OBBYS-AND-FORGE.md")
        archive.write(ROOT / "CARDS-AND-EVENTS.md", "CARDS-AND-EVENTS.md")
        for sheet in sorted((ROOT / "assets/cards").glob("CookieTCG_*.png")):
            archive.write(sheet, sheet.name)
        archive.write(ROOT / "assets/cards/Preview.png", "Preview.png")
        archive.write(ROOT / "assets/cards/README.md", "CARD_ART_SETUP.md")
        archive.write(ROOT / "assets/LICENSE.txt", "ASSET_LICENSE.txt")
    with ZipFile(ARCHIVE) as archive:
        assert archive.testzip() is None, "Download ZIP failed its integrity check"
        # Keep browser previews and OS scripts/executables out of game downloads.
        # Every entry is a plain root-level place, image, audio file or guide.
        allowed = {".rbxlx", ".png", ".wav", ".md", ".txt"}
        for entry in archive.infolist():
            path = Path(entry.filename)
            assert path.name == entry.filename and path.suffix.lower() in allowed, "Unexpected download file type/path"
            assert not entry.flag_bits & 1, "Unexpected encrypted ZIP entry"
        assert "CardGallery.html" not in archive.namelist(), "Browser preview must not be bundled"
        assert archive.read(PLACE.name) == PLACE.read_bytes()
        assert archive.read("COMBAT-AND-OBBY.md") == (ROOT / "COMBAT-AND-OBBY.md").read_bytes(), "Packaged combat guide is stale"
        assert archive.read("NIGHT-AND-PROGRESSION.md") == (ROOT / "NIGHT-AND-PROGRESSION.md").read_bytes(), "Packaged progression guide is stale"
        assert archive.read("OBBYS-AND-FORGE.md") == (ROOT / "OBBYS-AND-FORGE.md").read_bytes(), "Packaged forge guide is stale"
        assert archive.read("CAVE-AND-PRESTIGE.md") == (ROOT / "CAVE-AND-PRESTIGE.md").read_bytes(), "Packaged cave guide is stale"
        assert archive.read("NPC-UPDATE.md") == (ROOT / "NPC-UPDATE.md").read_bytes(), "Packaged NPC guide is stale"
        assert archive.read("POLISH-REVIEW.md") == (ROOT / "POLISH-REVIEW.md").read_bytes(), "Packaged review guide is stale"
        assert archive.read("MARKET-UPDATE.md") == (ROOT / "MARKET-UPDATE.md").read_bytes(), "Packaged market guide is stale"
        assert archive.read("UPLOAD-ASSETS.md") == (ROOT / "UPLOAD-ASSETS.md").read_bytes(), "Packaged upload guide is stale"
        assert archive.read(MUSIC.name) == MUSIC.read_bytes(), "Packaged song differs from the supplied original"
        for effect in EFFECT_AUDIO:
            assert archive.read(effect.name) == effect.read_bytes(), "Packaged effect differs from the generated WAV"
        sheets = sorted((ROOT / "assets/cards").glob("CookieTCG_*.png"))
        assert len(sheets) == 4, "Expected four TCG art sheets"
        for sheet in sheets:
            assert archive.read(sheet.name) == sheet.read_bytes(), "Card art differs from the generated sheet"
    # Keep the older local download path current too; build/ stays untracked.
    (ROOT / "build").mkdir(exist_ok=True)
    shutil.copyfile(PLACE, ROOT / "build" / PLACE.name)
    print(f"Verified {len(sources)} embedded scripts and the model pack.")
    print(f"Ready for GitHub: {PLACE.name} and {ARCHIVE.name}")


if __name__ == "__main__":
    main()
