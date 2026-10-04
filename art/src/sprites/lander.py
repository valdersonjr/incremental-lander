"""Lander do jogador — estilo FOFO com gatinho astronauta (aprovado pelo usuario em 2026-10-04). Skill pixel-art.
32x32, visao lateral: cupula de vidro com gatinho laranja contornado, disco branco com faixa turquesa, pernas mecanicas,
chama de plasma ciano. Substitui o estilo B futurista (2026-09-30; ainda em lander_styles.py).
Contrato com o jogo: origem = centro do sprite (16,16); sapatas na linha y=24 (feet_offset 8 px); pes x3..28
(half_width 13 px). Design em lander_cute.py. Rodar da raiz: python3 art/src/sprites/lander.py"""
import sys; sys.path.insert(0, ".claude/skills/pixel-art/scripts"); sys.path.insert(0, "art/src/sprites")
from pixelart import *
from lander_cute import body, thrust


if __name__ == "__main__":
    final = body()
    print("cores:", len(final.colors_used()), "lint:", final.lint(max_colors=16))
    idle = Animation("idle").add(final, 2400).add(body(blink=True), 130).add(final, 1100).add(body(blink=True), 130)
    flame = Animation("thrust")
    for i in range(4):
        flame.add(thrust(i), 70)
    meta = save_animations([idle, flame], "assets/sprites/lander.png", res_path="res://assets/sprites/lander.png",
                           tres_path="assets/sprites/lander_frames.tres", preview_dir="art/previews")
    print(meta)
