"""Terreno da Lua v2 — crosta + corpo rochoso (pedido do usuário 2026-10-02: "o terreno poderia ser mais bonito").

Padrão: .claude/skills/pixel-art/references/patterns/moon-ground.md
Três camadas, de cima para baixo no desenho:
  crust_<face>  faixa CISALHADA ao longo do relevo (UV como as faixas antigas): borda por face (lit/flat/shade),
                regolito com crateras 3/4 e pedrinhas, borda de baixo irregular com lábio de sombra; abaixo = transparente.
                O miolo é igual nas 3 faces (só a borda de 3 px muda) -> sem cortes verticais na troca de face.
  depth         faixa cisalhada transparente no topo que pontilha (bayer) até ink: escurece com a profundidade.
  body          tile 128x128 seamless ALINHADO AO MUNDO (não cisalha): rochas facetadas incrustadas, rachaduras,
                cascalho. Assim as pedras não deformam nas encostas.
Rodar da raiz: python3 art/src/terrain/moon_ground.py [--export]
"""
import math
import random
import sys

sys.path.insert(0, ".claude/skills/pixel-art/scripts")
from pixelart import *

T = 128                      # tile do corpo (seamless nos 2 eixos)
SW, CD, DD = 128, 26, 176    # largura da faixa, profundidade da crosta, profundidade da faixa de escurecimento
BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
RIM = {"lit": ["white", "mist", "steel"], "flat": ["mist", "steel", "steel"],
       "shade": ["steel", "lilac_grey", "lilac_grey"]}


def on(level: float, x: int, y: int) -> bool:
    return level * 16 > BAYER[y % 4][x % 4] + 0.5


def pnoise(x: float, seed: int, period: int, octaves=(1, 2, 5, 11), amp=(1, .6, .35, .2)) -> float:
    r = random.Random(seed)
    ph = [r.random() * 6.2832 for _ in octaves]
    return sum(a * math.sin(6.2832 * o * x / period + p) for o, a, p in zip(octaves, amp, ph)) / sum(amp)


# ------------------------------------------------------------------ corpo (alinhado ao mundo)
def boulder(cv: Canvas, cx: int, cy: int, w: int, h: int, rng: random.Random, dark: bool = False) -> None:
    """Rocha facetada incrustada (sombreamento de gema): contorno irregular de 5-7 vértices e um ápice deslocado
    para cima-esquerda; cada triângulo (ápice, vi, vi+1) é uma face com tom pela direção da luz (cima-esquerda)."""
    n = rng.randint(5, 7)
    off = rng.uniform(0, 6.28)
    verts = []
    for i in range(n):
        a = off + 2 * math.pi * i / n + rng.uniform(-0.3, 0.3)
        r = rng.uniform(0.7, 1.0)
        verts.append((math.cos(a) * w * r, math.sin(a) * h * r))
    ax, ay = -w * rng.uniform(0.15, 0.35), -h * rng.uniform(0.2, 0.45)
    tones = ["shadow", "slate", "lilac_grey", "steel"] if not dark else ["ink", "shadow", "slate", "lilac_grey"]
    def tri(px, py, a, b, c):
        def s(p1, p2, p3):
            return (p1[0] - p3[0]) * (p2[1] - p3[1]) - (p2[0] - p3[0]) * (p1[1] - p3[1])
        d1, d2, d3 = s((px, py), a, b), s((px, py), b, c), s((px, py), c, a)
        return not ((d1 < 0 or d2 < 0 or d3 < 0) and (d1 > 0 or d2 > 0 or d3 > 0))
    cells = {}
    for i in range(n):
        v0, v1 = verts[i], verts[(i + 1) % n]
        mx, my = (v0[0] + v1[0]) / 2 - ax, (v0[1] + v1[1]) / 2 - ay
        ln = math.hypot(mx, my) or 1
        lum = (-mx - my * 1.3) / ln / 1.64            # face virada para cima-esquerda = clara
        t = 3 if lum > 0.45 else 2 if lum > -0.15 else 1 if lum > -0.6 else 0
        for dy in range(-h - 1, h + 2):
            for dx in range(-w - 1, w + 2):
                if (dx, dy) not in cells and tri(dx + 0.5, dy + 0.5, (ax, ay), v0, v1):
                    cells[(dx, dy)] = max(t, 1) if t == 3 and (w < 5) else t
    for (dx, dy), t in cells.items():
        cv.px((cx + dx) % T, (cy + dy) % T, tones[t])
    for (dx, dy), t in cells.items():                 # sombra de contato embaixo e à direita
        for ex, ey in ((0, 1), (1, 1)):
            if (dx + ex, dy + ey) not in cells:
                cv.px((cx + dx + ex) % T, (cy + dy + ey) % T, "ink")


def crack(cv: Canvas, x: int, y: int, ln: int, rng: random.Random) -> None:
    """Rachadura no regolito: zigue-zague 1 px ink, borda de cima clara (luz de cima)."""
    for _ in range(ln):
        cv.px(x % T, y % T, "ink")
        if cv.get(x % T, (y - 1) % T) == resolve("shadow"):
            cv.px(x % T, (y - 1) % T, "slate")
        x += 1
        r = rng.random()
        if r < 0.3:
            y += 1
        elif r < 0.5:
            y -= 1


def body() -> Canvas:
    rng = random.Random(7)
    cv = Canvas(T, T, "shadow")
    reg = {(x, y) for y in range(T) for x in range(T)}
    cv.clusters(reg, "ink", 18, (2, 4), seed=4, wrap=True)
    # rachaduras longas, quase horizontais (estratos quebrados)
    for _ in range(9):
        crack(cv, rng.randrange(T), rng.randrange(T), rng.randint(8, 26), rng)
    # rochas: poucas grandes, várias médias, muitas pequenas; distância mínima -> peso distribuído
    placed = []
    for size, count, dark in (((11, 7), 2, False), ((8, 5), 4, False), ((5, 4), 8, False), ((4, 3), 7, False), ((6, 4), 6, True)):
        for _ in range(count):
            for _try in range(60):
                cx, cy = rng.randrange(T), rng.randrange(T)
                w = size[0] + rng.randint(-1, 2); h = size[1] + rng.randint(-1, 1)
                if all(min(abs(cx - px), T - abs(cx - px)) > w + pw + 2 or
                       min(abs(cy - py), T - abs(cy - py)) > h + ph + 2 for px, py, pw, ph in placed):
                    placed.append((cx, cy, w, h)); boulder(cv, cx, cy, w, h, rng, dark); break
    # cascalho: pontos 2x1 claros com sombra embaixo
    for _ in range(40):
        x, y = rng.randrange(T), rng.randrange(T)
        if cv.get(x, y) == resolve("shadow") and cv.get((x + 1) % T, y) == resolve("shadow"):
            cv.px(x, y, "slate"); cv.px((x + 1) % T, y, "slate"); cv.px(x, (y + 1) % T, "ink")
    return cv


# ------------------------------------------------------------------ crosta (cisalhada)
def crust(face: str) -> Canvas:
    rng = random.Random(41)                          # mesma semente nas 3 faces: só a borda muda
    cv = Canvas(SW, CD)
    bottom = [round(14 + 6 * (pnoise(x, 9, SW) + 1) / 2 + (1 if pnoise(x, 13, SW, (17, 29), (1, .6)) > .5 else 0))
              for x in range(SW)]
    for x in range(SW):
        b = bottom[x]
        for k in range(b):
            if k < 3:
                c = RIM[face][k]
            elif k < 7:
                c = "lilac_grey" if on(1 - (k - 3) / 4 * 0.6, x, k) else "slate"
            else:
                c = "slate" if not on((k - 7) / max(b - 7, 1) * 0.5, x, k) else "lilac_grey" if k < 9 else "slate"
            cv.px(x, k, c)
        cv.px(x, b, "shadow")                        # lábio: a crosta "projeta" sombra no corpo
        if bottom[(x + 1) % SW] > b or rng.random() < 0.3:
            cv.px(x, b + 1, "ink")
    # crateras rasas em 3/4 (elipses largas): borda de cima escura por dentro, borda de baixo iluminada
    for x0, w, cy in ((10, 15, 8), (58, 7, 6), (93, 11, 7)):
        rng.random(); ry = 2 if w < 12 else 3
        rx = w / 2
        for dx in range(w):
            for dy in range(-ry, ry + 1):
                ex = (dx + 0.5 - rx) / rx; ey = dy / (ry + 0.5)
                d = ex * ex + ey * ey
                if d > 1:
                    continue
                x, y = (x0 + dx) % SW, cy + dy
                if d > 0.55 and ey > 0.2:
                    c = "mist" if ex < 0.2 else "steel"     # borda de baixo pega a luz
                elif d > 0.55 and ey < -0.1:
                    c = "shadow"                            # parede de cima em sombra
                else:
                    c = "slate" if ex > -0.2 else "shadow"  # fundo da bacia
                cv.px(x, y, c)
    # pedrinhas sobre o regolito (2-3 px, topo claro)
    for _ in range(14):
        x, k = rng.randrange(SW), rng.randint(4, 12)
        if cv.get(x, k) in (resolve("slate"), resolve("lilac_grey")):
            cv.px(x, k, "mist"); cv.px((x + 1) % SW, k, "steel"); cv.px(x, k + 1, "shadow"); cv.px((x + 1) % SW, k + 1, "shadow")
    return cv


def depth() -> Canvas:
    """Escurecimento com a profundidade: transparente até k=34, pontilha ink até sólido em k=130."""
    cv = Canvas(SW, DD)
    for x in range(SW):
        for k in range(DD):
            lvl = (k - 34) / 96
            if lvl > 0 and on(min(lvl, 1.0), x, k):
                cv.px(x, k, "ink")
    return cv


def compose(cv: Canvas, ridge_y, x0: int, x1: int, faces_at, L: dict) -> None:
    """Pinta o chão como o Godot fará: corpo no mundo; faixa de escurecimento e crosta cisalhadas."""
    deep = resolve("ink")
    for x in range(x0, x1):
        r = ridge_y(x)
        f = faces_at(x)
        for y in range(max(r, 0), cv.h):
            k = y - r
            cr = L["crust_" + f]
            c = cr.get(x % SW, k) if k < cr.h else None
            if c is None:
                c = L["depth"].get(x % SW, k) if k < DD else deep
            if c is None:
                c = L["body"].get(x % T, y % T)
            cv.px(x, y, c)


def build() -> dict:
    return {"body": body(), "depth": depth(), **{"crust_" + f: crust(f) for f in RIM}}


def export(L: dict) -> None:
    L["body"].save("assets/tiles/luna_body.png", tiled=True)
    L["depth"].save("assets/tiles/luna_depth.png")
    for f in RIM:
        L["crust_" + f].save(f"assets/tiles/luna_crust_{f}.png")


if __name__ == "__main__":
    L = build()
    for k, c in L.items():
        print(k, c.lint(wrap=(k == "body")))
    L["body"].save("art/previews/moon_body.png", tiled=True)
    for f in RIM:
        L["crust_" + f].save(f"art/previews/moon_crust_{f}.png")
    if "--export" in sys.argv:
        export(L)


# ================================================================== PROPOSTAS ALTERNATIVAS (2026-10-02)
# O usuário pediu outra proposta: B = estratos, C = planalto de crateras, D = blocos de basalto.
# Todas mantêm o contrato de camadas (crust_<face> cisalhada, depth cisalhada, body no mundo).

def crust_strata(face: str) -> Canvas:
    """B — Estratos: camadas de rocha seguindo o relevo, espessuras variáveis, topo de cada camada claro."""
    depth_px = 140
    cv = Canvas(SW, depth_px)
    rng = random.Random(77)
    # limites entre camadas: profundidade base + ondulação periódica em SW
    bounds, k = [], 3
    i = 0
    while k < depth_px:
        k += rng.randint(5, 16)
        bounds.append((k, rng.randint(0, 999), rng.uniform(1.5, 4)))
        i += 1
    tones = ["lilac_grey", "slate", "slate", "shadow", "slate", "shadow", "shadow", "ink"]
    for x in range(SW):
        ys = [round(b + a * pnoise(x, s, SW, (1, 2, 4), (1, .5, .3))) for b, s, a in bounds]
        layer = 0
        for kk in range(depth_px):
            if kk < 3:
                cv.px(x, kk, RIM[face][kk]); continue
            while layer < len(ys) and kk >= ys[layer]:
                layer += 1
            base = tones[min(layer, len(tones) - 1)] if layer % 3 != 2 else shift_name(tones[min(layer, len(tones) - 1)], -1)
            top = layer > 0 and kk == ys[layer - 1]
            bot = layer < len(ys) and kk == ys[layer] - 1
            c = shift_name(base, 1) if top and layer < 6 else "ink" if bot else base
            cv.px(x, kk, c)
    # seixos dentro das camadas (achatados, seguem o estrato)
    for _ in range(26):
        x, kk = rng.randrange(SW), rng.randint(8, 90)
        w = rng.randint(3, 7)
        for dx in range(w):
            cv.px((x + dx) % SW, kk, "steel" if dx < w // 2 else "lilac_grey")
            cv.px((x + dx) % SW, kk + 1, "slate" if 0 < dx < w - 1 else "shadow")
            cv.px((x + dx) % SW, kk + 2, "ink") if 0 < dx < w - 1 else None
    return cv


GREY = ["ink", "shadow", "slate", "lilac_grey", "steel", "mist", "white"]


def shift_name(c: str, n: int) -> str:
    return GREY[max(0, min(len(GREY) - 1, GREY.index(c) + n))] if c in GREY else c


def crust_plateau(face: str) -> Canvas:
    """C — Planalto de crateras: faixa larga do chão visto de leve por cima, cheia de crateras em perspectiva,
    terminando num degrau claro; abaixo, corpo quase preto (contraste forte)."""
    rng = random.Random(91)
    D = 40
    cv = Canvas(SW, D + 4)
    bottom = [round(30 + 5 * (pnoise(x, 5, SW) + 1) / 2) for x in range(SW)]
    for x in range(SW):
        b = bottom[x]
        for k in range(b):
            if k < 3:
                c = RIM[face][k]
            else:
                f = (k - 3) / (b - 3)
                c = "steel" if f < 0.15 and on(1 - f / 0.15, x, k) else "lilac_grey" if f < 0.55 else \
                    ("lilac_grey" if on(1 - (f - 0.55) / 0.45, x, k) else "slate")
            cv.px(x, k, c)
        cv.px(x, b, "steel"); cv.px(x, b + 1, "slate")       # degrau: quina clara da placa
        cv.px(x, b + 2, "shadow"); cv.px(x, b + 3, "ink")
    craters = [(4, 21, 9, 3), (30, 9, 6, 2), (44, 15, 13, 4), (70, 7, 7, 2), (80, 22, 10, 3), (101, 12, 15, 4),
               (60, 26, 5, 2), (118, 25, 6, 2)]
    for x0, cy, w, ry in craters:
        rx = w / 2
        for dx in range(w):
            for dy in range(-ry, ry + 1):
                ex, ey = (dx + 0.5 - rx) / rx, dy / (ry + 0.5)
                d = ex * ex + ey * ey
                if d > 1:
                    continue
                if d > 0.5 and ey > 0.15:
                    c = "white" if ex < 0 and ey > 0.6 else "mist"
                elif d > 0.45 and ey < 0:
                    c = "ink" if ey < -0.5 else "shadow"
                else:
                    c = "shadow" if ex > 0.1 else "slate"
                cv.px((x0 + dx) % SW, cy + dy, c)
        # ejeção: anel claro sutil em volta
        for dx in range(-2, w + 2):
            yy = cy + ry + 1
            if rng.random() < 0.5 and cv.get((x0 + dx) % SW, yy) not in (None, resolve("steel")):
                cv.px((x0 + dx) % SW, yy, "steel")
    return cv


def body_dark() -> Canvas:
    rng = random.Random(5)
    cv = Canvas(T, T, "ink")
    reg = {(x, y) for y in range(T) for x in range(T)}
    cv.clusters(reg, "shadow", 30, (2, 6), seed=8, wrap=True)
    for _ in range(14):
        x, y = rng.randrange(T), rng.randrange(T)
        w = rng.randint(2, 5)
        for dx in range(w):
            cv.px((x + dx) % T, y, "slate" if dx < w - 1 else "shadow")
            cv.px((x + dx) % T, (y + 1) % T, "shadow")
    return cv


def body_basalt() -> Canvas:
    """D — Blocos de basalto: Voronoi seamless (blocos angulosos encaixados), aresta de cima-esquerda clara,
    junta escura embaixo-direita, tom do bloco variando."""
    rng = random.Random(13)
    seeds = [(rng.uniform(0, T), rng.uniform(0, T)) for _ in range(46)]
    tone = [rng.choice(["slate", "slate", "shadow", "shadow", "slate"]) for _ in seeds]
    def cell(x, y):
        best, bi = 1e9, 0
        for i, (sx, sy) in enumerate(seeds):
            dx = min(abs(x - sx), T - abs(x - sx)); dy = min(abs(y - sy), T - abs(y - sy)) * 1.5   # blocos mais largos
            d = max(dx, dy) * 0.6 + (dx + dy) * 0.4      # métrica angulosa
            if d < best:
                best, bi = d, i
        return bi
    facet = [rng.uniform(-6, -2) for _ in seeds]
    grid = [[cell(x, y) for x in range(T)] for y in range(T)]
    cv = Canvas(T, T)
    for y in range(T):
        for x in range(T):
            i = grid[y][x]
            c = tone[i]
            if grid[(y + 1) % T][x] != i or grid[y][(x + 1) % T] != i:
                c = "ink"
            elif grid[(y - 1) % T][x] != i or grid[y][(x - 1) % T] != i:
                c = shift_name(c, 1)
            elif grid[(y + 2) % T][x] != i or grid[y][(x + 2) % T] != i:
                c = shift_name(c, -1)
            else:
                sx, sy = seeds[i]
                rx = (x - sx + T / 2) % T - T / 2; ry = (y - sy + T / 2) % T - T / 2
                if rx * 0.8 + ry * 1.3 < facet[i]:          # faceta de cima-esquerda pega luz
                    c = shift_name(c, 1)
                elif (x * 7 + y * 13 + i) % 23 == 0:        # poros do basalto
                    c = shift_name(c, -1)
            cv.px(x, y, c)
    return cv


def thin_crust(face: str) -> Canvas:
    cv = crust(face)
    return cv


def depth_from(start: int) -> Canvas:
    cv = Canvas(SW, DD)
    for x in range(SW):
        for k in range(DD):
            lvl = (k - start) / 96
            if lvl > 0 and on(min(lvl, 1.0), x, k):
                cv.px(x, k, "ink")
    return cv


VARIANTS = {
    "A": lambda: build(),
    "B": lambda: {"body": body_dark(), "depth": depth_from(60), **{"crust_" + f: crust_strata(f) for f in RIM}},
    "C": lambda: {"body": body_dark(), "depth": depth_from(70), **{"crust_" + f: crust_plateau(f) for f in RIM}},
    "D": lambda: {"body": body_basalt(), "depth": depth_from(64), **{"crust_" + f: thin_crust(f) for f in RIM}},
}
