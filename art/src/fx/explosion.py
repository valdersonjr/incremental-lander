"""Explosão da batida do lander + poeira do pouso (padrão: patterns/explosion.md; estilo: cena da Lua + lander).

Contrato com o jogo (godot-dev):
  explosion 64x64, centro (32,32) = posição do lander; toca uma vez (sem loop) e some.
  dust      48x16, linha 15 = chão, x 24 = centro do lander; toca uma vez no pouso.
Paleta Resurrect 64: flash white/ice (plasma do lander), fogo na rampa fire, fumaça neutral, destroços do casco.
Rodar da raiz: python3 art/src/fx/explosion.py [--export]
"""
import math
import random
import sys

sys.path.insert(0, ".claude/skills/pixel-art/scripts")
from pixelart import *

S = 64
C = 32


def blob(cx: float, cy: float, r: float, seed: int, wobble: float = 0.22) -> set:
    """Forma redonda irregular (raio varia com o ângulo, determinístico)."""
    rng = random.Random(seed)
    ph = [rng.random() * 6.28 for _ in range(3)]
    pts = set()
    for y in range(int(cy - r * 1.4) - 1, int(cy + r * 1.4) + 2):
        for x in range(int(cx - r * 1.4) - 1, int(cx + r * 1.4) + 2):
            a = math.atan2(y - cy, x - cx)
            rr = r * (1 + wobble * (0.6 * math.sin(3 * a + ph[0]) + 0.4 * math.sin(5 * a + ph[1])
                                    + 0.25 * math.sin(7 * a + ph[2])))
            if math.hypot(x - cx, y - cy) <= rr:
                pts.add((x, y))
    return pts


def shade_blob(cv: Canvas, pts: set, cx: float, cy: float, r: float, ramp: list, mode: str = "radial") -> None:
    """Pinta a forma com a rampa (claro -> escuro).
    radial: fogo (emite luz do miolo, levemente deslocado p/ cima-esquerda).
    dir: fumaça/poeira (corpo plano iluminado de cima-esquerda: borda de cima-esq. clara, de baixo-dir. escura)."""
    n = len(ramp)
    for (x, y) in pts:
        if mode == "dir":
            # projeção na direção da luz + borda (pixels perto do contorno de cima-esq. clareiam)
            t = ((x - cx) * 0.6 + (y - cy) * 0.8) / (r * 1.1)          # -1 (luz) .. 1 (sombra)
            up = (x, y - 1) not in pts or (x - 1, y) not in pts
            t = t - 0.5 if up and t < 0.2 else t
            i = min(n - 1, max(0, int((t + 1) / 2 * n)))
        else:
            lx, ly = cx - r * 0.2, cy - r * 0.25
            d = math.hypot(x - lx, y - ly) / (r * 1.25)
            i = min(n - 1, int(d ** 0.9 * n))
        cv.px(x, y, ramp[i])


def explosion_frames() -> list:
    rng = random.Random(7)
    frames = []
    # destroços: pedaços do casco (white/mist/sea) voando em arco com gravidade
    debris = [(rng.uniform(-1, 1) * 2.2, rng.uniform(-2.6, -0.6), rng.choice(["white", "mist", "sea", "steel"]),
               rng.choice([1, 1, 2])) for _ in range(12)]

    def add_debris(cv: Canvas, t: int) -> None:
        for vx, vy, c, size in debris:
            x, y = C + vx * t * 3.2, C + vy * t * 3.2 + 0.55 * t * t
            for dx in range(size):
                cv.px(round(x) + dx, round(y), c)

    # 0: flash — núcleo de plasma rompendo (branco + anel ciano)
    cv = Canvas(S, S)
    for (x, y) in blob(C, C, 7, 1, 0.1):
        cv.px(x, y, "white")
    for (x, y) in blob(C, C, 10, 2, 0.12) - blob(C, C, 7.5, 1, 0.1):
        cv.px(x, y, "ice")
    for a in range(0, 360, 45):                          # raios curtos do flash
        for k in range(11, 15):
            cv.px(round(C + k * math.cos(math.radians(a))), round(C + k * math.sin(math.radians(a))), "aqua")
    frames.append(cv)
    # 1-3: bola de fogo cresce (núcleo branco/lemon -> gold -> amber -> orange -> brick na borda)
    fire = ["white", "lemon", "gold", "amber", "orange", "brick"]
    for i, r in enumerate((12, 15, 18)):
        cv = Canvas(S, S)
        pts = blob(C, C - i, r, 10 + i)
        ramp = fire[i:] if i < 2 else fire[2:] + ["maroon"]
        shade_blob(cv, pts, C, C - i, r, ramp)
        add_debris(cv, i + 1)
        frames.append(cv)
    # 4-5: fragmenta — buracos crescem, fogo esfria, fumaça aparece em cima
    for i, (r, holes) in enumerate(((19, 5), (20, 9))):
        cv = Canvas(S, S)
        pts = blob(C, C - 3 - i * 2, r, 30 + i)
        hr = random.Random(40 + i)
        for _ in range(holes):
            hx, hy = C + hr.uniform(-r, r) * 0.8, C + hr.uniform(-r, r) * 0.8
            pts -= blob(hx, hy, hr.uniform(3, 6), 50 + _)
        shade_blob(cv, pts, C, C, r, ["gold", "amber", "orange", "brick", "maroon"][i:])
        for j, (sx, sy, sr) in enumerate(((C - 8, C - 15 - i * 3, 6 + i), (C + 6, C - 17 - i * 3, 5 + i),
                                          (C - 1, C - 20 - i * 4, 4 + i))):
            sp = blob(sx, sy, sr, 80 + j + i * 5, 0.2)
            shade_blob(cv, sp, sx, sy, sr, ["steel", "lilac_grey", "slate", "shadow"], mode="dir")
        add_debris(cv, i + 4)
        frames.append(cv)
    # 6-8: fumaça sobe, se dissipa em tufos (luz de cima-esquerda), brasas somem
    for i in range(3):
        cv = Canvas(S, S)
        puffs = [(C - 9 + i, C - 10 - i * 4, 8 - i), (C + 7, C - 13 - i * 4, 7 - i), (C - 1, C - 4 - i * 3, 9 - i * 2),
                 (C + 12, C - 2 - i * 2, 5 - i)]
        for j, (px, py, pr) in enumerate(puffs):
            if pr < 3 or (i == 2 and j == 3):
                continue
            pts = blob(px, py, pr, 60 + j + i * 7, 0.18)
            hr = random.Random(70 + j + i)
            for _ in range(i * 2):                          # tufos se abrindo
                pts -= blob(px + hr.uniform(-pr, pr), py + hr.uniform(-pr, pr), pr * 0.4, 90 + _)
            shade_blob(cv, pts, px, py, pr, ["mist", "steel", "lilac_grey", "slate", "shadow"][min(i, 1):], mode="dir")
        if i == 0:
            for (x, y) in blob(C + 2, C + 6, 3, 99):
                cv.px(x, y, "brick")
            cv.px(C + 1, C + 5, "orange")
        add_debris(cv, 6 + i)
        frames.append(cv)
    return frames


def dust_frames() -> list:
    """Poeira do pouso: duas nuvens de regolito saindo dos pés para os lados, rente ao chão (linha 15)."""
    frames = []
    for i, (dx, r, lift) in enumerate(((5, 2.2, 0), (9, 3.2, 1), (13, 3.8, 2), (17, 3.6, 3), (20, 2.8, 3))):
        cv = Canvas(48, 16)
        for side in (-1, 1):
            cx, cy = 24 + side * dx, 15 - r * 0.7 - lift
            round_pts = blob(cx, cy, r, 5 + i + (side > 0) * 3, 0.25)
            # achatada na horizontal (poeira rente ao chão), cauda mais longa para fora
            pts = {(x, y) for y in range(0, 16) for x in range(48)
                   if (round(cx + (x - cx) / (1.7 if (x - cx) * side > 0 else 1.2)), y) in round_pts}
            if i >= 3:                                       # dissipando: abre buracos
                hr = random.Random(9 + i + side)
                for _ in range(i - 2):
                    pts -= blob(cx + hr.uniform(-r, r), cy + hr.uniform(-r, r), r * 0.45, 30 + _)
            ramp = ["mist", "steel", "lilac_grey"] if i < 3 else ["steel", "lilac_grey", "slate"]
            shade_blob(cv, pts, cx, cy, r, ramp, mode="dir")
            if i < 2:                                        # grãos jogados na frente
                cv.px(round(cx + side * (r + 2)), 14 - i, "steel")
        frames.append(cv)
    return frames


if __name__ == "__main__":
    ex = explosion_frames()
    du = dust_frames()
    for i, f in enumerate(ex):
        w = f.lint(max_colors=16)
        if w:
            print("explosion", i, w)
    anim_ex = Animation("boom", loop=False)
    for f, ms in zip(ex, (40, 50, 60, 60, 70, 90, 110, 130, 150)):
        anim_ex.add(f, ms)
    anim_du = Animation("puff", loop=False)
    for f, ms in zip(du, (60, 70, 80, 100, 120)):
        anim_du.add(f, ms)
    if "--export" in sys.argv:
        save_animations([anim_ex], "assets/sprites/explosion.png", res_path="res://assets/sprites/explosion.png",
                        tres_path="assets/sprites/explosion_frames.tres", preview_dir="art/previews")
        save_animations([anim_du], "assets/sprites/landing_dust.png", res_path="res://assets/sprites/landing_dust.png",
                        tres_path="assets/sprites/landing_dust_frames.tres", preview_dir="art/previews")
    else:
        save_animations([anim_ex], "art/previews/explosion_wip.png", preview_dir="art/previews")
        save_animations([anim_du], "art/previews/landing_dust_wip.png", preview_dir="art/previews")
        # prévia no estilo do jogo: quadros-chave sobre a cena aprovada
        sys.path.insert(0, "art/src/bg"); sys.path.insert(0, "art/src/terrain")
        import moon_scene as ms
        base = ms.ingame_preview(ms.load_layers(), with_lander=False).crop(200, 200, 240, 160)
        sheet = Canvas(240 * 4, 160)
        for k, fi in enumerate((0, 2, 4, 7)):
            c = base.copy()
            c.stamp(ex[fi], 120 - 32 + 20, 80 - 32 + 10)
            sheet.stamp(c, k * 240, 0)
        sheet.preview("art/previews/explosion_scene.png", scale=2, grid=False, show_1x=False)
