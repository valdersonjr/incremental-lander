"""Lua em guerra — narrativa de fundo (pedido do usuário 2026-10-02: "uma guerra alienígena acontecendo").

Padrão: .claude/skills/pixel-art/references/patterns/moon-war.md
Humanos (ciano/âmbar) defendem bases nas montanhas contra discos voadores (verde-ácido) e uma nave-mãe.
Partes ASSADAS nas camadas existentes (animadas por quadros empilhados, como o céu):
  sky   + nave-mãe (luzes piscando, núcleo pulsando)
  mid   + bases humanas no topo das montanhas (cúpulas, torres, antena), uma base em chamas com fumaça
  plain + disco abatido semienterrado, fumegando
Partes DINÂMICAS (o Godot desenha; contrato em luna_layers.json > "war"): discos voadores cruzando o céu,
lasers verdes descendo nas bases, traçantes âmbar subindo das torres, clarões de explosão.
Sprites: assets/sprites/war_saucer.png (24x10, 4 quadros), war_saucer_far.png (12x6, 2), war_blast.png (16x16, 6).
Rodar da raiz: python3 art/src/bg/moon_war.py  -> prévias em art/previews/moon_war*.png
"""
import math
import random
import sys

sys.path.insert(0, ".claude/skills/pixel-art/scripts")
from pixelart import *

W, H = 640, 360
FR = 4                         # quadros das camadas assadas (mid/plain); céu continua com 6
LAYER_MS = 140
# contrato com o Godot (game/background/war_fx.gd): coordenadas da camada mid (640 de laço)
WAR_META = {
    "saucers": 3, "sky_band": [70, 175], "speed": [10, 26],
    "laser": ["lime", "sprout", "green"], "tracer": ["gold", "amber"], "smoke": ["shadow", "ink"],
    "sprites": {"saucer": "res://assets/sprites/war_saucer.png", "saucer_far": "res://assets/sprites/war_saucer_far.png",
                "blast": "res://assets/sprites/war_blast.png"},
    "frames": {"saucer": [24, 10, 4, 110], "saucer_far": [12, 6, 2, 220], "blast": [16, 16, 6, 70]},
}
BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
ALIEN = {"deep": "pine", "base": "green", "glow": "leaf", "hot": "lime", "core": "sprout"}
HUMAN = {"win": "aqua", "win2": "sea", "tracer": "gold", "tracer2": "amber"}


def on(level, x, y):
    return level * 16 > BAYER[y % 4][x % 4] + 0.5


def war_meta() -> dict:
    """WAR_META com as cores trocadas por hex (o Godot lê Color("#rrggbb"))."""
    def hx(n):
        c = Canvas(1, 1); c.px(0, 0, n)
        r, g, b, _ = c.to_image().getpixel((0, 0))
        return "#%02x%02x%02x" % (r, g, b)
    return {**WAR_META, "laser": [hx(c) for c in WAR_META["laser"]], "tracer": [hx(c) for c in WAR_META["tracer"]],
            "smoke": [hx(c) for c in WAR_META["smoke"]]}


# ------------------------------------------------------------------ sprites dinâmicos
def saucer(fr: int) -> Canvas:
    """Disco voador 24x10, vista lateral com leve 3/4: cúpula verde, disco metálico, luzes da borda correndo."""
    cv = Canvas(24, 10)
    # cúpula (meia elipse) — vidro verde com brilho em cima-esquerda
    for y in range(0, 5):
        for x in range(24):
            dx, dy = (x + 0.5 - 12) / 5, (y + 0.5 - 5) / 4.6
            if dx * dx + dy * dy <= 1:
                c = ALIEN["glow"]
                if dx > 0.35 or dy > 0.55:
                    c = ALIEN["base"]
                if dx > 0.7:
                    c = ALIEN["deep"]
                cv.px(x, y, c)
    cv.px(9, 1, "white"); cv.px(10, 1, ALIEN["core"]); cv.px(9, 2, ALIEN["core"])
    # disco
    for y in range(4, 9):
        for x in range(24):
            dx, dy = (x + 0.5 - 12) / 12, (y + 0.5 - 6.3) / 2.4
            if dx * dx + dy * dy <= 1:
                c = "mist" if y == 4 or (y == 5 and dx < 0.2) else "steel" if y == 5 else "lilac_grey" if y == 6 else "slate"
                if y >= 7:
                    c = "shadow" if abs(dx) > 0.45 else "slate"
                cv.px(x, y, c)
    cv.px(3, 5, "steel"); cv.px(4, 4, "mist")
    # luzes da borda (y=6): uma "onda" que corre para a direita
    for i, x in enumerate(range(2, 23, 3)):
        lit = (i + fr) % 4 == 0
        cv.px(x, 6, ALIEN["hot"] if lit else ALIEN["deep"])
    # brilho de baixo (motor antigravidade)
    for x in range(9, 15):
        cv.px(x, 9, ALIEN["glow"] if (x + fr) % 2 else ALIEN["base"])
    return cv


def saucer_far(fr: int) -> Canvas:
    cv = Canvas(12, 6)
    cv.paint(["....gGG.....",
              "...gGGGG....",
              ".mmssssssll.",
              "lsssssssssll",
              "..ddddddddd.",
              "....kkkk...."],
             {"g": ALIEN["glow"], "G": ALIEN["base"], "m": "mist", "s": "steel", "l": "lilac_grey",
              "d": "slate", "k": ALIEN["glow"] if fr % 2 else ALIEN["base"]})
    return cv


def blast(fr: int) -> Canvas:
    """Clarão de explosão distante 16x16: flash branco -> bola dourada -> anel laranja -> fumaça."""
    cv = Canvas(16, 16)
    rng = random.Random(fr * 7 + 3)
    r = [2, 4, 6, 6, 6, 5][fr]
    for y in range(16):
        for x in range(16):
            d = math.hypot(x + 0.5 - 8, y + 0.5 - 8)
            n = rng.random() * 0.9
            if d > r + n:
                continue
            if fr == 0:
                c = "white"
            elif fr == 1:
                c = "white" if d < 2 else "lemon" if d < 3 else "gold"
            elif fr == 2:
                c = "gold" if d < 2.5 else "amber" if d < 4.5 else "orange"
            elif fr == 3:
                c = "amber" if d < 2 else "orange" if d < 3.5 else "rust" if d < 5 else "slate"
                if d < 5 and on(0.3, x, y):
                    c = "slate"
            elif fr == 4:
                c = "rust" if d < 2 else "slate" if on(0.6, x, y) else "shadow"
            else:
                if not on(0.5, x, y):
                    continue
                c = "shadow" if d > 2 else "slate"
            cv.px(x, y, c)
    if fr in (1, 2):                                   # estilhaços em cruz
        for dx, dy in ((7, 0), (-7, 0), (0, -7), (5, -5), (-5, -5), (5, 5)):
            if fr == 2:
                dx, dy = int(dx * 1.1), int(dy * 1.1)
            x, y = 8 + dx, 8 + dy
            if 0 <= x < 16 and 0 <= y < 16:
                cv.px(x, y, "gold")
    return cv


# ------------------------------------------------------------------ nave-mãe (no céu)
MOTHER = (196, 14, 212, 62)    # x, y, w, h


def mothership(cv: Canvas, fr: int) -> None:
    """Disco colossal (longe e contra a luz): cúpula com superestrutura, casco escuro com borda de cima clara,
    cinturão de janelas verdes em onda, barriga com anel de luzes e núcleo-arma pulsando."""
    x0, y0, w, h = MOTHER
    cx = x0 + w / 2
    belt = y0 + int(h * 0.55)
    def top_y(dx):            # perfil de cima: casco baixo + cúpula central
        hull = belt - 3 - 9 * (1 - dx * dx) ** 1.4
        domey = belt - 9 - 16 * max(0.0, 1 - (dx / 0.32) ** 2) ** 0.5
        return min(hull, domey)
    def bot_y(dx):
        return belt + 2 + 14 * (1 - dx * dx) ** 1.1
    for x in range(x0, x0 + w):
        dx = (x + 0.5 - cx) / (w / 2)
        if abs(dx) >= 1:
            continue
        t, b = top_y(dx), bot_y(dx)
        for y in range(int(t), int(b) + 1):
            if y + 0.5 < t:
                continue
            if y < t + 1:
                c = "lilac_grey" if dx < 0.15 else "slate"
            elif y < belt - 1:
                inside_dome = abs(dx) < 0.32 and y < belt - 9
                c = ("slate" if dx < -0.12 and on(0.5, x, y) else "shadow") if inside_dome else \
                    ("slate" if dx < -0.4 and on(0.35, x, y) else "shadow")
            elif y <= belt + 1:
                c = "charcoal" if y == belt - 1 else "slate" if y == belt else "ink"
            else:
                f = (y - belt) / max(b - belt, 1)
                c = "shadow" if not on(max(0, f - 0.5) * 1.6, x, y) else "charcoal"
                if y >= int(b) - 0 or (dx < -0.55 and y >= int(b) - 1):
                    c = "slate"                              # borda de baixo: reflexo do chão claro da Lua
            cv.px(x, y, c)
    # placas verticais no casco e anéis na cúpula
    for px in range(x0 + 10, x0 + w - 8, 11):
        dx = (px + 0.5 - cx) / (w / 2)
        for y in range(int(top_y(dx)) + 2, belt - 1):
            if cv.get(px, y) == resolve("shadow"):
                cv.px(px, y, "ink")
    for ry in (belt - 14, belt - 19):
        for x in range(x0, x0 + w):
            if cv.get(x, ry) == resolve("shadow"):
                cv.px(x, ry, "ink")
    # antenas na cúpula
    for ax, ah in ((cx - 10, 7), (cx + 6, 11), (cx + 14, 5)):
        ty = int(top_y((ax + 0.5 - cx) / (w / 2)))
        cv.vline(int(ax), ty - ah, ty, "slate")
    cv.px(int(cx + 6), int(top_y(6 / (w / 2))) - 12, "red" if fr % 2 == 0 else "maroon")
    # janelas no cinturão
    for i, px in enumerate(range(x0 + 12, x0 + w - 10, 4)):
        lit = (i + fr * 2) % 9 in (0, 1, 2)
        cv.px(px, belt, ALIEN["hot"] if lit else ALIEN["base"])
    # anel de luzes na barriga
    for i, px in enumerate(range(int(cx - 70), int(cx + 71), 10)):
        dx = (px + 0.5 - cx) / (w / 2)
        py = int(belt + 2 + 12 * (1 - dx * dx) ** 1.3 * 0.55)
        c = ALIEN["glow"] if (i + fr) % 3 else ALIEN["core"]
        cv.px(px, py, c); cv.px(px + 1, py, ALIEN["base"])
    # núcleo-arma pulsando
    pulse = [0, 1, 2, 3, 2, 1][fr % 6]
    by = int(bot_y(0)) - 2
    for dy in range(-2, 4):
        for dx in range(-8, 9):
            d = math.hypot(dx / (4 + pulse), dy / (2 + pulse * 0.5))
            if d <= 1:
                c = "white" if d < 0.3 else ALIEN["core"] if d < 0.55 else ALIEN["hot"] if d < 0.8 else ALIEN["glow"]
                cv.px(int(cx) + dx, by + dy, c)


# ------------------------------------------------------------------ bases humanas (nas montanhas do meio)
def top_of(cv: Canvas, x: int) -> int:
    return next(y for y in range(cv.h) if cv.get(x, y) is not None)


def dome(cv: Canvas, cx: int, base: int, r: int, fr: int, ruined: bool = False) -> None:
    for y in range(base - r, base + 1):
        for x in range(cx - r, cx + r + 1):
            dx, dy = (x + 0.5 - cx - 0.5) / (r + 0.5), (y + 0.5 - base) / (r * 0.8 + 0.5)
            if dx * dx + dy * dy > 1:
                continue
            if ruined and y < base - r * 0.35 and (x * 5 + y * 3) % 7 < 4:
                continue                                   # topo arrebentado
            c = "mist" if dx < -0.2 and dy < -0.4 else "steel" if dx < 0.3 else "lilac_grey"
            if dx > 0.65:
                c = "slate"
            cv.px(x, y, c)
    if not ruined:
        for i, x in enumerate(range(cx - r + 2, cx + r, 3)):         # janelas
            cv.px(x, base - 1, HUMAN["win"] if (i + fr) % 5 else HUMAN["win2"])
    for x in range(cx - r - 1, cx + r + 2):                           # base/fundação
        cv.px(x, base + 1, "shadow")


def turret(cv: Canvas, x: int, base: int, left: bool) -> tuple:
    cv.rect(x - 2, base - 3, 5, 4, "slate"); cv.hline(x - 2, x + 2, base - 3, "steel")
    cv.px(x - 1, base - 2, HUMAN["win"])
    d = -1 if left else 1
    for i in range(1, 5):                                              # cano apontado para o céu
        cv.px(x + d * i, base - 3 - i, "lilac_grey")
    return (x + d * 5, base - 8)                                       # boca do cano (origem dos traçantes)


def tower(cv: Canvas, x: int, base: int, fr: int) -> None:
    """Torre de comando saindo da cúpula: bloco com janelas ciano e luz vermelha no topo."""
    cv.rect(x - 2, base - 8, 5, 9, "steel"); cv.vline(x + 2, base - 8, base, "lilac_grey")
    cv.hline(x - 2, x + 2, base - 8, "mist")
    for yy in (base - 6, base - 3):
        cv.px(x - 1, yy, HUMAN["win"]); cv.px(x + 1, yy, HUMAN["win2"] if fr % 3 else HUMAN["win"])
    cv.vline(x, base - 12, base - 9, "lilac_grey")
    cv.px(x, base - 13, "red" if fr % 2 else "maroon")


def antenna(cv: Canvas, x: int, base: int, fr: int) -> None:
    cv.vline(x, base - 10, base, "lilac_grey")
    cv.hline(x - 2, x + 2, base - 7, "slate")
    cv.px(x, base - 11, "red" if fr % 2 == 0 else "maroon")


def fire(cv: Canvas, cx: int, base: int, fr: int, seed: int) -> None:
    """Incêndio: línguas de fogo tremulando + coluna de fumaça ESCURA (lê sobre montanha clara e céu)."""
    rng = random.Random(seed * 31 + fr)
    # fumaça primeiro (fica atrás das chamas): puffs que sobem e derivam, quadro a quadro
    for j in range(9):
        t = j * 5 + fr * 5 / FR
        y = base - 4 - t * 1.25
        x = cx + t * 0.45 + math.sin(j * 1.7) * 1.2
        rr = 2.2 + t * 0.09
        for yy in range(int(y - rr) - 1, int(y + rr) + 2):
            for xx in range(int(x - rr * 1.3) - 1, int(x + rr * 1.3) + 2):
                d = math.hypot((xx + 0.5 - x) / 1.3, yy + 0.5 - y)
                if d > rr or not cv.inside(xx, yy):
                    continue
                if t > 30 and not on(max(0.15, 1 - (t - 30) / 20), xx, yy):
                    continue                                   # topo da coluna se desfaz
                rim = (xx + 0.5 - x) + (yy + 0.5 - y) < -rr * 0.6
                cv.px(xx, yy, "slate" if rim else "shadow" if d > rr * 0.55 else "ink")
    for i in range(12):
        x = cx + rng.randint(-4, 4)
        hgt = rng.randint(2, 7) - abs(x - cx) // 2
        for k in range(max(hgt, 1)):
            c = "white" if k == 0 and abs(x - cx) < 2 else "gold" if k < 2 else "amber" if k < 4 else "orange" if k < hgt - 1 else "red"
            cv.px(x, base - k, c)


BASES = [  # (x no laço de 640, tipo)
    (82, "dome"), (238, "ruin"), (372, "dome"), (520, "dome"),
]


def war_mid(mid: Canvas, fr: int) -> tuple:
    cv = mid.copy()
    muzzles, targets = [], []
    for i, (x, kind) in enumerate(BASES):
        b = max(top_of(mid, xx) for xx in range(x - 6, x + 7)) + 1      # assenta na encosta
        if kind == "ruin":
            dome(cv, x, b, 8, fr, ruined=True)
            fire(cv, x, b - 2, fr, i)
            targets.append((x, b - 4))
            continue
        dome(cv, x, b, 8, fr)
        tower(cv, x - 4, b - 6, fr + i)
        muzzles.append(turret(cv, x + 10, max(top_of(mid, xx) for xx in range(x + 8, x + 13)) + 1, left=i % 2 == 0))
        antenna(cv, x - 9, max(top_of(mid, xx) for xx in range(x - 10, x - 7)) + 1, fr + i)
        targets.append((x, b - 6))
    return cv, muzzles, targets


# ------------------------------------------------------------------ disco abatido (na planície)
WRECK = (440, 18)    # x, y (base) na camada plain


def wreck(cv: Canvas, fr: int) -> None:
    """Disco abatido semienterrado (escala 1.5x, inclinado ~20 graus): cratera, poeira, luz morrendo, fogo e fumaça."""
    x0, y0 = WRECK
    s = saucer(0)
    for x in range(36):
        for y in range(15):
            c = s.get(int(x / 1.5), int(y / 1.5))
            yy = y0 - 12 + y + x // 4
            if c is None or yy > y0:
                continue
            if c in (resolve(ALIEN["glow"]), resolve(ALIEN["hot"]), resolve(ALIEN["base"])):
                c = resolve("slate") if (x + y) % 3 else resolve(ALIEN["deep"])
            cv.px(x0 + x, yy, c)
    for x in range(x0 - 8, x0 + 44):                                  # borda da cratera (monte de regolito)
        hump = int(2.5 * math.sin(math.pi * (x - x0 + 8) / 52))
        for k in range(hump + 1):
            cv.px(x, y0 - k, "lilac_grey" if k == hump else "slate")
    for dx in (-5, 3, 12, 30, 40):                                    # destroços espalhados
        cv.px(x0 + dx, y0 + 2, "steel"); cv.px(x0 + dx + 1, y0 + 2, "slate")
    cv.px(x0 + 12, y0 - 7, ALIEN["hot"] if fr % 2 else ALIEN["deep"])
    fire(cv, x0 + 22, y0 - 4, fr, 9)


# ------------------------------------------------------------------ composição / prévia
def layers():
    import moon_scene as ms
    L = ms.load_layers()
    return ms, L


def dynamic(cv: Canvas, t: float, muzzles, targets, seed: int = 1) -> None:
    """Simulação do que o Godot fará (para a prévia): discos cruzando, lasers e traçantes, clarões."""
    rng = random.Random(seed)
    craft = [(0.0, 120, 26, 1), (0.35, 150, 18, -1), (0.6, 96, 30, 1)]
    for i, (ph, y, spd, d) in enumerate(craft):
        x = ((ph * W + t * spd * d) % (W + 60)) - 30
        yy = y + 4 * math.sin(t * 2 + i)
        far = i == 2
        spr = saucer_far(int(t * 4)) if far else saucer(int(t * 8) % 4)
        cv.stamp(spr, int(x), int(yy))
        if not far and int(t * 3 + i) % 3 == 0:                       # laser verde até uma base
            tx, ty = targets[i % len(targets)]
            sx, sy = int(x) + 12, int(yy) + 10
            for k, (px, py) in enumerate(Canvas.line_points(sx, sy, tx, ty) if hasattr(Canvas, "line_points") else []):
                cv.px(px, py, ALIEN["hot"] if k % 5 else ALIEN["core"])
                if cv.inside(px + 1, py):
                    cv.px(px + 1, py, ALIEN["base"])
            cv.stamp(blast(1), tx - 8, ty - 8)
    for j, (mx, my) in enumerate(muzzles):                            # traçantes âmbar em rajada
        for b in range(3):
            prog = ((t * 1.7 + j * 0.37 + b * 0.12) % 1.0)
            ln = 130
            ex = mx + int((-1 if j % 2 == 0 else 1) * prog * ln * 0.55)
            ey = my - int(prog * ln)
            for k in range(5):
                px, py = ex - (-1 if j % 2 == 0 else 1) * (k // 2), ey + k
                cv.px(px, py, HUMAN["tracer"] if k == 0 else HUMAN["tracer2"])
    cv.stamp(blast(int(t * 6) % 6), 200, 104)                          # flak no céu


def compose(t: float, fr: int):
    """Prévia a partir dos ASSETS exportados (como o Godot): camadas assadas no quadro fr + dinâmica simulada."""
    import json
    ms, L = layers()
    meta = json.load(open("assets/bg/luna_layers.json"))["war"]
    def frame(path, h, n):
        c = Canvas.from_image(path)
        return c.crop(0, (fr % n) * h, W, h)
    cv = Canvas(W, H)
    cv.stamp(frame("assets/bg/luna_sky.png", H, ms.SKY_FRAMES))
    cv.stamp(L["planet"], ms.PLANET[0] - ms.PLANET[2] - 12, ms.PLANET[1] - ms.PLANET[2] - 12)
    cv.stamp(L["far"])
    cv.stamp(frame("assets/bg/luna_mid.png", ms.MID_BASE + 1, FR))
    dynamic(cv, t, [tuple(m) for m in meta["muzzles"]], [tuple(m) for m in meta["targets"]])
    cv.stamp(frame("assets/bg/luna_plain.png", H + 160 - ms.PLAIN_TOP, FR), 0, ms.PLAIN_TOP)
    full = ms.ingame_preview(L, with_lander=True)
    from moon import profile, ridge_y
    pts = profile(W, seed=7, base=292, amp=60, pad=(300, 64))
    for x in range(W):
        for y in range(ridge_y(pts, x) - 28, H):
            if y >= ridge_y(pts, x) or y >= 292 - 30:
                c = full.get(x, y)
                if y >= ridge_y(pts, x):
                    cv.px(x, y, c)
    lander = Canvas.from_image("assets/sprites/lander.png").crop(0, 0, 32, 32)
    cv.stamp(lander, 300 + 32 - 16, ridge_y(pts, 332) - 25)
    return cv


def export_sprites() -> None:
    for name, fn, n in (("war_saucer", saucer, 4), ("war_saucer_far", saucer_far, 2), ("war_blast", blast, 6)):
        frames = [fn(i) for i in range(n)]
        sheet = Canvas(frames[0].w * n, frames[0].h)
        for i, f in enumerate(frames):
            sheet.stamp(f, i * f.w, 0)
        sheet.save(f"assets/sprites/{name}.png")


if __name__ == "__main__":
    sys.path.insert(0, "art/src/terrain"); sys.path.insert(0, "art/src/bg")
    export_sprites()
    shots = [compose(t, i) for i, t in enumerate((0.0, 0.7, 1.4, 2.1))]
    shots[0].save("art/previews/moon_war.png", preview=False)
    shots[0].preview("art/previews/moon_war_2x.png", scale=2, grid=False, show_1x=False)
    sheet = Canvas(W * 2, H * 2)
    for i, s in enumerate(shots):
        sheet.stamp(s, (i % 2) * W, (i // 2) * H)
    sheet.save("art/previews/moon_war_sheet.png", preview=False)
