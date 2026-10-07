"""Badge da Reputação (2026-10-07). Skill pixel-art, estilo fofo (kids-ui).

Usuário: "o indicador de reputação na tela poderia ser um badge". Aceso = a próxima entrega vale +10% (pouso perfeito);
apagado = cinza (pouse reto e macio para acender). Três propostas 24x24 (célula do atlas kids), cada uma acesa/apagada:
  A medalha  — moeda dourada com coração rosa e duas fitas (os ratinhos gostam de você)
  B roseta   — roseta de prêmio (pétalas) com estrela no meio e fitas
  C escudo   — escudinho com o rostinho do ratinho sorrindo e uma estrelinha
ESCOLHIDO (2026-10-07): C escudo -> células rep_on/rep_off do atlas kids (art/src/ui/kids_ui.py --export).
Rodar da raiz:  python3 art/src/ui/rep_badge.py   -> art/previews/rep_badge_preview.png (+ PNGs para o HTML)
"""
import sys

sys.path.insert(0, ".claude/skills/pixel-art/scripts")
sys.path.insert(0, "art/src/bg")
from pixelart import *
import moon_cute as mc

CELL = 24
GOLD = ["lemon", "gold", "gold", "amber"]
GREY = ["mist", "steel", "steel", "lilac_grey"]


def _ribbons(k: Canvas, on: bool) -> None:
    """Duas fitas em V (3 px de largura) saindo de baixo do disco, abrindo para fora, com a ponta em bico."""
    a, b = ("sky", "blue") if on else ("steel", "slate")
    for side in (-1, 1):
        for i in range(9):
            x = 12 + side * (2 + i // 2)
            y = 13 + i
            for w in range(3):
                k.px(x + side * w - (1 if side > 0 else -1), y, a if w < 2 else b)
        k.px(12 + side * 6, 21, "clear"); k.px(12 + side * 7 - side, 21, "clear")


def heart(k: Canvas, cx: int, cy: int, col: str, hi: str) -> None:
    k.paint([".##.##.", "#######", "#######", ".#####.", "..###..", "...#..."], {"#": col}, x=cx - 3, y=cy - 3)
    k.px(cx - 2, cy - 2, hi)


def medal(on: bool) -> Canvas:
    k = Canvas(CELL, CELL)
    _ribbons(k, on)
    mc.disc(k, 12, 10, 8.4, "amber" if on else "slate")
    mc.sphere(k, 12, 10, 7.2, 7.2, GOLD if on else GREY)
    heart(k, 12, 10, "hot_pink" if on else "lilac_grey", "white" if on else "mist")
    if on:
        k.px(8, 6, "white"); k.px(9, 5, "white")
    k.outline("ink")
    return k


def star_shape(k: Canvas, cx: int, cy: int, col: str, hi: str) -> None:
    rows = ["....#....", "...###...", "#########", ".#######.", "..#####..", ".###.###.", ".##...##."]
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch == "#":
                k.px(cx - 4 + x, cy - 3 + y, col)
    k.px(cx - 1, cy - 1, hi)


def rosette(on: bool) -> Canvas:
    k = Canvas(CELL, CELL)
    _ribbons(k, on)
    petal = "hot_pink" if on else "steel"
    petal2 = "raspberry" if on else "slate"
    for i in range(12):                                        # coroa de pétalas
        import math
        a = i * math.pi / 6
        mc.disc(k, 12 + 7 * math.cos(a), 10 + 7 * math.sin(a), 2.4, petal if i % 2 == 0 else petal2)
    mc.disc(k, 12, 10, 6.4, "amber" if on else "slate")
    mc.sphere(k, 12, 10, 5.6, 5.6, ["white", "lemon", "lemon", "gold"] if on else GREY)
    star_shape(k, 12, 10, "orange" if on else "lilac_grey", "gold" if on else "mist")
    k.outline("ink")
    return k


def shield(on: bool) -> Canvas:
    k = Canvas(CELL, CELL)
    body = ["#################", "#################", "#################", "#################", "#################",
            "#################", "#################", "#################", ".###############.", ".###############.",
            "..#############..", "...###########...", "....#########....", ".....#######.....", "......#####......",
            ".......###.......", "........#........"]
    ramp = ["lemon", "gold", "gold", "amber"] if on else ["mist", "steel", "steel", "lilac_grey"]
    for y, row in enumerate(body):
        for x, ch in enumerate(row):
            if ch == "#":
                k.px(4 + x, 3 + y, ramp[min(3, (x + y) // 7)])
    face = "white" if on else "mist"                           # rostinho do ratinho
    for ex in (8, 16):
        mc.disc(k, ex, 7, 2.6, face); mc.disc(k, ex, 7, 1.2, "pink" if on else "steel")
    mc.disc(k, 12, 11, 4.0, face)
    for ex in (10, 14):
        k.px(ex, 10, "ink"); k.px(ex, 11, "ink")
    k.px(12, 12, "pink" if on else "steel")
    k.px(11, 13, "ink"); k.px(13, 13, "ink"); k.px(12, 14, "ink")       # sorriso
    k.outline("ink")
    return k


VARIANTS = {"a_medal": medal, "b_rosette": rosette, "c_shield": shield}


if __name__ == "__main__":
    out = Canvas(CELL * 6 + 10, CELL)
    for i, (name, make) in enumerate(VARIANTS.items()):
        for j, on in enumerate((True, False)):
            k = make(on)
            out.stamp(k, i * (CELL * 2 + 5) + j * CELL, 0)
            k.save(f"art/previews/rep_badge/{name}_{'on' if on else 'off'}.png", preview=False)
    out.preview("art/previews/rep_badge_preview.png", scale=6, grid=False, bg="dark", show_1x=True)
    print("ok")
