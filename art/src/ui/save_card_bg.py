"""Fundo dos cartões de jogo salvo (menu inicial, 2026-10-07). Skill pixel-art, padrão save-card-bg.
Uma faixa do cenário do mundo onde o jogo está (hoje só a Lua): monta o 1º quadro das camadas já aprovadas
(céu, morros do fundo, morros do meio, planície) na tela 640x360 e recorta a faixa do horizonte. Sem pintura nova:
mesma arte do voo, então o cartão "mostra o mapa" do jogo salvo. O cartão mostra a faixa inteira, sem escalar.
Rodar da raiz: python3 art/src/ui/save_card_bg.py   -> assets/ui/save_bg_luna.png (+ prévia)
"""
import json
import sys

sys.path.insert(0, ".claude/skills/pixel-art/scripts")
from pixelart import *

W, H = 640, 360
STRIP_W, STRIP_H = 244, 22            # = miolo do cartão (250x28 menos a borda de 3 px)
STRIP_TOP = 240                      # topo dos montinhos até o horizonte (o chão escuro fica de fora)
STRIP_X = 420                        # depois da mina e da cunha: céu limpo atrás do "Jogo N" e os montinhos


def frame0(path: str, frames: int, w: int | None = None) -> Canvas:
    """1º quadro de uma folha com quadros empilhados na vertical (recorta w de largura, se dado)."""
    c = Canvas.from_image(path)
    h = c.h // frames
    return c.crop(0, 0, w or c.w, h)


def scene(world: str, width: int = W) -> Canvas:
    """Cenário montado com `width` px de largura: as camadas se repetem na horizontal como no parallax do voo."""
    meta = json.load(open(f"assets/bg/{world}_layers.json"))
    anim = meta["anim"]
    layers = [(frame0(f"assets/bg/{world}_sky.png", anim["sky"]["frames"]), 0),
              (Canvas.from_image(f"assets/bg/{world}_far.png"), meta["far_y"]),
              (frame0(f"assets/bg/{world}_mid.png", anim["mid"]["frames"]), meta["mid_y"]),
              (frame0(f"assets/bg/{world}_plain.png", anim["plain"]["frames"]), meta["plain_y"])]
    cv = Canvas(width, H)
    for layer, y in layers:
        for x in range(0, width, layer.w):
            cv.stamp(layer, x, y)
    return cv


def strip(world: str) -> Canvas:
    return scene(world, STRIP_X + STRIP_W).crop(STRIP_X, STRIP_TOP, STRIP_W, STRIP_H)


if __name__ == "__main__":
    s = strip("luna")
    s.save("assets/ui/save_bg_luna.png", preview_dir="art/previews")
    print("ok", s.colors_used().__len__(), "cores")
