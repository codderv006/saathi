"""Build the launcher icons and the in-app logo from assets/Saathi App Icon.png.

- Android adaptive icon (API 26+): cream background colour + the two figures as the
  foreground, sized to the 66 dp safe zone so no launcher mask clips them.
- Legacy icons (older Android): the same figures on a cream rounded square.
- assets/brand/saathi_logo.png: the figures on transparency, for the app header.

The "Saathi" wordmark is left out of the icons: it would be unreadable at launcher
size, and the launcher already shows the app name under the icon.

Run from saathi_poc/:  python tools/build_icons.py
"""

import os

from PIL import Image, ImageDraw

SRC = os.path.join("assets", "Saathi App Icon.png")
RES = os.path.join("android", "app", "src", "main", "res")
CREAM = (254, 251, 246)
# The two figures (with the phone), in source pixels: left, top, right, bottom.
FIGURES = (290, 205, 970, 850)
DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}


def keyed(im: Image.Image) -> Image.Image:
    """Cream background -> transparent, with soft edges and un-blended colours."""
    out = Image.new("RGBA", im.size)
    src = im.load()
    dst = out.load()
    for y in range(im.height):
        for x in range(im.width):
            p = src[x, y]
            d = max(abs(p[i] - CREAM[i]) for i in range(3))
            a = min(1.0, max(0.0, (d - 6) / 40))
            if a == 0:
                dst[x, y] = (0, 0, 0, 0)
                continue
            c = tuple(
                min(255, max(0, round((p[i] - (1 - a) * CREAM[i]) / a))) for i in range(3)
            )
            dst[x, y] = (*c, round(a * 255))
    return out


def fit(art: Image.Image, canvas: int, max_diameter: float) -> Image.Image:
    """Centre art on a transparent square canvas so its bounding box fits a circle."""
    w, h = art.size
    scale = max_diameter / (w * w + h * h) ** 0.5
    size = (round(w * scale), round(h * scale))
    out = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    out.paste(art.resize(size, Image.LANCZOS), ((canvas - size[0]) // 2, (canvas - size[1]) // 2))
    return out


def main() -> None:
    figures = keyed(Image.open(SRC).convert("RGB").crop(FIGURES))

    os.makedirs(os.path.join("assets", "brand"), exist_ok=True)
    logo = figures.resize((256, round(256 * figures.height / figures.width)), Image.LANCZOS)
    logo.save(os.path.join("assets", "brand", "saathi_logo.png"), optimize=True)

    for name, k in DENSITIES.items():
        folder = os.path.join(RES, f"mipmap-{name}")
        os.makedirs(folder, exist_ok=True)
        # Adaptive foreground: 108 dp canvas, art inside the 66 dp safe circle.
        fit(figures, round(108 * k), 80 * k).save(
            os.path.join(folder, "ic_launcher_foreground.png"), optimize=True
        )
        # Legacy: 48 dp cream rounded square.
        n = round(48 * k)
        big = n * 4  # draw large, then downsample for smooth corners
        legacy = Image.new("RGBA", (big, big), (0, 0, 0, 0))
        ImageDraw.Draw(legacy).rounded_rectangle(
            (0, 0, big - 1, big - 1), radius=big * 0.22, fill=(*CREAM, 255)
        )
        legacy.alpha_composite(fit(figures, big, big * 0.9))
        legacy.resize((n, n), Image.LANCZOS).save(
            os.path.join(folder, "ic_launcher.png"), optimize=True
        )

    anydpi = os.path.join(RES, "mipmap-anydpi-v26")
    os.makedirs(anydpi, exist_ok=True)
    with open(os.path.join(anydpi, "ic_launcher.xml"), "w", encoding="utf-8") as f:
        f.write(
            '<?xml version="1.0" encoding="utf-8"?>\n'
            '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
            '    <background android:drawable="@color/ic_launcher_background"/>\n'
            '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
            "</adaptive-icon>\n"
        )
    with open(os.path.join(RES, "values", "ic_launcher_background.xml"), "w", encoding="utf-8") as f:
        f.write(
            '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
            '    <color name="ic_launcher_background">#%02X%02X%02X</color>\n</resources>\n' % CREAM
        )
    print("icons and assets/brand/saathi_logo.png written")


if __name__ == "__main__":
    main()
