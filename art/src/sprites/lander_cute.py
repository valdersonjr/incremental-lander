"""Lander FOFO com gatinho astronauta (teste de direcao de arte, 2026-10-04). Skill pixel-art, padrao cute-style.
32x32, mesmo contrato do lander atual: origem (16,16), sapatas na linha y=24.
v4: gatinho contornado (orelhas pontudas, bigodes, ombros) sentado DENTRO da cupula; anel escuro separa cupula do
casco; casco largo e achatado (disco) com pernas mecanicas — para a nave nao parecer o corpo do gato.
Gera art/previews/lander_cute_steps.png. Rodar da raiz: python3 art/src/sprites/lander_cute.py"""
import sys; sys.path.insert(0, ".claude/skills/pixel-art/scripts"); sys.path.insert(0, "art/src/sprites")
from pixelart import *
from lander_styles import b_body, cone_flame

FLAME = ["white", "ice", "aqua", "sea", "teal", "deep_teal", "navy"]


def in_dome(x: int, y: int) -> bool:
    """Cupula: elipse centrada em (16, 9.5), rx 9.5, ry 8; cortada pelo casco a partir de y=16."""
    return ((x + 0.5 - 16) / 9.5) ** 2 + ((y + 0.5 - 9.5) / 8) ** 2 <= 1 and y <= 15


def hull(cv: Canvas) -> None:
    """Casco largo e achatado (disco), anel escuro na base da cupula, bocal e pernas mecanicas."""
    rows = {16: (5, 26), 17: (3, 28), 18: (3, 28), 19: (5, 26)}
    for y, (x0, x1) in rows.items():
        cv.hline(x0, x1, y, "white" if y == 16 else "mist")
    cv.hline(3, 28, 18, "sea")                      # faixa turquesa (identidade)
    shade = {16: "steel", 17: "steel", 18: "teal", 19: "lilac_grey"}
    for y, (x0, x1) in rows.items():                # ponta direita na sombra (luz de cima-esquerda)
        cv.hline(max(x0, 24), x1, y, shade[y])
    cv.hline(5, 23, 19, "steel")
    for x in (6, 11, 20, 25):                       # luzinhas no disco
        cv.px(x, 17, "aqua" if x < 20 else "sea")
    cv.hline(7, 24, 16, "slate")                    # anel escuro: cupula | casco
    cv.hline(10, 21, 16, "charcoal")
    cv.hline(13, 18, 20, "slate"); cv.hline(14, 17, 21, "charcoal")   # bocal
    for x, y in ((7, 20), (6, 21), (5, 22), (5, 23)):                 # pernas mecanicas + sapatas
        cv.px(x, y, "steel"); cv.px(31 - x, y, "lilac_grey")
    cv.hline(3, 7, 24, "steel"); cv.hline(24, 28, 24, "lilac_grey")


def cat(blink: bool = False, details: bool = True) -> Canvas:
    """Gatinho em canvas proprio, contornado, para ler como personagem separado do vidro."""
    c = Canvas.grid32()
    c.ellipse(15.5, 10.5, 4.5, 3.5, "amber")        # cabeca
    for x, y in ((11, 5), (12, 5), (11, 6), (12, 6), (13, 6), (11, 7), (12, 7), (13, 7), (14, 7)):
        c.px(x, y, "amber"); c.px(31 - x, y, "amber")  # orelhas pontudas
    c.hline(11, 20, 15, "amber")                    # ombrinhos (sentado dentro da cupula)
    for x in range(18, 21):                         # sombra lado direito
        for y in range(4, 16):
            if c.get(x, y) == NAME_TO_INDEX["amber"] and (x - 18) + (y - 4) * 0.2 > 1.2:
                c.px(x, y, "copper")
    c.outline("ink")
    c.px(12, 6, "pink"); c.px(19, 6, "pink")        # dentro da orelha
    for x0 in (12, 18):                             # olhos 2x3, baixos e afastados
        if blink:
            c.hline(x0, x0 + 1, 11, "ink")
        else:
            c.rect(x0, 9, 2, 3, "ink")
            if details:
                c.px(x0, 9, "white")
    c.hline(14, 17, 12, "cream"); c.hline(15, 16, 13, "cream")  # focinho
    c.hline(15, 16, 11, "pink")                     # nariz
    if details:
        c.px(11, 12, "pink"); c.px(20, 12, "pink")  # bochechas
    return c


def whiskers(cv: Canvas) -> None:
    for x, y in ((8, 11), (9, 11), (10, 11), (8, 13), (9, 12)):
        cv.px(x, y, "white"); cv.px(31 - x, y, "white")


def dome(cv: Canvas, with_cat: bool, blink: bool = False, details: bool = True) -> None:
    for y in range(32):
        for x in range(32):
            if in_dome(x, y):
                cv.px(x, y, "sky" if (x - 19) + (y - 2) * 0.35 > 3.5 else "pale_sky")
    if with_cat:
        c = cat(blink, details)
        for y in range(32):
            for x in range(32):
                v = c.get(x, y)
                if v is not None and in_dome(x, y):
                    cv.px(x, y, COLOR_NAMES[v])
        whiskers(cv)
    for x, y in ((9, 4), (8, 5), (8, 6), (10, 3), (11, 2)):  # reflexo do vidro (cima-esquerda)
        if cv.get(x, y) in (NAME_TO_INDEX["pale_sky"], NAME_TO_INDEX["sky"]):
            cv.px(x, y, "white")


def body(step: int = 4, blink: bool = False) -> Canvas:
    cv = Canvas.grid32()
    dome(cv, with_cat=step >= 3, blink=blink, details=step >= 4)
    hull(cv)
    cv.outline("ink")
    return cv


def thrust(i: int) -> Canvas:
    cv = cone_flame(i, FLAME, "white", top=21)
    cv.stamp(body())
    return cv


if __name__ == "__main__":
    from PIL import Image, ImageDraw
    final = body()
    print("cores:", len(final.colors_used()), "lint:", final.lint(max_colors=16))
    final.preview("art/previews/lander_cute_preview.png")

    steps = [("1. Atual", b_body()), ("2. Formas redondas", body(2)), ("3. + Gatinho", body(3)),
             ("4. + Brilho e bochecha", body(4)), ("Piscando", body(4, blink=True)), ("Propulsor", thrust(1))]
    S = 8
    bg = Image.open("art/previews/ui_sample.png").convert("RGB")
    cell = 32 * S
    sheet = Image.new("RGB", (len(steps) * (cell + 8), cell + 24 + 32 * 3 + 8), (22, 20, 28))
    d = ImageDraw.Draw(sheet)
    for i, (name, cv) in enumerate(steps):
        x = i * (cell + 8)
        for size, y0 in ((cell, 22), (96, cell + 30)):
            tile = bg.crop((470, 236, 502, 268)).resize((size, size), Image.NEAREST)
            spr = cv.to_image().resize((size, size), Image.NEAREST)
            tile.paste(spr, (0, 0), spr)
            sheet.paste(tile, (x, y0))
        d.text((x + 4, 4), name, fill=(240, 236, 230))
    sheet.save("art/previews/lander_cute_steps.png")
    print("art/previews/lander_cute_steps.png")
