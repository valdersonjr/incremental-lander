"""Perigos por mundo (Fase 11.5; padrão: patterns/world-hazards.md): rajada (Silvânia), gêiser de calda (Docelândia),
assobio do brinquedo caindo (O Quarto). Tocam quando o perigo LIGA perto da nave — são o aviso sonoro. Secos.
Rodar da raiz: python3 audio/src/sfx/hazard_sfx.py [--export] [--reel]
"""
import sys

sys.path.insert(0, ".claude/skills/sound-design/scripts")
from soundkit import *


def gust() -> np.ndarray:
    """Rajada: ruído rosa com passa-banda varrendo 300 -> 1,4k -> 500 Hz e volume que cresce e some."""
    dur = 0.95
    n = noise(dur, "pink", seed=11)
    cut = env([(0, 300), (0.4, 1400), (dur, 500)], dur, "exp")
    x = svf(n, cut, q=1.4, mode="bp")
    x = x * env([(0, 0.0), (0.35, 1.0), (dur, 0.0)], dur)
    return fade(x, 0.01, 0.15)


def geyser() -> np.ndarray:
    """Gêiser: baque grave + nuvem de bolhas (blips senoidais curtos com o tom subindo, na escala) + chiado."""
    dur = 0.8
    thump = sine(sweep(95, 50, 0.18), 0.18) * decay(0.18, 0.06)
    rng = np.random.default_rng(7)
    parts = [(thump, 0, 0)]
    for k in range(26):
        f = snap(rng.uniform(380, 1500))
        b = sine(sweep(f, f * 1.5, 0.018), 0.018) * decay(0.018, 0.008)
        parts.append((b, 0.04 + k * 0.022 + rng.uniform(0, 0.01), -7 - rng.uniform(0, 6)))
    hiss = highpass(noise(dur, "white", seed=3), 2500) * decay(dur, 0.25)
    parts.append((hiss, 0.02, -20))
    return fade(lowpass(mix(parts), 7000), 0.002, 0.12)


def toy_fall() -> np.ndarray:
    """Assobio de queda: triângulo descendo de A6 a D5 (convenção de desenho animado: algo vai cair aqui)."""
    dur = 0.9
    f = sweep(note("A6"), note("D5"), dur)
    x = triangle(vibrato(f, dur, 7.0, 0.15), dur) * env([(0, 0.0), (0.05, 1.0), (0.75, 0.8), (dur, 0.0)], dur)
    return fade(lowpass(x, 6000), 0.005, 0.08)


if __name__ == "__main__":
    out = "assets/audio/sfx/" if "--export" in sys.argv else "audio/previews/"
    # caminhos literais (o pre-commit liga cada asset ao script-fonte):
    # assets/audio/sfx/gust.wav assets/audio/sfx/geyser.wav assets/audio/sfx/toy_fall.wav
    for name, make in (("gust", gust), ("geyser", geyser), ("toy_fall", toy_fall)):
        save_wav(f"{out}{name}.wav", make(), "sfx")
    if "--reel" in sys.argv:
        seq = mix([(gust(), 0.0, 0), (geyser(), 1.2, 0), (toy_fall(), 2.3, 0)])
        save_wav("audio/previews/hazard_reel.wav", seq, "sfx")
