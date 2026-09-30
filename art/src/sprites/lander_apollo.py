"""[ALTERNATIVA NAO ESCOLHIDA - estilo A Apollo] Lander 32x32 + chama. Skill pixel-art.
Contrato com o jogo: origem = centro do sprite (16,16); sapatas na linha y=24 (feet_offset 8 px).
Rodar da raiz: python3 art/src/sprites/lander.py [--final]"""
import sys; sys.path.insert(0, ".claude/skills/pixel-art/scripts")
from pixelart import *

LEG = {"l": "lilac_grey", "d": "slate", "f": "shadow"}

# metade esquerda (colunas 0..15); a direita e espelhada (mirror_x): simetria em torno do centro 15.5/16
LEFT = [
    "................",  # 0
    "................",  # 1
    "................",  # 2
    "................",  # 3
    "...............a",  # 4  antena (2 px no centro)
    "...............a",  # 5
    "...........MMMMM",  # 6  topo da cabine (luz)
    "..........MMmmmm",  # 7
    "..........Mmmmmm",  # 8
    "..........mmmmmm",  # 9
    "..........smmmmm",  # 10
    "..........ssssss",  # 11
    "........kkkkkkkk",  # 12 junta entre estagios (sombra)
    "........ggggggGg",  # 13 estagio de descida: folha dourada
    "........cgcccccg",  # 14
    "........ccccgccc",  # 15
    "........rrrrrrrr",  # 16
    ".......l.......n",  # 17 pernas + bocal (sino 2 -> 6 px)
    ".......l......nn",  # 18
    "......l......nNN",  # 19
    "......l.........",  # 20
    ".....l..........",  # 21
    ".....l..........",  # 22
    ".....l..........",  # 23
    "....fff.........",  # 24 sapata (pes do corpo fisico)
    "................",  # 25
]
LEGEND = {
    "a": "slate",
    "M": "white", "m": "mist", "s": "steel",
    "k": "slate",
    "G": "lemon", "g": "gold", "c": "honey", "r": "copper",
    "l": "lilac_grey", "f": "slate",
    "n": "charcoal", "N": "slate",
}
# janela unica (fora do centro, como o LM): pintada DEPOIS do espelhamento
WINDOW = ["ww.", "wWw"]
WINDOW_LEGEND = {"w": "sky", "W": "navy"}


# sombra da folha dourada (lado direito, longe da luz)
FOIL_SHADE = {"lemon": "gold", "gold": "amber", "honey": "copper", "copper": "terracotta"}


def body() -> Canvas:
    cv = Canvas.grid32()
    cv.paint(LEFT, LEGEND)
    cv.mirror_x()
    cv.paint(WINDOW, WINDOW_LEGEND, x=12, y=8)
    # luz de cima-esquerda: escurece a metade direita da cabine e da folha (volume)
    for y in range(6, 12):
        for x in range(18, 22):
            v = cv.get(x, y)
            if v is not None and COLOR_NAMES[v] in ("mist", "white"):
                cv.px(x, y, "steel" if COLOR_NAMES[v] == "mist" else "mist")
    for y in range(13, 17):
        for x in range(19, 24):
            v = cv.get(x, y)
            if v is not None and COLOR_NAMES[v] in FOIL_SHADE:
                cv.px(x, y, FOIL_SHADE[COLOR_NAMES[v]])
    cv.outline("ink")
    return cv


def flame(frame: int) -> Canvas:
    """Chama triangular sob o bocal (a partir da linha 20). frame 0..3 varia comprimento e largura."""
    fl = Canvas.grid32()
    L = [7, 10, 8, 11][frame % 4]
    wide = [2.6, 3.0, 2.4, 3.2][frame % 4]
    cols = ["white", "lemon", "gold", "amber", "orange", "brick", "maroon"]
    for i in range(L):
        t = i / max(1, L - 1)
        half = int(round(wide * (1.0 - t) ** 0.8))
        c = cols[min(len(cols) - 1, int(t * (len(cols) - 1) + 0.5))]
        fl.hline(16 - half - 1, 15 + half + 1 if half > 0 else 16, 20 + i, c)
        if i < 3 and half > 1:
            fl.hline(16 - half + 1, 15 + half - 1, 20 + i, "white" if i == 0 else "lemon")
    fl.px(15 if frame % 2 else 16, 20 + L, "brick")    # ponta irregular
    return fl


def frame_with_flame(frame: int) -> Canvas:
    cv = flame(frame)
    cv.stamp(body())
    return cv


if __name__ == "__main__":
    b = body()
    print("cores:", len(b.colors_used()), b.colors_used())
    print("lint:", b.lint(max_colors=16))
    final = "--final" in sys.argv
    if not final:
        b.save("art/previews/lander_body_wip.png")
        thrust = Animation("thrust")
        for i in range(4):
            thrust.add(frame_with_flame(i), 70)
        save_animations([Animation("idle").add(b, 200), thrust], "art/previews/lander_wip.png",
                        preview_dir="art/previews")
    else:
        thrust = Animation("thrust")
        for i in range(4):
            thrust.add(frame_with_flame(i), 70)
        save_animations([Animation("idle").add(b, 200), thrust], "assets/sprites/lander.png",
                        res_path="res://assets/sprites/lander.png", tres_path="assets/sprites/lander_frames.tres")
