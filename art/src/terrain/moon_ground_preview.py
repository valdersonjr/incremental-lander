"""Prévia do terreno v2 na cena da Lua (recompõe como o Godot fará). Rodar da raiz."""
import random
import sys
sys.path.insert(0, ".claude/skills/pixel-art/scripts"); sys.path.insert(0, "art/src/terrain"); sys.path.insert(0, "art/src/bg")
from pixelart import *
import moon_scene as ms
import moon_ground as mg
from moon import profile, ridge_y

L = ms.load_layers()
V = sys.argv[1] if len(sys.argv) > 1 else "A"
G = mg.VARIANTS[V]()
cv = Canvas(ms.W, ms.H)
cv.stamp(L["sky"]); cv.stamp(L["planet"], ms.PLANET[0] - ms.PLANET[2] - 12, ms.PLANET[1] - ms.PLANET[2] - 12)
cv.stamp(L["far"]); cv.stamp(L["mid"]); cv.stamp(L["plain"], 0, ms.PLAIN_TOP)
pad = (300, 64)
pts = profile(ms.W, seed=7, base=292, amp=60, pad=pad)
faces = ms.segment_faces(pts)
def face_at(x):
    return faces[min(sum(1 for p in pts[1:] if p[0] <= x), len(faces) - 1)]
mg.compose(cv, lambda x: ridge_y(pts, x), 0, ms.W, face_at, G)
rng = random.Random(31); cw, ch = ms.ROCK_CELL
for _ in range(26):
    x = rng.randrange(8, ms.W - 8)
    if pad[0] - 12 < x < pad[0] + pad[1] + 12:
        continue
    i = rng.randrange(len(ms.ROCK_SIZES))
    cv.stamp(L["rocks"].crop(i * cw, 0, cw, ch), x - cw // 2, ridge_y(pts, x) + rng.randint(0, 2) - 6)
pd = Canvas.from_image("assets/sprites/landing_pad.png").crop(0, 0, 80, 28)
lander = Canvas.from_image("assets/sprites/lander.png").crop(0, 0, 32, 32)
cv.stamp(lander, pad[0] + pad[1] // 2 - 16, ridge_y(pts, pad[0] + pad[1] // 2) - 25)
cv.save(f"art/previews/moon_ground_{V}.png", preview=False)
cv.preview(f"art/previews/moon_ground_{V}_2x.png", scale=2, grid=False, show_1x=False)
from PIL import Image
im = Image.open(f"art/previews/moon_ground_{V}.png").crop((0, 240, 400, 360))
im.resize((1200, 360), Image.NEAREST).save(f"art/previews/moon_ground_{V}_zoom.png")
