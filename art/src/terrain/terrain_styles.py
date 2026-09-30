"""Propostas de ESTILO de terreno (a 1ª versão em moon.py foi reprovada: "muito feia").

Mesmo relevo, mesmo lander futurista, 5 direções bem diferentes -> art/previews/terrain_styles_compare.png.
O usuário escolhe uma; a escolhida vira o terreno (moon.py) e as outras ficam aqui como alternativas.
Rodar da raiz: python3 art/src/terrain/terrain_styles.py
"""
import math
import random
import sys

sys.path.insert(0, ".claude/skills/pixel-art/scripts")
sys.path.insert(0, "art/src/terrain")
from pixelart import *
from moon import profile, ridge_y

W, H = 320, 180
PAD_X, PAD_W = 128, 64
BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def mix(a, b, level: float, x: int, y: int):
    """Dither ordenado (bayer4) entre a e b; level 0..1 = proporção de b."""
    return b if level * 16 > BAYER[y % 4][x % 4] + 0.5 else a


def ramp_at(stops: list, k: float, x: int, y: int):
    """stops = [(prof, cor), ...] crescente; entre dois stops faz dither bayer (gradiente de 5 estágios)."""
    for (k0, c0), (k1, c1) in zip(stops, stops[1:]):
        if k < k1:
            return mix(c0, c1, (k - k0) / (k1 - k0), x, y) if k >= k0 else c0
    return stops[-1][1]


def sky(cv: Canvas, seed: int = 7, base="ink") -> None:
    reg = {(x, y) for x in range(cv.w) for y in range(cv.h)}
    cv.scatter(reg, "shadow", 0.006, seed=seed, min_dist=3)
    cv.scatter(reg, "mist", 0.0015, seed=seed + 1, min_dist=6)
    cv.scatter(reg, "white", 0.0004, seed=seed + 2, min_dist=12)


def ground(cv: Canvas, pts: list, paint) -> None:
    for x in range(cv.w):
        r = ridge_y(pts, x)
        for y in range(max(r, 0), cv.h):
            c = paint(x, y, y - r)
            if c is not None:
                cv.px(x, y, c)


def layer(cv: Canvas, seed: int, base: float, amp: float, body, rim=None, step=24) -> None:
    """Montanhas de fundo (parallax): silhueta sem textura, contraste baixo."""
    r = random.Random(seed)
    ph = [r.random() * 6.28 for _ in range(3)]
    pts = [(x, base - amp * (math.sin(x * 0.018 + ph[0]) + 0.5 * math.sin(x * 0.041 + ph[1])
                             + 0.25 * math.sin(x * 0.09 + ph[2])) / 1.75) for x in range(0, cv.w + step, step)]
    ground(cv, pts, lambda x, y, k: rim if (rim and k == 0) else body)


def lander_on_pad(cv: Canvas, pts: list) -> None:
    lander = Canvas.from_image("assets/sprites/lander.png").crop(0, 0, 32, 32)
    y = ridge_y(pts, PAD_X + PAD_W // 2)
    cv.stamp(lander, PAD_X + PAD_W // 2 - 16, y - 25)


def craters(cv: Canvas, pts: list, spots, rim, inner, lit) -> None:
    """Crateras rasas na face do terreno: bacia escura, borda de baixo iluminada (luz de cima)."""
    for cx, w, dk in spots:
        r = ridge_y(pts, cx) + dk
        for i in range(w):
            edge = i in (0, w - 1)
            cv.px(cx + i, r, rim if edge else inner)
            if not edge:
                cv.px(cx + i, r + 1, inner if 1 < i < w - 2 else rim)
                if 1 < i < w - 2:
                    cv.px(cx + i, r + 2, lit)


# --- A: Minimalista limpo ---------------------------------------------------------------------------
def style_a(pts):
    cv = Canvas(W, H, "ink"); sky(cv)
    stops = [(0, "mist"), (1, "steel"), (3, "lilac_grey"), (9, "slate"), (26, "shadow")]
    ground(cv, pts, lambda x, y, k: ramp_at(stops, k, x, y))
    return cv


# --- B: Lua fria (azulada, combina com o turquesa do lander) -----------------------------------------
def style_b(pts):
    cv = Canvas(W, H, "ink"); sky(cv)
    layer(cv, 21, 110, 30, "navy")
    stops = [(0, "pale_sky"), (1, "sky"), (2, "blue"), (6, "indigo"), (22, "navy")]
    ground(cv, pts, lambda x, y, k: ramp_at(stops, k, x, y))
    craters(cv, pts, [(40, 7, 10), (230, 9, 12), (290, 5, 8)], "indigo", "navy", "blue")
    return cv


# --- C: Lua clara (como nas fotos da Apollo: solo claro, céu preto) -----------------------------------
def style_c(pts):
    cv = Canvas(W, H, "ink"); sky(cv)
    stops = [(0, "white"), (1, "mist"), (5, "steel"), (30, "lilac_grey"), (60, "slate")]
    ground(cv, pts, lambda x, y, k: ramp_at(stops, k, x, y))
    craters(cv, pts, [(20, 9, 9), (60, 6, 16), (215, 11, 10), (262, 7, 20), (300, 6, 7)], "steel", "lilac_grey", "mist")
    return cv


# --- D: Neon vetorial (homenagem ao Lunar Lander vetorial de 1979) -----------------------------------
def style_d(pts):
    cv = Canvas(W, H, "ink"); sky(cv)

    def paint(x, y, k):
        if k == 0:
            return "aqua"
        if k == 1:
            return "teal"
        if k == 2 and x % 2 == 0:
            return "deep_teal"
        if (y % 16 == 0 or x % 16 == 0) and k > 4:
            return "navy"
        return "ink"
    ground(cv, pts, paint)
    return cv


# --- E: Camadas com profundidade (parallax + planeta no céu) -----------------------------------------
def style_e(pts):
    cv = Canvas(W, H, "ink"); sky(cv)
    cx, cy, rad = 252, 40, 20                              # planeta ao fundo: crescente (luz de cima-esquerda)
    for y in range(cy - rad, cy + rad + 1):
        for x in range(cx - rad, cx + rad + 1):
            if (x - cx) ** 2 + (y - cy) ** 2 <= rad * rad:
                lx, ly = x - (cx - 9), y - (cy - 9)          # distância ao ponto de luz
                d = math.hypot(lx, ly)
                cv.px(x, y, "pale_sky" if d < 7 else "sky" if d < 15 else "blue" if d < 23 else
                      mix("blue", "indigo", (d - 23) / 5, x, y) if d < 28 else "indigo")
    layer(cv, 31, 95, 35, "navy", rim="indigo")
    layer(cv, 41, 118, 30, "shadow", rim="slate")
    stops = [(0, "mist"), (1, "steel"), (2, "lilac_grey"), (7, "slate"), (20, "shadow")]
    ground(cv, pts, lambda x, y, k: ramp_at(stops, k, x, y))
    return cv


STYLES = [("A  Minimalista limpo", style_a), ("B  Lua fria (azul)", style_b), ("C  Lua clara (Apollo)", style_c),
          ("D  Neon vetorial", style_d), ("E  Camadas + planeta", style_e)]


if __name__ == "__main__":
    from PIL import Image, ImageDraw
    # relevo de composição (desenhado à mão, encosta máx 1.2 como no jogo): morro, plataforma, vale, pico
    pts = [(0, 118), (22, 108), (44, 114), (66, 100), (90, 108), (112, 126), (128, 132), (192, 132), (208, 142),
           (224, 158), (242, 164), (258, 150), (274, 132), (290, 114), (306, 104), (320, 110)]
    scale, cols, label = 2, 2, 22
    rows = math.ceil(len(STYLES) / cols)
    sheet = Image.new("RGB", (W * scale * cols + 8 * (cols - 1), (H * scale + label) * rows), (20, 16, 24))
    d = ImageDraw.Draw(sheet)
    for i, (name, fn) in enumerate(STYLES):
        cv = fn(pts)
        lander_on_pad(cv, pts)
        print(f"{name:24s} cores={len(cv.colors_used())}")
        png = f"art/previews/terrain_style_{name[0].lower()}.png"
        cv.save(png, preview=False)
        im = Image.open(png).convert("RGB").resize((W * scale, H * scale), Image.NEAREST)
        x0, y0 = (i % cols) * (W * scale + 8), (i // cols) * (H * scale + label)
        sheet.paste(im, (x0, y0 + label))
        d.text((x0 + 6, y0 + 5), name, fill=(230, 230, 230))
    out = "art/previews/terrain_styles_compare.png"
    sheet.save(out)
    print(out)
