"""
pixelart.py - "Aseprite em codigo": uma grade de pixels travada na paleta Resurrect 64.

Uso tipico (dentro de um script gerador em art/src/...):

    import sys; sys.path.insert(0, ".claude/skills/pixel-art/scripts")
    from pixelart import *

    cv = Canvas.grid32()                 # ou grid16() / grid64() / Canvas.for_kind("ship")
    cv.rect(4, 4, 8, 8, "steel")         # cores por nome, hex ("#9babb2") ou indice (7)
    cv.paint([
        "..oo..",
        ".oSSo.",
    ], {"o": "ink", "S": "steel"}, x=10, y=2)
    cv.save("assets/sprites/foo.png")    # valida paleta + gera previa ampliada

Regras garantidas pela biblioteca:
  * Nenhuma cor fora da Resurrect 64 entra na grade (PaletteError).
  * Transparencia e binaria: um pixel e uma cor da paleta OU vazio (None).
  * Tudo e deterministico (ruido usa seed), entao o script gerador e a "fonte" do asset.
"""
from __future__ import annotations

import json
import os
import random
import sys
from dataclasses import dataclass, field
from typing import Callable, Iterable, Sequence

try:
    from PIL import Image, ImageDraw
except ImportError:  # pragma: no cover
    sys.exit("Pillow nao instalado: pip install pillow")

# ---------------------------------------------------------------------------
# Paleta Resurrect 64 (https://lospec.com/palette-list/resurrect-64)
# ---------------------------------------------------------------------------
PALETTE_HEX: list[str] = [
    "2e222f", "3e3546", "625565", "966c6c", "ab947a", "694f62", "7f708a", "9babb2",
    "c7dcd0", "ffffff", "6e2727", "b33831", "ea4f36", "f57d4a", "ae2334", "e83b3b",
    "fb6b1d", "f79617", "f9c22b", "7a3045", "9e4539", "cd683d", "e6904e", "fbb954",
    "4c3e24", "676633", "a2a947", "d5e04b", "fbff86", "165a4c", "239063", "1ebc73",
    "91db69", "cddf6c", "313638", "374e4a", "547e64", "92a984", "b2ba90", "0b5e65",
    "0b8a8f", "0eaf9b", "30e1b9", "8ff8e2", "323353", "484a77", "4d65b4", "4d9be6",
    "8fd3ff", "45293f", "6b3e75", "905ea9", "a884f3", "eaaded", "753c54", "a24b6f",
    "cf657f", "ed8099", "831c5d", "c32454", "f04f78", "f68181", "fca790", "fdcbb0",
]
PALETTE_RGB: list[tuple[int, int, int]] = [
    (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)) for h in PALETTE_HEX
]
_RGB_TO_INDEX = {rgb: i for i, rgb in enumerate(PALETTE_RGB)}

# Nomes (nao oficiais) para escrever codigo legivel. Indice -> nome na mesma ordem da paleta.
COLOR_NAMES: list[str] = [
    "ink", "shadow", "slate", "rosewood", "sand", "mauve", "lilac_grey", "steel",
    "mist", "white", "maroon", "brick", "vermilion", "coral", "crimson", "red",
    "orange", "amber", "gold", "wine", "rust", "terracotta", "copper", "honey",
    "umber", "olive", "moss", "lime", "lemon", "pine", "green", "emerald",
    "leaf", "sprout", "charcoal", "deep_sage", "sage", "lichen", "bone", "deep_teal",
    "teal", "sea", "aqua", "ice", "navy", "indigo", "blue", "sky",
    "pale_sky", "plum_dark", "plum", "purple", "violet", "lavender", "berry_dark", "berry",
    "rose", "pink", "magenta_dark", "raspberry", "hot_pink", "salmon", "peach", "cream",
]
NAME_TO_INDEX = {n: i for i, n in enumerate(COLOR_NAMES)}

# Rampas (escuro -> claro). Uma cor pode estar em mais de uma rampa.
# Ver references/palette.md para o uso recomendado de cada uma.
RAMPS: dict[str, list[str]] = {
    "neutral":  ["ink", "shadow", "slate", "lilac_grey", "steel", "mist", "white"],
    "warm_rock": ["ink", "shadow", "mauve", "rosewood", "sand", "cream"],
    "metal":    ["charcoal", "deep_sage", "sage", "lichen", "bone", "white"],
    "fire":     ["maroon", "brick", "orange", "amber", "gold", "lemon", "white"],
    "red":      ["wine", "crimson", "red", "vermilion", "coral", "peach"],
    "rust":     ["umber", "wine", "rust", "terracotta", "copper", "honey"],
    "olive":    ["umber", "olive", "moss", "lime", "lemon"],
    "green":    ["deep_sage", "pine", "green", "emerald", "leaf", "sprout"],
    "teal":     ["navy", "deep_teal", "teal", "sea", "aqua", "ice"],
    "blue":     ["ink", "navy", "indigo", "blue", "sky", "pale_sky", "white"],
    "purple":   ["ink", "plum_dark", "plum", "purple", "violet", "lavender"],
    "pink":     ["plum_dark", "berry_dark", "berry", "rose", "pink", "peach", "cream"],
    "magenta":  ["plum_dark", "magenta_dark", "raspberry", "hot_pink", "salmon", "peach", "cream"],
    "space":    ["ink", "shadow", "navy", "indigo"],
}

# Guia de tamanhos (kind -> lado do canvas). Ver SKILL.md para a justificativa.
SIZE_GUIDE: dict[str, int] = {
    "tile": 16, "terrain": 16, "item": 16, "icon": 16, "ui_icon": 16, "pickup": 16,
    "particle": 16, "fx_small": 16, "bullet": 16, "small_prop": 16,
    "character": 32, "ship": 32, "vehicle": 32, "lander": 32, "enemy": 32, "prop": 32,
    "fx": 32, "explosion": 32, "building_small": 32, "ui_panel": 32,
    "boss": 64, "portrait": 64, "large_prop": 64, "building": 64, "planet": 64,
    "station": 64, "background_chunk": 64, "big_fx": 64,
}


class PaletteError(ValueError):
    pass


Color = "str | int | tuple | None"


def resolve(color) -> int | None:
    """Converte nome / hex / indice / rgb em indice da paleta. None, 'clear' ou '.' = transparente."""
    if color is None:
        return None
    if isinstance(color, bool):
        raise PaletteError(f"cor invalida: {color!r}")
    if isinstance(color, int):
        if 0 <= color < len(PALETTE_HEX):
            return color
        raise PaletteError(f"indice fora da paleta (0-63): {color}")
    if isinstance(color, tuple):
        rgb = tuple(color[:3])
        if len(color) == 4 and color[3] == 0:
            return None
        if len(color) == 4 and color[3] != 255:
            raise PaletteError(f"semi-transparencia proibida: {color}")
        if rgb in _RGB_TO_INDEX:
            return _RGB_TO_INDEX[rgb]
        raise PaletteError(f"RGB {rgb} nao pertence a Resurrect 64")
    if isinstance(color, str):
        c = color.strip().lower()
        if c in ("clear", "transparent", "none", "."):
            return None
        if c in NAME_TO_INDEX:
            return NAME_TO_INDEX[c]
        h = c.lstrip("#")
        if len(h) == 6 and h in PALETTE_HEX:
            return PALETTE_HEX.index(h)
        raise PaletteError(
            f"cor {color!r} nao pertence a Resurrect 64. Use um nome de COLOR_NAMES, "
            f"um hex da paleta ou um indice 0-63."
        )
    raise PaletteError(f"cor invalida: {color!r}")


def name_of(idx: int | None) -> str:
    return "clear" if idx is None else COLOR_NAMES[idx]


def hex_of(color) -> str:
    i = resolve(color)
    return "transparent" if i is None else "#" + PALETTE_HEX[i]


def luminance(color) -> float:
    r, g, b = PALETTE_RGB[resolve(color)]
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def ramp(name: str) -> list[int]:
    """Indices de uma rampa nomeada (escuro -> claro)."""
    if name not in RAMPS:
        raise KeyError(f"rampa desconhecida: {name}. Disponiveis: {', '.join(RAMPS)}")
    return [NAME_TO_INDEX[n] for n in RAMPS[name]]


def shift(color, steps: int, ramp_name: str | None = None) -> int:
    """Clareia (+) ou escurece (-) uma cor andando na rampa. Se ramp_name for None,
    usa a primeira rampa que contem a cor. Satura nas pontas da rampa."""
    i = resolve(color)
    candidates = [ramp_name] if ramp_name else [k for k, v in RAMPS.items() if COLOR_NAMES[i] in v]
    if not candidates:
        raise PaletteError(f"{name_of(i)} nao esta em nenhuma rampa; informe ramp_name")
    r = ramp(candidates[0])
    if i not in r:
        raise PaletteError(f"{name_of(i)} nao esta na rampa {candidates[0]}")
    pos = max(0, min(len(r) - 1, r.index(i) + steps))
    return r[pos]


# ---------------------------------------------------------------------------
# Dithering
# ---------------------------------------------------------------------------
BAYER2 = [[0, 2], [3, 1]]
BAYER4 = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def dither_on(x: int, y: int, level: float, pattern: str = "bayer4", rng: random.Random | None = None) -> bool:
    """True se o pixel (x, y) recebe a cor B para uma mistura com `level` (0 = so A, 1 = so B).
    Padroes: 'checker' (50%), 'bayer2', 'bayer4', 'noise' (organico, precisa de rng),
    'hstripe', 'vstripe', 'diag'."""
    if level <= 0:
        return False
    if level >= 1:
        return True
    if pattern in ("checker", "bayer2"):  # em 50% o bayer2 e exatamente o xadrez
        if pattern == "checker" and abs(level - 0.5) < 1e-9:
            return (x + y) % 2 == 0
        return (BAYER2[y % 2][x % 2] + 0.5) / 4 < level
    if pattern == "bayer4":
        return (BAYER4[y % 4][x % 4] + 0.5) / 16 < level
    if pattern == "noise":
        return (rng or random.Random(x * 7919 + y * 104729)).random() < level
    if pattern == "hstripe":
        return y % max(1, round(1 / level)) == 0
    if pattern == "vstripe":
        return x % max(1, round(1 / level)) == 0
    if pattern == "diag":
        return (x + y) % max(1, round(1 / level)) == 0
    raise ValueError(f"padrao de dither desconhecido: {pattern}")


# ---------------------------------------------------------------------------
# Canvas
# ---------------------------------------------------------------------------
class Canvas:
    """Grade de pixels. Cada celula guarda um indice da paleta (0-63) ou None (transparente)."""

    def __init__(self, width: int, height: int | None = None, fill=None):
        self.w = width
        self.h = height if height is not None else width
        f = resolve(fill)
        self.px_data: list[list[int | None]] = [[f] * self.w for _ in range(self.h)]

    # ---- construtores por tamanho -------------------------------------------------
    @classmethod
    def grid16(cls, fill=None) -> "Canvas":
        """16x16: tiles de terreno, itens, icones, pickups, particulas, projeteis."""
        return cls(16, 16, fill)

    @classmethod
    def grid32(cls, fill=None) -> "Canvas":
        """32x32: naves/lander, personagens, inimigos, props, efeitos (explosao), predios pequenos."""
        return cls(32, 32, fill)

    @classmethod
    def grid64(cls, fill=None) -> "Canvas":
        """64x64: chefes, retratos, props grandes, estacoes, planetas, pedacos de fundo."""
        return cls(64, 64, fill)

    @classmethod
    def for_kind(cls, kind: str, fill=None) -> "Canvas":
        if kind not in SIZE_GUIDE:
            raise KeyError(f"kind desconhecido: {kind}. Opcoes: {', '.join(sorted(SIZE_GUIDE))}")
        s = SIZE_GUIDE[kind]
        return cls(s, s, fill)

    def copy(self) -> "Canvas":
        c = Canvas(self.w, self.h)
        c.px_data = [row[:] for row in self.px_data]
        return c

    # ---- acesso basico --------------------------------------------------------------
    def inside(self, x: int, y: int) -> bool:
        return 0 <= x < self.w and 0 <= y < self.h

    def px(self, x: int, y: int, color) -> "Canvas":
        """Pinta um pixel (fora da grade e ignorado, como no Aseprite)."""
        if self.inside(x, y):
            self.px_data[y][x] = resolve(color)
        return self

    def pxs(self, points: Iterable[tuple[int, int]], color) -> "Canvas":
        c = resolve(color)
        for x, y in points:
            if self.inside(x, y):
                self.px_data[y][x] = c
        return self

    def get(self, x: int, y: int, wrap: bool = False) -> int | None:
        if wrap:
            return self.px_data[y % self.h][x % self.w]
        return self.px_data[y][x] if self.inside(x, y) else None

    def clear(self) -> "Canvas":
        self.px_data = [[None] * self.w for _ in range(self.h)]
        return self

    # ---- primitivas -----------------------------------------------------------------
    def rect(self, x: int, y: int, w: int, h: int, color, fill: bool = True) -> "Canvas":
        c = resolve(color)
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                if fill or yy in (y, y + h - 1) or xx in (x, x + w - 1):
                    if self.inside(xx, yy):
                        self.px_data[yy][xx] = c
        return self

    def hline(self, x0: int, x1: int, y: int, color) -> "Canvas":
        for x in range(min(x0, x1), max(x0, x1) + 1):
            self.px(x, y, color)
        return self

    def vline(self, x: int, y0: int, y1: int, color) -> "Canvas":
        for y in range(min(y0, y1), max(y0, y1) + 1):
            self.px(x, y, color)
        return self

    @staticmethod
    def line_points(x0: int, y0: int, x1: int, y1: int, pixel_perfect: bool = True) -> list[tuple[int, int]]:
        """Bresenham. pixel_perfect remove os 'L' (pixels em cotovelo) como o modo Pixel Perfect do Aseprite."""
        pts = []
        dx, dy = abs(x1 - x0), -abs(y1 - y0)
        sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
        err = dx + dy
        x, y = x0, y0
        while True:
            pts.append((x, y))
            if x == x1 and y == y1:
                break
            e2 = 2 * err
            if e2 >= dy:
                err += dy
                x += sx
            if e2 <= dx:
                err += dx
                y += sy
        if pixel_perfect and len(pts) > 2:
            out = [pts[0]]
            i = 1
            while i < len(pts) - 1:
                a, b, c = out[-1], pts[i], pts[i + 1]
                if (a[0] == b[0] or a[1] == b[1]) and (b[0] == c[0] or b[1] == c[1]) and a[0] != c[0] and a[1] != c[1]:
                    i += 1  # b e um cotovelo: pula
                    continue
                out.append(b)
                i += 1
            out.append(pts[-1])
            pts = out
        return pts

    def line(self, x0: int, y0: int, x1: int, y1: int, color, pixel_perfect: bool = True) -> "Canvas":
        return self.pxs(self.line_points(x0, y0, x1, y1, pixel_perfect), color)

    def polyline(self, points: Sequence[tuple[int, int]], color, closed: bool = False) -> "Canvas":
        pts = list(points) + ([points[0]] if closed else [])
        for (a, b), (c, d) in zip(pts, pts[1:]):
            self.line(a, b, c, d, color)
        return self

    def ellipse(self, cx: float, cy: float, rx: float, ry: float, color, fill: bool = True) -> "Canvas":
        """Elipse por amostragem no centro do pixel (formas limpas em tamanhos pequenos).
        Para um circulo de diametro par use centro .5 (ex.: cx=7.5 num 16x16)."""
        c = resolve(color)
        inside = set()
        for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
            for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
                if rx > 0 and ry > 0 and ((x - cx) / (rx + 0.5)) ** 2 + ((y - cy) / (ry + 0.5)) ** 2 <= 1.0:
                    inside.add((x, y))
        if fill:
            pts = inside
        else:
            pts = {(x, y) for (x, y) in inside
                   if any((x + dx, y + dy) not in inside for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))}
        for x, y in pts:
            if self.inside(x, y):
                self.px_data[y][x] = c
        return self

    def circle(self, cx: float, cy: float, r: float, color, fill: bool = True) -> "Canvas":
        return self.ellipse(cx, cy, r, r, color, fill)

    def polygon(self, points: Sequence[tuple[int, int]], color, outline=None) -> "Canvas":
        """Preenche um poligono (scanline, regra par-impar, amostra no centro do pixel)."""
        c = resolve(color)
        ys = [p[1] for p in points]
        n = len(points)
        for y in range(min(ys), max(ys) + 1):
            sy = y + 0.5
            xs = []
            for i in range(n):
                (x0, y0), (x1, y1) = points[i], points[(i + 1) % n]
                if (y0 <= sy < y1) or (y1 <= sy < y0):
                    xs.append(x0 + (sy - y0) * (x1 - x0) / (y1 - y0))
            xs.sort()
            for a, b in zip(xs[::2], xs[1::2]):
                for x in range(int(round(a)), int(round(b))):
                    if self.inside(x, y):
                        self.px_data[y][x] = c
        if outline is not None:
            self.polyline(points, outline, closed=True)
        return self

    def flood_fill(self, x: int, y: int, color, diagonal: bool = False) -> "Canvas":
        """Balde de tinta (contiguo)."""
        target = self.get(x, y)
        c = resolve(color)
        if target == c or not self.inside(x, y):
            return self
        stack = [(x, y)]
        nbrs = [(1, 0), (-1, 0), (0, 1), (0, -1)] + ([(1, 1), (1, -1), (-1, 1), (-1, -1)] if diagonal else [])
        while stack:
            px, py = stack.pop()
            if not self.inside(px, py) or self.px_data[py][px] != target:
                continue
            self.px_data[py][px] = c
            stack.extend((px + dx, py + dy) for dx, dy in nbrs)
        return self

    def paint(self, rows: Sequence[str], legend: dict[str, object], x: int = 0, y: int = 0,
              transparent: str = ".") -> "Canvas":
        """Pinta a partir de um 'desenho ASCII' - o jeito mais proximo de pintar a mao no Aseprite.
        Cada caractere e uma cor via `legend`; `transparent` (padrao '.') nao altera o pixel;
        use a cor 'clear' na legenda para apagar."""
        cache = {k: resolve(v) for k, v in legend.items()}
        for j, row in enumerate(rows):
            for i, ch in enumerate(row):
                if ch == transparent or ch == " ":
                    continue
                if ch not in cache:
                    raise KeyError(f"caractere {ch!r} (linha {j}, col {i}) sem cor na legenda")
                if self.inside(x + i, y + j):
                    self.px_data[y + j][x + i] = cache[ch]
        return self

    def stamp(self, other: "Canvas", x: int = 0, y: int = 0) -> "Canvas":
        """Cola outro canvas (pixels transparentes nao sobrescrevem)."""
        for j in range(other.h):
            for i in range(other.w):
                v = other.px_data[j][i]
                if v is not None and self.inside(x + i, y + j):
                    self.px_data[y + j][x + i] = v
        return self

    # ---- mascaras e selecoes ---------------------------------------------------------
    def mask(self, pred: Callable[[int, int, int | None], bool]) -> set[tuple[int, int]]:
        return {(x, y) for y in range(self.h) for x in range(self.w) if pred(x, y, self.px_data[y][x])}

    def opaque(self) -> set[tuple[int, int]]:
        return self.mask(lambda x, y, v: v is not None)

    def where(self, color) -> set[tuple[int, int]]:
        c = resolve(color)
        return self.mask(lambda x, y, v: v == c)

    def replace(self, old, new, region: set[tuple[int, int]] | None = None) -> "Canvas":
        o, n = resolve(old), resolve(new)
        for y in range(self.h):
            for x in range(self.w):
                if self.px_data[y][x] == o and (region is None or (x, y) in region):
                    self.px_data[y][x] = n
        return self

    # ---- dithering / textura ----------------------------------------------------------
    def dither(self, region: Iterable[tuple[int, int]], color_a, color_b, level: float,
               pattern: str = "bayer4", seed: int = 0) -> "Canvas":
        """Mistura A/B na regiao. level 0..1 = proporcao de B."""
        a, b = resolve(color_a), resolve(color_b)
        rng = random.Random(seed)
        for x, y in sorted(region, key=lambda p: (p[1], p[0])):
            if self.inside(x, y):
                self.px_data[y][x] = b if dither_on(x, y, level, pattern, rng) else a
        return self

    def dither_rect(self, x: int, y: int, w: int, h: int, color_a, color_b, level: float,
                    pattern: str = "bayer4", seed: int = 0) -> "Canvas":
        return self.dither({(i, j) for j in range(y, y + h) for i in range(x, x + w)},
                           color_a, color_b, level, pattern, seed)

    def gradient(self, x: int, y: int, w: int, h: int, colors: Sequence, vertical: bool = True,
                 pattern: str = "bayer4", dither_width: float = 0.5) -> "Canvas":
        """Faixas de cor com transicao pontilhada entre elas (evita banding duro).
        dither_width = fracao da faixa usada na transicao (0 = faixas solidas)."""
        cols = [resolve(c) for c in colors]
        n = len(cols)
        length = h if vertical else w
        for j in range(h):
            for i in range(w):
                t = ((j if vertical else i) + 0.5) / length * n - 0.5  # posicao em "faixas"
                k = max(0, min(n - 1, int(t)))
                frac = t - k
                c = cols[k]
                if k + 1 < n and dither_width > 0:
                    edge = 1 - dither_width
                    if frac > edge:
                        lvl = (frac - edge) / dither_width
                        if dither_on(x + i, y + j, lvl, pattern):
                            c = cols[k + 1]
                elif t < 0:
                    c = cols[0]
                self.px(x + i, y + j, c)
        return self

    def scatter(self, region: Iterable[tuple[int, int]], color, density: float, seed: int = 0,
                min_dist: int = 0) -> "Canvas":
        """Espalha pixels soltos (poeira, estrelas, crateras pequenas). min_dist evita aglomerar."""
        rng = random.Random(seed)
        placed: list[tuple[int, int]] = []
        c = resolve(color)
        for x, y in sorted(region, key=lambda p: (p[1], p[0])):
            if rng.random() < density:
                if min_dist and any(abs(x - a) <= min_dist and abs(y - b) <= min_dist for a, b in placed):
                    continue
                placed.append((x, y))
                if self.inside(x, y):
                    self.px_data[y][x] = c
        return self

    def clusters(self, region: set[tuple[int, int]], color, count: int, size: tuple[int, int] = (2, 4),
                 seed: int = 0, wrap: bool = False) -> "Canvas":
        """Cria aglomerados organicos (clusters) de 'size' pixels - textura de rocha/solo sem ruido.
        wrap=True faz os clusters atravessarem as bordas (tile seamless)."""
        rng = random.Random(seed)
        c = resolve(color)
        cells = sorted(region)
        if not cells:
            return self
        for _ in range(count):
            x, y = rng.choice(cells)
            n = rng.randint(*size)
            pts = [(x, y)]
            while len(pts) < n:
                bx, by = rng.choice(pts)
                dx, dy = rng.choice([(1, 0), (-1, 0), (0, 1), (0, -1), (1, 0), (-1, 0)])  # tende a horizontal
                p = (bx + dx, by + dy)
                if wrap:
                    p = (p[0] % self.w, p[1] % self.h)
                if p in region and p not in pts:
                    pts.append(p)
                elif rng.random() < 0.2:
                    break
            self.pxs(pts, c)
        return self

    # ---- contorno / sombra ------------------------------------------------------------
    def _neighbors(self, x, y, diagonal=False):
        d = [(1, 0), (-1, 0), (0, 1), (0, -1)]
        if diagonal:
            d += [(1, 1), (1, -1), (-1, 1), (-1, -1)]
        return [(x + dx, y + dy) for dx, dy in d]

    def outline(self, color, diagonal: bool = False, inside: bool = False) -> "Canvas":
        """Contorno externo (pinta pixels transparentes vizinhos da forma). inside=True pinta a
        borda interna da propria forma. diagonal=False gera contorno 'arredondado' (recomendado)."""
        c = resolve(color)
        solid = self.opaque()
        targets = set()
        for x, y in solid:
            for nx, ny in self._neighbors(x, y, diagonal):
                if inside:
                    if (nx, ny) not in solid:
                        targets.add((x, y))
                elif self.inside(nx, ny) and (nx, ny) not in solid:
                    targets.add((nx, ny))
        return self.pxs(targets, c)

    def selout(self, light_dir: tuple[int, int] = (-1, -1), steps_dark: int = -2, steps_light: int = 0) -> "Canvas":
        """Selective outline: a borda interna recebe a propria cor escurecida (lado da sombra)
        e opcionalmente clareada (lado da luz). light_dir aponta DE ONDE vem a luz."""
        solid = self.opaque()
        edge = [(x, y) for x, y in solid if any(n not in solid for n in self._neighbors(x, y))]
        new = {}
        lx, ly = light_dir
        for x, y in edge:
            # lado da borda exposto: soma dos vizinhos vazios
            ex = sum(dx for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)) if (x + dx, y + dy) not in solid)
            ey = sum(dy for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)) if (x + dx, y + dy) not in solid)
            facing_light = ex * lx + ey * ly > 0
            v = self.px_data[y][x]
            try:
                new[(x, y)] = shift(v, steps_light if facing_light else steps_dark)
            except PaletteError:
                pass
        for (x, y), v in new.items():
            self.px_data[y][x] = v
        return self

    def drop_shadow(self, color, dx: int = 1, dy: int = 1) -> "Canvas":
        shadow = [(x + dx, y + dy) for x, y in self.opaque()]
        solid = self.opaque()
        return self.pxs([p for p in shadow if p not in solid], color)

    # ---- transformacoes -------------------------------------------------------------
    def flip_h(self) -> "Canvas":
        self.px_data = [row[::-1] for row in self.px_data]
        return self

    def flip_v(self) -> "Canvas":
        self.px_data = self.px_data[::-1]
        return self

    def mirror_x(self, left_to_right: bool = True) -> "Canvas":
        """Simetria horizontal: copia a metade esquerda para a direita (naves, personagens de frente)."""
        for y in range(self.h):
            for x in range(self.w // 2):
                if left_to_right:
                    self.px_data[y][self.w - 1 - x] = self.px_data[y][x]
                else:
                    self.px_data[y][x] = self.px_data[y][self.w - 1 - x]
        return self

    def wrap_shift(self, dx: int, dy: int) -> "Canvas":
        """Desloca com wrap (Aseprite: Edit > Shift / Tiled mode). Use para checar/corrigir costuras."""
        self.px_data = [[self.px_data[(y - dy) % self.h][(x - dx) % self.w] for x in range(self.w)]
                        for y in range(self.h)]
        return self

    def rotate90(self, times: int = 1) -> "Canvas":
        for _ in range(times % 4):
            self.px_data = [list(r) for r in zip(*self.px_data[::-1])]
            self.w, self.h = self.h, self.w
        return self

    def crop(self, x: int, y: int, w: int, h: int) -> "Canvas":
        c = Canvas(w, h)
        for j in range(h):
            for i in range(w):
                c.px_data[j][i] = self.get(x + i, y + j)
        return c

    # ---- analise (lint) ------------------------------------------------------------
    def colors_used(self) -> dict[str, int]:
        count: dict[str, int] = {}
        for row in self.px_data:
            for v in row:
                if v is not None:
                    count[COLOR_NAMES[v]] = count.get(COLOR_NAMES[v], 0) + 1
        return dict(sorted(count.items(), key=lambda kv: -kv[1]))

    def orphans(self, wrap: bool = False) -> list[tuple[int, int, str]]:
        """Pixels 'orfaos': nenhum vizinho (8 direcoes) da mesma cor. Muitos = ruido / textura suja.
        Alguns sao aceitaveis (brilho especular, estrelas, olhos)."""
        out = []
        for y in range(self.h):
            for x in range(self.w):
                v = self.px_data[y][x]
                if v is None:
                    continue
                same = False
                for nx, ny in self._neighbors(x, y, diagonal=True):
                    if wrap:
                        nv = self.px_data[ny % self.h][nx % self.w]
                    else:
                        nv = self.get(nx, ny)
                    if nv == v:
                        same = True
                        break
                if not same:
                    out.append((x, y, COLOR_NAMES[v]))
        return out

    def outline_doubles(self, color) -> list[tuple[int, int]]:
        """Encontra 'cotovelos' (L) numa linha de contorno de 1px: pixels da cor com vizinhos
        da mesma cor em uma direcao horizontal E uma vertical, e que podem ser removidos sem
        quebrar a linha. Linhas de contorno devem ser pixel-perfect."""
        c = resolve(color)
        out = []
        for y in range(self.h):
            for x in range(self.w):
                if self.get(x, y) != c:
                    continue
                hn = [self.get(x + d, y) == c for d in (-1, 1)]
                vn = [self.get(x, y + d) == c for d in (-1, 1)]
                if sum(hn) == 1 and sum(vn) == 1:
                    # os dois vizinhos se tocam na diagonal? entao este pixel e redundante
                    dx = -1 if hn[0] else 1
                    dy = -1 if vn[0] else 1
                    if self.get(x + dx, y + dy) != c:
                        out.append((x, y))
        return out

    def lint(self, max_colors: int | None = None, wrap: bool = False, outline_color=None,
             orphan_ratio_warn: float = 0.02) -> list[str]:
        """Checagens objetivas. Retorna lista de avisos (vazia = ok)."""
        warns = []
        used = self.colors_used()
        if max_colors and len(used) > max_colors:
            warns.append(f"{len(used)} cores usadas (limite {max_colors}): {', '.join(used)}")
        orph = self.orphans(wrap)
        total = max(1, sum(used.values()))
        if len(orph) / total > orphan_ratio_warn:
            sample = ", ".join(f"({x},{y}) {n}" for x, y, n in orph[:12])
            warns.append(f"{len(orph)} pixels orfaos ({len(orph) / total:.1%}) - ruido? ex.: {sample}")
        if outline_color is not None:
            d = self.outline_doubles(outline_color)
            if d:
                warns.append(f"contorno com {len(d)} cotovelos (nao pixel-perfect): {d[:12]}")
        return warns

    # ---- exportacao -----------------------------------------------------------------
    def to_image(self) -> Image.Image:
        img = Image.new("RGBA", (self.w, self.h), (0, 0, 0, 0))
        pix = img.load()
        for y in range(self.h):
            for x in range(self.w):
                v = self.px_data[y][x]
                if v is not None:
                    pix[x, y] = PALETTE_RGB[v] + (255,)
        return img

    @classmethod
    def from_image(cls, path: str) -> "Canvas":
        """Carrega um PNG existente (valida que so usa a paleta)."""
        img = Image.open(path).convert("RGBA")
        c = cls(img.width, img.height)
        pix = img.load()
        for y in range(img.height):
            for x in range(img.width):
                c.px_data[y][x] = resolve(pix[x, y])
        return c

    def save(self, path: str, preview: bool = True, scale: int | None = None, tiled: bool = False,
             preview_dir: str | None = None) -> str:
        """Salva o PNG em tamanho real. Por padrao tambem gera previa ampliada com grade
        (em art/previews/ se existir art/, senao ao lado do arquivo)."""
        os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
        self.to_image().save(path)
        check_png(path)
        if preview:
            pdir = preview_dir or default_preview_dir(path)
            base = os.path.splitext(os.path.basename(path))[0]
            self.preview(os.path.join(pdir, base + "_preview.png"), scale=scale)
            if tiled:
                self.tiled_preview(os.path.join(pdir, base + "_tiled.png"))
        return path

    def preview(self, path: str, scale: int | None = None, grid: bool = True, bg: str = "checker",
                show_1x: bool = True) -> str:
        """Previa ampliada (para revisar visualmente). Inclui a versao 1x e 2x no canto
        para julgar leitura em tamanho real."""
        scale = scale or max(4, 512 // max(self.w, self.h))
        img = _render_scaled(self, scale, grid, bg)
        if show_1x:
            small = _render_scaled(self, 1, False, "dark")
            small2 = _render_scaled(self, 2, False, "dark")
            pad = 8
            W = img.width + pad + max(small2.width, 1) + pad
            H = max(img.height, small.height + small2.height + pad * 3)
            out = Image.new("RGBA", (W, H), (24, 20, 28, 255))
            out.paste(img, (0, 0))
            out.paste(small2, (img.width + pad, pad), small2)
            out.paste(small, (img.width + pad, pad * 2 + small2.height), small)
            img = out
        os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
        img.save(path)
        return path

    def tiled_preview(self, path: str, nx: int = 3, ny: int = 3, scale: int | None = None) -> str:
        """Repete o tile nx x ny para checar costuras (Tiled Mode do Aseprite)."""
        big = Canvas(self.w * nx, self.h * ny)
        for j in range(ny):
            for i in range(nx):
                big.stamp(self, i * self.w, j * self.h)
        scale = scale or max(2, 384 // max(big.w, big.h))
        img = _render_scaled(big, scale, grid=False, bg="dark")
        os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
        img.save(path)
        return path


def default_preview_dir(asset_path: str) -> str:
    p = os.path.abspath(asset_path)
    parts = p.split(os.sep)
    # procura a raiz do projeto (pasta que contem assets/ ou art/)
    for i in range(len(parts) - 1, 0, -1):
        root = os.sep.join(parts[:i])
        if os.path.isdir(os.path.join(root, "art")):
            return os.path.join(root, "art", "previews")
    return os.path.join(os.path.dirname(p), "_previews")


def _render_scaled(cv: Canvas, scale: int, grid: bool, bg: str) -> Image.Image:
    W, H = cv.w * scale, cv.h * scale
    img = Image.new("RGBA", (W, H))
    d = ImageDraw.Draw(img)
    cs = max(scale, 4)
    for y in range(cv.h):
        for x in range(cv.w):
            v = cv.px_data[y][x]
            x0, y0 = x * scale, y * scale
            if v is None:
                if bg == "checker":
                    for yy in range(y0, y0 + scale, cs):
                        for xx in range(x0, x0 + scale, cs):
                            light = ((xx // cs) + (yy // cs)) % 2 == 0
                            d.rectangle([xx, yy, min(xx + cs, x0 + scale) - 1, min(yy + cs, y0 + scale) - 1],
                                        fill=(70, 66, 78, 255) if light else (52, 48, 60, 255))
                elif bg == "dark":
                    d.rectangle([x0, y0, x0 + scale - 1, y0 + scale - 1], fill=(20, 16, 24, 255))
                else:
                    d.rectangle([x0, y0, x0 + scale - 1, y0 + scale - 1], fill=(0, 0, 0, 0))
            else:
                d.rectangle([x0, y0, x0 + scale - 1, y0 + scale - 1], fill=PALETTE_RGB[v] + (255,))
    if grid and scale >= 6:
        overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        od = ImageDraw.Draw(overlay)
        gc = (0, 0, 0, 50)
        for x in range(0, W + 1, scale):
            od.line([(x, 0), (x, H)], fill=gc)
        for y in range(0, H + 1, scale):
            od.line([(0, y), (W, y)], fill=gc)
        # grade maior a cada 8 pixels (como a grade do Aseprite)
        gc2 = (0, 0, 0, 110)
        for x in range(0, W + 1, scale * 8):
            od.line([(x, 0), (x, H)], fill=gc2)
        for y in range(0, H + 1, scale * 8):
            od.line([(0, y), (W, y)], fill=gc2)
        img = Image.alpha_composite(img, overlay)
    return img


def check_png(path: str) -> None:
    """Falha se o PNG tiver qualquer cor fora da Resurrect 64 ou semi-transparencia."""
    img = Image.open(path).convert("RGBA")
    bad = {}
    data = img.get_flattened_data() if hasattr(img, "get_flattened_data") else img.getdata()
    for (r, g, b, a) in data:
        if a == 0:
            continue
        if a != 255:
            bad[(r, g, b, a)] = "semi-transparente"
        elif (r, g, b) not in _RGB_TO_INDEX:
            bad[(r, g, b, a)] = "fora da paleta"
    if bad:
        items = ", ".join(f"#{r:02x}{g:02x}{b:02x}@{a} ({why})" for (r, g, b, a), why in list(bad.items())[:10])
        raise PaletteError(f"{path}: {len(bad)} cores invalidas: {items}")


# ---------------------------------------------------------------------------
# Animacao
# ---------------------------------------------------------------------------
@dataclass
class Animation:
    """Uma animacao = lista de frames (Canvas do mesmo tamanho) + duracao por frame (ms)."""
    name: str
    frames: list[Canvas] = field(default_factory=list)
    durations: list[int] = field(default_factory=list)
    loop: bool = True

    def add(self, frame: Canvas, ms: int = 100) -> "Animation":
        if self.frames and (frame.w, frame.h) != (self.frames[0].w, self.frames[0].h):
            raise ValueError("todos os frames precisam ter o mesmo tamanho")
        self.frames.append(frame)
        self.durations.append(ms)
        return self


def save_animations(anims: Sequence[Animation], png_path: str, res_path: str | None = None,
                    tres_path: str | None = None, gif_scale: int = 6, preview_dir: str | None = None) -> dict:
    """Exporta uma spritesheet (uma linha por animacao, frames em colunas), GIFs de previa,
    um JSON com metadados e opcionalmente um SpriteFrames .tres do Godot 4.
    res_path: caminho res:// do PNG (ex.: 'res://assets/sprites/lander.png')."""
    fw, fh = anims[0].frames[0].w, anims[0].frames[0].h
    cols = max(len(a.frames) for a in anims)
    sheet = Canvas(fw * cols, fh * len(anims))
    meta = {"frame_width": fw, "frame_height": fh, "animations": []}
    for row, a in enumerate(anims):
        for col, f in enumerate(a.frames):
            if (f.w, f.h) != (fw, fh):
                raise ValueError(f"frame de {a.name} com tamanho diferente")
            sheet.stamp(f, col * fw, row * fh)
        meta["animations"].append({"name": a.name, "row": row, "frames": len(a.frames),
                                   "durations_ms": a.durations, "loop": a.loop})
    os.makedirs(os.path.dirname(os.path.abspath(png_path)), exist_ok=True)
    sheet.to_image().save(png_path)
    check_png(png_path)
    base = os.path.splitext(png_path)[0]
    with open(base + ".json", "w") as fh_:
        json.dump(meta, fh_, indent=2)
    pdir = preview_dir or default_preview_dir(png_path)
    os.makedirs(pdir, exist_ok=True)
    stem = os.path.basename(base)
    sheet.preview(os.path.join(pdir, stem + "_sheet_preview.png"), scale=max(4, 256 // fh), show_1x=False)
    for a in anims:
        gif = [_render_scaled(f, gif_scale, False, "dark").convert("P", palette=Image.ADAPTIVE) for f in a.frames]
        gif[0].save(os.path.join(pdir, f"{stem}_{a.name}.gif"), save_all=True, append_images=gif[1:],
                    duration=a.durations, loop=0 if a.loop else 1, disposal=2)
    if tres_path:
        write_godot_spriteframes(tres_path, res_path or _guess_res_path(png_path), anims, fw, fh)
    return meta


def _guess_res_path(png_path: str) -> str:
    p = os.path.abspath(png_path)
    d = os.path.dirname(p)
    while d != os.path.dirname(d):
        if os.path.exists(os.path.join(d, "project.godot")):
            return "res://" + os.path.relpath(p, d).replace(os.sep, "/")
        d = os.path.dirname(d)
    # sem project.godot: assume a raiz do projeto como cwd
    return "res://" + os.path.relpath(p, os.getcwd()).replace(os.sep, "/")


def write_godot_spriteframes(tres_path: str, res_path: str, anims: Sequence[Animation], fw: int, fh: int) -> str:
    """SpriteFrames (Godot 4) para AnimatedSprite2D. FPS base = 1000/menor duracao; a duracao
    relativa de cada frame vira o campo 'duration'."""
    subs, anim_entries, sid = [], [], 0
    for row, a in enumerate(anims):
        base_ms = min(a.durations)
        frames = []
        for col, ms in enumerate(a.durations):
            sid += 1
            subs.append(f'[sub_resource type="AtlasTexture" id="AtlasTexture_{sid}"]\n'
                        f'atlas = ExtResource("1_tex")\n'
                        f'region = Rect2({col * fw}, {row * fh}, {fw}, {fh})\n')
            frames.append(f'{{\n"duration": {ms / base_ms:.3f},\n"texture": SubResource("AtlasTexture_{sid}")\n}}')
        anim_entries.append(
            '{\n"frames": [' + ", ".join(frames) + f'],\n"loop": {"true" if a.loop else "false"},\n'
            f'"name": &"{a.name}",\n"speed": {1000 / base_ms:.3f}\n}}')
    body = (f'[gd_resource type="SpriteFrames" load_steps={len(subs) + 2} format=3]\n\n'
            f'[ext_resource type="Texture2D" path="{res_path}" id="1_tex"]\n\n'
            + "\n".join(subs) + "\n[resource]\nanimations = [" + ", ".join(anim_entries) + "]\n")
    os.makedirs(os.path.dirname(os.path.abspath(tres_path)), exist_ok=True)
    with open(tres_path, "w") as f:
        f.write(body)
    return tres_path


# ---------------------------------------------------------------------------
# Tilesets / auto-tiling (Godot 4 terrains)
# ---------------------------------------------------------------------------
# bits de vizinhanca
N, NE, E, SE, S, SW, W, NW = 1, 2, 4, 8, 16, 32, 64, 128
_GODOT_BITS = {N: "top_side", NE: "top_right_corner", E: "right_side", SE: "bottom_right_corner",
               S: "bottom_side", SW: "bottom_left_corner", W: "left_side", NW: "top_left_corner"}


def canonical_mask(m: int) -> int:
    """Regra do blob: uma diagonal so conta se os dois lados adjacentes tambem estiverem presentes."""
    if not (m & N and m & E):
        m &= ~NE
    if not (m & S and m & E):
        m &= ~SE
    if not (m & S and m & W):
        m &= ~SW
    if not (m & N and m & W):
        m &= ~NW
    return m


BLOB47_MASKS: list[int] = sorted({canonical_mask(m) for m in range(256)})
SIDES16_MASKS: list[int] = sorted({m & (N | E | S | W) for m in range(256)})
assert len(BLOB47_MASKS) == 47 and len(SIDES16_MASKS) == 16


@dataclass
class TileTemplate:
    """Metodo das 5 pecas (tambem usado pelo RPG Maker): voce desenha 5 tiles e a biblioteca
    monta automaticamente os 47 (blob) ou 16 (sides) combinando quadrantes.

      fill   - tile interno, vizinhos em todas as 8 direcoes (deve ser seamless consigo mesmo)
      island - tile isolado, nenhum vizinho (fornece os cantos externos)
      hstrip - vizinhos so a esquerda e direita (fornece bordas de cima e de baixo)
      vstrip - vizinhos so em cima e embaixo (fornece bordas esquerda e direita)
      inner  - vizinhos nos 4 lados mas em nenhuma diagonal (fornece os cantos internos)

    Todos devem ser consistentes entre si: a borda de cima do hstrip precisa bater com a do island etc.
    Tamanho do tile precisa ser par (quadrantes de size/2)."""
    fill: Canvas
    island: Canvas
    hstrip: Canvas
    vstrip: Canvas
    inner: Canvas | None = None

    @property
    def size(self) -> int:
        return self.fill.w

    def compose(self, mask: int) -> Canvas:
        s = self.size
        h = s // 2
        out = Canvas(s, s)
        quads = [  # (qx, qy, vertical_bit, horizontal_bit, diagonal_bit)
            (0, 0, N, W, NW), (h, 0, N, E, NE), (0, h, S, W, SW), (h, h, S, E, SE)]
        for qx, qy, vb, hb, db in quads:
            v, hz, dg = bool(mask & vb), bool(mask & hb), bool(mask & db)
            if v and hz:
                src = self.fill if (dg or self.inner is None) else self.inner
            elif v:
                src = self.vstrip
            elif hz:
                src = self.hstrip
            else:
                src = self.island
            out.stamp(src.crop(qx, qy, h, h), qx, qy)
        return out


def build_tileset(template: TileTemplate, mode: str = "blob47", columns: int = 8,
                  masks: Sequence[int] | None = None) -> tuple[Canvas, list[int]]:
    """Monta a folha de tiles. mode: 'blob47' (Godot: Match Corners and Sides) ou
    'sides16' (Godot: Match Sides). Retorna (folha, lista de mascaras na ordem da folha)."""
    masks = list(masks or (BLOB47_MASKS if mode == "blob47" else SIDES16_MASKS))
    s = template.size
    rows = (len(masks) + columns - 1) // columns
    sheet = Canvas(s * columns, s * rows)
    for k, m in enumerate(masks):
        sheet.stamp(template.compose(m), (k % columns) * s, (k // columns) * s)
    return sheet, masks


def terrain_test_map(template: TileTemplate, layout: Sequence[str], mode: str = "blob47") -> Canvas:
    """Renderiza um mini-mapa (strings com '#' = terreno) usando o auto-tiling, para revisar
    como o tileset fica em uso real (bordas, cantos internos, ilhas)."""
    s = template.size
    H, Wd = len(layout), max(len(r) for r in layout)
    solid = {(x, y) for y, r in enumerate(layout) for x, ch in enumerate(r) if ch == "#"}
    out = Canvas(Wd * s, H * s)
    for (x, y) in solid:
        m = 0
        for bit, (dx, dy) in {N: (0, -1), NE: (1, -1), E: (1, 0), SE: (1, 1), S: (0, 1),
                              SW: (-1, 1), W: (-1, 0), NW: (-1, -1)}.items():
            if (x + dx, y + dy) in solid:
                m |= bit
        m = canonical_mask(m) if mode == "blob47" else m & (N | E | S | W)
        out.stamp(template.compose(m), x * s, y * s)
    return out


def write_godot_tileset(tres_path: str, res_path: str, tile_size: int, masks: Sequence[int],
                        mode: str = "blob47", columns: int = 8, terrain_name: str = "terrain",
                        terrain_color: str = "sand") -> str:
    """Gera um TileSet .tres (Godot 4) com o terrain set ja configurado e os peering bits
    de cada tile preenchidos. Basta atribuir ao TileMapLayer e pintar com o terrain."""
    godot_mode = {"blob47": 0, "sides16": 2}[mode]
    r, g, b = PALETTE_RGB[resolve(terrain_color)]
    lines = []
    for k, m in enumerate(masks):
        cx, cy = k % columns, k // columns
        t = f"{cx}:{cy}/0"
        lines += [f"{t} = 0", f"{t}/terrain_set = 0", f"{t}/terrain = 0"]
        for bit, name in _GODOT_BITS.items():
            if godot_mode == 2 and name.endswith("corner"):
                continue
            if m & bit:
                lines.append(f"{t}/terrains_peering_bit/{name} = 0")
    body = (
        '[gd_resource type="TileSet" load_steps=3 format=3]\n\n'
        f'[ext_resource type="Texture2D" path="{res_path}" id="1_tex"]\n\n'
        '[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_1"]\n'
        'texture = ExtResource("1_tex")\n'
        f'texture_region_size = Vector2i({tile_size}, {tile_size})\n'
        + "\n".join(lines) + "\n\n"
        "[resource]\n"
        f"tile_size = Vector2i({tile_size}, {tile_size})\n"
        f"terrain_set_0/mode = {godot_mode}\n"
        f'terrain_set_0/terrain_0/name = "{terrain_name}"\n'
        f"terrain_set_0/terrain_0/color = Color({r / 255:.3f}, {g / 255:.3f}, {b / 255:.3f}, 1)\n"
        'sources/0 = SubResource("TileSetAtlasSource_1")\n'
    )
    os.makedirs(os.path.dirname(os.path.abspath(tres_path)), exist_ok=True)
    with open(tres_path, "w") as f:
        f.write(body)
    return tres_path


def save_tileset(template: TileTemplate, png_path: str, mode: str = "blob47", tres_path: str | None = None,
                 res_path: str | None = None, terrain_name: str = "terrain", test_layout: Sequence[str] | None = None,
                 preview_dir: str | None = None) -> list[int]:
    """Atalho: monta a folha, salva PNG + previa, mapa de teste e (opcional) TileSet .tres."""
    sheet, masks = build_tileset(template, mode)
    sheet.save(png_path, preview_dir=preview_dir, scale=4)
    pdir = preview_dir or default_preview_dir(png_path)
    stem = os.path.splitext(os.path.basename(png_path))[0]
    template.fill.tiled_preview(os.path.join(pdir, stem + "_fill_tiled.png"))
    layout = test_layout or [
        "..........",
        ".####.....",
        ".######...",
        ".##..###..",
        ".##..####.",
        ".#########",
        "..###.####",
    ]
    tm = terrain_test_map(template, layout, mode)
    tm.preview(os.path.join(pdir, stem + "_testmap.png"), scale=max(2, 640 // tm.w), grid=False, bg="dark",
               show_1x=False)
    if tres_path:
        write_godot_tileset(tres_path, res_path or _guess_res_path(png_path), template.size, masks, mode,
                            terrain_name=terrain_name)
    return masks


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
def palette_sheet(path: str, scale: int = 40) -> str:
    """Folha de referencia com indice e nome de cada cor, agrupada por rampa."""
    rows = list(RAMPS.items())
    maxlen = max(len(v) for _, v in rows)
    lw = 90
    img = Image.new("RGB", (lw + maxlen * scale, len(rows) * scale), (20, 16, 24))
    d = ImageDraw.Draw(img)
    for j, (rname, names) in enumerate(rows):
        d.text((4, j * scale + scale // 2 - 5), rname, fill=(220, 220, 220))
        for i, n in enumerate(names):
            idx = NAME_TO_INDEX[n]
            x0, y0 = lw + i * scale, j * scale
            d.rectangle([x0, y0, x0 + scale - 2, y0 + scale - 2], fill=PALETTE_RGB[idx])
            tc = (0, 0, 0) if luminance(idx) > 120 else (255, 255, 255)
            d.text((x0 + 2, y0 + 2), str(idx), fill=tc)
    img.save(path)
    return path


def _main(argv: list[str]) -> int:
    if len(argv) < 2 or argv[1] in ("-h", "--help"):
        print("uso:\n  pixelart.py check <png>...      valida paleta\n"
              "  pixelart.py lint <png> [--wrap]  lint de um PNG existente\n"
              "  pixelart.py palette <out.png>    folha de referencia das rampas\n"
              "  pixelart.py colors               lista indice/nome/hex\n"
              "  pixelart.py sizes                guia de tamanhos\n"
              "  pixelart.py preview <png> [--tiled]  gera previa ampliada")
        return 0
    cmd = argv[1]
    if cmd == "check":
        ok = True
        for p in argv[2:]:
            try:
                check_png(p)
                print(f"OK  {p}")
            except PaletteError as e:
                ok = False
                print(f"ERRO {e}")
        return 0 if ok else 1
    if cmd == "lint":
        c = Canvas.from_image(argv[2])
        w = c.lint(wrap="--wrap" in argv)
        print(f"{c.w}x{c.h}, cores: {c.colors_used()}")
        print("\n".join(w) or "sem avisos")
        return 0
    if cmd == "palette":
        print(palette_sheet(argv[2]))
        return 0
    if cmd == "colors":
        for i, (n, h) in enumerate(zip(COLOR_NAMES, PALETTE_HEX)):
            ramps_in = [k for k, v in RAMPS.items() if n in v]
            print(f"{i:2d} {n:13s} #{h}  {', '.join(ramps_in)}")
        return 0
    if cmd == "sizes":
        for k, v in sorted(SIZE_GUIDE.items(), key=lambda kv: (kv[1], kv[0])):
            print(f"{v:3d}  {k}")
        return 0
    if cmd == "preview":
        c = Canvas.from_image(argv[2])
        stem = os.path.splitext(argv[2])[0]
        print(c.preview(stem + "_preview.png"))
        if "--tiled" in argv:
            print(c.tiled_preview(stem + "_tiled.png"))
        return 0
    print(f"comando desconhecido: {cmd}")
    return 1


if __name__ == "__main__":
    sys.exit(_main(sys.argv))
