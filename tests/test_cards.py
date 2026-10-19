"""Validate the generated artwork delivered for the game's forty-card atlas."""
from pathlib import Path
import re
import unittest
from PIL import Image
ROOT = Path(__file__).resolve().parents[1]
class CardArtTests(unittest.TestCase):
    def sheets(self):
        source = (ROOT / 'src/shared/CardCatalog.luau').read_text()
        entries = re.findall(r'File = "(CookieTCG_\d+\.png)", Width = (\d+), Height = (\d+), Columns = (\d+), Rows = (\d+), First = (\d+), Last = (\d+)', source)
        self.assertEqual(len(entries), 4)
        return entries

    def test_atlas_is_a_valid_image_with_the_configured_dimensions(self):
        for filename, width, height, columns, rows, first, last in self.sheets():
            with Image.open(ROOT / 'assets/cards' / filename) as image:
                self.assertEqual(image.format, 'PNG')
                self.assertEqual(image.size, (int(width), int(height)))
                self.assertGreaterEqual(image.width / int(columns), 300)
                self.assertGreaterEqual(image.height / int(rows), 300)
                image.verify()
    def test_gallery_contains_all_forty_illustrations_and_quips(self):
        gallery = (ROOT / 'assets/cards/Gallery.html').read_text()
        self.assertEqual(gallery.count('<article '), 40)
        self.assertEqual(gallery.count('class="Common"'), 15)
        self.assertEqual(gallery.count('class="Legendary"'), 3)
        self.assertEqual(gallery.count('class="Mythical"'), 5)
        self.assertIn('Mint Chocolate Dragon', gallery)
    def test_runtime_atlas_configuration_matches_the_delivered_grid(self):
        covered = []
        for filename, width, height, columns, rows, first, last in self.sheets():
            first, last, columns, rows = map(int, (first, last, columns, rows))
            self.assertEqual(columns * rows, last - first + 1)
            covered.extend(range(first, last + 1))
        self.assertEqual(covered, list(range(1, 41)))
        source = (ROOT / 'src/shared/CardCatalog.luau').read_text()
        entries = re.findall(r'^\s*\{ "[^"]+", "[^"]+", "[^"]+", "(?:Cash|Speed|Sales|Crumbs|Mine)"', source, re.M)
        self.assertEqual(len(entries), 40)
if __name__ == '__main__': unittest.main()
