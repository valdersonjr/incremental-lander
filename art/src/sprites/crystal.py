"""Cristal flutuante (coletável no arco do salto) + estouro ao coletar (padrão: patterns/crystal-pickup.md).

Contrato com o jogo (godot-dev): 16x16, centro em (8, 8) -> sprite centrado na posição do cristal.
Animações: "spin" (8 quadros, laço: a aresta entre a faceta clara e a escura passa de um lado ao outro, como um
prisma girando; faísca curta num quadro) e "pop" (4 quadros, sem laço: faíscas abrindo, sem contorno = efeito).
Paleta Resurrect 64, rampa purple (plum -> purple -> violet -> lavender) — contrasta com o turquesa do alvo e
com os quatro mundos. Luz de cima-esquerda; selout + contorno ink (style-guide: pickups).
Rodar da raiz: python3 art/src/sprites/crystal.py [--export]
"""
import sys

sys.path.insert(0, ".claude/skills/pixel-art/scripts")
from pixelart import *

S = 16
CX = 7.5                      # eixo vertical do cristal (16 px: centro entre as colunas 7 e 8)
TOP, MID0, MID1, BOT = 1, 5, 9, 14   # ponta de cima, faixa larga (cinturão) e ponta de baixo
HALF = 3.5                    # meia-largura no cinturão


def half_width(y: int) -> float:
    """Silhueta de bipirâmide hexagonal alongada (ponta curta em cima, longa embaixo)."""
    if y < TOP or y > BOT:
        return -1
    if y < MID0:
        return HALF * (y - TOP + 0.6) / (MID0 - TOP + 0.6)
    if y <= MID1:
        return HALF
    return HALF * (BOT - y + 0.4) / (BOT - MID1 + 0.4)


def crystal(phase: float, glint: int = 0) -> Canvas:
    """phase 0..1: posição da aresta central (0 = encostada à esquerda, 1 = à direita).
    Faceta à esquerda da aresta = luz (lavender/violet); à direita = sombra (purple/plum)."""
    cv = Canvas(S, S)
    for y in range(S):
        h = half_width(y)
        if h < 0:
            continue
        x0, x1 = int(round(CX - h)), int(round(CX + h))
        if x1 < x0:
            continue
        ridge = x0 + (x1 - x0) * phase
        for x in range(x0, x1 + 1):
            left = x < ridge
            top_half = y < MID0
            if left:
                c = "lavender" if top_half else "violet"
            else:
                c = "violet" if top_half else "purple"
            if y > MID1 + 2 and not left:
                c = "plum"                                     # base em sombra
            cv.px(x, y, c)
        # aresta central iluminada (o "fio" do prisma)
        rx = int(round(ridge))
        if x0 <= rx <= x1 and TOP < y < BOT:
            cv.px(rx, y, "lavender" if y < MID1 else "violet")
    # cinturão: linha clara onde as pirâmides se encontram (lê como gema, não como pedra)
    for x in range(int(round(CX - HALF)), int(round(CX + HALF)) + 1):
        if cv.get(x, MID0) is not None and cv.get(x, MID0) != resolve("clear"):
            cv.px(x, MID0, "lavender" if x < CX else "violet")
    cv.selout(light_dir=(-1, -1))
    cv.outline("ink")
    if glint:                                                  # faísca curta no alto-esquerda (sem branco estourado)
        gx, gy = 5, 4
        cv.px(gx, gy, "white")
        if glint > 1:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                cv.px(gx + dx, gy + dy, "lavender")
    return cv


def spin_frames() -> list:
    phases = (0.15, 0.3, 0.5, 0.7, 0.85, 0.7, 0.5, 0.3)        # vai e volta: o brilho "passa" pelas facetas
    glints = (2, 1, 0, 0, 0, 0, 0, 0)
    return [crystal(p, g) for p, g in zip(phases, glints)]


def pop_frames() -> list:
    """Estouro ao coletar: núcleo claro some e faíscas abrem em 8 direções (efeito: sem contorno)."""
    frames = []
    dirs = ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1))
    for f, r in enumerate((1, 3, 5, 7)):
        cv = Canvas(S, S)
        if f == 0:
            cv.rect(6, 6, 4, 4, "lavender")
            cv.rect(7, 7, 2, 2, "white")
        elif f == 1:
            cv.rect(7, 7, 2, 2, "lavender")
        for i, (dx, dy) in enumerate(dirs):
            rr = r if i < 4 else max(1, r - 2)                 # diagonais mais curtas (estrela)
            x, y = int(CX + 0.5 + dx * rr), int(CX + 0.5 + dy * rr)
            if 0 <= x < S and 0 <= y < S:
                cv.px(x, y, "white" if f < 2 else "lavender" if f < 3 else "violet")
                if f < 2 and i < 4:
                    bx, by = x - dx, y - dy
                    cv.px(bx, by, "violet")
        frames.append(cv)
    return frames


if __name__ == "__main__":
    spin = Animation("spin")
    for fr, ms in zip(spin_frames(), (110, 90, 80, 80, 110, 80, 80, 90)):
        spin.add(fr, ms)
    pop = Animation("pop", loop=False)
    for fr, ms in zip(pop_frames(), (50, 60, 70, 90)):
        pop.add(fr, ms)
    print("spin", len(spin.frames[0].colors_used()), spin.frames[2].lint(max_colors=8))
    if "--export" in sys.argv:
        save_animations([spin, pop], "assets/sprites/crystal.png", res_path="res://assets/sprites/crystal.png",
                        tres_path="assets/sprites/crystal_frames.tres", preview_dir="art/previews")
    else:
        save_animations([spin, pop], "art/previews/crystal_wip.png", preview_dir="art/previews")
        # prévia na cena da Lua aprovada: três cristais no arco + a nave
        sys.path.insert(0, "art/src/bg")
        import moon_scene as ms
        comp = ms.ingame_preview(ms.load_layers(), with_lander=False)
        fr = spin_frames()
        for i, (x, y) in enumerate(((250, 150), (320, 120), (390, 150))):
            comp.stamp(fr[i * 2], x - 8, y - 8)
        lander = Canvas.from_image("assets/sprites/lander.png").crop(0, 0, 32, 32)
        comp.stamp(lander, 200, 170)
        comp.save("art/previews/crystal_scene.png", preview=False)
        comp.crop(180, 90, 260, 120).preview("art/previews/crystal_scene_zoom.png", scale=4, grid=False, show_1x=False)
