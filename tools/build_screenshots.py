"""Build the app's guide screenshots from recorded frames.

For each (app, step) in tools/screenshot_selection.py: blur personal data (strong blur +
pixelation, irreversible), resize to 720 px wide and save as
assets/workflows/<app>/<app>_<step>.jpg. Highlights are NOT drawn here; the app draws
them as a separate layer.

Run from saathi_poc/:  python tools/build_screenshots.py [--preview DIR]
"""

import argparse
import os
import sys

from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(__file__))
from screenshot_selection import SELECTION  # noqa: E402

WIDTH = 720


def redact(im: Image.Image, rects) -> Image.Image:
    w, h = im.size
    for (l, t, rw, rh) in rects:
        box = (int(l * w), int(t * h), int((l + rw) * w), int((t + rh) * h))
        region = im.crop(box)
        # Pixelate then blur: nothing legible survives.
        small = region.resize((max(1, region.width // 24), max(1, region.height // 24)))
        region = small.resize(region.size, Image.NEAREST).filter(ImageFilter.GaussianBlur(8))
        im.paste(region, box)
    return im


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--preview", help="also write copies with blur boxes outlined here")
    args = parser.parse_args()

    for (app, step), (src, rects) in sorted(SELECTION.items()):
        im = Image.open(src).convert("RGB")
        im = redact(im, rects)
        h = round(im.height * WIDTH / im.width)
        im = im.resize((WIDTH, h), Image.LANCZOS)
        out_dir = os.path.join("assets", "workflows", app)
        os.makedirs(out_dir, exist_ok=True)
        out = os.path.join(out_dir, f"{app}_{step}.jpg")
        im.save(out, "JPEG", quality=78, optimize=True, progressive=True)
        if args.preview:
            os.makedirs(args.preview, exist_ok=True)
            p = im.copy()
            d = ImageDraw.Draw(p)
            for (l, t, rw, rh) in rects:
                d.rectangle([l * WIDTH, t * h, (l + rw) * WIDTH, (t + rh) * h], outline="red", width=3)
            p.save(os.path.join(args.preview, f"{app}_{step}.jpg"), quality=70)
        print(f"{out}  ({os.path.getsize(out) // 1024} KB, {len(rects)} blurred areas)")


if __name__ == "__main__":
    main()
