"""Tela de título APROVADA "Noite de história" (2026-10-09). Skill pixel-art, padrão title-screen.
Usuário escolheu entre 4 estilos no navegador ("Gostei da noite de história") com o tema da ocarina a 68 BPM.
v2 (2026-10-09): lua EM PÉ estilo DreamWorks + mais detalhe ("ficou bom, só o contorno estranho" → sem halo
pontilhado). Desenho em art/src/title/night_v2.py; aqui só exporta em CAMADAS para o jogo
(TitleBackdrop faz o parallax pelo mouse e escolhe o quadro pela batida da música):
  assets/bg/title_night_sky.png     céu noturno (via láctea, nebulosa, planetinha) + banco de nuvens de trás (opaco)
  assets/bg/title_night_moon.png    lua crescente de queijo (camada "back", com a sobra lateral do parallax)
  assets/bg/title_night_clouds.png  nuvenzinhas lilás soltas (deriva lenta, na frente da lua)
  assets/bg/title_night_bank.png    banco de nuvens contínuo na base (camada da frente)
  assets/sprites/title_fisher.png   gatinho pescando + varinha + linha + estrelinha, "idle" 16 quadros
                                    (1 compasso: a linha balança, o gato respira, o rabo mexe)
  assets/sprites/title_star.png     estrela cadente (já existente, title_moon.py) — reaproveitada
  assets/bg/title_layout.json       posições (px na tela 640x360) + estrelas grandes que piscam
Rodar da raiz: python3 art/src/title/title_night.py   (prévia: art/previews/title_night_preview.png)
"""
import json
import os
import sys

sys.path.insert(0, ".claude/skills/pixel-art/scripts")
sys.path.insert(0, "art/src/title")
from pixelart import *
import night_v2 as nv
import title_moon as tm

W, H = nv.W, nv.H
PAD = tm.PAD
FR = 16


def bbox(cv: Canvas) -> tuple:
    pts = cv.opaque()
    xs = [x for x, _ in pts]
    ys = [y for _, y in pts]
    return min(xs), min(ys), max(xs), max(ys)


def fisher_anim() -> tuple:
    """Os 16 quadros do grupo do pescador recortados na mesma caixa (união das caixas de todos os quadros)."""
    full = []
    for fr in range(FR):
        cv = Canvas(W, H)
        nv.draw_fisher(cv, fr)
        full.append(cv)
    boxes = [bbox(c) for c in full]
    x0, y0 = min(b[0] for b in boxes), min(b[1] for b in boxes)
    x1, y1 = max(b[2] for b in boxes), max(b[3] for b in boxes)
    a = Animation("idle")
    for c in full:
        a.add(c.crop(x0, y0, x1 - x0 + 1, y1 - y0 + 1), 160)
    return a, (x0, y0)


def transparent_padded(c: Canvas) -> Canvas:
    o = Canvas(c.w + 2 * PAD, c.h)
    o.stamp(c, PAD, 0)
    return o


def export() -> dict:
    sky, moon, back_bank, bank, clouds = nv.static()
    sky = sky.copy()
    sky.stamp(back_bank)                                        # o banco de trás não tem parallax: vai junto do céu
    sky.save("assets/bg/title_night_sky.png", preview=False)
    transparent_padded(moon).save("assets/bg/title_night_moon.png", preview=False)
    clouds.save("assets/bg/title_night_clouds.png", preview=False)
    tm.padded(bank).save("assets/bg/title_night_bank.png", preview=False)
    fisher, pos = fisher_anim()
    save_animations([fisher], "assets/sprites/title_fisher.png", res_path="res://assets/sprites/title_fisher.png",
                    tres_path="assets/sprites/title_fisher_frames.tres", preview_dir="art/previews")
    layout = {
        "notes": "Gerado por art/src/title/title_night.py (pixel-art). Posições = canto de cima-esquerdo, px na tela "
                 "640x360. Camadas: sky (fixa), back (lua + pescador), front (nuvens soltas + banco). O quadro de cada "
                 "animação sai da batida da música (TitleBackdrop).",
        "fisher": list(pos),
        "clouds_y": 0,
        "star": [250, 18],
        "twinkle": [list(p) for p in nv.TWINKLE],
        "layer_pad": PAD,
        "cloud_drift_px": 2,
        "parallax_px": {"back": 3, "front": 6},
    }
    with open("assets/bg/title_layout.json", "w") as f:
        json.dump(layout, f, indent=2)
    return layout


def preview(layout: dict) -> None:
    sky, moon, back_bank, bank, clouds = nv.static()
    cv = sky.copy()
    cv.stamp(back_bank)
    cv.stamp(moon)
    cv.stamp(fisher_anim()[0].frames[0], *layout["fisher"])
    cv.stamp(bank)
    cv.stamp(clouds, 0, layout["clouds_y"])
    cv.stamp(nv.tc.lg.logo(), 22, 18)
    cv.preview("art/previews/title_night_preview.png", scale=2, grid=False)


if __name__ == "__main__":
    lay = export()
    preview(lay)
    print(json.dumps({k: v for k, v in lay.items() if k not in ("twinkle", "notes")}))
