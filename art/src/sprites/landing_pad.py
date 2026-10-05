"""Plataforma de pouso + marcador do alvo (padrão: patterns/landing-pad.md). Estilo FOFO desde 2026-10-04
(receita pixel-art/references/cute-scene-method.md: meia resolução + Scale2x, contorno ink, postes de pirulito).

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


def _scale2x(c: Canvas) -> Canvas:
    sys.path.insert(0, "art/src/bg")
    from moon_cute import scale2x
    return scale2x(c)


def structure(P: Pad) -> Canvas:
    """Estilo FOFO (2026-10-04, receita cute-scene-method): desenhada em meia resolução e ampliada com Scale2x —
    deck branco gordinho com faixa colorida do tipo, pezinhos redondos, postes de pirulito; contorno ink."""
    w2, d0, d1 = P.pw // 2, DX0 // 2, P.dx1 // 2          # meia resolução: deck nas linhas 5..7
    h = Canvas(w2, PH // 2)
    a = P.a
    for x in range(d0, d1 + 1):
        h.px(x, 5, "white"); h.px(x, 6, a["stripe"]); h.px(x, 7, "mist")
    fw = max(2, P.fw // 3)
    for fx in (d0 + 1, d1 - fw):                          # pezinhos: perninha + pé redondo
        mid = fx + fw / 2
        for y in range(8, 14):
            half = 1.0 if y < 11 else 2.2 if y < 13 else 1.6
            for x in range(int(mid - half - 0.5), int(mid + half + 0.5) + 1):
                if abs(x + 0.5 - mid) <= half + 0.01:
                    h.px(x, y, "mist" if x + 0.5 < mid - 0.4 else "steel" if x + 0.5 < mid + 0.8 else "lilac_grey")
    for x in range(d0 + fw + 2, d1 - fw - 1):             # sombrinha sob o deck
        h.px(x, 8, "lilac_grey")
    for lx in (P.lamps[0] // 2, P.lamps[1] // 2):         # postes de pirulito
        for y in range(3, 8):
            h.px(lx, y, "steel")
    c = _scale2x(h)
    full = Canvas(P.pw, PH)
    full.stamp(c)
    if a.get("hazard"):                                   # bengala: listras diagonais vermelho/branco
        for x in range(DX0 + 1, P.dx1):
            for y in (TOP + 2, TOP + 3):
                full.px(x, y, "white" if ((x + y) // 3) % 2 else "red")
    if a.get("dashes"):
        for x in range(DX0 + 2, P.dx1 - 1):
            if (x - DX0 - 2) % 6 < 3:
                full.px(x, TOP + 3, "honey")
    full.outline("ink", inside=False)
    for x in range(DX0 + 2, P.dx1 - 1):                   # brilho no topo do deck
        if full.get(x, TOP) not in (None, resolve("ink")):
            full.px(x, TOP, "white")
    return full


def lights(P: Pad, cv: Canvas, stripe_on: set, lamp_on: bool, dim: bool = False) -> Canvas:
    a = P.a
    for i, x in enumerate(P.stripe_lights):
        c = a["dim"] if dim else a["on"][0] if i in stripe_on else a["off"]
        cv.px(x, TOP + 2, c); cv.px(x + 1, TOP + 2, c)
    import math
    for cx in P.lamps:                                    # bolinha do pirulito (raio 2,5) com contorno ink
        if lamp_on:
            ramp = [a["lamp"][0], a["lamp"][1], a["lamp"][2], a["lamp"][2]]
        else:
            c0, c1 = a["lamp_dim"] if dim else a["lamp_off"]
            ramp = [c0, c0, c1, c1]
        cy = TOP - 9
        for y in range(cy - 4, cy + 4):
            for x in range(cx - 4, cx + 4):
                d = math.hypot(x + 0.5 - (cx + 0.5), y + 0.5 - (cy + 0.5))
                if d <= 2.6:
                    nx, ny = (x - cx) / 2.6, (y - cy) / 2.6
                    i = -0.6 * nx - 0.7 * ny
                    cv.px(x, y, ramp[0] if i > 0.45 else ramp[1] if i > -0.1 else ramp[2])
                elif d <= 3.5:
                    cv.px(x, y, "ink")
        cv.px(cx - 1, cy - 1, "white")
    return cv


def deck_glow(P: Pad, cv: Canvas, f: int) -> Canvas:
    """Alvo: o topo do deck brilha em ondas do centro para fora."""
    mid = (DX0 + P.dx1) / 2
    for x in range(DX0 + 2, P.dx1 - 1):
        d = abs(x - mid)
        lit = int(d) % 8 in ((f * 2) % 8, (f * 2 + 1) % 8)
        cv.px(x, TOP + 1, P.a["on"][0] if lit else "white")
    return cv


def pad_frames(kind: str = "normal"):
    P = Pad(kind)
    idle = lights(P, structure(P), set(), False, dim=True)
    n = len(P.stripe_lights)
    target = []
    for f in range(6):
        on = {f, n - 1 - f} if f < (n + 1) // 2 else set()
        target.append(deck_glow(P, lights(P, structure(P), on, lamp_on=f in (0, 1, 2)), f))
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
                lvl = amp * (1 - h) ** 1.6 * (0.10 + 0.90 * edge ** 1.5)
                if lvl * 16 > BAYER[y % 4][x % 4] + 0.5:
                    c = "ice" if lvl > 0.75 else "aqua" if lvl > 0.5 else "sea" if lvl > 0.28 else "teal"
                    cv.px(x, y, c)
        for i in range(max(3, round(9 * BW / 64))):      # partículas subindo (laço de 4 quadros)
            px = 6 + (i * 23) % (BW - 12)
            py = BH - 4 - ((i * 17 + f * 7) % (BH - 10))
            cv.px(px, py, "white")                        # brilhinho em cruz
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                if 0 <= px + dx < BW and 0 <= py + dy < BH:
                    cv.px(px + dx, py + dy, "ice" if py > BH * 0.5 else "aqua")
        frames.append(cv)
    return frames


def marker_frames():
    """Setinha gordinha com contorno (fofa), quica."""
    base = Canvas(11, 9)
    base.paint([
        "...bbbbb...",
        "...bcccb...",
        "...bcccb...",
        "bbbbcccbbbb",
        ".bcccccccb.",
        "..bcccccb..",
        "...bcccb...",
        "....bcb....",
        ".....b.....",
    ], {"b": "ink", "c": "aqua"}, x=0, y=0)
    base.px(4, 1, "white"); base.px(4, 2, "ice"); base.px(3, 4, "ice"); base.px(4, 4, "white")
    base.px(6, 5, "sea"); base.px(6, 6, "sea"); base.px(7, 4, "sea")
    frames = []
    for dy in (0, 1, 2, 1):
        f = Canvas(11, 9)
        f.stamp(base.crop(0, 0, 11, 9 - dy), 0, dy)
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
