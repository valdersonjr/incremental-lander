"""Propostas de estilo do lander (32x32) para o usuario escolher. Skill pixel-art.
Mesmo contrato do jogo: origem (16,16), sapatas na linha y=24. Gera art/previews/lander_styles_compare.png.
Rodar da raiz: python3 art/src/sprites/lander_styles.py"""
import sys; sys.path.insert(0, ".claude/skills/pixel-art/scripts"); sys.path.insert(0, "art/src/sprites")
from pixelart import *
import lander_apollo as apollo

E4 = ["................"] * 4


def build(left, legend, extra=None, shade=None, outline=True) -> Canvas:
    cv = Canvas.grid32()
    cv.paint(left, legend)
    cv.mirror_x()
    if shade:  # lado direito mais escuro (luz de cima-esquerda)
        for y in range(32):
            for x in range(17, 32):
                v = cv.get(x, y)
                if v is not None and COLOR_NAMES[v] in shade:
                    cv.px(x, y, shade[COLOR_NAMES[v]])
    for rows, leg, x, y in (extra or []):
        cv.paint(rows, leg, x=x, y=y)
    if outline:
        cv.outline("ink")
    return cv


def cone_flame(frame: int, cols: list[str], core: str, top: int = 20) -> Canvas:
    fl = Canvas.grid32()
    L = [7, 10, 8, 11][frame % 4]
    wide = [2.6, 3.0, 2.4, 3.2][frame % 4]
    for i in range(L):
        t = i / max(1, L - 1)
        half = int(round(wide * (1.0 - t) ** 0.8))
        c = cols[min(len(cols) - 1, int(t * (len(cols) - 1) + 0.5))]
        fl.hline(16 - half - 1, 15 + half + 1 if half > 0 else 16, top + i, c)
        if i < 3 and half > 1:
            fl.hline(16 - half + 1, 15 + half - 1, top + i, core)
    fl.px(15 if frame % 2 else 16, top + L, cols[-2])
    return fl


# ---------------- B: futurista (branco + turquesa, plasma ciano)
B_LEFT = E4 + [
    "...............M", "..............MM", "............MMmm", "...........Mmmmm",
    "..........Mmmvvv", "..........mmmVVV", ".........mmmmmmm", ".........sssssss",
    "........tttttttt", "........ssssssss", "........llllllll", ".........kkkkkkk",
    "...........kkkkk", ".......p.......n", "......p.......nn", ".....p.......nnN",
    ".....p..........", "....p...........", "....p...........", "...p............",
    "..ffff..........",
]
B_LEG = {"M": "white", "m": "mist", "s": "steel", "v": "aqua", "V": "teal", "t": "sea",
         "l": "lilac_grey", "k": "slate", "p": "lilac_grey", "f": "slate", "n": "charcoal", "N": "deep_teal"}
B_SHADE = {"white": "mist", "mist": "steel", "steel": "lilac_grey", "aqua": "sea"}


def b_body(): return build(B_LEFT, B_LEG, shade=B_SHADE)
def b_flame(i): return cone_flame(i, ["white", "ice", "aqua", "sea", "teal", "deep_teal", "navy"], "white")


# ---------------- C: industrial (cabine amarela, faixas de perigo, carga ferrugem, pernas grossas)
C_LEFT = E4 + [
    "................", "...........kkkkk", "..........yyyyyy", "..........yyyyyy",
    "..........yyyyyy", "..........YYYYYY", "........dddddddd", "........hhHHhhHH",
    "........hHHhhHHh", "........rrrrrrrr", "........rrRrrrRr", "........RRRRRRRR",
    "........dddddddd", "......PP......nn", "......PP.....nnN", ".....PP.......nN",
    ".....PP.........", ".....PP.........", "....PP..........", "....PP..........",
    "...FFFF.........",
]
C_LEG = {"k": "charcoal", "y": "gold", "Y": "amber", "d": "charcoal", "h": "gold", "H": "ink",
         "r": "rust", "R": "wine", "P": "slate", "F": "charcoal", "n": "charcoal", "N": "slate"}
C_WIN = (["www", "wWw"], {"w": "sky", "W": "navy"}, 12, 7)
C_SHADE = {"gold": "amber", "rust": "wine"}


def c_body(): return build(C_LEFT, C_LEG, extra=[C_WIN], shade=C_SHADE)
def c_flame(i): return apollo.flame(i)


# ---------------- D: fofo/retro (capsula vermelha, janela grande, pernas curtas)
D_LEFT = E4 + [
    "................", "............rrrr", "..........rRRrrr", ".........rRrrrrr",
    ".........rRrrrrr", ".........rrrrrrr", ".........rrrrrrr", "..........rrrrrr",
    "...........WWWWW", "..........wwwwww", "..........wwwwww", "...........WWWWW",
    "............ddnn", "........p....nnN", "........p.......", ".......p........",
    ".......p........", ".......p........", ".......p........", "......p.........",
    ".....fff........",
]
D_LEG = {"r": "red", "R": "coral", "W": "slate", "w": "white", "d": "charcoal", "n": "charcoal",
         "N": "slate", "p": "lilac_grey", "f": "slate"}
D_WIN = ([".www.", "wwWww", "wWWWw", ".www."], {"w": "pale_sky", "W": "sky"}, 11, 8)
D_SHADE = {"red": "crimson", "coral": "red", "white": "mist"}


def d_body(): return build(D_LEFT, D_LEG, extra=[D_WIN], shade=D_SHADE)
def d_flame(i): return apollo.flame(i)


# ---------------- E: vetorial (homenagem ao Lunar Lander de 1979: so linhas)
def e_body():
    """Linhas nas bordas externas E entre materiais diferentes (cabine | estagio | bocal | pernas)."""
    solid = apollo.body()
    ink = NAME_TO_INDEX["ink"]
    group = {"white": 0, "mist": 0, "steel": 0, "slate": 1, "sky": 0, "navy": 0, "gold": 2, "lemon": 2,
             "honey": 2, "copper": 2, "amber": 2, "terracotta": 2, "charcoal": 3, "lilac_grey": 4}
    def g(x, y):
        v = solid.get(x, y)
        return None if v is None or v == ink else group.get(COLOR_NAMES[v], 5)
    edge = Canvas.grid32()
    for y in range(32):
        for x in range(32):
            gx = g(x, y)
            if gx is None:
                continue
            if any(g(x + dx, y + dy) != gx for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                edge.px(x, y, "mist")
    return edge


def e_flame(i):
    fl = Canvas.grid32()
    L = [6, 9, 7, 10][i % 4]
    fl.line(14, 20, 16 if i % 2 else 15, 20 + L, "white")
    fl.line(17, 20, 16 if i % 2 else 15, 20 + L, "white")
    return fl


STYLES = [("A  Apollo (atual)", apollo.body, apollo.flame), ("B  Futurista", b_body, b_flame),
          ("C  Industrial", c_body, c_flame), ("D  Fofo/retro", d_body, d_flame), ("E  Vetorial", e_body, e_flame)]


if __name__ == "__main__":
    from PIL import ImageDraw
    cell = 40
    sheet = Canvas(cell * len(STYLES), cell * 2, "ink")
    sheet.scatter({(x, y) for x in range(sheet.w) for y in range(sheet.h)}, "shadow", 0.02, seed=5, min_dist=3)
    for i, (name, body, flame) in enumerate(STYLES):
        b = body()
        print(f"{name:20s} cores={len(b.colors_used())} lint={b.lint(max_colors=16)}")
        sheet.stamp(b, i * cell + 4, 2)
        f = flame(1)
        f.stamp(body())
        sheet.stamp(f, i * cell + 4, cell + 2)
    path = sheet.preview("art/previews/lander_styles_compare.png", scale=6, grid=False, bg="dark", show_1x=False)
    from PIL import Image
    im = Image.open(path).convert("RGB")
    top = Image.new("RGB", (im.width, im.height + 26), (20, 16, 24))
    top.paste(im, (0, 26))
    d = ImageDraw.Draw(top)
    for i, (name, _, _) in enumerate(STYLES):
        d.text((i * cell * 6 + 10, 6), name, fill=(230, 230, 230))
    top.save(path)
    print(path)
