"""Lua no estilo FOFO/COZY — tema "Lua de queijo" (2026-10-04). Skill pixel-art, padrões cute-style + moon-cute.

v4 (autoavaliação pedida pelo usuário; "então arruma tudo"): composição e desenho, não só cor.
  - foco: poucos elementos e MAIORES (2 coelhos grandes, 3 bases bem desenhadas, 2 nuvens grandes, 5 brilhos);
  - céu em degradê de verdade (6 tons, transições pontilhadas curtas e retas), sem listras serrilhadas;
  - morros com silhueta própria cada um (alturas, larguras, topo achatado, calombos) e sombreamento CEL que
    acompanha a forma: brilho na borda virada para a luz, sombra na borda oposta e na base — não anéis;
  - hierarquia de valor: fundo claro e apagado (morros de trás quase da cor do horizonte), morros da frente
    saturados com contorno colorido, personagens e chão de queijo mais fortes;
  - regra única de contorno: cenário = cor escura da própria rampa; personagens/veículos = ink;
  - nave-mãe menor e com volume, Terra dormindo com rosto legível, nuvens fofas, fumaça como uma nuvem só.
Mesmo contrato de assets da Lua (moon_scene.py / moon_war.py).

Rodar da raiz:
  python3 art/src/bg/moon_cute.py           -> prévia art/previews/moon_cute.png (não mexe no jogo)
  python3 art/src/bg/moon_cute.py --export  -> grava os assets luna_* / war_* e assets/bg/luna_layers.json
"""
import json
import math
import random
import sys

sys.path.insert(0, ".claude/skills/pixel-art/scripts")
sys.path.insert(0, "art/src/terrain")
sys.path.insert(0, "art/src/bg")
sys.path.insert(0, "art/src/sprites")
from pixelart import *
from moon import profile, ridge_y
import moon_scene as ms
import moon_war as mw
import anim_util as au

W, H = 640, 360
HORIZON, PLANET = ms.HORIZON, ms.PLANET
MID_BASE, PLAIN_TOP = ms.MID_BASE, ms.PLAIN_TOP
SKY_FRAMES, SKY_MS = ms.SKY_FRAMES, ms.SKY_MS
FR, LAYER_MS = mw.FR, mw.LAYER_MS
SW, CRUST_D, DEPTH_D, BODY_T = 128, 26, 176, 128
PLAIN_H = H + 160 - PLAIN_TOP
BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]

T = dict(
    name="Lua de queijo",
    sky=[(0, "plum"), (64, "berry"), (122, "rose"), (172, "salmon"), (214, "peach"), (246, "cream")],
    sparkle=["white", "cream", "peach"], cloud=["white", "cream", "peach"], cloud_ol="salmon",
    back=["cream", "peach", "peach", "salmon"],                   # morros de trás: quase o horizonte
    front=["peach", "salmon", "rose", "berry"], front_ol="berry_dark", haze="berry",
    plain=["berry", "berry_dark", "plum_dark"], plain_line="rose",
    rim={"lit": ["white", "lemon"], "flat": ["lemon", "gold"], "shade": ["gold", "amber"]},
    ol="rust", ao="amber", body="gold", strata="honey", hole="amber", hole_dark="copper", lip="lemon",
    pebble="honey", depth=["amber", "copper", "terracotta"], rock=["lemon", "gold", "white"],
    smoke=["white", "cream", "peach"], smoke_ol="rose", earth_glow=["peach", "salmon"],
)


# ------------------------------------------------------------------ utilidades
def on(level: float, x: int, y: int) -> bool:
    return level * 16 > BAYER[y % 4][x % 4] + 0.5


def wave(x: float, seed: int, amp: float, period: int = W, freqs=(1, 2, 3)) -> float:
    rng = random.Random(seed)
    s = 0.0
    for i, f in enumerate(freqs):
        s += math.sin(math.tau * f * x / period + rng.random() * math.tau) / (i + 1)
    return s * amp


def disc(cv: Canvas, cx: float, cy: float, r: float, color, wrap: int = 0) -> None:
    for y in range(int(cy - r) - 1, int(cy + r) + 2):
        for x in range(int(cx - r) - 1, int(cx + r) + 2):
            if (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 <= r * r:
                cv.px(x % wrap if wrap else x, y % wrap if wrap else y, color)


def sphere(cv: Canvas, cx: float, cy: float, rx: float, ry: float, ramp: list, clip=None) -> None:
    """Elipse com volume (luz de cima-esquerda): ramp = [brilho, luz, base, sombra]."""
    for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            nx, ny = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
            d = nx * nx + ny * ny
            if d > 1 or (clip and not clip(x, y)):
                continue
            nz = math.sqrt(1 - d)
            i = -0.5 * nx - 0.6 * ny + 0.62 * nz
            cv.px(x, y, ramp[0] if i > 0.85 else ramp[1] if i > 0.5 else ramp[2] if i > 0.08 else ramp[3])


def cel(k: Canvas, ramp: list, base_y: int | None = None, lit_w: int = 5) -> None:
    """Sombreamento cel que acompanha a silhueta: brilho na borda virada para a luz (cima-esquerda), sombra
    na borda oposta (direita) e na base. ramp = [brilho, luz, base, sombra]."""
    solid = k.opaque()

    def run(x, y, dx, dy, cap):
        n = 0
        while n < cap and (x + dx * (n + 1), y + dy * (n + 1)) in solid:
            n += 1
        return n
    for x, y in solid:
        dl = min(run(x, y, -1, -1, 40), run(x, y, 0, -1, 40) + 3)
        dr = run(x, y, 1, 0, 8)
        c = ramp[2]
        if dl <= lit_w:
            c = ramp[1]
        if dl <= 1:
            c = ramp[0]
        if dr <= 2 and dl > 1:
            c = ramp[3]
        if base_y is not None and base_y - y < 5:
            c = ramp[3]
        k.px(x, y, c)


# ------------------------------------------------------------------ céu
def sky_color(x: int, y: int):
    stops = T["sky"]
    c = stops[0][1]
    for i in range(1, len(stops)):
        y0, name = stops[i]
        if y >= y0:
            c = name
        elif y >= y0 - 16:                                      # transição reta (pontilhado bayer)
            if on((y - (y0 - 16)) / 16, x, y):
                c = name
    return c


SPARKLES = [(46, 30, 3), (186, 20, 2), (566, 26, 3), (118, 108, 2), (612, 120, 2)]


def sparkle(cv: Canvas, x: int, y: int, size: int) -> None:
    """Brilho de 4 pontas sem contorno (centro branco, braços creme/pêssego)."""
    a, b, c = T["sparkle"]
    cv.px(x, y, a)
    for d in range(1, size + 1):
        col = b if d < size else c
        for dx, dy in ((d, 0), (-d, 0), (0, d), (0, -d)):
            cv.px(x + dx, y + dy, col)
    if size >= 2:
        for dx, dy in ((1, 1), (-1, 1), (1, -1), (-1, -1)):
            cv.px(x + dx, y + dy, b)


CLOUD_TOPS = {
    "pequena": [7, 5, 4, 3, 3, 4, 3, 2, 1, 1, 1, 2, 2, 3, 2, 2, 2, 3, 4, 4, 5, 6, 7, 8],
    "grande": [8, 6, 4, 3, 2, 2, 3, 3, 2, 1, 0, 0, 1, 2, 2, 1, 1, 1, 2, 3, 3, 4, 3, 4, 5, 6, 7, 8, 9],
}
CLOUDS = [(84, 170, "grande", False), (500, 188, "grande", True), (236, 84, "pequena", False)]


def cloud(cv: Canvas, x: int, y: int, kind: str, flip: bool) -> None:
    """Nuvem do kit: perfil de cima desenhado (meia res.), topo branco, corpo creme, base pêssego, Scale2x."""
    tops = CLOUD_TOPS[kind]
    hgt = max(tops) + 3
    hi, base, shade = T["cloud"]
    k = Canvas(len(tops), hgt)
    for xx, t in enumerate(tops):
        k.vline(xx, t, hgt - 1, base)
        if t <= 3:
            k.px(xx, t, hi)
            if t <= 1:
                k.px(xx, t + 1, hi)
        k.px(xx, hgt - 1, shade)
        if 2 < xx < len(tops) - 3:
            k.px(xx, hgt - 2, shade)
    for yy in range(hgt):                                        # base arredondada (sem cara de caixa)
        for xx in list(range(0, 3)) + list(range(len(tops) - 3, len(tops))):
            edge = min(xx, len(tops) - 1 - xx)
            if yy >= hgt - (3 - edge):
                k.px(xx, yy, None)
    k.outline(T["cloud_ol"])
    if flip:
        k.flip_h()
    k = scale2x(k)
    cv.stamp(k, x - k.w // 2, y - k.h // 2)


def sky(fr: int) -> Canvas:
    cv = Canvas(W, H)
    for y in range(H):
        for x in range(W):
            cv.px(x, y, sky_color(x, y))
    rng = random.Random(4)
    for _ in range(36):                                        # poucas estrelinhas, só no alto
        x, y = rng.randrange(W), int(rng.random() ** 1.3 * 110)
        if (fr + x) % SKY_FRAMES:
            cv.px(x, y, "peach" if y > 60 else "cream")
    for i, (x, y, s) in enumerate(SPARKLES):
        sparkle(cv, x, y, max(1, s - [0, 1, 1, 0, 0, 0][(fr + i * 2) % SKY_FRAMES]))
    for x, y, kind, flip in CLOUDS:
        cloud(cv, x, y, kind, flip)
    ringed(cv, 404, 30)
    mothership(cv, fr)
    return cv


def ringed(cv: Canvas, cx: int, cy: int) -> None:
    k = Canvas(30, 22)
    sphere(k, 15, 11, 7, 7, ["cream", "peach", "salmon", "rose"])
    for x in range(1, 29):
        y = 12.5 + (x - 15) * 0.18
        if not (8 < x < 22 and y < 12):
            k.px(x, int(y), "lemon")
    k.outline("berry")
    cv.stamp(k, cx - 15, cy - 11)


MOTHER_C = (236, 50)


def mothership(cv: Canvas, fr: int) -> None:
    """Nave-mãe com volume: casco grosso sombreado, cúpula de vidro com alienzinho, luzinhas que correm."""
    k = Canvas(132, 54)
    ox = 66
    for y in range(4, 36):                                     # cúpula de vidro
        for x in range(ox - 22, ox + 23):
            if ((x + 0.5 - ox) / 22) ** 2 + ((y + 0.5 - 30) / 22) ** 2 <= 1 and y <= 30:
                k.px(x, y, "sky" if x > ox + 9 else "pale_sky")
    sphere(k, ox - 0.5, 22, 10, 8.5, ["sprout", "leaf", "leaf", "green"])           # alien
    for s in (-1, 1):
        k.line(ox + s * 5, 15, ox + s * 8, 9, "leaf")
        disc(k, ox + s * 8 + 0.5, 8.5, 1.8, "sprout")
    for x0 in (ox - 6, ox + 3):
        k.rect(x0, 19, 3, 5, "ink"); k.px(x0, 19, "white"); k.px(x0 + 1, 19, "white")
    k.hline(ox - 9, ox - 8, 25, "pink"); k.hline(ox + 8, ox + 9, 25, "pink")
    k.px(ox - 1, 27, "ink"); k.px(ox, 27, "ink")
    for x, y in ((ox - 15, 14), (ox - 16, 16), (ox - 13, 12), (ox - 11, 11)):
        k.px(x, y, "white")
    sphere(k, ox - 0.5, 35, 62, 9, ["white", "mist", "steel", "lilac_grey"])        # casco
    for i, x in enumerate(range(ox - 50, ox + 51, 10)):                             # luzinhas
        lit = (i + fr) % 3 == 0
        disc(k, x + 0.5, 37, 1.7, ("gold" if i % 2 else "hot_pink") if lit else "slate")
    sphere(k, ox - 0.5, 45, 13, 4, ["steel", "lilac_grey", "lilac_grey", "slate"])
    disc(k, ox, 48, 3.5 if fr % 2 else 2.5, "ice" if fr % 2 else "aqua")
    k.outline("ink")
    cv.stamp(k, MOTHER_C[0] - ox, MOTHER_C[1] - 35)


# ------------------------------------------------------------------ Terra dormindo
def planet() -> Canvas:
    cx, cy, r = PLANET
    m = r + 12
    c = Canvas(2 * m + 1, 2 * m + 1)
    o = m + 0.5
    g0, g1 = T["earth_glow"]
    for y in range(c.h):
        for x in range(c.w):
            d = math.hypot(x + 0.5 - o, y + 0.5 - o)
            if r + 3 <= d < r + 4.2:
                c.px(x, y, g0)
            elif r + 7 <= d < r + 8:
                c.px(x, y, g1)
    rng = random.Random(3)
    blobs = [(o - 12, o - 14, 9), (o + 14, o - 6, 7), (o - 16, o + 12, 8), (o + 8, o + 18, 6)]
    for y in range(c.h):
        for x in range(c.w):
            nx, ny = (x + 0.5 - o) / r, (y + 0.5 - o) / r
            d = nx * nx + ny * ny
            if d > 1:
                continue
            land = any(math.hypot(x + 0.5 - bx, y + 0.5 - by) < br + 2 * math.sin(x * 0.7 + y * 0.5) for bx, by, br in blobs)
            i = -0.5 * nx - 0.6 * ny + 0.62 * math.sqrt(1 - d)
            if land:
                c.px(x, y, "leaf" if i > 0.6 else "green" if i > 0.1 else "pine")
            else:
                c.px(x, y, "pale_sky" if i > 0.92 else "sky" if i > 0.55 else "blue" if i > 0.1 else "indigo")
    for bx, by, rr in ((o - 4, o - 24, 3.5), (o + 1, o - 24, 4), (o + 6, o - 23, 3), (o + 18, o + 9, 3), (o + 22, o + 9, 2.5)):
        disc(c, bx, by, rr, "white")
    ex, ey = int(o), int(o + 3)                                  # rosto dormindo, grande e central
    for sx in (-12, 7):
        for j, dy in enumerate((0, 1, 1, 1, 0)):
            c.px(ex + sx + j, ey + dy, "ink")
        bx = ex + sx - 3 if sx < 0 else ex + sx + 4                 # bochecha por fora e abaixo do olho
        c.hline(bx, bx + 2, ey + 3, "pink")
    c.px(ex - 1, ey + 6, "ink"); c.px(ex, ey + 7, "ink"); c.px(ex + 1, ey + 6, "ink")   # boquinha
    edge = Canvas(c.w, c.h)
    for y in range(c.h):
        for x in range(c.w):
            if r <= math.hypot(x + 0.5 - o, y + 0.5 - o) < r + 1.1:
                edge.px(x, y, "navy")
    c.stamp(edge)
    return c


# ------------------------------------------------------------------ KIT desenhado à mão (meia resolução + Scale2x)
# v5 (usuário: "faz no mapa pra eu ver"): morros e nuvens são PEÇAS com silhueta desenhada por pontos de controle
# (meia resolução), sombreadas, contornadas e ampliadas com Scale2x/EPX (arredonda bordas sem criar cores).
def scale2x(c: Canvas) -> Canvas:
    o = Canvas(c.w * 2, c.h * 2)

    def g(x, y):
        return c.get(min(max(x, 0), c.w - 1), min(max(y, 0), c.h - 1))
    for y in range(c.h):
        for x in range(c.w):
            P, A, B, C, D = g(x, y), g(x, y - 1), g(x + 1, y), g(x - 1, y), g(x, y + 1)
            e = [P] * 4
            if C == A and C != D and A != B: e[0] = A
            if A == B and A != C and B != D: e[1] = B
            if D == C and D != B and C != A: e[2] = C
            if B == D and B != A and D != C: e[3] = D
            for i, (dx, dy) in enumerate(((0, 0), (1, 0), (0, 1), (1, 1))):
                if e[i] is not None:
                    o.px(2 * x + dx, 2 * y + dy, e[i])
    return o


def profile_from(points: list) -> list:
    """Altura por coluna a partir de pontos de controle desenhados (interpolação cosseno = curva macia)."""
    out = []
    points = [(int(round(x * 1.7)), h) for x, h in points]           # morros largos e redondinhos (fofos)
    for (x0, h0), (x1, h1) in zip(points, points[1:]):
        for x in range(x0, x1):
            t = (x - x0) / (x1 - x0)
            out.append(h0 + (h1 - h0) * (1 - math.cos(math.pi * t)) / 2)
    out.append(points[-1][1])
    return out


def shade_piece(k: Canvas, ramp: list, base_y: int, lit_w: int, ao: int = 2) -> None:
    solid = k.opaque()

    def run(x, y, dx, dy, cap):
        n = 0
        while n < cap and (x + dx * (n + 1), y + dy * (n + 1)) in solid:
            n += 1
        return n
    for x, y in solid:
        dl = min(run(x, y, -1, -1, 60), run(x, y, 0, -1, 60) + 2)
        dr = run(x, y, 1, 0, 8)
        c = ramp[2]
        if dl <= lit_w:
            c = ramp[1]
        if dl <= 1:
            c = ramp[0]
        if dr <= 1 and dl > 1:
            c = ramp[3]
        if base_y - y < ao:
            c = ramp[3]
        k.px(x, y, c)


# pontos de controle (meia resolução): (x, altura)
HILLS = {
    "domo_calombo": [(0, 0), (5, 14), (10, 26), (15, 33), (20, 35), (25, 34), (29, 26), (32, 23), (36, 24), (40, 17), (46, 0)],
    "baixinho":     [(0, 0), (4, 9), (9, 15), (14, 17), (19, 15), (23, 9), (27, 0)],
    "planalto":     [(0, 0), (6, 18), (11, 31), (15, 39), (19, 42), (26, 42), (30, 40), (34, 32), (39, 18), (44, 0)],
    "dois_calombos": [(0, 0), (5, 10), (9, 16), (13, 18), (16, 15), (19, 16), (23, 21), (27, 20), (31, 12), (35, 0)],
    "bolinha":      [(0, 0), (5, 12), (9, 19), (12, 21), (15, 19), (19, 12), (23, 0)],
    "grande_fundo": [(0, 0), (10, 20), (22, 34), (34, 40), (46, 36), (56, 26), (66, 30), (76, 22), (90, 0)],
    "fundo_alto":   [(0, 0), (12, 26), (24, 42), (34, 47), (44, 41), (58, 20), (70, 0)],
}
BACK = [("grande_fundo", -60, False), ("fundo_alto", 190, True), ("grande_fundo", 360, True)]
FRONT = [("planalto", 296, False), ("domo_calombo", -6, False), ("domo_calombo", 470, True),
         ("dois_calombos", 196, True), ("baixinho", 150, False), ("bolinha", 116, False),
         ("baixinho", 420, True), ("bolinha", 590, False)]
BASES = [(64, "dome"), (374, "ruin"), (562, "dome")]
BUNNIES = [(196, False), (466, True)]


def piece(name: str, flip: bool, ramp: list, ol, lit_w: int, ao: int = 2) -> Canvas:
    hs = profile_from(HILLS[name])
    h = int(max(hs)) + 2
    k = Canvas(len(hs), h)
    for x, hh in enumerate(hs):
        if hh >= 0.5:
            k.vline(x, int(h - 1 - hh), h - 1, ramp[2])
    shade_piece(k, ramp, h - 1, lit_w, ao)
    if ol:
        k.outline(ol, inside=True)
    if flip:
        k.flip_h()
    return scale2x(k)


def stamp_wrap(c: Canvas, k: Canvas, x: int, y: int) -> None:
    for dx in (-W, 0, W):
        c.stamp(k, x + dx, y)


def mid_ground() -> tuple:
    c = Canvas(W, MID_BASE + 1)
    for name, x, flip in BACK:
        k = piece(name, flip, T["back"], None, 4, ao=0)
        stamp_wrap(c, k, x, MID_BASE + 1 - k.h)
    front = Canvas(W, MID_BASE + 1)
    for name, x, flip in FRONT:
        k = piece(name, flip, T["front"], T["front_ol"], 6)
        stamp_wrap(front, k, x, MID_BASE + 1 - k.h)
    c.stamp(front)
    for x in range(W):                                           # névoa lisa na base (liga com a planície)
        y0 = int(MID_BASE - 5 + wave(x, 21, 1.5, freqs=(4, 7, 11)))
        for y in range(y0, MID_BASE + 1):
            if c.get(x, y) is not None:
                c.px(x, y, T["haze"])
    tops = [next((y for y in range(MID_BASE + 1) if front.get(x, y) is not None), MID_BASE) for x in range(W)]
    return c, tops


def bunny(fr: int, phase: int) -> Canvas:
    """Coelhinho da Lua 15x18: orelhas compridas, rosto grande, olhinhos brilhando, bochecha — quica."""
    up = 1 if (fr + phase) % FR in (1, 2) else 0
    k = Canvas(15, 18)
    for ex in (4, 8):                                            # orelhas
        k.rect(ex, 1 - up + 1, 2, 6, "white")
        k.vline(ex + (1 if ex == 4 else 0), 3 - up, 6 - up, "pink")
    sphere(k, 6.5, 10 - up, 5, 4, ["white", "white", "white", "cream"])      # cabeça
    sphere(k, 7.5, 14 - up, 5, 3, ["white", "white", "cream", "peach"])      # corpinho
    k.px(4, 9 - up, "ink"); k.px(4, 10 - up, "ink"); k.px(8, 9 - up, "ink"); k.px(8, 10 - up, "ink")
    k.px(6, 11 - up, "pink")
    k.px(3, 11 - up, "pink"); k.px(9, 11 - up, "pink")
    disc(k, 12, 14 - up, 1.6, "white")                           # rabinho
    k.outline("ink")
    return k


def base_dome(fr: int, i: int, ruined: bool = False) -> Canvas:
    """Base fofa 44x32: cúpula com volume, janelas redondas acesas, porta, antena com luz, bandeirinha."""
    k = Canvas(44, 32)
    ramp = ["mist", "steel", "lilac_grey", "slate"] if ruined else ["white", "mist", "steel", "lilac_grey"]
    sphere(k, 22, 28, 15, 14, ramp, clip=lambda x, y: y <= 28)
    k.hline(5, 38, 29, "lilac_grey"); k.hline(6, 37, 30, "slate")             # sapata
    if ruined:
        for x, y in ((17, 15), (18, 16), (19, 15), (20, 16), (21, 15), (22, 16), (23, 15)):
            k.px(x, y, None)                                                  # rachado no topo
        disc(k, 22, 20, 2.2, "amber" if fr % 2 else "gold")
    else:
        for j, (wx, wy) in enumerate(((13, 22), (22, 19), (31, 22))):
            disc(k, wx, wy, 2.4, "gold" if (j + fr + i) % 3 else "honey")
            k.px(int(wx) - 1, int(wy) - 1, "lemon")
        k.rect(20, 23, 4, 6, "slate"); k.hline(21, 22, 22, "slate")          # porta
        k.line(32, 15, 36, 6, "lilac_grey")                                   # antena
        disc(k, 36.5, 5.5, 1.9, "hot_pink" if (fr + i) % 4 < 2 else "rose")
        k.vline(8, 7, 17, "lilac_grey")                                       # bandeirinha
        wave_y = fr % 2
        k.rect(9, 7 + wave_y, 5, 2, "aqua"); k.rect(9, 9 + wave_y, 4, 1, "sea")
    k.outline("ink")
    return k


def smoke(fr: int) -> Canvas:
    """Fumaça como UMA nuvenzinha que sobe e muda de forma (4 quadros)."""
    k = Canvas(30, 48)
    hi, base, shade = T["smoke"]
    for j in range(4):
        t = ((fr + j) % FR) / FR
        cy = 41 - 7 * j - 4 * t
        r = 4.5 + 1.4 * j + t
        cx = 15 + 3 * math.sin(j * 1.3 + t * 2)
        for y in range(int(cy - r) - 1, int(cy + r) + 2):
            for x in range(int(cx - r) - 1, int(cx + r) + 2):
                nx, ny = (x + 0.5 - cx) / r, (y + 0.5 - cy) / r
                if nx * nx + ny * ny <= 1:
                    k.px(x, y, hi if (-0.6 * nx - 0.8 * ny) > 0.4 else base if ny < 0.45 else shade)
    k.outline(T["smoke_ol"])
    return k


def mid_layer(base: Canvas, tops: list, fr: int) -> tuple:
    c = base.copy()
    muzzles, targets = [], []
    for i, (x, kind) in enumerate(BASES):
        b = min(tops[(x + d) % W] for d in range(-6, 7)) + 3
        k = base_dome(fr, i, ruined=kind == "ruin")
        c.stamp(k, x - 22, b - 31)
        if kind == "ruin":
            c.stamp(smoke(fr), x - 15, b - 31 - 40)
            targets.append((x, b - 16))
        else:
            muzzles.append((x + 14, b - 26))
            targets.append((x, b - 12))
    for i, (x, flip) in enumerate(BUNNIES):
        b = min(tops[(x + d) % W] for d in range(-3, 4)) + 2
        k = bunny(fr, i * 2)
        if flip:
            k.flip_h()
        c.stamp(k, x - 7, b - 18)
    return c, muzzles, targets


# ------------------------------------------------------------------ planície (+ disco abatido)
WRECK = (440, 18)


def plain(fr: int) -> Canvas:
    c = Canvas(W, PLAIN_H)
    p0, p1, p2 = T["plain"]
    for x in range(W):
        for y in range(PLAIN_H):
            col = p0 if y < 24 else p1 if y < 64 else p2
            if 20 <= y < 24 and on((y - 20) / 4, x, y):
                col = p1
            if 58 <= y < 64 and on((y - 58) / 6, x, y):
                col = p2
            c.px(x, y, col)
    rng = random.Random(41)
    for _ in range(10):
        x, y, ln = rng.randrange(W), rng.randint(4, 15), rng.randint(14, 34)
        for i in range(ln):
            c.px((x + i) % W, y, T["plain_line"])
    x0, y0 = WRECK
    s = saucer(0)
    for x in range(36):
        for y in range(15):
            v = s.get(int(x / 1.5), int(y / 1.5))
            yy = y0 - 12 + y + x // 5
            if v is not None and yy <= y0:
                c.px(x0 + x, yy, COLOR_NAMES[v])
    for x in range(x0 - 8, x0 + 44):
        hump = int(3 * math.sin(math.pi * (x - x0 + 8) / 52))
        for k in range(hump + 1):
            c.px(x, y0 - k, T["plain_line"] if k == hump else p0)
    c.px(x0 + 12, y0 - 8, "gold" if fr % 2 else "rose")
    k = smoke(fr)
    c.stamp(k.crop(0, 16, 30, 32), x0 + 8, y0 - 36)
    return c


# ------------------------------------------------------------------ terreno jogável (queijo)
def crust(face: str) -> Canvas:
    c = Canvas(SW, CRUST_D)
    r1, r2 = T["rim"][face]
    for x in range(SW):
        c.px(x, 0, T["ol"])
        c.px(x, 1, r1)
        t = 3 + int(round(2 * math.sin(math.pi * (x % 32) / 32)))
        for k in range(2, t + 1):
            c.px(x, k, r2)
        c.px(x, t + 1, T["ao"])
        if x % 2 == 0:
            c.px(x, t + 2, T["ao"])
    return c


def body() -> Canvas:
    c = Canvas(BODY_T, BODY_T, T["body"])
    for j, y0 in enumerate((14, 56, 98)):
        for x in range(BODY_T):
            a = y0 + 3 * math.sin(math.tau * x / BODY_T * 2 + j) + 2 * math.sin(math.tau * x / BODY_T * 3 + j * 2)
            th = 6 + 2 * math.sin(math.tau * x / BODY_T + j * 1.7)
            for y in range(int(a), int(a + th)):
                c.px(x, y % BODY_T, T["strata"])
            if x % 2 == 0:
                c.px(x, (int(a) - 1) % BODY_T, T["strata"])
    rng = random.Random(23)
    craters = [(rng.randrange(BODY_T), rng.randrange(BODY_T), r) for r in (6.5, 5, 4, 3.5, 3, 2.5, 2.5)]
    for x, y, r in craters:
        rx = r * 1.7
        for yy in range(int(y - r - 2), int(y + r + 3)):
            for xx in range(int(x - rx - 2), int(x + rx + 3)):
                d = ((xx + 0.5 - x) / rx) ** 2 + ((yy + 0.5 - y) / r) ** 2
                X, Y = xx % BODY_T, yy % BODY_T
                if d <= 1:
                    c.px(X, Y, T["hole_dark"] if (yy + 0.5 - y) / r < -0.15 else T["hole"])
                elif d <= 1.45 and yy + 0.5 > y:
                    c.px(X, Y, T["lip"] if yy + 0.5 > y + r * 0.6 else T["strata"])
    for _ in range(18):
        x, y = rng.randrange(BODY_T), rng.randrange(BODY_T)
        c.px(x, y, T["lip"]); c.px((x + 1) % BODY_T, y, T["pebble"]); c.px((x + 1) % BODY_T, (y + 1) % BODY_T, T["hole"])
    return c


def depth() -> Canvas:
    c = Canvas(SW, DEPTH_D)
    d0, d1, d2 = T["depth"]
    for x in range(SW):
        a = int(62 + 4 * math.sin(math.tau * x / 64) + 2 * math.sin(math.tau * x / 32 + 1))
        b = int(100 + 5 * math.sin(math.tau * x / 128 + 2) + 2 * math.sin(math.tau * x / 32))
        e = int(138 + 4 * math.sin(math.tau * x / 64 + 3))
        c.vline(x, a, b, d0)
        c.vline(x, b + 1, e, d1)
        c.vline(x, e + 1, DEPTH_D - 1, d2)
        if x % 2 == 0:
            c.px(x, a - 1, d0); c.px(x, b, d1); c.px(x, e, d2)
    return c


ROCK_SIZES = ms.ROCK_SIZES


def rocks_atlas() -> Canvas:
    """Pedrinhas (migalhas de queijo) redondas com volume e contorno colorido."""
    cw, ch = ms.ROCK_CELL
    c = Canvas(cw * len(ROCK_SIZES), ch)
    rh, rb, rs = T["rock"][0], T["rock"][1], T["ao"]
    for i, (w, h) in enumerate(ROCK_SIZES):
        k = Canvas(16, 8)
        cx, cy, rx, ry = 7.5, 7 - h / 2, w / 2, h / 2 - 0.01
        for y in range(8):
            for x in range(16):
                nx, ny = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
                if nx * nx + ny * ny <= 1:
                    j = -0.6 * nx - 0.75 * ny
                    k.px(x, y, rh if j > 0.55 else rb if j > -0.25 else rs)
        k.outline(T["ol"])
        cut = Canvas(16, 8)
        cut.stamp(k, 0, -1)
        c.stamp(cut, i * cw, 0)
    return c


# ------------------------------------------------------------------ sprites da guerra (o Godot anima)
def saucer(fr: int) -> Canvas:
    k = Canvas(24, 10)
    for y in range(1, 6):
        for x in range(7, 17):
            if ((x + 0.5 - 12) / 4.6) ** 2 + ((y + 0.5 - 5.5) / 4.2) ** 2 <= 1:
                k.px(x, y, "pale_sky" if x < 14 else "sky")
    k.px(11, 4, "leaf"); k.px(12, 4, "leaf"); k.px(11, 3, "leaf"); k.px(12, 3, "leaf")
    k.px(11, 3, "ink"); k.px(12, 3, "ink")
    sphere(k, 11.5, 6.5, 10.5, 2.2, ["white", "mist", "steel", "lilac_grey"])
    for j, x in enumerate((6, 11, 16)):
        k.px(x, 7, "hot_pink" if (fr + j) % 3 == 0 else "slate")
    k.outline("ink")
    return k


def saucer_far(fr: int) -> Canvas:
    k = Canvas(12, 6)
    k.ellipse(5.5, 2.2, 2, 1.5, "pale_sky")
    k.hline(2, 9, 3, "white")
    k.px(5 + fr, 3, "hot_pink")
    k.outline("ink")
    return k


def blast(fr: int) -> Canvas:
    c = Canvas(16, 16)
    if fr == 0:
        for d in range(5):
            for dx, dy in ((d, 0), (-d, 0), (0, d), (0, -d)):
                c.px(8 + dx, 8 + dy, "white" if d < 3 else "lemon")
        for d in (1, 2):
            for dx, dy in ((d, d), (-d, d), (d, -d), (-d, -d)):
                c.px(8 + dx, 8 + dy, "lemon")
    elif fr == 1:
        sphere(c, 8, 8, 4.5, 4.5, ["white", "lemon", "gold", "amber"])
    elif fr == 2:
        sphere(c, 8, 8, 6.5, 6.5, ["lemon", "gold", "amber", "orange"])
    else:
        rr = [5, 4, 2.5][fr - 3]
        k = Canvas(16, 16)
        hi, base, shade = T["smoke"]
        for dx, dy in ((-3, 1), (3, 1), (0, -2)):
            sphere(k, 8 + dx * (fr - 2) * 0.6, 8 + dy * (fr - 2) * 0.6 - (fr - 3), rr, rr, [hi, base, base, shade])
        k.outline(T["smoke_ol"])
        c.stamp(k)
    return c


def far() -> Canvas:
    """Sem colinas extras (os morros de trás já fazem a distância) — camada vazia mantém o contrato."""
    return Canvas(W, HORIZON + 1)


# ------------------------------------------------------------------ montagem
def build() -> dict:
    L = {"sky_frames": [sky(fr) for fr in range(SKY_FRAMES)], "planet": planet(), "far": far()}
    L["sky"] = L["sky_frames"][0]
    mbase, tops = mid_ground()
    mids = [mid_layer(mbase, tops, fr) for fr in range(FR)]
    L["mid_frames"] = [m[0] for m in mids]; L["mid"] = mids[0][0]
    L["war"] = {"muzzles": [list(m) for m in mids[0][1]], "targets": [list(t) for t in mids[0][2]]}
    L["plain_frames"] = [plain(fr) for fr in range(FR)]; L["plain"] = L["plain_frames"][0]
    for f in ("lit", "flat", "shade"):
        L[f] = crust(f)
    L["body"], L["depth"], L["rocks"] = body(), depth(), rocks_atlas()
    L["saucer"], L["saucer_far"], L["blast"] = saucer(1), saucer_far(0), blast(2)
    return L


def scene(L: dict, lander=None, extras: bool = True) -> Canvas:
    import moon_ground as mg
    cv = Canvas(W, H)
    cv.stamp(L["sky"]); cv.stamp(L["planet"], PLANET[0] - PLANET[2] - 12, PLANET[1] - PLANET[2] - 12)
    cv.stamp(L["far"]); cv.stamp(L["mid"]); cv.stamp(L["plain"], 0, PLAIN_TOP)
    pad = ms.PREVIEW_PAD
    pts = profile(W, seed=7, base=292, amp=60, pad=pad)
    faces = ms.segment_faces(pts)
    G = {"body": L["body"], "depth": L["depth"], **{"crust_" + f: L[f] for f in ("lit", "flat", "shade")}}
    mg.compose(cv, lambda x: ridge_y(pts, x), 0, W,
               lambda x: faces[min(sum(1 for p in pts[1:] if p[0] <= x), len(faces) - 1)], G)
    rng = random.Random(31)
    cw, ch = ms.ROCK_CELL
    for _ in range(18):
        x = rng.randrange(8, W - 8)
        if pad[0] - 12 < x < pad[0] + pad[1] + 12:
            continue
        i = rng.randrange(len(ROCK_SIZES))
        cv.stamp(L["rocks"].crop(i * cw, 0, cw, ch), x - cw // 2, ridge_y(pts, x) + rng.randint(0, 2) - 6)
    py = ridge_y(pts, pad[0] + pad[1] // 2)
    cv.stamp(Canvas.from_image("assets/sprites/landing_pad.png").crop(0, 0, 80, 28), pad[0] - 8, py - 10)
    if extras:
        cv.stamp(L["saucer"], 120, 128); cv.stamp(L["saucer_far"], 580, 150)
    if lander is not None:
        cv.stamp(lander, pad[0] + pad[1] // 2 - 16, py - 25)
    return cv


def export(L: dict) -> None:
    au.stack(L["sky_frames"]).save("assets/bg/luna_sky.png", preview=False)
    L["planet"].save("assets/bg/luna_planet.png", preview=False)
    L["far"].save("assets/bg/luna_far.png", preview=False)
    au.stack(L["mid_frames"]).save("assets/bg/luna_mid.png", preview=False)
    au.stack(L["plain_frames"]).save("assets/bg/luna_plain.png", preview=False)
    for f in ("lit", "flat", "shade"):
        L[f].save(f"assets/tiles/luna_ground_{f}.png", preview=False)
    L["body"].save("assets/tiles/luna_body.png", tiled=True, preview=False)
    L["depth"].save("assets/tiles/luna_depth.png", preview=False)
    L["rocks"].save("assets/sprites/luna_rocks.png", preview=False)
    for name, fn, n in (("war_saucer", saucer, 4), ("war_saucer_far", saucer_far, 2), ("war_blast", blast, 6)):
        frames = [fn(i) for i in range(n)]
        sheet = Canvas(frames[0].w * n, frames[0].h)
        for i, f in enumerate(frames):
            sheet.stamp(f, i * f.w, 0)
        sheet.save(f"assets/sprites/{name}.png", preview=False)
    with open("assets/bg/luna_layers.json") as f:
        meta = json.load(f)
    cx, cy, r = PLANET
    meta.update({
        "notes": "Gerado por art/src/bg/moon_cute.py (pixel-art, estilo fofo, Lua de queijo). Posições em px na tela 640x360.",
        "planet_pos": [cx - r - 12, cy - r - 12], "strip_depth": CRUST_D, "depth_depth": DEPTH_D,
        "deep_color": "#" + "%02x%02x%02x" % tuple(PALETTE_RGB[resolve(T["depth"][2])]),
    })
    meta["war"].update(L["war"])
    with open("assets/bg/luna_layers.json", "w") as f:
        json.dump(meta, f, indent=2)


if __name__ == "__main__":
    L = build()
    if "--export" in sys.argv:
        export(L)
        print("assets exportados")
    else:
        lander = Canvas.from_image("assets/sprites/lander.png").crop(0, 0, 32, 32)
        cv = scene(L, lander)
        print("cores:", len(cv.colors_used()), {k: L[k].lint(wrap=True) for k in ("lit", "body")})
        cv.save("art/previews/moon_cute.png", preview=False)
