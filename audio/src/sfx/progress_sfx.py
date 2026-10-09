"""Alarme de gás baixo e jingles de progresso (padrões: patterns/gas-alarm.md, patterns/progress-jingles.md).
  gas_alarm   — loop de 0,8 s: dois bipes descendo (B5 -> F#5, pulso 25% suave) + pausa. O jogo toca enquanto o gás
                está abaixo de 15% em voo e baixa o volume depois de alguns segundos (alarme que não irrita).
  milestone   — marco de upgrade / etapa da Expedição: arpejo rápido subindo na pentatônica + sino final (1,2 s).
  unlock      — mundo liberado: fanfarra curta (arpejo de D maior + acorde + sino com eco) (2,4 s).
  goal        — fanfarra de conquista (era o final do Quarto; guardada para a próxima meta) em duas frases, acorde final longo (~3,8 s).
  world_complete — mundo completo (última estrela do mundo): o motivo do tema do gatinho (F#-A-B-A-F#) na ocarina, cadência
                E5 sobre Lá -> D5 sobre Ré e "ta-dá" de sino (~3 s). Como o "Course Clear" do Mario: arranjo do tema principal.
                Opções para o usuário: A caixinha (ocarina + marimba), B fanfarra (ocarina + pulso dobrando), C sinos (motivo
                nos sinos, ocarina só no final). Prévia: --options
Rodar da raiz: python3 audio/src/sfx/progress_sfx.py [--export] [--reel]
"""
import sys

sys.path.insert(0, ".claude/skills/sound-design/scripts")
sys.path.insert(0, "audio/src/music")
from soundkit import *
from soundtrack import _bass_inst, _lead_marimba, _lead_ocarina      # timbres do tema (a ocarina é a identidade)

WC_STEP = 0.13          # colcheia do jingle (~115 BPM: mais animado que o tema, mesma melodia)
# (nota, colcheias): motivo do tema + cadência; acorde de cada trecho (Ré ... Lá -> Ré)
WC_MELODY = [("F#5", 2), ("A5", 2), ("B5", 1), ("A5", 1), ("F#5", 2), ("E5", 2), ("D5", 8)]
WC_CHORDS = [(0, "D"), (8, "A"), (10, "D")]                     # (colcheia de início, acorde)
WC_TONES = {"D": ["D4", "F#4", "A4"], "A": ["A3", "C#4", "E4"]}
WC_BASS = {"D": "D3", "A": "A2"}


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
    parts.append((pulse(vibrato(note("D6"), 0.6, 7.0, 0.25), 0.6, duty=0.25) * decay(0.6, 0.2), last, -10))
    x = mix(parts)
    # v2 (auditoria 2026-10-09): 22% > 5 kHz -> pulso 25% (era 12,5%, mais zumbido) e passa-baixa 5 kHz
    return fade(lowpass(delay(x, time=0.16, feedback=0.25, mix_=0.2, pingpong=False), 5000), 0.002, 0.15)


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


def world_complete(option: str = "A") -> np.ndarray:
    """Mundo completo: motivo do tema + cadência V -> I + "ta-dá" de sino no acorde final (opções A/B/C)."""
    oca, mar, bass = _lead_ocarina(), _lead_marimba(), _bass_inst(r=0.1)
    parts, t = [], 0.0
    end = sum(n for _, n in WC_MELODY) * WC_STEP
    for i, (n, k) in enumerate(WC_MELODY):
        d = k * WC_STEP * (0.92 if i < len(WC_MELODY) - 1 else 1.0)
        last = i == len(WC_MELODY) - 1
        if option in ("A", "B") or last:
            parts.append((oca(note(n), d, 1.0), t, -2))
        if option == "B":                                       # fanfarra: pulso 25% dobrando a melodia uma oitava abaixo
            parts.append((_note(note(n) / 2, d * 0.9, 0.25), t, -10))
        if option == "C" and not last:                          # sinos: o motivo inteiro na caixinha de música
            parts.append((_bell(note(n), 0.6, 2.0), t, -1))
        t += k * WC_STEP
    for j, (step, c) in enumerate(WC_CHORDS):
        t0 = step * WC_STEP
        t1 = WC_CHORDS[j + 1][0] * WC_STEP if j + 1 < len(WC_CHORDS) else end
        final = j == len(WC_CHORDS) - 1
        parts.append((bass(note(WC_BASS[c]), (t1 - t0) * 0.9 if not final else 1.0, 1.0), t0, -8))
        tones = WC_TONES[c]
        if final:                                              # "ta-dá": acorde dedilhado subindo + sino
            for k, n in enumerate(tones + ["D5"]):
                parts.append((mar(note(n), 0.9, 1.0), t0 + 0.035 * k, -9))
            parts.append((_bell(note("A5"), 1.2, 2.0), t0 + 0.12, -9))
            parts.append((_bell(note("D6"), 1.3, 2.2), t0 + 0.16, -7))
        else:                                                  # caminhada da marimba em colcheias no acorde
            for k in range(int(round((t1 - t0) / WC_STEP))):
                n = tones[[0, 1, 2, 1][k % 4]]
                parts.append((mar(note(n), WC_STEP, 1.0), t0 + k * WC_STEP, -12 if option != "A" else -10))
    x = mix(parts)
    return fade(lowpass(delay(x, time=WC_STEP * 3, feedback=0.22, mix_=0.16, pingpong=False), 6000), 0.002, 0.3)


WORLD_COMPLETE_PICK = "A"
JINGLES = {"milestone": milestone, "unlock": unlock, "goal": goal,
           "world_complete": lambda: world_complete(WORLD_COMPLETE_PICK)}

if __name__ == "__main__":
    out = "assets/audio/sfx/" if "--export" in sys.argv else "audio/previews/"
    # caminhos literais (o pre-commit liga cada asset ao script-fonte):
    # assets/audio/sfx/gas_alarm.wav assets/audio/sfx/milestone.wav assets/audio/sfx/unlock.wav
    # assets/audio/sfx/goal.wav assets/audio/sfx/world_complete.wav
    if "--options" in sys.argv:                                # prévia das opções do mundo completo (não exporta)
        for opt in "ABC":
            save_wav(f"audio/previews/world_complete_{opt}.wav", world_complete(opt), "jingle")
        sys.exit(0)
    save_wav(f"{out}gas_alarm.wav", gas_alarm(), "loop", loop=True)
    for name, make in JINGLES.items():
        save_wav(f"{out}{name}.wav", make(), "jingle")
    if "--reel" in sys.argv:
        alarm = np.tile(gas_alarm(), 4)
        seq = concat(alarm, milestone(), unlock(), goal(), gap=0.6)
        save_wav("audio/previews/progress_reel.wav", seq, "jingle", do_normalize=False)
