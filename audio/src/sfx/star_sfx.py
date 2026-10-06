"""Estrela de missão (v12, 2026-10-06): toca ao ganhar a estrela de cada entrega (logo depois do "entregue").
Frequente -> curta (~0,4 s), suave, sem agudo estridente, e diferente do cristal (sino FM de vidro). Padrão:
patterns/mission-star.md. Escala D (SFX_SCALE). Liberar missão usa o jingle "unlock" (progress_sfx.py).
Rodar da raiz: python3 audio/src/sfx/star_sfx.py [--export] [--options]
"""
import sys

sys.path.insert(0, ".claude/skills/sound-design/scripts")
from soundkit import *


def _ping(f: float, dur: float, tau: float) -> np.ndarray:
    """Sino fino: seno + 2o harmonico baixinho, ataque instantaneo, queda exponencial."""
    return (sine(f, dur) + 0.18 * sine(f * 2.0, dur)) * decay(dur, tau)


def _shimmer(dur: float, seed: int) -> np.ndarray:
    """Brilho de ar (cauda): ruido rosa em banda 5-8 kHz, bem baixo, com tremolo rapido (cintilar)."""
    n = bandpass(noise(dur, "pink", seed=seed), 5000, 8000) * env([(0, 0), (0.03, 1), (dur, 0)], dur)
    return tremolo(n, 22, 0.7)


def star_a() -> np.ndarray:
    """A — sino duplo subindo (D6 -> A6) + brilho de ar."""
    dur = 0.42
    x = mix([(_ping(note("D6"), 0.3, 0.07), 0, -3), (_ping(note("A6"), dur - 0.06, 0.11), 0.06, 0),
             (_shimmer(0.36, 7), 0.05, -20)])
    return fade(lowpass(x, 8000), 0.001, 0.08)


def star_b() -> np.ndarray:
    """B — brilhinho: tres pulsos curtinhos F#6 A6 D7 (12,5%) com eco curto."""
    notes = ["F#6", "A6", "D7"]
    parts = [(pulse(note(n), 0.07, duty=0.125) * decay(0.07, 0.025), i * 0.04, -4 + i) for i, n in enumerate(notes)]
    x = mix(parts + [(_shimmer(0.3, 9), 0.08, -22)])
    x = delay(x, time=0.09, feedback=0.25, mix_=0.25, pingpong=False)
    return fade(lowpass(x, 7500), 0.001, 0.1)


def star_c() -> np.ndarray:
    """C — estrela macia: triangulo que desliza D6 -> A6 e um sino A6 por cima (mais redondo, menos brilho)."""
    dur = 0.4
    glide = triangle(sweep(note("D6"), note("A6"), 0.08), 0.08)
    body = np.concatenate([glide, triangle(note("A6"), dur - 0.08)]) * decay(dur, 0.12)
    x = mix([(body, 0, -2), (_ping(note("A6"), dur, 0.1), 0.06, -8), (_shimmer(0.3, 11), 0.06, -24)])
    return fade(lowpass(x, 6500), 0.001, 0.08)


CHOSEN = star_a
OPTIONS = {"a": star_a, "b": star_b, "c": star_c}

if __name__ == "__main__":
    if "--options" in sys.argv:
        for k, make in OPTIONS.items():
            save_wav(f"audio/previews/star_{k}.wav", make(), "sfx")
        # contexto: "entregue" + estrela (como no jogo) para cada opcao
        import soundfile as sf
        dl, sr = sf.read("assets/audio/sfx/delivered.wav")
        for k, make in OPTIONS.items():
            save_wav(f"audio/previews/star_{k}_ctx.wav", mix([(dl, 0, 0), (make(), 0.55, 0)]), "jingle")
    if "--export" in sys.argv:
        # caminho literal (o pre-commit liga o asset ao script-fonte): assets/audio/sfx/star.wav
        save_wav("assets/audio/sfx/star.wav", CHOSEN(), "sfx")
