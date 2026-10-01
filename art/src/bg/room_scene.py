"""Mundo 4 — QUARTO BAGUNÇADO (id `titan`, o planeta "gigante": a nave é minúscula num quarto enorme).

Exemplo do próprio usuário ("outro um quarto bagunçado"); mesmo ESTILO dos outros mundos (rico em camadas, luz de
cima-esquerda, Resurrect 64), formas de um quarto à noite. Padrão: patterns/room-scene.md.
Luz motivada: abajur na parede (poça quente com queda suave) + luar frio pela janela.
Camadas (contrato do jogo, assets/bg/titan_layers.json):
  sky    parede listrada (fixa na tela) + abajur na prateleira + pôster de foguete + rodapé; poeira flutuando (anim)
  planet janela: noite, lua, estrelas cintilando (anim), cortinas
  far    móveis enormes na penumbra: cama, estante, guarda-roupa, baú
  mid    brinquedos gigantes: livros, cubos de letras, bola, torre de bloquinhos, robô (olho piscando), giz de cera
  plain  assoalho de tábuas
  ground cobertor de tricô listrado amontoado
  props  bloquinho, giz, bolinha de gude, moeda, botão, dado, lápis, pião (girando)
Rodar da raiz: python3 art/src/bg/room_scene.py [--export]
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
import anim_util as au

P = {"sky": "assets/bg/titan_sky.png", "planet": "assets/bg/titan_planet.png", "far": "assets/bg/titan_far.png",
     "mid": "assets/bg/titan_mid.png", "plain": "assets/bg/titan_plain.png",
     "lit": "assets/tiles/titan_ground_lit.png", "flat": "assets/tiles/titan_ground_flat.png",
     "shade": "assets/tiles/titan_ground_shade.png", "props": "assets/sprites/titan_rocks.png",
     "meta": "assets/bg/titan_layers.json"}
PROP_CELL, PROP_BASE, PROP_SPACING = (16, 16), 14, (12, 34)
N_FRAMES, FRAME_MS = 6, 200
LAMP = (150, 118)                 # centro da poça de luz quente (lâmpada do abajur)
WINDOW = (452, 14, 116, 92)       # x, y, largura, altura da janela (acima do guarda-roupa)
INV = {}


def pxw(cv: Canvas, x: int, y: int, c) -> None:
    cv.px(x % cv.w, y, c)


def warm(c: str, lvl: float, x: int, y: int) -> str:
    """Luz quente do abajur sobre uma cor: sobe na rampa quente (com dither nas transições)."""
    ramps = {"shadow": ["shadow", "mauve", "rosewood", "sand"], "slate": ["slate", "rosewood", "sand", "cream"],
             "ink": ["ink", "plum_dark", "mauve", "rosewood"], "umber": ["umber", "rust", "terracotta", "copper"],
             "navy": ["navy", "plum_dark", "mauve", "rosewood"]}
    r = ramps.get(c)
    if not r or lvl <= 0:
        return c
    f = min(len(r) - 1.001, lvl * (len(r) - 1))
    i = int(f)
    return mix(r[i], r[i + 1], f - i, x, y)


def lamp_light(x: int, y: int) -> float:
    d = math.hypot((x - LAMP[0]) / 1.15, y - LAMP[1])
    return max(0.0, 1 - d / 170) ** 1.6


# ------------------------------------------------------------------ parede (sky)
def wall(cv: Canvas, fr: int = 0) -> None:
    for y in range(H):
        for x in range(W):
            stripe = (x // 14) % 2 == 0
            base = "slate" if stripe else "shadow"
            if y < 40:
                base = mix("ink", base, y / 40, x, y)          # canto do teto mais escuro
            if (x % 28 == 7) and (y % 24 == 11) and stripe:
                base = "lilac_grey"                             # estrelinhas estampadas no papel de parede
            lv = lamp_light(x, y)
            c = warm(base, lv, x, y) if base in ("slate", "shadow", "ink") else base
            # luar frio vindo da janela (faixa diagonal pontilhada)
            wx, wy, ww, wh = WINDOW
            beam = (x - (wx + ww * 0.1)) + (y - (wy + wh)) * 0.9
            if wy + wh < y < HORIZON and -ww * 0.8 < beam < 0 and lv < 0.3:
                c = mix(c, "indigo" if c in ("shadow", "ink") else "blue", 0.35, x, y)
            cv.px(x, y, c)
    for y in range(HORIZON - 16, HORIZON + 1):                 # rodapé de madeira
        for x in range(W):
            c = "rust" if y < HORIZON - 13 else "umber"
            if y == HORIZON - 16:
                c = "terracotta"
            cv.px(x, y, warm(c, lamp_light(x, y) * 0.8, x, y) if c == "umber" else c)
    # prateleira + abajur (fonte da luz)
    lx, ly = LAMP
    for x in range(lx - 50, lx + 50):
        cv.px(x, ly + 26, "terracotta"); cv.px(x, ly + 27, "rust"); cv.px(x, ly + 28, "umber")
    for y in range(ly + 8, ly + 26):                            # base e haste
        cv.px(lx - 1, y, "steel"); cv.px(lx, y, "lilac_grey")
    for x in range(lx - 8, lx + 9):
        cv.px(x, ly + 25, "slate")
    for j, y in enumerate(range(ly - 12, ly + 6)):              # cúpula (trapézio) iluminada por dentro
        half = 9 + j // 2
        for x in range(lx - half, lx + half + 1):
            t = (x - (lx - half)) / (2 * half)
            cv.px(x, y, "gold" if t < 0.3 else "amber" if t < 0.75 else "orange")
    for x in range(lx - 17, lx + 18):
        cv.px(x, ly + 6, "lemon")                               # boca da cúpula: luz
    for y in range(ly + 7, ly + 10):
        for x in range(lx - 3, lx + 4):
            cv.px(x, y, "white")
    # pôster de foguete (homenagem ao gênero), iluminado pela lâmpada
    px0, py0 = 262, 60
    for y in range(py0, py0 + 70):
        for x in range(px0, px0 + 50):
            edge = x in (px0, px0 + 49) or y in (py0, py0 + 69)
            c = "sand" if edge else "navy"
            cv.px(x, y, c)
    rocket = ["....a....", "...aba...", "...aba...", "..abbba..", "..abcba..", "..abbba..", "..abbba..",
              ".aabbbaa.", "aa.bbb.aa", "a..ded..a", "...ede...", "....d...."]
    cv.paint(rocket, {"a": "red", "b": "mist", "c": "aqua", "d": "gold", "e": "orange"}, x=px0 + 20, y=py0 + 20)
    for i in range(14):
        cv.px(px0 + 4 + (i * 7) % 42, py0 + 4 + (i * 11) % 14, "white")
    # poeira flutuando na luz do abajur (animada)
    rng = random.Random(9)
    for i in range(36):
        x0, y0 = rng.randint(LAMP[0] - 90, LAMP[0] + 90), rng.randint(LAMP[1] + 10, 230)
        y = y0 - ((fr + i) % N_FRAMES) // 2
        x = x0 + (1 if (fr + i * 3) % N_FRAMES < 3 else 0)
        if lamp_light(x, y) > 0.25:
            cv.px(x, y, "cream" if i % 3 else "peach")


# ------------------------------------------------------------------ janela (planet)
def window(cv: Canvas, fr: int = 0) -> tuple:
    wx, wy, ww, wh = WINDOW
    rng = random.Random(4)
    for y in range(wy, wy + wh):
        for x in range(wx, wx + ww):
            t = (y - wy) / wh
            cv.px(x, y, "ink" if t < 0.35 else mix("ink", "navy", (t - 0.35) / 0.65, x, y))
    for i in range(40):                                          # estrelas cintilando
        x, y = rng.randint(wx + 4, wx + ww - 5), rng.randint(wy + 4, wy + wh - 30)
        st = (fr + i) % N_FRAMES
        cv.px(x, y, "white" if st < 2 else "mist" if st < 4 else "lilac_grey")
    mx, my, mr = wx + 82, wy + 30, 13                           # lua
    for y in range(my - mr, my + mr + 1):
        for x in range(mx - mr, mx + mr + 1):
            d = math.hypot(x - mx, y - my)
            if d <= mr:
                lit = (x - mx) * -0.6 + (y - my) * -0.5
                cv.px(x, y, "white" if lit > 4 else "mist" if lit > -4 else "steel")
    for (cx, cy, r) in ((mx + 4, my - 3, 3), (mx - 5, my + 4, 2)):
        for y in range(cy - r, cy + r + 1):
            for x in range(cx - r, cx + r + 1):
                if math.hypot(x - cx, y - cy) <= r:
                    cv.px(x, y, "steel")
    for y in range(wy + 20, wy + wh):                            # telhados lá fora (silhueta)
        for x in range(wx, wx + ww):
            roof = wy + wh - 18 - (12 if 30 < x - wx < 62 else 0) - (abs((x - wx) % 32 - 16) // 3 if (x - wx) > 62 else 0)
            if y > roof:
                lit_win = ((x - wx) % 9 in (3, 4)) and (y - roof) % 7 in (3, 4) and (x * 3 + y) % 5 == 0
                cv.px(x, y, "gold" if lit_win else "ink")
    for x in range(wx - 4, wx + ww + 4):                         # moldura
        for t in range(4):
            cv.px(x, wy - 4 + t, "sand" if t == 0 else "rosewood")
            cv.px(x, wy + wh + t, "sand" if t == 0 else "rosewood")
    for y in range(wy - 4, wy + wh + 4):
        for t in range(4):
            cv.px(wx - 4 + t, y, "sand" if t == 0 else "rosewood")
            cv.px(wx + ww + t, y, "rosewood")
    for y in range(wy, wy + wh):
        cv.px(wx + ww // 2, y, "rosewood"); cv.px(wx + ww // 2 + 1, y, "mauve")
    for x in range(wx, wx + ww):
        cv.px(x, wy + wh // 2, "rosewood")
    for side in (-1, 1):                                         # cortinas com dobras
        cx0 = wx - 10 if side < 0 else wx + ww - 14
        for y in range(wy - 8, wy + wh + 30):
            spread = 24 - int(10 * max(0, (y - (wy + wh * 0.5)) / (wh * 0.5 + 30)))
            for k in range(spread):
                x = cx0 + (k if side < 0 else 24 - k)
                fold = (k + y // 30) % 6
                c = "berry" if fold < 2 else "rose" if fold < 4 else "berry_dark"
                cv.px(x, y, c)
    return (wx - 12, wy - 10, ww + 30, wh + 42)


# ------------------------------------------------------------------ móveis (far)
def box3d(cv: Canvas, x0: int, y0: int, w: int, h: int, top: str, front: str, side: str, rim: str) -> None:
    for y in range(y0, y0 + h):
        for x in range(x0, x0 + w):
            c = front
            if y < y0 + 3:
                c = top
            elif x > x0 + w - 6:
                c = side
            pxw(cv, x, y, c)
    for x in range(x0, x0 + w - 5):
        pxw(cv, x, y0, rim)
    for y in range(y0, y0 + h):
        pxw(cv, x0, y, rim)


def far_layer() -> Canvas:
    cv = Canvas(W, HORIZON + 1)
    b = HORIZON
    # cama (cabeceira + colchão + cobertor caindo)
    box3d(cv, 10, b - 150, 16, 150, "rosewood", "mauve", "plum_dark", "sand")
    box3d(cv, 26, b - 72, 230, 72, "mist", "lilac_grey", "slate", "white")
    for x in range(30, 250):
        for y in range(b - 60, b - 10 + int(6 * math.sin(x * 0.07))):
            if y > b - 60:
                pxw(cv, x, y, "indigo" if (x // 12 + y // 12) % 2 else "navy")
    box3d(cv, 40, b - 92, 70, 22, "white", "mist", "lilac_grey", "white")      # travesseiro
    # estante de livros
    box3d(cv, 290, b - 200, 110, 200, "rosewood", "mauve", "plum_dark", "sand")
    rng = random.Random(12)
    for shelf in range(4):
        sy = b - 190 + shelf * 48
        x = 296
        while x < 390:
            bw, bh = rng.randint(5, 10), rng.randint(26, 40)
            col = rng.choice([("crimson", "wine"), ("blue", "navy"), ("green", "pine"), ("gold", "amber"), ("violet", "plum")])
            for y in range(sy + 40 - bh, sy + 40):
                for dx in range(bw):
                    pxw(cv, x + dx, y, col[0] if dx < bw - 2 else col[1])
            x += bw + 1
        for xx in range(292, 398):
            pxw(cv, xx, sy + 40, "sand"); pxw(cv, xx, sy + 41, "rosewood")
    # guarda-roupa e baú de brinquedos
    box3d(cv, 430, b - 140, 120, 140, "rosewood", "mauve", "plum_dark", "sand")
    for y in range(b - 132, b - 10):
        pxw(cv, 490, y, "plum_dark")
    pxw(cv, 484, b - 70, "gold"); pxw(cv, 496, b - 70, "gold")
    box3d(cv, 570, b - 60, 66, 60, "terracotta", "rust", "wine", "copper")
    # penumbra: tudo escurece longe da lâmpada; luz quente de borda perto dela
    for y in range(cv.h):
        for x in range(W):
            c = cv.get(x, y)
            if c is None:
                continue
            name = INV[c]
            dark = {"white": "lilac_grey", "mist": "slate", "lilac_grey": "shadow", "sand": "rosewood",
                    "rosewood": "mauve", "mauve": "plum_dark", "slate": "shadow", "copper": "rust",
                    "terracotta": "rust", "rust": "wine", "gold": "amber", "crimson": "wine", "blue": "indigo",
                    "green": "pine", "violet": "plum"}.get(name, name)
            cv.px(x, y, mix(dark, name, (lamp_light(x, y) - 0.25) * 5, x, y))      # transição curta (sem granulado)
    return cv


# ------------------------------------------------------------------ brinquedos gigantes (mid)
def toy_blocks(cv: Canvas, x0: int, base: int, s: int, letters: str) -> None:
    cols = [("red", "crimson", "coral"), ("sky", "blue", "pale_sky"), ("leaf", "green", "sprout"),
            ("gold", "amber", "lemon")]
    glyphs = {"A": [".##.", "#..#", "####", "#..#"], "B": ["###.", "####", "#..#", "###."],
              "C": [".###", "#...", "#...", ".###"]}
    for i, ch in enumerate(letters):
        bx, by = x0 + (i % 2) * (s // 3), base - (i + 1) * s
        mid, dark, light = cols[i % len(cols)]
        for y in range(by, by + s):
            for x in range(bx, bx + s):
                c = "sand" if y < by + 3 or x < bx + 3 else "rosewood" if x > bx + s - 4 else "cream"
                pxw(cv, x, y, c)
        for y in range(by + 6, by + s - 4):
            for x in range(bx + 6, bx + s - 6):
                pxw(cv, x, y, mid if x < bx + s - 9 else dark)
        g = glyphs.get(ch, glyphs["A"])
        sc = (s - 18) // 4
        for gy, row in enumerate(g):
            for gx, v in enumerate(row):
                if v == "#":
                    for dy in range(sc):
                        for dx in range(sc):
                            pxw(cv, bx + 9 + gx * sc + dx, by + 9 + gy * sc + dy, "white")


def bricks(cv: Canvas, x0: int, base: int, n: int) -> None:
    cols = [("red", "crimson", "coral"), ("blue", "navy", "sky"), ("gold", "amber", "lemon"), ("green", "pine", "leaf")]
    y = base
    for i in range(n):
        mid, dark, light = cols[i % 4]
        w, h = 44, 18
        bx = x0 + (6 if i % 2 else 0)
        y -= h
        for yy in range(y, y + h):
            for x in range(bx, bx + w):
                pxw(cv, x, yy, light if yy == y else dark if x > bx + w - 5 or yy > y + h - 3 else mid)
        for k in range(3):                                          # pinos
            sx = bx + 5 + k * 14
            for yy in range(y - 5, y):
                for x in range(sx, sx + 9):
                    pxw(cv, x, yy, light if yy == y - 5 or x == sx else dark if x > sx + 6 else mid)


def ball(cv: Canvas, cx: int, base: int, r: int) -> None:
    cy = base - r
    for y in range(cy - r, cy + r + 1):
        for x in range(cx - r, cx + r + 1):
            if math.hypot(x - cx, y - cy) > r:
                continue
            band = (x - cx) * 0.8 + (y - cy) * 0.3
            lit = (x - cx) * -0.6 + (y - cy) * -0.8
            c = ("white" if lit > r * 0.4 else "mist" if lit > -r * 0.3 else "steel") if abs(band) < r * 0.3 else \
                ("coral" if lit > r * 0.4 else "red" if lit > -r * 0.3 else "crimson")
            pxw(cv, x, y, c)


def robot(cv: Canvas, x0: int, base: int, fr: int) -> None:
    body = ["....aaaaaaaa....", "....abbbbbbc....", "....abeebeec....", "....abbbbbbc....", "....abbddbbc....",
            "....acccccccc...", "......aabb......", "..aaabbbbbbccc..", "..abbbbbbbbbbc..", "..abbfbbbbfbbc..",
            "..abbbbbbbbbbc..", "..abbbggggbbbc..", "..acccccccccccc.", "....abc..abc....", "....abc..abc....",
            "...aabcc.aabcc.."]
    eye = "aqua" if fr % N_FRAMES not in (4,) else "steel"               # pisca
    legend = {"a": "mist", "b": "steel", "c": "lilac_grey", "d": "slate", "e": eye, "f": "red", "g": "gold"}
    scale = 3
    for j, row in enumerate(body):
        for i, v in enumerate(row):
            if v == ".":
                continue
            for dy in range(scale):
                for dx in range(scale):
                    pxw(cv, x0 + i * scale + dx, base - (len(body) - j) * scale + dy, legend[v])
    ax, ay = x0 + 8 * scale, base - len(body) * scale - 8                 # antena com luz
    for y in range(ay, ay + 8):
        pxw(cv, ax, y, "steel")
    pxw(cv, ax, ay - 1, "red" if fr % 2 == 0 else "coral")


def crayon(cv: Canvas, x0: int, base: int, h: int, col: tuple) -> None:
    mid, dark, light = col
    for y in range(base - h, base + 1):
        for x in range(x0, x0 + 10):
            c = light if x < x0 + 3 else dark if x > x0 + 7 else mid
            if (y - (base - h)) % 30 in (18, 19):
                c = "ink"                                                 # faixa do rótulo
            pxw(cv, x, y, c)
    for j in range(10):                                                   # ponta
        for x in range(x0 + j // 2, x0 + 10 - j // 2):
            pxw(cv, x, base - h - j, mid if x < x0 + 6 else dark)


def mid_layer(fr: int = 0) -> Canvas:
    cv = Canvas(W, ms.MID_BASE + 1)
    b = ms.MID_BASE
    for i, (bw, bh, cols) in enumerate(((150, 22, ("blue", "navy")), (140, 26, ("crimson", "wine")),
                                         (130, 20, ("green", "pine")), (120, 24, ("gold", "amber")))):
        y0 = b - sum(h for _, h, _ in ((150, 22, 0), (140, 26, 0), (130, 20, 0), (120, 24, 0))[:i + 1])
        x0 = 20 + i * 4
        for y in range(y0, y0 + bh):
            for x in range(x0, x0 + bw):
                spine = x < x0 + 6
                c = cols[0] if not spine else cols[1]
                if y in (y0, y0 + bh - 1):
                    c = "cream" if not spine else cols[1]                 # páginas
                elif y == y0 + 3 and not spine:
                    c = "gold"
                pxw(cv, x, y, c)
    toy_blocks(cv, 200, b, 40, "ABC")
    ball(cv, 330, b, 34)
    bricks(cv, 395, b, 6)
    robot(cv, 470, b, fr)
    crayon(cv, 560, b, 140, ("violet", "purple", "lavender"))
    crayon(cv, 576, b, 110, ("leaf", "green", "sprout"))
    crayon(cv, 600, b, 125, ("red", "crimson", "coral"))
    return cv


# ------------------------------------------------------------------ assoalho (plain)
def plain_layer() -> Canvas:
    cv = Canvas(W, H + 160)
    top = ms.PLAIN_TOP
    for y in range(top, cv.h):
        k = y - top
        row = int(math.sqrt(k + 1) * 3)                                 # tábuas mais finas ao longe
        for x in range(W):
            seam = (x + row * 37) % 96 == 0
            line = int(math.sqrt(k) * 3) != int(math.sqrt(k + 1) * 3)
            c = "umber" if seam or line else ("rust" if row % 2 else "wine")
            lv = lamp_light(x, y)
            cv.px(x, y, warm("umber", lv, x, y) if c == "umber" else mix(c, "terracotta", lv * 1.2, x, y))
    return cv.crop(0, top, W, cv.h - top)


# ------------------------------------------------------------------ cobertor de tricô (chão de pouso)
STRIPES = [(0, "raspberry"), (16, "cream"), (21, "raspberry"), (36, "navy"), (41, "raspberry"), (58, "cream"),
           (62, "raspberry")]
RIM = {"lit": ["peach", "salmon", "raspberry"], "flat": ["salmon", "raspberry", "raspberry"],
       "shade": ["raspberry", "magenta_dark", "magenta_dark"]}
DARKER = {"raspberry": "magenta_dark", "cream": "sand", "navy": "ink", "salmon": "raspberry", "peach": "salmon"}


def ground_strip(face: str, seed: int) -> Canvas:
    cv = Canvas(STRIP_W, STRIP_D)
    for x in range(STRIP_W):
        for k in range(STRIP_D):
            if k < 3:
                c = RIM[face][k]
            else:
                c = "raspberry"
                for k0, col in STRIPES:
                    if k >= k0:
                        c = col
                if k >= 70:
                    c = mix("magenta_dark", "plum_dark", min(1, (k - 70) / 50), x, k)
                elif face == "shade":
                    c = DARKER.get(c, c)
            # ponto de tricô: "V" de 4 px (lado esquerdo claro, direito escuro)
            if 3 <= k < 70 and (x % 4 == 3 or (x % 4 == 0 and k % 3 == 0)):
                c = DARKER.get(c, c)
            cv.px(x, k, c)
    return cv


# ------------------------------------------------------------------ enfeites (16x16, base 14)
PROPS = {
    "brick": ({"a": "coral", "b": "red", "c": "crimson"}, ["..aa..aa........", "..bc..bc........",
                                                          ".aaaaaaaaa......", ".abbbbbbbc......", ".abbbbbbbc......",
                                                          ".ccccccccc......"]),
    "crayon": ({"a": "sky", "b": "blue", "c": "navy", "k": "ink"}, [".....a..........", "....abc.........",
                                                                    "....abc.........", "....kkk.........",
                                                                    "....abc.........", "....abc.........",
                                                                    "....abc.........", "....kkk.........",
                                                                    "....abc........."]),
    "marble": ({"w": "white", "a": "aqua", "s": "sea", "d": "deep_teal", "m": "mist"}, ["......wwa.......",
                                                                                      ".....wwaas......",
                                                                                      ".....wassd......",
                                                                                      ".....asssd......",
                                                                                      "......sdd......."]),
    "coin": ({"a": "lemon", "b": "gold", "c": "amber", "d": "orange"}, ["....aaaab.......", "...abbbbbc......",
                                                                        "...dccccccd.....", "....dddddd......"]),
    "button": ({"a": "lavender", "b": "violet", "c": "purple", "k": "plum"}, ["....abbbb.......", "...abkbkbc......",
                                                                               "...bbbbbbc......", "....cccc........"]),
    "dice": ({"w": "white", "m": "mist", "s": "steel", "k": "ink"}, ["...wwwwwwm......", "...wkwwkwm......",
                                                                     "...wwwwwwm......", "...wkwwkws......",
                                                                     "...mmmmmms......"]),
    "pencil": ({"a": "gold", "b": "amber", "p": "peach", "k": "ink", "r": "pink", "s": "steel"}, [
        "...............k", ".............ppk", "...........aap..", ".........aab....", ".......aab......",
        ".....aab........", "...ssb..........", "..rrs...........", "..rr............"]),
}


def top_frame(fr: int) -> list:
    """Pião girando: listras correm pela barriga do pião."""
    rows = ["......kk........", ".....abca.......", "....abcabc......", "...abcabcab.....", "....bcabca......",
            ".....cabc.......", "......kk........", ".......k........"]
    shift = fr % 3
    out = []
    for r in rows:
        out.append("".join({"a": "bca", "b": "cab", "c": "abc"}[ch][shift] if ch in "abc" else ch for ch in r))
    return out


PROP_ORDER = ["brick", "crayon", "marble", "coin", "button", "dice", "pencil", "top"]


def props_atlas(fr: int = 0) -> Canvas:
    cw, ch = PROP_CELL
    cv = Canvas(cw * len(PROP_ORDER), ch)
    for i, name in enumerate(PROP_ORDER):
        if name == "top":
            legend, rows = {"a": "red", "b": "gold", "c": "sky", "k": "umber"}, top_frame(fr)
        else:
            legend, rows = PROPS[name]
        cv.paint(rows, legend, x=i * cw, y=PROP_BASE + 1 - len(rows))
    return cv


# ------------------------------------------------------------------ montagem
def layers() -> dict:
    global INV
    INV = {resolve(n): n for n in COLOR_NAMES}
    L = {}
    L["sky_frames"] = []
    for f in range(N_FRAMES):
        c = Canvas(W, H); wall(c, f); L["sky_frames"].append(c)
    L["planet_frames"] = []
    for f in range(N_FRAMES):
        c = Canvas(W, H); box = window(c, f); L["planet_frames"].append(c.crop(*box))
    L["planet_pos"] = box[:2]
    L["far"] = far_layer()
    L["mid_frames"] = [mid_layer(f) for f in range(N_FRAMES)]
    L["plain"] = plain_layer()
    for i, face in enumerate(("lit", "flat", "shade")):
        L[face] = ground_strip(face, 61 + i)
    L["props_frames"] = [props_atlas(f) for f in range(N_FRAMES)]
    return L


def compose(L: dict, f: int = 0) -> Canvas:
    cv = Canvas(W, H)
    cv.stamp(L["sky_frames"][f]); cv.stamp(L["planet_frames"][f], *L["planet_pos"])
    cv.stamp(L["far"]); cv.stamp(L["mid_frames"][f]); cv.stamp(L["plain"], 0, ms.PLAIN_TOP)
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
            cv.stamp(L["props_frames"][(f + i) % N_FRAMES].crop(i * cw, 0, cw, ch), int(x - cw / 2),
                     ridge_y(pts, x) + rng.randint(0, 2) - PROP_BASE)
        x += rng.uniform(*PROP_SPACING)
    y = ridge_y(pts, pad[0] + pad[1] // 2)
    cv.stamp(Canvas.from_image("assets/sprites/target_beam.png").crop(0, 0, 64, 84), pad[0], y - 84)
    cv.stamp(Canvas.from_image("assets/sprites/landing_pad.png").crop(0, 28, 80, 28), pad[0] - 8, y - 10)
    cv.stamp(Canvas.from_image("assets/sprites/lander.png").crop(0, 0, 32, 32), pad[0] + pad[1] // 2 - 16, y - 25)
    return cv


def export(L: dict) -> None:
    au.stack(L["sky_frames"]).save(P["sky"])
    au.stack(L["planet_frames"]).save(P["planet"])
    L["far"].save(P["far"])
    au.stack(L["mid_frames"]).save(P["mid"])
    L["plain"].save(P["plain"])
    au.stack_cells(L["props_frames"]).save(P["props"])
    for k in ("lit", "flat", "shade"):
        L[k].save(P[k], tiled=True)
    meta = {
        "notes": "Quarto bagunçado (mundo 4, id titan). Gerado por art/src/bg/room_scene.py (pixel-art).",
        "horizon": HORIZON, "planet_pos": list(L["planet_pos"]), "far_y": 0, "mid_y": 0, "plain_y": ms.PLAIN_TOP,
        "deep_color": "#45293f", "strip_depth": STRIP_D, "strip_width": STRIP_W, "face_slope": FACE_SLOPE,
        "rock_cell": list(PROP_CELL), "rock_base_row": PROP_BASE, "rock_count": len(PROP_ORDER),
        "rock_widths": [16] * len(PROP_ORDER), "rock_spacing": list(PROP_SPACING),
        "rock_frames": N_FRAMES, "rock_ms": FRAME_MS,
        "anim": {"sky": {"frames": N_FRAMES, "ms": FRAME_MS * 2}, "planet": {"frames": N_FRAMES, "ms": FRAME_MS * 2},
                 "mid": {"frames": N_FRAMES, "ms": FRAME_MS * 2}},
    }
    with open(P["meta"], "w") as f:
        json.dump(meta, f, indent=2)


if __name__ == "__main__":
    L = layers()
    sc = compose(L)
    print("cores:", len(sc.colors_used()))
    sc.save("art/previews/room_scene.png", preview=False)
    sc.preview("art/previews/room_scene_2x.png", scale=2, grid=False, show_1x=False)
    au.save_gif([compose(L, f) for f in range(N_FRAMES)], "art/previews/room_anim.gif", FRAME_MS * 2)
    if "--export" in sys.argv:
        export(L)
