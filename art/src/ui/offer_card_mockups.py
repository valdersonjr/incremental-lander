"""Maquetes do mini-cartão do pedido (2026-10-06, skill pixel-art) para o usuário escolher a versão mais intuitiva.

Usuário: "o menu de seleção de missão está o mais intuitivo possível?" → crítica: "×1/×1,5/×2,2" é abstrato para
criança, a barra de gás cheia quer dizer "gasta muito" (invertido), o botão VAMOS tem a mesma cor da escolha.
Cada versão é desenhada em 1x (640x360) com as peças reais (painel, botões, fonte, atlas kids, cargas) por cima de
uma captura do jogo (.godot/captures/flight_ui_preview_last.png) e ampliada 2x/4x para a página HTML.

Rodar da raiz:  python3 art/src/ui/offer_card_mockups.py  -> art/previews/offer_card/*.png + index.html
"""
import json
import sys

sys.path.insert(0, ".claude/skills/pixel-art/scripts")
from PIL import Image
from pixelart import Canvas, COLOR_NAMES, PALETTE_RGB

OUT = "art/previews/offer_card"
CAP = ".godot/captures/flight_ui_preview_last.png"
OLD_CARD = (136, 292, 504, 354)                                 # cartão atual em 1x (x0, y0, x1, y1)


def rgb(name: str) -> tuple:
    return PALETTE_RGB[COLOR_NAMES.index(name)] + (255,)


# --- peças reais do jogo ----------------------------------------------------------------------------------------

KIDS = Image.open("assets/ui/kids.png").convert("RGBA")
KIDS_NAMES = json.load(open("assets/ui/kids.json"))["names"]
CARGO = Image.open("assets/sprites/cargo.png").convert("RGBA")
CARGO_NAMES = json.load(open("assets/sprites/cargo.json"))["names"]
UI = "assets/ui/luna/"


def kid(name: str) -> Image.Image:
    i = KIDS_NAMES.index(name)
    return KIDS.crop((i * 24, 0, i * 24 + 24, 24))


def cargo(name: str) -> Image.Image:
    i = CARGO_NAMES.index(name)
    return CARGO.crop((i * 16, 0, i * 16 + 16, 16))


def nine(path: str, w: int, h: int, mx: int, my: int) -> Image.Image:
    """9-slice como o StyleBoxTexture do tema (margens mx/my, miolo esticado)."""
    src = Image.open(path).convert("RGBA")
    sw, sh = src.size
    out = Image.new("RGBA", (w, h))
    xs = [(0, mx, 0, mx), (mx, sw - mx, mx, w - mx), (sw - mx, sw, w - mx, w)]
    ys = [(0, my, 0, my), (my, sh - my, my, h - my), (sh - my, sh, h - my, h)]
    for sx0, sx1, dx0, dx1 in xs:
        for sy0, sy1, dy0, dy1 in ys:
            if dx1 > dx0 and dy1 > dy0:
                part = src.crop((sx0, sy0, sx1, sy1)).resize((dx1 - dx0, dy1 - dy0), Image.NEAREST)
                out.alpha_composite(part, (dx0, dy0))
    return out


def recolor(img: Image.Image, mapping: dict) -> Image.Image:
    out = img.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            c = px[x, y]
            if c[3] and c[:3] in mapping:
                px[x, y] = mapping[c[:3]] + (255,)
    return out


# botão verde de ir: rampa violeta do botão primário → rampa verde
GREEN = {PALETTE_RGB[COLOR_NAMES.index(a)]: PALETTE_RGB[COLOR_NAMES.index(b)]
         for a, b in [("violet", "emerald"), ("purple", "green"), ("cream", "leaf"), ("white", "ice")]}


def button(w: int, h: int, kind: str = "normal") -> Image.Image:
    if kind == "go":
        return recolor(nine(UI + "button_primary.png", w, h, 6, 5), GREEN)
    return nine(UI + ("button_primary.png" if kind == "on" else "button_normal.png"), w, h, 6, 5)


# --- fonte do jogo (BMFont) --------------------------------------------------------------------------------------

FONT = Image.open("assets/ui/font.png").convert("RGBA")
GLYPH = {}
for line in open("assets/ui/font.fnt", encoding="utf-8"):
    if line.startswith("char "):
        f = dict(kv.split("=") for kv in line.split()[1:])
        GLYPH[int(f["id"])] = {k: int(v) for k, v in f.items()}


def text_w(s: str, scale: int = 1) -> int:
    return sum(GLYPH[ord(c)]["xadvance"] for c in s) * scale


def text(img: Image.Image, x: int, y: int, s: str, color: str, scale: int = 1, shadow: bool = True) -> None:
    """Desenha s com a fonte do jogo (glifos brancos tingidos) e sombra ink 1px, como o Label do tema."""
    for pass_color, off in ([("ink", scale)] if shadow else []) + [(color, 0)]:
        cx = x
        for c in s:
            g = GLYPH[ord(c)]
            gl = FONT.crop((g["x"], g["y"], g["x"] + g["width"], g["y"] + g["height"]))
            if scale > 1:
                gl = gl.resize((gl.width * scale, gl.height * scale), Image.NEAREST)
            tint = Image.new("RGBA", gl.size, rgb(pass_color))
            tint.putalpha(gl.getchannel("A"))
            img.alpha_composite(tint, (cx + g["xoffset"] * scale + off, y + g["yoffset"] * scale + off))
            cx += g["xadvance"] * scale


# --- figuras novas (rascunho; viram células do atlas kids se aprovadas) --------------------------------------

def mini_pad(half: int, lit: bool = False) -> Image.Image:
    """Plataforma de pouso em miniatura (largura 2*half): mesma receita do pad_s do atlas kids."""
    w = max(26, half * 2 + 4)
    m = w // 2
    k = Canvas(w, 12)
    x0 = m - half
    k.rect(x0, 4, half * 2, 3, "mist"); k.hline(x0, m - 1 + half, 4, "white"); k.hline(x0, m - 1 + half, 6, "steel")
    for x in (x0 + 1, m - 1 + half - 1):
        k.vline(x, 7, 9, "lilac_grey")
    k.px(x0, 3, "gold" if lit else "aqua"); k.px(m - 1 + half, 3, "gold" if lit else "aqua")
    k.outline("ink")
    return k.to_image()


PADS = {"normal": 11, "narrow": 7, "tight": 4}                  # meia largura do topo de cada plataforma


def tank(w: int, left: float, spend: float) -> Image.Image:
    """Tanque: o que sobra depois da viagem (aqua) + o pedaço que a viagem gasta (laranja, xadrez) + vazio."""
    k = Canvas(w, 8)
    k.rect(0, 0, w, 8, "ink")
    k.rect(1, 1, w - 2, 6, "shadow")
    inner = w - 2
    a = round(inner * max(left - spend, 0.0))
    b = round(inner * left)
    if a:
        k.rect(1, 1, a, 6, "aqua"); k.hline(1, a, 1, "ice"); k.hline(1, a, 6, "sea")
    if b > a:
        k.rect(1 + a, 1, b - a, 6, "amber")
        k.dither_rect(1 + a, 1, b - a, 6, "amber", "orange", 0.5, pattern="checker")
        k.hline(1 + a, b, 1, "honey")
    return k.to_image()


def drop_icon(state: str) -> Image.Image:
    """Gotinha 7x9: "full" (aqua) = sobra depois da viagem; "spend" (laranja) = esta viagem gasta; "empty" = já foi."""
    k = Canvas(9, 11)
    rows = ["...a...", "...a...", "..aaa..", ".aaaaa.", "aaaaaaa", "aaaaaaa", "aaaaaaa", ".aaaaa.", "..aaa.."]
    if state == "full":
        k.paint(rows, {"a": "aqua"}, x=1, y=1)
        k.px(3, 6, "ice"); k.px(3, 7, "white")
        for x, y in [(5, 8), (6, 7), (6, 6), (4, 9)]:
            k.px(x, y, "sea")
        k.outline("ink")
    elif state == "spend":
        k.paint(rows, {"a": "amber"}, x=1, y=1)
        k.px(3, 6, "honey"); k.px(3, 7, "lemon")
        for x, y in [(5, 8), (6, 7), (6, 6), (4, 9)]:
            k.px(x, y, "orange")
        k.outline("ink")
    else:
        k.paint(rows, {"a": "shadow"}, x=1, y=1)
        k.outline("slate")
    return k.to_image()


def play() -> Image.Image:
    k = Canvas(7, 9)
    for i in range(4):
        k.vline(i + 1, 1 + i, 7 - i, "white")
    k.outline("ink")
    return k.to_image()


def frame(img: Image.Image, x: int, y: int, w: int, h: int, color: str = "gold") -> None:
    """Moldura de seleção (1 px dourado, por fora do botão) — mesma cor do pino escolhido."""
    c = rgb(color)
    for i in range(w):
        img.putpixel((x + i, y), c); img.putpixel((x + i, y + h - 1), c)
    for j in range(h):
        img.putpixel((x, y + j), c); img.putpixel((x + w - 1, y + j), c)


def star_strip(n: int) -> Image.Image:
    s = kid("star_on").crop((6, 6, 18, 18))                     # estrela 11x11 no meio da célula
    out = Image.new("RGBA", (n * 8 + 4, 12))
    for i in range(n):
        out.alpha_composite(s, (i * 8, 0))
    return out


# --- pedidos de exemplo (números ilustrativos) -------------------------------------------------------------------

SIMPLE = {"face": "rat_simple", "cargo": "box", "left": 1.0, "spend": 0.12, "tier": "narrow",
          "pay": {"normal": 36, "narrow": 54, "tight": 79}, "stars": [], "star": 0}
SOFT = {"face": "rat_soft", "cargo": "cake", "left": 0.8, "spend": 0.35, "tier": "narrow", "star": 2,
        "pay": {"normal": 150, "narrow": 225, "tight": 330}, "stars": [1, 2, 3],
        "star_pay": {1: 160, 2: 225, 3: 310}}
TIERS = ["normal", "narrow", "tight"]


def card_panel(w: int, h: int) -> tuple[Image.Image, int, int]:
    """Painel do cartão (mesmo 9-slice do tema) e a origem dele em 1x, encostado embaixo e centralizado."""
    return nine(UI + "panel.png", w, h, 8, 8), 320 - w // 2, 354 - h


def head(c: Image.Image, o: dict, x: int, y: int) -> int:
    """Ratinho (24 nativo) + carga (16 em 2x = 32). Devolve o x seguinte."""
    c.alpha_composite(kid(o["face"]), (x, y + 4))
    cg = cargo(o["cargo"]).resize((32, 32), Image.NEAREST)
    c.alpha_composite(cg, (x + 26, y))
    return x + 62


# --- versões ------------------------------------------------------------------------------------------------------

def version_a(o: dict) -> Image.Image:
    """A — Prêmio em cada plataforma: cada botão mostra a plataforma e quanto ela paga; tanque com o pedaço gasto."""
    has_stars = bool(o["stars"])
    W, H = 300, 66 if not has_stars else 82
    c, ox, oy = card_panel(W, H)
    x = head(c, o, 10, (H - 32) // 2 - 1)
    gy = 12                                                     # tanque em cima, plataformas embaixo
    c.alpha_composite(drop_icon("full"), (x, gy - 2))
    c.alpha_composite(tank(118, o["left"], o["spend"]), (x + 12, gy))
    by = gy + 14
    for i, t in enumerate(TIERS):
        bx = x + i * 44
        on = t == o["tier"]
        c.alpha_composite(button(40, 30, "on" if on else "normal"), (bx, by))
        pad = mini_pad(PADS[t], on)
        c.alpha_composite(pad, (bx + 7, by + 3))
        s = "+%d" % o["pay"][t]
        text(c, bx + 20 - text_w(s) // 2, by + 16, s, "ink" if on else "gold", shadow=not on)
        if on:
            frame(c, bx - 1, by - 1, 42, 32)
    if has_stars:
        sy = by + 34
        for i, st in enumerate(o["stars"]):
            bx = x + i * 44
            on = st == o["star"]
            c.alpha_composite(button(40, 14, "on" if on else "normal"), (bx, sy))
            ss = star_strip(st)
            c.alpha_composite(ss, (bx + 20 - ss.width // 2 + 1, sy + 1))
            if on:
                frame(c, bx - 1, sy - 1, 42, 16)
    gx = W - 10 - 60                                            # botão de ir: verde, nave + setinha
    gyy = (H - 40) // 2
    c.alpha_composite(button(60, 40, "go"), (gx, gyy))
    c.alpha_composite(kid("ship"), (gx + 8, gyy + 7))
    c.alpha_composite(play(), (gx + 38, gyy + 15))
    return place(c, ox, oy)


def version_b(o: dict) -> Image.Image:
    """B — Clique na plataforma e vai: as 3 plataformas SÃO os botões de partir (sem VAMOS separado). A escolhida
    fica verde com a navezinha pousada nela; gás em gotinhas (aqua sobra, laranja esta viagem gasta)."""
    has_stars = bool(o["stars"])
    W, H = 372, 70 if not has_stars else 86
    c, ox, oy = card_panel(W, H)
    x = head(c, o, 10, (H - 32) // 2 - 1)
    n = 5                                                       # 5 gotinhas = tanque cheio
    full = round(o["left"] * n)
    cost = max(1, round(o["spend"] * n))
    for i in range(n):                                          # coluna de gotinhas: de baixo para cima
        st = "full" if i < full - cost else ("spend" if i < full else "empty")
        c.alpha_composite(drop_icon(st), (x, H - 18 - i * 10))
    x += 16
    by = 8
    for i, t in enumerate(TIERS):
        bx = x + i * 92
        on = t == o["tier"]
        c.alpha_composite(button(86, 54, "go" if on else "normal"), (bx, by))
        pad = mini_pad({"normal": 17, "narrow": 11, "tight": 6}[t], on)
        c.alpha_composite(pad, (bx + 43 - pad.width // 2, by + 38))
        s = "+%d" % o["pay"][t]
        coin = kid("coin").crop((6, 9, 18, 21))
        tw = text_w(s) + 13
        c.alpha_composite(coin, (bx + 43 - tw // 2, by + 4))
        text(c, bx + 43 - tw // 2 + 13, by + 5, s, "ink" if on else "gold", shadow=not on)
        if on:
            c.alpha_composite(kid("ship"), (bx + 31, by + 18))
            frame(c, bx - 1, by - 1, 88, 56)
    if has_stars:
        sy = by + 60
        for i, st in enumerate(o["stars"]):
            bx = x + 70 + i * 50
            on = st == o["star"]
            c.alpha_composite(button(44, 14, "on" if on else "normal"), (bx, sy))
            ss = star_strip(st)
            c.alpha_composite(ss, (bx + 22 - ss.width // 2 + 1, sy + 1))
            if on:
                frame(c, bx - 1, sy - 1, 46, 16)
    return place(c, ox, oy)


def version_d(o: dict) -> Image.Image:
    """D — B sem gás (usuário, 2026-10-06: "não precisa mostrar o combustível"; botão verde de ir não faz falta):
    ratinho + carga e as 3 plataformas, que são os botões de partir."""
    has_stars = bool(o["stars"])
    W, H = 340, 70 if not has_stars else 86
    c, ox, oy = card_panel(W, H)
    x = head(c, o, 10, (H - 32) // 2 - 1) + 2
    by = 8
    for i, t in enumerate(TIERS):
        bx = x + i * 88
        on = t == o["tier"]
        c.alpha_composite(button(82, 54, "on" if on else "normal"), (bx, by))
        pad = mini_pad({"normal": 17, "narrow": 11, "tight": 6}[t], on)
        c.alpha_composite(pad, (bx + 41 - pad.width // 2, by + 38))
        s = "+%d" % o["pay"][t]
        coin = kid("coin").crop((6, 9, 18, 21))
        tw = text_w(s) + 13
        c.alpha_composite(coin, (bx + 41 - tw // 2, by + 4))
        text(c, bx + 41 - tw // 2 + 13, by + 5, s, "ink" if on else "gold", shadow=not on)
        if on:
            c.alpha_composite(kid("ship"), (bx + 29, by + 18))
            frame(c, bx - 1, by - 1, 84, 56)
    if has_stars:
        sy = by + 60
        for i, st in enumerate(o["stars"]):
            bx = x + 66 + i * 50
            on = st == o["star"]
            c.alpha_composite(button(44, 14, "on" if on else "normal"), (bx, sy))
            ss = star_strip(st)
            c.alpha_composite(ss, (bx + 22 - ss.width // 2 + 1, sy + 1))
            if on:
                frame(c, bx - 1, sy - 1, 46, 16)
    return place(c, ox, oy)


def version_c(o: dict) -> Image.Image:
    """C — Ajuste mínimo: mesmo cartão de hoje, mas plataformas desenhadas no lugar de ×N, tanque com o pedaço gasto,
    escolha com moldura dourada e botão de ir verde com setinha."""
    has_stars = bool(o["stars"])
    W, H = 372, 62 if not has_stars else 74
    c, ox, oy = card_panel(W, H)
    x = head(c, o, 10, (H - 32) // 2 - 1)
    c.alpha_composite(drop_icon("full"), (x, 9))
    c.alpha_composite(tank(96, o["left"], o["spend"]), (x + 12, 11))
    by = 24
    for i, t in enumerate(TIERS):
        bx = x + i * 36
        on = t == o["tier"]
        c.alpha_composite(button(32, 20, "on" if on else "normal"), (bx, by))
        c.alpha_composite(mini_pad(PADS[t], on), (bx + 3, by + 3))
        if on:
            frame(c, bx - 1, by - 1, 34, 22)
    if has_stars:
        sy = by + 24
        for i, st in enumerate(o["stars"]):
            bx = x + i * 36
            on = st == o["star"]
            c.alpha_composite(button(32, 14, "on" if on else "normal"), (bx, sy))
            ss = star_strip(st)
            c.alpha_composite(ss, (bx + 16 - ss.width // 2 + 1, sy + 1))
            if on:
                frame(c, bx - 1, sy - 1, 34, 16)
    px = x + 118
    pay = o["pay"][o["tier"]] if not o["stars"] else o["star_pay"][o["star"]]
    c.alpha_composite(kid("coins"), (px, (H - 24) // 2))
    text(c, px + 28, (H - 22) // 2, "+%d" % pay, "gold", scale=2)
    gx = W - 10 - 56
    gyy = (H - 36) // 2
    c.alpha_composite(button(56, 36, "go"), (gx, gyy))
    c.alpha_composite(kid("ship"), (gx + 6, gyy + 5))
    c.alpha_composite(play(), (gx + 36, gyy + 13))
    return place(c, ox, oy)


def current(o: dict) -> Image.Image:
    return BASE.copy()


def place(card: Image.Image, ox: int, oy: int) -> Image.Image:
    img = CLEAN.copy()
    img.alpha_composite(card, (ox, oy))
    return img


def clean_base() -> Image.Image:
    """Captura sem o cartão atual: o chão de queijo à esquerda do cartão repetido por baixo dele (só para a maquete)."""
    img = BASE.copy()
    x0, y0, x1, y1 = OLD_CARD
    patch = img.crop((0, y0, x0, 360))
    for x in range(x0, x1, x0):
        img.alpha_composite(patch.crop((0, 0, min(x0, x1 - x), patch.height)), (x, y0))
    return img


BASE = Image.open(CAP).convert("RGBA").resize((640, 360), Image.NEAREST)
CLEAN = clean_base()

if __name__ == "__main__":
    import os
    os.makedirs(OUT, exist_ok=True)
    BASE.save(f"{OUT}/atual.png")
    for name, fn in [("a", version_a), ("b", version_b), ("c", version_c), ("d", version_d)]:
        for tag, o in [("simples", SIMPLE), ("estrelas", SOFT)]:
            im = fn(o)
            im.save(f"{OUT}/{name}_{tag}.png")
            crop = im.crop((120, 262, 520, 360)).resize((1600, 392), Image.NEAREST)
            crop.save(f"{OUT}/{name}_{tag}_zoom.png")
    BASE.crop((120, 262, 520, 360)).resize((1600, 392), Image.NEAREST).save(f"{OUT}/atual_zoom.png")
    print("ok", OUT)
