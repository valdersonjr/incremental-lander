"""Animação de camadas de cena (vento, pirulitos girando, estrelas cintilando...).

Formato para o jogo: quadros da mesma camada EMPILHADOS NA VERTICAL num PNG só (altura = h * quadros).
O Godot troca o quadro mudando region_rect.y; o laço horizontal (texture_repeat) continua funcionando.
Metadados no <planeta>_layers.json: "anim": {"mid": {"frames": N, "ms": M}, ...}, "rock_frames", "rock_ms".
"""
import sys

sys.path.insert(0, ".claude/skills/pixel-art/scripts")
from pixelart import Canvas


def stack(frames: list) -> Canvas:
    w, h = frames[0].w, frames[0].h
    out = Canvas(w, h * len(frames))
    for i, f in enumerate(frames):
        out.stamp(f, 0, i * h)
    return out


def stack_cells(frames: list) -> Canvas:
    """Atlas de enfeites: cada quadro é uma LINHA do atlas (mesma coluna = mesmo enfeite)."""
    return stack(frames)


def save_gif(frames: list, path: str, ms: int, scale: int = 2) -> str:
    from PIL import Image
    ims = []
    for f in frames:
        tmp = path + ".tmp.png"
        f.save(tmp, preview=False)
        im = Image.open(tmp).convert("RGB")
        ims.append(im.resize((im.width * scale, im.height * scale), Image.NEAREST))
    ims[0].save(path, save_all=True, append_images=ims[1:], duration=ms, loop=0)
    import os
    os.remove(path + ".tmp.png")
    return path
