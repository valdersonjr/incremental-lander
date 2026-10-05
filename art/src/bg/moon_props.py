"""Peças de cenário da Lua de queijo (2026-10-04). Skill pixel-art, receita cute-scene-method.

Usuário: "o background sempre tem as mesmas coisas" → o fundo dos morros vira 3 trechos (1920 px de laço):
  1 Mina dos ratinhos  ·  2 Vila dos coelhos  ·  3 Parquinho lunar   (a guerra continua no céu).
Cada peça: contorno ink (objeto), volume com sphere(), animação em FR=4 quadros (fr = 0..3).
Usado por moon_cute.py (mid_layer). Rodar a prévia das peças: python3 art/src/bg/moon_props.py
"""
import math
import sys

sys.path.insert(0, ".claude/skills/pixel-art/scripts")
from pixelart import *

FR = 4


def _h():
    import moon_cute as mc
    return mc


def ol(k: Canvas) -> Canvas:
    k.outline("ink")
    return k


GREY = ["mist", "steel", "lilac_grey", "slate"]
WOOD = ["copper", "rust", "rust", "wine"]


# ------------------------------------------------------------------ 1. mina dos ratinhos
def mouse(fr: int, phase: int = 0, helmet: bool = True) -> Canvas:
    """Ratinho de capacete com lanterna (14x13), quica ao andar."""
    mc = _h()
    up = 1 if (fr + phase) % FR in (1, 3) else 0
    k = Canvas(14, 13)
    mc.sphere(k, 6, 9 - up, 4.2, 2.8, GREY)                       # corpo
    mc.sphere(k, 9.5, 6 - up, 3.2, 3, GREY)                       # cabeça
    mc.disc(k, 7.5, 3 - up, 1.9, "steel"); k.px(7, 3 - up, "pink")  # orelha
    k.px(12, 7 - up, "pink")                                      # nariz
    k.px(10, 5 - up, "ink"); k.px(10, 6 - up, "ink")              # olhinho
    k.px(9, 7 - up, "pink")                                       # bochecha
    k.line(2, 9 - up, 0, 7 - up, "pink")                          # rabo
    k.px(4 + (fr + phase) % 2, 12 - up, "slate"); k.px(8 - (fr + phase) % 2, 12 - up, "slate")
    if helmet:
        k.hline(7, 11, 3 - up, "gold"); k.hline(8, 11, 2 - up, "gold"); k.px(12, 3 - up, "lemon")
    return ol(k)


def door(lit: bool = True) -> Canvas:
    """Portinha-toca na encosta (14x16): arco de madeira, porta redonda, janelinha acesa e lampião."""
    mc = _h()
    k = Canvas(14, 16)
    for y in range(3, 16):
        for x in range(2, 12):
            if ((x + 0.5 - 7) / 5) ** 2 + ((y + 0.5 - 8) / 5) ** 2 <= 1 or y >= 8:
                k.px(x, y, "rust")
    for y in range(5, 16):
        for x in range(4, 10):
            if ((x + 0.5 - 7) / 3) ** 2 + ((y + 0.5 - 8.5) / 3.2) ** 2 <= 1 or y >= 9:
                k.px(x, y, "wine")
    k.px(8, 11, "gold")                                           # maçaneta
    mc.disc(k, 7, 7, 1.2, "gold" if lit else "umber")
    k.px(12, 4, "lemon" if lit else "honey")
    return ol(k)


def cart(fr: int) -> Canvas:
    """Carrinho de mina cheio de queijo (20x14), rodas girando."""
    mc = _h()
    k = Canvas(20, 14)
    for y in range(5, 11):
        inset = (y - 5) // 3
        for x in range(2 + inset, 18 - inset):
            k.px(x, y, "lilac_grey" if x > 13 else "steel" if y > 6 else "mist")
    for cx, cy, r in ((6, 4, 2.5), (10, 3, 3), (14, 4, 2.4)):     # queijo
        mc.sphere(k, cx, cy, r, r * 0.8, ["lemon", "gold", "gold", "amber"])
    k.px(10, 3, "amber")
    for wx in (6, 14):
        mc.disc(k, wx, 11.5, 2, "charcoal")
        k.px(wx + (1 if fr % 2 else 0), 11 + (0 if fr % 2 else 1), "steel")
    return ol(k)


def shaft() -> Canvas:
    """Boca de poço da mina (18x22): cavalete de madeira com roldana sobre o buraco e a escada descendo nele.
    Usuário (2026-10-04): escada solta na montanha "nada a ver" — escada só existe onde leva a algum lugar."""
    mc = _h()
    k = Canvas(18, 22)
    k.vline(2, 3, 18, "rust"); k.vline(15, 3, 18, "rust")         # postes
    k.hline(1, 16, 3, "copper"); k.hline(2, 15, 4, "rust")        # travessa
    mc.disc(k, 8.5, 6, 1.4, "slate"); k.vline(8, 7, 12, "bone")   # roldana + corda
    k.rect(7, 12, 3, 2, "gold")                                   # baldinho de queijo
    for y in range(17, 22):                                       # buraco (some no chão)
        k.hline(3, 14, y, "wine" if y == 17 else "ink")
    k.hline(0, 17, 17, "copper")                                  # tábuas da borda
    k.vline(5, 9, 21, "rust"); k.vline(11, 9, 21, "rust")         # escada saindo do poço
    for y in range(10, 22, 3):
        k.hline(6, 10, y, "copper")
    return ol(k)


def crane(fr: int) -> Canvas:
    """Guindastezinho de madeira com balde de queijo que sobe e desce (26x34)."""
    mc = _h()
    k = Canvas(26, 34)
    k.line(4, 33, 9, 4, "rust"); k.line(14, 33, 9, 4, "rust")     # cavalete
    k.hline(6, 12, 20, "copper")
    k.line(9, 4, 22, 4, "copper"); k.line(9, 5, 22, 5, "rust")    # braço
    mc.disc(k, 21.5, 7, 1.6, "slate")                             # roldana
    dy = [0, 2, 4, 2][fr]
    k.vline(21, 8, 14 + dy, "bone")
    for y in range(15 + dy, 21 + dy):
        k.hline(18, 24, y, "lilac_grey" if y > 16 + dy else "steel")
    mc.sphere(k, 21, 14 + dy, 3, 2, ["lemon", "gold", "gold", "amber"])
    return ol(k)


def cheese_pile() -> Canvas:
    """Montinho de fatias de queijo (24x16)."""
    k = Canvas(24, 16)
    for x0, y0, w, h in ((2, 7, 12, 8), (11, 6, 11, 9), (6, 1, 11, 7)):
        for y in range(h):
            span = int(w * (y + 1) / h)
            for x in range(x0 + w - span, x0 + w):
                k.px(x, y0 + y, "lemon" if y < 2 else "gold" if x < x0 + w - 2 else "amber")
    for x, y in ((9, 11), (17, 12), (13, 5)):
        k.px(x, y, "amber"); k.px(x + 1, y, "copper")
    return ol(k)


# ------------------------------------------------------------------ 2. vila dos coelhos
def hut(size: float = 1.0, lit: bool = True) -> Canvas:
    """Casinha redonda de coelho: parede creme com volume, telhado de palha cônico, porta redonda, janela acesa."""
    mc = _h()
    w, h = int(30 * size), int(30 * size)
    k = Canvas(w + 2, h + 2)
    cx = w / 2
    wall_top = int(h * 0.45)
    for y in range(wall_top, h):
        for x in range(int(w * 0.12), int(w * 0.88)):
            u = (x + 0.5 - cx) / (w * 0.38)
            k.px(x, y, "white" if u < -0.4 else "cream" if u < 0.45 else "peach")
    for y in range(2, wall_top + 3):                              # telhado
        half = (y - 1) / (wall_top + 2) * w * 0.52
        for x in range(int(cx - half), int(cx + half) + 1):
            k.px(x, y, "honey" if x < cx - half * 0.2 else "copper" if x < cx + half * 0.6 else "rust")
            if (x + y) % 5 == 0 and y > 4:
                k.px(x, y, "rust")
    mc.disc(k, cx, 1.5, 1.5, "copper")
    dw = max(3, int(w * 0.18))
    for y in range(h - int(h * 0.32), h):
        for x in range(int(cx - dw / 2), int(cx + dw / 2) + 1):
            k.px(x, y, "rust" if x < cx + dw / 2 - 1 else "wine")
    mc.disc(k, cx - w * 0.25, wall_top + h * 0.2, max(1.4, 2 * size), "gold" if lit else "umber")
    return ol(k)


def mallet_bunny(fr: int, left: bool) -> Canvas:
    """Coelhinho segurando o martelo do mochi (o martelo sobe e desce)."""
    mc = _h()
    up = (fr % 2 == 0) if left else (fr % 2 == 1)
    b = mc.bunny(0, 0)
    k = Canvas(26, 24)
    k.stamp(b, 4, 6)
    hx, hy = (19, 2) if up else (21, 14)
    k.line(12, 16, hx, hy + 2, "copper")
    k.rect(hx - 2, hy, 6, 4, "rust"); k.hline(hx - 2, hx + 3, hy, "copper")
    if not left:
        k.flip_h()
    return ol(k)


def mochi(fr: int) -> Canvas:
    """Dois coelhinhos socando mochi no pilão (56x30)."""
    mc = _h()
    k = Canvas(56, 30)
    for y in range(20, 29):                                       # pilão
        inset = (y - 20) // 3
        for x in range(19 + inset, 37 - inset):
            k.px(x, y, "copper" if x < 24 else "rust" if x < 33 else "wine")
    squash = 1 if fr % 2 == 0 else 0
    mc.sphere(k, 28, 19 + squash, 7, 3 - squash, ["white", "white", "cream", "peach"])
    k.stamp(mallet_bunny(fr, True), 0, 4)
    k.stamp(mallet_bunny(fr, False), 30, 4)
    return k


def carrots(w: int) -> Canvas:
    """Canteiro de cenouras: fileira de folhinhas com a pontinha laranja aparecendo."""
    k = Canvas(w, 10)
    for x in range(0, w, 1):
        k.px(x, 8, "berry_dark"); k.px(x, 9, "berry_dark")
    for x in range(2, w - 2, 5):
        k.px(x, 7, "orange"); k.px(x + 1, 7, "orange"); k.px(x, 8, "orange")
        k.line(x, 6, x - 1, 2, "leaf"); k.line(x + 1, 6, x + 2, 3, "green"); k.px(x, 4, "sprout")
    return k


def windmill(fr: int) -> Canvas:
    """Moinho com pás girando (36x46; 4 quadros = 22,5° cada, laço de 90°)."""
    mc = _h()
    k = Canvas(36, 46)
    for y in range(20, 46):
        half = 4 + (y - 20) * 0.18
        for x in range(int(18 - half), int(18 + half) + 1):
            k.px(x, y, "white" if x < 16 else "cream" if x < 20 else "peach")
    for y in range(14, 22):
        half = (y - 13) * 0.9
        for x in range(int(18 - half), int(18 + half) + 1):
            k.px(x, y, "rose" if x < 19 else "berry")
    mc.disc(k, 18, 32, 2, "gold")
    a0 = fr * math.pi / 8
    for i in range(4):
        a = a0 + i * math.pi / 2
        for t in range(3, 16):
            x, y = 18 + math.cos(a) * t, 15 + math.sin(a) * t
            k.px(int(round(x)), int(round(y)), "white" if t > 6 else "copper")
            if t > 6:
                k.px(int(round(x - math.sin(a))), int(round(y + math.cos(a))), "mist")
    mc.disc(k, 18, 15, 1.6, "rust")
    return ol(k)


def lanterns(w: int, fr: int, sag: int = 6) -> Canvas:
    """Varal de lanternas de papel entre dois pontos (w de largura), piscando."""
    mc = _h()
    k = Canvas(w, sag + 8)
    for x in range(w):
        y = int(sag * math.sin(math.pi * x / (w - 1)))
        k.px(x, y, "umber")
    for i, x in enumerate(range(5, w - 3, 9)):
        y = int(sag * math.sin(math.pi * x / (w - 1))) + 1
        lit = (i + fr) % 3 != 0
        col = ["hot_pink", "gold", "aqua"][i % 3]
        k.rect(x - 1, y, 3, 4, col if lit else "berry_dark")
        if lit:
            k.px(x - 1, y, "white")
        k.px(x, y + 4, "umber")
    return k


# ------------------------------------------------------------------ 3. parquinho lunar
GONDOLA = ["hot_pink", "gold", "aqua", "lavender", "salmon", "leaf", "sky", "orange"]


def ferris(fr: int) -> Canvas:
    """Roda-gigante girando (laço de 4 quadros = 1/8 de volta) com 8 cabines coloridas."""
    mc = _h()
    k = Canvas(72, 80)
    cx, cy, R = 36, 32, 27
    k.line(cx, cy, 14, 79, "steel"); k.line(cx, cy, 58, 79, "steel")    # pés
    k.line(cx + 1, cy, 15, 79, "lilac_grey"); k.line(cx + 1, cy, 59, 79, "lilac_grey")
    for a10 in range(0, 3600, 4):                                      # aro
        a = a10 / 10 * math.pi / 180
        k.px(int(round(cx + math.cos(a) * R)), int(round(cy + math.sin(a) * R)), "lavender")
        k.px(int(round(cx + math.cos(a) * (R - 1))), int(round(cy + math.sin(a) * (R - 1))), "violet")
    a0 = fr * (math.pi / 4) / FR
    for i in range(8):
        a = a0 + i * math.pi / 4
        k.line(cx, cy, int(round(cx + math.cos(a) * R)), int(round(cy + math.sin(a) * R)), "mist")
    for i in range(8):
        a = a0 + i * math.pi / 4
        gx, gy = cx + math.cos(a) * R, cy + math.sin(a) * R
        mc.sphere(k, gx, gy + 4, 3.4, 3, [GONDOLA[i], GONDOLA[i], GONDOLA[i], "berry_dark"])
        k.px(int(gx), int(gy + 1), "steel")
    mc.disc(k, cx, cy, 3, "gold"); k.px(cx - 1, cy - 1, "lemon")
    return ol(k)


def balloon(fr: int, color: str, phase: int = 0, string: int = 12) -> Canvas:
    """Balão preso: o fio termina embaixo (y = h-1), no ponto onde está amarrado."""
    mc = _h()
    up = [0, 1, 2, 1][(fr + phase) % FR]
    k = Canvas(12, 13 + string)
    mc.sphere(k, 6, 6 - up, 4.5, 5.5, ["white", color, color, "berry_dark"])
    k.px(6, 12 - up, color)
    for y in range(13 - up, k.h):
        k.px(6 + (1 if (y // 3) % 2 else 0), y, "bone")
    return ol(k)


def toy_rocket(fr: int) -> Canvas:
    """Foguetinho de brinquedo (brinquedo do parque) com chaminha piscando."""
    mc = _h()
    k = Canvas(14, 26)
    for y in range(4, 20):
        for x in range(4, 10):
            k.px(x, y, "white" if x < 6 else "mist" if x < 8 else "steel")
    for y in range(0, 5):
        half = y * 0.7
        for x in range(int(7 - half), int(7 + half) + 1):
            k.px(x, y, "red")
    k.line(4, 15, 1, 20, "red"); k.line(9, 15, 12, 20, "red"); k.hline(1, 3, 20, "red"); k.hline(10, 12, 20, "red")
    mc.disc(k, 7, 9, 1.8, "sky"); k.px(6, 8, "white")
    fl = 3 if fr % 2 else 2
    for y in range(20, 20 + fl + 2):
        k.hline(6, 7, y, "lemon" if y < 22 else "orange")
    return ol(k)


def tent() -> Canvas:
    """Barraquinha listrada com bandeirinha (32x30)."""
    k = Canvas(32, 30)
    for y in range(4, 16):
        half = (y - 3) * 1.25
        for x in range(int(16 - half), int(16 + half) + 1):
            k.px(x, y, "red" if ((x - 16) // 3) % 2 == 0 else "white")
    for x in range(2, 30):
        k.px(x, 16, "red" if (x // 3) % 2 == 0 else "white")
        if x % 3 == 1:
            k.px(x, 17, "red" if (x // 3) % 2 == 0 else "white")
    for y in range(18, 30):
        k.hline(4, 27, y, "copper" if y < 21 else "rust")
    k.vline(4, 16, 29, "wine"); k.vline(27, 16, 29, "wine")
    k.vline(16, 0, 4, "bone"); k.rect(17, 0, 4, 2, "aqua")
    for x, c in ((9, "gold"), (14, "hot_pink"), (19, "aqua"), (23, "lemon")):
        k.px(x, 20, c); k.px(x, 19, c)
    return ol(k)


def bunting(w: int, sag: int = 5, dy: int = 0) -> Canvas:
    """Varal de bandeirinhas de (0, base) até (w-1, base+dy): as duas pontas presas em algo (stamp em min(y))."""
    base = max(0, -dy)
    k = Canvas(w, sag + 6 + abs(dy))
    cols = ["hot_pink", "gold", "aqua", "lavender", "leaf"]
    yat = lambda x: int(base + dy * x / (w - 1) + sag * math.sin(math.pi * x / (w - 1)))
    for x in range(w):
        k.px(x, yat(x), "umber")
    for i, x in enumerate(range(3, w - 4, 7)):
        y = yat(x) + 1
        for d in range(4):
            k.hline(x + d // 2, x + 3 - d // 2, y + d, cols[i % len(cols)])
    return k


if __name__ == "__main__":
    sys.path.insert(0, "art/src/bg"); sys.path.insert(0, "art/src/terrain")
    import moon_cute as mc
    from PIL import Image
    sheet = Canvas(360, 120)
    items = [(mouse(0), 4, 4), (door(), 24, 2), (cart(0), 44, 4), (shaft(), 66, 2), (crane(0), 82, 2),
             (cheese_pile(), 112, 10), (hut(1.0), 140, 0), (hut(0.75), 176, 8), (mochi(0), 206, 2),
             (windmill(0), 266, 0), (carrots(40), 306, 20), (ferris(0), 4, 36), (balloon(0, "hot_pink"), 80, 40),
             (balloon(0, "gold"), 94, 44), (toy_rocket(0), 110, 50), (tent(), 128, 50), (bunting(60), 164, 50),
             (lanterns(60, 0), 230, 50)]
    for k, x, y in items:
        sheet.stamp(k, x, y)
    sheet.preview("art/previews/moon_props.png", scale=4, grid=False, bg="dark", show_1x=False)
    print("ok")
