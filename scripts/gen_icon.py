#!/usr/bin/env python3
"""Generate a minimal Olive Dream theme icon: a soft olive circular gradient
with a white leaf, transparent background, 1:1, no text."""
from PIL import Image, ImageDraw
import math

SIZE = 256
CENTER = SIZE / 2.0
RADIUS = 118.0

LIGHT_SAGE = (0xC5, 0xD8, 0x9D)  # #C5D89D
OLIVE = (0x89, 0x98, 0x6D)        # #89986D
CREAM = (0xF8, 0xF6, 0xEA)        # highlight tint
WHITE = (255, 255, 255)
VEIN = (0x89, 0x98, 0x6D)         # olive vein


def lerp(a, b, t):
    return int(round(a + (b - a) * t))


def lerp_color(c1, c2, t):
    return (lerp(c1[0], c2[0], t), lerp(c1[1], c2[1], t), lerp(c1[2], c2[2], t))


img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
pix = img.load()

# Radial gradient circle (premium: slightly ease toward center highlight)
for y in range(SIZE):
    for x in range(SIZE):
        dx = x - CENTER
        dy = y - CENTER
        dist = math.hypot(dx, dy)
        if dist > RADIUS:
            continue
        t = (dist / RADIUS) ** 0.85
        col = lerp_color(LIGHT_SAGE, OLIVE, t)
        # subtle cream highlight near top-left
        highlight = max(0.0, 1.0 - (dist / (RADIUS * 0.9))) * 0.18
        hx = (dx + dy) / (RADIUS * 2)  # -0.5..0.5, top-left negative
        if hx < 0:
            col = lerp_color(col, CREAM, min(0.25, -hx * 0.6 + highlight))
        pix[x, y] = (col[0], col[1], col[2], 255)

draw = ImageDraw.Draw(img)

# Leaf shape: lens polygon along a 40-degree axis through center
ANG = math.radians(40)
cos_a, sin_a = math.cos(ANG), math.sin(ANG)
px, py = -sin_a, cos_a  # perpendicular unit
LEAF_LEN = 132.0
HALF_W = 34.0
N = 120
left = []
right = []
for i in range(N + 1):
    t = i / N
    midx = CENTER + (t - 0.5) * LEAF_LEN * cos_a
    midy = CENTER + (t - 0.5) * LEAF_LEN * sin_a
    hw = (HALF_W) * math.sin(math.pi * t)
    left.append((midx + hw * px, midy + hw * py))
    right.append((midx - hw * px, midy - hw * py))
leaf = left + right[::-1]
draw.polygon(leaf, fill=WHITE + (235,))

# Leaf vein: centerline through the leaf, slightly tapered look via 2 widths
tip1 = (CENTER - (LEAF_LEN / 2) * cos_a, CENTER - (LEAF_LEN / 2) * sin_a)
tip2 = (CENTER + (LEAF_LEN / 2) * cos_a, CENTER + (LEAF_LEN / 2) * sin_a)
draw.line([tip1, tip2], fill=VEIN + (150,), width=3)

# Tiny stem at the bottom tip
stem_end = (tip1[0] - 6 * cos_a, tip1[1] - 6 * sin_a)
draw.line([tip1, stem_end], fill=WHITE + (235,), width=4)

img.save("icon.png")
print("icon.png written:", img.size)
