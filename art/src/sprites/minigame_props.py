"""Figuras dos minijogos dos mundos (Fase 18.5, 2026-10-07). Skill pixel-art, estilo fofo (cute-scene-method).

Contrato com o jogo (godot-dev, game/flight/flight.gd + scripts/world/minigame_art.gd):
  assets/sprites/minigame_props.png + minigame_props.json {"rects": {nome: [x, y, w, h]}} — figuras soltas;
  assets/sprites/mg_<nome>.png — texturas que REPETEM (o Godot usa region + texture_repeat):
    mg_stalk (talo do cogumelo, repete na vertical), mg_stem (caule da flor, vertical),
    mg_sea (mar: ondinha no alto, repete na horizontal; abaixo da faixa o jogo pinta a cor "sea_deep"),
    mg_ice (pista de gelo, horizontal).
Tamanhos batem com data/world.json > minigames (1 m = 1 px): chapéus 56/44/36 px (cap_half_m 28/22/18),
caule 14 px (stem_half_m 7). Personagens/objetos = contorno ink; texturas de cenário = contorno da própria rampa.
Rodar da raiz: python3 art/src/sprites/minigame_props.py [--export]
"""
import json
import math
import sys

sys.path.insert(0, ".claude/skills/pixel-art/scripts")
sys.path.insert(0, "art/src/bg")
from pixelart import *
import moon_cute as mc
import world_scene as ws


def sheep(fr: int) -> Canvas:
    """Carneirinho perdido (Nuvens): o mesmo do cenário em tamanho de jogo (18x16), 2 quadros (pula)."""
    return ws._sheep(fr, 0)


def chest(open_: bool = False) -> Canvas:
    """Baú do tesouro 18x14: madeira, cintas douradas, fechadura; aberto mostra moedas."""
    k = Canvas(18, 15)
    k.rect(1, 6, 16, 8, "terracotta"); k.hline(1, 16, 13, "rust")
    for x in (1, 16):
        k.vline(x, 6, 13, "rust")
    for y in range(1, 6):                                       # tampa arredondada
        half = 8 - (1 if y == 1 else 0)
        k.hline(9 - half, 8 + half, y, "copper" if y < 3 else "terracotta")
    k.hline(2, 15, 1, "honey")
    for x in (4, 13):                                           # cintas
        k.vline(x, 1, 13, "gold")
    k.hline(1, 16, 6, "gold")
    k.rect(8, 6, 2, 3, "lemon"); k.px(8, 8, "ink")
    if open_:
        for x in range(3, 15):
            k.px(x, 4, "lemon" if x % 2 else "gold")
    k.outline("ink")
    return k


def hook() -> Canvas:
    """Garra vazia 11x11 (três dedinhos)."""
    k = Canvas(11, 11)
    k.rect(4, 0, 3, 4, "steel"); k.hline(3, 7, 4, "lilac_grey")
    for sx in (-1, 1):
        k.line(5 + sx * 2, 5, 5 + sx * 4, 8, "steel"); k.px(5 + sx * 3, 9, "steel"); k.px(5 + sx * 2, 9, "mist")
    k.vline(5, 5, 9, "steel"); k.px(5, 10, "mist")
    k.outline("ink")
    return k


def cap(w: int) -> Canvas:
    """Chapéu de cogumelo-mola (vista de lado), largura w, com bolinhas e um sorriso na base (é uma cama elástica)."""
    h = w // 4 + 3
    k = Canvas(w, h + 1)
    cx = w / 2
    for y in range(h):
        for x in range(w):
            nx, ny = (x + 0.5 - cx) / (w / 2), (y + 0.5 - h) / h
            if nx * nx + ny * ny <= 1:
                i = -0.55 * nx - 0.7 * ny - 0.2
                k.px(x, y, "white" if i > 0.7 else "salmon" if i > 0.35 else "red" if i > -0.25 else "crimson")
    for x in range(2, w - 2):                                  # aba de baixo (creme)
        k.px(x, h - 1, "cream" if x % 5 else "peach")
    for i, fx in enumerate((0.25, 0.55, 0.8)):
        r = max(1.4, w / 22) * (1.2 if i == 1 else 1)
        mc.disc(k, w * fx, h * (0.45 if i != 1 else 0.3), r, "white")
    k.outline("ink")
    return k


def stalk() -> Canvas:
    """Talo creme do cogumelo (8x8, repete na vertical)."""
    k = Canvas(8, 8)
    for y in range(8):
        k.hline(0, 7, y, "cream")
        k.px(0, y, "rust"); k.px(7, y, "rust"); k.px(1, y, "white"); k.px(6, y, "peach")
    k.px(4, 2, "peach"); k.px(3, 6, "peach")
    return k


def stem() -> Canvas:
    """Caule da flor gigante (14x16, repete na vertical): verde com fibra clara e um nó."""
    k = Canvas(14, 16)
    for y in range(16):
        for x in range(14):
            k.px(x, y, "pine" if x in (0, 13) else "sprout" if x in (2, 3) else "leaf" if x < 7 else "green" if x < 12 else "emerald")
    for x in range(1, 13):                                     # nó
        k.px(x, 15, "green")
    k.px(3, 15, "leaf")
    return k


def bloom(petal: str, petal_dark: str, down: bool) -> Canvas:
    """Flor na ponta do caule (26x18): pétalas abertas para o vão (down=True: a flor de cima, virada para baixo)."""
    k = Canvas(26, 18)
    for i in range(7):
        a = math.pi * (i / 6)
        mc.sphere(k, 13 + math.cos(a) * 9, 11 - math.sin(a) * 6, 4.2, 4.2, ["white", petal, petal, petal_dark])
    mc.sphere(k, 13, 12, 5.5, 4.5, ["lemon", "gold", "gold", "amber"])
    k.px(11, 12, "amber"); k.px(15, 11, "amber"); k.px(13, 14, "amber")
    k.outline("ink")
    if down:
        k = flip_v(k)
    return k


def flip_v(k: Canvas) -> Canvas:
    o = Canvas(k.w, k.h)
    for y in range(k.h):
        for x in range(k.w):
            c = k.get(x, y)
            if c is not None:
                o.px(x, k.h - 1 - y, c)
    return o


def sea() -> Canvas:
    """Faixa de cima do mar (32x12, repete na horizontal): crista de onda clara + brilhos; abaixo = cor funda."""
    k = Canvas(32, 12)
    for x in range(32):
        top = int(round(1.5 + 1.5 * math.sin(math.tau * x / 32)))
        for y in range(top, 12):
            k.px(x, y, "white" if y == top else "pale_sky" if y == top + 1 else "sea" if y < 7 else "teal")
    for x, y in ((6, 6), (7, 6), (21, 9), (22, 9), (23, 9)):
        k.px(x, y, "aqua")
    return k


def ice() -> Canvas:
    """Pista de gelo (16x4, repete na horizontal)."""
    k = Canvas(16, 4)
    for x in range(16):
        k.px(x, 0, "white"); k.px(x, 1, "pale_sky" if x % 7 else "white"); k.px(x, 2, "pale_sky"); k.px(x, 3, "sky")
    return k


def bubble(r: float) -> Canvas:
    n = int(r * 2 + 2)
    k = Canvas(n, n)
    c = n / 2
    for y in range(n):
        for x in range(n):
            d = math.hypot(x + 0.5 - c, y + 0.5 - c)
            if r - 1 <= d <= r:
                k.px(x, y, "white")
    k.px(int(c - r * 0.4), int(c - r * 0.4), "white")
    return k


def puff() -> Canvas:
    """Lufada de vento (corrente de ar das Nuvens) 10x12: espiral branca."""
    k = Canvas(10, 12)
    for t in range(40):
        a = t * 0.35
        r = 1 + t * 0.11
        k.px(int(5 + math.cos(a) * r), int(6 + math.sin(a) * r * 1.1), "white")
    return k


def build() -> dict:
    items = {
        "sheep0": sheep(0), "sheep1": sheep(1), "chest": chest(), "chest_open": chest(True), "hook": hook(),
        "cap56": cap(56), "cap44": cap(44), "cap36": cap(36),
        "bloom_top": bloom("pink", "rose", True), "bloom_bot": bloom("violet", "purple", False),
        "bubble3": bubble(3), "bubble2": bubble(2), "puff": puff(),
    }
    return items


def atlas(items: dict) -> tuple:
    x, h = 0, max(k.h for k in items.values())
    rects = {}
    for n, k in items.items():
        rects[n] = [x, 0, k.w, k.h]
        x += k.w + 1
    cv = Canvas(x, h)
    for n, k in items.items():
        cv.stamp(k, rects[n][0], 0)
    return cv, rects


if __name__ == "__main__":
    items = build()
    cv, rects = atlas(items)
    tiles = {"stalk": stalk(), "stem": stem(), "sea": sea(), "ice": ice()}
    if "--export" in sys.argv:
        cv.save("assets/sprites/minigame_props.png", preview=False)
        for n, k in tiles.items():
            k.save(f"assets/sprites/mg_{n}.png", preview=False)
        hexc = lambda n: "#" + "%02x%02x%02x" % tuple(PALETTE_RGB[resolve(n)])
        with open("assets/sprites/minigame_props.json", "w") as f:
            json.dump({"notes": "Gerado por art/src/sprites/minigame_props.py", "rects": rects,
                       "sea_deep": hexc("teal"), "stalk_w": 8}, f, indent=1)
        print("exportado")
    else:
        sheet = Canvas(max(cv.w, 200), cv.h + 24)
        sheet.stamp(cv, 0, 0)
        x = 0
        for k in tiles.values():
            for i in range(3 if k.w < 20 else 2):
                sheet.stamp(k, x + (i * k.w if k.h < 8 else 0), cv.h + 4 + (0 if k.h < 8 else i * k.h % 16))
            x += k.w * 3 + 4
        sheet.save("art/previews/minigame_props.png")
        print("ok")

# caminhos literais dos assets (o pre-commit procura a fonte de cada PNG pelo caminho escrito no script):
# assets/sprites/minigame_props.png assets/sprites/mg_stalk.png assets/sprites/mg_stem.png
# assets/sprites/mg_sea.png assets/sprites/mg_ice.png
