"""Obstáculos do céu da Lua (2026-10-11). Skill pixel-art, estilo fofo (cute-scene-method.md: meia resolução + Scale2x,
contorno ink no primeiro plano, cor chapada 2–3 tons, luz de cima-esquerda).

Pedido do usuário: mitigar o arremesso por cima (5 km num salto) com obstáculos no alto; "a quantidade de obstáculos
pode aumentar com a altitude". Três famílias para escolher (todas com um porquê no tema — Lua = mina de queijo dos
ratinhos, Terra dormindo):
  A queijo — lascas que a mina solta e ficam flutuando (fatia, pedaço com furos, farelo), giram devagar
  B satelite — satélites que os ratinhos montaram (corpo de lata com orelhinhas, placas turquesa, luz piscando)
  C estrela — estrelinhas dorminhocas (rostinho dormindo, bochecha rosa, "z"), balançam de leve
Cada família: grande 28–32 px, média ~20–24, pequena ~14–16 (o tamanho do sprite = área que bate na nave).
Prévias: art/previews/sky_obstacles/ (atlas ampliado + cena do jogo com a densidade subindo).
Escolhida pelo usuário (2026-10-11): B, satélites dos ratinhos ("ficaram bons"; A e C confundem com moedas/estrelas).
Export (--export): assets/sprites/sky_obstacles.png + .json — células CELL_W x CELL_H numa linha, sprite centrado,
nomes em EXPORT (on/off = luz vermelha acesa/apagada, alterna no jogo). Áreas de batida em data/world.json > sky_obstacles.
Rodar da raiz: python3 art/src/sprites/sky_obstacles.py [--export]
"""
import json
import math
import random
import sys

sys.path.insert(0, ".claude/skills/pixel-art/scripts")
sys.path.insert(0, "art/src/bg")
from pixelart import *
from moon_cute import cel, scale2x, sphere

OUT = "art/previews/sky_obstacles"
GOLD = ["lemon", "gold", "amber", "terracotta"]
STEEL = ["white", "mist", "steel", "lilac_grey"]


def finish(half: Canvas, post=None) -> Canvas:
    """Meia resolução -> Scale2x -> (post: detalhe fino em resolução final, ex. rostinho) -> contorno ink."""
    k = scale2x(half)
    big = Canvas(k.w + 2, k.h + 2)
    big.stamp(k, 1, 1)
    if post:
        post(big)
    big.outline("ink")
    return big


def hole(cv: Canvas, x: int, y: int, big: bool) -> None:
    """Furinho de queijo: escuro com borda de baixo clara (côncavo)."""
    cv.px(x, y, "rust")
    if big:
        cv.px(x + 1, y, "rust"); cv.px(x, y + 1, "terracotta"); cv.px(x + 1, y + 1, "terracotta")
        cv.px(x, y + 2, "lemon"); cv.px(x + 1, y + 2, "lemon")
    else:
        cv.px(x, y + 1, "lemon")


# --- A: queijo -----------------------------------------------------------------------------------------------

def cheese_wedge() -> Canvas:
    h = Canvas(15, 11)
    h.polygon([(0, 8), (14, 1), (14, 4), (0, 10)], "lemon")          # casca de cima (face clara)
    h.polygon([(0, 9), (14, 3), (14, 10), (0, 10)], "gold")           # face da frente
    h.vline(14, 2, 10, "amber"); h.hline(1, 14, 10, "amber")
    hole(h, 9, 5, True); hole(h, 5, 8, False); hole(h, 12, 7, False)
    return finish(h)


def cheese_chunk() -> Canvas:
    h = Canvas(11, 10)
    sphere(h, 5.5, 5, 5.2, 4.6, GOLD)
    hole(h, 3, 3, True); hole(h, 7, 5, True); hole(h, 4, 7, False)
    return finish(h)


def cheese_crumb() -> Canvas:
    h = Canvas(7, 6)
    sphere(h, 3.5, 3, 3.2, 2.7, GOLD)
    hole(h, 4, 2, False)
    return finish(h)


# --- B: satelite dos ratinhos --------------------------------------------------------------------------------

def panel(h: Canvas, x: int, y: int, w: int, hh: int) -> None:
    h.rect(x, y, w, hh, "sea")
    h.hline(x, x + w - 1, y, "aqua")
    for gx in range(x + 2, x + w, 3):
        h.vline(gx, y + 1, y + hh - 1, "teal")


def satellite(light: bool = True) -> Canvas:
    """Cabeça redonda de lata com orelhinhas de ratinho (separadas da cabeça pelo contorno), placas turquesa
    nos braços e luz no alto que pisca (light)."""
    h = Canvas(22, 12)
    for px_ in (0, 17):
        panel(h, px_, 6, 5, 4)
    h.hline(5, 16, 8, "lilac_grey")                                    # braços
    sphere(h, 11, 8, 3.9, 3.7, STEEL)
    for ex in (8, 14):                                                 # orelhinhas (1 linha de folga = contorno)
        sphere(h, ex, 2.9, 1.7, 1.7, STEEL)
        h.px(ex if ex < 11 else ex - 1, 2, "pink"); h.px(ex if ex < 11 else ex - 1, 3, "pink")
    h.vline(11, 1, 3, "lilac_grey"); h.px(11, 0, "red" if light else "gold")

    def face_(k: Canvas) -> None:
        cx, cy = 23, 17
        for ex in (cx - 4, cx + 3):
            k.px(ex, cy, "ink"); k.px(ex, cy + 1, "ink"); k.px(ex - 1 if ex < cx else ex, cy - 1, "white")
        k.px(cx - 1, cy + 3, "ink"); k.px(cx, cy + 3, "ink")             # sorrisinho
        k.px(cx - 6, cy + 2, "pink"); k.px(cx + 5, cy + 2, "pink")
    return finish(h, face_)


def probe(light: bool = True) -> Canvas:
    h = Canvas(11, 8)
    panel(h, 0, 3, 3, 3)
    h.hline(3, 5, 4, "lilac_grey")
    sphere(h, 7.5, 4.5, 3, 3, STEEL)
    h.px(7, 4, "ink"); h.px(9, 4, "ink")
    h.vline(8, 0, 1, "lilac_grey"); h.px(8, 0, "red" if light else "gold")
    return finish(h)


def bolt() -> Canvas:
    """Parafusinho/porca perdido (pequeno)."""
    h = Canvas(6, 6)
    sphere(h, 3, 3, 2.8, 2.8, STEEL)
    h.px(3, 3, "shadow"); h.px(2, 3, "lilac_grey")
    return finish(h)


# --- C: estrelinha dorminhoca --------------------------------------------------------------------------------

STAR_SHAPES = {
    "big": [".......x.......", "......xxx......", "......xxx......", ".....xxxxx.....", "xxxxxxxxxxxxxxx",
            ".xxxxxxxxxxxxx.", "..xxxxxxxxxxx..", "...xxxxxxxxx...", "...xxxxxxxxx...", "..xxxxxxxxxxx..",
            "..xxxxx.xxxxx..", ".xxxx.....xxxx.", ".xx.........xx."],
    "mid": ["....x....", "...xxx...", "xxxxxxxxx", ".xxxxxxx.", "..xxxxx..", "..xxxxx..", ".xxx.xxx.",
            ".xx...xx."],
    "small": ["...x...", "..xxx..", "xxxxxxx", ".xxxxx.", "..xxx..", ".xx.xx.", ".x...x."],
}


def star(size: str) -> Canvas:
    """Estrelinha dorminhoca desenhada à mão (pontas redondas pelo Scale2x), cel lemon/gold/amber e rostinho
    dormindo (olhos em arco, bochecha rosa)."""
    rows = STAR_SHAPES[size]
    h = Canvas(len(rows[0]), len(rows))
    h.paint(rows, {"x": "gold"})
    w2 = h.w * 2 + 2

    def post(k: Canvas) -> None:
        cel(k, ["lemon", "lemon", "gold", "amber"], None, 3)
        cx = w2 // 2
        cy = {"big": 14, "mid": 9, "small": 7}[size]
        if size == "small":
            k.px(cx - 2, cy, "ink"); k.px(cx + 1, cy, "ink")
            return
        span = 3 if size == "big" else 2
        gap = 3 if size == "big" else 2
        for sx in (cx - gap - span, cx + gap):                         # olho fechado: arco para baixo
            k.px(sx, cy, "ink"); k.px(sx + span, cy, "ink")
            for xx in range(sx + 1, sx + span):
                k.px(xx, cy + 1, "ink")
        k.px(cx - gap - span - 1, cy + 3, "pink"); k.px(cx + gap + span + 1, cy + 3, "pink")
        if size == "big":
            k.px(cx - 1, cy + 4, "ink"); k.px(cx, cy + 4, "ink")          # boquinha
    return finish(h, post)


def zz(cv: Canvas, x: int, y: int) -> None:
    cv.paint(["ccc", "..c", ".c.", "c..", "ccc"], {"c": "white"}, x=x, y=y)


# --- rodada 2 (2026-10-11): usuário achou os satélites "meio feios" -------------------------------------------------
ROCK = ["mist", "steel", "lilac_grey", "slate"]
MINE = ["pale_sky", "sky", "blue", "indigo"]


def blob(cv: Canvas, cx: float, cy: float, r: float, seed: int, ramp: list, lumps: float = 0.2) -> list:
    """Pedra irregular: contorno polar com 2 ondas (sem pontas), volume de esfera recortado pelo contorno."""
    rnd = random.Random(seed)
    p1, p2 = rnd.uniform(0, 6.3), rnd.uniform(0, 6.3)
    pts = []
    for k in range(28):
        a = k / 28 * math.tau
        rr = r * (1 + lumps * math.sin(2 * a + p1) + lumps * 0.6 * math.sin(3 * a + p2))
        pts.append((round(cx + rr * math.cos(a)), round(cy + rr * 0.95 * math.sin(a))))
    mask = Canvas(cv.w, cv.h)
    mask.polygon(pts, "ink")
    inside = set(mask.opaque())
    sphere(cv, cx, cy, r * 1.2, r * 1.08, ramp, clip=lambda x, y: (x, y) in inside)
    return pts


def crater(cv: Canvas, x: int, y: int, w: int) -> None:
    """Cratera côncava (meia resolução): miolo escuro e borda de baixo clara (a luz de cima-esquerda bate na parede de
    baixo-direita); w = 1 (furinho) | 2 | 3."""
    shape = {1: ["d"], 2: ["dd", "lm"], 3: [".dd", "ddd", "lmm"]}[w]
    cv.paint(shape, {"d": "slate", "l": "lilac_grey", "m": "mist"}, x=x, y=y)


def asteroid(size: str, face: bool = False) -> Canvas:
    r, n, seed = {"big": (8.0, 20, 3), "mid": (5.6, 15, 8), "small": (3.4, 10, 5)}[size]
    h = Canvas(n, n)
    c = n / 2
    blob(h, c, c, r, seed, ROCK)
    if size == "big":
        crater(h, int(c + 1), int(c - 5), 3); crater(h, int(c - 6), int(c + 1), 2); crater(h, int(c + 3), int(c + 3), 2)
        crater(h, int(c - 2), int(c + 5), 1)
    elif size == "mid":
        crater(h, int(c + 1), int(c - 3), 2); crater(h, int(c - 4), int(c + 1), 2); crater(h, int(c + 2), int(c + 3), 1)
    else:
        crater(h, int(c), int(c - 1), 1)

    def post(k: Canvas) -> None:
        if not face:
            return
        cx = k.w // 2
        cy = k.h // 2 + (1 if size == "big" else 0)
        gap = 4 if size == "big" else 3
        for ex in (cx - gap - 1, cx + gap - 1):                        # olhos 2x3 com brilho + sobrancelha brava
            k.rect(ex, cy - 1, 2, 3, "ink")
            k.px(ex, cy - 1, "white")
        k.line(cx - gap - 2, cy - 4, cx - gap + 1, cy - 3, "ink")
        k.line(cx + gap - 2, cy - 3, cx + gap + 1, cy - 4, "ink")
        k.hline(cx - 2, cx + 1, cy + 4, "ink")                         # boca reta (emburrado)
        k.px(cx - gap - 2, cy + 3, "rose"); k.px(cx + gap + 1, cy + 3, "rose")
    return finish(h, post)


def mine(size: str, light: bool = True) -> Canvas:
    """Mina espacial fofa: bola azul com espetos curtos e GROSSOS (cone de base larga, ponta clara) — lê "não encoste";
    luz vermelha no topo (pisca no jogo)."""
    r, n, spikes = {"big": (5.6, 21, 6), "mid": (4.2, 17, 6), "small": (3.0, 13, 4)}[size]
    h = Canvas(n, n)
    c = n / 2
    for k in range(spikes):
        a = k / spikes * math.tau + math.pi / spikes
        tip = (c + (r + 2.8) * math.cos(a), c + (r + 2.8) * math.sin(a))
        b1 = (c + r * 0.8 * math.cos(a - 0.55), c + r * 0.8 * math.sin(a - 0.55))
        b2 = (c + r * 0.8 * math.cos(a + 0.55), c + r * 0.8 * math.sin(a + 0.55))
        h.polygon([tuple(map(round, tip)), tuple(map(round, b1)), tuple(map(round, b2))], "steel")
        h.px(round(tip[0]), round(tip[1]), "mist")
    sphere(h, c, c, r, r, MINE)
    h.px(int(c), int(c - r) - 1, "lilac_grey")
    h.px(int(c), int(c - r) - 2, "red" if light else "maroon")
    return finish(h)


FAMILIES2 = {
    "D": ("Asteroides de pedra", [asteroid("big"), asteroid("mid"), asteroid("small")]),
    "E": ("Asteroides emburrados", [asteroid("big", True), asteroid("mid", True), asteroid("small")]),
    "F": ("Minas espaciais", [mine("big"), mine("mid"), mine("small")]),
}
FAMILIES = {
    "A": ("Lascas de queijo da mina", [cheese_wedge(), cheese_chunk(), cheese_crumb()]),
    "B": ("Satélites dos ratinhos", [satellite(), probe(), bolt()]),
    "C": ("Estrelinhas dorminhocas", [star("big"), star("mid"), star("small")]),
}


def atlas(sprites: list) -> Canvas:
    w = sum(s.w for s in sprites) + 6 * (len(sprites) + 1)
    hgt = max(s.h for s in sprites) + 12
    cv = Canvas(w, hgt)
    x = 6
    for s in sprites:
        cv.stamp(s, x, hgt - 6 - s.h)
        x += s.w + 6
    return cv


def scene(sprites: list, bg_path: str, out: str) -> None:
    """Prévia no jogo: captura real 640x360 + obstáculos ficando mais densos quanto mais alto (a faixa de baixo,
    onde se pula de plataforma em plataforma, fica livre). Só ilustração da regra; a densidade real vem do jogo."""
    from PIL import Image
    bg = Image.open(bg_path).convert("RGBA")
    ims = [s.to_image() for s in sprites]
    rng = random.Random(7)
    free_y = 165                                                       # abaixo disto (perto do chão) nada
    placed = []
    for _ in range(600):
        y = rng.uniform(-6, free_y)
        density = (1 - y / free_y) ** 1.5                              # mais alto = mais obstáculos
        if rng.random() > density * 0.55:
            continue
        x = rng.uniform(-10, 630)
        hud = [(0, 0, 172, 98), (282, 0, 360, 52), (172, 40, 378, 112), (418, 0, 640, 88)]   # painéis do HUD
        if any(x0 - 30 < x < x1 and y0 - 26 < y < y1 for x0, y0, x1, y1 in hud):
            continue
        i = rng.choice([0, 1, 1, 2, 2]) if y < 80 else rng.choice([1, 2, 2])
        if any(abs(x - px) < 30 and abs(y - py) < 26 for px, py in placed):
            continue
        placed.append((x, y))
        bg.alpha_composite(ims[i], (int(x), int(y)))
    bg.save(out)


CELL_W, CELL_H = 48, 28
EXPORT = [("sat_on", lambda: satellite(True)), ("sat_off", lambda: satellite(False)),
          ("probe_on", lambda: probe(True)), ("probe_off", lambda: probe(False)), ("bolt", bolt)]


def export() -> None:
    sheet = Canvas(CELL_W * len(EXPORT), CELL_H)
    for i, (_, make) in enumerate(EXPORT):
        k = make()
        sheet.stamp(k, i * CELL_W + (CELL_W - k.w) // 2, (CELL_H - k.h) // 2)
    sheet.save("art/previews/sky_obstacles_sheet.png")
    sheet.save("assets/sprites/sky_obstacles.png", preview=False)
    with open("assets/sprites/sky_obstacles.json", "w") as f:
        json.dump({"cell_w": CELL_W, "cell_h": CELL_H, "names": [n for n, _ in EXPORT],
                   "notes": "Gerado por art/src/sprites/sky_obstacles.py (pixel-art). Sprite centrado na célula."}, f,
                  indent=2)
    print("exportado assets/sprites/sky_obstacles.png")


if __name__ == "__main__":
    if "--export" in sys.argv:
        export()
    import os
    os.makedirs(OUT, exist_ok=True)
    for fam, (name, sprites) in (FAMILIES2 if "--v2" in sys.argv else FAMILIES).items():
        a = atlas(sprites)
        a.save(f"{OUT}/{fam}_atlas.png")
        print(fam, name, [f"{s.w}x{s.h}" for s in sprites], "cores", len(a.colors_used()))
        scene(sprites, f"{OUT}/game_bg.png", f"{OUT}/{fam}_scene.png")
        a.save(f"{OUT}/{fam}_atlas.png")
