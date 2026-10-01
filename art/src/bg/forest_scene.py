"""Mundo 2 — FLORESTA FECHADA (id `ares` no código). Padrão: patterns/forest-scene.md.

Regra do usuário: cada planeta é um mundo totalmente diferente; mesmo ESTILO da Lua aprovada (rico em camadas,
luz de cima-esquerda, perspectiva atmosférica, Resurrect 64), formas próprias da floresta.
Camadas (mesmo contrato do jogo, assets/bg/ares_layers.json):
  sky    copa escura pendurada no topo + cipós, luz dourada filtrando, raios de luz
  planet sol baixo dourado (atrás das árvores)
  far    pinheiros em silhueta na névoa
  mid    árvores gigantes (tronco, raízes, copa em aglomerados de folhas, cipós), névoa na base
  plain  sub-bosque escuro com moitas e vaga-lumes
  ground faixas lit/flat/shade: grama no topo, terra escura com raízes e pedrinhas
  props  atlas 8 x 16x16 (base na linha 14): grama, capim, samambaia, cogumelos, flores, moita
Rodar da raiz: python3 art/src/bg/forest_scene.py [--export]
"""
import json
import math
import random
import sys

sys.path.insert(0, ".claude/skills/pixel-art/scripts")
sys.path.insert(0, "art/src/terrain")
sys.path.insert(0, "art/src/bg")
sys.path.insert(0, "art/src/fx")
from pixelart import *
from moon import profile, ridge_y
import moon_scene as ms
from moon_scene import mix, pnoise, W, H, HORIZON, STRIP_W, STRIP_D, FACE_SLOPE
from explosion import blob, shade_blob
import planet_scenes as ps

P = {"sky": "assets/bg/ares_sky.png", "planet": "assets/bg/ares_planet.png", "far": "assets/bg/ares_far.png",
     "mid": "assets/bg/ares_mid.png", "plain": "assets/bg/ares_plain.png",
     "lit": "assets/tiles/ares_ground_lit.png", "flat": "assets/tiles/ares_ground_flat.png",
     "shade": "assets/tiles/ares_ground_shade.png", "props": "assets/sprites/ares_rocks.png",
     "meta": "assets/bg/ares_layers.json"}
PROP_CELL = (16, 16)
PROP_BASE = 14
PROP_SPACING = (6, 22)            # floresta: enfeites bem mais densos que as pedras da Lua
SUN = (452, 214, 20)
INV = {}


def pxw(cv: Canvas, x: int, y: int, c) -> None:
    """Pinta com laço horizontal (camadas de parallax repetem em W)."""
    cv.px(x % cv.w, y, c)


# ------------------------------------------------------------------ céu: copa fechada + luz filtrando
def sky(cv: Canvas) -> None:
    bands = [(0, "ink"), (46, "deep_sage"), (110, "sage"), (168, "lichen"), (214, "bone"), (252, "cream")]
    for y in range(H):
        for x in range(W):
            c = bands[0][1]
            for (y0, c0), (y1, c1) in zip(bands, bands[1:]):
                if y < y0:
                    break
                c = c0
                tw = min(22, (y1 - y0) // 2)
                if y1 - tw <= y < y1:
                    c = mix(c0, c1, (y - (y1 - tw)) / tw, x, y)
                elif y >= y1:
                    c = c1
            cv.px(x, y, c)
    # raios de luz diagonais (dither claro sobre o céu), mais fortes perto da copa, somem embaixo
    for x0, wdt, strength in ((40, 26, 0.5), (170, 14, 0.35), (300, 34, 0.45), (470, 18, 0.4), (560, 22, 0.3)):
        for y in range(30, 250):
            cx = x0 + (y - 30) * 0.42
            f = (1 - (y - 30) / 220) * strength
            for dx in range(-wdt // 2, wdt // 2 + 1):
                edge = 1 - abs(dx) / (wdt / 2 + 0.5)
                lvl = f * edge
                x = int(cx + dx) % W
                base = INV.get(cv.get(x, y))
                light = "cream" if base in ("bone", "cream") else "bone" if base in ("lichen",) else "lichen"
                if lvl > 0.08:
                    cv.px(x, y, mix(base, light, lvl, x, y))
    # copa pendurada no topo: massa escura com borda de bolhas de folhas, aro claro embaixo (contraluz)
    rng = random.Random(5)
    for x in range(W):
        edge = 16 + 10 * pnoise(x, 9, W, (2, 5, 11), (1, .6, .35))
        for y in range(0, int(edge)):
            cv.px(x, y, "ink" if y < edge - 6 else mix("ink", "deep_sage", (y - edge + 6) / 6, x, y))
    for _ in range(70):
        bx, by, br = rng.randrange(W), 12 + rng.randint(0, 22), rng.uniform(3, 8)
        pts = blob(bx, by, br, rng.randrange(999), 0.3)
        for (x, y) in pts:
            below = (x, y + 1) not in pts
            pxw(cv, x, y, "pine" if below and rng.random() < 0.7 else "deep_sage" if y > by else "ink")
    for _ in range(26):                                       # cipós pendurados com folhinhas
        vx, length = rng.randrange(W), rng.randint(18, 80)
        x = vx
        for k in range(length):
            y = 18 + k
            x += 1 if pnoise(k * 7 + vx, 13, 997) > 0.55 else -1 if pnoise(k * 7 + vx, 14, 997) > 0.55 else 0
            pxw(cv, x, y, "deep_sage")
            if k % 5 == 2:
                pxw(cv, x + (1 if k % 10 == 2 else -1), y, "green" if k < length - 6 else "pine")


def sun(cv: Canvas) -> tuple:
    cx, cy, r = SUN
    for y in range(cy - r - 18, cy + r + 19):
        for x in range(cx - r - 18, cx + r + 19):
            d = math.hypot(x - cx, y - cy)
            if r < d <= r + 18 and cv.inside(x, y):
                lvl = (1 - (d - r) / 18) ** 1.2
                if lvl > 0.1:
                    cv.px(x, y, mix(INV.get(cv.get(x, y), "clear"), "lemon" if lvl > 0.6 else "cream", lvl * 0.9, x, y))
    for y in range(cy - r, cy + r + 1):
        for x in range(cx - r, cx + r + 1):
            d = math.hypot(x - cx, y - cy) / r
            if d <= 1:
                cv.px(x, y, "white" if d < 0.55 else "lemon" if d < 0.85 else "gold")
    return (cx - r - 19, cy - r - 19, 2 * r + 39, 2 * r + 39)


# ------------------------------------------------------------------ árvores
def conifer(cv: Canvas, x0: int, base: int, h: int, w: int, cols: dict, haze=None, seed: int = 0) -> None:
    """Pinheiro em camadas (níveis de galhos serrilhados), lado esquerdo iluminado."""
    rng = random.Random(seed)
    top = base - h
    tier = max(6, h // 7)
    for y in range(top, base + 1):
        t = (y - top) / h
        k = ((y - top) % tier) / tier                         # serrilhado: cada nível começa estreito
        hw = (w / 2) * t * (0.55 + 0.45 * k) + rng.choice([0, 0, 0.5])
        for dx in range(-int(hw), int(hw) + 1):
            side = dx / max(hw, 1)
            c = cols["lit"] if side < -0.35 else cols["mid"] if side < 0.15 else cols["dark"]
            if dx == -int(hw) and k > 0.5:
                c = cols["rim"]
            if haze and y > base - 26:
                c = mix(c, haze, (y - (base - 26)) / 26, x0 + dx, y)
            pxw(cv, x0 + dx, y, c)
    for y in range(base - 4, base + 1):                       # tronquinho
        pxw(cv, x0, y, cols["dark"])


def big_tree(cv: Canvas, x0: int, base: int, h: int, tw: int, crown_r: int, seed: int, haze: str) -> None:
    rng = random.Random(seed)
    crown_y = base - h
    # tronco com casca (estrias verticais), luz à esquerda, raízes abrindo na base
    for y in range(crown_y + crown_r // 2, base + 1):
        flare = max(0, (y - (base - 14))) * 0.9
        a, b = int(x0 - tw / 2 - flare), int(x0 + tw / 2 + flare)
        for x in range(a, b + 1):
            t = (x - a) / max(b - a, 1)
            c = "olive" if t < 0.28 else "umber" if t < 0.8 else "charcoal"
            if (x * 7 + y // 3) % 9 == 0 and 0.15 < t < 0.85:
                c = "charcoal" if t > 0.4 else "umber"           # sulcos da casca
            if y > base - 18:
                c = mix(c, haze, (y - (base - 18)) / 18, x, y)
            pxw(cv, x, y, c)
    for side in (-1, 1):                                      # galhos saindo para a copa
        for k in range(crown_r):
            x = x0 + side * (tw // 2 + k)
            y = crown_y + crown_r // 2 + 6 - int(k * 0.7)
            pxw(cv, x, y, "umber"); pxw(cv, x, y + 1, "charcoal")
    # copa: vários blobs sombreados (dir) + aglomerados de folhas consistentes
    blobs = [(x0 + rng.randint(-crown_r, crown_r), crown_y + rng.randint(-crown_r // 2, crown_r // 2),
              crown_r * rng.uniform(0.5, 0.85)) for _ in range(7)]
    blobs.append((x0, crown_y, crown_r * 0.9))
    allpts = set()
    for i, (bx, by, br) in enumerate(sorted(blobs, key=lambda b: b[1])):
        pts = blob(bx, by, br, seed * 31 + i, 0.25)
        allpts |= pts
        tmp = Canvas(W * 3, H)
        shade_blob(tmp, {(x + W, y) for x, y in pts if 0 <= y < H}, bx + W, by, br,
                   ["emerald", "green", "green", "pine", "deep_sage"], mode="dir")
        for (x, y) in pts:
            if 0 <= y < H:
                c = tmp.get(x + W, y)
                if c is not None:
                    pxw(cv, x, y, INV[c])
    # aglomerados de folhas: tufos de 3 px (mais claros no lado da luz, escuros na sombra)
    for _ in range(int(len(allpts) / 18)):
        x, y = rng.choice(sorted(allpts))
        lit = (x - x0) * 0.6 + (y - crown_y) * 0.8 < 0
        c = "leaf" if lit else "deep_sage"
        for dx, dy in ((0, 0), (1, 0), (0, 1)) if lit else ((0, 0), (-1, 0), (0, -1)):
            if (x + dx, y + dy) in allpts:
                pxw(cv, x + dx, y + dy, c)
        if lit and rng.random() < 0.3:
            pxw(cv, x, y - 1, "sprout")
    # cipós descendo da copa
    for _ in range(3):
        vx = x0 + rng.randint(-crown_r, crown_r)
        vy = crown_y + crown_r // 2
        for k in range(rng.randint(15, 50)):
            pxw(cv, vx, vy + k, "pine" if k % 6 else "green")


def far_layer() -> Canvas:
    cv = Canvas(W, HORIZON + 1)
    rng = random.Random(23)
    trees = [(rng.randrange(W), rng.randint(70, 150), rng.randrange(9999)) for _ in range(34)]
    for x, h, s in sorted(trees, key=lambda t: -t[1]):
        conifer(cv, x, HORIZON, h, int(h * rng.uniform(0.3, 0.42)),
                {"lit": "lichen", "mid": "sage", "dark": "deep_sage", "rim": "bone"}, haze="lichen", seed=s)
    return cv


def mid_layer() -> Canvas:
    cv = Canvas(W, ms.MID_BASE + 1)
    base = ms.MID_BASE
    rng = random.Random(41)
    for i in range(4):                                         # arbustos/pinheiros médios atrás dos troncos
        conifer(cv, rng.randrange(W), base, rng.randint(50, 90), rng.randint(26, 36),
                {"lit": "green", "mid": "pine", "dark": "deep_sage", "rim": "emerald"}, haze="sage", seed=90 + i)
    for i, x in enumerate((40, 190, 330, 500)):
        big_tree(cv, x + rng.randint(-20, 20), base, rng.randint(150, 205), rng.randint(10, 16),
                 rng.randint(34, 46), 200 + i, "sage")
    # névoa na base (perspectiva atmosférica)
    for y in range(base - 14, base + 1):
        for x in range(W):
            if cv.get(x, y) is not None:
                cv.px(x, y, mix(INV[cv.get(x, y)], "sage", (y - (base - 14)) / 14 * 0.8, x, y))
    return cv


def plain_layer() -> Canvas:
    cv = Canvas(W, H + 160)
    top = ms.PLAIN_TOP
    rng = random.Random(51)
    for y in range(top, cv.h):
        f = (y - top) / (H - top)
        for x in range(W):
            cv.px(x, y, mix("deep_sage", "charcoal", min(1, f * 1.8), x, y) if f < 0.6 else "charcoal")
    for _ in range(90):                                        # sub-bosque: moitas apoiadas na linha do horizonte
        row = rng.random() < 0.65
        bx = rng.randrange(W)
        by, br = (top + rng.randint(0, 6), rng.uniform(6, 12)) if row else (top + rng.randint(14, 26), rng.uniform(3, 6))
        pts = {(x % W, y) for x, y in blob(bx, by, br, rng.randrange(999), 0.3) if y >= top}
        tmp = Canvas(W, cv.h)
        shade_blob(tmp, pts, bx, by, br, ["green", "pine", "deep_sage", "charcoal"], mode="dir")
        for (x, y) in pts:
            c = tmp.get(x, y)
            if c is not None:
                cv.px(x, y, INV[c])
    for _ in range(160):                                       # estrias do chão distante
        y = top + int(rng.random() ** 1.3 * (H - top))
        x, ln = rng.randrange(W), rng.randint(3, 16)
        for i in range(ln):
            cv.px((x + i) % W, y, "pine" if y < top + 40 else "deep_sage")
    for _ in range(40):                                        # vaga-lumes
        x, y = rng.randrange(W), top + rng.randint(-2, 70)
        cv.px(x, y, "lemon")
        if rng.random() < 0.5:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                cv.px((x + dx) % W, y + dy, "lime")
    return cv.crop(0, top, W, cv.h - top)


# ------------------------------------------------------------------ chão de pouso
THEME = {
    "rim": {"lit": ["sprout", "leaf", "emerald"], "flat": ["leaf", "emerald", "green"],
            "shade": ["emerald", "green", "pine"]},
    "body": ("umber", "olive", "charcoal", "ink"),
}


def ground_strip(face: str, seed: int) -> Canvas:
    rng = random.Random(seed)
    cv = Canvas(STRIP_W, STRIP_D)
    for x in range(STRIP_W):
        for k in range(STRIP_D):
            cv.px(x, k, ps.ground_color(THEME, face, k, x, k))
    for x in range(STRIP_W):                                   # franja de grama descendo na terra
        for k in range(3, 3 + int(2 + 2 * pnoise(x, seed, STRIP_W, (3, 7, 13), (1, .6, .4)))):
            cv.px(x, k, THEME["rim"][face][2] if (x + k) % 3 else THEME["rim"][face][1])
    for _ in range(14):                                        # raízes serpenteando
        x, k = rng.randrange(STRIP_W), rng.randint(6, 60)
        for i in range(rng.randint(12, 40)):
            x += 1
            if rng.random() < 0.35:
                k += rng.choice([-1, 1])
            k = max(5, min(STRIP_D - 4, k))
            cv.px(x % STRIP_W, k, "olive" if k < 30 else "umber")
            cv.px(x % STRIP_W, k + 1, "charcoal" if k < 30 else "ink")
    for _ in range(26):                                        # pedrinhas
        x, k = rng.randrange(STRIP_W), rng.randint(6, 70)
        cv.px(x, k, "lichen" if k < 30 else "sage"); cv.px((x + 1) % STRIP_W, k, "sage")
        cv.px(x, k + 1, "deep_sage"); cv.px((x + 1) % STRIP_W, k + 1, "charcoal")
    return cv


# ------------------------------------------------------------------ enfeites do chão (16x16, base na linha 14)
PROPS = [
    ("grass", {"a": "sprout", "b": "leaf", "c": "emerald"}, [
        "......a.........", "...a..ab..a.....", "...ab.ab.ab.....", "....bab.bab..a..", "..a.bbbcbbb.ab..",
        "..bbcbccbcbbbc..", ".bccccccccccccc."]),
    ("tallgrass", {"a": "sprout", "b": "leaf", "c": "emerald"}, [
        "......a.........", "......a...a.....", "..a...b...a.....", "..a...b..ab.....", "..b..ab..b...a..",
        ".ab..b...b..ab..", ".b...b..bb..b...", ".b..bb..b..bb...", ".bb.b..bb..b....", "..b.b..b..bb....",
        "..bbcb.bbcb.....", ".bcccccccccc...."]),
    ("fern", {"a": "leaf", "b": "green", "c": "pine"}, [
        ".......a........", "......aba.......", "..a..ab.ba..a...", ".aba.b...b.aba..", "ab..bb...bb..ba.",
        "b....bb.bb....b.", "......bbb.......", ".......c........", ".......c........", "......ccc......."]),
    ("redcap", {"a": "coral", "b": "red", "c": "crimson", "w": "white", "d": "cream", "e": "sand"}, [
        "......abbb......", ".....awbbbb.....", "....abbbwbbc....", "....bwbbbbcc....", ".....cccccc.....",
        "......dde.......", "......dde.......", ".....ddeee......"]),
    ("glowcap", {"a": "ice", "b": "aqua", "c": "sea", "w": "white", "d": "mist", "e": "steel"}, [
        ".....a..........", "........a.......", "................", "......aab.......", ".....awabb......",
        ".....bbbbc......", "......dde.......", "......dde.......", ".....ddee......."]),
    ("flowers", {"a": "pink", "c": "lemon", "b": "lavender", "d": "white", "e": "green"}, [
        "...a.....b......", "..aca...bdb.....", "...a..e..b......", "...e..e..e..a...", "...e.ee.e..aca..",
        "..eeeeeeeeeeee.."]),
    ("bush", {"a": "leaf", "b": "emerald", "c": "green", "d": "pine"}, [
        "......aab.......", "....aabbbbc.....", "...abbbabbbc....", "..abbabbbbbcc...", "..bbbbbbbcbcc...",
        "..bbbbcbcccccd..", "..cbcccccccdd...", "...ddddddddd...."]),
    ("browncaps", {"a": "sand", "b": "rosewood", "c": "mauve", "d": "cream"}, [
        "...ab.....ab....", "..abbc...abbc...", "...dd..ab..d....", "...dd.abbc.d....", "..ddd..dd.ddd..."]),
]


def props_atlas() -> Canvas:
    cw, ch = PROP_CELL
    cv = Canvas(cw * len(PROPS), ch)
    for i, (_, legend, rows) in enumerate(PROPS):
        cv.paint(rows, legend, x=i * cw, y=PROP_BASE + 1 - len(rows))
    return cv


# ------------------------------------------------------------------ montagem
def layers() -> dict:
    global INV
    INV = {resolve(n): n for n in COLOR_NAMES}
    ps.COLOR_INV = INV
    L = {}
    c = Canvas(W, H); sky(c); L["sky"] = c
    c = Canvas(W, H); box = sun(c); L["planet"] = c.crop(*box); L["planet_pos"] = box[:2]
    L["far"] = far_layer()
    L["mid"] = mid_layer()
    L["plain"] = plain_layer()
    for i, face in enumerate(("lit", "flat", "shade")):
        L[face] = ground_strip(face, 61 + i)
    L["props"] = props_atlas()
    return L


def compose(L: dict) -> Canvas:
    cv = Canvas(W, H)
    cv.stamp(L["sky"]); cv.stamp(L["planet"], *L["planet_pos"])
    cv.stamp(L["far"]); cv.stamp(L["mid"]); cv.stamp(L["plain"], 0, ms.PLAIN_TOP)
    pad = ms.PREVIEW_PAD
    pts = profile(W, seed=7, base=292, amp=60, pad=pad)
    faces = ms.segment_faces(pts)
    for x in range(W):
        r = ridge_y(pts, x)
        seg = min(sum(1 for p in pts[1:] if p[0] <= x), len(faces) - 1)
        for y in range(r, H):
            k = y - r
            cv.px(x, y, L[faces[seg]].get(x % STRIP_W, k) if k < STRIP_D else "ink")
    rng = random.Random(31)
    cw, ch = PROP_CELL
    x = rng.uniform(4, 20)
    while x < W - 8:
        if not (pad[0] - 12 < x < pad[0] + pad[1] + 12):
            i = rng.randrange(len(PROPS))
            cv.stamp(L["props"].crop(i * cw, 0, cw, ch), int(x - cw / 2), ridge_y(pts, x) + rng.randint(0, 2) - PROP_BASE)
        x += rng.uniform(*PROP_SPACING)
    y = ridge_y(pts, pad[0] + pad[1] // 2)
    beam = Canvas.from_image("assets/sprites/target_beam.png").crop(0, 0, 64, 84)
    padspr = Canvas.from_image("assets/sprites/landing_pad.png")
    cv.stamp(beam, pad[0], y - 84)
    cv.stamp(padspr.crop(0, 28, 80, 28), pad[0] - 8, y - 10)
    lander = Canvas.from_image("assets/sprites/lander.png").crop(0, 0, 32, 32)
    cv.stamp(lander, pad[0] + pad[1] // 2 - 16, y - 25)
    return cv


def export(L: dict) -> None:
    for k in ("sky", "planet", "far", "mid", "plain", "props"):
        L[k].save(P[k])
    for k in ("lit", "flat", "shade"):
        L[k].save(P[k], tiled=True)
    meta = {
        "notes": "Floresta fechada (mundo 2, id ares). Gerado por art/src/bg/forest_scene.py (pixel-art).",
        "horizon": HORIZON, "planet_pos": list(L["planet_pos"]), "far_y": 0, "mid_y": 0, "plain_y": ms.PLAIN_TOP,
        "deep_color": "#2e222f", "strip_depth": STRIP_D, "strip_width": STRIP_W, "face_slope": FACE_SLOPE,
        "rock_cell": list(PROP_CELL), "rock_base_row": PROP_BASE, "rock_count": len(PROPS),
        "rock_widths": [16] * len(PROPS), "rock_spacing": list(PROP_SPACING),
    }
    with open(P["meta"], "w") as f:
        json.dump(meta, f, indent=2)


if __name__ == "__main__":
    L = layers()
    sc = compose(L)
    print("cores:", len(sc.colors_used()))
    sc.save("art/previews/forest_scene.png", preview=False)
    sc.preview("art/previews/forest_scene_2x.png", scale=2, grid=False, show_1x=False)
    L["props"].preview("art/previews/forest_props_preview.png", scale=6)
    if "--export" in sys.argv:
        export(L)
