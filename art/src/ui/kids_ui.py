"""Peças da interface "para crianças" (2026-10-05). Skill pixel-art, estilo fofo (cute-style).

Usuário: "o menu de aceitar missão e o de compras estão como se fosse pra adulto; tinha que ser mais divertido
(gamificado) e intuitivo para crianças". Proposta aprovada em art/previews/ui_kids_plan.html:
  pedidos = pinos com o rostinho de quem pediu numa trilha; dificuldade = estrelas; prêmio = pilha de moedas.
Atlas de células 24x24 → assets/ui/kids.png + contrato assets/ui/kids.json (nomes na ordem das células).

Rodar da raiz:  python3 art/src/ui/kids_ui.py           -> prévia art/previews/kids_ui_preview.png
                python3 art/src/ui/kids_ui.py --export  -> assets/ui/kids.png + kids.json
"""
import json
import math
import sys

sys.path.insert(0, ".claude/skills/pixel-art/scripts")
sys.path.insert(0, "art/src/bg"); sys.path.insert(0, "art/src/terrain"); sys.path.insert(0, "art/src/sprites")
from pixelart import *
import moon_cute as mc

CELL = 24
FUR = ["white", "white", "cream", "peach"]


def badge(ramp: list, rim: str | None = None) -> Canvas:
    """Fundo redondo do pino (22x22 no centro da célula): bolacha com volume e contorno ink."""
    k = Canvas(CELL, CELL)
    if rim:
        mc.disc(k, 12, 12, 11.2, rim)
    mc.sphere(k, 12, 12, 9.6 if rim else 10.6, 9.6 if rim else 10.6, ramp)
    k.outline("ink")
    return k


def rat() -> Canvas:
    """Ratinho da Lua (rosto de frente): orelhonas rosa, olhos com brilho, bochecha, bigode."""
    k = Canvas(CELL, CELL)
    for ex in (6, 17):
        mc.disc(k, ex, 7, 4.2, "cream"); mc.disc(k, ex, 7.4, 2.4, "pink")
    mc.sphere(k, 11.5, 13, 7, 6.2, FUR)
    for x in (8, 14):
        k.px(x, 12, "ink"); k.px(x, 13, "ink"); k.px(x + 1, 12, "ink"); k.px(x + 1, 13, "ink"); k.px(x, 12, "white")
    k.px(11, 15, "pink"); k.px(12, 15, "pink")
    k.px(6, 15, "pink"); k.px(17, 15, "pink")
    k.line(2, 14, 5, 15, "lilac_grey"); k.line(18, 15, 21, 14, "lilac_grey")
    k.outline("ink")
    return k


def bunny() -> Canvas:
    k = Canvas(CELL, CELL)
    for ex in (8, 14):
        k.rect(ex, 1, 3, 9, "white"); k.vline(ex + 1, 2, 8, "pink")
    mc.sphere(k, 11.5, 15, 7, 6, FUR)
    for x in (8, 14):
        k.px(x, 14, "ink"); k.px(x + 1, 14, "ink"); k.px(x, 15, "ink"); k.px(x + 1, 15, "ink"); k.px(x, 14, "white")
    k.px(11, 17, "pink"); k.px(12, 17, "pink"); k.px(6, 17, "pink"); k.px(17, 17, "pink")
    k.outline("ink")
    return k


def alien() -> Canvas:
    k = Canvas(CELL, CELL)
    for s in (-1, 1):
        k.line(12 + s * 3, 6, 12 + s * 6, 2, "leaf"); mc.disc(k, 12 + s * 6 + 0.5, 2.5, 1.6, "sprout")
    mc.sphere(k, 12, 13, 8, 7, ["sprout", "leaf", "leaf", "green"])
    for x0 in (7, 13):
        k.rect(x0, 10, 4, 5, "ink"); k.px(x0, 10, "white"); k.px(x0 + 1, 10, "white"); k.px(x0, 11, "white")
    k.px(6, 16, "pink"); k.px(17, 16, "pink"); k.hline(11, 12, 17, "green")
    k.outline("ink")
    return k


def bear() -> Canvas:
    """Ursinho de pelúcia (cliente d'O Quarto / Silvânia)."""
    k = Canvas(CELL, CELL)
    for ex in (5, 18):
        mc.disc(k, ex, 6, 3.4, "copper"); mc.disc(k, ex, 6, 1.6, "rust")
    mc.sphere(k, 11.5, 13, 8, 7, ["honey", "copper", "copper", "rust"])
    mc.sphere(k, 11.5, 16, 3.6, 2.6, ["cream", "cream", "peach", "peach"])
    for x in (8, 15):
        k.px(x, 11, "ink"); k.px(x, 12, "ink"); k.px(x, 11, "white")
    k.px(11, 15, "ink"); k.px(12, 15, "ink")
    k.outline("ink")
    return k


def star(on: bool) -> Canvas:
    """Estrela de dificuldade 11x11 no centro da célula."""
    k = Canvas(CELL, CELL)
    rows = [".....#.....", "....###....", "....###....", "###########", ".#########.", "..#######..",
            "..#######..", ".####.####.", ".###...###.", "##.......##", "..........."]
    col = "gold" if on else "slate"
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch == "#":
                k.px(6 + x, 6 + y, col)
    if on:
        k.px(10, 9, "lemon"); k.px(11, 8, "white"); k.px(9, 10, "lemon"); k.px(10, 10, "lemon")
        for x, y in ((14, 14), (15, 13), (13, 15)):
            k.px(x, y, "amber")
    k.outline("ink")
    return k


def coins() -> Canvas:
    """Pilha de moedas (prêmio) 20x18."""
    k = Canvas(CELL, CELL)
    for cx, cy in ((8, 16), (16, 16), (12, 9)):
        mc.sphere(k, cx, cy, 5.2, 5.2, ["lemon", "gold", "gold", "amber"])
        k.vline(int(cx), int(cy) - 2, int(cy) + 2, "amber")
    k.outline("ink")
    return k


def ship() -> Canvas:
    """Navezinha do gatinho (início da trilha) ~18x18."""
    k = Canvas(CELL, CELL)
    mc.sphere(k, 12, 9, 6, 6, ["white", "pale_sky", "pale_sky", "sky"])
    mc.disc(k, 12, 10, 3.2, "orange"); k.px(10, 8, "orange"); k.px(14, 8, "orange")
    k.px(11, 10, "ink"); k.px(13, 10, "ink")
    for y in range(14, 18):
        k.hline(6, 17, y, "mist" if y < 16 else "steel")
    k.line(7, 18, 4, 21, "lilac_grey"); k.line(16, 18, 19, 21, "lilac_grey")
    k.hline(3, 5, 21, "slate"); k.hline(18, 20, 21, "slate")
    k.hline(11, 12, 18, "gold"); k.hline(11, 12, 19, "orange")
    k.outline("ink")
    return k


# ------------------------------------------------------------------ figuras "antes -> depois" da Oficina (2026-10-05)
# Usuário: até "leva mais gás" é adulto; uma criança de 6 anos tem que entender → o cartão mostra o EFEITO em figura.
FIRE = ["lemon", "gold", "orange", "red"]


def _canvas() -> Canvas:
    return Canvas(CELL, CELL)


def flame(big: bool) -> Canvas:
    """Chama do motor: pequena x grande (o motor fica mais forte)."""
    k = _canvas()
    h, w = (19, 7.5) if big else (9, 4)
    top = 23 - h
    for y in range(top, 23):
        t = (y - top) / h                                        # 0 no topo (ponta) .. 1 na base redonda
        half = w * (t ** 0.6) if t < 0.75 else w * math.sqrt(max(0.0, 1 - ((t - 0.75) / 0.25) ** 2)) ** 0.5
        for x in range(int(12 - half), int(12 + half) + 1):
            d = abs(x + 0.5 - 12) / max(half, 0.5)
            k.px(x, y, FIRE[0] if d < 0.3 and t > 0.35 else FIRE[1] if d < 0.6 else FIRE[2] if d < 0.85 else FIRE[3])
    k.outline("ink")
    return k


def gas_bar(full: bool) -> Canvas:
    """Barrinha de gás: curtinha x comprida (cabe mais gás)."""
    k = _canvas()
    k.rect(2, 8, 20, 8, "slate")
    n = 18 if full else 5
    k.rect(3, 9, n, 6, "aqua"); k.hline(3, 2 + n, 9, "ice"); k.hline(3, 2 + n, 14, "sea")
    k.outline("ink")
    return k


def drop(big: bool) -> Canvas:
    """Gota de gás: grande x pequena (gasta menos)."""
    k = _canvas()
    r = 7 if big else 4
    cy = 23 - r - 1
    mc.sphere(k, 12, cy, r, r, ["ice", "aqua", "aqua", "sea"])
    for i in range(int(r * 1.4)):                                # ponta da gota
        half = r * (i / (r * 1.4))
        for x in range(int(12 - half), int(12 + half) + 1):
            if k.get(x, int(cy - r * 1.4 + i)) is None:
                k.px(x, int(cy - r * 1.4 + i), "aqua" if x < 13 else "sea")
    k.px(10, cy - 1, "white")
    k.outline("ink")
    return k


def coin_one() -> Canvas:
    k = _canvas()
    mc.sphere(k, 12, 15, 5.2, 5.2, ["lemon", "gold", "gold", "amber"])
    k.vline(12, 13, 17, "amber")
    k.outline("ink")
    return k


def pad(wide: bool) -> Canvas:
    """Plataforma estreita x larga (pousar fica mais fácil)."""
    k = _canvas()
    half = 10 if wide else 4
    k.rect(12 - half, 15, half * 2, 3, "mist"); k.hline(12 - half, 11 + half, 15, "white")
    k.hline(12 - half, 11 + half, 17, "steel")
    for x in (12 - half + 1, 11 + half - 1):
        k.vline(x, 18, 21, "lilac_grey")
    k.px(12 - half, 14, "aqua"); k.px(11 + half, 14, "aqua")
    k.outline("ink")
    return k


def rock() -> Canvas:
    """Pedrinha de minério (vira gás na refinaria)."""
    k = _canvas()
    mc.sphere(k, 12, 15, 7, 5.5, ["honey", "copper", "terracotta", "rust"])
    k.px(10, 13, "lemon"); k.px(14, 16, "rust"); k.px(9, 17, "rust")
    k.outline("ink")
    return k


def _drone(k: Canvas, cx: int, cy: int) -> None:
    mc.sphere(k, cx, cy, 4.5, 3.5, ["white", "mist", "steel", "lilac_grey"])
    mc.disc(k, cx, cy - 0.5, 1.6, "aqua")
    k.hline(cx - 6, cx - 3, cy - 5, "slate"); k.hline(cx + 3, cx + 6, cy - 5, "slate")
    k.vline(cx - 4, cy - 4, cy - 3, "slate"); k.vline(cx + 4, cy - 4, cy - 3, "slate")


def drone(n: int = 1, coin: bool = False) -> Canvas:
    k = _canvas()
    if n == 1:
        _drone(k, 12 if not coin else 9, 13)
    else:
        _drone(k, 7, 10); _drone(k, 16, 17)
    if coin:
        mc.sphere(k, 18, 17, 3.6, 3.6, ["lemon", "gold", "gold", "amber"])
    k.outline("ink")
    return k


def arrow() -> Canvas:
    k = _canvas()
    k.rect(4, 11, 9, 3, "white")
    for i in range(6):
        k.vline(13 + i, 7 + i, 17 - i, "white")
    k.outline("ink")
    return k


def lock() -> Canvas:
    """Cadeado (coisa que ainda vai liberar): alça de metal em arco + corpo dourado com fechadura."""
    k = _canvas()
    k.paint(["...sssl...",
             "..ss..ll..",
             ".ss....ll.",
             ".s......l.",
             ".s......l.",
             ".s......l.",
             ".s......l."], {"s": "steel", "l": "lilac_grey"}, x=7, y=5)
    k.rect(6, 12, 12, 9, "gold")
    k.hline(6, 17, 12, "lemon"); k.vline(6, 13, 20, "lemon")
    k.hline(7, 17, 20, "amber"); k.vline(17, 13, 19, "amber")
    k.paint([".kk.",
             "kkkk",
             ".kk.",
             ".kk."], {"k": "ink"}, x=10, y=14)
    k.outline("ink")
    return k


def mystery() -> Canvas:
    """Bolacha com "?" (algo que existe mas ainda é surpresa)."""
    k = badge(["lilac_grey", "slate", "slate", "ink"])
    k.paint([".wwww.",
             "ww..ww",
             "....ww",
             "...ww.",
             "..ww..",
             "......",
             "..ww..",
             "..ww.."], {"w": "white"}, x=9, y=8)
    return k


NAMES = ["pin", "pin_sel", "pin_off", "rat", "bunny", "alien", "bear", "star_on", "star_off", "coins", "ship",
         "flame_s", "flame_b", "bar_s", "bar_b", "drop_b", "drop_s", "coin", "pad_s", "pad_b", "rock", "drone",
         "drones", "drone_coin", "arrow", "lock", "mystery"]


def build() -> Canvas:
    parts = [badge(["white", "white", "cream", "peach"]), badge(["white", "lemon", "lemon", "gold"], rim="hot_pink"),
             badge(["mist", "steel", "steel", "lilac_grey"]), rat(), bunny(), alien(), bear(), star(True), star(False),
             coins(), ship(), flame(False), flame(True), gas_bar(False), gas_bar(True), drop(True), drop(False),
             coin_one(), pad(False), pad(True), rock(), drone(), drone(2), drone(1, True), arrow(), lock(), mystery()]
    cv = Canvas(CELL * len(parts), CELL)
    for i, p in enumerate(parts):
        cv.stamp(p, i * CELL, 0)
    return cv


if __name__ == "__main__":
    cv = build()
    if "--export" in sys.argv:
        cv.save("assets/ui/kids.png", preview=False)
        with open("assets/ui/kids.json", "w") as f:
            json.dump({"notes": "Gerado por art/src/ui/kids_ui.py (pixel-art). Células quadradas na ordem de names.",
                       "size": CELL, "names": NAMES}, f, indent=2)
        print("exportado")
    else:
        cv.preview("art/previews/kids_ui_preview.png", scale=4, grid=False, bg="dark", show_1x=True)
        print("ok")
