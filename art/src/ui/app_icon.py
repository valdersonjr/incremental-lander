"""Ícone do jogo (janela, dock/barra de tarefas, executável). Padrão: patterns/app-icon.md. Skill pixel-art.
32x32 "boxed": retângulo arredondado com céu espacial em faixas pontilhadas (linguagem da cena da Lua aprovada),
estrelas e o lander futurista (lander_styles.b_body) com o plasma ciano ligado — a nave é o
herói e a silhueta do jogo. Margem transparente de 1 px (o sistema põe a sombra).
Exporta assets/ui/icon.png (32) e assets/ui/icon_512.png (ampliado x16 por vizinho mais próximo, sem suavizar).
Rodar da raiz: python3 art/src/ui/app_icon.py [--export]"""
import sys; sys.path.insert(0, ".claude/skills/pixel-art/scripts"); sys.path.insert(0, "art/src/sprites")
from pixelart import *
from lander_styles import b_body, b_flame

R = 5  # raio do canto (px)


def rounded(x: int, y: int) -> bool:
    """Ponto dentro do retângulo arredondado 30x30 (margem de 1 px)."""
    if not (1 <= x <= 30 and 1 <= y <= 30):
        return False
    cx = min(max(x, 1 + R), 30 - R)
    cy = min(max(y, 1 + R), 30 - R)
    return (x - cx) ** 2 + (y - cy) ** 2 <= R * R + 1


def build() -> Canvas:
    cv = Canvas(32, 32)
    inside = {(x, y) for x in range(32) for y in range(32) if rounded(x, y)}
    # céu em faixas (de cima: ink -> shadow -> navy -> indigo), transições pontilhadas como na cena da Lua
    bands = [("ink", 0, 9), ("shadow", 9, 17), ("navy", 17, 25), ("indigo", 25, 32)]
    for col, y0, y1 in bands:
        cv.pxs([(x, y) for (x, y) in inside if y0 <= y < y1], col)
    for (a, b, y) in (("ink", "shadow", 8), ("shadow", "navy", 16), ("navy", "indigo", 24)):
        cv.dither([(x, yy) for (x, yy) in inside if yy in (y, y + 1)], a, b, 0.5, pattern="checker")
    # estrelas esparsas (fora do planeta e da nave)
    for (x, y, c) in ((4, 4, "white"), (6, 9, "mist"), (3, 15, "mist"), (27, 4, "mist"), (28, 12, "white")):
        cv.px(x, y, c)
    # halo claro atrás das pernas e da chama (as pernas lilás sumiam no azul escuro)
    halo = {(x, y) for (x, y) in inside if ((x - 16) / 13.0) ** 2 + ((y - 22) / 7.0) ** 2 <= 1.0}
    cv.pxs(halo, "indigo")
    # nave com o propulsor ligado, centrada; o contrato do sprite (pés em y=24) sobe 2 px para caber a chama
    ship = b_flame(1)
    ship.stamp(b_body())
    for (x, y) in ship.opaque():
        yy = y - 2
        if (x, yy) in inside:
            cv.px(x, yy, ship.get(x, y))
    # borda do retângulo: contorno ink (lê sobre fundos claros de dock/explorer)
    edge = {(x, y) for (x, y) in inside if any((nx, ny) not in inside for nx, ny in
                                                ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))}
    cv.pxs(edge, "ink")
    return cv


if __name__ == "__main__":
    cv = build()
    print("cores:", len(cv.colors_used()), cv.colors_used())
    print("lint:", cv.lint(max_colors=18))
    out = "assets/ui/" if "--export" in sys.argv else "art/previews/"
    # caminhos literais (o pre-commit liga cada asset ao script-fonte): assets/ui/icon.png assets/ui/icon_512.png
    cv.save(out + "icon.png", preview_dir="art/previews") if "--export" in sys.argv else cv.save(out + "icon.png")
    big = Canvas(512, 512)
    for x in range(32):
        for y in range(32):
            c = cv.get(x, y)
            if c is not None:
                big.rect(x * 16, y * 16, 16, 16, c)
    big.save(out + "icon_512.png", preview=False)
