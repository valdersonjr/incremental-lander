"""Ambiência de cada mundo (padrão: patterns/world-ambience.md). Loops estéreo de LOOP s, -24 LUFS, embaixo de tudo:
cama contínua (drone/ar) + eventos esparsos com variação (nunca rítmicos), tonal em D.
  luna   — Lua em guerra (só cenário): drone grave espacial + estrondos distantes e abafados da batalha.
Rodar da raiz: python3 audio/src/ambience/world_ambience.py [--export] [luna]
"""
import sys

sys.path.insert(0, ".claude/skills/sound-design/scripts")
from soundkit import *

LOOP = 24.0          # s; LFOs com número inteiro de ciclos no loop
TAIL = 4.0           # s de cauda dobrada sobre o início (wrap_tail)


def _lfo_k(k: int, lo: float, hi: float, phase: float = 0.0) -> np.ndarray:
    """LFO senoidal com k ciclos exatos no loop (fecha a emenda), na duração com cauda."""
    return lfo(LOOP + TAIL, k / LOOP, lo, hi, "sine", phase)


def _bed_air(seed: int, lo: float, hi: float, k: int, db: float) -> np.ndarray:
    """Ar/ruído rosa com passa-baixa que respira devagar (k ciclos no loop), estéreo por seeds diferentes."""
    d = LOOP + TAIL
    out = []
    for ch in range(2):
        n = noise(d, "pink", seed=seed + ch)
        out.append(svf(n, _lfo_k(k, lo, hi, phase=0.25 * ch), q=0.6, mode="lp"))
    return np.stack(out, axis=1) * db_to_lin(db)


def _place(events: list, rng: np.random.Generator, count: int, make, db: tuple[float, float],
           span: tuple[float, float] = (0.0, LOOP)) -> None:
    """Espalha `count` eventos sem ritmo no loop (intervalos irregulares), com pan e volume variados."""
    slots = np.sort(rng.uniform(span[0], span[1], count))
    for i, t in enumerate(slots):
        x = make(i, rng)
        events.append((pan(x, float(rng.uniform(-0.8, 0.8))), float(t), float(rng.uniform(*db))))


def _finish(beds: list, events: list, size: float, damp: float, wet: float) -> np.ndarray:
    """Cama contínua fecha por crossfade (LFOs com ciclos inteiros); eventos ganham espaço (reverb) e a cauda que
    passa do fim é dobrada sobre o início — nada corta na emenda."""
    bed = make_loop(to_stereo(mix(beds, LOOP + TAIL)), LOOP, crossfade=1.5)
    ev = reverb(to_stereo(mix(events, LOOP + TAIL)), size=size, damp=damp, mix_=wet)
    return bed + wrap_tail(to_stereo(ev), LOOP)


# --- Lua ----------------------------------------------------------------------------------------------------------

def luna() -> np.ndarray:
    d = LOOP + TAIL
    rng = np.random.default_rng(101)
    drone = unison(sine, note("D2"), d, voices=4, detune_cents=7, stereo=True) * 0.5
    fifth = unison(triangle, note("A2"), d, voices=3, detune_cents=9, stereo=True) * 0.18
    swell = _lfo_k(2, 0.55, 1.0)[:, None]
    bed = (drone + fifth) * swell
    air = _bed_air(5, 220, 700, 3, -8)
    beds = [(bed, 0, -9), (air, 0, 0)]
    events = []

    def boom(i: int, r: np.random.Generator) -> np.ndarray:        # batalha ao longe: baque abafado + rumor
        dur = float(r.uniform(1.4, 2.4))
        body = lowpass(noise(dur, "brown", seed=200 + i), float(r.uniform(140, 260))) * decay(dur, dur * 0.3, 0.02)
        sub = sine(sweep(float(r.uniform(70, 90)), 38, dur), dur) * decay(dur, 0.35, 0.01) * 0.6
        return body + sub

    def ping(i: int, r: np.random.Generator) -> np.ndarray:        # rádio/sonar distante (sino FM, na escala)
        f = snap(float(r.uniform(700, 1400)))
        x = fm(f, 1.6, ratio=3.5, index=env([(0, 2.0), (1.6, 0.1)], 1.6)) * decay(1.6, 0.4)
        return lowpass(x, 3000) * 0.5

    _place(events, rng, 6, boom, (-10, -4))
    _place(events, rng, 3, ping, (-14, -9))
    return _finish(beds, events, 0.85, 0.5, 0.3)


# --- Silvânia (floresta) ------------------------------------------------------------------------------------------

WORLDS = {"luna": luna}   # 2026-10-06: só a Lua por enquanto (os outros mundos estão no git)

if __name__ == "__main__":
    out = "assets/audio/ambience/" if "--export" in sys.argv else "audio/previews/"
    # caminhos literais (o pre-commit liga cada asset ao script-fonte):
    # assets/audio/ambience/luna.wav
    names = [a for a in sys.argv[1:] if a in WORLDS] or list(WORLDS)
    for name in names:
        save_wav(f"{out}{name}.wav", WORLDS[name](), "ambience", loop=True)
