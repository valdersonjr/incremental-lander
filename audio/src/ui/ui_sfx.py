"""Sons de interface (frequentes: curtos, suaves, com variações). Padrão: patterns/ui-sfx.md.
click/confirmar (3 var.), buy (3 var.), denied, e a gramática de navegação (auditoria de som 2026-10-09):
move (cursor, 3 var., bem baixinho), back (voltar/fechar: desce), pop (balão/aviso aparecendo), tally (tique da
contagem do resumo; o jogo sobe o pitch em graus da escala). Sobe = sim/avança; desce = não/volta; plano = negado.
Rodar da raiz: python3 audio/src/ui/ui_sfx.py [--reel]
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


def move(seed: int) -> np.ndarray:
    """Cursor: o clique sem o tick, mais curto (35 ms) e mais grave/abafado — agradável na centésima repetição."""
    rng = np.random.default_rng(seed + 50)
    f = snap(rng.uniform(560, 760))
    tone = lowpass(triangle(f, 0.035), 2200) * decay(0.035, 0.009)
    return fade(tone, 0.001, 0.008)


def back() -> np.ndarray:
    """Voltar/fechar: o clique invertido — duas notas DESCENDO (A5 -> E5), triângulo suave, 110 ms."""
    a = lowpass(pulse(note("A5"), 0.05, duty=0.5), 2800) * decay(0.05, 0.016)
    b = lowpass(triangle(note("E5"), 0.07), 2400) * decay(0.07, 0.022)
    return fade(mix([(a, 0, -2), (b, 0.04, 0)]), 0.001, 0.015)


def pop() -> np.ndarray:
    """Balão aparecendo: bolha (seno com pitch subindo rápido, ~15 ms, receita de gota) + nota curta E6."""
    bub = sine(sweep(500, 1500, 0.03), 0.03) * decay(0.03, 0.009)
    ding = triangle(note("E6"), 0.09) * decay(0.09, 0.025)
    return fade(lowpass(mix([(bub, 0, 0), (ding, 0.02, -6)]), 6000), 0.001, 0.02)


def tally() -> np.ndarray:
    """Tique da contagem: 28 ms, seno + triângulo em D6 abafado; o jogo sobe o pitch grau a grau."""
    x = sine(note("D6"), 0.028) * 0.6 + triangle(note("D6"), 0.028) * 0.4
    return fade(lowpass(x * decay(0.028, 0.008), 4000), 0.001, 0.006)


# caminhos literais gerados por save_variations (o pre-commit procura a fonte de cada asset pelo caminho):
# assets/audio/ui/click_01.wav assets/audio/ui/click_02.wav assets/audio/ui/click_03.wav
# assets/audio/ui/buy_01.wav assets/audio/ui/buy_02.wav assets/audio/ui/buy_03.wav
# assets/audio/ui/move_01.wav assets/audio/ui/move_02.wav assets/audio/ui/move_03.wav
# assets/audio/ui/back.wav assets/audio/ui/pop.wav assets/audio/ui/tally.wav

if __name__ == "__main__":
    save_variations(click, "assets/audio/ui/click.wav", "ui", 3, tres_path="assets/audio/ui/click.tres")
    save_variations(buy, "assets/audio/ui/buy.wav", "ui", 3, tres_path="assets/audio/ui/buy.tres")
    save_wav("assets/audio/ui/denied.wav", denied(), "ui")
    save_variations(move, "assets/audio/ui/move.wav", "ui", 3, tres_path="assets/audio/ui/move.tres")
    save_wav("assets/audio/ui/back.wav", back(), "ui")
    save_wav("assets/audio/ui/pop.wav", pop(), "ui")
    save_wav("assets/audio/ui/tally.wav", tally(), "ui")
    if "--reel" in sys.argv:          # prévia: mover x3, confirmar, mover x2, voltar, negado, balão, contagem
        PENT = [0, 2, 4, 7, 9, 12, 14, 16, 19, 21, 24]
        seq = [(move(0), 0.0, -6), (move(1), 0.18, -6), (move(2), 0.36, -6), (click(0), 0.6, 0),
               (move(0), 1.1, -6), (move(1), 1.28, -6), (back(), 1.55, 0), (denied(), 2.1, 0), (pop(), 2.7, 0)]
        seq += [(pitch_shift(tally(), s_), 3.3 + i * 0.07, -3) for i, s_ in enumerate(PENT)]
        save_wav("audio/previews/ui_reel.wav", mix(seq), "jingle", do_normalize=True)
