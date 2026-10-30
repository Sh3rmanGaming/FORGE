"""Regression tests for the PF.005 badge asset generator."""

from __future__ import annotations

import importlib.util
from pathlib import Path
import struct
import tempfile
import unittest
import zlib


TOOLS = Path(__file__).resolve().parent.parent


def load(name: str):
    spec = importlib.util.spec_from_file_location(name, TOOLS / f"{name}.py")
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


generator = load("generate_badge_assets")


def decode(path: Path):
    """Return (width, height, rows of RGBA tuples) for a generator PNG."""
    data = path.read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n"
    width, height = struct.unpack(">II", data[16:24])
    offset, idat = 8, b""
    while offset < len(data):
        length = struct.unpack(">I", data[offset:offset + 4])[0]
        tag = data[offset + 4:offset + 8]
        if tag == b"IDAT":
            idat += data[offset + 8:offset + 8 + length]
        offset += 12 + length
    raw = zlib.decompress(idat)
    stride = 1 + width * 4
    rows = []
    for y in range(height):
        row = raw[y * stride + 1:(y + 1) * stride]
        rows.append([tuple(row[x * 4:x * 4 + 4]) for x in range(width)])
    return width, height, rows


class BadgeAssetTests(unittest.TestCase):
    def test_committed_assets_match_the_generator(self):
        with tempfile.TemporaryDirectory() as directory:
            for name, (width, height, shape, glyph) in (
                generator.assets().items()
            ):
                temporary = Path(directory) / name
                generator.write_png(
                    temporary, width, height,
                    generator.render(width, height, shape, glyph))
                committed = generator.OUTPUT_DIRECTORY / name
                self.assertTrue(committed.exists(), name)
                self.assertEqual(
                    temporary.read_bytes(), committed.read_bytes(), name)

    def test_shapes_are_rounded_and_opaque_in_the_middle(self):
        for name in generator.assets():
            width, height, rows = decode(generator.OUTPUT_DIRECTORY / name)
            self.assertEqual(rows[0][0][3], 0, f"{name} corner not clear")
            centre = rows[height // 2][width // 2]
            self.assertGreater(centre[3], 0, f"{name} centre empty")

    def test_plain_unread_shapes_have_no_glyph(self):
        for name in ("badge_unread_circle.png", "badge_unread_pill.png"):
            width, height, rows = decode(generator.OUTPUT_DIRECTORY / name)
            self.assertEqual(rows[height // 2][width // 2], (255, 255, 255, 255))

    def test_glyph_shapes_carry_a_dark_glyph(self):
        for name in ("badge_attention.png", "badge_warning.png",
                     "badge_error.png"):
            _, _, rows = decode(generator.OUTPUT_DIRECTORY / name)
            darkest = min(pixel[0] for row in rows for pixel in row
                          if pixel[3] == 255)
            self.assertLess(darkest, 60, f"{name} has no dark glyph")


if __name__ == "__main__":
    unittest.main()
