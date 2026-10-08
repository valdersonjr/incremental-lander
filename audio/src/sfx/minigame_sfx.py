"""Sons dos minijogos (auditoria dos minijogos, 2026-10-08): acerto e erro com sons DIFERENTES (antes o quique e a
batida no caule tocavam o mesmo pouso; carneirinho e vao o mesmo cristal). Padrao: patterns/minigame-sfx.md.
Escala D pentatonica maior, secos (sem reverb). Cadeias sobem um grau por item (a sequencia "se ouve").
  boing_1..3  quique no chapeu-mola (Cogumelos): triangulo que estica subindo uma quinta + oscilacao que assenta
  bump        bateu no caule (Jardim): "tonc" grave abafado, curto e quase plano (erro de tentar de novo)
  sheep_1..5  carneirinho entrou na fila (Nuvens): "be" de pulso com vibrato
  pass_1..3   passou pelo vao (Jardim): sopro de ar subindo + sininho
Rodar da raiz: python3 audio/src/sfx/minigame_sfx.py [--export] [--reel]
"""
import sys

sys.path.insert(0, ".claude/skills/sound-design/scripts")
from soundkit import *

BOING = ["D5", "F#5", "A5"]
SHEEP = ["E5", "F#5", "A5", "B5", "D6"]
PASS = ["A5", "B5", "D6"]


def boing(n: int) -> np.ndarray:
    """Mola: a nota estica uma quinta para cima em 60 ms e oscila (16 Hz, +-2,5 semitons) ate assentar."""
    dur = 0.3
    f0 = note(BOING[n])
    t = np.arange(int(dur * SR)) / SR
    stretch = f0 * 2 ** (7 / 12 * np.minimum(t / 0.06, 1.0))                # sobe uma quinta
    wob = 2 ** (2.5 / 12 * np.sin(2 * np.pi * 16 * t) * np.exp(-t / 0.11))  # oscilacao que morre
    body = triangle(stretch * wob, dur) * adsr(dur, 0.004, 0.08, 0.5, 0.15)
    click = pulse(f0 * 2, 0.02, duty=0.25) * decay(0.02, 0.006)
    x = mix([(body, 0, 0), (click, 0, -14)])
    return fade(lowpass(x, 5000), 0.001, 0.06)


def bump() -> np.ndarray:
    """Tonc: triangulo em A3 que cai so um grau (F#3) + baque de ruido grave; sem agudo (nao assusta)."""
    dur = 0.16
    body = triangle(sweep(note("A3"), note("F#3"), dur), dur) * decay(dur, 0.05)
    thud = lowpass(noise(0.05, "brown", seed=7), 600) * decay(0.05, 0.015)
    x = mix([(body, 0, 0), (thud, 0, -6)])
    return fade(lowpass(x, 1800), 0.001, 0.04)


def sheep(n: int) -> np.ndarray:
    """Be: pulso 25% com vibrato largo (9 Hz, +-0,7 semitom) em duas silabas curtas (be-e), subindo na fila."""
    f = note(SHEEP[n])
    a = pulse(vibrato(f, 0.11, 9.0, 0.7), 0.11, duty=0.25) * adsr(0.11, 0.006, 0.03, 0.6, 0.05)
    b = pulse(vibrato(f * 2 ** (2 / 12), 0.14, 9.0, 0.7), 0.14, duty=0.25) * adsr(0.14, 0.006, 0.04, 0.5, 0.08)
    x = mix([(a, 0, 0), (b, 0.1, -2)])
    return fade(lowpass(x, 4500), 0.001, 0.05)


def pass_gap(n: int) -> np.ndarray:
    """Vao: sopro de ruido rosa com filtro subindo (800 -> 3 kHz) + sininho FM na nota do caule."""
    dur = 0.32
    air = svf(noise(dur, "pink", seed=20 + n), sweep(800, 3000, dur), 1.2, "bp") * env([(0, 0), (0.08, 1), (dur, 0)], dur)
    ding = fm(note(PASS[n]), 0.25, ratio=3.0, index=env([(0, 1.6), (0.25, 0.2)], 0.25)) * decay(0.25, 0.07)
    x = mix([(air, 0, -6), (ding, 0.06, 0)])
    return fade(lowpass(x, 6500), 0.002, 0.06)


if __name__ == "__main__":
    out = "assets/audio/sfx/" if "--export" in sys.argv else "audio/previews/"
    # caminhos literais (o pre-commit liga cada asset ao script-fonte):
    # assets/audio/sfx/boing_1.wav assets/audio/sfx/boing_2.wav assets/audio/sfx/boing_3.wav assets/audio/sfx/bump.wav
    # assets/audio/sfx/sheep_1.wav assets/audio/sfx/sheep_2.wav assets/audio/sfx/sheep_3.wav assets/audio/sfx/sheep_4.wav
    # assets/audio/sfx/sheep_5.wav assets/audio/sfx/pass_1.wav assets/audio/sfx/pass_2.wav assets/audio/sfx/pass_3.wav
    for n in range(3):
        save_wav(f"{out}boing_{n + 1}.wav", boing(n), "sfx")
        save_wav(f"{out}pass_{n + 1}.wav", pass_gap(n), "sfx")
    for n in range(5):
        save_wav(f"{out}sheep_{n + 1}.wav", sheep(n), "sfx")
    save_wav(f"{out}bump.wav", bump(), "sfx")
    if "--reel" in sys.argv:                                   # resumo: 3 quiques, batida, 5 carneirinhos, 3 vaos
        seq = [(boing(0), 0.0, 0), (boing(1), 0.45, 0), (boing(2), 0.9, 0), (bump(), 1.7, 0)]
        seq += [(sheep(i), 2.4 + i * 0.35, 0) for i in range(5)]
        seq += [(pass_gap(i), 4.5 + i * 0.45, 0) for i in range(3)]
        save_wav("audio/previews/minigame_reel.wav", mix(seq), "jingle", do_normalize=True)
