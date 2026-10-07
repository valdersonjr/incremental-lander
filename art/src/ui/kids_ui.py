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
sys.path.insert(0, "art/src/ui")
import rep_badge

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


# ------------------------------------------------------------------ ratinhos das missões (v12, 2026-10-06)
# Um ratinho por tipo de missão (usuário: "características e cores distintas uns dos outros para ficar visual cada
# missão"). Padrão (patterns/mission-mice.md): rosto chibi igual ao rat() + UM elemento-assinatura que muda a silhueta
# (chapéu) + 2–3 cores dominantes por ratinho + forma que diz a regra (Pesada = largo/quadrado; Suave = chapéu alto
# e redondo; Rápida = boné inclinado para a frente com risquinhos de velocidade).

def mouse_face(fur: list, inner: str = "pink", ear_y: float = 8.0, head_y: float = 14.0, wide: float = 7.0,
               brows: bool = False, ears: tuple = (6, 17)) -> Canvas:
    """Rosto base de frente: orelhonas, cabeça com volume (fur = [brilho, luz, base, sombra]), olhos 2x2 com
    brilho, bochecha, focinho e bigode. Sem contorno (o acessório entra antes do outline)."""
    k = Canvas(CELL, CELL)
    for ex in ears:
        mc.disc(k, ex, ear_y, 4.0, fur[1]); mc.disc(k, ex, ear_y + 0.4, 2.2, inner)
    mc.sphere(k, 11.5, head_y, wide, 6.0, fur)
    ey = int(head_y) - 1
    for x in (8, 14):
        k.rect(x, ey, 2, 2, "ink"); k.px(x, ey, "white")
        if brows:                                               # sobrancelha grossa (cara de forte, mas sorrindo)
            k.hline(x - 1, x + 1, ey - 2, "ink")
    k.px(11, ey + 3, "pink"); k.px(12, ey + 3, "pink")          # focinho
    k.px(6, ey + 3, "pink"); k.px(17, ey + 3, "pink")           # bochechas
    k.line(2, ey + 2, 5, ey + 3, "lilac_grey"); k.line(18, ey + 3, 21, ey + 2, "lilac_grey")
    return k


def mouse_simple() -> Canvas:
    """Simples — mineiro: ratinho branco com capacete amarelo e lanterna (o da mina da Lua)."""
    k = mouse_face(FUR)
    k.rect(6, 6, 12, 3, "gold"); k.rect(7, 4, 10, 2, "gold"); k.hline(8, 15, 3, "lemon")
    k.hline(5, 18, 8, "amber")                                  # aba
    k.rect(10, 4, 4, 3, "white"); k.rect(11, 5, 2, 1, "lemon")  # lanterna
    k.outline("ink")
    return k


def mouse_heavy() -> Canvas:
    """Pesada — ratão forte: pelo caramelo, cabeça larga, faixa vermelha na testa (v1 com sobrancelha grossa
    parecia bravo: tirada)."""
    k = mouse_face(["honey", "copper", "terracotta", "rust"], inner="salmon", wide=8.4, ears=(5, 18), ear_y=7.5)
    k.rect(4, 9, 16, 2, "red"); k.hline(5, 18, 9, "coral")      # faixa
    k.rect(19, 10, 2, 3, "red"); k.px(20, 13, "crimson")        # pontas da faixa caindo do lado
    k.outline("ink")
    return k


def mouse_soft() -> Canvas:
    """Pouso suave — confeiteira: pelo rosado, chapéu de chef alto e fofo (cogumelo de nuvem)."""
    k = mouse_face(["cream", "peach", "salmon", "rose"], inner="hot_pink", head_y=15.0, ear_y=9.5)
    mc.sphere(k, 11.5, 4.5, 6.0, 4.0, ["white", "white", "mist", "steel"])   # copa do chapéu
    k.rect(7, 7, 10, 3, "white"); k.hline(7, 16, 9, "mist")     # faixa do chapéu
    k.px(15, 8, "hot_pink")                                     # coraçãozinho bordado
    k.outline("ink")
    return k


def mouse_fast() -> Canvas:
    """Rápida — sorveteiro: pelo cinza-azulado, boné listrado azul e branco virado para a frente + risquinhos."""
    k = mouse_face(["white", "mist", "steel", "lilac_grey"], inner="pink")
    for x in range(6, 18):                                      # copa listrada
        for y in range(5, 9):
            k.px(x, y, "sky" if (x // 2) % 2 == 0 else "white")
    k.hline(8, 15, 4, "sky")
    k.hline(14, 21, 9, "blue"); k.hline(16, 22, 8, "blue")     # aba para a frente (assimetria = velocidade)
    for y in (12, 15):                                          # risquinhos de velocidade atrás
        k.hline(0, 2, y, "pale_sky")
    k.outline("ink")
    return k


def mouse_passenger() -> Canvas:
    """Passageiro — taxista: pelo cinza, quepe amarelo com faixa quadriculada (táxi) e bandeirinha."""
    k = mouse_face(["mist", "steel", "lilac_grey", "slate"], inner="pink")
    k.rect(6, 4, 12, 3, "gold"); k.hline(7, 16, 3, "lemon")
    for x in range(6, 18):                                      # faixa quadriculada
        k.px(x, 7, "ink" if x % 2 == 0 else "white")
        k.px(x, 8, "white" if x % 2 == 0 else "ink")
    k.hline(5, 18, 9, "amber")                                  # aba
    k.vline(20, 1, 9, "rosewood")                               # haste da bandeirinha
    k.rect(21, 1, 3, 3, "red"); k.px(21, 4, "red")
    k.outline("ink")
    return k


def mouse_tow() -> Canvas:
    """Cabo — ratinha lilás: pelo lavanda, laço grande numa orelha e uma cordinha com gancho pendurada (v1: corda
    enrolada parecia moeda)."""
    k = mouse_face(["white", "lavender", "violet", "purple"], inner="hot_pink")
    k.rect(14, 2, 3, 3, "hot_pink"); k.rect(19, 2, 3, 3, "hot_pink")   # laço (asas)
    k.rect(17, 3, 2, 2, "raspberry"); k.px(15, 2, "pink"); k.px(20, 2, "pink")
    k.vline(20, 5, 16, "copper")                                # cordinha descendo do laço
    k.px(20, 8, "rust"); k.px(20, 12, "rust")                   # gomos da corda
    k.rect(19, 17, 3, 1, "steel"); k.px(19, 18, "steel"); k.px(19, 19, "steel"); k.px(20, 20, "steel")
    k.px(21, 19, "steel")                                       # gancho
    k.outline("ink")
    return k


def mouse_double() -> Canvas:
    """Dupla — campeão: pelo chocolate, coroinha dourada com pedra verde (duas regras = desafio de campeão)."""
    k = mouse_face(["copper", "rust", "wine", "maroon"], inner="salmon")
    k.rect(7, 5, 10, 3, "gold"); k.hline(7, 16, 7, "amber")
    for x in (7, 11, 16):                                       # pontas da coroa
        k.rect(x, 3, 1, 2, "gold"); k.px(x, 2, "lemon")
    k.px(11, 6, "emerald"); k.px(12, 6, "emerald")              # pedra
    k.outline("ink")
    return k



# ------------------------------------------------------------------ cartão do pedido (2026-10-06)
# Usuário escolheu a maquete D (art/previews/offer_card/): as 3 plataformas são os botões de partir; o mineiro mostra
# perto/médio/longe; a telinha "Novo amiguinho!" mostra certo × errado.
def pad_tier(half: int) -> Canvas:
    """Plataforma de pouso em miniatura (meia largura half): mesma receita de pad(); normal 10, estreita 7, apertada 4."""
    k = _canvas()
    k.rect(12 - half, 13, half * 2, 3, "mist"); k.hline(12 - half, 11 + half, 13, "white")
    k.hline(12 - half, 11 + half, 15, "steel")
    for x in (12 - half + 1, 11 + half - 1):
        k.vline(x, 16, 18, "lilac_grey")
    k.px(12 - half, 12, "aqua"); k.px(11 + half, 12, "aqua")
    k.outline("ink")
    return k


def distance(n: int) -> Canvas:
    """Perto/médio/longe: da plataforminha (esquerda) sai um caminho pontilhado até a bandeirinha; quanto mais longe,
    mais à direita fica a bandeira (n = 1, 2, 3)."""
    k = _canvas()
    fx = 6 + n * 5                                             # mastro: 11 / 16 / 21
    k.hline(1, 4, 17, "mist"); k.px(1, 16, "aqua"); k.px(4, 16, "aqua")
    for x in range(7, fx - 1, 3):                              # caminho pontilhado em arco baixinho
        k.px(x, 13 if 7 < x < fx - 3 else 14, "cream")
    k.vline(fx, 6, 18, "steel"); k.px(fx, 5, "gold")
    k.paint(["rrr", "rrrr", "rr"], {"r": "hot_pink"}, x=fx - 3 if fx > 19 else fx + 1, y=6)
    k.hline(fx - 1, fx + 1, 19, "lilac_grey")
    k.outline("ink")
    return k


def check() -> Canvas:
    """Certo: visto verde grosso (traço de 3 px)."""
    k = _canvas()
    for i in range(5):                                         # perninha curta
        k.rect(4 + i, 11 + i, 3, 3, "emerald")
    for i in range(10):                                        # perna longa
        k.rect(8 + i, 15 - i, 3, 3, "emerald")
    for i in range(10):
        k.px(9 + i, 15 - i, "leaf")
    k.outline("ink")
    return k


def cross() -> Canvas:
    """Errado: xis vermelho grosso (traço de 3 px)."""
    k = _canvas()
    for i in range(12):
        k.rect(5 + i, 5 + i, 3, 3, "red"); k.rect(16 - i, 5 + i, 3, 3, "red")
    for i in range(12):
        k.px(6 + i, 5 + i, "salmon") if i < 5 else None
        k.px(17 - i, 5 + i, "salmon") if i < 5 else None
    k.outline("ink")
    return k


def clock() -> Canvas:
    """Tempo de jogo: despertador fofo (sininhos no topo, mostrador branco com rim azul, ponteiros ink)."""
    k = _canvas()
    for bx in (6, 18):                                         # sininhos
        mc.sphere(k, bx, 6, 3.2, 3.2, ["lemon", "gold", "gold", "amber"])
    k.px(8, 20, "blue"); k.px(16, 20, "blue")                  # pezinhos
    mc.disc(k, 12, 13, 8.6, "sky")
    mc.sphere(k, 12, 13, 6.6, 6.6, ["white", "white", "mist", "mist"])
    k.vline(12, 8, 13, "ink")                                  # ponteiro grande (12h)
    k.hline(12, 15, 13, "ink")                                 # ponteiro pequeno (3h)
    k.px(12, 13, "raspberry")
    k.outline("ink")
    return k


def heart(on: bool) -> Canvas:
    """Coração da Reputação por ratinho (2026-10-07, padrão Stardew): 15x13, cheio rosa com brilho; vazio cinza."""
    k = _canvas()
    rows = ["..###...###..", ".#####.#####.", "#############", "#############", "#############", ".###########.",
            "..#########..", "...#######...", "....#####....", ".....###.....", "......#......"]
    base, light, dark = ("hot_pink", "salmon", "raspberry") if on else ("steel", "mist", "slate")
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch == "#":
                k.px(5 + x, 6 + y, dark if (x + y > 13 and on) or (x > 9 and y > 2) else base)
    k.px(7, 7, light); k.px(8, 7, light); k.px(7, 8, light); k.px(6, 8, "white" if on else light)
    k.outline("ink")
    return k


def trophy() -> Canvas:
    """Troféu do recorde pessoal (2026-10-07, "bata seu recorde"): taça dourada com alças em argola, haste e base."""
    k = _canvas()
    ox, oy = 4, 3
    for y in range(9):                                         # taça: larga em cima, afunila
        hw = 5 if y <= 4 else 9 - y
        for x in range(8 - hw, 8 + hw):
            k.px(ox + x, oy + y, "amber" if x >= 10 or y >= 6 else "gold")
    for x, y in ((2, 1), (1, 1), (0, 2), (0, 3), (0, 4), (1, 5), (2, 6)):   # alças (argola vazada)
        k.px(ox + x, oy + y, "amber"); k.px(ox + 15 - x, oy + y, "amber")
    k.rect(ox + 7, oy + 9, 2, 3, "amber")                      # haste
    k.rect(ox + 4, oy + 12, 8, 2, "gold"); k.rect(ox + 3, oy + 14, 10, 1, "amber")   # base
    k.hline(ox + 4, ox + 11, oy + 12, "lemon")
    for y in range(1, 5):                                      # brilho
        k.px(ox + 5, oy + y, "lemon")
    k.px(ox + 6, oy + 1, "white"); k.hline(ox + 3, ox + 12, oy, "lemon")
    k.outline("ink")
    return k


# perfil do chao (altura em px a partir da base, x = 0..17) de cada paisagem do relevo (2026-10-07, Estrada)
LAND_PROFILES = {
    "planicie": [6, 6, 6, 6, 7, 7, 7, 6, 6, 6, 6, 6, 7, 7, 7, 6, 6, 6],
    "colinas": [5, 5, 6, 7, 8, 9, 10, 11, 11, 11, 10, 9, 8, 7, 6, 5, 5, 5],
    "serra": [4, 6, 9, 12, 9, 6, 7, 10, 14, 10, 7, 5, 8, 11, 8, 5, 4, 4],
    "vale": [11, 11, 11, 11, 10, 8, 5, 3, 3, 3, 3, 5, 8, 10, 11, 11, 11, 11],
    "planalto": [4, 4, 4, 4, 4, 5, 6, 12, 12, 12, 12, 12, 12, 6, 5, 4, 4, 4],
    "crateras": [8, 8, 8, 7, 4, 3, 4, 7, 8, 8, 7, 4, 3, 4, 7, 8, 8, 8],
    "degraus": [3, 3, 3, 3, 6, 6, 6, 6, 9, 9, 9, 9, 12, 12, 12, 12, 12, 12],
}


def landscape(kind: str) -> Canvas:
    """Paisagem do relevo (parada da Estrada): janelinha redonda com céu rosado e o chão de queijo no formato dela."""
    k = _canvas()
    mc.sphere(k, 12, 12, 10.6, 10.6, ["peach", "salmon", "salmon", "raspberry"])
    prof = LAND_PROFILES[kind]
    for i, h in enumerate(prof):
        x = 3 + i
        top = 20 - h
        for y in range(top, 23):
            k.px(x, y, "lemon" if y == top else ("gold" if y < top + 3 else "amber"))
    # recorta o chao no circulo da janelinha
    for y in range(CELL):
        for x in range(CELL):
            if (x + 0.5 - 12) ** 2 + (y + 0.5 - 12) ** 2 > 10.6 ** 2:
                k.px(x, y, "clear")
    k.outline("ink")
    return k


MISSION_MICE = {"rat_simple": mouse_simple, "rat_heavy": mouse_heavy, "rat_soft": mouse_soft, "rat_fast": mouse_fast,
                "rat_passenger": mouse_passenger, "rat_tow": mouse_tow, "rat_double": mouse_double}


NAMES = ["pin", "pin_sel", "pin_off", "rat", "bunny", "alien", "bear", "star_on", "star_off", "coins", "ship",
         "flame_s", "flame_b", "bar_s", "bar_b", "drop_b", "drop_s", "coin", "pad_s", "pad_b", "rock", "drone",
         "drones", "drone_coin", "arrow", "lock", "mystery"] + list(MISSION_MICE) \
    + ["pad_normal", "pad_narrow", "pad_tight", "dist_1", "dist_2", "dist_3", "check", "cross", "clock"] \
    + ["rep_on", "rep_off", "heart_on", "heart_off", "trophy"] + ["land_" + n for n in LAND_PROFILES]


def build() -> Canvas:
    parts = [badge(["white", "white", "cream", "peach"]), badge(["white", "lemon", "lemon", "gold"], rim="hot_pink"),
             badge(["mist", "steel", "steel", "lilac_grey"]), rat(), bunny(), alien(), bear(), star(True), star(False),
             coins(), ship(), flame(False), flame(True), gas_bar(False), gas_bar(True), drop(True), drop(False),
             coin_one(), pad(False), pad(True), rock(), drone(), drone(2), drone(1, True), arrow(), lock(), mystery()] \
        + [make() for make in MISSION_MICE.values()] \
        + [pad_tier(10), pad_tier(7), pad_tier(4), distance(1), distance(2), distance(3), check(), cross(), clock()] \
        + [rep_badge.shield(True), rep_badge.shield(False)] \
        + [heart(True), heart(False)] \
        + [trophy()] \
        + [landscape(n) for n in LAND_PROFILES]                     # paisagens do relevo na Estrada (2026-10-07)
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
