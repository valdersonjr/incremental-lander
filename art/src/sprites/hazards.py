"""Perigos por mundo (Fase 11.5; padrão: patterns/world-hazards.md). Efeitos sem contorno (style-guide); objetos
interativos (brinquedo) com selout + contorno ink. Paleta Resurrect 64.

Contrato com o jogo (godot-dev, game/flight/hazard_view.gd):
  hazard_leaf    8x8   "flutter" 4 quadros   folha de Silvânia levada pela rajada (centrada)
  hazard_streak 16x4   "swirl"   3 quadros   traço de ar da rajada (centrado)
  syrup_column  32x16  "flow"    3 quadros   segmento da coluna de calda (empilha para cima; x centrado na coluna)
  syrup_cap     32x16  "splash"  3 quadros   topo da coluna (base do sprite = topo da coluna)
  syrup_bubbles 32x10  "bubble"  3 quadros   aviso no chão antes da erupção (base do sprite = chão)
  fan           96x28  "spin"    3 quadros   ventilador deitado no chão soprando para cima (base = chão)
  air_streak     3x14  "rise"    1 quadro    risco de ar subindo na coluna do ventilador (centrado)
  toy_block     24x24  "tumble"  4 quadros   bloquinho de madeira caindo (centrado)
  toy_shadow    24x6   "warn"    2 quadros   sombra no chão onde o brinquedo vai cair (centro = ponto no chão)
  toy_alert      9x13  "blink"   2 quadros   "!" vermelho acima da coluna de queda (centrado)
Rodar da raiz: python3 art/src/sprites/hazards.py [--export]
"""
import sys

import numpy as np

sys.path.insert(0, ".claude/skills/pixel-art/scripts")
from pixelart import *


# ------------------------------------------------------------------ Silvânia: rajada (folhas + traços de ar)
def leaf_frames() -> list:
    """Folha clara e quente (limão/dourado) tremulando em 4 posições — lê contra a floresta escura; o movimento rápido
    da rajada faz o resto (efeito: sem contorno)."""
    shapes = [
        ["...ab...", "..abbb..", ".abbbc..", "..bbc...", "...c...."],
        ["........", ".aabbb..", "aabbbbc.", ".bbbbc..", "........"],
        ["....ba..", "...bbba.", "..cbbba.", "...cbb..", "....c..."],
        ["........", "..bbbaa.", ".cbbbbaa", "..cbbbb.", "........"],
    ]
    out = []
    for sh in shapes:
        cv = Canvas(8, 8)
        cv.paint(sh, {"a": "lemon", "b": "gold", "c": "amber"}, x=0, y=1)
        out.append(cv)
    return out


def streak_frames() -> list:
    """Traço de ar em arco (swirl) branco: cresce, enrola e some."""
    out = []
    for f in range(3):
        cv = Canvas(16, 4)
        if f == 0:
            cv.hline(3, 10, 2, "white"); cv.hline(1, 3, 3, "mist")
        elif f == 1:
            cv.hline(1, 11, 2, "white"); cv.px(12, 1, "white"); cv.px(13, 0, "mist"); cv.hline(0, 2, 3, "mist")
        else:
            cv.hline(6, 12, 2, "mist"); cv.px(13, 1, "mist"); cv.px(14, 0, "steel")
        out.append(cv)
    return out


# ------------------------------------------------------------------ Docelândia: gêiser de calda de morango
SYRUP = ["berry_dark", "rose", "pink", "salmon", "peach"]


def syrup_column_frames() -> list:
    """Coluna de calda subindo: faixas verticais (borda escura, miolo claro) com gotas que sobem 5 px por quadro."""
    out = []
    for f in range(3):
        cv = Canvas(32, 16)
        for y in range(16):
            # borda ondulada que sobe com o fluxo (lê como líquido, não como pilar)
            wob = round(1.2 * np.sin((y + 5 * f) * 2 * np.pi / 16))
            wob2 = round(1.2 * np.sin((y + 5 * f + 6) * 2 * np.pi / 16))
            for x in range(4 + wob, 28 + wob2):
                d = abs(x - 15.5 - (wob + wob2) / 2) / 12.0
                c = "peach" if d < 0.2 else "salmon" if d < 0.45 else "pink" if d < 0.7 else "rose" if d < 0.9 else "berry_dark"
                if x < 15 and d < 0.6 and c != "peach":
                    c = SYRUP[min(SYRUP.index(c) + 1, 4)]      # lado da luz (esquerda) mais claro
                cv.px(x, y, c)
        for y in range(16):                                    # fio de brilho correndo para cima
            if (y + 5 * f) % 8 < 4:
                cv.px(11, y, "cream")
        for i, gx in enumerate((8, 14, 20, 24)):              # bolhas/brilhos subindo (laço de 15 px em 3 quadros)
            gy = (16 + 3 * i - 5 * f) % 16
            cv.px(gx, gy, "cream"); cv.px(gx, (gy + 1) % 16, "peach")
        out.append(cv)
    return out


def syrup_cap_frames() -> list:
    """Topo da coluna: coroa de respingo que pulsa (gotas soltas acima)."""
    out = []
    for f in range(3):
        cv = Canvas(32, 16)
        rise = (0, 2, 1)[f]
        for x in range(4, 28):
            d = abs(x - 15.5) / 12.0
            top = int(8 + 6 * d * d) - rise
            for y in range(max(top, 0), 16):
                c = "peach" if d < 0.25 else "salmon" if d < 0.5 else "pink" if d < 0.75 else "rose"
                cv.px(x, y, c)
            cv.px(x, max(top, 0), "cream" if d < 0.5 else "peach")
        for gx, gy in ((6, 4), (25, 3), (12, 1), (20, 2))[: 2 + f]:
            cv.px(gx, gy - rise + 2, "pink"); cv.px(gx, gy - rise + 3, "rose")
        out.append(cv)
    return out


def syrup_bubbles_frames() -> list:
    """Aviso: bolhas de calda brotando do chão (crescem e estouram) — 'vai jorrar aqui'."""
    out = []
    spots = ((8, 0), (15, 1), (22, 2), (12, 2), (19, 0))
    for f in range(3):
        cv = Canvas(32, 10)
        cv.hline(5, 26, 9, "rose"); cv.hline(7, 24, 8, "pink")  # poça na base
        for x0, ph in spots:
            r = (f + ph) % 3
            if r == 0:
                cv.px(x0, 7, "salmon")
            elif r == 1:
                cv.rect(x0 - 1, 5, 3, 3, "pink"); cv.px(x0 - 1, 5, "cream")
            else:
                cv.px(x0 - 2, 4, "peach"); cv.px(x0 + 2, 4, "peach"); cv.px(x0, 3, "cream")
        out.append(cv)
    return out


# ------------------------------------------------------------------ O Quarto: ventilador + brinquedo caindo
def fan_frames() -> list:
    """Ventilador de caixa GIGANTE deitado no tapete (escala do quarto), soprando para cima: caixa de plástico clara,
    boca com grade e pás borradas girando, botões e pés."""
    out = []
    W, H = 96, 28
    for f in range(3):
        cv = Canvas(W, H)
        cv.rect(3, 9, W - 6, 16, "steel")                     # caixa
        cv.rect(3, 9, W - 6, 1, "white"); cv.rect(3, 9, 1, 16, "mist")
        cv.rect(W - 4, 10, 1, 15, "lilac_grey"); cv.rect(3, 24, W - 6, 1, "slate")
        cv.rect(6, 2, W - 12, 8, "navy")                      # boca vista um pouco de cima
        for x in range(7, W - 6):
            ph = (x + f * 7) % 14
            cv.px(x, 3, "pale_sky" if ph < 3 else "indigo")
            cv.px(x, 4, "sky" if ph in (3, 4, 5) else "navy")
            cv.px(x, 5, "blue" if ph in (5, 6) else "navy")
            cv.px(x, 6, "indigo")
            cv.px(x, 7, "navy")
        for x in range(6, W - 5, 5):                          # grade
            cv.vline(x, 2, 8, "mist")
        cv.rect(6, 1, W - 12, 1, "white"); cv.rect(6, 9, W - 12, 1, "mist")
        cv.rect(W - 26, 13, 16, 7, "slate"); cv.rect(W - 25, 14, 14, 5, "charcoal")       # painel
        cv.px(W - 23, 16, "red"); cv.px(W - 19, 16, "emerald"); cv.px(W - 15, 16, "gold")
        cv.rect(10, 14, 40, 4, "mist"); cv.rect(10, 14, 40, 1, "white")                   # etiqueta
        for x in (8, W - 12):                                 # pés
            cv.rect(x, 25, 5, 3, "slate"); cv.rect(x, 25, 5, 1, "lilac_grey")
        out.append(cv)
    return out


def air_streak_frame() -> Canvas:
    """Risco de ar subindo (branco na cabeça, some em azul na cauda)."""
    cv = Canvas(3, 14)
    cv.vline(1, 0, 4, "white"); cv.vline(1, 5, 9, "pale_sky"); cv.vline(1, 10, 13, "sky")
    cv.px(0, 9, "pale_sky"); cv.px(2, 4, "pale_sky")
    return cv


def toy_block_frames() -> list:
    """Bloquinho de madeira com letra (brinquedo gigante), girando 90° por quadro ao cair. 24 px = área que destrói
    a nave (world.json hazards titan toy.radius_m 12): o que se vê é o que acerta."""
    base = Canvas(24, 24)
    base.rect(2, 2, 20, 20, "honey")
    base.rect(2, 2, 20, 2, "cream"); base.rect(2, 2, 2, 20, "cream")
    base.rect(20, 4, 2, 18, "copper"); base.rect(4, 20, 18, 2, "copper")
    base.rect(6, 6, 12, 12, "red")                            # face pintada
    base.rect(6, 6, 12, 1, "salmon")
    base.paint(["..ww..", ".wwww.", "ww..ww", "ww..ww", "wwwwww", "ww..ww", "ww..ww"], {"w": "white"}, x=9, y=8)  # "A"
    base.selout(light_dir=(-1, -1))
    base.outline("ink")
    out = [base]
    for _ in range(3):
        nxt = Canvas(24, 24)
        nxt.stamp(out[-1], 0, 0)
        nxt.rotate90()
        out.append(nxt)
    return out


def toy_shadow_frames() -> list:
    """Sombra no chão (dither escuro) que pulsa: onde o brinquedo vai cair."""
    out = []
    for f in range(2):
        cv = Canvas(24, 6)
        rx = 11.5 if f == 0 else 9
        for y in range(6):
            for x in range(24):
                dx, dy = (x - 11.5) / rx, (y - 2.5) / 2.6
                if dx * dx + dy * dy <= 1.0 and (x + y) % 2 == 0:
                    cv.px(x, y, "ink")
        out.append(cv)
    return out


def toy_alert_frames() -> list:
    """'!' vermelho grande com contorno escuro (lê contra qualquer fundo), pisca entre vivo e escuro."""
    out = []
    for f in range(2):
        cv = Canvas(9, 13)
        c, h = ("red", "salmon") if f == 0 else ("crimson", "red")
        cv.rect(3, 1, 3, 7, c); cv.px(3, 1, h); cv.px(3, 2, h)
        cv.rect(3, 9, 3, 3, c); cv.px(3, 9, h)
        cv.outline("ink")
        out.append(cv)
    return out


ASSETS = {
    # nome: (animação, frames, ms) — caminhos literais (o pre-commit liga cada PNG ao seu script-fonte):
    "assets/sprites/hazard_leaf.png": ("flutter", leaf_frames, 120),
    "assets/sprites/hazard_streak.png": ("swirl", streak_frames, 90),
    "assets/sprites/syrup_column.png": ("flow", syrup_column_frames, 90),
    "assets/sprites/syrup_cap.png": ("splash", syrup_cap_frames, 110),
    "assets/sprites/syrup_bubbles.png": ("bubble", syrup_bubbles_frames, 140),
    "assets/sprites/fan.png": ("spin", fan_frames, 60),
    "assets/sprites/air_streak.png": ("rise", lambda: [air_streak_frame()], 200),
    "assets/sprites/toy_block.png": ("tumble", toy_block_frames, 110),
    "assets/sprites/toy_shadow.png": ("warn", toy_shadow_frames, 160),
    "assets/sprites/toy_alert.png": ("blink", toy_alert_frames, 180),
}


if __name__ == "__main__":
    export = "--export" in sys.argv
    for path, (anim_name, make, ms) in ASSETS.items():
        anim = Animation(anim_name)
        for fr in make():
            anim.add(fr, ms)
        name = path.split("/")[-1][:-4]
        if export:
            save_animations([anim], path, res_path="res://" + path, tres_path=path[:-4] + "_frames.tres",
                            preview_dir="art/previews")
        else:
            save_animations([anim], f"art/previews/{name}_wip.png", preview_dir="art/previews")
    if not export:
        # prévias nas cenas aprovadas (camadas exportadas do mundo): rajada na floresta, gêiser nos doces, quarto
        import json as _json
        from PIL import Image as _Image

        def scene(pid: str) -> Canvas:
            meta = _json.load(open(f"assets/bg/{pid}_layers.json"))
            im = _Image.open(f"assets/bg/{pid}_sky.png").convert("RGBA")
            for layer, key in (("far", "far_y"), ("mid", "mid_y"), ("plain", "plain_y")):
                lay = _Image.open(f"assets/bg/{pid}_{layer}.png").convert("RGBA")
                im.alpha_composite(lay.crop((0, 0, 640, min(lay.height, 360 - int(meta[key])))), (0, int(meta[key])))
            return Canvas.from_image_obj(im) if hasattr(Canvas, "from_image_obj") else _canvas_from(im)

        def _canvas_from(im) -> Canvas:
            tmp = "art/previews/_hz_tmp.png"
            im.save(tmp)
            return Canvas.from_image(tmp)

        rows = []
        lander = Canvas.from_image("assets/sprites/lander.png").crop(0, 0, 32, 32)
        for pid in ("ares", "kronos", "titan"):
            comp = scene(pid)
            if pid == "ares":
                for i, (x, y) in enumerate(((260, 120), (300, 140), (330, 110), (360, 150), (390, 125))):
                    comp.stamp(leaf_frames()[i % 4], x, y)
                for i, (x, y) in enumerate(((240, 130), (320, 128), (370, 140))):
                    comp.stamp(streak_frames()[i % 3], x, y)
                comp.stamp(lander, 300, 160)
            elif pid == "kronos":
                gy = 300
                comp.stamp(syrup_bubbles_frames()[1], 150, gy - 10)
                col = syrup_column_frames()
                for k in range(6):
                    comp.stamp(col[k % 3], 300, gy - 16 * (k + 1))
                comp.stamp(syrup_cap_frames()[1], 300, gy - 16 * 7)
                comp.stamp(lander, 300, gy - 16 * 5)
            else:
                gy = 320
                comp.stamp(fan_frames()[0], 170, gy - 28)
                for i in range(12):
                    comp.stamp(air_streak_frame(), 178 + i * 7, gy - 50 - (i * 37) % 140)
                comp.stamp(toy_block_frames()[1], 420, 120)
                comp.stamp(toy_shadow_frames()[0], 416, gy - 4)
                comp.stamp(toy_alert_frames()[0], 425, 60)
                comp.stamp(lander, 202, gy - 130)
            rows.append(comp.crop(120, 40, 400, 300))
        sheet = Canvas(400, 300 * len(rows))
        for i, r in enumerate(rows):
            sheet.stamp(r, 0, 300 * i)
        sheet.preview("art/previews/hazards_scene.png", scale=2, grid=False, show_1x=False)
