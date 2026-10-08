"""Cenários dos mundos novos (Fase 18.5, 2026-10-07) — skill pixel-art, método aprovado cute-scene-method.

Reaproveita o KIT da Lua de queijo (art/src/bg/moon_cute.py: céu em degradê com transição bayer reta, nuvens e
morros desenhados por pontos em meia resolução + Scale2x, sombreamento cel, névoa clara na base de cada plano) e troca
o TEMA (rampas da Resurrect 64) e as PEÇAS de cada mundo (silhuetas próprias: o teste em preto e branco tem que dizer
qual mundo é). Mesmo contrato de assets da Lua (Backdrop/Terrain do Godot):
  assets/bg/<id>_{sky,clouds,planet,far,mid,plain}.png + <id>_layers.json
  assets/tiles/<id>_ground_{lit,flat,shade}.png, <id>_body.png, <id>_depth.png · assets/sprites/<id>_rocks.png

Mundos (docs/DECISIONS.md, protótipo art/previews/mundos/): nuvens (carneirinhos, balões, arco-íris, sol),
cogumelos (noite: cogumelos gigantes, sapinhos, vaga-lumes, lua), sorvete (montanhas de bolas de sorvete, casquinhas,
pinguins, iglu), jardim (flores gigantes, abelhinhas, joaninhas, sol de pétalas), bolhas (mar, ilhas com coqueiros,
baleia, conchas).

Rodar da raiz:
  python3 art/src/bg/world_scene.py nuvens            -> prévia art/previews/world_nuvens.png (não mexe no jogo)
  python3 art/src/bg/world_scene.py all --export      -> grava os assets dos 5 mundos
"""
import json
import math
import random
import sys

sys.path.insert(0, ".claude/skills/pixel-art/scripts")
sys.path.insert(0, "art/src/bg")
sys.path.insert(0, "art/src/terrain")
from pixelart import *
import moon_cute as mc
import anim_util as au

W, H = mc.W, mc.H
MW = mc.MW
FR = mc.FR

THEMES = {
    "nuvens": dict(
        name="Reino das Nuvens", night=False,
        sky=[(0, "sky"), (70, "pale_sky"), (150, "lavender"), (200, "cream"), (236, "white"), (300, "white")],
        sparkle=["white", "white", "lavender"], cloud=["white", "white", "lavender"], cloud_ol="pale_sky",
        far_ramp=["white", "white", "white", "lavender"], far_haze="white",
        back=["white", "white", "lavender", "violet"], back_haze="white",
        front=["white", "white", "pale_sky", "sky"], front_ol="sky", haze="pale_sky", front_tex=["pale_sky", "lavender"],
        plain=["pale_sky", "sky", "violet"], plain_line="white",
        rim={"lit": ["white", "white"], "flat": ["white", "white"], "shade": ["white", "pale_sky"]},
        ol="sky", ao="pale_sky", body="white", strata="lavender", hole="pale_sky", hole_dark="sky", lip="white",
        pebble="lavender", depth=["lavender", "violet", "purple"], deep="purple", rock=["white", "lavender", "pale_sky"],
        smoke=["white", "mist", "lavender"], smoke_ol="lavender", earth_glow=["lemon", "gold"], beam=["white", "lemon", "gold"],
    ),
    "cogumelos": dict(
        name="Floresta dos Cogumelos", night=True,
        sky=[(0, "navy"), (64, "indigo"), (124, "plum"), (176, "purple"), (218, "berry"), (248, "rose")],
        sparkle=["white", "lemon", "lime"], cloud=["purple", "plum", "plum"], cloud_ol="indigo",
        far_ramp=["violet", "purple", "purple", "plum"], far_haze="rose",
        back=["purple", "plum", "plum", "plum_dark"], back_haze="berry",
        front=["leaf", "green", "pine", "deep_teal"], front_ol="deep_sage", haze="deep_teal", front_tex=["pine", "green"],
        plain=["deep_teal", "pine", "deep_sage"], plain_line="green",
        rim={"lit": ["lime", "leaf"], "flat": ["leaf", "green"], "shade": ["green", "pine"]},
        ol="pine", ao="deep_sage", body="berry_dark", strata="wine", hole="plum", hole_dark="plum_dark", lip="berry",
        pebble="berry", depth=["wine", "maroon", "plum_dark"], deep="plum_dark", rock=["salmon", "red", "crimson"],
        smoke=["lavender", "violet", "purple"], smoke_ol="indigo", earth_glow=["lemon", "gold"], beam=["lemon", "lime", "leaf"],
    ),
    "sorvete": dict(
        name="Planeta Sorvete", night=False,
        sky=[(0, "sky"), (60, "pale_sky"), (124, "lavender"), (176, "cream"), (220, "peach"), (250, "pink")],
        sparkle=["white", "white", "lavender"], cloud=["white", "white", "lavender"], cloud_ol="pale_sky",
        far_ramp=["white", "white", "white", "pale_sky"], far_haze="white",
        back=["cream", "cream", "peach", "salmon"], back_haze="cream",
        front=["peach", "pink", "hot_pink", "raspberry"], front_ol="berry", haze="rose", front_tex=["white", "lemon"],
        plain=["pale_sky", "sky", "blue"], plain_line="white",
        rim={"lit": ["white", "white"], "flat": ["white", "white"], "shade": ["pale_sky", "pale_sky"]},
        ol="sky", ao="pale_sky", body="pink", strata="salmon", hole="white", hole_dark="hot_pink", lip="peach",
        pebble="lemon", depth=["rose", "berry", "berry_dark"], deep="wine", rock=["white", "pale_sky", "sky"],
        smoke=["white", "lavender", "pale_sky"], smoke_ol="sky", earth_glow=["lemon", "gold"], beam=["white", "lemon", "gold"],
    ),
    "jardim": dict(
        name="Jardim Gigante", night=False,
        sky=[(0, "sky"), (70, "pale_sky"), (150, "pale_sky"), (196, "cream"), (230, "lemon"), (300, "lemon")],
        sparkle=["white", "lemon", "sprout"], cloud=["white", "white", "mist"], cloud_ol="pale_sky",
        far_ramp=["sprout", "lime", "moss", "sage"], far_haze="sprout",
        back=["lime", "leaf", "leaf", "emerald"], back_haze="sprout",
        front=["leaf", "emerald", "green", "pine"], front_ol="pine", haze="green", front_tex=["sprout", "leaf"],
        plain=["green", "pine", "deep_teal"], plain_line="leaf",
        rim={"lit": ["lime", "sprout"], "flat": ["sprout", "leaf"], "shade": ["leaf", "green"]},
        ol="green", ao="pine", body="terracotta", strata="rust", hole="umber", hole_dark="umber", lip="copper",
        pebble="copper", depth=["rust", "maroon", "umber"], deep="umber", rock=["sprout", "leaf", "green"],
        smoke=["white", "mist", "steel"], smoke_ol="steel", earth_glow=["lemon", "gold"], beam=["white", "lemon", "gold"],
    ),
    "bolhas": dict(
        name="Mar das Bolhas", night=False,
        sky=[(0, "sky"), (64, "pale_sky"), (140, "lavender"), (186, "cream"), (226, "peach"), (300, "peach")],
        sparkle=["white", "white", "lavender"], cloud=["white", "white", "lavender"], cloud_ol="pale_sky",
        far_ramp=["white", "pale_sky", "pale_sky", "sky"], far_haze="pale_sky",
        back=["sprout", "leaf", "emerald", "green"], back_haze="peach",
        front=["lemon", "honey", "gold", "amber"], front_ol="copper", haze="sea", front_tex=["white", "salmon"],
        plain=["sea", "teal", "deep_teal"], plain_line="ice",
        rim={"lit": ["lemon", "honey"], "flat": ["honey", "gold"], "shade": ["gold", "amber"]},
        ol="copper", ao="amber", body="honey", strata="gold", hole="cream", hole_dark="salmon", lip="lemon",
        pebble="peach", depth=["copper", "terracotta", "rust"], deep="rust", rock=["white", "cream", "peach"],
        smoke=["white", "lavender", "pale_sky"], smoke_ol="sky", earth_glow=["lemon", "gold"], beam=["white", "lemon", "gold"],
    ),
}

# morros por mundo (BACK/FRONT da Lua sem a mina): (peça, x, espelhado) num laço de 1920 px
BACK = [(n, x + 640 * i, f != (i == 1)) for i in range(3)
        for n, x, f in (("grande_fundo", -60, False), ("fundo_alto", 190, True), ("grande_fundo", 360, True))]
FRONTS = {
    "default": [("baixinho", 40, False), ("domo_calombo", 170, False), ("bolinha", 330, True), ("dois_calombos", 430, False),
                ("baixinho", 640, True), ("domo_calombo", 730, False), ("bolinha", 880, False), ("dois_calombos", 960, False),
                ("baixinho", 1110, True), ("planalto", 1300, False), ("bolinha", 1460, False), ("domo_calombo", 1530, True),
                ("baixinho", 1700, False), ("bolinha", 1830, False)],
}


# ------------------------------------------------------------------ peças fofas (personagens/objetos = contorno ink)
def sheep(fr: int, phase: int = 0) -> Canvas:
    return mc.scale2x(_sheep(fr, phase))


def _sheep(fr: int, phase: int = 0) -> Canvas:
    """Carneirinho de nuvem 18x15: lã em bolinhas brancas, rostinho lilás, olhinhos e bochecha; pula de leve."""
    k = Canvas(18, 16)
    up = 1 if (fr + phase) % FR in (1, 2) else 0
    for x, y in ((5, 7), (9, 5), (13, 7), (4, 10), (14, 10), (8, 11), (11, 11)):
        mc.sphere(k, x, y - up, 3.3, 3.0, ["white", "white", "mist", "lavender"])
    mc.sphere(k, 3.5, 9 - up, 2.6, 2.6, ["lavender", "violet", "violet", "purple"])      # rosto
    k.px(2, 8 - up, "ink"); k.px(4, 8 - up, "ink"); k.px(1, 10 - up, "pink")
    for x in (6, 12):
        k.vline(x, 13 - up, 15 - up, "purple")
    k.outline("ink")
    return k


def hot_balloon(color: str, shade: str) -> Canvas:
    return mc.scale2x(_hot_balloon(color, shade))


def _hot_balloon(color: str, shade: str) -> Canvas:
    """Balão de ar quente 18x28: envelope com faixas, cestinha presa por cordas."""
    k = Canvas(18, 28)
    mc.sphere(k, 9, 9, 8, 9, ["white", color, color, shade])
    for x in (5, 13):
        k.vline(x, 2, 16, shade)
    k.line(4, 16, 7, 22, "sand"); k.line(14, 16, 11, 22, "sand")
    k.rect(6, 22, 6, 4, "terracotta"); k.hline(6, 11, 22, "copper")
    k.outline("ink")
    return k


def sun(face: bool = True, petals: str | None = None) -> Canvas:
    """Sol sorridente (foco do céu dos mundos de dia) com raios curtos; petals = sol-flor do Jardim."""
    r = 26
    m = r + 12
    c = Canvas(2 * m + 1, 2 * m + 1)
    o = m + 0.5
    for i in range(12):                                        # raios / pétalas
        a = math.tau * i / 12
        col = petals or ("lemon" if i % 2 else "gold")
        if petals:
            mc.sphere(c, o + math.cos(a) * (r + 5), o + math.sin(a) * (r + 5), 6, 6,
                      ["white", petals, petals, "rose" if petals == "pink" else "amber"])
        else:
            for d in range(r + 3, r + 9):
                c.px(int(o + math.cos(a) * d), int(o + math.sin(a) * d), col)
    mc.sphere(c, o, o, r, r, ["white", "lemon", "gold", "amber"])
    if face:
        ex, ey = int(o), int(o + 2)
        for sx in (-10, 5):                                    # olhinhos felizes (^ ^)
            for j, dy in enumerate((2, 1, 0, 0, 1, 2)):
                c.px(ex + sx + j, ey + dy - 3, "rust")
        mc.disc(c, ex - 12, ey + 4, 2.4, "salmon"); mc.disc(c, ex + 12, ey + 4, 2.4, "salmon")
        for j, dy in enumerate((0, 1, 2, 2, 1, 0)):
            c.px(ex - 3 + j, ey + 6 + dy, "rust")
    edge = Canvas(c.w, c.h)
    for y in range(c.h):
        for x in range(c.w):
            if r <= math.hypot(x + 0.5 - o, y + 0.5 - o) < r + 1.1:
                edge.px(x, y, "amber")
    c.stamp(edge)
    return c


def sleepy_moon() -> Canvas:
    """Lua cheia dormindo (foco do céu da Floresta, à noite)."""
    r = 26
    m = r + 12
    c = Canvas(2 * m + 1, 2 * m + 1)
    o = m + 0.5
    for y in range(c.h):
        for x in range(c.w):
            d = math.hypot(x + 0.5 - o, y + 0.5 - o)
            if r + 2 <= d < r + 4.4:
                c.px(x, y, "plum")
    mc.sphere(c, o, o, r, r, ["white", "cream", "cream", "peach"])
    for bx, by, br in ((o + 9, o - 10, 4), (o - 12, o + 9, 3), (o + 13, o + 11, 2.5)):
        mc.disc(c, bx, by, br, "peach")
    ex, ey = int(o), int(o + 2)
    for sx in (-12, 5):
        for j, dy in enumerate((0, 1, 2, 2, 2, 1, 0)):
            c.px(ex + sx + j, ey + dy, "plum")
        mc.disc(c, (ex + sx - 2 if sx < 0 else ex + sx + 8), ey + 6, 2, "salmon")
    return c


def rainbow(w: int = 220, h: int = 110) -> Canvas:
    """Arco-íris pastel (6 faixas de 3 px)."""
    c = Canvas(w, h)
    cols = ["salmon", "peach", "lemon", "sprout", "pale_sky", "lavender"]
    cx, cy = w / 2, h
    for y in range(h):
        for x in range(w):
            d = math.hypot((x + 0.5 - cx) / (w / 2), (y + 0.5 - cy) / h)
            i = int((1 - d) * 40)
            if 0 <= i < 18:
                c.px(x, y, cols[i // 3])
    return c


def mushroom(cap: str, cap_dark: str, h: int, r: float, dots: str = "white") -> Canvas:
    """Cogumelo gigante: talo creme e chapéu com bolinhas."""
    w = int(r * 2 + 4)
    k = Canvas(w, h + int(r) + 2)
    cx = w / 2
    top = int(r * 0.6)
    k.rect(int(cx - r * 0.25), top + 4, max(3, int(r * 0.5)), h, "cream")
    k.vline(int(cx + r * 0.2), top + 4, top + 3 + h, "peach")
    for y in range(int(r) + 1):
        for x in range(w):
            nx, ny = (x + 0.5 - cx) / r, (y + 0.5 - top - 2) / (r * 0.6)
            if nx * nx + ny * ny <= 1 and y <= top + 3:
                i = -0.55 * nx - 0.6 * ny
                k.px(x, y, "white" if i > 0.75 else cap if i > -0.3 else cap_dark)
    rng = random.Random(int(r * 10))
    for _ in range(max(2, int(r / 3))):
        x, y = rng.uniform(cx - r * 0.7, cx + r * 0.6), rng.uniform(1, top)
        mc.disc(k, x, y, max(1.2, r / 7), dots)
    k.outline("ink")
    return k


def frog(fr: int, phase: int = 0) -> Canvas:
    return mc.scale2x(_frog(fr, phase))


def _frog(fr: int, phase: int = 0) -> Canvas:
    """Sapinho 14x12: olhos no alto, bochecha, sorriso."""
    k = Canvas(16, 13)
    up = 1 if (fr + phase) % FR == 2 else 0
    mc.sphere(k, 7.5, 8 - up, 6.5, 4.5, ["lime", "leaf", "emerald", "green"])
    for ex in (4, 11):
        mc.sphere(k, ex, 4 - up, 2.5, 2.5, ["lime", "leaf", "leaf", "emerald"])
        k.px(ex, 4 - up, "ink")
    k.px(2, 9 - up, "pink"); k.px(13, 9 - up, "pink")
    k.hline(6, 9, 10 - up, "green")
    k.outline("ink")
    return k


def cone(scoops: list) -> Canvas:
    return mc.scale2x(_cone(scoops))


def _cone(scoops: list) -> Canvas:
    """Casquinha gigante com 1-3 bolas de sorvete (cores da rampa)."""
    k = Canvas(26, 40)
    for y in range(20, 40):                                    # casquinha em losangos
        half = (40 - y) * 0.32
        for x in range(int(13 - half), int(13 + half) + 1):
            k.px(x, y, "copper" if (x + y) % 4 == 0 else "honey")
    for i, (hi, base, shade) in enumerate(scoops):
        cy = 18 - i * 9
        mc.sphere(k, 13, cy, 9 - i, 7.5 - i * 0.5, ["white", hi, base, shade])
        for dx in (-5, 0, 4):                                  # calda escorrendo
            k.vline(13 + dx, cy + 4, cy + 7 + (dx % 3), base)
    k.outline("ink")
    return k


def penguin(fr: int, phase: int = 0, scarf: str = "red") -> Canvas:
    return mc.scale2x(_penguin(fr, phase, scarf))


def _penguin(fr: int, phase: int = 0, scarf: str = "red") -> Canvas:
    """Pinguim de cachecol 13x16."""
    k = Canvas(14, 17)
    up = 1 if (fr + phase) % FR in (0, 1) else 0
    mc.sphere(k, 7, 9 - up, 5.5, 6.5, ["shadow", "slate", "slate", "ink"])
    mc.sphere(k, 7, 10 - up, 3.5, 5, ["white", "white", "mist", "mist"])
    k.px(5, 6 - up, "white"); k.px(9, 6 - up, "white"); k.px(5, 6 - up, "ink"); k.px(9, 6 - up, "ink")
    k.px(7, 8 - up, "amber"); k.px(6, 8 - up, "amber")
    k.hline(3, 11, 10 - up, scarf); k.vline(10, 10 - up, 13 - up, scarf)
    k.hline(4, 6, 16, "amber"); k.hline(8, 10, 16, "amber")
    k.outline("ink")
    return k


def igloo() -> Canvas:
    k = Canvas(34, 20)
    for y in range(20):
        for x in range(34):
            nx, ny = (x + 0.5 - 17) / 16, (y + 0.5 - 20) / 18
            if nx * nx + ny * ny <= 1:
                k.px(x, y, "white" if (y % 5 and (x + (y // 5) * 3) % 8) else "ice")
    k.rect(13, 12, 8, 8, "sky"); k.rect(14, 13, 6, 7, "blue")
    k.outline("pale_sky")
    return k


def flower(petal: str, petal_dark: str, h: int, r: float = 9) -> Canvas:
    """Flor gigante: caule com folha, pétalas em volta do miolo dourado."""
    w = int(r * 2 + 12)
    k = Canvas(w, h + int(r * 2) + 4)
    cx, cy = w / 2, r + 2
    k.rect(int(cx) - 1, int(cy), 3, h + int(r), "green")
    k.vline(int(cx) + 1, int(cy), int(cy) + h + int(r) - 1, "pine")
    mc.sphere(k, cx + 6, cy + h * 0.6, 5, 2.5, ["sprout", "leaf", "leaf", "green"])
    for i in range(8):
        a = math.tau * i / 8
        mc.sphere(k, cx + math.cos(a) * r * 0.8, cy + math.sin(a) * r * 0.8, r * 0.45, r * 0.45,
                  ["white", petal, petal, petal_dark])
    mc.sphere(k, cx, cy, r * 0.45, r * 0.45, ["lemon", "gold", "gold", "amber"])
    k.outline("ink")
    return k


def bee(fr: int) -> Canvas:
    return mc.scale2x(_bee(fr))


def _bee(fr: int) -> Canvas:
    k = Canvas(12, 10)
    up = fr % 2
    mc.sphere(k, 5, 6, 4, 3, ["lemon", "gold", "gold", "amber"])
    k.vline(4, 3, 9, "ink"); k.vline(7, 3, 9, "ink")
    mc.disc(k, 4, 2 - up, 2, "white"); mc.disc(k, 8, 2 - up, 2, "white")
    k.px(2, 5, "ink")
    k.outline("ink")
    return k


def ladybug() -> Canvas:
    return mc.scale2x(_ladybug())


def _ladybug() -> Canvas:
    k = Canvas(10, 8)
    mc.sphere(k, 5, 5, 4, 3, ["salmon", "red", "red", "crimson"])
    k.vline(5, 2, 7, "ink")
    for x, y in ((3, 4), (7, 4), (4, 6), (6, 6)):
        k.px(x, y, "ink")
    mc.disc(k, 1.5, 4, 1.5, "ink")
    k.outline("ink")
    return k


def palm_island(w: int = 60, seed: int = 0) -> Canvas:
    """Ilhazinha de areia com coqueiro (o tronco curva, folhas em leque)."""
    k = Canvas(w, 46)
    for y in range(36, 46):
        for x in range(w):
            if ((x + 0.5 - w / 2) / (w / 2)) ** 2 + ((y + 0.5 - 46) / 10) ** 2 <= 1:
                k.px(x, y, "lemon" if y < 39 else "honey" if y < 42 else "gold")
    bx = w // 2 - 4
    for i in range(30):
        x = int(bx + math.sin(i / 10 + seed) * 4)
        k.px(x, 38 - i, "terracotta" if i % 3 else "rust"); k.px(x + 1, 38 - i, "copper")
    tx, ty = int(bx + math.sin(29 / 10 + seed) * 4), 8
    for j in range(5):
        a = -2.7 + j * 0.6
        for r in range(1, 13):
            x, y = int(tx + math.cos(a) * r), int(ty + math.sin(a) * r * 0.55 + r * r / 26)
            k.px(x, y, "emerald" if r < 4 else "leaf"); k.px(x, y + 1, "green")
    mc.disc(k, tx, ty + 3, 1.6, "rust")
    k.outline("copper")
    return k


def whale(fr: int) -> Canvas:
    return mc.scale2x(_whale(fr))


def _whale(fr: int) -> Canvas:
    k = Canvas(40, 22)
    mc.sphere(k, 18, 14, 15, 7, ["pale_sky", "sky", "blue", "indigo"])
    mc.sphere(k, 19, 17, 11, 3.5, ["white", "ice", "ice", "pale_sky"])
    for i in range(6):                                         # rabo
        k.px(34 + i // 2, 12 - i, "blue"); k.px(35 + i // 2, 12 - i, "sky")
    k.px(10, 11, "ink"); k.px(9, 12, "salmon")
    h = [3, 5, 4, 6][fr % FR]                                  # esguicho
    for i in range(h):
        k.px(16, 6 - i, "ice")
    k.px(15, 6 - h, "white"); k.px(17, 6 - h, "white")
    k.outline("ink")
    return k


# ------------------------------------------------------------------ planos
def sky_frames(theme: dict) -> list:
    out = []
    for fr in range(mc.SKY_FRAMES):
        cv = Canvas(W, H)
        for y in range(H):
            for x in range(W):
                cv.px(x, y, mc.sky_color(x, y))
        rng = random.Random(4)
        n = 60 if theme["night"] else 0
        for _ in range(n):                                     # estrelinhas e vaga-lumes (só à noite)
            x, y = rng.randrange(W), int(rng.random() ** 1.3 * 150)
            if (fr + x) % mc.SKY_FRAMES:
                cv.px(x, y, "lemon" if y > 100 else "white")
        for i, (x, y, s) in enumerate(mc.SPARKLES):
            mc.sparkle(cv, x, y, max(1, s - [0, 1, 1, 0, 0, 0][(fr + i * 2) % mc.SKY_FRAMES]))
        out.append(cv)
    return out


def focus(world: str) -> Canvas:
    if world == "cogumelos":
        return sleepy_moon()
    if world == "jardim":
        return sun(True, "pink")
    return sun(True)


def mid_frames(world: str) -> list:
    mc.BACK = BACK
    mc.FRONT = FRONTS.get(world, FRONTS["default"])
    base, tops = mc.mid_ground()
    frames = []
    for fr in range(FR):
        c = base.copy()

        def put(k, x, dy=2):
            b = max(tops[(x + d) % MW] for d in range(-max(2, k.w // 3), max(2, k.w // 3) + 1)) + 1 + dy
            mc.stamp_wrap(c, k, x - k.w // 2, b - k.h, MW)
        if world == "nuvens":
            for i, x in enumerate((110, 150, 196, 760, 1010, 1340, 1380)):
                k = sheep(fr, i)
                if i % 2:
                    k.flip_h()
                put(k, x)
            for x, y, col, sh in ((330, 96, "hot_pink", "raspberry"), (1180, 80, "violet", "purple"),
                                  (1640, 104, "lemon", "gold")):
                k = hot_balloon(col, sh)
                mc.stamp_wrap(c, k, x - k.w // 2, y + [0, 1, 2, 1][fr % FR], MW)
        elif world == "cogumelos":
            for i, (x, cap, dark, hh, rr) in enumerate(((80, "red", "crimson", 46, 24), (150, "hot_pink", "raspberry", 22, 12),
                                                       (440, "violet", "purple", 60, 28), (760, "red", "crimson", 30, 16),
                                                       (1050, "red", "crimson", 70, 30), (1110, "violet", "purple", 26, 14),
                                                       (1420, "hot_pink", "raspberry", 44, 20), (1720, "red", "crimson", 54, 24))):
                put(mushroom(cap, dark, hh, rr), x, dy=3)
            for i, x in enumerate((250, 290, 860, 1540)):
                put(frog(fr, i), x)
            rng = random.Random(9)
            for _ in range(28):                                # vaga-lumes piscando
                x, y = rng.randrange(MW), rng.randint(140, 250)
                if (x + fr) % 3:
                    c.px(x, y, "lemon"); c.px(x + 1, y, "lime")
        elif world == "sorvete":
            for i, (x, sc) in enumerate(((150, [["peach", "pink", "hot_pink"]]),
                                         (520, [["cream", "white", "ice"], ["lime", "sprout", "leaf"]]),
                                         (900, [["peach", "salmon", "rose"]]),
                                         (1280, [["cream", "cream", "peach"], ["peach", "pink", "hot_pink"], ["sprout", "lime", "moss"]]),
                                         (1660, [["ice", "pale_sky", "sky"]]))):
                put(cone(sc), x, dy=4)
            for i, x in enumerate((300, 340, 700, 1080, 1480, 1520)):
                put(penguin(fr, i, ["red", "sky", "gold"][i % 3]), x)
            put(mc.scale2x(igloo()), 1000, dy=3)
        elif world == "jardim":
            for i, (x, p, pd, hh) in enumerate(((100, "pink", "rose", 60), (380, "white", "mist", 44), (640, "violet", "purple", 70),
                                                (980, "gold", "amber", 50), (1260, "pink", "rose", 66), (1580, "lavender", "violet", 48),
                                                (1820, "white", "mist", 58))):
                put(flower(p, pd, hh + 30, 13 + (i % 3) * 3), x, dy=4)
            for i, (x, y) in enumerate(((240, 150), (290, 130), (820, 120), (1420, 150))):
                mc.stamp_wrap(c, bee(fr + i), x, y + [0, 2, 1, 2][(fr + i) % FR], MW)
            for x in (540, 1140, 1720):
                put(ladybug(), x)
        elif world == "bolhas":
            sea_y = mc.MID_BASE - 14                           # o mar ocupa a faixa de baixo do plano do meio
            for x in range(MW):
                for y in range(sea_y, mc.MID_BASE + 1):
                    c.px(x, y, "sea" if y < sea_y + 3 else "teal")
                if (x + fr * 3) % 23 < 4:
                    c.px(x, sea_y + 1, "ice")
            for i, x in enumerate((140, 560, 1000, 1440, 1780)):
                k = mc.scale2x(palm_island(40 + (i % 2) * 10, i))
                mc.stamp_wrap(c, k, x - k.w // 2, sea_y + 6 - k.h, MW)
            k = whale(fr)
            mc.stamp_wrap(c, k, 300, sea_y - 26, MW)
        frames.append(c)
    return frames


def plain_frames(world: str, theme: dict) -> list:
    out = []
    for fr in range(FR):
        c = Canvas(W, mc.PLAIN_H)
        p0, p1, p2 = theme["plain"]
        for x in range(W):
            for y in range(mc.PLAIN_H):
                col = p0 if y < 24 else p1 if y < 64 else p2
                if 20 <= y < 24 and mc.on((y - 20) / 4, x, y):
                    col = p1
                if 58 <= y < 64 and mc.on((y - 58) / 6, x, y):
                    col = p2
                c.px(x, y, col)
        rng = random.Random(41)
        for _ in range(14):
            x, y, ln = rng.randrange(W), rng.randint(4, 40), rng.randint(10, 30)
            if world == "bolhas":                              # ondinhas que andam
                x = (x + fr * 4) % W
            for i in range(ln):
                c.px((x + i) % W, y, theme["plain_line"])
        if world == "sorvete":                                 # granulado colorido na neve
            for _ in range(70):
                x, y = rng.randrange(W), rng.randint(2, 120)
                c.px(x, y, rng.choice(["hot_pink", "lemon", "sprout", "white"]))
        if world == "cogumelos":
            for _ in range(10):
                x = rng.randrange(W)
                k = mushroom("red", "crimson", 4, 4)
                c.stamp(k, x, rng.randint(6, 30))
        if world == "jardim":
            for _ in range(40):                                # trevinhos
                x, y = rng.randrange(W), rng.randint(3, 100)
                c.px(x, y, "leaf"); c.px(x + 1, y, "sprout"); c.px(x, y + 1, "emerald")
        out.append(c)
    return out


# ------------------------------------------------------------------ montagem / export
def build(world: str) -> dict:
    theme = THEMES[world]
    mc.T = theme
    L = {"sky_frames": sky_frames(theme), "planet": focus(world), "far": mc.far()}
    L["cloud_frames"] = [mc.clouds_layer(fr) for fr in range(FR)]
    L["mid_frames"] = mid_frames(world)
    L["plain_frames"] = plain_frames(world, theme)
    for f in ("lit", "flat", "shade"):
        L[f] = mc.crust(f)
    L["body"], L["depth"], L["rocks"] = mc.body(), mc.depth(), mc.rocks_atlas()
    return L


def preview(world: str, L: dict) -> Canvas:
    cv = Canvas(W, H)
    cv.stamp(L["sky_frames"][0]); cv.stamp(L["cloud_frames"][0])
    cx, cy, r = mc.PLANET
    cv.stamp(L["planet"], cx - r - 12, cy - r - 12)
    cv.stamp(L["far"]); cv.stamp(L["mid_frames"][0].crop(0, 0, W, L["mid_frames"][0].h)); cv.stamp(L["plain_frames"][0], 0, mc.PLAIN_TOP)
    import moon_ground as mg
    from moon import profile, ridge_y
    import moon_scene as ms
    pad = ms.PREVIEW_PAD
    pts = profile(W, seed=7, base=292, amp=60, pad=pad)
    faces = ms.segment_faces(pts)
    G = {"body": L["body"], "depth": L["depth"], **{"crust_" + f: L[f] for f in ("lit", "flat", "shade")}}
    mg.compose(cv, lambda x: ridge_y(pts, x), 0, W,
               lambda x: faces[min(sum(1 for p in pts[1:] if p[0] <= x), len(faces) - 1)], G)
    py = ridge_y(pts, pad[0] + pad[1] // 2)
    cv.stamp(Canvas.from_image("assets/sprites/landing_pad.png").crop(0, 0, 80, 28), pad[0] - 8, py - 10)
    cv.stamp(Canvas.from_image("assets/sprites/lander.png").crop(0, 0, 32, 32), pad[0] + pad[1] // 2 - 16, py - 25)
    return cv


def export(world: str, L: dict) -> None:
    au.stack(L["sky_frames"]).save(f"assets/bg/{world}_sky.png", preview=False)
    au.stack(L["cloud_frames"]).save(f"assets/bg/{world}_clouds.png", preview=False)
    L["planet"].save(f"assets/bg/{world}_planet.png", preview=False)
    L["far"].save(f"assets/bg/{world}_far.png", preview=False)
    au.stack(L["mid_frames"]).save(f"assets/bg/{world}_mid.png", preview=False)
    au.stack(L["plain_frames"]).save(f"assets/bg/{world}_plain.png", preview=False)
    for f in ("lit", "flat", "shade"):
        L[f].save(f"assets/tiles/{world}_ground_{f}.png", preview=False)
    L["body"].save(f"assets/tiles/{world}_body.png", tiled=True, preview=False)
    L["depth"].save(f"assets/tiles/{world}_depth.png", preview=False)
    L["rocks"].save(f"assets/sprites/{world}_rocks.png", preview=False)
    with open("assets/bg/luna_layers.json") as f:
        meta = json.load(f)
    meta.pop("war", None)                                      # sem discos voadores: a Lua tem os dela
    cx, cy, r = mc.PLANET
    hexc = lambda n: "#" + "%02x%02x%02x" % tuple(PALETTE_RGB[resolve(n)])
    meta.update({
        "notes": f"Gerado por art/src/bg/world_scene.py (pixel-art, estilo fofo, {THEMES[world]['name']}). Posições em px na tela 640x360.",
        "planet_pos": [cx - r - 12, cy - r - 12], "strip_depth": mc.CRUST_D, "depth_depth": mc.DEPTH_D,
        "deep_color": hexc(THEMES[world]["deep"]),
        "body_texture": f"res://assets/tiles/{world}_body.png", "depth_texture": f"res://assets/tiles/{world}_depth.png",
        "clouds": {"y": 0, "speed": 3},
    })
    meta["anim"]["clouds"] = {"frames": FR, "ms": 300}
    with open(f"assets/bg/{world}_layers.json", "w") as f:
        json.dump(meta, f, indent=2)


if __name__ == "__main__":
    which = sys.argv[1] if len(sys.argv) > 1 else "nuvens"
    worlds = list(THEMES) if which == "all" else [which]
    for w in worlds:
        L = build(w)
        if "--export" in sys.argv:
            export(w, L)
            print("exportado", w)
        else:
            preview(w, L).save(f"art/previews/world_{w}.png", preview=False)
            print("ok", w)

# caminhos literais dos assets (o pre-commit procura a fonte de cada PNG pelo caminho escrito no script):
# assets/bg/nuvens_sky.png assets/bg/nuvens_clouds.png assets/bg/nuvens_planet.png
# assets/bg/nuvens_far.png assets/bg/nuvens_mid.png assets/bg/nuvens_plain.png
# assets/bg/cogumelos_sky.png assets/bg/cogumelos_clouds.png assets/bg/cogumelos_planet.png
# assets/bg/cogumelos_far.png assets/bg/cogumelos_mid.png assets/bg/cogumelos_plain.png
# assets/bg/sorvete_sky.png assets/bg/sorvete_clouds.png assets/bg/sorvete_planet.png
# assets/bg/sorvete_far.png assets/bg/sorvete_mid.png assets/bg/sorvete_plain.png
# assets/bg/jardim_sky.png assets/bg/jardim_clouds.png assets/bg/jardim_planet.png
# assets/bg/jardim_far.png assets/bg/jardim_mid.png assets/bg/jardim_plain.png
# assets/bg/bolhas_sky.png assets/bg/bolhas_clouds.png assets/bg/bolhas_planet.png
# assets/bg/bolhas_far.png assets/bg/bolhas_mid.png assets/bg/bolhas_plain.png
# assets/tiles/nuvens_ground_lit.png assets/tiles/nuvens_ground_flat.png assets/tiles/nuvens_ground_shade.png
# assets/tiles/nuvens_body.png assets/tiles/nuvens_depth.png assets/tiles/cogumelos_ground_lit.png
# assets/tiles/cogumelos_ground_flat.png assets/tiles/cogumelos_ground_shade.png assets/tiles/cogumelos_body.png
# assets/tiles/cogumelos_depth.png assets/tiles/sorvete_ground_lit.png assets/tiles/sorvete_ground_flat.png
# assets/tiles/sorvete_ground_shade.png assets/tiles/sorvete_body.png assets/tiles/sorvete_depth.png
# assets/tiles/jardim_ground_lit.png assets/tiles/jardim_ground_flat.png assets/tiles/jardim_ground_shade.png
# assets/tiles/jardim_body.png assets/tiles/jardim_depth.png assets/tiles/bolhas_ground_lit.png
# assets/tiles/bolhas_ground_flat.png assets/tiles/bolhas_ground_shade.png assets/tiles/bolhas_body.png
# assets/tiles/bolhas_depth.png assets/sprites/nuvens_rocks.png assets/sprites/cogumelos_rocks.png
# assets/sprites/sorvete_rocks.png assets/sprites/jardim_rocks.png assets/sprites/bolhas_rocks.png
