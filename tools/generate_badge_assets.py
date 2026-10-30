"""
=============================================================================
FORGE Badge Asset Generator
=============================================================================

Purpose:
    Generates the PF.005 application attention badge images used by the
    ForgeOS Phone and Laptop Hosts.

Responsibilities:
    • Draw anti-aliased badge shapes with rounded corners.
    • Write RGBA PNG files into forgeos/assets.

Design Principles:
    • Pure standard library; no imaging package is required.
    • Deterministic: the same script always produces identical files.
    • Each image is a white shape (alpha-shaped) with any glyph baked in near
      black, so a Host can tint it with a semantic colour at draw time.
    • The repository asset files are authoritative; run this tool only to
      regenerate them after a deliberate design change.

Usage:
    python tools/generate_badge_assets.py
=============================================================================
"""

from __future__ import annotations

import math
from pathlib import Path
import struct
import zlib


REPOSITORY_ROOT = Path(__file__).resolve().parent.parent
OUTPUT_DIRECTORY = REPOSITORY_ROOT / "forgeos" / "assets"
SUPERSAMPLE = 4
GLYPH_VALUE = 18  # near-black glyph baked into the white shape


def segment_distance(px, py, ax, ay, bx, by):
    """Distance from a point to a line segment."""
    dx, dy = bx - ax, by - ay
    length_squared = dx * dx + dy * dy
    if length_squared == 0:
        return math.hypot(px - ax, py - ay)
    t = max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / length_squared))
    return math.hypot(px - (ax + t * dx), py - (ay + t * dy))


def inside_convex(px, py, vertices):
    """True when the point lies inside a convex polygon (either winding)."""
    count = len(vertices)
    negative = positive = False
    for index in range(count):
        ax, ay = vertices[index]
        bx, by = vertices[(index + 1) % count]
        side = (bx - ax) * (py - ay) - (by - ay) * (px - ax)
        negative = negative or side < 0
        positive = positive or side > 0
    return not (negative and positive)


def distance_to_convex(px, py, vertices):
    """Distance from a point to a convex polygon (zero when inside)."""
    if inside_convex(px, py, vertices):
        return 0.0
    count = len(vertices)
    return min(
        segment_distance(px, py, *vertices[i], *vertices[(i + 1) % count])
        for i in range(count)
    )


def circle(cx, cy, radius):
    return lambda x, y: math.hypot(x - cx, y - cy) <= radius


def stadium(ax, ay, bx, by, radius):
    return lambda x, y: segment_distance(x, y, ax, ay, bx, by) <= radius


def rounded_box(x0, y0, x1, y1, radius):
    def test(x, y):
        return distance_to_convex(
            x, y,
            [(x0 + radius, y0 + radius), (x1 - radius, y0 + radius),
             (x1 - radius, y1 - radius), (x0 + radius, y1 - radius)]
        ) <= radius
    return test


def rounded_triangle(vertices, radius):
    """Triangle with rounded corners: shrink about the incentre, then dilate."""
    (ax, ay), (bx, by), (cx, cy) = vertices
    a = math.hypot(bx - cx, by - cy)
    b = math.hypot(ax - cx, ay - cy)
    c = math.hypot(ax - bx, ay - by)
    perimeter = a + b + c
    ix = (a * ax + b * bx + c * cx) / perimeter
    iy = (a * ay + b * by + c * cy) / perimeter
    area = abs((bx - ax) * (cy - ay) - (cx - ax) * (by - ay)) / 2
    inradius = 2 * area / perimeter
    factor = (inradius - radius) / inradius
    shrunk = [(ix + (x - ix) * factor, iy + (y - iy) * factor)
              for x, y in vertices]
    return lambda x, y: distance_to_convex(x, y, shrunk) <= radius


def union(*tests):
    return lambda x, y: any(test(x, y) for test in tests)


def exclamation(cx, top, bottom, width, dot_radius):
    """Exclamation mark: a bar above a dot, in unit coordinates (y down)."""
    bar_radius = width / 2
    return union(
        stadium(cx, top + bar_radius, cx, bottom - 3.2 * dot_radius,
                bar_radius),
        circle(cx, bottom - dot_radius, dot_radius),
    )


def cross(cx, cy, reach, radius):
    return union(
        stadium(cx - reach, cy - reach, cx + reach, cy + reach, radius),
        stadium(cx - reach, cy + reach, cx + reach, cy - reach, radius),
    )


def render(width, height, shape, glyph=None):
    """Render to RGBA bytes. Shape and glyph are tests in unit coordinates
    where x spans 0..width/height and y spans 0..1 (y down)."""
    aspect = width / height
    rows = []
    samples = SUPERSAMPLE * SUPERSAMPLE
    for py in range(height):
        row = bytearray([0])  # PNG filter type 0
        for px in range(width):
            covered = glyphs = 0
            for sy in range(SUPERSAMPLE):
                for sx in range(SUPERSAMPLE):
                    x = (px + (sx + 0.5) / SUPERSAMPLE) / width * aspect
                    y = (py + (sy + 0.5) / SUPERSAMPLE) / height
                    if shape(x, y):
                        covered += 1
                        if glyph is not None and glyph(x, y):
                            glyphs += 1
            if covered == 0:
                row += bytes((255, 255, 255, 0))
                continue
            value = round(255 - (255 - GLYPH_VALUE) * glyphs / covered)
            alpha = round(255 * covered / samples)
            row += bytes((value, value, value, alpha))
        rows.append(bytes(row))
    return rows


def write_png(path, width, height, rows):
    def chunk(tag, data):
        body = tag + data
        return (struct.pack(">I", len(data)) + body
                + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF))

    header = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    payload = (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", header)
               + chunk(b"IDAT", zlib.compress(b"".join(rows), 9))
               + chunk(b"IEND", b""))
    path.write_bytes(payload)


def assets():
    """Return {filename: (width, height, shape, glyph)}."""
    return {
        "badge_unread_circle.png": (
            128, 128, circle(0.5, 0.5, 0.5), None),
        "badge_unread_pill.png": (
            256, 128, stadium(0.5, 0.5, 1.5, 0.5, 0.5), None),
        "badge_attention.png": (
            128, 128, circle(0.5, 0.5, 0.5),
            exclamation(0.5, 0.20, 0.80, 0.15, 0.085)),
        "badge_warning.png": (
            128, 128,
            rounded_triangle([(0.5, 0.04), (0.04, 0.92), (0.96, 0.92)], 0.07),
            exclamation(0.5, 0.36, 0.80, 0.13, 0.075)),
        "badge_error.png": (
            128, 128, rounded_box(0.0, 0.0, 1.0, 1.0, 0.22),
            cross(0.5, 0.5, 0.20, 0.07)),
    }


def main() -> None:
    OUTPUT_DIRECTORY.mkdir(parents=True, exist_ok=True)
    for name, (width, height, shape, glyph) in assets().items():
        write_png(OUTPUT_DIRECTORY / name, width, height,
                  render(width, height, shape, glyph))
        print(f"wrote {name} ({width}x{height})")


if __name__ == "__main__":
    main()
