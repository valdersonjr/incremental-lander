"""Sons do cachorrinho que vem buscar o osso (2026-10-11; céu da Lua: bater num osso de pedra = o cachorrinho vem,
pega o osso e derruba a nave). Padrão: patterns/dog-sfx.md. Escala D pentatônica, secos, sem agudo estridente.
  dog_bark  "au-au" fofo de cachorrinho: pulso 25% com a altura subindo e caindo (a sílaba) passado por um filtro
            passa-faixa que fecha de "a" para "u" (formante 1,8 kHz -> 700 Hz) + sopro de ruído; 2 latidos, o 2º mais alto
  dog_bump  encontrão: "vush" de ar (ruído rosa com filtro subindo e descendo) + baque grave abafado
Rodar da raiz: python3 audio/src/sfx/dog_sfx.py [--export] [--play]
"""
import sys

sys.path.insert(0, ".claude/skills/sound-design/scripts")
from soundkit import *


def bark_syllable(f0: float, dur: float, seed: int) -> np.ndarray:
    t = np.arange(int(dur * SR)) / SR
    rise = np.minimum(t / 0.02, 1.0)
    pitch = f0 * 2 ** ((3.0 * rise - 10.0 * np.clip((t - 0.02) / (dur - 0.02), 0, 1) ** 0.7) / 12)   # sobe 3, cai 10 st
    src = pulse(pitch, dur, duty=0.25)
    formant = sweep(1800, 700, dur)                                    # "a" -> "u"
    voiced = svf(src, formant, 2.5, "bp") * 1.6 + lowpass(src, 1200) * 0.35
    breath = svf(noise(dur, "pink", seed=seed), formant, 1.5, "bp") * 0.25
    amp = env([(0, 0), (0.004, 1), (0.035, 0.55), (0.07, 0.3), (dur, 0)], dur)
    return (voiced + breath) * amp


def dog_bark() -> np.ndarray:
    a = bark_syllable(note("D5"), 0.11, 1)
    b = bark_syllable(note("E5"), 0.12, 2)
    x = mix([(a, 0, -1), (b, 0.17, 0)])
    return fade(lowpass(drive(x, 1.2), 5000), 0.001, 0.04)


def dog_bump() -> np.ndarray:
    dur = 0.34
    air = svf(noise(dur, "pink", seed=11), env([(0, 400), (0.12, 2600), (dur, 700)], dur), 1.3, "bp") \
        * env([(0, 0), (0.1, 1), (dur, 0)], dur)
    thud = triangle(sweep(note("D3"), note("A2"), 0.14), 0.14) * decay(0.14, 0.05)
    knock = lowpass(noise(0.05, "brown", seed=5), 700) * decay(0.05, 0.012)
    x = mix([(air, 0, -4), (thud, 0.1, 0), (knock, 0.1, -4)])
    return fade(lowpass(x, 4500), 0.002, 0.06)


if __name__ == "__main__":
    out = "assets/audio/sfx/" if "--export" in sys.argv else "audio/previews/"
    # caminhos literais (pre-commit): assets/audio/sfx/dog_bark.wav assets/audio/sfx/dog_bump.wav
    save_wav(f"{out}dog_bark.wav", dog_bark(), "sfx")
    save_wav(f"{out}dog_bump.wav", dog_bump(), "sfx")
    if "--play" in sys.argv:
        play_sequence([f"{out}dog_bark.wav", f"{out}dog_bump.wav"])
