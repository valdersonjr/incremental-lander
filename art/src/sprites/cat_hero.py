"""Gatinho astronauta HERÓI (tela de título, 2026-10-06). Skill pixel-art, padrões cute-style + title-screen.
O mesmo gato do lander (laranja amber/honey/copper, focinho cream, olhos ink com brilho, bochecha pink), agora de
corpo inteiro e FORA da nave: capacete-bolha grande (proporção chibi, cabeça ≈ corpo), traje branco/mist com faixa
sea (o casco da nave), mochila, botinhas, rabo laranja de ponta creme saindo do traje. Contorno ink, luz de
cima-esquerda. Desenhado em resolução cheia com primitivas (esfera/cápsula) e TAMANHO AJUSTÁVEL (k): a geometria
escala e o contorno continua 1 px (mesma escala de pixel do jogo, só mais detalhe). k=1 → 64x72; k=1.6 → ~102x115.

Poses: rest/wave0..2 (aceno), float (flutuando no espaço, pernas soltas); blink = piscar.
Rodar da raiz: python3 art/src/sprites/cat_hero.py   -> art/previews/cat_hero_*.png
"""
import math
import sys

sys.path.insert(0, ".claude/skills/pixel-art/scripts")
from pixelart import *

FUR = ["honey", "amber", "amber", "copper"]          # brilho, luz, base, sombra
SUIT = ["white", "white", "mist", "steel"]
BOOT = ["ice", "aqua", "sea", "teal"]
GLASS = ("pale_sky", "sky")

ARMS = {  # (ombro -> mão) em unidades de desenho (k=1); mão = luva sea
    "rest": [((20, 44), (16, 52)), ((42, 44), (46, 52))],
    "wave0": [((20, 44), (16, 52)), ((42, 43), (50, 34))],
    "wave1": [((20, 44), (16, 52)), ((42, 43), (52, 30))],
    "wave2": [((20, 44), (16, 52)), ((42, 43), (49, 31))],
    "float": [((20, 44), (11, 40)), ((42, 44), (51, 40))],
    "hold": [((20, 44), (25, 52)), ((42, 44), (38, 52))],
    "thumb": [((20, 44), (16, 52)), ((42, 44), (49, 41))],     # joinha (janela de conversa do pedido)
}
LEGS = {
    "stand": [((26, 56), (25, 63)), ((36, 56), (37, 63))],
    "float": [((26, 56), (21, 63)), ((36, 56), (40, 62))],
}


def sphere(cv: Canvas, cx: float, cy: float, rx: float, ry: float, ramp: list) -> None:
    """Elipse com volume (luz de cima-esquerda), chapada em 3 faixas + brilho."""
    for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            nx, ny = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
            d = nx * nx + ny * ny
            if d > 1:
                continue
            i = -0.5 * nx - 0.6 * ny + 0.62 * math.sqrt(1 - d)
            cv.px(x, y, ramp[0] if i > 0.9 else ramp[1] if i > 0.5 else ramp[2] if i > 0.05 else ramp[3])


def capsule(cv: Canvas, x0: float, y0: float, x1: float, y1: float, r: float, ramp: list) -> None:
    """Braço/perna gordinho: discos ao longo do segmento, sombreado como uma esfera alongada."""
    n = max(2, int(math.hypot(x1 - x0, y1 - y0) * 2))
    for i in range(n + 1):
        t = i / n
        sphere(cv, x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, r, r, ramp)


def _ri(pts: list) -> list:
    return [(round(x), round(y)) for x, y in pts]


class Cat:
    """Desenho do gato numa escala k (coordenadas de desenho em k=1, multiplicadas por k)."""

    def __init__(self, k: float = 1.0):
        self.k = k
        self.W, self.H = int(64 * k), int(72 * k)
        self.HX, self.HY, self.HR = 31 * k, 22 * k, 17 * k

    def s(self, v: float) -> float:
        return v * self.k

    def p(self, pt: tuple) -> tuple:
        return pt[0] * self.k, pt[1] * self.k

    def n(self, v: float) -> int:
        """Tamanho de detalhe (olho, nariz) em px inteiros, nunca menor que no k=1."""
        return max(int(v), int(round(v * self.k)))

    def tail(self, cv: Canvas, path: list) -> None:
        path = [self.p(q) for q in path]
        seg = []
        for (ax, ay), (bx, by) in zip(path, path[1:]):
            m = int(math.hypot(bx - ax, by - ay) * 2) + 1
            seg += [(ax + (bx - ax) * i / m, ay + (by - ay) * i / m) for i in range(m)]
        for i, (x, y) in enumerate(seg):
            t = i / max(1, len(seg) - 1)
            r = self.s(2.9 - 0.9 * t)
            sphere(cv, x, y, r, r, ["white", "cream", "cream", "peach"] if t > 0.78 else FUR)

    def head(self, cv: Canvas, blink: bool, worried: bool = False) -> None:
        cx, cy = round(self.HX), round(self.HY + self.s(2))
        k = Canvas(self.W, self.H)
        for sd in (-1, 1):                                # orelhas (triângulos gordinhos)
            ex = cx + sd * self.s(7)
            k.polygon(_ri([(ex - self.s(4), cy - self.s(5)), (ex + sd * self.s(2), cy - self.s(15)),
                           (ex + self.s(4), cy - self.s(5))]), "amber")
        sphere(k, cx, cy, self.s(12), self.s(9.5), FUR)
        k.outline("ink")
        for sd in (-1, 1):                                # dentro da orelha
            ex = cx + sd * self.s(7)
            k.polygon(_ri([(ex - self.s(2), cy - self.s(6)), (ex + sd * self.s(1.4), cy - self.s(12)),
                           (ex + self.s(2), cy - self.s(6))]), "pink")
        ey = cy + round(self.s(1))
        ew, eh = self.n(3), self.n(4)
        for ox in (-6, 4):                                # olhos com brilho (baixos e afastados)
            x0 = cx + round(self.s(ox))
            if blink:
                k.hline(x0, x0 + ew - 1, ey + eh // 2, "ink")
                k.px(x0 - 1, ey + eh // 2 - 1, "ink"); k.px(x0 + ew, ey + eh // 2 - 1, "ink")
            else:
                k.rect(x0, ey, ew, eh, "ink")
                g = max(1, ew // 2)
                k.rect(x0, ey, g, g, "white")
                if self.k >= 1.4:
                    k.px(x0 + ew - 1, ey + eh - 1, "slate")
                else:
                    k.px(x0 + 1, ey, "white")
        if worried:                                       # sobrancelhas inclinadas (meio do rosto mais alto)
            for ox, sd in ((-6, 1), (4, -1)):
                x0 = cx + round(self.s(ox))
                for t in range(ew + 1):
                    k.px(x0 - (1 if sd > 0 else 0) + t, ey - self.n(2) - (t if sd > 0 else ew - t) // 2, "rust")
        sphere(k, cx, cy + self.s(6), self.s(4), self.s(2.6), ["white", "cream", "cream", "peach"])   # focinho
        nw = self.n(2)
        k.hline(cx - nw // 2, cx - nw // 2 + nw - 1, cy + round(self.s(4)), "pink")                   # nariz
        k.hline(cx - nw // 2, cx - nw // 2 + nw - 1, cy + round(self.s(4)) + 1, "rose")
        my = cy + round(self.s(7))                                   # boquinha "w" (preocupado: "o")
        if worried:
            k.rect(cx - nw // 2, my, nw, self.n(2), "ink")
        else:
            k.px(cx - nw // 2 - 1, my, "ink"); k.px(cx - nw // 2 + nw, my, "ink")
            k.hline(cx - nw // 2, cx - nw // 2 + nw - 1, my + 1, "ink")
        for ox in (-9, 8):                                # bochechas
            k.rect(cx + round(self.s(ox)), cy + round(self.s(5)), self.n(2), max(1, self.n(1)), "pink")
        for sd in (-1, 1):                                # bigodes
            bx = cx + sd * round(self.s(9.5))
            for dy, tilt in ((0, -1), (2, 1)):
                y = cy + round(self.s(4 + dy))
                k.line(bx, y, bx + sd * self.n(2), y + tilt * (1 if self.k > 1.2 else 0), "white")
        cv.stamp(k)

    def helmet_glass(self, cv: Canvas) -> None:
        for y in range(self.H):
            for x in range(self.W):
                if math.hypot(x + 0.5 - self.HX, y + 0.5 - self.HY) <= self.HR:
                    far = (x - self.HX) * 0.8 + (y - self.HY) * 0.6 > self.s(6)
                    cv.px(x, y, GLASS[1] if far else GLASS[0])

    def helmet_shine(self, cv: Canvas) -> None:
        r = self.HR - self.s(3)
        for a in range(200, 262, 2):
            x, y = self.HX + r * math.cos(math.radians(a)), self.HY + r * math.sin(math.radians(a))
            for t in range(self.n(2)):
                cv.px(int(x) + t, int(y), "white")
        cv.px(int(self.HX - self.s(6)), int(self.HY - self.s(11)), "white")
        r = self.HR - self.s(2)
        for a in range(20, 70, 4):                        # brilho fraco do lado oposto
            cv.px(int(self.HX + r * math.cos(math.radians(a))), int(self.HY + r * math.sin(math.radians(a))), "ice")

    def helmet_ring(self, cv: Canvas) -> None:
        w = self.s(10)
        for x in range(int(self.HX - w), int(self.HX + w) + 1):
            dy = int(round(((x - self.HX) / w) ** 2 * self.s(2)))
            y = int(self.HY + self.HR) - dy
            cv.px(x, y - 2, "slate")
            cv.px(x, y - 1, "steel" if x < self.HX + self.s(5) else "lilac_grey")
            if self.k >= 1.4:
                cv.px(x, y, "lilac_grey")

    def body(self, pose: str = "rest", legs: str = "stand", blink: bool = False, tail_up: int = 0,
             breathe: int = 0, worried: bool = False) -> Canvas:
        """breathe = 1 abaixa o capacete 1 px (respiração sutil, alternar com 0)."""
        s, p = self.s, self.p
        hy0 = self.HY
        self.HY = hy0 + breathe
        cv = Canvas(self.W, self.H)
        back = Canvas(self.W, self.H)                      # mochila (atrás, lado direito)
        back.rect(round(s(39)), round(s(38)), round(s(9)), round(s(16)), "mist")
        sphere(back, s(43.5), s(38), s(4.5), s(2.2), SUIT)
        back.vline(round(s(46)), round(s(39)), round(s(53)), "steel")
        back.vline(round(s(47)), round(s(39)), round(s(53)), "lilac_grey")
        back.rect(round(s(41)), round(s(41)), self.n(1), self.n(1), "aqua")
        back.rect(round(s(41)), round(s(44)), self.n(1), self.n(1), "sea")
        cv.stamp(back)
        self.tail(cv, [(20, 55), (13, 57), (7, 54), (5, 48 - tail_up), (7, 42 - tail_up), (11, 40 - tail_up),
                       (13, 42 - tail_up)])
        for a, b in LEGS[legs]:                            # pernas + botinhas
            (ax, ay), (bx, by) = p(a), p(b)
            capsule(cv, ax, ay, bx, by - s(2), s(3.4), SUIT)
            sphere(cv, bx + s(1 if b[0] > 31 else -1), by - s(1), s(4.2), s(2.6), BOOT)
        sphere(cv, s(31), s(48), s(12.5), s(10), SUIT)      # corpo (traje gordinho)
        for x in range(int(s(19)), int(s(44))):            # faixa sea (cinto) acompanhando a barriga
            y = int(s(51) + round(((x - s(31)) / s(12)) ** 2 * s(1.5)))
            for t in range(self.n(1)):
                if cv.get(x, y + t) is not None:
                    cv.px(x, y + t, "sea")
            if cv.get(x, y + self.n(1)) is not None:
                cv.px(x, y + self.n(1), "teal")
        px0, py0 = round(s(27)), round(s(43))              # painel do peito
        cv.rect(px0, py0, round(s(7)), round(s(5)), "mist")
        d = self.n(1)
        for i, col in enumerate(("aqua", "lemon", "hot_pink")):
            cv.rect(px0 + round(s(1 + 2 * i)), py0 + round(s(1)), d, d, col)
        cv.hline(px0 + round(s(1)), px0 + round(s(5)), py0 + round(s(3)), "steel")
        for a, b in ARMS[pose]:                            # braços
            (ax, ay), (bx, by) = p(a), p(b)
            capsule(cv, ax, ay, bx, by, s(3.2), SUIT)
            sphere(cv, bx, by, s(3.4), s(3.4), BOOT)
        self.helmet_glass(cv)                              # capacete
        self.head(cv, blink, worried)
        self.helmet_shine(cv)
        if worried:                                        # gotinha de suor no vidro
            gx, gy = round(self.HX + s(10)), round(self.HY - s(4))
            cv.rect(gx, gy, self.n(2), self.n(3), "pale_sky"); cv.px(gx, gy + self.n(3), "sky")
            cv.px(gx, gy - 1, "pale_sky")
        self.helmet_ring(cv)
        ax = round(self.HX + s(9))                         # antena com bolinha (assinatura do capacete)
        for t in range(self.n(1)):
            cv.vline(ax + t, round(self.HY - self.HR - s(3)), round(self.HY - self.HR + s(2)), "steel")
        sphere(cv, ax + s(0.5) * (self.k > 1.2), self.HY - self.HR - s(5), s(2.4), s(2.4),
               ["white", "pink", "hot_pink", "raspberry"])
        if pose == "thumb":                                # polegar para cima saindo da luva
            hx, hy = self.p(ARMS["thumb"][1][1])
            cv.rect(round(hx - s(1)), round(hy - s(5.5)), self.n(2), round(s(3)), "aqua")
            cv.px(round(hx - s(1)), round(hy - s(5.5)), "ice")
        cv.outline("ink")
        self.HY = hy0
        return cv


def body(pose: str = "rest", legs: str = "stand", blink: bool = False, tail_up: int = 0, k: float = 1.0,
         breathe: int = 0) -> Canvas:
    return Cat(k).body(pose, legs, blink, tail_up, breathe)


def frames(k: float = 1.0) -> dict:
    c = Cat(k)
    return {
        "rest": c.body(), "blink": c.body(blink=True),
        "wave0": c.body("wave0"), "wave1": c.body("wave1"), "wave2": c.body("wave2"),
        "float": c.body("float", "float", tail_up=3), "hold": c.body("hold"),
        "thumb": c.body("thumb", tail_up=2), "worried": c.body("hold", worried=True),
    }


if __name__ == "__main__":
    from PIL import Image
    for k, tag, S in ((1.0, "", 4), (1.6, "_big", 3)):
        fs = frames(k)
        s = fs["rest"]
        print(f"k={k}", s.w, "x", s.h, "cores:", len(s.colors_used()), "lint:", s.lint(max_colors=24)[:3])
        pad = 6
        sheet = Image.new("RGB", (len(fs) * (s.w * S + pad) + pad, s.h * S + 2 * pad), (252, 167, 144))
        for i, (name, c) in enumerate(fs.items()):
            im = c.to_image().resize((c.w * S, c.h * S), Image.NEAREST)
            sheet.paste(im, (pad + i * (c.w * S + pad), pad), im)
        sheet.save(f"art/previews/cat_hero{tag}_sheet.png")
        print(f"art/previews/cat_hero{tag}_sheet.png")
