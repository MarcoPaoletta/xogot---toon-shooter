#!/usr/bin/env python3
"""test_menu (GDD 6): the main menu is never a static image. Runs the project's main scene in Xogot, takes two
game screenshots 3 s apart and requires a mean absolute pixel difference above 2 (0 to 255 scale).

Usage: python3 tools/check_menu.py [xo instance name]
"""
import os, subprocess, sys, tempfile, time
from PIL import Image, ImageChops, ImageStat

XO = "/Applications/Xogot.app/Contents/MacOS/xo"
app = ["--app", sys.argv[1]] if len(sys.argv) > 1 else []


def xo(*a):
    return subprocess.run([XO, *a, *app], capture_output=True, text=True)


tmp = tempfile.mkdtemp()
xo("project", "stop")
time.sleep(1)
xo("project", "run")
time.sleep(5)
a, b = os.path.join(tmp, "a.png"), os.path.join(tmp, "b.png")
xo("editor", "screenshot", "--source", "game", "--max-resolution", "960", a)
time.sleep(3)
xo("editor", "screenshot", "--source", "game", "--max-resolution", "960", b)
xo("project", "stop")
diff = sum(ImageStat.Stat(ImageChops.difference(Image.open(a).convert("RGB"), Image.open(b).convert("RGB"))).mean) / 3
ok = diff > 2.0
print("%s test_menu_moves (mean absolute difference over 3 s: %.2f)" % ("PASS" if ok else "FAIL", diff))
sys.exit(0 if ok else 1)
