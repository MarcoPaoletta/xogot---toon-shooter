#!/usr/bin/env python3
"""Builds the concept comparison images of GDD section 1.5 and checks the value table of 1.6.

Usage:
    python3 tools/compare.py <game_screenshot.png> "<build step>" [--out docs/evidence/comparison-final.png] [--values]

Without --out the next free docs/evidence/comparison-NN.png is used; an existing file is never overwritten.
With --values the colour table of section 1.6 is sampled from the game screenshot at the concept's
positions (scaled to the screenshot size) and printed with the per channel deltas.
"""
import datetime, os, sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, ".."))
CONCEPT = os.path.join(ROOT, "docs", "concept", "concept.png")
EVIDENCE = os.path.join(ROOT, "docs", "evidence")

# (name, target hex, x, y in the 1600 x 893 concept, tolerance fraction)
VALUES = [
    ("Sky top", "#d3e8fa", 800, 20, 0.12),
    ("Sky at the horizon", "#f6efe3", 1150, 100, 0.12),
    ("Ground, sunlit", "#f8ad6a", 1180, 640, 0.12),
    ("Ground, in shadow", "#8a6a55", 800, 820, 0.12),
    ("Ground, deep shadow", "#654a3c", 1420, 830, 0.18),
    ("Red container, lit end face", "#e8654a", 800, 420, 0.18),
    ("Red container, top", "#963533", 700, 375, 0.18),
    ("Blue container, front", "#2d5284", 330, 250, 0.18),
    ("Blue container, lit end", "#9aa4be", 580, 250, 0.18),
    ("Yellow container", "#a9762c", 1450, 120, 0.18),
    ("Sandbags", "#ac886a", 700, 300, 0.18),
    ("Tree canopy, lit", "#b4b542", 1200, 230, 0.18),
    ("Water tower body", "#998689", 1000, 130, 0.18),
    ("Tank hull", "#c98a2a", 1130, 520, 0.18),
    ("Soldier helmet", "#4f663d", 560, 500, 0.18),
    ("Bandit hood", "#85171e", 930, 470, 0.18),
]


def font(size):
    for p in ("/System/Library/Fonts/Supplemental/Arial.ttf", "/System/Library/Fonts/Helvetica.ttc"):
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def next_path():
    os.makedirs(EVIDENCE, exist_ok=True)
    n = 1
    while os.path.exists(os.path.join(EVIDENCE, "comparison-%02d.png" % n)):
        n += 1
    return os.path.join(EVIDENCE, "comparison-%02d.png" % n)


def fit(img, w, h):
    img = img.convert("RGB")
    s = min(w / img.width, h / img.height)
    return img.resize((max(1, int(img.width * s)), max(1, int(img.height * s))), Image.LANCZOS)


def sample(img, x, y, r=6):
    box = (max(0, x - r), max(0, y - r), min(img.width, x + r), min(img.height, y + r))
    return img.crop(box).resize((1, 1), Image.BOX).getpixel((0, 0))[:3]


def values(game):
    game = game.convert("RGB")
    concept = Image.open(CONCEPT).convert("RGB")
    sx, sy = game.width / concept.width, game.height / concept.height
    ok = True
    print("%-30s %-8s %-8s %-8s %s" % ("What", "target", "concept", "game", "max delta"))
    for name, hexv, x, y, tol in VALUES:
        t = tuple(int(hexv[i:i + 2], 16) for i in (1, 3, 5))
        c = sample(concept, x, y)
        g = sample(game, int(x * sx), int(y * sy))
        d = max(abs(a - b) for a, b in zip(g, t)) / 255.0
        passed = d <= tol
        ok = ok and passed
        print("%-30s %s  #%02x%02x%02x  #%02x%02x%02x  %4.0f%% %s" % (name, hexv, *c, *g, d * 100, "ok" if passed else "OVER (%d%%)" % int(tol * 100)))
    print("VALUES PASS" if ok else "VALUES FAIL")
    return ok


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if len(args) < 2:
        print(__doc__)
        sys.exit(2)
    shot, step = args[0], args[1]
    out = None
    if "--out" in sys.argv:
        out = os.path.join(ROOT, sys.argv[sys.argv.index("--out") + 1])
    if out is None:
        out = next_path()
    elif os.path.exists(out):
        print("refusing to overwrite", out)
        sys.exit(1)
    canvas = Image.new("RGB", (1920, 1080), (24, 24, 28))
    left = fit(Image.open(CONCEPT), 960, 540)
    game = Image.open(shot)
    right = fit(game, 960, 540)
    top = (1080 - 60 - 540) // 2
    canvas.paste(left, ((960 - left.width) // 2, top + (540 - left.height) // 2))
    canvas.paste(right, (960 + (960 - right.width) // 2, top + (540 - right.height) // 2))
    d = ImageDraw.Draw(canvas)
    f = font(28)
    d.text((24, top - 44), "concept.png", fill=(230, 230, 230), font=f)
    d.text((984, top - 44), "game, ConceptCam", fill=(230, 230, 230), font=f)
    d.rectangle((0, 1020, 1920, 1080), fill=(12, 12, 14))
    d.text((24, 1034), "%s  |  %s  |  %s" % (os.path.basename(out), step, datetime.date.today().isoformat()), fill=(240, 240, 240), font=f)
    canvas.save(out)
    print("wrote", os.path.relpath(out, ROOT))
    if "--values" in sys.argv:
        values(game)


if __name__ == "__main__":
    main()
