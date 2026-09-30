"""Lander do jogador — estilo B FUTURISTA (escolhido pelo usuario em 2026-09-30). Skill pixel-art.
32x32, visao lateral: casco branco pontiagudo, visor e faixa turquesa, pernas lilac_grey, chama de plasma ciano.
Contrato com o jogo: origem = centro do sprite (16,16); sapatas na linha y=24 (feet_offset 8 px).
Design em lander_styles.py (b_body/b_flame). Rodar da raiz: python3 art/src/sprites/lander.py"""
import sys; sys.path.insert(0, ".claude/skills/pixel-art/scripts"); sys.path.insert(0, "art/src/sprites")
from pixelart import *
from lander_styles import b_body, b_flame


def thrust_frame(i: int) -> Canvas:
    cv = b_flame(i)
    cv.stamp(b_body())
    return cv


if __name__ == "__main__":
    body = b_body()
    print("cores:", len(body.colors_used()), "lint:", body.lint(max_colors=16))
    idle = Animation("idle").add(body, 200)
    thrust = Animation("thrust")
    for i in range(4):
        thrust.add(thrust_frame(i), 70)
    meta = save_animations([idle, thrust], "assets/sprites/lander.png", res_path="res://assets/sprites/lander.png",
                           tres_path="assets/sprites/lander_frames.tres", preview_dir="art/previews")
    print(meta)
