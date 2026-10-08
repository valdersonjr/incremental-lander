"""Planetinhas do Mapa das estrelas (Fase 18.5, 2026-10-07). Skill pixel-art, estilo fofo (cute-scene-method):
esfera com volume (luz de cima-esquerda), tema do mundo por cima, rostinho dormindo/sorrindo, contorno ink.
Contrato com o jogo (game/worlds/world_map.gd): assets/ui/map_planets.png — células CELLxCELL numa linha, na ordem
de map_planets.json "names" = <mundo>_open, <mundo>_locked, <mundo>_done para cada mundo. Mostrado em 1x
(48 px de planeta, a mesma escala de pixel do resto da UI). Bloqueado = mesmo desenho em cinzas da paleta;
completo = anel dourado + bandeirinha.
Rodar da raiz: python3 art/src/ui/map_planets.py [--export]
"""
import json
import math
import random
import sys

sys.path.insert(0, ".claude/skills/pixel-art/scripts")
sys.path.insert(0, "art/src/bg")
from pixelart import *
import moon_cute as mc

CELL = 60
R = 22
C = (30, 33)
WORLDS = ["luna", "nuvens", "cogumelos", "sorvete", "jardim", "bolhas"]
BASE = {
    "luna": ["lemon", "gold", "honey", "amber"],
    "nuvens": ["white", "pale_sky", "sky", "blue"],
    "cogumelos": ["lavender", "violet", "purple", "indigo"],
    "sorvete": ["white", "pink", "hot_pink", "raspberry"],
    "jardim": ["sprout", "leaf", "emerald", "green"],
    "bolhas": ["pale_sky", "sea", "teal", "deep_teal"],
}
GREY = {"white": "mist", "lemon": "mist", "lavender": "mist", "sprout": "mist", "pale_sky": "mist", "cream": "mist",
        "peach": "steel", "pink": "steel", "gold": "steel", "pale_sky2": "steel"}


def inside(x, y, r=R):
    return (x + 0.5 - C[0]) ** 2 + (y + 0.5 - C[1]) ** 2 <= r * r


def planet(world: str) -> Canvas:
    k = Canvas(CELL, CELL)
    mc.sphere(k, C[0], C[1], R, R, BASE[world])
    rng = random.Random(WORLDS.index(world) + 3)
    clip = lambda x, y: inside(x, y)
    if world == "luna":                                         # furinhos de queijo
        for cx, cy, r in ((19, 22, 4), (38, 20, 3), (42, 38, 4.5), (24, 44, 3), (33, 30, 2)):
            mc.sphere(k, cx, cy, r, r * 0.8, ["amber", "amber", "copper", "honey"], clip)
    elif world == "nuvens":                                     # faixa de nuvens fofas
        for cx, cy in ((14, 40), (22, 43), (31, 42), (40, 41), (47, 38), (20, 20), (28, 18)):
            mc.sphere(k, cx, cy, 6, 4.5, ["white", "white", "white", "lavender"], clip)
    elif world == "cogumelos":                                  # chapéus de cogumelo na superfície
        for cx, cy, r in ((16, 26, 6), (40, 22, 7), (30, 47, 6), (46, 40, 4)):
            mc.sphere(k, cx, cy, r, r * 0.7, ["salmon", "red", "red", "crimson"], clip)
            mc.disc(k, cx - r * 0.3, cy - r * 0.2, 1.2, "white")
    elif world == "sorvete":                                    # cobertura escorrendo + granulado
        for x in range(CELL):
            edge = 24 + int(3 * math.sin(x * 0.7) + (4 if x % 9 < 3 else 0))
            for y in range(0, edge):
                if inside(x, y):
                    k.px(x, y, "white" if y < 14 else "cream")
        for _ in range(16):
            x, y = rng.randrange(10, 50), rng.randrange(28, 54)
            if inside(x, y, R - 2):
                k.px(x, y, rng.choice(["lemon", "sprout", "pale_sky", "white"]))
    elif world == "jardim":                                     # florzinhas
        for cx, cy, col in ((18, 24, "pink"), (38, 20, "white"), (28, 40, "lemon"), (45, 36, "pink"), (16, 41, "violet")):
            for a in range(5):
                ang = a * math.tau / 5
                mc.disc(k, cx + math.cos(ang) * 2.2, cy + math.sin(ang) * 2.2, 1.6, col)
            k.px(cx, cy, "gold")
    elif world == "bolhas":                                     # ilhas e bolhas
        for cx, cy, w in ((20, 24, 7), (40, 40, 6)):
            mc.sphere(k, cx, cy, w, w * 0.6, ["lemon", "honey", "gold", "amber"], clip)
            mc.sphere(k, cx - 1, cy - 2, w * 0.6, w * 0.35, ["sprout", "leaf", "emerald", "green"], clip)
        for cx, cy, r in ((34, 20, 2.5), (14, 40, 2), (26, 50, 1.6)):
            for y in range(int(cy - r) - 1, int(cy + r) + 2):
                for x in range(int(cx - r) - 1, int(cx + r) + 2):
                    if r - 1 <= math.hypot(x + 0.5 - cx, y + 0.5 - cy) <= r:
                        k.px(x, y, "white")
    # rostinho fofo (sorriso e bochechas)
    ex, ey = C[0], C[1] + 2
    for sx in (-7, 4):
        k.rect(ex + sx, ey, 2, 3, "ink"); k.px(ex + sx, ey, "white")
    k.px(ex - 9, ey + 4, "pink"); k.px(ex - 10, ey + 4, "pink"); k.px(ex + 7, ey + 4, "pink"); k.px(ex + 8, ey + 4, "pink")
    k.px(ex - 2, ey + 5, "ink"); k.px(ex - 1, ey + 6, "ink"); k.px(ex, ey + 6, "ink"); k.px(ex + 1, ey + 5, "ink")
    k.outline("ink")
    return k


def locked(k: Canvas) -> Canvas:
    """Mesmo desenho em cinzas da paleta (por brilho)."""
    o = Canvas(k.w, k.h)
    greys = ["shadow", "slate", "lilac_grey", "steel", "mist", "white"]
    for (x, y) in k.opaque():
        c = k.get(x, y)
        r, g, b = PALETTE_RGB[resolve(c)]
        lum = (0.3 * r + 0.59 * g + 0.11 * b) / 255
        o.px(x, y, "ink" if resolve(c) == resolve("ink") else greys[min(5, int(lum * 6.4))])
    return o


def done(k: Canvas) -> Canvas:
    o = Canvas(k.w, k.h)
    for y in range(CELL):                                       # anel dourado
        for x in range(CELL):
            d = math.hypot(x + 0.5 - C[0], y + 0.5 - C[1])
            if R + 2 <= d < R + 4:
                o.px(x, y, "lemon" if (x + y) % 3 == 0 else "gold")
            elif R + 4 <= d < R + 5:
                o.px(x, y, "amber")
    o.stamp(k)
    fx = C[0] + 14                                              # bandeirinha fincada no alto
    o.vline(fx, 2, 15, "ink"); o.vline(fx + 1, 2, 14, "lilac_grey")
    for x in range(fx + 2, fx + 11):
        dy = int(round(math.sin(x * 0.9)))
        for y in range(3, 9):
            o.px(x, y + dy, "red" if y < 7 else "crimson")
    o.px(fx + 5, 5 + int(round(math.sin((fx + 5) * 0.9))), "white")
    return o


def build() -> tuple:
    names, cells = [], []
    for w in WORLDS:
        p = planet(w)
        for tag, c in (("open", p), ("locked", locked(p)), ("done", done(p))):
            names.append(f"{w}_{tag}")
            cells.append(c)
    cv = Canvas(CELL * len(cells), CELL)
    for i, c in enumerate(cells):
        cv.stamp(c, i * CELL, 0)
    return cv, names


if __name__ == "__main__":
    cv, names = build()
    if "--export" in sys.argv:
        cv.save("assets/ui/map_planets.png", preview=False)
        with open("assets/ui/map_planets.json", "w") as f:
            json.dump({"notes": "Gerado por art/src/ui/map_planets.py (pixel-art).", "cell": CELL,
                       "center": list(C), "radius": R, "names": names}, f, indent=1)
        print("exportado")
    else:
        cv.preview("art/previews/map_planets_preview.png", scale=3, grid=False, bg="dark", show_1x=True)
        print("ok")

# caminho literal do asset (pre-commit): assets/ui/map_planets.png
