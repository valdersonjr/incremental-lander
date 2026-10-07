"""Logo "INCREMENTAL LANDER" (tela de título, 2026-10-06). Skill pixel-art, padrão title-screen.
Letras GORDINHAS a partir da fonte do jogo: glifo → engorda 1 px → Scale2x (cantos redondos) → degradê de doce
(lemon → gold → amber), brilho em cima, contorno escuro duplo (berry_dark + ink) e sombra sólida embaixo.
"LANDER" maior que "INCREMENTAL" (a palavra que o jogador lembra). Brilhinho de 4 pontas como enfeite.
Variante "font": o texto atual (fonte 3x) para comparar.
Rodar da raiz: python3 art/src/ui/logo.py   -> art/previews/logo_*.png
"""
import sys

sys.path.insert(0, ".claude/skills/pixel-art/scripts")
sys.path.insert(0, "art/src/ui")
sys.path.insert(0, "art/src/bg")
from pixelart import *
from pixel_font import draw_text, text_width

FILL = [(0.0, "white"), (0.18, "lemon"), (0.45, "gold"), (0.78, "amber"), (1.0, "orange")]


def scale2x(c: Canvas) -> Canvas:
    import moon_cute as mc
    return mc.scale2x(c)


def mask_text(text: str, scale: int, gap: int = 2, fat_px: int = 1) -> Canvas:
    """Texto em blocos (scale), engordado 1 px, ampliado com Scale2x (bordas arredondadas)."""
    w = sum((text_width(ch) + gap) * scale for ch in text) + 4
    k = Canvas(w, 11 * scale + 4)
    x = 2
    for ch in text:
        draw_text(k, x, 0, ch, "white", scale=scale)
        x += (text_width(ch) + gap) * scale
    fat = Canvas(k.w, k.h)
    for (px, py) in k.opaque():
        for dx, dy in ((0, 0), (1, 0), (0, 1), (1, 1))[: 4 if fat_px else 1]:
            fat.px(px + dx, py + dy, "white")
    fat = scale2x(fat)
    xs = [p[0] for p in fat.opaque()]
    ys = [p[1] for p in fat.opaque()]
    out = Canvas(max(xs) - min(xs) + 1, max(ys) - min(ys) + 1)
    for px, py in fat.opaque():
        out.px(px - min(xs), py - min(ys), "white")
    return out


def candy(m: Canvas, ramp=FILL) -> Canvas:
    """Pinta a máscara: degradê vertical por letra-linha + brilho de 1 px no topo de cada traço."""
    solid = m.opaque()
    out = Canvas(m.w, m.h)
    for x, y in solid:
        t = y / max(1, m.h - 1)
        c = ramp[0][1]
        for t0, name in ramp:
            if t >= t0:
                c = name
        out.px(x, y, c)
    for x, y in solid:                                         # brilho: topo de cada traço
        if (x, y - 1) not in solid and (x, y + 1) in solid and (x, y + 2) in solid:
            out.px(x, y + 1, "white")
    for x, y in solid:                                         # sombra interna: base de cada traço
        if (x, y + 1) not in solid:
            out.px(x, y, "copper")
    return out


def frame(c: Canvas, inner: str = "berry_dark", outer: str = "ink", drop: int = 3, drop_c: str = "plum_dark") -> Canvas:
    pad = 3 + drop
    o = Canvas(c.w + 2 * pad, c.h + 2 * pad)
    solid = {(x + pad, y + pad) for x, y in c.opaque()}
    ring1 = {(x + dx, y + dy) for x, y in solid for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))} - solid
    ring2 = {(x + dx, y + dy) for x, y in solid | ring1 for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1),
                                                                       (1, 1), (-1, -1), (1, -1), (-1, 1))} - solid - ring1
    body = solid | ring1 | ring2
    for d in range(1, drop + 1):                              # sombra sólida embaixo (relevo de adesivo)
        for x, y in body:
            o.px(x, y + d, drop_c)
    for x, y in ring2:
        o.px(x, y, outer)
    for x, y in ring1:
        o.px(x, y, inner)
    o.stamp(c, pad, pad)
    return o


def sparkle(cv: Canvas, x: int, y: int, s: int, col="white") -> None:
    for i in range(-s, s + 1):
        cv.px(x + i, y, col); cv.px(x, y + i, col)
    if s >= 3:
        cv.px(x - 1, y - 1, col); cv.px(x + 1, y + 1, col); cv.px(x + 1, y - 1, col); cv.px(x - 1, y + 1, col)


def logo(big_scale: int = 2) -> Canvas:
    top = frame(candy(mask_text("INCREMENTAL", 1, gap=2, fat_px=0), [(0, "white"), (0.2, "ice"), (0.5, "pale_sky"),
                                                           (0.85, "sky")]), inner="navy", drop=2, drop_c="navy")
    big = frame(candy(mask_text("LANDER", big_scale, gap=1)))
    w = max(top.w, big.w) + 8
    cv = Canvas(w, top.h + big.h - 6 + 6)
    cv.stamp(big, (w - big.w) // 2, top.h - 6)
    cv.stamp(top, (w - top.w) // 2, 0)
    sparkle(cv, w - 8, top.h + 2, 3)
    sparkle(cv, 6, cv.h - 10, 2, "lemon")
    return cv


def font_logo() -> Canvas:
    t = "INCREMENTAL LANDER"
    cv = Canvas(text_width(t) * 3 + 6, 11 * 3 + 4)
    draw_text(cv, 0, 0, t, "cream", shadow="berry_dark", scale=3)
    return cv


if __name__ == "__main__":
    lg = logo()
    print("logo", lg.w, "x", lg.h, "cores:", len(lg.colors_used()))
    lg.preview("art/previews/logo_preview.png")
    font_logo().preview("art/previews/logo_font_preview.png")
