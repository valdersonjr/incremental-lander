"""
soundkit.py - sintetizador "retro-synth espacial" em codigo. Todo som do jogo nasce aqui.

Uso tipico (dentro de um script gerador em audio/src/...):

    import sys; sys.path.insert(0, ".claude/skills/sound-design/scripts")
    from soundkit import *

    body = pulse(sweep(note("A5"), note("D6"), 0.12), 0.12, duty=0.25) * decay(0.12, 0.05)
    click = noise(0.01, seed=1) * decay(0.01, 0.003)
    x = mix([(click, 0, -12), (body, 0.0, 0)])
    rep = save_wav("assets/audio/ui/click.wav", x, kind="ui")   # normaliza, valida, gera grafico
    play("assets/audio/ui/click.wav")                            # toca no Mac (afplay)

Convencoes:
  * Sinal mono = np.ndarray 1D float em [-1, 1]; estereo = shape (N, 2).
  * Tempo em segundos, frequencia em Hz, ganho em dB.
  * Tudo deterministico: ruido e aleatoriedade sempre com `seed`.
"""
from __future__ import annotations

import math
import os
import re
import struct
import subprocess
import sys
from dataclasses import dataclass, field
from typing import Callable, Iterable, Sequence

import numpy as np

try:
    from scipy import signal as sps
except ImportError:  # pragma: no cover
    sys.exit("scipy nao instalado: pip install scipy")

SR = 44100

# ---------------------------------------------------------------------------
# Travas do projeto (espelham references/style-guide.md)
# ---------------------------------------------------------------------------
KEY = "D"
# D pentatonica maior (= B pentatonica menor): consonante com D lidio, D maior e B menor.
SFX_SCALE = [0, 2, 4, 7, 9]
MODES = {
    "major":      [0, 2, 4, 5, 7, 9, 11],
    "lydian":     [0, 2, 4, 6, 7, 9, 11],
    "dorian":     [0, 2, 3, 5, 7, 9, 10],
    "minor":      [0, 2, 3, 5, 7, 8, 10],
    "mixolydian": [0, 2, 4, 5, 7, 9, 10],
    "pent_major": [0, 2, 4, 7, 9],
    "pent_minor": [0, 3, 5, 7, 10],
}
# Alvos de loudness (LUFS) e teto de pico (dBTP) por categoria.
LOUDNESS_TARGETS = {
    "ui":        {"lufs": -20.0, "peak": -1.0, "max_dur": 0.35},
    "sfx":       {"lufs": -16.0, "peak": -1.0, "max_dur": 2.0},
    "impact":    {"lufs": -12.0, "peak": -1.0, "max_dur": 3.0},
    "loop":      {"lufs": -18.0, "peak": -1.0, "max_dur": None},
    "ambience":  {"lufs": -24.0, "peak": -3.0, "max_dur": None},
    "music":     {"lufs": -18.0, "peak": -1.0, "max_dur": None},
    "jingle":    {"lufs": -16.0, "peak": -1.0, "max_dur": 4.0},
}

NOTE_NAMES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
_FLATS = {"Db": "C#", "Eb": "D#", "Gb": "F#", "Ab": "G#", "Bb": "A#"}


# ---------------------------------------------------------------------------
# Notas, escalas
# ---------------------------------------------------------------------------
def midi(name: str) -> int:
    """'A4' -> 69, 'F#5' -> 78, 'Bb3' -> 58."""
    m = re.fullmatch(r"([A-Ga-g])([#b]?)(-?\d)", name.strip())
    if not m:
        raise ValueError(f"nota invalida: {name!r}")
    n = m.group(1).upper() + m.group(2)
    n = _FLATS.get(n, n)
    return NOTE_NAMES.index(n) + 12 * (int(m.group(3)) + 1)


def mtof(m: float) -> float:
    return 440.0 * 2 ** ((m - 69) / 12)


def ftom(f: float) -> float:
    return 69 + 12 * math.log2(f / 440.0)


def note(name: str) -> float:
    """Frequencia de uma nota: note('D4') -> 293.66."""
    return mtof(midi(name))


def scale_midis(mode: str = "pent_major", key: str = KEY, lo: str = "C2", hi: str = "C8") -> list[int]:
    root = NOTE_NAMES.index(_FLATS.get(key, key))
    steps = SFX_SCALE if mode == "sfx" else MODES[mode]
    return [m for m in range(midi(lo), midi(hi) + 1) if (m - root) % 12 in steps]


def snap(freq: float, mode: str = "sfx", key: str = KEY) -> float:
    """Quantiza uma frequencia para a nota mais proxima da escala do projeto (padrao: SFX_SCALE)."""
    m = ftom(freq)
    cands = scale_midis(mode, key)
    return mtof(min(cands, key=lambda c: abs(c - m)))


def degree(d: int, octave: int = 4, mode: str = "lydian", key: str = KEY) -> float:
    """Grau da escala (1 = tonica). degree(5, 4) em D lidio -> A4. Graus > 7 sobem de oitava."""
    steps = MODES[mode]
    root = midi(f"{key}{octave}")
    d0 = d - 1
    return mtof(root + steps[d0 % len(steps)] + 12 * (d0 // len(steps)))


def chord(root: str, kind: str = "maj") -> list[float]:
    ivs = {"maj": [0, 4, 7], "min": [0, 3, 7], "sus2": [0, 2, 7], "sus4": [0, 5, 7], "maj7": [0, 4, 7, 11],
           "min7": [0, 3, 7, 10], "add9": [0, 4, 7, 14], "5": [0, 7], "dim": [0, 3, 6]}[kind]
    r = midi(root)
    return [mtof(r + i) for i in ivs]


# ---------------------------------------------------------------------------
# Utilidades de tempo / conversao
# ---------------------------------------------------------------------------
def ns(dur: float) -> int:
    return max(1, int(round(dur * SR)))


def t_axis(dur: float) -> np.ndarray:
    return np.arange(ns(dur)) / SR


def db_to_lin(db: float) -> float:
    return 10 ** (db / 20)


def lin_to_db(x: float) -> float:
    return 20 * math.log10(max(x, 1e-12))


def _as_array(v, n: int) -> np.ndarray:
    """Escalar -> array constante; array de outro tamanho -> reamostrado (interp linear)."""
    a = np.asarray(v, dtype=float)
    if a.ndim == 0:
        return np.full(n, float(a))
    if len(a) == n:
        return a
    return np.interp(np.linspace(0, 1, n), np.linspace(0, 1, len(a)), a)


def silence(dur: float, stereo: bool = False) -> np.ndarray:
    return np.zeros((ns(dur), 2)) if stereo else np.zeros(ns(dur))


# ---------------------------------------------------------------------------
# Envelopes e curvas de controle
# ---------------------------------------------------------------------------
def env(points: Sequence[tuple[float, float]], dur: float | None = None, curve: str = "lin") -> np.ndarray:
    """Envelope por pontos [(t, valor), ...]. curve='exp' interpola em escala log (bom para
    frequencia/volume). dur padrao = ultimo t."""
    dur = dur if dur is not None else points[-1][0]
    t = t_axis(dur)
    ts = np.array([p[0] for p in points])
    vs = np.array([p[1] for p in points], dtype=float)
    if curve == "exp":
        return np.exp(np.interp(t, ts, np.log(np.maximum(vs, 1e-6))))
    return np.interp(t, ts, vs)


def adsr(dur: float, a: float = 0.005, d: float = 0.08, s: float = 0.6, r: float = 0.1) -> np.ndarray:
    """ADSR com duracao TOTAL `dur` (o release acontece dentro dela)."""
    n = ns(dur)
    a_n, d_n, r_n = ns(a), ns(d), ns(r)
    s_n = max(0, n - a_n - d_n - r_n)
    e = np.concatenate([
        np.linspace(0, 1, a_n, endpoint=False),
        1 - (1 - s) * (1 - np.exp(-5 * np.linspace(0, 1, d_n))) / (1 - math.exp(-5)),
        np.full(s_n, s),
        s * np.exp(-5 * np.linspace(0, 1, r_n)) * np.linspace(1, 0, r_n),
    ])
    return _as_array(e, n) if len(e) != n else e


def decay(dur: float, tau: float = 0.1, attack: float = 0.002) -> np.ndarray:
    """Ataque curtissimo (anti-clique) + decaimento exponencial com constante `tau` (s).
    Termina em zero exato."""
    t = t_axis(dur)
    e = np.exp(-t / max(tau, 1e-4))
    if attack > 0:
        e *= np.clip(t / attack, 0, 1)
    fade = min(ns(0.004), len(e))
    e[-fade:] *= np.linspace(1, 0, fade)
    return e


def punch(dur: float, amount: float = 0.5, tau: float = 0.03) -> np.ndarray:
    """Reforco no inicio (o 'sustain punch' do sfxr): multiplicador 1+amount que decai."""
    return 1 + amount * np.exp(-t_axis(dur) / tau)


def sweep(f0: float, f1: float, dur: float, curve: str = "exp") -> np.ndarray:
    """Curva de frequencia de f0 a f1 (exp soa natural para pitch)."""
    return env([(0, f0), (dur, f1)], dur, curve)


def vibrato(freq, dur: float, rate: float = 6.0, depth_semi: float = 0.2, delay: float = 0.0) -> np.ndarray:
    n = ns(dur)
    f = _as_array(freq, n)
    t = t_axis(dur)
    amt = np.clip((t - delay) / 0.05, 0, 1) if delay > 0 else 1.0
    return f * 2 ** (depth_semi * amt * np.sin(2 * np.pi * rate * t) / 12)


def arp(freqs: Sequence[float], step: float, dur: float) -> np.ndarray:
    """Arpejo: alterna entre as frequencias a cada `step` segundos (acorde de chip)."""
    n = ns(dur)
    idx = (np.arange(n) // max(1, ns(step))) % len(freqs)
    return np.asarray(freqs, float)[idx]


def lfo(dur: float, rate: float, lo: float = 0.0, hi: float = 1.0, shape: str = "sine", phase: float = 0.0,
        seed: int = 0) -> np.ndarray:
    """Sinal de controle lento. shape: sine | tri | square | random (suave, sample&hold interpolado)."""
    t = t_axis(dur)
    if shape == "sine":
        u = 0.5 + 0.5 * np.sin(2 * np.pi * (rate * t + phase))
    elif shape == "tri":
        u = 1 - np.abs(((rate * t + phase) % 1) * 2 - 1)
    elif shape == "square":
        u = (((rate * t + phase) % 1) < 0.5).astype(float)
    elif shape == "random":
        rng = np.random.default_rng(seed)
        k = int(dur * rate) + 3
        pts = rng.random(k)
        u = np.interp(t * rate, np.arange(k), pts)
        u = 0.5 - 0.5 * np.cos(np.pi * u)  # suaviza
    else:
        raise ValueError(shape)
    return lo + (hi - lo) * u


# ---------------------------------------------------------------------------
# Osciladores (paleta de timbres)
# ---------------------------------------------------------------------------
def _phase(freq, n: int) -> np.ndarray:
    f = _as_array(freq, n)
    ph = np.cumsum(f) / SR
    return np.concatenate([[0.0], ph[:-1]]) % 1.0, f / SR


def _polyblep(t: np.ndarray, dt: np.ndarray) -> np.ndarray:
    out = np.zeros_like(t)
    m = t < dt
    x = t[m] / dt[m]
    out[m] = x + x - x * x - 1
    m2 = t > 1 - dt
    x = (t[m2] - 1) / dt[m2]
    out[m2] = x * x + x + x + 1
    return out


def sine(freq, dur: float, phase0: float = 0.0) -> np.ndarray:
    ph, _ = _phase(freq, ns(dur))
    return np.sin(2 * np.pi * (ph + phase0))


def triangle(freq, dur: float, steps: int | None = None) -> np.ndarray:
    """Triangular. steps=16 imita o triangulo quantizado do NES (mais 'chip')."""
    ph, _ = _phase(freq, ns(dur))
    x = 1 - 4 * np.abs(ph - 0.5)
    if steps:
        x = np.round((x + 1) / 2 * (steps - 1)) / (steps - 1) * 2 - 1
    return x


def saw(freq, dur: float, aa: bool = True) -> np.ndarray:
    ph, dt = _phase(freq, ns(dur))
    x = 2 * ph - 1
    return x - _polyblep(ph, dt) if aa else x


def pulse(freq, dur: float, duty=0.5, aa: bool = True) -> np.ndarray:
    """Onda de pulso. duty 0.5 = quadrada (oca), 0.25 = mais fina (classico NES), 0.125 = nasal.
    duty pode ser array (duty sweep)."""
    n = ns(dur)
    ph, dt = _phase(freq, n)
    d = _as_array(duty, n)
    x = np.where(ph < d, 1.0, -1.0)
    if aa:
        x = x + _polyblep(ph, dt) - _polyblep((ph - d) % 1.0, dt)
    return x - (2 * d - 1)  # remove DC do duty


def square(freq, dur: float, aa: bool = True) -> np.ndarray:
    return pulse(freq, dur, 0.5, aa)


def noise(dur: float, color: str = "white", seed: int = 0) -> np.ndarray:
    """Ruido: white (chiado), pink (natural, vento), brown (grave, ronco/motor)."""
    rng = np.random.default_rng(seed)
    w = rng.uniform(-1, 1, ns(dur))
    if color == "white":
        return w
    if color == "pink":
        b = [0.049922035, -0.095993537, 0.050612699, -0.004408786]
        a = [1, -2.494956002, 2.017265875, -0.522189400]
        x = sps.lfilter(b, a, w)
    elif color == "brown":
        x = sps.lfilter([1.0], [1.0, -0.997], w)
        x = sps.lfilter([1, -1], [1, -0.995], x)  # tira DC
    else:
        raise ValueError(color)
    return x / (np.max(np.abs(x)) + 1e-12)


def chip_noise(freq, dur: float, short: bool = False, seed: int = 1) -> np.ndarray:
    """Ruido de chip com 'altura' (LFSR de 15 bits como no NES). freq alto = chiado fino,
    baixo = crocante. short=True = modo metalico/tonal (periodo 93)."""
    n = ns(dur)
    f = _as_array(freq, n)
    idx = np.floor(np.cumsum(f) / SR * 2).astype(np.int64)  # 2 valores por ciclo
    count = int(idx[-1]) + 1
    reg = (seed & 0x7FFF) or 1
    tap = 6 if short else 1
    bits = np.empty(count, dtype=float)
    for i in range(count):
        fb = (reg & 1) ^ ((reg >> tap) & 1)
        reg = (reg >> 1) | (fb << 14)
        bits[i] = 1.0 if reg & 1 else -1.0
    return bits[idx]


def fm(freq, dur: float, ratio: float = 2.0, index=2.0, feedback: float = 0.0) -> np.ndarray:
    """FM de 2 operadores (sinos, metal, baixo 'DX'). index pode ser envelope (brilho que decai)."""
    n = ns(dur)
    f = _as_array(freq, n)
    ph_c, _ = _phase(f, n)
    ph_m, _ = _phase(f * ratio, n)
    idx = _as_array(index, n)
    mod = np.sin(2 * np.pi * ph_m)
    if feedback:
        mod = np.sin(2 * np.pi * ph_m + feedback * mod)
    return np.sin(2 * np.pi * ph_c + idx * mod)


def unison(osc: Callable, freq, dur: float, voices: int = 3, detune_cents: float = 12.0, stereo: bool = False,
           **kw) -> np.ndarray:
    """Varias vozes levemente desafinadas (pads largos, 'supersaw')."""
    n = ns(dur)
    f = _as_array(freq, n)
    outs = []
    for v in range(voices):
        c = 0 if voices == 1 else (v / (voices - 1) - 0.5) * 2 * detune_cents
        outs.append(osc(f * 2 ** (c / 1200), dur, **kw))
    if not stereo:
        return np.sum(outs, axis=0) / math.sqrt(voices)
    L = sum(o * (1 - v / max(1, voices - 1)) for v, o in enumerate(outs))
    R = sum(o * (v / max(1, voices - 1)) for v, o in enumerate(outs))
    return np.stack([L, R], axis=1) / math.sqrt(voices) * 1.4


# ---------------------------------------------------------------------------
# Filtros
# ---------------------------------------------------------------------------
def lowpass(x: np.ndarray, fc: float, order: int = 2) -> np.ndarray:
    sos = sps.butter(order, min(fc, SR * 0.45), "low", fs=SR, output="sos")
    return sps.sosfilt(sos, x, axis=0)


def highpass(x: np.ndarray, fc: float, order: int = 2) -> np.ndarray:
    sos = sps.butter(order, max(fc, 5), "high", fs=SR, output="sos")
    return sps.sosfilt(sos, x, axis=0)


def bandpass(x: np.ndarray, lo: float, hi: float, order: int = 2) -> np.ndarray:
    sos = sps.butter(order, [max(lo, 5), min(hi, SR * 0.45)], "band", fs=SR, output="sos")
    return sps.sosfilt(sos, x, axis=0)


def svf(x: np.ndarray, cutoff, q: float = 0.707, mode: str = "lp") -> np.ndarray:
    """Filtro de estado variavel com cutoff VARIAVEL no tempo (sweeps de filtro, 'wah', motor).
    mode: lp | hp | bp | notch. q alto = ressonante (0.5..10)."""
    if x.ndim == 2:
        return np.stack([svf(x[:, c], cutoff, q, mode) for c in range(2)], axis=1)
    n = len(x)
    fc = np.clip(_as_array(cutoff, n), 10, SR * 0.45)
    g = np.tan(np.pi * fc / SR)
    k = 1.0 / q
    a1 = 1.0 / (1.0 + g * (g + k))
    a2 = g * a1
    a3 = g * a2
    out = np.empty(n)
    ic1 = ic2 = 0.0
    xs = x.tolist()
    a1l, a2l, a3l = a1.tolist(), a2.tolist(), a3.tolist()
    m = {"lp": 0, "hp": 1, "bp": 2, "notch": 3}[mode]
    for i in range(n):
        v0 = xs[i]
        v3 = v0 - ic2
        v1 = a1l[i] * ic1 + a2l[i] * v3
        v2 = ic2 + a2l[i] * ic1 + a3l[i] * v3
        ic1 = 2 * v1 - ic1
        ic2 = 2 * v2 - ic2
        if m == 0:
            out[i] = v2
        elif m == 1:
            out[i] = v0 - k * v1 - v2
        elif m == 2:
            out[i] = v1
        else:
            out[i] = v0 - k * v1
    return out


# ---------------------------------------------------------------------------
# Efeitos
# ---------------------------------------------------------------------------
def gain(x: np.ndarray, db: float) -> np.ndarray:
    return x * db_to_lin(db)


def drive(x: np.ndarray, amount: float = 2.0) -> np.ndarray:
    """Saturacao suave (tanh). amount 1..10."""
    return np.tanh(x * amount) / math.tanh(amount)


def bitcrush(x: np.ndarray, bits: int = 6) -> np.ndarray:
    q = 2 ** (bits - 1)
    return np.round(x * q) / q


def decimate(x: np.ndarray, factor: int = 4) -> np.ndarray:
    """Reduz a taxa de amostragem 'na marra' (sample & hold) - grao lo-fi/chip."""
    idx = (np.arange(len(x)) // factor) * factor
    return x[idx]


def fade(x: np.ndarray, fade_in: float = 0.002, fade_out: float = 0.005) -> np.ndarray:
    y = x.copy()
    a, b = min(ns(fade_in), len(y)), min(ns(fade_out), len(y))
    ramp_in = np.linspace(0, 1, a)
    ramp_out = np.linspace(1, 0, b)
    if y.ndim == 2:
        ramp_in, ramp_out = ramp_in[:, None], ramp_out[:, None]
    if fade_in > 0:
        y[:a] *= ramp_in
    if fade_out > 0:
        y[-b:] *= ramp_out
    return y


def tremolo(x: np.ndarray, rate: float = 6.0, depth: float = 0.5) -> np.ndarray:
    m = 1 - depth * (0.5 + 0.5 * np.sin(2 * np.pi * rate * np.arange(len(x)) / SR))
    return x * (m[:, None] if x.ndim == 2 else m)


def pitch_shift(x: np.ndarray, semitones: float) -> np.ndarray:
    """Varispeed (muda pitch E duracao, como girar a fita). Bom para variacoes."""
    r = 2 ** (semitones / 12)
    n = max(1, int(len(x) / r))
    src = np.arange(n) * r
    if x.ndim == 2:
        return np.stack([np.interp(src, np.arange(len(x)), x[:, c]) for c in range(2)], axis=1)
    return np.interp(src, np.arange(len(x)), x)


def pan(x: np.ndarray, pos: float = 0.0) -> np.ndarray:
    """Mono -> estereo com pan de potencia constante (-1 esquerda, +1 direita)."""
    a = (pos + 1) * np.pi / 4
    return np.stack([x * math.cos(a), x * math.sin(a)], axis=1) * math.sqrt(2)


def to_mono(x: np.ndarray) -> np.ndarray:
    return x.mean(axis=1) if x.ndim == 2 else x


def to_stereo(x: np.ndarray) -> np.ndarray:
    return x if x.ndim == 2 else np.stack([x, x], axis=1)


def delay(x: np.ndarray, time: float = 0.25, feedback: float = 0.35, mix_: float = 0.3, tail: float | None = None,
          damp: float = 0.3, pingpong: bool = False) -> np.ndarray:
    """Eco. tail = segundos extras para o eco morrer (padrao: automatico). damp escurece as repeticoes.
    pingpong=True devolve estereo alternando L/R."""
    if tail is None:
        tail = time * math.log(0.001) / math.log(max(feedback, 1e-3))
        tail = min(tail, 4.0)
    dry = to_mono(x)
    n = len(dry) + ns(tail)
    d = ns(time)
    buf = np.zeros(n)
    buf[:len(dry)] = dry
    wetL, wetR = np.zeros(n), np.zeros(n)
    tap = buf.copy()
    k = 1
    while True:
        shifted = np.zeros(n)
        if k * d >= n:
            break
        shifted[k * d:] = tap[: n - k * d]
        tap_gain = feedback ** (k - 1)
        if tap_gain < 1e-3:
            break
        rep = shifted * tap_gain
        if damp > 0:
            rep = lowpass(rep, 12000 * (1 - damp) ** k + 300) if len(rep) > 12 else rep
        if pingpong and k % 2 == 0:
            wetR += rep
        else:
            wetL += rep
            if not pingpong:
                wetR += rep
        k += 1
    out_dry = np.zeros((n, 2))
    xs = to_stereo(x)
    out_dry[: len(xs)] = xs
    wet = np.stack([wetL, wetR], axis=1)
    y = out_dry * (1 - mix_ * 0.5) + wet * mix_
    return y if (pingpong or x.ndim == 2) else y[:, 0]


def _comb(x: np.ndarray, m: int, fb: float, damp: float) -> np.ndarray:
    n = len(x)
    y = np.zeros(n)
    zi = np.zeros(1)
    prev = np.zeros(m)
    for s in range(0, n, m):
        blk = x[s:s + m]
        lp, zi = sps.lfilter([1 - damp], [1, -damp], prev[: len(blk)], zi=zi)
        yb = blk + fb * lp
        y[s:s + len(blk)] = yb
        prev = np.zeros(m)
        prev[: len(yb)] = yb
    return y


def _allpass(x: np.ndarray, m: int, g: float = 0.5) -> np.ndarray:
    n = len(x)
    y = np.zeros(n)
    xp = np.zeros(m)
    yp = np.zeros(m)
    for s in range(0, n, m):
        blk = x[s:s + m]
        L = len(blk)
        yb = -g * blk + xp[:L] + g * yp[:L]
        y[s:s + L] = yb
        xp = np.zeros(m); xp[:L] = blk
        yp = np.zeros(m); yp[:L] = yb
    return y


def reverb(x: np.ndarray, size: float = 0.6, damp: float = 0.4, mix_: float = 0.25, tail: float | None = None,
           stereo: bool = True, predelay: float = 0.01) -> np.ndarray:
    """Reverb estilo Freeverb (8 combs + 4 allpass por canal). size 0..1 (sala -> catedral/espaco).
    Retorna estereo por padrao (largura espacial). Para SFX mono, prefira mix_ baixo ou reverb no Godot."""
    tail = tail if tail is not None else 0.5 + 3.0 * size
    dry = to_mono(x)
    n = len(dry) + ns(tail)
    src = np.zeros(n)
    pd = ns(predelay)
    src[pd: pd + len(dry)] = dry[: n - pd]
    fb = 0.7 + 0.28 * size
    combs = [1116, 1188, 1277, 1356, 1422, 1491, 1557, 1617]
    aps = [556, 441, 341, 225]
    scale = SR / 44100
    chans = []
    for spread in ((0, 23) if stereo else (0,)):
        acc = np.zeros(n)
        for c in combs:
            acc += _comb(src * 0.015, int((c + spread) * scale), fb, damp)
        for a in aps:
            acc = _allpass(acc, int((a + spread) * scale))
        chans.append(acc)
    wet = np.stack(chans, axis=1) if stereo else chans[0]
    xs = np.zeros((n, 2)) if stereo else np.zeros(n)
    xs[: len(x)] = to_stereo(x) if stereo else to_mono(x)
    wet = wet / (np.max(np.abs(wet)) + 1e-12) * (np.max(np.abs(x)) + 1e-12)
    return xs * (1 - mix_) + wet * mix_


# ---------------------------------------------------------------------------
# Mixagem e montagem
# ---------------------------------------------------------------------------
def mix(layers: Iterable, dur: float | None = None) -> np.ndarray:
    """Mixa camadas. Cada item: sinal | (sinal, inicio_s) | (sinal, inicio_s, ganho_db).
    Se alguma camada for estereo, o resultado e estereo."""
    items = []
    for it in layers:
        if isinstance(it, np.ndarray):
            items.append((it, 0.0, 0.0))
        elif len(it) == 2:
            items.append((it[0], it[1], 0.0))
        else:
            items.append(tuple(it))
    stereo = any(s.ndim == 2 for s, _, _ in items)
    end = max(ns(t0) + len(s) for s, t0, _ in items)
    n = ns(dur) if dur else end
    out = np.zeros((n, 2)) if stereo else np.zeros(n)
    for s, t0, g in items:
        s = to_stereo(s) if stereo else s
        a = ns(t0) if t0 > 0 else 0
        if a >= n:
            continue
        L = min(len(s), n - a)
        out[a:a + L] += s[:L] * db_to_lin(g)
    return out


def concat(*sigs: np.ndarray, gap: float = 0.0) -> np.ndarray:
    stereo = any(s.ndim == 2 for s in sigs)
    parts = []
    for i, s in enumerate(sigs):
        parts.append(to_stereo(s) if stereo else s)
        if gap and i < len(sigs) - 1:
            parts.append(silence(gap, stereo))
    return np.concatenate(parts, axis=0)


def trim(x: np.ndarray, threshold_db: float = -60.0, keep_start: bool = True) -> np.ndarray:
    """Remove silencio do fim (e do inicio se keep_start=False) e aplica micro-fade no fim."""
    a = np.abs(to_mono(x))
    thr = db_to_lin(threshold_db)
    idx = np.where(a > thr)[0]
    if len(idx) == 0:
        return x[:1]
    s = 0 if keep_start else idx[0]
    e = min(len(x), idx[-1] + ns(0.005))
    return fade(x[s:e], 0 if keep_start else 0.001, 0.005)


def normalize_peak(x: np.ndarray, db: float = -1.0) -> np.ndarray:
    p = np.max(np.abs(x))
    return x if p == 0 else x / p * db_to_lin(db)


def limit(x: np.ndarray, ceiling_db: float = -1.0) -> np.ndarray:
    """Limitador suave: comprime apenas os picos acima do teto (preserva o corpo)."""
    c = db_to_lin(ceiling_db)
    a = np.abs(x)
    over = a > c * 0.8
    if not over.any():
        return x
    knee = c * 0.8
    y = x.copy()
    y[over] = np.sign(x[over]) * (knee + (c - knee) * np.tanh((a[over] - knee) / (c - knee)))
    return y


# ---------------------------------------------------------------------------
# Loops
# ---------------------------------------------------------------------------
def make_loop(x: np.ndarray, loop_dur: float, crossfade: float = 0.08) -> np.ndarray:
    """Transforma um sinal (com pelo menos loop_dur + crossfade de duracao) num loop perfeito:
    o trecho apos o fim e mixado em crossfade de potencia constante sobre o inicio."""
    L, cf = ns(loop_dur), ns(crossfade)
    if len(x) < L + cf:
        raise ValueError(f"sinal curto demais: precisa de {(L + cf) / SR:.2f}s, tem {len(x) / SR:.2f}s")
    y = x[:L].copy()
    t = np.linspace(0, np.pi / 2, cf)
    fin, fout = np.sin(t), np.cos(t)
    if x.ndim == 2:
        fin, fout = fin[:, None], fout[:, None]
    y[:cf] = x[:cf] * fin + x[L:L + cf] * fout
    return y


def wrap_tail(x: np.ndarray, loop_dur: float) -> np.ndarray:
    """Dobra tudo que passa de loop_dur (caudas de reverb/eco/notas) de volta sobre o inicio.
    Resultado: loop sem corte de cauda (use em musica e ambiencias renderizadas com cauda)."""
    L = ns(loop_dur)
    y = x[:L].copy()
    rest = x[L:]
    while len(rest):
        k = min(L, len(rest))
        y[:k] += rest[:k]
        rest = rest[k:]
    return y


# ---------------------------------------------------------------------------
# Medicao / analise (os "ouvidos" do Claude)
# ---------------------------------------------------------------------------
def _biquad_highshelf(fs, G=3.99984385397, Q=0.7071752369554193, fc=1681.9744509555319):
    A = 10 ** (G / 40)
    w0 = 2 * np.pi * fc / fs
    al = np.sin(w0) / (2 * Q)
    cw = np.cos(w0)
    sA = np.sqrt(A)
    b = [A * ((A + 1) + (A - 1) * cw + 2 * sA * al), -2 * A * ((A - 1) + (A + 1) * cw),
         A * ((A + 1) + (A - 1) * cw - 2 * sA * al)]
    a = [(A + 1) - (A - 1) * cw + 2 * sA * al, 2 * ((A - 1) - (A + 1) * cw), (A + 1) - (A - 1) * cw - 2 * sA * al]
    return np.array(b) / a[0], np.array(a) / a[0]


def _biquad_highpass(fs, Q=0.5003270373253953, fc=38.13547087613982):
    w0 = 2 * np.pi * fc / fs
    al = np.sin(w0) / (2 * Q)
    cw = np.cos(w0)
    b = [(1 + cw) / 2, -(1 + cw), (1 + cw) / 2]
    a = [1 + al, -2 * cw, 1 - al]
    return np.array(b) / a[0], np.array(a) / a[0]


def lufs(x: np.ndarray) -> tuple[float, bool]:
    """Loudness integrado ITU-R BS.1770-4 (K-weighting + gating). Para sons < 0.4 s usa media
    sem gating (retorna approx=True)."""
    xs = to_stereo(x) if x.ndim == 1 else x
    b1, a1 = _biquad_highshelf(SR)
    b2, a2 = _biquad_highpass(SR)
    k = sps.lfilter(b2, a2, sps.lfilter(b1, a1, xs, axis=0), axis=0)
    if x.ndim == 1:
        k = k[:, :1]  # mono: um canal so
    n = len(k)
    blk, hop = ns(0.4), ns(0.1)
    if n < blk:
        z = np.mean(k ** 2, axis=0).sum()
        return (-0.691 + 10 * math.log10(max(z, 1e-12)), True)
    zs = np.array([np.mean(k[s:s + blk] ** 2, axis=0).sum() for s in range(0, n - blk + 1, hop)])
    lk = -0.691 + 10 * np.log10(np.maximum(zs, 1e-12))
    g1 = zs[lk > -70]
    if len(g1) == 0:
        return (-70.0, False)
    rel = -0.691 + 10 * math.log10(g1.mean()) - 10
    g2 = zs[(lk > -70) & (lk > rel)]
    return (-0.691 + 10 * math.log10(max(g2.mean(), 1e-12)), False)


def true_peak_db(x: np.ndarray) -> float:
    up = sps.resample_poly(x, 4, 1, axis=0)
    return lin_to_db(float(np.max(np.abs(up))))


def band_energy(x: np.ndarray) -> dict[str, float]:
    """Distribuicao de energia por faixa (% do total): ajuda a 'ouvir' o timbre pelo numero."""
    m = to_mono(x)
    spec = np.abs(np.fft.rfft(m * np.hanning(len(m)))) ** 2 if len(m) > 1 else np.zeros(1)
    freqs = np.fft.rfftfreq(len(m), 1 / SR)
    bands = {"sub<60": (0, 60), "grave60-250": (60, 250), "medio-grave250-800": (250, 800),
             "medio0.8-3k": (800, 3000), "agudo3-8k": (3000, 8000), "brilho>8k": (8000, SR / 2)}
    tot = spec.sum() + 1e-12
    return {k: round(float(100 * spec[(freqs >= lo) & (freqs < hi)].sum() / tot), 1) for k, (lo, hi) in bands.items()}


def analyze(x: np.ndarray, kind: str | None = None, loop: bool = False) -> dict:
    """Relatorio objetivo do som + avisos contra os alvos da categoria `kind`."""
    m = to_mono(x)
    a = np.abs(m)
    peak = float(np.max(np.abs(x))) if len(x) else 0.0
    L, approx = lufs(x)
    thr = db_to_lin(-50)
    above = np.where(a > thr)[0]
    lead_ms = (above[0] / SR * 1000) if len(above) else None
    spec = np.abs(np.fft.rfft(m)) if len(m) > 1 else np.zeros(1)
    freqs = np.fft.rfftfreq(len(m), 1 / SR)
    centroid = float((spec * freqs).sum() / (spec.sum() + 1e-12))
    rep = {
        "dur_s": round(len(x) / SR, 3),
        "channels": 2 if x.ndim == 2 else 1,
        "lufs": round(L, 1), "lufs_approx": approx,
        "peak_db": round(lin_to_db(peak), 2),
        "true_peak_db": round(true_peak_db(x), 2),
        "rms_db": round(lin_to_db(float(np.sqrt(np.mean(m ** 2)))), 1),
        "crest_db": round(lin_to_db(peak) - lin_to_db(float(np.sqrt(np.mean(m ** 2))) + 1e-12), 1),
        "dc_offset": round(float(np.mean(m)), 4),
        "clipped_samples": int(np.sum(np.abs(x) >= 0.999)),
        "leading_silence_ms": None if lead_ms is None else round(lead_ms, 1),
        "end_level_db": round(lin_to_db(float(np.max(a[-ns(0.0003):]))), 1),  # ultimas ~13 amostras
        "centroid_hz": round(centroid),
        "bands_pct": band_energy(x),
    }
    w = []
    if rep["clipped_samples"]:
        w.append(f"CLIPPING: {rep['clipped_samples']} amostras no teto")
    if abs(rep["dc_offset"]) > 0.01:
        w.append(f"DC offset {rep['dc_offset']} (use highpass(x, 20))")
    if lead_ms is not None and lead_ms > 10 and not loop and kind not in ("ambience", "music"):
        w.append(f"{lead_ms:.0f} ms de silencio no inicio (SFX deve responder imediato)")
    if not loop and rep["end_level_db"] > -50:
        w.append(f"termina em {rep['end_level_db']} dB: corte abrupto/clique no fim (use fade/trim)")
    if loop:
        seam = abs(float(m[-1]) - float(m[0]))
        rep["loop_seam_jump"] = round(seam, 4)
        win = min(ns(0.15), len(m) // 4)  # janela longa: ruido grave oscila muito em janelas curtas
        e1 = float(np.sqrt(np.mean(m[-win:] ** 2)))
        e0 = float(np.sqrt(np.mean(m[:win] ** 2)))
        rep["loop_energy_jump_db"] = round(abs(lin_to_db(e1 + 1e-9) - lin_to_db(e0 + 1e-9)), 1)
        if seam > 0.05:
            w.append(f"emenda do loop com salto de {seam:.3f} (clique provavel)")
        if rep["loop_energy_jump_db"] > 3:
            w.append(f"energia muda {rep['loop_energy_jump_db']} dB na emenda (loop perceptivel)")
    if kind:
        t = LOUDNESS_TARGETS[kind]
        if abs(L - t["lufs"]) > 2:
            w.append(f"loudness {L:.1f} LUFS fora do alvo {t['lufs']} (+-2) para '{kind}'")
        if rep["true_peak_db"] > t["peak"] + 0.1:
            w.append(f"true peak {rep['true_peak_db']} dB acima do teto {t['peak']}")
        if t["max_dur"] and rep["dur_s"] > t["max_dur"]:
            w.append(f"duracao {rep['dur_s']}s acima do maximo {t['max_dur']}s para '{kind}'")
    rep["warnings"] = w
    return rep


def normalize(x: np.ndarray, kind: str) -> np.ndarray:
    """Leva ao alvo de loudness da categoria e garante o teto de pico (limitador suave)."""
    t = LOUDNESS_TARGETS[kind]
    x = highpass(x, 18, order=1)  # remove DC/subsonico
    for _ in range(3):
        L, _ = lufs(x)
        x = x * db_to_lin(t["lufs"] - L)
        x = limit(x, t["peak"] - 0.3)
    tp = true_peak_db(x)  # picos entre amostras: o teto vence o alvo de loudness
    if tp > t["peak"] - 0.1:
        x = x * db_to_lin(t["peak"] - 0.1 - tp)
    return x


# ---------------------------------------------------------------------------
# Visualizacao (grafico de onda + espectrograma) - para revisar com Read
# ---------------------------------------------------------------------------
_CMAP = np.array([(20, 16, 24), (46, 34, 47), (69, 41, 63), (131, 28, 93), (195, 36, 84), (234, 79, 54),
                  (247, 150, 23), (249, 194, 43), (251, 255, 134)], float)  # tons da Resurrect 64


def _colormap(v: np.ndarray) -> np.ndarray:
    v = np.clip(v, 0, 1) * (len(_CMAP) - 1)
    i = np.floor(v).astype(int)
    j = np.minimum(i + 1, len(_CMAP) - 1)
    f = (v - i)[..., None]
    return (_CMAP[i] * (1 - f) + _CMAP[j] * f).astype(np.uint8)


def plot(x: np.ndarray, path: str, title: str = "", loop: bool = False, report: dict | None = None) -> str:
    """Imagem com: forma de onda (dB), envelope, espectrograma (escala log de frequencia) e metricas.
    Em loops, mostra tambem o zoom da emenda (fim -> inicio)."""
    from PIL import Image, ImageDraw
    W, WH, SH = 1100, 180, 300
    m = to_mono(x)
    n = len(m)
    rep = report or analyze(x, loop=loop)
    extra = 140 if loop else 0
    H = 30 + WH + 10 + SH + 10 + extra + 110
    img = Image.new("RGB", (W, H), (20, 16, 24))
    d = ImageDraw.Draw(img)
    d.text((10, 8), f"{title}  |  {rep['dur_s']}s  {rep['channels']}ch  {rep['lufs']} LUFS"
                    f"{'~' if rep['lufs_approx'] else ''}  pico {rep['true_peak_db']} dBTP", fill=(230, 230, 230))
    # forma de onda
    y0 = 30
    mid = y0 + WH // 2
    for db in (-6, -12, -24):
        a = db_to_lin(db) * WH / 2
        for yy in (mid - a, mid + a):
            d.line([(0, yy), (W, yy)], fill=(50, 44, 60))
        d.text((W - 40, mid - a - 12), f"{db}dB", fill=(90, 90, 110))
    d.line([(0, mid), (W, mid)], fill=(80, 70, 90))
    cols = np.array_split(m, W) if n >= W else [m[int(i * n / W):int(i * n / W) + 1] for i in range(W)]
    for i, c in enumerate(cols):
        if len(c) == 0:
            continue
        lo, hi = float(c.min()), float(c.max())
        d.line([(i, mid - hi * WH / 2), (i, mid - lo * WH / 2)], fill=(77, 155, 230))
        rms = float(np.sqrt(np.mean(c ** 2)))
        d.line([(i, mid - rms * WH / 2), (i, mid + rms * WH / 2)], fill=(143, 211, 255))
    # espectrograma
    y1 = y0 + WH + 10
    nfft = 1024 if n >= 1024 else max(64, 2 ** int(math.log2(max(n, 64))))
    hop = max(1, (n - nfft) // W) if n > nfft else 1
    frames = []
    win = np.hanning(nfft)
    for s in range(0, max(1, n - nfft), hop):
        seg = m[s:s + nfft]
        if len(seg) < nfft:
            seg = np.pad(seg, (0, nfft - len(seg)))
        frames.append(np.abs(np.fft.rfft(seg * win)))
        if len(frames) >= W:
            break
    S = np.array(frames).T if frames else np.zeros((nfft // 2 + 1, 1))
    S_db = 20 * np.log10(S + 1e-9)
    S_db = np.clip((S_db - (S_db.max() - 80)) / 80, 0, 1)
    freqs = np.fft.rfftfreq(nfft, 1 / SR)
    fmin, fmax = 30, SR / 2
    ys = np.arange(SH)
    fy = fmin * (fmax / fmin) ** (1 - ys / (SH - 1))
    rows = np.interp(fy, freqs, np.arange(len(freqs))).astype(int)
    colidx = np.linspace(0, S_db.shape[1] - 1, W).astype(int)
    rgb = _colormap(S_db[rows][:, colidx])
    img.paste(Image.fromarray(rgb, "RGB"), (0, y1))
    for f in (60, 250, 800, 3000, 8000):
        yy = y1 + (1 - math.log(f / fmin) / math.log(fmax / fmin)) * (SH - 1)
        d.line([(0, yy), (12, yy)], fill=(230, 230, 230))
        d.text((16, yy - 6), f"{f if f < 1000 else str(f // 1000) + 'k'}Hz", fill=(230, 230, 230))
    # marcas de tempo
    dur = n / SR
    step = 0.05 if dur <= 0.5 else 0.1 if dur <= 1.5 else 0.5 if dur <= 6 else 2.0
    t = 0.0
    while t <= dur:
        xx = t / dur * W
        d.line([(xx, y1 + SH), (xx, y1 + SH + 5)], fill=(200, 200, 200))
        d.text((xx + 2, y1 + SH - 12), f"{t:.2f}s", fill=(160, 160, 170))
        t += step
    yb = y1 + SH + 10
    # emenda do loop
    if loop:
        z = ns(0.02)
        seam = np.concatenate([m[-z:], m[:z]])
        zmid = yb + 60
        d.text((10, yb), "emenda do loop (20ms fim | 20ms inicio)", fill=(230, 230, 230))
        d.line([(0, zmid), (W, zmid)], fill=(80, 70, 90))
        pts = [(i / len(seam) * W, zmid - v * 55) for i, v in enumerate(seam)]
        d.line(pts, fill=(48, 225, 185))
        d.line([(W / 2, yb + 5), (W / 2, yb + 120)], fill=(232, 59, 59))
        yb += extra
    # metricas
    lines = [f"bandas %: {rep['bands_pct']}",
             f"centroide {rep['centroid_hz']} Hz  crest {rep['crest_db']} dB  rms {rep['rms_db']} dB  "
             f"silencio inicial {rep['leading_silence_ms']} ms  fim {rep['end_level_db']} dB"]
    if loop:
        lines.append(f"loop: salto {rep.get('loop_seam_jump')}  energia {rep.get('loop_energy_jump_db')} dB")
    lines += [f"! {w}" for w in rep.get("warnings", [])] or ["sem avisos"]
    for i, ln in enumerate(lines):
        d.text((10, yb + i * 16), ln, fill=(251, 185, 84) if ln.startswith("!") else (200, 200, 210))
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    img.save(path)
    return path


# ---------------------------------------------------------------------------
# Exportacao / reproducao
# ---------------------------------------------------------------------------
def default_preview_dir(asset_path: str) -> str:
    p = os.path.abspath(asset_path)
    d = os.path.dirname(p)
    while d != os.path.dirname(d):
        if os.path.isdir(os.path.join(d, "audio")) and os.path.isdir(os.path.join(d, ".claude")):
            return os.path.join(d, "audio", "previews")
        d = os.path.dirname(d)
    return os.path.join(os.path.dirname(p), "_previews")


def write_wav(path: str, x: np.ndarray, loop: tuple[int, int] | None = None) -> str:
    """WAV PCM 16-bit 44.1 kHz. loop=(inicio, fim) em amostras grava chunk 'smpl'
    (o Godot le e ativa o loop Forward automaticamente)."""
    x = np.asarray(x, float)
    if np.max(np.abs(x)) > 1.0:
        raise ValueError("sinal passa de 0 dBFS; normalize antes (normalize/limit)")
    ch = 2 if x.ndim == 2 else 1
    rng = np.random.default_rng(0)
    tpdf = (rng.random(x.shape) - rng.random(x.shape)) / 32768.0  # dither TPDF
    pcm = np.clip(np.round((x + tpdf) * 32767), -32768, 32767).astype("<i2")
    data = pcm.tobytes()
    fmt = struct.pack("<HHIIHH", 1, ch, SR, SR * ch * 2, ch * 2, 16)
    chunks = b"fmt " + struct.pack("<I", len(fmt)) + fmt
    chunks += b"data" + struct.pack("<I", len(data)) + data + (b"\x00" if len(data) % 2 else b"")
    if loop:
        smpl = struct.pack("<9I", 0, 0, int(1e9 / SR), 60, 0, 0, 0, 1, 0)
        smpl += struct.pack("<6I", 0, 0, int(loop[0]), int(loop[1]), 0, 0)
        chunks += b"smpl" + struct.pack("<I", len(smpl)) + smpl
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    with open(path, "wb") as f:
        f.write(b"RIFF" + struct.pack("<I", 4 + len(chunks)) + b"WAVE" + chunks)
    return path


def read_wav(path: str) -> np.ndarray:
    from scipy.io import wavfile
    sr, d = wavfile.read(path)
    if sr != SR:
        raise ValueError(f"{path}: {sr} Hz (projeto usa {SR})")
    return d.astype(float) / 32768.0 if d.dtype == np.int16 else d.astype(float)


def save_wav(path: str, x: np.ndarray, kind: str, loop: bool = False, do_normalize: bool = True,
             preview_dir: str | None = None, quiet: bool = False) -> dict:
    """Pipeline padrao de export: normaliza para a categoria, valida, grava WAV (com loop se pedido),
    gera grafico em audio/previews/<nome>.png e imprime o relatorio. Retorna o relatorio."""
    if kind not in LOUDNESS_TARGETS:
        raise KeyError(f"kind invalido: {kind}. Use: {', '.join(LOUDNESS_TARGETS)}")
    if kind in ("ui", "sfx", "impact", "jingle") and x.ndim == 2:
        x = to_mono(x)  # SFX sao mono (posicionais no Godot)
    if not loop:
        x = trim(x)
    if do_normalize:
        x = normalize(x, kind)
    write_wav(path, x, (0, len(x)) if loop else None)
    rep = analyze(x, kind, loop)
    pdir = preview_dir or default_preview_dir(path)
    stem = os.path.splitext(os.path.basename(path))[0]
    rep["plot"] = plot(x, os.path.join(pdir, stem + ".png"), title=stem, loop=loop, report=rep)
    rep["path"] = path
    if not quiet:
        print_report(rep)
    return rep


def print_report(rep: dict) -> None:
    keys = ["path", "dur_s", "channels", "lufs", "true_peak_db", "crest_db", "centroid_hz", "bands_pct",
            "leading_silence_ms", "end_level_db", "loop_seam_jump", "loop_energy_jump_db", "plot"]
    print(" | ".join(f"{k}={rep[k]}" for k in keys if k in rep))
    for w in rep["warnings"]:
        print("  AVISO:", w)
    if not rep["warnings"]:
        print("  OK: sem avisos")


def play(path_or_signal, volume: float = 0.8, label: str | None = None) -> None:
    """Toca no Mac com afplay (bloqueia ate terminar). Aceita caminho ou array."""
    path = path_or_signal
    if not isinstance(path_or_signal, str):
        path = os.path.join("/tmp", "soundkit_play.wav")
        write_wav(path, normalize_peak(path_or_signal, -1))
    if label:
        print(f">> tocando: {label}")
    subprocess.run(["afplay", "-v", str(volume), path], check=False)


def play_sequence(paths: Sequence[str], gap: float = 0.6, volume: float = 0.8, repeat: int = 1) -> None:
    """Toca varias opcoes em ordem (A, B, C...) com pausa, para o usuario comparar."""
    import time
    for r in range(repeat):
        for i, p in enumerate(paths):
            play(p, volume, label=f"{chr(65 + i)} - {os.path.basename(p)}")
            time.sleep(gap)


def save_variations(make: Callable[[int], np.ndarray], base_path: str, kind: str, n: int = 3,
                    seeds: Sequence[int] | None = None, tres_path: str | None = None, random_pitch: float = 1.05,
                    random_volume_db: float = 1.0) -> list[dict]:
    """Gera n variacoes (make(seed) -> sinal), exporta <base>_01.wav... e opcionalmente um
    AudioStreamRandomizer .tres do Godot que sorteia entre elas com pitch/volume aleatorio.
    Essencial para sons repetitivos (cliques, compras, passos) - evita fadiga."""
    seeds = list(seeds or range(1, n + 1))
    stem, ext = os.path.splitext(base_path)
    reps = [save_wav(f"{stem}_{i + 1:02d}{ext or '.wav'}", make(s), kind) for i, s in enumerate(seeds)]
    if tres_path:
        write_randomizer_tres(tres_path, [r["path"] for r in reps], random_pitch, random_volume_db)
    return reps


def _res_path(p: str) -> str:
    a = os.path.abspath(p)
    d = os.path.dirname(a)
    while d != os.path.dirname(d):
        if os.path.exists(os.path.join(d, "project.godot")):
            return "res://" + os.path.relpath(a, d).replace(os.sep, "/")
        d = os.path.dirname(d)
    return "res://" + os.path.relpath(a, os.getcwd()).replace(os.sep, "/")


def write_randomizer_tres(tres_path: str, wav_paths: Sequence[str], random_pitch: float = 1.05,
                          random_volume_db: float = 1.0) -> str:
    ext = "\n".join(f'[ext_resource type="AudioStream" path="{_res_path(p)}" id="{i + 1}_s"]'
                    for i, p in enumerate(wav_paths))
    streams = "\n".join(f'stream_{i}/stream = ExtResource("{i + 1}_s")\nstream_{i}/weight = 1.0'
                        for i in range(len(wav_paths)))
    body = (f'[gd_resource type="AudioStreamRandomizer" load_steps={len(wav_paths) + 1} format=3]\n\n{ext}\n\n'
            f"[resource]\nplayback_mode = 0\nrandom_pitch = {random_pitch}\n"
            f"random_volume_offset_db = {random_volume_db}\nstreams_count = {len(wav_paths)}\n{streams}\n")
    os.makedirs(os.path.dirname(os.path.abspath(tres_path)), exist_ok=True)
    with open(tres_path, "w") as f:
        f.write(body)
    return tres_path


# ---------------------------------------------------------------------------
# Sequenciador de musica (tracker simples)
# ---------------------------------------------------------------------------
Instrument = Callable[[float, float, float], np.ndarray]  # (freq, dur_s, vel 0..1) -> sinal mono


def inst_pulse(duty: float = 0.25, a: float = 0.005, d: float = 0.1, s: float = 0.5, r: float = 0.08,
               vib: float = 0.0, vib_rate: float = 5.5) -> Instrument:
    """Lead/arpejo de chip (pulso)."""
    def play_(f, dur, vel):
        total = dur + r
        fr = vibrato(f, total, vib_rate, vib, delay=0.15) if vib else f
        return pulse(fr, total, duty) * adsr(total, a, d, s, r) * vel
    return play_


def inst_triangle_bass(r: float = 0.05, steps: int | None = 16) -> Instrument:
    """Baixo triangular estilo NES."""
    def play_(f, dur, vel):
        total = dur + r
        return triangle(f, total, steps) * adsr(total, 0.003, 0.05, 0.9, r) * vel
    return play_


def inst_pad(voices: int = 4, detune: float = 14, cutoff: float = 1800, a: float = 0.4, r: float = 1.2,
             osc: str = "saw") -> Instrument:
    """Pad espacial: vozes desafinadas + lowpass + ataque/release lentos."""
    o = {"saw": saw, "pulse": pulse, "tri": triangle, "sine": sine}[osc]
    def play_(f, dur, vel):
        total = dur + r
        x = unison(o, f, total, voices, detune)
        x = lowpass(x, cutoff, 2)
        return x * adsr(total, a, 0.3, 0.8, r) * vel * 0.6
    return play_


def inst_bell(ratio: float = 3.5, index: float = 3.0, tau: float = 0.6) -> Instrument:
    """Sino/glockenspiel FM (brilho que decai) - otimo para melodias espaciais e UI."""
    def play_(f, dur, vel):
        total = max(dur, tau * 4)
        return fm(f, total, ratio, index * decay(total, tau * 0.4)) * decay(total, tau) * vel
    return play_


def inst_pluck(cutoff0: float = 5000, cutoff1: float = 400, tau: float = 0.25, osc: str = "saw") -> Instrument:
    o = {"saw": saw, "pulse": pulse}[osc]
    def play_(f, dur, vel):
        total = dur + tau * 2
        x = o(f, total)
        x = svf(x, sweep(cutoff0, cutoff1, total), 1.2)
        return x * decay(total, tau) * vel
    return play_


def drum_kick(f0: float = 150, f1: float = 45, tau: float = 0.12) -> Instrument:
    def play_(f, dur, vel):
        t = 0.35
        body = sine(sweep(f0, f1, t), t) * decay(t, tau)
        click = np.zeros(ns(t))
        c = noise(0.006, seed=3) * 0.4 * decay(0.006, 0.002)
        click[: len(c)] = c
        return (body + click) * vel
    return play_


def drum_snare(tone: float = 190, tau: float = 0.09) -> Instrument:
    def play_(f, dur, vel):
        t = 0.25
        body = sine(sweep(tone * 1.4, tone, 0.05), t) * decay(t, 0.04)
        sn = bandpass(noise(t, seed=5), 1500, 9000) * decay(t, tau)
        return (0.6 * body + 0.9 * sn) * vel
    return play_


def drum_hat(open_: bool = False) -> Instrument:
    def play_(f, dur, vel):
        t = 0.3 if open_ else 0.06
        return highpass(chip_noise(9000, t, seed=7), 7000) * decay(t, 0.12 if open_ else 0.015) * vel * 0.5
    return play_


def drum_chip(f0: float = 1200, f1: float = 60, t: float = 0.12) -> Instrument:
    """Bateria de chip: ruido com pitch caindo (o 'punch' e a queda de altura)."""
    def play_(f, dur, vel):
        return chip_noise(sweep(f0, f1, t), t, seed=9) * decay(t, t / 3) * vel
    return play_


_TOKEN = re.compile(r"^([A-Ga-g][#b]?-?\d)((?:\+[A-Ga-g][#b]?-?\d)*)(!?)$")


@dataclass
class Track:
    name: str
    instrument: Instrument
    pattern: str
    gain_db: float = 0.0
    pan: float = 0.0
    drum: bool = False
    fx: Callable[[np.ndarray], np.ndarray] | None = None  # efeito por faixa (ex.: lambda x: delay(x, ...))


@dataclass
class Song:
    """Musica em grade de passos. Padrao de notas (tokens separados por espaco, '|' ignorado):
      'D4'  nota      'D4+F#4+A4' acorde      'D4!' acento      '.' pausa      '-' sustenta a anterior
    Padrao de bateria: 'x' batida, 'X' acento, '.' pausa (cada caractere = 1 passo; espacos e '|' ignorados).
    O padrao se repete ate preencher `bars` compassos."""
    bpm: float = 100
    bars: int = 8
    steps_per_beat: int = 4
    beats_per_bar: int = 4
    tracks: list[Track] = field(default_factory=list)

    @property
    def step_dur(self) -> float:
        return 60.0 / self.bpm / self.steps_per_beat

    @property
    def total_steps(self) -> int:
        return self.bars * self.beats_per_bar * self.steps_per_beat

    @property
    def dur(self) -> float:
        return self.total_steps * self.step_dur

    def add(self, name: str, instrument: Instrument, pattern: str, gain_db: float = 0.0, pan: float = 0.0,
            drum: bool = False, fx=None) -> "Song":
        self.tracks.append(Track(name, instrument, pattern, gain_db, pan, drum, fx))
        return self

    def _events(self, tr: Track) -> list[tuple[int, int, list[float], float]]:
        ev = []
        if tr.drum:
            steps = [c for c in tr.pattern if c not in " |\n"]
            for i in range(self.total_steps):
                c = steps[i % len(steps)]
                if c in "xX":
                    ev.append((i, 1, [0.0], 1.0 if c == "X" else 0.7))
            return ev
        toks = [t for t in tr.pattern.split() if t != "|"]
        cur = None
        for i in range(self.total_steps):
            t = toks[i % len(toks)]
            if t == "-" and cur is not None:
                cur[1] += 1
                continue
            if cur:
                ev.append(tuple(cur))
                cur = None
            if t in (".", "-"):
                continue
            m = _TOKEN.match(t)
            if not m:
                raise ValueError(f"token invalido na faixa {tr.name}: {t!r}")
            names = [m.group(1)] + [s for s in m.group(2).split("+") if s]
            cur = [i, 1, [note(nm) for nm in names], 1.0 if m.group(3) else 0.75]
        if cur:
            ev.append(tuple(cur))
        return ev

    def render_track(self, tr: Track) -> np.ndarray:
        L = ns(self.dur)
        buf = np.zeros(L + ns(6.0))
        sd = self.step_dur
        for start, length, freqs, vel in self._events(tr):
            for f in freqs:
                s = tr.instrument(f, length * sd, vel / math.sqrt(len(freqs)))
                a = ns(start * sd) if start else 0
                end = min(len(buf), a + len(s))
                buf[a:end] += s[: end - a]
        out = pan(buf, tr.pan) * db_to_lin(tr.gain_db)
        if tr.fx:
            out = tr.fx(out)
            out = to_stereo(out)
        return out

    def render(self, loop: bool = True, master_fx: Callable[[np.ndarray], np.ndarray] | None = None) -> np.ndarray:
        """Renderiza estereo. loop=True dobra as caudas sobre o inicio (loop perfeito)."""
        parts = [self.render_track(tr) for tr in self.tracks]
        n = max(len(p) for p in parts)
        out = np.zeros((n, 2))
        for p in parts:
            out[: len(p)] += p
        if master_fx:
            out = to_stereo(master_fx(out))
        if loop:
            return wrap_tail(out, self.dur)
        return trim(out)

    def stems(self) -> dict[str, np.ndarray]:
        """Cada faixa separada (para camadas adaptativas no Godot: AudioStreamSynchronized)."""
        return {tr.name: wrap_tail(self.render_track(tr), self.dur) for tr in self.tracks}


# ---------------------------------------------------------------------------
# Presets (pontos de partida estilo sfxr - SEMPRE adapte ao pedido)
# ---------------------------------------------------------------------------
def p_blip(seed: int = 0) -> np.ndarray:
    """UI select/hover: pulso curto e agudo, na escala."""
    rng = np.random.default_rng(seed)
    f = snap(rng.uniform(900, 1600))
    d = rng.uniform(0.04, 0.07)
    return pulse(f, d, rng.choice([0.25, 0.5])) * decay(d, d / 3)


def p_coin(seed: int = 0) -> np.ndarray:
    """Moeda/pickup/compra: 2 notas subindo (quarta ou quinta), pulso, cauda curta."""
    rng = np.random.default_rng(seed)
    base = snap(rng.uniform(800, 1300))
    up = mtof(ftom(base) + rng.choice([5, 7]))
    d1, d2 = 0.06, rng.uniform(0.15, 0.25)
    a = pulse(base, d1, 0.5) * 0.9
    b = pulse(snap(up), d2, 0.5) * decay(d2, d2 / 3)
    return concat(a, b)


def p_powerup(seed: int = 0, steps: int = 6) -> np.ndarray:
    """Upgrade/power-up: arpejo ascendente na escala do projeto com vibrato leve."""
    rng = np.random.default_rng(seed)
    ms = scale_midis("sfx", lo="D4", hi="D7")
    i0 = int(rng.integers(0, 4))
    seq = ms[i0:i0 + steps]
    st = rng.uniform(0.045, 0.065)
    notes = [pulse(mtof(m), st, 0.25) * adsr(st, 0.002, 0.02, 0.7, 0.01) for m in seq[:-1]]
    last = 0.35
    notes.append(pulse(vibrato(mtof(seq[-1]), last, 7, 0.3), last, 0.25) * decay(last, 0.12))
    return concat(*notes)


def p_laser(seed: int = 0) -> np.ndarray:
    rng = np.random.default_rng(seed)
    d = rng.uniform(0.12, 0.25)
    f = sweep(rng.uniform(1500, 2500), rng.uniform(150, 400), d)
    return pulse(f, d, sweep(0.5, 0.15, d, "lin")) * decay(d, d / 2.5)


def p_hit(seed: int = 0) -> np.ndarray:
    rng = np.random.default_rng(seed)
    d = rng.uniform(0.12, 0.2)
    tone = saw(sweep(rng.uniform(300, 500), 60, d), d) * decay(d, d / 4)
    crunch = chip_noise(sweep(3000, 400, d), d, seed=seed + 1) * decay(d, d / 6)
    return mix([(tone, 0, -3), (crunch, 0, -2)])


def p_explosion(seed: int = 0, size: float = 1.0) -> np.ndarray:
    """Explosao em camadas: crack (transiente) + corpo (ruido com LP caindo) + sub (thump) + cauda."""
    rng = np.random.default_rng(seed)
    d = 0.8 + 0.8 * size
    crack = highpass(noise(0.03, seed=seed), 2000) * decay(0.03, 0.008)
    body = svf(noise(d, "white", seed + 1), sweep(4000 * size + 1500, 120, d), 0.9) * decay(d, d / 4)
    sub = sine(sweep(110, 35, 0.4), 0.4) * decay(0.4, 0.12)
    rumble = lowpass(noise(d, "brown", seed + 2), 300) * decay(d, d / 2.5)
    crackle = chip_noise(rng.uniform(800, 1600), d, seed=seed + 3) * (lfo(d, 18, 0, 1, "random", seed=seed) > 0.8)
    crackle = crackle * decay(d, d / 3)
    return mix([(crack, 0, -4), (body, 0.005, 0), (sub, 0, -2), (rumble, 0.02, -3), (crackle, 0.05, -16)])


def p_thruster_loop(seconds: float = 2.0, seed: int = 0, power: float = 0.7) -> np.ndarray:
    """Propulsor continuo (loop): ronco grave (brown) + sopro medio (pink c/ filtro oscilando) +
    crepitar sutil. power 0..1 abre o filtro e o volume."""
    total = seconds + 0.2
    roar = lowpass(noise(total, "brown", seed), 180 + 220 * power) * 1.0
    cut = lfo(total, 3.0, 500 + 900 * power, 900 + 1800 * power, "random", seed=seed + 1)
    hiss = svf(noise(total, "pink", seed + 2), cut, 0.8) * 0.5
    flutter = tremolo(roar + hiss, 22, 0.12)
    crack = highpass(chip_noise(2500, total, seed=seed + 3), 1500) * 0.04
    return make_loop(flutter + crack, seconds, crossfade=0.15)


def p_landing(seed: int = 0, soft: bool = True) -> np.ndarray:
    """Pouso: thump grave + poeira (ruido filtrado curto) + rangido metalico leve."""
    d = 0.5
    thump = sine(sweep(90, 40, 0.25), 0.25) * decay(0.25, 0.07 if soft else 0.12)
    dust = lowpass(noise(d, "pink", seed), 1200) * decay(d, 0.15)
    creak = fm(snap(420), 0.3, 1.41, 1.5 * decay(0.3, 0.1)) * decay(0.3, 0.08)
    return mix([(thump, 0, 0), (dust, 0.01, -8), (creak, 0.03, -18 if soft else -12)])


PRESETS = {"blip": p_blip, "coin": p_coin, "powerup": p_powerup, "laser": p_laser, "hit": p_hit,
           "explosion": p_explosion, "thruster_loop": p_thruster_loop, "landing": p_landing}


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
def _main(argv: list[str]) -> int:
    if len(argv) < 2 or argv[1] in ("-h", "--help"):
        print("uso:\n  soundkit.py analyze <wav> [kind] [--loop]   relatorio + grafico\n"
              "  soundkit.py play <wav>...                   toca (afplay) em sequencia A, B, C\n"
              "  soundkit.py preset <nome> <out.wav> <kind> [seed]\n"
              "  soundkit.py scale [modo]                    notas da escala do projeto\n"
              "  soundkit.py targets                         alvos de loudness")
        return 0
    cmd = argv[1]
    if cmd == "analyze":
        x = read_wav(argv[2])
        kind = argv[3] if len(argv) > 3 and not argv[3].startswith("--") else None
        lp = "--loop" in argv
        rep = analyze(x, kind, lp)
        rep["plot"] = plot(x, os.path.splitext(argv[2])[0] + "_analysis.png", os.path.basename(argv[2]), lp, rep)
        rep["path"] = argv[2]
        print_report(rep)
        return 0
    if cmd == "play":
        play_sequence(argv[2:])
        return 0
    if cmd == "preset":
        seed = int(argv[5]) if len(argv) > 5 else 0
        save_wav(argv[3], PRESETS[argv[2]](seed=seed), argv[4], loop=argv[2].endswith("_loop"))
        return 0
    if cmd == "scale":
        mode = argv[2] if len(argv) > 2 else "sfx"
        ms = scale_midis(mode, lo="C3", hi="C7")
        print(" ".join(f"{NOTE_NAMES[m % 12]}{m // 12 - 1}" for m in ms))
        return 0
    if cmd == "targets":
        for k, v in LOUDNESS_TARGETS.items():
            print(f"{k:9s} {v}")
        return 0
    print(f"comando desconhecido: {cmd}")
    return 1


if __name__ == "__main__":
    sys.exit(_main(sys.argv))
