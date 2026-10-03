"""Recompensas do voo (Fase 11): coleta de cristal (sobe um grau a cada cristal do mesmo salto) e estalo de combo
(sobe com o tamanho do combo). Padrão: patterns/reward-chain.md. Escala D pentatônica maior, secos (sem reverb).
Rodar da raiz: python3 audio/src/sfx/reward_sfx.py [--export]
"""
import sys

sys.path.insert(0, ".claude/skills/sound-design/scripts")
from soundkit import *

# graus seguidos da pentatônica (cada cristal / nível de combo sobe um degrau: a cadeia "se ouve")
CRYSTAL_NOTES = ["A5", "B5", "D6"]
FIFTH = {"A5": "E6", "B5": "F#6", "D6": "A6"}
COMBO_START = {2: "D5", 3: "E5", 4: "F#5", 5: "A5"}


def crystal(n: int) -> np.ndarray:
    """Sino de vidro: FM (ratio 3,5, índice caindo) na nota + quinta suave; tique de ruído no ataque."""
    root = CRYSTAL_NOTES[n]
    dur = 0.32
    body = fm(note(root), dur, ratio=3.5, index=env([(0, 2.2), (0.06, 0.6), (dur, 0.2)], dur)) * decay(dur, 0.085)
    fifth = sine(note(FIFTH[root]), dur) * decay(dur, 0.06)
    tick = highpass(noise(0.012, "white", seed=40 + n), 4000) * decay(0.012, 0.004)
    x = mix([(body, 0, 0), (fifth, 0.008, -9), (tick, 0, -16)])
    return fade(lowpass(x, 7000), 0.001, 0.08)


def combo(level: int) -> np.ndarray:
    """Estalo de combo: arpejo curto de 3 graus em pulso 12,5% começando mais alto a cada nível."""
    sc = scale_midis("sfx")
    i0 = sc.index(midi(COMBO_START[level]))
    notes = [mtof(sc[i0 + k * 2]) for k in range(3)]          # pula um grau: arpejo aberto e brilhante
    step = 0.045
    parts = [(pulse(f, 0.09, duty=0.125) * decay(0.09, 0.035), i * step, -2 if i == 2 else -5)
             for i, f in enumerate(notes)]
    spark = fm(notes[-1] * 2, 0.12, ratio=2.0, index=env([(0, 1.5), (0.12, 0.1)], 0.12)) * decay(0.12, 0.04)
    x = mix(parts + [(spark, 2 * step, -12)])
    return fade(lowpass(x, 6500), 0.001, 0.05)


if __name__ == "__main__":
    out = "assets/audio/sfx/" if "--export" in sys.argv else "audio/previews/"
    files = []
    # caminhos literais (o pre-commit liga cada asset ao script-fonte):
    # assets/audio/sfx/crystal_1.wav assets/audio/sfx/crystal_2.wav assets/audio/sfx/crystal_3.wav
    # assets/audio/sfx/combo_2.wav assets/audio/sfx/combo_3.wav assets/audio/sfx/combo_4.wav assets/audio/sfx/combo_5.wav
    for n in range(3):
        p = f"{out}crystal_{n + 1}.wav"
        save_wav(p, crystal(n), "sfx")
        files.append(p)
    for lv in (2, 3, 4, 5):
        p = f"{out}combo_{lv}.wav"
        save_wav(p, combo(lv), "sfx")
        files.append(p)
    if "--reel" in sys.argv:                                   # resumo para o usuário: 3 cristais + entrega + combo
        seq = mix([(crystal(0), 0.0, 0), (crystal(1), 0.35, 0), (crystal(2), 0.7, 0),
                   (combo(2), 1.6, 0), (combo(3), 2.2, 0), (combo(4), 2.8, 0), (combo(5), 3.4, 0)])
        save_wav("audio/previews/reward_reel.wav", seq, "jingle", do_normalize=True)
