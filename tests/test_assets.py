"""Asset integrity and Roblox import-contract checks, without running Roblox."""
import hashlib
import json
import math
from pathlib import Path
import re
import unittest
from xml.etree import ElementTree as ET

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets"


def name(item):
    return item.findtext("Properties/string[@name='Name']")


class AssetPackTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest = json.loads((ASSETS / "manifest.json").read_text())
        cls.xml = ET.parse(ASSETS / "models/CookieCornerAssets.rbxmx").getroot()
        cls.root = cls.xml.find("Item")
        cls.folders = {name(item): item for item in cls.root.findall("Item")}

    def test_all_recipes_have_one_named_cookie_model(self):
        names = re.findall(r'Name = "([^"]+)"', (ROOT / "src/shared/Recipes.luau").read_text())
        models = self.folders["Cookies"].findall("Item")
        self.assertEqual(len(names), 30)
        self.assertEqual([name(item) for item in models], names)

    def test_asset_pack_is_script_free_and_has_no_external_asset_dependencies(self):
        for item in self.xml.iter("Item"):
            self.assertIn(item.attrib["class"], ("Part", "Model", "Folder"))
        for node in self.xml.iter():
            if node.text:
                self.assertNotIn("rbxassetid://", node.text)
                self.assertNotIn("http://", node.text)
                self.assertNotIn("https://", node.text)
        self.assertEqual(name(self.root), "CookieCornerAssets")

    def test_primary_parts_resolve_locally_and_all_geometry_is_anchored(self):
        for folder in self.folders.values():
            for model in folder.findall("Item"):
                self.assertEqual(model.attrib["class"], "Model")
                ref = model.findtext("Properties/Ref[@name='PrimaryPart']")
                roots = [item for item in model.findall("Item") if item.attrib["referent"] == ref]
                self.assertEqual(len(roots), 1, name(model))
                self.assertEqual(name(roots[0]), "Root")
                for part in model.findall("Item"):
                    self.assertEqual(part.findtext("Properties/bool[@name='Anchored']"), "true")
                    size = part.find("Properties/Vector3[@name='size']")
                    self.assertTrue(all(math.isfinite(float(v.text)) and float(v.text) > 0 for v in size))
                    transform = part.find("Properties/CoordinateFrame[@name='CFrame']")
                    matrix = np.array([[float(transform.findtext(f"R{r}{c}")) for c in range(3)] for r in range(3)])
                    np.testing.assert_allclose(matrix.T @ matrix, np.eye(3), atol=1e-7)
                    self.assertAlmostEqual(float(np.linalg.det(matrix)), 1, places=6)

    def test_all_game_prop_requests_exist_in_the_pack(self):
        props = {name(item) for item in self.folders["Props"].findall("Item")}
        self.assertEqual(len(props), 20)
        world = (ROOT / "src/server/World.luau").read_text()
        requested = set(re.findall(r'prop\(plot, "([^"]+)"', world))
        requested.update(re.findall(r'Assets\.prop\("([^"]+)"', world))
        self.assertLessEqual(requested, props)  # The physical belts replace the optional Conveyor prop.
        oven = next(item for item in self.folders["Props"].findall("Item") if name(item) == "Oven")
        self.assertIn("RecipeBadge", {name(item) for item in oven.findall("Item")})
        self.assertIn("Window", {name(item) for item in oven.findall("Item")})
        claim = next(item for item in self.folders["Props"].findall("Item") if name(item) == "ClaimPad")
        self.assertIn("Claim Surface", {name(item) for item in claim.findall("Item")})
        counter = next(item for item in self.folders["Props"].findall("Item") if name(item) == "PrepCounter")
        self.assertIn("Texture_CounterMarble", {name(item) for item in counter.findall("Item")})

    def test_png_sizes_hashes_and_opposite_edges_match(self):
        records = self.manifest["textures"]
        self.assertEqual(len(records), 42)
        for record in records:
            file = ASSETS / record["file"]
            self.assertEqual(hashlib.sha256(file.read_bytes()).hexdigest(), record["sha256"])
            with Image.open(file) as image:
                self.assertEqual(image.size, (512, 512))
                self.assertEqual(image.mode, "RGB")
                array = np.asarray(image)
                np.testing.assert_array_equal(array[0], array[-1])
                np.testing.assert_array_equal(array[:, 0], array[:, -1])
                self.assertGreater(float(array.std()), 1, record["key"])

    def test_texture_slots_cover_every_png_and_model_surface(self):
        texture_keys = {item["key"] for item in self.manifest["textures"]}
        slots = set(re.findall(r'(\w+) = ""', (ROOT / "src/server/AssetTextures.luau").read_text()))
        self.assertEqual(texture_keys, slots)
        for item in self.xml.iter("Item"):
            if item.attrib["class"] == "Part" and name(item).startswith("Texture_"):
                self.assertIn(name(item)[8:], slots)

    def test_manifest_matches_models_and_limits_cookie_geometry(self):
        entries = {(record["category"], record["name"]): record for record in self.manifest["models"]}
        self.assertEqual(len(entries), 50)
        for category, folder in self.folders.items():
            for model in folder.findall("Item"):
                entry = entries[(category, name(model))]
                self.assertEqual(entry["parts"], len(model.findall("Item")))
                if category == "Cookies": self.assertLessEqual(entry["parts"], 20)
        self.assertEqual(self.manifest["license"], "CC0-1.0")
        self.assertIn("CC0", (ASSETS / "LICENSE.txt").read_text())

    def test_rojo_loads_the_model_pack_into_server_storage(self):
        project = json.loads((ROOT / "default.project.json").read_text())
        path = project["tree"]["ServerStorage"]["CookieCornerAssets"]["$path"]
        self.assertEqual((ROOT / path).resolve(), (ASSETS / "models/CookieCornerAssets.rbxmx").resolve())


if __name__ == "__main__":
    unittest.main()
