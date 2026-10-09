"""Sons do ROADMAP 16.5: parada da Estrada alcançada, degrau de peça e pouso perfeito. Padrão: patterns/step-sfx.md.
Escala D pentatônica, secos (sem reverb assado), timbres do tema (marimba/ocarina) e dos sinos FM do jogo.
  road_stop    parada nova na Estrada (toca muito: ~29 por mundo) — curto (~0,9 s), no lugar da fanfarra unlock
               A "xilofone": marimba D5-F#5-A5 subindo + sininho A6 | B "sino-pop": bolha + 2 sinos em quinta (D6, A6)
  part_step    a peça subiu de degrau e CRESCEU no desenho (~1,2 s), no lugar do jingle milestone genérico
               A "catraca": 3 cliques de catraca subindo + "boing" crescendo + acorde de sino
               B "infla": pulso que sobe uma oitava (fwoop, a peça inflando) + cascata de brilhos
  perfect      pouso perfeito (o jogo sobe o pitch a cada perfeito seguido, como o tique da contagem)
               A "ding duplo": 2 sinos rápidos A5 -> D6 + brilho | B "tim": triângulo + cascata chip curta
Rodar da raiz: python3 audio/src/sfx/step_sfx.py --options (prévias) | --export (escolhidas em PICK)"""
import sys

sys.path.insert(0, ".claude/skills/sound-design/scripts")
sys.path.insert(0, "audio/src/music")
from soundkit import *
from soundtrack import _lead_marimba

PICK = {"road_stop": "A", "part_step": "A", "perfect": "A"}


def _bell(n: str, dur: float, index: float = 2.2) -> np.ndarray:
    return fm(note(n), dur, ratio=3.5, index=env([(0, index), (dur, 0.2)], dur)) * decay(dur, dur * 0.35)


def _bubble(f0: float, d: float = 0.07) -> np.ndarray:
    return sine(sweep(f0, f0 * 2.2, d), d) * decay(d, d * 0.35)


def road_stop(opt: str = "A") -> np.ndarray:
    if opt == "A":
        mar = _lead_marimba()
        parts = [(mar(note(n), 0.25, 1.0), i * 0.075, -2 + i) for i, n in enumerate(["D5", "F#5", "A5"])]
        parts.append((_bell("A6", 0.5, 1.4), 0.17, -12))
        return fade(lowpass(mix(parts), 5000), 0.001, 0.12)
    parts = [(_bubble(500), 0.0, -4), (_bell("D6", 0.6, 1.2), 0.04, 0), (_bell("A6", 0.6, 0.8), 0.12, -6)]
    return fade(lowpass(mix(parts), 4200), 0.001, 0.15)     # toca muito: agudo controlado (<= 15% > 5 kHz)


def _ratchet(f: float, seed: int) -> np.ndarray:
    d = 0.03
    return bandpass(noise(d, "white", seed), f, f * 2.2) * decay(d, 0.006) + triangle(f / 2, d) * decay(d, 0.008) * 0.6


def part_step(opt: str = "A") -> np.ndarray:
    if opt == "A":
        parts = [(_ratchet(f, 10 + i), i * 0.07, -4) for i, f in enumerate([900, 1200, 1500])]
        boing = triangle(sweep(note("D4"), note("D5"), 0.18), 0.18) * adsr(0.18, 0.005, 0.05, 0.7, 0.08)
        parts.append((boing, 0.22, -2))
        for i, n in enumerate(["D5", "F#5", "A5"]):
            parts.append((_bell(n, 0.8, 1.8), 0.4 + 0.02 * i, -7))
        return fade(lowpass(mix(parts), 5000), 0.001, 0.2)
    fwoop = pulse(sweep(note("D4"), note("D5"), 0.35), 0.35, duty=0.25) * env([(0, 0), (0.05, 1), (0.3, 0.7), (0.35, 0)], 0.35)
    parts = [(lowpass(fwoop, 2500), 0, -3)]
    for i, n in enumerate(["A5", "B5", "D6", "E6", "F#6"]):
        parts.append((sine(note(n), 0.12) * decay(0.12, 0.04), 0.3 + i * 0.05, -8 - i))
    parts.append((_bell("D6", 0.8, 1.6), 0.55, -5))
    return fade(lowpass(mix(parts), 5000), 0.001, 0.2)


def perfect(opt: str = "A") -> np.ndarray:
    if opt == "A":
        parts = [(_bell("A5", 0.3, 1.5), 0, 0), (_bell("D6", 0.45, 1.3), 0.07, 0),
                 (bandpass(noise(0.08, "pink", 7), 2500, 4500) * decay(0.08, 0.02), 0.07, -20)]
        return fade(lowpass(mix(parts), 4500), 0.001, 0.1)       # toca a cada perfeito: agudo controlado
    ting = triangle(note("D6"), 0.3) * decay(0.3, 0.09)
    casc = mix([(pulse(note(n), 0.05, duty=0.125) * decay(0.05, 0.02), 0.06 + i * 0.035, -10 - 2 * i)
                for i, n in enumerate(["A6", "F#6", "D6"])])
    return fade(lowpass(mix([(ting, 0, 0), (casc, 0, 0)]), 5500), 0.001, 0.08)


SOUNDS = {"road_stop": ("jingle", road_stop), "part_step": ("jingle", part_step), "perfect": ("sfx", perfect)}

if __name__ == "__main__":
    # caminhos literais (o pre-commit liga cada asset ao script-fonte):
    # assets/audio/sfx/road_stop.wav assets/audio/sfx/part_step.wav assets/audio/sfx/perfect.wav
    if "--options" in sys.argv:
        for name, (kind, fn) in SOUNDS.items():
            for opt in "AB":
                save_wav(f"audio/previews/step/{name}_{opt}.wav", fn(opt), kind)
    if "--export" in sys.argv:
        for name, (kind, fn) in SOUNDS.items():
            save_wav(f"assets/audio/sfx/{name}.wav", fn(PICK[name]), kind)
