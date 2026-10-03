"""Ambiência de cada mundo (padrão: patterns/world-ambience.md). Loops estéreo de LOOP s, -24 LUFS, embaixo de tudo:
cama contínua (drone/ar) + eventos esparsos com variação (nunca rítmicos), tonal em D.
  luna   — Lua em guerra (só cenário): drone grave espacial + estrondos distantes e abafados da batalha.
  ares   — Silvânia (floresta fechada): vento que respira + folhas + piados de pássaro na escala.
  kronos — Docelândia (planeta dos doces): pad morno + bolhas de calda + campainhas de caixinha de música.
  titan  — O Quarto (quarto bagunçado gigante): zumbido do cômodo + tique-taque de relógio + rangidos.
Rodar da raiz: python3 audio/src/ambience/world_ambience.py [--export] [luna ares kronos titan]
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

def ares() -> np.ndarray:
    d = LOOP + TAIL
    rng = np.random.default_rng(202)
    wind = []
    for ch in range(2):
        n = noise(d, "pink", seed=31 + ch)
        cut = _lfo_k(2, 350, 1100, phase=0.3 * ch) * _lfo_k(5, 0.8, 1.15)
        wind.append(svf(n, cut, q=1.1, mode="bp") * _lfo_k(3, 0.45, 1.0, phase=0.2 * ch))
    wind = np.stack(wind, axis=1)
    leaves = []
    for ch in range(2):
        n = highpass(noise(d, "white", seed=41 + ch), 2500)
        leaves.append(lowpass(n, 7000) * _lfo_k(7, 0.0, 1.0, phase=0.5 * ch) ** 3 * 0.25)
    leaves = np.stack(leaves, axis=1)
    hum = unison(sine, note("D3"), d, voices=3, detune_cents=6, stereo=True) * 0.06
    beds = [(wind, 0, -2), (leaves, 0, -6), (hum, 0, 0)]
    events = []

    def bird(i: int, r: np.random.Generator) -> np.ndarray:        # 2-4 piados curtos subindo/descendo, na escala
        notes = [snap(float(r.uniform(2200, 3600))) for _ in range(int(r.integers(2, 5)))]
        parts = []
        t = 0.0
        for f in notes:
            dur = float(r.uniform(0.06, 0.12))
            up = r.random() < 0.6
            chirp = sine(sweep(f * (0.85 if up else 1.12), f, dur), dur) * env([(0, 0), (0.01, 1), (dur, 0)], dur)
            parts.append((chirp, t, 0))
            t += dur + float(r.uniform(0.03, 0.09))
        return mix(parts) * 0.8

    _place(events, rng, 9, bird, (-20, -12))
    return _finish(beds, events, 0.55, 0.6, 0.18)


# --- Docelândia (doces) -------------------------------------------------------------------------------------------

def kronos() -> np.ndarray:
    d = LOOP + TAIL
    rng = np.random.default_rng(303)
    pad = (unison(triangle, note("D3"), d, voices=3, detune_cents=10, stereo=True)
           + unison(triangle, note("F#3"), d, voices=3, detune_cents=10, stereo=True) * 0.7
           + unison(triangle, note("A3"), d, voices=3, detune_cents=10, stereo=True) * 0.6)
    pad = lowpass(pad, 900) * _lfo_k(2, 0.5, 0.9)[:, None] * 0.25
    air = _bed_air(51, 400, 900, 3, -18)
    beds = [(pad, 0, -10), (air, 0, 0)]
    events = []

    def bubbles(i: int, r: np.random.Generator) -> np.ndarray:     # calda borbulhando: blips senoidais subindo
        parts = []
        for k in range(int(r.integers(4, 9))):
            f = snap(float(r.uniform(300, 900)))
            dur = float(r.uniform(0.02, 0.04))
            parts.append((sine(sweep(f, f * 1.6, dur), dur) * decay(dur, dur * 0.4), k * float(r.uniform(0.05, 0.12)), 0))
        return lowpass(mix(parts), 3500)

    def chime(i: int, r: np.random.Generator) -> np.ndarray:       # caixinha de música: 2-3 notas de sino FM
        parts = []
        t = 0.0
        for _ in range(int(r.integers(2, 4))):
            f = snap(float(r.uniform(1200, 2400)))
            parts.append((fm(f, 1.4, ratio=4.0, index=env([(0, 1.6), (1.4, 0.0)], 1.4)) * decay(1.4, 0.45), t, 0))
            t += float(r.uniform(0.18, 0.3))
        return mix(parts) * 0.6

    _place(events, rng, 10, bubbles, (-10, -5))
    _place(events, rng, 4, chime, (-15, -10))
    return _finish(beds, events, 0.6, 0.5, 0.22)


# --- O Quarto -----------------------------------------------------------------------------------------------------

def titan() -> np.ndarray:
    d = LOOP + TAIL
    rng = np.random.default_rng(404)
    room = []
    for ch in range(2):
        room.append(lowpass(noise(d, "brown", seed=61 + ch), 220) * _lfo_k(2, 0.8, 1.0, phase=0.4 * ch))
    room = np.stack(room, axis=1) * 0.6
    hum = (sine(note("D2") * 0.98, d) * 0.5 + sine(note("D3") * 0.98, d) * 0.2 + sine(note("A3") * 0.98, d) * 0.08)
    hum = to_stereo(hum * _lfo_k(1, 0.6, 1.0)) * 0.25
    beds = [(room, 0, -2), (hum, 0, -15)]
    events = []
    # relógio de parede: tique (mais agudo) e taque alternados a cada 1 s — pulso lento e constante do cômodo
    for k in range(int(LOOP)):
        f = 2600 if k % 2 == 0 else 2100
        tick = bandpass(noise(0.03, "white", seed=900 + k), f * 0.8, f * 1.25) * decay(0.03, 0.006, 0.001)
        tick = tick + sine(f * 0.5, 0.03) * decay(0.03, 0.008) * 0.3
        events.append((pan(tick, 0.35), float(k) + 0.25, -8))

    def creak(i: int, r: np.random.Generator) -> np.ndarray:       # rangido de madeira/móvel ao longe
        dur = float(r.uniform(0.5, 0.9))
        f = sweep(float(r.uniform(140, 200)), float(r.uniform(110, 260)), dur)
        x = fm(f, dur, ratio=1.41, index=env([(0, 3.5), (dur, 1.0)], dur))
        x = bandpass(x * tremolo(np.ones(ns(dur)), float(r.uniform(18, 30)), 0.7), 150, 1400)
        return x * env([(0, 0), (0.1, 1), (dur, 0)], dur)

    _place(events, rng, 4, creak, (-14, -9), span=(1.0, LOOP - 1.0))
    return _finish(beds, events, 0.35, 0.6, 0.12)


WORLDS = {"luna": luna, "ares": ares, "kronos": kronos, "titan": titan}

if __name__ == "__main__":
    out = "assets/audio/ambience/" if "--export" in sys.argv else "audio/previews/"
    # caminhos literais (o pre-commit liga cada asset ao script-fonte):
    # assets/audio/ambience/luna.wav assets/audio/ambience/ares.wav assets/audio/ambience/kronos.wav
    # assets/audio/ambience/titan.wav
    names = [a for a in sys.argv[1:] if a in WORLDS] or list(WORLDS)
    for name in names:
        save_wav(f"{out}{name}.wav", WORLDS[name](), "ambience", loop=True)
