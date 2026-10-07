"""Tela de título APROVADA (conceito A "Vitrine" v3, 2026-10-06). Skill pixel-art, padrão title-screen.
Usuário: "A letra A ficou de longe a mais legal"; v3 com a crítica aplicada (logo menor, frase da proposta,
estados do Jogar, gatinho respirando, nuvens/estrelas vivas) → "gostei, pode aplicar".

Exporta em CAMADAS (o jogo faz o parallax e as animações em TitleBackdrop):
  assets/bg/title_sky.png     céu degradê + Terra dormindo + estrelinhas fixas (640x360, opaco)
  assets/bg/title_clouds.png  3 nuvens (deriva lenta no jogo)
  assets/bg/title_back.png    morros de trás (parallax lento)
  assets/bg/title_front.png   morro-palco de queijo, ratinhos espiando com patinhas, chão, pedaço de perto,
                              sombrinha do gatinho (parallax rápido; o gato, a bandeira e a nave andam junto)
  assets/sprites/title_cat.png    gatinho herói, "idle" 16 quadros x 150 ms (aceno, piscar, rabo, respiração)
  assets/sprites/title_flag.png   bandeira tremulando, 4 x 300 ms
  assets/sprites/title_lander.png nave "pôster" com as luzinhas do disco em sequência, 6 x 300 ms
  assets/sprites/title_star.png   estrela cadente, 4 x 70 ms (o jogo dispara de vez em quando)
  assets/ui/logo.png              logo "INCREMENTAL LANDER" (letras de doce)
  assets/bg/title_layout.json     posições (px na tela 640x360) + estrelas que cintilam
Rodar da raiz: python3 art/src/title/title_moon.py   (prévia: art/previews/title_moon_preview.png)
"""
import json
import os
import sys

sys.path.insert(0, ".claude/skills/pixel-art/scripts")
sys.path.insert(0, "art/src/title")
from pixelart import *
import title_concepts as tc

W, H = tc.W, tc.H
mc, ku, lg = tc.mc, tc.ku, tc.lg
CAT_X = 376                                                     # centro do gatinho no morro
PAD = 8                                                         # sobra nas laterais das camadas (o parallax não abre buraco)


def padded(c: Canvas) -> Canvas:
    """Camada com PAD px a mais de cada lado: repete a coluna da borda (chão e planície continuam)."""
    o = Canvas(c.w + 2 * PAD, c.h)
    o.stamp(c, PAD, 0)
    for y in range(c.h):
        for x, src in ((range(0, PAD), 0), (range(c.w + PAD, c.w + 2 * PAD), c.w - 1)):
            v = c.get(src, y)
            if v is not None:
                for xx in x:
                    o.px(xx, y, COLOR_NAMES[v])
    return o


def stage():
    hill = tc.cheese_hill(tc.STAGE, [(0.2, 0.35, 3), (0.42, 0.6, 2), (0.7, 0.3, 4), (0.86, 0.55, 2)], 3)
    return hill, 278, 330 - hill.h, tc.tops_of(hill)


def sky() -> Canvas:
    cv = tc.sky_canvas(mc.T["sky"], 30, 4)
    cv.stamp(mc.planet(), 548 - 50, 84 - 50)
    return cv


def clouds() -> Canvas:
    cv = Canvas(W, 260)
    for x, y, kind, flip in tc.A_CLOUDS:
        mc.cloud(cv, x, y, kind, flip)
    return cv


def back() -> Canvas:
    """Morros de trás + planície distante contínua (usuário 2026-10-06, "arrume o morro": a base reta do morro
    acabava solta no céu → morro a mais à esquerda e planície creme de ponta a ponta ligando ao chão)."""
    cv = Canvas(W, H)
    for name, x, flip in (("fundo_alto", -70, False), ("grande_fundo", 160, False), ("fundo_alto", 380, True),
                          ("grande_fundo", 470, True)):
        k = mc.piece(name, flip, mc.T["back"], None, 4, ao=0)
        cv.stamp(k, x, 300 - k.h)
    for x in range(W):                                          # névoa na base dos morros + planície até o chão
        y0 = 286 + int(mc.wave(x, 31, 1.5, freqs=(3, 5, 8)))
        for y in range(y0, H):
            if cv.get(x, y) is not None or y >= 292:
                cv.px(x, y, mc.T["back_haze"])
        cv.px(x, 292 + int(mc.wave(x, 33, 1.2, freqs=(4, 7))), "peach")   # linha suave do horizonte
    return cv


def front() -> tuple:
    hill, hx, hy, tops = stage()
    cv = Canvas(W, H)
    mice = [(ku.mouse_simple(), 562), (ku.mouse_soft(), 590)]
    for face, x in mice:
        cv.stamp(face, x, hy + tops[x + 12 - hx] - 16)
    cv.stamp(hill, hx, hy)
    for face, x in mice:
        ry = hy + tops[x + 12 - hx]
        for dx in (6, 17):
            paw = Canvas(7, 5)
            mc.sphere(paw, 3.5, 2.5, 3, 2, ["white", "white", "cream", "peach"])
            paw.outline("ink")
            cv.stamp(paw, x + dx - 3, ry - 3)
    tc.ground(cv, 326)
    for hx2, hy2, r in ((120, 346, 12), (236, 340, 7), (420, 352, 9)):
        for yy in range(hy2 - r // 2, hy2 + r // 2 + 1):
            for xx in range(hx2 - r, hx2 + r + 1):
                if ((xx - hx2) / r) ** 2 + ((yy - hy2) / (r / 2 + 0.5)) ** 2 <= 1:
                    cv.px(xx, yy, "copper" if yy < hy2 else "terracotta")
    chunk = tc.cheese_hill([(0, 0), (6, 14), (12, 20), (18, 21), (24, 17), (30, 8), (34, 0)], [(0.35, 0.45, 3)], 7)
    cv.stamp(chunk, W - chunk.w + 14, H - chunk.h + 12)
    ground_y = hy + min(tops[CAT_X - hx - 20], tops[CAT_X - hx + 20])
    for x in range(CAT_X - 26, CAT_X + 27):                      # sombrinha do gatinho
        dy = 1 - ((x - CAT_X) / 26) ** 2
        for y in range(ground_y + 1, ground_y + 1 + int(3 * dy) + 1):
            if cv.get(x, y) in (NAME_TO_INDEX["gold"], NAME_TO_INDEX["lemon"], NAME_TO_INDEX["amber"]):
                cv.px(x, y, "amber" if dy > 0.4 else "gold")
    return cv, (hx, hy, tops, ground_y)


def cat_anim() -> tuple:
    a = Animation("idle")
    for fr in range(tc.FR):
        pose = tc.WAVE[fr % len(tc.WAVE)]
        tail = 2 if (fr // 3) % 2 else 0
        br = 1 if (fr // 4) % 2 else 0
        a.add(tc.hero("rest" if pose == "blink" else pose.replace("stand", "rest"), blink=pose == "blink",
                      tail_up=tail, breathe=br), tc.FRAME_MS)
    return a, tc.feet(a.frames[0])


def flag_anim() -> Animation:
    a = Animation("wave")
    for fr in (0, 2, 4, 6):
        a.add(tc.flag(fr), 300)
    return a


def lander_anim() -> Animation:
    a = Animation("idle")
    for i, x in enumerate((12, 22, 32, 47, 57, 67)):
        k = tc.big_lander()
        k.rect(x, 36, 2, 1, "white")
        a.add(k, 300)
    return a


def star_anim() -> Animation:
    a = Animation("fall", loop=False)
    for t in range(4):
        c = Canvas(130, 60)
        tc.shooting_star(c, t, 0, 100, 20)
        a.add(c, 70)
    return a


def export() -> dict:
    os.makedirs("assets/bg", exist_ok=True)
    sky().save("assets/bg/title_sky.png", preview=False)
    clouds().save("assets/bg/title_clouds.png", preview=False)
    padded(back()).save("assets/bg/title_back.png", preview=False)
    fr, (hx, hy, tops, ground_y) = front()
    padded(fr).save("assets/bg/title_front.png", preview=False)
    lg.logo().save("assets/ui/logo.png", preview=False)
    cat, cat_feet = cat_anim()
    flag, lander, star = flag_anim(), lander_anim(), star_anim()
    for name, an in (("title_cat", cat), ("title_flag", flag), ("title_lander", lander), ("title_star", star)):
        save_animations([an], f"assets/sprites/{name}.png", res_path=f"res://assets/sprites/{name}.png",
                        tres_path=f"assets/sprites/{name}_frames.tres", preview_dir="art/previews")
    fx, sx = 446, 478
    layout = {
        "notes": "Gerado por art/src/title/title_moon.py (pixel-art). Posições = canto de cima-esquerdo dos sprites, "
                 "em px na tela 640x360. Camadas: sky (fixa), clouds, back, front (parallax).",
        "cat": [CAT_X - cat.frames[0].w // 2, ground_y - cat_feet + 2],
        "flag": [fx, hy + tops[fx + 4 - hx] - flag.frames[0].h + 3],
        "lander": [sx, hy + min(tops[sx - hx + 10], tops[sx - hx + 70]) - 61 + 1],
        "star": [372, 14],
        "twinkle": [list(p) for p in tc.TWINKLE],
        "layer_pad": PAD,
        "cloud_drift_px": 3,
        "parallax_px": {"clouds": 2, "back": 3, "front": 6},
    }
    with open("assets/bg/title_layout.json", "w") as f:
        json.dump(layout, f, indent=2)
    return layout


def preview(layout: dict) -> None:
    cv = sky()
    cv.stamp(clouds())
    cv.stamp(back())
    cv.stamp(front()[0])
    cv.stamp(flag_anim().frames[0], *layout["flag"])
    cv.stamp(lander_anim().frames[0], *layout["lander"])
    cv.stamp(cat_anim()[0].frames[0], *layout["cat"])
    cv.stamp(lg.logo(), 22, 18)
    cv.preview("art/previews/title_moon_preview.png", scale=2, grid=False)


if __name__ == "__main__":
    lay = export()
    preview(lay)
    print(json.dumps({k: v for k, v in lay.items() if k != "twinkle"}))
