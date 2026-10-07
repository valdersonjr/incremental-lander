"""Tela de título: 3 CONCEITOS para o usuário escolher (2026-10-06). Skill pixel-art, padrões title-screen +
cute-scene-method (kit de morros/nuvens da Lua de queijo + Scale2x, céu degradê, poucos elementos grandes).

Pesquisa (patterns/title-screen.md): um foco forte que diz do que é o jogo; o herói num momento de carisma; cena
viva mas calma (piscar, aceno, brilhos); o botão Jogar é o mais forte; terço esquerdo livre para logo + menu.
  A "Vitrine"    — gatinho acenando no alto do morro de queijo, ao lado da nave pousada; Terra dormindo; ratinhos
                   espiando atrás do morro; bandeirinha que o gato acabou de fincar.
  B "Passeio"    — no espaço: gatinho flutuando preso por um cabo à nave; a Lua de queijo enorme embaixo.
  C "Plataforma" — plataforma de partida: gatinho segurando o pacote, ratinhos trazendo cargas, nave esperando.
Saída: art/previews/title_concepts/ (PNG 2x + GIF por conceito, com/sem menu, logo desenhado/fonte) + index.html.
Rodar da raiz: python3 art/src/title/title_concepts.py   (~20 s; frames em paralelo)
"""
import math
import os
import random
import sys
from concurrent.futures import ProcessPoolExecutor

sys.path.insert(0, ".claude/skills/pixel-art/scripts")
for p in ("art/src/bg", "art/src/terrain", "art/src/sprites", "art/src/ui"):
    sys.path.insert(0, p)
from pixelart import *
import moon_cute as mc
import moon_mine as mm
import moon_props as mp
import cat_hero as ch
import cargo as cg
import kids_ui as ku
import ui_kit as uk
import logo as lg
from pixel_font import draw_text, text_width

W, H = 640, 360
OUT = "art/previews/title_concepts"
FR = 16                                                        # quadros do laço (16 x 150 ms)
FRAME_MS = 150
CHEESE = ["lemon", "gold", "gold", "amber"]
WAVE = ["wave0", "wave1", "wave2", "wave1", "wave2", "wave1", "wave0", "stand", "stand", "stand", "stand", "blink",
        "stand", "stand", "stand", "stand"]


# ------------------------------------------------------------------ peças
def big_lander(flame: int = -1) -> Canvas:
    """A nave em versão "pôster" (80x70, mesma escala de pixel): cúpula VAZIA (o piloto saiu), disco branco com
    faixa sea, luzinhas, pernas com sapatas. flame >= 0 desenha o plasma (4 quadros)."""
    k = Canvas(80, 70)
    if flame >= 0:
        ln = [12, 15, 13, 16][flame % 4]
        for i, col in enumerate(["navy", "teal", "sea", "aqua", "ice", "white"]):
            w = 7 - i
            mc.sphere(k, 40, 52 + ln * (1 - i / 7) * 0.9, max(1.5, w), ln * (1 - i / 8) * 0.55 + 2,
                      [col, col, col, col])
    # cúpula
    for y in range(k.h):
        for x in range(k.w):
            if ((x + 0.5 - 40) / 19) ** 2 + ((y + 0.5 - 24) / 17) ** 2 <= 1 and y <= 34:
                k.px(x, y, "sky" if (x - 40) * 0.8 + (y - 24) * 0.6 > 6 else "pale_sky")
    k.rect(33, 27, 14, 6, "steel"); k.hline(33, 46, 27, "mist")             # banquinho do piloto (vazio)
    k.rect(35, 21, 10, 6, "lilac_grey"); k.hline(35, 44, 21, "steel")
    for a in range(200, 262, 4):                                             # reflexo
        x = 40 + 15 * math.cos(math.radians(a)); y = 24 + 13 * math.sin(math.radians(a))
        k.px(int(x), int(y), "white"); k.px(int(x) + 1, int(y), "white")
    # casco (disco)
    rows = {34: (16, 63), 35: (10, 69), 36: (7, 72), 37: (6, 73), 38: (6, 73), 39: (7, 72), 40: (9, 70), 41: (13, 66)}
    for y, (x0, x1) in rows.items():
        k.hline(x0, x1, y, "white" if y <= 35 else "mist")
        k.hline(max(x0, 58), x1, y, "steel" if y < 39 else "lilac_grey")
    k.hline(6, 73, 38, "sea"); k.hline(7, 72, 39, "teal")
    k.hline(18, 61, 34, "slate"); k.hline(24, 55, 34, "charcoal")
    for i, x in enumerate((12, 22, 32, 47, 57, 67)):
        k.px(x, 36, "aqua" if i % 2 else "hot_pink"); k.px(x + 1, 36, "aqua" if i % 2 else "hot_pink")
    k.rect(33, 42, 14, 3, "slate"); k.rect(35, 45, 10, 3, "charcoal")       # bocal
    for x0, s in ((18, -1), (61, 1)):                                         # pernas
        k.line(x0, 41, x0 + s * 7, 58, "steel"); k.line(x0 + 1, 41, x0 + s * 7 + 1, 58, "mist" if s < 0 else "lilac_grey")
        k.rect(x0 + s * 7 - 4, 59, 10, 3, "steel"); k.hline(x0 + s * 7 - 4, x0 + s * 7 + 5, 59, "mist")
    k.outline("ink")
    return k


def parcel() -> Canvas:
    """Pacote de entrega na escala do gatinho herói (28x22): papelão, fita, coraçãozinho."""
    k = Canvas(28, 22)
    k.rect(0, 4, 28, 18, "copper"); k.rect(0, 4, 28, 3, "honey"); k.rect(22, 7, 6, 15, "terracotta")
    k.polygon([(0, 4), (4, 0), (27, 0), (27, 4)], "honey"); k.hline(4, 26, 1, "lemon")
    k.rect(12, 0, 4, 22, "cream"); k.vline(15, 0, 21, "peach")
    for x, y in ((5, 11), (6, 10), (7, 11), (8, 10), (9, 11)):
        k.px(x, y, "hot_pink")
    k.rect(6, 11, 3, 2, "hot_pink"); k.px(7, 13, "hot_pink")
    k.outline("ink")
    return k


def flag(fr: int = 0) -> Canvas:
    """Bandeira que o gatinho acabou de fincar (34x50, escala do herói): mastro, flâmula com patinha, tremula."""
    k = Canvas(36, 50)
    k.rect(3, 3, 2, 46, "mist"); k.vline(5, 3, 48, "steel")
    wob = [0, 1, 2, 1][(fr // 2) % 4]
    top = [(6, 4), (16, 6 + wob), (24, 5), (33, 9 - wob // 2)]
    bot = [(33, 17 - wob // 2), (24, 15), (16, 18 + wob), (6, 20)]
    k.polygon(top + bot, "hot_pink")
    k.polygon([(6, 4), (16, 6 + wob), (24, 5), (33, 9 - wob // 2), (33, 11 - wob // 2), (24, 7), (16, 9 + wob),
               (6, 7)], "pink")
    k.polygon([(6, 18), (16, 16 + wob), (24, 13), (33, 15 - wob // 2), (33, 17 - wob // 2), (24, 15),
               (16, 18 + wob), (6, 20)], "raspberry")
    px, py = 14, 11 + wob // 2                                   # patinha branca
    mc.disc(k, px + 0.5, py + 2.5, 2.6, "white")
    for dx, dy in ((-3, -2), (-1, -4), (2, -4), (4, -2)):
        k.px(px + dx, py + dy, "white"); k.px(px + dx + 1, py + dy, "white")
    mc.sphere(k, 4.5, 2.5, 2.6, 2.6, ["white", "lemon", "gold", "amber"])
    k.outline("ink")
    return k


def cheese_hill(points: list, holes: list, seed: int) -> Canvas:
    """Morro de queijo do kit (meia res. + cel + contorno rust + Scale2x) com furinhos."""
    hs = mc.profile_from(points)
    h = int(max(hs)) + 2
    k = Canvas(len(hs), h)
    for x, hh in enumerate(hs):
        if hh >= 0.5:
            k.vline(x, int(h - 1 - hh), h - 1, CHEESE[2])
    mc.shade_piece(k, CHEESE, h - 1, 6, ao=2)
    for fx, fy, r in holes:                                    # furinhos (meia resolução, depois do sombreado)
        x, y = int(fx * k.w), int(h - 1 - fy * h)
        for yy in range(y - r, y + r + 1):
            for xx in range(x - r - 1, x + r + 2):
                if ((xx - x) / (r + 0.6)) ** 2 + ((yy - y) / r) ** 2 <= 1 and k.get(xx, yy) is not None:
                    k.px(xx, yy, "amber" if yy < y else "copper")
    k.outline("rust", inside=True)
    return mc.scale2x(k)


HERO_K = 1.6


def hero(pose: str = "rest", legs: str = "stand", blink: bool = False, tail_up: int = 0, breathe: int = 0) -> Canvas:
    return ch.body(pose, legs, blink, tail_up, k=HERO_K, breathe=breathe)


def feet(k: Canvas) -> int:
    """Última linha opaca (onde o sprite pisa)."""
    return max(y for _, y in k.opaque())


def tops_of(k: Canvas) -> list:
    return [next((y for y in range(k.h) if k.get(x, y) is not None), k.h) for x in range(k.w)]


def sky_canvas(stops: list, stars: int, seed: int) -> Canvas:
    old = mc.T["sky"]
    mc.T["sky"] = stops
    cv = Canvas(W, H)
    for y in range(H):
        for x in range(W):
            cv.px(x, y, mc.sky_color(x, y))
    mc.T["sky"] = old
    rng = random.Random(seed)
    for _ in range(stars):
        x, y = rng.randrange(W), int(rng.random() ** 1.4 * 150)
        cv.px(x, y, "cream" if y < 70 else "peach")
    return cv


def sparkles(cv: Canvas, pts: list, fr: int) -> None:
    for i, (x, y, s) in enumerate(pts):
        size = max(1, s - [0, 1, 2, 1][(fr // 2 + i) % 4])
        mc.sparkle(cv, x, y, size)


def ground(cv: Canvas, top: int) -> None:
    """Chão de queijo na frente (faixa clara, corpo dourado, furinhos)."""
    for x in range(W):
        y0 = top + int(mc.wave(x, 5, 2, freqs=(2, 3, 5)))
        for y in range(y0, H):
            cv.px(x, y, "lemon" if y < y0 + 2 else "gold" if y < y0 + 16 else "amber")
        cv.px(x, y0 - 1, "rust")
    rng = random.Random(9)
    for _ in range(9):
        x, y, r = rng.randrange(20, W - 20), rng.randint(top + 8, H - 6), rng.randint(3, 7)
        for yy in range(y - r // 2, y + r // 2 + 1):
            for xx in range(x - r, x + r + 1):
                if ((xx - x) / r) ** 2 + ((yy - y) / (r / 2 + 0.5)) ** 2 <= 1:
                    cv.px(xx, yy, "copper" if yy < y else "amber")


# ------------------------------------------------------------------ cenas (fundo fixo + animado por quadro)
STAGE = [(0, 0), (10, 22), (22, 36), (36, 42), (56, 44), (74, 43), (90, 36), (102, 20), (108, 0)]


def scene_a_static() -> tuple:
    cv = sky_canvas(mc.T["sky"], 30, 4)
    cv.stamp(mc.planet(), 548 - 50, 84 - 50)
    sky = cv
    cv = Canvas(W, H)                                            # frente: tudo que fica na frente das nuvens
    back = Canvas(W, 300)
    for name, x, flip in (("grande_fundo", 160, False), ("fundo_alto", 380, True), ("grande_fundo", 470, True)):
        k = mc.piece(name, flip, mc.T["back"], None, 4, ao=0)
        back.stamp(k, x, 300 - k.h)
    for x in range(W):
        for y in range(286, 300):
            if back.get(x, y) is not None:
                back.px(x, y, mc.T["back_haze"])
    cv.stamp(back)
    hill = cheese_hill(STAGE, [(0.2, 0.35, 3), (0.42, 0.6, 2), (0.7, 0.3, 4), (0.86, 0.55, 2)], 3)
    hx, hy = 278, 330 - hill.h
    tops = tops_of(hill)
    mice = [(ku.mouse_simple(), 562), (ku.mouse_soft(), 590)]
    for face, x in mice:                                         # ratinhos espiando por trás do morro
        cv.stamp(face, x, hy + tops[x + 12 - hx] - 16)
    cv.stamp(hill, hx, hy)
    for face, x in mice:                                         # patinhas apoiadas na beira (não flutuam)
        ry = hy + tops[x + 12 - hx]
        for dx in (6, 17):
            paw = Canvas(7, 5)
            mc.sphere(paw, 3.5, 2.5, 3, 2, ["white", "white", "cream", "peach"])
            paw.outline("ink")
            cv.stamp(paw, x + dx - 3, ry - 3)
    ground(cv, 326)
    for hx2, hy2, r in ((120, 346, 12), (236, 340, 7), (420, 352, 9)):   # furos grandes no queijo de perto
        for yy in range(hy2 - r // 2, hy2 + r // 2 + 1):
            for xx in range(hx2 - r, hx2 + r + 1):
                if ((xx - hx2) / r) ** 2 + ((yy - hy2) / (r / 2 + 0.5)) ** 2 <= 1:
                    cv.px(xx, yy, "copper" if yy < hy2 else "terracotta")
    chunk = cheese_hill([(0, 0), (6, 14), (12, 20), (18, 21), (24, 17), (30, 8), (34, 0)], [(0.35, 0.45, 3)], 7)
    cv.stamp(chunk, W - chunk.w + 14, H - chunk.h + 12)          # pedaço de queijo de perto (moldura, profundidade)
    return (sky, cv), (hx, hy, tops)


def shooting_star(cv: Canvas, fr: int, start: int, x0: int, y0: int) -> None:
    """Estrela cadente: 4 quadros a partir de `start`, cabeça branca e rastro creme/pêssego."""
    t = fr - start
    if not 0 <= t < 4:
        return
    hx, hy = x0 - t * 30, y0 + t * 12
    tail = ["white"] * 3 + ["cream"] * 4 + ["peach"] * 4 + ["salmon"] * 3
    for i, col in enumerate(tail[: 6 + t * 3]):
        x, y = hx + int(i * 2.5), hy - i
        cv.px(x, y, col); cv.px(x + 1, y, col)
        if i < 5:
            cv.px(x, y + 1, col); cv.px(x + 1, y + 1, col)
    mc.sparkle(cv, hx, hy, 2)


A_CLOUDS = ((338, 128, "grande", False), (612, 196, "pequena", True), (262, 214, "pequena", False))
TWINKLE = [(random.Random(i).randrange(240, W), random.Random(i + 99).randrange(8, 120)) for i in range(10)]


def scene_a(fr: int, static) -> Canvas:
    (base, fore), (hx, hy, tops) = static
    cv = base.copy()
    for i, (x, y) in enumerate(TWINKLE):                          # estrelas cintilando devagar
        ph = (fr // 2 + i * 3) % 8
        if ph in (0, 1):
            cv.px(x, y, "white")
        if ph == 0:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                cv.px(x + dx, y + dy, "cream")
    for i, (x, y, kind, flip) in enumerate(A_CLOUDS):              # nuvens à deriva (atrás dos morros)
        mc.cloud(cv, x + round(3 * math.sin(math.tau * fr / FR + i)), y, kind, flip)
    cv.stamp(fore)
    sparkles(cv, [(232, 96, 3), (420, 60, 2), (612, 140, 2)], fr)
    shooting_star(cv, fr, 9, 470, 30)
    fl = flag(fr)
    fx = 446
    cv.stamp(fl, fx, hy + tops[fx + 4 - hx] - fl.h + 3)
    ship = big_lander()
    sx = 478
    sy = hy + min(tops[sx - hx + 10], tops[sx - hx + 70]) - 61 + 1
    cv.stamp(ship, sx, sy)
    for i, x in enumerate((12, 22, 32, 47, 57, 67)):              # luzinhas do disco piscam em sequência
        if (fr // 2) % 6 == i:
            cv.rect(sx + x, sy + 36, 2, 1, "white")
    pose = WAVE[fr % len(WAVE)]
    tail = 2 if (fr // 3) % 2 else 0                              # rabo balança
    br = 1 if (fr // 4) % 2 else 0                                # respiração (capacete desce 1 px)
    cat = hero(pose="rest" if pose == "blink" else pose.replace("stand", "rest"), blink=pose == "blink",
               tail_up=tail, breathe=br)
    cx = 376
    ground_y = hy + min(tops[cx - hx - 20], tops[cx - hx + 20])
    for x in range(cx - 26, cx + 27):                             # sombrinha no queijo (não flutua)
        dy = 1 - ((x - cx) / 26) ** 2
        for y in range(ground_y + 1, ground_y + 1 + int(3 * dy) + 1):
            if cv.get(x, y) in (NAME_TO_INDEX["gold"], NAME_TO_INDEX["lemon"], NAME_TO_INDEX["amber"]):
                cv.px(x, y, "amber" if dy > 0.4 else "gold")
    cv.stamp(cat, cx - cat.w // 2, ground_y - feet(cat) + 2)
    return cv


def scene_b_static() -> tuple:
    stops = [(0, "navy"), (70, "indigo"), (140, "plum"), (200, "berry"), (250, "rose")]
    cv = sky_canvas(stops, 70, 11)
    rng = random.Random(12)
    for _ in range(40):
        x, y = rng.randrange(W), rng.randrange(0, 200)
        cv.px(x, y, rng.choice(["white", "pale_sky", "lavender"]))
    earth = mc.planet()
    cv.stamp(earth, 560 - 50, 64 - 50)
    # Lua de queijo enorme embaixo (esfera com furinhos), centro fora da tela
    mx, my, r = 440, 600, 340
    for y in range(250, H):
        for x in range(W):
            nx, ny = (x + 0.5 - mx) / r, (y + 0.5 - my) / r
            d = nx * nx + ny * ny
            if d > 1:
                continue
            i = -0.5 * nx - 0.6 * ny + 0.62 * math.sqrt(1 - d)
            cv.px(x, y, "lemon" if i > 0.78 else "gold" if i > 0.55 else "amber")
            if d > 0.985:
                cv.px(x, y, "white" if x < mx else "copper")
    for hx, hy, hr in ((250, 336, 14), (350, 296, 9), (470, 312, 18), (600, 300, 10), (170, 356, 8), (560, 348, 13),
                       (410, 346, 7)):
        for y in range(hy - hr // 2, hy + hr // 2 + 1):
            for x in range(hx - hr, hx + hr + 1):
                if ((x - hx) / hr) ** 2 + ((y - hy) / (hr / 2)) ** 2 <= 1 and cv.get(x, y) in (
                        NAME_TO_INDEX["lemon"], NAME_TO_INDEX["gold"], NAME_TO_INDEX["amber"]):
                    cv.px(x, y, "copper" if y < hy else "amber")
    return cv, None


def tether(cv: Canvas, a: tuple, b: tuple, sag: float) -> None:
    pts = []
    for i in range(41):
        t = i / 40
        x = a[0] + (b[0] - a[0]) * t
        y = a[1] + (b[1] - a[1]) * t + sag * 4 * t * (1 - t)
        pts.append((int(round(x)), int(round(y))))
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        cv.line(x0, y0 + 1, x1, y1 + 1, "ink")
        cv.line(x0, y0, x1, y1, "white")


def scene_b(fr: int, static) -> Canvas:
    base, _ = static
    cv = base.copy()
    sparkles(cv, [(250, 70, 3), (430, 40, 2), (620, 170, 2), (300, 210, 2)], fr)
    bob = round(3 * math.sin(fr / FR * math.tau))
    bob2 = round(2 * math.sin(fr / FR * math.tau + 1.5))
    ship = big_lander(flame=fr)
    sx, sy = 486, 150 + bob2
    cat = hero("float", "float", tail_up=3, blink=fr == FR - 1)
    cx, cy = 290, 118 + bob
    tether(cv, (cx + round(43 * HERO_K), cy + round(46 * HERO_K)), (sx + 10, sy + 40), 30 + bob)
    cv.stamp(ship, sx, sy)
    cv.stamp(cat, cx, cy)
    return cv


PAD_Y = 296


def pad(cv: Canvas, fr: int, x0: int, x1: int) -> None:
    k = Canvas(x1 - x0, 24)
    k.rect(0, 0, k.w, 6, "mist"); k.hline(0, k.w - 1, 0, "white"); k.hline(0, k.w - 1, 5, "steel")
    k.rect(0, 6, k.w, 3, "slate")
    for i in range(6, k.w - 6, 12):
        k.px(i, 3, "sea"); k.px(i + 1, 3, "sea")
    for lx in (8, k.w // 2, k.w - 10):
        k.rect(lx, 9, 3, 15, "lilac_grey"); k.vline(lx, 9, 23, "steel")
    k.outline("ink")
    cv.stamp(k, x0, PAD_Y)
    for i, bx in enumerate((x0 + 3, x1 - 7)):                  # luzinhas piscando nas pontas
        on = (fr // 2 + i) % 2 == 0
        cv.rect(bx, PAD_Y - 5, 4, 4, "ink")
        cv.rect(bx + 1, PAD_Y - 4, 2, 2, "lemon" if on else "amber")


def scene_c_static() -> tuple:
    cv = sky_canvas(mc.T["sky"], 30, 4)
    cv.stamp(mc.planet(), 560 - 50, 70 - 50)
    for x, y, kind, flip in ((360, 110, "grande", True), (250, 180, "pequena", False)):
        mc.cloud(cv, x, y, kind, flip)
    back = Canvas(W, 300)
    for name, x, flip in (("grande_fundo", 200, True), ("fundo_alto", 440, False)):
        k = mc.piece(name, flip, mc.T["back"], None, 4, ao=0)
        back.stamp(k, x, 300 - k.h)
    cv.stamp(back)
    vil = None
    for name, x, flip in (("domo_calombo", 240, False), ("dois_calombos", 520, True)):
        k = mc.piece(name, flip, mc.T["front"], mc.T["front_ol"], 6, tex=mc.T["front_tex"])
        cv.stamp(k, x, 312 - k.h)
        vil = vil or (k, x, 312 - k.h)
    k, kx, ky = vil
    t = tops_of(k)
    for i, x in enumerate((268, 306)):                          # vilinha dos ratinhos apoiada no morro
        d = mc.small_dome(0, i)
        cv.stamp(d, x, ky + max(t[x - kx + 4], t[x - kx + d.w - 4]) - d.h + 3)
    ground(cv, 312)
    return cv, None


def scene_c(fr: int, static) -> Canvas:
    base, _ = static
    cv = base.copy()
    sparkles(cv, [(240, 80, 3), (450, 44, 2), (620, 150, 2)], fr)
    pad(cv, fr, 380, 620)
    ship = big_lander()
    cv.stamp(ship, 520, PAD_Y - 61)
    cat = hero("hold", blink=fr == FR - 1)
    cx = 392
    cy = PAD_Y - feet(cat) + 1
    cv.stamp(cat, cx, cy)
    box = parcel()
    cv.stamp(box, cx + round(31 * HERO_K) - box.w // 2, cy + round(52 * HERO_K) - box.h + 4)   # o pacote no colo
    for i, (mx, ph) in enumerate(((300, 0), (338, 2))):          # ratinhos trazendo as cargas
        m = mp.mouse(fr, ph)
        x = mx + (fr * 2 + i * 3) % 6
        cv.stamp(m, x, 312 - m.h + 1)
        cv.stamp([cg.cake(), cg.icecream()][i], x + 2, 312 - m.h - 14 + (1 if (fr + ph) % 4 in (1, 3) else 0))
    return cv


SCENES = {"A": ("Vitrine", scene_a_static, scene_a), "B": ("Passeio no espaço", scene_b_static, scene_b),
          "C": ("Plataforma", scene_c_static, scene_c)}


# ------------------------------------------------------------------ menu de mentira por cima
def glow(cv: Canvas, b: Canvas, x: int, y: int, col: str = "lavender") -> None:
    """Contorno luminoso discreto (1 px fora do botão) = estado SELECIONADO."""
    solid = {(x + px, y + py) for px, py in b.opaque()}
    for px, py in solid:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            q = (px + dx, py + dy)
            if q not in solid:
                cv.px(q[0], q[1], col)


def menu_button(cv: Canvas, x: int, y: int, label: str, main: bool, state: str) -> int:
    """state: normal | selected | pressed. Jogar = primário (maior, texto 2x)."""
    w, h = (140, 28) if main else (120, 22)
    style = "primary" if main else ("hover" if state == "selected" else "normal")
    pressed = state == "pressed"
    b = uk.themed(uk.button(w, h - (2 if pressed else 0), style), "luna")   # apertado: achata 2 px por cima
    dy = {"normal": 0, "selected": -1, "pressed": 2}[state]       # selecionado sobe 1 px
    if state == "selected":
        glow(cv, b, x, y + dy)
    cv.stamp(b, x, y + dy)
    sc = 2 if main else 1
    tw = text_width(label) * sc
    draw_text(cv, x + (w - tw) // 2, y + dy + (h - 7 * sc) // 2 - 2 * sc, label, "white", shadow="ink", scale=sc)
    return h


def menu(cv: Canvas, drawn_logo: bool, sel: str = "selected") -> None:
    x0 = 30
    if drawn_logo:
        l = lg.logo()
        cv.stamp(l, x0 - 8, 18)
        y = 18 + l.h + 6
    else:
        f = lg.font_logo()
        cv.stamp(f, x0 - 8, 24)
        y = 24 + 40
    draw_text(cv, x0, y, "Pouse. Entregue. Evolua sua nave.", "cream", shadow="berry_dark")   # a proposta
    y += 30
    for i, label in enumerate(("Jogar", "Sandbox", "Opções", "Sair")):
        y += menu_button(cv, x0, y, label, i == 0, sel if i == 0 else "normal") + (10 if i == 0 else 6)


def button_states() -> Canvas:
    cv = Canvas(3 * 160 + 20, 50, "plum")
    for i, st in enumerate(("normal", "selected", "pressed")):
        menu_button(cv, 14 + i * 160, 10, "Jogar", True, st)
    return cv


def render(args) -> list:
    key, variant, frames = args
    _, st, fn = SCENES[key]
    static = st()
    out = []
    for fr in frames:
        cv = fn(fr, static)
        if variant != "clean":
            menu(cv, variant == "drawn")
        out.append(cv.to_image().convert("RGB"))
    return out


if __name__ == "__main__":
    from PIL import Image
    os.makedirs(OUT, exist_ok=True)
    jobs = [(k, v, list(range(FR))) for k in SCENES for v in ("drawn", "font", "clean")]
    with ProcessPoolExecutor() as ex:
        results = list(ex.map(render, jobs))
    for (k, v, _), imgs in zip(jobs, results):
        big = [im.resize((W * 2, H * 2), Image.NEAREST) for im in imgs]
        big[0].save(f"{OUT}/{k}_{v}.png")
        if v == "clean":
            big[10].save(f"{OUT}/{k}_f10.png")
        big[0].save(f"{OUT}/{k}_{v}.gif", save_all=True, append_images=big[1:], duration=FRAME_MS, loop=0)
        if v == "drawn":                                         # teste de valor (P&B)
            from PIL import ImageOps
            ImageOps.grayscale(imgs[0]).resize((W, H)).save(f"{OUT}/{k}_gray.png")
    button_states().to_image().resize((500 * 3, 50 * 3), Image.NEAREST).save(f"{OUT}/A_v3_estados.png")
    print("ok", OUT)
