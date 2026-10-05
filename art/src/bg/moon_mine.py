"""Mina de queijo dos ratinhos (2026-10-05). Skill pixel-art, receita cute-scene-method.

Usuário: "a ideia era ter ratinhos minerando queijo na lua... tem que ter tudo que envolve a extração, carrinhos
personalizados dos ratinhos com caminhões". Plano de profundidade aprovado (art/previews/moon_mine_plan.html):
  longe = serra com degraus · meio = 3 cenários (extração · beneficiamento · expedição) · perto = estrada.
Regra: nada liga dois planos (cada um rola numa velocidade); o corte no morro mostra o queijo por dentro
(a casca do morro é poeira lunar amora; dentro é queijo) — é o que diz "aqui se minera queijo".

Peças: contorno ink nos objetos, volume com sphere(), animação em FR=4 quadros. Usado por moon_cute.py.
Prévia das peças: python3 art/src/bg/moon_mine.py
"""
import math
import random
import sys

sys.path.insert(0, ".claude/skills/pixel-art/scripts")
from pixelart import *

FR = 4
CHEESE = ["lemon", "gold", "gold", "amber"]


def _h():
    import moon_cute as mc
    return mc


def ol(k: Canvas) -> Canvas:
    k.outline("ink")
    return k


# ------------------------------------------------------------------ morro da pedreira (meia resolução)
# silhueta (x, altura) em meia resolução; o x é multiplicado por 1,7 em profile_from (morro largo e redondo)
MINE_HILL = [(0, 0), (8, 15), (18, 32), (28, 45), (38, 53), (46, 55), (54, 54), (62, 50), (72, 44), (82, 30),
             (90, 14), (96, 0)]
# degraus da pedreira no flanco direito (colunas em meia res. já esticadas): (x inicial, altura do degrau)
STEPS = [(84, 44), (98, 32), (126, 3)]
WEDGE = (34, 86, 34)                                            # fundo do corte: altura 34 em x=86, chega a 0 em x=120


def step_h(x: int):
    h = None
    for x0, hh in STEPS:
        if x >= x0:
            h = hh
    return h


def mine_hill(ramp: list, ol_color: str, tex: list) -> tuple:
    """Morro grande com a pedreira em degraus: casca amora + queijo exposto no corte. Devolve (peça 2x,
    lista de degraus em px da peça ampliada: (x0, x1, y do piso))."""
    mc = _h()
    hs = mc.profile_from(MINE_HILL)
    h = int(max(hs)) + 2
    k = Canvas(len(hs), h)
    surf = []
    for x, hh in enumerate(hs):
        s = step_h(x)
        top = hh if s is None else min(hh, s)
        surf.append(top)
        if top >= 0.5:
            k.vline(x, int(h - 1 - top), h - 1, ramp[2])
    mc.shade_piece(k, ramp, h - 1, 6)
    rng = random.Random(5)
    for _ in range(6):                                          # covinhas na casca
        x = rng.randrange(6, 84)
        y = rng.randint(int(h - 1 - hs[x]) + 5, h - 4)
        if k.get(x - 1, y) and k.get(x + 1, y):
            k.px(x - 1, y, tex[0]); k.px(x, y, tex[0]); k.px(x, y + 1, tex[1])
    # queijo exposto: faixa abaixo de cada degrau, riser (face virada à direita) na sombra
    for x in range(len(hs)):
        s = step_h(x)
        if s is None or s >= hs[x]:
            continue
        top = int(h - 1 - surf[x])
        nxt = step_h(x + 2)
        riser = nxt is not None and nxt < s
        low = max(0.0, WEDGE[0] * (1 - (x - WEDGE[1]) / WEDGE[2]))   # fundo do corte (diagonal dentro do morro)
        bottom = int(h - 1 - low)
        for y in range(top, h):
            if y > bottom:
                break
            d = y - top
            c = "lemon" if d == 0 else "honey" if d == 1 else "gold"
            if riser and d:
                c = "amber"
            if y == bottom and low > 0:
                c = "copper"
            k.px(x, y, c)
    for x, y in ((92, 4), (104, 6), (115, 4), (95, 10), (108, 12), (130, 1)):        # furinhos do queijo
        yy = int(h - 1 - surf[x]) + y
        k.px(x, yy, "amber"); k.px(x + 1, yy, "amber"); k.px(x, yy + 1, "copper")
    k.outline(ol_color, inside=True)
    big = mc.scale2x(k)
    steps = []
    for i, (x0, hh) in enumerate(STEPS):
        x1 = STEPS[i + 1][0] if i + 1 < len(STEPS) else len(hs)
        steps.append((x0 * 2, x1 * 2, (h - 1 - hh) * 2))
    return big, steps


# ------------------------------------------------------------------ peças da extração
def tunnel(fr: int) -> Canvas:
    """Boca do túnel escorada (30x30): arco de vigas, escuro com o trilho entrando, lampião piscando."""
    mc = _h()
    k = Canvas(30, 30)
    for y in range(4, 30):
        for x in range(3, 27):
            if ((x + 0.5 - 15) / 12) ** 2 + ((y + 0.5 - 16) / 12) ** 2 <= 1 or y >= 16:
                k.px(x, y, "copper" if x < 9 or y < 9 else "rust")
    for y in range(8, 30):
        for x in range(7, 23):
            if ((x + 0.5 - 15) / 8) ** 2 + ((y + 0.5 - 17) / 9) ** 2 <= 1 or y >= 17:
                k.px(x, y, "plum_dark" if y < 20 else "ink")
    for x in range(8, 22):                                      # trilho sumindo no escuro
        k.px(x, 27, "slate" if x % 3 else "rust")
    k.hline(9, 21, 26, "lilac_grey")
    k.vline(4, 16, 29, "honey"); k.vline(25, 16, 29, "wine")     # vigas laterais
    k.hline(2, 27, 15, "honey"); k.hline(3, 26, 16, "rust")     # viga de cima
    lit = fr % 4 != 2
    k.px(15, 6, "umber"); k.vline(15, 7, 8, "umber")             # lampião pendurado na viga
    mc.disc(k, 15, 11, 1.6, "lemon" if lit else "gold")
    k.px(15, 13, "rust")
    return ol(k)


def pick_mouse(fr: int, phase: int = 0, flip: bool = False) -> Canvas:
    """Ratinho mineiro (22x20): capacete com lanterna e picareta que sobe e desce."""
    import moon_props as mp
    m = mp.mouse(0, 0)
    k = Canvas(22, 20)
    k.stamp(m, 0, 3)
    up = (fr + phase) % 2 == 0
    hx, hy = (15, 9) if True else (0, 0)
    if up:                                                      # cabo inclinado para trás, ponta no alto
        k.line(hx, hy + 4, hx + 3, hy - 6, "copper")
        k.line(hx, hy - 6, hx + 6, hy - 6, "steel"); k.px(hx - 1, hy - 5, "steel"); k.px(hx + 7, hy - 5, "steel")
    else:                                                       # golpe: cabo deitado, ponta batendo no chão
        k.line(hx, hy + 4, hx + 6, hy + 6, "copper")
        k.line(hx + 6, hy + 2, hx + 6, hy + 9, "steel"); k.px(hx + 7, hy + 9, "steel")
        k.px(hx + 8, hy + 8, "lemon"); k.px(hx + 7, hy + 6, "white")   # faísca de queijo
    k = ol(k)
    if flip:
        k.flip_h()
    return k


def drill(fr: int) -> Canvas:
    """Perfuratriz dos ratinhos (52x30): esteira, cabine redonda com o piloto, braço com broca em espiral girando."""
    import moon_props as mp
    mc = _h()
    k = Canvas(52, 30)
    for y in range(22, 29):                                     # esteira
        for x in range(3, 31):
            if ((x - 3) < 3 and abs(y - 25.5) > (x - 3) + 1.5) or ((30 - x) < 3 and abs(y - 25.5) > (30 - x) + 1.5):
                continue
            k.px(x, y, "charcoal" if y in (22, 28) else "slate")
    for i, x in enumerate(range(6, 29, 5)):
        mc.disc(k, x + 0.5, 25.5, 1.5, "lilac_grey")
        k.px(x, 25, "steel")
    for x in range(4, 30):
        if (x + fr) % 3 == 0:
            k.px(x, 22, "lilac_grey"); k.px(x, 28, "lilac_grey")
    mc.sphere(k, 17, 16, 13, 7, ["lemon", "gold", "amber", "copper"], clip=lambda x, y: y <= 21)   # corpo
    k.hline(5, 29, 21, "rust")
    for y in range(3, 15):                                      # cabine de vidro
        for x in range(8, 24):
            if ((x + 0.5 - 15.5) / 7.5) ** 2 + ((y + 0.5 - 13) / 9) ** 2 <= 1 and y <= 14:
                k.px(x, y, "pale_sky" if x < 18 else "sky")
    m = mp.mouse(0, 0)                                          # piloto (cabeça aparecendo)
    head = m.crop(6, 0, 12, 12)
    k.stamp(head, 10, 3)
    k.px(10, 6, "white"); k.px(11, 5, "white")
    k.hline(8, 23, 14, "copper")
    k.rect(28, 13, 8, 4, "steel"); k.hline(28, 35, 13, "mist")  # braço
    k.rect(35, 11, 3, 8, "lilac_grey")
    for x in range(38, 51):                                     # broca cônica com espiral
        half = 4.5 * (1 - (x - 38) / 13)
        for y in range(int(15 - half), int(15 + half) + 1):
            stripe = (x + y * 2 + fr * 2) % 6 < 3
            k.px(x, y, "mist" if stripe else "steel")
    k.px(51, 15, "steel")
    mc.disc(k, 25, 17, 1.4, "hot_pink" if fr % 2 else "rose")   # luzinha
    return ol(k)


def rails(w: int) -> Canvas:
    """Trilho visto de lado (w x 3): dormentes de madeira + barra de aço."""
    k = Canvas(w, 3)
    k.hline(0, w - 1, 0, "steel"); k.hline(0, w - 1, 1, "lilac_grey")
    for x in range(1, w, 5):
        k.px(x, 2, "rust"); k.px(x + 1, 2, "rust"); k.px(x + 2, 2, "wine")
    return k


def sign(fr: int) -> Canvas:
    """Plaquinha com fatia de queijo e picareta (16x22): avisa que é a mina, sem texto."""
    mc = _h()
    k = Canvas(16, 22)
    k.vline(7, 10, 21, "rust"); k.vline(8, 10, 21, "copper")
    k.rect(1, 1, 14, 10, "honey"); k.hline(1, 14, 1, "lemon"); k.hline(1, 14, 10, "copper")
    for y in range(3, 9):                                       # fatia de queijo
        for x in range(4, 4 + (y - 2)):
            k.px(x, y, "gold")
    k.px(5, 7, "amber")
    k.line(9, 8, 12, 3, "rust"); k.hline(10, 13, 3, "slate")    # picareta
    return ol(k)


# ------------------------------------------------------------------ veículos (plano de perto)
def truck(fr: int) -> Canvas:
    """Caminhão-queijo dos ratinhos (58x32): cabine redonda com orelhinhas, ratinho no volante, caçamba com
    fatias de queijo, rodas grandes girando. Virado para a direita."""
    import moon_props as mp
    mc = _h()
    k = Canvas(58, 32)
    for y in range(12, 24):                                     # caçamba
        inset = max(0, y - 20)
        for x in range(2 + inset, 34):
            k.px(x, y, "steel" if y < 14 else "lilac_grey" if y < 22 else "slate")
    for x in range(4, 34, 6):
        k.vline(x, 14, 21, "mist")
    for cx, cy, r in ((9, 10, 5), (17, 8, 6), (26, 10, 5)):      # queijo empilhado
        mc.sphere(k, cx, cy, r, r * 0.8, CHEESE)
    k.px(17, 7, "amber"); k.px(9, 10, "amber")
    for y in range(8, 26):                                      # cabine (cabeça de ratinho, verde-água)
        for x in range(34, 56):
            rx = (x + 0.5 - 45) / 11.5
            ry = (y + 0.5 - 17) / 9.5
            if rx ** 4 + ry ** 4 <= 1:
                k.px(x, y, "ice" if x < 37 or y < 10 else "aqua" if x < 51 else "sea")
    for ex in (39, 49):                                         # orelhinhas no teto
        mc.disc(k, ex, 6.5, 3.4, "aqua"); mc.disc(k, ex, 6.5, 1.9, "pink")
    for y in range(11, 19):                                     # janela com o motorista
        for x in range(40, 52):
            if ((x + 0.5 - 46) / 6) ** 2 + ((y + 0.5 - 15) / 4.6) ** 2 <= 1:
                k.px(x, y, "pale_sky" if x + y < 58 else "sky")
    mc.disc(k, 46, 16.5, 2.8, "cream"); mc.disc(k, 43.5, 13.5, 1.4, "pink")
    k.hline(44, 48, 13, "gold"); k.px(47, 16, "ink"); k.px(49, 17, "pink")
    mc.disc(k, 56, 19, 1.5, "pink")                             # narizinho na frente
    k.px(53, 22, "lemon"); k.px(54, 22, "lemon")                # farol
    k.hline(34, 55, 24, "teal"); k.hline(36, 54, 25, "deep_teal")   # para-choque
    for wx in (12, 44):                                         # rodas
        mc.disc(k, wx, 26, 5, "charcoal")
        mc.disc(k, wx, 26, 2.2, "gold")
        a = fr * math.pi / 4
        k.px(int(round(wx + math.cos(a) * 3.6)), int(round(26 + math.sin(a) * 3.6)), "slate")
    return ol(k)


if __name__ == "__main__":
    sys.path.insert(0, "art/src/bg"); sys.path.insert(0, "art/src/terrain"); sys.path.insert(0, "art/src/sprites")
    import moon_cute as mc
    sheet = Canvas(330, 110)
    T = mc.T
    hill, _ = mine_hill(T["front"], T["front_ol"], T["front_tex"])
    sheet.stamp(hill, 0, 110 - hill.h)
    for k, x, y in ((tunnel(0), 200, 4), (pick_mouse(0), 236, 4), (pick_mouse(1), 260, 4), (drill(0), 200, 40),
                    (rails(40), 260, 40), (sign(0), 284, 30), (truck(0), 258, 72)):
        sheet.stamp(k, x, y)
    sheet.preview("art/previews/moon_mine_kit.png", scale=3, grid=False, bg="dark", show_1x=False)
    print("ok")
