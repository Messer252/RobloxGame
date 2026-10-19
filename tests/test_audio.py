"""Check the actual original WAV deliverables and Roblox upload constraints."""
import hashlib
import json
import struct
from pathlib import Path
import unittest
import wave

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
AUDIO = ROOT / "assets/audio"


class AudioPackTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest = json.loads((AUDIO / "manifest.json").read_text())

    def read_audio(self, name):
        with wave.open(str(AUDIO / name)) as stream:
            signal = np.frombuffer(stream.readframes(stream.getnframes()), dtype="<i2")
            return signal.reshape(-1, stream.getnchannels()).astype(float) / 32768

    def test_every_original_recording_matches_manifest_and_roblox_limits(self):
        self.assertEqual(self.manifest["license"], "CC0-1.0")
        self.assertEqual(len(self.manifest["files"]), 10)
        for record in self.manifest["files"]:
            path = AUDIO / record["file"]
            self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), record["sha256"])
            self.assertLess(path.stat().st_size, 20 * 1024 * 1024)
            with wave.open(str(path)) as stream:
                self.assertEqual(stream.getnchannels(), 2)
                self.assertEqual(stream.getsampwidth(), 2)
                self.assertEqual(stream.getframerate(), 32000)
                self.assertAlmostEqual(stream.getnframes() / stream.getframerate(), record["seconds"])
                self.assertGreater(record["seconds"], .1)
                self.assertLess(record["seconds"], 420)

    def test_audio_is_audible_without_clipping_or_dc_offset(self):
        for record in self.manifest["files"]:
            signal = self.read_audio(record["file"])
            self.assertGreater(float(np.sqrt(np.mean(signal ** 2))), .01, record["file"])
            self.assertLess(float(np.max(np.abs(signal))), .9, record["file"])
            self.assertLess(float(np.max(np.abs(signal.mean(axis=0)))), .002, record["file"])

    def test_music_has_full_bar_length_and_a_continuous_loop_boundary(self):
        signal = self.read_audio("CookieCornerCafe.wav")
        self.assertAlmostEqual(len(signal) / 32000, self.manifest["beats"] * 60 / self.manifest["bpm"], places=4)
        boundary_step = np.max(np.abs(signal[0] - signal[-1]))
        typical_loud_steps = np.quantile(np.abs(np.diff(signal, axis=0)), .99)
        self.assertLess(boundary_step, typical_loud_steps)
        for chunk in np.array_split(signal, 16):
            self.assertGreater(float(np.sqrt(np.mean(chunk ** 2))), .03)

    def test_sound_cues_end_silently_and_match_the_configurable_names(self):
        names = {record["file"][:-4] for record in self.manifest["files"] if record["file"] != "CookieCornerCafe.wav"}
        self.assertEqual(names, {"Click", "Claim", "Collect", "BuyRecipe", "UpgradeOven", "BuyModifier", "UpgradePermanent", "Rebirth", "Error"})
        for name in names:
            signal = self.read_audio(name + ".wav")
            self.assertLess(float(np.max(np.abs(signal[-160:]))), .001)

    def test_supplied_song_preserves_original_bytes_and_valid_vorbis_upload_format(self):
        path = AUDIO / "friend/cookiecookieloop1.ogg"
        data = path.read_bytes()
        self.assertEqual(len(data), 2145921)
        self.assertEqual(hashlib.sha256(data).hexdigest(), "05c0fab98151553ca1e934024a02d80fbdf5ec78a92643166321377fa1093d4a")
        self.assertEqual(data[:4], b"OggS")
        header = data.index(b"\x01vorbis")
        self.assertEqual(data[header + 11], 2)
        self.assertEqual(struct.unpack_from("<I", data, header + 12)[0], 44100)
        self.assertLess(len(data), 20 * 1024 * 1024)
        self.assertIn("NOT included in this CC0", (ROOT / "assets/LICENSE.txt").read_text())


if __name__ == "__main__":
    unittest.main()
