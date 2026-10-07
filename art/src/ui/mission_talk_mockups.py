"""Maquete da JANELA DE CONVERSA do pedido (2026-10-07, skill pixel-art) para o usuário aprovar antes do jogo.

Usuário: "melhorar a cena de aceite de missão onde estaria o gatinho laranja astronauta conversando com o ratinho e
não apenas uma nave parada numa plataforma" → escolheu a "janela de conversa"; roteiro igual para todos os ratinhos
(chegada → pedido → regra com certo × errado → escolha → aceite; gás pouco = o gatinho avisa).
Desenhada em 1x (640x360) com as peças reais (painel, botões, balão, fonte, atlas kids, cargas, gatinho herói,
ratinhos de corpo inteiro) por cima de uma captura do jogo escurecida; a fila de ratinhos fica acesa no alto.

Fundo: art/previews/mission_talk/map_clean.png (gdtool capture flight_ui_preview -- --no_title --no_offers) e
map_offers.png (-- --no_title --missions --select=soft).
Rodar da raiz:  python3 art/src/ui/mission_talk_mockups.py  -> art/previews/mission_talk/*.png + index.html
"""
import os
import sys

sys.path.insert(0, "art/src/ui")
sys.path.insert(0, "art/src/sprites")
from PIL import Image, ImageOps
import offer_card_mockups as oc
from offer_card_mockups import rgb, kid, cargo, nine, button, text, text_w, frame, star_strip, UI
import cat_hero
import mouse_hero

OUT = "art/previews/mission_talk"
WIN = (110, 88, 420, 252)                    # janela (x, y, w, h) em 1x
STAGE_H = 112                                # palco (mapa aceso atrás dos dois)
CAT_K, MOUSE_K = 1.15, 1.25


def canvas_img(c) -> Image.Image:
    return c.to_image().convert("RGBA")


def balloon(w: int, h: int, tail: str = "left") -> tuple[Image.Image, int]:
    """Balão 9-slice do tema + rabinho (esquerda = aponta para quem está à esquerda). Devolve (img, dx do balão)."""
    b = nine("assets/ui/balloon.png", w, h, 5, 5)
    t = Image.open("assets/ui/balloon_tail.png").convert("RGBA")
    out = Image.new("RGBA", (w + 5, h))
    if tail == "left":
        out.alpha_composite(b, (5, 0)); out.alpha_composite(t, (0, h // 2 - 4))
        return out, 5
    out.alpha_composite(b, (0, 0)); out.alpha_composite(ImageOps.mirror(t), (w - 1, h // 2 - 4))
    return out, 0


def say(img: Image.Image, x: int, y: int, lines: list, tail: str) -> None:
    w = max(text_w(s) for s in lines) + 12
    h = 12 * len(lines) + 6
    b, dx = balloon(w, h, tail)
    img.alpha_composite(b, (x - (b.width if tail == "right" else 0), y))
    bx = x - (b.width if tail == "right" else 0) + dx
    for i, s in enumerate(lines):
        text(img, bx + 6, y + 4 + 12 * i, s, "ink", shadow=False)


def base() -> Image.Image:
    """Captura do jogo escurecida (só a fila de ratinhos fica acesa)."""
    cap = Image.open(f"{OUT}/map_offers.png").convert("RGBA").resize((640, 360), Image.NEAREST)
    clean = Image.open(f"{OUT}/map_clean.png").convert("RGBA").resize((640, 360), Image.NEAREST)
    dark = Image.blend(cap, Image.new("RGBA", cap.size, rgb("ink")), 0.55)
    return dark, clean


ROW = [("simple", "+36"), ("heavy", "+68"), ("soft", "+225"), ("fast", "+796"), ("passenger", "+1.27K"),
       ("tow", "+3.46K")]


def chip_row(img: Image.Image, sel: str) -> None:
    """Fila nova: UM rostinho por tipo de ratinho (a distância virou escolha dentro da janela)."""
    w = len(ROW) * 37 + 10
    x0 = 320 - w // 2
    clean = Image.open(f"{OUT}/map_clean.png").convert("RGBA").resize((640, 360), Image.NEAREST)
    old = Image.blend(clean, Image.new("RGBA", clean.size, rgb("ink")), 0.55).crop((160, 30, 480, 92))
    img.alpha_composite(old, (160, 30))                                                   # some a fila antiga
    img.alpha_composite(nine(UI + "panel.png", w, 50, 8, 8), (x0, 34))
    for i, (kind, pay) in enumerate(ROW):
        cx = x0 + 5 + i * 37
        img.alpha_composite(kid("pin_sel" if kind == sel else "pin"), (cx + 6, 38))
        img.alpha_composite(kid("rat_" + kind), (cx + 6, 38))
        text(img, cx + 18 - text_w(pay) // 2, 68, pay, "gold")


def window(o: dict, state: str) -> Image.Image:
    if state == "gas" and o.get("dist"):                                                  # gás pouco = marcou o longe
        o = dict(o, d=list(o["dist"])[-1], total="+5.10K")
    img, cap = base()
    chip_row(img, o["kind"])
    x, y, w, h = WIN
    img.alpha_composite(nine(UI + "panel.png", w, h, 8, 8), (x, y))
    sx, sy, sw = x + 6, y + 6, w - 12
    st = cap.crop((640 - sw + 28, 108, 640, 108 + STAGE_H))                               # palco: o mapa aceso
    img.alpha_composite(st.crop((60, 0, 88, STAGE_H)), (sx, sy))      # borda esquerda: trecho limpo (sem o poste da mina)
    img.alpha_composite(st, (sx + 28, sy))
    for i in range(sw):                                                                   # chão do palco (queijo)
        for j in range(8):
            img.putpixel((sx + i, sy + STAGE_H - 8 + j), rgb("gold" if j == 0 else "amber" if j < 3 else "copper"))
    # gatinho (esquerda, olhando para a direita) e ratinho (direita, olhando para a esquerda)
    cat_pose = {"accept": "wave1"}.get(state, "rest")
    cat = canvas_img(cat_hero.Cat(CAT_K).body(cat_pose))
    img.alpha_composite(cat, (sx + 22, sy + STAGE_H - 6 - cat.height))
    mpose = {"accept": "happy"}.get(state, "talk")
    m = mouse_hero.Mouse(o["kind"], MOUSE_K)
    mi = canvas_img(m.draw(mpose, wag=3 if mpose == "happy" else 0, hop=4 if mpose == "happy" else 0))
    mx = sx + sw - 30 - mi.width
    img.alpha_composite(mi, (mx, sy + STAGE_H - 6 - mi.height))
    # falas: UM balão do ratinho (pedido em cima, regra + certo × errado embaixo)
    if state == "accept":
        say(img, sx + 22 + cat.width - 6, sy + 14, ["Deixa comigo!"], "left")
        say(img, mx + 6, sy + 10, ["Obaaa!"], "right")
    else:
        ask = " ".join(o["ask"])
        pics = o["pics"]
        rule_w = text_w(o["rule"]) + 4 + 28 * len(pics)
        bw = max(text_w(ask), rule_w) + 14
        b, dx = balloon(bw, 40, "right")
        bx, by = mx + 4 - b.width, sy + 40
        img.alpha_composite(b, (bx, by))
        text(img, bx + 7, by + 5, ask, "ink", shadow=False)
        for i in range(bw - 14):                                                          # risquinho separando
            if i % 2 == 0:
                img.putpixel((bx + 7 + i, by + 18), rgb("peach"))
        text(img, bx + 7, by + 25, o["rule"], "wine", shadow=False)
        px = bx + 7 + text_w(o["rule"]) + 4
        for pic, ok in pics:
            img.alpha_composite(cargo(pic), (px, by + 20))
            img.alpha_composite(kid("check" if ok else "cross").crop((4, 6, 20, 22)).resize((10, 10)), (px + 13, by + 27))
            px += 28
        if state == "gas":
            say(img, sx + 22 + cat.width - 6, sy + 4, ["Hmm... acho que a gasolina não dá!"], "left")
    # escolhas em COLUNAS: título em cima, 3 opções empilhadas; clicar só marca (partir = Aceitar missão)
    names = {"normal": "normal", "narrow": "estreita", "tight": "apertada"}
    cols = []
    if len(o.get("dist", {})) > 1:
        cols.append(("Distância", [(d, d == o["d"], ok) for d, (_, ok) in o["dist"].items()]))
    cols.append(("Tamanho da plataforma", [(names[t], t == o["tier"], True) for t in oc.TIERS]))
    if o["stars"]:
        cols.append(("Dificuldade", [(st, st == o["star"], True) for st in o["stars"]]))
    gap, cw = 10, 124
    tot = len(cols) * cw + (len(cols) - 1) * gap
    cx0 = sx + sw // 2 - tot // 2
    top = sy + STAGE_H + 6
    for c, (title, opts) in enumerate(cols):
        cx = cx0 + c * (cw + gap)
        text(img, cx + cw // 2 - text_w(title) // 2, top, title, "lemon")
        for r, (val, on, ok) in enumerate(opts):
            by = top + 13 + r * 19
            img.alpha_composite(button(cw, 17, "on" if on else "normal"), (cx, by))
            if on:
                frame(img, cx - 1, by - 1, cw + 2, 19)
            if isinstance(val, int):
                st = star_strip(val)
                img.alpha_composite(st, (cx + cw // 2 - st.width // 2 + 2, by + 3))
            else:
                col = ("ink" if on else "white") if ok else ("crimson" if on else "lilac_grey")
                text(img, cx + cw // 2 - text_w(val) // 2, by + 4, val, col, shadow=not on)
    # barra de baixo alinhada às colunas: prêmio à esquerda, Aceitar missão à direita
    by = y + h - 34
    for i in range(sw - 8):
        img.putpixel((sx + 4 + i, by - 5), rgb("purple"))
    total = o["total"]
    coin = kid("coin").crop((6, 9, 18, 21)).resize((24, 24), Image.NEAREST)
    lab = "Você ganha"
    tx = sx + 10
    text(img, tx, by + 9, lab, "white")
    img.alpha_composite(coin, (tx + text_w(lab) + 6, by + 1))
    text(img, tx + text_w(lab) + 34, by + 3, total, "gold", scale=2)
    acc = "ACEITAR MISSÃO"
    bw = text_w(acc) + 28
    bx = sx + sw - 10 - bw
    img.alpha_composite(button(bw, 26, "go"), (bx, by))
    if state == "accept":
        frame(img, bx - 1, by - 1, bw + 2, 28)
    text(img, bx + bw // 2 - text_w(acc) // 2, by + 8, acc, "white")
    return img


SIMPLE = {"kind": "simple", "ask": ["Leva meu queijo", "pra vila?"], "rule": "É só pousar na plataforma.",
          "pics": [("box", True)], "tier": "narrow", "d": "perto", "total": "+54",
          "dist": {"perto": ("+36", True), "médio": ("+379", True), "longe": ("+3.40K", False)}, "pay": {"normal": 36, "narrow": 54, "tight": 79}, "stars": []}
SOFT = {"kind": "soft", "ask": ["Meu bolo", "é fofinho!"], "rule": "Pousa bem devagarinho, senão amassa!",
        "pics": [("cake", True), ("cake_squashed", False)], "tier": "narrow", "star": 2, "d": "médio", "total": "+225",
        "dist": {"perto": ("+92", True), "médio": ("+225", True), "longe": ("+610", True)},
        "pay": {"normal": 150, "narrow": 225, "tight": 330}, "stars": [1, 2, 3]}

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    shots = []
    for tag, o in (("mineiro", SIMPLE), ("confeiteira", SOFT)):
        for state, label in (("ask", "pedido + regra + escolha"), ("gas", "gás pouco: o gatinho avisa"),
                             ("accept", "clicou na plataforma: aceite")):
            im = window(o, state)
            name = f"{tag}_{state}.png"
            im.resize((1280, 720), Image.NEAREST).save(f"{OUT}/{name}")
            shots.append((name, f"{tag.capitalize()} — {label}"))
    cap = Image.open(f"{OUT}/map_offers.png").convert("RGBA").resize((640, 360), Image.NEAREST)
    cap.resize((1280, 720), Image.NEAREST).save(f"{OUT}/atual.png")
    cards = "\n".join(f'<figure><img src="{n}"><figcaption>{c}</figcaption></figure>' for n, c in shots)
    open(f"{OUT}/index.html", "w").write(f"""<!doctype html><meta charset="utf-8"><title>Janela de conversa</title>
<style>body{{background:#2e222f;color:#fff;font:15px system-ui;margin:24px}}img{{width:100%;max-width:1280px;
image-rendering:pixelated;border:2px solid #45293f}}figure{{margin:0 0 28px}}figcaption{{margin:6px 0;color:#fbb954}}
</style><h1>Janela de conversa do pedido — maquete</h1>
<p>Roteiro igual para todos: o ratinho pede (balão) → regra com certo × errado → você escolhe onde pousar
(e a dificuldade, quando houver) → botão Aceitar missão = aceite (gatinho "Deixa comigo!", ratinho comemora).
A fila de ratinhos continua no alto: passar o mouse troca quem está na janela.</p>
{cards}<figure><img src="atual.png"><figcaption>Hoje (para comparar)</figcaption></figure>""")
    print("ok", OUT)
