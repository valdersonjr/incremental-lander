"""Botão de perigo (ação destrutiva: recomeçar o jogo, apagar progresso) = botão comum recolorido em vinho.

Auditoria de UX 2026-10-08: o "Novo jogo" do menu tinha só o texto vermelho e parecia um botão comum.
Mesma técnica do botão verde da janela de missão (mission_talk.py): recolorir o 9-slice do ui_kit, sem desenho novo,
para manter borda, sombra e cantos idênticos aos outros botões.
"""
import sys; sys.path.insert(0, ".claude/skills/pixel-art/scripts")
from pixelart import *

# roxo do botão -> vinho/carmim (Resurrect 64); contorno ink e sombra #45293f ficam
DANGER = {"#6b3e75": "#7a3045", "#a884f3": "#ae2334", "#905ea9": "#ae2334", "#eaaded": "#e83b3b"}

if __name__ == "__main__":
    for src, dst in (("button_normal", "button_danger"), ("button_hover", "button_danger_hover")):
        b = Canvas.from_image(f"assets/ui/luna/{src}.png")
        for a, c in DANGER.items():
            b.replace(a, c)
        b.save(f"assets/ui/luna/{dst}.png", preview_dir="art/previews")
    print("ok")

# caminhos literais dos assets (o pre-commit procura a fonte de cada PNG pelo caminho escrito no script):
# assets/ui/luna/button_danger.png assets/ui/luna/button_danger_hover.png
