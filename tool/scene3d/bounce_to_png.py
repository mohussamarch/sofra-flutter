"""Turns a Codex bounce lightmap (Radiance .hdr, linear) into an 8-bit sRGB
PNG the app can load as a three.js lightMap through model-viewer.

The PNG holds value / scale; the app multiplies the scale back in through
lightMapIntensity. Prints the scale to stdout as JSON.

    python bounce_to_png.py in.hdr out.png --size 2048
"""

import argparse
import json

import numpy as np
from PIL import Image


def read_hdr(path):
    with open(path, 'rb') as f:
        data = f.read()
    end = data.index(b'\n\n') + 2
    line_end = data.index(b'\n', end)
    dims = data[end:line_end].split()
    h, w = int(dims[1]), int(dims[3])
    pos = line_end + 1
    out = np.empty((h, w, 4), np.uint8)
    buf = np.frombuffer(data, np.uint8)
    for y in range(h):
        # New-style run-length encoding: 2 2 hi lo, then 4 channel planes.
        if buf[pos] != 2 or buf[pos + 1] != 2:
            raise ValueError('flat or old-style RLE not supported')
        pos += 4
        for c in range(4):
            x = 0
            row = out[y, :, c]
            while x < w:
                n = int(buf[pos])
                pos += 1
                if n > 128:
                    n -= 128
                    row[x:x + n] = buf[pos]
                    pos += 1
                else:
                    row[x:x + n] = buf[pos:pos + n]
                    pos += n
                x += n
    e = out[..., 3].astype(np.int32)
    f = np.where(e > 0, np.ldexp(1.0, e - 136), 0.0)
    return out[..., :3].astype(np.float32) * f[..., None].astype(np.float32)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('src')
    ap.add_argument('dst')
    ap.add_argument('--size', type=int, default=2048)
    a = ap.parse_args()
    rgb = read_hdr(a.src)
    k = rgb.shape[0] // a.size
    if k > 1:
        rgb = rgb[: a.size * k, : a.size * k].reshape(a.size, k, a.size, k, 3).mean((1, 3))
    scale = float(np.percentile(rgb, 99.7)) or 1.0
    v = np.clip(rgb / scale, 0, 1)
    srgb = np.where(v <= .0031308, v * 12.92, 1.055 * np.power(v, 1 / 2.4) - .055)
    Image.fromarray((srgb * 255 + .5).astype(np.uint8)).save(a.dst, optimize=True)
    print(json.dumps({'scale': scale}))


if __name__ == '__main__':
    main()
