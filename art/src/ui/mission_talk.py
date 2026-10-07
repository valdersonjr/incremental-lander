"""Janela de conversa do pedido (2026-10-07, maquete aprovada em art/previews/mission_talk/). Skill pixel-art,
padrão mouse-dialogue. Exporta:
  assets/sprites/talk_cat.png (+ _frames.tres)        gatinho herói k=1.15: idle, thumb (joinha), worried (gás pouco)
  assets/sprites/talk_mouse_<tipo>.png (+ _frames.tres) ratinho de corpo inteiro k=1.25: idle, talk, happy
  assets/ui/talk_stage_luna.png                       palco 408x112: faixa das camadas aprovadas da Lua (sem pintura nova)
  assets/ui/luna/button_go.png, button_go_hover.png  botão verde "Aceitar missão" = botão principal recolorido
Rodar da raiz: python3 art/src/ui/mission_talk.py
"""
import sys

sys.path.insert(0, ".claude/skills/pixel-art/scripts")
sys.path.insert(0, "art/src/sprites")
sys.path.insert(0, "art/src/ui")
from pixelart import *
import cat_hero
import mouse_hero
import save_card_bg

CAT_K, MOUSE_K = 1.15, 1.25
STAGE_W, STAGE_H = 408, 112
STAGE_X, STAGE_Y = 680, 150          # trecho do cenário montado (céu, nuvens, morros distantes) + Terra


# botão de aceitar: rampa violeta do botão principal -> rampa verde (mesma da maquete aprovada)
GO = {"violet": "emerald", "purple": "green", "cream": "leaf", "white": "ice", "lavender": "leaf"}


def cat_anims() -> list:
    c = cat_hero.Cat(CAT_K)
    rest, blink, br = c.body(), c.body(blink=True), c.body(breathe=1)
    idle = Animation("idle")
    for fr, ms in ((rest, 900), (br, 500), (rest, 700), (blink, 120), (rest, 600), (br, 500)):
        idle.add(fr, ms)
    thumb = Animation("thumb", loop=False)
    thumb.add(c.body("wave0"), 90).add(c.body("thumb", tail_up=2), 600)
    worried = Animation("worried")
    w0, w1 = c.body("hold", worried=True), c.body("hold", worried=True, breathe=1)
    worried.add(w0, 400).add(w1, 400)
    return [idle, thumb, worried]


def mouse_anims(kind: str) -> list:
    m = mouse_hero.Mouse(kind, MOUSE_K)
    rest, blink = m.draw(), m.draw(blink=True)
    idle = Animation("idle")
    idle.add(rest, 1000).add(blink, 120).add(rest, 800)
    talk = Animation("talk")
    talk.add(m.draw("talk"), 140).add(rest, 140).add(m.draw("talk"), 140).add(rest, 300)
    happy = Animation("happy")
    happy.add(m.draw("happy", wag=3, hop=4), 160).add(m.draw("happy", wag=0, hop=0), 160)
    return [idle, talk, happy]


def stage() -> Canvas:
    """Céu + nuvens + Terra dormindo + morros distantes (sem a camada do meio: moinho, casinhas e varal ficariam
    atrás dos personagens). O chão de queijo do palco é desenhado pela UI (faixa na base)."""
    import json
    meta = json.load(open("assets/bg/luna_layers.json"))
    w = STAGE_X + STAGE_W
    cv = Canvas(w, 360)
    sky = save_card_bg.frame0("assets/bg/luna_sky.png", meta["anim"]["sky"]["frames"])
    clouds = save_card_bg.frame0("assets/bg/luna_clouds.png", meta["anim"]["clouds"]["frames"])
    far = Canvas.from_image("assets/bg/luna_far.png")
    planet = Canvas.from_image("assets/bg/luna_planet.png")
    for layer, y in ((sky, 0), (clouds, meta["clouds"]["y"])):
        for x in range(0, w, layer.w):
            cv.stamp(layer, x, y)
    cv.stamp(planet, STAGE_X + STAGE_W // 2 - planet.w // 2 + 30, STAGE_Y - 34)      # Terra atrás dos morros (rosto à vista)
    for x in range(0, w, far.w):
        cv.stamp(far, x, meta["far_y"])
    return cv.crop(STAGE_X, STAGE_Y, STAGE_W, STAGE_H)


if __name__ == "__main__":
    save_animations(cat_anims(), "assets/sprites/talk_cat.png", res_path="res://assets/sprites/talk_cat.png",
                    tres_path="assets/sprites/talk_cat_frames.tres", preview_dir="art/previews")
    for kind in mouse_hero.KINDS:
        name = f"talk_mouse_{kind}"
        save_animations(mouse_anims(kind), f"assets/sprites/{name}.png", res_path=f"res://assets/sprites/{name}.png",
                        tres_path=f"assets/sprites/{name}_frames.tres", preview_dir="art/previews")
    for src, dst in (("button_primary", "button_go"), ("button_primary_hover", "button_go_hover")):
        b = Canvas.from_image(f"assets/ui/luna/{src}.png")
        for a, c in GO.items():
            b.replace(a, c)
        b.save(f"assets/ui/luna/{dst}.png", preview_dir="art/previews")
    st = stage()
    st.save("assets/ui/talk_stage_luna.png", preview_dir="art/previews")
    print("ok")

# caminhos literais dos assets (o pre-commit procura a fonte de cada PNG pelo caminho escrito no script):
# assets/sprites/talk_cat.png assets/sprites/talk_mouse_simple.png assets/sprites/talk_mouse_heavy.png
# assets/sprites/talk_mouse_soft.png assets/sprites/talk_mouse_fast.png assets/sprites/talk_mouse_passenger.png
# assets/sprites/talk_mouse_tow.png assets/sprites/talk_mouse_double.png assets/ui/talk_stage_luna.png
# assets/ui/luna/button_go.png assets/ui/luna/button_go_hover.png
