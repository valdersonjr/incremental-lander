"""Terreno da Lua (padrão: .claude/skills/pixel-art/references/patterns/moon-terrain.md).

Duas peças para o terreno em polígono (terrain-tiles.md §7):
  fill    64x64  textura seamless do corpo do polígono (Polygon2D, texture_repeat, UV = coordenada do mundo)
  surface 64x16  faixa da superfície, aplicada coluna a coluna logo abaixo do contorno (cisalhada, não girada:
                 cada coluna x recebe a coluna x%64 da faixa a partir da altura do relevo -> pixel-perfect em encostas)
Luz de cima (tiles), rampa neutral, estilo futurista limpo (clusters gordinhos, sem sujeira).
Rodar da raiz: python3 art/src/terrain/moon.py  -> prévias em art/previews/ (export só após aprovação).
"""
import math
import random
import sys

sys.path.insert(0, ".claude/skills/pixel-art/scripts")
from pixelart import *

FW = FH = 64
SW, SH = 64, 16


def _lens(cv: Canvas, cx: int, cy: int, length: int, thick: int, color) -> set:
    """Estrato horizontal em forma de lente (pontas afinam), com wrap. Retorna os pixels pintados."""
    pts = set()
    half = length / 2
    for i in range(length):
        t = abs((i - half + 0.5) / half)            # 0 no meio, 1 nas pontas
        h = max(1, round(thick * (1 - t * t)))
        top = cy - h // 2
        for j in range(h):
            p = ((cx - int(half) + i) % cv.w, (top + j) % cv.h)
            cv.px(*p, color)
            pts.add(p)
    return pts


def _rock(cv: Canvas, cx: int, cy: int, rx: int, ry: int, rng: random.Random) -> set:
    """Rocha em bloco irregular (elipse achatada com contorno 'mordido'), com wrap."""
    pts = set()
    # assimetria e inclinação por rocha (senão todas viram o mesmo "losango" repetido)
    left, right = rng.uniform(0.6, 1.25), rng.uniform(0.6, 1.25)
    tilt = rng.choice([-1, 0, 0, 1])
    for dy in range(-ry, ry + 1):
        k = 1 - (dy / (ry + 0.5)) ** 2
        w = math.sqrt(max(k, 0)) * (0.75 if dy < 0 else 1.0)       # topo mais estreito: rocha assentada
        shift = (tilt * (dy + ry)) // 2
        for dx in range(-round(rx * left * w), round(rx * right * w) + 1):
            p = ((cx + dx + shift) % cv.w, (cy + dy) % cv.h)
            pts.add(p)
    for p in pts:
        cv.px(*p, "slate")
    return pts


def _free(cv: Canvas, cx: int, cy: int, rx: int, ry: int) -> bool:
    return all(cv.get(cx + dx, cy + dy, wrap=True) == resolve("shadow")
               for dx in range(-rx - 2, rx + 3) for dy in range(-ry - 2, ry + 3))


def fill_tex(seed: int = 3) -> Canvas:
    """Rochas gordinhas de tamanhos variados (grande/médio/pequeno), sem fileiras; luz de cima."""
    rng = random.Random(seed)
    cv = Canvas(FW, FH, "shadow")
    rocks = []
    for rx, ry, n in ((8, 3, 3), (5, 2, 4), (3, 1, 5)):
        tries = 0
        while n and tries < 400:
            tries += 1
            cx, cy = rng.randrange(FW), rng.randrange(FH)
            if _free(cv, cx, cy, rx, ry):
                rocks.append(_rock(cv, cx, cy, rx + rng.randint(0, 2), ry, rng))
                n -= 1
    shadow = resolve("shadow")
    for pts in rocks:
        cols = sorted({p[0] for p in pts}, key=lambda x: x)
        for x in {p[0] for p in pts}:
            ys = [p[1] for p in pts if p[0] == x]
            top, bottom = min(ys), max(ys)
            # topo iluminado (só na parte esquerda/central: luz não uniforme, evita pillow shading)
            if len(pts) > 8 and cv.get(x, top - 1, wrap=True) == shadow and rng.random() < 0.75:
                cv.px(x, top, "lilac_grey")
            # sombra de contato embaixo (fenda)
            if len(pts) > 8 and cv.get(x, bottom + 1, wrap=True) == shadow and rng.random() < 0.6:
                cv.px(x, (bottom + 1) % FH, "ink")
    return cv


def surface_tex(seed: int = 5) -> Canvas:
    rng = random.Random(seed)
    cv = Canvas(SW, SH, "shadow")

    def wave(lo: float, hi: float, s: int) -> list:
        """Profundidade que ondula ao longo de x (periódica em SW -> seamless), em degraus progressivos."""
        r = random.Random(s)
        f = [(k, r.random() * 6.28, 1 / k) for k in (1, 2, 3, 5)]
        vals = [sum(a * math.sin(6.2832 * k * x / SW + ph) for k, ph, a in f) for x in range(SW)]
        m0, m1 = min(vals), max(vals)
        return [round(lo + (v - m0) / (m1 - m0) * (hi - lo)) for v in vals]

    steel_d, lilac_d, slate_d = wave(2, 5, seed), wave(5, 9, seed + 1), wave(8, 12, seed + 2)
    for x in range(SW):
        cv.px(x, 0, "mist")
        for y in range(1, SH):
            if y < steel_d[x]:
                cv.px(x, y, "steel")
            elif y < lilac_d[x]:
                cv.px(x, y, "lilac_grey")
            elif y < slate_d[x]:
                cv.px(x, y, "slate")
    # borda iluminada irregular (pesquisa: borda não precisa ter 1 px em todo lugar)
    x = rng.randint(0, 7)
    while x < SW:
        run = rng.randint(2, 5)
        for i in range(run):
            cv.px((x + i) % SW, 0, "steel")
        x += run + rng.randint(9, 17)
    # pedrinhas soltas na transição com o corpo (mesma linguagem das rochas do fill -> sem costura)
    for _ in range(5):
        cx, cy = rng.randrange(SW), rng.randint(10, SH - 3)
        w = rng.choice([2, 3, 4])
        for i in range(w):
            x = (cx + i) % SW
            if cy > slate_d[x]:
                cv.px(x, cy, "slate")
                if 0 < i < w - 1 or w == 2:
                    cv.px(x, cy + 1, "slate")
    # cratera rasa vista de leve de cima: bacia escura com borda de baixo iluminada (luz de cima)
    for cx, w in ((14, 7), (44, 5)):
        y = steel_d[cx] - 1
        for i in range(w):
            x = (cx + i) % SW
            edge = i in (0, w - 1)
            cv.px(x, y, "lilac_grey" if edge else "slate")
            if not edge:
                cv.px(x, y + 1, "lilac_grey" if i in (1, w - 2) else "steel")
    return cv


def profile(width: int, seed: int = 7, base: float = 250.0, amp: float = 70.0, step: int = 16,
            max_slope: float = 1.2, pad=(300, 64)) -> list:
    """Relevo parecido com o do jogo (TerrainGen: ruído por oitavas, passo 16, encosta máx 1.2, plataforma plana)."""
    rng = random.Random(seed)
    phases = [rng.random() * 6.28 for _ in range(4)]
    pts = []
    prev = None
    for x in range(0, width + step, step):
        h = sum(math.sin(x * 0.003 * 2 ** o * 2.3 + phases[o]) / 2 ** o for o in range(4))
        y = base - h * amp * 0.6
        if prev is not None:
            y = max(prev - max_slope * step, min(prev + max_slope * step, y))
        if pad[0] - step <= x <= pad[0] + pad[1] + step:
            y = pts[-1][1] if pad[0] < x else y
        pts.append((x, y))
        prev = y
    return pts


def ridge_y(pts: list, x: float) -> int:
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        if x0 <= x <= x1:
            return round(y0 + (y1 - y0) * (x - x0) / (x1 - x0))
    return round(pts[-1][1])


def scene(fill: Canvas, surf: Canvas, w: int = 640, h: int = 360, seed: int = 7) -> Canvas:
    cv = Canvas(w, h, "ink")
    sky = {(x, y) for x in range(w) for y in range(h)}
    cv.scatter(sky, "slate", 0.004, seed=seed, min_dist=3)
    cv.scatter(sky, "mist", 0.0012, seed=seed + 1, min_dist=6)
    cv.scatter(sky, "white", 0.0003, seed=seed + 2, min_dist=12)
    pad_x, pad_w = 300, 64
    pts = profile(w, seed, pad=(pad_x, pad_w))
    for x in range(w):
        r = ridge_y(pts, x)
        for y in range(r, h):
            k = y - r
            cv.px(x, y, surf.get(x % SW, k) if k < SH else fill.get(x % FW, y % FH))
    lander = Canvas.from_image("assets/sprites/lander.png").crop(0, 0, 32, 32)
    pad_y = ridge_y(pts, pad_x + pad_w // 2)
    cv.stamp(lander, pad_x + pad_w // 2 - 16, pad_y - 25)
    return cv


if __name__ == "__main__":
    fill, surf = fill_tex(), surface_tex()
    for name, c in (("moon_fill", fill), ("moon_surface", surf)):
        print(name, c.colors_used(), c.lint(max_colors=8, wrap=True))
    fill.save("art/previews/moon_fill.png", tiled=True)
    surf.save("art/previews/moon_surface.png", tiled=True)
    sc = scene(fill, surf)
    sc.save("art/previews/moon_scene.png", preview=False)
    sc.preview("art/previews/moon_scene_2x.png", scale=2, grid=False, show_1x=False)
