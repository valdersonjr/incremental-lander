"""Loops das mecânicas dos mundos (auditoria de som, 2026-10-09). Padrão: patterns/world-loops.md.
Mono, kind "loop" (-18 LUFS); o jogo controla o volume pela intensidade (vento, bolhas, velocidade no gelo).
  ice_slide    Sorvete: nave deslizando no gelo (chiado de patins + rumor grave), volume/pitch pela velocidade
  wind_loop    Jardim (vento de dente-de-leão) e Nuvens (correntes, tocado mais agudo): sopro com filtro respirando
  bubbles_loop Bolhas: coluna de bolhas empurrando a nave (bolhinhas aleatórias sobre um borbulhar grave)
Rodar da raiz: python3 audio/src/sfx/world_loops.py [--export]
"""
import sys

sys.path.insert(0, ".claude/skills/sound-design/scripts")
from soundkit import *

PRE = 0.3      # aquecimento dos filtros descartado (senão a emenda pula)


def ice_slide() -> np.ndarray:
    """Patins: ruído branco em banda 2,5-6 kHz com grão irregular (LFO aleatório) + rumor brown grave do casco."""
    loop = 1.5
    total = loop + 0.2 + PRE
    grain = lfo(total, 14, 0.6, 1.0, "random", seed=111)
    hiss = bandpass(noise(total, "white", 112), 2500, 6000) * grain * 0.5
    rumble = lowpass(noise(total, "brown", 113), 260) * 0.8
    tone = lowpass(triangle(note("D3"), total), 400) * 0.08                 # leve afinação em D (casa com a trilha)
    return make_loop((hiss + rumble + tone)[ns(PRE):], loop, crossfade=0.2)


def wind_loop() -> np.ndarray:
    """Vento: ruído rosa em passa-banda que respira (3 ciclos em 4 s) + assobio muito leve na quinta (A4)."""
    loop = 4.0
    total = loop + 0.4 + PRE
    cut = lfo(total, 3 / loop, 500, 1600, "sine")
    air = svf(noise(total, "pink", 121), cut, 1.4, "bp")
    whistle = sine(vibrato(note("A4"), total, 0.75, 0.3), total) * lfo(total, 3 / loop, 0.0, 0.06, "sine")
    return make_loop((air + whistle)[ns(PRE):], loop, crossfade=0.4)


def bubbles_loop() -> np.ndarray:
    """Borbulhar: cama de ruído brown grave pulsando + ~30 bolhinhas (seno com pitch subindo) espalhadas sem ritmo."""
    loop = 2.0
    rng = np.random.default_rng(131)
    total = loop + 0.3 + PRE
    bed = lowpass(noise(total, "brown", 132), 400) * lfo(total, 6 / loop, 0.5, 1.0, "sine") * 0.5
    parts = [(bed, 0, 0)]
    for _ in range(30):
        f0 = float(rng.uniform(350, 1100))
        d = float(rng.uniform(0.03, 0.07))
        b = sine(sweep(f0, f0 * 2.2, d), d) * decay(d, d * 0.3)
        parts.append((b, float(rng.uniform(PRE, total - 0.1)), float(rng.uniform(-10, -3))))
    return make_loop(mix(parts, total)[ns(PRE):], loop, crossfade=0.2)


LOOPS = {"ice_slide": ice_slide, "wind_loop": wind_loop, "bubbles_loop": bubbles_loop}

if __name__ == "__main__":
    out = "assets/audio/sfx/" if "--export" in sys.argv else "audio/previews/"
    # caminhos literais (o pre-commit liga cada asset ao script-fonte):
    # assets/audio/sfx/ice_slide.wav assets/audio/sfx/wind_loop.wav assets/audio/sfx/bubbles_loop.wav
    for name, fn in LOOPS.items():
        save_wav(f"{out}{name}.wav", fn(), "loop", loop=True)
