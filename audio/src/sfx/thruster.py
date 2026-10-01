"""Propulsor do lander: ignição (one-shot) -> loop -> corte (one-shot). Padrão: patterns/thruster.md.

3 caracteres para o usuário escolher ouvindo (style-guide: "caráter do propulsor a definir"):
  A plasma suave  — zumbido grave afinado em D + sopro de plasma com filtro que respira + brilho elétrico leve
  B foguete grave — ronco brown forte + sopro + crepitar de chama
  C chip retrô    — chip-noise pulsante + zumbido de pulso (homenagem ao fliperama)
Camadas por faixa (ronco < 300 Hz, sopro 300 Hz-3 kHz, detalhe 2-6 kHz) para o Godot controlar volume/pitch/filtro.
Rodar da raiz: python3 audio/src/sfx/thruster.py [--export A|B|C]
"""
import sys

sys.path.insert(0, ".claude/skills/sound-design/scripts")
from soundkit import *

LOOP = 2.0       # s; LFOs com número inteiro de ciclos em LOOP fecham a emenda
PRE = 0.3        # s descartados no começo (aquecimento dos filtros: senão a emenda tem salto de energia)


def warm(x: np.ndarray) -> np.ndarray:
    return x[int(SR * PRE):]


def loop_a(seed: int = 1) -> np.ndarray:
    total = LOOP + 0.2 + PRE
    hum = unison(triangle, note("D2"), total, voices=3, detune_cents=9) * 0.55          # zumbido afinado
    hum = lowpass(hum, 320)
    breath = lfo(total, 2 / LOOP, 900, 2200, "sine", seed=seed)                         # filtro que respira
    plasma = svf(noise(total, "pink", seed), breath, 1.2, "bp") * 0.75
    shimmer = highpass(fm(note("A5"), total, 1.5, lfo(total, 3 / LOOP, 0.4, 1.4)), 2000) * 0.05
    body = tremolo(hum + plasma, 18, 0.10)
    return make_loop(warm(body + shimmer), LOOP, crossfade=0.15)


def loop_b(seed: int = 2) -> np.ndarray:
    return p_thruster_loop(LOOP, seed=seed, power=0.85)


def loop_c(seed: int = 3) -> np.ndarray:
    total = LOOP + 0.2 + PRE
    chip = chip_noise(lfo(total, 4 / LOOP, 900, 1400, "sine"), total, short=False, seed=seed) * 0.6
    chip = lowpass(chip, 3500)
    buzz = pulse(note("D2"), total, duty=0.25) * 0.25
    buzz = lowpass(buzz, 600)
    return make_loop(warm(tremolo(chip + buzz, 12, 0.25)), LOOP, crossfade=0.1)


def ignition(loop: np.ndarray, seed: int = 4, with_loop: bool = False) -> np.ndarray:
    """Whoosh (ruído com filtro abrindo 200 -> 3k) + thump sub, com fim suave. No jogo toca POR CIMA do loop,
    que entra junto (with_loop=True só para a prévia encadeada)."""
    d = 0.32
    whoosh = svf(noise(d, "pink", seed), sweep(200, 3000, d), 0.9) * env([(0, 0), (0.05, 1), (0.2, 0.6), (d, 0)], d)
    thump = sine(sweep(110, 50, 0.18), 0.18) * decay(0.18, 0.05)
    parts = [(whoosh, 0, -6), (thump, 0, -4)]
    if with_loop:
        parts.append((loop[: int(SR * d)] * env([(0, 0), (d, 1)], d), 0, 0))
    return mix(parts)


def cutoff(loop: np.ndarray) -> np.ndarray:
    """Corte: o loop cai de pitch e fecha o filtro em 0,35 s (desligando)."""
    d = 0.35
    seg = pitch_shift(loop[: int(SR * d * 1.4)], -5)[: int(SR * d)]
    d = len(seg) / SR                                       # tamanho real (o pitch_shift pode encurtar 1 amostra)
    seg = svf(seg, sweep(3000, 200, d), 0.7)[: len(seg)] * env([(0, 1), (d, 0)], d, "exp")[: len(seg)]
    return fade(seg, 0.002, 0.05)


def audition(loop: np.ndarray) -> np.ndarray:
    return concat(concat(ignition(loop, with_loop=True), np.concatenate([loop, loop[: int(SR * 1.0)]]), gap=0.0), cutoff(loop), gap=0.0)


OPTIONS = {"A": loop_a, "B": loop_b, "C": loop_c}

if __name__ == "__main__":
    pick = sys.argv[sys.argv.index("--export") + 1] if "--export" in sys.argv else None
    if pick:
        lp = OPTIONS[pick]()
        save_wav("assets/audio/sfx/thruster_loop.wav", lp, "loop", loop=True)
        save_wav("assets/audio/sfx/thruster_start.wav", ignition(lp), "sfx")
        save_wav("assets/audio/sfx/thruster_stop.wav", cutoff(lp), "sfx")
    else:
        for k, fn in OPTIONS.items():
            lp = fn()
            save_wav(f"audio/previews/thruster_{k}_loop.wav", lp, "loop", loop=True)
            save_wav(f"audio/previews/thruster_{k}_demo.wav", audition(lp), "loop")
