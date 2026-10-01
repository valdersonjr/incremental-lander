"""Kit de interface (pixel-art): fonte, painéis 9-slice, botões (4 estados + principal), barras e ícones 12x12.

Estilo: o mesmo da nave e da plataforma (futurista: escuro + borda turquesa, brilho ciano, cantos chanfrados),
luz de cima-esquerda, só Resurrect 64. Padrão: patterns/ui-kit.md.
Contrato com o Godot (godot-dev monta o Theme): ver EXPORT no fim (tamanhos e margens 9-slice no ui_kit.json).
Rodar da raiz: python3 art/src/ui/ui_kit.py [--export]
"""
import json
import math
import sys

sys.path.insert(0, ".claude/skills/pixel-art/scripts")
sys.path.insert(0, "art/src/ui")
from pixelart import *
import pixel_font as pf

PANEL = 26              # 9-slice: margens 8, miolo 10 (grade de 5 px repete sem costura)
PM = 8
BTN_W, BTN_H = 20, 16   # margens 6 (lados) / 5 (cima-baixo)
BAR_W, BAR_H = 12, 8    # margens 3
ICON = 12

# Cor de destaque por mundo (decisão do usuário: "tem que mudar de acordo com o mapa"). O kit é desenhado na rampa
# turquesa (Lua) e cada mundo troca tom por tom: low < deep < mid < base < bright < hi. Fixos em todos: fundo escuro,
# dourado (dinheiro), vermelho (perigo), âmbar (gás acabando) e os ícones.
BASE_RAMP = {"low": "navy", "deep": "deep_teal", "mid": "teal", "base": "sea", "bright": "aqua", "hi": "ice"}
WORLDS = {
    "luna":   BASE_RAMP,
    "ares":   {"low": "deep_sage", "deep": "pine", "mid": "green", "base": "emerald", "bright": "leaf", "hi": "sprout"},
    "kronos": {"low": "plum_dark", "deep": "magenta_dark", "mid": "raspberry", "base": "hot_pink", "bright": "pink",
               "hi": "peach"},
    "titan":  {"low": "umber", "deep": "rust", "mid": "terracotta", "base": "copper", "bright": "honey", "hi": "cream"},
}


def themed(cv: Canvas, world: str) -> Canvas:
    """Troca a rampa turquesa pela do mundo, pixel a pixel (sem trocas em cadeia)."""
    if world == "luna":
        return cv
    remap = {resolve(BASE_RAMP[k]): resolve(v) for k, v in WORLDS[world].items()}
    out = cv.copy()
    for y in range(out.h):
        for x in range(out.w):
            c = out.px_data[y][x]
            if c in remap:
                out.px_data[y][x] = remap[c]
    return out


# ------------------------------------------------------------------ painel
def panel(w: int, h: int, header: int = 0) -> Canvas:
    """Painel escuro com grade sutil de HUD, borda turquesa (luz de cima-esquerda), cantos chanfrados com detalhe ciano.
    header > 0: faixa de título no topo com essa altura."""
    cv = Canvas(w, h)
    ch = 3                                                     # chanfro
    def inside(x, y):
        if not (0 <= x < w and 0 <= y < h):
            return False
        return not (x + y < ch or (w - 1 - x) + y < ch or x + (h - 1 - y) < ch or (w - 1 - x) + (h - 1 - y) < ch)
    for y in range(h):
        for x in range(w):
            if not inside(x, y):
                continue
            c = "shadow" if (x % 5 == 2 and y % 5 == 2) else "ink"
            cv.px(x, y, c)
    # contorno: externo escuro; filete turquesa (claro em cima/esquerda, escuro embaixo/direita)
    for y in range(h):
        for x in range(w):
            if not inside(x, y):
                continue
            edge = not (inside(x - 1, y) and inside(x + 1, y) and inside(x, y - 1) and inside(x, y + 1))
            if edge:
                lit = (y <= 3 or x <= 3) and not (y >= h - 4 or x >= w - 4)
                cv.px(x, y, "sea" if lit else "teal")
            elif not (inside(x - 2, y) and inside(x + 2, y) and inside(x, y - 2) and inside(x, y + 2)):
                cv.px(x, y, "deep_teal" if not (y >= h - 3 or x >= w - 3) else "navy")
    # detalhes ciano nos cantos de cima (colchetes de HUD)
    for (sx, d) in ((ch + 1, 1), (w - ch - 2, -1)):
        for k in range(3):
            cv.px(sx + d * k, 2, "aqua")
        cv.px(sx - d, 3, "aqua") if 0 else None
    cv.px(2, ch + 1, "aqua"); cv.px(2, ch + 2, "aqua")
    cv.px(w - 3, ch + 1, "aqua"); cv.px(w - 3, ch + 2, "aqua")
    if header:
        for y in range(3, header):
            for x in range(3, w - 3):
                if inside(x, y):
                    c = "deep_teal" if y > 3 else "sea"
                    if y == header - 1:
                        c = "teal"
                    cv.px(x, y, c)
    return cv


# ------------------------------------------------------------------ botões
BTN_STYLES = {
    "normal":   {"fill": "deep_teal", "hi": "teal", "top": "sea", "low": "navy"},
    "hover":    {"fill": "teal", "hi": "sea", "top": "aqua", "low": "deep_teal"},
    "pressed":  {"fill": "navy", "hi": "navy", "top": "ink", "low": "deep_teal"},
    "disabled": {"fill": "shadow", "hi": "slate", "top": "slate", "low": "ink"},
    "primary":  {"fill": "sea", "hi": "aqua", "top": "ice", "low": "teal"},
    "primary_hover": {"fill": "aqua", "hi": "ice", "top": "white", "low": "sea"},
}


def button(w: int, h: int, style: str) -> Canvas:
    s = BTN_STYLES[style]
    cv = Canvas(w, h)
    for y in range(h):
        for x in range(w):
            corner = (x in (0, w - 1)) and (y in (0, h - 1))
            if corner:
                continue
            if x in (0, w - 1) or y in (0, h - 1):
                c = "ink"
            elif y == 1:
                c = s["top"] if 1 < x < w - 2 else s["hi"]
            elif y == h - 2:
                c = s["low"]
            elif x == 1:
                c = s["hi"]
            elif x == w - 2:
                c = s["low"]
            else:
                c = s["fill"]
            cv.px(x, y, c)
    if style not in ("pressed", "disabled"):
        cv.px(2, 2, s["top"])                                   # brilho no canto da luz
    return cv


# ------------------------------------------------------------------ barras
BAR_RAMPS = {"bg": None, "fill": ("ice", "aqua", "sea", "teal"), "warn": ("lemon", "gold", "amber", "orange"),
             "danger": ("peach", "coral", "red", "crimson"), "xp": ("lavender", "violet", "purple", "plum")}


def bar(w: int, h: int, kind: str) -> Canvas:
    cv = Canvas(w, h)
    for y in range(h):
        for x in range(w):
            if (x in (0, w - 1)) and (y in (0, h - 1)):
                continue
            if x in (0, w - 1) or y in (0, h - 1):
                c = "ink"
            elif kind == "bg":
                c = "shadow" if y == 1 else "ink" if y == h - 2 else "navy"
            else:
                top, hi, mid, low = BAR_RAMPS[kind]
                c = top if y == 1 else hi if y == 2 else low if y == h - 2 else mid
            cv.px(x, y, c)
    return cv


# ------------------------------------------------------------------ ícones 12x12
def _circle(cv, cx, cy, r, fill, rim, hi, hi2=None):
    for y in range(ICON):
        for x in range(ICON):
            d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
            if d <= r:
                lit = (x - cx) * -0.6 + (y - cy) * -0.8
                c = fill
                if d > r - 1.1:
                    c = rim if lit < 0.5 else hi
                cv.px(x, y, c)
    if hi2:
        cv.px(int(cx - r * 0.45), int(cy - r * 0.5), hi2)


def icon(name: str) -> Canvas:
    cv = Canvas(ICON, ICON)
    P = lambda rows, legend: cv.paint(rows, legend, x=0, y=0)
    if name == "credits":
        _circle(cv, 6, 6, 5.5, "gold", "rust", "lemon", "white")
        P(["............", "............", "............", "....mmm.....", "...m........", "...m........",
           "...m........", "....mmm.....", "............"], {"m": "amber"})
    elif name == "ore":
        P(["......a.....", ".....aab....", "....aabbc...", "...aabbbc...", "..aaabbcc.d.", "..aabbbcc.dd",
           "...abbbc..dc", "....abc...cc", ".....c......", "............", "............", "............"],
          {"a": "honey", "b": "copper", "c": "terracotta", "d": "rust"})
    elif name == "stardust":
        P([".....a......", ".....b......", ".....b......", "....aba.....", "abbbbwbbbba.", "....aba.....",
           ".....b......", ".....b...a..", ".....a..aba.", ".........a..", "............", "............"],
          {"a": "violet", "b": "lavender", "w": "white"})
    elif name == "gas":
        P([".....a......", ".....a......", "....aba.....", "....abb.....", "...abbbc....", "...abwbbc...",
           "..abwbbbc...", "..abbbbbc...", "..abbbbcc...", "...abbcc....", "....ccc.....", "............"],
          {"a": "teal", "b": "aqua", "c": "sea", "w": "ice"})
    elif name == "thrust":
        P(["....mmm.....", "...mwwwm....", "...mwwws....", "...mwsss....", "..mmmmmmm...", "...abbba....",
           "...bcccb....", "....cdc.....", "....ddd.....", ".....d......", "............", "............"],
          {"m": "mist", "w": "white", "s": "steel", "a": "lemon", "b": "gold", "c": "orange", "d": "brick"})
    elif name == "tank":
        P(["....aaa.....", "...abbbc....", "..awwbbbc...", "..awbbbbc...", "..sssssss...", "..awbbbbc...",
           "..awbbbbc...", "..awbbbbc...", "..sssssss...", "..abbbbbc...", "...cccc.....", "............"],
          {"a": "mist", "b": "steel", "c": "lilac_grey", "w": "white", "s": "sea"})
    elif name == "efficiency":
        P(["...aaaaa....", "...abbbc....", "....abc.....", "...abbbc....", "..abbbbbc...", "..ccccccc...",
           "...ieeei....", "....eie.....", "....iei.....", ".....i......", "............", "............"],
          {"a": "mist", "b": "steel", "c": "slate", "e": "aqua", "i": "ice"})
    elif name == "reputation":
        P([".....a......", ".....a......", "....aba.....", "aaaabbbaaa..", ".abbbwbbba..", "..abbbbba...",
           "..abbcbba...", ".abbc.cbba..", ".bcc...ccb..", "............", "............", "............"],
          {"a": "lemon", "b": "gold", "c": "amber", "w": "white"})
    elif name == "gear":
        P(["....aaaa....", "...abbbbc...", "...bbbbbc...", "....a.c.....", "...a...c....", "..a.....c...",
           ".a.......c..", "a.........c.", "ab.......bc.", "sss.....sss.", "............", "............"],
          {"a": "mist", "b": "steel", "c": "lilac_grey", "s": "slate"})
    elif name == "refinery":
        P(["....aaa.....", "....aba.....", "....aba.....", "...ab.bc....", "..ab...bc...", ".ab.....bc..",
           ".bmmmmmmmc..", ".bmhhmmmmc..", ".bmmmmmmrc..", "..ccccccc...", "............", "............"],
          {"a": "pale_sky", "b": "sky", "c": "blue", "m": "copper", "h": "honey", "r": "rust"})
    elif name == "fleet":
        P(["aaa.....aaa.", ".s.......s..", ".s.mmmmm.s..", ".ssmwwwmss..", "...mweeem...", "...mmmmmm...",
           "....c..c....", "............", "............", "............", "............", "............"],
          {"a": "lilac_grey", "s": "steel", "m": "mist", "w": "white", "e": "aqua", "c": "slate"})
    elif name == "autopilot":
        P(["..s.s.s.s...", ".aaaaaaaaa..", "sabbbbbbbcs.", ".abeeeeebc..", "sabeiieebcs.", ".abeiieebc..",
           "sabeeeeebcs.", ".abbbbbbbc..", ".ccccccccc..", "..s.s.s.s...", "............", "............"],
          {"s": "steel", "a": "teal", "b": "deep_teal", "c": "navy", "e": "sea", "i": "aqua"})
    elif name == "planet":
        _circle(cv, 6, 6, 5, "blue", "navy", "sky", "pale_sky")
        for x in range(0, 12):
            y = round(6 + (x - 6) * 0.35)
            if not (4 <= x <= 8):
                cv.px(x, y, "lichen")
    elif name == "prestige":
        P(["..a.....a...", ".aba...aba..", "abbba.abbba.", ".abbbabbba..", "..abbbbba...", "...abbba....",
           "..a.aba.a...", ".aba.a.aba..", "abbba.abbba.", ".abbbbbba...", "..aaaaaa....", "............"],
          {"a": "violet", "b": "lavender"})
    elif name == "expedition":
        P(["ab..........", "abrrrrrr....", "abrwwrrrr...", "abrrrrrrc...", "abrrrrcc....", "ab..........",
           "ab..........", "ab..........", "ab..........", "ssss........", "............", "............"],
          {"a": "mist", "b": "steel", "r": "red", "w": "coral", "c": "crimson", "s": "slate"})
    elif name == "options":
        P(["....a.b.....", "..aaabbbc...", "..abbbbbc...", "aabbcccbbcc.", ".abbc.cbbc..", ".abbc.cbbc..",
           "aabbcccbbcc.", "..abbbbbc...", "..bccccccc..", "....b.c.....", "............", "............"],
          {"a": "mist", "b": "steel", "c": "lilac_grey"})
    elif name == "distance":
        P(["............", "......a.....", "......ab....", "aaaaaaabb...", "abbbbbbbbb..", "accccccbb...",
           "......cb....", "......c.....", "............", "............", "............", "............"],
          {"a": "ice", "b": "aqua", "c": "sea"})
    elif name == "quality":
        P(["...aaaaa....", "..a.....a...", ".a..bbb..a..", ".a.b...b.a..", ".a.b.w.b.a..", ".a.b...b.a..",
           ".a..bbb..a..", "..a.....a...", "...aaaaa....", "............", "............", "............"],
          {"a": "leaf", "b": "sprout", "w": "white"})
    return cv


ICONS = ["credits", "ore", "stardust", "gas", "thrust", "tank", "efficiency", "reputation", "gear", "refinery",
         "fleet", "autopilot", "planet", "prestige", "expedition", "options", "distance", "quality"]


# ------------------------------------------------------------------ amostra (prévia do estilo no jogo)
def world_scene(world: str) -> Canvas:
    sys.path.insert(0, "art/src/bg"); sys.path.insert(0, "art/src/terrain"); sys.path.insert(0, "art/src/fx")
    import moon_scene as ms
    if world == "luna":
        return ms.ingame_preview(ms.load_layers(), with_lander=True)
    mod = __import__({"ares": "forest_scene", "kronos": "candy_scene", "titan": "room_scene"}[world])
    return mod.compose(mod.layers())


def sample(world: str = "luna") -> Canvas:
    cv = world_scene(world)
    T = lambda c: themed(c, world)
    acc = WORLDS[world]
    ink_shadow = "ink"
    # HUD de voo (canto superior esquerdo)
    hud = T(panel(150, 74))
    cv.stamp(hud, 6, 6)
    cv.stamp(icon("gas"), 14, 14)
    pf.draw_text(cv, 30, 14, "GÁS", "mist")
    cv.stamp(bar(70, 8, "bg"), 58, 16)
    cv.stamp(bar(52, 8, "fill"), 58, 16)                       # gás: sempre ciano (cor do combustível)
    pf.draw_text(cv, 132, 14, "74", "white")
    for i, (lab, val, col) in enumerate((("V.VERT", "-1.2 m/s", "leaf"), ("V.HOR", "3.4 m/s", "gold"),
                                         ("ALT", "126 m", "mist"))):
        pf.draw_text(cv, 14, 28 + i * 12, lab, "steel")
        pf.draw_text(cv, 62, 28 + i * 12, val, col)
    # créditos + entrega (canto superior direito)
    top = T(panel(120, 26))
    cv.stamp(top, 514, 6)
    cv.stamp(icon("credits"), 522, 13)
    pf.draw_text(cv, 538, 13, "1.43K", "gold")
    pf.draw_text(cv, 576, 13, "2/6", "mist")
    # painel de ofertas
    off = T(panel(212, 128, header=15))
    ox, oy = 214, 40
    cv.stamp(off, ox, oy)
    pf.draw_text(cv, ox + 8, oy + 3, "ENTREGAS", "white", shadow="ink")
    pf.draw_text(cv, ox + 150, oy + 3, "[E] sair", acc["hi"])
    rows = [("1", "127 m", "12", "+22", True), ("2", "868 m", "32", "+187", True), ("3", "2.88K m", "58", "+698", True),
            ("4", "5.52K m", "81", "+1.43K", True), ("5", "9.11K m", "104", "+2.48K", False)]
    for i, (k, d, g, p, ok) in enumerate(rows):
        y = oy + 20 + i * 16
        b = T(button(14, 13, "hover" if i == 1 else "normal" if ok else "disabled"))
        cv.stamp(b, ox + 8, y)
        pf.draw_text(cv, ox + 12, y + 1, k, "white" if ok else "slate")
        col = "mist" if ok else "red"
        cv.stamp(icon("distance"), ox + 26, y + 1)
        pf.draw_text(cv, ox + 40, y + 1, d, col)
        cv.stamp(icon("gas"), ox + 92, y + 1)
        pf.draw_text(cv, ox + 106, y + 1, g, col)
        cv.stamp(icon("credits"), ox + 136, y + 1)
        pf.draw_text(cv, ox + 150, y + 1, p, "gold" if ok else "red")
    pf.draw_text(cv, ox + 8, oy + 106, "1-5 ou clique, depois W decola", "steel")
    # botão principal
    cv.stamp(T(button(96, 18, "primary")), 272, 300)
    pf.draw_text(cv, 272 + 48 - pf.text_width("DECOLAR") // 2, 303, "DECOLAR", "ink")
    return cv


def kit_sheet() -> Canvas:
    sheet = Canvas(300, 130, "navy")
    sheet.stamp(panel(PANEL, PANEL), 4, 4)
    sheet.stamp(panel(PANEL, PANEL, header=12), 34, 4)
    for i, st in enumerate(BTN_STYLES):
        sheet.stamp(button(BTN_W, BTN_H, st), 64 + i * 24, 4)
    for i, k in enumerate(BAR_RAMPS):
        sheet.stamp(bar(BAR_W, BAR_H, k), 64 + i * 16, 26)
    for i, n in enumerate(ICONS):
        sheet.stamp(icon(n), 4 + (i % 9) * 16, 40 + (i // 9) * 16)
    pf.draw_text(sheet, 4, 76, "Silvânia · Docelândia · Expedição", "mist")
    pf.draw_text(sheet, 4, 90, "HANGAR  5.00K cr  [COMPRAR]  MAX", "aqua")
    pf.draw_text(sheet, 4, 106, "TITULO", "white", scale=2)
    return sheet


def export() -> None:
    import os
    pf.export("assets/ui/font.png", "assets/ui/font.fnt")
    bar(BAR_W, BAR_H, "fill").save("assets/ui/bar_gas.png", preview=False)   # gás: sempre ciano
    for k in ("bg", "warn", "danger", "xp"):                    # fixos (significado)
        bar(BAR_W, BAR_H, k).save(f"assets/ui/bar_{k}.png", preview=False)
    for world in WORLDS:                                        # destaque por mundo
        d = f"assets/ui/{world}"
        os.makedirs(d, exist_ok=True)
        themed(panel(PANEL, PANEL), world).save(f"{d}/panel.png", preview=False)
        themed(panel(PANEL, PANEL, header=12), world).save(f"{d}/panel_header.png", preview=False)
        for st in BTN_STYLES:
            themed(button(BTN_W, BTN_H, st), world).save(f"{d}/button_{st}.png", preview=False)
        themed(bar(BAR_W, BAR_H, "fill"), world).save(f"{d}/bar_fill.png", preview=False)
    atlas = Canvas(ICON * len(ICONS), ICON)
    for i, n in enumerate(ICONS):
        atlas.stamp(icon(n), i * ICON, 0)
    atlas.save("assets/ui/icons.png", preview=False)
    meta = {"panel": {"size": PANEL, "margin": PM}, "panel_header": {"size": PANEL, "margin": PM, "header": 12},
            "button": {"size": [BTN_W, BTN_H], "margin": [6, 5], "styles": list(BTN_STYLES)},
            "bar": {"size": [BAR_W, BAR_H], "margin": 3, "kinds": list(BAR_RAMPS)},
            "icons": {"size": ICON, "names": ICONS}, "font": {"file": "font.fnt", "size": pf.ROWS},
            "worlds": {w: {"accent": r["bright"], "title": r["hi"], "text_accent": r["base"]} for w, r in WORLDS.items()},
            "world_files": ["panel.png", "panel_header.png", "bar_fill.png"] + [f"button_{s}.png" for s in BTN_STYLES]}
    with open("assets/ui/ui_kit.json", "w") as f:
        json.dump(meta, f, indent=2)


# caminhos literais dos assets (o pre-commit procura a fonte de cada PNG pelo caminho escrito no script):
# assets/ui/font.png assets/ui/icons.png assets/ui/bar_gas.png assets/ui/bar_bg.png assets/ui/bar_warn.png assets/ui/bar_danger.png
# assets/ui/bar_xp.png
# assets/ui/luna/panel.png assets/ui/luna/panel_header.png assets/ui/luna/bar_fill.png
# assets/ui/luna/button_normal.png assets/ui/luna/button_hover.png assets/ui/luna/button_pressed.png assets/ui/luna/button_disabled.png assets/ui/luna/button_primary.png assets/ui/luna/button_primary_hover.png
# assets/ui/ares/panel.png assets/ui/ares/panel_header.png assets/ui/ares/bar_fill.png
# assets/ui/ares/button_normal.png assets/ui/ares/button_hover.png assets/ui/ares/button_pressed.png assets/ui/ares/button_disabled.png assets/ui/ares/button_primary.png assets/ui/ares/button_primary_hover.png
# assets/ui/kronos/panel.png assets/ui/kronos/panel_header.png assets/ui/kronos/bar_fill.png
# assets/ui/kronos/button_normal.png assets/ui/kronos/button_hover.png assets/ui/kronos/button_pressed.png assets/ui/kronos/button_disabled.png assets/ui/kronos/button_primary.png assets/ui/kronos/button_primary_hover.png
# assets/ui/titan/panel.png assets/ui/titan/panel_header.png assets/ui/titan/bar_fill.png
# assets/ui/titan/button_normal.png assets/ui/titan/button_hover.png assets/ui/titan/button_pressed.png assets/ui/titan/button_disabled.png assets/ui/titan/button_primary.png assets/ui/titan/button_primary_hover.png

if __name__ == "__main__":
    kit_sheet().preview("art/previews/ui_kit_sheet.png", scale=3, grid=False, show_1x=False)
    from PIL import Image
    shots = []
    for world in WORLDS:
        s = sample(world)
        s.save(f"art/previews/ui_sample_{world}.png", preview=False)
        shots.append(Image.open(f"art/previews/ui_sample_{world}.png").convert("RGB"))
    sheet = Image.new("RGB", (640 * 2, 360 * 2))
    for i, im in enumerate(shots):
        sheet.paste(im, ((i % 2) * 640, (i // 2) * 360))
    sheet.save("art/previews/ui_worlds.png")
    if "--export" in sys.argv:
        import os
        os.makedirs("assets/ui", exist_ok=True)
        export()
