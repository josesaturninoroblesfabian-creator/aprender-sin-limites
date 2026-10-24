import hashlib
import unittest

from tools.story_audio_metadata import timing_matches, timing_sha256


class StoryAudioMetadataTest(unittest.TestCase):
    LF = b'{"text":"Hola","words":[{"start":0,"end":1}]}\n'
    CRLF = LF.replace(b"\n", b"\r\n")

    def test_checkout_preserves_legacy_windows_manifest(self):
        legacy = hashlib.sha256(self.CRLF).hexdigest()
        self.assertTrue(timing_matches(self.LF, legacy))

    def test_canonical_hash_survives_windows_newlines(self):
        self.assertEqual(timing_sha256(self.LF), timing_sha256(self.CRLF))
        self.assertTrue(timing_matches(self.CRLF, timing_sha256(self.LF)))

    def test_changed_narration_is_rejected(self):
        changed = self.LF.replace(b"Hola", b"Adios")
        self.assertFalse(timing_matches(changed, timing_sha256(self.LF)))

    def test_changed_timing_is_rejected(self):
        changed = self.LF.replace(b'"end":1', b'"end":2')
        self.assertFalse(timing_matches(changed, hashlib.sha256(self.CRLF).hexdigest()))


if __name__ == "__main__":
    unittest.main()
