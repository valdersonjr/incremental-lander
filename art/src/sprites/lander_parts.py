"""Pecas da nave que CRESCEM por degrau (ROADMAP 16.5). Skill pixel-art, padrao ship-parts (+ cute-style).

4 versoes por peca (0 = de serie, 1-3 = melhorias), nas duas escalas do jogo:
  - voo (32x32, mesmo contrato do lander: origem (16,16), sapatas na linha y=24, pes x3..28 — NUNCA muda);
  - poster da NAVE (80x70, nave do titulo com a cupula vazia).
Pecas (a melhoria muda a SILHUETA, nao so a cor):
  Gasolina (tank)       capsulas dos dois lados do disco: nenhuma -> bolinha -> capsula -> capsula grande com faixa
  Eficiencia (bocal)    bocal sob o casco: atual -> sino mais comprido -> sino largo com anel aqua -> anel dourado + aletas
  Resistencia (gear)    pernas/sapatas: atual -> sapata redonda -> mola na perna -> mola + almofada gordinha
  Motor (thrust)        chama de plasma (camada propria, atras da nave): curta -> longa -> longa e larga -> com brilho
O casco e montado JA com tanque/bocal/pernas (contorno ink da uniao, como a nave de sempre); a chama e uma camada
separada (efeito, sem contorno) que comeca na boca do bocal (nozzle_mouth). Versao 0 de tudo = a nave de hoje, pixel a
pixel (conferido no __main__).
Rodar da raiz: python3 art/src/sprites/lander_parts.py [--export]
Export (caminhos literais para o pre-commit): assets/sprites/lander_body.png assets/sprites/lander_flame.png
assets/sprites/ship_poster.png assets/sprites/ship_poster_flame.png (+ lander_body_frames.tres, lander_flame_frames.tres,
lander_parts.json: bocas do bocal e caixas das pecas do poster)."""
import sys
sys.path.insert(0, ".claude/skills/pixel-art/scripts"); sys.path.insert(0, "art/src/sprites"); sys.path.insert(0, "art/src/title"); sys.path.insert(0, "art/src/bg")
from pixelart import *
import lander_cute as lc
from lander_styles import cone_flame

TIERS = 4
FLAME = lc.FLAME                                    # white -> ice -> aqua -> sea -> teal -> deep_teal -> navy


# ------------------------------------------------------------------ voo (32x32)

def f_hull(cv: Canvas) -> None:
    """Disco do lander (lander_cute.hull sem bocal nem pernas: viraram pecas)."""
    rows = {16: (5, 26), 17: (3, 28), 18: (3, 28), 19: (5, 26)}
    for y, (x0, x1) in rows.items():
        cv.hline(x0, x1, y, "white" if y == 16 else "mist")
    cv.hline(3, 28, 18, "sea")
    shade = {16: "steel", 17: "steel", 18: "teal", 19: "lilac_grey"}
    for y, (x0, x1) in rows.items():
        cv.hline(max(x0, 24), x1, y, shade[y])
    cv.hline(5, 23, 19, "steel")
    for x in (6, 11, 20, 25):
        cv.px(x, 17, "aqua" if x < 20 else "sea")
    cv.hline(7, 24, 16, "slate")
    cv.hline(10, 21, 16, "charcoal")


def f_tanks(cv: Canvas, t: int) -> None:
    """Bolotas de gas sentadas nos ombros do disco (fora da cupula: x<=6 e x>=25), maiores a cada versao.
    Luz da esquerda: brilho ice em cima-esquerda, sombra sea embaixo-direita; versao 3 com faixa dourada."""
    if t <= 0:
        return
    shape = {1: {14: (5, 6), 15: (4, 6)},
             2: {13: (4, 5), 14: (3, 6), 15: (3, 6)},
             3: {12: (4, 5), 13: (3, 6), 14: (2, 6), 15: (2, 6)}}[t]
    top, bot = min(shape), max(shape)
    for y, (x0, x1) in shape.items():
        cv.hline(x0, x1, y, "aqua"); cv.hline(31 - x1, 31 - x0, y, "aqua")
        cv.px(x1, y, "sea"); cv.px(31 - x0, y, "sea")                         # lado da sombra (direita)
    x0, x1 = shape[top]
    cv.px(x0, top, "ice"); cv.px(31 - x1, top, "ice")                        # brilho
    if t == 3:
        cv.hline(*shape[14], 14, "gold"); cv.hline(31 - shape[14][1], 31 - shape[14][0], 14, "gold")


def nozzle_mouth(e: int) -> int:
    """Linha (y) onde a chama comeca: a ultima linha do bocal."""
    return {0: 21, 1: 22, 2: 23, 3: 23}[e]


def f_nozzle(cv: Canvas, e: int) -> None:
    if e == 0:
        cv.hline(13, 18, 20, "slate"); cv.hline(14, 17, 21, "charcoal")
    elif e == 1:                                                              # sino que abre para baixo
        cv.hline(14, 17, 20, "slate"); cv.hline(13, 18, 21, "slate"); cv.hline(12, 19, 22, "charcoal")
    else:
        cv.hline(14, 17, 20, "gold" if e == 3 else "slate")
        cv.hline(13, 18, 21, "aqua"); cv.px(18, 21, "sea")
        cv.hline(12, 19, 22, "slate"); cv.hline(11, 20, 23, "charcoal")
        if e == 3:                                                            # aletas
            cv.px(11, 21, "steel"); cv.px(10, 22, "steel"); cv.px(20, 21, "lilac_grey"); cv.px(21, 22, "lilac_grey")


def f_legs(cv: Canvas, g: int) -> None:
    """Pernas e sapatas. A linha de baixo das sapatas e SEMPRE y=24 e os pes ficam em x3..28 (fisica)."""
    if g >= 2:                                                                # mola em zigue-zague
        coil = [(7, 20), (6, 20), (5, 21), (6, 22), (7, 22)] if g == 2 else [(7, 20), (6, 20), (5, 21), (6, 21)]
        for x, y in coil:
            cv.px(x, y, "aqua"); cv.px(31 - x, y, "sea")
    else:
        for x, y in ((7, 20), (6, 21), (5, 22), (5, 23)):
            cv.px(x, y, "steel"); cv.px(31 - x, y, "lilac_grey")
    if g == 0:
        cv.hline(3, 7, 24, "steel"); cv.hline(24, 28, 24, "lilac_grey")
    elif g in (1, 2):                                                         # sapata redonda de 2 linhas
        cv.hline(4, 7, 23, "mist"); cv.hline(3, 8, 24, "steel")
        cv.hline(24, 27, 23, "steel"); cv.hline(23, 28, 24, "lilac_grey")
    else:                                                                     # almofada gordinha de 3 linhas
        cv.hline(4, 8, 22, "white"); cv.hline(3, 9, 23, "mist"); cv.hline(3, 9, 24, "steel")
        cv.hline(23, 27, 22, "mist"); cv.hline(22, 28, 23, "steel"); cv.hline(22, 28, 24, "lilac_grey")
        cv.px(5, 23, "sea"); cv.px(26, 23, "teal")                            # bolinha de borracha


def f_body(t: int = 0, e: int = 0, g: int = 0, blink: bool = False) -> Canvas:
    cv = Canvas.grid32()
    lc.dome(cv, with_cat=True, blink=blink, details=True)
    f_tanks(cv, t)
    f_legs(cv, g)
    f_nozzle(cv, e)
    f_hull(cv)
    cv.outline("ink")
    return cv


def f_flame(m: int, frame: int, top: int) -> Canvas:
    """Chama de plasma (sem contorno) num quadro 32x48 (mesma origem do corpo: 0,0 = canto de cima do lander)."""
    L = [7, 10, 8, 11][frame % 4] + [0, 3, 6, 9][m]
    wide = [2.6, 3.0, 2.4, 3.2][frame % 4] + [0.0, 0.5, 1.2, 1.9][m]
    fl = Canvas(32, 48)
    for i in range(L):
        k = i / max(1, L - 1)
        half = int(round(wide * (1.0 - k) ** 0.8))
        c = FLAME[min(len(FLAME) - 1, int(k * (len(FLAME) - 1) + 0.5))]
        fl.hline(16 - half - 1, 15 + half + 1 if half > 0 else 16, top + i, c)
        core = [3, 3, 4, 4][m]
        if i < core and half > 1:
            inset = 1 + (half - 2) // 2 if m >= 2 else 1                     # miolo afina (nao vira bloco)
            fl.hline(16 - half + inset, 15 + half - inset, top + i, "white")
    fl.px(15 if frame % 2 else 16, top + L, FLAME[-2])
    if m == 3:                                                                # faisquinhas laterais (motor no maximo)
        for dx, dy in ((-5, 4), (5, 6), (-4, 9), (4, 11)):
            if (frame + dy) % 2 == 0:
                fl.px(16 + dx, top + dy, "ice")
    return fl


# ------------------------------------------------------------------ poster da NAVE (80x70)

def p_body(t: int = 0, e: int = 0, g: int = 0) -> Canvas:
    """Nave poster (title_concepts.big_lander) com as pecas da versao pedida. Cupula vazia (o piloto saiu)."""
    import math
    k = Canvas(80, 70)
    for y in range(k.h):                                                     # cupula
        for x in range(k.w):
            if ((x + 0.5 - 40) / 19) ** 2 + ((y + 0.5 - 24) / 17) ** 2 <= 1 and y <= 34:
                k.px(x, y, "sky" if (x - 40) * 0.8 + (y - 24) * 0.6 > 6 else "pale_sky")
    k.rect(33, 27, 14, 6, "steel"); k.hline(33, 46, 27, "mist")
    k.rect(35, 21, 10, 6, "lilac_grey"); k.hline(35, 44, 21, "steel")
    for a in range(200, 262, 4):
        x = 40 + 15 * math.cos(math.radians(a)); y = 24 + 13 * math.sin(math.radians(a))
        k.px(int(x), int(y), "white"); k.px(int(x) + 1, int(y), "white")
    p_tanks(k, t)
    p_legs(k, g)
    p_nozzle(k, e)
    rows = {34: (16, 63), 35: (10, 69), 36: (7, 72), 37: (6, 73), 38: (6, 73), 39: (7, 72), 40: (9, 70), 41: (13, 66)}
    for y, (x0, x1) in rows.items():
        k.hline(x0, x1, y, "white" if y <= 35 else "mist")
        k.hline(max(x0, 58), x1, y, "steel" if y < 39 else "lilac_grey")
    k.hline(6, 73, 38, "sea"); k.hline(7, 72, 39, "teal")
    k.hline(18, 61, 34, "slate"); k.hline(24, 55, 34, "charcoal")
    for i, x in enumerate((12, 22, 32, 47, 57, 67)):
        k.px(x, 36, "aqua" if i % 2 else "hot_pink"); k.px(x + 1, 36, "aqua" if i % 2 else "hot_pink")
    k.outline("ink")
    return k


def p_tanks(k: Canvas, t: int) -> None:
    """Bolotas de gas sentadas nos ombros do disco (centros x 12 e 67), maiores a cada versao; faixa sea na 2,
    faixa dourada na 3. Desenhadas atras do disco (o casco cobre a base)."""
    if t <= 0:
        return
    import moon_cute as mc
    r = {1: 4.5, 2: 6.0, 3: 7.5}[t]
    for cx in (12.5, 67.5):
        cy = 35 - r * 0.8
        mc.sphere(k, cx, cy, r, r * 0.9, ["white", "ice", "aqua", "sea"])
        if t >= 2:
            band = int(cy) + (1 if t == 2 else 0)
            for x in range(int(cx - r) - 1, int(cx + r) + 2):
                if k.get(x, band) is not None:
                    k.px(x, band, "gold" if t == 3 else "sea")


def p_nozzle_mouth(e: int) -> int:
    return {0: 47, 1: 49, 2: 51, 3: 51}[e]


def p_nozzle(k: Canvas, e: int) -> None:
    if e == 0:
        k.rect(33, 42, 14, 3, "slate"); k.rect(35, 45, 10, 3, "charcoal")
        return
    k.rect(35, 42, 10, 3, "gold" if e == 3 else "slate")                       # garganta
    k.rect(33, 45, 14, 2, "aqua" if e >= 2 else "slate")
    k.rect(31, 47, 18, 2, "slate"); k.hline(31, 48, 47, "steel")
    if e >= 2:
        k.rect(29, 49, 22, 2, "slate"); k.hline(29, 50, 50, "charcoal")
    else:
        k.hline(31, 48, 49, "charcoal")
    if e == 3:                                                               # aletas
        k.polygon([(31, 43), (23, 51), (30, 51)], "steel"); k.polygon([(48, 43), (56, 51), (49, 51)], "lilac_grey")
        k.line(31, 43, 24, 50, "mist")


def p_legs(k: Canvas, g: int) -> None:
    """Pernas (linha de 2 px) e sapatas; o fundo da sapata fica sempre em y=61."""
    for x0, s in ((18, -1), (61, 1)):
        lit, dark = ("mist", "steel") if s < 0 else ("lilac_grey", "steel")
        if g >= 2:                                                           # mola: espiras alternando ao longo da perna
            for i in range(8):
                y = 42 + i * 2
                x = x0 + s * round(7 * (y - 41) / 17)
                k.hline(x - 2, x + 2, y, "aqua" if s < 0 else "sea")
                k.hline(x - 1, x + 1, y + 1, "teal")
        else:
            k.line(x0, 41, x0 + s * 7, 58, dark); k.line(x0 + 1, 41, x0 + s * 7 + 1, 58, lit)
        fx = x0 + s * 7
        if g == 0:
            k.rect(fx - 4, 59, 10, 3, "steel"); k.hline(fx - 4, fx + 5, 59, "mist")
        elif g in (1, 2):                                                    # sapata redonda mais larga
            k.hline(fx - 4, fx + 5, 58, "mist"); k.rect(fx - 5, 59, 12, 3, "steel"); k.hline(fx - 5, fx + 6, 59, "white")
            k.hline(fx - 4, fx + 5, 61, "lilac_grey")
        else:                                                                # almofada gordinha
            k.hline(fx - 4, fx + 5, 56, "white"); k.rect(fx - 6, 57, 14, 4, "mist"); k.hline(fx - 6, fx + 7, 57, "white")
            k.hline(fx - 5, fx + 6, 61, "steel"); k.rect(fx - 1, 58, 2, 2, "sea")


def p_flame(m: int, frame: int, top: int) -> Canvas:
    """Chama do poster (pilha de elipses como no big_lander) num quadro 80x110; cresce por versao."""
    import title_concepts as tc
    k = Canvas(80, 110)
    ln = [12, 15, 13, 16][frame % 4] + [0, 6, 12, 18][m]
    grow = [0, 1, 2, 3][m]
    for i, col in enumerate(["navy", "teal", "sea", "aqua", "ice", "white"]):
        w = 7 - i + grow
        tc.mc.sphere(k, 40, top + 5 + ln * (1 - i / 7) * 0.9, max(1.5, w), ln * (1 - i / 8) * 0.55 + 2, [col] * 4)
    if m == 3:
        for dx, dy in ((-10, 8), (10, 12), (-8, 18), (9, 22)):
            if (frame + dy) % 2 == 0:
                k.px(40 + dx, top + dy, "ice"); k.px(40 + dx, top + dy + 1, "ice")
    return k


# ------------------------------------------------------------------ prévias e export

def _regression() -> None:
    """Versao 0 de tudo = nave de hoje, pixel a pixel (corpo e os 4 quadros da chama)."""
    import numpy as np
    a = np.array(f_body().to_image()); b = np.array(lc.body().to_image())
    assert (a == b).all(), "corpo v0 difere do lander atual"
    for i in range(4):
        fl = f_flame(0, i, nozzle_mouth(0)).crop(0, 0, 32, 32)
        fl.stamp(f_body())
        assert (np.array(fl.to_image()) == np.array(lc.thrust(i).to_image())).all(), f"chama v0 quadro {i} difere"
    print("regressao ok: versao 0 = lander atual (corpo + 4 quadros de chama)")


def composite_flight(t: int, e: int, g: int, m: int, frame: int = 1, thrust: bool = True) -> Canvas:
    fl = f_flame(m, frame, nozzle_mouth(e)) if thrust else Canvas(32, 48)
    fl.stamp(f_body(t, e, g))
    return fl


def composite_poster(t: int, e: int, g: int, m: int, frame: int = 1, thrust: bool = True) -> Canvas:
    pf = p_flame(m, frame, p_nozzle_mouth(e)) if thrust else Canvas(80, 110)
    pf.stamp(p_body(t, e, g))
    return pf


def sheet(path: str) -> None:
    """Folha de revisao: cada peca nas 4 versoes (resto em 0) + tudo junto; voo x5 e poster x2, sobre o ceu do jogo."""
    from PIL import Image, ImageDraw
    sky = (67, 51, 108)
    rows = [("Gasolina", lambda v: (v, 0, 0, 0)), ("Eficiencia", lambda v: (0, v, 0, 0)),
            ("Resistencia", lambda v: (0, 0, v, 0)), ("Motor", lambda v: (0, 0, 0, v)),
            ("Tudo junto", lambda v: (v, v, v, v))]
    cw, ch = 160 + 8 + 160 + 24, 200 + 8
    img = Image.new("RGB", (110 + cw * TIERS, 28 + ch * len(rows)), (30, 24, 40))
    d = ImageDraw.Draw(img)
    for r, (name, fn) in enumerate(rows):
        d.text((6, 28 + r * ch + 90), name, fill=(240, 236, 230))
        for v in range(TIERS):
            t, e, g, m = fn(v)
            x0, y0 = 110 + v * cw, 28 + r * ch
            for cv, crop, sc, dx in ((composite_flight(t, e, g, m), (0, 0, 32, 40), 5, 0),
                                     (composite_poster(t, e, g, m), (0, 0, 80, 100), 2, 168)):
                im = Image.new("RGB", (cv.w, cv.h), sky); spr = cv.to_image(); im.paste(spr, (0, 0), spr)
                im = im.crop(crop)
                img.paste(im.resize((im.width * sc, im.height * sc), Image.NEAREST), (x0 + dx, y0))
            if r == 0:
                d.text((x0 + 4, 8), f"versao {v}", fill=(249, 194, 43))
    img.save(path)
    print(path)


def _bbox(cv: Canvas) -> list[int]:
    xs = [x for y in range(cv.h) for x in range(cv.w) if cv.get(x, y) is not None]
    ys = [y for y in range(cv.h) for x in range(cv.w) if cv.get(x, y) is not None]
    return [min(xs), min(ys), max(xs) - min(xs) + 1, max(ys) - min(ys) + 1] if xs else [0, 0, 0, 0]


FLAME_H = 24            # quadro da chama do voo (32x24, comeca na boca do bocal)
P_FLAME_H = 60          # quadro da chama do poster (80x60)


def export() -> None:
    """Folhas do jogo + JSON de montagem (bocas do bocal, tamanhos, caixas das pecas do poster para o destaque)."""
    import json
    body = []
    for t in range(TIERS):
        for e in range(TIERS):
            for g in range(TIERS):
                a, b = f_body(t, e, g), f_body(t, e, g, blink=True)
                body.append(Animation(f"b_{t}{e}{g}").add(a, 2400).add(b, 130).add(a, 1100).add(b, 130))
    save_animations(body, "assets/sprites/lander_body.png", res_path="res://assets/sprites/lander_body.png",
                    tres_path="assets/sprites/lander_body_frames.tres", preview_dir="art/previews/lander_parts_export")
    flames = []
    for m in range(TIERS):
        an = Animation(f"flame_{m}")
        for i in range(4):
            an.add(f_flame(m, i, 0).crop(0, 0, 32, FLAME_H), 70)
        flames.append(an)
    save_animations(flames, "assets/sprites/lander_flame.png", res_path="res://assets/sprites/lander_flame.png",
                    tres_path="assets/sprites/lander_flame_frames.tres", preview_dir="art/previews/lander_parts_export")
    atlas = Canvas(80 * 8, 70 * 8)                                           # poster: 64 corpos, indice t*16 + e*4 + g
    for t in range(TIERS):
        for e in range(TIERS):
            for g in range(TIERS):
                i = t * 16 + e * 4 + g
                atlas.stamp(p_body(t, e, g), (i % 8) * 80, (i // 8) * 70)
    atlas.save("assets/sprites/ship_poster.png", preview_dir="art/previews/lander_parts_export")
    pfl = Canvas(80 * 4, P_FLAME_H * TIERS)                                  # poster: linha = versao do Motor, 4 quadros
    for m in range(TIERS):
        for i in range(4):
            pfl.stamp(p_flame(m, i, 0).crop(0, 0, 80, P_FLAME_H), i * 80, m * P_FLAME_H)
    pfl.save("assets/sprites/ship_poster_flame.png", preview_dir="art/previews/lander_parts_export")
    boxes = {"tank": [], "efficiency": [], "gear": []}                     # por versao: lista de caixas (uma por lado)
    for v in range(TIERS):
        for key, fn in (("tank", p_tanks), ("efficiency", p_nozzle), ("gear", p_legs)):
            k = Canvas(80, 70); fn(k, v)
            if key == "efficiency":
                boxes[key].append([_bbox(k)])
                continue
            left = k.crop(0, 0, 40, 70)
            b = _bbox(left) if v or key != "tank" else [5, 29, 12, 6]          # sem tanque: o ombro do disco
            boxes[key].append([b, [80 - b[0] - b[2], b[1], b[2], b[3]]])
    meta = {"tiers": TIERS,
            "flight": {"frame": [32, 32], "flame": [32, FLAME_H], "mouth": [nozzle_mouth(e) for e in range(TIERS)]},
            "poster": {"frame": [80, 70], "grid": 8, "flame": [80, P_FLAME_H],
                       "mouth": [p_nozzle_mouth(e) for e in range(TIERS)], "boxes": boxes}}
    with open("assets/sprites/lander_parts.json", "w") as fh:
        json.dump(meta, fh, indent=1)
    print("export ok:", meta["flight"], {k: len(v) for k, v in boxes.items()})


if __name__ == "__main__":
    _regression()
    for t in range(TIERS):
        print("cores voo v%d:" % t, len(f_body(t, t, t).colors_used()), "lint:", f_body(t, t, t).lint(max_colors=18))
    sheet("art/previews/lander_parts_sheet.png")
    if "--export" in sys.argv:
        export()
