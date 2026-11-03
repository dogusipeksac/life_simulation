import unittest
from pathlib import Path

class TestReleaseAutomation(unittest.TestCase):
    def test_notes_exist(self):
        root = Path(__file__).resolve().parent.parent.parent
        self.assertTrue((root / "release_notes/1.0.0/ios.txt").is_file())
        self.assertTrue((root / "release_notes/1.0.0/android.txt").is_file())

    def test_fastfile_syntax(self):
        root = Path(__file__).resolve().parent.parent.parent
        fastfile = root / "release/fastlane/Fastfile"
        self.assertTrue(fastfile.is_file())
        content = fastfile.read_text(encoding="utf-8")
        self.assertIn("tf_upload", content)
        self.assertIn("apple_api_key", content)

if __name__ == "__main__":
    unittest.main()
