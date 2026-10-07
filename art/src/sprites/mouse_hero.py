"""Ratinhos das missões de CORPO INTEIRO (janela de conversa do pedido, 2026-10-07). Skill pixel-art, padrões
mission-mice + title-screen + mouse-dialogue. Mesmo jeito do gatinho herói (cat_hero.py): primitivas com volume
(esfera/cápsula), coordenadas de desenho em k=1 multiplicadas por k, contorno ink de 1 px no fim. Proporção chibi
(cabeça ≈ 60% da altura), orelhonas redondas, corpo de pera, membros curtinhos, rabinho fino enrolado. Cada tipo
mantém o pelo e o acessório-assinatura do rostinho 24x24 (kids_ui.MISSION_MICE) e segura a sua carga (cargo.py).

Virado para a ESQUERDA (conversa com o gatinho, que fica à esquerda olhando para a direita).
Poses: rest (segura a carga), talk (boca aberta, carga um pouco erguida), happy (braços para cima, pulinho);
blink = piscar. k=1 → 44x56; k=1.5 → 66x84.
Rodar da raiz: python3 art/src/sprites/mouse_hero.py   -> art/previews/mouse_hero_sheet.png
"""
import math
import sys

sys.path.insert(0, ".claude/skills/pixel-art/scripts")
sys.path.insert(0, "art/src/sprites")
from pixelart import *
from cat_hero import sphere, capsule, _ri
import cargo

# pelo [brilho, luz, base, sombra] e dentro da orelha, iguais aos rostinhos 24x24
KINDS = {
    "simple": {"fur": ["white", "white", "mist", "steel"], "inner": "pink", "cargo": "box"},
    "heavy": {"fur": ["honey", "copper", "terracotta", "rust"], "inner": "salmon", "cargo": "weight", "wide": 1.15},
    "soft": {"fur": ["cream", "peach", "salmon", "rose"], "inner": "hot_pink", "cargo": "cake"},
    "fast": {"fur": ["white", "mist", "steel", "lilac_grey"], "inner": "pink", "cargo": "icecream"},
    "passenger": {"fur": ["mist", "steel", "lilac_grey", "slate"], "inner": "pink", "cargo": None},
    "tow": {"fur": ["white", "lavender", "violet", "purple"], "inner": "hot_pink", "cargo": "wheel"},
    "double": {"fur": ["copper", "rust", "wine", "maroon"], "inner": "salmon", "cargo": "star_icon"},
}
BELLY = {"simple": "white", "heavy": "honey", "soft": "cream", "fast": "white", "passenger": "mist",
         "tow": "white", "double": "copper"}

ARMS = {  # (ombro -> mão), k=1; virado para a esquerda
    "rest": [((15, 37), (14, 43)), ((29, 37), (29, 43))],
    "talk": [((15, 37), (13, 40)), ((29, 37), (28, 40))],
    "happy": [((15, 36), (8, 28)), ((29, 36), (35, 28))],
}
HOLD = {"rest": (21, 43), "talk": (20, 40)}       # centro da carga (k=1), na frente da barriga


class Mouse:
    def __init__(self, kind: str, k: float = 1.0):
        self.kind, self.k = kind, k
        self.cfg = KINDS[kind]
        self.W, self.H = int(44 * k), int(56 * k)
        self.HX, self.HY = 21 * k, 21 * k

    def s(self, v: float) -> float:
        return v * self.k

    def n(self, v: float) -> int:
        return max(int(v), int(round(v * self.k)))

    # --- partes -------------------------------------------------------------------------------------------------
    def ears(self, cv: Canvas) -> None:
        fur = self.cfg["fur"]
        for ex, ey in ((9, 10), (32, 9)):
            sphere(cv, self.s(ex), self.s(ey) + self.HY - self.s(21), self.s(8), self.s(7.5), fur)
        ins = Canvas(self.W, self.H)
        for ex, ey in ((9, 10), (32, 9)):
            sphere(ins, self.s(ex + 0.5), self.s(ey + 0.8) + self.HY - self.s(21), self.s(5), self.s(4.6),
                   ["pink", self.cfg["inner"], self.cfg["inner"], "rose"])
        cv.stamp(ins)

    def head(self, cv: Canvas, blink: bool, talk: bool) -> None:
        cx, cy, k = self.HX, self.HY, self.k
        w = self.cfg.get("wide", 1.0)
        sphere(cv, cx, cy, self.s(13.5 * w), self.s(11.5), self.cfg["fur"])
        ey = round(cy + self.s(0.5))
        ew, eh = self.n(3), self.n(4)
        for ox in (-8, 2):                                  # olhos (cara virada um pouco para a esquerda)
            x0 = round(cx + self.s(ox))
            if blink:
                cv.hline(x0, x0 + ew - 1, ey + eh // 2, "ink")
                cv.px(x0 - 1, ey + eh // 2 - 1, "ink"); cv.px(x0 + ew, ey + eh // 2 - 1, "ink")
            else:
                cv.rect(x0, ey, ew, eh, "ink")
                g = max(1, ew // 2)
                cv.rect(x0, ey, g, g, "white")
                if k >= 1.4:
                    cv.px(x0 + ew - 1, ey + eh - 1, "slate")
        nx = round(cx - self.s(4))                          # focinho apontando para a esquerda
        sphere(cv, nx + 0.5, cy + self.s(5.5), self.s(2.2), self.s(1.6), ["pink", "pink", "hot_pink", "rose"])
        my = round(cy + self.s(8))
        if talk:                                            # boca aberta (ovalzinho escuro com língua)
            cv.rect(nx - 1, my, self.n(3), self.n(2), "ink")
            cv.px(nx, my + self.n(2) - 1, "rose")
        else:
            cv.px(nx - 1, my, "ink"); cv.px(nx + 1, my, "ink"); cv.px(nx, my + 1, "ink")
        for ox in (-12, 6):                                 # bochechas
            cv.rect(round(cx + self.s(ox)), round(cy + self.s(5)), self.n(2), max(1, self.n(1)), "pink")
        for sd, bx in ((-1, cx - self.s(11)), (1, cx + self.s(9))):   # bigodes
            for dy, tilt in ((0, -1), (2, 1)):
                y = round(cy + self.s(4 + dy))
                cv.line(round(bx), y, round(bx) + sd * self.n(3), y + tilt, "white")

    def tail(self, cv: Canvas, wag: int) -> None:
        pts = [(29, 46), (34, 48), (38, 46), (40, 41 - wag), (38, 37 - wag), (36, 38 - wag)]
        pts = [(self.s(x), self.s(y)) for x, y in pts]
        for (ax, ay), (bx, by) in zip(pts, pts[1:]):
            m = int(math.hypot(bx - ax, by - ay) * 2) + 1
            for i in range(m):
                x, y = ax + (bx - ax) * i / m, ay + (by - ay) * i / m
                r = self.s(1.1)
                sphere(cv, x, y, r, r, ["pink", "pink", "rose", "rose"])

    def body(self, cv: Canvas, pose: str) -> None:
        fur, s = self.cfg["fur"], self.s
        for fx in (16, 27):                                 # pezinhos
            sphere(cv, s(fx), s(50), s(4.2), s(2.6), [fur[0], fur[1], fur[2], fur[3]])
        sphere(cv, s(22), s(41), s(9.5), s(9), fur)         # corpo de pera (encosta na cabeça)
        sphere(cv, s(21), s(43), s(5.5), s(5.5), [BELLY[self.kind]] * 3 + [fur[2]])   # barriguinha

    def arms(self, cv: Canvas, pose: str) -> None:
        for a, b in ARMS[pose]:
            (ax, ay), (bx, by) = (self.s(a[0]), self.s(a[1])), (self.s(b[0]), self.s(b[1]))
            capsule(cv, ax, ay, bx, by, self.s(2.4), self.cfg["fur"])
            sphere(cv, bx, by, self.s(2.6), self.s(2.6), ["white", "pink", "pink", "rose"])

    # --- acessórios (mesma ideia do rostinho 24x24) -----------------------------------------------------------
    def accessory(self, cv: Canvas) -> None:
        cx, cy, s = self.HX, self.HY, self.s
        top = cy - s(11.5)
        if self.kind == "simple":                           # capacete de mineiro com lanterna
            sphere(cv, cx, top + s(4), s(10.5), s(6), ["lemon", "gold", "gold", "amber"])
            cv.rect(round(cx - s(12.5)), round(top + s(7)), round(s(25)), self.n(2), "amber")
            cv.hline(round(cx - s(12.5)), round(cx + s(12.5)), round(top + s(7)), "gold")
            sphere(cv, cx - s(2), top + s(2.5), s(3), s(2.6), ["white", "white", "lemon", "gold"])
        elif self.kind == "soft":                           # chapéu de chef alto e fofo
            sphere(cv, cx, top - s(4), s(9), s(6.5), ["white", "white", "mist", "steel"])
            cv.rect(round(cx - s(7.5)), round(top), round(s(15)), round(s(5)), "white")
            cv.hline(round(cx - s(7.5)), round(cx + s(7.5)), round(top + s(4)), "mist")
            cv.rect(round(cx + s(4)), round(top + s(1.5)), self.n(2), self.n(2), "hot_pink")
        elif self.kind == "fast":                           # boné listrado com aba para a frente (esquerda)
            for y in range(round(top - s(1)), round(top + s(6))):
                for x in range(round(cx - s(9)), round(cx + s(10))):
                    if (x - cx) ** 2 / s(10) ** 2 + (y - top - s(6)) ** 2 / s(7) ** 2 <= 1:
                        cv.px(x, y, "sky" if int((x - cx) / s(2)) % 2 == 0 else "white")
            cv.rect(round(cx - s(17)), round(top + s(5)), round(s(10)), self.n(2), "blue")
        elif self.kind == "heavy":                          # faixa vermelha na testa
            cv.rect(round(cx - s(13)), round(cy - s(6)), round(s(26)), self.n(2), "red")
            cv.hline(round(cx - s(12)), round(cx + s(12)), round(cy - s(6)), "coral")
            cv.rect(round(cx + s(12)), round(cy - s(5)), self.n(2), self.n(4), "red")
        elif self.kind == "passenger":                      # quepe de taxista quadriculado
            sphere(cv, cx, top + s(3), s(10), s(5.5), ["lemon", "gold", "gold", "amber"])     # cúpula do quepe
            yb = round(top + s(5))
            for x in range(round(cx - s(10)), round(cx + s(10)) + 1):                     # faixa quadriculada
                for t in range(self.n(2)):
                    if cv.get(x, yb + t) is not None:
                        cv.px(x, yb + t, "ink" if (x // self.n(2) + t) % 2 == 0 else "white")
            cv.rect(round(cx - s(16)), round(top + s(7)), round(s(11)), self.n(2), "amber")  # aba para a frente
        elif self.kind == "tow":                            # laço grande na orelha
            ex, ey = s(32), self.HY - s(21) + s(5)
            sphere(cv, ex - s(3.5), ey, s(3.2), s(2.6), ["pink", "hot_pink", "hot_pink", "raspberry"])
            sphere(cv, ex + s(3.5), ey, s(3.2), s(2.6), ["pink", "hot_pink", "hot_pink", "raspberry"])
            sphere(cv, ex, ey, s(1.6), s(1.6), ["hot_pink", "raspberry", "raspberry", "wine"])
        elif self.kind == "double":                         # coroinha dourada com pedra verde
            y0 = round(top - s(1))
            cv.rect(round(cx - s(7)), y0, round(s(14)), round(s(4)), "gold")
            cv.hline(round(cx - s(7)), round(cx + s(7)), y0 + round(s(4)) - 1, "amber")
            for ox in (-7, -1, 5):
                x = round(cx + s(ox))
                cv.rect(x, y0 - round(s(3)), self.n(2), round(s(3)), "gold"); cv.px(x, y0 - round(s(3)) - 1, "lemon")
            cv.rect(round(cx - s(1)), y0 + round(s(1)), self.n(2), self.n(2), "emerald")

    # --- montagem ---------------------------------------------------------------------------------------------
    def draw(self, pose: str = "rest", blink: bool = False, wag: int = 0, hop: int = 0) -> Canvas:
        hy0 = self.HY
        cv = Canvas(self.W, self.H)
        self.tail(cv, wag)
        self.body(cv, pose)
        cv.outline("ink")                                   # corpo contornado por baixo da cabeça (pescoço)
        if pose == "happy":
            self.arms(cv, pose)
        self.ears(cv)
        self.head(cv, blink, pose == "talk" or pose == "happy")
        self.accessory(cv)
        cv.outline("ink")
        if pose != "happy" and self.cfg["cargo"]:           # carga segura na frente, mãozinhas por cima
            c = getattr(cargo, self.cfg["cargo"])()
            hx, hy = HOLD[pose]
            cv.stamp(c, round(self.s(hx)) - c.w // 2, round(self.s(hy)) - c.h // 2)
            hands = Canvas(self.W, self.H)
            self.arms(hands, pose)
            hands.outline("ink")
            cv.stamp(hands)
        elif pose != "happy":
            hands = Canvas(self.W, self.H)
            self.arms(hands, pose)
            hands.outline("ink")
            cv.stamp(hands)
        if hop:
            out = Canvas(self.W, self.H)
            out.stamp(cv, 0, -hop)
            cv = out
        self.HY = hy0
        return cv


def frames(kind: str, k: float = 1.5) -> dict:
    m = Mouse(kind, k)
    return {"rest": m.draw(), "blink": m.draw(blink=True), "talk": m.draw("talk"),
            "happy": m.draw("happy", wag=3, hop=round(3 * k))}


if __name__ == "__main__":
    from PIL import Image
    kinds = sys.argv[1:] or list(KINDS)
    S, pad = 3, 6
    rows = [frames(kd) for kd in kinds]
    w0, h0 = rows[0]["rest"].w, rows[0]["rest"].h
    sheet = Image.new("RGB", (4 * (w0 * S + pad) + pad, len(rows) * (h0 * S + pad) + pad), (252, 167, 144))
    for r, fs in enumerate(rows):
        for i, c in enumerate(fs.values()):
            im = c.to_image().resize((c.w * S, c.h * S), Image.NEAREST)
            sheet.paste(im, (pad + i * (w0 * S + pad), pad + r * (h0 * S + pad)), im)
    sheet.save("art/previews/mouse_hero_sheet.png")
    print("art/previews/mouse_hero_sheet.png", w0, "x", h0, "cores:", len(rows[0]["rest"].colors_used()))
