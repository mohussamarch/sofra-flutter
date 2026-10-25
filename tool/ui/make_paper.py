"""Generates the recipe book's aged page: assets/ui/paper-page.webp.

Deterministic (fixed seed), so re-running gives the same file. Layers:
mottled sepia base, grain, fibres, foxing spots, a coffee ring, a water
tide-line, burnt uneven edges and a torn (deckled) outline in alpha.

Run with any Python that has numpy and Pillow:
    python tool/ui/make_paper.py
"""

from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

W, H = 1080, 1700
rng = np.random.default_rng(1957)
OUT = Path(__file__).resolve().parents[2] / "assets" / "ui" / "paper-page.webp"


def noise(scale, octaves=4):
    """Smooth value noise in [0, 1] by upsampling random grids."""
    acc = np.zeros((H, W), np.float32)
    amp, total = 1.0, 0.0
    for o in range(octaves):
        cells = max(2, int(scale * 2**o))
        grid = rng.random((cells, int(cells * W / H) + 2)).astype(np.float32)
        img = Image.fromarray((grid * 255).astype(np.uint8)).resize(
            (W, H), Image.BICUBIC
        )
        acc += amp * np.asarray(img, np.float32) / 255
        total += amp
        amp *= 0.5
    return acc / total


base = np.array([233, 216, 178], np.float32)  # warm aged paper
mottle = noise(4, 5) - 0.5
grain = rng.normal(0, 1, (H, W)).astype(np.float32)
rgb = base[None, None, :] + mottle[..., None] * np.array([46, 44, 40]) + grain[
    ..., None
] * 4.5

# Darkening towards the edges, uneven, like handled old pages.
yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
edge = np.minimum.reduce([xx, W - 1 - xx, yy, H - 1 - yy])
ragged = noise(10, 3) * 70
burn = np.clip(1 - (edge - ragged * 0.4) / (110 + ragged), 0, 1) ** 1.6
rgb -= burn[..., None] * np.array([95, 110, 120])

img = Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8), "RGB")
stain = Image.new("L", (W, H), 0)
d = ImageDraw.Draw(stain)

# Fibres.
for _ in range(1400):
    x, y = rng.random() * W, rng.random() * H
    a = rng.random() * np.pi
    length = 6 + rng.random() * 22
    d.line(
        [x, y, x + np.cos(a) * length, y + np.sin(a) * length],
        fill=int(18 + rng.random() * 22),
        width=1,
    )
# Foxing: small brown spots.
for _ in range(90):
    x, y = rng.random() * W, rng.random() * H
    r = 1 + rng.random() * 5
    d.ellipse([x - r, y - r, x + r, y + r], fill=int(40 + rng.random() * 60))
stain = stain.filter(ImageFilter.GaussianBlur(0.8))

# Larger soft age blotches.
blot = Image.new("L", (W, H), 0)
bd = ImageDraw.Draw(blot)
for _ in range(14):
    x, y = rng.random() * W, rng.random() * H
    r = 30 + rng.random() * 90
    bd.ellipse([x - r, y - r, x + r, y + r], fill=int(25 + rng.random() * 30))
blot = blot.filter(ImageFilter.GaussianBlur(40))

# A coffee ring low on the page and a water tide-line near the top.
ring = Image.new("L", (W, H), 0)
rd = ImageDraw.Draw(ring)


def wobbly(cx, cy, r, start, end, jitter):
    """Points round a circle whose radius drifts, like a dried liquid edge."""
    drift = np.cumsum(rng.normal(0, jitter, 240))
    drift -= np.linspace(0, drift[-1], 240)
    t = np.linspace(start, end, 240)
    return [(cx + (r + k) * np.cos(a), cy + (r + k) * np.sin(a)) for a, k in zip(t, drift)]


cx, cy = W * 0.24, H * 0.83
rd.line(wobbly(cx, cy, 120, 0.3, 2 * np.pi - 0.2, 1.4), fill=120, width=6)
rd.line(wobbly(cx + 4, cy - 2, 108, 0.9, 5.2, 1.0), fill=55, width=3)
ring = ring.filter(ImageFilter.GaussianBlur(2.4))
tide = Image.new("L", (W, H), 0)
td = ImageDraw.Draw(tide)
td.line(wobbly(W * 0.86, H * 0.05, 300, 1.7, 3.4, 2.5), fill=90, width=5)
tide = tide.filter(ImageFilter.GaussianBlur(3))

brown = Image.new("RGB", (W, H), (120, 82, 40))
for layer, strength in ((blot, 0.55), (stain, 0.6), (ring, 0.45), (tide, 0.35)):
    img = Image.composite(
        brown, img, layer.point(lambda v, s=strength: int(v * s))
    )

# Torn, deckled outline.
mask = Image.new("L", (W, H), 0)
md = ImageDraw.Draw(mask)
pts = []
inset = 10
for side in range(4):
    steps = 140
    for i in range(steps):
        t = i / steps
        j = inset + rng.random() * 9 + (rng.random() < 0.06) * rng.random() * 10
        if side == 0:
            pts.append((t * W, j))
        elif side == 1:
            pts.append((W - j, t * H))
        elif side == 2:
            pts.append((W - t * W, H - j))
        else:
            pts.append((j, H - t * H))
md.polygon(pts, fill=255)
mask = mask.filter(ImageFilter.GaussianBlur(1.2))

out = img.convert("RGBA")
out.putalpha(mask)
OUT.parent.mkdir(parents=True, exist_ok=True)
out.save(OUT, "WEBP", quality=82, method=6)
print(OUT, OUT.stat().st_size)
