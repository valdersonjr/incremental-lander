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

PW, PH = 80, 28
TOP = 10                      # linha do topo do deck (= altura da plataforma)
DX0, DX1 = 8, 71              # deck de 64 px
LAMPS = (4, 75)               # x dos postes
STRIPE_LIGHTS = list(range(DX0 + 4, DX1 - 2, 8))   # luzes embutidas na faixa


def structure() -> Canvas:
    cv = Canvas(PW, PH)
    # fundação encaixada no chão: blocos que se estreitam (luz de cima-esquerda: face esquerda clara)
    for (x0, x1) in ((DX0 + 3, DX0 + 18), (DX1 - 18, DX1 - 3)):
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
    for x in range(DX0 + 19, DX1 - 18):
        cv.px(x, TOP + 6, "slate")
        if (x - DX0) % 6 in (0, 1):
            for y in range(TOP + 7, TOP + 10):
                cv.px(x, y, "shadow")
        cv.px(x, TOP + 10, "shadow")
    # deck: topo branco (vê-se de leve de cima), faixa turquesa como no lander, borda inferior escura
    for x in range(DX0, DX1 + 1):
        cv.px(x, TOP, "white" if DX0 + 1 < x < DX1 - 10 else "mist")
        cv.px(x, TOP + 1, "mist")
        cv.px(x, TOP + 2, "steel")
        cv.px(x, TOP + 3, "sea")
        cv.px(x, TOP + 4, "lilac_grey")
        cv.px(x, TOP + 5, "slate")
    for x in (DX0, DX1):                       # pontas chanfradas
        cv.px(x, TOP, "clear"); cv.px(x, TOP + 5, "clear")
        cv.px(x, TOP + 1, "steel"); cv.px(x, TOP + 4, "slate")
    for x in range(DX0 + 16, DX1 - 14, 16):    # juntas do deck (painéis)
        cv.px(x, TOP + 2, "lilac_grey"); cv.px(x, TOP + 4, "slate")
    # postes de sinalização
    for lx in LAMPS:
        for y in range(TOP - 6, TOP + 6):
            cv.px(lx, y, "steel" if y < TOP else "lilac_grey")
            cv.px(lx + (1 if lx < 40 else -1), y, "slate")
        cv.px(lx, TOP + 6, "slate"); cv.px(lx + (1 if lx < 40 else -1), TOP + 6, "shadow")
        for x in range(min(lx, DX0), max(lx, DX0) + 1) if lx < 40 else range(DX1, lx + 1):
            cv.px(x, TOP + 4, "lilac_grey")    # braço que liga o poste ao deck
    return cv


def lights(cv: Canvas, stripe_on: set, lamp_on: bool, dim: bool = False) -> Canvas:
    for i, x in enumerate(STRIPE_LIGHTS):
        if dim:
            c = "deep_teal"
        else:
            c = "ice" if i in stripe_on else "teal"
        cv.px(x, TOP + 3, c)
        cv.px(x + 1, TOP + 3, c if c != "ice" else "aqua")
    for lx in LAMPS:
        cx = lx + (0 if lx < 40 else 0)
        if lamp_on:
            cv.px(cx, TOP - 8, "white")
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                cv.px(cx + dx, TOP - 8 + dy, "aqua")
            for dx, dy in ((2, 0), (-2, 0), (0, -2)):
                cv.px(cx + dx, TOP - 8 + dy, "teal")
        else:
            cv.px(cx, TOP - 8, "deep_teal" if dim else "teal")
            cv.px(cx, TOP - 7, "navy" if dim else "deep_teal")
    return cv


def pad_frames():
    idle = lights(structure(), set(), False, dim=True)
    n = len(STRIPE_LIGHTS)
    # luzes correm das pontas para o centro; lâmpadas acesas só no começo do ciclo (~25%)
    target = []
    for f in range(6):
        on = {f, n - 1 - f} if f < (n + 1) // 2 else set()
        target.append(lights(structure(), on, lamp_on=f in (0, 1)))
    return idle, target


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


if __name__ == "__main__":
    idle, target = pad_frames()
    print("idle", len(idle.colors_used()), idle.lint(max_colors=16))
    print("target", len(target[0].colors_used()), target[0].lint(max_colors=16))
    pad_anims = [Animation("idle").add(idle, 500), Animation("target")]
    for i, fr in enumerate(target):
        pad_anims[1].add(fr, [160, 140, 120, 120, 140, 260][i])
    marker = Animation("bob")
    for fr, ms in zip(marker_frames(), (220, 160, 220, 160)):
        marker.add(fr, ms)
    if "--export" in sys.argv:
        save_animations(pad_anims, "assets/sprites/landing_pad.png", res_path="res://assets/sprites/landing_pad.png",
                        tres_path="assets/sprites/landing_pad_frames.tres", preview_dir="art/previews")
        save_animations([marker], "assets/sprites/target_marker.png", res_path="res://assets/sprites/target_marker.png",
                        tres_path="assets/sprites/target_marker_frames.tres", preview_dir="art/previews")
    else:
        save_animations(pad_anims, "art/previews/landing_pad_wip.png", preview_dir="art/previews")
        save_animations([marker], "art/previews/target_marker_wip.png", preview_dir="art/previews")
        # prévia no estilo: plataforma (alvo) e a nave sobre a cena da Lua aprovada, recomposta das camadas
        sys.path.insert(0, "art/src/bg"); sys.path.insert(0, "art/src/terrain")
        import moon_scene as ms
        from moon import profile, ridge_y
        comp = ms.ingame_preview(ms.load_layers(), with_lander=False)
        pts = profile(640, seed=7, base=292, amp=60, pad=ms.PREVIEW_PAD)
        px0, pw = ms.PREVIEW_PAD
        y = ridge_y(pts, px0 + pw // 2)
        comp.stamp(target[0], px0 - DX0, y - TOP)
        lander = Canvas.from_image("assets/sprites/lander.png").crop(0, 0, 32, 32)
        comp.stamp(lander, px0 + pw // 2 - 16, y - 25)
        comp.stamp(marker_frames()[0], px0 + pw // 2 - 5, y - 58)
        comp.save("art/previews/landing_pad_scene.png", preview=False)
        comp.crop(230, 240, 200, 120).preview("art/previews/landing_pad_scene_zoom.png", scale=4, grid=False, show_1x=False)
