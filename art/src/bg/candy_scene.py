"""Mundo 3 — PLANETA DOS DOCES (id `kronos` no código). Padrão: patterns/candy-scene.md.

Regra do usuário: cada planeta é um mundo totalmente diferente; mesmo ESTILO (rico em camadas, luz de cima-esquerda,
perspectiva atmosférica, Resurrect 64), formas de doces.
Camadas (mesmo contrato do jogo, assets/bg/kronos_layers.json):
  sky    pastel roxo -> lilás -> rosa -> pêssego, brilhinhos, nuvens de algodão-doce
  planet planeta-rosquinha com cobertura e granulado
  far    colinas de goma com cobertura escorrendo (névoa lilás)
  mid    morros de chocolate com glacê, pirulitos gigantes em espiral, bengalas listradas
  plain  rio de chocolate brilhante com marshmallows na margem
  ground bolo em camadas: cobertura + granulado, pão de ló, geleia, chocolate
  props  atlas 8 x 16x16 (base na linha 14): pirulito, bengala, bala de goma, cupcake, bombom, rosquinha, sorvete,
         marshmallows
Rodar da raiz: python3 art/src/bg/candy_scene.py [--export]
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

P = {"sky": "assets/bg/kronos_sky.png", "planet": "assets/bg/kronos_planet.png", "far": "assets/bg/kronos_far.png",
     "mid": "assets/bg/kronos_mid.png", "plain": "assets/bg/kronos_plain.png",
     "lit": "assets/tiles/kronos_ground_lit.png", "flat": "assets/tiles/kronos_ground_flat.png",
     "shade": "assets/tiles/kronos_ground_shade.png", "props": "assets/sprites/kronos_rocks.png",
     "meta": "assets/bg/kronos_layers.json"}
PROP_CELL = (16, 16)
PROP_BASE = 14
PROP_SPACING = (10, 30)
DONUT = (150, 92, 30)
SPRINKLES = ["lemon", "sky", "leaf", "white", "red", "aqua"]
INV = {}


def pxw(cv: Canvas, x: int, y: int, c) -> None:
    cv.px(x % cv.w, y, c)


def paint_blob(cv: Canvas, pts: set, cx: float, cy: float, r: float, ramp: list, wrap: bool = True) -> None:
    """Sombreamento direcional (luz de cima-esquerda) com transições pontilhadas entre os tons da rampa
    (sem o corte diagonal duro) + aro claro nas bordas de cima/esquerda."""
    n = len(ramp)
    for (x, y) in pts:
        if not 0 <= y < cv.h:
            continue
        t = ((x - cx) * 0.6 + (y - cy) * 0.8) / (r * 1.15)          # -1 luz .. 1 sombra
        f = max(0.0, min(n - 1.001, (t + 1) / 2 * (n - 1)))
        i = int(f)
        c = mix(ramp[i], ramp[min(i + 1, n - 1)], f - i, x, y)
        if ((x, y - 1) not in pts or (x - 1, y) not in pts) and t < 0.1:
            c = ramp[0]
        (pxw if wrap else cv.px)(cv, x, y, c)


# ------------------------------------------------------------------ céu pastel + algodão-doce
def sky(cv: Canvas) -> None:
    bands = [(0, "plum"), (60, "purple"), (128, "violet"), (184, "lavender"), (228, "pink"), (258, "peach")]
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
    rng = random.Random(7)
    for _ in range(90):                                       # brilhinhos açucarados
        x, y = rng.randrange(W), int(rng.random() ** 1.4 * 150)
        cv.px(x, y, rng.choice(["white", "lavender", "white", "pale_sky"]))
    for x, y in ((90, 30), (260, 52), (400, 20), (590, 64), (520, 140)):
        cv.px(x, y, "white")
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            cv.px(x + dx, y + dy, "lavender")
    # nuvens de algodão-doce: bolhas unidas, topo claro, base sombreada e quase reta
    for cx, cy, wdt, kind in ((70, 120, 70, "pink"), (250, 92, 54, "blue"), (360, 150, 80, "pink"),
                              (520, 106, 60, "blue"), (610, 170, 46, "pink"), (190, 190, 40, "blue")):
        ramp = ["white", "lavender", "pink", "rose"] if kind == "pink" else ["white", "pale_sky", "violet", "purple"]
        bubbles = []
        for i in range(6):
            bx = cx - wdt / 2 + (i + 0.5) * wdt / 6 + rng.uniform(-4, 4)
            br = wdt / 6 * rng.uniform(1.0, 1.7) * (1.25 if 1 < i < 4 else 1)
            bubbles.append((bx, cy - br * 0.35, br, rng.randrange(999)))
        # de trás para frente: bolhas maiores/mais altas primeiro; cada bolha com luz própria (fofa)
        for bx, by, br, sd in sorted(bubbles, key=lambda b: b[1]):
            pts = {(x, y) for x, y in blob(bx, by, br, sd, 0.15) if y <= cy + 4}
            paint_blob(cv, pts, bx, by, br, ramp[:3])
        for x in range(int(cx - wdt / 2 - 6), int(cx + wdt / 2 + 6)):      # base achatada sombreada
            for y in (cy + 3, cy + 4):
                if INV.get(cv.get(x % W, y)) in ramp[:3]:
                    cv.px(x % W, y, ramp[3])


def donut(cv: Canvas) -> tuple:
    cx, cy, R = DONUT
    r_in, squash, thick = R * 0.36, 0.55, 5

    def ring(x, y, oy=0):
        dx, dy = (x - cx) / R, (y - cy - oy) / (R * squash)
        dxi, dyi = (x - cx) / r_in, (y - cy - oy) / (r_in * squash)
        return dx * dx + dy * dy <= 1 and dxi * dxi + dyi * dyi > 1

    for y in range(cy - R - 14, cy + R + 15):                 # halo rosado
        for x in range(cx - R - 14, cx + R + 15):
            d = math.hypot((x - cx) / R, (y - cy) / (R * 0.75))
            if 1.0 < d <= 1.45 and cv.inside(x, y):
                lvl = 1 - (d - 1) / 0.45
                if lvl > 0.15:
                    cv.px(x, y, mix(INV.get(cv.get(x, y), "clear"), "lavender", lvl * 0.8, x, y))
    for y in range(cy - R, cy + R + thick + 1):               # massa (lado de baixo/da frente)
        for x in range(cx - R, cx + R + 1):
            if ring(x, y, thick) and not ring(x, y):
                t = (x - cx) / R
                cv.px(x, y, "honey" if t < -0.3 else "copper" if t < 0.5 else "terracotta")
    rng = random.Random(3)
    for y in range(cy - R, cy + R + 1):                       # cobertura com borda ondulada (escorrendo)
        for x in range(cx - R, cx + R + 1):
            if ring(x, y):
                drip = math.sin(x * 0.9) > 0.6 and y > cy
                lx = -(x - cx) / R * 0.6 - (y - cy) / (R * squash) * 0.8
                c = "white" if lx > 0.65 else "pink" if lx > -0.35 else "rose"
                cv.px(x, y, c)
                if drip:
                    cv.px(x, y + 1, "rose")
    for _ in range(40):                                       # granulado
        x, y = rng.randint(cx - R, cx + R), rng.randint(cy - R, cy + R)
        if ring(x, y) and ring(x + 1, y):
            c = rng.choice(SPRINKLES)
            cv.px(x, y, c); cv.px(x + (1 if rng.random() < 0.5 else 0), y + (0 if rng.random() < 0.5 else 1), c)
    return (cx - R - 15, cy - R - 15, 2 * R + 31, 2 * R + thick + 31)


# ------------------------------------------------------------------ colinas de goma (far)
def far_layer() -> Canvas:
    cv = Canvas(W, HORIZON + 1)
    rng = random.Random(29)
    hills = [(rng.randrange(W), rng.randint(36, 70), rng.randint(40, 70)) for _ in range(14)]
    for hx, hh, hw in sorted(hills, key=lambda h: -h[1]):
        pts = set()
        for y in range(HORIZON - hh, HORIZON + 1):
            t = (y - (HORIZON - hh)) / hh
            half = hw * math.sqrt(max(0.0, 1 - (1 - t) ** 2))
            for dx in range(-int(half), int(half) + 1):
                pts.add((hx + dx, y))
        tmp = Canvas(W * 3, cv.h)
        shade_blob(tmp, {(x + W, y) for x, y in pts}, hx + W, HORIZON - hh * 0.4, hh, ["salmon", "pink", "rose", "berry"],
                   mode="dir")
        cap = HORIZON - hh + int(hh * 0.28)                     # cobertura lilás escorrendo
        for (x, y) in pts:
            c = INV[tmp.get(x + W, y)]
            drip = cap + int(4 * abs(math.sin(x * 0.7 + hx)))
            if y < drip:
                c = "white" if (x - hx) < -hw * 0.2 and y < cap - 2 else "lavender"
            if y > HORIZON - 16:
                c = mix(c, "lavender", (y - (HORIZON - 16)) / 16 * 0.85, x, y)
            pxw(cv, x, y, c)
    return cv


# ------------------------------------------------------------------ pirulitos, bengalas, morros de chocolate (mid)
def lollipop(cv: Canvas, x0: int, base: int, h: int, r: int, pair: tuple) -> None:
    for y in range(base - h + r, base + 1):                   # palito
        pxw(cv, x0, y, "cream"); pxw(cv, x0 + 1, y, "sand")
    cy = base - h
    a, b, shade_a, shade_b = pair
    for y in range(cy - r, cy + r + 1):
        for x in range(x0 - r, x0 + r + 1):
            d = math.hypot(x - x0, y - cy)
            if d > r:
                continue
            ang = math.atan2(y - cy, x - x0)
            band = ((ang + d * 0.32) % (2 * math.pi / 3)) < (math.pi / 3)
            dark = (x - x0) * 0.6 + (y - cy) * 0.8 > r * 0.25
            c = (shade_a if dark else a) if band else (shade_b if dark else b)
            if d > r - 1 and (x - x0) * 0.6 + (y - cy) * 0.8 < -r * 0.3:
                c = "white"                                     # brilho na borda iluminada
            pxw(cv, x, y, c)


def cane(cv: Canvas, x0: int, base: int, h: int) -> None:
    w, hook = 5, 9
    top = base - h
    for y in range(top + hook // 2, base + 1):                # haste listrada na diagonal
        for dx in range(w):
            s = ((x0 + dx) + y) % 8 < 4
            c = ("red" if dx > 0 else "coral") if s else ("white" if dx < 3 else "mist")
            if dx == w - 1:
                c = "crimson" if s else "mist"
            pxw(cv, x0 + dx, y, c)
    for a in range(0, 181, 3):                                 # gancho
        t = math.radians(a)
        for rr in range(hook - w + 1, hook + 1):
            x = round(x0 - hook + w / 2 + (hook - 0.5) * 0 + rr * math.cos(t) + hook - w / 2)
            y = round(top + hook // 2 - rr * math.sin(t))
            s = (x + y) % 8 < 4
            pxw(cv, x - hook + w // 2 - 2, y, "red" if s else "white")


def choco_hill(cv: Canvas, hx: int, base: int, hh: int, hw: int, seed: int) -> None:
    pts = set()
    for y in range(base - hh, base + 1):
        t = (y - (base - hh)) / hh
        half = hw * (0.25 + 0.75 * math.sqrt(t))
        for dx in range(-int(half), int(half) + 1):
            pts.add((hx + dx, y))
    paint_blob(cv, pts, hx, base - hh * 0.5, hh, ["sand", "rosewood", "mauve", "plum_dark"])
    rng = random.Random(seed)
    for x in range(hx - hw, hx + hw + 1):                      # glacê escorrendo do topo
        tops = [y for (xx, y) in pts if xx == x]
        if not tops:
            continue
        y0 = min(tops)
        ln = 3 + int(5 * abs(math.sin(x * 0.45 + seed))) + (rng.randint(0, 6) if rng.random() < 0.2 else 0)
        for k in range(ln):
            lit = (x - hx) < 0
            c = "white" if k < ln - 1 and lit else "cream" if k < ln - 1 else "lavender"
            pxw(cv, x, y0 + k, c)


def mid_layer() -> Canvas:
    cv = Canvas(W, ms.MID_BASE + 1)
    base = ms.MID_BASE
    rng = random.Random(61)
    for i, hx in enumerate((60, 230, 400, 560)):
        choco_hill(cv, hx + rng.randint(-20, 20), base, rng.randint(60, 95), rng.randint(70, 95), 70 + i)
    pairs = [("red", "white", "crimson", "mist"), ("hot_pink", "lemon", "raspberry", "gold"),
             ("aqua", "white", "sea", "mist"), ("violet", "white", "purple", "lavender")]
    for i, x in enumerate((130, 300, 470, 610)):
        lollipop(cv, x + rng.randint(-12, 12), base, rng.randint(110, 165), rng.randint(16, 24), pairs[i % len(pairs)])
    for x in (20, 360, 520):
        cane(cv, x + rng.randint(-10, 10), base, rng.randint(80, 120))
    for y in range(base - 14, base + 1):                       # névoa lilás na base
        for x in range(W):
            if cv.get(x, y) is not None:
                cv.px(x, y, mix(INV[cv.get(x, y)], "lavender", (y - (base - 14)) / 14 * 0.8, x, y))
    return cv


# ------------------------------------------------------------------ rio de chocolate (plain)
def plain_layer() -> Canvas:
    cv = Canvas(W, H + 160)
    top = ms.PLAIN_TOP
    rng = random.Random(71)
    for y in range(top, cv.h):
        f = (y - top) / (H - top)
        for x in range(W):
            cv.px(x, y, mix("rosewood", "mauve", min(1, f * 2.0), x, y) if f < 0.5 else
                  mix("mauve", "plum_dark", min(1, (f - 0.5) * 2), x, y) if f < 1 else "plum_dark")
    for _ in range(230):                                       # correnteza brilhante
        y = top + 3 + int(rng.random() ** 1.3 * (H - top))
        x, ln = rng.randrange(W), rng.randint(4, 22)
        near = (y - top) / (H - top)
        c = "peach" if near < 0.2 else "sand" if near < 0.5 else "rosewood"
        for i in range(ln):
            cv.px((x + i) % W, y, c)
            if i in (0, ln - 1) and near < 0.5:
                cv.px((x + i) % W, y, "rosewood")
    for _ in range(26):                                        # marshmallows na margem
        mx, mw = rng.randrange(W), rng.randint(5, 9)
        my = top + rng.randint(-2, 3)
        for dy in range(-4, 1):
            for dx in range(mw):
                c = "white" if dx < mw * 0.4 and dy < -1 else "mist" if dy < 0 else "lavender"
                if dy == -4 and dx in (0, mw - 1):
                    continue
                cv.px((mx + dx) % W, my + dy, c)
    for x in range(W):
        cv.px(x, top, "sand" if pnoise(x, 5) > 0 else "peach")
    return cv.crop(0, top - 6, W, cv.h - top + 6)


# ------------------------------------------------------------------ bolo em camadas (chão de pouso)
RIM = {"lit": ["white", "cream", "pink"], "flat": ["cream", "pink", "pink"], "shade": ["pink", "rose", "rose"]}


def cake_color(face: str, k: int, x: int, drip: int):
    rim = RIM[face]
    if k < 3:
        return rim[k]
    if k < 3 + drip:                                            # cobertura escorrendo sobre o pão de ló
        return rim[2] if k < 2 + drip else "rose"
    if k < 22:
        return mix("sand", "honey" if face == "lit" else "sand", 0.3, x, k) if k < 12 else "sand"
    if k < 26:                                                  # geleia
        return "red" if k < 25 else "crimson"
    if k < 44:
        return "sand" if k < 40 else mix("sand", "rosewood", (k - 40) / 4, x, k)
    if k < 70:                                                  # camada de chocolate
        return "rosewood" if k < 48 else mix("rosewood", "mauve", (k - 48) / 22, x, k)
    return mix("mauve", "plum_dark", min(1, (k - 70) / 40), x, k)


def ground_strip(face: str, seed: int) -> Canvas:
    rng = random.Random(seed)
    cv = Canvas(STRIP_W, STRIP_D)
    for x in range(STRIP_W):
        drip = 2 + int(5 * abs(math.sin(x * 0.55 + seed))) + (4 if (x * 13 + seed) % 23 == 0 else 0)
        for k in range(STRIP_D):
            cv.px(x, k, cake_color(face, k, x, drip))
    for _ in range(60):                                         # furinhos do pão de ló
        x, k = rng.randrange(STRIP_W), rng.choice([rng.randint(12, 21), rng.randint(27, 39)])
        if cv.get(x, k) == resolve("sand"):
            cv.px(x, k, "rosewood" if rng.random() < 0.6 else "honey")
    for _ in range(30):                                         # granulado na cobertura
        x, k = rng.randrange(STRIP_W), rng.randint(0, 3)
        c = rng.choice(SPRINKLES)
        cv.px(x, k, c)
        cv.px((x + 1) % STRIP_W, k, c)
    for _ in range(20):                                         # lascas de chocolate
        x, k = rng.randrange(STRIP_W), rng.randint(50, 100)
        cv.px(x, k, "rosewood"); cv.px((x + 1) % STRIP_W, k, "sand" if k < 70 else "rosewood")
    return cv


# ------------------------------------------------------------------ enfeites (16x16, base na linha 14)
ASCII_PROPS = {
    "gumdrop": ({"a": "sprout", "b": "leaf", "c": "green", "w": "white"}, [
        ".....aab........", "....abbbc.......", "...abwbbbc......", "...bbbbwbc......", "...bbbbbcc......",
        "...cccccc......."]),
    "cupcake": ({"a": "red", "b": "crimson", "w": "white", "p": "pink", "q": "rose", "s": "sea", "t": "aqua"}, [
        ".......a........", "......ab........", ".....wwpp.......", "....wwpppq......", "...wppppppq.....",
        "...ssttsstt.....", "...ssttsstt.....", "....sttsst......", "....ssssss......"]),
    "bonbon": ({"a": "lavender", "b": "violet", "c": "purple", "w": "white"}, [
        "..a..bbbbc..a...", "..aabwbbbccaa...", "..aabbbbbccaa...", "..a..bccccc.a..."]),
    "donut": ({"w": "white", "p": "pink", "q": "rose", "h": "honey", "g": "copper", "s": "sky", "l": "lemon"}, [
        "....wpslppq.....", "..wppqplppsqq...", "..hhhhhhhhhhg...", "...hhhhhhhgg...."]),
    "icecream": ({"w": "white", "p": "pale_sky", "q": "sky", "h": "honey", "g": "copper", "r": "red"}, [
        "......r.........", ".....wpp........", "....wpppq.......", "....pppqq.......", "....hhhhg.......",
        ".....hgh........", ".....ghg........", "......h........."]),
    "marshmallow": ({"w": "white", "m": "mist", "l": "lavender"}, [
        "....wwwm........", "....wmmm........", "....llll.wwwm...", "....wwwm.wmmm...", "....wmmm.llll...",
        "....llll.wwwm..."]),
}
PROP_ORDER = ["lollipop", "cane", "gumdrop", "cupcake", "bonbon", "donut", "icecream", "marshmallow"]


def props_atlas() -> Canvas:
    cw, ch = PROP_CELL
    cv = Canvas(cw * len(PROP_ORDER), ch)
    for i, name in enumerate(PROP_ORDER):
        ox = i * cw
        if name == "lollipop":
            tmp = Canvas(W, ch)
            lollipop(tmp, 7, PROP_BASE, 12, 4, ("hot_pink", "white", "raspberry", "mist"))
            cv.stamp(tmp.crop(0, 0, cw, ch), ox, 0)
        elif name == "cane":
            for y in range(6, PROP_BASE + 1):
                for dx in range(2):
                    s = (dx + y) % 4 < 2
                    cv.px(ox + 9 + dx, y, "red" if s else "white")
            for x, y in ((9, 5), (8, 4), (7, 4), (6, 4), (5, 5), (5, 6), (10, 5), (9, 4)):
                cv.px(ox + x, y, "red" if (x + y) % 4 < 2 else "white")
        else:
            legend, rows = ASCII_PROPS[name]
            cv.paint(rows, legend, x=ox, y=PROP_BASE + 1 - len(rows))
    return cv


# ------------------------------------------------------------------ montagem
def layers() -> dict:
    global INV
    INV = {resolve(n): n for n in COLOR_NAMES}
    L = {}
    c = Canvas(W, H); sky(c); L["sky"] = c
    c = Canvas(W, H); box = donut(c); L["planet"] = c.crop(*box); L["planet_pos"] = box[:2]
    L["far"] = far_layer()
    L["mid"] = mid_layer()
    L["plain"] = plain_layer()
    L["plain_y"] = ms.PLAIN_TOP - 6
    for i, face in enumerate(("lit", "flat", "shade")):
        L[face] = ground_strip(face, 61 + i)
    L["props"] = props_atlas()
    return L


def compose(L: dict) -> Canvas:
    cv = Canvas(W, H)
    cv.stamp(L["sky"]); cv.stamp(L["planet"], *L["planet_pos"])
    cv.stamp(L["far"]); cv.stamp(L["mid"]); cv.stamp(L["plain"], 0, L["plain_y"])
    pad = ms.PREVIEW_PAD
    pts = profile(W, seed=7, base=292, amp=60, pad=pad)
    faces = ms.segment_faces(pts)
    for x in range(W):
        r = ridge_y(pts, x)
        seg = min(sum(1 for p in pts[1:] if p[0] <= x), len(faces) - 1)
        for y in range(r, H):
            k = y - r
            cv.px(x, y, L[faces[seg]].get(x % STRIP_W, k) if k < STRIP_D else "plum_dark")
    rng = random.Random(31)
    cw, ch = PROP_CELL
    x = rng.uniform(4, 20)
    while x < W - 8:
        if not (pad[0] - 12 < x < pad[0] + pad[1] + 12):
            i = rng.randrange(len(PROP_ORDER))
            cv.stamp(L["props"].crop(i * cw, 0, cw, ch), int(x - cw / 2), ridge_y(pts, x) + rng.randint(0, 2) - PROP_BASE)
        x += rng.uniform(*PROP_SPACING)
    y = ridge_y(pts, pad[0] + pad[1] // 2)
    cv.stamp(Canvas.from_image("assets/sprites/target_beam.png").crop(0, 0, 64, 84), pad[0], y - 84)
    cv.stamp(Canvas.from_image("assets/sprites/landing_pad.png").crop(0, 28, 80, 28), pad[0] - 8, y - 10)
    cv.stamp(Canvas.from_image("assets/sprites/lander.png").crop(0, 0, 32, 32), pad[0] + pad[1] // 2 - 16, y - 25)
    return cv


def export(L: dict) -> None:
    for k in ("sky", "planet", "far", "mid", "plain", "props"):
        L[k].save(P[k])
    for k in ("lit", "flat", "shade"):
        L[k].save(P[k], tiled=True)
    meta = {
        "notes": "Planeta dos doces (mundo 3, id kronos). Gerado por art/src/bg/candy_scene.py (pixel-art).",
        "horizon": HORIZON, "planet_pos": list(L["planet_pos"]), "far_y": 0, "mid_y": 0, "plain_y": L["plain_y"],
        "deep_color": "#45293f", "strip_depth": STRIP_D, "strip_width": STRIP_W, "face_slope": FACE_SLOPE,
        "rock_cell": list(PROP_CELL), "rock_base_row": PROP_BASE, "rock_count": len(PROP_ORDER),
        "rock_widths": [16] * len(PROP_ORDER), "rock_spacing": list(PROP_SPACING),
    }
    with open(P["meta"], "w") as f:
        json.dump(meta, f, indent=2)


if __name__ == "__main__":
    L = layers()
    sc = compose(L)
    print("cores:", len(sc.colors_used()))
    sc.save("art/previews/candy_scene.png", preview=False)
    sc.preview("art/previews/candy_scene_2x.png", scale=2, grid=False, show_1x=False)
    L["props"].preview("art/previews/candy_props_preview.png", scale=6)
    if "--export" in sys.argv:
        export(L)
