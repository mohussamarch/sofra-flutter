"""Render every brand bitmap in the app from the SVGs in tool/brand/svg.

The SVGs are the owner's chosen logo (concept «الرقعة على خط المائدة»),
already outlined, so no font is needed here. Rendering uses the Edge or
Chrome already on the machine (headless, transparent background) and
Pillow for downscaling, masks and compositing, so it needs no install.

    python tool/brand/render_brand.py            # from the repo root

Writes, and overwrites:
  android/app/src/main/res/mipmap-*/ic_launcher.png, ic_launcher_round.png
  android/app/src/main/res/mipmap-*/ic_launcher_foreground.png
  android/app/src/main/res/mipmap-*/ic_launcher_monochrome.png
  web/favicon.png, web/favicon-dark.png, web/icons/Icon-*.png
  assets/brand/[2.0x/|3.0x/]logo-{ar,en}[-dark].png

The XML (adaptive icon, background colour) is hand written and lives next
to the PNGs; this script only makes pixels.
"""
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile
import time

from PIL import Image, ImageDraw

REPO = pathlib.Path(__file__).resolve().parents[2]
SVG = REPO / 'tool' / 'brand' / 'svg'
RES = REPO / 'android' / 'app' / 'src' / 'main' / 'res'
WEB = REPO / 'web'
BRAND = REPO / 'assets' / 'brand'

BROWSERS = [
    r'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe',
    r'C:\Program Files\Microsoft\Edge\Application\msedge.exe',
    r'C:\Program Files\Google\Chrome\Application\chrome.exe',
    'msedge', 'google-chrome', 'chromium', 'chrome',
]

# Android densities: legacy icon is 48 dp, adaptive layers are 108 dp.
DENSITIES = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}

# In-app wordmark: logical height of the 1x bitmap. Shown at this height or
# smaller, so the 2x/3x bitmaps stay sharp on dense phones.
LOGO_H = 40

MASTER = 1536  # icon master edge in px (108 units); the 72 viewport is 1024


def browser():
    for b in BROWSERS:
        if os.path.isfile(b) or shutil.which(b):
            return b
    sys.exit('Edge or Chrome is needed to render the SVGs.')


def render(svg_name, w, h):
    """Rasterise one SVG at w x h px on a transparent background."""
    src = (SVG / svg_name).read_text(encoding='utf-8')
    src = src[src.index('<svg'):]
    # Stretch to the requested box; aspect ratios are kept by the caller.
    src = src.replace('<svg ', f'<svg width="{w}" height="{h}" preserveAspectRatio="xMidYMid meet" ', 1)
    tmp = pathlib.Path(tempfile.mkdtemp(prefix='brand_'))
    page = tmp / 'p.html'
    out = tmp / 'o.png'
    page.write_text(
        '<!doctype html><meta charset="utf-8"><style>html,body{margin:0;'
        'background:transparent;overflow:hidden}svg{display:block}</style>' + src,
        encoding='utf-8')
    prof = tmp / 'profile'
    cmd = [browser(), '--headless=new', '--disable-gpu', '--hide-scrollbars',
           '--force-device-scale-factor=1', '--force-color-profile=srgb',
           '--default-background-color=00000000', f'--user-data-dir={prof}',
           f'--window-size={w},{h}', f'--screenshot={out}', page.as_uri()]
    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=120)
    last, deadline = -1, time.time() + 60
    while time.time() < deadline:  # Edge on Windows writes from a child process
        size = out.stat().st_size if out.is_file() else -1
        if size > 0 and size == last:
            break
        last = size
        time.sleep(0.5)
    if not out.is_file():
        sys.exit(f'Render failed: {svg_name}')
    img = Image.open(out).convert('RGBA').crop((0, 0, w, h))
    img.load()
    shutil.rmtree(tmp, ignore_errors=True)
    return img


def viewbox(svg_name):
    m = re.search(r'viewBox="([^"]+)"', (SVG / svg_name).read_text(encoding='utf-8'))
    return [float(v) for v in m.group(1).split()][2:]


def shrink(img, w, h):
    """Downscale with premultiplied alpha so edges do not darken."""
    return img.convert('RGBa').resize((w, h), Image.LANCZOS).convert('RGBA')


def mask(size, shape):
    big = size * 4
    m = Image.new('L', (big, big), 0)
    d = ImageDraw.Draw(m)
    if shape == 'circle':
        d.ellipse((0, 0, big - 1, big - 1), fill=255)
    else:  # rounded square, the shape most launchers and browsers use
        d.rounded_rectangle((0, 0, big - 1, big - 1), radius=int(big * 0.22), fill=255)
    return m.resize((size, size), Image.LANCZOS)


def save(img, path):
    path = pathlib.Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, optimize=True)
    print(path.relative_to(REPO).as_posix(), f'{img.width}x{img.height}')


def main():
    layers = {}
    for theme, suffix in (('light', ''), ('dark', '-dark')):
        bg = render(f'icon-background{suffix}.svg', MASTER, MASTER)
        fg = render(f'icon-foreground{suffix}.svg', MASTER, MASTER)
        layers[theme] = (fg, Image.alpha_composite(bg, fg))
    mono = render('icon-mono.svg', MASTER, MASTER)
    fg, full = layers['light']
    cut = (MASTER - 1024) // 2
    viewport = full.crop((cut, cut, cut + 1024, cut + 1024))

    def shaped(px, shape, source=viewport):
        img = shrink(source, px, px)
        out = Image.new('RGBA', (px, px), (0, 0, 0, 0))
        out.paste(img, (0, 0), mask(px, shape))
        return out

    for name, scale in DENSITIES.items():
        d = RES / f'mipmap-{name}'
        legacy = round(48 * scale)
        layer = round(108 * scale)
        save(shaped(legacy, 'rounded'), d / 'ic_launcher.png')
        save(shaped(legacy, 'circle'), d / 'ic_launcher_round.png')
        save(shrink(fg, layer, layer), d / 'ic_launcher_foreground.png')
        save(shrink(mono, layer, layer), d / 'ic_launcher_monochrome.png')

    dark_view = layers['dark'][1].crop((cut, cut, cut + 1024, cut + 1024))
    save(shaped(32, 'rounded'), WEB / 'favicon.png')
    save(shaped(32, 'rounded', dark_view), WEB / 'favicon-dark.png')
    for px in (192, 512):
        save(shaped(px, 'rounded'), WEB / 'icons' / f'Icon-{px}.png')
        # Maskable: the whole 108 canvas; the mark sits inside the safe circle.
        save(shrink(full, px, px).convert('RGB'), WEB / 'icons' / f'Icon-maskable-{px}.png')

    # In-app wordmarks, 1x/2x/3x by height.
    for lang in ('ar', 'en'):
        vw, vh = viewbox(f'logo-{lang}.svg')
        for suffix in ('', '-dark'):
            mh = 600
            mw = round(mh * vw / vh)
            master = render(f'logo-{lang}{suffix}.svg', mw, mh)
            for ratio, sub in ((1, ''), (2, '2.0x/'), (3, '3.0x/')):
                # Width from the 1x width, so every scale has the same size.
                h = LOGO_H * ratio
                w = round(LOGO_H * vw / vh) * ratio
                save(shrink(master, w, h), BRAND / f'{sub}logo-{lang}{suffix}.png')


if __name__ == '__main__':
    main()
