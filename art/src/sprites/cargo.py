"""Cargas da Lua + ícones das habilidades (2026-10-05). Skill pixel-art, estilo fofo (patterns/cute-style.md).

Pedido do usuário: "o que não existir no nosso jogo, adicione de forma divertida e dada a temática do mapa (só a Lua)".
Lua de queijo, mina dos ratinhos → cargas do tema: caixa de queijo, bolo de queijo (frágil), sorvete (derrete),
queijão inteiro pendurado no cabo (rebocado) e ratinho perdido (resgate). Cada carga tem a versão "estragada"
(bolo amassado, sorvete derretido, queijo rachado) para a criança entender o que aconteceu sem ler.

Contrato com o jogo (godot-dev, scripts/world/cargo_art.gd): células 16x16 numa linha, nomes em cargo.json
("names", "cell"). O queijão tem raio 6 px (world.json cargo.towed.radius_m = 6) e é desenhado centrado (7.5, 7.5).
O ratinho fica de pé com os pés na linha y = 15 (o jogo põe o centro 8 px acima do chão).
Paleta Resurrect 64, luz de cima-esquerda, contorno ink (primeiro plano), cor chapada (2–3 tons por material).
Rodar da raiz: python3 art/src/sprites/cargo.py [--export]
"""
import json
import sys

sys.path.insert(0, ".claude/skills/pixel-art/scripts")
from pixelart import *

S = 16
NAMES = ["box", "cake", "cake_squashed", "icecream", "icecream_melted", "wheel", "wheel_cracked",
         "mouse_wait0", "mouse_wait1", "mouse_safe", "stabilizer", "turbo", "gift", "gas_can",
         "weight", "clock", "star"]


def face(cv: Canvas, x: int, y: int, sad: bool = False) -> None:
    """Rostinho fofo: olhos 1x2 afastados (2 px), brilho branco, bochecha rosa; triste = sobrancelha caída."""
    for ex in (x, x + 3):
        cv.px(ex, y, "ink"); cv.px(ex, y + 1, "ink")
    if not sad:
        cv.px(x - 1, y + 2, "pink"); cv.px(x + 4, y + 2, "pink")
        cv.px(x + 1, y + 2, "ink"); cv.px(x + 2, y + 2, "ink")        # sorriso
    else:
        cv.px(x - 1, y - 1, "ink"); cv.px(x + 4, y - 1, "ink")
        cv.px(x + 1, y + 3, "ink"); cv.px(x + 2, y + 3, "ink")        # boquinha triste


def box() -> Canvas:
    """Caixote de madeira com um pedaço de queijo aparecendo por cima."""
    cv = Canvas(S, S)
    cv.polygon([(4, 6), (11, 3), (11, 6)], "gold")                     # fatia de queijo
    cv.hline(5, 10, 5, "lemon"); cv.px(9, 4, "lemon")
    cv.px(8, 5, "amber")
    cv.rect(2, 6, 12, 9, "terracotta")
    cv.hline(2, 13, 6, "copper"); cv.hline(2, 13, 10, "copper")
    cv.vline(2, 6, 14, "copper")
    cv.hline(2, 13, 14, "rust"); cv.vline(13, 7, 14, "rust")
    cv.line(3, 13, 12, 7, "rust")                                     # travessa diagonal
    cv.outline("ink")
    return cv


def cake(squashed: bool = False) -> Canvas:
    """Bolo de queijo redondo com cobertura rosa escorrendo e cereja; amassado = achatado e espalhado."""
    cv = Canvas(S, S)
    if not squashed:
        cv.rect(2, 8, 12, 6, "cream")
        cv.hline(2, 13, 11, "pink")                                   # recheio
        cv.hline(2, 13, 13, "peach"); cv.vline(13, 8, 13, "peach")
        cv.ellipse(7.5, 7.5, 6, 2, "hot_pink")                        # cobertura
        for x, d in ((3, 2), (6, 1), (10, 2)):
            cv.vline(x, 9, 9 + d, "hot_pink")
        cv.hline(4, 8, 6, "pink")
        cv.ellipse(8, 3.5, 1.5, 1.5, "red"); cv.px(7, 3, "white")      # cereja
        cv.px(9, 1, "green"); cv.px(10, 1, "green")
        face(cv, 6, 10)
    else:
        cv.ellipse(7.5, 12.5, 7, 2.5, "cream")
        cv.hline(1, 14, 12, "pink")
        cv.ellipse(7.5, 11, 6, 1.5, "hot_pink")
        cv.px(1, 13, "hot_pink"); cv.px(14, 12, "hot_pink")
        cv.ellipse(12, 9, 1.5, 1.5, "red"); cv.px(11, 8, "white")      # cereja caiu de lado
        face(cv, 5, 12, sad=True)
    cv.outline("ink")
    return cv


def icecream(melted: bool = False) -> Canvas:
    """Casquinha com duas bolas (morango + creme) e rostinho; derretido = poça com a casquinha caída."""
    cv = Canvas(S, S)
    if not melted:
        cv.polygon([(4, 8), (11, 8), (8, 15), (7, 15)], "copper")     # casquinha
        cv.line(5, 9, 8, 13, "honey"); cv.line(10, 9, 7, 13, "terracotta")
        cv.ellipse(7.5, 6.5, 4, 2.5, "cream")                          # bola de baixo
        cv.ellipse(7.5, 3.5, 3, 2.5, "pink")                           # bola de cima
        cv.px(6, 2, "peach"); cv.px(5, 3, "peach")
        cv.vline(11, 7, 9, "cream")                                    # pingo
        face(cv, 6, 5)
    else:
        cv.ellipse(7.5, 13, 7, 2, "cream")
        cv.ellipse(6, 12.5, 3.5, 1.5, "pink")
        cv.polygon([(9, 8), (14, 11), (12, 13), (8, 10)], "copper")   # casquinha tombada
        cv.line(10, 9, 12, 11, "honey")
        face(cv, 3, 11, sad=True)
    cv.outline("ink")
    return cv


def wheel(cracked: bool = False) -> Canvas:
    """Queijão inteiro (raio 6, centro 7.5): casca âmbar fina, massa dourada e furinhos ESCUROS com borda clara
    (v1 parecia uma laranja: o brilho grande lemon e furos âmbar quase sem contraste). Furos assimétricos = a roda
    girando se vê."""
    cv = Canvas(S, S)
    cv.ellipse(7.5, 7.5, 6, 6, "amber")
    cv.ellipse(7.5, 7.5, 5, 5, "gold")
    for x, y in ((4, 4), (5, 3), (3, 5)):                              # brilho pequeno cima-esquerda
        cv.px(x, y, "lemon")
    for x, y, big in ((5, 7, True), (9, 4, False), (10, 9, True), (6, 11, False)):
        cv.px(x, y, "terracotta"); cv.px(x, y + 1, "rust")
        if big:
            cv.px(x + 1, y, "terracotta"); cv.px(x + 1, y + 1, "rust")
            cv.px(x, y - 1, "lemon")
    if cracked:
        cv.polygon([(7, 7), (14, 3), (14, 10)], "clear")               # falta um pedaço
        cv.line(7, 7, 3, 12, "ink"); cv.px(5, 8, "ink")
        cv.line(7, 7, 13, 4, "honey"); cv.line(7, 7, 13, 10, "honey")
    cv.outline("ink")
    return cv


def mouse(wave: int = 0, safe: bool = False) -> Canvas:
    """Ratinho de frente (pés em y=15) com capacete de minerador; acena (2 quadros). Salvo = dentro de uma
    bolha de vidro com coraçãozinho (foi resgatado)."""
    cv = Canvas(S, S)
    fur = "white"
    cv.ellipse(7.5, 12, 3, 2.5, fur)                                   # corpinho
    cv.px(6, 14, "cream"); cv.px(9, 14, "cream")
    cv.ellipse(3.5, 4, 2, 2, "cream"); cv.ellipse(11.5, 4, 2, 2, "cream")   # orelhonas
    cv.px(3, 4, "pink"); cv.px(4, 4, "pink"); cv.px(11, 4, "pink"); cv.px(12, 4, "pink")
    cv.ellipse(7.5, 7, 4, 3, fur)                                      # cabeça grande (chibi)
    cv.hline(5, 10, 4, "gold"); cv.hline(6, 9, 3, "gold"); cv.px(7, 3, "lemon")   # capacete
    for ex in (5, 10):                                                 # olhos 1x2 com brilho (sem boca: focinho)
        cv.px(ex, 6, "ink"); cv.px(ex, 7, "ink")
    cv.px(4, 8, "pink"); cv.px(11, 8, "pink")                          # bochechas
    cv.px(7, 8, "pink"); cv.px(8, 8, "pink")                           # focinho
    cv.px(13, 13, "pink"); cv.px(14, 12, "pink")                        # rabinho
    if not safe:
        arm_y = 8 if wave == 0 else 9                                  # bracinho acenando
        cv.line(10, 11, 13, arm_y, "cream"); cv.px(13, arm_y - 1, "cream")
    cv.outline("ink")
    if safe:
        b = Canvas(S, S)
        b.ellipse(7.5, 8, 7.5, 7.5, "pale_sky", fill=False)
        b.px(3, 4, "white"); b.px(4, 3, "white")
        b.stamp(cv, 0, 0)
        b.px(13, 1, "hot_pink"); b.px(15, 1, "hot_pink"); b.hline(13, 15, 2, "hot_pink"); b.px(14, 3, "hot_pink")
        return b
    return cv


def stabilizer() -> Canvas:
    """Habilidade Estabilizador: navezinha de pé com setas curvas dos dois lados (volta a ficar reta)."""
    cv = Canvas(S, S)
    cv.ellipse(7.5, 6, 2.5, 2.5, "pale_sky")                           # cúpula
    cv.px(6, 5, "white")
    cv.rect(4, 8, 8, 2, "mist"); cv.hline(4, 11, 9, "sea")             # disco
    cv.line(5, 10, 4, 12, "steel"); cv.line(10, 10, 11, 12, "steel")   # perninhas
    cv.outline("ink")
    for (x0, y0, x1, y1), tip in (((1, 9, 1, 4), (0, 5)), ((14, 9, 14, 4), (15, 5))):
        cv.line(x0, y0, x1, y1, "lime")
        cv.px(tip[0], tip[1], "lime"); cv.px(x0 + (1 if x0 < 8 else -1), 3, "lime")
    cv.hline(3, 12, 14, "lime")                                        # chão nivelado
    return cv


def turbo() -> Canvas:
    """Habilidade Turbo: raio dourado com chama ciano dupla (motor com o dobro da força)."""
    cv = Canvas(S, S)
    cv.polygon([(9, 0), (4, 8), (8, 8), (6, 15), (12, 6), (8, 6), (11, 0)], "gold")
    cv.line(9, 1, 6, 7, "lemon")
    cv.outline("ink")
    for x in (2, 13):
        cv.vline(x, 10, 13, "aqua"); cv.px(x, 14, "ice"); cv.px(x, 9, "ice")
    return cv


def gift() -> Canvas:
    """Presente do alto do morro (v10, 2026-10-06): caixinha pink com fita e laço dourados e rostinho.
    Pés (fundo da caixa) na linha y = 15, como o ratinho: o jogo assenta no chão."""
    cv = Canvas(S, S)
    cv.rect(3, 8, 10, 7, "hot_pink")                                   # caixa
    cv.rect(2, 6, 12, 3, "pink")                                       # tampa (mais larga)
    cv.hline(2, 13, 8, "rose")                                         # sombra sob a tampa
    cv.vline(12, 9, 14, "raspberry"); cv.hline(3, 12, 14, "raspberry")  # lado da sombra (luz de cima-esquerda)
    cv.vline(7, 6, 8, "gold"); cv.vline(8, 6, 8, "amber")              # fita só na tampa: o rosto fica livre
    cv.hline(3, 12, 13, "gold"); cv.px(12, 13, "amber")                # faixa embaixo
    cv.px(7, 6, "lemon")
    cv.paint(["aa..aa",                                                # laço: duas voltas + nó
              "aab.aa",
              ".abba.",
              "..cc.."], {"a": "gold", "b": "lemon", "c": "amber"}, x=5, y=2)
    cv.outline("ink")
    face(cv, 6, 9)
    return cv


def gas_can() -> Canvas:
    """Galão de gás do alto do morro (v10): vermelho, alça vazada em cima, bico de metal e rostinho.
    Pés na linha y = 15."""
    cv = Canvas(S, S)
    cv.rect(3, 6, 9, 9, "red")                                         # corpo
    cv.vline(3, 6, 14, "salmon"); cv.hline(3, 11, 6, "salmon")         # luz (cima-esquerda)
    cv.vline(11, 7, 14, "crimson"); cv.hline(4, 11, 14, "crimson")     # sombra
    cv.rect(4, 3, 5, 3, "red"); cv.rect(5, 4, 3, 1, "clear")           # alça com furo
    cv.hline(4, 8, 3, "salmon")
    cv.line(11, 5, 13, 3, "steel"); cv.px(12, 5, "lilac_grey")         # bico
    cv.px(13, 2, "mist")
    cv.outline("ink")
    face(cv, 5, 9)
    return cv


# --- ícones das missões (v12, 2026-10-06): Pesada = peso de academia fofo; Rápida = relógio; estrela de missão ---
def weight() -> Canvas:
    """Peso (kettlebell) gordinho de ferro com alça e rostinho: a carga da missão Pesada."""
    cv = Canvas(S, S)
    cv.ellipse(7.5, 10, 6, 5, "slate")                                 # corpo
    cv.ellipse(6.5, 9, 4, 3, "lilac_grey")                             # luz (cima-esquerda)
    cv.px(4, 7, "steel"); cv.px(5, 6, "steel")                          # brilho
    cv.rect(5, 2, 6, 2, "slate"); cv.rect(4, 3, 2, 3, "slate"); cv.rect(10, 3, 2, 3, "slate")   # alça
    cv.outline("ink")
    for x in (6, 7, 8, 9):                                             # buraco da alça (vazado)
        cv.px(x, 4, None); cv.px(x, 5, None)
    face(cv, 6, 10)
    return cv


def clock() -> Canvas:
    """Relógio redondo de cozinha com sininhos: o prazo da missão Rápida."""
    cv = Canvas(S, S)
    cv.ellipse(3.5, 2.5, 2, 1.5, "gold"); cv.ellipse(11.5, 2.5, 2, 1.5, "gold")   # sininhos
    cv.ellipse(7.5, 9, 6, 6, "red")                                    # caixa
    cv.ellipse(7.5, 9, 4.5, 4.5, "white")                              # mostrador
    cv.px(5, 6, "mist"); cv.px(6, 6, "mist")
    cv.vline(7, 6, 9, "ink"); cv.hline(8, 9, 9, "ink")                # ponteiros
    cv.px(7, 14, "maroon"); cv.px(8, 14, "maroon")
    cv.outline("ink")
    return cv


def star_icon() -> Canvas:
    """Estrelinha dourada de missão (a moeda da árvore de PEDIDOS)."""
    cv = Canvas(S, S)
    cv.paint(["......aa......",
              ".....abba.....",
              ".....abba.....",
              "aaaaabbbbaaaaa",
              ".abbbbbbbbbba.",
              "..abbbbbbbba..",
              "...abbccbba...",
              "...abbccbba...",
              "..abbbaabbba..",
              "..abba..abba..",
              ".aba......aba.",
              ".aa........aa."], {"a": "amber", "b": "gold", "c": "lemon"}, x=1, y=2)
    cv.px(6, 5, "white"); cv.px(5, 6, "lemon")
    cv.outline("ink")
    return cv


def build() -> list:
    return [box(), cake(), cake(True), icecream(), icecream(True), wheel(), wheel(True),
            mouse(0), mouse(1), mouse(safe=True), stabilizer(), turbo(), gift(), gas_can(), weight(), clock(),
            star_icon()]


if __name__ == "__main__":
    cells = build()
    sheet = Canvas(S * len(cells), S)
    for i, c in enumerate(cells):
        sheet.stamp(c, i * S, 0)
    sheet.save("art/previews/cargo.png")
    # prévia sobre o chão de queijo e o céu da Lua (onde aparecem)
    bg = Canvas(S * len(cells) + 8, S + 12)
    bg.rect(0, 0, bg.w, bg.h, "rose")
    bg.rect(0, S + 3, bg.w, 9, "gold")
    bg.stamp(sheet, 4, 4)
    bg.save("art/previews/cargo_on_moon.png")
    if "--export" in sys.argv:
        sheet.save("assets/sprites/cargo.png", preview=False)
        with open("assets/sprites/cargo.json", "w") as f:
            json.dump({"cell": S, "names": NAMES,
                       "notes": "Gerado por art/src/sprites/cargo.py (pixel-art). Células 16x16 numa linha."}, f, indent=2)
        print("exportado assets/sprites/cargo.png")
    print("ok")
