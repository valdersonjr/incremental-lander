"""Plataforma de pouso + marcador do alvo (padrão: patterns/landing-pad.md; estilo: cena da Lua + lander).

Contrato com o jogo (godot-dev):
  pad   80x28: deck de 64 px (x 8..71) com o TOPO na linha 10 = altura da plataforma no mundo
        -> sprite com canto sup. esq. em (pad.x - 40, pad.y - 10). Animações: idle (apagada), target (luzes vivas).
  marker 11x9: seta ciano que flutua acima do alvo (animação bob).
Paleta Resurrect 64, rampas neutral (estrutura, igual ao casco do lander) + teal (luzes, igual ao propulsor).
Rodar da raiz: python3 art/src/sprites/landing_pad.py [--export]
"""
import sys

sys.path.insert(0, ".claude/skills/pixel-art/scripts")
from pixelart import *

PH = 28
TOP = 10                      # linha do topo do deck (= altura da plataforma)
DX0 = 8                       # deck começa em x=8 (8 px de margem para o poste)

# Destaque por tipo de plataforma (Fase 11): cor de risco + forma (largura, listras) + número escrito pelo jogo.
# normal = turquesa (igual ao lander); estreita = âmbar; apertada = vermelho com listras de perigo.
ACCENTS = {
    "normal": {"stripe": "sea", "off": "teal", "on": ("ice", "aqua"), "dim": "deep_teal",
               "lamp": ("white", "aqua", "teal"), "lamp_off": ("teal", "deep_teal"), "lamp_dim": ("deep_teal", "navy")},
    "narrow": {"stripe": "amber", "off": "orange", "on": ("lemon", "gold"), "dim": "rust",
               "lamp": ("white", "gold", "amber"), "lamp_off": ("amber", "rust"), "lamp_dim": ("rust", "umber"),
               "dashes": True},
    "tight": {"stripe": "red", "off": "crimson", "on": ("peach", "vermilion"), "dim": "maroon",
              "lamp": ("white", "coral", "red"), "lamp_off": ("red", "maroon"), "lamp_dim": ("maroon", "plum_dark"),
              "hazard": True},
}
DECKS = {"normal": 64, "narrow": 40, "tight": 28}


class Pad:
    """Geometria de uma plataforma com deck de deck_w px (contrato: topo do deck na linha TOP, deck em x DX0..DX1)."""

    def __init__(self, kind: str = "normal"):
        self.kind = kind
        self.deck_w = DECKS[kind]
        self.a = ACCENTS[kind]
        self.pw = self.deck_w + 16
        self.dx1 = DX0 + self.deck_w - 1
        self.mid_x = self.pw / 2
        self.lamps = (4, self.pw - 5)
        self.stripe_lights = list(range(DX0 + 4, self.dx1 - 2, 8))
        self.fw = 15 if self.deck_w >= 64 else 11 if self.deck_w >= 40 else 8   # largura das fundações


def structure(P: Pad) -> Canvas:
    cv = Canvas(P.pw, PH)
    DX1 = P.dx1
    # fundação encaixada no chão: blocos que se estreitam (luz de cima-esquerda: face esquerda clara)
    for (x0, x1) in ((DX0 + 3, DX0 + 3 + P.fw), (DX1 - 3 - P.fw, DX1 - 3)):
        for y in range(TOP + 6, PH):
            inset = (y - (TOP + 6)) // 3
            a, b = x0 + inset, x1 - inset
            for x in range(a, b + 1):
                t = (x - a) / max(b - a, 1)
                c = "lilac_grey" if t < 0.2 else "slate" if t < 0.75 else "shadow"
                cv.px(x, y, c)
            cv.px(a, y, "steel" if y < TOP + 12 else "lilac_grey")      # aresta iluminada
        # linha de painel feita com a rampa: sulco escuro com borda clara em cima
        for x in range(x0 + 2, x1 - 1):
            cv.px(x, TOP + 11, "shadow")
            cv.px(x, TOP + 10, "lilac_grey" if cv.get(x, TOP + 10) == resolve("slate") else cv.get(x, TOP + 10))
        cv.px(x0 + 5, TOP + 14, "ink"); cv.px(x1 - 5, TOP + 14, "ink")         # rebites/encaixes
    # treliça entre as fundações (sombra, recuada)
    for x in range(DX0 + P.fw + 4, DX1 - P.fw - 3):
        cv.px(x, TOP + 6, "slate")
        if (x - DX0) % 6 in (0, 1):
            for y in range(TOP + 7, TOP + 10):
                cv.px(x, y, "shadow")
        cv.px(x, TOP + 10, "shadow")
    # deck: topo branco (vê-se de leve de cima), faixa de destaque, borda inferior escura
    for x in range(DX0, DX1 + 1):
        cv.px(x, TOP, "white" if DX0 + 1 < x < DX1 - 10 else "mist")
        cv.px(x, TOP + 1, "mist")
        cv.px(x, TOP + 2, "steel")
        cv.px(x, TOP + 3, P.a["stripe"])
        cv.px(x, TOP + 4, "lilac_grey")
        cv.px(x, TOP + 5, "slate")
    if P.a.get("hazard"):                      # listras de perigo na face do deck (amarelo/preto em diagonal)
        for x in range(DX0 + 1, DX1):
            for y in (TOP + 4, TOP + 5):
                cv.px(x, y, "gold" if ((x + y) // 2) % 2 == 0 else "ink")
    if P.a.get("dashes"):                      # traços âmbar na face do deck (forma diferente das listras da apertada)
        for x in range(DX0 + 2, DX1 - 1):
            if (x - DX0 - 2) % 6 < 3:
                cv.px(x, TOP + 4, "amber")
                cv.px(x, TOP + 5, "rust")
    for x in (DX0, DX1):                       # pontas chanfradas
        cv.px(x, TOP, "clear"); cv.px(x, TOP + 5, "clear")
        cv.px(x, TOP + 1, "steel"); cv.px(x, TOP + 4, "slate")
    for x in range(DX0 + 16, DX1 - 14, 16):    # juntas do deck (painéis)
        cv.px(x, TOP + 2, "lilac_grey")
        if not P.a.get("hazard"):
            cv.px(x, TOP + 4, "slate")
    # postes de sinalização
    for lx in P.lamps:
        left = lx < P.mid_x
        for y in range(TOP - 6, TOP + 6):
            cv.px(lx, y, "steel" if y < TOP else "lilac_grey")
            cv.px(lx + (1 if left else -1), y, "slate")
        cv.px(lx, TOP + 6, "slate"); cv.px(lx + (1 if left else -1), TOP + 6, "shadow")
        for x in range(min(lx, DX0), max(lx, DX0) + 1) if left else range(DX1, lx + 1):
            cv.px(x, TOP + 4, "lilac_grey")    # braço que liga o poste ao deck
    return cv


def lights(P: Pad, cv: Canvas, stripe_on: set, lamp_on: bool, dim: bool = False) -> Canvas:
    a = P.a
    for i, x in enumerate(P.stripe_lights):
        if dim:
            c, c2 = a["dim"], a["dim"]
        elif i in stripe_on:
            c, c2 = a["on"]
        else:
            c, c2 = a["off"], a["off"]
        cv.px(x, TOP + 3, c)
        cv.px(x + 1, TOP + 3, c2)
    for cx in P.lamps:
        if lamp_on:
            core, cross, outer = a["lamp"]
            cv.px(cx, TOP - 8, core)
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                cv.px(cx + dx, TOP - 8 + dy, cross)
            for dx, dy in ((2, 0), (-2, 0), (0, -2)):
                cv.px(cx + dx, TOP - 8 + dy, outer)
        else:
            top, below = a["lamp_dim"] if dim else a["lamp_off"]
            cv.px(cx, TOP - 8, top)
            cv.px(cx, TOP - 7, below)
    return cv


def deck_glow(P: Pad, cv: Canvas, f: int) -> Canvas:
    """Alvo: topo do deck vira pista iluminada (luzes ciano de pouso que pulsam do centro para fora)."""
    mid = (DX0 + P.dx1) / 2
    for x in range(DX0 + 1, P.dx1):
        d = abs(x - mid)
        lit = int(d) % 8 == (f * 2) % 8 or int(d) % 8 == (f * 2 + 1) % 8
        cv.px(x, TOP, "white" if lit else "ice")
        cv.px(x, TOP + 1, "aqua" if lit else "mist")
    return cv


def pad_frames(kind: str = "normal"):
    P = Pad(kind)
    idle = lights(P, structure(P), set(), False, dim=True)
    n = len(P.stripe_lights)
    # luzes correm das pontas para o centro; lâmpadas acesas só no começo do ciclo (~25%)
    target = []
    for f in range(6):
        on = {f, n - 1 - f} if f < (n + 1) // 2 else set()
        target.append(deck_glow(P, lights(P, structure(P), on, lamp_on=f in (0, 1)), f))
    return idle, target


BH = 84                       # feixe do alvo: base (linha de baixo) encostada no topo do deck; largura = deck
BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def beam_frames(kind: str = "normal") -> list:
    """Cone de luz ciano subindo da plataforma alvo. Transparência binária -> 'translúcido' por dither com clear;
    mais forte embaixo e nas bordas, some no alto; pulsa e solta partículas que sobem."""
    BW = DECKS[kind]
    frames = []
    for f, amp in enumerate((1.0, 0.86, 0.74, 0.86)):
        cv = Canvas(BW, BH)
        for y in range(BH):
            h = (BH - 1 - y) / (BH - 1)                  # 0 na base, 1 no topo
            half = BW / 2 - 3 + 3 * h                    # alarga um pouco para cima
            for x in range(BW):
                d = abs(x - (BW - 1) / 2) / half         # 0 no centro, 1 na borda
                if d > 1:
                    continue
                edge = max(0.0, (d - 0.78) / 0.22)       # bordas mais fortes (parede do feixe)
                lvl = amp * (1 - h) ** 1.4 * (0.26 + 0.74 * edge)
                if lvl * 16 > BAYER[y % 4][x % 4] + 0.5:
                    c = "ice" if lvl > 0.75 else "aqua" if lvl > 0.5 else "sea" if lvl > 0.28 else "teal"
                    cv.px(x, y, c)
        for i in range(max(3, round(9 * BW / 64))):      # partículas subindo (laço de 4 quadros)
            px = 6 + (i * 23) % (BW - 12)
            py = BH - 4 - ((i * 17 + f * 7) % (BH - 10))
            cv.px(px, py, "white" if py > BH * 0.5 else "ice")
            if py + 1 < BH:
                cv.px(px, py + 1, "aqua")
        frames.append(cv)
    return frames


def marker_frames():
    base = Canvas(11, 9)
    base.paint([
        "abbbbbbbbba",
        ".abcccccba.",
        "..abcccba..",
        "...abcba...",
        "....aba....",
        ".....a.....",
    ], {"a": "teal", "b": "aqua", "c": "ice"}, x=0, y=0)
    base.px(5, 1, "white"); base.px(5, 2, "white")
    frames = []
    for dy in (0, 1, 2, 1):
        f = Canvas(11, 9)
        f.stamp(base, 0, dy)
        frames.append(f)
    return frames


# saídas por tipo: (plataforma, feixe do alvo) — nomes literais (o pre-commit liga cada PNG ao seu script-fonte)
EXPORTS = {
    "normal": ("assets/sprites/landing_pad.png", "assets/sprites/target_beam.png"),
    "narrow": ("assets/sprites/landing_pad_narrow.png", "assets/sprites/target_beam_narrow.png"),
    "tight": ("assets/sprites/landing_pad_tight.png", "assets/sprites/target_beam_tight.png"),
}


def pad_anims(kind: str) -> list:
    idle, target = pad_frames(kind)
    anims = [Animation("idle").add(idle, 500), Animation("target")]
    for i, fr in enumerate(target):
        anims[1].add(fr, [160, 140, 120, 120, 140, 260][i])
    return anims


def beam_anim(kind: str) -> Animation:
    beam = Animation("pulse")
    for fr, ms in zip(beam_frames(kind), (180, 150, 180, 150)):
        beam.add(fr, ms)
    return beam


if __name__ == "__main__":
    for kind in DECKS:
        idle, target = pad_frames(kind)
        print(kind, "idle", len(idle.colors_used()), idle.lint(max_colors=18))
        print(kind, "target", len(target[0].colors_used()), target[0].lint(max_colors=18))
    marker = Animation("bob")
    for fr, ms in zip(marker_frames(), (220, 160, 220, 160)):
        marker.add(fr, ms)
    if "--export" in sys.argv:
        for kind, (pad_png, beam_png) in EXPORTS.items():
            for anims, png in ((pad_anims(kind), pad_png), ([beam_anim(kind)], beam_png)):
                save_animations(anims, png, res_path="res://" + png, tres_path=png[:-4] + "_frames.tres",
                                preview_dir="art/previews")
        save_animations([marker], "assets/sprites/target_marker.png", res_path="res://assets/sprites/target_marker.png",
                        tres_path="assets/sprites/target_marker_frames.tres", preview_dir="art/previews")
    else:
        for kind, (pad_png, beam_png) in EXPORTS.items():
            for anims, png in ((pad_anims(kind), pad_png), ([beam_anim(kind)], beam_png)):
                save_animations(anims, "art/previews/" + png.split("/")[-1][:-4] + "_wip.png", preview_dir="art/previews")
        save_animations([marker], "art/previews/target_marker_wip.png", preview_dir="art/previews")
        # prévia no estilo: as três plataformas (alvo) com a nave sobre a cena da Lua aprovada
        sys.path.insert(0, "art/src/bg"); sys.path.insert(0, "art/src/terrain")
        import moon_scene as ms
        from moon import profile, ridge_y
        comp = ms.ingame_preview(ms.load_layers(), with_lander=False)
        lander = Canvas.from_image("assets/sprites/lander.png").crop(0, 0, 32, 32)
        y = 300
        for i, kind in enumerate(DECKS):
            P = Pad(kind)
            cx = 150 + i * 170
            idle, target = pad_frames(kind)
            fr = target[0] if kind == "normal" else idle
            if kind == "normal":
                comp.stamp(beam_frames(kind)[0], cx - P.deck_w // 2, y - BH)
                comp.stamp(marker_frames()[0], cx - 5, y - BH - 8)
            comp.stamp(fr, cx - P.deck_w // 2 - DX0, y - TOP)
            comp.stamp(lander, cx - 16, y - 25)
        comp.save("art/previews/landing_pad_scene.png", preview=False)
        comp.crop(60, 200, 520, 140).preview("art/previews/landing_pad_scene_zoom.png", scale=3, grid=False, show_1x=False)
