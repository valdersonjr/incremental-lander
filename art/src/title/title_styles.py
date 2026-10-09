"""Tela de título: 4 ESTILOS para o usuário avaliar no navegador (2026-10-09). Skill pixel-art, padrões title-screen +
cute-scene-method (kit da Lua de queijo + Scale2x, céu degradê, poucos elementos grandes, todo objeto com motivo).
Pedido: "essa tela inicial bastante pacata e não tanto bonitinha… 1 melhoria na atual, 2-4 novas, cada uma num estilo".
  1 "Festa na Lua"     — a Vitrine atual com vida: ratinhos pulando no ritmo, balões amarrados na nave, bandeirinhas
                         da bandeira até a nave, planetinha de anel, mais brilhos.
  2 "Planetinha"       — estilo Pequeno Príncipe: planetinha de queijo redondo, gatinho em cima, casinhas na curva e
                         a nave dando a volta (passa por trás do planeta).
  3 "Noite de história" — livro infantil: céu noturno, gatinho sentado na lua crescente de queijo pescando uma
                         estrelinha, nuvens lilás embaixo, ratinho de lanterna fazendo companhia.
  4 "Decolagem!"       — ação na diagonal: nave subindo com o gatinho na cúpula e o pacote pendurado, rastro de
                         plasma, riscos de velocidade, ratinhos comemorando na plataforma, confete.
Cada quadro = 1/16 de compasso do tema (92 BPM): a página toca o tema e escolhe o quadro pela posição da música.
Saída: art/previews/title_styles/<n>_<qq>.png (1x, com menu) + <n>_clean_<qq>.png (sem menu) + index.html.
Rodar da raiz: python3 art/src/title/title_styles.py   (quadros em paralelo)
"""
import math
import os
import random
import sys
from concurrent.futures import ProcessPoolExecutor

sys.path.insert(0, ".claude/skills/pixel-art/scripts")
for p in ("art/src/bg", "art/src/terrain", "art/src/sprites", "art/src/ui", "art/src/title"):
    sys.path.insert(0, p)
from pixelart import *
import moon_cute as mc
import moon_props as mp
import cat_hero as ch
import title_concepts as tc

W, H = 640, 360
OUT = "art/previews/title_styles"
FRAMES = {"1": 16, "2": 32, "3": 16, "4": 16}               # 16 quadros = 1 compasso; o planetinha gira em 2


def beat_up(fr: int) -> int:
    """Pulo no tempo: 2 px no quadro da batida, 1 no seguinte (16 quadros = 4 tempos)."""
    return {0: 2, 1: 1}.get(fr % 4, 0)


def big_mouse(fr: int, phase: int = 0) -> Canvas:
    return mc.scale2x(mp.mouse(fr, phase))


def cat_cheer(fr: int) -> Canvas:
    """Gatinho acenando no compasso (aceno nos 2 primeiros tempos, depois respira e pisca)."""
    pose = tc.WAVE[fr % len(tc.WAVE)]
    return tc.hero(pose="rest" if pose == "blink" else pose.replace("stand", "rest"), blink=pose == "blink",
                   tail_up=2 if (fr // 4) % 2 else 0, breathe=1 if (fr // 4) % 2 else 0)


def confetti(cv: Canvas, fr: int, seed: int, area: tuple, n: int) -> None:
    rng = random.Random(seed)
    x0, y0, x1, y1 = area
    for i in range(n):
        x = rng.randrange(x0, x1)
        y = y0 + (rng.randrange(0, y1 - y0) + fr * (3 + i % 3)) % (y1 - y0)
        col = rng.choice(["hot_pink", "gold", "aqua", "lavender", "leaf", "white"])
        if (fr + i) % 2:
            cv.rect(x, y, 2, 1, col)
        else:
            cv.rect(x, y, 1, 2, col)


# ================================================================== 1. Festa na Lua (melhoria)
def s1_static():
    st = tc.scene_a_static()
    (sky, fore), geo = st
    sky = sky.copy()
    mc.ringed(sky, 250, 54)                                     # planetinha de anel: companheiro da Terra
    return (sky, fore), geo


def s1(fr: int, static) -> Canvas:
    cv = tc.scene_a(fr, static)                                 # a Vitrine aprovada (gato, bandeira, nave, Terra)
    (_, _), (hx, hy, tops) = static
    fx, sx = 446, 478
    sy = hy + min(tops[sx - hx + 10], tops[sx - hx + 70]) - 61 + 1
    fl_top = hy + tops[fx + 4 - hx] - 50 + 3
    a, b_ = (fx + 6, fl_top + 4), (sx + 40, sy + 8)              # bandeirinhas: topo da bandeira -> antena da cúpula
    bt = mc.scale2x(mp.bunting((b_[0] - a[0]) // 2, sag=4, dy=(b_[1] - a[1]) // 2))
    cv.stamp(bt, a[0], min(a[1], b_[1]))
    knot = (sx + 70, sy + 60)                                   # balões amarrados no pé direito da nave
    for i, (col, dx, s) in enumerate((("hot_pink", -14, 14), ("sky", 0, 20), ("lemon", 12, 10))):
        bl = mc.scale2x(mp.balloon(fr // 2, col, i, s))
        cv.stamp(bl, knot[0] + dx - 12, knot[1] - bl.h + 2)
    for i, (x, ph) in enumerate(((214, 0), (252, 2), (600, 1))):   # ratinhos pulando no tempo (no queijo da frente)
        m = big_mouse(fr, ph)
        if i == 2:
            m.flip_h()
        up = beat_up(fr + (2 if i == 1 else 0))
        cv.stamp(m, x, 328 - m.h + 2 - up * 2)
    tc.sparkles(cv, [(300, 40, 3), (560, 170, 2), (200, 150, 2), (520, 20, 2)], fr + 3)
    return cv


# ================================================================== 2. Planetinha (Pequeno Príncipe)
P2 = (452, 336, 122)                                            # centro e raio do planetinha


def s2_static():
    stops = [(0, "navy"), (60, "indigo"), (120, "plum_dark"), (170, "plum"), (220, "berry_dark"), (270, "berry"),
             (320, "rose")]
    cv = tc.sky_canvas(stops, 90, 21)
    rng = random.Random(22)
    for _ in range(50):
        cv.px(rng.randrange(W), rng.randrange(0, 260), rng.choice(["white", "pale_sky", "lavender", "lemon"]))
    earth = mc.planet()
    cv.stamp(earth, 556 - earth.w // 2, 74 - earth.h // 2)
    mc.ringed(cv, 238, 220)
    planet = Canvas(W, H)
    cx, cy, r = P2
    for y in range(cy - r - 1, H):
        for x in range(cx - r - 1, cx + r + 2):
            nx, ny = (x + 0.5 - cx) / r, (y + 0.5 - cy) / r
            d = nx * nx + ny * ny
            if d > 1:
                continue
            i = -0.45 * nx - 0.6 * ny + 0.65 * math.sqrt(1 - d)
            planet.px(x, y, "lemon" if i > 0.8 else "gold" if i > 0.55 else "amber" if i > 0.3 else "copper")
            if d > 0.982:
                planet.px(x, y, "rust")
    for hxx, hyy, hr in ((380, 300, 12), (470, 268, 8), (520, 322, 16), (420, 350, 9), (560, 290, 7), (340, 344, 7)):
        for y in range(hyy - hr // 2, hyy + hr // 2 + 1):
            for x in range(hxx - hr, hxx + hr + 1):
                if ((x - hxx) / hr) ** 2 + ((y - hyy) / (hr / 2)) ** 2 <= 1 and planet.get(x, y) is not None \
                        and planet.get(x, y) != NAME_TO_INDEX["rust"]:
                    planet.px(x, y, "copper" if y < hyy else "amber")
    return cv, planet


def surface_y(x: float) -> int:
    cx, cy, r = P2
    return int(cy - math.sqrt(max(0.0, r * r - (x - cx) ** 2)))


def s2(fr: int, static) -> Canvas:
    sky, planet = static
    cv = sky.copy()
    tc.sparkles(cv, [(250, 60, 3), (470, 40, 2), (610, 160, 2), (330, 150, 2), (180, 250, 2)], fr)
    th = math.tau * fr / FRAMES["2"]                            # órbita da nave: 2 compassos por volta
    ox, oy = P2[0] + 205 * math.cos(th), 236 + 62 * math.sin(th)
    ship = tc.big_lander(flame=fr)
    far = math.sin(th) < 0
    if far:                                                     # lado de lá: passa ATRÁS do planeta
        cv.stamp(ship, int(ox) - 40, int(oy) - 40)
    cv.stamp(planet)
    houses = []
    for i, x in enumerate((382, 522)):                          # casinhas dos ratinhos na curva (escala do ratinho)
        d = mc.scale2x(mc.small_dome(fr // 2, i))
        houses.append((d, x - d.w // 2, max(surface_y(x - 20), surface_y(x + 20)) - d.h + 8))
    fl = tc.flag(fr)
    cv.stamp(fl, 556, surface_y(560) - fl.h + 6)
    for d, x, y in houses:
        cv.stamp(d, x, y)
    m = big_mouse(fr, 1)
    m.flip_h()
    cv.stamp(m, 400, surface_y(418) - m.h + 5 - beat_up(fr) * 2)
    cat = cat_cheer(fr)
    cv.stamp(cat, P2[0] - cat.w // 2, P2[1] - P2[2] - tc.feet(cat) + 3)
    if not far:
        cv.stamp(ship, int(ox) - 40, int(oy) - 40)
    return cv


# ================================================================== 3. Noite de história
MOON3 = ((462, 150, 150), (462, 96, 142))                       # círculo de fora e o que recorta (crescente-barquinho)


def in_crescent(x: float, y: float) -> bool:
    (ax, ay, ar), (bx, by, br) = MOON3
    return (x - ax) ** 2 + (y - ay) ** 2 <= ar * ar and (x - bx) ** 2 + (y - by) ** 2 > br * br


def s3_static():
    stops = [(0, "navy"), (110, "indigo"), (210, "plum_dark"), (290, "plum")]
    cv = tc.sky_canvas(stops, 120, 31)
    rng = random.Random(32)
    for _ in range(60):
        cv.px(rng.randrange(W), rng.randrange(0, 300), rng.choice(["white", "pale_sky", "lavender", "lemon", "cream"]))
    moon = Canvas(W, H)
    (ax, ay, ar), _ = MOON3
    for y in range(0, H):
        for x in range(ax - ar - 1, ax + ar + 2):
            if not in_crescent(x + 0.5, y + 0.5):
                continue
            nx, ny = (x + 0.5 - ax) / ar, (y + 0.5 - ay) / ar
            edge = not in_crescent(x + 1.5, y + 0.5) or not in_crescent(x - 0.5, y + 0.5) \
                or not in_crescent(x + 0.5, y + 1.5) or not in_crescent(x + 0.5, y - 0.5)
            i = -0.3 * nx - 0.7 * ny
            moon.px(x, y, "rust" if edge else ("lemon" if i > 0.1 else "gold" if i > -0.45 else "amber"))
    for hxx, hyy, hr in ((380, 262, 9), (470, 284, 12), (552, 250, 8), (330, 214, 6), (600, 196, 6)):
        for y in range(hyy - hr // 2, hyy + hr // 2 + 1):
            for x in range(hxx - hr, hxx + hr + 1):
                if ((x - hxx) / hr) ** 2 + ((y - hyy) / (hr / 2)) ** 2 <= 1 and moon.get(x, y) not in (
                        None, NAME_TO_INDEX["rust"]):
                    moon.px(x, y, "copper" if y < hyy else "amber")
    old = mc.T["cloud"], mc.T["cloud_ol"]
    mc.T["cloud"], mc.T["cloud_ol"] = ["lavender", "lavender", "violet"], "indigo"
    clouds = Canvas(W, H)
    for x, y, kind, flip in ((200, 352, "grande", False), (300, 340, "grande", True), (400, 350, "grande", False),
                             (500, 338, "grande", True), (600, 348, "grande", False), (660, 334, "pequena", True),
                             (250, 322, "pequena", False), (560, 318, "pequena", True), (120, 356, "grande", True)):
        mc.cloud(clouds, x, y, kind, flip)                       # banco de nuvens: a lua flutua sobre elas
    mc.T["cloud"], mc.T["cloud_ol"] = old
    bank = Canvas(W, H)                                         # banco de nuvens contínuo (a lua flutua sobre ele)
    bumps = [(x, rng.uniform(10, 22)) for x in range(-10, W + 20, 26)]
    for x in range(W):
        top = min(330 - math.sqrt(max(0.0, r * r - (x - bx) ** 2)) for bx, r in bumps)
        top = int(min(top, 336))
        for y in range(top, H):
            bank.px(x, y, "white" if y < top + 2 else "lavender" if y < top + 10 else "violet")
        bank.px(x, top - 1, "indigo")
    return cv, moon, clouds, bank


TWINKLE3 = [(random.Random(7 + i).randrange(200, W), random.Random(70 + i).randrange(6, 200)) for i in range(14)]


def seat() -> tuple:
    """Ponto onde o gatinho senta: o fundo de dentro da crescente."""
    _, (bx, by, br) = MOON3
    sx = 452
    return sx, int(by + math.sqrt(br * br - (sx - bx) ** 2))


def draw_fisher(cv: Canvas, fr: int) -> None:
    """Grupo do pescador (anda com a lua): ratinho de companhia, gatinho sentado com as perninhas para fora, varinha,
    linha balançando no compasso e a estrelinha dormindo no anzol."""
    seat_x, seat_y = seat()
    m = big_mouse(fr, 2)
    cv.stamp(m, seat_x - 66, seat_y - m.h + 4 - (1 if fr % 8 < 4 else 0))
    cat = ch.body("hold", "float", blink=fr == 15, tail_up=2 if (fr // 4) % 2 else 0, k=tc.HERO_K,
                  breathe=1 if (fr // 4) % 2 else 0)
    cx = seat_x - cat.w // 2
    cy = seat_y - tc.feet(cat) + 18                             # sentado: as perninhas balançam para fora da borda
    cv.stamp(cat, cx, cy)
    hand = (cx + round(38 * tc.HERO_K), cy + round(52 * tc.HERO_K))
    tip = (hand[0] + 70, hand[1] - 62)
    for d, col in ((0, "ink"), (1, "copper"), (2, "honey"), (3, "ink")):   # varinha (2 px + contorno)
        cv.line(hand[0] + d, hand[1], tip[0] + d, tip[1], col)
    sway = round(5 * math.sin(math.tau * fr / 16))
    end = (tip[0] + sway, 292)
    cv.line(tip[0], tip[1], end[0], end[1], "pale_sky")         # linha de pesca até a estrelinha
    star = Canvas(15, 15)
    pts = [(7, 0), (9, 5), (14, 5), (10, 9), (12, 14), (7, 11), (2, 14), (4, 9), (0, 5), (5, 5)]
    star.polygon(pts, "lemon")
    star.px(6, 4, "white"); star.px(6, 5, "white"); star.px(5, 6, "white")
    star.px(5, 8, "ink"); star.px(9, 8, "ink"); star.px(7, 9, "salmon")   # carinha dormindo da estrela
    star.outline("ink")
    cv.stamp(star, end[0] - 7, end[1])
    if fr % 4 == 0:
        mc.sparkle(cv, end[0] + 9, end[1] - 2, 2)


def s3(fr: int, static) -> Canvas:
    sky, moon, clouds, bank = static
    cv = sky.copy()
    for i, (x, y) in enumerate(TWINKLE3):                       # estrelas grandes piscando em colcheias
        if (fr // 2 + i * 5) % 8 < 2:
            mc.sparkle(cv, x, y, 2)
        else:
            cv.px(x, y, "white")
    cv.stamp(moon)
    draw_fisher(cv, fr)
    cv.stamp(bank)
    cv.stamp(clouds, round(2 * math.sin(math.tau * fr / 16)), -14)
    return cv


# ================================================================== 4. Decolagem!
def pilot_lander(fr: int) -> Canvas:
    """A nave pôster com o gatinho na cúpula (cabeça + capacete, recortado de um gatinho k=0.8 acenando)."""
    ship = tc.big_lander(flame=fr)
    cat = ch.body("wave1" if (fr // 2) % 2 else "wave2", blink=fr == 12, k=0.8)
    top = min(y for _, y in cat.opaque())
    head_h = 26
    xs = [x for x, y in cat.opaque()]
    cx0 = (min(xs) + max(xs)) // 2
    k = Canvas(ship.w, ship.h)
    k.stamp(ship)
    for y in range(top, top + head_h):
        for x in range(cat.w):
            c = cat.get(x, y)
            if c is None:
                continue
            tx, ty = 40 + x - cx0, 9 + y - top
            if ((tx + 0.5 - 40) / 18) ** 2 + ((ty + 0.5 - 24) / 16) ** 2 <= 1 and ty <= 33:
                k.px(tx, ty, c)
    for a in range(205, 250, 5):                                # reflexo do vidro por cima
        x = 40 + 15 * math.cos(math.radians(a)); y = 24 + 13 * math.sin(math.radians(a))
        k.px(int(x), int(y), "white")
    return k


def s4_static():
    cv = tc.sky_canvas(mc.T["sky"], 20, 41)
    cv.stamp(mc.planet(), 556 - 60, 74 - 60)
    for x, y, kind, flip in ((250, 130, "grande", False), (600, 210, "pequena", True)):
        mc.cloud(cv, x, y, kind, flip)
    back = Canvas(W, 300)
    for name, x, flip in (("grande_fundo", 180, False), ("fundo_alto", 430, True)):
        k = mc.piece(name, flip, mc.T["back"], None, 4, ao=0)
        back.stamp(k, x, 300 - k.h)
    cv.stamp(back)
    tc.ground(cv, 318)
    return (cv,)


def s4(fr: int, static) -> Canvas:
    (base,) = static
    cv = base.copy()
    rng = random.Random(5)
    for i in range(16):                                         # riscos de velocidade na diagonal (a nave sobe)
        x0 = rng.randrange(200, W + 80)
        y0 = (rng.randrange(0, 300) + fr * 18) % 320 - 10
        ln = rng.randrange(14, 30)
        for t in range(ln):
            x, y = x0 - t * 2 // 3, y0 + t
            if 0 <= x < W and 0 <= y < H:
                cv.px(x, y, "white" if t < ln // 2 else "cream")
    tc.pad(cv, fr, 330, 600)
    bob = round(4 * math.sin(math.tau * fr / 16))
    sx, sy = 470, 92 + bob
    for i in range(14):                                         # rastro: fumaça que abre embaixo + núcleo de plasma
        y = sy + 76 + i * 11
        if y > tc.PAD_Y + 8:
            break
        r = 7 + i * 2.6 + (fr + i) % 3
        wob = math.sin(i * 1.3 + fr * math.tau / 16) * (1 + i * 0.6)
        mc.sphere(cv, sx + 40 + wob, y, r, r * 0.75, ["white", "white", "cream", "peach"])
        if i < 5:
            mc.sphere(cv, sx + 40 + wob, y - 4, max(2.5, 5 - i), 6, ["white", "ice", "aqua", "sea"])
    cv.stamp(pilot_lander(fr), sx, sy)
    for i, (x, ph) in enumerate(((360, 0), (400, 2), (540, 1))):  # ratinhos comemorando na plataforma
        m = big_mouse(fr, ph)
        if i == 2:
            m.flip_h()
        cv.stamp(m, x, tc.PAD_Y - m.h + 2 - beat_up(fr + i * 2) * 3)
    confetti(cv, fr, 9, (300, 120, 640, 300), 40)
    tc.sparkles(cv, [(250, 60, 3), (600, 140, 2)], fr)
    return cv


STYLES = {"1": ("Festa na Lua", s1_static, s1), "2": ("Planetinha", s2_static, s2),
          "3": ("Noite de história", s3_static, s3), "4": ("Decolagem!", s4_static, s4)}


def render(args) -> list:
    key, frames = args
    _, st, fn = STYLES[key]
    static = st()
    out = []
    for fr in frames:
        cv = fn(fr, static)
        clean = cv.copy()
        tc.menu(cv, True)
        out.append((fr, clean.to_image().convert("RGB"), cv.to_image().convert("RGB")))
    return out


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    keys = [a for a in sys.argv[1:] if a in STYLES] or list(STYLES)
    jobs = []
    for k in keys:                                              # quadros em lotes de 4 por processo
        n = FRAMES[k]
        jobs += [(k, list(range(i, min(n, i + 4)))) for i in range(0, n, 4)]
    with ProcessPoolExecutor() as ex:
        results = list(ex.map(render, jobs))
    for (k, _), imgs in zip(jobs, results):
        for fr, clean, menu_img in imgs:
            clean.save(f"{OUT}/{k}_clean_{fr:02d}.png")
            menu_img.save(f"{OUT}/{k}_{fr:02d}.png")
    for k in keys:                                              # paleta: todo quadro só com cores da Resurrect 64
        check_png(f"{OUT}/{k}_00.png")
    print("ok", OUT, keys)
