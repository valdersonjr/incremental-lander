"""Cenas de Ares, Kronos e Titan — MESMO estilo da cena da Lua aprovada (patterns/moon-scene.md), outras rampas.

Regra do usuário: mesmo estilo de arte, só a paleta Resurrect 64 (muda a rampa, nunca a paleta).
Reaproveita as técnicas de moon_scene.py (montanhas facetadas, faixas do céu, estrias, pedregulhos); a Lua fica
intocada em moon_scene.py. Mesmo contrato do jogo: assets/bg/<planeta>_layers.json + camadas + faixas + pedras.
Rodar da raiz: python3 art/src/bg/planet_scenes.py [ares|kronos|titan ...] [--export]
"""
import json
import math
import random
import sys

sys.path.insert(0, ".claude/skills/pixel-art/scripts")
sys.path.insert(0, "art/src/terrain")
sys.path.insert(0, "art/src/bg")
from pixelart import *
from moon import profile, ridge_y
import moon_scene as ms
from moon_scene import mix, mountains, W, H, HORIZON, STRIP_W, STRIP_D, FACE_SLOPE, ROCK_CELL, ROCK_SIZES

# caminhos literais (o pre-commit procura a fonte de cada asset pelo caminho escrito no script)
PATHS = {
    "ares": {"sky": "assets/bg/ares_sky.png", "planet": "assets/bg/ares_planet.png", "far": "assets/bg/ares_far.png",
             "mid": "assets/bg/ares_mid.png", "plain": "assets/bg/ares_plain.png",
             "lit": "assets/tiles/ares_ground_lit.png", "flat": "assets/tiles/ares_ground_flat.png",
             "shade": "assets/tiles/ares_ground_shade.png", "rocks": "assets/sprites/ares_rocks.png",
             "meta": "assets/bg/ares_layers.json"},
    "kronos": {"sky": "assets/bg/kronos_sky.png", "planet": "assets/bg/kronos_planet.png",
               "far": "assets/bg/kronos_far.png", "mid": "assets/bg/kronos_mid.png",
               "plain": "assets/bg/kronos_plain.png", "lit": "assets/tiles/kronos_ground_lit.png",
               "flat": "assets/tiles/kronos_ground_flat.png", "shade": "assets/tiles/kronos_ground_shade.png",
               "rocks": "assets/sprites/kronos_rocks.png", "meta": "assets/bg/kronos_layers.json"},
    "titan": {"sky": "assets/bg/titan_sky.png", "planet": "assets/bg/titan_planet.png",
              "far": "assets/bg/titan_far.png", "mid": "assets/bg/titan_mid.png", "plain": "assets/bg/titan_plain.png",
              "lit": "assets/tiles/titan_ground_lit.png", "flat": "assets/tiles/titan_ground_flat.png",
              "shade": "assets/tiles/titan_ground_shade.png", "rocks": "assets/sprites/titan_rocks.png",
              "meta": "assets/bg/titan_layers.json"},
}

THEMES = {
    # Ares: gravidade forte, poeira — anoitecer empoeirado, sol pálido baixo, 2 luas, rocha ferrugem
    "ares": {
        "sky": [(0, "ink"), (80, "plum_dark"), (150, "wine"), (205, "rust"), (240, "terracotta"), (262, "copper")],
        "stars": (170, 150, ["lilac_grey", "mist", "peach"], [5, 2, 1]), "twinkles": 3,
        "object": ("sun", (150, 168, 10)), "moons": [(470, 64, 7, ["umber", "rosewood", "sand"]),
                                                     (532, 104, 4, ["umber", "mauve", "rosewood"])],
        "far": ({"shadow": "wine", "mid": "wine", "lit": "rust", "ridge": "rust"}, "terracotta", (60, 110), 9, 23),
        "mid": ({"shadow": "maroon", "mid": "wine", "lit": "terracotta", "ridge": "copper"}, "rust", (35, 95), 6, 27,
                90),
        "plain": ("rust", "wine", ["terracotta", "rust", "wine"], ["copper", "terracotta"]),
        "rim": {"lit": ["peach", "honey", "copper"], "flat": ["honey", "copper", "terracotta"],
                "shade": ["copper", "terracotta", "rust"]},
        "body": ("rust", "terracotta", "wine", "maroon"), "deep_hex": "#6e2727",
        "estria": (["copper", "terracotta", "rust"], ["rust", "wine", "maroon"]),
        "estria_deep": (["wine", "maroon", "maroon"], ["umber", "umber"]),
        "rock": ["peach", "honey", "copper", "terracotta", "rust", "wine"],
        "crater": ("rust", "wine", "copper", "terracotta"),
    },
    # Kronos: atmosfera densa — neblina verde-acinzentada, gigante com anéis, rocha escura com musgo tóxico
    "kronos": {
        "sky": [(0, "charcoal"), (90, "deep_sage"), (165, "sage"), (222, "lichen"), (256, "bone")],
        "stars": (50, 70, ["lichen", "bone"], [3, 1]), "twinkles": 0,
        "object": ("ringed", (470, 96, 30)), "moons": [(150, 60, 5, ["charcoal", "deep_sage", "lichen"])],
        "far": ({"shadow": "sage", "mid": "sage", "lit": "lichen", "ridge": "bone"}, "lichen", (55, 100), 8, 33),
        "mid": ({"shadow": "charcoal", "mid": "deep_sage", "lit": "sage", "ridge": "lichen"}, "sage", (30, 85), 6, 37,
                60),
        "plain": ("deep_sage", "charcoal", ["sage", "deep_sage", "charcoal"], ["lichen", "sage"]),
        "rim": {"lit": ["bone", "lichen", "sage"], "flat": ["lichen", "sage", "sage"],
                "shade": ["sage", "deep_sage", "deep_sage"]},
        "body": ("deep_sage", "sage", "charcoal", "ink"), "deep_hex": "#2e222f",
        "estria": (["lichen", "olive", "olive"], ["deep_sage", "charcoal", "ink"]),
        "estria_deep": (["deep_sage", "charcoal", "charcoal"], ["ink", "ink"]),
        "rock": ["bone", "lichen", "sage", "deep_sage", "charcoal", "ink"],
        "crater": ("deep_sage", "charcoal", "lichen", "sage"),
    },
    # Titan: gigante gelado — noite azul com aurora, montanhas de gelo altas, chão de gelo
    "titan": {
        "sky": [(0, "ink"), (100, "navy"), (175, "indigo"), (226, "blue"), (258, "sky")],
        "stars": (420, 230, ["lilac_grey", "mist", "white", "pale_sky"], [5, 3, 1.2, 1.5]), "twinkles": 6,
        "object": ("moon", (150, 70, 16)), "moons": [], "aurora": True,
        "far": ({"shadow": "indigo", "mid": "indigo", "lit": "blue", "ridge": "sky"}, "blue", (80, 135), 10, 43),
        "mid": ({"shadow": "navy", "mid": "indigo", "lit": "sky", "ridge": "pale_sky"}, "indigo", (45, 115), 7, 47,
                100),
        "plain": ("indigo", "navy", ["sky", "blue", "indigo"], ["pale_sky", "sky"]),
        "rim": {"lit": ["white", "pale_sky", "sky"], "flat": ["pale_sky", "sky", "blue"],
                "shade": ["sky", "blue", "indigo"]},
        "body": ("blue", "sky", "indigo", "navy"), "deep_hex": "#323353",
        "estria": (["pale_sky", "sky", "blue"], ["blue", "indigo", "navy"]),
        "estria_deep": (["indigo", "navy", "navy"], ["ink", "ink"]),
        "rock": ["white", "ice", "pale_sky", "sky", "blue", "indigo"],
        "crater": ("blue", "indigo", "pale_sky", "sky"),
    },
}


# ------------------------------------------------------------------ céu
def sky(cv: Canvas, th: dict) -> None:
    bands = th["sky"]
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
    if th.get("aurora"):
        aurora(cv)
    n, max_y, cols, wts = th["stars"]
    rng = random.Random(11)
    for _ in range(n):
        x, y = rng.randrange(W), int(rng.random() ** 1.6 * max_y)
        cv.px(x, y, rng.choices(cols, wts)[0])
    for x, y in ((60, 40), (205, 22), (330, 78), (560, 30), (610, 120), (120, 150))[:th["twinkles"]]:
        cv.px(x, y, "white")
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            cv.px(x + dx, y + dy, "mist")
        for dx, dy in ((2, 0), (-2, 0), (0, 2), (0, -2)):
            cv.px(x + dx, y + dy, "lilac_grey")
    for mx, my, mr, ramp in th["moons"]:
        sphere(cv, mx, my, mr, ramp)


def aurora(cv: Canvas) -> None:
    """Cortinas de aurora: faixas verticais pontilhadas que ondulam, mais fortes embaixo da cortina."""
    for x in range(W):
        top = 40 + 18 * ms.pnoise(x, 71, W, (1, 2, 5), (1, .6, .3))
        length = 70 + 30 * ms.pnoise(x, 73, W, (2, 3, 7), (1, .5, .3))
        glow = 0.5 + 0.5 * ms.pnoise(x, 75, W, (3, 4, 9), (1, .7, .4))
        for y in range(int(top), int(top + length)):
            t = max(0.0, (y - top) / length)             # 0 topo da cortina .. 1 base
            lvl = glow * (t ** 1.5) * 0.9
            if t > 0.92:
                lvl *= (1 - t) / 0.08
            base = COLOR_INV.get(cv.get(x, y))
            c = "leaf" if lvl > 0.62 else "emerald" if lvl > 0.42 else "sea" if lvl > 0.22 else "teal"
            if lvl > 0.06:
                cv.px(x, y, mix(base, c, min(1.0, lvl * 1.6), x, y))


def sphere(cv: Canvas, cx: int, cy: int, r: int, ramp: list, halo=None) -> None:
    """Esfera iluminada de cima-esquerda (ramp escuro->claro), terminador pontilhado, halo opcional."""
    if halo:
        for y in range(cy - r - 10, cy + r + 11):
            for x in range(cx - r - 10, cx + r + 11):
                d = math.hypot(x - cx, y - cy)
                if r < d <= r + 10 and cv.inside(x, y):
                    lvl = 1 - (d - r) / 10
                    if lvl > 0.15:
                        cv.px(x, y, mix(COLOR_INV.get(cv.get(x, y), "clear"), halo, lvl * 0.85, x, y))
    for y in range(cy - r, cy + r + 1):
        for x in range(cx - r, cx + r + 1):
            dx, dy = (x - cx) / r, (y - cy) / r
            if dx * dx + dy * dy > 1:
                continue
            dz = math.sqrt(max(0.0, 1 - dx * dx - dy * dy))
            light = -0.6 * dx - 0.55 * dy + 0.58 * dz
            n = len(ramp)
            i = max(0, min(n - 1, int((light + 0.35) / 1.25 * n)))
            c = ramp[i]
            if i > 0 and (light + 0.35) / 1.25 * n - i < 0.25:
                c = mix(ramp[i - 1], ramp[i], 0.5, x, y)
            cv.px(x, y, c)


def sky_object(cv: Canvas, th: dict) -> tuple:
    """Desenha o objeto do céu (camada 'planet'); devolve a caixa (x, y, w, h) para recortar."""
    kind, (cx, cy, r) = th["object"]
    if kind == "sun":
        for y in range(cy - r - 14, cy + r + 15):                     # brilho largo empoeirado
            for x in range(cx - r - 14, cx + r + 15):
                d = math.hypot(x - cx, y - cy)
                if r < d <= r + 14 and cv.inside(x, y):
                    lvl = (1 - (d - r) / 14) ** 1.3
                    if lvl > 0.1:
                        cv.px(x, y, mix(COLOR_INV.get(cv.get(x, y), "clear"),
                                        "honey" if lvl > 0.55 else "copper", lvl * 0.9, x, y))
        for y in range(cy - r, cy + r + 1):
            for x in range(cx - r, cx + r + 1):
                d = math.hypot(x - cx, y - cy) / r
                if d <= 1:
                    cv.px(x, y, "white" if d < 0.45 else "cream" if d < 0.8 else "peach")
        pad = 15
    elif kind == "ringed":
        rings = []
        for y in range(cy - r - 4, cy + r + 5):                       # anel de trás (atrás do planeta)
            for x in range(cx - int(r * 1.9), cx + int(r * 1.9) + 1):
                e = ((x - cx) / (r * 1.85)) ** 2 + ((y - cy - (x - cx) * 0.18) / (r * 0.42)) ** 2
                if 0.62 < e <= 1.0:
                    rings.append((x, y, e))
        for x, y, e in rings:
            if y < cy - (x - cx) * -0.18 * 0:                         # metade de cima fica atrás
                cv.px(x, y, "lichen" if e < 0.8 else "sage" if e < 0.9 else "deep_sage")
        bands_ramp = [["mauve", "rosewood", "sand", "cream"], ["umber", "mauve", "rosewood", "sand"]]
        for y in range(cy - r, cy + r + 1):
            for x in range(cx - r, cx + r + 1):
                dx, dy = (x - cx) / r, (y - cy) / r
                if dx * dx + dy * dy > 1:
                    continue
                dz = math.sqrt(max(0.0, 1 - dx * dx - dy * dy))
                light = -0.6 * dx - 0.55 * dy + 0.58 * dz
                band = bands_ramp[int((dy + 1) * 4.5 + 0.6 * math.sin(dx * 3)) % 2]
                i = max(0, min(3, int((light + 0.35) / 1.25 * 4)))
                cv.px(x, y, band[i] if light > -0.3 else "deep_sage")
        for x, y, e in rings:                                         # metade da frente passa na frente
            if y >= cy + (x - cx) * 0.18 * 0 and not (abs(x - cx) < r * 0.98 and y < cy):
                cv.px(x, y, "bone" if e < 0.72 else "lichen" if e < 0.86 else "sage")
        r = int(r * 1.9)
        pad = 2
    else:                                                             # lua pálida com halo
        sphere(cv, cx, cy, r, ["indigo", "blue", "sky", "pale_sky", "white"], halo="blue")
        pad = 11
    return (cx - r - pad, cy - r - pad - (10 if kind == "ringed" else 0),
            2 * (r + pad) + 1, 2 * (r + pad) + 1 + (20 if kind == "ringed" else 0))


COLOR_INV = {}


# ------------------------------------------------------------------ planície e terreno
def plain(cv: Canvas, th: dict, top: int) -> None:
    near_c, far_c, streaks, horizon = th["plain"]
    rng = random.Random(21)
    for y in range(top, cv.h):
        f = (y - top) / (H - top)
        for x in range(W):
            cv.px(x, y, mix(near_c, far_c, min(1, f * 2.2), x, y) if f < 0.5 else far_c)
    for _ in range(320):
        y = top + int(rng.random() ** 1.5 * (H - top))
        x, ln = rng.randrange(W), rng.randint(4, 26)
        near = (y - top) / (H - top)
        c = streaks[0] if near < 0.25 else streaks[1] if near < 0.6 else streaks[2]
        for i in range(ln):
            cv.px((x + i) % W, y, c)
    for x in range(W):
        cv.px(x, top, horizon[0] if ms.pnoise(x, 3) > 0.1 else horizon[1])


def ground_color(th: dict, face: str, k: int, x: int, y: int):
    rim = th["rim"][face]
    body1, lit_mid, body2, deep = th["body"]
    if k < 3:
        return rim[k]
    if k < 14:
        return mix(rim[2] if face != "shade" else body1, lit_mid if face == "lit" else body1, (k - 3) / 11, x, y)
    if k < 40:
        return mix(body1, body2, (k - 14) / 26, x, y)
    return mix(body2, deep, min(1, (k - 40) / 40), x, y)


def strip(th: dict, face: str, seed: int) -> Canvas:
    rng = random.Random(seed)
    cv = Canvas(STRIP_W, STRIP_D)
    for x in range(STRIP_W):
        for k in range(STRIP_D):
            cv.px(x, k, ground_color(th, face, k, x, k))
    lights, darks = th["estria"]
    for _ in range(56):
        x, k, ln = rng.randrange(STRIP_W), int(rng.random() ** 1.8 * 70) + 4, rng.randint(3, 18)
        li = 0 if k < 12 else 1 if k < 30 else 2
        for i in range(ln):
            cv.px((x + i) % STRIP_W, k, lights[li])
            if rng.random() < 0.5:
                cv.px((x + i) % STRIP_W, k + 1, darks[li])
    dl, dd = th["estria_deep"]
    for _ in range(70):
        x, k, ln = rng.randrange(STRIP_W), rng.randint(74, STRIP_D - 12), rng.randint(4, 22)
        light = dl[0] if k < 110 else dl[1] if k < 150 else dl[2]
        dark = dd[0] if k < 150 else dd[1]
        for i in range(ln):
            cv.px((x + i) % STRIP_W, k, light)
            if rng.random() < 0.5:
                cv.px((x + i) % STRIP_W, k + 1, dark)
    edge, inner, lit, lit2 = th["crater"]
    if face != "shade":
        for x, w in ((18, 9), (83, 7)):
            y = rng.randint(5, 10)
            for i in range(w):
                e = i in (0, w - 1)
                cv.px(x + i, y, edge if e else inner)
                if not e:
                    cv.px(x + i, y + 1, inner if 1 < i < w - 2 else edge)
                    if 1 < i < w - 2:
                        cv.px(x + i, y + 2, lit if i < w * 0.7 else lit2)
    return cv


def rock(cv: Canvas, th: dict, x0: int, base_y: int, w: int, h: int) -> None:
    hi, hi2, mid, low, dark, shadow = th["rock"]
    for j in range(h):
        y = base_y - h + 1 + j
        f = j / max(h - 1, 1)
        inset = round((1 - f) ** 1.6 * w * 0.35) if j < h - 1 else 0
        a, b = x0 + inset + (1 if j == 0 else 0), x0 + w - 1 - inset // 2
        for x in range(a, b + 1):
            t = (x - a) / max(b - a, 1)
            if j == 0 or (t < 0.35 and f < 0.5):
                c = hi if t < 0.5 else hi2
            elif t < 0.55 and f < 0.8:
                c = hi2 if f < 0.4 else mid
            elif t < 0.8:
                c = mid if f < 0.6 else low
            else:
                c = low if f < 0.5 else dark
            cv.px(x, y, c)
    for x in range(x0 + w // 3, x0 + w + 2):
        cv.px(x, base_y + 1, shadow)


def rocks_atlas(th: dict) -> Canvas:
    cw, ch = ROCK_CELL
    cv = Canvas(cw * len(ROCK_SIZES), ch)
    for i, (w, h) in enumerate(ROCK_SIZES):
        rock(cv, th, i * cw + (cw - w) // 2 - 1, 6, w, h)
    return cv


# ------------------------------------------------------------------ montagem
def layers(pid: str) -> tuple:
    th = THEMES[pid]
    global COLOR_INV
    COLOR_INV = {resolve(n): n for n in COLOR_NAMES}
    L = {}
    c = Canvas(W, H); sky(c, th); L["sky"] = c
    c = Canvas(W, H); box = sky_object(c, th); L["planet"] = c.crop(*box); L["planet_pos"] = box[:2]
    fcols, fhaze, fh, fn, fseed = th["far"]
    c = Canvas(W, HORIZON + 1); mountains(c, fseed, HORIZON, fn, fh, fcols, gullies=0, haze=fhaze); L["far"] = c
    mcols, mhaze, mh, mn, mseed, mg = th["mid"]
    c = Canvas(W, ms.MID_BASE + 1); mountains(c, mseed, ms.MID_BASE, mn, mh, mcols, gullies=mg, haze=mhaze)
    L["mid"] = c
    c = Canvas(W, H + 160); plain(c, th, ms.PLAIN_TOP); L["plain"] = c.crop(0, ms.PLAIN_TOP, W, c.h - ms.PLAIN_TOP)
    for i, face in enumerate(("lit", "flat", "shade")):
        L[face] = strip(th, face, 61 + i)
    L["rocks"] = rocks_atlas(th)
    return th, L


def compose(L: dict, with_target=True) -> Canvas:
    """Cena como no jogo (a partir das camadas), com lander e plataforma alvo, para revisar contra a Lua."""
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
            cv.px(x, y, L[faces[seg]].get(x % STRIP_W, k) if k < STRIP_D else L["lit"].get(0, STRIP_D - 1))
    rng = random.Random(31)
    cw, ch = ROCK_CELL
    for _ in range(26):
        x = rng.randrange(8, W - 8)
        if pad[0] - 12 < x < pad[0] + pad[1] + 12:
            continue
        i = rng.randrange(len(ROCK_SIZES))
        cv.stamp(L["rocks"].crop(i * cw, 0, cw, ch), x - cw // 2, ridge_y(pts, x) + rng.randint(0, 2) - 6)
    y = ridge_y(pts, pad[0] + pad[1] // 2)
    if with_target:
        beam = Canvas.from_image("assets/sprites/target_beam.png").crop(0, 0, 64, 84)
        padspr = Canvas.from_image("assets/sprites/landing_pad.png")
        cv.stamp(beam, pad[0] + 32 - 32, y - 84)
        cv.stamp(padspr.crop(0, 28, 80, 28), pad[0] - 8, y - 10)
    lander = Canvas.from_image("assets/sprites/lander.png").crop(0, 0, 32, 32)
    cv.stamp(lander, pad[0] + pad[1] // 2 - 16, y - 25)
    return cv


def export(pid: str, th: dict, L: dict) -> None:
    P = PATHS[pid]
    for k in ("sky", "planet", "far", "mid", "plain", "rocks"):
        L[k].save(P[k])
    for k in ("lit", "flat", "shade"):
        L[k].save(P[k], tiled=True)
    meta = {
        "notes": "Gerado por art/src/bg/planet_scenes.py (pixel-art). Mesmo contrato de luna_layers.json.",
        "horizon": HORIZON, "planet_pos": list(L["planet_pos"]), "far_y": 0, "mid_y": 0, "plain_y": ms.PLAIN_TOP,
        "deep_color": th["deep_hex"], "strip_depth": STRIP_D, "strip_width": STRIP_W, "face_slope": FACE_SLOPE,
        "rock_cell": list(ROCK_CELL), "rock_base_row": 6, "rock_count": len(ROCK_SIZES),
        "rock_widths": [w for w, _ in ROCK_SIZES],
    }
    with open(P["meta"], "w") as f:
        json.dump(meta, f, indent=2)


if __name__ == "__main__":
    pids = [a for a in sys.argv[1:] if a in THEMES] or list(THEMES)
    luna = ms.ingame_preview(ms.load_layers(), with_lander=True)
    scenes = [("luna (aprovada)", luna)]
    for pid in pids:
        th, L = layers(pid)
        sc = compose(L)
        print(pid, "cores:", len(sc.colors_used()), [L[f].lint(wrap=True)[:0] for f in ("lit",)])
        sc.save(f"art/previews/{pid}_scene.png", preview=False)
        sc.preview(f"art/previews/{pid}_scene_2x.png", scale=2, grid=False, show_1x=False)
        scenes.append((pid, sc))
        if "--export" in sys.argv:
            export(pid, th, L)
    # comparação lado a lado com a Lua aprovada (regra: comparar antes de mostrar)
    from PIL import Image, ImageDraw
    sheet = Image.new("RGB", (W * 2 + 8, (H + 20) * ((len(scenes) + 1) // 2)), (20, 16, 24))
    d = ImageDraw.Draw(sheet)
    for i, (name, sc) in enumerate(scenes):
        sc.save("/tmp/_sc.png", preview=False)
        im = Image.open("/tmp/_sc.png").convert("RGB")
        x0, y0 = (i % 2) * (W + 8), (i // 2) * (H + 20)
        sheet.paste(im, (x0, y0 + 20))
        d.text((x0 + 6, y0 + 4), name, fill=(230, 230, 230))
    sheet.save("art/previews/planet_scenes_compare.png")
    print("art/previews/planet_scenes_compare.png")
