"""Validate the generated artwork delivered for the game's forty-card atlas."""
from pathlib import Path
import re
import unittest
from PIL import Image
ROOT = Path(__file__).resolve().parents[1]
class CardArtTests(unittest.TestCase):
    def test_atlas_is_a_valid_image_with_the_configured_dimensions(self):
        with Image.open(ROOT / 'assets/cards/CookieAnimals.png') as image:
            self.assertEqual(image.format, 'PNG')
            self.assertEqual(image.size, (1586, 992))
            self.assertGreater(image.width / 8, 190)
            self.assertGreater(image.height / 5, 190)
            image.verify()
    def test_gallery_contains_all_forty_illustrations_and_quips(self):
        gallery = (ROOT / 'assets/cards/Gallery.html').read_text()
        self.assertEqual(gallery.count('<article '), 40)
        self.assertEqual(gallery.count('class="Common"'), 15)
        self.assertEqual(gallery.count('class="Legendary"'), 3)
        self.assertEqual(gallery.count('class="Mythical"'), 5)
        self.assertIn('Mint Chocolate Dragon', gallery)
    def test_runtime_atlas_configuration_matches_the_delivered_grid(self):
        source = (ROOT / 'src/shared/CardCatalog.luau').read_text()
        self.assertIn('ArtColumns = 8, ArtRows = 5, ArtWidth = 1586, ArtHeight = 992', source)
        entries = re.findall(r'^\s*\{ "[^"]+", "[^"]+", "[^"]+", "(?:Cash|Speed|Sales|Crumbs|Mine)"', source, re.M)
        self.assertEqual(len(entries), 40)
if __name__ == '__main__': unittest.main()
