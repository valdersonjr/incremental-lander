"""Moradores dos mundos novos de CORPO INTEIRO para a conversa do pedido (Fase 18.5, 2026-10-07).
Skill pixel-art, mesmo molde do ratinho (mouse_hero.py, padrão mouse-dialogue): primitivas com volume (sphere/capsule),
coordenadas em k=1 × k, proporção chibi (cabeça ≈ 60%), contorno ink, virado para a ESQUERDA (o gatinho fica à
esquerda). Moldura 44x56 em k=1 (talk: k=1.25 → 55x70). Poses: rest (segura a carga), talk, happy (braços para cima,
pulinho); blink. Cada um segura a carga do pedido-assinatura do mundo:
  nuvens · carneirinho (Passageiro: sem carga, é ele que se perdeu) · cogumelos · sapinho com o ovinho (Pouso suave)
  sorvete · pinguim com o picolé (Rápida) · jardim · abelhinha com o pote de mel (Pesada) · bolhas · caranguejinho com
  o baú (Cabo).
Exporta assets/sprites/talk_<mundo>.png (+ _frames.tres) e o palco assets/ui/talk_stage_<mundo>.png (camadas do
próprio cenário, como o da Lua em art/src/ui/mission_talk.py).
Rodar da raiz: python3 art/src/sprites/world_npcs.py            -> art/previews/world_npcs_sheet.png
               python3 art/src/sprites/world_npcs.py --export
"""
import json
import math
import sys

sys.path.insert(0, ".claude/skills/pixel-art/scripts")
sys.path.insert(0, "art/src/sprites")
sys.path.insert(0, "art/src/ui")
from pixelart import *
from cat_hero import sphere, capsule
import cargo

K = 1.25
WORLDS = ["nuvens", "cogumelos", "sorvete", "jardim", "bolhas"]


def egg() -> Canvas:
    k = Canvas(12, 14)
    sphere(k, 5.5, 7.5, 4.6, 5.8, ["white", "white", "cream", "peach"])
    for x, y in ((4, 5), (7, 8), (5, 10)):
        k.px(x, y, "sprout")
    k.outline("ink")
    return k


def honey() -> Canvas:
    k = Canvas(14, 14)
    sphere(k, 6.5, 8.5, 5.8, 4.8, ["lemon", "gold", "amber", "copper"])
    k.rect(3, 2, 8, 3, "white"); k.hline(3, 10, 4, "mist")
    k.rect(4, 9, 6, 3, "cream"); k.px(5, 10, "amber"); k.px(8, 10, "amber")      # rótulo
    k.vline(9, 5, 7, "gold")                                                      # mel escorrendo
    k.outline("ink")
    return k


def chest() -> Canvas:
    import minigame_props as mp
    return mp.chest()


SPECIES = {
    "nuvens": {"cargo": None},
    "cogumelos": {"cargo": egg},
    "sorvete": {"cargo": cargo.icecream},
    "jardim": {"cargo": honey},
    "bolhas": {"cargo": chest},
}
ARMS = {
    "rest": [((15, 37), (14, 43)), ((29, 37), (29, 43))],
    "talk": [((15, 37), (13, 40)), ((29, 37), (28, 40))],
    "happy": [((15, 36), (8, 28)), ((29, 36), (35, 28))],
}
HOLD = {"rest": (21, 43), "talk": (20, 40)}


class Npc:
    def __init__(self, world: str, k: float = K):
        self.w, self.k = world, k
        self.W, self.H = int(44 * k), int(56 * k)
        self.HX, self.HY = 21 * k, 21 * k

    def s(self, v: float) -> float:
        return v * self.k

    def n(self, v: float) -> int:
        return max(int(v), int(round(v * self.k)))

    # --- rosto comum: olhos grandes com brilho, bochecha, boca ---------------------------------------------------
    def face(self, cv: Canvas, cx: float, cy: float, blink: bool, talk: bool, gap: float = 10, cheek: str = "pink",
             mouth_dy: float = 7) -> None:
        ey = round(cy)
        ew, eh = self.n(3), self.n(4)
        for ox in (-gap / 2 - 3, gap / 2 - 1):
            x0 = round(cx + self.s(ox))
            if blink:
                cv.hline(x0, x0 + ew - 1, ey + eh // 2, "ink")
            else:
                cv.rect(x0, ey, ew, eh, "ink")
                cv.rect(x0, ey, max(1, ew // 2), max(1, ew // 2), "white")
        for ox in (-gap / 2 - 6, gap / 2 + 2):
            cv.rect(round(cx + self.s(ox)), round(cy + self.s(5)), self.n(2), max(1, self.n(1)), cheek)
        mx, my = round(cx - self.s(2)), round(cy + self.s(mouth_dy))
        if talk:
            cv.rect(mx - 1, my, self.n(3), self.n(2), "ink"); cv.px(mx, my + self.n(2) - 1, "rose")
        else:
            cv.px(mx - 1, my, "ink"); cv.px(mx + 1, my, "ink"); cv.px(mx, my + 1, "ink")

    def arms(self, cv: Canvas, pose: str, ramp: list, hand: list) -> None:
        for a, b in ARMS[pose]:
            ax, ay, bx, by = self.s(a[0]), self.s(a[1]), self.s(b[0]), self.s(b[1])
            capsule(cv, ax, ay, bx, by, self.s(2.4), ramp)
            sphere(cv, bx, by, self.s(2.6), self.s(2.6), hand)

    # --- espécies ------------------------------------------------------------------------------------------------
    def sheep(self, cv, pose, blink, talk):
        s = self.s
        wool = ["white", "white", "mist", "lavender"]
        for fx in (16, 27):
            capsule(cv, s(fx), s(46), s(fx), s(51), s(2.2), ["lavender", "violet", "violet", "purple"])
        for bx, by in ((15, 38), (22, 36), (29, 38), (17, 44), (27, 44), (22, 43)):
            sphere(cv, s(bx), s(by), s(5.5), s(5), wool)
        cv.outline("ink")
        if pose == "happy":
            self.arms(cv, pose, wool, ["lavender", "violet", "violet", "purple"])
        cx, cy = self.HX, self.HY
        for ox, oy in ((-10, -6), (-3, -10), (5, -10), (11, -5), (13, 3), (-12, 2)):      # topete de lã
            sphere(cv, cx + s(ox), cy + s(oy), s(5.5), s(5), wool)
        for sd in (-1, 1):                                                                 # orelhinhas de lado
            sphere(cv, cx + sd * s(13), cy + s(1), s(4.5), s(2.4), ["lavender", "violet", "violet", "purple"])
        sphere(cv, cx, cy + s(3), s(10), s(9.5), ["lavender", "lavender", "lavender", "violet"])  # rosto lilás
        self.face(cv, cx, cy + s(1), blink, talk)
        for ox, oy in ((-5, -8), (3, -9)):                                                # cachinhos na testa
            sphere(cv, cx + s(ox), cy + s(oy), s(4.5), s(3.5), wool)

    def frog(self, cv, pose, blink, talk):
        s = self.s
        g = ["lime", "leaf", "emerald", "green"]
        for fx in (15, 28):
            sphere(cv, s(fx), s(51), s(5), s(2.4), g)
        sphere(cv, s(22), s(42), s(10), s(9), g)
        sphere(cv, s(21), s(44), s(6), s(5.5), ["white", "cream", "cream", "peach"])
        cv.outline("ink")
        if pose == "happy":
            self.arms(cv, pose, g, g)
        cx, cy = self.HX, self.HY + s(4)
        for ex in (-8, 6):                                                                 # olhos no alto
            sphere(cv, cx + s(ex), cy - s(10), s(5.5), s(5.5), g)
        sphere(cv, cx, cy, s(15), s(10), g)
        for ex in (-8, 6):
            sphere(cv, cx + s(ex), cy - s(10), s(3.6), s(3.6), ["white", "white", "white", "mist"])
            x0, y0 = round(cx + s(ex - 1)), round(cy - s(11))
            if blink:
                cv.hline(x0 - 1, x0 + self.n(3), y0 + self.n(2), "ink")
            else:
                cv.rect(x0, y0, self.n(2), self.n(3), "ink"); cv.px(x0, y0, "white")
        for ox in (-12, 8):
            cv.rect(round(cx + s(ox)), round(cy + s(1)), self.n(3), self.n(1), "pink")
        y = round(cy + s(3))                                                               # sorrisão
        if talk:
            sphere(cv, cx - s(2), cy + s(4), s(4), s(2.2), ["rose", "rose", "red", "crimson"])
        else:
            for i in range(-self.n(5), self.n(4)):
                cv.px(round(cx - s(2)) + i, y + (1 if abs(i) < self.n(3) else 0), "pine")

    def penguin(self, cv, pose, blink, talk):
        s = self.s
        dark = ["slate", "slate", "shadow", "ink"]
        for fx in (16, 27):
            sphere(cv, s(fx), s(51), s(4.5), s(2), ["lemon", "gold", "amber", "copper"])
        sphere(cv, s(22), s(41), s(10.5), s(10), dark)
        sphere(cv, s(21), s(43), s(7), s(7.5), ["white", "white", "mist", "mist"])
        cv.outline("ink")
        if pose == "happy":
            self.arms(cv, pose, dark, dark)
        cx, cy = self.HX, self.HY
        sphere(cv, cx, cy, s(13), s(11.5), dark)
        sphere(cv, cx - s(1), cy + s(2), s(9.5), s(8), ["white", "white", "white", "mist"])  # máscara branca
        self.face(cv, cx, cy, blink, False, gap=9, mouth_dy=20)
        bx, by = round(cx - s(3)), round(cy + s(5))                                       # bico laranja p/ esquerda
        sphere(cv, bx, by, s(3.2), s(1.8), ["lemon", "gold", "amber", "copper"])
        if talk:
            cv.hline(bx - self.n(2), bx + self.n(1), by + 1, "copper")
        for y in range(round(cy + s(10)), round(cy + s(13))):                             # cachecol
            cv.hline(round(cx - s(10)), round(cx + s(10)), y, "red")
        cv.hline(round(cx - s(10)), round(cx + s(10)), round(cy + s(10)), "salmon")
        cv.rect(round(cx + s(6)), round(cy + s(12)), self.n(3), self.n(7), "red")
        sphere(cv, cx + s(2), cy - s(12), s(6), s(3), ["salmon", "red", "red", "crimson"])  # gorrinho
        sphere(cv, cx + s(2), cy - s(16), s(2.4), s(2.4), ["white", "white", "mist", "mist"])

    def bee(self, cv, pose, blink, talk):
        s = self.s
        y = ["lemon", "gold", "gold", "amber"]
        for wx in (30, 35):                                                                # asinhas
            sphere(cv, s(wx), s(28), s(6), s(8), ["white", "white", "pale_sky", "pale_sky"])
        for fx in (17, 27):
            sphere(cv, s(fx), s(51), s(3.4), s(2), ["shadow", "slate", "slate", "ink"])
        sphere(cv, s(22), s(41), s(10), s(9.5), y)
        for by in (38, 44):
            for x in range(int(s(12)), int(s(33))):
                for t in range(self.n(2)):
                    if cv.get(x, round(s(by)) + t) is not None:
                        cv.px(x, round(s(by)) + t, "shadow")
        cv.outline("ink")
        if pose == "happy":
            self.arms(cv, pose, ["shadow", "slate", "slate", "ink"], y)
        cx, cy = self.HX, self.HY
        for sd in (-1, 1):                                                                 # anteninhas
            cv.line(round(cx + sd * s(4)), round(cy - s(10)), round(cx + sd * s(7)), round(cy - s(17)), "ink")
            sphere(cv, cx + sd * s(7), cy - s(18), s(2), s(2), ["salmon", "red", "red", "crimson"])
        sphere(cv, cx, cy, s(12.5), s(11.5), y)
        self.face(cv, cx, cy, blink, talk)

    def crab(self, cv, pose, blink, talk):
        s = self.s
        r = ["salmon", "red", "red", "crimson"]
        for i, fx in enumerate((11, 16, 28, 33)):                                          # perninhas
            capsule(cv, s(fx), s(44), s(fx + (-3 if fx < 22 else 3)), s(51), s(1.6), r)
        cv.outline("ink")
        if pose == "happy":                                                                # garras para cima
            for sd, hx in ((-1, 6), (1, 38)):
                capsule(cv, s(22 + sd * 9), s(38), s(hx), s(26), s(2.2), r)
                sphere(cv, s(hx), s(22), s(4.5), s(5), r)
                cv.line(round(s(hx)), round(s(18)), round(s(hx)), round(s(24)), "ink")
        cx, cy = self.HX + s(1), self.HY + s(14)
        for ex in (-6, 6):                                                                 # olhos nas anteninhas
            cv.vline(round(cx + s(ex)), round(cy - s(18)), round(cy - s(8)), "crimson")
            sphere(cv, cx + s(ex), cy - s(19), s(4), s(4), ["white", "white", "white", "mist"])
            x0, y0 = round(cx + s(ex - 1.5)), round(cy - s(20))
            if blink:
                cv.hline(x0, x0 + self.n(3), y0 + self.n(1), "ink")
            else:
                cv.rect(x0, y0, self.n(2), self.n(3), "ink"); cv.px(x0, y0, "white")
        sphere(cv, cx, cy, s(16), s(10.5), r)                                              # casco
        for ox in (-11, 9):
            cv.rect(round(cx + s(ox)), round(cy + s(1)), self.n(3), self.n(1), "pink")
        mx, my = round(cx - s(1)), round(cy + s(3))
        if talk:
            cv.rect(mx - 1, my, self.n(3), self.n(2), "ink")
        else:
            cv.px(mx - 1, my, "ink"); cv.px(mx + 1, my, "ink"); cv.px(mx, my + 1, "ink")

    # --- montagem ------------------------------------------------------------------------------------------------
    def draw(self, pose: str = "rest", blink: bool = False, hop: int = 0) -> Canvas:
        cv = Canvas(self.W, self.H)
        {"nuvens": self.sheep, "cogumelos": self.frog, "sorvete": self.penguin, "jardim": self.bee,
         "bolhas": self.crab}[self.w](cv, pose, blink, pose in ("talk", "happy"))
        cv.outline("ink")
        if pose != "happy":
            fn = SPECIES[self.w]["cargo"]
            hx, hy = HOLD[pose]
            if self.w == "bolhas":                                   # o caranguejo segura com as garras na frente
                hy += 4
            if fn:
                c = fn()
                cv.stamp(c, round(self.s(hx)) - c.w // 2, round(self.s(hy)) - c.h // 2)
            if self.w != "bolhas":
                hands = Canvas(self.W, self.H)
                ramp = {"nuvens": ["white", "white", "mist", "lavender"], "cogumelos": ["lime", "leaf", "emerald", "green"],
                        "sorvete": ["slate", "slate", "shadow", "ink"], "jardim": ["shadow", "slate", "slate", "ink"]}[self.w]
                self.arms(hands, pose, ramp, ramp)
                hands.outline("ink")
                cv.stamp(hands)
            else:
                cl = Canvas(self.W, self.H)
                for hx2 in (hx - 9, hx + 9):
                    sphere(cl, self.s(hx2), self.s(hy), self.s(4), self.s(4.5), ["salmon", "red", "red", "crimson"])
                cl.outline("ink")
                cv.stamp(cl)
        if hop:
            out = Canvas(self.W, self.H)
            out.stamp(cv, 0, -hop)
            cv = out
        return cv


def anims(world: str) -> list:
    m = Npc(world)
    rest, blink = m.draw(), m.draw(blink=True)
    idle = Animation("idle")
    idle.add(rest, 1000).add(blink, 120).add(rest, 800)
    talk = Animation("talk")
    talk.add(m.draw("talk"), 140).add(rest, 140).add(m.draw("talk"), 140).add(rest, 300)
    happy = Animation("happy")
    happy.add(m.draw("happy", hop=4), 160).add(m.draw("happy"), 160)
    return [idle, talk, happy]


def stage(world: str) -> Canvas:
    """Palco 408x112 da conversa: céu + nuvens + foco (sol/lua) + morros distantes do próprio mundo."""
    import mission_talk as mt
    import save_card_bg
    meta = json.load(open(f"assets/bg/{world}_layers.json"))
    w = mt.STAGE_X + mt.STAGE_W
    cv = Canvas(w, 360)
    sky = save_card_bg.frame0(f"assets/bg/{world}_sky.png", meta["anim"]["sky"]["frames"])
    clouds = save_card_bg.frame0(f"assets/bg/{world}_clouds.png", meta["anim"]["clouds"]["frames"])
    far = Canvas.from_image(f"assets/bg/{world}_far.png")
    planet = Canvas.from_image(f"assets/bg/{world}_planet.png")
    for layer, y in ((sky, 0), (clouds, meta["clouds"]["y"])):
        for x in range(0, w, layer.w):
            cv.stamp(layer, x, y)
    cv.stamp(planet, mt.STAGE_X + mt.STAGE_W // 2 - planet.w // 2 + 30, mt.STAGE_Y - 34)
    for x in range(0, w, far.w):
        cv.stamp(far, x, meta["far_y"])
    return cv.crop(mt.STAGE_X, mt.STAGE_Y, mt.STAGE_W, mt.STAGE_H)


if __name__ == "__main__":
    if "--export" in sys.argv:
        for w in WORLDS:
            save_animations(anims(w), f"assets/sprites/talk_{w}.png", res_path=f"res://assets/sprites/talk_{w}.png",
                            tres_path=f"assets/sprites/talk_{w}_frames.tres", preview_dir="art/previews")
            stage(w).save(f"assets/ui/talk_stage_{w}.png", preview_dir="art/previews")
        print("exportado")
    else:
        from PIL import Image
        S, pad = 3, 6
        rows = []
        for w in WORLDS:
            m = Npc(w)
            rows.append([m.draw(), m.draw(blink=True), m.draw("talk"), m.draw("happy", hop=4)])
        w0, h0 = rows[0][0].w, rows[0][0].h
        sheet = Image.new("RGB", (4 * (w0 * S + pad) + pad, len(rows) * (h0 * S + pad) + pad), (252, 167, 144))
        for r, fs in enumerate(rows):
            for i, c in enumerate(fs):
                im = c.to_image().resize((c.w * S, c.h * S), Image.NEAREST)
                sheet.paste(im, (pad + i * (w0 * S + pad), pad + r * (h0 * S + pad)), im)
        sheet.save("art/previews/world_npcs_sheet.png")
        print("ok")

# caminhos literais dos assets (o pre-commit procura a fonte de cada PNG pelo caminho escrito no script):
# assets/sprites/talk_nuvens.png assets/sprites/talk_cogumelos.png assets/sprites/talk_sorvete.png
# assets/sprites/talk_jardim.png assets/sprites/talk_bolhas.png assets/ui/talk_stage_nuvens.png
# assets/ui/talk_stage_cogumelos.png assets/ui/talk_stage_sorvete.png assets/ui/talk_stage_jardim.png
# assets/ui/talk_stage_bolhas.png
