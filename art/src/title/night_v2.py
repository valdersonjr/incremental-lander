"""Noite de história v2 (2026-10-09): lua crescente EM PÉ (como a da DreamWorks: barriga à esquerda, pontas para a
direita, o pescador sentado na ponta de baixo com a linha caindo) e mais detalhe em tudo. Skill pixel-art, padrões
title-screen + cute-scene-method (cel em poucos tons, contorno colorido, luz de cima-esquerda, todo objeto com motivo).
Pedido: "seria mais legal se a lua fosse em pé, igual a da dreamworks. E também melhor o nível de detalhamento".
  céu    — 7 tons, faixa de via láctea (estrelinhas densas na diagonal), nebulosa em pontilhado, estrelas de 3
           tamanhos, planetinha de anel ao longe
  lua    — esfera iluminada de cima-esquerda em 5 tons, recortada por um círculo deslocado para a direita
           (terminador com sombra), contorno rust, brilho de borda no lado da luz, halo pontilhado no céu, furos de
           queijo com profundidade (parede de cima na sombra, de baixo-direita na luz, lábio claro), textura de
           pintinhas e um pingo de queijo escorrendo da ponta de baixo
  nuvens — duas camadas: banco de trás mais escuro e alto, banco da frente com volume (topo claro, sombra embaixo
           de cada bolota) e nuvenzinhas soltas
  pescador — gatinho sentado na ponta de baixo (perninhas para fora), varinha com carretel, linha com brilho e a
           estrelinha dormindo 2x com brilhos em volta
"""
import math
import random
import sys

sys.path.insert(0, ".claude/skills/pixel-art/scripts")
for p in ("art/src/bg", "art/src/sprites", "art/src/title"):
    sys.path.insert(0, p)
from pixelart import *
import moon_cute as mc
import cat_hero as ch
import title_concepts as tc

W, H = 640, 360
BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
OUTER = (456, 170, 148)                                         # círculo da lua
INNER = (516, 150, 132)                                         # círculo que recorta (deslocado p/ direita e cima)
LIGHT = (-0.55, -0.65, 0.52)


def bayer(x: int, y: int, level: float) -> bool:
    """True em `level` (0..1) dos pixels, no padrão Bayer 4x4 (transição reta e limpa)."""
    return BAYER[y % 4][x % 4] < level * 16


def in_moon(x: float, y: float) -> bool:
    (ax, ay, ar), (bx, by, br) = OUTER, INNER
    return (x - ax) ** 2 + (y - ay) ** 2 <= ar * ar and (x - bx) ** 2 + (y - by) ** 2 > br * br


# ------------------------------------------------------------------ céu
SKY_STOPS = [(0, "navy"), (100, "indigo"), (190, "plum_dark"), (270, "plum"), (361, "purple")]


def sky() -> Canvas:
    cv = Canvas(W, H)
    for y in range(H):
        for i in range(len(SKY_STOPS) - 1):
            y0, c0 = SKY_STOPS[i]
            y1, c1 = SKY_STOPS[i + 1]
            if y0 <= y < y1:
                break
        t = (y - y0) / (y1 - y0)
        for x in range(W):                                      # degradê com transição Bayer só nos 18 px de troca
            k = max(0.0, (t - 1) * (y1 - y0) / 18 + 1)
            cv.px(x, y, c1 if bayer(x, y, k) else c0)
    rng = random.Random(51)
    for _ in range(900):                                        # nebulosa: nuvem de pontinhos violeta numa faixa
        x = rng.randrange(W)
        y = int(120 + 70 * math.sin(x / 140) + rng.gauss(0, 26))
        if 0 <= y < H and rng.random() < 0.55:
            cv.px(x, y, rng.choice(["purple", "plum", "violet"]) if rng.random() < 0.8 else "berry_dark")
    for _ in range(420):                                        # via láctea: estrelinhas densas na diagonal
        u = rng.random()
        x = int(W * u + rng.gauss(0, 18))
        y = int(260 - 240 * u + rng.gauss(0, 22))
        if 0 <= x < W and 0 <= y < H:
            cv.px(x, y, rng.choice(["lavender", "pale_sky", "white", "violet"]))
    for _ in range(140):                                        # estrelas soltas
        cv.px(rng.randrange(W), rng.randrange(0, 300), rng.choice(["white", "pale_sky", "lemon", "cream", "lavender"]))
    for x, y in ((206, 40), (330, 24), (600, 120), (250, 210), (612, 30)):   # estrelas médias (cruzinha)
        cv.px(x, y, "white")
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            cv.px(x + dx, y + dy, "lavender")
    mc.ringed(cv, 262, 150)                                     # planetinha de anel ao longe
    return cv


# ------------------------------------------------------------------ lua em pé
HOLES = [(360, 120, 13), (338, 196, 9), (392, 250, 15), (372, 60, 7), (414, 168, 6), (360, 290, 7), (402, 92, 5),
         (440, 300, 8), (326, 150, 5)]


def moon() -> Canvas:
    cv = Canvas(W, H)
    ax, ay, ar = OUTER
    bx, by, br = INNER
    lx, ly, lz = LIGHT
    for y in range(ay - ar - 12, ay + ar + 12):                # halo pontilhado no céu (mais forte no lado da luz)
        for x in range(ax - ar - 12, ax + ar + 12):
            d = math.hypot(x + 0.5 - ax, y + 0.5 - ay) - ar
            if 0 < d < 11 and not in_moon(x + 0.5, y + 0.5) and (x - bx) ** 2 + (y - by) ** 2 > (br - 6) ** 2:
                side = max(0.0, -((x - ax) * 0.8 + (y - ay) * 0.6) / ar)    # 1 no lado de cima-esquerda
                if bayer(x, y, (1 - d / 11) * (0.12 + 0.3 * side)):
                    cv.px(x, y, "violet" if d < 4 else "purple")
    for y in range(H):
        for x in range(ax - ar - 1, ax + ar + 2):
            if not in_moon(x + 0.5, y + 0.5):
                continue
            nx, ny = (x + 0.5 - ax) / ar, (y + 0.5 - ay) / ar
            nz = math.sqrt(max(0.0, 1 - nx * nx - ny * ny))
            i = nx * lx + ny * ly + nz * lz                     # luz de cima-esquerda (normal . luz)
            din = math.hypot(x + 0.5 - bx, y + 0.5 - by) - br   # distância até o terminador (borda de dentro)
            if din < 5:
                i -= 0.35 * (1 - din / 5)                       # sombra colada no terminador
            col = "white" if i > 1.02 else "lemon" if i > 0.72 else "gold" if i > 0.42 else "amber" if i > 0.15 \
                else "copper"
            cv.px(x, y, col)
    for hx, hy, r in HOLES:                                     # furos de queijo com profundidade
        rx, ry = r, r * 0.72
        for y in range(int(hy - ry) - 1, int(hy + ry) + 2):
            for x in range(hx - r - 1, hx + r + 2):
                u, v = (x + 0.5 - hx) / rx, (y + 0.5 - hy) / ry
                if u * u + v * v > 1 or cv.get(x, y) is None:
                    continue
                wall = u * 0.6 + v * 0.8                        # >0: parede de baixo-direita (recebe a luz)
                col = "gold" if wall > 0.55 else "amber" if wall > 0.1 else "copper" if wall > -0.5 else "rust"
                if u * u + v * v > 0.72 and wall > 0.3:
                    col = "lemon"                               # lábio claro na borda de baixo
                cv.px(x, y, col)
    rng = random.Random(61)
    for _ in range(260):                                        # pintinhas (textura) por tom
        x, y = rng.randrange(ax - ar, ax + ar), rng.randrange(ay - ar, ay + ar)
        c = cv.get(x, y)
        swap = {NAME_TO_INDEX["gold"]: "honey", NAME_TO_INDEX["lemon"]: "gold", NAME_TO_INDEX["amber"]: "copper"}
        if c in swap and in_moon(x + 2.5, y + 0.5) and in_moon(x - 1.5, y + 0.5):
            cv.px(x, y, swap[c])
    drip_x, drip_y = tip_bottom()                               # pingo de queijo escorrendo da ponta de baixo
    for y in range(drip_y - 2, drip_y + 9):
        w = 2 if y < drip_y + 5 else 3 if y < drip_y + 8 else 2
        for x in range(drip_x - w // 2, drip_x + (w + 1) // 2 + 1):
            cv.px(x, y, "gold" if x > drip_x else "lemon")
    cv.outline("rust")
    for y in range(H):                                          # brilho de borda no lado da luz (1 px dentro)
        for x in range(ax - ar, ax):
            if in_moon(x + 0.5, y + 0.5) and not in_moon(x - 0.5, y + 0.5) and y < ay + 60:
                cv.px(x, y, "white" if y < ay - 30 else "lemon")
    return cv


def tip_bottom() -> tuple:
    """Ponta de baixo da crescente = interseção de baixo dos dois círculos (o pingo escorre um pouco antes dela)."""
    (ax, ay, ar), (bx, by, br) = OUTER, INNER
    d = math.hypot(bx - ax, by - ay)
    a = (ar * ar - br * br + d * d) / (2 * d)
    h = math.sqrt(max(0.0, ar * ar - a * a))
    mx, my = ax + a * (bx - ax) / d, ay + a * (by - ay) / d
    pts = [(mx + h * (by - ay) / d, my - h * (bx - ax) / d), (mx - h * (by - ay) / d, my + h * (bx - ax) / d)]
    px_, py_ = max(pts, key=lambda p: p[1])
    x = int(px_ - 16)                                          # um pouco para dentro, onde ainda há espessura
    y = max(yy for yy in range(H) if in_moon(x + 0.5, yy + 0.5))
    return x, y


def seat() -> tuple:
    """Onde o gatinho senta: a superfície de dentro (terminador) da ponta de baixo, num trecho quase plano."""
    bx, by, br = INNER
    x = 478
    return x, int(by + math.sqrt(br * br - (x - bx) ** 2))


# ------------------------------------------------------------------ nuvens
def _bank(seed: int, base: float, amp: tuple, step: int, ramp: list, ol: str) -> Canvas:
    rng = random.Random(seed)
    bumps = [(x + rng.randrange(-6, 7), base - rng.uniform(*amp), rng.uniform(14, 26)) for x in range(-20, W + 30, step)]
    cv = Canvas(W, H)
    for x in range(W):
        top = H
        own = None
        for bx, cy, r in bumps:
            if abs(x - bx) < r:
                t = cy - math.sqrt(r * r - (x - bx) ** 2) + r * 0.5
                if t < top:
                    top, own = t, (bx, cy, r)
        top = int(min(top, base + 6))
        for y in range(top, H):
            d = y - top
            col = ramp[0] if d < 2 else ramp[1] if d < 9 else ramp[2]
            if own is not None and d >= 2:                      # sombra embaixo de cada bolota (volume)
                bx, cy, r = own
                if (x - bx) ** 2 / (r * r) + (y - (cy + r * 0.9)) ** 2 / (r * r * 0.3) <= 1 and d > 5:
                    col = ramp[2]
            if y > base + 22:
                col = ramp[3] if bayer(x, y, min(1.0, (y - base - 22) / 16)) else col
            cv.px(x, y, col)
        cv.px(x, top - 1, ol)
    return cv


def clouds() -> tuple:
    back = _bank(71, 318, (4, 16), 34, ["violet", "purple", "plum", "plum_dark"], "plum_dark")
    front = _bank(72, 336, (2, 12), 28, ["white", "lavender", "violet", "purple"], "indigo")
    puffs = Canvas(W, H)
    old = mc.T["cloud"], mc.T["cloud_ol"]
    mc.T["cloud"], mc.T["cloud_ol"] = ["white", "lavender", "violet"], "indigo"
    for x, y, kind, flip in ((230, 300, "pequena", False), (610, 286, "pequena", True), (140, 314, "grande", True)):
        mc.cloud(puffs, x, y, kind, flip)
    mc.T["cloud"], mc.T["cloud_ol"] = old
    return back, front, puffs


# ------------------------------------------------------------------ pescador
def sleepy_star() -> Canvas:
    s = Canvas(15, 15)
    s.polygon([(7, 0), (9, 5), (14, 5), (10, 9), (12, 14), (7, 11), (2, 14), (4, 9), (0, 5), (5, 5)], "lemon")
    for x, y in ((9, 7), (10, 8), (8, 10), (11, 9), (6, 11)):
        s.px(x, y, "gold")
    s.px(6, 4, "white"); s.px(6, 5, "white"); s.px(5, 6, "white")
    s.px(4, 8, "ink"); s.px(5, 8, "ink"); s.px(9, 8, "ink"); s.px(10, 8, "ink")   # olhinhos fechados
    s.px(7, 9, "salmon"); s.px(3, 9, "pink"); s.px(11, 9, "pink")
    s.outline("ink")
    return mc.scale2x(s)


def draw_fisher(cv: Canvas, fr: int) -> None:
    sx, sy = seat()
    cat = ch.body("hold", "float", blink=fr == 15, tail_up=2 if (fr // 4) % 2 else 0, k=tc.HERO_K,
                  breathe=1 if (fr // 4) % 2 else 0)
    cx = sx - cat.w // 2
    cy = sy - tc.feet(cat) + 18                                 # sentado na ponta: perninhas para fora da borda
    cv.stamp(cat, cx, cy)
    hand = (cx + round(38 * tc.HERO_K), cy + round(52 * tc.HERO_K))
    tip = (hand[0] + 56, hand[1] - 70)
    for d, col in ((0, "ink"), (1, "copper"), (2, "honey"), (3, "ink")):   # varinha de bambu
        cv.line(hand[0] + d, hand[1], tip[0] + d, tip[1], col)
    for t in (0.33, 0.66):                                      # nós do bambu
        x, y = int(hand[0] + (tip[0] - hand[0]) * t), int(hand[1] + (tip[1] - hand[1]) * t)
        cv.rect(x, y, 4, 1, "rust")
    rx, ry = hand[0] + 9, hand[1] - 9                           # carretelzinho
    mc.sphere(cv, rx, ry, 3, 3, ["mist", "steel", "steel", "lilac_grey"])
    cv.px(rx, ry, "ink")
    sway = round(6 * math.sin(math.tau * fr / 16))
    end = (tip[0] + 2 + sway, 300)
    cv.line(tip[0] + 2, tip[1], end[0], end[1], "pale_sky")     # linha de pesca
    gl = tip[1] + int((end[1] - tip[1]) * ((fr % 16) / 16))     # brilho correndo pela linha
    gx = int(tip[0] + 2 + (end[0] - tip[0] - 2) * (gl - tip[1]) / max(1, end[1] - tip[1]))
    cv.px(gx, gl, "white")
    star = sleepy_star()
    cv.stamp(star, end[0] - star.w // 2, end[1] - 2)
    for i, (dx, dy) in enumerate(((-20, 6), (19, -2), (16, 24), (-16, 26))):   # brilhinhos em volta, um por tempo
        if fr // 4 == i:
            mc.sparkle(cv, end[0] + dx, end[1] + dy, 2)


def static() -> tuple:
    back, front, puffs = clouds()
    return sky(), moon(), back, front, puffs


TWINKLE = [(random.Random(300 + i).randrange(180, W), random.Random(400 + i).randrange(6, 230)) for i in range(16)]


def frame(fr: int, st: tuple) -> Canvas:
    sky_, moon_, back, front, puffs = st
    cv = sky_.copy()
    for i, (x, y) in enumerate(TWINKLE):
        if (fr // 2 + i * 5) % 8 < 2:
            mc.sparkle(cv, x, y, 2)
    cv.stamp(back)
    cv.stamp(moon_)
    draw_fisher(cv, fr)
    cv.stamp(front)
    cv.stamp(puffs, round(2 * math.sin(math.tau * fr / 16)), 0)
    return cv
