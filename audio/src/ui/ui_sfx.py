"""Sons de interface (frequentes: curtos, suaves, com variações). Padrão: patterns/ui-sfx.md.
click (3 var.), buy (3 var.), denied. Rodar da raiz: python3 audio/src/ui/ui_sfx.py
"""
import sys

sys.path.insert(0, ".claude/skills/sound-design/scripts")
from soundkit import *


def click(seed: int) -> np.ndarray:
    """Clique: tick de ruído bem curto + tom de pulso abafado (~1 kHz na escala), 60 ms."""
    rng = np.random.default_rng(seed)
    f = snap(rng.uniform(700, 1100))
    tone = lowpass(pulse(f, 0.06, duty=0.5), 3000) * decay(0.06, 0.018)
    tick = highpass(noise(0.008, "white", seed), 2500) * decay(0.008, 0.002)
    return fade(mix([(tone, 0, 0), (tick, 0, -12)]), 0.001, 0.01)


def buy(seed: int) -> np.ndarray:
    """Compra: 2 notas subindo (cha-ching retrô), mais suave que a moeda padrão."""
    return fade(lowpass(p_coin(seed=seed), 5000), 0.001, 0.03)


def denied() -> np.ndarray:
    """Negado (sem dinheiro): 2 notas descendo (segunda menor), pulso 12,5%, 150 ms."""
    a = pulse(note("A4"), 0.07, duty=0.125) * decay(0.07, 0.03)
    b = pulse(note("G#4"), 0.09, duty=0.125) * decay(0.09, 0.04)
    return fade(lowpass(concat(a, b, gap=0.0), 3000), 0.001, 0.02)


# caminhos literais gerados por save_variations (o pre-commit procura a fonte de cada asset pelo caminho):
# assets/audio/ui/click_01.wav assets/audio/ui/click_02.wav assets/audio/ui/click_03.wav
# assets/audio/ui/buy_01.wav assets/audio/ui/buy_02.wav assets/audio/ui/buy_03.wav

if __name__ == "__main__":
    save_variations(click, "assets/audio/ui/click.wav", "ui", 3, tres_path="assets/audio/ui/click.tres")
    save_variations(buy, "assets/audio/ui/buy.wav", "ui", 3, tres_path="assets/audio/ui/buy.tres")
    save_wav("assets/audio/ui/denied.wav", denied(), "ui")
