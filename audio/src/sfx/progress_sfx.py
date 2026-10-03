"""Alarme de gás baixo e jingles de progresso (padrões: patterns/gas-alarm.md, patterns/progress-jingles.md).
  gas_alarm   — loop de 0,8 s: dois bipes descendo (B5 -> F#5, pulso 25% suave) + pausa. O jogo toca enquanto o gás
                está abaixo de 15% em voo e baixa o volume depois de alguns segundos (alarme que não irrita).
  milestone   — marco de upgrade / etapa da Expedição: arpejo rápido subindo na pentatônica + sino final (1,2 s).
  unlock      — mundo liberado: fanfarra curta (arpejo de D maior + acorde + sino com eco) (2,4 s).
  prestige    — recomeço (Poeira Estelar): cascata de sinos em D lídio subindo + brilho que se abre (2,8 s).
  goal        — final (chegou ao Quarto): fanfarra maior em duas frases, acorde final longo (~3,8 s).
Rodar da raiz: python3 audio/src/sfx/progress_sfx.py [--export] [--reel]
"""
import sys

sys.path.insert(0, ".claude/skills/sound-design/scripts")
from soundkit import *


def _beep(f: float, dur: float) -> np.ndarray:
    x = pulse(f, dur, duty=0.25) * 0.6 + triangle(f, dur) * 0.4
    return lowpass(x, 4000) * env([(0, 0), (0.006, 1), (dur * 0.7, 0.8), (dur, 0)], dur)


def gas_alarm() -> np.ndarray:
    period = 0.8
    x = mix([(_beep(note("B5"), 0.11), 0.0, 0), (_beep(note("F#5"), 0.13), 0.17, -1)], period)
    return x[: ns(period)]


def _note(f: float, dur: float, duty: float = 0.25) -> np.ndarray:
    return pulse(f, dur, duty=duty) * env([(0, 0), (0.004, 1), (dur, 0.0)], dur)


def _bell(f: float, dur: float, index: float = 2.5) -> np.ndarray:
    return fm(f, dur, ratio=3.5, index=env([(0, index), (dur, 0.2)], dur)) * decay(dur, dur * 0.35)


def milestone() -> np.ndarray:
    notes = ["D5", "E5", "F#5", "A5", "B5", "D6"]
    parts = [(_note(note(n), 0.07), i * 0.055, -2) for i, n in enumerate(notes)]
    last = 0.055 * len(notes)
    parts.append((_bell(note("D6"), 0.9) * 0.9, last, 0))
    parts.append((pulse(vibrato(note("D6"), 0.6, 7.0, 0.25), 0.6, duty=0.125) * decay(0.6, 0.2), last, -8))
    x = mix(parts)
    return fade(lowpass(delay(x, time=0.16, feedback=0.25, mix_=0.2, pingpong=False), 7000), 0.002, 0.15)


def unlock() -> np.ndarray:
    parts = [(_note(note(n), 0.11, 0.5), i * 0.09, -3) for i, n in enumerate(["D4", "A4", "D5", "F#5", "A5"])]
    t = 0.09 * 5
    for f, db in ((note("D4"), -6), (note("F#4"), -8), (note("A4"), -8), (note("D5"), -6)):
        body = (pulse(f, 1.6, duty=0.25) * 0.5 + triangle(f, 1.6)) * env([(0, 0), (0.01, 1), (0.4, 0.6), (1.6, 0)], 1.6)
        parts.append((body, t, db))
    parts.append((_bell(note("A5"), 1.6), t, -2))
    parts.append((triangle(note("D3"), 1.4) * decay(1.4, 0.5), t, -4))
    x = mix(parts)
    return fade(lowpass(delay(x, time=0.22, feedback=0.3, mix_=0.25, pingpong=False), 7000), 0.002, 0.25)


def prestige() -> np.ndarray:
    # D lídio (G#: o "brilho" do lídio) — som de algo maior começando
    notes = ["D5", "E5", "F#5", "G#5", "A5", "C#6", "D6", "E6"]
    parts = [(_bell(note(n), 1.3, 1.8) * 0.8, i * 0.11, -3 - i * 0.3) for i, n in enumerate(notes)]
    swell_d = 2.4
    pad = sum(unison(saw, note(n), swell_d, voices=3, detune_cents=12) for n in ("D4", "A4", "E5"))
    pad = svf(pad, sweep(400, 3500, swell_d), q=0.9, mode="lp") * env([(0, 0), (1.2, 1), (swell_d, 0)], swell_d)
    parts.append((pad * 0.3, 0.1, -4))
    x = mix(parts)
    return fade(lowpass(delay(x, time=0.19, feedback=0.35, mix_=0.25, pingpong=False), 8000), 0.002, 0.3)


def goal() -> np.ndarray:
    parts = []
    phrase1 = [("D5", 0.12), ("F#5", 0.12), ("A5", 0.24), ("F#5", 0.12), ("A5", 0.36)]
    phrase2 = [("B5", 0.12), ("A5", 0.12), ("B5", 0.12), ("D6", 0.5)]
    t = 0.0
    for n, d in phrase1 + phrase2:
        parts.append((_note(note(n), d * 0.95, 0.25), t, -3))
        parts.append((triangle(note(n) / 2, d * 0.95) * env([(0, 0), (0.005, 1), (d * 0.95, 0)], d * 0.95), t, -9))
        t += d
    for f, db in ((note("D4"), -6), (note("F#4"), -8), (note("A4"), -8), (note("D5"), -6), (note("A5"), -10)):
        body = (pulse(f, 1.6, duty=0.25) * 0.4 + triangle(f, 1.6)) * env([(0, 0), (0.02, 1), (0.6, 0.7), (1.6, 0)], 1.6)
        parts.append((body, t - 0.5, db))
    parts.append((_bell(note("D6"), 1.6, 3.0), t - 0.5, -1))
    parts.append((triangle(note("D2"), 1.5) * decay(1.5, 0.6), t - 0.5, -3))
    x = mix(parts)
    return fade(lowpass(delay(x, time=0.24, feedback=0.3, mix_=0.22, pingpong=False), 7500), 0.002, 0.3)


JINGLES = {"milestone": milestone, "unlock": unlock, "prestige": prestige, "goal": goal}

if __name__ == "__main__":
    out = "assets/audio/sfx/" if "--export" in sys.argv else "audio/previews/"
    # caminhos literais (o pre-commit liga cada asset ao script-fonte):
    # assets/audio/sfx/gas_alarm.wav assets/audio/sfx/milestone.wav assets/audio/sfx/unlock.wav
    # assets/audio/sfx/prestige.wav assets/audio/sfx/goal.wav
    save_wav(f"{out}gas_alarm.wav", gas_alarm(), "loop", loop=True)
    for name, make in JINGLES.items():
        save_wav(f"{out}{name}.wav", make(), "jingle")
    if "--reel" in sys.argv:
        alarm = np.tile(gas_alarm(), 4)
        seq = concat(alarm, milestone(), unlock(), prestige(), goal(), gap=0.6)
        save_wav("audio/previews/progress_reel.wav", seq, "jingle", do_normalize=False)
