"""Ícones das AJUDAS de voo na Estrada das Estrelas (ROADMAP 16.5). Skill pixel-art, estilo fofo (cute-style).
Antes as paradas reaproveitavam figuras genéricas (bolinhas de distância, plataforma, xis); cada ajuda ganha a figura
do que ela MOSTRA no voo (GDD §6b), legível para uma criança de 6 anos sem ler. Células 24x24 do atlas kids.png
(entram no fim de kids_ui.build/NAMES). A nave aparece como mini lander com o gatinho (não o ícone "navezinha",
reprovado pelo usuário).
  assist_color   Setinha colorida: seta em 3 cores (azul longe, amarelo, verde chegando)
  assist_trail   Rastro: mini lander + pontinhos do arco só à frente
  assist_route   Rota completa: arco pontilhado inteiro de uma plataforma à outra
  assist_shadow  Sombra: mini lander no alto, tracejado e a sombra no chão
  assist_level   Nivelador: mini lander perto do chão com a linha de nível verde (pontas amarela/vermelha)
  assist_predict Onde vou cair: queda pontilhada terminando num X verde no chão
  assist_gas     Dá pra chegar?: barrinha de gás com a marquinha do que sobra e uma bandeirinha
Rodar da raiz: python3 art/src/ui/assist_icons.py  -> art/previews/assist_icons_sheet.png"""
import sys
sys.path.insert(0, ".claude/skills/pixel-art/scripts")
from pixelart import *

CELL = 24


def _canvas() -> Canvas:
    return Canvas(CELL, CELL)


def mini_lander(k: Canvas, x: int, y: int) -> None:
    """Lander de 11x9 com o gatinho na cúpula (x, y = canto de cima). Sem contorno (o ícone contorna tudo junto)."""
    k.paint(["...bbbbb...",
             "..bcoooob..",
             ".bbooEoEbb.",
             ".bbboooobb.",
             "wwwwwwwwwww",
             "mssssssssmm",
             ".ll.....ll.",
             "l.........l"],
            {"b": "pale_sky", "c": "white", "o": "amber", "E": "ink", "w": "white", "m": "mist", "s": "sea",
             "l": "steel"}, x=x, y=y)


def ground(k: Canvas, y: int, x0: int = 1, x1: int = 22) -> None:
    k.hline(x0, x1, y, "honey"); k.rect(x0, y + 1, x1 - x0 + 1, CELL - y - 2, "amber")


def assist_color() -> Canvas:
    k = _canvas()
    k.rect(2, 10, 5, 4, "sky"); k.rect(7, 10, 5, 4, "lemon")
    for i in range(7):
        k.vline(12 + i, 5 + i, 18 - i, "green" if i < 5 else "lime")
    k.hline(2, 6, 10, "pale_sky"); k.hline(7, 11, 10, "white")
    k.outline("ink")
    return k


def assist_trail() -> Canvas:
    k = _canvas()
    mini_lander(k, 1, 12)
    for x, y in ((14, 11), (17, 8), (20, 6)):
        k.rect(x, y, 2, 2, "white")
    k.outline("ink")
    return k


def assist_route() -> Canvas:
    k = _canvas()
    for x0 in (1, 17):                                           # duas plataformas
        k.rect(x0, 18, 6, 2, "mist"); k.hline(x0, x0 + 5, 18, "white")
        k.vline(x0 + 1, 20, 21, "lilac_grey"); k.vline(x0 + 4, 20, 21, "lilac_grey")
    pts = [(3, 15), (5, 10), (8, 7), (12, 6), (16, 7), (19, 10), (20, 15)]
    for x, y in pts:
        k.rect(x, y, 2, 2, "white")
    k.outline("ink")
    return k


def assist_shadow() -> Canvas:
    k = _canvas()
    mini_lander(k, 6, 1)
    for y in (11, 14, 17):                                       # tracejado até o chão
        k.vline(11, y, y + 1, "white")
    ground(k, 21)
    k.hline(7, 15, 20, "plum"); k.hline(8, 14, 21, "plum")      # sombra (oval escuro no chão)
    k.outline("ink")
    return k


def assist_level() -> Canvas:
    k = _canvas()
    mini_lander(k, 6, 5)
    k.rect(2, 16, 4, 2, "red"); k.rect(6, 16, 4, 2, "lemon"); k.rect(10, 16, 4, 2, "green")
    k.rect(14, 16, 4, 2, "lemon"); k.rect(18, 16, 4, 2, "red")
    ground(k, 20)
    k.outline("ink")
    return k


def assist_predict() -> Canvas:
    k = _canvas()
    for x, y in ((2, 2), (6, 3), (10, 5), (13, 8), (15, 11)):    # queda (parábola) pontilhada
        k.rect(x, y, 2, 2, "white")
    ground(k, 20)
    for i in range(6):                                           # X verde onde vai cair
        k.px(14 + i, 13 + i, "green"); k.px(15 + i, 13 + i, "green")
        k.px(19 - i, 13 + i, "green"); k.px(20 - i, 13 + i, "green")
    k.outline("ink")
    return k


def assist_gas() -> Canvas:
    k = _canvas()
    k.rect(2, 12, 20, 7, "slate")
    k.rect(3, 13, 14, 5, "aqua"); k.hline(3, 16, 13, "ice"); k.hline(3, 16, 17, "sea")
    k.vline(12, 9, 19, "white")                                  # marquinha: o que sobra ao chegar
    k.vline(13, 3, 10, "mist"); k.rect(14, 3, 6, 4, "green"); k.hline(14, 19, 3, "lime")   # bandeirinha: chega!
    k.outline("ink")
    return k


ICONS = {"assist_color": assist_color, "assist_trail": assist_trail, "assist_route": assist_route,
         "assist_shadow": assist_shadow, "assist_level": assist_level, "assist_predict": assist_predict,
         "assist_gas": assist_gas}
# parada da Estrada -> ícone novo
STOP_ICON = {"nav_color": "assist_color", "nav_trail": "assist_trail", "nav_route": "assist_route",
             "land_shadow": "assist_shadow", "land_level": "assist_level", "land_predict": "assist_predict",
             "gas_need": "assist_gas"}


if __name__ == "__main__":
    from PIL import Image, ImageDraw
    S = 6
    img = Image.new("RGB", (len(ICONS) * (CELL * S + 16) + 16, CELL * S + 40), (62, 53, 70))
    d = ImageDraw.Draw(img)
    for i, (name, fn) in enumerate(ICONS.items()):
        cv = fn()
        print(name, "cores", len(cv.colors_used()), cv.lint(max_colors=10))
        x = 16 + i * (CELL * S + 16)
        spr = cv.to_image().resize((CELL * S, CELL * S), Image.NEAREST)
        img.paste(spr, (x, 30), spr)
        d.text((x, 8), name, fill=(240, 236, 230))
    img.save("art/previews/assist_icons_sheet.png")
    print("art/previews/assist_icons_sheet.png")
