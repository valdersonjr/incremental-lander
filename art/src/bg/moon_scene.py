"""Cena da Lua rica em detalhe (pedido do usuário após reprovar os estilos minimalistas).

Referências do usuário: paisagens em camadas (montanha facetada, céu em faixas roxo/magenta, lua com halo).
Regras (patterns/moon-scene.md): perspectiva atmosférica (perto = saturado e contrastado; longe = matiz do céu,
pouco contraste, névoa na base), faces luz/sombra com luz de cima-esquerda, céu em faixas com dither, textura em
estrias horizontais no chão, pedregulhos com luz.
Camadas (cada uma vira um asset de parallax, laço horizontal em W):
  sky (faixas + estrelas) · planet (Terra + halo) · far (montanhas distantes) · mid (montanhas facetadas)
  · plain (chão distante com estrias) · ground (terreno jogável, gerado a partir do contorno do jogo)
Rodar da raiz: python3 art/src/bg/moon_scene.py  -> art/previews/moon_scene_rich.png (+ _2x)
"""
import json
import math
import random
import sys

sys.path.insert(0, ".claude/skills/pixel-art/scripts")
sys.path.insert(0, "art/src/terrain")
from pixelart import *
from moon import profile, ridge_y

W, H = 640, 360
HORIZON = 262
BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def mix(a, b, level: float, x: int, y: int):
    return b if level * 16 > BAYER[y % 4][x % 4] + 0.5 else a


def pnoise(x: float, seed: int, period: int = W, octaves=(1, 3, 7, 13), amp=(1, .5, .3, .15)) -> float:
    """Ruído 1D periódico em 'period' (laço de parallax sem costura), -1..1 aprox."""
    r = random.Random(seed)
    ph = [r.random() * 6.2832 for _ in octaves]
    s = sum(a * math.sin(6.2832 * o * x / period + p) for o, a, p in zip(octaves, amp, ph))
    return s / sum(amp)


# ------------------------------------------------------------------ céu
def sky(cv: Canvas) -> None:
    bands = [(0, "ink"), (95, "navy"), (170, "plum_dark"), (212, "plum"), (244, "berry"), (262, "rose")]
    for y in range(H):
        for x in range(W):
            c = bands[0][1]
            for (y0, c0), (y1, c1) in zip(bands, bands[1:]):
                if y < y0:
                    break
                c = c0
                # transição pontilhada de ~10 px antes do próximo stop (faixa, não degradê liso)
                tw = min(22, (y1 - y0) // 2)
                if y1 - tw <= y < y1:
                    c = mix(c0, c1, (y - (y1 - tw)) / tw, x, y)
                elif y >= y1:
                    c = c1
            cv.px(x, y, c)
    rng = random.Random(11)
    for _ in range(420):                       # estrelas: densidade cai perto do horizonte
        x, y = rng.randrange(W), int(rng.random() ** 1.6 * 230)
        c = rng.choices(["lilac_grey", "mist", "white", "lavender", "pale_sky"], [5, 3, 1.2, 1, 1])[0]
        cv.px(x, y, c)
    for x, y in ((60, 40), (205, 22), (330, 78), (560, 30), (610, 120), (120, 150)):   # cintilantes
        cv.px(x, y, "white")
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            cv.px(x + dx, y + dy, "mist")
        for dx, dy in ((2, 0), (-2, 0), (0, 2), (0, -2)):
            cv.px(x + dx, y + dy, "lilac_grey")


# ------------------------------------------------------------------ planeta (Terra) com halo
def planet(cv: Canvas, cx: int = 478, cy: int = 92, r: int = 34) -> None:
    for y in range(cy - r - 12, cy + r + 13):          # halo: anéis pontilhados que somem
        for x in range(cx - r - 12, cx + r + 13):
            d = math.hypot(x - cx, y - cy)
            if r < d <= r + 12:
                lvl = 1 - (d - r) / 12
                if cv.inside(x, y) and lvl > 0.15:
                    # sobre o céu (prévia) mistura com a cor de baixo; na camada exportada, com transparência
                    base = COLOR_NAMES_INV.get(cv.get(x, y), "clear")
                    cv.px(x, y, mix(base, "indigo" if lvl < 0.6 else "blue", lvl * 0.9, x, y))
    for y in range(cy - r, cy + r + 1):
        for x in range(cx - r, cx + r + 1):
            dx, dy = (x - cx) / r, (y - cy) / r
            if dx * dx + dy * dy > 1:
                continue
            dz = math.sqrt(1 - dx * dx - dy * dy)
            light = -0.6 * dx - 0.55 * dy + 0.58 * dz        # luz de cima-esquerda
            # continentes e nuvens: ruído na superfície da esfera
            u, v = math.atan2(dx, dz) * 3.1, dy * 3.3
            land = math.sin(u * 1.7 + 0.4) + math.sin(v * 2.1 + u * 0.8) + 0.6 * math.sin(u * 3.7 - v * 2.9)
            cloud = math.sin(u * 2.3 + v * 5.1 + 1.3) + 0.7 * math.sin(v * 7.7 - u * 1.1)
            if cloud > 1.25:
                ramp = ["navy", "lilac_grey", "mist", "white"]
            elif land > 0.9:
                ramp = ["pine", "green", "emerald", "leaf"]
            else:
                ramp = ["navy", "blue", "sky", "pale_sky"]
            idx = 0 if light < 0.02 else 1 if light < 0.35 else 2 if light < 0.72 else 3
            c = ramp[idx]
            if idx == 0 and light > -0.08:              # terminador pontilhado
                c = mix(ramp[0], ramp[1], 0.5, x, y)
            if light < -0.25:
                c = "navy" if light > -0.5 else "ink"
            cv.px(x, y, c)
    # borda iluminada fina no lado da luz
    for a in range(0, 360, 2):
        t = math.radians(a)
        if 150 < a < 290:
            x, y = round(cx + r * math.cos(t)), round(cy + r * math.sin(t))
            cv.px(x, y, "pale_sky")


COLOR_NAMES_INV = {}


# ------------------------------------------------------------------ montanhas facetadas
def mountains(cv: Canvas, seed: int, base: int, n: int, hrange, cols: dict, gullies: int, haze=None) -> None:
    """cols: shadow, mid, lit, ridge. Luz de cima-esquerda: face esquerda de cada pico iluminada."""
    rng = random.Random(seed)
    peaks = []
    for i in range(n):
        px = (i + rng.uniform(-0.3, 0.3)) * W / n
        peaks.append((px, rng.uniform(*hrange), rng.uniform(0.55, 1.0), rng.uniform(0.6, 1.1), seed * 10 + i))
    owner = {}
    for x in range(W):
        best = None
        for i, (px, h, sl, sr, s) in enumerate(peaks):
            dx = (x - px + W / 2) % W - W / 2
            top = base - h + abs(dx) * (sl if dx < 0 else sr) + 7 * pnoise(x, s, W, (7, 17, 41, 83), (1, .6, .4, .25))
            if best is None or top < best[0]:
                best = (top, i, dx)
        top, i, dx = best
        t = int(round(top))
        owner[x] = (t, i)
        px, h, sl, sr, s = peaks[i]
        for y in range(max(t, 0), base + 1):
            depth = y - t
            # aresta do facetamento: desce do pico com deriva (linha de crista em zigue-zague)
            crest = pnoise(y * 5, s + 5, 997, (1, 3, 7), (1, .6, .4)) * 9 + (y - (base - h)) * 0.3
            lit = dx < crest
            if depth == 0:
                c = cols["ridge"] if lit else cols["mid"]
            elif lit:
                hf = (y - (base - h)) / max(h, 1)         # 0 no pico, 1 na base
                c = cols["ridge"] if depth <= 1 else mix(cols["lit"], cols["mid"], (hf - 0.25) / 0.5, x, y) \
                    if hf > 0.25 else cols["lit"]
                if hf > 0.75:
                    c = cols["mid"]
                if dx > crest - 2:
                    c = cols["mid"]                     # meio-tom junto à aresta (AA interno)
            else:
                c = cols["shadow"]
            if haze and y > base - 14:                  # névoa na base (perspectiva atmosférica)
                c = mix(c, haze, (y - (base - 14)) / 14, x, y)
            cv.px(x, y, c)
    # ravinas/cristas secundárias: na face iluminada, sulcos escuros; na sombra, cristas claras
    for g in range(gullies):
        x0 = rng.randrange(W)
        t, i = owner[x0]
        lit_side = rng.random() < 0.55
        x, y = x0, t + 2
        length = rng.randint(10, 40)
        for k in range(length):
            if y >= base - 6 or cv.get(x % W, y) is None:
                break
            cur = cv.get(x % W, y)
            if lit_side and cur in (resolve(cols["lit"]), resolve(cols["ridge"])):
                cv.px(x % W, y, cols["mid"])
                if cv.get((x + 1) % W, y) == resolve(cols["lit"]):
                    cv.px((x + 1) % W, y, cols["ridge"])      # borda iluminada da ravina
            elif not lit_side and cur == resolve(cols["shadow"]):
                cv.px(x % W, y, cols["mid"])
                if k % 3:
                    cv.px((x - 1) % W, y, cols["mid"])
            y += 1
            x += (-1 if lit_side else 1) if rng.random() < 0.7 else 0


# ------------------------------------------------------------------ chão distante (planície com estrias)
def plain(cv: Canvas, top: int = HORIZON) -> None:
    rng = random.Random(21)
    for y in range(top, cv.h):          # cv.h > H na camada exportada: sobra navy para o parallax vertical
        f = (y - top) / (H - top)
        for x in range(W):
            cv.px(x, y, mix("plum", "navy", min(1, f * 2.2), x, y) if f < 0.5 else "navy")
    for _ in range(320):                        # estrias horizontais (mais finas e claras perto do horizonte)
        y = top + int(rng.random() ** 1.5 * (H - top))
        x, ln = rng.randrange(W), rng.randint(4, 26)
        near = (y - top) / (H - top)
        c = "purple" if near < 0.25 else "plum" if near < 0.6 else "indigo"
        for i in range(ln):
            cv.px((x + i) % W, y, c)
    for x in range(W):
        cv.px(x, top, "violet" if pnoise(x, 3) > 0.1 else "purple")


# ------------------------------------------------------------------ terreno jogável (primeiro plano)
def ground(cv: Canvas, pts: list, pad: tuple) -> None:
    rng = random.Random(31)
    for x in range(W):
        r = ridge_y(pts, x)
        s = ridge_y(pts, x + 3) - ridge_y(pts, x - 3)     # >0 desce p/ direita (sombra); <0 sobe (luz)
        face = "lit" if s < -1 else "shade" if s > 1 else "flat"
        rim = {"lit": ["white", "mist", "steel"], "flat": ["mist", "steel", "lilac_grey"],
               "shade": ["steel", "lilac_grey", "slate"]}[face]
        for y in range(r, H):
            k = y - r
            if k < 3:
                c = rim[k]
            elif k < 14:
                c = mix(rim[2] if face != "shade" else "slate", "lilac_grey" if face == "lit" else "slate",
                        (k - 3) / 11, x, y)
            elif k < 40:
                c = mix("slate", "shadow", (k - 14) / 26, x, y)
            else:
                c = mix("shadow", "plum_dark", min(1, (k - 40) / 40), x, y)
            cv.px(x, y, c)
    # estrias horizontais no corpo (camadas de regolito): claras em cima, escuras embaixo
    for _ in range(260):
        x = rng.randrange(W)
        r = ridge_y(pts, x)
        k = int(rng.random() ** 1.8 * 70) + 4
        y, ln = r + k, rng.randint(3, 18)
        light = "steel" if k < 12 else "lilac_grey" if k < 30 else "slate"
        dark = "slate" if k < 12 else "shadow" if k < 30 else "ink"
        for i in range(ln):
            xx = x + i
            if xx >= W or ridge_y(pts, xx) + 3 > y:
                break
            cv.px(xx, y, light)
            if rng.random() < 0.5:
                cv.px(xx, y + 1, dark)
    # pedregulhos com luz de cima-esquerda (fora da plataforma)
    for _ in range(26):
        x = rng.randrange(8, W - 8)
        if pad[0] - 12 < x < pad[0] + pad[1] + 12:
            continue
        w, h = rng.choice([(4, 3), (6, 4), (8, 5), (11, 6), (5, 3)])
        base_y = ridge_y(pts, x + w // 2) + rng.randint(0, 2)
        rock(cv, x, base_y, w, h, rng)
    # crateras na face plana/iluminada perto da borda
    for _ in range(7):
        x = rng.randrange(10, W - 20)
        if pad[0] - 20 < x < pad[0] + pad[1] + 10:
            continue
        w = rng.choice([7, 9, 12])
        y = ridge_y(pts, x) + rng.randint(5, 12)
        for i in range(w):
            edge = i in (0, w - 1)
            cv.px(x + i, y, "slate" if edge else "shadow")
            if not edge:
                cv.px(x + i, y + 1, "shadow" if 1 < i < w - 2 else "slate")
                if 1 < i < w - 2:
                    cv.px(x + i, y + 2, "steel" if i < w * 0.7 else "lilac_grey")


def rock(cv: Canvas, x0: int, base_y: int, w: int, h: int, rng: random.Random) -> None:
    for j in range(h):
        y = base_y - h + 1 + j
        f = j / max(h - 1, 1)
        inset = round((1 - f) ** 1.6 * w * 0.35) if j < h - 1 else 0
        a, b = x0 + inset + (1 if j == 0 else 0), x0 + w - 1 - inset // 2
        for x in range(a, b + 1):
            t = (x - a) / max(b - a, 1)
            if j == 0 or (t < 0.35 and f < 0.5):
                c = "mist" if t < 0.5 else "steel"
            elif t < 0.55 and f < 0.8:
                c = "steel" if f < 0.4 else "lilac_grey"
            elif t < 0.8:
                c = "lilac_grey" if f < 0.6 else "slate"
            else:
                c = "slate" if f < 0.5 else "shadow"
            cv.px(x, y, c)
    for x in range(x0 + w // 3, x0 + w + 2):          # sombra projetada para a direita
        cv.px(x, base_y + 1, "shadow")


def build() -> Canvas:
    cv = Canvas(W, H, "ink")
    sky(cv)
    global COLOR_NAMES_INV
    COLOR_NAMES_INV = {resolve(n): n for n in COLOR_NAMES}
    planet(cv)
    mountains(cv, 3, HORIZON, 9, (70, 125), {"shadow": "plum", "mid": "plum", "lit": "purple", "ridge": "purple"},
              gullies=0, haze="berry")
    mountains(cv, 7, HORIZON + 4, 7, (30, 100),
              {"shadow": "navy", "mid": "indigo", "lit": "purple", "ridge": "violet"}, gullies=90, haze="plum")
    plain(cv, HORIZON + 5)
    pad = (300, 64)
    pts = profile(W, seed=7, base=292, amp=60, pad=pad)
    ground(cv, pts, pad)
    lander = Canvas.from_image("assets/sprites/lander.png").crop(0, 0, 32, 32)
    cv.stamp(lander, pad[0] + pad[1] // 2 - 16, ridge_y(pts, pad[0] + pad[1] // 2) - 25)
    return cv


# ================================================================== EXPORT (aprovado pelo usuário em 2026-09-30)
# Camadas separadas para o Godot. Contrato em assets/bg/luna_layers.json (gerado aqui).
PLANET = (478, 92, 34)                   # cx, cy, r (halo +12)
MID_BASE = HORIZON + 4
PLAIN_TOP = HORIZON + 5
STRIP_W, STRIP_D = 128, 176              # faixa do terreno: laço de 128 px, abaixo de 176 px é plum_dark sólido
# (no jogo a câmera centraliza a nave: o terreno ocupa metade da tela -> faixa funda com estrias até escurecer)
FACE_SLOPE = 0.15                        # |inclinação| do segmento acima disso = encosta (luz/sombra)
ROCK_CELL = (16, 8)                      # célula do atlas de pedregulhos; base da pedra na linha 6
ROCK_SIZES = [(4, 3), (5, 3), (6, 4), (8, 5), (11, 6), (7, 4)]
RIM = {"lit": ["white", "mist", "steel"], "flat": ["mist", "steel", "lilac_grey"],
       "shade": ["steel", "lilac_grey", "slate"]}


def ground_color(face: str, k: int, x: int, y: int):
    """Cor do terreno a k px abaixo da borda (mesma regra da cena aprovada)."""
    rim = RIM[face]
    if k < 3:
        return rim[k]
    if k < 14:
        return mix(rim[2] if face != "shade" else "slate", "lilac_grey" if face == "lit" else "slate",
                   (k - 3) / 11, x, y)
    if k < 40:
        return mix("slate", "shadow", (k - 14) / 26, x, y)
    return mix("shadow", "plum_dark", min(1, (k - 40) / 40), x, y)


def strip(face: str, seed: int) -> Canvas:
    """Faixa do terreno (aplicada cisalhada, coluna a coluna, abaixo do contorno). Laço horizontal em STRIP_W."""
    rng = random.Random(seed)
    cv = Canvas(STRIP_W, STRIP_D)
    for x in range(STRIP_W):
        for k in range(STRIP_D):
            cv.px(x, k, ground_color(face, k, x, k))
    for _ in range(56):                                    # estrias (camadas de regolito) — parte aprovada
        x, k, ln = rng.randrange(STRIP_W), int(rng.random() ** 1.8 * 70) + 4, rng.randint(3, 18)
        light = "steel" if k < 12 else "lilac_grey" if k < 30 else "slate"
        dark = "slate" if k < 12 else "shadow" if k < 30 else "ink"
        for i in range(ln):
            cv.px((x + i) % STRIP_W, k, light)
            if rng.random() < 0.5:
                cv.px((x + i) % STRIP_W, k + 1, dark)
    for _ in range(70):                                    # estrias fundas: escurecem até sumir no plum_dark
        x, k, ln = rng.randrange(STRIP_W), rng.randint(74, STRIP_D - 12), rng.randint(4, 22)
        light = "slate" if k < 110 else "shadow" if k < 150 else "plum_dark"
        dark = "ink"
        if k >= 150:
            light, dark = "shadow", "plum_dark"
        for i in range(ln):
            cv.px((x + i) % STRIP_W, k, light)
            if rng.random() < 0.5:
                cv.px((x + i) % STRIP_W, k + 1, dark)
    if face != "shade":                                    # crateras pequenas perto da borda
        for x, w in ((18, 9), (83, 7)):
            y = rng.randint(5, 10)
            for i in range(w):
                edge = i in (0, w - 1)
                cv.px(x + i, y, "slate" if edge else "shadow")
                if not edge:
                    cv.px(x + i, y + 1, "shadow" if 1 < i < w - 2 else "slate")
                    if 1 < i < w - 2:
                        cv.px(x + i, y + 2, "steel" if i < w * 0.7 else "lilac_grey")
    return cv


def rocks_atlas() -> Canvas:
    rng = random.Random(51)
    cw, ch = ROCK_CELL
    cv = Canvas(cw * len(ROCK_SIZES), ch)
    for i, (w, h) in enumerate(ROCK_SIZES):
        rock(cv, i * cw + (cw - w) // 2 - 1, 6, w, h, rng)
    return cv


def segment_faces(pts: list) -> list:
    faces = []
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        s = (y1 - y0) / (x1 - x0)
        faces.append("lit" if s < -FACE_SLOPE else "shade" if s > FACE_SLOPE else "flat")
    return faces


def export() -> dict:
    global COLOR_NAMES_INV
    COLOR_NAMES_INV = {resolve(n): n for n in COLOR_NAMES}
    out = {}
    c = Canvas(W, H); sky(c); c.save("assets/bg/luna_sky.png"); out["sky"] = c
    c = Canvas(W, H); planet(c, *PLANET)
    cx, cy, r = PLANET
    c = c.crop(cx - r - 12, cy - r - 12, 2 * r + 25, 2 * r + 25); c.save("assets/bg/luna_planet.png"); out["planet"] = c
    c = Canvas(W, HORIZON + 1)
    mountains(c, 3, HORIZON, 9, (70, 125), {"shadow": "plum", "mid": "plum", "lit": "purple", "ridge": "purple"},
              gullies=0, haze="berry")
    c.save("assets/bg/luna_far.png"); out["far"] = c
    c = Canvas(W, MID_BASE + 1)
    mountains(c, 7, MID_BASE, 7, (30, 100), {"shadow": "navy", "mid": "indigo", "lit": "purple", "ridge": "violet"},
              gullies=90, haze="plum")
    c.save("assets/bg/luna_mid.png"); out["mid"] = c
    c = Canvas(W, H + 160); plain(c, PLAIN_TOP)
    c = c.crop(0, PLAIN_TOP, W, c.h - PLAIN_TOP); c.save("assets/bg/luna_plain.png"); out["plain"] = c
    out["lit"] = strip("lit", 61); out["lit"].save("assets/tiles/luna_ground_lit.png", tiled=True)
    out["flat"] = strip("flat", 62); out["flat"].save("assets/tiles/luna_ground_flat.png", tiled=True)
    out["shade"] = strip("shade", 63); out["shade"].save("assets/tiles/luna_ground_shade.png", tiled=True)
    out["rocks"] = rocks_atlas(); out["rocks"].save("assets/sprites/luna_rocks.png")
    for k in ("lit", "flat", "shade"):
        print(k, out[k].lint(wrap=True))
    meta = {
        "notes": "Gerado por art/src/bg/moon_scene.py (pixel-art). Posições em px na tela de 640x360 da cena aprovada.",
        "horizon": HORIZON, "planet_pos": [cx - r - 12, cy - r - 12], "far_y": 0, "mid_y": 0, "plain_y": PLAIN_TOP,
        "deep_color": "#45293f", "strip_depth": STRIP_D, "strip_width": STRIP_W, "face_slope": FACE_SLOPE,
        "rock_cell": list(ROCK_CELL), "rock_base_row": 6, "rock_count": len(ROCK_SIZES),
        "rock_widths": [w for w, _ in ROCK_SIZES],
    }
    with open("assets/bg/luna_layers.json", "w") as f:
        json.dump(meta, f, indent=2)
    return out


def ingame_preview(L: dict, with_lander: bool = True) -> Canvas:
    """Recompõe a cena A PARTIR DOS ASSETS, como o Godot fará (prova de que o export = cena aprovada)."""
    cv = Canvas(W, H)
    cv.stamp(L["sky"]); cv.stamp(L["planet"], PLANET[0] - PLANET[2] - 12, PLANET[1] - PLANET[2] - 12)
    cv.stamp(L["far"]); cv.stamp(L["mid"]); cv.stamp(L["plain"], 0, PLAIN_TOP)
    pad = (300, 64)
    pts = profile(W, seed=7, base=292, amp=60, pad=pad)
    faces = segment_faces(pts)
    for x in range(W):
        r = ridge_y(pts, x)
        seg = min(sum(1 for p in pts[1:] if p[0] <= x), len(faces) - 1)
        for y in range(r, H):
            k = y - r
            cv.px(x, y, L[faces[seg]].get(x % STRIP_W, k) if k < STRIP_D else "plum_dark")
    rng = random.Random(31)
    cw, ch = ROCK_CELL
    for _ in range(26):
        x = rng.randrange(8, W - 8)
        if pad[0] - 12 < x < pad[0] + pad[1] + 12:
            continue
        i = rng.randrange(len(ROCK_SIZES))
        cv.stamp(L["rocks"].crop(i * cw, 0, cw, ch), x - cw // 2, ridge_y(pts, x) + rng.randint(0, 2) - 6)
    if with_lander:
        lander = Canvas.from_image("assets/sprites/lander.png").crop(0, 0, 32, 32)
        cv.stamp(lander, pad[0] + pad[1] // 2 - 16, ridge_y(pts, pad[0] + pad[1] // 2) - 25)
    return cv


def load_layers() -> dict:
    """Camadas exportadas (para prévias de outros assets sobre a cena aprovada)."""
    names = {"sky": "assets/bg/luna_sky.png", "planet": "assets/bg/luna_planet.png", "far": "assets/bg/luna_far.png",
             "mid": "assets/bg/luna_mid.png", "plain": "assets/bg/luna_plain.png",
             "lit": "assets/tiles/luna_ground_lit.png", "flat": "assets/tiles/luna_ground_flat.png",
             "shade": "assets/tiles/luna_ground_shade.png", "rocks": "assets/sprites/luna_rocks.png"}
    return {k: Canvas.from_image(v) for k, v in names.items()}


PREVIEW_PAD = (300, 64)


if __name__ == "__main__":
    import json
    cv = build()
    print("cores:", len(cv.colors_used()))
    cv.save("art/previews/moon_scene_rich.png", preview=False)
    cv.preview("art/previews/moon_scene_rich_2x.png", scale=2, grid=False, show_1x=False)
    if "--export" in sys.argv:
        ig = ingame_preview(export())
        ig.save("art/previews/moon_ingame.png", preview=False)
        ig.preview("art/previews/moon_ingame_2x.png", scale=2, grid=False, show_1x=False)
